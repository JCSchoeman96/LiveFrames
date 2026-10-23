defmodule LiveFrames.Adapters.Bricks.SourceLocalCustomPropertyResolver do
  @moduledoc false

  alias LiveFrames.Fidelity.CSSDeclaration
  alias LiveFrames.Tokens.VariableAuthority

  @max_definitions 256
  @max_references 1_024
  @max_ancestry_hops 64
  @max_terminal_bytes 4_096
  @max_dependency_edges 1_024

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

  @doc false
  @spec definition_compiler_input_state(String.t(), String.t(), keyword()) ::
          :ok | {:error, atom()}
  def definition_compiler_input_state(local_name, terminal_text, _opts \\ [])
      when is_binary(local_name) and is_binary(terminal_text) do
    cond do
      not valid_local_name?(local_name) ->
        {:error, :invalid_local_name}

      byte_size(terminal_text) > @max_terminal_bytes ->
        {:error, :resource_limit_exceeded}

      true ->
        case dependency_calls(terminal_text, @max_dependency_edges + 1) do
          :limit ->
            {:error, :resource_limit_exceeded}

          {:ok, names, fallback?} ->
            case isolated_definition_compiler_input_failure(
                   local_name,
                   terminal_text,
                   names,
                   fallback?
                 ) do
              nil -> :ok
              failure -> {:error, failure}
            end
        end
    end
  end

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
      Map.new(definitions_by_path, fn {{_local_name, _reversed_path, scope} = key, definitions} ->
        {key, select_definition(definitions, scope)}
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
    Enum.reduce_while(records, {:ok, 0, MapSet.new()}, fn record, {:ok, edge_count, seen} ->
      local_name = Map.get(record, :local_name)
      target_path = Map.get(record, :target_path)
      terminal = Map.get(record, :terminal_text_if_definition)

      if eligible_definition?(
           record,
           local_name,
           target_path,
           owner_source_id,
           provenance_identity
         ) and Map.get(record, :viewport_scope) == :base and is_binary(terminal) and
           byte_size(terminal) <= @max_terminal_bytes do
        coalescing_key =
          {local_name, target_path, Map.get(record, :viewport_scope),
           Map.get(record, :state_scope), Map.get(record, :selector_identity), terminal}

        if MapSet.member?(seen, coalescing_key) do
          {:cont, {:ok, edge_count, seen}}
        else
          remaining_edges = @max_dependency_edges - edge_count

          case dependency_calls(terminal, remaining_edges + 1) do
            :limit ->
              {:halt, {:error, :resource_limit_exceeded}}

            {:ok, names, _fallback?} ->
              {:cont, {:ok, edge_count + length(names), MapSet.put(seen, coalescing_key)}}
          end
        end
      else
        {:cont, {:ok, edge_count, seen}}
      end
    end)
    |> case do
      {:ok, edge_count, _seen} when edge_count <= @max_dependency_edges -> :ok
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
      is_nil(Map.get(record, :state_scope)) and
      supported_definition_viewport_scope?(Map.get(record, :viewport_scope)) and
      trusted_scope?(record, owner_source_id, provenance_identity)
  end

  defp supported_definition_viewport_scope?(:base), do: true
  defp supported_definition_viewport_scope?({:responsive_source_key, _source_key}), do: true
  defp supported_definition_viewport_scope?(_viewport_scope), do: false

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

  # Absolute path depth is uncapped. Path work is measured by structural components:
  # each reference may hash up to H + 1 path prefixes and scan one prefix trie.
  defp resolve_target(local_name, target_path, index, viewport_scope) do
    reversed_path = Enum.reverse(target_path)
    trie = Map.get(index.tries_by_name, local_name, empty_path_trie())

    case viewport_scope do
      :base ->
        resolve_base_relation(local_name, target_path, reversed_path, trie, index)

      {:responsive_source_key, _source_key} = responsive_scope ->
        responsive_scope_key = {responsive_scope, nil}

        case selected_relation_for_scopes(
               index.by_name_and_path,
               local_name,
               reversed_path,
               [responsive_scope_key, {:base, nil}]
             ) do
          {:found, candidate_path, scope_selections} ->
            if Map.has_key?(scope_selections, responsive_scope_key) do
              {:error, :unsupported_scope}
            else
              resolve_scope_selection(
                scope_selections,
                local_name,
                candidate_path,
                index.dependency_states
              )
            end

          :none ->
            if farther_ancestor_exists_in_scope?(trie, target_path, responsive_scope_key) or
                 farther_ancestor_exists_in_scope?(trie, target_path, {:base, nil}) do
              {:error, :resource_limit_exceeded}
            else
              {:error, :no_local_definition}
            end
        end
    end
  end

  defp resolve_base_relation(local_name, target_path, reversed_path, trie, index) do
    case selected_relation_for_scope(
           index.by_name_and_path,
           local_name,
           reversed_path,
           {:base, nil}
         ) do
      {:found, candidate_path, scope_selections} ->
        resolve_scope_selection(
          scope_selections,
          local_name,
          candidate_path,
          index.dependency_states
        )

      :none ->
        if farther_ancestor_exists_in_scope?(trie, target_path, {:base, nil}) do
          {:error, :resource_limit_exceeded}
        else
          {:error, :no_local_definition}
        end
    end
  end

  defp selected_relation_for_scope(index, local_name, reversed_path, scope_key) do
    case Map.fetch(index, {local_name, reversed_path}) do
      {:ok, selections} ->
        if Map.has_key?(selections, scope_key) do
          {:found, reversed_path, selections}
        else
          nearest_relation_for_scope(index, local_name, reversed_path, scope_key)
        end

      :error ->
        nearest_relation_for_scope(index, local_name, reversed_path, scope_key)
    end
  end

  defp selected_relation_for_scopes(index, local_name, reversed_path, scope_keys) do
    nearest_relation_for_scopes(index, local_name, reversed_path, scope_keys, 0)
  end

  defp nearest_relation_for_scopes(index, local_name, reversed_path, scope_keys, distance)
       when distance <= @max_ancestry_hops do
    case Map.fetch(index, {local_name, reversed_path}) do
      {:ok, selections} ->
        if Enum.any?(scope_keys, &Map.has_key?(selections, &1)) do
          {:found, reversed_path, selections}
        else
          nearest_relation_for_scopes(
            index,
            local_name,
            drop_path_head(reversed_path),
            scope_keys,
            distance + 1
          )
        end

      :error ->
        nearest_relation_for_scopes(
          index,
          local_name,
          drop_path_head(reversed_path),
          scope_keys,
          distance + 1
        )
    end
  end

  defp nearest_relation_for_scopes(_index, _local_name, _reversed_path, _scope_keys, _distance),
    do: :none

  defp drop_path_head([_component | rest]), do: rest
  defp drop_path_head([]), do: []

  defp nearest_relation_for_scope(index, local_name, reversed_path, scope_key) do
    case nearest_ancestor_for_scope(index, local_name, reversed_path, scope_key, 1) do
      {:found, candidate_path, selections} -> {:found, candidate_path, selections}
      :none -> :none
    end
  end

  defp nearest_ancestor_for_scope(_index, _local_name, _reversed_path, _scope_key, distance)
       when distance > @max_ancestry_hops,
       do: :none

  defp nearest_ancestor_for_scope(_index, _local_name, [], _scope_key, _distance), do: :none

  defp nearest_ancestor_for_scope(
         index,
         local_name,
         [_target_component | reversed_ancestor],
         scope_key,
         distance
       ) do
    case Map.fetch(index, {local_name, reversed_ancestor}) do
      {:ok, selections} ->
        if Map.has_key?(selections, scope_key) do
          {:found, reversed_ancestor, selections}
        else
          nearest_ancestor_for_scope(
            index,
            local_name,
            reversed_ancestor,
            scope_key,
            distance + 1
          )
        end

      :error ->
        nearest_ancestor_for_scope(index, local_name, reversed_ancestor, scope_key, distance + 1)
    end
  end

  defp farther_ancestor_exists_in_scope?(same_name_trie, target_path, scope_key) do
    max_candidate_depth = length(target_path) - @max_ancestry_hops - 1

    if max_candidate_depth < 0 do
      false
    else
      has_definition_in_prefix?(
        same_name_trie,
        target_path,
        0,
        max_candidate_depth,
        scope_key
      )
    end
  end

  defp has_definition_in_prefix?(trie, path, depth, max_depth, scope_key) do
    cond do
      Map.has_key?(trie.scopes, scope_key) ->
        true

      depth == max_depth ->
        false

      true ->
        case path do
          [component | rest] ->
            case Map.fetch(trie.children, component) do
              {:ok, child} ->
                has_definition_in_prefix?(child, rest, depth + 1, max_depth, scope_key)

              :error ->
                false
            end

          [] ->
            false
        end
    end
  end

  defp resolve_scope_selection(
         scope_selections,
         local_name,
         reversed_path,
         dependency_states
       ) do
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

  defp supported_viewport_scope?(:base), do: true
  defp supported_viewport_scope?({:responsive_source_key, _source_key}), do: true
  defp supported_viewport_scope?(_viewport_scope), do: false

  defp external_candidate?(%VariableAuthority{by_variable: by_variable}, local_name)
       when is_map(by_variable),
       do: Map.has_key?(by_variable, local_name)

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

        cyclic_definitions = dependency_cycle_members(dependency_graph)

        dependency_states =
          Map.new(dependency_data, fn
            {{local_name, reversed_path, {:base, nil}} = key,
             %{names: names, fallback?: fallback?}} ->
              state =
                batch_definition_dependency_failure(
                  local_name,
                  names,
                  fallback?,
                  cyclic_definitions,
                  {local_name, reversed_path}
                )

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

  defp isolated_definition_compiler_input_failure(local_name, terminal_text, names, fallback?) do
    cond do
      fallback? ->
        :unsupported_fallback

      Enum.any?(names, &(&1 == local_name)) ->
        :self_reference

      true ->
        case exact_passthrough_name(terminal_text) do
          {:ok, captured} ->
            if names == [captured], do: nil, else: :unsupported_nested_reference

          :no_match ->
            if names != [] or malformed_nbsp_passthrough?(terminal_text),
              do: :unsupported_nested_reference,
              else: nil
        end
    end
  end

  defp batch_definition_dependency_failure(
         local_name,
         names,
         fallback?,
         cyclic_definitions,
         cycle_key
       ) do
    cond do
      fallback? ->
        :unsupported_fallback

      Enum.any?(names, &(&1 == local_name)) ->
        :self_reference

      MapSet.member?(cyclic_definitions, cycle_key) ->
        :cycle

      names != [] ->
        :unsupported_nested_reference

      true ->
        nil
    end
  end

  defp dependency_calls(text, max_calls) do
    scan_css_value(text, 0, [], 0, false, max_calls)
  end

  defp scan_css_value(text, offset, names, _count, fallback?, _max_calls)
       when offset >= byte_size(text),
       do: {:ok, Enum.reverse(names), fallback?}

  defp scan_css_value(text, offset, names, count, fallback?, max_calls) do
    case :binary.at(text, offset) do
      quote when quote in [?', ?"] ->
        scan_css_value(
          text,
          skip_css_string(text, offset + 1, quote),
          names,
          count,
          fallback?,
          max_calls
        )

      ?/ ->
        if comment_start?(text, offset) do
          scan_css_value(
            text,
            skip_css_comment(text, offset + 2),
            names,
            count,
            fallback?,
            max_calls
          )
        else
          scan_css_value(text, offset + 1, names, count, fallback?, max_calls)
        end

      byte ->
        if css_name_byte?(byte) or byte == ?\\ do
          {identifier, identifier_end} = consume_css_identifier(text, offset)
          function_open = skip_css_comments(text, identifier_end)

          if ascii_downcase(identifier) == "var" and function_open < byte_size(text) and
               :binary.at(text, function_open) == ?( do
            {name_text, has_fallback?} =
              var_argument_name(text, function_open + 1, 0, function_open + 1)

            next_count = count + 1

            if next_count >= max_calls do
              :limit
            else
              scan_css_value(
                text,
                function_open + 1,
                [name_text |> String.trim() |> valid_dependency_name() | names],
                next_count,
                fallback? or has_fallback?,
                max_calls
              )
            end
          else
            scan_css_value(text, identifier_end, names, count, fallback?, max_calls)
          end
        else
          scan_css_value(text, offset + 1, names, count, fallback?, max_calls)
        end
    end
  end

  defp consume_css_identifier(text, offset), do: consume_css_identifier(text, offset, [])

  defp consume_css_identifier(text, offset, decoded) when offset >= byte_size(text),
    do: {decoded |> Enum.reverse() |> IO.iodata_to_binary(), offset}

  defp consume_css_identifier(text, offset, decoded) do
    byte = :binary.at(text, offset)

    cond do
      css_name_byte?(byte) ->
        consume_css_identifier(text, offset + 1, [<<byte>> | decoded])

      byte == ?\\ ->
        {escaped, next_offset} = decode_css_escape(text, offset + 1)
        consume_css_identifier(text, next_offset, [escaped | decoded])

      true ->
        {decoded |> Enum.reverse() |> IO.iodata_to_binary(), offset}
    end
  end

  defp decode_css_escape(text, offset) when offset >= byte_size(text), do: {"", offset}

  defp decode_css_escape(text, offset) do
    byte = :binary.at(text, offset)

    if hex_byte?(byte) do
      {digits, next_offset} = consume_hex_escape(text, offset, 0, 0)

      next_offset =
        if next_offset < byte_size(text) and css_whitespace?(:binary.at(text, next_offset)),
          do: next_offset + 1,
          else: next_offset

      {css_codepoint(digits), next_offset}
    else
      {<<byte>>, offset + 1}
    end
  end

  defp consume_hex_escape(text, offset, count, value)
       when offset >= byte_size(text) or count == 6,
       do: {value, offset}

  defp consume_hex_escape(text, offset, count, value) do
    byte = :binary.at(text, offset)

    if hex_byte?(byte) do
      consume_hex_escape(text, offset + 1, count + 1, value * 16 + hex_value(byte))
    else
      {value, offset}
    end
  end

  defp css_codepoint(value) when value == 0 or value > 0x10FFFF or value in 0xD800..0xDFFF,
    do: <<0xEF, 0xBF, 0xBD>>

  defp css_codepoint(value), do: <<value::utf8>>

  defp var_argument_name(text, offset, _depth, name_end) when offset >= byte_size(text),
    do: {binary_part(text, name_end, byte_size(text) - name_end), false}

  defp var_argument_name(text, offset, depth, name_end) do
    case :binary.at(text, offset) do
      quote when quote in [?', ?"] ->
        next_offset = skip_css_string(text, offset + 1, quote)
        var_argument_name(text, next_offset, depth, name_end)

      ?/ ->
        if comment_start?(text, offset) do
          var_argument_name(text, skip_css_comment(text, offset + 2), depth, name_end)
        else
          var_argument_name(text, offset + 1, depth, name_end)
        end

      ?( ->
        var_argument_name(text, offset + 1, depth + 1, name_end)

      ?) when depth > 0 ->
        var_argument_name(text, offset + 1, depth - 1, name_end)

      ?, when depth == 0 ->
        {binary_part(text, name_end, offset - name_end), true}

      ?) when depth == 0 ->
        {binary_part(text, name_end, offset - name_end), false}

      _byte ->
        var_argument_name(text, offset + 1, depth, name_end)
    end
  end

  defp skip_css_string(text, offset, _quote) when offset >= byte_size(text), do: offset

  defp skip_css_string(text, offset, quote) do
    case :binary.at(text, offset) do
      ^quote -> offset + 1
      ?\\ -> skip_css_string(text, min(offset + 2, byte_size(text)), quote)
      _byte -> skip_css_string(text, offset + 1, quote)
    end
  end

  defp skip_css_comment(text, offset) when offset + 1 >= byte_size(text), do: byte_size(text)

  defp skip_css_comment(text, offset) do
    if :binary.at(text, offset) == ?* and :binary.at(text, offset + 1) == ?/ do
      offset + 2
    else
      skip_css_comment(text, offset + 1)
    end
  end

  defp skip_css_comments(text, offset) when offset >= byte_size(text), do: offset

  defp skip_css_comments(text, offset) do
    if offset + 1 < byte_size(text) and :binary.at(text, offset) == ?/ and
         :binary.at(text, offset + 1) == ?* do
      skip_css_comments(text, skip_css_comment(text, offset + 2))
    else
      offset
    end
  end

  defp comment_start?(text, offset),
    do: offset + 1 < byte_size(text) and :binary.at(text, offset + 1) == ?*

  defp css_name_byte?(byte),
    do: byte in ?a..?z or byte in ?A..?Z or byte in ?0..?9 or byte in [?-, ?_] or byte >= 0x80

  defp css_whitespace?(byte), do: byte in [9, 10, 12, 13, 32]

  defp exact_passthrough_name(text) when is_binary(text),
    do: do_exact_passthrough_name(text, 0)

  defp exact_passthrough_name(_text), do: :no_match

  defp malformed_nbsp_passthrough?(text) do
    case :binary.match(text, <<0xC2, 0xA0>>) do
      :nomatch ->
        false

      _match ->
        normalized = :binary.replace(text, <<0xC2, 0xA0>>, " ", [:global])
        match?({:ok, _local_name}, exact_passthrough_name(normalized))
    end
  end

  defp do_exact_passthrough_name(text, offset) do
    offset = skip_css_syntactic_whitespace_forward(text, offset)

    with {:ok, offset} <- match_exact_var_open(text, offset),
         {:ok, offset, local_name} <- match_exact_var_local_name(text, offset),
         {:ok, offset} <- match_exact_var_close(text, offset),
         {:ok, final_offset} <- skip_css_syntactic_whitespace_end(text, offset) do
      if final_offset == byte_size(text) do
        if valid_local_name?(local_name), do: {:ok, local_name}, else: :no_match
      else
        :no_match
      end
    else
      _ -> :no_match
    end
  end

  defp skip_css_syntactic_whitespace_forward(text, offset) when offset >= byte_size(text),
    do: offset

  defp skip_css_syntactic_whitespace_forward(text, offset) do
    if css_whitespace?(:binary.at(text, offset)),
      do: skip_css_syntactic_whitespace_forward(text, offset + 1),
      else: offset
  end

  defp skip_css_syntactic_whitespace_end(text, offset) when offset >= byte_size(text),
    do: {:ok, offset}

  defp skip_css_syntactic_whitespace_end(text, offset) do
    if css_whitespace?(:binary.at(text, offset)),
      do: skip_css_syntactic_whitespace_end(text, offset + 1),
      else: {:ok, offset}
  end

  defp match_exact_var_open(text, offset) do
    if offset + 3 < byte_size(text) and
         binary_part(text, offset, 4) == "var(" do
      {:ok, offset + 4}
    else
      :no_match
    end
  end

  defp match_exact_var_close(text, offset) do
    offset = skip_css_syntactic_whitespace_forward(text, offset)

    if offset < byte_size(text) and :binary.at(text, offset) == ?) do
      {:ok, offset + 1}
    else
      :no_match
    end
  end

  defp match_exact_var_local_name(text, offset) do
    offset = skip_css_syntactic_whitespace_forward(text, offset)
    name_end = offset

    if name_end >= byte_size(text) or :binary.at(text, name_end) != ?- or
         name_end + 1 >= byte_size(text) or :binary.at(text, name_end + 1) != ?- do
      :no_match
    else
      consume_exact_local_name(text, name_end)
    end
  end

  defp consume_exact_local_name(text, offset) do
    consume_exact_local_name(text, offset, offset)
  end

  defp consume_exact_local_name(text, offset, _start) when offset >= byte_size(text) do
    :no_match
  end

  defp consume_exact_local_name(text, offset, start) do
    byte = :binary.at(text, offset)

    if css_whitespace?(byte) or byte == ?) do
      local_name = binary_part(text, start, offset - start)

      if byte_size(local_name) >= 2 do
        {:ok, offset, local_name}
      else
        :no_match
      end
    else
      consume_exact_local_name(text, offset + 1, start)
    end
  end

  defp hex_byte?(byte), do: byte in ?0..?9 or byte in ?a..?f or byte in ?A..?F
  defp hex_value(byte) when byte in ?0..?9, do: byte - ?0
  defp hex_value(byte) when byte in ?a..?f, do: byte - ?a + 10
  defp hex_value(byte), do: byte - ?A + 10

  defp ascii_downcase(text) do
    for <<byte <- text>>, into: <<>> do
      if byte in ?A..?Z, do: <<byte + 32>>, else: <<byte>>
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

  defp dependency_cycle_members(graph) do
    {_, cycle_members} =
      Enum.reduce(Map.keys(graph), {MapSet.new(), MapSet.new()}, fn node,
                                                                    {visited, cycle_members} ->
        collect_dependency_cycles(
          node,
          graph,
          MapSet.new(),
          [],
          visited,
          cycle_members
        )
      end)

    cycle_members
  end

  defp collect_dependency_cycles(node, graph, active, stack, visited, cycle_members) do
    cond do
      MapSet.member?(active, node) ->
        {visited, add_cycle_members(stack, node, cycle_members)}

      MapSet.member?(visited, node) ->
        {visited, cycle_members}

      true ->
        active = MapSet.put(active, node)
        stack = [node | stack]

        {visited, cycle_members} =
          Enum.reduce(Map.get(graph, node, []), {visited, cycle_members}, fn dependency,
                                                                             {seen, members} ->
            collect_dependency_cycles(dependency, graph, active, stack, seen, members)
          end)

        {MapSet.put(visited, node), cycle_members}
    end
  end

  defp add_cycle_members(stack, cycle_target, cycle_members) do
    stack
    |> Enum.reduce_while(cycle_members, fn node, members ->
      members = MapSet.put(members, node)

      if node == cycle_target,
        do: {:halt, members},
        else: {:cont, members}
    end)
    |> MapSet.put(cycle_target)
  end

  defp select_definition(_definitions, {{:responsive_source_key, _source_key}, nil}),
    do: {:error, :unsupported_scope}

  defp select_definition(definitions, _scope) do
    selector_identities = definitions |> Enum.map(&Map.get(&1, :selector_identity)) |> Enum.uniq()

    cond do
      length(selector_identities) > 1 ->
        {:error, :ambiguous_definition}

      true ->
        terminal_texts = Enum.map(definitions, &Map.get(&1, :terminal_text_if_definition))

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
