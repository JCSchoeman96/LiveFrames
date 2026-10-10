defmodule LiveFrames.Behavior.ReviewResultTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Behavior.ReviewResult
  alias LiveFrames.Behavior.Binding
  alias LiveFrames.Behavior.Binding.PrimitiveRef
  alias LiveFrames.Behavior.BindingIdentity
  alias LiveFrames.Behavior.Contract
  alias LiveFrames.Behavior.Serializer
  alias LiveFrames.IR.Identity

  @identity %Identity{
    ir_version: "3.0.0",
    canonicalization_id: "lf-ir-serializer-v1",
    digest_algorithm: "sha-256",
    digest: String.duplicate("a", 64)
  }

  @review_attrs [
    review_format_version: "1.0.0",
    design_document_identity: @identity,
    behavior_contract_digest_algorithm: "lf-behavior-v1-jcs-sha256",
    behavior_contract_digest: String.duplicate("b", 64),
    decision: "approved",
    reviewer_identity: "reviewer:example",
    reviewed_at: "2026-10-10T12:34:56.123456Z",
    review_note: "Reviewed for exact behavior evidence.",
    evidence_refs: ["evidence:z", "evidence:a"]
  ]

  @golden_bytes "{\"behavior_contract_digest\":\"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb\",\"behavior_contract_digest_algorithm\":\"lf-behavior-v1-jcs-sha256\",\"decision\":\"approved\",\"design_document_identity\":{\"canonicalization_id\":\"lf-ir-serializer-v1\",\"digest\":\"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\",\"digest_algorithm\":\"sha-256\",\"ir_version\":\"3.0.0\"},\"evidence_refs\":[\"evidence:a\",\"evidence:z\"],\"review_format_version\":\"1.0.0\",\"review_note\":\"Reviewed for exact behavior evidence.\",\"reviewed_at\":\"2026-10-10T12:34:56.123456Z\",\"reviewer_identity\":\"reviewer:example\"}"
  @golden_id "brv_cca94dfa2c8259d798a9001e3abd620bb0f9e381a1e6dcc8f116f8538d3f8e37"

  test "validates and encodes the frozen review fixture with a derived ID" do
    review = struct(ReviewResult, @review_attrs)

    assert Enum.sort(Map.keys(review)) ==
             Enum.sort([
               :__struct__,
               :review_format_version,
               :design_document_identity,
               :behavior_contract_digest_algorithm,
               :behavior_contract_digest,
               :decision,
               :reviewer_identity,
               :reviewed_at,
               :review_note,
               :evidence_refs
             ])

    assert ReviewResult.algorithm() == "lf-behavior-review-v1-jcs-sha256"
    assert ReviewResult.validate(review) == :ok
    assert {:ok, @golden_bytes} = ReviewResult.encode(review)
    assert {:ok, @golden_id} = ReviewResult.id(review)
  end

  test "rejects malformed result values and unsupported review formats" do
    assert invalid_code(nil) == "behavior.review.invalid"
    assert invalid_code(%{}) == "behavior.review.invalid"

    impostor = Map.put(review(), :extra_field, "unexpected")
    assert invalid_code(impostor) == "behavior.review.invalid"
    assert invalid_code(Map.delete(review(), :review_note)) == "behavior.review.invalid"

    assert invalid_code(review(review_format_version: "2.0.0")) ==
             "behavior.review.format_unsupported"

    assert invalid_code(review(review_format_version: nil)) ==
             "behavior.review.format_unsupported"

    for field <- [
          :design_document_identity,
          :behavior_contract_digest_algorithm,
          :behavior_contract_digest,
          :decision,
          :reviewer_identity,
          :reviewed_at,
          :evidence_refs
        ] do
      assert invalid_code(review([{field, nil}])) == "behavior.review.invalid"
    end
  end

  test "validates exact DesignDocumentIdentity and contract digest syntax" do
    invalid_identities = [
      :not_an_identity,
      Map.put(@identity, :extra_field, true),
      %Identity{@identity | ir_version: "2.0.0"},
      %Identity{@identity | canonicalization_id: "unknown"},
      %Identity{@identity | digest_algorithm: "sha-512"},
      %Identity{@identity | digest: String.duplicate("A", 64)},
      %Identity{@identity | digest: String.duplicate("a", 63)}
    ]

    for identity <- invalid_identities do
      assert invalid_code(review(design_document_identity: identity)) == "behavior.review.invalid"
    end

    assert invalid_code(review(behavior_contract_digest_algorithm: "sha-256")) ==
             "behavior.review.invalid"

    for digest <- [String.duplicate("A", 64), String.duplicate("a", 63)] do
      assert invalid_code(review(behavior_contract_digest: digest)) == "behavior.review.invalid"
    end
  end

  test "validates decisions, reviewer identity, and inert notes" do
    assert invalid_code(review(decision: "approve")) == "behavior.review.invalid"
    assert invalid_code(review(reviewer_identity: "")) == "behavior.review.invalid"
    assert invalid_code(review(reviewer_identity: <<255>>)) == "behavior.review.invalid"
    assert ReviewResult.validate(review(reviewer_identity: " \t ")) == :ok
    assert ReviewResult.validate(review(review_note: "")) == :ok
    assert invalid_code(review(review_note: <<255>>)) == "behavior.review.invalid"
  end

  test "accepts only real UTC timestamps with six fractional digits" do
    for timestamp <- [
          "2026-10-10T12:34:56Z",
          "2026-10-10T12:34:56.123Z",
          "2026-10-10T12:34:56.1234567Z",
          "2026-10-10T12:34:56.123456+00:00",
          "2026-13-99T25:61:61.123456Z"
        ] do
      assert invalid_code(review(reviewed_at: timestamp)) == "behavior.review.invalid"
    end
  end

  test "rejects malformed, unsafe, or duplicated evidence references" do
    assert invalid_code(review(evidence_refs: "evidence:a")) == "behavior.review.invalid"
    assert invalid_code(review(evidence_refs: [""])) == "behavior.review.invalid"
    assert invalid_code(review(evidence_refs: [<<255>>])) == "behavior.review.invalid"

    assert invalid_code(review(evidence_refs: ["evidence:a", "evidence:a"])) ==
             "behavior.review.invalid"

    assert ReviewResult.validate(review(evidence_refs: [])) == :ok

    assert invalid_code(review(evidence_refs: ["evidence:a" | :improper])) ==
             "behavior.review.invalid"
  end

  test "sorts only evidence references and derives identity from every review field" do
    review_a = review(evidence_refs: ["evidence:z", "evidence:a"])
    review_b = review(evidence_refs: ["evidence:a", "evidence:z"])

    assert {:ok, bytes} = ReviewResult.encode(review_a)
    assert {:ok, ^bytes} = ReviewResult.encode(review_b)
    assert {:ok, id} = ReviewResult.id(review_a)
    assert {:ok, ^id} = ReviewResult.id(review_b)

    changes = [
      [decision: "rejected"],
      [reviewer_identity: "reviewer:other"],
      [reviewed_at: "2026-10-10T12:34:56.123457Z"],
      [review_note: nil],
      [review_note: ""],
      [evidence_refs: ["evidence:other"]]
    ]

    ids =
      Enum.map(changes, fn attrs ->
        assert {:ok, changed_id} = ReviewResult.id(review(attrs))
        changed_id
      end)

    assert Enum.uniq([id | ids]) == [id | ids]

    {:ok, nil_note_id} = ReviewResult.id(review(review_note: nil))
    {:ok, empty_note_id} = ReviewResult.id(review(review_note: ""))
    refute nil_note_id == empty_note_id

    original = review()
    revised = review(decision: "rejected")
    assert original.decision == "approved"
    assert revised.decision == "rejected"
  end

  test "matches the exact contract identity, algorithm, and recomputed digest" do
    contract = %Contract{design_document_identity: @identity}
    review = matching_review(contract)

    assert ReviewResult.validate_against_contract(review, contract) == :ok

    changed_identity = %Identity{@identity | digest: String.duplicate("c", 64)}
    different_document_contract = %Contract{design_document_identity: changed_identity}

    assert review_code(
             ReviewResult.validate_against_contract(review, different_document_contract)
           ) ==
             "behavior.review.document_identity_mismatch"

    changed_digest = %Contract{contract | provenance: %{"changed" => true}}

    assert review_code(ReviewResult.validate_against_contract(review, changed_digest)) ==
             "behavior.review.contract_digest_mismatch"

    assert invalid_code(review(behavior_contract_digest_algorithm: "other")) ==
             "behavior.review.invalid"
  end

  test "maps an undigestable contract to the frozen review identity diagnostic" do
    invalid_contract = %Contract{
      design_document_identity: @identity,
      bindings: :not_a_list
    }

    assert review_code(ReviewResult.validate_against_contract(review(), invalid_contract)) ==
             "behavior.review.contract_digest_mismatch"
  end

  test "uses the frozen diagnostic categories and clears unrelated associations" do
    assert review_failure(ReviewResult.validate(nil)) ==
             {"behavior.review.invalid", "structure"}

    assert review_failure(ReviewResult.validate(review(review_format_version: "2.0.0"))) ==
             {"behavior.review.format_unsupported", "structure"}

    contract = %Contract{design_document_identity: @identity}
    matching = matching_review(contract)
    other_identity = %Identity{@identity | digest: String.duplicate("c", 64)}
    different_document = %Contract{design_document_identity: other_identity}

    assert review_failure(ReviewResult.validate_against_contract(matching, different_document)) ==
             {"behavior.review.document_identity_mismatch", "identity"}

    changed_contract = %Contract{contract | provenance: %{"changed" => true}}

    assert review_failure(ReviewResult.validate_against_contract(matching, changed_contract)) ==
             {"behavior.review.contract_digest_mismatch", "identity"}

    assert review_failure(ReviewResult.require_approved([], contract)) ==
             {"behavior.review.result_missing", "structure"}

    assert review_failure(ReviewResult.require_approved([matching, matching], contract)) ==
             {"behavior.review.result_ambiguous", "structure"}

    rejected = matching_review(contract, decision: "rejected")

    assert review_failure(ReviewResult.require_approved([rejected], contract)) ==
             {"behavior.review.not_approved", "semantic"}

    assert {:error, [diagnostic]} = ReviewResult.validate(nil)
    assert diagnostic.severity == "error"
    assert diagnostic.binding_id == nil
    assert diagnostic.node_id == nil
    assert diagnostic.evidence_id == nil
    assert diagnostic.source_trace == nil
  end

  test "requires exactly one matching approved result without selecting by timestamp" do
    contract = %Contract{design_document_identity: @identity}
    approved = matching_review(contract)

    rejected =
      matching_review(contract, decision: "rejected", reviewed_at: "2026-10-11T12:34:56.123456Z")

    needs_review = matching_review(contract, decision: "needs_review")

    assert review_code(ReviewResult.require_approved([], contract)) ==
             "behavior.review.result_missing"

    assert review_code(ReviewResult.require_approved([approved, rejected], contract)) ==
             "behavior.review.result_ambiguous"

    assert review_code(ReviewResult.require_approved([rejected, approved], contract)) ==
             "behavior.review.result_ambiguous"

    assert review_code(ReviewResult.require_approved([approved, approved], contract)) ==
             "behavior.review.result_ambiguous"

    assert review_code(ReviewResult.require_approved([rejected, rejected], contract)) ==
             "behavior.review.result_ambiguous"

    assert ReviewResult.require_approved([approved], contract) == {:ok, approved}

    for result <- [needs_review, rejected] do
      assert review_code(ReviewResult.require_approved([result], contract)) ==
               "behavior.review.not_approved"
    end

    assert review_code(ReviewResult.require_approved([approved | :improper], contract)) ==
             "behavior.review.invalid"

    assert review_code(ReviewResult.require_approved(:not_a_list, contract)) ==
             "behavior.review.invalid"

    assert review_code(ReviewResult.require_approved([:not_a_review_result], contract)) ==
             "behavior.review.invalid"

    mismatched_rejection = matching_review(contract, decision: "rejected")
    different_contract = %Contract{contract | provenance: %{"changed" => true}}

    assert review_code(ReviewResult.require_approved([mismatched_rejection], different_contract)) ==
             "behavior.review.contract_digest_mismatch"
  end

  test "accepts a matching contract with an unknown primitive reference" do
    binding = %Binding{
      primitive_ref: %PrimitiveRef{kind: "future-primitive", definition_version: "9.9.9"},
      owner_node_id: "node-owner",
      binding_role: "primary"
    }

    assert {:ok, contract} =
             BindingIdentity.assign(%Contract{
               design_document_identity: @identity,
               bindings: [binding]
             })

    review = matching_review(contract)

    assert ReviewResult.validate_against_contract(review, contract) == :ok
    assert ReviewResult.require_approved([review], contract) == {:ok, review}
  end

  defp invalid_code(value) do
    assert {:error, [%{severity: "error", category: "structure", code: code}]} =
             ReviewResult.validate(value)

    code
  end

  defp review_code({:error, [%{code: code}]}) do
    code
  end

  defp review_failure({:error, [%{code: code, category: category}]}) do
    {code, category}
  end

  defp matching_review(contract, attrs \\ []) do
    assert {:ok, digest} = Serializer.digest(contract)

    struct(
      ReviewResult,
      Keyword.merge(
        @review_attrs,
        [
          behavior_contract_digest: digest,
          design_document_identity: contract.design_document_identity
        ] ++ attrs
      )
    )
  end

  defp review(attrs \\ []) do
    struct(ReviewResult, Keyword.merge(@review_attrs, attrs))
  end
end
