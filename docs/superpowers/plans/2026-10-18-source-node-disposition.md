# SourceNodeDisposition 1.1.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the accepted SourceNodeDisposition 1.1.0 authority so an exactly reviewed source-runtime carrier may remain as Design IR evidence while being omitted from generated structure without weakening unsupported-node fail-closed behavior.

**Architecture:** SourceNodeDisposition decisions enter through SemanticInput, receive exact Behavior authority through Behavior.ComponentizationDecision and an ephemeral BehaviorAuthorityContext, become deterministic ComponentizationPlan 1.1.0 NodeDisposition records, receive an exact ComponentReviewResult, and are revalidated before one shared filtered native-generation structural view is used by styling and rendering.

**Tech Stack:** Elixir, Phoenix/HEEx generation, ExUnit, deterministic JSON serializers.

**Spec:** `docs/superpowers/specs/2026-10-18-source-node-disposition-design.md`

---

## Base and authority gate

This correction is based on the following exact `origin/main` identity and CI evidence:

```text
CORRECTION_BASE_SHA=f75c9a19fb1965648b6e4c6dce2c88e4c376f014
CORRECTION_BASE_TREE=1ee056644312c65acb006d4f48c84d8ab16cfae1
CORRECTION_BASE_CI_RUN=39119253153
CORRECTION_BASE_CI_RESULT=success
PR245_REJECTED_HEAD=31baf490562672afddbd4d66c5a5857a8213c539
PR245_MERGE_SHA=9fff912f4e05e628f8790c98a22fff6c701cb49a
PR245_MERGE_TREE=be14b95f0e7feeb407f505b34882254054041e12
PR245_MERGE_FIRST_PARENT=d5e2421f64766dffe328bc992e357e1854308fa2
PR245_MERGE_SECOND_PARENT=31baf490562672afddbd4d66c5a5857a8213c539
PR245_POST_MERGE_CI=39119244543
PR245_POST_MERGE_CI_RESULT=success
NAV_CARRIER_IMPLEMENTATION_MERGE=d5e2421f64766dffe328bc992e357e1854308fa2
```

After this correction merges, implementation authorization must record the then-current `origin/main` commit, tree, and successful CI run as the implementation base. Recheck that exact identity, the primary spec, and the accepted authority files before Task 1. If main moves after implementation starts, stop. Do not rebase automatically.

The repository names the accepted native-generation authority `docs/development/c09d6_native_generation_authority.md`; the name in the request included an extra `_and_review`. Use the file that exists in the accepted tree. Preserve these authorities without editing them:

- `docs/development/c09d3_componentization_plan_authority.md`
- `docs/development/c09d5_componentization_proposer_authority.md`
- `docs/development/p7_interaction_conversion_implementation_plan.md`
- `docs/development/c09d6_native_generation_authority.md`
- `docs/development/nav_carrier_heading_link_representation_authority.md`

The Plan field and generation inputs apply only to the accepted SourceNodeDisposition capability. Keep `NativeGenerator.generate/3` for plans without dispositions. The disposition-aware overload must not change NAV-CARRIER markup, navigation validation, renderer-created anchor styling, or the existing C09D6 rules for ordinary generation.

PR #244 merged NAV-CARRIER implementation at `d5e2421f64766dffe328bc992e357e1854308fa2`. The implementation owners are `apps/live_frames/lib/live_frames/adapters/bricks/static_navigation.ex`, `apps/live_frames/lib/live_frames/componentization_plan/reference_validation.ex`, `apps/live_frames/lib/live_frames/fidelity.ex`, `apps/live_frames/lib/live_frames/native_generator/renderer.ex`, `apps/live_frames/lib/live_frames/native_generator/style_integration.ex`, and `apps/live_frames/lib/live_frames/native_generator/stylesheet_renderer.ex`. Relevant existing tests include `apps/live_frames/test/live_frames/bricks_static_navigation_test.exs`, `apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs`, `apps/live_frames/test/live_frames/native_generator/style_integration_test.exs`, `apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs`, and `apps/live_frames/test/live_frames/native_generator_v6_proofs_test.exs`.

The filter applies only to explicit disposed DesignNode IDs. Renderer-created anchor markup is not a disposable DesignNode. Task 9 must prove that disposing an unrelated DesignNode leaves NAV-CARRIER behavior intact.

## Implementation contract

The interfaces below are frozen for implementation. Each review value is one exact selected record, not a collection from which the callee chooses.

```elixir
defmodule LiveFrames.ComponentizationPlan.NodeDisposition do
  @type t :: %__MODULE__{
          design_node_id: String.t(),
          disposition: :exclude_source_runtime_carrier,
          source_type: String.t(),
          source_id: String.t(),
          behavior_binding_id: String.t(),
          behavior_contract_digest: String.t(),
          behavior_review_id: String.t(),
          evidence_refs: [String.t()]
        }

  def validate(term()) :: :ok | {:error, [LiveFrames.ComponentizationPlan.Diagnostic.t()]}
  def validate_list([term()]) ::
        :ok | {:error, [LiveFrames.ComponentizationPlan.Diagnostic.t()]}

  defstruct [
    :design_node_id,
    :disposition,
    :source_type,
    :source_id,
    :behavior_binding_id,
    :behavior_contract_digest,
    :behavior_review_id,
    :evidence_refs
  ]
end

defmodule LiveFrames.ComponentizationProposer.SemanticInput.SourceNodeDispositionDecision do
  @type t :: %__MODULE__{
          design_node_id: String.t() | nil,
          outcome: :exclude_source_runtime_carrier | nil,
          behavior_binding_id: String.t() | nil,
          evidence_refs: [String.t()]
        }

  defstruct design_node_id: nil,
            outcome: nil,
            behavior_binding_id: nil,
            evidence_refs: []
end

defmodule LiveFrames.ComponentizationProposer.SemanticInput do
  @type t :: %__MODULE__{
          source_node_dispositions: [
            LiveFrames.ComponentizationProposer.SemanticInput.SourceNodeDispositionDecision.t()
          ]
        }

  def repeatable_families() :: [atom()]
  def validate(term(), LiveFrames.IR.DesignDocument.t()) ::
        {:ok, t()} | {:error, [LiveFrames.ComponentizationProposer.Diagnostic.t()]}
end

defmodule LiveFrames.BehaviorAuthorityContext do
  @type t :: %__MODULE__{
          behavior_contract: LiveFrames.Behavior.Contract.t(),
          behavior_contract_digest: String.t(),
          selected_behavior_review_result: LiveFrames.Behavior.ReviewResult.t(),
          behavior_review_result_id: String.t()
        }

  defstruct [
    :behavior_contract,
    :behavior_contract_digest,
    :selected_behavior_review_result,
    :behavior_review_result_id
  ]
end

defmodule LiveFrames.NativeGenerator.FilteredStructure do
  @type t :: %__MODULE__{
          boundary_node_id: String.t(),
          root_node_ids: [String.t()],
          nodes_by_id: %{optional(String.t()) => LiveFrames.IR.DesignNode.t()},
          children_by_id: %{optional(String.t()) => [String.t()]},
          path_by_id: %{optional(String.t()) => [pos_integer()]},
          private_class_by_id: %{optional(String.t()) => String.t()}
        }

  defstruct [
    :boundary_node_id,
    root_node_ids: [],
    nodes_by_id: %{},
    children_by_id: %{},
    path_by_id: %{},
    private_class_by_id: %{}
  ]
end

LiveFrames.ComponentizationProposer.Construction.build(
  design_document, canonical_semantic_input, behavior_authority_context
) ::
  {:ok, LiveFrames.ComponentContract.t(), LiveFrames.ComponentizationPlan.t()}
  | {:error, [LiveFrames.ComponentizationProposer.Diagnostic.t()]}

LiveFrames.Behavior.ComponentizationDecision.authority_context(
  design_document,
  behavior_contract,
  selected_behavior_review_result
) :: {:ok, LiveFrames.BehaviorAuthorityContext.t()}
   | {:error, {:prerequisite, atom(), list()}}

LiveFrames.Behavior.ComponentizationDecision.reference_index(
  design_document,
  behavior_contract
) :: {:ok, %{optional(String.t()) => MapSet.t(atom())}}
   | {:error, [LiveFrames.Behavior.Diagnostic.t()]}

LiveFrames.ComponentizationProposer.propose_with_behavior_authority_context_internal(
  design_document,
  canonical_semantic_input,
  behavior_authority_context
) :: LiveFrames.ComponentizationProposer.Result.t()

LiveFrames.ComponentizationPlan.validate_references_with_behavior_authority(
  plan, component_contract, design_document, behavior_contract, selected_behavior_review_result
) :: :ok | {:error, [LiveFrames.ComponentizationPlan.Diagnostic.t()]}

LiveFrames.ComponentizationPlan.validate_generation_prerequisites_with_behavior_authority(
  plan, component_contract, design_document, behavior_contract, selected_behavior_review_result
) :: :ok | {:error, [LiveFrames.ComponentizationPlan.Diagnostic.t()]}

LiveFrames.ComponentizationPlan.validate_for_generation_with_behavior_authority(
  plan, approved_component_contract, design_document, behavior_contract,
  selected_behavior_review_result
) :: :ok | {:error, [LiveFrames.ComponentizationPlan.Diagnostic.t()]}

defmodule LiveFrames.ComponentReviewResult do
  @type t :: %__MODULE__{
          review_format_version: String.t(),
          component_contract_id: String.t(),
          component_contract_digest_algorithm: String.t(),
          component_contract_digest: String.t(),
          design_document_sha256: String.t(),
          componentization_plan_digest_algorithm: String.t(),
          componentization_plan_digest: String.t(),
          decision: String.t(),
          reviewer_identity: String.t(),
          reviewed_at: String.t(),
          evidence_refs: [String.t()]
        }

  defstruct [
    :review_format_version,
    :component_contract_id,
    :component_contract_digest_algorithm,
    :component_contract_digest,
    :design_document_sha256,
    :componentization_plan_digest_algorithm,
    :componentization_plan_digest,
    :decision,
    :reviewer_identity,
    :reviewed_at,
    :evidence_refs
  ]

  def algorithm() :: String.t()
  def validate(term()) :: :ok | {:error, list()}
  def encode(term()) :: {:ok, binary()} | {:error, list()}
  def id(term()) :: {:ok, String.t()} | {:error, list()}
  def validate_against(review_result, approved_component_contract, plan, design_document) ::
        :ok | {:error, list()}
end

LiveFrames.ComponentReview.approve_with_result(
  proposed_component_contract, plan, design_document, behavior_contract,
  selected_behavior_review_result, reviewer_identity, reviewed_at, evidence_refs
) :: {:ok, LiveFrames.ComponentContract.t(), LiveFrames.ComponentReviewResult.t()}
   | {:error, list()}

LiveFrames.NativeGenerator.generate(
  approved_component_contract, plan, design_document, behavior_contract,
  selected_behavior_review_result, selected_component_review_result,
  selected_component_review_result_id
) :: {:ok, LiveFrames.NativeGenerator.GeneratedArtifactBundle.t()}
   | {:error, :generation_blocked | :generation_failed, list()}

LiveFrames.NativeGenerator.FilteredStructure.build(
  design_document, boundary_node_id, authorized_disposed_node_ids, package_root_class
) :: {:ok, LiveFrames.NativeGenerator.FilteredStructure.t()}
   | {:error, LiveFrames.NativeGenerator.Diagnostic.t()}

LiveFrames.NativeGenerator.FilteredStructure.children(
  filtered_structure, design_node_id
) :: [String.t()]

LiveFrames.NativeGenerator.StyleIntegration.build(contract, plan, filtered_structure) ::
  {:ok,
   %{
     private_class_by_id: map(),
     primary_action_slot_targets: MapSet.t(),
     stylesheet_content: binary(),
     stylesheet_path: binary()
   }}
  | {:error, :generation_blocked, [LiveFrames.NativeGenerator.Diagnostic.t()]}
LiveFrames.NativeGenerator.Renderer.build_indexes(
  contract, plan, filtered_structure, value_bindings, primary_action_slot_targets
) :: {:ok, LiveFrames.NativeGenerator.Renderer.Indexes.t()}
   | {:error, LiveFrames.NativeGenerator.Diagnostic.t()}
```

`ComponentReviewResult` has exactly these closed fields and no serialized ID or optional metadata:

```text
review_format_version = "1.0.0"
component_contract_id: non-empty string
component_contract_digest_algorithm = "sha-256"
component_contract_digest: 64 lowercase hexadecimal characters
design_document_sha256: 64 lowercase hexadecimal characters
componentization_plan_digest_algorithm = "sha-256"
componentization_plan_digest: 64 lowercase hexadecimal characters
decision: "approved" | "needs_review" | "rejected"
reviewer_identity: non-empty string
reviewed_at: UTC YYYY-MM-DDTHH:MM:SS.ffffffZ
evidence_refs: non-empty unique string list

COMPONENT_REVIEW_ID_ALGORITHM=lf-component-review-v1-jcs-sha256
COMPONENT_REVIEW_ID=crv_ + lowercase SHA-256 of canonical review-result bytes
```

`validate/1` checks this exact shape. `encode/1` uses `LiveFrames.CanonicalJSON.encode/1`, deterministic object keys, and evidence refs sorted by Unicode-scalar order. `id/1` hashes those exact bytes. `validate_against/4` requires an approved contract and an approved result, then matches contract ID, exact approved contract bytes, exact encoded plan bytes, and exact DesignDocument digest.

Freeze this synthetic review-result fixture and its canonical identity. Compute the byte count and ID independently from the literal canonical JSON, not with the production `ComponentReviewResult.id/1` implementation under test.

```text
review_format_version=1.0.0
component_contract_id=component:test

component_contract_digest_algorithm=sha-256
component_contract_digest=
1111111111111111111111111111111111111111111111111111111111111111

design_document_sha256=
2222222222222222222222222222222222222222222222222222222222222222

componentization_plan_digest_algorithm=sha-256
componentization_plan_digest=
3333333333333333333333333333333333333333333333333333333333333333

decision=approved
reviewer_identity=reviewer:test
reviewed_at=2026-10-18T00:00:00.000000Z

evidence_refs=
evidence:a
evidence:b
```

The exact canonical JSON literal is:

```json
{"component_contract_digest":"1111111111111111111111111111111111111111111111111111111111111111","component_contract_digest_algorithm":"sha-256","component_contract_id":"component:test","componentization_plan_digest":"3333333333333333333333333333333333333333333333333333333333333333","componentization_plan_digest_algorithm":"sha-256","decision":"approved","design_document_sha256":"2222222222222222222222222222222222222222222222222222222222222222","evidence_refs":["evidence:a","evidence:b"],"review_format_version":"1.0.0","reviewed_at":"2026-10-18T00:00:00.000000Z","reviewer_identity":"reviewer:test"}
```

```text
COMPONENT_REVIEW_GOLDEN_CANONICAL_BYTES=604
COMPONENT_REVIEW_GOLDEN_ID=crv_1b012f7028cc1b15a4127403e12ed032e3ed6ead16b8c995690f8e12ef1136d7
```

If `CanonicalJSON` or `ComponentReviewResult.encode/1` does not reproduce these literal bytes, stop with `STOP=COMPONENT_REVIEW_GOLDEN_IDENTITY_MISMATCH`. Do not replace the golden with implementation output.

`ComponentReviewResult` has no public constructor or approval operation. `ComponentReview.approve_with_result/8` is the only supported operation that creates an approved result, and it creates it in the same transition that returns the matching approved contract.

`SourceNodeDispositionDecision` is the nested module shown in the Interfaces block. `SemanticInput` adds only `source_node_dispositions` to its struct and repeatable-family list; it remains transient and has no serializer or persistence API. Its four decision fields are closed, and Behavior digest/review identity fields are rejected as unknown fields.

`BehaviorAuthorityContext` has `serialization=NONE`, `persistence=NONE`, and `runtime_presence=NONE`. It is ordinary data, not an unforgeable capability. The context-aware proposer recalculates the Behavior contract digest and review ID, checks singleton approval against that contract, checks the contract's DesignDocument identity, and checks every requested binding ID for exactly one match.

`ComponentizationPlan.current_format_version/0` and the default for new plans become `"1.1.0"`. Explicit `"1.0.0"` plans remain valid with their historical schema and behavior. Existing `validate_references/3`, `validate_generation_prerequisites/3`, and `validate_for_generation/3` continue to accept ordinary plans. For a 1.1.0 plan with dispositions, those APIs emit `componentization_plan.node_disposition.behavior_authority_mismatch` and retain `componentization_plan.unsupported_node` for every unconsumed unsupported target. The three authority-aware `/5` APIs are required to validate a disposition-bearing plan successfully.

`ComponentizationPlan.t` adds `node_dispositions: [NodeDisposition.t()]`, and the struct defaults that field to `[]`. Sort the list by ascending UTF-8 `design_node_id` bytes; sort each disposition's `evidence_refs` by ascending Unicode-scalar order.

`ComponentReview.approve/3` remains compatible for plans without dispositions. It returns `component_contract.approval_blocked` without changing the candidate when `node_dispositions` is non-empty. `approve_with_result/8` is the only approval operation for a disposition-bearing plan. It validates the candidate, exact plan, document, Behavior contract, selected Behavior review, and review evidence; derives the approved contract; hashes that approved contract's encoded bytes; hashes the exact plan bytes and document identity; creates the approved ComponentReviewResult; and returns the approved contract and result together. It never hashes the proposed contract.

`NativeGenerator.generate/3` remains the ordinary path and returns `:generation_blocked` with `native_generator.disposition_authority_required` for a disposition-bearing plan. `generate/7` is the disposition-aware path. It verifies the supplied Behavior and Component review identities and all exact digests before building the filtered structure. Any selected ComponentReviewResult ID, decision, contract-byte, plan-byte, or document-digest mismatch returns `native_generator.component_review_authority_mismatch`. It accepts one selected result and never searches review history. There is no persisted generation-authority wrapper.

Preserve the original DesignDocument unchanged. Never execute or copy source runtime data.

Plan diagnostics for defined failure modes remain deterministic and use these exact codes: `componentization_plan.node_disposition.invalid`, `target_missing`, `target_outside_boundary`, `target_semantic_incompatible`, `duplicate`, `outcome_unsupported`, `source_identity_mismatch`, `behavior_binding_mismatch`, `behavior_authority_mismatch`, `behavior_reference_conflict`, and `unused`. Prefix every short suffix after `componentization_plan.node_disposition.`. Keep the existing `componentization_plan.unsupported_node` blocker whenever a target has not passed every applicable plan and Behavior guard. Independent presentation, content, accessibility, and generated-DOM roles are human review judgments; do not claim the plan validator infers them from opaque evidence refs.

| Diagnostic code | Failing condition |
| --- | --- |
| `componentization_plan.node_disposition.invalid` | Wrong struct, missing/extra field, malformed string, digest/review-ID syntax, or evidence-list shape. |
| `componentization_plan.node_disposition.target_missing` | `design_node_id` does not exist in the original document index. |
| `componentization_plan.node_disposition.target_outside_boundary` | Target exists outside the selected original boundary. |
| `componentization_plan.node_disposition.target_semantic_incompatible` | Target is supported or is not a leaf. |
| `componentization_plan.node_disposition.duplicate` | More than one disposition names the same node. |
| `componentization_plan.node_disposition.outcome_unsupported` | Outcome is outside the closed enum. |
| `componentization_plan.node_disposition.source_identity_mismatch` | SourceTrace is absent or its source type/ID differs. |
| `componentization_plan.node_disposition.behavior_binding_mismatch` | Binding is missing or appears more than once in the exact Behavior contract. |
| `componentization_plan.node_disposition.behavior_authority_mismatch` | Contract digest, selected review ID, document identity, or singleton approval differs. |
| `componentization_plan.node_disposition.behavior_reference_conflict` | A Behavior or relevant IR interaction reference touches the disposed node. |
| `componentization_plan.node_disposition.unused` | A valid disposition is not consumed exactly once by validation and filtering. |

## File structure

Freeze this map before Task 1. Do not add dependencies, change Design IR or ComponentContract schemas, edit accepted authority files, or modify unrelated modules.

### New production files

| File | One responsibility |
| --- | --- |
| `apps/live_frames/lib/live_frames/componentization_plan/node_disposition.ex` | Define and intrinsically validate the closed NodeDisposition record and canonical disposition lists. |
| `apps/live_frames/lib/live_frames/behavior_authority_context.ex` | Carry one validated Behavior contract and selected review between the Behavior gate and proposer in memory. |
| `apps/live_frames/lib/live_frames/component_review_result.ex` | Validate, encode, bind, and derive the content ID for one immutable component review result. |
| `apps/live_frames/lib/live_frames/native_generator/filtered_structure.ex` | Build the single in-memory DesignNode view used by every native-generation traversal after authority checks. |

### Existing production files to modify

| File | Responsibility in this plan |
| --- | --- |
| `apps/live_frames/lib/live_frames/componentization_plan.ex` | Expose versioned schema and authority-aware validation APIs. |
| `apps/live_frames/lib/live_frames/componentization_plan/validation.ex` | Validate Plan 1.0.0 and 1.1.0 schemas and disposition records. |
| `apps/live_frames/lib/live_frames/componentization_plan/serializer.ex` | Encode 1.0.0 without the new field and 1.1.0 with it, including an empty list. |
| `apps/live_frames/lib/live_frames/componentization_plan/reference_validation.ex` | Validate dispositions against the original document and preserve unsupported-node fail-closed behavior. |
| `apps/live_frames/lib/live_frames/componentization_proposer/semantic_input.ex` | Add the typed decision and repeatable family. |
| `apps/live_frames/lib/live_frames/componentization_proposer/semantic_input/validation.ex` | Validate closed decision fields and evidence references. |
| `apps/live_frames/lib/live_frames/componentization_proposer/semantic_input/canonicalization.ex` | Canonicalize decision and evidence-reference ordering. |
| `apps/live_frames/lib/live_frames/behavior/componentization_decision.ex` | Build exact Behavior authority context and one indexed set of Behavior/IR node references. |
| `apps/live_frames/lib/live_frames/componentization_proposer.ex` | Keep direct APIs closed to dispositions and add the context-aware proposer handoff. |
| `apps/live_frames/lib/live_frames/componentization_proposer/construction.ex` | Build a NodeDisposition only after target and authority gates pass. |
| `apps/live_frames/lib/live_frames/component_review.ex` | Guard `approve/3` and add the atomic result-producing approval transition. |
| `apps/live_frames/lib/live_frames/native_generator.ex` | Add `generate/7`, revalidate exact authority, and build one filtered structure. |
| `apps/live_frames/lib/live_frames/native_generator/style_integration.ex` | Consume the shared filtered structure for CSS and state-rule traversal. |
| `apps/live_frames/lib/live_frames/native_generator/renderer.ex` | Consume the same structure for renderer indexes and HEEx traversal. |

`component_contract.ex`, `component_contract/serializer.ex`, `behavior/contract.ex`, `behavior/review_result.ex`, `native_generator/node_style_identity.ex`, Design IR modules, and NAV-CARRIER implementation files remain owners of their current rules. Use their APIs; do not duplicate their schemas or change their authority.

### Existing tests to extend

- `apps/live_frames/test/live_frames/componentization_plan_test.exs`
- `apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs`
- `apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs`
- `apps/live_frames/test/live_frames/componentization_proposer_test.exs`
- `apps/live_frames/test/live_frames/behavior/componentization_decision_test.exs`
- `apps/live_frames/test/live_frames/component_review_test.exs`
- `apps/live_frames/test/live_frames/native_generator_test.exs`
- `apps/live_frames/test/live_frames/native_generator/style_integration_test.exs`

### New test files

| File | One responsibility |
| --- | --- |
| `apps/live_frames/test/live_frames/componentization_plan/node_disposition_test.exs` | Exercise the closed NodeDisposition record, value constraints, and list uniqueness/order. |
| `apps/live_frames/test/live_frames/component_review_result_test.exs` | Exercise canonical review bytes, content ID, and exact input binding. |
| `apps/live_frames/test/live_frames/native_generator/filtered_structure_test.exs` | Prove filtering preserves original traversal paths while removing exactly authorized IDs from the shared view. |
| `apps/live_frames/test/live_frames/native_generator/disposition_end_to_end_test.exs` | Task 8 synthetic proof that preserves DesignDocument and plan identity while omitting only authorized IDs from HEEx, CSS, state traversal, renderer indexes, and private-class ownership. |

Use `behavior/componentization_decision_test.exs` for BehaviorAuthorityContext tests. Its existing fixtures construct exact contracts, approved singleton reviews, and resolved DesignDocuments.

## Task ownership sequence

```text
Task 1
Plan 1.1.0 schema + NodeDisposition

Task 2
SemanticInput SourceNodeDispositionDecision

Task 3
BehaviorAuthorityContext + behavior-aware proposer handoff

Task 4
guarded NodeDisposition construction

Task 5
reference-validation disposition semantics

Task 6
ComponentReviewResult + exact approval transition

Task 7
generation authority gate only

Task 8
shared FilteredStructure
+ synthetic end-to-end omission
+ multi-disposition structural determinism

Task 9
historical/API/NAV-CARRIER regression verification

Task 10
read-only exact Milan proof
```

## Task-boundary invariant

```text
TASK_BOUNDARY_WORKTREE_STATUS=clean
```

After every Task 1–9 commit, run `git status --porcelain` and require `EMPTY` before starting the next task. No task may carry another task's changed or untracked files forward. Apply this check before each subsequent task. If the status is not empty, stop with `STOP=TASK_BOUNDARY_WORKTREE_DIRTY` and resolve the task boundary before continuing.

## Task 1: Plan 1.1.0 schema and NodeDisposition

**Files:**
- Create: `apps/live_frames/lib/live_frames/componentization_plan/node_disposition.ex`
- Modify: `apps/live_frames/lib/live_frames/componentization_plan.ex`
- Modify: `apps/live_frames/lib/live_frames/componentization_plan/validation.ex`
- Modify: `apps/live_frames/lib/live_frames/componentization_plan/serializer.ex`
- Create: `apps/live_frames/test/live_frames/componentization_plan/node_disposition_test.exs`
- Modify: `apps/live_frames/test/live_frames/componentization_plan_test.exs`

- [ ] **Step 1: Add failing schema and golden-byte tests.** Extend the existing plan test with new-default assertions, an empty 1.1.0 field assertion, and two explicit 1.0.0 byte fixtures. The fixtures cover an empty plan and a plan with a RenderProjection. Capture their expected bytes from the unmodified base serializer before changing it.

```elixir
test "1.1.0 encodes an empty disposition list and 1.0.0 keeps historical bytes" do
  assert ComponentizationPlan.current_format_version() == "1.1.0"
  current_map = ComponentizationPlan.to_map(valid_plan())
  assert current_map["node_dispositions"] == []

  legacy = valid_plan(plan_format_version: "1.0.0")
  assert {:ok, legacy_bytes} = ComponentizationPlan.encode(legacy)
  expected = ~s({"boundary_node_id":"node_000001","contract_id":"hero","design_document_sha256":"#{String.duplicate("a", 64)}","diagnostics":[],"plan_format_version":"1.0.0","provenance":{},"render_projections":[]})
  assert legacy_bytes == expected
  refute String.contains?(legacy_bytes, "node_dispositions")

  legacy_projection = valid_plan(
    plan_format_version: "1.0.0",
    render_projections: [%RenderProjection{public_attr_name: "title", target_node_id: "node_000001_000001", render_role: :text_content}]
  )
  assert {:ok, projection_bytes} = ComponentizationPlan.encode(legacy_projection)
  projection_expected = ~s({"boundary_node_id":"node_000001","contract_id":"hero","design_document_sha256":"#{String.duplicate("a", 64)}","diagnostics":[],"plan_format_version":"1.0.0","provenance":{},"render_projections":[{"public_attr_name":"title","public_slot_name":null,"render_role":"text_content","target_node_id":"node_000001_000001"}]})
  assert projection_bytes == projection_expected
end
```

- [ ] **Step 2: Run the focused plan tests and confirm failure.** Run `mix test apps/live_frames/test/live_frames/componentization_plan_test.exs apps/live_frames/test/live_frames/componentization_plan/node_disposition_test.exs`. Expected: the new module and 1.1.0 schema are absent, and the historical fixture assertion fails if serialization changes.
- [ ] **Step 3: Implement the closed type and versioned schema.** `NodeDisposition.validate/1` requires the exact struct keys, non-empty valid UTF-8 strings, the sole atom `:exclude_source_runtime_carrier`, a 64-character lowercase hexadecimal Behavior digest, `brv_` plus 64 lowercase hexadecimal characters, and a proper non-empty evidence list with unique strings in ascending Unicode-scalar order. `validate_list/1` rejects duplicate `design_node_id` values and any order other than ascending UTF-8 `design_node_id` bytes. New plans default to 1.1.0. For 1.0.0, require an empty disposition list and omit the key from encoded maps. For 1.1.0, require and encode the field even when empty. Do not add a decode API.
- [ ] **Step 4: Run focused tests and confirm green output.** Run the same two test files. Expected: both 1.0.0 golden fixtures match byte-for-byte, 1.1.0 includes the field, and invalid records return deterministic `componentization_plan.node_disposition.*` diagnostics.
- [ ] **Step 5: Run the plan reference suite and commit.** Run `mix test apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs`. Expected: ordinary reference cases pass with the new default. Commit as `feat: add componentization plan 1.1 dispositions`.

## Task 2: SemanticInput decision family

**Files:**
- Modify: `apps/live_frames/lib/live_frames/componentization_proposer/semantic_input.ex`
- Modify: `apps/live_frames/lib/live_frames/componentization_proposer/semantic_input/validation.ex`
- Modify: `apps/live_frames/lib/live_frames/componentization_proposer/semantic_input/canonicalization.ex`
- Modify: `apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs`

- [ ] **Step 1: Add failing decision tests.** Add `SourceNodeDispositionDecision` with `design_node_id`, `outcome`, `behavior_binding_id`, and `evidence_refs`. Add a local test helper `decision(node_id, refs)` that returns that exact struct. Test canonical family order and evidence order independent of caller order, duplicate target, duplicate evidence ref, unknown outcome, empty/malformed values, and injected digest/review keys. For an existing input with no disposition family, assert all prior canonical decision values and proposed ComponentContract behavior remain unchanged, adding only an empty field. SemanticInput has no byte serializer; durable byte compatibility is asserted by the 1.0.0 plan goldens in Task 1.

```elixir
test "source node dispositions canonicalize by node ID and evidence reference" do
  left = %{input() | source_node_dispositions: [decision("node_b", ["z", "a"]), decision("node_a", ["b"])]}
  right = %{input() | source_node_dispositions: [decision("node_a", ["b"]), decision("node_b", ["a", "z"])]}
  assert {:ok, left} = Input.validate(left, document())
  assert {:ok, right} = Input.validate(right, document())
  assert left.source_node_dispositions == right.source_node_dispositions
end

test "an input without source node dispositions remains valid and empty" do
  assert {:ok, canonical} = Input.validate(input(), document())
  assert canonical.source_node_dispositions == []
end
```

- [ ] **Step 2: Run the focused semantic-input test and confirm failure.** Run `mix test apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs`. Expected: shape, family, and ordering assertions fail before implementation.
- [ ] **Step 3: Implement only this family.** Add exactly `:source_node_dispositions` to `repeatable_families/0`, the SemanticInput type/struct, and the validation family table. Validate its four closed fields. Canonicalize decisions by ascending UTF-8 `design_node_id` bytes, sort evidence refs by Unicode-scalar order, and reject repeated target IDs and evidence refs. Keep Behavior digest and review ID out of SemanticInput.
- [ ] **Step 4: Run semantic-input and proposer suites.** Run `mix test apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs apps/live_frames/test/live_frames/componentization_proposer_test.exs`. Expected: no-disposition inputs retain their prior result; new decisions validate and canonicalize.
- [ ] **Step 5: Commit.** Commit as `feat: add source node disposition semantic input`.

## Task 3: BehaviorAuthorityContext and proposer handoff

**Files:**
- Create: `apps/live_frames/lib/live_frames/behavior_authority_context.ex`
- Modify: `apps/live_frames/lib/live_frames/behavior/componentization_decision.ex`
- Modify: `apps/live_frames/lib/live_frames/componentization_proposer.ex`
- Modify: `apps/live_frames/test/live_frames/behavior/componentization_decision_test.exs`
- Modify: `apps/live_frames/test/live_frames/componentization_proposer_test.exs`

- [ ] **Step 1: Add failing handoff and compatibility tests.** Test that the Behavior-aware gate passes the exact contract, digest, selected review, and review ID into the context-aware path. Test that direct proposer `/2`, breakpoint `/3`, and preflighted calls with non-empty dispositions return `componentization_proposer.behavior_authority_required`. Confirm an ordinary empty-list call keeps its existing result.
- [ ] **Step 2: Run the proposer and Behavior gate suites.** Run `mix test apps/live_frames/test/live_frames/componentization_proposer_test.exs apps/live_frames/test/live_frames/behavior/componentization_decision_test.exs`. Expected: the context API is unavailable and missing-authority input currently has no dedicated gate.
- [ ] **Step 3: Implement the ephemeral handoff.** Add the four-field `BehaviorAuthorityContext` struct with no serializer, persistence API, or runtime consumer. Add `authority_context/3` to `Behavior.ComponentizationDecision`; it validates DesignDocument identity, the Behavior contract, the selected singleton approved review, digest, and review ID. Add `propose_with_behavior_authority_context_internal/3`. Keep existing public calls unchanged for empty dispositions and fail closed for non-empty dispositions without context. The proposer independently revalidates the context; it does not trust its origin.
- [ ] **Step 4: Run focused tests and prove ordinary compatibility.** Run `mix test apps/live_frames/test/live_frames/behavior/componentization_decision_test.exs apps/live_frames/test/live_frames/componentization_proposer_test.exs`. Expected: valid authority reaches the new internal path; missing context fails only for dispositions; ordinary direct proposal behavior is unchanged.
- [ ] **Step 5: Commit.** Commit as `feat: gate dispositions on behavior authority`.

## Task 4: Disposition construction and mechanical guards

**Files:**
- Modify: `apps/live_frames/lib/live_frames/behavior/componentization_decision.ex`
- Modify: `apps/live_frames/lib/live_frames/componentization_proposer/construction.ex`
- Modify: `apps/live_frames/lib/live_frames/componentization_proposer.ex`
- Modify: `apps/live_frames/test/live_frames/behavior/componentization_decision_test.exs`
- Modify: `apps/live_frames/test/live_frames/componentization_proposer_test.exs`

- [ ] **Step 1: Add failing construction tests.** Cover missing target, outside boundary, supported semantic type, non-leaf, missing SourceTrace, empty trace values, type mismatch, source ID mismatch, missing/duplicated Behavior binding, and each Behavior/IR reference role. Fixtures must use synthetic data.
- [ ] **Step 2: Run the focused proposer and Behavior gate suites.** Run `mix test apps/live_frames/test/live_frames/componentization_proposer_test.exs apps/live_frames/test/live_frames/behavior/componentization_decision_test.exs`. Expected: valid candidate construction has no NodeDisposition record or conflict checks.
- [ ] **Step 3: Build records after mechanical gates pass.** Add `Construction.build/3` with the exact context type and retain `/2` for ordinary input. Index the original document once. Require the target to exist inside the selected boundary, have semantic type `raw`, `unsupported`, or `unknown`, be a leaf, and have a SourceTrace with exact non-empty `source_type` and `source_id`. Build one reference index with `binding_owner`, `controlled_target`, `trigger_origin`, `focus_reference`, `ir_interaction_ref`, and `ir_interaction_target` roles. Reject a target if any Behavior owner, controlled target, trigger origin, or non-nil focus reference equals its ID; reject it if its own `interaction_refs` is non-empty or any registered Interaction `target_node_ids` contains its ID. Copy Behavior digest and review ID only from the independently validated context. Sort records by UTF-8 `design_node_id` bytes and evidence refs by Unicode-scalar order.
- [ ] **Step 4: Run the construction suites.** Run the same two test files. Expected: valid candidates produce exact records; every invalid target or reference has a deterministic diagnostic and no authorized record.
- [ ] **Step 5: Commit.** Commit as `feat: construct guarded node dispositions`.

## Task 5: Reference-validation disposition semantics

**Files:**
- Modify: `apps/live_frames/lib/live_frames/componentization_plan.ex`
- Modify: `apps/live_frames/lib/live_frames/componentization_plan/reference_validation.ex`
- Modify: `apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs`

- [ ] **Step 1: Add failing reference tests.** Build `disposition_tuple/0` from a synthetic document with a selected section boundary and one in-boundary `unsupported` leaf with a SourceTrace matching the NodeDisposition source fields. Include one exact Behavior contract with one matching binding and one singleton approved review. Cover exact targets, missing/outside targets, wrong semantic type, changed SourceTrace, Behavior digest/review mismatch, missing/duplicated binding ID, changed BehaviorReviewResult, reference conflicts, duplicate and unused dispositions. For every invalid or absent disposition, assert the original `componentization_plan.unsupported_node` blocker remains.

```elixir
test "an authority-incomplete disposition does not suppress the unsupported blocker" do
  {plan, contract, document} = disposition_tuple()
  assert {:error, diagnostics} = ComponentizationPlan.validate_references(plan, contract, document)
  assert Enum.any?(diagnostics, &(&1.code == "componentization_plan.unsupported_node"))
  assert Enum.any?(diagnostics, &(&1.code == "componentization_plan.node_disposition.behavior_authority_mismatch"))
end
```

- [ ] **Step 2: Run the focused reference suite and confirm failure.** Run `mix test apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs`. Expected: current validation reports every unsupported node and has no authority-aware entry point.
- [ ] **Step 3: Implement indexed validation without deleting unsupported IDs early.** Add the three frozen `/5` APIs from the Interfaces section. Build the original node/boundary index once and retain all `unsupported_node_ids`. Validate every disposition against the original document and Behavior authority. Derive the consumed ID set only after target, source, Behavior, reference, and uniqueness guards pass. Emit the existing unsupported blocker for every target outside that set and verify each valid disposition is consumed once. Do not mutate DesignDocument or rescan it per disposition. Sort diagnostics deterministically.
- [ ] **Step 4: Run all plan tests.** Run `mix test apps/live_frames/test/live_frames/componentization_plan_test.exs apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs apps/live_frames/test/live_frames/componentization_plan/node_disposition_test.exs`. Expected: exact authority passes; invalid or absent authority keeps the blocker visible.
- [ ] **Step 5: Commit.** Commit as `feat: validate source node dispositions against evidence`.

## Task 6: ComponentReviewResult and approval transition

**Files:**
- Create: `apps/live_frames/lib/live_frames/component_review_result.ex`
- Modify: `apps/live_frames/lib/live_frames/component_review.ex`
- Create: `apps/live_frames/test/live_frames/component_review_result_test.exs`
- Modify: `apps/live_frames/test/live_frames/component_review_test.exs`

- [ ] **Step 1: Add failing artifact and transition tests.** Build `disposition_candidate/0` from the same synthetic document, exact NodeDisposition, Behavior contract, and singleton approved Behavior review used by the neighboring proposer fixtures. Use the frozen fixture and canonical JSON literal above. Assert `ComponentReviewResult.encode(fixture)` equals those exact bytes, `byte_size(encoded) == 604`, and `ComponentReviewResult.id(fixture)` equals `crv_1b012f7028cc1b15a4127403e12ed032e3ed6ead16b8c995690f8e12ef1136d7`. Compute and freeze the expected literal independently of the production ID function. Also cover the closed fields; algorithms and digest formats; decision enum; reviewer string; UTC microsecond timestamp; non-empty unique evidence refs; plan/document/contract mismatch; same `contract_id` with different approved contract bytes; and rejection by `approve/3` for a disposition plan.
- [ ] **Step 2: Run focused review tests and confirm the bypass.** Run `mix test apps/live_frames/test/live_frames/component_review_test.exs apps/live_frames/test/live_frames/component_review_result_test.exs`. Expected: the result module is absent and `approve/3` currently returns an approved contract for a valid plan.
- [ ] **Step 3: Implement immutable result bytes and atomic approval.** Add exactly the eleven specified fields. Use `sha-256` for both stored digest algorithms and `lf-component-review-v1-jcs-sha256` for IDs. Encode canonical JSON with exact closed keys and evidence refs sorted by Unicode-scalar order. Derive `crv_` plus lowercase SHA-256 of those bytes. The private construction inside `approve_with_result/8` encodes `ComponentContract` only after `approval_status` becomes `:approved`, hashes those exact bytes, hashes `ComponentizationPlan.encode/1`, and captures the exact document digest. It validates all inputs and Behavior authority, then returns `{approved_contract, matching_result}` only when every step succeeds; there is no public `new_approved/6` bypass. The human review step must examine the cited evidence and confirm that Behavior owns the source runtime responsibility and no independent presentation, content, accessibility, or generated-DOM role is required; the function records the reviewer identity and evidence refs but does not infer those judgments from their strings. If the review cannot affirm those points, do not call this approval operation. Guard `approve/3` on non-empty dispositions and preserve it for empty lists.
- [ ] **Step 4: Run result and review tests.** Run `mix test apps/live_frames/test/live_frames/component_review_result_test.exs apps/live_frames/test/live_frames/component_review_test.exs`. Expected: the fixture matches the frozen 604-byte canonical JSON and ID; stale or same-ID/different-bytes contracts fail; only `approve_with_result/8` can approve a disposition plan. If the serializer differs from the frozen literal, stop with `STOP=COMPONENT_REVIEW_GOLDEN_IDENTITY_MISMATCH`; do not change the golden.
- [ ] **Step 5: Commit.** Commit as `feat: bind component review to exact plan bytes`.

## Task 7: Generation authority gate only

**Files:**
- Modify: `apps/live_frames/lib/live_frames/native_generator.ex`
- Modify: `apps/live_frames/test/live_frames/native_generator_test.exs`

- [ ] **Step 1: Add failing authority-gate tests.** In `native_generator_test.exs`, prove that `generate/3` with non-empty `node_dispositions` returns `native_generator.disposition_authority_required`. Prove that `generate/7` blocks a missing or wrong BehaviorContract; a missing, stale, wrong, or non-approved selected BehaviorReviewResult; a missing or wrong ComponentReviewResult; a wrong selected ComponentReviewResult ID; changed approved ComponentContract bytes; changed plan bytes; and changed DesignDocument identity. For the exact valid authority tuple, assert only `AUTHORITY_GATE=PASS` and `GENERATION_PATH_ENTERED=YES`. Do not assert that the disposed node is omitted from generated HEEx or CSS in this task.
- [ ] **Step 2: Run the focused generation tests and confirm the authority gap.** Run `mix test apps/live_frames/test/live_frames/native_generator_test.exs`. Expected: `/3` does not yet reject disposition-bearing plans with the required diagnostic, and `/7` does not yet validate the exact selected authority tuple.
- [ ] **Step 3: Add the explicit overload and authority checks.** Keep `generate/3` compatible for plans with no dispositions and return `native_generator.disposition_authority_required` for plans that contain them. Implement `generate/7` for the exact seven inputs in the Interfaces section. Recompute Behavior digest and review ID, require singleton approval against the exact contract, bind its document identity, verify each NodeDisposition binding, and validate the ComponentReviewResult ID selector, approved decision, contract ID, approved-contract bytes, plan bytes, and document digest. Authority failures return `:generation_blocked` with no partial artifacts. This task adds no filtered traversal and makes no structural omission claim. Do not add a persisted wrapper.
- [ ] **Step 4: Run the focused generation tests.** Run `mix test apps/live_frames/test/live_frames/native_generator_test.exs`. Expected: ordinary `/3` generation remains available; disposition `/3` blocks; invalid `/7` authority blocks; the exact valid tuple passes the authority gate and enters generation. Do not use output omission as Task 7 acceptance evidence.
- [ ] **Step 5: Commit and check the task boundary.** Commit as `feat: require exact review authority for disposition generation` with only the Task 7 production and test files. Run `git status --porcelain` and require `EMPTY` before Task 8.

## Task 8: Shared FilteredStructure and structural omission

**Files:**
- Create: `apps/live_frames/lib/live_frames/native_generator/filtered_structure.ex`
- Modify: `apps/live_frames/lib/live_frames/native_generator.ex`
- Modify: `apps/live_frames/lib/live_frames/native_generator/style_integration.ex`
- Modify: `apps/live_frames/lib/live_frames/native_generator/renderer.ex`
- Create: `apps/live_frames/test/live_frames/native_generator/filtered_structure_test.exs`
- Modify: `apps/live_frames/test/live_frames/native_generator/style_integration_test.exs`
- Modify: `apps/live_frames/test/live_frames/native_generator_test.exs`
- Create and commit: `apps/live_frames/test/live_frames/native_generator/disposition_end_to_end_test.exs`

- [ ] **Step 1: Add the synthetic end-to-end omission test before FilteredStructure exists.** Use one inert unsupported leaf with a harmless fixture SourceTrace. Assert that the original DesignDocument still contains the node and the plan still contains its NodeDisposition. Supply exact Behavior authority and create the accepted ComponentReviewResult through `ComponentReview.approve_with_result/8` so the Task 7 generation authority gate passes. The test must fail because generation still traverses the unfiltered DesignDocument. Require generated HEEx, generated CSS, state-rule traversal, renderer indexes, and private-class ownership to omit the disposed node. Require supported siblings to remain, including their canonical paths and private identities. Assert that no source payload appears in generated output and no source runtime is executed. Run this test and record the RED before writing FilteredStructure.
- [ ] **Step 2: Add and run the two-disposition structural determinism regression before FilteredStructure implementation.** Use `unsupported_leaf_A`, `unsupported_leaf_B`, and `supported_sibling`. Generate once with caller decision order A,B and once with B,A. Before FilteredStructure, both runs must have valid exact Behavior and ComponentReview authority and pass the generation authority gate. The red reason is that traversals still use the original unfiltered DesignDocument. After Task 8, assert that encoded plan bytes are identical, the authorized disposed set is identical, and generated artifacts are identical. Only A and B are omitted. The supported sibling remains with its original canonical path and private identity.
- [ ] **Step 3: Run the focused structural tests and confirm the FilteredStructure gap.** Run `mix test apps/live_frames/test/live_frames/native_generator/filtered_structure_test.exs apps/live_frames/test/live_frames/native_generator/style_integration_test.exs apps/live_frames/test/live_frames/native_generator_test.exs apps/live_frames/test/live_frames/native_generator/disposition_end_to_end_test.exs`. Expected: the shared view is absent and the synthetic end-to-end assertions fail while exact authority checks pass.
- [ ] **Step 4: Build and share one filtered structure.** `FilteredStructure.build/4` first calls `NodeStyleIdentity.build/2` on the original document to preserve canonical path IDs and private classes. It then removes only validated disposed DesignNode IDs from `nodes_by_id`, `children_by_id`, `root_node_ids`, `path_by_id`, and private-class ownership. Keep order and parentage for included nodes. Never mutate or serialize DesignDocument. Build the ordinary generation view with an empty disposed set. Pass the same `FilteredStructure` value to StyleIntegration and Renderer. Replace direct `node.children` traversals with `FilteredStructure.children/2`. Renderer indexes must include only retained nodes, and `Renderer.build_indexes/5` must read private classes from this view. Never copy or execute source runtime data.
- [ ] **Step 5: Run focused native-generation tests.** Run `mix test apps/live_frames/test/live_frames/native_generator/filtered_structure_test.exs apps/live_frames/test/live_frames/native_generator/style_integration_test.exs apps/live_frames/test/live_frames/native_generator_test.exs apps/live_frames/test/live_frames/native_generator/disposition_end_to_end_test.exs`. Expected: all structural surfaces omit only authorized IDs, both decision orders produce identical output, source payload is absent, and retained siblings keep their original path and private identity.
- [ ] **Step 6: Commit all Task 8 files and check the task boundary.** Commit as `feat: share filtered design structure across generation`, including `disposition_end_to_end_test.exs`. Run `git status --porcelain` and require `EMPTY` before Task 9.

## Task 9: Regression verification

```text
MODE=REGRESSION_VERIFICATION
```

**Files:**
- Modify as needed: `apps/live_frames/test/live_frames/componentization_plan_test.exs`
- Modify as needed: `apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs`
- Modify as needed: `apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs`
- Modify as needed: `apps/live_frames/test/live_frames/componentization_proposer_test.exs`
- Modify as needed: `apps/live_frames/test/live_frames/behavior/componentization_decision_test.exs`
- Modify as needed: `apps/live_frames/test/live_frames/component_review_test.exs`
- Modify as needed: `apps/live_frames/test/live_frames/component_review_result_test.exs`
- Modify as needed: `apps/live_frames/test/live_frames/native_generator_test.exs`
- Modify as needed: `apps/live_frames/test/live_frames/native_generator/style_integration_test.exs`
- Modify as needed: `apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs`
- Modify as needed: `apps/live_frames/test/live_frames/native_generator_v6_proofs_test.exs`
- Modify as needed: `apps/live_frames/test/live_frames/bricks_static_navigation_test.exs`

- [ ] **Step 1: Verify legacy and ordinary API behavior.** Verify historical Plan 1.0.0 canonical bytes and unsupported-node semantics, ordinary no-disposition proposer behavior, and ordinary `NativeGenerator.generate/3` behavior. Verify that stale or forged disposition authority remains blocked and a changed approved ComponentContract with the same `contract_id` remains blocked.
- [ ] **Step 2: Verify multi-disposition determinism.** Rerun the Task 8 caller-order regression. Confirm the same encoded plan bytes, authorized disposed set, and generated artifacts for orders A,B and B,A; confirm only A and B disappear and the supported sibling retains its original canonical path and private identity. This capability already exists after Task 8, so this step does not claim a guaranteed RED.
- [ ] **Step 3: Run the mandatory NAV-CARRIER regression.** NAV-CARRIER is implemented by PR #244 and this test is required. Dispose an unrelated explicit DesignNode ID, then prove the navigable heading retains its heading element and inner anchor, validated static `href`, applicable target attributes, heading root private class and style, and renderer-created anchor styling with `color: inherit` and `text-decoration: inherit`. The filter applies only to explicit disposed DesignNode IDs; it must never treat renderer-created anchor markup as a disposable DesignNode. On any regression, stop with `STOP=NAV_CARRIER_REGRESSION` and do not continue implementation.
- [ ] **Step 4: Run focused regression suites.** Run the plan, proposer, Behavior, ComponentReview, generator, stylesheet, proof, Bricks navigation, and NAV-CARRIER suites named above. Existing tests may already prove a requirement. Add or adjust tests where evidence is missing, but do not change correct production code to manufacture a red phase.
- [ ] **Step 5: Commit test-only hardening and check the task boundary.** If Task 9 adds or changes tests, commit only those tests as `test: cover source node disposition compatibility`. Task 9 owns no production files. If no tests need changes, create no commit. In either case, require `git status --porcelain` to be `EMPTY` before Task 10.

## Task 10: Read-only exact Milan proof

**Ownership:** No production files and no test files. No commit is expected.

- [ ] **Step 1: Rerun the committed Task 8 synthetic regression and focused accepted suites.** Run:

```sh
mix test apps/live_frames/test/live_frames/native_generator/disposition_end_to_end_test.exs apps/live_frames/test/live_frames/native_generator_test.exs apps/live_frames/test/live_frames/component_review_test.exs apps/live_frames/test/live_frames/component_review_result_test.exs
mix test apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs apps/live_frames/test/live_frames/native_generator/style_integration_test.exs apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs apps/live_frames/test/live_frames/native_generator_v6_proofs_test.exs apps/live_frames/test/live_frames/bricks_static_navigation_test.exs
```

Record sanitized pass/fail results and accepted identities only.
- [ ] **Step 2: Run the exact local Milan proof without changing its source.** Use only the resolved DesignDocument whose SHA-256 is `1fdc6e859bdb624f0931106f78a46b25baae89f807b6bfc7ba3e14ee79da1045`, Behavior binding `bnd_fd4b72a566b2c38f00f5396bfc0f2c26453d49a1c19290dfe9dec2a67ee78fe4`, Behavior contract digest `5d2b37acbfa357a66357bf7ea09ce21f15353702d85a5d202f275dcb6794a344`, Behavior review ID `brv_d19b80b64c3e3281a42ae6763ea95877b45e2728c9a29f89a220777e8b45d2dd`, target `node_000001_000002`, and source ID `2265d2`. Recompute each identity. Require the target remains present and unchanged, has semantic type `unsupported`, and has a matching SourceTrace. Use reviewer-supplied identity, timestamp, and evidence refs for ComponentReviewResult; never invent those values. Generate only through `/7`. Confirm the unsupported blocker clears only for this validated target; generated HTML/CSS contain no source code element or source JavaScript; the generator does not execute source input; and all other Design IR nodes retain expected markup, classes, and styles. Keep all proof output local and read-only.
- [ ] **Step 3: Record proof status.** Record sanitized pass/fail and accepted identities only. Do not commit private Milan evidence or create generated proof artifacts in the repository. Do not fix production defects or modify tests in Task 10. If the proof exposes a defect, stop with `STOP=MILAN_PROOF_IMPLEMENTATION_DEFECT` and return to the exact earlier task/module that owns it.

## Failure and risk coverage

| Failure or risk | Required test/task |
| --- | --- |
| Wrong Plan version; non-empty 1.0.0 dispositions; historical bytes or semantics drift | Task 1 golden fixtures; Task 9 legacy regression |
| Wrong/missing node ID; outside boundary; wrong semantic type; non-leaf; missing SourceTrace; source type/ID mismatch | Tasks 4 and 5 |
| Duplicate disposition; unknown outcome; unused disposition | Tasks 1, 4, and 5 |
| Missing/duplicated Behavior binding; owner, controlled target, trigger origin, focus, or IR interaction reference conflicts | Tasks 4 and 5 |
| Behavior contract digest changes; BehaviorReviewResult changes or loses singleton approval | Tasks 3, 5, and 7 |
| Same `contract_id` with changed approved ComponentContract bytes | Tasks 6 and 7 |
| Plan bytes, DesignDocument identity, ComponentReviewResult content, or selected result ID changes | Tasks 6 and 7 |
| Source runtime copied or executed | Task 8 synthetic output check and Task 10 proof; no execution or copy path is added |
| Disposed node still emits CSS, state rules, HEEx, renderer index, or private class | Tasks 8 through 10 |
| Style and renderer use different structures | Task 8 passes the same `FilteredStructure`; Task 9 checks every traversal |
| NAV-CARRIER renderer-created structure is filtered or rewritten | Task 9 mandatory regression |
| ComponentReviewResult canonical bytes or ID drift | Task 6 frozen literal, byte count, and independently computed ID |
| Task files leak across commit boundaries | Task-boundary invariant after every Task 1–9 commit |
| Ordinary callers or historical 1.0.0 plans regress | Tasks 1, 3, 7, and 9 |

Every ambiguous or unlisted authority state fails closed. No target is silently dropped because it disappeared, became supported, moved, changed source identity, or failed to be consumed exactly once.

## Review focus

| Review question | Tests that must answer it |
| --- | --- |
| Can a forged or stale disposition suppress an unsupported-node blocker? | `componentization_plan_reference_validation_test.exs`: mismatched Behavior context, changed source identity, duplicate, unused, and no-context cases retain `componentization_plan.unsupported_node`. |
| Do historical 1.0.0 canonical bytes and semantics remain unchanged? | `componentization_plan_test.exs`: two literal 1.0.0 byte goldens with no `node_dispositions` key; reference tests retain the old unsupported blocker. |
| Does the same `contract_id` with different approved contract bytes invalidate ComponentReviewResult? | `component_review_result_test.exs`: alter an encoded approved-contract field while keeping the ID; `validate_against/4` fails. |
| Do ComponentReviewResult canonical bytes and ID match the frozen independent golden? | `component_review_result_test.exs`: assert the literal bytes, `byte_size == 604`, and the frozen `crv_...` value. |
| Does every native-generation traversal use the same filtered structure? | `filtered_structure_test.exs`, `native_generator_test.exs`, and `style_integration_test.exs`: child list, index, path/class maps, CSS, state rules, and HEEx omit the same target. |
| Do two disposition decision orders produce one canonical plan and identical output? | `disposition_end_to_end_test.exs`: compare A,B and B,A plan bytes, authorized sets, and artifacts; only A and B are absent and the sibling's original path and private identity remain. |
| Do direct proposer/generator APIs fail only when dispositions lack exact authority, while ordinary callers continue to work? | `componentization_proposer_test.exs`, `behavior/componentization_decision_test.exs`, and `native_generator_test.exs`: no-context disposition calls fail closed; empty-list calls preserve prior behavior. |
| Does filtering preserve implemented NAV-CARRIER markup and styling? | Task 9 tests retain the heading, inner anchor, validated static `href`, applicable target attributes, heading root class/style, and anchor rules `color: inherit` and `text-decoration: inherit` when an unrelated DesignNode is disposed. |

## Performance and scaling

```text
DATA_LAYER=COLD_COMPILE_REVIEW_GENERATION_TIME
VALIDATION_COMPLEXITY_TARGET=O(IR nodes + Behavior references + dispositions)
INDEX_ONCE=YES
TREE_RESCAN_PER_DISPOSITION=NO
ETS=N/A
CACHEX=N/A
REDIS=N/A
POSTGRES=N/A
PGBouncer=N/A
READ_REPLICA=N/A
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
RUNTIME_POLLING=0
PUBSUB=N/A
GENSERVER=N/A
OBAN=N/A
```

Build node, boundary, and Behavior-reference indexes once. Never rescan the DesignDocument per disposition. Build the filtered view once and pass that same immutable value to StyleIntegration and Renderer. No runtime infrastructure is part of this change.

## Global implementation restrictions

Do not add a general `ignore_unsupported` flag, generic exclusion switch, Milan/source-ID allowlist, Bricks code-element allowlist, DesignDocument deletion or mutation, source runtime execution, translation, or copying, provenance text as authority, optional NodeDisposition metadata, or Behavior semantics duplicated in NodeDisposition. Preserve the original DesignDocument unchanged. Never execute or copy source runtime data. Do not start Feature Milan A1 or real P7-D0. Do not add runtime Redis, Postgres, PubSub, GenServer, polling, or a new dependency. Do not add children-hoisting, subtree removal, a second review lifecycle on ComponentizationPlan, a serialized BehaviorAuthorityContext, or a persisted generation-authority wrapper.

## Stop conditions

Execution stops without broadening the architecture if any condition below occurs:

```text
STOP=MAIN_MOVED
STOP=SPEC_CHANGED
STOP=IMPLEMENTATION_AUTHORITY_CONFLICT
STOP=PLAN_1_0_0_CANONICAL_DRIFT
STOP=PLAN_VERSION_COMPATIBILITY_FAILURE
STOP=BEHAVIOR_AUTHORITY_BYPASS_REQUIRED
STOP=COMPONENT_REVIEW_EXACT_IDENTITY_UNAVAILABLE
STOP=DESIGN_DOCUMENT_MUTATION_REQUIRED
STOP=SOURCE_RUNTIME_EXECUTION_REQUIRED
STOP=SOURCE_RUNTIME_COPY_REQUIRED
STOP=FILTERED_STRUCTURE_NOT_SHARED
STOP=NAV_CARRIER_REGRESSION
STOP=TASK_BOUNDARY_WORKTREE_DIRTY
STOP=COMPONENT_REVIEW_GOLDEN_IDENTITY_MISMATCH
STOP=MILAN_PROOF_IMPLEMENTATION_DEFECT
STOP=MILAN_RESOLVED_IDENTITY_MISMATCH
STOP=MILAN_BEHAVIOR_IDENTITY_MISMATCH
STOP=UNEXPECTED_PUBLIC_API_BREAK_REQUIRED
STOP=NEW_DEPENDENCY_REQUIRED
```

## Verification strategy

Tasks 1–8 start each new production behavior with a focused failing ExUnit test. The red reason must match that task's missing capability. Each task implements only its assigned behavior, reruns its focused suite, runs neighboring suites, commits its owned files, and leaves a clean worktree.

Task 7 proves only the generation authority gate. It does not prove structural omission. Task 8 owns the synthetic end-to-end omission test and multi-disposition structural determinism test, adds them before FilteredStructure implementation, and commits both with the shared view implementation. Task 9 is regression verification. Its tests may already pass when Tasks 1–8 are correct, and it must not manufacture a red phase by changing correct production code. Task 10 is read-only proof work with no production or test ownership and normally no commit.

After every Task 1–9 commit, require `git status --porcelain` to print nothing. Stop with `STOP=TASK_BOUNDARY_WORKTREE_DIRTY` before starting another task if the worktree is not clean. Do not start a later task while a focused or relevant broader suite fails.

```sh
mix test apps/live_frames/test/live_frames/componentization_plan_test.exs apps/live_frames/test/live_frames/componentization_plan/node_disposition_test.exs
mix test apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs
mix test apps/live_frames/test/live_frames/componentization_proposer_test.exs apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs
mix test apps/live_frames/test/live_frames/behavior/componentization_decision_test.exs
mix test apps/live_frames/test/live_frames/component_review_test.exs apps/live_frames/test/live_frames/component_review_result_test.exs
mix test apps/live_frames/test/live_frames/native_generator_test.exs apps/live_frames/test/live_frames/native_generator/filtered_structure_test.exs apps/live_frames/test/live_frames/native_generator/style_integration_test.exs apps/live_frames/test/live_frames/native_generator/disposition_end_to_end_test.exs
mix test apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs apps/live_frames/test/live_frames/native_generator_v6_proofs_test.exs apps/live_frames/test/live_frames/bricks_static_navigation_test.exs
```

Before implementation review, run all repository gates from the exact final implementation head:

```sh
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix assets.build
mix test
mix deps.unlock --check-unused
git diff --check
```

CI must pass on the exact final implementation head before merge consideration. This plan does not authorize a merge.

## Plan self-review

Tasks 1–6 own the versioned plan schema, semantic input, Behavior authority handoff, guarded construction, reference validation, and exact ComponentReview approval transition. Task 7 owns the generation authority gate only. Task 8 owns the shared FilteredStructure, synthetic end-to-end omission, and multi-disposition structural determinism. Task 9 verifies historical behavior, ordinary APIs, stale authority rejection, and mandatory NAV-CARRIER compatibility. Task 10 owns read-only Milan proof only.

Tasks 1–8 require a focused failing test for each new production behavior, with a red reason tied to the missing capability. Task 9 may already be green and requires no artificial failure. Task 10 adds no code or tests. The Task 8 end-to-end test is not assigned to Task 7 or Task 10. Task 9 has no production file ownership. Task-boundary cleanliness is required after each Task 1–9 commit.

The ComponentReviewResult fixture includes the exact frozen canonical JSON literal, 604-byte length, and ID computed independently from that literal. The plan records PR #244's NAV-CARRIER implementation and requires an unconditional regression. Every Review Focus item maps to assertions and test files. The named interfaces match across task ownership. The accepted spec remains unchanged. This document contains no implementation code.

```text
TASK7_SCOPE=GENERATION_AUTHORITY_ONLY
END_TO_END_TEST_OWNER=TASK_8
MULTI_DISPOSITION_STRUCTURAL_TEST_OWNER=TASK_8
TASK7_TASK8_SEQUENCE_CONSISTENT=YES
NO_CROSS_TASK_DIRTY_FILE=YES

TASK9_MODE=REGRESSION_VERIFICATION
TASK9_FALSE_RED_REQUIREMENT_REMOVED=YES
TASK10_MODE=READ_ONLY_MILAN_PROOF
TASK10_CODE_OR_TEST_OWNERSHIP=NONE

TASK_BOUNDARY_WORKTREE_CLEAN_REQUIRED=YES
TASK_BOUNDARY_DIRTY_STOP_DEFINED=YES

NAV_CARRIER_CURRENT_IMPLEMENTATION_ACKNOWLEDGED=YES
NAV_CARRIER_REGRESSION_MANDATORY=YES

COMPONENT_REVIEW_GOLDEN_LITERAL_DEFINED=YES
COMPONENT_REVIEW_GOLDEN_CANONICAL_BYTES=604
COMPONENT_REVIEW_GOLDEN_BYTES=604
COMPONENT_REVIEW_GOLDEN_ID=crv_1b012f7028cc1b15a4127403e12ed032e3ed6ead16b8c995690f8e12ef1136d7

TDD_TASKS_1_TO_8_DEFINED=YES
SPEC_COVERAGE_GAPS=NONE
STEP_GRANULARITY=ONE_REVIEWABLE_CHANGE_PER_TASK
INTERFACE_INCONSISTENCIES=NONE
UNTESTED_REVIEW_FOCUS_ITEMS=NONE
PLAN_CODE_PROPORTION=PLAN_ONLY
```
