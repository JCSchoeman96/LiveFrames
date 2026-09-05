defmodule LiveFrames.Adapters.Bricks.DesignIRNormalizer do
  @moduledoc """
  Converts the validated structured Bricks model into Design IR `1.0.0`.

  This module consumes the source adapter's structured stages directly. It does
  not read Stage A HTML, CSS, or report artifacts, and it never evaluates source
  runtime values.
  """

  alias LiveFrames.Adapters.Bricks.ClassResolver
  alias LiveFrames.Adapters.Bricks.DependencyExtractor
  alias LiveFrames.Adapters.Bricks.Diagnostic, as: BricksDiagnostic
  alias LiveFrames.Adapters.Bricks.Document
  alias LiveFrames.Adapters.Bricks.Element
  alias LiveFrames.Adapters.Bricks.Loader
  alias LiveFrames.Adapters.Bricks.Resolver
  alias LiveFrames.Adapters.Bricks.Settings
  alias LiveFrames.Adapters.Bricks.TreeBuilder
  alias LiveFrames.IR
  alias LiveFrames.IR.AssetReference
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Diagnostic
  alias LiveFrames.IR.ResponsiveOverride
  alias LiveFrames.IR.SourceTrace
  alias LiveFrames.IR.StyleValue
  alias LiveFrames.Tokens
  alias LiveFrames.Tokens.Diagnostic, as: TokenDiagnostic
  alias LiveFrames.Tokens.TokenSet

  @default_component_id "sqhmmc"
  @ir_severities [:info, :warning, :error, :fatal]

  @lifecycle [
    "source_model_ready",
    "token_set_bound",
    "nodes_normalized",
    "styles_normalized",
    "responsive_normalized",
    "dependencies_bound",
    "document_assembled",
    "ir_validated",
    "serialized"
  ]

  @keyword_values [
    "absolute",
    "auto",
    "baseline",
    "block",
    "center",
    "contain",
    "cover",
    "column",
    "flex",
    "flex-end",
    "flex-start",
    "fixed",
    "grid",
    "hidden",
    "inherit",
    "initial",
    "inline",
    "inline-block",
    "isolate",
    "none",
    "nowrap",
    "relative",
    "revert",
    "row",
    "space-around",
    "space-between",
    "space-evenly",
    "static",
    "sticky",
    "stretch",
    "unset",
    "visible",
    "wrap"
  ]

  @supported_element_names [
    "section",
    "container",
    "div",
    "heading",
    "text-basic",
    "button",
    "image"
  ]

  @spec normalize(term(), keyword()) ::
          {:ok, DesignDocument.t()} | {:error, [Diagnostic.t()]}
  def normalize(source, opts \\ [])

  def normalize(source, opts) when is_list(opts) do
    with {:ok, token_set} <- validate_token_set(Keyword.get(opts, :token_set)),
         {:ok, document, load_diagnostics} <- load_source(source, opts),
         {:ok, proxy, component, resolve_diagnostics} <-
           Resolver.resolve(document,
             component_id: Keyword.get(opts, :component_id, @default_component_id)
           ),
         {:ok, tree, tree_diagnostics} <- TreeBuilder.build(component),
         :ok <- expected_root_count(tree, opts),
         {:ok, resolved, class_diagnostics} <- ClassResolver.resolve(tree, document) do
      dependencies = DependencyExtractor.extract(resolved, document, token_set: token_set)

      diagnostics =
        load_diagnostics ++
          resolve_diagnostics ++
          tree_diagnostics ++
          class_diagnostics ++
          dependencies.diagnostics ++
          unsupported_element_diagnostics(tree)

      if blocking?(diagnostics) do
        {:error, to_ir_diagnostics(diagnostics)}
      else
        context = %{
          document: document,
          proxy: proxy,
          component: component,
          tree: tree,
          resolved: resolved,
          dependencies: dependencies,
          token_set: token_set,
          component_index: component_index(document, component),
          source_diagnostics: diagnostics
        }

        assemble(context)
      end
    else
      {:error, diagnostics} -> {:error, to_ir_diagnostics(diagnostics)}
    end
  end

  def normalize(_source, _opts) do
    {:error,
     [
       Diagnostic.new(
         code: "bricks.ir.options.invalid",
         severity: :error,
         category: :schema,
         message: "Bricks Design IR options must be a keyword list"
       )
     ]}
  end

  defp validate_token_set(%TokenSet{} = token_set) do
    validation_diagnostics =
      case Tokens.validate(token_set, []) do
        :ok -> []
        {:error, diagnostics} -> diagnostics
      end

    source_diagnostics =
      if Enum.any?(token_set.diagnostics, &(&1.severity in [:error, :fatal])),
        do: token_set.diagnostics,
        else: []

    if validation_diagnostics == [] and source_diagnostics == [] do
      {:ok, token_set}
    else
      {:error, validation_diagnostics ++ source_diagnostics}
    end
  end

  defp validate_token_set(_token_set) do
    {:error,
     [
       Diagnostic.new(
         code: "bricks.ir.token_set_missing",
         severity: :error,
         category: :schema,
         message: "Bricks Design IR normalization requires a validated TokenSet"
       )
     ]}
  end

  defp load_source(%Document{} = document, _opts), do: {:ok, document, []}

  defp load_source(source, opts) when is_map(source), do: Loader.recognize(source, opts)

  defp load_source(source, opts) when is_binary(source) do
    if File.regular?(source),
      do: Loader.from_file(source, opts),
      else: Loader.from_json(source, opts)
  end

  defp load_source(_source, _opts) do
    {:error,
     [
       BricksDiagnostic.new(
         code: "bricks.source.invalid",
         severity: :error,
         message: "Bricks Design IR source must be a document, map, JSON text, or file path"
       )
     ]}
  end

  defp expected_root_count(tree, opts) do
    expected = Keyword.get(opts, :expected_root_count, 1)

    if length(tree.root_ids) == expected do
      :ok
    else
      {:error,
       [
         BricksDiagnostic.new(
           code: "bricks.tree.root_count",
           severity: :error,
           source_path: "components",
           raw_value: tree.root_ids,
           message: "Bricks Design IR expected a different root count",
           metadata: %{"expected" => expected, "actual" => length(tree.root_ids)}
         )
       ]}
    end
  end

  defp assemble(context) do
    trace_index = build_trace_index(context)
    {assets, asset_ids_by_source} = build_assets(context, trace_index)

    context =
      Map.merge(context, %{trace_index: trace_index, asset_ids_by_source: asset_ids_by_source})

    root_nodes =
      context.tree.root_ids
      |> Enum.with_index(1)
      |> Enum.map(fn {source_id, index} -> build_node(source_id, [index], context) end)

    document = %DesignDocument{
      ir_version: DesignDocument.current_ir_version(),
      source_metadata: source_metadata(context),
      token_set: Tokens.to_map(context.token_set),
      root_nodes: root_nodes,
      assets: assets,
      interactions: %{},
      diagnostics: to_ir_diagnostics(context.source_diagnostics, context),
      provenance: provenance(context)
    }

    validate_and_serialize(document)
  end

  defp validate_and_serialize(document) do
    case IR.validate(document) do
      :ok ->
        case encode_document(document) do
          :ok -> {:ok, document}
          {:error, diagnostics} -> {:error, diagnostics}
        end

      {:error, diagnostics} ->
        {:error, diagnostics}
    end
  end

  defp encode_document(document) do
    case IR.encode(document) do
      {:ok, _bytes} -> :ok
      {:error, diagnostics} when is_list(diagnostics) -> {:error, diagnostics}
      {:error, exception} -> {:error, [serialization_diagnostic(exception)]}
    end
  rescue
    exception -> {:error, [serialization_diagnostic(exception)]}
  end

  defp serialization_diagnostic(exception) do
    Diagnostic.new(
      code: "bricks.ir.serialization_failed",
      severity: :fatal,
      category: :schema,
      message: "Design IR serialization failed",
      metadata: %{"reason" => Exception.message(exception)}
    )
  end

  defp build_trace_index(context) do
    Enum.reduce(Enum.with_index(context.tree.root_ids, 1), %{}, fn {source_id, index},
                                                                   index_map ->
      collect_trace(source_id, [index], context, index_map)
    end)
  end

  defp collect_trace(source_id, path, context, index_map) do
    element = Map.fetch!(context.tree.elements, source_id)
    resolved = Map.fetch!(context.resolved.elements, source_id)
    trace = source_trace(element, resolved, path, context)
    index_map = Map.put(index_map, source_id, %{path: path, trace: trace})

    context.tree.children_by_id
    |> Map.get(source_id, [])
    |> Enum.with_index(1)
    |> Enum.reduce(index_map, fn {child_id, child_index}, index_map ->
      collect_trace(child_id, path ++ [child_index], context, index_map)
    end)
  end

  defp source_trace(%Element{} = element, resolved, path, context) do
    %SourceTrace{
      source_type: "bricks_element",
      source_id: element.id,
      source_path: source_path(element, context),
      source_name: element.name,
      source_classes: resolved.class_names,
      source_settings: json_safe(element.settings),
      adapter: "bricks",
      adapter_version: context.document.adapter_version,
      inference: inference_for(element),
      metadata:
        json_safe(%{
          "component_id" => context.component.id,
          "source_index" => element.source_index,
          "parent" => element.parent,
          "children" => element.children,
          "class_ids" => resolved.class_ids,
          "class_names" => resolved.class_names,
          "semantic_classes" => resolved.semantic_classes,
          "class_refs" => simplified_class_refs(resolved.class_refs),
          "effective_settings" => resolved.settings,
          "ir_path" => path
        })
    }
  end

  defp simplified_class_refs(class_refs) do
    Enum.map(class_refs, fn ref ->
      %{
        "id" => ref.id,
        "name" => ref.name,
        "category" => ref.category,
        "status" => ref.status
      }
    end)
  end

  defp source_path(element, context),
    do: "components[#{context.component_index}].elements[#{element.source_index}]"

  defp inference_for(%Element{name: "text-basic", settings: settings}) do
    if Map.get(settings, "tag") == "p",
      do: "paragraph semantics proven by the source element tag",
      else: "text-basic element kept as rich text because paragraph semantics were not proven"
  end

  defp inference_for(%Element{name: "div"}),
    do: "generic structural semantics preserved without source class component inference"

  defp inference_for(%Element{}), do: "direct mapping from the supported Bricks element type"

  defp build_node(source_id, path, context) do
    element = Map.fetch!(context.tree.elements, source_id)
    resolved = Map.fetch!(context.resolved.elements, source_id)
    trace = context.trace_index[source_id].trace
    settings_result = Settings.extract(resolved.settings)

    children =
      context.tree.children_by_id
      |> Map.get(source_id, [])
      |> Enum.with_index(1)
      |> Enum.map(fn {child_id, child_index} ->
        build_node(child_id, path ++ [child_index], context)
      end)

    DesignNode.new(path,
      semantic_type: semantic_type(element),
      semantic_role: nil,
      label: element.label,
      content: content_for(element),
      attributes: attributes_for(element),
      styles: styles_for(settings_result, trace, context.token_set, element),
      responsive: responsive_for(settings_result, trace, resolved.class_names, element, context),
      interaction_refs: [],
      asset_refs: Map.get(context.asset_ids_by_source, source_id, []),
      children: children,
      source_trace: trace
    )
  end

  defp semantic_type(%Element{name: "section"}), do: "section"
  defp semantic_type(%Element{name: "container"}), do: "container"
  defp semantic_type(%Element{name: "div"}), do: "generic"
  defp semantic_type(%Element{name: "heading"}), do: "heading"

  defp semantic_type(%Element{name: "text-basic", settings: settings}) do
    if Map.get(settings, "tag") == "p", do: "paragraph", else: "rich_text"
  end

  defp semantic_type(%Element{name: "button"}), do: "button"
  defp semantic_type(%Element{name: "image"}), do: "image"
  defp semantic_type(%Element{}), do: "unsupported"

  defp content_for(%Element{name: name, settings: settings})
       when name in ["heading", "text-basic", "button"] do
    case Map.get(settings, "text") do
      value when is_binary(value) -> value
      _value -> nil
    end
  end

  defp content_for(_element), do: nil

  defp attributes_for(%Element{settings: settings}) do
    ["tag", "style", "outline", "caption", "link", "url", "alt"]
    |> Enum.reduce(%{}, fn key, attributes ->
      case Map.fetch(settings, key) do
        {:ok, value} -> Map.put(attributes, key, json_safe(value))
        :error -> attributes
      end
    end)
  end

  defp styles_for(settings_result, trace, token_set, element) do
    styles =
      Enum.reduce(settings_result.base_styles, %{}, fn {property, value}, styles ->
        source_key = source_key_for(settings_result.consumed, property, nil)
        style_trace = style_trace(trace, source_key)

        Map.put(
          styles,
          property,
          normalize_style(value, property, style_trace, token_set,
            metadata: %{"source_key" => source_key}
          )
        )
      end)

    styles =
      Enum.reduce(settings_result.unresolved_values, styles, fn {source_key, value}, styles ->
        property = unresolved_property(source_key)

        Map.put(
          styles,
          property,
          StyleValue.unresolved(value,
            source_expression: if(is_binary(value), do: value, else: nil),
            source_trace: style_trace(trace, source_key),
            metadata: %{
              "source_key" => source_key,
              "reason" => "source value has no proven CSS unit or representation"
            }
          )
        )
      end)

    styles =
      Enum.reduce(settings_result.custom_css.base, styles, fn value, styles ->
        source_key = "_cssCustom"

        Map.put(
          styles,
          "custom-css",
          StyleValue.complex_css(
            %{
              "type" => "custom_css",
              "property" => "custom-css",
              "source_key" => source_key,
              "rules" => [value]
            },
            source_expression: value,
            source_trace: style_trace(trace, source_key),
            metadata: %{"source_key" => source_key}
          )
        )
      end)

    styles =
      Enum.reduce(settings_result.gradients, styles, fn gradient, styles ->
        source_key = gradient.source_key

        Map.put(
          styles,
          gradient.property,
          gradient_style(gradient, style_trace(trace, source_key))
        )
      end)

    merge_intrinsic_styles(styles, element, trace)
  end

  # Bricks frontend `.brxe-container` intrinsic layout (frontend-layer.css).
  defp merge_intrinsic_styles(styles, %Element{name: "container"}, trace) do
    styles
    |> put_intrinsic_style(trace, "display", "flex")
    |> put_intrinsic_style(trace, "flex-direction", "column")
  end

  defp merge_intrinsic_styles(styles, _element, _trace), do: styles

  defp put_intrinsic_style(styles, trace, property, value) do
    Map.put_new(
      styles,
      property,
      StyleValue.keyword(value,
        source_expression: value,
        source_trace: %{
          trace
          | source_type: "bricks_intrinsic",
            source_path: "#{trace.source_path}.intrinsic.brxe-container.#{property}",
            source_name: "brxe-container.#{property}"
        },
        metadata: %{
          "authority" => "bricks_intrinsic_element_default",
          "selector" => ".brxe-container"
        }
      )
    )
  end

  defp source_key_for(consumed, property, breakpoint) do
    case Enum.find(consumed, fn record ->
           record.property == property and record.breakpoint == breakpoint
         end) do
      %{source_key: source_key} -> source_key
      _record -> property
    end
  end

  defp unresolved_property("_margin." <> side), do: "margin-" <> side
  defp unresolved_property("_border.radius." <> side), do: "border-" <> side <> "-radius"
  defp unresolved_property(source_key), do: String.trim_leading(source_key, "_")

  defp style_trace(trace, source_key) do
    %{
      trace
      | source_type: "bricks_style",
        source_path: "#{trace.source_path}.settings.#{source_key}",
        source_name: source_key,
        inference: "style value preserved from the structured Bricks settings model"
    }
  end

  defp normalize_style(value, _property, trace, token_set, opts) when is_binary(value) do
    metadata = Keyword.get(opts, :metadata, %{})

    cond do
      value == "var(--content-gap)" and token_present?(token_set, "spacing.content_gap") ->
        StyleValue.token_ref("spacing.content_gap",
          source_expression: value,
          source_trace: trace,
          metadata: Map.merge(metadata, %{"source_variable" => "--content-gap"})
        )

      String.starts_with?(value, "var(") ->
        unresolved_variable_style(value, trace, metadata)

      calculation?(value) ->
        StyleValue.calculation(value,
          source_expression: value,
          source_trace: trace,
          metadata: metadata
        )

      value in @keyword_values ->
        StyleValue.keyword(value,
          source_expression: value,
          source_trace: trace,
          metadata: metadata
        )

      true ->
        StyleValue.literal(value,
          source_expression: value,
          source_trace: trace,
          metadata: metadata
        )
    end
  end

  defp normalize_style(value, _property, trace, _token_set, opts) do
    StyleValue.literal(json_safe(value),
      source_trace: trace,
      metadata: Keyword.get(opts, :metadata, %{})
    )
  end

  defp unresolved_variable_style(value, trace, metadata) do
    metadata =
      case Regex.run(~r/^var\(--content-gap,\s*(.+)\)$/, value) do
        [_, fallback] ->
          Map.merge(metadata, %{"fallback" => fallback, "token_path" => "spacing.content_gap"})

        _other ->
          variable_names =
            Regex.scan(~r/--[A-Za-z0-9_-]+/, value) |> List.flatten() |> Enum.uniq()

          Map.put(metadata, "variable_names", variable_names)
      end

    StyleValue.unresolved(value,
      source_expression: value,
      source_trace: trace,
      metadata: metadata
    )
  end

  defp calculation?(value),
    do: String.starts_with?(value, ["calc(", "clamp(", "min(", "max("])

  defp token_present?(%TokenSet{tokens: tokens}, path), do: Map.has_key?(tokens, path)
  defp token_present?(_token_set, _path), do: false

  defp gradient_style(gradient, trace) do
    StyleValue.complex_css(
      %{
        "type" => "gradient",
        "property" => gradient.property,
        "source_key" => gradient.source_key,
        "value" => json_safe(gradient.raw_value)
      },
      source_trace: trace,
      metadata: %{"source_key" => gradient.source_key}
    )
  end

  defp responsive_for(settings_result, trace, source_classes, element, context) do
    settings_result.responsive
    |> Enum.group_by(& &1.breakpoint)
    |> Enum.sort_by(fn {breakpoint, _records} -> breakpoint end)
    |> Map.new(fn {breakpoint, records} ->
      first = hd(records)

      styles =
        Enum.reduce(records, %{}, fn record, styles ->
          property = record.property || "custom-css"
          record_trace = responsive_trace(trace, source_classes, element, breakpoint, record)

          style =
            case record.kind do
              :gradient ->
                gradient_style(record, record_trace)

              :custom_css ->
                StyleValue.complex_css(
                  %{
                    "type" => "custom_css",
                    "property" => "custom-css",
                    "source_key" => record.source_key,
                    "rules" => [record.value]
                  },
                  source_expression: record.value,
                  source_trace: record_trace,
                  metadata: %{"source_key" => record.source_key}
                )

              _kind ->
                normalize_style(record.value, property, record_trace, context.token_set,
                  metadata: %{"source_key" => record.source_key, "breakpoint" => breakpoint}
                )
            end

          Map.put(styles, property, style)
        end)

      override_trace = responsive_trace(trace, source_classes, element, breakpoint, first)

      {breakpoint,
       %ResponsiveOverride{
         breakpoint_id: breakpoint,
         source_name: breakpoint,
         min_width: nil,
         max_width: nil,
         resolution_status: :unresolved,
         styles: styles,
         source_trace: override_trace
       }}
    end)
  end

  defp responsive_trace(trace, source_classes, element, breakpoint, record) do
    %SourceTrace{
      source_type: "bricks_responsive",
      source_id: element.id,
      source_path: "#{trace.source_path}.settings.#{record.source_key}",
      source_name: breakpoint,
      source_classes: source_classes,
      source_settings: trace.source_settings,
      adapter: trace.adapter,
      adapter_version: trace.adapter_version,
      inference: "responsive source name preserved without an invented numeric threshold",
      metadata:
        json_safe(%{
          "source_key" => record.source_key,
          "breakpoint" => breakpoint,
          "min_width" => nil,
          "max_width" => nil,
          "resolution_status" => "unresolved"
        })
    }
  end

  defp build_assets(context, trace_index) do
    context.dependencies.assets
    |> Enum.with_index(1)
    |> Enum.reduce({%{}, %{}}, fn {asset, index}, {assets, by_source} ->
      asset_id = "asset_#{String.pad_leading(Integer.to_string(index), 6, "0")}"
      trace = asset_trace(asset, trace_index)

      status =
        if asset.status == :resolved and is_binary(asset.url), do: :resolved, else: :unresolved

      uri = if status == :resolved, do: asset.url, else: nil

      reference = %AssetReference{
        asset_id: asset_id,
        kind: "image",
        uri: uri,
        alt: asset.alt,
        status: status,
        metadata:
          json_safe(%{
            "attachment_id" => asset.attachment_id,
            "filename" => asset.filename,
            "url" => asset.url,
            "alt" => asset.alt,
            "dimensions" => asset.dimensions,
            "source_image" => source_image_metadata(trace),
            "source_node_id" => asset.source_id
          }),
        source_trace: trace
      }

      by_source = Map.update(by_source, asset.source_id, [asset_id], &(&1 ++ [asset_id]))
      {Map.put(assets, asset_id, reference), by_source}
    end)
  end

  defp asset_trace(asset, trace_index) do
    case Map.get(trace_index, asset.source_id) do
      %{trace: trace} ->
        %{
          trace
          | source_type: "bricks_asset",
            source_path: "#{trace.source_path}.settings.image",
            source_name: "image",
            inference: "asset registry entry preserves unresolved source evidence"
        }

      nil ->
        %SourceTrace{
          source_type: "bricks_asset",
          source_id: asset.source_id,
          source_path: "settings.image",
          source_name: "image",
          source_classes: [],
          source_settings: %{},
          adapter: "bricks",
          adapter_version: Document.adapter_version(),
          inference: "asset registry entry preserves unresolved source evidence",
          metadata: %{}
        }
    end
  end

  defp source_image_metadata(%SourceTrace{source_settings: source_settings}),
    do: Map.get(source_settings, "image")

  defp source_metadata(context) do
    document = context.document
    component = context.component
    proxy = context.proxy

    json_safe(%{
      "source_system" => "bricks",
      "source" => document.source,
      "source_url" => document.source_url,
      "source_label" => document.source_label,
      "source_hash" => document.source_hash,
      "payload_version" => document.payload_version,
      "adapter_version" => document.adapter_version,
      "component_id" => component.id,
      "component_name" => component.name,
      "component_category" => component.category,
      "component_version" => component.version,
      "component_proxy_id" => proxy.id,
      "component_proxy_name" => proxy.name,
      "component_proxy_label" => proxy.label,
      "source_element_count" => length(component.elements),
      "root_count" => length(context.tree.root_ids),
      "source_order" => context.tree.source_order
    })
  end

  defp provenance(context) do
    json_safe(%{
      "adapter" => "bricks",
      "adapter_version" => context.document.adapter_version,
      "source_hash" => context.document.source_hash,
      "component_id" => context.component.id,
      "source_of_truth" => "structured_bricks_source_model",
      "source_pipeline" => [
        "loader",
        "resolver",
        "tree_builder",
        "class_resolver",
        "settings_extractor",
        "dependency_extractor",
        "design_ir_normalizer"
      ],
      "dependency_summary" => %{
        "source_classes" => context.dependencies.source_classes,
        "acss_classes" => context.dependencies.acss_classes,
        "class_dependencies" => context.dependencies.class_dependencies,
        "variables" => context.dependencies.variables,
        "runtime_dependencies" => context.dependencies.runtime_dependencies,
        "unsupported_settings" => context.dependencies.unsupported_settings
      },
      "normalization_lifecycle" => @lifecycle,
      "normalization_status" => "serialized",
      "stage_a_artifacts_are_evidence_only" => true
    })
  end

  defp unsupported_element_diagnostics(tree) do
    tree.ordered_elements
    |> Enum.filter(&(&1.name not in @supported_element_names))
    |> Enum.map(fn element ->
      BricksDiagnostic.new(
        code: "bricks.element.unsupported",
        severity: :warning,
        source_id: element.id,
        raw_value: element.name,
        message: "Bricks element type is preserved as an unsupported IR node"
      )
    end)
  end

  defp blocking?(diagnostics),
    do: Enum.any?(diagnostics, &(&1.severity in [:error, :fatal]))

  defp to_ir_diagnostics(diagnostics, context \\ nil) when is_list(diagnostics) do
    diagnostics
    |> Enum.map(&to_ir_diagnostic(&1, context))
    |> Enum.sort_by(fn diagnostic ->
      {diagnostic.code || "", trace_sort_key(diagnostic.source_trace), diagnostic.message || ""}
    end)
  end

  defp to_ir_diagnostic(%Diagnostic{} = diagnostic, _context), do: diagnostic

  defp to_ir_diagnostic(%TokenDiagnostic{} = diagnostic, _context) do
    Diagnostic.new(
      code: diagnostic.code || "tokens.diagnostic",
      severity: normalize_severity(diagnostic.severity),
      category: :unresolved_token,
      message: diagnostic.message || "TokenSet validation produced a diagnostic",
      metadata:
        json_safe(
          Map.merge(diagnostic.metadata || %{}, %{
            "path" => diagnostic.path,
            "source_key" => diagnostic.source_key
          })
        )
    )
  end

  defp to_ir_diagnostic(%BricksDiagnostic{} = diagnostic, context) do
    Diagnostic.new(
      code: diagnostic.code || "bricks.diagnostic",
      severity: normalize_severity(diagnostic.severity),
      category: category_for(diagnostic.code),
      message: diagnostic.message || "Bricks source produced a diagnostic",
      source_trace: diagnostic_trace(diagnostic, context),
      metadata:
        json_safe(
          Map.merge(diagnostic.metadata || %{}, %{
            "raw_value" => diagnostic.raw_value,
            "source_path" => diagnostic.source_path
          })
        )
    )
  end

  defp to_ir_diagnostic(diagnostic, _context) do
    Diagnostic.new(
      code: "bricks.ir.diagnostic.invalid",
      severity: :fatal,
      category: :schema,
      message: "Bricks source produced an invalid diagnostic",
      metadata: %{"raw_value" => inspect(diagnostic)}
    )
  end

  defp diagnostic_trace(%BricksDiagnostic{source_id: source_id} = diagnostic, context)
       when is_binary(source_id) and is_map(context) do
    case Map.get(context.trace_index || %{}, source_id) do
      %{trace: trace} ->
        %{
          trace
          | source_type: "bricks_diagnostic",
            source_path: diagnostic_source_path(trace, diagnostic.source_path),
            source_name: diagnostic.code,
            inference: "source diagnostic preserved during Design IR normalization"
        }

      nil ->
        generic_diagnostic_trace(diagnostic)
    end
  end

  defp diagnostic_trace(
         %BricksDiagnostic{code: "bricks.variable.unresolved", raw_value: variable_name} =
           diagnostic,
         context
       )
       when is_binary(variable_name) and is_map(context) do
    occurrence =
      context.dependencies.variables
      |> Enum.find(&(&1.name == variable_name))
      |> case do
        %{occurrences: [first | _rest]} -> first
        _variable -> nil
      end

    case occurrence && Map.get(context.trace_index || %{}, occurrence.source_id) do
      %{trace: trace} ->
        %{
          trace
          | source_type: "bricks_diagnostic",
            source_path: "#{trace.source_path}.#{occurrence.source_path}",
            source_name: diagnostic.code,
            inference:
              "unresolved CSS variable occurrence preserved during Design IR normalization"
        }

      nil ->
        generic_diagnostic_trace(diagnostic)
    end
  end

  defp diagnostic_trace(%BricksDiagnostic{} = diagnostic, _context),
    do: generic_diagnostic_trace(diagnostic)

  defp diagnostic_source_path(trace, nil), do: trace.source_path

  defp diagnostic_source_path(trace, source_path),
    do: "#{trace.source_path}.settings.#{source_path}"

  defp generic_diagnostic_trace(diagnostic) do
    %SourceTrace{
      source_type: "bricks_dependency",
      source_id: diagnostic.source_id,
      source_path: diagnostic.source_path,
      source_name:
        if(is_binary(diagnostic.raw_value), do: diagnostic.raw_value, else: diagnostic.code),
      source_classes: [],
      source_settings: %{},
      adapter: "bricks",
      adapter_version: Document.adapter_version(),
      inference: "source diagnostic preserved without source-node guessing",
      metadata: %{}
    }
  end

  defp category_for("bricks.variable.unresolved"), do: :unresolved_token
  defp category_for("bricks.asset.unresolved"), do: :asset_missing
  defp category_for("bricks.breakpoint.unresolved"), do: :ambiguous_semantics
  defp category_for("bricks.setting.value_unresolved"), do: :ambiguous_semantics
  defp category_for("bricks.setting.unsupported"), do: :unsupported_style
  defp category_for("bricks.element.unsupported"), do: :unsupported_element
  defp category_for("bricks.runtime.unsupported"), do: :interaction_unsupported

  defp category_for(code) when is_binary(code) do
    cond do
      String.starts_with?(code, "bricks.class.") -> :unresolved_class
      String.starts_with?(code, "bricks.tree.") -> :schema
      String.starts_with?(code, "bricks.source.") -> :schema
      String.starts_with?(code, "bricks.component.") -> :schema
      true -> :provenance
    end
  end

  defp category_for(_code), do: :provenance

  defp normalize_severity(value) when value in @ir_severities, do: value
  defp normalize_severity("info"), do: :info
  defp normalize_severity("warning"), do: :warning
  defp normalize_severity("error"), do: :error
  defp normalize_severity("fatal"), do: :fatal
  defp normalize_severity(_value), do: :error

  defp trace_sort_key(nil), do: ""

  defp trace_sort_key(%SourceTrace{source_path: source_path, source_id: source_id}),
    do: "#{source_path || ""}|#{source_id || ""}"

  defp component_index(document, component) do
    Enum.find_index(document.component_order, &(&1 == component.id)) || 0
  end

  defp json_safe(nil), do: nil
  defp json_safe(value) when is_binary(value) or is_boolean(value), do: value
  defp json_safe(value) when is_integer(value) or is_float(value), do: value
  defp json_safe(value) when is_atom(value), do: Atom.to_string(value)
  defp json_safe(value) when is_list(value), do: Enum.map(value, &json_safe/1)

  defp json_safe(value) when is_map(value) do
    value = if is_struct(value), do: Map.from_struct(value), else: value

    Map.new(value, fn {key, nested} -> {json_key(key), json_safe(nested)} end)
  end

  defp json_safe(value) when is_tuple(value), do: inspect(value)
  defp json_safe(value), do: inspect(value)

  defp json_key(key) when is_binary(key), do: key
  defp json_key(key) when is_atom(key) and key not in [nil, true, false], do: Atom.to_string(key)
  defp json_key(key), do: inspect(key)
end
