defmodule LiveFrames.Catalogue.CanonicalJSON do
  @moduledoc false

  @max_safe_integer 9_007_199_254_740_991
  @min_safe_integer -@max_safe_integer

  @type diagnostic :: %{code: String.t(), path: String.t(), message: String.t()}

  @spec encode(term()) :: {:ok, binary()} | {:error, [diagnostic()]}
  def encode(value) do
    case validate(value, "$") do
      :ok -> {:ok, Jcs.encode(value)}
      {:error, diagnostic} -> {:error, [diagnostic]}
    end
  end

  defp validate(nil, _path), do: :ok
  defp validate(value, _path) when is_boolean(value), do: :ok

  defp validate(value, _path)
       when is_integer(value) and value >= @min_safe_integer and value <= @max_safe_integer,
       do: :ok

  defp validate(value, path) when is_binary(value) do
    if valid_unicode?(value) do
      :ok
    else
      invalid_string(path)
    end
  end

  defp validate(value, path) when is_list(value), do: validate_list(value, path, 0)
  defp validate(%_{} = _struct, path), do: invalid_value(path)

  defp validate(value, path) when is_map(value) do
    keys = Map.keys(value)

    cond do
      not Enum.all?(keys, &is_binary/1) ->
        invalid_object_key(path)

      not Enum.all?(keys, &valid_unicode?/1) ->
        invalid_object_key(path)

      true ->
        validate_map_values(value, path)
    end
  end

  defp validate(_value, path), do: invalid_value(path)

  defp validate_list([], _path, _index), do: :ok

  defp validate_list([value | rest], path, index) do
    with :ok <- validate(value, "#{path}[#{index}]") do
      validate_list(rest, path, index + 1)
    end
  end

  defp validate_list(_improper_tail, path, index),
    do: invalid_value("#{path}[#{index}]")

  defp validate_map_values(map, path) do
    diagnostics =
      Enum.reduce(map, [], fn {key, value}, diagnostics ->
        case validate(value, "#{path}.#{key}") do
          :ok -> diagnostics
          {:error, diagnostic} -> [diagnostic | diagnostics]
        end
      end)

    case diagnostics do
      [] -> :ok
      _ -> {:error, Enum.min_by(diagnostics, &{&1.path, &1.code, &1.message})}
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

  defp invalid_value(path),
    do: diagnostic("catalogue.canonical_json.invalid_value", path, "Value is not supported.")

  defp invalid_string(path),
    do:
      diagnostic(
        "catalogue.canonical_json.invalid_string",
        path,
        "String must contain valid Unicode scalar values."
      )

  defp invalid_object_key(path),
    do:
      diagnostic(
        "catalogue.canonical_json.invalid_object_key",
        path,
        "Object keys must be valid Unicode strings."
      )

  defp diagnostic(code, path, message), do: {:error, %{code: code, path: path, message: message}}
end
