defmodule LiveFrames.Adapters.Bricks.PhpSemanticRecognizer do
  @moduledoc """
  Recognizes one bounded, inert Bricks PHP source shape.

  The lexer and parser accept only the current-entity full-description flow.
  They never evaluate source bytes or return source-derived structures.
  """

  @max_source_bytes 16_384
  @max_tokens 2_048
  @max_nesting_depth 16
  @max_variables 32
  @max_calls 8
  @max_analysis_steps 128
  @max_statements 16
  @max_control_flow_nodes 1
  @product_acquisition_edges 2
  @description_assignment_edges 2
  @guarded_output_edges 2

  @unsafe_identifiers ~w(
    eval include include_once require require_once exec shell_exec system passthru
    proc_open popen file_get_contents file_put_contents fopen fwrite unlink
    curl_init wp_remote_get wp_remote_post mysqli_query pg_query
  )

  @type semantic :: :current_entity_full_description
  @type reason ::
          :parse_failed
          | :unsafe
          | :semantic_unsupported
          | :semantic_ambiguous
          | :resource_limit_exceeded

  @spec recognize(binary()) :: {:ok, semantic()} | {:error, reason()}
  def recognize(source) when is_binary(source) do
    with :ok <- check_source_size(source),
         :ok <- check_tag_context(source),
         {:ok, tokens, stats} <- lex(source),
         :ok <- check_resource_limits(tokens, stats),
         :ok <- reject_unsafe_identifiers(tokens),
         {:ok, semantic} <- parse(tokens) do
      {:ok, semantic}
    end
  end

  def recognize(_source), do: {:error, :parse_failed}

  defp check_source_size(source) do
    if byte_size(source) <= @max_source_bytes,
      do: :ok,
      else: {:error, :resource_limit_exceeded}
  end

  defp check_tag_context(source) do
    if contains_marker?(source, "<?php") or contains_marker?(source, "?>") do
      check_tag_context(source, :outside)
    else
      :ok
    end
  end

  defp check_tag_context(<<>>, _mode), do: :ok

  defp check_tag_context(source, :outside) do
    case {find_marker(source, "<?php"), find_marker(source, "?>")} do
      {{:ok, open_tag}, {:ok, close_tag}} when close_tag < open_tag ->
        {:error, :parse_failed}

      {{:ok, open_tag}, _close_tag} ->
        prefix = binary_part(source, 0, open_tag)
        tail = binary_part(source, open_tag + 5, byte_size(source) - open_tag - 5)

        if ascii_whitespace?(prefix),
          do: check_tag_context(tail, :inside),
          else: {:error, :parse_failed}

      {:error, {:ok, _close_tag}} ->
        {:error, :parse_failed}

      {:error, :error} ->
        if ascii_whitespace?(source), do: :ok, else: {:error, :parse_failed}
    end
  end

  defp check_tag_context(source, :inside) do
    case find_marker(source, "?>") do
      {:ok, close_tag} ->
        tail = binary_part(source, close_tag + 2, byte_size(source) - close_tag - 2)
        check_tag_context(tail, :outside)

      :error ->
        :ok
    end
  end

  defp contains_marker?(binary, marker), do: find_marker(binary, marker) != :error

  defp ascii_whitespace?(<<>>), do: true

  defp ascii_whitespace?(<<char, rest::binary>>) when char in [32, 9, 10, 11, 12, 13],
    do: ascii_whitespace?(rest)

  defp ascii_whitespace?(_binary), do: false

  defp lex(source), do: lex(source, [], MapSet.new(), 0, 0, 0, 0)

  defp lex(<<>>, tokens, variables, max_depth, depth, _calls, control_flow) do
    if depth != 0 do
      {:error, :parse_failed}
    else
      tokens = Enum.reverse(tokens)

      {:ok, tokens,
       %{
         variables: MapSet.size(variables),
         max_depth: max_depth,
         calls: call_count(tokens),
         control_flow: control_flow,
         statements: statement_count(tokens)
       }}
    end
  end

  defp lex(<<char, rest::binary>>, tokens, variables, max_depth, depth, calls, flow)
       when char in [32, 9, 10, 11, 12, 13],
       do: lex(rest, tokens, variables, max_depth, depth, calls, flow)

  defp lex(<<"<?php", rest::binary>>, tokens, variables, max_depth, depth, calls, flow),
    do: push(:open_tag, rest, tokens, variables, max_depth, depth, calls, flow)

  defp lex(<<"?>", rest::binary>>, tokens, variables, max_depth, depth, calls, flow),
    do: push(:close_tag, rest, tokens, variables, max_depth, depth, calls, flow)

  defp lex(<<"//", rest::binary>>, tokens, variables, max_depth, depth, calls, flow),
    do: lex(skip_line(rest), tokens, variables, max_depth, depth, calls, flow)

  defp lex(<<"#[", _rest::binary>>, _tokens, _variables, _max_depth, _depth, _calls, _flow),
    do: {:error, :parse_failed}

  defp lex(<<"#", rest::binary>>, tokens, variables, max_depth, depth, calls, flow),
    do: lex(skip_line(rest), tokens, variables, max_depth, depth, calls, flow)

  defp lex(<<"/*", rest::binary>>, tokens, variables, max_depth, depth, calls, flow) do
    case :binary.match(rest, "*/") do
      {index, 2} ->
        <<_comment::binary-size(index), _terminator::binary-size(2), tail::binary>> = rest
        lex(tail, tokens, variables, max_depth, depth, calls, flow)

      :nomatch ->
        {:error, :parse_failed}
    end
  end

  defp lex(<<"$", rest::binary>>, tokens, variables, max_depth, depth, calls, flow) do
    case rest do
      <<char, _tail::binary>> when char in ?A..?Z or char in ?a..?z or char == ?_ ->
        {name, tail} = take_identifier(rest)

        push(
          {:variable, name},
          tail,
          tokens,
          MapSet.put(variables, name),
          max_depth,
          depth,
          calls,
          flow
        )

      _invalid_start ->
        {:error, :parse_failed}
    end
  end

  defp lex(<<char, rest::binary>>, tokens, variables, max_depth, depth, calls, flow)
       when char in ?0..?9 do
    push(:literal, rest, tokens, variables, max_depth, depth, calls, flow)
  end

  defp lex(<<char, _rest::binary>> = source, tokens, variables, max_depth, depth, calls, flow)
       when char in ?A..?Z or char in ?a..?z or char == ?_ do
    {name, tail} = take_identifier(source)
    call_count = if starts_with_open_paren?(tail), do: calls + 1, else: calls
    flow_count = if name == "if", do: flow + 1, else: flow
    push({:identifier, name}, tail, tokens, variables, max_depth, depth, call_count, flow_count)
  end

  defp lex(<<char, rest::binary>>, tokens, variables, max_depth, depth, calls, flow)
       when char in [?=, ?(, ?), ?{, ?}, ?;, ?-, ?>] do
    token = if char == ?- and starts_with_greater?(rest), do: :arrow, else: <<char>>
    tail = if token == :arrow, do: binary_part(rest, 1, byte_size(rest) - 1), else: rest
    new_depth = depth + if(char in [?(, ?{], do: 1, else: if(char in [?), ?}], do: -1, else: 0))

    if new_depth < 0 do
      {:error, :parse_failed}
    else
      push(
        token,
        tail,
        tokens,
        variables,
        max(max_depth, new_depth),
        new_depth,
        calls,
        flow
      )
    end
  end

  defp lex(_source, _tokens, _variables, _max_depth, _depth, _calls, _flow),
    do: {:error, :parse_failed}

  defp push(token, rest, tokens, variables, max_depth, depth, calls, flow) do
    if length(tokens) >= @max_tokens do
      {:error, :resource_limit_exceeded}
    else
      lex(rest, [token | tokens], variables, max_depth, depth, calls, flow)
    end
  end

  defp skip_line(binary) do
    case {find_marker(binary, "\n"), find_marker(binary, "?>")} do
      {{:ok, newline}, {:ok, close_tag}} when newline < close_tag ->
        binary_part(binary, newline + 1, byte_size(binary) - newline - 1)

      {_newline, {:ok, close_tag}} ->
        binary_part(binary, close_tag, byte_size(binary) - close_tag)

      {{:ok, newline}, :error} ->
        binary_part(binary, newline + 1, byte_size(binary) - newline - 1)

      {:error, :error} ->
        <<>>
    end
  end

  defp find_marker(binary, marker) do
    case :binary.match(binary, marker) do
      {index, _size} -> {:ok, index}
      :nomatch -> :error
    end
  end

  defp take_identifier(binary), do: take_identifier(binary, binary, 0)

  defp take_identifier(<<char, rest::binary>>, original, size)
       when char in ?A..?Z or char in ?a..?z or char in ?0..?9 or char == ?_ do
    take_identifier(rest, original, size + 1)
  end

  defp take_identifier(rest, original, size),
    do: {binary_part(original, 0, size), rest}

  defp starts_with_open_paren?(<<"(", _::binary>>), do: true
  defp starts_with_open_paren?(_binary), do: false
  defp starts_with_greater?(<<">", _::binary>>), do: true
  defp starts_with_greater?(_binary), do: false

  defp check_resource_limits(tokens, stats) do
    if length(tokens) > @max_tokens or stats.variables > @max_variables or
         stats.calls > @max_calls or stats.max_depth > @max_nesting_depth or
         stats.statements > @max_statements or
         stats.control_flow > @max_control_flow_nodes do
      {:error, :resource_limit_exceeded}
    else
      :ok
    end
  end

  defp statement_count(tokens) do
    Enum.count(tokens, &(&1 == ";" or &1 == {:identifier, "if"}))
  end

  defp call_count(tokens) do
    tokens
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.count(fn
      [{:identifier, "if"}, "("] -> false
      [{:identifier, _name}, "("] -> true
      [{:variable, _name}, "("] -> true
      _other -> false
    end)
  end

  defp reject_unsafe_identifiers(tokens) do
    if Enum.any?(tokens, fn
         {:identifier, name} -> name in @unsafe_identifiers
         _ -> false
       end) do
      {:error, :unsafe}
    else
      :ok
    end
  end

  defp parse(tokens) do
    tokens = maybe_drop(tokens, :open_tag)

    # The accepted flow visits six edges: current ID to product, product result
    # to alias, product alias to description receiver, description result to
    # alias, product alias to guard, and description alias to echo.
    with {:ok, product, tokens, product_edges} <- parse_product_assignment(tokens),
         {:ok, description, tokens, description_edges} <-
           parse_description_assignment(tokens, product),
         :ok <- distinct_aliases(product, description),
         {:ok, tokens, output_edges} <- parse_guarded_output(tokens, product, description),
         :ok <- check_analysis_steps(product_edges + description_edges + output_edges),
         [] <- maybe_drop(tokens, :close_tag) do
      {:ok, :current_entity_full_description}
    else
      {:error, reason} -> {:error, reason}
      _other -> {:error, classify_unmatched(tokens)}
    end
  end

  defp parse_product_assignment([
         {:variable, product},
         "=",
         {:identifier, "wc_get_product"},
         "(",
         {:identifier, "get_the_ID"},
         "(",
         ")",
         ")",
         ";"
         | rest
       ]),
       do: {:ok, product, rest, @product_acquisition_edges}

  defp parse_product_assignment(tokens), do: {:error, classify_unmatched(tokens)}

  defp parse_description_assignment(
         [
           {:variable, description},
           "=",
           {:variable, product},
           :arrow,
           {:identifier, "get_description"},
           "(",
           ")",
           ";"
           | rest
         ],
         product
       ),
       do: {:ok, description, rest, @description_assignment_edges}

  defp parse_description_assignment(tokens, _product),
    do: {:error, classify_unmatched(tokens)}

  defp distinct_aliases(product, description) when product != description, do: :ok
  defp distinct_aliases(_product, _description), do: {:error, :semantic_ambiguous}

  defp parse_guarded_output(
         [
           {:identifier, "if"},
           "(",
           {:variable, product},
           ")",
           "{",
           {:identifier, "echo"},
           {:variable, description},
           ";",
           "}"
           | rest
         ],
         product,
         description
       ),
       do: {:ok, rest, @guarded_output_edges}

  defp parse_guarded_output(tokens, _product, _description),
    do: {:error, classify_unmatched(tokens)}

  defp check_analysis_steps(steps) when steps <= @max_analysis_steps, do: :ok
  defp check_analysis_steps(_steps), do: {:error, :resource_limit_exceeded}

  defp maybe_drop([token | rest], token), do: rest
  defp maybe_drop(tokens, _token), do: tokens

  defp classify_unmatched(tokens) do
    variable_count =
      tokens
      |> Enum.flat_map(fn
        {:variable, name} -> [name]
        _ -> []
      end)
      |> Enum.uniq()
      |> length()

    cond do
      variable_count > 2 ->
        :semantic_ambiguous

      Enum.any?(tokens, &(&1 == {:identifier, "else"} or &1 == {:identifier, "elseif"})) ->
        :semantic_unsupported

      Enum.any?(tokens, &(&1 == {:identifier, "echo"} or &1 == {:identifier, "print"})) ->
        :semantic_unsupported

      true ->
        :parse_failed
    end
  end
end
