defmodule LiveFrames.NativeGenerator.NodeStyleIdentityTest do
  use ExUnit.Case, async: true

  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.NativeGenerator.NodeStyleIdentity

  @root_class "lf-section-marketing-block"

  test "assigns the canonical private class to a root node" do
    root = DesignNode.new([1])

    assert {:ok, index} =
             NodeStyleIdentity.build(DesignDocument.new(root_nodes: [root]), @root_class)

    assert index.private_class_by_id[root.node_id] ==
             "lf-section-marketing-block__n-000001"

    assert index.path_by_id[root.node_id] == [1]
  end

  test "uses absolute one-based paths for nested nodes and multiple roots" do
    first_root =
      DesignNode.new([1], children: [DesignNode.new([1, 1]), DesignNode.new([1, 2])])

    second_root = DesignNode.new([2])

    assert {:ok, index} =
             NodeStyleIdentity.build(
               DesignDocument.new(root_nodes: [first_root, second_root]),
               @root_class
             )

    assert index.private_class_by_id["node_000001_000001"] ==
             "lf-section-marketing-block__n-000001-000001"

    assert index.private_class_by_id["node_000001_000002"] ==
             "lf-section-marketing-block__n-000001-000002"

    assert index.private_class_by_id["node_000002"] ==
             "lf-section-marketing-block__n-000002"

    assert Map.keys(index.nodes_by_id) |> Enum.sort() ==
             ["node_000001", "node_000001_000001", "node_000001_000002", "node_000002"]
  end

  test "returns the same index for the same document" do
    document = DesignDocument.new(root_nodes: [DesignNode.new([1])])

    assert NodeStyleIdentity.build(document, @root_class) ==
             NodeStyleIdentity.build(document, @root_class)
  end

  test "rejects a node id that does not match its canonical path" do
    node = %DesignNode{node_id: "node_000002", children: []}
    document = DesignDocument.new(root_nodes: [node])

    assert {:error, diagnostic} = NodeStyleIdentity.build(document, @root_class)
    assert diagnostic.code == "native_generator.styling.node_identity_mismatch"
    assert diagnostic.metadata.path == [1]
    assert diagnostic.metadata.expected_node_id == "node_000001"
    assert diagnostic.metadata.actual_node_id == "node_000002"
  end

  test "never derives selector text from an arbitrary node id" do
    malicious_id = "node_000001 .pwned"
    node = %DesignNode{node_id: malicious_id, children: []}

    assert {:error, diagnostic} =
             NodeStyleIdentity.build(DesignDocument.new(root_nodes: [node]), @root_class)

    assert diagnostic.code == "native_generator.styling.node_identity_mismatch"
    refute Map.has_key?(diagnostic.metadata, :private_class)
    refute inspect(diagnostic.metadata) =~ @root_class <> "__n-" <> malicious_id
  end
end
