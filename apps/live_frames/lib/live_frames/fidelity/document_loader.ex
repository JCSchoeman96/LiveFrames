defmodule LiveFrames.Fidelity.DocumentLoader do
  @moduledoc "Loads the committed JSON representation into validated IR structs."

  alias LiveFrames.IR

  alias LiveFrames.IR.{
    AssetReference,
    DesignDocument,
    DesignNode,
    Diagnostic,
    ResponsiveOverride,
    SourceTrace,
    StyleValue
  }

  def from_file(path) when is_binary(path) do
    with {:ok, json} <- File.read(path), {:ok, map} <- Jason.decode(json), do: from_map(map)
  end

  def from_map(map) when is_map(map) do
    document = %DesignDocument{
      ir_version: map["ir_version"],
      source_metadata: map["source_metadata"] || %{},
      token_set: map["token_set"] || %{},
      root_nodes: Enum.map(map["root_nodes"] || [], &decode_node/1),
      assets: Map.new(map["assets"] || %{}, fn {id, value} -> {id, asset(value)} end),
      interactions: %{},
      diagnostics: Enum.map(map["diagnostics"] || [], &diagnostic/1),
      provenance: map["provenance"] || %{}
    }

    case IR.validate(document) do
      :ok -> {:ok, document}
      {:error, diagnostics} -> {:error, diagnostics}
    end
  end

  def from_map(_), do: {:error, [:invalid_document]}

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
  defp style_kind("literal"), do: :literal
  defp style_kind("token_ref"), do: :token_ref
  defp style_kind("calculation"), do: :calculation
  defp style_kind("keyword"), do: :keyword
  defp style_kind("responsive"), do: :responsive
  defp style_kind("complex_css"), do: :complex_css
  defp style_kind("unresolved"), do: :unresolved
end
