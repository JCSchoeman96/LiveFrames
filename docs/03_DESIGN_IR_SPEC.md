# LiveFrames Design IR specification

## Authority and scope

`docs/00_LIVEFRAMES_MASTER_SPEC.md` remains authoritative. This document freezes
the Phase 2 framework-independent representation used between source adapters
and generators.

Phase 2 owns plain Elixir data structures, construction helpers, validation,
diagnostics, and deterministic JSON serialization. It does not parse Bricks,
read Automatic.css settings, render HEEx, start a database, or depend on a
source plugin.

## Version

The first contract version is `1.0.0`. Every `DesignDocument` carries its
`ir_version`. A change to required fields, field meaning, validation rules, or
serialized shape requires a new IR version and an explicit migration decision.

## Root document

`LiveFrames.IR.DesignDocument` has these fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `ir_version` | non-empty string | Version of this IR contract. |
| `source_metadata` | JSON object | General source identity and conversion context. |
| `token_set` | JSON object | Semantic token data. Phase 2 treats this as an opaque JSON object; the ACSS adapter defines its contents in Phase 3. |
| `root_nodes` | list of `DesignNode` | Ordered roots of the design tree. |
| `assets` | asset ID to `AssetReference` map | Canonical asset registry. |
| `interactions` | interaction ID to `Interaction` map | Canonical interaction registry. |
| `diagnostics` | list of `Diagnostic` | Findings carried with the document. |
| `provenance` | JSON object | Origin, version, hashes, permission and adapter metadata. |

Assets and interactions are registries. Nodes store references, not duplicate
definitions. Registry keys must match the corresponding `asset_id` or
`interaction_id`.

## Design nodes

`LiveFrames.IR.DesignNode` has these fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `node_id` | non-empty string | Deterministic identity within the document. |
| `semantic_type` | supported string | Normalized structural or content meaning. |
| `semantic_role` | string or `nil` | Optional role inferred from source intent. |
| `label` | string or `nil` | Human-readable source or review label. |
| `content` | JSON value or `nil` | Text or structured content. |
| `attributes` | JSON object | Normalized non-style attributes. |
| `styles` | property to `StyleValue` map | Base style declarations. |
| `responsive` | breakpoint ID to `ResponsiveOverride` map | Responsive style overrides. |
| `interaction_refs` | list of strings | IDs in the document interaction registry. |
| `asset_refs` | list of strings | IDs in the document asset registry. |
| `children` | list of `DesignNode` | Ordered child nodes. |
| `source_trace` | `SourceTrace` or `nil` | Source and inference information. |

Initial `semantic_type` values are:

- structural: `section`, `container`, `wrapper`, `stack`, `grid`, `generic`
- content: `heading`, `paragraph`, `rich_text`, `image`, `icon`, `button`, `link`
- intent: `actions`, `background`, `overlay`
- preservation: `raw`, `unsupported`

Adapters may preserve unsupported input as `raw` or `unsupported` nodes with a
diagnostic. Dropping an input node without a diagnostic is invalid.

## Deterministic node identity

`node_id` is deterministic for a fixed source, adapter version, conversion
options, and traversal order. The Phase 2 construction helper uses a
one-based traversal path:

```text
[1]       -> node_000001
[1, 2]    -> node_000001_000002
[2, 1]    -> node_000002_000001
```

The helper is independent of source-system IDs. Source IDs such as builder
element IDs belong in `SourceTrace`. Identical normalized input must produce
identical node IDs and list ordering.

## Style IR

`LiveFrames.IR.StyleValue` is an explicit tagged value with a `kind`, a
`value`, optional `source_expression`, optional `source_trace`, and JSON
metadata. The allowed kinds are:

| Kind | Meaning |
| --- | --- |
| `literal` | A literal CSS value or JSON-compatible primitive. |
| `token_ref` | A semantic token path, such as `color.brand.primary`. |
| `calculation` | A preserved CSS calculation or expression. |
| `keyword` | A CSS keyword such as `flex` or `auto`. |
| `responsive` | A nested responsive value that cannot be represented as a simple base declaration. |
| `complex_css` | Structured selector/rule data that needs a CSS renderer. |
| `unresolved` | Raw value retained because the adapter cannot resolve it yet. |

`unresolved` is a valid preservation state. Unsupported styles must remain
inspectable and must carry a diagnostic rather than disappearing.

Responsive overrides are represented separately from base styles by
`LiveFrames.IR.ResponsiveOverride`:

| Field | Type | Meaning |
| --- | --- | --- |
| `breakpoint_id` | non-empty string | Normalized key used by consumers. |
| `source_name` | string or `nil` | Raw source breakpoint name. |
| `min_width` | number or `nil` | Proven lower threshold when known. |
| `max_width` | number or `nil` | Proven upper threshold when known. |
| `resolution_status` | `resolved` or `unresolved` | Whether thresholds are known. |
| `styles` | property to `StyleValue` map | Override declarations. |
| `source_trace` | `SourceTrace` or `nil` | Origin of the override. |

An unresolved entry such as `tablet_portrait` is legal when its source name is
preserved and its thresholds are `nil`. The IR recognizes responsive intent
without inventing a numeric breakpoint.

## Assets and interactions

`LiveFrames.IR.AssetReference` contains an `asset_id`, `kind`, optional `uri`,
optional `alt`, a `resolved` or `unresolved` status, JSON metadata, and an
optional source trace. A resolved asset must have a URI. An unresolved asset
may omit it when a diagnostic explains the missing resolution.

`LiveFrames.IR.Interaction` contains an `interaction_id`, normalized `intent`,
optional `trigger`, target node IDs, JSON parameters, and an optional source
trace. The IR records intent only. It does not choose between CSS,
`Phoenix.LiveView.JS`, hooks, server events, or LiveComponents.

## Source trace

`LiveFrames.IR.SourceTrace` is generic and may contain:

- `source_type`, `source_id`, `source_path`, and `source_name`
- `global_classes`
- `source_settings`
- `adapter` and `adapter_version`
- `inference`
- arbitrary JSON `metadata`

The required contract never depends on a Bricks, WordPress, or plugin-specific
field. Adapters can retain those details in the generic trace fields.

## Diagnostics

`LiveFrames.IR.Diagnostic` contains:

- `code`
- `severity`: `info`, `warning`, `error`, or `fatal`
- `category`: `schema`, `unsupported_element`, `unsupported_style`,
  `unresolved_class`, `unresolved_token`, `ambiguous_semantics`,
  `asset_missing`, `interaction_unsupported`, `accessibility`, `provenance`,
  `generator`, or `visual_validation`
- human-readable `message`
- optional `source_trace`
- optional `suggested_action`
- JSON `metadata`

Validation diagnostics use stable `ir.*` codes. A caller can therefore make a
strict conversion decision without matching human-readable text.

## Validation rules

`LiveFrames.IR.validate/1` returns `:ok` or `{:error, diagnostics}`. It checks:

1. document version and JSON-compatible metadata;
2. unique, non-empty node IDs across the entire tree;
3. supported semantic types;
4. child node structure and style property names;
5. explicit `StyleValue` kinds and values;
6. responsive keys matching their override IDs;
7. unresolved responsive entries retaining a source name;
8. asset and interaction registry IDs matching their definitions;
9. node references resolving to registry entries;
10. interaction target node IDs resolving to nodes; and
11. diagnostic shape and source-trace shape.

The validator reports all discoverable violations in one result. It does not
silently repair or drop invalid values. `validate!/1` raises
`LiveFrames.IR.ValidationError` with the diagnostics for callers that require
an exception boundary.

## Serialization

`LiveFrames.IR.to_map/1` produces a JSON-ready object with string keys and
explicit tagged structs. `LiveFrames.IR.encode/1` validates first and returns
`{:ok, json}` or `{:error, diagnostics}`. `encode!/1` raises on invalid IR.

Serialization preserves list order and sorts object keys recursively before
encoding. Therefore identical normalized IR has semantically and bytewise
deterministic JSON. The serializer does not include Elixir struct names or
internal implementation fields.

## Public module boundary

The public entry points are:

```elixir
LiveFrames.IR.validate(document)
LiveFrames.IR.validate!(document)
LiveFrames.IR.to_map(document)
LiveFrames.IR.encode(document)
LiveFrames.IR.encode!(document)
LiveFrames.IR.DesignNode.deterministic_id(path)
```

Source adapters and generators depend on these contracts. The core IR modules
do not depend on any source adapter or preview application.

## Phase 2 gate

Phase 2 is complete when valid and invalid IR examples are constructed,
validated, and serialized in core tests; unresolved responsive entries remain
representable; registry references and duplicate IDs are checked; and no
Bricks, ACSS, Hero India, or HEEx implementation has been added.
