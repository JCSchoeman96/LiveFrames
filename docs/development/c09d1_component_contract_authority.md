# C09D1 Phoenix component contract authority

**Status:** authority/documentation only

**Accepted base:** `baa969eb61e2454c6889bb29d076fdf1015032f7`

**Accepted tree:** `9904b56444118989fa99f98b7d5358b9b72f24a1`

**Post-merge CI:** run `36920938814`, completed with conclusion `success`

This authority defines the componentization boundary after Design IR 2.0.0 and
before any HEEx generator. It does not implement a struct, componentizer,
generator, Phoenix module, runtime accessor, or Catalogue record.

## 1. Scope and product boundary

The pipeline is:

```text
source parsing
    -> Design IR normalization
    -> componentization
    -> approved Phoenix component contract
    -> later HEEx generation
```

These stages answer different questions:

- Parsing records what the source contains.
- Design IR records normalized frontend meaning.
- Componentization chooses a reusable public API.
- Generation writes source code that implements that approved API.

The C09B, C09B1, and C09C2 authorities define frontend `CollectionBinding`
and `ValueBinding` meaning. They do not define public Phoenix names. C09D1
chooses those names only after a semantic component boundary is selected.

LiveFrames owns presentation, semantic HTML, component structure, responsive
behavior, repeated presentation, and frontend validation. The host application
owns Ash resources, schemas, queries, APIs, CMS data, tenant context,
authorization, filtering, ordering, pagination, caching, and data adaptation.
Every generated component receives caller data. It never fetches it.

## 2. ComponentContract artifact

`ComponentContract` is the source-independent componentization artifact. It is
the only input a later generator may use to decide a generated public API.

The conceptual record contains these fields:

| Field | Meaning |
| --- | --- |
| `contract_format_version` | Version of the serialized ComponentContract format, initially `1.0.0`. This is separate from Design IR, CatalogueItem release, and package versions. |
| `contract_id` | Stable, non-empty semantic identity for the component contract. It is not a source ID. |
| `category` | One of `primitive`, `component`, `pattern`, or `section`. |
| `module_intent` | Source-independent Phoenix module intent selected by componentization. |
| `function_intent` | Source-independent Phoenix function-component intent selected by componentization. |
| `public_attrs` | Ordered semantic attr definitions. |
| `public_slots` | Ordered semantic slot definitions. |
| `collection_inputs` | Ordered `CollectionInput` metadata records for admitted repeated data. Each record references one source `CollectionBinding` and either a top-level `public_attrs` list entry or a nested parent item field. |
| `binding_projections` | Compiler metadata connecting IR bindings and targets to public inputs. |
| `diagnostics` | Accumulated contract findings. Validation does not hide them. |
| `provenance` | Source traces, IR binding IDs, selected classification evidence, and reviewer decisions. |
| `approval_status` | `proposed`, `approved`, `needs_review`, or `rejected`. This is an approval result, not a second lifecycle. |

Each attr definition records `name`, Phoenix type, required/default behavior,
semantic purpose, binding provenance, validation requirements, and any
accessibility consequence. `public_attrs` is the sole authority for those
Phoenix attr properties. Each slot definition records its semantic purpose,
validation information, cardinality, and consumer responsibility. Each
collection input records its source `CollectionBinding` identity, its location
(top-level public attr or nested parent item field), item fields, count
relationship, and provenance. It does not redefine the referenced attr or
parent item field type, requiredness, default, semantic purpose, or validation.

The contract contains no fetched records, query plans, provider references,
runtime values, raw HTML, executable expressions, or source-system fields.
Source-specific identifiers may appear only under provenance.

### 2.1 Artifact decision

`ComponentContract` is an explicit, versioned, serializable compiler artifact.
Its `contract_format_version` starts at `1.0.0`. C09D2 must provide
deterministic representation, validation, and serialization for this format.
The format version is not reused from Design IR 2.0.0, CatalogueItem release
SemVer, or the Mix package.

`contract_format_version` describes only serialized shape and meaning:

- PATCH corrects representation, documentation, or validation while preserving
  the authorized serialized shape and meaning.
- MINOR adds an optional serialized field or optional format capability that a
  newer reader can read without migration while preserving earlier contracts.
- MAJOR adds a required field, removes or renames a field, changes serialized
  meaning incompatibly, changes enum or shape semantics incompatibly, makes a
  previously valid contract structurally incompatible, or requires migration.

Adding or removing a component attr, changing a slot, changing cardinality, or
changing behavior ownership does not change `contract_format_version` by
itself. Those are consumer-facing compatibility questions owned by
`docs/24_CATALOGUE_VERSIONING_POLICY.md` once a component participates in
Catalogue release/versioning. A pre-Catalogue contract content change does not
create a new format version unless the serialized format itself changes.

A generated module must not infer a public API from a contract that lacks
approval.

## 3. Category and page decisions

`ComponentContract.category` uses the existing taxonomy only:

```text
primitive | component | pattern | section
```

The category describes the selected reusable semantic boundary. It does not
describe a source editor element, CSS class, or implementation wrapper.

`page` is not a fifth `ComponentContract.category`. A page is a separate
generation target that may compose approved component contracts and sections.
If a future page contract is needed, it receives its own authority and record
shape. A page target cannot bypass component contract approval for its child
components.

## 4. Classification and lifecycle gate

Componentization requires all of the following:

```text
valid Design IR
    + selected semantic component boundary and category
    + representable binding semantics
    -> ComponentContract may be proposed
```

Classification cannot be derived solely from editor names, source labels, CSS
classes, wrapper depth, or a valid IR document. A selected boundary must have a
semantic role and a deliberate reusable consumer contract. Ambiguous
classification produces `NEEDS_REVIEW` and no automatic public API.

The existing `ConversionJob` lifecycle remains the only pipeline state
machine:

```text
NORMALIZING
    -> COMPONENTIZING
    -> GENERATING
```

Within `COMPONENTIZING`, the gate is:

```text
classification selected
    -> contract proposed
    -> contract reviewed and approved
    -> GENERATING may begin
```

`approval_status` records the contract decision. The native Hero lifecycle
labels (`api_proposed`, `api_approved`, and later implementation evidence) are
review vocabulary, not a competing persisted state machine. `NEEDS_REVIEW` is
the exceptional ConversionJob outcome when classification, naming, binding
projection, accessibility, or public API semantics cannot be inferred safely.

`GENERATING` is impossible until `approval_status` is `approved` and contract
validation has no blocking diagnostic.

## 5. Phoenix-native output model

The default output target is a stateless `Phoenix.Component` function
component with declarative `attr/3` and `slot/3` declarations. Public inputs
must be ordinary Phoenix attrs, slots, and assigns derived from those
declarations.

The normal API is not a universal `@props`, `props` map, `bindings` map, or
`data` map. A contract that requires such a map for ordinary use is invalid and
must be redesigned into named attrs, slots, or collection item fields.

`Phoenix.LiveComponent` is allowed only when independent evidence proves all
of the following:

1. the component owns reusable state or events;
2. that state is meaningfully local to the component;
3. parent LiveView ownership would create worse coupling; and
4. a stable unique component identity can be required.

Presentation-only toggles, client-side behavior, navigation, and consumer
events do not satisfy this rule. Current C09 evidence proves no component-owned
state or events.

## 6. Attr and slot contract

### 6.1 Attr rule

Use attrs for plain scalar content, typed configuration, URLs, media
references, counts, and structured caller data when LiveFrames owns the
rendering. Use the narrowest truthful first-wave Phoenix type:

```text
:string | :integer | :boolean | :list | :map | :global
```

`:any` is permitted only when a separately reviewed Phoenix value cannot be
represented by those types. It is never the default. Public attr types are
chosen from semantic meaning, not copied from source strings.

Every attr declares its required/default behavior. A default is added only
when omission has a reusable meaning across the selected contract. A fixture's
one value never supplies a default for all consumers.

### 6.2 Slot rule

Use slots when the consumer owns arbitrary Phoenix markup, navigation or
action behavior, events, interactive roots, or application-owned composition.
Dynamic source origin alone never turns a value into a slot. A source string
is not automatically an attr either.

Each slot definition records:

```text
semantic name
cardinality
required/optional status
consumer responsibility
accessibility implications
```

The default cardinality for a singular semantic role is `0..1`. Repeated slots
require evidence of a repeated consumer-owned markup role. A slot is not a
substitute for choosing a data model, and nested DesignNode structure does not
create arbitrary slot DSLs.

Navigation, events, and business behavior remain consumer-owned. Generated
contracts do not infer `phx-click`, `navigate`, `patch`, JavaScript commands,
event names, or Ash actions from source evidence.

### 6.3 Global attributes and class

Generated DOM-root components expose `class` as an additive string extension
when a root has a meaningful style contract, and `rest` as Phoenix `:global`
attributes. Internal semantic classes remain component-owned. Source classes
never become public inputs. Raw inline `style` is not the primary extension
API.

Expose `id` when the semantic root has a meaningful DOM identity, linking,
labeling, test, or interaction need. Do not add an `id` input or generated ID
when no such use exists. Consumers provide unique IDs.

Consumer global attributes can change semantics, visibility, ARIA, focus,
LiveView bindings, or appearance. Those effects are consumer-owned and are not
silently folded into LiveFrames accessibility guarantees.

## 7. Collection projection

### 7.1 Public collection input

An admitted root/top-level `CollectionBinding` has
`parent_collection_binding_id = nil`. It projects by default to one semantic
`:list` attr in `public_attrs`, not to a repeatable arbitrary-markup slot and
not to a backend query. The componentizer chooses the public name from the
component role:

```text
pricing section -> plans
team grid       -> members
feature grid    -> features
```

An unresolved semantic role produces `NEEDS_REVIEW`; it does not fall back to
the literal name `items`. Query names, source element IDs, and source field
paths never choose the public name.

The top-level `CollectionInput` stores `public_attr_name`, with both parent
location fields set to `nil`, its item fields, any top-level count relation,
and binding/provenance metadata. `public_attr_name` must identify exactly one
existing `public_attrs` entry with type `:list`. That entry remains the sole
authority for its name, type, required/default behavior, semantic purpose,
validation, and accessibility consequence. The public collection attr has
Phoenix type `:list`. Requiredness depends on the approved component
semantics. An optional collection may default to `[]` only when the component
has a valid empty state. A required collection has no invented default. The
contract records whether an empty list omits, empties, or renders a deliberate
empty state.

### 7.2 CollectionInput and item shape

Each source `CollectionBinding` produces exactly one conceptual
`CollectionInput`. The compiler identity and reference key is
`source_collection_binding_id`, which must be non-empty and unique within the
contract. It is compiler/provenance metadata, not a public Phoenix name. No
separate `collection_input_name` is required.

The two location modes use this conceptual shape:

```text
source_collection_binding_id

public_attr_name
  # top-level only

parent_collection_binding_id
parent_item_field_name
  # nested only

item_fields

count_attr_name
  # top-level count only

count_item_field_name
  # nested count only

binding/provenance metadata
```

A top-level record has `public_attr_name` present and both nested location
fields nil. A nested record has `public_attr_name` nil and both nested location
fields present. These modes are mutually exclusive. A `CollectionInput` cannot
redefine the referenced attr or item field type, required/default behavior,
semantic purpose, validation, or accessibility consequence.

Items are caller-provided semantic maps or struct-like values. Item fields use
public semantic names chosen by componentization, such as `name`, `price`,
`image`, or `label`. Callers do not expose `content.title`, `media.primary`,
or another internal `value_key` as a literal nested key unless a separately
approved contract explicitly chooses that name.

Each item field records `name`, Phoenix type, required/default behavior,
semantic purpose, binding provenance, validation requirements, and any
accessibility consequence. A field is not required merely because the source
contained a value. The componentizer decides whether a field is required to
render the approved semantic role.

### 7.3 Collection item access

Later generated code uses one explicit safe accessor contract for item fields.
The accessor accepts a caller item and a compiler-selected public field name
as a string. It resolves, in order:

1. an exact string key in a map;
2. an existing atom key whose `Atom.to_string/1` equals the public field name.

Structs use the same existing-key lookup. After lookup, the item-field
definition controls absence and validation:

```text
required field missing
    -> clear contract validation/access error

optional field missing with an explicit default
    -> use the contract-defined default

optional field missing without an explicit default
    -> resolve as nil / absent optional value

present field with an invalid value
    -> field validation error
```

Non-map items and invalid item shapes fail with a clear contract error. The
accessor never calls `String.to_atom/1`, `String.to_existing_atom/1`, a
source-dependent module, or an arbitrary function supplied by source data. It
does not interpret dotted paths or execute accessors from strings. If both
string and atom keys exist, the exact string key wins.

This is an explicit accessor contract for later implementation, not a request
to add the accessor in C09D1.

### 7.4 Nested collections

A nested `CollectionBinding` has
`parent_collection_binding_id != nil`. It does not create a top-level
`public_attrs` entry. Its `CollectionInput` sets `public_attr_name` to `nil`,
references the existing parent `CollectionInput` through
`parent_collection_binding_id`, and sets `parent_item_field_name` to an
existing item field on that parent. The parent item field must have type
`:list` and owns the nested field public name, required/default behavior,
semantic purpose, validation, and accessibility consequence.

The nested binding must have a proven parent relationship in IR and a selected
semantic child role. If either is unresolved, approval is blocked. The child
`CollectionInput` adds only the source binding relationship, child item shape,
nested count relationship, and provenance. Its child fields stay inside the
nested list on each parent item. They are not flattened into the outer item or
top-level attrs, merged with sibling lists, or converted to a slot. The
child-to-parent reference is canonical; child collections are derived by
indexing `parent_collection_binding_id` when needed. The parent graph must be
acyclic, and a child cannot reference itself or a missing parent.

### 7.5 Collection count

When a design visibly renders a collection count, the location follows the
owning `CollectionInput`.

For a top-level collection, the count is a scalar `:integer` entry in
`public_attrs` with non-negative validation. The top-level `CollectionInput`
stores `count_attr_name`, and the count uses
`projection_kind = collection_count_attr`. The count attr owns its name, type,
required/default behavior, semantic purpose, and validation. It receives a
semantic name such as `plan_count` selected by the component role. It is not
automatically called `count` or `length`.

For a nested collection, the count varies per parent item. It is a scalar
`:integer` item field on the parent `CollectionInput`, with non-negative
validation. The child `CollectionInput` stores `count_item_field_name`, and
the count uses the existing `collection_item_field` projection kind. Its
source `ValueBinding.value_kind = collection_count` records that the field is a
collection count. The parent item field owns the count field name, type,
required/default behavior, semantic purpose, and validation.

A top-level `CollectionInput` has `count_item_field_name = nil`; a nested
`CollectionInput` has `count_attr_name = nil`. Both count fields may be nil
when no visible count exists. The contract never silently derives a count from
`length(items)`. The host may supply a total that differs from rendered list
length. If no count is supplied, the contract omits the count display or stays
`NEEDS_REVIEW`.

## 8. ValueBinding projection

`ValueBinding` maps through semantic role analysis. It does not mechanically
determine an attr name.

For a singular field outside a collection, a field becomes a scalar attr when
LiveFrames owns rendering and the semantic public role is proven. A text field
may become `heading`, `title`, `name`, or `label` according to the selected
component. An asset field may become `image`, `logo`, or another proven media
role. A link URL may become `destination` or `href` only when that role is
proven. The source `value_key` is not exposed merely for convenience.

For `scope = collection_item`, a field becomes an item field in its owning
`CollectionInput`, never an unrelated top-level attr. Fields owned by a nested
`CollectionBinding` remain in that child input, below the parent item list field.

For `value_kind = collection_count`, a top-level binding becomes the explicit
count attr associated with its owning top-level collection. A nested count becomes
the scalar count item field on its parent `CollectionInput`; it does not become a
top-level attr. Both cases retain `ValueBinding.value_kind = collection_count`.

Every projection records the source binding ID, target node ID, public input,
and status. A projection cannot silently change an evidence-insufficient or
unsupported binding into an ordinary field.

## 9. Evidence and unsupported targets

An evidence-insufficient `ValueBinding`, including an opaque source modifier,
blocks automatic contract approval when it affects visible, required, or
accessibility-relevant semantics. It remains provenance and diagnostic data
until a reviewer chooses one of these outcomes:

```text
resolve the semantics under a later authority
exclude the unsupported target from the candidate
reject the candidate
```

The componentizer must not mark the binding approved as an ordinary attr or
item field and must not silently discard the modifier.

An unsupported source occurrence for which C09C3 emitted no `ValueBinding`
does not become a public input. If it affects visible or required output,
automatic approval is blocked unless an explicit reviewed waiver or redesign
makes the component semantically complete. A waiver is recorded in provenance
and diagnostics, not hidden.

## 10. Image accessibility

An asset binding does not prove image accessibility. Any contract that renders
an image must define one of these explicit policies:

```text
informative image -> a required semantic alt-text input
decorative image  -> an explicit decorative decision and empty alt output
```

The contract may represent a media value as `:string` when it is a URL-like
source, or `:map` when the approved component owns a structured media shape.
The contract must also define the companion alt/decorative field and its
validation. `nil` cannot silently mean decorative. If the IR does not prove a
trustworthy accessibility policy, approval is `NEEDS_REVIEW` or the contract
requires consumer-provided accessibility data.

The accepted Hero's explicit `image_alt` decision is evidence for this rule.
Hero's names and field set are not a generic generated template.

## 11. Public naming and value_key boundary

Public names are semantic, short, Phoenix-idiomatic, stable under source
adapter replacement, and selected as part of the approved classification.

These names are prohibited in attrs, slots, item fields, module intent, and
function intent:

```text
post_title
featured_image
query_results
bricks_*
wp_*
element_<id>
source field paths
DesignNode IDs
ValueBinding IDs
CollectionBinding IDs
```

`source_collection_binding_id` is compiler/provenance metadata. It is not a
consumer-facing collection identifier or a public Phoenix name. The contract
does not require a separate `collection_input_name`. `value_key` remains
internal componentization and provenance input. It is never a public API
default. A human-selected semantic name may be recorded in the approved
contract, but it must remain independent of source vocabulary.

## 12. BindingProjection model

`BindingProjection` is compiler/provenance metadata. Consumers do not receive
it and generated components do not expose it.

Every projection records:

```text
source binding ID
public attr or slot name
projection kind
public_attr_name, when the projection targets a top-level attr
source_collection_binding_id, when a collection input is involved
owning parent CollectionInput, for a nested collection projection
parent_item_field_name, for a nested collection or nested count projection
item field name, when applicable
target DesignNode ID
status
```

A root `CollectionBinding` uses `projection_kind = collection_attr` and
references its source binding ID, its existing public `:list` attr, and its
`CollectionInput` metadata. A nested `CollectionBinding` uses
`projection_kind = collection_item_field`; it references the owning parent
`CollectionInput`, the parent item field, the child source binding ID, and the
child `CollectionInput` metadata. A nested collection never uses
`collection_attr`.

A top-level collection count uses `projection_kind = collection_count_attr`
and references its scalar public count attr and owning `CollectionInput`. A
nested collection count uses the existing `collection_item_field` projection
kind and references the scalar parent item field. Its source
`ValueBinding.value_kind = collection_count` preserves the count meaning.

The first-wave `projection_kind` set is closed:

```text
scalar_attr
collection_attr
collection_item_field
collection_count_attr
slot
```

`slot` is valid only when an IR/source semantic explicitly maps to
consumer-owned markup or behavior. Ordinary `ValueBinding` records never
become slots by default. No other projection kind may be invented during
generation.

## 13. Contract validation and diagnostics

Validation accumulates discoverable findings and never silently repairs a
contract. At minimum it checks:

- `contract_id` and `contract_format_version` are non-empty and valid;
- category is one of the four approved values;
- module and function intent are source-independent and non-empty;
- public attr names are unique;
- public slot names are unique;
- attr and slot names do not conflict;
- every attr and item field uses an allowed truthful type;
- required/default declarations are coherent;
- every `source_collection_binding_id` is non-empty and unique within the contract;
- each collection has unique item field names;
- every `CollectionInput` uses exactly one location mode: top-level fields
  (`public_attr_name` present and both parent fields nil) or nested fields
  (`public_attr_name` nil and both parent fields present);
- a top-level `CollectionInput` references exactly one existing `public_attrs`
  entry through `public_attr_name`, and that entry has type `:list`;
- a nested `CollectionInput` references an existing parent `CollectionInput`
  through `parent_collection_binding_id` and an existing parent item field
  through `parent_item_field_name`, and that field has type `:list`;
- `CollectionInput` records do not redefine referenced attr or item field
  type, required/default behavior, semantic purpose, validation, or
  accessibility;
- the child-to-parent collection graph is acyclic, has no self-parent, and
  every parent reference resolves;
- children are derived from the canonical `parent_collection_binding_id` edge;
- a root `collection_attr` projection references its existing public `:list`
  attr and `CollectionInput`; nested collections never use `collection_attr`;
- a nested `collection_item_field` projection references its owning parent
  `CollectionInput`, parent item field, child source binding ID, and child
  `CollectionInput`;
- a top-level count references an existing scalar public attr with type
  `:integer` and non-negative validation;
- a nested count references an existing scalar parent item field with type
  `:integer` and non-negative validation;
- top-level inputs use `count_attr_name` only, nested inputs use
  `count_item_field_name` only, and both may be nil when no count is visible;
- all count projections reference their intended collection and use the count
  location allowed by that collection;
- all `BindingProjection` source binding IDs exist in the input IR;
- every referenced public attr, parent input, and item field exists;
- collection-item projections reference their owning collection and item field;
- an evidence-insufficient binding is never marked approved without a recorded
  review decision;
- unsupported bindings are never silently promoted;
- no public name contains prohibited source vocabulary;
- image inputs have an explicit accessibility policy;
- slot cardinality and consumer responsibility are present;
- no public universal props/data/bindings map is required;
- approval is blocked by unresolved required diagnostics; and
- provenance identifies the IR binding and selected semantic classification.

Diagnostics use stable `component_contract.*` codes. The first-wave outcome
classes are `info`, `warning`, `error`, and `fatal`; a blocking error or fatal
diagnostic prevents approval. Suggested diagnostics include:

```text
component_contract.classification_ambiguous
component_contract.public_name_source_specific
component_contract.binding_missing
component_contract.binding_evidence_insufficient
component_contract.binding_unsupported
component_contract.collection_shape_invalid
component_contract.collection_field_missing
component_contract.count_semantics_unproven
component_contract.image_accessibility_unproven
component_contract.api_conflict
component_contract.approval_blocked
```

## 14. Determinism and provenance

Given the same Design IR, approved component classification, naming decisions,
and C09D authority version, the proposed contract is deterministic.

The componentizer must not derive names or structure from map iteration order,
clock values, randomness, database values, runtime query results, host records,
or provider responses. Human-reviewed semantic names are explicit inputs to
the approved classification. Once approved, serialization sorts object keys
and preserves declared list order.

Provenance records enough information to answer:

```text
which IR binding supplied this public attr or item field?
which CollectionBinding owns this collection input?
which DesignNode target is rendered from it?
which reviewer decision resolved an ambiguity or waiver?
```

Source element IDs, Bricks query settings, raw expressions, source classes,
and source adapter details may appear in provenance only. They cannot be used
as public names or executable instructions.

## 15. Styling, responsiveness, and behavior boundaries

Responsive behavior is internal component behavior. Public contracts do not
expose source breakpoint names, pixel thresholds, ACSS variables, source
classes, raw declarations, or layout implementation details.

Componentization records semantic styling responsibility where needed, but it
does not turn styling details into attrs. `class` is additive and `rest` is a
normal Phoenix global-attribute capture. Responsive implementation remains in
the later generated component and its approved styling contract.

Navigation, events, business logic, and interactive roots are consumer-owned.
An action surface with consumer-owned markup uses a semantic slot. The
componentizer does not generate event names, server calls, JavaScript commands,
or Ash behavior.

## 16. Catalogue and generator boundaries

Catalogue metadata is not the component API authority. The production
component contract owns attrs, slots, item fields, projections, and rendering
meaning. A future Catalogue manifest records identity, taxonomy, lifecycle,
release metadata, and a contract fingerprint under its own authority.

C09D1 does not create or modify a CatalogueItem, manifest, Catalogue state,
Hero admission, or release metadata.

Only an approved `ComponentContract` may enter a later generator. C09D1
authorizes no HEEx templates, Phoenix modules, CSS, JavaScript, LiveView events,
file writing, ejection, or generator inference. A generator must reject a
contract that leaves public API semantics undecided.

## 17. Performance and security

Componentization is compile/build-time work over cold, ephemeral compiler
data. It uses no runtime service or fetched data:

```text
RUNTIME_DB_CALLS = 0
RUNTIME_REDIS_CALLS = 0
RUNTIME_NETWORK_CALLS = 0
ETS = NO
Cachex = NO
Postgres = NO
GenServer = NO
Oban = NO
```

The future implementation should build indexes for deterministic validation:

```text
CollectionBinding ID -> CollectionInput
public attr name -> Attr
parent CollectionBinding ID -> parent CollectionInput
(parent CollectionInput, item field name) -> ItemField
```

Children are derived from the child `parent_collection_binding_id` references.
With these indexes, validation targets `O(contract records + binding
references)` and does not rescan the complete contract for every field.
Imported JSON, CSS, JavaScript, PHP, source paths, and expressions are inert
untrusted data. Componentization performs no evaluation, dynamic module
loading, query execution, URL fetch, raw HTML injection, or event execution.
Public names are reviewer/compiler-selected identifiers. Later generated HEEx
remains responsible for escaping caller values.

## 18. Frontend semantics decision matrix

| IR input kind | Scope | Componentization meaning | Default public projection | Attr/slot/item-field decision | Approval blockers | Example |
| --- | --- | --- | --- | --- | --- | --- |
| Singular text field | `site` or component root | A scalar semantic role rendered by the component | Named scalar attr chosen by role | Attr when LiveFrames owns plain-text rendering; slot only when consumer markup/behavior is required | Ambiguous role, required accessibility text unresolved, or unsupported evidence | `heading` or `label` |
| Singular asset field | `site` or component root | A media role rendered by the component | Semantic media attr, usually `:string` for a URL or `:map` for an approved structured media value | Attr plus explicit informative-alt or decorative policy; never a slot by dynamic origin alone | No trustworthy accessibility policy, unsupported asset meaning, or required companion field missing | `image` with `image_alt` |
| Singular `link_url` field | `site` or component root | A destination consumed by a rendered link/action | Named URL attr when LiveFrames owns the link shell | Attr for a LiveFrames-owned link; slot when consumer owns link/button markup or events | Link role or safe destination semantics unproven | `destination` |
| Root collection | `collection` | Caller-supplied repeated data with LiveFrames-owned item rendering | Top-level semantic `:list` public attr | Attr with `CollectionInput`; not a repeatable arbitrary-markup slot | Boundary/category/name unresolved or no stable item shape | `plans` |
| Collection-item text field | `collection_item` | A field on each item in the enclosing collection | Semantic item field | Item field inside the owning `CollectionInput`, never a top-level attr | Field role, requiredness, or safe item shape unresolved | `plan.name` |
| Collection-item asset field | `collection_item` | Media rendered for each item | Semantic item media field plus alt/decorative companion | Item field inside the owning collection; no asset slot by default | Accessibility policy, media shape, or required companion unresolved | `member.image` plus `member.image_alt` |
| Top-level collection count | `collection` | Host-supplied displayed count associated with one root collection | Explicit non-negative `:integer` public attr tied to that collection | Scalar public attr; never inferred from list length by default | Display meaning or owning collection unresolved | `plan_count` |
| Nested collection | nested collection scope | A repeated child list belonging to a parent item | Nested `:list` item field with child `CollectionInput` metadata | Remains nested under parent item; never flattened and never converted to a slot | Parent containment, child role, or nested item shape unresolved | `plan.features` |
| Nested collection count | `collection` | Host-supplied displayed count associated with a child list on each parent item | Scalar non-negative `:integer` parent item field | Item field on the parent `CollectionInput`; never a top-level attr | Display meaning, parent field, or owning collection unresolved | `plan.feature_count` |
| Evidence-insufficient value binding | any proven scope | Unresolved semantic declaration requiring review | No approved public projection | Keep diagnostic/provenance; proposal remains `NEEDS_REVIEW` unless reviewed resolution, exclusion, or rejection is recorded | Always blocks automatic approval when visible, required, or accessibility-relevant | Opaque modifier on a visible text field |
| Unsupported diagnosed source target | any | Source occurrence has no authorized IR target | No public input | Preserve diagnostic/provenance; exclude or redesign only by explicit review | Blocks approval when output would be incomplete; no silent static fallback | Unsupported dynamic accessibility target |

## 19. Explicit decision register

The following values are final for C09D1. None is delegated to a generator.

```text
COMPONENT_CONTRACT_ARTIFACT_DECISION = explicit versioned serializable
  ComponentContract artifact with contract_format_version 1.0.0. The field
  describes only serialized format/schema compatibility and is separate from
  Design IR, CatalogueItem release, public API, and package versions.

COMPONENT_CATEGORY_MODEL = primitive | component | pattern | section only.

PAGE_TARGET_DECISION = page is a separate generation target and is not a
  ComponentContract category.

COMPONENTIZATION_APPROVAL_GATE = valid Design IR plus selected semantic
  boundary/category plus representable binding semantics plus validated
  contract plus reviewed approval_status=approved.

NEEDS_REVIEW_RULE = use NEEDS_REVIEW when boundary, public naming, binding
  projection, image accessibility, count meaning, nested ownership, or
  unsupported/evidence-insufficient semantics cannot be safely inferred.

FUNCTION_COMPONENT_DEFAULT = stateless Phoenix.Component function component
  with declarative attr/3 and slot/3 inputs.

LIVECOMPONENT_ESCALATION_RULE = require independent evidence of component-owned
  state/events, local ownership, worse parent coupling, and stable identity.

ATTR_RULE = use attrs for scalar content, typed configuration, URLs, media,
  counts, and structured caller data rendered by LiveFrames; use narrow,
  truthful Phoenix types and no universal props/data map.

SLOT_RULE = use slots for consumer-owned Phoenix markup, navigation/action
  behavior, events, interactive roots, or application composition; default
  singular cardinality is 0..1.

COLLECTION_PUBLIC_INPUT_RULE = only a root CollectionBinding with
  parent_collection_binding_id = nil becomes one public_attrs entry with a
  semantic name and type :list plus one CollectionInput. The CollectionInput
  stores public_attr_name for that root attr. Nested CollectionBindings do not
  create top-level attrs. Never use a backend query or mandate the literal name
  items.

COLLECTION_ITEM_SHAPE_RULE = caller-provided semantic maps or struct-like
  values with contract-defined public item fields; value_key strings remain
  internal. ItemField required/default/type/validation metadata controls item
  access, while CollectionInput stores only repeated-data metadata.

COLLECTION_ITEM_ACCESS_RULE = one explicit safe accessor uses exact string-key
  lookup, then existing atom-key lookup by Atom.to_string comparison. Missing
  required fields fail, optional fields use an explicit default or nil, and
  present invalid values fail validation. No dynamic atom or module creation
  is allowed.

NESTED_COLLECTION_RULE = a nested CollectionBinding remains a :list item
  field on its parent collection item. Its child CollectionInput references
  the actual parent through parent_collection_binding_id and the parent list
  ItemField through parent_item_field_name. It does not create a top-level
  public attr, redefine the parent field contract, flatten data, or become a
  slot. The canonical child-to-parent edge is indexed when children are needed.

SINGULAR_FIELD_PROJECTION_RULE = a proven site/root ValueBinding becomes a
  semantic scalar attr only when LiveFrames owns rendering and the role is
  proven.

COLLECTION_ITEM_FIELD_PROJECTION_RULE = a collection-item ValueBinding becomes
  a semantic field inside its owning collection item, never a top-level attr.

COLLECTION_COUNT_PROJECTION_RULE = a visible count for a top-level
  collection becomes an ordinary non-negative integer public_attrs entry
  associated through count_attr_name and projected as collection_count_attr.
  The attr owns its type, required/default behavior, validation, and semantic
  purpose. List length is not inferred without reviewed evidence.

NESTED_COLLECTION_COUNT_RULE = a visible count for a nested collection becomes
  a non-negative integer ItemField on the parent CollectionInput and is
  associated through count_item_field_name. It uses the existing
  collection_item_field projection kind and is never flattened to a top-level
  attr. Its ValueBinding keeps value_kind = collection_count.

EVIDENCE_INSUFFICIENT_RULE = no automatic approval for an unresolved binding
  affecting visible, required, or accessibility semantics; reviewer may
  resolve, exclude, or reject it with provenance.

UNSUPPORTED_TARGET_RULE = unsupported targets never become public inputs or
  static fallback values; visible/required impact blocks approval unless a
  reviewed waiver or redesign makes output complete.

PUBLIC_NAMING_RULE = names are semantic, short, Phoenix-idiomatic,
  source-independent, and stable under adapter replacement; source IDs,
  paths, classes, query fields, and binding IDs are prohibited.

VALUE_KEY_PUBLIC_API_RULE = value_key is internal componentization/provenance
  input and never the public API name by default.

IMAGE_ACCESSIBILITY_RULE = every rendered image has a proven informative alt
  input or an explicit decorative decision; nil never implies decorative.

ACTION_BEHAVIOR_RULE = consumer owns navigation, events, business behavior,
  and interactive roots; LiveFrames supplies presentation only.

ID_CLASS_GLOBAL_ATTR_RULE = expose additive class and Phoenix :global rest on
  meaningful DOM roots; expose id only when semantic identity or integration
  needs it; never expose source classes or raw style as the primary API.

RESPONSIVE_PUBLIC_API_RULE = responsive behavior is internal; source
  breakpoints, pixel thresholds, and style-source details are not public
  inputs.

BINDING_PROJECTION_MODEL = closed projection kinds are scalar_attr,
  collection_attr, collection_item_field, collection_count_attr, and slot.
  Root CollectionBindings use collection_attr and reference their public :list
  attr plus CollectionInput. Nested CollectionBindings use
  collection_item_field and reference the parent ItemField plus child
  CollectionInput. Top-level counts use collection_count_attr; nested counts
  use collection_item_field. No new projection kind is introduced.

CONTRACT_VALIDATION_RULE = accumulate diagnostics for identity, category,
  names, types, requiredness, location XOR, parent/item relationships,
  one-authority attr and ItemField references, projections, count placement,
  evidence, source leakage, accessibility, and approval. Require unique
  source_collection_binding_id values, an acyclic canonical child-to-parent
  graph, root public :list attrs, nested parent list ItemFields, and count
  locations that match collection location. Reject conflicting CollectionInput
  metadata and do not silently repair contracts.

CONTRACT_DETERMINISM_RULE = same IR, approved classification, naming input,
  and authority version produce the same contract and deterministic
  serialization, independent of runtime data or map order.

CONTRACT_VERSIONING_RULE = contract_format_version has its own format-only
  SemVer rules: representation-preserving corrections are PATCH,
  backwards-compatible optional serialized fields/capabilities are MINOR,
  and incompatible serialized shape/meaning or required migration is MAJOR.
  Consumer-facing public API SemVer belongs to docs/24 CatalogueItem release
  versioning, not this field.

PUBLIC_ATTR_AUTHORITY = public_attrs is the sole authority for Phoenix attr
  name, type, required/default behavior, semantic purpose, validation, and
  accessibility consequence.

COLLECTION_INPUT_IDENTITY_RULE = source_collection_binding_id is the
  non-empty, unique compiler identity/reference key for each CollectionInput.
  It is not a public Phoenix identifier, and no separate
  collection_input_name is required.

COLLECTION_LOCATION_EXCLUSIVITY_RULE = a top-level CollectionInput has
  public_attr_name present with parent_collection_binding_id and
  parent_item_field_name nil. A nested CollectionInput has public_attr_name
  nil with both parent fields present. No other combination is valid.

NESTED_PARENT_REFERENCE_RULE = parent_collection_binding_id is the only
  authoritative child-to-parent edge. It must resolve to an existing parent
  CollectionInput, cannot self-reference, and must form an acyclic graph.

NESTED_ITEM_FIELD_RULE = parent_item_field_name must resolve to an existing
  parent ItemField with type :list. The parent ItemField owns the nested
  field public contract; the child CollectionInput adds child shape and
  provenance only.

NESTED_CHILD_DERIVATION_RULE = derive child collections by indexing
  parent_collection_binding_id when needed. Do not store a second authoritative
  child relationship list.

COLLECTION_INPUT_AUTHORITY = CollectionInput owns only repeated-data metadata:
  source_collection_binding_id, top-level public_attr_name or nested parent
  references, item fields, count relation, binding metadata, and provenance.
  It never redefines the referenced Attr or ItemField contract.

COLLECTION_ATTR_RELATIONSHIP = only a root collection has one
  public_attrs entry with type :list plus at most one CollectionInput reference.
  A nested collection has no top-level public_attrs entry; its parent ItemField
  with type :list is the public field authority.

COUNT_ATTR_RELATIONSHIP = count_attr_name is top-level only and references an
  existing scalar public_attrs entry with type :integer and non-negative
  validation. Its attr owns required/default behavior, semantic purpose, and
  validation.

COUNT_ITEM_FIELD_RELATIONSHIP = count_item_field_name is nested only and
  references an existing scalar parent ItemField with type :integer and
  non-negative validation. That ItemField owns its public contract.

COUNT_LOCATION_EXCLUSIVITY_RULE = a top-level CollectionInput may store only
  count_attr_name; a nested CollectionInput may store only
  count_item_field_name. Both may be nil when no visible count exists.

ITEM_REQUIRED_MISSING_POLICY = missing required item field raises a clear
  contract validation/access error.

ITEM_OPTIONAL_DEFAULT_POLICY = missing optional item field with an explicit
  default resolves to that contract-defined default.

ITEM_OPTIONAL_NO_DEFAULT_POLICY = missing optional item field without an
  explicit default resolves to nil / absent optional value.

ITEM_LOOKUP_ORDER = exact string key first, then an existing atom key matched
  by Atom.to_string comparison; an exact string key wins when both exist.

DYNAMIC_ATOM_POLICY = never create atoms or resolve modules/functions from
  public item field names.

CATALOGUE_BOUNDARY = Catalogue metadata records identity, taxonomy,
  lifecycle, release information, and a contract fingerprint; production
  component contracts remain API authority and C09D1 changes no Catalogue.

GENERATOR_BOUNDARY = only an approved, validated ComponentContract may feed a
  later generator; C09D1 authorizes no HEEx, Phoenix module, CSS, JS, event,
  file-writing, or ejection work.
```

## 20. Hero reconciliation

`LiveFrames.Components.Sections.Hero.hero/1` is reference evidence for
Phoenix API quality. It demonstrates semantic attrs, named action slots,
plain-text content, image accessibility guards, additive classes, global attrs,
and consumer-owned action behavior.

The Hero API is not a generic generated API template. `heading_level`,
`primary_action`, `secondary_action`, and its image fields exist because Hero
evidence proves those roles. Componentization must not inject those names into
an unrelated contract. A future generated contract selects its own semantic
roles under the rules above.

## 21. C09D2 implementation envelope

The next slice is:

```text
C09D2: ComponentContract core model and validation
```

C09D2 may implement the conceptual `ComponentContract`, `CollectionInput`,
item-field definitions, `BindingProjection`, diagnostics, validation,
deterministic serialization, and the approval gate defined here. It must not
generate HEEx, create Phoenix modules, modify the accepted Hero component,
change Design IR 2.0.0, add Bricks vocabulary to the public model, add a
universal props/data map, fetch host data, add Ash/backend/provider behavior,
change Catalogue state, or start generation.

A later, separately reviewed slice may project Design IR into approved
contracts once classification and semantic naming inputs are available.

## 22. Scope confirmation and stop conditions

This C09D1 change defines componentization semantics only.

```text
production code changed = 0
Design IR schema changed = 0
Bricks vocabulary in public Phoenix API model = 0
universal props/data map introduced = 0
backend queries or host data fetching = 0
HEEx generator implemented = 0
Catalogue lifecycle state changed = 0
C09D2 started = 0
merge performed = 0
```

Stop if the work requires a Design IR schema change, source-specific public
names, invented semantic attrs, normalizing evidence-insufficient values,
component classification coupled to generation, a universal map API, Ash or
provider architecture, HEEx generation, Catalogue admission, production code,
or another changed file. Those decisions require a later authority or an
explicitly authorized implementation slice.
