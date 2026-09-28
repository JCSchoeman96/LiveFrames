defmodule LiveFrames.Catalogue.SchemaTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Catalogue.Schema
  alias LiveFrames.Catalogue.Schema.V1

  @v1_manifest %{
    "schema_version" => 1,
    "id" => "live_frames.component.synthetic",
    "kind" => "component",
    "display_name" => "Synthetic component",
    "state" => "DRAFT",
    "component" => %{
      "module" => "LiveFrames.Components.Synthetic",
      "function" => "synthetic"
    },
    "storybook" => %{"module" => "LiveFrames.Stories.Synthetic"},
    "docs" => %{},
    "provenance" => %{}
  }

  test "exposes only validate/1" do
    assert Code.ensure_loaded?(Schema)
    assert Schema.__info__(:functions) == [validate: 1]
  end

  test "a valid v1 map returns the v1 validator result" do
    assert {:ok, _attributes} = Schema.validate(@v1_manifest)
    assert Schema.validate(@v1_manifest) == V1.validate(@v1_manifest)
  end

  test "reports a missing exact string schema version key" do
    map = %{:schema_version => 1}

    assert Schema.validate(map) ==
             diagnostic(
               "catalogue.manifest.schema_version_missing",
               "schema_version",
               "Required field is missing."
             )
  end

  test "rejects non-integer schema versions without coercion" do
    for version <- ["1", 1.0, nil, false, [], %{}] do
      assert Schema.validate(%{"schema_version" => version}) ==
               diagnostic(
                 "catalogue.manifest.schema_version_invalid",
                 "schema_version",
                 "Expected an integer."
               )
    end
  end

  test "rejects unsupported integer schema versions" do
    for version <- [0, 2, -1, 999] do
      assert Schema.validate(%{"schema_version" => version}) ==
               diagnostic(
                 "catalogue.manifest.schema_version_unsupported",
                 "schema_version",
                 "No validator is available for this schema version."
               )
    end
  end

  test "propagates v1 structural diagnostics unchanged" do
    map = Map.put(@v1_manifest, "id", 7)

    assert Schema.validate(map) == V1.validate(map)
  end

  defp diagnostic(code, path, message),
    do: {:error, [%{code: code, path: path, message: message}]}
end
