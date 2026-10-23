defmodule LiveFrames.Behavior.BindingContainment do
  @moduledoc """
  Shared reference indexing and binding containment classification for Behavior gates.
  """

  alias LiveFrames.Behavior.Binding
  alias LiveFrames.Behavior.Binding.ControlledTarget
  alias LiveFrames.Behavior.Binding.FocusPolicy
  alias LiveFrames.Behavior.Binding.Trigger
  alias LiveFrames.Behavior.Contract
  alias LiveFrames.Behavior.Diagnostic
  alias LiveFrames.Behavior.Validation
  alias LiveFrames.IR.{DesignDocument, DesignNode, Interaction}

  @type disposition :: :contained | :outside_candidate | :split | :unresolved

  defmodule Context do
    @moduledoc false
    defstruct [:node_index, :candidate_nodes]
  end

  @reference_roles [
    :binding_owner,
    :controlled_target,
    :trigger_origin,
    :focus_reference,
    :ir_interaction_ref,
    :ir_interaction_target
  ]

  @spec reference_index(DesignDocument.t(), Contract.t()) ::
          {:ok, %{optional(String.t()) => MapSet.t(atom())}}
          | {:error, [Diagnostic.t()]}
  def reference_index(%DesignDocument{} = design_document, %Contract{} = behavior_contract) do
    with :ok <- Validation.validate_structure(design_document, behavior_contract) do
      index =
        design_document.root_nodes
        |> index_interaction_refs(%{})
        |> index_interaction_targets(design_document.interactions)
        |> index_behavior_references(behavior_contract.bindings)

      {:ok, index}
    else
      {:error, diagnostics} -> {:error, diagnostics}
    end
  rescue
    _error ->
      {:error, [reference_index_diagnostic()]}
  end

  def reference_index(_design_document, _behavior_contract),
    do: {:error, [reference_index_diagnostic()]}

  @spec prepare(DesignDocument.t(), String.t()) :: Context.t()
  def prepare(%DesignDocument{} = design_document, boundary_node_id)
      when is_binary(boundary_node_id) do
    node_index = index_nodes(design_document.root_nodes)
    candidate_nodes = subtree_node_ids(boundary_node_id, node_index)

    %Context{node_index: node_index, candidate_nodes: candidate_nodes}
  end

  @spec classify_binding(Binding.t(), Context.t()) :: disposition()
  def classify_binding(%Binding{} = binding, %Context{
        node_index: index,
        candidate_nodes: candidate_nodes
      }) do
    refs = binding_node_references(binding)

    cond do
      Enum.any?(refs, &(not Map.has_key?(index, &1))) ->
        :unresolved

      Enum.all?(refs, &MapSet.member?(candidate_nodes, &1)) ->
        :contained

      Enum.all?(refs, &(not MapSet.member?(candidate_nodes, &1))) ->
        :outside_candidate

      true ->
        :split
    end
  end

  defp index_interaction_refs(nodes, index) do
    nodes
    |> Enum.reduce([], &[&1 | &2])
    |> index_interaction_ref_stack(index)
  end

  defp index_interaction_ref_stack([], index), do: index

  defp index_interaction_ref_stack(
         [
           %DesignNode{node_id: node_id, interaction_refs: interaction_refs, children: children}
           | rest
         ],
         index
       ) do
    index =
      if interaction_refs == [] do
        index
      else
        add_reference(index, node_id, :ir_interaction_ref)
      end

    next = Enum.reduce(children, rest, &[&1 | &2])
    index_interaction_ref_stack(next, index)
  end

  defp index_interaction_targets(index, interactions) do
    Enum.reduce(interactions, index, fn
      {_interaction_id, %Interaction{target_node_ids: target_node_ids}}, index ->
        Enum.reduce(target_node_ids, index, &add_reference(&2, &1, :ir_interaction_target))
    end)
  end

  defp index_behavior_references(index, bindings) do
    Enum.reduce(bindings, index, fn %Binding{} = binding, index ->
      index = add_reference(index, binding.owner_node_id, :binding_owner)

      index =
        Enum.reduce(binding.controlled_targets, index, fn %ControlledTarget{node_id: node_id},
                                                          index ->
          add_reference(index, node_id, :controlled_target)
        end)

      index =
        Enum.reduce(binding.triggers, index, fn
          %Trigger{origin_node_id: nil}, index ->
            index

          %Trigger{origin_node_id: node_id}, index ->
            add_reference(index, node_id, :trigger_origin)
        end)

      case binding.focus_policy do
        %FocusPolicy{} = focus_policy ->
          [
            focus_policy.initial_target_node_id,
            focus_policy.scope_node_id,
            focus_policy.restoration_target_node_id,
            focus_policy.restoration_fallback_node_id
          ]
          |> Enum.reject(&is_nil/1)
          |> Enum.reduce(index, &add_reference(&2, &1, :focus_reference))

        _focus_policy ->
          index
      end
    end)
  end

  defp add_reference(index, node_id, role) when is_binary(node_id) and role in @reference_roles do
    Map.update(index, node_id, MapSet.new([role]), &MapSet.put(&1, role))
  end

  defp add_reference(index, _node_id, _role), do: index

  defp index_nodes(nodes), do: index_nodes(nodes, %{})

  defp index_nodes([], index), do: index

  defp index_nodes([%DesignNode{node_id: node_id, children: children} | rest], index) do
    index = Map.put(index, node_id, children)
    index = index_nodes(children, index)
    index_nodes(rest, index)
  end

  defp subtree_node_ids(boundary_node_id, index),
    do: subtree_node_ids([boundary_node_id], index, MapSet.new())

  defp subtree_node_ids([], _index, node_ids), do: node_ids

  defp subtree_node_ids([node_id | rest], index, node_ids) do
    if MapSet.member?(node_ids, node_id) do
      subtree_node_ids(rest, index, node_ids)
    else
      child_ids = index |> Map.get(node_id, []) |> Enum.map(& &1.node_id)
      subtree_node_ids(child_ids ++ rest, index, MapSet.put(node_ids, node_id))
    end
  end

  defp binding_node_references(%Binding{} = binding) do
    ([binding.owner_node_id] ++
       Enum.flat_map(binding.triggers, fn
         %Trigger{origin_node_id: nil} -> []
         %Trigger{origin_node_id: node_id} -> [node_id]
       end) ++
       Enum.map(binding.controlled_targets, fn %ControlledTarget{node_id: node_id} -> node_id end) ++
       focus_node_references(binding.focus_policy))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp focus_node_references(%FocusPolicy{} = focus_policy) do
    [
      focus_policy.initial_target_node_id,
      focus_policy.scope_node_id,
      focus_policy.restoration_target_node_id,
      focus_policy.restoration_fallback_node_id
    ]
  end

  defp focus_node_references(_focus_policy), do: []

  defp reference_index_diagnostic do
    %Diagnostic{
      code: "behavior.design_document.invalid",
      severity: "error",
      category: "structure",
      message: "DesignDocument and BehaviorContract cannot form a reference index"
    }
  end
end
