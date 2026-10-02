defmodule LiveFrames.ComponentContract.Diagnostic do
  @moduledoc """
  Structured diagnostic emitted by ComponentContract validation.
  """

  @severities [:info, :warning, :error, :fatal]

  @type t :: %__MODULE__{
          code: String.t() | nil,
          severity: atom(),
          message: String.t() | nil,
          path: String.t() | nil,
          suggested_action: String.t() | nil,
          metadata: map()
        }

  defstruct code: nil,
            severity: :error,
            message: nil,
            path: nil,
            suggested_action: nil,
            metadata: %{}

  @spec severities() :: [atom()]
  def severities, do: @severities

  @spec blocking_severities() :: [atom()]
  def blocking_severities, do: [:error, :fatal]

  @spec new(keyword()) :: t()
  def new(attrs \\ []) when is_list(attrs) do
    attrs =
      Keyword.update(attrs, :severity, :error, fn value ->
        if value in @severities, do: value, else: :error
      end)

    struct(__MODULE__, attrs)
  end
end
