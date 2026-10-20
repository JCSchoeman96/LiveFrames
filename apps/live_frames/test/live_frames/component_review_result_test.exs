defmodule LiveFrames.ComponentReviewResultTest do
  use ExUnit.Case, async: true

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentReviewResult
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode

  @golden_bytes "{\"component_contract_digest\":\"1111111111111111111111111111111111111111111111111111111111111111\",\"component_contract_digest_algorithm\":\"sha-256\",\"component_contract_id\":\"component:test\",\"componentization_plan_digest\":\"3333333333333333333333333333333333333333333333333333333333333333\",\"componentization_plan_digest_algorithm\":\"sha-256\",\"decision\":\"approved\",\"design_document_sha256\":\"2222222222222222222222222222222222222222222222222222222222222222\",\"evidence_refs\":[\"evidence:a\",\"evidence:b\"],\"review_format_version\":\"1.0.0\",\"reviewed_at\":\"2026-10-18T00:00:00.000000Z\",\"reviewer_identity\":\"reviewer:test\"}"
  @golden_id "crv_1b012f7028cc1b15a4127403e12ed032e3ed6ead16b8c995690f8e12ef1136d7"
  @review_attrs [
    review_format_version: "1.0.0",
    component_contract_id: "component:test",
    component_contract_digest_algorithm: "sha-256",
    component_contract_digest: String.duplicate("1", 64),
    design_document_sha256: String.duplicate("2", 64),
    componentization_plan_digest_algorithm: "sha-256",
    componentization_plan_digest: String.duplicate("3", 64),
    decision: "approved",
    reviewer_identity: "reviewer:test",
    reviewed_at: "2026-10-18T00:00:00.000000Z",
    evidence_refs: ["evidence:b", "evidence:a"]
  ]

  defp fixture(overrides \\ []) do
    struct(ComponentReviewResult, Keyword.merge(@review_attrs, overrides))
  end

  test "encodes the frozen 604-byte review result and its independent ID" do
    assert Code.ensure_loaded?(ComponentReviewResult)

    review = fixture()

    assert Enum.sort(Map.keys(review)) ==
             Enum.sort([
               :__struct__,
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
             ])

    assert ComponentReviewResult.algorithm() == "lf-component-review-v1-jcs-sha256"
    assert ComponentReviewResult.validate(review) == :ok
    assert ComponentReviewResult.validate(fixture(decision: "needs_review")) == :ok
    assert ComponentReviewResult.validate(fixture(decision: "rejected")) == :ok
    assert {:ok, @golden_bytes} = ComponentReviewResult.encode(review)
    assert byte_size(@golden_bytes) == 604
    assert {:ok, @golden_id} = ComponentReviewResult.id(review)
  end

  test "validates the closed fields, algorithms, digests, decisions, and review metadata" do
    assert Code.ensure_loaded?(ComponentReviewResult)

    valid = fixture()

    invalid_results = [
      Map.put(valid, :extra_field, "unexpected"),
      Map.delete(valid, :reviewer_identity),
      %{valid | review_format_version: "2.0.0"},
      %{valid | component_contract_digest_algorithm: "lf-component-contract-v1-jcs-sha256"},
      %{valid | component_contract_digest: String.duplicate("A", 64)},
      %{valid | design_document_sha256: String.duplicate("a", 63)},
      %{valid | componentization_plan_digest_algorithm: "sha-512"},
      %{valid | componentization_plan_digest: String.duplicate("A", 64)},
      %{valid | decision: "approve"},
      %{valid | reviewer_identity: ""},
      %{valid | reviewer_identity: <<255>>},
      %{valid | reviewed_at: "2026-10-18T00:00:00Z"},
      %{valid | reviewed_at: "2026-02-30T00:00:00.000000Z"},
      %{valid | evidence_refs: []},
      %{valid | evidence_refs: ["evidence:a", "evidence:a"]},
      %{valid | evidence_refs: [""]},
      %{valid | evidence_refs: [<<255>>]},
      %{valid | evidence_refs: ["evidence:a" | :improper]}
    ]

    for review <- invalid_results do
      refute ComponentReviewResult.validate(review) == :ok
    end
  end

  test "validates exact bindings to an approved contract, plan, and DesignDocument" do
    assert Code.ensure_loaded?(ComponentReviewResult)

    design_document =
      DesignDocument.new(
        root_nodes: [
          %DesignNode{node_id: DesignNode.deterministic_id([1]), semantic_type: "section"}
        ]
      )

    contract =
      ComponentContract.new(
        contract_id: "component:exact-binding",
        module_intent: "marketing_block",
        function_intent: "hero",
        approval_status: :approved
      )

    {:ok, document_digest} = ComponentizationPlan.design_document_sha256(design_document)

    plan = %ComponentizationPlan{
      contract_id: contract.contract_id,
      design_document_sha256: document_digest,
      boundary_node_id: DesignNode.deterministic_id([1])
    }

    review = bound_result(contract, plan, design_document)

    assert ComponentReviewResult.validate_against(review, contract, plan, design_document) == :ok

    changed_contract = %{contract | provenance: %{"revision" => "changed"}}
    changed_plan = %{plan | provenance: %{"revision" => "changed"}}
    changed_document = %{design_document | source_metadata: %{"revision" => "changed"}}

    assert {:error, _} =
             ComponentReviewResult.validate_against(
               review,
               changed_contract,
               plan,
               design_document
             )

    assert {:error, _} =
             ComponentReviewResult.validate_against(
               review,
               contract,
               changed_plan,
               design_document
             )

    assert {:error, _} =
             ComponentReviewResult.validate_against(
               review,
               contract,
               plan,
               changed_document
             )

    assert {:error, _} =
             ComponentReviewResult.validate_against(
               %{review | decision: "needs_review"},
               contract,
               plan,
               design_document
             )

    assert {:error, _} =
             ComponentReviewResult.validate_against(
               review,
               %{contract | approval_status: :proposed},
               plan,
               design_document
             )
  end

  test "matches approved contract bytes even when the semantic contract ID is unchanged" do
    assert Code.ensure_loaded?(ComponentReviewResult)

    design_document =
      DesignDocument.new(
        root_nodes: [
          %DesignNode{node_id: DesignNode.deterministic_id([1]), semantic_type: "section"}
        ]
      )

    contract =
      ComponentContract.new(
        contract_id: "component:same-id",
        module_intent: "marketing_block",
        function_intent: "hero",
        approval_status: :approved
      )

    {:ok, document_digest} = ComponentizationPlan.design_document_sha256(design_document)

    plan = %ComponentizationPlan{
      contract_id: contract.contract_id,
      design_document_sha256: document_digest,
      boundary_node_id: DesignNode.deterministic_id([1])
    }

    review = bound_result(contract, plan, design_document)
    changed_contract = %{contract | provenance: %{"same_id" => true}}

    assert changed_contract.contract_id == contract.contract_id

    assert {:error, _} =
             ComponentReviewResult.validate_against(
               review,
               changed_contract,
               plan,
               design_document
             )
  end

  defp bound_result(contract, plan, design_document) do
    {:ok, contract_bytes} = ComponentContract.encode(contract)
    {:ok, plan_bytes} = ComponentizationPlan.encode(plan)
    {:ok, document_digest} = ComponentizationPlan.design_document_sha256(design_document)

    fixture(
      component_contract_id: contract.contract_id,
      component_contract_digest: digest(contract_bytes),
      design_document_sha256: document_digest,
      componentization_plan_digest: digest(plan_bytes)
    )
  end

  defp digest(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
end
