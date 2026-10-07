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
  alias LiveFrames.ComponentContract.Json
  alias LiveFrames.StaticMarkupContract
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
              attrs_by_name: %{},
              binding_roles_by_node: %{},
              binding_projection_by_node_role: %{},
              effective_roles_by_node: %{},
              count_attr_names: MapSet.new()
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

      {binding_roles_by_node, binding_projection_by_node_role} =
        build_binding_role_indexes(contract, nodes_by_id, value_bindings)

      effective_roles_by_node =
        merge_effective_roles(render_roles_by_node, binding_roles_by_node)

      count_attr_names = count_public_attr_names(contract)

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
         attrs_by_name: attrs_by_name,
         binding_roles_by_node: binding_roles_by_node,
         binding_projection_by_node_role: binding_projection_by_node_role,
         effective_roles_by_node: effective_roles_by_node,
         count_attr_names: count_attr_names
       }}
    end
  end

  defp build_binding_role_indexes(contract, nodes_by_id, value_bindings) do
    mini = %{value_bindings: value_bindings}

    Enum.reduce(contract.binding_projections, {%{}, %{}}, fn projection, {by_node, by_key} ->
      node = Map.get(nodes_by_id, projection.target_node_id)

      role =
        if node,
          do: ReferenceValidation.native_binding_role(projection, node, mini),
          else: :unsupported

      if role in [:unsupported, :repeat] do
        {by_node, by_key}
      else
        node_id = projection.target_node_id

        by_node =
          Map.update(by_node, node_id, %{role => projection}, &Map.put(&1, role, projection))

        by_key = Map.put(by_key, {node_id, role}, projection)
        {by_node, by_key}
      end
    end)
  end

  defp merge_effective_roles(render_roles_by_node, binding_roles_by_node) do
    ids =
      MapSet.union(
        MapSet.new(Map.keys(render_roles_by_node)),
        MapSet.new(Map.keys(binding_roles_by_node))
      )

    Map.new(ids, fn id ->
      roles =
        Map.merge(
          Map.get(render_roles_by_node, id, %{}),
          Map.get(binding_roles_by_node, id, %{})
        )

      {id, roles}
    end)
  end

  defp count_public_attr_names(contract) do
    contract.binding_projections
    |> Enum.filter(&(&1.projection_kind == :collection_count_attr))
    |> Enum.map(& &1.public_attr_name)
    |> Enum.reject(&is_nil/1)
    |> MapSet.new()
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
          source_binding_kind: :collection,
          projection_kind: :collection_item_field,
          source_collection_binding_id: cb_id,
          parent_collection_binding_id: parent_cb_id,
          parent_item_field_name: parent_field,
          target_node_id: repeat_root
        }
        when is_binary(parent_cb_id) and is_binary(parent_field) ->
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
         helper_lines <- runtime_helper_lines(indexes) do
      assemble_module_source(indexes, heex_body, attr_lines, slot_lines, helper_lines)
    end
  end

  defp runtime_helper_lines(indexes) do
    global_attrs_runtime_helpers() ++
      item_field_helpers(indexes) ++
      slot_runtime_helpers(indexes.contract.public_slots) ++
      count_runtime_helpers(indexes)
  end

  defp global_attrs_runtime_helpers do
    [
      "",
      "defp lf_optional_global_attrs(value) do",
      "  case value do",
      "    nil -> %{}",
      "    attrs when is_map(attrs) -> attrs",
      "    attrs when is_list(attrs) -> Enum.into(attrs, %{})",
      "    _ -> raise ArgumentError, \"root global attrs must be a map or keyword list\"",
      "  end",
      "end"
    ]
  end

  defp build_attr_lines(contract) do
    contract.public_attrs
    |> Enum.reduce_while({:ok, []}, fn attr, {:ok, acc} ->
      case attr_line(attr) do
        {:ok, line} -> {:cont, {:ok, [line | acc]}}
        {:error, diagnostic} -> {:halt, {:error, diagnostic}}
      end
    end)
    |> case do
      {:ok, lines} -> {:ok, Enum.reverse(lines)}
      other -> other
    end
  end

  defp assemble_module_source(indexes, heex_body, attr_lines, slot_lines, helper_lines) do
    """
    defmodule #{indexes.module_name} do
      use Phoenix.Component

    #{indent_lines(attr_lines, 2)}
    #{indent_lines(slot_lines, 2)}

      def #{indexes.function_name}(assigns) do
        lf_validate_first_wave_slots!(assigns)
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
    case Json.normalize(value) do
      {:ok, normalized} ->
        case LiveFrames.NativeGenerator.Literal.render(normalized) do
          {:ok, literal} -> {:ok, literal}
          {:error, _} -> {:error, :unrepresentable}
        end

      :error ->
        {:error, :unrepresentable}
    end
  end

  defp slot_runtime_helpers([]) do
    ["", "defp lf_validate_first_wave_slots!(_assigns), do: :ok"]
  end

  defp slot_runtime_helpers(slots) do
    [
      "",
      "defp lf_validate_first_wave_slots!(assigns) do"
    ] ++
      Enum.flat_map(slots, &slot_guard_lines/1) ++
      ["  :ok", "end"]
  end

  defp slot_guard_lines(%Slot{name: name, required: required?}) do
    [
      "  case Map.get(assigns, :#{name}) do",
      "    nil ->",
      if(required?,
        do: "      raise ArgumentError, \"required slot #{name} is missing\"",
        else: "      :ok"
      ),
      "    [] ->",
      if(required?,
        do: "      raise ArgumentError, \"required slot #{name} is missing\"",
        else: "      :ok"
      ),
      "    [_] -> :ok",
      "    _ -> raise ArgumentError, \"slot #{name} allows at most one entry\"",
      "  end"
    ]
  end

  defp count_runtime_helpers(indexes) do
    count_specs =
      indexes.contract.public_attrs
      |> Enum.filter(fn attr -> MapSet.member?(indexes.count_attr_names, attr.name) end)
      |> Enum.map(fn attr ->
        min =
          case attr.validation do
            %{"min" => n} when is_number(n) -> n
            _ -> 0
          end

        {attr.name, min}
      end)

    if count_specs == [] do
      []
    else
      [
        "",
        "defp lf_validate_count!(value, min) when is_number(min) and min >= 0 do",
        "  cond do",
        "    is_nil(value) -> nil",
        "    is_integer(value) and value >= min -> Integer.to_string(value)",
        "    true ->",
        "      raise ArgumentError, \"collection count must be an integer >= \" <> inspect(min)",
        "  end",
        "end"
      ]
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
      "  fetched =",
      "    case Map.fetch(item, field) do",
      "      {:ok, found} -> {:present, found}",
      "      :error ->",
      "        case Enum.find(item, fn {key, _} -> is_atom(key) and Atom.to_string(key) == field end) do",
      "          {_, found} -> {:present, found}",
      "          nil -> :missing",
      "        end",
      "    end",
      "",
      "  case fetched do",
      "    :missing -> lf_item_field_missing(collection_ordinal, field)",
      "    {:present, value} -> lf_item_field_validate(collection_ordinal, field, value)",
      "  end",
      "end",
      "",
      "defp lf_item_field(_item, _collection_ordinal, _field) do",
      "  raise ArgumentError, \"collection item must be a map\"",
      "end",
      "",
      "defp lf_item_field_missing(collection_ordinal, field) do",
      "  case {collection_ordinal, field} do"
    ] ++
      missing_cases(indexes, specs) ++
      [
        "  end",
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
      value_guard = item_field_value_guard(field)

      [
        "    {#{ordinal}, #{inspect(field.name)}} ->",
        "      if #{type_guard} do",
        "        if #{value_guard} do",
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

  defp item_field_value_guard(%{
         type: :integer,
         validation: %{"values" => [1, 2, 3, 4, 5, 6]}
       }),
       do: "is_integer(value) and value in 1..6"

  defp item_field_value_guard(%{validation: %{"min" => min}})
       when is_number(min) and min >= 0,
       do: "is_integer(value) and value >= #{min}"

  defp item_field_value_guard(_field), do: "true"

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

    list_branch = indent(nested_loop, 2)
    omit_on_nil? = field_spec != nil and not field_spec.required and field_spec.default == nil

    if omit_on_nil? do
      """
      <%= case #{fetch} do %>
          <% nil -> %>
          <% nested_list when is_list(nested_list) -> %>
      #{list_branch}
          <% _ -> %>
            <% raise ArgumentError, "collection item field #{field} must be a list" %>
      <% end %>
      """
      |> String.trim_trailing()
    else
      """
      <%= case #{fetch} do %>
          <% nested_list when is_list(nested_list) -> %>
      #{list_branch}
          <% nil -> %>
          <% _ -> %>
            <% raise ArgumentError, "collection item field #{field} must be a list" %>
      <% end %>
      """
      |> String.trim_trailing()
    end
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
       when is_map(content) or is_list(content) do
    {:error,
     Diagnostic.error(
       "native_generator.content_unsupported",
       "rich_text structured content should have been blocked at generation prerequisites"
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

  defp render_image(indexes, node, _roles, collection_stack, is_root?) do
    node_id = node.node_id
    figure? = Map.get(node.attributes, "tag") == "figure"

    case asset_src_source_spec(indexes, node_id, collection_stack) do
      nil ->
        if node_id == indexes.boundary_id do
          {:error,
           Diagnostic.error(
             "native_generator.projection_missing",
             "boundary image is missing asset_src placement"
           )}
        else
          {:ok, ""}
        end

      {:required, src_expr} ->
        {:ok,
         image_unit_heex(
           indexes,
           node,
           collection_stack,
           is_root?,
           figure?,
           src_expr,
           required_src?: true
         )}

      {:optional, src_expr} ->
        {:ok,
         """
         <%= if (lf_src = #{src_expr}) != nil do %>
         #{indent(image_unit_heex(indexes, node, collection_stack, is_root?, figure?, "lf_src", required_src?: true), 2)}
         <% end %>
         """
         |> String.trim_trailing()}
    end
  end

  defp image_unit_heex(indexes, node, collection_stack, is_root?, figure?, src_var, _opts) do
    policy = image_alt_policy(indexes, node.node_id, collection_stack)

    img_attrs =
      if figure?, do: "", else: tag_attrs(indexes, node, collection_stack, is_root?, "img")

    img_inner =
      case policy do
        :decorative ->
          "<img#{img_attrs} src={#{src_var}} alt=\"\" />"

        :consumer ->
          alt_expr = consumer_alt_expr(indexes, node.node_id, collection_stack)

          """
          <%= case #{alt_expr} do %>
            <% lf_alt when lf_alt in [nil, ""] -> %>
              <% raise ArgumentError, "image alt is required when source is present" %>
            <% lf_alt -> %>
              <img#{img_attrs} src={#{src_var}} alt={lf_alt} />
          <% end %>
          """
          |> String.trim_trailing()

        :none ->
          "<img#{img_attrs} src={#{src_var}} />"
      end

    if figure? do
      figure_attrs = tag_attrs(indexes, node, collection_stack, is_root?, "figure")
      "<figure#{figure_attrs}>#{img_inner}</figure>"
    else
      img_inner
    end
  end

  defp consumer_alt_expr(indexes, node_id, collection_stack) do
    case Map.get(indexes.effective_roles_by_node, node_id, %{}) |> Map.get(:asset_alt) do
      %RenderProjection{public_attr_name: name} ->
        attr_expr(indexes, name)

      %BindingProjection{} = projection ->
        binding_collection_expr(indexes, projection, collection_stack)

      nil ->
        case collection_alt_binding(indexes, node_id) do
          %BindingProjection{} = projection ->
            binding_collection_expr(indexes, projection, collection_stack)

          nil ->
            "nil"
        end
    end
  end

  defp collection_alt_binding(indexes, node_id) do
    case Map.get(indexes.effective_roles_by_node, node_id, %{}) |> Map.get(:asset_src) do
      %BindingProjection{
        projection_kind: :collection_item_field,
        target_node_id: ^node_id,
        source_collection_binding_id: cb_id,
        item_field_name: field_name
      } ->
        alt_field = collection_alt_field_name(indexes, cb_id, field_name)

        Map.get(indexes.binding_projection_by_node_role, {node_id, :asset_alt}) ||
          find_alt_field_projection(indexes, node_id, alt_field)

      _ ->
        nil
    end
  end

  defp find_alt_field_projection(indexes, node_id, _alt_field) do
    Map.get(indexes.binding_projection_by_node_role, {node_id, :asset_alt}) ||
      case Map.get(indexes.binding_roles_by_node, node_id, %{}) |> Map.get(:asset_alt) do
        %BindingProjection{} = p -> p
        _ -> nil
      end
  end

  defp collection_alt_field_name(indexes, cb_id, field_name) do
    fields = Map.get(indexes.item_fields_by_collection, cb_id, %{})
    accessibility = get_in(fields, [field_name, Access.key(:accessibility)]) || %{}
    Map.get(accessibility, "alt_item_field_name") || "alt"
  end

  defp image_alt_policy(indexes, node_id, _collection_stack) do
    case Map.get(indexes.effective_roles_by_node, node_id, %{}) |> Map.get(:asset_alt) do
      %RenderProjection{} ->
        :consumer

      %BindingProjection{} ->
        :consumer

      nil ->
        case asset_src_accessibility_policy(indexes, node_id) do
          "decorative" -> :decorative
          "consumer_supplied" -> :consumer
          _ -> :none
        end
    end
  end

  defp asset_src_accessibility_policy(indexes, node_id) do
    case Map.get(indexes.effective_roles_by_node, node_id, %{}) |> Map.get(:asset_src) do
      %RenderProjection{public_attr_name: name} ->
        Map.get(Map.fetch!(indexes.attrs_by_name, name), :accessibility, %{})
        |> Map.get("image_alt_policy")

      %BindingProjection{
        projection_kind: :collection_item_field,
        source_collection_binding_id: cb_id,
        item_field_name: field_name
      } ->
        fields = Map.get(indexes.item_fields_by_collection, cb_id, %{})
        get_in(fields, [field_name, Access.key(:accessibility), "image_alt_policy"])

      %BindingProjection{projection_kind: :scalar_attr, public_attr_name: name} ->
        Map.get(Map.fetch!(indexes.attrs_by_name, name), :accessibility, %{})
        |> Map.get("image_alt_policy")

      _ ->
        nil
    end
  end

  defp asset_src_source_spec(indexes, node_id, collection_stack) do
    case Map.get(indexes.effective_roles_by_node, node_id, %{}) |> Map.get(:asset_src) do
      %RenderProjection{public_attr_name: name} ->
        attr_source_spec(indexes, name)

      %BindingProjection{projection_kind: :scalar_attr, public_attr_name: name} ->
        attr_source_spec(indexes, name)

      %BindingProjection{
        projection_kind: :collection_item_field,
        source_collection_binding_id: cb_id,
        item_field_name: field_name
      } = projection ->
        field = Map.fetch!(Map.fetch!(indexes.item_fields_by_collection, cb_id), field_name)
        expr = binding_collection_expr(indexes, projection, collection_stack)

        if field.required or field.default != nil do
          {:required, expr}
        else
          {:optional, expr}
        end

      %BindingProjection{} = projection ->
        {:required, binding_collection_expr(indexes, projection, collection_stack)}

      nil ->
        nil
    end
  end

  defp attr_source_spec(indexes, name) do
    attr = Map.fetch!(indexes.attrs_by_name, name)
    expr = attr_expr(indexes, name)

    if attr.required or attr.default != nil do
      {:required, expr}
    else
      {:optional, expr}
    end
  end

  defp render_heading(indexes, node, _roles, collection_stack, is_root?) do
    text = role_expr(indexes, node.node_id, :text_content, collection_stack)
    body = static_or_expr_body(node, text)

    roles = Map.get(indexes.effective_roles_by_node, node.node_id, %{})

    if Map.has_key?(roles, :heading_level) do
      level_expr = role_expr(indexes, node.node_id, :heading_level, collection_stack)

      if level_expr == nil do
        {:error,
         Diagnostic.error(
           "native_generator.projection_missing",
           "heading_level placement could not be resolved"
         )}
      else
        dynamic_heading_markup(indexes, node, collection_stack, is_root?, level_expr, body)
      end
    else
      case ReferenceValidation.native_tag(node, false) do
        {:ok, tag} when is_binary(tag) ->
          attrs = tag_attrs(indexes, node, collection_stack, is_root?, tag)

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

  defp dynamic_heading_markup(indexes, node, collection_stack, is_root?, level_expr, body) do
    branches =
      for level <- 1..6, tag <- ["h#{level}"] do
        attrs = tag_attrs(indexes, node, collection_stack, is_root?, tag)
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

  defp render_link(indexes, node, _roles, collection_stack, is_root?) do
    render_anchor(indexes, node, collection_stack, is_root?)
  end

  defp node_owns_role?(indexes, node_id, role) do
    Map.has_key?(Map.get(indexes.effective_roles_by_node, node_id, %{}), role)
  end

  defp safe_static_attribute_fragment(%DesignNode{attributes: attrs}, tag) when is_map(attrs) do
    attrs
    |> Map.drop(["tag", "navigation", "class", "id"])
    |> Enum.filter(fn {name, value} ->
      StaticMarkupContract.safe_attribute?(name, value, tag)
    end)
    |> Enum.sort_by(fn {name, _} -> name end)
    |> Enum.map_join("", fn {name, value} ->
      " #{name}=\"#{html_escape_attr(value)}\""
    end)
  end

  defp safe_static_attribute_fragment(_node, _tag), do: ""

  defp render_button(indexes, node, _roles, collection_stack, is_root?) do
    if static_navigation?(indexes, node) do
      render_anchor(indexes, node, collection_stack, is_root?)
    else
      tag = "button"
      attrs = tag_attrs(indexes, node, collection_stack, is_root?, tag)

      with {:ok, body} <- interactive_body(indexes, node, collection_stack, is_root?) do
        {:ok, "<button#{attrs}>#{body}</button>"}
      end
    end
  end

  defp render_anchor(indexes, node, collection_stack, is_root?) do
    node_id = node.node_id
    href = role_expr(indexes, node_id, :link_url, collection_stack)
    attrs = tag_attrs(indexes, node, collection_stack, is_root?, "a")
    nav_attrs = static_navigation_attrs(indexes, node)
    href_attr = if href, do: " href={#{href}}", else: ""

    with {:ok, body} <- interactive_body(indexes, node, collection_stack, is_root?) do
      {:ok, "<a#{attrs}#{nav_attrs}#{href_attr}>#{body}</a>"}
    end
  end

  defp static_navigation?(indexes, node) do
    node.semantic_type in ["link", "button"] and Map.has_key?(node.attributes, "navigation") and
      not node_owns_role?(indexes, node.node_id, :link_url)
  end

  defp static_navigation_attrs(indexes, node) do
    if static_navigation?(indexes, node) do
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

  defp interactive_body(indexes, node, collection_stack, is_root?) do
    text = role_expr(indexes, node.node_id, :text_content, collection_stack)
    prefix = static_or_expr_body(node, text)

    with {:ok, children} <- render_children(indexes, node, collection_stack, is_root?) do
      {:ok, prefix <> children}
    end
  end

  defp render_generic(indexes, node, type, _roles, collection_stack, is_root?) do
    case ReferenceValidation.native_tag(node, false) do
      {:ok, :dynamic_heading} ->
        {:error,
         Diagnostic.error(
           "native_generator.tag_unresolved",
           "unexpected dynamic heading without heading_level placement"
         )}

      {:ok, tag} when is_binary(tag) ->
        attrs = tag_attrs(indexes, node, collection_stack, is_root?, tag)

        body =
          static_or_expr_body(
            node,
            role_expr(indexes, node.node_id, :text_content, collection_stack)
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

  defp tag_attrs(indexes, node, collection_stack, is_root?, tag) do
    root_attrs(indexes, node, collection_stack, is_root?) <>
      safe_static_attribute_fragment(node, tag)
  end

  defp root_attrs(indexes, node, collection_stack, is_root?) do
    node_id = node.node_id
    roles = Map.get(indexes.effective_roles_by_node, node_id, %{})

    id_part =
      if is_root? and Map.has_key?(roles, :root_id) do
        expr = role_expr(indexes, node_id, :root_id, collection_stack)
        if expr, do: " id={#{expr}}", else: ""
      else
        ""
      end

    class_part = class_attr(indexes, node, roles, collection_stack, is_root?)
    global_part = root_global_attrs_fragment(indexes, node_id, roles, collection_stack, is_root?)

    id_part <> class_part <> global_part
  end

  defp root_global_attrs_fragment(indexes, _node_id, roles, _collection_stack, is_root?) do
    if is_root? and Map.has_key?(roles, :root_global_attrs) do
      case Map.get(roles, :root_global_attrs) do
        %RenderProjection{public_attr_name: name} ->
          spread_optional_global(indexes, name)

        %BindingProjection{public_attr_name: name} ->
          spread_optional_global(indexes, name)

        _ ->
          ""
      end
    else
      ""
    end
  end

  defp spread_optional_global(indexes, name) do
    attr = Map.fetch!(indexes.attrs_by_name, name)

    if attr.required or attr.default != nil do
      " {lf_optional_global_attrs(@#{name})}"
    else
      " {lf_optional_global_attrs(Map.get(assigns, :#{name}))}"
    end
  end

  defp class_attr(indexes, node, roles, collection_stack, is_root?) do
    package? = is_root? and node.node_id == indexes.boundary_id
    consumer? = is_root? and Map.has_key?(roles, :root_class)

    cond do
      package? and consumer? ->
        expr = role_expr(indexes, node.node_id, :root_class, collection_stack)
        " class={[#{inspect(indexes.package_root_class)}, #{expr || "nil"}]}"

      package? ->
        " class={#{inspect(indexes.package_root_class)}}"

      consumer? ->
        expr = role_expr(indexes, node.node_id, :root_class, collection_stack)
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
        {:ok, lines} -> {:cont, {:ok, [lines | acc]}}
        {:error, diagnostic} -> {:halt, {:error, diagnostic}}
      end
    end)
    |> case do
      {:ok, parts} -> {:ok, Enum.join(Enum.reverse(parts), "\n")}
      {:error, diagnostic} -> {:error, diagnostic}
    end
  end

  defp role_expr(indexes, node_id, role, collection_stack) do
    case Map.get(indexes.effective_roles_by_node, node_id, %{}) |> Map.get(role) do
      %RenderProjection{public_attr_name: name} ->
        public_role_expr(indexes, name, role)

      %BindingProjection{} = projection ->
        binding_role_value_expr(indexes, projection, role, collection_stack)

      nil ->
        nil
    end
  end

  defp public_role_expr(indexes, name, role) do
    expr = attr_expr(indexes, name)

    if role == :text_content and MapSet.member?(indexes.count_attr_names, name) do
      attr = Map.fetch!(indexes.attrs_by_name, name)
      min = count_min(attr)
      "lf_validate_count!(#{expr}, #{min})"
    else
      expr
    end
  end

  defp count_min(%Attr{validation: %{"min" => min}}) when is_number(min) and min >= 0, do: min
  defp count_min(_attr), do: 0

  defp binding_role_value_expr(indexes, projection, role, collection_stack) do
    case projection.projection_kind do
      kind when kind in [:scalar_attr, :collection_count_attr] ->
        public_role_expr(indexes, projection.public_attr_name, role)

      :collection_item_field ->
        binding_collection_expr(indexes, projection, collection_stack)

      _ ->
        nil
    end
  end

  defp binding_collection_expr(indexes, projection, collection_stack) do
    value_binding = Map.get(indexes.value_bindings, projection.source_binding_id)

    if match?(%ValueBinding{value_kind: :collection_count}, value_binding) do
      parent_cb = projection.parent_collection_binding_id
      parent_field = projection.parent_item_field_name
      {var, ord} = collection_item_ref(parent_cb, collection_stack, indexes)
      "lf_item_field(#{var}, #{ord}, #{inspect(parent_field)})"
    else
      field_name = projection.item_field_name

      {var, ord} =
        collection_item_ref(projection.source_collection_binding_id, collection_stack, indexes)

      "lf_item_field(#{var}, #{ord}, #{inspect(field_name)})"
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
