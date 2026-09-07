defmodule LiveFrames.P5CBR3BricksContainerWidthTest do
  @moduledoc """
  Regression coverage for P5C-B-R3 Bricks container width fidelity.

  Authority chain (Bricks 2.3.1 + DanBricks LocalWP + ACSS 4.0.1):

  * Bricks frontend intrinsic: `.brxe-container { width: 1100px; margin-*: auto }`
  * `[class*=brxe-] { max-width: 100% }`
  * DanBricks Theme Styles (active `standard`): `.brxe-container { width: var(--content-width) }`
  * ACSS owns `--content-width` via setting `vp-max` (UI: Content Width) → TokenSet
    `layout.viewport.max`
  """
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.AutomaticCSS.FidelityResolver
  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Fidelity
  alias LiveFrames.IR.StyleValue

  @token_fixture Path.expand("../../../../fixtures/automatic_css/acss_settings.json", __DIR__)
  @bricks_fixture Path.expand("../../../../fixtures/bricks/bricks_components.json", __DIR__)
  @theme_styles_fixture Path.expand(
                          "../../../../fixtures/bricks/bricks_theme_styles.json",
                          __DIR__
                        )

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

  defp theme_styles(overrides \\ %{}) do
    @theme_styles_fixture
    |> File.read!()
    |> Jason.decode!()
    |> deep_merge(overrides)
  end

  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _k, l, r -> deep_merge(l, r) end)
  end

  defp deep_merge(_left, right), do: right

  defp hero_document(opts) do
    assert {:ok, document} =
             Bricks.to_ir(
               @bricks_fixture,
               Keyword.merge([component_id: "sqhmmc", token_set: token_set()], opts)
             )

    document
  end

  defp hero_container(opts \\ []) do
    hd(hd(hero_document(opts).root_nodes).children)
  end

  defp document_with_container_settings(settings, opts \\ []) do
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
             Bricks.to_ir(
               source,
               Keyword.merge([component_id: "sqhmmc", token_set: token_set()], opts)
             )

    document
  end

  test "no site override keeps proven Bricks 2.3.1 default 1100px" do
    container = hero_container()

    assert %StyleValue{kind: :literal, value: "1100px"} = container.styles["width"]
    assert container.styles["width"].metadata["authority"] == "bricks_intrinsic_element_default"
    assert %StyleValue{kind: :literal, value: "100%"} = container.styles["max-width"]
    assert %StyleValue{kind: :keyword, value: "auto"} = container.styles["margin-left"]
    assert %StyleValue{kind: :keyword, value: "auto"} = container.styles["margin-right"]
  end

  test "authoritative Theme Styles override replaces Bricks default via TokenSet" do
    container = hero_container(theme_styles: theme_styles())

    assert %StyleValue{
             kind: :token_ref,
             value: "layout.viewport.max",
             source_expression: "var(--content-width)"
           } = container.styles["width"]

    assert container.styles["width"].metadata["authority"] == "bricks_theme_styles"
    assert container.styles["width"].metadata["source_variable"] == "--content-width"
    refute container.styles["width"].value == "1100px"
  end

  test "alternate Theme Styles width flows from source config not a manual shortcut" do
    styles =
      theme_styles(%{
        "styles" => %{"standard" => %{"settings" => %{"container" => %{"width" => "960px"}}}}
      })

    container = hero_container(theme_styles: styles)

    assert %StyleValue{kind: :literal, value: "960px"} = container.styles["width"]
    assert container.styles["width"].metadata["authority"] == "bricks_theme_styles"
  end

  test "configured Theme Styles width beats Bricks default" do
    styles =
      theme_styles(%{
        "styles" => %{"standard" => %{"settings" => %{"container" => %{"width" => "1200px"}}}}
      })

    container = hero_container(theme_styles: styles)
    assert container.styles["width"].value == "1200px"
    refute container.styles["width"].metadata["authority"] == "bricks_intrinsic_element_default"
  end

  test "explicit authored width beats Theme Styles and Bricks default" do
    styles = theme_styles()

    container =
      document_with_container_settings(%{"_width" => "720px"}, theme_styles: styles)
      |> then(&hd(hd(&1.root_nodes).children))

    assert %StyleValue{kind: :literal, value: "720px"} = container.styles["width"]

    refute container.styles["width"].metadata["authority"] in [
             "bricks_intrinsic_element_default",
             "bricks_theme_styles"
           ]
  end

  test "explicit authored max-width overrides intrinsic max-width" do
    container =
      document_with_container_settings(%{"_widthMax" => "80%"})
      |> then(&hd(hd(&1.root_nodes).children))

    assert %StyleValue{kind: :literal, value: "80%"} = container.styles["max-width"]

    refute container.styles["max-width"].metadata["authority"] ==
             "bricks_intrinsic_element_default"
  end

  test "explicit unavailable authority does not guess 1100px" do
    container = hero_container(container_width: :unavailable)

    refute Map.has_key?(container.styles, "width")
    assert %StyleValue{kind: :literal, value: "100%"} = container.styles["max-width"]
  end

  test "invalid configured Theme Styles width does not silently fall back to 1100px" do
    styles =
      theme_styles(%{
        "styles" => %{
          "standard" => %{"settings" => %{"container" => %{"width" => "not-a-width!!!"}}}
        }
      })

    container = hero_container(theme_styles: styles)

    refute Map.has_key?(container.styles, "width")
    refute Map.get(container.styles, "width") == %StyleValue{kind: :literal, value: "1100px"}
  end

  test "generic Fidelity remains free of Bricks container width assumptions" do
    source =
      Path.expand("../../lib/live_frames/fidelity.ex", __DIR__)
      |> File.read!()

    refute source =~ "1100px"
    refute source =~ "brxe-container"
    refute source =~ "content-width"
    refute source =~ "fr-hero-india__content-wrapper"
  end

  test "generated Hero with Theme Styles emits configured width without Hero hacks" do
    assert {:ok, bundle} =
             Fidelity.generate(hero_document(theme_styles: theme_styles()),
               source_resolver: FidelityResolver
             )

    assert bundle.css =~ "width: 1366px"
    assert bundle.css =~ "max-width: 100%"
    assert bundle.css =~ "margin-left: auto"
    assert bundle.css =~ "margin-right: auto"
    refute bundle.css =~ "width: 1100px"
    refute bundle.css =~ "fr-hero-india__content-wrapper"
    refute bundle.css =~ "sqhmmc"
  end
end
