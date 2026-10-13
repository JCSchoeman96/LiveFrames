defmodule LiveFrames.BricksDesignIRDriftTest do
  use ExUnit.Case, async: false

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.IR

  @fixture_path Path.expand("../../../../fixtures/bricks/bricks_components.json", __DIR__)
  @token_fixture_path Path.expand(
                        "../../../../fixtures/automatic_css/acss_settings.json",
                        __DIR__
                      )
  @theme_styles_path Path.expand(
                       "../../../../fixtures/bricks/bricks_theme_styles.json",
                       __DIR__
                     )
  @artifact_path Path.expand(
                   "../../../../sources/work/hero_india/design_ir/design_document.json",
                   __DIR__
                 )

  test "current regeneration matches the committed current artifact byte-for-byte" do
    token_set = token_set()

    assert {:ok, document} =
             Bricks.to_ir(@fixture_path,
               component_id: "sqhmmc",
               token_set: token_set,
               theme_styles: @theme_styles_path
             )

    assert document.ir_version == "4.0.0"
    assert document.collection_bindings == %{}
    assert document.value_bindings == %{}
    assert Map.has_key?(document.token_set["tokens"], "typography.heading.scale.h2")

    current_bytes = IR.encode!(document) <> "\n"
    artifact_bytes = File.read!(@artifact_path)
    assert Jason.decode!(artifact_bytes)["ir_version"] == "4.0.0"

    unless current_bytes == artifact_bytes do
      flunk(
        "current Bricks Design IR bytes differ: generated=#{sha256(current_bytes)} artifact=#{sha256(artifact_bytes)}"
      )
    end

    assert Jason.decode!(artifact_bytes)["ir_version"] == "4.0.0"
  end

  defp sha256(value), do: Base.encode16(:crypto.hash(:sha256, value), case: :lower)

  defp token_set do
    {:ok, token_set, _diagnostics} =
      AutomaticCSS.from_file(
        @token_fixture_path,
        source_version: "4.0.1",
        source_version_status: "fixture_reference",
        strict: true,
        profile: :hero_foundation
      )

    token_set
  end
end
