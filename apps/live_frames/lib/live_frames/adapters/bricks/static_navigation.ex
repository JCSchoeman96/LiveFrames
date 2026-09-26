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
          optional(:element_tag) => String.t(),
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
          trace_metadata: trace_metadata(element, :not_a_carrier, nil, nil)
        }

      true ->
        case resolve_destination(element) do
          {:ok, href, target} ->
            navigation = build_navigation_map(href, target)

            %{
              element_tag: "a",
              semantic_type_override: semantic_type_override(element),
              navigation: navigation,
              diagnostics: [],
              trace_metadata: trace_metadata(element, :accepted, navigation, nil)
            }

          {:duplicate, href} ->
            navigation = build_navigation_map(href, nil)

            %{
              element_tag: "a",
              semantic_type_override: semantic_type_override(element),
              navigation: navigation,
              diagnostics: [],
              trace_metadata:
                trace_metadata(element, :accepted_duplicate, navigation, %{
                  "note" => "equivalent link evidence collapsed"
                })
            }

          {:conflict, representations} ->
            %{
              diagnostics: [
                conflict_diagnostic(element, representations)
              ],
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

    cond do
      link_dest == :dynamic or url_dest == :dynamic ->
        {:dynamic, %{"link" => link_value, "url" => url_value}}

      link_dest == :mode_url and url_dest == :dynamic ->
        {:dynamic, %{"link" => link_value, "url" => url_value}}

      tuple_destination?(link_dest) and tuple_destination?(url_dest) ->
        compare_destinations(link_dest, url_dest)

      tuple_destination?(link_dest) ->
        finalize_destination(link_dest)

      tuple_destination?(url_dest) ->
        finalize_destination(url_dest)

      true ->
        :none
    end
  end

  defp compare_destinations({:link_object, _type, href_a}, {:settings_url, href_b})
       when href_a == href_b,
       do: {:duplicate, href_a}

  defp compare_destinations({:link_object, _type, href_a}, {:settings_url, href_b}),
    do: {:conflict, %{"link" => href_a, "url" => href_b}}

  defp tuple_destination?({:link_object, _, _}), do: true
  defp tuple_destination?({:settings_url, _}), do: true
  defp tuple_destination?(_), do: false

  defp finalize_destination({:link_object, type, href}) do
    cond do
      not corpus_link_type?(type) ->
        {:rejected, :unsupported_link_type, %{"type" => type, "url" => href}}

      true ->
        case StaticNavigation.classify_destination(href) do
          :safe -> {:ok, href, nil}
          :unsafe -> {:rejected, :unsafe_destination, href}
          :dynamic -> {:dynamic, %{"url" => href}}
          :malformed -> {:rejected, :malformed_destination, href}
        end
    end
  end

  defp finalize_destination({:settings_url, href}) do
    case StaticNavigation.classify_destination(href) do
      :safe -> {:ok, href, nil}
      :unsafe -> {:rejected, :unsafe_destination, href}
      :dynamic -> {:dynamic, %{"url" => href}}
      :malformed -> {:rejected, :malformed_destination, href}
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
