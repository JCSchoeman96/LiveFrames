defmodule LiveFrames.Catalogue.StorybookReference do
  @moduledoc false

  alias LiveFrames.Catalogue.Manifest

  @spec validate(Manifest.t(), module()) :: :ok | {:error, [Manifest.diagnostic()]}
  def validate(%Manifest{storybook: storybook}, resolved_story_module) when is_map(storybook) do
    with {:ok, module_reference} <- module_reference(storybook),
         :ok <- validate_resolved_module(resolved_story_module),
         :ok <- matches_resolved_module(module_reference, resolved_story_module),
         :ok <- validate_variation_ids(storybook) do
      :ok
    end
  end

  def validate(%Manifest{}, _resolved_story_module) do
    error(
      "catalogue.storybook_reference.storybook_invalid",
      "storybook",
      "Expected a Storybook object."
    )
  end

  def validate(_manifest, _resolved_story_module) do
    error(
      "catalogue.storybook_reference.manifest_invalid",
      "$",
      "Expected a decoded Catalogue manifest."
    )
  end

  defp module_reference(storybook) do
    case Map.fetch(storybook, "module") do
      {:ok, module} when is_binary(module) ->
        if String.valid?(module) do
          {:ok, module}
        else
          module_invalid()
        end

      _ ->
        module_invalid()
    end
  end

  defp validate_resolved_module(module) when is_atom(module), do: :ok

  defp validate_resolved_module(_module) do
    error(
      "catalogue.storybook_reference.resolved_module_invalid",
      "storybook.module",
      "Expected a trusted module atom."
    )
  end

  defp matches_resolved_module(module_reference, resolved_story_module) do
    if module_reference == module_name(resolved_story_module) do
      :ok
    else
      error(
        "catalogue.storybook_reference.module_mismatch",
        "storybook.module",
        "Storybook module reference does not match the supplied module."
      )
    end
  end

  defp module_name(module) do
    module
    |> Atom.to_string()
    |> String.replace_prefix("Elixir.", "")
  end

  defp validate_variation_ids(storybook) do
    case Map.fetch(storybook, "variation_ids") do
      :error ->
        :ok

      {:ok, variation_ids} ->
        if proper_list?(variation_ids) do
          validate_variation_members(variation_ids)
        else
          variation_ids_invalid()
        end
    end
  end

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_value), do: false

  defp validate_variation_members(variation_ids) do
    case first_invalid_variation_id(variation_ids) do
      nil -> validate_unique_variation_ids(variation_ids)
      index -> variation_id_invalid(index)
    end
  end

  defp first_invalid_variation_id(variation_ids) do
    variation_ids
    |> Enum.with_index()
    |> Enum.find_value(fn {variation_id, index} ->
      if valid_variation_id?(variation_id), do: nil, else: index
    end)
  end

  defp valid_variation_id?(variation_id) when is_binary(variation_id) do
    byte_size(variation_id) > 0 and String.valid?(variation_id)
  end

  defp valid_variation_id?(_variation_id), do: false

  defp validate_unique_variation_ids(variation_ids) do
    if length(variation_ids) == length(Enum.uniq(variation_ids)) do
      :ok
    else
      error(
        "catalogue.storybook_reference.variation_id_duplicate",
        "storybook.variation_ids",
        "Variation IDs must be unique."
      )
    end
  end

  defp variation_ids_invalid do
    error(
      "catalogue.storybook_reference.variation_ids_invalid",
      "storybook.variation_ids",
      "Expected a proper list of variation IDs."
    )
  end

  defp variation_id_invalid(index) do
    error(
      "catalogue.storybook_reference.variation_id_invalid",
      "storybook.variation_ids[#{index}]",
      "Expected a non-empty valid UTF-8 string."
    )
  end

  defp module_invalid do
    error(
      "catalogue.storybook_reference.module_invalid",
      "storybook.module",
      "Expected a valid UTF-8 module string."
    )
  end

  defp error(code, path, message), do: {:error, [%{code: code, path: path, message: message}]}
end
