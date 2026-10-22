defmodule LiveFrames.ComponentizationProposerTest do
  use ExUnit.Case, async: true

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.{BindingProjection, CollectionInput, ItemField}
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.NodeDisposition
  alias LiveFrames.ComponentizationProposer
  alias LiveFrames.ComponentizationProposer.Construction
  alias LiveFrames.ComponentizationProposer.SemanticInput, as: Input

  alias LiveFrames.ComponentizationProposer.SemanticInput.{
    BindingAssignmentDecision,
    BoundaryDecision,
    ClassificationDecision,
    CollectionAdmissionDecision,
    CollectionCountLinkDecision,
    ContractIdentityDecision,
    EvidenceHandlingDecision,
    ItemFieldDecision,
    ImageAccessibilityDecision,
    PublicAttrDecision,
    PublicSlotDecision,
    RenderPlacementDecision
  }

  alias LiveFrames.ComponentizationProposer.SemanticInput.SourceNodeDispositionDecision

  alias LiveFrames.Behavior.{
    Binding,
    BindingIdentity,
    Contract,
    ReviewResult,
    Serializer
  }

  alias LiveFrames.Behavior.Binding.{
    ControlledTarget,
    FocusPolicy,
    PrimitiveRef,
    Trigger
  }

  alias LiveFrames.IR.{
    CollectionBinding,
    DesignDocument,
    DesignNode,
    Identity,
    Interaction,
    ResponsiveOverride,
    SourceTrace,
    StyleValue,
    ValueBinding
  }

  alias LiveFrames.Responsive.BreakpointAuthority

  @boundary_id "node_000001"
  @heading_id "node_000001_000001"
  @paragraph_id "node_000001_000002"
  @actions_id "node_000001_000003"

  defp document(overrides \\ []) do
    struct!(
      %DesignDocument{
        root_nodes: [
          %DesignNode{
            node_id: @boundary_id,
            semantic_type: "section",
            children: [
              %DesignNode{node_id: @heading_id, semantic_type: "heading"},
              %DesignNode{node_id: @paragraph_id, semantic_type: "paragraph"},
              %DesignNode{node_id: @actions_id, semantic_type: "actions"}
            ]
          }
        ]
      },
      overrides
    )
  end

  defp input(overrides \\ []) do
    struct!(
      %Input{
        contract_identity: %ContractIdentityDecision{contract_id: "card_contract"},
        classification: %ClassificationDecision{
          category: :component,
          module_intent: "content_card",
          function_intent: "card"
        },
        boundary: %BoundaryDecision{boundary_node_id: @boundary_id}
      },
      overrides
    )
  end

  defp collection_image_fixture(source_pairs \\ [{"photo", "alt"}]) do
    collection_id = DesignNode.deterministic_id([1, 1])

    sources =
      Enum.with_index(source_pairs, 1)
      |> Enum.map(fn {{source_name, alt_name}, index} ->
        {source_name, alt_name, "vb_#{index}", DesignNode.deterministic_id([1, 1, index])}
      end)

    image_nodes =
      Enum.map(sources, fn {_source, _alt, _binding_id, node_id} ->
        %DesignNode{node_id: node_id, semantic_type: "image"}
      end)

    collection = %CollectionBinding{
      collection_binding_id: "outer",
      owner_node_id: @boundary_id,
      repeat_root_node_id: collection_id
    }

    value_bindings =
      Map.new(sources, fn {source_name, _alt, binding_id, node_id} ->
        {binding_id,
         value(binding_id,
           target_node_id: node_id,
           target_kind: :asset,
           scope: :collection_item,
           collection_binding_id: "outer",
           value_key: source_name
         )}
      end)

    design_document =
      document(
        root_nodes: [
          %DesignNode{
            node_id: @boundary_id,
            semantic_type: "section",
            children: [
              %DesignNode{
                node_id: collection_id,
                semantic_type: "container",
                children: image_nodes
              }
            ]
          }
        ],
        collection_bindings: %{"outer" => collection},
        value_bindings: value_bindings
      )

    accessibility = fn alt_name ->
      %{
        "image_alt_policy" => "consumer_supplied",
        "alt_item_field_name" => alt_name,
        "required_when_source_present" => true
      }
    end

    source_fields =
      Enum.map(sources, fn {source_name, alt_name, _binding_id, _node_id} ->
        field("outer", source_name, accessibility: accessibility.(alt_name))
      end)

    alt_fields =
      sources
      |> Enum.map(fn {_source_name, alt_name, _binding_id, _node_id} -> alt_name end)
      |> Enum.uniq()
      |> Enum.map(&field("outer", &1))

    root_assignment = %BindingAssignmentDecision{
      source_binding_kind: :collection,
      source_binding_id: "outer",
      assignment_kind: :collection_attr,
      public_attr_name: "entries",
      source_collection_binding_id: "outer"
    }

    source_assignments =
      Enum.map(sources, fn {source_name, _alt_name, binding_id, _node_id} ->
        %BindingAssignmentDecision{
          source_binding_kind: :value,
          source_binding_id: binding_id,
          assignment_kind: :collection_item_field_value,
          item_field_name: source_name,
          source_collection_binding_id: "outer"
        }
      end)

    image_decisions =
      Enum.map(sources, fn {source_name, alt_name, _binding_id, _node_id} ->
        %ImageAccessibilityDecision{
          target_kind: :item_field,
          source_collection_binding_id: "outer",
          target_name: source_name,
          accessibility: accessibility.(alt_name)
        }
      end)

    semantic_input =
      input(
        public_attrs: [attr("entries", type: :list)],
        collection_admissions: [
          %CollectionAdmissionDecision{
            source_collection_binding_id: "outer",
            public_attr_name: "entries",
            provenance: %{}
          }
        ],
        item_fields: source_fields ++ alt_fields,
        binding_assignments: [root_assignment | source_assignments],
        image_accessibility: image_decisions
      )

    {design_document, semantic_input}
  end

  defp input_with_disposition do
    disposition = %SourceNodeDispositionDecision{
      design_node_id: @heading_id,
      outcome: :exclude_source_runtime_carrier,
      behavior_binding_id: "selected-behavior-binding",
      evidence_refs: ["task-3-test-evidence"]
    }

    input(source_node_dispositions: [disposition])
  end

  defp attr(name, overrides \\ []) do
    struct!(
      %PublicAttrDecision{
        name: name,
        type: :string,
        required: false,
        default: nil,
        semantic_purpose: "Explicit consumer value",
        validation: %{},
        accessibility: %{},
        provenance: %{}
      },
      overrides
    )
  end

  defp slot(name, overrides \\ []) do
    struct!(
      %PublicSlotDecision{
        name: name,
        cardinality: "0..1",
        required: false,
        semantic_purpose: "Consumer markup",
        consumer_responsibility: "Supply markup",
        validation: %{},
        accessibility: %{},
        provenance: %{}
      },
      overrides
    )
  end

  defp field(owner, name, overrides \\ []) do
    struct!(
      %ItemFieldDecision{
        source_collection_binding_id: owner,
        name: name,
        type: :string,
        required: false,
        default: nil,
        semantic_purpose: "Explicit item value",
        validation: %{},
        accessibility: %{},
        provenance: %{}
      },
      overrides
    )
  end

  defp value(id, overrides) do
    struct!(
      %ValueBinding{
        value_binding_id: id,
        target_node_id: @heading_id,
        target_kind: :text,
        value_kind: :field,
        scope: :site,
        value_key: "field",
        modifier: %LiveFrames.IR.ValueModifier.None{}
      },
      overrides
    )
  end

  defp assignment(id, name, overrides \\ []) do
    struct!(
      %BindingAssignmentDecision{
        source_binding_kind: :value,
        source_binding_id: id,
        assignment_kind: :scalar_attr,
        public_attr_name: name
      },
      overrides
    )
  end

  defp render(name, target \\ @heading_id, role \\ :text_content) do
    %RenderPlacementDecision{
      public_target_kind: :attr,
      public_target_name: name,
      target_node_id: target,
      render_role: role
    }
  end

  defp assert_pair_valid(result) do
    assert result.contract != nil
    assert result.plan != nil
    assert ComponentContract.validate(result.contract) == :ok
    assert ComponentizationPlan.validate(result.plan) == :ok
  end

  defp assert_missing_behavior_authority(result) do
    assert result.outcome == :invalid_input
    assert result.contract == nil
    assert result.plan == nil

    assert Enum.any?(result.input_diagnostics, fn diagnostic ->
             diagnostic.code == "componentization_proposer.behavior_authority_required"
           end)
  end

  defp assert_blocked_context(result) do
    assert result.outcome == :invalid_input
    assert result.contract == nil
    assert result.plan == nil
    assert result.input_diagnostics != []
  end

  defp behavior_authority_context(design_document) do
    {:ok, identity} = Identity.from_document(design_document)
    {:ok, contract} = BindingIdentity.assign(%Contract{design_document_identity: identity})
    {:ok, digest} = Serializer.digest(contract)

    review = %ReviewResult{
      review_format_version: "1.0.0",
      design_document_identity: identity,
      behavior_contract_digest_algorithm: Serializer.algorithm(),
      behavior_contract_digest: digest,
      decision: "approved",
      reviewer_identity: "reviewer:task-3-test",
      reviewed_at: "2026-10-18T00:00:00.000000Z",
      review_note: nil,
      evidence_refs: ["task-3-test"]
    }

    {:ok, context} =
      apply(LiveFrames.Behavior.ComponentizationDecision, :authority_context, [
        design_document,
        contract,
        review
      ])

    context
  end

  defp disposition_document(target_overrides \\ [], document_overrides \\ []) do
    target =
      struct!(
        %DesignNode{
          node_id:
            if(Keyword.get(document_overrides, :target_outside_boundary, false),
              do: "node_000002",
              else: @heading_id
            ),
          semantic_type: "unsupported",
          source_trace: source_trace()
        },
        target_overrides
      )

    boundary_children =
      if Keyword.get(document_overrides, :target_outside_boundary, false),
        do: [],
        else: [target]

    boundary = %DesignNode{
      node_id: @boundary_id,
      semantic_type: "section",
      children: boundary_children
    }

    roots =
      if Keyword.get(document_overrides, :target_outside_boundary, false),
        do: [boundary, target],
        else: [boundary]

    %DesignDocument{
      root_nodes: roots,
      interactions: Keyword.get(document_overrides, :interactions, %{})
    }
  end

  defp source_trace(overrides \\ []) do
    struct!(
      %SourceTrace{source_type: "builder", source_id: "source-element-42"},
      overrides
    )
  end

  defp reference_binding(overrides \\ []) do
    struct!(
      %Binding{
        primitive_ref: %PrimitiveRef{kind: "synthetic-primitive", definition_version: "1.0.0"},
        owner_node_id: @boundary_id,
        binding_role: "task4",
        triggers: [],
        controlled_targets: []
      },
      overrides
    )
  end

  defp behavior_authority_context_with_bindings(design_document, bindings) do
    {:ok, identity} = Identity.from_document(design_document)

    {:ok, contract} =
      BindingIdentity.assign(%Contract{design_document_identity: identity, bindings: bindings})

    {:ok, digest} = Serializer.digest(contract)

    review = %ReviewResult{
      review_format_version: "1.0.0",
      design_document_identity: identity,
      behavior_contract_digest_algorithm: Serializer.algorithm(),
      behavior_contract_digest: digest,
      decision: "approved",
      reviewer_identity: "reviewer:task-4-test",
      reviewed_at: "2026-10-18T00:00:00.000000Z",
      review_note: nil,
      evidence_refs: ["task-4-test"]
    }

    {:ok, context} =
      apply(LiveFrames.Behavior.ComponentizationDecision, :authority_context, [
        design_document,
        contract,
        review
      ])

    {context, contract.bindings}
  end

  defp disposition_input(node_id, binding_id, evidence_refs \\ ["evidence-z", "evidence-a"]) do
    disposition = %SourceNodeDispositionDecision{
      design_node_id: node_id,
      outcome: :exclude_source_runtime_carrier,
      behavior_binding_id: binding_id,
      evidence_refs: evidence_refs
    }

    input(source_node_dispositions: [disposition])
  end

  defp propose_disposition(design_document, node_id, behavior_binding, selected_binding_id \\ nil) do
    {context, [assigned_binding]} =
      behavior_authority_context_with_bindings(design_document, [behavior_binding])

    selected_binding_id = selected_binding_id || assigned_binding.binding_id

    {:ok, canonical_input} =
      Input.validate(disposition_input(node_id, selected_binding_id), design_document)

    result =
      apply(ComponentizationProposer, :propose_with_behavior_authority_context_internal, [
        design_document,
        canonical_input,
        context
      ])

    {result, context, assigned_binding}
  end

  defp different_document(design_document) do
    %{design_document | source_metadata: %{"task_3_variant" => "other"}}
  end

  test "invalid input returns no pair and preserves input diagnostics" do
    result = ComponentizationProposer.propose(document(), %{input() | classification: nil})

    assert result.outcome == :invalid_input
    assert result.contract == nil
    assert result.plan == nil
    assert result.input_diagnostics != []
    assert result.construction_diagnostics == []
  end

  test "multi-root unsupported is an invalid input outcome" do
    semantic_input = %{input() | boundary: %BoundaryDecision{multi_root_unsupported: true}}
    result = ComponentizationProposer.propose(document(), semantic_input)

    assert result.outcome == :invalid_input
    assert result.contract == nil
    assert result.plan == nil
    assert Enum.any?(result.input_diagnostics, &(&1.code =~ "multi_root_unsupported"))
  end

  test "B1 conflicts remain invalid input" do
    semantic_input = input(public_attrs: [attr("title")], public_slots: [slot("title")])
    result = ComponentizationProposer.propose(document(), semantic_input)

    assert result.outcome == :invalid_input
    assert result.contract == nil
    assert result.plan == nil

    assert Enum.any?(
             result.input_diagnostics,
             &(&1.code == "componentization_proposer.input.conflict")
           )
  end

  test "constructs a proposed pair for explicit unbound placement" do
    semantic_input = input(public_attrs: [attr("title")], render_placements: [render("title")])
    design_document = document()
    result = ComponentizationProposer.propose(design_document, semantic_input)

    assert result.outcome == :proposed
    assert result.contract.approval_status == :proposed
    assert result.contract.contract_id == "card_contract"
    assert result.contract.category == :component
    assert result.contract.module_intent == "content_card"
    assert result.contract.function_intent == "card"
    assert result.plan.contract_id == "card_contract"
    assert result.plan.boundary_node_id == @boundary_id
    assert result.design_document == design_document
    assert_pair_valid(result)

    assert ComponentContract.validate_ir_references(result.contract, document()) == :ok

    assert ComponentizationPlan.validate_references(result.plan, result.contract, document()) ==
             :ok
  end

  test "direct proposal requires behavior authority for disposition input" do
    result = ComponentizationProposer.propose(document(), input_with_disposition())

    assert_missing_behavior_authority(result)
  end

  test "responsive direct proposal still requires behavior authority for disposition input" do
    result = ComponentizationProposer.propose(responsive_document(), input_with_disposition())

    assert_missing_behavior_authority(result)
  end

  test "breakpoint-authorized direct proposal requires behavior authority for disposition input" do
    result =
      ComponentizationProposer.propose(
        responsive_document(),
        input_with_disposition(),
        breakpoint_authority()
      )

    assert_missing_behavior_authority(result)
  end

  test "preflighted proposal requires behavior authority for disposition input" do
    design_document = document()
    assert {:ok, canonical_input} = Input.validate(input_with_disposition(), design_document)

    result =
      apply(ComponentizationProposer, :propose_from_preflighted_document_internal, [
        design_document,
        canonical_input
      ])

    assert_missing_behavior_authority(result)
  end

  test "empty disposition input keeps the ordinary proposal result" do
    design_document = document()
    ordinary_result = ComponentizationProposer.propose(design_document, input())
    assert {:ok, canonical_input} = Input.validate(input(), design_document)

    preflighted_result =
      ComponentizationProposer.propose_from_preflighted_document_internal(
        design_document,
        canonical_input
      )

    assert ordinary_result == preflighted_result
    assert ordinary_result.outcome == :proposed
    assert ordinary_result.plan.node_dispositions == []
    assert_pair_valid(ordinary_result)
  end

  test "context-aware proposal accepts a freshly validated Behavior authority context" do
    design_document = disposition_document()

    {result, context, binding} =
      propose_disposition(design_document, @heading_id, reference_binding())

    expected = %NodeDisposition{
      design_node_id: @heading_id,
      disposition: :exclude_source_runtime_carrier,
      source_type: "builder",
      source_id: "source-element-42",
      behavior_binding_id: binding.binding_id,
      behavior_contract_digest: context.behavior_contract_digest,
      behavior_review_id: context.behavior_review_result_id,
      evidence_refs: ["evidence-a", "evidence-z"]
    }

    assert result.outcome == :proposed
    assert result.contract.approval_status == :proposed
    assert result.design_document == design_document
    assert result.contract != nil
    assert result.plan.node_dispositions == [expected]

    refute Enum.any?(result.plan.diagnostics, fn diagnostic ->
             diagnostic.code == "componentization_plan.unsupported_node"
           end)

    refute Enum.any?(result.plan.diagnostics, fn diagnostic ->
             diagnostic.code ==
               "componentization_plan.node_disposition.behavior_authority_mismatch"
           end)
  end

  test "multiple dispositions sort records and reject the whole candidate when one target fails" do
    node_a = "node_000001_000001"
    node_b = "node_000001_000002"

    design_document = %DesignDocument{
      root_nodes: [
        %DesignNode{
          node_id: @boundary_id,
          semantic_type: "section",
          children: [
            %DesignNode{
              node_id: node_a,
              semantic_type: "unsupported",
              source_trace: source_trace(source_id: "source-a")
            },
            %DesignNode{
              node_id: node_b,
              semantic_type: "raw",
              source_trace: source_trace(source_id: "source-b")
            }
          ]
        }
      ]
    }

    {context, [binding]} =
      behavior_authority_context_with_bindings(design_document, [reference_binding()])

    decisions = [
      %SourceNodeDispositionDecision{
        design_node_id: node_b,
        outcome: :exclude_source_runtime_carrier,
        behavior_binding_id: binding.binding_id,
        evidence_refs: ["z-ref", "a-ref"]
      },
      %SourceNodeDispositionDecision{
        design_node_id: node_a,
        outcome: :exclude_source_runtime_carrier,
        behavior_binding_id: binding.binding_id,
        evidence_refs: ["only-ref"]
      }
    ]

    {:ok, canonical_input} =
      Input.validate(input(source_node_dispositions: decisions), design_document)

    result =
      apply(ComponentizationProposer, :propose_with_behavior_authority_context_internal, [
        design_document,
        canonical_input,
        context
      ])

    assert Enum.map(result.plan.node_dispositions, & &1.design_node_id) == [node_a, node_b]
    assert Enum.at(result.plan.node_dispositions, 1).evidence_refs == ["a-ref", "z-ref"]

    invalid_input =
      input(
        source_node_dispositions: [
          %SourceNodeDispositionDecision{
            design_node_id: node_a,
            outcome: :exclude_source_runtime_carrier,
            behavior_binding_id: binding.binding_id,
            evidence_refs: ["a-ref"]
          },
          %SourceNodeDispositionDecision{
            design_node_id: "node_000001_000099",
            outcome: :exclude_source_runtime_carrier,
            behavior_binding_id: binding.binding_id,
            evidence_refs: ["missing-target"]
          }
        ]
      )

    {:ok, canonical_invalid_input} = Input.validate(invalid_input, design_document)

    failed_result =
      apply(ComponentizationProposer, :propose_with_behavior_authority_context_internal, [
        design_document,
        canonical_invalid_input,
        context
      ])

    assert failed_result.outcome == :construction_failed
    assert failed_result.plan == nil

    assert Enum.any?(
             failed_result.construction_diagnostics,
             &(&1.code == "componentization_plan.node_disposition.target_missing")
           )
  end

  test "mechanical disposition guards reject invalid targets and source traces" do
    scenarios = [
      {"missing target", disposition_document(), "node_000001_000099", [], nil,
       "componentization_plan.node_disposition.target_missing"},
      {"outside boundary", disposition_document([], target_outside_boundary: true), "node_000002",
       [], nil, "componentization_plan.node_disposition.target_outside_boundary"},
      {"supported semantic type", disposition_document(semantic_type: "heading"), @heading_id, [],
       nil, "componentization_plan.node_disposition.target_semantic_incompatible"},
      {"non-leaf target",
       disposition_document(
         children: [
           %DesignNode{node_id: "node_000001_000001_000001", semantic_type: "unknown"}
         ]
       ), @heading_id, [], nil,
       "componentization_plan.node_disposition.target_semantic_incompatible"},
      {"missing SourceTrace", disposition_document(source_trace: nil), @heading_id, [], nil,
       "componentization_plan.node_disposition.source_identity_mismatch"},
      {"nil source type", disposition_document(source_trace: source_trace(source_type: nil)),
       @heading_id, [], nil, "componentization_plan.node_disposition.source_identity_mismatch"},
      {"nil source ID", disposition_document(source_trace: source_trace(source_id: nil)),
       @heading_id, [], nil, "componentization_plan.node_disposition.source_identity_mismatch"},
      {"missing Behavior binding", disposition_document(), @heading_id, [], "missing-binding-id",
       "componentization_plan.node_disposition.behavior_binding_mismatch"}
    ]

    Enum.each(scenarios, fn {label, design_document, node_id, binding_options, selected_id, code} ->
      {result, _context, _binding} =
        propose_disposition(
          design_document,
          node_id,
          reference_binding(binding_options),
          selected_id
        )

      assert result.outcome == :construction_failed, label
      assert result.plan == nil, label
      assert Enum.any?(result.construction_diagnostics, &(&1.code == code)), label
    end)
  end

  test "non-string SourceTrace identity fields fail the source identity guard" do
    valid_document = disposition_document()

    {context, [binding]} =
      behavior_authority_context_with_bindings(valid_document, [reference_binding()])

    {:ok, canonical_input} =
      Input.validate(disposition_input(@heading_id, binding.binding_id), valid_document)

    invalid_documents = [
      disposition_document(source_trace: source_trace(source_type: "")),
      disposition_document(source_trace: source_trace(source_type: 42)),
      disposition_document(source_trace: source_trace(source_id: "")),
      disposition_document(source_trace: source_trace(source_id: 42))
    ]

    Enum.each(invalid_documents, fn design_document ->
      assert {:error, diagnostics} =
               apply(Construction, :build, [design_document, canonical_input, context])

      assert Enum.any?(
               diagnostics,
               &(&1.code == "componentization_plan.node_disposition.source_identity_mismatch")
             )
    end)
  end

  test "Behavior and IR references to the target reject the disposition" do
    target_id = @heading_id

    focus_cases =
      Enum.map(
        [
          :initial_target_node_id,
          :scope_node_id,
          :restoration_target_node_id,
          :restoration_fallback_node_id
        ],
        fn field ->
          focus_policy = struct!(%FocusPolicy{}, [{field, target_id}])
          {"focus #{field}", [focus_policy: focus_policy]}
        end
      )

    interactions = %{
      "interaction-1" => %Interaction{
        interaction_id: "interaction-1",
        intent: "activate",
        target_node_ids: [target_id]
      }
    }

    scenarios =
      [
        {"binding owner", [], [owner_node_id: target_id]},
        {"controlled target", [],
         [controlled_targets: [%ControlledTarget{role: "content", node_id: target_id}]]},
        {"trigger origin", [],
         [triggers: [%Trigger{kind: "activate", origin_node_id: target_id}]]}
      ] ++
        Enum.map(focus_cases, fn {label, binding_options} -> {label, [], binding_options} end) ++
        [
          {"IR interaction ref", [interaction_refs: ["interaction-1"]], []},
          {"IR interaction target", [], []}
        ]

    Enum.each(scenarios, fn {label, target_options, binding_options} ->
      document_options =
        if label == "IR interaction target", do: [interactions: interactions], else: []

      if label == "IR interaction ref" do
        document_options = [interactions: interactions]
        design_document = disposition_document(target_options, document_options)

        {result, _context, _binding} =
          propose_disposition(design_document, target_id, reference_binding(binding_options))

        assert result.outcome == :construction_failed, label

        assert Enum.any?(
                 result.construction_diagnostics,
                 &(&1.code == "componentization_plan.node_disposition.behavior_reference_conflict")
               ),
               label
      else
        design_document = disposition_document([], document_options)

        {result, _context, _binding} =
          propose_disposition(design_document, target_id, reference_binding(binding_options))

        assert result.outcome == :construction_failed, label

        assert Enum.any?(
                 result.construction_diagnostics,
                 &(&1.code == "componentization_plan.node_disposition.behavior_reference_conflict")
               ),
               label
      end
    end)
  end

  test "Construction.build/3 rejects a duplicated Behavior binding identity" do
    design_document = disposition_document()

    {context, [first, second]} =
      behavior_authority_context_with_bindings(design_document, [
        reference_binding(binding_role: "first"),
        reference_binding(binding_role: "second")
      ])

    duplicated_contract = %{
      context.behavior_contract
      | bindings: [first, %{second | binding_id: first.binding_id}]
    }

    duplicated_context = %{context | behavior_contract: duplicated_contract}

    {:ok, canonical_input} =
      Input.validate(disposition_input(@heading_id, first.binding_id), design_document)

    assert {:error, diagnostics} =
             apply(Construction, :build, [design_document, canonical_input, duplicated_context])

    assert Enum.any?(
             diagnostics,
             &(&1.code == "componentization_plan.node_disposition.behavior_binding_mismatch")
           )
  end

  test "context-aware proposal blocks a forged contract digest" do
    design_document = document()
    assert {:ok, canonical_input} = Input.validate(input_with_disposition(), design_document)
    context = behavior_authority_context(design_document)
    forged_context = Map.put(context, :behavior_contract_digest, String.duplicate("0", 64))

    result =
      apply(ComponentizationProposer, :propose_with_behavior_authority_context_internal, [
        design_document,
        canonical_input,
        forged_context
      ])

    assert_blocked_context(result)
  end

  test "context-aware proposal blocks a forged selected review ID" do
    design_document = document()
    assert {:ok, canonical_input} = Input.validate(input_with_disposition(), design_document)
    context = behavior_authority_context(design_document)

    forged_context =
      Map.put(context, :behavior_review_result_id, "brv_" <> String.duplicate("0", 64))

    result =
      apply(ComponentizationProposer, :propose_with_behavior_authority_context_internal, [
        design_document,
        canonical_input,
        forged_context
      ])

    assert_blocked_context(result)
  end

  test "context-aware proposal requires its selected review to remain the approved singleton" do
    design_document = document()
    assert {:ok, canonical_input} = Input.validate(input_with_disposition(), design_document)
    context = behavior_authority_context(design_document)

    unapproved_review =
      Map.put(context.selected_behavior_review_result, :decision, "needs_review")

    assert {:ok, unapproved_review_id} = ReviewResult.id(unapproved_review)

    forged_context =
      context
      |> Map.put(:selected_behavior_review_result, unapproved_review)
      |> Map.put(:behavior_review_result_id, unapproved_review_id)

    result =
      apply(ComponentizationProposer, :propose_with_behavior_authority_context_internal, [
        design_document,
        canonical_input,
        forged_context
      ])

    assert_blocked_context(result)
  end

  test "context-aware proposal rejects a contract bound to another document" do
    design_document = document()
    other_document = different_document(design_document)
    assert {:ok, canonical_input} = Input.validate(input_with_disposition(), other_document)
    context = behavior_authority_context(design_document)

    result =
      apply(ComponentizationProposer, :propose_with_behavior_authority_context_internal, [
        other_document,
        canonical_input,
        context
      ])

    assert_blocked_context(result)
  end

  test "authority-less proposal rejects a responsive document" do
    result = ComponentizationProposer.propose(responsive_document(), input())

    assert result.outcome == :invalid_input
    assert result.contract == nil
    assert result.plan == nil

    assert Enum.any?(result.input_diagnostics, fn diagnostic ->
             diagnostic.code == "componentization_proposer.breakpoint_authority_required"
           end)
  end

  test "authority-less proposal rejects responsive state nested on a child" do
    original = document()
    [root] = original.root_nodes
    [child | rest] = root.children

    override = %ResponsiveOverride{
      breakpoint_id: "tablet_portrait",
      source_name: "tablet_portrait",
      resolution_status: :unresolved,
      styles: %{"display" => StyleValue.keyword("grid")}
    }

    nested_document = %{
      original
      | root_nodes: [
          %{
            root
            | children: [%{child | responsive: %{"tablet_portrait" => override}} | rest]
          }
        ]
    }

    [nested_root] = nested_document.root_nodes
    [nested_child | _] = nested_root.children
    assert nested_root.responsive == %{}
    assert nested_child.responsive != %{}

    result = ComponentizationProposer.propose(nested_document, input())

    assert result.outcome == :invalid_input

    assert Enum.any?(result.input_diagnostics, fn diagnostic ->
             diagnostic.code == "componentization_proposer.breakpoint_authority_required"
           end)
  end

  test "authority-aware proposal preserves missing-breakpoint metadata" do
    original = document()
    [root] = original.root_nodes

    override = %ResponsiveOverride{
      breakpoint_id: "legacy_tablet",
      source_name: "legacy_tablet",
      resolution_status: :unresolved,
      styles: %{"display" => StyleValue.keyword("grid")}
    }

    responsive = %{original | root_nodes: [%{root | responsive: %{"legacy_tablet" => override}}]}
    result = ComponentizationProposer.propose(responsive, input(), breakpoint_authority())

    assert result.outcome == :invalid_input
    [diagnostic] = result.input_diagnostics
    assert diagnostic.code == "design_document_resolver.authority_missing"

    assert Map.get(diagnostic, :metadata) == %{
             "breakpoint_id" => "legacy_tablet",
             "node_id" => @boundary_id,
             "source_name" => "legacy_tablet"
           }
  end

  test "authority-aware proposal preserves source-name mismatch metadata" do
    original = responsive_document()
    [root] = original.root_nodes
    override = root.responsive["tablet_portrait"]
    mismatched = %{override | source_name: "tablet"}

    responsive = %{
      original
      | root_nodes: [%{root | responsive: %{"tablet_portrait" => mismatched}}]
    }

    result = ComponentizationProposer.propose(responsive, input(), breakpoint_authority())

    assert result.outcome == :invalid_input
    [diagnostic] = result.input_diagnostics
    assert diagnostic.code == "design_document_resolver.source_breakpoint_mismatch"

    assert Map.get(diagnostic, :metadata) == %{
             "breakpoint_id" => "tablet_portrait",
             "node_id" => @boundary_id,
             "source_name" => "tablet"
           }
  end

  test "authority-aware proposal resolves before fingerprinting and returns that document" do
    original_document = responsive_document()
    result = ComponentizationProposer.propose(original_document, input(), breakpoint_authority())

    assert result.outcome == :proposed
    assert %DesignDocument{} = result.design_document
    [resolved_boundary] = result.design_document.root_nodes
    resolved_override = resolved_boundary.responsive["tablet_portrait"]

    assert resolved_override.max_width == 991
    assert resolved_override.resolution_status == :resolved

    assert {:ok, resolved_identity} =
             ComponentizationPlan.design_document_sha256(result.design_document)

    assert result.plan.design_document_sha256 == resolved_identity

    assert {:ok, original_identity} =
             ComponentizationPlan.design_document_sha256(original_document)

    refute result.plan.design_document_sha256 == original_identity

    assert ComponentContract.validate_ir_references(result.contract, result.design_document) ==
             :ok

    assert ComponentizationPlan.validate_references(
             result.plan,
             result.contract,
             result.design_document
           ) == :ok
  end

  test "canonical caller order produces identical structs and encodings" do
    first =
      input(
        public_attrs: [attr("zeta"), attr("alpha")],
        render_placements: [render("zeta", @paragraph_id), render("alpha")]
      )

    second =
      input(
        public_attrs: [attr("alpha"), attr("zeta")],
        render_placements: [render("alpha"), render("zeta", @paragraph_id)]
      )

    first_result = ComponentizationProposer.propose(document(), first)
    second_result = ComponentizationProposer.propose(document(), second)

    assert first_result.outcome == :proposed
    assert second_result.outcome == :proposed
    assert_pair_valid(first_result)
    assert_pair_valid(second_result)
    assert first_result.contract == second_result.contract
    assert first_result.plan == second_result.plan

    assert ComponentContract.encode!(first_result.contract) ==
             ComponentContract.encode!(second_result.contract)

    assert ComponentizationPlan.encode!(first_result.plan) ==
             ComponentizationPlan.encode!(second_result.plan)
  end

  test "materializes all seven binding assignment projections" do
    {design_document, semantic_input} = all_projection_input()
    result = ComponentizationProposer.propose(design_document, semantic_input)

    assert result.outcome == :needs_review
    assert_pair_valid(result)

    projections = Map.new(result.contract.binding_projections, &{&1.source_binding_id, &1})

    assert projections["scalar"] == %BindingProjection{
             source_binding_kind: :value,
             source_binding_id: "scalar",
             projection_kind: :scalar_attr,
             public_attr_name: "title",
             public_slot_name: nil,
             source_collection_binding_id: nil,
             parent_collection_binding_id: nil,
             item_field_name: nil,
             parent_item_field_name: nil,
             target_node_id: "node_000001_000002"
           }

    assert projections["outer"] == %BindingProjection{
             source_binding_kind: :collection,
             source_binding_id: "outer",
             projection_kind: :collection_attr,
             public_attr_name: "entries",
             public_slot_name: nil,
             source_collection_binding_id: "outer",
             parent_collection_binding_id: nil,
             item_field_name: nil,
             parent_item_field_name: nil,
             target_node_id: "node_000001_000001"
           }

    assert projections["item"] == %BindingProjection{
             source_binding_kind: :value,
             source_binding_id: "item",
             projection_kind: :collection_item_field,
             public_attr_name: nil,
             public_slot_name: nil,
             source_collection_binding_id: "outer",
             parent_collection_binding_id: nil,
             item_field_name: "label",
             parent_item_field_name: nil,
             target_node_id: "node_000001_000001_000001"
           }

    assert projections["inner"] == %BindingProjection{
             source_binding_kind: :collection,
             source_binding_id: "inner",
             projection_kind: :collection_item_field,
             public_attr_name: nil,
             public_slot_name: nil,
             source_collection_binding_id: "inner",
             parent_collection_binding_id: "outer",
             item_field_name: nil,
             parent_item_field_name: "children",
             target_node_id: "node_000001_000001_000003"
           }

    assert projections["outer_count"] == %BindingProjection{
             source_binding_kind: :value,
             source_binding_id: "outer_count",
             projection_kind: :collection_count_attr,
             public_attr_name: "total",
             public_slot_name: nil,
             source_collection_binding_id: "outer",
             parent_collection_binding_id: nil,
             item_field_name: nil,
             parent_item_field_name: nil,
             target_node_id: @heading_id
           }

    assert projections["inner_count"] == %BindingProjection{
             source_binding_kind: :value,
             source_binding_id: "inner_count",
             projection_kind: :collection_item_field,
             public_attr_name: nil,
             public_slot_name: nil,
             source_collection_binding_id: "inner",
             parent_collection_binding_id: "outer",
             item_field_name: nil,
             parent_item_field_name: "inner_total",
             target_node_id: @heading_id
           }

    assert projections["slot"] == %BindingProjection{
             source_binding_kind: :value,
             source_binding_id: "slot",
             projection_kind: :slot,
             public_attr_name: nil,
             public_slot_name: "body",
             source_collection_binding_id: nil,
             parent_collection_binding_id: nil,
             item_field_name: nil,
             parent_item_field_name: nil,
             target_node_id: @actions_id
           }

    refute Map.has_key?(projections, "owner_should_not_be_target")
  end

  test "materializes root and nested collections, counts and item ordering" do
    {design_document, semantic_input} = all_projection_input()
    result = ComponentizationProposer.propose(design_document, semantic_input)

    assert [%CollectionInput{} = nested, %CollectionInput{} = root] =
             result.contract.collection_inputs

    assert nested.source_collection_binding_id == "inner"
    assert nested.public_attr_name == nil
    assert nested.parent_collection_binding_id == "outer"
    assert nested.parent_item_field_name == "children"
    assert nested.count_attr_name == nil
    assert nested.count_item_field_name == "inner_total"

    assert root.source_collection_binding_id == "outer"
    assert root.public_attr_name == "entries"
    assert root.parent_collection_binding_id == nil
    assert root.parent_item_field_name == nil
    assert root.count_attr_name == "total"
    assert root.count_item_field_name == nil
    assert Enum.map(root.item_fields, & &1.name) == ["children", "inner_total", "label"]

    assert %ItemField{name: "inner_total", type: :integer} =
             Enum.find(root.item_fields, &(&1.name == "inner_total"))

    assert_pair_valid(result)
  end

  test "explicit evidence omission creates audit and blocking contract diagnostic" do
    design_document = %{
      document()
      | value_bindings: %{
          "opaque" =>
            value("opaque",
              target_node_id: @paragraph_id,
              normalization_status: :evidence_insufficient
            )
        }
    }

    semantic_input =
      input(
        evidence_handling: [
          %EvidenceHandlingDecision{
            source_binding_kind: :value,
            source_binding_id: "opaque",
            outcome: :omit_public_projection
          }
        ]
      )

    result = ComponentizationProposer.propose(design_document, semantic_input)

    assert result.outcome == :needs_review
    assert result.contract.approval_status == :needs_review
    assert result.contract.binding_projections == []

    assert get_in(result.contract.provenance, ["evidence_handling", "opaque"]) == %{
             "outcome" => "omit_public_projection"
           }

    assert Enum.count(
             result.contract.diagnostics,
             &(&1.code == "component_contract.binding_evidence_insufficient" and
                 &1.path == "value_bindings[opaque]")
           ) == 1

    assert Enum.any?(
             result.plan.diagnostics,
             &(&1.code == "componentization_plan.binding.evidence_insufficient")
           )

    assert Enum.any?(
             result.plan.diagnostics,
             &(&1.code == "componentization_plan.binding.uncovered")
           )

    assert_pair_valid(result)
  end

  test "unhandled in-boundary evidence insufficiency keeps the pair for review" do
    design_document = %{
      document()
      | value_bindings: %{
          "opaque" =>
            value("opaque",
              target_node_id: @paragraph_id,
              normalization_status: :evidence_insufficient
            )
        }
    }

    result = ComponentizationProposer.propose(design_document, input())

    assert result.outcome == :needs_review
    assert result.contract.binding_projections == []

    assert Enum.any?(
             result.plan.diagnostics,
             &(&1.code == "componentization_plan.binding.uncovered")
           )

    assert Enum.any?(
             result.plan.diagnostics,
             &(&1.code == "componentization_plan.binding.evidence_insufficient")
           )

    assert Enum.any?(
             result.contract.diagnostics,
             &(&1.code == "component_contract.binding_evidence_insufficient")
           )

    assert_pair_valid(result)
  end

  test "binding-backed slots survive construction and require review" do
    design_document = %{
      document()
      | value_bindings: %{"slot_value" => value("slot_value", target_node_id: @actions_id)}
    }

    semantic_input =
      input(
        public_slots: [slot("body")],
        binding_assignments: [
          %BindingAssignmentDecision{
            source_binding_kind: :value,
            source_binding_id: "slot_value",
            assignment_kind: :slot,
            public_slot_name: "body"
          }
        ]
      )

    result = ComponentizationProposer.propose(design_document, semantic_input)

    assert result.outcome == :needs_review

    assert Enum.any?(
             result.plan.diagnostics,
             &(&1.code == "componentization_plan.slot.binding_backed_unsupported")
           )

    assert result.contract.approval_status == :needs_review
    assert_pair_valid(result)
  end

  test "reference validation blockers return the pair for review" do
    semantic_input =
      input(
        public_attrs: [attr("level", type: :integer)],
        render_placements: [render("level", @paragraph_id, :heading_level)]
      )

    result = ComponentizationProposer.propose(document(), semantic_input)

    assert result.outcome == :needs_review
    assert_pair_valid(result)

    assert Enum.any?(result.plan.diagnostics, fn diagnostic ->
             diagnostic.code in [
               "componentization_plan.render_projection.role_type_mismatch",
               "componentization_plan.render_projection.role_node_mismatch"
             ]
           end)

    assert result.contract.approval_status == :needs_review
  end

  test "static unbound item fields force review without a fake projection" do
    design_document = %{
      document()
      | collection_bindings: %{
          "outer" => %CollectionBinding{
            collection_binding_id: "outer",
            owner_node_id: @boundary_id,
            repeat_root_node_id: @heading_id
          }
        }
    }

    semantic_input =
      input(
        public_attrs: [attr("entries", type: :list)],
        collection_admissions: [
          %CollectionAdmissionDecision{
            source_collection_binding_id: "outer",
            public_attr_name: "entries",
            provenance: %{}
          }
        ],
        item_fields: [field("outer", "label")],
        binding_assignments: [
          %BindingAssignmentDecision{
            source_binding_kind: :collection,
            source_binding_id: "outer",
            assignment_kind: :collection_attr,
            public_attr_name: "entries",
            source_collection_binding_id: "outer"
          }
        ]
      )

    result = ComponentizationProposer.propose(design_document, semantic_input)

    assert result.outcome == :needs_review
    assert_pair_valid(result)
    assert ComponentContract.validate_ir_references(result.contract, design_document) == :ok

    assert ComponentizationPlan.validate_references(result.plan, result.contract, design_document) ==
             :ok

    assert Enum.all?(result.contract.binding_projections, &(&1.source_binding_id != "label"))
    assert [%ItemField{name: "label"}] = hd(result.contract.collection_inputs).item_fields
  end

  test "valid unbound accessibility companion reaches proposed" do
    {design_document, semantic_input} = collection_image_fixture()
    result = ComponentizationProposer.propose(design_document, semantic_input)

    assert result.outcome == :proposed
    assert result.contract.approval_status == :proposed
    assert_pair_valid(result)

    assert ComponentizationPlan.validate_references(
             result.plan,
             result.contract,
             design_document
           ) == :ok

    assert Enum.all?(result.contract.binding_projections, &(&1.item_field_name != "alt"))
  end

  test "zero-reference unbound collection item still needs review" do
    {design_document, semantic_input} = collection_image_fixture([])
    semantic_input = %{semantic_input | item_fields: [field("outer", "caption")]}

    result = ComponentizationProposer.propose(design_document, semantic_input)

    assert result.outcome == :needs_review
    assert result.contract.approval_status == :needs_review
    assert_pair_valid(result)

    assert ComponentizationPlan.validate_references(result.plan, result.contract, design_document) ==
             :ok
  end

  test "non-image accessibility metadata cannot exempt a zero-reference item field" do
    {design_document, semantic_input} = collection_image_fixture([])
    text_node_id = DesignNode.deterministic_id([1, 1, 1])
    [boundary] = design_document.root_nodes
    [collection_node] = boundary.children

    design_document = %{
      design_document
      | root_nodes: [
          %{
            boundary
            | children: [
                %{
                  collection_node
                  | children: [%DesignNode{node_id: text_node_id, semantic_type: "paragraph"}]
                }
              ]
          }
        ],
        value_bindings: %{
          "vb_label" =>
            value("vb_label",
              target_node_id: text_node_id,
              target_kind: :text,
              scope: :collection_item,
              collection_binding_id: "outer",
              value_key: "label"
            )
        }
    }

    semantic_input = %{
      semantic_input
      | item_fields: [
          field("outer", "label",
            accessibility: %{
              "image_alt_policy" => "consumer_supplied",
              "alt_item_field_name" => "caption",
              "required_when_source_present" => true
            }
          ),
          field("outer", "caption")
        ],
        binding_assignments:
          semantic_input.binding_assignments ++
            [
              %BindingAssignmentDecision{
                source_binding_kind: :value,
                source_binding_id: "vb_label",
                assignment_kind: :collection_item_field_value,
                item_field_name: "label",
                source_collection_binding_id: "outer"
              }
            ]
    }

    assert semantic_input.image_accessibility == []
    assert :ok = LiveFrames.IR.validate(design_document)
    assert {:ok, _validated_input} = Input.validate(semantic_input, design_document)

    result = ComponentizationProposer.propose(design_document, semantic_input)

    assert result.outcome == :needs_review, inspect(result.construction_diagnostics)
    assert result.contract.approval_status == :needs_review
    refute Enum.any?(result.contract.binding_projections, &(&1.item_field_name == "caption"))

    assert ComponentizationPlan.validate_references(
             result.plan,
             result.contract,
             design_document
           ) == :ok
  end

  test "shared or malformed named companions do not become proposed" do
    {design_document, shared_input} =
      collection_image_fixture([{"photo", "alt"}, {"cover", "alt"}])

    shared_result = ComponentizationProposer.propose(design_document, shared_input)

    assert shared_result.outcome == :invalid_input
    assert shared_result.contract == nil
    assert shared_result.plan == nil

    {design_document, valid_input} = collection_image_fixture()

    malformed_input = %{
      valid_input
      | item_fields:
          Enum.map(valid_input.item_fields, fn
            %{name: "alt"} = item -> %{item | required: true}
            item -> item
          end)
    }

    malformed_result = ComponentizationProposer.propose(design_document, malformed_input)

    assert malformed_result.outcome == :invalid_input
    assert malformed_result.contract == nil
    assert malformed_result.plan == nil
  end

  test "successful outcomes never set approval to approved or rejected" do
    proposed =
      ComponentizationProposer.propose(
        document(),
        input(public_attrs: [attr("title")], render_placements: [render("title")])
      )

    reviewed = ComponentizationProposer.propose(document(), input())

    assert proposed.outcome == :proposed
    assert reviewed.outcome == :proposed
    assert proposed.contract.approval_status in [:proposed, :needs_review]
    assert reviewed.contract.approval_status in [:proposed, :needs_review]
    refute proposed.contract.approval_status in [:approved, :rejected]
    refute reviewed.contract.approval_status in [:approved, :rejected]
    assert_pair_valid(proposed)
    assert_pair_valid(reviewed)
  end

  test "construction failures return only transient construction diagnostics" do
    assert {:error, diagnostics} =
             LiveFrames.ComponentizationProposer.Construction.build(
               document(),
               %{input() | contract_identity: %ContractIdentityDecision{contract_id: nil}}
             )

    assert diagnostics != []
    assert Enum.all?(diagnostics, &(&1.code == "componentization_proposer.construction.failed"))

    assert Enum.any?(
             diagnostics,
             &String.contains?(&1.message, "component_contract.identity.invalid")
           )
  end

  test "diagnostics use code then path with empty paths last" do
    semantic_input =
      input(
        public_attrs: [attr("alpha"), attr("level", type: :integer)],
        render_placements: [render("level", @paragraph_id, :heading_level)]
      )

    result = ComponentizationProposer.propose(document(), semantic_input)
    assert result.outcome == :needs_review

    assert result.plan.diagnostics ==
             Enum.sort_by(result.plan.diagnostics, fn diagnostic ->
               {diagnostic.code, if(diagnostic.path in [nil, ""], do: 1, else: 0),
                diagnostic.path || "", diagnostic.message || ""}
             end)

    assert result.contract.diagnostics ==
             Enum.sort_by(result.contract.diagnostics, fn diagnostic ->
               {diagnostic.code, if(diagnostic.path in [nil, ""], do: 1, else: 0),
                diagnostic.path || "", diagnostic.message || ""}
             end)
  end

  test "canonical caller order across all decision families is byte-identical" do
    {design_document, first} = all_projection_input()

    second = %{
      first
      | public_attrs: Enum.reverse(first.public_attrs),
        public_slots: Enum.reverse(first.public_slots),
        collection_admissions: Enum.reverse(first.collection_admissions),
        item_fields: Enum.reverse(first.item_fields),
        collection_count_links: Enum.reverse(first.collection_count_links),
        binding_assignments: Enum.reverse(first.binding_assignments),
        render_placements: Enum.reverse(first.render_placements),
        image_accessibility: Enum.reverse(first.image_accessibility),
        evidence_handling: Enum.reverse(first.evidence_handling),
        static_content_dispositions: Enum.reverse(first.static_content_dispositions)
    }

    first_result = ComponentizationProposer.propose(design_document, first)
    second_result = ComponentizationProposer.propose(design_document, second)

    assert first_result.outcome == :needs_review
    assert second_result.outcome == :needs_review
    assert_pair_valid(first_result)
    assert_pair_valid(second_result)
    assert first_result.contract == second_result.contract
    assert first_result.plan == second_result.plan

    assert ComponentContract.encode!(first_result.contract) ==
             ComponentContract.encode!(second_result.contract)

    assert ComponentizationPlan.encode!(first_result.plan) ==
             ComponentizationPlan.encode!(second_result.plan)
  end

  test "evidence diagnostics and encodings are deterministic across decision order" do
    {design_document, first} = evidence_input(["opaque_a", "opaque_b"])
    {_same_document, second} = evidence_input(["opaque_b", "opaque_a"])

    first_result = ComponentizationProposer.propose(design_document, first)
    second_result = ComponentizationProposer.propose(design_document, second)

    assert first_result.outcome == :needs_review
    assert second_result.outcome == :needs_review
    assert_pair_valid(first_result)
    assert_pair_valid(second_result)
    assert first_result.contract == second_result.contract
    assert first_result.plan == second_result.plan

    assert ComponentContract.encode!(first_result.contract) ==
             ComponentContract.encode!(second_result.contract)

    assert ComponentizationPlan.encode!(first_result.plan) ==
             ComponentizationPlan.encode!(second_result.plan)

    assert Enum.count(first_result.contract.diagnostics) >= 2
    assert Enum.count(first_result.plan.diagnostics) >= 2

    assert first_result.contract.diagnostics ==
             Enum.sort_by(first_result.contract.diagnostics, &diagnostic_sort_key/1)

    assert first_result.plan.diagnostics ==
             Enum.sort_by(first_result.plan.diagnostics, &diagnostic_sort_key/1)
  end

  defp all_projection_input do
    design_document =
      document(
        root_nodes: [
          %DesignNode{
            node_id: @boundary_id,
            semantic_type: "section",
            children: [
              %DesignNode{
                node_id: "node_000001_000001",
                semantic_type: "container",
                children: [
                  %DesignNode{node_id: "node_000001_000001_000001", semantic_type: "heading"},
                  %DesignNode{node_id: "node_000001_000001_000002", semantic_type: "paragraph"},
                  %DesignNode{
                    node_id: "node_000001_000001_000003",
                    semantic_type: "container"
                  }
                ]
              },
              %DesignNode{node_id: "node_000001_000002", semantic_type: "heading"},
              %DesignNode{node_id: @actions_id, semantic_type: "actions"}
            ]
          }
        ],
        collection_bindings: %{
          "outer" => %CollectionBinding{
            collection_binding_id: "outer",
            owner_node_id: @boundary_id,
            repeat_root_node_id: "node_000001_000001"
          },
          "inner" => %CollectionBinding{
            collection_binding_id: "inner",
            owner_node_id: "node_000001_000001",
            repeat_root_node_id: "node_000001_000001_000003",
            parent_collection_binding_id: "outer"
          }
        },
        value_bindings: %{
          "scalar" => value("scalar", target_node_id: "node_000001_000002"),
          "item" =>
            value("item",
              target_node_id: "node_000001_000001_000001",
              scope: :collection_item,
              collection_binding_id: "outer"
            ),
          "outer_count" =>
            value("outer_count",
              value_kind: :collection_count,
              scope: :collection,
              collection_binding_id: "outer",
              value_key: nil
            ),
          "inner_count" =>
            value("inner_count",
              value_kind: :collection_count,
              scope: :collection,
              collection_binding_id: "inner",
              value_key: nil
            ),
          "slot" => value("slot", target_node_id: @actions_id)
        }
      )

    semantic_input =
      input(
        public_attrs: [
          attr("entries", type: :list),
          attr("title"),
          attr("total", type: :integer, validation: %{"min" => 0})
        ],
        public_slots: [slot("body")],
        collection_admissions: [
          %CollectionAdmissionDecision{
            source_collection_binding_id: "outer",
            public_attr_name: "entries",
            provenance: %{}
          },
          %CollectionAdmissionDecision{
            source_collection_binding_id: "inner",
            parent_collection_binding_id: "outer",
            parent_item_field_name: "children",
            provenance: %{}
          }
        ],
        item_fields: [
          field("outer", "label"),
          field("outer", "children", type: :list),
          field("outer", "inner_total", type: :integer, validation: %{"min" => 0})
        ],
        collection_count_links: [
          %CollectionCountLinkDecision{
            source_collection_binding_id: "outer",
            count_public_name: "total",
            count_value_binding_id: "outer_count"
          },
          %CollectionCountLinkDecision{
            source_collection_binding_id: "inner",
            count_public_name: "inner_total",
            count_value_binding_id: "inner_count"
          }
        ],
        binding_assignments: [
          assignment("scalar", "title"),
          %BindingAssignmentDecision{
            source_binding_kind: :collection,
            source_binding_id: "outer",
            assignment_kind: :collection_attr,
            public_attr_name: "entries",
            source_collection_binding_id: "outer"
          },
          %BindingAssignmentDecision{
            source_binding_kind: :value,
            source_binding_id: "item",
            assignment_kind: :collection_item_field_value,
            item_field_name: "label",
            source_collection_binding_id: "outer"
          },
          %BindingAssignmentDecision{
            source_binding_kind: :collection,
            source_binding_id: "inner",
            assignment_kind: :collection_item_field_nested_collection,
            parent_item_field_name: "children",
            source_collection_binding_id: "inner"
          },
          %BindingAssignmentDecision{
            source_binding_kind: :value,
            source_binding_id: "outer_count",
            assignment_kind: :collection_count_attr,
            public_attr_name: "total",
            source_collection_binding_id: "outer"
          },
          %BindingAssignmentDecision{
            source_binding_kind: :value,
            source_binding_id: "inner_count",
            assignment_kind: :collection_count_item_field,
            parent_item_field_name: "inner_total",
            source_collection_binding_id: "inner"
          },
          %BindingAssignmentDecision{
            source_binding_kind: :value,
            source_binding_id: "slot",
            assignment_kind: :slot,
            public_slot_name: "body"
          }
        ]
      )

    assert LiveFrames.IR.validate(design_document) == :ok
    assert {:ok, _canonical} = Input.validate(semantic_input, design_document)
    {design_document, semantic_input}
  end

  defp evidence_input(order) do
    design_document = %{
      document()
      | value_bindings: %{
          "opaque_a" =>
            value("opaque_a",
              target_node_id: @paragraph_id,
              normalization_status: :evidence_insufficient
            ),
          "opaque_b" =>
            value("opaque_b",
              target_node_id: @paragraph_id,
              normalization_status: :evidence_insufficient
            )
        }
    }

    semantic_input =
      input(
        evidence_handling:
          Enum.map(order, fn source_binding_id ->
            %EvidenceHandlingDecision{
              source_binding_kind: :value,
              source_binding_id: source_binding_id,
              outcome: :omit_public_projection
            }
          end)
      )

    {design_document, semantic_input}
  end

  defp responsive_document do
    original = document()
    [boundary | rest] = original.root_nodes

    override = %ResponsiveOverride{
      breakpoint_id: "tablet_portrait",
      source_name: "tablet_portrait",
      resolution_status: :unresolved,
      styles: %{"display" => StyleValue.keyword("grid")}
    }

    %{original | root_nodes: [%{boundary | responsive: %{"tablet_portrait" => override}} | rest]}
  end

  defp breakpoint_authority do
    {:ok, authority} =
      BreakpointAuthority.from_map(%{
        "schema_version" => "1.0.0",
        "authority_status" => "accepted",
        "authority_level" => 3,
        "authority_type" => "version_matched_default_confirmed_by_source_environment",
        "breakpoints" => %{
          "tablet_portrait" => %{
            "source_name" => "tablet_portrait",
            "source_width" => 991,
            "min_width" => nil,
            "max_width" => 991,
            "unit" => "px",
            "query_semantics" => "max-width",
            "media_condition" => "@media (max-width: 991px)",
            "enabled" => true,
            "cascade_order" => 1,
            "authority_level" => 3,
            "authority_type" => "version_matched_default_confirmed_by_source_environment",
            "status" => "accepted"
          }
        },
        "cascade" => %{"ordering" => "descending_width"}
      })

    authority
  end

  defp diagnostic_sort_key(diagnostic) do
    {
      diagnostic.code,
      if(diagnostic.path in [nil, ""], do: 1, else: 0),
      diagnostic.path || "",
      diagnostic.message || ""
    }
  end
end
