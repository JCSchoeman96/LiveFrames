defmodule LiveFrames.Catalogue.DistributionCapabilityTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Catalogue.DistributionCapability
  alias LiveFrames.Catalogue.Manifest

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

  test "accepts an absent distribution claim" do
    assert DistributionCapability.validate(%Manifest{distribution: nil}) == :ok
  end

  test "accepts a structurally valid library claim" do
    manifest = %Manifest{distribution: %{"library" => capability()}}

    assert DistributionCapability.validate(manifest) == :ok
  end

  test "accepts all declared capabilities with valid structure" do
    distribution = %{
      "library" => capability(),
      "generator" => capability(),
      "ejection" => capability()
    }

    assert DistributionCapability.validate(%Manifest{distribution: distribution}) == :ok
  end

  test "accepts evidence references without checking whether their paths exist" do
    manifest = %Manifest{distribution: %{"library" => capability(["does/not/exist.md"])}}

    assert DistributionCapability.validate(manifest) == :ok
  end

  test "accepts exact evidence strings without normalization" do
    refs = [" leading and trailing ", "e\u0301", "é", "REF"]
    manifest = %Manifest{distribution: %{"library" => capability(refs)}}

    assert DistributionCapability.validate(manifest) == :ok
    assert manifest.distribution["library"]["evidence_refs"] == refs
  end

  test "rejects values that are not decoded Manifest structs" do
    assert_diagnostic(
      DistributionCapability.validate(%{}),
      "catalogue.distribution_capability.manifest_invalid",
      "$"
    )
  end

  test "rejects non-map and empty distribution values" do
    for distribution <- [[], "distribution", 7, false, %{}] do
      assert_diagnostic(
        DistributionCapability.validate(%Manifest{distribution: distribution}),
        "catalogue.distribution_capability.distribution_invalid",
        "distribution"
      )
    end
  end

  test "rejects unknown string capability keys before validating known claims" do
    distribution = %{
      "library" => %{},
      "future" => capability()
    }

    assert_diagnostic(
      DistributionCapability.validate(%Manifest{distribution: distribution}),
      "catalogue.distribution_capability.capability_unknown",
      "distribution"
    )
  end

  test "rejects atom-key capability names" do
    assert_diagnostic(
      DistributionCapability.validate(%Manifest{distribution: %{library: capability()}}),
      "catalogue.distribution_capability.capability_unknown",
      "distribution"
    )
  end

  test "rejects malformed capability objects at the capability path" do
    valid = capability()

    malformed = [
      {"non-map capability", "supported"},
      {"missing status", Map.delete(valid, "status")},
      {"missing evidence refs", Map.delete(valid, "evidence_refs")},
      {"extra key", Map.put(valid, "extra", true)},
      {"atom keys", %{status: "supported", evidence_refs: ["evidence.md"]}}
    ]

    for {_label, value} <- malformed do
      assert_diagnostic(
        DistributionCapability.validate(%Manifest{distribution: %{"library" => value}}),
        "catalogue.distribution_capability.capability_invalid",
        "distribution.library"
      )
    end
  end

  test "accepts only the exact supported status string" do
    for status <- ["unsupported", "pending", "SUPPORTED", true, false, nil, 7] do
      assert_diagnostic(
        DistributionCapability.validate(%Manifest{
          distribution: %{"library" => capability(["evidence.md"], status)}
        }),
        "catalogue.distribution_capability.status_invalid",
        "distribution.library.status"
      )
    end
  end

  test "rejects malformed evidence reference containers" do
    improper_list = ["evidence.md" | :improper_tail]

    for evidence_refs <- [[], nil, "single-string", 7, %{}, improper_list] do
      assert_diagnostic(
        DistributionCapability.validate(%Manifest{
          distribution: %{"library" => capability(evidence_refs)}
        }),
        "catalogue.distribution_capability.evidence_refs_invalid",
        "distribution.library.evidence_refs"
      )
    end
  end

  test "reports the first malformed evidence member at its source index" do
    for evidence_ref <- ["", nil, 7, <<255>>] do
      assert_diagnostic(
        DistributionCapability.validate(%Manifest{
          distribution: %{"library" => capability(["valid", evidence_ref])}
        }),
        "catalogue.distribution_capability.evidence_ref_invalid",
        "distribution.library.evidence_refs[1]"
      )
    end
  end

  test "rejects exact duplicate evidence references" do
    assert_diagnostic(
      DistributionCapability.validate(%Manifest{
        distribution: %{"library" => capability(["same", "same"])}
      }),
      "catalogue.distribution_capability.evidence_ref_duplicate",
      "distribution.library.evidence_refs"
    )
  end

  test "validates capabilities in library, generator, ejection order" do
    distribution = %{
      "ejection" => %{},
      "generator" => %{},
      "library" => %{}
    }

    assert_diagnostic(
      DistributionCapability.validate(%Manifest{distribution: distribution}),
      "catalogue.distribution_capability.capability_invalid",
      "distribution.library"
    )
  end

  test "leaves nested distribution shape validation outside Manifest.decode" do
    assert {:ok, manifest} =
             @base_manifest
             |> Map.put("distribution", %{})
             |> Jason.encode!()
             |> Manifest.decode()

    assert_diagnostic(
      DistributionCapability.validate(manifest),
      "catalogue.distribution_capability.distribution_invalid",
      "distribution"
    )
  end

  defp capability(
         evidence_refs \\ ["docs/development/example_evidence.md"],
         status \\ "supported"
       ) do
    %{"status" => status, "evidence_refs" => evidence_refs}
  end

  defp assert_diagnostic({:error, [%{code: code, path: path, message: message}]}, code, path) do
    assert is_binary(message)
  end
end
