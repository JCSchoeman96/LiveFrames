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

  @required_v2_root_fields ~w(
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
         :ok <- require_v2_root_shape(migrated),
         document = decode_document(migrated),
         :ok <- IR.validate(document) do
      {:ok, document}
    else
      {:error, diagnostics} when is_list(diagnostics) -> {:error, diagnostics}
    end
  end

  def from_map(_),
    do: {:error, [loader_error("fidelity.loader.invalid", "expected a JSON object")]}

  defp require_v2_root_shape(map) do
    missing =
      Enum.reject(@required_v2_root_fields, fn field ->
        Map.has_key?(map, field)
      end)

    if missing == [] do
      :ok
    else
      {:error,
       [
         loader_error(
           "ir.document.required_root_missing",
           "serialized Design IR 2.0.0 is missing required root fields: #{Enum.join(missing, ", ")}"
         )
       ]}
    end
  end

  defp decode_document(map) do
    %DesignDocument{
      ir_version: map["ir_version"],
      source_metadata: map["source_metadata"],
      token_set: map["token_set"],
      root_nodes: Enum.map(map["root_nodes"], &decode_node/1),
      assets: Map.new(map["assets"], fn {id, value} -> {id, asset(value)} end),
      interactions: Map.new(map["interactions"], fn {id, value} -> {id, interaction(value)} end),
      collection_bindings:
        Map.new(map["collection_bindings"], fn {id, value} ->
          {id, collection_binding(value)}
        end),
      value_bindings:
        Map.new(map["value_bindings"], fn {id, value} -> {id, value_binding(value)} end),
      diagnostics: Enum.map(map["diagnostics"], &diagnostic/1),
      provenance: map["provenance"]
    }
  end

  defp decode_node(map),
    do: %DesignNode{
      node_id: map["node_id"],
      semantic_type: map["semantic_type"],
      semantic_role: map["semantic_role"],
      label: map["label"],
      content: map["content"],
      attributes: map["attributes"] || %{},
      styles: Map.new(map["styles"] || %{}, fn {key, value} -> {key, style(value)} end),
      responsive:
        Map.new(map["responsive"] || %{}, fn {key, value} -> {key, responsive(value)} end),
      interaction_refs: map["interaction_refs"] || [],
      asset_refs: map["asset_refs"] || [],
      children: Enum.map(map["children"] || [], &decode_node/1),
      source_trace: trace(map["source_trace"])
    }

  defp style(map),
    do: %StyleValue{
      kind: style_kind(map["kind"]),
      value: map["value"],
      source_expression: map["source_expression"],
      source_trace: trace(map["source_trace"]),
      metadata: map["metadata"] || %{}
    }

  defp responsive(map),
    do: %ResponsiveOverride{
      breakpoint_id: map["breakpoint_id"],
      source_name: map["source_name"],
      min_width: map["min_width"],
      max_width: map["max_width"],
      resolution_status: status(map["resolution_status"]),
      styles: Map.new(map["styles"] || %{}, fn {key, value} -> {key, style(value)} end),
      source_trace: trace(map["source_trace"])
    }

  defp asset(map),
    do: %AssetReference{
      asset_id: map["asset_id"],
      kind: map["kind"],
      uri: map["uri"],
      alt: map["alt"],
      status: status(map["status"]),
      metadata: map["metadata"] || %{},
      source_trace: trace(map["source_trace"])
    }

  defp interaction(map),
    do: %Interaction{
      interaction_id: map["interaction_id"],
      intent: map["intent"],
      trigger: map["trigger"],
      target_node_ids: map["target_node_ids"] || [],
      parameters: map["parameters"] || %{},
      source_trace: trace(map["source_trace"])
    }

  defp collection_binding(map),
    do: %CollectionBinding{
      collection_binding_id: map["collection_binding_id"],
      owner_node_id: map["owner_node_id"],
      repeat_root_node_id: map["repeat_root_node_id"],
      parent_collection_binding_id: map["parent_collection_binding_id"],
      normalization_status: collection_normalization_status(map["normalization_status"]),
      source_trace: trace(map["source_trace"])
    }

  defp value_binding(map),
    do: %ValueBinding{
      value_binding_id: map["value_binding_id"],
      target_node_id: map["target_node_id"],
      target_kind: value_target_kind(map["target_kind"]),
      value_kind: value_kind(map["value_kind"]),
      scope: value_scope(map["scope"]),
      value_key: map["value_key"],
      collection_binding_id: map["collection_binding_id"],
      modifier_status: value_modifier_status(map["modifier_status"]),
      normalization_status: value_normalization_status(map["normalization_status"]),
      source_trace: trace(map["source_trace"])
    }

  defp diagnostic(map),
    do:
      Diagnostic.new(
        code: map["code"],
        severity: map["severity"],
        category: map["category"],
        message: map["message"],
        source_trace: trace(map["source_trace"]),
        suggested_action: map["suggested_action"],
        metadata: map["metadata"] || %{}
      )

  defp trace(nil), do: nil

  defp trace(map),
    do:
      struct(
        SourceTrace,
        Enum.reduce(Map.to_list(SourceTrace.__struct__()), [], fn {key, _}, acc ->
          if Map.has_key?(map, Atom.to_string(key)),
            do: [{key, map[Atom.to_string(key)]} | acc],
            else: acc
        end)
      )

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
