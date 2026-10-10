defmodule LiveFrames.Behavior.Contract do
  @moduledoc """
  Source-neutral structural representation of one BehaviorContract.
  """

  alias LiveFrames.Behavior.Binding
  alias LiveFrames.IR.Identity

  @current_format_version "1.0.0"

  @type t :: %__MODULE__{
          contract_format_version: String.t(),
          design_document_identity: Identity.t() | nil,
          bindings: [Binding.t()],
          diagnostics: list(),
          provenance: map()
        }

  defstruct contract_format_version: @current_format_version,
            design_document_identity: nil,
            bindings: [],
            diagnostics: [],
            provenance: %{}

  @spec current_format_version() :: String.t()
  def current_format_version, do: @current_format_version

  @spec new(keyword()) :: t()
  def new(attrs \\ []) when is_list(attrs), do: struct(__MODULE__, attrs)
end
