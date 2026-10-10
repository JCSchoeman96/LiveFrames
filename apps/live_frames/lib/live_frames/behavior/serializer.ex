defmodule LiveFrames.Behavior.Serializer do
  @moduledoc """
  Canonically serializes structurally valid BehaviorContracts.
  """

  alias LiveFrames.Behavior.Contract
  alias LiveFrames.Behavior.Diagnostic
  alias LiveFrames.Behavior.Binding
  alias LiveFrames.Behavior.Binding.ControlledTarget
  alias LiveFrames.Behavior.Binding.FocusPolicy
  alias LiveFrames.Behavior.Binding.PrimitiveRef
  alias LiveFrames.Behavior.Binding.ResponsiveBehaviorOverride
  alias LiveFrames.Behavior.Binding.Trigger
  alias LiveFrames.CanonicalJSON
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.Identity

  @algorithm "lf-behavior-v1-jcs-sha256"
  @current_format_version "1.0.0"
  @digest_pattern ~r/\A[0-9a-f]{64}\z/

  @spec algorithm() :: String.t()
  def algorithm, do: @algorithm

  @spec encode(term()) :: {:ok, binary()} | {:error, [Diagnostic.t()]}
  def encode(%Contract{} = contract) do
    with :ok <- contract_fields(contract),
         :ok <- supported_format(contract.contract_format_version),
         :ok <- identity_valid(contract.design_document_identity),
         {:ok, bindings} <- validate_bindings(contract.bindings),
         {:ok, diagnostics} <-
           validate_diagnostics(contract.diagnostics, binding_ids(bindings), :contract),
         :ok <- valid_contract_fields(contract),
         {:ok, bytes} <- CanonicalJSON.encode(contract_value(contract, bindings, diagnostics)) do
      {:ok, bytes}
    else
      {:error, %Diagnostic{} = diagnostic} -> {:error, [diagnostic]}
      {:error, _reason} -> {:error, [error_diagnostic()]}
    end
  end

  def encode(_contract), do: {:error, [error_diagnostic()]}

  @spec digest(term()) :: {:ok, String.t()} | {:error, [Diagnostic.t()]}
  def digest(contract) do
    case encode(contract) do
      {:ok, bytes} ->
        {:ok, :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)}

      {:error, diagnostics} ->
        {:error, diagnostics}
    end
  end

  defp contract_fields(contract) do
    expected = [
      :contract_format_version,
      :design_document_identity,
      :bindings,
      :diagnostics,
      :provenance
    ]

    if Enum.sort(Map.keys(contract)) == Enum.sort([:__struct__ | expected]) do
      :ok
    else
      invalid_contract()
    end
  end

  defp supported_format(@current_format_version), do: :ok

  defp supported_format(_version),
    do: {:error, diagnostic("behavior.contract.format_unsupported", "structure")}

  defp identity_valid(%Identity{} = identity) do
    expected = [:ir_version, :canonicalization_id, :digest_algorithm, :digest]

    if Enum.sort(Map.keys(identity)) == Enum.sort([:__struct__ | expected]) and
         identity.ir_version == DesignDocument.current_ir_version() and
         Identity.supported_canonicalization_id?(identity.canonicalization_id) and
         Identity.supported_digest_algorithm?(identity.digest_algorithm) and
         is_binary(identity.digest) and Regex.match?(@digest_pattern, identity.digest) do
      :ok
    else
      {:error, diagnostic("behavior.contract.identity_invalid", "identity")}
    end
  end

  defp identity_valid(_identity),
    do: {:error, diagnostic("behavior.contract.identity_invalid", "identity")}

  defp valid_contract_fields(%Contract{provenance: provenance})
       when is_map(provenance) and not is_struct(provenance) do
    provenance_valid(provenance)
  end

  defp valid_contract_fields(_contract), do: invalid_contract()

  defp validate_bindings(bindings) when is_list(bindings) do
    if proper_list?(bindings) do
      Enum.reduce_while(bindings, {:ok, [], MapSet.new()}, fn binding, {:ok, encoded, ids} ->
        with :ok <- persisted_binding_valid(binding),
             false <- MapSet.member?(ids, binding.binding_id),
             {:ok, value} <- binding_value(binding) do
          {:cont, {:ok, [value | encoded], MapSet.put(ids, binding.binding_id)}}
        else
          true ->
            {:halt,
             {:error,
              diagnostic("behavior.binding.identity_invalid", "identity", binding.binding_id)}}

          {:error, %Diagnostic{} = error} ->
            {:halt, {:error, error}}

          _ ->
            {:halt, {:error, diagnostic("behavior.binding.invalid", "structure")}}
        end
      end)
      |> case do
        {:ok, values, _ids} -> {:ok, Enum.reverse(values)}
        error -> error
      end
    else
      {:error, diagnostic("behavior.contract.invalid", "structure")}
    end
  end

  defp validate_bindings(_bindings),
    do: {:error, diagnostic("behavior.contract.invalid", "structure")}

  defp persisted_binding_valid(%Binding{} = binding) do
    expected = [
      :binding_id,
      :ordinal,
      :primitive_ref,
      :owner_node_id,
      :binding_role,
      :initial_state,
      :primitive_policy_values,
      :triggers,
      :controlled_targets,
      :timer_policy,
      :focus_policy,
      :keyboard_policy,
      :motion_policy,
      :responsive_overrides,
      :diagnostics,
      :provenance,
      :source_trace
    ]

    cond do
      Enum.sort(Map.keys(binding)) != Enum.sort([:__struct__ | expected]) ->
        {:error, diagnostic("behavior.binding.invalid", "structure")}

      not (is_binary(binding.binding_id) and
               Regex.match?(~r/\Abnd_[0-9a-f]{64}\z/, binding.binding_id)) ->
        {:error, diagnostic("behavior.binding.identity_invalid", "identity")}

      not (is_integer(binding.ordinal) and binding.ordinal >= 0) ->
        {:error, diagnostic("behavior.binding.identity_invalid", "identity", binding.binding_id)}

      true ->
        case safe_binding_validate(%{binding | binding_id: nil, ordinal: nil}) do
          :ok -> :ok
          {:error, _reason} -> {:error, diagnostic("behavior.binding.invalid", "structure")}
        end
    end
  end

  defp persisted_binding_valid(_binding),
    do: {:error, diagnostic("behavior.binding.invalid", "structure")}

  defp safe_binding_validate(binding) do
    Binding.validate(binding)
  rescue
    _error -> {:error, :invalid_structure}
  catch
    _kind, _reason -> {:error, :invalid_structure}
  end

  defp binding_value(%Binding{} = binding) do
    with {:ok, triggers} <- canonical_trigger_values(binding.triggers),
         {:ok, source_trace} <- source_trace_value(binding.source_trace),
         :ok <- provenance_valid(binding.provenance),
         {:ok, diagnostics} <- validate_diagnostics(binding.diagnostics, MapSet.new(), :binding) do
      {:ok,
       %{
         "binding_id" => binding.binding_id,
         "ordinal" => binding.ordinal,
         "primitive_ref" => primitive_ref_value(binding.primitive_ref),
         "owner_node_id" => binding.owner_node_id,
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
           |> Enum.map(&override_value/1),
         "diagnostics" => diagnostics,
         "provenance" => binding.provenance,
         "source_trace" => source_trace
       }}
    end
  end

  defp canonical_trigger_values(triggers) do
    triggers
    |> Enum.map(&trigger_value/1)
    |> Enum.reduce_while({:ok, []}, fn value, {:ok, entries} ->
      case CanonicalJSON.encode(value) do
        {:ok, bytes} ->
          {:cont, {:ok, [{bytes, value} | entries]}}

        {:error, _reason} ->
          {:halt, {:error, diagnostic("behavior.binding.invalid", "structure")}}
      end
    end)
    |> case do
      {:ok, entries} ->
        {:ok, entries |> Enum.sort_by(&elem(&1, 0)) |> Enum.map(&elem(&1, 1))}

      error ->
        error
    end
  end

  defp primitive_ref_value(%PrimitiveRef{kind: kind, definition_version: version}),
    do: %{"kind" => kind, "definition_version" => version}

  defp trigger_value(%Trigger{kind: kind, origin_node_id: origin}),
    do: %{"kind" => kind, "origin_node_id" => origin}

  defp target_value(%ControlledTarget{role: role, node_id: node_id}),
    do: %{"role" => role, "node_id" => node_id}

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

  defp override_value(%ResponsiveBehaviorOverride{
         mode: mode,
         authority_ref: authority,
         state_mapping: mapping
       }),
       do: %{"mode" => mode, "authority_ref" => authority, "state_mapping" => mapping}

  defp source_trace_value(nil), do: {:ok, nil}

  defp source_trace_value(%LiveFrames.IR.SourceTrace{} = trace) do
    expected = [
      :source_type,
      :source_id,
      :source_path,
      :source_name,
      :source_classes,
      :source_settings,
      :adapter,
      :adapter_version,
      :inference,
      :metadata
    ]

    scalars = [
      trace.source_type,
      trace.source_id,
      trace.source_path,
      trace.source_name,
      trace.adapter,
      trace.adapter_version,
      trace.inference
    ]

    classes_valid =
      proper_list?(trace.source_classes) and
        Enum.all?(trace.source_classes, &safe_string?/1) and
        length(trace.source_classes) == MapSet.size(MapSet.new(trace.source_classes))

    settings_valid = canonical_object?(trace.source_settings)
    metadata_valid = canonical_object?(trace.metadata)

    if Enum.sort(Map.keys(trace)) == Enum.sort([:__struct__ | expected]) and
         Enum.all?(scalars, &(is_nil(&1) or safe_string?(&1))) and classes_valid and
         settings_valid and metadata_valid do
      {:ok,
       %{
         "source_type" => trace.source_type,
         "source_id" => trace.source_id,
         "source_path" => trace.source_path,
         "source_name" => trace.source_name,
         "source_classes" => Enum.sort(trace.source_classes),
         "source_settings" => trace.source_settings,
         "adapter" => trace.adapter,
         "adapter_version" => trace.adapter_version,
         "inference" => trace.inference,
         "metadata" => trace.metadata
       }}
    else
      {:error, diagnostic("behavior.source_trace.invalid", "provenance")}
    end
  end

  defp source_trace_value(_trace),
    do: {:error, diagnostic("behavior.source_trace.invalid", "provenance")}

  defp validate_diagnostics(diagnostics, binding_ids, association) when is_list(diagnostics) do
    if proper_list?(diagnostics) do
      diagnostics
      |> Enum.reduce_while({:ok, []}, fn item, {:ok, entries} ->
        case diagnostic_value(item, binding_ids, association) do
          {:ok, value} ->
            case CanonicalJSON.encode(value) do
              {:ok, bytes} ->
                {:cont, {:ok, [{diagnostic_sort_key(value, bytes), value} | entries]}}

              {:error, _reason} ->
                {:halt, {:error, diagnostic("behavior.diagnostic.invalid", "structure")}}
            end

          error ->
            {:halt, error}
        end
      end)
      |> case do
        {:ok, entries} ->
          {:ok, entries |> Enum.sort_by(&elem(&1, 0)) |> Enum.map(&elem(&1, 1))}

        error ->
          error
      end
    else
      {:error, diagnostic("behavior.diagnostic.invalid", "structure")}
    end
  end

  defp validate_diagnostics(_diagnostics, _binding_ids, _association),
    do: {:error, diagnostic("behavior.diagnostic.invalid", "structure")}

  defp diagnostic_value(%Diagnostic{} = item, binding_ids, association) do
    expected = [
      :code,
      :severity,
      :category,
      :binding_id,
      :node_id,
      :evidence_id,
      :message,
      :suggested_action,
      :source_trace
    ]

    cond do
      Enum.sort(Map.keys(item)) != Enum.sort([:__struct__ | expected]) ->
        diagnostic_invalid()

      not (is_binary(item.code) and item.code != "" and safe_string?(item.code)) ->
        diagnostic_invalid()

      item.severity not in Diagnostic.severities() ->
        diagnostic_invalid()

      item.category not in Diagnostic.categories() ->
        diagnostic_invalid()

      association == :binding and not is_nil(item.binding_id) ->
        diagnostic_invalid()

      not optional_binding_id?(item.binding_id) ->
        diagnostic_invalid()

      association == :contract and not is_nil(item.binding_id) and
          not MapSet.member?(binding_ids, item.binding_id) ->
        {:error,
         diagnostic("behavior.diagnostic.binding_unresolved", "reference", item.binding_id)}

      not optional_safe_string?(item.binding_id) ->
        diagnostic_invalid()

      not optional_safe_string?(item.node_id) ->
        diagnostic_invalid()

      not optional_nonempty_safe_string?(item.evidence_id) ->
        diagnostic_invalid()

      not safe_string?(item.message) ->
        diagnostic_invalid()

      not optional_safe_string?(item.suggested_action) ->
        diagnostic_invalid()

      true ->
        case source_trace_value(item.source_trace) do
          {:ok, source_trace} ->
            {:ok,
             %{
               "code" => item.code,
               "severity" => item.severity,
               "category" => item.category,
               "binding_id" => item.binding_id,
               "node_id" => item.node_id,
               "evidence_id" => item.evidence_id,
               "message" => item.message,
               "suggested_action" => item.suggested_action,
               "source_trace" => source_trace
             }}

          error ->
            error
        end
    end
  end

  defp diagnostic_value(_item, _binding_ids, _association), do: diagnostic_invalid()

  defp diagnostic_sort_key(value, bytes) do
    {
      value["code"],
      value["severity"],
      value["category"],
      value["binding_id"] || "",
      value["node_id"] || "",
      value["evidence_id"] || "",
      value["message"],
      bytes
    }
  end

  defp binding_ids(bindings) do
    bindings
    |> Enum.map(&Map.fetch!(&1, "binding_id"))
    |> MapSet.new()
  end

  defp optional_safe_string?(nil), do: true
  defp optional_safe_string?(value), do: safe_string?(value)

  defp optional_binding_id?(nil), do: true

  defp optional_binding_id?(value) when is_binary(value),
    do: Regex.match?(~r/\Abnd_[0-9a-f]{64}\z/, value)

  defp optional_binding_id?(_value), do: false

  defp optional_nonempty_safe_string?(nil), do: true

  defp optional_nonempty_safe_string?(value),
    do: is_binary(value) and value != "" and safe_string?(value)

  defp diagnostic_invalid,
    do: {:error, diagnostic("behavior.diagnostic.invalid", "structure")}

  defp canonical_object?(value) when is_map(value) and not is_struct(value) do
    Enum.all?(Map.keys(value), &is_binary/1) and match?({:ok, _}, CanonicalJSON.encode(value))
  end

  defp canonical_object?(_value), do: false

  defp provenance_valid(value) do
    if canonical_object?(value) do
      :ok
    else
      {:error, diagnostic("behavior.provenance.invalid", "provenance")}
    end
  end

  defp safe_string?(value) when is_binary(value) do
    match?({:ok, _}, CanonicalJSON.encode(value))
  end

  defp safe_string?(_value), do: false

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_tail), do: false

  defp contract_value(contract, bindings, diagnostics) do
    %{
      "behavior_contract_format_version" => contract.contract_format_version,
      "design_document_identity" => identity_value(contract.design_document_identity),
      "bindings" => Enum.sort_by(bindings, &Map.fetch!(&1, "binding_id")),
      "diagnostics" => diagnostics,
      "provenance" => contract.provenance
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

  defp invalid_contract, do: {:error, diagnostic("behavior.contract.invalid", "structure")}

  defp error_diagnostic, do: diagnostic("behavior.contract.invalid", "structure")

  defp diagnostic(code, category, binding_id \\ nil) do
    %Diagnostic{
      code: code,
      severity: "error",
      category: category,
      binding_id: binding_id,
      message: "BehaviorContract structure is invalid"
    }
  end
end
