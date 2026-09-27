defmodule LiveFrames.Catalogue.ProvenanceReferenceTest do
  use ExUnit.Case, async: false

  alias LiveFrames.Catalogue.Manifest
  alias LiveFrames.Catalogue.ProvenanceReference

  @authority "docs/04_SOURCE_AND_PROVENANCE.md"

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
    "docs" => %{}
  }

  test "accepts unresolved and non-public governance facts as structurally valid" do
    manifest = decoded_manifest([reference("Synthetic source A")])

    assert ProvenanceReference.validate(manifest, [
             resolved_record("Synthetic source A")
           ]) == :ok
  end

  test "accepts approved values without evaluating clearance evidence" do
    manifest = decoded_manifest([reference("Synthetic source A")])

    record =
      resolved_record("Synthetic source A", %{
        "redistribution_status" => "approved",
        "publication_state" => "public_safe",
        "clearance_evidence_refs" => ["test/evidence/not-in-record"]
      })

    assert ProvenanceReference.validate(manifest, [record]) == :ok
  end

  test "accepts an empty clearance evidence list" do
    manifest = decoded_manifest([reference("Synthetic source A")])
    record = resolved_record("Synthetic source A", %{"clearance_evidence_refs" => []})

    assert ProvenanceReference.validate(manifest, [record]) == :ok
  end

  test "requires a decoded Manifest struct" do
    assert_diagnostic(
      ProvenanceReference.validate(%{"provenance" => %{}}, []),
      "catalogue.provenance_reference.manifest_invalid",
      "$"
    )
  end

  test "leaves empty provenance accepted by Manifest.decode but rejects it here" do
    assert {:ok, manifest} =
             @base_manifest
             |> Map.put("provenance", %{})
             |> Jason.encode!()
             |> Manifest.decode()

    assert_diagnostic(
      ProvenanceReference.validate(manifest, []),
      "catalogue.provenance_reference.provenance_invalid",
      "provenance"
    )
  end

  test "rejects mutable authority fields as extra manifest provenance keys" do
    for field <- [
          "redistribution_status",
          "publication_state",
          "internal_use_status",
          "license_status",
          "clearance",
          "clearance_evidence_refs",
          "approved",
          "public_safe"
        ] do
      provenance = %{"references" => [reference("Synthetic source A")], field => "value"}

      assert {:ok, manifest} =
               @base_manifest
               |> Map.put("provenance", provenance)
               |> Jason.encode!()
               |> Manifest.decode()

      assert_diagnostic(
        ProvenanceReference.validate(manifest, [resolved_record("Synthetic source A")]),
        "catalogue.provenance_reference.provenance_invalid",
        "provenance"
      )
    end
  end

  test "requires provenance to contain exactly the references key" do
    for provenance <- [nil, [], "references", 7, %{}, %{"other" => []}] do
      assert_diagnostic(
        ProvenanceReference.validate(%Manifest{provenance: provenance}, []),
        "catalogue.provenance_reference.provenance_invalid",
        "provenance"
      )
    end

    atom_keyed = %Manifest{provenance: %{references: [reference("Synthetic source A")]}}

    assert_diagnostic(
      ProvenanceReference.validate(atom_keyed, []),
      "catalogue.provenance_reference.provenance_invalid",
      "provenance"
    )
  end

  test "requires references to be a non-empty proper list" do
    for references <- [[], nil, "reference", 7, %{}, [reference("A") | :improper_tail]] do
      assert_diagnostic(
        ProvenanceReference.validate(%Manifest{provenance: %{"references" => references}}, []),
        "catalogue.provenance_reference.references_invalid",
        "provenance.references"
      )
    end
  end

  test "rejects references without exactly the required string keys" do
    valid = reference("Synthetic source A")

    malformed_references = [
      {"non-map reference", "not a map"},
      {"missing source_group", Map.delete(valid, "source_group")},
      {"missing authority", Map.delete(valid, "authority")},
      {"missing evidence_refs", Map.delete(valid, "evidence_refs")},
      {"extra field", Map.put(valid, "status", "approved")},
      {"atom keys",
       %{
         source_group: "Synthetic source A",
         authority: @authority,
         evidence_refs: ["test/evidence/source-a"]
       }}
    ]

    for {_label, malformed} <- malformed_references do
      assert_diagnostic(
        ProvenanceReference.validate(
          %Manifest{provenance: %{"references" => [malformed]}},
          [resolved_record("Synthetic source A")]
        ),
        "catalogue.provenance_reference.reference_invalid",
        "provenance.references[0]"
      )
    end
  end

  test "validates manifest source groups without normalizing them" do
    for source_group <- ["", 7, nil, <<255>>] do
      ref = reference(source_group)

      assert_diagnostic(
        ProvenanceReference.validate(%Manifest{provenance: %{"references" => [ref]}}, []),
        "catalogue.provenance_reference.source_group_invalid",
        "provenance.references[0].source_group"
      )
    end

    manifest = decoded_manifest([reference("Synthetic source A")])

    assert_diagnostic(
      ProvenanceReference.validate(manifest, [resolved_record(" synthetic source a ")]),
      "catalogue.provenance_reference.resolution_missing",
      "provenance.references[0]"
    )
  end

  test "requires the exact supported authority string" do
    for authority <- [
          "",
          "docs/04_source_and_provenance.md",
          "/docs/04_SOURCE_AND_PROVENANCE.md",
          "https://example.test/provenance",
          <<255>>
        ] do
      ref = reference("Synthetic source A", %{"authority" => authority})

      assert_diagnostic(
        ProvenanceReference.validate(%Manifest{provenance: %{"references" => [ref]}}, []),
        "catalogue.provenance_reference.authority_invalid",
        "provenance.references[0].authority"
      )
    end
  end

  test "requires manifest evidence refs to be a non-empty proper list" do
    for evidence_refs <- [[], nil, "test/evidence/source-a", 7, %{}, ["a" | :improper_tail]] do
      ref = reference("Synthetic source A", %{"evidence_refs" => evidence_refs})

      assert_diagnostic(
        ProvenanceReference.validate(%Manifest{provenance: %{"references" => [ref]}}, []),
        "catalogue.provenance_reference.evidence_refs_invalid",
        "provenance.references[0].evidence_refs"
      )
    end
  end

  test "rejects malformed and duplicate manifest evidence members in source order" do
    for evidence_ref <- ["", 7, nil, <<255>>] do
      ref = reference("Synthetic source A", %{"evidence_refs" => ["valid", evidence_ref]})

      assert_diagnostic(
        ProvenanceReference.validate(%Manifest{provenance: %{"references" => [ref]}}, []),
        "catalogue.provenance_reference.evidence_ref_invalid",
        "provenance.references[0].evidence_refs[1]"
      )
    end

    duplicate = reference("Synthetic source A", %{"evidence_refs" => ["same", "same"]})

    assert_diagnostic(
      ProvenanceReference.validate(%Manifest{provenance: %{"references" => [duplicate]}}, []),
      "catalogue.provenance_reference.evidence_ref_duplicate",
      "provenance.references[0].evidence_refs"
    )
  end

  test "rejects duplicate manifest reference identities even when evidence differs" do
    references = [
      reference("Synthetic source A", %{"evidence_refs" => ["test/evidence/one"]}),
      reference("Synthetic source A", %{"evidence_refs" => ["test/evidence/two"]})
    ]

    assert_diagnostic(
      ProvenanceReference.validate(decoded_manifest(references), []),
      "catalogue.provenance_reference.reference_duplicate",
      "provenance.references"
    )
  end

  test "requires resolved records to be a proper list" do
    manifest = decoded_manifest([reference("Synthetic source A")])

    for records <- [
          nil,
          "record",
          7,
          %{},
          [resolved_record("Synthetic source A") | :improper_tail]
        ] do
      assert_diagnostic(
        ProvenanceReference.validate(manifest, records),
        "catalogue.provenance_reference.resolved_records_invalid",
        "resolved_records"
      )
    end
  end

  test "validates exact resolved-record keys, including unreferenced records" do
    valid = resolved_record("Synthetic source A")

    malformed_records = [
      {"non-map record", "not a map"},
      {"missing key", Map.delete(valid, "publication_state")},
      {"extra key", Map.put(valid, "approved", true)},
      {"atom keys",
       %{
         source_group: "Synthetic source A",
         authority: @authority,
         evidence_refs: ["test/evidence/source-a"],
         redistribution_status: "unknown",
         publication_state: "classified",
         clearance_evidence_refs: []
       }}
    ]

    for {_label, malformed} <- malformed_records do
      assert_diagnostic(
        ProvenanceReference.validate(decoded_manifest([reference("Synthetic source A")]), [
          malformed
        ]),
        "catalogue.provenance_reference.resolved_record_invalid",
        "resolved_records[0]"
      )
    end

    assert_diagnostic(
      ProvenanceReference.validate(decoded_manifest([reference("Synthetic source A")]), [
        valid,
        Map.put(resolved_record("Synthetic source B"), "extra", true)
      ]),
      "catalogue.provenance_reference.resolved_record_invalid",
      "resolved_records[1]"
    )
  end

  test "validates resolved source groups, authority, and evidence refs" do
    manifest = decoded_manifest([reference("Synthetic source A")])

    for source_group <- ["", 7, nil, <<255>>] do
      record = resolved_record("Synthetic source A", %{"source_group" => source_group})

      assert_diagnostic(
        ProvenanceReference.validate(manifest, [record]),
        "catalogue.provenance_reference.source_group_invalid",
        "resolved_records[0].source_group"
      )
    end

    wrong_authority = resolved_record("Synthetic source A", %{"authority" => "docs/other.md"})

    assert_diagnostic(
      ProvenanceReference.validate(manifest, [wrong_authority]),
      "catalogue.provenance_reference.authority_invalid",
      "resolved_records[0].authority"
    )

    for {evidence_refs, code, path} <- [
          {[], "catalogue.provenance_reference.evidence_refs_invalid",
           "resolved_records[0].evidence_refs"},
          {nil, "catalogue.provenance_reference.evidence_refs_invalid",
           "resolved_records[0].evidence_refs"},
          {"evidence", "catalogue.provenance_reference.evidence_refs_invalid",
           "resolved_records[0].evidence_refs"},
          {["same", "same"], "catalogue.provenance_reference.evidence_ref_duplicate",
           "resolved_records[0].evidence_refs"},
          {["valid", <<255>>], "catalogue.provenance_reference.evidence_ref_invalid",
           "resolved_records[0].evidence_refs[1]"},
          {["a" | :improper_tail], "catalogue.provenance_reference.evidence_refs_invalid",
           "resolved_records[0].evidence_refs"}
        ] do
      record = resolved_record("Synthetic source A", %{"evidence_refs" => evidence_refs})

      assert_diagnostic(
        ProvenanceReference.validate(manifest, [record]),
        code,
        path
      )
    end
  end

  test "checks status fields as valid UTF-8 strings without evaluating values" do
    manifest = decoded_manifest([reference("Synthetic source A")])

    for {field, value, code} <- [
          {"redistribution_status", nil,
           "catalogue.provenance_reference.redistribution_status_invalid"},
          {"redistribution_status", 7,
           "catalogue.provenance_reference.redistribution_status_invalid"},
          {"redistribution_status", <<255>>,
           "catalogue.provenance_reference.redistribution_status_invalid"},
          {"publication_state", nil, "catalogue.provenance_reference.publication_state_invalid"},
          {"publication_state", 7, "catalogue.provenance_reference.publication_state_invalid"},
          {"publication_state", <<255>>,
           "catalogue.provenance_reference.publication_state_invalid"}
        ] do
      record = resolved_record("Synthetic source A", %{field => value})

      assert_diagnostic(
        ProvenanceReference.validate(manifest, [record]),
        code,
        "resolved_records[0].#{field}"
      )
    end

    empty_values =
      resolved_record("Synthetic source A", %{
        "redistribution_status" => "",
        "publication_state" => ""
      })

    future_values =
      resolved_record("Synthetic source A", %{
        "redistribution_status" => "future_value",
        "publication_state" => "discovered"
      })

    assert ProvenanceReference.validate(manifest, [empty_values]) == :ok
    assert ProvenanceReference.validate(manifest, [future_values]) == :ok
  end

  test "validates clearance evidence shape without checking membership or requiring members" do
    manifest = decoded_manifest([reference("Synthetic source A")])

    assert ProvenanceReference.validate(
             manifest,
             [resolved_record("Synthetic source A", %{"clearance_evidence_refs" => []})]
           ) == :ok

    assert ProvenanceReference.validate(
             manifest,
             [
               resolved_record("Synthetic source A", %{
                 "clearance_evidence_refs" => ["not-in-evidence-refs"]
               })
             ]
           ) == :ok

    for {evidence_refs, code, path} <- [
          {nil, "catalogue.provenance_reference.clearance_evidence_refs_invalid",
           "resolved_records[0].clearance_evidence_refs"},
          {"evidence", "catalogue.provenance_reference.clearance_evidence_refs_invalid",
           "resolved_records[0].clearance_evidence_refs"},
          {["", "valid"], "catalogue.provenance_reference.clearance_evidence_ref_invalid",
           "resolved_records[0].clearance_evidence_refs[0]"},
          {["valid", 7], "catalogue.provenance_reference.clearance_evidence_ref_invalid",
           "resolved_records[0].clearance_evidence_refs[1]"},
          {["valid", <<255>>], "catalogue.provenance_reference.clearance_evidence_ref_invalid",
           "resolved_records[0].clearance_evidence_refs[1]"},
          {["same", "same"], "catalogue.provenance_reference.clearance_evidence_ref_duplicate",
           "resolved_records[0].clearance_evidence_refs"},
          {["a" | :improper_tail],
           "catalogue.provenance_reference.clearance_evidence_refs_invalid",
           "resolved_records[0].clearance_evidence_refs"}
        ] do
      record =
        resolved_record("Synthetic source A", %{"clearance_evidence_refs" => evidence_refs})

      assert_diagnostic(
        ProvenanceReference.validate(manifest, [record]),
        code,
        path
      )
    end
  end

  test "reports missing and ambiguous exact resolutions" do
    manifest = decoded_manifest([reference("Synthetic source A")])

    assert_diagnostic(
      ProvenanceReference.validate(manifest, []),
      "catalogue.provenance_reference.resolution_missing",
      "provenance.references[0]"
    )

    assert_diagnostic(
      ProvenanceReference.validate(manifest, [resolved_record("Synthetic source B")]),
      "catalogue.provenance_reference.resolution_missing",
      "provenance.references[0]"
    )

    assert_diagnostic(
      ProvenanceReference.validate(manifest, [
        resolved_record("Synthetic source A"),
        resolved_record("Synthetic source A", %{
          "evidence_refs" => ["test/evidence/source-a", "another"]
        })
      ]),
      "catalogue.provenance_reference.resolution_ambiguous",
      "provenance.references[0]"
    )
  end

  test "rejects the first manifest evidence ref absent from its exact resolved record" do
    ref = reference("Synthetic source A", %{"evidence_refs" => ["known", "not-recorded"]})
    manifest = decoded_manifest([ref])
    record = resolved_record("Synthetic source A", %{"evidence_refs" => ["known"]})

    assert_diagnostic(
      ProvenanceReference.validate(manifest, [record]),
      "catalogue.provenance_reference.evidence_ref_dangling",
      "provenance.references[0].evidence_refs[1]"
    )
  end

  test "matches records and evidence refs without using input positions" do
    references = [
      reference("Synthetic source A", %{"evidence_refs" => ["a", "b"]}),
      reference("Synthetic source B", %{"evidence_refs" => ["source-b"]}),
      reference("synthetic source a", %{"evidence_refs" => ["case-distinct"]})
    ]

    records = [
      resolved_record("synthetic source a", %{"evidence_refs" => ["case-distinct"]}),
      resolved_record("Synthetic source B", %{"evidence_refs" => ["source-b"]}),
      resolved_record("Synthetic source A", %{"evidence_refs" => ["b", "a", "c"]})
    ]

    assert ProvenanceReference.validate(decoded_manifest(references), records) == :ok
  end

  test "reports the first missing group in manifest reference order" do
    manifest =
      decoded_manifest([reference("Synthetic source A"), reference("Synthetic source B")])

    assert_diagnostic(
      ProvenanceReference.validate(manifest, [resolved_record("Synthetic source B")]),
      "catalogue.provenance_reference.resolution_missing",
      "provenance.references[0]"
    )
  end

  test "ignores valid unreferenced records after validating their shape" do
    manifest = decoded_manifest([reference("Synthetic source A")])

    assert ProvenanceReference.validate(manifest, [
             resolved_record("Synthetic source A"),
             resolved_record("Synthetic source B")
           ]) == :ok
  end

  test "does not create atoms from source groups or evidence refs" do
    marker = "untrusted_provenance_marker_#{System.unique_integer([:positive, :monotonic])}"

    assert_raise ArgumentError, fn ->
      String.to_existing_atom(marker)
    end

    manifest = decoded_manifest([reference(marker, %{"evidence_refs" => [marker]})])
    record = resolved_record(marker, %{"evidence_refs" => [marker]})

    assert ProvenanceReference.validate(manifest, [record]) == :ok

    assert_raise ArgumentError, fn ->
      String.to_existing_atom(marker)
    end
  end

  test "returns clearance evidence for a fully cleared DRAFT source" do
    manifest = decoded_manifest([reference("Synthetic source A")])

    record = cleared_record("Synthetic source A", ["test/evidence/clearance-a"])

    assert manifest.state == "DRAFT"
    assert ProvenanceReference.validate(manifest, [record]) == :ok

    assert ProvenanceReference.release_clearance(manifest, [record]) ==
             {:ok, ["test/evidence/clearance-a"]}
  end

  test "combines cleared synthetic source evidence and deduplicates shared refs" do
    references = [
      reference("Synthetic source A"),
      reference("Synthetic source B")
    ]

    records = [
      cleared_record(
        "Synthetic source A",
        ["test/evidence/shared", "test/evidence/clearance-a"]
      ),
      cleared_record(
        "Synthetic source B",
        ["test/evidence/shared", "test/evidence/clearance-b"]
      )
    ]

    assert ProvenanceReference.release_clearance(decoded_manifest(references), records) ==
             {:ok,
              [
                "test/evidence/clearance-a",
                "test/evidence/clearance-b",
                "test/evidence/shared"
              ]}
  end

  test "sorts clearance evidence by UTF-8 byte order" do
    manifest = decoded_manifest([reference("Synthetic source A")])

    record = cleared_record("Synthetic source A", ["é", "z", "a"])

    assert ProvenanceReference.release_clearance(manifest, [record]) ==
             {:ok, ["a", "z", "é"]}
  end

  test "returns the same evidence when reference, record, and clearance orders change" do
    references = [reference("Synthetic source A"), reference("Synthetic source B")]

    records = [
      cleared_record(
        "Synthetic source A",
        ["clearance/z", "clearance/a"]
      ),
      cleared_record(
        "Synthetic source B",
        ["clearance/shared", "clearance/b"]
      )
    ]

    expected = {:ok, ["clearance/a", "clearance/b", "clearance/shared", "clearance/z"]}

    assert ProvenanceReference.release_clearance(decoded_manifest(references), records) ==
             expected

    reordered_records =
      records
      |> Enum.reverse()
      |> Enum.map(&Map.update!(&1, "clearance_evidence_refs", fn refs -> Enum.reverse(refs) end))

    assert ProvenanceReference.release_clearance(
             decoded_manifest(Enum.reverse(references)),
             reordered_records
           ) == expected
  end

  test "requires redistribution status to equal approved exactly" do
    manifest = decoded_manifest([reference("Synthetic source A")])

    for status <- ["unknown", "future_value", "", "approved ", "Approved", "explicitly_allowed"] do
      record =
        cleared_record(
          "Synthetic source A",
          ["test/evidence/clearance-a"],
          %{"redistribution_status" => status}
        )

      assert_diagnostic(
        ProvenanceReference.release_clearance(manifest, [record]),
        "catalogue.provenance_reference.redistribution_not_approved",
        "provenance.references[0]"
      )
    end
  end

  test "APPROVED Catalogue state does not clear unknown redistribution status" do
    manifest =
      decoded_manifest([reference("Synthetic source A")])
      |> Map.put(:state, "APPROVED")

    record =
      cleared_record(
        "Synthetic source A",
        ["test/evidence/clearance-a"],
        %{"redistribution_status" => "unknown"}
      )

    assert_diagnostic(
      ProvenanceReference.release_clearance(manifest, [record]),
      "catalogue.provenance_reference.redistribution_not_approved",
      "provenance.references[0]"
    )
  end

  test "requires public_safe publication state" do
    manifest = decoded_manifest([reference("Synthetic source A")])

    for state <- ["classified", "private_only"] do
      record =
        cleared_record(
          "Synthetic source A",
          ["test/evidence/clearance-a"],
          %{"publication_state" => state}
        )

      assert_diagnostic(
        ProvenanceReference.release_clearance(manifest, [record]),
        "catalogue.provenance_reference.publication_not_public_safe",
        "provenance.references[0]"
      )
    end
  end

  test "requires at least one clearance evidence ref while validate remains structural" do
    manifest = decoded_manifest([reference("Synthetic source A")])

    record = cleared_record("Synthetic source A", [])

    assert ProvenanceReference.validate(manifest, [record]) == :ok

    assert_diagnostic(
      ProvenanceReference.release_clearance(manifest, [record]),
      "catalogue.provenance_reference.clearance_evidence_missing",
      "provenance.references[0]"
    )
  end

  test "requires every clearance evidence ref to exist in the matching record" do
    manifest = decoded_manifest([reference("Synthetic source A")])

    record =
      cleared_record(
        "Synthetic source A",
        ["test/evidence/clearance-missing-first", "test/evidence/clearance-missing-second"],
        %{"evidence_refs" => ["test/evidence/source-a", "test/evidence/clearance-a"]}
      )

    assert ProvenanceReference.validate(manifest, [record]) == :ok

    assert {:error, [diagnostic]} = ProvenanceReference.release_clearance(manifest, [record])
    assert diagnostic.code == "catalogue.provenance_reference.clearance_evidence_dangling"
    assert diagnostic.path == "provenance.references[0]"
    assert diagnostic.message =~ "test/evidence/clearance-missing-first"
  end

  test "requires every referenced source to pass before returning evidence" do
    manifest =
      decoded_manifest([reference("Synthetic source A"), reference("Synthetic source B")])

    record_a = cleared_record("Synthetic source A", ["test/evidence/clearance-a"])

    record_b =
      cleared_record(
        "Synthetic source B",
        ["test/evidence/clearance-b"],
        %{"redistribution_status" => "unknown"}
      )

    assert_diagnostic(
      ProvenanceReference.release_clearance(manifest, [record_a, record_b]),
      "catalogue.provenance_reference.redistribution_not_approved",
      "provenance.references[1]"
    )
  end

  test "chooses the first clearance failure by manifest reference order" do
    references = [reference("Synthetic source A"), reference("Synthetic source B")]

    record_a =
      cleared_record(
        "Synthetic source A",
        ["test/evidence/clearance-a"],
        %{"publication_state" => "classified"}
      )

    record_b =
      cleared_record(
        "Synthetic source B",
        ["test/evidence/clearance-b"],
        %{"redistribution_status" => "unknown"}
      )

    reversed_records = [record_b, record_a]

    assert_diagnostic(
      ProvenanceReference.release_clearance(decoded_manifest(references), reversed_records),
      "catalogue.provenance_reference.publication_not_public_safe",
      "provenance.references[0]"
    )

    assert_diagnostic(
      ProvenanceReference.release_clearance(
        decoded_manifest(Enum.reverse(references)),
        reversed_records
      ),
      "catalogue.provenance_reference.redistribution_not_approved",
      "provenance.references[0]"
    )
  end

  test "ignores valid unreferenced uncleared records and their evidence" do
    manifest = decoded_manifest([reference("Synthetic source A")])

    record_a = cleared_record("Synthetic source A", ["test/evidence/clearance-a"])

    record_b =
      cleared_record(
        "Synthetic source B",
        ["test/evidence/unreferenced-clearance"],
        %{"redistribution_status" => "unknown", "publication_state" => "private_only"}
      )

    assert ProvenanceReference.release_clearance(manifest, [record_a, record_b]) ==
             {:ok, ["test/evidence/clearance-a"]}
  end

  test "propagates #45A diagnostics unchanged before clearance evaluation" do
    manifest =
      decoded_manifest([
        reference("Synthetic source A", %{"evidence_refs" => ["test/evidence/dangling"]})
      ])

    record = cleared_record("Synthetic source A", ["test/evidence/source-a"])

    expected = ProvenanceReference.validate(manifest, [record])

    assert_diagnostic(
      expected,
      "catalogue.provenance_reference.evidence_ref_dangling",
      "provenance.references[0].evidence_refs[0]"
    )

    assert ProvenanceReference.release_clearance(manifest, [record]) == expected
  end

  test "propagates #45A shape failures for malformed unreferenced records" do
    manifest = decoded_manifest([reference("Synthetic source A")])

    record_a = cleared_record("Synthetic source A", ["test/evidence/clearance-a"])

    malformed_record_b =
      resolved_record("Synthetic source B")
      |> Map.delete("publication_state")

    expected = ProvenanceReference.validate(manifest, [record_a, malformed_record_b])

    assert ProvenanceReference.release_clearance(manifest, [record_a, malformed_record_b]) ==
             expected

    assert_diagnostic(
      expected,
      "catalogue.provenance_reference.resolved_record_invalid",
      "resolved_records[1]"
    )
  end

  defp reference(source_group, overrides \\ %{}) do
    Map.merge(
      %{
        "source_group" => source_group,
        "authority" => @authority,
        "evidence_refs" => ["test/evidence/source-a"]
      },
      overrides
    )
  end

  defp resolved_record(source_group, overrides \\ %{}) do
    Map.merge(
      %{
        "source_group" => source_group,
        "authority" => @authority,
        "evidence_refs" => ["test/evidence/source-a"],
        "redistribution_status" => "unknown",
        "publication_state" => "classified",
        "clearance_evidence_refs" => []
      },
      overrides
    )
  end

  defp cleared_record(
         source_group,
         clearance_evidence_refs,
         overrides \\ %{}
       ) do
    resolved_record(
      source_group,
      Map.merge(
        %{
          "evidence_refs" => Enum.uniq(["test/evidence/source-a" | clearance_evidence_refs]),
          "redistribution_status" => "approved",
          "publication_state" => "public_safe",
          "clearance_evidence_refs" => clearance_evidence_refs
        },
        overrides
      )
    )
  end

  defp decoded_manifest(references) do
    assert {:ok, manifest} =
             @base_manifest
             |> Map.put("provenance", %{"references" => references})
             |> Jason.encode!()
             |> Manifest.decode()

    manifest
  end

  defp assert_diagnostic({:error, [%{code: code, path: path, message: message}]}, code, path) do
    assert is_binary(message)
  end
end
