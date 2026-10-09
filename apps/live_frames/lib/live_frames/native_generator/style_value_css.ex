defmodule LiveFrames.NativeGenerator.StyleValueCSS do
  @moduledoc false

  alias LiveFrames.Fidelity.CSSDeclaration
  alias LiveFrames.IR.StyleValue
  alias LiveFrames.Styling.TokenBridge

  @spec serialize(StyleValue.t()) :: {:ok, String.t()} | {:error, term()}
  def serialize(%StyleValue{kind: :literal, value: value}), do: serialize_literal(value)
  def serialize(%StyleValue{kind: :keyword, value: value}), do: serialize_binary(value)

  def serialize(%StyleValue{kind: :token_ref, value: path}) when is_binary(path) do
    case TokenBridge.package_css_variable(path) do
      {:ok, css_variable} -> validate_css_value("var(" <> css_variable <> ")")
      {:error, reason} -> {:error, {:token_mapping_blocked, reason}}
    end
  end

  def serialize(%StyleValue{kind: :calculation, value: calculation}) do
    with {:ok, token_path, multiplier} <- structured_multiply(calculation),
         {:ok, css_variable} <- package_variable(token_path),
         {:ok, multiplier_css} <- serialize_number(multiplier),
         {:ok, css_value} <-
           validate_css_value("calc(var(" <> css_variable <> ") * " <> multiplier_css <> ")") do
      {:ok, css_value}
    end
  end

  def serialize(%StyleValue{}), do: {:error, :unsupported_style_value}
  def serialize(_value), do: {:error, :unsupported_style_value}

  defp serialize_literal(value) when is_binary(value), do: validate_css_value(value)

  defp serialize_literal(value) when is_integer(value),
    do: validate_css_value(Integer.to_string(value))

  defp serialize_literal(value) when is_float(value) do
    with {:ok, serialized} <- serialize_number(value), do: validate_css_value(serialized)
  end

  defp serialize_literal(_value), do: {:error, :unsupported_style_value}

  defp serialize_binary(value) when is_binary(value), do: validate_css_value(value)
  defp serialize_binary(_value), do: {:error, :unsupported_style_value}

  defp serialize_number(value) when is_integer(value), do: {:ok, Integer.to_string(value)}

  defp serialize_number(value) when is_float(value) do
    serialized = :erlang.float_to_binary(value, [:short])

    if String.match?(serialized, ~r/^-?(?:[0-9]+(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?)$/) do
      {:ok, serialized}
    else
      {:error, :unsupported_style_value}
    end
  rescue
    ArgumentError -> {:error, :unsupported_style_value}
  end

  defp serialize_number(_value), do: {:error, :unsupported_calculation}

  defp structured_multiply(
         %{
           "operation" => "multiply",
           "operands" => [
             %{"kind" => "token_ref", "path" => token_path} = token,
             %{"kind" => "literal", "value" => multiplier} = literal
           ]
         } = calculation
       )
       when is_binary(token_path) and (is_integer(multiplier) or is_float(multiplier)) and
              map_size(calculation) == 2 and map_size(token) == 2 and map_size(literal) == 2 do
    {:ok, token_path, multiplier}
  end

  defp structured_multiply(_calculation), do: {:error, :unsupported_calculation}

  defp package_variable(token_path) do
    case TokenBridge.package_css_variable(token_path) do
      {:ok, css_variable} -> {:ok, css_variable}
      {:error, reason} -> {:error, {:token_mapping_blocked, reason}}
    end
  end

  defp validate_css_value(value) do
    if CSSDeclaration.safe_value?(value),
      do: {:ok, value},
      else: {:error, :unsafe_css_value}
  end
end
