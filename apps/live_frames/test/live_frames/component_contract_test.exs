defmodule LiveFrames.ComponentContractTest do
  use ExUnit.Case, async: true

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentContract.CollectionInput
  alias LiveFrames.ComponentContract.Diagnostic
  alias LiveFrames.ComponentContract.ItemField
  alias LiveFrames.ComponentContract.Slot
  alias LiveFrames.ComponentContract.ValidationError

  defp base_contract(overrides \\ []) do
    struct!(
      ComponentContract.new(
        contract_id: "contract-1",
        category: :component,
        module_intent: "marketing_block",
        function_intent: "hero"
      ),
      overrides
    )
  end

  defp attr(name, overrides \\ []) do
    struct!(
      %Attr{
        name: name,
        type: :string,
        semantic_purpose: "consumer-facing #{name}"
      },
      overrides
    )
  end

  defp slot(name, overrides \\ []) do
    struct!(
      %Slot{
        name: name,
        semantic_purpose: "slot #{name}",
        consumer_responsibility: "caller supplies markup"
      },
      overrides
    )
  end

  defp item_field(name, overrides \\ []) do
    struct!(
      %ItemField{
        name: name,
        type: :string,
        semantic_purpose: "field #{name}"
      },
      overrides
    )
  end

  test "format version and enums" do
    assert ComponentContract.current_format_version() == "1.0.0"
    assert ComponentContract.categories() == [:primitive, :component, :pattern, :section]

    assert ComponentContract.approval_statuses() == [
             :proposed,
             :approved,
             :needs_review,
             :rejected
           ]

    assert ComponentContract.validate(base_contract()) == :ok
  end

  test "categories and approval statuses" do
    for category <- ComponentContract.categories() do
      assert ComponentContract.validate(base_contract(category: category)) == :ok
    end

    for status <- ComponentContract.approval_statuses() do
      assert ComponentContract.validate(base_contract(approval_status: status)) == :ok
    end

    assert {:error, diagnostics} = ComponentContract.validate(base_contract(category: :page))
    assert Enum.any?(diagnostics, &(&1.code == "component_contract.category.invalid"))

    assert {:error, diagnostics} =
             ComponentContract.validate(base_contract(approval_status: :draft))

    assert Enum.any?(diagnostics, &(&1.code == "component_contract.approval_status.invalid"))
  end

  test "public name rules" do
    contract =
      base_contract(
        public_attrs: [attr("title"), attr("title")],
        public_slots: []
      )

    assert {:error, diagnostics} = ComponentContract.validate(contract)
    assert Enum.any?(diagnostics, &(&1.code == "component_contract.attr.name_duplicate"))

    contract =
      base_contract(
        public_attrs: [attr("body")],
        public_slots: [slot("body")]
      )

    assert {:error, diagnostics} = ComponentContract.validate(contract)
    assert Enum.any?(diagnostics, &(&1.code == "component_contract.public_name.conflict"))

    for banned <- ["post_title", "bricks_foo", "wp_meta", "element_abc"] do
      assert {:error, diagnostics} =
               ComponentContract.validate(base_contract(public_attrs: [attr(banned)]))

      assert Enum.any?(
               diagnostics,
               &(&1.code == "component_contract.public_name.source_specific")
             )
    end
  end

  test "attr type and default rules" do
    for type <- Attr.phoenix_types() do
      assert ComponentContract.validate(base_contract(public_attrs: [attr("x", type: type)])) ==
               :ok
    end

    assert {:error, diagnostics} =
             ComponentContract.validate(base_contract(public_attrs: [attr("x", type: :atom)]))

    assert Enum.any?(diagnostics, &(&1.code == "component_contract.attr.type_invalid"))

    assert {:error, diagnostics} =
             ComponentContract.validate(
               base_contract(public_attrs: [attr("x", required: true, default: "nope")])
             )

    assert Enum.any?(diagnostics, &(&1.code == "component_contract.attr.default_conflict"))

    assert {:error, diagnostics} =
             ComponentContract.validate(base_contract(public_attrs: [attr("x", default: {1, 2})]))

    assert Enum.any?(diagnostics, &(&1.code == "component_contract.metadata.invalid"))
  end

  test "collection input location and count rules" do
    root =
      base_contract(
        public_attrs: [
          attr("items", type: :list),
          attr("count", type: :integer, validation: %{"min" => 0})
        ],
        collection_inputs: [
          %CollectionInput{
            source_collection_binding_id: "cb_root",
            public_attr_name: "items",
            count_attr_name: "count"
          }
        ]
      )

    assert ComponentContract.validate(root) == :ok

    nested =
      base_contract(
        public_attrs: [attr("items", type: :list)],
        collection_inputs: [
          %CollectionInput{
            source_collection_binding_id: "cb_parent",
            public_attr_name: "items",
            item_fields: [
              item_field("children", type: :list),
              item_field("child_count", type: :integer, validation: %{"min" => 0})
            ]
          },
          %CollectionInput{
            source_collection_binding_id: "cb_child",
            parent_collection_binding_id: "cb_parent",
            parent_item_field_name: "children",
            count_item_field_name: "child_count",
            item_fields: []
          }
        ]
      )

    assert ComponentContract.validate(nested) == :ok

    invalid_xor =
      base_contract(
        collection_inputs: [
          %CollectionInput{
            source_collection_binding_id: "cb_bad",
            public_attr_name: "items",
            parent_collection_binding_id: "cb_parent"
          }
        ]
      )

    assert {:error, diagnostics} = ComponentContract.validate(invalid_xor)
    assert Enum.any?(diagnostics, &(&1.code == "component_contract.collection.location_invalid"))
  end

  test "collection graph detects self-parent and cycle without marking tail as cycle member" do
    self_parent =
      base_contract(
        public_attrs: [attr("items", type: :list)],
        collection_inputs: [
          %CollectionInput{
            source_collection_binding_id: "cb_a",
            public_attr_name: "items",
            parent_collection_binding_id: "cb_a",
            parent_item_field_name: "children",
            item_fields: [item_field("children", type: :list)]
          }
        ]
      )

    assert {:error, diagnostics} = ComponentContract.validate(self_parent)

    assert Enum.any?(diagnostics, fn d ->
             d.code in [
               "component_contract.collection.parent_self",
               "component_contract.collection.location_invalid"
             ]
           end)

    cycle =
      base_contract(
        public_attrs: [attr("items", type: :list)],
        collection_inputs: [
          %CollectionInput{
            source_collection_binding_id: "cb_root",
            public_attr_name: "items",
            item_fields: [item_field("kids", type: :list)]
          },
          %CollectionInput{
            source_collection_binding_id: "cb_a",
            parent_collection_binding_id: "cb_c",
            parent_item_field_name: "loop",
            item_fields: [item_field("loop", type: :list)]
          },
          %CollectionInput{
            source_collection_binding_id: "cb_b",
            parent_collection_binding_id: "cb_a",
            parent_item_field_name: "loop",
            item_fields: [item_field("loop", type: :list)]
          },
          %CollectionInput{
            source_collection_binding_id: "cb_c",
            parent_collection_binding_id: "cb_b",
            parent_item_field_name: "loop",
            item_fields: [item_field("loop", type: :list)]
          }
        ]
      )

    assert {:error, diagnostics} = ComponentContract.validate(cycle)
    assert Enum.any?(diagnostics, &(&1.code == "component_contract.collection.parent_cycle"))
  end

  test "binding projection intrinsic shapes" do
    contract =
      base_contract(
        public_attrs: [attr("title"), attr("items", type: :list)],
        public_slots: [slot("inner")],
        collection_inputs: [
          %CollectionInput{
            source_collection_binding_id: "cb_1",
            public_attr_name: "items",
            item_fields: [item_field("label")]
          }
        ],
        binding_projections: [
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_1",
            projection_kind: :scalar_attr,
            public_attr_name: "title",
            target_node_id: "node_1"
          },
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_slot",
            projection_kind: :slot,
            public_slot_name: "inner",
            target_node_id: "node_2"
          }
        ]
      )

    assert ComponentContract.validate(contract) == :ok
    refute Map.has_key?(contract.binding_projections |> List.first(), :status)
  end

  test "serialization is deterministic and omits structs" do
    contract = base_contract(public_attrs: [attr("title")])

    assert {:ok, first} = ComponentContract.encode(contract)
    assert {:ok, second} = ComponentContract.encode(contract)
    assert first == second
    assert first =~ "\"contract_format_version\":\"1.0.0\""
    refute first =~ "__struct__"
    refute first =~ "\"status\""

    assert_raise ValidationError, fn ->
      ComponentContract.encode!(base_contract(contract_id: ""))
    end
  end

  test "validate_for_generation blocks non-approved contracts" do
    document = LiveFrames.IR.DesignDocument.new()

    for status <- [:proposed, :needs_review, :rejected] do
      assert {:error, diagnostics} =
               ComponentContract.validate_for_generation(
                 base_contract(approval_status: status),
                 document
               )

      assert Enum.any?(diagnostics, &(&1.code == "component_contract.approval_blocked"))
    end
  end

  test "stored diagnostics must validate" do
    contract =
      base_contract(
        diagnostics: [
          %Diagnostic{
            code: "component_contract.fixture.note",
            severity: :info,
            message: "note"
          }
        ]
      )

    assert ComponentContract.validate(contract) == :ok

    invalid =
      base_contract(diagnostics: [%Diagnostic{code: "ir.bad", severity: :info, message: "x"}])

    assert {:error, diagnostics} = ComponentContract.validate(invalid)
    assert Enum.any?(diagnostics, &(&1.code == "component_contract.metadata.invalid"))
  end

  test "rejects non-boolean required flags without raising" do
    for bad <- ["yes", :yes, nil] do
      assert {:error, diagnostics} =
               ComponentContract.validate(base_contract(public_attrs: [attr("x", required: bad)]))

      assert Enum.any?(diagnostics, &(&1.code == "component_contract.attr.invalid"))
    end

    assert {:error, diagnostics} =
             ComponentContract.validate(
               base_contract(public_slots: [slot("inner", required: nil)])
             )

    assert Enum.any?(diagnostics, &(&1.code == "component_contract.attr.invalid"))
  end

  test "rejects JSON key collisions after normalization" do
    assert {:error, diagnostics} =
             ComponentContract.validate(base_contract(provenance: %{:foo => 1, "foo" => 2}))

    assert Enum.any?(diagnostics, &(&1.code == "component_contract.metadata.invalid"))

    assert {:error, diagnostics} =
             ComponentContract.validate(
               base_contract(public_attrs: [attr("title", provenance: %{:key => 1, "key" => 2})])
             )

    assert Enum.any?(diagnostics, &(&1.code == "component_contract.metadata.invalid"))
  end

  test "duplicate equal projections report distinct binding_projections paths" do
    invalid = %BindingProjection{
      source_binding_kind: :value,
      projection_kind: :scalar_attr
    }

    contract =
      base_contract(binding_projections: [invalid, invalid])

    assert {:error, diagnostics} = ComponentContract.validate(contract)

    paths =
      diagnostics
      |> Enum.filter(&(&1.code == "component_contract.projection.binding_missing"))
      |> Enum.map(& &1.path)

    assert "binding_projections[0]" in paths
    assert "binding_projections[1]" in paths
  end

  test "malformed nested contract does not raise public validators" do
    document = LiveFrames.IR.DesignDocument.new()
    bad = base_contract(public_attrs: ["not-an-attr"])

    assert {:error, _} = ComponentContract.validate(bad)
    assert {:error, _} = ComponentContract.validate_ir_references(bad, document)
    assert {:error, _} = ComponentContract.validate_for_generation(bad, document)
    assert {:error, _} = ComponentContract.encode(bad)
  end
end
