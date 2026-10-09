defmodule LiveFrames.Adapters.Bricks.BoundedCustomCssNormalizer do
  @moduledoc false

  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Tree
  alias LiveFrames.IR.StyleValue

  @owner_id "0531fc"
  @child_ids ["1171e1", "806d86", "fc5f68"]
  @class_name "image-group-tango"
  @class_id "cIqHGvqlwpj"

  @rule_specs %{
    "CCS-01" => %{
      selector: ".image-group-tango",
      target_id: @owner_id,
      properties: %{"min-height" => "675px"}
    },
    "CCS-02" => %{
      selector: ".image-group-tango > *:first-child",
      target_id: "1171e1",
      properties: %{"grid-column" => "1 / -1", "width" => "90%"}
    },
    "CCS-03" => %{
      selector: ".image-group-tango > *:nth-child(2)",
      target_id: "806d86",
      properties: %{"width" => "100%", "aspect-ratio" => "16/9"}
    },
    "CCS-04" => %{
      selector: ".image-group-tango > *:nth-child(3)",
      target_id: "fc5f68",
      properties: %{"width" => "100%", "aspect-ratio" => "5/3.5"}
    }
  }

  @type result :: %{
          styles_by_source_id: %{optional(String.t()) => map()},
          residual_custom_css_by_source_id: %{optional(String.t()) => String.t() | nil},
          custom_css_mode_by_source_id: %{optional(String.t()) => :legacy | :consumed | :residual},
          diagnostics: [Diagnostic.t()]
        }

  @doc false
  @spec parse_blocks(String.t()) :: [map()]
  def parse_blocks(blob) when is_binary(blob), do: parse_rule_blocks(blob)

  @spec empty_result() :: result()
  def empty_result do
    %{
      styles_by_source_id: %{},
      residual_custom_css_by_source_id: %{},
      custom_css_mode_by_source_id: %{},
      diagnostics: []
    }
  end

  @spec normalize(map()) :: result()
  def normalize(context) do
    cond do
      not Map.has_key?(context.tree.elements, @owner_id) ->
        empty_result()

      verify_topology(context.tree) == {:error, :topology_mismatch} ->
        %{
          empty_result()
          | diagnostics: [
              diagnostic(
                "bricks.bounded_custom_css.topology_mismatch",
                :warning,
                "CTA Tango image-group direct-child topology did not match the frozen CCS contract",
                Map.get(context.tree.children_by_id, @owner_id)
              )
            ]
        }

      verify_owner_class(context) != :ok ->
        empty_result()

      true ->
        with {:ok, owner_trace} <- owner_css_custom_trace(context) do
          style_result = Map.fetch!(context.dependencies.style_results, @owner_id)
          css_blobs = style_result.custom_css.base

          Enum.reduce(css_blobs, empty_result(), fn blob, acc ->
            process_blob(blob, owner_trace, context, acc)
          end)
        else
          _ -> empty_result()
        end
    end
  end

  defp verify_owner_class(context) do
    resolved = Map.fetch!(context.resolved.elements, @owner_id)

    cond do
      @class_id in resolved.class_ids and @class_name in resolved.class_names ->
        :ok

      true ->
        {:error, :owner_class_mismatch}
    end
  end

  defp verify_topology(%Tree{} = tree) do
    children = Map.get(tree.children_by_id, @owner_id)

    if children == @child_ids do
      :ok
    else
      {:error, :topology_mismatch}
    end
  end

  defp owner_css_custom_trace(context) do
    case Map.fetch(context.trace_index, @owner_id) do
      {:ok, %{trace: owner_trace}} ->
        resolved = Map.fetch!(context.resolved.elements, @owner_id)

        class_ref_index =
          resolved.class_refs
          |> Enum.find_index(fn ref -> ref.id == @class_id or ref.name == @class_name end)

        source_path =
          if is_integer(class_ref_index) do
            "#{owner_trace.source_path}.class_refs[#{class_ref_index}].settings._cssCustom"
          else
            "#{owner_trace.source_path}.settings._cssCustom"
          end

        trace = %{
          owner_trace
          | source_type: "bricks_style",
            source_path: source_path,
            source_name: "_cssCustom",
            inference: "bounded CTA Tango image-group custom CSS normalized to node-local styles"
        }

        {:ok, trace}

      :error ->
        {:error, :missing_owner}
    end
  end

  defp process_blob(blob, owner_trace, context, acc) when is_binary(blob) do
    parsed_rules = parse_rule_blocks(blob)

    {accepted, rejected, diagnostics} =
      classify_rules(parsed_rules, context, owner_trace)

    styles_by_source_id =
      merge_styles(acc.styles_by_source_id, accepted)

    residual_text =
      rejected
      |> Enum.map(& &1.raw)
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n\n")

    mode =
      cond do
        map_size(accepted) == 0 and rejected == [] -> :legacy
        residual_text == "" -> :consumed
        true -> :residual
      end

    residual_value = if residual_text == "", do: nil, else: String.trim(residual_text)

    %{
      acc
      | styles_by_source_id: styles_by_source_id,
        residual_custom_css_by_source_id:
          Map.put(acc.residual_custom_css_by_source_id, @owner_id, residual_value),
        custom_css_mode_by_source_id: Map.put(acc.custom_css_mode_by_source_id, @owner_id, mode),
        diagnostics: acc.diagnostics ++ diagnostics
    }
  end

  defp process_blob(_blob, _owner_trace, _context, acc), do: acc

  defp classify_rules(parsed_rules, context, owner_trace) do
    Enum.reduce(parsed_rules, {%{}, [], []}, fn rule, {accepted, rejected, diagnostics} ->
      case match_rule(rule) do
        {:ok, rule_id} ->
          case Map.get(accepted, rule_id) do
            nil ->
              case apply_rule(rule_id, context, owner_trace) do
                {:ok, styles} ->
                  {Map.put(accepted, rule_id, styles), rejected, diagnostics}

                {:error, :style_collision, property, target_id} ->
                  {
                    accepted,
                    rejected ++ [rule],
                    diagnostics ++
                      [
                        diagnostic(
                          "bricks.bounded_custom_css.style_collision",
                          :warning,
                          "Bounded custom CSS rule #{rule_id} could not relocate #{property} onto #{target_id} because the target already owns that property",
                          property,
                          target_id
                        )
                      ]
                  }
              end

            _existing ->
              {
                Map.delete(accepted, rule_id),
                rejected ++ [rule],
                diagnostics ++
                  [
                    diagnostic(
                      "bricks.bounded_custom_css.duplicate_rule",
                      :warning,
                      "Bounded custom CSS rule #{rule_id} appeared more than once in the source blob",
                      rule_id
                    )
                  ]
              }
          end

        {:error, :declaration_mismatch} ->
          {
            accepted,
            rejected ++ [rule],
            diagnostics ++
              [
                diagnostic(
                  "bricks.bounded_custom_css.declaration_mismatch",
                  :warning,
                  "Bounded custom CSS declarations did not match the frozen CTA Tango contract",
                  rule.selector
                )
              ]
          }

        :unsupported ->
          {
            accepted,
            rejected ++ [rule],
            diagnostics ++
              [
                diagnostic(
                  "bricks.bounded_custom_css.unsupported_selector",
                  :warning,
                  "Bounded custom CSS selector is outside the frozen CTA Tango CCS-01..04 contract",
                  rule.selector
                )
              ]
          }
      end
    end)
  end

  defp apply_rule(rule_id, context, owner_trace) do
    spec = Map.fetch!(@rule_specs, rule_id)
    target_id = spec.target_id
    style_result = Map.fetch!(context.dependencies.style_results, target_id)

    existing_properties =
      style_result.base_styles
      |> Map.keys()
      |> MapSet.new()

    colliding_property =
      Enum.find(spec.properties, fn {property, _value} ->
        MapSet.member?(existing_properties, property)
      end)

    if colliding_property do
      {property, _value} = colliding_property
      {:error, :style_collision, property, target_id}
    else
      styles =
        Map.new(spec.properties, fn {property, value} ->
          {property,
           StyleValue.literal(value,
             source_expression: value,
             source_trace: owner_trace,
             metadata: %{
               "bounded_rule_id" => rule_id,
               "source_owner_id" => @owner_id,
               "source_selector_trace" => spec.selector
             }
           )}
        end)

      {:ok, styles}
    end
  end

  defp match_rule(%{selector: selector, declarations: declarations}) do
    normalized_selector = normalize_selector(selector)

    case Enum.find(@rule_specs, fn {_id, spec} ->
           normalize_selector(spec.selector) == normalized_selector
         end) do
      {rule_id, spec} ->
        if declarations_match?(declarations, spec.properties),
          do: {:ok, rule_id},
          else: {:error, :declaration_mismatch}

      nil ->
        :unsupported
    end
  end

  defp declarations_match?(declarations, expected) do
    normalized_declarations =
      declarations
      |> Enum.map(fn {property, value} ->
        {property, normalize_declaration_value(property, value)}
      end)
      |> Map.new()

    normalized_expected =
      Map.new(expected, fn {property, value} ->
        {property, normalize_declaration_value(property, value)}
      end)

    map_size(normalized_declarations) == map_size(normalized_expected) and
      normalized_declarations == normalized_expected
  end

  defp parse_rule_blocks(blob) do
    blob
    |> strip_comments()
    |> String.split("}", trim: true)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&parse_rule_block/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_rule_block(chunk) do
    case String.split(chunk, "{", parts: 2) do
      [selector, body] ->
        declarations = parse_declarations(body)

        if map_size(declarations) == 0 do
          nil
        else
          %{
            selector: String.trim(selector),
            declarations: declarations,
            raw: "#{String.trim(selector)} { #{String.trim(body)} }"
          }
        end

      _ ->
        nil
    end
  end

  defp parse_declarations(body) do
    body
    |> String.split(";", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.reduce({%{}, nil}, fn decl, {acc, _duplicate} ->
      case String.split(decl, ":", parts: 2) do
        [property, value] ->
          property = property |> String.trim() |> String.downcase()
          value = String.trim(value)

          if Map.has_key?(acc, property) do
            {acc, :duplicate}
          else
            {Map.put(acc, property, value), nil}
          end

        _ ->
          {acc, :invalid}
      end
    end)
    |> case do
      {declarations, nil} -> declarations
      _ -> %{}
    end
  end

  defp normalize_selector(selector) do
    selector
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
  end

  defp normalize_declaration_value("grid-column", value) do
    value
    |> String.replace(~r/\s+/, "")
    |> String.replace("1/-1", "1 / -1")
  end

  defp normalize_declaration_value(_property, value) do
    value |> String.trim() |> String.replace(~r/\s+/, " ")
  end

  defp strip_comments(css) do
    Regex.replace(~r/\/\*.*?\*\//s, css, "")
  end

  defp merge_styles(styles_by_source_id, accepted_rules) do
    Enum.reduce(accepted_rules, styles_by_source_id, fn {rule_id, rule_styles}, acc ->
      target_id = @rule_specs |> Map.fetch!(rule_id) |> Map.fetch!(:target_id)

      Map.update(acc, target_id, rule_styles, &Map.merge(&1, rule_styles))
    end)
  end

  defp diagnostic(code, severity, message, raw_value, source_id \\ @owner_id) do
    Diagnostic.new(
      code: code,
      severity: severity,
      message: message,
      source_id: source_id,
      raw_value: raw_value
    )
  end
end
