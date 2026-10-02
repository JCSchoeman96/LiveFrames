defmodule LiveFrames.ComponentContract.CollectionInput do
  @moduledoc """
  Collection input binding metadata in a ComponentContract.
  """

  alias LiveFrames.ComponentContract.ItemField

  @type t :: %__MODULE__{
          source_collection_binding_id: String.t() | nil,
          public_attr_name: String.t() | nil,
          parent_collection_binding_id: String.t() | nil,
          parent_item_field_name: String.t() | nil,
          item_fields: [ItemField.t()],
          count_attr_name: String.t() | nil,
          count_item_field_name: String.t() | nil,
          provenance: map()
        }

  defstruct source_collection_binding_id: nil,
            public_attr_name: nil,
            parent_collection_binding_id: nil,
            parent_item_field_name: nil,
            item_fields: [],
            count_attr_name: nil,
            count_item_field_name: nil,
            provenance: %{}
end
