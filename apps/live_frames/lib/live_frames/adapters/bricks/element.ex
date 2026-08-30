defmodule LiveFrames.Adapters.Bricks.Element do
  @moduledoc """
  A raw Bricks element record. Its source ID remains source identity.
  """

  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t() | nil,
          parent: term(),
          children: [String.t()],
          settings: map(),
          label: String.t() | nil,
          source_index: non_neg_integer() | nil,
          raw: map()
        }

  defstruct id: nil,
            name: nil,
            parent: nil,
            children: [],
            settings: %{},
            label: nil,
            source_index: nil,
            raw: %{}

  @spec new(keyword()) :: t()
  def new(attrs \\ []) when is_list(attrs), do: struct(__MODULE__, attrs)
end
