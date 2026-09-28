defmodule LiveFrames.Catalogue.Migration do
  @moduledoc false

  @spec migrate(term(), term()) :: {:ok, map()} | {:error, [map()]}
  def migrate(source, target) when is_map(source) do
    with {:ok, source_version} <- source_version(source),
         {:ok, target_version} <- target_version(target) do
      migrate_route(source_version, target_version, source)
    end
  end

  def migrate(_source, _target),
    do:
      error(
        "catalogue.migration.source_invalid",
        "$",
        "Expected a decoded manifest map."
      )

  defp source_version(source) do
    case Map.fetch(source, "schema_version") do
      :error ->
        error(
          "catalogue.manifest.schema_version_missing",
          "schema_version",
          "Required field is missing."
        )

      {:ok, version} when not is_integer(version) ->
        error(
          "catalogue.manifest.schema_version_invalid",
          "schema_version",
          "Expected an integer."
        )

      {:ok, 1} ->
        {:ok, 1}

      {:ok, _version} ->
        error(
          "catalogue.manifest.schema_version_unsupported",
          "schema_version",
          "No validator is available for this schema version."
        )
    end
  end

  defp target_version(version) when not is_integer(version),
    do:
      error(
        "catalogue.migration.target_version_invalid",
        "target_version",
        "Expected an integer."
      )

  defp target_version(1), do: {:ok, 1}

  defp target_version(_version),
    do:
      error(
        "catalogue.migration.target_version_unsupported",
        "target_version",
        "No migration is available for this target version."
      )

  defp migrate_route(1, 1, source), do: {:ok, source}

  defp migrate_route(_source_version, _target_version, _source),
    do:
      error(
        "catalogue.migration.route_unsupported",
        "target_version",
        "No migration route is available for these schema versions."
      )

  defp error(code, path, message), do: {:error, [%{code: code, path: path, message: message}]}
end
