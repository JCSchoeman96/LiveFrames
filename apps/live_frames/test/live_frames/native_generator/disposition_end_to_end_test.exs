defmodule LiveFrames.NativeGenerator.DispositionEndToEndTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Behavior.Binding, as: BehaviorBinding
  alias LiveFrames.Behavior.Binding.PrimitiveRef
  alias LiveFrames.Behavior.BindingIdentity
  alias LiveFrames.Behavior.ComponentizationDecision
  alias LiveFrames.Behavior.Contract, as: BehaviorContract
  alias LiveFrames.Behavior.ReviewResult, as: BehaviorReviewResult
  alias LiveFrames.Behavior.Serializer, as: BehaviorSerializer
  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentReview
  alias LiveFrames.ComponentReviewResult
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.NodeDisposition
  alias LiveFrames.ComponentizationProposer
  alias LiveFrames.ComponentizationProposer.SemanticInput, as: SemanticInput
  alias LiveFrames.ComponentizationProposer.SemanticInput.BoundaryDecision
  alias LiveFrames.ComponentizationProposer.SemanticInput.ClassificationDecision
  alias LiveFrames.ComponentizationProposer.SemanticInput.ContractIdentityDecision
  alias LiveFrames.ComponentizationProposer.SemanticInput.SourceNodeDispositionDecision
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Identity
  alias LiveFrames.IR.SourceTrace
  alias LiveFrames.IR.StyleValue
  alias LiveFrames.NativeGenerator
  alias LiveFrames.NativeGenerator.FilteredStructure
  alias LiveFrames.NativeGenerator.Renderer
  alias LiveFrames.NativeGenerator.StyleIntegration

  @boundary_id DesignNode.deterministic_id([1])
  @before_id DesignNode.deterministic_id([1, 1])
  @disposed_id DesignNode.deterministic_id([1, 2])
  @after_id DesignNode.deterministic_id([1, 3])
  @runtime_sentinel "SYNTHETIC_RUNTIME_SENTINEL_TASK_8"
  @source_type "synthetic-source-runtime-carrier"
  @multi_a_id DesignNode.deterministic_id([1, 2])
  @multi_b_id DesignNode.deterministic_id([1, 3])
  @multi_sibling_id DesignNode.deterministic_id([1, 4])
  @multi_a_sentinel "SYNTHETIC_RUNTIME_SENTINEL_A"
  @multi_b_sentinel "SYNTHETIC_RUNTIME_SENTINEL_B"

  defp document do
    disposed_node = %DesignNode{
      node_id: @disposed_id,
      semantic_type: "raw",
      source_trace: %SourceTrace{
        source_type: @source_type,
        source_id: @runtime_sentinel,
        source_name: @runtime_sentinel
      },
      styles: %{
        "display" => StyleValue.keyword("block"),
        "custom-css" =>
          StyleValue.complex_css(%{
            "type" => "state_rules",
            "rules" => [
              %{
                "condition" => "hover",
                "target_node_id" => @disposed_id,
                "declarations" => %{
                  "opacity" => %{"kind" => "literal", "value" => 0.5}
                },
                "viewport" => nil,
                "order" => 0
              }
            ],
            "residual" => []
          })
      }
    }

    %DesignDocument{
      root_nodes: [
        %DesignNode{
          node_id: @boundary_id,
          semantic_type: "section",
          children: [
            %DesignNode{
              node_id: @before_id,
              semantic_type: "heading",
              attributes: %{"tag" => "h2"},
              content: "Supported before"
            },
            disposed_node,
            %DesignNode{
              node_id: @after_id,
              semantic_type: "paragraph",
              content: "Supported sibling"
            }
          ]
        }
      ]
    }
  end

  defp exact_authority(design_document) do
    {behavior_contract, behavior_review_result, _authority_context} =
      behavior_authority(design_document)

    {:ok, behavior_digest} = BehaviorSerializer.digest(behavior_contract)
    {:ok, behavior_review_id} = BehaviorReviewResult.id(behavior_review_result)
    {:ok, design_document_sha256} = ComponentizationPlan.design_document_sha256(design_document)

    disposition = %NodeDisposition{
      design_node_id: @disposed_id,
      disposition: :exclude_source_runtime_carrier,
      source_type: @source_type,
      source_id: @runtime_sentinel,
      behavior_binding_id: hd(behavior_contract.bindings).binding_id,
      behavior_contract_digest: behavior_digest,
      behavior_review_id: behavior_review_id,
      evidence_refs: ["synthetic-task8-disposition-evidence"]
    }

    proposed_contract = %ComponentContract{
      contract_id: "task8-synthetic-contract",
      category: :section,
      module_intent: "task8_synthetic",
      function_intent: "render",
      approval_status: :proposed
    }

    plan = %ComponentizationPlan{
      contract_id: proposed_contract.contract_id,
      design_document_sha256: design_document_sha256,
      boundary_node_id: @boundary_id,
      node_dispositions: [disposition]
    }

    {:ok, approved_contract, component_review_result} =
      ComponentReview.approve_with_result(
        proposed_contract,
        plan,
        design_document,
        behavior_contract,
        behavior_review_result,
        "reviewer:task8-synthetic",
        "2026-10-20T00:00:00.000000Z",
        ["synthetic-task8-component-evidence"]
      )

    {:ok, component_review_result_id} = ComponentReviewResult.id(component_review_result)

    {approved_contract, plan, behavior_contract, behavior_review_result, component_review_result,
     component_review_result_id}
  end

  defp behavior_authority(design_document) do
    {:ok, identity} = Identity.from_document(design_document)

    binding = %BehaviorBinding{
      primitive_ref: %PrimitiveRef{kind: "synthetic-task8", definition_version: "1.0.0"},
      owner_node_id: @boundary_id,
      binding_role: "task8-structural-omission"
    }

    {:ok, behavior_contract} =
      BindingIdentity.assign(%BehaviorContract{
        design_document_identity: identity,
        bindings: [binding]
      })

    {:ok, behavior_digest} = BehaviorSerializer.digest(behavior_contract)

    behavior_review_result = %BehaviorReviewResult{
      review_format_version: "1.0.0",
      design_document_identity: identity,
      behavior_contract_digest_algorithm: BehaviorSerializer.algorithm(),
      behavior_contract_digest: behavior_digest,
      decision: "approved",
      reviewer_identity: "reviewer:task8-synthetic",
      reviewed_at: "2026-10-20T00:00:00.000000Z",
      review_note: nil,
      evidence_refs: ["synthetic-task8-behavior-evidence"]
    }

    {:ok, authority_context} =
      ComponentizationDecision.authority_context(
        design_document,
        behavior_contract,
        behavior_review_result
      )

    {behavior_contract, behavior_review_result, authority_context}
  end

  defp multi_disposition_document do
    %DesignDocument{
      root_nodes: [
        %DesignNode{
          node_id: @boundary_id,
          semantic_type: "section",
          children: [
            %DesignNode{
              node_id: DesignNode.deterministic_id([1, 1]),
              semantic_type: "heading",
              attributes: %{"tag" => "h2"},
              content: "Multi before"
            },
            %DesignNode{
              node_id: @multi_a_id,
              semantic_type: "raw",
              source_trace: %SourceTrace{
                source_type: "synthetic-carrier-a",
                source_id: @multi_a_sentinel
              }
            },
            %DesignNode{
              node_id: @multi_b_id,
              semantic_type: "unsupported",
              source_trace: %SourceTrace{
                source_type: "synthetic-carrier-b",
                source_id: @multi_b_sentinel
              }
            },
            %DesignNode{
              node_id: @multi_sibling_id,
              semantic_type: "paragraph",
              content: "Multi supported sibling"
            }
          ]
        }
      ]
    }
  end

  defp propose_and_approve_multi(design_document, caller_order) do
    {behavior_contract, behavior_review_result, authority_context} =
      behavior_authority(design_document)

    binding_id = hd(behavior_contract.bindings).binding_id

    decisions =
      Enum.map(caller_order, fn {node_id, evidence_ref} ->
        %SourceNodeDispositionDecision{
          design_node_id: node_id,
          outcome: :exclude_source_runtime_carrier,
          behavior_binding_id: binding_id,
          evidence_refs: [evidence_ref]
        }
      end)

    assert Enum.map(decisions, & &1.design_node_id) == Enum.map(caller_order, &elem(&1, 0))

    semantic_input = %SemanticInput{
      contract_identity: %ContractIdentityDecision{contract_id: "task8-multi-contract"},
      classification: %ClassificationDecision{
        category: :component,
        module_intent: "task8_multi",
        function_intent: "render"
      },
      boundary: %BoundaryDecision{boundary_node_id: @boundary_id},
      source_node_dispositions: decisions
    }

    assert {:ok, canonical_input} = SemanticInput.validate(semantic_input, design_document)

    proposal =
      apply(ComponentizationProposer, :propose_with_behavior_authority_context_internal, [
        design_document,
        canonical_input,
        authority_context
      ])

    assert proposal.outcome == :proposed

    {:ok, approved_contract, component_review_result} =
      ComponentReview.approve_with_result(
        proposal.contract,
        proposal.plan,
        design_document,
        behavior_contract,
        behavior_review_result,
        "reviewer:task8-multi",
        "2026-10-20T00:00:00.000000Z",
        ["synthetic-task8-multi-review"]
      )

    {:ok, component_review_result_id} = ComponentReviewResult.id(component_review_result)

    {approved_contract, proposal.plan, behavior_contract, behavior_review_result,
     component_review_result, component_review_result_id}
  end

  test "exactly authorized source runtime carrier is omitted while original evidence stays intact" do
    design_document = document()
    original_document = design_document

    {approved_contract, plan, behavior_contract, behavior_review_result, component_review_result,
     component_review_result_id} = exact_authority(design_document)

    original_plan_bytes = ComponentizationPlan.encode!(plan)

    assert ComponentReviewResult.id(component_review_result) == {:ok, component_review_result_id}

    assert :ok ==
             ComponentReviewResult.validate_against(
               component_review_result,
               approved_contract,
               plan,
               design_document
             )

    assert :ok ==
             ComponentizationPlan.validate_for_generation_with_behavior_authority(
               plan,
               approved_contract,
               design_document,
               behavior_contract,
               behavior_review_result
             )

    assert {:ok, bundle} =
             NativeGenerator.generate(
               approved_contract,
               plan,
               design_document,
               behavior_contract,
               behavior_review_result,
               component_review_result,
               component_review_result_id
             )

    assert design_document == original_document
    assert ComponentizationPlan.encode!(plan) == original_plan_bytes
    assert hd(plan.node_dispositions).design_node_id == @disposed_id

    [boundary] = design_document.root_nodes
    assert Enum.any?(boundary.children, &(&1.node_id == @disposed_id))
    disposed_node = Enum.find(boundary.children, &(&1.node_id == @disposed_id))
    assert disposed_node.source_trace.source_id == @runtime_sentinel

    module = Enum.find(bundle.artifacts, &(&1.kind == :elixir_module)).content
    stylesheet = Enum.find(bundle.artifacts, &(&1.kind == :stylesheet)).content

    assert module =~ "Supported before"
    assert module =~ "Supported sibling"
    assert module =~ "lf-section-task8-synthetic"
    refute module =~ "<raw"
    refute module =~ @runtime_sentinel
    refute stylesheet =~ @runtime_sentinel
    refute stylesheet =~ "lf-section-task8-synthetic__n-000001-000002"
    refute stylesheet =~ ":hover"

    {:ok, filtered_structure} =
      FilteredStructure.build(
        design_document,
        @boundary_id,
        [@disposed_id],
        Renderer.package_root_class(approved_contract)
      )

    assert filtered_structure.root_node_ids == [@boundary_id]
    assert filtered_structure.children_by_id[@boundary_id] == [@before_id, @after_id]
    refute Map.has_key?(filtered_structure.nodes_by_id, @disposed_id)
    refute Map.has_key?(filtered_structure.path_by_id, @disposed_id)
    refute Map.has_key?(filtered_structure.private_class_by_id, @disposed_id)
    assert filtered_structure.path_by_id[@after_id] == [1, 3]

    assert filtered_structure.private_class_by_id[@after_id] ==
             "lf-section-task8-synthetic__n-000001-000003"

    assert {:ok, styling} = StyleIntegration.build(approved_contract, plan, filtered_structure)

    assert {:ok, indexes} =
             Renderer.build_indexes(
               approved_contract,
               plan,
               filtered_structure,
               design_document.value_bindings,
               styling.primary_action_slot_targets
             )

    refute Map.has_key?(indexes.nodes_by_id, @disposed_id)
    refute Map.has_key?(indexes.private_class_by_id, @disposed_id)
    assert Map.has_key?(indexes.nodes_by_id, @after_id)
  end

  test "multi-disposition caller order produces identical plans, views, and artifacts" do
    design_document = multi_disposition_document()
    order_a_b = [{@multi_a_id, "evidence-a"}, {@multi_b_id, "evidence-b"}]
    order_b_a = Enum.reverse(order_a_b)

    {contract_a_b, plan_a_b, behavior_a_b, behavior_review_a_b, component_review_a_b,
     component_review_id_a_b} = propose_and_approve_multi(design_document, order_a_b)

    {contract_b_a, plan_b_a, behavior_b_a, behavior_review_b_a, component_review_b_a,
     component_review_id_b_a} = propose_and_approve_multi(design_document, order_b_a)

    assert ComponentizationPlan.encode!(plan_a_b) == ComponentizationPlan.encode!(plan_b_a)

    disposed_a_b = MapSet.new(Enum.map(plan_a_b.node_dispositions, & &1.design_node_id))
    disposed_b_a = MapSet.new(Enum.map(plan_b_a.node_dispositions, & &1.design_node_id))

    assert disposed_a_b == disposed_b_a
    assert disposed_a_b == MapSet.new([@multi_a_id, @multi_b_id])

    assert {:ok, bundle_a_b} =
             NativeGenerator.generate(
               contract_a_b,
               plan_a_b,
               design_document,
               behavior_a_b,
               behavior_review_a_b,
               component_review_a_b,
               component_review_id_a_b
             )

    assert {:ok, bundle_b_a} =
             NativeGenerator.generate(
               contract_b_a,
               plan_b_a,
               design_document,
               behavior_b_a,
               behavior_review_b_a,
               component_review_b_a,
               component_review_id_b_a
             )

    assert bundle_a_b == bundle_b_a

    module = Enum.find(bundle_a_b.artifacts, &(&1.kind == :elixir_module)).content
    stylesheet = Enum.find(bundle_a_b.artifacts, &(&1.kind == :stylesheet)).content
    sibling_class = "lf-component-task8-multi__n-000001-000004"

    assert module =~ "Multi supported sibling"
    refute module =~ @multi_a_sentinel
    refute module =~ @multi_b_sentinel
    refute stylesheet =~ @multi_a_sentinel
    refute stylesheet =~ @multi_b_sentinel

    {:ok, filtered_structure} =
      FilteredStructure.build(
        design_document,
        @boundary_id,
        Enum.map(plan_a_b.node_dispositions, & &1.design_node_id),
        Renderer.package_root_class(contract_a_b)
      )

    assert filtered_structure.path_by_id[@multi_sibling_id] == [1, 4]
    assert filtered_structure.private_class_by_id[@multi_sibling_id] == sibling_class
    refute Map.has_key?(filtered_structure.nodes_by_id, @multi_a_id)
    refute Map.has_key?(filtered_structure.nodes_by_id, @multi_b_id)
  end
end
