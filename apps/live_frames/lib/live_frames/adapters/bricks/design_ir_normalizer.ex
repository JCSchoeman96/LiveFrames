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
  alias LiveFrames.Adapters.Bricks.StaticNavigation
  alias LiveFrames.Adapters.Bricks.StaticSemantics
  alias LiveFrames.Adapters.Bricks.ThemeStyles
  alias LiveFrames.Adapters.Bricks.TreeBuilder
  alias LiveFrames.IR
  alias LiveFrames.IR.AssetReference
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Diagnostic
  alias LiveFrames.IR.ResponsiveOverride
  alias LiveFrames.IR.SourceTrace
  alias LiveFrames.IR.StyleValue
  alias LiveFrames.StaticAsset
  alias LiveFrames.Tokens
  alias LiveFrames.Tokens.AuthorityGate
  alias LiveFrames.Tokens.Diagnostic, as: TokenDiagnostic
  alias LiveFrames.Tokens.TokenSet
  alias LiveFrames.Fidelity.CSSDeclaration
  alias LiveFrames.Styles.StructuralVariableAuthority
  alias LiveFrames.Tokens.VariableAuthority

  @bricks_container_width_default "1100px"
  @valid_width_length ~r/^-?(?:\d+(?:\.\d+)?|\.\d+)(?:px|rem|em|%|ch|vw|vh|vmin|vmax|ex|cm|mm|in|pt|pc)$/i
  @direct_variable_expression ~r/^\s*var\(\s*(--[A-Za-z0-9_-]+)\s*\)\s*$/
  @fallback_variable_expression ~r/^\s*var\(\s*(--[A-Za-z0-9_-]+)\s*,\s*(.*)\)\s*$/s
  @valid_width_keywords ~w(0 auto inherit initial unset fit-content max-content min-content)

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
    "block",
    "div",
    "heading",
    "text",
    "text-basic",
    "button",
    "image",
    "text-link"
  ]

  @spec normalize(term(), keyword()) ::
          {:ok, DesignDocument.t()} | {:error, [Diagnostic.t()]}
  def normalize(source, opts \\ [])

  def normalize(source, opts) when is_list(opts) do
    with {:ok, token_set, authority_index} <-
           authorize_token_set(Keyword.get(opts, :token_set)),
         {:ok, structural_authority_index} <-
           authorize_structural_variable_authority(
             Keyword.get(opts, :structural_variable_authority)
           ),
         {:ok, document, load_diagnostics} <- load_source(source, opts),
         {:ok, proxy, component, resolve_diagnostics} <-
           Resolver.resolve(document,
             component_id: component_selection(document, opts)
           ),
         {:ok, tree, tree_diagnostics} <- TreeBuilder.build(component),
         :ok <- expected_root_count(tree, opts),
         {:ok, resolved, class_diagnostics} <-
           ClassResolver.resolve(tree, document,
             external_class_authorities: Keyword.get(opts, :external_class_authorities, [])
           ) do
      semantic_settings = StaticSemantics.source_setting_names()

      dependencies =
        DependencyExtractor.extract(resolved, document,
          authority_index: authority_index,
          structural_authority_index: structural_authority_index,
          semantic_settings: semantic_settings
        )

      {static_semantics, static_diagnostics} = normalize_static_semantics(tree)
      {static_navigation, navigation_diagnostics} = StaticNavigation.normalize_tree(tree)

      diagnostics =
        load_diagnostics ++
          resolve_diagnostics ++
          tree_diagnostics ++
          class_diagnostics ++
          dependencies.diagnostics ++
          unsupported_element_diagnostics(tree) ++
          static_diagnostics ++
          navigation_diagnostics

      if blocking?(diagnostics) do
        {:error, to_ir_diagnostics(diagnostics)}
      else
        {theme_styles, theme_diagnostics} = load_theme_styles(Keyword.get(opts, :theme_styles))

        context = %{
          document: document,
          proxy: proxy,
          component: component,
          tree: tree,
          resolved: resolved,
          dependencies: dependencies,
          token_set: token_set,
          authority_index: authority_index,
          structural_authority_index: structural_authority_index,
          component_index: component_index(document, component),
          source_diagnostics: diagnostics ++ theme_diagnostics,
          static_semantics: static_semantics,
          static_navigation: static_navigation,
          container_width: Keyword.get(opts, :container_width),
          theme_styles: theme_styles
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

  defp authorize_token_set(%TokenSet{} = token_set) do
    with {:ok, authority_index} <- AuthorityGate.authorize(token_set) do
      {:ok, token_set, authority_index}
    end
  end

  defp authorize_token_set(_token_set) do
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

  defp authorize_structural_variable_authority(nil) do
    {:ok, %StructuralVariableAuthority{}}
  end

  defp authorize_structural_variable_authority(%StructuralVariableAuthority{} = index) do
    {:ok, index}
  end

  defp authorize_structural_variable_authority(_other) do
    {:error,
     [
       Diagnostic.new(
         code: "bricks.ir.structural_variable_authority.invalid",
         severity: :error,
         category: :schema,
         message:
           "Bricks Design IR structural_variable_authority must be a StructuralVariableAuthority index"
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

  defp component_selection(%Document{source_shape: :component_fragment}, opts) do
    case Keyword.fetch(opts, :component_id) do
      {:ok, component_id} -> component_id
      :error -> nil
    end
  end

  defp component_selection(_document, opts),
    do: Keyword.get(opts, :component_id, @default_component_id)

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
    static_semantics = Map.fetch!(context.static_semantics, element.id)

    trace_metadata = %{
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
    }

    trace_metadata =
      trace_metadata
      |> maybe_put_trace_metadata("native_semantics", static_semantics.trace_metadata)
      |> maybe_put_trace_metadata(
        "static_navigation",
        Map.fetch!(context.static_navigation, element.id)[:trace_metadata]
      )

    %SourceTrace{
      source_type: "bricks_element",
      source_id: element.id,
      source_path: source_path(element, context),
      source_name: element.name,
      source_classes: resolved.class_names,
      source_settings: json_safe(element.settings),
      adapter: "bricks",
      adapter_version: context.document.adapter_version,
      inference: inference_for(element, static_semantics),
      metadata: json_safe(trace_metadata)
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

  defp inference_for(%Element{name: "block"}, _static_semantics),
    do: "block element mapped to generic structural semantics"

  defp inference_for(%Element{name: "text"}, _static_semantics),
    do: "text element mapped to the existing rich text semantic type"

  defp inference_for(%Element{name: "div"}, _static_semantics),
    do: "generic structural semantics preserved without source class component inference"

  defp inference_for(%Element{name: "text-basic", settings: settings}, %{native_tag: "p"}) do
    if Map.get(settings, "tag") == "p",
      do: "paragraph semantics proven by the source element tag",
      else: "paragraph semantics proven by the normalized native tag"
  end

  defp inference_for(%Element{name: "text-basic"}, _static_semantics),
    do: "text-basic element kept as rich text because paragraph semantics were not proven"

  defp inference_for(%Element{name: "text-link"}, _static_semantics),
    do: "text-link element mapped to link semantics for static navigation"

  defp inference_for(%Element{}, _static_semantics),
    do: "direct mapping from the supported Bricks element type"

  defp maybe_put_trace_metadata(trace_metadata, _key, nil), do: trace_metadata

  defp maybe_put_trace_metadata(trace_metadata, key, value),
    do: Map.put(trace_metadata, key, value)

  defp normalize_static_semantics(tree) do
    Enum.reduce(tree.ordered_elements, {%{}, []}, fn element, {semantics_by_id, diagnostics} ->
      static_semantics = StaticSemantics.normalize(element)

      {
        Map.put(semantics_by_id, element.id, static_semantics),
        diagnostics ++ static_semantics.diagnostics
      }
    end)
  end

  defp build_node(source_id, path, context) do
    element = Map.fetch!(context.tree.elements, source_id)
    resolved = Map.fetch!(context.resolved.elements, source_id)
    trace = context.trace_index[source_id].trace
    static_semantics = Map.fetch!(context.static_semantics, source_id)
    static_navigation = Map.fetch!(context.static_navigation, source_id)

    style_result = Map.fetch!(context.dependencies.style_results, source_id)

    children =
      context.tree.children_by_id
      |> Map.get(source_id, [])
      |> Enum.with_index(1)
      |> Enum.map(fn {child_id, child_index} ->
        build_node(child_id, path ++ [child_index], context)
      end)

    attributes =
      attributes_for(element, static_semantics)
      |> apply_static_navigation(static_navigation, static_semantics)

    semantic_type =
      static_navigation[:semantic_type_override] ||
        semantic_type(element, static_semantics)

    DesignNode.new(path,
      semantic_type: semantic_type,
      semantic_role: nil,
      label: element.label,
      content: content_for(element),
      attributes: attributes,
      styles: styles_for(style_result, trace, context.authority_index, element, context),
      responsive: responsive_for(style_result, trace, resolved.class_names, element, context),
      interaction_refs: [],
      asset_refs: Map.get(context.asset_ids_by_source, source_id, []),
      children: children,
      source_trace: trace
    )
  end

  defp semantic_type(%Element{name: "section"}, _static_semantics), do: "section"
  defp semantic_type(%Element{name: "container"}, _static_semantics), do: "container"
  defp semantic_type(%Element{name: "block"}, _static_semantics), do: "generic"
  defp semantic_type(%Element{name: "div"}, _static_semantics), do: "generic"
  defp semantic_type(%Element{name: "heading"}, _static_semantics), do: "heading"

  defp semantic_type(%Element{name: "text"}, _static_semantics), do: "rich_text"

  defp semantic_type(%Element{name: "text-basic"}, %{native_tag: "p"}), do: "paragraph"
  defp semantic_type(%Element{name: "text-basic"}, _static_semantics), do: "rich_text"

  defp semantic_type(%Element{name: "button"}, _static_semantics), do: "button"
  defp semantic_type(%Element{name: "text-link"}, _static_semantics), do: "link"
  defp semantic_type(%Element{name: "image"}, _static_semantics), do: "image"
  defp semantic_type(%Element{}, _static_semantics), do: "unsupported"

  defp apply_static_navigation(attributes, static_navigation, _static_semantics) do
    if static_navigation[:navigation] do
      Map.put(attributes, "navigation", static_navigation[:navigation])
    else
      attributes
    end
  end

  defp attributes_for(%Element{settings: settings}, static_semantics) do
    # Keep these established IR evidence fields. Fidelity never emits them as
    # native attributes.
    existing_attributes =
      ["style", "outline", "caption", "link", "url", "alt"]
      |> Enum.reduce(%{}, fn key, attributes ->
        case Map.fetch(settings, key) do
          {:ok, value} -> Map.put(attributes, key, json_safe(value))
          :error -> attributes
        end
      end)

    Map.merge(existing_attributes, static_semantics.attributes)
  end

  defp content_for(%Element{name: name, settings: settings})
       when name in ["heading", "text", "text-basic", "button", "text-link"] do
    case Map.get(settings, "text") do
      value when is_binary(value) -> value
      _value -> nil
    end
  end

  defp content_for(_element), do: nil

  defp styles_for(style_result, trace, authority_index, element, context) do
    styles =
      Enum.reduce(style_result.base_styles, %{}, fn {property, declaration}, styles ->
        declaration_trace = style_declaration_trace(trace, declaration)
        metadata = declaration_metadata(declaration)

        style =
          case declaration.kind do
            :gradient ->
              declaration
              |> gradient_style(declaration_trace)
              |> merge_style_metadata(metadata)

            _kind ->
              normalize_style(
                declaration.value,
                property,
                declaration_trace,
                authority_index,
                metadata: metadata,
                structural_authority_index: context.structural_authority_index
              )
          end

        Map.put(styles, property, style)
      end)

    styles =
      Enum.reduce(style_result.unresolved_styles, styles, fn declaration, styles ->
        if is_nil(declaration.breakpoint) do
          style =
            unresolved_style_value(declaration, style_declaration_trace(trace, declaration))

          Map.put(styles, declaration.property, style)
        else
          styles
        end
      end)

    styles =
      Enum.reduce(style_result.custom_css.base, styles, fn value, styles ->
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

    merge_intrinsic_styles(
      styles,
      element,
      trace,
      context,
      unresolved_precedence_properties(style_result)
    )
  end

  defp unresolved_precedence_properties(style_result) do
    style_result.resolutions
    |> Enum.filter(&(&1.breakpoint == nil and &1.state == :unresolved_precedence))
    |> Enum.map(& &1.property)
    |> MapSet.new()
  end

  defp style_declaration_trace(trace, declaration) do
    source_path = declaration.source_path || declaration.source_key

    path =
      case declaration.origin do
        :global_class ->
          "#{trace.source_path}.class_refs[#{declaration.class_reference_index}].settings.#{source_path}"

        :element_local ->
          "#{trace.source_path}.settings.#{source_path}"
      end

    %{
      trace
      | source_type: "bricks_style",
        source_path: path,
        source_name: source_path,
        inference:
          if(Map.get(declaration, :normalization_state) == :unresolved,
            do: "style value retained with source-layer provenance after validation",
            else: "style declaration normalized from its source layer"
          )
    }
  end

  defp unresolved_style_value(declaration, trace) do
    StyleValue.unresolved(declaration.value,
      source_expression: if(is_binary(declaration.value), do: declaration.value, else: nil),
      source_trace: trace,
      metadata:
        declaration_metadata(declaration)
        |> Map.put("reason", declaration.reason)
    )
  end

  defp declaration_metadata(declaration) do
    %{
      "source_key" => declaration.source_root_key,
      "source_path" => declaration.source_path,
      "precedence" => declaration.precedence,
      "contributors" => declaration.contributors
    }
    |> maybe_put_metadata("breakpoint", declaration.breakpoint)
  end

  defp maybe_put_metadata(metadata, _key, nil), do: metadata
  defp maybe_put_metadata(metadata, key, value), do: Map.put(metadata, key, value)

  defp merge_style_metadata(%StyleValue{} = style, metadata) do
    %{style | metadata: Map.merge(style.metadata, metadata)}
  end

  # Bricks frontend `.brxe-container` / `.brxe-section` intrinsic layout.
  # Precedence for width (Map.put_new keeps authored `_width`):
  #   explicit element _width
  #     > active Theme Styles container.width
  #     > Bricks 2.3.1 intrinsic default 1100px
  # Explicit :unavailable / invalid configured values omit width (no silent
  # fallback). max-width/margins remain Bricks frontend intrinsics.
  defp merge_intrinsic_styles(styles, %Element{name: "container"}, trace, context, blocked) do
    styles
    |> put_intrinsic_style(trace, "container", "display", "flex", blocked)
    |> put_intrinsic_style(trace, "container", "flex-direction", "column", blocked)
    |> put_container_width(trace, context, blocked)
    |> put_intrinsic_literal(trace, "container", "max-width", "100%", blocked,
      selector: "[class*=brxe-]"
    )
    |> put_intrinsic_style(trace, "container", "margin-left", "auto", blocked)
    |> put_intrinsic_style(trace, "container", "margin-right", "auto", blocked)
  end

  defp merge_intrinsic_styles(styles, %Element{name: "section"}, trace, _context, blocked) do
    put_intrinsic_style(styles, trace, "section", "align-items", "center", blocked)
  end

  defp merge_intrinsic_styles(styles, _element, _trace, _context, _blocked), do: styles

  defp put_container_width(styles, _trace, %{container_width: :unavailable}, _blocked), do: styles

  defp put_container_width(styles, trace, context, blocked) do
    if MapSet.member?(blocked, "width") do
      styles
    else
      case resolve_container_width_authority(context) do
        :omit ->
          styles

        {:intrinsic, value} ->
          put_intrinsic_literal(styles, trace, "container", "width", value, blocked)

        {:theme_styles, value} ->
          put_theme_styles_width(
            styles,
            trace,
            context.authority_index,
            context.structural_authority_index,
            value
          )
      end
    end
  end

  defp resolve_container_width_authority(%{container_width: value}) when is_binary(value) do
    if valid_width_authority?(value), do: {:intrinsic, value}, else: :omit
  end

  defp resolve_container_width_authority(%{container_width: value})
       when value in [:invalid, :unavailable],
       do: :omit

  defp resolve_container_width_authority(%{theme_styles: :unavailable}), do: :omit

  defp resolve_container_width_authority(%{theme_styles: :absent}) do
    {:intrinsic, @bricks_container_width_default}
  end

  defp resolve_container_width_authority(%{theme_styles: theme_styles})
       when is_map(theme_styles) do
    case ThemeStyles.container_width(theme_styles) do
      {:ok, value} ->
        if valid_width_authority?(value), do: {:theme_styles, value}, else: :omit

      {:invalid, _value} ->
        :omit

      :absent ->
        {:intrinsic, @bricks_container_width_default}
    end
  end

  defp resolve_container_width_authority(_context) do
    {:intrinsic, @bricks_container_width_default}
  end

  defp put_theme_styles_width(styles, trace, authority_index, structural_authority_index, value) do
    theme_trace = %{
      trace
      | source_type: "bricks_theme_styles",
        source_path: "#{trace.source_path}.theme_styles.container.width",
        source_name: "theme_styles.container.width",
        inference: "Bricks Theme Styles container width preserved from site configuration"
    }

    style =
      normalize_style(value, "width", theme_trace, authority_index,
        metadata: %{
          "authority" => "bricks_theme_styles",
          "selector" => ".brxe-container"
        },
        structural_authority_index: structural_authority_index
      )

    case style do
      %StyleValue{} = style_value -> Map.put_new(styles, "width", style_value)
    end
  end

  # Theme Styles load states:
  #   :absent — option omitted; Bricks 1100px default allowed
  #   map — supplied and valid
  #   :unavailable — supplied but unreadable/invalid; width omitted
  defp load_theme_styles(nil), do: {:absent, []}

  defp load_theme_styles(path) when is_binary(path) do
    case ThemeStyles.from_file(path) do
      {:ok, theme_styles} ->
        {theme_styles, []}

      {:error, reason} ->
        {:unavailable, [theme_styles_unavailable_diagnostic(reason)]}
    end
  end

  defp load_theme_styles(map) when is_map(map) do
    case ThemeStyles.from_map(map) do
      {:ok, theme_styles} ->
        {theme_styles, []}

      {:error, reason} ->
        {:unavailable, [theme_styles_unavailable_diagnostic(reason)]}
    end
  end

  defp load_theme_styles(_other) do
    {:unavailable, [theme_styles_unavailable_diagnostic(:invalid_theme_styles)]}
  end

  defp theme_styles_unavailable_diagnostic(reason) do
    BricksDiagnostic.new(
      code: "bricks.theme_styles.unavailable",
      severity: :warning,
      message: "Bricks Theme Styles could not be loaded; container width left unresolved",
      metadata: %{"reason" => theme_styles_reason(reason)}
    )
  end

  defp theme_styles_reason(:enoent), do: "missing_file"
  defp theme_styles_reason(:invalid_theme_styles), do: "invalid_payload"
  defp theme_styles_reason(%Jason.DecodeError{}), do: "malformed_json"
  defp theme_styles_reason({:error, %Jason.DecodeError{}}), do: "malformed_json"
  defp theme_styles_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp theme_styles_reason(_reason), do: "unavailable"

  defp valid_width_authority?(value) when is_binary(value) do
    safe_css_fragment?(value) and
      (String.starts_with?(String.trim_leading(value), "var(") or
         String.starts_with?(value, "calc(") or
         Regex.match?(@valid_width_length, value) or value in @valid_width_keywords)
  end

  defp valid_width_authority?(_value), do: false

  defp safe_css_fragment?(value) do
    lowered = String.downcase(value)

    value != "" and
      not String.contains?(lowered, [
        "{",
        "}",
        ";",
        "\\",
        "\0",
        "</",
        "url(",
        "expression(",
        "javascript:"
      ])
  end

  defp put_intrinsic_style(styles, trace, element_name, property, value, blocked) do
    put_intrinsic_value(styles, trace, element_name, property, value, :keyword, blocked, [])
  end

  defp put_intrinsic_literal(styles, trace, element_name, property, value, blocked, opts \\ []) do
    put_intrinsic_value(styles, trace, element_name, property, value, :literal, blocked, opts)
  end

  defp put_intrinsic_value(styles, trace, element_name, property, value, kind, blocked, opts) do
    if MapSet.member?(blocked, property) do
      styles
    else
      put_intrinsic_value_unblocked(styles, trace, element_name, property, value, kind, opts)
    end
  end

  defp put_intrinsic_value_unblocked(styles, trace, element_name, property, value, kind, opts) do
    selector = Keyword.get(opts, :selector, ".brxe-#{element_name}")

    style_value =
      case kind do
        :keyword ->
          StyleValue.keyword(value,
            source_expression: value,
            source_trace: intrinsic_trace(trace, element_name, property),
            metadata: intrinsic_metadata(selector)
          )

        :literal ->
          StyleValue.literal(value,
            source_expression: value,
            source_trace: intrinsic_trace(trace, element_name, property),
            metadata: intrinsic_metadata(selector)
          )
      end

    Map.put_new(styles, property, style_value)
  end

  defp intrinsic_trace(trace, element_name, property) do
    %{
      trace
      | source_type: "bricks_intrinsic",
        source_path: "#{trace.source_path}.intrinsic.brxe-#{element_name}.#{property}",
        source_name: "brxe-#{element_name}.#{property}"
    }
  end

  defp intrinsic_metadata(selector) do
    %{
      "authority" => "bricks_intrinsic_element_default",
      "selector" => selector
    }
  end

  defp style_trace(trace, source_key) do
    %{
      trace
      | source_type: "bricks_style",
        source_path: "#{trace.source_path}.settings.#{source_key}",
        source_name: source_key,
        inference: "style value preserved from the structured Bricks settings model"
    }
  end

  defp normalize_style(value, property, trace, authority_index, opts)
       when is_binary(value) do
    metadata = Keyword.get(opts, :metadata, %{})

    structural_authority_index =
      Keyword.get(opts, :structural_authority_index, %StructuralVariableAuthority{})

    case parse_direct_variable_expression(value) do
      {:ok, variable} ->
        resolve_direct_variable(
          value,
          variable,
          property,
          authority_index,
          structural_authority_index,
          trace,
          metadata
        )

      :error ->
        case parse_fallback_variable_expression(value) do
          {:ok, variable, fallback} ->
            unresolved_fallback_style(
              value,
              variable,
              fallback,
              authority_index,
              trace,
              metadata
            )

          :error ->
            normalize_non_direct_style(value, trace, metadata)
        end
    end
  end

  defp normalize_style(value, _property, trace, _authority_index, opts) do
    StyleValue.literal(json_safe(value),
      source_trace: trace,
      metadata: Keyword.get(opts, :metadata, %{})
    )
  end

  defp normalize_non_direct_style(value, trace, metadata) do
    cond do
      calculation?(value) ->
        StyleValue.calculation(value,
          source_expression: value,
          source_trace: trace,
          metadata: metadata
        )

      variable_expression?(value) ->
        unresolved_variable_style(value, trace, metadata)

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

  defp parse_direct_variable_expression(value) do
    case Regex.run(@direct_variable_expression, value) do
      [_, variable] -> {:ok, variable}
      _other -> :error
    end
  end

  defp parse_fallback_variable_expression(value) do
    case Regex.run(@fallback_variable_expression, value) do
      [_, variable, fallback] -> {:ok, variable, String.trim(fallback)}
      _other -> :error
    end
  end

  defp resolve_direct_variable(
         value,
         variable,
         property,
         authority_index,
         structural_authority_index,
         trace,
         metadata
       ) do
    resolution = VariableAuthority.resolve(authority_index, variable)
    authority_metadata = authority_resolution_metadata(resolution)

    case {resolution.state, resolution.candidates} do
      {:unique_candidate, [%{token_path: token_path, resolution_status: :resolved}]} ->
        StyleValue.token_ref(token_path,
          source_expression: value,
          source_trace: trace,
          metadata: Map.merge(metadata, authority_metadata)
        )

      {:unique_candidate, [_candidate]} ->
        unresolved_authority_style(
          value,
          trace,
          metadata,
          authority_metadata,
          "token_unresolved"
        )

      {:ambiguous_candidates, _candidates} ->
        unresolved_authority_style(
          value,
          trace,
          metadata,
          authority_metadata,
          "mapping_ambiguous"
        )

      {:no_authority, []} ->
        resolve_structural_direct_variable(
          value,
          variable,
          property,
          structural_authority_index,
          trace,
          metadata,
          authority_metadata
        )
    end
  end

  defp resolve_structural_direct_variable(
         value,
         variable,
         property,
         structural_authority_index,
         trace,
         metadata,
         authority_metadata
       ) do
    resolution = StructuralVariableAuthority.resolve(structural_authority_index, variable)
    structural_metadata = structural_resolution_metadata(resolution)

    case resolution.state do
      :unique_candidate ->
        [candidate] = resolution.candidates

        if valid_structural_literal?(property, candidate.resolved_value) do
          StyleValue.literal(candidate.resolved_value,
            source_expression: value,
            source_trace: trace,
            metadata:
              metadata
              |> Map.merge(authority_metadata)
              |> Map.merge(structural_metadata)
          )
        else
          unresolved_authority_style(
            value,
            trace,
            metadata,
            Map.merge(authority_metadata, structural_metadata),
            "structural_value_invalid"
          )
        end

      :ambiguous_candidates ->
        unresolved_authority_style(
          value,
          trace,
          metadata,
          Map.merge(authority_metadata, structural_metadata),
          "structural_ambiguous"
        )

      :no_authority ->
        reason =
          if DependencyExtractor.known_external_variable?(variable),
            do: "external_unresolved",
            else: "mapping_unproven"

        unresolved_authority_style(value, trace, metadata, authority_metadata, reason)
    end
  end

  defp valid_structural_literal?(property, value) when is_binary(property) and is_binary(value) do
    property in ["grid-template-columns", "grid-template-rows"] and
      match?(
        {:ok, _declaration},
        CSSDeclaration.normalize(%{property: property, value: value}, :ir)
      )
  end

  defp valid_structural_literal?(_property, _value), do: false

  defp structural_resolution_metadata(resolution) do
    base = %{
      "source_variable" => resolution.variable,
      "structural_authority_state" => Atom.to_string(resolution.state)
    }

    case resolution.candidates do
      [candidate] ->
        Map.merge(base, %{
          "structural_authority_id" => candidate.authority_id,
          "structural_source_system" => candidate.source_system,
          "structural_source_version" => candidate.source_version,
          "structural_authority_type" => candidate.authority_type,
          "structural_resolved_value" => candidate.resolved_value
        })

      _candidates ->
        Map.put(
          base,
          "structural_authority_candidates",
          Enum.map(resolution.candidates, fn candidate ->
            %{
              "authority_id" => candidate.authority_id,
              "resolved_value" => candidate.resolved_value
            }
          end)
        )
    end
  end

  defp unresolved_fallback_style(
         value,
         variable,
         fallback,
         authority_index,
         trace,
         metadata
       ) do
    resolution = VariableAuthority.resolve(authority_index, variable)

    metadata =
      metadata
      |> Map.merge(authority_resolution_metadata(resolution))
      |> Map.put("fallback", fallback)
      |> Map.put("resolution_reason", "fallback_semantics_unrepresented")

    StyleValue.unresolved(value,
      source_expression: value,
      source_trace: trace,
      metadata: metadata
    )
  end

  defp unresolved_authority_style(
         value,
         trace,
         metadata,
         authority_metadata,
         reason
       ) do
    metadata =
      metadata
      |> Map.merge(authority_metadata)
      |> Map.put("resolution_reason", reason)

    StyleValue.unresolved(value,
      source_expression: value,
      source_trace: trace,
      metadata: metadata
    )
  end

  defp authority_resolution_metadata(resolution) do
    evidence =
      Enum.map(resolution.candidates, fn candidate ->
        %{
          "token_path" => candidate.token_path,
          "resolution_status" =>
            if(candidate.resolution_status, do: Atom.to_string(candidate.resolution_status)),
          "authorities" => candidate.authorities
        }
      end)

    %{
      "source_variable" => resolution.variable,
      "authority_state" => Atom.to_string(resolution.state),
      "candidate_paths" => Enum.map(resolution.candidates, & &1.token_path),
      "authority_evidence" => evidence
    }
    |> case do
      %{"candidate_paths" => [token_path]} = metadata ->
        Map.put(metadata, "token_path", token_path)

      metadata ->
        metadata
    end
  end

  defp unresolved_variable_style(value, trace, metadata) do
    variable_names = Regex.scan(~r/--[A-Za-z0-9_-]+/, value) |> List.flatten() |> Enum.uniq()

    metadata =
      metadata
      |> Map.put("variable_names", variable_names)
      |> Map.put("resolution_reason", "compound_expression_unrepresented")

    StyleValue.unresolved(value,
      source_expression: value,
      source_trace: trace,
      metadata: metadata
    )
  end

  defp calculation?(value),
    do: String.starts_with?(value, ["calc(", "clamp(", "min(", "max("])

  defp variable_expression?(value), do: Regex.match?(~r/var\s*\(/, value)

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

  defp responsive_for(style_result, trace, source_classes, element, context) do
    (style_result.responsive ++
       Enum.filter(style_result.unresolved_styles, &(&1.breakpoint != nil)))
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
                record
                |> gradient_style(record_trace)
                |> merge_style_metadata(declaration_metadata(record))

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

              :style
              when is_map_key(record, :normalization_state) and
                     record.normalization_state == :unresolved ->
                unresolved_style_value(record, record_trace)

              _kind ->
                normalize_style(
                  record.value,
                  property,
                  record_trace,
                  context.authority_index,
                  metadata:
                    record
                    |> declaration_metadata()
                    |> Map.put("breakpoint", breakpoint),
                  structural_authority_index: context.structural_authority_index
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
    source_path = Map.get(record, :source_path) || record.source_key

    path =
      case Map.get(record, :origin) do
        :global_class ->
          "#{trace.source_path}.class_refs[#{Map.get(record, :class_reference_index)}].settings.#{source_path}"

        :element_local ->
          "#{trace.source_path}.settings.#{source_path}"

        _origin ->
          "#{trace.source_path}.settings.#{source_path}"
      end

    metadata = %{
      "source_key" => Map.get(record, :source_root_key) || record.source_key,
      "breakpoint" => breakpoint,
      "min_width" => nil,
      "max_width" => nil,
      "resolution_status" => "unresolved"
    }

    metadata =
      if is_list(Map.get(record, :contributors)),
        do:
          Map.merge(metadata, %{
            "precedence" => Map.get(record, :precedence),
            "contributors" => Map.get(record, :contributors)
          }),
        else: metadata

    %SourceTrace{
      source_type: "bricks_responsive",
      source_id: element.id,
      source_path: path,
      source_name: breakpoint,
      source_classes: source_classes,
      source_settings: trace.source_settings,
      adapter: trace.adapter,
      adapter_version: trace.adapter_version,
      inference: "responsive source name preserved without an invented numeric threshold",
      metadata: json_safe(metadata)
    }
  end

  defp build_assets(context, trace_index) do
    context.dependencies.assets
    |> Enum.with_index(1)
    |> Enum.reduce({%{}, %{}}, fn {asset, index}, {assets, by_source} ->
      asset_id = "asset_#{String.pad_leading(Integer.to_string(index), 6, "0")}"

      {status, uri, resolution_reason} =
        case {asset.status, StaticAsset.validate(asset.uri)} do
          {:resolved, {:ok, validated_uri}} ->
            {:resolved, validated_uri, "resolved_static"}

          {:resolved, {:error, reason}} ->
            {:unresolved, nil, "unresolved_#{reason}"}

          _ ->
            {:unresolved, nil, asset.resolution_reason}
        end

      trace =
        asset
        |> Map.put(:status, status)
        |> Map.put(:resolution_reason, resolution_reason)
        |> then(&asset_trace(&1, trace_index))

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
            "full" => asset.full,
            "path" => asset.path,
            "size" => asset.size,
            "alt" => asset.alt,
            "dimensions" => asset.dimensions,
            "resolution_reason" => resolution_reason,
            "alt_resolution" => asset.alt_resolution,
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
        inference = asset_inference(asset)

        %{
          trace
          | source_type: "bricks_asset",
            source_path: "#{trace.source_path}.settings.image",
            source_name: "image",
            inference: inference,
            metadata: Map.put(trace.metadata, "asset_resolution", asset.resolution_reason)
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
          inference: asset_inference(asset),
          metadata: %{"asset_resolution" => asset.resolution_reason}
        }
    end
  end

  defp asset_inference(%{status: :resolved}),
    do: "media-backed Bricks image identity and selected URI passed the local safety contract"

  defp asset_inference(asset),
    do: "image source evidence preserved without a URI (#{asset.resolution_reason})"

  defp source_image_metadata(%SourceTrace{source_settings: source_settings}),
    do: Map.get(source_settings, "image")

  defp source_metadata(context) do
    document = context.document
    component = context.component
    proxy = context.proxy

    %{
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
      "component_proxy_id" => if(proxy, do: proxy.id),
      "component_proxy_name" => if(proxy, do: proxy.name),
      "component_proxy_label" => if(proxy, do: proxy.label),
      "source_element_count" => length(component.elements),
      "root_count" => length(context.tree.root_ids),
      "source_order" => context.tree.source_order
    }
    |> maybe_put_fragment_source_shape(document.source_shape)
    |> json_safe()
  end

  defp provenance(context) do
    %{
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
    }
    |> maybe_put_fragment_source_shape(context.document.source_shape)
    |> json_safe()
  end

  defp maybe_put_fragment_source_shape(metadata, :component_fragment),
    do: Map.put(metadata, "source_shape", "component_fragment")

  defp maybe_put_fragment_source_shape(metadata, _source_shape), do: metadata

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
  defp category_for("bricks.tag.unsupported"), do: :unsupported_element
  defp category_for("bricks.tag.conflict"), do: :ambiguous_semantics
  defp category_for("bricks.attribute.conflict"), do: :ambiguous_semantics
  defp category_for("bricks.attribute.unsupported"), do: :provenance
  defp category_for("bricks.navigation." <> _), do: :ambiguous_semantics
  defp category_for("bricks.runtime.unsupported"), do: :interaction_unsupported
  defp category_for("bricks.style.precedence_conflict"), do: :unsupported_style

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
