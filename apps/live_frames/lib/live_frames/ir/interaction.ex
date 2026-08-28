defmodule LiveFrames.IR.Interaction do
  @moduledoc """
  Normalized interaction intent stored in a Design IR document registry.
  """

  @type t :: %__MODULE__{
          interaction_id: String.t() | nil,
          intent: String.t() | nil,
          trigger: String.t() | nil,
          target_node_ids: [String.t()],
          parameters: map(),
          source_trace: LiveFrames.IR.SourceTrace.t() | nil
        }

  defstruct interaction_id: nil,
            intent: nil,
            trigger: nil,
            target_node_ids: [],
            parameters: %{},
            source_trace: nil
end
