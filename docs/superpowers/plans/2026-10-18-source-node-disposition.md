# SourceNodeDisposition 1.1.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the accepted SourceNodeDisposition 1.1.0 authority so an exactly reviewed source-runtime carrier may remain as Design IR evidence while being omitted from generated structure without weakening unsupported-node fail-closed behavior.

**Architecture:** SourceNodeDisposition decisions enter through SemanticInput, receive exact Behavior authority through Behavior.ComponentizationDecision and an ephemeral BehaviorAuthorityContext, become deterministic ComponentizationPlan 1.1.0 NodeDisposition records, receive an exact ComponentReviewResult, and are revalidated before one shared filtered native-generation structural view is used by styling and rendering.

**Tech Stack:** Elixir, Phoenix/HEEx generation, ExUnit, deterministic JSON serializers.

**Spec:** `docs/superpowers/specs/2026-10-18-source-node-disposition-design.md`

---

## Base and authority gate

Fetch `origin/main` and stop if its commit or tree differs from the accepted base. Do not rebase automatically.

```text
BASE_SHA=f5dcaf534db675b16fe1a4fa90e347cb96f42c40
BASE_TREE=443ca2e1e371ad05e0b0144b307860986629b849
BASE_CI_RUN=39111159407
BASE_CI_RESULT=success
PR243_APPROVED_HEAD=33a54d0c048d8479a8ec5851ac3d40d5e0907ca3
PR243_MERGE_SHA=f5dcaf534db675b16fe1a4fa90e347cb96f42c40
```

The plan was authored against this exact main tree. At implementation start, recheck the base, the primary spec, and the accepted authority files. A changed main, changed spec, or material authority conflict stops execution.

The repository names the accepted native-generation authority `docs/development/c09d6_native_generation_authority.md`; the name in the request included an extra `_and_review`. Use the file that exists in the accepted tree. Preserve these authorities without editing them:

- `docs/development/c09d3_componentization_plan_authority.md`
- `docs/development/c09d5_componentization_proposer_authority.md`
- `docs/development/p7_interaction_conversion_implementation_plan.md`
- `docs/development/c09d6_native_generation_authority.md`
- `docs/development/nav_carrier_heading_link_representation_authority.md`

The Plan field and generation inputs apply only to the accepted SourceNodeDisposition capability. Keep `NativeGenerator.generate/3` for plans without dispositions. The disposition-aware overload must not change NAV-CARRIER markup, navigation validation, renderer-created anchor styling, or the existing C09D6 rules for ordinary generation.

At this base, NAV-CARRIER is accepted authority but its heading carrier is not implemented in the renderer or style integration. The implementation must filter only explicitly authorized DesignNode IDs. If NAV-CARRIER code exists when execution reaches Task 9, add a regression proving that filtering another DesignNode leaves the renderer-created heading anchor and its bounded style rule intact. If it remains absent, record the cross-lane compatibility gate and do not invent NAV-CARRIER behavior in this work.

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

`ComponentReviewResult` has no public constructor or approval operation. `ComponentReview.approve_with_result/8` is the only supported operation that creates an approved result, and it creates it in the same transition that returns the matching approved contract.

`SourceNodeDispositionDecision` is the nested module shown in the Interfaces block. `SemanticInput` adds only `source_node_dispositions` to its struct and repeatable-family list; it remains transient and has no serializer or persistence API. Its four decision fields are closed, and Behavior digest/review identity fields are rejected as unknown fields.

`BehaviorAuthorityContext` has `serialization=NONE`, `persistence=NONE`, and `runtime_presence=NONE`. It is ordinary data, not an unforgeable capability. The context-aware proposer recalculates the Behavior contract digest and review ID, checks singleton approval against that contract, checks the contract's DesignDocument identity, and checks every requested binding ID for exactly one match.

`ComponentizationPlan.current_format_version/0` and the default for new plans become `"1.1.0"`. Explicit `"1.0.0"` plans remain valid with their historical schema and behavior. Existing `validate_references/3`, `validate_generation_prerequisites/3`, and `validate_for_generation/3` continue to accept ordinary plans. For a 1.1.0 plan with dispositions, those APIs emit `componentization_plan.node_disposition.behavior_authority_mismatch` and retain `componentization_plan.unsupported_node` for every unconsumed unsupported target. The three authority-aware `/5` APIs are required to validate a disposition-bearing plan successfully.

`ComponentizationPlan.t` adds `node_dispositions: [NodeDisposition.t()]`, and the struct defaults that field to `[]`. Sort the list by ascending UTF-8 `design_node_id` bytes; sort each disposition's `evidence_refs` by ascending Unicode-scalar order.

`ComponentReview.approve/3` remains compatible for plans without dispositions. It returns `component_contract.approval_blocked` without changing the candidate when `node_dispositions` is non-empty. `approve_with_result/8` is the only approval operation for a disposition-bearing plan. It validates the candidate, exact plan, document, Behavior contract, selected Behavior review, and review evidence; derives the approved contract; hashes that approved contract's encoded bytes; hashes the exact plan bytes and document identity; creates the approved ComponentReviewResult; and returns the approved contract and result together. It never hashes the proposed contract.

`NativeGenerator.generate/3` remains the ordinary path and returns `:generation_blocked` with `native_generator.disposition_authority_required` for a disposition-bearing plan. `generate/7` is the disposition-aware path. It verifies the supplied Behavior and Component review identities and all exact digests before building the filtered structure. Any selected ComponentReviewResult ID, decision, contract-byte, plan-byte, or document-digest mismatch returns `native_generator.component_review_authority_mismatch`. It accepts one selected result and never searches review history. There is no persisted generation-authority wrapper.

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
| `apps/live_frames/test/live_frames/native_generator/disposition_end_to_end_test.exs` | Prove the synthetic SemanticInput-to-generation authority path preserves source IR and omits the authorized carrier from generated HTML and CSS. |

Use `behavior/componentization_decision_test.exs` for BehaviorAuthorityContext tests. Its existing fixtures construct exact contracts, approved singleton reviews, and resolved DesignDocuments.

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

- [ ] **Step 1: Add failing artifact and transition tests.** Build `disposition_candidate/0` from the same synthetic document, exact NodeDisposition, Behavior contract, and singleton approved Behavior review used by the neighboring proposer fixtures. Cover the closed fields; algorithms and digest formats; decision enum; reviewer string; UTC microsecond timestamp; non-empty unique evidence refs; exact canonical bytes; deterministic `crv_` ID; plan/document/contract mismatch; and same `contract_id` with different approved contract bytes. Assert `approve/3` cannot approve a disposition plan.
- [ ] **Step 2: Run focused review tests and confirm the bypass.** Run `mix test apps/live_frames/test/live_frames/component_review_test.exs apps/live_frames/test/live_frames/component_review_result_test.exs`. Expected: the result module is absent and `approve/3` currently returns an approved contract for a valid plan.
- [ ] **Step 3: Implement immutable result bytes and atomic approval.** Add exactly the eleven specified fields. Use `sha-256` for both stored digest algorithms and `lf-component-review-v1-jcs-sha256` for IDs. Encode canonical JSON with exact closed keys and evidence refs sorted by Unicode-scalar order. Derive `crv_` plus lowercase SHA-256 of those bytes. The private construction inside `approve_with_result/8` encodes `ComponentContract` only after `approval_status` becomes `:approved`, hashes those exact bytes, hashes `ComponentizationPlan.encode/1`, and captures the exact document digest. It validates all inputs and Behavior authority, then returns `{approved_contract, matching_result}` only when every step succeeds; there is no public `new_approved/6` bypass. The human review step must examine the cited evidence and confirm that Behavior owns the source runtime responsibility and no independent presentation, content, accessibility, or generated-DOM role is required; the function records the reviewer identity and evidence refs but does not infer those judgments from their strings. If the review cannot affirm those points, do not call this approval operation. Guard `approve/3` on non-empty dispositions and preserve it for empty lists.
- [ ] **Step 4: Run result and review tests.** Run `mix test apps/live_frames/test/live_frames/component_review_result_test.exs apps/live_frames/test/live_frames/component_review_test.exs`. Expected: canonical bytes and ID match goldens; stale or same-ID/different-bytes contracts fail; only `approve_with_result/8` can approve a disposition plan.
- [ ] **Step 5: Commit.** Commit as `feat: bind component review to exact plan bytes`.

## Task 7: Disposition-aware generation authority gate

**Files:**
- Modify: `apps/live_frames/lib/live_frames/native_generator.ex`
- Modify: `apps/live_frames/test/live_frames/native_generator_test.exs`
- Create: `apps/live_frames/test/live_frames/native_generator/disposition_end_to_end_test.exs`

- [ ] **Step 1: Add failing generation and end-to-end tests.** In `native_generator_test.exs`, cover missing Behavior contract, missing/stale selected BehaviorReviewResult, invalid singleton approval, wrong Behavior digest, missing ComponentReviewResult, wrong selected content ID, unapproved result, wrong contract digest with the same `contract_id`, changed plan bytes, and changed DesignDocument. In `disposition_end_to_end_test.exs`, build an inert unsupported leaf with fixture SourceTrace, drive it through SemanticInput and the Behavior-aware proposer, approve it with `approve_with_result/8`, and assert the proposed `/7` call preserves the source node in DesignDocument while omitting it from both HEEx and CSS. This is also Task 10's synthetic acceptance regression. Record its red result before implementing `/7`.
- [ ] **Step 2: Run the focused generator suites and confirm the API gap.** Run `mix test apps/live_frames/test/live_frames/native_generator_test.exs apps/live_frames/test/live_frames/native_generator/disposition_end_to_end_test.exs`. Expected: `/3` has no explicit review inputs and `/7` is undefined, so the authority and end-to-end assertions fail.
- [ ] **Step 3: Add the explicit overload.** Keep `generate/3` for empty disposition lists and return `native_generator.disposition_authority_required` for non-empty lists. Implement `generate/7` for the exact seven inputs in the Interfaces section. Recompute Behavior digest and review ID, require singleton approval against the exact contract, bind its document identity, verify each NodeDisposition binding, and validate the ComponentReviewResult ID selector, approved decision, contract ID, approved-contract bytes, plan bytes, and document digest before filtering. Authority failures return `:generation_blocked` with no partial artifacts. Do not add a persisted wrapper.
- [ ] **Step 4: Run generation and review tests.** Run `mix test apps/live_frames/test/live_frames/native_generator_test.exs apps/live_frames/test/live_frames/native_generator/disposition_end_to_end_test.exs apps/live_frames/test/live_frames/component_review_result_test.exs apps/live_frames/test/live_frames/component_review_test.exs`. Expected: ordinary `/3` generation remains available; disposition `/3` blocks; exact `/7` authority passes and stale authority blocks.
- [ ] **Step 5: Commit.** Commit as `feat: require exact review authority for disposition generation` with only the Task 7 implementation and `native_generator_test.exs`; leave `disposition_end_to_end_test.exs` uncommitted for Task 10's separate test commit.

## Task 8: Shared filtered structural view

**Files:**
- Create: `apps/live_frames/lib/live_frames/native_generator/filtered_structure.ex`
- Modify: `apps/live_frames/lib/live_frames/native_generator.ex`
- Modify: `apps/live_frames/lib/live_frames/native_generator/style_integration.ex`
- Modify: `apps/live_frames/lib/live_frames/native_generator/renderer.ex`
- Create: `apps/live_frames/test/live_frames/native_generator/filtered_structure_test.exs`
- Modify: `apps/live_frames/test/live_frames/native_generator/style_integration_test.exs`
- Modify: `apps/live_frames/test/live_frames/native_generator_test.exs`

- [ ] **Step 1: Add failing shared-view tests.** Define `filtered_fixture/0` as a synthetic document whose boundary is at `[1]`, with supported siblings at `[1,1]` and `[1,3]` and a SourceTrace-bearing unsupported leaf at `[1,2]`. Assert that the view excludes exactly the authorized ID from `nodes_by_id`, `children_by_id`, private-class ownership, CSS, state-rule traversal, renderer indexes, and HEEx. Assert the later sibling keeps the private class derived from its original Design IR path.

```elixir
test "filtered structure omits only the authorized ID and keeps original paths" do
  {document, boundary_id, disposed_id, survivor_id, contract} = filtered_fixture()
  assert {:ok, view} =
           FilteredStructure.build(
             document,
             boundary_id,
             MapSet.new([disposed_id]),
             Renderer.package_root_class(contract)
           )
  refute Map.has_key?(view.nodes_by_id, disposed_id)
  assert survivor_id in view.children_by_id[view.boundary_node_id]
  assert view.path_by_id[survivor_id] == [1, 3]
end
```

- [ ] **Step 2: Run the focused structural and generation tests and confirm failure.** Run `mix test apps/live_frames/test/live_frames/native_generator/filtered_structure_test.exs apps/live_frames/test/live_frames/native_generator/style_integration_test.exs apps/live_frames/test/live_frames/native_generator_test.exs`. Expected: the helper is absent and current traversals read DesignNode children directly.
- [ ] **Step 3: Build one view after authority validation.** `FilteredStructure.build/4` first calls `NodeStyleIdentity.build/2` on the original document, preserving canonical path IDs and private classes. It then removes only the IDs in the validated set from `nodes_by_id`, `children_by_id`, `root_node_ids`, `path_by_id`, and private-class ownership. It retains order and parentage for included nodes. It never mutates or serializes DesignDocument. The ordinary generator path builds the same view with an empty set. Pass this exact view to StyleIntegration and Renderer. Replace their direct `node.children` walks with `FilteredStructure.children/2`; renderer indexes contain only included nodes. `Renderer.build_indexes/5` reads private classes from this view and does not accept a second class map.
- [ ] **Step 4: Run focused native-generation tests.** Run `mix test apps/live_frames/test/live_frames/native_generator/filtered_structure_test.exs apps/live_frames/test/live_frames/native_generator/style_integration_test.exs apps/live_frames/test/live_frames/native_generator_test.exs apps/live_frames/test/live_frames/native_generator/disposition_end_to_end_test.exs`. Expected: no disposed node markup, CSS, state traversal, renderer index, or class remains; retained siblings keep original path identity.
- [ ] **Step 5: Commit.** Commit as `feat: share filtered design structure across generation`, staging only Task 8 files and leaving `disposition_end_to_end_test.exs` out for Task 10.

## Task 9: Historical, authority, and cross-feature regressions

**Files:**
- Modify: `apps/live_frames/test/live_frames/componentization_plan_test.exs`
- Modify: `apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs`
- Modify: `apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs`
- Modify: `apps/live_frames/test/live_frames/componentization_proposer_test.exs`
- Modify: `apps/live_frames/test/live_frames/behavior/componentization_decision_test.exs`
- Modify: `apps/live_frames/test/live_frames/component_review_test.exs`
- Modify: `apps/live_frames/test/live_frames/native_generator_test.exs`
- Modify: `apps/live_frames/test/live_frames/native_generator/style_integration_test.exs`

- [ ] **Step 1: Add failing multi-disposition integration regressions.** Use two unsupported leaves and one supported sibling. Construct decisions in both caller orders and prove encoded plans and generated artifacts match, only the two target IDs disappear, the supported sibling retains markup/styles, and no source payload is emitted. Add direct API/no-disposition compatibility assertions to the existing suites.
- [ ] **Step 2: Run all focused suites and confirm the combined case fails before any correction.** Run:

```sh
mix test apps/live_frames/test/live_frames/componentization_plan_test.exs apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs
mix test apps/live_frames/test/live_frames/componentization_proposer_test.exs apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs
mix test apps/live_frames/test/live_frames/behavior/componentization_decision_test.exs
mix test apps/live_frames/test/live_frames/component_review_test.exs apps/live_frames/test/live_frames/component_review_result_test.exs
mix test apps/live_frames/test/live_frames/native_generator_test.exs apps/live_frames/test/live_frames/native_generator/style_integration_test.exs apps/live_frames/test/live_frames/native_generator/disposition_end_to_end_test.exs
```

Expected: the new two-target assertions expose any ordering or shared-view gap; all listed suites pass after the smallest correction in an earlier owner.
- [ ] **Step 3: Check NAV-CARRIER state.** Read `docs/development/nav_carrier_heading_link_representation_authority.md` and inspect its production owners and tests. If implementation exists by this step, add a regression proving a neighboring disposed DesignNode does not remove or rewrite the renderer-created heading anchor, heading root class/styles, safe `href`, or direct-child `color: inherit` and `text-decoration: inherit` rule. If absent, record the cross-lane compatibility gate. Do not change NAV-CARRIER implementation.
- [ ] **Step 4: Rerun the focused suites and commit.** Run all five command groups from Step 2. Expected: zero failures, including the NAV-CARRIER gate where applicable. Commit as `test: cover source node disposition compatibility`, staging Task 9 files but leaving `disposition_end_to_end_test.exs` for Task 10.

## Task 10: Synthetic proof and exact Milan local proof

**Files:**
- Commit the synthetic test created in Task 7: `apps/live_frames/test/live_frames/native_generator/disposition_end_to_end_test.exs`
- Read only: the authorized local Feature Milan resolved DesignDocument and its approved Behavior authority.
- Do not create or commit private evidence, imported source, generated artifacts, or local proof output.

- [ ] **Step 1: Rerun the synthetic end-to-end regression proven red in Task 7 before implementation.** Use its synthetic DesignDocument with one inert unsupported leaf carrying a harmless fixture SourceTrace. Drive it through SemanticInput, the Behavior-aware proposer, `ComponentReview.approve_with_result/8`, and `NativeGenerator.generate/7`. Assert DesignDocument retains the node and the plan records it; output HEEx/CSS contain no target representation or source payload; and all other supported nodes remain in output.
- [ ] **Step 2: Run the focused proof suite.** Run `mix test apps/live_frames/test/live_frames/native_generator/disposition_end_to_end_test.exs apps/live_frames/test/live_frames/native_generator_test.exs`. Expected: the acceptance test is green after Tasks 1–9. Its TDD sequence began with the red run in Task 7 before `/7` was implemented.
- [ ] **Step 3: Run the exact local Milan proof without changing its source.** Use only the resolved DesignDocument whose SHA-256 is `1fdc6e859bdb624f0931106f78a46b25baae89f807b6bfc7ba3e14ee79da1045`, Behavior binding `bnd_fd4b72a566b2c38f00f5396bfc0f2c26453d49a1c19290dfe9dec2a67ee78fe4`, Behavior contract digest `5d2b37acbfa357a66357bf7ea09ce21f15353702d85a5d202f275dcb6794a344`, Behavior review ID `brv_d19b80b64c3e3281a42ae6763ea95877b45e2728c9a29f89a220777e8b45d2dd`, target `node_000001_000002`, and source ID `2265d2`. Recompute each identity. Require the target remains present and unchanged, has semantic type `unsupported`, and has a matching SourceTrace. Use reviewer-supplied identity, timestamp, and evidence refs for ComponentReviewResult; never invent those values. Generate only through `/7`. Confirm the old unsupported blocker disappears only for this validated target, generated HTML/CSS contain no source code element or source JavaScript, the generator did not execute source input, and all other Design IR nodes retain expected markup, classes, and styles. Keep proof output local and read-only.
- [ ] **Step 4: Run synthetic and focused integration tests.** Run `mix test apps/live_frames/test/live_frames/native_generator/disposition_end_to_end_test.exs apps/live_frames/test/live_frames/native_generator_test.exs apps/live_frames/test/live_frames/component_review_test.exs apps/live_frames/test/live_frames/component_review_result_test.exs`. Expected: all tests pass and no private Milan source bytes enter the repository.
- [ ] **Step 5: Record readiness evidence and commit the synthetic acceptance test.** Record only pass/fail and authorized identity digests in the PR report; do not commit private source data or exact-source proof output. Commit `disposition_end_to_end_test.exs` separately as `test: prove reviewed carrier omission end to end`.

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
| Source runtime copied or executed | Tasks 9 and 10 synthetic output checks; no eval or execution path is added |
| Disposed node still emits CSS, state rules, HEEx, renderer index, or private class | Tasks 8 through 10 |
| Style and renderer use different structures | Task 8 passes the same `FilteredStructure`; Task 9 checks every traversal |
| NAV-CARRIER renderer-created structure is filtered or rewritten | Task 9 cross-lane gate and conditional regression |
| Ordinary callers or historical 1.0.0 plans regress | Tasks 1, 3, 7, and 9 |

Every ambiguous or unlisted authority state fails closed. No target is silently dropped because it disappeared, became supported, moved, changed source identity, or failed to be consumed exactly once.

## Review focus

| Review question | Tests that must answer it |
| --- | --- |
| Can a forged or stale disposition suppress an unsupported-node blocker? | `componentization_plan_reference_validation_test.exs`: mismatched Behavior context, changed source identity, duplicate, unused, and no-context cases retain `componentization_plan.unsupported_node`. |
| Do historical 1.0.0 canonical bytes and semantics remain unchanged? | `componentization_plan_test.exs`: two literal 1.0.0 byte goldens with no `node_dispositions` key; reference tests retain the old unsupported blocker. |
| Does the same `contract_id` with different approved contract bytes invalidate ComponentReviewResult? | `component_review_result_test.exs`: alter an encoded approved-contract field while keeping the ID; `validate_against/4` fails. |
| Does every native-generation traversal use the same filtered structure? | `filtered_structure_test.exs`, `native_generator_test.exs`, and `style_integration_test.exs`: child list, index, path/class maps, CSS, state rules, and HEEx omit the same target. |
| Do direct proposer/generator APIs fail only when dispositions lack exact authority, while ordinary callers continue to work? | `componentization_proposer_test.exs`, `behavior/componentization_decision_test.exs`, and `native_generator_test.exs`: no-context disposition calls fail closed; empty-list calls preserve prior behavior. |

## Performance and scaling

```text
DATA_LAYER=COLD_COMPILE_REVIEW_GENERATION_TIME
ETS=N/A
CACHEX=N/A
REDIS=N/A
POSTGRES=N/A
PGBouncer=N/A
READ_REPLICA=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
RUNTIME_POLLING=0
```

Target validation complexity is `O(IR nodes + Behavior references + dispositions)`. Build node, boundary, and Behavior-reference indexes once. Never rescan the DesignDocument per disposition. Build the filtered view once and pass that same immutable value to StyleIntegration and Renderer. No runtime infrastructure is part of this change.

## Global implementation restrictions

Do not add a general `ignore_unsupported` flag, generic exclusion switch, Milan/source-ID allowlist, Bricks code-element allowlist, DesignDocument deletion or mutation, source JavaScript execution/translation/copy-through, provenance text as authority, optional NodeDisposition metadata, or Behavior semantics duplicated in NodeDisposition. Do not start Feature Milan A1 or real P7-D0. Do not add runtime Redis, Postgres, PubSub, GenServer, polling, or a new dependency. Do not add children-hoisting, subtree removal, a second review lifecycle on ComponentizationPlan, a serialized BehaviorAuthorityContext, or a persisted generation-authority wrapper.

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
STOP=MILAN_RESOLVED_IDENTITY_MISMATCH
STOP=MILAN_BEHAVIOR_IDENTITY_MISMATCH
STOP=UNEXPECTED_PUBLIC_API_BREAK_REQUIRED
STOP=NEW_DEPENDENCY_REQUIRED
```

## Verification strategy

Tasks 1–9 each start with a focused failing ExUnit test, confirm the red result, implement only that task, rerun its focused suite, run neighboring suites, then create one task commit. Task 10's synthetic acceptance test is authored and proven red as the first step of Task 7, before `/7` implementation; its dedicated file remains separate so Task 10 can commit it after the test passes and the exact local proof is complete. Task 10 adds no production code or private evidence. Do not start a later task while a focused or relevant broader suite fails.

```sh
mix test apps/live_frames/test/live_frames/componentization_plan_test.exs apps/live_frames/test/live_frames/componentization_plan/node_disposition_test.exs
mix test apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs
mix test apps/live_frames/test/live_frames/componentization_proposer_test.exs apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs
mix test apps/live_frames/test/live_frames/behavior/componentization_decision_test.exs
mix test apps/live_frames/test/live_frames/component_review_test.exs apps/live_frames/test/live_frames/component_review_result_test.exs
mix test apps/live_frames/test/live_frames/native_generator_test.exs apps/live_frames/test/live_frames/native_generator/filtered_structure_test.exs apps/live_frames/test/live_frames/native_generator/style_integration_test.exs apps/live_frames/test/live_frames/native_generator/disposition_end_to_end_test.exs
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

The plan maps schema/version compatibility to Task 1, SemanticInput to Task 2, Behavior handoff to Task 3, construction guards to Task 4, reference validation to Task 5, the result and transition to Task 6, generation authority to Task 7, shared filtering to Task 8, compatibility and NAV-CARRIER to Task 9, and synthetic plus Milan proof to Task 10. Every task names files, a failing test, its focused command, implementation scope, broader tests, and a separate commit. The interfaces are consistent across tasks. Every Review Focus item maps to explicit assertions and test files. Each new module has one responsibility. This document contains no implementation code.

```text
SPEC_COVERAGE_GAPS=NONE
STEP_GRANULARITY=ONE_REVIEWABLE_CHANGE_PER_TASK
INTERFACE_INCONSISTENCIES=NONE
UNTESTED_REVIEW_FOCUS_ITEMS=NONE
PLAN_CODE_PROPORTION=PLAN_ONLY
```
