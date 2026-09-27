defmodule LiveFrames.Adapters.Bricks.StylePrecedence do
  @moduledoc false

  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Settings

  @structured_roots ["_margin", "_border", "_background", "_gradient"]

  @spec layers([map()], map(), String.t()) :: [map()]
  def layers(class_refs, source_settings, source_id) when is_list(class_refs) do
    class_layers =
      class_refs
      |> Enum.with_index()
      |> Enum.flat_map(fn {class_ref, reference_index} ->
        if Map.get(class_ref, :resolution_status) in [:local_resolved, :external_resolved] do
          [
            %{
              origin: :global_class,
              class_id: Map.get(class_ref, :id),
              resolution_source: Map.get(class_ref, :resolution_source),
              authority_ids: Map.get(class_ref, :authority_ids, []),
              class_reference_index: reference_index,
              source_id: source_id,
              settings: Map.get(class_ref, :settings, %{})
            }
          ]
        else
          []
        end
      end)

    class_layers ++
      [
        %{
          origin: :element_local,
          class_id: nil,
          resolution_source: nil,
          authority_ids: [],
          class_reference_index: nil,
          source_id: source_id,
          settings: source_settings
        }
      ]
  end

  def layers(_class_refs, source_settings, source_id),
    do: layers([], source_settings, source_id)

  @spec resolve([map()], keyword()) :: map()
  def resolve(layers, opts \\ []) when is_list(layers) and is_list(opts) do
    extractions =
      Enum.map(layers, fn layer ->
        {layer, Settings.extract(layer.settings, opts)}
      end)

    declarations =
      Enum.flat_map(extractions, fn {layer, extraction} ->
        Enum.map(extraction.declarations, &add_layer_provenance(&1, layer))
      end)

    unresolved_declarations =
      Enum.flat_map(extractions, fn {layer, extraction} ->
        Enum.map(extraction.unresolved_declarations, &add_layer_provenance(&1, layer))
      end)

    resolutions =
      (declarations ++ unresolved_declarations)
      |> Enum.group_by(&{&1.property, &1.breakpoint})
      |> Enum.sort_by(fn {{property, breakpoint}, _declarations} ->
        {property, breakpoint || ""}
      end)
      |> Enum.map(fn {{property, breakpoint}, grouped} ->
        resolve_group(property, breakpoint, order_contributors(grouped))
      end)

    custom_css = resolved_custom_css(extractions)
    custom_css_responsive = resolved_custom_css_responsive(extractions)

    %{
      base_styles: emitted_styles(resolutions, nil),
      responsive:
        (emitted_responsive(resolutions) ++ custom_css_responsive)
        |> Enum.sort_by(&{&1.breakpoint || "", &1.property || "", &1.source_key}),
      custom_css: custom_css,
      unresolved_styles: unresolved_styles(resolutions),
      resolutions: resolutions,
      consumed: extraction_records(extractions, :consumed),
      unsupported: extraction_records(extractions, :unsupported),
      diagnostics:
        extraction_diagnostics(extractions) ++
          Enum.flat_map(resolutions, &precedence_diagnostic/1)
    }
  end

  defp resolve_group(property, breakpoint, declarations) do
    values = Enum.map(declarations, & &1.value)
    contributors = Enum.map(declarations, &contributor/1)

    case classify(declarations) do
      {:emit, declaration, state, precedence} ->
        emitted =
          declaration
          |> Map.put(:precedence, precedence)
          |> Map.put(:contributors, contributors)
          |> Map.put(:resolution_state, state)

        %{
          property: property,
          breakpoint: breakpoint,
          state: state,
          resolution_path: ["observed_declaration", "normalized", Atom.to_string(state)],
          emitted: emitted,
          contributors: contributors
        }

      {:retain_unresolved, declaration, state, precedence} ->
        unresolved =
          declaration
          |> Map.put(:precedence, precedence)
          |> Map.put(:contributors, contributors)
          |> Map.put(:resolution_state, state)

        %{
          property: property,
          breakpoint: breakpoint,
          state: state,
          resolution_path: [
            "observed_declaration",
            "normalization_unresolved",
            Atom.to_string(state)
          ],
          emitted: nil,
          unresolved: unresolved,
          contributors: contributors
        }

      {:unresolved, state, reason} ->
        %{
          property: property,
          breakpoint: breakpoint,
          state: :unresolved_precedence,
          conflict_state: state,
          conflict_reason: reason,
          resolution_path: [
            "observed_declaration",
            "normalized",
            Atom.to_string(state),
            "unresolved_precedence"
          ],
          emitted: nil,
          contributors: contributors,
          conflicting_values: values
        }
    end
  end

  defp classify([declaration]) do
    if unresolved_declaration?(declaration) do
      {:retain_unresolved, declaration, :unresolved_value, "unresolved_value"}
    else
      {:emit, declaration, :unique, "unique"}
    end
  end

  defp classify(declarations) do
    values = Enum.map(declarations, & &1.value)

    cond do
      Enum.all?(declarations, &(not unresolved_declaration?(&1))) and
          Enum.all?(values, &(&1 === hd(values))) ->
        {:emit, hd(declarations), :equivalent_duplicate, "equivalent_duplicate"}

      Enum.all?(declarations, &unresolved_declaration?/1) and
          Enum.all?(values, &(&1 === hd(values))) ->
        {:retain_unresolved, hd(declarations), :unresolved_duplicate_evidence,
         "identical_unresolved_evidence"}

      element_local_override?(declarations) ->
        local = Enum.find(declarations, &(&1.origin == :element_local))

        if unresolved_declaration?(local) do
          {:retain_unresolved, local, :element_override,
           "element_local_same_source_key_project_contract"}
        else
          {:emit, local, :element_override, "element_local_same_source_key_project_contract"}
        end

      Enum.all?(declarations, &(not unresolved_declaration?(&1))) and
          class_value_conflict?(declarations) ->
        {:unresolved, :class_conflict, "class_conflict"}

      true ->
        {:unresolved, :unresolved_precedence, "unresolved_precedence"}
    end
  end

  defp unresolved_declaration?(declaration),
    do: Map.get(declaration, :normalization_state) == :unresolved

  defp element_local_override?(declarations) do
    class_declarations = Enum.filter(declarations, &(&1.origin == :global_class))
    local_declarations = Enum.filter(declarations, &(&1.origin == :element_local))

    local_roots = Enum.map(local_declarations, & &1.source_root_key) |> Enum.uniq()

    case local_roots do
      [source_root_key] ->
        source_root_key in Map.keys(Settings.style_properties()) and
          Enum.all?(declarations, &(&1.source_root_key == source_root_key)) and
          class_declarations != [] and local_declarations != []

      _other ->
        false
    end
  end

  defp class_value_conflict?(declarations) do
    class_values =
      declarations
      |> Enum.filter(&(&1.origin == :global_class))
      |> Enum.map(& &1.value)

    length(class_values) > 1 and not Enum.all?(class_values, &(&1 === hd(class_values)))
  end

  defp order_contributors(declarations) do
    Enum.sort_by(declarations, fn declaration ->
      case declaration.origin do
        :global_class ->
          {0, declaration.class_reference_index, declaration.source_root_key,
           declaration.source_path}

        :element_local ->
          {1, 0, declaration.source_root_key, declaration.source_path}
      end
    end)
  end

  defp add_layer_provenance(declaration, layer) do
    Map.merge(declaration, %{
      origin: layer.origin,
      class_id: layer.class_id,
      resolution_source: layer.resolution_source,
      authority_ids: layer.authority_ids,
      class_reference_index: layer.class_reference_index,
      element_source_id: layer.source_id,
      state: Map.get(declaration, :normalization_state, :normalized)
    })
  end

  defp contributor(declaration) do
    %{
      "origin" => origin_name(declaration.origin),
      "class_id" => declaration.class_id,
      "resolution_source" => resolution_source_name(declaration.resolution_source),
      "authority_ids" => declaration.authority_ids,
      "class_reference_index" => declaration.class_reference_index,
      "source_id" => declaration.element_source_id,
      "source_root_key" => declaration.source_root_key,
      "source_path" => declaration.source_path
    }
  end

  defp origin_name(:global_class), do: "global_class"
  defp origin_name(:element_local), do: "element_local"

  defp resolution_source_name(nil), do: nil
  defp resolution_source_name(source) when is_atom(source), do: Atom.to_string(source)
  defp resolution_source_name(source), do: source

  defp emitted_styles(resolutions, nil) do
    resolutions
    |> Enum.filter(&(&1.breakpoint == nil and not is_nil(&1.emitted)))
    |> Map.new(fn resolution -> {resolution.property, resolution.emitted} end)
  end

  defp emitted_responsive(resolutions) do
    resolutions
    |> Enum.filter(&(&1.breakpoint != nil and not is_nil(&1.emitted)))
    |> Enum.map(fn resolution ->
      resolution.emitted
      |> Map.put(:property, resolution.property)
      |> Map.put(:breakpoint, resolution.breakpoint)
    end)
  end

  defp extraction_records(extractions, key) do
    Enum.flat_map(extractions, fn {layer, extraction} ->
      Enum.map(Map.fetch!(extraction, key), fn record ->
        Map.merge(record, layer_record_provenance(layer))
      end)
    end)
  end

  defp extraction_diagnostics(extractions) do
    Enum.flat_map(extractions, fn {layer, extraction} ->
      Enum.map(extraction.diagnostics, fn diagnostic ->
        metadata =
          diagnostic.metadata
          |> Map.merge(layer_record_provenance(layer))
          |> mark_malformed_layer(diagnostic)

        %{diagnostic | source_id: diagnostic.source_id || layer.source_id, metadata: metadata}
      end)
    end)
  end

  defp resolved_custom_css(extractions) do
    base_values =
      Enum.flat_map(extractions, fn {_layer, extraction} -> extraction.custom_css.base end)

    responsive_values =
      extractions
      |> Enum.flat_map(fn {_layer, extraction} -> extraction.custom_css.responsive end)
      |> Enum.reduce(%{}, fn record, values -> Map.put(values, record.source_key, record) end)
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(&elem(&1, 1))

    %{
      base: if(base_values == [], do: [], else: [List.last(base_values)]),
      responsive: responsive_values
    }
  end

  defp resolved_custom_css_responsive(extractions) do
    extractions
    |> Enum.flat_map(fn {_layer, extraction} ->
      Enum.filter(extraction.responsive, &(&1.kind == :custom_css))
    end)
    |> Enum.reduce(%{}, fn record, records -> Map.put(records, record.source_key, record) end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  defp unresolved_styles(resolutions) do
    resolutions
    |> Enum.flat_map(fn resolution ->
      if is_map(resolution[:unresolved]), do: [resolution.unresolved], else: []
    end)
  end

  defp layer_record_provenance(layer) do
    %{
      source_id: layer.source_id,
      origin: origin_name(layer.origin),
      class_id: layer.class_id,
      resolution_source: layer.resolution_source,
      authority_ids: layer.authority_ids,
      class_reference_index: layer.class_reference_index
    }
  end

  defp mark_malformed_layer(metadata, diagnostic) do
    malformed? =
      Enum.any?(@structured_roots, fn root ->
        is_binary(diagnostic.source_path) and
          String.starts_with?(diagnostic.source_path, root) and
          malformed_shape_message?(diagnostic.message)
      end)

    if malformed?,
      do: Map.put(metadata, "style_layer_state", "malformed_layer"),
      else: metadata
  end

  defp malformed_shape_message?(message) when is_binary(message),
    do:
      String.contains?(message, "must be an object") or
        String.contains?(message, "must be a string")

  defp malformed_shape_message?(_message), do: false

  defp precedence_diagnostic(%{state: :unresolved_precedence} = resolution) do
    [
      Diagnostic.new(
        code: "bricks.style.precedence_conflict",
        severity: :warning,
        source_id: source_id(resolution.contributors),
        source_path: "styles.#{resolution.property}",
        message: "Multiple source layers provide different values for one CSS property",
        metadata: %{
          "property" => resolution.property,
          "breakpoint" => resolution.breakpoint,
          "resolution" => "unresolved_precedence",
          "conflict" => Atom.to_string(resolution.conflict_state),
          "resolution_path" => resolution.resolution_path,
          "contributors" => resolution.contributors
        }
      )
    ]
  end

  defp precedence_diagnostic(_resolution), do: []

  defp source_id([%{"source_id" => source_id} | _rest]), do: source_id
  defp source_id(_contributors), do: nil
end
