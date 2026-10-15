defmodule LiveFrames.NativeGenerator.StylesheetRenderer do
  @moduledoc false

  alias LiveFrames.Fidelity.CSSDeclaration
  alias LiveFrames.IR.ResponsiveOverride
  alias LiveFrames.IR.StyleValue
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

  @spec render_figure_image(String.t(), map(), map()) ::
          {:ok, String.t()} | {:error, Diagnostic.t()}
  def render_figure_image(private_class, figure_styles, image_styles) do
    with :ok <- validate_private_class(private_class),
         {:ok, figure_declarations} <- serialize_styles(figure_styles),
         {:ok, image_declarations} <- serialize_styles(image_styles) do
      css =
        [
          render_block("." <> private_class, figure_declarations, 2),
          render_block("." <> private_class <> " > img", image_declarations, 2)
        ]
        |> Enum.reject(&is_nil/1)
        |> Enum.join("\n\n")

      if css == "", do: {:ok, ""}, else: {:ok, css <> "\n"}
    else
      {:error, %Diagnostic{} = diagnostic} -> {:error, diagnostic}
      {:error, reason} -> {:error, style_diagnostic(reason)}
    end
  end

  @spec render_primary_action_slot(String.t(), map(), map()) ::
          {:ok, String.t()} | {:error, Diagnostic.t()}
  def render_primary_action_slot(private_class, base_styles, pseudo_styles) do
    selector = "." <> private_class <> " > :where(a, button)"

    structure = %{
      "align-items" => StyleValue.keyword("center"),
      "box-sizing" => StyleValue.keyword("border-box"),
      "display" => StyleValue.keyword("inline-flex"),
      "font-family" => StyleValue.keyword("inherit"),
      "justify-content" => StyleValue.keyword("center"),
      "text-decoration" => StyleValue.keyword("none")
    }

    with :ok <- validate_private_class(private_class),
         {:ok, action_declarations} <- serialize_styles(Map.merge(structure, base_styles)),
         {:ok, pseudo_css} <- render_primary_action_pseudos(selector, pseudo_styles) do
      css =
        [
          render_block("." <> private_class, [{"display", "contents"}], 2),
          render_block(selector, action_declarations, 2),
          pseudo_css
        ]
        |> Enum.reject(&is_nil/1)
        |> Enum.join("\n\n")

      {:ok, css <> "\n"}
    else
      {:error, %Diagnostic{} = diagnostic} -> {:error, diagnostic}
      {:error, reason} -> {:error, style_diagnostic(reason)}
    end
  end

  defp render_primary_action_pseudos(selector, pseudos) do
    Enum.reduce_while([:hover, :focus_visible], {:ok, []}, fn pseudo, {:ok, acc} ->
      case Map.fetch(pseudos, pseudo) do
        {:ok, styles} ->
          with {:ok, declarations} <- serialize_styles(styles) do
            suffix = if pseudo == :hover, do: ":hover", else: ":focus-visible"
            {:cont, {:ok, [render_block(selector <> suffix, declarations, 2) | acc]}}
          else
            {:error, reason} -> {:halt, {:error, style_diagnostic(reason)}}
          end

        :error ->
          {:cont, {:ok, acc}}
      end
    end)
    |> case do
      {:ok, blocks} ->
        css = blocks |> Enum.reverse() |> Enum.reject(&is_nil/1) |> Enum.join("\n\n")
        {:ok, css}

      {:error, _} = error ->
        error
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

  @spec render_state_rule(String.t(), String.t(), :hover | :focus_within, map(), map() | nil) ::
          {:ok, String.t()} | {:error, Diagnostic.t()}
  def render_state_rule(owner_private_class, target_private_class, condition, styles, viewport) do
    with :ok <- validate_private_class(owner_private_class),
         :ok <- validate_private_class(target_private_class),
         {:ok, pseudo} <- state_rule_pseudo(condition),
         {:ok, declarations} <- serialize_styles(styles),
         {:ok, media_bounds} <- state_rule_media_bounds(viewport) do
      selector =
        "." <>
          owner_private_class <>
          pseudo <>
          if(owner_private_class == target_private_class,
            do: "",
            else: " ." <> target_private_class
          )

      case render_block(selector, declarations, 2) do
        nil ->
          {:ok, ""}

        block when is_nil(media_bounds) ->
          {:ok, block <> "\n"}

        block ->
          media_conditions =
            []
            |> maybe_add_media_condition(media_bounds.serialized_min, "min-width")
            |> maybe_add_media_condition(media_bounds.serialized_max, "max-width")
            |> Enum.join(") and (")

          media_rule =
            "@media (" <>
              media_conditions <>
              ") {\n  " <> String.replace(block, "\n", "\n  ") <> "\n}"

          {:ok, media_rule <> "\n"}
      end
    else
      {:error, %Diagnostic{} = diagnostic} -> {:error, diagnostic}
      {:error, reason} -> {:error, style_diagnostic(reason)}
    end
  end

  defp state_rule_pseudo(:hover), do: {:ok, ":hover"}
  defp state_rule_pseudo(:focus_within), do: {:ok, ":focus-within"}
  defp state_rule_pseudo(_condition), do: {:error, :unsupported_state_condition}

  defp state_rule_media_bounds(nil), do: {:ok, nil}

  defp state_rule_media_bounds(%{min_width: min_width, max_width: max_width} = viewport)
       when not is_struct(viewport) and map_size(viewport) == 2 do
    with true <- not (is_nil(min_width) and is_nil(max_width)),
         {:ok, normalized_min, serialized_min} <- normalize_bound(min_width),
         {:ok, normalized_max, serialized_max} <- normalize_bound(max_width),
         true <-
           is_nil(normalized_min) or is_nil(normalized_max) or normalized_min <= normalized_max do
      {:ok,
       %{
         min_width: normalized_min,
         max_width: normalized_max,
         serialized_min: serialized_min,
         serialized_max: serialized_max
       }}
    else
      _ -> {:error, :invalid_state_rule_viewport}
    end
  end

  defp state_rule_media_bounds(_viewport), do: {:error, :invalid_state_rule_viewport}

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
    Enum.reduce_while(overrides, {:ok, %{}}, fn override, {:ok, intervals} ->
      case responsive_interval(override) do
        {:ok, interval, styles} ->
          case serialize_styles(styles) do
            {:ok, declarations} ->
              case merge_interval_declarations(intervals, interval, declarations) do
                {:ok, updated_intervals} -> {:cont, {:ok, updated_intervals}}
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
      {:ok, intervals} ->
        ordered_intervals = intervals |> Map.values() |> Enum.sort_by(&interval_sort_key/1)

        case validate_interval_overlaps(ordered_intervals) do
          :ok -> {:ok, ordered_intervals}
          {:error, _} = error -> error
        end

      {:error, _} = error ->
        error
    end
  end

  defp responsive_rules(_overrides), do: {:error, responsive_gap()}

  defp responsive_interval(%ResponsiveOverride{
         resolution_status: :resolved,
         min_width: min_width,
         max_width: max_width,
         styles: styles
       })
       when is_map(styles) do
    with true <- is_number(min_width) or is_nil(min_width),
         true <- is_number(max_width) or is_nil(max_width),
         false <- is_nil(min_width) and is_nil(max_width),
         {:ok, normalized_min, serialized_min} <- normalize_bound(min_width),
         {:ok, normalized_max, serialized_max} <- normalize_bound(max_width),
         true <-
           is_nil(normalized_min) or is_nil(normalized_max) or normalized_min <= normalized_max do
      interval = %{
        min_width: normalized_min,
        max_width: normalized_max,
        serialized_min: serialized_min,
        serialized_max: serialized_max
      }

      {:ok, interval, styles}
    else
      _ -> :error
    end
  end

  defp responsive_interval(_override), do: :error

  defp normalize_bound(nil), do: {:ok, nil, nil}

  defp normalize_bound(width) when is_integer(width) or is_float(width) do
    if width >= 0 do
      case serialize_width(width) do
        {:ok, serialized_width} -> {:ok, width, serialized_width}
        :error -> :error
      end
    else
      :error
    end
  end

  defp normalize_bound(_width), do: :error

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

  defp merge_interval_declarations(intervals, interval, declarations) do
    identity = interval_identity(interval)
    existing = Map.get(intervals, identity, Map.put(interval, :declarations, %{}))

    Enum.reduce_while(declarations, {:ok, existing.declarations}, fn {property, value},
                                                                     {:ok, acc} ->
      case Map.fetch(acc, property) do
        :error -> {:cont, {:ok, Map.put(acc, property, value)}}
        {:ok, ^value} -> {:cont, {:ok, acc}}
        {:ok, _other_value} -> {:halt, {:error, responsive_gap()}}
      end
    end)
    |> case do
      {:ok, merged} ->
        {:ok, Map.put(intervals, identity, Map.put(existing, :declarations, merged))}

      {:error, _} = error ->
        error
    end
  end

  defp interval_identity(interval) do
    {interval.serialized_min, interval.serialized_max}
  end

  defp interval_sort_key(interval) do
    {
      lower_bound_sort_key(interval.min_width),
      upper_bound_sort_key(interval.max_width),
      interval.serialized_min || "",
      interval.serialized_max || ""
    }
  end

  defp lower_bound_sort_key(nil), do: {0, 0}
  defp lower_bound_sort_key(width), do: {1, width}

  defp upper_bound_sort_key(nil), do: {0, 0}
  defp upper_bound_sort_key(width), do: {1, -width}

  defp validate_interval_overlaps(intervals) do
    if Enum.any?(intervals, &interval_has_conflicting_overlap?(&1, intervals)) do
      {:error, responsive_gap()}
    else
      :ok
    end
  end

  defp interval_has_conflicting_overlap?(interval, intervals) do
    Enum.any?(intervals, fn other ->
      interval_identity(interval) != interval_identity(other) and
        conflicting_interval_values?(interval, other)
    end)
  end

  defp conflicting_interval_values?(left, right) do
    not (max_only_interval?(left) and max_only_interval?(right)) and
      intervals_overlap?(left, right) and
      Enum.any?(left.declarations, fn {property, value} ->
        case Map.fetch(right.declarations, property) do
          {:ok, other_value} -> value != other_value
          :error -> false
        end
      end)
  end

  defp max_only_interval?(%{min_width: nil, max_width: max_width})
       when is_number(max_width),
       do: true

  defp max_only_interval?(_interval), do: false

  defp intervals_overlap?(left, right) do
    lower_bound = greater_lower_bound(left.min_width, right.min_width)
    upper_bound = lesser_upper_bound(left.max_width, right.max_width)

    is_nil(lower_bound) or is_nil(upper_bound) or lower_bound <= upper_bound
  end

  defp greater_lower_bound(nil, width), do: width
  defp greater_lower_bound(width, nil), do: width
  defp greater_lower_bound(left, right), do: max(left, right)

  defp lesser_upper_bound(nil, width), do: width
  defp lesser_upper_bound(width, nil), do: width
  defp lesser_upper_bound(left, right), do: min(left, right)

  defp render_responsive(private_class, responsive_rules) do
    Enum.reduce_while(responsive_rules, {:ok, []}, fn interval, {:ok, acc} ->
      case interval.declarations do
        empty when map_size(empty) == 0 ->
          {:cont, {:ok, acc}}

        _declarations ->
          sorted_declarations = Enum.sort_by(interval.declarations, &elem(&1, 0))
          block = render_block("." <> private_class, sorted_declarations, 2)

          media_conditions =
            []
            |> maybe_add_media_condition(interval.serialized_min, "min-width")
            |> maybe_add_media_condition(interval.serialized_max, "max-width")
            |> Enum.join(") and (")

          media_rule =
            "@media (" <>
              media_conditions <> ") {\n  " <> String.replace(block, "\n", "\n  ") <> "\n}"

          {:cont, {:ok, [media_rule | acc]}}
      end
    end)
    |> case do
      {:ok, rules} -> {:ok, Enum.reverse(rules)}
      {:error, _} = error -> error
    end
  end

  defp maybe_add_media_condition(conditions, nil, _name), do: conditions

  defp maybe_add_media_condition(conditions, width, name),
    do: conditions ++ [name <> ": " <> width <> "px"]

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
      "Responsive interval authority is incomplete or conflicting",
      %{}
    )
  end
end
