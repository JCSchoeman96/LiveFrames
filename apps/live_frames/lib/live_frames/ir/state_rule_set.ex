defmodule LiveFrames.IR.StateRuleSet do
  @moduledoc false

  alias LiveFrames.Fidelity.CSSDeclaration

  @top_level_keys ["type", "rules", "residual"]
  @rule_keys ["condition", "target_node_id", "declarations", "viewport", "order"]
  @viewport_keys ["min_width", "max_width"]
  @tagged_value_keys ["kind", "value"]
  @calculation_keys ["operation", "operands"]
  @token_operand_keys ["kind", "path"]
  @literal_operand_keys ["kind", "value"]
  @residual_keys ["reason", "source_text"]
  @conditions ["hover", "focus_within"]
  @residual_reasons MapSet.new([
                      "ambiguous_selector",
                      "malformed_block",
                      "responsive_collision",
                      "responsive_overlap_conflict",
                      "style_collision",
                      "unresolved_target",
                      "unresolved_value",
                      "unsupported_declaration",
                      "unsupported_selector",
                      "unsafe_declaration"
                    ])
  @token_path ~r/^[a-z][a-z0-9]*(\.[a-z][a-z0-9_]*)*$/
  @var_function ~r/var\s*\(/i

  @type error_reason :: :invalid_state_rule_set

  @spec validate(term()) :: :ok | {:error, error_reason()}
  def validate(value) when is_map(value) and not is_struct(value) do
    if exact_keys?(value, @top_level_keys) and value["type"] == "state_rules" and
         valid_rules?(value["rules"]) and valid_residual?(value["residual"]) do
      :ok
    else
      {:error, :invalid_state_rule_set}
    end
  end

  def validate(_value), do: {:error, :invalid_state_rule_set}

  @spec new(term(), term()) :: {:ok, map()} | {:error, error_reason()}
  def new(rules, residual) do
    value = %{"type" => "state_rules", "rules" => rules, "residual" => residual}

    case validate(value) do
      :ok -> {:ok, value}
      {:error, _reason} = error -> error
    end
  end

  defp valid_rules?(rules), do: validate_rules(rules, nil, MapSet.new(), 0)

  defp validate_rules([], _previous_order, _seen_orders, count), do: count > 0

  defp validate_rules([rule | remaining], previous_order, seen_orders, count) do
    case validate_rule(rule) do
      {:ok, order} ->
        cond do
          MapSet.member?(seen_orders, order) ->
            false

          not is_nil(previous_order) and order < previous_order ->
            false

          true ->
            validate_rules(remaining, order, MapSet.put(seen_orders, order), count + 1)
        end

      :error ->
        false
    end
  end

  defp validate_rules(_improper_or_invalid, _previous_order, _seen_orders, _count), do: false

  defp validate_rule(rule) when is_map(rule) and not is_struct(rule) do
    order = Map.get(rule, "order")

    if exact_keys?(rule, @rule_keys) and Map.get(rule, "condition") in @conditions and
         nonempty_utf8_string?(Map.get(rule, "target_node_id")) and
         valid_declarations?(Map.get(rule, "declarations")) and
         valid_viewport?(Map.get(rule, "viewport")) and is_integer(order) and order >= 0 do
      {:ok, order}
    else
      :error
    end
  end

  defp validate_rule(_rule), do: :error

  defp valid_declarations?(declarations)
       when is_map(declarations) and not is_struct(declarations) and map_size(declarations) > 0 do
    validate_declarations(Map.to_list(declarations))
  end

  defp valid_declarations?(_declarations), do: false

  defp validate_declarations([]), do: true

  defp validate_declarations([{property, tagged_value} | remaining]) do
    valid_property?(property) and valid_tagged_value?(tagged_value) and
      validate_declarations(remaining)
  end

  defp validate_declarations(_improper_or_invalid), do: false

  defp valid_property?(property) when is_binary(property) do
    nonempty_utf8_string?(property) and property != "custom-css" and
      CSSDeclaration.safe_property?(property)
  end

  defp valid_property?(_property), do: false

  defp valid_tagged_value?(value) when is_map(value) and not is_struct(value) do
    if exact_keys?(value, @tagged_value_keys) do
      case value["kind"] do
        "literal" -> valid_literal?(value["value"])
        "keyword" -> valid_keyword?(value["value"])
        "token_ref" -> valid_token_path?(value["value"])
        "calculation" -> valid_calculation?(value["value"])
        _unknown_kind -> false
      end
    else
      false
    end
  end

  defp valid_tagged_value?(_value), do: false

  defp valid_literal?(value) when is_binary(value),
    do: String.valid?(value) and CSSDeclaration.safe_value?(value)

  defp valid_literal?(value) when is_number(value), do: finite_number?(value)
  defp valid_literal?(_value), do: false

  defp valid_keyword?(value),
    do: nonempty_utf8_string?(value) and CSSDeclaration.safe_value?(value)

  defp valid_token_path?(path) when is_binary(path) do
    nonempty_utf8_string?(path) and Regex.match?(@token_path, path) and
      not String.contains?(path, "--") and not Regex.match?(@var_function, path)
  end

  defp valid_token_path?(_path), do: false

  defp valid_calculation?(
         %{"operation" => "multiply", "operands" => [token_operand, literal_operand]} = value
       ) do
    exact_keys?(value, @calculation_keys) and valid_token_operand?(token_operand) and
      valid_literal_operand?(literal_operand)
  end

  defp valid_calculation?(_calculation), do: false

  defp valid_token_operand?(operand) when is_map(operand) and not is_struct(operand) do
    exact_keys?(operand, @token_operand_keys) and operand["kind"] == "token_ref" and
      valid_token_path?(operand["path"])
  end

  defp valid_token_operand?(_operand), do: false

  defp valid_literal_operand?(operand) when is_map(operand) and not is_struct(operand) do
    exact_keys?(operand, @literal_operand_keys) and operand["kind"] == "literal" and
      is_number(operand["value"]) and finite_number?(operand["value"])
  end

  defp valid_literal_operand?(_operand), do: false

  defp valid_viewport?(nil), do: true

  defp valid_viewport?(viewport) when is_map(viewport) and not is_struct(viewport) do
    if exact_keys?(viewport, @viewport_keys) do
      min_width = viewport["min_width"]
      max_width = viewport["max_width"]

      valid_viewport_bound?(min_width) and valid_viewport_bound?(max_width) and
        (is_number(min_width) or is_number(max_width)) and
        viewport_bounds_ordered?(min_width, max_width)
    else
      false
    end
  end

  defp valid_viewport?(_viewport), do: false

  defp valid_viewport_bound?(nil), do: true

  defp valid_viewport_bound?(bound) when is_number(bound),
    do: finite_number?(bound) and bound >= 0

  defp valid_viewport_bound?(_bound), do: false

  defp viewport_bounds_ordered?(min_width, max_width)
       when is_number(min_width) and is_number(max_width),
       do: min_width <= max_width

  defp viewport_bounds_ordered?(_min_width, _max_width), do: true

  defp valid_residual?(residual), do: validate_residual(residual)

  defp validate_residual([]), do: true

  defp validate_residual([entry | remaining]) do
    valid_residual_entry?(entry) and validate_residual(remaining)
  end

  defp validate_residual(_improper_or_invalid), do: false

  defp valid_residual_entry?(entry) when is_map(entry) and not is_struct(entry) do
    exact_keys?(entry, @residual_keys) and MapSet.member?(@residual_reasons, entry["reason"]) and
      nonempty_utf8_string?(entry["source_text"])
  end

  defp valid_residual_entry?(_entry), do: false

  defp exact_keys?(map, expected_keys) do
    map_size(map) == length(expected_keys) and Enum.all?(expected_keys, &Map.has_key?(map, &1))
  end

  defp nonempty_utf8_string?(value) when is_binary(value),
    do: byte_size(value) > 0 and String.valid?(value)

  defp nonempty_utf8_string?(_value), do: false

  defp finite_number?(value) when is_integer(value), do: true

  defp finite_number?(value) when is_float(value) do
    case Jason.encode(value) do
      {:ok, encoded} -> not String.contains?(encoded, ["NaN", "Infinity"])
      _error -> false
    end
  rescue
    _error -> false
  catch
    _kind, _reason -> false
  end

  defp finite_number?(_value), do: false
end
