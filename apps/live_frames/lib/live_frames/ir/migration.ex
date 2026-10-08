defmodule LiveFrames.IR.Migration do
  @moduledoc false

  alias LiveFrames.IR.Diagnostic

  @migration_provenance_key "liveframes_ir_migrations"
  @v1 "1.0.0"
  @v2 "2.0.0"
  @v3 "3.0.0"

  @v1_to_v2 %{
    "source_version" => @v1,
    "target_version" => @v2,
    "kind" => "structural",
    "frontend_semantics_recovered" => false
  }
  @v2_to_v3 %{
    "source_version" => @v2,
    "target_version" => @v3,
    "kind" => "structural",
    "frontend_semantics_recovered" => false
  }

  @spec to_current(map()) :: {:ok, map()} | {:error, [Diagnostic.t()]}
  def to_current(map) when is_map(map) do
    case Map.fetch(map, "ir_version") do
      :error ->
        {:error, [error("ir.document.version_missing", "ir_version must be a non-empty string")]}

      {:ok, ""} ->
        {:error, [error("ir.document.version_missing", "ir_version must be a non-empty string")]}

      {:ok, version} when not is_binary(version) ->
        {:error, [error("ir.document.version_invalid", "ir_version must be a string")]}

      {:ok, @v1} ->
        with {:ok, v2} <- migrate_v1_to_v2(map) do
          migrate_v2_to_v3(v2, :legacy_values_checked)
        end

      {:ok, @v2} ->
        migrate_v2_to_v3(map, :check_legacy_values)

      {:ok, @v3} ->
        {:ok, map}

      {:ok, _unsupported} ->
        {:error,
         [
           error(
             "ir.document.version_unsupported",
             "ir_version is not supported by the current IR contract"
           )
         ]}
    end
  end

  def to_current(_map),
    do: {:error, [error("ir.document.invalid", "expected a decoded JSON object")]}

  defp migrate_v1_to_v2(map) do
    with :ok <- reject_legacy_structured_calculations(map),
         :ok <- reject_v2_only_roots(map),
         :ok <- require_provenance_object(map),
         provenance = Map.fetch!(map, "provenance"),
         {:ok, provenance} <- merge_migration_provenance(provenance, @v1_to_v2) do
      {:ok,
       map
       |> Map.put("ir_version", @v2)
       |> Map.put("collection_bindings", %{})
       |> Map.put("value_bindings", %{})
       |> Map.put("provenance", provenance)}
    end
  end

  defp migrate_v2_to_v3(map, legacy_check) do
    with :ok <- ensure_legacy_calculations_valid(map, legacy_check),
         :ok <- require_provenance_object(map),
         provenance = Map.fetch!(map, "provenance"),
         {:ok, provenance} <- merge_migration_provenance(provenance, @v2_to_v3) do
      {:ok, map |> Map.put("ir_version", @v3) |> Map.put("provenance", provenance)}
    end
  end

  defp ensure_legacy_calculations_valid(_map, :legacy_values_checked), do: :ok

  defp ensure_legacy_calculations_valid(map, :check_legacy_values),
    do: reject_legacy_structured_calculations(map)

  defp reject_legacy_structured_calculations(map) do
    if legacy_calculations_valid?(Map.get(map, "root_nodes")) do
      :ok
    else
      {:error,
       [
         error(
           "ir.migration.legacy_calculation_invalid",
           "legacy calculation values must be non-empty strings"
         )
       ]}
    end
  end

  defp legacy_calculations_valid?(nodes) when is_list(nodes),
    do: Enum.all?(nodes, &legacy_node_calculations_valid?/1)

  defp legacy_calculations_valid?(_nodes), do: true

  defp legacy_node_calculations_valid?(node) when is_map(node) and not is_struct(node) do
    styles_valid = legacy_style_map_valid?(Map.get(node, "styles"))

    responsive_valid =
      case Map.get(node, "responsive") do
        responsive when is_map(responsive) and not is_struct(responsive) ->
          Enum.all?(responsive, fn {_key, override} ->
            is_map(override) and not is_struct(override) and
              legacy_style_map_valid?(Map.get(override, "styles"))
          end)

        _other ->
          true
      end

    children_valid =
      case Map.get(node, "children") do
        children when is_list(children) -> Enum.all?(children, &legacy_node_calculations_valid?/1)
        _other -> true
      end

    styles_valid and responsive_valid and children_valid
  end

  defp legacy_node_calculations_valid?(_node), do: true

  defp legacy_style_map_valid?(styles) when is_map(styles) and not is_struct(styles) do
    Enum.all?(styles, fn
      {_key, %{"kind" => "calculation", "value" => value}}
      when is_binary(value) and byte_size(value) > 0 ->
        true

      {_key, %{"kind" => "calculation"}} ->
        false

      _entry ->
        true
    end)
  end

  defp legacy_style_map_valid?(_styles), do: true

  defp reject_v2_only_roots(map) do
    cond do
      Map.has_key?(map, "collection_bindings") ->
        {:error,
         [
           error(
             "ir.migration.v1_shape_invalid",
             "1.0.0 documents must not contain collection_bindings before migration"
           )
         ]}

      Map.has_key?(map, "value_bindings") ->
        {:error,
         [
           error(
             "ir.migration.v1_shape_invalid",
             "1.0.0 documents must not contain value_bindings before migration"
           )
         ]}

      true ->
        :ok
    end
  end

  defp require_provenance_object(map) do
    case Map.fetch(map, "provenance") do
      :error ->
        {:error,
         [
           error(
             "ir.migration.provenance_missing",
             "provenance is required for structural migration"
           )
         ]}

      {:ok, provenance} when is_map(provenance) and not is_struct(provenance) ->
        :ok

      {:ok, nil} ->
        {:error,
         [
           error(
             "ir.migration.provenance_invalid",
             "provenance must be a JSON object before structural migration"
           )
         ]}

      {:ok, _other} ->
        {:error,
         [
           error(
             "ir.migration.provenance_invalid",
             "provenance must be a JSON object before structural migration"
           )
         ]}
    end
  end

  defp merge_migration_provenance(provenance, migration_entry) do
    case Map.fetch(provenance, @migration_provenance_key) do
      :error ->
        {:ok, Map.put(provenance, @migration_provenance_key, [migration_entry])}

      {:ok, existing} when existing == [migration_entry] ->
        {:ok, provenance}

      {:ok, entries} when is_list(entries) ->
        if Enum.any?(entries, &(not valid_migration_entry?(&1))) or
             Enum.any?(entries, &conflicting_migration?(&1, migration_entry)) do
          {:error,
           [
             error(
               "ir.migration.provenance_collision",
               "provenance already records an incompatible IR migration"
             )
           ]}
        else
          if Enum.any?(entries, &(&1 == migration_entry)) do
            {:ok, provenance}
          else
            ordered_entries = insert_migration_entry(entries, migration_entry)
            {:ok, Map.put(provenance, @migration_provenance_key, ordered_entries)}
          end
        end

      {:ok, _other} ->
        {:error,
         [
           error(
             "ir.migration.provenance_collision",
             "provenance liveframes_ir_migrations must be a list when present"
           )
         ]}
    end
  end

  defp conflicting_migration?(
         %{"source_version" => source, "target_version" => target} = entry,
         %{"source_version" => source, "target_version" => target} = expected
       ),
       do: entry != expected

  defp conflicting_migration?(_entry, _expected), do: false

  defp valid_migration_entry?(%{
         "source_version" => source,
         "target_version" => target,
         "kind" => kind,
         "frontend_semantics_recovered" => recovered
       }) do
    is_binary(source) and source != "" and is_binary(target) and target != "" and
      is_binary(kind) and is_boolean(recovered)
  end

  defp valid_migration_entry?(_entry), do: false

  defp insert_migration_entry(entries, migration_entry) do
    index =
      if migration_entry == @v1_to_v2 do
        Enum.find_index(entries, fn
          %{"source_version" => @v2, "target_version" => @v3} -> true
          _entry -> false
        end) || length(entries)
      else
        length(entries)
      end

    List.insert_at(entries, index, migration_entry)
  end

  defp error(code, message),
    do: Diagnostic.new(code: code, severity: :error, category: :schema, message: message)
end
