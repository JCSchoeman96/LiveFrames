defmodule LiveFrames.ComponentContract.ReferenceValidation do
  @moduledoc false

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentContract.CollectionInput
  alias LiveFrames.ComponentContract.Diagnostic
  alias LiveFrames.ComponentContract.ItemField
  alias LiveFrames.IR.CollectionBinding
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.ValueBinding

  @spec validate(ComponentContract.t(), term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate(%ComponentContract{} = contract, %DesignDocument{} = document) do
    indexes = build_indexes(document)
    attrs_by_name = Map.new(contract.public_attrs, fn %Attr{name: n} -> {n, true} end)
    slots_by_name = Map.new(contract.public_slots, fn s -> {s.name, true} end)

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
        {id, Map.new(fields, fn %ItemField{name: n} -> {n, true} end)}
      end)

    diagnostics =
      contract.binding_projections
      |> Enum.with_index()
      |> Enum.reduce([], fn {projection, idx}, acc ->
        path = "binding_projections[#{idx}]"

        acc ++
          validate_projection(
            projection,
            path,
            document,
            indexes,
            attrs_by_name,
            slots_by_name,
            collection_by_id,
            item_index,
            contract
          )
      end)

    diagnostics =
      diagnostics ++ validate_public_names_against_ir(contract, indexes)

    finish(diagnostics)
  end

  def validate(_contract, _document) do
    finish([
      err(
        "component_contract.contract.invalid",
        "expected ComponentContract and DesignDocument structs"
      )
    ])
  end

  @spec evidence_insufficient_diagnostics(ComponentContract.t(), DesignDocument.t()) :: [
          Diagnostic.t()
        ]
  def evidence_insufficient_diagnostics(
        %ComponentContract{} = contract,
        %DesignDocument{} = document
      ) do
    contract.binding_projections
    |> Enum.flat_map(fn %BindingProjection{source_binding_kind: :value, source_binding_id: id} ->
      case Map.get(document.value_bindings, id) do
        %ValueBinding{normalization_status: :evidence_insufficient} ->
          [
            err(
              "component_contract.binding.evidence_insufficient",
              "referenced value binding has insufficient evidence"
            )
          ]

        _ ->
          []
      end
    end)
  end

  def evidence_insufficient_diagnostics(_, _), do: []

  defp validate_projection(
         %BindingProjection{} = p,
         path,
         document,
         indexes,
         attrs_by_name,
         slots_by_name,
         collection_by_id,
         item_index,
         contract
       ) do
    case p.source_binding_kind do
      :collection ->
        validate_collection_projection(
          p,
          path,
          document,
          indexes,
          attrs_by_name,
          collection_by_id,
          contract
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
          item_index,
          contract
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
         collection_by_id,
         _contract
       ) do
    case Map.get(document.collection_bindings, p.source_binding_id) do
      %CollectionBinding{} = binding ->
        diagnostics = []

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
            nested_collection_ir(p, path, binding, diagnostics, collection_by_id)

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

  defp validate_value_projection(
         p,
         path,
         document,
         indexes,
         attrs_by_name,
         slots_by_name,
         collection_by_id,
         item_index,
         _contract
       ) do
    case Map.get(document.value_bindings, p.source_binding_id) do
      %ValueBinding{} = binding ->
        if binding.normalization_status == :evidence_insufficient do
          [
            err_at(
              "component_contract.binding.evidence_insufficient",
              "value binding has insufficient evidence",
              path: path
            )
          ]
        else
          if p.target_node_id == binding.target_node_id do
            validate_value_kind_projection(
              p,
              path,
              binding,
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
        collection_item_field_ir(p, path, binding, node_ok, collection_by_id, item_index)

      :collection_count_attr ->
        collection_count_ir(p, path, binding, node_ok, attrs_by_name, collection_by_id)

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

      not Map.has_key?(collection_by_id, p.source_collection_binding_id) ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "collection input missing",
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

  defp collection_item_field_ir(p, path, binding, node_ok, collection_by_id, item_index) do
    nested_count? =
      p.source_binding_kind == :value and p.parent_collection_binding_id != nil and
        p.parent_item_field_name != nil and p.item_field_name == nil

    if nested_count? do
      nested_count_ir(p, path, binding, node_ok, collection_by_id)
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

  defp nested_count_ir(p, path, binding, node_ok, collection_by_id) do
    cond do
      binding.value_kind != :collection_count or binding.scope != :collection or
          binding.collection_binding_id == nil ->
        [
          err_at(
            "component_contract.projection.binding_kind_mismatch",
            "nested count semantic mismatch",
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

      true ->
        case Map.get(collection_by_id, p.source_collection_binding_id) do
          %CollectionInput{count_item_field_name: count_field}
          when count_field == p.parent_item_field_name ->
            node_ok

          %CollectionInput{} ->
            [
              err_at(
                "component_contract.projection.collection_ownership_mismatch",
                "nested count parent field mismatch",
                path: path
              )
              | node_ok
            ]

          _ ->
            [
              err_at(
                "component_contract.projection.collection_ownership_mismatch",
                "collection input missing",
                path: path
              )
              | node_ok
            ]
        end
    end
  end

  defp nested_collection_ir(p, path, binding, diagnostics, collection_by_id) do
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

      not Map.has_key?(collection_by_id, p.source_collection_binding_id) ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "collection input missing",
            path: path
          )
          | diagnostics
        ]

      true ->
        diagnostics
    end
  end

  defp collection_count_ir(p, path, binding, node_ok, attrs_by_name, collection_by_id) do
    root_input = Map.get(collection_by_id, p.source_collection_binding_id)

    cond do
      binding.value_kind != :collection_count or binding.scope != :collection or
          binding.collection_binding_id == nil ->
        [
          err_at(
            "component_contract.projection.binding_kind_mismatch",
            "collection count semantic mismatch",
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

      not match?(%CollectionInput{}, root_input) ->
        [
          err_at(
            "component_contract.projection.collection_ownership_mismatch",
            "collection input missing",
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
      (Enum.map(contract.public_attrs, & &1.name) ++
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

    %{
      node_ids: node_ids,
      value_binding_ids: MapSet.new(Map.keys(document.value_bindings || %{})),
      collection_binding_ids: MapSet.new(Map.keys(document.collection_bindings || %{}))
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
