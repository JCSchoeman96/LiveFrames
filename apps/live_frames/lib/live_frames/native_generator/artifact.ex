defmodule LiveFrames.NativeGenerator.Artifact do
  @moduledoc false

  @type kind :: :elixir_module

  @type t :: %__MODULE__{
          kind: kind(),
          path: String.t(),
          content: String.t()
        }

  defstruct kind: :elixir_module,
            path: nil,
            content: nil
end
