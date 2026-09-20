defmodule LiveFrames.FidelityUnresolvedAssetAccessibilityTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Fidelity
  alias LiveFrames.IR.{AssetReference, DesignDocument, DesignNode}

  @bricks_path Path.expand("../../../../fixtures/bricks/bricks_components.json", __DIR__)
  @acss_path Path.expand("../../../../fixtures/automatic_css/acss_settings.json", __DIR__)
  @fabricated_label "Unresolved fidelity image placeholder"
  @adversarial_alt ~s(Team "Alpha" <launch> & friends" autofocus data-injected="true)

  test "hero unresolved asset placeholder never receives fabricated accessible label" do
    assert {:ok, bundle} = Fidelity.generate(hero_document())

    assert bundle.heex =~ "data-lf-asset-status=\"unresolved\""
    assert bundle.heex =~ "data-lf-asset-id=\"asset_000001\""
    refute bundle.heex =~ @fabricated_label
    refute bundle.heex =~ "aria-label"
    refute bundle.heex =~ "aria-hidden"
  end

  test "minimal unresolved asset with nil alt preserves status metadata only" do
    document = unresolved_image_document(alt: nil)

    assert {:ok, bundle} = Fidelity.generate(document)
    figure_fragment = figure_attrs_fragment(bundle.heex)

    assert figure_fragment =~ "data-lf-asset-status=\"unresolved\""
    assert figure_fragment =~ "data-lf-asset-id=\"asset_000001\""
    refute figure_fragment =~ @fabricated_label
    refute figure_fragment =~ "aria-label"
    refute figure_fragment =~ "aria-hidden"
    refute figure_fragment =~ "880"
    refute figure_fragment =~ "cordallman"
  end

  test "minimal unresolved asset with authoritative alt uses that alt as accessible label" do
    document = unresolved_image_document(alt: "Team celebrating launch")

    assert {:ok, bundle} = Fidelity.generate(document)
    figure_fragment = figure_attrs_fragment(bundle.heex)

    assert figure_fragment =~ "aria-label=\"Team celebrating launch\""
    refute figure_fragment =~ @fabricated_label
    refute figure_fragment =~ "aria-hidden"
  end

  test "minimal unresolved asset with blank alt does not invent accessible label" do
    document = unresolved_image_document(alt: "   ")

    assert {:ok, bundle} = Fidelity.generate(document)
    figure_fragment = figure_attrs_fragment(bundle.heex)

    refute figure_fragment =~ "aria-label"
    refute figure_fragment =~ @fabricated_label
  end

  test "unresolved asset accessibility generation remains deterministic" do
    document = unresolved_image_document(alt: nil)

    assert {:ok, first} = Fidelity.generate(document)
    assert {:ok, second} = Fidelity.generate(document)
    assert first.heex == second.heex
  end

  test "unresolved asset fix does not change unrelated button and heading semantics" do
    assert {:ok, bundle} = Fidelity.generate(hero_document())

    assert bundle.heex =~ "<h1"
    assert bundle.heex =~ "Hero heading"
    assert bundle.heex =~ "<button"
    assert bundle.heex =~ "type=\"button\""
    assert bundle.heex =~ "Call to action"
  end

  test "authoritative adversarial alt is serialized safely without attribute or structure injection" do
    document = unresolved_image_document(alt: @adversarial_alt)

    assert {:ok, bundle} = Fidelity.generate(document)
    figure_open = figure_attrs_fragment(bundle.heex)

    assert {:ok, _quoted} = compile_heex(bundle.heex)
    rendered = render_heex(bundle.heex)

    assert figure_attribute_names(figure_open) == [
             "class",
             "data-lf-asset-status",
             "data-lf-asset-id",
             "aria-label"
           ]

    refute String.contains?(figure_open, "<launch>")
    refute injected_attribute_outside_aria_label?(figure_open, "autofocus")
    refute injected_attribute_outside_aria_label?(figure_open, "data-injected")

    assert decode_html_attr_value(extract_aria_label(figure_open)) == @adversarial_alt
    assert decode_html_attr_value(extract_aria_label(rendered)) == @adversarial_alt
    assert count_elements(rendered, "figure") == 1
  end

  test "simple authoritative alt regression remains preserved after safe serialization" do
    document = unresolved_image_document(alt: "Team celebrating launch")

    assert {:ok, bundle} = Fidelity.generate(document)
    figure_open = figure_attrs_fragment(bundle.heex)
    rendered = render_heex(bundle.heex)

    assert decode_html_attr_value(extract_aria_label(figure_open)) == "Team celebrating launch"
    assert decode_html_attr_value(extract_aria_label(rendered)) == "Team celebrating launch"
    refute bundle.heex =~ @fabricated_label
  end

  defp hero_document do
    {:ok, token_set, _} =
      AutomaticCSS.from_file(@acss_path,
        source_version: "4.0.1",
        source_version_status: "fixture_reference",
        strict: true,
        profile: :hero_foundation
      )

    {:ok, document} = Bricks.to_ir(@bricks_path, component_id: "sqhmmc", token_set: token_set)
    document
  end

  defp unresolved_image_document(opts) do
    alt = Keyword.get(opts, :alt)

    image_node = %DesignNode{
      node_id: "node_000001",
      semantic_type: "image",
      content: nil,
      attributes: %{},
      styles: %{},
      responsive: %{},
      asset_refs: ["asset_000001"],
      children: []
    }

    %DesignDocument{
      source_metadata: %{"source" => "fixture"},
      token_set: %{},
      root_nodes: [image_node],
      assets: %{
        "asset_000001" => %AssetReference{
          asset_id: "asset_000001",
          kind: "image",
          uri: nil,
          alt: alt,
          status: :unresolved,
          metadata: %{
            "attachment_id" => 880,
            "filename" => "cordallman-man-8493246_1920.webp"
          }
        }
      },
      interactions: %{},
      diagnostics: [],
      provenance: %{}
    }
  end

  defp figure_attrs_fragment(heex) do
    [fragment | _] = Regex.run(~r/<figure[^>]*>/, heex)
    fragment
  end

  defp compile_heex(heex) do
    try do
      {:ok, EEx.compile_string(heex, engine: Phoenix.LiveView.Engine)}
    rescue
      error -> {:error, error}
    end
  end

  defp render_heex(heex) do
    heex
    |> EEx.eval_string(engine: Phoenix.LiveView.Engine)
    |> IO.iodata_to_binary()
  end

  defp extract_aria_label(fragment) do
    case Regex.run(~r/\baria-label="([^"]*)"/, fragment) do
      [_, value] -> value
      _ -> flunk("expected exactly one aria-label attribute, got: #{inspect(fragment)}")
    end
  end

  defp figure_attribute_names(fragment) do
    outside_aria = String.replace(fragment, ~r/\saria-label="[^"]*"/, "")

    outside_aria
    |> then(&Regex.scan(~r/\s([a-zA-Z0-9:-]+)=/, &1))
    |> Enum.map(fn [_, name] -> name end)
    |> Kernel.++(if(Regex.match?(~r/\saria-label="/, fragment), do: ["aria-label"], else: []))
  end

  defp injected_attribute_outside_aria_label?(fragment, name) do
    outside_aria = String.replace(fragment, ~r/\saria-label="[^"]*"/, "")
    Regex.match?(~r/\s#{name}(=|\s|>)/, outside_aria)
  end

  defp count_elements(html, tag) do
    Regex.scan(~r/<#{tag}\b/, html) |> length()
  end

  defp decode_html_attr_value(value) do
    value
    |> String.replace("&quot;", "\"")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&amp;", "&")
  end
end
