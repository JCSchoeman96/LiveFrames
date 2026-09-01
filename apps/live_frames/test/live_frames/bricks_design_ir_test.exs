defmodule LiveFrames.BricksDesignIRTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.IR
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.StyleValue

  @fixture_path Path.expand("../../../../fixtures/bricks/bricks_components.json", __DIR__)
  @token_fixture_path Path.expand(
                        "../../../../fixtures/automatic_css/acss_settings.json",
                        __DIR__
                      )

  @source_ids [
    "sqhmmc",
    "2ef2fa",
    "561d75",
    "3f6ee6",
    "8ae908",
    "8ca7e4",
    "7ea788",
    "1c85d9",
    "a1745a",
    "be2b65"
  ]

  defp token_set do
    {:ok, token_set, _diagnostics} =
      AutomaticCSS.from_file(
        @token_fixture_path,
        source_version: "4.0.1",
        source_version_status: "fixture_reference",
        strict: true,
        profile: :hero_foundation
      )

    token_set
  end

  defp document do
    assert {:ok, document} =
             Bricks.to_ir(@fixture_path,
               component_id: "sqhmmc",
               token_set: token_set()
             )

    document
  end

  defp flatten(nodes), do: Enum.flat_map(nodes, &[&1 | flatten(&1.children)])

  defp node_by_source_id(document, source_id) do
    Enum.find(flatten(document.root_nodes), fn node ->
      node.source_trace.source_id == source_id
    end)
  end

  test "normalizes a valid DesignDocument with the complete ordered Hero tree" do
    document = document()

    assert IR.validate(document) == :ok
    assert document.ir_version == "1.0.0"
    assert length(document.root_nodes) == 1

    nodes = flatten(document.root_nodes)
    assert Enum.map(nodes, & &1.source_trace.source_id) == @source_ids

    assert Enum.map(nodes, & &1.semantic_type) == [
             "section",
             "container",
             "heading",
             "paragraph",
             "generic",
             "button",
             "button",
             "generic",
             "image",
             "generic"
           ]

    assert Enum.map(nodes, & &1.node_id) == [
             DesignNode.deterministic_id([1]),
             DesignNode.deterministic_id([1, 1]),
             DesignNode.deterministic_id([1, 1, 1]),
             DesignNode.deterministic_id([1, 1, 2]),
             DesignNode.deterministic_id([1, 1, 3]),
             DesignNode.deterministic_id([1, 1, 3, 1]),
             DesignNode.deterministic_id([1, 1, 3, 2]),
             DesignNode.deterministic_id([1, 2]),
             DesignNode.deterministic_id([1, 2, 1]),
             DesignNode.deterministic_id([1, 2, 2])
           ]

    refute Enum.any?(nodes, fn node -> node.node_id in @source_ids end)

    assert node_by_source_id(document, "2ef2fa").children |> Enum.map(& &1.source_trace.source_id) ==
             [
               "561d75",
               "3f6ee6",
               "8ae908"
             ]
  end

  test "retains source content, classes, settings, and ten source traces" do
    document = document()
    nodes = flatten(document.root_nodes)

    assert Enum.count(nodes, &match?(%{source_trace: %LiveFrames.IR.SourceTrace{}}, &1)) == 10

    assert node_by_source_id(document, "561d75").content == "Hero heading"

    assert node_by_source_id(document, "3f6ee6").content ==
             "This is just placeholder text. Don’t be alarmed, this is just here to fill up space since your finalized copy isn’t ready yet. Once we have your content finalized, we’ll replace this placeholder text with your real content."

    assert node_by_source_id(document, "561d75").attributes == %{"tag" => "h1"}
    assert node_by_source_id(document, "3f6ee6").attributes == %{"tag" => "p"}

    assert node_by_source_id(document, "sqhmmc").source_trace.source_classes == [
             "fr-hero-india",
             "bg--ultra-dark"
           ]

    assert node_by_source_id(document, "sqhmmc").source_trace.source_settings == %{
             "_cssGlobalClasses" => ["6lGpftooejv", "acss_import_bg--ultra-dark"]
           }
  end

  test "normalizes literal, keyword, token, fallback, calculation, and unresolved styles" do
    document = document()

    assert %StyleValue{kind: :keyword, value: "relative"} =
             node_by_source_id(document, "sqhmmc").styles["position"]

    assert %StyleValue{
             kind: :token_ref,
             value: "spacing.content_gap",
             source_expression: "var(--content-gap)"
           } = node_by_source_id(document, "2ef2fa").styles["row-gap"]

    assert %StyleValue{kind: :literal, value: "70ch"} =
             node_by_source_id(document, "3f6ee6").styles["max-width"]

    assert %StyleValue{
             kind: :unresolved,
             value: "var(--content-gap, 30px)",
             source_expression: "var(--content-gap, 30px)",
             metadata: %{"fallback" => "30px", "token_path" => "spacing.content_gap"}
           } = node_by_source_id(document, "8ae908").styles["column-gap"]

    assert %StyleValue{kind: :unresolved, value: "400", source_expression: "400"} =
             node_by_source_id(document, "2ef2fa").styles["margin-top"]

    assert %StyleValue{
             kind: :unresolved,
             value: "var(--overlay-bg, var(--neutral-ultra-dark-trans-60))",
             source_expression: "var(--overlay-bg, var(--neutral-ultra-dark-trans-60))"
           } = node_by_source_id(document, "be2b65").styles["background"]

    assert %StyleValue{kind: :complex_css, value: %{"type" => "custom_css"}} =
             node_by_source_id(document, "1c85d9").styles["custom-css"]

    calculation_source =
      File.read!(@fixture_path)
      |> Jason.decode!()
      |> put_in(["globalClasses", Access.filter(&(&1["id"] == "6lGpfjmaoto")), "settings"], %{
        "_width" => "calc(100% - 1rem)"
      })

    assert {:ok, calculation_document} =
             Bricks.to_ir(calculation_source, token_set: token_set(), component_id: "sqhmmc")

    assert %StyleValue{kind: :calculation, value: "calc(100% - 1rem)"} =
             node_by_source_id(calculation_document, "2ef2fa").styles["width"]
  end

  test "preserves base and responsive gradients as complex CSS" do
    document = document()
    overlay = node_by_source_id(document, "be2b65")

    assert %StyleValue{kind: :complex_css, value: base_gradient} =
             overlay.styles["background-image"]

    assert base_gradient["type"] == "gradient"
    assert base_gradient["value"]["angle"] == "90"
    assert length(base_gradient["value"]["colors"]) == 3

    assert %StyleValue{kind: :complex_css, value: responsive_gradient} =
             overlay.responsive["tablet_portrait"].styles["background-image"]

    assert responsive_gradient["value"]["angle"] == "180"

    assert responsive_gradient["value"]["colors"] == [
             %{
               "color" => %{"raw" => "hsla(0, 0%, 0%, 0)"},
               "id" => "oqyyja",
               "stop" => "5%"
             },
             %{
               "color" => %{"raw" => "hsla(0, 0%, 5%, 0.39)"},
               "id" => "gzslth",
               "stop" => "20%"
             },
             %{
               "color" => %{"raw" => "hsla(0, 1%, 4%, 0.91)"},
               "id" => "wnuidn",
               "stop" => "65%"
             }
           ]
  end

  test "retains every responsive record without inventing thresholds" do
    document = document()
    nodes = flatten(document.root_nodes)
    overrides = Enum.flat_map(nodes, &Map.values(&1.responsive))

    assert Enum.sum(Enum.map(overrides, &map_size(&1.styles))) == 4

    assert Enum.map(overrides, & &1.source_name) == [
             "mobile_portrait",
             "tablet_portrait",
             "tablet_portrait"
           ]

    assert Enum.all?(overrides, fn override ->
             override.breakpoint_id == override.source_name and
               override.min_width == nil and
               override.max_width == nil and
               override.resolution_status == :unresolved and
               match?(%LiveFrames.IR.SourceTrace{}, override.source_trace)
           end)

    assert node_by_source_id(document, "8ae908").responsive["mobile_portrait"].styles[
             "custom-css"
           ].value["rules"] == [".fr-cta-links-alpha > * {\n  width: 100% !important;\n}"]
  end

  test "creates one unresolved image asset and no synthetic interactions" do
    document = document()

    assert map_size(document.assets) == 1
    assert document.interactions == %{}

    {asset_id, asset} = Enum.at(document.assets, 0)
    assert asset_id == asset.asset_id
    assert asset.kind == "image"
    assert asset.status == :unresolved
    assert asset.uri == nil
    assert asset.alt == nil
    assert asset.metadata["attachment_id"] == 880
    assert asset.metadata["filename"] == "cordallman-man-8493246_1920.webp"
    assert asset.metadata["url"] == false
    assert asset.source_trace.source_id == "a1745a"
    assert node_by_source_id(document, "a1745a").asset_refs == [asset_id]
  end

  test "preserves Stage A unresolved diagnostics and deterministic lifecycle evidence" do
    document = document()
    codes = Enum.map(document.diagnostics, & &1.code)

    assert length(document.diagnostics) == 8
    assert Enum.count(codes, &(&1 == "bricks.breakpoint.unresolved")) == 4
    assert Enum.count(codes, &(&1 == "bricks.variable.unresolved")) == 2
    assert "bricks.setting.value_unresolved" in codes
    assert "bricks.asset.unresolved" in codes

    assert Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.setting.value_unresolved" and
               diagnostic.source_trace.source_id == "2ef2fa" and
               diagnostic.metadata["raw_value"] == "400"
           end)

    assert Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.variable.unresolved" and
               diagnostic.metadata["raw_value"] == "--overlay-bg"
           end)

    assert Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.asset.unresolved" and
               diagnostic.source_trace.source_id == "a1745a"
           end)

    assert document.provenance["normalization_lifecycle"] == [
             "source_model_ready",
             "token_set_bound",
             "nodes_normalized",
             "styles_normalized",
             "responsive_normalized",
             "dependencies_bound",
             "document_assembled",
             "ir_validated",
             "serialized",
             "drift_verified",
             "completed"
           ]
  end

  test "embeds the validated TokenSet JSON object without changing its contract" do
    document = document()
    assert document.token_set == LiveFrames.Tokens.to_map(token_set())
    assert document.token_set["token_set_version"] == "1.0.0"
    assert document.token_set["tokens"]["spacing.content_gap"]["path"] == "spacing.content_gap"
  end

  test "equivalent conversions produce byte-identical deterministic JSON" do
    first = document()
    second = document()

    assert IR.encode!(first) == IR.encode!(second)
    assert first.root_nodes == second.root_nodes
  end
end
