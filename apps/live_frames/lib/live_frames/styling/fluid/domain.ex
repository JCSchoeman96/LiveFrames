defmodule LiveFrames.Styling.Fluid.Domain do
  @type reason :: :invalid_domain

  @type_tag "fluid_domain"
  @keys ["type", "format_version", "input", "start", "end", "clamp_policy"]
  @length_keys ["value", "unit"]

  @spec validate(term()) :: :ok | {:error, reason()}
  def validate(value) do
    if valid_domain?(value) do
      :ok
    else
      {:error, :invalid_domain}
    end
  end

  @spec type?(term()) :: boolean()
  def type?(%{"type" => @type_tag}), do: true
  def type?(_value), do: false

  defp valid_domain?(domain) do
    closed_object?(domain, @keys) and
      type?(domain) and
      domain["format_version"] == "1.0.0" and
      domain["input"] == "viewport_width" and
      domain["clamp_policy"] == "bounded" and
      pixel_length?(domain["start"]) and
      pixel_length?(domain["end"]) and
      domain["start"]["value"] < domain["end"]["value"]
  end

  defp pixel_length?(value) do
    closed_object?(value, @length_keys) and
      finite_number?(value["value"]) and
      value["unit"] == "px"
  end

  defp finite_number?(value) when is_integer(value), do: true

  defp finite_number?(value) when is_float(value) do
    <<_sign::1, exponent::11, _fraction::52>> = <<value::float-64>>
    exponent != 0x7FF
  end

  defp finite_number?(_value), do: false

  defp closed_object?(value, keys) when is_map(value) do
    not is_struct(value) and map_size(value) == length(keys) and
      Enum.all?(keys, &Map.has_key?(value, &1))
  end

  defp closed_object?(_value, _keys), do: false
end
