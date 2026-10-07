defmodule LiveFrames.NativeGenerator.Renderer do
  @moduledoc false

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentContract.Slot
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.ReferenceValidation
  alias LiveFrames.ComponentizationPlan.RenderProjection
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.StaticNavigation
  alias LiveFrames.IR.ValueBinding
  alias LiveFrames.NativeGenerator.Diagnostic

  @forbidden_source_fragments ~w(
    Code.eval
    Code.compile_string
    String.to_atom
    String.to_existing_atom
    raw(
    LiveFrames.Fidelity
  )

  defmodule Indexes do
    @moduledoc false

    defstruct nodes_by_id: %{},
              boundary_id: nil,
              boundary_node: nil,
              slot_targets: MapSet.new(),
              subtree_slot_by_target: %{},
              render_by_node: %{},
              render_roles_by_node: %{},
              collection_by_repeat_root: %{},
              collection_inputs_by_binding_id: %{},
              item_fields_by_collection: %{},
              package_root_class: nil,
              module_name: nil,
              function_name: nil,
              artifact_path: nil,
              contract: nil,
              plan: nil,
              value_bindings: %{},
              collection_ordinals: %{},
              attrs_by_name: %{}
  end

  @spec build_indexes(ComponentContract.t(), ComponentizationPlan.t(), map(), map()) ::
          {:ok, Indexes.t()} | {:error, Diagnostic.t()}
  def build_indexes(contract, plan, nodes_by_id, value_bindings) do
    boundary_node = Map.get(nodes_by_id, plan.boundary_node_id)

    if boundary_node == nil do
      {:error,
       Diagnostic.error(
         "native_generator.boundary_missing",
         "boundary node is missing from the design document"
       )}
    else
      slot_targets =
        plan.render_projections
        |> Enum.filter(&(&1.render_role == :subtree_slot))
        |> Enum.map(& &1.target_node_id)
        |> MapSet.new()

      subtree_slot_by_target =
        plan.render_projections
        |> Enum.filter(&(&1.render_role == :subtree_slot))
        |> Map.new(&{&1.target_node_id, &1.public_slot_name})

      render_by_node = Enum.group_by(plan.render_projections, & &1.target_node_id)

      render_roles_by_node =
        Map.new(render_by_node, fn {node_id, projections} ->
          roles =
            Map.new(projections, fn projection ->
              {projection.render_role, projection}
            end)

          {node_id, roles}
        end)

      collection_inputs_by_binding_id =
        Map.new(contract.collection_inputs, &{&1.source_collection_binding_id, &1})

      item_fields_by_collection =
        Map.new(contract.collection_inputs, fn input ->
          {input.source_collection_binding_id, Map.new(input.item_fields, &{&1.name, &1})}
        end)

      collection_ordinals =
        contract.collection_inputs
        |> Enum.with_index(1)
        |> Map.new(fn {input, ordinal} -> {input.source_collection_binding_id, ordinal} end)

      collection_by_repeat_root =
        build_collection_repeat_index(contract, collection_ordinals)

      attrs_by_name = Map.new(contract.public_attrs, &{&1.name, &1})

      {:ok,
       %Indexes{
         nodes_by_id: nodes_by_id,
         boundary_id: plan.boundary_node_id,
         boundary_node: boundary_node,
         slot_targets: slot_targets,
         subtree_slot_by_target: subtree_slot_by_target,
         render_by_node: render_by_node,
         render_roles_by_node: render_roles_by_node,
         collection_by_repeat_root: collection_by_repeat_root,
         collection_inputs_by_binding_id: collection_inputs_by_binding_id,
         item_fields_by_collection: item_fields_by_collection,
         package_root_class: package_root_class(contract),
         module_name: module_name(contract),
         function_name: contract.function_intent,
         artifact_path: artifact_path(contract),
         contract: contract,
         plan: plan,
         value_bindings: value_bindings,
         collection_ordinals: collection_ordinals,
         attrs_by_name: attrs_by_name
       }}
    end
  end

  defp build_collection_repeat_index(contract, collection_ordinals) do
    Enum.reduce(contract.binding_projections, %{}, fn projection, acc ->
      case projection do
        %BindingProjection{
          projection_kind: :collection_attr,
          source_collection_binding_id: cb_id,
          public_attr_name: attr_name,
          target_node_id: repeat_root
        } ->
          merge_repeat_root(acc, repeat_root, %{
            collection_binding_id: cb_id,
            kind: :top_level,
            public_attr_name: attr_name,
            item_var: collection_item_var_name(collection_ordinals, cb_id)
          })

        %BindingProjection{
          projection_kind: :collection_item_field,
          source_collection_binding_id: cb_id,
          parent_collection_binding_id: parent_cb_id,
          parent_item_field_name: parent_field,
          target_node_id: repeat_root
        } ->
          merge_repeat_root(acc, repeat_root, %{
            collection_binding_id: cb_id,
            kind: :nested,
            parent_collection_binding_id: parent_cb_id,
            parent_item_field_name: parent_field,
            item_var: collection_item_var_name(collection_ordinals, cb_id)
          })

        _ ->
          acc
      end
    end)
  end

  defp merge_repeat_root(acc, repeat_root, attrs) do
    Map.update(acc, repeat_root, attrs, fn existing ->
      merged = Map.merge(existing, attrs)

      kind =
        if existing[:kind] == :top_level or attrs[:kind] == :top_level,
          do: :top_level,
          else: Map.get(merged, :kind)

      Map.put(merged, :kind, kind)
    end)
  end

  @spec render_module(Indexes.t()) :: {:ok, String.t()} | {:error, Diagnostic.t()}
  def render_module(indexes) do
    with {:ok, heex_body} <- render_boundary(indexes, []),
         {:ok, source} <- assemble_module(indexes, heex_body),
         {:ok, formatted} <- format_source(source),
         :ok <- validate_emitted_source(formatted, indexes) do
      {:ok, formatted}
    end
  end

  defp assemble_module(indexes, heex_body) do
    contract = indexes.contract

    with {:ok, attr_lines} <- build_attr_lines(contract),
         slot_lines <- Enum.map(contract.public_slots, &slot_line/1),
         helper_lines <- item_field_helpers(indexes) do
      assemble_module_source(indexes, heex_body, attr_lines, slot_lines, helper_lines)
    end
  end

  defp build_attr_lines(contract) do
    Enum.reduce_while(contract.public_attrs, {:ok, []}, fn attr, {:ok, acc} ->
      case attr_line(attr) do
        {:ok, line} -> {:cont, {:ok, acc ++ [line]}}
        {:error, diagnostic} -> {:halt, {:error, diagnostic}}
      end
    end)
  end

  defp assemble_module_source(indexes, heex_body, attr_lines, slot_lines, helper_lines) do
    """
    defmodule #{indexes.module_name} do
      use Phoenix.Component

    #{indent_lines(attr_lines, 2)}
    #{indent_lines(slot_lines, 2)}

      def #{indexes.function_name}(assigns) do
        ~H\"\"\"
    #{indent(heex_body, 4)}
        \"\"\"
      end
    #{indent_lines(helper_lines, 2)}
    end
    """
    |> String.trim_trailing()
    |> Kernel.<>("\n")
    |> then(&{:ok, &1})
  end

  defp attr_line(%Attr{
         name: name,
         type: type,
         required: required,
         default: default,
         validation: validation
       }) do
    with {:ok, opts} <- attr_options(type, required, default, validation) do
      {:ok, "attr :#{name}, #{inspect(type)}#{opts}"}
    end
  end

  defp attr_options(type, required, default, validation) do
    base = if required, do: ["required: true"], else: []

    with {:ok, parts} <- append_default_part(base, default),
         parts = parts ++ validation_options(type, validation) do
      {:ok, if(parts == [], do: "", else: ", " <> Enum.join(parts, ", "))}
    end
  end

  defp append_default_part(parts, default) do
    case default_literal(default) do
      :omit -> {:ok, parts}
      {:ok, literal} -> {:ok, parts ++ ["default: #{literal}"]}
      {:error, _} -> return_literal_error()
    end
  end

  defp return_literal_error do
    {:error,
     Diagnostic.error(
       "native_generator.default_unrepresentable",
       "attr default is not representable after generation gates"
     )}
  end

  defp validation_options(:integer, %{"values" => values})
       when values == [1, 2, 3, 4, 5, 6],
       do: ["values: 1..6"]

  defp validation_options(_type, _validation), do: []

  defp default_literal(nil), do: :omit

  defp default_literal(value) do
    case LiveFrames.NativeGenerator.Literal.render(value) do
      {:ok, literal} -> {:ok, literal}
      {:error, _} -> {:error, :unrepresentable}
    end
  end

  defp slot_line(%Slot{name: name, required: required}) do
    if required, do: "slot :#{name}, required: true", else: "slot :#{name}"
  end

  defp item_field_helpers(indexes) do
    specs = collection_field_specs(indexes)

    if specs == [] do
      []
    else
      ["" | item_accessor_helpers(indexes, specs)]
    end
  end

  defp collection_field_specs(indexes) do
    indexes.contract.collection_inputs
    |> Enum.flat_map(fn input ->
      ordinal = Map.fetch!(indexes.collection_ordinals, input.source_collection_binding_id)

      Enum.map(input.item_fields, fn field ->
        {ordinal, field}
      end)
    end)
  end

  defp item_accessor_helpers(indexes, specs) do
    [
      "defp lf_item_field(item, collection_ordinal, field) when is_map(item) do",
      "  raw =",
      "    case Map.fetch(item, field) do",
      "      {:ok, found} -> found",
      "      :error ->",
      "        case Enum.find(item, fn {key, _} -> is_atom(key) and Atom.to_string(key) == field end) do",
      "          {_, found} -> found",
      "          nil -> :__lf_missing__",
      "        end",
      "    end",
      "",
      "  case raw do",
      "    :__lf_missing__ -> lf_item_field_missing(collection_ordinal, field)",
      "    other -> lf_item_field_validate(collection_ordinal, field, other)",
      "  end",
      "end",
      "",
      "defp lf_item_field_missing(collection_ordinal, field) do"
    ] ++
      missing_cases(indexes, specs) ++
      [
        "end",
        "",
        "defp lf_item_field_validate(collection_ordinal, field, value) do",
        "  case {collection_ordinal, field} do"
      ] ++
      validate_cases(specs) ++
      [
        "    _ -> raise ArgumentError, \"unsupported collection item field \" <> field",
        "  end",
        "end"
      ]
  end

  defp missing_cases(_indexes, specs) do
    Enum.map(specs, fn {ordinal, field} ->
      cond do
        field.required ->
          "    {#{ordinal}, #{inspect(field.name)}} -> raise ArgumentError, \"missing required collection item field #{field.name}\""

        match?({:ok, _}, default_literal(field.default)) ->
          {:ok, lit} = default_literal(field.default)
          "    {#{ordinal}, #{inspect(field.name)}} -> #{lit}"

        true ->
          "    {#{ordinal}, #{inspect(field.name)}} -> nil"
      end
    end) ++
      ["    _ -> raise ArgumentError, \"missing collection item field \" <> field"]
  end

  defp validate_cases(specs) do
    Enum.flat_map(specs, fn {ordinal, field} ->
      type_guard = item_field_type_guard(field.type, "value")
      count_guard = item_field_count_guard(field)

      [
        "    {#{ordinal}, #{inspect(field.name)}} ->",
        "      if #{type_guard} do",
        "        if #{count_guard} do",
        "          value",
        "        else",
        "          raise ArgumentError, \"collection item field #{field.name} failed validation\"",
        "        end",
        "      else",
        "        raise ArgumentError, \"collection item field #{field.name} has invalid type\"",
        "      end"
      ]
    end)
  end

  defp item_field_type_guard(:string, var), do: "is_binary(#{var})"
  defp item_field_type_guard(:integer, var), do: "is_integer(#{var})"
  defp item_field_type_guard(:boolean, var), do: "is_boolean(#{var})"
  defp item_field_type_guard(:list, var), do: "is_list(#{var})"
  defp item_field_type_guard(:map, var), do: "is_map(#{var})"
  defp item_field_type_guard(_type, var), do: "is_nil(#{var}) and false"

  defp item_field_count_guard(%{validation: %{"min" => min}}) when is_number(min) and min >= 0,
    do: "is_integer(value) and value >= #{min}"

  defp item_field_count_guard(_field), do: "true"

  defp render_boundary(indexes, collection_stack) do
    render_node(indexes, indexes.boundary_id, collection_stack, true)
  end

  defp render_node(indexes, node_id, collection_stack, is_root?) do
    if Map.has_key?(indexes.subtree_slot_by_target, node_id) do
      slot_name = Map.fetch!(indexes.subtree_slot_by_target, node_id)
      {:ok, "<%= render_slot(@#{slot_name}) %>"}
    else
      case Map.get(indexes.collection_by_repeat_root, node_id) do
        nil ->
          render_element(indexes, node_id, collection_stack, is_root?)

        repeat ->
          stack_entry = %{
            collection_binding_id: repeat.collection_binding_id,
            item_var: repeat.item_var
          }

          with {:ok, inner} <-
                 render_element(indexes, node_id, [stack_entry | collection_stack], is_root?) do
            {:ok, wrap_collection_repeat(indexes, repeat, collection_stack, inner)}
          end
      end
    end
  end

  defp wrap_collection_repeat(
         indexes,
         %{kind: :top_level, public_attr_name: attr, item_var: var},
         _stack,
         inner
       ) do
    attr_spec = Map.fetch!(indexes.attrs_by_name, attr)
    loop = indent(inner, 2)

    source =
      cond do
        attr_spec.required -> "@#{attr}"
        attr_spec.default != nil -> "@#{attr}"
        true -> "Map.get(assigns, :#{attr})"
      end

    if attr_spec.required or attr_spec.default != nil do
      """
      <%= for #{var} <- #{source} do %>
      #{loop}
      <% end %>
      """
    else
      """
      <%= if is_list(#{source}) do %>
        <%= for #{var} <- #{source} do %>
        #{loop}
        <% end %>
      <% end %>
      """
    end
    |> String.trim_trailing()
  end

  defp wrap_collection_repeat(
         indexes,
         %{
           kind: :nested,
           parent_collection_binding_id: parent_cb,
           parent_item_field_name: field,
           item_var: var,
           collection_binding_id: _cb_id
         },
         stack,
         inner
       ) do
    parent_var = parent_item_var(indexes, stack, parent_cb)
    parent_ord = Map.fetch!(indexes.collection_ordinals, parent_cb)
    field_spec = field_spec(indexes, parent_cb, field)
    loop = indent(inner, 2)
    fetch = "lf_item_field(#{parent_var}, #{parent_ord}, #{inspect(field)})"

    nested_loop = """
    <%= for #{var} <- nested_list do %>
    #{loop}
    <% end %>
    """

    omit_on_nil? = field_spec != nil and not field_spec.required and field_spec.default == nil

    clauses =
      if omit_on_nil? do
        """
            <% nil -> %>
            <% nested_list when is_list(nested_list) -> %>
        """
      else
        """
            <% nested_list when is_list(nested_list) -> %>
            <% nil -> %>
        """
      end

    """
    <%= case #{fetch} do %>
    #{clauses}#{indent(nested_loop, 2)}
        <% _ -> %>
          <% raise ArgumentError, "collection item field #{field} must be a list" %>
    <% end %>
    """
    |> String.trim_trailing()
  end

  defp field_spec(indexes, collection_id, field_name) do
    get_in(indexes.item_fields_by_collection, [collection_id, field_name])
  end

  defp parent_item_var(indexes, stack, parent_cb_id) do
    case Enum.find(stack, &(&1.collection_binding_id == parent_cb_id)) do
      %{item_var: var} -> var
      nil -> collection_item_var_name(indexes.collection_ordinals, parent_cb_id)
    end
  end

  defp collection_item_var_name(ordinals, cb_id), do: "lf_ci_#{Map.fetch!(ordinals, cb_id)}"

  defp render_element(indexes, node_id, collection_stack, is_root?) do
    node = Map.fetch!(indexes.nodes_by_id, node_id)
    roles = Map.get(indexes.render_roles_by_node, node_id, %{})

    with :ok <- check_emit_surface(node),
         {:ok, tag_lines} <- element_markup(indexes, node, roles, collection_stack, is_root?) do
      {:ok, tag_lines}
    end
  end

  defp check_emit_surface(%DesignNode{semantic_type: "rich_text", content: content})
       when not is_binary(content) do
    {:error,
     Diagnostic.error(
       "native_generator.content_unsupported",
       "rich_text structured content cannot be emitted without raw HTML interpretation"
     )}
  end

  defp check_emit_surface(_node), do: :ok

  defp element_markup(indexes, node, roles, collection_stack, is_root?) do
    case node.semantic_type do
      "image" ->
        render_image(indexes, node, roles, collection_stack, is_root?)

      "heading" ->
        render_heading(indexes, node, roles, collection_stack, is_root?)

      "link" ->
        render_link(indexes, node, roles, collection_stack, is_root?)

      "button" ->
        render_button(indexes, node, roles, collection_stack, is_root?)

      type ->
        render_generic(indexes, node, type, roles, collection_stack, is_root?)
    end
  end

  defp render_image(indexes, node, roles, collection_stack, is_root?) do
    src = role_expr(indexes, node, roles, :asset_src, collection_stack)
    figure? = Map.get(node.attributes, "tag") == "figure"

    if src == nil do
      if node.node_id == indexes.boundary_id do
        {:error,
         Diagnostic.error(
           "native_generator.projection_missing",
           "boundary image is missing asset_src placement"
         )}
      else
        {:ok, ""}
      end
    else
      alt = image_alt_expr(indexes, node, roles, collection_stack)
      img = "<img src={#{src}}#{alt} />"

      if figure? do
        attrs = root_attrs(indexes, node, roles, collection_stack, is_root?, "figure")
        {:ok, "<figure#{attrs}>#{img}</figure>"}
      else
        attrs = root_attrs(indexes, node, roles, collection_stack, is_root?, "img")
        {:ok, "<img#{attrs} src={#{src}}#{alt} />"}
      end
    end
  end

  defp image_alt_expr(indexes, node, roles, collection_stack) do
    policy = image_alt_policy(indexes, node, roles, collection_stack)

    case policy do
      :decorative ->
        ~s( alt="")

      :consumer ->
        expr =
          role_expr(indexes, node, roles, :asset_alt, collection_stack) ||
            collection_alt_field_expr(indexes, node.node_id, collection_stack)

        if expr, do: " alt={#{expr}}", else: ""

      :none ->
        ""
    end
  end

  defp collection_alt_field_expr(indexes, node_id, collection_stack) do
    with policy when policy == "consumer_supplied" <-
           collection_item_image_policy(indexes, node_id, collection_stack),
         alt_field <- collection_alt_field_name(indexes, node_id),
         %BindingProjection{source_collection_binding_id: cb_id} <-
           Enum.find(indexes.contract.binding_projections, fn projection ->
             projection.projection_kind == :collection_item_field and
               projection.target_node_id == node_id and projection.item_field_name == alt_field
           end) do
      {var, ord} = collection_item_ref(cb_id, collection_stack, indexes)
      "lf_item_field(#{var}, #{ord}, #{inspect(alt_field)})"
    else
      _ -> nil
    end
  end

  defp collection_alt_field_name(indexes, node_id) do
    indexes.contract.binding_projections
    |> Enum.find_value(fn
      %BindingProjection{
        projection_kind: :collection_item_field,
        target_node_id: ^node_id,
        item_field_name: field_name,
        source_collection_binding_id: cb_id
      } = projection ->
        value_binding = Map.get(indexes.value_bindings, projection.source_binding_id)

        if match?(%ValueBinding{target_kind: :asset}, value_binding) do
          fields = Map.get(indexes.item_fields_by_collection, cb_id, %{})
          accessibility = get_in(fields, [field_name, Access.key(:accessibility)]) || %{}
          Map.get(accessibility, "alt_item_field_name") || "alt"
        end

      _ ->
        nil
    end)
  end

  defp image_alt_policy(indexes, node, roles, collection_stack) do
    cond do
      Map.has_key?(roles, :asset_alt) ->
        :consumer

      true ->
        case static_image_attr_policy(indexes, roles, collection_stack) ||
               collection_item_image_policy(indexes, node.node_id, collection_stack) do
          "decorative" -> :decorative
          "consumer_supplied" -> :consumer
          _ -> :none
        end
    end
  end

  defp static_image_attr_policy(indexes, roles, collection_stack) do
    with {:attr, name} <- role_binding_target(roles, :asset_src),
         %Attr{accessibility: accessibility} <-
           Map.get(indexes.contract.public_attrs |> Enum.map(&{&1.name, &1}) |> Map.new(), name) do
      Map.get(accessibility, "image_alt_policy")
    else
      _ -> collection_item_image_policy(indexes, roles, collection_stack)
    end
  end

  defp collection_item_image_policy(indexes, node_id, _collection_stack) do
    indexes.contract.binding_projections
    |> Enum.find_value(fn
      %BindingProjection{
        projection_kind: :collection_item_field,
        target_node_id: ^node_id,
        item_field_name: field_name,
        source_collection_binding_id: cb_id
      } = projection ->
        value_binding = Map.get(indexes.value_bindings, projection.source_binding_id)

        if match?(%ValueBinding{target_kind: :asset}, value_binding) do
          fields = Map.get(indexes.item_fields_by_collection, cb_id, %{})
          accessibility = get_in(fields, [field_name, Access.key(:accessibility)]) || %{}
          Map.get(accessibility, "image_alt_policy")
        end

      _ ->
        nil
    end)
  end

  defp render_heading(indexes, node, roles, collection_stack, is_root?) do
    text = role_expr(indexes, node, roles, :text_content, collection_stack)
    body = static_or_expr_body(node, text)

    if Map.has_key?(roles, :heading_level) do
      level_expr = role_expr(indexes, node, roles, :heading_level, collection_stack)

      if level_expr == nil do
        {:error,
         Diagnostic.error(
           "native_generator.projection_missing",
           "heading_level placement could not be resolved"
         )}
      else
        dynamic_heading_markup(indexes, node, roles, collection_stack, is_root?, level_expr, body)
      end
    else
      case ReferenceValidation.native_tag(node, false) do
        {:ok, tag} when is_binary(tag) ->
          attrs = root_attrs(indexes, node, roles, collection_stack, is_root?, tag)

          with {:ok, children} <- render_children(indexes, node, collection_stack, is_root?) do
            {:ok, "<#{tag}#{attrs}>#{body}#{children}</#{tag}>"}
          end

        _ ->
          {:error,
           Diagnostic.error(
             "native_generator.tag_unresolved",
             "heading tag could not be resolved after generation gates"
           )}
      end
    end
  end

  defp dynamic_heading_markup(indexes, node, roles, collection_stack, is_root?, level_expr, body) do
    branches =
      for level <- 1..6, tag <- ["h#{level}"] do
        attrs = root_attrs(indexes, node, roles, collection_stack, is_root?, tag)
        "    <% #{level} -> %><#{tag}#{attrs}>#{body}</#{tag}>"
      end

    {:ok,
     """
     <%= case #{level_expr} do %>
     #{Enum.join(branches, "\n")}
     <% end %>
     """
     |> String.trim_trailing()}
  end

  defp render_link(indexes, node, roles, collection_stack, is_root?) do
    render_anchor(indexes, node, roles, collection_stack, is_root?)
  end

  defp render_button(indexes, node, roles, collection_stack, is_root?) do
    if static_navigation?(node, roles) do
      render_anchor(indexes, node, roles, collection_stack, is_root?)
    else
      attrs = root_attrs(indexes, node, roles, collection_stack, is_root?, "button")

      with {:ok, body} <- interactive_body(indexes, node, roles, collection_stack, is_root?) do
        {:ok, "<button#{attrs} type=\"button\">#{body}</button>"}
      end
    end
  end

  defp render_anchor(indexes, node, roles, collection_stack, is_root?) do
    href = role_expr(indexes, node, roles, :link_url, collection_stack)
    attrs = root_attrs(indexes, node, roles, collection_stack, is_root?, "a")
    nav_attrs = static_navigation_attrs(node, roles)
    href_attr = if href, do: " href={#{href}}", else: ""

    with {:ok, body} <- interactive_body(indexes, node, roles, collection_stack, is_root?) do
      {:ok, "<a#{attrs}#{nav_attrs}#{href_attr}>#{body}</a>"}
    end
  end

  defp static_navigation?(node, roles) do
    node.semantic_type in ["link", "button"] and Map.has_key?(node.attributes, "navigation") and
      not Map.has_key?(roles, :link_url)
  end

  defp static_navigation_attrs(node, roles) do
    if static_navigation?(node, roles) do
      case StaticNavigation.validate_navigation_map(node.attributes["navigation"]) do
        {:ok, attrs} ->
          Enum.map_join(attrs, "", fn {name, value} ->
            " #{name}=\"#{html_escape_attr(value)}\""
          end)

        _ ->
          ""
      end
    else
      ""
    end
  end

  defp html_escape_attr(value) when is_binary(value) do
    value
    |> String.replace("&", "&amp;")
    |> String.replace("\"", "&quot;")
  end

  defp interactive_body(indexes, node, roles, collection_stack, is_root?) do
    text = role_expr(indexes, node, roles, :text_content, collection_stack)
    prefix = static_or_expr_body(node, text)

    with {:ok, children} <- render_children(indexes, node, collection_stack, is_root?) do
      {:ok, prefix <> children}
    end
  end

  defp render_generic(indexes, node, type, roles, collection_stack, is_root?) do
    case ReferenceValidation.native_tag(node, false) do
      {:ok, :dynamic_heading} ->
        {:error,
         Diagnostic.error(
           "native_generator.tag_unresolved",
           "unexpected dynamic heading without heading_level placement"
         )}

      {:ok, tag} when is_binary(tag) ->
        attrs = root_attrs(indexes, node, roles, collection_stack, is_root?, tag)

        body =
          static_or_expr_body(
            node,
            role_expr(indexes, node, roles, :text_content, collection_stack)
          )

        with {:ok, children} <- render_children(indexes, node, collection_stack, is_root?) do
          {:ok, "<#{tag}#{attrs}>#{body}#{children}</#{tag}>"}
        end

      :error ->
        {:error,
         Diagnostic.error(
           "native_generator.semantic_unsupported",
           "semantic_type #{type} has no frozen native tag mapping"
         )}
    end
  end

  defp root_attrs(indexes, node, roles, collection_stack, is_root?, tag) do
    id_part =
      if is_root? and Map.has_key?(roles, :root_id) do
        expr = role_expr(indexes, node, roles, :root_id, collection_stack)
        if expr, do: " id={#{expr}}", else: ""
      else
        ""
      end

    class_part = class_attr(indexes, node, roles, collection_stack, is_root?)

    global_part =
      if is_root? and Map.has_key?(roles, :root_global_attrs) do
        name = projection_attr_name(roles, :root_global_attrs)
        " {@#{name}}"
      else
        ""
      end

    if tag == "img", do: id_part <> class_part, else: id_part <> class_part <> global_part
  end

  defp class_attr(indexes, node, roles, collection_stack, is_root?) do
    package? = is_root? and node.node_id == indexes.boundary_id
    consumer? = is_root? and Map.has_key?(roles, :root_class)

    cond do
      package? and consumer? ->
        expr = role_expr(indexes, node, roles, :root_class, collection_stack)
        " class={[#{inspect(indexes.package_root_class)}, #{expr || "nil"}]}"

      package? ->
        " class={#{inspect(indexes.package_root_class)}}"

      consumer? ->
        expr = role_expr(indexes, node, roles, :root_class, collection_stack)
        if expr, do: " class={#{expr}}", else: ""

      true ->
        ""
    end
  end

  defp static_or_expr_body(%DesignNode{content: content}, nil) when is_binary(content) do
    "{#{inspect(content)}}"
  end

  defp static_or_expr_body(_node, expr) when is_binary(expr), do: "{#{expr}}"
  defp static_or_expr_body(_node, nil), do: ""

  defp render_children(indexes, %DesignNode{children: children}, collection_stack, _is_root?) do
    children
    |> Enum.reduce_while({:ok, []}, fn child, {:ok, acc} ->
      case render_node(indexes, child.node_id, collection_stack, false) do
        {:ok, lines} -> {:cont, {:ok, acc ++ [lines]}}
        {:error, diagnostic} -> {:halt, {:error, diagnostic}}
      end
    end)
    |> case do
      {:ok, parts} -> {:ok, Enum.join(parts, "\n")}
      {:error, diagnostic} -> {:error, diagnostic}
    end
  end

  defp role_expr(indexes, node, roles, role, collection_stack) do
    case Map.get(roles, role) do
      %RenderProjection{public_attr_name: name} ->
        attr_expr(indexes, name)

      nil ->
        binding_expr(indexes, node.node_id, role, collection_stack)
    end
  end

  defp binding_expr(indexes, node_id, role, collection_stack) do
    indexes.contract.binding_projections
    |> Enum.find_value(fn projection ->
      if projection.target_node_id != node_id do
        nil
      else
        binding_role_expr(indexes, projection, role, collection_stack)
      end
    end)
  end

  defp binding_role_expr(indexes, projection, role, collection_stack) do
    node = Map.fetch!(indexes.nodes_by_id, projection.target_node_id)
    mini = %{value_bindings: indexes.value_bindings}

    if ReferenceValidation.native_binding_role(projection, node, mini) != role do
      nil
    else
      case projection.projection_kind do
        kind when kind in [:scalar_attr, :collection_count_attr] ->
          attr_expr(indexes, projection.public_attr_name)

        :collection_item_field ->
          {var, ord} =
            collection_item_ref(
              projection.source_collection_binding_id,
              collection_stack,
              indexes
            )

          "lf_item_field(#{var}, #{ord}, #{inspect(projection.item_field_name)})"

        _ ->
          nil
      end
    end
  end

  defp attr_expr(indexes, name) do
    attr = Map.fetch!(indexes.attrs_by_name, name)

    if attr.required or attr.default != nil do
      "@#{name}"
    else
      "Map.get(assigns, :#{name})"
    end
  end

  defp collection_item_ref(cb_id, stack, indexes) do
    var =
      case Enum.find(stack, &(&1.collection_binding_id == cb_id)) do
        %{item_var: v} -> v
        nil -> collection_item_var_name(indexes.collection_ordinals, cb_id)
      end

    {var, Map.fetch!(indexes.collection_ordinals, cb_id)}
  end

  defp projection_attr_name(roles, role) do
    roles |> Map.fetch!(role) |> Map.fetch!(:public_attr_name)
  end

  defp role_binding_target(roles, role) do
    case Map.get(roles, role) do
      %RenderProjection{public_attr_name: name} -> {:attr, name}
      _ -> nil
    end
  end

  defp format_source(source) do
    try do
      {:ok, IO.iodata_to_binary(Code.format_string!(source))}
    rescue
      _error ->
        {:error,
         Diagnostic.error(
           "native_generator.format_failed",
           "generated source could not be formatted"
         )}
    end
  end

  defp validate_emitted_source(source, indexes) do
    with :ok <- utf8_ok(source),
         :ok <- fragment_ok(source),
         :ok <- declarations_ok(source, indexes),
         :ok <- parse_ok(source) do
      :ok
    end
  end

  defp utf8_ok(source) do
    if String.valid?(source),
      do: :ok,
      else: {:error, Diagnostic.error("native_generator.utf8_invalid", "invalid UTF-8")}
  end

  defp fragment_ok(source) do
    case Enum.find(@forbidden_source_fragments, &String.contains?(source, &1)) do
      nil ->
        :ok

      fragment ->
        {:error,
         Diagnostic.error(
           "native_generator.forbidden_fragment",
           "generated source contains forbidden fragment",
           %{fragment: fragment}
         )}
    end
  end

  defp declarations_ok(source, indexes) do
    cond do
      not String.contains?(source, "defmodule #{indexes.module_name}") ->
        {:error,
         Diagnostic.error("native_generator.module_mismatch", "module declaration mismatch")}

      not String.contains?(source, "def #{indexes.function_name}(assigns)") ->
        {:error,
         Diagnostic.error("native_generator.function_mismatch", "function declaration mismatch")}

      true ->
        :ok
    end
  end

  defp parse_ok(source) do
    case Code.string_to_quoted(source) do
      {:ok, _ast} ->
        :ok

      {:error, _} ->
        {:error,
         Diagnostic.error("native_generator.parse_failed", "generated source did not parse")}
    end
  end

  @spec module_name(ComponentContract.t()) :: String.t()
  def module_name(%ComponentContract{category: category, module_intent: intent}) do
    prefix =
      case category do
        :section -> "LiveFrames.Components.Sections"
        :component -> "LiveFrames.Components"
        :pattern -> "LiveFrames.Components.Patterns"
        :primitive -> "LiveFrames.Components.Primitives"
      end

    "#{prefix}.#{pascal_case(intent)}"
  end

  @spec artifact_path(ComponentContract.t()) :: String.t()
  def artifact_path(%ComponentContract{category: category, module_intent: intent}) do
    case category do
      :section -> "lib/live_frames/components/sections/#{intent}.ex"
      :pattern -> "lib/live_frames/components/patterns/#{intent}.ex"
      :primitive -> "lib/live_frames/components/primitives/#{intent}.ex"
      :component -> "lib/live_frames/components/#{intent}.ex"
    end
  end

  @spec package_root_class(ComponentContract.t()) :: String.t()
  def package_root_class(%ComponentContract{category: category, module_intent: intent}) do
    category_name = Atom.to_string(category)
    hyphenated = String.replace(intent, "_", "-")
    "lf-#{category_name}-#{hyphenated}"
  end

  defp pascal_case(intent) do
    intent
    |> String.split("_", trim: true)
    |> Enum.map(&String.capitalize/1)
    |> Enum.join("")
  end

  defp indent(text, spaces) do
    prefix = String.duplicate(" ", spaces)

    text
    |> String.split("\n")
    |> Enum.map(fn line -> if line == "", do: "", else: prefix <> line end)
    |> Enum.join("\n")
  end

  defp indent_lines(lines, spaces) do
    lines
    |> Enum.reject(&(&1 == ""))
    |> Enum.map_join("\n", &indent(&1, spaces))
  end
end

defmodule LiveFrames.NativeGenerator.Literal do
  @moduledoc false

  @spec render(term()) :: {:ok, String.t()} | {:error, :unsupported}
  def render(nil), do: {:ok, "nil"}
  def render(true), do: {:ok, "true"}
  def render(false), do: {:ok, "false"}
  def render(value) when is_integer(value), do: {:ok, Integer.to_string(value)}
  def render(value) when is_float(value), do: {:ok, inspect(value)}

  def render(value) when is_binary(value) do
    if String.valid?(value), do: {:ok, inspect(value)}, else: {:error, :unsupported}
  end

  def render(values) when is_list(values) do
    parts = Enum.map(values, fn item -> render!(item) end)
    {:ok, "[" <> Enum.join(parts, ", ") <> "]"}
  end

  def render(value) when is_map(value) do
    keys = value |> Map.keys() |> Enum.sort()

    if Enum.all?(keys, &valid_key?/1) do
      pairs =
        Enum.map(keys, fn key ->
          {render!(key), render!(Map.get(value, key))}
        end)

      {:ok, "%{" <> Enum.map_join(pairs, ", ", fn {k, v} -> "#{k} => #{v}" end) <> "}"}
    else
      {:error, :unsupported}
    end
  end

  def render(_), do: {:error, :unsupported}

  defp render!(term) do
    case render(term) do
      {:ok, literal} -> literal
      {:error, _} -> throw(:unsupported)
    end
  end

  defp valid_key?(key) when is_binary(key), do: String.valid?(key)
  defp valid_key?(key) when is_atom(key), do: true
  defp valid_key?(_), do: false
end
