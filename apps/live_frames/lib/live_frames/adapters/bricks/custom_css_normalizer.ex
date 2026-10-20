defmodule LiveFrames.Adapters.Bricks.CustomCssNormalizer do
  @moduledoc false

  alias LiveFrames.Adapters.Bricks.CustomCssParser
  alias LiveFrames.Adapters.Bricks.CompoundCssValue
  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.SourceLocalCustomPropertyResolver
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
  @two_dimension_value ~r/^-?\d+(?:\.\d+)?(?:px|rem|em|vh|vw|fr|deg|%)[ \t\r\n\f]+-?\d+(?:\.\d+)?(?:px|rem|em|vh|vw|fr|deg|%)$/
  @unsafe_value_fragments ["url(", "expression(", "javascript:", "behavior:", "-moz-binding"]
  @max_effective_layer_css_bytes 65_536
  @max_local_definitions 256
  @max_local_references 1_024

  @type owner :: %{
          required(:source_id) => String.t(),
          required(:value) => String.t(),
          required(:provenance) => map(),
          optional(:source_key) => String.t(),
          optional(:viewport_scope) => :base | {:responsive_source_key, String.t()}
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
      responsive_custom_css_by_source_id: %{},
      responsive_source_keys_by_source_id: %{},
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

    {frames, rejects, processed_owners} = collect_frames(source_owners, source_id)

    if frames == [] and map_size(rejects) == 0 do
      result
    else
      normalize_owner_frames(
        source_id,
        source_owners,
        owner_node,
        scope_nodes,
        scope_ids,
        frames,
        rejects,
        processed_owners,
        result,
        opts
      )
    end
  end

  defp normalize_owner_frames(
         source_id,
         source_owners,
         owner_node,
         scope_nodes,
         scope_ids,
         frames,
         rejects,
         processed_owners,
         result,
         opts
       ) do
    {selector_selections, observed_local_names, definitions_by_provenance,
     references_by_provenance, record_limited_provenances, compound_analysis} =
      analyze_local_records(frames, owner_node, scope_nodes, scope_ids, opts)

    {local_resolutions, resolver_limited_provenances} =
      resolve_local_batches(
        source_id,
        observed_local_names,
        definitions_by_provenance,
        references_by_provenance,
        opts,
        record_limited_provenances
      )

    resource_limited_provenances =
      MapSet.union(record_limited_provenances, resolver_limited_provenances)

    residuals =
      resource_failure_residuals(processed_owners, resource_limited_provenances, rejects)

    {base_candidates, responsive_candidates, state_candidates, residuals} =
      Enum.reduce(frames, {[], [], [], residuals}, fn frame_entry,
                                                      {base, responsive, states, residuals} ->
        provenance_identity = effective_provenance_identity(frame_entry.provenance)

        normalized_frame =
          if MapSet.member?(resource_limited_provenances, provenance_identity) do
            :skip
          else
            normalize_frame(
              frame_entry,
              owner_node,
              opts,
              selector_selections,
              observed_local_names,
              local_resolutions,
              compound_analysis
            )
          end

        case normalized_frame do
          {:ok, candidates} ->
            {
              base ++
                Enum.filter(
                  candidates,
                  &(is_nil(&1.viewport) and not is_responsive_source_scope?(&1.viewport_scope) and
                      is_nil(&1.condition))
                ),
              responsive ++
                Enum.filter(
                  candidates,
                  &((not is_nil(&1.viewport) or is_responsive_source_scope?(&1.viewport_scope)) and
                      is_nil(&1.condition))
                ),
              states ++ Enum.filter(candidates, & &1.condition),
              residuals
            }

          {:residual, residual} ->
            {base, responsive, states, Map.put(residuals, residual.rule_id, residual)}

          :skip ->
            {base, responsive, states, residuals}
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
        owner_node,
        source_id,
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

    result =
      add_responsive_source_results(
        result,
        source_id,
        processed_owners,
        residuals,
        source_owners,
        owner_node
      )

    residual_list =
      residuals
      |> Map.values()
      |> Enum.sort_by(&{&1.source_index, &1.source_order})
      |> Enum.map(&%{"reason" => &1.reason, "source_text" => &1.source_text})

    base_source_owners =
      Enum.filter(source_owners, &(Map.get(&1, :viewport_scope, :base) == :base))

    base_residual_list =
      residuals
      |> Map.values()
      |> Enum.filter(fn residual ->
        owner = Enum.at(source_owners, residual.source_index)
        is_map(owner) and Map.get(owner, :viewport_scope, :base) == :base
      end)
      |> Enum.sort_by(&{&1.source_index, &1.source_order})
      |> Enum.map(&%{"reason" => &1.reason, "source_text" => &1.source_text})

    state_rules = build_state_rules(state_candidates)

    source_key =
      case List.first(base_source_owners) do
        nil -> "_cssCustom"
        owner -> Map.get(owner, :source_key, "_cssCustom")
      end

    base_source_expression = Enum.map_join(base_source_owners, "\n", & &1.value)

    custom_css_value =
      cond do
        state_rules != [] ->
          StyleValue.complex_css(
            %{
              "type" => "state_rules",
              "rules" => state_rules,
              "residual" => base_residual_list
            },
            source_expression: base_source_expression,
            source_trace: custom_css_trace(owner_node, source_id, base_source_owners),
            metadata: %{"source_key" => source_key}
          )

        base_residual_list != [] ->
          residual_rules =
            if base_candidates == [] and responsive_candidates == [] do
              Enum.map(base_source_owners, &Map.get(&1, :value))
            else
              Enum.map(base_residual_list, & &1["source_text"])
            end

          StyleValue.complex_css(
            %{
              "type" => "custom_css",
              "property" => "custom-css",
              "source_key" => source_key,
              "rules" => residual_rules
            },
            source_expression: base_source_expression,
            source_trace: custom_css_trace(owner_node, source_id, base_source_owners),
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
    |> Enum.reduce({[], %{}, []}, fn {owner, source_index}, {frames, rejects, processed_owners} ->
      source_text = Map.get(owner, :value)
      provenance = Map.get(owner, :provenance)

      if valid_effective_provenance?(source_id, provenance) and is_binary(source_text) and
           String.valid?(source_text) do
        if byte_size(source_text) > @max_effective_layer_css_bytes do
          residual = %{
            rule_id: {source_index, 0},
            source_index: source_index,
            source_order: 0,
            reason: "resource_limit_exceeded",
            source_text: source_text
          }

          {frames, Map.put(rejects, residual.rule_id, residual),
           processed_owners ++ [{source_index, owner}]}
        else
          parsed = CustomCssParser.parse(source_text)

          source_frames =
            Enum.map(parsed.frames, fn frame ->
              Map.merge(frame, %{
                source_index: source_index,
                source_key: Map.get(owner, :source_key, "_cssCustom"),
                provenance: provenance,
                viewport_scope: Map.get(owner, :viewport_scope, :base),
                aliases: TransientStyleState.resolve_aliases(source_text, provenance)
              })
            end)

          source_rejects =
            Enum.reduce(parsed.rejects, rejects, fn reject, rejects ->
              residual = parser_residual(reject, source_index)
              Map.put(rejects, residual.rule_id, residual)
            end)

          {frames ++ source_frames, source_rejects, processed_owners ++ [{source_index, owner}]}
        end
      else
        residual = %{
          rule_id: {source_index, 0},
          source_index: source_index,
          source_order: 0,
          reason: "unresolved_value",
          source_text: if(is_binary(source_text), do: source_text, else: "")
        }

        {frames, Map.put(rejects, residual.rule_id, residual), processed_owners}
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

  defp analyze_local_records(frames, owner_node, scope_nodes, scope_ids, opts) do
    observed_local_names = observed_local_definition_names(frames)
    compound_analysis = analyze_compound_values(frames)

    {selections_by_rule, record_batches, resource_limited} =
      Enum.reduce(frames, {%{}, %{}, MapSet.new()}, fn frame,
                                                       {selections_by_rule, record_batches,
                                                        resource_limited} ->
        provenance_identity = effective_provenance_identity(frame.provenance)

        if MapSet.member?(resource_limited, provenance_identity) do
          {selections_by_rule, record_batches, resource_limited}
        else
          selection_result =
            resolve_selector(
              frame.selector,
              frame.aliases,
              owner_node,
              scope_nodes,
              scope_ids,
              Keyword.get(opts, :all_source_classes, MapSet.new())
            )

          case selection_result do
            {:ok, selections} ->
              case collect_local_records(
                     frame,
                     selections,
                     provenance_identity,
                     Map.get(observed_local_names, provenance_identity, MapSet.new()),
                     compound_analysis,
                     record_batches,
                     resource_limited
                   ) do
                {:ok, record_batches, resource_limited} ->
                  {
                    Map.put(selections_by_rule, frame_rule_id(frame), selection_result),
                    record_batches,
                    resource_limited
                  }

                {:overflow, record_batches, resource_limited} ->
                  {selections_by_rule, record_batches, resource_limited}
              end

            {:error, _reason} ->
              {
                Map.put(selections_by_rule, frame_rule_id(frame), selection_result),
                record_batches,
                resource_limited
              }
          end
        end
      end)

    {definitions_by_provenance, references_by_provenance} =
      finalize_local_record_batches(record_batches)

    {selections_by_rule, observed_local_names, definitions_by_provenance,
     references_by_provenance, resource_limited, compound_analysis}
  end

  defp analyze_compound_values(frames) do
    Enum.reduce(frames, %{}, fn frame, analysis ->
      Enum.reduce(frame.declarations, analysis, fn {property, value}, analysis ->
        if local_definition_name?(property) do
          analysis
        else
          route = compound_route(value)
          Map.put(analysis, {frame_rule_id(frame), property}, route)
        end
      end)
    end)
  end

  defp compound_route(value) when is_binary(value) do
    trimmed = String.trim(value)
    lowered = String.downcase(trimmed)

    cond do
      local_name = direct_variable_name(trimmed) ->
        {:direct_reference, local_name}

      Regex.match?(@two_dimension_value, trimmed) ->
        compound_analysis(trimmed)

      String.contains?(lowered, "var(") or String.contains?(lowered, "calc(") ->
        compound_analysis(trimmed)

      true ->
        :generic
    end
  end

  defp compound_route(_value), do: :generic

  defp compound_analysis(value) do
    case CompoundCssValue.parse(value) do
      {:ok, parsed} -> {:compound, {:ok, parsed, CompoundCssValue.occurrences(parsed)}}
      result -> {:compound, result}
    end
  end

  defp observed_local_definition_names(frames) do
    Enum.reduce(frames, %{}, fn frame, observed ->
      local_names =
        frame.declarations
        |> Map.keys()
        |> Enum.filter(&local_definition_name?/1)

      if local_names == [] do
        observed
      else
        Map.update(
          observed,
          effective_provenance_identity(frame.provenance),
          MapSet.new(local_names),
          fn names -> Enum.reduce(local_names, names, &MapSet.put(&2, &1)) end
        )
      end
    end)
  end

  defp collect_local_records(
         frame,
         selections,
         provenance_identity,
         observed_local_names,
         compound_analysis,
         record_batches,
         resource_limited
       ) do
    Enum.reduce_while(selections, {:ok, record_batches, resource_limited}, fn selection,
                                                                              {:ok, batches,
                                                                               limited} ->
      case collect_selection_local_records(
             frame,
             selection,
             provenance_identity,
             observed_local_names,
             compound_analysis,
             batches,
             limited
           ) do
        {:ok, batches, limited} -> {:cont, {:ok, batches, limited}}
        {:overflow, batches, limited} -> {:halt, {:overflow, batches, limited}}
      end
    end)
  end

  defp collect_selection_local_records(
         frame,
         selection,
         provenance_identity,
         observed_local_names,
         compound_analysis,
         record_batches,
         resource_limited
       ) do
    Enum.reduce_while(selection.targets, {:ok, record_batches, resource_limited}, fn target,
                                                                                     {:ok,
                                                                                      batches,
                                                                                      limited} ->
      case collect_target_local_records(
             frame,
             selection,
             target,
             provenance_identity,
             observed_local_names,
             compound_analysis,
             batches,
             limited
           ) do
        {:ok, batches, limited} -> {:cont, {:ok, batches, limited}}
        {:overflow, batches, limited} -> {:halt, {:overflow, batches, limited}}
      end
    end)
  end

  defp collect_target_local_records(
         frame,
         selection,
         target,
         provenance_identity,
         observed_local_names,
         compound_analysis,
         record_batches,
         resource_limited
       ) do
    Enum.reduce_while(frame.declarations, {:ok, record_batches, resource_limited}, fn
      {property, value}, {:ok, batches, limited} ->
        cond do
          local_definition_name?(property) and resolver_definition_scope?(frame, selection) ->
            append_local_record(
              :definition,
              frame,
              selection,
              target,
              property,
              value,
              nil,
              provenance_identity,
              batches,
              limited
            )

          local_definition_name?(property) ->
            {:ok, batches, limited}

          true ->
            route = Map.get(compound_analysis, {frame_rule_id(frame), property}, :generic)

            case route do
              {:compound, {:ok, _parsed, occurrences}} ->
                Enum.reduce_while(occurrences, {:ok, batches, limited}, fn occurrence,
                                                                           {:ok, current,
                                                                            current_limited} ->
                  local_name = occurrence.local_name

                  reference_id =
                    {frame_rule_id(frame), target.source_id, selection.selector_identity,
                     property, occurrence.occurrence_index}

                  case append_local_record(
                         :reference,
                         frame,
                         selection,
                         target,
                         local_name,
                         nil,
                         reference_id,
                         provenance_identity,
                         current,
                         current_limited
                       ) do
                    {:ok, next, next_limited} -> {:cont, {:ok, next, next_limited}}
                    {:overflow, next, next_limited} -> {:halt, {:overflow, next, next_limited}}
                  end
                end)

              {:compound, _failed_parse} ->
                {:ok, batches, limited}

              {:direct_reference, local_name} ->
                if MapSet.member?(observed_local_names, local_name) do
                  reference_id =
                    {frame_rule_id(frame), target.source_id, selection.selector_identity,
                     property}

                  append_local_record(
                    :reference,
                    frame,
                    selection,
                    target,
                    local_name,
                    nil,
                    reference_id,
                    provenance_identity,
                    batches,
                    limited
                  )
                else
                  {:ok, batches, limited}
                end

              :generic ->
                {:ok, batches, limited}
            end
        end
        |> case do
          {:ok, batches, limited} -> {:cont, {:ok, batches, limited}}
          {:overflow, batches, limited} -> {:halt, {:overflow, batches, limited}}
        end
    end)
  end

  defp resolver_definition_scope?(frame, selection) do
    is_nil(frame.min_width) and is_nil(frame.max_width) and is_nil(selection.condition)
  end

  defp append_local_record(
         kind,
         frame,
         selection,
         target,
         local_name,
         terminal_text,
         reference_id,
         provenance_identity,
         record_batches,
         resource_limited
       ) do
    batch =
      Map.get(record_batches, provenance_identity, %{
        definitions: [],
        definition_count: 0,
        references: [],
        reference_count: 0
      })

    count_key = if kind == :definition, do: :definition_count, else: :reference_count
    limit = if kind == :definition, do: @max_local_definitions, else: @max_local_references

    if Map.fetch!(batch, count_key) >= limit do
      {:overflow, Map.delete(record_batches, provenance_identity),
       MapSet.put(resource_limited, provenance_identity)}
    else
      record =
        local_record(
          kind,
          frame,
          selection,
          target,
          local_name,
          terminal_text,
          provenance_identity
        )

      updated_batch =
        case kind do
          :definition ->
            %{
              batch
              | definitions: [record | batch.definitions],
                definition_count: batch.definition_count + 1
            }

          :reference ->
            reference = {reference_id, record}

            %{
              batch
              | references: [reference | batch.references],
                reference_count: batch.reference_count + 1
            }
        end

      {:ok, Map.put(record_batches, provenance_identity, updated_batch), resource_limited}
    end
  end

  defp finalize_local_record_batches(record_batches) do
    Enum.reduce(record_batches, {%{}, %{}}, fn {provenance_identity, batch},
                                               {definitions, references} ->
      {
        Map.put(definitions, provenance_identity, Enum.reverse(batch.definitions)),
        Map.put(references, provenance_identity, Enum.reverse(batch.references))
      }
    end)
  end

  defp local_record(
         kind,
         frame,
         selection,
         target,
         local_name,
         terminal_text,
         provenance_identity
       ) do
    record = %{
      owner_source_id: Map.get(frame.provenance, :source_id),
      effective_provenance_identity: provenance_identity,
      target_source_id: target.source_id,
      target_path: target.path,
      selector_identity: selection.selector_identity,
      viewport_scope: frame.viewport_scope,
      state_scope: selection.condition,
      source_order: {frame.source_index, frame.source_order},
      local_name: local_name,
      record_kind: kind
    }

    if kind == :definition,
      do: Map.put(record, :terminal_text_if_definition, terminal_text),
      else: record
  end

  defp resolve_local_batches(
         owner_source_id,
         observed_local_names,
         definitions_by_provenance,
         references_by_provenance,
         opts,
         pre_limited_provenances
       ) do
    batch_identities =
      (Map.keys(observed_local_names) ++
         Map.keys(definitions_by_provenance) ++
         Map.keys(references_by_provenance))
      |> Enum.uniq()

    Enum.reduce(batch_identities, {%{}, pre_limited_provenances}, fn provenance_identity,
                                                                     {resolutions,
                                                                      resource_limited} ->
      if MapSet.member?(resource_limited, provenance_identity) do
        {resolutions, resource_limited}
      else
        local_names = Map.get(observed_local_names, provenance_identity, MapSet.new())
        definitions = Map.get(definitions_by_provenance, provenance_identity, [])

        references =
          references_by_provenance
          |> Map.get(provenance_identity, [])
          |> Enum.filter(fn {reference_id, record} ->
            retain_local_reference?(reference_id, record, local_names)
          end)

        reference_records = Enum.map(references, &elem(&1, 1))

        case SourceLocalCustomPropertyResolver.resolve(definitions, reference_records,
               owner_source_id: owner_source_id,
               effective_provenance_identity: provenance_identity,
               authority_index: Keyword.get(opts, :authority_index, %VariableAuthority{})
             ) do
          {:ok, reference_results} when length(reference_results) == length(references) ->
            next_resolutions =
              Enum.zip(references, reference_results)
              |> Enum.reduce(resolutions, fn {{reference_id, _record}, resolution}, resolutions ->
                Map.put(resolutions, {provenance_identity, reference_id}, resolution)
              end)

            {next_resolutions, resource_limited}

          {:ok, _reference_results} ->
            failed_resolutions =
              Enum.reduce(references, resolutions, fn {reference_id, _record}, resolutions ->
                Map.put(
                  resolutions,
                  {provenance_identity, reference_id},
                  {:error, :result_count_mismatch}
                )
              end)

            {failed_resolutions, resource_limited}

          {:error, :resource_limit_exceeded} ->
            {resolutions, MapSet.put(resource_limited, provenance_identity)}
        end
      end
    end)
  end

  defp retain_local_reference?(
         {_rule_id, _target_source_id, _selector_identity, _property, _occurrence_index},
         _record,
         _local_names
       ),
       do: true

  defp retain_local_reference?(_reference_id, record, local_names),
    do: MapSet.member?(local_names, Map.get(record, :local_name))

  defp effective_provenance_identity(provenance) do
    {
      Map.get(provenance, :source_id),
      Map.get(provenance, :origin),
      Map.get(provenance, :class_id),
      Map.get(provenance, :resolution_source),
      Map.get(provenance, :authority_ids),
      Map.get(provenance, :class_reference_index)
    }
  end

  defp local_definition_name?(property) when is_binary(property),
    do: CSSDeclaration.safe_property?(property) and String.starts_with?(property, "--")

  defp local_definition_name?(_property), do: false

  defp direct_variable_name(value) when is_binary(value) do
    case Regex.run(@direct_variable_expression, String.trim(value)) do
      [_, local_name] -> local_name
      _ -> nil
    end
  end

  defp direct_variable_name(_value), do: nil

  defp consumable_local_definition_compiler_input?(frame, selection, property, value)
       when is_binary(property) and is_binary(value) do
    resolver_definition_scope?(frame, selection) and
      SourceLocalCustomPropertyResolver.definition_compiler_input_state(property, value) == :ok
  end

  defp consumable_local_definition_compiler_input?(_frame, _selection, _property, _value),
    do: false

  defp frame_rule_id(frame), do: {frame.source_index, frame.source_order}

  defp residual_for(frame, reason) do
    %{
      rule_id: frame_rule_id(frame),
      source_index: frame.source_index,
      source_order: frame.source_order,
      reason: reason,
      source_text: frame.raw
    }
  end

  defp normalize_frame(
         frame,
         owner_node,
         opts,
         selections_by_rule,
         observed_local_names,
         local_resolutions,
         compound_analysis
       ) do
    rule_id = {frame.source_index, frame.source_order}

    case Map.get(selections_by_rule, rule_id) do
      {:error, reason} ->
        {:residual, residual_for(frame, reason)}

      {:ok, selections} ->
        viewport = viewport(frame.min_width, frame.max_width)

        cond do
          not valid_viewport_scope?(frame.viewport_scope) ->
            {:residual, residual_for(frame, "unsupported_scope")}

          unsupported_local_definition_scope?(frame, selections) ->
            {:residual, residual_for(frame, "unsupported_scope")}

          is_responsive_source_scope?(frame.viewport_scope) and not is_nil(viewport) ->
            {:residual, residual_for(frame, "unsupported_scope")}

          is_responsive_source_scope?(frame.viewport_scope) and
              Enum.any?(selections, &(not is_nil(&1.condition))) ->
            {:residual, residual_for(frame, "unsupported_scope")}

          true ->
            normalize_frame_targets(
              frame,
              selections,
              viewport,
              owner_node,
              opts,
              observed_local_names,
              local_resolutions,
              compound_analysis
            )
        end
    end
  end

  defp unsupported_local_definition_scope?(frame, selections) do
    has_local_definition? =
      Enum.any?(frame.declarations, fn {property, _value} -> local_definition_name?(property) end)

    has_local_definition? and
      (is_responsive_source_scope?(frame.viewport_scope) or
         not is_nil(frame.min_width) or not is_nil(frame.max_width) or
         Enum.any?(selections, &(not is_nil(&1.condition))))
  end

  defp normalize_frame_targets(
         frame,
         selections,
         viewport,
         owner_node,
         opts,
         observed_local_names,
         local_resolutions,
         compound_analysis
       ) do
    provenance_identity = effective_provenance_identity(frame.provenance)

    selections
    |> Enum.reduce_while({:ok, []}, fn selection, {:ok, candidates} ->
      Enum.reduce_while(selection.targets, {:ok, candidates}, fn target, {:ok, candidates} ->
        case normalize_declarations_for_target(
               frame,
               selection,
               target,
               opts,
               Map.get(observed_local_names, provenance_identity, MapSet.new()),
               local_resolutions,
               compound_analysis
             ) do
          {:error, reason} ->
            {:halt, {:error, reason}}

          {:ok, declarations} when map_size(declarations) == 0 ->
            {:cont, {:ok, candidates}}

          {:ok, declarations} ->
            candidate = %{
              rule_id: frame_rule_id(frame),
              source_index: frame.source_index,
              source_order: frame.source_order,
              target_source_id: target.source_id,
              target_node_id: target.node_id,
              target_path: target.path,
              declarations: declarations,
              viewport: viewport,
              viewport_scope: frame.viewport_scope,
              condition: selection.condition,
              source_text: frame.raw,
              source_key: frame.source_key,
              provenance: frame.provenance,
              owner_source_id: owner_node.source_id
            }

            {:cont, {:ok, candidates ++ [candidate]}}
        end
      end)
      |> case do
        {:ok, candidates} -> {:cont, {:ok, candidates}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, candidates} -> {:ok, candidates}
      {:error, reason} -> {:residual, residual_for(frame, reason)}
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
            condition: condition,
            selector_identity: selector_identity(compounds, condition)
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

  defp selector_identity(compounds, condition) do
    compounds =
      Enum.map(compounds, fn compound ->
        {compound.classes |> Enum.uniq() |> Enum.sort(), compound.marker}
      end)

    {compounds, condition}
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

  defp normalize_declarations_for_target(
         frame,
         selection,
         target,
         opts,
         observed_local_names,
         local_resolutions,
         compound_analysis
       ) do
    provenance_identity = effective_provenance_identity(frame.provenance)

    declarations = frame.declarations

    declarations
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.reduce_while({:ok, %{}}, fn {property, value}, {:ok, normalized} ->
      cond do
        local_definition_name?(property) and
            consumable_local_definition_compiler_input?(frame, selection, property, value) ->
          {:cont, {:ok, normalized}}

        local_definition_name?(property) ->
          {:halt, {:error, "unresolved_value"}}

        true ->
          case normalize_target_declaration(
                 frame,
                 selection,
                 target,
                 property,
                 value,
                 provenance_identity,
                 opts,
                 observed_local_names,
                 local_resolutions,
                 compound_analysis
               ) do
            {:ok, tagged} -> {:cont, {:ok, Map.put(normalized, property, tagged)}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
      end
    end)
  end

  defp normalize_target_declaration(
         frame,
         selection,
         target,
         property,
         value,
         provenance_identity,
         opts,
         observed_local_names,
         local_resolutions,
         compound_analysis
       ) do
    case Map.get(compound_analysis, {frame_rule_id(frame), property}, :generic) do
      {:compound, {:error, :resource_limit_exceeded}} ->
        {:error, "resource_limit_exceeded"}

      {:compound, {:ok, parsed, occurrences}} ->
        terminals =
          Enum.reduce_while(occurrences, {:ok, %{}}, fn occurrence, {:ok, terminals} ->
            reference_id =
              {frame_rule_id(frame), target.source_id, selection.selector_identity, property,
               occurrence.occurrence_index}

            case Map.get(local_resolutions, {provenance_identity, reference_id}) do
              {:ok, terminal} when is_binary(terminal) ->
                {:cont, {:ok, Map.put(terminals, occurrence.occurrence_index, terminal)}}

              _closed_result ->
                {:halt, :error}
            end
          end)

        with {:ok, terminals} <- terminals,
             {:ok, reconstructed} <- CompoundCssValue.reconstruct(parsed, terminals),
             {:ok, safe_value} <-
               safe_declaration_value(property, reconstructed, :source_resolver) do
          {:ok, %{"kind" => "literal", "value" => safe_value}}
        else
          {:error, "unsafe_declaration"} -> {:error, "unsafe_declaration"}
          {:error, "unsupported_declaration"} -> {:error, "unsupported_declaration"}
          {:error, :resource_limit_exceeded} -> {:error, "resource_limit_exceeded"}
          _closed_result -> {:error, "unresolved_value"}
        end

      {:compound, _closed_parse_result} ->
        {:error, "unresolved_value"}

      route when route == :generic ->
        normalize_direct_or_generic_target(
          frame,
          selection,
          target,
          property,
          value,
          provenance_identity,
          opts,
          observed_local_names,
          local_resolutions,
          route
        )

      {:direct_reference, _local_name} = route ->
        normalize_direct_or_generic_target(
          frame,
          selection,
          target,
          property,
          value,
          provenance_identity,
          opts,
          observed_local_names,
          local_resolutions,
          route
        )
    end
  end

  defp normalize_direct_or_generic_target(
         frame,
         selection,
         target,
         property,
         value,
         provenance_identity,
         opts,
         observed_local_names,
         local_resolutions,
         route
       ) do
    local_name =
      case route do
        {:direct_reference, name} -> name
        :generic -> nil
      end

    case local_name do
      nil ->
        normalize_declaration(property, value, opts)

      local_name when is_struct(observed_local_names, MapSet) ->
        if MapSet.member?(observed_local_names, local_name) do
          reference_id =
            {frame_rule_id(frame), target.source_id, selection.selector_identity, property}

          case Map.get(local_resolutions, {provenance_identity, reference_id}) do
            {:ok, terminal_text} ->
              normalize_declaration(property, terminal_text, opts, :source_resolver)

            _resolution_error ->
              {:error, "unresolved_value"}
          end
        else
          normalize_declaration(property, value, opts)
        end
    end
  end

  defp normalize_declaration(property, value, opts),
    do: normalize_declaration(property, value, opts, :ir)

  defp normalize_declaration(property, value, opts, origin)
       when is_binary(property) and is_binary(value) do
    with {:ok, safe_value} <- safe_declaration_value(property, value, origin) do
      normalize_declaration_value(property, safe_value, opts)
    end
  end

  defp normalize_declaration(_property, _value, _opts, _origin),
    do: {:error, "unsupported_declaration"}

  defp safe_declaration_value(property, value, origin)
       when is_binary(property) and is_binary(value) do
    lowered = String.downcase(value)

    cond do
      Enum.any?(@unsafe_value_fragments, &String.contains?(lowered, &1)) ->
        {:error, "unsafe_declaration"}

      not CSSDeclaration.safe_property?(property) or property == "custom-css" ->
        {:error, "unsupported_declaration"}

      not match?(
        {:ok, _},
        CSSDeclaration.normalize(%{property: property, value: value}, origin)
      ) ->
        {:error, "unsafe_declaration"}

      true ->
        {:ok, String.trim(value)}
    end
  end

  defp safe_declaration_value(_property, _value, _origin),
    do: {:error, "unsupported_declaration"}

  defp resource_failure_residuals(processed_owners, resource_limited_provenances, rejects) do
    failed_owners =
      Enum.filter(processed_owners, fn {_source_index, owner} ->
        MapSet.member?(
          resource_limited_provenances,
          effective_provenance_identity(Map.get(owner, :provenance))
        )
      end)

    failed_source_indexes = MapSet.new(failed_owners, &elem(&1, 0))

    rejects =
      rejects
      |> Enum.reject(fn {_rule_id, residual} ->
        MapSet.member?(failed_source_indexes, residual.source_index)
      end)
      |> Map.new()

    Enum.reduce(failed_owners, rejects, fn {source_index, owner}, residuals ->
      residual = %{
        rule_id: {source_index, -1},
        source_index: source_index,
        source_order: -1,
        reason: "resource_limit_exceeded",
        source_text: Map.get(owner, :value)
      }

      Map.put(residuals, residual.rule_id, residual)
    end)
  end

  defp add_responsive_source_results(
         result,
         source_id,
         processed_owners,
         residuals,
         source_owners,
         owner_node
       ) do
    responsive_owners =
      processed_owners
      |> Enum.filter(fn {_source_index, owner} ->
        is_responsive_source_scope?(Map.get(owner, :viewport_scope))
      end)
      |> Enum.map(&elem(&1, 1))

    source_keys =
      responsive_owners
      |> Enum.map(&Map.get(&1, :source_key, "_cssCustom"))
      |> MapSet.new()

    residual_custom_css =
      residuals
      |> Map.values()
      |> Enum.reduce(%{}, fn residual, by_source_key ->
        owner = Enum.at(source_owners, residual.source_index)

        if is_map(owner) and is_responsive_source_scope?(Map.get(owner, :viewport_scope)) do
          source_key = Map.get(owner, :source_key, "_cssCustom")

          Map.update(by_source_key, source_key, [residual.source_text], fn rules ->
            rules ++ [residual.source_text]
          end)
        else
          by_source_key
        end
      end)
      |> Map.new(fn {source_key, rules} ->
        owner =
          Enum.find(source_owners, fn owner ->
            Map.get(owner, :source_key, "_cssCustom") == source_key and
              is_responsive_source_scope?(Map.get(owner, :viewport_scope))
          end)

        {source_key,
         StyleValue.complex_css(
           %{
             "type" => "custom_css",
             "property" => "custom-css",
             "source_key" => source_key,
             "rules" => rules
           },
           source_expression: owner.value,
           source_trace:
             responsive_custom_css_trace(owner_node, source_key) ||
               custom_css_trace(owner_node, source_id, [owner]),
           metadata: %{"source_key" => source_key}
         )}
      end)

    result
    |> Map.update!(:responsive_source_keys_by_source_id, &Map.put(&1, source_id, source_keys))
    |> Map.update!(
      :responsive_custom_css_by_source_id,
      &Map.put(&1, source_id, residual_custom_css)
    )
  end

  defp valid_viewport_scope?(:base), do: true

  defp valid_viewport_scope?({:responsive_source_key, source_key}),
    do: non_empty_string?(source_key)

  defp valid_viewport_scope?(_viewport_scope), do: false

  defp is_responsive_source_scope?({:responsive_source_key, source_key}),
    do: is_binary(source_key)

  defp is_responsive_source_scope?(_viewport_scope), do: false

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

  defp responsive_candidate_key(candidate, owner_node) do
    if is_responsive_source_scope?(candidate.viewport_scope) do
      case matching_source_custom_css_override(owner_node, candidate.source_key) do
        {key, _override} -> key
        nil -> nil
      end
    else
      responsive_key(candidate.viewport)
    end
  end

  defp matching_source_custom_css_override(node, source_key) do
    node
    |> Map.get(:responsive, %{})
    |> Enum.find(fn {_key, override} ->
      custom_css_source_key(override) == source_key
    end)
  end

  defp custom_css_source_key(override) do
    case Map.get(Map.get(override, :styles, %{}), "custom-css") do
      %StyleValue{metadata: metadata} -> Map.get(metadata, "source_key")
      _style -> nil
    end
  end

  defp responsive_custom_css_trace(node, source_key) do
    case matching_source_custom_css_override(node, source_key) do
      {_key, override} ->
        case Map.get(Map.get(override, :styles, %{}), "custom-css") do
          %StyleValue{source_trace: %SourceTrace{} = source_trace} -> source_trace
          _style -> nil
        end

      nil ->
        nil
    end
  end

  defp responsive_candidates_overlap?(left, right) do
    cond do
      is_responsive_source_scope?(left.viewport_scope) or
          is_responsive_source_scope?(right.viewport_scope) ->
        left.viewport_scope == right.viewport_scope

      true ->
        interval_overlap?(left.viewport, right.viewport)
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

  defp preflight_responsive(candidates, residuals, scope_nodes, owner_node, owner_source_id, opts) do
    key_collisions =
      Enum.flat_map(candidates, fn candidate ->
        node = Map.fetch!(scope_nodes, candidate.target_source_id)
        source_scoped? = is_responsive_source_scope?(candidate.viewport_scope)
        owner_authority = matching_source_custom_css_override(owner_node, candidate.source_key)
        target_source_override = matching_source_custom_css_override(node, candidate.source_key)
        key = responsive_candidate_key(candidate, owner_node)
        target_override = if is_binary(key), do: Map.get(Map.get(node, :responsive, %{}), key)

        existing_key? =
          not source_scoped? and Map.has_key?(Map.get(node, :responsive, %{}), key) and
            is_nil(target_source_override)

        existing_property_collision? =
          if source_scoped? do
            existing_styles = Map.get(target_override || %{}, :styles, %{})

            existing_styles =
              if node.source_id == owner_source_id,
                do: Map.delete(existing_styles, "custom-css"),
                else: existing_styles

            Enum.any?(candidate.declarations, fn {property, _tagged} ->
              Map.has_key?(existing_styles, property)
            end)
          else
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
          end

        custom_key? =
          is_binary(key) and
            opts
            |> Keyword.get(:existing_custom_responsive_keys, %{})
            |> Map.get(candidate.target_source_id, MapSet.new())
            |> MapSet.member?(key)

        cond do
          source_scoped? and is_nil(owner_authority) ->
            [{candidate.rule_id, "unsupported_scope"}]

          existing_key? or existing_property_collision? or custom_key? ->
            [{candidate.rule_id, "responsive_collision"}]

          true ->
            []
        end
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
             responsive_candidates_overlap?(left, right) do
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
            prior.viewport_scope == candidate.viewport_scope and
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
      key = responsive_candidate_key(candidate, owner_node)
      trace = declaration_trace(owner_node, candidate, owner_source_id)

      styles =
        Enum.reduce(candidate.declarations, %{}, fn {property, tagged}, styles ->
          Map.put(styles, property, style_value(tagged, trace, candidate.source_text))
        end)

      override =
        responsive_output_override(
          candidate,
          node,
          owner_node,
          owner_source_id,
          key,
          styles,
          trace
        )

      Map.update!(result, :responsive_by_source_id, fn by_source ->
        Map.update(by_source, node.source_id, %{key => override}, fn current ->
          Map.update(current, key, override, &merge_override(&1, override))
        end)
      end)
    end)
  end

  defp responsive_output_override(
         %{viewport_scope: {:responsive_source_key, source_key}},
         target_node,
         owner_node,
         owner_source_id,
         key,
         styles,
         trace
       ) do
    {_authority_key, authority} = matching_source_custom_css_override(owner_node, source_key)

    existing_styles =
      case Map.get(Map.get(target_node, :responsive, %{}), key) do
        %ResponsiveOverride{styles: existing_styles} -> existing_styles
        _missing_target_override -> %{}
      end

    existing_styles =
      if target_node.source_id == owner_source_id,
        do: Map.delete(existing_styles, "custom-css"),
        else: existing_styles

    %{authority | styles: Map.merge(existing_styles, styles), source_trace: trace}
  end

  defp responsive_output_override(
         candidate,
         target_node,
         _owner_node,
         _owner_source_id,
         key,
         styles,
         trace
       ) do
    case matching_source_custom_css_override(target_node, candidate.source_key) do
      {^key, existing} ->
        %{
          existing
          | resolution_status: if(is_nil(candidate.viewport), do: :unresolved, else: :resolved),
            styles: Map.merge(Map.delete(Map.get(existing, :styles, %{}), "custom-css"), styles),
            source_trace: trace
        }

      _no_source_override ->
        %ResponsiveOverride{
          breakpoint_id: key,
          source_name: key,
          min_width: candidate.viewport && candidate.viewport.min_width,
          max_width: candidate.viewport && candidate.viewport.max_width,
          resolution_status: if(is_nil(candidate.viewport), do: :unresolved, else: :resolved),
          styles: styles,
          source_trace: trace
        }
    end
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

    case String.split(expanded, ".", parts: 2) do
      [whole, fraction] ->
        fraction = String.trim_trailing(fraction, "0")
        if fraction == "", do: whole, else: whole <> "." <> fraction

      [whole] ->
        whole
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
    |> Enum.reject(fn residual ->
      owner = Enum.at(source_owners, residual.source_index)
      duplicate_responsive_residual?(owner_node, owner, residual)
    end)
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

  defp duplicate_responsive_residual?(owner_node, owner, residual) when is_map(owner) do
    case Map.get(owner, :viewport_scope) do
      {:responsive_source_key, source_key} when is_binary(source_key) ->
        source_text = Map.get(owner, :value)

        if Map.get(residual, :reason) == "unsupported_selector" and
             is_binary(source_text) and Map.get(residual, :source_text) == source_text do
          case matching_source_custom_css_override(owner_node, source_key) do
            {_breakpoint, override} ->
              case Map.get(Map.get(override, :styles, %{}), "custom-css") do
                %StyleValue{source_expression: ^source_text} -> true
                _style -> false
              end

            nil ->
              false
          end
        else
          false
        end

      _scope ->
        false
    end
  end

  defp duplicate_responsive_residual?(_owner_node, _owner, _residual), do: false

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
