defmodule LiveFrames.NativeGenerator.GeneratedArtifactBundle do
  @moduledoc """
  Deterministic in-memory output of a successful native generation run.
  """

  alias LiveFrames.NativeGenerator.Artifact

  @type t :: %__MODULE__{
          contract_id: String.t(),
          design_document_sha256: String.t(),
          plan_fingerprint: String.t(),
          artifacts: [Artifact.t()]
        }

  defstruct contract_id: nil,
            design_document_sha256: nil,
            plan_fingerprint: nil,
            artifacts: []
end
