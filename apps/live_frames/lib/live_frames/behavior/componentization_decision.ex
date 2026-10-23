defmodule LiveFrames.Behavior.ComponentizationDecision do
  @moduledoc """
  Ephemeral behavior-aware gate for an explicit componentization candidate.
  """

  alias LiveFrames.Behavior.BindingContainment
  alias LiveFrames.Behavior.Contract
  alias LiveFrames.Behavior.Diagnostic
  alias LiveFrames.Behavior.ReviewResult
  alias LiveFrames.Behavior.Serializer
  alias LiveFrames.Behavior.Validation
  alias LiveFrames.BehaviorAuthorityContext
  alias LiveFrames.ComponentizationProposer
  alias LiveFrames.ComponentizationProposer.Diagnostic, as: ProposerDiagnostic
  alias LiveFrames.ComponentizationProposer.SemanticInput
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.Identity
  alias LiveFrames.Responsive.DesignDocumentResolver

  @type disposition :: :contained | :outside_candidate | :split | :unresolved

  @type t :: %__MODULE__{
          outcome: :admissible | :rejected,
          design_document_identity: Identity.t(),
          behavior_contract_digest: String.t(),
          behavior_review_result_id: String.t(),
          semantic_input: SemanticInput.t(),
          boundary_node_id: String.t(),
          binding_dispositions: [%{binding_id: String.t(), disposition: disposition()}],
          diagnostics: [Diagnostic.t()]
        }

  defstruct [
    :outcome,
    :design_document_identity,
    :behavior_contract_digest,
    :behavior_review_result_id,
    :semantic_input,
    :boundary_node_id,
    :binding_dispositions,
    :diagnostics
  ]

  @spec reference_index(DesignDocument.t(), Contract.t()) ::
          {:ok, %{optional(String.t()) => MapSet.t(atom())}}
          | {:error, [Diagnostic.t()]}
  def reference_index(design_document, behavior_contract),
    do: BindingContainment.reference_index(design_document, behavior_contract)

  @spec authority_context(term(), term(), term()) ::
          {:ok, BehaviorAuthorityContext.t()}
          | {:error, {:prerequisite, atom(), list()}}
  def authority_context(design_document, behavior_contract, selected_behavior_review_result) do
    with :ok <- structure_prerequisite(design_document, behavior_contract),
         {:ok, behavior_contract_digest} <-
           prerequisite(:behavior_contract, Serializer.digest(behavior_contract)),
         {:ok, selected_review} <-
           prerequisite(
             :behavior_review,
             ReviewResult.require_approved(
               [selected_behavior_review_result],
               behavior_contract
             )
           ),
         {:ok, behavior_review_result_id} <-
           prerequisite(:behavior_review, ReviewResult.id(selected_review)) do
      {:ok,
       %BehaviorAuthorityContext{
         behavior_contract: behavior_contract,
         behavior_contract_digest: behavior_contract_digest,
         selected_behavior_review_result: selected_review,
         behavior_review_result_id: behavior_review_result_id
       }}
    end
  end

  @spec propose(term(), term(), term(), term()) ::
          {:ok, t(), term()} | {:error, t()} | {:error, {:prerequisite, atom(), list()}}
  def propose(design_document, behavior_contract, behavior_review_result, semantic_input) do
    if DesignDocumentResolver.has_responsive_overrides?(design_document) do
      result = ComponentizationProposer.propose(design_document, semantic_input)
      {:error, {:prerequisite, :breakpoint_authority, result.input_diagnostics}}
    else
      propose_after_preflight(
        design_document,
        behavior_contract,
        behavior_review_result,
        semantic_input,
        &ComponentizationProposer.propose_from_preflighted_document_internal/2
      )
    end
  end

  @spec propose(term(), term(), term(), term(), term()) ::
          {:ok, t(), term()} | {:error, t()} | {:error, {:prerequisite, atom(), list()}}
  def propose(
        design_document,
        behavior_contract,
        behavior_review_result,
        semantic_input,
        breakpoint_authority
      ) do
    case DesignDocumentResolver.resolve(design_document, breakpoint_authority) do
      {:error, diagnostic} ->
        {:error, {:prerequisite, :breakpoint_authority, [proposal_diagnostic(diagnostic)]}}

      {:ok, resolved_document} ->
        propose_after_preflight(
          resolved_document,
          behavior_contract,
          behavior_review_result,
          semantic_input,
          &ComponentizationProposer.propose_from_preflighted_document_internal/2
        )
    end
  end

  defp propose_after_preflight(
         design_document,
         behavior_contract,
         behavior_review_result,
         semantic_input,
         proposal_builder
       ) do
    with {:ok, document_identity} <-
           prerequisite(:design_document, Identity.from_document(design_document)),
         {:ok, contract_digest} <-
           prerequisite(:behavior_contract, Serializer.digest(behavior_contract)),
         {:ok, review_result} <-
           prerequisite(
             :behavior_review,
             ReviewResult.require_approved([behavior_review_result], behavior_contract)
           ),
         {:ok, review_result_id} <-
           prerequisite(:behavior_review, ReviewResult.id(review_result)),
         {:ok, canonical_input} <-
           prerequisite(:semantic_input, SemanticInput.validate(semantic_input, design_document)) do
      context_result =
        authority_context_for_input(
          design_document,
          behavior_contract,
          review_result,
          canonical_input
        )

      structural = structural_result(context_result, design_document, behavior_contract)
      boundary_node_id = canonical_input.boundary.boundary_node_id
      containment_context = BindingContainment.prepare(design_document, boundary_node_id)

      binding_dispositions =
        behavior_contract.bindings
        |> Enum.map(fn binding ->
          %{
            binding_id: binding.binding_id,
            disposition: BindingContainment.classify_binding(binding, containment_context)
          }
        end)
        |> Enum.sort_by(& &1.binding_id)

      diagnostics =
        (structural_diagnostics(structural) ++
           Enum.flat_map(binding_dispositions, &containment_diagnostic/1))
        |> Enum.sort_by(&{&1.binding_id || "", &1.code || "", &1.node_id || "", &1.message || ""})

      outcome =
        if structural == :ok and
             Enum.all?(
               binding_dispositions,
               &(&1.disposition in [:contained, :outside_candidate])
             ) do
          :admissible
        else
          :rejected
        end

      decision = %__MODULE__{
        outcome: outcome,
        design_document_identity: document_identity,
        behavior_contract_digest: contract_digest,
        behavior_review_result_id: review_result_id,
        semantic_input: canonical_input,
        boundary_node_id: boundary_node_id,
        binding_dispositions: binding_dispositions,
        diagnostics: diagnostics
      }

      case decision.outcome do
        :admissible ->
          case propose_with_authority_if_needed(
                 design_document,
                 decision.semantic_input,
                 context_result,
                 proposal_builder
               ) do
            {:error, {:prerequisite, _stage, _diagnostics}} = error ->
              error

            proposal ->
              {:ok, decision, proposal}
          end

        :rejected ->
          {:error, decision}
      end
    end
  end

  defp proposal_diagnostic(diagnostic) do
    %ProposerDiagnostic{
      code: diagnostic.code,
      severity: diagnostic.severity,
      message: diagnostic.message,
      path: "breakpoint_authority",
      metadata: diagnostic.metadata
    }
  end

  defp prerequisite(_stage, {:ok, value}), do: {:ok, value}

  defp prerequisite(stage, {:error, diagnostics}),
    do: {:error, {:prerequisite, stage, diagnostics}}

  defp structural_diagnostics(:ok), do: []
  defp structural_diagnostics({:error, diagnostics}), do: diagnostics

  defp structure_prerequisite(design_document, behavior_contract) do
    case Validation.validate_structure(design_document, behavior_contract) do
      :ok -> :ok
      {:error, diagnostics} -> {:error, {:prerequisite, :behavior_contract, diagnostics}}
    end
  end

  defp authority_context_for_input(
         _design_document,
         _behavior_contract,
         _selected_behavior_review_result,
         %SemanticInput{source_node_dispositions: []}
       ),
       do: :not_required

  defp authority_context_for_input(
         design_document,
         behavior_contract,
         selected_behavior_review_result,
         _semantic_input
       ),
       do: authority_context(design_document, behavior_contract, selected_behavior_review_result)

  defp structural_result(:not_required, design_document, behavior_contract),
    do: Validation.validate_structure(design_document, behavior_contract)

  defp structural_result({:ok, _context}, _design_document, _behavior_contract), do: :ok

  defp structural_result(
         {:error, {:prerequisite, _stage, diagnostics}},
         _design_document,
         _behavior_contract
       ),
       do: {:error, diagnostics}

  defp propose_with_authority_if_needed(
         design_document,
         semantic_input,
         :not_required,
         proposal_builder
       ),
       do: proposal_builder.(design_document, semantic_input)

  defp propose_with_authority_if_needed(
         design_document,
         semantic_input,
         {:ok, context},
         _proposal_builder
       ) do
    ComponentizationProposer.propose_with_behavior_authority_context_internal(
      design_document,
      semantic_input,
      context
    )
  end

  defp containment_diagnostic(%{binding_id: binding_id, disposition: :split}) do
    [
      %Diagnostic{
        code: "behavior.componentization.binding_split",
        severity: "error",
        category: "projection",
        binding_id: binding_id,
        node_id: nil,
        evidence_id: nil,
        message: "Behavior binding crosses the proposed component boundary",
        suggested_action: nil,
        source_trace: nil
      }
    ]
  end

  defp containment_diagnostic(%{binding_id: binding_id, disposition: :unresolved}) do
    [
      %Diagnostic{
        code: "behavior.componentization.binding_unresolved",
        severity: "error",
        category: "reference",
        binding_id: binding_id,
        node_id: nil,
        evidence_id: nil,
        message: "Behavior binding contains an unresolved DesignNode reference",
        suggested_action: nil,
        source_trace: nil
      }
    ]
  end

  defp containment_diagnostic(_disposition), do: []
end
