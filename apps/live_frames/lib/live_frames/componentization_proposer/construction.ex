defmodule LiveFrames.ComponentizationProposer.Construction do
  @moduledoc false

  alias LiveFrames.ComponentContract

  alias LiveFrames.ComponentContract.{
    Attr,
    BindingProjection,
    CollectionInput,
    Diagnostic,
    ItemField,
    Slot
  }

  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.NodeDisposition
  alias LiveFrames.ComponentizationPlan.RenderProjection
  alias LiveFrames.ComponentizationProposer.Diagnostic, as: ProposerDiagnostic
  alias LiveFrames.ComponentizationProposer.SemanticInput
  alias LiveFrames.ComponentizationProposer.SemanticInput.BindingAssignmentDecision
  alias LiveFrames.ComponentizationProposer.SemanticInput.SourceNodeDispositionDecision
  alias LiveFrames.Behavior.{Binding, ComponentizationDecision, Contract}
  alias LiveFrames.BehaviorAuthorityContext
  alias LiveFrames.IR.{CollectionBinding, DesignDocument, ValueBinding}
  alias LiveFrames.IR.{DesignNode, SourceTrace}

  @construction_code "componentization_proposer.construction.failed"

  @projection_kind_rank %{
    scalar_attr: 0,
    collection_attr: 1,
    collection_item_field: 2,
    collection_count_attr: 3,
    slot: 4
  }

  @spec build(DesignDocument.t(), SemanticInput.t()) ::
          {:ok, ComponentContract.t(), ComponentizationPlan.t()}
          | {:error, [ProposerDiagnostic.t()]}
  def build(%DesignDocument{} = design_document, %SemanticInput{} = input) do
    build_pair(design_document, input, [])
  rescue
    error ->
      {:error, [construction_diagnostic("construction", Exception.message(error))]}
  end

  def build(_design_document, _input),
    do: {:error, [construction_diagnostic("construction", "construction inputs are malformed")]}

  @doc false
  @spec build(DesignDocument.t(), SemanticInput.t(), BehaviorAuthorityContext.t()) ::
          {:ok, ComponentContract.t(), ComponentizationPlan.t()}
          | {:error, [ProposerDiagnostic.t()]}
  def build(
        %DesignDocument{} = design_document,
        %SemanticInput{} = input,
        %BehaviorAuthorityContext{} = context
      ) do
    with {:ok, node_index} <- index_document(design_document),
         {:ok, binding_index} <- index_behavior_bindings(context),
         :ok <- validate_binding_selections(input.source_node_dispositions, binding_index),
         {:ok, prepared_node_dispositions} <-
           prepare_node_dispositions(
             input.source_node_dispositions,
             input.boundary.boundary_node_id,
             node_index
           ),
         {:ok, validated_context} <- revalidate_context(design_document, context),
         {:ok, reference_index} <-
           behavior_reference_index(design_document, validated_context.behavior_contract),
         {:ok, node_dispositions} <-
           build_node_dispositions(
             prepared_node_dispositions,
             reference_index,
             validated_context
           ) do
      build_pair(design_document, input, node_dispositions)
    else
      {:error, diagnostics} -> {:error, diagnostics}
    end
  rescue
    _error ->
      {:error, [node_disposition_diagnostic("invalid", nil)]}
  end

  def build(_design_document, _input, _context),
    do: {:error, [node_disposition_diagnostic("behavior_authority_mismatch", nil)]}

  defp build_pair(design_document, input, node_dispositions) do
    with {:ok, contract} <- build_contract(design_document, input),
         {:ok, fingerprint} <- fingerprint(design_document),
         {:ok, plan} <- build_plan(input, contract, fingerprint, node_dispositions),
         :ok <- validate_contract(contract),
         :ok <- validate_plan(plan) do
      {:ok, contract, plan}
    else
      {:error, diagnostics} -> {:error, diagnostics}
    end
  end

  defp index_document(%DesignDocument{root_nodes: root_nodes}) when is_list(root_nodes),
    do: index_document_nodes(root_nodes, %{})

  defp index_document(_design_document),
    do: {:error, [node_disposition_diagnostic("invalid", nil)]}

  defp index_document_nodes([], index), do: {:ok, index}

  defp index_document_nodes(
         [%DesignNode{node_id: node_id, children: children} = node | rest],
         index
       )
       when is_binary(node_id) and node_id != "" and is_list(children) do
    if Map.has_key?(index, node_id) do
      {:error, [node_disposition_diagnostic("invalid", node_id)]}
    else
      stack = Enum.reduce(children, rest, &[&1 | &2])
      index_document_nodes(stack, Map.put(index, node_id, node))
    end
  end

  defp index_document_nodes(_nodes, _index),
    do: {:error, [node_disposition_diagnostic("invalid", nil)]}

  defp index_behavior_bindings(%BehaviorAuthorityContext{
         behavior_contract: %Contract{bindings: bindings}
       })
       when is_list(bindings) do
    Enum.reduce_while(bindings, {:ok, %{}}, fn
      %Binding{binding_id: binding_id}, {:ok, index}
      when is_binary(binding_id) and binding_id != "" ->
        {:cont, {:ok, Map.update(index, binding_id, 1, &(&1 + 1))}}

      _binding, _index ->
        {:halt, {:error, [behavior_authority_mismatch_diagnostic()]}}
    end)
  end

  defp index_behavior_bindings(_context),
    do: {:error, [behavior_authority_mismatch_diagnostic()]}

  defp validate_binding_selections(decisions, binding_index) when is_list(decisions) do
    diagnostics =
      Enum.reduce(decisions, [], fn
        %SourceNodeDispositionDecision{
          design_node_id: node_id,
          behavior_binding_id: binding_id
        },
        diagnostics ->
          if Map.get(binding_index, binding_id, 0) == 1 do
            diagnostics
          else
            [node_disposition_diagnostic("behavior_binding_mismatch", node_id) | diagnostics]
          end

        _decision, diagnostics ->
          [node_disposition_diagnostic("invalid", nil) | diagnostics]
      end)

    case canonical_disposition_diagnostics(diagnostics) do
      [] -> :ok
      diagnostics -> {:error, diagnostics}
    end
  end

  defp validate_binding_selections(_decisions, _binding_index),
    do: {:error, [node_disposition_diagnostic("invalid", nil)]}

  defp revalidate_context(design_document, %BehaviorAuthorityContext{} = context) do
    case ComponentizationDecision.authority_context(
           design_document,
           context.behavior_contract,
           context.selected_behavior_review_result
         ) do
      {:ok, ^context} ->
        {:ok, context}

      _result ->
        {:error, [behavior_authority_mismatch_diagnostic()]}
    end
  end

  defp behavior_reference_index(design_document, behavior_contract) do
    case ComponentizationDecision.reference_index(design_document, behavior_contract) do
      {:ok, reference_index} ->
        {:ok, reference_index}

      {:error, _diagnostics} ->
        {:error, [behavior_authority_mismatch_diagnostic()]}
    end
  end

  defp prepare_node_dispositions(decisions, boundary_node_id, node_index)
       when is_list(decisions) do
    boundary_nodes = boundary_node_ids(boundary_node_id, node_index)

    {prepared, diagnostics} =
      Enum.reduce(decisions, {[], []}, fn decision, {prepared, diagnostics} ->
        case prepare_node_disposition(decision, boundary_nodes, node_index) do
          {:ok, entry} -> {[entry | prepared], diagnostics}
          {:error, diagnostic} -> {prepared, [diagnostic | diagnostics]}
        end
      end)

    case canonical_disposition_diagnostics(diagnostics) do
      [] ->
        {:ok, Enum.sort_by(prepared, fn {decision, _target} -> decision.design_node_id end)}

      diagnostics ->
        {:error, diagnostics}
    end
  end

  defp prepare_node_dispositions(_decisions, _boundary, _node_index),
    do: {:error, [node_disposition_diagnostic("invalid", nil)]}

  defp prepare_node_disposition(
         %SourceNodeDispositionDecision{} = decision,
         boundary_nodes,
         node_index
       ) do
    with :ok <- validate_disposition_decision(decision),
         {:ok, target} <- fetch_target(decision.design_node_id, node_index),
         :ok <- validate_target_boundary(target.node_id, boundary_nodes),
         :ok <- validate_target_shape(target),
         :ok <- validate_source_trace(target) do
      {:ok, {decision, target}}
    end
  end

  defp prepare_node_disposition(
         _decision,
         _boundary_nodes,
         _node_index
       ),
       do: {:error, node_disposition_diagnostic("invalid", nil)}

  defp build_node_dispositions(prepared, reference_index, context) do
    {records, diagnostics} =
      Enum.reduce(prepared, {[], []}, fn {decision, target}, {records, diagnostics} ->
        case validate_reference_conflict(target.node_id, reference_index) do
          :ok ->
            trace = target.source_trace

            record = %NodeDisposition{
              design_node_id: decision.design_node_id,
              disposition: decision.outcome,
              source_type: trace.source_type,
              source_id: trace.source_id,
              behavior_binding_id: decision.behavior_binding_id,
              behavior_contract_digest: context.behavior_contract_digest,
              behavior_review_id: context.behavior_review_result_id,
              evidence_refs: Enum.sort(decision.evidence_refs)
            }

            {[record | records], diagnostics}

          {:error, diagnostic} ->
            {records, [diagnostic | diagnostics]}
        end
      end)

    case canonical_disposition_diagnostics(diagnostics) do
      [] -> {:ok, Enum.sort_by(records, & &1.design_node_id)}
      diagnostics -> {:error, diagnostics}
    end
  end

  defp validate_disposition_decision(%SourceNodeDispositionDecision{
         design_node_id: node_id,
         outcome: :exclude_source_runtime_carrier,
         behavior_binding_id: binding_id,
         evidence_refs: evidence_refs
       }) do
    if valid_non_empty_string?(node_id) and valid_non_empty_string?(binding_id) and
         valid_evidence_refs?(evidence_refs) do
      :ok
    else
      {:error, node_disposition_diagnostic("invalid", node_id)}
    end
  end

  defp validate_disposition_decision(%SourceNodeDispositionDecision{design_node_id: node_id}),
    do: {:error, node_disposition_diagnostic("invalid", node_id)}

  defp fetch_target(node_id, node_index) when is_binary(node_id) do
    case Map.fetch(node_index, node_id) do
      {:ok, target} -> {:ok, target}
      :error -> {:error, node_disposition_diagnostic("target_missing", node_id)}
    end
  end

  defp fetch_target(node_id, _node_index),
    do: {:error, node_disposition_diagnostic("target_missing", node_id)}

  defp validate_target_boundary(node_id, boundary_nodes) do
    if MapSet.member?(boundary_nodes, node_id) do
      :ok
    else
      {:error, node_disposition_diagnostic("target_outside_boundary", node_id)}
    end
  end

  defp validate_target_shape(%DesignNode{
         node_id: node_id,
         semantic_type: semantic_type,
         children: children
       }) do
    if semantic_type in ["raw", "unsupported", "unknown"] and children == [] do
      :ok
    else
      {:error, node_disposition_diagnostic("target_semantic_incompatible", node_id)}
    end
  end

  defp validate_source_trace(%DesignNode{
         node_id: node_id,
         source_trace: %SourceTrace{source_type: source_type, source_id: source_id}
       }) do
    if valid_non_empty_string?(source_type) and valid_non_empty_string?(source_id) do
      :ok
    else
      {:error, node_disposition_diagnostic("source_identity_mismatch", node_id)}
    end
  end

  defp validate_source_trace(%DesignNode{node_id: node_id}),
    do: {:error, node_disposition_diagnostic("source_identity_mismatch", node_id)}

  defp validate_reference_conflict(node_id, reference_index) do
    case Map.get(reference_index, node_id) do
      %MapSet{} = roles ->
        if MapSet.size(roles) > 0 do
          {:error, node_disposition_diagnostic("behavior_reference_conflict", node_id)}
        else
          :ok
        end

      _roles ->
        :ok
    end
  end

  defp boundary_node_ids(boundary_node_id, node_index),
    do: boundary_node_ids([boundary_node_id], node_index, MapSet.new())

  defp boundary_node_ids([], _node_index, node_ids), do: node_ids

  defp boundary_node_ids([node_id | rest], node_index, node_ids) do
    if MapSet.member?(node_ids, node_id) do
      boundary_node_ids(rest, node_index, node_ids)
    else
      case Map.get(node_index, node_id) do
        %DesignNode{children: children} ->
          child_ids = Enum.map(children, & &1.node_id)
          next = Enum.reduce(child_ids, rest, &[&1 | &2])
          boundary_node_ids(next, node_index, MapSet.put(node_ids, node_id))

        _missing_boundary ->
          boundary_node_ids(rest, node_index, node_ids)
      end
    end
  end

  defp valid_evidence_refs?(refs) when is_list(refs) and refs != [] do
    Enum.all?(refs, &valid_non_empty_string?/1) and
      length(refs) == MapSet.size(MapSet.new(refs))
  end

  defp valid_evidence_refs?(_refs), do: false

  defp valid_non_empty_string?(value),
    do: is_binary(value) and byte_size(value) > 0 and String.valid?(value)

  defp behavior_authority_mismatch_diagnostic do
    node_disposition_diagnostic("behavior_authority_mismatch", nil)
  end

  defp node_disposition_diagnostic(suffix, node_id) do
    %ProposerDiagnostic{
      code: "componentization_plan.node_disposition." <> suffix,
      severity: :error,
      path:
        if(is_binary(node_id), do: "node_dispositions[#{node_id}]", else: "node_dispositions"),
      message: "node disposition failed the #{suffix} guard"
    }
  end

  defp canonical_disposition_diagnostics(diagnostics) do
    Enum.sort_by(diagnostics, &{&1.code || "", &1.path || "", &1.message || ""})
  end

  defp validate_contract(contract) do
    case ComponentContract.validate(contract) do
      :ok -> :ok
      {:error, diagnostics} -> {:error, construction_diagnostics(diagnostics)}
    end
  end

  defp validate_plan(plan) do
    case ComponentizationPlan.validate(plan) do
      :ok -> :ok
      {:error, diagnostics} -> {:error, construction_diagnostics(diagnostics)}
    end
  end

  defp construction_diagnostics(diagnostics) do
    diagnostics
    |> Enum.map(fn diagnostic ->
      code = Map.get(diagnostic, :code) || "construction"
      path = Map.get(diagnostic, :path)
      message = Map.get(diagnostic, :message) || "construction failed"

      construction_diagnostic(path || code, "#{code}: #{message}")
    end)
    |> case do
      [] -> [construction_diagnostic("construction", "construction failed")]
      values -> values
    end
  end

  defp fingerprint(design_document) do
    case ComponentizationPlan.design_document_sha256(design_document) do
      {:ok, fingerprint} ->
        {:ok, fingerprint}

      {:error, [diagnostic | _]} ->
        {:error,
         [
           construction_diagnostic(
             diagnostic.path || diagnostic.code,
             "#{diagnostic.code}: #{diagnostic.message}"
           )
         ]}

      {:error, _diagnostics} ->
        {:error,
         [construction_diagnostic("design_document_sha256", "fingerprint materialization failed")]}
    end
  end

  defp build_contract(design_document, input) do
    try do
      {provenance, evidence_diagnostics} = evidence_metadata(input.evidence_handling)

      contract = %ComponentContract{
        contract_format_version: ComponentContract.current_format_version(),
        contract_id: input.contract_identity.contract_id,
        category: input.classification.category,
        module_intent: input.classification.module_intent,
        function_intent: input.classification.function_intent,
        approval_status: :proposed,
        public_attrs:
          input.public_attrs
          |> Enum.sort_by(& &1.name)
          |> Enum.map(&attr/1),
        public_slots:
          input.public_slots
          |> Enum.sort_by(& &1.name)
          |> Enum.map(&slot/1),
        collection_inputs:
          input
          |> collection_inputs()
          |> Enum.sort_by(& &1.source_collection_binding_id),
        binding_projections: binding_projections(design_document, input.binding_assignments),
        diagnostics: evidence_diagnostics,
        provenance: provenance
      }

      {:ok, contract}
    rescue
      error ->
        {:error, [construction_diagnostic("contract", Exception.message(error))]}
    end
  end

  defp attr(decision) do
    %Attr{
      name: decision.name,
      type: decision.type,
      required: decision.required,
      default: decision.default,
      semantic_purpose: decision.semantic_purpose,
      validation: decision.validation,
      accessibility: decision.accessibility,
      provenance: decision.provenance
    }
  end

  defp slot(decision) do
    %Slot{
      name: decision.name,
      cardinality: decision.cardinality,
      required: decision.required,
      semantic_purpose: decision.semantic_purpose,
      consumer_responsibility: decision.consumer_responsibility,
      validation: decision.validation,
      accessibility: decision.accessibility,
      provenance: decision.provenance
    }
  end

  defp collection_inputs(input) do
    fields_by_collection = Enum.group_by(input.item_fields, & &1.source_collection_binding_id)

    count_by_collection =
      Map.new(input.collection_count_links, &{&1.source_collection_binding_id, &1})

    Enum.map(input.collection_admissions, fn decision ->
      count = Map.get(count_by_collection, decision.source_collection_binding_id)

      %CollectionInput{
        source_collection_binding_id: decision.source_collection_binding_id,
        public_attr_name: decision.public_attr_name,
        parent_collection_binding_id: decision.parent_collection_binding_id,
        parent_item_field_name: decision.parent_item_field_name,
        item_fields:
          fields_by_collection
          |> Map.get(decision.source_collection_binding_id, [])
          |> Enum.map(&item_field/1)
          |> Enum.sort_by(& &1.name),
        count_attr_name: if(root_collection?(decision), do: count_name(count), else: nil),
        count_item_field_name: if(root_collection?(decision), do: nil, else: count_name(count)),
        provenance: decision.provenance
      }
    end)
  end

  defp item_field(decision) do
    %ItemField{
      name: decision.name,
      type: decision.type,
      required: decision.required,
      default: decision.default,
      semantic_purpose: decision.semantic_purpose,
      validation: decision.validation,
      accessibility: decision.accessibility,
      provenance: decision.provenance
    }
  end

  defp root_collection?(decision), do: is_nil(decision.parent_collection_binding_id)
  defp count_name(nil), do: nil
  defp count_name(decision), do: decision.count_public_name

  defp binding_projections(document, assignments) do
    assignments
    |> Enum.map(&binding_projection(document, &1))
    |> Enum.sort_by(&projection_sort_key/1)
  end

  defp binding_projection(document, %BindingAssignmentDecision{} = assignment) do
    case assignment.assignment_kind do
      :scalar_attr ->
        value_projection(document, assignment, :scalar_attr,
          public_attr_name: assignment.public_attr_name
        )

      :collection_attr ->
        collection = collection_binding!(document, assignment.source_binding_id)

        %BindingProjection{
          source_binding_kind: :collection,
          source_binding_id: assignment.source_binding_id,
          projection_kind: :collection_attr,
          public_attr_name: assignment.public_attr_name,
          source_collection_binding_id: assignment.source_binding_id,
          target_node_id: collection.repeat_root_node_id
        }

      :collection_item_field_value ->
        value_projection(document, assignment, :collection_item_field,
          source_collection_binding_id: assignment.source_collection_binding_id,
          item_field_name: assignment.item_field_name
        )

      :collection_item_field_nested_collection ->
        collection = collection_binding!(document, assignment.source_binding_id)

        %BindingProjection{
          source_binding_kind: :collection,
          source_binding_id: assignment.source_binding_id,
          projection_kind: :collection_item_field,
          source_collection_binding_id: assignment.source_binding_id,
          parent_collection_binding_id: collection.parent_collection_binding_id,
          parent_item_field_name: assignment.parent_item_field_name,
          target_node_id: collection.repeat_root_node_id
        }

      :collection_count_attr ->
        value_projection(document, assignment, :collection_count_attr,
          source_collection_binding_id: assignment.source_collection_binding_id,
          public_attr_name: assignment.public_attr_name
        )

      :collection_count_item_field ->
        collection = collection_binding!(document, assignment.source_collection_binding_id)

        value_projection(document, assignment, :collection_item_field,
          source_collection_binding_id: assignment.source_collection_binding_id,
          parent_collection_binding_id: collection.parent_collection_binding_id,
          parent_item_field_name: assignment.parent_item_field_name
        )

      :slot ->
        value_projection(document, assignment, :slot,
          public_slot_name: assignment.public_slot_name
        )
    end
  end

  defp value_projection(document, assignment, projection_kind, fields) do
    value = value_binding!(document, assignment.source_binding_id)

    struct!(
      %BindingProjection{
        source_binding_kind: :value,
        source_binding_id: assignment.source_binding_id,
        projection_kind: projection_kind,
        target_node_id: value.target_node_id
      },
      fields
    )
  end

  defp build_plan(input, contract, fingerprint, node_dispositions) do
    plan = %ComponentizationPlan{
      plan_format_version: ComponentizationPlan.current_format_version(),
      contract_id: contract.contract_id,
      design_document_sha256: fingerprint,
      boundary_node_id: input.boundary.boundary_node_id,
      render_projections:
        input.render_placements
        |> Enum.map(&render_projection/1)
        |> Enum.sort_by(&render_projection_sort_key/1),
      node_dispositions: node_dispositions,
      diagnostics: [],
      provenance: %{}
    }

    {:ok, plan}
  rescue
    error -> {:error, [construction_diagnostic("plan", Exception.message(error))]}
  end

  defp render_projection(decision) do
    case decision.public_target_kind do
      :attr ->
        %RenderProjection{
          public_attr_name: decision.public_target_name,
          target_node_id: decision.target_node_id,
          render_role: decision.render_role
        }

      :slot ->
        %RenderProjection{
          public_slot_name: decision.public_target_name,
          target_node_id: decision.target_node_id,
          render_role: decision.render_role
        }
    end
  end

  defp render_projection_sort_key(%RenderProjection{public_attr_name: name}) when is_binary(name),
    do: name

  defp render_projection_sort_key(%RenderProjection{public_slot_name: name}), do: name

  defp projection_sort_key(projection) do
    {
      binding_rank(projection.source_binding_kind),
      projection.source_binding_id,
      Map.fetch!(@projection_kind_rank, projection.projection_kind),
      optional_sort_key(projection.public_attr_name),
      optional_sort_key(projection.public_slot_name),
      optional_sort_key(projection.item_field_name),
      optional_sort_key(projection.parent_item_field_name)
    }
  end

  defp binding_rank(:collection), do: 0
  defp binding_rank(:value), do: 1

  defp optional_sort_key(value) when is_binary(value) and value != "", do: {0, value}
  defp optional_sort_key(_value), do: {1, ""}

  defp evidence_metadata(decisions) do
    Enum.reduce(decisions, {%{}, []}, fn decision, {provenance, diagnostics} ->
      provenance =
        Map.update(
          provenance,
          "evidence_handling",
          %{decision.source_binding_id => %{"outcome" => "omit_public_projection"}},
          &Map.put(&1, decision.source_binding_id, %{"outcome" => "omit_public_projection"})
        )

      diagnostic = %Diagnostic{
        code: "component_contract.binding_evidence_insufficient",
        severity: :error,
        message: "value binding has insufficient evidence",
        path: "value_bindings[#{decision.source_binding_id}]"
      }

      {provenance, [diagnostic | diagnostics]}
    end)
    |> then(fn {provenance, diagnostics} -> {provenance, Enum.reverse(diagnostics)} end)
  end

  defp value_binding!(%DesignDocument{value_bindings: values}, id) when is_map(values) do
    case Map.get(values, id) do
      %ValueBinding{} = value -> value
      _ -> raise ArgumentError, "value binding #{inspect(id)} is missing"
    end
  end

  defp collection_binding!(%DesignDocument{collection_bindings: collections}, id)
       when is_map(collections) do
    case Map.get(collections, id) do
      %CollectionBinding{} = collection -> collection
      _ -> raise ArgumentError, "collection binding #{inspect(id)} is missing"
    end
  end

  defp construction_diagnostic(path, message) do
    %ProposerDiagnostic{
      code: @construction_code,
      severity: :error,
      path: path,
      message: message || "construction failed"
    }
  end
end
