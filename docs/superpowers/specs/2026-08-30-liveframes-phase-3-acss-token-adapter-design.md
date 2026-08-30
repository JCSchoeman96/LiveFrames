# LiveFrames Phase 3 Automatic.css TokenSet Adapter Design

## Goal

Translate the approved Automatic.css settings export into a deterministic,
source-independent LiveFrames TokenSet. The resulting token artifact must be
usable by later Design IR and CSS/Tailwind bridges without Automatic.css,
WordPress, Bricks, Frames, Novamira, or PHP at runtime.

This design starts from the Phase 2 merge commit
`7231195b5bf150ba7896648576c1bd0718801506`. Design IR remains version `1.0.0`
and is not changed by this phase.

## Evidence and source boundary

The approved fixture is `fixtures/automatic_css/acss_settings.json`. It is a
flat JSON object containing 2,573 persisted settings. It has no embedded export
version. `fixtures/automatic_css/SOURCE.md` and the committed ACSS 4.0.1
settings research map establish `4.0.1` as the reference/source version, so
the adapter records:

```text
source_version: "4.0.1"       # fixture/reference provenance
export_version: nil            # not present in the JSON export
source_shape: "flat_settings_map"
```

The research map is reference evidence only. The adapter does not load,
execute, copy, or depend on Automatic.css plugin code. The JSON is treated as
untrusted data: no CSS, JavaScript, PHP, shell command, module, or path from
the input is executed or followed.

## Design choices

Three approaches were considered:

1. Flatten every setting into a token. This would expose implementation
   controls, feature flags, and source-specific names as the public API.
2. Build a general formula/compiler graph for all ACSS variables. This would
   reproduce a large portion of Automatic.css and would make unresolved
   source behaviour appear resolved.
3. Use a narrow, reviewable mapping table, explicit semantic references, and a
   bounded reference validator. This keeps the first contract small while
   preserving the relationships needed by the next conversion.

Approach 3 is selected. Known calculated relationships are represented as a
small structured derived value with its proven input references; ACSS formula
evaluation and CSS generation remain later work.

The following assumptions are deliberately rejected:

- settings become tokens only when they are reusable design semantics or a
  proven dependency of one of those semantics;
- CSS custom properties do not automatically become literals;
- ACSS utility class names are not canonical token paths;
- breakpoint labels do not imply framework thresholds; and
- one successful fixture does not establish complete ACSS compatibility.

## TokenSet contract

`LiveFrames.Tokens.TokenSet` owns the independent TokenSet version. The first
version is `1.0.0`, separate from `LiveFrames.IR`'s `1.0.0`.

The root contains only the generic contract fields:

```elixir
%LiveFrames.Tokens.TokenSet{
  token_set_version: "1.0.0",
  source_metadata: %{...},
  tokens: %{"color.primary" => %LiveFrames.Tokens.Token{}},
  diagnostics: [%LiveFrames.Tokens.Diagnostic{}]
}
```

Each token preserves separate semantic, source, and resolution concepts:

```elixir
%LiveFrames.Tokens.Token{
  path: "button.primary.background",
  category: :button,
  value: %{"type" => "reference", "path" => "color.primary"},
  resolved_value: "#32a2c1",
  source_expression: "var(--primary)",
  resolution_status: :resolved,
  references: ["color.primary"],
  provenance: %{
    "source_type" => "automatic_css_settings",
    "source_keys" => ["btn-primary-bg"],
    "raw_value" => "var(--primary)",
    "adapter" => "automatic_css",
    "adapter_version" => "1.0.0",
    "transformation" => "semantic_reference"
  },
  metadata: %{}
}
```

`value` is the canonical value. It is a literal, a structured responsive
value, a semantic reference, or a structured `derived` recipe. A semantic
reference is never flattened merely because its source syntax contains
`var(...)`. `resolved_value` contains the proven target literal or derived
representation when available. `resolution_status` is `:resolved` when the
literal or relationship is proven and `:unresolved` when the source value or
target cannot be established. An unresolved expression remains inspectable in
`source_expression` and provenance.

Derived values are intentionally descriptive, for example:

```json
{
  "type": "derived",
  "recipe": "acss.clamp",
  "variable": "space-m",
  "inputs": {
    "min": "spacing.base.min",
    "max": "spacing.base.max",
    "mobile_scale": 1.333,
    "desktop_scale": 1.5
  }
}
```

This records a proven ACSS relationship without pretending that Phase 3 is a
complete ACSS formula engine.

## Canonical mapping scope

`LiveFrames.Adapters.AutomaticCSS.Normalizer.mapping/0` is the one authoritative
mapping definition. It is ordered by canonical path and records source keys,
category, transformation, units, and any expected semantic reference. Raw
ACSS keys are never exposed as the canonical API.

The initial mapping covers these paths:

### Colors and backgrounds

```text
color.primary
color.primary.hover
color.primary.light
color.primary.semi_light
color.primary.dark
color.primary.semi_dark
color.primary.ultra_light
color.primary.ultra_dark
color.neutral
color.neutral.light
color.neutral.semi_light
color.neutral.dark
color.neutral.semi_dark
color.neutral.ultra_light
color.neutral.ultra_dark
color.base
color.base.ultra_light
color.background.light
color.background.dark
color.background.ultra_light
color.background.ultra_dark
color.text.dark
color.text.light
```

Direct palette colors use the fixture's hex value. Proven HSL channel groups
are rendered deterministically as an HSL expression while retaining all raw
channel settings in provenance. Background values retain semantic references
to the corresponding palette token. `text-dark` and `text-light` currently
refer to `--black` and `--white`, which are not supplied as settings; they are
represented as unresolved rather than inferred from another palette.

The Hero overlay expression
`var(--overlay-bg, var(--neutral-ultra-dark-trans-60))` is not an ACSS setting
in this fixture. Phase 3 does not invent an overlay token for it.

### Spacing and radius

```text
spacing.base.min
spacing.base.max
spacing.scale.medium
spacing.scale.xl
spacing.content_gap
spacing.grid_gap
spacing.container_gap
spacing.section
spacing.section.padding_block
spacing.gutter.min
spacing.gutter.max
radius.base
```

Numeric `px` settings are converted to explicit CSS values only where the
committed ACSS research map identifies the source control as `px`. Contextual
gaps preserve references to the proven ACSS calculated variables (`space-m`,
`space-xl`, and `section-space-m`).

### Typography

```text
typography.body.base_size
typography.body.scale
typography.body.scale.medium
typography.body.line_height
typography.heading.base_size
typography.heading.scale
typography.heading.scale.h1
typography.heading.line_height
```

Base sizes are structured min/max responsive values. Base line-height values
remain source CSS expressions. Scale variables are represented as proven
derived relationships with their source ratios and base references; blank
per-heading overrides are not treated as defaults.

### Primary buttons

```text
button.primary.background
button.primary.background_hover
button.primary.text
button.primary.border
button.primary.focus
button.primary.radius
button.primary.padding_inline
button.primary.padding_block
button.primary.min_width
button.primary.font_size
button.primary.font_weight
button.primary.line_height
button.primary.border_width
button.primary.border_style
button.primary.outline.background
button.primary.outline.background_hover
button.primary.outline.border
button.primary.outline.border_hover
button.primary.outline.focus
button.primary.outline.text
button.primary.outline.text_hover
```

The `--btn-background` and `--btn-background-hover` references are resolved
to the primary button background tokens because the ACSS research map proves
those generated CSS-variable identities. `--text-m` is resolved to the
semantic `typography.body.scale.medium` relationship, not to an ACSS runtime
variable.

### Layout

```text
layout.viewport.min
layout.viewport.max
layout.breakpoint.auto_grid
```

The first two come from `vp-min` and `vp-max`; the last comes from the explicit
`auto-staggered-grid-breakpoint` setting. No tablet or mobile threshold is
created from a label or convention.

## Required profile and strict mode

The first required-token profile is the semantic `hero_foundation` profile.
It is token-centric and does not name a Hero component. It requires:

```text
color.primary
color.primary.hover
color.primary.light
color.primary.ultra_dark
color.neutral
color.neutral.ultra_dark
spacing.base.min
spacing.base.max
spacing.content_gap
spacing.gutter.min
spacing.gutter.max
typography.body.base_size
typography.body.line_height
typography.heading.base_size
typography.heading.line_height
button.primary.background
button.primary.background_hover
button.primary.text
button.primary.border
button.primary.focus
button.primary.radius
button.primary.padding_inline
button.primary.padding_block
button.primary.min_width
button.primary.font_size
button.primary.font_weight
button.primary.line_height
layout.viewport.min
layout.viewport.max
```

Strict mode validates only this requirement set. It does not require every
known ACSS setting or every mapped optional token. A missing or unresolved
required path emits `tokens.required.missing` and returns an error. An
unrelated absent setting does not fail the profile.

## Adapter API and data flow

The public adapter surface is:

```elixir
LiveFrames.Adapters.AutomaticCSS.from_file(path, opts \\ [])
LiveFrames.Adapters.AutomaticCSS.from_json(json, opts \\ [])
LiveFrames.Adapters.AutomaticCSS.normalize(decoded_map, opts \\ [])
```

The result is always explicit:

```elixir
{:ok, token_set, diagnostics}
{:error, diagnostics}
```

`from_file/2` reads one caller-supplied local path and feeds the decoded data
through the same normalization path. File and decode failures are structured
diagnostics. `from_json/2` decodes one JSON document and rejects non-object or
unsupported envelopes. The initial recognizer accepts only the flat settings
map shape and requires at least one known ACSS setting key. `normalize/2`
operates on an already-decoded map and does not read files, resolve paths, or
make network calls.

The internal stages are:

```text
loader/recognizer
  -> narrow source envelope
normalizer
  -> explicit token mapping and provenance
resolver
  -> references, HSL values, and proven derived relationships
TokenSet validator
  -> schema, references, cycles, and profile requirements
serializer
  -> stable JSON
```

`LiveFrames.Tokens` has no dependency on the Automatic.css adapter. The
adapter depends on the generic TokenSet contract.

## Diagnostics and unknown settings

Token diagnostics use stable machine-readable codes. The initial set includes:

```text
acss.source.invalid
acss.source.json_invalid
acss.setting.unknown
acss.setting.invalid
acss.value.unresolved
acss.mapping.conflict
tokens.version.unsupported
tokens.path.invalid
tokens.path.duplicate
tokens.category.invalid
tokens.status.invalid
tokens.reference.missing
tokens.reference.cycle
tokens.required.missing
tokens.provenance.invalid
```

Unknown settings are expected. The adapter ignores them for canonical output
and emits one deterministic summary diagnostic containing the count and a
bounded sorted sample. Mapped values with invalid types or unsupported color
representations remain inspectable as unresolved tokens with diagnostics.
No fallback literal is inserted below a confirmed source value.

## Validation and serialization

`LiveFrames.Tokens.Validation` is source-independent and validates:

- supported TokenSet version and root shape;
- canonical path format and uniqueness after JSON-key normalization;
- supported categories and resolution statuses;
- JSON-safe token values, metadata, and provenance;
- reference shape and target existence;
- reference cycles;
- diagnostic shape; and
- strict required-token satisfaction.

The validator does not know Bricks, ACSS setting names, or Hero semantics.

`LiveFrames.Tokens.Serializer` converts structs to explicit JSON objects,
recursively sorts object keys, preserves list order, and encodes with
`maps: :strict`. It emits no struct metadata, timestamps, process state, or
map-iteration-dependent ordering. The adapter sorts diagnostics by a stable
normalization sequence and paths are emitted in canonical order. Equivalent
source maps therefore produce bytewise-identical TokenSet JSON.

## Testing design

Focused tests use the committed fixture once for integration coverage and
small in-memory maps for malformed input, missing values, references, cycles,
unknown settings, breakpoint policy, and invalid types. They cover:

- loader recognition and malformed JSON;
- TokenSet version and source-version provenance;
- representative mappings in every category;
- raw keys, raw values, transformation evidence, and adapter provenance;
- semantic reference preservation and derived relationships;
- strict `hero_foundation` success, missing, and unresolved cases;
- unknown-setting tolerance;
- proven viewport/breakpoint values without inferred thresholds;
- deterministic normalization and bytewise serialization; and
- safety against arbitrary atom creation.

All Phase 0–2 gates remain required. No database, Redis, Docker, runtime cache,
streaming parser, browser automation, or external API is introduced.

## Explicit stop boundary

This phase does not parse Bricks, resolve Bricks global classes or ACSS utility
classes, construct Design IR, create Hero India structures or components,
generate HEEx, generate Tailwind configuration/classes, generate SCSS, or
start Phase 4. The TokenSet is the only downstream-facing artifact.

