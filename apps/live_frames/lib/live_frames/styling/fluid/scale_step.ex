defmodule LiveFrames.Styling.Fluid.ScaleStep do
  @type reason :: :invalid_scale_step

  @type_tag "fluid_scale_step"
  @keys ["type", "format_version", "scale_ref", "power"]

  @spec validate(term()) :: :ok | {:error, reason()}
  def validate(value) do
    if valid_scale_step?(value) do
      :ok
    else
      {:error, :invalid_scale_step}
    end
  end

  @spec type?(term()) :: boolean()
  def type?(%{"type" => @type_tag}), do: true
  def type?(_value), do: false

  defp valid_scale_step?(step) do
    closed_object?(step, @keys) and
      type?(step) and
      step["format_version"] == "1.0.0" and
      non_blank_string?(step["scale_ref"]) and
      is_integer(step["power"]) and
      step["power"] >= -4 and
      step["power"] <= 4
  end

  defp non_blank_string?(value) when is_binary(value) do
    try do
      String.trim(value) != ""
    rescue
      _error -> false
    end
  end

  defp non_blank_string?(_value), do: false

  defp closed_object?(value, keys) when is_map(value) do
    not is_struct(value) and map_size(value) == length(keys) and
      Enum.all?(keys, &Map.has_key?(value, &1))
  end

  defp closed_object?(_value, _keys), do: false
end
