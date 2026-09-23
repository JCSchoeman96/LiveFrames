defmodule LiveFrames.Catalogue.Schema.V1 do
  @moduledoc false

  @required_string_fields ["id", "kind", "display_name", "state"]
  @required_object_fields ["component", "storybook", "docs", "provenance"]
  @required_nested_string_fields [
    {"component", "module"},
    {"component", "function"},
    {"storybook", "module"}
  ]
  @optional_object_fields ["contract", "distribution", "release", "lifecycle", "deprecation"]
  @optional_nullable_string_fields [
    "introduced_in_package",
    "last_changed_in_package",
    "superseded_by"
  ]

  @spec validate(map()) :: {:ok, keyword()} | {:error, [map()]}
  def validate(manifest) when is_map(manifest) do
    with :ok <- validate_required_strings(manifest),
         :ok <- validate_required_objects(manifest),
         :ok <- validate_required_nested_strings(manifest),
         :ok <- validate_optional_objects(manifest),
         :ok <- validate_optional_nullable_strings(manifest) do
      {:ok, attributes(manifest)}
    end
  end

  def validate(_manifest),
    do: error("catalogue.manifest.root_not_object", "$", "Expected a JSON object.")

  defp validate_required_strings(manifest) do
    Enum.reduce_while(@required_string_fields, :ok, fn field, :ok ->
      case Map.fetch(manifest, field) do
        :error -> {:halt, missing(field)}
        {:ok, value} when is_binary(value) -> {:cont, :ok}
        {:ok, _value} -> {:halt, invalid_type(field, "Expected a string.")}
      end
    end)
  end

  defp validate_required_objects(manifest) do
    Enum.reduce_while(@required_object_fields, :ok, fn field, :ok ->
      case Map.fetch(manifest, field) do
        :error -> {:halt, missing(field)}
        {:ok, value} when is_map(value) -> {:cont, :ok}
        {:ok, _value} -> {:halt, invalid_type(field, "Expected a JSON object.")}
      end
    end)
  end

  defp validate_required_nested_strings(manifest) do
    Enum.reduce_while(@required_nested_string_fields, :ok, fn {parent, field}, :ok ->
      object = Map.fetch!(manifest, parent)
      path = parent <> "." <> field

      case Map.fetch(object, field) do
        :error -> {:halt, missing(path)}
        {:ok, value} when is_binary(value) -> {:cont, :ok}
        {:ok, _value} -> {:halt, invalid_type(path, "Expected a string.")}
      end
    end)
  end

  defp validate_optional_objects(manifest) do
    Enum.reduce_while(@optional_object_fields, :ok, fn field, :ok ->
      case Map.fetch(manifest, field) do
        :error -> {:cont, :ok}
        {:ok, value} when is_map(value) -> {:cont, :ok}
        {:ok, _value} -> {:halt, invalid_type(field, "Expected a JSON object.")}
      end
    end)
  end

  defp validate_optional_nullable_strings(manifest) do
    Enum.reduce_while(@optional_nullable_string_fields, :ok, fn field, :ok ->
      case Map.fetch(manifest, field) do
        :error -> {:cont, :ok}
        {:ok, value} when is_binary(value) or is_nil(value) -> {:cont, :ok}
        {:ok, _value} -> {:halt, invalid_type(field, "Expected a string or null.")}
      end
    end)
  end

  defp attributes(manifest) do
    [
      schema_version: 1,
      id: manifest["id"],
      kind: manifest["kind"],
      display_name: manifest["display_name"],
      state: manifest["state"],
      component: manifest["component"],
      contract: manifest["contract"],
      storybook: manifest["storybook"],
      docs: manifest["docs"],
      provenance: manifest["provenance"],
      distribution: manifest["distribution"],
      release: manifest["release"],
      introduced_in_package: manifest["introduced_in_package"],
      last_changed_in_package: manifest["last_changed_in_package"],
      lifecycle: manifest["lifecycle"],
      deprecation: manifest["deprecation"],
      superseded_by: manifest["superseded_by"]
    ]
  end

  defp missing(path),
    do: error("catalogue.manifest.field_missing", path, "Required field is missing.")

  defp invalid_type(path, message),
    do: error("catalogue.manifest.field_type_invalid", path, message)

  defp error(code, path, message), do: {:error, [%{code: code, path: path, message: message}]}
end
