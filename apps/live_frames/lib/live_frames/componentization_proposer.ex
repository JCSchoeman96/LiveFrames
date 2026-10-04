defmodule LiveFrames.ComponentizationProposer do
  @moduledoc """
  Builds a deterministic ComponentContract and ComponentizationPlan proposal.
  """

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Diagnostic, as: ContractDiagnostic
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationProposer.Construction
  alias LiveFrames.ComponentizationProposer.Diagnostic
  alias LiveFrames.ComponentizationProposer.Result
  alias LiveFrames.ComponentizationProposer.SemanticInput

  @evidence_plan_code "componentization_plan.binding.evidence_insufficient"
  @evidence_contract_code "component_contract.binding_evidence_insufficient"
  @construction_code "componentization_proposer.construction.failed"

  @spec propose(LiveFrames.IR.DesignDocument.t(), SemanticInput.t()) :: Result.t()
  def propose(design_document, semantic_input) do
    case SemanticInput.validate(semantic_input, design_document) do
      {:error, diagnostics} ->
        Result.invalid_input(diagnostics)

      {:ok, canonical_input} ->
        propose_canonical(design_document, canonical_input)
    end
  end

  defp propose_canonical(design_document, canonical_input) do
    case Construction.build(design_document, canonical_input) do
      {:error, diagnostics} ->
        Result.construction_failed(diagnostics)

      {:ok, contract, plan} ->
        validate_references(contract, plan, design_document)
    end
  rescue
    error ->
      Result.construction_failed([
        construction_diagnostic("construction", Exception.message(error))
      ])
  end

  defp validate_references(contract, plan, design_document) do
    contract_reference_diagnostics =
      diagnostics_from(ComponentContract.validate_ir_references(contract, design_document))

    plan_reference_diagnostics =
      diagnostics_from(ComponentizationPlan.validate_references(plan, contract, design_document))

    candidate_contract_diagnostics =
      contract.diagnostics
      |> Kernel.++(contract_reference_diagnostics)
      |> Kernel.++(evidence_counterparts(plan_reference_diagnostics))

    candidate_plan_diagnostics =
      plan.diagnostics
      |> Kernel.++(plan_reference_diagnostics)

    outcome = classify(contract, candidate_contract_diagnostics, candidate_plan_diagnostics)

    contract = %{
      contract
      | approval_status: outcome_status(outcome),
        diagnostics: canonicalize_diagnostics(candidate_contract_diagnostics)
    }

    plan = %{plan | diagnostics: canonicalize_diagnostics(candidate_plan_diagnostics)}

    finalize(contract, plan, outcome)
  end

  defp finalize(contract, plan, outcome) do
    case ComponentContract.validate(contract) do
      :ok ->
        case ComponentizationPlan.validate(plan) do
          :ok ->
            Result.successful(contract, plan, outcome)

          {:error, diagnostics} ->
            Result.construction_failed(construction_diagnostics(diagnostics))
        end

      {:error, diagnostics} ->
        Result.construction_failed(construction_diagnostics(diagnostics))
    end
  end

  defp classify(contract, contract_diagnostics, plan_diagnostics) do
    blocking? =
      Enum.any?(contract_diagnostics ++ plan_diagnostics, fn diagnostic ->
        Map.get(diagnostic, :severity) in [:error, :fatal]
      end)

    if blocking? or static_item_review?(contract), do: :needs_review, else: :proposed
  end

  defp outcome_status(:needs_review), do: :needs_review
  defp outcome_status(:proposed), do: :proposed

  defp static_item_review?(contract) do
    covered =
      Enum.reduce(contract.binding_projections, MapSet.new(), fn projection, identities ->
        case projection do
          %{
            projection_kind: :collection_item_field,
            source_binding_kind: :value,
            source_collection_binding_id: collection_id,
            item_field_name: field_name
          }
          when is_binary(collection_id) and is_binary(field_name) ->
            MapSet.put(identities, {collection_id, field_name})

          %{
            projection_kind: :collection_item_field,
            source_binding_kind: kind,
            parent_collection_binding_id: collection_id,
            parent_item_field_name: field_name
          }
          when kind in [:collection, :value] and is_binary(collection_id) and
                 is_binary(field_name) ->
            MapSet.put(identities, {collection_id, field_name})

          _ ->
            identities
        end
      end)

    Enum.any?(contract.collection_inputs, fn collection_input ->
      Enum.any?(collection_input.item_fields, fn item_field ->
        not MapSet.member?(
          covered,
          {collection_input.source_collection_binding_id, item_field.name}
        )
      end)
    end)
  end

  defp evidence_counterparts(diagnostics) do
    diagnostics
    |> Enum.filter(&(&1.code == @evidence_plan_code))
    |> Enum.map(fn diagnostic ->
      %ContractDiagnostic{
        code: @evidence_contract_code,
        severity: :error,
        message: "value binding has insufficient evidence",
        path: diagnostic.path
      }
    end)
  end

  defp diagnostics_from(:ok), do: []
  defp diagnostics_from({:error, diagnostics}), do: diagnostics

  defp construction_diagnostics(diagnostics) do
    diagnostics
    |> Enum.map(fn diagnostic ->
      %Diagnostic{
        code: @construction_code,
        severity: :error,
        path: Map.get(diagnostic, :path) || Map.get(diagnostic, :code),
        message:
          "#{Map.get(diagnostic, :code) || "construction"}: #{Map.get(diagnostic, :message) || "construction failed"}"
      }
    end)
    |> case do
      [] -> [construction_diagnostic("construction", "construction failed")]
      values -> values
    end
  end

  defp construction_diagnostic(path, message) do
    %Diagnostic{
      code: @construction_code,
      severity: :error,
      path: path,
      message: message
    }
  end

  defp dedupe_diagnostics(diagnostics), do: Enum.uniq(diagnostics)

  defp canonicalize_diagnostics(diagnostics) do
    diagnostics
    |> dedupe_diagnostics()
    |> sort_diagnostics()
  end

  defp sort_diagnostics(diagnostics) do
    Enum.sort_by(diagnostics, fn diagnostic ->
      {
        Map.get(diagnostic, :code) || "",
        if(Map.get(diagnostic, :path) in [nil, ""], do: 1, else: 0),
        Map.get(diagnostic, :path) || "",
        Map.get(diagnostic, :message) || ""
      }
    end)
  end
end
