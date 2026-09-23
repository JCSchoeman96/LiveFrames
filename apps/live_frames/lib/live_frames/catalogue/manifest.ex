defmodule LiveFrames.Catalogue.Manifest do
  @moduledoc """
  Decodes canonical Catalogue manifest JSON into a bounded data structure.

  Manifest values remain inert data. Module references and nested metadata are
  stored as strings, maps, and lists.
  """

  alias LiveFrames.Catalogue.Schema.V1

  defstruct [
    :schema_version,
    :id,
    :kind,
    :display_name,
    :state,
    :component,
    :contract,
    :storybook,
    :docs,
    :provenance,
    :distribution,
    :release,
    :introduced_in_package,
    :last_changed_in_package,
    :lifecycle,
    :deprecation,
    :superseded_by
  ]

  @type diagnostic :: %{code: String.t(), path: String.t(), message: String.t()}
  @type t :: %__MODULE__{}

  @spec decode(term()) :: {:ok, t()} | {:error, [diagnostic()]}
  def decode(json) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, manifest} when is_map(manifest) ->
        from_map(manifest)

      {:ok, _value} ->
        error("catalogue.manifest.root_not_object", "$", "Expected a JSON object.")

      {:error, _reason} ->
        error("catalogue.manifest.invalid_json", "$", "Manifest is not valid JSON.")
    end
  end

  def decode(_json),
    do: error("catalogue.manifest.invalid_json", "$", "Manifest input must be JSON text.")

  defp from_map(manifest) when is_map(manifest) do
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
        case V1.validate(manifest) do
          {:ok, attributes} -> {:ok, struct(__MODULE__, attributes)}
          {:error, diagnostics} -> {:error, diagnostics}
        end

      {:ok, _version} ->
        error(
          "catalogue.manifest.schema_version_unsupported",
          "schema_version",
          "No validator is available for this schema version."
        )
    end
  end

  defp from_map(_manifest),
    do: error("catalogue.manifest.root_not_object", "$", "Expected a JSON object.")

  defp error(code, path, message), do: {:error, [%{code: code, path: path, message: message}]}
end
