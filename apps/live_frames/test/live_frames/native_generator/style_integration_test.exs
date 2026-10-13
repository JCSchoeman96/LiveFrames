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
    {:ok, fingerprint} = ComponentizationPlan.design_document_sha256(document)

    plan = %ComponentizationPlan{
      contract_id: contract.contract_id,
      design_document_sha256: fingerprint,
      boundary_node_id: DesignNode.deterministic_id([1]),
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
