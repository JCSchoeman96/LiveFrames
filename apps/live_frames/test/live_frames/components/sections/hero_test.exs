defmodule LiveFrames.Components.Sections.HeroTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveFrames.Components.Sections.Hero
  alias LiveFrames.Components.Sections.HeroTest.HeroTestCaller

  defp render_hero(extra \\ []) do
    assigns = Enum.into(Keyword.merge([heading: "Hero heading"], extra), %{})
    render_component(&Hero.hero/1, assigns)
  end

  defmodule HeroTestCaller do
    use Phoenix.Component

    import LiveFrames.Components.Sections.Hero

    def with_globals(assigns) do
      ~H"""
      <.hero
        id="hero-root"
        heading="Hero heading"
        data-testid="hero-root"
        aria-labelledby="hero-label"
        title="Hero section"
      />
      """
    end

    def with_primary(assigns) do
      ~H"""
      <.hero heading="Hero heading">
        <:primary_action><button type="button">Primary</button></:primary_action>
      </.hero>
      """
    end

    def with_secondary(assigns) do
      ~H"""
      <.hero heading="Hero heading">
        <:secondary_action><a href="/more">Secondary</a></:secondary_action>
      </.hero>
      """
    end

    def with_both_actions(assigns) do
      ~H"""
      <.hero heading="Hero heading">
        <:primary_action><button type="button">Primary</button></:primary_action>
        <:secondary_action><a href="/more">Secondary</a></:secondary_action>
      </.hero>
      """
    end

    def with_duplicate_primary(assigns) do
      ~H"""
      <.hero heading="Hero heading">
        <:primary_action><button type="button">One</button></:primary_action>
        <:primary_action><button type="button">Two</button></:primary_action>
      </.hero>
      """
    end

    def with_duplicate_secondary(assigns) do
      ~H"""
      <.hero heading="Hero heading">
        <:secondary_action><a href="/one">One</a></:secondary_action>
        <:secondary_action><a href="/two">Two</a></:secondary_action>
      </.hero>
      """
    end
  end

  describe "basic render" do
    test "renders required heading" do
      html = render_hero()

      assert html =~ "Hero heading"
      assert html =~ "lf-hero__heading"
    end

    test "defaults heading level to h2" do
      html = render_hero()

      assert html =~ "<h2"
      refute html =~ "<h1"
    end
  end

  describe "heading levels" do
    test "maps all valid levels to the correct heading element" do
      for level <- 1..6 do
        html = render_hero(heading_level: level)

        assert html =~ "<h#{level} class=\"lf-hero__heading\">"
      end
    end
  end

  describe "invalid heading guards" do
    test "rejects 0" do
      assert_raise ArgumentError, "heading_level must be an integer between 1 and 6", fn ->
        render_hero(heading_level: 0)
      end
    end

    test "rejects 7" do
      assert_raise ArgumentError, "heading_level must be an integer between 1 and 6", fn ->
        render_hero(heading_level: 7)
      end
    end

    test "rejects string level" do
      assert_raise ArgumentError, "heading_level must be an integer between 1 and 6", fn ->
        render_hero(heading_level: "2")
      end
    end

    test "rejects explicit nil level" do
      assert_raise ArgumentError, "heading_level must be an integer between 1 and 6", fn ->
        render_hero(heading_level: nil)
      end
    end
  end

  describe "lede" do
    test "renders one paragraph when present" do
      html = render_hero(lede: "Supporting copy")

      assert html =~ ~s(<p class="lf-hero__lede">Supporting copy</p>)
    end

    test "omits paragraph when nil" do
      html = render_hero(lede: nil)

      refute html =~ "lf-hero__lede"
      refute html =~ "<p"
    end
  end

  describe "image" do
    test "renders without image when image_src is nil" do
      html = render_hero()

      refute html =~ "<img"
      refute html =~ "lf-hero__media"
      assert html =~ "lf-hero"
    end

    test "renders informative image with non-empty alt" do
      html =
        render_hero(
          image_src: "/images/hero.jpg",
          image_alt: "Team collaborating"
        )

      assert html =~ ~s(src="/images/hero.jpg")
      assert html =~ ~s(alt="Team collaborating")
      assert html =~ "lf-hero__image"
      assert html =~ "lf-hero__media"
    end

    test "preserves explicit decorative alt" do
      html =
        render_hero(
          image_src: "/images/hero.jpg",
          image_alt: ""
        )

      assert html =~ ~s(alt="")
      refute html =~ "aria-hidden"
    end

    test "requires image_alt when image_src is provided" do
      assert_raise ArgumentError, "image_alt is required when image_src is provided", fn ->
        render_hero(image_src: "/images/hero.jpg", image_alt: nil)
      end
    end
  end

  describe "actions" do
    test "omits action region when both slots are absent" do
      html = render_hero()

      refute html =~ "lf-hero__actions"
    end

    test "renders primary action unchanged in primary wrapper" do
      html = render_component(&HeroTestCaller.with_primary/1, %{})

      assert html =~ ~s(<button type="button">Primary</button>)
      assert html =~ "lf-hero__action lf-hero__action--primary"
      refute html =~ "lf-hero__action--secondary"
    end

    test "renders secondary action unchanged in secondary wrapper" do
      html = render_component(&HeroTestCaller.with_secondary/1, %{})

      assert html =~ ~s(<a href="/more">Secondary</a>)
      assert html =~ "lf-hero__action lf-hero__action--secondary"
      refute html =~ "lf-hero__action--primary"
    end

    test "renders both actions in primary-then-secondary order" do
      html = render_component(&HeroTestCaller.with_both_actions/1, %{})

      primary_index = :binary.match(html, "lf-hero__action--primary") |> elem(0)
      secondary_index = :binary.match(html, "lf-hero__action--secondary") |> elem(0)

      assert primary_index < secondary_index
      assert html =~ "lf-hero__actions"
    end

    test "rejects duplicate primary_action entries" do
      assert_raise ArgumentError, "primary_action accepts at most one slot entry", fn ->
        render_component(&HeroTestCaller.with_duplicate_primary/1, %{})
      end
    end

    test "rejects duplicate secondary_action entries" do
      assert_raise ArgumentError, "secondary_action accepts at most one slot entry", fn ->
        render_component(&HeroTestCaller.with_duplicate_secondary/1, %{})
      end
    end
  end

  describe "root attributes" do
    test "applies explicit id to root section" do
      html = render_hero(id: "hero-section")

      assert html =~ ~s(<section id="hero-section")
    end

    test "merges consumer class with internal lf-hero class" do
      html = render_hero(class: "my-class")

      assert html =~ "lf-hero"
      assert html =~ "my-class"
    end

    test "passes declarative global attrs to root section" do
      html =
        render_component(&HeroTestCaller.with_globals/1, %{})

      assert html =~ ~s(data-testid="hero-root")
      assert html =~ ~s(aria-labelledby="hero-label")
      assert html =~ ~s(title="Hero section")
      assert html =~ ~s(<section id="hero-root")
    end
  end

  describe "public contract metadata" do
    test "persists exactly one frozen supplemental metadata map for hero/1" do
      assert Hero.__info__(:attributes)[:liveframes_public_contract_metadata] == [
               %{
                 hero: %{
                   slot_cardinality: %{
                     "primary_action" => {0, 1},
                     "secondary_action" => {0, 1}
                   },
                   capabilities: [
                     "liveframes.consumer.owns_action_navigation_and_events",
                     "liveframes.consumer.owns_global_root_attributes",
                     "liveframes.content.plain_text_heading_and_lede",
                     "liveframes.integration.requires_liveframes_css",
                     "liveframes.validation.argument_error_on_contract_violation"
                   ],
                   css_theme_contract: [
                     "--lf-action-primary-background",
                     "--lf-action-primary-background-hover",
                     "--lf-action-primary-border",
                     "--lf-action-primary-border-style",
                     "--lf-action-primary-border-width",
                     "--lf-action-primary-focus",
                     "--lf-action-primary-font-size",
                     "--lf-action-primary-font-weight",
                     "--lf-action-primary-line-height",
                     "--lf-action-primary-min-width",
                     "--lf-action-primary-padding-block",
                     "--lf-action-primary-padding-inline",
                     "--lf-action-primary-radius",
                     "--lf-action-primary-text",
                     "--lf-action-secondary-background",
                     "--lf-action-secondary-background-hover",
                     "--lf-action-secondary-border",
                     "--lf-action-secondary-border-hover",
                     "--lf-action-secondary-focus",
                     "--lf-action-secondary-text",
                     "--lf-action-secondary-text-hover",
                     "--lf-color-background-ultra-dark",
                     "--lf-color-heading-on-dark",
                     "--lf-color-text-on-dark",
                     "--lf-layout-container-max-width",
                     "--lf-space-container-gap",
                     "--lf-space-content-gap",
                     "--lf-space-gutter",
                     "--lf-space-section-padding-block",
                     "--lf-typography-body-line-height",
                     "--lf-typography-body-size",
                     "--lf-typography-display-line-height",
                     "--lf-typography-display-size",
                     "--lf-typography-display-weight"
                   ],
                   global_prefixes: []
                 }
               }
             ]
    end
  end
end
