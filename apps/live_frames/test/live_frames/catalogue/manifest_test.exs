defmodule LiveFrames.Catalogue.ManifestTest do
  use ExUnit.Case, async: false

  alias LiveFrames.Catalogue.Manifest

  @minimal_manifest %{
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

  test "decodes a minimal v1 manifest into a bounded struct" do
    assert {:ok, manifest} = Manifest.decode(encode(@minimal_manifest))

    assert is_struct(manifest, Manifest)
    assert manifest.schema_version == 1
    assert manifest.id == "live_frames.component.synthetic"
    assert manifest.kind == "component"
    assert manifest.display_name == "Synthetic component"
    assert manifest.state == "DRAFT"
    assert manifest.component == @minimal_manifest["component"]
    assert manifest.storybook == @minimal_manifest["storybook"]
    assert manifest.docs == %{}
    assert manifest.provenance == %{}
    assert manifest.contract == nil
    assert manifest.distribution == nil
    assert manifest.release == nil
    assert manifest.lifecycle == nil
    assert manifest.deprecation == nil
    assert manifest.introduced_in_package == nil
    assert manifest.last_changed_in_package == nil
    assert manifest.superseded_by == nil
    refute Map.has_key?(Map.from_struct(manifest), :slug)
  end

  test "decodes equivalent objects with different source key ordering equally" do
    first =
      ~s({"schema_version":1,"id":"live_frames.component.synthetic","kind":"component","display_name":"Synthetic component","state":"DRAFT","component":{"module":"LiveFrames.Components.Synthetic","function":"synthetic"},"storybook":{"module":"LiveFrames.Stories.Synthetic"},"docs":{"guide":{"url":"docs/component.md","labels":{"locale":"en"}}},"provenance":{"sources":[{"name":"synthetic"}]}})

    second =
      ~s({"provenance":{"sources":[{"name":"synthetic"}]},"docs":{"guide":{"labels":{"locale":"en"},"url":"docs/component.md"}},"storybook":{"module":"LiveFrames.Stories.Synthetic"},"component":{"function":"synthetic","module":"LiveFrames.Components.Synthetic"},"state":"DRAFT","display_name":"Synthetic component","kind":"component","id":"live_frames.component.synthetic","schema_version":1})

    assert {:ok, first_manifest} = Manifest.decode(first)
    assert {:ok, second_manifest} = Manifest.decode(second)
    assert first_manifest == second_manifest
  end

  test "returns a stable diagnostic for malformed JSON" do
    assert_diagnostic("{bad", "catalogue.manifest.invalid_json", "$")
  end

  test "rejects JSON roots that are not objects" do
    for json <- ["[]", "null", "\"manifest\"", "42", "true"] do
      assert_diagnostic(json, "catalogue.manifest.root_not_object", "$")
    end
  end

  test "reports a missing schema version" do
    @minimal_manifest
    |> Map.delete("schema_version")
    |> encode()
    |> assert_diagnostic("catalogue.manifest.schema_version_missing", "schema_version")
  end

  test "requires an integer schema version" do
    for value <- ["1", 1.0, nil] do
      json = @minimal_manifest |> Map.put("schema_version", value) |> encode()
      assert_diagnostic(json, "catalogue.manifest.schema_version_invalid", "schema_version")
    end
  end

  test "rejects unsupported integer schema versions" do
    json = @minimal_manifest |> Map.put("schema_version", 2) |> encode()

    assert_diagnostic(
      json,
      "catalogue.manifest.schema_version_unsupported",
      "schema_version"
    )
  end

  test "requires every v1 structural area" do
    for field <- [
          "id",
          "kind",
          "display_name",
          "state",
          "component",
          "storybook",
          "docs",
          "provenance"
        ] do
      json = @minimal_manifest |> Map.delete(field) |> encode()
      assert_diagnostic(json, "catalogue.manifest.field_missing", field)
    end
  end

  test "requires string identity and presentation fields" do
    for field <- ["id", "kind", "display_name", "state"] do
      json = @minimal_manifest |> Map.put(field, 7) |> encode()
      assert_diagnostic(json, "catalogue.manifest.field_type_invalid", field)
    end
  end

  test "requires component to be an object" do
    for value <- [[], nil, "LiveFrames.Components.Synthetic"] do
      json = @minimal_manifest |> Map.put("component", value) |> encode()
      assert_diagnostic(json, "catalogue.manifest.field_type_invalid", "component")
    end
  end

  test "requires a string component module" do
    missing = update_in(@minimal_manifest, ["component"], &Map.delete(&1, "module"))
    wrong = update_in(@minimal_manifest, ["component"], &Map.put(&1, "module", 7))

    assert_diagnostic(encode(missing), "catalogue.manifest.field_missing", "component.module")

    assert_diagnostic(
      encode(wrong),
      "catalogue.manifest.field_type_invalid",
      "component.module"
    )
  end

  test "requires a string component function" do
    missing = update_in(@minimal_manifest, ["component"], &Map.delete(&1, "function"))
    wrong = update_in(@minimal_manifest, ["component"], &Map.put(&1, "function", false))

    assert_diagnostic(
      encode(missing),
      "catalogue.manifest.field_missing",
      "component.function"
    )

    assert_diagnostic(
      encode(wrong),
      "catalogue.manifest.field_type_invalid",
      "component.function"
    )
  end

  test "requires storybook to be an object" do
    for value <- [[], nil, "LiveFrames.Stories.Synthetic"] do
      json = @minimal_manifest |> Map.put("storybook", value) |> encode()
      assert_diagnostic(json, "catalogue.manifest.field_type_invalid", "storybook")
    end
  end

  test "requires a string storybook module" do
    missing = update_in(@minimal_manifest, ["storybook"], &Map.delete(&1, "module"))
    wrong = update_in(@minimal_manifest, ["storybook"], &Map.put(&1, "module", 7))

    assert_diagnostic(encode(missing), "catalogue.manifest.field_missing", "storybook.module")

    assert_diagnostic(
      encode(wrong),
      "catalogue.manifest.field_type_invalid",
      "storybook.module"
    )
  end

  test "accepts empty docs and provenance objects" do
    assert {:ok, manifest} = Manifest.decode(encode(@minimal_manifest))
    assert manifest.docs == %{}
    assert manifest.provenance == %{}
  end

  test "requires docs and provenance to be objects" do
    for field <- ["docs", "provenance"], value <- [[], nil, "reference"] do
      json = @minimal_manifest |> Map.put(field, value) |> encode()
      assert_diagnostic(json, "catalogue.manifest.field_type_invalid", field)
    end
  end

  test "type checks optional object areas when present" do
    for field <- ["contract", "distribution", "release", "lifecycle", "deprecation"] do
      json = @minimal_manifest |> Map.put(field, []) |> encode()
      assert_diagnostic(json, "catalogue.manifest.field_type_invalid", field)
    end
  end

  test "type checks optional package links and supersession reference" do
    for field <- ["introduced_in_package", "last_changed_in_package", "superseded_by"] do
      json = @minimal_manifest |> Map.put(field, %{}) |> encode()
      assert_diagnostic(json, "catalogue.manifest.field_type_invalid", field)
    end

    optional_values = %{
      "introduced_in_package" => nil,
      "last_changed_in_package" => "0.1.0",
      "superseded_by" => nil
    }

    assert {:ok, manifest} =
             @minimal_manifest
             |> Map.merge(optional_values)
             |> encode()
             |> Manifest.decode()

    assert manifest.introduced_in_package == nil
    assert manifest.last_changed_in_package == "0.1.0"
    assert manifest.superseded_by == nil
  end

  test "keeps nested docs and provenance values inert and string-keyed" do
    docs = %{
      "guides" => [%{"role" => "usage", "url" => "docs/usage.md"}],
      "metadata" => %{"enabled" => true, "count" => 2}
    }

    provenance = %{
      "references" => [%{"source" => "synthetic", "evidence" => ["record-1"]}],
      "opaque" => %{"value" => nil}
    }

    assert {:ok, manifest} =
             @minimal_manifest
             |> Map.merge(%{"docs" => docs, "provenance" => provenance})
             |> encode()
             |> Manifest.decode()

    assert manifest.docs == docs
    assert manifest.provenance == provenance
    assert Map.has_key?(manifest.docs, "guides")
    assert Map.has_key?(manifest.provenance, "references")
  end

  test "does not create atoms from manifest-controlled strings" do
    marker = "untrusted_manifest_value_#{System.unique_integer([:positive, :monotonic])}"

    json =
      @minimal_manifest
      |> Map.put("id", marker)
      |> update_in(["component"], &Map.put(&1, "module", marker))
      |> encode()

    atom_count_before = :erlang.system_info(:atom_count)
    assert {:ok, manifest} = Manifest.decode(json)
    atom_count_after = :erlang.system_info(:atom_count)

    assert atom_count_after == atom_count_before
    assert manifest.id == marker
    assert manifest.component["module"] == marker
  end

  defp encode(manifest), do: Jason.encode!(manifest)

  defp assert_diagnostic(json, expected_code, expected_path) do
    assert {:error, diagnostics} = Manifest.decode(json)

    assert Enum.any?(diagnostics, fn diagnostic ->
             diagnostic.code == expected_code and diagnostic.path == expected_path
           end)
  end
end
