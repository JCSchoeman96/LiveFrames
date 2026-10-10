defmodule LiveFrames.Behavior.Diagnostic do
  @moduledoc """
  A persisted structural, identity, reference, or semantic diagnostic.
  """

  @severities ~w(info warning error fatal)
  @categories ~w(structure identity reference semantic accessibility provenance projection realization runtime)

  @type t :: %__MODULE__{
          code: String.t() | nil,
          severity: String.t() | nil,
          category: String.t() | nil,
          binding_id: String.t() | nil,
          node_id: String.t() | nil,
          evidence_id: String.t() | nil,
          message: String.t() | nil,
          suggested_action: String.t() | nil,
          source_trace: LiveFrames.IR.SourceTrace.t() | nil
        }

  defstruct [
    :code,
    :severity,
    :category,
    :binding_id,
    :node_id,
    :evidence_id,
    :message,
    :suggested_action,
    :source_trace
  ]

  @spec severities() :: [String.t()]
  def severities, do: @severities

  @spec categories() :: [String.t()]
  def categories, do: @categories
end
