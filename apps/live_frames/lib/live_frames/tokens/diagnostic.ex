defmodule LiveFrames.Tokens.Diagnostic do
  @moduledoc """
  Structured information, warning, or error emitted by token processing.
  """

  @severities [:info, :warning, :error, :fatal]
  @categories [
    :source,
    :version,
    :mapping,
    :value,
    :path,
    :reference,
    :required,
    :provenance,
    :serialization
  ]

  @type t :: %__MODULE__{
          code: String.t() | nil,
          severity: atom(),
          category: atom(),
          message: String.t() | nil,
          path: String.t() | nil,
          source_key: String.t() | nil,
          metadata: map()
        }

  defstruct code: nil,
            severity: :error,
            category: :source,
            message: nil,
            path: nil,
            source_key: nil,
            metadata: %{}

  @spec severities() :: [atom()]
  def severities, do: @severities

  @spec categories() :: [atom()]
  def categories, do: @categories

  @spec new(keyword()) :: t()
  def new(attrs \\ []) when is_list(attrs) do
    attrs =
      attrs
      |> Keyword.update(:severity, :error, &normalize(&1, @severities, :error))
      |> Keyword.update(:category, :source, &normalize(&1, @categories, :source))

    struct(__MODULE__, attrs)
  end

  defp normalize(value, allowed, fallback) do
    cond do
      value in allowed ->
        value

      is_binary(value) ->
        atom = String.to_existing_atom(value)
        if atom in allowed, do: atom, else: fallback

      true ->
        fallback
    end
  rescue
    ArgumentError -> fallback
  end
end
