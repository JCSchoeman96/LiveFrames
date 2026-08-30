defmodule LiveFrames.IR.ResponsiveOverride do
  @moduledoc """
  A responsive style override whose breakpoint may remain unresolved.
  """

  @type resolution_status :: :resolved | :unresolved

  @type t :: %__MODULE__{
          breakpoint_id: String.t() | nil,
          source_name: String.t() | nil,
          min_width: number() | nil,
          max_width: number() | nil,
          resolution_status: resolution_status() | atom(),
          styles: map(),
          source_trace: LiveFrames.IR.SourceTrace.t() | nil
        }

  defstruct breakpoint_id: nil,
            source_name: nil,
            min_width: nil,
            max_width: nil,
            resolution_status: :resolved,
            styles: %{},
            source_trace: nil
end
