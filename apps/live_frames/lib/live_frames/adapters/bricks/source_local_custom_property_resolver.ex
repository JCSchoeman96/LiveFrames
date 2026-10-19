defmodule LiveFrames.Adapters.Bricks.SourceLocalCustomPropertyResolver do
  @moduledoc false

  alias LiveFrames.Fidelity.CSSDeclaration

  @max_definitions 256
  @max_references 1_024
  @max_ancestry_hops 64
  @max_terminal_bytes 4_096

  @spec resolve([map()], [map()], keyword()) ::
          {:ok, [{:ok, binary()} | {:error, atom()}]} | {:error, :resource_limit_exceeded}
  def resolve(definition_records, reference_records, opts)
      when is_list(definition_records) and is_list(reference_records) and is_list(opts) do
    owner_source_id = Keyword.fetch!(opts, :owner_source_id)
    effective_provenance_identity = Keyword.fetch!(opts, :effective_provenance_identity)
    _authority_index = Keyword.fetch!(opts, :authority_index)

    if within_limit?(definition_records, @max_definitions) and
         within_limit?(reference_records, @max_references) do
      if foreign_owner_record?(definition_records, owner_source_id) or
           foreign_owner_record?(reference_records, owner_source_id) do
        {:ok, Enum.map(reference_records, fn _reference -> {:error, :cross_owner_reference} end)}
      else
        definition_index =
          build_definition_index(
            definition_records,
            owner_source_id,
            effective_provenance_identity
          )

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

  defp build_definition_index(records, owner_source_id, provenance_identity) do
    {definitions_by_path, tries_by_name} =
      Enum.reduce(records, {%{}, %{}}, fn record, {definitions_by_path, tries_by_name} ->
        local_name = Map.get(record, :local_name)
        target_path = Map.get(record, :target_path)

        if eligible_definition?(
             record,
             local_name,
             target_path,
             owner_source_id,
             provenance_identity
           ) do
          reversed_path = Enum.reverse(target_path)

          {
            Map.update(
              definitions_by_path,
              {local_name, reversed_path},
              [record],
              &[record | &1]
            ),
            Map.update(
              tries_by_name,
              local_name,
              insert_path(empty_path_trie(), target_path),
              &insert_path(&1, target_path)
            )
          }
        else
          {definitions_by_path, tries_by_name}
        end
      end)

    selected_by_path =
      Map.new(definitions_by_path, fn {key, definitions} ->
        {key, select_definition(definitions)}
      end)

    {selected_by_path, tries_by_name}
  end

  defp empty_path_trie, do: %{children: %{}, has_definition: false}

  defp insert_path(trie, []), do: %{trie | has_definition: true}

  defp insert_path(trie, [component | rest]) do
    child = Map.get(trie.children, component, empty_path_trie())

    Map.put(
      trie,
      :children,
      Map.put(trie.children, component, insert_path(child, rest))
    )
  end

  defp eligible_definition?(record, local_name, target_path, owner_source_id, provenance_identity) do
    is_map(record) and record_kind(record) == :definition and valid_local_name?(local_name) and
      is_list(target_path) and
      trusted_scope?(record, owner_source_id, provenance_identity)
  end

  defp resolve_reference(
         reference,
         {by_name_and_path, tries_by_name},
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

      true ->
        resolve_target(
          local_name,
          target_path,
          by_name_and_path,
          Map.get(tries_by_name, local_name, empty_path_trie())
        )
    end
  end

  defp resolve_reference(_reference, _index, _owner_source_id, _provenance_identity),
    do: {:error, :cross_owner_reference}

  defp resolve_target(local_name, target_path, by_name_and_path, same_name_trie) do
    reversed_path = Enum.reverse(target_path)

    case Map.fetch(by_name_and_path, {local_name, reversed_path}) do
      :error ->
        case nearest_ancestor(by_name_and_path, local_name, reversed_path, 1) do
          {:found, selected_definition} ->
            selected_definition

          :none ->
            if farther_ancestor_exists?(same_name_trie, target_path) do
              {:error, :resource_limit_exceeded}
            else
              {:error, :no_local_definition}
            end
        end

      {:ok, selected_definition} ->
        selected_definition
    end
  end

  defp nearest_ancestor(_index, _local_name, _reversed_path, distance)
       when distance > @max_ancestry_hops,
       do: :none

  defp nearest_ancestor(_index, _local_name, [], _distance), do: :none

  defp nearest_ancestor(index, local_name, [_target_component | reversed_ancestor], distance) do
    case Map.fetch(index, {local_name, reversed_ancestor}) do
      :error when distance <= @max_ancestry_hops ->
        nearest_ancestor(index, local_name, reversed_ancestor, distance + 1)

      :error ->
        :none

      {:ok, selected_definition} ->
        {:found, selected_definition}
    end
  end

  defp farther_ancestor_exists?(same_name_trie, target_path) do
    max_candidate_depth = length(target_path) - @max_ancestry_hops - 1

    if max_candidate_depth < 0 do
      false
    else
      has_definition_in_prefix?(same_name_trie, target_path, 0, max_candidate_depth)
    end
  end

  defp has_definition_in_prefix?(%{has_definition: true}, _path, _depth, _max_depth), do: true

  defp has_definition_in_prefix?(_trie, _path, depth, max_depth) when depth == max_depth,
    do: false

  defp has_definition_in_prefix?(%{children: children}, [component | rest], depth, max_depth) do
    case Map.fetch(children, component) do
      {:ok, child} -> has_definition_in_prefix?(child, rest, depth + 1, max_depth)
      :error -> false
    end
  end

  defp has_definition_in_prefix?(_trie, [], _depth, _max_depth), do: false

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
