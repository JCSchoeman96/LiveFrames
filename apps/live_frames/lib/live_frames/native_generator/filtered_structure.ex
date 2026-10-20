defmodule LiveFrames.NativeGenerator.FilteredStructure do
  @moduledoc """
  Immutable generation-time structure indexed from the original DesignDocument.
  """

  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.NativeGenerator.Diagnostic
  alias LiveFrames.NativeGenerator.NodeStyleIdentity

  @type t :: %__MODULE__{
          boundary_node_id: String.t(),
          root_node_ids: [String.t()],
          nodes_by_id: %{optional(String.t()) => LiveFrames.IR.DesignNode.t()},
          children_by_id: %{optional(String.t()) => [String.t()]},
          path_by_id: %{optional(String.t()) => [pos_integer()]},
          private_class_by_id: %{optional(String.t()) => String.t()}
        }

  defstruct boundary_node_id: nil,
            root_node_ids: [],
            nodes_by_id: %{},
            children_by_id: %{},
            path_by_id: %{},
            private_class_by_id: %{}

  @spec build(DesignDocument.t(), String.t(), [String.t()], String.t()) ::
          {:ok, t()} | {:error, Diagnostic.t()}
  def build(
        %DesignDocument{root_nodes: root_node_ids} = design_document,
        boundary_node_id,
        authorized_disposed_node_ids,
        package_root_class
      )
      when is_binary(boundary_node_id) and is_list(authorized_disposed_node_ids) and
             is_binary(package_root_class) do
    with {:ok, original_identity} <- NodeStyleIdentity.build(design_document, package_root_class) do
      disposed_ids = MapSet.new(authorized_disposed_node_ids)

      nodes_by_id = retain_index(original_identity.nodes_by_id, disposed_ids)
      path_by_id = retain_index(original_identity.path_by_id, disposed_ids)
      private_class_by_id = retain_index(original_identity.private_class_by_id, disposed_ids)

      case Map.fetch(nodes_by_id, boundary_node_id) do
        {:ok, _boundary_node} ->
          children_by_id =
            Map.new(nodes_by_id, fn {node_id, node} ->
              child_ids =
                node.children
                |> Enum.map(& &1.node_id)
                |> Enum.reject(&MapSet.member?(disposed_ids, &1))

              {node_id, child_ids}
            end)

          root_node_ids =
            root_node_ids
            |> Enum.map(& &1.node_id)
            |> Enum.reject(&MapSet.member?(disposed_ids, &1))

          {:ok,
           %__MODULE__{
             boundary_node_id: boundary_node_id,
             root_node_ids: root_node_ids,
             nodes_by_id: nodes_by_id,
             children_by_id: children_by_id,
             path_by_id: path_by_id,
             private_class_by_id: private_class_by_id
           }}

        :error ->
          {:error,
           Diagnostic.error(
             "native_generator.boundary_missing",
             "boundary node is missing from the design document"
           )}
      end
    end
  end

  def build(
        _design_document,
        _boundary_node_id,
        _authorized_disposed_node_ids,
        _package_root_class
      ) do
    {:error,
     Diagnostic.error(
       "native_generator.filtered_structure.invalid_input",
       "filtered structure inputs are invalid"
     )}
  end

  @spec children(t(), String.t()) :: [String.t()]
  def children(%__MODULE__{children_by_id: children_by_id}, design_node_id) do
    Map.get(children_by_id, design_node_id, [])
  end

  defp retain_index(index, disposed_ids) do
    Map.reject(index, fn {design_node_id, _value} ->
      MapSet.member?(disposed_ids, design_node_id)
    end)
  end
end
