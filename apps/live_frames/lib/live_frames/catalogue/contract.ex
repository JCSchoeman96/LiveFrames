defmodule LiveFrames.Catalogue.Contract do
  @moduledoc false

  alias LiveFrames.Catalogue.CanonicalJSON
  alias LiveFrames.Catalogue.Contract.Reflection
  alias LiveFrames.Catalogue.Contract.Value

  @target_invalid "catalogue.contract.normalization.target_invalid"
  @unsupported_type "catalogue.contract.normalization.unsupported_type"
  @allowed_values_invalid "catalogue.contract.normalization.allowed_values_invalid"
  @allowed_values_duplicate "catalogue.contract.normalization.allowed_values_duplicate"
  @global_names_invalid "catalogue.contract.normalization.global_names_invalid"
  @unbound_global_prefixes "catalogue.contract.normalization.unbound_global_prefixes"

  @module_name_pattern ~r/\A\p{Lu}[\p{L}\p{N}_]*(?:\.\p{Lu}[\p{L}\p{N}_]*)*\z/u

  @type diagnostic :: %{code: String.t(), path: String.t(), message: String.t()}

  @spec normalize(module(), atom()) :: {:ok, map()} | {:error, [diagnostic()]}
  def normalize(module, function) do
    case Reflection.read(module, function) do
      {:error, diagnostics} ->
        {:error, diagnostics}

      {:ok, %{component: component, metadata: metadata}} ->
        normalize_reflected_contract(module, function, component, metadata)
    end
  end

  defp normalize_reflected_contract(module, function, component, metadata) do
    with {:ok, module_name} <- normalize_module_name(module),
         {:ok, attrs} <- normalize_attrs(component.attrs, metadata),
         :ok <- bind_global_prefixes(component.attrs, metadata),
         {:ok, slots} <- normalize_slots(component.slots, metadata) do
      document = %{
        "format" => "lf-contract-v1",
        "component" => %{
          "module" => module_name,
          "function" => Atom.to_string(function)
        },
        "attrs" => attrs,
        "slots" => slots,
        "capabilities" => metadata.capabilities,
        "css_theme_contract" => metadata.css_theme_contract
      }

      validate_final_document(document)
    end
  end

  defp normalize_module_name(module) when is_atom(module) do
    case Atom.to_string(module) do
      "Elixir." <> name ->
        if String.valid?(name) and Regex.match?(@module_name_pattern, name) do
          {:ok, name}
        else
          target_invalid()
        end

      _other ->
        target_invalid()
    end
  end

  defp normalize_module_name(_module), do: target_invalid()

  defp normalize_attrs(attrs, metadata) do
    attrs
    |> Enum.sort_by(&Atom.to_string(&1.name))
    |> normalize_attrs(metadata, 0, [])
  end

  defp normalize_attrs([], _metadata, _index, normalized_attrs),
    do: {:ok, Enum.reverse(normalized_attrs)}

  defp normalize_attrs([attr | rest], metadata, index, normalized_attrs) do
    case normalize_attr(attr, metadata, index) do
      {:ok, normalized_attr} ->
        normalize_attrs(rest, metadata, index + 1, [normalized_attr | normalized_attrs])

      {:error, _diagnostics} = failure ->
        failure
    end
  end

  defp normalize_attr(attr, metadata, index) do
    path = "$.attrs[#{index}]"

    with {:ok, type} <- normalize_type(attr.type, "#{path}.type"),
         {:ok, default} <- normalize_default(attr.opts, index),
         {:ok, constraints} <- normalize_constraints(attr, metadata, index) do
      {:ok,
       %{
         "name" => Atom.to_string(attr.name),
         "type" => type,
         "required" => attr.required,
         "default" => default,
         "constraints" => constraints
       }}
    end
  end

  defp normalize_type(:any, _path), do: {:ok, builtin_type("any")}
  defp normalize_type(:boolean, _path), do: {:ok, builtin_type("boolean")}
  defp normalize_type(:integer, _path), do: {:ok, builtin_type("integer")}
  defp normalize_type(:float, _path), do: {:ok, builtin_type("float")}
  defp normalize_type(:string, _path), do: {:ok, builtin_type("string")}
  defp normalize_type(:atom, _path), do: {:ok, builtin_type("atom")}
  defp normalize_type(:list, _path), do: {:ok, builtin_type("list")}
  defp normalize_type(:map, _path), do: {:ok, builtin_type("map")}
  defp normalize_type(:fun, _path), do: {:ok, builtin_type("fun")}
  defp normalize_type(:global, _path), do: {:ok, builtin_type("global")}

  defp normalize_type({:struct, module}, path) when is_atom(module) do
    case normalize_module_name(module) do
      {:ok, name} -> {:ok, %{"kind" => "struct", "module" => name}}
      {:error, _diagnostics} -> unsupported_type(path)
    end
  end

  defp normalize_type({:fun, _arity}, path), do: unsupported_type(path)
  defp normalize_type(_type, path), do: unsupported_type(path)

  defp builtin_type(name), do: %{"kind" => "builtin", "name" => name}

  defp normalize_default(opts, attr_index) do
    case Keyword.fetch(opts, :default) do
      :error ->
        {:ok, %{"present" => false}}

      {:ok, value} ->
        case Value.normalize(value) do
          {:ok, normalized_value} ->
            {:ok, %{"present" => true, "value" => normalized_value}}

          {:error, diagnostics} ->
            rebase_diagnostics(diagnostics, "$.attrs[#{attr_index}].default.value")
        end
    end
  end

  defp normalize_constraints(attr, metadata, attr_index) do
    with {:ok, allowed_values} <- normalize_allowed_values(attr.opts, attr_index),
         {:ok, global_names} <- normalize_global_names(attr, attr_index) do
      global_prefixes =
        if attr.type == :global do
          metadata.global_prefixes
        else
          []
        end

      {:ok,
       %{
         "allowed_values" => allowed_values,
         "global_names" => global_names,
         "global_prefixes" => global_prefixes
       }}
    end
  end

  defp normalize_allowed_values(opts, attr_index) do
    case Keyword.fetch(opts, :values) do
      :error ->
        {:ok, nil}

      {:ok, values} when is_list(values) ->
        if proper_list?(values) do
          normalize_allowed_list(values, attr_index)
        else
          allowed_values_invalid(attr_index)
        end

      {:ok, %Range{} = range} ->
        if valid_range?(range) do
          normalize_allowed_range(range, attr_index)
        else
          allowed_values_invalid(attr_index)
        end

      {:ok, _value} ->
        allowed_values_invalid(attr_index)
    end
  end

  defp normalize_allowed_list(values, attr_index) do
    case normalize_allowed_list(values, attr_index, 0, []) do
      {:ok, members} -> sort_allowed_members(members, attr_index)
      {:error, _diagnostics} = failure -> failure
    end
  end

  defp normalize_allowed_list([], _attr_index, _member_index, normalized_members),
    do: {:ok, normalized_members}

  defp normalize_allowed_list([value | rest], attr_index, member_index, normalized_members) do
    case normalize_allowed_member(value, attr_index, member_index) do
      {:ok, member} ->
        normalize_allowed_list(rest, attr_index, member_index + 1, [member | normalized_members])

      {:error, _diagnostics} = failure ->
        failure
    end
  end

  defp normalize_allowed_range(range, attr_index) do
    range
    |> Enum.reduce_while({:ok, 0, []}, fn value, {:ok, member_index, normalized_members} ->
      case normalize_allowed_member(value, attr_index, member_index) do
        {:ok, member} ->
          {:cont, {:ok, member_index + 1, [member | normalized_members]}}

        {:error, _diagnostics} = failure ->
          {:halt, failure}
      end
    end)
    |> case do
      {:ok, _member_count, members} -> sort_allowed_members(members, attr_index)
      {:error, _diagnostics} = failure -> failure
    end
  end

  defp normalize_allowed_member(value, attr_index, member_index) do
    member_path = "$.attrs[#{attr_index}].constraints.allowed_values[#{member_index}]"

    case Value.normalize(value) do
      {:ok, normalized} ->
        case CanonicalJSON.encode(normalized) do
          {:ok, bytes} -> {:ok, %{bytes: bytes, value: normalized}}
          {:error, diagnostics} -> rebase_diagnostics(diagnostics, member_path)
        end

      {:error, diagnostics} ->
        rebase_diagnostics(diagnostics, member_path)
    end
  end

  defp sort_allowed_members(members, attr_index) do
    members = Enum.sort_by(members, & &1.bytes)

    if duplicate_allowed_members?(members) do
      error(
        @allowed_values_duplicate,
        "$.attrs[#{attr_index}].constraints.allowed_values",
        "Allowed values contain duplicate canonical members."
      )
    else
      {:ok, Enum.map(members, & &1.value)}
    end
  end

  defp duplicate_allowed_members?([first, second | rest]) do
    first.bytes == second.bytes or duplicate_allowed_members?([second | rest])
  end

  defp duplicate_allowed_members?(_members), do: false

  defp valid_range?(%Range{first: first, last: last, step: step} = range) do
    map_size(range) == 4 and is_integer(first) and is_integer(last) and is_integer(step) and
      step != 0
  end

  defp normalize_global_names(%{type: :global, opts: opts}, attr_index) do
    case Keyword.fetch(opts, :include) do
      :error -> {:ok, []}
      {:ok, nil} -> {:ok, []}
      {:ok, names} when is_list(names) -> normalize_global_name_list(names, attr_index)
      {:ok, _other} -> global_names_invalid(attr_index)
    end
  end

  defp normalize_global_names(_attr, _attr_index), do: {:ok, []}

  defp normalize_global_name_list(names, attr_index) do
    if proper_list?(names) and Enum.all?(names, &(is_binary(&1) and String.valid?(&1))) do
      {:ok, names |> Enum.uniq() |> Enum.sort()}
    else
      global_names_invalid(attr_index)
    end
  end

  defp bind_global_prefixes(component_attrs, metadata) do
    has_global_attr = Enum.any?(component_attrs, &(&1.type == :global))

    if metadata.global_prefixes != [] and not has_global_attr do
      error(
        @unbound_global_prefixes,
        "$.attrs",
        "Supplemental global prefixes require at least one global attr."
      )
    else
      :ok
    end
  end

  defp normalize_slots(slots, metadata) do
    normalized_slots =
      slots
      |> Enum.sort_by(&Atom.to_string(&1.name))
      |> Enum.map(&normalize_slot(&1, metadata))

    {:ok, normalized_slots}
  end

  defp normalize_slot(slot, metadata) do
    name = Atom.to_string(slot.name)
    cardinality = Map.get(metadata, :slot_cardinality, %{})

    {min_entries, max_entries} =
      case Map.fetch(cardinality, name) do
        {:ok, {min_entries, max_entries}} ->
          {min_entries, max_entries}

        :error ->
          {if(slot.required, do: 1, else: 0), nil}
      end

    %{
      "name" => name,
      "required" => slot.required,
      "min_entries" => min_entries,
      "max_entries" => max_entries
    }
  end

  defp validate_final_document(document) do
    case CanonicalJSON.encode(document) do
      {:ok, _bytes} -> {:ok, document}
      {:error, diagnostics} -> {:error, diagnostics}
    end
  end

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_other), do: false

  defp rebase_diagnostics(diagnostics, prefix) do
    rebased =
      diagnostics
      |> Enum.map(fn diagnostic ->
        %{diagnostic | path: rebase_path(diagnostic.path, prefix)}
      end)
      |> Enum.sort_by(&{&1.path, &1.code, &1.message})

    {:error, rebased}
  end

  defp rebase_path("$", prefix), do: prefix
  defp rebase_path("$." <> rest, prefix), do: prefix <> "." <> rest
  defp rebase_path("$[" <> rest, prefix), do: prefix <> "[" <> rest
  defp rebase_path(path, prefix), do: prefix <> "." <> path

  defp target_invalid do
    error(
      @target_invalid,
      "$",
      "Target module must be a normal Elixir module name."
    )
  end

  defp unsupported_type(path),
    do: error(@unsupported_type, path, "Type has no lf-contract-v1 representation.")

  defp allowed_values_invalid(attr_index),
    do:
      error(
        @allowed_values_invalid,
        "$.attrs[#{attr_index}].constraints.allowed_values",
        "Allowed values must be a proper list or a finite integer Range."
      )

  defp global_names_invalid(attr_index),
    do:
      error(
        @global_names_invalid,
        "$.attrs[#{attr_index}].constraints.global_names",
        "Global include names must be nil or a proper list of valid UTF-8 strings."
      )

  defp error(code, path, message), do: {:error, [%{code: code, path: path, message: message}]}
end
