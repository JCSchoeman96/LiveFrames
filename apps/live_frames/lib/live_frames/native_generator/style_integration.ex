defmodule LiveFrames.NativeGenerator.StyleIntegration do
  @moduledoc false

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.StateRuleSet
  alias LiveFrames.IR.StyleValue
  alias LiveFrames.NativeGenerator.Diagnostic
  alias LiveFrames.NativeGenerator.NodeStyleIdentity
  alias LiveFrames.NativeGenerator.StylesheetRenderer
  alias LiveFrames.NativeGenerator.StyleValueCSS

  @locus_gap_code "native_generator.styling.style_locus_authority_gap"
  @primary_variant_gap_code "native_generator.styling.primary_action_variant_authority_gap"
  @primary_precedence_gap_code "native_generator.styling.primary_action_style_precedence_gap"
  @primary_slot_gap_code "native_generator.styling.primary_action_subtree_slot_authority_gap"
  @figure_image_radius_properties [
    "border-radius",
    "border-top-left-radius",
    "border-top-right-radius",
    "border-bottom-right-radius",
    "border-bottom-left-radius"
  ]

  @primary_base_tokens %{
    "background-color" => "button.primary.background",
    "color" => "button.primary.text",
    "border-color" => "button.primary.border",
    "border-width" => "button.primary.border_width",
    "border-style" => "button.primary.border_style",
    "border-radius" => "button.primary.radius",
    "padding-inline" => "button.primary.padding_inline",
    "padding-block" => "button.primary.padding_block",
    "min-width" => "button.primary.min_width",
    "font-size" => "button.primary.font_size",
    "font-weight" => "button.primary.font_weight",
    "line-height" => "button.primary.line_height"
  }

  @spec build(ComponentContract.t(), ComponentizationPlan.t(), DesignDocument.t()) ::
          {:ok, map()} | {:error, :generation_blocked, [Diagnostic.t()]}
  def build(
        %ComponentContract{} = contract,
        %ComponentizationPlan{} = plan,
        %DesignDocument{} = doc
      ) do
    package_class = LiveFrames.NativeGenerator.Renderer.package_root_class(contract)

    with {:ok, identity} <- identity_index(doc, package_class),
         {:ok, boundary_node} <- boundary_node(plan.boundary_node_id, identity.nodes_by_id),
         {:ok, style_result, classes} <-
           collect_styles(boundary_node, plan, identity),
         {:ok, css} <- render_styles_and_state(style_result),
         {:ok, stylesheet_path} <- stylesheet_path(contract) do
      {:ok,
       %{
         private_class_by_id: classes,
         primary_action_slot_targets: style_result.primary_action_slot_targets,
         nodes_by_id: identity.nodes_by_id,
         stylesheet_content: css,
         stylesheet_path: stylesheet_path
       }}
    else
      {:error, %Diagnostic{} = diagnostic} -> blocked(diagnostic)
      {:error, :generation_blocked, _diagnostics} = error -> error
      {:error, reason} -> blocked(style_diagnostic(reason))
    end
  end

  defp identity_index(doc, package_class) do
    case NodeStyleIdentity.build(doc, package_class) do
      {:ok, identity} -> {:ok, identity}
      {:error, diagnostic} -> {:error, diagnostic}
    end
  end

  defp boundary_node(boundary_id, nodes_by_id) do
    case Map.fetch(nodes_by_id, boundary_id) do
      {:ok, node} -> {:ok, node}
      :error -> {:error, :boundary_missing}
    end
  end

  defp collect_styles(boundary_node, plan, identity) do
    slot_targets =
      plan.render_projections
      |> Enum.filter(&(&1.render_role == :subtree_slot))
      |> Map.new(&{&1.target_node_id, &1.public_slot_name})

    style_context = %{
      nodes_by_id: identity.nodes_by_id,
      path_by_id: identity.path_by_id,
      private_class_by_id: identity.private_class_by_id,
      boundary_path: Map.get(identity.path_by_id, plan.boundary_node_id),
      subtree_slot_paths:
        Enum.flat_map(Map.keys(slot_targets), fn node_id ->
          case Map.fetch(identity.path_by_id, node_id) do
            {:ok, path} -> [path]
            :error -> []
          end
        end)
    }

    case collect_node_styles(
           boundary_node,
           plan,
           slot_targets,
           style_context,
           {[], %{}, MapSet.new(), []}
         ) do
      {:ok, {rendered, classes, primary_action_slot_targets, state_rules}} ->
        state_rules = Enum.reverse(state_rules)

        with :ok <- validate_cross_owner_state_cascade(state_rules) do
          {:ok,
           %{
             entries: Enum.reverse(rendered),
             primary_action_slot_targets: primary_action_slot_targets,
             state_rules: state_rules
           }, classes}
        else
          {:error, diagnostic} -> {:error, diagnostic}
        end

      {:error, diagnostic} ->
        {:error, diagnostic}
    end
  end

  defp collect_node_styles(node, plan, slot_targets, style_context, acc) do
    case Map.fetch(slot_targets, node.node_id) do
      {:ok, public_slot_name} ->
        collect_subtree_slot_style(node, public_slot_name, style_context.private_class_by_id, acc)

      :error ->
        with {:ok, next_acc} <-
               collect_node_style(node, plan.boundary_node_id, style_context, acc),
             {:ok, descendant_acc} <-
               collect_child_styles(
                 node.children,
                 plan,
                 slot_targets,
                 style_context,
                 next_acc
               ) do
          {:ok, descendant_acc}
        end
    end
  end

  defp collect_child_styles(children, plan, slot_targets, style_context, acc) do
    Enum.reduce_while(children, {:ok, acc}, fn child, {:ok, child_acc} ->
      case collect_node_styles(child, plan, slot_targets, style_context, child_acc) do
        {:ok, next_acc} -> {:cont, {:ok, next_acc}}
        {:error, diagnostic} -> {:halt, {:error, diagnostic}}
      end
    end)
  end

  defp collect_node_style(
         node,
         boundary_id,
         style_context,
         {rendered, classes, slot_targets, state_rule_acc}
       ) do
    with {:ok, state_rule_set} <- node_state_rule_set(node),
         :ok <- validate_state_owner_scope(node.node_id, state_rule_set, style_context),
         ordinary_node <- ordinary_style_node(node, state_rule_set),
         {:ok, base_styles, pseudo_styles} <- node_style(ordinary_node),
         responsive = responsive_overrides(node.responsive),
         {:ok, node_state_rules} <-
           prepare_state_rules(state_rule_set, node.node_id, style_context),
         :ok <- validate_state_rule_pseudo_precedence(node_state_rules, pseudo_styles) do
      styled? = base_styles != %{} or responsive != [] or pseudo_styles != %{}
      root? = node.node_id == boundary_id
      heading_navigation? = navigable_heading?(node)
      class = Map.fetch!(style_context.private_class_by_id, node.node_id)

      classes =
        Enum.reduce(node_state_rules, classes, fn state_rule, acc ->
          acc
          |> Map.put(state_rule.owner_node_id, state_rule.owner_private_class)
          |> Map.put(state_rule.target_node_id, state_rule.target_private_class)
        end)

      state_rule_acc = Enum.reverse(node_state_rules) ++ state_rule_acc

      if figure_image?(node) do
        collect_figure_image_style(
          node,
          class,
          base_styles,
          responsive,
          pseudo_styles,
          styled?,
          root?,
          {rendered, classes, slot_targets, state_rule_acc}
        )
      else
        classes =
          if root? or styled? or heading_navigation?,
            do: Map.put(classes, node.node_id, class),
            else: classes

        rendered =
          if styled?,
            do: [{:single, class, base_styles, responsive, pseudo_styles} | rendered],
            else: rendered

        rendered =
          if heading_navigation?, do: [{:heading_navigation, class} | rendered], else: rendered

        {:ok, {rendered, classes, slot_targets, state_rule_acc}}
      end
    end
  end

  defp node_state_rule_set(%DesignNode{styles: styles}) when is_map(styles) do
    case Map.get(styles, "custom-css") do
      %StyleValue{kind: :complex_css, value: %{"type" => "state_rules"} = value} ->
        case StateRuleSet.validate(value) do
          :ok -> {:ok, value}
          {:error, _reason} -> {:error, style_diagnostic(:invalid_state_rule_set)}
        end

      _other_style_value ->
        {:ok, nil}
    end
  end

  defp node_state_rule_set(_node), do: {:ok, nil}

  defp ordinary_style_node(node, nil), do: node

  defp ordinary_style_node(%DesignNode{styles: styles} = node, _state_rule_set)
       when is_map(styles),
       do: %{node | styles: Map.delete(styles, "custom-css")}

  defp validate_state_owner_scope(_owner_node_id, nil, _style_context), do: :ok

  defp validate_state_owner_scope(owner_node_id, _state_rule_set, style_context) do
    case Map.fetch(style_context.path_by_id, owner_node_id) do
      {:ok, owner_path} ->
        if path_prefix?(style_context.boundary_path, owner_path),
          do: :ok,
          else: {:error, style_diagnostic(:state_rule_owner_outside_component_boundary)}

      :error ->
        {:error, style_diagnostic(:missing_state_rule_owner_identity)}
    end
  end

  defp prepare_state_rules(nil, _owner_node_id, _style_context), do: {:ok, []}

  defp prepare_state_rules(state_rule_set, owner_node_id, style_context) do
    with {:ok, owner_path} <-
           identity_path(style_context, owner_node_id, :missing_state_rule_owner),
         {:ok, owner_private_class} <-
           identity_private_class(
             style_context,
             owner_node_id,
             :missing_state_rule_owner_private_class
           ) do
      state_rule_set["rules"]
      |> Enum.reduce_while({:ok, []}, fn wire_rule, {:ok, acc} ->
        case prepare_state_rule(
               wire_rule,
               owner_node_id,
               owner_path,
               owner_private_class,
               style_context
             ) do
          {:ok, state_rule} -> {:cont, {:ok, [state_rule | acc]}}
          {:error, %Diagnostic{} = diagnostic} -> {:halt, {:error, diagnostic}}
          {:error, reason} -> {:halt, {:error, style_diagnostic(reason)}}
        end
      end)
      |> case do
        {:ok, state_rules} -> {:ok, Enum.reverse(state_rules)}
        {:error, _diagnostic} = error -> error
      end
    else
      {:error, reason} -> {:error, style_diagnostic(reason)}
    end
  end

  defp prepare_state_rule(
         wire_rule,
         owner_node_id,
         owner_path,
         owner_private_class,
         style_context
       ) do
    target_node_id = wire_rule["target_node_id"]

    with {:ok, target_node} <- identity_node(style_context, target_node_id),
         :ok <- state_rule_target_locus(target_node),
         {:ok, target_path} <-
           identity_path(style_context, target_node_id, :missing_state_rule_target),
         :ok <- validate_state_target_path(target_path, owner_path, style_context),
         {:ok, target_private_class} <-
           identity_private_class(
             style_context,
             target_node_id,
             :missing_state_rule_target_private_class
           ),
         {:ok, condition} <- state_rule_condition(wire_rule["condition"]),
         {:ok, styles} <- state_rule_styles(wire_rule["declarations"]),
         {:ok, viewport} <- state_rule_viewport(wire_rule["viewport"]) do
      {:ok,
       %{
         owner_node_id: owner_node_id,
         owner_private_class: owner_private_class,
         target_node_id: target_node_id,
         target_private_class: target_private_class,
         condition: condition,
         styles: styles,
         viewport: viewport,
         order: wire_rule["order"]
       }}
    end
  end

  defp identity_node(style_context, node_id) do
    case Map.fetch(style_context.nodes_by_id, node_id) do
      {:ok, node} -> {:ok, node}
      :error -> {:error, :missing_state_rule_target}
    end
  end

  defp state_rule_target_locus(%DesignNode{
         node_id: node_id,
         semantic_type: "image",
         attributes: %{"tag" => "figure"}
       }),
       do: {:error, style_locus_gap(node_id)}

  defp state_rule_target_locus(_target_node), do: :ok

  defp identity_path(style_context, node_id, missing_reason) do
    case Map.fetch(style_context.path_by_id, node_id) do
      {:ok, path} -> {:ok, path}
      :error -> {:error, missing_reason}
    end
  end

  defp identity_private_class(style_context, node_id, missing_reason) do
    case Map.fetch(style_context.private_class_by_id, node_id) do
      {:ok, private_class} -> {:ok, private_class}
      :error -> {:error, missing_reason}
    end
  end

  defp validate_state_target_path(target_path, owner_path, style_context) do
    cond do
      not path_prefix?(style_context.boundary_path, target_path) ->
        {:error, :state_rule_target_outside_component_boundary}

      not path_prefix?(owner_path, target_path) ->
        {:error, :state_rule_target_not_self_or_descendant}

      Enum.any?(style_context.subtree_slot_paths, &path_prefix?(&1, target_path)) ->
        {:error, :state_rule_pruned_slot_target}

      true ->
        :ok
    end
  end

  defp path_prefix?(prefix, path) when is_list(prefix) and is_list(path) do
    length(prefix) <= length(path) and Enum.take(path, length(prefix)) == prefix
  end

  defp path_prefix?(_prefix, _path), do: false

  defp state_rule_condition("hover"), do: {:ok, :hover}
  defp state_rule_condition("focus_within"), do: {:ok, :focus_within}
  defp state_rule_condition(_condition), do: {:error, :state_rule_validator_contract_broken}

  defp state_rule_styles(declarations) when is_map(declarations) do
    Enum.reduce_while(declarations, {:ok, %{}}, fn {property, tagged_value}, {:ok, styles} ->
      case state_rule_style_value(tagged_value) do
        {:ok, style_value} -> {:cont, {:ok, Map.put(styles, property, style_value)}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end

  defp state_rule_styles(_declarations),
    do: {:error, :state_rule_validator_contract_broken}

  defp state_rule_style_value(%{"kind" => "literal", "value" => value}),
    do: {:ok, StyleValue.literal(value)}

  defp state_rule_style_value(%{"kind" => "keyword", "value" => value}),
    do: {:ok, StyleValue.keyword(value)}

  defp state_rule_style_value(%{"kind" => "token_ref", "value" => value}),
    do: {:ok, StyleValue.token_ref(value)}

  defp state_rule_style_value(%{"kind" => "calculation", "value" => value}),
    do: {:ok, StyleValue.calculation(value)}

  defp state_rule_style_value(_tagged_value),
    do: {:error, :state_rule_validator_contract_broken}

  defp state_rule_viewport(nil), do: {:ok, nil}

  defp state_rule_viewport(%{"min_width" => min_width, "max_width" => max_width} = viewport)
       when map_size(viewport) == 2 do
    {:ok, %{min_width: min_width, max_width: max_width}}
  end

  defp state_rule_viewport(_viewport),
    do: {:error, :state_rule_validator_contract_broken}

  defp validate_state_rule_pseudo_precedence(state_rules, pseudo_styles) do
    hover_styles = Map.get(pseudo_styles, :hover, %{})
    hover_properties = MapSet.new(Map.keys(hover_styles))

    collides? =
      Enum.any?(state_rules, fn state_rule ->
        state_rule.owner_node_id == state_rule.target_node_id and
          state_rule.condition == :hover and
          Enum.any?(Map.keys(state_rule.styles), &MapSet.member?(hover_properties, &1))
      end)

    if collides?,
      do: {:error, style_diagnostic(:state_rule_pseudo_precedence_gap)},
      else: :ok
  end

  defp collect_subtree_slot_style(
         %DesignNode{semantic_type: "button", attributes: %{"style" => "primary"}} = node,
         "primary_action",
         private_class_by_id,
         {rendered, classes, slot_targets, state_rule_acc} = acc
       ) do
    responsive = responsive_overrides(node.responsive)

    cond do
      Map.get(node.attributes, "outline") in [true, "true"] ->
        case primary_action_styles(node) do
          {:error, diagnostic} -> {:error, diagnostic}
          {:ok, _, _} -> {:ok, acc}
        end

      node.styles != %{} or responsive != [] ->
        {:error,
         diagnostic(
           @primary_slot_gap_code,
           "Styled primary action subtree slot target has no proven presentation partition",
           %{node_id: node.node_id}
         )}

      true ->
        with {:ok, base_styles, pseudo_styles} <- node_style(node) do
          class = Map.fetch!(private_class_by_id, node.node_id)

          {:ok,
           {[{:primary_action_slot, class, base_styles, pseudo_styles} | rendered],
            Map.put(classes, node.node_id, class), MapSet.put(slot_targets, node.node_id),
            state_rule_acc}}
        end
    end
  end

  defp collect_subtree_slot_style(_node, _public_slot_name, _private_class_by_id, acc),
    do: {:ok, acc}

  defp collect_figure_image_style(
         node,
         class,
         base_styles,
         responsive,
         pseudo_styles,
         styled?,
         root?,
         {rendered, classes, slot_targets, state_rule_acc}
       ) do
    cond do
      responsive != [] or pseudo_styles != %{} ->
        {:error, style_locus_gap(node.node_id)}

      true ->
        with {:ok, {figure_styles, image_styles}} <-
               partition_figure_image_styles(node.node_id, base_styles) do
          image_styles =
            if Enum.any?(@figure_image_radius_properties, &Map.has_key?(figure_styles, &1)) do
              Map.put(image_styles, "border-radius", StyleValue.keyword("inherit"))
            else
              image_styles
            end

          classes =
            if root? or styled?, do: Map.put(classes, node.node_id, class), else: classes

          rendered =
            if styled?,
              do: [{:figure_image, class, figure_styles, image_styles} | rendered],
              else: rendered

          {:ok, {rendered, classes, slot_targets, state_rule_acc}}
        end
    end
  end

  defp partition_figure_image_styles(node_id, styles) do
    Enum.reduce_while(styles, {:ok, {%{}, %{}}}, fn {property, value}, {:ok, {figure, image}} ->
      case property do
        "border-radius" ->
          {:cont, {:ok, {Map.put(figure, property, value), image}}}

        "border-top-left-radius" ->
          {:cont, {:ok, {Map.put(figure, property, value), image}}}

        "border-top-right-radius" ->
          {:cont, {:ok, {Map.put(figure, property, value), image}}}

        "border-bottom-right-radius" ->
          {:cont, {:ok, {Map.put(figure, property, value), image}}}

        "border-bottom-left-radius" ->
          {:cont, {:ok, {Map.put(figure, property, value), image}}}

        "aspect-ratio" ->
          {:cont, {:ok, {figure, Map.put(image, property, value)}}}

        "object-fit" ->
          {:cont, {:ok, {figure, Map.put(image, property, value)}}}

        "width" ->
          {:cont, {:ok, {Map.put(figure, property, value), Map.put(image, property, value)}}}

        "height" ->
          {:cont, {:ok, {Map.put(figure, property, value), Map.put(image, property, value)}}}

        _unsupported ->
          {:halt, {:error, style_locus_gap(node_id)}}
      end
    end)
  end

  defp node_style(%DesignNode{} = node) do
    with {:ok, action_styles, pseudo_styles} <- primary_action_styles(node),
         :ok <- no_base_collisions(node.styles, action_styles) do
      base_styles =
        node
        |> semantic_base_styles()
        |> Map.merge(node.styles)
        |> Map.merge(action_styles)

      {:ok, base_styles, pseudo_styles}
    end
  end

  defp semantic_base_styles(%DesignNode{
         semantic_type: "heading",
         attributes: %{"tag" => "h2"}
       }) do
    %{
      "font-size" => StyleValue.token_ref("typography.heading.scale.h2"),
      "font-weight" => StyleValue.token_ref("typography.heading.font_weight"),
      "line-height" => StyleValue.token_ref("typography.heading.line_height")
    }
  end

  defp semantic_base_styles(_node), do: %{}

  defp primary_action_styles(%DesignNode{semantic_type: "button", attributes: attrs}) do
    if Map.get(attrs, "style") == "primary" do
      cond do
        Map.get(attrs, "outline") in [true, "true"] ->
          {:error,
           diagnostic(
             @primary_variant_gap_code,
             "Primary button outline variant authority is unresolved"
           )}

        true ->
          base =
            Map.new(@primary_base_tokens, fn {property, path} ->
              {property, StyleValue.token_ref(path)}
            end)

          {:ok, base,
           %{
             hover: %{
               "background-color" => StyleValue.token_ref("button.primary.background_hover")
             },
             focus_visible: %{
               "outline-color" => StyleValue.token_ref("button.primary.focus"),
               "outline-style" => StyleValue.keyword("solid"),
               "outline-width" => StyleValue.literal("2px"),
               "outline-offset" => StyleValue.literal("2px")
             }
           }}
      end
    else
      {:ok, %{}, %{}}
    end
  end

  defp primary_action_styles(_node), do: {:ok, %{}, %{}}

  defp no_base_collisions(styles, action_styles) do
    if MapSet.size(
         MapSet.intersection(MapSet.new(Map.keys(styles)), MapSet.new(Map.keys(action_styles)))
       ) == 0 do
      :ok
    else
      {:error,
       diagnostic(
         @primary_precedence_gap_code,
         "Primary action and normalized base styles overlap"
       )}
    end
  end

  defp responsive_overrides(responsive) when is_map(responsive), do: Map.values(responsive)
  defp responsive_overrides(responsive) when is_list(responsive), do: responsive
  defp responsive_overrides(nil), do: []
  defp responsive_overrides(_), do: [:invalid_responsive_authority]

  defp validate_cross_owner_state_cascade(state_rules) do
    declarations_by_target_property =
      Enum.reduce(state_rules, %{}, fn state_rule, grouped ->
        Enum.reduce(state_rule.styles, grouped, fn {property, style_value}, acc ->
          key = {state_rule.target_node_id, property}

          event = %{
            owner_node_id: state_rule.owner_node_id,
            style_value: style_value,
            viewport: state_rule.viewport
          }

          Map.update(acc, key, [event], &[event | &1])
        end)
      end)

    if Enum.any?(Map.values(declarations_by_target_property), &cross_owner_interval_conflict?/1) do
      {:error, style_diagnostic(:state_rule_cross_owner_cascade_authority_gap)}
    else
      :ok
    end
  end

  defp cross_owner_interval_conflict?(events) do
    distinct_owners = events |> Enum.map(& &1.owner_node_id) |> Enum.uniq()

    if length(distinct_owners) <= 1 do
      false
    else
      case serialize_cross_owner_values(events) do
        {:ok, serialized_events} -> sweep_cross_owner_intervals(serialized_events)
        {:error, _reason} -> false
      end
    end
  end

  defp serialize_cross_owner_values(events) do
    Enum.reduce_while(events, {:ok, []}, fn event, {:ok, acc} ->
      case StyleValueCSS.serialize(event.style_value) do
        {:ok, value} -> {:cont, {:ok, [Map.put(event, :value, value) | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, serialized_events} -> {:ok, Enum.reverse(serialized_events)}
      {:error, _reason} = error -> error
    end
  end

  defp sweep_cross_owner_intervals(events) do
    ordered_events =
      events
      |> Enum.with_index()
      |> Enum.sort_by(fn {event, index} ->
        {state_lower_bound_sort_key(viewport_min(event.viewport)), index}
      end)

    initial_active = %{
      endpoints: :gb_sets.empty(),
      events: %{},
      owner_counts: %{},
      value_counts: %{},
      owner_value_counts: %{},
      count: 0
    }

    Enum.reduce_while(ordered_events, {:ok, initial_active}, fn {event, id}, {:ok, active} ->
      active = expire_state_intervals(active, viewport_min(event.viewport))
      owner_count = Map.get(active.owner_counts, event.owner_node_id, 0)
      value_count = Map.get(active.value_counts, event.value, 0)

      owner_value_count =
        Map.get(active.owner_value_counts, {event.owner_node_id, event.value}, 0)

      conflicting_other_owner? =
        active.count - owner_count > value_count - owner_value_count

      if conflicting_other_owner? do
        {:halt, :conflict}
      else
        {:cont, {:ok, add_active_state_interval(active, event, id)}}
      end
    end)
    |> case do
      :conflict -> true
      {:ok, _active} -> false
    end
  end

  defp expire_state_intervals(active, start_width) do
    if :gb_sets.is_empty(active.endpoints) do
      active
    else
      {{upper_sort_key, id}, remaining_endpoints} = :gb_sets.take_smallest(active.endpoints)
      event = Map.fetch!(active.events, id)

      if state_interval_before_start?(event.viewport, start_width) do
        active
        |> remove_active_state_interval(event, id, remaining_endpoints)
        |> expire_state_intervals(start_width)
      else
        %{active | endpoints: :gb_sets.add({upper_sort_key, id}, remaining_endpoints)}
      end
    end
  end

  defp state_interval_before_start?(viewport, start_width) do
    upper_width = viewport_max(viewport)
    is_number(upper_width) and is_number(start_width) and upper_width < start_width
  end

  defp add_active_state_interval(active, event, id) do
    endpoint = {state_upper_bound_sort_key(viewport_max(event.viewport)), id}

    %{
      active
      | endpoints: :gb_sets.add(endpoint, active.endpoints),
        events: Map.put(active.events, id, event),
        owner_counts: increment_count(active.owner_counts, event.owner_node_id),
        value_counts: increment_count(active.value_counts, event.value),
        owner_value_counts:
          increment_count(active.owner_value_counts, {event.owner_node_id, event.value}),
        count: active.count + 1
    }
  end

  defp remove_active_state_interval(active, event, id, remaining_endpoints) do
    %{
      active
      | endpoints: remaining_endpoints,
        events: Map.delete(active.events, id),
        owner_counts: decrement_count(active.owner_counts, event.owner_node_id),
        value_counts: decrement_count(active.value_counts, event.value),
        owner_value_counts:
          decrement_count(active.owner_value_counts, {event.owner_node_id, event.value}),
        count: active.count - 1
    }
  end

  defp increment_count(counts, key), do: Map.update(counts, key, 1, &(&1 + 1))

  defp decrement_count(counts, key) do
    case Map.fetch!(counts, key) do
      1 -> Map.delete(counts, key)
      count -> Map.put(counts, key, count - 1)
    end
  end

  defp state_lower_bound_sort_key(nil), do: {0, 0}
  defp state_lower_bound_sort_key(width), do: {1, width}

  defp state_upper_bound_sort_key(nil), do: {1, 0}
  defp state_upper_bound_sort_key(width), do: {0, width}

  defp viewport_min(nil), do: nil
  defp viewport_min(%{min_width: min_width}), do: min_width
  defp viewport_max(nil), do: nil
  defp viewport_max(%{max_width: max_width}), do: max_width

  defp render_styles_and_state(style_result) do
    with {:ok, ordinary_css} <- render_styles(style_result.entries),
         {:ok, state_css} <- render_state_rules(style_result.state_rules) do
      {:ok, append_stylesheet_css(ordinary_css, state_css)}
    end
  end

  defp render_state_rules(state_rules) do
    Enum.reduce_while(state_rules, {:ok, []}, fn state_rule, {:ok, acc} ->
      case StylesheetRenderer.render_state_rule(
             state_rule.owner_private_class,
             state_rule.target_private_class,
             state_rule.condition,
             state_rule.styles,
             state_rule.viewport
           ) do
        {:ok, ""} -> {:cont, {:ok, acc}}
        {:ok, css} -> {:cont, {:ok, [String.trim_trailing(css) | acc]}}
        {:error, diagnostic} -> {:halt, {:error, diagnostic}}
      end
    end)
    |> case do
      {:ok, blocks} ->
        css = blocks |> Enum.reverse() |> Enum.join("\n\n")
        {:ok, trailing_newline(css)}

      {:error, diagnostic} ->
        {:error, diagnostic}
    end
  end

  defp append_stylesheet_css(ordinary_css, ""), do: ordinary_css
  defp append_stylesheet_css("", state_css), do: state_css

  defp append_stylesheet_css(ordinary_css, state_css),
    do: String.trim_trailing(ordinary_css) <> "\n\n" <> String.trim_trailing(state_css) <> "\n"

  defp render_styles(styles) do
    Enum.reduce_while(styles, {:ok, []}, fn style_entry, {:ok, acc} ->
      with {:ok, css, pseudo_css} <- render_style_entry(style_entry) do
        content =
          [css, pseudo_css]
          |> Enum.reject(&(&1 == ""))
          |> Enum.map(&String.trim_trailing/1)
          |> Enum.join("\n\n")

        {:cont, {:ok, [content | acc]}}
      else
        {:error, diagnostic} -> {:halt, {:error, diagnostic}}
      end
    end)
    |> case do
      {:ok, blocks} ->
        css =
          blocks
          |> Enum.reverse()
          |> Enum.reject(&(&1 == ""))
          |> Enum.join("\n\n")

        {:ok, trailing_newline(css)}

      {:error, diagnostic} ->
        {:error, diagnostic}
    end
  end

  defp render_style_entry({:single, class, base, responsive, pseudos}) do
    with {:ok, css} <- StylesheetRenderer.render(class, base, responsive),
         {:ok, pseudo_css} <- render_pseudos(class, pseudos) do
      {:ok, css, pseudo_css}
    end
  end

  defp render_style_entry({:figure_image, class, figure_styles, image_styles}) do
    with {:ok, css} <- StylesheetRenderer.render_figure_image(class, figure_styles, image_styles) do
      {:ok, css, ""}
    end
  end

  defp render_style_entry({:primary_action_slot, class, base_styles, pseudo_styles}) do
    case StylesheetRenderer.render_primary_action_slot(class, base_styles, pseudo_styles) do
      {:ok, css} -> {:ok, css, ""}
      {:error, diagnostic} -> {:error, diagnostic}
    end
  end

  defp render_style_entry({:heading_navigation, class}) do
    case StylesheetRenderer.render_heading_navigation_anchor(class) do
      {:ok, css} -> {:ok, css, ""}
      {:error, diagnostic} -> {:error, diagnostic}
    end
  end

  defp navigable_heading?(%DesignNode{semantic_type: "heading", attributes: attributes})
       when is_map(attributes),
       do: Map.has_key?(attributes, "navigation")

  defp navigable_heading?(_node), do: false

  defp render_pseudos(class, pseudos) do
    Enum.reduce_while([:hover, :focus_visible], {:ok, []}, fn pseudo, {:ok, acc} ->
      case Map.fetch(pseudos, pseudo) do
        {:ok, styles} ->
          case StylesheetRenderer.render_pseudo(class, pseudo, styles) do
            {:ok, ""} -> {:cont, {:ok, acc}}
            {:ok, css} -> {:cont, {:ok, [css | acc]}}
            {:error, diagnostic} -> {:halt, {:error, diagnostic}}
          end

        :error ->
          {:cont, {:ok, acc}}
      end
    end)
    |> case do
      {:ok, blocks} ->
        {:ok,
         blocks
         |> Enum.reverse()
         |> Enum.map(&String.trim_trailing/1)
         |> Enum.join("\n\n")}

      {:error, diagnostic} ->
        {:error, diagnostic}
    end
  end

  defp trailing_newline(""), do: ""
  defp trailing_newline(css), do: css <> "\n"

  defp stylesheet_path(%ComponentContract{category: category, module_intent: intent}) do
    directory =
      case category do
        :section -> "sections/"
        :component -> ""
        :pattern -> "patterns/"
        :primitive -> "primitives/"
        _ -> nil
      end

    if is_binary(directory) and is_binary(intent) do
      {:ok, "assets/css/components/" <> directory <> intent <> ".css"}
    else
      {:error, :invalid_stylesheet_authority}
    end
  end

  defp figure_image?(%DesignNode{semantic_type: "image", attributes: attrs}),
    do: Map.get(attrs, "tag") == "figure"

  defp figure_image?(_node), do: false

  defp style_locus_gap(node_id),
    do:
      diagnostic(@locus_gap_code, "Image styles cannot be assigned to a proven native element", %{
        node_id: node_id
      })

  defp style_diagnostic(reason),
    do:
      Diagnostic.error(
        "native_generator.styling.integration_failed",
        "Native styling input could not be integrated",
        %{reason: reason}
      )

  defp diagnostic(code, message, metadata \\ %{}), do: Diagnostic.error(code, message, metadata)

  defp blocked(diagnostic), do: {:error, :generation_blocked, [diagnostic]}
end
