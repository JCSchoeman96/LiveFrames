defmodule LiveFrames.Behavior.ComponentizationDecisionTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Behavior.Binding
  alias LiveFrames.Behavior.Binding.ControlledTarget
  alias LiveFrames.Behavior.Binding.FocusPolicy
  alias LiveFrames.Behavior.Binding.PrimitiveRef
  alias LiveFrames.Behavior.Binding.Trigger
  alias LiveFrames.Behavior.BindingIdentity
  alias LiveFrames.Behavior.ComponentizationDecision
  alias LiveFrames.Behavior.Contract
  alias LiveFrames.Behavior.Diagnostic
  alias LiveFrames.Behavior.ReviewResult
  alias LiveFrames.Behavior.Serializer
  alias LiveFrames.Behavior.Validation
  alias LiveFrames.ComponentizationProposer
  alias LiveFrames.ComponentizationProposer.SemanticInput
  alias LiveFrames.ComponentizationProposer.SemanticInput.BoundaryDecision
  alias LiveFrames.ComponentizationProposer.SemanticInput.ClassificationDecision
  alias LiveFrames.ComponentizationProposer.SemanticInput.ContractIdentityDecision
  alias LiveFrames.IR.{DesignDocument, DesignNode, Identity}

  test "contained binding admits and passes the validated canonical input to the proposer" do
    document = document()
    contract = reviewed_contract(document, [behavior_binding(owner: ids().candidate)])
    review = approved_review(document, contract)
    input = semantic_input(ids().candidate)

    assert {:ok, canonical_input} = SemanticInput.validate(input, document)
    direct_result = ComponentizationProposer.propose(document, canonical_input)

    assert {:ok, decision, gated_result} =
             ComponentizationDecision.propose(document, contract, review, input)

    assert decision.outcome == :admissible
    assert decision.design_document_identity == elem(Identity.from_document(document), 1)
    assert decision.behavior_contract_digest == elem(Serializer.digest(contract), 1)
    assert decision.behavior_review_result_id == elem(ReviewResult.id(review), 1)
    assert decision.semantic_input == canonical_input
    assert decision.boundary_node_id == ids().candidate

    assert decision.binding_dispositions == [
             %{binding_id: hd(contract.bindings).binding_id, disposition: :contained}
           ]

    assert gated_result == direct_result
  end

  test "a binding wholly outside the candidate is irrelevant and remains admissible" do
    document = document()
    values = ids()

    contract =
      reviewed_contract(document, [
        behavior_binding(
          owner: values.outside,
          origin: values.focus_outside,
          target: values.focus_outside
        )
      ])

    assert {:ok, decision, _result} =
             ComponentizationDecision.propose(
               document,
               contract,
               approved_review(document, contract),
               semantic_input(values.candidate)
             )

    assert decision.outcome == :admissible
    assert hd(decision.binding_dispositions).disposition == :outside_candidate
  end

  test "a split binding is rejected with the D0 containment diagnostic" do
    document = document()
    values = ids()
    contract = reviewed_contract(document, [behavior_binding(owner: values.outside)])

    assert {:error, decision} =
             ComponentizationDecision.propose(
               document,
               contract,
               approved_review(document, contract),
               semantic_input(values.candidate)
             )

    assert decision.outcome == :rejected
    assert hd(decision.binding_dispositions).disposition == :split

    assert %Diagnostic{
             code: "behavior.componentization.binding_split",
             severity: "error",
             category: "projection",
             binding_id: binding_id,
             node_id: nil,
             message: "Behavior binding crosses the proposed component boundary"
           } = hd(decision.diagnostics)

    assert binding_id == hd(contract.bindings).binding_id
  end

  test "trigger origins and controlled targets participate in containment" do
    document = document()
    values = ids()

    contracts = [
      reviewed_contract(document, [
        behavior_binding(owner: values.root, origin: values.control, target: values.focus_outside)
      ]),
      reviewed_contract(document, [
        behavior_binding(
          owner: values.root,
          origin: values.focus_outside,
          target: values.presentation
        )
      ])
    ]

    for contract <- contracts do
      assert :ok = Validation.validate_structure(document, contract)

      assert {:error, decision} =
               ComponentizationDecision.propose(
                 document,
                 contract,
                 approved_review(document, contract),
                 semantic_input(values.candidate)
               )

      assert decision.outcome == :rejected
      assert hd(decision.binding_dispositions).disposition == :split
    end
  end

  test "an unresolved binding reference is classified and keeps structural diagnostics" do
    document = document()
    values = ids()
    contract = reviewed_contract(document, [behavior_binding(target: "missing-node")])

    assert {:error, decision} =
             ComponentizationDecision.propose(
               document,
               contract,
               approved_review(document, contract),
               semantic_input(values.candidate)
             )

    assert decision.outcome == :rejected
    assert hd(decision.binding_dispositions).disposition == :unresolved
    assert Enum.any?(decision.diagnostics, &(&1.code == "behavior.reference.unresolved"))

    assert Enum.any?(decision.diagnostics, fn diagnostic ->
             diagnostic.code == "behavior.componentization.binding_unresolved" and
               diagnostic.binding_id == hd(contract.bindings).binding_id and
               diagnostic.node_id == nil and
               diagnostic.message ==
                 "Behavior binding contains an unresolved DesignNode reference"
           end)
  end

  test "nil FocusPolicy scope uses the owner without adding a reference" do
    document = document()

    focus = %FocusPolicy{
      initial_strategy: "first",
      initial_target_node_id: ids().focus_inside,
      containment_strategy: "none",
      movement_strategy: "none",
      scope_node_id: nil,
      restoration_strategy: "target",
      restoration_target_node_id: ids().focus_inside,
      restoration_fallback_node_id: ids().focus_inside
    }

    contract = reviewed_contract(document, [behavior_binding(focus_policy: focus)])

    assert {:ok, decision, _result} =
             ComponentizationDecision.propose(
               document,
               contract,
               approved_review(document, contract),
               semantic_input(ids().candidate)
             )

    assert decision.outcome == :admissible
    assert hd(decision.binding_dispositions).disposition == :contained
  end

  test "each explicit FocusPolicy reference participates in candidate containment" do
    values = ids()

    focus_fields = [
      :initial_target_node_id,
      :scope_node_id,
      :restoration_target_node_id,
      :restoration_fallback_node_id
    ]

    for field <- focus_fields do
      inside_focus = focus_policy(values.focus_inside)

      inside_contract =
        reviewed_contract(document(), [behavior_binding(focus_policy: inside_focus)])

      assert {:ok, inside_decision, _result} =
               ComponentizationDecision.propose(
                 document(),
                 inside_contract,
                 approved_review(document(), inside_contract),
                 semantic_input(values.candidate)
               )

      assert inside_decision.outcome == :admissible
      assert hd(inside_decision.binding_dispositions).disposition == :contained

      inside_only_focus = Map.put(focus_policy(values.focus_outside), field, values.focus_inside)

      inside_only_contract =
        reviewed_contract(document(), [
          behavior_binding(
            owner: values.root,
            origin: values.focus_outside,
            target: values.focus_outside,
            focus_policy: inside_only_focus
          )
        ])

      assert :ok = Validation.validate_structure(document(), inside_only_contract)

      assert {:error, inside_only_decision} =
               ComponentizationDecision.propose(
                 document(),
                 inside_only_contract,
                 approved_review(document(), inside_only_contract),
                 semantic_input(values.candidate)
               )

      assert inside_only_decision.outcome == :rejected
      assert hd(inside_only_decision.binding_dispositions).disposition == :split

      outside_focus = Map.put(focus_policy(values.focus_inside), field, values.focus_outside)

      outside_contract =
        reviewed_contract(document(), [
          behavior_binding(owner: values.root, focus_policy: outside_focus)
        ])

      assert {:error, outside_decision} =
               ComponentizationDecision.propose(
                 document(),
                 outside_contract,
                 approved_review(document(), outside_contract),
                 semantic_input(values.candidate)
               )

      assert outside_decision.outcome == :rejected
      assert hd(outside_decision.binding_dispositions).disposition == :split
    end
  end

  test "structural validation admits an unsupported primitive at D0" do
    document = document()
    contract = reviewed_contract(document, [behavior_binding(owner: ids().candidate)])

    assert :ok = Validation.validate_structure(document, contract)
    assert {:error, semantic_diagnostics} = Validation.validate(document, contract)
    assert Enum.any?(semantic_diagnostics, &(&1.category == "semantic"))

    assert {:ok, decision, _result} =
             ComponentizationDecision.propose(
               document,
               contract,
               approved_review(document, contract),
               semantic_input(ids().candidate)
             )

    assert decision.outcome == :admissible
  end

  test "a contract diagnostic node outside the candidate is not a binding reference" do
    document = document()
    values = ids()

    contract =
      reviewed_contract(document, [behavior_binding(owner: values.candidate)],
        diagnostics: [
          %Diagnostic{
            code: "behavior.contract.review_note",
            severity: "warning",
            category: "reference",
            binding_id: nil,
            node_id: values.focus_outside,
            evidence_id: nil,
            message: "Contract evidence refers to a document-wide node",
            suggested_action: nil,
            source_trace: nil
          }
        ]
      )

    assert :ok = Validation.validate_structure(document, contract)

    assert {:ok, decision, _result} =
             ComponentizationDecision.propose(
               document,
               contract,
               approved_review(document, contract),
               semantic_input(values.candidate)
             )

    assert decision.outcome == :admissible
    assert hd(decision.binding_dispositions).disposition == :contained
  end

  test "generic policy and provenance strings do not become node references" do
    document = document()
    values = ids()

    contract =
      reviewed_contract(document, [
        behavior_binding(
          owner: values.candidate,
          primitive_policy_values: %{"opaque" => values.focus_outside},
          provenance: %{"note" => values.focus_outside}
        )
      ])

    assert {:ok, decision, _result} =
             ComponentizationDecision.propose(
               document,
               contract,
               approved_review(document, contract),
               semantic_input(values.candidate)
             )

    assert decision.outcome == :admissible
    assert hd(decision.binding_dispositions).disposition == :contained
  end

  test "contract identity mismatch with a valid different document rejects the tuple" do
    document = document()
    other_document = %{document | source_metadata: %{"revision" => "other"}}
    contract = reviewed_contract(document, [behavior_binding(owner: ids().candidate)])

    assert {:error, decision} =
             ComponentizationDecision.propose(
               other_document,
               contract,
               approved_review(document, contract),
               semantic_input(ids().candidate)
             )

    assert decision.outcome == :rejected
    assert decision.design_document_identity != contract.design_document_identity
    assert decision.diagnostics != []
  end

  test "review digest mismatch fails closed at the review prerequisite" do
    document = document()
    contract = reviewed_contract(document, [behavior_binding(owner: ids().candidate)])

    bad_review = %{
      approved_review(document, contract)
      | behavior_contract_digest: String.duplicate("0", 64)
    }

    assert {:error, {:prerequisite, :behavior_review, diagnostics}} =
             ComponentizationDecision.propose(
               document,
               contract,
               bad_review,
               semantic_input(ids().candidate)
             )

    assert diagnostics != []
  end

  test "review document identity mismatch fails closed" do
    document = document()
    other_document = %{document | source_metadata: %{"revision" => "other"}}
    contract = reviewed_contract(document, [behavior_binding(owner: ids().candidate)])
    {:ok, other_identity} = Identity.from_document(other_document)
    review = %{approved_review(document, contract) | design_document_identity: other_identity}

    assert {:error, {:prerequisite, :behavior_review, diagnostics}} =
             ComponentizationDecision.propose(
               document,
               contract,
               review,
               semantic_input(ids().candidate)
             )

    assert diagnostics != []
  end

  test "a review decision other than approved fails closed" do
    document = document()
    contract = reviewed_contract(document, [behavior_binding(owner: ids().candidate)])
    review = %{approved_review(document, contract) | decision: "needs_review"}

    assert {:error, {:prerequisite, :behavior_review, diagnostics}} =
             ComponentizationDecision.propose(
               document,
               contract,
               review,
               semantic_input(ids().candidate)
             )

    assert diagnostics != []
  end

  test "an invalid SemanticInput boundary is surfaced without repair" do
    document = document()
    contract = reviewed_contract(document, [behavior_binding(owner: ids().candidate)])

    assert {:error, {:prerequisite, :semantic_input, diagnostics}} =
             ComponentizationDecision.propose(
               document,
               contract,
               approved_review(document, contract),
               semantic_input("missing-boundary")
             )

    assert diagnostics != []
  end

  test "binding dispositions and D0 diagnostics have deterministic ordering" do
    document = document()
    values = ids()

    contract =
      reviewed_contract(document, [
        behavior_binding(owner: values.candidate, target: "unresolved-z"),
        behavior_binding(
          owner: values.outside,
          target: values.presentation,
          binding_role: "second"
        ),
        behavior_binding(owner: values.candidate, target: "unresolved-a", binding_role: "third")
      ])

    contract = %{contract | bindings: Enum.sort_by(contract.bindings, & &1.binding_id, :desc)}

    assert {:error, decision} =
             ComponentizationDecision.propose(
               document,
               contract,
               approved_review(document, contract),
               semantic_input(values.candidate)
             )

    disposition_ids = Enum.map(decision.binding_dispositions, & &1.binding_id)
    assert disposition_ids == Enum.sort(disposition_ids)

    containment_diagnostic_ids =
      decision.diagnostics
      |> Enum.filter(
        &(&1.code in [
            "behavior.componentization.binding_split",
            "behavior.componentization.binding_unresolved"
          ])
      )
      |> Enum.map(& &1.binding_id)

    assert containment_diagnostic_ids == Enum.sort(containment_diagnostic_ids)
  end

  defp document do
    %DesignDocument{
      root_nodes: [
        %DesignNode{
          node_id: "node_000001",
          semantic_type: "section",
          children: [
            %DesignNode{
              node_id: "node_000001_000001",
              semantic_type: "container",
              children: [
                %DesignNode{node_id: "node_000001_000001_000001", semantic_type: "button"},
                %DesignNode{node_id: "node_000001_000001_000002", semantic_type: "paragraph"},
                %DesignNode{node_id: "node_000001_000001_000003", semantic_type: "button"}
              ]
            },
            %DesignNode{
              node_id: "node_000001_000002",
              semantic_type: "container",
              children: [
                %DesignNode{node_id: "node_000001_000002_000001", semantic_type: "button"}
              ]
            }
          ]
        }
      ]
    }
  end

  defp ids do
    %{
      root: "node_000001",
      candidate: "node_000001_000001",
      control: "node_000001_000001_000001",
      presentation: "node_000001_000001_000002",
      focus_inside: "node_000001_000001_000003",
      outside: "node_000001_000002",
      focus_outside: "node_000001_000002_000001"
    }
  end

  defp behavior_binding(opts) do
    values = ids()
    owner = Keyword.get(opts, :owner, values.candidate)

    %Binding{
      primitive_ref: %PrimitiveRef{kind: "future-primitive", definition_version: "9.9.9"},
      owner_node_id: owner,
      binding_role: Keyword.get(opts, :binding_role, "primary"),
      primitive_policy_values: Keyword.get(opts, :primitive_policy_values, %{}),
      triggers: [
        %Trigger{kind: "activate", origin_node_id: Keyword.get(opts, :origin, values.control)}
      ],
      controlled_targets: [
        %ControlledTarget{
          role: "content",
          node_id: Keyword.get(opts, :target, values.presentation)
        }
      ],
      focus_policy: Keyword.get(opts, :focus_policy),
      provenance: Keyword.get(opts, :provenance, %{})
    }
  end

  defp focus_policy(node_id) do
    %FocusPolicy{
      initial_strategy: "first",
      initial_target_node_id: node_id,
      containment_strategy: "none",
      movement_strategy: "none",
      scope_node_id: node_id,
      restoration_strategy: "target",
      restoration_target_node_id: node_id,
      restoration_fallback_node_id: node_id
    }
  end

  defp reviewed_contract(document, bindings, attrs \\ []) do
    {:ok, identity} = Identity.from_document(document)

    {:ok, contract} =
      BindingIdentity.assign(
        struct!(%Contract{design_document_identity: identity, bindings: bindings}, attrs)
      )

    contract
  end

  defp approved_review(document, contract) do
    {:ok, identity} = Identity.from_document(document)
    {:ok, digest} = Serializer.digest(contract)

    %ReviewResult{
      review_format_version: "1.0.0",
      design_document_identity: identity,
      behavior_contract_digest_algorithm: Serializer.algorithm(),
      behavior_contract_digest: digest,
      decision: "approved",
      reviewer_identity: "reviewer:p7-d0-test",
      reviewed_at: "2026-10-11T00:00:00.000000Z",
      review_note: nil,
      evidence_refs: ["P7-D0-test"]
    }
  end

  defp semantic_input(boundary_node_id) do
    %SemanticInput{
      contract_identity: %ContractIdentityDecision{contract_id: "test-contract"},
      classification: %ClassificationDecision{
        category: :component,
        module_intent: "Cards",
        function_intent: "card"
      },
      boundary: %BoundaryDecision{boundary_node_id: boundary_node_id}
    }
  end
end
