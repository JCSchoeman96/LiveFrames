defmodule LiveFrames.NativeGenerator.Diagnostic do
  @moduledoc false

  @type t :: %__MODULE__{
          code: String.t(),
          severity: :error,
          message: String.t(),
          metadata: map()
        }

  defstruct code: nil,
            severity: :error,
            message: nil,
            metadata: %{}

  @spec error(String.t(), String.t(), map()) :: t()
  def error(code, message, metadata \\ %{}) do
    %__MODULE__{code: code, message: message, metadata: metadata}
  end
end
