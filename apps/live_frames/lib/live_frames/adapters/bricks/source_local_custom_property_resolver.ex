defmodule LiveFrames.Adapters.Bricks.SourceLocalCustomPropertyResolver do
  @moduledoc false

  alias LiveFrames.Fidelity.CSSDeclaration
  alias LiveFrames.Tokens.VariableAuthority

  @max_definitions 256
  @max_references 1_024
  @max_ancestry_hops 64
  @max_terminal_bytes 4_096
  @max_dependency_edges 1_024
  @var_spellings ["var(", "vAr(", "vaR(", "vAR(", "Var(", "VAr(", "VaR(", "VAR("]

  @spec resolve([map()], [map()], keyword()) ::
          {:ok, [{:ok, binary()} | {:error, atom()}]} | {:error, :resource_limit_exceeded}
  def resolve(definition_records, reference_records, opts)
      when is_list(definition_records) and is_list(reference_records) and is_list(opts) do
    owner_source_id = Keyword.fetch!(opts, :owner_source_id)
    effective_provenance_identity = Keyword.fetch!(opts, :effective_provenance_identity)
    authority_index = Keyword.fetch!(opts, :authority_index)

    if within_limit?(definition_records, @max_definitions) and
         within_limit?(reference_records, @max_references) do
      if foreign_owner_record?(definition_records, owner_source_id) or
           foreign_owner_record?(reference_records, owner_source_id) do
        {:ok, Enum.map(reference_records, fn _reference -> {:error, :cross_owner_reference} end)}
      else
        index_result =
          build_definition_index(
            definition_records,
            owner_source_id,
            effective_provenance_identity,
            authority_index
          )

        case index_result do
          {:error, :resource_limit_exceeded} ->
            {:error, :resource_limit_exceeded}

          {:ok, definition_index} ->
            results =
              Enum.map(reference_records, fn reference_record ->
                resolve_reference(
                  reference_record,
                  definition_index,
                  owner_source_id,
                  effective_provenance_identity
                )
              end)

            {:ok, results}
        end
      end
    else
      {:error, :resource_limit_exceeded}
    end
  end

  def resolve(_definition_records, _reference_records, _opts),
    do: {:error, :resource_limit_exceeded}

  defp within_limit?(records, limit), do: within_limit?(records, limit, 0)

  defp within_limit?(_records, limit, count) when count > limit, do: false
  defp within_limit?([], _limit, _count), do: true
  defp within_limit?([_record | rest], limit, count), do: within_limit?(rest, limit, count + 1)

  defp foreign_owner_record?(records, owner_source_id) do
    Enum.any?(records, fn
      record when is_map(record) -> Map.get(record, :owner_source_id) !== owner_source_id
      _record -> true
    end)
  end

  defp build_definition_index(records, owner_source_id, provenance_identity, authority_index) do
    with :ok <- dependency_edge_limit(records, owner_source_id, provenance_identity) do
      do_build_definition_index(records, owner_source_id, provenance_identity, authority_index)
    end
  end

  defp do_build_definition_index(records, owner_source_id, provenance_identity, authority_index) do
    {definitions_by_path, tries_by_name} =
      Enum.reduce(records, {%{}, %{}}, fn record, {definitions_by_path, tries_by_name} ->
        local_name = Map.get(record, :local_name)
        target_path = Map.get(record, :target_path)
        viewport_scope = Map.get(record, :viewport_scope)
        state_scope = Map.get(record, :state_scope)

        if eligible_definition?(
             record,
             local_name,
             target_path,
             owner_source_id,
             provenance_identity
           ) do
          reversed_path = Enum.reverse(target_path)
          scope = {viewport_scope, state_scope}

          {
            Map.update(
              definitions_by_path,
              {local_name, reversed_path, scope},
              [record],
              &[record | &1]
            ),
            Map.update(
              tries_by_name,
              local_name,
              insert_path(empty_path_trie(), target_path, scope),
              &insert_path(&1, target_path, scope)
            )
          }
        else
          {definitions_by_path, tries_by_name}
        end
      end)

    selected_by_path_scope =
      Map.new(definitions_by_path, fn {key, definitions} ->
        {key, select_definition(definitions)}
      end)

    selected_by_path =
      Enum.reduce(selected_by_path_scope, %{}, fn
        {{local_name, reversed_path, scope}, selection}, by_path ->
          Map.update(
            by_path,
            {local_name, reversed_path},
            %{scope => selection},
            &Map.put(&1, scope, selection)
          )
      end)

    local_names = selected_by_path_scope |> Map.keys() |> Enum.map(&elem(&1, 0)) |> Enum.uniq()

    external_collisions =
      local_names
      |> Enum.filter(&external_candidate?(authority_index, &1))
      |> MapSet.new()

    with {:ok, dependency_states} <- build_dependency_states(selected_by_path_scope) do
      {:ok,
       %{
         by_name_and_path: selected_by_path,
         tries_by_name: tries_by_name,
         external_collisions: external_collisions,
         dependency_states: dependency_states
       }}
    end
  end

  defp dependency_edge_limit(records, owner_source_id, provenance_identity) do
    Enum.reduce_while(records, {:ok, 0}, fn record, {:ok, edge_count} ->
      local_name = Map.get(record, :local_name)
      target_path = Map.get(record, :target_path)
      terminal = Map.get(record, :terminal_text)

      if eligible_definition?(
           record,
           local_name,
           target_path,
           owner_source_id,
           provenance_identity
         ) and is_binary(terminal) and byte_size(terminal) <= @max_terminal_bytes do
        remaining_edges = @max_dependency_edges - edge_count

        case dependency_calls(terminal, remaining_edges + 1) do
          :limit -> {:halt, {:error, :resource_limit_exceeded}}
          {:ok, names, _fallback?} -> {:cont, {:ok, edge_count + length(names)}}
        end
      else
        {:cont, {:ok, edge_count}}
      end
    end)
    |> case do
      {:ok, edge_count} when edge_count <= @max_dependency_edges -> :ok
      _overflow -> {:error, :resource_limit_exceeded}
    end
  end

  defp empty_path_trie, do: %{children: %{}, scopes: %{}}

  defp insert_path(trie, [], scope), do: %{trie | scopes: Map.put(trie.scopes, scope, true)}

  defp insert_path(trie, [component | rest], scope) do
    child = Map.get(trie.children, component, empty_path_trie())

    Map.put(
      trie,
      :children,
      Map.put(trie.children, component, insert_path(child, rest, scope))
    )
  end

  defp eligible_definition?(record, local_name, target_path, owner_source_id, provenance_identity) do
    is_map(record) and record_kind(record) == :definition and valid_local_name?(local_name) and
      is_list(target_path) and
      trusted_scope?(record, owner_source_id, provenance_identity)
  end

  defp resolve_reference(
         reference,
         index,
         owner_source_id,
         provenance_identity
       )
       when is_map(reference) do
    local_name = Map.get(reference, :local_name)
    target_path = Map.get(reference, :target_path)

    cond do
      not valid_local_name?(local_name) ->
        {:error, :invalid_local_name}

      not trusted_scope?(reference, owner_source_id, provenance_identity) ->
        {:error, :no_local_definition}

      record_kind(reference) != :reference ->
        {:error, :no_local_definition}

      not is_list(target_path) ->
        {:error, :unsupported_inheritance}

      MapSet.member?(index.external_collisions, local_name) ->
        {:error, :external_authority_collision}

      Map.get(reference, :state_scope) != nil ->
        {:error, :unsupported_scope}

      not supported_viewport_scope?(Map.get(reference, :viewport_scope)) ->
        {:error, :unsupported_scope}

      true ->
        resolve_target(
          local_name,
          target_path,
          index,
          Map.get(reference, :viewport_scope)
        )
    end
  end

  defp resolve_reference(_reference, _index, _owner_source_id, _provenance_identity),
    do: {:error, :cross_owner_reference}

  # Absolute path depth is uncapped. Path complexity counts structural components:
  # each reference may hash its path for up to H ancestor lookups and scan one prefix.
  defp resolve_target(local_name, target_path, index, viewport_scope) do
    reversed_path = Enum.reverse(target_path)

    case selected_relation(index.by_name_and_path, local_name, reversed_path, viewport_scope) do
      {:found, candidate_path, scope_selections} ->
        resolve_scope_selection(
          scope_selections,
          local_name,
          candidate_path,
          viewport_scope,
          index.dependency_states
        )

      :none ->
        trie = Map.get(index.tries_by_name, local_name, empty_path_trie())

        if farther_ancestor_exists?(trie, target_path, viewport_scope) do
          {:error, :resource_limit_exceeded}
        else
          {:error, :no_local_definition}
        end
    end
  end

  defp selected_relation(index, local_name, reversed_path, viewport_scope) do
    case Map.fetch(index, {local_name, reversed_path}) do
      {:ok, selections} ->
        if scope_candidate?(selections, viewport_scope) do
          {:found, reversed_path, selections}
        else
          nearest_relation(index, local_name, reversed_path, viewport_scope)
        end

      :error ->
        nearest_relation(index, local_name, reversed_path, viewport_scope)
    end
  end

  defp nearest_relation(index, local_name, reversed_path, viewport_scope) do
    case nearest_ancestor(index, local_name, reversed_path, viewport_scope, 1) do
      {:found, candidate_path, selections} -> {:found, candidate_path, selections}
      :none -> :none
    end
  end

  defp nearest_ancestor(_index, _local_name, _reversed_path, _viewport_scope, distance)
       when distance > @max_ancestry_hops,
       do: :none

  defp nearest_ancestor(_index, _local_name, [], _viewport_scope, _distance), do: :none

  defp nearest_ancestor(
         index,
         local_name,
         [_target_component | reversed_ancestor],
         viewport_scope,
         distance
       ) do
    case Map.fetch(index, {local_name, reversed_ancestor}) do
      {:ok, selections} ->
        if scope_candidate?(selections, viewport_scope) do
          {:found, reversed_ancestor, selections}
        else
          nearest_ancestor(index, local_name, reversed_ancestor, viewport_scope, distance + 1)
        end

      :error ->
        nearest_ancestor(index, local_name, reversed_ancestor, viewport_scope, distance + 1)
    end
  end

  defp farther_ancestor_exists?(same_name_trie, target_path, viewport_scope) do
    max_candidate_depth = length(target_path) - @max_ancestry_hops - 1

    if max_candidate_depth < 0 do
      false
    else
      has_definition_in_prefix?(
        same_name_trie,
        target_path,
        0,
        max_candidate_depth,
        viewport_scope
      )
    end
  end

  defp has_definition_in_prefix?(trie, path, depth, max_depth, viewport_scope) do
    cond do
      scope_candidate?(trie.scopes, viewport_scope) ->
        true

      depth == max_depth ->
        false

      true ->
        case path do
          [component | rest] ->
            case Map.fetch(trie.children, component) do
              {:ok, child} ->
                has_definition_in_prefix?(child, rest, depth + 1, max_depth, viewport_scope)

              :error ->
                false
            end

          [] ->
            false
        end
    end
  end

  defp scope_candidate?(scope_selections, :base),
    do: Map.has_key?(scope_selections, {:base, nil})

  defp scope_candidate?(scope_selections, {:responsive_source_key, source_key}) do
    Map.has_key?(scope_selections, {:base, nil}) or
      Map.has_key?(scope_selections, {{:responsive_source_key, source_key}, nil})
  end

  defp resolve_scope_selection(
         scope_selections,
         local_name,
         reversed_path,
         viewport_scope,
         dependency_states
       ) do
    responsive_key = {{:responsive_source_key, responsive_source_key(viewport_scope)}, nil}

    if match?({:responsive_source_key, _}, viewport_scope) and
         Map.has_key?(scope_selections, responsive_key) do
      {:error, :unsupported_scope}
    else
      case Map.fetch(scope_selections, {:base, nil}) do
        :error ->
          {:error, :no_local_definition}

        {:ok, {:error, _state} = error} ->
          error

        {:ok, {:ok, terminal}} ->
          dependency_state = Map.get(dependency_states, {local_name, reversed_path, {:base, nil}})

          if dependency_state do
            {:error, dependency_state}
          else
            {:ok, terminal}
          end
      end
    end
  end

  defp responsive_source_key({:responsive_source_key, source_key}), do: source_key
  defp responsive_source_key(_viewport_scope), do: nil

  defp supported_viewport_scope?(:base), do: true
  defp supported_viewport_scope?({:responsive_source_key, _source_key}), do: true
  defp supported_viewport_scope?(_viewport_scope), do: false

  defp external_candidate?(%VariableAuthority{} = authority_index, local_name) do
    %{state: state} = VariableAuthority.resolve(authority_index, local_name)
    state != :no_authority
  end

  defp external_candidate?(_authority_index, _local_name), do: true

  defp build_dependency_states(selected_by_path_scope) do
    case collect_dependency_data(selected_by_path_scope) do
      {:error, :resource_limit_exceeded} ->
        {:error, :resource_limit_exceeded}

      {:ok, dependency_data, edge_count} when edge_count <= @max_dependency_edges ->
        base_definitions =
          Map.new(selected_by_path_scope, fn
            {{local_name, reversed_path, {:base, nil}}, selection} ->
              {{local_name, reversed_path}, selection}

            {_key, _selection} ->
              {nil, nil}
          end)
          |> Map.delete(nil)

        dependency_graph =
          Map.new(base_definitions, fn {{local_name, reversed_path}, _selection} ->
            node = {local_name, reversed_path}

            dependencies =
              case Map.get(dependency_data, {local_name, reversed_path, {:base, nil}}) do
                nil ->
                  []

                %{names: names} ->
                  names
                  |> Enum.reject(&is_nil/1)
                  |> Enum.map(&find_dependency_definition(base_definitions, &1, reversed_path))
                  |> Enum.reject(&is_nil/1)
              end

            {node, dependencies}
          end)

        dependency_states =
          Map.new(dependency_data, fn
            {{local_name, reversed_path, {:base, nil}} = key,
             %{names: names, fallback?: fallback?}} ->
              state =
                cond do
                  fallback? ->
                    :unsupported_fallback

                  Enum.any?(names, &(&1 == local_name)) ->
                    :self_reference

                  names != [] and cycle_reachable?({local_name, reversed_path}, dependency_graph) ->
                    :cycle

                  names != [] ->
                    :unsupported_nested_reference

                  true ->
                    nil
                end

              {key, state}

            {key, _data} ->
              {key, nil}
          end)
          |> Enum.reject(fn {_key, state} -> is_nil(state) end)
          |> Map.new()

        {:ok, dependency_states}
    end
  end

  defp collect_dependency_data(selected_by_path_scope) do
    Enum.reduce_while(selected_by_path_scope, {:ok, %{}, 0}, fn
      {{local_name, _reversed_path, scope} = key, {:ok, terminal}}, {:ok, data, edge_count} ->
        remaining_edges = @max_dependency_edges - edge_count

        case dependency_calls(terminal, remaining_edges + 1) do
          :limit ->
            {:halt, {:error, :resource_limit_exceeded}}

          {:ok, names, fallback?} ->
            new_edge_count = edge_count + length(names)

            if new_edge_count > @max_dependency_edges do
              {:halt, {:error, :resource_limit_exceeded}}
            else
              next_data =
                if scope == {:base, nil} do
                  Map.put(data, key, %{local_name: local_name, names: names, fallback?: fallback?})
                else
                  data
                end

              {:cont, {:ok, next_data, new_edge_count}}
            end
        end

      {_key, _selection}, accumulator ->
        {:cont, accumulator}
    end)
  end

  defp dependency_calls(text, max_calls) do
    scan_dependency_calls(text, 0, [], 0, false, max_calls)
  end

  defp scan_dependency_calls(text, offset, names, count, fallback?, max_calls) do
    case next_var_call(text, offset) do
      :none ->
        {:ok, Enum.reverse(names), fallback?}

      {:found, start, spelling} ->
        argument_start = start + byte_size(spelling)

        argument_end =
          case :binary.match(text, ")", scope: {argument_start, byte_size(text) - argument_start}) do
            {index, 1} -> index
            :nomatch -> byte_size(text)
          end

        argument = binary_part(text, argument_start, argument_end - argument_start)
        {name_text, has_fallback?} = split_fallback_argument(argument)
        name = name_text |> String.trim() |> valid_dependency_name()
        next_count = count + 1

        if next_count >= max_calls do
          :limit
        else
          scan_dependency_calls(
            text,
            argument_start,
            [name | names],
            next_count,
            fallback? or has_fallback?,
            max_calls
          )
        end
    end
  end

  defp next_var_call(text, offset) when offset >= byte_size(text), do: :none

  defp next_var_call(text, offset) do
    remaining_bytes = byte_size(text) - offset

    Enum.reduce(@var_spellings, nil, fn spelling, earliest ->
      case :binary.match(text, spelling, scope: {offset, remaining_bytes}) do
        :nomatch ->
          earliest

        {index, _length} when is_nil(earliest) or index < elem(earliest, 0) ->
          {index, spelling}

        _match ->
          earliest
      end
    end)
    |> case do
      nil -> :none
      {index, spelling} -> {:found, index, spelling}
    end
  end

  defp split_fallback_argument(argument) do
    case :binary.match(argument, ",") do
      {index, 1} -> {binary_part(argument, 0, index), true}
      :nomatch -> {argument, false}
    end
  end

  defp valid_dependency_name(name) do
    if valid_local_name?(name), do: name, else: nil
  end

  defp find_dependency_definition(base_definitions, local_name, reversed_path) do
    case Map.fetch(base_definitions, {local_name, reversed_path}) do
      {:ok, _selection} ->
        {local_name, reversed_path}

      :error ->
        nearest_dependency_definition(base_definitions, local_name, reversed_path, 1)
    end
  end

  defp nearest_dependency_definition(_definitions, _local_name, _reversed_path, distance)
       when distance > @max_ancestry_hops,
       do: nil

  defp nearest_dependency_definition(_definitions, _local_name, [], _distance), do: nil

  defp nearest_dependency_definition(definitions, local_name, [_component | ancestor], distance) do
    case Map.fetch(definitions, {local_name, ancestor}) do
      {:ok, _selection} ->
        {local_name, ancestor}

      :error ->
        nearest_dependency_definition(definitions, local_name, ancestor, distance + 1)
    end
  end

  defp cycle_reachable?(node, graph) do
    {reachable?, _visited} = cycle_reachable?(node, graph, MapSet.new(), MapSet.new())
    reachable?
  end

  defp cycle_reachable?(node, graph, active, visited) do
    cond do
      MapSet.member?(active, node) ->
        {true, visited}

      MapSet.member?(visited, node) ->
        {false, visited}

      true ->
        active = MapSet.put(active, node)
        visited = MapSet.put(visited, node)

        Enum.reduce_while(Map.get(graph, node, []), {false, visited}, fn dependency,
                                                                         {_found, seen} ->
          if MapSet.member?(active, dependency) do
            {:halt, {true, seen}}
          else
            {found?, seen} = cycle_reachable?(dependency, graph, active, seen)

            if found? do
              {:halt, {true, seen}}
            else
              {:cont, {false, seen}}
            end
          end
        end)
    end
  end

  defp select_definition(definitions) do
    selector_identities = definitions |> Enum.map(&Map.get(&1, :selector_identity)) |> Enum.uniq()

    cond do
      length(selector_identities) > 1 ->
        {:error, :ambiguous_definition}

      true ->
        terminal_texts = Enum.map(definitions, &Map.get(&1, :terminal_text))

        cond do
          not Enum.all?(terminal_texts, &is_binary/1) ->
            {:error, :unsupported_terminal_value}

          Enum.any?(terminal_texts, &(byte_size(&1) > @max_terminal_bytes)) ->
            {:error, :resource_limit_exceeded}

          not Enum.all?(terminal_texts, &(&1 === hd(terminal_texts))) ->
            {:error, :conflicting_source_order}

          true ->
            {:ok, hd(terminal_texts)}
        end
    end
  end

  defp trusted_scope?(record, owner_source_id, provenance_identity) do
    is_map(record) and Map.get(record, :owner_source_id) === owner_source_id and
      Map.get(record, :effective_provenance_identity) === provenance_identity
  end

  defp record_kind(record) when is_map(record), do: Map.get(record, :record_kind)
  defp record_kind(_record), do: nil

  defp valid_local_name?(name) when is_binary(name) do
    String.valid?(name) and CSSDeclaration.safe_property?(name) and
      String.starts_with?(name, "--")
  end

  defp valid_local_name?(_name), do: false
end
