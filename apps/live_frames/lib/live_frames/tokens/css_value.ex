defmodule LiveFrames.Tokens.CSSValue do
  @moduledoc """
  Finds a CSS-value candidate for a semantically resolved Token.

  This module does not validate CSS safety. Each consumer applies its own
  declaration policy to the returned candidate.
  """

  alias LiveFrames.Styling.Fluid.{CSSSerializer, Domain, Scale, ScaleStep, Value}
  alias LiveFrames.Tokens.{Token, TokenSet}

  @type reason :: :unresolved | :resolved_value_missing | :non_serializable
  @type contextual_reason :: reason() | CSSSerializer.reason() | {:invalid_fluid_target, term()}

  @fluid_targets [:legacy, :fallback, :modern]

  @spec candidate(Token.t() | map()) :: {:ok, String.t()} | {:error, reason()}
  def candidate(%Token{resolution_status: :resolved} = token) do
    candidate(:resolved, token.resolved_value, token.metadata, token.source_expression)
  end

  def candidate(%Token{}), do: {:error, :unresolved}

  def candidate(%{"resolution_status" => "resolved"} = token) do
    candidate(
      :resolved,
      Map.get(token, "resolved_value"),
      Map.get(token, "metadata"),
      Map.get(token, "source_expression")
    )
  end

  def candidate(%{"resolution_status" => "unresolved"}), do: {:error, :unresolved}

  def candidate(_token), do: {:error, :unresolved}

  @spec candidate(TokenSet.t(), Token.t(), keyword()) ::
          {:ok, String.t()} | {:error, contextual_reason()}
  def candidate(%TokenSet{} = token_set, %Token{} = token, options) when is_list(options) do
    fluid_target = Keyword.get(options, :fluid_target, :legacy)

    if fluid_target in @fluid_targets do
      contextual_candidate(token_set, token, fluid_target)
    else
      {:error, {:invalid_fluid_target, fluid_target}}
    end
  end

  defp contextual_candidate(token_set, %Token{resolution_status: :resolved} = token, fluid_target) do
    if fluid_semantic?(token.resolved_value) do
      fluid_candidate(token_set, token, fluid_target)
    else
      candidate(token)
    end
  end

  defp contextual_candidate(_token_set, token, _fluid_target), do: candidate(token)

  defp fluid_candidate(token_set, token, :legacy) do
    CSSSerializer.legacy_value(token_set, token.path)
  end

  defp fluid_candidate(token_set, token, fluid_target)
       when fluid_target in [:fallback, :modern] do
    with {:ok, %{values: values}} <- CSSSerializer.plan(token_set, [token.path]) do
      case Enum.find(values, &(&1.path == token.path)) do
        %{expression: expression} -> {:ok, expression}
        nil -> {:error, {:unsupported_realization, token.path}}
      end
    end
  end

  defp fluid_semantic?(semantic) do
    Domain.type?(semantic) or Value.type?(semantic) or Scale.type?(semantic) or
      ScaleStep.type?(semantic)
  end

  defp candidate(:resolved, nil, _metadata, _source_expression),
    do: {:error, :resolved_value_missing}

  defp candidate(:resolved, resolved_value, metadata, source_expression) do
    cond do
      css_expression = css_expression(metadata) ->
        {:ok, css_expression}

      is_binary(resolved_value) and byte_size(resolved_value) > 0 ->
        {:ok, resolved_value}

      is_integer(resolved_value) ->
        {:ok, Integer.to_string(resolved_value)}

      is_float(resolved_value) ->
        {:ok, format_float(resolved_value)}

      derived_value?(resolved_value) and is_binary(source_expression) ->
        {:ok, derived_css_value(source_expression)}

      true ->
        {:error, :non_serializable}
    end
  end

  defp css_expression(metadata) when is_map(metadata) do
    case Map.get(metadata, "css_expression", Map.get(metadata, :css_expression)) do
      expression when is_binary(expression) and byte_size(expression) > 0 -> expression
      _ -> nil
    end
  end

  defp css_expression(_metadata), do: nil

  defp derived_value?(value) when is_map(value),
    do: Map.get(value, "type", Map.get(value, :type)) == "derived"

  defp derived_value?(_value), do: false

  defp derived_css_value(expression) do
    if String.starts_with?(expression, "var("), do: expression, else: "var(#{expression})"
  end

  defp format_float(value) when is_float(value) do
    value
    |> :erlang.float_to_binary(decimals: 10)
    |> String.trim_trailing("0")
    |> String.trim_trailing(".")
  end
end
