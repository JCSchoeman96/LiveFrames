defmodule LiveFrames.ComponentContractReferenceValidationTest do
  use ExUnit.Case, async: true

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentContract.CollectionInput
  alias LiveFrames.ComponentContract.ItemField
  alias LiveFrames.ComponentContract.Slot
  alias LiveFrames.IR.CollectionBinding
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.ValueBinding

  @site_id DesignNode.deterministic_id([1])
  @repeat_id DesignNode.deterministic_id([2])

  defp ir_document(overrides \\ []) do
    base =
      DesignDocument.new(
        source_metadata: %{"fixture" => true},
        provenance: %{},
        root_nodes: [
          %DesignNode{node_id: @site_id, semantic_type: "section", children: []},
          %DesignNode{node_id: @repeat_id, semantic_type: "container", children: []}
        ]
      )

    struct!(base, Map.new(overrides))
  end

  defp value_binding(id, opts) do
    value_kind = Keyword.fetch!(opts, :value_kind)

    %ValueBinding{
      value_binding_id: id,
      target_node_id: Keyword.fetch!(opts, :target_node_id),
      target_kind: Keyword.get(opts, :target_kind, :text),
      value_kind: value_kind,
      scope: Keyword.fetch!(opts, :scope),
      value_key: value_key_for(value_kind, opts),
      collection_binding_id: Keyword.get(opts, :collection_binding_id),
      normalization_status: Keyword.get(opts, :normalization_status, :normalized),
      modifier_status: Keyword.get(opts, :modifier_status, :none)
    }
  end

  defp value_key_for(:collection_count, opts), do: Keyword.get(opts, :value_key)
  defp value_key_for(_value_kind, opts), do: Keyword.get(opts, :value_key, "field")

  defp collection_binding(id, opts) do
    %CollectionBinding{
      collection_binding_id: id,
      owner_node_id: Keyword.get(opts, :owner_node_id, @repeat_id),
      repeat_root_node_id: Keyword.fetch!(opts, :repeat_root_node_id),
      parent_collection_binding_id: Keyword.get(opts, :parent_collection_binding_id)
    }
  end

  defp base_contract(overrides \\ []) do
    struct!(
      ComponentContract.new(
        contract_id: "c-ref",
        category: :component,
        module_intent: "marketing_block",
        function_intent: "hero",
        public_attrs: [
          struct!(%Attr{name: "title", type: :string, semantic_purpose: "title"})
        ],
        public_slots: [
          struct!(%Slot{
            name: "inner",
            semantic_purpose: "inner",
            consumer_responsibility: "caller"
          })
        ]
      ),
      overrides
    )
  end

  describe "IR preflight and malformed inputs" do
    test "malformed DesignDocument returns design_ir_invalid without raising" do
      contract = base_contract()

      assert {:error, diagnostics} =
               ComponentContract.validate_ir_references(contract, %DesignDocument{
                 collection_bindings: []
               })

      assert Enum.any?(
               diagnostics,
               &(&1.code == "component_contract.reference.design_ir_invalid")
             )
    end

    test "malformed contract lists return intrinsic diagnostics without raising" do
      document = ir_document()

      contract = base_contract(public_attrs: [%{not: "attr"}])

      assert {:error, diagnostics} = ComponentContract.validate_ir_references(contract, document)

      refute Enum.any?(
               diagnostics,
               &(&1.code == "component_contract.reference.design_ir_invalid")
             )

      assert Enum.any?(diagnostics, &(&1.code == "component_contract.attr.invalid"))
    end
  end

  describe "projection reference matrix" do
    test "scalar_attr valid and semantic mismatch" do
      document =
        ir_document(
          value_bindings: %{
            "vb_site" =>
              value_binding("vb_site",
                target_node_id: @site_id,
                value_kind: :field,
                scope: :site
              )
          }
        )

      contract =
        base_contract(
          binding_projections: [
            %BindingProjection{
              source_binding_kind: :value,
              source_binding_id: "vb_site",
              projection_kind: :scalar_attr,
              public_attr_name: "title",
              target_node_id: @site_id
            }
          ]
        )

      assert ComponentContract.validate_ir_references(contract, document) == :ok

      [projection] = contract.binding_projections

      bad_contract = %{
        contract
        | binding_projections: [%{projection | target_node_id: @repeat_id}]
      }

      assert {:error, diagnostics} =
               ComponentContract.validate_ir_references(bad_contract, document)

      assert Enum.any?(
               diagnostics,
               &(&1.code == "component_contract.projection.target_node_mismatch")
             )
    end

    test "collection_attr valid and collection input public attr mismatch" do
      document =
        ir_document(
          collection_bindings: %{
            "cb_root" => collection_binding("cb_root", repeat_root_node_id: @repeat_id)
          }
        )

      contract =
        base_contract(
          public_attrs: [
            struct!(%Attr{name: "items", type: :list, semantic_purpose: "items"}),
            struct!(%Attr{name: "entries", type: :list, semantic_purpose: "entries"})
          ],
          collection_inputs: [
            %CollectionInput{
              source_collection_binding_id: "cb_root",
              public_attr_name: "entries"
            }
          ],
          binding_projections: [
            %BindingProjection{
              source_binding_kind: :collection,
              source_binding_id: "cb_root",
              projection_kind: :collection_attr,
              public_attr_name: "items",
              source_collection_binding_id: "cb_root",
              target_node_id: @repeat_id
            }
          ]
        )

      assert {:error, diagnostics} = ComponentContract.validate_ir_references(contract, document)

      assert Enum.any?(
               diagnostics,
               &(&1.code == "component_contract.projection.collection_ownership_mismatch")
             )

      fixed = %{
        contract
        | collection_inputs: [
            %CollectionInput{
              source_collection_binding_id: "cb_root",
              public_attr_name: "items"
            }
          ]
      }

      assert ComponentContract.validate_ir_references(fixed, document) == :ok
    end

    test "root collection generation gate accepts valid collection projection" do
      document =
        ir_document(
          collection_bindings: %{
            "cb_root" => collection_binding("cb_root", repeat_root_node_id: @repeat_id)
          }
        )

      contract =
        base_contract(
          approval_status: :approved,
          public_attrs: [
            struct!(%Attr{name: "items", type: :list, semantic_purpose: "items"})
          ],
          collection_inputs: [
            %CollectionInput{
              source_collection_binding_id: "cb_root",
              public_attr_name: "items"
            }
          ],
          binding_projections: [
            %BindingProjection{
              source_binding_kind: :collection,
              source_binding_id: "cb_root",
              projection_kind: :collection_attr,
              public_attr_name: "items",
              source_collection_binding_id: "cb_root",
              target_node_id: @repeat_id
            }
          ]
        )

      assert ComponentContract.validate_for_generation(contract, document) == :ok
    end

    test "evidence-insufficient value binding blocks generation without crash" do
      document =
        ir_document(
          value_bindings: %{
            "vb_opaque" =>
              value_binding("vb_opaque",
                target_node_id: @site_id,
                value_kind: :field,
                scope: :site,
                modifier_status: :opaque,
                normalization_status: :evidence_insufficient
              )
          }
        )

      contract =
        base_contract(
          approval_status: :approved,
          binding_projections: [
            %BindingProjection{
              source_binding_kind: :value,
              source_binding_id: "vb_opaque",
              projection_kind: :scalar_attr,
              public_attr_name: "title",
              target_node_id: @site_id
            }
          ]
        )

      assert {:error, diagnostics} = ComponentContract.validate_for_generation(contract, document)

      assert Enum.any?(
               diagnostics,
               &(&1.code == "component_contract.binding.evidence_insufficient")
             )
    end

    test "nested collection projection requires matching CollectionInput parent fields" do
      document =
        ir_document(
          collection_bindings: %{
            "cb_root" => collection_binding("cb_root", repeat_root_node_id: @repeat_id),
            "cb_child" =>
              collection_binding("cb_child",
                repeat_root_node_id: @repeat_id,
                parent_collection_binding_id: "cb_root"
              )
          }
        )

      contract =
        base_contract(
          public_attrs: [
            struct!(%Attr{name: "items", type: :list, semantic_purpose: "items"})
          ],
          collection_inputs: [
            %CollectionInput{
              source_collection_binding_id: "cb_root",
              public_attr_name: "items",
              item_fields: [
                struct!(%ItemField{name: "kids", type: :list, semantic_purpose: "kids"})
              ]
            },
            %CollectionInput{
              source_collection_binding_id: "cb_child",
              parent_collection_binding_id: "cb_root",
              parent_item_field_name: "kids"
            }
          ],
          binding_projections: [
            %BindingProjection{
              source_binding_kind: :collection,
              source_binding_id: "cb_child",
              projection_kind: :collection_item_field,
              source_collection_binding_id: "cb_child",
              parent_collection_binding_id: "cb_root",
              parent_item_field_name: "kids",
              target_node_id: @repeat_id
            }
          ]
        )

      assert ComponentContract.validate_ir_references(contract, document) == :ok

      [projection] = contract.binding_projections

      bad = %{
        contract
        | binding_projections: [%{projection | parent_item_field_name: "wrong"}]
      }

      assert {:error, diagnostics} = ComponentContract.validate_ir_references(bad, document)

      assert Enum.any?(
               diagnostics,
               &(&1.code == "component_contract.projection.collection_ownership_mismatch")
             )
    end

    test "top-level count rejects nested owning collection binding" do
      document =
        ir_document(
          collection_bindings: %{
            "cb_root" => collection_binding("cb_root", repeat_root_node_id: @repeat_id),
            "cb_child" =>
              collection_binding("cb_child",
                repeat_root_node_id: @repeat_id,
                parent_collection_binding_id: "cb_root"
              )
          },
          value_bindings: %{
            "vb_count" =>
              value_binding("vb_count",
                target_node_id: @site_id,
                value_kind: :collection_count,
                scope: :collection,
                collection_binding_id: "cb_child"
              )
          }
        )

      contract =
        base_contract(
          approval_status: :approved,
          public_attrs: [
            struct!(%Attr{name: "items", type: :list, semantic_purpose: "items"}),
            struct!(%Attr{
              name: "count",
              type: :integer,
              semantic_purpose: "count",
              validation: %{"min" => 0}
            })
          ],
          collection_inputs: [
            %CollectionInput{
              source_collection_binding_id: "cb_root",
              public_attr_name: "items",
              item_fields: [
                struct!(%ItemField{name: "kids", type: :list, semantic_purpose: "kids"})
              ]
            },
            %CollectionInput{
              source_collection_binding_id: "cb_child",
              parent_collection_binding_id: "cb_root",
              parent_item_field_name: "kids"
            }
          ],
          binding_projections: [
            %BindingProjection{
              source_binding_kind: :value,
              source_binding_id: "vb_count",
              projection_kind: :collection_count_attr,
              public_attr_name: "count",
              source_collection_binding_id: "cb_child",
              target_node_id: @site_id
            }
          ]
        )

      assert {:error, diagnostics} = ComponentContract.validate_ir_references(contract, document)

      assert Enum.any?(
               diagnostics,
               &(&1.code == "component_contract.projection.collection_ownership_mismatch")
             )
    end
  end
end
