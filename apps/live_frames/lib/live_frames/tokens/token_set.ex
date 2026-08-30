defmodule LiveFrames.Tokens.TokenSet do
  @moduledoc """
  Root container for a source-independent, versioned LiveFrames token set.

  The token-set version is owned by this contract and evolves independently of
  the Design IR version.
  """

  @current_token_set_version "1.0.0"

  @type t :: %__MODULE__{
          token_set_version: String.t(),
          source_metadata: map(),
          tokens: %{optional(String.t()) => LiveFrames.Tokens.Token.t()},
          diagnostics: [LiveFrames.Tokens.Diagnostic.t()]
        }

  defstruct token_set_version: @current_token_set_version,
            source_metadata: %{},
            tokens: %{},
            diagnostics: []

  @spec current_token_set_version() :: String.t()
  def current_token_set_version, do: @current_token_set_version

  @spec new(keyword()) :: t()
  def new(attrs \\ []) when is_list(attrs), do: struct(__MODULE__, attrs)
end
