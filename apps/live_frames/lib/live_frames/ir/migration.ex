defmodule LiveFrames.IR.Migration do
  @moduledoc false

  alias LiveFrames.IR.Diagnostic

  @migration_provenance_key "liveframes_ir_migrations"
  @v1 "1.0.0"
  @v2 "2.0.0"

  @migration_entry %{
    "source_version" => @v1,
    "target_version" => @v2,
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
        migrate_v1_to_v2(map)

      {:ok, @v2} ->
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
    with :ok <- reject_v2_only_roots(map),
         :ok <- require_provenance_object(map),
         provenance = Map.fetch!(map, "provenance"),
         {:ok, provenance} <- merge_migration_provenance(provenance) do
      {:ok,
       map
       |> Map.put("ir_version", @v2)
       |> Map.put("collection_bindings", %{})
       |> Map.put("value_bindings", %{})
       |> Map.put("provenance", provenance)}
    end
  end

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
             "provenance is required for 1.0.0 structural migration"
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

  defp merge_migration_provenance(provenance) do
    case Map.fetch(provenance, @migration_provenance_key) do
      :error ->
        {:ok, Map.put(provenance, @migration_provenance_key, [@migration_entry])}

      {:ok, existing} when existing == [@migration_entry] ->
        {:ok, provenance}

      {:ok, entries} when is_list(entries) ->
        if Enum.any?(entries, &conflicting_migration?/1) do
          {:error,
           [
             error(
               "ir.migration.provenance_collision",
               "provenance already records an incompatible IR migration"
             )
           ]}
        else
          if Enum.any?(entries, &(&1 == @migration_entry)) do
            {:ok, provenance}
          else
            {:ok, Map.put(provenance, @migration_provenance_key, entries ++ [@migration_entry])}
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

  defp conflicting_migration?(%{"source_version" => @v1, "target_version" => @v2} = entry) do
    entry != @migration_entry
  end

  defp conflicting_migration?(_entry), do: false

  defp error(code, message),
    do: Diagnostic.new(code: code, severity: :error, category: :schema, message: message)
end
