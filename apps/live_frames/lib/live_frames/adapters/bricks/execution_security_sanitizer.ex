defmodule LiveFrames.Adapters.Bricks.ExecutionSecuritySanitizer do
  @moduledoc false

  alias LiveFrames.Adapters.Bricks.Component
  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Document
  alias LiveFrames.Adapters.Bricks.Element

  @unclassified_signature_code "bricks.execution_security.unclassified_signature"
  @unclassified_signature_message "Bricks execution security metadata could not be sanitized"

  @spec sanitize(Document.t()) :: {:ok, Document.t()} | {:error, [Diagnostic.t()]}
  def sanitize(%Document{components: components} = document) when is_map(components) do
    with {:ok, sanitized_components} <- sanitize_components(components) do
      sanitized_raw =
        sanitize_document_raw(document.raw, sanitized_components, document.component_order)

      candidate = %{document | components: sanitized_components, raw: sanitized_raw}

      if contains_signature_key?(candidate) do
        {:error, [unclassified_signature_diagnostic()]}
      else
        {:ok, candidate}
      end
    end
  end

  defp sanitize_components(components) do
    Enum.reduce_while(components, {:ok, %{}}, fn {id, component}, {:ok, sanitized} ->
      case sanitize_component(component) do
        {:ok, sanitized_component} ->
          {:cont, {:ok, Map.put(sanitized, id, sanitized_component)}}

        {:error, diagnostics} ->
          {:halt, {:error, diagnostics}}
      end
    end)
  end

  defp sanitize_component(%Component{elements: elements} = component) when is_list(elements) do
    case sanitize_elements(elements) do
      {:ok, sanitized_elements} ->
        sanitized_raw = sanitize_component_raw(component.raw, sanitized_elements)

        {:ok, %{component | elements: sanitized_elements, raw: sanitized_raw}}

      {:error, diagnostics} ->
        {:error, diagnostics}
    end
  end

  defp sanitize_elements(elements) do
    Enum.reduce_while(elements, {:ok, []}, fn element, {:ok, sanitized} ->
      case sanitize_element(element) do
        {:ok, sanitized_element} ->
          {:cont, {:ok, [sanitized_element | sanitized]}}

        {:error, diagnostics} ->
          {:halt, {:error, diagnostics}}
      end
    end)
    |> case do
      {:ok, sanitized} -> {:ok, Enum.reverse(sanitized)}
      {:error, diagnostics} -> {:error, diagnostics}
    end
  end

  defp sanitize_element(element) do
    with {:ok, code_sanitized} <- sanitize_code_element(element),
         {:ok, query_sanitized} <- sanitize_query_element(code_sanitized) do
      sanitized_raw = sanitize_element_raw(element.raw, element)
      {:ok, %{query_sanitized | raw: sanitized_raw}}
    end
  end

  defp sanitize_element_raw(raw, %Element{} = element) when is_map(raw) do
    case Map.get(raw, "settings") do
      settings when is_map(settings) ->
        Map.put(raw, "settings", sanitize_raw_settings(settings, element))

      _settings ->
        raw
    end
  end

  defp sanitize_element_raw(raw, _element), do: raw

  defp sanitize_raw_settings(settings, element) do
    settings =
      if admitted_code_body?(element) do
        settings = Map.delete(settings, "code")

        if admitted_code_signature?(element) do
          Map.delete(settings, "signature")
        else
          settings
        end
      else
        settings
      end

    if admitted_query_body?(element) do
      case Map.get(settings, "query") do
        query when is_map(query) ->
          sanitized_query = Map.delete(query, "queryEditor")

          sanitized_query =
            if admitted_query_signature?(element),
              do: Map.delete(sanitized_query, "signature"),
              else: sanitized_query

          Map.put(settings, "query", sanitized_query)

        _query ->
          settings
      end
    else
      settings
    end
  end

  defp sanitize_component_raw(raw, elements) when is_map(raw) do
    case Map.get(raw, "elements") do
      raw_elements when is_list(raw_elements) and length(raw_elements) == length(elements) ->
        Map.put(raw, "elements", Enum.map(elements, & &1.raw))

      _raw_elements ->
        raw
    end
  end

  defp sanitize_component_raw(raw, _elements), do: raw

  defp sanitize_document_raw(raw, components, component_order)
       when is_map(raw) and is_list(component_order) do
    case Map.get(raw, "components") do
      raw_components
      when is_list(raw_components) and length(raw_components) == length(component_order) ->
        sanitized_components =
          Enum.map(component_order, fn id -> Map.fetch!(components, id).raw end)

        Map.put(raw, "components", sanitized_components)

      _raw_components ->
        raw
    end
  end

  defp sanitize_document_raw(raw, _components, _component_order), do: raw

  defp admitted_code_body?(%Element{name: "code", settings: settings}) when is_map(settings),
    do: Map.get(settings, "executeCode") == true and is_binary(Map.get(settings, "code"))

  defp admitted_code_body?(_element), do: false

  defp admitted_code_signature?(%Element{settings: settings} = element) do
    admitted_code_body?(element) and valid_signature?(Map.get(settings, "signature"))
  end

  defp admitted_query_body?(%Element{settings: settings}) when is_map(settings) do
    case Map.get(settings, "query") do
      %{"useQueryEditor" => true, "queryEditor" => body} -> is_binary(body)
      _query -> false
    end
  end

  defp admitted_query_body?(_element), do: false

  defp admitted_query_signature?(%Element{settings: settings} = element) do
    admitted_query_body?(element) and
      case Map.get(settings, "query") do
        query when is_map(query) -> valid_signature?(Map.get(query, "signature"))
        _query -> false
      end
  end

  defp sanitize_code_element(%Element{name: "code", settings: settings} = element)
       when is_map(settings) do
    execution_like? = Map.get(settings, "executeCode") == true
    code_body? = execution_like? and is_binary(Map.get(settings, "code"))
    signature_present? = Map.has_key?(settings, "signature")
    valid_signature? = code_body? and valid_signature?(Map.get(settings, "signature"))

    cond do
      execution_like? and signature_present? and not valid_signature? ->
        {:error, [unclassified_signature_diagnostic()]}

      code_body? ->
        sanitized_settings = Map.delete(settings, "code")

        sanitized_settings =
          if valid_signature?,
            do: Map.delete(sanitized_settings, "signature"),
            else: sanitized_settings

        {:ok, %{element | settings: sanitized_settings}}

      true ->
        {:ok, element}
    end
  end

  defp sanitize_code_element(element), do: {:ok, element}

  defp sanitize_query_element(%Element{settings: settings} = element) when is_map(settings) do
    case Map.get(settings, "query") do
      %{"useQueryEditor" => true} = query ->
        query_body? = is_binary(Map.get(query, "queryEditor"))
        signature_present? = Map.has_key?(query, "signature")
        valid_signature? = query_body? and valid_signature?(Map.get(query, "signature"))

        cond do
          signature_present? and not valid_signature? ->
            {:error, [unclassified_signature_diagnostic()]}

          query_body? ->
            sanitized_query = Map.delete(query, "queryEditor")

            sanitized_query =
              if valid_signature?,
                do: Map.delete(sanitized_query, "signature"),
                else: sanitized_query

            {:ok, %{element | settings: Map.put(settings, "query", sanitized_query)}}

          true ->
            {:ok, element}
        end

      _query ->
        {:ok, element}
    end
  end

  defp sanitize_query_element(element), do: {:ok, element}

  defp valid_signature?(signature),
    do: is_binary(signature) and byte_size(signature) == 32

  defp contains_signature_key?(%_{} = struct) do
    struct
    |> Map.from_struct()
    |> contains_signature_key?()
  end

  defp contains_signature_key?(map) when is_map(map) do
    Enum.any?(map, fn {key, value} ->
      key == "signature" or contains_signature_key?(value)
    end)
  end

  defp contains_signature_key?(list) when is_list(list),
    do: Enum.any?(list, &contains_signature_key?/1)

  defp contains_signature_key?(tuple) when is_tuple(tuple),
    do: tuple |> Tuple.to_list() |> contains_signature_key?()

  defp contains_signature_key?(_value), do: false

  defp unclassified_signature_diagnostic do
    Diagnostic.new(
      code: @unclassified_signature_code,
      message: @unclassified_signature_message
    )
  end
end
