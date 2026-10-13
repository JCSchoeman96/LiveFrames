defmodule LiveFrames.IR.ValueBinding do
  @moduledoc """
  Caller-supplied frontend value binding stored in a Design IR registry.
  """

  @target_kinds [:text, :asset, :link_url]
  @value_kinds [:field, :collection_count]
  @scopes [:collection_item, :site, :collection]
  @normalization_statuses [:normalized, :evidence_insufficient]

  alias LiveFrames.IR.ValueModifier

  @type target_kind :: :text | :asset | :link_url
  @type value_kind :: :field | :collection_count
  @type scope :: :collection_item | :site | :collection
  @type normalization_status :: :normalized | :evidence_insufficient

  @enforce_keys [:modifier]
  @type t :: %__MODULE__{
          value_binding_id: String.t() | nil,
          target_node_id: String.t() | nil,
          target_kind: target_kind() | atom(),
          value_kind: value_kind() | atom(),
          scope: scope() | atom(),
          value_key: String.t() | nil,
          collection_binding_id: String.t() | nil,
          modifier: ValueModifier.t() | atom(),
          normalization_status: normalization_status() | atom(),
          source_trace: LiveFrames.IR.SourceTrace.t() | nil
        }

  defstruct value_binding_id: nil,
            target_node_id: nil,
            target_kind: nil,
            value_kind: nil,
            scope: nil,
            value_key: nil,
            collection_binding_id: nil,
            modifier: nil,
            normalization_status: :normalized,
            source_trace: nil

  @spec target_kinds() :: [atom()]
  def target_kinds, do: @target_kinds

  @spec value_kinds() :: [atom()]
  def value_kinds, do: @value_kinds

  @spec scopes() :: [atom()]
  def scopes, do: @scopes

  @spec normalization_statuses() :: [atom()]
  def normalization_statuses, do: @normalization_statuses
end
