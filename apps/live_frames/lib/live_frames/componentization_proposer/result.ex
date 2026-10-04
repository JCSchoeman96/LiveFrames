defmodule LiveFrames.ComponentizationProposer.Result do
  @moduledoc """
  Process result for one compile-time componentization proposal attempt.
  """

  @type outcome :: :invalid_input | :construction_failed | :needs_review | :proposed

  @type t :: %__MODULE__{
          contract: LiveFrames.ComponentContract.t() | nil,
          plan: LiveFrames.ComponentizationPlan.t() | nil,
          input_diagnostics: [LiveFrames.ComponentizationProposer.Diagnostic.t()],
          construction_diagnostics: [LiveFrames.ComponentizationProposer.Diagnostic.t()],
          outcome: outcome()
        }

  defstruct contract: nil,
            plan: nil,
            input_diagnostics: [],
            construction_diagnostics: [],
            outcome: nil

  @spec invalid_input([LiveFrames.ComponentizationProposer.Diagnostic.t()]) :: t()
  def invalid_input(diagnostics) when is_list(diagnostics) do
    %__MODULE__{
      input_diagnostics: diagnostics,
      outcome: :invalid_input
    }
  end

  @spec construction_failed([LiveFrames.ComponentizationProposer.Diagnostic.t()]) :: t()
  def construction_failed(diagnostics) when is_list(diagnostics) do
    %__MODULE__{
      construction_diagnostics: diagnostics,
      outcome: :construction_failed
    }
  end

  @spec successful(
          LiveFrames.ComponentContract.t(),
          LiveFrames.ComponentizationPlan.t(),
          :needs_review | :proposed
        ) :: t()
  def successful(contract, plan, outcome) when outcome in [:needs_review, :proposed] do
    %__MODULE__{contract: contract, plan: plan, outcome: outcome}
  end
end
