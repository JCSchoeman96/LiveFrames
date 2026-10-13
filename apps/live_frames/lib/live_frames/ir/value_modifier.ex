defmodule LiveFrames.IR.ValueModifier do
  @moduledoc "Closed ValueBinding modifier variants for Design IR 4.0.0."

  defmodule None do
    @moduledoc false
    defstruct []
    @type t :: %__MODULE__{}
  end

  defmodule Opaque do
    @moduledoc false
    defstruct []
    @type t :: %__MODULE__{}
  end

  defmodule Resolved do
    @moduledoc false
    @enforce_keys [:kind, :arguments]
    defstruct [:kind, :arguments]
    @type t :: %__MODULE__{kind: :word_limit, arguments: map()}
  end

  @type t :: None.t() | Opaque.t() | Resolved.t()
end
