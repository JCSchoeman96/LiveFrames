defmodule LiveFrames.ComponentizationPlan.RenderProjection do
  @moduledoc """
  Placement of one unbound public attr or slot in a Design IR subtree.
  """

  @render_roles [
    :text_content,
    :asset_src,
    :asset_alt,
    :link_url,
    :heading_level,
    :root_id,
    :root_class,
    :root_global_attrs,
    :subtree_slot
  ]

  @type t :: %__MODULE__{
          public_attr_name: String.t() | nil,
          public_slot_name: String.t() | nil,
          target_node_id: String.t() | nil,
          render_role: atom() | nil
        }

  defstruct public_attr_name: nil,
            public_slot_name: nil,
            target_node_id: nil,
            render_role: nil

  @spec render_roles() :: [atom()]
  def render_roles, do: @render_roles
end
