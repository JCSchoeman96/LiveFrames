defmodule LiveFrames.P5CBR3BricksContainerWidthTest do
  @moduledoc """
  Regression coverage for P5C-B-R3 Bricks container width fidelity.

  Authority (Bricks 2.3.1 frontend CSS, installed DanBricks LocalWP):

      .brxe-container {
        width: 1100px;           /* Bricks intrinsic default / Theme Styles placeholder */
        margin-left: auto;
        margin-right: auto;
        ...
      }
      [class*=brxe-] { max-width: 100%; }

  DanBricks Theme Styles override container width to `var(--content-width)`
  (ACSS). That site override is not ingested in this slice; the Bricks
  intrinsic default remains the Case A boundary. Alternate configured widths
  are proven via optional `:container_width` and authored `_width` / `_widthMax`.
  """
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS
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

  defp hero_document(opts \\ []) do
    assert {:ok, document} =
             Bricks.to_ir(
               @bricks_fixture,
               Keyword.merge([component_id: "sqhmmc", token_set: token_set()], opts)
             )

    document
  end

  defp hero_container(opts \\ []) do
    document = hero_document(opts)
    hd(hd(document.root_nodes).children)
  end

  defp document_with_container_settings(settings) do
    source =
      File.read!(@bricks_fixture)
      |> Jason.decode!()
      |> update_in(
        ["components", Access.filter(&(&1["id"] == "sqhmmc")), "elements"],
        fn elements ->
          Enum.map(elements, fn
            %{"id" => "2ef2fa"} = element ->
              Map.update(element, "settings", %{}, &Map.merge(&1, settings))

            other ->
              other
          end)
        end
      )

    assert {:ok, document} =
             Bricks.to_ir(source, component_id: "sqhmmc", token_set: token_set())

    document
  end

  test "Bricks container receives authoritative width, max-width, and auto margins" do
    container = hero_container()

    assert container.semantic_type == "container"
    assert %StyleValue{kind: :literal, value: "1100px"} = container.styles["width"]
    assert %StyleValue{kind: :literal, value: "100%"} = container.styles["max-width"]
    assert %StyleValue{kind: :keyword, value: "auto"} = container.styles["margin-left"]
    assert %StyleValue{kind: :keyword, value: "auto"} = container.styles["margin-right"]

    assert container.styles["width"].metadata["authority"] == "bricks_intrinsic_element_default"
    assert container.styles["width"].metadata["selector"] == ".brxe-container"
    assert container.styles["max-width"].metadata["selector"] == "[class*=brxe-]"
  end

  test "explicit authored width overrides intrinsic container width" do
    container =
      document_with_container_settings(%{"_width" => "720px"})
      |> then(&hd(hd(&1.root_nodes).children))

    assert %StyleValue{kind: :literal, value: "720px"} = container.styles["width"]
    refute container.styles["width"].metadata["authority"] == "bricks_intrinsic_element_default"
  end

  test "explicit authored max-width overrides intrinsic max-width" do
    container =
      document_with_container_settings(%{"_widthMax" => "80%"})
      |> then(&hd(hd(&1.root_nodes).children))

    assert %StyleValue{kind: :literal, value: "80%"} = container.styles["max-width"]

    refute container.styles["max-width"].metadata["authority"] ==
             "bricks_intrinsic_element_default"
  end

  test "alternate configured container width does not hard-code only 1100px" do
    container = hero_container(container_width: "960px")

    assert %StyleValue{kind: :literal, value: "960px"} = container.styles["width"]
    assert container.styles["max-width"].value == "100%"
  end

  test "unknown container width authority remains unresolved rather than guessed" do
    container = hero_container(container_width: :unavailable)

    refute Map.has_key?(container.styles, "width")
    assert %StyleValue{kind: :literal, value: "100%"} = container.styles["max-width"]
    assert %StyleValue{kind: :keyword, value: "auto"} = container.styles["margin-left"]
  end

  test "generic Fidelity remains free of Bricks container width assumptions" do
    source =
      Path.expand("../../lib/live_frames/fidelity.ex", __DIR__)
      |> File.read!()

    refute source =~ "1100px"
    refute source =~ "brxe-container"
    refute source =~ "fr-hero-india__content-wrapper"
  end

  test "generated Hero fidelity emits container width semantics without Hero hacks" do
    assert {:ok, bundle} =
             Fidelity.generate(hero_document(),
               source_resolver: LiveFrames.Adapters.AutomaticCSS.FidelityResolver
             )

    assert bundle.css =~ "width: 1100px"
    assert bundle.css =~ "max-width: 100%"
    assert bundle.css =~ "margin-left: auto"
    assert bundle.css =~ "margin-right: auto"
    refute bundle.css =~ "fr-hero-india__content-wrapper"
    refute bundle.css =~ "sqhmmc"
  end
end
