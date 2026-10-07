defmodule LiveFrames.ComponentReview do
  @moduledoc """
  Pure reviewer transitions for a ComponentContract, ComponentizationPlan, and DesignDocument.
  """

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Diagnostic, as: ContractDiagnostic
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.Diagnostic, as: PlanDiagnostic
  alias LiveFrames.IR.DesignDocument

  @spec validate_generation_prerequisites(term(), term(), term()) ::
          :ok | {:error, [PlanDiagnostic.t()]}
  def validate_generation_prerequisites(contract, plan, design_document) do
    ComponentizationPlan.validate_generation_prerequisites(plan, contract, design_document)
  end

  @spec approve(term(), term(), term()) :: {:ok, ComponentContract.t()} | {:error, list()}
  def approve(contract, plan, design_document) do
    with :ok <- total_shape_guard(contract, plan, design_document),
         :ok <- require_proposed(contract),
         :ok <- validate_generation_prerequisites(contract, plan, design_document) do
      {:ok, %{contract | approval_status: :approved}}
    end
  rescue
    _error ->
      {:error, [malformed_review_input()]}
  catch
    _kind, _reason ->
      {:error, [malformed_review_input()]}
  end

  @spec reject(term(), term(), term()) :: {:ok, ComponentContract.t()} | {:error, list()}
  def reject(contract, plan, design_document) do
    with :ok <- total_shape_guard(contract, plan, design_document),
         :ok <- require_rejectable(contract),
         :ok <- validate_candidate_identity(contract, plan, design_document) do
      {:ok, %{contract | approval_status: :rejected}}
    end
  rescue
    _error ->
      {:error, [malformed_review_input()]}
  catch
    _kind, _reason ->
      {:error, [malformed_review_input()]}
  end

  defp total_shape_guard(contract, plan, design_document) do
    cond do
      not is_struct(contract, ComponentContract) ->
        {:error, [contract_shape_error()]}

      not is_struct(plan, ComponentizationPlan) ->
        {:error, [plan_shape_error()]}

      not is_struct(design_document, DesignDocument) ->
        {:error, [design_document_shape_error()]}

      true ->
        :ok
    end
  end

  defp require_proposed(%ComponentContract{approval_status: :proposed}), do: :ok

  defp require_proposed(_contract) do
    {:error, [transition_error("only proposed candidates may be approved")]}
  end

  defp require_rejectable(%ComponentContract{approval_status: status})
       when status in [:proposed, :needs_review],
       do: :ok

  defp require_rejectable(_contract) do
    {:error, [transition_error("candidate cannot be rejected from its current approval_status")]}
  end

  defp validate_candidate_identity(contract, plan, design_document) do
    diagnostics =
      [
        ComponentContract.validate(contract),
        ComponentizationPlan.validate(plan),
        LiveFrames.IR.validate(design_document)
      ]
      |> Enum.flat_map(fn
        :ok -> []
        {:error, values} -> values
      end)

    if diagnostics == [] do
      validate_candidate_links(contract, plan, design_document)
    else
      {:error, diagnostics}
    end
  end

  defp validate_candidate_links(contract, plan, design_document) do
    cond do
      plan.contract_id != contract.contract_id ->
        {:error,
         [
           plan_error(
             "componentization_plan.contract.mismatch",
             "plan contract_id does not match the supplied ComponentContract",
             "contract_id"
           )
         ]}

      true ->
        case ComponentizationPlan.design_document_sha256(design_document) do
          {:ok, fingerprint} when fingerprint == plan.design_document_sha256 ->
            :ok

          {:ok, _fingerprint} ->
            {:error,
             [
               plan_error(
                 "componentization_plan.design_document.mismatch",
                 "plan fingerprint does not match the supplied DesignDocument",
                 "design_document_sha256"
               )
             ]}

          {:error, diagnostics} ->
            {:error, diagnostics}
        end
    end
  end

  defp transition_error(message) do
    %ContractDiagnostic{
      code: "component_contract.approval_blocked",
      severity: :error,
      message: message
    }
  end

  defp malformed_review_input do
    %ContractDiagnostic{
      code: "component_contract.contract.invalid",
      severity: :error,
      message: "review inputs are malformed"
    }
  end

  defp contract_shape_error do
    %ContractDiagnostic{
      code: "component_contract.contract.invalid",
      severity: :error,
      message: "expected a ComponentContract struct"
    }
  end

  defp plan_shape_error do
    %PlanDiagnostic{
      code: "componentization_plan.plan.invalid",
      severity: :error,
      message: "expected a ComponentizationPlan struct"
    }
  end

  defp design_document_shape_error do
    %PlanDiagnostic{
      code: "componentization_plan.design_document.fingerprint_invalid",
      severity: :error,
      message: "expected a DesignDocument struct"
    }
  end

  defp plan_error(code, message, path) do
    %PlanDiagnostic{code: code, severity: :error, message: message, path: path}
  end
end
