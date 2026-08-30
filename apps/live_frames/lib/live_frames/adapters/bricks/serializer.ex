defmodule LiveFrames.Adapters.Bricks.Serializer do
  @moduledoc """
  Deterministic JSON serialization for Stage A report data.
  """

  @spec encode!(term()) :: String.t()
  def encode!(value), do: Jason.encode!(ordered(normalize(value)), maps: :strict)

  @spec encode(term()) :: {:ok, String.t()} | {:error, term()}
  def encode(value) do
    try do
      {:ok, encode!(value)}
    rescue
      exception -> {:error, exception}
    end
  end

  @spec to_map(term()) :: term()
  def to_map(value), do: normalize(value)

  defp normalize(nil), do: nil
  defp normalize(value) when is_binary(value), do: value
  defp normalize(value) when is_boolean(value), do: value
  defp normalize(value) when is_integer(value) or is_float(value), do: value
  defp normalize(value) when is_atom(value), do: Atom.to_string(value)

  defp normalize(value) when is_struct(value), do: value |> Map.from_struct() |> normalize()

  defp normalize(value) when is_list(value), do: Enum.map(value, &normalize/1)

  defp normalize(value) when is_map(value) do
    Map.new(value, fn {key, nested} -> {key_string(key), normalize(nested)} end)
  end

  defp normalize(value),
    do: raise(ArgumentError, "cannot serialize non-JSON value: #{inspect(value)}")

  defp ordered(value) when is_map(value) do
    value
    |> Enum.map(fn {key, nested} -> {key, ordered(nested)} end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Jason.OrderedObject.new()
  end

  defp ordered(value) when is_list(value), do: Enum.map(value, &ordered/1)
  defp ordered(value), do: value

  defp key_string(key) when is_binary(key), do: key
  defp key_string(key) when is_atom(key), do: Atom.to_string(key)
  defp key_string(key) when is_integer(key), do: Integer.to_string(key)
  defp key_string(key), do: raise(ArgumentError, "cannot serialize map key: #{inspect(key)}")
end
