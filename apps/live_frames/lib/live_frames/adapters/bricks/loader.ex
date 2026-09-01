defmodule LiveFrames.Adapters.Bricks.Loader do
  @moduledoc """
  Decodes and validates the small Bricks copied-elements envelope used by the
  source adapter.
  """

  alias LiveFrames.Adapters.Bricks.Component
  alias LiveFrames.Adapters.Bricks.ContentProxy
  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Document
  alias LiveFrames.Adapters.Bricks.Element
  alias LiveFrames.Adapters.Bricks.GlobalClass

  @source "bricksCopiedElements"
  @supported_payload_version "2.3.1"

  @spec from_file(term(), keyword()) ::
          {:ok, Document.t(), [Diagnostic.t()]} | {:error, [Diagnostic.t()]}
  def from_file(path, opts \\ [])

  def from_file(path, opts) when is_binary(path) or is_list(path) do
    case File.read(path) do
      {:ok, bytes} ->
        opts = Keyword.put_new(opts, :source_label, source_label(path))
        from_json(bytes, opts)

      {:error, reason} ->
        {:error,
         [
           diagnostic("bricks.source.invalid", "Bricks source file could not be read",
             metadata: %{"reason" => inspect(reason)}
           )
         ]}
    end
  end

  def from_file(_path, _opts),
    do: {:error, [diagnostic("bricks.source.invalid", "Bricks source path must be a string")]}

  @spec from_json(term(), keyword()) ::
          {:ok, Document.t(), [Diagnostic.t()]} | {:error, [Diagnostic.t()]}
  def from_json(json, opts \\ [])

  def from_json(json, opts) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, source} when is_map(source) ->
        recognize(source, Keyword.put(opts, :source_bytes, json))

      {:ok, _source} ->
        {:error, [diagnostic("bricks.source.invalid", "Bricks source must be a JSON object")]}

      {:error, reason} ->
        {:error,
         [
           diagnostic("bricks.source.json_invalid", "Bricks source JSON could not be decoded",
             metadata: %{"reason" => Exception.message(reason)}
           )
         ]}
    end
  end

  def from_json(_json, _opts),
    do: {:error, [diagnostic("bricks.source.json_invalid", "Bricks source must be JSON text")]}

  @spec recognize(term(), keyword()) ::
          {:ok, Document.t(), [Diagnostic.t()]} | {:error, [Diagnostic.t()]}
  def recognize(source, opts \\ [])

  def recognize(source, opts) when is_map(source) do
    with {:ok, envelope, diagnostics} <- validate_envelope(source, opts),
         {:ok, proxies, proxy_order} <- parse_proxies(Map.get(source, "content")),
         {:ok, components, component_order} <- parse_components(Map.get(source, "components")),
         {:ok, classes, class_order} <- parse_global_classes(Map.get(source, "globalClasses")) do
      bytes = Keyword.get(opts, :source_bytes, Jason.encode!(source))

      document = %Document{
        source: envelope.source,
        source_url: envelope.source_url,
        payload_version: envelope.payload_version,
        adapter_version: Document.adapter_version(),
        source_label: Keyword.get(opts, :source_label, "inline"),
        source_hash: hash(bytes),
        content_proxies: proxies,
        content_proxy_order: proxy_order,
        components: components,
        component_order: component_order,
        global_classes: classes,
        global_class_order: class_order,
        raw: source
      }

      {:ok, document, diagnostics}
    else
      {:error, diagnostics} -> {:error, sort_diagnostics(diagnostics)}
    end
  end

  def recognize(_source, _opts),
    do: {:error, [diagnostic("bricks.source.invalid", "Bricks source must be a JSON object")]}

  defp validate_envelope(source, opts) do
    fields = [
      {"source", &valid_string?/1, "source marker"},
      {"sourceUrl", &valid_string?/1, "source URL"},
      {"version", &valid_string?/1, "payload version"},
      {"content", &is_list/1, "content collection"},
      {"components", &is_list/1, "component collection"},
      {"globalClasses", &is_list/1, "global class collection"}
    ]

    invalid =
      Enum.flat_map(fields, fn {key, predicate, label} ->
        if predicate.(Map.get(source, key)) do
          []
        else
          [
            diagnostic("bricks.source.invalid", "Bricks #{label} has an invalid shape",
              source_path: key
            )
          ]
        end
      end)

    source_diagnostic =
      if Map.get(source, "source") == @source do
        []
      else
        [
          diagnostic("bricks.source.invalid", "Bricks copied-elements envelope is not recognized",
            raw_value: Map.get(source, "source")
          )
        ]
      end

    version_diagnostics =
      if Map.get(source, "version") == @supported_payload_version do
        []
      else
        version = Map.get(source, "version")

        if Keyword.get(opts, :allow_unknown_version, false) do
          [
            diagnostic(
              "bricks.source.version_unsupported",
              "Bricks payload version is outside the tested adapter contract",
              severity: :warning,
              raw_value: version
            )
          ]
        else
          [
            diagnostic(
              "bricks.source.version_unsupported",
              "Bricks payload version is outside the tested adapter contract",
              severity: :error,
              raw_value: version
            )
          ]
        end
      end

    diagnostics = invalid ++ source_diagnostic ++ version_diagnostics

    if Enum.any?(diagnostics, &(&1.severity in [:error, :fatal])) do
      {:error, diagnostics}
    else
      {:ok,
       %{
         source: Map.get(source, "source"),
         source_url: Map.get(source, "sourceUrl"),
         payload_version: Map.get(source, "version")
       }, diagnostics}
    end
  end

  defp parse_proxies(proxies) when is_list(proxies) do
    {parsed, order, diagnostics} =
      Enum.with_index(proxies)
      |> Enum.reduce({%{}, [], []}, fn {raw, index}, {acc, order, diagnostics} ->
        case parse_proxy(raw, index) do
          {:ok, proxy} ->
            if Map.has_key?(acc, proxy.id) do
              {acc, order,
               diagnostics ++
                 [
                   diagnostic("bricks.proxy.duplicate", "Content proxy ID is duplicated",
                     source_id: proxy.id
                   )
                 ]}
            else
              {Map.put(acc, proxy.id, proxy), order ++ [proxy.id], diagnostics}
            end

          {:error, errors} ->
            {acc, order, diagnostics ++ errors}
        end
      end)

    if Enum.any?(diagnostics, &(&1.severity in [:error, :fatal])),
      do: {:error, diagnostics},
      else: {:ok, parsed, order}
  end

  defp parse_proxies(_),
    do: {:error, [diagnostic("bricks.source.invalid", "Content collection is invalid")]}

  defp parse_proxy(raw, index) when is_map(raw) do
    with {:ok, id} <- required_string(raw, "id", "bricks.proxy.invalid", index),
         {:ok, cid} <- required_string(raw, "cid", "bricks.component.cid_missing", index),
         {:ok, name} <- optional_string(raw, "name", "bricks.proxy.invalid", index),
         {:ok, label} <- optional_string(raw, "label", "bricks.proxy.invalid", index),
         {:ok, children} <- children_value(raw, index),
         {:ok, settings} <- settings_value(raw, index) do
      {:ok,
       %ContentProxy{
         id: id,
         name: name,
         parent: Map.get(raw, "parent"),
         children: children,
         settings: settings,
         label: label,
         cid: cid,
         raw: raw
       }}
    else
      {:error, diagnostic} -> {:error, [diagnostic]}
    end
  end

  defp parse_proxy(_raw, index),
    do:
      {:error,
       [
         diagnostic("bricks.proxy.invalid", "Content proxy must be an object",
           source_path: "content[#{index}]"
         )
       ]}

  defp parse_components(components) when is_list(components) do
    {parsed, order, diagnostics} =
      Enum.with_index(components)
      |> Enum.reduce({%{}, [], []}, fn {raw, index}, {acc, order, diagnostics} ->
        case parse_component(raw, index) do
          {:ok, component} ->
            if Map.has_key?(acc, component.id) do
              {acc, order,
               diagnostics ++
                 [
                   diagnostic("bricks.component.duplicate", "Component ID is duplicated",
                     source_id: component.id
                   )
                 ]}
            else
              {Map.put(acc, component.id, component), order ++ [component.id], diagnostics}
            end

          {:error, errors} ->
            {acc, order, diagnostics ++ errors}
        end
      end)

    if Enum.any?(diagnostics, &(&1.severity in [:error, :fatal])),
      do: {:error, diagnostics},
      else: {:ok, parsed, order}
  end

  defp parse_components(_),
    do: {:error, [diagnostic("bricks.source.invalid", "Component collection is invalid")]}

  defp parse_component(raw, index) when is_map(raw) do
    with {:ok, id} <- required_string(raw, "id", "bricks.component.invalid", index),
         {:ok, name} <- optional_string(raw, "name", "bricks.component.invalid", index),
         {:ok, category} <- optional_string(raw, "category", "bricks.component.invalid", index),
         {:ok, desc} <- optional_string(raw, "desc", "bricks.component.invalid", index),
         {:ok, elements} <- parse_elements(Map.get(raw, "elements"), index),
         {:ok, properties} <- properties_value(raw, index),
         {:ok, version} <- optional_string(raw, "_version", "bricks.component.invalid", index) do
      {:ok,
       %Component{
         id: id,
         name: name,
         category: category,
         description: desc,
         desc: desc,
         properties: properties,
         version: version,
         elements: elements,
         raw: raw
       }}
    else
      {:error, diagnostics} when is_list(diagnostics) -> {:error, diagnostics}
      {:error, diagnostic} -> {:error, [diagnostic]}
    end
  end

  defp parse_component(_raw, index),
    do:
      {:error,
       [
         diagnostic("bricks.component.invalid", "Component must be an object",
           source_path: "components[#{index}]"
         )
       ]}

  defp parse_elements(elements, index) when is_list(elements) do
    {parsed, diagnostics} =
      Enum.with_index(elements)
      |> Enum.reduce({[], []}, fn {raw, element_index}, {parsed, diagnostics} ->
        case parse_element(raw, index, element_index) do
          {:ok, element} -> {parsed ++ [element], diagnostics}
          {:error, errors} -> {parsed, diagnostics ++ errors}
        end
      end)

    if Enum.any?(diagnostics, &(&1.severity in [:error, :fatal])),
      do: {:error, diagnostics},
      else: {:ok, parsed}
  end

  defp parse_elements(_elements, index),
    do:
      {:error,
       [
         diagnostic("bricks.component.invalid", "Component elements must be a list",
           source_path: "components[#{index}].elements"
         )
       ]}

  defp parse_element(raw, component_index, element_index) when is_map(raw) do
    path = "components[#{component_index}].elements[#{element_index}]"

    with {:ok, id} <- required_string(raw, "id", "bricks.element.invalid", path),
         {:ok, name} <- required_string(raw, "name", "bricks.element.invalid", path),
         {:ok, label} <- optional_string(raw, "label", "bricks.element.invalid", path),
         {:ok, children} <- children_value(raw, path),
         {:ok, settings} <- settings_value(raw, path) do
      {:ok,
       %Element{
         id: id,
         name: name,
         parent: Map.get(raw, "parent"),
         children: children,
         settings: settings,
         label: label,
         source_index: element_index,
         raw: raw
       }}
    else
      {:error, diagnostic} -> {:error, [diagnostic]}
    end
  end

  defp parse_element(_raw, component_index, element_index),
    do:
      {:error,
       [
         diagnostic("bricks.element.invalid", "Element must be an object",
           source_path: "components[#{component_index}].elements[#{element_index}]"
         )
       ]}

  defp parse_global_classes(classes) when is_list(classes) do
    {parsed, order, diagnostics} =
      Enum.with_index(classes)
      |> Enum.reduce({%{}, [], []}, fn {raw, index}, {acc, order, diagnostics} ->
        case parse_global_class(raw, index) do
          {:ok, class} ->
            if Map.has_key?(acc, class.id) do
              {acc, order,
               diagnostics ++
                 [
                   diagnostic("bricks.class.duplicate", "Global class ID is duplicated",
                     source_id: class.id
                   )
                 ]}
            else
              {Map.put(acc, class.id, class), order ++ [class.id], diagnostics}
            end

          {:error, errors} ->
            {acc, order, diagnostics ++ errors}
        end
      end)

    if Enum.any?(diagnostics, &(&1.severity in [:error, :fatal])),
      do: {:error, diagnostics},
      else: {:ok, parsed, order}
  end

  defp parse_global_classes(_),
    do: {:error, [diagnostic("bricks.source.invalid", "Global class collection is invalid")]}

  defp parse_global_class(raw, index) when is_map(raw) do
    with {:ok, id} <- required_string(raw, "id", "bricks.class.invalid", index),
         {:ok, name} <- required_string(raw, "name", "bricks.class.invalid", index),
         {:ok, category} <- optional_string(raw, "category", "bricks.class.invalid", index),
         {:ok, settings} <- settings_value(raw, index) do
      {:ok,
       %GlobalClass{
         id: id,
         name: name,
         category: category,
         settings: settings,
         raw: raw
       }}
    else
      {:error, diagnostic} -> {:error, [diagnostic]}
    end
  end

  defp parse_global_class(_raw, index),
    do:
      {:error,
       [
         diagnostic("bricks.class.invalid", "Global class must be an object",
           source_path: "globalClasses[#{index}]"
         )
       ]}

  defp required_string(raw, key, code, path) do
    case Map.get(raw, key) do
      value when is_binary(value) and byte_size(value) > 0 ->
        {:ok, value}

      value ->
        {:error,
         diagnostic(code, "Bricks field must be a non-empty string",
           source_path: path_for(path, key),
           raw_value: value
         )}
    end
  end

  defp optional_string(raw, key, code, path) do
    case Map.get(raw, key) do
      nil ->
        {:ok, nil}

      value when is_binary(value) ->
        {:ok, value}

      value ->
        {:error,
         diagnostic(code, "Bricks optional field must be a string",
           source_path: path_for(path, key),
           raw_value: value
         )}
    end
  end

  defp children_value(raw, path) do
    case Map.get(raw, "children", []) do
      children when is_list(children) ->
        if Enum.all?(children, &(is_binary(&1) and byte_size(&1) > 0)) do
          {:ok, children}
        else
          {:error,
           diagnostic("bricks.element.invalid", "Bricks children must contain non-empty IDs",
             source_path: path_for(path, "children"),
             raw_value: children
           )}
        end

      value ->
        {:error,
         diagnostic("bricks.element.invalid", "Bricks children must be a list",
           source_path: path_for(path, "children"),
           raw_value: value
         )}
    end
  end

  defp settings_value(raw, path) do
    case Map.get(raw, "settings", %{}) do
      value when is_map(value) ->
        {:ok, value}

      [] ->
        {:ok, %{}}

      value ->
        {:error,
         diagnostic("bricks.setting.invalid", "Bricks settings must be an object",
           source_path: path_for(path, "settings"),
           raw_value: value
         )}
    end
  end

  defp properties_value(raw, path) do
    case Map.get(raw, "properties", []) do
      value when is_list(value) ->
        {:ok, value}

      value ->
        {:error,
         diagnostic("bricks.component.invalid", "Component properties must be a list",
           source_path: path_for(path, "properties"),
           raw_value: value
         )}
    end
  end

  defp valid_string?(value), do: is_binary(value) and byte_size(value) > 0

  defp path_for(index, key) when is_integer(index), do: "collection[#{index}].#{key}"
  defp path_for(path, key) when is_binary(path), do: "#{path}.#{key}"

  defp source_label(path) do
    path
    |> to_string()
    |> Path.basename()
  end

  defp hash(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

  defp diagnostic(code, message, opts \\ []),
    do: Diagnostic.new([code: code, message: message] ++ opts)

  defp sort_diagnostics(diagnostics) do
    Enum.sort_by(diagnostics, fn diagnostic ->
      {diagnostic.code || "", diagnostic.source_path || "", diagnostic.source_id || "",
       diagnostic.message || ""}
    end)
  end
end
