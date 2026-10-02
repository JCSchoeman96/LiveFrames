# C09D3 Componentization plan and render projection authority

**Status:** authority/documentation only

**Accepted base:** `0522a7240b1edbe955ef70de302a61f50495548c`

**Accepted tree:** `112e3521fa3ff643ced9412fd0ed8186952287fe`

**Approved C09D2 head:** `f39d7105ca3ba57a28927a118bb0df5402ba92c7`

**Post-merge CI:** run `36984795342`, completed with conclusion `success`, `headSha =
0522a7240b1edbe955ef70de302a61f50495548c`

This authority freezes the compile-time placement boundary between an approved
`ComponentContract` and a later HEEx generator. C09D2 provides a validated
`ComponentContract` model and `BindingProjection` linkage from Design IR
bindings to public contract inputs. C09D3 defines a separate
`ComponentizationPlan` artifact for render placement of public inputs that are
not already represented by `BindingProjection`.

This slice does not implement plan structs, a proposer, HEEx generation, or
changes to Design IR 2.0.0 or `ComponentContract` format `1.0.0`.

**Supersedes nothing.** `docs/development/c09d1_component_contract_authority.md`
remains the public API authority. C09D3 adds placement authority only.

## 1. Scope and compiler boundary

The pipeline after normalization is:

```text
DesignDocument
    + semantic componentization decisions
    -> ComponentContract (public API)
    + ComponentizationPlan (render placement)
    -> validated proposal pair
    -> later generation
```

Three questions must stay separate:

| Artifact | Question |
| --- | --- |
| Design IR 2.0.0 | What does the normalized design mean? |
| ComponentContract 1.0.0 | What may consumers supply? |
| ComponentizationPlan 1.0.0 | Where do approved public inputs render in the boundary subtree? |

`BindingProjection` maps Design IR `CollectionBinding` / `ValueBinding` records
to public contract targets. It does not define how an unbound, static, or
consumer-only public attr or slot is placed into the `DesignNode` tree when no
Design IR binding exists. A generator must not infer that placement from public
name, `semantic_type`, `value_key`, node label, source class, source ID, DOM
order, or source-editor terminology.

## 2. ComponentizationPlan artifact

`ComponentizationPlan` is an explicit, versioned, serializable compiler
artifact. Its sole responsibility is to map an approved `ComponentContract`'s
public rendering inputs onto exact locations and roles in one
`DesignDocument` component boundary.

The plan is not:

```text
a public component API
a Catalogue record
a Design IR replacement
a runtime object
a provider or data-source definition
a component lifecycle
```

Recommended first-wave format identity:

```text
COMPONENTIZATION_PLAN_ARTIFACT =
  explicit versioned serializable compiler artifact

PLAN_FORMAT_VERSION = 1.0.0
```

`PLAN_PUBLIC_API_AUTHORITY_RULE`: `ComponentContract` remains the sole public
API authority. The plan may control render placement only. It must not define
new attrs, slots, item fields, collection inputs, types, required/default
values, slot cardinality, category, or module/function intent. If the plan
references a public member not already present in the contract, the plan is
**invalid**. No silent creation.

## 3. Authority split

### 3.1 ComponentContract owns

```text
contract identity
component category
module/function public intent

public attrs
public slots
CollectionInputs
ItemFields

BindingProjections

public types
required/default rules
accessibility policy
consumer responsibility

approval_status

public API diagnostics/provenance
```

### 3.2 ComponentizationPlan owns

```text
component boundary in Design IR

render placement of public inputs not already represented by BindingProjection

target DesignNode IDs (for RenderProjection)
render roles

relationship to exact ComponentContract (contract_id)

plan diagnostics/provenance
```

### 3.3 Binding link authority

`BindingProjection` remains authoritative for Design IR binding → public
contract target relationships. Do not copy those relationships into the plan.
A binding-backed public target does not need a second render projection merely
to repeat source binding ID, target node ID, or public attr/item field/slot.

```text
BINDING_LINK_AUTHORITY = ComponentContract.BindingProjection
BINDING_RENDER_DUPLICATION_RULE =
  RenderProjection must not duplicate a public target already linked by
  BindingProjection
```

The plan may validate that each `BindingProjection.target_node_id` lies within
the selected component boundary. It does not redefine binding semantics.

## 4. RenderProjection model

`RenderProjection` is conceptual metadata owned by `ComponentizationPlan`. It
is not another `BindingProjection` and has no source binding ID.

```text
RENDER_PROJECTION_MODEL =
  ComponentContract public attr or public slot
  -> exact DesignNode rendering locus + closed render_role
  for public inputs with no BindingProjection
```

Each projection references exactly one existing public target:

```text
public_attr_name
```

or:

```text
public_slot_name
```

Never both. Format `1.0.0` must not reference `item_field_name`,
`CollectionInput`, `source_collection_binding_id`, or
`parent_collection_binding_id`.

Every `RenderProjection` requires:

```text
target_node_id   non-empty; exists in the exact DesignDocument;
                 lies inside the selected component boundary subtree
render_role      closed first-wave enum (section 6)
```

Do not derive `target_node_id` from node label, `source_trace.source_id`,
source path, CSS class, or DOM selector. No source-system ID may substitute
for a Design IR node ID.

### 4.1 First-wave scope

```text
RENDER_PROJECTION_SCOPE =
  top-level/public scalar attr
  top-level/public slot
  root/component extension attrs on the boundary node
```

Format `1.0.0` must not yet represent:

```text
static collection-item fields
static nested collection fields
static collection counts
repeatable slot DSLs
slot :let contracts
collection-backed slots
arbitrary node-template expressions
```

Requirements in those categories produce `NEEDS_REVIEW` until a later authority
extends the plan.

## 5. Component boundary

First-wave componentization uses exactly one explicit:

```text
boundary_node_id
```

in the plan.

```text
COMPONENT_BOUNDARY_RULE =
  boundary_node_id resolves to one DesignNode;
  every RenderProjection.target_node_id is that node or a descendant;
  every ComponentContract BindingProjection.target_node_id lies within the
  same boundary subtree;
  every root CollectionBinding repeat root owned by this component lies within
  the boundary
```

The boundary is an explicit semantic decision. Do not infer it from first root,
largest subtree, `semantic_type` alone, or source editor component name.

```text
MULTI_ROOT_BOUNDARY_RULE =
  multiple disjoint boundary roots -> NEEDS_REVIEW / unsupported in plan 1.0.0
```

`page` remains a separate generation target, not a `ComponentContract` category
(C09D1).

## 6. Render role vocabulary

C09D3 freezes a closed first-wave render-role enum proven by current master,
component, and Hero reference evidence:

```text
RENDER_ROLE_ENUM =
  text_content
  asset_src
  asset_alt
  link_url
  heading_level
  root_id
  root_class
  root_global_attrs
  subtree_slot
```

Role meaning:

| Role | Meaning |
| --- | --- |
| `text_content` | Scalar public attr rendered as node text content |
| `asset_src` | Scalar media/source attr consumed by an image/media node |
| `asset_alt` | Scalar accessibility attr for an image/media node |
| `link_url` | Scalar URL attr used by a LiveFrames-owned link shell |
| `heading_level` | Constrained heading-level attr on a heading node |
| `root_id` | Consumer `id` applied to component boundary root |
| `root_class` | Additive class applied to component boundary root |
| `root_global_attrs` | Phoenix global attr capture on component boundary root |
| `subtree_slot` | Consumer-owned markup filling an approved semantic subtree role |

Do not add generic roles such as `property`, `expression`, `callback`,
`renderer`, or `template`.

### 6.1 Role and public-type compatibility

```text
RENDER_ROLE_TYPE_COMPATIBILITY =
  text_content        -> Attr, truthful scalar text-compatible type
  asset_src           -> Attr, approved media representation
  asset_alt           -> Attr, explicit accessibility semantics
  link_url            -> Attr
  heading_level       -> Attr type :integer with approved heading-level validation
  root_id             -> Attr
  root_class          -> Attr
  root_global_attrs   -> Attr type :global
  subtree_slot        -> Slot
```

A render role must never silently reinterpret an incompatible public type.

### 6.2 Role and node semantic compatibility

```text
RENDER_ROLE_NODE_COMPATIBILITY =
  text_content     -> heading | paragraph | rich_text or independently justified content node
  asset_src        -> image (asset_alt pairs with same image node)
  asset_alt        -> image
  link_url         -> link or independently proven LiveFrames-owned navigation shell
  heading_level    -> heading
  subtree_slot     -> exact reviewed node/subtree root
  root_id          -> boundary node only
  root_class       -> boundary node only
  root_global_attrs-> boundary node only
```

Wrong node semantic type: validation error / `NEEDS_REVIEW`. Do not coerce.

## 7. Public render link coverage

For generation eligibility, every public input that affects rendered output must
have exactly one structured placement source:

```text
BindingProjection
OR
RenderProjection
```

unless proven non-rendering metadata.

```text
PUBLIC_RENDER_LINK_XOR_RULE =
  the same public attr or slot must not be simultaneously driven by
  BindingProjection and RenderProjection in first-wave authority
```

Binding-backed members obtain target node, binding scope, target kind, and
collection ownership from `BindingProjection` plus the referenced Design IR
binding. `ValueBinding.target_kind` remains normalized frontend destination
evidence; no public name is inferred from it.

```text
UNBOUND_PUBLIC_INPUT_RULE =
  a public attr or slot without a Design IR binding is permitted when semantic
  review proves the reusable API; when the generator must know where it
  renders, an explicit RenderProjection is required; absence of RenderProjection
  means the generator must not guess
```

Unused `RenderProjection` records (public target not in contract, or target
not used for generation) fail reference validation.

## 8. Static content, defaults, and internal constants

Master-spec rule (clarified):

```text
static source text becomes attrs/slots only when the component contract
requires customization
```

```text
STATIC_CONTENT_PROMOTION_RULE =
  fixture/source literal -> internal generated constant when not public;
  promotion to public API -> explicit Attr/Slot on ComponentContract +
  matching RenderProjection when placement is required

STATIC_DEFAULT_RULE =
  source literal does not automatically become the public default;
  defaults must satisfy D1 genuinely reusable rules

INTERNAL_CONSTANT_RULE =
  a node with no BindingProjection or RenderProjection may retain Design IR
  content as an internal generated value when content is supported, semantics
  are complete, the value is not consumer-owned, and behavior is not concealed;
  do not create a fake attr merely to preserve literal text
```

## 9. Root extension attrs

```text
ROOT_ID_RULE =
  root_id render role applies only to boundary_node_id; consumer id on the
  component root

ROOT_CLASS_RULE =
  root_class render role applies only to boundary_node_id; additive class only

ROOT_GLOBAL_ATTR_RULE =
  root_global_attrs render role applies only to boundary_node_id; Phoenix :global
  rest capture per C09D1 ID_CLASS_GLOBAL_ATTR_RULE
```

Root roles mapped to a non-boundary node: invalid.

## 10. Actions, accessibility, collections

```text
ACTION_SLOT_RULE =
  consumer-owned actions remain slots; subtree_slot may place a slot at a
  reviewed semantic action subtree; the plan must not invent navigate, patch,
  phx-click, event names, server handlers, JS commands, or Ash actions

IMAGE_ACCESSIBILITY_RULE =
  asset_src alone does not prove alt contract; generation eligibility requires
  truthful informative or decorative consumer policy on ComponentContract;
  do not infer decorative alt="" from RenderProjection
```

```text
COLLECTION_RENDER_PROJECTION_RULE =
  collection public attrs, item fields, nested collections, and counts remain
  driven by CollectionBinding, ValueBinding, CollectionInput, and
  BindingProjection only; RenderProjection is not a collection mapping mechanism

STATIC_COLLECTION_ITEM_RULE =
  static/unbound collection-item public field -> NEEDS_REVIEW; later authority required
```

Preserve C09D1/C09D2 collection rules without change.

## 11. Evidence-insufficient and unsupported nodes

```text
EVIDENCE_INSUFFICIENT_RULE =
  ValueBinding.normalization_status = evidence_insufficient does not become safe
  because a RenderProjection exists; RenderProjection must not shadow or bypass
  an unresolved binding on the same node/semantic role; preferred outcome ->
  NEEDS_REVIEW, no automatic approved proposal

UNSUPPORTED_NODE_RULE =
  raw | unsupported | unknown nodes inside the boundary that affect visible
  structure, interaction, accessibility, or public API prevent an automatically
  review-ready proposal; do not silently drop them; arbitrary provenance is not
  executable
```

## 12. Componentization proposal model

A componentization proposal is the validated pair:

```text
ComponentContract + ComponentizationPlan
```

against one exact `DesignDocument`.

```text
COMPONENTIZATION_PROPOSAL_MODEL =
  validated tuple of DesignDocument + ComponentContract + ComponentizationPlan;
  no third serialized ComponentizationProposal wrapper in first wave unless
  later evidence requires it
```

Only `ComponentContract` carries `approval_status`.

```text
PLAN_LIFECYCLE_RULE =
  ComponentizationPlan has no draft/proposed/approved/rejected lifecycle;
  for a given DesignDocument + ComponentContract it is structurally/reference
  valid or invalid
```

During `COMPONENTIZING`:

```text
valid DesignDocument
-> explicit boundary/classification/public API decisions
-> proposed ComponentContract
-> matching ComponentizationPlan
-> validate both against DesignDocument
-> reviewer approves contract or sends NEEDS_REVIEW
```

Transition to `GENERATING` requires:

```text
ComponentContract.approval_status = approved
AND ComponentContract generation validation passes
AND ComponentizationPlan reference validation passes
```

No plan status transition occurs.

```text
PROPOSER_APPROVAL_RULE =
  a future proposer may emit proposed or needs_review contract candidates;
  it never sets approval_status = approved automatically
```

Deterministic compiler output does not equal semantic approval.

## 13. Public naming and classification

These rules restate C09D1 boundaries in the plan/proposer context:

```text
PUBLIC_NAMING_RULE =
  do not derive public names mechanically from value_key, semantic_type,
  semantic_role, label, SourceTrace, source classes, or source IDs; ambiguous
  name -> NEEDS_REVIEW; no generic fallback

CLASSIFICATION_RULE =
  category primitive | component | pattern | section is an explicit semantic
  decision; do not classify solely from semantic_type, tree depth, descendant
  count, or source editor names; ambiguous -> NEEDS_REVIEW
```

## 14. Plan conceptual shape

Minimal conceptual fields (implementation in C09D4):

```text
plan_format_version
contract_id
boundary_node_id
render_projections
diagnostics
provenance
```

Do not duplicate contract fields (attrs, slots, collection inputs, item fields,
binding projections, approval_status, category, module/function intent).

`contract_id` links the plan to exactly one `ComponentContract`.

## 15. Validation layers

```text
PLAN_INTRINSIC_VALIDATION_RULE =
  without Design IR or contract: format version, contract_id,
  boundary_node_id shape, RenderProjection shape, closed role enum, public target
  XOR, duplicate projection identities, JSON diagnostics/provenance, no executable
  terms

PLAN_REFERENCE_VALIDATION_RULE =
  against exact ComponentizationPlan + ComponentContract + DesignDocument:
  contract_id matches; boundary exists; targets exist and lie in boundary;
  referenced public attrs/slots exist; role/type and role/node compatibility;
  BindingProjection targets lie in boundary; no BindingProjection/RenderProjection
  conflict; every render-relevant public input has required placement;
  unsupported/raw/unknown policy; stale plan against changed contract or IR ->
  invalid
```

Do not merge intrinsic and reference validation responsibilities.

## 16. Generation gate

C09D1 stated generation eligibility from an approved contract alone. C09D3
refines the generator input without changing contract schema:

```text
GENERATION_INPUT_RULE =
  an approved ComponentContract may be generated only together with its
  validated matching ComponentizationPlan and the exact DesignDocument

GENERATION_GATE_RULE =
  DesignDocument valid
  AND ComponentContract.validate_for_generation(...) = :ok
  AND ComponentizationPlan reference validation = :ok
  AND ComponentContract.approval_status = approved
```

```text
HEEX_GENERATOR_BOUNDARY =
  C09D3 authorizes no HEEx, Phoenix module emission, CSS, JS, file writing, or
  ejection work; generator authority remains a later slice
```

## 17. Versioning, determinism, provenance, performance, security

```text
PLAN_VERSIONING_RULE =
  plan_format_version is independent from Design IR, contract_format_version,
  CatalogueItem release, and Mix package version; format compatibility follows
  serialized-schema rules, not consumer public API SemVer

PLAN_DETERMINISM_RULE =
  identical DesignDocument + ComponentContract + ComponentizationPlan + authority
  version -> deterministic validation and future generation inputs; no map order,
  clock, randomness, DB, network, or runtime app state; explicit list ordering;
  deterministic JSON object keys

PLAN_PROVENANCE_RULE =
  plan provenance may record boundary selection evidence, unbound mapping rationale,
  classification and accessibility references; never executable instructions;
  structured fields remain authoritative; provenance cannot redefine contract_id,
  boundary_node_id, public target, target_node_id, or render_role
```

Expected future indexes (C09D4+): node_id → `DesignNode`, boundary membership,
public name → attr/slot, public target → binding or render projection. Validation
target `O(IR nodes + contract records + plan records + references)` without
walking the full tree once per projection.

Compiler-time cold artifact only. No Redis, ETS, Cachex, Postgres, GenServer,
Oban, PubSub, or network at runtime for the plan.

Security: no `String.to_atom`, dynamic module loading, `Code.eval_string`,
`apply` from artifact data, MFA callbacks, template expressions, selector
execution, source JS/PHP, URL fetch, DB query, or raw HTML execution from plan
data.

### Performance and scaling review

```text
DATA_LAYER = compile/build-time cold artifact
SAFE_AT_100K_RUNTIME_USERS = yes; no runtime path
EXCESS_DB_CALLS = none
REDIS_REPRESENTATION = none required
STREAMING = unnecessary for one component artifact; future whole-catalogue
  compiler may process documents incrementally
```

Runtime event-platform caching architecture does not apply to this compiler slice.

## 18. Decision matrix

| Public input case | Source evidence | BindingProjection? | RenderProjection? | Render role | Allowed target node type | Automatic proposal allowed? | Review blocker |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Dynamic site text | ValueBinding field, site scope | Yes (`scalar_attr`) | No | — | `ValueBinding.target_node_id` | Yes when binding + contract complete | evidence_insufficient, unsupported |
| Dynamic site asset | ValueBinding media field | Yes | No | — | binding target | Yes when complete | same |
| Dynamic site link URL | ValueBinding URL field | Yes | No | — | link-capable binding target | Yes when complete | same |
| Root collection | Root CollectionBinding | Yes (`collection_attr`) | No | — | repeat root | Yes when complete | shape/count errors |
| Collection item field | collection_item ValueBinding | Yes (`collection_item_field`) | No | — | item field target | Yes when complete | same |
| Nested collection | nested CollectionBinding | Yes (`collection_item_field`) | No | — | nested repeat root | Yes when complete | parent field errors |
| Top-level count | collection_count ValueBinding | Yes (`collection_count_attr`) | No | — | count target | Yes when proven | unproven count |
| Nested count | nested collection_count | Yes (`collection_item_field`) | No | — | count target | Yes when proven | same |
| Binding-backed slot | reviewed ValueBinding slot projection | Yes (`slot`) | No | — | slot target | Yes when explicit | auto slot forbidden |
| Static heading promoted to attr | static IR text + semantic review | No | Yes | `text_content` | heading/content node | No | naming, node mismatch |
| Static paragraph promoted to attr | static IR text | No | Yes | `text_content` | paragraph/rich_text | No | same |
| `heading_level` config | semantic review | No | Yes | `heading_level` | heading | No | type/validation |
| Consumer `image_alt` | accessibility policy | No | Yes | `asset_alt` | image | No | missing informative/decorative policy |
| Root `id` | integration need | No | Yes | `root_id` | boundary only | No | non-boundary target |
| Root `class` | additive styling | No | Yes | `root_class` | boundary only | No | source class as API |
| Root global attrs (`rest`) | Phoenix :global | No | Yes | `root_global_attrs` | boundary only | No | wrong type |
| Consumer action slot | reviewed action subtree | No (unless binding-backed slot) | Yes | `subtree_slot` | reviewed action node | No | invented behavior |
| Internal static/decorative label | not public | No | No | — | internal constant | Yes as internal | fake public attr |
| Static collection-item customization | unbound item field request | No | No in 1.0.0 | — | — | No | `STATIC_COLLECTION_ITEM_RULE` |
| Evidence-insufficient binding | normalization_status | If emitted, blocks approval | Must not bypass | — | — | No | `EVIDENCE_INSUFFICIENT_RULE` |
| Unsupported/raw/unknown visible node | semantic_type | — | — | — | — | No | `UNSUPPORTED_NODE_RULE` |

## 19. Edge cases and resulting rules

The following cases are encoded in the authority above, not deferred to an
informal risk list:

- **Multiple headings/images/action groups inside boundary:** each render-relevant
  public input still requires exactly one placement source; duplicate public
  targets or duplicate nodes for different attrs require explicit separate
  contract members and non-conflicting projections.
- **Same public attr mapped to two nodes:** invalid (duplicate public target).
- **Same node mapped by two public attrs:** allowed only when contract defines
  two distinct public attrs and roles/types are compatible without ambiguity.
- **Public target in both BindingProjection and RenderProjection:** invalid
  (`PUBLIC_RENDER_LINK_XOR_RULE`).
- **RenderProjection outside boundary:** invalid reference validation.
- **Boundary inside a collection repeat root or containing nested
  CollectionBindings:** allowed only when boundary and all binding repeat roots
  satisfy `COMPONENT_BOUNDARY_RULE`; otherwise `NEEDS_REVIEW`.
- **Binding target outside boundary:** invalid.
- **Slot target subtree contains binding-backed descendants:** allowed when
  contract and bindings already define consumer/data ownership; plan does not
  redefine bindings.
- **Image source without accessibility contract:** blocks generation
  (`IMAGE_ACCESSIBILITY_RULE`).
- **Fixture literal as public default:** forbidden (`STATIC_DEFAULT_RULE`).
- **Source label as public name:** forbidden (`PUBLIC_NAMING_RULE`).
- **Interaction-bearing node projected as plain text:** invalid role/node pairing.
- **Public attr with no structured placement:** blocks generation (coverage rule).
- **Stale plan vs changed contract or DesignDocument:** reference validation
  fails; regenerate or revise plan.

## 20. Expected future sequence

Preferred next slices (do not combine into C09D3):

```text
C09D4
  -> ComponentizationPlan core model + validation + deterministic serialization
  -> no proposer
  -> no HEEx

C09D5
  -> proposal construction using explicit semantic decision inputs
  -> produces proposed/needs_review ComponentContract + matching plan
  -> never auto-approves

later -> generator authority
later -> HEEx/Phoenix generation
```

C09D4 is the mechanical core-model slice (analogous to C09D2) without inventing
semantic names, placement heuristics, or generator behavior.

## 21. Catalogue boundary

```text
CATALOGUE_BOUNDARY =
  unchanged; Catalogue metadata does not replace ComponentContract or
  ComponentizationPlan; plan admission to Catalogue (if ever needed) requires
  separate authority
```

## 22. Scope confirmation

```text
production code changed = 0
Design IR schema changed = 0
ComponentContract schema changed = 0
Catalogue changed = 0
HEEx generator authorized = 0
merge performed = 0
```

Stop if work requires Design IR or ComponentContract schema change, collection-item
RenderProjection in 1.0.0, repeated slot DSL, a second approval lifecycle,
automatic semantic naming or classification, executable provenance, Catalogue
implementation, HEEx generation, or amending existing authority files instead
of this document.

## 23. Decision register

```text
COMPONENTIZATION_PLAN_ARTIFACT =
  explicit versioned serializable compiler artifact separate from ComponentContract

PLAN_FORMAT_VERSION = 1.0.0

PLAN_PUBLIC_API_AUTHORITY_RULE =
  ComponentContract sole public API authority; plan placement only; no silent
  public members

PLAN_LIFECYCLE_RULE =
  valid | invalid only; no approval_status on plan

COMPONENT_BOUNDARY_RULE =
  single explicit boundary_node_id; all projections and binding targets within
  subtree; root collection repeat roots within boundary

MULTI_ROOT_BOUNDARY_RULE =
  multiple disjoint roots -> NEEDS_REVIEW / unsupported in 1.0.0

COMPONENTIZATION_PROPOSAL_MODEL =
  validated DesignDocument + ComponentContract + ComponentizationPlan tuple

PROPOSER_APPROVAL_RULE =
  proposer never sets approval_status = approved

PUBLIC_NAMING_RULE =
  semantic explicit names only; no mechanical derivation from IR/source

CLASSIFICATION_RULE =
  explicit category decision; ambiguous -> NEEDS_REVIEW

RENDER_PROJECTION_MODEL =
  unbound public attr/slot -> target_node_id + render_role; no source binding

RENDER_PROJECTION_SCOPE =
  top-level attr/slot and root extension attrs only in 1.0.0

RENDER_ROLE_ENUM =
  text_content | asset_src | asset_alt | link_url | heading_level |
  root_id | root_class | root_global_attrs | subtree_slot

RENDER_ROLE_TYPE_COMPATIBILITY = see section 6.1

RENDER_ROLE_NODE_COMPATIBILITY = see section 6.2

BINDING_LINK_AUTHORITY = ComponentContract.BindingProjection

BINDING_RENDER_DUPLICATION_RULE =
  no RenderProjection for binding-backed public targets

PUBLIC_RENDER_LINK_XOR_RULE =
  BindingProjection XOR RenderProjection per public attr/slot

UNBOUND_PUBLIC_INPUT_RULE =
  RenderProjection required when generator needs placement; no guessing

STATIC_CONTENT_PROMOTION_RULE = see section 8

STATIC_DEFAULT_RULE =
  source literals do not auto-become public defaults

INTERNAL_CONSTANT_RULE = see section 8

ROOT_ID_RULE = root_id on boundary_node_id only

ROOT_CLASS_RULE = root_class on boundary_node_id only

ROOT_GLOBAL_ATTR_RULE = root_global_attrs on boundary_node_id only

ACTION_SLOT_RULE = subtree_slot only; no invented behavior

IMAGE_ACCESSIBILITY_RULE = contract policy required; no inferred decorative alt

COLLECTION_RENDER_PROJECTION_RULE =
  collections via bindings/projections only

STATIC_COLLECTION_ITEM_RULE = NEEDS_REVIEW in 1.0.0

EVIDENCE_INSUFFICIENT_RULE = fail closed; RenderProjection cannot bypass

UNSUPPORTED_NODE_RULE = visible impact blocks auto review-ready proposal

PLAN_INTRINSIC_VALIDATION_RULE = see section 15

PLAN_REFERENCE_VALIDATION_RULE = see section 15

GENERATION_INPUT_RULE =
  approved contract + matching validated plan + exact DesignDocument

GENERATION_GATE_RULE = see section 16

PLAN_VERSIONING_RULE = independent plan_format_version SemVer for serialized shape

PLAN_DETERMINISM_RULE = deterministic validation and generation inputs

PLAN_PROVENANCE_RULE = audit only; structured fields authoritative

CATALOGUE_BOUNDARY = unchanged by C09D3

HEEX_GENERATOR_BOUNDARY = not authorized in C09D3
```
