defmodule LiveFrames.Catalogue.Lifecycle do
  @moduledoc """
  Pure CatalogueItem lifecycle transition engine for approved G1 v1 actions.

  Consumes explicit guard results and updates only `state` and
  `lifecycle.last_transition` on success.
  """

  alias LiveFrames.Catalogue.Manifest

  @approved_actions ~w(
    admit_to_catalogue
    validate
    review
    approve
    release
    publish_new_version
    deprecate
    retire
    withdraw
  )

  @valid_states ~w(
    DRAFT
    VALIDATED
    REVIEWED
    APPROVED
    RELEASED
    DEPRECATED
    RETIRED
    WITHDRAWN
  )

  @last_transition_keys ~w(action from to evidence_refs)

  @transitions %{
    "validate" => %{"DRAFT" => "VALIDATED"},
    "review" => %{"VALIDATED" => "REVIEWED"},
    "approve" => %{"REVIEWED" => "APPROVED"},
    "release" => %{"APPROVED" => "RELEASED"},
    "publish_new_version" => %{"RELEASED" => "RELEASED"},
    "deprecate" => %{"RELEASED" => "DEPRECATED"},
    "retire" => %{"DEPRECATED" => "RETIRED"},
    "withdraw" => %{
      "DRAFT" => "WITHDRAWN",
      "VALIDATED" => "WITHDRAWN",
      "REVIEWED" => "WITHDRAWN",
      "APPROVED" => "WITHDRAWN"
    }
  }

  @type diagnostic :: %{code: String.t(), path: String.t(), message: String.t()}

  @spec transition(Manifest.t(), String.t(), term()) ::
          {:ok, Manifest.t()} | {:error, diagnostic() | [diagnostic()] | term()}
  def transition(%Manifest{} = manifest, action, guard_result) when is_binary(action) do
    cond do
      action not in @approved_actions ->
        {:error, action_invalid(action)}

      action == "admit_to_catalogue" ->
        transition_admission(manifest, guard_result)

      true ->
        transition_lifecycle(manifest, action, guard_result)
    end
  end

  def transition(_manifest, action, _guard_result) when not is_binary(action) do
    {:error, action_invalid(inspect(action))}
  end

  @spec validate_snapshot(term()) :: :ok | {:error, [diagnostic()]}
  def validate_snapshot(%Manifest{} = manifest) do
    with :ok <- validate_snapshot_state(manifest.state),
         :ok <- validate_snapshot_lifecycle(manifest.lifecycle, manifest.state) do
      :ok
    else
      {:error, diagnostic} -> {:error, [diagnostic]}
    end
  end

  def validate_snapshot(_manifest) do
    {:error, [snapshot_invalid("$", "Expected a Catalogue Manifest struct.")]}
  end

  defp transition_admission(%Manifest{state: "DRAFT"} = manifest, guard_result) do
    cond do
      last_transition?(manifest) ->
        {:error, admission_invalid("Catalogue item was already admitted.")}

      true ->
        case consume_guard(guard_result) do
          {:error, diagnostics} ->
            {:error, diagnostics}

          {:ok, evidence_refs} ->
            {:ok, apply_transition(manifest, "admit_to_catalogue", nil, "DRAFT", evidence_refs)}
        end
    end
  end

  defp transition_admission(%Manifest{} = manifest, _guard_result) do
    {:error,
     admission_invalid(
       "Admission requires manifest state DRAFT (got #{inspect(manifest.state)})."
     )}
  end

  defp transition_lifecycle(%Manifest{state: from_state} = manifest, action, guard_result) do
    cond do
      from_state not in @valid_states ->
        {:error, state_invalid(from_state)}

      true ->
        case transition_target(action, from_state) do
          :error ->
            {:error, transition_invalid(action, from_state)}

          {:ok, to_state} ->
            case consume_guard(guard_result) do
              {:error, diagnostics} ->
                {:error, diagnostics}

              {:ok, evidence_refs} ->
                {:ok, apply_transition(manifest, action, from_state, to_state, evidence_refs)}
            end
        end
    end
  end

  defp validate_snapshot_state(state) when state in @valid_states, do: :ok

  defp validate_snapshot_state(state), do: {:error, state_invalid(state)}

  defp validate_snapshot_lifecycle(lifecycle, state) when is_map(lifecycle) do
    case Map.fetch(lifecycle, "last_transition") do
      {:ok, last_transition} when is_map(last_transition) ->
        validate_last_transition(last_transition, state)

      _ ->
        {:error, last_transition_invalid()}
    end
  end

  defp validate_snapshot_lifecycle(_lifecycle, _state) do
    {:error, snapshot_invalid("lifecycle", "Lifecycle data must be a map.")}
  end

  defp validate_last_transition(last_transition, state) do
    with :ok <- validate_last_transition_shape(last_transition),
         :ok <- validate_last_transition_fields(last_transition),
         :ok <- validate_evidence_refs(Map.fetch!(last_transition, "evidence_refs")),
         :ok <- validate_snapshot_transition(last_transition, state) do
      :ok
    end
  end

  defp validate_last_transition_shape(last_transition) do
    has_exact_keys? =
      map_size(last_transition) == length(@last_transition_keys) and
        Enum.all?(@last_transition_keys, &Map.has_key?(last_transition, &1))

    if has_exact_keys? do
      :ok
    else
      {:error, last_transition_invalid()}
    end
  end

  defp validate_last_transition_fields(last_transition) do
    action = Map.fetch!(last_transition, "action")
    from = Map.fetch!(last_transition, "from")
    to = Map.fetch!(last_transition, "to")

    cond do
      not valid_utf8_binary?(action) ->
        {:error, snapshot_transition_invalid("lifecycle.last_transition.action")}

      not (from == nil and action == "admit_to_catalogue") and not valid_utf8_binary?(from) ->
        {:error, snapshot_transition_invalid("lifecycle.last_transition.from")}

      not valid_utf8_binary?(to) ->
        {:error, snapshot_transition_invalid("lifecycle.last_transition.to")}

      true ->
        :ok
    end
  end

  defp validate_snapshot_transition(last_transition, state) do
    action = Map.fetch!(last_transition, "action")
    from = Map.fetch!(last_transition, "from")
    to = Map.fetch!(last_transition, "to")

    cond do
      action not in @approved_actions ->
        {:error, action_invalid(action)}

      action == "admit_to_catalogue" ->
        validate_admission_snapshot(from, to, state)

      true ->
        validate_normal_snapshot(action, from, to, state)
    end
  end

  defp validate_admission_snapshot(from, to, state) do
    cond do
      from != nil or to != "DRAFT" ->
        {:error, snapshot_transition_invalid()}

      state != to ->
        {:error, snapshot_state_mismatch(state, to)}

      true ->
        :ok
    end
  end

  defp validate_normal_snapshot(action, from, to, state) do
    cond do
      from not in @valid_states ->
        {:error, snapshot_transition_invalid()}

      to not in @valid_states ->
        {:error, snapshot_transition_invalid("lifecycle.last_transition.to")}

      true ->
        case transition_target(action, from) do
          {:ok, expected_to} when to == expected_to ->
            if state == expected_to do
              :ok
            else
              {:error, snapshot_state_mismatch(state, expected_to)}
            end

          {:ok, _expected_to} ->
            {:error, snapshot_transition_invalid("lifecycle.last_transition.to")}

          :error ->
            {:error, snapshot_transition_invalid()}
        end
    end
  end

  defp transition_target(action, from_state) do
    Map.get(@transitions, action, %{}) |> Map.fetch(from_state)
  end

  defp valid_utf8_binary?(value), do: is_binary(value) and String.valid?(value)

  defp apply_transition(manifest, action, from_state, to_state, evidence_refs) do
    last_transition = %{
      "action" => action,
      "from" => from_state,
      "to" => to_state,
      "evidence_refs" => evidence_refs
    }

    lifecycle =
      case manifest.lifecycle do
        lifecycle when is_map(lifecycle) -> Map.put(lifecycle, "last_transition", last_transition)
        _ -> %{"last_transition" => last_transition}
      end

    %{manifest | state: to_state, lifecycle: lifecycle}
  end

  defp last_transition?(%Manifest{lifecycle: lifecycle}) when is_map(lifecycle) do
    case Map.fetch(lifecycle, "last_transition") do
      {:ok, nil} -> false
      {:ok, _} -> true
      :error -> false
    end
  end

  defp last_transition?(_manifest), do: false

  defp consume_guard({:error, diagnostics}), do: {:error, diagnostics}

  defp consume_guard({:ok, evidence_refs}) when is_list(evidence_refs) do
    case validate_evidence_refs(evidence_refs) do
      :ok -> {:ok, evidence_refs}
      {:error, diagnostic} -> {:error, diagnostic}
    end
  end

  defp consume_guard(_guard_result), do: {:error, guard_result_invalid()}

  defp validate_evidence_refs(evidence_refs) when is_list(evidence_refs) do
    validate_evidence_refs(evidence_refs, 0)
  end

  defp validate_evidence_refs(_),
    do: {:error, evidence_refs_invalid(nil, "Evidence references must be a list.")}

  defp validate_evidence_refs([], _index), do: :ok

  defp validate_evidence_refs([ref | rest], index) do
    if is_binary(ref) and ref != "" and String.valid?(ref) do
      validate_evidence_refs(rest, index + 1)
    else
      {:error,
       evidence_refs_invalid(
         index,
         "Each evidence reference must be a non-empty string (got #{inspect(ref)})."
       )}
    end
  end

  defp validate_evidence_refs(_improper_tail, _index),
    do: {:error, evidence_refs_invalid(nil, "Evidence references must be a list.")}

  defp snapshot_invalid(path, message) do
    %{
      code: "catalogue.lifecycle.snapshot_invalid",
      path: path,
      message: message
    }
  end

  defp last_transition_invalid do
    %{
      code: "catalogue.lifecycle.last_transition_invalid",
      path: "lifecycle.last_transition",
      message:
        "Lifecycle last_transition must contain exactly action, from, to, and evidence_refs."
    }
  end

  defp snapshot_transition_invalid(path \\ "lifecycle.last_transition") do
    %{
      code: "catalogue.lifecycle.snapshot_transition_invalid",
      path: path,
      message: "Stored lifecycle transition is not valid for the approved transition matrix."
    }
  end

  defp snapshot_state_mismatch(state, expected_state) do
    %{
      code: "catalogue.lifecycle.snapshot_state_mismatch",
      path: "state",
      message:
        "CatalogueItem state #{inspect(state)} does not match last_transition target #{inspect(expected_state)}."
    }
  end

  defp action_invalid(action),
    do: %{
      code: "catalogue.lifecycle.action_invalid",
      path: "action",
      message: "Lifecycle action #{inspect(action)} is not approved."
    }

  defp state_invalid(state),
    do: %{
      code: "catalogue.lifecycle.state_invalid",
      path: "state",
      message: "CatalogueItem state #{inspect(state)} is not valid for lifecycle transitions."
    }

  defp transition_invalid(action, from_state),
    do: %{
      code: "catalogue.lifecycle.transition_invalid",
      path: "state",
      message: "Action #{inspect(action)} is not allowed from state #{inspect(from_state)}."
    }

  defp admission_invalid(message),
    do: %{
      code: "catalogue.lifecycle.admission_invalid",
      path: "lifecycle.last_transition",
      message: message
    }

  defp guard_result_invalid,
    do: %{
      code: "catalogue.lifecycle.guard_result_invalid",
      path: "guard",
      message: "Guard result must be {:ok, evidence_refs} or {:error, diagnostics}."
    }

  defp evidence_refs_invalid(index, message) do
    path =
      case index do
        nil -> "lifecycle.last_transition.evidence_refs"
        idx -> "lifecycle.last_transition.evidence_refs[#{idx}]"
      end

    %{
      code: "catalogue.lifecycle.evidence_refs_invalid",
      path: path,
      message: message
    }
  end
end
