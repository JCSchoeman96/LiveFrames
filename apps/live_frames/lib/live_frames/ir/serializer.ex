defmodule LiveFrames.IR.Serializer do
  @moduledoc """
  Converts validated IR structs to explicit JSON objects.
  """

  alias LiveFrames.IR.AssetReference
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Diagnostic
  alias LiveFrames.IR.Interaction
  alias LiveFrames.IR.ResponsiveOverride
  alias LiveFrames.IR.SourceTrace
  alias LiveFrames.IR.StyleValue

  @spec to_map(DesignDocument.t()) :: map()
  def to_map(%DesignDocument{} = document) do
    %{
      "ir_version" => document.ir_version,
      "source_metadata" => normalize_json(document.source_metadata),
      "token_set" => normalize_json(document.token_set),
      "root_nodes" => Enum.map(document.root_nodes, &node_to_map/1),
      "assets" => registry_to_map(document.assets, &asset_to_map/1),
      "interactions" => registry_to_map(document.interactions, &interaction_to_map/1),
      "diagnostics" => Enum.map(document.diagnostics, &diagnostic_to_map/1),
      "provenance" => normalize_json(document.provenance)
    }
  end

  @spec encode(DesignDocument.t()) :: {:ok, String.t()} | {:error, Exception.t()}
  def encode(%DesignDocument{} = document) do
    Jason.encode(ordered(to_map(document)), maps: :strict)
  end

  @spec encode!(DesignDocument.t()) :: String.t()
  def encode!(%DesignDocument{} = document),
    do: Jason.encode!(ordered(to_map(document)), maps: :strict)

  defp node_to_map(%DesignNode{} = node) do
    %{
      "node_id" => node.node_id,
      "semantic_type" => node.semantic_type,
      "semantic_role" => node.semantic_role,
      "label" => node.label,
      "content" => normalize_json(node.content),
      "attributes" => normalize_json(node.attributes),
      "styles" => style_map(node.styles),
      "responsive" => responsive_map(node.responsive),
      "interaction_refs" => node.interaction_refs,
      "asset_refs" => node.asset_refs,
      "children" => Enum.map(node.children, &node_to_map/1),
      "source_trace" => source_trace_to_map(node.source_trace)
    }
  end

  defp style_map(styles), do: registry_to_map(styles, &style_to_map/1)

  defp responsive_map(responsive), do: registry_to_map(responsive, &responsive_to_map/1)

  defp asset_to_map(%AssetReference{} = asset) do
    %{
      "asset_id" => asset.asset_id,
      "kind" => asset.kind,
      "uri" => asset.uri,
      "alt" => asset.alt,
      "status" => Atom.to_string(asset.status),
      "metadata" => normalize_json(asset.metadata),
      "source_trace" => source_trace_to_map(asset.source_trace)
    }
  end

  defp interaction_to_map(%Interaction{} = interaction) do
    %{
      "interaction_id" => interaction.interaction_id,
      "intent" => interaction.intent,
      "trigger" => interaction.trigger,
      "target_node_ids" => interaction.target_node_ids,
      "parameters" => normalize_json(interaction.parameters),
      "source_trace" => source_trace_to_map(interaction.source_trace)
    }
  end

  defp responsive_to_map(%ResponsiveOverride{} = override) do
    %{
      "breakpoint_id" => override.breakpoint_id,
      "source_name" => override.source_name,
      "min_width" => override.min_width,
      "max_width" => override.max_width,
      "resolution_status" => Atom.to_string(override.resolution_status),
      "styles" => style_map(override.styles),
      "source_trace" => source_trace_to_map(override.source_trace)
    }
  end

  defp style_to_map(%StyleValue{} = style) do
    %{
      "kind" => Atom.to_string(style.kind),
      "value" => normalize_json(style.value),
      "source_expression" => style.source_expression,
      "source_trace" => source_trace_to_map(style.source_trace),
      "metadata" => normalize_json(style.metadata)
    }
  end

  defp diagnostic_to_map(%Diagnostic{} = diagnostic) do
    %{
      "code" => diagnostic.code,
      "severity" => Atom.to_string(diagnostic.severity),
      "category" => Atom.to_string(diagnostic.category),
      "message" => diagnostic.message,
      "source_trace" => source_trace_to_map(diagnostic.source_trace),
      "suggested_action" => diagnostic.suggested_action,
      "metadata" => normalize_json(diagnostic.metadata)
    }
  end

  defp source_trace_to_map(nil), do: nil

  defp source_trace_to_map(%SourceTrace{} = trace) do
    %{
      "source_type" => trace.source_type,
      "source_id" => trace.source_id,
      "source_path" => trace.source_path,
      "source_name" => trace.source_name,
      "source_classes" => trace.source_classes,
      "source_settings" => normalize_json(trace.source_settings),
      "adapter" => trace.adapter,
      "adapter_version" => trace.adapter_version,
      "inference" => trace.inference,
      "metadata" => normalize_json(trace.metadata)
    }
  end

  defp registry_to_map(map, converter) when is_map(map) do
    Map.new(map, fn {key, value} -> {key_string!(key), converter.(value)} end)
  end

  defp normalize_json(nil), do: nil
  defp normalize_json(value) when is_binary(value), do: value
  defp normalize_json(value) when is_boolean(value), do: value
  defp normalize_json(value) when is_integer(value) or is_float(value), do: value
  defp normalize_json(value) when is_list(value), do: Enum.map(value, &normalize_json/1)

  defp normalize_json(value) when is_map(value) and not is_struct(value) do
    Map.new(value, fn {key, nested} -> {key_string!(key), normalize_json(nested)} end)
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

  defp key_string!(key) when is_binary(key), do: key

  defp key_string!(key) when is_atom(key) and key not in [nil, true, false],
    do: Atom.to_string(key)

  defp key_string!(key),
    do: raise(ArgumentError, "JSON object key must be a string or atom: #{inspect(key)}")
end
