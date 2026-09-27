defmodule LiveFrames.Adapters.Bricks.ClassResolver do
  @moduledoc """
  Resolves source/global class references against the local catalogue and
  explicitly supplied external class authorities while retaining provenance.
  """

  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Document
  alias LiveFrames.Adapters.Bricks.Loader
  alias LiveFrames.Adapters.Bricks.Tree

  @doc """
  Resolves class references using the document catalogue and optional
  `external_class_authorities` entries shaped as
  `%{id: stable_authority_id, global_classes: [Bricks global-class records]}`.

  External authorities are explicit inputs and are never copied into the
  document's local class catalogue.
  """
  @spec resolve(Tree.t(), Document.t(), keyword()) ::
          {:ok, map(), [Diagnostic.t()]} | {:error, [Diagnostic.t()]}
  def resolve(tree, document, opts \\ [])

  def resolve(%Tree{} = tree, %Document{} = document, opts) when is_list(opts) do
    authorities =
      if Keyword.keyword?(opts),
        do: Keyword.get(opts, :external_class_authorities, []),
        else: :invalid

    with {:ok, authorities} <- parse_external_class_authorities(authorities) do
      definitions = definitions_by_id(document, authorities)
      referenced_ids = referenced_class_ids(tree)

      {elements, diagnostics} =
        Enum.reduce(tree.ordered_elements, {%{}, []}, fn element, {elements, diagnostics} ->
          {class_ids, class_id_diagnostics} = class_ids(element)

          {class_refs, class_names, class_settings, class_diagnostics} =
            Enum.reduce(class_ids, {[], [], %{}, []}, fn class_id,
                                                         {refs, names, settings, diagnostics} ->
              {ref, class_diagnostics} = resolve_class_reference(element, class_id, definitions)

              names =
                if is_binary(ref.name), do: names ++ [ref.name], else: names

              settings =
                if ref.resolution_status in [:local_resolved, :external_resolved],
                  do: Map.merge(settings, ref.settings),
                  else: settings

              {refs ++ [ref], names, settings, diagnostics ++ class_diagnostics}
            end)

          {class_names, semantic_names} = add_button_classes(element, class_names)
          source_settings = Map.drop(element.settings, ["_cssGlobalClasses"])

          resolved = %{
            element: element,
            class_ids: class_ids,
            class_names: class_names,
            class_refs: class_refs,
            settings: Map.merge(class_settings, source_settings),
            source_settings: source_settings,
            semantic_classes: semantic_names
          }

          {Map.put(elements, element.id, resolved),
           diagnostics ++ class_id_diagnostics ++ class_diagnostics}
        end)

      unreferenced_conflicts = unreferenced_conflict_diagnostics(definitions, referenced_ids)

      {:ok, %{tree: tree, elements: elements},
       sort_diagnostics(diagnostics ++ unreferenced_conflicts)}
    end
  end

  def resolve(_tree, _document, _opts),
    do:
      {:error,
       [
         Diagnostic.new(
           code: "bricks.class.invalid",
           message: "Cannot resolve classes without a Bricks tree and document"
         )
       ]}

  defp parse_external_class_authorities(authorities) when is_list(authorities) do
    authorities = Enum.sort_by(authorities, &authority_sort_key/1)

    {parsed, diagnostics} =
      Enum.reduce(authorities, {[], []}, fn authority, {parsed, diagnostics} ->
        case parse_external_class_authority(authority) do
          {:ok, parsed_authority} -> {parsed ++ [parsed_authority], diagnostics}
          {:error, diagnostic} -> {parsed, diagnostics ++ [diagnostic]}
        end
      end)

    duplicate_ids =
      parsed
      |> Enum.map(& &1.id)
      |> Enum.frequencies()
      |> Enum.filter(fn {_id, count} -> count > 1 end)
      |> Enum.map(&elem(&1, 0))
      |> Enum.sort()

    duplicate_diagnostics =
      Enum.map(duplicate_ids, fn id ->
        authority_diagnostic(id, "External class authority ID must be unique")
      end)

    diagnostics = sort_diagnostics(diagnostics ++ duplicate_diagnostics)

    if diagnostics == [] do
      {:ok, Enum.sort_by(parsed, & &1.id)}
    else
      {:error, diagnostics}
    end
  end

  defp parse_external_class_authorities(_authorities),
    do: {:error, [authority_diagnostic(nil, "External class authorities must be a list")]}

  defp parse_external_class_authority(authority) when is_map(authority) do
    with {:ok, id} <- authority_field(authority, :id, "id"),
         true <- is_binary(id) and String.trim(id) != "",
         {:ok, records} <- authority_field(authority, :global_classes, "global_classes"),
         true <- is_list(records),
         {:ok, classes} <- parse_authority_classes(records) do
      {:ok, %{id: id, classes: classes}}
    else
      {:authority_error, errors} ->
        {:error,
         authority_diagnostic(
           authority_id(authority),
           "External class records are invalid",
           errors
         )}

      _ ->
        {:error,
         authority_diagnostic(
           authority_id(authority),
           "External class authority must provide a stable ID and a global class list"
         )}
    end
  end

  defp parse_external_class_authority(_authority),
    do: {:error, authority_diagnostic(nil, "External class authority must be a map")}

  defp parse_authority_classes(records) do
    case Loader.parse_global_class_records(records) do
      {:ok, classes} -> {:ok, classes}
      {:error, errors} -> {:authority_error, errors}
    end
  end

  defp authority_field(authority, atom_key, string_key) do
    case {Map.fetch(authority, atom_key), Map.fetch(authority, string_key)} do
      {{:ok, atom_value}, {:ok, string_value}} when atom_value === string_value ->
        {:ok, atom_value}

      {{:ok, _atom_value}, {:ok, _string_value}} ->
        :error

      {{:ok, value}, :error} ->
        {:ok, value}

      {:error, {:ok, value}} ->
        {:ok, value}

      {:error, :error} ->
        :error
    end
  end

  defp authority_id(authority) do
    case authority_field(authority, :id, "id") do
      {:ok, id} when is_binary(id) -> id
      _ -> nil
    end
  end

  defp authority_sort_key(authority) when is_map(authority) do
    case authority_id(authority) do
      id when is_binary(id) -> {0, id}
      _ -> {1, ""}
    end
  end

  defp authority_sort_key(_authority), do: {1, ""}

  defp authority_diagnostic(id, message, errors \\ []) do
    error_details =
      Enum.map(errors, fn error ->
        %{
          "code" => error.code,
          "source_id" => error.source_id,
          "source_path" => error.source_path,
          "message" => error.message
        }
      end)

    Diagnostic.new(
      code: "bricks.class.authority_invalid",
      severity: :error,
      source_id: id,
      source_path: "external_class_authorities",
      message: message,
      metadata: %{"authority_id" => id, "validation_errors" => error_details}
    )
  end

  defp definitions_by_id(document, authorities) do
    local =
      Enum.reduce(document.global_classes, %{}, fn {id, class}, definitions ->
        Map.put(definitions, id, [%{source: :local, authority_id: nil, class: class}])
      end)

    Enum.reduce(authorities, local, fn authority, definitions ->
      authority.classes
      |> Enum.sort_by(fn {id, _class} -> id end)
      |> Enum.reduce(definitions, fn {id, class}, definitions ->
        Map.update(
          definitions,
          id,
          [%{source: :external, authority_id: authority.id, class: class}],
          &(&1 ++ [%{source: :external, authority_id: authority.id, class: class}])
        )
      end)
    end)
  end

  defp referenced_class_ids(tree) do
    tree.ordered_elements
    |> Enum.flat_map(fn element ->
      case Map.get(element.settings, "_cssGlobalClasses", []) do
        ids when is_list(ids) -> Enum.filter(ids, &(is_binary(&1) and byte_size(&1) > 0))
        _ -> []
      end
    end)
    |> MapSet.new()
  end

  defp resolve_class_reference(element, class_id, definitions) do
    records = Map.get(definitions, class_id, [])
    authority_ids = authority_ids(records)
    local = Enum.find(records, &(&1.source == :local))

    cond do
      records == [] ->
        ref = unresolved_ref(class_id)
        {ref, [unresolved_diagnostic(element, class_id)]}

      conflicting_definitions?(records) ->
        ref = conflicted_ref(class_id, authority_ids)
        {ref, [conflict_diagnostic(element, class_id, records, :error)]}

      true ->
        record = local || Enum.find(records, &(&1.source == :external))
        class = record.class

        resolution_status = if local, do: :local_resolved, else: :external_resolved
        resolution_source = if local, do: :local, else: :external

        ref = %{
          id: class.id,
          name: class.name,
          category: class.category,
          status: :resolved,
          resolution_status: resolution_status,
          resolution_source: resolution_source,
          authority_ids: authority_ids,
          settings: class.settings,
          raw: class.raw
        }

        {ref, []}
    end
  end

  defp unresolved_ref(class_id) do
    %{
      id: class_id,
      name: nil,
      category: nil,
      status: :unresolved,
      resolution_status: :unresolved_external,
      resolution_source: nil,
      authority_ids: [],
      settings: %{},
      raw: nil
    }
  end

  defp conflicted_ref(class_id, authority_ids) do
    %{
      id: class_id,
      name: nil,
      category: nil,
      status: :conflicted,
      resolution_status: :conflicted,
      resolution_source: nil,
      authority_ids: authority_ids,
      settings: %{},
      raw: nil
    }
  end

  defp unresolved_diagnostic(element, class_id) do
    Diagnostic.new(
      code: "bricks.class.unresolved_external",
      severity: :warning,
      source_id: element.id,
      source_path: "#{element.id}.settings._cssGlobalClasses",
      raw_value: class_id,
      message: "Element references a class absent from local and supplied external authorities",
      metadata: %{"class_id" => class_id}
    )
  end

  defp conflict_diagnostic(element, class_id, records, severity) do
    Diagnostic.new(
      code: "bricks.class.authority_conflict",
      severity: severity,
      source_id: element.id,
      source_path: "#{element.id}.settings._cssGlobalClasses",
      raw_value: class_id,
      message: "Conflicting definitions exist for a referenced global class",
      metadata: %{
        "class_id" => class_id,
        "authority_ids" => authority_ids(records),
        "has_local_definition" => Enum.any?(records, &(&1.source == :local))
      }
    )
  end

  defp unreferenced_conflict_diagnostics(definitions, referenced_ids) do
    definitions
    |> Enum.filter(fn {id, records} ->
      not MapSet.member?(referenced_ids, id) and conflicting_definitions?(records)
    end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(fn {id, records} ->
      Diagnostic.new(
        code: "bricks.class.authority_conflict",
        severity: :warning,
        source_id: id,
        source_path: "external_class_authorities",
        raw_value: id,
        message: "Conflicting definitions exist for an unreferenced global class",
        metadata: %{
          "class_id" => id,
          "authority_ids" => authority_ids(records),
          "has_local_definition" => Enum.any?(records, &(&1.source == :local))
        }
      )
    end)
  end

  defp authority_ids(records) do
    records
    |> Enum.filter(&(&1.source == :external))
    |> Enum.map(& &1.authority_id)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp conflicting_definitions?([first | rest]) do
    Enum.any?(rest, fn record ->
      not structurally_equal?(first.class.raw, record.class.raw)
    end)
  end

  defp conflicting_definitions?(_records), do: false

  defp structurally_equal?(left, right) when is_map(left) and is_map(right) do
    map_size(left) == map_size(right) and
      Enum.all?(left, fn {key, value} ->
        case Map.fetch(right, key) do
          {:ok, other_value} -> structurally_equal?(value, other_value)
          :error -> false
        end
      end)
  end

  defp structurally_equal?(left, right) when is_list(left) and is_list(right) do
    length(left) == length(right) and
      Enum.zip(left, right)
      |> Enum.all?(fn {left_value, right_value} ->
        structurally_equal?(left_value, right_value)
      end)
  end

  defp structurally_equal?(left, right), do: left === right

  defp class_ids(element) do
    case Map.get(element.settings, "_cssGlobalClasses", []) do
      ids when is_list(ids) ->
        if Enum.all?(ids, &(is_binary(&1) and byte_size(&1) > 0)) do
          {ids, []}
        else
          {[],
           [
             Diagnostic.new(
               code: "bricks.class.invalid",
               severity: :warning,
               source_id: element.id,
               message: "Global class references must be non-empty strings",
               raw_value: ids
             )
           ]}
        end

      value ->
        {[],
         [
           Diagnostic.new(
             code: "bricks.class.invalid",
             severity: :warning,
             source_id: element.id,
             message: "Global class references must be a list",
             raw_value: value
           )
         ]}
    end
  end

  defp add_button_classes(%{name: "button", settings: settings}, class_names) do
    source_count = length(class_names)
    style = Map.get(settings, "style")

    class_names =
      if is_binary(style) and safe_class_name?(style),
        do: append_unless_present(class_names, style),
        else: class_names

    class_names =
      if Map.get(settings, "outline") == true,
        do: append_unless_present(class_names, "btn--outline"),
        else: class_names

    {class_names, Enum.drop(class_names, source_count)}
  end

  defp add_button_classes(_element, class_names), do: {class_names, []}

  defp append_unless_present(values, value),
    do: if(value in values, do: values, else: values ++ [value])

  defp safe_class_name?(value),
    do: is_binary(value) and Regex.match?(~r/^[A-Za-z_][A-Za-z0-9_-]*$/, value)

  defp sort_diagnostics(diagnostics) do
    Enum.sort_by(diagnostics, fn diagnostic ->
      {diagnostic.code || "", diagnostic.source_path || "", diagnostic.source_id || "",
       diagnostic.message || "", canonical_term(diagnostic.metadata)}
    end)
  end

  defp canonical_term(value) when is_map(value) do
    value
    |> Enum.map(fn {key, nested_value} -> {canonical_term(key), canonical_term(nested_value)} end)
    |> Enum.sort()
  end

  defp canonical_term(value) when is_list(value), do: Enum.map(value, &canonical_term/1)
  defp canonical_term(value), do: value
end
