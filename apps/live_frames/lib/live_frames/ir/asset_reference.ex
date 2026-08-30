defmodule LiveFrames.IR.AssetReference do
  @moduledoc """
  Canonical asset record stored in a Design IR document registry.
  """

  @type status :: :resolved | :unresolved

  @type t :: %__MODULE__{
          asset_id: String.t() | nil,
          kind: String.t() | nil,
          uri: String.t() | nil,
          alt: String.t() | nil,
          status: status() | atom(),
          metadata: map(),
          source_trace: LiveFrames.IR.SourceTrace.t() | nil
        }

  defstruct asset_id: nil,
            kind: nil,
            uri: nil,
            alt: nil,
            status: :resolved,
            metadata: %{},
            source_trace: nil
end
