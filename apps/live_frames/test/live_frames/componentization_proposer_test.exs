defmodule LiveFrames.ComponentizationProposerTest do
  use ExUnit.Case, async: true

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.{BindingProjection, CollectionInput, ItemField}
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationProposer
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
    PublicAttrDecision,
    PublicSlotDecision,
    RenderPlacementDecision
  }

  alias LiveFrames.IR.{CollectionBinding, DesignDocument, DesignNode, ValueBinding}

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
        value_key: "field"
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
    result = ComponentizationProposer.propose(document(), semantic_input)

    assert result.outcome == :proposed
    assert result.contract.approval_status == :proposed
    assert result.contract.contract_id == "card_contract"
    assert result.contract.category == :component
    assert result.contract.module_intent == "content_card"
    assert result.contract.function_intent == "card"
    assert result.plan.contract_id == "card_contract"
    assert result.plan.boundary_node_id == @boundary_id
    assert_pair_valid(result)

    assert ComponentContract.validate_ir_references(result.contract, document()) == :ok

    assert ComponentizationPlan.validate_references(result.plan, result.contract, document()) ==
             :ok
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
    assert function_exported?(LiveFrames.ComponentizationProposer.Construction, :build, 2)

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

  defp diagnostic_sort_key(diagnostic) do
    {
      diagnostic.code,
      if(diagnostic.path in [nil, ""], do: 1, else: 0),
      diagnostic.path || "",
      diagnostic.message || ""
    }
  end
end
