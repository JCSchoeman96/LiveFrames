defmodule LiveFrames.Catalogue.MigrationTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Catalogue.Migration

  @identity_map %{
    "schema_version" => 1,
    "id" => "live_frames.component.synthetic",
    "kind" => "component",
    "release" => %{
      "version" => "12.34.56",
      "metadata" => %{"channels" => ["stable", "preview"]}
    },
    "lifecycle" => %{
      "state" => "RELEASED",
      "history" => [
        %{"action" => "approve", "accepted" => true},
        %{"action" => "release", "previous_state" => nil}
      ]
    },
    "opaque" => %{
      "items" => [1, nil, false, "preserve me", %{"enabled" => true}],
      "nested" => %{"count" => 2, "valid" => false}
    }
  }

  test "exposes only migrate/2" do
    assert Code.ensure_loaded?(Migration)
    assert Migration.__info__(:functions) == [migrate: 2]
  end

  test "rejects a non-map source" do
    for source <- [nil, [], "manifest", 1, :manifest] do
      assert Migration.migrate(source, 2) ==
               diagnostic(
                 "catalogue.migration.source_invalid",
                 "$",
                 "Expected a decoded manifest map."
               )
    end
  end

  test "reports a missing exact string source schema version key" do
    assert Migration.migrate(%{:schema_version => 1}, "1") ==
             diagnostic(
               "catalogue.manifest.schema_version_missing",
               "schema_version",
               "Required field is missing."
             )
  end

  test "rejects non-integer source schema versions without coercion" do
    for version <- ["1", 1.0, nil, false, [], %{}] do
      assert Migration.migrate(%{"schema_version" => version}, "1") ==
               diagnostic(
                 "catalogue.manifest.schema_version_invalid",
                 "schema_version",
                 "Expected an integer."
               )
    end
  end

  test "rejects unsupported source schema versions" do
    for version <- [0, 2, -1, 999] do
      assert Migration.migrate(%{"schema_version" => version}, "1") ==
               diagnostic(
                 "catalogue.manifest.schema_version_unsupported",
                 "schema_version",
                 "No validator is available for this schema version."
               )
    end
  end

  test "rejects non-integer targets after validating the source" do
    source = %{"schema_version" => 1}

    for target <- ["1", 1.0, nil, :latest, :current] do
      assert Migration.migrate(source, target) ==
               diagnostic(
                 "catalogue.migration.target_version_invalid",
                 "target_version",
                 "Expected an integer."
               )
    end
  end

  test "rejects unsupported integer targets after validating the source" do
    source = %{"schema_version" => 1}

    for target <- [0, 2, 999] do
      assert Migration.migrate(source, target) ==
               diagnostic(
                 "catalogue.migration.target_version_unsupported",
                 "target_version",
                 "No migration is available for this target version."
               )
    end
  end

  test "source errors take precedence over invalid target errors" do
    assert Migration.migrate(nil, 2) ==
             diagnostic(
               "catalogue.migration.source_invalid",
               "$",
               "Expected a decoded manifest map."
             )

    assert Migration.migrate(%{}, "1") ==
             diagnostic(
               "catalogue.manifest.schema_version_missing",
               "schema_version",
               "Required field is missing."
             )

    assert Migration.migrate(%{"schema_version" => "1"}, "1") ==
             diagnostic(
               "catalogue.manifest.schema_version_invalid",
               "schema_version",
               "Expected an integer."
             )

    assert Migration.migrate(%{"schema_version" => 2}, "1") ==
             diagnostic(
               "catalogue.manifest.schema_version_unsupported",
               "schema_version",
               "No validator is available for this schema version."
             )
  end

  test "the 1 to 1 route returns the exact input without structural validation" do
    source = %{
      "schema_version" => 1,
      "not_a_complete_manifest" => true,
      "opaque" => %{"items" => [1, nil, false]}
    }

    assert {:ok, ^source} = Migration.migrate(source, 1)
  end

  test "the 1 to 1 route preserves every decoded field and nested value" do
    assert {:ok, migrated} = Migration.migrate(@identity_map, 1)

    assert migrated == @identity_map
    assert migrated["id"] == @identity_map["id"]
    assert migrated["kind"] == @identity_map["kind"]
    assert migrated["release"]["version"] == "12.34.56"
    assert migrated["lifecycle"] == @identity_map["lifecycle"]
    assert migrated["opaque"] == @identity_map["opaque"]
  end

  defp diagnostic(code, path, message),
    do: {:error, [%{code: code, path: path, message: message}]}
end
