defmodule LiveFrames.Adapters.Bricks.StaticNavigation do
  @moduledoc """
  Corpus-backed Bricks static navigation normalization for Design IR attributes.

  Navigation carriers are limited to proven source forms (`text-link`, `button` with
  a static `link` object). Raw `link`/`url` evidence is preserved separately.
  """

  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Element
  alias LiveFrames.StaticNavigation

  @type normalization :: %{
          optional(:semantic_type_override) => String.t(),
          optional(:navigation) => map(),
          diagnostics: [Diagnostic.t()],
          trace_metadata: map() | nil
        }

  @spec normalize_tree(LiveFrames.Adapters.Bricks.Tree.t()) ::
          {%{String.t() => normalization()}, [Diagnostic.t()]}
  def normalize_tree(tree) do
    Enum.reduce(tree.ordered_elements, {%{}, []}, fn element, {by_id, diagnostics} ->
      normalization = normalize(element)
      {Map.put(by_id, element.id, normalization), diagnostics ++ normalization.diagnostics}
    end)
  end

  @spec normalize(Element.t()) :: normalization()
  def normalize(%Element{} = element) do
    case navigation_carrier?(element) do
      false ->
        %{
          diagnostics: carrier_diagnostics(element),
          trace_metadata: non_carrier_trace_metadata(element)
        }

      true ->
        case resolve_destination(element) do
          {:ok, href, target, duplicate} when is_boolean(duplicate) ->
            navigation = build_navigation_map(href, target)

            %{
              semantic_type_override: semantic_type_override(element),
              navigation: navigation,
              diagnostics: [],
              trace_metadata:
                trace_metadata(
                  element,
                  if(duplicate, do: :accepted_duplicate, else: :accepted),
                  navigation,
                  if(duplicate, do: %{"note" => "equivalent link evidence collapsed"}, else: nil)
                )
            }

          {:conflict, representations} ->
            %{
              diagnostics: [conflict_diagnostic(element, representations)],
              trace_metadata: trace_metadata(element, :conflict, nil, representations)
            }

          {:dynamic, evidence} ->
            %{
              diagnostics: [dynamic_diagnostic(element, evidence)],
              trace_metadata: trace_metadata(element, :dynamic, nil, evidence)
            }

          {:rejected, reason, raw} ->
            %{
              diagnostics: [rejected_diagnostic(element, reason, raw)],
              trace_metadata: trace_metadata(element, reason, nil, raw)
            }

          :none ->
            %{
              diagnostics: [missing_diagnostic(element)],
              trace_metadata: trace_metadata(element, :missing, nil, nil)
            }
        end
    end
  end

  defp navigation_carrier?(%Element{name: name, settings: settings}) do
    cond do
      name == "text-link" ->
        true

      name == "button" and link_object?(settings["link"]) ->
        true

      true ->
        false
    end
  end

  defp non_carrier_trace_metadata(%Element{name: "heading", settings: settings} = element) do
    if link_object?(settings["link"]) do
      trace_metadata(element, :unsupported_carrier, nil, settings["link"])
    else
      nil
    end
  end

  defp non_carrier_trace_metadata(_element), do: nil

  defp carrier_diagnostics(%Element{id: source_id, name: name, settings: settings}) do
    if name == "heading" and link_object?(settings["link"]) do
      [
        Diagnostic.new(
          code: "bricks.navigation.unsupported_carrier",
          severity: :warning,
          source_id: source_id,
          source_path: "link",
          raw_value: settings["link"],
          message:
            "Bricks heading link settings do not establish safe native navigation markup in C-04A",
          metadata: %{"element_name" => name}
        )
      ]
    else
      []
    end
  end

  defp resolve_destination(%Element{settings: settings}) do
    link_value = Map.get(settings, "link")
    url_value = Map.get(settings, "url")

    link_dest = destination_from_link(link_value)
    url_dest = destination_from_url(url_value)

    case {link_dest, url_dest} do
      {:dynamic, _} ->
        {:dynamic, %{"link" => link_value, "url" => url_value}}

      {_, :dynamic} ->
        {:dynamic, %{"link" => link_value, "url" => url_value}}

      {:mode_url, :dynamic} ->
        {:dynamic, %{"link" => link_value, "url" => url_value}}

      {{:link_object, type, href}, {:settings_url, secondary}} ->
        compare_destinations(type, href, secondary)

      {{:link_object, type, href}, _} ->
        finalize_link_object(type, href, false)

      _ ->
        :none
    end
  end

  defp compare_destinations(type, href_a, href_b) do
    if not corpus_link_type?(type) do
      {:rejected, :unsupported_link_type, %{"type" => type, "url" => href_a}}
    else
      if href_a == href_b do
        finalize_link_object(type, href_a, true)
      else
        {:conflict, %{"link" => href_a, "url" => href_b}}
      end
    end
  end

  defp finalize_link_object(type, href, duplicate?) do
    if not corpus_link_type?(type) do
      {:rejected, :unsupported_link_type, %{"type" => type, "url" => href}}
    else
      case StaticNavigation.classify_destination(href) do
        :safe -> {:ok, href, nil, duplicate?}
        :unsafe -> {:rejected, :unsafe_destination, href}
        :dynamic -> {:dynamic, %{"url" => href}}
        :malformed -> {:rejected, :malformed_destination, href}
      end
    end
  end

  defp destination_from_link(%{"type" => type, "url" => url}) when is_binary(url),
    do: {:link_object, type, url}

  defp destination_from_link(%{"useDynamicData" => _expression}), do: :dynamic
  defp destination_from_link("url"), do: :mode_url
  defp destination_from_link("lightbox"), do: :not_navigation
  defp destination_from_link(_value), do: :none

  defp destination_from_url(url) when is_binary(url), do: {:settings_url, url}

  defp destination_from_url(%{"type" => "meta", "useDynamicData" => _expression}), do: :dynamic
  defp destination_from_url(%{"useDynamicData" => _expression}), do: :dynamic
  defp destination_from_url(_value), do: :none

  defp link_object?(value), do: is_map(value) and Map.has_key?(value, "url")

  defp corpus_link_type?("external"), do: true
  defp corpus_link_type?(_type), do: false

  defp semantic_type_override(%Element{name: "text-link"}), do: "link"
  defp semantic_type_override(%Element{name: "button"}), do: nil

  defp build_navigation_map(href, target) do
    base = %{"href" => href}

    if target == "_blank" do
      Map.put(base, "target", "_blank")
    else
      base
    end
  end

  defp trace_metadata(element, decision, navigation, extra) do
    %{
      "source_element" => element.name,
      "decision" => Atom.to_string(decision),
      "navigation" => navigation,
      "evidence" => extra
    }
  end

  defp conflict_diagnostic(element, representations) do
    Diagnostic.new(
      code: "bricks.navigation.conflict",
      severity: :warning,
      source_id: element.id,
      source_path: "link",
      raw_value: representations,
      message: "Bricks link and url settings disagreed on the static destination",
      metadata: %{"element_name" => element.name}
    )
  end

  defp dynamic_diagnostic(element, evidence) do
    Diagnostic.new(
      code: "bricks.navigation.dynamic",
      severity: :warning,
      source_id: element.id,
      source_path: "link",
      raw_value: evidence,
      message: "Bricks navigation destination requires runtime binding and was not emitted",
      metadata: %{"element_name" => element.name}
    )
  end

  defp rejected_diagnostic(element, reason, raw) do
    Diagnostic.new(
      code: "bricks.navigation.rejected",
      severity: :warning,
      source_id: element.id,
      source_path: "link.url",
      raw_value: raw,
      message: rejected_message(reason),
      metadata: %{"element_name" => element.name, "reason" => Atom.to_string(reason)}
    )
  end

  defp missing_diagnostic(element) do
    Diagnostic.new(
      code: "bricks.navigation.missing",
      severity: :warning,
      source_id: element.id,
      source_path: "link",
      raw_value: nil,
      message: "Bricks navigation carrier did not provide a static destination",
      metadata: %{"element_name" => element.name}
    )
  end

  defp rejected_message(:unsafe_destination),
    do: "Bricks navigation destination used a forbidden URL scheme"

  defp rejected_message(:malformed_destination),
    do: "Bricks navigation destination was not a proven static URL form"

  defp rejected_message(:unsupported_link_type),
    do: "Bricks link type was outside the corpus-proven static navigation set"

  defp rejected_message(reason), do: "Bricks navigation destination was rejected (#{reason})"
end
