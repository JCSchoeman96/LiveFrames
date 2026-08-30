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
so normalized metadata records:

~~~json
{
  "source_version": "4.0.1",
  "source_version_status": "fixture_reference",
  "export_version": null,
  "source_shape": "flat_settings_map"
}
~~~

source_version is the reference-set version; export_version remains explicitly
absent. The adapter accepts only a flat JSON object with non-empty string keys,
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
| metadata | Non-authoritative calculation or source details |

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

## Canonical token coverage

The initial mapping emits 67 tokens. It is one explicit mapping table; raw
Automatic.css setting names are not the canonical API.

### Colors (23)

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
color.text.dark
color.text.light
~~~

Direct hex colors remain direct. Proven HSL channel triples are rendered as a
bounded-precision hsl(H S% L%) value while preserving the raw channel map.

### Spacing and radius (12)

~~~text
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
~~~

The spacing scale and section values preserve the ACSS clamp relationship and
its base, scale, adjustment, and viewport inputs. Contextual gaps retain
semantic references to those derived tokens.

### Typography (8)

~~~text
typography.body.base_size
typography.body.scale
typography.body.scale.medium
typography.body.line_height
typography.heading.base_size
typography.heading.scale
typography.heading.scale.h1
typography.heading.line_height
~~~

Base sizes are responsive pairs from the demonstrated mobile and desktop
settings. Line-height expressions remain source CSS expressions.

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

It requires these 29 paths:

~~~text
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
~~~

With strict: true, every required path must exist and have
resolution_status: resolved. Missing or unresolved unrelated tokens do not
fail this profile. No fallback values are inserted.

## Unknown settings and diagnostics

Unknown Automatic.css settings are expected. The adapter ignores them for
canonical output and emits one informational acss.setting.unknown diagnostic
with a total and at most ten sorted sample keys. The approved fixture currently
has 2,476 unknown settings after the supported source keys are accounted for.

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
~~~

Expected malformed input returns diagnostics instead of crashing. Strict
required-token failures combine adapter diagnostics with generic TokenSet
validation diagnostics.

## Breakpoints and unresolved values

Numeric viewport and auto-grid values are resolved from explicit source
settings. A source label without a proven threshold would remain an
unresolved source candidate; the adapter never invents tablet or mobile
defaults. The fixture does not produce generic tablet/mobile token paths.

The fixture's var(--black) and var(--white) text values have no proven source
token in the supported subset, so color.text.dark and color.text.light
preserve their expressions with resolution_status: unresolved. CSS variable
references are never evaluated or replaced with invented literals.

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
