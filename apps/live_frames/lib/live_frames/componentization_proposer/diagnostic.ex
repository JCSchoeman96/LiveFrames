defmodule LiveFrames.ComponentizationProposer.Diagnostic do
  @moduledoc "Transient proposal diagnostic. Never serialized onto contract or plan artifacts."
  @type t :: %__MODULE__{
          code: String.t(),
          severity: :error,
          message: String.t(),
          path: String.t(),
          metadata: map() | nil
        }
  defstruct code: nil, severity: :error, message: nil, path: nil, metadata: nil
end
