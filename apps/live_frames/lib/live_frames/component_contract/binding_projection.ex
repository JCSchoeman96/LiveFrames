defmodule LiveFrames.ComponentContract.BindingProjection do
  @moduledoc """
  Compiler metadata linking Design IR bindings to public contract surfaces.
  """

  @source_binding_kinds [:collection, :value]
  @projection_kinds [
    :scalar_attr,
    :collection_attr,
    :collection_item_field,
    :collection_count_attr,
    :slot
  ]

  @type t :: %__MODULE__{
          source_binding_kind: atom() | nil,
          source_binding_id: String.t() | nil,
          projection_kind: atom() | nil,
          public_attr_name: String.t() | nil,
          public_slot_name: String.t() | nil,
          source_collection_binding_id: String.t() | nil,
          parent_collection_binding_id: String.t() | nil,
          item_field_name: String.t() | nil,
          parent_item_field_name: String.t() | nil,
          target_node_id: String.t() | nil
        }

  defstruct source_binding_kind: nil,
            source_binding_id: nil,
            projection_kind: nil,
            public_attr_name: nil,
            public_slot_name: nil,
            source_collection_binding_id: nil,
            parent_collection_binding_id: nil,
            item_field_name: nil,
            parent_item_field_name: nil,
            target_node_id: nil

  @spec source_binding_kinds() :: [atom()]
  def source_binding_kinds, do: @source_binding_kinds

  @spec projection_kinds() :: [atom()]
  def projection_kinds, do: @projection_kinds
end
