defmodule LiveFrames.IR.DesignDocument do
  @moduledoc """
  Root container for a validated, source-independent Design IR document.
  """

  @current_ir_version "1.0.0"

  @type t :: %__MODULE__{
          ir_version: String.t(),
          source_metadata: map(),
          token_set: map(),
          root_nodes: [LiveFrames.IR.DesignNode.t()],
          assets: %{optional(String.t()) => LiveFrames.IR.AssetReference.t()},
          interactions: %{optional(String.t()) => LiveFrames.IR.Interaction.t()},
          diagnostics: [LiveFrames.IR.Diagnostic.t()],
          provenance: map()
        }

  defstruct ir_version: @current_ir_version,
            source_metadata: %{},
            token_set: %{},
            root_nodes: [],
            assets: %{},
            interactions: %{},
            diagnostics: [],
            provenance: %{}

  @spec current_ir_version() :: String.t()
  def current_ir_version, do: @current_ir_version

  @spec new(keyword()) :: t()
  def new(attrs \\ []) when is_list(attrs), do: struct(__MODULE__, attrs)
end
