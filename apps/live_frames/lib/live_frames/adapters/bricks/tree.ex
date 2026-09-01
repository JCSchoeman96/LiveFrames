defmodule LiveFrames.Adapters.Bricks.Tree do
  @moduledoc """
  Deterministic ordered reconstruction of a Bricks component's flat elements.
  """

  alias LiveFrames.Adapters.Bricks.Element

  @type t :: %__MODULE__{
          elements: %{optional(String.t()) => Element.t()},
          ordered_elements: [Element.t()],
          root_ids: [String.t()],
          children_by_id: %{optional(String.t()) => [String.t()]},
          parent_by_id: %{optional(String.t()) => term()},
          source_order: [String.t()]
        }

  defstruct elements: %{},
            ordered_elements: [],
            root_ids: [],
            children_by_id: %{},
            parent_by_id: %{},
            source_order: []

  @spec new(keyword()) :: t()
  def new(attrs \\ []) when is_list(attrs), do: struct(__MODULE__, attrs)

  @spec element_count(t()) :: non_neg_integer()
  def element_count(%__MODULE__{elements: elements}), do: map_size(elements)
end
