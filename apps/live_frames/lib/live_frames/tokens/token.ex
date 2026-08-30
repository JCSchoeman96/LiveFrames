defmodule LiveFrames.Tokens.Token do
  @moduledoc """
  A canonical semantic token and its source-resolution evidence.
  """

  @type t :: %__MODULE__{
          path: String.t() | nil,
          category: atom() | nil,
          value: term(),
          resolved_value: term(),
          source_expression: term(),
          resolution_status: :resolved | :unresolved,
          references: [String.t()],
          provenance: map(),
          metadata: map()
        }

  defstruct path: nil,
            category: nil,
            value: nil,
            resolved_value: nil,
            source_expression: nil,
            resolution_status: :unresolved,
            references: [],
            provenance: %{},
            metadata: %{}

  @spec new(keyword()) :: t()
  def new(attrs \\ []) when is_list(attrs), do: struct(__MODULE__, attrs)
end
