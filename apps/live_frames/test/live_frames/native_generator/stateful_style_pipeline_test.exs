defmodule LiveFrames.NativeGenerator.StatefulStylePipelineTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.IR
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.ResponsiveOverride
  alias LiveFrames.IR.StyleValue
  alias LiveFrames.NativeGenerator
  alias LiveFrames.NativeGenerator.NodeStyleIdentity
  alias LiveFrames.NativeGenerator.Renderer
  alias LiveFrames.Tokens.TokenSet

  @component_id "component-stateful-proof"
  @owner_class_id "class-owner-shared"
  @target_class_id "class-target-shared"
  @transient_token "synthetic-active"

  @shared_css """
  .synthetic-owner .synthetic-target {
    color: red;
  }

  @media (min-width: 640px) and (max-width: 960px) {
    .synthetic-owner .synthetic-target {
      display: block;
    }
  }

  .synthetic-owner.synthetic-active .synthetic-target {
    opacity: 1;
  }

  .synthetic-owner:focus-within .synthetic-target {
    visibility: visible;
  }

  .synthetic-owner > .synthetic-target {
    margin-left: 12345px;
  }
  """

  test "keeps shared stateful styles owner-scoped through native generation" do
    source = synthetic_source()
    original_source = source

    assert {:ok, document_a} =
             Bricks.to_ir(source,
               component_id: @component_id,
               token_set: TokenSet.new()
             )

    assert {:ok, document_b} =
             Bricks.to_ir(source,
               component_id: @component_id,
               token_set: TokenSet.new()
             )

    assert source == original_source

    ir_bytes_a = IR.encode!(document_a)
    ir_bytes_b = IR.encode!(document_b)
    assert ir_bytes_a == ir_bytes_b

    root = node_by_source_id(document_a, "root")
    owner_a = node_by_source_id(document_a, "owner-a")
    owner_b = node_by_source_id(document_a, "owner-b")
    target_a = node_by_source_id(document_a, "target-a")
    target_b = node_by_source_id(document_a, "target-b")

    assert %DesignNode{} = root
    assert %DesignNode{} = owner_a
    assert %DesignNode{} = owner_b
    assert %DesignNode{} = target_a
    assert %DesignNode{} = target_b

    [owner_class] = Enum.filter(source["globalClasses"], &(&1["id"] == @owner_class_id))

    assert MapSet.new(Map.keys(owner_class["settings"])) ==
             MapSet.new(["_cssCustom", "_interactions"])

    assert owner_class["settings"]["_cssCustom"] == @shared_css
    assert owner_class["settings"]["_interactions"] == transient_interactions()

    assert get_in(owner_a.source_trace.metadata, ["class_ids"]) == [@owner_class_id]
    assert get_in(owner_b.source_trace.metadata, ["class_ids"]) == [@owner_class_id]
    assert get_in(target_a.source_trace.metadata, ["class_ids"]) == [@target_class_id]
    assert get_in(target_b.source_trace.metadata, ["class_ids"]) == [@target_class_id]

    assert Enum.map(root.children, & &1.source_trace.source_id) == ["owner-a", "owner-b"]
    assert Enum.map(owner_a.children, & &1.source_trace.source_id) == ["target-a"]
    assert Enum.map(owner_b.children, & &1.source_trace.source_id) == ["target-b"]

    effective_owner_a = get_in(owner_a.source_trace.metadata, ["effective_settings"])
    effective_owner_b = get_in(owner_b.source_trace.metadata, ["effective_settings"])
    assert effective_owner_a["_cssCustom"] == @shared_css
    assert effective_owner_b["_cssCustom"] == @shared_css
    assert effective_owner_a["_interactions"] == transient_interactions()
    assert effective_owner_b["_interactions"] == transient_interactions()

    node_ids = Enum.map([root, owner_a, owner_b, target_a, target_b], & &1.node_id)
    assert length(node_ids) == length(Enum.uniq(node_ids))

    assert %StyleValue{kind: :literal, value: "red"} = target_a.styles["color"]
    assert %StyleValue{kind: :literal, value: "red"} = target_b.styles["color"]
    refute Map.has_key?(owner_a.styles, "color")
    refute Map.has_key?(owner_b.styles, "color")

    responsive_a = target_a.responsive["custom_range_640_960"]
    responsive_b = target_b.responsive["custom_range_640_960"]

    assert %ResponsiveOverride{
             min_width: 640.0,
             max_width: 960.0,
             resolution_status: :resolved,
             styles: %{"display" => %StyleValue{kind: :keyword, value: "block"}}
           } = responsive_a

    assert %ResponsiveOverride{
             min_width: 640.0,
             max_width: 960.0,
             resolution_status: :resolved,
             styles: %{"display" => %StyleValue{kind: :keyword, value: "block"}}
           } = responsive_b

    assert {responsive_a.min_width, responsive_a.max_width, responsive_a.resolution_status,
            responsive_semantics(responsive_a.styles)} ==
             {responsive_b.min_width, responsive_b.max_width, responsive_b.resolution_status,
              responsive_semantics(responsive_b.styles)}

    {owner_a_rules, owner_a_residuals} = state_style!(owner_a)
    {owner_b_rules, owner_b_residuals} = state_style!(owner_b)

    hover_a = rule_for!(owner_a_rules, "hover")
    focus_a = rule_for!(owner_a_rules, "focus_within")
    hover_b = rule_for!(owner_b_rules, "hover")
    focus_b = rule_for!(owner_b_rules, "focus_within")

    assert hover_a["target_node_id"] == target_a.node_id
    assert focus_a["target_node_id"] == target_a.node_id
    assert hover_b["target_node_id"] == target_b.node_id
    assert focus_b["target_node_id"] == target_b.node_id

    refute Enum.any?(owner_a_rules, &(&1["target_node_id"] == target_b.node_id))
    refute Enum.any?(owner_b_rules, &(&1["target_node_id"] == target_a.node_id))

    executable_rules =
      Enum.flat_map([owner_a_rules, owner_b_rules], fn rules ->
        Enum.map(rules, fn rule ->
          Map.take(rule, ["condition", "target_node_id", "declarations", "viewport", "order"])
        end)
      end)

    refute inspect(executable_rules) =~ @transient_token

    owner_a_unsupported = residual_for!(owner_a_residuals, "unsupported_selector")
    owner_b_unsupported = residual_for!(owner_b_residuals, "unsupported_selector")
    assert owner_a_unsupported["source_text"] =~ "12345px"
    assert owner_b_unsupported["source_text"] =~ "12345px"

    contract = %ComponentContract{
      contract_id: "stateful-style-proof",
      category: :section,
      module_intent: "stateful_style_proof",
      function_intent: "fixture",
      approval_status: :approved
    }

    assert {:ok, digest_a} = ComponentizationPlan.design_document_sha256(document_a)
    assert {:ok, digest_b} = ComponentizationPlan.design_document_sha256(document_b)

    plan_a = %ComponentizationPlan{
      contract_id: contract.contract_id,
      design_document_sha256: digest_a,
      boundary_node_id: root.node_id
    }

    plan_b = %ComponentizationPlan{
      contract_id: contract.contract_id,
      design_document_sha256: digest_b,
      boundary_node_id: node_by_source_id(document_b, "root").node_id
    }

    assert {:ok, bundle_a} = NativeGenerator.generate(contract, plan_a, document_a)
    assert {:ok, bundle_b} = NativeGenerator.generate(contract, plan_b, document_b)

    assert Enum.map(bundle_a.artifacts, & &1.kind) == [:stylesheet, :elixir_module]
    assert Enum.map(bundle_b.artifacts, & &1.kind) == [:stylesheet, :elixir_module]

    stylesheet_a = artifact_content!(bundle_a, :stylesheet)
    stylesheet_b = artifact_content!(bundle_b, :stylesheet)
    module_a = artifact_content!(bundle_a, :elixir_module)
    module_b = artifact_content!(bundle_b, :elixir_module)

    assert stylesheet_a == stylesheet_b
    assert module_a == module_b

    assert {:ok, identity} =
             NodeStyleIdentity.build(document_a, Renderer.package_root_class(contract))

    owner_a_private = identity.private_class_by_id[owner_a.node_id]
    owner_b_private = identity.private_class_by_id[owner_b.node_id]
    target_a_private = identity.private_class_by_id[target_a.node_id]
    target_b_private = identity.private_class_by_id[target_b.node_id]

    assert length(
             Enum.uniq([owner_a_private, owner_b_private, target_a_private, target_b_private])
           ) ==
             4

    assert stylesheet_a =~ ".#{owner_a_private}:hover .#{target_a_private} {"
    assert stylesheet_a =~ ".#{owner_a_private}:focus-within .#{target_a_private} {"
    assert stylesheet_a =~ ".#{owner_b_private}:hover .#{target_b_private} {"
    assert stylesheet_a =~ ".#{owner_b_private}:focus-within .#{target_b_private} {"

    refute stylesheet_a =~ ".#{owner_a_private}:hover .#{target_b_private} {"
    refute stylesheet_a =~ ".#{owner_a_private}:focus-within .#{target_b_private} {"
    refute stylesheet_a =~ ".#{owner_b_private}:hover .#{target_a_private} {"
    refute stylesheet_a =~ ".#{owner_b_private}:focus-within .#{target_a_private} {"

    media_query = "@media (min-width: 640px) and (max-width: 960px)"
    assert stylesheet_a =~ "#{media_query} {\n  .#{target_a_private} {\n    display: block;"
    assert stylesheet_a =~ "#{media_query} {\n  .#{target_b_private} {\n    display: block;"

    refute stylesheet_a =~ "synthetic-owner"
    refute stylesheet_a =~ "synthetic-target"
    refute stylesheet_a =~ @transient_token
    refute module_a =~ "synthetic-owner"
    refute module_a =~ "synthetic-target"
    refute module_a =~ @transient_token
    refute module_a =~ "mouseenter"
    refute module_a =~ "mouseleave"
    refute stylesheet_a =~ ".synthetic-owner > .synthetic-target"
    refute module_a =~ ".synthetic-owner > .synthetic-target"
    refute stylesheet_a =~ "12345px"
    refute module_a =~ "12345px"
  end

  defp synthetic_source do
    %{
      "source" => "bricksCopiedElements",
      "sourceUrl" => "https://example.test/stateful-style-proof.json",
      "version" => "2.3.1",
      "content" => [
        %{"id" => "proof-proxy", "cid" => @component_id, "label" => "Synthetic proof"}
      ],
      "components" => [
        %{
          "id" => @component_id,
          "elements" => [
            source_element("root", "section", 0, ["owner-a", "owner-b"], %{}),
            source_element("owner-a", "div", "root", ["target-a"], %{
              "_cssGlobalClasses" => [@owner_class_id]
            }),
            source_element("target-a", "div", "owner-a", [], %{
              "_cssGlobalClasses" => [@target_class_id]
            }),
            source_element("owner-b", "div", "root", ["target-b"], %{
              "_cssGlobalClasses" => [@owner_class_id]
            }),
            source_element("target-b", "div", "owner-b", [], %{
              "_cssGlobalClasses" => [@target_class_id]
            })
          ]
        }
      ],
      "globalClasses" => [
        %{
          "id" => @owner_class_id,
          "name" => "synthetic-owner",
          "settings" => %{
            "_cssCustom" => @shared_css,
            "_interactions" => transient_interactions()
          }
        },
        %{
          "id" => @target_class_id,
          "name" => "synthetic-target",
          "settings" => %{}
        }
      ]
    }
  end

  defp source_element(id, name, parent, children, settings) do
    %{
      "id" => id,
      "name" => name,
      "parent" => parent,
      "children" => children,
      "settings" => settings
    }
  end

  defp transient_interactions do
    [
      %{
        "id" => "enter",
        "trigger" => "mouseenter",
        "action" => "setAttribute",
        "actionAttributeKey" => "class",
        "actionAttributeValue" => @transient_token
      },
      %{
        "id" => "leave",
        "trigger" => "mouseleave",
        "action" => "removeAttribute",
        "actionAttributeKey" => "class",
        "actionAttributeValue" => @transient_token
      }
    ]
  end

  defp node_by_source_id(document, source_id) do
    document.root_nodes
    |> flatten_nodes()
    |> Enum.find(&(&1.source_trace.source_id == source_id))
  end

  defp flatten_nodes(nodes) do
    Enum.flat_map(nodes, fn node -> [node | flatten_nodes(node.children)] end)
  end

  defp state_style!(node) do
    assert %StyleValue{
             kind: :complex_css,
             value: %{"type" => "state_rules", "rules" => rules, "residual" => residuals}
           } = node.styles["custom-css"]

    {rules, residuals}
  end

  defp rule_for!(rules, condition) do
    rule = Enum.find(rules, &(&1["condition"] == condition))
    assert is_map(rule)
    rule
  end

  defp residual_for!(residuals, reason) do
    residual = Enum.find(residuals, &(&1["reason"] == reason))
    assert is_map(residual)
    assert residual["reason"] == reason
    residual
  end

  defp responsive_semantics(styles) do
    Map.new(styles, fn {property, %StyleValue{kind: kind, value: value}} ->
      {property, {kind, value}}
    end)
  end

  defp artifact_content!(bundle, kind) do
    case Enum.find(bundle.artifacts, &(&1.kind == kind)) do
      %{content: content} -> content
      nil -> flunk("expected a #{kind} artifact")
    end
  end
end
