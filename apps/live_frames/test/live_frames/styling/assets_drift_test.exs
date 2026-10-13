defmodule LiveFrames.Styling.AssetsDriftTest do
  use ExUnit.Case, async: false

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Styling.TokenBridge

  @fixture Path.expand("../../../../../fixtures/automatic_css/acss_settings.json", __DIR__)
  @mapping Path.expand("../../../priv/token_maps/native_hero_v1.json", __DIR__)
  @shared_mapping Path.expand("../../../priv/token_maps/native_shared_v3.json", __DIR__)
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

    mappings = [TokenBridge.load_mapping!(@shared_mapping), TokenBridge.load_mapping!(@mapping)]
    assert {:ok, generated} = TokenBridge.generate(token_set, mappings)
    assert {:ok, repeated} = TokenBridge.generate(token_set, mappings)
    assert generated == repeated
    assert length(Regex.scan(~r/--lf-space-scale-xs:/, generated)) == 1
    assert length(Regex.scan(~r/--lf-typography-heading-size-h2:/, generated)) == 1

    assert generated =~
             "--lf-space-scale-xs: clamp(0.8333333333rem, calc(-0.0172384889vw + 0.8480506933rem), 0.8441720333rem);"

    assert generated =~
             "--lf-typography-heading-size-h2: clamp(1.62rem, calc(0.9560417495vw + 1.4048906064rem), 2.22111125rem);"

    for declaration <- [
          "--lf-typography-display-size: clamp(1.944rem, calc(1.6170835726vw + 1.5801561962rem), 2.9607412962rem);",
          "--lf-typography-display-weight: 700;",
          "--lf-typography-display-line-height: calc(4px + 2ex);",
          "--lf-typography-body-size: clamp(1rem, calc(0.1988071571vw + 0.9552683897rem), 1.125rem);",
          "--lf-typography-body-size-small: clamp(0.875rem, calc(0.0994035785vw + 0.8526341948rem), 0.9375rem);",
          "--lf-typography-body-line-height: calc(6px + 2ex);"
        ] do
      assert generated =~ declaration
    end

    assert File.read!(@theme) == generated
  end

  test "committed live_frames.css rebuilds byte-identically" do
    rebuild_assets!()
    assert File.exists?(@compiled)
    first = File.read!(@compiled)

    rebuild_assets!()
    second = File.read!(@compiled)

    assert first == second
    assert first =~ ".lf-hero"
    refute String.downcase(first) =~ "preflight"
  end

  defp rebuild_assets! do
    Mix.Task.reenable("live_frames.assets.build")
    Mix.Task.reenable("live_frames.styling.theme.build")
    Mix.Task.reenable("tailwind")
    Mix.Task.run("live_frames.assets.build")
  end
end
