defmodule LiveFrames.ComponentizationPlan.Diagnostic do
  @moduledoc """
  Structured finding emitted while validating a ComponentizationPlan.
  """

  @severities [:info, :warning, :error, :fatal]

  @type t :: %__MODULE__{
          code: String.t() | nil,
          severity: atom(),
          message: String.t() | nil,
          path: String.t() | nil,
          suggested_action: String.t() | nil,
          metadata: map()
        }

  defstruct code: nil,
            severity: :error,
            message: nil,
            path: nil,
            suggested_action: nil,
            metadata: %{}

  @spec severities() :: [atom()]
  def severities, do: @severities

  @spec blocking_severities() :: [atom()]
  def blocking_severities, do: [:error, :fatal]
end
