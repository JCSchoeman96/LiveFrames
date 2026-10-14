defmodule LiveFrames.Adapters.Bricks.TransientStyleState do
  @moduledoc false

  @interaction_keys [
    "action",
    "actionAttributeKey",
    "actionAttributeValue",
    "id",
    "trigger"
  ]

  @spec resolve_aliases(term(), term()) :: %{optional(String.t()) => :hover}
  def resolve_aliases(effective_css_value, provenance) do
    with true <- valid_css_value?(effective_css_value),
         {:ok, layer_settings} <- effective_layer_settings(provenance),
         {:ok, token} <- interaction_alias(layer_settings) do
      %{token => :hover}
    else
      _ -> %{}
    end
  end

  defp valid_css_value?(value), do: is_binary(value) and String.valid?(value)

  defp effective_layer_settings(provenance) when is_map(provenance) do
    with {:ok, origin} <- Map.fetch(provenance, :origin),
         {:ok, class_id} <- Map.fetch(provenance, :class_id),
         {:ok, resolution_source} <- Map.fetch(provenance, :resolution_source),
         {:ok, authority_ids} <- Map.fetch(provenance, :authority_ids),
         {:ok, class_reference_index} <- Map.fetch(provenance, :class_reference_index),
         {:ok, source_id} <- Map.fetch(provenance, :source_id),
         {:ok, layer_settings} <- Map.fetch(provenance, :layer_settings),
         true <-
           valid_layer_identity?(
             origin,
             class_id,
             resolution_source,
             authority_ids,
             class_reference_index,
             source_id,
             layer_settings
           ) do
      {:ok, layer_settings}
    else
      _ -> :error
    end
  end

  defp effective_layer_settings(_provenance), do: :error

  defp valid_layer_identity?(
         :global_class,
         class_id,
         resolution_source,
         authority_ids,
         class_reference_index,
         source_id,
         layer_settings
       ) do
    non_empty_string?(source_id) and non_empty_string?(class_id) and
      resolution_source in [:local, :external] and valid_authority_ids?(authority_ids) and
      (resolution_source != :external or authority_ids != []) and
      is_integer(class_reference_index) and class_reference_index >= 0 and is_map(layer_settings)
  end

  defp valid_layer_identity?(
         :element_local,
         nil,
         nil,
         [],
         nil,
         source_id,
         layer_settings
       ) do
    non_empty_string?(source_id) and is_map(layer_settings)
  end

  defp valid_layer_identity?(
         _origin,
         _class_id,
         _resolution_source,
         _authority_ids,
         _class_reference_index,
         _source_id,
         _layer_settings
       ),
       do: false

  defp valid_authority_ids?(authority_ids) when is_list(authority_ids),
    do: Enum.all?(authority_ids, &non_empty_string?/1)

  defp valid_authority_ids?(_authority_ids), do: false

  defp non_empty_string?(value),
    do: is_binary(value) and byte_size(value) > 0 and String.valid?(value)

  defp interaction_alias(layer_settings) do
    case Map.fetch(layer_settings, "_interactions") do
      {:ok, interactions} when is_list(interactions) -> reversible_token(interactions)
      _ -> :error
    end
  end

  defp validate_interaction(interaction) when is_map(interaction) do
    if exact_interaction_keys?(interaction) do
      with {:ok, action} <- valid_string_field(interaction, "action"),
           {:ok, attribute_key} <- valid_string_field(interaction, "actionAttributeKey"),
           {:ok, attribute_value} <- valid_string_field(interaction, "actionAttributeValue"),
           {:ok, id} <- non_empty_string_field(interaction, "id"),
           {:ok, trigger} <- valid_string_field(interaction, "trigger") do
        {:ok, {trigger, action, attribute_key, attribute_value, id}}
      else
        _ -> :error
      end
    else
      :error
    end
  end

  defp validate_interaction(_interaction), do: :error

  defp exact_interaction_keys?(interaction) do
    map_size(interaction) == length(@interaction_keys) and
      Enum.all?(@interaction_keys, &Map.has_key?(interaction, &1))
  end

  defp valid_string_field(interaction, key) do
    case Map.fetch(interaction, key) do
      {:ok, value} when is_binary(value) ->
        if String.valid?(value), do: {:ok, value}, else: :error

      _ ->
        :error
    end
  end

  defp non_empty_string_field(interaction, key) do
    case valid_string_field(interaction, key) do
      {:ok, value} when byte_size(value) > 0 -> {:ok, value}
      _ -> :error
    end
  end

  defp reversible_token(interactions) do
    candidates =
      Enum.reduce_while(interactions, {:ok, %{}}, fn interaction, {:ok, candidates} ->
        case validate_interaction(interaction) do
          {:ok, {trigger, action, attribute_key, token, _id}} ->
            {:cont,
             {:ok, add_interaction_candidate(candidates, trigger, action, attribute_key, token)}}

          :error ->
            {:halt, :error}
        end
      end)

    case candidates do
      {:ok, candidates} ->
        case Enum.filter(candidates, fn {_token, evidence} ->
               evidence.enter? and evidence.leave?
             end) do
          [{token, %{contradictory?: false}}] -> {:ok, token}
          _ -> :error
        end

      :error ->
        :error
    end
  end

  defp add_interaction_candidate(candidates, _trigger, _action, attribute_key, _token)
       when attribute_key != "class",
       do: candidates

  defp add_interaction_candidate(candidates, trigger, action, "class", token) do
    if single_class_token?(token) do
      evidence =
        Map.get(candidates, token, %{enter?: false, leave?: false, contradictory?: false})

      evidence =
        case {trigger, action} do
          {"mouseenter", "setAttribute"} -> %{evidence | enter?: true}
          {"mouseleave", "removeAttribute"} -> %{evidence | leave?: true}
          _ -> %{evidence | contradictory?: true}
        end

      Map.put(candidates, token, evidence)
    else
      candidates
    end
  end

  defp single_class_token?(token) when is_binary(token) do
    String.valid?(token) and byte_size(token) > 0 and String.trim(token) != "" and
      not String.match?(token, ~r/\s/u)
  end

  defp single_class_token?(_token), do: false
end
