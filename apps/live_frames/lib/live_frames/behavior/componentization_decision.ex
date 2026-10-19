defmodule LiveFrames.Behavior.ComponentizationDecision do
  @moduledoc """
  Ephemeral behavior-aware gate for an explicit componentization candidate.
  """

  alias LiveFrames.Behavior.Binding
  alias LiveFrames.Behavior.Binding.ControlledTarget
  alias LiveFrames.Behavior.Binding.FocusPolicy
  alias LiveFrames.Behavior.Binding.Trigger
  alias LiveFrames.Behavior.Contract
  alias LiveFrames.Behavior.Diagnostic
  alias LiveFrames.Behavior.ReviewResult
  alias LiveFrames.Behavior.Serializer
  alias LiveFrames.Behavior.Validation
  alias LiveFrames.BehaviorAuthorityContext
  alias LiveFrames.ComponentizationProposer
  alias LiveFrames.ComponentizationProposer.Diagnostic, as: ProposerDiagnostic
  alias LiveFrames.ComponentizationProposer.SemanticInput
  alias LiveFrames.IR.{DesignDocument, DesignNode, Interaction}
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

  @reference_roles [
    :binding_owner,
    :controlled_target,
    :trigger_origin,
    :focus_reference,
    :ir_interaction_ref,
    :ir_interaction_target
  ]

  @spec reference_index(DesignDocument.t(), Contract.t()) ::
          {:ok, %{optional(String.t()) => MapSet.t(atom())}}
          | {:error, [Diagnostic.t()]}
  def reference_index(
        %DesignDocument{} = design_document,
        %Contract{} = behavior_contract
      ) do
    with :ok <- Validation.validate_structure(design_document, behavior_contract) do
      index =
        design_document.root_nodes
        |> index_interaction_refs(%{})
        |> index_interaction_targets(design_document.interactions)
        |> index_behavior_references(behavior_contract.bindings)

      {:ok, index}
    else
      {:error, diagnostics} -> {:error, diagnostics}
    end
  rescue
    _error ->
      {:error, [reference_index_diagnostic()]}
  end

  def reference_index(_design_document, _behavior_contract),
    do: {:error, [reference_index_diagnostic()]}

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

  defp index_interaction_refs(nodes, index) do
    nodes
    |> Enum.reduce([], &[&1 | &2])
    |> index_interaction_ref_stack(index)
  end

  defp index_interaction_ref_stack([], index), do: index

  defp index_interaction_ref_stack(
         [
           %DesignNode{node_id: node_id, interaction_refs: interaction_refs, children: children}
           | rest
         ],
         index
       ) do
    index =
      if interaction_refs == [] do
        index
      else
        add_reference(index, node_id, :ir_interaction_ref)
      end

    next = Enum.reduce(children, rest, &[&1 | &2])
    index_interaction_ref_stack(next, index)
  end

  defp index_interaction_targets(index, interactions) do
    Enum.reduce(interactions, index, fn
      {_interaction_id, %Interaction{target_node_ids: target_node_ids}}, index ->
        Enum.reduce(target_node_ids, index, &add_reference(&2, &1, :ir_interaction_target))
    end)
  end

  defp index_behavior_references(index, bindings) do
    Enum.reduce(bindings, index, fn %Binding{} = binding, index ->
      index = add_reference(index, binding.owner_node_id, :binding_owner)

      index =
        Enum.reduce(binding.controlled_targets, index, fn %ControlledTarget{node_id: node_id},
                                                          index ->
          add_reference(index, node_id, :controlled_target)
        end)

      index =
        Enum.reduce(binding.triggers, index, fn
          %Trigger{origin_node_id: nil}, index ->
            index

          %Trigger{origin_node_id: node_id}, index ->
            add_reference(index, node_id, :trigger_origin)
        end)

      case binding.focus_policy do
        %FocusPolicy{} = focus_policy ->
          [
            focus_policy.initial_target_node_id,
            focus_policy.scope_node_id,
            focus_policy.restoration_target_node_id,
            focus_policy.restoration_fallback_node_id
          ]
          |> Enum.reject(&is_nil/1)
          |> Enum.reduce(index, &add_reference(&2, &1, :focus_reference))

        _focus_policy ->
          index
      end
    end)
  end

  defp add_reference(index, node_id, role) when is_binary(node_id) and role in @reference_roles do
    Map.update(index, node_id, MapSet.new([role]), &MapSet.put(&1, role))
  end

  defp add_reference(index, _node_id, _role), do: index

  defp reference_index_diagnostic do
    %Diagnostic{
      code: "behavior.design_document.invalid",
      severity: "error",
      category: "structure",
      message: "DesignDocument and BehaviorContract cannot form a reference index"
    }
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
      index = index_nodes(design_document.root_nodes)
      boundary_node_id = canonical_input.boundary.boundary_node_id
      candidate_nodes = subtree_node_ids(boundary_node_id, index)

      binding_dispositions =
        behavior_contract.bindings
        |> Enum.map(fn binding ->
          %{
            binding_id: binding.binding_id,
            disposition: classify(binding, index, candidate_nodes)
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

  defp index_nodes(nodes), do: index_nodes(nodes, %{})

  defp index_nodes([], index), do: index

  defp index_nodes([%DesignNode{node_id: node_id, children: children} | rest], index) do
    index = Map.put(index, node_id, children)
    index = index_nodes(children, index)
    index_nodes(rest, index)
  end

  defp subtree_node_ids(boundary_node_id, index),
    do: subtree_node_ids([boundary_node_id], index, MapSet.new())

  defp subtree_node_ids([], _index, node_ids), do: node_ids

  defp subtree_node_ids([node_id | rest], index, node_ids) do
    if MapSet.member?(node_ids, node_id) do
      subtree_node_ids(rest, index, node_ids)
    else
      child_ids = index |> Map.get(node_id, []) |> Enum.map(& &1.node_id)
      subtree_node_ids(child_ids ++ rest, index, MapSet.put(node_ids, node_id))
    end
  end

  defp classify(%Binding{} = binding, index, candidate_nodes) do
    refs = binding_node_references(binding)

    cond do
      Enum.any?(refs, &(not Map.has_key?(index, &1))) ->
        :unresolved

      Enum.all?(refs, &MapSet.member?(candidate_nodes, &1)) ->
        :contained

      Enum.all?(refs, &(not MapSet.member?(candidate_nodes, &1))) ->
        :outside_candidate

      true ->
        :split
    end
  end

  defp binding_node_references(%Binding{} = binding) do
    ([binding.owner_node_id] ++
       Enum.flat_map(binding.triggers, fn
         %Trigger{origin_node_id: nil} -> []
         %Trigger{origin_node_id: node_id} -> [node_id]
       end) ++
       Enum.map(binding.controlled_targets, fn %ControlledTarget{node_id: node_id} -> node_id end) ++
       focus_node_references(binding.focus_policy))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp focus_node_references(%FocusPolicy{} = focus_policy) do
    [
      focus_policy.initial_target_node_id,
      focus_policy.scope_node_id,
      focus_policy.restoration_target_node_id,
      focus_policy.restoration_fallback_node_id
    ]
  end

  defp focus_node_references(_focus_policy), do: []

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
