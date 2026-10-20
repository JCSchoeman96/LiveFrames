defmodule LiveFrames.ComponentReview do
  @moduledoc """
  Pure reviewer transitions for a ComponentContract, ComponentizationPlan, and DesignDocument.
  """

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Diagnostic, as: ContractDiagnostic
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.Diagnostic, as: PlanDiagnostic
  alias LiveFrames.ComponentReviewResult
  alias LiveFrames.Behavior.Contract, as: BehaviorContract
  alias LiveFrames.Behavior.ReviewResult, as: BehaviorReviewResult
  alias LiveFrames.IR.DesignDocument

  @spec validate_generation_prerequisites(term(), term(), term()) ::
          :ok | {:error, [PlanDiagnostic.t()]}
  def validate_generation_prerequisites(contract, plan, design_document) do
    ComponentizationPlan.validate_generation_prerequisites(plan, contract, design_document)
  end

  @spec approve(term(), term(), term()) :: {:ok, ComponentContract.t()} | {:error, list()}
  def approve(contract, plan, design_document) do
    with :ok <- total_shape_guard(contract, plan, design_document),
         :ok <- reject_disposition_plan(plan),
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

  @doc """
  Approves a disposition-bearing candidate and returns its matching ComponentReviewResult.

  Call this only after the human reviewer has examined the cited evidence, confirmed that Behavior
  owns the source runtime responsibility, and confirmed that no separate presentation, content,
  accessibility, or generated-DOM role is required. This function records the reviewer identity
  and evidence references. It does not infer those judgments from their values.
  """
  @spec approve_with_result(
          term(),
          term(),
          term(),
          term(),
          term(),
          term(),
          term(),
          term()
        ) :: {:ok, ComponentContract.t(), ComponentReviewResult.t()} | {:error, list()}
  def approve_with_result(
        contract,
        plan,
        design_document,
        behavior_contract,
        selected_behavior_review_result,
        reviewer_identity,
        reviewed_at,
        evidence_refs
      ) do
    with :ok <- total_shape_guard(contract, plan, design_document),
         :ok <- require_proposed(contract),
         :ok <- validate_candidate_identity(contract, plan, design_document),
         :ok <- require_disposition_plan(plan),
         :ok <- validate_behavior_shapes(behavior_contract, selected_behavior_review_result),
         :ok <-
           ComponentizationPlan.validate_generation_prerequisites_with_behavior_authority(
             plan,
             contract,
             design_document,
             behavior_contract,
             selected_behavior_review_result
           ),
         {:ok, approved_contract, review_result} <-
           approved_result(
             contract,
             plan,
             design_document,
             reviewer_identity,
             reviewed_at,
             evidence_refs
           ),
         :ok <-
           ComponentizationPlan.validate_for_generation_with_behavior_authority(
             plan,
             approved_contract,
             design_document,
             behavior_contract,
             selected_behavior_review_result
           ),
         :ok <-
           ComponentReviewResult.validate_against(
             review_result,
             approved_contract,
             plan,
             design_document
           ) do
      {:ok, approved_contract, review_result}
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

  defp reject_disposition_plan(%ComponentizationPlan{node_dispositions: [_ | _]}) do
    {:error,
     [
       transition_error(
         "disposition plans require approve_with_result/8 and their matching review result"
       )
     ]}
  end

  defp reject_disposition_plan(_plan), do: :ok

  defp require_disposition_plan(%ComponentizationPlan{node_dispositions: [_ | _]}), do: :ok

  defp require_disposition_plan(_plan) do
    {:error,
     [
       transition_error("approve_with_result/8 requires a non-empty node_dispositions list")
     ]}
  end

  defp validate_behavior_shapes(behavior_contract, selected_behavior_review_result) do
    cond do
      not is_struct(behavior_contract, BehaviorContract) ->
        {:error, [transition_error("expected a BehaviorContract")]}

      not is_struct(selected_behavior_review_result, BehaviorReviewResult) ->
        {:error, [transition_error("expected one selected BehaviorReviewResult")]}

      true ->
        :ok
    end
  end

  defp approved_result(
         contract,
         plan,
         design_document,
         reviewer_identity,
         reviewed_at,
         evidence_refs
       ) do
    approved_contract = %{contract | approval_status: :approved}

    with {:ok, contract_bytes} <- ComponentContract.encode(approved_contract),
         {:ok, plan_bytes} <- ComponentizationPlan.encode(plan),
         {:ok, document_digest} <- ComponentizationPlan.design_document_sha256(design_document) do
      review_result = %ComponentReviewResult{
        review_format_version: "1.0.0",
        component_contract_id: approved_contract.contract_id,
        component_contract_digest_algorithm: "sha-256",
        component_contract_digest: sha256(contract_bytes),
        design_document_sha256: document_digest,
        componentization_plan_digest_algorithm: "sha-256",
        componentization_plan_digest: sha256(plan_bytes),
        decision: "approved",
        reviewer_identity: reviewer_identity,
        reviewed_at: reviewed_at,
        evidence_refs: evidence_refs
      }

      case ComponentReviewResult.validate(review_result) do
        :ok -> {:ok, approved_contract, review_result}
        {:error, diagnostics} -> {:error, diagnostics}
      end
    else
      {:error, diagnostics} -> {:error, diagnostics}
    end
  end

  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

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
