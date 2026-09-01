# Bricks Stage A source adapter

Phase 4 is the source-extraction boundary for Bricks copied-elements data. It
recognizes and preserves Bricks source truth for later normalization; it does
not define LiveFrames component semantics.

The public boundary is `LiveFrames.Adapters.Bricks`. Its implementation is
source-specific and has no dependency on WordPress, the Bricks runtime,
Automatic.css runtime code, a database, a queue, or a network service.

## Recognized payload

The approved fixture is
`fixtures/bricks/bricks_components.json`. It has the copied-elements marker
`source = "bricksCopiedElements"`, source URL
`http://localhost:10049`, payload version `2.3.1`, 39 content proxies, 39
components, and 468 global class records.

The loader requires the marker, a non-empty source URL and version, and list
values for `content`, `components`, and `globalClasses`. JSON is decoded as
data with Jason. It is never evaluated as JavaScript, PHP, CSS, or a module.
The tested payload version is accepted by default. An unknown version is
rejected unless `allow_unknown_version: true` is explicitly supplied; that
experimental path keeps a warning in the result.

The loader records a logical source label and SHA-256 of the input bytes. It
never places an absolute input path in report data.

Versions remain independent:

| Evidence | Value |
| --- | --- |
| copied payload | `2.3.1` |
| Hero component `_version` | `2.3.5` |
| Bricks adapter | `1.0.0` |
| Stage A schema | `1.0.0` |

## Component proxy resolution

The top-level `content` collection contains proxies, not necessarily the real
element tree. In the approved fixture the Hero proxy is:

```json
{
  "id": "ulsuff",
  "name": "section",
  "cid": "sqhmmc",
  "label": "Hero India"
}
```

The real flat element collection is `components[].elements` for component
`sqhmmc`. `LiveFrames.Adapters.Bricks.resolve/2` resolves `cid` explicitly.
The Stage A command freezes `component_id = "sqhmmc"`. A generic call without
an ID is allowed only when exactly one proxy exists. Missing `cid`, missing
components, duplicate IDs, ambiguous proxy matches, and malformed element
collections return structured diagnostics; the adapter never falls back to an
unrelated component.

## Source tree rules

Bricks elements are a flat ordered collection with `id`, `name`, `parent`,
`children`, `settings`, and optional `label`. The adapter builds an ID map in
one pass and retains the source element order and each declared child order.
It validates:

* unique non-empty element IDs;
* root parents represented by `0`, `"0"`, or `nil`;
* existing parent and child IDs;
* no duplicate child declarations;
* parent/child reciprocity in both directions;
* no self-cycle or longer parent-chain cycle;
* deterministic root order.

Contradictory input is not silently repaired. Multiple roots are retained and
reported as a warning for the generic tree builder. The Hero Stage A pipeline
requires exactly one root and rejects a different count. Hero India has root
`sqhmmc` and 10 elements.

## Supported elements and HTML

The initial supported set is exactly what Hero India demonstrates:
`section`, `container`, `div`, `heading`, `text-basic`, `button`, and `image`.
The renderer maps these to `section`, `div`, validated heading/text tags,
button or validated anchor semantics, and figure/image structure. Source text
and attributes are escaped. Source HTML is never marked trusted.

An unsupported element remains in the source model and report and is rendered
as an explicit escaped preservation element when its shape is safe. It receives
`bricks.element.unsupported`; the adapter does not pretend to support the
entire Bricks element catalogue. Stage A adds deterministic
`bricks-element--<source-id>` scope classes for its own CSS targeting. These
are not public LiveFrames component IDs or APIs.

An image whose source URL is `false` uses `about:blank` only as a deterministic
Stage A placeholder. The report retains the attachment ID, filename, URL
evidence, and unresolved status. The adapter never fetches or invents an
asset URL.

## Classes and settings

`_cssGlobalClasses` IDs are resolved through the copied `globalClasses`
records. HTML retains source class names in source order, and the report
records ID, name, category, element source ID, and provenance. A class record
with category `acss` is preserved as an ACSS dependency; the copied payload is
not treated as a declaration source when its settings are empty. Button
`style` and `outline` settings preserve the demonstrated `btn--primary` and
`btn--outline` class names.

Stage A maps only this deliberate setting subset:

| Bricks setting | Stage A CSS |
| --- | --- |
| `_position`, `_isolation` | same property |
| `_rowGap`, `_columnGap` | `row-gap`, `column-gap` |
| `_alignItems`, `_justifyContent` | `align-items`, `justify-content` |
| `_zIndex` | `z-index` |
| `_width`, `_widthMax`, `_height` | `width`, `max-width`, `height` |
| `_display`, `_flexWrap`, `_direction` | `display`, `flex-wrap`, `flex-direction` |
| `_top`, `_right`, `_bottom`, `_left` | same inset property |
| `_margin` | validated side-specific margin values |
| `_border.radius` | validated corner radius values |
| `_objectFit`, `_objectPosition` | same object property |
| `_background.color.raw` | `background` |
| `_gradient` | validated linear `background-image` |
| `_cssCustom` | preserved source CSS |

Values containing declaration separators, braces, unsafe URL expressions, or
ambiguous units are not executed or guessed. The Hero `_margin.top` value
`"400"` is retained as an unresolved raw value; the adapter does not append
`px`.

Unknown settings and malformed supported values remain in the report and
produce `bricks.setting.unsupported` or a value diagnostic.

## Responsive settings

Keys such as `_objectFit:tablet_portrait`,
`_objectPosition:tablet_portrait`, `_gradient:tablet_portrait`, and
`_cssCustom:mobile_portrait` retain the exact source breakpoint name, raw
value, affected property, source ID, and unresolved threshold status.

The fixture does not prove numeric thresholds. Stage A therefore emits
deterministic explanatory CSS comments and no invented media query. It does
not assume Bootstrap, Tailwind, or another framework breakpoint. A future
numeric threshold may be used only when accepted source authority provides
that threshold.

## Custom CSS and dependencies

Base `_cssCustom` text is copied into `styles.css` and represented with source
trace in `report.json`. Responsive custom CSS is preserved in the report and
as an explanatory source comment until its threshold is authoritative. Custom
CSS is not parsed or executed by the adapter.

Variable references are extracted from supported values and custom CSS,
including nested fallbacks. The only explicit Phase 3 relationship is:

```text
--content-gap -> spacing.content_gap -> resolved_token
```

The TokenSet is read for comparison only and is never mutated. The Hero
expression
`var(--overlay-bg, var(--neutral-ultra-dark-trans-60))` preserves both
`--overlay-bg` and `--neutral-ultra-dark-trans-60` as
`unresolved_external`; the transparency value is not invented.

Image attachment evidence is recorded as an asset dependency. Settings whose
keys identify interactions, dynamic data, query loops, browser runtime,
external scripts, hooks, or another runtime feature are preserved and receive
an unsupported-runtime diagnostic. Phase 4 does not implement those features.

## Lifecycle and diagnostics

The plain `Bricks.Result` status model records:

```text
received -> recognized -> validated -> resolved -> tree_built
         -> dependencies_extracted -> rendered -> verified -> completed
```

Expected input/validation failures are `rejected`; renderer or filesystem
failures are `failed`. No process or workflow service is introduced merely to
represent these states.

Diagnostics have severity `info`, `warning`, `error`, or `fatal`. Current
machine-readable categories include source, component, tree, class, setting,
breakpoint, variable, asset, runtime, and artifact findings. Representative
codes include:
`bricks.source.invalid`, `bricks.component.missing`,
`bricks.component.ambiguous`, `bricks.element.duplicate`,
`bricks.parent.missing`, `bricks.child.missing`, `bricks.tree.cycle`,
`bricks.tree.reciprocity`, `bricks.element.unsupported`,
`bricks.setting.unsupported`, `bricks.breakpoint.unresolved`,
`bricks.variable.unresolved`, and `bricks.asset.unresolved`.

## Stage A artifact contract

The stable regeneration command is:

```text
mix live_frames.bricks.stage_a
```

It accepts `--source`, `--component-id`, `--acss-source`, and `--output-dir`.
Its frozen defaults use the approved Bricks fixture, component `sqhmmc`, the
approved Automatic.css settings fixture for reading the already-defined Phase
3 TokenSet, and:

```text
sources/work/hero_india/stage_a/
```

The Mix task only parses options, loads the canonical TokenSet through the
existing public Phase 3 adapter, and delegates to
`LiveFrames.Adapters.Bricks.StageA.generate_from_file/2`. It contains no
parsing, CSS, dependency, HTML, or report logic.

The committed generated files are:

```text
sources/work/hero_india/stage_a/index.html
sources/work/hero_india/stage_a/styles.css
sources/work/hero_india/stage_a/report.json
```

HTML and CSS contain a generated-file warning. The report stores schema and
generator metadata as JSON. Given identical source bytes, adapter/schema
versions, and generation options, all three files are byte-identical. No
timestamp, process ID, host, random ID, absolute path, or environment value is
generated.

`StageA.verify_drift/1` regenerates into a caller-provided temporary directory
and compares exactly those three filenames. Missing, different, and
unexpected files are structured errors. Normal tests never write the
committed output directory.

## Stage A stop boundary

Stage A stops at faithful source HTML, CSS, dependencies, diagnostics, report,
and deterministic artifacts. The Stage A artifacts are evidence for review.
They are not input to the Design IR normalizer.

## Phase 4B Design IR normalization

Phase 4B crosses the source-specific boundary with one public function:

    LiveFrames.Adapters.Bricks.to_ir(source, token_set: token_set, component_id: "sqhmmc")

source may be the recognized Bricks.Document, a structured source map, JSON
text, or a source file path. The function runs the existing Loader, Resolver,
TreeBuilder, ClassResolver, Settings, and DependencyExtractor stages, then
assembles and validates a DesignDocument with IR version 1.0.0. It does not
parse index.html, styles.css, or report.json.

The approved Hero mapping is deliberately small:

| Bricks source element | Design IR semantic type |
| --- | --- |
| section | section |
| container | container |
| div | generic |
| heading | heading |
| text-basic with tag = "p" | paragraph |
| button | button |
| image | image |

Source class names remain in SourceTrace and dependency provenance. Names such
as fr-hero-india__content-wrapper do not become LiveFrames-native component
types.

The normalizer uses the existing StyleValue kinds. Safe values become literal
or keyword values, calc and clamp expressions become calculations, and the
proven var(--content-gap) relationship becomes the TokenSet path
spacing.content_gap. Fallback expressions retain their fallback metadata.
Nested overlay variables and the unitless source value "400" remain
unresolved. Gradients and custom CSS use complex_css with their source values
intact. No style is silently dropped.

Responsive overrides retain mobile_portrait and tablet_portrait as both
breakpoint_id and source_name. Their min_width and max_width remain nil, and
their resolution status is unresolved. The normalizer does not invent
framework breakpoint values.

The document embeds the JSON object produced by the existing Phase 3 TokenSet
serializer. It creates one unresolved image asset registry entry for
attachment 880, with the image node referring to that entry. The source URL
remains unresolved. Buttons do not create interaction records, so the Hero
interaction registry is empty.

Every source element receives a SourceTrace, including its source path, source
ID, source classes, settings, adapter version, and normalization inference.
Design node IDs come from the existing one-based traversal helper, for example
node_000001; Bricks IDs remain trace data only. The document retains the source
diagnostics, including the four unresolved responsive thresholds, two
unresolved external variables, unitless "400", and unresolved image asset.

The normalization lifecycle recorded in provenance is:

    source_model_ready -> token_set_bound -> nodes_normalized
    -> styles_normalized -> responsive_normalized -> dependencies_bound
    -> document_assembled -> ir_validated -> serialized -> drift_verified
    -> completed

The regeneration command is:

    mix live_frames.bricks.design_ir

It accepts --source, --component-id, --acss-source, and --output. Defaults use
the approved fixtures and write:

    sources/work/hero_india/design_ir/design_document.json

The Mix task only loads the approved TokenSet, calls the public adapter
boundary, validates through the existing IR serializer, and writes the
generated file. The drift test regenerates into a temporary directory and
compares bytes with the committed artifact. It never writes the tracked output
during normal tests.

This is static compiler work. It uses no database, queue, cache, process
registry, pub/sub, or network call. Source maps are treated as data. The
normalizer never evaluates source code or CSS, creates atoms from source
strings, follows source-provided paths, or downloads assets.

## Exact stop boundary

Phase 4B stops at the validated, deterministic Design IR document and its
source evidence. It does not create a Hero LiveFrames component, generate
HEEx, normalize to Tailwind, add LiveView behavior, add Storybook catalogue
content, or begin Master Phase 5. Any source requirement that would force a
change to frozen Design IR 1.0.0 or TokenSet 1.0.0 is reported as a later
architectural issue rather than changed here.
