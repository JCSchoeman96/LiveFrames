defmodule LiveFrames.Behavior.BindingIdentity do
  @moduledoc """
  Assigns deterministic occurrence identities to structurally valid behavior bindings.
  """

  alias LiveFrames.Behavior.Binding
  alias LiveFrames.Behavior.Binding.ControlledTarget
  alias LiveFrames.Behavior.Binding.FocusPolicy
  alias LiveFrames.Behavior.Binding.PrimitiveRef
  alias LiveFrames.Behavior.Binding.ResponsiveBehaviorOverride
  alias LiveFrames.Behavior.Binding.Trigger
  alias LiveFrames.Behavior.Contract
  alias LiveFrames.CanonicalJSON
  alias LiveFrames.IR.Identity

  @algorithm "lf-behavior-binding-v1-jcs-sha256"
  @current_format_version "1.0.0"

  @spec algorithm() :: String.t()
  def algorithm, do: @algorithm

  @spec assign(term()) :: {:ok, Contract.t()} | {:error, term()}
  def assign(%Contract{} = contract) do
    with :ok <- validate_contract(contract),
         {:ok, entries} <- encode_discriminators(contract.bindings),
         {:ok, ordinals} <- assign_ordinals(entries),
         {:ok, identified} <- identify_bindings(entries, ordinals, contract) do
      {:ok, %{contract | bindings: identified}}
    end
  end

  def assign(_contract), do: {:error, :invalid_contract}

  defp validate_contract(%Contract{
         contract_format_version: @current_format_version,
         design_document_identity: %Identity{},
         bindings: bindings
       })
       when is_list(bindings),
       do: :ok

  defp validate_contract(_contract), do: {:error, :invalid_contract}

  defp encode_discriminators(bindings) do
    bindings
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {binding, index}, {:ok, entries} ->
      case Binding.validate(binding) do
        :ok ->
          with {:ok, value} <- discriminator(binding),
               {:ok, bytes} <- CanonicalJSON.encode(value) do
            entry = %{
              index: index,
              binding: binding,
              group: group_key(binding),
              discriminator_bytes: bytes
            }

            {:cont, {:ok, [entry | entries]}}
          else
            {:error, error} -> {:halt, {:error, {:invalid_discriminator, index, error}}}
          end

        {:error, reason} ->
          {:halt, {:error, {:invalid_binding, index, reason}}}
      end
    end)
    |> case do
      {:ok, entries} -> {:ok, Enum.reverse(entries)}
      error -> error
    end
  end

  defp discriminator(%Binding{} = binding) do
    with {:ok, triggers} <- canonical_trigger_order(binding.triggers) do
      {:ok,
       %{
         "owner_node_id" => binding.owner_node_id,
         "primitive_kind" => binding.primitive_ref.kind,
         "binding_role" => binding.binding_role,
         "initial_state" => binding.initial_state,
         "primitive_policy_values" => binding.primitive_policy_values,
         "triggers" => triggers,
         "controlled_targets" =>
           binding.controlled_targets
           |> Enum.sort_by(&{&1.role, &1.node_id})
           |> Enum.map(&target_value/1),
         "timer_policy" => binding.timer_policy,
         "focus_policy" => focus_value(binding.focus_policy),
         "keyboard_policy" => binding.keyboard_policy,
         "motion_policy" => binding.motion_policy,
         "responsive_overrides" =>
           binding.responsive_overrides
           |> Enum.sort_by(& &1.mode)
           |> Enum.map(&override_value/1)
       }}
    end
  end

  defp canonical_trigger_order(triggers) do
    triggers
    |> Enum.map(&trigger_value/1)
    |> Enum.reduce_while({:ok, []}, fn value, {:ok, encoded} ->
      case CanonicalJSON.encode(value) do
        {:ok, bytes} -> {:cont, {:ok, [{bytes, value} | encoded]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, encoded} ->
        {:ok, encoded |> Enum.sort_by(&elem(&1, 0)) |> Enum.map(&elem(&1, 1))}

      error ->
        error
    end
  end

  defp trigger_value(%Trigger{kind: kind, origin_node_id: origin_node_id}) do
    %{"kind" => kind, "origin_node_id" => origin_node_id}
  end

  defp target_value(%ControlledTarget{role: role, node_id: node_id}) do
    %{"role" => role, "node_id" => node_id}
  end

  defp focus_value(nil), do: nil

  defp focus_value(%FocusPolicy{} = focus) do
    %{
      "initial_strategy" => focus.initial_strategy,
      "initial_target_node_id" => focus.initial_target_node_id,
      "containment_strategy" => focus.containment_strategy,
      "movement_strategy" => focus.movement_strategy,
      "scope_node_id" => focus.scope_node_id,
      "restoration_strategy" => focus.restoration_strategy,
      "restoration_target_node_id" => focus.restoration_target_node_id,
      "restoration_fallback_node_id" => focus.restoration_fallback_node_id
    }
  end

  defp override_value(%ResponsiveBehaviorOverride{} = override) do
    %{
      "mode" => override.mode,
      "authority_ref" => override.authority_ref,
      "state_mapping" => override.state_mapping
    }
  end

  defp group_key(%Binding{
         owner_node_id: owner_node_id,
         primitive_ref: %PrimitiveRef{kind: primitive_kind},
         binding_role: binding_role
       }),
       do: {owner_node_id, primitive_kind, binding_role}

  defp assign_ordinals(entries) do
    groups = Enum.group_by(entries, & &1.group)

    if Enum.any?(groups, fn {_key, group} -> duplicate_discriminator?(group) end) do
      {:error, :duplicate_semantic_binding}
    else
      ordinals =
        Enum.reduce(groups, %{}, fn {_key, group}, assigned ->
          group
          |> Enum.sort_by(& &1.discriminator_bytes)
          |> Enum.with_index()
          |> Enum.reduce(assigned, fn {entry, ordinal}, acc ->
            Map.put(acc, entry.index, ordinal)
          end)
        end)

      {:ok, ordinals}
    end
  end

  defp duplicate_discriminator?(group) do
    bytes = Enum.map(group, & &1.discriminator_bytes)
    length(bytes) != MapSet.size(MapSet.new(bytes))
  end

  defp identify_bindings(entries, ordinals, %Contract{} = contract) do
    entries
    |> Enum.reduce_while({:ok, %{}}, fn entry, {:ok, identified} ->
      ordinal = Map.fetch!(ordinals, entry.index)

      case binding_id_payload(entry.binding, contract, ordinal)
           |> CanonicalJSON.encode() do
        {:ok, payload_bytes} ->
          id = "bnd_" <> (:crypto.hash(:sha256, payload_bytes) |> Base.encode16(case: :lower))
          binding = %{entry.binding | binding_id: id, ordinal: ordinal}
          {:cont, {:ok, Map.put(identified, entry.index, binding)}}

        {:error, error} ->
          {:halt, {:error, {:invalid_contract, error}}}
      end
    end)
    |> case do
      {:ok, identified} ->
        if map_size(identified) == 0 do
          {:ok, []}
        else
          {:ok, Enum.map(0..(map_size(identified) - 1), &Map.fetch!(identified, &1))}
        end

      error ->
        error
    end
  end

  defp binding_id_payload(%Binding{} = binding, %Contract{} = contract, ordinal) do
    %{
      "behavior_contract_format_version" => contract.contract_format_version,
      "design_document_identity" => identity_value(contract.design_document_identity),
      "owner_node_id" => binding.owner_node_id,
      "primitive_kind" => binding.primitive_ref.kind,
      "binding_role" => binding.binding_role,
      "ordinal" => ordinal
    }
  end

  defp identity_value(%Identity{} = identity) do
    %{
      "ir_version" => identity.ir_version,
      "canonicalization_id" => identity.canonicalization_id,
      "digest_algorithm" => identity.digest_algorithm,
      "digest" => identity.digest
    }
  end
end
