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
        case Map.get(@transitions, action, %{}) |> Map.fetch(from_state) do
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
    evidence_refs
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn
      {ref, _index}, :ok when is_binary(ref) and ref != "" ->
        {:cont, :ok}

      {ref, index}, :ok ->
        {:halt,
         {:error,
          evidence_refs_invalid(
            index,
            "Each evidence reference must be a non-empty string (got #{inspect(ref)})."
          )}}
    end)
    |> case do
      :ok -> :ok
      other -> other
    end
  end

  defp validate_evidence_refs(_),
    do: {:error, evidence_refs_invalid(nil, "Evidence references must be a list.")}

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
