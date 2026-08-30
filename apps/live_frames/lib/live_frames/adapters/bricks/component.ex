defmodule LiveFrames.Adapters.Bricks.Component do
  @moduledoc """
  A source-specific Bricks component and its ordered raw elements.
  """

  alias LiveFrames.Adapters.Bricks.Element

  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t() | nil,
          category: String.t() | nil,
          description: String.t() | nil,
          desc: String.t() | nil,
          properties: list(),
          version: String.t() | nil,
          elements: [Element.t()],
          raw: map()
        }

  defstruct id: nil,
            name: nil,
            category: nil,
            description: nil,
            desc: nil,
            properties: [],
            version: nil,
            elements: [],
            raw: %{}

  @spec new(keyword()) :: t()
  def new(attrs \\ []) when is_list(attrs), do: struct(__MODULE__, attrs)
end
