defmodule LiveFrames.Adapters.Bricks.ContentProxy do
  @moduledoc """
  A top-level copied-content proxy that points to a Bricks component by `cid`.
  """

  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t() | nil,
          parent: term(),
          children: [String.t()],
          settings: map(),
          label: String.t() | nil,
          cid: String.t() | nil,
          raw: map()
        }

  defstruct id: nil,
            name: nil,
            parent: nil,
            children: [],
            settings: %{},
            label: nil,
            cid: nil,
            raw: %{}

  @spec new(keyword()) :: t()
  def new(attrs \\ []) when is_list(attrs), do: struct(__MODULE__, attrs)
end
