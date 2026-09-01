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
  @artifact_path Path.expand(
                   "../../../../sources/work/hero_india/design_ir/design_document.json",
                   __DIR__
                 )

  test "regeneration byte-compares with the committed Design IR artifact" do
    token_set = token_set()

    temporary_dir =
      Path.join(System.tmp_dir!(), "live_frames_phase_4b_#{System.unique_integer([:positive])}")

    temporary_output = Path.join(temporary_dir, "design_document.json")
    File.mkdir_p!(temporary_dir)

    on_exit(fn -> File.rm_rf!(temporary_dir) end)

    assert {:ok, document} =
             Bricks.to_ir(@fixture_path, component_id: "sqhmmc", token_set: token_set)

    File.write!(temporary_output, IR.encode!(document) <> "\n")

    assert File.read!(@artifact_path) == File.read!(temporary_output)
  end

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
