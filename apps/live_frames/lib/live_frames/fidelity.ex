defmodule LiveFrames.Fidelity do
  @moduledoc "Deterministic, source-independent base fidelity generation."

  alias LiveFrames.IR
  alias LiveFrames.IR.{AssetReference, DesignDocument, DesignNode, StyleValue}

  @version "1.0.0"
  @safe_class ~r/^[A-Za-z_][A-Za-z0-9_-]*$/

  def version, do: @version

  def generate(document, opts \\ [])

  def generate(%DesignDocument{} = document, opts) when is_list(opts) do
    source_resolver = Keyword.get(opts, :source_resolver, LiveFrames.Fidelity.SourceResolver.Noop)

    case IR.validate(document) do
      :ok ->
        {plan, state, diagnostics} =
          build_nodes(document.root_nodes, document, source_resolver, %{}, [], [])

        heex = render_heex(plan)
        css = render_css(plan)
        manifest = manifest(document, plan, state, diagnostics, heex, css)
        {:ok, %{heex: heex, css: css, manifest: manifest |> Jason.encode!() |> Jason.decode!()}}

      {:error, diagnostics} ->
        {:error, diagnostics}
    end
  end

  def generate(_document, _opts),
    do: {:error, [diagnostic("fidelity.input.invalid", "expected a DesignDocument")]}

  defp build_nodes(nodes, document, source_resolver, state, diagnostics, acc) do
    Enum.reduce(nodes, {acc, state, diagnostics}, fn node, {nodes_acc, state, diagnostics} ->
      {render_node, state, diagnostics} =
        build_node(node, document, source_resolver, state, diagnostics)

      {children, state, diagnostics} =
        build_nodes(node.children, document, source_resolver, state, diagnostics, [])

      {nodes_acc ++ [%{render_node | children: children}], state, diagnostics}
    end)
  end

  defp build_node(%DesignNode{} = node, document, source_resolver, state, diagnostics) do
    {classes, class_diagnostics} = source_classes(node)
    diagnostics = diagnostics ++ class_diagnostics
    {styles, state, diagnostics} = base_styles(node, document, state, diagnostics)
    responsive = deferred(node)

    diagnostics =
      diagnostics ++
        Enum.map(
          responsive,
          &diagnostic(
            "fidelity.responsive.deferred",
            "responsive entry deferred because breakpoint is unresolved",
            node,
            %{breakpoint: &1.source_name}
          )
        )

    {asset, diagnostics} = asset_decision(node, document, diagnostics)

    resolver_result =
      source_resolver.resolve(String.split(String.trim(classes)), document.token_set)

    state = record_resolver(state, resolver_result)

    {%{
       id: node.node_id,
       element: element(node),
       content: node.content,
       attrs: attrs(node, asset),
       class: fidelity_class(node.node_id) <> classes,
       styles: styles,
       source_declarations: resolver_result.declarations,
       responsive: responsive,
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
    {declarations, state, diagnostics} =
      Enum.reduce(node.styles, {[], state, diagnostics}, fn {property, style},
                                                            {decls, state, diagnostics} ->
        case style_value(property, style, document) do
          {:emit, value, path} ->
            {[{property, value, path} | decls], Map.update(state, :base_count, 1, &(&1 + 1)),
             diagnostics}

          {:skip, reason} ->
            {decls, state,
             diagnostics ++
               [
                 diagnostic("fidelity.style.omitted", reason, node, %{
                   property: property,
                   raw_value: style.value
                 })
               ]}

          {:complex, value} ->
            {[{property, value, nil} | decls], Map.update(state, :complex_count, 1, &(&1 + 1)),
             diagnostics}
        end
      end)

    {Enum.reverse(declarations), state, diagnostics}
  end

  defp style_value(_property, %StyleValue{kind: kind, value: value}, _document)
       when kind in [:literal, :keyword, :calculation] and is_binary(value),
       do:
         if(safe_css_value?(value),
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
        if safe_css_value?(value),
          do: {:emit, value, path},
          else: {:skip, "unsafe token CSS value was not emitted"}

      %{"resolved_value" => %{"type" => "derived"}, "source_expression" => expression} ->
        value = derived_css_value(expression)

        if safe_css_value?(value),
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
      not Regex.match?(~r/@import|url\s*\(\s*(?:https?:|\/\/|javascript:)|expression\s*\(/i, css)

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
         safe_css_value?(angle) and
           Enum.all?(colors, fn %{"color" => %{"raw" => color}, "stop" => stop}
                                when is_binary(color) and is_binary(stop) ->
             safe_css_value?(color) and safe_css_value?(stop)
           end)

  defp valid_gradient?(_), do: false

  defp safe_css_value?(value),
    do: not Regex.match?(~r/[{};]|url\s*\(\s*(?:https?:|\/\/|javascript:)/i, value)

  defp deferred(%{responsive: responsive}) do
    responsive |> Map.values() |> Enum.sort_by(& &1.breakpoint_id)
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
    nodes
    |> flat_nodes()
    |> Enum.map_join("\n", &node_css/1)
    |> then(
      &if(&1 == "",
        do: "",
        else: "/* DO NOT EDIT: generated by mix live_frames.fidelity.generate */\n" <> &1 <> "\n"
      )
    )
  end

  defp flat_nodes(nodes),
    do: Enum.flat_map(nodes, fn node -> [node | flat_nodes(node.children)] end)

  defp node_css(node) do
    base =
      Enum.map(node.styles, fn {property, value, path} ->
        %{property: property, value: value, path: path, selector: nil}
      end)

    declarations = base ++ node.source_declarations

    custom =
      declarations
      |> Enum.filter(&(&1.property == "custom-css"))
      |> Enum.map_join("\n", & &1.value)

    declarations =
      declarations |> Enum.filter(&(is_binary(&1.value) and &1.property != "custom-css"))

    base_css =
      declarations
      |> Enum.filter(&is_nil(&1.selector))
      |> Enum.map_join("\n", fn d -> "  #{d.property}: #{d.value};" end)

    states =
      declarations
      |> Enum.reject(&is_nil(&1.selector))
      |> Enum.group_by(& &1.selector)
      |> Enum.sort()

    rules = if base_css == "", do: [], else: [".#{fidelity_class(node.id)} {\n#{base_css}\n}"]

    rules =
      rules ++
        Enum.map(states, fn {selector, values} ->
          ".#{fidelity_class(node.id)}#{String.replace(selector, "&", "")} {\n#{Enum.map_join(values, "\n", fn d -> "  #{d.property}: #{d.value};" end)}\n}"
        end)

    Enum.join(Enum.reject([custom | rules], &(&1 == "")), "\n")
  end

  defp manifest(document, plan, state, diagnostics, heex, css) do
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

    %{
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
  end

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
