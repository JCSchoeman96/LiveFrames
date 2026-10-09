defmodule LiveFrames.Adapters.Bricks.BoundedCustomCssNormalizer do
  @moduledoc false

  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Settings
  alias LiveFrames.Adapters.Bricks.StylePrecedence
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

  @frozen_selector_strings Enum.map(@rule_specs, fn {_id, spec} -> spec.selector end)

  @type result :: %{
          styles_by_source_id: %{optional(String.t()) => map()},
          residual_custom_css_by_source_id: %{optional(String.t()) => String.t() | nil},
          custom_css_mode_by_source_id: %{optional(String.t()) => :legacy | :consumed | :residual},
          diagnostics: [Diagnostic.t()]
        }

  @doc false
  @spec parse_blocks(String.t()) :: [map()]
  def parse_blocks(blob) when is_binary(blob) do
    {rules, _rejects} = parse_rule_blocks(blob)
    rules
  end

  @doc false
  @spec parse_parts(String.t()) :: {[map()], [map()]}
  def parse_parts(blob) when is_binary(blob), do: parse_rule_blocks(blob)

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
        case authorized_effective_custom_css(context) do
          {:ok, blob, owner_trace} ->
            process_blob(blob, owner_trace, context, empty_result())

          {:error, _} ->
            empty_result()
        end
    end
  end

  defp verify_owner_class(context) do
    resolved = Map.fetch!(context.resolved.elements, @owner_id)

    if frozen_class_ref?(resolved) do
      :ok
    else
      {:error, :owner_class_mismatch}
    end
  end

  defp frozen_class_ref?(resolved) do
    Enum.any?(resolved.class_refs, fn ref ->
      ref.id == @class_id and ref.name == @class_name and
        ref.resolution_status in [:local_resolved, :external_resolved]
    end)
  end

  defp verify_topology(%Tree{} = tree) do
    children = Map.get(tree.children_by_id, @owner_id)

    if children == @child_ids do
      :ok
    else
      {:error, :topology_mismatch}
    end
  end

  defp authorized_effective_custom_css(context) do
    resolved = Map.fetch!(context.resolved.elements, @owner_id)
    style_result = Map.fetch!(context.dependencies.style_results, @owner_id)

    layers =
      StylePrecedence.layers(resolved.class_refs, resolved.source_settings, @owner_id)

    extraction_opts = [semantic_settings: [], rejected_semantic_settings: []]

    contributions =
      layers
      |> Enum.flat_map(fn layer ->
        extraction = Settings.extract(layer.settings, extraction_opts)

        Enum.map(extraction.custom_css.base, fn value -> {layer, value} end)
      end)

    with [_ | _] = contributions,
         {effective_layer, effective_blob} <- List.last(contributions),
         true <- effective_layer.origin == :global_class,
         true <- effective_layer.class_id == @class_id,
         true <- frozen_layer_class_ref?(resolved, effective_layer),
         true <- effective_blob_effective?(style_result, effective_blob),
         {:ok, owner_trace} <- owner_css_custom_trace(context, effective_layer) do
      {:ok, effective_blob, owner_trace}
    else
      _ -> {:error, :unauthorized_custom_css_source}
    end
  end

  defp effective_blob_effective?(style_result, effective_blob) do
    case style_result.custom_css.base do
      [^effective_blob] -> true
      [] -> false
      [other] -> other == effective_blob
      _ -> effective_blob in style_result.custom_css.base
    end
  end

  defp frozen_layer_class_ref?(resolved, layer) do
    case Enum.at(resolved.class_refs, layer.class_reference_index) do
      %{id: id, name: name} when id == @class_id and name == @class_name ->
        true

      _ ->
        false
    end
  end

  defp owner_css_custom_trace(context, effective_layer) do
    case Map.fetch(context.trace_index, @owner_id) do
      {:ok, %{trace: owner_trace}} ->
        resolved = Map.fetch!(context.resolved.elements, @owner_id)
        index = effective_layer.class_reference_index

        case Enum.at(resolved.class_refs, index) do
          %{id: @class_id, name: @class_name} ->
            trace = %{
              owner_trace
              | source_type: "bricks_style",
                source_path:
                  "#{owner_trace.source_path}.class_refs[#{index}].settings._cssCustom",
                source_name: "_cssCustom",
                inference:
                  "bounded CTA Tango image-group custom CSS normalized to node-local styles"
            }

            {:ok, trace}

          _ ->
            {:error, :missing_frozen_class_ref}
        end

      :error ->
        {:error, :missing_owner}
    end
  end

  defp process_blob(blob, owner_trace, context, acc) when is_binary(blob) do
    case scan_flat_blocks(blob) do
      {:error, reason, _detail} ->
        framing_fail_closed(acc, blob, reason)

      {:ok, frames} ->
        process_framed_blob(blob, frames, owner_trace, context, acc)
    end
  end

  defp process_blob(_blob, _owner_trace, _context, acc), do: acc

  defp framing_fail_closed(acc, blob, reason) do
    %{
      acc
      | residual_custom_css_by_source_id:
          Map.put(acc.residual_custom_css_by_source_id, @owner_id, String.trim(blob)),
        custom_css_mode_by_source_id:
          Map.put(acc.custom_css_mode_by_source_id, @owner_id, :residual),
        diagnostics:
          acc.diagnostics ++
            [
              diagnostic(
                "bricks.bounded_custom_css.framing_ambiguous",
                :warning,
                "Bounded custom CSS blob framing is ambiguous or incomplete; the full source blob was preserved in residual complex_css",
                reason
              )
            ]
    }
  end

  defp process_framed_blob(_blob, frames, owner_trace, context, acc) do
    duplicate_selectors = duplicate_frozen_selectors_from_frames(frames)

    {parsed_rules, unparseable_blocks} = frames_to_rules(frames)

    unparseable_rejects =
      Enum.map(unparseable_blocks, fn block ->
        %{
          raw: block.raw,
          kind: :unparseable,
          selector: Map.get(block, :selector)
        }
      end)

    unparseable_diagnostics =
      Enum.map(unparseable_blocks, fn block ->
        diagnostic(
          "bricks.bounded_custom_css.unparseable_block",
          :warning,
          "Bounded custom CSS block could not be parsed safely and was preserved in residual complex_css",
          block.raw
        )
      end)

    {accepted, rejected, diagnostics} =
      classify_rules(parsed_rules, duplicate_selectors, context, owner_trace)

    rejected = rejected ++ unparseable_rejects
    diagnostics = diagnostics ++ unparseable_diagnostics

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

  defp duplicate_frozen_selectors_from_frames(frames) do
    frames
    |> Enum.map(&normalize_selector(&1.selector))
    |> Enum.filter(&frozen_selector_normalized?/1)
    |> Enum.frequencies()
    |> Enum.filter(fn {_selector, count} -> count >= 2 end)
    |> Enum.map(&elem(&1, 0))
    |> MapSet.new()
  end

  defp frozen_selector_normalized?(normalized) do
    Enum.any?(@frozen_selector_strings, fn frozen ->
      normalize_selector(frozen) == normalized
    end)
  end

  defp classify_rules(parsed_rules, duplicate_selectors, context, owner_trace) do
    Enum.reduce(parsed_rules, {%{}, [], []}, fn rule, {accepted, rejected, diagnostics} ->
      normalized_selector = normalize_selector(rule.selector)

      cond do
        MapSet.member?(duplicate_selectors, normalized_selector) ->
          {
            accepted,
            rejected ++ [rule],
            diagnostics ++
              [
                diagnostic(
                  "bricks.bounded_custom_css.duplicate_rule",
                  :warning,
                  "Bounded custom CSS frozen selector appeared more than once in the source blob",
                  rule.selector
                )
              ]
          }

        true ->
          case match_rule(rule) do
            {:ok, rule_id} ->
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
      end
    end)
  end

  defp apply_rule(rule_id, context, owner_trace) do
    spec = Map.fetch!(@rule_specs, rule_id)
    target_id = spec.target_id
    style_result = Map.fetch!(context.dependencies.style_results, target_id)

    owned_properties = base_resolution_properties(style_result)

    colliding_property =
      Enum.find(spec.properties, fn {property, _value} ->
        MapSet.member?(owned_properties, property)
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

  defp base_resolution_properties(style_result) do
    style_result.resolutions
    |> Enum.filter(&(&1.breakpoint == nil))
    |> Enum.map(& &1.property)
    |> MapSet.new()
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
    case scan_flat_blocks(blob) do
      {:ok, frames} ->
        frames_to_rules(frames)

      {:error, _reason, _detail} ->
        {[], [%{raw: blob, selector: nil}]}
    end
  end

  defp frames_to_rules(frames) do
    Enum.reduce(frames, {[], []}, fn frame, {rules, rejects} ->
      case frame_to_rule(frame) do
        {:ok, rule} ->
          {rules ++ [rule], rejects}

        {:error, _} ->
          {rules, rejects ++ [%{raw: frame.raw, selector: frame.selector}]}
      end
    end)
  end

  defp frame_to_rule(frame) do
    case parse_declarations(frame.body) do
      {:ok, declarations} ->
        {:ok,
         %{
           selector: frame.selector,
           declarations: declarations,
           raw: frame.raw
         }}

      {:error, _} ->
        {:error, :invalid_declarations}
    end
  end

  defp scan_flat_blocks(blob) when is_binary(blob) do
    scan_flat_blocks(blob, 0, [])
  end

  defp scan_flat_blocks(blob, index, blocks) do
    index = skip_trivia(blob, index)

    cond do
      index >= byte_size(blob) ->
        {:ok, Enum.reverse(blocks)}

      :binary.at(blob, index) == ?} ->
        {:error, :unmatched_closing_brace, index}

      true ->
        case read_flat_block(blob, index) do
          {:ok, frame, next_index} ->
            scan_flat_blocks(blob, next_index, [frame | blocks])

          {:error, _reason, _detail} = error ->
            error
        end
    end
  end

  defp read_flat_block(blob, index) do
    selector_start = index
    {selector_end, index} = read_until(blob, index, ?{)

    if index >= byte_size(blob) do
      orphan =
        String.slice(blob, selector_start, byte_size(blob) - selector_start) |> String.trim()

      if orphan == "" do
        {:error, :missing_closing_brace, selector_start}
      else
        {:error, :orphan_text, selector_start}
      end
    else
      selector =
        String.slice(blob, selector_start, selector_end - selector_start) |> String.trim()

      if selector == "" do
        {:error, :framing_ambiguous, index}
      else
        body_start = index + 1
        block_start = selector_start

        case read_balanced_body(blob, body_start, 1) do
          {:ok, body_end, close_index} ->
            body = String.slice(blob, body_start, body_end - body_start)
            raw = String.slice(blob, block_start, close_index - block_start + 1)

            frame = %{
              selector: selector,
              body: body,
              raw: raw
            }

            {:ok, frame, close_index + 1}

          {:error, _reason, _detail} = error ->
            error
        end
      end
    end
  end

  defp read_balanced_body(blob, index, depth) do
    if index >= byte_size(blob) do
      {:error, :missing_closing_brace, index}
    else
      case :binary.at(blob, index) do
        ?{ ->
          if depth >= 1 do
            {:error, :nested_block, index}
          else
            read_balanced_body(blob, index + 1, depth + 1)
          end

        ?} ->
          next_depth = depth - 1

          if next_depth == 0 do
            {:ok, index, index}
          else
            read_balanced_body(blob, index + 1, next_depth)
          end

        _ ->
          read_balanced_body(blob, index + 1, depth)
      end
    end
  end

  defp read_until(blob, index, char) do
    if index >= byte_size(blob) do
      {index, index}
    else
      case :binary.at(blob, index) do
        ^char ->
          {index, index}

        _ ->
          read_until(blob, index + 1, char)
      end
    end
  end

  defp skip_trivia(blob, index) do
    cond do
      index >= byte_size(blob) ->
        index

      index + 1 < byte_size(blob) and :binary.part(blob, index, 2) == "/*" ->
        comment_body_start = index + 2

        case :binary.match(blob, "*/", [
               {:scope, {comment_body_start, byte_size(blob) - comment_body_start}}
             ]) do
          {close_start, _close_length} -> skip_trivia(blob, close_start + 2)
          :nomatch -> byte_size(blob)
        end

      :binary.at(blob, index) in [?\s, ?\n, ?\r, ?\t] ->
        skip_trivia(blob, index + 1)

      true ->
        index
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
      {declarations, nil} when map_size(declarations) > 0 -> {:ok, declarations}
      _ -> {:error, :invalid_declarations}
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
