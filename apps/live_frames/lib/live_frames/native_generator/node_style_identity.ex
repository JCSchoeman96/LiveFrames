defmodule LiveFrames.NativeGenerator.NodeStyleIdentity do
  @moduledoc false

  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.NativeGenerator.Diagnostic

  @identity_mismatch_code "native_generator.styling.node_identity_mismatch"

  @spec build(DesignDocument.t(), String.t()) ::
          {:ok,
           %{
             nodes_by_id: %{optional(String.t()) => DesignNode.t()},
             path_by_id: %{optional(String.t()) => [pos_integer()]},
             private_class_by_id: %{optional(String.t()) => String.t()}
           }}
          | {:error, Diagnostic.t()}
  def build(%DesignDocument{root_nodes: root_nodes}, package_root_class)
      when is_binary(package_root_class) do
    index = %{nodes_by_id: %{}, path_by_id: %{}, private_class_by_id: %{}}

    index_nodes(root_nodes, [], package_root_class, index)
  end

  defp index_nodes(nodes, reversed_parent_path, package_root_class, index) do
    nodes
    |> Enum.with_index(1)
    |> Enum.reduce_while({:ok, index}, fn {node, position}, {:ok, acc} ->
      reversed_path = [position | reversed_parent_path]
      path = Enum.reverse(reversed_path)
      expected_node_id = DesignNode.deterministic_id(path)

      if node.node_id == expected_node_id do
        node_index = put_node(acc, node, path, package_root_class)

        case index_nodes(node.children, reversed_path, package_root_class, node_index) do
          {:ok, updated_index} -> {:cont, {:ok, updated_index}}
          {:error, diagnostic} -> {:halt, {:error, diagnostic}}
        end
      else
        diagnostic =
          Diagnostic.error(
            @identity_mismatch_code,
            "DesignNode node_id does not match its canonical traversal path",
            %{
              path: path,
              expected_node_id: expected_node_id,
              actual_node_id: node.node_id
            }
          )

        {:halt, {:error, diagnostic}}
      end
    end)
  end

  defp put_node(index, node, path, package_root_class) do
    private_class = package_root_class <> "__n-" <> private_path_suffix(path)

    %{
      nodes_by_id: Map.put(index.nodes_by_id, node.node_id, node),
      path_by_id: Map.put(index.path_by_id, node.node_id, path),
      private_class_by_id: Map.put(index.private_class_by_id, node.node_id, private_class)
    }
  end

  defp private_path_suffix(path) do
    Enum.map_join(path, "-", fn segment ->
      String.pad_leading(Integer.to_string(segment), 6, "0")
    end)
  end
end
