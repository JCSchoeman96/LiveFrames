defmodule LiveFrames.IR.IdentityTest do
  use ExUnit.Case, async: true

  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.Diagnostic
  alias LiveFrames.IR
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Identity

  @baseline_golden_digest "f0cc7b053b89b1522b3f336a53c31c461f645fa30077aeefa611bfb95de123e3"

  defp valid_document do
    %DesignDocument{root_nodes: [DesignNode.new([1], semantic_type: "section")]}
  end

  test "derives identity metadata and preserves the baseline digest" do
    document = valid_document()

    assert Identity.canonicalization_id() == "lf-ir-serializer-v1"
    assert Identity.digest_algorithm() == "sha-256"
    assert {:ok, identity} = Identity.from_document(document)
    assert identity.ir_version == "3.0.0"
    assert identity.canonicalization_id == "lf-ir-serializer-v1"
    assert identity.digest_algorithm == "sha-256"
    assert identity.digest == @baseline_golden_digest
    assert identity.digest =~ ~r/\A[0-9a-f]{64}\z/
  end

  test "hashes the exact existing IR encoding and is deterministic" do
    document = valid_document()
    expected = :crypto.hash(:sha256, IR.encode!(document)) |> Base.encode16(case: :lower)

    assert {:ok, identity} = Identity.from_document(document)
    assert identity.digest == expected
    assert {:ok, ^identity} = Identity.from_document(document)
  end

  test "changes the digest when valid document semantics change" do
    document = valid_document()

    changed =
      put_in(document.root_nodes, [%{hd(document.root_nodes) | semantic_type: "container"}])

    assert :ok == IR.validate(changed)
    assert {:ok, original_identity} = Identity.from_document(document)
    assert {:ok, changed_identity} = Identity.from_document(changed)
    assert original_identity.digest != changed_identity.digest
  end

  test "returns existing IR diagnostics for invalid documents before hashing" do
    invalid_documents = [
      :not_a_design_document,
      %{valid_document() | ir_version: "99.0.0"},
      %{
        valid_document()
        | root_nodes: [%DesignNode{node_id: "invalid", semantic_type: "section"}]
      }
    ]

    for document <- invalid_documents do
      assert {:error, diagnostics} = IR.validate(document)
      assert {:error, ^diagnostics} = Identity.from_document(document)
    end
  end

  test "reports only the supported canonicalization and digest identifiers" do
    assert Identity.supported_canonicalization_id?("lf-ir-serializer-v1")
    refute Identity.supported_canonicalization_id?("unknown")
    refute Identity.supported_canonicalization_id?(nil)

    assert Identity.supported_digest_algorithm?("sha-256")
    refute Identity.supported_digest_algorithm?("unknown")
    refute Identity.supported_digest_algorithm?(nil)
  end

  test "keeps the ComponentizationPlan digest API as an identity delegate" do
    document = valid_document()
    assert {:ok, identity} = Identity.from_document(document)
    assert ComponentizationPlan.design_document_sha256(document) == {:ok, identity.digest}
  end

  test "preserves the ComponentizationPlan fingerprint error contract" do
    expected_error =
      {:error,
       [
         %Diagnostic{
           code: "componentization_plan.design_document.fingerprint_invalid",
           severity: :error,
           message: "DesignDocument must be valid before its canonical bytes can be fingerprinted"
         }
       ]}

    for invalid_document <- [
          :not_a_design_document,
          %{valid_document() | ir_version: "99.0.0"},
          %{
            valid_document()
            | root_nodes: [%DesignNode{node_id: "invalid", semantic_type: "section"}]
          }
        ] do
      assert ComponentizationPlan.design_document_sha256(invalid_document) == expected_error
    end
  end

  test "keeps ComponentizationPlan 1.0.0 and its serialized field set" do
    plan = %ComponentizationPlan{
      contract_id: "component",
      boundary_node_id: "node_000001",
      design_document_sha256: @baseline_golden_digest
    }

    assert ComponentizationPlan.current_format_version() == "1.0.0"
    assert plan.plan_format_version == "1.0.0"

    expected_fields =
      ~w(boundary_node_id contract_id design_document_sha256 diagnostics plan_format_version provenance render_projections)

    assert ComponentizationPlan.to_map(plan) |> Map.keys() |> Enum.sort() == expected_fields
    assert {:ok, encoded} = ComponentizationPlan.encode(plan)
    assert Jason.decode!(encoded) |> Map.keys() |> Enum.sort() == expected_fields
  end
end
