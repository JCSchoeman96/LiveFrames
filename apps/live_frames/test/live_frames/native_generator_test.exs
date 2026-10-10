defmodule LiveFrames.NativeGeneratorTest do
  use ExUnit.Case, async: true

  alias LiveFrames.ComponentContract
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
  alias LiveFrames.IR.ValueBinding
  alias LiveFrames.IR
  alias LiveFrames.NativeGenerator
  alias LiveFrames.NativeGenerator.Renderer

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

  test "styled figure image blocks when the emitted style element cannot be proven" do
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
                      styles: %{"object-fit" => StyleValue.keyword("cover")}
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
        modifier_status: :none
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
        modifier_status: :none
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
            modifier_status: :none
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
            modifier_status: :none
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
    refute source =~ "LF_RICH_TEXT_SOURCE_SENTINEL"
    refute source =~ "<p>LF_RICH_TEXT_SOURCE_SENTINEL</p>"
    refute source =~ "Phoenix.HTML.raw"
    refute source =~ "raw("
    refute stylesheet =~ "lf-section-marketing-block__n-000001-000005"
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
