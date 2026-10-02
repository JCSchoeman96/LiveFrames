defmodule LiveFrames.ComponentizationPlanReferenceValidationTest do
  use ExUnit.Case, async: true

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentContract.CollectionInput
  alias LiveFrames.ComponentContract.ItemField
  alias LiveFrames.ComponentContract.Slot
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.Diagnostic
  alias LiveFrames.ComponentizationPlan.RenderProjection
  alias LiveFrames.IR.CollectionBinding
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR
  alias LiveFrames.IR.ValueBinding

  @boundary_id DesignNode.deterministic_id([1])
  @heading_id DesignNode.deterministic_id([1, 1])
  @image_id DesignNode.deterministic_id([1, 2])
  @actions_id DesignNode.deterministic_id([1, 3])
  @outside_id DesignNode.deterministic_id([2])

  defp document(overrides \\ []) do
    roots = [
      %DesignNode{
        node_id: @boundary_id,
        semantic_type: "section",
        children: [
          %DesignNode{node_id: @heading_id, semantic_type: "heading"},
          %DesignNode{node_id: @image_id, semantic_type: "paragraph"},
          %DesignNode{
            node_id: @actions_id,
            semantic_type: "actions",
            children: [
              %DesignNode{
                node_id: DesignNode.deterministic_id([1, 3, 1]),
                semantic_type: "button"
              }
            ]
          }
        ]
      },
      %DesignNode{node_id: @outside_id, semantic_type: "paragraph"}
    ]

    struct!(%DesignDocument{root_nodes: roots}, overrides)
  end

  defp image_document do
    design_document = document()
    [boundary, outside] = design_document.root_nodes
    [heading, image, actions] = boundary.children

    %{
      design_document
      | root_nodes: [
          %{boundary | children: [heading, %{image | semantic_type: "image"}, actions]},
          outside
        ]
    }
  end

  defp role_document do
    design_document = document()
    [boundary, outside] = design_document.root_nodes
    link = %DesignNode{node_id: DesignNode.deterministic_id([1, 4]), semantic_type: "link"}
    link_slot = %DesignNode{node_id: DesignNode.deterministic_id([1, 5]), semantic_type: "link"}

    %{
      design_document
      | root_nodes: [%{boundary | children: boundary.children ++ [link, link_slot]}, outside]
    }
  end

  defp semantic_boundary_document(semantic_type) do
    design_document = document()
    [_boundary, outside] = design_document.root_nodes
    boundary = %DesignNode{node_id: @boundary_id, semantic_type: semantic_type}
    %{design_document | root_nodes: [boundary, outside]}
  end

  defp contract(overrides \\ []) do
    struct!(
      %ComponentContract{
        contract_id: "hero-contract",
        module_intent: "marketing_block",
        function_intent: "hero",
        approval_status: :approved
      },
      overrides
    )
  end

  defp plan(contract, design_document, overrides \\ []) do
    {:ok, fingerprint} = ComponentizationPlan.design_document_sha256(design_document)

    struct!(
      %ComponentizationPlan{
        contract_id: contract.contract_id,
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

  defp binding_projection(id, name, target \\ @heading_id) do
    %BindingProjection{
      source_binding_kind: :value,
      source_binding_id: id,
      projection_kind: :scalar_attr,
      public_attr_name: name,
      target_node_id: target
    }
  end

  defp value_binding(id, target, options \\ []) do
    %ValueBinding{
      value_binding_id: id,
      target_node_id: target,
      target_kind: Keyword.get(options, :target_kind, :text),
      value_kind: Keyword.get(options, :value_kind, :field),
      scope: Keyword.get(options, :scope, :site),
      value_key: Keyword.get(options, :value_key, "field"),
      collection_binding_id: Keyword.get(options, :collection_binding_id),
      normalization_status: Keyword.get(options, :normalization_status, :normalized),
      modifier_status: Keyword.get(options, :modifier_status, :none)
    }
  end

  defp codes({:error, diagnostics}), do: Enum.map(diagnostics, & &1.code)

  test "fingerprint hashes canonical bytes and distinguishes documents with colliding node ids" do
    first = document()
    [boundary | rest] = first.root_nodes
    second = %{first | root_nodes: [%{boundary | label: "different content"} | rest]}

    assert {:ok, first_hash} = ComponentizationPlan.design_document_sha256(first)
    assert {:ok, ^first_hash} = ComponentizationPlan.design_document_sha256(first)
    expected = :crypto.hash(:sha256, IR.encode!(first)) |> Base.encode16(case: :lower)
    assert {:ok, second_hash} = ComponentizationPlan.design_document_sha256(second)
    assert first_hash =~ ~r/^[0-9a-f]{64}$/
    assert first_hash == expected
    refute first_hash == second_hash

    plan = plan(contract(), first)

    assert "componentization_plan.design_document.mismatch" in codes(
             ComponentizationPlan.validate_references(plan, contract(), second)
           )
  end

  test "accepts a structurally valid empty plan and contract" do
    design_document = document()
    component_contract = contract()

    assert ComponentizationPlan.validate_references(
             plan(component_contract, design_document),
             component_contract,
             design_document
           ) == :ok
  end

  test "validates unbound top-level attr placement against role type and node matrices" do
    design_document = document()

    component_contract =
      contract(public_attrs: [attr("title")])

    good_plan =
      plan(component_contract, design_document,
        render_projections: [render_attr("title", :text_content)]
      )

    assert ComponentizationPlan.validate_references(
             good_plan,
             component_contract,
             design_document
           ) == :ok

    wrong_type = contract(public_attrs: [attr("title", :integer)])

    wrong_type_plan =
      plan(wrong_type, design_document, render_projections: [render_attr("title", :text_content)])

    assert "componentization_plan.render_projection.role_type_mismatch" in codes(
             ComponentizationPlan.validate_references(
               wrong_type_plan,
               wrong_type,
               design_document
             )
           )

    wrong_node_plan =
      plan(component_contract, design_document,
        render_projections: [render_attr("title", :text_content, @actions_id)]
      )

    assert "componentization_plan.render_projection.role_node_mismatch" in codes(
             ComponentizationPlan.validate_references(
               wrong_node_plan,
               component_contract,
               design_document
             )
           )
  end

  test "accepts each closed render role with its authorized attr, slot and node type" do
    design_document = role_document()
    link_id = DesignNode.deterministic_id([1, 4])
    link_slot_id = DesignNode.deterministic_id([1, 5])

    component_contract =
      contract(
        public_attrs: [
          attr("title"),
          attr("level", :integer, validation: %{"values" => [1, 2, 3, 4, 5, 6]}),
          attr("href"),
          attr("id"),
          attr("class"),
          attr("rest", :global)
        ],
        public_slots: [
          %Slot{name: "actions", semantic_purpose: "actions", consumer_responsibility: "caller"},
          %Slot{
            name: "link_actions",
            semantic_purpose: "actions",
            consumer_responsibility: "caller"
          }
        ]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [
          render_attr("title", :text_content),
          render_attr("level", :heading_level),
          render_attr("href", :link_url, link_id),
          render_attr("id", :root_id, @boundary_id),
          render_attr("class", :root_class, @boundary_id),
          render_attr("rest", :root_global_attrs, @boundary_id),
          %RenderProjection{
            public_slot_name: "actions",
            target_node_id: @actions_id,
            render_role: :subtree_slot
          },
          %RenderProjection{
            public_slot_name: "link_actions",
            target_node_id: link_slot_id,
            render_role: :subtree_slot
          }
        ]
      )

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok

    wrong_root = contract(public_attrs: [attr("id")])

    wrong_root_plan =
      plan(wrong_root, design_document, render_projections: [render_attr("id", :root_id)])

    assert "componentization_plan.render_projection.role_node_mismatch" in codes(
             ComponentizationPlan.validate_references(
               wrong_root_plan,
               wrong_root,
               design_document
             )
           )
  end

  test "allows semantic render roles on a heading boundary" do
    design_document = semantic_boundary_document("heading")

    text_contract = contract(public_attrs: [attr("title")])

    text_plan =
      plan(text_contract, design_document,
        render_projections: [render_attr("title", :text_content, @boundary_id)]
      )

    assert ComponentizationPlan.validate_references(text_plan, text_contract, design_document) ==
             :ok

    component_contract =
      contract(
        public_attrs: [
          attr("title"),
          attr("level", :integer, validation: %{"values" => [1, 2, 3, 4, 5, 6]})
        ]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [
          render_attr("title", :text_content, @boundary_id),
          render_attr("level", :heading_level, @boundary_id)
        ]
      )

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok

    root_contract = contract(public_attrs: [attr("id"), attr("class")])

    root_plan =
      plan(root_contract, design_document,
        render_projections: [
          render_attr("id", :root_id, @boundary_id),
          render_attr("class", :root_class, @boundary_id)
        ]
      )

    assert ComponentizationPlan.validate_references(root_plan, root_contract, design_document) ==
             :ok
  end

  test "allows accessible image source and alt roles on an image boundary" do
    design_document = semantic_boundary_document("image")

    decorative_contract =
      contract(
        public_attrs: [
          attr("src", :string, accessibility: %{"image_alt_policy" => "decorative"})
        ]
      )

    decorative_plan =
      plan(decorative_contract, design_document,
        render_projections: [render_attr("src", :asset_src, @boundary_id)]
      )

    assert ComponentizationPlan.validate_references(
             decorative_plan,
             decorative_contract,
             design_document
           ) == :ok

    consumer_contract =
      contract(
        public_attrs: [
          attr("src", :string,
            accessibility: %{
              "image_alt_policy" => "consumer_supplied",
              "alt_attr_name" => "alt",
              "required_when_source_present" => true
            }
          ),
          attr("alt")
        ]
      )

    consumer_plan =
      plan(consumer_contract, design_document,
        render_projections: [
          render_attr("src", :asset_src, @boundary_id),
          render_attr("alt", :asset_alt, @boundary_id)
        ]
      )

    assert ComponentizationPlan.validate_references(
             consumer_plan,
             consumer_contract,
             design_document
           ) == :ok
  end

  test "allows link_url on a link boundary" do
    design_document = semantic_boundary_document("link")
    component_contract = contract(public_attrs: [attr("href")])

    component_plan =
      plan(component_contract, design_document,
        render_projections: [render_attr("href", :link_url, @boundary_id)]
      )

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok
  end

  test "allows subtree_slot on an actions boundary without bindings" do
    design_document = semantic_boundary_document("actions")

    component_contract =
      contract(
        public_slots: [
          %Slot{name: "actions", semantic_purpose: "actions", consumer_responsibility: "caller"}
        ]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [
          %RenderProjection{
            public_slot_name: "actions",
            target_node_id: @boundary_id,
            render_role: :subtree_slot
          }
        ]
      )

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok
  end

  test "rejects mixed root and semantic render roles on a boundary" do
    heading_document = semantic_boundary_document("heading")
    heading_contract = contract(public_attrs: [attr("id"), attr("title")])

    heading_plan =
      plan(heading_contract, heading_document,
        render_projections: [
          render_attr("id", :root_id, @boundary_id),
          render_attr("title", :text_content, @boundary_id)
        ]
      )

    image_document = semantic_boundary_document("image")

    image_contract =
      contract(
        public_attrs: [
          attr("class"),
          attr("src", :string, accessibility: %{"image_alt_policy" => "decorative"})
        ]
      )

    image_plan =
      plan(image_contract, image_document,
        render_projections: [
          render_attr("class", :root_class, @boundary_id),
          render_attr("src", :asset_src, @boundary_id)
        ]
      )

    link_document = semantic_boundary_document("link")
    link_contract = contract(public_attrs: [attr("rest", :global), attr("href")])

    link_plan =
      plan(link_contract, link_document,
        render_projections: [
          render_attr("rest", :root_global_attrs, @boundary_id),
          render_attr("href", :link_url, @boundary_id)
        ]
      )

    for {component_plan, component_contract, design_document} <- [
          {heading_plan, heading_contract, heading_document},
          {image_plan, image_contract, image_document},
          {link_plan, link_contract, link_document}
        ] do
      assert "componentization_plan.render_projection.role_conflict" in codes(
               ComponentizationPlan.validate_references(
                 component_plan,
                 component_contract,
                 design_document
               )
             )
    end
  end

  test "rejects unsupported render role co-location" do
    design_document = document()
    component_contract = contract(public_attrs: [attr("title"), attr("label")])

    component_plan =
      plan(component_contract, design_document,
        render_projections: [
          render_attr("title", :text_content),
          render_attr("label", :text_content)
        ]
      )

    assert "componentization_plan.render_projection.role_conflict" in codes(
             ComponentizationPlan.validate_references(
               component_plan,
               component_contract,
               design_document
             )
           )
  end

  test "a link subtree slot excludes link_url projection on the same node" do
    design_document = role_document()
    link_id = DesignNode.deterministic_id([1, 4])

    component_contract =
      contract(
        public_attrs: [attr("href")],
        public_slots: [
          %Slot{
            name: "link_actions",
            semantic_purpose: "actions",
            consumer_responsibility: "caller"
          }
        ]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [
          render_attr("href", :link_url, link_id),
          %RenderProjection{
            public_slot_name: "link_actions",
            target_node_id: link_id,
            render_role: :subtree_slot
          }
        ]
      )

    assert "componentization_plan.slot.subtree_conflict" in codes(
             ComponentizationPlan.validate_references(
               component_plan,
               component_contract,
               design_document
             )
           )
  end

  test "requires exactly one placement for every top-level public attr and slot" do
    design_document = document()

    component_contract =
      contract(
        public_attrs: [attr("title")],
        public_slots: [
          %Slot{name: "actions", semantic_purpose: "actions", consumer_responsibility: "caller"}
        ]
      )

    missing_plan = plan(component_contract, design_document)

    assert "componentization_plan.public_input.placement_missing" in codes(
             ComponentizationPlan.validate_references(
               missing_plan,
               component_contract,
               design_document
             )
           )

    placed_plan =
      plan(component_contract, design_document,
        render_projections: [
          render_attr("title", :text_content),
          %RenderProjection{
            public_slot_name: "actions",
            target_node_id: @actions_id,
            render_role: :subtree_slot
          }
        ]
      )

    assert ComponentizationPlan.validate_references(
             placed_plan,
             component_contract,
             design_document
           ) == :ok
  end

  test "rejects a public input with both binding and render placement" do
    design_document = %{
      document()
      | value_bindings: %{"vb_title" => value_binding("vb_title", @heading_id)}
    }

    component_contract =
      contract(
        public_attrs: [attr("title")],
        binding_projections: [binding_projection("vb_title", "title")]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [render_attr("title", :text_content)]
      )

    assert "componentization_plan.public_input.placement_conflict" in codes(
             ComponentizationPlan.validate_references(
               component_plan,
               component_contract,
               design_document
             )
           )
  end

  test "requires complete in-boundary value binding coverage" do
    design_document = %{
      document()
      | value_bindings: %{"vb_title" => value_binding("vb_title", @heading_id)}
    }

    component_contract = contract()

    assert "componentization_plan.binding.uncovered" in codes(
             ComponentizationPlan.validate_references(
               plan(component_contract, design_document),
               component_contract,
               design_document
             )
           )
  end

  test "accepts one value projection and rejects duplicate binding projections" do
    design_document = %{
      document()
      | value_bindings: %{"vb_title" => value_binding("vb_title", @heading_id)}
    }

    projection = binding_projection("vb_title", "title")

    component_contract =
      contract(public_attrs: [attr("title")], binding_projections: [projection])

    assert ComponentizationPlan.validate_references(
             plan(component_contract, design_document),
             component_contract,
             design_document
           ) == :ok

    duplicate_contract = %{
      component_contract
      | binding_projections: [projection, projection]
    }

    diagnostic_codes =
      ComponentizationPlan.validate_references(
        plan(duplicate_contract, design_document),
        duplicate_contract,
        design_document
      )
      |> codes()

    assert "componentization_plan.binding.duplicate" in diagnostic_codes
    assert "componentization_plan.public_input.placement_conflict" in diagnostic_codes
  end

  test "rejects bindings whose targets fall outside the selected boundary" do
    design_document = %{
      document()
      | value_bindings: %{"vb_title" => value_binding("vb_title", @outside_id)}
    }

    component_contract =
      contract(
        public_attrs: [attr("title")],
        binding_projections: [binding_projection("vb_title", "title", @outside_id)]
      )

    assert "componentization_plan.render_projection.target_outside_boundary" in codes(
             ComponentizationPlan.validate_references(
               plan(component_contract, design_document),
               component_contract,
               design_document
             )
           )
  end

  test "rejects collection bindings that cross the selected boundary" do
    design_document = %{
      document()
      | collection_bindings: %{
          "cb_root" => %CollectionBinding{
            collection_binding_id: "cb_root",
            owner_node_id: @boundary_id,
            repeat_root_node_id: @outside_id
          }
        }
    }

    component_contract = contract()

    assert "componentization_plan.boundary.binding_crosses" in codes(
             ComponentizationPlan.validate_references(
               plan(component_contract, design_document),
               component_contract,
               design_document
             )
           )
  end

  test "covers in-boundary collection bindings and ignores wholly external ones" do
    collection_binding = %CollectionBinding{
      collection_binding_id: "cb_items",
      owner_node_id: @boundary_id,
      repeat_root_node_id: @image_id
    }

    design_document = %{
      document()
      | collection_bindings: %{"cb_items" => collection_binding}
    }

    input = %CollectionInput{
      source_collection_binding_id: "cb_items",
      public_attr_name: "items"
    }

    projection = %BindingProjection{
      source_binding_kind: :collection,
      source_binding_id: "cb_items",
      projection_kind: :collection_attr,
      public_attr_name: "items",
      source_collection_binding_id: "cb_items",
      target_node_id: @image_id
    }

    component_contract =
      contract(
        public_attrs: [attr("items", :list)],
        collection_inputs: [input],
        binding_projections: [projection]
      )

    assert ComponentizationPlan.validate_references(
             plan(component_contract, design_document),
             component_contract,
             design_document
           ) == :ok

    uncovered_contract = %{component_contract | binding_projections: []}

    assert "componentization_plan.binding.uncovered" in codes(
             ComponentizationPlan.validate_references(
               plan(uncovered_contract, design_document),
               uncovered_contract,
               design_document
             )
           )

    external_binding = %{
      collection_binding
      | owner_node_id: @outside_id,
        repeat_root_node_id: @outside_id
    }

    external_document = %{
      document()
      | collection_bindings: %{
          "cb_external" => %{external_binding | collection_binding_id: "cb_external"}
        }
    }

    assert ComponentizationPlan.validate_references(
             plan(contract(), external_document),
             contract(),
             external_document
           ) == :ok
  end

  test "reports both collection boundary crossing directions and missing targets" do
    crossing = %CollectionBinding{
      collection_binding_id: "cb_crossing",
      owner_node_id: @outside_id,
      repeat_root_node_id: @heading_id
    }

    design_document = %{
      document()
      | collection_bindings: %{"cb_crossing" => crossing}
    }

    assert "componentization_plan.boundary.binding_crosses" in codes(
             ComponentizationPlan.validate_references(
               plan(contract(), design_document),
               contract(),
               design_document
             )
           )

    component_contract = contract(public_attrs: [attr("title")])

    missing_target_plan =
      plan(component_contract, document(),
        render_projections: [render_attr("title", :text_content, "node_missing")]
      )

    assert "componentization_plan.render_projection.target_missing" in codes(
             ComponentizationPlan.validate_references(
               missing_target_plan,
               component_contract,
               document()
             )
           )

    missing_boundary_plan = plan(contract(), document(), boundary_node_id: "node_missing")

    assert "componentization_plan.boundary.missing" in codes(
             ComponentizationPlan.validate_references(
               missing_boundary_plan,
               contract(),
               document()
             )
           )
  end

  test "blocks unsupported nodes and static internal images" do
    for semantic_type <- ["raw", "unsupported", "unknown"] do
      base = document()
      [boundary, outside] = base.root_nodes
      [heading | rest] = boundary.children

      unsupported_document = %{
        base
        | root_nodes: [
            %{boundary | children: [%{heading | semantic_type: semantic_type} | rest]},
            outside
          ]
      }

      assert "componentization_plan.unsupported_node" in codes(
               ComponentizationPlan.validate_references(
                 plan(contract(), unsupported_document),
                 contract(),
                 unsupported_document
               )
             )
    end

    base = document()
    [boundary, outside] = base.root_nodes
    external_document = %{base | root_nodes: [boundary, %{outside | semantic_type: "raw"}]}

    assert ComponentizationPlan.validate_references(
             plan(contract(), external_document),
             contract(),
             external_document
           ) == :ok

    assert "componentization_plan.accessibility.static_image_unsupported" in codes(
             ComponentizationPlan.validate_references(
               plan(contract(), image_document()),
               contract(),
               image_document()
             )
           )
  end

  test "a subtree slot owns and replaces a static image in its subtree" do
    base = document()
    [boundary, outside] = base.root_nodes
    [heading, paragraph, actions] = boundary.children
    child_image = %{hd(actions.children) | semantic_type: "image"}

    design_document = %{
      base
      | root_nodes: [
          %{boundary | children: [heading, paragraph, %{actions | children: [child_image]}]},
          outside
        ]
    }

    component_contract =
      contract(
        public_slots: [
          %Slot{name: "actions", semantic_purpose: "actions", consumer_responsibility: "caller"}
        ]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [
          %RenderProjection{
            public_slot_name: "actions",
            target_node_id: @actions_id,
            render_role: :subtree_slot
          }
        ]
      )

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok
  end

  test "validates top-level consumer-supplied and decorative image accessibility" do
    design_document = image_document()

    accessibility = %{
      "image_alt_policy" => "consumer_supplied",
      "alt_attr_name" => "alt",
      "required_when_source_present" => true
    }

    component_contract =
      contract(public_attrs: [attr("image", :string, accessibility: accessibility), attr("alt")])

    component_plan =
      plan(component_contract, design_document,
        render_projections: [
          render_attr("image", :asset_src, @image_id),
          render_attr("alt", :asset_alt, @image_id)
        ]
      )

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok

    decorative_contract =
      contract(
        public_attrs: [
          attr("image", :string, accessibility: %{"image_alt_policy" => "decorative"})
        ]
      )

    decorative_plan =
      plan(decorative_contract, design_document,
        render_projections: [render_attr("image", :asset_src, @image_id)]
      )

    assert ComponentizationPlan.validate_references(
             decorative_plan,
             decorative_contract,
             design_document
           ) == :ok
  end

  test "consumer-supplied image accessibility requires exactly one matching asset_alt projection" do
    design_document = image_document()

    source_accessibility = %{
      "image_alt_policy" => "consumer_supplied",
      "alt_attr_name" => "alt",
      "required_when_source_present" => true
    }

    component_contract =
      contract(
        public_attrs: [attr("image", :string, accessibility: source_accessibility), attr("alt")]
      )

    matching_plan =
      plan(component_contract, design_document,
        render_projections: [
          render_attr("image", :asset_src, @image_id),
          render_attr("alt", :asset_alt, @image_id)
        ]
      )

    assert ComponentizationPlan.validate_references(
             matching_plan,
             component_contract,
             design_document
           ) == :ok

    missing_alt_plan = %{
      matching_plan
      | render_projections: [render_attr("image", :asset_src, @image_id)]
    }

    assert "componentization_plan.accessibility.alt_projection_mismatch" in codes(
             ComponentizationPlan.validate_references(
               missing_alt_plan,
               component_contract,
               design_document
             )
           )

    multiple_contract =
      contract(
        public_attrs: [
          attr("image", :string, accessibility: source_accessibility),
          attr("alt"),
          attr("other_alt")
        ]
      )

    multiple_alt_plan =
      plan(multiple_contract, design_document,
        render_projections: [
          render_attr("image", :asset_src, @image_id),
          render_attr("alt", :asset_alt, @image_id),
          render_attr("other_alt", :asset_alt, @image_id)
        ]
      )

    assert "componentization_plan.accessibility.alt_projection_mismatch" in codes(
             ComponentizationPlan.validate_references(
               multiple_alt_plan,
               multiple_contract,
               design_document
             )
           )
  end

  test "decorative image accessibility rejects any asset_alt projection" do
    design_document = image_document()
    accessibility = %{"image_alt_policy" => "decorative"}

    no_alt_contract =
      contract(public_attrs: [attr("image", :string, accessibility: accessibility)])

    no_alt_plan =
      plan(no_alt_contract, design_document,
        render_projections: [render_attr("image", :asset_src, @image_id)]
      )

    assert ComponentizationPlan.validate_references(no_alt_plan, no_alt_contract, design_document) ==
             :ok

    one_alt_contract =
      contract(
        public_attrs: [
          attr("image", :string, accessibility: accessibility),
          attr("alt")
        ]
      )

    one_alt_plan =
      plan(one_alt_contract, design_document,
        render_projections: [
          render_attr("image", :asset_src, @image_id),
          render_attr("alt", :asset_alt, @image_id)
        ]
      )

    assert "componentization_plan.accessibility.image_policy_invalid" in codes(
             ComponentizationPlan.validate_references(
               one_alt_plan,
               one_alt_contract,
               design_document
             )
           )

    multiple_alt_contract =
      contract(
        public_attrs: [
          attr("image", :string, accessibility: accessibility),
          attr("alt"),
          attr("other_alt")
        ]
      )

    multiple_alt_plan =
      plan(multiple_alt_contract, design_document,
        render_projections: [
          render_attr("image", :asset_src, @image_id),
          render_attr("alt", :asset_alt, @image_id),
          render_attr("other_alt", :asset_alt, @image_id)
        ]
      )

    assert "componentization_plan.accessibility.image_policy_invalid" in codes(
             ComponentizationPlan.validate_references(
               multiple_alt_plan,
               multiple_alt_contract,
               design_document
             )
           )
  end

  test "validates many image sources sharing one node without changing diagnostics" do
    design_document = image_document()
    source_names = Enum.map(1..64, &"image_#{&1}")

    component_contract =
      contract(
        public_attrs:
          Enum.map(source_names, fn name ->
            attr(name, :string, accessibility: %{"image_alt_policy" => "decorative"})
          end)
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: Enum.map(source_names, &render_attr(&1, :asset_src, @image_id))
      )

    assert "componentization_plan.render_projection.role_conflict" in codes(
             ComponentizationPlan.validate_references(
               component_plan,
               component_contract,
               design_document
             )
           )
  end

  test "checks accessibility when the top-level image source is binding-backed" do
    design_document = %{
      image_document()
      | value_bindings: %{
          "vb_image" => value_binding("vb_image", @image_id, target_kind: :asset, scope: :site)
        }
    }

    accessibility = %{
      "image_alt_policy" => "consumer_supplied",
      "alt_attr_name" => "alt",
      "required_when_source_present" => true
    }

    component_contract =
      contract(
        public_attrs: [attr("image", :string, accessibility: accessibility), attr("alt")],
        binding_projections: [binding_projection("vb_image", "image", @image_id)]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [render_attr("alt", :asset_alt, @image_id)]
      )

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok
  end

  test "rejects missing and contradictory top-level image accessibility policies" do
    design_document = image_document()

    missing_policy =
      contract(public_attrs: [attr("image")])

    missing_policy_plan =
      plan(missing_policy, design_document,
        render_projections: [render_attr("image", :asset_src, @image_id)]
      )

    assert "componentization_plan.accessibility.image_policy_missing" in codes(
             ComponentizationPlan.validate_references(
               missing_policy_plan,
               missing_policy,
               design_document
             )
           )

    invalid_policy = %{
      "image_alt_policy" => "consumer_supplied",
      "alt_attr_name" => "alt",
      "required_when_source_present" => false
    }

    invalid_contract =
      contract(public_attrs: [attr("image", :string, accessibility: invalid_policy), attr("alt")])

    invalid_plan =
      plan(invalid_contract, design_document,
        render_projections: [
          render_attr("image", :asset_src, @image_id),
          render_attr("alt", :asset_alt, @image_id)
        ]
      )

    assert "componentization_plan.accessibility.image_policy_invalid" in codes(
             ComponentizationPlan.validate_references(
               invalid_plan,
               invalid_contract,
               design_document
             )
           )

    decorative_contract =
      contract(
        public_attrs: [
          attr("image", :string,
            accessibility: %{"image_alt_policy" => "decorative", "alt_attr_name" => "alt"}
          ),
          attr("alt")
        ]
      )

    decorative_plan =
      plan(decorative_contract, design_document,
        render_projections: [
          render_attr("image", :asset_src, @image_id),
          render_attr("alt", :asset_alt, @image_id)
        ]
      )

    assert "componentization_plan.accessibility.image_policy_invalid" in codes(
             ComponentizationPlan.validate_references(
               decorative_plan,
               decorative_contract,
               design_document
             )
           )
  end

  test "validates collection-item image accessibility through sibling binding projections" do
    design_document = image_document()

    collection_binding = %CollectionBinding{
      collection_binding_id: "cb_members",
      owner_node_id: @boundary_id,
      repeat_root_node_id: @image_id
    }

    image_binding =
      value_binding("vb_image", @image_id,
        target_kind: :asset,
        scope: :collection_item,
        collection_binding_id: "cb_members",
        value_key: "photo"
      )

    alt_binding =
      value_binding("vb_alt", @image_id,
        target_kind: :text,
        scope: :collection_item,
        collection_binding_id: "cb_members",
        value_key: "alt"
      )

    design_document = %{
      design_document
      | collection_bindings: %{"cb_members" => collection_binding},
        value_bindings: %{"vb_image" => image_binding, "vb_alt" => alt_binding}
    }

    accessibility = %{
      "image_alt_policy" => "consumer_supplied",
      "alt_item_field_name" => "alt",
      "required_when_source_present" => true
    }

    component_contract =
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
            target_node_id: @image_id
          },
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_image",
            projection_kind: :collection_item_field,
            source_collection_binding_id: "cb_members",
            item_field_name: "photo",
            target_node_id: @image_id
          },
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_alt",
            projection_kind: :collection_item_field,
            source_collection_binding_id: "cb_members",
            item_field_name: "alt",
            target_node_id: @image_id
          }
        ]
      )

    component_plan = plan(component_contract, design_document)

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok

    missing_alt_projection = %{
      component_contract
      | binding_projections:
          Enum.reject(component_contract.binding_projections, &(&1.source_binding_id == "vb_alt"))
    }

    assert "componentization_plan.accessibility.alt_item_projection_mismatch" in codes(
             ComponentizationPlan.validate_references(
               plan(missing_alt_projection, design_document),
               missing_alt_projection,
               design_document
             )
           )
  end

  test "applies collection-item image validation to nested CollectionInputs" do
    design_document = document()
    [boundary, outside] = design_document.root_nodes
    [heading, paragraph, actions] = boundary.children
    child_image_id = DesignNode.deterministic_id([1, 3, 1])
    image_child = %{hd(actions.children) | semantic_type: "image"}
    actions = %{actions | children: [image_child]}

    design_document = %{
      design_document
      | root_nodes: [%{boundary | children: [heading, paragraph, actions]}, outside]
    }

    parent_collection = %CollectionBinding{
      collection_binding_id: "cb_parent",
      owner_node_id: @boundary_id,
      repeat_root_node_id: @actions_id
    }

    child_collection = %CollectionBinding{
      collection_binding_id: "cb_child",
      owner_node_id: child_image_id,
      repeat_root_node_id: child_image_id,
      parent_collection_binding_id: "cb_parent"
    }

    image_binding =
      value_binding("vb_nested_image", child_image_id,
        target_kind: :asset,
        scope: :collection_item,
        collection_binding_id: "cb_child",
        value_key: "photo"
      )

    alt_binding =
      value_binding("vb_nested_alt", child_image_id,
        target_kind: :text,
        scope: :collection_item,
        collection_binding_id: "cb_child",
        value_key: "alt"
      )

    design_document = %{
      design_document
      | collection_bindings: %{
          "cb_parent" => parent_collection,
          "cb_child" => child_collection
        },
        value_bindings: %{"vb_nested_image" => image_binding, "vb_nested_alt" => alt_binding}
    }

    accessibility = %{
      "image_alt_policy" => "consumer_supplied",
      "alt_item_field_name" => "alt",
      "required_when_source_present" => true
    }

    component_contract =
      contract(
        public_attrs: [attr("members", :list)],
        collection_inputs: [
          %CollectionInput{
            source_collection_binding_id: "cb_parent",
            public_attr_name: "members",
            item_fields: [%ItemField{name: "features", type: :list, semantic_purpose: "features"}]
          },
          %CollectionInput{
            source_collection_binding_id: "cb_child",
            parent_collection_binding_id: "cb_parent",
            parent_item_field_name: "features",
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
            source_binding_id: "cb_parent",
            projection_kind: :collection_attr,
            public_attr_name: "members",
            source_collection_binding_id: "cb_parent",
            target_node_id: @actions_id
          },
          %BindingProjection{
            source_binding_kind: :collection,
            source_binding_id: "cb_child",
            projection_kind: :collection_item_field,
            source_collection_binding_id: "cb_child",
            parent_collection_binding_id: "cb_parent",
            parent_item_field_name: "features",
            target_node_id: child_image_id
          },
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_nested_image",
            projection_kind: :collection_item_field,
            source_collection_binding_id: "cb_child",
            item_field_name: "photo",
            target_node_id: child_image_id
          },
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_nested_alt",
            projection_kind: :collection_item_field,
            source_collection_binding_id: "cb_child",
            item_field_name: "alt",
            target_node_id: child_image_id
          }
        ]
      )

    component_plan = plan(component_contract, design_document)

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok
  end

  test "a subtree slot replaces its static subtree but cannot conceal a binding" do
    design_document = document()

    component_contract =
      contract(
        public_slots: [
          %Slot{name: "actions", semantic_purpose: "actions", consumer_responsibility: "caller"}
        ]
      )

    slot_projection = %RenderProjection{
      public_slot_name: "actions",
      target_node_id: @actions_id,
      render_role: :subtree_slot
    }

    component_plan =
      plan(component_contract, design_document, render_projections: [slot_projection])

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok

    action_child_id = DesignNode.deterministic_id([1, 3, 1])

    bound_document = %{
      design_document
      | value_bindings: %{"vb_action" => value_binding("vb_action", action_child_id)}
    }

    bound_contract =
      contract(
        public_attrs: [attr("label")],
        public_slots: component_contract.public_slots,
        binding_projections: [binding_projection("vb_action", "label", action_child_id)]
      )

    bound_plan = plan(bound_contract, bound_document, render_projections: [slot_projection])

    assert "componentization_plan.slot.subtree_conflict" in codes(
             ComponentizationPlan.validate_references(bound_plan, bound_contract, bound_document)
           )
  end

  test "a subtree slot cannot contain another render projection" do
    design_document = document()
    button_id = DesignNode.deterministic_id([1, 3, 1])

    component_contract =
      contract(
        public_slots: [
          %Slot{name: "actions", semantic_purpose: "actions", consumer_responsibility: "caller"},
          %Slot{name: "primary", semantic_purpose: "primary", consumer_responsibility: "caller"}
        ]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [
          %RenderProjection{
            public_slot_name: "actions",
            target_node_id: @actions_id,
            render_role: :subtree_slot
          },
          %RenderProjection{
            public_slot_name: "primary",
            target_node_id: button_id,
            render_role: :subtree_slot
          }
        ]
      )

    assert "componentization_plan.slot.subtree_conflict" in codes(
             ComponentizationPlan.validate_references(
               component_plan,
               component_contract,
               design_document
             )
           )
  end

  test "reports evidence-insufficient bindings in the plan diagnostic namespace" do
    design_document = %{
      document()
      | value_bindings: %{
          "vb_title" =>
            value_binding("vb_title", @heading_id,
              normalization_status: :evidence_insufficient,
              modifier_status: :opaque
            )
        }
    }

    component_contract =
      contract(
        public_attrs: [attr("title")],
        binding_projections: [binding_projection("vb_title", "title")]
      )

    assert "componentization_plan.binding.evidence_insufficient" in codes(
             ComponentizationPlan.validate_references(
               plan(component_contract, design_document),
               component_contract,
               design_document
             )
           )
  end

  test "generation requires an approved contract and blocks stored errors" do
    design_document = document()
    approved = contract()
    valid_plan = plan(approved, design_document)

    assert ComponentizationPlan.validate_for_generation(valid_plan, approved, design_document) ==
             :ok

    proposed = %{approved | approval_status: :proposed}

    assert {:error, approval_diagnostics} =
             ComponentizationPlan.validate_for_generation(valid_plan, proposed, design_document)

    assert Enum.any?(
             approval_diagnostics,
             &(&1.code == "componentization_plan.generation_blocked")
           )

    stored = %Diagnostic{
      code: "componentization_plan.review.required",
      severity: :error,
      message: "review required"
    }

    blocked_plan = %{valid_plan | diagnostics: [stored]}

    assert {:error, blocked_diagnostics} =
             ComponentizationPlan.validate_for_generation(blocked_plan, approved, design_document)

    assert Enum.any?(
             blocked_diagnostics,
             &(&1.code == "componentization_plan.generation_blocked")
           )
  end

  test "info and warning plan diagnostics do not block generation" do
    design_document = document()
    component_contract = contract()
    base_plan = plan(component_contract, design_document)

    for severity <- [:info, :warning] do
      stored = %Diagnostic{
        code: "componentization_plan.review.note",
        severity: severity,
        message: "non-blocking note"
      }

      assert ComponentizationPlan.validate_for_generation(
               %{base_plan | diagnostics: [stored]},
               component_contract,
               design_document
             ) == :ok
    end
  end

  test "binding-backed slots satisfy placement and remain generation-blocked" do
    design_document = %{
      document()
      | value_bindings: %{"vb_actions" => value_binding("vb_actions", @actions_id)}
    }

    component_contract =
      contract(
        public_slots: [
          %Slot{name: "actions", semantic_purpose: "actions", consumer_responsibility: "caller"}
        ],
        binding_projections: [
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_actions",
            projection_kind: :slot,
            public_slot_name: "actions",
            target_node_id: @actions_id
          }
        ]
      )

    component_plan = plan(component_contract, design_document)

    assert "componentization_plan.slot.binding_backed_unsupported" in codes(
             ComponentizationPlan.validate_references(
               component_plan,
               component_contract,
               design_document
             )
           )

    assert {:error, diagnostics} =
             ComponentizationPlan.validate_for_generation(
               component_plan,
               component_contract,
               design_document
             )

    assert Enum.any?(
             diagnostics,
             &(&1.code == "componentization_plan.slot.binding_backed_unsupported")
           )
  end

  test "malformed plans, contracts and documents fail closed without raising" do
    malformed_plan = %ComponentizationPlan{
      contract_id: "hero-contract",
      design_document_sha256: String.duplicate("a", 64),
      boundary_node_id: @boundary_id,
      render_projections: [%{}],
      diagnostics: :invalid,
      provenance: %{bad: self()}
    }

    assert {:error, _} =
             ComponentizationPlan.validate_references(malformed_plan, contract(), document())

    assert {:error, _} =
             ComponentizationPlan.validate_for_generation(malformed_plan, contract(), document())

    assert {:error, _} =
             ComponentizationPlan.validate_references(
               plan(contract(), document()),
               %{},
               document()
             )

    assert {:error, _} =
             ComponentizationPlan.validate_references(
               plan(contract(), document()),
               contract(),
               %{}
             )
  end
end
