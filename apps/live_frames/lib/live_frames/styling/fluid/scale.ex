defmodule LiveFrames.Styling.Fluid.Scale do
  @type reason :: :invalid_scale

  @type_tag "fluid_scale"
  @keys [
    "type",
    "format_version",
    "domain_ref",
    "base_start",
    "base_end",
    "ratio_start",
    "ratio_end"
  ]
  @length_keys ["value", "unit"]

  @spec validate(term()) :: :ok | {:error, reason()}
  def validate(value) do
    if valid_scale?(value) do
      :ok
    else
      {:error, :invalid_scale}
    end
  end

  @spec type?(term()) :: boolean()
  def type?(%{"type" => @type_tag}), do: true
  def type?(_value), do: false

  defp valid_scale?(scale) do
    closed_object?(scale, @keys) and
      type?(scale) and
      scale["format_version"] == "1.0.0" and
      non_blank_string?(scale["domain_ref"]) and
      length_value?(scale["base_start"]) and
      length_value?(scale["base_end"]) and
      positive_finite_number?(scale["ratio_start"]) and
      positive_finite_number?(scale["ratio_end"])
  end

  defp length_value?(value) do
    closed_object?(value, @length_keys) and
      finite_number?(value["value"]) and
      value["unit"] in ["px", "rem"]
  end

  defp positive_finite_number?(value) do
    finite_number?(value) and value > 0
  end

  defp finite_number?(value) when is_integer(value), do: true

  defp finite_number?(value) when is_float(value) do
    <<_sign::1, exponent::11, _fraction::52>> = <<value::float-64>>
    exponent != 0x7FF
  end

  defp finite_number?(_value), do: false

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
