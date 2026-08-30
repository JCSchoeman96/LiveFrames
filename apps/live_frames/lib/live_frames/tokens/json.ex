defmodule LiveFrames.Tokens.Json do
  @moduledoc """
  Shared JSON object-key policy for TokenSet validation and serialization.
  """

  @spec key_string(term()) :: {:ok, String.t()} | :error
  def key_string(key) when is_binary(key), do: {:ok, key}

  def key_string(key) when is_atom(key) and key not in [nil, true, false],
    do: {:ok, Atom.to_string(key)}

  def key_string(_key), do: :error

  @spec key_string!(term()) :: String.t()
  def key_string!(key) do
    case key_string(key) do
      {:ok, string} -> string
      :error -> raise ArgumentError, "JSON object key must be a string or atom: #{inspect(key)}"
    end
  end
end
