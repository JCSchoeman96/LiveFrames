defmodule LiveFrames.Styling.Fluid.Value do
  @type reason :: :invalid_value

  @type_tag "fluid_value"
  @keys ["type", "format_version", "domain_ref", "start_value", "end_value", "interpolation"]
  @numeric_keys ["value", "unit"]

  @spec validate(term()) :: :ok | {:error, reason()}
  def validate(value) do
    if valid_value?(value) do
      :ok
    else
      {:error, :invalid_value}
    end
  end

  @spec type?(term()) :: boolean()
  def type?(%{"type" => @type_tag}), do: true
  def type?(_value), do: false

  defp valid_value?(value) do
    start_dimension = numeric_dimension(value_field(value, "start_value"))
    end_dimension = numeric_dimension(value_field(value, "end_value"))

    closed_object?(value, @keys) and
      type?(value) and
      value["format_version"] == "1.0.0" and
      non_blank_string?(value["domain_ref"]) and
      value["interpolation"] == "linear" and
      not is_nil(start_dimension) and
      start_dimension == end_dimension
  end

  defp value_field(value, key) when is_map(value), do: Map.get(value, key)
  defp value_field(_value, _key), do: nil

  defp numeric_dimension(value) when is_integer(value), do: :number

  defp numeric_dimension(value) when is_float(value) do
    if finite_number?(value), do: :number, else: nil
  end

  defp numeric_dimension(value) when is_map(value) do
    if closed_object?(value, @numeric_keys) and finite_number?(value["value"]) do
      if value["unit"] in ["px", "rem"], do: :length, else: nil
    else
      nil
    end
  end

  defp numeric_dimension(_value), do: nil

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
