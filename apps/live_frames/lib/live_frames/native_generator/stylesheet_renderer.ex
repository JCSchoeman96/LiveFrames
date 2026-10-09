defmodule LiveFrames.NativeGenerator.StylesheetRenderer do
  @moduledoc false

  alias LiveFrames.Fidelity.CSSDeclaration
  alias LiveFrames.IR.ResponsiveOverride
  alias LiveFrames.NativeGenerator.Diagnostic
  alias LiveFrames.NativeGenerator.StyleValueCSS

  @responsive_gap_code "native_generator.styling.responsive_cascade_authority_gap"
  @style_error_code "native_generator.styling.css_serialization_failed"
  @selector_pattern ~r/^[A-Za-z_][A-Za-z0-9_-]*$/

  @spec render(String.t(), map(), [ResponsiveOverride.t()] | map()) ::
          {:ok, String.t()} | {:error, Diagnostic.t()}
  def render(private_class, base_styles, responsive_overrides \\ []) do
    with :ok <- validate_private_class(private_class),
         {:ok, base_declarations} <- serialize_styles(base_styles),
         {:ok, responsive_rules} <- responsive_rules(responsive_overrides),
         {:ok, rendered_responsive} <- render_responsive(private_class, responsive_rules) do
      blocks =
        [render_block("." <> private_class, base_declarations, 2)] ++ rendered_responsive

      css =
        blocks
        |> Enum.reject(&is_nil/1)
        |> Enum.join("\n\n")

      if css == "", do: {:ok, ""}, else: {:ok, css <> "\n"}
    else
      {:error, %Diagnostic{} = diagnostic} -> {:error, diagnostic}
      {:error, reason} -> {:error, style_diagnostic(reason)}
    end
  end

  @spec render_pseudo(String.t(), :hover | :focus_visible, map()) ::
          {:ok, String.t()} | {:error, Diagnostic.t()}
  def render_pseudo(private_class, pseudo, styles) when pseudo in [:hover, :focus_visible] do
    with :ok <- validate_private_class(private_class),
         {:ok, declarations} <- serialize_styles(styles) do
      suffix = if pseudo == :hover, do: ":hover", else: ":focus-visible"
      css = render_block("." <> private_class <> suffix, declarations, 2)
      if is_nil(css), do: {:ok, ""}, else: {:ok, css <> "\n"}
    else
      {:error, %Diagnostic{} = diagnostic} -> {:error, diagnostic}
      {:error, reason} -> {:error, style_diagnostic(reason)}
    end
  end

  def render_pseudo(_private_class, _pseudo, _styles),
    do: {:error, style_diagnostic(:unsupported_pseudo)}

  defp validate_private_class(class) when is_binary(class) do
    if Regex.match?(@selector_pattern, class), do: :ok, else: {:error, :unsafe_private_class}
  end

  defp validate_private_class(_class), do: {:error, :unsafe_private_class}

  defp serialize_styles(styles) when is_map(styles) do
    styles
    |> Enum.sort_by(fn {property, _style_value} -> property_sort_key(property) end)
    |> Enum.reduce_while({:ok, []}, fn {property, style_value}, {:ok, declarations} ->
      case serialize_declaration(property, style_value) do
        {:ok, declaration} -> {:cont, {:ok, [declaration | declarations]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, declarations} -> {:ok, Enum.reverse(declarations)}
      {:error, _reason} = error -> error
    end
  end

  defp serialize_styles(_styles), do: {:error, :invalid_style_map}

  defp property_sort_key(property) when is_binary(property), do: property
  defp property_sort_key(property), do: inspect(property)

  defp serialize_declaration(property, style_value) when is_binary(property) do
    if property != "custom-css" and CSSDeclaration.safe_property?(property) do
      case StyleValueCSS.serialize(style_value) do
        {:ok, css_value} ->
          if CSSDeclaration.safe_value?(css_value),
            do: {:ok, {property, css_value}},
            else: {:error, :unsafe_css_value}

        {:error, reason} ->
          {:error, {:invalid_declaration, property, reason}}
      end
    else
      {:error, {:unsafe_css_property, property}}
    end
  end

  defp serialize_declaration(property, _style_value),
    do: {:error, {:unsafe_css_property, property}}

  defp responsive_rules(overrides) when is_map(overrides),
    do: responsive_rules(Map.values(overrides))

  defp responsive_rules(overrides) when is_list(overrides) do
    Enum.reduce_while(overrides, {:ok, %{}}, fn override, {:ok, widths} ->
      case responsive_width(override) do
        {:ok, numeric_width, css_width, styles} ->
          case serialize_styles(styles) do
            {:ok, declarations} ->
              case merge_width_declarations(widths, numeric_width, css_width, declarations) do
                {:ok, updated_widths} -> {:cont, {:ok, updated_widths}}
                {:error, diagnostic} -> {:halt, {:error, diagnostic}}
              end

            {:error, reason} ->
              {:halt, {:error, style_diagnostic(reason)}}
          end

        :error ->
          {:halt, {:error, responsive_gap()}}
      end
    end)
    |> case do
      {:ok, widths} -> {:ok, Enum.sort_by(widths, fn {_css_width, {width, _}} -> -width end)}
      {:error, _} = error -> error
    end
  end

  defp responsive_rules(_overrides), do: {:error, responsive_gap()}

  defp responsive_width(%ResponsiveOverride{
         resolution_status: :resolved,
         min_width: nil,
         max_width: width,
         styles: styles
       })
       when is_map(styles) and (is_integer(width) or is_float(width)) and width >= 0 do
    case serialize_width(width) do
      {:ok, css_width} -> {:ok, width, css_width, styles}
      :error -> :error
    end
  end

  defp responsive_width(_override), do: :error

  defp serialize_width(width) when is_integer(width), do: {:ok, Integer.to_string(width)}

  defp serialize_width(width) when is_float(width) and width == 0, do: {:ok, "0"}

  defp serialize_width(width) when is_float(width) do
    serialized = :erlang.float_to_binary(width, [:short])

    if String.match?(serialized, ~r/^[0-9]+(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?$/) do
      if width == trunc(width),
        do: {:ok, Integer.to_string(trunc(width))},
        else: {:ok, serialized}
    else
      :error
    end
  rescue
    ArgumentError -> :error
  end

  defp merge_width_declarations(widths, numeric_width, css_width, declarations) do
    {existing_width, existing_declarations} = Map.get(widths, css_width, {numeric_width, %{}})

    Enum.reduce_while(declarations, {:ok, existing_declarations}, fn {property, value},
                                                                     {:ok, acc} ->
      case Map.fetch(acc, property) do
        :error -> {:cont, {:ok, Map.put(acc, property, value)}}
        {:ok, ^value} -> {:cont, {:ok, acc}}
        {:ok, _other_value} -> {:halt, {:error, responsive_gap()}}
      end
    end)
    |> case do
      {:ok, merged} -> {:ok, Map.put(widths, css_width, {existing_width, merged})}
      {:error, _} = error -> error
    end
  end

  defp render_responsive(private_class, responsive_rules) do
    Enum.reduce_while(responsive_rules, {:ok, []}, fn {css_width, {_numeric_width, declarations}},
                                                      {:ok, acc} ->
      case declarations do
        empty when map_size(empty) == 0 ->
          {:cont, {:ok, acc}}

        _declarations ->
          sorted_declarations = Enum.sort_by(declarations, &elem(&1, 0))
          block = render_block("." <> private_class, sorted_declarations, 2)

          media_rule =
            "@media (max-width: " <>
              css_width <> "px) {\n  " <> String.replace(block, "\n", "\n  ") <> "\n}"

          {:cont, {:ok, [media_rule | acc]}}
      end
    end)
    |> case do
      {:ok, rules} -> {:ok, Enum.reverse(rules)}
      {:error, _} = error -> error
    end
  end

  defp render_block(_selector, [], _indent), do: nil

  defp render_block(selector, declarations, indent) do
    spacing = String.duplicate(" ", indent)

    lines =
      Enum.map_join(declarations, "\n", fn {property, value} ->
        spacing <> property <> ": " <> value <> ";"
      end)

    selector <> " {\n" <> lines <> "\n}"
  end

  defp style_diagnostic(reason) do
    Diagnostic.error(
      @style_error_code,
      "Native stylesheet declaration could not be serialized safely",
      %{reason: reason}
    )
  end

  defp responsive_gap do
    Diagnostic.error(
      @responsive_gap_code,
      "Responsive max-width cascade authority is incomplete or conflicting",
      %{}
    )
  end
end
