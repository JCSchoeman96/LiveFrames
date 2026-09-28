defmodule LiveFrames.Catalogue.VersioningTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Catalogue.Manifest
  alias LiveFrames.Catalogue.Versioning

  @base_manifest %{
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

  @evidence_refs ["catalogue-version-review:synthetic"]
  @version_review %{"evidence_refs" => @evidence_refs}
  @compatibility_evidence_refs ["catalogue-compatibility-review:synthetic"]

  test "accepts stable G1 versions as initial release versions" do
    for version <- ~w(0.0.0 0.1.0 0.9.0 1.0.0 1.10.0 12.34.56 2.0.0) do
      assert {:ok, @evidence_refs} =
               Versioning.validate_initial_release(candidate(version), @version_review)
    end
  end

  test "exposes only the initial release validation operation" do
    assert Versioning.__info__(:functions) == [
             validate_initial_release: 2,
             validate_publish_new_version: 3
           ]
  end

  test "accepts exact reviewed patch, minor, and major increments" do
    cases = [
      {"1.7.4", "1.7.5", "patch"},
      {"1.7.4", "1.8.0", "minor"},
      {"1.7.4", "2.0.0", "major"}
    ]

    for {current, proposed, class} <- cases do
      assert {:ok, @compatibility_evidence_refs} =
               Versioning.validate_publish_new_version(
                 current,
                 candidate(proposed),
                 compatibility_review(class)
               )
    end
  end

  test "uses the same exact compatibility increments for zero-major versions" do
    cases = [
      {"0.3.2", "0.3.3", "patch"},
      {"0.3.2", "0.4.0", "minor"},
      {"0.3.2", "1.0.0", "major"}
    ]

    for {current, proposed, class} <- cases do
      assert {:ok, @compatibility_evidence_refs} =
               Versioning.validate_publish_new_version(
                 current,
                 candidate(proposed),
                 compatibility_review(class)
               )
    end
  end

  test "rejects invalid current versions before candidate and review errors" do
    invalid_versions = [
      nil,
      1,
      :version,
      %{},
      [],
      <<0xFF>>,
      "1",
      "1.2",
      "01.2.3",
      "1.02.3",
      "1.2.03",
      "v1.2.3",
      "1.2.3-alpha",
      "1.2.3+build",
      " 1.2.3",
      "1.2.3 "
    ]

    for current <- invalid_versions do
      assert_publish_error(
        current,
        nil,
        :malformed_review,
        "catalogue.versioning.current_version_invalid",
        "current_version"
      )
    end
  end

  test "requires a decoded Manifest after validating the current version" do
    for manifest <- [nil, %{}, "manifest", []] do
      assert_publish_error(
        "1.2.3",
        manifest,
        :malformed_review,
        "catalogue.versioning.manifest_invalid",
        "$"
      )
    end
  end

  test "requires the candidate release object to contain only version" do
    invalid_releases = [
      nil,
      [],
      "1.2.4",
      %{},
      %{version: "1.2.4"},
      %{"version" => "1.2.4", "class" => "patch"}
    ]

    for release <- invalid_releases do
      manifest = candidate("1.2.4") |> Map.put(:release, release)

      assert_publish_error(
        "1.2.3",
        manifest,
        :malformed_review,
        "catalogue.versioning.release_invalid",
        "release"
      )
    end
  end

  test "rejects invalid candidate version syntax before compatibility review errors" do
    invalid_versions = [
      nil,
      42,
      :version,
      <<0xFF>>,
      "1",
      "1.2",
      "01.2.3",
      "1.02.3",
      "1.2.03",
      "v1.2.4",
      "1.2.4-alpha",
      "1.2.4+build",
      " 1.2.4",
      "1.2.4 "
    ]

    for proposed <- invalid_versions do
      manifest = candidate("1.2.4") |> Map.put(:release, %{"version" => proposed})

      assert_publish_error(
        "1.2.3",
        manifest,
        :malformed_review,
        "catalogue.versioning.version_invalid",
        "release.version"
      )
    end
  end

  test "requires an exact compatibility review object" do
    invalid_reviews = [
      nil,
      [],
      "review",
      1,
      %{},
      %{class: "patch", evidence_refs: @compatibility_evidence_refs},
      %{"class" => "patch"},
      %{"evidence_refs" => @compatibility_evidence_refs},
      %{"class" => "patch", "evidence_refs" => @compatibility_evidence_refs, "extra" => true}
    ]

    for review <- invalid_reviews do
      assert_publish_error(
        "1.2.3",
        candidate("1.2.3"),
        review,
        "catalogue.versioning.compatibility_review_invalid",
        "compatibility_review"
      )
    end
  end

  test "accepts only exact lowercase compatibility classes" do
    for class <- [
          "MAJOR",
          "Minor",
          "breaking",
          "feature",
          "fix",
          ":major",
          " major",
          "major ",
          :major,
          nil
        ] do
      assert_publish_error(
        "1.2.3",
        candidate("1.2.4"),
        compatibility_review(class),
        "catalogue.versioning.compatibility_class_invalid",
        "compatibility_review.class"
      )
    end
  end

  test "validates compatibility evidence list shape, members, and duplicates" do
    invalid_lists = [[], nil, "review:a", %{}, {:a, :b}, ["review:a" | "review:b"]]

    for evidence_refs <- invalid_lists do
      assert_publish_error(
        "1.2.3",
        candidate("1.2.4"),
        compatibility_review("patch", evidence_refs),
        "catalogue.versioning.evidence_refs_invalid",
        "compatibility_review.evidence_refs"
      )
    end

    for bad_ref <- [42, "", :evidence, <<0xFF>>] do
      assert_publish_error(
        "1.2.3",
        candidate("1.2.4"),
        compatibility_review("patch", ["review:valid", bad_ref]),
        "catalogue.versioning.evidence_ref_invalid",
        "compatibility_review.evidence_refs[1]"
      )
    end

    assert_publish_error(
      "1.2.3",
      candidate("1.2.4"),
      compatibility_review("patch", ["review:a", "review:a"]),
      "catalogue.versioning.evidence_ref_duplicate",
      "compatibility_review.evidence_refs[1]"
    )
  end

  test "returns compatibility evidence refs in their supplied order" do
    evidence_refs = ["review:z", "review:a"]

    assert {:ok, ^evidence_refs} =
             Versioning.validate_publish_new_version(
               "1.2.3",
               candidate("1.2.4"),
               compatibility_review("patch", evidence_refs)
             )
  end

  test "rejects equal and numerically lower proposed versions" do
    for proposed <- ["1.2.3", "1.2.2", "1.1.9", "0.99.99"] do
      assert_publish_error(
        "1.2.3",
        candidate(proposed),
        compatibility_review("patch"),
        "catalogue.versioning.version_not_greater",
        "release.version"
      )
    end
  end

  test "rejects skipped increments and increments that disagree with the reviewed class" do
    cases = [
      {"1.2.3", "1.2.5", "patch"},
      {"1.2.3", "1.3.0", "patch"},
      {"1.2.3", "2.0.0", "patch"},
      {"1.2.3", "1.2.4", "minor"},
      {"1.2.3", "1.4.0", "minor"},
      {"1.2.3", "2.0.0", "minor"},
      {"1.2.3", "1.2.4", "major"},
      {"1.2.3", "1.3.0", "major"},
      {"1.2.3", "3.0.0", "major"}
    ]

    for {current, proposed, class} <- cases do
      assert_publish_error(
        current,
        candidate(proposed),
        compatibility_review(class),
        "catalogue.versioning.increment_mismatch",
        "release.version"
      )
    end
  end

  test "reviewed major change cannot use a patch version" do
    assert_publish_error(
      "1.2.3",
      candidate("1.2.4"),
      compatibility_review("major"),
      "catalogue.versioning.increment_mismatch",
      "release.version"
    )
  end

  test "compares numeric components and supports arbitrarily large values" do
    assert {:ok, @compatibility_evidence_refs} =
             Versioning.validate_publish_new_version(
               "1.9.0",
               candidate("1.10.0"),
               compatibility_review("minor")
             )

    assert_publish_error(
      "2.999.999",
      candidate("10.0.0"),
      compatibility_review("major"),
      "catalogue.versioning.increment_mismatch",
      "release.version"
    )

    large_current = "999999999999999999999.0.0"
    large_proposed = "999999999999999999999.0.1"

    assert {:ok, @compatibility_evidence_refs} =
             Versioning.validate_publish_new_version(
               large_current,
               candidate(large_proposed),
               compatibility_review("patch")
             )
  end

  test "does not gate on state or package and schema version fields" do
    manifest =
      decoded_candidate(%{
        "release" => %{"version" => "3.1.1"},
        "schema_version" => 1,
        "introduced_in_package" => "0.1.0",
        "last_changed_in_package" => "0.2.0"
      })

    assert manifest.state == "DRAFT"
    assert manifest.schema_version == 1

    assert {:ok, @compatibility_evidence_refs} =
             Versioning.validate_publish_new_version(
               "3.1.0",
               manifest,
               compatibility_review("patch")
             )
  end

  test "validates malformed review before greater-than and increment checks" do
    assert_publish_error(
      "1.2.3",
      candidate("1.2.3"),
      %{},
      "catalogue.versioning.compatibility_review_invalid",
      "compatibility_review"
    )
  end

  test "leaves the candidate manifest unchanged on success and failure" do
    manifest = candidate("1.2.4")
    original = manifest

    assert {:ok, @compatibility_evidence_refs} =
             Versioning.validate_publish_new_version(
               "1.2.3",
               manifest,
               compatibility_review("patch")
             )

    assert manifest == original

    assert {:error, _diagnostics} =
             Versioning.validate_publish_new_version(
               "1.2.3",
               manifest,
               compatibility_review("major")
             )

    assert manifest == original
  end

  test "requires a decoded Manifest struct" do
    for value <- [nil, %{}, "manifest", []] do
      assert_error(value, @version_review, "catalogue.versioning.manifest_invalid", "$")
    end
  end

  test "Manifest decoding allows an absent release and versioning rejects it" do
    assert {:ok, manifest} = Manifest.decode(Jason.encode!(@base_manifest))
    assert manifest.release == nil

    assert_error(
      manifest,
      @version_review,
      "catalogue.versioning.release_invalid",
      "release"
    )
  end

  test "Manifest decoding allows an empty release object and versioning rejects it" do
    manifest = decoded_candidate(%{"release" => %{}})

    assert_error(
      manifest,
      @version_review,
      "catalogue.versioning.release_invalid",
      "release"
    )
  end

  test "rejects extra release keys after Manifest decoding" do
    manifest =
      decoded_candidate(%{
        "release" => %{"version" => "1.2.3", "class" => "minor"}
      })

    assert_error(
      manifest,
      @version_review,
      "catalogue.versioning.release_invalid",
      "release"
    )
  end

  test "rejects non-object, atom-keyed, and multi-key release values" do
    releases = [
      [],
      "1.2.3",
      1,
      %{version: "1.2.3"},
      %{"version" => "1.2.3", "extra" => true}
    ]

    for release <- releases do
      manifest = candidate("1.2.3") |> Map.put(:release, release)

      assert_error(
        manifest,
        @version_review,
        "catalogue.versioning.release_invalid",
        "release"
      )
    end
  end

  test "rejects non-string release versions" do
    for version <- [42, 1.2, :version, nil, [], %{}] do
      manifest = candidate("1.2.3") |> Map.put(:release, %{"version" => version})

      assert_error(
        manifest,
        @version_review,
        "catalogue.versioning.version_invalid",
        "release.version"
      )
    end
  end

  test "rejects invalid UTF-8 in a release version without raising" do
    manifest = candidate("1.2.3") |> Map.put(:release, %{"version" => <<0xFF>>})

    assert_error(
      manifest,
      @version_review,
      "catalogue.versioning.version_invalid",
      "release.version"
    )
  end

  test "rejects malformed stable-core version syntax without normalizing it" do
    invalid_versions = [
      "1",
      "1.2",
      "1.2.3.4",
      "01.2.3",
      "1.02.3",
      "1.2.03",
      "-1.2.3",
      "v1.2.3",
      " 1.2.3",
      "1.2.3 ",
      "1.2.3\n"
    ]

    for version <- invalid_versions do
      assert_error(
        candidate(version),
        @version_review,
        "catalogue.versioning.version_invalid",
        "release.version"
      )
    end
  end

  test "rejects prerelease and build metadata versions" do
    for version <- [
          "1.0.0-alpha",
          "1.0.0-alpha.1",
          "1.0.0-rc.1",
          "0.1.0-dev",
          "1.0.0+build.7",
          "1.0.0+sha.abc",
          "1.0.0-rc.1+build.7"
        ] do
      assert_error(
        candidate(version),
        @version_review,
        "catalogue.versioning.version_invalid",
        "release.version"
      )
    end
  end

  test "rejects non-map, atom-keyed, incomplete, or extended version reviews" do
    reviews = [
      nil,
      [],
      "review",
      1,
      %{},
      %{evidence_refs: @evidence_refs},
      %{"class" => "minor", "evidence_refs" => @evidence_refs}
    ]

    for review <- reviews do
      assert_error(
        candidate("1.2.3"),
        review,
        "catalogue.versioning.version_review_invalid",
        "version_review"
      )
    end
  end

  test "requires evidence refs to be a non-empty proper list" do
    invalid_evidence_refs = [[], nil, "review:a", %{}, {:a, :b}, ["review:a" | "review:b"]]

    for evidence_refs <- invalid_evidence_refs do
      assert_error(
        candidate("1.2.3"),
        %{"evidence_refs" => evidence_refs},
        "catalogue.versioning.evidence_refs_invalid",
        "version_review.evidence_refs"
      )
    end
  end

  test "reports malformed evidence members by source index" do
    invalid_refs = [
      {42, "version_review.evidence_refs[1]"},
      {"", "version_review.evidence_refs[1]"},
      {:evidence, "version_review.evidence_refs[1]"},
      {<<0xFF>>, "version_review.evidence_refs[1]"}
    ]

    for {bad_ref, path} <- invalid_refs do
      assert_error(
        candidate("1.2.3"),
        %{"evidence_refs" => ["review:valid", bad_ref]},
        "catalogue.versioning.evidence_ref_invalid",
        path
      )
    end
  end

  test "rejects exact duplicate evidence refs at the repeated index" do
    assert_error(
      candidate("1.2.3"),
      %{"evidence_refs" => ["review:a", "review:a"]},
      "catalogue.versioning.evidence_ref_duplicate",
      "version_review.evidence_refs[1]"
    )
  end

  test "validates all evidence members before checking for duplicates" do
    assert_error(
      candidate("1.2.3"),
      %{"evidence_refs" => ["review:a", "review:a", 42]},
      "catalogue.versioning.evidence_ref_invalid",
      "version_review.evidence_refs[2]"
    )
  end

  test "preserves supplied evidence order and returns no invented refs" do
    evidence_refs = ["review:z", "review:a"]

    assert {:ok, ^evidence_refs} =
             Versioning.validate_initial_release(candidate("1.2.3"), %{
               "evidence_refs" => evidence_refs
             })
  end

  test "does not require a prior version, compatibility class, or 1.0.0" do
    assert {:ok, @evidence_refs} =
             Versioning.validate_initial_release(candidate("0.1.0"), @version_review)
  end

  test "does not gate version validation on the manifest state" do
    manifest = candidate("2.0.0")

    assert manifest.state == "DRAFT"

    assert {:ok, @evidence_refs} =
             Versioning.validate_initial_release(manifest, @version_review)
  end

  test "package links cannot substitute for a missing CatalogueItem release version" do
    manifest =
      decoded_candidate(%{
        "introduced_in_package" => "9.9.9",
        "last_changed_in_package" => "9.9.9"
      })

    assert manifest.release == nil

    assert_error(
      manifest,
      @version_review,
      "catalogue.versioning.release_invalid",
      "release"
    )
  end

  test "schema version and package links do not constrain the CatalogueItem version" do
    manifest =
      decoded_candidate(%{
        "release" => %{"version" => "4.2.0"},
        "introduced_in_package" => "0.1.0",
        "last_changed_in_package" => "0.2.0"
      })

    assert manifest.schema_version == 1
    assert manifest.release["version"] == "4.2.0"

    assert {:ok, @evidence_refs} =
             Versioning.validate_initial_release(manifest, @version_review)
  end

  test "leaves the manifest unchanged on success and failure" do
    manifest = candidate("1.2.3")
    original = manifest

    assert {:ok, @evidence_refs} =
             Versioning.validate_initial_release(manifest, @version_review)

    assert manifest == original

    assert {:error, _diagnostics} =
             Versioning.validate_initial_release(manifest, %{"evidence_refs" => []})

    assert manifest == original
  end

  defp candidate(version), do: decoded_candidate(%{"release" => %{"version" => version}})

  defp compatibility_review(class, evidence_refs \\ @compatibility_evidence_refs) do
    %{"class" => class, "evidence_refs" => evidence_refs}
  end

  defp decoded_candidate(overrides) do
    {:ok, manifest} =
      @base_manifest
      |> Map.merge(overrides)
      |> Jason.encode!()
      |> Manifest.decode()

    manifest
  end

  defp assert_error(manifest, version_review, expected_code, expected_path) do
    assert {:error, [diagnostic]} =
             Versioning.validate_initial_release(manifest, version_review)

    assert diagnostic.code == expected_code
    assert diagnostic.path == expected_path
  end

  defp assert_publish_error(current_version, manifest, review, expected_code, expected_path) do
    assert {:error, [diagnostic]} =
             Versioning.validate_publish_new_version(current_version, manifest, review)

    assert diagnostic.code == expected_code
    assert diagnostic.path == expected_path
  end
end
