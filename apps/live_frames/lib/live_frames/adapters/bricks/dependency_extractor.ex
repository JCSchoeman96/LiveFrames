defmodule LiveFrames.Adapters.Bricks.DependencyExtractor do
  @moduledoc """
  Collects source dependencies without resolving or executing source-runtime
  behavior.
  """

  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Element
  alias LiveFrames.Adapters.Bricks.StylePrecedence
  alias LiveFrames.StaticAsset
  alias LiveFrames.Tokens.AuthorityGate
  alias LiveFrames.Tokens.TokenSet
  alias LiveFrames.Tokens.VariableAuthority

  @known_external_variables ["--overlay-bg", "--neutral-ultra-dark-trans-60"]
  @runtime_fragments ["interaction", "dynamic", "query", "script", "hook", "runtime"]
  @image_atom_keys %{
    "url" => :url,
    "id" => :id,
    "filename" => :filename,
    "dimensions" => :dimensions,
    "full" => :full,
    "path" => :path,
    "size" => :size,
    "isPlaceholder" => :is_placeholder,
    "useDynamicData" => :use_dynamic_data,
    "__source_id" => :__source_id
  }

  @spec variables(term(), keyword()) :: [map()]
  def variables(values, opts \\ []) do
    authority_index = authority_index(opts)

    values
    |> strings()
    |> Enum.flat_map(&variable_names/1)
    |> Enum.uniq()
    |> Enum.map(&variable_record(&1, authority_index))
  end

  @spec assets(term()) :: [map()]
  def assets(values) when is_list(values) do
    values
    |> Enum.flat_map(&image_sources/1)
    |> Enum.map(&asset_record/1)
  end

  def assets(value), do: assets([value])

  @spec known_external_variable?(String.t()) :: boolean()
  def known_external_variable?(name) when is_binary(name),
    do: name in @known_external_variables

  def known_external_variable?(_name), do: false

  @spec extract(map(), term(), keyword()) :: map()
  def extract(resolved, document, opts \\ [])

  def extract(%{tree: tree, elements: elements}, document, opts) do
    authority_index = authority_index(opts)

    semantic_settings =
      case Keyword.get(opts, :semantic_settings, []) do
        names when is_list(names) -> names
        _value -> []
      end

    {class_dependencies, source_classes, acss_classes, settings_consumed, unsupported_settings,
     responsive, custom_css, variable_values, variable_occurrences, assets, runtime, diagnostics,
     style_results} =
      Enum.reduce(
        tree.ordered_elements,
        {[], [], [], [], [], [], %{base: [], responsive: []}, [], [], [], [], [], %{}},
        fn element,
           {class_dependencies_acc, source_classes_acc, acss_classes_acc, settings_consumed_acc,
            unsupported_settings_acc, responsive_acc, custom_css_acc, variable_values_acc,
            variable_occurrences_acc, assets_acc, runtime_acc, diagnostics_acc, style_results_acc} ->
          resolved = Map.fetch!(elements, element.id)

          layers =
            StylePrecedence.layers(resolved.class_refs, resolved.source_settings, element.id)

          element_semantic_settings =
            Enum.filter(semantic_settings, &Map.has_key?(resolved.source_settings, &1))

          class_semantic_settings =
            Enum.filter(semantic_settings, fn name ->
              Enum.any?(resolved.class_refs, fn class_ref ->
                class_ref.resolution_status in [:local_resolved, :external_resolved] and
                  Map.has_key?(class_ref.settings, name)
              end) and not Map.has_key?(resolved.source_settings, name)
            end)

          extraction_opts =
            [
              semantic_settings: element_semantic_settings,
              rejected_semantic_settings: class_semantic_settings
            ]

          style_result = StylePrecedence.resolve(layers, extraction_opts)

          class_records = class_records(resolved, element.id)
          class_names = resolved.class_names

          element_assets =
            if element.name == "image" do
              [
                asset_record(
                  Map.get(element.settings, "image", :missing),
                  element.id,
                  element.settings
                )
              ]
            else
              []
            end

          runtime_records = runtime_records(element.settings, element.id)
          runtime_diagnostics = Enum.map(runtime_records, &runtime_diagnostic/1)
          settings_consumed = add_source(style_result.consumed, element.id)

          unsupported_settings = add_source(style_result.unsupported, element.id)

          responsive =
            responsive_evidence(style_result)
            |> add_source(element.id)

          custom_css =
            merge_custom_css(
              custom_css_acc,
              style_result.custom_css,
              element.id
            )

          values = Enum.flat_map(layers, &strings(&1.settings))

          occurrences =
            layer_variable_occurrences(layers, element.id)

          style_results_acc = Map.put(style_results_acc, element.id, style_result)

          diagnostics =
            report_style_diagnostics(style_result)

          {
            class_dependencies_acc ++ class_records,
            append_unique(source_classes_acc, class_names),
            append_unique(acss_classes_acc, Enum.filter(class_names, &acss_class?/1)),
            settings_consumed_acc ++ settings_consumed,
            unsupported_settings_acc ++ unsupported_settings,
            responsive_acc ++ responsive,
            custom_css,
            variable_values_acc ++ values,
            variable_occurrences_acc ++ occurrences,
            assets_acc ++ add_source(element_assets, element.id),
            runtime_acc ++ runtime_records,
            diagnostics_acc ++ diagnostics ++ runtime_diagnostics,
            style_results_acc
          }
        end
      )

    variables =
      variable_values
      |> variables(authority_index: authority_index)
      |> add_variable_occurrences(variable_occurrences)

    variable_diagnostics =
      variables
      |> Enum.reject(&(&1.status == :resolved_token))
      |> Enum.map(&variable_diagnostic/1)

    asset_diagnostics =
      assets
      |> Enum.flat_map(&asset_diagnostics/1)

    %{
      class_dependencies: class_dependencies,
      source_classes: source_classes,
      acss_classes: acss_classes,
      settings_consumed: settings_consumed,
      unsupported_settings: unsupported_settings,
      responsive: responsive,
      custom_css: custom_css,
      variables: variables,
      assets: assets,
      runtime_dependencies: runtime,
      diagnostics: diagnostics ++ variable_diagnostics ++ asset_diagnostics,
      style_results: style_results,
      document: document
    }
  end

  def extract(_resolved, _document, _opts),
    do: %{
      class_dependencies: [],
      source_classes: [],
      acss_classes: [],
      settings_consumed: [],
      unsupported_settings: [],
      responsive: [],
      custom_css: %{base: [], responsive: []},
      variables: [],
      assets: [],
      runtime_dependencies: [],
      diagnostics: [],
      style_results: %{}
    }

  defp layer_variable_occurrences(layers, source_id) do
    Enum.flat_map(layers, fn layer ->
      path =
        case layer.origin do
          :global_class ->
            "settings.class_refs[#{layer.class_reference_index}].settings"

          :element_local ->
            "settings"
        end

      variable_occurrences(layer.settings, source_id, path, [])
    end)
  end

  defp responsive_evidence(style_result) do
    style_responsive =
      Enum.reject(style_result.responsive_evidence, &(Map.get(&1, :kind) == :custom_css))

    custom_css_responsive =
      Enum.map(style_result.custom_css.responsive, &Map.put(&1, :kind, :custom_css))

    style_responsive ++ custom_css_responsive
  end

  defp report_style_diagnostics(style_result) do
    precedence_conflict_paths =
      style_result.resolutions
      |> Enum.filter(&(&1.state == :unresolved_precedence))
      |> Enum.flat_map(
        &Enum.map(&1.contributors, fn contributor -> contributor["source_path"] end)
      )
      |> MapSet.new()

    Enum.reject(style_result.diagnostics, fn diagnostic ->
      diagnostic.code == "bricks.setting.value_unresolved" and
        MapSet.member?(precedence_conflict_paths, diagnostic.source_path)
    end)
  end

  defp variable_record(name, authority_index) do
    resolution = VariableAuthority.resolve(authority_index, name)
    candidates = Enum.map(resolution.candidates, &candidate_evidence/1)
    candidate_paths = Enum.map(candidates, & &1.token_path)

    base = %{
      name: name,
      status: nil,
      token_path: nil,
      candidate_paths: candidate_paths,
      authority_state: resolution.state,
      authority_evidence: candidates,
      token_status: nil,
      resolution_reason: nil,
      expressions: []
    }

    record =
      case {resolution.state, resolution.candidates} do
        {:unique_candidate, [%{resolution_status: :resolved} = candidate]} ->
          %{
            base
            | status: :resolved_token,
              token_path: candidate.token_path,
              token_status: :resolved
          }

        {:unique_candidate, [candidate]} ->
          %{
            base
            | status: :unresolved_token,
              token_path: candidate.token_path,
              token_status: candidate.resolution_status,
              resolution_reason: "token_unresolved"
          }

        {:ambiguous_candidates, _candidates} ->
          %{base | status: :ambiguous_token, resolution_reason: "mapping_ambiguous"}

        {:no_authority, []} when name in @known_external_variables ->
          %{base | status: :unresolved_external, resolution_reason: "external_unresolved"}

        {:no_authority, []} ->
          %{base | status: :source_variable, resolution_reason: "mapping_unproven"}
      end

    if is_nil(record.resolution_reason),
      do: Map.delete(record, :resolution_reason),
      else: record
  end

  defp candidate_evidence(candidate) do
    %{
      token_path: candidate.token_path,
      resolution_status: candidate.resolution_status,
      authorities: candidate.authorities
    }
  end

  defp authority_index(opts) do
    case Keyword.fetch(opts, :authority_index) do
      {:ok, %VariableAuthority{} = index} ->
        index

      {:ok, _invalid_index} ->
        raise ArgumentError, "Bricks variable authority index is invalid"

      :error ->
        build_authority_index!(Keyword.get(opts, :token_set))
    end
  end

  defp build_authority_index!(nil), do: %VariableAuthority{}

  defp build_authority_index!(%TokenSet{} = token_set) do
    case AuthorityGate.authorize(token_set) do
      {:ok, index} ->
        index

      {:error, _diagnostics} ->
        raise ArgumentError, "Bricks TokenSet variable authority could not be authorized"
    end
  end

  defp build_authority_index!(_invalid_token_set) do
    raise ArgumentError, "Bricks TokenSet must be a validated TokenSet struct"
  end

  defp variable_names(value) when is_binary(value) do
    if Regex.match?(~r/var\s*\(/, value) do
      Regex.scan(~r/--[A-Za-z0-9_-]+/, value) |> List.flatten() |> Enum.uniq()
    else
      []
    end
  end

  defp variable_names(_value), do: []

  defp strings(value) when is_binary(value), do: [value]
  defp strings(value) when is_list(value), do: Enum.flat_map(value, &strings/1)

  defp strings(value) when is_map(value),
    do:
      value
      |> Enum.sort_by(fn {key, _nested} -> to_string(key) end)
      |> Enum.flat_map(fn {_key, nested} -> strings(nested) end)

  defp strings(_value), do: []

  defp variable_occurrences(value, source_id, path, occurrences) when is_binary(value) do
    names = variable_names(value)

    Enum.reduce(names, occurrences, fn name, occurrences ->
      occurrences ++ [%{name: name, source_id: source_id, source_path: path, expression: value}]
    end)
  end

  defp variable_occurrences(value, source_id, path, occurrences) when is_list(value) do
    value
    |> Enum.with_index()
    |> Enum.reduce(occurrences, fn {item, index}, occurrences ->
      variable_occurrences(item, source_id, "#{path}[#{index}]", occurrences)
    end)
  end

  defp variable_occurrences(value, source_id, path, occurrences) when is_map(value) do
    value
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
    |> Enum.reduce(occurrences, fn {key, item}, occurrences ->
      variable_occurrences(item, source_id, "#{path}.#{key}", occurrences)
    end)
  end

  defp variable_occurrences(_value, _source_id, _path, occurrences), do: occurrences

  defp add_variable_occurrences(variables, occurrences) do
    Enum.map(variables, fn variable ->
      matches = Enum.filter(occurrences, &(&1.name == variable.name))

      variable
      |> Map.put(:expressions, Enum.uniq(Enum.map(matches, & &1.expression)))
      |> Map.put(:occurrences, matches)
    end)
  end

  defp image_sources(%Element{name: "image", settings: settings, id: source_id}),
    do: [asset_source(Map.get(settings, "image", :missing), source_id, settings)]

  defp image_sources(%{"image" => image}) when is_map(image), do: [image]
  defp image_sources(%{image: image}) when is_map(image), do: [image]
  defp image_sources(%{} = image), do: [image]
  defp image_sources(_value), do: []

  defp asset_source(image, source_id, element_settings),
    do: %{image: image, source_id: source_id, element_settings: element_settings}

  defp asset_record(%{image: image, source_id: source_id, element_settings: settings}),
    do: asset_record(image, source_id, settings)

  defp asset_record(image), do: asset_record(image, image_value(image, "__source_id"), %{})

  defp asset_record(image, source_id, element_settings) do
    image_map = if is_map(image), do: image, else: %{}
    url = image_value(image_map, "url")
    dynamic? = dynamic_image_source?(image_map)
    sources_count = responsive_sources_count(element_settings)

    {status, uri, resolution_reason} =
      case classify_image_uri(image_map, url, dynamic?) do
        {:ok, validated_uri} -> {:resolved, validated_uri, "resolved_static"}
        {:error, reason} -> {:unresolved, nil, "unresolved_#{reason}"}
      end

    asset = %{
      attachment_id: image_value(image_map, "id"),
      filename: image_value(image_map, "filename"),
      url: url,
      uri: uri,
      alt: nil,
      alt_resolution: "unproven",
      dimensions: image_value(image_map, "dimensions"),
      full: image_value(image_map, "full"),
      path: image_value(image_map, "path"),
      size: image_value(image_map, "size"),
      sources_count: sources_count,
      resolution_reason: resolution_reason,
      status: status,
      source_id: source_id
    }

    if custom_caption?(element_settings), do: Map.put(asset, :custom_caption?, true), else: asset
  end

  defp image_value(image, key),
    do: Map.get(image, key, Map.get(image, Map.fetch!(@image_atom_keys, key)))

  defp dynamic_image_source?(image) do
    image_value(image, "useDynamicData") not in [nil, false, ""]
  end

  defp classify_image_uri(_image, _url, true), do: {:error, :dynamic}

  defp classify_image_uri(image, _url, false) do
    if image_value(image, "isPlaceholder") == true do
      {:error, :placeholder}
    else
      classify_media_image(image)
    end
  end

  defp classify_media_image(image) do
    with :ok <- validate_media_identity(image),
         {:ok, selected_uri} <- StaticAsset.validate(image_value(image, "url")),
         {:ok, _full_uri} <- StaticAsset.validate(image_value(image, "full")) do
      {:ok, selected_uri}
    end
  end

  defp validate_media_identity(image) do
    attachment_id = image_value(image, "id")
    filename = image_value(image, "filename")
    size = image_value(image, "size")

    cond do
      missing_asset_field?(attachment_id) or missing_asset_field?(filename) or
          missing_asset_field?(size) ->
        {:error, :missing}

      not is_integer(attachment_id) or attachment_id <= 0 or not is_binary(filename) or
          not is_binary(size) ->
        {:error, :malformed}

      true ->
        :ok
    end
  end

  defp missing_asset_field?(value), do: value in [nil, false, ""]

  defp responsive_sources_count(settings) when is_map(settings) do
    sources = Map.get(settings, "sources", Map.get(settings, :sources))

    cond do
      is_list(sources) -> length(sources)
      is_map(sources) and not is_struct(sources) -> map_size(sources)
      true -> 0
    end
  end

  defp responsive_sources_count(_settings), do: 0

  defp custom_caption?(settings) when is_map(settings),
    do: Map.get(settings, "caption", Map.get(settings, :caption)) == "custom"

  defp custom_caption?(_settings), do: false

  defp asset_diagnostics(asset) do
    unresolved_diagnostic =
      if asset.status == :unresolved, do: [asset_diagnostic(asset)], else: []

    sources_diagnostic =
      if asset.sources_count > 0 do
        [
          Diagnostic.new(
            code: "bricks.asset.sources_unsupported",
            severity: :warning,
            source_id: asset.source_id,
            source_path: "settings.sources",
            message: "responsive Bricks image sources were preserved but not compiled",
            metadata: %{"source_count" => asset.sources_count}
          )
        ]
      else
        []
      end

    caption_diagnostic =
      if Map.get(asset, :custom_caption?, false) do
        [
          Diagnostic.new(
            code: "bricks.asset.caption_unsupported",
            severity: :warning,
            source_id: asset.source_id,
            source_path: "settings.caption",
            message:
              "Bricks image caption structure and content were preserved as evidence but not compiled in C-04B",
            metadata: %{"caption_mode" => "custom"}
          )
        ]
      else
        []
      end

    unresolved_diagnostic ++ sources_diagnostic ++ caption_diagnostic
  end

  defp class_records(resolved, source_id) do
    global =
      Enum.map(resolved.class_refs, fn ref ->
        record = %{
          element_id: source_id,
          class_id: ref.id,
          name: ref.name,
          category: ref.category,
          status: ref.status,
          provenance: :global_class
        }

        if ref.resolution_status == :local_resolved and ref.authority_ids == [] do
          record
        else
          Map.merge(record, %{
            resolution_status: ref.resolution_status,
            resolution_source: ref.resolution_source,
            authority_ids: ref.authority_ids
          })
        end
      end)

    semantic =
      Enum.map(resolved.semantic_classes, fn name ->
        %{
          element_id: source_id,
          class_id: nil,
          name: name,
          category: "acss",
          status: :preserved,
          provenance: :element_setting
        }
      end)

    global ++ semantic
  end

  defp acss_class?(name) when is_binary(name),
    do: String.starts_with?(name, ["btn--", "bg--", "text--", "acss-"])

  defp acss_class?(_name), do: false

  defp append_unique(values, additions) do
    Enum.reduce(additions, values, fn value, values ->
      if value in values, do: values, else: values ++ [value]
    end)
  end

  defp add_source(records, source_id),
    do: Enum.map(records, &Map.put(&1, :source_id, source_id))

  defp merge_custom_css(current, %{base: base, responsive: responsive}, source_id) do
    %{
      base: current.base ++ Enum.map(base, &%{source_id: source_id, value: &1}),
      responsive:
        current.responsive ++ Enum.map(responsive, &Map.put_new(&1, :source_id, source_id))
    }
  end

  defp runtime_records(value, source_id), do: runtime_records(value, source_id, "settings", [])

  defp runtime_records(value, source_id, path, records) when is_map(value) do
    value
    |> Enum.sort_by(fn {key, _nested} -> to_string(key) end)
    |> Enum.reduce(records, fn {key, nested}, records ->
      key_string = to_string(key)
      path = "#{path}.#{key_string}"

      records =
        if runtime_key?(key_string) do
          records ++
            [
              %{
                kind: runtime_kind(key_string),
                status: :unsupported,
                source_id: source_id,
                source_path: path,
                key: key_string,
                raw_value: nested
              }
            ]
        else
          records
        end

      runtime_records(nested, source_id, path, records)
    end)
  end

  defp runtime_records(value, source_id, path, records) when is_list(value) do
    value
    |> Enum.with_index()
    |> Enum.reduce(records, fn {nested, index}, records ->
      runtime_records(nested, source_id, "#{path}[#{index}]", records)
    end)
  end

  defp runtime_records(_value, _source_id, _path, records), do: records

  defp runtime_key?(key),
    do: Enum.any?(@runtime_fragments, &String.contains?(String.downcase(key), &1))

  defp runtime_kind(key) do
    cond do
      String.contains?(String.downcase(key), "interaction") -> :interaction
      String.contains?(String.downcase(key), "dynamic") -> :dynamic_data
      String.contains?(String.downcase(key), "query") -> :query_loop
      String.contains?(String.downcase(key), "script") -> :external_script
      String.contains?(String.downcase(key), "hook") -> :browser_runtime
      true -> :unsupported_feature
    end
  end

  defp runtime_diagnostic(record),
    do:
      Diagnostic.new(
        code: "bricks.runtime.unsupported",
        severity: :warning,
        source_path: record.source_path,
        source_id: record.source_id,
        raw_value: record.raw_value,
        message: "Bricks runtime behavior is preserved but not implemented in Stage A"
      )

  defp variable_diagnostic(variable),
    do:
      Diagnostic.new(
        code: "bricks.variable.unresolved",
        severity: :warning,
        source_path: "variables.#{variable.name}",
        raw_value: variable.name,
        message: "CSS variable has no proven TokenSet resolution",
        metadata:
          %{
            "resolution_reason" => variable.resolution_reason,
            "source_variable" => variable.name,
            "candidate_paths" => variable.candidate_paths,
            "authority_state" => Atom.to_string(variable.authority_state),
            "authority_evidence" => variable.authority_evidence
          }
          |> maybe_put_metadata("token_path", variable.token_path)
      )

  defp maybe_put_metadata(metadata, _key, nil), do: metadata
  defp maybe_put_metadata(metadata, key, value), do: Map.put(metadata, key, value)

  defp asset_diagnostic(asset),
    do:
      Diagnostic.new(
        code: "bricks.asset.unresolved",
        severity: :warning,
        source_id: asset.source_id,
        source_path: "image.url",
        raw_value: asset.url,
        message: "Bricks image URI remained unresolved (#{asset.resolution_reason})",
        metadata: %{"resolution_reason" => asset.resolution_reason}
      )
end
