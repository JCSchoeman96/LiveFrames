defmodule LiveFrames.NativeGenerator.StyleIntegrationTest do
  use ExUnit.Case, async: true

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.Slot
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.RenderProjection
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR
  alias LiveFrames.IR.ResponsiveOverride
  alias LiveFrames.IR.StyleValue
  alias LiveFrames.NativeGenerator
  alias LiveFrames.NativeGenerator.StyleIntegration

  defp contract(category \\ :section, attrs \\ [], slots \\ []) do
    %ComponentContract{
      contract_id: "style-contract",
      category: category,
      module_intent: "style_fixture",
      function_intent: "render",
      approval_status: :approved,
      public_attrs: attrs,
      public_slots: slots
    }
  end

  defp generate(document, contract, projections \\ []) do
    generate_at(document, contract, DesignNode.deterministic_id([1]), projections)
  end

  defp generate_at(document, contract, boundary_node_id, projections \\ []) do
    {:ok, fingerprint} = ComponentizationPlan.design_document_sha256(document)

    plan = %ComponentizationPlan{
      contract_id: contract.contract_id,
      design_document_sha256: fingerprint,
      boundary_node_id: boundary_node_id,
      render_projections: projections
    }

    NativeGenerator.generate(contract, plan, document)
  end

  defp boundary(children \\ []) do
    %DesignNode{
      node_id: DesignNode.deterministic_id([1]),
      semantic_type: "section",
      children: children
    }
  end

  defp bundle!(result) do
    assert {:ok, bundle} = result
    bundle
  end

  defp blocked_reason(result) do
    assert {:error, :generation_blocked, [diagnostic]} = result
    diagnostic.metadata.reason
  end

  defp state_value(rules, residual \\ [], opts \\ []) do
    StyleValue.complex_css(
      %{"type" => "state_rules", "rules" => rules, "residual" => residual},
      opts
    )
  end

  defp state_rule(condition, target_node_id, declarations, order, viewport \\ nil) do
    %{
      "condition" => condition,
      "target_node_id" => target_node_id,
      "declarations" => declarations,
      "viewport" => viewport,
      "order" => order
    }
  end

  defp literal(value), do: %{"kind" => "literal", "value" => value}
  defp keyword(value), do: %{"kind" => "keyword", "value" => value}
  defp token_ref(value), do: %{"kind" => "token_ref", "value" => value}

  defp calculation(token_path, multiplier) do
    %{
      "kind" => "calculation",
      "value" => %{
        "operation" => "multiply",
        "operands" => [
          %{"kind" => "token_ref", "path" => token_path},
          %{"kind" => "literal", "value" => multiplier}
        ]
      }
    }
  end

  test "primary button intent emits token backed base, hover, and focus-visible rules" do
    button = %DesignNode{
      node_id: DesignNode.deterministic_id([1, 1]),
      semantic_type: "button",
      attributes: %{"style" => "primary"},
      content: "Continue"
    }

    document = %DesignDocument{root_nodes: [boundary([button])]}
    bundle = bundle!(generate(document, contract()))
    stylesheet = Enum.find(bundle.artifacts, &(&1.kind == :stylesheet))
    module = Enum.find(bundle.artifacts, &(&1.kind == :elixir_module))

    assert stylesheet.content =~ ".lf-section-style-fixture__n-000001-000001 {"
    assert stylesheet.content =~ "background-color: var(--lf-action-primary-background);"
    assert stylesheet.content =~ ".lf-section-style-fixture__n-000001-000001:hover {"
    assert stylesheet.content =~ "background-color: var(--lf-action-primary-background-hover);"
    assert stylesheet.content =~ ".lf-section-style-fixture__n-000001-000001:focus-visible {"
    assert stylesheet.content =~ "outline-color: var(--lf-action-primary-focus);"
    assert stylesheet.content =~ "outline-style: solid;"
    refute stylesheet.content =~ "btn--primary"
    refute stylesheet.content =~ ".lf-hero__action--primary"
    refute module.content =~ "btn--primary"
    assert module.content =~ "lf-section-style-fixture__n-000001-000001"
  end

  test "renders ordered self and descendant hover and focus-within rules" do
    owner_id = DesignNode.deterministic_id([1, 1])
    target_id = DesignNode.deterministic_id([1, 1, 1])

    rules = [
      state_rule("hover", owner_id, %{"opacity" => literal(0.5)}, 0),
      state_rule("hover", target_id, %{"color" => keyword("tomato")}, 1),
      state_rule("focus_within", owner_id, %{"border-style" => keyword("solid")}, 2),
      state_rule("focus_within", target_id, %{"display" => keyword("grid")}, 3)
    ]

    target = %DesignNode{node_id: target_id, semantic_type: "container"}

    owner = %DesignNode{
      node_id: owner_id,
      semantic_type: "container",
      styles: %{"custom-css" => state_value(rules)},
      children: [target]
    }

    bundle = bundle!(generate(%DesignDocument{root_nodes: [boundary([owner])]}, contract()))
    stylesheet = Enum.find(bundle.artifacts, &(&1.kind == :stylesheet)).content
    module = Enum.find(bundle.artifacts, &(&1.kind == :elixir_module)).content
    owner_class = "lf-section-style-fixture__n-000001-000001"
    target_class = owner_class <> "-000001"

    expected =
      ".#{owner_class}:hover {\n  opacity: 0.5;\n}\n\n" <>
        ".#{owner_class}:hover .#{target_class} {\n  color: tomato;\n}\n\n" <>
        ".#{owner_class}:focus-within {\n  border-style: solid;\n}\n\n" <>
        ".#{owner_class}:focus-within .#{target_class} {\n  display: grid;\n}\n"

    assert stylesheet == expected
    assert module =~ "class={\"#{owner_class}\"}"
    assert module =~ "class={\"#{target_class}\"}"
  end

  test "serializes all closed declaration kinds through native style values" do
    owner_id = DesignNode.deterministic_id([1, 1])

    declarations = %{
      "opacity" => literal(0.5),
      "display" => keyword("flex"),
      "gap" => token_ref("spacing.grid_gap"),
      "margin-inline" => calculation("spacing.grid_gap", 2)
    }

    owner = %DesignNode{
      node_id: owner_id,
      semantic_type: "container",
      styles: %{
        "custom-css" => state_value([state_rule("hover", owner_id, declarations, 0)])
      }
    }

    stylesheet =
      generate(%DesignDocument{root_nodes: [boundary([owner])]}, contract())
      |> bundle!()
      |> then(&Enum.find(&1.artifacts, fn artifact -> artifact.kind == :stylesheet end).content)

    assert stylesheet ==
             ".lf-section-style-fixture__n-000001-000001:hover {\n" <>
               "  display: flex;\n" <>
               "  gap: var(--lf-space-grid-gap);\n" <>
               "  margin-inline: calc(var(--lf-space-grid-gap) * 2);\n" <>
               "  opacity: 0.5;\n}\n"
  end

  test "renders each state viewport form with inclusive media bounds" do
    owner_id = DesignNode.deterministic_id([1, 1])

    rules = [
      state_rule("hover", owner_id, %{"opacity" => literal(0.5)}, 0, %{
        "min_width" => 767,
        "max_width" => nil
      }),
      state_rule("hover", owner_id, %{"display" => keyword("grid")}, 1, %{
        "min_width" => nil,
        "max_width" => 767
      }),
      state_rule("focus_within", owner_id, %{"gap" => literal(2)}, 2, %{
        "min_width" => 500,
        "max_width" => 900
      }),
      state_rule("focus_within", owner_id, %{"color" => keyword("red")}, 3, %{
        "min_width" => 767,
        "max_width" => 767
      })
    ]

    owner = %DesignNode{
      node_id: owner_id,
      semantic_type: "container",
      styles: %{"custom-css" => state_value(rules)}
    }

    stylesheet =
      generate(%DesignDocument{root_nodes: [boundary([owner])]}, contract())
      |> bundle!()
      |> then(&Enum.find(&1.artifacts, fn artifact -> artifact.kind == :stylesheet end).content)

    assert stylesheet =~
             "@media (min-width: 767px) {\n  .lf-section-style-fixture__n-000001-000001:hover {"

    assert stylesheet =~
             "@media (max-width: 767px) {\n  .lf-section-style-fixture__n-000001-000001:hover {"

    assert stylesheet =~
             "@media (min-width: 500px) and (max-width: 900px) {\n  .lf-section-style-fixture__n-000001-000001:focus-within {"

    assert stylesheet =~
             "@media (min-width: 767px) and (max-width: 767px) {\n  .lf-section-style-fixture__n-000001-000001:focus-within {"
  end

  test "rejects missing sibling ancestor and outside-boundary targets" do
    owner_id = DesignNode.deterministic_id([1, 1])
    sibling_id = DesignNode.deterministic_id([1, 2])
    parent_id = DesignNode.deterministic_id([1, 1])
    nested_owner_id = DesignNode.deterministic_id([1, 1, 1])

    missing_owner = %DesignNode{
      node_id: DesignNode.deterministic_id([1]),
      semantic_type: "section",
      styles: %{
        "custom-css" =>
          state_value([
            state_rule("hover", "node_missing_synthetic_target", %{"opacity" => literal(1)}, 0)
          ])
      }
    }

    assert blocked_reason(generate(%DesignDocument{root_nodes: [missing_owner]}, contract())) ==
             :missing_state_rule_target

    sibling_owner = %DesignNode{
      node_id: owner_id,
      semantic_type: "container",
      styles: %{
        "custom-css" =>
          state_value([state_rule("hover", sibling_id, %{"opacity" => literal(1)}, 0)])
      }
    }

    sibling = %DesignNode{node_id: sibling_id, semantic_type: "container"}

    assert blocked_reason(
             generate(
               %DesignDocument{root_nodes: [boundary([sibling_owner, sibling])]},
               contract()
             )
           ) == :state_rule_target_not_self_or_descendant

    nested_owner = %DesignNode{
      node_id: nested_owner_id,
      semantic_type: "container",
      styles: %{
        "custom-css" =>
          state_value([state_rule("hover", parent_id, %{"opacity" => literal(1)}, 0)])
      }
    }

    parent = %DesignNode{node_id: parent_id, semantic_type: "container", children: [nested_owner]}

    assert blocked_reason(generate(%DesignDocument{root_nodes: [boundary([parent])]}, contract())) ==
             :state_rule_target_not_self_or_descendant

    selected_boundary_id = DesignNode.deterministic_id([1, 1])
    outside_target_id = DesignNode.deterministic_id([1, 2])

    selected_boundary = %DesignNode{
      node_id: selected_boundary_id,
      semantic_type: "container",
      styles: %{
        "custom-css" =>
          state_value([state_rule("hover", outside_target_id, %{"opacity" => literal(1)}, 0)])
      }
    }

    outside_target = %DesignNode{node_id: outside_target_id, semantic_type: "container"}
    document = %DesignDocument{root_nodes: [boundary([selected_boundary, outside_target])]}

    assert blocked_reason(generate_at(document, contract(), selected_boundary_id)) ==
             :state_rule_target_outside_component_boundary
  end

  test "rejects state targets inside a pruned subtree slot" do
    slot_id = DesignNode.deterministic_id([1, 1])
    target_id = DesignNode.deterministic_id([1, 1, 1])

    root = %DesignNode{
      boundary()
      | styles: %{
          "custom-css" =>
            state_value([state_rule("hover", target_id, %{"opacity" => literal(1)}, 0)])
        },
        children: [
          %DesignNode{
            node_id: slot_id,
            semantic_type: "actions",
            children: [%DesignNode{node_id: target_id, semantic_type: "container"}]
          }
        ]
    }

    document = %DesignDocument{root_nodes: [root]}

    projection = %RenderProjection{
      public_slot_name: "actions",
      target_node_id: slot_id,
      render_role: :subtree_slot
    }

    slot = %Slot{
      name: "actions",
      semantic_purpose: "caller actions",
      consumer_responsibility: "caller"
    }

    assert blocked_reason(generate(document, contract(:section, [], [slot]), [projection])) ==
             :state_rule_pruned_slot_target
  end

  test "malformed state rules block and unknown or raw complex CSS remains non-generatable" do
    node_id = DesignNode.deterministic_id([1])
    malformed = %{"type" => "state_rules", "rules" => [], "residual" => []}

    assert {:error, :generation_blocked, [malformed_diagnostic]} =
             generate(
               %DesignDocument{
                 root_nodes: [
                   %DesignNode{
                     node_id: node_id,
                     semantic_type: "section",
                     styles: %{"custom-css" => StyleValue.complex_css(malformed)}
                   }
                 ]
               },
               contract()
             )

    assert malformed_diagnostic.metadata.reason == :invalid_state_rule_set

    for subtype <- [
          %{"type" => "something_else"},
          %{
            "type" => "custom_css",
            "property" => "custom-css",
            "source_key" => "_cssCustom",
            "rules" => [".synthetic-source-rule { color: red; }"]
          }
        ] do
      document = %DesignDocument{
        root_nodes: [
          %DesignNode{
            node_id: node_id,
            semantic_type: "section",
            styles: %{"custom-css" => StyleValue.complex_css(subtype)}
          }
        ]
      }

      assert {:error, :generation_blocked, [_]} = generate(document, contract())
    end
  end

  test "renders valid state rules and ignores malicious-looking residual and provenance text" do
    owner_id = DesignNode.deterministic_id([1, 1])
    target_id = DesignNode.deterministic_id([1, 1, 1])
    source_class = "source-card-73"
    source_selector = ".#{source_class}:hover .source-heading-41"
    transient_token = "interaction-class-62"
    residual_text = "#{source_selector} { --#{transient_token}: display; }"

    residual = [%{"reason" => "unsupported_selector", "source_text" => residual_text}]

    owner = %DesignNode{
      node_id: owner_id,
      semantic_type: "container",
      attributes: %{"source-class" => source_class},
      styles: %{
        "custom-css" =>
          state_value(
            [state_rule("hover", target_id, %{"opacity" => literal(0.75)}, 0)],
            residual,
            source_expression: "#{source_selector} #{transient_token}"
          )
      },
      children: [%DesignNode{node_id: target_id, semantic_type: "container"}]
    }

    bundle = bundle!(generate(%DesignDocument{root_nodes: [boundary([owner])]}, contract()))
    stylesheet = Enum.find(bundle.artifacts, &(&1.kind == :stylesheet)).content
    module = Enum.find(bundle.artifacts, &(&1.kind == :elixir_module)).content

    assert stylesheet =~
             ".lf-section-style-fixture__n-000001-000001:hover .lf-section-style-fixture__n-000001-000001-000001 {"

    for leaked_text <- [source_class, source_selector, transient_token, residual_text] do
      refute stylesheet =~ leaked_text
      refute module =~ leaked_text
    end
  end

  test "unmapped state token references fail at the existing CSS value boundary" do
    owner_id = DesignNode.deterministic_id([1, 1])

    owner = %DesignNode{
      node_id: owner_id,
      semantic_type: "container",
      styles: %{
        "custom-css" =>
          state_value([
            state_rule("hover", owner_id, %{"color" => token_ref("unmapped.synthetic.token")}, 0)
          ])
      }
    }

    assert {:error, :generation_blocked, [diagnostic]} =
             generate(%DesignDocument{root_nodes: [boundary([owner])]}, contract())

    assert diagnostic.code == "native_generator.styling.css_serialization_failed"
  end

  test "fails closed when a primary action hover property collides with a self state rule" do
    button_id = DesignNode.deterministic_id([1, 1])

    button = %DesignNode{
      node_id: button_id,
      semantic_type: "button",
      attributes: %{"style" => "primary"},
      styles: %{
        "custom-css" =>
          state_value([
            state_rule("hover", button_id, %{"background-color" => literal("red")}, 0)
          ])
      }
    }

    assert {:error, :generation_blocked, [diagnostic]} =
             generate(%DesignDocument{root_nodes: [boundary([button])]}, contract())

    assert diagnostic.metadata.reason == :state_rule_pseudo_precedence_gap
  end

  test "preserves focus-visible output when unrelated focus-within rules exist" do
    button_id = DesignNode.deterministic_id([1, 1])
    panel_id = DesignNode.deterministic_id([1, 2])

    button = %DesignNode{
      node_id: button_id,
      semantic_type: "button",
      attributes: %{"style" => "primary"}
    }

    panel = %DesignNode{
      node_id: panel_id,
      semantic_type: "container",
      styles: %{
        "custom-css" =>
          state_value([state_rule("focus_within", panel_id, %{"opacity" => literal(0.9)}, 0)])
      }
    }

    bundle =
      bundle!(generate(%DesignDocument{root_nodes: [boundary([button, panel])]}, contract()))

    stylesheet = Enum.find(bundle.artifacts, &(&1.kind == :stylesheet)).content

    assert stylesheet =~
             ".lf-section-style-fixture__n-000001-000001:focus-visible {\n  outline-color: var(--lf-action-primary-focus);\n  outline-offset: 2px;\n  outline-style: solid;\n  outline-width: 2px;\n}"

    refute stylesheet =~ "outline: 0"
    refute stylesheet =~ "box-shadow: none"
  end

  test "rejects conflicting cross-owner state declarations on a shared target" do
    outer_id = DesignNode.deterministic_id([1, 1])
    inner_id = DesignNode.deterministic_id([1, 1, 1])
    target_id = DesignNode.deterministic_id([1, 1, 1, 1])

    target = %DesignNode{node_id: target_id, semantic_type: "container"}

    inner = %DesignNode{
      node_id: inner_id,
      semantic_type: "container",
      styles: %{
        "custom-css" =>
          state_value([
            state_rule("focus_within", target_id, %{"opacity" => literal(0.7)}, 0)
          ])
      },
      children: [target]
    }

    outer = %DesignNode{
      node_id: outer_id,
      semantic_type: "container",
      styles: %{
        "custom-css" =>
          state_value([state_rule("hover", target_id, %{"opacity" => literal(0.2)}, 0)])
      },
      children: [inner]
    }

    assert {:error, :generation_blocked, [diagnostic]} =
             generate(%DesignDocument{root_nodes: [boundary([outer])]}, contract())

    assert diagnostic.metadata.reason == :state_rule_cross_owner_cascade_authority_gap
  end

  test "uses inclusive viewport overlap for cross-owner state conflicts" do
    for {outer_max, inner_min, overlaps?} <- [{499, 500, false}, {500, 500, true}] do
      outer_id = DesignNode.deterministic_id([1, 1])
      inner_id = DesignNode.deterministic_id([1, 1, 1])
      target_id = DesignNode.deterministic_id([1, 1, 1, 1])

      target = %DesignNode{node_id: target_id, semantic_type: "container"}

      inner = %DesignNode{
        node_id: inner_id,
        semantic_type: "container",
        styles: %{
          "custom-css" =>
            state_value([
              state_rule("focus_within", target_id, %{"opacity" => literal(0.7)}, 0, %{
                "min_width" => inner_min,
                "max_width" => nil
              })
            ])
        },
        children: [target]
      }

      outer = %DesignNode{
        node_id: outer_id,
        semantic_type: "container",
        styles: %{
          "custom-css" =>
            state_value([
              state_rule("hover", target_id, %{"opacity" => literal(0.2)}, 0, %{
                "min_width" => nil,
                "max_width" => outer_max
              })
            ])
        },
        children: [inner]
      }

      result = generate(%DesignDocument{root_nodes: [boundary([outer])]}, contract())

      if overlaps? do
        assert blocked_reason(result) == :state_rule_cross_owner_cascade_authority_gap
      else
        bundle = bundle!(result)
        stylesheet = Enum.find(bundle.artifacts, &(&1.kind == :stylesheet)).content
        assert stylesheet =~ "@media (max-width: 499px)"
        assert stylesheet =~ "@media (min-width: 500px)"
      end
    end
  end

  test "keeps ordinary stylesheet bytes unchanged without state rules" do
    node = %DesignNode{
      node_id: DesignNode.deterministic_id([1, 1]),
      semantic_type: "container",
      styles: %{"display" => StyleValue.keyword("grid")},
      responsive: %{
        "mobile" => %ResponsiveOverride{
          breakpoint_id: "mobile",
          source_name: "mobile",
          resolution_status: :resolved,
          max_width: 767,
          styles: %{"gap" => StyleValue.literal(8)}
        }
      }
    }

    bundle = bundle!(generate(%DesignDocument{root_nodes: [boundary([node])]}, contract()))
    stylesheet = Enum.find(bundle.artifacts, &(&1.kind == :stylesheet)).content

    assert stylesheet ==
             ".lf-section-style-fixture__n-000001-000001 {\n" <>
               "  display: grid;\n}\n\n" <>
               "@media (max-width: 767px) {\n" <>
               "  .lf-section-style-fixture__n-000001-000001 {\n" <>
               "    gap: 8;\n  }\n}\n"
  end

  test "primary outline intent blocks instead of guessing a variant" do
    button = %DesignNode{
      node_id: DesignNode.deterministic_id([1, 1]),
      semantic_type: "button",
      attributes: %{"style" => "primary", "outline" => true}
    }

    document = %DesignDocument{root_nodes: [boundary([button])]}

    assert {:error, :generation_blocked, [diagnostic]} = generate(document, contract())
    assert diagnostic.code == "native_generator.styling.primary_action_variant_authority_gap"
  end

  test "semantic primary styles block on base property collisions" do
    button = %DesignNode{
      node_id: DesignNode.deterministic_id([1, 1]),
      semantic_type: "button",
      attributes: %{"style" => "primary"},
      styles: %{"color" => StyleValue.literal("red")}
    }

    document = %DesignDocument{root_nodes: [boundary([button])]}

    assert {:error, :generation_blocked, [diagnostic]} = generate(document, contract())

    assert diagnostic.code ==
             "native_generator.styling.primary_action_style_precedence_gap"
  end

  test "all category paths retain underscore intent names" do
    document = %DesignDocument{root_nodes: [boundary()]}

    expected = %{
      section: "assets/css/components/sections/style_fixture.css",
      component: "assets/css/components/style_fixture.css",
      pattern: "assets/css/components/patterns/style_fixture.css",
      primitive: "assets/css/components/primitives/style_fixture.css"
    }

    for {category, path} <- expected do
      bundle = bundle!(generate(document, contract(category)))
      stylesheet = Enum.find(bundle.artifacts, &(&1.kind == :stylesheet))
      assert stylesheet.path == path
      assert stylesheet.content == ""
    end
  end

  test "responsive-only nodes receive a class and unrelated roots stay outside the stylesheet" do
    responsive = %DesignNode{
      node_id: DesignNode.deterministic_id([1, 1]),
      semantic_type: "container",
      responsive: %{
        "mobile" => %ResponsiveOverride{
          breakpoint_id: "mobile",
          source_name: "mobile",
          resolution_status: :resolved,
          max_width: 767,
          styles: %{"gap" => StyleValue.literal(8)}
        }
      }
    }

    unrelated = %DesignNode{
      node_id: DesignNode.deterministic_id([2]),
      semantic_type: "section",
      styles: %{"display" => StyleValue.keyword("grid")}
    }

    document = %DesignDocument{root_nodes: [boundary([responsive]), unrelated]}
    bundle = bundle!(generate(document, contract()))
    stylesheet = Enum.find(bundle.artifacts, &(&1.kind == :stylesheet))
    module = Enum.find(bundle.artifacts, &(&1.kind == :elixir_module))

    assert stylesheet.content =~ ".lf-section-style-fixture__n-000001-000001 {"
    assert stylesheet.content =~ "@media (max-width: 767px)"
    assert module.content =~ "class={\"lf-section-style-fixture__n-000001-000001\"}"
    refute stylesheet.content =~ "lf-section-style-fixture__n-000002"
  end

  test "unsafe serialization and unresolved responsive inputs block generation" do
    unsafe_node = %DesignNode{
      node_id: DesignNode.deterministic_id([1]),
      semantic_type: "section",
      styles: %{"color" => StyleValue.literal("red; background: blue")}
    }

    unsafe_document = %DesignDocument{root_nodes: [unsafe_node]}

    assert {:error, :generation_blocked, [unsafe_diagnostic]} =
             generate(unsafe_document, contract())

    assert unsafe_diagnostic.code == "native_generator.styling.css_serialization_failed"

    responsive_node = %DesignNode{
      node_id: DesignNode.deterministic_id([1]),
      semantic_type: "section",
      responsive: %{
        "mobile" => %ResponsiveOverride{
          breakpoint_id: "mobile",
          source_name: "mobile",
          resolution_status: :unresolved,
          styles: %{"display" => StyleValue.keyword("grid")}
        }
      }
    }

    responsive_document = %DesignDocument{root_nodes: [responsive_node]}

    assert {:error, :generation_blocked, [responsive_diagnostic]} =
             generate(responsive_document, contract())

    assert responsive_diagnostic.code ==
             "native_generator.styling.responsive_cascade_authority_gap"
  end

  test "canonical path mismatches from styling integration remain generation_blocked" do
    node = %DesignNode{node_id: "node_renamed", semantic_type: "section"}
    document = %DesignDocument{root_nodes: [node]}
    c = contract()
    plan = %ComponentizationPlan{contract_id: c.contract_id, boundary_node_id: node.node_id}

    assert {:error, :generation_blocked, [diagnostic]} = StyleIntegration.build(c, plan, document)
    assert diagnostic.code == "native_generator.styling.node_identity_mismatch"
  end

  test "subtree slots prune styling on the target and all descendants" do
    slot_target_id = DesignNode.deterministic_id([1, 1])

    descendant = %DesignNode{
      node_id: DesignNode.deterministic_id([1, 1, 1]),
      semantic_type: "container",
      styles: %{"display" => StyleValue.keyword("grid")}
    }

    slot_target = %DesignNode{
      node_id: slot_target_id,
      semantic_type: "actions",
      styles: %{"color" => StyleValue.keyword("red")},
      children: [descendant]
    }

    document = %DesignDocument{root_nodes: [boundary([slot_target])]}

    slots = [
      %Slot{
        name: "actions",
        semantic_purpose: "actions",
        consumer_responsibility: "caller"
      }
    ]

    projection = %RenderProjection{
      public_slot_name: "actions",
      target_node_id: slot_target_id,
      render_role: :subtree_slot
    }

    bundle = bundle!(generate(document, contract(:section, [], slots), [projection]))
    stylesheet = Enum.find(bundle.artifacts, &(&1.kind == :stylesheet)).content
    module = Enum.find(bundle.artifacts, &(&1.kind == :elixir_module)).content
    target_class = "lf-section-style-fixture__n-000001-000001"
    descendant_class = target_class <> "-000001"

    assert module =~ "render_slot(@actions)"
    refute module =~ target_class
    refute module =~ descendant_class
    refute stylesheet =~ target_class
    refute stylesheet =~ descendant_class
    assert stylesheet == ""
  end

  test "an unresolved style inside a subtree slot does not block generation" do
    slot_target_id = DesignNode.deterministic_id([1, 1])

    descendant = %DesignNode{
      node_id: DesignNode.deterministic_id([1, 1, 1]),
      semantic_type: "container",
      styles: %{"display" => StyleValue.unresolved("var(--unresolved)")}
    }

    slot_target = %DesignNode{
      node_id: slot_target_id,
      semantic_type: "actions",
      children: [descendant]
    }

    document = %DesignDocument{root_nodes: [boundary([slot_target])]}
    assert :ok = IR.validate(document)

    slots = [
      %Slot{
        name: "actions",
        semantic_purpose: "actions",
        consumer_responsibility: "caller"
      }
    ]

    projection = %RenderProjection{
      public_slot_name: "actions",
      target_node_id: slot_target_id,
      render_role: :subtree_slot
    }

    bundle = bundle!(generate(document, contract(:section, [], slots), [projection]))
    stylesheet = Enum.find(bundle.artifacts, &(&1.kind == :stylesheet)).content

    assert stylesheet == ""
  end

  test "ordinary styled image places its private class on img" do
    image = %DesignNode{
      node_id: DesignNode.deterministic_id([1, 1]),
      semantic_type: "image",
      styles: %{"object-fit" => StyleValue.keyword("cover")}
    }

    document = %DesignDocument{root_nodes: [boundary([image])]}

    source_attr = %Attr{
      name: "src",
      type: :string,
      required: true,
      semantic_purpose: "image source",
      accessibility: %{"image_alt_policy" => "decorative"}
    }

    projection = %RenderProjection{
      public_attr_name: "src",
      render_role: :asset_src,
      target_node_id: image.node_id
    }

    bundle = bundle!(generate(document, contract(:section, [source_attr]), [projection]))
    module = Enum.find(bundle.artifacts, &(&1.kind == :elixir_module))

    assert module.content =~ "<img class={\"lf-section-style-fixture__n-000001-000001\"}"
  end

  test "each figure radius property stays on the figure and is inherited by img" do
    private_class = "lf-section-style-fixture__n-000001-000001"

    for property <- [
          "border-radius",
          "border-top-left-radius",
          "border-top-right-radius",
          "border-bottom-right-radius",
          "border-bottom-left-radius"
        ] do
      image = %DesignNode{
        node_id: DesignNode.deterministic_id([1, 1]),
        semantic_type: "image",
        attributes: %{"tag" => "figure"},
        styles: %{property => StyleValue.literal("1rem")}
      }

      root = boundary([image])
      c = contract()

      {:ok, result} =
        StyleIntegration.build(c, plan_for(root, c), %DesignDocument{root_nodes: [root]})

      stylesheet = result.stylesheet_content

      assert [figure_rule, image_rule] =
               String.split(stylesheet, "\n\n.#{private_class} > img {")

      assert figure_rule =~ ".#{private_class} {"
      assert figure_rule =~ "#{property}: 1rem;"
      refute figure_rule =~ "overflow: hidden;"
      assert String.trim(image_rule) == "border-radius: inherit;\n}"
    end
  end

  test "figure image dimensions and image-only properties keep their authorized loci" do
    image = %DesignNode{
      node_id: DesignNode.deterministic_id([1, 1]),
      semantic_type: "image",
      attributes: %{"tag" => "figure"},
      styles: %{
        "aspect-ratio" => StyleValue.literal("16/9"),
        "object-fit" => StyleValue.keyword("cover"),
        "width" => StyleValue.literal("100%"),
        "height" => StyleValue.literal("100%")
      }
    }

    root = boundary([image])
    c = contract()

    {:ok, result} =
      StyleIntegration.build(c, plan_for(root, c), %DesignDocument{root_nodes: [root]})

    stylesheet = result.stylesheet_content
    private_class = "lf-section-style-fixture__n-000001-000001"
    [figure_rule, image_rule] = String.split(stylesheet, "\n\n.#{private_class} > img {")

    assert figure_rule =~ "width: 100%;"
    assert figure_rule =~ "height: 100%;"
    refute figure_rule =~ "aspect-ratio:"
    refute figure_rule =~ "object-fit:"

    assert image_rule =~ "aspect-ratio: 16/9;"
    assert image_rule =~ "object-fit: cover;"
    assert image_rule =~ "width: 100%;"
    assert image_rule =~ "height: 100%;"
    refute image_rule =~ "border-radius: inherit;"
  end

  test "all dynamic heading alternatives reuse the node's private class" do
    heading = %DesignNode{
      node_id: DesignNode.deterministic_id([1, 1]),
      semantic_type: "heading",
      attributes: %{"tag" => "h2"}
    }

    document = %DesignDocument{root_nodes: [boundary([heading])]}

    attrs = [
      %Attr{
        name: "level",
        type: :integer,
        required: true,
        semantic_purpose: "heading level",
        validation: %{"values" => [1, 2, 3, 4, 5, 6]}
      },
      %Attr{name: "title", type: :string, semantic_purpose: "heading text"}
    ]

    projections = [
      %RenderProjection{
        public_attr_name: "level",
        render_role: :heading_level,
        target_node_id: heading.node_id
      },
      %RenderProjection{
        public_attr_name: "title",
        render_role: :text_content,
        target_node_id: heading.node_id
      }
    ]

    bundle = bundle!(generate(document, contract(:section, attrs), projections))
    module = Enum.find(bundle.artifacts, &(&1.kind == :elixir_module))
    stylesheet = Enum.find(bundle.artifacts, &(&1.kind == :stylesheet))
    class = "lf-section-style-fixture__n-000001-000001"

    assert length(String.split(module.content, class)) == 7
    assert stylesheet.content =~ "font-size: var(--lf-typography-heading-size-h2);"
    assert stylesheet.content =~ "font-weight: var(--lf-typography-display-weight);"
    assert stylesheet.content =~ "line-height: var(--lf-typography-display-line-height);"
    assert module.content =~ "class={\"#{class}\"}"
  end

  test "explicit heading typography wins property by property over H2 defaults" do
    node_id = DesignNode.deterministic_id([1, 1])

    for {property, value} <- [
          {"font-size", StyleValue.literal("30px")},
          {"font-weight", StyleValue.literal(700)},
          {"line-height", StyleValue.literal("1.4")}
        ] do
      heading = %DesignNode{
        node_id: node_id,
        semantic_type: "heading",
        attributes: %{"tag" => "h2"},
        styles: %{property => value}
      }

      bundle = bundle!(generate(%DesignDocument{root_nodes: [boundary([heading])]}, contract()))
      stylesheet = Enum.find(bundle.artifacts, &(&1.kind == :stylesheet)).content

      assert stylesheet =~ "#{property}: #{value.value};"

      for {fallback_property, fallback_value} <- [
            {"font-size", "var(--lf-typography-heading-size-h2)"},
            {"font-weight", "var(--lf-typography-display-weight)"},
            {"line-height", "var(--lf-typography-display-line-height)"}
          ],
          fallback_property != property do
        assert stylesheet =~ "#{fallback_property}: #{fallback_value};"
      end

      refute stylesheet =~ "#{property}: #{fallback_value_for(property)};"
    end
  end

  test "responsive heading typography remains separate from semantic base defaults" do
    heading = %DesignNode{
      node_id: DesignNode.deterministic_id([1, 1]),
      semantic_type: "heading",
      attributes: %{"tag" => "h2"},
      responsive: %{
        "mobile" => %ResponsiveOverride{
          breakpoint_id: "mobile",
          source_name: "mobile",
          resolution_status: :resolved,
          max_width: 767,
          styles: %{"font-size" => StyleValue.literal("24px")}
        }
      }
    }

    bundle = bundle!(generate(%DesignDocument{root_nodes: [boundary([heading])]}, contract()))
    stylesheet = Enum.find(bundle.artifacts, &(&1.kind == :stylesheet)).content
    [base_rule, responsive_rule] = String.split(stylesheet, "@media")

    assert base_rule =~ "font-size: var(--lf-typography-heading-size-h2);"
    assert responsive_rule =~ "font-size: 24px;"
    refute responsive_rule =~ "font-weight"
    refute responsive_rule =~ "line-height"
  end

  test "semantic H2 fallback is closed to every other heading tag" do
    headings =
      for {tag, index} <- Enum.with_index(["h1", "h3", "h4", "h5", "h6"], 1) do
        %DesignNode{
          node_id: DesignNode.deterministic_id([1, index]),
          semantic_type: "heading",
          attributes: %{"tag" => tag}
        }
      end

    {:ok, result} =
      StyleIntegration.build(
        contract(),
        plan_for(boundary(headings), contract()),
        %DesignDocument{root_nodes: [boundary(headings)]}
      )

    assert result.stylesheet_content == ""
    Enum.each(headings, &refute(Map.has_key?(result.private_class_by_id, &1.node_id)))
  end

  test "unmapped token styling on an H2 node blocks stylesheet generation" do
    heading = %DesignNode{
      node_id: DesignNode.deterministic_id([1, 1]),
      semantic_type: "heading",
      attributes: %{"tag" => "h2"},
      styles: %{"font-size" => StyleValue.token_ref("unknown.h2.path")}
    }

    assert {:error, :generation_blocked, [diagnostic]} =
             generate(%DesignDocument{root_nodes: [boundary([heading])]}, contract())

    assert diagnostic.code == "native_generator.styling.css_serialization_failed"

    assert diagnostic.metadata.reason ==
             {:invalid_declaration, "font-size",
              {:token_mapping_blocked, {:unknown_token_path, "unknown.h2.path"}}}
  end

  defp fallback_value_for("font-size"), do: "var(--lf-typography-heading-size-h2)"
  defp fallback_value_for("font-weight"), do: "var(--lf-typography-display-weight)"
  defp fallback_value_for("line-height"), do: "var(--lf-typography-display-line-height)"

  defp plan_for(root, c) do
    {:ok, fingerprint} =
      ComponentizationPlan.design_document_sha256(%DesignDocument{root_nodes: [root]})

    %ComponentizationPlan{
      contract_id: c.contract_id,
      design_document_sha256: fingerprint,
      boundary_node_id: root.node_id
    }
  end
end
