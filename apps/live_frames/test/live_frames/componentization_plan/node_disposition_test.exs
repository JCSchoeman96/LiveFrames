defmodule LiveFrames.ComponentizationPlan.NodeDispositionTest do
  use ExUnit.Case, async: true

  alias LiveFrames.ComponentizationPlan.NodeDisposition

  @digest String.duplicate("a", 64)
  @review_id "brv_" <> String.duplicate("b", 64)

  defp valid_disposition(attrs \\ []) do
    struct!(
      NodeDisposition,
      Keyword.merge(
        [
          design_node_id: "node_000001_000001",
          disposition: :exclude_source_runtime_carrier,
          source_type: "source_type_1",
          source_id: "source_1",
          behavior_binding_id: "binding_1",
          behavior_contract_digest: @digest,
          behavior_review_id: @review_id,
          evidence_refs: ["evidence_a", "evidence_z"]
        ],
        attrs
      )
    )
  end

  defp assert_invalid({:error, diagnostics} = result) do
    assert diagnostics != []

    assert Enum.all?(diagnostics, fn diagnostic ->
             String.starts_with?(diagnostic.code, "componentization_plan.node_disposition.")
           end)

    result
  end

  test "validates the exact accepted NodeDisposition struct" do
    assert Code.ensure_loaded?(NodeDisposition)
    disposition = valid_disposition()

    assert Map.keys(disposition) |> Enum.sort() ==
             [
               :__struct__,
               :behavior_binding_id,
               :behavior_contract_digest,
               :behavior_review_id,
               :design_node_id,
               :disposition,
               :evidence_refs,
               :source_id,
               :source_type
             ]

    assert NodeDisposition.validate(disposition) == :ok
  end

  test "rejects values that are not the exact NodeDisposition struct" do
    assert Code.ensure_loaded?(NodeDisposition)
    disposition = valid_disposition()

    for value <- [
          :not_a_disposition,
          Map.from_struct(disposition),
          Map.put(disposition, :__struct__, __MODULE__)
        ] do
      assert_invalid(NodeDisposition.validate(value))
    end
  end

  test "rejects missing and unexpected struct fields" do
    assert Code.ensure_loaded?(NodeDisposition)
    disposition = valid_disposition()

    assert_invalid(NodeDisposition.validate(Map.delete(disposition, :source_type)))
    assert_invalid(NodeDisposition.validate(Map.put(disposition, :unexpected, "value")))
  end

  test "rejects empty and invalid UTF-8 string fields" do
    assert Code.ensure_loaded?(NodeDisposition)

    for field <- [
          :design_node_id,
          :source_type,
          :source_id,
          :behavior_binding_id,
          :behavior_contract_digest,
          :behavior_review_id
        ],
        value <- ["", <<255>>] do
      assert_invalid(NodeDisposition.validate(valid_disposition([{field, value}])))
    end
  end

  test "accepts only the source runtime carrier disposition" do
    assert Code.ensure_loaded?(NodeDisposition)

    for outcome <- [:ignore, :exclude, "exclude_source_runtime_carrier", nil] do
      assert_invalid(NodeDisposition.validate(valid_disposition(disposition: outcome)))
    end
  end

  test "requires a 64 character lowercase Behavior contract digest" do
    assert Code.ensure_loaded?(NodeDisposition)

    for digest <- [
          String.duplicate("A", 64),
          String.duplicate("g", 64),
          String.duplicate("a", 63)
        ] do
      assert_invalid(
        NodeDisposition.validate(valid_disposition(behavior_contract_digest: digest))
      )
    end
  end

  test "requires a brv-prefixed 64 character lowercase Behavior review ID" do
    assert Code.ensure_loaded?(NodeDisposition)

    for review_id <- [
          String.duplicate("b", 64),
          "brv_" <> String.duplicate("B", 64),
          "brv_" <> String.duplicate("b", 63)
        ] do
      assert_invalid(NodeDisposition.validate(valid_disposition(behavior_review_id: review_id)))
    end
  end

  test "requires a proper non-empty list of non-empty UTF-8 evidence references" do
    assert Code.ensure_loaded?(NodeDisposition)

    for refs <- [[], [""], [<<255>>], [1], ["evidence" | :tail]] do
      assert_invalid(NodeDisposition.validate(valid_disposition(evidence_refs: refs)))
    end
  end

  test "rejects duplicate evidence references" do
    assert Code.ensure_loaded?(NodeDisposition)
    refs = ["evidence_a", "evidence_a"]

    first = NodeDisposition.validate(valid_disposition(evidence_refs: refs))
    assert_invalid(first)
    assert first == NodeDisposition.validate(valid_disposition(evidence_refs: refs))
  end

  test "rejects evidence references that are not in Unicode scalar order" do
    assert Code.ensure_loaded?(NodeDisposition)
    refs = ["z", "a"]

    first = NodeDisposition.validate(valid_disposition(evidence_refs: refs))
    assert_invalid(first)
    assert first == NodeDisposition.validate(valid_disposition(evidence_refs: refs))
  end

  test "accepts evidence references in ascending Unicode scalar order" do
    assert Code.ensure_loaded?(NodeDisposition)
    assert NodeDisposition.validate(valid_disposition(evidence_refs: ["Z", "a", "é"])) == :ok
  end

  test "validates disposition lists in ascending UTF-8 design node ID order" do
    assert Code.ensure_loaded?(NodeDisposition)
    first = valid_disposition(design_node_id: "node_10")
    second = valid_disposition(design_node_id: "node_2")

    assert NodeDisposition.validate_list([first, second]) == :ok
    assert_invalid(NodeDisposition.validate_list([second, first]))
  end

  test "rejects duplicate design node IDs in a disposition list" do
    assert Code.ensure_loaded?(NodeDisposition)
    first = valid_disposition()
    second = valid_disposition(source_id: "source_2")

    assert_invalid(NodeDisposition.validate_list([first, second]))
  end

  test "rejects non-list and improper disposition lists" do
    assert Code.ensure_loaded?(NodeDisposition)
    disposition = valid_disposition()

    assert_invalid(NodeDisposition.validate_list(:not_a_list))
    assert_invalid(NodeDisposition.validate_list([disposition | :tail]))
  end
end
