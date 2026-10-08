defmodule LiveFrames.Adapters.Bricks.FrontendBindingNormalizer do
  @moduledoc """
  Normalizes Bricks collection boundaries and closed frontend value forms.

  Source expressions stay inert. This module records only frontend semantics
  established by the Bricks export and current Design IR contract.
  """

  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Element
  alias LiveFrames.Adapters.Bricks.Tree
  alias LiveFrames.IR.CollectionBinding
  alias LiveFrames.IR.SourceTrace
  alias LiveFrames.IR.ValueBinding

  @query_count_token ~r/^\{query_results_count:([^{}]+)\}$/
  @query_count_occurrence ~r/\{query_results_count:([^{}]+)\}/
  @known_text_tokens ["{post_title}", "{post_content}", "{post_content:16}"]

  @spec normalize(Tree.t(), map(), String.t()) :: map()
  def normalize(%Tree{} = tree, trace_index, adapter_version) when is_map(trace_index) do
    initial = {%{}, %{}, %{}, MapSet.new(), []}

    {collection_bindings, collection_by_source, collection_context_by_source, query_owner_ids,
     diagnostics} =
      Enum.reduce(tree.root_ids, initial, fn source_id, acc ->
        collect_collections(
          source_id,
          nil,
          tree,
          trace_index,
          adapter_version,
          acc
        )
      end)

    diagnostics = Enum.reverse(diagnostics)

    {value_bindings, node_actions, dynamic_image_source_ids, dynamic_url_source_ids,
     normalized_site_url_source_ids, value_diagnostics} =
      normalize_values(
        tree,
        trace_index,
        adapter_version,
        collection_by_source,
        collection_context_by_source
      )

    %{
      collection_bindings: collection_bindings,
      collection_by_source: collection_by_source,
      collection_context_by_source: collection_context_by_source,
      query_owner_ids: query_owner_ids,
      value_bindings: value_bindings,
      node_actions: node_actions,
      dynamic_image_source_ids: dynamic_image_source_ids,
      dynamic_url_source_ids: dynamic_url_source_ids,
      normalized_site_url_source_ids: normalized_site_url_source_ids,
      diagnostics: diagnostics ++ value_diagnostics
    }
  end

  def normalize(_tree, _trace_index, _adapter_version) do
    %{
      collection_bindings: %{},
      collection_by_source: %{},
      collection_context_by_source: %{},
      query_owner_ids: MapSet.new(),
      value_bindings: %{},
      node_actions: %{},
      dynamic_image_source_ids: MapSet.new(),
      dynamic_url_source_ids: MapSet.new(),
      normalized_site_url_source_ids: MapSet.new(),
      diagnostics: []
    }
  end

  defp collect_collections(
         source_id,
         parent_binding_id,
         tree,
         trace_index,
         adapter_version,
         {bindings, by_source, contexts, query_owner_ids, diagnostics}
       ) do
    element = Map.fetch!(tree.elements, source_id)
    query = Map.get(element.settings, "query")
    query_present? = Map.has_key?(element.settings, "query")
    query? = json_object?(query)
    query_candidate? = query_present? or Map.get(element.settings, "hasLoop") == true

    query_owner_ids =
      if query_candidate?,
        do: MapSet.put(query_owner_ids, source_id),
        else: query_owner_ids

    admitted? =
      query? and Map.get(element.settings, "hasLoop") == true and
        Map.has_key?(trace_index, source_id) and
        has_structural_child?(source_id, tree, trace_index)

    {current_binding_id, bindings, by_source, diagnostics} =
      cond do
        admitted? ->
          trace =
            collection_trace(element, query, parent_binding_id, trace_index, adapter_version)

          owner_node_id = Map.fetch!(trace_index, source_id).node_id
          binding_id = "cb_" <> owner_node_id

          binding = %CollectionBinding{
            collection_binding_id: binding_id,
            owner_node_id: owner_node_id,
            repeat_root_node_id: owner_node_id,
            parent_collection_binding_id: parent_binding_id,
            normalization_status: :normalized,
            source_trace: trace
          }

          {binding_id, Map.put(bindings, binding_id, binding),
           Map.put(by_source, source_id, binding), diagnostics}

        query_candidate? ->
          diagnostic = unproven_boundary_diagnostic(element, query, query_present?)
          {parent_binding_id, bindings, by_source, [diagnostic | diagnostics]}

        true ->
          {parent_binding_id, bindings, by_source, diagnostics}
      end

    contexts = Map.put(contexts, source_id, current_binding_id)

    tree.children_by_id
    |> Map.get(source_id, [])
    |> Enum.reduce({bindings, by_source, contexts, query_owner_ids, diagnostics}, fn child_id,
                                                                                     acc ->
      collect_collections(
        child_id,
        current_binding_id,
        tree,
        trace_index,
        adapter_version,
        acc
      )
    end)
  end

  defp normalize_values(
         tree,
         trace_index,
         adapter_version,
         collection_by_source,
         collection_context_by_source
       ) do
    initial = %{
      candidates: [],
      node_actions: %{},
      dynamic_image_source_ids: MapSet.new(),
      dynamic_url_source_ids: MapSet.new(),
      normalized_site_url_source_ids: MapSet.new(),
      diagnostics: []
    }

    result =
      Enum.reduce(tree.ordered_elements, initial, fn element, acc ->
        collection_id = Map.get(collection_context_by_source, element.id)

        classified =
          classify_element_values(
            element,
            collection_id,
            collection_by_source,
            trace_index,
            adapter_version
          )

        %{
          acc
          | candidates: Enum.reverse(classified.candidates, acc.candidates),
            node_actions:
              Map.update(acc.node_actions, element.id, classified.node_actions, fn current ->
                Map.merge(current, classified.node_actions)
              end),
            dynamic_image_source_ids:
              if(classified.dynamic_image?,
                do: MapSet.put(acc.dynamic_image_source_ids, element.id),
                else: acc.dynamic_image_source_ids
              ),
            dynamic_url_source_ids:
              if(classified.dynamic_url?,
                do: MapSet.put(acc.dynamic_url_source_ids, element.id),
                else: acc.dynamic_url_source_ids
              ),
            normalized_site_url_source_ids:
              if(classified.normalized_site_url?,
                do: MapSet.put(acc.normalized_site_url_source_ids, element.id),
                else: acc.normalized_site_url_source_ids
              ),
            diagnostics: Enum.reverse(classified.diagnostics, acc.diagnostics)
        }
      end)

    diagnostics = Enum.reverse(result.diagnostics)

    {value_bindings, _ordinals} =
      result.candidates
      |> Enum.reverse()
      |> assign_value_binding_ids()

    {
      value_bindings,
      result.node_actions,
      result.dynamic_image_source_ids,
      result.dynamic_url_source_ids,
      result.normalized_site_url_source_ids,
      diagnostics
    }
  end

  defp classify_element_values(
         element,
         collection_id,
         collection_by_source,
         trace_index,
         adapter_version
       ) do
    {text_candidates, clear_content?, text_diagnostics} =
      classify_text(
        element,
        collection_id,
        collection_by_source,
        trace_index,
        adapter_version
      )

    {image_candidates, dynamic_image?, image_diagnostics} =
      classify_dynamic_image(element, collection_id, trace_index, adapter_version)

    {url_candidates, dynamic_url?, normalized_site_url?, url_diagnostics} =
      classify_dynamic_url(element, trace_index, adapter_version)

    alt_diagnostics = classify_dynamic_alt_text(element)

    candidates =
      Enum.sort_by(text_candidates ++ image_candidates ++ url_candidates, &candidate_order_key/1)

    node_actions =
      %{}
      |> maybe_put_action(:clear_content, clear_content?)
      |> maybe_put_action(:remove_dynamic_url, dynamic_url?)

    %{
      candidates: candidates,
      node_actions: node_actions,
      dynamic_image?: dynamic_image?,
      dynamic_url?: dynamic_url?,
      normalized_site_url?: normalized_site_url?,
      diagnostics: text_diagnostics ++ image_diagnostics ++ url_diagnostics ++ alt_diagnostics
    }
  end

  defp classify_text(
         element,
         collection_id,
         collection_by_source,
         trace_index,
         adapter_version
       ) do
    case Map.get(element.settings, "text") do
      "{post_title}" = expression ->
        classify_collection_field(
          element,
          collection_id,
          trace_index,
          adapter_version,
          "text",
          %{"text" => expression},
          expression,
          "text.post_title",
          "content.title",
          :none,
          :normalized
        )

      "{post_content}" = expression ->
        classify_collection_field(
          element,
          collection_id,
          trace_index,
          adapter_version,
          "text",
          %{"text" => expression},
          expression,
          "text.post_content",
          "content.body",
          :none,
          :normalized
        )

      "{post_content:16}" = expression ->
        classify_collection_field(
          element,
          collection_id,
          trace_index,
          adapter_version,
          "text",
          %{"text" => expression},
          expression,
          "text.post_content_opaque",
          "content.body",
          :opaque,
          :evidence_insufficient
        )

      expression when is_binary(expression) ->
        classify_other_text(
          element,
          expression,
          collection_by_source,
          trace_index,
          adapter_version
        )

      _other ->
        {[], false, []}
    end
  end

  defp classify_other_text(
         element,
         expression,
         collection_by_source,
         trace_index,
         adapter_version
       ) do
    case Regex.run(@query_count_token, expression) do
      [^expression, owner_id] ->
        case Map.get(collection_by_source, owner_id) do
          %CollectionBinding{} = collection ->
            candidate =
              value_candidate(
                element,
                trace_index,
                adapter_version,
                "text",
                %{"text" => expression},
                expression,
                "text.query_results_count",
                "collection count for source owner #{owner_id}",
                %{
                  target_kind: :text,
                  value_kind: :collection_count,
                  scope: :collection,
                  value_key: nil,
                  collection_binding_id: collection.collection_binding_id,
                  modifier_status: :none,
                  normalization_status: :normalized
                },
                %{
                  "referenced_bricks_owner_id" => owner_id,
                  "resolved_collection_binding_id" => collection.collection_binding_id
                }
              )

            {[candidate], true, []}

          _missing_or_unadmitted ->
            diagnostic =
              binding_diagnostic(
                "bricks.binding.evidence_insufficient",
                element,
                "text",
                expression,
                "query count token does not reference an admitted CollectionBinding"
              )

            {[], true, [diagnostic]}
        end

      _not_exact_count ->
        if brace_syntax?(expression) do
          code =
            if known_text_token_occurs?(expression),
              do: "bricks.binding.interpolation_unsupported",
              else: "bricks.binding.expression_unsupported"

          message =
            if code == "bricks.binding.interpolation_unsupported",
              do: "Bricks text combines a known dynamic token with surrounding text",
              else: "Bricks text expression is outside the closed binding classifier"

          {[], true, [binding_diagnostic(code, element, "text", expression, message)]}
        else
          {[], false, []}
        end
    end
  end

  defp classify_collection_field(
         element,
         nil,
         _trace_index,
         _adapter_version,
         path,
         _source_settings,
         expression,
         _discriminator,
         _value_key,
         _modifier_status,
         _normalization_status
       ) do
    diagnostic =
      binding_diagnostic(
        "bricks.binding.evidence_insufficient",
        element,
        path,
        expression,
        "known collection-item token has no admitted collection context"
      )

    {[], true, [diagnostic]}
  end

  defp classify_collection_field(
         element,
         collection_id,
         trace_index,
         adapter_version,
         path,
         source_settings,
         expression,
         discriminator,
         value_key,
         modifier_status,
         normalization_status
       ) do
    inference = "closed Bricks text form maps to #{value_key}"

    candidate =
      value_candidate(
        element,
        trace_index,
        adapter_version,
        path,
        source_settings,
        expression,
        discriminator,
        inference,
        %{
          target_kind: :text,
          value_kind: :field,
          scope: :collection_item,
          value_key: value_key,
          collection_binding_id: collection_id,
          modifier_status: modifier_status,
          normalization_status: normalization_status
        },
        %{}
      )

    diagnostics =
      if normalization_status == :evidence_insufficient do
        [
          binding_diagnostic(
            "bricks.binding.evidence_insufficient",
            element,
            path,
            expression,
            "Bricks post content modifier semantics are unproven"
          )
        ]
      else
        []
      end

    {[candidate], true, diagnostics}
  end

  defp classify_dynamic_image(
         %Element{name: "image"} = element,
         collection_id,
         trace_index,
         adapter_version
       ) do
    image = Map.get(element.settings, "image")
    expression = if is_map(image), do: Map.get(image, "useDynamicData"), else: nil

    if non_empty_declaration?(expression) do
      case expression do
        "{featured_image}" ->
          if is_binary(collection_id) do
            candidate =
              value_candidate(
                element,
                trace_index,
                adapter_version,
                "image.useDynamicData",
                %{"image" => image},
                expression,
                "image.featured_image",
                "closed Bricks image form maps to media.primary",
                %{
                  target_kind: :asset,
                  value_kind: :field,
                  scope: :collection_item,
                  value_key: "media.primary",
                  collection_binding_id: collection_id,
                  modifier_status: :none,
                  normalization_status: :normalized
                },
                %{}
              )

            {[candidate], true, []}
          else
            diagnostic =
              binding_diagnostic(
                "bricks.binding.evidence_insufficient",
                element,
                "image.useDynamicData",
                expression,
                "featured image token has no admitted collection context"
              )

            {[], true, [diagnostic]}
          end

        "{post_id}" ->
          diagnostic =
            binding_diagnostic(
              "bricks.binding.evidence_insufficient",
              element,
              "image.useDynamicData",
              expression,
              "post ID evidence does not prove a frontend asset value"
            )

          {[], true, [diagnostic]}

        _unsupported_expression ->
          diagnostic =
            binding_diagnostic(
              "bricks.binding.expression_unsupported",
              element,
              "image.useDynamicData",
              expression,
              "Bricks image expression is outside the closed binding classifier"
            )

          {[], true, [diagnostic]}
      end
    else
      {[], false, []}
    end
  end

  defp classify_dynamic_image(%Element{}, _collection_id, _trace_index, _adapter_version),
    do: {[], false, []}

  defp classify_dynamic_url(element, trace_index, adapter_version) do
    url = Map.get(element.settings, "url")
    expression = if is_map(url), do: Map.get(url, "useDynamicData"), else: nil

    if non_empty_declaration?(expression) do
      case expression do
        "{site_url}" ->
          candidate =
            value_candidate(
              element,
              trace_index,
              adapter_version,
              "url.useDynamicData",
              %{"url" => url},
              expression,
              "url.site_url",
              "closed Bricks URL form maps to the site-scoped site.url value",
              %{
                target_kind: :link_url,
                value_kind: :field,
                scope: :site,
                value_key: "site.url",
                collection_binding_id: nil,
                modifier_status: :none,
                normalization_status: :normalized
              },
              %{}
            )

          {[candidate], true, true, []}

        _unsupported_expression ->
          diagnostic =
            binding_diagnostic(
              "bricks.binding.expression_unsupported",
              element,
              "url.useDynamicData",
              expression,
              "Bricks URL expression is outside the closed binding classifier"
            )

          {[], true, false, [diagnostic]}
      end
    else
      {[], false, false, []}
    end
  end

  defp classify_dynamic_alt_text(element) do
    case Map.get(element.settings, "altText") do
      "{site_title} Logo" = expression ->
        [
          binding_diagnostic(
            "bricks.binding.target_unsupported",
            element,
            "altText",
            expression,
            "Bricks alt text has no authorized Design IR binding target"
          )
        ]

      _other ->
        []
    end
  end

  defp value_candidate(
         element,
         trace_index,
         adapter_version,
         setting_path,
         source_settings,
         raw_expression,
         discriminator,
         inference,
         binding_fields,
         extra_metadata
       ) do
    trace =
      value_trace(
        element,
        trace_index,
        adapter_version,
        setting_path,
        source_settings,
        raw_expression,
        discriminator,
        inference,
        extra_metadata
      )

    %{
      target_node_id: Map.fetch!(trace_index, element.id).node_id,
      target_kind: binding_fields.target_kind,
      source_path: trace.source_path,
      raw_expression: raw_expression,
      discriminator: discriminator,
      binding_fields: Map.put(binding_fields, :source_trace, trace)
    }
  end

  defp value_trace(
         element,
         trace_index,
         adapter_version,
         setting_path,
         source_settings,
         raw_expression,
         discriminator,
         inference,
         extra_metadata
       ) do
    base = Map.fetch!(trace_index, element.id).trace

    metadata =
      %{
        "ir_path" => Map.get(base.metadata, "ir_path"),
        "classification" => discriminator,
        "raw_expression" => json_safe(raw_expression)
      }
      |> Map.merge(extra_metadata)
      |> json_safe()

    %SourceTrace{
      source_type: "bricks_value_binding",
      source_id: element.id,
      source_path: base.source_path <> ".settings." <> setting_path,
      source_name: setting_path,
      source_classes: base.source_classes,
      source_settings: json_safe(source_settings),
      adapter: "bricks",
      adapter_version: adapter_version,
      inference: inference,
      metadata: metadata
    }
  end

  defp binding_diagnostic(code, element, setting_path, raw_value, message) do
    Diagnostic.new(
      code: code,
      severity: :warning,
      source_id: element.id,
      source_path: setting_path,
      raw_value: raw_value,
      message: message,
      metadata: %{"target_path" => "settings." <> setting_path}
    )
  end

  defp assign_value_binding_ids(candidates) do
    candidates
    |> Enum.reduce({%{}, %{}}, fn candidate, {bindings, ordinals} ->
      group = {candidate.target_node_id, candidate.target_kind}
      ordinal = Map.get(ordinals, group, 0) + 1
      target_kind = Atom.to_string(candidate.target_kind)
      ordinal_text = Integer.to_string(ordinal) |> String.pad_leading(6, "0")
      id = "vb_#{candidate.target_node_id}_#{target_kind}_#{ordinal_text}"

      binding =
        struct(
          ValueBinding,
          Map.merge(candidate.binding_fields, %{
            value_binding_id: id,
            target_node_id: candidate.target_node_id
          })
        )

      {Map.put(bindings, id, binding), Map.put(ordinals, group, ordinal)}
    end)
  end

  defp candidate_order_key(candidate) do
    {
      candidate.source_path,
      candidate.raw_expression,
      candidate.discriminator
    }
  end

  defp known_text_token_occurs?(text) do
    Enum.any?(@known_text_tokens, &String.contains?(text, &1)) or
      Regex.match?(@query_count_occurrence, text)
  end

  defp brace_syntax?(text), do: String.contains?(text, ["{", "}"])

  defp non_empty_declaration?(value), do: value not in [nil, false, ""]

  defp maybe_put_action(actions, _key, false), do: actions
  defp maybe_put_action(actions, key, true), do: Map.put(actions, key, true)

  defp has_structural_child?(source_id, tree, trace_index) do
    tree.children_by_id
    |> Map.get(source_id, [])
    |> Enum.any?(fn child_id ->
      Map.has_key?(trace_index, child_id) and Map.get(tree.parent_by_id, child_id) == source_id
    end)
  end

  defp collection_trace(element, query, parent_binding_id, trace_index, adapter_version) do
    base = Map.fetch!(trace_index, element.id).trace

    %SourceTrace{
      source_type: "bricks_collection_binding",
      source_id: element.id,
      source_path: base.source_path <> ".settings.query",
      source_name: "query",
      source_classes: base.source_classes,
      source_settings:
        json_safe(%{"query" => query, "hasLoop" => Map.get(element.settings, "hasLoop")}),
      adapter: "bricks",
      adapter_version: adapter_version,
      inference: "query and hasLoop with a structurally linked child prove a repeat boundary",
      metadata:
        %{
          "ir_path" => Map.get(base.metadata, "ir_path"),
          "classification" => "collection_repeat_boundary",
          "parent_collection_binding_id" => parent_binding_id
        }
        |> json_safe()
    }
  end

  defp unproven_boundary_diagnostic(element, query, true) do
    Diagnostic.new(
      code: "bricks.collection.boundary_unproven",
      severity: :warning,
      source_id: element.id,
      source_path: "query",
      raw_value: query,
      message: "Bricks query settings do not prove a frontend repeat boundary",
      metadata: %{
        "has_loop" => Map.get(element.settings, "hasLoop"),
        "query_is_object" => json_object?(query)
      }
    )
  end

  defp unproven_boundary_diagnostic(element, _query, false) do
    Diagnostic.new(
      code: "bricks.collection.boundary_unproven",
      severity: :warning,
      source_id: element.id,
      source_path: "hasLoop",
      raw_value: Map.get(element.settings, "hasLoop"),
      message: "Bricks loop settings lack a query object for a frontend repeat boundary",
      metadata: %{"query_is_object" => false}
    )
  end

  defp json_object?(value) when is_map(value) and not is_struct(value), do: true
  defp json_object?(_value), do: false

  defp json_safe(nil), do: nil
  defp json_safe(value) when is_binary(value) or is_boolean(value), do: value
  defp json_safe(value) when is_integer(value) or is_float(value), do: value
  defp json_safe(value) when is_atom(value), do: Atom.to_string(value)
  defp json_safe(value) when is_list(value), do: Enum.map(value, &json_safe/1)

  defp json_safe(value) when is_map(value) do
    value = if is_struct(value), do: Map.from_struct(value), else: value
    Map.new(value, fn {key, nested} -> {json_key(key), json_safe(nested)} end)
  end

  defp json_safe(value), do: inspect(value)

  defp json_key(key) when is_binary(key), do: key
  defp json_key(key) when is_atom(key) and key not in [nil, true, false], do: Atom.to_string(key)
  defp json_key(key), do: inspect(key)
end
