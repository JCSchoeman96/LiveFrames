# C09C2 Bricks frontend binding mapping authority

This document freezes the Bricks 2.3.1 export to Design IR 2.0.0 mapping for
frontend CollectionBinding and ValueBinding records. It is an authority for a
later adapter change. It does not change production code or define a backend
query model.

## 1. Accepted base and evidence

| Item | Accepted value |
| --- | --- |
| Repository | `JCSchoeman96/LiveFrames` |
| Base SHA | `52c65d05ce0d373077dbb062d245c2391b1ba9d2` |
| Base tree | `cebb2af01e8b5bba736d56c061c07f8ea32c1459` |
| C09C1 post-merge CI | Run `36886664635`, completed / success, head `52c65d05ce0d373077dbb062d245c2391b1ba9d2` |
| Canonical corpus | `private_reference/frames/staging-2026-09/`, 34 records excluding `Archive.tar.gz` |
| Corpus digest | `074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e` |

The accepted lineage is C09A source evidence, C09B frontend binding authority,
C09B1 Design IR 2.0.0 authority, and C09C1 Design IR binding core. The corpus
digest uses lexicographically sorted relative paths and records of
`path<TAB>size<TAB>lowercase-sha256<NL>`, then hashes the concatenated records
with SHA-256. The gate matched before this document was authored.

The inventory uses the canonical staging corpus only. It excludes
`private_reference/frames/frames-components/`, whose later drift is known. It
does not use Bricks 2.4.x PHP or JavaScript runtime behavior to infer Bricks
2.3.1 export semantics. The JSON exports were read as data. No source code,
query, dynamic URL, or expression was executed.

C09A established 26 query owners, five `useDynamicData` owners with five
bindings, five text settings with dynamic expressions, seven query shapes
(QS-01 through QS-07), and six scalar shape families (DB-01, DB-02, TB-01
through TB-04). The raw tree confirms that `hasLoop` is a boolean under the
owner's `settings` map. The owner's exported `children` identify its subtree.

One C09A path label needs correction from the raw corpus. Header Basel element
`5bf400` stores the site URL expression at
`settings.url.useDynamicData`. C09A lists
`settings.link.url.useDynamicData` for that row. C09C2 uses the digest-matched
export path and retains C09A's classification of the value as a dynamic link
URL.

C09C2's bounded source re-audit found one additional brace-bearing frontend
expression outside the C09A DB/TB summary. It scanned all nine canonical
Bricks component JSON fragments for string-valued settings outside
`settings.text`, `settings.image.useDynamicData`, and
`settings.url.useDynamicData`, excluding CSS/Sass, style values, and
JavaScript/code fields. The audit does not interpret arbitrary expressions.

| Source element | Source path | Raw-expression class | Target surface | Already covered by classifier? | Final policy |
| --- | --- | --- | --- | --- | --- |
| `5bf400` | `settings.altText` | Dynamic token followed by literal text (`{site_title} Logo`) | Accessibility / alt-text attribute | No | `NO_BINDING / DIAGNOSTIC_ONLY`; preserve the focused raw setting in SourceTrace, emit `bricks.binding.target_unsupported`, and do not create a static alt attribute. |

No other brace-based expression was found in the bounded nonstandard frontend
settings audit. This occurrence is not added to the historical C09A summary.

## 2. Contract boundary

Design IR 2.0.0 owns the `collection_bindings` and `value_bindings` root
registries. The Bricks adapter maps proven frontend repetition and values into
those registries. It does not turn Bricks query settings into a generic query
abstraction, DataProvider, or backend execution plan.

Bricks settings such as `post_type`, `posts_per_page`, `tax_query`, `orderby`,
`offset`, and `disable_query_merge` remain focused SourceTrace evidence. They
do not become CollectionBinding fields. No fetched record, runtime value,
provider, Ash query, database access, or host application value belongs in
Design IR.

Design IR's source-independent keys remain `content.title`, `media.primary`,
and `content.body` for `post_title`, `featured_image`, and `post_content`.
Source spellings are provenance, not generic `value_key` values. The accepted
evidence also proves a site-scoped URL value. This authority names its generic
key `site.url`. It does not assign a generic asset key to `post_id` when the
source targets an image.

The current `DesignIRNormalizer` module documentation still says it converts
to Design IR `1.0.0`. Record that as implementation cleanup for the later
adapter slice. C09C2 does not edit production code.

## 3. CollectionBinding admission

The admission check uses the parsed Bricks element tree and the same element's
source settings. An admitted record always has `normalization_status:
:normalized`; evidence-insufficient and unsupported source occurrences stay
in diagnostics and SourceTrace only.

| QS shape | `hasLoop` | Query present | Repeat boundary proven | Emit? | Owner node rule | Repeat-root rule | Parent rule | Diagnostic |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| QS-01, 15 Header Basel `Item` owners | `false` | Yes, JSON object | No. Static sibling items and links do not prove repetition. | No | Each source `Item` remains its own source owner; no combined menu owner is inferred. | None. No repeat root is assigned. | No collection parent is assigned. | `bricks.collection.boundary_unproven` per query owner. |
| QS-02, `ebbb6e` Feature Card | `true` | Yes, JSON object | Yes. The owner has a structurally linked child subtree. | Yes | The Bricks element with the query and loop flag maps to its DesignNode. | The owner DesignNode is the repeat root. | Nearest strict ancestor source element that emitted a CollectionBinding; none in this case. | None. |
| QS-03, `05e604` and `b71f5d` Feature media wrappers | `false` on `05e604`; `true` on `b71f5d` | Yes, JSON object on both | Proven only for `b71f5d`, which has a linked child subtree. `05e604` is a nested query under `ebbb6e`, but does not have `hasLoop: true`. | `b71f5d`: yes. `05e604`: no. | Each source element is assessed independently. | `b71f5d` itself is the repeat root. `05e604` has no repeat root. | `b71f5d` has no emitted collection ancestor. `05e604` is not a parent record; descendants still inherit `ebbb6e` as their nearest emitted scope. | None for `b71f5d`. `bricks.collection.boundary_unproven` for `05e604`. |
| QS-04, `118bbd` Basel slide | `true` | Yes, JSON object | Yes. The owner has linked content and media children. | Yes | The slide source element maps to its DesignNode. | The owner DesignNode is the repeat root. | Nearest strict ancestor source element that emitted a CollectionBinding; none in this case. | None. |
| QS-05, `895a32` and `4976fc` Hero wrappers | `true` on both | Yes, JSON object on both | Yes. Each owner has a linked image child. | Yes, one per owner. | Each wrapper source element maps to its DesignNode. | Each owner DesignNode is its repeat root. | Nearest strict ancestor source element that emitted a CollectionBinding; none in these paths. | None. |
| QS-06, `307070`, `dc20fb`, `10f903`, and `6309a6` Hero wrappers | `true` on all four | Yes, JSON object on all four | Yes. Each owner has a linked image child. | Yes, one per owner. | Each wrapper source element maps to its DesignNode. | Each owner DesignNode is its repeat root. | Nearest strict ancestor source element that emitted a CollectionBinding; none in these paths. | None. |
| QS-07, `c74cb5` Gallery wrapper | `true` | Yes, JSON object | Yes. The owner has a linked image child. | Yes | The wrapper source element maps to its DesignNode. | The owner DesignNode is the repeat root. | Nearest strict ancestor source element that emitted a CollectionBinding; none in this path. | None. |

The exact admission rule is conjunctive. `settings.query` must be a JSON
object, `settings.hasLoop` must equal boolean `true`, the source owner must map
to a DesignNode, and its non-empty child list must resolve to structurally
linked child nodes in the same tree. Any failed condition emits no
CollectionBinding and a diagnostic that identifies the failed boundary or
source shape.

For all emitted records, `owner_node_id` is the normalized DesignNode ID for
the Bricks element that owns `settings.query` and `settings.hasLoop`.
`repeat_root_node_id` is that same DesignNode ID. The complete owner subtree,
including its direct children, is rendered once per caller-supplied item.
Query limits, filters, sort settings, and merge flags remain SourceTrace only.

## 4. Nested source queries and collection parents

Feature Milan distinguishes a nested query from nested frontend repetition:

| Source element | Tree evidence | CollectionBinding outcome |
| --- | --- | --- |
| `ebbb6e` (QS-02) | `hasLoop: true`; its subtree includes `966841` and nested `05e604`. | Emit. Its owner DesignNode is the repeat root. |
| `05e604` (QS-03) | Child of `966841` under `ebbb6e`; owns a query object and an image child, but has no true `hasLoop` flag. | Do not emit. This is a nested source query without a proven nested repeated boundary. It does not create a parent collection scope. |
| `b71f5d` (QS-03) | `hasLoop: true`; its path goes through sibling `30fae8` under the section, outside the `ebbb6e` repeat subtree. | Emit as a separate collection with `parent_collection_binding_id: nil`. |

The generic parent field remains available for future source trees with proven
nested repeated boundaries. In this corpus, none of the ten emitted
CollectionBindings has a non-nil parent. A query-only ancestor never creates
collection scope. The emitted parent, when present, is the nearest strict
ancestor source element that itself emitted a CollectionBinding. The validator
must accept this parent only when the child owner lies within the parent's
repeat-root subtree.

For a loop-scoped value target, the adapter carries the nearest emitted
collection context through the source tree. A collection applies to its own
owner node and all descendants inside its repeat-root subtree. A nested
admitted collection replaces the inherited context for its subtree. A query
owner without an emitted CollectionBinding never replaces that context. This
inclusive target rule matches the Design IR containment validator and needs no
exception.

## 5. Closed ValueBinding classifier

The adapter recognizes only the exact supported source forms in the matrix
below. Supported paths are `settings.text`,
`settings.image.useDynamicData`, and `settings.url.useDynamicData`. For text
settings, the entire value must equal an admitted token to create a
ValueBinding, except that recognized mixed text is diagnosed as unsupported
interpolation. For dynamic settings, the expression is read only from the
listed target path. The observed `settings.altText` expression is an
unsupported frontend target, not a text binding: `target_kind: :text` means a
node's content target, not an arbitrary textual attribute. The classifier
does not interpret arbitrary brace tokens, modifiers, nested objects, or
source values as semantic fields. Observed unsupported target paths receive a
specific diagnostic and SourceTrace only; unknown future forms fail closed.

`value_kind: field` uses a proven source-independent `value_key`.
`collection_item` scope points to the nearest enclosing admitted collection
context, while `site` scope has no collection reference. A
`collection_count` uses `scope: collection`, `target_kind: text`, a nil
`value_key`, and the normalized ID of an emitted CollectionBinding.

| Source shape | Evidence ID | Target source setting | Admission | Target kind | Value kind | Scope | Semantic value_key | Collection context | Modifier status | Normalization status | Node cleanup | Diagnostic | SourceTrace evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `{featured_image}` on image | DB-01; elements `2a8181`, `0ba4da`, `c22f13` | `settings.image.useDynamicData` | Emit normalized ValueBinding. | `asset` | `field` | `collection_item` | `media.primary` | Nearest emitted collection: `ebbb6e` for `2a8181`, `b71f5d` for `0ba4da`, and `118bbd` for `c22f13`. | `none` | `normalized` | No AssetReference or asset ref for this `settings.image` declaration. Do not copy the expression into another generic node field. | None. | Source element ID, exact path, Bricks adapter/version, the focused `settings.image` source object, exact raw expression, and classification `media.primary`. |
| `{post_id}` on image | DB-01; element `bbf168` | `settings.image.useDynamicData` | No ValueBinding. The source identifies an attachment ID, but the evidence does not prove an asset value that the frontend asset target can consume. | `asset` | `field` candidate only; no record | `collection_item` candidate only, under `c74cb5` | None. Do not use `post_id`, `media.id`, or another invented key. | `c74cb5` is the nearest collection, but a valid value binding is not emitted. | `none` | `evidence_insufficient` | Suppress AssetReference and `asset_refs` for this dynamic image setting. | `bricks.binding.evidence_insufficient`. | Source element ID, exact path, focused `settings.image` object, raw `{post_id}`, and inference that an attachment ID does not prove a frontend asset value. |
| `{site_url}` on dynamic URL | DB-02; element `5bf400` | `settings.url.useDynamicData` | Emit normalized ValueBinding. The path is the raw export path; see the C09A correction in section 1. | `link_url` | `field` | `site` | `site.url` | None. | `none` | `normalized` | Remove the raw dynamic `url` object from `attributes`; do not emit a static `navigation` value. | None. | Source element ID, exact path, Bricks adapter/version, focused raw `settings.url` object, exact expression, and classification `site.url`. |
| `{site_title} Logo` | C09C2 bounded source re-audit; element `5bf400` | `settings.altText` | No ValueBinding. This is mixed dynamic/literal accessibility text, and Design IR 2.0.0 has no authorized attribute or alt-text target. | None | None | None | None | None. | `none` | `unsupported` | Preserve the raw setting only in SourceTrace. Do not emit a static alt attribute or treat this as `content`. | `bricks.binding.target_unsupported`. | Source element ID, exact path, Bricks adapter/version, focused raw `settings.altText`, exact raw value, and inference that the accessibility target has no authorized IR representation. |
| `{post_title}` | TB-01; elements `a34333`, `222894` | `settings.text` | Emit one normalized ValueBinding per target. | `text` | `field` | `collection_item` | `content.title` | Nearest emitted collection: `ebbb6e` for `a34333`; `118bbd` for `222894`. | `none` | `normalized` | Set `DesignNode.content` to nil. Preserve the source text only in SourceTrace. | None. | Source element ID, exact `settings.text` path, Bricks adapter/version, focused raw text setting, exact expression, and classification `content.title`. |
| `{post_content:16}` | TB-02; element `b41076` | `settings.text` | Emit an evidence-insufficient ValueBinding because its base field and typed target remain proven. | `text` | `field` | `collection_item` | `content.body` | Nearest emitted collection `ebbb6e`. | `opaque` | `evidence_insufficient` | Set `DesignNode.content` to nil. Do not expose the expression as static content. | `bricks.binding.evidence_insufficient`, with modifier inference. | Source element ID, exact path, focused raw text setting, exact expression, adapter/version, base-field classification, and inference that modifier `16` is opaque. |
| Exact whole `{post_content}` token | C09B section 6; this exact whole-text shape is not a separate corpus occurrence. | `settings.text` | Emit only when the complete text setting equals the exact token and the target has an admitted collection context. | `text` | `field` | `collection_item` | `content.body` | Nearest emitted collection containing the target. | `none` | `normalized` | Set `DesignNode.content` to nil. | None when all required fields resolve. | Source element ID, exact path, focused raw text setting, exact expression, adapter/version, and classification `content.body`. |
| Exact whole `{query_results_count:<owner-id>}` token | TB-03 token form; its corpus occurrence at `22de9a` is wrapped, not whole-text. | `settings.text` | Emit only when the complete text equals this exact token form and the referenced source owner maps to an emitted CollectionBinding. | `text` | `collection_count` | `collection` | Nil. | Resolve the referenced Bricks owner ID through the source-owner-to-admitted-collection index. Store only its normalized CollectionBinding ID. | `none` | `normalized` | Set `DesignNode.content` to nil. | None when the exact target and collection reference resolve. If the owner is absent or did not emit a CollectionBinding, emit no ValueBinding and `bricks.binding.evidence_insufficient`. | Source element ID, exact path, focused raw text setting, token string, adapter/version, referenced source owner ID in trace metadata, and resolved or failed reference classification. |
| Wrapped `{query_results_count:c74cb5}` with surrounding text | TB-03; element `22de9a`; C09A records 43 characters, with non-empty text before and after the token. | `settings.text` | No ValueBinding. The target contains interpolation that ValueBinding cannot represent. | `text` | None | None | None | `c74cb5` is an admitted collection, but that does not make partial text representable. | `none` | `unsupported` | Set `DesignNode.content` to nil. Do not remove surrounding content and emit a count-only value. | `bricks.binding.interpolation_unsupported`. | Source element ID, exact path, focused raw text setting, raw token and full raw text retained in trace, adapter/version, and interpolation classification. |
| Wrapped `{post_content}` with markup | TB-04; element `d01006`; source text has markup before and after the token. | `settings.text` | No ValueBinding. Partial interpolation is not represented by Design IR 2.0.0. | `text` | None | None | None | The target is within the `118bbd` repeat subtree, but no binding is emitted. | `none` | `unsupported` | Set `DesignNode.content` to nil. Do not strip markup or treat the full string as static text. | `bricks.binding.interpolation_unsupported`. | Source element ID, exact path, focused raw text setting, raw token and full text retained in trace, adapter/version, and interpolation classification. |

For a query-count token, `<owner-id>` is an inert string looked up by exact
equality in the already-built source element index. The adapter does not turn
it into an atom, module, path, query, or runtime reference. The accepted corpus
proves the token `{query_results_count:c74cb5}` and the referenced collection
`c74cb5`; it does not prove that the surrounding text can be discarded. The
actual `22de9a` value therefore has no ValueBinding.

An unknown brace-bearing value at one of these supported target paths gets no
ValueBinding and no invented key. If `settings.text` contains brace syntax but
does not equal an allowlisted token, the adapter clears generic content and
emits `bricks.binding.expression_unsupported`. Unknown dynamic values in
`settings.image.useDynamicData` or `settings.url.useDynamicData` receive the
same closed-classifier outcome. The observed `settings.altText` occurrence
gets `bricks.binding.target_unsupported` because the target itself has no
authorized ValueBinding representation. Other unrecognized source settings
remain under existing unsupported-source handling and must not be promoted to
generic frontend values.

## 6. Dynamic asset and link boundaries

For an image element, any non-empty `settings.image.useDynamicData` marks that
image setting as caller data. The same source setting cannot produce both a
dynamic ValueBinding and an AssetReference. This rule also applies when the
expression is unsupported or evidence is insufficient. The full focused image
setting remains in SourceTrace; static-looking keys co-located in that same
source object do not prove a separate asset declaration in this corpus.

The admitted `{featured_image}` form becomes `target_kind: :asset`,
`value_kind: :field`, `scope: :collection_item`, and `value_key:
"media.primary"`. `{post_id}` does not become a ValueBinding or a resolved
AssetReference. Static, non-dynamic image settings continue through the
existing asset authority.

The admitted `{site_url}` form at `settings.url.useDynamicData` becomes a
site-scoped `link_url` ValueBinding with `value_key: "site.url"`. It does not
become an already resolved frontend `href` or `attributes.navigation` value.
Remove that raw dynamic URL object from generic attributes. Retain it as
focused SourceTrace data. Do not fetch it, interpret it as a URL, or evaluate
it. Existing static navigation checks still own safe static destinations.

## 7. Deterministic binding IDs

DesignNode IDs already follow the stable one-based source-tree traversal path
defined by the Design IR specification. Binding IDs use those normalized IDs,
not Bricks source IDs, map enumeration order, caller values, database contents,
query result order, clock values, randomness, or host application values.

Each Bricks query owner can emit at most one CollectionBinding because the
source contract has one `settings.query` and one `settings.hasLoop` slot. Its
ID is `cb_<owner-node-id>`.

ValueBinding candidates are grouped by `(target_node_id, target_kind)`. Within
each group, sort by UTF-8 byte order of `source_path`, then raw expression,
then the closed classifier's canonical source-form name. Assign a one-based,
six-digit ordinal in that order. The ID is
`vb_<target-node-id>_<target-kind>_<ordinal>`, for example
`vb_node_000001_000002_text_000001`. The target kind and ordinal allow more
than one value binding on the same DesignNode, including more than one
binding of the same target kind. No map enumeration order participates.

## 8. Node cleanup and SourceTrace

Once a source value is classified as dynamic, generic DesignNode fields must
not present that raw value as static frontend content or as a resolved target.

| Target kind | DesignNode cleanup |
| --- | --- |
| `text` | Set `content` to nil for an emitted binding, opaque modifier, wrapped expression, or unknown brace-bearing expression. Keep ordinary static text only when it contains no classified dynamic expression. |
| `asset` | For a dynamic `settings.image` value, emit no AssetReference and no `asset_refs` entry for that declaration. Keep the raw image setting in SourceTrace. |
| `link_url` | Remove the dynamic source URL object from `attributes`; emit no static `navigation` or `href` from that object. Keep it in SourceTrace. |
| Unsupported accessibility / attribute target | The current adapter does not normalize `altText` into a generic node attribute; preserve that fail-closed behavior for the observed dynamic `settings.altText`. Keep the raw setting in SourceTrace, emit no ValueBinding, and emit no static alt attribute. Do not add a generic attribute or accessibility target. |

For each source-derived binding, SourceTrace identifies the source element,
exact source path, adapter name and adapter version, focused raw source
setting, raw expression, and classification inference. A collection trace
also records its raw `settings.query` object and `settings.hasLoop` value. A
binding trace stores only the focused setting needed to audit that binding;
it does not duplicate the full export. Expressions remain inert strings.

The existing node SourceTrace may continue to preserve original element
settings as source provenance. Dynamic syntax in that trace does not make it a
generic node value. The cleanup rule applies to `content`, `attributes`,
`asset_refs`, and the AssetReference registry.

## 9. Diagnostics ownership and lifecycle

Normalization follows C09B:

```text
source_seen
-> frontend_semantics_classified
-> binding_normalized
```

Terminal outcomes are `normalized`, `evidence_insufficient`, and
`unsupported`. Registry admission remains exactly the C09B rule:

| Registry | Outcome | Admission |
| --- | --- | --- |
| CollectionBinding | `normalized` | Emit. |
| CollectionBinding | `evidence_insufficient` or `unsupported` | Emit no record; preserve SourceTrace and a diagnostic. |
| ValueBinding | `normalized` | Emit. |
| ValueBinding | `evidence_insufficient` | Emit only when every required typed/base field is proven. The consumer must treat it as unresolved. |
| ValueBinding | `unsupported` | Emit no record; preserve SourceTrace and a diagnostic. |

The existing `DependencyExtractor` emits broad `bricks.runtime.unsupported`
diagnostics when setting keys contain words such as `query` or `dynamic`.
Later normalization owns only the exact source occurrences it classifies:

- A query occurrence, including keys below that same `settings.query`
  object, is replaced by the CollectionBinding outcome. QS-01 gets
  `bricks.collection.boundary_unproven`; an admitted query gets no generic
  runtime-unsupported diagnostic.
- A `useDynamicData` occurrence at a classified image or URL target is
  replaced by its ValueBinding outcome. A normalized occurrence gets no
  generic runtime-unsupported diagnostic. Evidence-insufficient and
  unsupported occurrences get their specific binding diagnostic.
- A normalized `{site_url}` occurrence also replaces the overlapping
  `bricks.navigation.dynamic` finding. It remains absent from static
  navigation because it is now represented as a link URL binding.
- Text tokens that the broad detector does not see still get their exact
  ValueBinding or binding diagnostic.
- Keep every broad runtime diagnostic outside the exact query object or
  classified dynamic target path. Do not suppress unrelated interaction,
  script, hook, or runtime findings.

Diagnostic decisions are specific and stable:

| Occurrence | Outcome and diagnostic |
| --- | --- |
| QS-01 query with no proven repeat boundary | Evidence insufficient; `bricks.collection.boundary_unproven`. |
| Known token with an opaque modifier or unresolved collection reference | Evidence insufficient; `bricks.binding.evidence_insufficient`; emit a ValueBinding only when all C09B required fields are proven. |
| Known token embedded in surrounding text or markup | Unsupported interpolation; `bricks.binding.interpolation_unsupported`; no ValueBinding. |
| Unknown expression at a supported target path | Unsupported; `bricks.binding.expression_unsupported`; no ValueBinding. |
| Observed dynamic `settings.altText` on element `5bf400` | Unsupported target; `bricks.binding.target_unsupported`; no ValueBinding and no static alt attribute. |
| Proven supported binding | Normalized; no generic unsupported diagnostic for that source occurrence. |

## 10. Security and performance boundary

Expression recognition is exact and closed. No arbitrary `{anything}` value is
accepted as a semantic field. Unknown tokens produce a diagnostic and
SourceTrace only. The adapter must not evaluate or execute PHP, JavaScript,
shortcodes, SQL, WordPress queries, or dynamic URLs. Source values must not
create atoms or modules.

This phase performs compile-time normalization over an ephemeral source
artifact. It uses no Redis, ETS, Cachex, Postgres, network, or GenServer. The
implementation builds a source ID to DesignNode ID index and a source owner
ID to admitted CollectionBinding index while traversing the tree. It carries
the nearest admitted collection context with each tree node, then classifies
the closed set of binding candidates from those indexes. Aim for
`O(elements + emitted bindings)` without a full-tree search per binding. Store
no fetched records in IR.

## 11. Exact implementation decisions

| Decision | Frozen value |
| --- | --- |
| `COLLECTION_ADMISSION_RULE` | Emit only when `settings.query` is a JSON object, `settings.hasLoop` is exactly boolean `true`, the owner maps to a DesignNode, and at least one exported child resolves to a structurally linked node. Otherwise emit no CollectionBinding and diagnose the failed boundary or source shape. |
| `REPEAT_ROOT_RULE` | Use the DesignNode mapped from the Bricks element that owns the query and true loop flag. That owner node is the root of its complete repeated subtree. |
| `NESTED_COLLECTION_PARENT_RULE` | Use the nearest strict ancestor source element that itself emitted a CollectionBinding. A query-only ancestor never creates a parent. |
| `COLLECTION_BINDING_ID_RULE` | `cb_<owner-node-id>`, where the owner node ID is the deterministic Design IR ID. |
| `VALUE_BINDING_ID_RULE` | `vb_<target-node-id>_<target-kind>_<ordinal>`; ordinal is one-based per node and target kind after sorting source path, raw expression, and canonical source-form name by UTF-8 byte order. |
| `POST_TITLE_VALUE_KEY` | Map exact whole `{post_title}` text to `content.title`. |
| `FEATURED_IMAGE_VALUE_KEY` | Map exact `settings.image.useDynamicData` `{featured_image}` to `media.primary`. |
| `POST_CONTENT_VALUE_KEY` | Map exact whole `{post_content}` text to `content.body`. |
| `POST_ID_ASSET_VALUE_KEY` | `NO_BINDING / DIAGNOSTIC_ONLY`; no source-independent asset value key is proven for `{post_id}` targeting an image. |
| `SITE_URL_VALUE_KEY` | Map exact `settings.url.useDynamicData` `{site_url}` to `site.url`, with site scope. |
| `DYNAMIC_ALT_TEXT_POLICY` | The observed `settings.altText` value `{site_title} Logo` is `NO_BINDING / DIAGNOSTIC_ONLY`: emit `bricks.binding.target_unsupported`, preserve the raw setting in SourceTrace, and emit no static alt attribute. Design IR 2.0.0 has no authorized alt-text or arbitrary-attribute target; do not add a target kind, field, or value key. |
| `OPAQUE_POST_CONTENT_MODIFIER_POLICY` | `{post_content:16}` may emit `content.body` only as `modifier_status: :opaque` and `normalization_status: :evidence_insufficient`. Do not interpret `16`. |
| `WRAPPED_TEXT_EXPRESSION_POLICY` | `NO_BINDING / DIAGNOSTIC_ONLY`; Design IR 2.0.0 has no interpolation template. Preserve the complete raw setting in SourceTrace, clear `DesignNode.content`, and emit `bricks.binding.interpolation_unsupported`. |
| `QUERY_RESULTS_COUNT_POLICY` | Only an exact whole `{query_results_count:<owner-id>}` text token can map to `target_kind: :text`, `value_kind: :collection_count`, `scope: :collection`, nil `value_key`, and the referenced owner's emitted CollectionBinding ID. Missing or non-admitted owners get no ValueBinding. The observed wrapped TB-03 value gets no ValueBinding and an interpolation diagnostic. |
| `DYNAMIC_ASSET_POLICY` | A dynamic `settings.image` is caller data. `{featured_image}` emits a `media.primary` ValueBinding; `{post_id}` is diagnostic-only. Neither form creates an AssetReference from that same image setting. |
| `DYNAMIC_LINK_POLICY` | Exact `{site_url}` at `settings.url.useDynamicData` emits a site-scoped `link_url` binding with `site.url`. Remove its raw object from generic attributes; do not emit a resolved href/navigation value or fetch the URL. |
| `TEXT_NODE_CLEANUP_POLICY` | Clear `DesignNode.content` for dynamic text tokens, opaque modifiers, wrapped expressions, and unknown brace-bearing text. Store the raw setting only in SourceTrace. |
| `ASSET_NODE_CLEANUP_POLICY` | For any dynamic `settings.image` declaration, emit no AssetReference and no matching `asset_refs` entry. Keep the focused raw image setting in SourceTrace. |
| `LINK_NODE_CLEANUP_POLICY` | For a dynamic URL declaration, remove the source URL object from `attributes` and emit no static `navigation` or `href` from that declaration. Keep the raw source setting in SourceTrace. |
| `SUPPORTED_RUNTIME_DIAGNOSTIC_POLICY` | Replace broad `bricks.runtime.unsupported` only for exact paths claimed by the closed binding/collection classifier, including normalized, evidence-insufficient, and unsupported outcomes; emit that occurrence's specific outcome diagnostic. The observed unsupported `settings.altText` path gets `bricks.binding.target_unsupported`. Replace `bricks.navigation.dynamic` only for normalized `{site_url}`. Keep unrelated runtime diagnostics. |
| `EVIDENCE_INSUFFICIENT_DIAGNOSTIC_POLICY` | Preserve SourceTrace and emit the specific evidence-insufficient diagnostic. Emit an evidence-insufficient ValueBinding only when all C09B required typed and base fields remain proven. QS-01 always reports `bricks.collection.boundary_unproven`. |
| `UNKNOWN_EXPRESSION_POLICY` | `NO_BINDING / DIAGNOSTIC_ONLY`; keep the raw value in SourceTrace, clear its generic node target, emit `bricks.binding.expression_unsupported`, and do not extend the classifier to arbitrary expressions. |

## 12. Later implementation envelope

The next implementation branch is `feat/c09c3-bricks-frontend-bindings`.
That slice may change the Bricks adapter, focused helpers and tests, and
necessary current documentation. It may implement this exact closed
classifier, deterministic registry IDs, indexes, node cleanup, diagnostics,
and `IR.validate/1` integration.

It must not implement HEEx binding rendering, component attributes or slots,
DataProvider, Ash queries, database access, query filters or ordering,
pagination, or runtime values. It must keep the reusable library independent
from the preview application and Bricks runtime.

C09C2 changes only this authority document. It adds no production code, tests,
generated artifacts, dependencies, query execution, backend/provider
architecture, or merge. C09C3 has not started.

```text
RUNTIME_DB_CALLS = 0
RUNTIME_REDIS_CALLS = 0
RUNTIME_NETWORK_CALLS = 0
```
