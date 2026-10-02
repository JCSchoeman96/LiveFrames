defmodule LiveFrames.ComponentContract.Serializer do
  @moduledoc """
  Converts ComponentContract structs to deterministic JSON objects.
  """

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentContract.CollectionInput
  alias LiveFrames.ComponentContract.Diagnostic
  alias LiveFrames.ComponentContract.ItemField
  alias LiveFrames.ComponentContract.Json
  alias LiveFrames.ComponentContract.Slot

  @spec to_map(ComponentContract.t()) :: map()
  def to_map(%ComponentContract{} = contract) do
    %{
      "approval_status" => Atom.to_string(contract.approval_status),
      "binding_projections" => Enum.map(contract.binding_projections, &projection_to_map/1),
      "category" => Atom.to_string(contract.category),
      "collection_inputs" => Enum.map(contract.collection_inputs, &collection_input_to_map/1),
      "contract_format_version" => contract.contract_format_version,
      "contract_id" => contract.contract_id,
      "diagnostics" => Enum.map(contract.diagnostics, &diagnostic_to_map/1),
      "function_intent" => contract.function_intent,
      "module_intent" => contract.module_intent,
      "provenance" => normalize_json(contract.provenance),
      "public_attrs" => Enum.map(contract.public_attrs, &attr_to_map/1),
      "public_slots" => Enum.map(contract.public_slots, &slot_to_map/1)
    }
  end

  @spec encode(ComponentContract.t()) :: {:ok, String.t()} | {:error, Exception.t()}
  def encode(%ComponentContract{} = contract) do
    Jason.encode(ordered(to_map(contract)), maps: :strict)
  end

  @spec encode!(ComponentContract.t()) :: String.t()
  def encode!(%ComponentContract{} = contract),
    do: Jason.encode!(ordered(to_map(contract)), maps: :strict)

  defp attr_to_map(%Attr{} = attr) do
    %{
      "accessibility" => normalize_json(attr.accessibility),
      "default" => normalize_json(attr.default),
      "name" => attr.name,
      "provenance" => normalize_json(attr.provenance),
      "required" => attr.required,
      "semantic_purpose" => attr.semantic_purpose,
      "type" => Atom.to_string(attr.type),
      "validation" => normalize_json(attr.validation)
    }
  end

  defp item_field_to_map(%ItemField{} = field) do
    %{
      "accessibility" => normalize_json(field.accessibility),
      "default" => normalize_json(field.default),
      "name" => field.name,
      "provenance" => normalize_json(field.provenance),
      "required" => field.required,
      "semantic_purpose" => field.semantic_purpose,
      "type" => Atom.to_string(field.type),
      "validation" => normalize_json(field.validation)
    }
  end

  defp slot_to_map(%Slot{} = slot) do
    %{
      "accessibility" => normalize_json(slot.accessibility),
      "cardinality" => slot.cardinality,
      "consumer_responsibility" => slot.consumer_responsibility,
      "name" => slot.name,
      "provenance" => normalize_json(slot.provenance),
      "required" => slot.required,
      "semantic_purpose" => slot.semantic_purpose,
      "validation" => normalize_json(slot.validation)
    }
  end

  defp collection_input_to_map(%CollectionInput{} = input) do
    %{
      "count_attr_name" => input.count_attr_name,
      "count_item_field_name" => input.count_item_field_name,
      "item_fields" => Enum.map(input.item_fields, &item_field_to_map/1),
      "parent_collection_binding_id" => input.parent_collection_binding_id,
      "parent_item_field_name" => input.parent_item_field_name,
      "provenance" => normalize_json(input.provenance),
      "public_attr_name" => input.public_attr_name,
      "source_collection_binding_id" => input.source_collection_binding_id
    }
  end

  defp projection_to_map(%BindingProjection{} = projection) do
    %{
      "item_field_name" => projection.item_field_name,
      "parent_collection_binding_id" => projection.parent_collection_binding_id,
      "parent_item_field_name" => projection.parent_item_field_name,
      "projection_kind" => atom_string(projection.projection_kind),
      "public_attr_name" => projection.public_attr_name,
      "public_slot_name" => projection.public_slot_name,
      "source_binding_id" => projection.source_binding_id,
      "source_binding_kind" => atom_string(projection.source_binding_kind),
      "source_collection_binding_id" => projection.source_collection_binding_id,
      "target_node_id" => projection.target_node_id
    }
  end

  defp diagnostic_to_map(%Diagnostic{} = diagnostic) do
    %{
      "code" => diagnostic.code,
      "message" => diagnostic.message,
      "metadata" => normalize_json(diagnostic.metadata),
      "path" => diagnostic.path,
      "severity" => Atom.to_string(diagnostic.severity),
      "suggested_action" => diagnostic.suggested_action
    }
  end

  defp atom_string(nil), do: nil
  defp atom_string(atom) when is_atom(atom), do: Atom.to_string(atom)

  defp normalize_json(nil), do: nil
  defp normalize_json(value) when is_binary(value), do: value
  defp normalize_json(value) when is_boolean(value), do: value
  defp normalize_json(value) when is_integer(value) or is_float(value), do: value
  defp normalize_json(value) when is_list(value), do: Enum.map(value, &normalize_json/1)

  defp normalize_json(value) when is_map(value) and not is_struct(value) do
    Map.new(value, fn {key, nested} -> {Json.key_string!(key), normalize_json(nested)} end)
  end

  defp normalize_json(value),
    do: raise(ArgumentError, "cannot serialize non-JSON value: #{inspect(value)}")

  defp ordered(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} -> {key, ordered(value)} end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Jason.OrderedObject.new()
  end

  defp ordered(list) when is_list(list), do: Enum.map(list, &ordered/1)
  defp ordered(value), do: value
end
