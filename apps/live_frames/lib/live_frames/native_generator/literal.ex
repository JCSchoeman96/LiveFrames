defmodule LiveFrames.NativeGenerator.Literal do
  @moduledoc false

  alias LiveFrames.ComponentContract.Json

  @spec render(term()) :: {:ok, String.t()} | {:error, :unsupported}
  def render(term) do
    case Json.normalize(term) do
      {:ok, normalized} -> render_normalized(normalized)
      :error -> {:error, :unsupported}
    end
  end

  defp render_normalized(nil), do: {:ok, "nil"}
  defp render_normalized(true), do: {:ok, "true"}
  defp render_normalized(false), do: {:ok, "false"}
  defp render_normalized(value) when is_integer(value), do: {:ok, Integer.to_string(value)}
  defp render_normalized(value) when is_float(value), do: {:ok, inspect(value)}

  defp render_normalized(value) when is_binary(value) do
    if String.valid?(value), do: {:ok, inspect(value)}, else: {:error, :unsupported}
  end

  defp render_normalized(values) when is_list(values) do
    values
    |> Enum.reduce_while({:ok, []}, fn item, {:ok, acc} ->
      case render_normalized(item) do
        {:ok, lit} -> {:cont, {:ok, acc ++ [lit]}}
        {:error, _} -> {:halt, {:error, :unsupported}}
      end
    end)
    |> case do
      {:ok, parts} -> {:ok, "[" <> Enum.join(parts, ", ") <> "]"}
      {:error, _} -> {:error, :unsupported}
    end
  end

  defp render_normalized(value) when is_map(value) do
    keys = value |> Map.keys() |> Enum.sort()

    keys
    |> Enum.reduce_while({:ok, []}, fn key, {:ok, acc} ->
      with {:ok, key_lit} <- render_normalized(key),
           {:ok, val_lit} <- render_normalized(Map.get(value, key)) do
        {:cont, {:ok, acc ++ ["#{key_lit} => #{val_lit}"]}}
      else
        {:error, _} -> {:halt, {:error, :unsupported}}
      end
    end)
    |> case do
      {:ok, pairs} -> {:ok, "%{" <> Enum.join(pairs, ", ") <> "}"}
      {:error, _} -> {:error, :unsupported}
    end
  end

  defp render_normalized(_), do: {:error, :unsupported}
end
