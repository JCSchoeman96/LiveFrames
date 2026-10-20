defmodule LiveFrames.Adapters.Bricks.CompoundCssValue do
  @moduledoc false

  @max_bytes 4096
  @max_argument_bytes 2048
  @max_tokens 32
  @max_refs 16
  @local_var ~r/var\([\x20\t\r\n\f]*(--[A-Za-z0-9_-]+)[\x20\t\r\n\f]*\)/
  @dimension ~r/^-?\d+(?:\.\d+)?(?:px|rem|em|vh|vw|fr|deg)$/

  defmodule Occurrence do
    @moduledoc false
    defstruct [:occurrence_index, :local_name, :slot_grammar]

    @type t :: %__MODULE__{
            occurrence_index: non_neg_integer(),
            local_name: binary(),
            slot_grammar:
              :gradient_stop_atom
              | :calc_operand
              | :juxtaposition_left_operand
              | :juxtaposition_right_operand
          }
  end

  defmodule Parsed do
    @moduledoc false
    defstruct [:production, :function_name, :pieces, :occurrences]

    @type t :: %__MODULE__{
            production: :function_call | :multi_token_value | :var_reference_with_operation,
            function_name: :linear_gradient | :calc | nil,
            pieces: [binary() | {:occurrence, non_neg_integer()}],
            occurrences: [Occurrence.t()]
          }
  end

  @spec parse(binary()) ::
          {:ok, Parsed.t()}
          | :no_match
          | {:error, :unsupported_grammar | :resource_limit_exceeded}
  def parse(value) when is_binary(value) do
    value = String.trim(value, " \t\r\n\f")

    cond do
      byte_size(value) > @max_bytes -> {:error, :resource_limit_exceeded}
      function_attempt?(value) -> parse_function(value)
      true -> parse_non_function(value)
    end
  end

  def parse(_), do: :no_match

  @spec occurrences(Parsed.t()) :: [Occurrence.t()]
  def occurrences(%Parsed{occurrences: items}), do: items

  @spec reconstruct(Parsed.t(), %{non_neg_integer() => binary()}) ::
          {:ok, binary()}
          | {:error,
             :occurrence_terminal_mismatch
             | :invalid_slot_terminal
             | :resolved_grammar_mismatch
             | :resource_limit_exceeded}
  def reconstruct(%Parsed{} = parsed, terminals) when is_map(terminals) do
    indices = MapSet.new(Enum.map(parsed.occurrences, & &1.occurrence_index))

    if MapSet.new(Map.keys(terminals)) != indices do
      {:error, :occurrence_terminal_mismatch}
    else
      with :ok <- validate_terminals(parsed.occurrences, terminals),
           {:ok, value} <- substitute(parsed.pieces, terminals),
           :ok <- reject_remaining_reference(value) do
        cond do
          byte_size(value) > @max_bytes ->
            {:error, :resource_limit_exceeded}

          function_argument_bytes(parsed, value) > @max_argument_bytes ->
            {:error, :resource_limit_exceeded}

          resolved_valid?(parsed, value) ->
            {:ok, value}

          true ->
            {:error, :resolved_grammar_mismatch}
        end
      else
        {:error, _} = error -> error
        _ -> {:error, :resolved_grammar_mismatch}
      end
    end
  end

  defp function_attempt?(value), do: Regex.match?(~r/^(?:linear-gradient|calc)\(/i, value)

  defp parse_function(value) do
    case Regex.run(~r/^([A-Za-z-]+)\((.*)\)$/s, value, capture: :all_but_first) do
      [name, body] when byte_size(body) <= @max_argument_bytes ->
        identity = if String.downcase(name) == "calc", do: :calc, else: :linear_gradient

        case identity do
          :calc -> parse_calc(value, body)
          :linear_gradient -> parse_gradient(value, body)
        end

      [_name, _body] ->
        {:error, :resource_limit_exceeded}

      _ ->
        {:error, :unsupported_grammar}
    end
  end

  defp parse_gradient(source, body) do
    case split_top_level_commas(body) do
      [angle | stops] when length(stops) in 1..8 ->
        cond do
          not Regex.match?(~r/^\d+(?:\.\d+)?deg$/, angle) ->
            unsupported()

          true ->
            tokens = Enum.flat_map(stops, &split_ws/1)

            cond do
              Enum.any?(stops, &(length(split_ws(&1)) > 4)) ->
                resource()

              Enum.any?(stops, &(length(split_ws(&1)) == 0)) ->
                unsupported()

              length(tokens) + 1 > @max_tokens ->
                resource()

              true ->
                slots = gradient_vars(source, body)

                if slots == :invalid,
                  do: unsupported(),
                  else: build(:function_call, :linear_gradient, source, slots)
            end
        end

      [_angle | stops] when length(stops) > 8 ->
        resource()

      [_angle] ->
        unsupported()

      _ ->
        unsupported()
    end
  end

  defp parse_calc(source, body) do
    case Regex.run(
           ~r/^[\x20\t\r\n\f]*(var\([\x20\t\r\n\f]*--[A-Za-z0-9_-]+[\x20\t\r\n\f]*\))[\x20\t\r\n\f]*(?:\*[\x20\t\r\n\f]*((?:\d+(?:\.\d+)?|\.\d+)))?[\x20\t\r\n\f]*$/,
           body,
           capture: :all_but_first
         ) do
      [ref] ->
        build(:function_call, :calc, source, [{ref, :calc_operand}])

      [ref, factor] ->
        if positive_finite?(factor),
          do: build(:function_call, :calc, source, [{ref, :calc_operand}]),
          else: unsupported()

      _ ->
        unsupported()
    end
  end

  defp parse_non_function(value) do
    refs = Regex.scan(@local_var, value, capture: :all_but_first)

    cond do
      length(refs) > @max_refs ->
        resource()

      match?([[_], [_]], refs) and
          Regex.match?(
            ~r/^var\([\x20\t\r\n\f]*--[A-Za-z0-9_-]+[\x20\t\r\n\f]*\)[\x20\t\r\n\f]+var\([\x20\t\r\n\f]*--[A-Za-z0-9_-]+[\x20\t\r\n\f]*\)$/,
            value
          ) ->
        names =
          Regex.scan(@local_var, value, return: :index)
          |> Enum.with_index()
          |> Enum.map(fn {[{start, len} | _], index} ->
            {binary_part(value, start, len),
             if(index == 0, do: :juxtaposition_left_operand, else: :juxtaposition_right_operand)}
          end)

        build(:var_reference_with_operation, nil, value, names)

      Regex.match?(
        ~r/^-?\d+(?:\.\d+)?(?:px|rem|em|vh|vw|fr|deg|%)[\x20\t\r\n\f]+-?\d+(?:\.\d+)?(?:px|rem|em|vh|vw|fr|deg|%)$/,
        value
      ) ->
        if length(split_ws(value)) == 2,
          do: build(:multi_token_value, nil, value, []),
          else: :no_match

      true ->
        :no_match
    end
  end

  defp build(production, function_name, source, slot_refs) do
    if length(slot_refs) > @max_refs do
      resource()
    else
      {pieces, occurrences} = make_pieces(source, slot_refs)

      {:ok,
       %Parsed{
         production: production,
         function_name: function_name,
         pieces: pieces,
         occurrences: occurrences
       }}
    end
  end

  defp make_pieces(source, slot_refs) do
    Enum.with_index(slot_refs)
    |> Enum.reduce({source, [], []}, fn {{ref, grammar}, index}, {rest, chunks, occs} ->
      case :binary.match(rest, ref) do
        {at, len} ->
          <<literal::binary-size(at), _::binary-size(len), tail::binary>> = rest

          {tail, chunks ++ [literal, {:occurrence, index}],
           occs ++
             [
               %Occurrence{
                 occurrence_index: index,
                 local_name: extract_name(ref),
                 slot_grammar: grammar
               }
             ]}

        :nomatch ->
          {rest, chunks, occs}
      end
    end)
    |> then(fn {tail, chunks, occs} -> {chunks ++ [tail], occs} end)
  end

  defp gradient_vars(source, body) do
    matches = Regex.scan(@local_var, source, return: :index)

    if balanced_only_vars?(body) and gradient_atoms_valid?(body) do
      Enum.map(matches, fn [{start, len} | _] ->
        {binary_part(source, start, len), :gradient_stop_atom}
      end)
    else
      :invalid
    end
  end

  defp balanced_only_vars?(body) do
    stripped = Regex.replace(@local_var, body, "")
    not String.contains?(stripped, ["'", "\"", "(", ")"])
  end

  defp gradient_atoms_valid?(body) do
    if String.contains?(body, <<0>>) do
      false
    else
      body = Regex.replace(@local_var, body, <<0>>)

      case split_top_level_commas(body) do
        [_angle | stops] ->
          Enum.all?(stops, fn stop -> Enum.all?(split_ws(stop), &valid_gradient_atom?(&1)) end)

        _ ->
          false
      end
    end
  end

  defp valid_gradient_atom?(<<0>>), do: true

  defp valid_gradient_atom?(value),
    do: value == "transparent" or Regex.match?(~r/^\d+(?:\.\d+)?%$/, value)

  defp split_top_level_commas(body) do
    body
    |> String.graphemes()
    |> Enum.reduce({0, [], ""}, fn
      "(", {depth, parts, current} -> {depth + 1, parts, current <> "("}
      ")", {depth, parts, current} -> {max(depth - 1, 0), parts, current <> ")"}
      ",", {0, parts, current} -> {0, [current | parts], ""}
      char, {depth, parts, current} -> {depth, parts, current <> char}
    end)
    |> then(fn {_depth, parts, current} -> Enum.reverse([current | parts]) end)
  end

  defp split_ws(value),
    do: Regex.split(~r/[\x20\t\r\n\f]+/, String.trim(value, " \t\r\n\f"), trim: true)

  defp validate_terminals(occurrences, terminals) do
    if Enum.all?(occurrences, fn occurrence ->
         valid_slot?(occurrence.slot_grammar, terminals[occurrence.occurrence_index])
       end),
       do: :ok,
       else: {:error, :invalid_slot_terminal}
  end

  defp valid_slot?(:gradient_stop_atom, value) when is_binary(value) do
    value == "transparent" or Regex.match?(~r/^\d+(?:\.\d+)?%$/, value) or
      Regex.match?(@dimension, value) or valid_rgb?(value)
  end

  defp valid_slot?(:calc_operand, value) when is_binary(value),
    do:
      Regex.match?(~r/^-?\d+(?:\.\d+)?$/, value) or Regex.match?(@dimension, value) or
        Regex.match?(~r/^-?\d+(?:\.\d+)?%$/, value)

  defp valid_slot?(:juxtaposition_left_operand, value) when is_binary(value),
    do:
      Regex.match?(~r/^(?:\d+(?:\.\d+)?|\.\d+)(?:s|ms)$/, value) and
        finite_nonnegative?(String.replace(value, ~r/(?:s|ms)$/, ""))

  defp valid_slot?(:juxtaposition_right_operand, "ease-in-out"), do: true
  defp valid_slot?(_, _), do: false

  defp valid_rgb?(value) do
    case Regex.run(~r/^(rgb|rgba)\((.*)\)$/i, value, capture: :all_but_first) do
      [name, inside] ->
        case {String.downcase(name), String.split(inside, ",")} do
          {"rgb", [r, g, b]} -> Enum.all?([r, g, b], &channel?/1)
          {"rgba", [r, g, b, a]} -> Enum.all?([r, g, b], &channel?/1) and alpha?(a)
          _ -> false
        end

      _ ->
        false
    end
  end

  defp channel?(value), do: Regex.match?(~r/^\d{1,3}$/, value) and String.to_integer(value) <= 255

  defp alpha?(value) do
    valid_alpha = Regex.match?(~r/^(?:0|1|(?:\d+\.\d+|\.\d+))$/, value)
    number_text = if String.starts_with?(value, "."), do: "0" <> value, else: value

    valid_alpha and
      case Float.parse(number_text) do
        {number, ""} -> number >= 0 and number <= 1 and number == number
        _ -> false
      end
  end

  defp substitute(pieces, terminals) do
    value =
      Enum.map_join(pieces, fn
        {:occurrence, index} -> terminals[index]
        binary -> binary
      end)

    if byte_size(value) <= @max_bytes, do: {:ok, value}, else: {:error, :resource_limit_exceeded}
  end

  defp reject_remaining_reference(value) do
    if String.contains?(String.downcase(value), "var("),
      do: {:error, :resolved_grammar_mismatch},
      else: :ok
  end

  defp function_argument_bytes(%Parsed{function_name: function_name}, value)
       when function_name in [:calc, :linear_gradient] do
    case :binary.match(value, "(") do
      {open, 1} when byte_size(value) > open + 1 -> byte_size(value) - open - 2
      _ -> 0
    end
  end

  defp function_argument_bytes(_parsed, _value), do: 0

  defp resolved_valid?(%Parsed{production: :multi_token_value}, value),
    do:
      Regex.match?(
        ~r/^-?\d+(?:\.\d+)?(?:px|rem|em|vh|vw|fr|deg|%)[\x20\t\r\n\f]+-?\d+(?:\.\d+)?(?:px|rem|em|vh|vw|fr|deg|%)$/,
        value
      )

  defp resolved_valid?(%Parsed{production: :var_reference_with_operation}, value),
    do: juxtaposition_valid?(value)

  defp resolved_valid?(%Parsed{function_name: :calc}, value), do: calc_resolved_valid?(value)

  defp resolved_valid?(%Parsed{function_name: :linear_gradient}, value),
    do: gradient_resolved_valid?(value)

  defp juxtaposition_valid?(value) do
    case split_ws(value) do
      [left, right] ->
        valid_slot?(:juxtaposition_left_operand, left) and
          valid_slot?(:juxtaposition_right_operand, right)

      _ ->
        false
    end
  end

  defp calc_resolved_valid?(value) do
    case Regex.run(~r/^calc\((.*)\)$/is, value, capture: :all_but_first) do
      [body] ->
        case Regex.run(
               ~r/^[\x20\t\r\n\f]*(.*?)[\x20\t\r\n\f]*(?:\*[\x20\t\r\n\f]*((?:\d+(?:\.\d+)?|\.\d+)))?[\x20\t\r\n\f]*$/,
               body,
               capture: :all_but_first
             ) do
          [operand] -> valid_slot?(:calc_operand, operand)
          [operand, factor] -> valid_slot?(:calc_operand, operand) and positive_finite?(factor)
          _ -> false
        end

      _ ->
        false
    end
  end

  defp gradient_resolved_valid?(value) do
    case Regex.run(~r/^linear-gradient\((.*)\)$/is, value, capture: :all_but_first) do
      [body] ->
        case split_top_level_commas(body) do
          [angle | stops] when length(stops) in 1..8 ->
            Regex.match?(~r/^\d+(?:\.\d+)?deg$/, angle) and
              Enum.all?(stops, fn stop ->
                Enum.all?(split_ws(stop), &valid_slot?(:gradient_stop_atom, &1))
              end)

          _ ->
            false
        end

      _ ->
        false
    end
  end

  defp positive_finite?(value) do
    case Float.parse(value) do
      {number, ""} ->
        number > 0 and number == number and number <= 1.7976931348623157e308

      :error ->
        case Float.parse("0" <> value) do
          {number, ""} -> number > 0 and number == number and number <= 1.7976931348623157e308
          _ -> false
        end

      _ ->
        false
    end
  end

  defp finite_nonnegative?(value) do
    case Float.parse(value) do
      {number, ""} ->
        number >= 0 and number == number and number <= 1.7976931348623157e308

      :error ->
        case Float.parse("0" <> value) do
          {number, ""} -> number >= 0 and number == number and number <= 1.7976931348623157e308
          _ -> false
        end

      _ ->
        false
    end
  end

  defp extract_name(ref),
    do: Regex.run(~r/--([A-Za-z0-9_-]+)/, ref, capture: :all_but_first) |> List.first()

  defp unsupported, do: {:error, :unsupported_grammar}
  defp resource, do: {:error, :resource_limit_exceeded}
end
