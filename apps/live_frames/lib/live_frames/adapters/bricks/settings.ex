defmodule LiveFrames.Adapters.Bricks.Settings do
  @moduledoc """
  Deliberate mapping of the small Bricks setting subset demonstrated by the
  approved fixture.

  This module is intentionally not a general Bricks CSS engine. Values that
  are not safe or unambiguous remain in the extraction result and receive a
  diagnostic.
  """

  alias LiveFrames.Adapters.Bricks.Diagnostic

  @style_properties %{
    "_position" => "position",
    "_isolation" => "isolation",
    "_rowGap" => "row-gap",
    "_columnGap" => "column-gap",
    "_alignItems" => "align-items",
    "_justifyContent" => "justify-content",
    "_zIndex" => "z-index",
    "_width" => "width",
    "_widthMax" => "max-width",
    "_height" => "height",
    "_display" => "display",
    "_flexWrap" => "flex-wrap",
    "_direction" => "flex-direction",
    "_top" => "top",
    "_right" => "right",
    "_bottom" => "bottom",
    "_left" => "left",
    "_objectFit" => "object-fit",
    "_objectPosition" => "object-position"
  }

  @semantic_settings ["text", "tag", "style", "outline", "image", "caption", "link", "url", "alt"]

  @spec style_properties() :: map()
  def style_properties, do: @style_properties

  @spec extract(term()) :: map()
  def extract(settings) when is_map(settings) do
    settings
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
    |> Enum.reduce(empty_result(settings), &consume/2)
  end

  def extract(settings) do
    result = empty_result(settings)
    add_unsupported(result, "<settings>", settings, "Bricks settings must be an object")
  end

  defp empty_result(settings) do
    %{
      base_styles: %{},
      gradients: [],
      responsive: [],
      custom_css: %{base: [], responsive: []},
      consumed: [],
      unsupported: [],
      unresolved_values: %{},
      diagnostics: [],
      raw: settings
    }
  end

  defp consume({key, value}, result) when is_binary(key) do
    {base_key, breakpoint} = split_key(key)

    cond do
      base_key in @semantic_settings or base_key == "_cssGlobalClasses" ->
        add_consumed(result, key, nil, value, breakpoint)

      base_key == "_cssCustom" ->
        consume_custom_css(result, key, value, breakpoint)

      base_key in Map.keys(@style_properties) ->
        consume_simple_style(result, key, base_key, value, breakpoint)

      base_key == "_margin" ->
        consume_box(result, key, value, breakpoint, "margin")

      base_key == "_border" ->
        consume_border(result, key, value, breakpoint)

      base_key == "_background" ->
        consume_background(result, key, value, breakpoint)

      base_key == "_gradient" ->
        consume_gradient(result, key, value, breakpoint)

      true ->
        add_unsupported(
          result,
          key,
          value,
          "Bricks setting is outside the supported Stage A subset"
        )
    end
  end

  defp consume({_key, value}, result),
    do: add_unsupported(result, "<non-string-key>", value, "Bricks setting keys must be strings")

  defp consume_simple_style(result, key, base_key, value, breakpoint) do
    property = Map.fetch!(@style_properties, base_key)

    case safe_style_value(value, property) do
      {:ok, css_value} ->
        if breakpoint do
          add_responsive(result, key, base_key, property, css_value, value, breakpoint)
        else
          result
          |> put_style(property, css_value)
          |> add_consumed(key, property, value, nil)
        end

      :unresolved ->
        add_unresolved(result, key, value, "Style value is not unambiguous CSS")
    end
  end

  defp consume_box(result, key, value, breakpoint, property_prefix) when is_map(value) do
    sides = ["top", "right", "bottom", "left"]

    Enum.reduce(sides, result, fn side, result ->
      case Map.fetch(value, side) do
        {:ok, side_value} ->
          property = "#{property_prefix}-#{side}"

          case safe_box_value(side_value) do
            {:ok, css_value} ->
              if breakpoint do
                add_responsive(
                  result,
                  key,
                  "#{key}.#{side}",
                  property,
                  css_value,
                  side_value,
                  breakpoint
                )
              else
                result
                |> put_style(property, css_value)
                |> add_consumed("#{key}.#{side}", property, side_value, nil)
              end

            :unresolved ->
              add_unresolved(
                result,
                "#{key}.#{side}",
                side_value,
                "Box value has no proven CSS unit"
              )
          end

        :error ->
          result
      end
    end)
  end

  defp consume_box(result, key, value, _breakpoint, _property_prefix),
    do: add_unsupported(result, key, value, "Bricks box setting must be an object")

  defp consume_border(result, key, value, breakpoint) when is_map(value) do
    case Map.get(value, "radius") do
      radius when is_map(radius) ->
        consume_radius(result, key, radius, breakpoint)

      nil ->
        add_unsupported(result, key, value, "Only Bricks border radius is supported in Stage A")

      other ->
        add_unsupported(result, "#{key}.radius", other, "Bricks border radius must be an object")
    end
  end

  defp consume_border(result, key, value, _breakpoint),
    do: add_unsupported(result, key, value, "Bricks border setting must be an object")

  defp consume_radius(result, key, radius, breakpoint) do
    Enum.reduce(["top", "right", "bottom", "left"], result, fn side, result ->
      case Map.fetch(radius, side) do
        {:ok, side_value} ->
          property =
            case side do
              "top" -> "border-top-left-radius"
              "right" -> "border-top-right-radius"
              "bottom" -> "border-bottom-right-radius"
              "left" -> "border-bottom-left-radius"
            end

          case safe_box_value(side_value) do
            {:ok, css_value} ->
              if breakpoint do
                add_responsive(
                  result,
                  "#{key}.radius.#{side}",
                  "#{key}.radius.#{side}",
                  property,
                  css_value,
                  side_value,
                  breakpoint
                )
              else
                result
                |> put_style(property, css_value)
                |> add_consumed("#{key}.radius.#{side}", property, side_value, nil)
              end

            :unresolved ->
              add_unresolved(
                result,
                "#{key}.radius.#{side}",
                side_value,
                "Border radius has no proven CSS unit"
              )
          end

        :error ->
          result
      end
    end)
  end

  defp consume_background(result, key, value, breakpoint) when is_map(value) do
    case get_in(value, ["color", "raw"]) do
      raw when is_binary(raw) ->
        case safe_style_value(raw, "background") do
          {:ok, css_value} ->
            if breakpoint do
              add_responsive(result, key, "_background", "background", css_value, raw, breakpoint)
            else
              result
              |> put_style("background", css_value)
              |> add_consumed(key, "background", value, nil)
            end

          :unresolved ->
            add_unresolved(result, "#{key}.color.raw", raw, "Background color is not safe CSS")
        end

      nil ->
        add_unsupported(result, key, value, "Bricks background color raw value is missing")

      raw ->
        add_unsupported(
          result,
          "#{key}.color.raw",
          raw,
          "Bricks background color must be a string"
        )
    end
  end

  defp consume_background(result, key, value, _breakpoint),
    do: add_unsupported(result, key, value, "Bricks background setting must be an object")

  defp consume_gradient(result, key, value, breakpoint) when is_map(value) do
    record = %{
      source_key: key,
      property: "background-image",
      breakpoint: breakpoint,
      raw_value: value,
      value: value,
      threshold_status: if(breakpoint, do: :unresolved, else: :not_applicable),
      min_width: nil,
      max_width: nil
    }

    if breakpoint do
      result
      |> Map.update!(:responsive, &(&1 ++ [Map.put(record, :kind, :gradient)]))
      |> add_consumed(key, "background-image", value, breakpoint)
      |> add_diagnostic(
        Diagnostic.new(
          code: "bricks.breakpoint.unresolved",
          severity: :warning,
          source_path: key,
          raw_value: breakpoint,
          message: "Bricks responsive source name has no authoritative numeric threshold"
        )
      )
    else
      result
      |> Map.update!(:gradients, &(&1 ++ [record]))
      |> add_consumed(key, "background-image", value, nil)
    end
  end

  defp consume_gradient(result, key, value, _breakpoint),
    do: add_unsupported(result, key, value, "Bricks gradient setting must be an object")

  defp consume_custom_css(result, key, value, nil) when is_binary(value) do
    result
    |> Map.update!(:custom_css, &Map.update!(&1, :base, fn values -> values ++ [value] end))
    |> add_consumed(key, nil, value, nil)
  end

  defp consume_custom_css(result, key, value, breakpoint) when is_binary(value) do
    record = %{
      source_key: key,
      breakpoint: breakpoint,
      value: value,
      threshold_status: :unresolved,
      min_width: nil,
      max_width: nil
    }

    result
    |> Map.update!(
      :custom_css,
      &Map.update!(&1, :responsive, fn values -> values ++ [record] end)
    )
    |> Map.update!(
      :responsive,
      &(&1 ++
          [
            %{
              kind: :custom_css,
              source_key: key,
              breakpoint: breakpoint,
              raw_value: value,
              value: value,
              property: nil,
              threshold_status: :unresolved,
              min_width: nil,
              max_width: nil
            }
          ])
    )
    |> add_consumed(key, nil, value, breakpoint)
    |> add_diagnostic(
      Diagnostic.new(
        code: "bricks.breakpoint.unresolved",
        severity: :warning,
        source_path: key,
        raw_value: breakpoint,
        message: "Bricks responsive source name has no authoritative numeric threshold"
      )
    )
  end

  defp consume_custom_css(result, key, value, _breakpoint),
    do: add_unsupported(result, key, value, "Bricks custom CSS must be a string")

  defp add_responsive(result, key, base_key, property, css_value, raw_value, breakpoint) do
    record = %{
      kind: :style,
      source_key: key,
      base_key: base_key,
      property: property,
      value: css_value,
      raw_value: raw_value,
      breakpoint: breakpoint,
      threshold_status: :unresolved,
      min_width: nil,
      max_width: nil
    }

    result
    |> Map.update!(:responsive, &(&1 ++ [record]))
    |> add_consumed(key, property, raw_value, breakpoint)
    |> add_diagnostic(
      Diagnostic.new(
        code: "bricks.breakpoint.unresolved",
        severity: :warning,
        source_path: key,
        raw_value: breakpoint,
        message: "Bricks responsive source name has no authoritative numeric threshold"
      )
    )
  end

  defp put_style(result, property, value), do: put_in(result, [:base_styles, property], value)

  defp add_consumed(result, key, property, value, breakpoint) do
    record = %{source_key: key, property: property, raw_value: value, breakpoint: breakpoint}
    Map.update!(result, :consumed, &(&1 ++ [record]))
  end

  defp add_unsupported(result, key, value, message) do
    record = %{source_key: key, raw_value: value, reason: message}

    result
    |> Map.update!(:unsupported, &(&1 ++ [record]))
    |> add_diagnostic(
      Diagnostic.new(
        code: "bricks.setting.unsupported",
        severity: :warning,
        source_path: key,
        raw_value: value,
        message: message
      )
    )
  end

  defp add_unresolved(result, key, value, message) do
    result
    |> put_in([:unresolved_values, key], value)
    |> add_diagnostic(
      Diagnostic.new(
        code: "bricks.setting.value_unresolved",
        severity: :warning,
        source_path: key,
        raw_value: value,
        message: message
      )
    )
  end

  defp add_diagnostic(result, diagnostic),
    do: Map.update!(result, :diagnostics, &(&1 ++ [diagnostic]))

  defp safe_style_value(value, "z-index") when is_integer(value),
    do: {:ok, Integer.to_string(value)}

  defp safe_style_value(value, "z-index") when is_float(value),
    do: {:ok, :erlang.float_to_binary(value, decimals: 4)}

  defp safe_style_value(value, "z-index") when is_binary(value) do
    if safe_css_value?(value) and
         (Regex.match?(~r/^-?(?:\d+(?:\.\d+)?|\.\d+)$/, value) or
            value in ["auto", "inherit", "initial", "unset"]),
       do: {:ok, value},
       else: :unresolved
  end

  defp safe_style_value(value, _property) when is_binary(value) do
    if safe_css_value?(value) and (value == "0" or not bare_number?(value)),
      do: {:ok, value},
      else: :unresolved
  end

  defp safe_style_value(_value, _property), do: :unresolved

  defp safe_box_value(value) when is_integer(value) and value == 0, do: {:ok, "0"}
  defp safe_box_value(value) when is_float(value) and value == 0.0, do: {:ok, "0"}

  defp safe_box_value(value) when is_binary(value) do
    cond do
      not safe_css_value?(value) ->
        :unresolved

      value == "0" ->
        {:ok, value}

      value in ["auto", "initial", "inherit", "unset", "revert"] ->
        {:ok, value}

      Regex.match?(
        ~r/^-?(?:\d+(?:\.\d+)?|\.\d+)(?:px|em|rem|%|vh|vw|vmin|vmax|ch|ex|cm|mm|in|pt|pc)(?:\s+[^;{}]+)?$/i,
        value
      ) ->
        {:ok, value}

      String.starts_with?(value, "var(") or String.starts_with?(value, "calc(") or
          String.starts_with?(value, "clamp(") ->
        {:ok, value}

      true ->
        :unresolved
    end
  end

  defp safe_box_value(_value), do: :unresolved

  defp safe_css_value?(value) do
    lowered = String.downcase(value)

    value != "" and
      not String.contains?(lowered, [
        "{",
        "}",
        ";",
        "\0",
        "</",
        "url(",
        "expression(",
        "javascript:"
      ])
  end

  defp bare_number?(value), do: Regex.match?(~r/^-?(?:\d+(?:\.\d+)?|\.\d+)$/, value)

  defp split_key(key) do
    case String.split(key, ":", parts: 2) do
      [base_key] -> {base_key, nil}
      [base_key, breakpoint] when breakpoint != "" -> {base_key, breakpoint}
      _ -> {key, nil}
    end
  end
end
