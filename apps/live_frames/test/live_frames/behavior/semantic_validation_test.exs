defmodule LiveFrames.Behavior.SemanticValidationTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Behavior.Binding
  alias LiveFrames.Behavior.Binding.ControlledTarget
  alias LiveFrames.Behavior.Binding.FocusPolicy
  alias LiveFrames.Behavior.Binding.PrimitiveRef
  alias LiveFrames.Behavior.Binding.ResponsiveBehaviorOverride
  alias LiveFrames.Behavior.Binding.Trigger
  alias LiveFrames.Behavior.BindingIdentity
  alias LiveFrames.Behavior.Contract
  alias LiveFrames.Behavior.Validation
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Identity

  @safe_integer 9_007_199_254_740_991
  @selection %PrimitiveRef{kind: "selection", definition_version: "1.0.0"}
  @unsupported %PrimitiveRef{kind: "future-primitive", definition_version: "9.9.9"}
  @timer_policy %{
    "purpose" => "advance_selection",
    "interval_ms" => 5_000,
    "start" => "on_initialization",
    "manual_activation" => "stop",
    "restart" => "never",
    "reset" => "none",
    "reduced_motion" => "disable_automatic_advance"
  }

  test "accepts nil state, explicit zero, positive positions, and the safe-integer maximum" do
    for state <- [
          nil,
          %{"selected_position" => 0},
          %{"selected_position" => 3},
          %{"selected_position" => @safe_integer}
        ] do
      {document, contract} = persisted_contract(initial_state: state)

      assert :ok = Validation.validate_structure(document, contract)
      assert :ok = Validation.validate_semantics(document, contract)
      assert hd(contract.bindings).initial_state == state
    end
  end

  test "rejects invalid Selection state dimensions and values" do
    invalid_states = [
      %{"selected_position" => -1},
      %{"selected_position" => "1"},
      %{"selected_position" => true},
      %{"selected_position" => nil},
      %{"unknown_dimension" => 1},
      %{"selected_position" => 1, "unknown_dimension" => 2},
      %{}
    ]

    for state <- invalid_states do
      {document, contract} = persisted_contract(initial_state: state)
      assert_semantic_code(document, contract, "behavior.semantic.initial_state_invalid")
    end
  end

  test "rejects float and above-safe-range positions at the semantic boundary" do
    for value <- [1.0, @safe_integer + 1] do
      {document, contract} = persisted_contract()
      [binding] = contract.bindings

      contract = %{
        contract
        | bindings: [%{binding | initial_state: %{"selected_position" => value}}]
      }

      assert_semantic_code(document, contract, "behavior.semantic.initial_state_invalid")
    end
  end

  test "accepts the exact Selection occurrence policy" do
    {document, contract} = persisted_contract(primitive_policy_values: selection_policy())
    assert :ok = Validation.validate_semantics(document, contract)
  end

  test "rejects missing, extra, and incorrect Selection policy fields" do
    invalid_policies = [
      %{"advance_boundary" => "wrap"},
      %{"alignment" => "position"},
      %{"alignment" => "position", "advance_boundary" => "wrap", "extra" => true},
      %{"alignment" => "index", "advance_boundary" => "wrap"},
      %{"alignment" => "position", "advance_boundary" => "clamp"},
      %{"alignment" => 1, "advance_boundary" => "wrap"}
    ]

    for policy <- invalid_policies do
      {document, contract} = persisted_contract(primitive_policy_values: policy)
      assert_semantic_code(document, contract, "behavior.semantic.primitive_policy_invalid")
    end
  end

  test "accepts one control target and one or more distinct presentation targets" do
    for targets <- [
          base_targets(),
          base_targets() ++ [target("presentation_collection", "node_000001_000003")]
        ] do
      {document, contract} = persisted_contract(controlled_targets: targets)
      assert :ok = Validation.validate_semantics(document, contract)
    end
  end

  test "rejects missing, duplicate, unknown, and repeated controlled targets" do
    invalid_targets = [
      [target("presentation_collection", "node_000001_000002")],
      [
        target("control_collection", "node_000001_000001"),
        target("control_collection", "node_000001_000003"),
        target("presentation_collection", "node_000001_000002")
      ],
      [target("control_collection", "node_000001_000001")],
      [
        target("control_collection", "node_000001_000001"),
        target("presentation_collection", "node_000001_000002"),
        target("unknown-role", "node_000001_000003")
      ],
      [
        target("control_collection", "node_000001_000001"),
        target("presentation_collection", "node_000001_000002"),
        target("presentation_collection", "node_000001_000002")
      ]
    ]

    for targets <- invalid_targets do
      {document, contract} = persisted_contract(controlled_targets: targets)
      assert_semantic_code(document, contract, "behavior.semantic.target_invalid")
    end
  end

  test "omits target node attribution when multiple target nodes are implicated" do
    multiple_duplicate_nodes = [
      target("control_collection", "node_000001_000001"),
      target("presentation_collection", "node_000001_000002"),
      target("presentation_collection", "node_000001_000002"),
      target("presentation_collection", "node_000001_000003"),
      target("presentation_collection", "node_000001_000003")
    ]

    unknown_role_and_duplicate = [
      target("control_collection", "node_000001_000001"),
      target("presentation_collection", "node_000001_000002"),
      target("presentation_collection", "node_000001_000002"),
      target("unknown-role", "node_000001_000003")
    ]

    for targets <- [multiple_duplicate_nodes, unknown_role_and_duplicate] do
      {document, contract} = persisted_contract(controlled_targets: targets)
      assert {:error, diagnostics} = Validation.validate_semantics(document, contract)

      assert [%{code: "behavior.semantic.target_invalid", node_id: nil}] =
               Enum.filter(diagnostics, &(&1.code == "behavior.semantic.target_invalid"))
    end
  end

  test "accepts the manual-only activate trigger from the control target" do
    {document, contract} = persisted_contract()
    assert :ok = Validation.validate_semantics(document, contract)
  end

  test "accepts the timed activate and timer trigger pair" do
    {document, contract} =
      persisted_contract(
        timer_policy: @timer_policy,
        triggers: [trigger("activate", "node_000001_000001"), trigger("timer", nil)]
      )

    assert :ok = Validation.validate_semantics(document, contract)
  end

  test "rejects a non-nil timer origin in an otherwise valid timed occurrence" do
    {document, contract} =
      persisted_contract(
        timer_policy: @timer_policy,
        triggers: [
          trigger("activate", "node_000001_000001"),
          trigger("timer", "node_000001_000002")
        ]
      )

    assert_semantic_code(document, contract, "behavior.semantic.trigger_invalid")
  end

  test "rejects duplicate timers in an otherwise valid timed occurrence" do
    {document, contract} =
      persisted_contract(
        timer_policy: @timer_policy,
        triggers: [
          trigger("activate", "node_000001_000001"),
          trigger("timer", nil),
          trigger("timer", nil)
        ]
      )

    assert_semantic_code(document, contract, "behavior.semantic.trigger_invalid")
  end

  test "rejects invalid trigger counts, kinds, and origins" do
    invalid_trigger_sets = [
      [trigger("activate", "node_000001_000001"), trigger("activate", "node_000001_000001")],
      [trigger("activate", "node_000001_000001"), trigger("timer", nil), trigger("timer", nil)],
      [trigger("activate", "node_000001_000001"), trigger("click", nil)],
      [],
      [trigger("activate", nil)],
      [trigger("activate", "node_000001_000003")],
      [trigger("activate", "node_000001_000001"), trigger("timer", "node_000001_000002")]
    ]

    for triggers <- invalid_trigger_sets do
      {document, contract} = persisted_contract(triggers: triggers)
      assert_semantic_code(document, contract, "behavior.semantic.trigger_invalid")
    end

    timed_without_timer =
      persisted_contract(
        timer_policy: @timer_policy,
        triggers: [trigger("activate", "node_000001_000001")]
      )

    timer_without_policy =
      persisted_contract(
        triggers: [trigger("activate", "node_000001_000001"), trigger("timer", nil)]
      )

    for {document, contract} <- [timed_without_timer, timer_without_policy] do
      assert_semantic_code(document, contract, "behavior.semantic.trigger_invalid")
    end
  end

  test "accepts the exact seven-key 5000 millisecond TimerPolicy" do
    {document, contract} =
      persisted_contract(
        timer_policy: @timer_policy,
        triggers: [trigger("activate", "node_000001_000001"), trigger("timer", nil)]
      )

    assert :ok = Validation.validate_semantics(document, contract)
  end

  test "rejects TimerPolicy keys, values, types, and source eligibility fields" do
    invalid_policies = [
      Map.delete(@timer_policy, "purpose"),
      Map.put(@timer_policy, "extra", true),
      Map.put(@timer_policy, "interval_ms", "5000"),
      Map.put(@timer_policy, "interval_ms", 4_000),
      Map.put(@timer_policy, "purpose", "other"),
      Map.put(@timer_policy, "start", "on_activation"),
      Map.put(@timer_policy, "manual_activation", "continue"),
      Map.put(@timer_policy, "restart", "always"),
      Map.put(@timer_policy, "reset", "on_update"),
      Map.put(@timer_policy, "reduced_motion", "continue"),
      Map.put(@timer_policy, "data-should-animate", true)
    ]

    for policy <- invalid_policies do
      {document, contract} =
        persisted_contract(
          timer_policy: policy,
          triggers: [trigger("activate", "node_000001_000001"), trigger("timer", nil)]
        )

      assert_semantic_code(document, contract, "behavior.semantic.timer_policy_invalid")
    end
  end

  test "rejects a floating-point interval even when its numeric value is 5000" do
    {document, contract} =
      persisted_contract(
        timer_policy: @timer_policy,
        triggers: [trigger("activate", "node_000001_000001"), trigger("timer", nil)]
      )

    [binding] = contract.bindings
    timer_policy = Map.put(binding.timer_policy, "interval_ms", 5_000.0)
    contract = %{contract | bindings: [%{binding | timer_policy: timer_policy}]}

    assert_semantic_code(document, contract, "behavior.semantic.timer_policy_invalid")
  end

  test "rejects TimerPolicy without a timer trigger and a timer trigger without TimerPolicy" do
    policy_without_timer = persisted_contract(timer_policy: @timer_policy)

    timer_without_policy =
      persisted_contract(
        triggers: [trigger("activate", "node_000001_000001"), trigger("timer", nil)]
      )

    for {document, contract} <- [policy_without_timer, timer_without_policy] do
      codes = semantic_codes(document, contract)
      assert "behavior.semantic.trigger_invalid" in codes
    end
  end

  test "rejects each unsupported Milan cross-cutting policy" do
    invalid_policies = [
      [focus_policy: %FocusPolicy{initial_strategy: "preserve"}],
      [keyboard_policy: %{"activation" => "enter"}],
      [motion_policy: %{"reduced_motion" => "disable"}],
      [responsive_overrides: [%ResponsiveBehaviorOverride{mode: "compact", state_mapping: %{}}]]
    ]

    for attrs <- invalid_policies do
      {document, contract} = persisted_contract(attrs)
      assert_semantic_code(document, contract, "behavior.semantic.cross_cutting_policy_invalid")
    end
  end

  test "an unsupported exact primitive pair produces only primitive_unsupported" do
    {document, contract} =
      persisted_contract(primitive_ref: @unsupported, initial_state: %{"unknown" => true})

    assert :ok = Validation.validate_structure(document, contract)
    assert {:error, [diagnostic]} = Validation.validate_semantics(document, contract)
    assert diagnostic.code == "behavior.semantic.primitive_unsupported"
    assert diagnostic.category == "semantic"
    assert diagnostic.severity == "error"
    assert diagnostic.binding_id == hd(contract.bindings).binding_id
    assert :ok = Validation.validate_structure(document, contract)
    assert {:error, [composed_diagnostic]} = Validation.validate(document, contract)
    assert composed_diagnostic.code == diagnostic.code
  end

  test "validate runs structure before semantics and returns structural diagnostics unchanged" do
    {document, contract} = persisted_contract(initial_state: %{"unknown" => true})
    [binding] = contract.bindings
    structurally_invalid = %{contract | bindings: [%{binding | ordinal: 1}]}

    assert {:error, structural_diagnostics} =
             Validation.validate_structure(document, structurally_invalid)

    assert {:error, ^structural_diagnostics} = Validation.validate(document, structurally_invalid)

    refute Enum.any?(
             structural_diagnostics,
             &String.starts_with?(&1.code || "", "behavior.semantic.")
           )
  end

  test "validate reaches semantic validation after successful structural validation" do
    {document, contract} = persisted_contract(initial_state: %{"unknown" => true})

    assert :ok = Validation.validate_structure(document, contract)
    assert {:error, diagnostics} = Validation.validate(document, contract)
    assert Enum.any?(diagnostics, &(&1.code == "behavior.semantic.initial_state_invalid"))
  end

  test "semantic diagnostics have stable ordering, codes, and persisted binding IDs" do
    {document, contract} =
      persisted_contract([
        [
          binding_role: "secondary",
          initial_state: %{"unknown" => 1},
          primitive_policy_values: %{"bad" => true}
        ],
        [
          binding_role: "primary",
          timer_policy: %{"bad" => true},
          focus_policy: %FocusPolicy{initial_strategy: "preserve"}
        ]
      ])

    assert {:error, diagnostics} = Validation.validate_semantics(document, contract)

    assert Enum.map(diagnostics, & &1.code) |> Enum.uniq() |> Enum.sort() == [
             "behavior.semantic.cross_cutting_policy_invalid",
             "behavior.semantic.initial_state_invalid",
             "behavior.semantic.primitive_policy_invalid",
             "behavior.semantic.timer_policy_invalid",
             "behavior.semantic.trigger_invalid"
           ]

    expected_order =
      Enum.sort_by(diagnostics, &{&1.binding_id || "", &1.code, &1.node_id || "", &1.message})

    assert diagnostics == expected_order
    assert Enum.all?(diagnostics, &(&1.severity == "error" and &1.category == "semantic"))

    assert Enum.all?(
             diagnostics,
             &(&1.binding_id in Enum.map(contract.bindings, fn b -> b.binding_id end))
           )
  end

  defp persisted_contract(attrs \\ []) when is_list(attrs) do
    document = document()
    assert {:ok, identity} = Identity.from_document(document)

    bindings =
      case attrs do
        [first, second] when is_list(first) and is_list(second) ->
          Enum.map(attrs, &make_binding/1)

        _ ->
          [make_binding(attrs)]
      end

    assert {:ok, contract} =
             BindingIdentity.assign(%Contract{
               design_document_identity: identity,
               bindings: bindings
             })

    {document, contract}
  end

  defp make_binding(attrs) do
    defaults = [
      primitive_ref: @selection,
      owner_node_id: "node_000001",
      binding_role: "primary",
      initial_state: nil,
      primitive_policy_values: selection_policy(),
      triggers: [trigger("activate", "node_000001_000001")],
      controlled_targets: base_targets(),
      timer_policy: nil
    ]

    Binding.new(Keyword.merge(defaults, attrs))
  end

  defp document do
    %DesignDocument{
      root_nodes: [
        %DesignNode{
          node_id: "node_000001",
          semantic_type: "section",
          children: [
            DesignNode.new([1, 1], semantic_type: "generic"),
            DesignNode.new([1, 2], semantic_type: "generic"),
            DesignNode.new([1, 3], semantic_type: "generic")
          ]
        }
      ]
    }
  end

  defp selection_policy, do: %{"alignment" => "position", "advance_boundary" => "wrap"}

  defp base_targets do
    [
      target("control_collection", "node_000001_000001"),
      target("presentation_collection", "node_000001_000002")
    ]
  end

  defp target(role, node_id), do: %ControlledTarget{role: role, node_id: node_id}
  defp trigger(kind, origin), do: %Trigger{kind: kind, origin_node_id: origin}

  defp assert_semantic_code(document, contract, expected_code) do
    assert {:error, diagnostics} = Validation.validate_semantics(document, contract)
    assert Enum.any?(diagnostics, &(&1.code == expected_code))
  end

  defp semantic_codes(document, contract) do
    assert {:error, diagnostics} = Validation.validate_semantics(document, contract)
    Enum.map(diagnostics, & &1.code)
  end
end
