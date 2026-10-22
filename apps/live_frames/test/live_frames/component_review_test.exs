defmodule LiveFrames.ComponentReviewTest do
  use ExUnit.Case, async: true

  alias LiveFrames.ComponentReview
  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentContract.CollectionInput
  alias LiveFrames.ComponentContract.Diagnostic, as: ContractDiagnostic
  alias LiveFrames.ComponentContract.ItemField
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.Diagnostic
  alias LiveFrames.ComponentizationPlan.RenderProjection
  alias LiveFrames.ComponentizationPlan.Diagnostic, as: PlanDiagnostic
  alias LiveFrames.ComponentizationPlan.NodeDisposition
  alias LiveFrames.ComponentizationProposer
  alias LiveFrames.ComponentizationProposer.SemanticInput, as: SemanticInput

  alias LiveFrames.ComponentizationProposer.SemanticInput.{
    BindingAssignmentDecision,
    BoundaryDecision,
    ClassificationDecision,
    CollectionAdmissionDecision,
    ContractIdentityDecision,
    ImageAccessibilityDecision,
    ItemFieldDecision,
    PublicAttrDecision
  }

  alias LiveFrames.ComponentReviewResult
  alias LiveFrames.Behavior.Binding, as: BehaviorBinding
  alias LiveFrames.Behavior.Binding.PrimitiveRef
  alias LiveFrames.Behavior.BindingIdentity
  alias LiveFrames.Behavior.Contract, as: BehaviorContract
  alias LiveFrames.Behavior.ReviewResult
  alias LiveFrames.Behavior.Serializer, as: BehaviorSerializer
  alias LiveFrames.IR.{CollectionBinding, DesignDocument, ValueBinding}
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Identity
  alias LiveFrames.IR.SourceTrace
  alias LiveFrames.IR.ValueBinding

  @boundary_id DesignNode.deterministic_id([1])
  @heading_id DesignNode.deterministic_id([1, 1])
  @outside_id DesignNode.deterministic_id([2])
  @image_id DesignNode.deterministic_id([1, 2])
  @actions_id DesignNode.deterministic_id([1, 3])
  @disposition_target_id DesignNode.deterministic_id([1, 4])
  @disposition_source_type "synthetic-builder"
  @disposition_source_id "synthetic-node-42"

  defp document do
    DesignDocument.new(
      root_nodes: [
        %DesignNode{
          node_id: @boundary_id,
          semantic_type: "section",
          children: [
            %DesignNode{
              node_id: @heading_id,
              semantic_type: "heading",
              attributes: %{"tag" => "h2"}
            }
          ]
        },
        %DesignNode{node_id: @outside_id, semantic_type: "paragraph"}
      ]
    )
  end

  defp candidate(contract_options \\ [], plan_options \\ [], design_document \\ document()) do
    contract =
      struct!(
        ComponentContract.new(
          contract_id: "review-candidate",
          category: :section,
          module_intent: "marketing_block",
          function_intent: "hero"
        ),
        contract_options
      )

    {:ok, fingerprint} = ComponentizationPlan.design_document_sha256(design_document)

    plan =
      struct!(
        %ComponentizationPlan{
          contract_id: contract.contract_id,
          design_document_sha256: fingerprint,
          boundary_node_id: @boundary_id
        },
        plan_options
      )

    {contract, plan, design_document}
  end

  defp unbound_alt_companion_candidate do
    collection_id = "cb_members"
    image_node_id = DesignNode.deterministic_id([1, 1])

    accessibility = %{
      "image_alt_policy" => "consumer_supplied",
      "alt_item_field_name" => "alt",
      "required_when_source_present" => true
    }

    design_document = %DesignDocument{
      root_nodes: [
        %DesignNode{
          node_id: @boundary_id,
          semantic_type: "section",
          children: [%DesignNode{node_id: image_node_id, semantic_type: "image"}]
        }
      ],
      collection_bindings: %{
        collection_id => %CollectionBinding{
          collection_binding_id: collection_id,
          owner_node_id: @boundary_id,
          repeat_root_node_id: image_node_id
        }
      },
      value_bindings: %{
        "image" => %ValueBinding{
          value_binding_id: "image",
          target_node_id: image_node_id,
          target_kind: :asset,
          value_kind: :field,
          scope: :collection_item,
          collection_binding_id: collection_id,
          value_key: "image",
          normalization_status: :normalized,
          modifier: %LiveFrames.IR.ValueModifier.None{}
        }
      }
    }

    semantic_input = %SemanticInput{
      contract_identity: %ContractIdentityDecision{contract_id: "alt-companion"},
      classification: %ClassificationDecision{
        category: :component,
        module_intent: "media",
        function_intent: "gallery"
      },
      boundary: %BoundaryDecision{boundary_node_id: @boundary_id},
      public_attrs: [
        %PublicAttrDecision{
          name: "members",
          type: :list,
          required: false,
          default: nil,
          semantic_purpose: "Image collection",
          validation: %{},
          accessibility: %{},
          provenance: %{}
        }
      ],
      collection_admissions: [
        %CollectionAdmissionDecision{
          source_collection_binding_id: collection_id,
          public_attr_name: "members",
          provenance: %{}
        }
      ],
      item_fields: [
        %ItemFieldDecision{
          source_collection_binding_id: collection_id,
          name: "photo",
          type: :string,
          required: false,
          default: nil,
          semantic_purpose: "Image source",
          validation: %{},
          accessibility: accessibility,
          provenance: %{}
        },
        %ItemFieldDecision{
          source_collection_binding_id: collection_id,
          name: "alt",
          type: :string,
          required: false,
          default: nil,
          semantic_purpose: "Consumer supplied image description",
          validation: %{},
          accessibility: %{},
          provenance: %{}
        }
      ],
      binding_assignments: [
        %BindingAssignmentDecision{
          source_binding_kind: :collection,
          source_binding_id: collection_id,
          assignment_kind: :collection_attr,
          public_attr_name: "members",
          source_collection_binding_id: collection_id
        },
        %BindingAssignmentDecision{
          source_binding_kind: :value,
          source_binding_id: "image",
          assignment_kind: :collection_item_field_value,
          item_field_name: "photo",
          source_collection_binding_id: collection_id
        }
      ],
      image_accessibility: [
        %ImageAccessibilityDecision{
          target_kind: :item_field,
          target_name: "photo",
          source_collection_binding_id: collection_id,
          accessibility: accessibility
        }
      ]
    }

    {design_document, semantic_input}
  end

  defp attr(name, type \\ :string, options \\ []) do
    struct!(%Attr{name: name, type: type, semantic_purpose: name}, options)
  end

  defp text_projection(name, target \\ @heading_id) do
    %RenderProjection{public_attr_name: name, target_node_id: target, render_role: :text_content}
  end

  defp codes({:error, diagnostics}), do: Enum.map(diagnostics, & &1.code)

  test "Contract C0 validation blockers propagate through review approval" do
    {contract, plan, document} =
      candidate(
        [public_attrs: [attr("title", :string, validation: %{"pattern" => "text"})]],
        render_projections: [text_projection("title")]
      )

    assert ComponentizationPlan.validate_references(plan, contract, document) == :ok

    assert {:error, contract_errors} =
             ComponentContract.validate_generation_prerequisites(contract, document)

    assert {:error, errors} = ComponentReview.approve(contract, plan, document)

    assert Enum.any?(errors, fn diagnostic ->
             Enum.any?(
               contract_errors,
               &(&1.code in Map.get(diagnostic.metadata, "upstream_codes", []))
             )
           end)

    assert {:ok, rejected} = ComponentReview.reject(contract, plan, document)
    assert rejected.approval_status == :rejected
  end

  test "Plan C0 icon blocker prevents approval while ordinary references remain valid" do
    document = document()
    [root, outside] = document.root_nodes
    [heading] = root.children

    document = %{
      document
      | root_nodes: [
          %{root | children: [%{heading | semantic_type: "icon", attributes: %{}}]},
          outside
        ]
    }

    {contract, plan, document} = candidate([], [], document)
    assert ComponentContract.validate_generation_prerequisites(contract, document) == :ok
    assert ComponentizationPlan.validate_references(plan, contract, document) == :ok

    assert "componentization_plan.native_generation.icon_unsupported" in codes(
             ComponentReview.approve(contract, plan, document)
           )

    assert {:ok, _} = ComponentReview.reject(contract, plan, document)
  end

  test "proposed candidate approval passes both generation gates without changing inputs" do
    {contract, plan, design_document} = candidate()
    original_plan = plan
    original_document = design_document

    assert ComponentReview.validate_generation_prerequisites(contract, plan, design_document) ==
             :ok

    assert ComponentizationPlan.validate_generation_prerequisites(
             plan,
             contract,
             design_document
           ) == :ok

    assert {:ok, approved} = ComponentReview.approve(contract, plan, design_document)
    assert approved.approval_status == :approved
    assert ComponentContract.validate_for_generation(approved, design_document) == :ok
    assert ComponentizationPlan.validate_for_generation(plan, approved, design_document) == :ok
    assert contract.approval_status == :proposed
    assert plan == original_plan
    assert design_document == original_document
  end

  test "unbound accessibility companion passes the ordinary generation gate" do
    {design_document, semantic_input} = unbound_alt_companion_candidate()

    assert :ok = LiveFrames.IR.validate(design_document)
    assert {:ok, _validated_input} = SemanticInput.validate(semantic_input, design_document)

    proposal = ComponentizationProposer.propose(design_document, semantic_input)

    assert proposal.outcome == :proposed,
           "expected a proposed candidate, got #{inspect(proposal.plan && proposal.plan.diagnostics)}"

    assert ComponentContract.validate_generation_prerequisites(
             proposal.contract,
             design_document
           ) == :ok

    assert ComponentizationPlan.validate_generation_prerequisites(
             proposal.plan,
             proposal.contract,
             design_document
           ) == :ok

    assert ComponentReview.validate_generation_prerequisites(
             proposal.contract,
             proposal.plan,
             design_document
           ) == :ok

    assert {:ok, approved} =
             ComponentReview.approve(proposal.contract, proposal.plan, design_document)

    assert approved.approval_status == :approved
    assert ComponentContract.validate_for_generation(approved, design_document) == :ok

    assert ComponentizationPlan.validate_for_generation(
             proposal.plan,
             approved,
             design_document
           ) == :ok

    assert {:ok, _generated_bundle} =
             LiveFrames.NativeGenerator.generate(approved, proposal.plan, design_document)
  end

  test "legacy approval blocks every plan containing a node disposition" do
    {contract, plan, design_document, _behavior_contract, _review} = disposition_candidate()

    assert {:error, diagnostics} = ComponentReview.approve(contract, plan, design_document)
    assert Enum.any?(diagnostics, &(&1.code == "component_contract.approval_blocked"))
    assert contract.approval_status == :proposed
  end

  test "atomic disposition approval returns the approved contract with its exact review result" do
    {contract, plan, design_document, behavior_contract, behavior_review} =
      disposition_candidate()

    original_contract = contract
    original_plan = plan
    original_document = design_document

    assert {:ok, proposed_contract_bytes} = ComponentContract.encode(contract)

    assert ComponentizationPlan.validate_generation_prerequisites_with_behavior_authority(
             plan,
             contract,
             design_document,
             behavior_contract,
             behavior_review
           ) == :ok

    assert {:ok, approved, review_result} =
             ComponentReview.approve_with_result(
               contract,
               plan,
               design_document,
               behavior_contract,
               behavior_review,
               "reviewer:task6",
               "2026-10-18T00:00:00.000000Z",
               ["component-evidence:b", "component-evidence:a"]
             )

    assert approved.approval_status == :approved
    assert ComponentReviewResult.validate(review_result) == :ok

    assert ComponentReviewResult.validate_against(review_result, approved, plan, design_document) ==
             :ok

    assert review_result.component_contract_id == approved.contract_id
    assert review_result.component_contract_digest_algorithm == "sha-256"
    assert review_result.componentization_plan_digest_algorithm == "sha-256"
    assert review_result.decision == "approved"
    assert review_result.evidence_refs == ["component-evidence:b", "component-evidence:a"]

    assert {:ok, approved_contract_bytes} = ComponentContract.encode(approved)
    approved_digest = sha256(approved_contract_bytes)
    proposed_digest = sha256(proposed_contract_bytes)
    assert review_result.component_contract_digest == approved_digest
    refute review_result.component_contract_digest == proposed_digest

    assert {:ok, encoded_review_result} = ComponentReviewResult.encode(review_result)

    assert String.contains?(
             encoded_review_result,
             "\"evidence_refs\":[\"component-evidence:a\",\"component-evidence:b\"]"
           )

    assert original_contract.approval_status == :proposed
    assert plan == original_plan
    assert design_document == original_document
    assert length(original_plan.node_dispositions) == 1
  end

  test "atomic disposition approval never promotes a needs_review candidate" do
    {contract, plan, design_document, behavior_contract, behavior_review} =
      disposition_candidate(approval_status: :needs_review)

    assert {:error, diagnostics} =
             ComponentReview.approve_with_result(
               contract,
               plan,
               design_document,
               behavior_contract,
               behavior_review,
               "reviewer:task6",
               "2026-10-18T00:00:00.000000Z",
               ["component-evidence:a"]
             )

    assert Enum.any?(diagnostics, &(&1.code == "component_contract.approval_blocked"))
    assert contract.approval_status == :needs_review
  end

  test "atomic disposition approval validates review metadata and Behavior authority" do
    {contract, plan, design_document, behavior_contract, behavior_review} =
      disposition_candidate()

    for {reviewer, reviewed_at, evidence_refs} <- [
          {"", "2026-10-18T00:00:00.000000Z", ["component-evidence:a"]},
          {<<255>>, "2026-10-18T00:00:00.000000Z", ["component-evidence:a"]},
          {"reviewer:task6", "2026-10-18T00:00:00Z", ["component-evidence:a"]},
          {"reviewer:task6", "2026-10-18T00:00:00.000000+00:00", ["component-evidence:a"]},
          {"reviewer:task6", "2026-10-18T00:00:00.000000Z", []},
          {"reviewer:task6", "2026-10-18T00:00:00.000000Z", ["same", "same"]},
          {"reviewer:task6", "2026-10-18T00:00:00.000000Z", [<<255>>]}
        ] do
      assert {:error, _diagnostics} =
               ComponentReview.approve_with_result(
                 contract,
                 plan,
                 design_document,
                 behavior_contract,
                 behavior_review,
                 reviewer,
                 reviewed_at,
                 evidence_refs
               )
    end

    assert {:error, _diagnostics} =
             ComponentReview.approve_with_result(
               contract,
               plan,
               design_document,
               behavior_contract,
               %{behavior_review | decision: "needs_review"},
               "reviewer:task6",
               "2026-10-18T00:00:00.000000Z",
               ["component-evidence:a"]
             )
  end

  test "approve_with_result is proposed-only and requires a non-empty disposition plan" do
    for status <- [:needs_review, :approved, :rejected] do
      {contract, plan, design_document, behavior_contract, behavior_review} =
        disposition_candidate(approval_status: status)

      assert {:error, _diagnostics} =
               ComponentReview.approve_with_result(
                 contract,
                 plan,
                 design_document,
                 behavior_contract,
                 behavior_review,
                 "reviewer:task6",
                 "2026-10-18T00:00:00.000000Z",
                 ["component-evidence:a"]
               )
    end

    {contract, plan, design_document, behavior_contract, behavior_review} =
      disposition_candidate()

    empty_plan = %{plan | node_dispositions: []}

    assert {:error, _diagnostics} =
             ComponentReview.approve_with_result(
               contract,
               empty_plan,
               design_document,
               behavior_contract,
               behavior_review,
               "reviewer:task6",
               "2026-10-18T00:00:00.000000Z",
               ["component-evidence:a"]
             )
  end

  test "approve_with_result rejects wrong document and Behavior authority inputs" do
    {contract, plan, design_document, behavior_contract, behavior_review} =
      disposition_candidate()

    changed_document = %{design_document | source_metadata: %{"revision" => "changed"}}
    changed_behavior_contract = %{behavior_contract | bindings: []}
    changed_selected_review = %{behavior_review | reviewer_identity: "reviewer:other"}

    for {candidate_document, candidate_behavior, selected_review} <- [
          {changed_document, behavior_contract, behavior_review},
          {design_document, changed_behavior_contract, behavior_review},
          {design_document, behavior_contract, changed_selected_review},
          {design_document, behavior_contract, %{behavior_review | decision: "needs_review"}}
        ] do
      assert {:error, _diagnostics} =
               ComponentReview.approve_with_result(
                 contract,
                 plan,
                 candidate_document,
                 candidate_behavior,
                 selected_review,
                 "reviewer:task6",
                 "2026-10-18T00:00:00.000000Z",
                 ["component-evidence:a"]
               )
    end
  end

  test "approve_with_result fails closed for stale NodeDisposition authority" do
    {contract, plan, design_document, behavior_contract, behavior_review} =
      disposition_candidate()

    {:ok, changed_review_id} =
      ReviewResult.id(%{behavior_review | reviewer_identity: "reviewer:stale"})

    [disposition] = plan.node_dispositions
    missing_binding_id = "bnd_" <> String.duplicate("0", 64)

    missing_binding_id =
      if missing_binding_id == disposition.behavior_binding_id do
        "bnd_" <> String.duplicate("1", 64)
      else
        missing_binding_id
      end

    stale_plans = [
      %{
        plan
        | node_dispositions: [
            %{disposition | behavior_contract_digest: String.duplicate("0", 64)}
          ]
      },
      %{plan | node_dispositions: [%{disposition | behavior_review_id: changed_review_id}]},
      %{plan | node_dispositions: [%{disposition | source_type: "stale-builder"}]},
      %{plan | node_dispositions: [%{disposition | source_id: "stale-node-42"}]},
      %{plan | node_dispositions: [%{disposition | behavior_binding_id: missing_binding_id}]}
    ]

    for stale_plan <- stale_plans do
      assert {:error, _diagnostics} =
               ComponentReview.approve_with_result(
                 contract,
                 stale_plan,
                 design_document,
                 behavior_contract,
                 behavior_review,
                 "reviewer:task6",
                 "2026-10-18T00:00:00.000000Z",
                 ["component-evidence:a"]
               )
    end
  end

  test "approve_with_result blocks a disposed node referenced by fresh Behavior authority" do
    {contract, plan, design_document, behavior_contract, behavior_review} =
      disposition_candidate()

    [binding] = behavior_contract.bindings

    {:ok, behavior_contract} =
      BindingIdentity.assign(%{
        behavior_contract
        | bindings: [
            %{binding | owner_node_id: @disposition_target_id, binding_id: nil, ordinal: nil}
          ]
      })

    {:ok, behavior_digest} = BehaviorSerializer.digest(behavior_contract)
    behavior_review = %{behavior_review | behavior_contract_digest: behavior_digest}
    {:ok, behavior_review_id} = ReviewResult.id(behavior_review)
    [disposition] = plan.node_dispositions

    plan = %{
      plan
      | node_dispositions: [
          %{
            disposition
            | behavior_binding_id: hd(behavior_contract.bindings).binding_id,
              behavior_contract_digest: behavior_digest,
              behavior_review_id: behavior_review_id
          }
        ]
    }

    assert {:error, diagnostics} =
             ComponentReview.approve_with_result(
               contract,
               plan,
               design_document,
               behavior_contract,
               behavior_review,
               "reviewer:task6",
               "2026-10-18T00:00:00.000000Z",
               ["component-evidence:a"]
             )

    assert "componentization_plan.node_disposition.behavior_reference_conflict" in codes(
             {:error, diagnostics}
           )
  end

  test "approval is available only from proposed" do
    for status <- [:needs_review, :approved, :rejected] do
      {contract, plan, design_document} = candidate(approval_status: status)

      if status == :needs_review do
        assert ComponentReview.validate_generation_prerequisites(contract, plan, design_document) ==
                 :ok
      end

      assert {:error, diagnostics} = ComponentReview.approve(contract, plan, design_document)
      assert Enum.any?(diagnostics, &(&1.code == "component_contract.approval_blocked"))
    end
  end

  test "proposed and needs_review candidates can be rejected" do
    for status <- [:proposed, :needs_review] do
      {contract, plan, design_document} = candidate(approval_status: status)

      assert {:ok, rejected} = ComponentReview.reject(contract, plan, design_document)
      assert rejected.approval_status == :rejected
      assert contract.approval_status == status
    end
  end

  test "approved and rejected candidates cannot be rejected again" do
    for status <- [:approved, :rejected] do
      {contract, plan, design_document} = candidate(approval_status: status)

      assert {:error, diagnostics} = ComponentReview.reject(contract, plan, design_document)
      assert Enum.any?(diagnostics, &(&1.code == "component_contract.approval_blocked"))
    end
  end

  test "legacy reject and no-disposition approval compatibility is preserved" do
    {contract, plan, design_document} = candidate()

    assert {:ok, %{approval_status: :approved}} =
             ComponentReview.approve(contract, plan, design_document)

    assert {:ok, %{approval_status: :rejected}} =
             ComponentReview.reject(contract, plan, design_document)

    {needs_review, needs_review_plan, needs_review_document} =
      candidate(approval_status: :needs_review)

    {approved, approved_plan, approved_document} = candidate(approval_status: :approved)
    {rejected, rejected_plan, rejected_document} = candidate(approval_status: :rejected)

    for {status_contract, status_plan, status_document} <- [
          {needs_review, needs_review_plan, needs_review_document},
          {approved, approved_plan, approved_document},
          {rejected, rejected_plan, rejected_document}
        ] do
      assert {:error, diagnostics} =
               ComponentReview.approve(status_contract, status_plan, status_document)

      assert "component_contract.approval_blocked" in codes({:error, diagnostics})
    end
  end

  test "any public attr blocks approval" do
    {contract, plan, design_document} =
      candidate(
        [public_attrs: [attr("title", :any)]],
        render_projections: [text_projection("title")]
      )

    assert {:error, diagnostics} = ComponentReview.approve(contract, plan, design_document)
    assert "componentization_plan.contract.mismatch" in codes({:error, diagnostics})
  end

  test "any collection ItemField blocks approval" do
    {contract, plan, design_document} =
      candidate(
        [
          public_attrs: [attr("items", :list)],
          collection_inputs: [
            %CollectionInput{
              source_collection_binding_id: "collection-1",
              public_attr_name: "items",
              item_fields: [%ItemField{name: "label", type: :any, semantic_purpose: "label"}]
            }
          ]
        ],
        render_projections: [text_projection("items")]
      )

    assert {:error, diagnostics} = ComponentReview.approve(contract, plan, design_document)
    assert "componentization_plan.contract.mismatch" in codes({:error, diagnostics})
  end

  test "generation module intent must use the token grammar" do
    {contract, plan, design_document} = candidate(module_intent: "Marketing-Block")

    assert ComponentContract.validate(contract) == :ok
    assert {:error, _diagnostics} = ComponentReview.approve(contract, plan, design_document)
  end

  test "generation function intent must use the token grammar" do
    {contract, plan, design_document} = candidate(function_intent: "Hero!")

    assert ComponentContract.validate(contract) == :ok
    assert {:error, _diagnostics} = ComponentReview.approve(contract, plan, design_document)
  end

  test "evidence-insufficient references block approval" do
    design_document = %{
      document()
      | value_bindings: %{
          "value-title" => %ValueBinding{
            value_binding_id: "value-title",
            target_node_id: @heading_id,
            target_kind: :text,
            value_kind: :field,
            scope: :site,
            value_key: "title",
            normalization_status: :evidence_insufficient,
            modifier: %LiveFrames.IR.ValueModifier.Opaque{}
          }
        }
    }

    {contract, plan, design_document} =
      candidate(
        [
          public_attrs: [attr("title")],
          binding_projections: [
            %BindingProjection{
              source_binding_kind: :value,
              source_binding_id: "value-title",
              projection_kind: :scalar_attr,
              public_attr_name: "title",
              target_node_id: @heading_id
            }
          ]
        ],
        [],
        design_document
      )

    assert {:error, diagnostics} = ComponentReview.approve(contract, plan, design_document)
    assert "componentization_plan.contract.mismatch" in codes({:error, diagnostics})

    assert {:error, prerequisite_diagnostics} =
             ComponentReview.validate_generation_prerequisites(contract, plan, design_document)

    assert "componentization_plan.contract.mismatch" in codes({:error, prerequisite_diagnostics})

    assert {:ok, %{approval_status: :rejected}} =
             ComponentReview.reject(contract, plan, design_document)
  end

  test "stored blocking Contract diagnostics block approval" do
    diagnostic = %ContractDiagnostic{
      code: "component_contract.fixture.blocker",
      severity: :error,
      message: "review required"
    }

    {contract, plan, design_document} = candidate(diagnostics: [diagnostic])

    assert {:error, _diagnostics} = ComponentReview.approve(contract, plan, design_document)
  end

  test "stored blocking Plan diagnostics block approval" do
    diagnostic = %Diagnostic{
      code: "componentization_plan.fixture.blocker",
      severity: :fatal,
      message: "review required"
    }

    {contract, plan, design_document} = candidate([], diagnostics: [diagnostic])

    assert {:error, _diagnostics} = ComponentReview.approve(contract, plan, design_document)
  end

  test "contract identity mismatch blocks approval and rejection" do
    {contract, plan, design_document} = candidate([], contract_id: "another-candidate")

    assert {:error, diagnostics} = ComponentReview.approve(contract, plan, design_document)
    assert "componentization_plan.contract.mismatch" in codes({:error, diagnostics})

    assert {:error, reject_diagnostics} = ComponentReview.reject(contract, plan, design_document)
    assert "componentization_plan.contract.mismatch" in codes({:error, reject_diagnostics})
  end

  test "DesignDocument fingerprint mismatch blocks approval and rejection" do
    {contract, plan, design_document} = candidate()
    changed_document = %{design_document | source_metadata: %{"revision" => "changed"}}

    assert {:error, diagnostics} = ComponentReview.approve(contract, plan, changed_document)
    assert "componentization_plan.design_document.mismatch" in codes({:error, diagnostics})

    assert {:error, reject_diagnostics} =
             ComponentReview.reject(contract, plan, changed_document)

    assert "componentization_plan.design_document.mismatch" in codes({:error, reject_diagnostics})
  end

  test "indexed Plan reference failures block approval" do
    {contract, plan, design_document} =
      candidate(
        [public_attrs: [attr("title")]],
        render_projections: [text_projection("title", @outside_id)]
      )

    assert {:error, diagnostics} = ComponentReview.approve(contract, plan, design_document)

    assert "componentization_plan.render_projection.target_outside_boundary" in codes(
             {:error, diagnostics}
           )
  end

  test "rejection remains available when generation prerequisites fail" do
    {any_attr_contract, any_attr_plan, any_attr_document} =
      candidate(
        [public_attrs: [attr("title", :any)]],
        render_projections: [text_projection("title")]
      )

    blocker = %Diagnostic{
      code: "componentization_plan.fixture.blocker",
      severity: :error,
      message: "generation blocker"
    }

    {plan_blocked_contract, plan_blocked_plan, plan_blocked_document} =
      candidate([], diagnostics: [blocker])

    candidates = [
      {any_attr_contract, any_attr_plan, any_attr_document},
      {plan_blocked_contract, plan_blocked_plan, plan_blocked_document}
    ]

    for {contract, plan, design_document} <- candidates do
      assert {:error, _} =
               ComponentReview.validate_generation_prerequisites(contract, plan, design_document)

      assert {:ok, %{approval_status: :rejected}} =
               ComponentReview.reject(contract, plan, design_document)
    end
  end

  test "rejection rejects a needs_review candidate with blockers" do
    diagnostic = %ContractDiagnostic{
      code: "component_contract.fixture.blocker",
      severity: :error,
      message: "review required"
    }

    {contract, plan, design_document} =
      candidate(approval_status: :needs_review, diagnostics: [diagnostic])

    assert {:ok, %{approval_status: :rejected}} =
             ComponentReview.reject(contract, plan, design_document)
  end

  test "malformed values, improper lists and invalid UTF-8 return errors" do
    assert {:error, _} = ComponentReview.approve(%{}, %{}, %{})
    assert {:error, _} = ComponentReview.reject(%{}, %{}, %{})

    {contract, plan, design_document} = candidate()
    improper_contract = %{contract | public_attrs: [%Attr{name: "title"} | :tail]}
    improper_plan = %{plan | render_projections: [text_projection("title") | :tail]}
    invalid_utf8_contract = %{contract | module_intent: <<255>>}

    for {bad_contract, bad_plan, bad_document} <- [
          {improper_contract, plan, design_document},
          {contract, improper_plan, design_document},
          {invalid_utf8_contract, plan, design_document}
        ] do
      assert {:error, _} =
               ComponentReview.validate_generation_prerequisites(
                 bad_contract,
                 bad_plan,
                 bad_document
               )

      assert {:error, _} = ComponentReview.approve(bad_contract, bad_plan, bad_document)
      assert {:error, _} = ComponentReview.reject(bad_contract, bad_plan, bad_document)
    end
  end

  test "equivalent approval calls return equal contracts" do
    {contract, plan, design_document} = candidate()

    assert ComponentReview.approve(contract, plan, design_document) ==
             ComponentReview.approve(contract, plan, design_document)
  end

  defp disposition_candidate(options \\ []) do
    target = %DesignNode{
      node_id: @disposition_target_id,
      semantic_type: "unsupported",
      source_trace: %SourceTrace{
        source_type: @disposition_source_type,
        source_id: @disposition_source_id
      }
    }

    design_document = %DesignDocument{
      root_nodes: [
        %DesignNode{
          node_id: @boundary_id,
          semantic_type: "section",
          children: [
            %DesignNode{
              node_id: @heading_id,
              semantic_type: "heading",
              attributes: %{"tag" => "h2"}
            },
            %DesignNode{node_id: @image_id, semantic_type: "paragraph"},
            %DesignNode{
              node_id: @actions_id,
              semantic_type: "actions",
              children: [
                %DesignNode{
                  node_id: DesignNode.deterministic_id([1, 3, 1]),
                  semantic_type: "button"
                }
              ]
            },
            target
          ]
        },
        %DesignNode{node_id: @outside_id, semantic_type: "paragraph"}
      ]
    }

    {:ok, identity} = Identity.from_document(design_document)

    binding = %BehaviorBinding{
      primitive_ref: %PrimitiveRef{kind: "synthetic-task5", definition_version: "1.0.0"},
      owner_node_id: @boundary_id,
      binding_role: "task5-reference-validation"
    }

    {:ok, behavior_contract} =
      BindingIdentity.assign(%BehaviorContract{
        design_document_identity: identity,
        bindings: [binding]
      })

    {:ok, behavior_digest} = BehaviorSerializer.digest(behavior_contract)
    behavior_binding = hd(behavior_contract.bindings)

    behavior_review = %ReviewResult{
      review_format_version: "1.0.0",
      design_document_identity: identity,
      behavior_contract_digest_algorithm: BehaviorSerializer.algorithm(),
      behavior_contract_digest: behavior_digest,
      decision: "approved",
      reviewer_identity: "reviewer:synthetic-task5",
      reviewed_at: "2026-10-18T00:00:00.000000Z",
      review_note: nil,
      evidence_refs: ["synthetic-review-evidence"]
    }

    {:ok, behavior_review_id} = ReviewResult.id(behavior_review)

    disposition = %NodeDisposition{
      design_node_id: @disposition_target_id,
      disposition: :exclude_source_runtime_carrier,
      source_type: @disposition_source_type,
      source_id: @disposition_source_id,
      behavior_binding_id: behavior_binding.binding_id,
      behavior_contract_digest: behavior_digest,
      behavior_review_id: behavior_review_id,
      evidence_refs: ["synthetic-evidence-1"]
    }

    contract =
      struct!(
        ComponentContract.new(
          contract_id: "hero-contract",
          category: :section,
          module_intent: "marketing_block",
          function_intent: "hero"
        ),
        approval_status: Keyword.get(options, :approval_status, :proposed)
      )

    {:ok, fingerprint} = ComponentizationPlan.design_document_sha256(design_document)

    plan = %ComponentizationPlan{
      contract_id: contract.contract_id,
      design_document_sha256: fingerprint,
      boundary_node_id: @boundary_id,
      node_dispositions: [disposition],
      diagnostics: [
        %PlanDiagnostic{
          code: "componentization_plan.unsupported_node",
          severity: :error,
          message: "candidate-stage unsupported node blocker"
        },
        %PlanDiagnostic{
          code: "componentization_plan.node_disposition.behavior_authority_mismatch",
          severity: :error,
          message: "candidate-stage authority blocker"
        }
      ]
    }

    {contract, plan, design_document, behavior_contract, behavior_review}
  end

  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
end
