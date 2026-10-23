defmodule LiveFrames.BricksCustomCssNormalizerTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks.CustomCssNormalizer
  alias LiveFrames.Adapters.Bricks.CompoundCssValue
  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.IR.ResponsiveOverride
  alias LiveFrames.IR.SourceTrace
  alias LiveFrames.IR.StyleValue
  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.VariableAuthority

  @owner "owner"
  @child "child"
  @token "pointer-active"

  defp interaction_pair do
    [
      %{
        "action" => "setAttribute",
        "actionAttributeKey" => "class",
        "actionAttributeValue" => @token,
        "id" => "enter",
        "trigger" => "mouseenter"
      },
      %{
        "action" => "removeAttribute",
        "actionAttributeKey" => "class",
        "actionAttributeValue" => @token,
        "id" => "leave",
        "trigger" => "mouseleave"
      }
    ]
  end

  defp provenance(source_id, settings, opts) do
    origin = Keyword.get(opts, :origin, :global_class)

    %{
      origin: origin,
      class_id: if(origin == :global_class, do: "class-owner"),
      resolution_source: if(origin == :global_class, do: :local),
      authority_ids: [],
      class_reference_index:
        if(origin == :global_class, do: Keyword.get(opts, :class_reference_index, 0)),
      source_id: source_id,
      layer_settings: settings
    }
  end

  defp node(id, classes, path, opts \\ []) do
    %{
      node_id: "node_" <> Enum.map_join(path, "_", &Integer.to_string/1),
      source_id: id,
      parent_id: Keyword.get(opts, :parent_id),
      classes: classes,
      path: path,
      styles: Keyword.get(opts, :styles, %{}),
      responsive: Keyword.get(opts, :responsive, %{}),
      source_trace: %SourceTrace{source_id: id, source_path: "elements[#{id}]"}
    }
  end

  defp owner(css, opts \\ []) do
    settings = Keyword.get(opts, :settings, %{})

    %{
      source_id: Keyword.get(opts, :source_id, @owner),
      value: css,
      source_key: Keyword.get(opts, :source_key, "_cssCustom"),
      provenance:
        provenance(Keyword.get(opts, :source_id, @owner), settings,
          origin: Keyword.get(opts, :origin, :global_class),
          class_reference_index: Keyword.get(opts, :class_reference_index, 0)
        )
    }
  end

  defp variable_authority(variable, path) do
    %VariableAuthority{
      by_variable: %{variable => %{path => []}},
      tokens_by_path: %{path => Token.new(path: path, resolution_status: :resolved)}
    }
  end

  defp responsive_custom_css_override(source_key, opts \\ []) do
    %ResponsiveOverride{
      breakpoint_id: Keyword.get(opts, :breakpoint_id, "authority-breakpoint-id"),
      source_name: Keyword.get(opts, :source_name, "authority-source-name"),
      min_width: Keyword.get(opts, :min_width, 321.0),
      max_width: Keyword.get(opts, :max_width, 654.0),
      resolution_status: Keyword.get(opts, :resolution_status, :unresolved),
      styles: %{
        "custom-css" =>
          StyleValue.complex_css(
            %{"type" => "custom_css", "source_key" => source_key},
            metadata: %{"source_key" => source_key}
          )
      }
    }
  end

  defp run(css, opts \\ []) do
    source_owner = owner(css, opts)

    nodes = %{
      @owner =>
        node(@owner, ["owner"], [1],
          styles: Keyword.get(opts, :owner_styles, %{}),
          responsive: Keyword.get(opts, :owner_responsive, %{})
        ),
      @child => node(@child, ["child"], [1, 1], parent_id: @owner)
    }

    CustomCssNormalizer.normalize(
      [source_owner],
      nodes,
      %{@owner => [@child]},
      Keyword.get(opts, :claimed_source_ids, MapSet.new()),
      Keyword.get(opts, :opts, [])
    )
  end

  defp run_sources(source_specs, opts \\ []) do
    source_owners =
      Enum.map(source_specs, fn
        {css, source_key, viewport_scope, settings} ->
          owner(css, source_key: source_key, settings: settings)
          |> Map.put(:viewport_scope, viewport_scope)

        {css, source_key, viewport_scope} ->
          owner(css, source_key: source_key)
          |> Map.put(:viewport_scope, viewport_scope)
      end)

    nodes = %{
      @owner =>
        node(@owner, Keyword.get(opts, :owner_classes, ["owner"]), [1],
          styles: Keyword.get(opts, :owner_styles, %{}),
          responsive: Keyword.get(opts, :owner_responsive, %{})
        ),
      @child =>
        node(@child, Keyword.get(opts, :child_classes, ["child"]), [1, 1],
          parent_id: @owner,
          responsive: Keyword.get(opts, :child_responsive, %{})
        )
    }

    CustomCssNormalizer.normalize(
      source_owners,
      nodes,
      %{@owner => [@child]},
      Keyword.get(opts, :claimed_source_ids, MapSet.new()),
      Keyword.get(opts, :opts, [])
    )
  end

  defp normalize_tree(css, nodes, children_by_source_id, opts \\ []) do
    CustomCssNormalizer.normalize(
      [owner(css)],
      nodes,
      children_by_source_id,
      MapSet.new(),
      opts
    )
  end

  defp wide_tree(target_count) do
    children = Enum.map(1..target_count, &"child-#{&1}")

    nodes =
      Enum.reduce(Enum.with_index(children, 2), %{@owner => node(@owner, ["owner"], [1])}, fn
        {child_id, index}, nodes ->
          Map.put(nodes, child_id, node(child_id, ["child"], [1, index], parent_id: @owner))
      end)

    {nodes, %{@owner => children}}
  end

  defp transition_css(definitions, value),
    do: ".owner { #{definitions} transition: #{value}; }"

  test "relocates a safe conditionless rule to its target node" do
    result = run(".owner { color: red; }")

    assert %StyleValue{kind: :literal, value: "red"} =
             result.styles_by_source_id[@owner]["color"]

    assert result.custom_css_by_source_id[@owner] == nil
    assert result.residuals_by_source_id[@owner] == []
  end

  test "keeps values outside compound admission on the generic path" do
    for {property, value} <- [
          {"color", "teal"},
          {"justify-content", "center center"},
          {"margin", "10 20px"},
          {"color", "unknown-function(teal)"},
          {"color", "linear-gradient(90deg, transparent, +)"}
        ] do
      result = run(".owner { #{property}: #{value}; }")

      assert result.residuals_by_source_id[@owner] == [], inspect({property, value})
      assert result.styles_by_source_id[@owner][property].value == value
    end
  end

  test "routes admitted malformed compound values to a closed residual" do
    for value <- [
          "linear-gradient(90deg, var(--accent), +)",
          "unknown-function(var(--accent))",
          "calc(var(--measure) + 2px)",
          "var(--duration) + var(--timing)"
        ] do
      result = run(".owner { color: #{value}; }")
      assert [%{"reason" => "unresolved_value"}] = result.residuals_by_source_id[@owner]
    end
  end

  test "finalizes supported compounds as literal values" do
    cases = [
      {"background", "linear-gradient(90deg, var(--accent) 100%)",
       "linear-gradient(90deg, rgb(1,2,3) 100%)", "--accent: rgb(1,2,3);"},
      {"width", "calc(var(--measure) * 2)", "calc(12px * 2)", "--measure: 12px;"},
      {"transition", "var(--duration) var(--timing)", "250ms ease-in-out",
       "--duration: 250ms; --timing: ease-in-out;"},
      {"gap", "10px 20px", "10px 20px", ""}
    ]

    for {property, expression, expected, definitions} <- cases do
      result = run(".owner { #{definitions} #{property}: #{expression}; }")

      assert %StyleValue{kind: :literal, value: ^expected} =
               result.styles_by_source_id[@owner][property]

      assert result.residuals_by_source_id[@owner] == []
    end
  end

  test "trims ASCII CSS whitespace before compound parsing" do
    result =
      run(".owner { --measure: 12px; width: \t \f\r\ncalc(var(--measure) * 2)\n \t; }")

    assert %StyleValue{kind: :literal, value: "calc(12px * 2)"} =
             result.styles_by_source_id[@owner]["width"]

    assert result.residuals_by_source_id[@owner] == []
  end

  test "rejects compound terminals that do not fit their occurrence slot" do
    result =
      run(
        ".owner { --duration: ease-in-out; --timing: ease-in-out; transition: var(--duration) var(--timing); }"
      )

    assert [%{"reason" => "unresolved_value"}] = result.residuals_by_source_id[@owner]
    refute Map.has_key?(Map.get(result.styles_by_source_id, @owner, %{}), "transition")
  end

  test "keeps ineligible and nested compound definitions closed" do
    ineligible =
      run(
        ".owner:hover { --accent: rgb(1,2,3); } .owner { background: linear-gradient(90deg, var(--accent) 100%); }"
      )

    assert [
             %{"reason" => "unsupported_scope"},
             %{"reason" => "unresolved_value"}
           ] = ineligible.residuals_by_source_id[@owner]

    nested =
      run(
        ".owner { --base: 12px; --derived: calc(var(--base)); width: calc(var(--derived) * 2); }"
      )

    assert [%{"reason" => "unresolved_value"}] = nested.residuals_by_source_id[@owner]
    refute Map.has_key?(Map.get(nested.styles_by_source_id, @owner, %{}), "width")
  end

  test "keeps compound references closed for state scope and external-only names" do
    state_scoped =
      run(".owner { --measure: 12px; } .owner:hover { width: calc(var(--measure) * 2); }")

    assert [%{"reason" => "unresolved_value"}] = state_scoped.residuals_by_source_id[@owner]

    authority_index = variable_authority("--external-accent", "color.accent")

    external =
      run(
        ".owner { background: linear-gradient(90deg, var(--external-accent) 100%); }",
        opts: [authority_index: authority_index]
      )

    assert [%{"reason" => "unresolved_value"}] = external.residuals_by_source_id[@owner]
    refute Map.has_key?(Map.get(external.styles_by_source_id, @owner, %{}), "background")
  end

  test "normalizes each target occurrence of a compound declaration" do
    nodes = %{
      @owner => node(@owner, ["owner"], [1]),
      "first-item" => node("first-item", ["item"], [1, 1], parent_id: @owner),
      "second-item" => node("second-item", ["item"], [1, 2], parent_id: @owner)
    }

    result =
      normalize_tree(
        ".owner { --measure: 12px; } .owner .item { width: calc(var(--measure) * 2); }",
        nodes,
        %{@owner => ["first-item", "second-item"]}
      )

    for source_id <- ["first-item", "second-item"] do
      assert %StyleValue{kind: :literal, value: "calc(12px * 2)"} =
               result.styles_by_source_id[source_id]["width"]
    end
  end

  test "keeps a mixed compound rule atomic when a sibling is unsafe" do
    result =
      run(
        ".owner { --measure: 12px; } .owner { width: calc(var(--measure) * 2); background: url(https://example.test/image.png); }"
      )

    assert [%{"reason" => "unsafe_declaration"}] = result.residuals_by_source_id[@owner]
    refute Map.has_key?(Map.get(result.styles_by_source_id, @owner, %{}), "width")
    refute Map.has_key?(Map.get(result.styles_by_source_id, @owner, %{}), "background")
  end

  test "a compound local name cannot fall back to external variable authority" do
    authority_index = variable_authority("--external-space", "spacing.content_gap")

    result =
      run(".owner { background: linear-gradient(90deg, var(--external-space) 100%); }",
        opts: [authority_index: authority_index]
      )

    refute Map.has_key?(Map.get(result.styles_by_source_id, @owner, %{}), "background")
    assert [%{"reason" => "unresolved_value"}] = result.residuals_by_source_id[@owner]
  end

  test "compound reference names retain leading hyphens without resolving a different local name" do
    result =
      run(".owner { --accent: rgb(1,2,3); background: linear-gradient(90deg, var(----accent)); }")

    refute Map.has_key?(Map.get(result.styles_by_source_id, @owner, %{}), "background")
    assert [%{"reason" => "unresolved_value"}] = result.residuals_by_source_id[@owner]
  end

  test "overflowing resolved compound terminals fail closed" do
    overflowing_number = String.duplicate("9", 400)

    duration_result =
      run(
        ".owner { --duration: " <>
          overflowing_number <>
          "s; --timing: ease-in-out; transition: var(--duration) var(--timing); }"
      )

    refute Map.has_key?(Map.get(duration_result.styles_by_source_id, @owner, %{}), "transition")

    assert [%{"reason" => "unresolved_value"}] =
             duration_result.residuals_by_source_id[@owner]

    alpha_result =
      run(
        ".owner { --stop: rgba(1,2,3," <>
          overflowing_number <>
          ".0); background: linear-gradient(90deg, var(--stop)); }"
      )

    refute Map.has_key?(Map.get(alpha_result.styles_by_source_id, @owner, %{}), "background")
    assert [%{"reason" => "unresolved_value"}] = alpha_result.residuals_by_source_id[@owner]
  end

  test "compound and direct references share the 1024-record target-expansion budget" do
    {nodes, children_by_source_id} = wide_tree(511)

    css =
      ".owner { --duration: 250ms; --timing: ease-in-out; --accent: rgb(1,2,3); " <>
        "color: var(--accent); background-color: var(--accent); }\n" <>
        ".owner .child { width: var(--duration) var(--timing); }"

    result = normalize_tree(css, nodes, children_by_source_id)

    assert %StyleValue{kind: :literal, value: "rgb(1,2,3)"} =
             result.styles_by_source_id[@owner]["color"]

    assert %StyleValue{kind: :literal, value: "rgb(1,2,3)"} =
             result.styles_by_source_id[@owner]["background-color"]

    assert %StyleValue{kind: :literal, value: "250ms ease-in-out"} =
             result.styles_by_source_id["child-1"]["width"]

    assert map_size(result.styles_by_source_id) == 512

    assert Enum.all?(result.residuals_by_source_id, fn {_source_id, residuals} ->
             residuals == []
           end)

    over_budget_css =
      ".owner { --duration: 250ms; --timing: ease-in-out; --accent: rgb(1,2,3); " <>
        "color: var(--accent); background-color: var(--accent); " <>
        "border-color: var(--accent); }\n" <>
        ".owner .child { width: var(--duration) var(--timing); }"

    over_budget = normalize_tree(over_budget_css, nodes, children_by_source_id)

    assert over_budget.styles_by_source_id == %{}
    assert over_budget.responsive_by_source_id == %{}

    assert Enum.any?(over_budget.residuals_by_source_id, fn {_source_id, residuals} ->
             Enum.any?(residuals, &(&1["reason"] == "resource_limit_exceeded"))
           end)
  end

  test "unobserved compound references consume the target-expansion reference budget" do
    css = ".owner .child { width: calc(var(--missing) * 2); }"

    {nodes_at_limit, children_at_limit} = wide_tree(1_024)
    at_limit = normalize_tree(css, nodes_at_limit, children_at_limit)

    assert at_limit.styles_by_source_id == %{}
    assert at_limit.responsive_by_source_id == %{}

    assert [%{"reason" => "unresolved_value", "source_text" => ^css}] =
             at_limit.residuals_by_source_id[@owner]

    refute Enum.any?(at_limit.styles_by_source_id, fn {_source_id, styles} ->
             Enum.any?(styles, fn {_property, value} -> value.kind == :token_ref end)
           end)

    {nodes_over_limit, children_over_limit} = wide_tree(1_025)
    over_limit = normalize_tree(css, nodes_over_limit, children_over_limit)

    assert over_limit.styles_by_source_id == %{}
    assert over_limit.responsive_by_source_id == %{}

    assert [%{"reason" => "resource_limit_exceeded", "source_text" => ^css}] =
             over_limit.residuals_by_source_id[@owner]

    refute Enum.any?(over_limit.styles_by_source_id, fn {_source_id, styles} ->
             Enum.any?(styles, fn {_property, value} -> value.kind == :token_ref end)
           end)
  end

  test "relocates conditionless descendant rules only to descendants in the owner subtree" do
    result = run(".owner .child { color: red; }")

    assert %StyleValue{kind: :literal, value: "red"} =
             result.styles_by_source_id[@child]["color"]

    refute Map.has_key?(result.styles_by_source_id, @owner)
  end

  test "applies a conditionless descendant selector to every matching node in scope" do
    nodes = %{
      @owner => node(@owner, ["owner"], [1]),
      "late-item" => node("late-item", ["item"], [1, 10], parent_id: @owner),
      "early-item" => node("early-item", ["item"], [1, 2], parent_id: @owner),
      "outside-item" => node("outside-item", ["item"], [2])
    }

    result =
      normalize_tree(
        ".owner .item { color: red; }",
        nodes,
        %{@owner => ["late-item", "early-item"]}
      )

    for source_id <- ["early-item", "late-item"] do
      assert %StyleValue{kind: :literal, value: "red"} =
               result.styles_by_source_id[source_id]["color"]
    end

    refute Map.has_key?(result.styles_by_source_id, "outside-item")
  end

  test "relocates min-only responsive rules with an inclusive resolved override" do
    result = run("@media (min-width: 767px) { .owner { color: red; } }")

    assert %ResponsiveOverride{min_width: 767.0, max_width: nil, resolution_status: :resolved} =
             result.responsive_by_source_id[@owner]["custom_min_767"]

    assert %StyleValue{kind: :literal, value: "red"} =
             result.responsive_by_source_id[@owner]["custom_min_767"].styles["color"]
  end

  test "relocates max-only responsive rules" do
    result = run("@media (max-width: 767px) { .owner { color: red; } }")

    assert %ResponsiveOverride{min_width: nil, max_width: 767.0} =
             result.responsive_by_source_id[@owner]["custom_max_767"]
  end

  test "relocates bounded responsive ranges" do
    result = run("@media (min-width: 767.5px) and (max-width: 991px) { .owner { color: red; } }")

    assert %ResponsiveOverride{min_width: 767.5, max_width: 991.0} =
             result.responsive_by_source_id[@owner]["custom_range_767p5_991"]
  end

  test "canonicalizes integer-like responsive dimensions without dropping integer zeros" do
    for {dimension, key} <- [{"767.0", "custom_min_767"}, {"1000.0", "custom_min_1000"}] do
      result = run("@media (min-width: #{dimension}px) { .owner { color: red; } }")

      assert Map.has_key?(result.responsive_by_source_id[@owner], key)
    end
  end

  test "canonicalizes fractional responsive dimensions" do
    result = run("@media (min-width: 767.5px) { .owner { color: red; } }")

    assert Map.has_key?(result.responsive_by_source_id[@owner], "custom_min_767p5")
  end

  test "expands large finite responsive dimensions without colliding with one pixel" do
    result =
      run(
        "@media (min-width: 1px) { .owner { color: red; } }\n" <>
          "@media (min-width: 100000000000000000000px) { .owner { color: red; } }"
      )

    assert Map.keys(result.responsive_by_source_id[@owner]) |> MapSet.new() ==
             MapSet.new(["custom_min_1", "custom_min_100000000000000000000"])
  end

  test "expands very small finite responsive dimensions from exponent notation" do
    result = run("@media (min-width: 0.0000001px) { .owner { color: red; } }")

    assert Map.has_key?(result.responsive_by_source_id[@owner], "custom_min_0p0000001")
  end

  test "maps a proven same-layer transient alias to hover and removes its source token" do
    result =
      run(".owner.#{@token} { opacity: 1; }", settings: %{"_interactions" => interaction_pair()})

    state = result.custom_css_by_source_id[@owner].value
    assert state["type"] == "state_rules"
    assert [%{"condition" => "hover", "target_node_id" => "node_1"}] = state["rules"]
    refute String.contains?(inspect(state), @token)
  end

  test "maps literal focus-within to a state rule" do
    result = run(".owner:focus-within .child { opacity: 1; }")

    assert [%{"condition" => "focus_within", "target_node_id" => "node_1_1"}] =
             result.custom_css_by_source_id[@owner].value["rules"]
  end

  test "expands hover descendant selectors to every matching node in numeric path order" do
    nodes = %{
      @owner => node(@owner, ["owner"], [1]),
      "late-item" => node("late-item", ["item"], [1, 10], parent_id: @owner),
      "early-item" => node("early-item", ["item"], [1, 2], parent_id: @owner)
    }

    result =
      normalize_tree(
        ".owner:hover .item { opacity: 1; }",
        nodes,
        %{@owner => ["late-item", "early-item"]}
      )

    assert %StyleValue{value: %{"type" => "state_rules", "rules" => rules}} =
             result.custom_css_by_source_id[@owner]

    assert Enum.map(rules, &{&1["condition"], &1["target_node_id"]}) == [
             {"hover", "node_1_2"},
             {"hover", "node_1_10"}
           ]
  end

  test "expands focus-within descendant selectors to every matching node" do
    nodes = %{
      @owner => node(@owner, ["owner"], [1]),
      "item-a" => node("item-a", ["item"], [1, 1], parent_id: @owner),
      "item-b" => node("item-b", ["item"], [1, 2], parent_id: @owner)
    }

    result =
      normalize_tree(
        ".owner:focus-within .item { opacity: 1; }",
        nodes,
        %{@owner => ["item-a", "item-b"]}
      )

    assert %StyleValue{value: %{"type" => "state_rules", "rules" => rules}} =
             result.custom_css_by_source_id[@owner]

    assert Enum.map(rules, &{&1["condition"], &1["target_node_id"]}) == [
             {"focus_within", "node_1_1"},
             {"focus_within", "node_1_2"}
           ]
  end

  test "expands comma groups and orders hover before focus-within" do
    result = run(".owner:focus-within, .owner:hover { opacity: 1; }")
    rules = result.custom_css_by_source_id[@owner].value["rules"]

    assert Enum.map(rules, &{&1["condition"], &1["order"]}) == [
             {"hover", 0},
             {"focus_within", 1}
           ]
  end

  test "retains an unproven transient token as inert residual" do
    result = run(".owner.#{@token} { opacity: 1; }")

    assert %StyleValue{value: %{"type" => "custom_css", "rules" => [residual]}} =
             result.custom_css_by_source_id[@owner]

    assert residual =~ @token
    assert [%{"reason" => "unsupported_selector"}] = result.residuals_by_source_id[@owner]
  end

  test "fails closed on an existing base style collision" do
    result =
      run(".owner { color: red; }",
        owner_styles: %{"color" => StyleValue.literal("blue")}
      )

    assert result.styles_by_source_id == %{}
    assert hd(result.residuals_by_source_id[@owner])["reason"] == "style_collision"
  end

  test "fails closed on an existing responsive key collision" do
    existing = %ResponsiveOverride{
      breakpoint_id: "custom_min_767",
      source_name: "custom_min_767",
      min_width: 767.0,
      max_width: nil,
      resolution_status: :resolved,
      styles: %{"color" => StyleValue.literal("blue")}
    }

    result =
      run("@media (min-width: 767px) { .owner { color: red; } }",
        owner_responsive: %{"custom_min_767" => existing}
      )

    assert result.responsive_by_source_id == %{}
    assert hd(result.residuals_by_source_id[@owner])["reason"] == "responsive_collision"
  end

  test "fails closed when inclusive responsive intervals overlap with different values" do
    result =
      run(
        "@media (max-width: 767px) { .owner { color: red; } }\n@media (min-width: 767px) { .owner { color: blue; } }"
      )

    assert result.responsive_by_source_id == %{}

    assert Enum.map(result.residuals_by_source_id[@owner], & &1["reason"]) == [
             "responsive_overlap_conflict",
             "responsive_overlap_conflict"
           ]
  end

  test "deduplicates exact responsive intervals and values" do
    result =
      run(
        "@media (min-width: 767px) { .owner { color: red; } }\n@media (min-width: 767px) { .owner { color: red; } }"
      )

    assert map_size(result.responsive_by_source_id[@owner]) == 1
    assert result.residuals_by_source_id[@owner] == []
  end

  test "keeps unsupported selectors as residual" do
    result = run(".owner > .child { color: red; }")

    assert hd(result.residuals_by_source_id[@owner])["reason"] == "unsupported_selector"
    assert result.styles_by_source_id == %{}
  end

  test "preserves the full source value when unsupported CSS is residual-only" do
    css = " \n\n.owner img {\n  height: 100%;\n}\n\n\n"
    result = run(css)

    assert result.styles_by_source_id == %{}

    assert result.residuals_by_source_id[@owner] == [
             %{
               "reason" => "unsupported_selector",
               "source_text" => ".owner img {\n  height: 100%;\n}"
             }
           ]

    assert %StyleValue{value: %{"type" => "custom_css", "rules" => [^css]}} =
             result.custom_css_by_source_id[@owner]
  end

  test "keeps mixed state-rule residuals atomic" do
    css = ".owner:hover { opacity: 1; }\n\n.owner > .child { color: red; }\n\n"
    result = run(css)

    assert %StyleValue{
             value: %{
               "type" => "state_rules",
               "rules" => [%{"condition" => "hover"}],
               "residual" => [
                 %{
                   "reason" => "unsupported_selector",
                   "source_text" => ".owner > .child { color: red; }"
                 }
               ]
             }
           } = result.custom_css_by_source_id[@owner]
  end

  test "does not restore normalized conditionless rules into residual fallback" do
    css = ".owner { color: red; }\n\n.owner > .child { opacity: 1; }\n\n"
    result = run(css)

    assert %StyleValue{kind: :literal, value: "red"} =
             result.styles_by_source_id[@owner]["color"]

    assert %StyleValue{value: %{"type" => "custom_css", "rules" => [residual]}} =
             result.custom_css_by_source_id[@owner]

    assert residual == ".owner > .child { opacity: 1; }"
  end

  test "diagnostics trace unsupported global class CSS through its class reference" do
    result = run(".owner > .child { color: red; }", class_reference_index: 1)

    assert %Diagnostic{source_path: "elements[owner].class_refs[1].settings._cssCustom"} =
             hd(result.diagnostics)

    refute String.contains?(hd(result.diagnostics).source_path, ".settings.settings.")
  end

  test "diagnostics trace element-local CSS through element settings" do
    result = run(".owner > .child { color: red; }", origin: :element_local)

    assert %Diagnostic{source_path: "elements[owner].settings._cssCustom"} =
             hd(result.diagnostics)

    refute String.contains?(hd(result.diagnostics).source_path, "class_refs[")
  end

  test "diagnostics preserve responsive custom CSS source keys and nonzero class indexes" do
    result =
      run(".owner > .child { color: red; }",
        source_key: "_cssCustom:tablet",
        class_reference_index: 2
      )

    assert %Diagnostic{
             source_path: "elements[owner].class_refs[2].settings._cssCustom:tablet"
           } = hd(result.diagnostics)
  end

  test "keeps an unsafe declaration and its whole rule as residual" do
    result = run(".owner { color: red; background-image: url(https://example.test/a.png); }")

    assert result.styles_by_source_id == %{}
    assert hd(result.residuals_by_source_id[@owner])["reason"] == "unsafe_declaration"
  end

  test "keeps a duplicate-property rule as residual" do
    result = run(".owner { color: red; color: blue; }")

    assert result.styles_by_source_id == %{}
    assert hd(result.residuals_by_source_id[@owner])["reason"] == "unsupported_declaration"
  end

  test "resolves an exact passthrough through the normalizer flow" do
    result = run(".owner { --b: 12px; --a: var(--b); color: var(--a); }")

    assert %StyleValue{kind: :literal, value: "12px"} =
             result.styles_by_source_id[@owner]["color"]

    refute Map.has_key?(result.styles_by_source_id[@owner], "--a")
    refute Map.has_key?(result.styles_by_source_id[@owner], "--b")
    assert result.residuals_by_source_id[@owner] == []
  end

  test "resolves a direct local custom property without emitting its definition" do
    result = run(".owner { --local-space: 12px; color: var(--local-space); }")

    assert %StyleValue{kind: :literal, value: "12px"} =
             result.styles_by_source_id[@owner]["color"]

    refute Map.has_key?(result.styles_by_source_id[@owner], "--local-space")
    assert result.residuals_by_source_id[@owner] == []
  end

  test "a definition with an invalid downstream var dependency remains a whole-rule residual" do
    css = ".owner { --local-name: var(color); }"
    result = run(css)

    assert result.styles_by_source_id == %{}
    assert result.responsive_by_source_id == %{}

    refute Enum.any?(result.styles_by_source_id, fn {_source_id, styles} ->
             Enum.any?(styles, fn {_property, value} -> value.kind == :token_ref end)
           end)

    assert [%{"reason" => "unresolved_value", "source_text" => ^css}] =
             result.residuals_by_source_id[@owner]
  end

  test "a definition with an unsupported terminal dependency remains a whole-rule residual" do
    css =
      ".owner { --theme-token: var(--external-space); color: var(--theme-token); }"

    result = run(css)

    assert result.styles_by_source_id == %{}
    assert result.responsive_by_source_id == %{}

    refute Enum.any?(result.styles_by_source_id, fn {_source_id, styles} ->
             Enum.any?(styles, fn {_property, value} -> value.kind == :token_ref end)
           end)

    assert [%{"reason" => "unresolved_value", "source_text" => ^css}] =
             result.residuals_by_source_id[@owner]
  end

  test "resolving a direct local consumer does not drop a failed definition rule" do
    css =
      ".owner { --theme-token: var(--external-space); color: var(--theme-token); }\n" <>
        ".owner { --local-space: 12px; width: var(--local-space); }"

    result = run(css)

    assert %StyleValue{kind: :literal, value: "12px"} =
             result.styles_by_source_id[@owner]["width"]

    refute Map.has_key?(result.styles_by_source_id[@owner], "--local-space")

    assert Enum.any?(result.residuals_by_source_id[@owner], fn residual ->
             residual["reason"] == "unresolved_value" and
               residual["source_text"] =~ "--theme-token"
           end)
  end

  test "mixed-case var spelling stays outside the direct local-variable lane" do
    css = ".owner { --local-space: 12px; color: VaR(--local-space); }"
    result = run(css)

    refute Map.has_key?(Map.get(result.styles_by_source_id, @owner, %{}), "color")

    assert [%{"reason" => "unresolved_value", "source_text" => ^css}] =
             result.residuals_by_source_id[@owner]
  end

  test "parser media definitions cannot satisfy base references" do
    media_definition_rule = ".owner { --local-space: 12px; }"
    consumer_rule = ".owner { color: var(--local-space); }"

    result =
      run("@media (min-width: 767px) { " <> media_definition_rule <> " }\n" <> consumer_rule)

    refute Map.has_key?(Map.get(result.styles_by_source_id, @owner, %{}), "color")

    assert Enum.any?(result.residuals_by_source_id[@owner], fn residual ->
             residual["reason"] == "unsupported_scope" and
               residual["source_text"] == media_definition_rule
           end)

    assert Enum.any?(result.residuals_by_source_id[@owner], fn residual ->
             residual["source_text"] == consumer_rule
           end)
  end

  test "base definitions remain available to parser media references" do
    result =
      run(
        ".owner { --local-space: 12px; }\n" <>
          "@media (min-width: 767px) { .owner { color: var(--local-space); } }"
      )

    assert %StyleValue{kind: :literal, value: "12px"} =
             result.responsive_by_source_id[@owner]["custom_min_767"].styles["color"]
  end

  test "state-scoped definition rules remain residual and do not satisfy base references" do
    definition_rule = ".owner:hover { --local-space: 12px; }"

    result =
      run(definition_rule <> "\n.owner { color: var(--local-space); }")

    refute Map.has_key?(Map.get(result.styles_by_source_id, @owner, %{}), "color")

    assert Enum.any?(result.residuals_by_source_id[@owner], fn residual ->
             residual["reason"] == "unsupported_scope" and
               residual["source_text"] == definition_rule
           end)
  end

  test "responsive source definition-only rules remain unsupported residuals" do
    source_key = "_cssCustom:mobile_portrait"
    definition_rule = ".owner { --local-space: 12px; }"

    result =
      run_sources(
        [{definition_rule, source_key, {:responsive_source_key, source_key}}],
        owner_responsive: %{
          "mobile_portrait" => responsive_custom_css_override(source_key)
        }
      )

    refute Map.has_key?(result.responsive_by_source_id, @owner)

    assert Enum.any?(result.residuals_by_source_id[@owner], fn residual ->
             residual["reason"] == "unsupported_scope" and
               residual["source_text"] == definition_rule
           end)
  end

  test "uses external authority when no local definition is observed" do
    authority_index = variable_authority("--external-space", "spacing.content_gap")

    result =
      run(".owner { color: var(--external-space); }",
        opts: [authority_index: authority_index]
      )

    assert %StyleValue{kind: :token_ref, value: "spacing.content_gap"} =
             result.styles_by_source_id[@owner]["color"]
  end

  test "an ineligible local definition prevents external authority fallback" do
    authority_index = variable_authority("--local-space", "spacing.content_gap")

    result =
      run(
        ".owner > * { --local-space: 12px; }\n.owner { color: var(--local-space); }",
        opts: [authority_index: authority_index]
      )

    refute Map.has_key?(result.styles_by_source_id, @owner)

    assert Enum.any?(result.residuals_by_source_id[@owner], fn residual ->
             residual["source_text"] =~ "color: var(--local-space)"
           end)
  end

  test "different selector identities at one target make same-terminal definitions ambiguous" do
    css =
      ".owner { --local-space: 12px; }\n" <>
        ".owner.child { --local-space: 12px; }\n" <>
        ".owner { color: var(--local-space); }"

    result =
      run_sources(
        [{css, "_cssCustom", :base}],
        owner_classes: ["owner", "child"]
      )

    assert result.styles_by_source_id == %{}
    assert [%{"reason" => "unresolved_value"}] = result.residuals_by_source_id[@owner]
  end

  test "a local definition exactly in responsive source scope blocks base fallback" do
    source_key = "_cssCustom:mobile_portrait"

    result =
      run_sources([
        {".owner { --local-space: 12px; }", "_cssCustom", :base},
        {".owner { --local-space: 18px; color: var(--local-space); }", source_key,
         {:responsive_source_key, source_key}}
      ])

    assert result.styles_by_source_id == %{}
    assert result.responsive_by_source_id == %{}

    assert Enum.any?(
             result.residuals_by_source_id[@owner],
             &(&1["reason"] == "unsupported_scope")
           )
  end

  test "a nearest ancestor responsive definition blocks base fallback" do
    source_key = "_cssCustom:tablet_portrait"

    result =
      run_sources([
        {".owner { --local-space: 12px; }", "_cssCustom", :base},
        {".owner { --local-space: 18px; } .owner .child { color: var(--local-space); }",
         source_key, {:responsive_source_key, source_key}}
      ])

    assert result.responsive_by_source_id == %{}

    assert Enum.any?(
             result.residuals_by_source_id[@owner],
             &(&1["reason"] == "unresolved_value")
           )
  end

  test "uses the frozen provenance identity across different layer settings" do
    source_key = "_cssCustom:mobile_portrait"

    result =
      run_sources(
        [
          {".owner { --local-space: 12px; }", "_cssCustom", :base,
           %{"_cssCustom" => "base-owner-settings"}},
          {".owner .child { color: var(--local-space); }", source_key,
           {:responsive_source_key, source_key}, %{source_key => "responsive-owner-settings"}}
        ],
        owner_responsive: %{"mobile_portrait" => responsive_custom_css_override(source_key)}
      )

    assert %StyleValue{kind: :literal, value: "12px"} =
             result.responsive_by_source_id[@child]["mobile_portrait"].styles["color"]
  end

  test "an unwrapped responsive source remains responsive and keeps its exact source key" do
    source_key = "_cssCustom:mobile_landscape"

    result =
      run_sources(
        [
          {".owner { color: teal; }", source_key, {:responsive_source_key, source_key}}
        ],
        owner_responsive: %{
          "mobile_landscape" =>
            responsive_custom_css_override(source_key,
              min_width: nil,
              max_width: nil,
              resolution_status: :unresolved
            )
        }
      )

    assert result.styles_by_source_id == %{}

    assert %ResponsiveOverride{min_width: nil, max_width: nil} =
             result.responsive_by_source_id[@owner]["mobile_landscape"]

    assert %StyleValue{kind: :literal, value: "teal"} =
             result.responsive_by_source_id[@owner]["mobile_landscape"].styles["color"]
  end

  test "descendant responsive styles use the custom CSS owner's exact authority record" do
    source_key = "_cssCustom:mobile_portrait"
    authority = responsive_custom_css_override(source_key)

    result =
      run_sources(
        [
          {".owner .child { color: teal; }", source_key, {:responsive_source_key, source_key}}
        ],
        owner_responsive: %{"mobile_portrait" => authority}
      )

    assert Map.keys(result.responsive_by_source_id[@child]) == ["mobile_portrait"]

    assert %ResponsiveOverride{
             breakpoint_id: "authority-breakpoint-id",
             source_name: "authority-source-name",
             min_width: 321.0,
             max_width: 654.0,
             resolution_status: :unresolved,
             styles: %{"color" => %StyleValue{kind: :literal, value: "teal"}}
           } = result.responsive_by_source_id[@child]["mobile_portrait"]
  end

  test "descendant responsive styles merge with a nonconflicting target override" do
    source_key = "_cssCustom:mobile_portrait"

    existing_target = %ResponsiveOverride{
      breakpoint_id: "target-breakpoint-id",
      source_name: "target-source-name",
      min_width: 100.0,
      max_width: 200.0,
      resolution_status: :resolved,
      styles: %{"font-weight" => StyleValue.literal("bold")}
    }

    result =
      run_sources(
        [
          {".owner .child { color: teal; }", source_key, {:responsive_source_key, source_key}}
        ],
        owner_responsive: %{
          "mobile_portrait" => responsive_custom_css_override(source_key)
        },
        child_responsive: %{"mobile_portrait" => existing_target}
      )

    assert %ResponsiveOverride{
             breakpoint_id: "authority-breakpoint-id",
             source_name: "authority-source-name",
             min_width: 321.0,
             max_width: 654.0,
             styles: %{
               "font-weight" => %StyleValue{value: "bold"},
               "color" => %StyleValue{value: "teal"}
             }
           } = result.responsive_by_source_id[@child]["mobile_portrait"]
  end

  test "descendant responsive styles fail closed when target properties conflict" do
    source_key = "_cssCustom:mobile_portrait"

    conflicting_target = %ResponsiveOverride{
      breakpoint_id: "target-breakpoint-id",
      source_name: "target-source-name",
      min_width: 100.0,
      max_width: 200.0,
      resolution_status: :resolved,
      styles: %{"color" => StyleValue.literal("blue")}
    }

    result =
      run_sources(
        [
          {".owner .child { color: teal; }", source_key, {:responsive_source_key, source_key}}
        ],
        owner_responsive: %{
          "mobile_portrait" => responsive_custom_css_override(source_key)
        },
        child_responsive: %{"mobile_portrait" => conflicting_target}
      )

    refute Map.has_key?(result.responsive_by_source_id, @child)

    assert Enum.any?(result.residuals_by_source_id[@owner], fn residual ->
             residual["reason"] == "responsive_collision" and
               residual["source_text"] == ".owner .child { color: teal; }"
           end)
  end

  test "responsive candidates remain residual without an exact owner authority record" do
    source_key = "_cssCustom:mobile_portrait"
    css = ".owner .child { color: teal; }"

    result =
      run_sources([
        {css, source_key, {:responsive_source_key, source_key}}
      ])

    refute Map.has_key?(result.responsive_by_source_id, @child)

    assert Enum.any?(result.residuals_by_source_id[@owner], fn residual ->
             residual["reason"] == "unsupported_scope" and residual["source_text"] == css
           end)
  end

  test "responsive candidates do not match an owner authority with a different source key" do
    source_key = "_cssCustom:mobile_portrait"

    result =
      run_sources(
        [
          {".owner .child { color: teal; }", source_key, {:responsive_source_key, source_key}}
        ],
        owner_responsive: %{
          "mobile_portrait" => responsive_custom_css_override("_cssCustom:mobile_landscape")
        }
      )

    refute Map.has_key?(result.responsive_by_source_id, @child)

    assert Enum.any?(result.residuals_by_source_id[@owner], fn residual ->
             residual["reason"] == "unsupported_scope"
           end)
  end

  test "a responsive source wrapper and parser media scope stay residual" do
    source_key = "_cssCustom:mobile_portrait"

    result =
      run_sources([
        {"@media (min-width: 767px) { .owner { color: teal; } }", source_key,
         {:responsive_source_key, source_key}}
      ])

    assert result.responsive_by_source_id == %{}

    assert Enum.any?(
             result.residuals_by_source_id[@owner],
             &(&1["reason"] == "unsupported_scope")
           )
  end

  test "one unresolved target keeps a multi-target selector rule wholly residual" do
    nodes = %{
      @owner => node(@owner, ["owner"], [1]),
      "child-a" => node("child-a", ["child", "child-a"], [1, 1], parent_id: @owner),
      "child-b" => node("child-b", ["child", "child-b"], [1, 2], parent_id: @owner)
    }

    css =
      ".owner .child-a { --local-space: 12px; }\n" <>
        ".owner .child { color: var(--local-space); }"

    result =
      CustomCssNormalizer.normalize(
        [owner(css)],
        nodes,
        %{@owner => ["child-a", "child-b"]},
        MapSet.new()
      )

    assert result.styles_by_source_id == %{}
    assert result.responsive_by_source_id == %{}

    assert Enum.any?(
             result.residuals_by_source_id[@owner],
             &(&1["source_text"] =~ ".owner .child {")
           )
  end

  test "a resolved local terminal that fails declaration safety remains residual" do
    result =
      run(
        ".owner { --local-image: url(https://example.test/a.png); background-image: var(--local-image); }"
      )

    assert result.styles_by_source_id == %{}
    assert [%{"reason" => "unsafe_declaration"}] = result.residuals_by_source_id[@owner]
  end

  test "compound var expressions remain residual" do
    result = run(".owner { --local-space: 12px; margin: calc(var(--local-space) + 2px); }")

    assert result.styles_by_source_id == %{}
    assert [%{"reason" => "unresolved_value"}] = result.residuals_by_source_id[@owner]
  end

  test "CSS larger than the layer byte limit is rejected as one residual before parsing" do
    css = ".owner { color: red; }" <> String.duplicate(" ", 65_537)
    result = run(css)

    assert result.styles_by_source_id == %{}

    assert [%{"reason" => "resource_limit_exceeded", "source_text" => ^css}] =
             result.residuals_by_source_id[@owner]

    assert Enum.any?(
             result.diagnostics,
             &(&1.code == "bricks.custom_css.resource_limit_exceeded")
           )
  end

  test "a resolver batch over the reference limit produces no partial styles" do
    references = String.duplicate(".owner { color: var(--local-space); }\n", 1_025)
    css = ".owner { --local-space: teal; }\n" <> references
    result = run(css)

    assert result.styles_by_source_id == %{}

    assert [%{"reason" => "resource_limit_exceeded", "source_text" => ^css}] =
             result.residuals_by_source_id[@owner]

    assert Enum.any?(
             result.diagnostics,
             &(&1.code == "bricks.custom_css.resource_limit_exceeded")
           )
  end

  test "reference fan-out stops local record work at the first excess reference" do
    css =
      ".owner { --local-space: teal; }\n" <>
        ".owner .child { color: var(--local-space); }"

    {nodes, children_by_source_id} = wide_tree(4_096)
    authority_index = variable_authority("--local-space", "spacing.content_gap")
    reductions_before = elem(Process.info(self(), :reductions), 1)

    result =
      normalize_tree(css, nodes, children_by_source_id, authority_index: authority_index)

    reductions_after = elem(Process.info(self(), :reductions), 1)

    assert reductions_after - reductions_before < 900_000
    assert result.styles_by_source_id == %{}
    assert result.responsive_by_source_id == %{}

    assert [%{"reason" => "resource_limit_exceeded", "source_text" => ^css}] =
             result.residuals_by_source_id[@owner]

    refute Enum.any?(result.styles_by_source_id, fn {_source_id, styles} ->
             Enum.any?(styles, fn {_property, value} -> value.kind == :token_ref end)
           end)
  end

  test "definition fan-out stops local record work at the first excess definition" do
    css = ".owner .child { --local-space: teal; }"
    {nodes, children_by_source_id} = wide_tree(4_096)
    reductions_before = elem(Process.info(self(), :reductions), 1)

    result = normalize_tree(css, nodes, children_by_source_id)

    reductions_after = elem(Process.info(self(), :reductions), 1)

    assert reductions_after - reductions_before < 700_000
    assert result.styles_by_source_id == %{}
    assert result.responsive_by_source_id == %{}

    assert [%{"reason" => "resource_limit_exceeded", "source_text" => ^css}] =
             result.residuals_by_source_id[@owner]
  end

  test "parser media definitions stay unsupported when selector fan-out exceeds the definition limit" do
    rule = ".owner .child { --local-space: teal; }"
    css = "@media (min-width: 767px) { " <> rule <> " }"
    {nodes, children_by_source_id} = wide_tree(257)

    result = normalize_tree(css, nodes, children_by_source_id)

    assert [%{"reason" => "unsupported_scope", "source_text" => ^rule}] =
             result.residuals_by_source_id[@owner]
  end

  test "state definitions stay unsupported when selector fan-out exceeds the definition limit" do
    rule = ".owner:hover .child { --local-space: teal; }"
    {nodes, children_by_source_id} = wide_tree(257)

    result = normalize_tree(rule, nodes, children_by_source_id)

    assert [%{"reason" => "unsupported_scope", "source_text" => ^rule}] =
             result.residuals_by_source_id[@owner]
  end

  test "preserves malformed framing as one inert residual" do
    css = ".owner { color: red;"
    result = run(css)

    assert [%{"reason" => "malformed_block", "source_text" => ^css}] =
             result.residuals_by_source_id[@owner]
  end

  test "assigns deterministic state order by source rule and numeric node path" do
    source_owner =
      owner(
        ".owner:hover .child-b, .owner:hover .child-a { opacity: 1; }\n.owner:focus-within { color: red; }"
      )

    nodes = %{
      @owner => node(@owner, ["owner"], [1]),
      "child-b" => node("child-b", ["child-b"], [1, 2], parent_id: @owner),
      "child-a" => node("child-a", ["child-a"], [1, 1], parent_id: @owner)
    }

    result =
      CustomCssNormalizer.normalize(
        [source_owner],
        nodes,
        %{@owner => ["child-b", "child-a"]},
        MapSet.new()
      )

    rules = result.custom_css_by_source_id[@owner].value["rules"]

    assert Enum.map(rules, &{&1["condition"], &1["target_node_id"], &1["order"]}) == [
             {"hover", "node_1_1", 0},
             {"hover", "node_1_2", 1},
             {"focus_within", "node_1", 2}
           ]
  end

  test "state rules may target the owner itself" do
    result = run(".owner:hover { opacity: 1; }")
    assert hd(result.custom_css_by_source_id[@owner].value["rules"])["target_node_id"] == "node_1"
  end

  test "state rules may target descendants inside the owner subtree" do
    result = run(".owner:hover .child { opacity: 1; }")

    assert hd(result.custom_css_by_source_id[@owner].value["rules"])["target_node_id"] ==
             "node_1_1"
  end

  test "state selectors cannot target siblings outside the owner subtree" do
    source_owner = owner(".owner:hover .sibling { opacity: 1; }")

    nodes = %{
      @owner => node(@owner, ["owner"], [1]),
      @child => node(@child, ["child"], [1, 1], parent_id: @owner),
      "sibling" => node("sibling", ["sibling"], [2])
    }

    result =
      CustomCssNormalizer.normalize([source_owner], nodes, %{@owner => [@child]}, MapSet.new())

    assert hd(result.residuals_by_source_id[@owner])["reason"] == "unresolved_target"
    assert result.custom_css_by_source_id[@owner].value["type"] == "custom_css"
  end

  test "state selectors cannot target ancestors outside the owner subtree" do
    source_owner = owner(".owner:hover .ancestor { opacity: 1; }")

    nodes = %{
      "ancestor" => node("ancestor", ["ancestor"], [1]),
      @owner => node(@owner, ["owner"], [1, 1], parent_id: "ancestor"),
      @child => node(@child, ["child"], [1, 1, 1], parent_id: @owner)
    }

    result =
      CustomCssNormalizer.normalize([source_owner], nodes, %{@owner => [@child]}, MapSet.new())

    assert hd(result.residuals_by_source_id[@owner])["reason"] == "unresolved_target"
  end

  test "state selectors cannot target nodes outside the selected component" do
    source_owner = owner(".owner:hover .outside { opacity: 1; }")

    nodes = %{
      @owner => node(@owner, ["owner"], [1]),
      @child => node(@child, ["child"], [1, 1], parent_id: @owner),
      "outside" => node("outside", ["outside"], [2])
    }

    result =
      CustomCssNormalizer.normalize([source_owner], nodes, %{@owner => [@child]}, MapSet.new())

    assert hd(result.residuals_by_source_id[@owner])["reason"] == "unresolved_target"
  end

  test "keeps a state selector ambiguous when its owner compound matches multiple nodes" do
    css = ".owner:hover .item { opacity: 1; }"

    nodes = %{
      @owner => node(@owner, ["owner"], [1]),
      "nested-owner" => node("nested-owner", ["owner"], [1, 1], parent_id: @owner),
      "item" => node("item", ["item"], [1, 1, 1], parent_id: "nested-owner")
    }

    result =
      normalize_tree(
        css,
        nodes,
        %{@owner => ["nested-owner"], "nested-owner" => ["item"]}
      )

    assert [%{"reason" => "ambiguous_selector"}] = result.residuals_by_source_id[@owner]
    assert result.custom_css_by_source_id[@owner].value["type"] == "custom_css"
  end

  test "claimed Tango owners are excluded from generic normalization" do
    result =
      run(".owner { color: red; }",
        claimed_source_ids: MapSet.new([@owner])
      )

    assert result.styles_by_source_id == %{}
    assert result.custom_css_by_source_id == %{}
  end

  test "shared class owners resolve state targets within their own subtrees" do
    css = ".owner.#{@token} .child { opacity: 1; }"
    pair = interaction_pair()

    owners = [
      owner(css, source_id: "owner-a", settings: %{"_interactions" => pair}),
      owner(css, source_id: "owner-b", settings: %{"_interactions" => pair})
    ]

    nodes = %{
      "owner-a" => node("owner-a", ["owner"], [1]),
      "child-a" => node("child-a", ["child"], [1, 1], parent_id: "owner-a"),
      "owner-b" => node("owner-b", ["owner"], [2]),
      "child-b" => node("child-b", ["child"], [2, 1], parent_id: "owner-b")
    }

    result =
      CustomCssNormalizer.normalize(
        owners,
        nodes,
        %{"owner-a" => ["child-a"], "owner-b" => ["child-b"]},
        MapSet.new()
      )

    rules_a = result.custom_css_by_source_id["owner-a"].value["rules"]
    rules_b = result.custom_css_by_source_id["owner-b"].value["rules"]

    assert Enum.map(rules_a, & &1["target_node_id"]) == ["node_1_1"]
    assert Enum.map(rules_b, & &1["target_node_id"]) == ["node_2_1"]
    refute String.contains?(inspect(result.custom_css_by_source_id["owner-a"].value), @token)
    refute String.contains?(inspect(result.custom_css_by_source_id["owner-b"].value), @token)
  end

  test "resolves a one-spec transition shorthand to a literal StyleValue" do
    expression = "opacity var(--duration) var(--timing)"
    css = transition_css("--duration: 250ms; --timing: ease-in-out;", expression)

    assert {:ok, parsed} = CompoundCssValue.parse_transition_shorthand(expression)

    assert [
             %{
               occurrence_index: 0,
               local_name: "--duration",
               slot_grammar: :transition_duration_operand
             },
             %{
               occurrence_index: 1,
               local_name: "--timing",
               slot_grammar: :juxtaposition_right_operand
             }
           ] = CompoundCssValue.occurrences(parsed)

    result = run(css)

    assert %StyleValue{kind: :literal, value: "opacity 250ms ease-in-out"} =
             result.styles_by_source_id[@owner]["transition"]

    refute result.styles_by_source_id[@owner]["transition"].value =~ "var("
    assert result.residuals_by_source_id[@owner] == []
  end

  test "resolves a two-spec transition shorthand with canonical whitespace" do
    expression =
      "opacity var(--duration-a) var(--timing-a),\n  transform var(--duration-b) var(--timing-b)"

    definitions =
      "--duration-a: 250ms; --timing-a: ease-in-out; " <>
        "--duration-b: 1.5s; --timing-b: ease-in-out;"

    assert {:ok, parsed} = CompoundCssValue.parse_transition_shorthand(expression)

    assert Enum.map(CompoundCssValue.occurrences(parsed), &{&1.occurrence_index, &1.local_name}) ==
             [
               {0, "--duration-a"},
               {1, "--timing-a"},
               {2, "--duration-b"},
               {3, "--timing-b"}
             ]

    result = run(transition_css(definitions, expression))

    assert %StyleValue{
             kind: :literal,
             value: "opacity 250ms ease-in-out, transform 1.5s ease-in-out"
           } = result.styles_by_source_id[@owner]["transition"]

    refute result.styles_by_source_id[@owner]["transition"].value =~ "var("
    assert result.residuals_by_source_id[@owner] == []
  end

  test "fails closed for a leading NBSP at a transition value boundary" do
    nbsp = <<0xC2, 0xA0>>

    result =
      run(
        transition_css(
          "--duration: 250ms; --timing: ease-in-out;",
          nbsp <> "opacity var(--duration) var(--timing)"
        )
      )

    refute Enum.any?(result.styles_by_source_id, fn {_source_id, styles} ->
             Map.has_key?(styles, "transition")
           end)

    assert [%{"reason" => "unresolved_value"}] = result.residuals_by_source_id[@owner]
  end

  test "fails closed for a trailing NBSP at a transition value boundary" do
    nbsp = <<0xC2, 0xA0>>

    result =
      run(
        transition_css(
          "--duration: 250ms; --timing: ease-in-out;",
          "opacity var(--duration) var(--timing)" <> nbsp
        )
      )

    refute Enum.any?(result.styles_by_source_id, fn {_source_id, styles} ->
             Map.has_key?(styles, "transition")
           end)

    assert [%{"reason" => "unresolved_value"}] = result.residuals_by_source_id[@owner]
  end

  test "resolves transition values surrounded by ordinary ASCII CSS whitespace" do
    result =
      run(
        transition_css(
          "--duration: 250ms; --timing: ease-in-out;",
          "\t \f\r\nopacity var(--duration) var(--timing)\n \t"
        )
      )

    assert %StyleValue{kind: :literal, value: "opacity 250ms ease-in-out"} =
             result.styles_by_source_id[@owner]["transition"]

    assert result.residuals_by_source_id[@owner] == []
  end

  test "keeps transition literals without var on the ordinary generic path" do
    result = run(".owner { transition: opacity 250ms ease-in-out; }")

    assert %StyleValue{kind: :literal, value: "opacity 250ms ease-in-out"} =
             result.styles_by_source_id[@owner]["transition"]

    assert result.residuals_by_source_id[@owner] == []
  end

  test "keeps bare transition var juxtaposition on the existing path" do
    result =
      run(
        ".owner { --duration: 250ms; --timing: ease-in-out; " <>
          "transition: var(--duration) var(--timing); }"
      )

    assert %StyleValue{kind: :literal, value: "250ms ease-in-out"} =
             result.styles_by_source_id[@owner]["transition"]

    assert result.residuals_by_source_id[@owner] == []
  end

  test "does not route IDENT-prefixed references on non-transition properties" do
    result =
      run(
        ".owner { --duration: 250ms; --timing: ease-in-out; " <>
          "width: opacity var(--duration) var(--timing); }"
      )

    refute Map.has_key?(Map.get(result.styles_by_source_id, @owner, %{}), "width")
    assert [%{"reason" => "unresolved_value"}] = result.residuals_by_source_id[@owner]
  end

  test "maps malformed transition shorthand to unresolved_value" do
    definitions = "--duration: 250ms; --timing: ease-in-out;"

    for expression <- [
          ", opacity var(--duration) var(--timing)",
          "opacity var(--duration) var(--timing),",
          "opacity var(--duration) var(--timing),, transform var(--duration) var(--timing)",
          "opacity var(--duration)",
          "opacity var(--duration) var(--timing) extra",
          "opacity var(--duration invalid) var(--timing)",
          "opacity var(--duration, 250ms) var(--timing)"
        ] do
      result = run(transition_css(definitions, expression))
      assert [%{"reason" => "unresolved_value"}] = result.residuals_by_source_id[@owner]
      refute Map.has_key?(Map.get(result.styles_by_source_id, @owner, %{}), "transition")
    end
  end

  test "keeps a missing transition local definition fail closed" do
    for definitions <- [
          "--timing: ease-in-out;",
          "--duration: 250ms;"
        ] do
      result =
        run(
          transition_css(
            definitions,
            "opacity var(--duration) var(--timing)"
          )
        )

      refute Map.has_key?(Map.get(result.styles_by_source_id, @owner, %{}), "transition")
      assert [%{"reason" => "unresolved_value"}] = result.residuals_by_source_id[@owner]
    end
  end

  test "does not rescue transition references through external-only authority" do
    authority_index = variable_authority("--external-duration", "motion.duration")

    result =
      run(
        transition_css(
          "--timing: ease-in-out;",
          "opacity var(--external-duration) var(--timing)"
        ),
        opts: [authority_index: authority_index]
      )

    refute Map.has_key?(Map.get(result.styles_by_source_id, @owner, %{}), "transition")
    assert [%{"reason" => "unresolved_value"}] = result.residuals_by_source_id[@owner]
  end

  test "resolves a one-hop nested local definition for transition" do
    result =
      run(
        transition_css(
          "--base-duration: 250ms; --duration: var(--base-duration); --timing: ease-in-out;",
          "opacity var(--duration) var(--timing)"
        )
      )

    assert %StyleValue{kind: :literal, value: "opacity 250ms ease-in-out"} =
             result.styles_by_source_id[@owner]["transition"]

    assert result.residuals_by_source_id[@owner] == []
  end

  test "keeps a multi-hop nested local definition fail closed for transition" do
    result =
      run(
        transition_css(
          "--base-duration: 250ms; --mid-duration: var(--base-duration); --duration: var(--mid-duration); --timing: ease-in-out;",
          "opacity var(--duration) var(--timing)"
        )
      )

    refute Map.has_key?(Map.get(result.styles_by_source_id, @owner, %{}), "transition")
    assert [%{"reason" => "unresolved_value"}] = result.residuals_by_source_id[@owner]
  end

  test "preserves existing local resolver selection and scope for transition references" do
    nearest =
      run(
        ".owner { --duration: 250ms; --timing: ease-in-out; }\n" <>
          ".owner .child { --duration: 500ms; " <>
          "transition: opacity var(--duration) var(--timing); }"
      )

    assert %StyleValue{kind: :literal, value: "opacity 500ms ease-in-out"} =
             nearest.styles_by_source_id[@child]["transition"]

    ambiguous_css =
      ".owner { --duration: 250ms; --timing: ease-in-out; }\n" <>
        ".owner.child { --duration: 250ms; --timing: ease-in-out; }\n" <>
        ".owner { transition: opacity var(--duration) var(--timing); }"

    ambiguous =
      run_sources(
        [{ambiguous_css, "_cssCustom", :base}],
        owner_classes: ["owner", "child"]
      )

    refute Map.has_key?(Map.get(ambiguous.styles_by_source_id, @owner, %{}), "transition")
    assert [%{"reason" => "unresolved_value"}] = ambiguous.residuals_by_source_id[@owner]
  end

  test "keeps a transition timing-slot mismatch fail closed" do
    result =
      run(
        transition_css(
          "--duration: 250ms; --timing: linear;",
          "opacity var(--duration) var(--timing)"
        )
      )

    refute Map.has_key?(Map.get(result.styles_by_source_id, @owner, %{}), "transition")
    assert [%{"reason" => "unresolved_value"}] = result.residuals_by_source_id[@owner]
  end

  test "keeps a transition duration-slot mismatch fail closed" do
    result =
      run(
        transition_css(
          "--duration: 250; --timing: ease-in-out;",
          "opacity var(--duration) var(--timing)"
        )
      )

    refute Map.has_key?(Map.get(result.styles_by_source_id, @owner, %{}), "transition")
    assert [%{"reason" => "unresolved_value"}] = result.residuals_by_source_id[@owner]
  end

  test "fails closed when any two-spec transition reference is missing or invalid" do
    expression =
      "opacity var(--duration-a) var(--timing-a), transform var(--duration-b) var(--timing-b)"

    definitions = %{
      "--duration-a" => "250ms",
      "--timing-a" => "ease-in-out",
      "--duration-b" => "1.5s",
      "--timing-b" => "ease-in-out"
    }

    for local_name <- Map.keys(definitions) do
      missing_definitions =
        definitions
        |> Map.delete(local_name)
        |> Enum.map_join(" ", fn {name, value} -> "#{name}: #{value};" end)

      missing = run(transition_css(missing_definitions, expression))
      refute Map.has_key?(Map.get(missing.styles_by_source_id, @owner, %{}), "transition")
      assert [%{"reason" => "unresolved_value"}] = missing.residuals_by_source_id[@owner]

      invalid_terminal =
        if String.starts_with?(local_name, "--duration"), do: "250", else: "linear"

      invalid_definitions =
        definitions
        |> Map.put(local_name, invalid_terminal)
        |> Enum.map_join(" ", fn {name, value} -> "#{name}: #{value};" end)

      invalid = run(transition_css(invalid_definitions, expression))
      refute Map.has_key?(Map.get(invalid.styles_by_source_id, @owner, %{}), "transition")
      assert [%{"reason" => "unresolved_value"}] = invalid.residuals_by_source_id[@owner]
    end
  end

  test "keeps an unsafe sibling declaration atomic with a transition declaration" do
    result =
      run(
        ".owner { --duration: 250ms; --timing: ease-in-out; " <>
          "transition: opacity var(--duration) var(--timing); " <>
          "background: url(https://example.test/image.png); }"
      )

    assert [%{"reason" => "unsafe_declaration"}] = result.residuals_by_source_id[@owner]
    refute Map.has_key?(Map.get(result.styles_by_source_id, @owner, %{}), "transition")
    refute Map.has_key?(Map.get(result.styles_by_source_id, @owner, %{}), "background")
  end

  test "reconstructs transition values deterministically for multiple target nodes" do
    nodes = %{
      @owner => node(@owner, ["owner"], [1]),
      "first-item" => node("first-item", ["item"], [1, 1], parent_id: @owner),
      "second-item" => node("second-item", ["item"], [1, 2], parent_id: @owner)
    }

    result =
      normalize_tree(
        ".owner { --duration: 250ms; --timing: ease-in-out; }\n" <>
          ".owner .item { transition: opacity var(--duration) var(--timing); }",
        nodes,
        %{@owner => ["first-item", "second-item"]}
      )

    for source_id <- ["first-item", "second-item"] do
      assert %StyleValue{kind: :literal, value: "opacity 250ms ease-in-out"} =
               result.styles_by_source_id[source_id]["transition"]
    end
  end

  test "preserves base and responsive provenance for transition resolution" do
    source_key = "_cssCustom:mobile_portrait"

    result =
      run_sources(
        [
          {".owner { --duration: 250ms; --timing: ease-in-out; " <>
             "transition: opacity var(--duration) var(--timing); }", "_cssCustom", :base},
          {".owner .child { transition: transform var(--duration) var(--timing); }", source_key,
           {:responsive_source_key, source_key}}
        ],
        owner_responsive: %{
          "mobile_portrait" => responsive_custom_css_override(source_key)
        }
      )

    assert %StyleValue{kind: :literal, value: "opacity 250ms ease-in-out"} =
             result.styles_by_source_id[@owner]["transition"]

    assert %StyleValue{kind: :literal, value: "transform 250ms ease-in-out"} =
             result.responsive_by_source_id[@child]["mobile_portrait"].styles["transition"]
  end

  test "shares the owner reference budget across direct and four-reference transition values" do
    definitions =
      "--color: red; --duration-a: 250ms; --timing-a: ease-in-out; " <>
        "--duration-b: 1.5s; --timing-b: ease-in-out;"

    css =
      ".owner { #{definitions} color: var(--color); background-color: var(--color); " <>
        "border-color: var(--color); outline-color: var(--color); }\n" <>
        ".owner .child { transition: opacity var(--duration-a) var(--timing-a), " <>
        "transform var(--duration-b) var(--timing-b); }"

    {nodes_at_limit, children_at_limit} = wide_tree(255)
    at_limit = normalize_tree(css, nodes_at_limit, children_at_limit)

    assert %StyleValue{
             kind: :literal,
             value: "opacity 250ms ease-in-out, transform 1.5s ease-in-out"
           } =
             at_limit.styles_by_source_id["child-1"]["transition"]

    for property <- ["color", "background-color", "border-color", "outline-color"] do
      assert %StyleValue{kind: :literal, value: "red"} =
               at_limit.styles_by_source_id[@owner][property]
    end

    assert Enum.all?(at_limit.residuals_by_source_id, fn {_source_id, residuals} ->
             residuals == []
           end)

    {nodes_over_limit, children_over_limit} = wide_tree(256)
    over_limit = normalize_tree(css, nodes_over_limit, children_over_limit)

    assert over_limit.styles_by_source_id == %{}

    assert Enum.any?(over_limit.residuals_by_source_id, fn {_source_id, residuals} ->
             Enum.any?(residuals, &(&1["reason"] == "resource_limit_exceeded"))
           end)
  end

  test "keeps transition failures within existing public residual reasons" do
    malformed =
      run(
        transition_css(
          "--duration: 250ms; --timing: ease-in-out;",
          "opacity var(--duration) var(--timing) extra"
        )
      )

    unresolved =
      run(
        transition_css(
          "--timing: ease-in-out;",
          "opacity var(--duration) var(--timing)"
        )
      )

    assert [%{"reason" => "unresolved_value"}] = malformed.residuals_by_source_id[@owner]
    assert [%{"reason" => "unresolved_value"}] = unresolved.residuals_by_source_id[@owner]
  end

  test "keeps fallback and missing downstream definitions fail closed" do
    for definitions <- [
          "--a: var(--b, 4px);",
          "--a: var(--missing);"
        ] do
      result = run(".owner { #{definitions} color: var(--a); }")

      assert result.styles_by_source_id == %{}
      assert [%{"reason" => "unresolved_value"}] = result.residuals_by_source_id[@owner]
    end
  end

  test "applies consumer declaration safety to a one-hop terminal" do
    result =
      run(".owner { --b: url(https://example.test/a.png); --a: var(--b); color: var(--a); }")

    assert result.styles_by_source_id == %{}
    assert [%{"reason" => "unsafe_declaration"}] = result.residuals_by_source_id[@owner]
  end

  test "does not use external authority to rescue a failed local chain" do
    authority_index = %VariableAuthority{by_variable: %{"--b" => %{}, "--c" => %{}}}

    result =
      run(
        ".owner { --c: 12px; --b: var(--c); --a: var(--b); color: var(--a); }",
        opts: [authority_index: authority_index]
      )

    assert result.styles_by_source_id == %{}
    assert [%{"reason" => "unresolved_value"}] = result.residuals_by_source_id[@owner]
  end

  test "applies the same passthrough syntax across synthetic source metadata" do
    cases = [
      {"owner-a", "owner-a", "color", "component-a", "fingerprint-a", :unknown},
      {"owner-b", "owner-b", "width", "component-b", "fingerprint-b", :required}
    ]

    for {source_id, class_name, property, component_id, fingerprint, classification} <- cases do
      css = ".#{class_name} { --b: 12px; --a: var(--b); #{property}: var(--a); }"

      source_owner =
        owner(css, source_id: source_id)
        |> Map.put(:component_id, component_id)
        |> Map.put(:residual_fingerprint, fingerprint)
        |> Map.put(:requirement_classification, classification)

      nodes = %{source_id => node(source_id, [class_name], [1])}

      result = CustomCssNormalizer.normalize([source_owner], nodes, %{}, MapSet.new())

      assert %StyleValue{kind: :literal, value: "12px"} =
               result.styles_by_source_id[source_id][property]

      assert result.residuals_by_source_id[source_id] == []
    end
  end
end
