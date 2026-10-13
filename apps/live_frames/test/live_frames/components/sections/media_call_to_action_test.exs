defmodule LiveFrames.Components.Sections.MediaCallToActionTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveFrames.Components.Sections.MediaCallToAction
  alias LiveFrames.Components.Sections.MediaCallToActionTest.Caller

  defmodule Caller do
    use Phoenix.Component

    import LiveFrames.Components.Sections.MediaCallToAction

    def default(assigns) do
      ~H"""
      <.media_call_to_action
        heading="A place to begin"
        image_1_src="/images/first.svg"
        image_1_alt="First image"
        image_2_src="/images/second.svg"
        image_2_alt="Second image"
        image_3_src="/images/third.svg"
        image_3_alt="Third image"
      >
        <:primary_action><a href="#preview">See the details</a></:primary_action>
      </.media_call_to_action>
      """
    end

    def with_body(assigns) do
      ~H"""
      <.media_call_to_action
        heading="A place to begin"
        heading_level={3}
        eyebrow="A small introduction"
        image_1_src="/images/first.svg"
        image_1_alt="First image"
        image_2_src="/images/second.svg"
        image_2_alt="Second image"
        image_3_src="/images/third.svg"
        image_3_alt="Third image"
        class="consumer-class"
        id="cta-root"
        data-testid="cta-root"
      >
        <:body><p>Optional supporting copy.</p></:body>
        <:primary_action><button type="button">Continue</button></:primary_action>
      </.media_call_to_action>
      """
    end
  end

  test "renders the required heading, all image sources and alt text, and consumer action markup" do
    html = render_component(&Caller.default/1, %{})

    assert html =~ "A place to begin"
    assert html =~ ~r/<h2 class="[^"]+">A place to begin<\/h2>/
    assert html =~ ~s(src="/images/first.svg" alt="First image")
    assert html =~ ~s(src="/images/second.svg" alt="Second image")
    assert html =~ ~s(src="/images/third.svg" alt="Third image")
    assert html =~ ~s(<a href="#preview">See the details</a>)
    refute html =~ "Optional supporting copy."
  end

  test "supports heading level, optional eyebrow and body, additive class, and global attrs" do
    html = render_component(&Caller.with_body/1, %{})

    assert html =~ ~r/<h3 class="[^"]+">A place to begin<\/h3>/
    assert html =~ "A small introduction"
    assert html =~ "Optional supporting copy."
    assert html =~ "consumer-class"
    assert html =~ ~s(id="cta-root")
    assert html =~ ~s(data-testid="cta-root")
    assert html =~ ~r/<span class="[^"]+"><button type="button">Continue<\/button><\/span>/
    assert html =~ ~s(<button type="button">Continue</button>)
  end

  test "runtime heading level changes the tag without changing the visual heading class" do
    h2_html = render_component(&Caller.default/1, %{})
    h3_html = render_component(&Caller.with_body/1, %{})

    assert [_, h2_class] = Regex.run(~r/<h2 class="([^"]+)"/, h2_html)
    assert [_, h3_class] = Regex.run(~r/<h3 class="([^"]+)"/, h3_html)
    assert h2_class == h3_class

    stylesheet =
      File.read!(
        Path.expand(
          "../../../../assets/css/components/sections/media_call_to_action.css",
          __DIR__
        )
      )

    assert stylesheet =~ "font-size: var(--lf-typography-heading-size-h2);"
    refute stylesheet =~ "typography-heading-size-h3"
  end

  test "public component attributes contain no source-system API" do
    assert function_exported?(MediaCallToAction, :media_call_to_action, 1)

    refute File.read!(
             Path.expand(
               "../../../../lib/live_frames/components/sections/media_call_to_action.ex",
               __DIR__
             )
           ) =~
             ~r/Bricks|\bFrames\b|ACSS|hxambs|Tango/i
  end
end
