defmodule LiveFrames.Tokens.Serializer do
  @moduledoc """
  Converts validated TokenSet structs to deterministic JSON objects.
  """

  alias LiveFrames.Tokens.Diagnostic
  alias LiveFrames.Tokens.Json
  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet

  @spec to_map(TokenSet.t()) :: map()
  def to_map(%TokenSet{} = token_set) do
    %{
      "token_set_version" => token_set.token_set_version,
      "source_metadata" => normalize_json(token_set.source_metadata),
      "tokens" => token_registry_to_map(token_set.tokens),
      "diagnostics" => Enum.map(token_set.diagnostics, &diagnostic_to_map/1)
    }
  end

  @spec encode(TokenSet.t()) :: {:ok, String.t()} | {:error, Exception.t()}
  def encode(%TokenSet{} = token_set) do
    Jason.encode(ordered(to_map(token_set)), maps: :strict)
  end

  @spec encode!(TokenSet.t()) :: String.t()
  def encode!(%TokenSet{} = token_set),
    do: Jason.encode!(ordered(to_map(token_set)), maps: :strict)

  defp token_registry_to_map(tokens) when is_map(tokens) do
    Map.new(tokens, fn {path, token} -> {key_string!(path), token_to_map(token)} end)
  end

  defp token_to_map(%Token{} = token) do
    %{
      "path" => token.path,
      "category" => Atom.to_string(token.category),
      "value" => normalize_json(token.value),
      "resolved_value" => normalize_json(token.resolved_value),
      "source_expression" => normalize_json(token.source_expression),
      "resolution_status" => Atom.to_string(token.resolution_status),
      "references" => token.references,
      "provenance" => normalize_json(token.provenance),
      "metadata" => normalize_json(token.metadata)
    }
  end

  defp diagnostic_to_map(%Diagnostic{} = diagnostic) do
    %{
      "code" => diagnostic.code,
      "severity" => Atom.to_string(diagnostic.severity),
      "category" => Atom.to_string(diagnostic.category),
      "message" => diagnostic.message,
      "path" => diagnostic.path,
      "source_key" => diagnostic.source_key,
      "metadata" => normalize_json(diagnostic.metadata)
    }
  end

  defp normalize_json(nil), do: nil
  defp normalize_json(value) when is_binary(value), do: value
  defp normalize_json(value) when is_boolean(value), do: value
  defp normalize_json(value) when is_integer(value) or is_float(value), do: value
  defp normalize_json(value) when is_list(value), do: Enum.map(value, &normalize_json/1)

  defp normalize_json(value) when is_map(value) and not is_struct(value) do
    Map.new(value, fn {key, nested} -> {key_string!(key), normalize_json(nested)} end)
  end

  defp normalize_json(value),
    do: raise(ArgumentError, "cannot serialize non-JSON value: #{inspect(value)}")

  defp ordered(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} -> {key, ordered(value)} end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Jason.OrderedObject.new()
  end

  defp ordered(list) when is_list(list), do: Enum.map(list, &ordered/1)
  defp ordered(value), do: value

  defp key_string!(key), do: Json.key_string!(key)
end
