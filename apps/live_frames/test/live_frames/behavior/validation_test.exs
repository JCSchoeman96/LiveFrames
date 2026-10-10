defmodule LiveFrames.Behavior.ValidationTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Behavior.Contract
  alias LiveFrames.Behavior.Binding
  alias LiveFrames.Behavior.Binding.ControlledTarget
  alias LiveFrames.Behavior.Binding.FocusPolicy
  alias LiveFrames.Behavior.Binding.PrimitiveRef
  alias LiveFrames.Behavior.Binding.ResponsiveBehaviorOverride
  alias LiveFrames.Behavior.Binding.Trigger
  alias LiveFrames.Behavior.BindingIdentity
  alias LiveFrames.Behavior.Diagnostic
  alias LiveFrames.Behavior.Validation
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Identity

  test "accepts a contract linked to the exact valid DesignDocument identity" do
    document = document()
    assert {:ok, identity} = Identity.from_document(document)

    assert :ok =
             Validation.validate_structure(document, %Contract{
               design_document_identity: identity
             })
  end

  test "rejects a contract with a different DesignDocument identity" do
    document = document()

    mismatched = %Identity{
      ir_version: "3.0.0",
      canonicalization_id: "lf-ir-serializer-v1",
      digest_algorithm: "sha-256",
      digest: String.duplicate("a", 64)
    }

    assert {:error, [%{code: "behavior.design_document.identity_mismatch", category: "identity"}]} =
             Validation.validate_structure(document, %Contract{
               design_document_identity: mismatched
             })
  end

  test "rejects an invalid DesignDocument through existing IR identity validation" do
    invalid = %DesignDocument{ir_version: "99.0.0"}

    identity = %Identity{
      ir_version: "3.0.0",
      canonicalization_id: "lf-ir-serializer-v1",
      digest_algorithm: "sha-256",
      digest: String.duplicate("a", 64)
    }

    assert {:error, [%{code: "behavior.design_document.invalid", category: "structure"}]} =
             Validation.validate_structure(invalid, %Contract{design_document_identity: identity})
  end

  test "verifies persisted IDs by one complete B2 assignment" do
    document = document()
    assert {:ok, identity} = Identity.from_document(document)
    binding = test_binding(owner_node_id: "node_000001")

    assert {:ok, assigned} =
             BindingIdentity.assign(%Contract{
               design_document_identity: identity,
               bindings: [binding]
             })

    assert :ok = Validation.validate_structure(document, assigned)

    mismatched = %{assigned | bindings: [%{hd(assigned.bindings) | ordinal: 1}]}

    assert {:error, [%{code: "behavior.binding.identity_mismatch", category: "identity"}]} =
             Validation.validate_structure(document, mismatched)
  end

  test "accepts owner and descendant behavior references in the exact document" do
    document = document()

    contract =
      identified_contract(document,
        owner_node_id: "node_000001",
        initial_state: %{"unknown_dimension" => "unknown_value"},
        primitive_policy_values: %{"unknown_policy" => ["one", "two"]},
        triggers: [%Trigger{kind: "unregistered-trigger", origin_node_id: "node_000001_000001"}],
        controlled_targets: [
          %ControlledTarget{role: "unknown-role", node_id: "node_000001_000001"}
        ],
        timer_policy: %{"unknown_timer_key" => true},
        keyboard_policy: %{"unknown_keyboard_key" => "unknown"},
        motion_policy: %{"unknown_motion_key" => false},
        responsive_overrides: [
          %ResponsiveBehaviorOverride{
            mode: "unknown-mode",
            authority_ref: "unknown-but-structural-authority",
            state_mapping: %{"unknown_state" => "unknown_value"}
          }
        ],
        focus_policy: %FocusPolicy{
          initial_strategy: "unknown-strategy",
          initial_target_node_id: "node_000001_000001",
          containment_strategy: "unknown-containment",
          movement_strategy: "unknown-movement",
          scope_node_id: "node_000001_000001",
          restoration_strategy: "unknown-restoration",
          restoration_target_node_id: "node_000001_000001",
          restoration_fallback_node_id: "node_000001_000001"
        }
      )

    assert :ok = Validation.validate_structure(document, contract)
  end

  test "rejects unresolved behavior references" do
    document = document()

    contract =
      identified_contract(document,
        owner_node_id: "node_000001",
        controlled_targets: [%ControlledTarget{role: "content", node_id: "missing-node"}]
      )

    assert {:error,
            [
              %{
                code: "behavior.reference.unresolved",
                category: "reference",
                node_id: "missing-node"
              }
            ]} =
             Validation.validate_structure(document, contract)
  end

  test "rejects behavior references outside the binding owner subtree" do
    document = document()

    contract =
      identified_contract(document,
        owner_node_id: "node_000001",
        controlled_targets: [%ControlledTarget{role: "content", node_id: "node_000002"}]
      )

    assert {:error,
            [
              %{
                code: "behavior.reference.outside_owner",
                category: "reference",
                node_id: "node_000002"
              }
            ]} =
             Validation.validate_structure(document, contract)
  end

  test "checks each typed binding reference against the owner subtree" do
    document = document()
    external_id = "node_000002"

    escaped_bindings = [
      [triggers: [%Trigger{kind: "activate", origin_node_id: external_id}]],
      [controlled_targets: [%ControlledTarget{role: "content", node_id: external_id}]],
      [focus_policy: %FocusPolicy{initial_target_node_id: external_id}],
      [focus_policy: %FocusPolicy{scope_node_id: external_id}],
      [focus_policy: %FocusPolicy{restoration_target_node_id: external_id}],
      [focus_policy: %FocusPolicy{restoration_fallback_node_id: external_id}]
    ]

    for attrs <- escaped_bindings do
      assert {:error,
              [
                %{
                  code: "behavior.reference.outside_owner",
                  category: "reference",
                  node_id: ^external_id
                }
              ]} =
               Validation.validate_structure(
                 document,
                 identified_contract(document, [owner_node_id: "node_000001"] ++ attrs)
               )
    end
  end

  test "diagnostic node references are document-wide and evidence IDs stay opaque" do
    document = document()

    contract =
      identified_contract(document,
        owner_node_id: "node_000001",
        diagnostics: [
          %Diagnostic{
            code: "behavior.note",
            severity: "warning",
            category: "provenance",
            node_id: "node_000002",
            evidence_id: "opaque-with-no-provenance-entry",
            message: "Retained evidence"
          }
        ]
      )

    assert :ok = Validation.validate_structure(document, contract)

    binding_diagnostic_contract =
      identified_contract(document,
        owner_node_id: "node_000001",
        binding_diagnostics: [
          %Diagnostic{
            code: "behavior.binding.note",
            severity: "warning",
            category: "provenance",
            node_id: "node_000002",
            evidence_id: "no-provenance-key",
            message: "Binding evidence"
          }
        ]
      )

    assert :ok = Validation.validate_structure(document, binding_diagnostic_contract)

    unresolved = %{
      contract
      | diagnostics: [%{hd(contract.diagnostics) | node_id: "missing-node"}]
    }

    assert {:error,
            [
              %{
                code: "behavior.diagnostic.node_unresolved",
                category: "reference",
                node_id: "missing-node"
              }
            ]} =
             Validation.validate_structure(document, unresolved)
  end

  defp document do
    %DesignDocument{
      root_nodes: [
        %DesignNode{
          node_id: "node_000001",
          semantic_type: "section",
          children: [DesignNode.new([1, 1], semantic_type: "generic")]
        },
        DesignNode.new([2], semantic_type: "section")
      ]
    }
  end

  defp test_binding(attrs) do
    %Binding{
      primitive_ref: %PrimitiveRef{kind: "unknown-primitive", definition_version: "9.9.9"},
      owner_node_id: "node_000001",
      binding_role: "primary"
    }
    |> struct(attrs)
  end

  defp identified_contract(document, attrs) do
    {diagnostics, attrs} = Keyword.pop(attrs, :diagnostics, [])
    {binding_diagnostics, binding_attrs} = Keyword.pop(attrs, :binding_diagnostics, [])
    assert {:ok, identity} = Identity.from_document(document)

    binding = %{test_binding(binding_attrs) | diagnostics: binding_diagnostics}

    assert {:ok, contract} =
             BindingIdentity.assign(%Contract{
               design_document_identity: identity,
               bindings: [binding],
               diagnostics: diagnostics
             })

    contract
  end
end
