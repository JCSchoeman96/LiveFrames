defmodule LiveFrames.ComponentContract.ItemField do
  @moduledoc """
  Item field shape for a collection input's list items.
  """

  alias LiveFrames.ComponentContract.Attr

  @type t :: %__MODULE__{
          name: String.t() | nil,
          type: atom(),
          required: boolean(),
          default: term(),
          semantic_purpose: String.t() | nil,
          validation: map(),
          accessibility: map(),
          provenance: map()
        }

  defstruct name: nil,
            type: :string,
            required: false,
            default: nil,
            semantic_purpose: nil,
            validation: %{},
            accessibility: %{},
            provenance: %{}

  @spec phoenix_types() :: [atom()]
  def phoenix_types, do: Attr.phoenix_types()
end
