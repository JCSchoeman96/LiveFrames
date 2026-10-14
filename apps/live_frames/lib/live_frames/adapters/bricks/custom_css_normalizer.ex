defmodule LiveFrames.Adapters.Bricks.CustomCssNormalizer do
  @moduledoc false

  alias LiveFrames.Adapters.Bricks.CustomCssParser
  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.TransientStyleState
  alias LiveFrames.Fidelity.CSSDeclaration
  alias LiveFrames.IR.ResponsiveOverride
  alias LiveFrames.IR.SourceTrace
  alias LiveFrames.IR.StyleValue
  alias LiveFrames.Tokens.VariableAuthority

  @keyword_values ~w(
    auto block bold border-box content-box currentColor flex grid hidden inherit initial
    inline inline-block inline-flex inline-grid inherit none normal revert revert-layer
    static unset visible
  )

  @grid_gap_multiply_expression ~r/^calc\s*\(\s*var\s*\(\s*--grid-gap\s*\)\s*\*\s*(\d+(?:\.\d+)?|\.\d+)\s*\)$/i
  @direct_variable_expression ~r/^var\(\s*(--[A-Za-z0-9_-]+)\s*\)$/
  @unsafe_value_fragments ["url(", "expression(", "javascript:", "behavior:", "-moz-binding"]

  @type owner :: %{
          required(:source_id) => String.t(),
          required(:value) => String.t(),
          required(:provenance) => map(),
          optional(:source_key) => String.t()
        }

  @type node_context :: %{
          required(:node_id) => String.t(),
          required(:source_id) => String.t(),
          required(:classes) => [String.t()],
          required(:path) => [pos_integer()],
          optional(:parent_id) => String.t() | nil,
          optional(:styles) => map(),
          optional(:responsive) => map(),
          optional(:source_trace) => SourceTrace.t() | nil
        }

  @spec normalize(
          [owner()],
          %{optional(String.t()) => node_context()},
          map(),
          MapSet.t(),
          keyword()
        ) :: map()
  def normalize(owners, nodes, children_by_source_id, claimed_source_ids, opts \\ [])

  def normalize(owners, nodes, children_by_source_id, claimed_source_ids, opts)
      when is_list(owners) and is_map(nodes) and is_map(children_by_source_id) and
             is_struct(claimed_source_ids, MapSet) and is_list(opts) do
    all_source_classes =
      nodes
      |> Map.values()
      |> Enum.flat_map(&Map.get(&1, :classes, []))
      |> MapSet.new()

    opts = Keyword.put_new(opts, :all_source_classes, all_source_classes)

    owners
    |> Enum.group_by(&Map.get(&1, :source_id))
    |> Enum.sort_by(fn {source_id, _owners} -> node_path(nodes, source_id) end)
    |> Enum.reduce(empty_result(), fn {source_id, source_owners}, result ->
      cond do
        not is_binary(source_id) or MapSet.member?(claimed_source_ids, source_id) ->
          result

        not Map.has_key?(nodes, source_id) ->
          add_unresolved_owner(result, source_id, source_owners)

        true ->
          normalize_owner_sources(
            source_id,
            source_owners,
            nodes,
            children_by_source_id,
            result,
            opts
          )
      end
    end)
  end

  def normalize(_owners, _nodes, _children, _claimed_source_ids, _opts),
    do: empty_result()

  @spec empty_result() :: map()
  def empty_result do
    %{
      styles_by_source_id: %{},
      responsive_by_source_id: %{},
      custom_css_by_source_id: %{},
      residuals_by_source_id: %{},
      diagnostics: []
    }
  end

  defp normalize_owner_sources(
         source_id,
         source_owners,
         nodes,
         children_by_source_id,
         result,
         opts
       ) do
    owner_node = Map.fetch!(nodes, source_id)
    scope_ids = owner_scope(source_id, children_by_source_id)
    scope_nodes = Map.take(nodes, MapSet.to_list(scope_ids))

    {frames, rejects, owner_sources} = collect_frames(source_owners, source_id)

    if frames == [] and map_size(rejects) == 0 do
      result
    else
      normalize_owner_frames(
        source_id,
        source_owners,
        owner_sources,
        owner_node,
        scope_nodes,
        scope_ids,
        frames,
        rejects,
        result,
        opts
      )
    end
  end

  defp normalize_owner_frames(
         source_id,
         source_owners,
         owner_sources,
         owner_node,
         scope_nodes,
         scope_ids,
         frames,
         rejects,
         result,
         opts
       ) do
    {base_candidates, responsive_candidates, state_candidates, residuals} =
      Enum.reduce(frames, {[], [], [], rejects}, fn frame_entry,
                                                    {base, responsive, states, residuals} ->
        case normalize_frame(frame_entry, owner_node, scope_nodes, scope_ids, opts) do
          {:ok, candidates} ->
            {
              base ++ Enum.filter(candidates, &(is_nil(&1.viewport) and is_nil(&1.condition))),
              responsive ++
                Enum.filter(candidates, &(not is_nil(&1.viewport) and is_nil(&1.condition))),
              states ++ Enum.filter(candidates, & &1.condition),
              residuals
            }

          {:residual, residual} ->
            {base, responsive, states, Map.put(residuals, residual.rule_id, residual)}
        end
      end)

    {base_candidates, responsive_candidates, residuals} =
      preflight_base(
        base_candidates,
        responsive_candidates,
        residuals,
        scope_nodes
      )

    {responsive_candidates, residuals} =
      preflight_responsive(
        responsive_candidates,
        residuals,
        scope_nodes,
        opts
      )

    {base_candidates, responsive_candidates} =
      discard_residual_rules(base_candidates, responsive_candidates, residuals)

    state_candidates =
      state_candidates
      |> Enum.reject(&Map.has_key?(residuals, &1.rule_id))
      |> sort_state_candidates()

    result = add_base_styles(result, base_candidates, scope_nodes, source_id, owner_node)

    result =
      add_responsive_styles(result, responsive_candidates, scope_nodes, source_id, owner_node)

    residual_list =
      residuals
      |> Map.values()
      |> Enum.sort_by(&{&1.source_index, &1.source_order})
      |> Enum.map(&%{"reason" => &1.reason, "source_text" => &1.source_text})

    state_rules = build_state_rules(state_candidates)
    source_key = source_owners |> List.first() |> Map.get(:source_key, "_cssCustom")

    custom_css_value =
      cond do
        state_rules != [] ->
          StyleValue.complex_css(
            %{"type" => "state_rules", "rules" => state_rules, "residual" => residual_list},
            source_expression: Enum.map_join(owner_sources, "\n", & &1.value),
            source_trace: custom_css_trace(owner_node, source_id, source_owners),
            metadata: %{"source_key" => source_key}
          )

        residual_list != [] ->
          residual_rules =
            if base_candidates == [] and responsive_candidates == [] do
              Enum.map(source_owners, &Map.get(&1, :value))
            else
              Enum.map(residual_list, & &1["source_text"])
            end

          StyleValue.complex_css(
            %{
              "type" => "custom_css",
              "property" => "custom-css",
              "source_key" => source_key,
              "rules" => residual_rules
            },
            source_expression: Enum.map_join(owner_sources, "\n", & &1.value),
            source_trace: custom_css_trace(owner_node, source_id, source_owners),
            metadata: %{"source_key" => source_key}
          )

        true ->
          nil
      end

    result
    |> Map.update!(:custom_css_by_source_id, &Map.put(&1, source_id, custom_css_value))
    |> Map.update!(:residuals_by_source_id, &Map.put(&1, source_id, residual_list))
    |> Map.update!(
      :diagnostics,
      &(&1 ++ residual_diagnostics(source_id, residuals, owner_node, source_owners))
    )
  end

  defp collect_frames(source_owners, source_id) do
    source_owners
    |> Enum.with_index()
    |> Enum.reduce({[], %{}, []}, fn {owner, source_index}, {frames, rejects, accepted_owners} ->
      source_text = Map.get(owner, :value)
      provenance = Map.get(owner, :provenance)

      if valid_effective_provenance?(source_id, provenance) and is_binary(source_text) and
           String.valid?(source_text) do
        parsed = CustomCssParser.parse(source_text)

        source_frames =
          Enum.map(parsed.frames, fn frame ->
            Map.merge(frame, %{
              source_index: source_index,
              source_key: Map.get(owner, :source_key, "_cssCustom"),
              provenance: provenance,
              aliases: TransientStyleState.resolve_aliases(source_text, provenance)
            })
          end)

        source_rejects =
          Enum.reduce(parsed.rejects, rejects, fn reject, rejects ->
            residual = parser_residual(reject, source_index)
            Map.put(rejects, residual.rule_id, residual)
          end)

        {frames ++ source_frames, source_rejects, accepted_owners ++ [owner]}
      else
        residual = %{
          rule_id: {source_index, 0},
          source_index: source_index,
          source_order: 0,
          reason: "unresolved_value",
          source_text: if(is_binary(source_text), do: source_text, else: "")
        }

        {frames, Map.put(rejects, residual.rule_id, residual), accepted_owners}
      end
    end)
  end

  defp valid_effective_provenance?(source_id, provenance) when is_map(provenance) do
    non_empty_string?(source_id) and Map.get(provenance, :source_id) == source_id and
      is_map(Map.get(provenance, :layer_settings)) and
      case Map.get(provenance, :origin) do
        :global_class ->
          non_empty_string?(Map.get(provenance, :class_id)) and
            Map.get(provenance, :resolution_source) in [:local, :external] and
            is_list(Map.get(provenance, :authority_ids)) and
            Enum.all?(Map.get(provenance, :authority_ids), &non_empty_string?/1) and
            (Map.get(provenance, :resolution_source) != :external or
               Map.get(provenance, :authority_ids) != []) and
            is_integer(Map.get(provenance, :class_reference_index)) and
            Map.get(provenance, :class_reference_index) >= 0

        :element_local ->
          is_nil(Map.get(provenance, :class_id)) and
            is_nil(Map.get(provenance, :resolution_source)) and
            Map.get(provenance, :authority_ids) == [] and
            is_nil(Map.get(provenance, :class_reference_index))

        _ ->
          false
      end
  end

  defp valid_effective_provenance?(_source_id, _provenance), do: false

  defp normalize_frame(frame, owner_node, scope_nodes, scope_ids, opts) do
    rule_id = {frame.source_index, frame.source_order}
    all_source_classes = Keyword.get(opts, :all_source_classes, MapSet.new())

    with {:ok, selections} <-
           resolve_selector(
             frame.selector,
             frame.aliases,
             owner_node,
             scope_nodes,
             scope_ids,
             all_source_classes
           ),
         {:ok, declarations} <- normalize_declarations(frame.declarations, opts) do
      viewport = viewport(frame.min_width, frame.max_width)

      candidates =
        Enum.flat_map(selections, fn %{targets: targets, condition: condition} ->
          Enum.map(targets, fn target ->
            %{
              rule_id: rule_id,
              source_index: frame.source_index,
              source_order: frame.source_order,
              target_source_id: target.source_id,
              target_node_id: target.node_id,
              target_path: target.path,
              declarations: declarations,
              viewport: viewport,
              condition: condition,
              source_text: frame.raw,
              source_key: frame.source_key,
              provenance: frame.provenance,
              owner_source_id: owner_node.source_id
            }
          end)
        end)

      {:ok, candidates}
    else
      {:error, reason} ->
        {:residual,
         %{
           rule_id: rule_id,
           source_index: frame.source_index,
           source_order: frame.source_order,
           reason: reason,
           source_text: frame.raw
         }}
    end
  end

  defp resolve_selector(selector, aliases, owner_node, scope_nodes, scope_ids, all_source_classes) do
    groups = String.split(selector, ",")

    if groups == [] or Enum.any?(groups, &(String.trim(&1) == "")) do
      {:error, "unsupported_selector"}
    else
      Enum.reduce_while(groups, {:ok, []}, fn group, {:ok, selections} ->
        with {:ok, compounds, condition} <- parse_selector_group(String.trim(group), aliases),
             :ok <- selector_classes_known(compounds, all_source_classes, aliases),
             :ok <- state_owner_matches(condition, hd(compounds), owner_node, scope_nodes),
             {:ok, group_targets} <-
               matching_targets(compounds, condition, owner_node, scope_nodes, scope_ids) do
          selection = %{
            targets: Enum.uniq_by(group_targets, & &1.source_id),
            condition: condition
          }

          {:cont, {:ok, selections ++ [selection]}}
        else
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
      |> case do
        {:ok, []} ->
          {:error, "unresolved_target"}

        {:ok, selections} ->
          {:ok, selections}

        error ->
          error
      end
    end
  end

  defp parse_selector_group(selector, aliases) do
    if String.contains?(selector, [">", "+", "~", "[", "]", "#", "\\", "(", ")"]) do
      {:error, "unsupported_selector"}
    else
      compounds =
        selector
        |> String.split(~r/\s+/u, trim: true)
        |> Enum.map(&parse_compound(&1, aliases))

      cond do
        compounds == [] or Enum.any?(compounds, &match?({:error, _}, &1)) ->
          {:error, "unsupported_selector"}

        true ->
          compounds = Enum.map(compounds, fn {:ok, compound} -> compound end)

          markers =
            Enum.with_index(compounds)
            |> Enum.flat_map(fn {compound, index} ->
              if compound.marker, do: [{index, compound.marker}], else: []
            end)

          cond do
            length(markers) > 1 ->
              {:error, "unsupported_selector"}

            markers != [] and hd(markers) |> elem(0) != 0 ->
              {:error, "unsupported_selector"}

            true ->
              condition =
                case markers do
                  [{0, :hover}] -> "hover"
                  [{0, :focus_within}] -> "focus_within"
                  [] -> nil
                end

              {:ok, compounds, condition}
          end
      end
    end
  end

  defp parse_compound(compound, aliases) do
    matches = Regex.scan(~r/\.([-_A-Za-z][A-Za-z0-9_-]*)|:(hover|focus-within)/u, compound)
    reconstructed = Enum.map_join(matches, &hd/1)

    if matches == [] or reconstructed != compound do
      {:error, "unsupported_selector"}
    else
      Enum.reduce_while(matches, {:ok, %{classes: [], marker: nil}}, fn
        [_full, class], {:ok, parsed} ->
          if Map.has_key?(aliases, class) do
            if is_nil(parsed.marker),
              do: {:cont, {:ok, %{parsed | marker: :hover}}},
              else: {:halt, {:error, "unsupported_selector"}}
          else
            {:cont, {:ok, %{parsed | classes: parsed.classes ++ [class]}}}
          end

        [_full, "", "hover"], {:ok, parsed} ->
          if is_nil(parsed.marker),
            do: {:cont, {:ok, %{parsed | marker: :hover}}},
            else: {:halt, {:error, "unsupported_selector"}}

        [_full, "", "focus-within"], {:ok, parsed} ->
          if is_nil(parsed.marker),
            do: {:cont, {:ok, %{parsed | marker: :focus_within}}},
            else: {:halt, {:error, "unsupported_selector"}}
      end)
    end
  end

  defp selector_classes_known(compounds, known_classes, aliases) do
    classes = Enum.flat_map(compounds, & &1.classes)

    if Enum.all?(classes, &(MapSet.member?(known_classes, &1) or Map.has_key?(aliases, &1))),
      do: :ok,
      else: {:error, "unsupported_selector"}
  end

  defp state_owner_matches(nil, _first_compound, _owner_node, _scope_nodes), do: :ok

  defp state_owner_matches(_condition, %{classes: []}, _owner_node, _scope_nodes),
    do: {:error, "unresolved_target"}

  defp state_owner_matches(_condition, first_compound, owner_node, scope_nodes) do
    matches =
      scope_nodes
      |> Enum.filter(fn {_id, node} -> matches_compound?(node, first_compound) end)
      |> Enum.map(&elem(&1, 0))

    cond do
      matches == [owner_node.source_id] -> :ok
      owner_node.source_id in matches -> {:error, "ambiguous_selector"}
      true -> {:error, "unresolved_target"}
    end
  end

  defp matching_targets(compounds, condition, owner_node, scope_nodes, scope_ids) do
    candidates =
      if condition do
        Enum.filter(
          Map.values(scope_nodes),
          &descendant_or_self?(owner_node.source_id, &1.source_id, scope_ids)
        )
      else
        Map.values(scope_nodes)
      end

    targets =
      candidates
      |> Enum.filter(fn node ->
        matches_selector_chain?(node.source_id, compounds, scope_nodes, scope_ids)
      end)
      |> Enum.sort_by(& &1.path)

    cond do
      targets == [] ->
        {:error, "unresolved_target"}

      length(targets) > 1 ->
        {:error, "ambiguous_selector"}

      condition && hd(targets).source_id != owner_node.source_id &&
          not descendant_or_self?(owner_node.source_id, hd(targets).source_id, scope_ids) ->
        {:error, "unresolved_target"}

      true ->
        {:ok, targets}
    end
  end

  defp matches_selector_chain?(source_id, compounds, scope_nodes, scope_ids) do
    case Enum.reverse(compounds) do
      [last] ->
        case Map.get(scope_nodes, source_id) do
          nil -> false
          node -> matches_compound?(node, last)
        end

      [last | preceding_reversed] ->
        case Map.get(scope_nodes, source_id) do
          nil ->
            false

          node ->
            matches_compound?(node, last) and
              match_ancestor_compounds(node.parent_id, preceding_reversed, scope_nodes, scope_ids)
        end
    end
  end

  defp match_ancestor_compounds(_source_id, [], _scope_nodes, _scope_ids), do: true
  defp match_ancestor_compounds(nil, _compounds, _scope_nodes, _scope_ids), do: false

  defp match_ancestor_compounds(source_id, [compound | rest], scope_nodes, scope_ids) do
    if MapSet.member?(scope_ids, source_id) do
      case Map.get(scope_nodes, source_id) do
        nil ->
          false

        node ->
          if matches_compound?(node, compound),
            do: match_ancestor_compounds(node.parent_id, rest, scope_nodes, scope_ids),
            else:
              match_ancestor_compounds(node.parent_id, [compound | rest], scope_nodes, scope_ids)
      end
    else
      false
    end
  end

  defp matches_compound?(node, %{classes: [_ | _] = classes}) do
    source_classes = Map.get(node, :classes, [])
    Enum.all?(classes, &(&1 in source_classes))
  end

  defp matches_compound?(_node, _compound), do: false

  defp descendant_or_self?(_owner_id, target_id, scope_ids),
    do: MapSet.member?(scope_ids, target_id)

  defp normalize_declarations(declarations, opts)
       when is_map(declarations) and map_size(declarations) > 0 do
    declarations
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.reduce_while({:ok, %{}}, fn {property, value}, {:ok, normalized} ->
      case normalize_declaration(property, value, opts) do
        {:ok, tagged} -> {:cont, {:ok, Map.put(normalized, property, tagged)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp normalize_declarations(_declarations, _opts), do: {:error, "unsupported_declaration"}

  defp normalize_declaration(property, value, opts)
       when is_binary(property) and is_binary(value) do
    lowered = String.downcase(value)

    cond do
      Enum.any?(@unsafe_value_fragments, &String.contains?(lowered, &1)) ->
        {:error, "unsafe_declaration"}

      not CSSDeclaration.safe_property?(property) or property == "custom-css" ->
        {:error, "unsupported_declaration"}

      not match?({:ok, _}, CSSDeclaration.normalize(%{property: property, value: value}, :ir)) ->
        {:error, "unsafe_declaration"}

      true ->
        normalize_declaration_value(property, String.trim(value), opts)
    end
  end

  defp normalize_declaration(_property, _value, _opts), do: {:error, "unsupported_declaration"}

  defp normalize_declaration_value(property, value, opts) do
    cond do
      value in @keyword_values ->
        {:ok, %{"kind" => "keyword", "value" => value}}

      match = Regex.run(@direct_variable_expression, value) ->
        [_, variable] = match
        authority_index = Keyword.get(opts, :authority_index)

        resolution =
          if authority_index, do: VariableAuthority.resolve(authority_index, variable), else: nil

        case resolution do
          %{
            state: :unique_candidate,
            candidates: [%{token_path: path, resolution_status: :resolved}]
          }
          when is_binary(path) ->
            {:ok, %{"kind" => "token_ref", "value" => path}}

          _ ->
            {:error, "unresolved_value"}
        end

      match = Regex.run(@grid_gap_multiply_expression, value) ->
        [_, factor_text] = match

        if property == "gap" do
          with {:ok, factor} <- positive_finite_number(factor_text),
               true <- grid_gap_authorized?(Keyword.get(opts, :authority_index)) do
            {:ok,
             %{
               "kind" => "calculation",
               "value" => %{
                 "operation" => "multiply",
                 "operands" => [
                   %{"kind" => "token_ref", "path" => "spacing.grid_gap"},
                   %{"kind" => "literal", "value" => factor}
                 ]
               }
             }}
          else
            _ -> {:error, "unresolved_value"}
          end
        else
          {:error, "unresolved_value"}
        end

      String.contains?(String.downcase(value), "var(") or
          String.contains?(String.downcase(value), "calc(") ->
        {:error, "unresolved_value"}

      true ->
        {:ok, %{"kind" => "literal", "value" => value}}
    end
  end

  defp positive_finite_number(text) do
    case Float.parse(text) do
      {number, ""} when number > 0 and number == number ->
        if number <= 1.7976931348623157e308, do: {:ok, number}, else: :error

      _ ->
        :error
    end
  end

  defp grid_gap_authorized?(nil), do: false

  defp grid_gap_authorized?(authority_index) do
    case VariableAuthority.resolve(authority_index, "--grid-gap") do
      %{
        state: :unique_candidate,
        candidates: [%{token_path: "spacing.grid_gap", resolution_status: :resolved}]
      } ->
        true

      _ ->
        false
    end
  end

  defp preflight_base(base_candidates, responsive_candidates, residuals, scope_nodes) do
    existing_collisions =
      Enum.flat_map(base_candidates, fn candidate ->
        node = Map.fetch!(scope_nodes, candidate.target_source_id)

        Enum.flat_map(candidate.declarations, fn {property, _tagged} ->
          if Map.has_key?(Map.get(node, :styles, %{}), property),
            do: [{candidate.rule_id, "style_collision"}],
            else: []
        end)
      end)

    duplicate_collisions = candidate_conflicts(base_candidates, nil)

    residuals =
      add_rule_conflicts(
        residuals,
        existing_collisions ++ duplicate_collisions,
        base_candidates
      )

    {Enum.reject(base_candidates, &Map.has_key?(residuals, &1.rule_id)), responsive_candidates,
     residuals}
  end

  defp preflight_responsive(candidates, residuals, scope_nodes, opts) do
    key_collisions =
      Enum.flat_map(candidates, fn candidate ->
        node = Map.fetch!(scope_nodes, candidate.target_source_id)
        key = responsive_key(candidate.viewport)

        existing_key? = Map.has_key?(Map.get(node, :responsive, %{}), key)

        existing_property_collision? =
          Enum.any?(Map.get(node, :responsive, %{}), fn {_existing_key, override} ->
            override_interval = %{
              min_width: Map.get(override, :min_width),
              max_width: Map.get(override, :max_width)
            }

            interval_overlap?(candidate.viewport, override_interval) and
              Enum.any?(candidate.declarations, fn {property, _tagged} ->
                Map.has_key?(Map.get(override, :styles, %{}), property)
              end)
          end)

        custom_key? =
          opts
          |> Keyword.get(:existing_custom_responsive_keys, %{})
          |> Map.get(candidate.target_source_id, MapSet.new())
          |> MapSet.member?(key)

        if existing_key? or existing_property_collision? or custom_key?,
          do: [{candidate.rule_id, "responsive_collision"}],
          else: []
      end)

    overlap_conflicts = candidate_conflicts(candidates, :inclusive_overlap)

    residuals =
      add_rule_conflicts(
        residuals,
        key_collisions ++ overlap_conflicts,
        candidates
      )

    candidates = Enum.reject(candidates, &Map.has_key?(residuals, &1.rule_id))
    candidates = deduplicate_responsive_candidates(candidates)
    {candidates, residuals}
  end

  defp candidate_conflicts(candidates, nil) do
    candidates
    |> Enum.with_index()
    |> Enum.flat_map(fn {left, index} ->
      candidates
      |> Enum.drop(index + 1)
      |> Enum.flat_map(fn right ->
        if left.target_source_id == right.target_source_id do
          Enum.flat_map(left.declarations, fn {property, left_value} ->
            case Map.fetch(right.declarations, property) do
              {:ok, right_value} when left_value != right_value ->
                [{left.rule_id, "style_collision"}, {right.rule_id, "style_collision"}]

              _ ->
                []
            end
          end)
        else
          []
        end
      end)
    end)
  end

  defp candidate_conflicts(candidates, :inclusive_overlap) do
    candidates
    |> Enum.with_index()
    |> Enum.flat_map(fn {left, index} ->
      candidates
      |> Enum.drop(index + 1)
      |> Enum.flat_map(fn right ->
        if left.target_source_id == right.target_source_id and
             interval_overlap?(left.viewport, right.viewport) do
          Enum.flat_map(left.declarations, fn {property, left_value} ->
            case Map.fetch(right.declarations, property) do
              {:ok, right_value} when left_value != right_value ->
                [
                  {left.rule_id, "responsive_overlap_conflict"},
                  {right.rule_id, "responsive_overlap_conflict"}
                ]

              _ ->
                []
            end
          end)
        else
          []
        end
      end)
    end)
  end

  defp add_rule_conflicts(residuals, conflicts, candidates) do
    Enum.reduce(conflicts, residuals, fn {rule_id, reason}, residuals ->
      case Map.fetch(residuals, rule_id) do
        {:ok, existing} ->
          if reason == "responsive_overlap_conflict",
            do: Map.put(residuals, rule_id, %{existing | reason: reason}),
            else: residuals

        :error ->
          case Enum.find(candidates, &(&1.rule_id == rule_id)) do
            nil ->
              residuals

            candidate ->
              Map.put(residuals, rule_id, %{
                rule_id: rule_id,
                reason: reason,
                source_text: candidate.source_text,
                source_index: candidate.source_index,
                source_order: candidate.source_order
              })
          end
      end
    end)
  end

  defp discard_residual_rules(base, responsive, residuals) do
    {
      Enum.reject(base, &Map.has_key?(residuals, &1.rule_id)),
      Enum.reject(responsive, &Map.has_key?(residuals, &1.rule_id))
    }
  end

  defp deduplicate_responsive_candidates(candidates) do
    Enum.reduce(candidates, [], fn candidate, deduped ->
      duplicate? =
        Enum.any?(deduped, fn prior ->
          prior.target_source_id == candidate.target_source_id and
            prior.viewport == candidate.viewport and
            prior.declarations == candidate.declarations
        end)

      if duplicate?, do: deduped, else: deduped ++ [candidate]
    end)
  end

  defp add_base_styles(result, candidates, scope_nodes, owner_source_id, owner_node) do
    candidates
    |> Enum.sort_by(&{&1.source_index, &1.source_order, &1.target_path})
    |> Enum.reduce(result, fn candidate, result ->
      node = Map.fetch!(scope_nodes, candidate.target_source_id)
      trace = declaration_trace(owner_node, candidate, owner_source_id)

      styles =
        Enum.reduce(candidate.declarations, %{}, fn {property, tagged}, styles ->
          Map.put(styles, property, style_value(tagged, trace, candidate.source_text))
        end)

      Map.update!(result, :styles_by_source_id, fn by_source ->
        Map.update(by_source, node.source_id, styles, &Map.merge(&1, styles))
      end)
    end)
  end

  defp add_responsive_styles(result, candidates, scope_nodes, owner_source_id, owner_node) do
    candidates
    |> Enum.sort_by(&{&1.source_index, &1.source_order, &1.target_path})
    |> Enum.reduce(result, fn candidate, result ->
      node = Map.fetch!(scope_nodes, candidate.target_source_id)
      key = responsive_key(candidate.viewport)
      trace = declaration_trace(owner_node, candidate, owner_source_id)

      styles =
        Enum.reduce(candidate.declarations, %{}, fn {property, tagged}, styles ->
          Map.put(styles, property, style_value(tagged, trace, candidate.source_text))
        end)

      override = %ResponsiveOverride{
        breakpoint_id: key,
        source_name: key,
        min_width: candidate.viewport.min_width,
        max_width: candidate.viewport.max_width,
        resolution_status: :resolved,
        styles: styles,
        source_trace: trace
      }

      Map.update!(result, :responsive_by_source_id, fn by_source ->
        Map.update(by_source, node.source_id, %{key => override}, fn current ->
          Map.update(current, key, override, &merge_override(&1, override))
        end)
      end)
    end)
  end

  defp merge_override(existing, incoming),
    do: %{existing | styles: Map.merge(existing.styles, incoming.styles)}

  defp build_state_rules(candidates) do
    candidates
    |> Enum.flat_map(fn candidate ->
      [
        %{
          "condition" => candidate.condition,
          "target_node_id" => candidate.target_node_id,
          "declarations" => candidate.declarations,
          "viewport" =>
            candidate.viewport &&
              %{
                "min_width" => candidate.viewport.min_width,
                "max_width" => candidate.viewport.max_width
              },
          "_source_order" => candidate.source_order,
          "_source_index" => candidate.source_index,
          "_target_path" => candidate.target_path
        }
      ]
    end)
    |> Enum.sort_by(fn rule ->
      condition_order = if rule["condition"] == "hover", do: 0, else: 1
      {rule["_source_index"], rule["_source_order"], condition_order, rule["_target_path"]}
    end)
    |> Enum.with_index()
    |> Enum.map(fn {rule, order} ->
      rule
      |> Map.drop(["_source_order", "_source_index", "_target_path"])
      |> Map.put("order", order)
    end)
  end

  defp sort_state_candidates(candidates), do: candidates

  defp style_value(%{"kind" => "literal", "value" => value}, trace, source_text),
    do: StyleValue.literal(value, source_expression: source_text, source_trace: trace)

  defp style_value(%{"kind" => "keyword", "value" => value}, trace, source_text),
    do: StyleValue.keyword(value, source_expression: source_text, source_trace: trace)

  defp style_value(%{"kind" => "token_ref", "value" => value}, trace, source_text),
    do: StyleValue.token_ref(value, source_expression: source_text, source_trace: trace)

  defp style_value(%{"kind" => "calculation", "value" => value}, trace, source_text),
    do: StyleValue.calculation(value, source_expression: source_text, source_trace: trace)

  defp declaration_trace(owner_node, candidate, owner_source_id) do
    base_trace = Map.get(owner_node, :source_trace) || %SourceTrace{source_id: owner_source_id}

    path =
      custom_css_source_path(
        owner_node,
        owner_source_id,
        candidate.provenance,
        candidate.source_key
      )

    %{
      base_trace
      | source_type: "bricks_style",
        source_id: owner_source_id,
        source_name: candidate.source_key,
        source_path: path,
        inference: "generic custom CSS declaration normalized within its effective owner subtree"
    }
  end

  defp custom_css_trace(owner_node, source_id, source_owners) do
    candidate = List.first(source_owners)
    provenance = Map.get(candidate, :provenance, %{})
    base_trace = Map.get(owner_node, :source_trace) || %SourceTrace{source_id: source_id}
    source_key = Map.get(candidate, :source_key, "_cssCustom")
    path = custom_css_source_path(owner_node, source_id, provenance, source_key)

    %{
      base_trace
      | source_type: "bricks_style",
        source_id: source_id,
        source_name: source_key,
        source_path: path,
        inference: "generic custom CSS normalized to owner-scoped styles and inert state rules"
    }
  end

  defp viewport(nil, nil), do: nil
  defp viewport(min_width, max_width), do: %{min_width: min_width, max_width: max_width}

  defp responsive_key(%{min_width: min_width, max_width: max_width}) do
    case {min_width, max_width} do
      {min, nil} -> "custom_min_" <> canonical_dimension(min)
      {nil, max} -> "custom_max_" <> canonical_dimension(max)
      {min, max} -> "custom_range_" <> canonical_dimension(min) <> "_" <> canonical_dimension(max)
    end
  end

  defp canonical_dimension(number) when is_integer(number), do: Integer.to_string(number)

  defp canonical_dimension(number) when is_float(number) do
    number
    |> :erlang.float_to_binary([:short])
    |> expand_decimal_exponent()
    |> String.replace(".", "p")
  end

  defp expand_decimal_exponent(text) do
    case Regex.run(~r/\A(\d+)(?:\.(\d+))?(?:[eE]([+-]?\d+))?\z/, text) do
      [_, integer, fraction, exponent] when is_binary(fraction) and is_binary(exponent) ->
        decimal_text(integer, fraction, String.to_integer(exponent))

      [_, integer, fraction, nil] ->
        decimal_text(integer, fraction, 0)

      [_, integer, nil, exponent] when is_binary(exponent) ->
        decimal_text(integer, "", String.to_integer(exponent))

      [_, integer, nil, nil] ->
        integer

      [_, integer, fraction] when is_binary(fraction) ->
        decimal_text(integer, fraction, 0)

      [_, integer] ->
        integer
    end
  end

  defp decimal_text(integer, fraction, exponent) do
    digits = integer <> fraction
    decimal_index = byte_size(integer) + exponent

    expanded =
      cond do
        decimal_index <= 0 ->
          "0." <> String.duplicate("0", -decimal_index) <> digits

        decimal_index >= byte_size(digits) ->
          digits <> String.duplicate("0", decimal_index - byte_size(digits))

        true ->
          binary_part(digits, 0, decimal_index) <>
            "." <>
            binary_part(digits, decimal_index, byte_size(digits) - decimal_index)
      end

    expanded
    |> String.trim_trailing("0")
    |> String.trim_trailing(".")
    |> case do
      "" -> "0"
      value -> value
    end
  end

  defp interval_overlap?(left, right) do
    left_min = Map.get(left, :min_width)
    left_max = Map.get(left, :max_width)
    right_min = Map.get(right, :min_width)
    right_max = Map.get(right, :max_width)

    lower = max_bound(left_min, right_min)
    upper = min_bound(left_max, right_max)

    is_nil(lower) or is_nil(upper) or lower <= upper
  end

  defp max_bound(nil, right), do: right
  defp max_bound(left, nil), do: left
  defp max_bound(left, right), do: max(left, right)
  defp min_bound(nil, right), do: right
  defp min_bound(left, nil), do: left
  defp min_bound(left, right), do: min(left, right)

  defp parser_residual(reject, source_index) do
    source_text =
      if Map.get(reject, :reason) == :malformed_framing,
        do: Map.get(reject, :container_raw) || Map.get(reject, :raw, ""),
        else: Map.get(reject, :raw, "")

    source_order = Map.get(reject, :source_order, 0)

    %{
      rule_id: {source_index, source_order},
      source_index: source_index,
      source_order: source_order,
      reason: parser_reason(Map.get(reject, :reason)),
      source_text: source_text
    }
  end

  defp parser_reason(:malformed_framing), do: "malformed_block"
  defp parser_reason(:unclosed_block), do: "malformed_block"
  defp parser_reason(:invalid_declaration), do: "unsupported_declaration"
  defp parser_reason(:duplicate_property), do: "unsupported_declaration"
  defp parser_reason(:invalid_css_property), do: "unsupported_declaration"
  defp parser_reason(:unsafe_css_value), do: "unsafe_declaration"
  defp parser_reason(:invalid_viewport), do: "unsupported_selector"
  defp parser_reason(:unsupported_media_condition), do: "unsupported_selector"
  defp parser_reason(:unsupported_at_rule), do: "unsupported_selector"
  defp parser_reason(:nested_construct), do: "unsupported_selector"
  defp parser_reason(_reason), do: "malformed_block"

  defp custom_css_source_path(owner_node, source_id, provenance, source_key)
       when is_map(provenance) and is_binary(source_key) do
    base_trace = Map.get(owner_node, :source_trace) || %SourceTrace{source_id: source_id}
    base_path = base_trace.source_path || "elements[#{source_id}]"

    case {Map.get(provenance, :origin), Map.get(provenance, :class_reference_index)} do
      {:global_class, index} when is_integer(index) and index >= 0 ->
        "#{base_path}.class_refs[#{index}].settings.#{source_key}"

      {:element_local, nil} ->
        "#{base_path}.settings.#{source_key}"

      _ ->
        nil
    end
  end

  defp custom_css_source_path(_owner_node, _source_id, _provenance, _source_key), do: nil

  defp residual_diagnostics(source_id, residuals, owner_node, source_owners) do
    residuals
    |> Map.values()
    |> Enum.sort_by(&{&1.source_index, &1.source_order})
    |> Enum.map(fn residual ->
      owner = Enum.at(source_owners, residual.source_index)
      provenance = if is_map(owner), do: Map.get(owner, :provenance, %{}), else: %{}
      source_key = if is_map(owner), do: Map.get(owner, :source_key, "_cssCustom"), else: nil

      Diagnostic.new(
        code: "bricks.custom_css.#{residual.reason}",
        severity: :warning,
        source_id: source_id,
        source_path: custom_css_source_path(owner_node, source_id, provenance, source_key),
        raw_value: residual.source_text,
        message: "Generic custom CSS rule was preserved as inert residual evidence",
        metadata: %{"reason" => residual.reason}
      )
    end)
  end

  defp add_unresolved_owner(result, source_id, source_owners) do
    residuals =
      Enum.map(source_owners, fn owner ->
        %{"reason" => "unresolved_target", "source_text" => Map.get(owner, :value, "")}
      end)

    result
    |> Map.update!(:custom_css_by_source_id, &Map.put(&1, source_id, nil))
    |> Map.update!(:residuals_by_source_id, &Map.put(&1, source_id, residuals))
  end

  defp owner_scope(owner_source_id, children_by_source_id) do
    Enum.reduce(
      Map.get(children_by_source_id, owner_source_id, []),
      MapSet.new([owner_source_id]),
      fn child_id, scope ->
        add_descendants(child_id, children_by_source_id, scope)
      end
    )
  end

  defp add_descendants(source_id, children_by_source_id, scope) do
    if MapSet.member?(scope, source_id) do
      scope
    else
      scope = MapSet.put(scope, source_id)

      Enum.reduce(Map.get(children_by_source_id, source_id, []), scope, fn child_id, scope ->
        add_descendants(child_id, children_by_source_id, scope)
      end)
    end
  end

  defp node_path(nodes, source_id), do: Map.get(nodes, source_id, %{}) |> Map.get(:path, [])

  defp non_empty_string?(value), do: is_binary(value) and value != "" and String.valid?(value)
end
