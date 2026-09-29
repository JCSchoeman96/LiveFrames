defmodule LiveFrames.Catalogue.Schema do
  @moduledoc false

  alias LiveFrames.Catalogue.Schema.V1

  @spec validate(map()) :: {:ok, keyword()} | {:error, [map()]}
  def validate(manifest) when is_map(manifest) do
    case Map.fetch(manifest, "schema_version") do
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
        V1.validate(manifest)

      {:ok, _version} ->
        error(
          "catalogue.manifest.schema_version_unsupported",
          "schema_version",
          "No validator is available for this schema version."
        )
    end
  end

  def validate(_manifest),
    do: error("catalogue.manifest.root_not_object", "$", "Expected a JSON object.")

  defp error(code, path, message), do: {:error, [%{code: code, path: path, message: message}]}
end
