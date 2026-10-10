defmodule LiveFrames.Behavior.Validation do
  @moduledoc """
  Validates BehaviorContract structure and references against one DesignDocument.
  """

  alias LiveFrames.Behavior.Binding
  alias LiveFrames.Behavior.BindingIdentity
  alias LiveFrames.Behavior.Contract
  alias LiveFrames.Behavior.Diagnostic
  alias LiveFrames.Behavior.Serializer
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Identity

  @spec validate_structure(term(), term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate_structure(design_document, %Contract{} = contract) do
    with {:ok, document_identity} <- document_identity(design_document),
         {:ok, _bytes} <- Serializer.encode(contract),
         :ok <- exact_identity(contract.design_document_identity, document_identity),
         :ok <- verify_binding_identities(contract),
         index <- index_nodes(design_document.root_nodes),
         :ok <- validate_binding_references(contract.bindings, index),
         :ok <- validate_diagnostic_references(contract, index) do
      :ok
    else
      {:error, [%Diagnostic{} | _] = diagnostics} -> {:error, diagnostics}
      {:error, _reason} -> {:error, [diagnostic("behavior.design_document.invalid", "structure")]}
    end
  end

  def validate_structure(_design_document, _contract),
    do: {:error, [diagnostic("behavior.contract.invalid", "structure")]}

  defp document_identity(document) do
    case Identity.from_document(document) do
      {:ok, identity} ->
        {:ok, identity}

      {:error, _diagnostics} ->
        {:error, [diagnostic("behavior.design_document.invalid", "structure")]}
    end
  end

  defp exact_identity(identity, identity), do: :ok

  defp exact_identity(_contract_identity, _document_identity),
    do: {:error, [diagnostic("behavior.design_document.identity_mismatch", "identity")]}

  defp verify_binding_identities(%Contract{} = contract) do
    pre_identity_bindings =
      Enum.map(contract.bindings, fn %Binding{} = binding ->
        %{binding | binding_id: nil, ordinal: nil}
      end)

    pre_identity_contract = %Contract{
      contract_format_version: contract.contract_format_version,
      design_document_identity: contract.design_document_identity,
      bindings: pre_identity_bindings
    }

    case BindingIdentity.assign(pre_identity_contract) do
      {:ok, %Contract{bindings: recomputed}} ->
        if Enum.zip(contract.bindings, recomputed)
           |> Enum.all?(fn {persisted, assigned} ->
             persisted.binding_id == assigned.binding_id and persisted.ordinal == assigned.ordinal
           end) and length(contract.bindings) == length(recomputed) do
          :ok
        else
          {:error, [diagnostic("behavior.binding.identity_mismatch", "identity")]}
        end

      {:error, _reason} ->
        {:error, [diagnostic("behavior.binding.identity_mismatch", "identity")]}
    end
  end

  defp index_nodes(root_nodes) do
    root_nodes
    |> Enum.reverse()
    |> Enum.map(&{&1, nil})
    |> index_stack(%{}, %{})
  end

  defp index_stack([], nodes_by_id, parent_by_id),
    do: %{nodes_by_id: nodes_by_id, parent_by_id: parent_by_id}

  defp index_stack([{%DesignNode{} = node, parent_id} | rest], nodes_by_id, parent_by_id) do
    children = Enum.reverse(node.children) |> Enum.map(&{&1, node.node_id})

    index_stack(
      children ++ rest,
      Map.put(nodes_by_id, node.node_id, node),
      Map.put(parent_by_id, node.node_id, parent_id)
    )
  end

  defp validate_binding_references(bindings, index) do
    Enum.reduce_while(bindings, :ok, fn binding, :ok ->
      case validate_one_binding_references(binding, index) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_one_binding_references(binding, index) do
    owner_id = binding.owner_node_id

    cond do
      not Map.has_key?(index.nodes_by_id, owner_id) ->
        unresolved(owner_id, binding.binding_id)

      true ->
        binding
        |> binding_node_references()
        |> Enum.reduce_while(:ok, fn node_id, :ok ->
          cond do
            not Map.has_key?(index.nodes_by_id, node_id) ->
              {:halt, unresolved(node_id, binding.binding_id)}

            descendant_or_owner?(node_id, owner_id, index.parent_by_id) ->
              {:cont, :ok}

            true ->
              {:halt, outside_owner(node_id, binding.binding_id)}
          end
        end)
    end
  end

  defp binding_node_references(binding) do
    trigger_refs = Enum.map(binding.triggers, & &1.origin_node_id)
    target_refs = Enum.map(binding.controlled_targets, & &1.node_id)

    focus_refs =
      case binding.focus_policy do
        nil ->
          []

        focus ->
          [
            focus.initial_target_node_id,
            focus.scope_node_id,
            focus.restoration_target_node_id,
            focus.restoration_fallback_node_id
          ]
      end

    [trigger_refs, target_refs, focus_refs]
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
  end

  defp descendant_or_owner?(node_id, owner_id, _parent_by_id) when node_id == owner_id, do: true

  defp descendant_or_owner?(node_id, owner_id, parent_by_id) do
    case Map.fetch(parent_by_id, node_id) do
      {:ok, nil} -> false
      {:ok, ^owner_id} -> true
      {:ok, parent_id} -> descendant_or_owner?(parent_id, owner_id, parent_by_id)
      :error -> false
    end
  end

  defp validate_diagnostic_references(contract, index) do
    diagnostics =
      Enum.flat_map(contract.bindings, & &1.diagnostics) ++ contract.diagnostics

    Enum.reduce_while(diagnostics, :ok, fn diagnostic, :ok ->
      case diagnostic.node_id do
        nil ->
          {:cont, :ok}

        node_id when is_map_key(index.nodes_by_id, node_id) ->
          {:cont, :ok}

        node_id ->
          {:halt,
           {:error,
            [
              %Diagnostic{
                code: "behavior.diagnostic.node_unresolved",
                severity: "error",
                category: "reference",
                binding_id: diagnostic.binding_id,
                node_id: node_id,
                evidence_id: diagnostic.evidence_id,
                message: "Diagnostic node reference does not resolve in the DesignDocument"
              }
            ]}}
      end
    end)
  end

  defp unresolved(node_id, binding_id) do
    {:error,
     [
       %Diagnostic{
         code: "behavior.reference.unresolved",
         severity: "error",
         category: "reference",
         binding_id: binding_id,
         node_id: node_id,
         message: "Behavior node reference does not resolve in the DesignDocument"
       }
     ]}
  end

  defp outside_owner(node_id, binding_id) do
    {:error,
     [
       %Diagnostic{
         code: "behavior.reference.outside_owner",
         severity: "error",
         category: "reference",
         binding_id: binding_id,
         node_id: node_id,
         message: "Behavior node reference is outside the binding owner subtree"
       }
     ]}
  end

  defp diagnostic(code, category) do
    %Diagnostic{
      code: code,
      severity: "error",
      category: category,
      message: "Behavior structure validation failed"
    }
  end
end
