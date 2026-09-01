defmodule LiveFrames.FidelityDriftTest do
  use ExUnit.Case, async: false

  alias LiveFrames.Fidelity
  alias LiveFrames.Fidelity.DocumentLoader
  alias LiveFrames.Adapters.AutomaticCSS.FidelityResolver

  @input Path.expand(
           "../../../../sources/work/hero_india/design_ir/design_document.json",
           __DIR__
         )
  @heex Path.expand(
          "../../../../apps/live_frames_preview/lib/live_frames_preview_web/live/fidelity_generated/hero.html.heex",
          __DIR__
        )
  @css Path.expand(
         "../../../../apps/live_frames_preview/priv/static/assets/fidelity/hero.css",
         __DIR__
       )
  @manifest Path.expand("../../../../sources/work/hero_india/fidelity/manifest.json", __DIR__)

  test "committed fidelity artifacts regenerate byte-identically" do
    assert {:ok, document} = DocumentLoader.from_file(@input)
    assert {:ok, bundle} = Fidelity.generate(document, source_resolver: FidelityResolver)
    assert File.read!(@heex) == bundle.heex
    assert File.read!(@css) == bundle.css
    expected_manifest = Map.put(bundle.manifest, "input_ir_sha256", sha(File.read!(@input)))
    assert Jason.decode!(File.read!(@manifest)) == expected_manifest
  end

  defp sha(value), do: Base.encode16(:crypto.hash(:sha256, value), case: :lower)
end
