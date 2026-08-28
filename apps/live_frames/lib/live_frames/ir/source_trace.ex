defmodule LiveFrames.IR.SourceTrace do
  @moduledoc """
  Generic trace information retained from an adapter and its source.
  """

  @type t :: %__MODULE__{
          source_type: String.t() | nil,
          source_id: String.t() | nil,
          source_path: String.t() | nil,
          source_name: String.t() | nil,
          global_classes: [String.t()],
          source_settings: map(),
          adapter: String.t() | nil,
          adapter_version: String.t() | nil,
          inference: String.t() | nil,
          metadata: map()
        }

  defstruct source_type: nil,
            source_id: nil,
            source_path: nil,
            source_name: nil,
            global_classes: [],
            source_settings: %{},
            adapter: nil,
            adapter_version: nil,
            inference: nil,
            metadata: %{}
end
