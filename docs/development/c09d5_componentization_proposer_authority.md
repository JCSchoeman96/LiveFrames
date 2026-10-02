# C09D5-A Componentization proposer authority

**Status:** authority/documentation only (C09D5-A)

**Plan ID:** C09D5-A

**Plan version:** v1

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
  -> explicit semantic componentization decisions (compile-time input; section 7)
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
| `ComponentizationSemanticInput` | compile-time input bundle (section 7); **not serialized** | proposer caller / review tooling | valid or invalid input; no approval state |
| `ComponentContract` | `contract_id` | persisted compiler artifact | `approval_status`: proposed, needs_review, approved, rejected — **proposer may set only proposed or needs_review** |
| `ComponentizationPlan` | `(contract_id, design_document_sha256)` link | persisted compiler artifact | structurally/reference valid or invalid; **no approval_status** |
| `BindingProjection` | `(source_binding_kind, source_binding_id, projection_kind, public target fields)` | ComponentContract | no independent status (D1) |
| `RenderProjection` | `{:attr, name}` or `{:slot, name}` | ComponentizationPlan | one per public target (D3) |
| `ComponentContract.Diagnostic` | stable `component_contract.*` code | ComponentContract.diagnostics | info / warning / error / fatal |
| `ComponentizationPlan.Diagnostic` | stable `componentization_plan.*` code | ComponentizationPlan.diagnostics | info / warning / error / fatal |
| `ProposerResult` | outcome enum + optional pair + transient diagnostics | **process only**; not serialized | terminal: proposed, needs_review, invalid_input, construction_failed |

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

`ComponentizationSemanticInput` contains **ordered, typed decision records**.
Serialization order of maps in the host language is irrelevant; the proposer
**must** sort each decision list by a stable key before construction (section 21).

Closed first-wave decision record kinds:

| Record kind | Purpose |
| --- | --- |
| `ContractIdentityDecision` | `contract_id` |
| `ClassificationDecision` | `category`, `module_intent`, `function_intent` |
| `BoundaryDecision` | `boundary_node_id` **or** explicit `multi_root_unsupported` flag |
| `PublicAttrDecision` | full public attr semantics (name, type, required, default, purpose, validation, accessibility, provenance audit) |
| `PublicSlotDecision` | slot name, cardinality, required/optional, consumer responsibility, accessibility, provenance audit |
| `CollectionAdmissionDecision` | admit IR `CollectionBinding` as top-level `:list` attr or nested list item field (names + parent linkage explicit) |
| `ItemFieldDecision` | item field semantics under a specific `CollectionAdmissionDecision` / collection binding id |
| `BindingAssignmentDecision` | assign one IR binding to one public contract member (attr, slot, item field, or collection attr) |
| `RenderPlacementDecision` | unbound public attr/slot → `target_node_id` + `render_role` |
| `ImageAccessibilityDecision` | closed D3 policies on a named public attr or item field |
| `EvidenceHandlingDecision` | explicit handling for `evidence_insufficient` bindings (section 13) |
| `StaticContentDispositionDecision` | promote to public vs leave internal constant (section 16) |
| `InputProvenanceAudit` | optional non-executable audit map; never overrides structured decisions |

Forbidden fields on any decision record (reject input):

```text
source_system, bricks_*, wp_*, frame_*, editor_label, source_path, source_class,
source_id as semantic authority, fixture_id, value_key as public name,
DesignNode id as contract_id, mechanical hashes of source identity as contract_id
```

### 6.3 What counts as an explicit semantic decision

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

### 6.4 Missing decisions

```text
MISSING_SEMANTIC_DECISION_RULE =
  the proposer MUST NOT synthesize missing semantic decisions from IR, source
  metadata, map order, or defaults. A missing mandatory decision yields a
  deterministic outcome (section 17): invalid_input when the input model cannot
  be validated, or needs_review when a structurally constructible candidate
  still reflects unresolved semantics via blocking diagnostics and
  approval_status = needs_review.
```

---

## 7. Decision versus derivation matrix

Legend:

- **Explicit?** — must appear in semantic input (yes/no/partial).
- **Derived?** — proposer may compute when explicit assignment exists.
- **Missing** — outcome: `invalid_input` (I), `needs_review` (R), `construction_failed` (C), or N/A.
- **Invalid decision** — outcome: `invalid_input` (I) or `construction_failed` (C).

| Field / relationship | Owning artifact | Explicit? | May derive? | Authoritative derivation source | Forbidden inference | Missing | Invalid |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `contract_id` | Contract | yes | no | — | hash of source/node/path/labels | I | I |
| `category` | Contract | yes | no | — | semantic_type, depth, editor name | I | I |
| `module_intent` | Contract | yes | no | — | source module names | I | I |
| `function_intent` | Contract | yes | no | — | DOM tag, component name | I | I |
| public attr `name` | Contract | yes | no | — | value_key, label, class | I | I |
| public attr `type` | Contract | yes | no | — | source string type | I | C |
| required / default | Contract | yes | no | — | fixture literal | partial → R if default implied | C |
| `semantic_purpose` | Contract | yes | no | — | auto prose from IR | R if absent on promoted member | C |
| `validation` | Contract | yes | partial | heading_level may copy explicit decision values | IR attributes | R if role needs matrix | C |
| `accessibility` (image) | Contract Attr / ItemField | yes | no | — | nil alt, source HTML, filename | R | C |
| attr `provenance` | Contract | partial | audit only | binding ids from assignments | executable prose | N/A | C |
| public slot `name` | Contract | yes | no | — | child order, button count | I | I |
| slot cardinality | Contract | yes | no | — | repeat count in source | I | C |
| consumer responsibility | Contract | yes | no | — | — | R | C |
| `CollectionInput` location | Contract | yes | partial | parent ids from IR graph once names chosen | auto `items` name | I/R | C |
| `ItemField` names/types | Contract | yes | no | — | value_key | I | I |
| nested collection parent field | Contract | yes | partial | IR parent binding id | flatten to top-level | R | C |
| `BindingProjection` rows | Contract | partial | yes | IR binding + assignment decision | unassigned binding | R (uncovered) | C |
| `boundary_node_id` | Plan | yes | no | — | first root, largest subtree | I | I/R |
| `design_document_sha256` | Plan | no | yes | `ComponentizationPlan.design_document_sha256/1` | stale manual hash | C if IR invalid | C |
| `RenderProjection` | Plan | yes | partial | roles/targets only from `RenderPlacementDecision` | name→node | R | C |
| `contract approval_status` | Contract | no | yes | outcome rules §17 | auto approved | N/A | C if approved |
| contract diagnostics | Contract | partial | generated | validation + semantic rules | — | — | — |
| plan diagnostics | Plan | partial | generated | validation + semantic rules | — | — | — |
| plan `contract_id` link | Plan | partial | yes | contract `contract_id` | — | C | C |
| provenance (both) | both | audit | copy | decision audit + IR ids | override structured fields | N/A | C |

---

## 8. Proposal construction algorithm

Deterministic ordering:

```text
1. LiveFrames.IR.validate(design_document) -> invalid => ProposerResult invalid_input
2. validate ComponentizationSemanticInput intrinsic -> invalid => invalid_input
3. sort all decision lists by stable keys (section 21)
4. build ComponentContract shell:
     contract_format_version, contract_id, classification, empty collections
5. materialize PublicAttrDecision / PublicSlotDecision / ItemFieldDecision /
     CollectionAdmissionDecision into contract lists (no IR inference)
6. materialize BindingProjection from BindingAssignmentDecision + IR registries
7. materialize CollectionInput records from CollectionAdmissionDecision + IR
8. compute design_document_sha256
9. build ComponentizationPlan:
     plan_format_version, contract_id, fingerprint, boundary_node_id,
     RenderProjection from RenderPlacementDecision
10. ComponentContract.validate/1 -> errors => construction_failed
11. ComponentizationPlan.validate/1 -> errors => construction_failed
12. ComponentContract.validate_ir_references/2
13. ComponentizationPlan.validate_references/3
14. classify approval_status and ProposerResult outcome (section 17)
15. merge owned diagnostics into contract/plan lists deterministically
16. STOP — no approval transition, no generation
```

The proposer does **not** reimplement validation rules; it calls existing
validators. It may add **additional** proposer-owned semantic diagnostics before
step 10 when input validation requires them.

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
- **Initial approval_status:** set in step 14 only; never `:approved` /
  auto `:rejected`.

---

## 10. Plan construction rules

- **Fingerprint:** always computed from the same `DesignDocument` passed to the
  proposer; stored on plan.
- **contract_id:** must equal contract’s `contract_id`.
- **boundary_node_id:** from `BoundaryDecision`, or `multi_root_unsupported`
  yields `needs_review` with plan diagnostic `componentization_plan.boundary.invalid`
  if implementer emits a placeholder — prefer **invalid_input** if boundary
  record absent entirely.
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
- ordinary projection for `evidence_insufficient` without `EvidenceHandlingDecision`
  resolving to an allowed D1 outcome.

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

- Top-level image sources: `ImageAccessibilityDecision` on the asset **source**
  attr must set closed `Attr.accessibility` maps per D3 (`consumer_supplied` or
  `decorative`).
- Collection-item image sources: same on `ItemField.accessibility` with sibling
  alt field decisions and binding assignments per D3 §10.2.
- Proposer **must not** infer decorative/informative/alt from nil, source alt,
  or provenance prose.
- Missing policy on an admitted image public member → `needs_review` with D3
  accessibility diagnostics on plan reference validation (and contract intrinsic
  image rules where applicable).

---

## 14. Collections and nesting

- Admitting a collection requires `CollectionAdmissionDecision` with explicit
  public `:list` name (top-level) or `parent_item_field_name` (nested).
- IR proves parent/child edges; proposer does not invent parentage.
- Boundary-crossing collections → plan `boundary.binding_crosses` → `needs_review`.
- Nested collection without represented parent admission → `construction_failed`
  or `invalid_input` depending on whether parent decision is missing (missing → I)
  vs inconsistent with IR (C).
- Count attrs/fields require explicit item/attr decisions plus binding assignment
  for `collection_count` value bindings; no `length(items)` inference.

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

### 16.1 Outcome classes

| ProposerResult outcome | Meaning |
| --- | --- |
| `:invalid_input` | semantic input fails intrinsic validation; no candidate pair |
| `:construction_failed` | input valid but contract/plan fail **intrinsic** validation |
| `:needs_review` | candidate pair assembled; `approval_status = needs_review` |
| `:proposed` | candidate pair assembled; `approval_status = proposed` |

Ordinary semantic ambiguity uses `:needs_review`, not exceptions.

### 16.2 `approval_status` mapping

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
    AND no mandatory semantic review trigger in section 16.3

  OTHERWISE approval_status = needs_review (when a pair was constructed)
```

Do **not** call `validate_for_generation` during proposal classification.

### 16.3 Mandatory `needs_review` triggers (non-exhaustive; pair may still be intrinsic-valid)

```text
any blocking diagnostic from steps 11–13
EvidenceHandlingDecision absent for in-boundary evidence_insufficient binding
  that remains projected or uncovered
BINDING_BACKED_SLOT_PLAN_RULE
STATIC_COLLECTION_ITEM_RULE
UNSUPPORTED_NODE_RULE inside boundary
MULTI_ROOT_BOUNDARY_RULE
missing ImageAccessibilityDecision on admitted image source
STATIC_INTERNAL_IMAGE_RULE
explicit EvidenceHandlingDecision outcome = defer_review
any PublicAttrDecision / ItemFieldDecision flagged review_required in input
```

### 16.4 Blocking diagnostics vs `approval_status`

```text
PROPOSER_DIAGNOSTIC_APPROVAL_RULE =
  error or fatal diagnostics on the contract or plan (stored or generated in the
  proposer pass) force approval_status = needs_review when a pair is returned.
  info and warning alone do not force needs_review if all validations pass and
  section 16.3 triggers are absent.
```

### 16.5 `needs_review` vs malformed data

| Situation | Outcome |
| --- | --- |
| Wrong types / forbidden source fields in semantic input | `invalid_input` |
| Missing `contract_id` / category / boundary record | `invalid_input` |
| Duplicate decision keys / conflicting assignments | `invalid_input` |
| Decisions reference missing IR binding/node | `invalid_input` |
| Constructed contract/plan fail intrinsic shape | `construction_failed` |
| Valid shape but reference/coverage/accessibility failures | `needs_review` |
| Valid shape + all pass + no triggers | `proposed` |

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
| Input shape / forbidden field | transient `ProposerResult.input_diagnostics` | not serialized as artifact |
| Intrinsic contract failure | transient construction diagnostics | optional copy to contract.diagnostics |
| Intrinsic plan failure | transient | optional copy to plan.diagnostics |
| IR reference contract | `ComponentContract.Diagnostic` | contract.diagnostics |
| IR reference plan | `ComponentizationPlan.Diagnostic` | plan.diagnostics |
| Semantic review triggers | both per D1/D3 code families | respective artifact |

No third serialized diagnostic artifact. Provenance remains audit-only;
structured fields on contract/plan/decisions win on conflict.

Suggested proposer-only transient codes (not stored on artifacts unless copied):

```text
componentization_proposer.input.invalid
componentization_proposer.input.conflict
componentization_proposer.input.missing_decision
componentization_proposer.construction.failed
```

---

## 19. Validation ordering

Exact order (repeat of §8 for implementers):

```text
1. LiveFrames.IR.validate/1
2. semantic input validate
3. construct contract + plan
4. ComponentContract.validate/1
5. ComponentizationPlan.validate/1
6. ComponentContract.validate_ir_references/2
7. ComponentizationPlan.validate_references/3
8. classify proposed vs needs_review
```

**Never** invoke `ComponentContract.validate_for_generation/2` or
`ComponentizationPlan.validate_for_generation/3` as part of proposal success.

Failures in steps 4–5 → `construction_failed`. Failures in steps 6–7 with
valid intrinsic → `needs_review` (unless step 2 already rejected input).

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
  under stable sorting), and authority version -> identical contract, plan,
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
| evidence_insufficient unresolved | | yes | `componentization_plan.binding.evidence_insufficient` + contract | both |
| unsupported/raw/unknown node in boundary | | yes | `componentization_plan.unsupported_node` | plan |
| boundary-crossing collection | | yes | `componentization_plan.boundary.binding_crosses` | plan |
| nested collection parent missing | yes | | input / construction | transient |
| static internal image | | yes | STATIC_INTERNAL_IMAGE (plan) | plan |
| image policy missing | | yes | `componentization_plan.accessibility.*` | plan |
| consumer alt target mismatch | | yes | alt mismatch codes | plan |
| binding-backed slot | | yes | `componentization_plan.slot.binding_backed_unsupported` | plan |
| subtree slot hides bindings | | yes | `componentization_plan.slot.subtree_conflict` | plan |
| role/type or role/node mismatch | | yes | render_projection.* | plan |
| role co-location conflict | | yes | `render_projection.role_conflict` | plan |
| multi-root boundary flag | | yes | `componentization_plan.boundary.invalid` | plan |
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
| Map ordering alters output? | Stable sort on all decision lists before construction. |
| Bypass D1/D3 validation? | Proposer calls existing validators; no duplicate weakened rules. |
| `needs_review` vs malformed? | §16.5 table. |
| Accidental `approved`? | `PROPOSER_APPROVAL_RULE` forbids; construction sets only proposed/needs_review. |
| Duplicate artifact? | No serialized proposal wrapper; pair only. |
| New serialized decision artifact? | Not required; compile-time input only. |
| Collection/accessibility edge cases? | §13–14, D3 §10, failure matrix. |
| Approximately linear? | §8 algorithm + O() bound §20.3. |

---

## 24. Decision register (frozen rules)

```text
SEMANTIC_INPUT_ARTIFACT_DECISION = compile-time ComponentizationSemanticInput only;
  no versioned serialized decision artifact in C09D5 first wave

MISSING_SEMANTIC_DECISION_RULE = no fill-in; deterministic invalid_input or
  needs_review per §16

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

PROPOSER_APPROVAL_CLASSIFICATION_RULE = §16.2

PROPOSER_DIAGNOSTIC_APPROVAL_RULE = §16.4

PROPOSER_VALIDATION_ORDER_RULE = §19

PROPOSER_GENERATION_GATE_SEPARATION = validate_for_generation not used in proposal

PROPOSER_DETERMINISM_RULE = §20.2

PROPOSER_INDEX_ONCE_RULE = §20.3

EVIDENCE_HANDLING_INPUT_RULE = evidence_insufficient bindings require
  EvidenceHandlingDecision or force needs_review

STATIC_PROMOTION_INPUT_RULE = promotion requires Public*Decision or explicit
  disposition; STATIC_DEFAULT_RULE preserved

IMAGE_ACCESSIBILITY_INPUT_RULE = ImageAccessibilityDecision required for
  admitted image sources; D3 closed maps only

BINDING_BACKED_SLOT_PROPOSER_RULE = BINDING_BACKED_SLOT_PLAN_RULE -> needs_review

COMPONENTIZATION_PROPOSAL_MODEL = DesignDocument + ComponentContract +
  ComponentizationPlan tuple; no ComponentizationProposal serialized wrapper

PLAN_LIFECYCLE_RULE = restated; plan valid | invalid only

REVIEWER_APPROVAL_AUTHORITY = §17.4

PROPOSER_RESULT_MODEL = process-only outcome + optional pair + transient diagnostics
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
| U2 | Whether `EvidenceHandlingDecision` should encode reviewer `exclude` as contract diagnostic codes only vs omitting projections | C09D5-B implementation must follow D1 §9 outcomes literally |
| U3 | Exact Elixir struct names for decision records | C09D5-B naming; semantics frozen here |

No STOP triggered on accepted base.
