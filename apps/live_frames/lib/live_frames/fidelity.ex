defmodule LiveFrames.Fidelity do
  @moduledoc "Deterministic, source-independent base fidelity generation."

  alias LiveFrames.IR
  alias LiveFrames.IR.{AssetReference, DesignDocument, DesignNode, StyleValue}
  alias LiveFrames.Fidelity.CSSDeclaration
  alias LiveFrames.Responsive.BreakpointAuthority
  alias LiveFrames.Responsive.Resolution

  @version "1.0.0"
  @safe_class ~r/^[A-Za-z_][A-Za-z0-9_-]*$/

  def version, do: @version

  def generate(document, opts \\ [])

  def generate(%DesignDocument{} = document, opts) when is_list(opts) do
    source_resolver = Keyword.get(opts, :source_resolver, LiveFrames.Fidelity.SourceResolver.Noop)

    case IR.validate(document) do
      :ok ->
        case BreakpointAuthority.coerce(Keyword.get(opts, :responsive_authority)) do
          {:ok, responsive_authority} ->
            {plan, state, diagnostics} =
              build_nodes(
                document.root_nodes,
                document,
                source_resolver,
                responsive_authority,
                %{},
                [],
                []
              )

            heex = render_heex(plan)
            css = render_css(plan)

            manifest =
              manifest(document, plan, state, diagnostics, heex, css, responsive_authority)

            {:ok,
             %{heex: heex, css: css, manifest: manifest |> Jason.encode!() |> Jason.decode!()}}

          {:error, reason} ->
            {:error,
             [
               diagnostic(
                 "fidelity.responsive.authority_invalid",
                 "responsive breakpoint authority was not supported",
                 nil,
                 %{reason: Atom.to_string(reason)}
               )
             ]}
        end

      {:error, diagnostics} ->
        {:error, diagnostics}
    end
  end

  def generate(_document, _opts),
    do: {:error, [diagnostic("fidelity.input.invalid", "expected a DesignDocument")]}

  defp build_nodes(
         nodes,
         document,
         source_resolver,
         responsive_authority,
         state,
         diagnostics,
         acc
       ) do
    Enum.reduce(nodes, {acc, state, diagnostics}, fn node, {nodes_acc, state, diagnostics} ->
      {render_node, state, diagnostics} =
        build_node(node, document, source_resolver, responsive_authority, state, diagnostics)

      {children, state, diagnostics} =
        build_nodes(
          node.children,
          document,
          source_resolver,
          responsive_authority,
          state,
          diagnostics,
          []
        )

      {nodes_acc ++ [%{render_node | children: children}], state, diagnostics}
    end)
  end

  defp build_node(
         %DesignNode{} = node,
         document,
         source_resolver,
         responsive_authority,
         state,
         diagnostics
       ) do
    {classes, class_diagnostics} = source_classes(node)
    diagnostics = diagnostics ++ class_diagnostics
    {styles, custom_css, state, diagnostics} = base_styles(node, document, state, diagnostics)
    responsive = deferred(node)

    {responsive_resolutions, responsive_diagnostics} =
      responsive_resolutions(node, document, responsive, responsive_authority)

    deferred_diagnostics =
      if is_nil(responsive_authority) do
        Enum.map(
          responsive,
          &diagnostic(
            "fidelity.responsive.deferred",
            "responsive entry deferred because breakpoint is unresolved",
            node,
            %{breakpoint: &1.source_name}
          )
        )
      else
        []
      end

    diagnostics = diagnostics ++ deferred_diagnostics ++ responsive_diagnostics

    {asset, diagnostics} = asset_decision(node, document, diagnostics)

    {resolver_result, resolver_diagnostics} =
      source_resolver_result(source_resolver, classes, document.token_set, node)

    state = record_resolver(state, resolver_result)
    {base_declarations, base_diagnostics} = normalize_base_declarations(styles, node)

    {source_declarations, source_diagnostics} =
      normalize_declarations(resolver_result.declarations, :source_resolver, node)

    diagnostics = diagnostics ++ resolver_diagnostics ++ base_diagnostics ++ source_diagnostics

    {%{
       id: node.node_id,
       element: element(node),
       content: node.content,
       attrs: attrs(node, asset),
       class: fidelity_class(node.node_id) <> classes,
       styles: styles,
       custom_css: custom_css,
       css_declarations: base_declarations ++ source_declarations,
       source_declarations: source_declarations,
       responsive: responsive,
       responsive_resolutions: responsive_resolutions,
       asset: asset,
       children: []
     }, state, diagnostics}
  end

  defp source_classes(%{source_trace: %{source_classes: classes}}) when is_list(classes) do
    Enum.reduce(classes, {"", []}, fn class, {value, diagnostics} ->
      if is_binary(class) and Regex.match?(@safe_class, class) do
        {value <> " " <> class, diagnostics}
      else
        {value,
         diagnostics ++
           [
             diagnostic("fidelity.class.invalid", "unsafe source class was omitted", nil, %{
               class: class
             })
           ]}
      end
    end)
  end

  defp source_classes(_), do: {"", []}

  defp element(%{semantic_type: "section"}), do: "section"
  defp element(%{semantic_type: type}) when type in ["container", "generic"], do: "div"
  defp element(%{semantic_type: "paragraph"}), do: "p"
  defp element(%{semantic_type: "button"}), do: "button"
  defp element(%{semantic_type: "image"}), do: "figure"

  defp element(%{semantic_type: "heading", attributes: %{"tag" => tag}})
       when tag in ~w(h1 h2 h3 h4 h5 h6), do: tag

  defp element(%{semantic_type: "heading"}), do: "h2"
  defp element(_), do: "div"

  defp attrs(%{semantic_type: "button"}, _), do: [{"type", "button"}]

  defp attrs(%{semantic_type: "image"}, %{"status" => "unresolved"} = asset),
    do: [
      {"data-lf-asset-status", "unresolved"},
      {"data-lf-asset-id", asset["asset_id"]},
      {"aria-label", "Unresolved fidelity image placeholder"}
    ]

  defp attrs(_, _), do: []

  defp fidelity_class(id), do: "lf-fidelity-" <> String.replace(id, "_", "-")

  defp base_styles(node, document, state, diagnostics) do
    {declarations, custom_css, state, diagnostics} =
      Enum.reduce(node.styles, {[], nil, state, diagnostics}, fn {property, style},
                                                                 {decls, custom_css, state,
                                                                  diagnostics} ->
        case style_value(property, style, document) do
          {:emit, value, path} ->
            {[{property, value, path} | decls], custom_css,
             Map.update(state, :base_count, 1, &(&1 + 1)), diagnostics}

          {:skip, reason} ->
            {decls, custom_css, state,
             diagnostics ++
               [
                 diagnostic("fidelity.style.omitted", reason, node, %{
                   property: property,
                   raw_value: style.value
                 })
               ]}

          {:complex, value} when property == "custom-css" ->
            {decls, value, Map.update(state, :complex_count, 1, &(&1 + 1)), diagnostics}

          {:complex, value} ->
            {[{property, value, nil} | decls], custom_css,
             Map.update(state, :complex_count, 1, &(&1 + 1)), diagnostics}
        end
      end)

    {Enum.reverse(declarations), custom_css, state, diagnostics}
  end

  defp style_value(_property, %StyleValue{kind: kind, value: value}, _document)
       when kind in [:literal, :keyword, :calculation] and is_binary(value),
       do:
         if(CSSDeclaration.safe_value?(value),
           do: {:emit, value, nil},
           else: {:skip, "unsafe CSS value was not emitted"}
         )

  defp style_value(_property, %StyleValue{kind: :token_ref, value: path}, document),
    do: token_value(path, document.token_set)

  defp style_value("background-image", %StyleValue{kind: :complex_css, value: value}, _document) do
    if valid_gradient?(value),
      do: {:complex, complex_value("background-image", value)},
      else: {:skip, "malformed gradient was not emitted"}
  end

  defp style_value("custom-css", %StyleValue{kind: :complex_css, value: value}, _document) do
    if safe_custom_structure?(value),
      do: {:complex, complex_value("custom-css", value)},
      else: {:skip, "unsafe custom CSS was not emitted"}
  end

  defp style_value(_property, %StyleValue{kind: :complex_css}, _document),
    do: {:skip, "unsupported complex CSS was not emitted"}

  defp style_value(_property, %StyleValue{kind: :unresolved, value: value}, _document),
    do: {:skip, "unresolved style was not emitted: #{inspect(value)}"}

  defp style_value(_property, _style, _document), do: {:skip, "unsupported style value"}

  defp token_value(path, %{"tokens" => tokens}) do
    case tokens[path] do
      %{"resolved_value" => value} when is_binary(value) ->
        if CSSDeclaration.safe_value?(value),
          do: {:emit, value, path},
          else: {:skip, "unsafe token CSS value was not emitted"}

      %{"resolved_value" => %{"type" => "derived"}, "source_expression" => expression} ->
        value = derived_css_value(expression)

        if CSSDeclaration.safe_value?(value),
          do: {:emit, value, path},
          else: {:skip, "unsafe token CSS value was not emitted"}

      _ ->
        {:skip, "unresolved token: #{path}"}
    end
  end

  defp token_value(path, _), do: {:skip, "unresolved token: #{path}"}

  defp complex_value("background-image", %{"type" => "gradient", "value" => gradient}),
    do: gradient_css(gradient)

  defp complex_value("custom-css", %{"type" => "custom_css", "rules" => rules}),
    do: Enum.filter(rules, &safe_custom_css?/1) |> Enum.join("\n")

  defp complex_value(_, value), do: inspect(value)

  defp gradient_css(%{"angle" => angle, "colors" => colors}) do
    stops =
      Enum.map_join(colors, ", ", fn %{"color" => %{"raw" => color}, "stop" => stop} ->
        "#{color} #{stop_value(stop)}"
      end)

    "linear-gradient(#{angle}deg, #{stops})"
  end

  defp gradient_css(value), do: inspect(value)

  defp stop_value(stop) when is_binary(stop),
    do: if(String.ends_with?(stop, "%"), do: stop, else: stop <> "%")

  defp stop_value(stop), do: to_string(stop)

  defp safe_custom_css?(css) when is_binary(css),
    do:
      not String.contains?(css, "\\") and
        not CSSDeclaration.unsafe_external_url?(css) and
        not Regex.match?(~r/@import|expression\s*\(/i, css)

  defp safe_custom_css?(_), do: false

  defp safe_custom_structure?(%{"type" => "custom_css", "rules" => rules}),
    do: is_list(rules) and Enum.all?(rules, &safe_custom_css?/1)

  defp safe_custom_structure?(_), do: false

  defp valid_gradient?(%{
         "type" => "gradient",
         "value" => %{"angle" => angle, "colors" => colors}
       })
       when is_binary(angle) and is_list(colors) and colors != [],
       do:
         CSSDeclaration.safe_value?(angle) and
           Enum.all?(colors, fn %{"color" => %{"raw" => color}, "stop" => stop}
                                when is_binary(color) and is_binary(stop) ->
             CSSDeclaration.safe_value?(color) and CSSDeclaration.safe_value?(stop)
           end)

  defp valid_gradient?(_), do: false

  defp deferred(%{responsive: responsive}) do
    responsive |> Map.values() |> Enum.sort_by(& &1.breakpoint_id)
  end

  defp responsive_resolutions(_node, _document, _overrides, nil), do: {[], []}

  defp responsive_resolutions(node, document, overrides, authority) do
    {resolutions, diagnostics} =
      Enum.reduce(overrides, {[], []}, fn override, {resolutions, diagnostics} ->
        {resolution, resolution_diagnostics} =
          resolve_responsive_override(node, document, authority, override)

        {[resolution | resolutions], diagnostics ++ resolution_diagnostics}
      end)

    {Enum.sort_by(resolutions, &resolution_sort_key/1), diagnostics}
  end

  defp resolution_sort_key(%Resolution{authority: nil, source_name: source_name}),
    do: {1_000_000, source_name || ""}

  defp resolution_sort_key(%Resolution{authority: authority, source_name: source_name}),
    do: {authority.cascade_order, source_name || ""}

  defp resolve_responsive_override(node, document, authority, override) do
    resolution = Resolution.new(node.node_id, override)

    case BreakpointAuthority.lookup(authority, override.breakpoint_id, override.source_name) do
      {:ok, entry} ->
        {:ok, bound} = Resolution.bind(resolution, entry)
        {declarations, custom_css, diagnostics} = responsive_values(bound, document, node)

        if declarations == [] and (is_nil(custom_css) or custom_css == "") do
          {:ok, rejected} = Resolution.reject(bound, :responsive_value_rejected)

          {rejected,
           diagnostics ++
             [responsive_resolution_diagnostic(node, rejected, :responsive_value_rejected)]}
        else
          {:ok, validated} = Resolution.validate_value(bound, declarations, custom_css)
          {:ok, resolved} = Resolution.resolve(validated)
          {:ok, serialized} = Resolution.serialize(resolved, responsive_css(node, resolved))
          {serialized, diagnostics}
        end

      {:error, reason} ->
        {:ok, blocked} = Resolution.block(resolution, reason)
        {blocked, [responsive_resolution_diagnostic(node, blocked, reason)]}
    end
  end

  defp responsive_values(resolution, document, node) do
    {declarations, custom_css, diagnostics} =
      resolution.raw_styles
      |> sorted_style_entries()
      |> Enum.with_index()
      |> Enum.reduce({[], nil, []}, fn {{property, style}, index},
                                       {declarations, custom_css, diagnostics} ->
        case style_value(property, style, document) do
          {:emit, value, path} ->
            responsive_declaration(
              property,
              value,
              path,
              resolution,
              node,
              index,
              declarations,
              custom_css,
              diagnostics
            )

          {:complex, value} when property == "custom-css" ->
            {declarations, value, diagnostics}

          {:complex, value} ->
            responsive_declaration(
              property,
              value,
              nil,
              resolution,
              node,
              index,
              declarations,
              custom_css,
              diagnostics
            )

          {:skip, reason} ->
            metadata = responsive_value_metadata(property, resolution)

            {
              declarations,
              custom_css,
              [
                diagnostic(
                  "fidelity.responsive.value_omitted",
                  reason,
                  node,
                  metadata
                )
                | diagnostics
              ]
            }
        end
      end)

    {Enum.reverse(declarations), custom_css, Enum.reverse(diagnostics)}
  end

  defp responsive_declaration(
         property,
         value,
         path,
         resolution,
         node,
         index,
         declarations,
         custom_css,
         diagnostics
       ) do
    raw = %{property: property, value: value, path: path, selector: nil}

    case CSSDeclaration.normalize(raw, :ir) do
      {:ok, declaration} ->
        {[declaration | declarations], custom_css, diagnostics}

      {:unresolved, declaration} ->
        {[declaration | declarations], custom_css, diagnostics}

      {:rejected, _declaration, reason} ->
        diagnostic =
          declaration_diagnostic(raw, :ir, node, index, reason)
          |> Map.update!(:metadata, &Map.put(&1, :breakpoint, resolution.source_name))

        {declarations, custom_css, [diagnostic | diagnostics]}
    end
  end

  defp responsive_value_metadata(property, resolution) do
    metadata = %{
      origin: "ir",
      breakpoint: resolution.source_name,
      reason: "responsive_value_omitted"
    }

    case property do
      property when is_binary(property) and byte_size(property) <= 128 ->
        if CSSDeclaration.safe_property?(property),
          do: Map.put(metadata, :property, property),
          else: metadata

      _ ->
        metadata
    end
  end

  defp responsive_css(node, resolution) do
    declaration_css = Enum.map_join(resolution.declarations, "\n", &serialized_declaration/1)

    declaration_rule =
      if declaration_css == "",
        do: "",
        else: ".#{fidelity_class(node.node_id)} {\n#{declaration_css}\n}"

    [resolution.custom_css || "", declaration_rule]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  defp responsive_resolution_diagnostic(node, resolution, reason) do
    diagnostic(
      responsive_resolution_code(reason),
      responsive_resolution_message(reason),
      node,
      %{
        origin: "ir",
        breakpoint: resolution.source_name,
        reason: Atom.to_string(reason),
        node_id: node.node_id
      }
    )
  end

  defp responsive_resolution_code(:authority_missing),
    do: "fidelity.responsive.authority_missing"

  defp responsive_resolution_code(:source_breakpoint_mismatch),
    do: "fidelity.responsive.authority_mismatch"

  defp responsive_resolution_code(:responsive_value_rejected),
    do: "fidelity.responsive.value_rejected"

  defp responsive_resolution_code(_reason), do: "fidelity.responsive.failed"

  defp responsive_resolution_message(:authority_missing),
    do: "responsive entry deferred because breakpoint authority is missing"

  defp responsive_resolution_message(:source_breakpoint_mismatch),
    do: "responsive entry rejected because breakpoint identity does not match authority"

  defp responsive_resolution_message(:responsive_value_rejected),
    do: "responsive entry rejected because no safe value could be emitted"

  defp responsive_resolution_message(_reason),
    do: "responsive entry failed before serialization"

  defp sorted_style_entries(styles) when is_map(styles) do
    Enum.sort_by(styles, fn {property, _style} ->
      if is_binary(property), do: property, else: inspect(property)
    end)
  end

  defp asset_decision(%{asset_refs: [id]}, %{assets: assets}, diagnostics) do
    case assets[id] do
      %AssetReference{status: :unresolved} = asset ->
        {%{
           "status" => "unresolved",
           "asset_id" => asset.asset_id,
           "attachment_id" => asset.metadata["attachment_id"],
           "filename" => asset.metadata["filename"]
         },
         diagnostics ++
           [
             diagnostic(
               "fidelity.asset.placeholder",
               "unresolved asset emitted as placeholder",
               nil,
               %{asset_id: id}
             )
           ]}

      _ ->
        {nil, diagnostics}
    end
  end

  defp asset_decision(_, _, diagnostics), do: {nil, diagnostics}

  defp source_resolver_result(source_resolver, classes, token_set, node) do
    result =
      try do
        {:ok, source_resolver.resolve(String.split(String.trim(classes)), token_set)}
      rescue
        _exception -> {:error, :resolver_failed}
      catch
        _kind, _reason -> {:error, :resolver_failed}
      end

    case result do
      {:ok, result} ->
        case normalize_resolver_result(result) do
          {:ok, normalized} -> {normalized, []}
          :error -> invalid_resolver_result(node, :invalid_resolver_result)
        end

      {:error, reason} ->
        invalid_resolver_result(node, reason)
    end
  end

  defp normalize_resolver_result(result) when is_map(result) and not is_struct(result) do
    with {:ok, declarations} <- resolver_field(result, :declarations),
         true <- proper_list?(declarations),
         true <- valid_consumed_hints?(result) do
      {:ok,
       %{
         resolver_id: resolver_id(result),
         declarations: declarations,
         consumed_hints: consumed_hints(result)
       }}
    else
      _ -> :error
    end
  end

  defp normalize_resolver_result(_result), do: :error

  defp valid_consumed_hints?(result) do
    case resolver_field(result, :consumed_hints) do
      {:ok, hints} -> proper_list?(hints)
      :error -> true
    end
  end

  defp proper_list?(value) when is_list(value) do
    try do
      _ = length(value)
      true
    rescue
      _exception -> false
    end
  end

  defp proper_list?(_value), do: false

  defp resolver_field(result, key) do
    string_key = Atom.to_string(key)

    case {Map.fetch(result, key), Map.fetch(result, string_key)} do
      {{:ok, value}, :error} -> {:ok, value}
      {:error, {:ok, value}} -> {:ok, value}
      {{:ok, value}, {:ok, value}} -> {:ok, value}
      {{:ok, _value}, {:ok, _other_value}} -> :error
      {:error, :error} -> :error
    end
  end

  defp resolver_id(result) do
    case resolver_field(result, :resolver_id) do
      {:ok, resolver_id} when is_binary(resolver_id) and resolver_id != "" -> resolver_id
      _ -> "source"
    end
  end

  defp consumed_hints(result) do
    case resolver_field(result, :consumed_hints) do
      {:ok, hints} when is_list(hints) -> Enum.filter(hints, &is_binary/1)
      _ -> []
    end
  end

  defp invalid_resolver_result(node, reason) do
    {
      %{resolver_id: "source", declarations: [], consumed_hints: []},
      [
        diagnostic(
          "fidelity.source_resolver.invalid",
          "source resolver output was not a supported result",
          node,
          %{origin: "source_resolver", reason: Atom.to_string(reason)}
        )
      ]
    }
  end

  defp normalize_base_declarations(styles, node) do
    styles
    |> Enum.map(fn {property, value, path} ->
      %{property: property, value: value, path: path, selector: nil}
    end)
    |> normalize_declarations(:ir, node)
  end

  defp normalize_declarations(declarations, origin, node) do
    {accepted, diagnostics} =
      declarations
      |> Enum.with_index()
      |> Enum.reduce({[], []}, fn {raw, index}, {accepted, diagnostics} ->
        case CSSDeclaration.normalize(raw, origin) do
          {:ok, declaration} ->
            {[declaration | accepted], diagnostics}

          {:unresolved, declaration} ->
            {[declaration | accepted], diagnostics}

          {:rejected, _declaration, reason} ->
            {accepted, [declaration_diagnostic(raw, origin, node, index, reason) | diagnostics]}
        end
      end)

    {Enum.reverse(accepted), Enum.reverse(diagnostics)}
  end

  defp declaration_diagnostic(raw, origin, node, index, reason) do
    reason = Atom.to_string(reason)

    metadata = %{
      origin: Atom.to_string(origin),
      reason: reason,
      declaration_index: index,
      node_id: node.node_id
    }

    metadata =
      case declaration_property(raw) do
        property when is_binary(property) and byte_size(property) <= 128 ->
          if CSSDeclaration.safe_property?(property),
            do: Map.put(metadata, :property, property),
            else: metadata

        _ ->
          metadata
      end

    diagnostic(
      declaration_diagnostic_code(reason),
      declaration_diagnostic_message(reason),
      node,
      metadata
    )
  end

  defp declaration_property(raw) when is_map(raw) do
    case Map.get(raw, :property) do
      property when is_binary(property) -> property
      _ -> Map.get(raw, "property")
    end
  end

  defp declaration_property(_raw), do: nil

  defp declaration_diagnostic_code("invalid_declaration_shape"),
    do: "fidelity.declaration.shape_invalid"

  defp declaration_diagnostic_code("invalid_css_property"),
    do: "fidelity.declaration.property_invalid"

  defp declaration_diagnostic_code("invalid_css_value"),
    do: "fidelity.declaration.value_invalid"

  defp declaration_diagnostic_code("unsafe_css_value"),
    do: "fidelity.declaration.value_unsafe"

  defp declaration_diagnostic_code("unsupported_selector"),
    do: "fidelity.declaration.selector_unsupported"

  defp declaration_diagnostic_code("custom_css_forbidden"),
    do: "fidelity.declaration.custom_css_forbidden"

  defp declaration_diagnostic_code(_reason), do: "fidelity.declaration.rejected"

  defp declaration_diagnostic_message("invalid_declaration_shape"),
    do: "CSS declaration shape was not supported"

  defp declaration_diagnostic_message("invalid_css_property"),
    do: "CSS property was not supported"

  defp declaration_diagnostic_message("invalid_css_value"),
    do: "CSS declaration value was not supported"

  defp declaration_diagnostic_message("unsafe_css_value"),
    do: "unsafe CSS value was not emitted"

  defp declaration_diagnostic_message("unsupported_selector"),
    do: "CSS selector state was not supported"

  defp declaration_diagnostic_message("custom_css_forbidden"),
    do: "source resolver custom CSS declarations are not supported"

  defp declaration_diagnostic_message(_reason),
    do: "CSS declaration was rejected before serialization"

  defp render_heex(nodes),
    do:
      "<%!-- DO NOT EDIT: generated by mix live_frames.fidelity.generate --%>\n" <>
        Enum.map_join(nodes, "\n", &render_node/1) <> "\n"

  defp render_node(node) do
    attrs = Enum.map_join(node.attrs, " ", fn {key, value} -> "#{key}=#{inspect(value)}" end)

    attrs =
      "class=#{inspect(String.trim(node.class))}" <> if(attrs == "", do: "", else: " " <> attrs)

    content = if is_binary(node.content), do: "<%= #{inspect(node.content)} %>", else: ""
    open = "<#{node.element} #{attrs}>"

    if node.element == "figure" and node.asset,
      do: open <> content <> render_children(node.children) <> "</figure>",
      else: open <> content <> render_children(node.children) <> "</#{node.element}>"
  end

  defp render_children(children), do: Enum.map_join(children, "\n", &render_node/1)

  defp render_css(nodes) do
    flat = flat_nodes(nodes)
    base = Enum.map_join(flat, "\n", &node_css/1)
    responsive = render_responsive_css(flat)

    [base, responsive]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
    |> then(
      &if(&1 == "",
        do: "",
        else: "/* DO NOT EDIT: generated by mix live_frames.fidelity.generate */\n" <> &1 <> "\n"
      )
    )
  end

  defp flat_nodes(nodes),
    do: Enum.flat_map(nodes, fn node -> [node | flat_nodes(node.children)] end)

  defp render_responsive_css(nodes) do
    nodes
    |> Enum.flat_map(fn node ->
      Enum.map(node.responsive_resolutions, &{node, &1})
    end)
    |> Enum.filter(fn {_node, resolution} -> resolution.state == :serialized end)
    |> Enum.group_by(fn {_node, resolution} ->
      {resolution.authority.cascade_order, resolution.media_condition}
    end)
    |> Enum.sort_by(fn {{order, media_condition}, _entries} -> {order, media_condition} end)
    |> Enum.map_join("\n", fn {{_order, media_condition}, entries} ->
      inner =
        Enum.map_join(entries, "\n", fn {_node, resolution} -> resolution.serialized_css end)

      media_condition <> " {\n#{inner}\n}"
    end)
  end

  defp node_css(node) do
    declarations = Enum.filter(node.css_declarations, &(&1.state == :accepted))

    custom = node.custom_css || ""

    base_css =
      declarations
      |> Enum.filter(&is_nil(&1.selector))
      |> Enum.map_join("\n", &serialized_declaration/1)

    states =
      declarations
      |> Enum.reject(&is_nil(&1.selector))
      |> Enum.group_by(& &1.selector)
      |> Enum.sort_by(fn {selector, _values} -> CSSDeclaration.selector_sort_key(selector) end)

    rules = if base_css == "", do: [], else: [".#{fidelity_class(node.id)} {\n#{base_css}\n}"]

    rules =
      rules ++
        Enum.map(states, fn {selector, values} ->
          ".#{fidelity_class(node.id)}#{CSSDeclaration.selector_suffix(selector)} {\n#{Enum.map_join(values, "\n", &serialized_declaration/1)}\n}"
        end)

    Enum.join(Enum.reject([custom | rules], &(&1 == "")), "\n")
  end

  defp serialized_declaration(declaration) do
    case CSSDeclaration.serialize(declaration) do
      {:ok, _serialized, text} -> text
      {:error, _reason} -> ""
    end
  end

  defp manifest(document, plan, state, diagnostics, heex, css, responsive_authority) do
    flat = flat_nodes(plan)

    deferred_count =
      Enum.sum(
        Enum.map(flat, fn node -> Enum.sum(Enum.map(node.responsive, &map_size(&1.styles))) end)
      )

    token_paths =
      ((flat |> Enum.flat_map(& &1.styles) |> Enum.map(&elem(&1, 2))) ++
         Enum.flat_map(flat, fn node -> Enum.map(node.source_declarations, & &1.path) end))
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()

    deferred_entries =
      Enum.flat_map(flat, fn node ->
        Enum.flat_map(node.responsive, fn override ->
          Enum.map(override.styles, fn {property, style} ->
            %{
              "node_id" => node.id,
              "source_breakpoint_name" => override.source_name,
              "property" => property,
              "raw_value" => style.value,
              "status" => "deferred_unresolved_breakpoint"
            }
          end)
        end)
      end)

    base_manifest = %{
      "schema_version" => "1.0.0",
      "generator_version" => @version,
      "input_ir_version" => document.ir_version,
      "node_count" => length(flat),
      "generated_element_count" => length(flat),
      "semantic_type_counts" => Enum.frequencies_by(flat, & &1.element),
      "source_classes_preserved" =>
        flat
        |> Enum.flat_map(&String.split(&1.class))
        |> Enum.reject(&String.starts_with?(&1, "lf-fidelity"))
        |> Enum.uniq()
        |> Enum.sort(),
      "token_paths_consumed" => token_paths,
      "source_fidelity_resolver" => Map.get(state, :resolver_id, "noop"),
      "source_fidelity_hints_consumed" => Map.get(state, :consumed_hints, []),
      "base_declaration_count" => Map.get(state, :base_count, 0),
      "complex_css_count" => Map.get(state, :complex_count, 0),
      "unresolved_declarations" => Enum.map(diagnostics, & &1.metadata),
      "deferred_responsive_count" => deferred_count,
      "deferred_responsive_entries" => deferred_entries,
      "invented_breakpoint_count" => 0,
      "asset_substitutions" => flat |> Enum.map(& &1.asset) |> Enum.reject(&is_nil/1),
      "diagnostic_counts" => Enum.frequencies_by(diagnostics, &Atom.to_string(&1.severity)),
      "generated_heex_sha256" => sha(heex),
      "generated_css_sha256" => sha(css),
      "generation_lifecycle" =>
        ~w(ir_received ir_validated render_plan_built heex_generated css_generated manifest_generated serialized)
    }

    if responsive_authority,
      do: Map.merge(base_manifest, responsive_manifest(flat, responsive_authority)),
      else: base_manifest
  end

  defp responsive_manifest(nodes, authority) do
    resolutions = Enum.flat_map(nodes, & &1.responsive_resolutions)
    total = Enum.sum(Enum.map(resolutions, &map_size(&1.raw_styles)))

    resolved =
      resolutions
      |> Enum.filter(&(&1.state == :serialized))
      |> Enum.map(&responsive_emitted_count/1)
      |> Enum.sum()

    deferred_for_authority =
      resolutions
      |> Enum.filter(
        &(&1.state == :blocked and &1.reason in [:authority_missing, :source_breakpoint_mismatch])
      )
      |> Enum.map(&map_size(&1.raw_styles))
      |> Enum.sum()

    rejected = max(total - resolved - deferred_for_authority, 0)

    consumed_resolutions =
      resolutions
      |> Enum.filter(&(&1.state == :serialized))
      |> Enum.sort_by(&{&1.authority.cascade_order, &1.source_name})

    %{
      "responsive_breakpoint_authority" => %{
        "schema_version" => authority.schema_version,
        "authority_hash" => authority.authority_hash,
        "authority_level" => authority.authority_level,
        "authority_type" => authority.authority_type,
        "source_names" => Enum.map(consumed_resolutions, & &1.source_name) |> Enum.uniq(),
        "media_conditions" => Enum.map(consumed_resolutions, & &1.media_condition) |> Enum.uniq()
      },
      "responsive_entries_total" => total,
      "responsive_entries_resolved" => resolved,
      "responsive_entries_deferred_for_authority" => deferred_for_authority,
      "responsive_entries_rejected" => rejected,
      "deferred_responsive_count" => deferred_for_authority,
      "deferred_responsive_entries" => Enum.flat_map(resolutions, &deferred_responsive_entries/1),
      "invented_breakpoints" => 0
    }
  end

  defp responsive_emitted_count(resolution) do
    custom_count =
      if is_binary(resolution.custom_css) and resolution.custom_css != "", do: 1, else: 0

    length(resolution.declarations) + custom_count
  end

  defp deferred_responsive_entries(%Resolution{state: :blocked} = resolution) do
    if resolution.reason in [:authority_missing, :source_breakpoint_mismatch] do
      resolution.raw_styles
      |> sorted_style_entries()
      |> Enum.map(fn {property, style} ->
        %{
          "node_id" => resolution.node_id,
          "source_breakpoint_name" => resolution.source_name,
          "property" => property,
          "raw_value" => style.value,
          "status" => "deferred_unresolved_authority"
        }
      end)
    else
      []
    end
  end

  defp deferred_responsive_entries(_resolution), do: []

  defp sha(value), do: Base.encode16(:crypto.hash(:sha256, value), case: :lower)

  defp record_resolver(state, result) do
    state
    |> Map.put_new(:resolver_id, Map.get(result, :resolver_id, "source"))
    |> Map.update(:consumed_hints, Map.get(result, :consumed_hints, []), fn hints ->
      Enum.uniq(hints ++ Map.get(result, :consumed_hints, []))
    end)
  end

  defp derived_css_value(expression) when is_binary(expression),
    do: if(String.starts_with?(expression, "var("), do: expression, else: "var(#{expression})")

  defp diagnostic(code, message, node \\ nil, metadata \\ %{}),
    do: %LiveFrames.IR.Diagnostic{
      code: code,
      severity: :warning,
      category: :generator,
      message: message,
      source_trace: node && node.source_trace,
      metadata: metadata
    }
end
