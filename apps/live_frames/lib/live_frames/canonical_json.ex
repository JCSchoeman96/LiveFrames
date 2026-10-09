defmodule LiveFrames.CanonicalJSON do
  @moduledoc """
  Encodes restricted JSON values as RFC 8785 canonical bytes.

  Values move from received to validated before encoding. Successful calls
  finish encoded, while invalid values are rejected without calling the JCS
  encoder.
  """

  @max_safe_integer 9_007_199_254_740_991
  @min_safe_integer -@max_safe_integer

  @type reason :: :invalid_value | :invalid_string | :invalid_object_key
  @type error :: %{reason: reason(), path: String.t()}

  @spec encode(term()) :: {:ok, binary()} | {:error, error()}
  def encode(value) do
    case validate(value, "$") do
      {:ok, :validated} -> {:ok, Jcs.encode(value)}
      {:error, error} -> {:error, error}
    end
  end

  defp validate(nil, _path), do: {:ok, :validated}
  defp validate(value, _path) when is_boolean(value), do: {:ok, :validated}

  defp validate(value, _path)
       when is_integer(value) and value >= @min_safe_integer and value <= @max_safe_integer,
       do: {:ok, :validated}

  defp validate(value, path) when is_binary(value) do
    if valid_unicode?(value) do
      {:ok, :validated}
    else
      invalid(:invalid_string, path)
    end
  end

  defp validate(value, path) when is_list(value), do: validate_list(value, path, 0)
  defp validate(%_{} = _struct, path), do: invalid(:invalid_value, path)

  defp validate(value, path) when is_map(value) do
    keys = Map.keys(value)

    cond do
      not Enum.all?(keys, &is_binary/1) ->
        invalid(:invalid_object_key, path)

      not Enum.all?(keys, &valid_unicode?/1) ->
        invalid(:invalid_object_key, path)

      true ->
        validate_map_values(value, path)
    end
  end

  defp validate(_value, path), do: invalid(:invalid_value, path)

  defp validate_list([], _path, _index), do: {:ok, :validated}

  defp validate_list([value | rest], path, index) do
    with {:ok, :validated} <- validate(value, "#{path}[#{index}]") do
      validate_list(rest, path, index + 1)
    end
  end

  defp validate_list(_improper_tail, path, index),
    do: invalid(:invalid_value, "#{path}[#{index}]")

  defp validate_map_values(map, path) do
    errors =
      Enum.reduce(map, [], fn {key, value}, errors ->
        case validate(value, "#{path}.#{key}") do
          {:ok, :validated} -> errors
          {:error, error} -> [error | errors]
        end
      end)

    case errors do
      [] -> {:ok, :validated}
      _ -> {:error, Enum.min_by(errors, &{&1.path, reason_order(&1.reason)})}
    end
  end

  defp valid_unicode?(string) do
    String.valid?(string) and
      Enum.all?(String.to_charlist(string), fn codepoint ->
        not noncharacter?(codepoint)
      end)
  end

  defp noncharacter?(codepoint) when codepoint in 0xFDD0..0xFDEF, do: true

  defp noncharacter?(codepoint),
    do: rem(codepoint, 65_536) in 65_534..65_535

  defp reason_order(:invalid_object_key), do: 0
  defp reason_order(:invalid_string), do: 1
  defp reason_order(:invalid_value), do: 2

  defp invalid(reason, path), do: {:error, %{reason: reason, path: path}}
end
