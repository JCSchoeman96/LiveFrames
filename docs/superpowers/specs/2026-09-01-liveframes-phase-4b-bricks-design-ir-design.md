# LiveFrames Phase 4B Bricks Design IR Design

## Goal

Normalize the approved, structured Hero India Bricks component and the
validated Phase 3 TokenSet into a valid, deterministic Design IR `1.0.0`
document. This phase ends at serialized IR evidence; it does not generate
HEEx, Tailwind output, native components, or Storybook content.

## Frozen boundaries

The existing Design IR `1.0.0` and TokenSet `1.0.0` contracts remain
unchanged. The normalizer consumes the structured Bricks pipeline:

```text
Loader → Resolver → TreeBuilder → ClassResolver → Settings/DependencyExtractor
  → Design IR normalizer → IR validator → IR serializer
```

The normalizer never reads Stage A HTML, CSS, or `report.json`, and it never
evaluates source PHP, JavaScript, CSS, or remote assets. The Stage A files are
review evidence only.

## Public boundary and result

`LiveFrames.Adapters.Bricks.to_ir/2` is the only public Bricks-to-IR entry
point. It accepts the approved source path, a JSON/map source, or an already
recognized Bricks `Document`; it accepts `component_id` and a validated
`TokenSet` through options. It returns `{:ok, %DesignDocument{}}` only after
strict source checks and `LiveFrames.IR.validate/1` succeed, or
`{:error, diagnostics}` without serializing an invalid document.

The document provenance contains the complete pure normalization lifecycle:

```text
source_model_ready → token_set_bound → nodes_normalized → styles_normalized
→ responsive_normalized → dependencies_bound → document_assembled
→ ir_validated → serialized → drift_verified → completed
```

`needs_review` and `failed` are documented exceptional states. The normalizer
does not use a process or persistent workflow; errors/fatals stop the
conversion.

## Source-to-IR mapping

Semantic type is established from the structured Bricks element name and
direct source evidence only. Source class names are provenance, never a basis
for a `HeroIndia` or other native component semantic.

| Source ID | Bricks source | Design IR type | Evidence |
| --- | --- | --- | --- |
| `sqhmmc` | `section` | `section` | Direct structural source type |
| `2ef2fa` | `container` | `container` | Direct structural source type |
| `561d75` | `heading` with `tag: h1` | `heading` | Direct content source type and heading tag |
| `3f6ee6` | `text-basic` with `tag: p` | `paragraph` | Paragraph tag proves the generic text element's meaning |
| `8ae908` | structural `div` | `generic` | No independent IR-native intent is required or guessed |
| `8ca7e4` | `button` | `button` | Direct content source type |
| `7ea788` | `button` | `button` | Direct content source type |
| `1c85d9` | structural `div` | `generic` | Background class remains source provenance |
| `a1745a` | `image` | `image` | Direct asset-bearing source type |
| `be2b65` | structural `div` | `generic` | Overlay class remains source provenance |

The source tree's root and child order are retained. Every node receives the
existing traversal ID (`node_000001`, `node_000001_000001`, and so on), while
the original Bricks ID remains in `SourceTrace.source_id`.

Text nodes retain the exact source text in `content`; proven tags and button
settings are retained in `attributes` or the source trace. Image attachment
evidence is kept in the asset registry and referenced by the image node.

## Loss-preserving styles

The existing `Settings.extract/1` result is the style source. Each base style
is represented by a tagged `StyleValue`; unresolved values are not dropped.

- plain safe CSS values are `literal` or `keyword` according to their proven
  CSS meaning;
- `calc(...)` and `clamp(...)` expressions are `calculation`;
- exact `var(--content-gap)` is `token_ref("spacing.content_gap")` with the
  original expression retained;
- `var(--content-gap, 30px)` remains an `unresolved` value with the complete
  expression and token/fallback metadata, because the frozen style contract
  has no combined token-plus-fallback variant;
- `var(--overlay-bg, var(--neutral-ultra-dark-trans-60))` remains a complete
  `unresolved` value and both variable names remain represented in diagnostics
  and dependency metadata;
- gradients and custom CSS use `complex_css` JSON objects containing their raw
  source values, property, source key, and rules; gradient angle, stops, IDs,
  colors, and responsive variants are never simplified;
- the bare `_margin.top` value `"400"` is an `unresolved` `margin-top` style
  with raw value `"400"`; no unit is invented.

## Responsive normalization

The four structured responsive records are grouped by source node and source
breakpoint into `ResponsiveOverride` entries. The two source names remain
exactly `mobile_portrait` and `tablet_portrait`, each override has
`min_width: nil`, `max_width: nil`, and `resolution_status: :unresolved`, and
each retains a source trace. No framework breakpoint or ACSS auto-grid value is
introduced.

## Registries, diagnostics, and tokens

The image creates one deterministic asset registry entry with `uri: nil` and
`:unresolved` status. Attachment ID `880`, filename, original `url: false`,
alt, dimensions, and source node are preserved in metadata and trace. The
image node references the registry entry. The interaction registry stays
empty because the structured source proves no runtime interaction.

The eight Stage A warnings are mapped to valid IR diagnostic categories while
retaining their source code, raw value, source ID/path, and message:

```text
unitless margin;
four unresolved responsive thresholds;
two unresolved CSS variables;
one unresolved image asset.
```

The validated TokenSet is embedded as the JSON object returned by
`LiveFrames.Tokens.to_map/1`, unchanged and independently versioned.

## Evidence and tests

The Mix task `mix live_frames.bricks.design_ir` loads the approved Bricks and
ACSS fixtures, calls `Bricks.to_ir/2`, and writes the Design IR serializer
output to `sources/work/hero_india/design_ir/design_document.json`. It contains
no normalization logic. Drift tests generate only into a temporary directory
and byte-compare the committed file; tracked output is never modified by a
normal test.

Focused tests cover structure, source traces, IDs, all semantic mappings,
every tagged style kind in evidence, gradients, fallback/nested variables,
the raw unitless value, responsive names and nil thresholds, asset and empty
interaction registries, diagnostics, validator success, deterministic JSON,
and committed-artifact drift. Existing Phase 0–4A tests and all repository
gates remain required.

## Explicit stop boundary

This design does not add a HEEx generator, Tailwind normalization, Hero
function component, Storybook Hero, downloaded asset, Design IR schema field,
TokenSet schema field, or Phase 5 implementation.
