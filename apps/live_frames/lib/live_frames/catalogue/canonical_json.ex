defmodule LiveFrames.Catalogue.CanonicalJSON do
  @moduledoc false

  alias LiveFrames.CanonicalJSON, as: SharedCanonicalJSON

  @type diagnostic :: %{code: String.t(), path: String.t(), message: String.t()}

  @spec encode(term()) :: {:ok, binary()} | {:error, [diagnostic()]}
  def encode(value) do
    case SharedCanonicalJSON.encode(value) do
      {:ok, bytes} -> {:ok, bytes}
      {:error, %{reason: reason, path: path}} -> {:error, [diagnostic(reason, path)]}
    end
  end

  defp diagnostic(:invalid_value, path),
    do: diagnostic("catalogue.canonical_json.invalid_value", path, "Value is not supported.")

  defp diagnostic(:invalid_string, path),
    do:
      diagnostic(
        "catalogue.canonical_json.invalid_string",
        path,
        "String must contain valid Unicode scalar values."
      )

  defp diagnostic(:invalid_object_key, path),
    do:
      diagnostic(
        "catalogue.canonical_json.invalid_object_key",
        path,
        "Object keys must be valid Unicode strings."
      )

  defp diagnostic(code, path, message), do: %{code: code, path: path, message: message}
end
