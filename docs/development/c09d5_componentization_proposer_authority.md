# C09D5-A Componentization proposer authority

**Status:** authority/documentation only (C09D5-A)

**Plan ID:** C09D5-A

**Plan version:** v3

**Scope:** freeze explicit semantic-decision input model and proposer construction
rules; no proposer production code in this slice

**Authority:** this file is the active contract for C09D5 proposer semantics.
`docs/development/c09d1_component_contract_authority.md` and
`docs/development/c09d3_componentization_plan_authority.md` win on public API and
placement conflicts respectively. Historical Hero/P6.1 evidence in
`docs/19_PHASE_6_NATIVE_COMPONENTIZATION.md` and `docs/08_COMPONENT_MODEL.md` is
non-authoritative examples only.

**Accepted base:** `4bad28d60c2a0caa0e249e69368555a81be12aa8`

**Accepted tree:** `986c806a928ecf42bad9166870b7a8ba3137cb4e`

**Post-merge CI:** run `37034504527`, conclusion `success` (C09D4 / PR #121)

**Last updated:** 2026-10-02

### Revision log

- `v1` — initial C09D5-A authority: semantic input model, derivation matrix,
  proposer lifecycle, outcome rules, failure modes, decision register
- `v2` — freeze EvidenceHandlingDecision outcomes, canonical decision/output
  ordering, complete decision-record field shapes, outcome taxonomy, multi-root
  behavior (PR #122 review)
- `v3` — image-source detection (D3-only), accessibility map equality,
  remove InputProvenanceAudit and review_required, freeze ProposerResult pair
  and provisional approval_status (PR #122 final tightening)

---

## 1. Goal and non-goals

### Goal

Freeze a machine-implementable contract for the **componentization proposer**:
the compile-time stage that turns a validated `DesignDocument` plus **explicit
semantic decisions** into a deterministic candidate pair:

```text
ComponentContract (approval_status = proposed | needs_review)
+ matching ComponentizationPlan (structurally/reference valid or invalid only)
```

The proposer must not invent semantics, auto-approve, or become a heuristic
inference engine over Design IR or source metadata.

### Non-goals (C09D5-A and deferred C09D5 implementation)

```text
semantic guessing or missing-decision fill-in
automatic approval_status = approved
automatic approval_status = rejected (semantic judgment)
HEEx / Phoenix module emission
CSS / JS generation
Catalogue admission or Storybook
source-system runtime integration (Bricks, WordPress, Frames vocabulary as authority)
database, network, cache, or runtime service access
new serialized public artifacts (ComponentizationProposal wrapper, decision-file format)
Design IR 2.0.0 schema changes
ComponentContract format 1.0.0 schema changes
ComponentizationPlan format 1.0.0 schema changes
new render roles or collection-item RenderProjection
binding-backed slot composition semantics
static collection-item public customization in plan 1.0.0
```

C09D5-A produces this authority document only. C09D5-B (separate slice) may
implement the proposer under these rules.

---

## 2. Existing authority hierarchy

Read order for implementers:

| Priority | Document | Owns |
| --- | --- | --- |
| 1 | `docs/03_DESIGN_IR_SPEC.md` | normalized design meaning |
| 2 | `docs/development/c09d1_component_contract_authority.md` | public API, BindingProjection, collections, naming, accessibility fields |
| 3 | `docs/development/c09d3_componentization_plan_authority.md` | boundary, RenderProjection, placement XOR, plan validation, generation gate |
| 4 | **this document** | proposer inputs, construction, outcomes, process lifecycle |
| 5 | `docs/00_LIVEFRAMES_MASTER_SPEC.md` §14 | product boundary (non-schema) |
| 6 | `docs/08_COMPONENT_MODEL.md`, `docs/19_PHASE_6_NATIVE_COMPONENTIZATION.md` | Hero evidence only |

Merged implementation on accepted base (reference only, not amended by C09D5-A):

```text
apps/live_frames/lib/live_frames/component_contract.ex
apps/live_frames/lib/live_frames/component_contract/**
apps/live_frames/lib/live_frames/componentization_plan.ex
apps/live_frames/lib/live_frames/componentization_plan/**
apps/live_frames/lib/live_frames/ir/**
```

C09D3 forward contract (unchanged):

```text
C09D5 -> proposal construction using explicit semantic decision inputs
      -> produces proposed/needs_review ComponentContract + matching plan
      -> never auto-approves
```

---

## 3. Backward compiler plan

```text
source design
  -> normalized DesignDocument (LiveFrames.IR.validate/1)
  -> explicit semantic componentization decisions (compile-time input; section 6)
  -> proposer (C09D5-B)
  -> ComponentContract + ComponentizationPlan candidate pair
  -> human/reviewer approval on ComponentContract only
  -> later HEEx generation (separate authority; requires approved contract + validated plan)
```

C09D5 owns only the middle arrow. Parsing and IR normalization are upstream;
approval and generation are downstream.

---

## 4. Domain and resource map

| Concept | Identity | Owner | Lifecycle / terminal state |
| --- | --- | --- | --- |
| `DesignDocument` | IR document value; node IDs path-scoped per document | Design IR | validated or invalid; fingerprint via `ComponentizationPlan.design_document_sha256/1` |
| `ComponentizationSemanticInput` | compile-time input bundle (section 6); **not serialized** | proposer caller / review tooling | valid or invalid input; no approval state |
| `ComponentContract` | `contract_id` | persisted compiler artifact | `approval_status`: proposed, needs_review, approved, rejected — **proposer may set only proposed or needs_review** |
| `ComponentizationPlan` | `(contract_id, design_document_sha256)` link | persisted compiler artifact | structurally/reference valid or invalid; **no approval_status** |
| `BindingProjection` | `(source_binding_kind, source_binding_id, projection_kind, public target fields)` | ComponentContract | no independent status (D1) |
| `RenderProjection` | `{:attr, name}` or `{:slot, name}` | ComponentizationPlan | one per public target (D3) |
| `ComponentContract.Diagnostic` | stable `component_contract.*` code | ComponentContract.diagnostics | info / warning / error / fatal |
| `ComponentizationPlan.Diagnostic` | stable `componentization_plan.*` code | ComponentizationPlan.diagnostics | info / warning / error / fatal |
| `ProposerResult` | outcome enum + pair (only when proposed/needs_review) + transient diagnostics | **process only**; not serialized | terminal: proposed, needs_review, invalid_input, construction_failed |

### Invariants (cross-cutting)

- **Single approval authority:** only `ComponentContract.approval_status` records
  review state. The plan never gains draft/approved/rejected.
- **No second lifecycle artifact:** proposer process state is not persisted unless
  a future authority explicitly requires it (none today).
- **BINDING_LINK_AUTHORITY** remains `ComponentContract.BindingProjection` (D1).
  **Placement XOR** remains D3 `PUBLIC_TOP_LEVEL_PLACEMENT_RULE`.
- **Source independence:** semantic input must not encode Bricks/WordPress/Frames
  IDs, source CSS classes, editor labels, fixture paths, or adapter vocabulary as
  authoritative fields.

### Validation responsibility

| Layer | Function (implementation) | Proposer uses |
| --- | --- | --- |
| Design IR intrinsic | `LiveFrames.IR.validate/1` | gate before construction |
| Contract intrinsic | `ComponentContract.validate/1` | after construction |
| Contract IR refs | `ComponentContract.validate_ir_references/2` | after construction |
| Plan intrinsic | `ComponentizationPlan.validate/1` | after construction |
| Plan IR refs | `ComponentizationPlan.validate_references/3` | after construction |
| Generation gate | `ComponentContract.validate_for_generation/2`, `ComponentizationPlan.validate_for_generation/3` | **not** called as proposer success criterion; proposer never assumes approved |

---

## 5. Proposer responsibility boundary

The proposer **may**:

- copy authorized linkage fields from Design IR into `BindingProjection` /
  `RenderProjection` when explicit decisions name the public contract meaning;
- compute `design_document_sha256` from the supplied `DesignDocument`;
- assemble `CollectionInput` records from explicit collection admission decisions
  plus IR parent/child graph;
- set `contract_format_version` / `plan_format_version` to current `1.0.0`;
- set `approval_status` to `:proposed` or `:needs_review` only;
- append deterministic diagnostics to contract/plan diagnostic lists when the
  authority assigns ownership there;
- return transient `ProposerResult` diagnostics for input validation failures.

The proposer **must not**:

- infer `contract_id`, category, module/function intent, public names, boundary,
  defaults, accessibility policy, or render placement from IR/source metadata;
- emit `approval_status = :approved` or auto-emit `:rejected`;
- call `validate_for_generation` as a substitute for proposal validation;
- hide unresolved bindings behind `RenderProjection`;
- introduce Hero-specific templates or generic fallbacks (`title`, `content`,
  `items`, `component_1`, etc.);
- execute source code, load modules dynamically, or consult runtime services.

---

## 6. Explicit semantic decision input model

### 6.1 Artifact decision: no new serialized decision format

A separate versioned on-disk “decision document” is **not required** for C09D5.
Semantic decisions are supplied as a **compile-time input bundle**:

```text
SEMANTIC_INPUT_ARTIFACT_DECISION =
  ComponentizationSemanticInput is a source-independent compile-time input
  struct/map passed into the proposer API; it is NOT serialized, NOT versioned
  as a public compiler artifact, and NOT persisted by the proposer unless a
  caller chooses to store it outside LiveFrames artifact schemas.
```

If product later requires durable decision storage, that requires a **new
authority slice**; C09D5-B must not invent one silently.

### 6.2 Input bundle shape

`ComponentizationSemanticInput` contains typed decision records in caller-supplied
lists. Host-language map/list order is **not** authoritative. Before construction
the proposer **must** canonicalize every repeatable decision family per section
6.4 and emit artifact lists per section 6.5.

Closed first-wave decision record kinds:

| Record kind | Purpose |
| --- | --- |
| `ContractIdentityDecision` | `contract_id` (singleton) |
| `ClassificationDecision` | `category`, `module_intent`, `function_intent` (singleton) |
| `BoundaryDecision` | exactly one `boundary_node_id` **or** `multi_root_unsupported` (singleton; section 10) |
| `PublicAttrDecision` | complete `ComponentContract.Attr` semantics (section 6.3) |
| `PublicSlotDecision` | complete `ComponentContract.Slot` semantics (section 6.3) |
| `CollectionAdmissionDecision` | admit one IR `CollectionBinding` (section 6.3) |
| `ItemFieldDecision` | complete item-field semantics under a collection (section 6.3) |
| `CollectionCountLinkDecision` | link `count_attr_name` / `count_item_field_name` on `CollectionInput` (section 6.3) |
| `BindingAssignmentDecision` | assign one IR binding to one public member |
| `RenderPlacementDecision` | unbound public attr/slot → `target_node_id` + `render_role` |
| `ImageAccessibilityDecision` | closed D3 accessibility maps (section 13) |
| `EvidenceHandlingDecision` | closed handling for `evidence_insufficient` bindings (section 6.6) |
| `StaticContentDispositionDecision` | internal vs promoted static content (section 15) |

Per-record `provenance` on semantic decisions (section 6.3) is the only
first-wave input audit surface. There is no separate `InputProvenanceAudit`
record kind.

Forbidden fields on any decision record (reject input during semantic-input
validation):

```text
source_system, bricks_*, wp_*, frame_*, editor_label, source_path, source_class,
source_id as semantic authority, fixture_id, value_key as public name,
DesignNode id as contract_id, mechanical hashes of source identity as contract_id
```

Duplicate canonical identity keys within one family (section 6.4) → `invalid_input`
with `componentization_proposer.input.conflict`. Input order must not resolve
duplicates.

### 6.3 Decision record field schemas (required unless marked optional)

Semantic-input validation (step 2) **must** reject any record with missing
required fields, wrong types, or empty strings where non-empty is required.
The proposer **must not** rely on `ComponentContract` / `Slot` / `ItemField`
struct defaults for semantic fields.

#### `ContractIdentityDecision` (singleton)

| Field | Required | Type / constraint |
| --- | --- | --- |
| `contract_id` | yes | non-empty string; source-independent |

#### `ClassificationDecision` (singleton)

| Field | Required | Type / constraint |
| --- | --- | --- |
| `category` | yes | `primitive` \| `component` \| `pattern` \| `section` |
| `module_intent` | yes | non-empty string |
| `function_intent` | yes | non-empty string |

#### `BoundaryDecision` (singleton; XOR)

Exactly one mode:

| Mode | Fields |
| --- | --- |
| single boundary | `boundary_node_id` (non-empty Design IR node id string) |
| multi-root declared | `multi_root_unsupported` = `true` and **no** `boundary_node_id` |

`boundary_node_id` and `multi_root_unsupported: true` together → `invalid_input`.

#### `PublicAttrDecision`

Maps 1:1 to `ComponentContract.Attr` fields the proposer materializes:

| Field | Required | Notes |
| --- | --- | --- |
| `name` | yes | non-empty; unique among attrs |
| `type` | yes | closed Phoenix types per D1 |
| `required` | yes | boolean |
| `default` | yes | explicit term (use `nil` when no default) |
| `semantic_purpose` | yes | non-empty string (intrinsic validator) |
| `validation` | yes | JSON object (may be `%{}`) |
| `accessibility` | yes | JSON object (may be `%{}`; image **source** members per §6.3.1) |
| `provenance` | yes | JSON object audit (may be `%{}`) |

#### `PublicSlotDecision`

Maps 1:1 to `ComponentContract.Slot`:

| Field | Required | Notes |
| --- | --- | --- |
| `name` | yes | non-empty; unique among slots |
| `cardinality` | yes | first-wave only `"0..1"` unless later authority |
| `required` | yes | boolean |
| `semantic_purpose` | yes | non-empty string |
| `consumer_responsibility` | yes | non-empty string (intrinsic validator) |
| `validation` | yes | JSON object (may be `%{}`) |
| `accessibility` | yes | JSON object (may be `%{}`) |
| `provenance` | yes | JSON object audit (may be `%{}`) |

#### `CollectionAdmissionDecision`

| Field | Required | Notes |
| --- | --- | --- |
| `source_collection_binding_id` | yes | non-empty; unique per decision list |
| `public_attr_name` | top-level XOR | non-empty when root collection; `nil` when nested |
| `parent_collection_binding_id` | nested XOR | non-empty when nested; `nil` when top-level |
| `parent_item_field_name` | nested XOR | non-empty when nested; names existing `ItemFieldDecision.name` on parent collection with `type: :list` |
| `provenance` | yes | JSON object audit (may be `%{}`) |

Top-level vs nested location XOR matches D1 `COLLECTION_LOCATION_EXCLUSIVITY_RULE`.
`count_attr_name` / `count_item_field_name` are **not** set here; see
`CollectionCountLinkDecision`.

#### `ItemFieldDecision`

| Field | Required | Notes |
| --- | --- | --- |
| `source_collection_binding_id` | yes | owning collection binding id |
| `name` | yes | non-empty; unique per `(source_collection_binding_id, name)` |
| `type` | yes | closed Phoenix types |
| `required` | yes | boolean |
| `default` | yes | explicit term (`nil` allowed) |
| `semantic_purpose` | yes | non-empty string |
| `validation` | yes | JSON object |
| `accessibility` | yes | JSON object (image **source** item fields per §6.3.1) |
| `provenance` | yes | JSON object audit |

#### `CollectionCountLinkDecision`

Required when a visible count is part of the public API for a collection.

| Field | Required | Notes |
| --- | --- | --- |
| `source_collection_binding_id` | yes | collection owning the count |
| `count_public_name` | yes | non-empty; must equal an existing `PublicAttrDecision.name` (top-level) or `ItemFieldDecision.name` on the parent collection (nested) with `type: :integer` |
| `count_value_binding_id` | yes | non-empty `ValueBinding` id with `value_kind = collection_count` assigned via `BindingAssignmentDecision` |

Population rule:

```text
COLLECTION_COUNT_LINK_RULE =
  top-level CollectionAdmissionDecision (public_attr_name present):
    CollectionInput.count_attr_name = count_public_name
    CollectionInput.count_item_field_name = nil

  nested CollectionAdmissionDecision:
    CollectionInput.count_item_field_name = count_public_name
    CollectionInput.count_attr_name = nil

  when no count is part of the public API, omit CollectionCountLinkDecision;
  both count fields on CollectionInput remain nil
```

#### `BindingAssignmentDecision`

| Field | Required | Notes |
| --- | --- | --- |
| `source_binding_kind` | yes | `collection` \| `value` |
| `source_binding_id` | yes | non-empty |
| `assignment_kind` | yes | closed discriminant: `scalar_attr`, `collection_attr`, `collection_item_field_value`, `collection_item_field_nested_collection`, `collection_count_attr`, `collection_count_item_field`, `slot` |
| `public_attr_name` | per kind | when assignment targets top-level attr |
| `public_slot_name` | per kind | when assignment targets slot |
| `item_field_name` | per kind | when assignment targets ordinary item field |
| `parent_item_field_name` | per kind | when assignment targets nested collection list field |
| `source_collection_binding_id` | per kind | when required by D1 projection shape |

Must not reference `evidence_insufficient` bindings unless paired with
`EvidenceHandlingDecision` per section 6.6 (otherwise `invalid_input`).

#### `RenderPlacementDecision`

| Field | Required | Notes |
| --- | --- | --- |
| `public_target_kind` | yes | `attr` \| `slot` |
| `public_target_name` | yes | non-empty |
| `target_node_id` | yes | non-empty Design IR node id |
| `render_role` | yes | closed D3 enum |

#### `ImageAccessibilityDecision`

| Field | Required | Notes |
| --- | --- | --- |
| `target_kind` | yes | `attr` \| `item_field` |
| `target_name` | yes | public attr or item field name |
| `source_collection_binding_id` | item_field only | required when `target_kind = item_field` |
| `accessibility` | yes | exact D3 closed map; must match public-member decision per §6.3.1 |

#### 6.3.1 Image source members and accessibility authority (D3-aligned)

```text
IMAGE_SOURCE_MEMBER_RULE =
  a public attr or item field is an image SOURCE member only when explicit
  placement proves it (against the supplied DesignDocument during step 2):

  top-level attr:
    RenderPlacementDecision on that attr with render_role = asset_src
    OR BindingAssignmentDecision on that attr resolves to a ValueBinding with
      target_kind = asset and DesignNode.semantic_type = image at
      ValueBinding.target_node_id

  collection item field:
    BindingAssignmentDecision on that field resolves to a ValueBinding with
      value_kind = field, scope = collection_item, target_kind = asset, and
      DesignNode.semantic_type = image at ValueBinding.target_node_id
    (RenderProjection does not apply to item fields in plan 1.0.0)

  a non-empty accessibility map alone does NOT make a member an image source.
```

```text
IMAGE_ACCESSIBILITY_DECISION_CONSISTENCY_RULE =
  for every image SOURCE member (IMAGE_SOURCE_MEMBER_RULE):
    exactly one ImageAccessibilityDecision is required (identity per section 6.4)

    PublicAttrDecision.accessibility or ItemFieldDecision.accessibility must
    exactly equal ImageAccessibilityDecision.accessibility (deep term equality
    on the JSON object maps)

    mismatch -> invalid_input (componentization_proposer.input.conflict)
    missing ImageAccessibilityDecision -> invalid_input
    extra ImageAccessibilityDecision with no matching image source member ->
      invalid_input

  no precedence, no silent overwrite, no inference from accessibility maps

  the accessibility map must be one of the exact D3 closed policies
  (consumer_supplied or decorative per D3 §10.1 / §10.2)

  non-image public members may carry ordinary accessibility metadata without
  an ImageAccessibilityDecision
```

#### `StaticContentDispositionDecision`

| Field | Required | Notes |
| --- | --- | --- |
| `target_kind` | yes | `internal_node` \| `promote_attr` \| `promote_slot` |
| `design_node_id` | `internal_node` | node left as internal constant |
| `public_target_name` | promote_* | must match an existing attr/slot decision when promoting |

### 6.4 Canonical input ordering (pre-construction sort)

Sort each family by **UTF-8 byte order** (`<` on strings) unless noted.
After sorting, reject duplicate identity keys.

| Decision family | Canonical identity key (duplicate → `invalid_input`) | Sort key (ascending) |
| --- | --- | --- |
| `PublicAttrDecision` | `name` | `name` |
| `PublicSlotDecision` | `name` | `name` |
| `CollectionAdmissionDecision` | `source_collection_binding_id` | `source_collection_binding_id` |
| `ItemFieldDecision` | `{source_collection_binding_id, name}` | `source_collection_binding_id`, then `name` |
| `CollectionCountLinkDecision` | `source_collection_binding_id` | `source_collection_binding_id` |
| `BindingAssignmentDecision` | `{source_binding_kind, source_binding_id}` | `source_binding_kind` (`collection` before `value`), then `source_binding_id` |
| `RenderPlacementDecision` | `{public_target_kind, public_target_name}` | `public_target_kind` (`attr` before `slot`), then `public_target_name` |
| `ImageAccessibilityDecision` | attr: `{attr, name}`; item: `{item_field, source_collection_binding_id, name}` | `target_kind`, then `source_collection_binding_id` (empty for attr), then `target_name` |
| `EvidenceHandlingDecision` | `{source_binding_kind, source_binding_id}` | same as binding assignment |
| `StaticContentDispositionDecision` | `target_kind` + (`design_node_id` or `public_target_name`) | `target_kind`, then node or public name |

Singleton records (`ContractIdentityDecision`, `ClassificationDecision`,
`BoundaryDecision`) have no list ordering.

### 6.5 Canonical output ordering (serialized artifact lists)

After construction, lists on artifacts **must** appear in this order before
serialization so value-equivalent inputs produce byte-identical
`ComponentContract` / `ComponentizationPlan` JSON:

| Artifact field | Sort key (ascending) |
| --- | --- |
| `public_attrs` | `Attr.name` |
| `public_slots` | `Slot.name` |
| `collection_inputs` | `source_collection_binding_id` |
| each `CollectionInput.item_fields` | `ItemField.name` |
| `binding_projections` | `source_binding_kind` (`collection` before `value`), `source_binding_id`, `projection_kind` (enum order: `scalar_attr`, `collection_attr`, `collection_item_field`, `collection_count_attr`, `slot`), then `public_attr_name`, `public_slot_name`, `item_field_name`, `parent_item_field_name` (empty last) |
| `render_projections` | `public_attr_name` if present else `public_slot_name` (exactly one) |
| `diagnostics` (contract and plan) | `code`, then `path` (empty last), then `message` |

`ComponentContract` / `ComponentizationPlan` serializers already preserve list
order; the proposer must emit sorted lists.

### 6.6 `EvidenceHandlingDecision` (frozen first wave)

Applies only when the referenced IR `ValueBinding` has
`normalization_status = evidence_insufficient` (verified against the supplied
`DesignDocument` during semantic-input validation).

#### Decision shape

| Field | Required |
| --- | --- |
| `source_binding_kind` | yes; must be `value` |
| `source_binding_id` | yes; non-empty |
| `outcome` | yes; closed enum below |

#### Closed outcomes (only these)

D1 allows reviewer resolve / exclude / reject / waiver, but does **not** define a
machine-level waiver or “ordinary projection while insufficient” encoding for
the proposer. C09D5 first wave therefore admits **one** construction outcome:

```text
outcome = omit_public_projection
```

| Effect | Value |
| --- | --- |
| `BindingProjection` emitted? | **no** |
| `BindingAssignmentDecision` allowed for same binding? | **no** — if present → `invalid_input` (`componentization_proposer.input.conflict`) |
| Public attr/slot/item field from that binding? | **no** — public members come only from explicit `Public*` / `ItemField` decisions, not from this binding |
| Contract diagnostic stored | yes — `component_contract.binding_evidence_insufficient` severity `error` on `contract.diagnostics` when a contract is returned |
| Plan diagnostic | when binding is in-boundary: `componentization_plan.binding.uncovered` and/or `componentization_plan.binding.evidence_insufficient` from reference validation |
| Contract `provenance` audit | append-only map entry under `provenance["evidence_handling"]` keyed by `source_binding_id` with `%{"outcome" => "omit_public_projection"}` (inert JSON) |
| `approval_status` / `ProposerResult` | always `needs_review` when a pair is returned; **never** `:proposed` for this binding |
| Ordinary approved projection? | **forbidden** — proposer must not emit `BindingProjection` for this binding in C09D5 first wave |

```text
EVIDENCE_INSUFFICIENT_PROJECTION_RULE =
  evidence_insufficient ValueBinding -> BindingProjection forbidden unless IR
  normalization_status changes to normalized in a future document version;
  EvidenceHandlingDecision does not authorize ordinary projection
```

#### Missing / invalid handling

| Situation | ProposerResult |
| --- | --- |
| in-boundary `evidence_insufficient` binding, no `EvidenceHandlingDecision` and no `BindingAssignmentDecision` | `needs_review` (pair allowed); reference diagnostics as above |
| `BindingAssignmentDecision` for `evidence_insufficient` binding without matching `EvidenceHandlingDecision` | `invalid_input` |
| `EvidenceHandlingDecision` for binding that is not `evidence_insufficient` | `invalid_input` |
| `EvidenceHandlingDecision` with outcome other than `omit_public_projection` | `invalid_input` |
| `EvidenceHandlingDecision` + `BindingAssignmentDecision` same binding | `invalid_input` |

Reviewer-side D1 outcomes (`resolve`, `reject`, `waiver`) that change
approval or ordinary projection while IR remains `evidence_insufficient` are
**out of scope** for the proposer; defer richer encodings to later authority.
C09D5-B must not invent them.

### 6.7 What counts as an explicit semantic decision

A value is an **explicit semantic decision** when:

1. it appears in a typed decision record in `ComponentizationSemanticInput`, and
2. it is required by D1/D3 for that field and cannot be computed from IR alone
   without semantic judgment, and
3. it is source-independent per section 6.2.

Examples of **explicit** decisions: `contract_id`, `category`, `module_intent`,
`function_intent`, `boundary_node_id`, each `PublicAttrDecision.name`, each
`BindingAssignmentDecision` pairing binding → public member, each
`RenderPlacementDecision`, each `ImageAccessibilityDecision`, each
`CollectionAdmissionDecision` public name, each `ItemFieldDecision`, each
`EvidenceHandlingDecision`.

Examples of **authorized mechanical derivation** (not decisions): `target_node_id`
on `BindingProjection` from referenced `ValueBinding` / `CollectionBinding`;
`design_document_sha256`; projection_kind from binding kind + assignment kind;
`source_collection_binding_id` on projections when assignment references a
collection; canonical child `parent_collection_binding_id` from IR.

### 6.8 Missing decisions

```text
MISSING_SEMANTIC_DECISION_RULE =
  the proposer MUST NOT synthesize missing semantic decisions from IR, source
  metadata, map order, or struct defaults.

SEMANTIC_INPUT_COMPLETENESS_RULE =
  any missing required field on a decision record (section 6.3), missing
  singleton decision, or duplicate identity key (section 6.4) is rejected during
  semantic-input validation as invalid_input with no candidate pair.

  needs_review is reserved for a fully input-valid, intrinsically valid contract
  and plan pair that still has reference/coverage/accessibility or policy
  blockers (section 16).
```

---

## 7. Decision versus derivation matrix

Legend (aligned with section 16 outcome taxonomy):

- **Explicit?** — must appear in semantic input (yes/no/partial).
- **Derived?** — proposer may compute when explicit assignment exists.
- **Missing** — `invalid_input` (I), `needs_review` (R), or N/A.
- **Invalid** — `invalid_input` (I). Intrinsic artifact failure after valid input
  is `construction_failed` (implementer defect; section 16.6).

| Field / relationship | Owning artifact | Explicit? | May derive? | Authoritative derivation source | Forbidden inference | Missing | Invalid |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `contract_id` | Contract | yes | no | — | hash of source/node/path/labels | I | I |
| `category` | Contract | yes | no | — | semantic_type, depth, editor name | I | I |
| `module_intent` | Contract | yes | no | — | source module names | I | I |
| `function_intent` | Contract | yes | no | — | DOM tag, component name | I | I |
| public attr `name` | Contract | yes | no | — | value_key, label, class | I | I |
| public attr `type` | Contract | yes | no | — | source string type | I | I |
| required / default | Contract | yes | no | — | fixture literal | I | I |
| `semantic_purpose` (attr/slot/field) | Contract | yes | no | — | auto prose from IR | I | I |
| `validation` | Contract | yes | yes | copy from decision record | IR attributes alone | I | I |
| `consumer_responsibility` (slot) | Contract | yes | no | — | — | I | I |
| `accessibility` (image) | Contract Attr / ItemField | yes | no | — | nil alt, source HTML, filename | I** | I |
| attr/slot/field `provenance` | Contract | yes | audit | decision `provenance` field | executable prose | I | I |
| public slot `name` / cardinality | Contract | yes | no | — | child order, repeat count | I | I |
| `CollectionInput` location | Contract | yes | partial | IR parent ids after names chosen | auto `items` name | I | I |
| `count_attr_name` / `count_item_field_name` | Contract | yes | yes | `CollectionCountLinkDecision` | infer `count` name | I | I |
| `ItemField` full shape | Contract | yes | no | — | value_key, struct defaults | I | I |
| nested collection parent field | Contract | yes | partial | IR parent binding id | flatten to top-level | I | I |
| `BindingProjection` rows | Contract | partial | yes | IR + `BindingAssignmentDecision` | unassigned in-boundary binding | R (uncovered) | I |
| `evidence_insufficient` handling | Contract | yes | no | `EvidenceHandlingDecision` §6.6 | ordinary projection | R | I |
| `boundary_node_id` | Plan | yes | no | — | first root, largest subtree | I | I |
| `multi_root_unsupported` | — | yes | no | — | invented boundary id | I (no pair) | I |
| `design_document_sha256` | Plan | no | yes | `ComponentizationPlan.design_document_sha256/1` | manual hash | I* | I* |
| `RenderProjection` | Plan | yes | partial | `RenderPlacementDecision` only | name→node | I | I |
| `contract approval_status` | Contract | no | yes | outcome rules §16 | auto approved | N/A | I if approved |
| contract/plan diagnostics | both | partial | generated | validators + §6.6 | — | — | — |
| plan `contract_id` link | Plan | partial | yes | contract `contract_id` | — | I | I |
| provenance (both) | both | audit | copy | decision audit + IR ids | override structured fields | N/A | I |

\* `design_document_sha256` missing on plan is proposer materialization failure;
IR invalid is caught at step 1 (`invalid_input`).

Image-source and accessibility input rules: section 6.3.1. Reference-layer
accessibility mismatches on an otherwise input-valid pair → `needs_review`.

---

## 8. Proposal construction algorithm

Deterministic ordering:

```text
1. LiveFrames.IR.validate(design_document) -> invalid => invalid_input, no pair
2. validate ComponentizationSemanticInput (sections 6.3, 6.3.1, 6.4, 6.6)
     against design_document -> invalid => invalid_input, no pair
3. canonicalize decision lists (section 6.4)
4. build ComponentContract with approval_status = :proposed (provisional only;
     PROPOSER_PROVISIONAL_APPROVAL_STATUS_RULE)
5. materialize PublicAttrDecision / PublicSlotDecision / ItemFieldDecision /
     CollectionAdmissionDecision into contract lists (no IR inference)
6. materialize BindingProjection from BindingAssignmentDecision + IR registries
7. materialize CollectionInput from CollectionAdmissionDecision +
     CollectionCountLinkDecision + IR
8. sort contract lists (section 6.5)
9. compute design_document_sha256
10. build ComponentizationPlan (boundary_node_id from BoundaryDecision)
11. sort plan lists (section 6.5)
12. ComponentContract.validate/1 -> {:error, _} => construction_failed, no pair,
     transient construction diagnostics only
13. ComponentizationPlan.validate/1 -> {:error, _} => construction_failed, no pair
14. ComponentContract.validate_ir_references/2 (generated diagnostics)
15. ComponentizationPlan.validate_references/3 (generated diagnostics)
16. classify ProposerResult outcome and final approval_status (section 16)
17. merge only diagnostics owned by returned artifacts (section 18); canonical
     sort diagnostics (section 6.5)
18. ComponentContract.validate/1 and ComponentizationPlan.validate/1 again on the
     returned pair (PROPOSER_FINAL_INTRINSIC_VALIDATE_RULE); failure =>
     construction_failed, no pair
19. STOP — no approval transition, no generation
```

```text
PROPOSER_PROVISIONAL_APPROVAL_STATUS_RULE =
  materialize ComponentContract with approval_status = :proposed before step 12
  so intrinsic validation has a closed enum value; replace with final
  :proposed | :needs_review only at step 16; never :approved | :rejected

PROPOSER_FINAL_INTRINSIC_VALIDATE_RULE =
  after diagnostic merge (step 17), re-run intrinsic validation on the returned
  pair; if either fails, construction_failed with no pair (proposer defect)
```

The proposer does **not** reimplement validation rules; it calls existing
validators.

---

## 9. Contract construction rules

- **Identity:** `contract_id` only from `ContractIdentityDecision`. Non-empty,
  stable, source-independent string (D1).
- **Classification:** only from `ClassificationDecision`; closed category enum
  (D1 `COMPONENT_CATEGORY_MODEL`).
- **Public members:** only from `PublicAttrDecision` / `PublicSlotDecision`;
  unique names; no attr/slot name collision.
- **Collections:** each admitted `CollectionBinding` yields exactly one
  `CollectionInput` via `CollectionAdmissionDecision`; location XOR and graph
  rules per D1.
- **Item fields:** only from `ItemFieldDecision` scoped to a collection binding
  id; nested collections require explicit parent item field name of type `:list`.
- **Binding projections:** only for explicit `BindingAssignmentDecision`; shape
  per D1 §12; `target_node_id` copied from IR binding (VALUE/COLLECTION target
  rules).
- **Defaults:** only when `PublicAttrDecision` / `ItemFieldDecision` explicitly
  sets `default` satisfying D1 `STATIC_DEFAULT_RULE`.
- **Provenance:** may record reviewer audit and IR binding ids; must not
  redefine projections.
- **Collection counts:** `CollectionCountLinkDecision` populates
  `count_attr_name` / `count_item_field_name` per `COLLECTION_COUNT_LINK_RULE`.
- **Provisional approval_status:** `:proposed` during steps 4–15 per
  `PROPOSER_PROVISIONAL_APPROVAL_STATUS_RULE`.
- **Final approval_status:** set at step 16 only; `:proposed` or `:needs_review`;
  never `:approved` / auto `:rejected`.
- **Image accessibility:** copy `accessibility` from `PublicAttrDecision` /
  `ItemFieldDecision` (already equal to `ImageAccessibilityDecision` per §6.3.1).

---

## 10. Plan construction rules

- **Fingerprint:** always computed from the same `DesignDocument` passed to the
  proposer; stored on plan.
- **contract_id:** must equal contract’s `contract_id`.
- **boundary_node_id:** only from `BoundaryDecision.boundary_node_id` (single-root
  mode). See `MULTI_ROOT_PROPOSER_RULE` below; no placeholder or sentinel node id.

```text
MULTI_ROOT_PROPOSER_RULE =
  BoundaryDecision.multi_root_unsupported = true ->
    ProposerResult = invalid_input
    componentization_proposer.input.multi_root_unsupported (transient)
    no ComponentContract, no ComponentizationPlan returned
    caller must supply exactly one boundary_node_id to obtain a plan (D3 plan 1.0.0)
```
- **RenderProjection:** one per `RenderPlacementDecision`; public target must
  exist on contract; closed `render_role` enum (D3).
- **No duplication:** omit `RenderProjection` for public targets already covered
  by `BindingProjection` (`BINDING_RENDER_DUPLICATION_RULE`).
- **Diagnostics:** plan-owned codes only for placement, boundary, coverage, and
  accessibility validation findings (D3 §14.1).

---

## 11. BindingProjection construction

### 11.1 When the proposer may create a projection

Only when **both**:

1. a `BindingAssignmentDecision` names the public member and binding id/kind, and
2. IR reference validation can resolve the binding and target node.

### 11.2 Mechanical fields (authorized)

From IR after assignment exists:

```text
source_binding_kind, source_binding_id, target_node_id
source_collection_binding_id, parent_collection_binding_id (per projection kind)
projection_kind (from assignment discriminant + binding shape per D1)
public_attr_name | public_slot_name | item_field_name | parent_item_field_name
```

### 11.3 Cases (first wave)

| Case | Assignment explicit | Projection kind |
| --- | --- | --- |
| site scalar field | yes | `scalar_attr` |
| root collection | yes | `collection_attr` |
| collection item field | yes | `collection_item_field` (value) |
| nested collection | yes | `collection_item_field` (collection) |
| top-level count | yes | `collection_count_attr` |
| nested count | yes | `collection_item_field` + count field link |
| binding-backed slot | yes | `slot` (plan: `BINDING_BACKED_SLOT_PLAN_RULE`) |

### 11.4 Forbidden

- projecting bindings without assignment;
- slot projection for `collection_item` value bindings;
- using `RenderProjection` to cover the same public target;
- any `BindingProjection` for a `ValueBinding` with
  `normalization_status = evidence_insufficient` (section 6.6).
- `BindingAssignmentDecision` paired with `evidence_insufficient` binding without
  matching `EvidenceHandlingDecision.outcome = omit_public_projection` and without
  assignment (assignments are forbidden for that binding).

---

## 12. RenderProjection construction

Only from `RenderPlacementDecision` for public attrs/slots **without**
`BindingAssignmentDecision` on that target.

- Closed roles: D3 `RENDER_ROLE_ENUM`.
- `target_node_id` must be explicit in the decision (not inferred from labels).
- Root roles (`root_id`, `root_class`, `root_global_attrs`) only on
  `boundary_node_id`.
- `subtree_slot` requires explicit slot decision + placement; enforce
  `SUBTREE_SLOT_OWNERSHIP_RULE` at reference validation.
- No collection-item `RenderProjection` in plan 1.0.0.

---

## 13. Accessibility

- Image **source** membership: `IMAGE_SOURCE_MEMBER_RULE` (§6.3.1) only; not
  inferred from non-empty `accessibility` maps.
- Input consistency: `IMAGE_ACCESSIBILITY_DECISION_CONSISTENCY_RULE` (§6.3.1).
- Proposer **must not** infer decorative/informative/alt from nil, source alt,
  or provenance prose.
- Reference validation enforces D3 `IMAGE_ACCESSIBILITY_VALIDATION_RULE` on
  constructed pairs; failures → `needs_review` when intrinsic validation still
  passes.

---

## 14. Collections and nesting

- Admitting a collection requires `CollectionAdmissionDecision` with explicit
  public `:list` name (top-level) or `parent_item_field_name` (nested).
- IR proves parent/child edges; proposer does not invent parentage.
- Boundary-crossing collections → plan `boundary.binding_crosses` → `needs_review`.
- Nested collection without represented parent admission → `invalid_input` when
  parent admission or parent item field decision is missing; `invalid_input`
  when decisions contradict IR parent graph.
- Count attrs/fields require `CollectionCountLinkDecision`, matching integer
  `PublicAttrDecision` / `ItemFieldDecision`, and `BindingAssignmentDecision`
  for the `collection_count` value binding; no `length(items)` inference.

---

## 15. Static content and internal constants

Per D3 `STATIC_CONTENT_PROMOTION_RULE`, `STATIC_DEFAULT_RULE`,
`INTERNAL_CONSTANT_RULE`, `STATIC_INTERNAL_IMAGE_RULE`:

- Source literals do not become public attrs/slots without `PublicAttrDecision` /
  `PublicSlotDecision` or promotion via explicit disposition.
- `StaticContentDispositionDecision = internal` leaves IR content as internal
  generated constants; no fake attr.
- Static internal images without public asset placement block generation;
  proposer outcome `needs_review` with `STATIC_INTERNAL_IMAGE_RULE` diagnostics.
- Explicit `default` in decisions must not copy fixture literals unless the
  decision record explicitly sets that default as reusable semantics.

---

## 16. Proposal outcome and approval rules

### 16.1 Outcome taxonomy (single authority)

```text
PROPOSER_OUTCOME_TAXONOMY =
  invalid_input
    -> semantic-input validation (step 2) or MULTI_ROOT_PROPOSER_RULE or step 1 IR invalid
    -> no ComponentContract / ComponentizationPlan pair

  construction_failed
    -> semantic input valid, but intrinsic validation fails at step 12–13 or 18
    -> no ComponentContract / ComponentizationPlan pair returned
    -> transient construction diagnostics only; never copy onto artifacts
    -> MUST NOT occur when semantic-input validation mirrors section 6.3 and the
       proposer is correct; indicates implementation defect

  needs_review
    -> intrinsically valid pair returned (steps 12–13 and 18 pass)
    -> final approval_status = needs_review
    -> reference/coverage/accessibility/policy blockers per section 16.4

  proposed
    -> intrinsically and reference-valid pair returned
    -> final approval_status = proposed
```

```text
PROPOSER_RESULT_PAIR_RULE =
  invalid_input -> contract = nil, plan = nil, input_diagnostics only
  construction_failed -> contract = nil, plan = nil, construction_diagnostics only
  needs_review -> contract != nil, plan != nil, both intrinsically valid
  proposed -> contract != nil, plan != nil, both intrinsically valid
```

Malformed decision shape, missing required decision fields, forbidden fields,
duplicate identity keys, contradictory assignments, and invalid
`EvidenceHandlingDecision` pairings are **`invalid_input`**, not
`needs_review` and not `construction_failed`.

### 16.2 Outcome classes (summary)

| ProposerResult outcome | Meaning |
| --- | --- |
| `:invalid_input` | steps 1–2 or multi-root rule; **no pair** (§16.8) |
| `:construction_failed` | steps 12–13 or 18 intrinsic failure; **no pair** |
| `:needs_review` | pair returned; final `approval_status = needs_review` |
| `:proposed` | pair returned; final `approval_status = proposed` |

Ordinary semantic ambiguity uses `:needs_review`, not exceptions.

### 16.3 `approval_status` mapping

```text
PROPOSER_APPROVAL_RULE (restated) =
  proposer may set approval_status to proposed or needs_review only;
  proposer NEVER sets approved;
  proposer MUST NOT set rejected as an automatic semantic judgment.

PROPOSER_APPROVAL_CLASSIFICATION_RULE =
  approval_status = proposed ONLY WHEN:
    ComponentContract.validate/1 = :ok
    AND ComponentizationPlan.validate/1 = :ok
    AND ComponentContract.validate_ir_references/2 = :ok
    AND ComponentizationPlan.validate_references/3 = :ok
    AND no generated or stored contract/plan diagnostic with severity error or fatal
    AND no mandatory semantic review trigger in section 16.4

  OTHERWISE final approval_status = needs_review (pair returned per
  PROPOSER_RESULT_PAIR_RULE)
```

Do **not** call `validate_for_generation` during proposal classification.

### 16.4 Mandatory `needs_review` triggers (pair must be intrinsic-valid)

```text
any blocking diagnostic from steps 13–14 (reference validation)
in-boundary evidence_insufficient binding (with or without
  EvidenceHandlingDecision omit_public_projection) — never :proposed
BINDING_BACKED_SLOT_PLAN_RULE
STATIC_COLLECTION_ITEM_RULE
UNSUPPORTED_NODE_RULE inside boundary
STATIC_INTERNAL_IMAGE_RULE
```

`MULTI_ROOT_PROPOSER_RULE` and missing required decision fields are
`invalid_input`, not listed here.

### 16.5 Blocking diagnostics vs `approval_status`

```text
PROPOSER_DIAGNOSTIC_APPROVAL_RULE =
  error or fatal diagnostics on the contract or plan (stored or generated in the
  proposer pass) force approval_status = needs_review when a pair is returned.
  info and warning alone do not force needs_review if all validations pass and
  section 16.4 triggers are absent.
```

### 16.6 `needs_review` vs malformed data

| Situation | Outcome |
| --- | --- |
| Wrong types / forbidden source fields in semantic input | `invalid_input` |
| Missing singleton or required decision field (section 6.3) | `invalid_input` |
| Missing `semantic_purpose` / `consumer_responsibility` on decision record | `invalid_input` |
| Duplicate decision identity keys | `invalid_input` |
| Conflicting assignments / evidence handling | `invalid_input` |
| Decisions reference missing IR binding/node | `invalid_input` |
| `multi_root_unsupported` | `invalid_input` (no pair) |
| Constructed contract/plan fail intrinsic validation (steps 12–13 or 18) | `construction_failed` (no pair) |
| ImageAccessibilityDecision / public-member accessibility mismatch | `invalid_input` |
| Intrinsic-valid pair; reference/coverage/accessibility failures | `needs_review` |
| Intrinsic-valid pair; all pass; no triggers | `proposed` |

### 16.7 Semantic-input validation vs artifact intrinsic validation

```text
SEMANTIC_INPUT_VALIDATION_RULE =
  step 2 validates every section 6.3 record, section 6.3.1 image-source and
  accessibility consistency, section 6.4 uniqueness, section 6.6 evidence rules,
  and forbidden fields (using the supplied DesignDocument). Failures are
  invalid_input only.

ARTIFACT_INTRINSIC_RULE =
  steps 12–13 and 18 assume materialized fields satisfy intrinsic validators.
  When semantic-input validation mirrors section 6.3, steps 12–13 succeed;
  failure at 12–13 or 18 is construction_failed with no pair (proposer bug).

### 16.8 `ProposerResult` fields (frozen API)

| Field | `invalid_input` | `construction_failed` | `needs_review` | `proposed` |
| --- | --- | --- | --- | --- |
| `contract` | `nil` | `nil` | non-nil | non-nil |
| `plan` | `nil` | `nil` | non-nil | non-nil |
| `input_diagnostics` | non-empty allowed | empty | empty | empty |
| `construction_diagnostics` | empty | non-empty allowed | empty | empty |
| `outcome` | atom above | atom above | atom above | atom above |

Persisted contract/plan diagnostics: only for `needs_review` and `proposed`,
merged deterministically at step 17, never for failure outcomes.

---

## 17. Process lifecycle, guards, and terminal states

### 17.1 Before construction

State: caller holds `DesignDocument` + `ComponentizationSemanticInput`.

Guards:

```text
G1  DesignDocument passes LiveFrames.IR.validate/1
G2  Semantic input passes intrinsic validation
G3  design_document value is the sole IR authority for reference checks
```

### 17.2 Construction and validation

No hidden transitions. Side effects: none beyond returned structs and
diagnostics (pure compile-time).

### 17.3 Terminal proposer outcomes

All proposer paths end in exactly one of:

```text
invalid_input | construction_failed | needs_review | proposed
```

### 17.4 After proposer STOP

Only a human/reviewer or authorized review tooling may set
`approval_status` to `approved` or `rejected`. ConversionJob pipeline states
remain D1 (`COMPONENTIZING` gate).

```text
REVIEWER_APPROVAL_AUTHORITY =
  only reviewers set approval_status approved or rejected;
  proposer output is never generation-eligible.
```

---

## 18. Diagnostics and provenance ownership

| Finding source | Owner | Persisted on |
| --- | --- | --- |
| Input shape / forbidden field | `ProposerResult.input_diagnostics` | never on artifacts |
| Intrinsic failure (steps 12–13, 18) | `ProposerResult.construction_diagnostics` | never on artifacts |
| IR reference / policy blockers | `ComponentContract.Diagnostic` / `ComponentizationPlan.Diagnostic` | `contract.diagnostics` / `plan.diagnostics` only when pair returned (`needs_review` or `proposed`) |
| Evidence omit (§6.6) | contract + plan codes | contract/plan when pair returned |

```text
PROPOSER_DIAGNOSTIC_PERSISTENCE_RULE =
  invalid_input and construction_failed never attach diagnostics to contract or
  plan structs because no pair is returned; determinism requires a single
  canonical merge at step 17 for successful pair outcomes only
```

No third serialized diagnostic artifact. Provenance remains audit-only;
structured fields on contract/plan/decisions win on conflict.

Transient proposer codes (never stored on artifacts):

```text
componentization_proposer.input.invalid
componentization_proposer.input.conflict
componentization_proposer.input.missing_decision
componentization_proposer.input.multi_root_unsupported
componentization_proposer.construction.failed
```

---

## 19. Validation ordering

Exact order (matches §8):

```text
1. LiveFrames.IR.validate/1
2. semantic input validate (sections 6.3, 6.3.1, 6.4, 6.6) with DesignDocument
3–11. construct contract (provisional :proposed) + plan per §8
12–13. intrinsic validate; failure → construction_failed, no pair
14–15. reference validate (diagnostics generated, not yet merged)
16. classify outcome and final approval_status
17. merge + sort diagnostics on returned pair only
18. final intrinsic validate; failure → construction_failed, no pair
```

**Never** invoke `ComponentContract.validate_for_generation/2` or
`ComponentizationPlan.validate_for_generation/3` as part of proposal success.

Failures in steps 12–13 or 18 → `construction_failed`, no pair (§16.8). Failures
in steps 14–15 with passing intrinsic → `needs_review` pair (unless steps 1–2
already returned `invalid_input`).

---

## 20. Determinism, security, complexity

### 20.1 Purity

Same as D1/D3:

```text
no DB, Redis, ETS, Cachex, GenServer, Oban, PubSub, HTTP, clock, randomness
no String.to_atom, Code.eval*, dynamic apply from untrusted data, MFA callbacks
```

### 20.2 Determinism

```text
PROPOSER_DETERMINISM_RULE =
  identical DesignDocument, ComponentizationSemanticInput (value-equal decisions
  under section 6.4 canonicalization), and authority version -> identical contract, plan,
  diagnostics, and approval_status classification.
```

### 20.3 Complexity

Build IR and contract indexes once:

```text
O(IR nodes + IR bindings + semantic decisions + contract records + plan records)
```

Do not scan the full IR tree per decision.

---

## 21. Failure-mode matrix

| Condition | invalid_input | needs_review | Diagnostic | Owner |
| --- | --- | --- | --- | --- |
| missing boundary decision | yes | | `componentization_proposer.input.missing_decision` | transient |
| missing category / identity | yes | | same | transient |
| missing semantic public name | yes | | `componentization_proposer.input.missing_decision` | transient |
| duplicate public names in input | yes | | `componentization_proposer.input.conflict` | transient |
| contract_id conflicting duplicates | yes | | same | transient |
| decision references missing node | yes | | `componentization_proposer.input.invalid` | transient |
| decision references missing binding | yes | | same | transient |
| wrong binding kind in assignment | yes | | same | transient |
| one binding, multiple public members | yes | | same | transient |
| public member both binding + render decision | yes | | same | transient |
| uncovered in-boundary binding | | yes | `componentization_plan.binding.uncovered` | plan |
| evidence_insufficient in-boundary (omit_public_projection or absent handling) | | yes | `component_contract.binding_evidence_insufficient` + plan binding codes | both |
| BindingAssignment on evidence_insufficient binding | yes | | `componentization_proposer.input.conflict` | transient |
| unsupported/raw/unknown node in boundary | | yes | `componentization_plan.unsupported_node` | plan |
| boundary-crossing collection | | yes | `componentization_plan.boundary.binding_crosses` | plan |
| nested collection parent missing | yes | | input / construction | transient |
| static internal image | | yes | STATIC_INTERNAL_IMAGE (plan) | plan |
| image source missing ImageAccessibilityDecision at input | yes | | `componentization_proposer.input.missing_decision` | transient |
| image accessibility map mismatch (decision vs attr/field) | yes | | `componentization_proposer.input.conflict` | transient |
| image policy invalid at reference validation | | yes | `componentization_plan.accessibility.*` | plan |
| consumer alt target mismatch | | yes | alt mismatch codes | plan |
| binding-backed slot | | yes | `componentization_plan.slot.binding_backed_unsupported` | plan |
| subtree slot hides bindings | | yes | `componentization_plan.slot.subtree_conflict` | plan |
| role/type or role/node mismatch | | yes | render_projection.* | plan |
| role co-location conflict | | yes | `render_projection.role_conflict` | plan |
| multi-root boundary flag (`multi_root_unsupported`) | yes | | `componentization_proposer.input.multi_root_unsupported` | transient |
| missing required field on decision record (e.g. semantic_purpose) | yes | | `componentization_proposer.input.missing_decision` | transient |
| conflicting explicit decisions | yes | | input conflict | transient |
| stale decisions vs changed IR | yes* | | *invalid if node/binding ids no longer resolve | transient |
| same decisions, different map order | no | | — | deterministic output |

---

## 22. Hero and P6.1 evidence (non-template)

Hero proves **examples** of explicit decisions: `section` category,
`Sections.Hero`-style module intent, semantic attrs (`heading`, `lede`,
`image_src`, `image_alt`), heading level validation, consumer action slots,
`class`/`rest`/`id` extension concepts.

Hero does **not** authorize:

```text
automatic Hero classification for all sections
shared hero API for every design
automatic extraction of primary_action / secondary_action
automatic image policy
automatic module/function naming from file paths
```

Generalization is via decision records, not special cases.

---

## 23. Review challenge (design resolution)

| Challenge | Resolution |
| --- | --- |
| Derived field is semantic judgment? | Only IR linkage fields are derived; names, category, boundary, policy are decisions. |
| Source-adapter-specific proposer? | Forbidden fields on input; no Bricks/WP vocabulary. |
| Missing decision → fallback? | `MISSING_SEMANTIC_DECISION_RULE`; no generic names. |
| Two decision sets → same identity? | `contract_id` is explicit; distinct inputs must not collide on identity intentionally. |
| Map ordering alters output? | Section 6.4 input sort + section 6.5 output sort. |
| Bypass D1/D3 validation? | Proposer calls existing validators; no duplicate weakened rules. |
| `needs_review` vs malformed? | §16.1 taxonomy and §16.6 table. |
| Accidental `approved`? | `PROPOSER_APPROVAL_RULE`; provisional `:proposed` only until step 16. |
| Duplicate artifact? | No serialized proposal wrapper; pair only. |
| New serialized decision artifact? | Not required; compile-time input only. |
| Collection/accessibility edge cases? | §13–14, D3 §10, failure matrix. |
| Approximately linear? | §8 algorithm + O() bound §20.3. |

---

## 24. Decision register (frozen rules)

```text
SEMANTIC_INPUT_ARTIFACT_DECISION = compile-time ComponentizationSemanticInput only;
  no versioned serialized decision artifact in C09D5 first wave

MISSING_SEMANTIC_DECISION_RULE = no fill-in; §6.8

SEMANTIC_INPUT_COMPLETENESS_RULE = §6.8 / §16.7

SEMANTIC_INPUT_VALIDATION_RULE = §16.7

PROPOSER_OUTCOME_TAXONOMY = §16.1

CANONICAL_INPUT_ORDER_RULE = §6.4

CANONICAL_OUTPUT_ORDER_RULE = §6.5

COLLECTION_COUNT_LINK_RULE = §6.3 CollectionCountLinkDecision

EVIDENCE_INSUFFICIENT_PROJECTION_RULE = §6.6

EVIDENCE_HANDLING_OUTCOME_OMIT_PUBLIC_PROJECTION = only closed outcome in C09D5
  first wave; no ordinary projection; see §6.6

MULTI_ROOT_PROPOSER_RULE = §10

SEMANTIC_INPUT_CONTRACT_ID_RULE = contract_id supplied only by
  ContractIdentityDecision; no hashing of source or node ids

PUBLIC_NAMING_RULE = restated from D1/D3; no mechanical fallback names

CLASSIFICATION_RULE = restated from D1/D3; explicit category only

PROPOSER_BOUNDARY_RULE = boundary_node_id explicit; MULTI_ROOT_BOUNDARY_RULE;
  no inference from first root, size, semantic_type, editor name

PROPOSER_BINDING_PROJECTION_RULE = BindingAssignmentDecision required before
  emitting BindingProjection; mechanical IR linkage only

PROPOSER_RENDER_PROJECTION_RULE = RenderPlacementDecision required for unbound
  public members; BINDING_RENDER_DUPLICATION_RULE preserved

PROPOSER_APPROVAL_RULE = proposed | needs_review only; never approved

PROPOSER_REJECTED_STATUS_RULE = proposer never auto-sets rejected

PROPOSER_APPROVAL_CLASSIFICATION_RULE = §16.3

PROPOSER_DIAGNOSTIC_APPROVAL_RULE = §16.5

PROPOSER_VALIDATION_ORDER_RULE = §19

PROPOSER_GENERATION_GATE_SEPARATION = validate_for_generation not used in proposal

PROPOSER_DETERMINISM_RULE = §20.2

PROPOSER_INDEX_ONCE_RULE = §20.3

EVIDENCE_HANDLING_INPUT_RULE = §6.6; assignment + evidence_insufficient ->
  invalid_input; omit_public_projection -> needs_review when pair returned

STATIC_PROMOTION_INPUT_RULE = promotion requires Public*Decision or explicit
  disposition; STATIC_DEFAULT_RULE preserved

IMAGE_SOURCE_MEMBER_RULE = §6.3.1

IMAGE_ACCESSIBILITY_DECISION_CONSISTENCY_RULE = §6.3.1

IMAGE_ACCESSIBILITY_INPUT_RULE = §6.3.1; D3 closed maps only

PROPOSER_PROVISIONAL_APPROVAL_STATUS_RULE = §8

PROPOSER_FINAL_INTRINSIC_VALIDATE_RULE = §8

PROPOSER_RESULT_PAIR_RULE = §16.1 / §16.8

PROPOSER_DIAGNOSTIC_PERSISTENCE_RULE = §18

BINDING_BACKED_SLOT_PROPOSER_RULE = BINDING_BACKED_SLOT_PLAN_RULE -> needs_review

COMPONENTIZATION_PROPOSAL_MODEL = DesignDocument + ComponentContract +
  ComponentizationPlan tuple; no ComponentizationProposal serialized wrapper

PLAN_LIFECYCLE_RULE = restated; plan valid | invalid only

REVIEWER_APPROVAL_AUTHORITY = §17.4

PROPOSER_RESULT_MODEL = §16.8; pair only for proposed | needs_review
```

---

## 25. C09D5-B implementation scope (next slice)

After C09D5-A merge, C09D5-B may implement:

```text
LiveFrames.ComponentizationProposer (module name illustrative)
ComponentizationSemanticInput + decision record structs (compile-time only)
propose/2 : DesignDocument, ComponentizationSemanticInput -> ProposerResult
deterministic construction per §8–12
validation orchestration per §19
unit tests: determinism, missing decision, proposed vs needs_review, never approved
fixture: minimal synthetic DesignDocument + hand-authored decisions (not Hero template)
```

C09D5-B must not: change IR/contract/plan schemas, add render roles, implement
HEEx, or embed Hero defaults.

---

## 26. STOP conditions (C09D5-A)

C09D5-A completed without triggering STOP. Implementers must STOP and escalate
if a future slice requires:

1. Design IR, ComponentContract, or ComponentizationPlan schema changes
2. new render role or collection-item RenderProjection
3. serialized `ComponentizationProposal` or versioned decision file
4. automatic public naming, classification, or boundary inference
5. inferred accessibility or binding-backed slot composition
6. second approval lifecycle on the plan
7. `contract_id` derivation without explicit semantic input
8. production proposer code in the authority-only slice (C09D5-A)

---

## 27. Scope confirmation (C09D5-A)

```text
production code changed = 0 (this slice)
Design IR schema changed = 0
ComponentContract schema changed = 0
ComponentizationPlan schema changed = 0
existing C09D1/C09D3 authority files amended = 0
merge performed = 0
```

---

## 28. Unresolved questions (explicit)

| ID | Question | Owner / next step |
| --- | --- | --- |
| U1 | Durable storage format if product requires replayable semantic decisions outside compile-time | future authority; not blocking C09D5-B API |
| U3 | Exact Elixir struct/module names for decision records | C09D5-B naming only; field shapes frozen in §6.3 |

Reviewer-side D1 `resolve` / `waiver` / `reject` encodings while IR remains
`evidence_insufficient` are deferred to later authority (not U2 — frozen as
`omit_public_projection` only in §6.6).

No STOP triggered on accepted base.
