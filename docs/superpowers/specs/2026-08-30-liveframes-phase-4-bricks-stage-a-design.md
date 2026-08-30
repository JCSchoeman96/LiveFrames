# LiveFrames Phase 4 Bricks Stage A design

## Status

Approved for implementation on 2026-08-30.

The Phase 3 merge baseline is `eb67286e128526d0a746f8098cfd750cd5f167f2`.
PR #3 is merged into `main`. The Phase 4 worktree is based directly on that
commit.

## Goal

Build the first source-specific Bricks adapter for the approved Hero India
copied-elements fixture. The adapter will recognize and validate the Bricks
envelope, resolve the `sqhmmc` component proxy, rebuild its flat element list
as an ordered source tree, preserve classes and source settings, extract
dependencies, and render deterministic Stage A HTML, CSS, and a machine-
readable report.

The Stage A boundary is deliberate. This work preserves source truth so a
later phase can decide how to normalize it. It does not create a Design IR
document, a LiveFrames component, HEEx, Tailwind classes, or Storybook content.

## Scope and boundaries

The adapter lives under `LiveFrames.Adapters.Bricks` and owns interpretation
of Bricks input only. It does not define LiveFrames component semantics, alter
Design IR `1.0.0`, alter TokenSet `1.0.0`, or add Bricks, WordPress,
Automatic.css, or runtime dependencies.

The committed input is
`fixtures/bricks/bricks_components.json`. Its envelope is
`bricksCopiedElements`, its payload version is `2.3.1`, and its Hero India
component is `sqhmmc` with component version `2.3.5`. The source includes 39
content proxies/components and 468 global class records. The duplicate copy
under `sources/bricks_components.json` is provenance evidence, not a second
input source.

Stage A artifacts are committed at:

```text
sources/work/hero_india/stage_a/index.html
sources/work/hero_india/stage_a/styles.css
sources/work/hero_india/stage_a/report.json
```

The adapter and frozen generation options, rather than those files, remain
the authority. The artifacts are reviewable evidence and must regenerate
byte-for-byte.

## Pipeline

The public façade coordinates small pure stages:

```text
JSON bytes
  -> decode and recognize
  -> validate the source envelope and collections
  -> resolve the requested component proxy
  -> validate and build the ordered flat-element tree
  -> collect classes, settings, variables, assets, and runtime dependencies
  -> render Stage A HTML, CSS, and report bytes
  -> optionally write the three artifacts
```

The lifecycle is represented in the result data, not in a process or runtime
workflow:

```text
received -> recognized -> validated -> resolved -> tree_built
         -> dependencies_extracted -> rendered -> verified -> completed
```

Expected source and validation failures end at `rejected`. Unexpected renderer
or filesystem failures end at `failed`. A result carries the furthest status,
the partial source-specific data that is safe to retain, and sorted
diagnostics.

The public operations are:

```elixir
LiveFrames.Adapters.Bricks.from_file(path, opts)
LiveFrames.Adapters.Bricks.from_json(json, opts)
LiveFrames.Adapters.Bricks.StageA.generate_from_file(path, opts)
LiveFrames.Adapters.Bricks.StageA.generate(source, opts)
LiveFrames.Adapters.Bricks.StageA.verify_drift(opts)
```

`from_file/2` and `from_json/2` expose the recognized, validated source model.
`StageA.generate_from_file/2` is the stable end-to-end entry point used by the
Mix task. The Mix task only parses command options, loads the already-built
Phase 3 TokenSet from its approved fixture, and delegates to this API.

## Source-specific model

The model stays small and source-specific:

- `BricksDocument` stores envelope metadata, independent payload/component
  versions, content proxies, component lookup data, global class lookup data,
  source labels, and adapter metadata.
- `BricksComponent` stores the component ID, `_version`, category, description,
  properties, and its ordered raw element records.
- `BricksElement` stores the source ID, Bricks type, parent ID, declared child
  IDs, label, settings, and the raw JSON object for unsupported fields.
- `BricksGlobalClass` stores the source class ID, class name, category, local
  settings, and raw JSON metadata.
- `BricksTree` stores the element lookup map, ordered root IDs, and ordered
  child-ID lists. It does not duplicate elements into a second universal AST.
- `SourceDependency` stores dependency kind, status, raw source expression,
  source location, and structured metadata.
- `BricksDiagnostic` stores severity, stable code/category, message, source
  path or ID, and JSON metadata.
- `StageA.Result` stores lifecycle status, selected source/component/tree,
  dependencies, artifact bytes/paths, and diagnostics.

No model converts a `BricksElement` into a `DesignNode`. The adapter's source
IDs remain source identity and are not public LiveFrames component IDs.

## Recognition, versions, and component resolution

Recognition requires a JSON object with the tested source marker
`source = "bricksCopiedElements"`, a non-empty string `sourceUrl`, a
non-empty string `version`, a list `content`, a list `components`, and a list
`globalClasses`. The loader decodes JSON with Jason and never evaluates source
strings.

The loader records these values independently:

```json
{
  "payload_version": "2.3.1",
  "component_version": "2.3.5",
  "adapter_version": "1.0.0",
  "stage_a_schema_version": "1.0.0"
}
```

The exact tested payload version is accepted. An unknown payload version is
rejected by default, or can be parsed only with an explicit experimental
option that emits a warning. The component version is preserved separately;
its difference from the payload version is expected and is not normalized.

The Stage A command freezes `component_id = "sqhmmc"`. The resolver finds the
matching content proxy and then the matching component record. It rejects a
missing `cid`, missing component, duplicate/ambiguous component ID, or
malformed resolved component. A generic API call without a component ID only
auto-selects when exactly one proxy is present. It never selects the first
unrelated component from a multi-component export.

## Tree reconstruction and validation

The component's `elements` list is the ordered source collection. The builder
creates an ID map in one pass and then validates relationships with map and
set lookups:

- every ID is a non-empty string and unique;
- each parent is the root marker (`0`, `"0"`, or `nil`) or an existing ID;
- every declared child exists;
- a child appears at most once in each declared child list;
- a child is not its own ancestor and parent chains contain no cycles;
- each parent pointer and declared child list are reciprocal;
- roots are retained in source-list order and child order is retained exactly.

The approved fixture has one root, `sqhmmc`, with children `2ef2fa` and
`1c85d9`. Any contradiction returns a structured error. The adapter does not
silently repair a malformed source tree, even though Bricks tooling may use
parent pointers to rebuild children in other contexts.

## Supported elements and HTML

The first supported set is exactly the set demonstrated by Hero India:
`section`, `container`, `div`, `heading`, `text-basic`, `button`, and `image`.
Unsupported element records remain in the source model/report and receive a
`bricks.element.unsupported` diagnostic. They are rendered as an explicit,
escaped preservation element only when their shape is safe; otherwise the
pipeline stops before rendering.

The renderer maps proven source semantics only:

- `section` renders as `section`.
- `container` and `div` render as `div` because the fixture provides Bricks
  structural types rather than a more specific HTML tag.
- `heading` uses the validated source `tag`, which is `h1` in Hero India.
- `text-basic` uses the validated source `tag`, which is `p` in Hero India.
- `button` renders as a `button` when no link setting exists. A validated link
  setting may render an anchor without inventing an `href`.
- `image` with source `tag = "figure"` renders a figure containing an image.

Text and attributes are escaped. Source text is never treated as trusted raw
HTML. An unresolved image URL uses the deterministic `about:blank` placeholder
only in Stage A HTML; the report retains attachment ID `880`, filename, and
the unresolved status. The placeholder is not presented as the source asset.

The renderer appends deterministic `bricks-element--<source-id>` scope classes
for source-local CSS targeting. They are Stage A implementation details and
are not a public component API. Source/global class names remain in their
original order. Button `style` and `outline` settings preserve the proven
`btn--primary` and `btn--outline` ACSS class names.

## Classes and settings

`_cssGlobalClasses` is a list of class IDs. The resolver maps each ID through
the global class lookup and records the ID, name, category, settings, and
element source path. Missing class IDs remain unresolved dependencies and are
diagnosed. An empty ACSS class record is still meaningful as a source class;
the adapter does not invent its CSS declarations.

The CSS renderer uses one explicit mapping table for the settings required by
the fixture:

| Bricks key | CSS output |
| --- | --- |
| `_position` | `position` |
| `_isolation` | `isolation` |
| `_rowGap`, `_columnGap` | `row-gap`, `column-gap` |
| `_alignItems`, `_justifyContent` | `align-items`, `justify-content` |
| `_zIndex` | `z-index` |
| `_margin` | side-specific margin declarations when values are valid CSS |
| `_width`, `_widthMax`, `_height` | `width`, `max-width`, `height` |
| `_display`, `_flexWrap`, `_direction` | matching flex/display properties |
| `_top`, `_right`, `_bottom`, `_left` | matching inset properties |
| `_border` radius data | side-specific border-radius declarations |
| `_objectFit`, `_objectPosition` | matching object properties |
| `_background` color raw value | `background` |
| `_gradient` | validated linear-gradient output |

Keys with a Bricks breakpoint suffix are collected as responsive entries.
Base custom CSS is retained as source CSS. Responsive custom CSS is retained
with its source breakpoint and is not activated without a proven threshold.
Unknown keys and malformed supported values stay in the report and produce
`bricks.setting.unsupported` or value diagnostics.

The fixture's `_margin.top = "400"` has no unit in the accepted source
evidence. The adapter preserves the raw value and emits an unresolved-value
diagnostic instead of guessing `px`. Explicit units, CSS keywords such as
`auto`, and zero are rendered when valid. This keeps the ambiguity visible for
the later source-authority decision.

## Responsive policy

The parser splits suffixes such as `:tablet_portrait` and records the raw
breakpoint name, affected property, raw value, and source trace. The Hero
fixture proves `tablet_portrait` for object fit, object position, and gradient,
and `mobile_portrait` for CTA custom CSS.

No standard breakpoint threshold is inferred. Since the accepted fixture has
no authoritative threshold, the CSS contains deterministic explanatory source
comments/raw preservation for those entries, while `report.json` records
`resolution_status = "unresolved"`, `min_width = null`, and `max_width = null`.
If a future source supplies a numeric threshold, only that explicit value may
produce a media query.

## Dependencies and TokenSet interaction

The dependency collector extracts:

- applied source/global classes and ACSS class names;
- CSS variable references, including nested fallback expressions;
- responsive source entries;
- custom CSS;
- image attachment references;
- interaction, dynamic-data, query-loop, browser-runtime, external-script,
  and unsupported-feature settings when present.

Variable dependencies use these statuses:

- `resolved_token` when an explicit mapping exists and the supplied TokenSet
  contains the target path;
- `source_variable` when the source expression is preserved but no canonical
  mapping applies;
- `unresolved_external` when the source names an external or unproven value.

The only initial variable mapping is the proven
`--content-gap -> spacing.content_gap` relationship from the Phase 3
contract. The Hero expression
`var(--overlay-bg, var(--neutral-ultra-dark-trans-60))` preserves both
`--overlay-bg` and `--neutral-ultra-dark-trans-60` as unresolved source
dependencies. The adapter never invents a transparency value and never
mutates the TokenSet.

## Stage A artifacts and regeneration

`LiveFrames.Adapters.Bricks.StageA.generate/2` produces bytes for exactly
`index.html`, `styles.css`, and `report.json`. The HTML and CSS begin with a
generated-file comment. The report stores generator/schema metadata instead of
a comment.

The stable command is:

```text
mix live_frames.bricks.stage_a
```

Its frozen defaults are the approved Bricks fixture, component `sqhmmc`, the
approved ACSS settings fixture, and
`sources/work/hero_india/stage_a`. It accepts explicit switches for source,
component, ACSS source, and output directory. The task performs no parsing,
rendering, dependency extraction, or report construction.

`StageA.verify_drift/1` generates into a caller-created temporary directory,
checks the three expected files byte-for-byte against the committed artifact
directory, and fails for a missing, different, or unexpected generated file.
Normal tests never rewrite the committed artifacts. Two successive generations
must be byte-identical.

## Report contract

The report is recursively key-sorted JSON. It contains:

- report/schema, adapter, and source version metadata;
- logical source label, source hash, component ID, label, and category;
- lifecycle status, root IDs/count, element count, supported/unsupported
  counts, and deterministic element source trace;
- full source/global class count and applied class provenance;
- ACSS class dependencies;
- consumed settings, unsupported settings, and custom CSS records;
- responsive entries and resolved/unresolved breakpoint counts;
- CSS variable dependencies and TokenSet resolutions;
- assets and unresolved asset records;
- interaction/dynamic dependencies;
- diagnostics grouped by severity as well as the ordered diagnostic records.

The report includes no timestamps, random IDs, process IDs, host data, absolute
paths, or environment-dependent ordering. Report arrays use source order where
source order has meaning and stable lexical ordering elsewhere.

## Failure handling and security

Malformed JSON, wrong envelopes, missing collections, missing/ambiguous
components, duplicate IDs, missing relationships, reciprocity errors, cycles,
unsupported elements, malformed values, unknown breakpoints, missing image
URLs, unresolved variables, and runtime/dynamic settings receive structured
diagnostics. The pipeline never drops an unsupported value without either
retaining it or reporting why it cannot render.

The loader treats all source values as untrusted. It does not evaluate
JavaScript, PHP, CSS, shell syntax, or source-provided modules. It does not
follow paths from JSON, make network requests, fetch assets, create dynamic
atoms, or load runtime plugins. CSS selectors and HTML values are escaped or
validated before interpolation. Custom CSS is copied as source text only; it
is not parsed for execution by the adapter.

The conversion is stateless and uses maps, ordered lists, and sets. It adds no
ETS, GenServer, database, queue, cache, or network service.

## Verification

Focused tests cover recognition, component resolution, every tree failure
mode, supported Hero element rendering, representative settings, responsive
suffix preservation without invented thresholds, custom CSS, class and ACSS
provenance, TokenSet resolution/unresolved variables, unresolved assets,
dynamic-feature diagnostics, escaping, deterministic output, and drift
detection. The full repository suite and required Mix quality gates run before
the branch is published.

The final Phase 4 stop boundary is the verified Stage A artifact set. Design
IR generation, Hero componentization, HEEx, Tailwind normalization, Storybook
catalogue work, and Phase 5 remain unstarted.
