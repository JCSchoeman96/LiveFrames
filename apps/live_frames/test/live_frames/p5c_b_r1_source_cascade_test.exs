defmodule LiveFrames.P5CBR1SourceCascadeTest do
  @moduledoc """
  Regression coverage for P5C-B-R1 source-cascade fidelity correction.
  """
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.AutomaticCSS.FidelityResolver
  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Adapters.Bricks.Settings
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

  test "Bricks spacing authority resolves unitless nonzero box values to px" do
    result = Settings.extract(%{"_margin" => %{"top" => "400"}})

    assert result.base_styles["margin-top"] == "400px"
    refute Map.has_key?(result.unresolved_values, "_margin.top")
  end

  test "unitless box values remain unresolved without numeric spacing authority" do
    result = Settings.extract(%{"_margin" => %{"top" => "autoish"}})

    assert result.unresolved_values["_margin.top"] == "autoish"
    refute Map.has_key?(result.base_styles, "margin-top")
  end

  test "zero box values stay unitless zero" do
    result = Settings.extract(%{"_margin" => %{"top" => "0"}})
    assert result.base_styles["margin-top"] == "0"
  end

  test "Bricks container intrinsic defaults enter Design IR without inventing unrelated styles" do
    document = hero_document()
    container = hd(hd(document.root_nodes).children)

    assert container.semantic_type == "container"
    assert %StyleValue{kind: :keyword, value: "flex"} = container.styles["display"]
    assert %StyleValue{kind: :keyword, value: "column"} = container.styles["flex-direction"]
    assert %StyleValue{kind: :literal, value: "400px"} = container.styles["margin-top"]

    paragraph = Enum.find(container.children, &(&1.semantic_type == "paragraph"))
    refute Map.has_key?(paragraph.styles, "display")
  end

  test "ACSS fidelity emits section layout through semantic context, not Hero class names" do
    tokens = token_map()

    result =
      FidelityResolver.resolve([], tokens, %{semantic_type: "section", tag: "section"})

    props = Map.new(result.declarations, &{&1.property, &1.value})

    assert props["display"] == "flex"
    assert props["flex-direction"] == "column"
    assert props["padding-block"] =~ "clamp("
    assert props["padding-inline"] =~ "clamp("
    assert props["gap"] =~ "clamp("
    refute Enum.any?(result.consumed_hints, &String.contains?(&1, "hero"))
  end

  test "ACSS fidelity emits heading typography through tag context using source expressions" do
    tokens = token_map()

    result =
      FidelityResolver.resolve([], tokens, %{semantic_type: "heading", tag: "h1"})

    props = Map.new(result.declarations, &{&1.property, &1.value})

    assert props["font-size"] =~ "clamp("
    assert props["font-weight"] == "700"
    assert props["line-height"] == "calc(4px + 2ex)"
    refute props["font-size"] =~ "44.6875"
  end

  test "generic Fidelity remains free of Bricks Frames and ACSS hard-coded Hero assumptions" do
    source =
      Path.expand("../../lib/live_frames/fidelity.ex", __DIR__)
      |> File.read!()

    refute source =~ "fr-hero-india"
    refute source =~ "brxe-container"
    refute source =~ "heading-font-weight"
    refute source =~ "section-padding-block"
  end

  test "generated Hero fidelity corrects material cascade properties without Hero hacks" do
    assert {:ok, bundle} =
             Fidelity.generate(hero_document(), source_resolver: FidelityResolver)

    assert bundle.css =~ "margin-top: 400px"
    assert bundle.css =~ "display: flex"
    assert bundle.css =~ "flex-direction: column"
    assert bundle.css =~ "padding-block:"
    assert bundle.css =~ "padding-inline:"
    assert bundle.css =~ "font-size: clamp("
    assert bundle.css =~ "font-weight: 700"
    refute bundle.css =~ "fr-hero-india__heading"
    refute bundle.css =~ "44.6875px"
  end

  test "malformed source evidence stays contained for box values" do
    result = Settings.extract(%{"_margin" => %{"top" => "400; } .x{color:red"}})

    assert result.unresolved_values["_margin.top"] == "400; } .x{color:red"
    refute Map.has_key?(result.base_styles, "margin-top")
  end
end
