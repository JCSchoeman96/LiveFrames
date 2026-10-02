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
| `collection_inputs` | Ordered `CollectionInput` metadata records for admitted repeated data. Each record references one `public_attrs` list entry. |
| `binding_projections` | Compiler metadata connecting IR bindings and targets to public inputs. |
| `diagnostics` | Accumulated contract findings. Validation does not hide them. |
| `provenance` | Source traces, IR binding IDs, selected classification evidence, and reviewer decisions. |
| `approval_status` | `proposed`, `approved`, `needs_review`, or `rejected`. This is an approval result, not a second lifecycle. |

Each attr definition records `name`, Phoenix type, required/default behavior,
semantic purpose, binding provenance, validation requirements, and any
accessibility consequence. `public_attrs` is the sole authority for those
Phoenix attr properties. Each slot definition records its semantic purpose,
validation information, cardinality, and consumer responsibility. Each
collection input records the referenced public attr name, owning
`CollectionBinding`, item fields, count relationship, nested collection
relationships, and provenance. It does not redefine the referenced attr's
type, requiredness, or default.

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

An admitted `CollectionBinding` projects by default to a semantic list attr,
not to a repeatable arbitrary-markup slot and not to a backend query. The
componentizer chooses the public name from the component's role:

```text
pricing section -> plans
team grid       -> members
feature grid    -> features
```

An unresolved semantic role produces `NEEDS_REVIEW`; it does not fall back to
the literal name `items`. Query names, source element IDs, and source field
paths never choose the public name.

The public collection attr has Phoenix type `:list`. Requiredness depends on
the approved component semantics. An optional collection may default to `[]`
only when the component has a valid empty state. A required collection has no
invented default. The contract records whether an empty list omits, empties, or
renders a deliberate empty state.

### 7.2 CollectionInput and item shape

Each collection attr has one conceptual `CollectionInput` metadata definition.
The corresponding `public_attrs` entry remains the sole authority for the
Phoenix attr contract:

```text
public_attr_name
source CollectionBinding ID
item field definitions
count_attr_name, when applicable
parent_collection_input_name, when nested
nested collection relationships
binding/provenance metadata
```

The referenced public attr must have type `:list`. `CollectionInput` cannot
redefine its Phoenix type, requiredness, default, semantic purpose, or
validation. A collection attr has at most one `CollectionInput` record.

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

A nested `CollectionBinding` remains nested in its enclosing item model. Its
public list field belongs to the parent item and has its own `CollectionInput`
definition. The contract records the parent collection input and child item
fields. It does not flatten nested data into unrelated top-level attrs, merge
nested lists, or turn an inner collection into a slot. A nested collection
must have a proven parent relationship in IR and a selected semantic child
role; otherwise approval is blocked.

### 7.5 Collection count

When the design visibly renders a collection count, componentization projects
the `ValueBinding` as an ordinary scalar entry in `public_attrs` and associates
that attr with its collection metadata. The attr uses `:integer`, requires a
non-negative value, and receives a semantic name such as `plan_count` selected
by the component role. It is not automatically called `count` or `length`.

The `CollectionInput` stores only the related `count_attr_name`. The count
attr's type, requiredness, default, semantic purpose, and validation live in
`public_attrs`.

The host may supply a total count that differs from the rendered list length.
The contract must not generate `length(@items)` unless reviewed semantics prove
that the displayed number means rendered items. If no count is supplied, the
contract either omits the count display or remains `NEEDS_REVIEW`; it does not
silently derive one.

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
`CollectionInput`, never an unrelated top-level attr. Nested collection fields
remain in the nested input.

For `value_kind = collection_count`, the binding becomes the explicit count
attr associated with its owning collection as described above.

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

These names are prohibited in attrs, slots, item fields, module intent,
function intent, and collection input names:

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

`value_key` remains internal componentization and provenance input. It is
never a public API default. A human-selected semantic name may be recorded in
the approved contract, but it must remain independent of source vocabulary.

## 12. BindingProjection model

`BindingProjection` is compiler/provenance metadata. Consumers do not receive
it and generated components do not expose it.

Every projection records:

```text
source binding ID
public attr or slot name
projection kind
public_attr_name, when the projection targets an attr
collection input name, when applicable
item field name, when applicable
target DesignNode ID
status
```

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
- collection input names are unique;
- each collection has unique item field names;
- each `CollectionInput` references exactly one existing `public_attrs` entry
  through `public_attr_name`;
- every referenced collection attr has type `:list`;
- each collection attr has at most one `CollectionInput`;
- `CollectionInput` cannot redefine a public attr's type, requiredness, or
  default;
- every `collection_attr` projection references both its existing public attr
  and its `CollectionInput` metadata;
- nested collection relationships are acyclic and reference existing inputs;
- nested `CollectionInput` records reference their actual parent metadata;
- every collection count relationship references an existing scalar public
  attr, whose type, requiredness, and default remain in `public_attrs`;
- all `BindingProjection` source binding IDs exist in the input IR;
- every referenced public input exists;
- collection-item projections reference their owning collection and item field;
- count projections reference their intended collection;
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

The future implementation should build binding and node indexes and target
`O(nodes + bindings + contract inputs)`. It must not rescan the complete node
tree for every binding.

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
| Collection | collection scope | Caller-supplied repeated data with LiveFrames-owned item rendering | Semantic `:list` collection attr | Attr with `CollectionInput`; not a repeatable arbitrary-markup slot | Boundary/category/name unresolved or no stable item shape | `plans` |
| Collection-item text field | `collection_item` | A field on each item in the enclosing collection | Semantic item field | Item field inside the owning `CollectionInput`, never a top-level attr | Field role, requiredness, or safe item shape unresolved | `plan.name` |
| Collection-item asset field | `collection_item` | Media rendered for each item | Semantic item media field plus alt/decorative companion | Item field inside the owning collection; no asset slot by default | Accessibility policy, media shape, or required companion unresolved | `member.image` plus `member.image_alt` |
| Collection count | `collection` | Host-supplied displayed count associated with one collection | Explicit non-negative `:integer` attr tied to that collection | Scalar count attr; never inferred from list length by default | Display meaning or owning collection unresolved | `plan_count` |
| Nested collection | nested collection scope | A repeated child list belonging to a parent item | Nested `:list` item field with child `CollectionInput` metadata | Remains nested under parent item; never flattened and never converted to a slot | Parent containment, child role, or nested item shape unresolved | `plan.features` |
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

COLLECTION_PUBLIC_INPUT_RULE = an admitted CollectionBinding becomes one
  public_attrs entry with a semantic name and type :list, plus one
  CollectionInput that references that attr; never use a backend query or
  mandate the literal name items.

COLLECTION_ITEM_SHAPE_RULE = caller-provided semantic maps or struct-like
  values with contract-defined public item fields; value_key strings remain
  internal. ItemField required/default/type/validation metadata controls item
  access, while CollectionInput stores only repeated-data metadata.

COLLECTION_ITEM_ACCESS_RULE = one explicit safe accessor uses exact string-key
  lookup, then existing atom-key lookup by Atom.to_string comparison. Missing
  required fields fail, optional fields use an explicit default or nil, and
  present invalid values fail validation. No dynamic atom or module creation
  is allowed.

NESTED_COLLECTION_RULE = keep nested collections as nested item list fields
  with parent CollectionInput metadata. The child references its actual parent
  metadata and does not redefine the parent attr contract; do not flatten or
  turn nested collections into slots.

SINGULAR_FIELD_PROJECTION_RULE = a proven site/root ValueBinding becomes a
  semantic scalar attr only when LiveFrames owns rendering and the role is
  proven.

COLLECTION_ITEM_FIELD_PROJECTION_RULE = a collection-item ValueBinding becomes
  a semantic field inside its owning collection item, never a top-level attr.

COLLECTION_COUNT_PROJECTION_RULE = a visible collection count becomes an
  ordinary non-negative integer public_attrs entry associated with its
  collection through count_attr_name; CollectionInput does not redefine its
  type, requiredness, or default, and list length is not inferred without
  reviewed evidence.

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
  collection_attr, collection_item_field, collection_count_attr, and slot;
  each records source binding, public attr or slot name, collection/item
  context, target node, and status. A collection_attr projection references
  both its public :list attr and CollectionInput metadata.

CONTRACT_VALIDATION_RULE = accumulate diagnostics for identity, category,
  names, types, requiredness, collection/item relationships, one-authority
  public attr references, projections, evidence, source leakage,
  accessibility, and approval; reject conflicting CollectionInput attr
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

COLLECTION_INPUT_AUTHORITY = CollectionInput owns only repeated-data metadata:
  public_attr_name, source CollectionBinding ID, item fields, count relation,
  parent/nested relationships, binding metadata, and provenance.

COLLECTION_ATTR_RELATIONSHIP = one collection attr is one public_attrs entry
  with type :list plus at most one CollectionInput reference; CollectionInput
  cannot redefine type, requiredness, or default.

COUNT_ATTR_RELATIONSHIP = count_attr_name references an existing scalar
  public_attrs entry; its type, required/default behavior, validation, and
  semantic purpose are defined only by public_attrs.

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
