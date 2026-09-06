defmodule LiveFrames.P5CBR2SourceCascadeTest do
  @moduledoc """
  Regression coverage for P5C-B-R2 source-cascade fidelity correction.
  """
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.AutomaticCSS.FidelityResolver
  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Fidelity
  alias LiveFrames.IR.StyleValue

  @token_fixture Path.expand("../../../../fixtures/automatic_css/acss_settings.json", __DIR__)
  @bricks_fixture Path.expand("../../../../fixtures/bricks/bricks_components.json", __DIR__)

  defp token_set do
    {:ok, token_set, _} =
      AutomaticCSS.from_file(@token_fixture,
        source_version: "4.0.1",
        source_version_status: "fixture_reference",
        strict: true,
        profile: :hero_foundation
      )

    token_set
  end

  defp hero_document do
    assert {:ok, document} =
             Bricks.to_ir(@bricks_fixture, component_id: "sqhmmc", token_set: token_set())

    document
  end

  defp token_map, do: hero_document().token_set

  test "ACSS prefers fixture OKLCH primary channels over legacy hex when both exist" do
    tokens = token_set().tokens
    primary = tokens["color.primary"]

    assert primary.resolved_value == "oklch(0.8839 0.154 90.78)"
    assert primary.provenance["transformation"] == "oklch_channels"
    refute primary.resolved_value == "#32a2c1"

    button_bg = tokens["button.primary.background"]
    assert button_bg.resolved_value == "oklch(0.8839 0.154 90.78)"

    button_text = tokens["button.primary.text"]
    assert button_text.resolved_value == "oklch(0.1 0.024 90.78)"
  end

  test "ACSS fidelity emits body typography through section inheritance context" do
    tokens = token_map()

    result =
      FidelityResolver.resolve([], tokens, %{semantic_type: "section", tag: "section"})

    props = Map.new(result.declarations, &{&1.property, &1.value})

    assert props["font-size"] =~ "clamp("
    assert props["line-height"] == "calc(6px + 2ex)"
    refute props["font-size"] =~ "17.67"
  end

  test "ACSS fidelity emits button display as inline-flex from btn hints" do
    tokens = token_map()

    primary =
      FidelityResolver.resolve(["btn--primary"], tokens, %{semantic_type: "button", tag: "a"})

    outline =
      FidelityResolver.resolve(["btn--outline"], tokens, %{semantic_type: "button", tag: "a"})

    assert Map.new(primary.declarations, &{&1.property, &1.value})["display"] == "inline-flex"
    assert Map.new(outline.declarations, &{&1.property, &1.value})["display"] == "inline-flex"
  end

  test "Bricks section intrinsic emits align-items center without Hero hardcodes" do
    document = hero_document()
    section = hd(document.root_nodes)

    assert section.semantic_type == "section"
    assert %StyleValue{kind: :keyword, value: "center"} = section.styles["align-items"]
    assert section.styles["align-items"].metadata["selector"] == ".brxe-section"
  end

  test "content-gap with fallback promotes to spacing.content_gap token_ref" do
    document = hero_document()

    cta =
      document.root_nodes
      |> flatten_nodes()
      |> Enum.find(&(&1.source_trace.source_id == "8ae908"))

    assert %StyleValue{
             kind: :token_ref,
             value: "spacing.content_gap",
             source_expression: "var(--content-gap, 30px)"
           } = cta.styles["column-gap"]

    assert %StyleValue{kind: :token_ref, value: "spacing.content_gap"} = cta.styles["row-gap"]
    assert cta.styles["column-gap"].metadata["fallback"] == "30px"
  end

  defp flatten_nodes(nodes) do
    Enum.flat_map(nodes, fn node -> [node | flatten_nodes(node.children)] end)
  end

  test "generated Hero fidelity emits R2 cascade properties without sampled pixels" do
    assert {:ok, bundle} =
             Fidelity.generate(hero_document(), source_resolver: FidelityResolver)

    assert bundle.css =~ "align-items: center"
    assert bundle.css =~ "display: inline-flex"
    assert bundle.css =~ "oklch(0.8839 0.154 90.78)"
    assert bundle.css =~ "font-size: clamp("
    assert bundle.css =~ "line-height: calc(6px + 2ex)"
    # CTA gap via token expression (not 30px fallback)
    assert bundle.css =~ ~r/(?:row-|column-)?gap: clamp\(/
    refute bundle.css =~ "#32a2c1"
    refute bundle.css =~ "17.67px"
    refute bundle.css =~ "fr-cta-links-alpha"
  end
end
