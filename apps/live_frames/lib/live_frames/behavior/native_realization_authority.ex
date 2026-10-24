defmodule LiveFrames.Behavior.NativeRealizationAuthority do
  @moduledoc """
  Transient generation-time authority for one approved Selection occurrence.
  """

  alias LiveFrames.Behavior.Binding
  alias LiveFrames.Behavior.Binding.ControlledTarget
  alias LiveFrames.Behavior.Binding.FocusPolicy
  alias LiveFrames.Behavior.Binding.Trigger
  alias LiveFrames.Behavior.BindingContainment
  alias LiveFrames.Behavior.Diagnostic
  alias LiveFrames.Behavior.PrimitiveRegistry
  alias LiveFrames.Behavior.ReviewResult
  alias LiveFrames.Behavior.Serializer
  alias LiveFrames.Behavior.Validation
  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.RenderProjection
  alias LiveFrames.IR.{DesignDocument, DesignNode, Identity, ValueBinding}

  @type t :: %__MODULE__{
          component_contract_id: String.t(),
          plan_contract_id: String.t(),
          design_document_identity: Identity.t(),
          plan_design_document_sha256: String.t(),
          boundary_node_id: String.t(),
          behavior_contract_digest: String.t(),
          behavior_review_result_id: String.t(),
          behavior_binding_id: String.t(),
          control_node_id: String.t(),
          activation_carrier_node_id: String.t(),
          presentation_node_ids: [String.t()]
        }

  defstruct [
    :component_contract_id,
    :plan_contract_id,
    :design_document_identity,
    :plan_design_document_sha256,
    :boundary_node_id,
    :behavior_contract_digest,
    :behavior_review_result_id,
    :behavior_binding_id,
    :control_node_id,
    :activation_carrier_node_id,
    :presentation_node_ids
  ]

  @spec derive(term(), term(), term(), term(), term()) :: {:ok, t()} | {:error, [term()]}
  def derive(
        approved_component_contract,
        plan,
        design_document,
        behavior_contract,
        approved_behavior_review
      ) do
    with :ok <-
           ComponentContract.validate_for_generation(approved_component_contract, design_document),
         :ok <- Validation.validate_structure(design_document, behavior_contract),
         {:ok, behavior_contract_digest} <- Serializer.digest(behavior_contract),
         {:ok, approved_review} <-
           ReviewResult.require_approved([approved_behavior_review], behavior_contract),
         {:ok, behavior_review_result_id} <- ReviewResult.id(approved_review),
         :ok <-
           ComponentizationPlan.validate_references_with_behavior_authority(
             plan,
             approved_component_contract,
             design_document,
             behavior_contract,
             approved_review
           ),
         :ok <- Validation.validate_semantics(design_document, behavior_contract),
         {:ok, design_document_identity} <- Identity.from_document(design_document) do
      derive_topology(
        approved_component_contract,
        plan,
        design_document,
        behavior_contract,
        behavior_contract_digest,
        behavior_review_result_id,
        design_document_identity
      )
    else
      {:error, diagnostics} -> {:error, diagnostics}
    end
  end

  defp derive_topology(
         component_contract,
         plan,
         design_document,
         behavior_contract,
         behavior_contract_digest,
         behavior_review_result_id,
         design_document_identity
       ) do
    containment_context = BindingContainment.prepare(design_document, plan.boundary_node_id)

    dispositions =
      Enum.map(behavior_contract.bindings, fn binding ->
        {binding, BindingContainment.classify_binding(binding, containment_context)}
      end)

    case containment_diagnostics(dispositions) do
      [] ->
        nodes_by_id = nodes_by_id(design_document.root_nodes)
        projection_indexes = carrier_projection_indexes(component_contract, plan)

        with {:ok, selection_binding} <- contained_selection(dispositions),
             {:ok, control_node_id} <- control_node_id(selection_binding),
             {:ok, presentation_node_ids} <- presentation_node_ids(selection_binding, nodes_by_id),
             {:ok, control_node} <- control_node(control_node_id, nodes_by_id, selection_binding),
             :ok <- validate_control_node(control_node, selection_binding),
             {:ok, carrier_node_id} <-
               activation_carrier_node_id(
                 control_node,
                 projection_indexes,
                 design_document,
                 selection_binding
               ),
             {:ok, reference_index} <-
               BindingContainment.reference_index(design_document, behavior_contract),
             :ok <-
               validate_interaction_conflicts(
                 reference_index,
                 control_node_id,
                 carrier_node_id,
                 selection_binding
               ),
             :ok <-
               validate_link_binding_conflicts(
                 design_document,
                 control_node_id,
                 carrier_node_id,
                 selection_binding
               ),
             :ok <-
               validate_behavior_conflicts(
                 behavior_contract.bindings,
                 selection_binding,
                 control_node_id,
                 carrier_node_id
               ) do
          {:ok,
           %__MODULE__{
             component_contract_id: component_contract.contract_id,
             plan_contract_id: plan.contract_id,
             design_document_identity: design_document_identity,
             plan_design_document_sha256: plan.design_document_sha256,
             boundary_node_id: plan.boundary_node_id,
             behavior_contract_digest: behavior_contract_digest,
             behavior_review_result_id: behavior_review_result_id,
             behavior_binding_id: selection_binding.binding_id,
             control_node_id: control_node_id,
             activation_carrier_node_id: carrier_node_id,
             presentation_node_ids: presentation_node_ids
           }}
        end

      diagnostics ->
        {:error, sort_diagnostics(diagnostics)}
    end
  end

  defp containment_diagnostics(dispositions) do
    dispositions
    |> Enum.flat_map(fn
      {%Binding{binding_id: binding_id}, disposition}
      when disposition in [:split, :unresolved] ->
        [
          realization_diagnostic(
            "behavior.native_realization.binding_not_contained",
            binding_id,
            nil,
            "Behavior binding references are split across or unresolved from the component boundary"
          )
        ]

      _entry ->
        []
    end)
    |> sort_diagnostics()
  end

  defp contained_selection(dispositions) do
    contained =
      Enum.filter(dispositions, fn {_binding, disposition} -> disposition == :contained end)

    {selections, unsupported} =
      Enum.reduce(contained, {[], []}, fn {%Binding{} = binding, _disposition},
                                          {selections, unsupported} ->
        case PrimitiveRegistry.resolve(binding.primitive_ref) do
          {:ok, {:selection_v1, _default_position}} ->
            {[binding | selections], unsupported}

          {:ok, _other_supported_primitive} ->
            {selections, unsupported}

          :error ->
            {selections,
             [
               realization_diagnostic(
                 "behavior.native_realization.selection_unsupported",
                 binding.binding_id,
                 nil,
                 "Contained Behavior binding does not resolve to Selection 1.0.0"
               )
               | unsupported
             ]}
        end
      end)

    cond do
      unsupported != [] ->
        {:error, sort_diagnostics(unsupported)}

      length(selections) == 0 ->
        {:error,
         [
           realization_diagnostic(
             "behavior.native_realization.selection_missing",
             nil,
             nil,
             "Component boundary contains no Selection 1.0.0 Behavior binding"
           )
         ]}

      length(selections) > 1 ->
        {:error,
         selections
         |> Enum.map(fn binding ->
           realization_diagnostic(
             "behavior.native_realization.selection_ambiguous",
             binding.binding_id,
             nil,
             "Component boundary contains more than one Selection 1.0.0 Behavior binding"
           )
         end)
         |> sort_diagnostics()}

      true ->
        {:ok, hd(selections)}
    end
  end

  defp control_node_id(%Binding{} = binding) do
    controls = Enum.filter(binding.controlled_targets, &(&1.role == "control_collection"))
    activations = Enum.filter(binding.triggers, &(&1.kind == "activate"))

    case {controls, activations} do
      {[%ControlledTarget{node_id: control_node_id}], [%Trigger{origin_node_id: origin_node_id}]}
      when origin_node_id == control_node_id ->
        {:ok, control_node_id}

      _ ->
        {:error,
         [
           realization_diagnostic(
             "behavior.native_realization.control_invalid",
             binding.binding_id,
             single_control_id(controls),
             "Selection requires one control_collection and one activate trigger originating from it"
           )
         ]}
    end
  end

  defp single_control_id([%ControlledTarget{node_id: node_id}]), do: node_id
  defp single_control_id(_controls), do: nil

  defp presentation_node_ids(%Binding{} = binding, nodes_by_id) do
    targets = Enum.filter(binding.controlled_targets, &(&1.role == "presentation_collection"))
    node_ids = Enum.map(targets, & &1.node_id)
    unique_node_ids = Enum.uniq(node_ids)

    valid? =
      length(node_ids) == 2 and length(unique_node_ids) == 2 and
        Enum.all?(unique_node_ids, &Map.has_key?(nodes_by_id, &1))

    if valid? do
      {:ok, Enum.sort(unique_node_ids)}
    else
      {:error,
       [
         realization_diagnostic(
           "behavior.native_realization.presentation_invalid",
           binding.binding_id,
           if(length(unique_node_ids) == 1, do: hd(unique_node_ids), else: nil),
           "Selection requires exactly two distinct, resolvable presentation collections"
         )
       ]}
    end
  end

  defp control_node(control_node_id, nodes_by_id, binding) do
    case Map.fetch(nodes_by_id, control_node_id) do
      {:ok, %DesignNode{} = node} ->
        {:ok, node}

      :error ->
        {:error,
         [
           realization_diagnostic(
             "behavior.native_realization.control_invalid",
             binding.binding_id,
             control_node_id,
             "Selection control_collection does not resolve to a DesignNode"
           )
         ]}
    end
  end

  defp validate_control_node(
         %DesignNode{semantic_type: "generic", attributes: %{"tag" => "button"}},
         _binding
       ),
       do: :ok

  defp validate_control_node(%DesignNode{} = node, binding) do
    {:error,
     [
       realization_diagnostic(
         "behavior.native_realization.control_invalid",
         binding.binding_id,
         node.node_id,
         "Selection control node must be a generic DesignNode with normalized tag button"
       )
     ]}
  end

  defp activation_carrier_node_id(
         %DesignNode{children: children} = control_node,
         projection_indexes,
         design_document,
         binding
       ) do
    headings = Enum.filter(children, &match?(%DesignNode{semantic_type: "heading"}, &1))

    candidates =
      Enum.map(headings, fn %DesignNode{} = heading ->
        title_result = title_value_binding(heading, projection_indexes, design_document, binding)
        heading_result = heading_level_projection(heading, projection_indexes, binding)
        {heading, title_result, heading_result}
      end)

    eligible =
      Enum.filter(candidates, fn {_heading, title_result, projection_result} ->
        title_result == :ok and projection_result == :ok
      end)

    case eligible do
      [{%DesignNode{node_id: node_id}, :ok, :ok}] ->
        {:ok, node_id}

      [_first, _second | _rest] ->
        {:error,
         [
           realization_diagnostic(
             "behavior.native_realization.carrier_invalid",
             binding.binding_id,
             nil,
             "Selection control has more than one direct child satisfying the activation-carrier contract"
           )
         ]}

      [] when headings == [] ->
        {:error,
         [
           realization_diagnostic(
             "behavior.native_realization.carrier_invalid",
             binding.binding_id,
             control_node.node_id,
             "Selection control has no direct heading child for its activation carrier"
           )
         ]}

      [] ->
        diagnostics =
          Enum.flat_map(candidates, fn {_heading, title_result, projection_result} ->
            result_diagnostics(title_result) ++ result_diagnostics(projection_result)
          end)

        {:error, sort_diagnostics(diagnostics)}
    end
  end

  defp title_value_binding(
         %DesignNode{node_id: node_id},
         %{title_projections_by_target: projections_by_target},
         design_document,
         binding
       ) do
    projections = Map.get(projections_by_target, node_id, [])

    valid? =
      case projections do
        [
          %BindingProjection{source_binding_id: source_binding_id}
        ]
        when is_binary(source_binding_id) ->
          case Map.get(design_document.value_bindings, source_binding_id) do
            %ValueBinding{
              value_binding_id: ^source_binding_id,
              target_node_id: ^node_id,
              target_kind: :text,
              normalization_status: :normalized
            } ->
              true

            _value_binding ->
              false
          end

        _projections ->
          false
      end

    if valid? do
      :ok
    else
      {:error,
       realization_diagnostic(
         "behavior.native_realization.title_binding_invalid",
         binding.binding_id,
         node_id,
         "Activation carrier requires exactly one approved collection-item text ValueBinding projection"
       )}
    end
  end

  defp heading_level_projection(
         %DesignNode{node_id: node_id},
         %{heading_projections_by_target: projections_by_target},
         binding
       ) do
    projections = Map.get(projections_by_target, node_id, [])

    if length(projections) == 1 do
      :ok
    else
      {:error,
       realization_diagnostic(
         "behavior.native_realization.heading_projection_invalid",
         binding.binding_id,
         node_id,
         "Activation carrier requires exactly one approved heading_level RenderProjection"
       )}
    end
  end

  defp validate_interaction_conflicts(reference_index, control_node_id, carrier_node_id, binding) do
    diagnostics =
      [control_node_id, carrier_node_id]
      |> Enum.uniq()
      |> Enum.flat_map(fn node_id ->
        roles = Map.get(reference_index, node_id, MapSet.new())

        if MapSet.member?(roles, :ir_interaction_ref) or
             MapSet.member?(roles, :ir_interaction_target) do
          [
            realization_diagnostic(
              "behavior.native_realization.interaction_conflict",
              binding.binding_id,
              node_id,
              "Selection control or activation carrier also has Design IR interaction authority"
            )
          ]
        else
          []
        end
      end)

    if diagnostics == [], do: :ok, else: {:error, sort_diagnostics(diagnostics)}
  end

  defp validate_link_binding_conflicts(
         %DesignDocument{value_bindings: value_bindings},
         control_node_id,
         carrier_node_id,
         %Binding{binding_id: selected_binding_id}
       ) do
    diagnostics =
      value_bindings
      |> Enum.flat_map(fn
        {_value_binding_id, %ValueBinding{target_node_id: node_id, target_kind: :link_url}}
        when node_id in [control_node_id, carrier_node_id] ->
          [
            realization_diagnostic(
              "behavior.native_realization.link_binding_conflict",
              selected_binding_id,
              node_id,
              "Selection control or activation carrier also has a link_url ValueBinding"
            )
          ]

        _entry ->
          []
      end)

    if diagnostics == [], do: :ok, else: {:error, sort_diagnostics(diagnostics)}
  end

  defp validate_behavior_conflicts(bindings, selected_binding, control_node_id, carrier_node_id) do
    realization_nodes = MapSet.new([control_node_id, carrier_node_id])

    diagnostics =
      bindings
      |> Enum.reject(&(&1.binding_id == selected_binding.binding_id))
      |> Enum.flat_map(fn %Binding{} = binding ->
        binding
        |> explicit_node_references()
        |> Enum.filter(&MapSet.member?(realization_nodes, &1))
        |> Enum.uniq()
        |> Enum.map(fn node_id ->
          realization_diagnostic(
            "behavior.native_realization.behavior_conflict",
            binding.binding_id,
            node_id,
            "Another Behavior binding directly claims the Selection control or activation carrier"
          )
        end)
      end)

    if diagnostics == [], do: :ok, else: {:error, sort_diagnostics(diagnostics)}
  end

  defp explicit_node_references(%Binding{} = binding) do
    focus_references =
      case binding.focus_policy do
        %FocusPolicy{} = focus_policy ->
          [
            focus_policy.initial_target_node_id,
            focus_policy.scope_node_id,
            focus_policy.restoration_target_node_id,
            focus_policy.restoration_fallback_node_id
          ]

        _focus_policy ->
          []
      end

    ([binding.owner_node_id] ++
       Enum.flat_map(binding.triggers, fn
         %Trigger{origin_node_id: node_id} -> [node_id]
         _trigger -> []
       end) ++
       Enum.flat_map(binding.controlled_targets, fn
         %ControlledTarget{node_id: node_id} -> [node_id]
         _target -> []
       end) ++ focus_references)
    |> Enum.reject(&is_nil/1)
  end

  defp carrier_projection_indexes(component_contract, plan) do
    title_projections_by_target =
      Enum.reduce(component_contract.binding_projections, %{}, fn
        %BindingProjection{
          source_binding_kind: :value,
          projection_kind: :collection_item_field,
          target_node_id: node_id
        } = projection,
        index
        when is_binary(node_id) ->
          Map.update(index, node_id, [projection], &[projection | &1])

        _projection, index ->
          index
      end)

    heading_projections_by_target =
      Enum.reduce(plan.render_projections, %{}, fn
        %RenderProjection{target_node_id: node_id, render_role: :heading_level} = projection,
        index
        when is_binary(node_id) ->
          Map.update(index, node_id, [projection], &[projection | &1])

        _projection, index ->
          index
      end)

    %{
      title_projections_by_target: title_projections_by_target,
      heading_projections_by_target: heading_projections_by_target
    }
  end

  defp nodes_by_id(nodes), do: nodes_by_id(nodes, %{})

  defp nodes_by_id([], index), do: index

  defp nodes_by_id([%DesignNode{node_id: node_id, children: children} = node | rest], index) do
    index = Map.put(index, node_id, node)
    index = nodes_by_id(children, index)
    nodes_by_id(rest, index)
  end

  defp result_diagnostics({:error, %Diagnostic{} = diagnostic}), do: [diagnostic]
  defp result_diagnostics({:error, diagnostics}) when is_list(diagnostics), do: diagnostics
  defp result_diagnostics(_result), do: []

  defp realization_diagnostic(code, binding_id, node_id, message) do
    %Diagnostic{
      code: code,
      severity: "error",
      category: "realization",
      binding_id: binding_id,
      node_id: node_id,
      message: message,
      source_trace: nil
    }
  end

  defp sort_diagnostics(diagnostics) do
    Enum.sort_by(
      diagnostics,
      &{&1.binding_id || "", &1.code || "", &1.node_id || "", &1.message || ""}
    )
  end
end
