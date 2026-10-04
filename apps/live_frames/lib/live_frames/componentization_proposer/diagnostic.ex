defmodule LiveFrames.ComponentizationProposer.Diagnostic do
  @moduledoc "Transient semantic-input finding. Never serialized onto contract or plan artifacts."
  @type t :: %__MODULE__{
          code: String.t(),
          severity: :error,
          message: String.t(),
          path: String.t()
        }
  defstruct code: nil, severity: :error, message: nil, path: nil
end
