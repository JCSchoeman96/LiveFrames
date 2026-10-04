defmodule LiveFrames.ComponentizationPlan.Json do
  @moduledoc false

  @spec normalize(term()) :: {:ok, term()} | :error
  def normalize(nil), do: {:ok, nil}
  def normalize(value) when is_binary(value), do: key_string(value)
  def normalize(value) when is_boolean(value), do: {:ok, value}
  def normalize(value) when is_integer(value) or is_float(value), do: {:ok, value}

  def normalize([]), do: {:ok, []}

  def normalize([head | tail]) do
    with {:ok, normalized_head} <- normalize(head),
         {:ok, normalized_tail} <- normalize_list_tail(tail) do
      {:ok, [normalized_head | normalized_tail]}
    else
      _ -> :error
    end
  end

  def normalize(value) when is_map(value) and not is_struct(value) do
    Enum.reduce_while(value, {:ok, %{}}, fn {key, nested}, {:ok, acc} ->
      with {:ok, key} <- key_string(key),
           false <- Map.has_key?(acc, key),
           {:ok, normalized} <- normalize(nested) do
        {:cont, {:ok, Map.put(acc, key, normalized)}}
      else
        _ -> {:halt, :error}
      end
    end)
  end

  def normalize(_value), do: :error

  defp normalize_list_tail([]), do: {:ok, []}

  defp normalize_list_tail([head | tail]) do
    with {:ok, normalized_head} <- normalize(head),
         {:ok, normalized_tail} <- normalize_list_tail(tail) do
      {:ok, [normalized_head | normalized_tail]}
    else
      _ -> :error
    end
  end

  defp normalize_list_tail(_improper_tail), do: :error

  @spec key_string(term()) :: {:ok, String.t()} | :error
  def key_string(key) when is_binary(key) do
    if String.valid?(key), do: {:ok, key}, else: :error
  end

  def key_string(key) when is_atom(key) and key not in [nil, true, false],
    do: {:ok, Atom.to_string(key)}

  def key_string(_key), do: :error

  @spec object?(term()) :: boolean()
  def object?(value) when is_map(value) and not is_struct(value) do
    case normalize(value) do
      {:ok, normalized} when map_size(normalized) == map_size(value) -> true
      _ -> false
    end
  end

  def object?(_value), do: false
end
