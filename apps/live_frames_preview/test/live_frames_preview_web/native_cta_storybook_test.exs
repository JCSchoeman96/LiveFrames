defmodule LiveFramesPreviewWeb.NativeCTAStorybookTest do
  use LiveFramesPreviewWeb.ConnCase, async: true

  @story_path Path.expand("../../storybook/components/media_call_to_action.story.exs", __DIR__)

  defp story_module do
    unless Code.ensure_loaded?(LiveFramesPreviewWeb.Storybook.Components.MediaCallToAction) do
      Code.compile_file(@story_path)
    end

    LiveFramesPreviewWeb.Storybook.Components.MediaCallToAction
  end

  test "CTA story is discoverable and serves the generated component" do
    assert File.exists?(@story_path)
    stories = Path.wildcard(Path.expand("../../storybook/**/*.story.exs", __DIR__))
    assert @story_path in stories

    story = story_module()

    assert story.function() ==
             (&LiveFrames.Components.Sections.MediaCallToAction.media_call_to_action/1)

    assert story.render_source() == :function
  end

  test "CTA story includes required synthetic variations and isolated body link" do
    story = story_module()
    variations = story.variations()
    assert Enum.map(variations, & &1.id) == [:default, :without_body, :heading_level_variant]

    default = Enum.find(variations, &(&1.id == :default))
    assert Enum.any?(default.slots, &(&1 =~ ~r/<:primary_action><a\b/))

    heading_variant = Enum.find(variations, &(&1.id == :heading_level_variant))
    assert Enum.any?(heading_variant.slots, &(&1 =~ ~r/<:body>.*<a href="\#body-preview">/))

    source = File.read!(@story_path)
    assert source =~ "/assets/native/hero-demo.svg"
    refute source =~ ~r/Tango|hxambs|Bricks|AutomaticCSS/i
  end

  test "CTA Storybook route responds with generated package component" do
    conn = get(build_conn(), "/storybook/components/media_call_to_action")
    assert conn.status == 200
    assert conn.resp_body =~ "LiveFrames Storybook"
    assert conn.resp_body =~ "Make room for what comes next"
    assert conn.resp_body =~ "lf-section-media-call-to-action"
  end
end
