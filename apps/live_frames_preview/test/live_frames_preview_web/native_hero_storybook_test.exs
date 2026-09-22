defmodule LiveFramesPreviewWeb.NativeHeroStorybookTest do
  use LiveFramesPreviewWeb.ConnCase, async: true

  @hero_story_path Path.expand("../../storybook/components/hero.story.exs", __DIR__)
  @proof_story_path Path.expand("../../storybook/components/proof_component.story.exs", __DIR__)
  @storybook_css_path Path.expand("../../assets/css/storybook.css", __DIR__)
  @live_frames_css_artifact Path.expand(
                              "../../../live_frames/priv/static/live_frames/css/live_frames.css",
                              __DIR__
                            )

  defp hero_story_module do
    unless Code.ensure_loaded?(LiveFramesPreviewWeb.Storybook.Components.Hero) do
      Code.compile_file(@hero_story_path)
    end

    LiveFramesPreviewWeb.Storybook.Components.Hero
  end

  test "native Hero story file exists and is discoverable" do
    assert File.exists?(@hero_story_path)

    stories = Path.wildcard(Path.expand("../../storybook/**/*.story.exs", __DIR__))
    assert @hero_story_path in stories
  end

  test "GET /storybook/components/hero responds successfully" do
    conn = get(build_conn(), "/storybook/components/hero")
    assert conn.status == 200
    assert conn.resp_body =~ "LiveFrames Storybook"
    assert conn.resp_body =~ "Build faster with native LiveFrames"
    assert conn.resp_body =~ "lf-hero"
  end

  test "Hero story calls production hero/1" do
    story = hero_story_module()
    assert story.function() == (&LiveFrames.Components.Sections.Hero.hero/1)
    assert story.render_source() == :function
    assert story.layout() == :one_column
  end

  test "Hero story defines four representative variations" do
    story = hero_story_module()
    variation_ids = Enum.map(story.variations(), & &1.id)

    assert variation_ids == [:default, :informative_media, :no_media, :minimal]
  end

  test "Hero story variations represent both action slots where applicable" do
    story = hero_story_module()
    variations = story.variations()
    default = Enum.find(variations, &(&1.id == :default))

    assert Enum.any?(default.slots, &(&1 =~ ~r/<:primary_action>/))
    assert Enum.any?(default.slots, &(&1 =~ ~r/<:secondary_action>/))

    minimal = Enum.find(variations, &(&1.id == :minimal))
    refute Enum.any?(minimal.slots, &(&1 =~ ~r/<:primary_action>/))
    refute Enum.any?(minimal.slots, &(&1 =~ ~r/<:secondary_action>/))
  end

  test "Hero story uses synthetic preview media and not attachment 880" do
    story_source = File.read!(@hero_story_path)

    assert story_source =~ "/assets/native/hero-demo.svg"
    refute story_source =~ ~r/attachment[_-]?880/i
    refute story_source =~ ~r/image_src:\s*["'][^"']*880/
  end

  test "Storybook CSS imports canonical LiveFrames package artifact" do
    css = File.read!(@storybook_css_path)

    assert css =~
             ~r/@import\s+["'].*live_frames\/priv\/static\/live_frames\/css\/live_frames\.css["']/

    refute Regex.match?(~r/\.lf-hero/, css)
  end

  test "canonical LiveFrames CSS artifact exists for Storybook consumption" do
    assert File.exists?(@live_frames_css_artifact)
    assert File.read!(@live_frames_css_artifact) =~ ".lf-hero"
  end

  test "Phase 1 proof story remains discoverable" do
    stories = Path.wildcard(Path.expand("../../storybook/**/*.story.exs", __DIR__))
    assert @proof_story_path in stories
    assert File.exists?(@proof_story_path)
  end
end
