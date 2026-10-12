defmodule LiveFrames.Behavior.ComponentizationDecision do
  @moduledoc """
  Ephemeral behavior-aware gate for an explicit componentization candidate.
  """

  alias LiveFrames.Behavior.Binding
  alias LiveFrames.Behavior.Binding.ControlledTarget
  alias LiveFrames.Behavior.Binding.FocusPolicy
  alias LiveFrames.Behavior.Binding.Trigger
  alias LiveFrames.Behavior.Diagnostic
  alias LiveFrames.Behavior.ReviewResult
  alias LiveFrames.Behavior.Serializer
  alias LiveFrames.Behavior.Validation
  alias LiveFrames.ComponentizationProposer
  alias LiveFrames.ComponentizationProposer.SemanticInput
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Identity

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

  @spec propose(term(), term(), term(), term()) ::
          {:ok, t(), term()} | {:error, t()} | {:error, {:prerequisite, atom(), list()}}
  def propose(design_document, behavior_contract, behavior_review_result, semantic_input) do
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
      structural = Validation.validate_structure(design_document, behavior_contract)
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
          proposer_result =
            ComponentizationProposer.propose(design_document, decision.semantic_input)

          {:ok, decision, proposer_result}

        :rejected ->
          {:error, decision}
      end
    end
  end

  defp prerequisite(_stage, {:ok, value}), do: {:ok, value}

  defp prerequisite(stage, {:error, diagnostics}),
    do: {:error, {:prerequisite, stage, diagnostics}}

  defp structural_diagnostics(:ok), do: []
  defp structural_diagnostics({:error, diagnostics}), do: diagnostics

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
