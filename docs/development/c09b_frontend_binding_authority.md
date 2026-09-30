# C09B Frontend Binding and Repetition Authority

This document freezes the frontend contract required to reproduce dynamic
source UI with caller-supplied Phoenix data. It is a target authority for later
implementation; it does not claim that the current Design IR or generators
already support these concepts.

## 1. Accepted base

The accepted C09A base is:

| Item | Value |
| --- | --- |
| Main commit | bed398add9e3dab2abff28e23357234e6f23c419 |
| Main tree | 7e7a71b9d070305005d1182c52a6b3f211431880 |
| Exact-main CI | 36734667858, completed / success |

This authority preserves the C09A evidence about frontend repetition,
bindings, nested structures, and source provenance. It replaces C09B's
backend query and provider framing.

## 2. Correction of C09 direction

LiveFrames is a frontend compiler. The C09B question is:

> What frontend inputs and repetition contracts are required to reproduce the
> source UI using caller-supplied Phoenix data?

It is not how LiveFrames should normalize or execute source queries. Bricks
query configuration remains useful provenance. It does not obligate LiveFrames
to implement a query abstraction or reproduce the source backend.

## 3. LiveFrames frontend-only boundary

| LiveFrames owns | Host Phoenix application owns |
| --- | --- |
| Frontend structure and component inputs | Ash queries and database access |
| Collection inputs and repeated subtrees | APIs and CMS data access |
| Value bindings within item or site scope | Tenant context and backend authorization |
| Frontend state, events, and interaction intent | Backend filtering, ordering, and pagination |
| HEEx / LiveView generation | Data fetching and caching |
| Frontend slots and attributes where a later component phase chooses them | Which authorized values are supplied |

LiveFrames does not need a WordPress-compatible query engine. Its generated
frontend consumes values supplied by the host application.

## 4. C09A evidence retained

C09A establishes these frontend facts:

- Collection repetition exists for feature cards, slides, hero media, and a
  gallery.
- Scalar bindings exist for text, image/asset, link URL, and collection/result
  count.
- A nested repeated structure exists in the Feature Milan evidence.
- Loop-current item scope exists.
- A site/global value exists independently of a collection.
- QS-01 Header Basel query settings do not prove a repeat boundary or dynamic
  label/link bindings. No navigation/menu semantics are inferred.
- A modifier is present in the content expression shown as
  {post_content:16}, but its meaning is unproven.

The source query evidence remains available for traceability. These facts do
not establish LiveFrames backend query responsibilities.

## 5. Collection and repetition semantics

The source-independent concept is CollectionBinding. It binds a caller-supplied
collection input to a subtree that is rendered once per supplied item.

A CollectionBinding means:

- this source node owns a frontend collection boundary;
- this subtree is the item template; and
- the generated frontend expects a collection value from its caller.

It does not mean that LiveFrames runs a query, filters records, chooses an
order, limits results, or fetches data.

Emit a CollectionBinding only when both its owner and repeated subtree are
supported by evidence. QS-01 has query settings but no proven repeat boundary;
it remains source trace and a diagnostic, with no CollectionBinding and no
invented repeat root.

### CollectionBinding fields

| Field | Type | Required | Allowed values or invariant | Frontend meaning |
| --- | --- | --- | --- | --- |
| collection_binding_id | non-empty string | yes | Deterministic within a normalized document | Stable identity for this collection input and repeat contract |
| owner_node_id | node ID | yes | Must resolve to a DesignNode | Node that declares or owns the source repetition |
| repeat_root_node_id | node ID | yes | Must resolve to a DesignNode | Root of the subtree rendered once for each supplied item |
| parent_collection_binding_id | collection binding ID or nil | no | Must resolve when set; cannot be self; graph must be acyclic | Enclosing repeat context for nested repetition |
| normalization_status | enum | yes | normalized, evidence_insufficient, unsupported | Compile-time confidence in the frontend repetition contract |
| source_trace | SourceTrace | yes for source-derived records | Identifies source owner, path, adapter/version, relevant source settings, and inference | Audit trail for the inferred frontend contract |

No item scope name or caller attribute name is stored here. The referenced
collection binding identifies the item scope; a later componentization phase
chooses native Phoenix input names.

Collection and value binding IDs are deterministic for the same normalized
source, adapter version, and stable source-to-IR traversal. They do not depend
on host data, fetched records, or runtime order. Source-system IDs may be
retained in SourceTrace but do not replace the normalized registry ID.

## 6. Scalar and value binding semantics

ValueBinding means a generated frontend node target receives a value from
caller-supplied component or item data. It stores the binding declaration, not
the value.

A node can be structurally static and still have a ValueBinding. A
CollectionBinding marks a repeated subtree; its children may contain value
bindings. These are separate concepts. Frontend interaction state remains in
the existing interaction model and is not a value binding.

### ValueBinding fields

| Field | Type | Required | Allowed values or invariant | Frontend meaning |
| --- | --- | --- | --- | --- |
| value_binding_id | non-empty string | yes | Deterministic within a normalized document | Stable identity for this value binding |
| target_node_id | node ID | yes | Must resolve to a DesignNode | Node receiving the bound value |
| target_kind | enum | yes | text, asset, link_url | Frontend destination represented by the binding |
| value_kind | enum | yes | field, collection_count | Whether the value is a semantic field or a collection count |
| scope | enum | yes | collection_item, site, collection | Caller-data scope from which the value is supplied |
| value_key | source-independent semantic key or nil | conditional | Required for value_kind field; absent for collection_count | Normalized frontend meaning, not a raw source field name or Phoenix API name |
| collection_binding_id | collection binding ID or nil | conditional | Required for collection_item and collection scopes; absent for site scope | The repeat context or collection whose supplied values this binding uses |
| modifier_status | enum | yes | none, opaque | Whether a source modifier exists and whether its meaning is understood |
| normalization_status | enum | yes | normalized, evidence_insufficient, unsupported | Compile-time confidence in the binding meaning |
| source_trace | SourceTrace | yes for source-derived records | Identifies source target, expression/settings, adapter/version, and inference | Audit trail for the inferred frontend binding |

Scope and value consistency rules:

- field + collection_item requires a collection binding and a value_key.
- field + site requires a value_key and no collection binding.
- collection_count + collection requires a collection binding and no value_key.
- Other combinations are invalid until evidence and a later authority define
  them.

The value_key is a normalized, source-independent semantic identifier. It is
not the original source field spelling and does not prescribe a generated
component input. For example, source post_title may establish the semantic key
content.title; source featured_image may establish media.primary; source
post_content may establish content.body when the modifier is absent or
understood. The original source identity remains in SourceTrace. A later
componentization phase may map that key to an attribute, slot, item field, or
another frontend API.

ValueBinding IDs follow the same deterministic rule as collection IDs.

An opaque modifier makes the binding evidence_insufficient unless its
semantics are separately established. For {post_content:16}, the normalized
meaning may retain the proven base-field identity and modifier_status opaque.
The value must not be silently treated as an unmodified body value.

Fallback behavior is deferred. No provider-resolved value, fetched record,
placeholder asset, or runtime value is stored in Design IR.

## 7. Nested repetition

A nested CollectionBinding points to its enclosing CollectionBinding through
parent_collection_binding_id. This records only the frontend nesting
relationship. It does not represent a nested backend query.

The collection graph must be acyclic. A record cannot parent itself. Every
owner and repeat-root node must exist. For nested repetition, the child owner
must lie within the parent repeat-root subtree. The child repeat-root
identifies the inner template. No execution depth or backend query behavior is
implied beyond the represented structure.

## 8. Proven frontend target kinds

C09A supports only these target meanings in this authority:

| Frontend target | ValueBinding representation |
| --- | --- |
| Text/content | target_kind text; field binding or collection_count |
| Image/asset | target_kind asset; field binding |
| Link URL | target_kind link_url; field binding |
| Collection/result count | value_kind collection_count, scope collection, target_kind text |

A dynamic asset binding is not an AssetReference. It remains a caller-data
binding until the host application supplies a value. It must not create a
placeholder resolved asset.

For a collection count, the host may supply a count alongside the collection.
The frontend may derive length from the supplied items only when that matches
the intended display. A count must not imply a backend count operation or
promise a total across host-side pagination.

## Registry and reference invariants

The proposed successor registries are JSON objects. After JSON key
normalization, keys must be unique, non-empty, and equal to the corresponding
collection_binding_id or value_binding_id. Each record must be JSON-compatible.
The serializer must sort registry object keys deterministically and preserve
list order and SourceTrace content.

Validation must report all discoverable violations and must not silently
repair or discard records. It must check:

- registry object shape, key/ID agreement, and non-empty IDs;
- owner_node_id, repeat_root_node_id, and target_node_id references;
- parent collection existence, no self-parent, and an acyclic parent graph;
- a nested collection owner lies under its parent repeat root;
- collection_item bindings reference an existing collection and target a node
  within that repeat root;
- collection_count bindings reference an existing collection;
- site bindings have no collection reference;
- field bindings have a value_key, while collection_count does not; and
- target kind, value kind, scope, modifier status, normalization status, and
  SourceTrace shape.

Future registry records must survive serialize, load, validate, and serialize
again without loss. The current loader's interaction round-trip omission is
known evidence from the prior C09A review; it is not corrected here and must
not be repeated for collection or value bindings.

## 9. Source-specific provenance boundary

Source-specific details remain in SourceTrace, including Bricks element/query
owner identity, source path, adapter and version, relevant raw source settings,
raw expressions, and normalization inference.

Bricks query settings such as post_type, taxonomy constraints, ordering,
offset, posts_per_page, and disable_query_merge are provenance. They are not
generic collection fields unless a separately proven frontend consequence
requires a frontend contract field.

Raw Bricks expressions such as {post_title}, {featured_image},
{query_results_count:...}, and {post_content:16} remain in SourceTrace. Generic
IR carries only proven frontend meaning. No raw source expression is evaluated
or stored as an executable generic binding.

## 10. HEEx / LiveView caller-data model

The intended flow is:

    Bricks / Frames source
             |
             v
    LiveFrames frontend IR
             |
             v
    HEEx / LiveView component contract
             |
             v
    host application assigns, attributes, and slots

For example, a source feature-card loop may become a component that accepts an
items value, with item.title bound to a heading and item.image bound to an
image. A gallery may similarly accept caller-supplied gallery items.

Conceptual render sites could look like:

    <.feature_cards items={@features} />
    <.gallery items={@gallery_items} />

These examples do not freeze a component API. C09B does not decide exact
assign names, item structs, slots, event interfaces, or component boundaries.
The later native-component phase chooses those from frontend IR and application
needs.

## 11. Normalization lifecycle

The normalization process is declarative and compile-time:

    source_seen
        -> frontend_semantics_classified
        -> binding_normalized

The persistent terminal statuses are normalized, evidence_insufficient, and
unsupported. They describe source-to-frontend normalization only:

- normalized means the repeat or value-binding semantics are supported by
  evidence;
- evidence_insufficient means source evidence exists but does not prove the
  needed frontend meaning; and
- unsupported means the source shape cannot be represented by this contract.

Status changes do not fetch, resolve, sort, filter, or mutate caller data.
There is no provider lifecycle in this authority. A later generator must
diagnose or preserve an unresolved dynamic declaration; it must not emit a
static value that pretends the binding was resolved.

## 12. Current Design IR fit

Design IR 1.0.0 has root registries for assets and interactions. DesignNode
has generic content and attributes, plus asset and interaction references.
SourceTrace records source evidence and inference. None of those fields defines
a repeat boundary, a caller collection input, an item scope, or a typed target
binding.

The current validator accepts only DesignDocument.current_ir_version()
(currently 1.0.0); another non-empty version is rejected. A successor
consumer therefore needs the explicit migration path described below before
successor validation.

Overloading content or attributes would invent a public convention absent from
the current contract. Reusing AssetReference or Interaction would change
their meanings. Putting the semantics only in SourceTrace would make them
provenance rather than consumable frontend IR.

## 13. IR version decision

| Option | Evaluation |
| --- | --- |
| A: use 1.0.0 unchanged | Rejected. It cannot truthfully represent collection repetition or typed value bindings using existing public meanings. |
| B: add first-class frontend registries | Required. Add root collection_bindings and value_bindings registries; leave DesignNode unchanged. |
| C: incompatible redesign | Not required. The existing tree, trace, asset, and interaction structures remain useful. |

IR_CHANGE_REQUIRED: yes.
NODE_REFERENCE_DECISION: keep DesignNode unchanged. CollectionBinding and
ValueBinding records reference nodes from root registries; no node-side
collection_refs or value_binding_refs arrays are added.

The current Design IR authority says a serialized-shape, required-field,
field-meaning, or validation-rule change requires a new IR version and an
explicit migration decision. The repository does not define whether such an
additive contract change increments the major or minor SemVer component.
The master specification places the general semantic-versioning policy in
Phase 11. Therefore this authority does not select a new numeric version.

TARGET_IR_VERSION: undecided due absent repository version-bump policy.

The next authority step must establish the applicable version-bump rule and
then assign the successor number before schema implementation. The prior
2.0.0 proposal is superseded and is not evidence for a version number.

### Root field comparison

| Root field | 1.0.0 | Proposed successor | Required | Meaning | Migration default |
| --- | --- | --- | --- | --- | --- |
| ir_version | Required | Required | yes | One schema version per document | Set to the selected successor |
| source_metadata | JSON object | JSON object | yes | General source identity and conversion context | Preserve |
| token_set | JSON object | JSON object | yes | Semantic tokens | Preserve |
| root_nodes | DesignNode list | DesignNode list | yes | Ordered design tree | Preserve |
| assets | Registry map | Registry map | yes | Static asset definitions | Preserve |
| interactions | Registry map | Registry map | yes | Frontend interaction intent | Preserve |
| collection_bindings | Absent | Registry map | yes | Caller collection inputs and repeated subtrees | Empty map; never inferred from trace during structural migration |
| value_bindings | Absent | Registry map | yes | Caller-supplied frontend values and targets | Empty map; never inferred from trace during structural migration |
| diagnostics | Diagnostic list | Diagnostic list | yes | Normalization and validation findings | Preserve |
| provenance | JSON object | JSON object | yes | Origin, adapter and migration evidence | Preserve; migration provenance may be added |

Every document has one schema version. Adapters must not choose it per node.
Once the successor version is selected, new normalization writes that version
only.

## 14. Migration decision

A new version is required by the current IR authority, so migration is
applicable. The selected policy is an explicit, deterministic structural
migration from 1.0.0 before successor validation:

- preserve all 1.0.0 fields and existing meanings;
- add empty collection_bindings and value_bindings registries;
- retain migration evidence in the existing provenance object, including
  source version, target version, migration kind structural, and
  frontend_semantics_recovered false;
- do not infer repetition or bindings from SourceTrace during structural
  migration; and
- do not write new documents as 1.0.0 after successor implementation.

The exact target number remains pending the version-bump policy decision. This
authority freezes the migration shape and non-inference rule, not the numeric
version.

Structural migration can preserve only semantics already represented in
1.0.0. If frontend binding or repetition semantics must be recovered, the
original Bricks / Frames source must be normalized by a successor adapter.
The generic IR migrator does not parse Bricks.

## 15. Security boundary

LiveFrames must not evaluate source expressions, execute PHP, execute
WordPress queries, run source-provided SQL, fetch dynamic URLs because a source
references them, or accept source data as authority for tenant/backend
context. Backend authorization and data access remain with the host
application.

Generated HEEx / LiveView must later escape and validate caller-supplied
frontend values according to the selected output target. C09B defines that
boundary but does not implement the generator.

## 16. Performance boundary

LiveFrames concerns for this contract are deterministic normalization,
compact binding metadata, no duplicated large source payloads, reasonable
generated template size, and efficient rendering of caller-provided
collections.

Database access, batching, caching, pagination, and backend collection size
are host application concerns. Design IR stores no fetched records or
unbounded result sets.

## 17. Exact next implementation slice

After this authority is reviewed:

1. Resolve the repository's IR version-bump rule and assign the successor
   number in a focused authority decision.
2. C09C1 may then implement the two core frontend registries, version,
   deterministic serialization, and validation boundary.
3. A later adapter slice may map only evidenced Bricks repetition and value
   shapes into the frontend contract.
4. A later componentization/generator slice may choose native Phoenix attrs,
   slots, item shapes, events, and state.

No C09C implementation is authorized or started by this document.

## 18. Non-goals

C09B does not implement Design IR structs, validators, serializers, loader
changes, adapters, HEEx components, LiveView runtime behavior, source query
execution, DataProvider APIs, Ash integrations, database or API access,
filtering, ordering, pagination, caching, tenant handling, backend
authorization, or native Phoenix component APIs.
