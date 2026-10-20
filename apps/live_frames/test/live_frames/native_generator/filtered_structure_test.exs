defmodule LiveFrames.NativeGenerator.FilteredStructureTest do
  use ExUnit.Case, async: true

  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.NativeGenerator.FilteredStructure
  alias LiveFrames.NativeGenerator.NodeStyleIdentity

  @boundary_id DesignNode.deterministic_id([1])
  @retained_before_id DesignNode.deterministic_id([1, 1])
  @disposed_id DesignNode.deterministic_id([1, 2])
  @retained_after_id DesignNode.deterministic_id([1, 3])
  @second_root_id DesignNode.deterministic_id([2])
  @package_root_class "lf-section-filtered-structure"

  defp document do
    %DesignDocument{
      root_nodes: [
        %DesignNode{
          node_id: @boundary_id,
          semantic_type: "section",
          children: [
            %DesignNode{node_id: @retained_before_id, semantic_type: "paragraph"},
            %DesignNode{node_id: @disposed_id, semantic_type: "raw"},
            %DesignNode{node_id: @retained_after_id, semantic_type: "paragraph"}
          ]
        },
        %DesignNode{node_id: @second_root_id, semantic_type: "section"}
      ]
    }
  end

  test "build filters exact IDs after preserving original paths and private classes" do
    design_document = document()
    original_document = design_document
    original_boundary = hd(design_document.root_nodes)

    assert {:ok, original_identity} =
             NodeStyleIdentity.build(design_document, @package_root_class)

    assert {:ok, filtered_structure} =
             FilteredStructure.build(
               design_document,
               @boundary_id,
               [@disposed_id],
               @package_root_class
             )

    assert Map.keys(filtered_structure) |> Enum.sort() ==
             [
               :__struct__,
               :boundary_node_id,
               :children_by_id,
               :nodes_by_id,
               :path_by_id,
               :private_class_by_id,
               :root_node_ids
             ]

    assert filtered_structure.boundary_node_id == @boundary_id
    assert filtered_structure.root_node_ids == [@boundary_id, @second_root_id]

    assert filtered_structure.children_by_id[@boundary_id] == [
             @retained_before_id,
             @retained_after_id
           ]

    assert FilteredStructure.children(filtered_structure, @boundary_id) == [
             @retained_before_id,
             @retained_after_id
           ]

    refute Map.has_key?(filtered_structure.nodes_by_id, @disposed_id)
    refute Map.has_key?(filtered_structure.children_by_id, @disposed_id)
    refute Map.has_key?(filtered_structure.path_by_id, @disposed_id)
    refute Map.has_key?(filtered_structure.private_class_by_id, @disposed_id)

    assert filtered_structure.nodes_by_id[@boundary_id] == original_boundary
    assert filtered_structure.path_by_id[@retained_before_id] == [1, 1]
    assert filtered_structure.path_by_id[@retained_after_id] == [1, 3]

    assert filtered_structure.path_by_id[@retained_after_id] ==
             original_identity.path_by_id[@retained_after_id]

    assert filtered_structure.private_class_by_id[@retained_after_id] ==
             original_identity.private_class_by_id[@retained_after_id]

    assert filtered_structure.private_class_by_id[@retained_after_id] ==
             "#{@package_root_class}__n-000001-000003"

    assert FilteredStructure.children(filtered_structure, @retained_before_id) == []
    assert FilteredStructure.children(filtered_structure, @disposed_id) == []
    assert FilteredStructure.children(filtered_structure, "unknown-node") == []
    assert design_document == original_document
    assert Enum.any?(hd(design_document.root_nodes).children, &(&1.node_id == @disposed_id))
  end

  test "an empty disposition set keeps the original root and child order" do
    design_document = document()

    assert {:ok, filtered_structure} =
             FilteredStructure.build(design_document, @boundary_id, [], @package_root_class)

    assert filtered_structure.root_node_ids == [@boundary_id, @second_root_id]

    assert filtered_structure.children_by_id[@boundary_id] == [
             @retained_before_id,
             @disposed_id,
             @retained_after_id
           ]
  end
end
