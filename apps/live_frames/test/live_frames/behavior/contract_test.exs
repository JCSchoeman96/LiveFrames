defmodule LiveFrames.Behavior.ContractTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Behavior.Contract
  alias LiveFrames.IR.Identity

  test "uses the current BehaviorContract format version" do
    assert Contract.current_format_version() == "1.0.0"
  end

  test "new contracts have only the B1 fields and defaults" do
    contract = Contract.new()

    assert Map.keys(contract) |> Enum.sort() ==
             [
               :__struct__,
               :contract_format_version,
               :design_document_identity,
               :bindings,
               :diagnostics,
               :provenance
             ]
             |> Enum.sort()

    assert contract.contract_format_version == "1.0.0"
    assert contract.design_document_identity == nil
    assert contract.bindings == []
    assert contract.diagnostics == []
    assert contract.provenance == %{}
  end

  test "design document identity uses the existing IR identity type" do
    identity = %Identity{
      ir_version: "3.0.0",
      canonicalization_id: "lf-ir-serializer-v1",
      digest_algorithm: "sha-256",
      digest: String.duplicate("a", 64)
    }

    assert %Contract{design_document_identity: ^identity} =
             Contract.new(design_document_identity: identity)
  end
end
