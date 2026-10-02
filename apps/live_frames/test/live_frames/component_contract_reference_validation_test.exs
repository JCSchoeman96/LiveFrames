defmodule LiveFrames.ComponentContractReferenceValidationTest do
  use ExUnit.Case, async: true

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentContract.CollectionInput
  alias LiveFrames.ComponentContract.Slot
  alias LiveFrames.IR.CollectionBinding
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.ValueBinding

  defp site_field_contract(projections) do
    ComponentContract.new(
      contract_id: "c-ref",
      category: :component,
      module_intent: "block",
      function_intent: "block",
      public_attrs: [struct!(%Attr{name: "title", type: :string, semantic_purpose: "title"})],
      public_slots: [
        struct!(%Slot{
          name: "inner",
          semantic_purpose: "inner",
          consumer_responsibility: "caller"
        })
      ],
      binding_projections: projections
    )
  end

  defp document_with_bindings(opts) do
    site_node = Keyword.fetch!(opts, :site_node_id)
    repeat_root = Keyword.fetch!(opts, :repeat_root_id)
    owner = Keyword.get(opts, :owner_id, repeat_root)

    %DesignDocument{
      root_nodes: [
        %DesignNode{node_id: site_node, semantic_type: "section", children: []},
        %DesignNode{node_id: repeat_root, semantic_type: "container", children: []}
      ],
      collection_bindings: %{
        "cb_shared" => %CollectionBinding{
          collection_binding_id: "cb_shared",
          owner_node_id: owner,
          repeat_root_node_id: repeat_root,
          parent_collection_binding_id: Keyword.get(opts, :collection_parent)
        }
      },
      value_bindings:
        Map.merge(
          %{
            "vb_site" => %ValueBinding{
              value_binding_id: "vb_site",
              target_node_id: site_node,
              target_kind: :text,
              value_kind: :field,
              scope: :site
            }
          },
          Keyword.get(opts, :value_bindings, %{})
        )
    }
  end

  test "typed registries disambiguate same id" do
    document =
      %DesignDocument{
        root_nodes: [%DesignNode{node_id: "node_1", semantic_type: "section"}],
        collection_bindings: %{
          "shared_id" => %CollectionBinding{
            collection_binding_id: "shared_id",
            owner_node_id: "node_1",
            repeat_root_node_id: "node_1"
          }
        },
        value_bindings: %{
          "shared_id" => %ValueBinding{
            value_binding_id: "shared_id",
            target_node_id: "node_1",
            target_kind: :text,
            value_kind: :field,
            scope: :site
          }
        }
      }

    contract =
      site_field_contract([
        %BindingProjection{
          source_binding_kind: :value,
          source_binding_id: "shared_id",
          projection_kind: :scalar_attr,
          public_attr_name: "title",
          target_node_id: "node_1"
        }
      ])

    assert ComponentContract.validate_ir_references(contract, document) == :ok

    collection_contract =
      struct!(contract, %{
        public_attrs: [struct!(%Attr{name: "items", type: :list, semantic_purpose: "items"})],
        collection_inputs: [
          %CollectionInput{source_collection_binding_id: "shared_id", public_attr_name: "items"}
        ],
        binding_projections: [
          %BindingProjection{
            source_binding_kind: :collection,
            source_binding_id: "shared_id",
            projection_kind: :collection_attr,
            public_attr_name: "items",
            source_collection_binding_id: "shared_id",
            target_node_id: "node_1"
          }
        ]
      })

    assert ComponentContract.validate_ir_references(collection_contract, document) == :ok
  end

  test "collection projections require repeat_root_node_id not owner_node_id" do
    document =
      document_with_bindings(
        site_node_id: "node_site",
        repeat_root_id: "node_repeat",
        owner_id: "node_owner"
      )

    contract =
      struct!(site_field_contract([]), %{
        public_attrs: [struct!(%Attr{name: "items", type: :list, semantic_purpose: "items"})],
        collection_inputs: [
          %CollectionInput{source_collection_binding_id: "cb_shared", public_attr_name: "items"}
        ],
        binding_projections: [
          %BindingProjection{
            source_binding_kind: :collection,
            source_binding_id: "cb_shared",
            projection_kind: :collection_attr,
            public_attr_name: "items",
            source_collection_binding_id: "cb_shared",
            target_node_id: "node_repeat"
          }
        ]
      })

    assert ComponentContract.validate_ir_references(contract, document) == :ok

    [projection | _] = contract.binding_projections

    wrong_target = %{
      contract
      | binding_projections: [%{projection | target_node_id: "node_owner"}]
    }

    assert {:error, diagnostics} =
             ComponentContract.validate_ir_references(wrong_target, document)

    assert Enum.any?(
             diagnostics,
             &(&1.code == "component_contract.projection.target_node_mismatch")
           )
  end

  test "evidence insufficient bindings fail closed" do
    document =
      document_with_bindings(
        site_node_id: "node_site",
        repeat_root_id: "node_repeat",
        value_bindings: %{
          "vb_opaque" => %ValueBinding{
            value_binding_id: "vb_opaque",
            target_node_id: "node_site",
            target_kind: :text,
            value_kind: :field,
            scope: :site,
            modifier_status: :opaque,
            normalization_status: :evidence_insufficient
          }
        }
      )

    contract =
      site_field_contract([
        %BindingProjection{
          source_binding_kind: :value,
          source_binding_id: "vb_opaque",
          projection_kind: :scalar_attr,
          public_attr_name: "title",
          target_node_id: "node_site"
        }
      ])

    assert {:error, diagnostics} = ComponentContract.validate_ir_references(contract, document)

    assert Enum.any?(
             diagnostics,
             &(&1.code == "component_contract.binding.evidence_insufficient")
           )
  end

  test "slot projections reject collection-scoped bindings" do
    document =
      document_with_bindings(
        site_node_id: "node_site",
        repeat_root_id: "node_repeat",
        value_bindings: %{
          "vb_item" => %ValueBinding{
            value_binding_id: "vb_item",
            target_node_id: "node_site",
            target_kind: :text,
            value_kind: :field,
            scope: :collection_item,
            collection_binding_id: "cb_shared"
          }
        }
      )

    contract =
      site_field_contract([
        %BindingProjection{
          source_binding_kind: :value,
          source_binding_id: "vb_item",
          projection_kind: :slot,
          public_slot_name: "inner",
          target_node_id: "node_site"
        }
      ])

    assert {:error, diagnostics} = ComponentContract.validate_ir_references(contract, document)

    assert Enum.any?(
             diagnostics,
             &(&1.code == "component_contract.projection.binding_kind_mismatch")
           )
  end
end
