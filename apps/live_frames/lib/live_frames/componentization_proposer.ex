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
  alias LiveFrames.Behavior.{ReviewResult, Serializer, Validation}
  alias LiveFrames.BehaviorAuthorityContext
  alias LiveFrames.Responsive.DesignDocumentResolver

  @evidence_plan_code "componentization_plan.binding.evidence_insufficient"
  @evidence_contract_code "component_contract.binding_evidence_insufficient"
  @construction_code "componentization_proposer.construction.failed"
  @behavior_authority_required_code "componentization_proposer.behavior_authority_required"

  @spec propose(LiveFrames.IR.DesignDocument.t(), SemanticInput.t()) :: Result.t()
  def propose(design_document, semantic_input) do
    cond do
      disposition_bearing_input?(semantic_input) ->
        propose_document(design_document, semantic_input)

      DesignDocumentResolver.has_responsive_overrides?(design_document) ->
        Result.invalid_input([authority_required_diagnostic()])

      true ->
        propose_document(design_document, semantic_input)
    end
  end

  @spec propose(
          LiveFrames.IR.DesignDocument.t(),
          SemanticInput.t(),
          LiveFrames.Responsive.BreakpointAuthority.t() | map()
        ) :: Result.t()
  def propose(design_document, semantic_input, breakpoint_authority) do
    case DesignDocumentResolver.resolve(design_document, breakpoint_authority) do
      {:ok, resolved_document} ->
        propose_document(resolved_document, semantic_input)

      {:error, diagnostic} ->
        Result.invalid_input([resolver_diagnostic(diagnostic)])
    end
  end

  defp propose_document(design_document, semantic_input) do
    case SemanticInput.validate(semantic_input, design_document) do
      {:error, diagnostics} ->
        Result.invalid_input(diagnostics, design_document)

      {:ok, canonical_input} ->
        propose_from_preflighted_document_internal(design_document, canonical_input)
    end
  end

  @doc false
  @spec propose_from_preflighted_document_internal(
          LiveFrames.IR.DesignDocument.t(),
          SemanticInput.t()
        ) :: Result.t()
  def propose_from_preflighted_document_internal(design_document, canonical_input) do
    propose_without_behavior_authority(design_document, canonical_input)
  end

  @doc false
  @spec propose_with_behavior_authority_context_internal(
          LiveFrames.IR.DesignDocument.t(),
          SemanticInput.t(),
          BehaviorAuthorityContext.t()
        ) :: Result.t()
  def propose_with_behavior_authority_context_internal(
        design_document,
        canonical_semantic_input,
        behavior_authority_context
      ) do
    case validate_behavior_authority_context(design_document, behavior_authority_context) do
      :ok ->
        propose_canonical(
          design_document,
          canonical_semantic_input,
          behavior_authority_context
        )

      {:error, diagnostics} ->
        Result.invalid_input(diagnostics, design_document)
    end
  end

  defp propose_without_behavior_authority(
         design_document,
         %SemanticInput{source_node_dispositions: dispositions}
       )
       when is_list(dispositions) and dispositions != [] do
    Result.invalid_input([behavior_authority_required_diagnostic()], design_document)
  end

  defp propose_without_behavior_authority(design_document, canonical_input),
    do: propose_canonical(design_document, canonical_input)

  defp disposition_bearing_input?(%SemanticInput{source_node_dispositions: dispositions}),
    do: is_list(dispositions) and dispositions != []

  defp disposition_bearing_input?(_semantic_input), do: false

  defp behavior_authority_required_diagnostic do
    %Diagnostic{
      code: @behavior_authority_required_code,
      severity: :error,
      path: "behavior_authority_context",
      message: "source node dispositions require validated Behavior authority"
    }
  end

  defp validate_behavior_authority_context(
         design_document,
         %BehaviorAuthorityContext{} = context
       ) do
    with :ok <- validate_context_shape(context),
         {:ok, _validated} <-
           context_validation(
             :contract_binding,
             Validation.validate_structure(design_document, context.behavior_contract)
           ),
         {:ok, behavior_contract_digest} <-
           context_validation(:contract_digest, Serializer.digest(context.behavior_contract)),
         :ok <-
           context_value_matches(
             :contract_digest,
             behavior_contract_digest,
             context.behavior_contract_digest
           ),
         {:ok, behavior_review_result_id} <-
           context_validation(
             :review_result_id,
             ReviewResult.id(context.selected_behavior_review_result)
           ),
         :ok <-
           context_value_matches(
             :review_result_id,
             behavior_review_result_id,
             context.behavior_review_result_id
           ),
         {:ok, _approved_review} <-
           context_validation(
             :review_approval,
             ReviewResult.require_approved(
               [context.selected_behavior_review_result],
               context.behavior_contract
             )
           ) do
      :ok
    else
      {:error, diagnostic} -> {:error, [diagnostic]}
    end
  end

  defp validate_behavior_authority_context(_design_document, _context),
    do: {:error, [behavior_authority_context_diagnostic(:shape, [])]}

  defp validate_context_shape(context) do
    expected_keys = [
      :__struct__,
      :behavior_contract,
      :behavior_contract_digest,
      :selected_behavior_review_result,
      :behavior_review_result_id
    ]

    if Enum.sort(Map.keys(context)) == Enum.sort(expected_keys),
      do: :ok,
      else: {:error, behavior_authority_context_diagnostic(:shape, [])}
  end

  defp context_validation(_stage, :ok), do: {:ok, :ok}
  defp context_validation(_stage, {:ok, value}), do: {:ok, value}

  defp context_validation(stage, {:error, diagnostics}),
    do: {:error, behavior_authority_context_diagnostic(stage, diagnostics)}

  defp context_value_matches(_stage, value, value), do: :ok

  defp context_value_matches(stage, _actual, _expected),
    do: {:error, behavior_authority_context_diagnostic(stage, [])}

  defp behavior_authority_context_diagnostic(stage, diagnostics) do
    diagnostic_codes =
      diagnostics
      |> Enum.map(&Map.get(&1, :code))
      |> Enum.filter(&is_binary/1)

    %Diagnostic{
      code: "componentization_proposer.behavior_authority_context.invalid",
      severity: :error,
      path: "behavior_authority_context." <> Atom.to_string(stage),
      message: "Behavior authority context failed validation at #{stage}",
      metadata: %{"behavior_diagnostic_codes" => diagnostic_codes}
    }
  end

  defp propose_canonical(design_document, canonical_input, behavior_authority_context \\ nil) do
    construction_result =
      if canonical_input.source_node_dispositions == [] do
        Construction.build(design_document, canonical_input)
      else
        Construction.build(
          design_document,
          canonical_input,
          behavior_authority_context
        )
      end

    case construction_result do
      {:error, diagnostics} ->
        Result.construction_failed(diagnostics, design_document)

      {:ok, contract, plan} ->
        validate_references(contract, plan, design_document)
    end
  rescue
    error ->
      Result.construction_failed(
        [construction_diagnostic("construction", Exception.message(error))],
        design_document
      )
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

    finalize(contract, plan, outcome, design_document)
  end

  defp finalize(contract, plan, outcome, design_document) do
    case ComponentContract.validate(contract) do
      :ok ->
        case ComponentizationPlan.validate(plan) do
          :ok ->
            Result.successful(contract, plan, outcome, design_document)

          {:error, diagnostics} ->
            Result.construction_failed(construction_diagnostics(diagnostics), design_document)
        end

      {:error, diagnostics} ->
        Result.construction_failed(construction_diagnostics(diagnostics), design_document)
    end
  end

  defp authority_required_diagnostic do
    %Diagnostic{
      code: "componentization_proposer.breakpoint_authority_required",
      severity: :error,
      path: "breakpoint_authority",
      message: "responsive overrides require accepted breakpoint authority"
    }
  end

  defp resolver_diagnostic(diagnostic) do
    %Diagnostic{
      code: diagnostic.code,
      severity: diagnostic.severity,
      message: diagnostic.message,
      path: "breakpoint_authority",
      metadata: diagnostic.metadata
    }
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
