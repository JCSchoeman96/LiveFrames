defmodule LiveFrames.Behavior.Validation do
  @moduledoc """
  Validates BehaviorContract structure and references against one DesignDocument.
  """

  alias LiveFrames.Behavior.Binding
  alias LiveFrames.Behavior.BindingIdentity
  alias LiveFrames.Behavior.Contract
  alias LiveFrames.Behavior.Diagnostic
  alias LiveFrames.Behavior.PrimitiveRegistry
  alias LiveFrames.Behavior.Serializer
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Identity

  @safe_integer 9_007_199_254_740_991
  @selection_policy %{"alignment" => "position", "advance_boundary" => "wrap"}
  @timer_policy %{
    "purpose" => "advance_selection",
    "interval_ms" => 5_000,
    "start" => "on_initialization",
    "manual_activation" => "stop",
    "restart" => "never",
    "reset" => "none",
    "reduced_motion" => "disable_automatic_advance"
  }

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

  @spec validate_semantics(term(), Contract.t()) :: :ok | {:error, [Diagnostic.t()]}
  def validate_semantics(_design_document, %Contract{bindings: bindings}) do
    diagnostics =
      bindings
      |> Enum.flat_map(&validate_binding_semantics/1)
      |> Enum.sort_by(&{&1.binding_id || "", &1.code, &1.node_id || "", &1.message})

    case diagnostics do
      [] -> :ok
      diagnostics -> {:error, diagnostics}
    end
  end

  @spec validate(term(), term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate(design_document, behavior_contract) do
    case validate_structure(design_document, behavior_contract) do
      :ok -> validate_semantics(design_document, behavior_contract)
      {:error, _diagnostics} = error -> error
    end
  end

  defp validate_binding_semantics(binding) do
    case PrimitiveRegistry.resolve(binding.primitive_ref) do
      {:ok, {:selection_v1, default_position}} -> selection_diagnostics(binding, default_position)
      :error -> [semantic_diagnostic(binding, "primitive_unsupported", nil)]
    end
  end

  defp selection_diagnostics(binding, default_position) do
    targets = target_diagnostic(binding)
    control_node_id = single_control_node_id(binding.controlled_targets)

    [
      invalid_diagnostic(
        state_valid?(binding.initial_state, default_position),
        binding,
        "initial_state_invalid"
      ),
      invalid_diagnostic(
        binding.primitive_policy_values == @selection_policy,
        binding,
        "primitive_policy_invalid"
      ),
      invalid_diagnostic(
        triggers_valid?(binding, control_node_id),
        binding,
        "trigger_invalid",
        trigger_error_node(binding, control_node_id)
      ),
      targets,
      invalid_diagnostic(
        timer_policy_valid?(binding.timer_policy),
        binding,
        "timer_policy_invalid"
      ),
      invalid_diagnostic(
        cross_cutting_policy_valid?(binding),
        binding,
        "cross_cutting_policy_invalid"
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp state_valid?(nil, default_position),
    do:
      is_integer(default_position) and default_position >= 0 and default_position <= @safe_integer

  defp state_valid?(%{"selected_position" => value} = state, _default_position)
       when map_size(state) == 1 do
    is_integer(value) and value >= 0 and value <= @safe_integer
  end

  defp state_valid?(_state, _default_position), do: false

  defp target_diagnostic(binding) do
    targets = binding.controlled_targets
    controls = Enum.filter(targets, &(&1.role == "control_collection"))
    presentations = Enum.filter(targets, &(&1.role == "presentation_collection"))

    unknown_roles =
      Enum.reject(targets, &(&1.role in ["control_collection", "presentation_collection"]))

    duplicate_targets = duplicate_targets(targets)
    cardinality_valid = length(controls) == 1 and presentations != []

    if cardinality_valid and unknown_roles == [] and duplicate_targets == [] do
      nil
    else
      node_subjects =
        (unknown_roles ++ duplicate_targets)
        |> Enum.map(& &1.node_id)
        |> Enum.uniq()
        |> Enum.sort()

      node_id = target_error_node(cardinality_valid, node_subjects)
      semantic_diagnostic(binding, "target_invalid", node_id)
    end
  end

  defp target_error_node(true, [node_id]), do: node_id
  defp target_error_node(_cardinality_valid, _node_subjects), do: nil

  defp duplicate_targets(targets) do
    targets
    |> Enum.group_by(&{&1.role, &1.node_id})
    |> Enum.filter(fn {_key, records} -> length(records) > 1 end)
    |> Enum.map(fn {{role, node_id}, _records} ->
      %LiveFrames.Behavior.Binding.ControlledTarget{role: role, node_id: node_id}
    end)
    |> Enum.sort_by(&{&1.role, &1.node_id})
  end

  defp single_control_node_id(targets) do
    case Enum.filter(targets, &(&1.role == "control_collection")) do
      [%{node_id: node_id}] -> node_id
      _ -> nil
    end
  end

  defp triggers_valid?(binding, control_node_id) do
    activates = Enum.filter(binding.triggers, &(&1.kind == "activate"))
    timers = Enum.filter(binding.triggers, &(&1.kind == "timer"))
    unknown = Enum.reject(binding.triggers, &(&1.kind in ["activate", "timer"]))
    expected_timer_count = if is_nil(binding.timer_policy), do: 0, else: 1

    not is_nil(control_node_id) and length(activates) == 1 and
      length(timers) == expected_timer_count and unknown == [] and
      match?([%{origin_node_id: ^control_node_id}], activates) and
      (expected_timer_count == 0 or match?([%{origin_node_id: nil}], timers))
  end

  defp trigger_error_node(binding, control_node_id) do
    activates = Enum.filter(binding.triggers, &(&1.kind == "activate"))
    timers = Enum.filter(binding.triggers, &(&1.kind == "timer"))
    unknown = Enum.reject(binding.triggers, &(&1.kind in ["activate", "timer"]))

    bad_origins =
      (Enum.flat_map(activates, fn trigger ->
         if trigger.origin_node_id == control_node_id, do: [], else: [trigger.origin_node_id]
       end) ++
         Enum.flat_map(timers, fn trigger ->
           if is_nil(trigger.origin_node_id), do: [], else: [trigger.origin_node_id]
         end) ++
         Enum.map(unknown, & &1.origin_node_id))
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()

    case bad_origins do
      [node_id] -> node_id
      _ -> nil
    end
  end

  defp timer_policy_valid?(nil), do: true
  defp timer_policy_valid?(policy), do: policy === @timer_policy

  defp cross_cutting_policy_valid?(binding) do
    is_nil(binding.focus_policy) and is_nil(binding.keyboard_policy) and
      is_nil(binding.motion_policy) and binding.responsive_overrides == []
  end

  defp invalid_diagnostic(valid?, binding, suffix, node_id \\ nil)
  defp invalid_diagnostic(true, _binding, _suffix, _node_id), do: nil

  defp invalid_diagnostic(false, binding, suffix, node_id),
    do: semantic_diagnostic(binding, suffix, node_id)

  defp semantic_diagnostic(binding, suffix, node_id) do
    code = "behavior.semantic." <> suffix

    %Diagnostic{
      code: code,
      severity: "error",
      category: "semantic",
      binding_id: binding.binding_id,
      node_id: node_id,
      message: semantic_message(suffix)
    }
  end

  defp semantic_message("primitive_unsupported"), do: "Behavior primitive version is unsupported"
  defp semantic_message("initial_state_invalid"), do: "Selection initial state is invalid"
  defp semantic_message("primitive_policy_invalid"), do: "Selection primitive policy is invalid"
  defp semantic_message("trigger_invalid"), do: "Selection triggers are invalid"
  defp semantic_message("target_invalid"), do: "Selection controlled targets are invalid"
  defp semantic_message("timer_policy_invalid"), do: "Selection timer policy is invalid"

  defp semantic_message("cross_cutting_policy_invalid"),
    do: "Selection cross-cutting policy is invalid"

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
