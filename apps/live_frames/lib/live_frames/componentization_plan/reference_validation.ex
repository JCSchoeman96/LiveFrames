defmodule LiveFrames.ComponentizationPlan.ReferenceValidation do
  @moduledoc false

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentContract.CollectionInput
  alias LiveFrames.ComponentContract.Diagnostic, as: ContractDiagnostic
  alias LiveFrames.ComponentContract.ItemField
  alias LiveFrames.ComponentContract.Slot
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.Diagnostic
  alias LiveFrames.ComponentizationPlan.Json
  alias LiveFrames.ComponentizationPlan.RenderProjection
  alias LiveFrames.ComponentizationPlan.Validation
  alias LiveFrames.IR.CollectionBinding
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.ValueBinding

  @role_types %{
    text_content: :string,
    asset_src: :string,
    asset_alt: :string,
    link_url: :string,
    heading_level: :integer,
    root_id: :string,
    root_class: :string,
    root_global_attrs: :global
  }

  @root_roles [:root_id, :root_class, :root_global_attrs]

  @spec validate(term(), term(), term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate(plan, component_contract, design_document) do
    case preflight(plan, component_contract, design_document) do
      {:ok, plan, component_contract, design_document} ->
        validate_indexed(plan, component_contract, design_document)

      {:error, diagnostics} ->
        finish(diagnostics)
    end
  end

  @spec validate_generation_prerequisites(term(), term(), term()) ::
          :ok | {:error, [Diagnostic.t()]}
  def validate_generation_prerequisites(plan, component_contract, design_document) do
    case preflight_generation(plan, component_contract, design_document) do
      {:ok, plan, component_contract, design_document} ->
        reference_result = validate_indexed(plan, component_contract, design_document)

        stored_blockers =
          Enum.filter(plan.diagnostics, fn diagnostic ->
            diagnostic.severity in Diagnostic.blocking_severities()
          end)

        diagnostics = [] |> append_result(reference_result) |> Kernel.++(stored_blockers)
        finish(diagnostics)

      {:error, diagnostics} ->
        finish(diagnostics)
    end
  rescue
    _error ->
      finish([
        error(
          "componentization_plan.plan.invalid",
          "generation prerequisite inputs are malformed"
        )
      ])
  catch
    _kind, _reason ->
      finish([
        error(
          "componentization_plan.plan.invalid",
          "generation prerequisite inputs are malformed"
        )
      ])
  end

  @spec validate_for_generation(term(), term(), term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate_for_generation(plan, component_contract, design_document) do
    prerequisite_result =
      validate_generation_prerequisites(plan, component_contract, design_document)

    approval_result = contract_approval_result(component_contract)

    diagnostics =
      []
      |> append_result(prerequisite_result)
      |> append_contract_gate(approval_result)

    if diagnostics == [], do: :ok, else: finish([generation_blocked(diagnostics) | diagnostics])
  rescue
    _error ->
      finish([
        error("componentization_plan.generation_blocked", "generation inputs are malformed")
      ])
  catch
    _kind, _reason ->
      finish([
        error("componentization_plan.generation_blocked", "generation inputs are malformed")
      ])
  end

  defp preflight_generation(plan, component_contract, design_document) do
    case Validation.validate(plan) do
      :ok ->
        preflight_generation_document(plan, component_contract, design_document)

      {:error, diagnostics} ->
        {:error, diagnostics}
    end
  rescue
    _error ->
      {:error, [error("componentization_plan.plan.invalid", "plan failed intrinsic validation")]}
  end

  defp preflight_generation_document(plan, component_contract, design_document) do
    case LiveFrames.IR.validate(design_document) do
      :ok ->
        preflight_generation_fingerprint(plan, component_contract, design_document)

      {:error, diagnostics} ->
        {:error,
         [
           upstream_error(
             "componentization_plan.design_document.fingerprint_invalid",
             "DesignDocument failed IR validation",
             diagnostics
           )
         ]}
    end
  end

  defp preflight_generation_fingerprint(plan, component_contract, design_document) do
    case ComponentizationPlan.design_document_sha256(design_document) do
      {:ok, fingerprint} when fingerprint != plan.design_document_sha256 ->
        {:error,
         [
           error_at(
             "componentization_plan.design_document.mismatch",
             "plan fingerprint does not match the supplied DesignDocument",
             "design_document_sha256"
           )
         ]}

      {:ok, _fingerprint} ->
        preflight_generation_contract(plan, component_contract, design_document)

      {:error, diagnostics} ->
        {:error, diagnostics}
    end
  end

  defp preflight_generation_contract(plan, component_contract, design_document) do
    case ComponentContract.validate_generation_prerequisites(component_contract, design_document) do
      :ok when plan.contract_id == component_contract.contract_id ->
        {:ok, plan, component_contract, design_document}

      :ok ->
        {:error,
         [
           error_at(
             "componentization_plan.contract.mismatch",
             "plan contract_id does not match the supplied ComponentContract",
             "contract_id"
           )
         ]}

      {:error, diagnostics} ->
        {:error,
         [
           upstream_error(
             "componentization_plan.contract.mismatch",
             "ComponentContract is not generation-eligible",
             diagnostics
           )
         ]}
    end
  end

  defp preflight(plan, component_contract, design_document) do
    case Validation.validate(plan) do
      :ok ->
        preflight_contract(plan, component_contract, design_document)

      {:error, diagnostics} ->
        {:error, diagnostics}
    end
  rescue
    _error ->
      {:error, [error("componentization_plan.plan.invalid", "plan failed intrinsic validation")]}
  end

  defp preflight_contract(plan, component_contract, design_document) do
    case ComponentContract.validate(component_contract) do
      :ok ->
        preflight_document(plan, component_contract, design_document)

      {:error, diagnostics} ->
        {:error,
         [
           upstream_error(
             "componentization_plan.contract.mismatch",
             "ComponentContract failed intrinsic validation",
             diagnostics
           )
         ]}
    end
  end

  defp preflight_document(plan, component_contract, design_document) do
    case LiveFrames.IR.validate(design_document) do
      :ok ->
        preflight_fingerprint(plan, component_contract, design_document)

      {:error, diagnostics} ->
        {:error,
         [
           upstream_error(
             "componentization_plan.design_document.fingerprint_invalid",
             "DesignDocument failed IR validation",
             diagnostics
           )
         ]}
    end
  end

  defp preflight_fingerprint(plan, component_contract, design_document) do
    case ComponentizationPlan.design_document_sha256(design_document) do
      {:ok, fingerprint} ->
        cond do
          fingerprint != plan.design_document_sha256 ->
            {:error,
             [
               error_at(
                 "componentization_plan.design_document.mismatch",
                 "plan fingerprint does not match the supplied DesignDocument",
                 "design_document_sha256"
               )
             ]}

          plan.contract_id != component_contract.contract_id ->
            {:error,
             [
               error_at(
                 "componentization_plan.contract.mismatch",
                 "plan contract_id does not match the supplied ComponentContract",
                 "contract_id"
               )
             ]}

          true ->
            case ComponentContract.validate_ir_references(component_contract, design_document) do
              :ok ->
                {:ok, plan, component_contract, design_document}

              {:error, diagnostics} ->
                if Enum.all?(
                     diagnostics,
                     &(&1.code == "component_contract.binding.evidence_insufficient")
                   ) do
                  {:ok, plan, component_contract, design_document}
                else
                  {:error,
                   [
                     upstream_error(
                       "componentization_plan.contract.mismatch",
                       "ComponentContract references do not validate against the DesignDocument",
                       diagnostics
                     )
                   ]}
                end
            end
        end

      {:error, diagnostics} ->
        {:error, diagnostics}
    end
  end

  defp validate_indexed(plan, contract, document) do
    indexes = build_indexes(plan, contract, document)

    case Map.fetch(indexes.nodes_by_id, plan.boundary_node_id) do
      :error ->
        finish([
          error_at(
            "componentization_plan.boundary.missing",
            "boundary_node_id does not resolve to a DesignNode",
            "boundary_node_id"
          )
        ])

      {:ok, _boundary} ->
        boundary_ids = indexes.boundary_ids
        slot_owners = indexes.slot_owners

        diagnostics = []
        diagnostics = validate_render_projections(plan, indexes, boundary_ids, diagnostics)
        diagnostics = validate_render_subtrees(plan, slot_owners, diagnostics)
        diagnostics = validate_binding_targets(contract, boundary_ids, slot_owners, diagnostics)
        diagnostics = validate_binding_coverage(indexes, boundary_ids, slot_owners, diagnostics)
        diagnostics = validate_placements(plan, contract, indexes, diagnostics)
        diagnostics = validate_role_colocation(plan, indexes, diagnostics)

        {image_sources, diagnostics} =
          validate_image_sources(plan, contract, indexes, boundary_ids, diagnostics)

        diagnostics = validate_static_images(indexes, image_sources, diagnostics)

        diagnostics = validate_unsupported_nodes(indexes, diagnostics)

        finish(diagnostics)
    end
  rescue
    _error ->
      finish([
        error("componentization_plan.plan.invalid", "reference inputs failed closed validation")
      ])
  end

  defp build_indexes(plan, contract, document) do
    slot_targets =
      plan.render_projections
      |> Enum.filter(&(&1.render_role == :subtree_slot))
      |> Enum.map(& &1.target_node_id)
      |> MapSet.new()

    tree_indexes =
      index_nodes(
        document.root_nodes,
        %{
          nodes_by_id: %{},
          boundary_ids: MapSet.new(),
          slot_owners: %{},
          static_image_ids: [],
          unsupported_node_ids: []
        },
        plan.boundary_node_id,
        slot_targets,
        false,
        nil
      )

    nodes_by_id = tree_indexes.nodes_by_id

    attrs_by_name =
      Map.new(contract.public_attrs, fn %Attr{name: name} = attr -> {name, attr} end)

    slots_by_name =
      Map.new(contract.public_slots, fn %Slot{name: name} = slot -> {name, slot} end)

    collection_inputs_by_id =
      Map.new(contract.collection_inputs, fn %CollectionInput{source_collection_binding_id: id} =
                                               input ->
        {id, input}
      end)

    item_fields_by_collection =
      Map.new(contract.collection_inputs, fn %CollectionInput{
                                               source_collection_binding_id: id,
                                               item_fields: fields
                                             } ->
        {id, Map.new(fields, fn %ItemField{name: name} = item -> {name, item} end)}
      end)

    bindings_by_source =
      Enum.group_by(contract.binding_projections, fn %BindingProjection{
                                                       source_binding_kind: kind,
                                                       source_binding_id: id
                                                     } ->
        {kind, id}
      end)

    bindings_by_public_target =
      Enum.reduce(contract.binding_projections, %{}, fn projection, acc ->
        case binding_public_target(projection) do
          nil -> acc
          key -> Map.update(acc, key, [projection], &[projection | &1])
        end
      end)

    item_field_projection_index =
      Enum.reduce(contract.binding_projections, %{}, fn
        %BindingProjection{
          source_binding_kind: :value,
          projection_kind: :collection_item_field,
          source_collection_binding_id: collection_id,
          item_field_name: name,
          source_binding_id: id,
          target_node_id: target
        },
        acc
        when is_binary(collection_id) and is_binary(name) and is_binary(target) ->
          valid_text_binding? =
            match?(
              %ValueBinding{
                value_kind: :field,
                scope: :collection_item,
                target_kind: :text,
                collection_binding_id: ^collection_id,
                target_node_id: ^target
              },
              Map.get(document.value_bindings, id)
            )

          targets = if valid_text_binding?, do: MapSet.new([target]), else: MapSet.new()

          Map.update(acc, {collection_id, name}, {1, targets}, fn {count, indexed_targets} ->
            indexed_targets =
              if valid_text_binding?,
                do: MapSet.put(indexed_targets, target),
                else: indexed_targets

            {count + 1, indexed_targets}
          end)

        _projection, acc ->
          acc
      end)

    collection_item_text_targets =
      Enum.reduce(contract.binding_projections, MapSet.new(), fn
        %BindingProjection{
          source_binding_kind: :value,
          projection_kind: :collection_item_field,
          source_collection_binding_id: collection_id,
          source_binding_id: id,
          target_node_id: target
        },
        acc ->
          case Map.get(document.value_bindings, id) do
            %ValueBinding{} = binding when is_binary(collection_id) and is_binary(target) ->
              if binding.scope == :collection_item and binding.target_kind == :text and
                   binding.collection_binding_id == collection_id do
                MapSet.put(acc, {collection_id, target})
              else
                acc
              end

            _ ->
              acc
          end

        _projection, acc ->
          acc
      end)

    render_by_public_target =
      Map.new(plan.render_projections, fn projection ->
        {render_public_target(projection), projection}
      end)

    render_by_node_role =
      Enum.group_by(plan.render_projections, &{&1.target_node_id, &1.render_role})

    render_by_node = Enum.group_by(plan.render_projections, & &1.target_node_id)

    value_bindings = normalized_registry(document.value_bindings)
    collection_bindings = normalized_registry(document.collection_bindings)

    %{
      nodes_by_id: nodes_by_id,
      boundary_ids: tree_indexes.boundary_ids,
      slot_owners: tree_indexes.slot_owners,
      static_image_ids: Enum.reverse(tree_indexes.static_image_ids),
      unsupported_node_ids: Enum.reverse(tree_indexes.unsupported_node_ids),
      attrs_by_name: attrs_by_name,
      slots_by_name: slots_by_name,
      collection_inputs_by_id: collection_inputs_by_id,
      item_fields_by_collection: item_fields_by_collection,
      bindings_by_source: bindings_by_source,
      bindings_by_public_target: bindings_by_public_target,
      item_field_projection_index: item_field_projection_index,
      collection_item_text_targets: collection_item_text_targets,
      render_by_public_target: render_by_public_target,
      render_by_node_role: render_by_node_role,
      render_by_node: render_by_node,
      value_bindings: value_bindings,
      collection_bindings: collection_bindings
    }
  end

  defp index_nodes(nodes, indexes, boundary_id, slot_targets, in_boundary?, current_slot_owner) do
    Enum.reduce(nodes, indexes, fn %DesignNode{node_id: id, children: children} = node, acc ->
      in_boundary? = in_boundary? or id == boundary_id

      slot_owner =
        if current_slot_owner == nil and MapSet.member?(slot_targets, id),
          do: id,
          else: current_slot_owner

      acc = %{acc | nodes_by_id: Map.put(acc.nodes_by_id, id, node)}

      acc =
        if in_boundary? do
          %{acc | boundary_ids: MapSet.put(acc.boundary_ids, id)}
        else
          acc
        end

      acc =
        if slot_owner == nil do
          acc
        else
          %{acc | slot_owners: Map.put(acc.slot_owners, id, slot_owner)}
        end

      acc =
        if in_boundary? and slot_owner == nil and node.semantic_type == "image" do
          %{acc | static_image_ids: [id | acc.static_image_ids]}
        else
          acc
        end

      acc =
        if in_boundary? and node.semantic_type in ["raw", "unsupported", "unknown"] do
          %{acc | unsupported_node_ids: [id | acc.unsupported_node_ids]}
        else
          acc
        end

      index_nodes(children, acc, boundary_id, slot_targets, in_boundary?, slot_owner)
    end)
  end

  defp validate_render_projections(plan, indexes, boundary_ids, diagnostics) do
    Enum.reduce(Enum.with_index(plan.render_projections), diagnostics, fn {projection, index},
                                                                          acc ->
      path = "render_projections[#{index}]"
      target = Map.get(indexes.nodes_by_id, projection.target_node_id)
      acc = validate_render_target(projection, path, target, boundary_ids, acc)
      acc = validate_render_public_target(projection, path, indexes, acc)
      acc = validate_render_role_type(projection, path, indexes, acc)
      validate_render_role_node(projection, path, target, plan.boundary_node_id, acc)
    end)
  end

  defp validate_render_target(_projection, path, nil, _boundary_ids, diagnostics) do
    add(
      diagnostics,
      error_at(
        "componentization_plan.render_projection.target_missing",
        "target_node_id does not resolve to a DesignNode",
        path
      )
    )
  end

  defp validate_render_target(projection, path, _target, boundary_ids, diagnostics) do
    if MapSet.member?(boundary_ids, projection.target_node_id) do
      diagnostics
    else
      add(
        diagnostics,
        error_at(
          "componentization_plan.render_projection.target_outside_boundary",
          "RenderProjection target is outside the selected boundary",
          path
        )
      )
    end
  end

  defp validate_render_public_target(projection, path, indexes, diagnostics) do
    exists? =
      case render_public_target(projection) do
        {:attr, name} -> Map.has_key?(indexes.attrs_by_name, name)
        {:slot, name} -> Map.has_key?(indexes.slots_by_name, name)
      end

    if exists? do
      diagnostics
    else
      add(
        diagnostics,
        error_at(
          "componentization_plan.render_projection.invalid",
          "RenderProjection public target is absent from the ComponentContract",
          path
        )
      )
    end
  end

  defp validate_render_role_type(projection, path, indexes, diagnostics) do
    valid? =
      case {projection.render_role, render_public_target(projection)} do
        {:subtree_slot, {:slot, name}} ->
          match?(%Slot{cardinality: "0..1"}, Map.get(indexes.slots_by_name, name))

        {role, {:attr, name}} when is_map_key(@role_types, role) ->
          case Map.get(indexes.attrs_by_name, name) do
            %Attr{type: type, validation: validation} ->
              type == Map.fetch!(@role_types, role) and
                (role != :heading_level or Map.get(validation, "values") == [1, 2, 3, 4, 5, 6])

            _ ->
              false
          end

        _ ->
          false
      end

    if valid? do
      diagnostics
    else
      add(
        diagnostics,
        error_at(
          "componentization_plan.render_projection.role_type_mismatch",
          "public target type or slot cardinality is incompatible with render_role",
          path
        )
      )
    end
  end

  defp validate_render_role_node(_projection, _path, nil, _boundary_id, diagnostics),
    do: diagnostics

  defp validate_render_role_node(projection, path, node, boundary_id, diagnostics) do
    valid? =
      case projection.render_role do
        role when role in @root_roles -> projection.target_node_id == boundary_id
        :text_content -> node.semantic_type in ["heading", "paragraph", "rich_text"]
        :asset_src -> node.semantic_type == "image"
        :asset_alt -> node.semantic_type == "image"
        :link_url -> node.semantic_type == "link"
        :heading_level -> node.semantic_type == "heading"
        :subtree_slot -> node.semantic_type in ["actions", "button", "link"]
        _ -> false
      end

    if valid? do
      diagnostics
    else
      add(
        diagnostics,
        error_at(
          "componentization_plan.render_projection.role_node_mismatch",
          "render_role is incompatible with the target node semantic_type",
          path
        )
      )
    end
  end

  defp validate_binding_targets(contract, boundary_ids, slot_owners, diagnostics) do
    Enum.reduce(Enum.with_index(contract.binding_projections), diagnostics, fn {projection, index},
                                                                               acc ->
      path = "binding_projections[#{index}]"

      acc =
        if MapSet.member?(boundary_ids, projection.target_node_id) do
          acc
        else
          add(
            acc,
            error_at(
              "componentization_plan.render_projection.target_outside_boundary",
              "BindingProjection target is outside the selected boundary",
              path
            )
          )
        end

      if Map.get(slot_owners, projection.target_node_id) do
        add(
          acc,
          error_at(
            "componentization_plan.slot.subtree_conflict",
            "BindingProjection targets a subtree replaced by subtree_slot",
            path
          )
        )
      else
        acc
      end
    end)
  end

  defp validate_render_subtrees(plan, slot_owners, diagnostics) do
    Enum.reduce(Enum.with_index(plan.render_projections), diagnostics, fn {projection, index},
                                                                          acc ->
      owner = Map.get(slot_owners, projection.target_node_id)

      owner_projection? =
        projection.render_role == :subtree_slot and projection.target_node_id == owner

      if owner && not owner_projection? do
        add(
          acc,
          error_at(
            "componentization_plan.slot.subtree_conflict",
            "RenderProjection targets a subtree replaced by subtree_slot",
            "render_projections[#{index}]"
          )
        )
      else
        acc
      end
    end)
  end

  defp validate_binding_coverage(indexes, boundary_ids, slot_owners, diagnostics) do
    diagnostics =
      Enum.reduce(indexes.value_bindings, diagnostics, fn {id, %ValueBinding{} = binding}, acc ->
        if MapSet.member?(boundary_ids, binding.target_node_id) do
          matches = Map.get(indexes.bindings_by_source, {:value, id}, [])
          acc = require_binding_count(acc, matches, "value", id)

          acc =
            if binding.normalization_status == :evidence_insufficient do
              add(
                acc,
                error_at(
                  "componentization_plan.binding.evidence_insufficient",
                  "in-boundary ValueBinding has insufficient normalization evidence",
                  "value_bindings[#{id}]"
                )
              )
            else
              acc
            end

          if Map.get(slot_owners, binding.target_node_id) do
            add(
              acc,
              error_at(
                "componentization_plan.slot.subtree_conflict",
                "ValueBinding targets a subtree replaced by subtree_slot",
                "value_bindings[#{id}]"
              )
            )
          else
            acc
          end
        else
          acc
        end
      end)

    Enum.reduce(indexes.collection_bindings, diagnostics, fn {id, %CollectionBinding{} = binding},
                                                             acc ->
      owner_inside = MapSet.member?(boundary_ids, binding.owner_node_id)
      repeat_inside = MapSet.member?(boundary_ids, binding.repeat_root_node_id)

      acc =
        cond do
          owner_inside != repeat_inside ->
            add(
              acc,
              error_at(
                "componentization_plan.boundary.binding_crosses",
                "CollectionBinding owner and repeat root must both lie inside or both outside the boundary",
                "collection_bindings[#{id}]"
              )
            )

          owner_inside ->
            require_binding_count(
              acc,
              Map.get(indexes.bindings_by_source, {:collection, id}, []),
              "collection",
              id
            )

          true ->
            acc
        end

      parent = binding.parent_collection_binding_id

      acc =
        if owner_inside and is_binary(parent) do
          case Map.get(indexes.collection_bindings, parent) do
            %CollectionBinding{} = parent_binding ->
              parent_inside =
                MapSet.member?(boundary_ids, parent_binding.owner_node_id) and
                  MapSet.member?(boundary_ids, parent_binding.repeat_root_node_id)

              if parent_inside do
                acc
              else
                add(
                  acc,
                  error_at(
                    "componentization_plan.boundary.binding_crosses",
                    "in-boundary nested CollectionBinding requires its parent binding inside the boundary",
                    "collection_bindings[#{id}].parent_collection_binding_id"
                  )
                )
              end

            _ ->
              acc
          end
        else
          acc
        end

      if Map.get(slot_owners, binding.owner_node_id) ||
           Map.get(slot_owners, binding.repeat_root_node_id) do
        add(
          acc,
          error_at(
            "componentization_plan.slot.subtree_conflict",
            "CollectionBinding crosses a subtree replaced by subtree_slot",
            "collection_bindings[#{id}]"
          )
        )
      else
        acc
      end
    end)
  end

  defp require_binding_count(diagnostics, [_], _kind, _id), do: diagnostics

  defp require_binding_count(diagnostics, [], kind, id) do
    add(
      diagnostics,
      error_at(
        "componentization_plan.binding.uncovered",
        "in-boundary Design IR binding has no BindingProjection",
        "#{kind}_bindings[#{id}]"
      )
    )
  end

  defp require_binding_count(diagnostics, _many, kind, id) do
    add(
      diagnostics,
      error_at(
        "componentization_plan.binding.duplicate",
        "in-boundary Design IR binding has multiple BindingProjections",
        "#{kind}_bindings[#{id}]"
      )
    )
  end

  defp validate_placements(_plan, contract, indexes, diagnostics) do
    diagnostics =
      Enum.reduce(contract.public_attrs, diagnostics, fn %Attr{name: name}, acc ->
        validate_one_placement(acc, {:attr, name}, name, indexes)
      end)

    Enum.reduce(contract.public_slots, diagnostics, fn %Slot{name: name}, acc ->
      validate_one_placement(acc, {:slot, name}, name, indexes)
    end)
    |> then(fn acc ->
      Enum.reduce(contract.binding_projections, acc, fn
        %BindingProjection{projection_kind: :slot, public_slot_name: name}, d
        when is_binary(name) ->
          add(
            d,
            error_at(
              "componentization_plan.slot.binding_backed_unsupported",
              "binding-backed slots are not generation-eligible in plan format 1.0.0",
              "public_slots[#{name}]"
            )
          )

        _projection, d ->
          d
      end)
    end)
  end

  defp validate_one_placement(diagnostics, target, name, indexes) do
    binding_count = length(Map.get(indexes.bindings_by_public_target, target, []))
    render_count = if Map.has_key?(indexes.render_by_public_target, target), do: 1, else: 0

    if (binding_count == 1 and render_count == 0) or (binding_count == 0 and render_count == 1) do
      diagnostics
    else
      code =
        if binding_count == 0 and render_count == 0,
          do: "componentization_plan.public_input.placement_missing",
          else: "componentization_plan.public_input.placement_conflict"

      add(
        diagnostics,
        error_at(
          code,
          "public input must have exactly one BindingProjection or RenderProjection",
          "public_inputs[#{name}]"
        )
      )
    end
  end

  defp validate_role_colocation(plan, indexes, diagnostics) do
    Enum.reduce(indexes.render_by_node, diagnostics, fn {node_id, projections}, acc ->
      roles = Enum.map(projections, & &1.render_role)
      role_counts = Enum.frequencies(roles)
      duplicate? = Enum.any?(role_counts, fn {_role, count} -> count > 1 end)
      node = Map.get(indexes.nodes_by_id, node_id)
      boundary? = node_id == plan.boundary_node_id
      root_role_present? = Enum.any?(roles, &(&1 in @root_roles))
      semantic_role_present? = Enum.any?(roles, &(&1 not in @root_roles))
      mixed_boundary_roles? = boundary? and root_role_present? and semantic_role_present?

      allowed_roles =
        if boundary? and root_role_present? and not semantic_role_present? do
          @root_roles
        else
          semantic_allowed_roles(node)
        end

      unsupported? =
        mixed_boundary_roles? or Enum.any?(roles, &(&1 not in allowed_roles))

      if duplicate? or unsupported? do
        add(
          acc,
          error_at(
            "componentization_plan.render_projection.role_conflict",
            "render roles on one node are duplicated or cannot be co-located",
            "render_projections[#{node_id}]"
          )
        )
      else
        acc
      end
    end)
  end

  defp semantic_allowed_roles(%DesignNode{semantic_type: "heading"}),
    do: [:text_content, :heading_level]

  defp semantic_allowed_roles(%DesignNode{semantic_type: type})
       when type in ["paragraph", "rich_text"],
       do: [:text_content]

  defp semantic_allowed_roles(%DesignNode{semantic_type: "image"}),
    do: [:asset_src, :asset_alt]

  defp semantic_allowed_roles(%DesignNode{semantic_type: "link"}),
    do: [:link_url, :subtree_slot]

  defp semantic_allowed_roles(%DesignNode{semantic_type: type})
       when type in ["actions", "button"],
       do: [:subtree_slot]

  defp semantic_allowed_roles(_node), do: []

  defp validate_image_sources(plan, contract, indexes, boundary_ids, diagnostics) do
    {valid_source_nodes, diagnostics} =
      validate_top_level_image_sources(plan, contract, indexes, boundary_ids, diagnostics)

    validate_collection_item_image_sources(indexes, boundary_ids, valid_source_nodes, diagnostics)
  end

  defp validate_top_level_image_sources(plan, contract, indexes, boundary_ids, diagnostics) do
    render_sources =
      Enum.filter(plan.render_projections, fn projection ->
        projection.render_role == :asset_src and
          MapSet.member?(boundary_ids, projection.target_node_id)
      end)

    binding_sources =
      Enum.flat_map(contract.binding_projections, fn
        %BindingProjection{
          source_binding_kind: :value,
          projection_kind: :scalar_attr,
          public_attr_name: name,
          source_binding_id: id,
          target_node_id: target
        } ->
          case Map.get(indexes.value_bindings, id) do
            %ValueBinding{scope: :site, target_kind: :asset} ->
              if MapSet.member?(boundary_ids, target) and
                   match?(
                     %DesignNode{semantic_type: "image"},
                     Map.get(indexes.nodes_by_id, target)
                   ) do
                [{name, target, "binding_projections[#{id}]"}]
              else
                []
              end

            _ ->
              []
          end

        _projection ->
          []
      end)

    sources =
      Enum.map(
        render_sources,
        &{&1.public_attr_name, &1.target_node_id, "render_projections[#{&1.public_attr_name}]"}
      ) ++
        binding_sources

    Enum.reduce(sources, {MapSet.new(), diagnostics}, fn {name, target, path}, {nodes, acc} ->
      case Map.get(indexes.attrs_by_name, name) do
        %Attr{} = source_attr ->
          {valid?, acc} =
            validate_top_level_image_policy(source_attr, name, target, plan, indexes, path, acc)

          {if(valid?, do: MapSet.put(nodes, target), else: nodes), acc}

        _ ->
          {nodes,
           add(
             acc,
             error_at(
               "componentization_plan.accessibility.image_policy_missing",
               "image source attr does not resolve",
               path
             )
           )}
      end
    end)
  end

  defp validate_top_level_image_policy(
         source_attr,
         source_name,
         target,
         plan,
         indexes,
         path,
         diagnostics
       ) do
    {:ok, policy} = Json.normalize(source_attr.accessibility)

    case Map.get(policy, "image_alt_policy") do
      nil ->
        {false,
         add(
           diagnostics,
           error_at(
             "componentization_plan.accessibility.image_policy_missing",
             "image source requires an explicit accessibility policy",
             path
           )
         )}

      "consumer_supplied" ->
        validate_consumer_alt_policy(
          policy,
          source_name,
          target,
          plan,
          indexes,
          path,
          diagnostics
        )

      "decorative" ->
        validate_decorative_policy(policy, target, indexes, path, diagnostics)

      _unknown ->
        {false,
         add(
           diagnostics,
           error_at(
             "componentization_plan.accessibility.image_policy_invalid",
             "image_alt_policy is not supported",
             path
           )
         )}
    end
  end

  defp validate_consumer_alt_policy(
         policy,
         _source_name,
         target,
         _plan,
         indexes,
         path,
         diagnostics
       ) do
    alt_name = Map.get(policy, "alt_attr_name")
    required? = Map.get(policy, "required_when_source_present") == true
    exact_keys? = map_size(policy) == 3

    diagnostics =
      if required? and exact_keys? do
        diagnostics
      else
        add(
          diagnostics,
          error_at(
            "componentization_plan.accessibility.image_policy_invalid",
            "consumer-supplied alt policy requires exactly the approved keys and required_when_source_present = true",
            path
          )
        )
      end

    case Map.get(indexes.attrs_by_name, alt_name) do
      %Attr{type: :string} when is_binary(alt_name) and alt_name != "" ->
        projections = Map.get(indexes.render_by_node_role, {target, :asset_alt}, [])

        valid_projection? =
          match?([%RenderProjection{public_attr_name: ^alt_name}], projections)

        diagnostics =
          if valid_projection? do
            diagnostics
          else
            add(
              diagnostics,
              error_at(
                "componentization_plan.accessibility.alt_projection_mismatch",
                "consumer alt attr requires one asset_alt RenderProjection for the same image",
                path
              )
            )
          end

        {required? and exact_keys? and valid_projection?, diagnostics}

      _ ->
        {false,
         add(
           diagnostics,
           error_at(
             "componentization_plan.accessibility.alt_attr_missing",
             "alt_attr_name must resolve to a string public attr",
             path
           )
         )}
    end
  end

  defp validate_decorative_policy(policy, target, indexes, path, diagnostics) do
    has_alt_name? = Map.has_key?(policy, "alt_attr_name")
    exact_keys? = map_size(policy) == 1

    has_alt_projection? = Map.has_key?(indexes.render_by_node_role, {target, :asset_alt})

    if has_alt_name? or not exact_keys? or has_alt_projection? do
      {false,
       add(
         diagnostics,
         error_at(
           "componentization_plan.accessibility.image_policy_invalid",
           "decorative image policy cannot declare an alt attr or asset_alt projection",
           path
         )
       )}
    else
      {true, diagnostics}
    end
  end

  defp validate_collection_item_image_sources(
         indexes,
         boundary_ids,
         valid_source_nodes,
         diagnostics
       ) do
    Enum.reduce(indexes.value_bindings, {valid_source_nodes, diagnostics}, fn
      {id,
       %ValueBinding{scope: :collection_item, target_kind: :asset, target_node_id: target} =
           binding},
      {nodes, acc} ->
        if MapSet.member?(boundary_ids, target) and
             match?(%DesignNode{semantic_type: "image"}, Map.get(indexes.nodes_by_id, target)) do
          projections = Map.get(indexes.bindings_by_source, {:value, id}, [])

          case projections do
            [
              %BindingProjection{
                projection_kind: :collection_item_field,
                source_collection_binding_id: collection_id,
                item_field_name: field_name
              }
            ] ->
              source_field =
                get_in(indexes.item_fields_by_collection, [collection_id, field_name])

              case source_field do
                %ItemField{} ->
                  {valid?, acc} =
                    validate_item_image_policy(
                      source_field,
                      field_name,
                      collection_id,
                      binding,
                      target,
                      indexes,
                      acc
                    )

                  {if(valid?, do: MapSet.put(nodes, target), else: nodes), acc}

                _ ->
                  {nodes,
                   add(
                     acc,
                     error_at(
                       "componentization_plan.accessibility.item_image_policy_missing",
                       "collection image source ItemField does not resolve",
                       "value_bindings[#{id}]"
                     )
                   )}
              end

            _ ->
              {nodes,
               add(
                 acc,
                 error_at(
                   "componentization_plan.accessibility.item_image_policy_missing",
                   "collection image source requires one collection item projection",
                   "value_bindings[#{id}]"
                 )
               )}
          end
        else
          {nodes, acc}
        end

      _other, state ->
        state
    end)
  end

  defp validate_item_image_policy(
         source_field,
         field_name,
         collection_id,
         image_binding,
         target,
         indexes,
         diagnostics
       ) do
    {:ok, policy} = Json.normalize(source_field.accessibility)

    case Map.get(policy, "image_alt_policy") do
      nil ->
        {false,
         add(
           diagnostics,
           error_at(
             "componentization_plan.accessibility.item_image_policy_missing",
             "collection image ItemField requires an explicit accessibility policy",
             "item_fields[#{collection_id}.#{field_name}]"
           )
         )}

      "consumer_supplied" ->
        validate_item_consumer_alt(
          policy,
          collection_id,
          image_binding,
          target,
          indexes,
          diagnostics
        )

      "decorative" ->
        validate_item_decorative(
          policy,
          collection_id,
          image_binding,
          target,
          indexes,
          diagnostics
        )

      _unknown ->
        {false,
         add(
           diagnostics,
           error_at(
             "componentization_plan.accessibility.item_image_policy_invalid",
             "image_alt_policy is not supported for a collection image",
             "item_fields[#{collection_id}.#{field_name}]"
           )
         )}
    end
  end

  defp validate_item_consumer_alt(
         policy,
         collection_id,
         image_binding,
         target,
         indexes,
         diagnostics
       ) do
    alt_name = Map.get(policy, "alt_item_field_name")
    exact_keys? = map_size(policy) == 3
    required? = Map.get(policy, "required_when_source_present") == true
    alt_field = get_in(indexes.item_fields_by_collection, [collection_id, alt_name])

    diagnostics =
      if required? and exact_keys? do
        diagnostics
      else
        add(
          diagnostics,
          error_at(
            "componentization_plan.accessibility.item_image_policy_invalid",
            "consumer item alt policy requires exactly the approved keys and required_when_source_present = true",
            "item_fields[#{collection_id}.#{alt_name}]"
          )
        )
      end

    case alt_field do
      %ItemField{type: :string} when is_binary(alt_name) and alt_name != "" ->
        valid? =
          case Map.get(indexes.item_field_projection_index, {collection_id, alt_name}) do
            {1, targets} ->
              MapSet.member?(targets, target) and
                image_binding.collection_binding_id == collection_id

            _ ->
              false
          end

        if valid? and required? and exact_keys? do
          {true, diagnostics}
        else
          {false,
           add(
             diagnostics,
             error_at(
               "componentization_plan.accessibility.alt_item_projection_mismatch",
               "consumer item alt requires one sibling text binding to the same image node and collection",
               "item_fields[#{collection_id}.#{alt_name}]"
             )
           )}
        end

      _ ->
        {false,
         add(
           diagnostics,
           error_at(
             "componentization_plan.accessibility.alt_item_field_missing",
             "alt_item_field_name must resolve to a string ItemField in the same CollectionInput",
             "item_fields[#{collection_id}.#{alt_name}]"
           )
         )}
    end
  end

  defp validate_item_decorative(
         policy,
         collection_id,
         image_binding,
         target,
         indexes,
         diagnostics
       ) do
    alt_name? = Map.has_key?(policy, "alt_item_field_name")
    exact_keys? = map_size(policy) == 1

    sibling_text_binding? =
      MapSet.member?(indexes.collection_item_text_targets, {collection_id, target})

    if alt_name? or not exact_keys? or image_binding.collection_binding_id != collection_id or
         sibling_text_binding? do
      {false,
       add(
         diagnostics,
         error_at(
           "componentization_plan.accessibility.item_image_policy_invalid",
           "decorative collection image cannot name or bind a sibling alt field",
           "item_fields[#{collection_id}]"
         )
       )}
    else
      {true, diagnostics}
    end
  end

  defp validate_static_images(indexes, valid_source_nodes, diagnostics) do
    Enum.reduce(indexes.static_image_ids, diagnostics, fn id, acc ->
      if MapSet.member?(valid_source_nodes, id) do
        acc
      else
        add(
          acc,
          error_at(
            "componentization_plan.accessibility.static_image_unsupported",
            "in-boundary image lacks an authorized public source and accessibility policy",
            "nodes[#{id}]"
          )
        )
      end
    end)
  end

  defp validate_unsupported_nodes(indexes, diagnostics) do
    Enum.reduce(indexes.unsupported_node_ids, diagnostics, fn id, acc ->
      add(
        acc,
        error_at(
          "componentization_plan.unsupported_node",
          "unsupported DesignNode semantic_type blocks plan validation",
          "nodes[#{id}]"
        )
      )
    end)
  end

  defp normalized_registry(registry) when is_map(registry) and not is_struct(registry),
    do: registry

  defp normalized_registry(_registry), do: %{}

  defp binding_public_target(%BindingProjection{public_attr_name: name}) when is_binary(name),
    do: {:attr, name}

  defp binding_public_target(%BindingProjection{public_slot_name: name}) when is_binary(name),
    do: {:slot, name}

  defp binding_public_target(_projection), do: nil

  defp render_public_target(%RenderProjection{public_attr_name: name, public_slot_name: nil}),
    do: {:attr, name}

  defp render_public_target(%RenderProjection{public_attr_name: nil, public_slot_name: name}),
    do: {:slot, name}

  defp append_result(diagnostics, :ok), do: diagnostics
  defp append_result(diagnostics, {:error, values}), do: diagnostics ++ values

  defp contract_approval_result(%ComponentContract{approval_status: :approved}), do: :ok

  defp contract_approval_result(%ComponentContract{}) do
    {:error,
     [
       %ContractDiagnostic{
         code: "component_contract.approval_blocked",
         severity: :error,
         message: "contract is not approved for generation"
       }
     ]}
  end

  defp contract_approval_result(_contract), do: :ok

  defp append_contract_gate(diagnostics, :ok), do: diagnostics

  defp append_contract_gate(diagnostics, {:error, upstream}) do
    [
      upstream_error(
        "componentization_plan.contract.mismatch",
        "ComponentContract is not generation-eligible",
        upstream
      )
      | diagnostics
    ]
  end

  defp upstream_error(code, message, diagnostics) do
    codes =
      diagnostics
      |> Enum.map(&Map.get(&1, :code))
      |> Enum.filter(&is_binary/1)
      |> Enum.uniq()
      |> Enum.sort()

    %Diagnostic{
      code: code,
      severity: :error,
      message: message,
      metadata: %{"upstream_codes" => codes}
    }
  end

  defp generation_blocked(diagnostics) do
    codes =
      diagnostics
      |> Enum.map(& &1.code)
      |> Enum.filter(&is_binary/1)
      |> Enum.uniq()
      |> Enum.sort()

    %Diagnostic{
      code: "componentization_plan.generation_blocked",
      severity: :error,
      message: "generation inputs contain blocking plan or contract diagnostics",
      metadata: %{"blocking_codes" => codes}
    }
  end

  defp finish([]), do: :ok

  defp finish(diagnostics) do
    {:error,
     diagnostics
     |> Enum.sort_by(fn diagnostic ->
       {diagnostic.path || "", diagnostic.code || "", diagnostic.message || ""}
     end)}
  end

  defp add(diagnostics, diagnostic), do: [diagnostic | diagnostics]

  defp error(code, message),
    do: %Diagnostic{code: code, severity: :error, message: message}

  defp error_at(code, message, path),
    do: %Diagnostic{code: code, severity: :error, message: message, path: path}
end
