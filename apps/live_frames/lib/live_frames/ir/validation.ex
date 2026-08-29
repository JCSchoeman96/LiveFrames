defmodule LiveFrames.IR.Validation do
  @moduledoc """
  Validates Design IR documents without repairing or dropping input.
  """

  alias LiveFrames.IR.AssetReference
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Diagnostic
  alias LiveFrames.IR.Interaction
  alias LiveFrames.IR.ResponsiveOverride
  alias LiveFrames.IR.SourceTrace
  alias LiveFrames.IR.StyleValue

  @statuses [:resolved, :unresolved]

  @spec validate(term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate(%DesignDocument{} = document) do
    diagnostics = []
    diagnostics = validate_document_fields(document, diagnostics)

    {node_ids, diagnostics} =
      if is_list(document.root_nodes) do
        collect_nodes(document.root_nodes, MapSet.new(), diagnostics, [])
      else
        {MapSet.new(), diagnostics}
      end

    {asset_ids, diagnostics} = validate_assets(document.assets, diagnostics)
    {interaction_ids, diagnostics} = validate_interactions(document.interactions, diagnostics)

    diagnostics =
      if is_list(document.root_nodes) do
        validate_node_references(
          document.root_nodes,
          node_ids,
          asset_ids,
          interaction_ids,
          diagnostics
        )
      else
        diagnostics
      end

    diagnostics = validate_interaction_targets(document.interactions, node_ids, diagnostics)
    diagnostics = validate_diagnostics(document.diagnostics, diagnostics)

    finish(diagnostics)
  end

  def validate(_document) do
    finish([error("ir.document.invalid", "expected a DesignDocument struct", :schema, nil)])
  end

  defp validate_document_fields(document, diagnostics) do
    diagnostics
    |> validate_ir_version(document.ir_version)
    |> require_object(
      document.source_metadata,
      "ir.document.source_metadata_invalid",
      "source_metadata must be a JSON object"
    )
    |> require_object(
      document.token_set,
      "ir.document.token_set_invalid",
      "token_set must be a JSON object"
    )
    |> require_list(
      document.root_nodes,
      "ir.document.root_nodes_invalid",
      "root_nodes must be a list"
    )
    |> require_registry(
      document.assets,
      "ir.document.assets_invalid",
      "assets must be a registry map"
    )
    |> require_registry(
      document.interactions,
      "ir.document.interactions_invalid",
      "interactions must be a registry map"
    )
    |> require_list(
      document.diagnostics,
      "ir.document.diagnostics_invalid",
      "diagnostics must be a list"
    )
    |> require_object(
      document.provenance,
      "ir.document.provenance_invalid",
      "provenance must be a JSON object"
    )
  end

  defp validate_ir_version(diagnostics, "") do
    error(
      diagnostics,
      "ir.document.version_missing",
      "ir_version must be a non-empty string",
      :schema,
      nil
    )
  end

  defp validate_ir_version(diagnostics, version) when is_binary(version) do
    if version == DesignDocument.current_ir_version() do
      diagnostics
    else
      error(
        diagnostics,
        "ir.document.version_unsupported",
        "ir_version is not supported by the current IR contract",
        :schema,
        nil
      )
    end
  end

  defp validate_ir_version(diagnostics, _version),
    do:
      error(
        diagnostics,
        "ir.document.version_invalid",
        "ir_version must be a string",
        :schema,
        nil
      )

  defp collect_nodes(nodes, ids, diagnostics, path) do
    nodes
    |> Enum.with_index(1)
    |> Enum.reduce({ids, diagnostics}, fn {node, index}, {ids, diagnostics} ->
      node_path = path ++ [index]

      case node do
        %DesignNode{} ->
          diagnostics = validate_node(node, diagnostics)
          diagnostics = validate_deterministic_node_id(diagnostics, node.node_id, node_path)
          {ids, diagnostics} = collect_node_id(node.node_id, ids, diagnostics)

          if is_list(node.children) do
            collect_nodes(node.children, ids, diagnostics, node_path)
          else
            {ids, diagnostics}
          end

        _other ->
          {ids,
           error(
             diagnostics,
             "ir.node.invalid",
             "every child of root_nodes must be a DesignNode",
             :schema,
             nil
           )}
      end
    end)
  end

  defp collect_node_id(node_id, ids, diagnostics) do
    cond do
      not non_empty_string?(node_id) ->
        {ids, diagnostics}

      MapSet.member?(ids, node_id) ->
        {ids,
         error(
           diagnostics,
           "ir.node.id_duplicate",
           "node_id must be unique across the document",
           :schema,
           nil
         )}

      true ->
        {MapSet.put(ids, node_id), diagnostics}
    end
  end

  defp validate_deterministic_node_id(diagnostics, node_id, path) do
    expected_id = DesignNode.deterministic_id(path)

    if non_empty_string?(node_id) and node_id == expected_id do
      diagnostics
    else
      if non_empty_string?(node_id) do
        error(
          diagnostics,
          "ir.node.id_not_deterministic",
          "node_id must match its one-based traversal path (expected #{expected_id})",
          :schema,
          nil
        )
      else
        diagnostics
      end
    end
  end

  defp validate_node(node, diagnostics) do
    trace = node.source_trace

    diagnostics
    |> require_string(node.node_id, "ir.node.id_missing", "node_id must be a non-empty string")
    |> require_semantic_type(node.semantic_type)
    |> require_optional_string(
      node.semantic_role,
      "ir.node.semantic_role_invalid",
      "semantic_role must be a string or nil"
    )
    |> require_optional_string(
      node.label,
      "ir.node.label_invalid",
      "label must be a string or nil"
    )
    |> require_json_value(
      node.content,
      "ir.node.content_invalid",
      "content must be JSON-compatible"
    )
    |> require_object(
      node.attributes,
      "ir.node.attributes_invalid",
      "attributes must be a JSON object"
    )
    |> validate_styles(node.styles, trace)
    |> validate_responsive(node.responsive, trace)
    |> validate_reference_list(
      node.interaction_refs,
      "ir.node.interaction_refs_invalid",
      "interaction_refs"
    )
    |> validate_reference_list(node.asset_refs, "ir.node.asset_refs_invalid", "asset_refs")
    |> require_list(node.children, "ir.node.children_invalid", "children must be a list")
    |> validate_source_trace(trace)
  end

  defp require_semantic_type(diagnostics, semantic_type) do
    if semantic_type in DesignNode.semantic_types() do
      diagnostics
    else
      error(
        diagnostics,
        "ir.node.semantic_type_invalid",
        "semantic_type is not supported by the IR contract",
        :schema,
        nil
      )
    end
  end

  defp validate_styles(diagnostics, styles, trace)
       when is_map(styles) and not is_struct(styles) do
    diagnostics =
      validate_unique_keys(
        diagnostics,
        styles,
        "ir.style.property_duplicate",
        "style property names must be unique after JSON normalization",
        trace
      )

    styles
    |> sorted_entries()
    |> Enum.reduce(diagnostics, fn {property, value}, diagnostics ->
      case key_string(property) do
        property when is_binary(property) and property != "" ->
          validate_style_value(diagnostics, value, trace)

        _invalid_property ->
          error(
            diagnostics,
            "ir.style.property_invalid",
            "style property names must be non-empty strings",
            :schema,
            trace
          )
      end
    end)
  end

  defp validate_styles(diagnostics, _styles, trace),
    do: error(diagnostics, "ir.style.map_invalid", "styles must be a JSON object", :schema, trace)

  defp validate_style_value(diagnostics, %StyleValue{} = style, fallback_trace) do
    trace = style.source_trace || fallback_trace

    diagnostics
    |> validate_style_kind(style.kind, trace)
    |> require_json_value(
      style.value,
      "ir.style.value_invalid",
      "style values must be JSON-compatible"
    )
    |> require_optional_string(
      style.source_expression,
      "ir.style.source_expression_invalid",
      "source_expression must be a string or nil"
    )
    |> require_object(
      style.metadata,
      "ir.style.metadata_invalid",
      "style metadata must be a JSON object"
    )
    |> validate_source_trace(style.source_trace)
    |> validate_style_kind_value(style.kind, style.value, trace)
  end

  defp validate_style_value(diagnostics, _style, trace),
    do:
      error(
        diagnostics,
        "ir.style.invalid",
        "style entries must be StyleValue structs",
        :schema,
        trace
      )

  defp validate_style_kind(diagnostics, kind, trace) do
    if kind in StyleValue.kinds() do
      diagnostics
    else
      error(
        diagnostics,
        "ir.style.kind_invalid",
        "style kind is not supported by the IR contract",
        :unsupported_style,
        trace
      )
    end
  end

  defp validate_style_kind_value(diagnostics, :token_ref, value, trace) do
    require_string(
      diagnostics,
      value,
      "ir.style.token_ref_empty",
      "token_ref values must be non-empty strings",
      trace
    )
  end

  defp validate_style_kind_value(diagnostics, kind, value, trace)
       when kind in [:calculation, :keyword] do
    require_string(
      diagnostics,
      value,
      "ir.style.text_value_empty",
      "calculation and keyword values must be non-empty strings",
      trace
    )
  end

  defp validate_style_kind_value(diagnostics, :complex_css, value, trace) do
    require_object(
      diagnostics,
      value,
      "ir.style.complex_css_invalid",
      "complex_css values must be JSON objects",
      trace
    )
  end

  defp validate_style_kind_value(diagnostics, :responsive, value, trace) do
    require_object(
      diagnostics,
      value,
      "ir.style.responsive_invalid",
      "responsive style values must be JSON objects",
      trace
    )
  end

  defp validate_style_kind_value(diagnostics, _kind, _value, _trace), do: diagnostics

  defp validate_responsive(diagnostics, responsive, trace)
       when is_map(responsive) and not is_struct(responsive) do
    diagnostics =
      validate_unique_keys(
        diagnostics,
        responsive,
        "ir.responsive.key_duplicate",
        "responsive keys must be unique after JSON normalization",
        trace
      )

    responsive
    |> sorted_entries()
    |> Enum.reduce(diagnostics, fn {key, override}, diagnostics ->
      case key_string(key) do
        key when is_binary(key) and key != "" ->
          validate_responsive_override(diagnostics, key, override, trace)

        _invalid_key ->
          error(
            diagnostics,
            "ir.responsive.key_invalid",
            "responsive keys must be non-empty strings",
            :schema,
            trace
          )
      end
    end)
  end

  defp validate_responsive(diagnostics, _responsive, trace),
    do:
      error(
        diagnostics,
        "ir.responsive.map_invalid",
        "responsive must be a JSON object",
        :schema,
        trace
      )

  defp validate_responsive_override(
         diagnostics,
         key,
         %ResponsiveOverride{} = override,
         fallback_trace
       ) do
    trace = override.source_trace || fallback_trace

    diagnostics
    |> require_string(
      override.breakpoint_id,
      "ir.responsive.breakpoint_id_missing",
      "breakpoint_id must be a non-empty string",
      trace
    )
    |> compare_breakpoint_key(key, override.breakpoint_id, trace)
    |> require_optional_string(
      override.source_name,
      "ir.responsive.source_name_invalid",
      "source_name must be a string or nil",
      trace
    )
    |> require_dimension(override.min_width, "ir.responsive.min_width_invalid", trace)
    |> require_dimension(override.max_width, "ir.responsive.max_width_invalid", trace)
    |> compare_dimensions(override.min_width, override.max_width, trace)
    |> require_status(override.resolution_status, trace)
    |> require_unresolved_source_name(override.resolution_status, override.source_name, trace)
    |> require_resolved_threshold(
      override.resolution_status,
      override.min_width,
      override.max_width,
      trace
    )
    |> validate_styles(override.styles, trace)
    |> validate_source_trace(override.source_trace)
  end

  defp validate_responsive_override(diagnostics, _key, _override, trace),
    do:
      error(
        diagnostics,
        "ir.responsive.invalid",
        "responsive entries must be ResponsiveOverride structs",
        :schema,
        trace
      )

  defp compare_breakpoint_key(diagnostics, key, breakpoint_id, trace) do
    if is_binary(breakpoint_id) and key == breakpoint_id do
      diagnostics
    else
      error(
        diagnostics,
        "ir.responsive.key_mismatch",
        "responsive map keys must match breakpoint_id",
        :schema,
        trace
      )
    end
  end

  defp require_dimension(diagnostics, nil, _code, _trace), do: diagnostics

  defp require_dimension(diagnostics, value, code, trace) do
    if is_number(value) and value >= 0 do
      diagnostics
    else
      error(
        diagnostics,
        code,
        "breakpoint dimensions must be non-negative numbers or nil",
        :schema,
        trace
      )
    end
  end

  defp compare_dimensions(diagnostics, min_width, max_width, trace)
       when is_number(min_width) and is_number(max_width) and min_width > max_width do
    error(
      diagnostics,
      "ir.responsive.range_invalid",
      "min_width cannot exceed max_width",
      :schema,
      trace
    )
  end

  defp compare_dimensions(diagnostics, _min_width, _max_width, _trace), do: diagnostics

  defp require_status(diagnostics, status, trace) do
    if status in @statuses do
      diagnostics
    else
      error(
        diagnostics,
        "ir.responsive.status_invalid",
        "resolution_status must be resolved or unresolved",
        :schema,
        trace
      )
    end
  end

  defp require_unresolved_source_name(diagnostics, :unresolved, source_name, trace) do
    require_string(
      diagnostics,
      source_name,
      "ir.responsive.source_name_missing",
      "unresolved breakpoints must preserve source_name",
      trace
    )
  end

  defp require_unresolved_source_name(diagnostics, _status, _source_name, _trace), do: diagnostics

  defp require_resolved_threshold(diagnostics, :resolved, nil, nil, trace),
    do:
      error(
        diagnostics,
        "ir.responsive.threshold_missing",
        "resolved breakpoints need min_width or max_width",
        :schema,
        trace
      )

  defp require_resolved_threshold(diagnostics, _status, _min_width, _max_width, _trace),
    do: diagnostics

  defp validate_assets(assets, diagnostics) when is_map(assets) and not is_struct(assets) do
    diagnostics =
      validate_unique_keys(
        diagnostics,
        assets,
        "ir.asset.registry_key_duplicate",
        "asset registry keys must be unique after JSON normalization",
        nil
      )

    Enum.reduce(sorted_entries(assets), {MapSet.new(), diagnostics}, fn {key, asset},
                                                                        {ids, diagnostics} ->
      case key_string(key) do
        nil ->
          {ids,
           error(
             diagnostics,
             "ir.asset.registry_key_invalid",
             "asset registry keys must be strings",
             :schema,
             nil
           )}

        id ->
          ids = MapSet.put(ids, id)
          {ids, validate_asset(diagnostics, id, asset)}
      end
    end)
  end

  defp validate_assets(_assets, diagnostics),
    do:
      {MapSet.new(),
       error(
         diagnostics,
         "ir.asset.registry_invalid",
         "assets must be a JSON object",
         :schema,
         nil
       )}

  defp validate_asset(diagnostics, id, %AssetReference{} = asset) do
    trace = asset.source_trace

    diagnostics
    |> require_string(
      asset.asset_id,
      "ir.asset.id_missing",
      "asset_id must be a non-empty string",
      trace
    )
    |> require_matching_id(
      asset.asset_id,
      id,
      "ir.asset.id_mismatch",
      "asset_id must match its registry key",
      trace
    )
    |> require_string(
      asset.kind,
      "ir.asset.kind_missing",
      "asset kind must be a non-empty string",
      trace
    )
    |> require_member(
      asset.status,
      @statuses,
      "ir.asset.status_invalid",
      "asset status must be resolved or unresolved"
    )
    |> require_optional_string(
      asset.uri,
      "ir.asset.uri_invalid",
      "asset uri must be a string or nil",
      trace
    )
    |> require_resolved_uri(asset.status, asset.uri, trace)
    |> require_optional_string(
      asset.alt,
      "ir.asset.alt_invalid",
      "asset alt must be a string or nil",
      trace
    )
    |> require_object(
      asset.metadata,
      "ir.asset.metadata_invalid",
      "asset metadata must be a JSON object",
      trace
    )
    |> validate_source_trace(trace)
  end

  defp validate_asset(diagnostics, _id, _asset),
    do:
      error(
        diagnostics,
        "ir.asset.invalid",
        "asset registry values must be AssetReference structs",
        :schema,
        nil
      )

  defp require_resolved_uri(diagnostics, :resolved, uri, trace),
    do:
      require_string(
        diagnostics,
        uri,
        "ir.asset.uri_missing",
        "resolved assets must have a non-empty uri",
        trace
      )

  defp require_resolved_uri(diagnostics, _status, _uri, _trace), do: diagnostics

  defp validate_interactions(interactions, diagnostics)
       when is_map(interactions) and not is_struct(interactions) do
    diagnostics =
      validate_unique_keys(
        diagnostics,
        interactions,
        "ir.interaction.registry_key_duplicate",
        "interaction registry keys must be unique after JSON normalization",
        nil
      )

    Enum.reduce(sorted_entries(interactions), {MapSet.new(), diagnostics}, fn {key, interaction},
                                                                              {ids, diagnostics} ->
      case key_string(key) do
        nil ->
          {ids,
           error(
             diagnostics,
             "ir.interaction.registry_key_invalid",
             "interaction registry keys must be strings",
             :schema,
             nil
           )}

        id ->
          ids = MapSet.put(ids, id)
          {ids, validate_interaction(diagnostics, id, interaction)}
      end
    end)
  end

  defp validate_interactions(_interactions, diagnostics),
    do:
      {MapSet.new(),
       error(
         diagnostics,
         "ir.interaction.registry_invalid",
         "interactions must be a JSON object",
         :schema,
         nil
       )}

  defp validate_interaction(diagnostics, id, %Interaction{} = interaction) do
    trace = interaction.source_trace

    diagnostics
    |> require_string(
      interaction.interaction_id,
      "ir.interaction.id_missing",
      "interaction_id must be a non-empty string",
      trace
    )
    |> require_matching_id(
      interaction.interaction_id,
      id,
      "ir.interaction.id_mismatch",
      "interaction_id must match its registry key",
      trace
    )
    |> require_string(
      interaction.intent,
      "ir.interaction.intent_missing",
      "interaction intent must be a non-empty string",
      trace
    )
    |> require_optional_string(
      interaction.trigger,
      "ir.interaction.trigger_invalid",
      "interaction trigger must be a string or nil",
      trace
    )
    |> validate_reference_list(
      interaction.target_node_ids,
      "ir.interaction.targets_invalid",
      "target_node_ids",
      trace
    )
    |> require_object(
      interaction.parameters,
      "ir.interaction.parameters_invalid",
      "interaction parameters must be a JSON object",
      trace
    )
    |> validate_source_trace(trace)
  end

  defp validate_interaction(diagnostics, _id, _interaction),
    do:
      error(
        diagnostics,
        "ir.interaction.invalid",
        "interaction registry values must be Interaction structs",
        :schema,
        nil
      )

  defp validate_node_references(nodes, node_ids, asset_ids, interaction_ids, diagnostics) do
    Enum.reduce(nodes, diagnostics, fn
      %DesignNode{} = node, diagnostics ->
        diagnostics
        |> validate_references(
          node.asset_refs,
          asset_ids,
          "ir.node.asset_reference_missing",
          "asset"
        )
        |> validate_references(
          node.interaction_refs,
          interaction_ids,
          "ir.node.interaction_reference_missing",
          "interaction"
        )
        |> validate_child_references(node.children, node_ids, asset_ids, interaction_ids)

      _other, diagnostics ->
        diagnostics
    end)
  end

  defp validate_child_references(diagnostics, children, node_ids, asset_ids, interaction_ids)
       when is_list(children) do
    validate_node_references(children, node_ids, asset_ids, interaction_ids, diagnostics)
  end

  defp validate_child_references(diagnostics, _children, _node_ids, _asset_ids, _interaction_ids),
    do: diagnostics

  defp validate_references(diagnostics, refs, registry_ids, code, label) when is_list(refs) do
    Enum.reduce(refs, diagnostics, fn ref, diagnostics ->
      if is_binary(ref) and MapSet.member?(registry_ids, ref) do
        diagnostics
      else
        error(
          diagnostics,
          code,
          "#{label} reference does not resolve in the document registry",
          :schema,
          nil
        )
      end
    end)
  end

  defp validate_references(diagnostics, _refs, _registry_ids, _code, _label), do: diagnostics

  defp validate_interaction_targets(interactions, node_ids, diagnostics)
       when is_map(interactions) and not is_struct(interactions) do
    Enum.reduce(sorted_entries(interactions), diagnostics, fn {_id, interaction}, diagnostics ->
      case interaction do
        %Interaction{target_node_ids: targets} when is_list(targets) ->
          Enum.reduce(targets, diagnostics, fn target, diagnostics ->
            if is_binary(target) and MapSet.member?(node_ids, target) do
              diagnostics
            else
              error(
                diagnostics,
                "ir.interaction.target_missing",
                "interaction target does not resolve to a node",
                :schema,
                interaction.source_trace
              )
            end
          end)

        _other ->
          diagnostics
      end
    end)
  end

  defp validate_interaction_targets(_interactions, _node_ids, diagnostics), do: diagnostics

  defp validate_reference_list(diagnostics, refs, code, field, trace \\ nil)

  defp validate_reference_list(diagnostics, refs, _code, _field, _trace) when is_list(refs) do
    Enum.reduce(refs, diagnostics, fn ref, diagnostics ->
      if non_empty_string?(ref) do
        diagnostics
      else
        error(
          diagnostics,
          "ir.reference.invalid",
          "reference lists must contain non-empty strings",
          :schema,
          nil
        )
      end
    end)
  end

  defp validate_reference_list(diagnostics, _refs, code, field, trace),
    do: error(diagnostics, code, "#{field} must be a list of non-empty strings", :schema, trace)

  defp validate_diagnostics(diagnostics, values) when is_list(diagnostics) do
    Enum.reduce(diagnostics, values, fn
      %Diagnostic{} = diagnostic, values ->
        validate_diagnostic(values, diagnostic)

      _other, values ->
        error(
          values,
          "ir.diagnostic.invalid",
          "diagnostics must contain Diagnostic structs",
          :schema,
          nil
        )
    end)
  end

  defp validate_diagnostics(_diagnostics, values),
    do: error(values, "ir.diagnostic.list_invalid", "diagnostics must be a list", :schema, nil)

  defp validate_diagnostic(diagnostics, diagnostic) do
    diagnostics
    |> require_string(
      diagnostic.code,
      "ir.diagnostic.code_missing",
      "diagnostic code must be a non-empty string"
    )
    |> require_status_value(
      diagnostic.severity,
      "ir.diagnostic.severity_invalid",
      "diagnostic severity is invalid"
    )
    |> require_member(
      diagnostic.severity,
      Diagnostic.severities(),
      "ir.diagnostic.severity_invalid",
      "diagnostic severity is invalid"
    )
    |> require_member(
      diagnostic.category,
      Diagnostic.categories(),
      "ir.diagnostic.category_invalid",
      "diagnostic category is invalid"
    )
    |> require_string(
      diagnostic.message,
      "ir.diagnostic.message_missing",
      "diagnostic message must be a non-empty string"
    )
    |> require_optional_string(
      diagnostic.suggested_action,
      "ir.diagnostic.action_invalid",
      "suggested_action must be a string or nil"
    )
    |> require_object(
      diagnostic.metadata,
      "ir.diagnostic.metadata_invalid",
      "diagnostic metadata must be a JSON object"
    )
    |> validate_source_trace(diagnostic.source_trace)
  end

  defp validate_source_trace(diagnostics, nil), do: diagnostics

  defp validate_source_trace(diagnostics, %SourceTrace{} = trace) do
    diagnostics
    |> require_optional_string(
      trace.source_type,
      "ir.trace.source_type_invalid",
      "source_type must be a string or nil"
    )
    |> require_optional_string(
      trace.source_id,
      "ir.trace.source_id_invalid",
      "source_id must be a string or nil"
    )
    |> require_optional_string(
      trace.source_path,
      "ir.trace.source_path_invalid",
      "source_path must be a string or nil"
    )
    |> require_optional_string(
      trace.source_name,
      "ir.trace.source_name_invalid",
      "source_name must be a string or nil"
    )
    |> require_string_list(
      trace.global_classes,
      "ir.trace.global_classes_invalid",
      "global_classes must be a list of strings"
    )
    |> require_object(
      trace.source_settings,
      "ir.trace.source_settings_invalid",
      "source_settings must be a JSON object"
    )
    |> require_optional_string(
      trace.adapter,
      "ir.trace.adapter_invalid",
      "adapter must be a string or nil"
    )
    |> require_optional_string(
      trace.adapter_version,
      "ir.trace.adapter_version_invalid",
      "adapter_version must be a string or nil"
    )
    |> require_optional_string(
      trace.inference,
      "ir.trace.inference_invalid",
      "inference must be a string or nil"
    )
    |> require_object(
      trace.metadata,
      "ir.trace.metadata_invalid",
      "trace metadata must be a JSON object"
    )
  end

  defp validate_source_trace(diagnostics, _trace),
    do:
      error(
        diagnostics,
        "ir.trace.invalid",
        "source_trace must be a SourceTrace struct or nil",
        :provenance,
        nil
      )

  defp require_matching_id(diagnostics, value, expected, code, message, trace) do
    if value == expected do
      diagnostics
    else
      error(diagnostics, code, message, :schema, trace)
    end
  end

  defp require_status_value(diagnostics, value, code, message) do
    if is_atom(value) do
      diagnostics
    else
      error(diagnostics, code, message, :schema, nil)
    end
  end

  defp require_member(diagnostics, value, allowed, code, message) do
    if value in allowed do
      diagnostics
    else
      error(diagnostics, code, message, :schema, nil)
    end
  end

  defp require_string_list(diagnostics, value, code, message) when is_list(value) do
    if Enum.all?(value, &non_empty_string?/1) do
      diagnostics
    else
      error(diagnostics, code, message, :schema, nil)
    end
  end

  defp require_string_list(diagnostics, _value, code, message),
    do: error(diagnostics, code, message, :schema, nil)

  defp require_string(diagnostics, value, code, message, trace \\ nil) do
    if non_empty_string?(value) do
      diagnostics
    else
      error(diagnostics, code, message, :schema, trace)
    end
  end

  defp require_optional_string(diagnostics, value, code, message, trace \\ nil)

  defp require_optional_string(diagnostics, nil, _code, _message, _trace), do: diagnostics

  defp require_optional_string(diagnostics, value, code, message, trace) do
    require_string(diagnostics, value, code, message, trace)
  end

  defp require_object(diagnostics, value, code, message, trace \\ nil) do
    if json_object?(value) do
      diagnostics
    else
      error(diagnostics, code, message, :schema, trace)
    end
  end

  defp require_registry(diagnostics, value, code, message) do
    if is_map(value) and not is_struct(value) do
      diagnostics
    else
      error(diagnostics, code, message, :schema, nil)
    end
  end

  defp validate_unique_keys(diagnostics, map, code, message, trace) do
    keys = Enum.map(map, fn {key, _value} -> key_string(key) end)

    if Enum.all?(keys, &is_binary/1) and MapSet.size(MapSet.new(keys)) < map_size(map) do
      error(diagnostics, code, message, :schema, trace)
    else
      diagnostics
    end
  end

  defp require_list(diagnostics, value, code, message) do
    if is_list(value) do
      diagnostics
    else
      error(diagnostics, code, message, :schema, nil)
    end
  end

  defp require_json_value(diagnostics, value, code, message) do
    if json_value?(value) do
      diagnostics
    else
      error(diagnostics, code, message, :schema, nil)
    end
  end

  defp error(code, message, category, trace),
    do:
      Diagnostic.new(
        code: code,
        severity: :error,
        category: category,
        message: message,
        source_trace: normalize_trace(trace)
      )

  defp error(diagnostics, code, message, category, trace),
    do: [error(code, message, category, trace) | diagnostics]

  defp finish([]), do: :ok
  defp finish(diagnostics), do: {:error, Enum.reverse(diagnostics)}

  defp sorted_entries(map) do
    Enum.sort_by(map, fn {key, _value} -> key_string(key) || inspect(key) end)
  end

  defp key_string(value) when is_binary(value), do: value

  defp key_string(value) when is_atom(value) and value not in [nil, true, false],
    do: Atom.to_string(value)

  defp key_string(_value), do: nil

  defp non_empty_string?(value), do: is_binary(value) and byte_size(value) > 0

  defp json_object?(value) when is_map(value) and not is_struct(value),
    do:
      value
      |> Enum.map(fn {key, nested} -> {key_string(key), json_value?(nested)} end)
      |> then(fn entries ->
        valid_entries? =
          Enum.all?(entries, fn {key, valid?} -> is_binary(key) and valid? end)

        unique_keys? =
          entries
          |> Enum.map(&elem(&1, 0))
          |> MapSet.new()
          |> MapSet.size() == map_size(value)

        valid_entries? and unique_keys?
      end)

  defp json_object?(_value), do: false

  defp json_value?(nil), do: true
  defp json_value?(value) when is_binary(value), do: true
  defp json_value?(value) when is_boolean(value), do: true
  defp json_value?(value) when is_integer(value), do: true
  defp json_value?(value) when is_float(value), do: true
  defp json_value?(value) when is_list(value), do: Enum.all?(value, &json_value?/1)

  defp json_value?(value) when is_map(value) and not is_struct(value), do: json_object?(value)

  defp json_value?(_value), do: false

  defp normalize_trace(nil), do: nil
  defp normalize_trace(%SourceTrace{} = trace), do: trace
  defp normalize_trace(_trace), do: nil
end
