defmodule LiveFrames.Tokens do
  @moduledoc """
  Public API for the source-independent LiveFrames TokenSet contract.

  This module intentionally has no dependency on any source adapter.
  """

  alias LiveFrames.Tokens.TokenSet

  @spec current_token_set_version() :: String.t()
  def current_token_set_version, do: TokenSet.current_token_set_version()

  @spec validate(TokenSet.t(), keyword()) :: :ok | {:error, [LiveFrames.Tokens.Diagnostic.t()]}
  def validate(token_set, opts \\ []), do: LiveFrames.Tokens.Validation.validate(token_set, opts)

  @spec validate!(TokenSet.t(), keyword()) :: TokenSet.t()
  def validate!(token_set, opts \\ []) do
    case validate(token_set, opts) do
      :ok ->
        token_set

      {:error, diagnostics} ->
        raise LiveFrames.Tokens.ValidationError, diagnostics: diagnostics
    end
  end

  @spec to_map(TokenSet.t()) :: map()
  def to_map(token_set), do: LiveFrames.Tokens.Serializer.to_map(token_set)

  @spec encode(TokenSet.t(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def encode(token_set, opts \\ []) do
    case validate(token_set, opts) do
      :ok ->
        LiveFrames.Tokens.Serializer.encode(token_set)

      {:error, diagnostics} ->
        {:error, diagnostics}
    end
  end

  @spec encode!(TokenSet.t(), keyword()) :: String.t()
  def encode!(token_set, opts \\ []) do
    token_set
    |> validate!(opts)
    |> LiveFrames.Tokens.Serializer.encode!()
  end
end
