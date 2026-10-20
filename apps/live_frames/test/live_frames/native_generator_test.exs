defmodule LiveFrames.NativeGeneratorTest do
  use ExUnit.Case, async: true

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentReview
  alias LiveFrames.ComponentReviewResult
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentContract.CollectionInput
  alias LiveFrames.ComponentContract.Diagnostic, as: ContractDiagnostic
  alias LiveFrames.ComponentContract.ItemField
  alias LiveFrames.ComponentContract.Slot
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.Diagnostic, as: PlanDiagnostic
  alias LiveFrames.ComponentizationPlan.RenderProjection
  alias LiveFrames.IR.CollectionBinding
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.StyleValue
  alias LiveFrames.IR.Identity
  alias LiveFrames.IR.SourceTrace
  alias LiveFrames.IR.ValueBinding
  alias LiveFrames.IR
  alias LiveFrames.NativeGenerator
  alias LiveFrames.NativeGenerator.Renderer
  alias LiveFrames.Behavior.Binding, as: BehaviorBinding
  alias LiveFrames.Behavior.Binding.PrimitiveRef
  alias LiveFrames.Behavior.BindingIdentity
  alias LiveFrames.Behavior.Contract, as: BehaviorContract
  alias LiveFrames.Behavior.ReviewResult, as: BehaviorReviewResult
  alias LiveFrames.Behavior.Serializer, as: BehaviorSerializer
  alias LiveFrames.ComponentizationPlan.NodeDisposition

  @boundary_id DesignNode.deterministic_id([1])
  @heading_id DesignNode.deterministic_id([1, 1])
  @paragraph_id DesignNode.deterministic_id([1, 2])
  @link_id DesignNode.deterministic_id([1, 3])
  @actions_id DesignNode.deterministic_id([1, 4])

  defp document(overrides \\ []) do
    roots = [
      %DesignNode{
        node_id: @boundary_id,
        semantic_type: "section",
        children: [
          %DesignNode{
            node_id: @heading_id,
            semantic_type: "heading",
            attributes: %{"tag" => "h2"},
            content: "Static heading"
          },
          %DesignNode{
            node_id: @paragraph_id,
            semantic_type: "paragraph",
            content: "Static body"
          }
        ]
      }
    ]

    struct!(%DesignDocument{root_nodes: roots}, overrides)
  end

  defp rich_document(overrides \\ []) do
    %DesignNode{} = boundary = hd(document().root_nodes)

    roots = [
      %DesignNode{
        boundary
        | children:
            boundary.children ++
              [
                %DesignNode{node_id: @link_id, semantic_type: "link"},
                %DesignNode{node_id: @actions_id, semantic_type: "actions"}
              ]
      }
    ]

    struct!(%DesignDocument{root_nodes: roots}, overrides)
  end

  defp contract(overrides \\ []) do
    struct!(
      %ComponentContract{
        contract_id: "hero-contract",
        category: :section,
        module_intent: "marketing_block",
        function_intent: "hero",
        approval_status: :approved
      },
      overrides
    )
  end

  defp plan(component_contract, design_document, overrides \\ []) do
    {:ok, fingerprint} = ComponentizationPlan.design_document_sha256(design_document)

    struct!(
      %ComponentizationPlan{
        contract_id: component_contract.contract_id,
        design_document_sha256: fingerprint,
        boundary_node_id: @boundary_id
      },
      overrides
    )
  end

  defp attr(name, type \\ :string, options \\ []) do
    struct!(%Attr{name: name, type: type, semantic_purpose: name}, options)
  end

  defp render_attr(name, role, target \\ @heading_id) do
    %RenderProjection{public_attr_name: name, render_role: role, target_node_id: target}
  end

  defp generate!(contract, plan, document) do
    case NativeGenerator.generate(contract, plan, document) do
      {:ok, bundle} -> bundle
      other -> flunk("expected success, got #{inspect(other)}")
    end
  end

  defp elixir_artifact(bundle), do: Enum.find(bundle.artifacts, &(&1.kind == :elixir_module))

  defp disposition_authority do
    target_id = DesignNode.deterministic_id([1, 3])
    source_type = "synthetic-builder"
    source_id = "synthetic-node-42"

    design_document = %DesignDocument{
      root_nodes: [
        %DesignNode{
          node_id: @boundary_id,
          semantic_type: "section",
          children: [
            %DesignNode{
              node_id: @heading_id,
              semantic_type: "heading",
              attributes: %{"tag" => "h2"},
              content: "Static heading"
            },
            %DesignNode{
              node_id: @paragraph_id,
              semantic_type: "paragraph",
              content: "Static body"
            },
            %DesignNode{
              node_id: target_id,
              semantic_type: "raw",
              source_trace: %SourceTrace{source_type: source_type, source_id: source_id}
            }
          ]
        }
      ]
    }

    component_contract = contract(approval_status: :proposed)
    {:ok, identity} = Identity.from_document(design_document)

    binding = %BehaviorBinding{
      primitive_ref: %PrimitiveRef{kind: "synthetic-task7", definition_version: "1.0.0"},
      owner_node_id: @boundary_id,
      binding_role: "task7-authority-fixture"
    }

    {:ok, behavior_contract} =
      BindingIdentity.assign(%BehaviorContract{
        design_document_identity: identity,
        bindings: [binding]
      })

    {:ok, behavior_digest} = BehaviorSerializer.digest(behavior_contract)

    behavior_review_result = %BehaviorReviewResult{
      review_format_version: "1.0.0",
      design_document_identity: identity,
      behavior_contract_digest_algorithm: BehaviorSerializer.algorithm(),
      behavior_contract_digest: behavior_digest,
      decision: "approved",
      reviewer_identity: "reviewer:task7-test",
      reviewed_at: "2026-10-20T00:00:00.000000Z",
      review_note: nil,
      evidence_refs: ["synthetic-behavior-evidence"]
    }

    {:ok, behavior_review_id} = BehaviorReviewResult.id(behavior_review_result)
    behavior_binding = hd(behavior_contract.bindings)

    plan =
      plan(component_contract, design_document,
        node_dispositions: [
          %NodeDisposition{
            design_node_id: target_id,
            disposition: :exclude_source_runtime_carrier,
            source_type: source_type,
            source_id: source_id,
            behavior_binding_id: behavior_binding.binding_id,
            behavior_contract_digest: behavior_digest,
            behavior_review_id: behavior_review_id,
            evidence_refs: ["synthetic-disposition-evidence"]
          }
        ],
        diagnostics: []
      )

    {:ok, approved_contract, component_review_result} =
      ComponentReview.approve_with_result(
        component_contract,
        plan,
        design_document,
        behavior_contract,
        behavior_review_result,
        "reviewer:task7-test",
        "2026-10-20T00:00:00.000000Z",
        ["synthetic-component-evidence"]
      )

    {:ok, component_review_result_id} = ComponentReviewResult.id(component_review_result)

    {approved_contract, plan, design_document, behavior_contract, behavior_review_result,
     component_review_result, component_review_result_id}
  end

  defp refresh_behavior_authority(
         {contract, plan, document, behavior_contract, behavior_review, component_review,
          review_id},
         bindings
       ) do
    {:ok, identity} = Identity.from_document(document)

    bindings = Enum.map(bindings, &%{&1 | binding_id: nil, ordinal: nil})

    {:ok, behavior_contract} =
      BindingIdentity.assign(%{
        behavior_contract
        | design_document_identity: identity,
          bindings: bindings
      })

    {:ok, behavior_digest} = BehaviorSerializer.digest(behavior_contract)

    behavior_review = %{
      behavior_review
      | design_document_identity: identity,
        behavior_contract_digest: behavior_digest
    }

    {:ok, behavior_review_id} = BehaviorReviewResult.id(behavior_review)
    [disposition] = plan.node_dispositions

    disposition = %{
      disposition
      | behavior_contract_digest: behavior_digest,
        behavior_review_id: behavior_review_id
    }

    disposition =
      case behavior_contract.bindings do
        [binding | _] -> %{disposition | behavior_binding_id: binding.binding_id}
        [] -> disposition
      end

    {contract, %{plan | node_dispositions: [disposition]}, document, behavior_contract,
     behavior_review, component_review, review_id}
  end

  test "generate/3 requires explicit authority for disposition-bearing plans" do
    {approved_contract, plan, design_document, _behavior_contract, _behavior_review_result,
     _component_review_result, _component_review_result_id} = disposition_authority()

    assert {:error, :generation_blocked, diagnostics} =
             NativeGenerator.generate(approved_contract, plan, design_document)

    assert Enum.map(diagnostics, & &1.code) == ["native_generator.disposition_authority_required"]
  end

  test "generate/7 accepts the selected exact review authority before entering generation" do
    {approved_contract, plan, design_document, behavior_contract, behavior_review_result,
     component_review_result, component_review_result_id} = disposition_authority()

    assert ComponentReviewResult.id(component_review_result) == {:ok, component_review_result_id}

    assert :ok ==
             ComponentReviewResult.validate_against(
               component_review_result,
               approved_contract,
               plan,
               design_document
             )

    assert :ok ==
             ComponentizationPlan.validate_for_generation_with_behavior_authority(
               plan,
               approved_contract,
               design_document,
               behavior_contract,
               behavior_review_result
             )

    result =
      NativeGenerator.generate(
        approved_contract,
        plan,
        design_document,
        behavior_contract,
        behavior_review_result,
        component_review_result,
        component_review_result_id
      )

    assert {:error, :generation_failed, [diagnostic]} = result
    assert diagnostic.code == "native_generator.semantic_unsupported"
  end

  test "ordinary generate/3 still generates plans without dispositions" do
    document = document()
    c = contract()
    p = plan(c, document)

    assert {:ok, %{artifacts: [_module, _stylesheet]}} = NativeGenerator.generate(c, p, document)
  end

  test "generate/7 blocks when Behavior authority is missing or mismatched" do
    tuple = disposition_authority()

    {contract, plan, document, behavior_contract, behavior_review, component_review, review_id} =
      tuple

    other_document = %{document | provenance: %{"source" => "different-document"}}
    {:ok, other_identity} = Identity.from_document(other_document)

    {:ok, wrong_document_contract} =
      BindingIdentity.assign(%{
        behavior_contract
        | design_document_identity: other_identity,
          bindings: Enum.map(behavior_contract.bindings, &%{&1 | binding_id: nil, ordinal: nil})
      })

    cases = [
      {behavior_contract, nil},
      {nil, behavior_review},
      {%BehaviorContract{}, behavior_review},
      {wrong_document_contract, behavior_review},
      {behavior_contract, %{behavior_review | decision: "needs_review"}},
      {behavior_contract, %{behavior_review | reviewer_identity: "reviewer:changed"}},
      {behavior_contract, %{behavior_review | design_document_identity: nil}},
      {behavior_contract,
       %{behavior_review | behavior_contract_digest: String.duplicate("0", 64)}}
    ]

    for {changed_contract, changed_review} <- cases do
      assert {:error, expected_diagnostics} =
               ComponentizationPlan.validate_for_generation_with_behavior_authority(
                 plan,
                 contract,
                 document,
                 changed_contract,
                 changed_review
               )

      assert {:error, :generation_blocked, ^expected_diagnostics} =
               NativeGenerator.generate(
                 contract,
                 plan,
                 document,
                 changed_contract,
                 changed_review,
                 component_review,
                 review_id
               )
    end
  end

  test "generate/7 blocks a stale NodeDisposition Behavior digest" do
    {contract, plan, document, behavior_contract, behavior_review, component_review, review_id} =
      disposition_authority()

    [disposition] = plan.node_dispositions

    stale_plan = %{
      plan
      | node_dispositions: [%{disposition | behavior_contract_digest: String.duplicate("0", 64)}]
    }

    assert {:error, :generation_blocked, [_ | _]} =
             NativeGenerator.generate(
               contract,
               stale_plan,
               document,
               behavior_contract,
               behavior_review,
               component_review,
               review_id
             )
  end

  test "generate/7 blocks a selected BehaviorReviewResult that is not approved" do
    tuple = disposition_authority()

    {_contract, _plan, _document, behavior_contract, behavior_review, _component_review,
     _review_id} =
      tuple

    changed_review = %{behavior_review | decision: "needs_review"}

    {contract, plan, document, behavior_contract, changed_review, component_review, review_id} =
      refresh_behavior_authority(put_elem(tuple, 4, changed_review), behavior_contract.bindings)

    assert {:error, expected_diagnostics} =
             ComponentizationPlan.validate_for_generation_with_behavior_authority(
               plan,
               contract,
               document,
               behavior_contract,
               changed_review
             )

    assert {:error, :generation_blocked, ^expected_diagnostics} =
             NativeGenerator.generate(
               contract,
               plan,
               document,
               behavior_contract,
               changed_review,
               component_review,
               review_id
             )
  end

  test "generate/7 reuses Task 5 diagnostics for Behavior reference conflicts and missing bindings" do
    tuple = disposition_authority()

    {_contract, plan, _document, behavior_contract, _behavior_review, _component_review,
     _review_id} =
      tuple

    [binding] = behavior_contract.bindings
    target_id = hd(plan.node_dispositions).design_node_id
    conflicting_binding = %{binding | owner_node_id: target_id}
    conflicting = refresh_behavior_authority(tuple, [conflicting_binding])
    missing_binding = refresh_behavior_authority(tuple, [])

    for {authority, expected_code} <- [
          {conflicting, "componentization_plan.node_disposition.behavior_reference_conflict"},
          {missing_binding, "componentization_plan.node_disposition.behavior_binding_mismatch"}
        ] do
      {changed_contract, changed_plan, changed_document, changed_behavior, changed_review,
       changed_component_review, changed_review_id} = authority

      assert {:error, upstream_diagnostics} =
               ComponentizationPlan.validate_for_generation_with_behavior_authority(
                 changed_plan,
                 changed_contract,
                 changed_document,
                 changed_behavior,
                 changed_review
               )

      assert Enum.any?(upstream_diagnostics, &(&1.code == expected_code))

      assert {:error, :generation_blocked, ^upstream_diagnostics} =
               NativeGenerator.generate(
                 changed_contract,
                 changed_plan,
                 changed_document,
                 changed_behavior,
                 changed_review,
                 changed_component_review,
                 changed_review_id
               )
    end
  end

  test "generate/7 blocks invalid selected ComponentReviewResult authority" do
    tuple = disposition_authority()

    {contract, plan, document, behavior_contract, behavior_review, component_review, review_id} =
      tuple

    changed_review = %{component_review | reviewer_identity: "reviewer:changed"}

    cases = [
      {nil, review_id},
      {:wrong_shape, review_id},
      {component_review, "crv_" <> String.duplicate("0", 64)},
      {changed_review, review_id},
      {%{component_review | decision: "needs_review"},
       review_id_for(%{component_review | decision: "needs_review"})},
      {%{component_review | decision: "rejected"},
       review_id_for(%{component_review | decision: "rejected"})},
      {%{component_review | component_contract_id: "other-contract"},
       review_id_for(%{component_review | component_contract_id: "other-contract"})}
    ]

    for {selected_review, selected_id} <- cases do
      assert {:error, :generation_blocked, [diagnostic]} =
               NativeGenerator.generate(
                 contract,
                 plan,
                 document,
                 behavior_contract,
                 behavior_review,
                 selected_review,
                 selected_id
               )

      assert diagnostic.code == "native_generator.component_review_authority_mismatch"
    end
  end

  test "generate/7 binds the exact approved contract bytes and encoded plan" do
    {contract, plan, document, behavior_contract, behavior_review, component_review, review_id} =
      disposition_authority()

    changed_contract = %{contract | module_intent: "changed_marketing_block"}
    changed_plan = %{plan | provenance: %{"task7" => "changed"}}

    for {selected_contract, selected_plan} <- [
          {changed_contract, plan},
          {contract, changed_plan}
        ] do
      assert {:error, :generation_blocked, [diagnostic]} =
               NativeGenerator.generate(
                 selected_contract,
                 selected_plan,
                 document,
                 behavior_contract,
                 behavior_review,
                 component_review,
                 review_id
               )

      assert diagnostic.code == "native_generator.component_review_authority_mismatch"
    end
  end

  test "generate/7 blocks a changed document after refreshing Task 5 Behavior identity" do
    tuple = disposition_authority()

    {contract, plan, document, behavior_contract, _behavior_review, component_review, review_id} =
      tuple

    [boundary] = document.root_nodes
    [heading | tail] = boundary.children

    changed_document = %{
      document
      | root_nodes: [%{boundary | children: [%{heading | content: "Changed"} | tail]}]
    }

    changed_plan = %{
      plan
      | design_document_sha256:
          elem(ComponentizationPlan.design_document_sha256(changed_document), 1)
    }

    fresh_behavior_tuple =
      refresh_behavior_authority(
        {contract, changed_plan, changed_document, behavior_contract, elem(tuple, 4),
         component_review, review_id},
        behavior_contract.bindings
      )

    {contract, changed_plan, changed_document, behavior_contract, behavior_review, _, _} =
      fresh_behavior_tuple

    assert :ok ==
             ComponentizationPlan.validate_for_generation_with_behavior_authority(
               changed_plan,
               contract,
               changed_document,
               behavior_contract,
               behavior_review
             )

    assert {:error, :generation_blocked, [diagnostic]} =
             NativeGenerator.generate(
               contract,
               changed_plan,
               changed_document,
               behavior_contract,
               behavior_review,
               component_review,
               review_id
             )

    assert diagnostic.code == "native_generator.component_review_authority_mismatch"
  end

  defp review_id_for(review_result) do
    {:ok, id} = ComponentReviewResult.id(review_result)
    id
  end

  test "unapproved contract returns generation_blocked" do
    document = document()
    c = contract(approval_status: :proposed)
    p = plan(c, document)

    assert {:error, :generation_blocked, diagnostics} = NativeGenerator.generate(c, p, document)

    assert Enum.any?(diagnostics, fn d ->
             match?(%ContractDiagnostic{code: "component_contract.approval_blocked"}, d) or
               match?(%PlanDiagnostic{code: "componentization_plan.generation_blocked"}, d)
           end)
  end

  test "contract and plan mismatch returns generation_blocked" do
    document = document()
    c = contract(contract_id: "a")
    p = plan(contract(contract_id: "b"), document)

    assert {:error, :generation_blocked, _} = NativeGenerator.generate(c, p, document)
  end

  test "stored contract blocker returns generation_blocked without partial artifacts" do
    document = document()

    c =
      contract(
        diagnostics: [
          %ContractDiagnostic{
            code: "component_contract.fixture.blocker",
            severity: :error,
            message: "blocked"
          }
        ]
      )

    p = plan(c, document)

    assert {:error, :generation_blocked, _} = NativeGenerator.generate(c, p, document)
  end

  test "deterministic naming path and package class for section category" do
    document = document()

    c =
      contract(
        public_attrs: [
          attr("title"),
          attr("level", :integer,
            required: true,
            validation: %{"values" => [1, 2, 3, 4, 5, 6]}
          )
        ]
      )

    p =
      plan(c, document,
        render_projections: [
          render_attr("title", :text_content),
          render_attr("level", :heading_level)
        ]
      )

    bundle = generate!(c, p, document)
    artifact = Enum.find(bundle.artifacts, &(&1.kind == :elixir_module))

    assert artifact.path == "lib/live_frames/components/sections/marketing_block.ex"
    assert artifact.content =~ "defmodule LiveFrames.Components.Sections.MarketingBlock"
    assert artifact.content =~ "def hero(assigns)"
    assert artifact.content =~ "lf-section-marketing-block"
    assert artifact.content =~ "attr(:title, :string)"
    assert artifact.content =~ "values: 1..6"
  end

  test "generated Elixir module artifact ends with a newline" do
    bundle = generate!(contract(), plan(contract(), document()), document())
    artifact = elixir_artifact(bundle)

    assert String.ends_with?(artifact.content, "\n")
  end

  for {category, prefix, path_segment, class_prefix} <- [
        {:component, "LiveFrames.Components.Demo", "lib/live_frames/components/demo.ex",
         "lf-component-demo"},
        {:pattern, "LiveFrames.Components.Patterns.Demo",
         "lib/live_frames/components/patterns/demo.ex", "lf-pattern-demo"},
        {:primitive, "LiveFrames.Components.Primitives.Demo",
         "lib/live_frames/components/primitives/demo.ex", "lf-primitive-demo"}
      ] do
    test "deterministic naming for #{category}" do
      document = document()

      c =
        contract(
          category: unquote(category),
          module_intent: "demo",
          function_intent: "demo",
          public_attrs: [attr("title")],
          public_slots: []
        )

      p =
        plan(c, document,
          render_projections: [render_attr("title", :text_content, @paragraph_id)]
        )

      bundle = generate!(c, p, document)
      artifact = Enum.find(bundle.artifacts, &(&1.kind == :elixir_module))

      assert artifact.path == unquote(path_segment)
      assert artifact.content =~ unquote("defmodule #{prefix}")
      assert artifact.content =~ unquote(class_prefix)
    end
  end

  test "generation returns sorted module and stylesheet artifacts with canonical classes" do
    document = document()
    [boundary] = document.root_nodes
    [heading, paragraph] = boundary.children

    document = %{
      document
      | root_nodes: [
          %{
            boundary
            | styles: %{"display" => StyleValue.keyword("grid")},
              children: [
                %{heading | styles: %{"color" => StyleValue.literal("red")}},
                paragraph
              ]
          }
        ]
    }

    c = contract()
    bundle = generate!(c, plan(c, document), document)
    module = elixir_artifact(bundle)
    stylesheet = Enum.find(bundle.artifacts, &(&1.kind == :stylesheet))

    assert length(bundle.artifacts) == 2
    assert Enum.map(bundle.artifacts, & &1.kind) == [:stylesheet, :elixir_module]

    assert Enum.map(bundle.artifacts, & &1.path) ==
             Enum.sort(Enum.map(bundle.artifacts, & &1.path))

    assert stylesheet.path == "assets/css/components/sections/marketing_block.css"
    assert module.content =~ "lf-section-marketing-block"
    assert module.content =~ "lf-section-marketing-block__n-000001"
    assert module.content =~ "lf-section-marketing-block__n-000001-000001"
    refute module.content =~ "lf-section-marketing-block__n-000001-000002"
    assert stylesheet.content =~ ".lf-section-marketing-block__n-000001 {"
    assert stylesheet.content =~ ".lf-section-marketing-block__n-000001-000001 {"
    refute stylesheet.content =~ "000001-000002"
  end

  test "figure image styles use the proven outer and inner native elements" do
    document = document()
    [boundary] = document.root_nodes
    image_id = DesignNode.deterministic_id([1, 3])

    document = %{
      document
      | root_nodes: [
          %{
            boundary
            | children:
                boundary.children ++
                  [
                    %DesignNode{
                      node_id: image_id,
                      semantic_type: "image",
                      attributes: %{"tag" => "figure"},
                      styles: %{
                        "width" => StyleValue.literal("100%"),
                        "height" => StyleValue.literal("100%"),
                        "aspect-ratio" => StyleValue.literal("16/9"),
                        "object-fit" => StyleValue.keyword("cover"),
                        "border-top-left-radius" => StyleValue.literal("1rem"),
                        "border-top-right-radius" => StyleValue.literal("1rem"),
                        "border-bottom-right-radius" => StyleValue.literal("1rem"),
                        "border-bottom-left-radius" => StyleValue.literal("1rem")
                      }
                    }
                  ]
          }
        ]
    }

    c =
      contract(
        public_attrs: [
          attr("src", :string,
            required: true,
            accessibility: %{"image_alt_policy" => "decorative"}
          )
        ]
      )

    p = plan(c, document, render_projections: [render_attr("src", :asset_src, image_id)])

    bundle = generate!(c, p, document)
    stylesheet = Enum.find(bundle.artifacts, &(&1.kind == :stylesheet)).content
    source = elixir_artifact(bundle).content
    private_class = "lf-section-marketing-block__n-000001-000003"

    assert stylesheet =~ ".#{private_class} {"
    assert stylesheet =~ "border-bottom-left-radius: 1rem;"
    assert stylesheet =~ "border-bottom-right-radius: 1rem;"
    assert stylesheet =~ "border-top-left-radius: 1rem;"
    assert stylesheet =~ "border-top-right-radius: 1rem;"
    assert stylesheet =~ "height: 100%;"
    assert stylesheet =~ "width: 100%;"

    assert stylesheet =~ ".#{private_class} > img {"
    assert stylesheet =~ "aspect-ratio: 16/9;"
    assert stylesheet =~ "border-radius: inherit;"
    assert stylesheet =~ "object-fit: cover;"

    assert source =~ ~s(<figure class={"#{private_class}"}>)
    assert source =~ ~s(<img src={@src} alt="" />)
    refute source =~ ~s(<img class={"#{private_class}"})
  end

  test "unlisted figure image styles remain blocked" do
    document = document()
    [boundary] = document.root_nodes
    image_id = DesignNode.deterministic_id([1, 3])

    document = %{
      document
      | root_nodes: [
          %{
            boundary
            | children:
                boundary.children ++
                  [
                    %DesignNode{
                      node_id: image_id,
                      semantic_type: "image",
                      attributes: %{"tag" => "figure"},
                      styles: %{"max-width" => StyleValue.literal("80rem")}
                    }
                  ]
          }
        ]
    }

    c =
      contract(
        public_attrs: [
          attr("src", :string,
            required: true,
            accessibility: %{"image_alt_policy" => "decorative"}
          )
        ]
      )

    p = plan(c, document, render_projections: [render_attr("src", :asset_src, image_id)])

    assert {:error, :generation_blocked, [diagnostic]} = NativeGenerator.generate(c, p, document)
    assert diagnostic.code == "native_generator.styling.style_locus_authority_gap"
  end

  test "render projections for root, link, image accessibility, and subtree slot" do
    document = rich_document()

    [boundary] = document.root_nodes

    document = %{
      document
      | root_nodes: [
          %{
            boundary
            | children:
                Enum.map(boundary.children, fn
                  %DesignNode{node_id: @actions_id} = actions ->
                    %{actions | styles: %{"display" => StyleValue.keyword("grid")}}

                  other ->
                    other
                end)
          }
        ]
    }

    assert :ok = IR.validate(document)

    c =
      contract(
        public_attrs: [
          attr("title"),
          attr("level", :integer,
            required: true,
            validation: %{"values" => [1, 2, 3, 4, 5, 6]}
          ),
          attr("href"),
          attr("id"),
          attr("class"),
          attr("rest", :global),
          attr("src", :string, accessibility: %{"image_alt_policy" => "decorative"}),
          attr("src2", :string,
            accessibility: %{
              "image_alt_policy" => "consumer_supplied",
              "alt_attr_name" => "alt",
              "required_when_source_present" => true
            }
          ),
          attr("alt")
        ],
        public_slots: [
          %Slot{name: "actions", semantic_purpose: "actions", consumer_responsibility: "caller"}
        ]
      )

    decorative_image_id = DesignNode.deterministic_id([1, 5])
    consumer_image_id = DesignNode.deterministic_id([1, 6])

    %DesignNode{} = boundary = hd(document.root_nodes)

    document = %{
      document
      | root_nodes: [
          %DesignNode{
            boundary
            | children:
                boundary.children ++
                  [
                    %DesignNode{node_id: decorative_image_id, semantic_type: "image"},
                    %DesignNode{node_id: consumer_image_id, semantic_type: "image"}
                  ]
          }
        ]
    }

    p =
      plan(c, document,
        render_projections: [
          render_attr("title", :text_content),
          render_attr("level", :heading_level),
          render_attr("href", :link_url, @link_id),
          render_attr("id", :root_id, @boundary_id),
          render_attr("class", :root_class, @boundary_id),
          render_attr("rest", :root_global_attrs, @boundary_id),
          render_attr("src", :asset_src, decorative_image_id),
          render_attr("src2", :asset_src, consumer_image_id),
          render_attr("alt", :asset_alt, consumer_image_id),
          %RenderProjection{
            public_slot_name: "actions",
            target_node_id: @actions_id,
            render_role: :subtree_slot
          }
        ]
      )

    bundle = generate!(c, p, document)
    source = elixir_artifact(bundle).content
    stylesheet = Enum.find(bundle.artifacts, &(&1.kind == :stylesheet)).content

    assert source =~ "Map.get(assigns, :title)"
    assert source =~ "case @level"
    assert source =~ "href={Map.get(assigns, :href)}"
    assert source =~ "id={Map.get(assigns, :id)}"
    assert source =~ ~s/"lf-section-marketing-block__n-000001"/

    assert source =~
             ~s/class={["lf-section-marketing-block", "lf-section-marketing-block__n-000001", Map.get(assigns, :class)]}/

    assert source =~ "Map.get(assigns, :class)"
    assert source =~ "lf_optional_global_attrs(Map.get(assigns, :rest))"
    assert source =~ "lf_validate_first_wave_slots!"
    assert source =~ "lf_src = Map.get(assigns, :src)"
    assert source =~ ~s/alt=""/
    assert source =~ "image alt is required when source is present"
    assert source =~ "case Map.get(assigns, :alt)"
    assert source =~ "render_slot(@actions)"
    refute source =~ "node_"
    refute source =~ "LiveFrames.Fidelity"
    refute source =~ "lf-section-marketing-block__n-000001-000004"
    refute stylesheet =~ "lf-section-marketing-block__n-000001-000004"
  end

  test "collection repeat targets repeat_root_node_id and item field accessors" do
    %DesignNode{} = boundary = hd(rich_document().root_nodes)
    image_id = DesignNode.deterministic_id([1, 5])

    document =
      rich_document(
        root_nodes: [
          %DesignNode{
            boundary
            | children:
                boundary.children ++
                  [
                    %DesignNode{
                      node_id: image_id,
                      semantic_type: "image",
                      styles: %{"object-fit" => StyleValue.keyword("cover")}
                    }
                  ]
          }
        ]
      )

    collection_binding = %CollectionBinding{
      collection_binding_id: "cb_members",
      owner_node_id: @boundary_id,
      repeat_root_node_id: image_id
    }

    image_binding =
      %ValueBinding{
        value_binding_id: "vb_image",
        target_node_id: image_id,
        target_kind: :asset,
        value_kind: :field,
        scope: :collection_item,
        collection_binding_id: "cb_members",
        value_key: "photo",
        normalization_status: :normalized,
        modifier: %LiveFrames.IR.ValueModifier.None{}
      }

    alt_binding =
      %ValueBinding{
        value_binding_id: "vb_alt",
        target_node_id: image_id,
        target_kind: :text,
        value_kind: :field,
        scope: :collection_item,
        collection_binding_id: "cb_members",
        value_key: "alt",
        normalization_status: :normalized,
        modifier: %LiveFrames.IR.ValueModifier.None{}
      }

    document = %{
      document
      | collection_bindings: %{"cb_members" => collection_binding},
        value_bindings: %{"vb_image" => image_binding, "vb_alt" => alt_binding}
    }

    assert :ok = IR.validate(document)

    accessibility = %{
      "image_alt_policy" => "consumer_supplied",
      "alt_item_field_name" => "alt",
      "required_when_source_present" => true
    }

    c =
      contract(
        public_attrs: [attr("members", :list)],
        collection_inputs: [
          %CollectionInput{
            source_collection_binding_id: "cb_members",
            public_attr_name: "members",
            item_fields: [
              %ItemField{
                name: "photo",
                type: :string,
                semantic_purpose: "photo",
                accessibility: accessibility
              },
              %ItemField{name: "alt", type: :string, semantic_purpose: "alt"}
            ]
          }
        ],
        binding_projections: [
          %BindingProjection{
            source_binding_kind: :collection,
            source_binding_id: "cb_members",
            projection_kind: :collection_attr,
            public_attr_name: "members",
            source_collection_binding_id: "cb_members",
            target_node_id: image_id
          },
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_image",
            projection_kind: :collection_item_field,
            source_collection_binding_id: "cb_members",
            item_field_name: "photo",
            target_node_id: image_id
          },
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_alt",
            projection_kind: :collection_item_field,
            source_collection_binding_id: "cb_members",
            item_field_name: "alt",
            target_node_id: image_id
          }
        ]
      )

    p = plan(c, document)
    source = elixir_artifact(generate!(c, p, document)).content

    assert source =~ "for lf_ci_1 <- Map.get(assigns, :members)"
    assert source =~ "class={\"lf-section-marketing-block__n-000001-000005\"}"
    assert length(String.split(source, "lf-section-marketing-block__n-000001-000005")) == 2
    assert source =~ ~s/lf_item_field(lf_ci_1, 1, "photo")/
    assert source =~ ~s/lf_item_field(lf_ci_1, 1, "alt")/
    assert source =~ "case {collection_ordinal, field} do"
    refute source =~ "owner_node_id"
    refute source =~ "String.to_atom"
  end

  test "deterministic bytes and artifact ordering are stable" do
    document = document()

    c =
      contract(
        public_attrs: [attr("title")],
        provenance: %{"z" => 1, "a" => 2}
      )

    p =
      plan(c, document,
        provenance: %{"b" => 1, "a" => 2},
        render_projections: [render_attr("title", :text_content)]
      )

    first = generate!(c, p, document)
    second = generate!(c, p, document)

    assert first == second
    assert first.artifacts == second.artifacts
    assert {:ok, plan_bytes} = ComponentizationPlan.encode(p)

    assert first.plan_fingerprint ==
             :crypto.hash(:sha256, plan_bytes) |> Base.encode16(case: :lower)
  end

  test "static internal paragraph content is emitted without new public attrs" do
    document = document()

    c = contract(public_attrs: [attr("title")])

    p =
      plan(c, document, render_projections: [render_attr("title", :text_content, @heading_id)])

    source = elixir_artifact(generate!(c, p, document)).content
    assert source =~ "Static body"
    refute source =~ "attr :static"
  end

  test "icon nodes inside boundary return generation_blocked at plan gate" do
    icon_id = DesignNode.deterministic_id([1, 3])
    %DesignNode{} = boundary = hd(document().root_nodes)

    document = %{
      document()
      | root_nodes: [
          %DesignNode{
            boundary
            | children:
                boundary.children ++ [%DesignNode{node_id: icon_id, semantic_type: "icon"}]
          }
        ]
    }

    c = contract(public_attrs: [attr("title")])
    p = plan(c, document, render_projections: [render_attr("title", :text_content)])

    assert {:error, :generation_blocked, diagnostics} = NativeGenerator.generate(c, p, document)

    assert Enum.any?(diagnostics, fn d ->
             d.code == "componentization_plan.native_generation.icon_unsupported"
           end)
  end

  test "static link text and internal navigation emit on anchor" do
    %DesignNode{} = boundary = hd(rich_document().root_nodes)

    document = %{
      rich_document()
      | root_nodes: [
          %DesignNode{
            boundary
            | children:
                Enum.map(boundary.children, fn
                  %DesignNode{node_id: @link_id} = link ->
                    %DesignNode{
                      link
                      | content: "Shop now",
                        attributes: %{"navigation" => %{"href" => "/shop"}}
                    }

                  other ->
                    other
                end)
          }
        ]
    }

    c = contract(public_attrs: [attr("title")])
    p = plan(c, document, render_projections: [render_attr("title", :text_content, @heading_id)])
    source = elixir_artifact(generate!(c, p, document)).content

    assert source =~ "Shop now"
    assert source =~ ~s(href="/shop")
    refute source =~ "<button"
  end

  test "figure wrapper keeps package class on outer element" do
    image_id = DesignNode.deterministic_id([1, 3])
    %DesignNode{} = boundary = hd(document().root_nodes)

    document = %{
      document()
      | root_nodes: [
          %DesignNode{
            boundary
            | children:
                boundary.children ++
                  [
                    %DesignNode{
                      node_id: image_id,
                      semantic_type: "image",
                      attributes: %{"tag" => "figure"}
                    }
                  ]
          }
        ]
    }

    assert :ok = IR.validate(document)

    c =
      contract(
        public_attrs: [
          attr("src", :string,
            required: true,
            accessibility: %{"image_alt_policy" => "decorative"}
          )
        ]
      )

    p =
      plan(c, document, render_projections: [render_attr("src", :asset_src, image_id)])

    source = elixir_artifact(generate!(c, p, document)).content
    assert source =~ "<figure"
    assert source =~ "lf-section-marketing-block"
    assert source =~ "<img src={@src}"
    assert source =~ ~s(alt="")
  end

  test "scalar BindingProjection link_url suppresses static navigation href" do
    link_id = @link_id
    %DesignNode{} = boundary = hd(rich_document().root_nodes)

    document = %{
      rich_document()
      | root_nodes: [
          %DesignNode{
            boundary
            | children:
                Enum.map(boundary.children, fn
                  %DesignNode{node_id: @link_id} = link ->
                    %DesignNode{
                      link
                      | attributes: %{"navigation" => %{"href" => "/static"}}
                    }

                  other ->
                    other
                end)
          }
        ]
    }

    assert :ok = IR.validate(document)

    c =
      contract(
        public_attrs: [attr("url")],
        binding_projections: [
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_url",
            projection_kind: :scalar_attr,
            public_attr_name: "url",
            target_node_id: link_id
          }
        ]
      )

    document = %{
      document
      | value_bindings: %{
          "vb_url" => %ValueBinding{
            value_binding_id: "vb_url",
            target_node_id: link_id,
            target_kind: :link_url,
            value_kind: :field,
            scope: :site,
            value_key: "url",
            normalization_status: :normalized,
            modifier: %LiveFrames.IR.ValueModifier.None{}
          }
        }
    }

    p = plan(c, document)
    source = elixir_artifact(generate!(c, p, document)).content

    assert source =~ "href={Map.get(assigns, :url)}"
    refute source =~ ~s(href="/static")
    refute source =~ "target="
  end

  test "top-level collection count emits runtime min validation helper" do
    count_id = @paragraph_id
    %DesignNode{} = boundary = hd(document().root_nodes)

    c =
      contract(
        public_attrs: [
          attr("items", :list),
          attr("total", :integer, validation: %{"min" => 2})
        ],
        collection_inputs: [
          %CollectionInput{
            source_collection_binding_id: "cb_x",
            public_attr_name: "items",
            count_attr_name: "total"
          }
        ],
        binding_projections: [
          %BindingProjection{
            source_binding_kind: :collection,
            source_binding_id: "cb_x",
            projection_kind: :collection_attr,
            public_attr_name: "items",
            source_collection_binding_id: "cb_x",
            target_node_id: count_id
          },
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_count",
            projection_kind: :collection_count_attr,
            public_attr_name: "total",
            source_collection_binding_id: "cb_x",
            target_node_id: count_id
          }
        ]
      )

    document = %{
      document()
      | collection_bindings: %{
          "cb_x" => %CollectionBinding{
            collection_binding_id: "cb_x",
            owner_node_id: @boundary_id,
            repeat_root_node_id: count_id
          }
        },
        value_bindings: %{
          "vb_count" => %ValueBinding{
            value_binding_id: "vb_count",
            target_node_id: count_id,
            target_kind: :text,
            value_kind: :collection_count,
            scope: :collection,
            collection_binding_id: "cb_x",
            normalization_status: :normalized,
            modifier: %LiveFrames.IR.ValueModifier.None{}
          }
        }
    }

    assert :ok = IR.validate(document)
    p = plan(c, document)
    source = elixir_artifact(generate!(c, p, document)).content
    assert source =~ "lf_validate_count!"
    assert source =~ "lf_validate_count!(Map.get(assigns, :total), 2)"
    refute source =~ "min:"
  end

  test "slot runtime guard rejects more than one entry" do
    c =
      contract(
        public_attrs: [attr("title")],
        public_slots: [
          %Slot{name: "actions", semantic_purpose: "actions", consumer_responsibility: "caller"}
        ]
      )

    rich_doc = rich_document()

    p =
      plan(c, rich_doc,
        render_projections: [
          render_attr("title", :text_content, @heading_id),
          %RenderProjection{
            public_slot_name: "actions",
            target_node_id: @actions_id,
            render_role: :subtree_slot
          }
        ]
      )

    source = elixir_artifact(generate!(c, p, rich_doc)).content
    assert source =~ "slot actions allows at most one entry"
  end

  test "Literal normalizes atom map keys without throwing" do
    assert {:ok, literal} = LiveFrames.NativeGenerator.Literal.render(%{foo: "bar"})
    assert literal =~ "\"foo\" => \"bar\""
  end

  test "button preserves safe normalized type submit attribute" do
    %DesignNode{} = boundary = hd(rich_document().root_nodes)

    document = %{
      rich_document()
      | root_nodes: [
          %DesignNode{
            boundary
            | children:
                Enum.map(boundary.children, fn
                  %DesignNode{node_id: @actions_id} = actions ->
                    %DesignNode{
                      actions
                      | children: [
                          %DesignNode{
                            node_id: DesignNode.deterministic_id([1, 4, 1]),
                            semantic_type: "button",
                            attributes: %{"type" => "submit"},
                            content: "Go"
                          }
                        ]
                    }

                  other ->
                    other
                end)
          }
        ]
    }

    assert :ok = IR.validate(document)

    c = contract(public_attrs: [attr("title")])
    p = plan(c, document, render_projections: [render_attr("title", :text_content, @heading_id)])
    source = elixir_artifact(generate!(c, p, document)).content
    assert source =~ ~s(type="submit")
    refute source =~ "type=\"button\""
  end

  test "replaces a rich_text subtree slot without emitting source or native style" do
    rich_text_id = DesignNode.deterministic_id([1, 5])

    rich_text = %DesignNode{
      node_id: rich_text_id,
      semantic_type: "rich_text",
      content: "<p>LF_RICH_TEXT_SOURCE_SENTINEL</p>",
      styles: %{"color" => StyleValue.literal("red")}
    }

    %DesignNode{} = boundary = hd(rich_document().root_nodes)

    document = %{
      rich_document()
      | root_nodes: [%{boundary | children: boundary.children ++ [rich_text]}]
    }

    assert :ok = IR.validate(document)

    c =
      contract(
        public_slots: [
          %Slot{
            name: "body",
            semantic_purpose: "body",
            consumer_responsibility: "caller"
          }
        ]
      )

    p =
      plan(c, document,
        render_projections: [
          %RenderProjection{
            public_slot_name: "body",
            target_node_id: rich_text_id,
            render_role: :subtree_slot
          }
        ]
      )

    bundle = generate!(c, p, document)
    source = elixir_artifact(bundle).content
    stylesheet = Enum.find(bundle.artifacts, &(&1.kind == :stylesheet)).content

    assert source =~ "render_slot(@body)"
    refute source =~ "<span class={"
    refute source =~ "LF_RICH_TEXT_SOURCE_SENTINEL"
    refute source =~ "<p>LF_RICH_TEXT_SOURCE_SENTINEL</p>"
    refute source =~ "Phoenix.HTML.raw"
    refute source =~ "raw("
    refute stylesheet =~ "lf-section-marketing-block__n-000001-000005"
  end

  test "primary action subtree slot gets a package boundary and direct-root presentation" do
    target_id = DesignNode.deterministic_id([1, 3])

    button = %DesignNode{
      node_id: target_id,
      semantic_type: "button",
      attributes: %{"tag" => "button", "style" => "primary"},
      content: "Source label must not render"
    }

    %DesignNode{} = boundary = hd(document().root_nodes)
    document = %{document() | root_nodes: [%{boundary | children: boundary.children ++ [button]}]}

    c =
      contract(
        public_slots: [
          %Slot{
            name: "primary_action",
            semantic_purpose: "action",
            consumer_responsibility: "caller"
          }
        ]
      )

    p =
      plan(c, document,
        render_projections: [
          %RenderProjection{
            public_slot_name: "primary_action",
            target_node_id: target_id,
            render_role: :subtree_slot
          }
        ]
      )

    bundle = generate!(c, p, document)
    source = elixir_artifact(bundle).content
    stylesheet = Enum.find(bundle.artifacts, &(&1.kind == :stylesheet)).content
    private_class = "lf-section-marketing-block__n-000001-000003"

    assert source =~ "<span class={\"#{private_class}\"}>"
    assert source =~ "render_slot(@primary_action)"
    assert source =~ "</span>"
    refute source =~ "Source label must not render"
    refute source =~ "<button"
    assert length(:binary.matches(source, private_class)) == 1

    assert stylesheet =~ ".#{private_class} {\n  display: contents;\n}"
    assert stylesheet =~ ".#{private_class} > :where(a, button) {"
    assert stylesheet =~ "align-items: center;"
    assert stylesheet =~ "box-sizing: border-box;"
    assert stylesheet =~ "display: inline-flex;"
    assert stylesheet =~ "font-family: inherit;"
    assert stylesheet =~ "justify-content: center;"
    assert stylesheet =~ "text-decoration: none;"
    assert stylesheet =~ "background-color: var(--lf-action-primary-background);"
    assert stylesheet =~ "padding-inline: var(--lf-action-primary-padding-inline);"
    assert stylesheet =~ ".#{private_class} > :where(a, button):hover {"
    assert stylesheet =~ ".#{private_class} > :where(a, button):focus-visible {"
    refute stylesheet =~ ".#{private_class} :where(a, button)"
  end

  test "primary-styled button in non-primary subtree slot stays ordinary" do
    target_id = DesignNode.deterministic_id([1, 3])

    button = %DesignNode{
      node_id: target_id,
      semantic_type: "button",
      attributes: %{"tag" => "button", "style" => "primary"}
    }

    %DesignNode{} = boundary = hd(document().root_nodes)
    document = %{document() | root_nodes: [%{boundary | children: boundary.children ++ [button]}]}

    c =
      contract(
        public_slots: [
          %Slot{
            name: "secondary_action",
            semantic_purpose: "action",
            consumer_responsibility: "caller"
          }
        ]
      )

    p =
      plan(c, document,
        render_projections: [
          %RenderProjection{
            public_slot_name: "secondary_action",
            target_node_id: target_id,
            render_role: :subtree_slot
          }
        ]
      )

    bundle = generate!(c, p, document)
    source = elixir_artifact(bundle).content
    stylesheet = Enum.find(bundle.artifacts, &(&1.kind == :stylesheet)).content

    assert source =~ "render_slot(@secondary_action)"
    refute source =~ "<span class={"
    refute stylesheet =~ "display: contents"
    refute stylesheet =~ ":where(a, button)"
  end

  test "styled primary subtree slot target remains blocked" do
    target_id = DesignNode.deterministic_id([1, 3])

    button = %DesignNode{
      node_id: target_id,
      semantic_type: "button",
      attributes: %{"tag" => "button", "style" => "primary"},
      styles: %{"max-width" => StyleValue.literal("20rem")}
    }

    %DesignNode{} = boundary = hd(document().root_nodes)
    document = %{document() | root_nodes: [%{boundary | children: boundary.children ++ [button]}]}

    c =
      contract(
        public_slots: [
          %Slot{
            name: "primary_action",
            semantic_purpose: "action",
            consumer_responsibility: "caller"
          }
        ]
      )

    p =
      plan(c, document,
        render_projections: [
          %RenderProjection{
            public_slot_name: "primary_action",
            target_node_id: target_id,
            render_role: :subtree_slot
          }
        ]
      )

    assert {:error, :generation_blocked, [diagnostic]} = NativeGenerator.generate(c, p, document)
    assert diagnostic.code == "native_generator.styling.primary_action_subtree_slot_authority_gap"
  end

  test "responsive primary subtree slot target remains blocked" do
    target_id = DesignNode.deterministic_id([1, 3])

    button = %DesignNode{
      node_id: target_id,
      semantic_type: "button",
      attributes: %{"tag" => "button", "style" => "primary"},
      responsive: %{
        "tablet_portrait" => %LiveFrames.IR.ResponsiveOverride{
          breakpoint_id: "tablet_portrait",
          source_name: "tablet_portrait",
          max_width: 991,
          resolution_status: :resolved
        }
      }
    }

    %DesignNode{} = boundary = hd(document().root_nodes)
    document = %{document() | root_nodes: [%{boundary | children: boundary.children ++ [button]}]}

    c =
      contract(
        public_slots: [
          %Slot{
            name: "primary_action",
            semantic_purpose: "action",
            consumer_responsibility: "caller"
          }
        ]
      )

    p =
      plan(c, document,
        render_projections: [
          %RenderProjection{
            public_slot_name: "primary_action",
            target_node_id: target_id,
            render_role: :subtree_slot
          }
        ]
      )

    assert {:error, :generation_blocked, [diagnostic]} = NativeGenerator.generate(c, p, document)

    assert diagnostic.code ==
             "native_generator.styling.primary_action_subtree_slot_authority_gap"
  end

  test "outline primary subtree slot remains blocked by variant authority" do
    target_id = DesignNode.deterministic_id([1, 3])

    button = %DesignNode{
      node_id: target_id,
      semantic_type: "button",
      attributes: %{"tag" => "button", "style" => "primary", "outline" => true}
    }

    %DesignNode{} = boundary = hd(document().root_nodes)
    document = %{document() | root_nodes: [%{boundary | children: boundary.children ++ [button]}]}

    c =
      contract(
        public_slots: [
          %Slot{
            name: "primary_action",
            semantic_purpose: "action",
            consumer_responsibility: "caller"
          }
        ]
      )

    p =
      plan(c, document,
        render_projections: [
          %RenderProjection{
            public_slot_name: "primary_action",
            target_node_id: target_id,
            render_role: :subtree_slot
          }
        ]
      )

    assert {:error, :generation_blocked, [diagnostic]} = NativeGenerator.generate(c, p, document)
    assert diagnostic.code == "native_generator.styling.primary_action_variant_authority_gap"
  end

  test "non-slotted rich_text without a normalized tag remains generation_blocked" do
    rich_text_id = DesignNode.deterministic_id([1, 5])

    rich_text = %DesignNode{
      node_id: rich_text_id,
      semantic_type: "rich_text",
      content: "Visible rich text"
    }

    %DesignNode{} = boundary = hd(rich_document().root_nodes)

    document = %{
      rich_document()
      | root_nodes: [%{boundary | children: boundary.children ++ [rich_text]}]
    }

    c = contract()
    p = plan(c, document)

    assert {:error, :generation_blocked, diagnostics} = NativeGenerator.generate(c, p, document)

    assert Enum.any?(diagnostics, fn diagnostic ->
             diagnostic.code == "componentization_plan.native_generation.tag_unsupported"
           end)
  end

  test "structured rich_text is generation_blocked before renderer" do
    node =
      %DesignNode{
        node_id: @boundary_id,
        semantic_type: "rich_text",
        attributes: %{"tag" => "div"},
        content: %{"blocks" => []}
      }

    document = %DesignDocument{root_nodes: [node]}
    c = contract(public_attrs: [attr("title")])
    p = plan(c, document)

    assert {:error, :generation_blocked, diagnostics} = NativeGenerator.generate(c, p, document)

    assert Enum.any?(diagnostics, fn d ->
             d.code == "componentization_plan.native_generation.rich_text_structured_content"
           end)
  end

  test "module naming helpers" do
    assert Renderer.module_name(%ComponentContract{
             category: :section,
             module_intent: "marketing_block"
           }) ==
             "LiveFrames.Components.Sections.MarketingBlock"

    assert Renderer.package_root_class(%ComponentContract{
             category: :section,
             module_intent: "marketing_block"
           }) == "lf-section-marketing-block"
  end
end
