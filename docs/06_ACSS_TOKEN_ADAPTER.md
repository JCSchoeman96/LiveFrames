# Automatic.css TokenSet adapter

Phase 3 translates the approved Automatic.css settings fixture into the
source-independent LiveFrames TokenSet contract. The adapter is a
compile-time/data-conversion boundary:

~~~text
Automatic.css JSON
  -> recognize and validate the flat source envelope
  -> normalize the supported semantic subset
  -> resolve proven relationships and preserve unresolved expressions
  -> validate and deterministically serialize a LiveFrames TokenSet
~~~

It does not make Automatic.css a runtime dependency. A consuming Phoenix
project needs only the serialized LiveFrames TokenSet and later bridges that
consume it; it does not need WordPress, Bricks, Automatic.css, Frames,
Novamira, or PHP.

## Scope and source compatibility

The initial adapter recognizes the committed flat settings map at
fixtures/automatic_css/acss_settings.json. The fixture contains 2,573 source
keys and does not contain an embedded export-version field. Its adjacent
provenance record identifies the reference source as Automatic.css 4.0.1,
so the fixture integration supplies that sidecar evidence explicitly and
normalized metadata records:

~~~json
{
  "source_version": "4.0.1",
  "source_version_status": "fixture_reference",
  "export_version": null,
  "source_shape": "flat_settings_map"
}
~~~

source_version is the reference-set version; export_version remains explicitly
absent. The loader does not assume 4.0.1 for arbitrary input: when
source_version is not supplied, it records source_version as null and
source_version_status as not_embedded. A supplied source version is caller
metadata and does not make the adapter claim full source compatibility.

The committed fixture is normalized with the sidecar evidence explicitly:

~~~elixir
AutomaticCSS.from_file(path,
  source_version: "4.0.1",
  source_version_status: "fixture_reference"
)
~~~

The adapter accepts only a flat JSON object with non-empty string keys,
JSON-safe values, and at least one recognized mapping key. Nested envelopes,
lists, scalars, malformed JSON, unreadable files, and unrecognized-only maps
return structured diagnostics.

The public boundary is intentionally small:

~~~elixir
LiveFrames.Adapters.AutomaticCSS.from_file(path, opts)
LiveFrames.Adapters.AutomaticCSS.from_json(json, opts)
LiveFrames.Adapters.AutomaticCSS.normalize(decoded_settings, opts)
~~~

Successful normalization returns {:ok, token_set, diagnostics}. Expected
source or validation failures return {:error, diagnostics}. normalize/2 is the
only path that operates on decoded settings; file and JSON loading feed into
it.

## TokenSet version and model

The adapter emits TokenSet 1.0.0, independently of frozen Design IR 1.0.0. A
TokenSet root contains only:

~~~json
{
  "token_set_version": "1.0.0",
  "source_metadata": {},
  "tokens": {},
  "diagnostics": []
}
~~~

Each canonical token preserves:

| Field | Meaning |
| --- | --- |
| path | Stable semantic path owned by LiveFrames |
| category | Generic category such as color, spacing, or button |
| value | Canonical literal, semantic reference, responsive value, or derived recipe |
| resolved_value | Proven literal/structured result, or null when unresolved |
| source_expression | Raw source expression or source channel/input map |
| resolution_status | resolved or unresolved |
| references | Canonical token paths used by the token |
| provenance | Source keys, raw value, adapter/version, and transformation |
| metadata | Calculation and source details, including optional typed CSS-variable authority records |

Token resolution follows `source observed -> resolution attempt -> resolved` or
`unresolved`. A resolved token requires a non-nil `resolved_value`; an
unresolved token requires `resolved_value: null`. Source `value` and
`source_expression` evidence may remain on unresolved tokens. Resolution is
semantic, so a resolved structured value such as a responsive map does not
have to serialize as one CSS value. Resolved and unresolved are the only
terminal states.

`Token.metadata` may include a `variable_authorities` list. Each record has a
CSS custom-property `variable`, a `kind`, a stable `authority_id`, an optional
`source_key`, and a nullable `source_version`. The owning token supplies the
canonical TokenSet path, so records do not repeat it.

A resolved token with variable authority must also expose a representation
that can be written as one CSS value, since it may back a direct token
reference. CSS safety checks remain the responsibility of each CSS consumer.

The supported kinds describe separate relationships:

| Kind | Relationship |
| --- | --- |
| `source_output_alias` | An explicit source setting or calculated-variable contract emits the CSS variable for the owning token path. |
| `source_reference` | The source adapter explicitly validated a source expression that consumes the CSS variable for the owning token path. |
| `explicit_project_contract` | LiveFrames has a frozen project-specific variable-to-path contract. |

Consumers can build an inverse index from these records without loading the
source adapter. Records for the same variable and token path support one
candidate; records for distinct paths remain ambiguous. A candidate's token
resolution status remains a separate fact. This optional metadata keeps
TokenSet at version `1.0.0` and does not add a root field.

Structural framework variables such as Automatic.css grid recipes are **not**
TokenSet tokens. They are recorded separately through
`LiveFrames.Adapters.AutomaticCSS.StructuralVariables` and consumed by Bricks
through `structural_variable_authority`. For the proven ACSS 4.0.1 contract,
`--grid-1` resolves structurally to `repeat(1, minmax(0, 1fr))` from
project/source-environment generated CSS evidence. TokenSet paths such as
`layout.grid.one` are intentionally not introduced for these variables.

Structural authority is fail-closed. `StructuralVariableAuthority.build/1`
rejects malformed records instead of silently dropping them. A variable is a
unique structural candidate only when exactly one distinct authority record
remains after exact duplicate deduplication; two records with the same value but
different authority identities remain ambiguous.

ACSS grid-variable authority requires explicit enabled evidence:
`grid_variables_enabled: true` or settings
`option-grid-variables` = `"on"`. Missing or off settings produce an empty
structural index.

Structural validity and authority trust are separate checks:

* `Tokens.validate/2` checks the TokenSet structure. Processing diagnostics
  remain part of the TokenSet evidence and do not make it structurally invalid.
* `VariableAuthority.build/1` validates the structure and builds the
  deterministic variable authority evidence index.
* `AuthorityGate.authorize/1` decides whether a compiler consumer may trust
  that index. `info` and `warning` diagnostics do not block authority use.
  `error` and `fatal` diagnostics do, while the TokenSet remains serializable
  and auditable.

Proven semantic references remain references in value, for example:

~~~json
{
  "value": {"type": "reference", "path": "color.primary"},
  "source_expression": "var(--primary)",
  "resolved_value": "#32a2c1",
  "resolution_status": "resolved",
  "references": ["color.primary"]
}
~~~

Derived Automatic.css relationships use structured values such as
{"type":"derived","recipe":"acss.clamp",...}. They are marked resolved when
the source relationship and all required inputs are proven, even though Phase
3 does not evaluate every generated CSS formula.

The ACSS 4.0.1 black/white foundation is the one intentionally supported
generated relationship in this subset. The reference palette defines white as
`#fff` and black as `#000`, with reversed alternate-scheme values. When
`auto-color-scheme` is `on`, the adapter preserves the generated
`light-dark(...)` expression; when it is `off`, it preserves the corresponding
light-scheme literal. These are distinct `color.black` and `color.white`
concepts, not aliases for neutral palette tokens. `color.text.dark` and
`color.text.light` retain their source expressions while referencing those
canonical foundation paths.

This distinction defines three boundaries:

* A canonical semantic token is a value or relationship provable from approved
  ACSS settings/reference evidence and useful independently of ACSS
  implementation details.
* A generated ACSS implementation variable is emitted or consumed by ACSS CSS
  but is not necessarily represented or derivable from the settings export.
* A source dependency is a variable, class, asset, or runtime dependency
  encountered later while parsing a Bricks component. The later Stage A
  dependency-reporting pipeline must preserve and report it even when no
  canonical TokenSet resolution exists.

`--neutral-ultra-dark-trans-60` is the first concrete example of the second
and third categories. The approved 4.0.1 evidence proves the name is part of
the ACSS utility vocabulary but does not prove its generated value. Phase 3
therefore does not create a transparency token for it, include it in
`hero_foundation`, or invent a color expression.

## Canonical token coverage

The mapping emits 76 tokens. It is one explicit mapping table; raw
Automatic.css setting names are not the canonical API.

### Colors (27)

~~~text
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
color.black
color.white
color.text.dark
color.text.light
color.background.ultra_dark.text
color.background.ultra_dark.heading
~~~

Direct hex colors remain direct. Proven HSL channel triples are rendered as a
bounded-precision hsl(H S% L%) value while preserving the raw channel map.

### Spacing and radius (16)

~~~text
spacing.base.min
spacing.base.max
spacing.scale.xs
spacing.scale.s
spacing.scale.medium
spacing.scale.l
spacing.scale.xl
spacing.scale.xxl
spacing.content_gap
spacing.grid_gap
spacing.container_gap
spacing.section
spacing.section.padding_block
spacing.gutter.min
spacing.gutter.max
radius.base
~~~

The standard ACSS spacing scale is derived from one F01 input bundle:

| Derived input | ACSS setting |
| --- | --- |
| `mobile_base` | `base-space-min` |
| `desktop_base` | `base-space` |
| `mobile_scale` | `mob-space-scale` |
| `desktop_scale` | `space-scale` |
| `viewport_min` | `vp-min` |
| `viewport_max` | `vp-max` |

Automatic.css uses M as the base. It multiplies M by the corresponding scale
for sizes above M and divides M by that scale for sizes below M. LiveFrames
applies the mobile scale to the mobile base and the desktop scale to the
desktop base, then uses the existing `FluidClamp` viewport interpolation.
The scale outputs are:

| ACSS variable | Canonical TokenSet path | Endpoint formula |
| --- | --- | --- |
| `--space-xs` | `spacing.scale.xs` | `M / scale²` |
| `--space-s` | `spacing.scale.s` | `M / scale` |
| `--space-m` | `spacing.scale.medium` | `M` |
| `--space-l` | `spacing.scale.l` | `M × scale` |
| `--space-xl` | `spacing.scale.xl` | `M × scale²` |
| `--space-xxl` | `spacing.scale.xxl` | `M × scale³` |

`spacing.scale.medium` and `spacing.scale.xl` retain their existing public
paths. The four added paths use the ACSS suffixes `xs`, `s`, `l`, and `xxl`.
Each token keeps the `acss.clamp` recipe, all six inputs, its references, the
resolved relationship, a deterministic CSS expression, and a calculated
output alias. The alias authority IDs follow
`automatic-css-4.0.1:calculated-variable-group:spacing:<suffix>` for all six
variables. Contextual gaps retain semantic references to the scale tokens.
The spacing and section values preserve their respective ACSS clamp inputs.

### Typography (9)

~~~text
typography.body.base_size
typography.body.scale
typography.body.scale.medium
typography.body.line_height
typography.heading.base_size
typography.heading.scale
typography.heading.scale.h1
typography.heading.line_height
typography.heading.font_weight
~~~

Base sizes are responsive pairs from the demonstrated mobile and desktop
settings. Line-height expressions remain source CSS expressions. Heading font
weight uses the exported `heading-weight` setting when present, otherwise the
Automatic.css SCSS default `700`.

### Primary button (21)

~~~text
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
~~~

Button font size, radius, border, and outline relationships retain their
semantic targets. Known pixel settings are normalized to pixel strings only
when the source setting is proven numeric.

### Layout (3)

~~~text
layout.viewport.min
layout.viewport.max
layout.breakpoint.auto_grid
~~~

The auto-grid breakpoint is emitted only from the explicit numeric
auto-staggered-grid-breakpoint setting.

## Strict required-token profile

Strict mode is requirement-driven rather than “all known settings must
resolve”. The initial profile is:

~~~elixir
profile: :hero_foundation
~~~

It requires these 43 paths:

~~~text
color.primary
color.primary.hover
color.primary.light
color.primary.ultra_dark
color.neutral
color.neutral.ultra_dark
color.background.ultra_dark
color.background.ultra_dark.text
color.background.ultra_dark.heading
color.text.light
color.white
spacing.base.min
spacing.base.max
spacing.content_gap
spacing.gutter.min
spacing.gutter.max
typography.body.base_size
typography.body.line_height
typography.heading.base_size
typography.heading.line_height
typography.heading.font_weight
button.primary.background
button.primary.background_hover
button.primary.text
button.primary.border
button.primary.border_width
button.primary.border_style
button.primary.focus
button.primary.radius
button.primary.padding_inline
button.primary.padding_block
button.primary.min_width
button.primary.font_size
button.primary.font_weight
button.primary.line_height
button.primary.outline.background
button.primary.outline.background_hover
button.primary.outline.border
button.primary.outline.border_hover
button.primary.outline.focus
button.primary.outline.text
button.primary.outline.text_hover
layout.viewport.min
layout.viewport.max
~~~

With strict: true, every required path must exist and have
resolution_status: resolved. Missing or unresolved unrelated tokens do not
fail this profile. No fallback values are inserted.

## Icon authority (Automatic.css 4.0.1)

Icon semantic tokens are emitted only when the exported setting `option-icons`
is exactly `"on"`. When the gate is `"off"`, missing, or any other value, no
`icon.*` paths are normalized. Gated icon settings are still recognized so they
do not inflate `acss.setting.unknown` diagnostics.

Canonical paths use the `icon.*` namespace and the `:icon` token category.
Each mapped path is backed by a proven chain from the DanBricks fixture
settings to ACSS 4.0.1 icon SCSS (`modules/icons`) and the effective
`automatic-variables.css` `--icon-*` custom properties. Null SCSS map entries
are not invented: omitted variables such as `--icon-shadow` and list offsets
stay absent when the configured project does not emit them.

| LiveFrames path | ACSS setting | Generated CSS (when emitted) |
| --- | --- | --- |
| `icon.scheme` | `icon-default-scheme` | `--icon-scheme` |
| `icon.size.default` | `icon-size` or SCSS fallback `icon-size-m` | `--icon-size` |
| `icon.padding.default` | `icon-padding` | `--icon-padding` |
| `icon.radius` | `icon-radius` | `--icon-radius` |
| `icon.background` | `icon-background` | `--icon-background` |
| `icon.background_hover` | `icon-background-hover` | `--icon-background-hover` |
| `icon.border.color` | `icon-border-color` | `--icon-border-color` |
| `icon.border.color_hover` | `icon-border-color-hover` | `--icon-border-color-hover` |
| `icon.border.width` | `icon-border-width` | `--icon-border-width` |
| `icon.border.style` | `icon-border-style` | `--icon-border-style` |
| `icon.color` | `icon-color` | `--icon-color` |
| `icon.color_hover` | `icon-color-hover` | `--icon-color-hover` |
| `icon.list.icon_size` | `icon-list-icon-size` | `--icon-list-icon-size` |
| `icon.list.gap` | `icon-list-gap` | `--icon-list-gap` |
| `icon.size.{xs,s,m,l,xl}` | `icon-size-*` | `--icon-size-*` |
| `icon.padding.{xs,s,m,l,xl}` | `icon-padding-*` | `--icon-padding-*` |

Proven semantic references (for example `icon.radius` → `radius.base`,
`icon.padding.{xs..xl}` → `icon.padding.default`, `icon.color_hover` →
`color.primary`) preserve TokenSet reference relationships instead of
duplicating literals. Other effective project values remain literal CSS
expressions when no canonical target is mapped.

**2XL evidence gap:** the fixture still exports `icon-size-2xl` and
`icon-padding-2xl`, and frontend CSS references `.icon--2xl`, but the audited
DanBricks `automatic-variables.css` snapshot does not emit
`--icon-size-2xl` or `--icon-padding-2xl`. C-08A therefore omits
`icon.size.2xl` and `icon.padding.2xl` rather than fabricating values.

`:hero_foundation` does not require any `icon.*` paths.

## Unknown settings and diagnostics

Unknown Automatic.css settings are expected. The adapter ignores them for
canonical output and emits one informational acss.setting.unknown diagnostic
with a total and at most ten sorted sample keys. The approved fixture currently
has 2,471 unknown settings after the supported source keys are accounted for.

Diagnostics are deterministic and machine-readable. The initial namespaces
include:

~~~text
acss.source.invalid
acss.source.json_invalid
acss.setting.invalid
acss.setting.unknown
acss.mapping.conflict
acss.value.unresolved
tokens.version.unsupported
tokens.path.duplicate
tokens.reference.missing
tokens.reference.cycle
tokens.required.missing
tokens.required.conflict
~~~

Expected malformed input returns diagnostics instead of crashing. Strict
required-token failures combine adapter diagnostics with generic TokenSet
validation diagnostics.

## Breakpoints and unresolved values

Numeric viewport and auto-grid values are resolved from explicit source
settings. A source label without a proven threshold would remain an
unresolved source candidate; the adapter never invents tablet or mobile
defaults. The fixture does not produce generic tablet/mobile token paths.

The fixture's `var(--black)` and `var(--white)` text values are proven
relationships to the ACSS 4.0.1 BW foundation. `color.text.dark` references
`color.black`, and `color.text.light` references `color.white`; both preserve
their original expressions and resolve to the generated foundation expression
when the fixture's `auto-color-scheme` setting is enabled. The
ultra-dark-background text and heading settings likewise reference
`color.text.light`. CSS variable references are never evaluated beyond a
proven semantic relationship.

The Hero source's
`var(--overlay-bg, var(--neutral-ultra-dark-trans-60))` remains outside this
TokenSet. `--overlay-bg` is a later source-level override, while the ACSS
transparency variable cannot be derived from the approved settings/reference
inputs. The later Bricks Stage A pipeline owns preserving and reporting that
unresolved source dependency.

## Validation and serialization

LiveFrames.Tokens validates the generic contract without knowing anything
about Automatic.css or Bricks. It checks the supported version, path format,
categories, statuses, JSON-safe metadata, provenance, duplicate paths,
reference targets, cycles, and strict required paths.

LiveFrames.Tokens.encode/2 and encode!/2 serialize TokenSets separately from
Design IR. They explicitly convert structs, recursively sort JSON object keys,
preserve list order, and emit stable token/diagnostic fields. Equivalent
source maps produce bytewise-identical serialized output.

## Security and scaling classification

The adapter treats JSON as untrusted data. It does not execute PHP, JavaScript,
CSS, shell commands, or source-provided modules; it does not access paths
embedded in JSON or make network calls; and it does not turn source strings
into atoms. It is pure/stateless and safe for parallel conversion jobs.

This is compile-time/static normalization. The fixture is small enough for a
normal JSON decode, so no streaming parser, runtime cache, database, Redis,
ETS, GenServer, queue, or external service is introduced. Generated token
artifacts may be cached by later consumers, but this adapter owns no runtime
cache.

## Known limitations and stop boundary

Phase 3 normalizes only this initial semantic subset. It does not claim full
Automatic.css compatibility and does not reconstruct arbitrary utility
classes. In particular, it does not implement:

* Bricks parsing, tree reconstruction, or class resolution;
* Hero/India conversion or Design IR generation;
* HEEx, LiveView components, or generated CSS;
* Tailwind theme/configuration or an SCSS bridge;
* a complete Automatic.css typography, color, responsive, or utility engine;
* breakpoint reconciliation between Automatic.css and Bricks.

ACSS classes and ACSS settings remain separate concepts. Utility-class lookup is
deferred to the later Bricks integration phase.
