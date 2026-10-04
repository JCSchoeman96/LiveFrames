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
  alias LiveFrames.ComponentizationPlan.RenderProjection
  alias LiveFrames.ComponentizationProposer.Diagnostic, as: ProposerDiagnostic
  alias LiveFrames.ComponentizationProposer.SemanticInput
  alias LiveFrames.ComponentizationProposer.SemanticInput.BindingAssignmentDecision
  alias LiveFrames.IR.{CollectionBinding, DesignDocument, ValueBinding}

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
    with {:ok, contract} <- build_contract(design_document, input),
         {:ok, fingerprint} <- fingerprint(design_document),
         {:ok, plan} <- build_plan(input, contract, fingerprint),
         :ok <- validate_contract(contract),
         :ok <- validate_plan(plan) do
      {:ok, contract, plan}
    else
      {:error, diagnostics} -> {:error, diagnostics}
    end
  rescue
    error ->
      {:error, [construction_diagnostic("construction", Exception.message(error))]}
  end

  def build(_design_document, _input),
    do: {:error, [construction_diagnostic("construction", "construction inputs are malformed")]}

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

  defp build_plan(input, contract, fingerprint) do
    plan = %ComponentizationPlan{
      plan_format_version: ComponentizationPlan.current_format_version(),
      contract_id: contract.contract_id,
      design_document_sha256: fingerprint,
      boundary_node_id: input.boundary.boundary_node_id,
      render_projections:
        input.render_placements
        |> Enum.map(&render_projection/1)
        |> Enum.sort_by(&render_projection_sort_key/1),
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
