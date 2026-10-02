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

### 2.1 Design document identity

`DesignNode` IDs are traversal-path deterministic (for example `node_000001`,
`node_000001_000002`) and are **not** globally unique across unrelated
`DesignDocument` values. A plan must therefore bind to the exact document it
was built against.

```text
DESIGN_DOCUMENT_IDENTITY_RULE =
  design_document_sha256 is lowercase SHA-256 of the exact canonical
  deterministic JSON bytes returned by LiveFrames.IR.encode!/1 for an
  intrinsically valid DesignDocument

DESIGN_DOCUMENT_IDENTITY_FIELD = design_document_sha256
```

Requirements:

```text
64 lowercase hexadecimal characters

computed only from an intrinsically valid DesignDocument

reference validation recomputes the fingerprint from the supplied DesignDocument
and requires exact equality before trusting boundary_node_id or any
RenderProjection target_node_id
```

Do not use node IDs alone, source IDs, source paths, source labels, provenance
text, or timestamps as document identity.

### 2.2 Contract staleness

Do not hash the whole `ComponentContract` in C09D3. `contract_id` remains the
identity link between plan and contract.

```text
CONTRACT_STALENESS_RULE =
  plan invalid when referenced contract_id differs from the supplied contract,
  or when the supplied ComponentContract no longer satisfies
  PUBLIC_TOP_LEVEL_PLACEMENT_RULE, role matrices, or
  IMAGE_ACCESSIBILITY_VALIDATION_RULE referenced by the plan
```

Examples that invalidate placement compatibility:

```text
referenced attr or slot removed
referenced attr type changed incompatibly with render_role
slot cardinality changed incompatibly with subtree_slot
public target now binding-backed while plan also contains RenderProjection
PUBLIC_TOP_LEVEL_PLACEMENT_RULE no longer satisfied
IMAGE_ACCESSIBILITY_VALIDATION_RULE no longer satisfied
design_document_sha256 mismatch
```

Changes to review-only metadata such as `approval_status`, contract
diagnostics, or non-authoritative provenance do **not** by themselves make
placement stale. Do not create a separate public API fingerprint authority.

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

cryptographic bind to exact DesignDocument (design_document_sha256)

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

### 4.1 RenderProjection identity

Each `RenderProjection` is identified by its public target. Serialized form
retains `public_attr_name` and `public_slot_name` with exactly one non-nil
field (public target XOR). Do not add a second parallel identity representation.

```text
RENDER_PROJECTION_IDENTITY_RULE =
  Attr target -> {:attr, public_attr_name}
  Slot target -> {:slot, public_slot_name}

  identity is derived from the single non-nil public_attr_name or
  public_slot_name field

  exactly one RenderProjection per public target identity

  duplicate public-target identity -> invalid
```

This is what `duplicate projection identities` means in validation.

### 4.2 First-wave scope

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
  in-boundary CollectionBinding coverage follows IN_BOUNDARY_BINDING_COVERAGE_RULE
  (owner_node_id and repeat_root_node_id membership; no vague component ownership)
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

Format `1.0.0` uses an exact machine-checkable matrix. Reference validation
compares the referenced `ComponentContract` attr or slot definition; no review
prose substitutes for these rules.

```text
RENDER_ROLE_TYPE_COMPATIBILITY =
  text_content        -> public Attr.type == :string
  asset_src           -> public Attr.type == :string
  asset_alt           -> public Attr.type == :string
  link_url            -> public Attr.type == :string
  heading_level       -> public Attr.type == :integer
                        AND validation["values"] == [1,2,3,4,5,6]
  root_id             -> public Attr.type == :string
  root_class          -> public Attr.type == :string
  root_global_attrs   -> public Attr.type == :global
  subtree_slot        -> public Slot with cardinality "0..1"
```

Not supported in plan `1.0.0` (later authority required):

```text
asset_src or asset_alt with Attr.type == :map
structured media :map attrs
:boolean or :integer for text_content
:any without separate authority
repeated slots (cardinality other than 0..1 for subtree_slot)
slot attributes
```

A render role must never silently reinterpret an incompatible public type.

### 6.2 Role and node semantic compatibility

Reference validation compares `DesignNode.semantic_type` on
`target_node_id` (exact equality to one allowed token):

```text
RENDER_ROLE_NODE_COMPATIBILITY =
  text_content     -> heading | paragraph | rich_text
  asset_src        -> image
  asset_alt        -> image
  link_url         -> link
  heading_level    -> heading
  subtree_slot     -> actions | button | link
  root_id          -> boundary_node_id only
  root_class       -> boundary_node_id only
  root_global_attrs-> boundary_node_id only
```

Any pair outside this closed matrix: invalid / `NEEDS_REVIEW` for generation.
Do not coerce.

### 6.3 Same-node role co-location

A node may host multiple `RenderProjection` records only under these first-wave
combinations:

```text
RENDER_ROLE_COLOCATION_RULE =
  heading node: at most one text_content; at most one heading_level
  image node: at most one asset_src; at most one asset_alt
  IMAGE_ALT_SAME_NODE_RULE =
    consumer_supplied image policy -> asset_src (BindingProjection or
    RenderProjection) and matching asset_alt RenderProjection on the same
    image target_node_id;
    decorative image policy -> asset_src placement only; no asset_alt
    RenderProjection on that image node
  link node: at most one link_url
  boundary node (boundary_node_id): at most one root_id; at most one
    root_class; at most one root_global_attrs
  subtree_slot target: exclusive under SUBTREE_SLOT_OWNERSHIP_RULE
```

Duplicate instances of the **same** render role on one node: invalid. Any other
multi-role combination on one node: invalid / `NEEDS_REVIEW`.

### 6.4 Subtree slot ownership

```text
SUBTREE_SLOT_OWNERSHIP_RULE =
  subtree_slot replaces the target DesignNode subtree as consumer-owned markup
  for generation purposes

SUBTREE_SLOT_BINDING_DESCENDANT_POLICY =
  the target node's parent remains part of generated internal structure;
  the target node and its descendants are not separately emitted from Design IR;
  no BindingProjection.target_node_id may equal the subtree_slot target or lie
  beneath it;
  no other RenderProjection.target_node_id may equal the subtree_slot target
  or lie beneath it except the subtree_slot projection itself;
  the replaced subtree must not contain any ValueBinding.target_node_id,
  CollectionBinding.owner_node_id, or CollectionBinding.repeat_root_node_id
  -> otherwise invalid / NEEDS_REVIEW
```

If the subtree contains only supported static internal `DesignNode` records (no
bindings), `subtree_slot` may replace them subject to role/node compatibility.
Collection-backed, repeated, `:let`, fallback, or binding-backed slot
composition requires later authority.

## 7. Public render link coverage

`ComponentContract` format `1.0.0` has no field that classifies a public `Attr`
or `Slot` as rendering vs non-rendering. Plan `1.0.0` therefore must not
require a later implementation to infer that distinction.

```text
PUBLIC_TOP_LEVEL_PLACEMENT_RULE =
  every ComponentContract.public_attrs entry and every
  ComponentContract.public_slots entry must have exactly one structured
  placement source:

  exactly one matching BindingProjection
  XOR
  exactly one matching RenderProjection

PUBLIC_ATTR_ZERO_PLACEMENT_POLICY =
  zero BindingProjection and zero RenderProjection for a public attr -> invalid

PUBLIC_SLOT_ZERO_PLACEMENT_POLICY =
  zero BindingProjection and zero RenderProjection for a public slot -> invalid

PUBLIC_MULTIPLE_PLACEMENT_POLICY =
  more than one BindingProjection, more than one RenderProjection, or both
  kinds for the same public target -> invalid
```

There is no first-wave exemption for:

```text
non-rendering public attr
metadata-only public slot
```

If a future public configuration attr would affect rendering through a mechanism
not covered by the current render-role vocabulary (for example `image_position`,
`overlay_variant`, or `layout_variant`):

```text
NEEDS_REVIEW
```

until a later render-role authority defines that mechanism.

Reference validation indexes public targets and computes, per
`{:attr, public_attr_name}` or `{:slot, public_slot_name}`:

```text
binding_projection_count
render_projection_count
```

Require:

```text
(binding_projection_count == 1 AND render_projection_count == 0)
OR
(binding_projection_count == 0 AND render_projection_count == 1)
```

All other combinations are invalid.

```text
PUBLIC_RENDER_LINK_XOR_RULE =
  complete top-level coverage per PUBLIC_TOP_LEVEL_PLACEMENT_RULE;
  not only conflict prevention between BindingProjection and RenderProjection
```

Binding-backed members obtain target node, binding scope, target kind, and
collection ownership from `BindingProjection` plus the referenced Design IR
binding. `ValueBinding.target_kind` remains normalized frontend destination
evidence; no public name is inferred from it.

```text
UNBOUND_PUBLIC_INPUT_RULE =
  a public attr or slot without a Design IR binding is permitted when semantic
  review proves the reusable API; it must still satisfy
  PUBLIC_TOP_LEVEL_PLACEMENT_RULE through exactly one RenderProjection; absence
  of that RenderProjection is invalid, not an invitation to guess
```

Unused `RenderProjection` records whose public target is not a contract member
fail reference validation.

### 7.1 Placement ownership split

```text
BindingProjection coverage owns:
  top-level collection attrs and top-level count attrs (public attrs)
  collection item fields (via item_field projections, not RenderProjection)
  nested collections
  binding-backed slots
  binding-backed scalar attrs

RenderProjection coverage owns:
  only unbound top-level public attrs and slots authorized by plan 1.0.0

No public item field may use RenderProjection in plan 1.0.0.
```

`CollectionInput.item_fields`, nested collection fields, and collection counts
represented as item fields are **not** subject to
`PUBLIC_TOP_LEVEL_PLACEMENT_RULE`. They remain governed by `CollectionInput`,
`BindingProjection`, and `IN_BOUNDARY_BINDING_COVERAGE_RULE`.

### 7.2 In-boundary binding coverage

Public-input placement is necessary but not sufficient. The plan must also
prove complete representation of in-boundary Design IR bindings.

```text
VALUE_BINDING_COVERAGE_RULE =
  every ValueBinding whose target_node_id lies at or beneath boundary_node_id
  must have exactly one ComponentContract.BindingProjection with
  source_binding_kind = value and source_binding_id equal to that ValueBinding ID

  zero projections -> invalid / NEEDS_REVIEW
  more than one -> invalid

  includes normalization_status = normalized and evidence_insufficient;
  omission does not bypass D1/D2 approval blocks
```

```text
COLLECTION_BINDING_COVERAGE_RULE =
  both owner_node_id and repeat_root_node_id outside boundary -> irrelevant
  both inside boundary -> exactly one collection-source BindingProjection with
    source_binding_kind = collection and source_binding_id equal to that
    CollectionBinding ID
  nested in-boundary child -> parent CollectionBinding must also be in-boundary
    and represented
```

```text
BOUNDARY_CROSSING_BINDING_RULE =
  if exactly one of owner_node_id or repeat_root_node_id lies within the
  component boundary -> invalid / NEEDS_REVIEW;
  the boundary may not cut through repetition ownership in plan 1.0.0
```

```text
IN_BOUNDARY_BINDING_COVERAGE_RULE =
  VALUE_BINDING_COVERAGE_RULE + COLLECTION_BINDING_COVERAGE_RULE +
  BOUNDARY_CROSSING_BINDING_RULE
```

This is the inverse invariant: IR binding semantics ↔ `BindingProjection`
coverage.

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
  a non-image node with no BindingProjection or RenderProjection may retain
  Design IR content as an internal generated value when content is supported,
  semantics are complete, the value is not consumer-owned, and behavior is not
  concealed; do not create a fake attr merely to preserve literal text;
  an in-boundary image node without authorized public asset-source placement is
  not an ordinary internal constant (see STATIC_INTERNAL_IMAGE_RULE)
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
  consumer-owned actions remain slots; subtree_slot follows
  SUBTREE_SLOT_OWNERSHIP_RULE; the plan must not invent navigate, patch,
  phx-click, event names, server handlers, JS commands, or Ash actions
```

### 10.1 Image accessibility representation

Do not change `ComponentContract` schema. Use the existing `Attr.accessibility`
JSON map on the **asset source** public attr.

An asset source is any public attr whose rendered image source is established by
either a `BindingProjection` to an image node or a `RenderProjection` with
`render_role = asset_src`.

```text
IMAGE_SOURCE_BINDING_POLICY =
  binding-backed image source: image node from BindingProjection.target_node_id
  plus referenced ValueBinding semantics; accessibility map on source public attr

IMAGE_SOURCE_RENDER_PROJECTION_POLICY =
  unbound image source: RenderProjection(render_role = asset_src) on image node;
  accessibility map on that source public attr
```

Both paths require `IMAGE_ACCESSIBILITY_VALIDATION_RULE`. Binding-backed sources
do not bypass accessibility validation.

Plan `1.0.0` admits exactly two policies.

#### Consumer-supplied alt

```text
CONSUMER_SUPPLIED_ALT_POLICY =
  source Attr.accessibility = %{
    "image_alt_policy" => "consumer_supplied",
    "alt_attr_name" => "<public attr name>",
    "required_when_source_present" => true
  }
```

Require:

```text
alt_attr_name resolves to an existing public_attrs entry with type :string

named alt attr satisfies PUBLIC_TOP_LEVEL_PLACEMENT_RULE through exactly one
asset_alt RenderProjection on the same image target_node_id as the asset source

when image source renders -> consumer must supply a binary alt value at runtime
(empty string = deliberate decorative for that invocation; non-empty = informative;
do not infer either from nil)
```

#### Decorative image

```text
DECORATIVE_ALT_POLICY =
  source Attr.accessibility = %{
    "image_alt_policy" => "decorative"
  }

no alt_attr_name key
no asset_alt RenderProjection for that image node
later generation emits alt="" as explicit decorative output
```

Do not derive decorative semantics from nil, missing accessibility metadata,
empty source alt, source-editor defaults, or provenance prose.

#### Invalid policies

These block plan reference validation (`IMAGE_ACCESSIBILITY_VALIDATION_RULE`):

```text
missing image_alt_policy
unknown image_alt_policy
consumer_supplied without alt_attr_name
consumer_supplied without required_when_source_present = true
alt_attr_name missing from public_attrs
alt attr type not :string
asset_alt projection on a different image node than the source
multiple asset_alt RenderProjections for the same source image
decorative policy with alt_attr_name
decorative policy with asset_alt RenderProjection
```

Use diagnostics under `componentization_plan.accessibility.*`:

```text
componentization_plan.accessibility.image_policy_missing
componentization_plan.accessibility.image_policy_invalid
componentization_plan.accessibility.alt_attr_missing
componentization_plan.accessibility.alt_projection_mismatch
```

```text
IMAGE_ACCESSIBILITY_REPRESENTATION_RULE =
  closed first-wave keys inside existing Attr.accessibility on asset source attrs

IMAGE_ACCESSIBILITY_VALIDATION_RULE =
  reference validation enforces CONSUMER_SUPPLIED_ALT_POLICY or
  DECORATIVE_ALT_POLICY for every authorized asset source; no arbitrary
  provenance satisfies accessibility validation
```

#### Static internal images

```text
STATIC_INTERNAL_IMAGE_RULE =
  an in-boundary DesignNode with semantic_type = image that is not replaced by
  subtree_slot and is not represented by an authorized public asset-source
  placement (BindingProjection or asset_src RenderProjection) blocks plan 1.0.0
  generation eligibility -> NEEDS_REVIEW

do not inspect DesignNode.attributes, SourceTrace, source HTML, or source-editor
alt fields to invent static accessibility policy in C09D3
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
  any DesignNode with semantic_type raw | unsupported | unknown inside the
  selected boundary blocks plan reference validation and generation eligibility
  in plan 1.0.0; do not inspect arbitrary provenance prose to waive this rule;
  structured exclusions require later authority
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
design_document_sha256
boundary_node_id
render_projections
diagnostics
provenance
```

Do not duplicate contract fields (attrs, slots, collection inputs, item fields,
binding projections, approval_status, category, module/function intent).

`contract_id` links the plan to exactly one `ComponentContract`.

## 14.1 ComponentizationPlan diagnostic model

Define a distinct conceptual record. Do not reuse
`ComponentContract.Diagnostic` as hidden authority.

```text
PLAN_DIAGNOSTIC_MODEL = ComponentizationPlan.Diagnostic

PLAN_DIAGNOSTIC_NAMESPACE = componentization_plan.*

PLAN_BLOCKING_SEVERITIES = error | fatal
```

Fields:

```text
code
severity
message
path
suggested_action
metadata
```

Defaults follow compiler convention:

```text
severity = error
path = nil
suggested_action = nil
metadata = %{}
```

Closed severities: `info`, `warning`, `error`, `fatal`. Blocking:
`error`, `fatal`. Codes must begin with `componentization_plan.`. Metadata
must be inert JSON-compatible data.

Validators return generated diagnostics; they do not silently append them to
`plan.diagnostics`. Stored plan diagnostics are themselves validated on
intrinsic checks.

Minimum frozen code families:

```text
componentization_plan.plan.invalid
componentization_plan.version.invalid
componentization_plan.version.unsupported

componentization_plan.design_document.fingerprint_invalid
componentization_plan.design_document.mismatch

componentization_plan.contract.mismatch

componentization_plan.boundary.invalid
componentization_plan.boundary.missing
componentization_plan.boundary.binding_crosses

componentization_plan.render_projection.invalid
componentization_plan.render_projection.duplicate_target
componentization_plan.render_projection.target_missing
componentization_plan.render_projection.target_outside_boundary
componentization_plan.render_projection.role_type_mismatch
componentization_plan.render_projection.role_node_mismatch
componentization_plan.render_projection.role_conflict

componentization_plan.slot.subtree_conflict

componentization_plan.binding.uncovered
componentization_plan.binding.duplicate
componentization_plan.binding.evidence_insufficient

componentization_plan.public_input.placement_missing
componentization_plan.public_input.placement_conflict

componentization_plan.accessibility.image_policy_missing
componentization_plan.accessibility.image_policy_invalid
componentization_plan.accessibility.alt_attr_missing
componentization_plan.accessibility.alt_projection_mismatch

componentization_plan.unsupported_node
componentization_plan.metadata.invalid
componentization_plan.generation_blocked
```

## 15. Validation layers

```text
PLAN_INTRINSIC_VALIDATION_RULE =
  without Design IR or contract:
  plan format version
  contract_id
  design_document_sha256 syntax (64 lowercase hex)
  boundary_node_id shape
  RenderProjection shape
  render-role enum
  public target XOR
  RenderProjection public-target uniqueness (RENDER_PROJECTION_IDENTITY_RULE)
  ComponentizationPlan.Diagnostic shape and codes
  provenance JSON safety
  no executable terms

PLAN_REFERENCE_VALIDATION_RULE =
  against exact ComponentizationPlan + ComponentContract + DesignDocument:
  recompute design_document_sha256 and require exact match first
  contract_id equality and CONTRACT_STALENESS_RULE checks against exact
  PUBLIC_TOP_LEVEL_PLACEMENT_RULE, role matrices, and
  IMAGE_ACCESSIBILITY_VALIDATION_RULE
  boundary node exists; build boundary membership index once
  RenderProjection targets exist and lie in boundary
  exact RENDER_ROLE_TYPE_COMPATIBILITY matrix
  exact RENDER_ROLE_NODE_COMPATIBILITY matrix
  RENDER_ROLE_COLOCATION_RULE and IMAGE_ALT_SAME_NODE_RULE
  SUBTREE_SLOT_OWNERSHIP_RULE and binding-descendant exclusion
  BindingProjection targets lie in boundary
  IN_BOUNDARY_BINDING_COVERAGE_RULE
  PUBLIC_TOP_LEVEL_PLACEMENT_RULE with per-target binding/render counts
  IMAGE_ACCESSIBILITY_VALIDATION_RULE and STATIC_INTERNAL_IMAGE_RULE
  UNSUPPORTED_NODE_RULE fail closed

REFERENCE_VALIDATION_COMPLEXITY =
  O(IR nodes + IR bindings + contract records + plan records + references);
  build indexes once; do not walk the full tree once per projection
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
  AND plan.design_document_sha256 ==
     SHA-256(canonical LiveFrames.IR.encode! bytes for that DesignDocument)
  AND ComponentContract.validate_for_generation(...) = :ok
  AND ComponentizationPlan intrinsic validation = :ok
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
  design_document_sha256, boundary_node_id, public target, target_node_id, or
  render_role
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
| Static heading promoted to attr | static IR text + semantic review | No | Yes | `text_content` | `heading` | No | type/node mismatch |
| Static paragraph promoted to attr | static IR text | No | Yes | `text_content` | `paragraph` or `rich_text` | No | type/node mismatch |
| `heading_level` config | semantic review | No | Yes | `heading_level` | heading | No | type/validation |
| Consumer `image_alt` | `consumer_supplied` policy | No | Yes | `asset_alt` | same image as source | No | accessibility / same-node |
| Root `id` | integration need | No | Yes | `root_id` | boundary only | No | non-boundary target |
| Root `class` | additive styling | No | Yes | `root_class` | boundary only | No | source class as API |
| Root global attrs (`rest`) | Phoenix :global | No | Yes | `root_global_attrs` | boundary only | No | wrong type |
| Consumer action slot | reviewed action subtree | No (unless binding-backed slot) | Yes | `subtree_slot` | `actions`, `button`, or `link` | No | subtree binding conflict |
| Internal static/decorative label | not public | No | No | — | internal constant | Yes as internal | fake public attr |
| Static collection-item customization | unbound item field request | No | No in 1.0.0 | — | — | No | `STATIC_COLLECTION_ITEM_RULE` |
| Evidence-insufficient binding | normalization_status | If emitted, blocks approval | Must not bypass | — | — | No | `EVIDENCE_INSUFFICIENT_RULE` |
| Unsupported/raw/unknown visible node | semantic_type | — | — | — | any in boundary | No | `UNSUPPORTED_NODE_RULE` |
| Unprojected normalized in-boundary ValueBinding | ValueBinding in boundary | No | — | — | — | No | `binding.uncovered` |
| Unprojected evidence-insufficient in-boundary ValueBinding | evidence_insufficient | No (must not omit) | — | — | — | No | `binding.uncovered` + contract block |
| Unprojected in-boundary root CollectionBinding | both nodes in boundary | No | — | — | — | No | `binding.uncovered` |
| Unprojected in-boundary nested CollectionBinding | child in boundary | No | — | — | — | No | `binding.uncovered` / missing parent |
| Boundary-crossing CollectionBinding | owner/repeat split by boundary | — | — | — | — | No | `boundary.binding_crosses` |
| `subtree_slot` with binding-backed descendant | ValueBinding/CollectionBinding in subtree | — | Yes invalid | `subtree_slot` | actions/button/link | No | `slot.subtree_conflict` |
| Plan vs different DesignDocument, same node IDs | path-based IDs collide | — | — | — | — | No | `design_document.mismatch` |
| Structured media attr `:map` request | semantic review | No | No in 1.0.0 | — | — | No | role/type matrix |
| Public attr with zero placement | top-level attr | No | No | — | — | No | `public_input.placement_missing` |
| Public slot with zero placement | top-level slot | No | No | — | — | No | `public_input.placement_missing` |
| Public attr with both placements | conflict | Yes | Yes | — | — | No | `public_input.placement_conflict` |
| Binding-backed image + consumer alt | BindingProjection + policy map | Yes source | Yes alt | `asset_src` / `asset_alt` | same image node | No when complete | accessibility codes |
| Unbound `asset_src` + consumer alt | RenderProjection + policy map | No source | Yes | `asset_src` / `asset_alt` | same image node | No when complete | same |
| Decorative public image source | `decorative` policy | Yes or RenderProjection | No alt projection | `asset_src` | image | No when complete | alt projection forbidden |
| Image source missing accessibility metadata | no `image_alt_policy` | — | — | — | image | No | `accessibility.image_policy_missing` |
| Consumer alt on wrong image node | policy map | — | Yes invalid | `asset_alt` | wrong node | No | `accessibility.alt_projection_mismatch` |
| Static internal image, no public source | internal image node | No | No | — | image | No | `STATIC_INTERNAL_IMAGE_RULE` |

## 19. Edge cases and resulting rules

The following cases are encoded in the authority above, not deferred to an
informal risk list:

- **Multiple headings/images/action groups inside boundary:** each top-level
  public attr and slot satisfies `PUBLIC_TOP_LEVEL_PLACEMENT_RULE`; duplicate
  public targets or invalid role co-location remain invalid.
- **Same public attr mapped to two nodes:** invalid (duplicate public target).
- **Same node mapped by two public attrs:** allowed only when contract defines
  two distinct public attrs and roles/types are compatible without ambiguity.
- **Public target in both BindingProjection and RenderProjection:** invalid
  (`PUBLIC_MULTIPLE_PLACEMENT_POLICY`).
- **Top-level public attr or slot with zero placements:** invalid
  (`PUBLIC_TOP_LEVEL_PLACEMENT_RULE`).
- **RenderProjection outside boundary:** invalid reference validation.
- **Boundary inside a collection repeat root or containing nested
  CollectionBindings:** allowed only when `IN_BOUNDARY_BINDING_COVERAGE_RULE`
  and `BOUNDARY_CROSSING_BINDING_RULE` both pass; otherwise invalid /
  `NEEDS_REVIEW`.
- **Binding target outside boundary:** invalid.
- **Slot target subtree contains binding-backed descendants:** invalid in plan
  1.0.0 (`SUBTREE_SLOT_BINDING_DESCENDANT_POLICY`); do not combine slot output
  with separately emitted binding-backed descendants.
- **Image source without structured accessibility policy:** blocks generation
  (`IMAGE_ACCESSIBILITY_VALIDATION_RULE`).
- **Static internal image without public asset-source placement:** blocks plan
  1.0.0 (`STATIC_INTERNAL_IMAGE_RULE`).
- **Fixture literal as public default:** forbidden (`STATIC_DEFAULT_RULE`).
- **Source label as public name:** forbidden (`PUBLIC_NAMING_RULE`).
- **Interaction-bearing node projected as plain text:** invalid role/node pairing.
- **Public attr with no structured placement:** invalid
  (`PUBLIC_ATTR_ZERO_PLACEMENT_POLICY`).
- **Stale plan vs changed contract:** `CONTRACT_STALENESS_RULE` when current
  contract no longer satisfies exact placement, role, or accessibility validation;
  review-only metadata changes alone do not.
- **Stale plan vs changed DesignDocument:** `design_document_sha256` mismatch ->
  invalid.

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

DESIGN_DOCUMENT_IDENTITY_FIELD = design_document_sha256

DESIGN_DOCUMENT_IDENTITY_RULE =
  lowercase SHA-256 of canonical LiveFrames.IR.encode!/1 bytes for the exact
  DesignDocument; reference validation recomputes before trusting nodes

CONTRACT_STALENESS_RULE =
  invalid on contract_id mismatch or when the supplied ComponentContract no
  longer satisfies PUBLIC_TOP_LEVEL_PLACEMENT_RULE, role matrices, or
  IMAGE_ACCESSIBILITY_VALIDATION_RULE referenced by the plan; not on
  approval_status/diagnostics alone

PLAN_PUBLIC_API_AUTHORITY_RULE =
  ComponentContract sole public API authority; plan placement only; no silent
  public members

PLAN_LIFECYCLE_RULE =
  valid | invalid only; no approval_status on plan

COMPONENT_BOUNDARY_RULE =
  single explicit boundary_node_id; all projections and binding targets within
  subtree; collection membership via owner/repeat boundary rules

MULTI_ROOT_BOUNDARY_RULE =
  multiple disjoint roots -> NEEDS_REVIEW / unsupported in 1.0.0

IN_BOUNDARY_BINDING_COVERAGE_RULE =
  complete ValueBinding and in-boundary CollectionBinding BindingProjection
  coverage; see section 7.2

BOUNDARY_CROSSING_BINDING_RULE =
  owner/repeat split across boundary -> invalid / NEEDS_REVIEW

VALUE_BINDING_COVERAGE_RULE = see section 7.2

COLLECTION_BINDING_COVERAGE_RULE = see section 7.2

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

RENDER_PROJECTION_IDENTITY_RULE =
  {:attr, public_attr_name} | {:slot, public_slot_name}; one projection per
  public target

RENDER_PROJECTION_SCOPE =
  top-level attr/slot and root extension attrs only in 1.0.0

RENDER_ROLE_ENUM =
  text_content | asset_src | asset_alt | link_url | heading_level |
  root_id | root_class | root_global_attrs | subtree_slot

RENDER_ROLE_TYPE_COMPATIBILITY = exact matrix section 6.1

RENDER_ROLE_NODE_COMPATIBILITY = exact matrix section 6.2

RENDER_ROLE_COLOCATION_RULE = section 6.3

SUBTREE_SLOT_OWNERSHIP_RULE = section 6.4

SUBTREE_SLOT_BINDING_DESCENDANT_POLICY = section 6.4

BINDING_LINK_AUTHORITY = ComponentContract.BindingProjection

BINDING_RENDER_DUPLICATION_RULE =
  no RenderProjection for binding-backed public targets

PUBLIC_RENDER_LINK_XOR_RULE =
  PUBLIC_TOP_LEVEL_PLACEMENT_RULE: exactly one BindingProjection XOR exactly
  one RenderProjection per top-level public attr/slot

PUBLIC_TOP_LEVEL_PLACEMENT_RULE = section 7

UNBOUND_PUBLIC_INPUT_RULE =
  unbound public attr/slot still requires exactly one RenderProjection under
  PUBLIC_TOP_LEVEL_PLACEMENT_RULE

STATIC_CONTENT_PROMOTION_RULE = see section 8

STATIC_DEFAULT_RULE =
  source literals do not auto-become public defaults

INTERNAL_CONSTANT_RULE = see section 8; excludes unprojected image nodes

ROOT_ID_RULE = root_id on boundary_node_id only

ROOT_CLASS_RULE = root_class on boundary_node_id only

ROOT_GLOBAL_ATTR_RULE = root_global_attrs on boundary_node_id only

ACTION_SLOT_RULE = subtree_slot only; no invented behavior

IMAGE_ACCESSIBILITY_RULE =
  IMAGE_ACCESSIBILITY_REPRESENTATION_RULE + IMAGE_ACCESSIBILITY_VALIDATION_RULE

IMAGE_ACCESSIBILITY_REPRESENTATION_RULE = section 10.1

IMAGE_ACCESSIBILITY_VALIDATION_RULE = section 10.1

CONSUMER_SUPPLIED_ALT_POLICY = section 10.1

DECORATIVE_ALT_POLICY = section 10.1

STATIC_INTERNAL_IMAGE_RULE = section 10.1

IMAGE_SOURCE_BINDING_POLICY = section 10.1

IMAGE_SOURCE_RENDER_PROJECTION_POLICY = section 10.1

IMAGE_ALT_SAME_NODE_RULE = section 6.3

COLLECTION_RENDER_PROJECTION_RULE =
  collections via bindings/projections only

STATIC_COLLECTION_ITEM_RULE = NEEDS_REVIEW in 1.0.0

EVIDENCE_INSUFFICIENT_RULE = fail closed; RenderProjection cannot bypass

UNSUPPORTED_NODE_RULE =
  raw | unsupported | unknown anywhere inside boundary blocks plan 1.0.0

PLAN_DIAGNOSTIC_MODEL = ComponentizationPlan.Diagnostic section 14.1

PLAN_DIAGNOSTIC_NAMESPACE = componentization_plan.*

PLAN_BLOCKING_SEVERITIES = error | fatal

PLAN_INTRINSIC_VALIDATION_RULE = see section 15

PLAN_REFERENCE_VALIDATION_RULE = see section 15

REFERENCE_VALIDATION_COMPLEXITY = see section 15

PLAN_CONCEPTUAL_FIELDS =
  plan_format_version, contract_id, design_document_sha256, boundary_node_id,
  render_projections, diagnostics, provenance

GENERATION_INPUT_RULE =
  approved contract + matching validated plan + exact DesignDocument

GENERATION_GATE_RULE = see section 16

PLAN_VERSIONING_RULE = independent plan_format_version SemVer for serialized shape

PLAN_DETERMINISM_RULE = deterministic validation and generation inputs

PLAN_PROVENANCE_RULE = audit only; structured fields authoritative

CATALOGUE_BOUNDARY = unchanged by C09D3

HEEX_GENERATOR_BOUNDARY = not authorized in C09D3
```
