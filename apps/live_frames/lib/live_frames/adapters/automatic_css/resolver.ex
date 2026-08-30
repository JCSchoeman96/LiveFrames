defmodule LiveFrames.Adapters.AutomaticCSS.Resolver do
  @moduledoc """
  Pure value resolvers used by the Automatic.css mapping table.

  These functions interpret only the small set of source representations
  demonstrated by the approved fixture. They never evaluate source code or
  CSS.
  """

  @hex_pattern ~r/^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/
  @reference_pattern ~r/^var\(\s*(--[a-zA-Z0-9_-]+)\s*\)$/
  @variable_pattern ~r/^--[a-zA-Z0-9_-]+$/

  @spec literal(term(), atom(), keyword()) :: map()
  def literal(value, kind, _opts \\ []) do
    if literal_value?(value, kind) do
      resolved(value, value, value, "direct")
    else
      unresolved(value, nil, "value does not match the known source type")
    end
  end

  @spec px(term(), String.t()) :: map()
  def px(value, source_key) when is_binary(source_key) do
    if number?(value) do
      result = format_number(value) <> "px"
      resolved(result, result, value, "direct", %{"unit" => "px", "source_key" => source_key})
    else
      unresolved(value, source_key, "expected a numeric value for a px setting")
    end
  end

  @spec hsl(map(), [String.t()]) :: map()
  def hsl(settings, source_keys) when is_map(settings) and is_list(source_keys) do
    raw_value = Map.new(source_keys, &{&1, Map.get(settings, &1)})

    case Enum.map(source_keys, &Map.get(settings, &1)) do
      [hue, saturation, lightness]
      when (is_integer(hue) or is_float(hue)) and (is_integer(saturation) or is_float(saturation)) and
             (is_integer(lightness) or is_float(lightness)) ->
        if hue >= 0 and hue <= 360 and saturation >= 0 and saturation <= 100 and lightness >= 0 and
             lightness <= 100 do
          result =
            "hsl(#{format_number(hue)} #{format_number(saturation)}% #{format_number(lightness)}%)"

          resolved(
            result,
            result,
            raw_value,
            "hsl_channels",
            %{"channels" => raw_value}
          )
        else
          unresolved(
            raw_value,
            List.first(source_keys),
            "HSL channels are outside supported ranges"
          )
        end

      _ ->
        unresolved(
          raw_value,
          List.first(source_keys),
          "HSL channel values are incomplete or invalid"
        )
    end
  end

  @spec responsive(map(), [String.t()], String.t() | nil) :: map()
  def responsive(settings, source_keys, unit)
      when is_map(settings) and is_list(source_keys) and (is_binary(unit) or is_nil(unit)) do
    raw_value = Map.new(source_keys, &{&1, Map.get(settings, &1)})

    case Enum.map(source_keys, &Map.get(settings, &1)) do
      [minimum, maximum]
      when (is_integer(minimum) or is_float(minimum)) and
             (is_integer(maximum) or is_float(maximum)) ->
        value = %{
          "type" => "responsive",
          "min" => format_responsive_value(minimum, unit),
          "max" => format_responsive_value(maximum, unit)
        }

        resolved(value, value, raw_value, "responsive_pair", %{"unit" => unit})

      _ ->
        unresolved(
          raw_value,
          List.first(source_keys),
          "responsive values are incomplete or invalid"
        )
    end
  end

  @spec reference(term(), String.t() | nil, String.t()) :: map()
  def reference(raw_value, target_path, source_key) when is_binary(source_key) do
    reference(raw_value, target_path, source_key, nil)
  end

  @spec reference(term(), String.t() | nil, String.t(), String.t() | nil) :: map()
  def reference(raw_value, target_path, source_key, expected_variable)
      when is_binary(source_key) and (is_binary(expected_variable) or is_nil(expected_variable)) do
    case reference_variable(raw_value) do
      {:ok, variable} when is_binary(target_path) and variable == expected_variable ->
        resolved(
          %{"type" => "reference", "path" => target_path},
          nil,
          raw_value,
          "semantic_reference",
          %{"source_variable" => variable, "source_key" => source_key},
          [target_path]
        )

      {:ok, _variable} when is_binary(target_path) ->
        unresolved(
          raw_value,
          source_key,
          "source variable does not match the proven semantic target"
        )

      {:ok, _variable} ->
        unresolved(raw_value, source_key, "source variable has no proven semantic target")

      :error ->
        unresolved(
          raw_value,
          source_key,
          "source value is not a supported CSS variable reference"
        )
    end
  end

  @spec foundation(map(), String.t(), String.t(), String.t(), [String.t()]) :: map()
  def foundation(settings, variable, light_value, dark_value, source_keys)
      when is_map(settings) and is_binary(variable) and is_binary(light_value) and
             is_binary(dark_value) and is_list(source_keys) do
    bw_variables = Map.get(settings, "option-bw-color-variables", "on")
    auto_color_scheme = Map.get(settings, "auto-color-scheme", "off")

    inputs = %{
      "light" => light_value,
      "dark" => dark_value,
      "option_bw_color_variables" => bw_variables,
      "auto_color_scheme" => auto_color_scheme
    }

    cond do
      bw_variables != "on" ->
        unresolved(inputs, List.first(source_keys), "ACSS black/white variables are disabled")

      auto_color_scheme == "on" ->
        expression = "light-dark(#{light_value}, #{dark_value})"

        generated_foundation(variable, inputs, source_keys, expression)

      auto_color_scheme == "off" ->
        generated_foundation(variable, inputs, source_keys, light_value)

      true ->
        unresolved(
          inputs,
          List.first(source_keys),
          "auto-color-scheme must be on or off for the ACSS BW contract"
        )
    end
  end

  @spec derived(String.t(), String.t(), map(), [String.t()], [String.t()]) :: map()
  def derived(recipe, variable, inputs, references, source_keys)
      when is_binary(recipe) and is_binary(variable) and is_map(inputs) and is_list(references) and
             is_list(source_keys) do
    value = %{
      "type" => "derived",
      "recipe" => recipe,
      "variable" => variable,
      "inputs" => inputs
    }

    resolved(
      value,
      value,
      inputs,
      "derived_relationship",
      %{"variable" => variable, "source_keys" => source_keys},
      references
    )
  end

  @spec unresolved(term(), String.t() | nil, String.t()) :: map()
  def unresolved(raw_value, source_key, reason) when is_binary(reason) do
    unresolved_value = %{"type" => "unresolved", "expression" => raw_value, "reason" => reason}

    %{
      value: unresolved_value,
      resolved_value: nil,
      source_expression: raw_value,
      resolution_status: :unresolved,
      references: [],
      transformation: "unresolved",
      metadata: compact_metadata(%{"source_key" => source_key, "reason" => reason})
    }
  end

  defp resolved(
         value,
         resolved_value,
         source_expression,
         transformation,
         metadata \\ %{},
         references \\ []
       ) do
    %{
      value: value,
      resolved_value: resolved_value,
      source_expression: source_expression,
      resolution_status: :resolved,
      references: references,
      transformation: transformation,
      metadata: metadata
    }
  end

  defp generated_foundation(variable, inputs, source_keys, expression) do
    value = %{
      "type" => "derived",
      "recipe" => "acss.bw_foundation",
      "variable" => variable,
      "inputs" => inputs
    }

    source_expression = %{
      "type" => "acss_generated_variable",
      "variable" => variable,
      "expression" => expression,
      "inputs" => inputs
    }

    resolved(
      value,
      expression,
      source_expression,
      "acss_generated_foundation",
      %{
        "source_variable" => variable,
        "source_keys" => source_keys,
        "source_contract_version" => "4.0.1"
      }
    )
  end

  defp literal_value?(value, :color),
    do: is_binary(value) and Regex.match?(@hex_pattern, value)

  defp literal_value?(value, :string), do: is_binary(value) and value != ""
  defp literal_value?(value, :number), do: number?(value)
  defp literal_value?(value, :css), do: is_binary(value) and value != ""
  defp literal_value?(value, _kind), do: is_binary(value) or number?(value) or is_boolean(value)

  defp reference_variable(value) when is_binary(value) do
    cond do
      Regex.match?(@reference_pattern, value) ->
        [_, variable] = Regex.run(@reference_pattern, value)
        {:ok, variable}

      Regex.match?(@variable_pattern, value) ->
        {:ok, value}

      true ->
        :error
    end
  end

  defp reference_variable(_value), do: :error

  defp number?(value), do: is_integer(value) or is_float(value)

  defp format_number(value) when is_integer(value), do: Integer.to_string(value)

  defp format_number(value) when is_float(value) do
    value
    |> :erlang.float_to_binary(decimals: 6)
    |> String.trim_trailing("0")
    |> String.trim_trailing(".")
  end

  defp format_responsive_value(value, nil), do: value
  defp format_responsive_value(value, unit), do: format_number(value) <> unit

  defp compact_metadata(metadata), do: Map.reject(metadata, fn {_key, value} -> is_nil(value) end)
end
