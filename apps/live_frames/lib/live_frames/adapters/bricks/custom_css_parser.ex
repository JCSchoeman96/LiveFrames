defmodule LiveFrames.Adapters.Bricks.CustomCssParser do
  @moduledoc false

  @max_finite_float 1.7976931348623157e308
  @property_name ~r/\A(?:--[A-Za-z0-9_-]+|-?[A-Za-z_][A-Za-z0-9_-]*)\z/

  @doc false
  @spec parse(String.t()) :: %{frames: [map()], rejects: [map()]}
  def parse(css) when is_binary(css) do
    case scan_items(css, 0, 0, [], []) do
      {:ok, frames, rejects, _source_order} ->
        %{frames: frames, rejects: rejects}

      {:error, reason} ->
        %{frames: [], rejects: [%{raw: css, reason: reason, source_order: 0}]}
    end
  end

  @doc false
  @spec parse_flat_blocks(String.t()) :: {:ok, [map()]} | {:error, atom(), non_neg_integer()}
  def parse_flat_blocks(css) when is_binary(css) do
    scan_flat_blocks(css, 0, [])
  end

  @doc false
  @spec parse_flat_blocks_legacy(String.t()) ::
          {:ok, [map()]} | {:error, atom(), non_neg_integer()}
  def parse_flat_blocks_legacy(css) when is_binary(css) do
    scan_flat_blocks_legacy(css, 0, [])
  end

  @doc false
  @spec parse_declarations(String.t()) :: {:ok, map()} | {:error, atom()}
  def parse_declarations(body) when is_binary(body) do
    with {:ok, segments} <- scan_declaration_segments(body) do
      segments
      |> Enum.reduce_while({:ok, %{}}, fn segment, {:ok, declarations} ->
        case parse_declaration_segment(body, segment) do
          {:ok, :skip} ->
            {:cont, {:ok, declarations}}

          {:ok, {property, value}} ->
            cond do
              not Regex.match?(@property_name, property) ->
                {:halt, {:error, :invalid_declaration}}

              Map.has_key?(declarations, property) ->
                {:halt, {:error, :duplicate_property}}

              true ->
                {:cont, {:ok, Map.put(declarations, property, value)}}
            end

          {:error, reason} ->
            {:halt, {:error, reason}}
        end
      end)
      |> case do
        {:ok, declarations} when map_size(declarations) > 0 -> {:ok, declarations}
        {:ok, _} -> {:error, :invalid_declaration}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp scan_declaration_segments(body) do
    scan_declaration_segments(body, 0, 0, nil, [], [])
  end

  defp scan_declaration_segments(body, index, start, colon, nesting, segments)
       when index >= byte_size(body) do
    if nesting == [] do
      segment = {start, index - start, colon}
      {:ok, Enum.reverse([segment | segments])}
    else
      {:error, :invalid_declaration}
    end
  end

  defp scan_declaration_segments(body, index, start, colon, nesting, segments) do
    cond do
      comment_start?(body, index) ->
        case skip_comment(body, index) do
          {:ok, next_index} ->
            scan_declaration_segments(
              body,
              next_index,
              start,
              colon,
              nesting,
              segments
            )

          {:error, _reason, _detail} ->
            {:error, :invalid_declaration}
        end

      :binary.at(body, index) in [?\", ?'] ->
        quote = :binary.at(body, index)

        case skip_string(body, index + 1, quote) do
          {:ok, next_index} ->
            scan_declaration_segments(
              body,
              next_index,
              start,
              colon,
              nesting,
              segments
            )

          {:error, _reason, _detail} ->
            {:error, :invalid_declaration}
        end

      true ->
        scan_declaration_char(
          body,
          index,
          start,
          colon,
          nesting,
          segments
        )
    end
  end

  defp scan_declaration_char(body, index, start, colon, nesting, segments) do
    case {:binary.at(body, index), nesting} do
      {?(, _nesting} ->
        scan_declaration_segments(
          body,
          index + 1,
          start,
          colon,
          [?( | nesting],
          segments
        )

      {?), [?( | rest]} ->
        scan_declaration_segments(
          body,
          index + 1,
          start,
          colon,
          rest,
          segments
        )

      {?), _nesting} ->
        {:error, :invalid_declaration}

      {?[, _nesting} ->
        scan_declaration_segments(
          body,
          index + 1,
          start,
          colon,
          [?[ | nesting],
          segments
        )

      {?], [?[ | rest]} ->
        scan_declaration_segments(
          body,
          index + 1,
          start,
          colon,
          rest,
          segments
        )

      {?], _nesting} ->
        {:error, :invalid_declaration}

      {?:, []} when is_nil(colon) ->
        scan_declaration_segments(
          body,
          index + 1,
          start,
          index,
          nesting,
          segments
        )

      {?;, []} ->
        segment = {start, index - start, colon}

        scan_declaration_segments(
          body,
          index + 1,
          index + 1,
          nil,
          nesting,
          [segment | segments]
        )

      {_char, _nesting} ->
        scan_declaration_segments(
          body,
          index + 1,
          start,
          colon,
          nesting,
          segments
        )
    end
  end

  defp parse_declaration_segment(body, {start, length, nil}) do
    segment = binary_part(body, start, length)

    case strip_comments(segment) do
      {:ok, text} ->
        if String.trim(text) == "", do: {:ok, :skip}, else: {:error, :invalid_declaration}

      {:error, _reason} ->
        {:error, :invalid_declaration}
    end
  end

  defp parse_declaration_segment(body, {start, length, colon}) do
    property_source = binary_part(body, start, colon - start)
    value_source = binary_part(body, colon + 1, start + length - colon - 1)

    with {:ok, property_source} <- strip_comments(property_source),
         {:ok, value_without_comments} <- strip_comments(value_source) do
      property = String.trim(property_source)
      value = String.trim(value_source)

      cond do
        property == "" or String.trim(value_without_comments) == "" ->
          {:error, :invalid_declaration}

        true ->
          property =
            if String.starts_with?(property, "--"), do: property, else: String.downcase(property)

          {:ok, {property, value}}
      end
    else
      {:error, _reason} -> {:error, :invalid_declaration}
    end
  end

  defp strip_comments(text) do
    strip_comments(text, 0, 0, [])
  end

  defp strip_comments(text, index, chunk_start, chunks) when index >= byte_size(text) do
    tail = binary_part(text, chunk_start, byte_size(text) - chunk_start)
    {:ok, chunks |> Enum.reverse([tail]) |> IO.iodata_to_binary()}
  end

  defp strip_comments(text, index, chunk_start, chunks) do
    cond do
      comment_start?(text, index) ->
        chunk = binary_part(text, chunk_start, index - chunk_start)

        case skip_comment(text, index) do
          {:ok, next_index} -> strip_comments(text, next_index, next_index, [" ", chunk | chunks])
          {:error, _reason, _detail} -> {:error, :invalid_declaration}
        end

      :binary.at(text, index) in [?\", ?'] ->
        case skip_string(text, index + 1, :binary.at(text, index)) do
          {:ok, next_index} -> strip_comments(text, next_index, chunk_start, chunks)
          {:error, _reason, _detail} -> {:error, :invalid_declaration}
        end

      true ->
        strip_comments(text, index + 1, chunk_start, chunks)
    end
  end

  defp scan_items(css, index, source_order, frames_rev, rejects_rev, context \\ nil) do
    case skip_trivia(css, index) do
      {:error, _reason, _detail} ->
        {:error, :malformed_framing}

      {:ok, index} when index >= byte_size(css) ->
        {:ok, Enum.reverse(frames_rev), Enum.reverse(rejects_rev), source_order}

      {:ok, index} ->
        case read_item(css, index) do
          {:error, _reason, _detail} ->
            {:error, :malformed_framing}

          {:ok, item} ->
            {:ok, frames, rejects, next_order} = parse_item(item, source_order, context)
            frames_rev = Enum.reduce(frames, frames_rev, &[&1 | &2])
            rejects_rev = Enum.reduce(rejects, rejects_rev, &[&1 | &2])

            scan_items(
              css,
              item.next_index,
              next_order,
              frames_rev,
              rejects_rev,
              context
            )
        end
    end
  end

  defp parse_item(%{kind: :statement} = item, source_order, context) do
    reason =
      if String.starts_with?(String.trim(item.prelude), "@"),
        do: :unsupported_at_rule,
        else: :malformed_framing

    {:ok, [], [reject_item(item, reason, source_order, context)], source_order + 1}
  end

  defp parse_item(%{kind: :block} = block, source_order, nil) do
    parse_top_level_block(block, source_order)
  end

  defp parse_item(%{kind: :block} = block, source_order, context) do
    parse_media_child_block(block, source_order, context)
  end

  defp parse_top_level_block(%{prelude: prelude} = block, source_order) do
    prelude = String.trim(prelude)

    cond do
      String.match?(prelude, ~r/\A@media(?:\s|$)/i) ->
        parse_media_block(%{block | prelude: prelude}, source_order)

      String.starts_with?(prelude, "@") ->
        {:ok, [], [reject_item(block, :unsupported_at_rule, source_order, nil)], source_order + 1}

      block.nested? ->
        {:ok, [], [reject_item(block, :nested_construct, source_order, nil)], source_order + 1}

      prelude == "" ->
        {:ok, [], [reject_item(block, :malformed_framing, source_order, nil)], source_order + 1}

      true ->
        case parse_declarations(block.body) do
          {:ok, declarations} ->
            frame = frame(block, prelude, declarations, nil, nil, source_order, nil)

            {:ok, [frame], [], source_order + 1}

          {:error, reason} ->
            {:ok, [], [reject_item(block, reason, source_order, nil)], source_order + 1}
        end
    end
  end

  defp parse_media_block(block, source_order) do
    case parse_media_bounds(block.prelude) do
      {:ok, min_width, max_width} ->
        context = %{container_raw: block.raw, min_width: min_width, max_width: max_width}

        case scan_items(block.body, 0, source_order, [], [], context) do
          {:ok, [], [], _next_order} ->
            {:ok, [], [reject_item(block, :malformed_framing, source_order, nil)],
             source_order + 1}

          {:ok, frames, rejects, next_order} ->
            {:ok, frames, rejects, next_order}

          {:error, _reason} ->
            {:ok, [], [reject_item(block, :malformed_framing, source_order, nil)],
             source_order + 1}
        end

      {:error, reason} ->
        {:ok, [], [reject_item(block, reason, source_order, nil)], source_order + 1}
    end
  end

  defp parse_media_child_block(%{prelude: prelude} = block, source_order, context) do
    selector = String.trim(prelude)

    cond do
      String.starts_with?(selector, "@") ->
        {:ok, [], [reject_item(block, :unsupported_at_rule, source_order, context)],
         source_order + 1}

      block.nested? ->
        {:ok, [], [reject_item(block, :nested_construct, source_order, context)],
         source_order + 1}

      selector == "" ->
        {:ok, [], [reject_item(block, :malformed_framing, source_order, context)],
         source_order + 1}

      true ->
        case parse_declarations(block.body) do
          {:ok, declarations} ->
            frame =
              frame(
                block,
                selector,
                declarations,
                context.min_width,
                context.max_width,
                source_order,
                context.container_raw
              )

            {:ok, [frame], [], source_order + 1}

          {:error, reason} ->
            {:ok, [], [reject_item(block, reason, source_order, context)], source_order + 1}
        end
    end
  end

  defp reject_item(item, reason, source_order, nil) do
    %{raw: item.raw, reason: reason, source_order: source_order}
  end

  defp reject_item(item, reason, source_order, context) do
    %{
      raw: item.raw,
      reason: reason,
      source_order: source_order,
      min_width: context.min_width,
      max_width: context.max_width,
      container_raw: context.container_raw
    }
  end

  defp frame(block, selector, declarations, min_width, max_width, source_order, container_raw) do
    %{
      raw: block.raw,
      container_raw: container_raw,
      selector: selector,
      body: block.body,
      declarations: declarations,
      min_width: min_width,
      max_width: max_width,
      source_order: source_order
    }
  end

  defp parse_media_bounds(prelude) do
    case Regex.run(~r/\A@media\s+(.+)\z/i, prelude, capture: :all_but_first) do
      [query] -> parse_media_query(String.trim(query))
      _ -> {:error, :unsupported_media_condition}
    end
  end

  defp parse_media_query(query) do
    min_pattern =
      ~r/\A\(\s*min-width\s*:\s*([+-]?(?:\d+(?:\.\d+)?|\.\d+))\s*px\s*\)\z/i

    max_pattern =
      ~r/\A\(\s*max-width\s*:\s*([+-]?(?:\d+(?:\.\d+)?|\.\d+))\s*px\s*\)\z/i

    range_pattern =
      ~r/\A\(\s*min-width\s*:\s*([+-]?(?:\d+(?:\.\d+)?|\.\d+))\s*px\s*\)\s+and\s+\(\s*max-width\s*:\s*([+-]?(?:\d+(?:\.\d+)?|\.\d+))\s*px\s*\)\z/i

    case Regex.run(range_pattern, query, capture: :all_but_first) do
      [min_text, max_text] ->
        with {:ok, min_width} <- parse_width(min_text),
             {:ok, max_width} <- parse_width(max_text),
             true <- min_width <= max_width do
          {:ok, min_width, max_width}
        else
          _ -> {:error, :invalid_viewport}
        end

      _ ->
        parse_single_bound(query, min_pattern, max_pattern)
    end
  end

  defp parse_single_bound(query, min_pattern, max_pattern) do
    case Regex.run(min_pattern, query, capture: :all_but_first) do
      [min_text] ->
        case parse_width(min_text) do
          {:ok, min_width} -> {:ok, min_width, nil}
          {:error, _reason} -> {:error, :invalid_viewport}
        end

      _ ->
        case Regex.run(max_pattern, query, capture: :all_but_first) do
          [max_text] ->
            case parse_width(max_text) do
              {:ok, max_width} -> {:ok, nil, max_width}
              {:error, _reason} -> {:error, :invalid_viewport}
            end

          _ ->
            {:error, :unsupported_media_condition}
        end
    end
  end

  defp parse_width(text) do
    case Float.parse(text) do
      {width, ""} when width >= 0 and width <= @max_finite_float -> {:ok, width}
      _ -> {:error, :invalid_viewport}
    end
  end

  defp scan_flat_blocks(css, index, blocks_rev) do
    case skip_trivia(css, index) do
      {:error, reason, detail} ->
        {:error, reason, detail}

      {:ok, index} when index >= byte_size(css) ->
        {:ok, Enum.reverse(blocks_rev)}

      {:ok, index} ->
        case read_block(css, index) do
          {:error, reason, detail} ->
            {:error, reason, detail}

          {:ok, %{nested?: true}} ->
            {:error, :nested_block, index}

          {:ok, block} ->
            selector = String.trim(block.prelude)

            if selector == "" do
              {:error, :framing_ambiguous, index}
            else
              flat_block = %{
                selector: selector,
                body: block.body,
                raw: block.raw
              }

              scan_flat_blocks(css, block.next_index, [flat_block | blocks_rev])
            end
        end
    end
  end

  defp scan_flat_blocks_legacy(css, index, blocks) do
    case skip_trivia_legacy(css, index) do
      {:error, _reason, _detail} = error ->
        error

      {:ok, index} ->
        cond do
          index >= byte_size(css) ->
            {:ok, Enum.reverse(blocks)}

          :binary.at(css, index) == ?} ->
            {:error, :unmatched_closing_brace, index}

          true ->
            case read_flat_block_legacy(css, index) do
              {:ok, frame, next_index} ->
                scan_flat_blocks_legacy(css, next_index, [frame | blocks])

              {:error, _reason, _detail} = error ->
                error
            end
        end
    end
  end

  defp read_flat_block_legacy(blob, index) do
    selector_start = index
    {selector_end, index} = read_until_legacy(blob, index, ?{)

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

        case read_balanced_body_legacy(blob, body_start, 1) do
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

  defp read_balanced_body_legacy(blob, index, depth) do
    if index >= byte_size(blob) do
      {:error, :missing_closing_brace, index}
    else
      case :binary.at(blob, index) do
        ?{ ->
          if depth >= 1 do
            {:error, :nested_block, index}
          else
            read_balanced_body_legacy(blob, index + 1, depth + 1)
          end

        ?} ->
          next_depth = depth - 1

          if next_depth == 0 do
            {:ok, index, index}
          else
            read_balanced_body_legacy(blob, index + 1, next_depth)
          end

        _ ->
          read_balanced_body_legacy(blob, index + 1, depth)
      end
    end
  end

  defp read_until_legacy(blob, index, char) do
    if index >= byte_size(blob) do
      {index, index}
    else
      case :binary.at(blob, index) do
        ^char ->
          {index, index}

        _ ->
          read_until_legacy(blob, index + 1, char)
      end
    end
  end

  defp skip_trivia_legacy(blob, index) do
    cond do
      index >= byte_size(blob) ->
        {:ok, index}

      index + 1 < byte_size(blob) and :binary.part(blob, index, 2) == "/*" ->
        comment_start = index
        comment_body_start = index + 2

        case :binary.match(blob, "*/", [
               {:scope, {comment_body_start, byte_size(blob) - comment_body_start}}
             ]) do
          {close_start, _close_length} -> skip_trivia_legacy(blob, close_start + 2)
          :nomatch -> {:error, :unterminated_comment, comment_start}
        end

      :binary.at(blob, index) in [?\s, ?\n, ?\r, ?\t] ->
        skip_trivia_legacy(blob, index + 1)

      true ->
        {:ok, index}
    end
  end

  defp read_block(css, start_index) do
    case read_item(css, start_index) do
      {:ok, %{kind: :block} = block} -> {:ok, block}
      {:ok, _statement} -> {:error, :statement_item, start_index}
      {:error, _reason, _detail} = error -> error
    end
  end

  defp read_item(css, start_index) do
    case read_item_boundary(css, start_index, 0, 0) do
      {:ok, :statement, end_index} ->
        raw = binary_part(css, start_index, end_index - start_index + 1)

        {:ok,
         %{
           kind: :statement,
           prelude: binary_part(css, start_index, end_index - start_index),
           raw: raw,
           next_index: end_index + 1
         }}

      {:ok, :block, open_index} ->
        with {:ok, close_index, nested?} <- read_block_end(css, open_index + 1, 1, false) do
          {:ok,
           %{
             kind: :block,
             prelude: binary_part(css, start_index, open_index - start_index),
             body: binary_part(css, open_index + 1, close_index - open_index - 1),
             raw: binary_part(css, start_index, close_index - start_index + 1),
             next_index: close_index + 1,
             nested?: nested?
           }}
        end

      {:error, _reason, _detail} = error ->
        error
    end
  end

  defp read_item_boundary(css, index, _paren_depth, _bracket_depth)
       when index >= byte_size(css),
       do: {:error, :orphan_text, index}

  defp read_item_boundary(css, index, paren_depth, bracket_depth) do
    cond do
      comment_start?(css, index) ->
        with {:ok, next_index} <- skip_comment(css, index),
             do: read_item_boundary(css, next_index, paren_depth, bracket_depth)

      :binary.at(css, index) in [?\", ?'] ->
        with {:ok, next_index} <- skip_string(css, index + 1, :binary.at(css, index)),
             do: read_item_boundary(css, next_index, paren_depth, bracket_depth)

      true ->
        read_item_boundary_char(css, index, paren_depth, bracket_depth)
    end
  end

  defp read_item_boundary_char(css, index, paren_depth, bracket_depth) do
    case :binary.at(css, index) do
      ?( ->
        read_item_boundary(css, index + 1, paren_depth + 1, bracket_depth)

      ?) when paren_depth > 0 ->
        read_item_boundary(css, index + 1, paren_depth - 1, bracket_depth)

      ?) ->
        {:error, :unbalanced_parenthesis, index}

      ?[ ->
        read_item_boundary(css, index + 1, paren_depth, bracket_depth + 1)

      ?] when bracket_depth > 0 ->
        read_item_boundary(css, index + 1, paren_depth, bracket_depth - 1)

      ?] ->
        {:error, :unbalanced_bracket, index}

      ?; when paren_depth == 0 and bracket_depth == 0 ->
        {:ok, :statement, index}

      ?{ when paren_depth == 0 and bracket_depth == 0 ->
        {:ok, :block, index}

      ?} when paren_depth == 0 and bracket_depth == 0 ->
        {:error, :unmatched_closing_brace, index}

      _ ->
        read_item_boundary(css, index + 1, paren_depth, bracket_depth)
    end
  end

  defp read_block_end(css, index, _depth, _nested?) when index >= byte_size(css),
    do: {:error, :missing_closing_brace, index}

  defp read_block_end(css, index, depth, nested?) do
    case :binary.at(css, index) do
      ?/ ->
        if index + 1 < byte_size(css) and :binary.at(css, index + 1) == ?* do
          with {:ok, next_index} <- skip_comment(css, index),
               do: read_block_end(css, next_index, depth, nested?)
        else
          read_block_end(css, index + 1, depth, nested?)
        end

      quote when quote in [?', ?"] ->
        with {:ok, next_index} <- skip_string(css, index + 1, quote),
             do: read_block_end(css, next_index, depth, nested?)

      ?{ ->
        read_block_end(css, index + 1, depth + 1, true)

      ?} when depth == 1 ->
        {:ok, index, nested?}

      ?} ->
        read_block_end(css, index + 1, depth - 1, nested?)

      _ ->
        read_block_end(css, index + 1, depth, nested?)
    end
  end

  defp skip_trivia(css, index) when index >= byte_size(css), do: {:ok, index}

  defp skip_trivia(css, index) do
    cond do
      index + 1 < byte_size(css) and :binary.part(css, index, 2) == "/*" ->
        case skip_comment(css, index) do
          {:ok, next_index} -> skip_trivia(css, next_index)
          {:error, reason, detail} -> {:error, reason, detail}
        end

      :binary.at(css, index) in [?\s, ?\n, ?\r, ?\t, ?\f] ->
        skip_trivia(css, index + 1)

      true ->
        {:ok, index}
    end
  end

  defp comment_start?(css, index) when index + 1 < byte_size(css),
    do: :binary.part(css, index, 2) == "/*"

  defp comment_start?(_css, _index), do: false

  defp skip_comment(css, index) do
    comment_body_start = index + 2

    case :binary.match(css, "*/", [
           {:scope, {comment_body_start, byte_size(css) - comment_body_start}}
         ]) do
      {close_start, _close_length} -> {:ok, close_start + 2}
      :nomatch -> {:error, :unterminated_comment, index}
    end
  end

  defp skip_string(css, index, _quote) when index >= byte_size(css),
    do: {:error, :unterminated_string, index}

  defp skip_string(css, index, quote) do
    case :binary.at(css, index) do
      ?\\ when index + 1 < byte_size(css) -> skip_string(css, index + 2, quote)
      ^quote -> {:ok, index + 1}
      _ -> skip_string(css, index + 1, quote)
    end
  end
end
