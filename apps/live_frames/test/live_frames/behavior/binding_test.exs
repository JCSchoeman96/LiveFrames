defmodule LiveFrames.Behavior.BindingTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Behavior.Binding
  alias LiveFrames.Behavior.Binding.ControlledTarget
  alias LiveFrames.Behavior.Binding.FocusPolicy
  alias LiveFrames.Behavior.Binding.PrimitiveRef
  alias LiveFrames.Behavior.Binding.ResponsiveBehaviorOverride
  alias LiveFrames.Behavior.Binding.Trigger
  alias LiveFrames.IR.SourceTrace

  @binding_fields [
    :binding_id,
    :ordinal,
    :primitive_ref,
    :owner_node_id,
    :binding_role,
    :initial_state,
    :primitive_policy_values,
    :triggers,
    :controlled_targets,
    :timer_policy,
    :focus_policy,
    :keyboard_policy,
    :motion_policy,
    :responsive_overrides,
    :diagnostics,
    :provenance,
    :source_trace
  ]

  test "has exactly the accepted top-level fields and pre-identity defaults" do
    binding = Binding.new()

    assert binding |> Map.keys() |> Enum.sort() ==
             ([:__struct__] ++ @binding_fields) |> Enum.sort()

    assert binding.binding_id == nil
    assert binding.ordinal == nil
    assert binding.primitive_ref == nil
    assert binding.owner_node_id == nil
    assert binding.binding_role == nil
    assert binding.initial_state == nil
    assert binding.primitive_policy_values == %{}
    assert binding.triggers == []
    assert binding.controlled_targets == []
    assert binding.timer_policy == nil
    assert binding.focus_policy == nil
    assert binding.keyboard_policy == nil
    assert binding.motion_policy == nil
    assert binding.responsive_overrides == []
    assert binding.diagnostics == []
    assert binding.provenance == %{}
    assert binding.source_trace == nil
  end

  test "primitive references, triggers, and controlled targets have closed fields" do
    assert struct_fields(PrimitiveRef) == [:definition_version, :kind]
    assert struct_fields(Trigger) == [:kind, :origin_node_id]
    assert struct_fields(ControlledTarget) == [:node_id, :role]

    assert valid?(
             primitive_ref: nested(PrimitiveRef, kind: "disclosure", definition_version: "1.0.0"),
             triggers: [nested(Trigger, kind: "activate", origin_node_id: "node-trigger")],
             controlled_targets: [
               nested(ControlledTarget, role: "content", node_id: "node-content")
             ]
           )
  end

  test "rejects extra fields on the binding and nested structural types" do
    binding = binding_with_defaults([])
    refute Binding.validate(Map.put(binding, :source_selector, "[data-open]")) == :ok

    malformed_ref =
      binding.primitive_ref
      |> Map.put(:definition_name, "unapproved-field")

    refute Binding.validate(%{binding | primitive_ref: malformed_ref}) == :ok
  end

  test "keeps binding identity fields unassigned in B1" do
    binding = binding_with_defaults([])

    refute Binding.validate(%{binding | binding_id: "bnd_123"}) == :ok
    refute Binding.validate(%{binding | ordinal: 0}) == :ok
  end

  test "initial state and primitive policies are separate ordered safe objects" do
    initial_state = %{"open_item_ids" => ["item-b", "item-a"]}
    policy_values = %{"nested" => [%{"values" => ["second", "first"]}, true, nil]}

    binding =
      binding_with_defaults(
        initial_state: initial_state,
        primitive_policy_values: policy_values
      )

    assert Binding.validate(binding) == :ok
    assert binding.initial_state == initial_state
    assert binding.primitive_policy_values == policy_values
  end

  test "rejects values outside the recursive canonical value algebra" do
    invalid_values = [
      %{"number" => 1.5},
      %{"number" => 9_007_199_254_740_992},
      %{1 => "non-string key"},
      %{"invalid" => <<0xFF>>},
      %{"struct" => %URI{path: "/x"}},
      %{"function" => fn -> :unsafe end},
      %{"improper" => [1 | 2]}
    ]

    for value <- invalid_values do
      refute valid?(primitive_policy_values: value)
    end
  end

  test "cross-cutting policy values are safe objects or nil" do
    assert valid?(timer_policy: nil, keyboard_policy: nil, motion_policy: nil)

    assert valid?(
             timer_policy: %{"delay" => 100},
             keyboard_policy: %{"keys" => ["Enter"]},
             motion_policy: %{"reduced" => false}
           )

    refute valid?(timer_policy: ["not", "an", "object"])
    refute valid?(keyboard_policy: %{key: "Enter"})
    refute valid?(motion_policy: %{"value" => 1.25})
  end

  test "FocusPolicy has exactly eight fields and four node references" do
    focus =
      nested(FocusPolicy,
        initial_strategy: "first_available",
        initial_target_node_id: "node-initial",
        containment_strategy: "trap",
        movement_strategy: "linear",
        scope_node_id: nil,
        restoration_strategy: "invoker",
        restoration_target_node_id: nil,
        restoration_fallback_node_id: "node-fallback"
      )

    assert struct_fields(FocusPolicy) == [
             :containment_strategy,
             :initial_strategy,
             :initial_target_node_id,
             :movement_strategy,
             :restoration_fallback_node_id,
             :restoration_strategy,
             :restoration_target_node_id,
             :scope_node_id
           ]

    assert Binding.validate(binding_with_defaults(focus_policy: focus)) == :ok

    assert focus_reference_fields() == [
             :initial_target_node_id,
             :restoration_fallback_node_id,
             :restoration_target_node_id,
             :scope_node_id
           ]

    refute Map.has_key?(focus, :invoker_node_id)
    refute Map.has_key?(focus, :runtime_invoker_id)
    refute Map.has_key?(focus, :last_trigger_node_id)
    refute Map.has_key?(focus, :roving_node_ids)
    refute Map.has_key?(focus, :focusable_node_ids)
    refute Map.has_key?(focus, :contained_node_ids)
  end

  test "nil focus scope canonically means owner scope" do
    assert valid?(
             owner_node_id: "node-owner",
             focus_policy: nested(FocusPolicy, scope_node_id: nil)
           )
  end

  test "rejects explicit focus scope equal to owner" do
    refute valid?(
             owner_node_id: "node-owner",
             focus_policy: nested(FocusPolicy, scope_node_id: "node-owner")
           )
  end

  test "allows a distinct explicit focus scope structurally" do
    assert valid?(
             owner_node_id: "node-owner",
             focus_policy: nested(FocusPolicy, scope_node_id: "node-scope")
           )
  end

  test "responsive override has exactly its three fields and unique modes" do
    override =
      nested(ResponsiveBehaviorOverride,
        mode: "compact",
        authority_ref: "responsive-authority-1",
        state_mapping: %{"open" => true}
      )

    assert struct_fields(ResponsiveBehaviorOverride) == [:authority_ref, :mode, :state_mapping]
    assert valid?(responsive_overrides: [override])
    assert Binding.new().responsive_overrides == []

    duplicate =
      nested(ResponsiveBehaviorOverride,
        mode: "compact",
        authority_ref: "responsive-authority-2",
        state_mapping: %{"open" => false}
      )

    refute valid?(responsive_overrides: [override, duplicate])
  end

  test "keeps supplied array order in all policy and responsive values" do
    policy_values = %{"sequence" => ["b", "a"]}
    mapping = %{"sequence" => ["narrow", "wide"]}

    binding =
      binding_with_defaults(
        primitive_policy_values: policy_values,
        timer_policy: %{"sequence" => [2, 1]},
        responsive_overrides: [
          nested(ResponsiveBehaviorOverride,
            mode: "wide",
            authority_ref: "semantic-authority",
            state_mapping: mapping
          )
        ]
      )

    assert Binding.validate(binding) == :ok
    assert binding.primitive_policy_values == policy_values
    assert binding.timer_policy["sequence"] == [2, 1]
    assert hd(binding.responsive_overrides).state_mapping == mapping
    assert hd(binding.responsive_overrides).authority_ref == "semantic-authority"
  end

  test "generic policies have no typed DesignNode reference fields" do
    policies =
      binding_with_defaults(
        timer_policy: %{},
        keyboard_policy: %{},
        motion_policy: %{}
      )

    for policy <- [policies.timer_policy, policies.keyboard_policy, policies.motion_policy] do
      assert is_map(policy)
      refute Enum.any?(Map.keys(policy), &String.ends_with?(Atom.to_string(&1), "node_id"))
    end

    override =
      nested(ResponsiveBehaviorOverride,
        mode: "wide",
        authority_ref: "semantic-authority",
        state_mapping: %{"node-a" => "node-b"}
      )

    assert valid?(responsive_overrides: [override])
  end

  test "BehaviorBinding does not own primitive state-machine fields" do
    refute Enum.any?(@binding_fields, fn field ->
             field in [
               :state_model,
               :state_dimensions,
               :state_domains,
               :default_state_definition,
               :invariants,
               :transitions,
               :transition_definitions,
               :guards,
               :effects,
               :accessibility_effects,
               :terminal_states,
               :terminal_rules,
               :definition_version
             ]
           end)
  end

  test "reuses the generic IR source trace type" do
    assert %Binding{source_trace: %SourceTrace{}} =
             Binding.new(source_trace: %SourceTrace{source_id: "evidence-only"})
  end

  defp valid?(attrs), do: Binding.validate(binding_with_defaults(attrs)) == :ok

  defp binding_with_defaults(attrs) do
    [
      primitive_ref: nested(PrimitiveRef, kind: "test", definition_version: "1.0.0"),
      owner_node_id: "node-owner",
      binding_role: "test"
    ]
    |> Keyword.merge(attrs)
    |> then(&Binding.new(&1))
  end

  defp nested(module, attrs), do: apply(module, :__struct__, [attrs])

  defp struct_fields(module) do
    module
    |> struct()
    |> Map.keys()
    |> Enum.reject(&(&1 == :__struct__))
    |> Enum.sort()
  end

  defp focus_reference_fields do
    FocusPolicy
    |> struct()
    |> Map.keys()
    |> Enum.filter(&String.ends_with?(Atom.to_string(&1), "node_id"))
    |> Enum.sort()
  end
end
