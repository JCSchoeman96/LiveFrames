defmodule LiveFrames.Adapters.Bricks.GlobalClass do
  @moduledoc """
  A Bricks global class record, including its source category and raw data.
  """

  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t() | nil,
          category: String.t() | nil,
          settings: map(),
          raw: map()
        }

  defstruct id: nil,
            name: nil,
            category: nil,
            settings: %{},
            raw: %{}

  @spec new(keyword()) :: t()
  def new(attrs \\ []) when is_list(attrs), do: struct(__MODULE__, attrs)
end
