defmodule LiveFrames.Behavior.BindingContainmentTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Behavior.Binding
  alias LiveFrames.Behavior.Binding.ControlledTarget
  alias LiveFrames.Behavior.Binding.FocusPolicy
  alias LiveFrames.Behavior.Binding.PrimitiveRef
  alias LiveFrames.Behavior.Binding.Trigger
  alias LiveFrames.Behavior.BindingContainment
  alias LiveFrames.Behavior.BindingIdentity
  alias LiveFrames.Behavior.Contract
  alias LiveFrames.Behavior.Diagnostic
  alias LiveFrames.IR.{DesignDocument, DesignNode, Identity, Interaction}

  test "reference index records the closed Behavior and IR reference roles" do
    root_id = "node_000001"
    target_id = "node_000001_000001"

    document = %DesignDocument{
      root_nodes: [
        %DesignNode{
          node_id: root_id,
          semantic_type: "section",
          children: [
            %DesignNode{
              node_id: target_id,
              semantic_type: "unsupported",
              interaction_refs: ["interaction-1"]
            }
          ]
        }
      ],
      interactions: %{
        "interaction-1" => %Interaction{
          interaction_id: "interaction-1",
          intent: "activate",
          target_node_ids: [target_id]
        }
      }
    }

    focus = %FocusPolicy{
      initial_target_node_id: target_id,
      scope_node_id: target_id,
      restoration_target_node_id: target_id,
      restoration_fallback_node_id: target_id
    }

    binding = %Binding{
      primitive_ref: %PrimitiveRef{kind: "future-primitive", definition_version: "9.9.9"},
      owner_node_id: root_id,
      binding_role: "reference-index",
      triggers: [%Trigger{kind: "activate", origin_node_id: target_id}],
      controlled_targets: [%ControlledTarget{role: "content", node_id: target_id}],
      focus_policy: focus
    }

    contract = reviewed_contract(document, [binding])

    expected_roles =
      MapSet.new([
        :controlled_target,
        :focus_reference,
        :ir_interaction_ref,
        :ir_interaction_target,
        :trigger_origin
      ])

    assert {:ok, index} = BindingContainment.reference_index(document, contract)

    assert index == %{root_id => MapSet.new([:binding_owner]), target_id => expected_roles}
  end

  test "reference index returns Behavior diagnostics for malformed authority inputs" do
    assert {:error, diagnostics} =
             BindingContainment.reference_index(
               %DesignDocument{root_nodes: :malformed},
               %Contract{}
             )

    assert diagnostics != []
    assert Enum.all?(diagnostics, &match?(%Diagnostic{}, &1))
  end

  test "classifies contained, outside, split, and unresolved binding references" do
    document = document()
    values = ids()
    boundary = values.candidate
    context = BindingContainment.prepare(document, boundary)

    contained =
      test_binding(
        owner: values.candidate,
        origin: values.control,
        target: values.presentation
      )

    outside =
      test_binding(
        owner: values.outside,
        origin: values.focus_outside,
        target: values.focus_outside
      )

    split =
      test_binding(
        owner: values.outside,
        origin: values.control,
        target: values.presentation
      )

    unresolved = test_binding(target: "missing-node")

    assert :contained == BindingContainment.classify_binding(contained, context)
    assert :outside_candidate == BindingContainment.classify_binding(outside, context)
    assert :split == BindingContainment.classify_binding(split, context)
    assert :unresolved == BindingContainment.classify_binding(unresolved, context)
  end

  test "focus policy node references participate in binding classification" do
    document = document()
    values = ids()
    context = BindingContainment.prepare(document, values.candidate)

    inside_focus =
      test_binding(
        owner: values.candidate,
        origin: values.control,
        target: values.presentation,
        focus_policy: focus_policy(values.focus_inside)
      )

    outside_focus =
      test_binding(
        owner: values.candidate,
        origin: values.control,
        target: values.presentation,
        focus_policy: focus_policy(values.focus_outside)
      )

    assert :contained == BindingContainment.classify_binding(inside_focus, context)
    assert :split == BindingContainment.classify_binding(outside_focus, context)
  end

  test "nil trigger origins and nil focus references are ignored for classification" do
    document = document()
    values = ids()
    context = BindingContainment.prepare(document, values.candidate)

    binding =
      %Binding{
        primitive_ref: %PrimitiveRef{kind: "future-primitive", definition_version: "9.9.9"},
        owner_node_id: values.candidate,
        binding_role: "primary",
        triggers: [%Trigger{kind: "timer", origin_node_id: nil}],
        controlled_targets: [
          %ControlledTarget{role: "content", node_id: values.presentation}
        ],
        focus_policy: %FocusPolicy{
          initial_target_node_id: nil,
          scope_node_id: nil,
          restoration_target_node_id: nil,
          restoration_fallback_node_id: nil
        }
      }

    assert :contained == BindingContainment.classify_binding(binding, context)
  end

  test "IR interaction refs outside the boundary do not change an otherwise contained binding disposition" do
    values = ids()

    document = %DesignDocument{
      root_nodes: [
        %DesignNode{
          node_id: values.root,
          semantic_type: "section",
          children: [
            %DesignNode{
              node_id: values.candidate,
              semantic_type: "container",
              children: [
                %DesignNode{node_id: values.control, semantic_type: "button"},
                %DesignNode{node_id: values.presentation, semantic_type: "paragraph"}
              ]
            },
            %DesignNode{
              node_id: values.outside,
              semantic_type: "container",
              interaction_refs: ["interaction-outside"],
              children: [
                %DesignNode{node_id: values.focus_outside, semantic_type: "button"}
              ]
            }
          ]
        }
      ],
      interactions: %{
        "interaction-outside" => %Interaction{
          interaction_id: "interaction-outside",
          intent: "activate",
          target_node_ids: [values.focus_outside]
        }
      }
    }

    contained_binding =
      test_binding(
        owner: values.candidate,
        origin: values.control,
        target: values.presentation
      )

    context = BindingContainment.prepare(document, values.candidate)

    assert :contained == BindingContainment.classify_binding(contained_binding, context)

    assert {:ok, index} =
             BindingContainment.reference_index(
               document,
               reviewed_contract(document, [contained_binding])
             )

    assert MapSet.member?(index[values.outside], :ir_interaction_ref)
    assert MapSet.member?(index[values.focus_outside], :ir_interaction_target)
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

  defp test_binding(opts) do
    values = ids()

    %Binding{
      primitive_ref: %PrimitiveRef{kind: "future-primitive", definition_version: "9.9.9"},
      owner_node_id: Keyword.get(opts, :owner, values.candidate),
      binding_role: "primary",
      triggers: [
        %Trigger{
          kind: "activate",
          origin_node_id: Keyword.get(opts, :origin, values.control)
        }
      ],
      controlled_targets: [
        %ControlledTarget{
          role: "content",
          node_id: Keyword.get(opts, :target, values.presentation)
        }
      ],
      focus_policy: Keyword.get(opts, :focus_policy)
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

  defp reviewed_contract(document, bindings) do
    {:ok, identity} = Identity.from_document(document)

    {:ok, contract} =
      BindingIdentity.assign(%Contract{design_document_identity: identity, bindings: bindings})

    contract
  end
end
