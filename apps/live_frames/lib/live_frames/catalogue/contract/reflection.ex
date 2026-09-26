defmodule LiveFrames.Catalogue.Contract.Reflection do
  @moduledoc false

  @type diagnostic :: %{code: String.t(), path: String.t(), message: String.t()}

  @target_invalid "catalogue.contract.reflection.target_invalid"
  @version_mismatch "catalogue.contract.reflection.version_mismatch"
  @component_invalid "catalogue.contract.reflection.component_invalid"
  @attr_invalid "catalogue.contract.reflection.attr_invalid"
  @slot_invalid "catalogue.contract.reflection.slot_invalid"
  @metadata_invalid "catalogue.contract.reflection.metadata_invalid"
  @metadata_function_missing "catalogue.contract.reflection.metadata_function_missing"

  @phoenix_live_view_version "1.2.11"
  @phoenix_live_view_version_charlist ~c"1.2.11"
  @component_keys [:kind, :attrs, :slots, :line]
  @attr_keys [:slot, :name, :type, :required, :opts, :doc, :line]
  @slot_keys [:name, :required, :opts, :doc, :line, :attrs, :validate_attrs]
  @simple_attr_types [
    :any,
    :boolean,
    :integer,
    :float,
    :string,
    :atom,
    :list,
    :map,
    :fun,
    :global
  ]
  @attr_option_keys [:default, :values, :examples, :include]
  @metadata_required_keys [:capabilities, :css_theme_contract, :global_prefixes]
  @metadata_allowed_keys @metadata_required_keys ++ [:slot_cardinality]

  @capability_pattern ~r/\A[a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*)+\z/
  @module_segment_pattern ~r/\A\p{Lu}[\p{L}\p{N}_]*\z/u

  @spec read(term(), term()) ::
          {:ok, %{component: map(), metadata: map()}} | {:error, [diagnostic()]}
  def read(module, function) when is_atom(module) and is_atom(function) do
    with :ok <- validate_target(module, function),
         :ok <- validate_phoenix_live_view_version(),
         {:ok, components} <- read_components(module),
         {:ok, component} <- fetch_component(components, function),
         :ok <- validate_component(component),
         {:ok, metadata} <- read_function_metadata(module, function, component) do
      {:ok, %{component: component, metadata: metadata}}
    end
  end

  def read(_module, _function),
    do: error(@target_invalid, "$", "Target must use a module atom and function atom.")

  defp validate_target(module, function) do
    if safely_ensure_loaded?(module) and function_exported?(module, function, 1) do
      :ok
    else
      error(@target_invalid, "$", "Target must be a loaded module with an exported function/1.")
    end
  end

  defp safely_ensure_loaded?(module) do
    try do
      Code.ensure_loaded?(module)
    rescue
      _ -> false
    catch
      _, _ -> false
    end
  end

  defp validate_phoenix_live_view_version do
    try do
      case Application.spec(:phoenix_live_view, :vsn) do
        @phoenix_live_view_version_charlist ->
          :ok

        @phoenix_live_view_version ->
          :ok

        _ ->
          error(
            @version_mismatch,
            "$.phoenix_live_view",
            "Phoenix LiveView must be exactly 1.2.11."
          )
      end
    rescue
      _ ->
        error(
          @version_mismatch,
          "$.phoenix_live_view",
          "Phoenix LiveView must be exactly 1.2.11."
        )
    catch
      _, _ ->
        error(
          @version_mismatch,
          "$.phoenix_live_view",
          "Phoenix LiveView must be exactly 1.2.11."
        )
    end
  end

  defp read_components(module) do
    if function_exported?(module, :__components__, 0) do
      try do
        case apply(module, :__components__, []) do
          components when is_map(components) -> {:ok, components}
          _ -> component_error("$.component")
        end
      rescue
        _ -> component_error("$.component")
      catch
        _, _ -> component_error("$.component")
      end
    else
      component_error("$.component")
    end
  end

  defp fetch_component(components, function) do
    case Map.fetch(components, function) do
      {:ok, component} -> {:ok, component}
      :error -> component_error("$.component")
    end
  end

  defp validate_component(component) when is_map(component) do
    if exact_keys?(component, @component_keys) and
         Map.get(component, :kind) == :def and
         proper_list?(Map.get(component, :attrs)) and
         proper_list?(Map.get(component, :slots)) and
         is_integer(Map.get(component, :line)) do
      with :ok <- validate_attrs(component.attrs, "$.component.attrs", :top_level),
           :ok <- validate_slots(component.slots) do
        :ok
      end
    else
      component_error("$.component")
    end
  end

  defp validate_component(_component), do: component_error("$.component")

  defp validate_attrs(attrs, path, slot_scope) do
    if proper_list?(attrs) do
      attrs
      |> Enum.with_index()
      |> Enum.reduce_while(:ok, fn {attr, index}, :ok ->
        case validate_attr(attr, "#{path}[#{index}]", slot_scope) do
          :ok -> {:cont, :ok}
          {:error, _diagnostics} = failure -> {:halt, failure}
        end
      end)
    else
      attr_error(path)
    end
  end

  defp validate_attr(attr, path, slot_scope) when is_map(attr) do
    with true <- exact_keys?(attr, @attr_keys) || attr_error(path),
         true <- is_atom(Map.get(attr, :name)) || attr_error(path),
         :ok <- validate_attr_slot(attr, path, slot_scope),
         :ok <- validate_attr_type(Map.get(attr, :type), "#{path}.type"),
         :ok <- validate_slot_global_type(attr, path, slot_scope),
         true <- is_boolean(Map.get(attr, :required)) || attr_error(path),
         :ok <- validate_attr_opts(Map.get(attr, :opts), "#{path}.opts"),
         true <- valid_doc?(Map.get(attr, :doc)) || attr_error(path),
         true <- is_integer(Map.get(attr, :line)) || attr_error(path) do
      :ok
    else
      {:error, _diagnostics} = failure -> failure
      false -> attr_error(path)
    end
  end

  defp validate_attr(_attr, path, _slot_scope), do: attr_error(path)

  defp validate_attr_slot(attr, path, :top_level) do
    if Map.get(attr, :slot) == nil, do: :ok, else: attr_error(path)
  end

  defp validate_attr_slot(attr, path, {:slot, slot_name}) do
    if Map.get(attr, :slot) == slot_name, do: :ok, else: attr_error(path)
  end

  defp validate_slot_global_type(attr, path, {:slot, _slot_name}) do
    if Map.get(attr, :type) == :global do
      attr_error("#{path}.type")
    else
      :ok
    end
  end

  defp validate_slot_global_type(_attr, _path, :top_level), do: :ok

  defp validate_attr_type(type, _path) when type in @simple_attr_types, do: :ok

  defp validate_attr_type({:struct, module}, path) when is_atom(module) do
    if module_style_atom?(module), do: :ok, else: attr_error(path)
  end

  defp validate_attr_type({:fun, arity}, _path) when is_integer(arity), do: :ok

  defp validate_attr_type(_type, path), do: attr_error(path)

  defp module_style_atom?(module) do
    name = Atom.to_string(module)

    if String.valid?(name) do
      case String.split(name, ".") do
        ["Elixir" | segments] when segments != [] ->
          Enum.all?(segments, &Regex.match?(@module_segment_pattern, &1))

        _ ->
          false
      end
    else
      false
    end
  end

  defp validate_attr_opts(opts, path) do
    if proper_list?(opts) and Keyword.keyword?(opts) and
         Enum.all?(Keyword.keys(opts), &(&1 in @attr_option_keys)) do
      :ok
    else
      attr_error(path)
    end
  end

  defp validate_slots(slots) do
    if proper_list?(slots) do
      slots
      |> Enum.with_index()
      |> Enum.reduce_while(:ok, fn {slot, index}, :ok ->
        case validate_slot(slot, "$.component.slots[#{index}]") do
          :ok -> {:cont, :ok}
          {:error, _diagnostics} = failure -> {:halt, failure}
        end
      end)
    else
      slot_error("$.component.slots")
    end
  end

  defp validate_slot(slot, path) when is_map(slot) do
    if not exact_keys?(slot, @slot_keys) do
      slot_error(path)
    else
      with true <- is_atom(Map.get(slot, :name)) || slot_error(path),
           true <- is_boolean(Map.get(slot, :required)) || slot_error(path),
           true <- Map.get(slot, :opts) == [] || slot_error("#{path}.opts"),
           true <- valid_doc?(Map.get(slot, :doc)) || slot_error(path),
           true <- is_integer(Map.get(slot, :line)) || slot_error(path),
           true <- proper_list?(Map.get(slot, :attrs)) || slot_error("#{path}.attrs"),
           true <- is_boolean(Map.get(slot, :validate_attrs)) || slot_error(path) do
        validate_attrs(slot.attrs, "#{path}.attrs", {:slot, slot.name})
      else
        {:error, _diagnostics} = failure -> failure
        false -> slot_error(path)
      end
    end
  end

  defp validate_slot(_slot, path), do: slot_error(path)

  defp read_function_metadata(module, function, component) do
    with {:ok, persisted} <- persisted_metadata_attribute(module),
         [metadata] when is_map(metadata) <- persisted,
         {:ok, function_metadata} <- fetch_function_metadata(metadata, function),
         :ok <- validate_metadata_entry(function_metadata),
         :ok <- validate_capabilities(function_metadata.capabilities),
         :ok <- validate_css_theme_contract(function_metadata.css_theme_contract),
         :ok <- validate_global_prefixes(function_metadata.global_prefixes, module),
         :ok <- validate_optional_slot_cardinality(function_metadata, component.slots) do
      {:ok, function_metadata}
    else
      {:error, _diagnostics} = failure -> failure
      _ -> metadata_error("$.metadata")
    end
  end

  defp persisted_metadata_attribute(module) do
    try do
      case module.__info__(:attributes) do
        attributes when is_list(attributes) ->
          if proper_list?(attributes) and Keyword.keyword?(attributes) do
            case Keyword.get_values(attributes, :liveframes_public_contract_metadata) do
              [] ->
                {:ok, :missing}

              [_single_attribute] ->
                {:ok, attributes[:liveframes_public_contract_metadata]}

              _multiple_attributes ->
                {:ok, :malformed}
            end
          else
            {:ok, :malformed}
          end

        _ ->
          {:ok, :malformed}
      end
    rescue
      _ -> {:ok, :malformed}
    catch
      _, _ -> {:ok, :malformed}
    end
  end

  defp fetch_function_metadata(metadata, function) do
    case Map.fetch(metadata, function) do
      {:ok, entry} when is_map(entry) ->
        {:ok, entry}

      {:ok, _entry} ->
        metadata_error("$.metadata")

      :error ->
        error(
          @metadata_function_missing,
          "$.metadata",
          "Persisted LiveFrames metadata has no entry for the requested function."
        )
    end
  end

  defp validate_metadata_entry(entry) do
    keys = Map.keys(entry)

    if Enum.all?(@metadata_required_keys, &Map.has_key?(entry, &1)) and
         Enum.all?(keys, &(&1 in @metadata_allowed_keys)) and
         map_size(entry) in [length(@metadata_required_keys), length(@metadata_allowed_keys)] do
      :ok
    else
      metadata_error("$.metadata")
    end
  end

  defp validate_capabilities(capabilities) do
    validate_sorted_unique_strings(
      capabilities,
      "$.metadata.capabilities",
      fn value -> Regex.match?(@capability_pattern, value) end
    )
  end

  defp validate_css_theme_contract(identifiers) do
    validate_sorted_unique_strings(
      identifiers,
      "$.metadata.css_theme_contract",
      fn value ->
        String.starts_with?(value, "--lf-") and byte_size(value) > byte_size("--lf-")
      end
    )
  end

  defp validate_global_prefixes(prefixes, module) do
    with :ok <-
           validate_sorted_unique_strings(prefixes, "$.metadata.global_prefixes", fn value ->
             byte_size(value) > 1 and String.ends_with?(value, "-")
           end),
         :ok <- validate_global_prefix_candidates(prefixes, module) do
      :ok
    end
  end

  defp validate_sorted_unique_strings(values, path, value_validator) do
    if proper_list?(values) do
      values
      |> Enum.with_index()
      |> Enum.reduce_while(:ok, fn {value, index}, :ok ->
        if is_binary(value) and String.valid?(value) and value_validator.(value) do
          {:cont, :ok}
        else
          {:halt, metadata_error("#{path}[#{index}]")}
        end
      end)
      |> case do
        :ok ->
          if values == Enum.sort(values) and length(values) == MapSet.size(MapSet.new(values)) do
            :ok
          else
            metadata_error(path)
          end

        {:error, _diagnostics} = failure ->
          failure
      end
    else
      metadata_error(path)
    end
  end

  defp validate_global_prefix_candidates([], _module), do: :ok

  defp validate_global_prefix_candidates(prefixes, module) do
    if function_exported?(module, :__global__?, 1) do
      prefixes
      |> Enum.with_index()
      |> Enum.reduce_while(:ok, fn {prefix, index}, :ok ->
        candidate = prefix <> "liveframes-contract-probe"

        if safely_accepts_global_candidate?(module, candidate) do
          {:cont, :ok}
        else
          {:halt, metadata_error("$.metadata.global_prefixes[#{index}]")}
        end
      end)
    else
      metadata_error("$.metadata.global_prefixes[0]")
    end
  end

  defp safely_accepts_global_candidate?(module, candidate) do
    try do
      apply(module, :__global__?, [candidate]) === true
    rescue
      _ -> false
    catch
      _, _ -> false
    end
  end

  defp validate_optional_slot_cardinality(metadata, slots) do
    case Map.fetch(metadata, :slot_cardinality) do
      :error -> :ok
      {:ok, overrides} -> validate_slot_cardinality(overrides, slots)
    end
  end

  defp validate_slot_cardinality(overrides, slots) when is_map(overrides) do
    slot_names =
      slots
      |> Enum.map(&Atom.to_string(&1.name))
      |> MapSet.new()

    overrides
    |> Map.keys()
    |> Enum.sort()
    |> Enum.reduce_while(:ok, fn key, :ok ->
      path = slot_cardinality_path(key)

      case validate_slot_cardinality_entry(key, Map.fetch!(overrides, key), slot_names, path) do
        :ok -> {:cont, :ok}
        {:error, _diagnostics} = failure -> {:halt, failure}
      end
    end)
  end

  defp validate_slot_cardinality(_overrides, _slots),
    do: metadata_error("$.metadata.slot_cardinality")

  defp validate_slot_cardinality_entry(key, value, slot_names, path)
       when is_binary(key) do
    cond do
      not String.valid?(key) ->
        metadata_error(path)

      not MapSet.member?(slot_names, key) ->
        metadata_error(path)

      valid_cardinality?(value) ->
        :ok

      true ->
        metadata_error(path)
    end
  end

  defp validate_slot_cardinality_entry(_key, _value, _slot_names, path),
    do: metadata_error(path)

  defp valid_cardinality?({min_entries, max_entries})
       when is_integer(min_entries) and min_entries >= 0 do
    max_entries == nil or (is_integer(max_entries) and max_entries >= min_entries)
  end

  defp valid_cardinality?(_value), do: false

  defp slot_cardinality_path(key) when is_binary(key),
    do: "$.metadata.slot_cardinality.#{key}"

  defp slot_cardinality_path(_key), do: "$.metadata.slot_cardinality"

  defp exact_keys?(map, keys) do
    map_size(map) == length(keys) and Enum.all?(keys, &Map.has_key?(map, &1))
  end

  defp valid_doc?(doc), do: is_nil(doc) or doc == false or is_binary(doc)

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_value), do: false

  defp component_error(path),
    do:
      error(
        @component_invalid,
        path,
        "Phoenix component reflection does not match the expected 1.2.11 shape."
      )

  defp attr_error(path),
    do:
      error(
        @attr_invalid,
        path,
        "Phoenix component attr does not match the expected 1.2.11 shape."
      )

  defp slot_error(path),
    do: error(@slot_invalid, path, "Phoenix slot does not match the expected 1.2.11 shape.")

  defp metadata_error(path),
    do:
      error(@metadata_invalid, path, "Persisted LiveFrames metadata is malformed or unsupported.")

  defp error(code, path, message), do: {:error, [%{code: code, path: path, message: message}]}
end
