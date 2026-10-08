defmodule LiveFrames.BricksDesignIRDriftTest do
  use ExUnit.Case, async: false

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Fidelity.DocumentLoader
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

  test "regeneration matches the committed v1 artifact after structural migration" do
    token_set = token_set()

    assert {:ok, document} =
             Bricks.to_ir(@fixture_path,
               component_id: "sqhmmc",
               token_set: token_set,
               theme_styles: @theme_styles_path
             )

    assert document.ir_version == "3.0.0"
    assert document.collection_bindings == %{}
    assert document.value_bindings == %{}

    assert {:ok, migrated_fixture} = DocumentLoader.from_file(@artifact_path)
    assert Jason.decode!(File.read!(@artifact_path))["ir_version"] == "1.0.0"

    assert scrub_migration_provenance(IR.to_map(document)) ==
             scrub_migration_provenance(IR.to_map(migrated_fixture))
  end

  defp scrub_migration_provenance(map) do
    Map.update!(map, "provenance", fn provenance ->
      Map.delete(provenance, "liveframes_ir_migrations")
      |> Map.update!("normalization_lifecycle", &List.delete(&1, "frontend_bindings_normalized"))
      |> Map.update!("source_pipeline", &List.delete(&1, "frontend_binding_normalizer"))
    end)
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
