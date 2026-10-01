defmodule LiveFrames.IR.CollectionBinding do
  @moduledoc """
  Frontend collection input and repeat boundary stored in a Design IR registry.
  """

  @normalization_statuses [:normalized]

  @type normalization_status :: :normalized

  @type t :: %__MODULE__{
          collection_binding_id: String.t() | nil,
          owner_node_id: String.t() | nil,
          repeat_root_node_id: String.t() | nil,
          parent_collection_binding_id: String.t() | nil,
          normalization_status: normalization_status() | atom(),
          source_trace: LiveFrames.IR.SourceTrace.t() | nil
        }

  defstruct collection_binding_id: nil,
            owner_node_id: nil,
            repeat_root_node_id: nil,
            parent_collection_binding_id: nil,
            normalization_status: :normalized,
            source_trace: nil

  @spec normalization_statuses() :: [atom()]
  def normalization_statuses, do: @normalization_statuses
end
