defmodule LiveFrames.Fidelity.DocumentLoader do
  @moduledoc "Loads the committed JSON representation into validated IR structs."

  alias LiveFrames.IR

  alias LiveFrames.IR.{
    AssetReference,
    CollectionBinding,
    DesignDocument,
    DesignNode,
    Diagnostic,
    Interaction,
    Migration,
    ResponsiveOverride,
    SourceTrace,
    StyleValue,
    ValueBinding
  }

  @required_current_root_fields ~w(
    ir_version
    source_metadata
    token_set
    root_nodes
    assets
    interactions
    collection_bindings
    value_bindings
    diagnostics
    provenance
  )

  def from_file(path) when is_binary(path) do
    with {:ok, json} <- File.read(path), {:ok, map} <- Jason.decode(json), do: from_map(map)
  end

  def from_map(map) when is_map(map) do
    with {:ok, migrated} <- Migration.to_current(map),
         :ok <- validate_current_root_shapes(migrated),
         {:ok, document} <- decode_document(migrated),
         :ok <- IR.validate(document) do
      {:ok, document}
    else
      {:error, diagnostics} when is_list(diagnostics) -> {:error, diagnostics}
    end
  end

  def from_map(_),
    do: {:error, [loader_error("fidelity.loader.invalid", "expected a JSON object")]}

  defp validate_current_root_shapes(map) do
    missing =
      Enum.reject(@required_current_root_fields, fn field ->
        Map.has_key?(map, field)
      end)

    if missing != [] do
      {:error,
       [
         loader_error(
           "ir.document.required_root_missing",
           "serialized current Design IR is missing required root fields: #{Enum.join(missing, ", ")}"
         )
       ]}
    else
      validate_root_field_shapes(map)
    end
  end

  defp validate_root_field_shapes(map) do
    []
    |> validate_json_object_field(map, "source_metadata")
    |> validate_json_object_field(map, "token_set")
    |> validate_json_list_field(map, "root_nodes")
    |> validate_json_object_field(map, "assets")
    |> validate_json_object_field(map, "interactions")
    |> validate_json_object_field(map, "collection_bindings")
    |> validate_json_object_field(map, "value_bindings")
    |> validate_json_list_field(map, "diagnostics")
    |> validate_json_object_field(map, "provenance")
    |> finish_shape_validation()
  end

  defp validate_json_object_field(diagnostics, map, field) do
    case Map.get(map, field) do
      value when is_map(value) and not is_struct(value) ->
        diagnostics

      _invalid ->
        [
          loader_error(
            "ir.document.root_shape_invalid",
            "#{field} must be a JSON object"
          )
          | diagnostics
        ]
    end
  end

  defp validate_json_list_field(diagnostics, map, field) do
    case Map.get(map, field) do
      value when is_list(value) ->
        diagnostics

      _invalid ->
        [
          loader_error(
            "ir.document.root_shape_invalid",
            "#{field} must be a JSON array"
          )
          | diagnostics
        ]
    end
  end

  defp finish_shape_validation([]), do: :ok
  defp finish_shape_validation(diagnostics), do: {:error, Enum.reverse(diagnostics)}

  defp decode_document(map) do
    with {:ok, root_nodes} <- decode_root_nodes(map["root_nodes"]),
         {:ok, assets} <- decode_registry(map["assets"], "assets", &decode_asset/1),
         {:ok, interactions} <-
           decode_registry(map["interactions"], "interactions", &decode_interaction/1),
         {:ok, collection_bindings} <-
           decode_registry(
             map["collection_bindings"],
             "collection_bindings",
             &decode_collection_binding/1
           ),
         {:ok, value_bindings} <-
           decode_registry(map["value_bindings"], "value_bindings", &decode_value_binding/1),
         {:ok, diagnostics} <- decode_diagnostics(map["diagnostics"]) do
      {:ok,
       %DesignDocument{
         ir_version: map["ir_version"],
         source_metadata: map["source_metadata"],
         token_set: map["token_set"],
         root_nodes: root_nodes,
         assets: assets,
         interactions: interactions,
         collection_bindings: collection_bindings,
         value_bindings: value_bindings,
         diagnostics: diagnostics,
         provenance: map["provenance"]
       }}
    end
  end

  defp decode_root_nodes(nodes) when is_list(nodes) do
    Enum.reduce_while(nodes, {:ok, []}, fn node, {:ok, acc} ->
      case decode_node(node) do
        {:ok, decoded} -> {:cont, {:ok, acc ++ [decoded]}}
        {:error, diagnostics} -> {:halt, {:error, diagnostics}}
      end
    end)
  end

  defp decode_root_nodes(_other),
    do:
      {:error,
       [loader_error("ir.document.root_shape_invalid", "root_nodes must be a JSON array")]}

  defp decode_registry(map, field, decoder) when is_map(map) and not is_struct(map) do
    Enum.reduce_while(Map.to_list(map), {:ok, %{}}, fn {id, value}, {:ok, acc} ->
      if is_binary(id) do
        case decoder.(value) do
          {:ok, decoded} -> {:cont, {:ok, Map.put(acc, id, decoded)}}
          {:error, diagnostics} -> {:halt, {:error, diagnostics}}
        end
      else
        {:halt,
         {:error,
          [
            loader_error(
              "ir.document.registry_key_invalid",
              "#{field} registry keys must be strings"
            )
          ]}}
      end
    end)
  end

  defp decode_registry(_other, field, _decoder),
    do:
      {:error,
       [
         loader_error(
           "ir.document.root_shape_invalid",
           "#{field} must be a JSON object"
         )
       ]}

  defp decode_diagnostics(list) when is_list(list) do
    Enum.reduce_while(list, {:ok, []}, fn entry, {:ok, acc} ->
      case decode_diagnostic(entry) do
        {:ok, decoded} -> {:cont, {:ok, acc ++ [decoded]}}
        {:error, diagnostics} -> {:halt, {:error, diagnostics}}
      end
    end)
  end

  defp decode_diagnostics(_other),
    do:
      {:error,
       [loader_error("ir.document.root_shape_invalid", "diagnostics must be a JSON array")]}

  defp decode_node(map) when is_map(map) and not is_struct(map) do
    with {:ok, styles} <- decode_style_map(Map.get(map, "styles")),
         {:ok, responsive} <- decode_responsive_map(Map.get(map, "responsive")),
         {:ok, children} <- decode_children(Map.get(map, "children")),
         {:ok, interaction_refs} <-
           decode_string_list(Map.get(map, "interaction_refs"), "interaction_refs"),
         {:ok, asset_refs} <- decode_string_list(Map.get(map, "asset_refs"), "asset_refs"),
         {:ok, attributes} <- decode_json_object(Map.get(map, "attributes"), "attributes"),
         {:ok, source_trace} <- decode_source_trace(Map.get(map, "source_trace")) do
      {:ok,
       %DesignNode{
         node_id: map["node_id"],
         semantic_type: map["semantic_type"],
         semantic_role: map["semantic_role"],
         label: map["label"],
         content: map["content"],
         attributes: attributes,
         styles: styles,
         responsive: responsive,
         interaction_refs: interaction_refs,
         asset_refs: asset_refs,
         children: children,
         source_trace: source_trace
       }}
    end
  end

  defp decode_node(_other),
    do:
      {:error, [loader_error("ir.node.invalid", "every root_nodes entry must be a JSON object")]}

  defp decode_children(nil), do: {:ok, []}

  defp decode_children(list) when is_list(list) do
    Enum.reduce_while(list, {:ok, []}, fn child, {:ok, acc} ->
      case decode_node(child) do
        {:ok, decoded} -> {:cont, {:ok, acc ++ [decoded]}}
        {:error, diagnostics} -> {:halt, {:error, diagnostics}}
      end
    end)
  end

  defp decode_children(_other),
    do: {:error, [loader_error("ir.node.children_invalid", "children must be a JSON array")]}

  defp decode_style_map(nil), do: {:ok, %{}}

  defp decode_style_map(map) when is_map(map) and not is_struct(map) do
    Enum.reduce_while(Map.to_list(map), {:ok, %{}}, fn {key, value}, {:ok, acc} ->
      if is_binary(key) do
        case decode_style(value) do
          {:ok, decoded} -> {:cont, {:ok, Map.put(acc, key, decoded)}}
          {:error, diagnostics} -> {:halt, {:error, diagnostics}}
        end
      else
        {:halt,
         {:error,
          [loader_error("ir.style.property_invalid", "style property names must be strings")]}}
      end
    end)
  end

  defp decode_style_map(_other),
    do: {:error, [loader_error("ir.style.map_invalid", "styles must be a JSON object")]}

  defp decode_responsive_map(nil), do: {:ok, %{}}

  defp decode_responsive_map(map) when is_map(map) and not is_struct(map) do
    Enum.reduce_while(Map.to_list(map), {:ok, %{}}, fn {key, value}, {:ok, acc} ->
      if is_binary(key) do
        case decode_responsive(value) do
          {:ok, decoded} -> {:cont, {:ok, Map.put(acc, key, decoded)}}
          {:error, diagnostics} -> {:halt, {:error, diagnostics}}
        end
      else
        {:halt,
         {:error, [loader_error("ir.responsive.key_invalid", "responsive keys must be strings")]}}
      end
    end)
  end

  defp decode_responsive_map(_other),
    do: {:error, [loader_error("ir.responsive.map_invalid", "responsive must be a JSON object")]}

  defp decode_style(map) when is_map(map) and not is_struct(map) do
    with {:ok, metadata} <- decode_json_object(Map.get(map, "metadata"), "metadata"),
         {:ok, source_trace} <- decode_source_trace(Map.get(map, "source_trace")) do
      {:ok,
       %StyleValue{
         kind: style_kind(map["kind"]),
         value: map["value"],
         source_expression: map["source_expression"],
         source_trace: source_trace,
         metadata: metadata
       }}
    end
  end

  defp decode_style(_other),
    do: {:error, [loader_error("ir.style.invalid", "style entries must be JSON objects")]}

  defp decode_responsive(map) when is_map(map) and not is_struct(map) do
    with {:ok, styles} <- decode_style_map(Map.get(map, "styles")),
         {:ok, source_trace} <- decode_source_trace(Map.get(map, "source_trace")) do
      {:ok,
       %ResponsiveOverride{
         breakpoint_id: map["breakpoint_id"],
         source_name: map["source_name"],
         min_width: map["min_width"],
         max_width: map["max_width"],
         resolution_status: status(map["resolution_status"]),
         styles: styles,
         source_trace: source_trace
       }}
    end
  end

  defp decode_responsive(_other),
    do:
      {:error, [loader_error("ir.responsive.invalid", "responsive entries must be JSON objects")]}

  defp decode_asset(map) when is_map(map) and not is_struct(map) do
    with {:ok, metadata} <- decode_json_object(Map.get(map, "metadata"), "metadata"),
         {:ok, source_trace} <- decode_source_trace(Map.get(map, "source_trace")) do
      {:ok,
       %AssetReference{
         asset_id: map["asset_id"],
         kind: map["kind"],
         uri: map["uri"],
         alt: map["alt"],
         status: status(map["status"]),
         metadata: metadata,
         source_trace: source_trace
       }}
    end
  end

  defp decode_asset(_other),
    do: {:error, [loader_error("ir.asset.invalid", "asset registry values must be JSON objects")]}

  defp decode_interaction(map) when is_map(map) and not is_struct(map) do
    with {:ok, target_node_ids} <-
           decode_string_list(Map.get(map, "target_node_ids"), "target_node_ids"),
         {:ok, parameters} <- decode_json_object(Map.get(map, "parameters"), "parameters"),
         {:ok, source_trace} <- decode_source_trace(Map.get(map, "source_trace")) do
      {:ok,
       %Interaction{
         interaction_id: map["interaction_id"],
         intent: map["intent"],
         trigger: map["trigger"],
         target_node_ids: target_node_ids,
         parameters: parameters,
         source_trace: source_trace
       }}
    end
  end

  defp decode_interaction(_other),
    do:
      {:error,
       [
         loader_error(
           "ir.interaction.invalid",
           "interaction registry values must be JSON objects"
         )
       ]}

  defp decode_collection_binding(map) when is_map(map) and not is_struct(map) do
    with {:ok, source_trace} <- decode_source_trace(Map.get(map, "source_trace")) do
      {:ok,
       %CollectionBinding{
         collection_binding_id: map["collection_binding_id"],
         owner_node_id: map["owner_node_id"],
         repeat_root_node_id: map["repeat_root_node_id"],
         parent_collection_binding_id: map["parent_collection_binding_id"],
         normalization_status: collection_normalization_status(map["normalization_status"]),
         source_trace: source_trace
       }}
    end
  end

  defp decode_collection_binding(_other),
    do:
      {:error,
       [
         loader_error(
           "ir.collection_binding.invalid",
           "collection binding registry values must be JSON objects"
         )
       ]}

  defp decode_value_binding(map) when is_map(map) and not is_struct(map) do
    with {:ok, source_trace} <- decode_source_trace(Map.get(map, "source_trace")) do
      {:ok,
       %ValueBinding{
         value_binding_id: map["value_binding_id"],
         target_node_id: map["target_node_id"],
         target_kind: value_target_kind(map["target_kind"]),
         value_kind: value_kind(map["value_kind"]),
         scope: value_scope(map["scope"]),
         value_key: map["value_key"],
         collection_binding_id: map["collection_binding_id"],
         modifier_status: value_modifier_status(map["modifier_status"]),
         normalization_status: value_normalization_status(map["normalization_status"]),
         source_trace: source_trace
       }}
    end
  end

  defp decode_value_binding(_other),
    do:
      {:error,
       [
         loader_error(
           "ir.value_binding.invalid",
           "value binding registry values must be JSON objects"
         )
       ]}

  defp decode_diagnostic(map) when is_map(map) and not is_struct(map) do
    with {:ok, metadata} <- decode_json_object(Map.get(map, "metadata"), "metadata"),
         {:ok, source_trace} <- decode_source_trace(Map.get(map, "source_trace")) do
      {:ok,
       Diagnostic.new(
         code: map["code"],
         severity: map["severity"],
         category: map["category"],
         message: map["message"],
         source_trace: source_trace,
         suggested_action: map["suggested_action"],
         metadata: metadata
       )}
    end
  end

  defp decode_diagnostic(_other),
    do: {:error, [loader_error("ir.diagnostic.invalid", "diagnostics must be JSON objects")]}

  defp decode_json_object(nil, _field), do: {:ok, %{}}

  defp decode_json_object(map, _field) when is_map(map) and not is_struct(map), do: {:ok, map}

  defp decode_json_object(_other, field),
    do:
      {:error, [loader_error("ir.document.root_shape_invalid", "#{field} must be a JSON object")]}

  defp decode_string_list(nil, _field), do: {:ok, []}

  defp decode_string_list(list, _field) when is_list(list) do
    if Enum.all?(list, &is_binary/1) do
      {:ok, list}
    else
      {:error,
       [
         loader_error(
           "ir.reference.invalid",
           "reference lists must contain non-empty strings"
         )
       ]}
    end
  end

  defp decode_string_list(_other, field),
    do:
      {:error, [loader_error("ir.document.root_shape_invalid", "#{field} must be a JSON array")]}

  defp decode_source_trace(nil), do: {:ok, nil}

  defp decode_source_trace(map) when is_map(map) and not is_struct(map) do
    with {:ok, source_settings} <-
           decode_json_object(Map.get(map, "source_settings"), "source_settings"),
         {:ok, metadata} <- decode_json_object(Map.get(map, "metadata"), "metadata"),
         {:ok, source_classes} <-
           decode_string_list(Map.get(map, "source_classes"), "source_classes") do
      {:ok,
       %SourceTrace{
         source_type: map["source_type"],
         source_id: map["source_id"],
         source_path: map["source_path"],
         source_name: map["source_name"],
         source_classes: source_classes,
         source_settings: source_settings,
         adapter: map["adapter"],
         adapter_version: map["adapter_version"],
         inference: map["inference"],
         metadata: metadata
       }}
    end
  end

  defp decode_source_trace(_other),
    do: {:error, [loader_error("ir.trace.invalid", "source_trace must be a JSON object or nil")]}

  defp status("resolved"), do: :resolved
  defp status("unresolved"), do: :unresolved
  defp status(_other), do: :__invalid_enum__

  defp style_kind("literal"), do: :literal
  defp style_kind("token_ref"), do: :token_ref
  defp style_kind("calculation"), do: :calculation
  defp style_kind("keyword"), do: :keyword
  defp style_kind("responsive"), do: :responsive
  defp style_kind("complex_css"), do: :complex_css
  defp style_kind("unresolved"), do: :unresolved
  defp style_kind(_other), do: :__invalid_enum__

  defp collection_normalization_status("normalized"), do: :normalized
  defp collection_normalization_status(_other), do: :__invalid_enum__

  defp value_target_kind("text"), do: :text
  defp value_target_kind("asset"), do: :asset
  defp value_target_kind("link_url"), do: :link_url
  defp value_target_kind(_other), do: :__invalid_enum__

  defp value_kind("field"), do: :field
  defp value_kind("collection_count"), do: :collection_count
  defp value_kind(_other), do: :__invalid_enum__

  defp value_scope("collection_item"), do: :collection_item
  defp value_scope("site"), do: :site
  defp value_scope("collection"), do: :collection
  defp value_scope(_other), do: :__invalid_enum__

  defp value_modifier_status("none"), do: :none
  defp value_modifier_status("opaque"), do: :opaque
  defp value_modifier_status(_other), do: :__invalid_enum__

  defp value_normalization_status("normalized"), do: :normalized
  defp value_normalization_status("evidence_insufficient"), do: :evidence_insufficient
  defp value_normalization_status(_other), do: :__invalid_enum__

  defp loader_error(code, message),
    do: Diagnostic.new(code: code, severity: :error, category: :schema, message: message)
end
