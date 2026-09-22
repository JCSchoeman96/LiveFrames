defmodule LiveFrames.Styling.AssetsDriftTest do
  use ExUnit.Case, async: false

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Styling.TokenBridge

  @fixture Path.expand("../../../../../fixtures/automatic_css/acss_settings.json", __DIR__)
  @mapping Path.expand("../../../priv/token_maps/native_hero_v1.json", __DIR__)
  @compiled Path.expand("../../../priv/static/live_frames/css/live_frames.css", __DIR__)
  @theme Path.expand("../../../assets/css/theme/lf_theme.css", __DIR__)

  test "committed lf_theme.css regenerates byte-identically" do
    {:ok, token_set, _} =
      AutomaticCSS.from_file(@fixture,
        strict: true,
        profile: :hero_foundation,
        source_version: "4.0.1",
        source_version_status: "fixture_reference"
      )

    mapping = TokenBridge.load_mapping!(@mapping)
    assert {:ok, generated} = TokenBridge.generate(token_set, mapping)
    assert File.read!(@theme) == generated
  end

  test "committed live_frames.css rebuilds byte-identically" do
    Mix.Task.run("live_frames.assets.build")
    assert File.exists?(@compiled)

    Mix.Task.run("live_frames.assets.build")

    first = File.read!(@compiled)
    Mix.Task.run("live_frames.assets.build")
    second = File.read!(@compiled)

    assert first == second
    assert first =~ ".lf-hero"
    refute String.downcase(first) =~ "preflight"
  end
end
