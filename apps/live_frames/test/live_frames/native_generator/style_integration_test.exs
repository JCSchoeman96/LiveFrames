defmodule LiveFrames.NativeGenerator.StyleIntegrationTest do
  use ExUnit.Case, async: true

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.RenderProjection
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.ResponsiveOverride
  alias LiveFrames.IR.StyleValue
  alias LiveFrames.NativeGenerator
  alias LiveFrames.NativeGenerator.StyleIntegration

  defp contract(category \\ :section, attrs \\ []) do
    %ComponentContract{
      contract_id: "style-contract",
      category: category,
      module_intent: "style_fixture",
      function_intent: "render",
      approval_status: :approved,
      public_attrs: attrs
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

  test "all dynamic heading alternatives reuse the node's private class" do
    heading = %DesignNode{
      node_id: DesignNode.deterministic_id([1, 1]),
      semantic_type: "heading",
      styles: %{"color" => StyleValue.keyword("navy")}
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
    class = "lf-section-style-fixture__n-000001-000001"

    assert length(String.split(module.content, class)) == 7
  end
end
