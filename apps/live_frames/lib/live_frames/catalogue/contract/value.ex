defmodule LiveFrames.Catalogue.Contract.Value do
  @moduledoc false

  alias LiveFrames.Catalogue.CanonicalJSON

  @type diagnostic :: %{code: String.t(), path: String.t(), message: String.t()}

  @unsupported_code "catalogue.contract.value.unsupported"
  @invalid_string_code "catalogue.contract.value.invalid_string"
  @invalid_range_code "catalogue.contract.value.invalid_range"
  @duplicate_key_code "catalogue.contract.value.map_key_duplicate"

  @spec normalize(term()) :: {:ok, term()} | {:error, [diagnostic()]}
  def normalize(value), do: normalize(value, "$")

  defp normalize(nil, _path), do: {:ok, nil}
  defp normalize(value, _path) when is_boolean(value), do: {:ok, value}

  defp normalize(value, path) when is_binary(value) do
    case CanonicalJSON.encode(value) do
      {:ok, _bytes} ->
        {:ok, value}

      {:error, _diagnostics} ->
        error(@invalid_string_code, path, "String must contain valid Unicode.")
    end
  end

  defp normalize(value, _path) when is_integer(value) do
    {:ok, %{"$type" => "integer", "value" => Integer.to_string(value)}}
  end

  defp normalize(value, _path) when is_float(value) do
    bits = <<value::float-big-64>> |> Base.encode16(case: :lower)
    {:ok, %{"$type" => "float64", "bits" => bits}}
  end

  defp normalize(%{__struct__: Range} = range, path) do
    if map_size(range) == 4 do
      normalize_range(Map.get(range, :first), Map.get(range, :last), Map.get(range, :step), path)
    else
      invalid_range(path)
    end
  end

  defp normalize(value, path) when is_atom(value) do
    value
    |> Atom.to_string()
    |> normalize(path)
    |> tag_atom_result()
  end

  defp normalize(value, path) when is_list(value) do
    with {:ok, items} <- normalize_list(value, "#{path}.items", 0, []) do
      {:ok, %{"$type" => "list", "items" => items}}
    end
  end

  defp normalize(value, path) when is_tuple(value) do
    with {:ok, items} <- normalize_sequence(Tuple.to_list(value), "#{path}.items") do
      {:ok, %{"$type" => "tuple", "items" => items}}
    end
  end

  defp normalize(%_{} = _struct, path),
    do: error(@unsupported_code, path, "Value is not supported.")

  defp normalize(value, path) when is_map(value), do: normalize_map(value, path)

  defp normalize(_value, path),
    do: error(@unsupported_code, path, "Value is not supported.")

  defp tag_atom_result({:ok, value}), do: {:ok, %{"$type" => "atom", "value" => value}}
  defp tag_atom_result({:error, diagnostics}), do: {:error, diagnostics}

  defp normalize_range(first, last, step, path)
       when is_integer(first) and is_integer(last) and is_integer(step) and step != 0 do
    with {:ok, normalized_first} <- normalize(first, "#{path}.first"),
         {:ok, normalized_last} <- normalize(last, "#{path}.last"),
         {:ok, normalized_step} <- normalize(step, "#{path}.step") do
      {:ok,
       %{
         "$type" => "range",
         "first" => normalized_first,
         "last" => normalized_last,
         "step" => normalized_step
       }}
    end
  end

  defp normalize_range(_first, _last, _step, path),
    do: invalid_range(path)

  defp invalid_range(path),
    do:
      error(
        @invalid_range_code,
        path,
        "Range must have integer endpoints and a non-zero integer step."
      )

  defp normalize_list([], _path, _index, acc), do: {:ok, Enum.reverse(acc)}

  defp normalize_list([value | rest], path, index, acc) do
    with {:ok, normalized} <- normalize(value, "#{path}[#{index}]") do
      normalize_list(rest, path, index + 1, [normalized | acc])
    end
  end

  defp normalize_list(_improper_tail, path, index, _acc),
    do: error(@unsupported_code, "#{path}[#{index}]", "Value is not supported.")

  defp normalize_sequence(values, path) do
    values
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {value, index}, {:ok, acc} ->
      case normalize(value, "#{path}[#{index}]") do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, diagnostics} -> {:halt, {:error, diagnostics}}
      end
    end)
    |> reverse_sequence_result()
  end

  defp reverse_sequence_result({:ok, values}), do: {:ok, Enum.reverse(values)}
  defp reverse_sequence_result({:error, diagnostics}), do: {:error, diagnostics}

  defp normalize_map(map, path) do
    key_path = "#{path}.entries.key"

    prepared_keys =
      map
      |> Map.keys()
      |> Enum.map(&prepare_map_key(&1, key_path))

    case map_key_errors(prepared_keys) do
      [] ->
        entries =
          prepared_keys
          |> Enum.map(fn {:ok, prepared} -> prepared end)
          |> Enum.sort_by(& &1.bytes)

        if duplicate_map_keys?(entries) do
          error(
            @duplicate_key_code,
            "#{path}.entries",
            "Map keys have duplicate canonical representations."
          )
        else
          normalize_map_values(entries, map, path)
        end

      diagnostics ->
        diagnostic = Enum.min_by(diagnostics, &{&1.path, &1.code, &1.message})
        {:error, [diagnostic]}
    end
  end

  defp prepare_map_key(key, path) do
    with {:ok, normalized_key} <- normalize(key, path),
         {:ok, bytes} <- canonical_key_bytes(normalized_key, path) do
      {:ok, %{bytes: bytes, source_key: key, normalized_key: normalized_key}}
    end
  end

  defp canonical_key_bytes(normalized_key, path) do
    case CanonicalJSON.encode(normalized_key) do
      {:ok, bytes} -> {:ok, bytes}
      {:error, _diagnostics} -> error(@unsupported_code, path, "Value is not supported.")
    end
  end

  defp map_key_errors(prepared_keys) do
    for {:error, diagnostics} <- prepared_keys, diagnostic <- diagnostics, do: diagnostic
  end

  defp duplicate_map_keys?([first, second | rest]) do
    first.bytes == second.bytes or duplicate_map_keys?([second | rest])
  end

  defp duplicate_map_keys?(_entries), do: false

  defp normalize_map_values(entries, map, path) do
    entries
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {entry, index}, {:ok, acc} ->
      value_path = "#{path}.entries[#{index}].value"

      case normalize(Map.fetch!(map, entry.source_key), value_path) do
        {:ok, normalized_value} ->
          normalized_entry = %{"key" => entry.normalized_key, "value" => normalized_value}
          {:cont, {:ok, [normalized_entry | acc]}}

        {:error, diagnostics} ->
          {:halt, {:error, diagnostics}}
      end
    end)
    |> reverse_sequence_result()
    |> tag_map_result()
  end

  defp tag_map_result({:ok, entries}), do: {:ok, %{"$type" => "map", "entries" => entries}}
  defp tag_map_result({:error, diagnostics}), do: {:error, diagnostics}

  defp error(code, path, message) do
    {:error, [%{code: code, path: path, message: message}]}
  end
end
