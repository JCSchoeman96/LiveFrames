defmodule LiveFrames.IR.IdentityTest do
  use ExUnit.Case, async: true

  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.Diagnostic
  alias LiveFrames.IR
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Identity
  alias LiveFrames.Fidelity.DocumentLoader

  @baseline_golden_digest "db122326699eef1df1da1b6f967f201d5372c3ab7e3efda3b649a36aed710cf2"

  defp valid_document do
    %DesignDocument{root_nodes: [DesignNode.new([1], semantic_type: "section")]}
  end

  test "derives identity metadata and preserves the baseline digest" do
    document = valid_document()

    assert Identity.canonicalization_id() == "lf-ir-serializer-v1"
    assert Identity.digest_algorithm() == "sha-256"
    assert {:ok, identity} = Identity.from_document(document)
    assert identity.ir_version == "4.0.0"
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

  test "includes the v4 modifier in the canonical document identity" do
    node_id = DesignNode.deterministic_id([1])

    document_with_modifier = fn modifier ->
      map = %{
        "ir_version" => "4.0.0",
        "source_metadata" => %{},
        "token_set" => %{},
        "root_nodes" => [
          %{
            "node_id" => node_id,
            "semantic_type" => "paragraph",
            "semantic_role" => nil,
            "label" => nil,
            "content" => "Body",
            "attributes" => %{},
            "styles" => %{},
            "responsive" => %{},
            "interaction_refs" => [],
            "asset_refs" => [],
            "children" => [],
            "source_trace" => nil
          }
        ],
        "assets" => %{},
        "interactions" => %{},
        "collection_bindings" => %{},
        "value_bindings" => %{
          "value_001" => %{
            "value_binding_id" => "value_001",
            "target_node_id" => node_id,
            "target_kind" => "text",
            "value_kind" => "field",
            "scope" => "site",
            "value_key" => "content.body",
            "collection_binding_id" => nil,
            "modifier" => modifier,
            "normalization_status" => "normalized",
            "source_trace" => nil
          }
        },
        "diagnostics" => [],
        "provenance" => %{}
      }

      assert {:ok, document} = DocumentLoader.from_map(map)
      document
    end

    none = document_with_modifier.(%{"status" => "none"})

    resolved =
      document_with_modifier.(%{
        "status" => "resolved",
        "kind" => "word_limit",
        "arguments" => %{"count" => 16}
      })

    assert {:ok, none_identity} = Identity.from_document(none)
    assert {:ok, resolved_identity} = Identity.from_document(resolved)
    assert none_identity.ir_version == "4.0.0"
    assert resolved_identity.ir_version == "4.0.0"
    assert none_identity.digest != resolved_identity.digest
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

  test "keeps historical ComponentizationPlan 1.0.0 serialized field set" do
    plan = %ComponentizationPlan{
      plan_format_version: "1.0.0",
      contract_id: "component",
      boundary_node_id: "node_000001",
      design_document_sha256: @baseline_golden_digest
    }

    assert plan.plan_format_version == "1.0.0"

    expected_fields =
      ~w(boundary_node_id contract_id design_document_sha256 diagnostics plan_format_version provenance render_projections)

    plan_map = ComponentizationPlan.to_map(plan)
    assert Map.keys(plan_map) |> Enum.sort() == expected_fields
    refute Map.has_key?(plan_map, "node_dispositions")

    assert {:ok, encoded} = ComponentizationPlan.encode(plan)
    decoded = Jason.decode!(encoded)
    assert Map.keys(decoded) |> Enum.sort() == expected_fields
    refute Map.has_key?(decoded, "node_dispositions")
  end
end
