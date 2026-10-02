defmodule LiveFrames.ComponentContract.ReferenceValidation do
  @moduledoc false

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentContract.CollectionInput
  alias LiveFrames.ComponentContract.Diagnostic
  alias LiveFrames.ComponentContract.ItemField
  alias LiveFrames.ComponentContract.Validation, as: ContractValidation
  alias LiveFrames.IR.CollectionBinding
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Validation, as: IRValidation
  alias LiveFrames.IR.ValueBinding

  @spec validate(ComponentContract.t(), term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate(%ComponentContract{} = contract, %DesignDocument{} = document) do
    case IRValidation.validate(document) do
      :ok ->
        case ContractValidation.validate(contract) do
          :ok -> validate_references(contract, document)
          {:error, diagnostics} -> finish(diagnostics)
        end

      {:error, _ir_diagnostics} ->
        finish([
          err(
            "component_contract.reference.design_ir_invalid",
            "Design IR document failed validation"
          )
        ])
    end
  end

  def validate(%ComponentContract{}, _document) do
    finish([
      err(
        "component_contract.contract.invalid",
        "expected a ComponentContract and DesignDocument struct"
      )
    ])
  end

  def validate(_contract, _document) do
    finish([
      err(
        "component_contract.contract.invalid",
        "expected a ComponentContract and DesignDocument struct"
      )
    ])
  end

  defp validate_references(%ComponentContract{} = contract, %DesignDocument{} = document) do
    indexes = build_indexes(document)

    attrs_by_name =
      Map.new(contract.public_attrs, fn %Attr{name: name} = attr -> {name, attr} end)

    slots_by_name = Map.new(contract.public_slots, fn slot -> {slot.name, true} end)

    collection_by_id =
      Map.new(contract.collection_inputs, fn %CollectionInput{source_collection_binding_id: id} =
                                               ci ->
        {id, ci}
      end)

    item_index =
      Map.new(contract.collection_inputs, fn %CollectionInput{
                                               source_collection_binding_id: id,
                                               item_fields: fields
                                             } ->
        {id, Map.new(fields, fn %ItemField{name: name} = field -> {name, field} end)}
      end)

    diagnostics =
      Enum.flat_map(Enum.with_index(contract.binding_projections), fn {projection, idx} ->
        path = "binding_projections[#{idx}]"

        case projection do
          %BindingProjection{} = p ->
            validate_projection(
              p,
              path,
              document,
              indexes,
              attrs_by_name,
              slots_by_name,
              collection_by_id,
              item_index
            )

          _ ->
            [
              err_at(
                "component_contract.projection.invalid",
                "expected BindingProjection struct",
                path: path
              )
            ]
        end
      end)

    diagnostics = diagnostics ++ validate_public_names_against_ir(contract, indexes)
    finish(diagnostics)
  end

  defp validate_projection(
         %BindingProjection{} = p,
         path,
         document,
         indexes,
         attrs_by_name,
         slots_by_name,
         collection_by_id,
         item_index
       ) do
    case p.source_binding_kind do
      :collection ->
        validate_collection_projection(
          p,
          path,
          document,
          indexes,
          attrs_by_name,
          collection_by_id
        )

      :value ->
        validate_value_projection(
          p,
          path,
          document,
          indexes,
          attrs_by_name,
          slots_by_name,
          collection_by_id,
          item_index
        )

      _ ->
        [
          err_at(
            "component_contract.projection.source_kind_invalid",
            "unknown source binding kind",
            path: path
          )
        ]
    end
  end

  defp validate_collection_projection(
         p,
         path,
         document,
         indexes,
         attrs_by_name,
         collection_by_id
       ) do
    case Map.get(document.collection_bindings, p.source_binding_id) do
      %CollectionBinding{} = binding ->
        diagnostics = collection_binding_normalization(binding, path)

        diagnostics =
          if p.target_node_id == binding.repeat_root_node_id do
            diagnostics
          else
            [
              err_at(
                "component_contract.projection.target_node_mismatch",
                "collection projection target must be repeat_root_node_id",
                path: path
              )
              | diagnostics
            ]
          end

        diagnostics =
          if MapSet.member?(indexes.node_ids, p.target_node_id) do
            diagnostics
          else
            [
              err_at(
                "component_contract.projection.target_node_mismatch",
                "target node does not exist",
                path: path
              )
              | diagnostics
            ]
          end

        case p.projection_kind do
          :collection_attr ->
            collection_attr_ir(p, path, binding, diagnostics, attrs_by_name, collection_by_id)

          :collection_item_field ->
            nested_collection_ir(
              p,
              path,
              binding,
              diagnostics,
              collection_by_id,
              item_index_from_inputs(collection_by_id)
            )

          _ ->
            [
              err_at(
                "component_contract.projection.binding_kind_mismatch",
                "invalid collection source projection",
                path: path
              )
              | diagnostics
            ]
        end

      _ ->
        [
          err_at("component_contract.projection.binding_missing", "collection binding not found",
            path: path
          )
        ]
    end
  end

  defp item_index_from_inputs(collection_by_id) do
    Map.new(collection_by_id, fn {id, %CollectionInput{item_fields: fields}} ->
      {id, Map.new(fields, fn %ItemField{name: name} = field -> {name, field} end)}
    end)
  end

  defp collection_binding_normalization(
         %CollectionBinding{normalization_status: :normalized},
         _path
       ),
       do: []

  defp collection_binding_normalization(_binding, path) do
    [
      err_at(
        "component_contract.reference.design_ir_invalid",
        "collection binding normalization state is invalid",
        path: path
      )
    ]
  end

  defp validate_value_projection(
         p,
         path,
         document,
         indexes,
         attrs_by_name,
         slots_by_name,
         collection_by_id,
         item_index
       ) do
    case Map.get(document.value_bindings, p.source_binding_id) do
      %ValueBinding{} = binding ->
        case binding.normalization_status do
          :evidence_insufficient ->
            [
              err_at(
                "component_contract.binding.evidence_insufficient",
                "value binding has insufficient evidence",
                path: path
              )
            ]

          :normalized ->
            if p.target_node_id == binding.target_node_id do
              validate_value_kind_projection(
                p,
                path,
                binding,
                document,
                indexes,
                attrs_by_name,
                slots_by_name,
                collection_by_id,
                item_index
              )
            else
              [
                err_at(
                  "component_contract.projection.target_node_mismatch",
                  "value projection target must match ValueBinding.target_node_id",
                  path: path
                )
              ]
            end

          _ ->
            [
              err_at(
                "component_contract.reference.design_ir_invalid",
                "value binding normalization state is invalid",
                path: path
              )
            ]
        end

      _ ->
        case wrong_registry(document, p) do
          [] ->
            [
              err_at("component_contract.projection.binding_missing", "value binding not found",
                path: path
              )
            ]

          diagnostics ->
            diagnostics
        end
    end
  end

  defp wrong_registry(document, %BindingProjection{source_binding_id: id}) do
    if Map.has_key?(document.collection_bindings, id) do
      [
        err_at(
          "component_contract.projection.binding_kind_mismatch",
          "binding id resolves in wrong registry",
          path: "binding_projections"
        )
      ]
    else
      []
    end
  end

  defp validate_value_kind_projection(
         p,
         path,
         binding,
         document,
         indexes,
         attrs_by_name,
         slots_by_name,
         collection_by_id,
         item_index
       ) do
    node_ok =
      if MapSet.member?(indexes.node_ids, p.target_node_id),
        do: [],
        else: [
          err_at(
            "component_contract.projection.target_node_mismatch",
            "target node does not exist",
            path: path
          )
        ]

    case p.projection_kind do
      :scalar_attr ->
        scalar_attr_ir(p, path, binding, node_ok, attrs_by_name)

      :collection_item_field ->
        collection_item_field_ir(
          p,
          path,
          binding,
          document,
          node_ok,
          collection_by_id,
          item_index
        )

      :collection_count_attr ->
        collection_count_ir(p, path, binding, document, node_ok, attrs_by_name, collection_by_id)

      :slot ->
        slot_ir(p, path, binding, node_ok, slots_by_name)

      _ ->
        [
          err_at(
            "component_contract.projection.binding_kind_mismatch",
            "invalid value source projection",
            path: path
          )
          | node_ok
        ]
    end
  end

  defp scalar_attr_ir(p, path, binding, node_ok, attrs_by_name) do
    cond do
      binding.value_kind != :field or binding.scope != :site or
          binding.collection_binding_id != nil ->
        [
          err_at(
            "component_contract.projection.binding_kind_mismatch",
            "scalar_attr semantic mismatch",
            path: path
          )
          | node_ok
        ]

      not Map.has_key?(attrs_by_name, p.public_attr_name) ->
        [
          err_at("component_contract.projection.target_shape_invalid", "public attr missing",
            path: path
          )
          | node_ok
        ]

      true ->
        node_ok
    end
  end

  defp collection_attr_ir(p, path, binding, node_ok, attrs_by_name, collection_by_id) do
    ci = Map.get(collection_by_id, p.source_collection_binding_id)

    cond do
      binding.parent_collection_binding_id != nil ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "collection_attr requires root collection binding",
            path: path
          )
          | node_ok
        ]

      p.source_collection_binding_id != p.source_binding_id ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "source_collection_binding_id must match source_binding_id",
            path: path
          )
          | node_ok
        ]

      not match?(%CollectionInput{}, ci) ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "collection input missing",
            path: path
          )
          | node_ok
        ]

      ci.public_attr_name != p.public_attr_name ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "collection input public attr does not match projection",
            path: path
          )
          | node_ok
        ]

      ci.parent_collection_binding_id != nil or ci.parent_item_field_name != nil ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "collection input must be root-located for collection_attr",
            path: path
          )
          | node_ok
        ]

      ci.source_collection_binding_id != p.source_binding_id ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "collection input source id mismatch",
            path: path
          )
          | node_ok
        ]

      match?(%Attr{type: :list}, Map.get(attrs_by_name, p.public_attr_name)) ->
        node_ok

      Map.has_key?(attrs_by_name, p.public_attr_name) ->
        [
          err_at(
            "component_contract.projection.target_shape_invalid",
            "public attr must be :list",
            path: path
          )
          | node_ok
        ]

      true ->
        [
          err_at("component_contract.projection.target_shape_invalid", "public attr missing",
            path: path
          )
          | node_ok
        ]
    end
  end

  defp collection_item_field_ir(p, path, binding, document, node_ok, collection_by_id, item_index) do
    nested_count? =
      p.source_binding_kind == :value and p.parent_collection_binding_id != nil and
        p.parent_item_field_name != nil and p.item_field_name == nil

    if nested_count? do
      nested_count_ir(p, path, binding, document, node_ok, collection_by_id, item_index)
    else
      ordinary_item_ir(p, path, binding, node_ok, collection_by_id, item_index)
    end
  end

  defp ordinary_item_ir(p, path, binding, node_ok, collection_by_id, item_index) do
    cond do
      binding.value_kind != :field or binding.scope != :collection_item or
          binding.collection_binding_id == nil ->
        [
          err_at(
            "component_contract.projection.binding_kind_mismatch",
            "ordinary item field semantic mismatch",
            path: path
          )
          | node_ok
        ]

      p.source_collection_binding_id != binding.collection_binding_id ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "collection ownership mismatch",
            path: path
          )
          | node_ok
        ]

      p.parent_collection_binding_id != nil ->
        [
          err_at(
            "component_contract.projection.target_shape_invalid",
            "ordinary item field requires nil parent_collection_binding_id",
            path: path
          )
          | node_ok
        ]

      not Map.has_key?(collection_by_id, p.source_collection_binding_id) ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "collection input missing",
            path: path
          )
          | node_ok
        ]

      p.item_field_name == nil or
          not Map.has_key?(
            Map.get(item_index, p.source_collection_binding_id, %{}),
            p.item_field_name
          ) ->
        [
          err_at("component_contract.projection.target_shape_invalid", "item field missing",
            path: path
          )
          | node_ok
        ]

      true ->
        node_ok
    end
  end

  defp nested_count_ir(p, path, binding, document, node_ok, collection_by_id, item_index) do
    owning_id = binding.collection_binding_id

    cond do
      binding.value_kind != :collection_count or binding.scope != :collection or owning_id == nil ->
        [
          err_at(
            "component_contract.projection.binding_kind_mismatch",
            "nested count semantic mismatch",
            path: path
          )
          | node_ok
        ]

      p.source_collection_binding_id != owning_id ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "collection ownership mismatch",
            path: path
          )
          | node_ok
        ]

      true ->
        case Map.get(document.collection_bindings, owning_id) do
          %CollectionBinding{parent_collection_binding_id: parent_id}
          when is_binary(parent_id) ->
            nested_count_ownership(
              p,
              path,
              parent_id,
              node_ok,
              collection_by_id,
              item_index
            )

          %CollectionBinding{} ->
            [
              err_at(
                "component_contract.projection.collection_ownership_mismatch",
                "nested count requires nested owning collection binding",
                path: path
              )
              | node_ok
            ]

          _ ->
            [
              err_at(
                "component_contract.projection.collection_ownership_mismatch",
                "owning collection binding missing",
                path: path
              )
              | node_ok
            ]
        end
    end
  end

  defp nested_count_ownership(
         p,
         path,
         owning_parent_id,
         node_ok,
         collection_by_id,
         item_index
       ) do
    child = Map.get(collection_by_id, p.source_collection_binding_id)

    cond do
      p.parent_collection_binding_id != owning_parent_id ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "nested count parent collection binding mismatch",
            path: path
          )
          | node_ok
        ]

      not match?(%CollectionInput{}, child) ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "collection input missing",
            path: path
          )
          | node_ok
        ]

      child.parent_collection_binding_id != p.parent_collection_binding_id ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "child collection input parent id mismatch",
            path: path
          )
          | node_ok
        ]

      child.count_item_field_name != p.parent_item_field_name ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "nested count item field mismatch",
            path: path
          )
          | node_ok
        ]

      true ->
        parent_fields = Map.get(item_index, p.parent_collection_binding_id, %{})

        case Map.get(parent_fields, p.parent_item_field_name) do
          %ItemField{type: :integer, validation: validation} ->
            if ContractValidation.non_negative_validation?(validation) do
              node_ok
            else
              [
                err_at(
                  "component_contract.projection.collection_ownership_mismatch",
                  "nested count parent item field requires non-negative validation",
                  path: path
                )
                | node_ok
              ]
            end

          %ItemField{} ->
            [
              err_at(
                "component_contract.projection.collection_ownership_mismatch",
                "nested count parent item field must be integer",
                path: path
              )
              | node_ok
            ]

          _ ->
            [
              err_at(
                "component_contract.projection.collection_ownership_mismatch",
                "nested count parent item field missing",
                path: path
              )
              | node_ok
            ]
        end
    end
  end

  defp nested_collection_ir(p, path, binding, diagnostics, collection_by_id, item_index) do
    child = Map.get(collection_by_id, p.source_collection_binding_id)

    cond do
      binding.parent_collection_binding_id == nil ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "nested collection requires parent binding",
            path: path
          )
          | diagnostics
        ]

      p.source_collection_binding_id != p.source_binding_id ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "source_collection_binding_id must match source_binding_id",
            path: path
          )
          | diagnostics
        ]

      p.parent_collection_binding_id != binding.parent_collection_binding_id ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "parent collection binding mismatch",
            path: path
          )
          | diagnostics
        ]

      not match?(%CollectionInput{}, child) ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "collection input missing",
            path: path
          )
          | diagnostics
        ]

      child.parent_collection_binding_id != p.parent_collection_binding_id ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "child collection input parent id mismatch",
            path: path
          )
          | diagnostics
        ]

      child.parent_item_field_name != p.parent_item_field_name ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "child collection input parent item field mismatch",
            path: path
          )
          | diagnostics
        ]

      true ->
        parent_fields = Map.get(item_index, p.parent_collection_binding_id, %{})

        case Map.get(parent_fields, p.parent_item_field_name) do
          %ItemField{type: :list} ->
            diagnostics

          %ItemField{} ->
            [
              err_at(
                "component_contract.projection.collection_ownership_mismatch",
                "parent item field must be :list",
                path: path
              )
              | diagnostics
            ]

          _ ->
            [
              err_at(
                "component_contract.projection.collection_ownership_mismatch",
                "parent item field missing",
                path: path
              )
              | diagnostics
            ]
        end
    end
  end

  defp collection_count_ir(p, path, binding, document, node_ok, attrs_by_name, collection_by_id) do
    root_input = Map.get(collection_by_id, p.source_collection_binding_id)
    owning_id = binding.collection_binding_id

    cond do
      binding.value_kind != :collection_count or binding.scope != :collection or owning_id == nil ->
        [
          err_at(
            "component_contract.projection.binding_kind_mismatch",
            "collection count semantic mismatch",
            path: path
          )
          | node_ok
        ]

      p.source_collection_binding_id != owning_id ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "collection ownership mismatch",
            path: path
          )
          | node_ok
        ]

      true ->
        case Map.get(document.collection_bindings, owning_id) do
          %CollectionBinding{
            parent_collection_binding_id: nil,
            normalization_status: :normalized
          } ->
            collection_count_root_contract(
              p,
              path,
              root_input,
              node_ok,
              attrs_by_name
            )

          %CollectionBinding{parent_collection_binding_id: parent} when not is_nil(parent) ->
            [
              err_at(
                "component_contract.projection.collection_ownership_mismatch",
                "collection count requires root owning collection binding",
                path: path
              )
              | node_ok
            ]

          %CollectionBinding{} ->
            [
              err_at(
                "component_contract.reference.design_ir_invalid",
                "owning collection binding normalization state is invalid",
                path: path
              )
              | node_ok
            ]

          _ ->
            [
              err_at(
                "component_contract.projection.collection_ownership_mismatch",
                "owning collection binding missing",
                path: path
              )
              | node_ok
            ]
        end
    end
  end

  defp collection_count_root_contract(p, path, root_input, node_ok, attrs_by_name) do
    cond do
      not match?(%CollectionInput{}, root_input) ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "collection input missing",
            path: path
          )
          | node_ok
        ]

      root_input.parent_collection_binding_id != nil or root_input.parent_item_field_name != nil ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "count collection input must be root-located",
            path: path
          )
          | node_ok
        ]

      root_input.count_attr_name != p.public_attr_name ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "count attr name mismatch",
            path: path
          )
          | node_ok
        ]

      true ->
        case Map.get(attrs_by_name, p.public_attr_name) do
          %Attr{type: :integer, validation: validation} ->
            if ContractValidation.non_negative_validation?(validation) do
              node_ok
            else
              [
                err_at(
                  "component_contract.projection.target_shape_invalid",
                  "count public attr must be integer with non-negative validation",
                  path: path
                )
                | node_ok
              ]
            end

          %Attr{} ->
            [
              err_at(
                "component_contract.projection.target_shape_invalid",
                "count public attr must be integer with non-negative validation",
                path: path
              )
              | node_ok
            ]

          nil ->
            [
              err_at("component_contract.projection.target_shape_invalid", "public attr missing",
                path: path
              )
              | node_ok
            ]
        end
    end
  end

  defp slot_ir(p, path, binding, node_ok, slots_by_name) do
    cond do
      binding.value_kind != :field or binding.scope != :site or
          binding.collection_binding_id != nil ->
        [
          err_at(
            "component_contract.projection.binding_kind_mismatch",
            "slot projection semantic mismatch",
            path: path
          )
          | node_ok
        ]

      p.source_collection_binding_id != nil or p.parent_collection_binding_id != nil ->
        [
          err_at(
            "component_contract.projection.target_shape_invalid",
            "slot projection cannot reference collections",
            path: path
          )
          | node_ok
        ]

      not Map.has_key?(slots_by_name, p.public_slot_name) ->
        [
          err_at("component_contract.projection.target_shape_invalid", "public slot missing",
            path: path
          )
          | node_ok
        ]

      true ->
        node_ok
    end
  end

  defp validate_public_names_against_ir(contract, indexes) do
    reserved =
      indexes.node_ids
      |> MapSet.union(indexes.value_binding_ids)
      |> MapSet.union(indexes.collection_binding_ids)

    names =
      ([contract.module_intent, contract.function_intent] ++
         Enum.map(contract.public_attrs, & &1.name) ++
         Enum.map(contract.public_slots, & &1.name) ++
         Enum.flat_map(contract.collection_inputs, fn ci ->
           [ci.public_attr_name, ci.count_attr_name] ++ Enum.map(ci.item_fields, & &1.name)
         end))
      |> Enum.reject(&is_nil/1)

    Enum.flat_map(names, fn name ->
      if MapSet.member?(reserved, name) do
        [
          err_at(
            "component_contract.public_name.conflict",
            "public name conflicts with Design IR identifier",
            path: name
          )
        ]
      else
        []
      end
    end)
  end

  defp build_indexes(%DesignDocument{} = document) do
    node_ids =
      document.root_nodes
      |> flatten_nodes([])
      |> Enum.map(& &1.node_id)
      |> Enum.reject(&is_nil/1)
      |> MapSet.new()

    collection_bindings =
      case document.collection_bindings do
        bindings when is_map(bindings) and not is_struct(bindings) -> bindings
        _ -> %{}
      end

    value_bindings =
      case document.value_bindings do
        bindings when is_map(bindings) and not is_struct(bindings) -> bindings
        _ -> %{}
      end

    %{
      node_ids: node_ids,
      value_binding_ids: MapSet.new(Map.keys(value_bindings)),
      collection_binding_ids: MapSet.new(Map.keys(collection_bindings))
    }
  end

  defp flatten_nodes(nodes, acc) when is_list(nodes) do
    Enum.reduce(nodes, acc, fn node, acc ->
      case node do
        %DesignNode{children: children} -> flatten_nodes(children, [node | acc])
        _ -> acc
      end
    end)
  end

  defp flatten_nodes(_, acc), do: acc

  defp finish([]), do: :ok

  defp finish(diagnostics) do
    {:error,
     diagnostics
     |> Enum.sort_by(fn d -> {d.path || "", d.code || "", d.message || ""} end)}
  end

  defp err(code, message), do: Diagnostic.new(code: code, severity: :error, message: message)

  defp err_at(code, message, opts),
    do: Diagnostic.new([code: code, severity: :error, message: message] ++ opts)
end
