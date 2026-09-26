defmodule LiveFrames.Adapters.Bricks.StaticSemantics do
  @moduledoc """
  Normalizes Bricks native tags and the small, safe source-attribute subset.

  `normalize/1` returns only values accepted by the fixed static markup
  contract. The normalizer separately preserves established evidence keys.
  """

  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Element
  alias LiveFrames.StaticMarkupContract

  @source_setting_names ["tag", "customTag", "_attributes", "ariaLabel"]

  @spec source_setting_names() :: [String.t()]
  def source_setting_names, do: @source_setting_names

  @spec normalize(Element.t()) :: map()
  def normalize(%Element{} = element) do
    {native_tag, tag_decision, tag_diagnostics} = normalize_tag(element)
    attribute_tag = attribute_tag(element, native_tag, tag_decision)
    {source_attributes, attribute_diagnostics} = normalize_attributes(element, attribute_tag)

    node_attributes =
      if is_binary(native_tag),
        do: Map.put(source_attributes, "tag", native_tag),
        else: source_attributes

    diagnostics = tag_diagnostics ++ attribute_diagnostics

    trace_metadata =
      if trace_metadata_required?(element, native_tag, source_attributes, diagnostics) do
        %{
          "decision" => tag_decision,
          "native_tag" => native_tag,
          "attributes" => source_attributes |> Map.keys() |> Enum.sort()
        }
      end

    %{
      native_tag: native_tag,
      attributes: node_attributes,
      diagnostics: diagnostics,
      trace_metadata: trace_metadata
    }
  end

  defp attribute_tag(%Element{name: "button"}, nil, "semantic_default"), do: "button"
  defp attribute_tag(_element, native_tag, _decision), do: native_tag

  defp trace_metadata_required?(element, native_tag, attributes, diagnostics) do
    diagnostics != [] or map_size(attributes) > 0 or
      (is_binary(native_tag) and not legacy_native_tag?(element.name, native_tag))
  end

  defp legacy_native_tag?("heading", tag), do: tag in ~w(h1 h2 h3 h4 h5 h6)
  defp legacy_native_tag?("text-basic", "p"), do: true
  defp legacy_native_tag?("image", "figure"), do: true
  defp legacy_native_tag?("section", "section"), do: true
  defp legacy_native_tag?("container", "div"), do: true
  defp legacy_native_tag?("div", "div"), do: true
  defp legacy_native_tag?("button", "button"), do: true
  defp legacy_native_tag?(_element_name, _native_tag), do: false

  defp normalize_tag(%Element{id: source_id, settings: settings}) do
    tag_present? = Map.has_key?(settings, "tag")
    custom_tag_present? = Map.has_key?(settings, "customTag")
    tag = Map.get(settings, "tag")
    custom_tag = Map.get(settings, "customTag")

    cond do
      not tag_present? and not custom_tag_present? ->
        {nil, "semantic_default", []}

      tag == "custom" and custom_tag_present? and
          StaticMarkupContract.native_tag?(custom_tag) ->
        {custom_tag, "customTag", []}

      tag == "custom" ->
        diagnostic =
          tag_diagnostic(
            "bricks.tag.unsupported",
            source_id,
            "customTag",
            custom_tag,
            "Bricks customTag did not name an approved native HTML tag"
          )

        {nil, "safe_fallback", [diagnostic]}

      tag_present? and custom_tag_present? ->
        diagnostic =
          Diagnostic.new(
            code: "bricks.tag.conflict",
            severity: :warning,
            source_id: source_id,
            source_path: "customTag",
            raw_value: %{"tag" => tag, "customTag" => custom_tag},
            message: "Bricks tag and customTag did not establish an unambiguous native tag",
            metadata: %{"tag" => tag, "customTag" => custom_tag}
          )

        {nil, "safe_fallback", [diagnostic]}

      custom_tag_present? ->
        diagnostic =
          tag_diagnostic(
            "bricks.tag.unsupported",
            source_id,
            "customTag",
            custom_tag,
            "Bricks customTag requires the proven custom tag marker"
          )

        {nil, "safe_fallback", [diagnostic]}

      StaticMarkupContract.native_tag?(tag) ->
        {tag, "tag", []}

      true ->
        diagnostic =
          tag_diagnostic(
            "bricks.tag.unsupported",
            source_id,
            "tag",
            tag,
            "Bricks tag did not name an approved native HTML tag"
          )

        {nil, "safe_fallback", [diagnostic]}
    end
  end

  defp normalize_attributes(%Element{id: source_id, settings: settings}, native_tag) do
    events =
      case Map.fetch(settings, "_attributes") do
        :error ->
          []

        {:ok, entries} when is_list(entries) ->
          entries
          |> Enum.with_index()
          |> Enum.flat_map(fn {entry, index} ->
            attribute_events(entry, index, source_id, native_tag)
          end)

        {:ok, value} ->
          [
            {:diagnostic,
             attribute_diagnostic(
               "bricks.attribute.unsupported",
               source_id,
               "_attributes",
               value,
               "Bricks _attributes must be a list"
             )}
          ]
      end

    events =
      case Map.fetch(settings, "ariaLabel") do
        :error -> events
        {:ok, value} -> events ++ aria_label_event(value, source_id, native_tag)
      end

    apply_attribute_events(events, %{}, MapSet.new(), [], source_id)
    |> then(fn {attributes, _blocked, diagnostics} -> {attributes, diagnostics} end)
  end

  defp attribute_events(entry, index, source_id, native_tag) when is_map(entry) do
    path = "_attributes[#{index}]"
    name = Map.get(entry, "name")

    if StaticMarkupContract.safe_attribute_name?(name, native_tag) do
      case source_attribute_value(entry, name, native_tag) do
        {:ok, value} ->
          [{:candidate, name, value, path <> ".value"}]

        {:error, value, message} ->
          [
            {:invalid, name,
             attribute_diagnostic(
               "bricks.attribute.unsupported",
               source_id,
               path <> ".value",
               value,
               message,
               %{"attribute_name" => name}
             )}
          ]
      end
    else
      [
        {:diagnostic,
         attribute_diagnostic(
           "bricks.attribute.unsupported",
           source_id,
           path <> ".name",
           name,
           "Bricks source attribute name is outside the static allowlist",
           %{"attribute_name" => name}
         )}
      ]
    end
  end

  defp attribute_events(entry, index, source_id, _native_tag) do
    [
      {:diagnostic,
       attribute_diagnostic(
         "bricks.attribute.unsupported",
         source_id,
         "_attributes[#{index}]",
         entry,
         "Bricks source attribute entry must be an object"
       )}
    ]
  end

  defp source_attribute_value(entry, name, native_tag) do
    case Map.fetch(entry, "value") do
      {:ok, value} ->
        if StaticMarkupContract.safe_attribute?(name, value, native_tag) do
          {:ok, value}
        else
          {:error, value, "Bricks source attribute value was not a safe static string"}
        end

      :error ->
        if is_binary(name) and String.starts_with?(name, "data-") do
          {:ok, ""}
        else
          {:error, nil, "Bricks source attribute requires a static string value"}
        end
    end
  end

  defp aria_label_event(value, source_id, native_tag) do
    if StaticMarkupContract.safe_attribute?("aria-label", value, native_tag) do
      [{:candidate, "aria-label", value, "ariaLabel"}]
    else
      [
        {:invalid, "aria-label",
         attribute_diagnostic(
           "bricks.attribute.unsupported",
           source_id,
           "ariaLabel",
           value,
           "Bricks ariaLabel must be a safe static string",
           %{"attribute_name" => "aria-label"}
         )}
      ]
    end
  end

  defp apply_attribute_events(events, attributes, blocked, diagnostics, source_id) do
    Enum.reduce(events, {attributes, blocked, diagnostics}, fn
      {:candidate, name, value, path}, {attributes, blocked, diagnostics} ->
        cond do
          MapSet.member?(blocked, name) ->
            {attributes, blocked, diagnostics}

          not Map.has_key?(attributes, name) ->
            {Map.put(attributes, name, value), blocked, diagnostics}

          Map.fetch!(attributes, name) == value ->
            {attributes, blocked, diagnostics}

          true ->
            existing_value = Map.fetch!(attributes, name)
            attributes = Map.delete(attributes, name)
            blocked = MapSet.put(blocked, name)

            diagnostic =
              Diagnostic.new(
                code: "bricks.attribute.conflict",
                severity: :warning,
                source_id: source_id,
                source_path: path,
                raw_value: %{"attribute" => name, "values" => [existing_value, value]},
                message: "Bricks source attributes contained conflicting values",
                metadata: %{"attribute_name" => name}
              )

            {attributes, blocked, diagnostics ++ [diagnostic]}
        end

      {:invalid, name, diagnostic}, {attributes, blocked, diagnostics} ->
        attributes = Map.delete(attributes, name)
        {attributes, MapSet.put(blocked, name), diagnostics ++ [diagnostic]}

      {:diagnostic, diagnostic}, {attributes, blocked, diagnostics} ->
        {attributes, blocked, diagnostics ++ [diagnostic]}
    end)
  end

  defp tag_diagnostic(code, source_id, source_path, value, message) do
    Diagnostic.new(
      code: code,
      severity: :warning,
      source_id: source_id,
      source_path: source_path,
      raw_value: value,
      message: message
    )
  end

  defp attribute_diagnostic(code, source_id, source_path, value, message, metadata \\ %{}) do
    Diagnostic.new(
      code: code,
      severity: :warning,
      source_id: source_id,
      source_path: source_path,
      raw_value: value,
      message: message,
      metadata: metadata
    )
  end
end
