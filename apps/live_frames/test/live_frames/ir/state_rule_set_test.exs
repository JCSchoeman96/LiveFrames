defmodule LiveFrames.IR.StateRuleSetTest do
  use ExUnit.Case, async: true

  alias LiveFrames.IR.StateRuleSet
  alias LiveFrames.IR.StyleValue

  @valid_rule %{
    "condition" => "hover",
    "target_node_id" => "node_000001",
    "declarations" => %{"opacity" => %{"kind" => "literal", "value" => 1}},
    "viewport" => nil,
    "order" => 0
  }

  @valid_set %{
    "type" => "state_rules",
    "rules" => [@valid_rule],
    "residual" => []
  }

  @multiply %{
    "operation" => "multiply",
    "operands" => [
      %{"kind" => "token_ref", "path" => "spacing.grid_gap"},
      %{"kind" => "literal", "value" => 2}
    ]
  }

  @residual_reasons ~w(
    ambiguous_selector malformed_block responsive_collision responsive_overlap_conflict
    style_collision unresolved_target unresolved_value unsupported_declaration
    unsupported_selector unsafe_declaration
  )

  # This is the exact JSON map shape emitted by Task 3 for a one-rule hover
  # selector with one safe literal declaration and no residual source rules.
  @task_3_state_rules %{
    "type" => "state_rules",
    "rules" => [
      %{
        "condition" => "hover",
        "target_node_id" => "node_000001_000001",
        "declarations" => %{"opacity" => %{"kind" => "literal", "value" => 1}},
        "viewport" => nil,
        "order" => 0
      }
    ],
    "residual" => []
  }

  test "accepts the Task 3 state_rules producer shape" do
    assert StateRuleSet.validate(@task_3_state_rules) == :ok
  end

  test "accepts minimal hover and focus_within rules with self or descendant IDs" do
    assert StateRuleSet.validate(@valid_set) == :ok

    focus_rule =
      valid_rule(%{"condition" => "focus_within", "target_node_id" => "node_000001_000002"})

    assert StateRuleSet.validate(valid_set([focus_rule])) == :ok
  end

  test "accepts null, one-sided, bounded, and zero viewport bounds" do
    for viewport <- [
          nil,
          %{"min_width" => 320, "max_width" => nil},
          %{"min_width" => nil, "max_width" => 800.5},
          %{"min_width" => 0, "max_width" => 0},
          %{"min_width" => 320, "max_width" => 800}
        ] do
      assert StateRuleSet.validate(valid_set([valid_rule(%{"viewport" => viewport})])) == :ok
    end
  end

  test "accepts every closed declaration tag" do
    values = [
      %{"kind" => "literal", "value" => "2px"},
      %{"kind" => "literal", "value" => 2},
      %{"kind" => "literal", "value" => 1.25},
      %{"kind" => "keyword", "value" => "flex"},
      %{"kind" => "token_ref", "value" => "color.brand.primary"},
      %{"kind" => "calculation", "value" => @multiply}
    ]

    for tagged_value <- values do
      assert StateRuleSet.validate(
               valid_set([valid_rule(%{"declarations" => %{"opacity" => tagged_value}})])
             ) == :ok
    end
  end

  test "accepts every residual reason as inert non-empty source evidence" do
    residual =
      Enum.map(@residual_reasons, fn reason ->
        %{"reason" => reason, "source_text" => ".owner { color: red; }"}
      end)

    assert StateRuleSet.validate(valid_set([@valid_rule], residual)) == :ok
  end

  test "accepts multiple unique rules only when their order is ascending" do
    first = valid_rule(%{"order" => 0})
    second = valid_rule(%{"condition" => "focus_within", "order" => 2})

    assert StateRuleSet.validate(valid_set([first, second])) == :ok
  end

  test "constructor returns the exact wire map and validates before returning it" do
    assert {:ok, @valid_set} = StateRuleSet.new([@valid_rule], [])

    invalid_rules = [valid_rule(%{"order" => 1}), valid_rule(%{"order" => 0})]
    invalid = valid_set(invalid_rules)

    assert StateRuleSet.new(invalid_rules, []) == StateRuleSet.validate(invalid)
  end

  test "rejects non-map values and top-level key or type violations" do
    assert_rejected(nil)
    assert_rejected([])
    assert_rejected("state_rules")
    assert_rejected(Map.delete(@valid_set, "type"))
    assert_rejected(Map.put(@valid_set, "type", "custom_css"))
    assert_rejected(Map.delete(@valid_set, "rules"))
    assert_rejected(Map.put(@valid_set, "rules", []))
    assert_rejected(Map.delete(@valid_set, "residual"))
    assert_rejected(Map.put(@valid_set, "extra", true))

    atom_keys = %{type: "state_rules", rules: [@valid_rule], residual: []}
    assert_rejected(atom_keys)
  end

  test "rejects malformed rules and every missing or additional rule key" do
    assert_rejected(valid_set([nil]))
    assert_rejected(valid_set(["rule"]))

    for key <- ["condition", "target_node_id", "declarations", "viewport", "order"] do
      assert_rejected(valid_set([Map.delete(@valid_rule, key)]))
    end

    assert_rejected(valid_set([Map.put(@valid_rule, "extra", true)]))
  end

  test "rejects open or unsupported conditions" do
    for condition <- ["focus_visible", "default", "active", ":hover", nil, :hover] do
      assert_rejected(valid_set([valid_rule(%{"condition" => condition})]))
    end
  end

  test "requires a non-empty string target and non-empty declaration map" do
    for target <- ["", 12, nil] do
      assert_rejected(valid_set([valid_rule(%{"target_node_id" => target})]))
    end

    assert_rejected(valid_set([valid_rule(%{"declarations" => %{}})]))
    assert_rejected(valid_set([valid_rule(%{"declarations" => []})]))
  end

  test "requires a non-negative integer order that is unique and ascending" do
    for order <- [-1, 1.0, nil] do
      assert_rejected(valid_set([valid_rule(%{"order" => order})]))
    end

    duplicate = [@valid_rule, valid_rule(%{"condition" => "focus_within"})]
    assert_rejected(valid_set(duplicate))

    unsorted = [valid_rule(%{"order" => 1}), valid_rule(%{"order" => 0})]
    assert_rejected(valid_set(unsorted))
  end

  test "rejects malformed viewport objects and bounds" do
    invalid_viewports = [
      :viewport,
      [],
      %{"max_width" => 500},
      %{"min_width" => 300},
      %{"min_width" => 300, "max_width" => 500, "extra" => 1},
      %{"min_width" => nil, "max_width" => nil},
      %{"min_width" => -1, "max_width" => nil},
      %{"min_width" => nil, "max_width" => -1},
      %{"min_width" => "300", "max_width" => nil},
      %{"min_width" => nil, "max_width" => "500"},
      %{"min_width" => 501, "max_width" => 500},
      %{"min_width" => :infinity, "max_width" => nil},
      %{min_width: 300, max_width: 500}
    ]

    for viewport <- invalid_viewports do
      assert_rejected(valid_set([valid_rule(%{"viewport" => viewport})]))
    end
  end

  test "rejects unsafe, empty, non-string, and recursive CSS property keys" do
    invalid_properties = ["", 12, "color;", "custom-css"]

    for property <- invalid_properties do
      assert_rejected(
        valid_set([
          valid_rule(%{
            "declarations" => %{property => %{"kind" => "literal", "value" => "red"}}
          })
        ])
      )
    end

    assert_rejected(
      valid_set([
        valid_rule(%{"declarations" => %{:opacity => %{"kind" => "literal", "value" => 1}}})
      ])
    )
  end

  test "requires exact declaration tags with a closed string kind" do
    invalid_values = [
      %{"value" => "red"},
      %{"kind" => "literal"},
      %{"kind" => "literal", "value" => "red", "extra" => true},
      %{"kind" => "other", "value" => "red"},
      %{"kind" => "complex_css", "value" => %{}},
      %{"kind" => "responsive", "value" => %{}},
      %{"kind" => "unresolved", "value" => "red"},
      %{"kind" => :literal, "value" => "red"},
      StyleValue.literal("red")
    ]

    for tagged_value <- invalid_values do
      assert_rejected(valid_set([valid_rule(%{"declarations" => %{"color" => tagged_value}})]))
    end
  end

  test "applies the existing CSS-safe value boundary to literal strings and keywords" do
    for unsafe <- ["red; display: none", "url(javascript:alert(1))", "x\\y"] do
      assert_rejected(
        valid_set([
          valid_rule(%{
            "declarations" => %{"color" => %{"kind" => "literal", "value" => unsafe}}
          })
        ])
      )

      assert_rejected(
        valid_set([
          valid_rule(%{
            "declarations" => %{"display" => %{"kind" => "keyword", "value" => unsafe}}
          })
        ])
      )
    end

    assert_rejected(
      valid_set([
        valid_rule(%{"declarations" => %{"display" => %{"kind" => "keyword", "value" => ""}}})
      ])
    )
  end

  test "accepts only canonical token paths and rejects raw variable syntax" do
    for path <- ["", "Color.primary", "spacing..gap", "--lf-gap", "var(--lf-gap)"] do
      assert_rejected(
        valid_set([
          valid_rule(%{
            "declarations" => %{"gap" => %{"kind" => "token_ref", "value" => path}}
          })
        ])
      )
    end
  end

  test "accepts only the ordered structured multiply calculation" do
    invalid_calculations = [
      "calc(var(--lf-space-grid-gap) * 2)",
      Map.put(@multiply, "operation", "add"),
      %{
        "operation" => "multiply",
        "operands" => Enum.reverse(@multiply["operands"])
      },
      %{
        "operation" => "multiply",
        "operands" => [
          %{"kind" => "token_ref", "path" => "spacing.grid_gap"},
          %{"kind" => "calculation", "value" => @multiply}
        ]
      },
      %{
        "operation" => "multiply",
        "operands" => @multiply["operands"] ++ [%{"kind" => "literal", "value" => 3}]
      },
      Map.put(@multiply, "extra", true),
      %{
        "operation" => "multiply",
        "operands" => [
          %{"kind" => "token_ref", "path" => "spacing.grid_gap", "extra" => true},
          %{"kind" => "literal", "value" => 2}
        ]
      },
      %{
        "operation" => "multiply",
        "operands" => [
          %{"kind" => "token_ref", "path" => "spacing.grid_gap"},
          %{"kind" => "literal", "value" => 2, "extra" => true}
        ]
      },
      %{"operation" => "multiply"},
      %{
        "operation" => "multiply",
        "operands" => [
          %{"kind" => "token_ref", "path" => "spacing.grid_gap"},
          %{"kind" => "literal", "value" => :infinity}
        ]
      }
    ]

    for calculation <- invalid_calculations do
      assert_rejected(
        valid_set([
          valid_rule(%{
            "declarations" => %{"gap" => %{"kind" => "calculation", "value" => calculation}}
          })
        ])
      )
    end
  end

  test "rejects malformed residual entries and unknown reasons" do
    invalid_residuals = [
      nil,
      "residual",
      %{"source_text" => ".owner { color: red; }"},
      %{"reason" => "unsupported_selector"},
      %{"reason" => "unsupported_selector", "source_text" => "", "extra" => true},
      %{"reason" => "unknown_reason", "source_text" => ".owner { color: red; }"},
      %{"reason" => "unsupported_selector", "source_text" => 1},
      %{"reason" => :unsupported_selector, "source_text" => ".owner {}"},
      %{reason: "unsupported_selector", source_text: ".owner {}"}
    ]

    for residual <- invalid_residuals do
      assert_rejected(valid_set([@valid_rule], [residual]))
    end
  end

  defp valid_rule(changes), do: Map.merge(@valid_rule, changes)

  defp valid_set(rules, residual \\ []),
    do: %{"type" => "state_rules", "rules" => rules, "residual" => residual}

  defp assert_rejected(value) do
    assert StateRuleSet.validate(value) == {:error, :invalid_state_rule_set}
  end
end
