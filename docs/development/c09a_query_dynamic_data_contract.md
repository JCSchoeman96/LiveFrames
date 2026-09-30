# C-09A Bricks query and dynamic data contract

## Revision log

- `v1` — initial authority audit from canonical `staging-2026-09` exports; frozen source-independent query/data semantics and IR gate.

## 1. Accepted base

| Fact | Accepted value |
| --- | --- |
| Repository | `JCSchoeman96/LiveFrames` |
| Base commit | `bc46c6b31390d526e9f4931fb1024186f371bda3` |
| Base tree | `748431a9f806401870a30e7322c0536498480e12` |
| Exact-main CI | Run `36730112397`, completed / success, `headSha` matches the base commit |
| Worktree at audit start | Clean |
| Branch | `docs/c09a-query-dynamic-data-contract` |

Preflight matched all pinned values before corpus inspection.

## 2. Source authority and digest

| Authority | Scope | Records | Digest |
| --- | --- | ---: | --- |
| Frames exported corpus | `private_reference/frames/staging-2026-09/`; `Archive.tar.gz` excluded | 34 | `074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e |

Digest algorithm matches C-07X: lexicographic relative paths; each record is `path<TAB>size<TAB>lowercase-sha256<TAB newline>`; corpus digest is SHA-256 of the concatenation.

Bricks component fragments audited: **9** JSON files under the nine template folders. The remaining 25 corpus records are PNG captures and the ACSS settings export; they contain no structured query objects.

**Prohibited authority (not used):** `private_reference/frames/frames-components/` (drifted digest). Current Bricks 2.4.2 PHP/JS source was not used to infer 2.3.1 query behavior.

## 3. Current LiveFrames behavior

C-07X classifies query and dynamic data as **X08**: parse preserves source evidence; normalize is partial; authority, IR, fidelity, and runtime are missing.

`LiveFrames.Adapters.Bricks.DependencyExtractor` walks each element’s `settings` recursively. Any setting key whose lowercase form contains one of `interaction`, `dynamic`, `query`, `script`, `hook`, or `runtime` produces a `bricks.runtime.unsupported` diagnostic with kind `:query_loop`, `:dynamic_data`, `:interaction`, `:external_script`, `:browser_runtime`, or `:unsupported_feature`.

That path is **evidence preservation only**. It does not classify query intent, bind fields, represent collection repetition, or call an application data provider.

`LiveFrames.IR.Interaction` models browser/user behavior intent (`intent`, `trigger`, `target_node_ids`, `parameters`). This audit treats **behavior intent ≠ data/query intent**; Interaction must not carry query loops or dynamic field bindings.

## 4. Search methodology

1. Recomputed the 34-record corpus digest (gate).
2. Loaded all nine `bricks-component-*.json` fragments from `components[0].elements`.
3. Seed searches with `rg` for `query`, `hasLoop`, `useDynamicData`, `tax_query`, `orderby`, `offset`, and brace patterns in JSON.
4. Ran a deterministic read-only `python3` inventory: element tree index, parent/child links, `settings.query` owners, nested `useDynamicData`, and recursive string walk for `{field}` / `{field:modifier}` / `{query_results_count:…}` patterns under non-runtime keys.
5. Simulated current `runtime_key?/1` matching on the same trees for coverage matrix.
6. No browser, network, database, WordPress, PHP, or JavaScript execution.

Custom CSS strings containing `{` for Sass/CSS variables were classified as **css_or_opaque_brace** and excluded from dynamic-data binding semantics (style surface, not record binding).

## 5. Complete occurrence inventory

### Counts

| Metric | Count |
| --- | ---: |
| Query owners (distinct elements with `settings.query` object) | 26 |
| Dynamic-binding owners (`useDynamicData` on any nested setting) | 5 |
| Individual `useDynamicData` bindings | 5 |
| Text-setting dynamic expressions (non-CSS) | 5 |
| Distinct query source shapes (QS-01 … QS-07) | 7 |
| Distinct scalar binding shape families (DB/TB) | 6 |

Templates with **no** query objects in export: CTA Tango, Feature Romeo, Pricing Echo, Slide Menu Alpha.

### Query owners by template

| Template folder | Query owners |
| --- | ---: |
| header-basel | 15 |
| hero-barcelona | 6 |
| feature-section-milan | 3 |
| gallery-bravo | 1 |
| slider-section-basel | 1 |

### Query owner register

Each row is one element owning `settings.query`. `hasLoop` is the export flag on that same element.

| Corpus file | Element id | Name | Label | Parent | hasLoop | Shape |
| --- | --- | --- | --- | --- | --- | --- |
| feature-section-milan/…milan.json | ebbb6e | block | Feature Card | (root card) | true | QS-02 |
| feature-section-milan/…milan.json | 05e604 | div | Media Wrapper | ebbb6e | false | QS-03 |
| feature-section-milan/…milan.json | b71f5d | div | Media Wrapper | (tab panel) | true | QS-03 |
| gallery-bravo/…bravo….json | c74cb5 | div | Media Wrapper (CSS) | ohflag | true | QS-07 |
| header-basel/…basel….json | 15× `block` | block | Item | nav list | false | QS-01 |
| hero-barcelona/…barcelona.json | 6× wrapper ids | div | Slider Image Wrapper | column | true | QS-05/QS-06 |
| slider-section-basel/…basel.json | (slide root) | block | Slide | slider | true | QS-04 |

(Fifteen Header Basel rows share element pattern `Item` + QS-01; six Hero rows pair as two QS-05 and four QS-06 by offset presence.)

### Dynamic binding register (`useDynamicData`)

| Template | Element | Parent setting | Source path | Expression category | Length | SHA-256 |
| --- | --- | --- | --- | --- | ---: | --- |
| feature-section-milan | image (loop child) | `image` | `settings.image.useDynamicData` | `{featured_image}` field ref | 16 | `8ba515b969c39b775f9e77d913a056fe9462316d998ae0f7f261a1b0ae9b94ea` |
| feature-section-milan | image (tab media) | `image` | same | `{featured_image}` field ref | 16 | `8ba515b969c39b775f9e77d913a056fe9462316d998ae0f7f261a1b0ae9b94ea` |
| gallery-bravo | image Media | `image` | `settings.image.useDynamicData` | `{post_id}` attachment id ref | 9 | `1904f15dcdd63d105f212ef4eb88c54fc0b869d5de40a0e5c379d8f0c9644694` |
| header-basel | logo link | `url` | `settings.link.url.useDynamicData` | `{site_url}` site field ref | 10 | `9354420d78b03949441e642e0ed145469bddcb8029bfabfa00a2f1bb8d81d56d` |
| slider-section-basel | slide image | `image` | `settings.image.useDynamicData` | `{featured_image}` field ref | 16 | `8ba515b969c39b775f9e77d913a056fe9462316d998ae0f7f261a1b0ae9b94ea` |

### Text-setting dynamic expressions (detector misses)

| Template | Element | Source path | Category | Under loop subtree | Length | SHA-256 |
| --- | --- | --- | --- | --- | ---: | --- |
| feature-section-milan | heading a34333 | `settings.text` | `{post_title}` | yes | 12 | `1cec9750eea38d7b02256c8bac377453ef415ac53335e3f2d312b17a9036aa01` |
| feature-section-milan | text-basic b41076 | `settings.text` | `{post_content:16}` modifier | yes | 17 | `e8b1ed82a82259350f2aecc9e97f9af88227e81abad4289fe0d27341760b24a1` |
| gallery-bravo | text-basic 22de9a | `settings.text` | `{query_results_count:c74cb5}` | no | 43 | `396552e6b5e9e9fc21c75acd9b509d728ea2ae86357e1e8662ce551eaacb6b22` |
| slider-section-basel | heading 222894 | `settings.text` | `{post_title}` | yes | 12 | `1cec9750eea38d7b02256c8bac377453ef415ac53335e3f2d312b17a9036aa01` |
| slider-section-basel | text d01006 | `settings.text` | post field ref (21 chars) | yes | 21 | `4552f832a80bf18072dc8747bfe06ca4fe630c4c2d5b798450bec93a7c04d176` |

## 6. Distinct query source shapes

| Shape ID | Owners | Occurrences | Collection / scalar | Dynamic child bindings | Source dependency | Proposed normalized meaning | Current status |
| --- | ---: | ---: | --- | --- | --- | --- | --- |
| QS-01 | Header list `Item` | 15 | Collection intent **uncertain** (`hasLoop` false) | Static link text in export | WP post query stub + `disable_query_merge` | Navigation/menu item collection with merge disabled; child links not dynamically bound in export | Evidence only |
| QS-02 | Feature Card | 1 | Collection (`hasLoop` true) | `{post_title}`, `{post_content:16}`, nested QS-03 | Post type `post`, limit 4 | Repeat feature card subtree for up to four posts | Evidence only |
| QS-03 | Feature media wrapper | 2 | One nested without loop flag | `{featured_image}` on child image | Post query, limit 4; one owner nested under QS-02 | Media slot per loop record; nested query on one path | Evidence only |
| QS-04 | Slider slide | 1 | Collection (`hasLoop` true) | `{post_title}`, `{featured_image}` | Custom post type `locations` | Repeat slide subtree for location posts | Evidence only |
| QS-05 | Hero slider wrapper | 2 | Collection (`hasLoop` true) | Child image from attachment context (static image element in export) | Attachment + taxonomy filter, no offset | Repeat wrapper for filtered attachments | Evidence only |
| QS-06 | Hero slider wrapper | 4 | Collection (`hasLoop` true) | Same | Attachment + taxonomy + numeric **offset** (8 or 12) | Same as QS-05 with staggered window | Evidence only |
| QS-07 | Gallery media wrapper | 1 | Collection (`hasLoop` true) | `{post_id}` on image; count in sibling text | Attachment + taxonomy; **orderby random**; unbounded limit | Gallery grid of filtered attachments; non-deterministic **ordering intent** at provider | Evidence only |

**Input fields observed:** `objectType`, `post_type`, `posts_per_page`, `tax_query` (opaque taxonomy tokens), `orderby` (`rand`), `offset`, `disable_query_merge`.

**Result usage:** repeated subtree under query owner (`children` lists in export); scalar reads via `useDynamicData` or `text` field templates.

## 7. Distinct dynamic binding shapes

| Shape ID | Mechanism | Occurrences | Target | Context |
| --- | --- | ---: | --- | --- |
| DB-01 | `useDynamicData` on `image` | 4 | Asset / media field | Loop record |
| DB-02 | `useDynamicData` on link `url` | 1 | Link destination | Site/global |
| TB-01 | `text` `{post_title}` | 2 | Text content | Loop record |
| TB-02 | `text` `{post_content:…}` | 1 | Text content (truncation modifier) | Loop record |
| TB-03 | `text` `{query_results_count:…}` | 1 | Text content | References query owner id |
| TB-04 | `text` other post field | 1 | Text content | Loop record |

## 8. Collection vs scalar semantics

**Collection binding proven:** yes. Ten query owners set `hasLoop: true` and own a non-empty child subtree that is the repetition template (Gallery, Hero columns, Slider slide, Feature card/media).

**Scalar binding proven:** yes. Five `useDynamicData` bindings and five `text` template bindings read fields from the current or site context.

**Header Basel gap:** fifteen query owners lack `hasLoop` and use static placeholder link text (`Feature`, `#`). The export proves query **configuration** on list items but not that the published menu repeats or which fields populate labels/URLs. Normalization must allow **declared query without proven repeat flag** and surface `collection_boundary_unproven` until structure or authority supplements the export.

**Nested collection:** one proven parent/child pair both owning `query`: Feature Milan `ebbb6e` (QS-02) → `05e604` (QS-03). Child inherits loop context by tree position; nested query object on child is a separate intent.

## 9. Data context and scoping findings

| Context | Proven by corpus | Notes |
| --- | --- | --- |
| Query-loop current record | Yes | `{post_title}`, `{post_content:…}`, `{featured_image}`, `{post_id}` on descendants of loop owners |
| Site / global | Yes | `{site_url}` on header logo |
| Query result count | Yes | `{query_results_count:c74cb5}` references owner element id |
| Page/current post | Not proven | No `{post_*}` outside loops except ambiguous header stubs |
| Parent-loop record | Partial | Nested QS-03 under QS-02 |
| Media attachment record | Yes | Gallery/Hero attachment queries + `{post_id}` binding |
| Navigation hierarchy | Not proven | Header lists are flat `Item` blocks; no `{menu_*}` bindings |
| Menu item current-page | Not proven | Slide Menu Alpha has no query objects in export |

## 10. Current detector coverage

Simulated `runtime_key?/1` on canonical exports:

| Metric | Value |
| --- | ---: |
| Runtime-key records emitted | 56 |
| Semantic query object keys (`query`) | 26 |
| Semantic dynamic keys (`useDynamicData`) | 5 |
| False-positive keys | 25 |

### Detector matrix

| Source occurrence class | Current detector | Correct semantic class | Gap |
| --- | --- | --- | --- |
| `settings.query` object | `:query_loop` record on `query` key | Collection query intent | Over-broad raw dump; no normalized intent |
| Nested `tax_query` array key | `:query_loop` (substring `query`) | Filter clause inside query | False positive duplicate record |
| `disable_query_merge` flag | `:query_loop` | Query merge policy | False positive |
| `useDynamicData` string | `:dynamic_data` | Scalar data binding | No target kind or scope |
| `settings.text` `{post_title}` etc. | **Miss** | Scalar text binding | Not keyed with `dynamic`/`query` |
| `settings.text` `{query_results_count:…}` | **Miss** | Aggregate binding | Miss |
| `hasLoop` flag | **Miss** (not a runtime key) | Collection boundary signal | Must pair with query in normalizer |
| `javascriptCode` | `:external_script` | External script (X09) | Substring `script` false positive on unrelated key name |
| `_interactions` (Feature Romeo) | Would match `interaction` | Behavior, not data | Out of scope for data contract |

## 11. Source-independent semantic model

LiveFrames core should preserve **intent**, not WordPress query API details. Raw Bricks keys remain in `SourceTrace`.

### DataSourceIntent (collection)

| Field | Purpose |
| --- | --- |
| `id` | Stable document-local id |
| `kind` | Normalized enum: `post_collection`, `attachment_collection`, `navigation_collection` (last only when export proves bindings) |
| `cardinality` | `one_or_many` |
| `record_type` | `post`, `attachment`, `custom_type:<name>` from evidence |
| `filters` | Opaque filter list + normalized taxonomy intent where shape known |
| `ordering` | Including `random` as **ordering intent** (not compiler randomness) |
| `limit` / `offset` | Numeric bounds when present |
| `merge_policy` | e.g. disable merge when proven |
| `repeat_root_node_id` | Design node subtree repeated per item |
| `scope_parent_intent_id` | Optional nested parent |
| `source_trace` | Full source query object |
| `resolution_status` | Lifecycle state |

### DataBinding (scalar)

| Field | Purpose |
| --- | --- |
| `id` | Stable id |
| `intent_ref` | Optional link to collection intent for loop scope |
| `target_node_id` | Design node |
| `target_kind` | `text`, `asset`, `link_url`, `attribute`, … |
| `field_expression` | Declarative reference token(s), not evaluated PHP/JS |
| `scope` | `loop_current`, `site`, `query_aggregate`, … |
| `fallback` | Explicit unresolved when provider omits field |
| `source_trace` | Path + raw string hash |
| `resolution_status` | Lifecycle state |

### Separation from Interaction

User/browser interactions stay in `interactions` registry. DataSourceIntent and DataBinding represent **data plane** only.

## 12. Query and data lifecycle state machines

### Scalar / binding lifecycle

```text
source_seen
  → source_classified
  → intent_normalized
  → provider_unbound
  → provider_bound
  → value_resolved
```

Terminal / exception: `provider_unbound`, `unsupported_source_shape`, `opaque_expression`, `invalid_binding`, `resolution_failed`, `resolved`.

Guards: normalization must not call a provider; `provider_bound` requires explicit application adapter; `value_resolved` requires authorized provider response.

### Collection lifecycle

```text
query_declared
  → query_normalized
  → provider_unbound
  → provider_bound
  → collection_loaded
  → items_bound
  → subtree_instantiated
```

Terminal / exception: `empty_collection`, `provider_unbound`, `query_invalid`, `load_failed`, `collection_boundary_unproven`.

## 13. Security boundary

Dynamic strings are **untrusted templates**. Classification for observed corpus patterns:

| Class | Corpus examples |
| --- | --- |
| KNOWN_DECLARATIVE_SHAPE | `{post_title}`, `{featured_image}`, `{site_url}`, `{post_id}`, `{post_content:16}`, `{query_results_count:<id>}` |
| OPAQUE_SOURCE_EXPRESSION | Taxonomy tokens in `tax_query` (`happyfiles_category::…`) — preserve in trace; do not parse as SQL |
| UNSAFE_EXECUTABLE | Not observed as binding values; `javascriptCode` blocks are separate X09 surface |
| EVIDENCE_INSUFFICIENT | Header menu item population |

Future rules: no `eval` of Bricks/PHP/JS; no implicit shortcodes; no URL fetch from binding strings; HTML/attribute injection mitigated at render boundary; provider enforces tenant isolation; bounded limits on collection size.

## 14. Provider boundary

```text
Bricks query/dynamic source
        ↓
Bricks adapter (classify + normalize)
        ↓
DataSourceIntent / DataBinding in Design IR
        ↓
application-supplied DataProvider (explicit tenant context)
        ↓
records / values
        ↓
LiveFrames render layer
```

**LiveFrames core** owns normalization, validation, deterministic unresolved states, and lifecycle.

**Application provider** owns WordPress/Ash/DB/static fixtures, caching, and batch loading.

Invariant: **source query cannot choose or escape tenant context**; caller passes tenant/application scope into the provider.

## 15. Determinism contract

- **Source normalization** must be deterministic: same export + adapter version → same QueryIntent/DataBinding ids and serialized IR, independent of live database contents.
- **Ordering intent `random`** is stored declaratively; the compiler must not shuffle nodes. Nondeterministic ordering, if any, happens only when the application provider resolves `ordering = random` at render/data time (explicit policy in C-09B+).
- Database snapshots during compile are out of scope unless a future explicit snapshot mode is authorized separately.

## 16. Performance and scaling review

Future implementation (not this PR):

- Load each collection intent once per provider bind; no N+1 provider calls per repeated child node.
- Batch asset resolution for image bindings sharing an intent.
- Enforce limits (`posts_per_page`, reasonable caps) at normalization validation.
- Stream or page large collections at provider discretion.
- Caching belongs to the application provider, not the Bricks adapter.

C-09A audit: DB 0, Redis 0, network 0, runtime fetch 0.

## 17. Design IR fit analysis

Design IR `1.0.0` provides:

- `DesignNode.content` — static or unresolved content, not a registry for loop-scoped bindings.
- `DesignNode.asset_refs` — static asset registry references; dynamic `{featured_image}` must **not** appear as resolved static assets.
- `DesignNode.interaction_refs` + root `interactions` — behavior only.
- No root registry for data sources or bindings.

Fidelity needs repeated subtrees and bound field values; preserving query objects only inside diagnostics/`SourceTrace` on nodes is insufficient for truthful template reconstruction.

**Answer:** query/data needs a **new first-class root registry** (or registries) and node **references**, analogous to `assets` and `interactions`, without overloading `Interaction` or stuffing opaque JSON into `content` alone.

## 18. IR version decision

**Decision: `IR_VERSION_DECISION_REQUIRED`**

Adding required root fields (`data_sources`, `data_bindings`, or equivalent) and reference lists on nodes changes the serialized contract and validation semantics. Staying on `1.0.0` by overloading `content` or `Interaction` would misrepresent field meaning.

**IR_VERSION_CHANGE_LIKELY:** yes

## 19. Failure-mode register

| Mode | Owner | Handling |
| --- | --- | --- |
| Unknown query shape | Adapter | `unsupported_source_shape` + diagnostic |
| Unknown dynamic expression | Adapter | `opaque_expression` |
| Provider missing | Compile/render | `provider_unbound` |
| Wrong cardinality returned | Provider | `resolution_failed` |
| Field missing | Provider | Explicit fallback or `resolution_failed` |
| Binding target missing | Adapter validation | `invalid_binding` |
| Asset result unsafe/unapproved | Asset authority gate | Block resolution (C-08 lineage) |
| Empty collection | Provider | `empty_collection`; optional empty subtree policy |
| Non-deterministic ordering intent | Normalizer | Store intent; do not randomize in compiler |
| Nested context unresolved | Adapter | `nested_context_unresolved` |
| Collection boundary unproven | Adapter | `collection_boundary_unproven` (Header Basel) |

No silent defaults to live WordPress data during normalization.

## 20. Binding target matrix

| Binding target | Occurrences | Context required | Provider required | Current IR support | Gap |
| --- | ---: | --- | --- | --- | --- |
| Text content | 5 | Loop / site / query aggregate | Yes | `content` static only | No binding ref or scoped override |
| Image / asset | 4 | Loop record | Yes | `asset_refs` static | Dynamic asset must stay unresolved |
| Link URL | 1 | Site | Yes | attributes partial | No URL binding model |
| Query result count | 1 | Query owner id | Yes | none | Missing aggregate binding |
| Component option | 0 | — | — | — | Not proven |
| Style value | 0 (CSS braces excluded) | — | — | StyleValue | Not data-bound in corpus |

## 21. Random ordering (Gallery Bravo)

Gallery QS-07 sets `orderby: ["rand"]`. Normalized **`ordering_intent = random`**. Compilation remains deterministic; provider/application chooses shuffle or stable surrogate when serving data.

## 22. Asset bindings vs AssetReference

Dynamic image bindings (`useDynamicData` on `image`) must produce **DataBinding** targets with `resolution_status: provider_unbound`. They must not create `AssetReference` entries with `redistribution_status` implied resolved. Static S1 icon pipeline (C-08) remains separate.

## 23. Navigation / menu data

Header QS-01 proves repeated list **items** with query stubs and merge disabled, but not dynamic label/URL fields. Minimum contract: **`navigation_collection` stub** with `collection_boundary_unproven` until labels/URLs bind to records or authority supplements. No hierarchy or current-page semantics proven in Header export (Slide Menu Alpha uses static structure + JS note about query compatibility without query objects in JSON).

## 24. Pagination

Exports prove static **limits** (`posts_per_page`: `4`, `-1`) and **offsets** (Hero). No `paged`, cursor, or page-number state proven. Distinguish **limit/offset configuration** from **interactive pagination** — only the former is in scope.

## 25. Query nesting

**Nested query proven:** Feature Milan parent QS-02 + child QS-03 (`05e604` under `ebbb6e`). No deeper nesting observed. No dynamic binding proven that references parent-loop record explicitly by syntax.

## 26. Exact next implementation slice

**Recommended next branch: `C09B_IR_VERSION_AUTHORITY`**

1. Author Design IR `1.1.0` (or successor) decision record: root `data_sources` / `data_bindings` (names TBD), node reference fields, validation, serialization tests.
2. Keep Bricks adapter changes minimal until IR gate merges: no provider, no WordPress.
3. Map QS-01 … QS-07 and DB/TB shapes to normalized enums in a follow-on adapter slice (C-09C).

Not recommended next: `C09B_EVIDENCE_PRESERVATION` alone (IR cannot truthfully represent semantics on 1.0.0); `C09B_PROVIDER_CONTRACT` before IR version; Frames component runtime.

## 27. Explicit non-goals (C-09A)

- No query execution, WordPress, or provider implementation
- No Design IR schema or production code changes
- No use of drifted `frames-components` corpus
- No Bricks 2.4.2 runtime semantics as authority
- No repurposing `Interaction` as data model
- No Frames widget/modal/tabs runtime
- No customer-specific raw expression publication beyond hashes and generic field names

---

## Audit confirmations

- No query was executed.
- No dynamic expression was evaluated.
- No database or network source was contacted.
- The drifted Frames component corpus was not used.
- Interaction IR was not repurposed as a data model.
- No production code or Design IR schema changed.
