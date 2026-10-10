defmodule LiveFrames.Behavior.BindingIdentityTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Behavior.Binding
  alias LiveFrames.Behavior.Binding.ControlledTarget
  alias LiveFrames.Behavior.Binding.FocusPolicy
  alias LiveFrames.Behavior.Binding.PrimitiveRef
  alias LiveFrames.Behavior.Binding.ResponsiveBehaviorOverride
  alias LiveFrames.Behavior.Binding.Trigger
  alias LiveFrames.Behavior.BindingIdentity
  alias LiveFrames.Behavior.Contract
  alias LiveFrames.CanonicalJSON
  alias LiveFrames.IR.Identity

  @identity %Identity{
    ir_version: "3.0.0",
    canonicalization_id: "lf-ir-serializer-v1",
    digest_algorithm: "sha-256",
    digest: String.duplicate("a", 64)
  }

  test "exposes the accepted algorithm identifier" do
    assert BindingIdentity.algorithm() == "lf-behavior-binding-v1-jcs-sha256"
  end

  test "assigns a fixed golden ID from the exact contract identity and ordinal" do
    binding = occurrence()
    contract = contract([binding])

    assert {:ok, %Contract{bindings: [%Binding{ordinal: 0, binding_id: id}]}} =
             BindingIdentity.assign(contract)

    assert id == "bnd_a0fbef5fe549adc33e7070a21899cb2d3e83a6df2f1662640e7db8b65df188c4"

    payload = %{
      "behavior_contract_format_version" => "1.0.0",
      "design_document_identity" => %{
        "ir_version" => "3.0.0",
        "canonicalization_id" => "lf-ir-serializer-v1",
        "digest_algorithm" => "sha-256",
        "digest" => String.duplicate("a", 64)
      },
      "owner_node_id" => "node-owner",
      "primitive_kind" => "disclosure",
      "binding_role" => "primary",
      "ordinal" => 0
    }

    assert {:ok,
            ~s|{"behavior_contract_format_version":"1.0.0","binding_role":"primary","design_document_identity":{"canonicalization_id":"lf-ir-serializer-v1","digest":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","digest_algorithm":"sha-256","ir_version":"3.0.0"},"ordinal":0,"owner_node_id":"node-owner","primitive_kind":"disclosure"}|} =
             CanonicalJSON.encode(payload)
  end

  test "preserves binding list order while IDs follow semantic occurrences" do
    first = occurrence(primitive_policy_values: %{"mode" => "alpha"})
    second = occurrence(primitive_policy_values: %{"mode" => "beta"})

    assert {:ok, forward} = BindingIdentity.assign(contract([first, second]))
    assert {:ok, reverse} = BindingIdentity.assign(contract([second, first]))

    assert Enum.map(forward.bindings, & &1.primitive_policy_values) ==
             Enum.map(contract([first, second]).bindings, & &1.primitive_policy_values)

    assert ids_by_policy(forward) == ids_by_policy(reverse)
    assert ordinals_by_policy(forward) == ordinals_by_policy(reverse)
  end

  test "rejects discriminator duplicates after canonicalizing policy object keys" do
    first = occurrence(primitive_policy_values: %{"a" => 1, "b" => 2})
    second = occurrence(primitive_policy_values: %{"b" => 2, "a" => 1})

    assert {:error, :duplicate_semantic_binding} =
             BindingIdentity.assign(contract([first, second]))
  end

  test "canonicalizes nested stable-key objects without changing ordered arrays" do
    first = occurrence(primitive_policy_values: %{"stable" => %{"b" => 2, "a" => 1}})
    second = occurrence(primitive_policy_values: %{"stable" => %{"a" => 1, "b" => 2}})

    assert {:error, :duplicate_semantic_binding} =
             BindingIdentity.assign(contract([first, second]))

    forward = occurrence(primitive_policy_values: %{"sequence" => ["a", "b"]})
    reverse = occurrence(primitive_policy_values: %{"sequence" => ["b", "a"]})

    assert {:ok, identified} = BindingIdentity.assign(contract([forward, reverse]))
    assert Enum.sort(Enum.map(identified.bindings, & &1.ordinal)) == [0, 1]
    assert length(Enum.uniq(Enum.map(identified.bindings, & &1.binding_id))) == 2
  end

  test "canonicalizes initial state and cross-cutting policy objects" do
    first =
      occurrence(
        initial_state: %{"open" => true, "selected" => "item-a"},
        timer_policy: %{"delay" => 100, "enabled" => true},
        keyboard_policy: %{"keys" => ["Enter", "Space"], "mode" => "activate"},
        motion_policy: %{"duration" => 200, "reduced" => false},
        responsive_overrides: [
          %ResponsiveBehaviorOverride{
            mode: "compact",
            authority_ref: "auth",
            state_mapping: %{"open" => true, "selected" => "item-a"}
          }
        ]
      )

    second =
      occurrence(
        initial_state: %{"selected" => "item-a", "open" => true},
        timer_policy: %{"enabled" => true, "delay" => 100},
        keyboard_policy: %{"mode" => "activate", "keys" => ["Enter", "Space"]},
        motion_policy: %{"reduced" => false, "duration" => 200},
        responsive_overrides: [
          %ResponsiveBehaviorOverride{
            mode: "compact",
            authority_ref: "auth",
            state_mapping: %{"selected" => "item-a", "open" => true}
          }
        ]
      )

    assert {:error, :duplicate_semantic_binding} =
             BindingIdentity.assign(contract([first, second]))
  end

  test "canonicalizes trigger and controlled target order" do
    first =
      occurrence(
        triggers: [trigger("activate", "node-a"), trigger("escape", nil)],
        controlled_targets: [target("content", "node-b"), target("label", "node-a")]
      )

    second =
      occurrence(
        triggers: [trigger("escape", nil), trigger("activate", "node-a")],
        controlled_targets: [target("label", "node-a"), target("content", "node-b")]
      )

    assert {:error, :duplicate_semantic_binding} =
             BindingIdentity.assign(contract([first, second]))
  end

  test "canonicalizes responsive overrides by mode and keeps authority semantic" do
    first =
      occurrence(
        responsive_overrides: [override("compact", "auth-a"), override("wide", "auth-b")]
      )

    reordered =
      occurrence(
        responsive_overrides: [override("wide", "auth-b"), override("compact", "auth-a")]
      )

    assert {:error, :duplicate_semantic_binding} =
             BindingIdentity.assign(contract([first, reordered]))

    changed_authority =
      occurrence(
        responsive_overrides: [override("compact", "auth-changed"), override("wide", "auth-b")]
      )

    assert {:ok, identified} = BindingIdentity.assign(contract([first, changed_authority]))
    assert length(Enum.uniq(Enum.map(identified.bindings, & &1.binding_id))) == 2
  end

  test "diagnostics, provenance, source trace, and definition version do not affect identity" do
    original = occurrence()

    changed_nonsemantic = %{
      original
      | diagnostics: [:ignored],
        provenance: %{evidence: "changed"},
        source_trace: %LiveFrames.IR.SourceTrace{source_id: "changed"},
        primitive_ref: %PrimitiveRef{kind: "disclosure", definition_version: "2.0.0"}
    }

    assert {:ok, left} = BindingIdentity.assign(contract([original]))
    assert {:ok, right} = BindingIdentity.assign(contract([changed_nonsemantic]))
    assert hd(left.bindings).binding_id == hd(right.bindings).binding_id

    assert {:error, :duplicate_semantic_binding} =
             BindingIdentity.assign(contract([original, changed_nonsemantic]))
  end

  test "changes the binding ID when the DesignDocument identity changes" do
    binding = occurrence()
    other_identity = %{@identity | digest: String.duplicate("b", 64)}

    assert {:ok, left} = BindingIdentity.assign(contract([binding]))
    assert {:ok, right} = BindingIdentity.assign(contract([binding], other_identity))
    refute hd(left.bindings).binding_id == hd(right.bindings).binding_id
  end

  test "returns an equivalent identified empty contract" do
    input = contract([])
    assert {:ok, ^input} = BindingIdentity.assign(input)
  end

  test "rejects wrong contract format or missing DesignDocument identity" do
    assert {:error, :invalid_contract} =
             BindingIdentity.assign(%{contract([]) | contract_format_version: "2.0.0"})

    assert {:error, :invalid_contract} =
             BindingIdentity.assign(%{contract([]) | design_document_identity: nil})
  end

  test "runs B1 structural validation before identity assignment" do
    valid = occurrence()

    invalid_bindings = [
      %{valid | binding_id: "bnd_preassigned"},
      %{valid | ordinal: 0},
      %{valid | responsive_overrides: [override("compact", "a"), override("compact", "b")]},
      %{valid | focus_policy: %FocusPolicy{scope_node_id: "node-owner"}},
      %{valid | primitive_policy_values: %{not_a_string_key: "value"}},
      %{valid | triggers: [:not_a_trigger]}
    ]

    for invalid <- invalid_bindings do
      assert {:error, {:invalid_binding, 0, {:invalid_structure, _path}}} =
               BindingIdentity.assign(contract([invalid]))
    end
  end

  defp contract(bindings, identity \\ @identity) do
    Contract.new(design_document_identity: identity, bindings: bindings)
  end

  defp occurrence(attrs \\ []) do
    defaults = [
      primitive_ref: %PrimitiveRef{kind: "disclosure", definition_version: "1.0.0"},
      owner_node_id: "node-owner",
      binding_role: "primary"
    ]

    Binding.new(Keyword.merge(defaults, attrs))
  end

  defp trigger(kind, origin), do: %Trigger{kind: kind, origin_node_id: origin}
  defp target(role, node_id), do: %ControlledTarget{role: role, node_id: node_id}

  defp override(mode, authority_ref) do
    %ResponsiveBehaviorOverride{mode: mode, authority_ref: authority_ref, state_mapping: %{}}
  end

  defp ids_by_policy(contract) do
    Map.new(contract.bindings, &{&1.primitive_policy_values, &1.binding_id})
  end

  defp ordinals_by_policy(contract) do
    Map.new(contract.bindings, &{&1.primitive_policy_values, &1.ordinal})
  end
end
