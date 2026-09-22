defmodule LiveFrames.Components.Sections.HeroSemanticsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveFrames.Components.Sections.Hero
  alias LiveFrames.Components.Sections.HeroSemanticsTest.HeroSemanticsCaller

  @hero_source Path.expand(
                 "../../../../lib/live_frames/components/sections/hero.ex",
                 __DIR__
               )

  @forbidden_provenance ~w(
    fr-
    btn--primary
    btn--outline
    bg--ultra-dark
    lf-fidelity
    Bricks
    Automatic.css
    ACSS
    sqhmmc
    attachment 880
    tablet_portrait
    mobile_portrait
    991
    478
  )

  @forbidden_business ~w(
    phx-click
    navigate
    patch
    analytics
    checkout
    GenServer
    PubSub
    Oban
  )

  defp render_hero(extra \\ []) do
    assigns = Enum.into(Keyword.merge([heading: "Hero heading"], extra), %{})
    render_component(&Hero.hero/1, assigns)
  end

  defp hero_heading_count(html) do
    Regex.scan(~r/<h[1-6][^>]*class="lf-hero__heading"/, html) |> length()
  end

  defp section_count(html) do
    Regex.scan(~r/<section[\s>]/, html) |> length()
  end

  defp count_attr(html, attr) do
    Regex.scan(~r/\s#{attr}="/, html) |> length()
  end

  defmodule HeroSemanticsCaller do
    use Phoenix.Component

    import LiveFrames.Components.Sections.Hero

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

    def with_consumer_tabindex(assigns) do
      ~H"""
      <.hero heading="Hero heading" tabindex="0" />
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

    def with_full_content(assigns) do
      ~H"""
      <.hero
        heading="Hero heading"
        lede="Supporting copy"
        image_src="/images/hero.jpg"
        image_alt="Team collaborating"
      >
        <:primary_action><button type="button">Primary</button></:primary_action>
        <:secondary_action><a href="/more">Secondary</a></:secondary_action>
      </.hero>
      """
    end
  end

  describe "root semantic structure" do
    test "renders one section root with internal structure and omits optional regions" do
      html = render_hero()

      assert section_count(html) == 1
      assert html =~ ~s(class="lf-hero)
      assert html =~ "lf-hero__content"
      assert html =~ "lf-hero__heading"
      assert hero_heading_count(html) == 1
      refute html =~ "<img"
      refute html =~ "lf-hero__media"
      refute html =~ "lf-hero__lede"
      refute html =~ "lf-hero__actions"
    end
  end

  describe "heading semantics" do
    test "emits exactly one hero heading regardless of level" do
      for level <- 1..6 do
        html = render_hero(heading_level: level)
        assert hero_heading_count(html) == 1
      end
    end

    test "selected semantic level controls the element" do
      html = render_hero(heading_level: 4)

      assert html =~ ~s(<h4 class="lf-hero__heading">)
      refute html =~ ~s(<h2 class="lf-hero__heading">)
    end

    test "invalid dynamic levels fail before render" do
      assert_raise ArgumentError, "heading_level must be an integer between 1 and 6", fn ->
        render_hero(heading_level: 99)
      end
    end

    test "escapes hostile heading content as text" do
      hostile = ~S(<script>"'&<>)
      html = render_hero(heading: hostile)

      refute html =~ ~s(<script>)
      assert html =~ "&lt;script&gt;"
      assert html =~ "&quot;"
      assert html =~ "&#39;"
      assert html =~ "&amp;"
      assert html =~ "&lt;"
      assert html =~ "&gt;"
      assert hero_heading_count(html) == 1
    end
  end

  describe "lede escaping" do
    test "escapes adversarial lede as one paragraph of text" do
      hostile = ~S|<img src=x onerror=alert(1)>"'&<>|
      html = render_hero(lede: hostile)

      assert Regex.scan(~r/<p class="lf-hero__lede">/, html) |> length() == 1
      refute html =~ ~r/<img[\s>]/
      refute html =~ ~r/\sonerror="/
      refute html =~ ~s(<script>)
      assert html =~ "&lt;img"
      assert html =~ "onerror=alert(1)"
      assert html =~ "&quot;"
      assert html =~ "&#39;"
      assert html =~ "&amp;"
    end
  end

  describe "attribute escaping" do
    test "escapes hostile id without injecting attributes" do
      hostile_id = ~S|hero" onclick="alert(1)|
      html = render_hero(id: hostile_id)

      assert html =~ ~s|id="hero&quot; onclick=&quot;alert(1)"|
      refute html =~ ~s| onclick="alert(1)|
      assert count_attr(html, "onclick") == 0
    end

    test "escapes hostile class without injecting attributes" do
      hostile_class = ~S|evil" onclick="alert(1)|
      html = render_hero(class: hostile_class)

      assert html =~ "evil&quot; onclick=&quot;alert(1)"
      assert count_attr(html, "onclick") == 0
    end

    test "escapes hostile image_src and image_alt" do
      hostile_src = ~S|/images/hero.jpg" onload="alert(1)|
      hostile_alt = ~S|Team" onclick="alert(1)|

      html =
        render_hero(
          image_src: hostile_src,
          image_alt: hostile_alt
        )

      assert html =~
               ~s|src="/images/hero.jpg&quot; onload=&quot;alert(1)"|

      assert html =~ ~s|alt="Team&quot; onclick=&quot;alert(1)"|
      assert count_attr(html, "onload") == 0
      refute html =~ ~s| onclick="alert(1)|
    end
  end

  describe "global attribute trust boundary" do
    test "passes benign consumer-owned globals to the root section" do
      html =
        render_hero(
          id: "hero-root",
          "data-testid": "hero-root",
          "aria-labelledby": "hero-label",
          title: "Hero section"
        )

      assert html =~ ~s(data-testid="hero-root")
      assert html =~ ~s(aria-labelledby="hero-label")
      assert html =~ ~s(title="Hero section")
      assert html =~ ~s(<section id="hero-root")
    end

    test "does not introduce component-owned semantic globals by default" do
      html = render_hero()

      refute html =~ ~r/\stabindex="/
      refute html =~ "phx-click"
      refute html =~ ~r/\srole="/
      refute html =~ ~r/\saria-label="/
      refute html =~ ~r/\shidden="/
      refute html =~ ~r/\shidden>/
    end

    test "allows explicitly supplied consumer globals such as tabindex" do
      html = render_component(&HeroSemanticsCaller.with_consumer_tabindex/1, %{})

      assert html =~ ~s(tabindex="0")
    end
  end

  describe "image semantics" do
    test "omits image, media wrapper, and placeholder when image_src is absent" do
      html = render_hero()

      refute html =~ "<img"
      refute html =~ "lf-hero__media"
      refute html =~ "attachment"
    end

    test "renders one informative image with escaped source and preserved alt" do
      html =
        render_hero(
          image_src: "/images/hero.jpg",
          image_alt: "Team collaborating"
        )

      assert Regex.scan(~r/<img[\s>]/, html) |> length() == 1
      assert html =~ ~s(src="/images/hero.jpg")
      assert html =~ ~s(alt="Team collaborating")
      assert html =~ "lf-hero__media"
      refute html =~ ~r/<img[^>]*aria-label=/
      refute html =~ ~r/<img[^>]*role="img"/
    end

    test "renders decorative image with empty alt and no fabricated ARIA" do
      html =
        render_hero(
          image_src: "/images/hero.jpg",
          image_alt: ""
        )

      assert html =~ ~s(alt="")
      refute html =~ "aria-hidden"
      refute html =~ ~r/<img[^>]*aria-label=/
      refute html =~ ~r/<img[^>]*role="img"/
    end

    test "does not render image when only image_alt is supplied" do
      html = render_hero(image_alt: "Unused alt")

      refute html =~ "<img"
      refute html =~ "lf-hero__media"
      refute html =~ "Unused alt"
    end

    test "preserves authoritative missing-alt guard with image_src" do
      assert_raise ArgumentError, "image_alt is required when image_src is provided", fn ->
        render_hero(image_src: "/images/hero.jpg", image_alt: nil)
      end
    end
  end

  describe "action semantics" do
    test "preserves native primary button unchanged" do
      html = render_component(&HeroSemanticsCaller.with_primary/1, %{})

      assert html =~ ~s(<button type="button">Primary</button>)
      refute html =~ "phx-click"
      refute html =~ ~r/<a[\s>]/
    end

    test "preserves native secondary link unchanged" do
      html = render_component(&HeroSemanticsCaller.with_secondary/1, %{})

      assert html =~ ~s(<a href="/more">Secondary</a>)
      refute html =~ "phx-click"
    end

    test "does not invent href, navigation, or business behavior" do
      html = render_component(&HeroSemanticsCaller.with_primary/1, %{})

      refute html =~ ~r/href="[^"]+"/
      refute html =~ "navigate"
      refute html =~ "patch"
    end

    test "wraps only supplied actions in primary-then-secondary order" do
      html = render_component(&HeroSemanticsCaller.with_both_actions/1, %{})

      primary_index = :binary.match(html, "lf-hero__action--primary") |> elem(0)
      secondary_index = :binary.match(html, "lf-hero__action--secondary") |> elem(0)

      assert primary_index < secondary_index
    end
  end

  describe "semantic keyboard behavior" do
    test "preserves native button and link focusability without component tabindex" do
      html = render_component(&HeroSemanticsCaller.with_both_actions/1, %{})

      assert html =~ ~s(<button type="button">Primary</button>)
      assert html =~ ~s(<a href="/more">Secondary</a>)
      refute html =~ ~r/lf-hero__action[^>]*tabindex=/
      refute html =~ ~r/lf-hero__actions[^>]*tabindex=/
      refute html =~ ~r/lf-hero__content[^>]*tabindex=/
    end

    test "does not create hidden focus targets" do
      html = render_component(&HeroSemanticsCaller.with_both_actions/1, %{})

      refute html =~ ~r/\shidden="/
      refute html =~ ~r/\shidden>/
    end
  end

  describe "action cardinality regression" do
    test "still rejects duplicate primary_action entries in O(1) validation" do
      assert_raise ArgumentError, "primary_action accepts at most one slot entry", fn ->
        render_component(&HeroSemanticsCaller.with_duplicate_primary/1, %{})
      end
    end

    test "slot validation avoids length/1 in production source" do
      source = File.read!(@hero_source)
      refute source =~ "length("
    end
  end

  describe "optional content matrix" do
    test "heading only omits optional wrappers" do
      html = render_hero()

      refute html =~ "lf-hero__lede"
      refute html =~ "lf-hero__actions"
      refute html =~ "lf-hero__media"
    end

    test "heading and lede omit action and media wrappers" do
      html = render_hero(lede: "Supporting copy")

      assert html =~ "lf-hero__lede"
      refute html =~ "lf-hero__actions"
      refute html =~ "lf-hero__media"
    end

    test "heading and primary omit secondary wrapper and media" do
      html = render_component(&HeroSemanticsCaller.with_primary/1, %{})

      assert html =~ "lf-hero__action--primary"
      refute html =~ "lf-hero__action--secondary"
      refute html =~ "lf-hero__media"
    end

    test "heading and secondary omit primary wrapper and media" do
      html = render_component(&HeroSemanticsCaller.with_secondary/1, %{})

      assert html =~ "lf-hero__action--secondary"
      refute html =~ "lf-hero__action--primary"
      refute html =~ "lf-hero__media"
    end

    test "heading and both actions omit media wrapper" do
      html = render_component(&HeroSemanticsCaller.with_both_actions/1, %{})

      assert html =~ "lf-hero__action--primary"
      assert html =~ "lf-hero__action--secondary"
      refute html =~ "lf-hero__media"
    end

    test "heading and image omit lede and actions" do
      html =
        render_hero(
          image_src: "/images/hero.jpg",
          image_alt: "Decorative"
        )

      assert html =~ "lf-hero__media"
      refute html =~ "lf-hero__lede"
      refute html =~ "lf-hero__actions"
    end

    test "full content renders each optional region exactly once" do
      html = render_component(&HeroSemanticsCaller.with_full_content/1, %{})

      assert hero_heading_count(html) == 1
      assert Regex.scan(~r/lf-hero__lede/, html) |> length() == 1
      assert Regex.scan(~r/lf-hero__actions/, html) |> length() == 1
      assert Regex.scan(~r/<img[\s>]/, html) |> length() == 1
      assert html =~ "lf-hero__action--primary"
      assert html =~ "lf-hero__action--secondary"
    end
  end

  describe "long content" do
    test "preserves unusually long heading and lede without truncation or duplication" do
      long_heading = String.duplicate("Heading fragment. ", 500)
      long_lede = String.duplicate("Lede fragment. ", 500)

      html = render_hero(heading: long_heading, lede: long_lede)

      assert html =~ long_heading
      assert html =~ long_lede
      assert hero_heading_count(html) == 1
      assert Regex.scan(~r/lf-hero__lede/, html) |> length() == 1
    end
  end

  describe "deterministic rendering" do
    test "identical attrs and slots produce equivalent HTML on repeated render" do
      attrs = [
        heading: "Hero heading",
        lede: "Supporting copy",
        image_src: "/images/hero.jpg",
        image_alt: "Team collaborating",
        id: "hero-section",
        class: "my-class"
      ]

      first = render_hero(attrs)
      second = render_hero(attrs)

      assert first == second
      refute first =~ ~r/id="[^"]*-[0-9a-f]{8}/
    end
  end

  describe "source leakage verification" do
    test "production hero source contains no forbidden provenance vocabulary" do
      source = File.read!(@hero_source)

      for term <- @forbidden_provenance do
        refute source =~ term, "forbidden provenance term #{inspect(term)} found in hero.ex"
      end
    end
  end

  describe "business and state boundary" do
    test "production hero source contains no business or runtime coupling" do
      source = File.read!(@hero_source)

      for term <- @forbidden_business do
        refute source =~ term, "forbidden business term #{inspect(term)} found in hero.ex"
      end

      refute source =~ "href"
      refute source =~ "database"
      refute source =~ "network"
      refute source =~ "hook"
      refute source =~ "JavaScript"
    end

    test "default rendered output contains no component-owned event behavior" do
      html = render_hero()

      refute html =~ "phx-click"
      refute html =~ "navigate"
      refute html =~ "patch"
    end
  end
end
