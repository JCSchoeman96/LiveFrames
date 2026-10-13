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
    body
    |> String.split(";")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.reduce_while({:ok, %{}}, fn declaration, {:ok, declarations} ->
      case String.split(declaration, ":", parts: 2) do
        [property, value] ->
          property = property |> String.trim() |> String.downcase()
          value = String.trim(value)

          cond do
            not Regex.match?(@property_name, property) or value == "" ->
              {:halt, {:error, :invalid_declaration}}

            Map.has_key?(declarations, property) ->
              {:halt, {:error, :duplicate_property}}

            true ->
              {:cont, {:ok, Map.put(declarations, property, value)}}
          end

        _ ->
          {:halt, {:error, :invalid_declaration}}
      end
    end)
    |> case do
      {:ok, declarations} when map_size(declarations) > 0 -> {:ok, declarations}
      {:ok, _} -> {:error, :invalid_declaration}
      {:error, reason} -> {:error, reason}
    end
  end

  defp scan_items(css, index, source_order, frames_rev, rejects_rev) do
    case skip_trivia(css, index) do
      {:error, _reason, _detail} ->
        {:error, :malformed_framing}

      {:ok, index} when index >= byte_size(css) ->
        {:ok, Enum.reverse(frames_rev), Enum.reverse(rejects_rev), source_order}

      {:ok, index} ->
        case read_block(css, index) do
          {:error, _reason, _detail} ->
            {:error, :malformed_framing}

          {:ok, block} ->
            case parse_block(block, source_order) do
              {:frames, frames, next_order} ->
                frames_rev = Enum.reduce(frames, frames_rev, &[&1 | &2])

                scan_items(
                  css,
                  block.next_index,
                  next_order,
                  frames_rev,
                  rejects_rev
                )

              {:reject, reason, next_order} ->
                reject = %{raw: block.raw, reason: reason, source_order: source_order}

                scan_items(
                  css,
                  block.next_index,
                  next_order,
                  frames_rev,
                  [reject | rejects_rev]
                )
            end
        end
    end
  end

  defp parse_block(%{prelude: prelude} = block, source_order) do
    prelude = String.trim(prelude)

    cond do
      String.match?(prelude, ~r/\A@media(?:\s|$)/i) ->
        parse_media_block(%{block | prelude: prelude}, source_order)

      String.starts_with?(prelude, "@") ->
        {:reject, :unsupported_at_rule, source_order + 1}

      block.nested? ->
        {:reject, :nested_construct, source_order + 1}

      prelude == "" ->
        {:reject, :malformed_framing, source_order + 1}

      true ->
        case parse_declarations(block.body) do
          {:ok, declarations} ->
            frame =
              frame(block, prelude, declarations, nil, nil, source_order, block.raw)

            {:frames, [frame], source_order + 1}

          {:error, reason} ->
            {:reject, reason, source_order + 1}
        end
    end
  end

  defp parse_media_block(block, source_order) do
    case parse_media_bounds(block.prelude) do
      {:ok, min_width, max_width} ->
        case parse_media_rules(block.body, block.raw, min_width, max_width, source_order) do
          {:ok, []} ->
            {:reject, :malformed_framing, source_order + 1}

          {:ok, frames} ->
            {:frames, frames, source_order + length(frames)}

          {:error, reason} ->
            {:reject, reason, source_order + 1}
        end

      {:error, reason} ->
        {:reject, reason, source_order + 1}
    end
  end

  defp parse_media_rules(body, media_raw, min_width, max_width, source_order) do
    case parse_flat_blocks(body) do
      {:ok, []} ->
        {:ok, []}

      {:ok, rules} ->
        rules
        |> Enum.with_index(source_order)
        |> Enum.reduce_while({:ok, []}, fn {rule, order}, {:ok, frames} ->
          case parse_declarations(rule.body) do
            {:ok, declarations} ->
              frame =
                frame(
                  %{rule | raw: media_raw},
                  rule.selector,
                  declarations,
                  min_width,
                  max_width,
                  order,
                  rule.raw
                )

              {:cont, {:ok, [frame | frames]}}

            {:error, reason} ->
              {:halt, {:error, reason}}
          end
        end)
        |> case do
          {:ok, frames} -> {:ok, Enum.reverse(frames)}
          {:error, reason} -> {:error, reason}
        end

      {:error, :nested_block, _detail} ->
        {:error, :nested_construct}

      {:error, _reason, _detail} ->
        {:error, :malformed_framing}
    end
  end

  defp frame(block, selector, declarations, min_width, max_width, source_order, rule_raw) do
    %{
      raw: block.raw,
      rule_raw: rule_raw,
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
    with {:ok, open_index} <- read_until_open(css, start_index),
         {:ok, close_index, nested?} <- read_block_end(css, open_index + 1, 1, false) do
      block = %{
        prelude: binary_part(css, start_index, open_index - start_index),
        body: binary_part(css, open_index + 1, close_index - open_index - 1),
        raw: binary_part(css, start_index, close_index - start_index + 1),
        next_index: close_index + 1,
        nested?: nested?
      }

      {:ok, block}
    end
  end

  defp read_until_open(css, index) when index >= byte_size(css),
    do: {:error, :orphan_text, index}

  defp read_until_open(css, index) do
    case :binary.at(css, index) do
      ?{ ->
        {:ok, index}

      ?} ->
        {:error, :unmatched_closing_brace, index}

      quote when quote in [?', ?"] ->
        with {:ok, next_index} <- skip_string(css, index + 1, quote),
             do: read_until_open(css, next_index)

      ?/ ->
        if index + 1 < byte_size(css) and :binary.at(css, index + 1) == ?* do
          with {:ok, next_index} <- skip_comment(css, index),
               do: read_until_open(css, next_index)
        else
          read_until_open(css, index + 1)
        end

      _ ->
        read_until_open(css, index + 1)
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
