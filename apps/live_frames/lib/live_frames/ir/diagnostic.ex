defmodule LiveFrames.IR.Diagnostic do
  @moduledoc """
  Structured information, warning, or error emitted during IR processing.
  """

  @severities [:info, :warning, :error, :fatal]
  @categories [
    :schema,
    :unsupported_element,
    :unsupported_style,
    :unresolved_class,
    :unresolved_token,
    :ambiguous_semantics,
    :asset_missing,
    :interaction_unsupported,
    :accessibility,
    :provenance,
    :generator,
    :visual_validation
  ]

  @type t :: %__MODULE__{
          code: String.t() | nil,
          severity: atom(),
          category: atom(),
          message: String.t() | nil,
          source_trace: LiveFrames.IR.SourceTrace.t() | nil,
          suggested_action: String.t() | nil,
          metadata: map()
        }

  defstruct code: nil,
            severity: :error,
            category: :schema,
            message: nil,
            source_trace: nil,
            suggested_action: nil,
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
      |> Keyword.update(:category, :schema, &normalize(&1, @categories, :schema))

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
