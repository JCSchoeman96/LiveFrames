defmodule LiveFrames.NativeGeneratorV6ProofsTest do
  use ExUnit.Case, async: true

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentContract.CollectionInput
  alias LiveFrames.ComponentContract.ItemField
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.RenderProjection
  alias LiveFrames.IR.CollectionBinding
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.ValueBinding
  alias LiveFrames.IR
  alias LiveFrames.NativeGenerator

  @boundary_id DesignNode.deterministic_id([1])
  @heading_id DesignNode.deterministic_id([1, 1])

  defp section_node(children \\ []) do
    %DesignNode{
      node_id: @boundary_id,
      semantic_type: "section",
      attributes: %{"aria-label" => "Hero"},
      children: children
    }
  end

  defp approved_contract(overrides \\ []) do
    struct!(
      %ComponentContract{
        contract_id: "proof",
        category: :section,
        module_intent: "proof",
        function_intent: "proof",
        approval_status: :approved
      },
      overrides
    )
  end

  defp plan_for(contract, document, overrides \\ []) do
    {:ok, fingerprint} = ComponentizationPlan.design_document_sha256(document)

    struct!(
      %ComponentizationPlan{
        contract_id: contract.contract_id,
        design_document_sha256: fingerprint,
        boundary_node_id: @boundary_id
      },
      overrides
    )
  end

  defp generate_source(contract, plan, document) do
    case NativeGenerator.generate(contract, plan, document) do
      {:ok, bundle} ->
        hd(bundle.artifacts).content

      other ->
        flunk("expected generation success, got #{inspect(other)}")
    end
  end

  test "scalar text BindingProjection renders at target" do
    node =
      section_node([
        %DesignNode{node_id: @heading_id, semantic_type: "heading", attributes: %{"tag" => "h2"}}
      ])

    document = %DesignDocument{root_nodes: [node]}

    c =
      approved_contract(
        public_attrs: [%Attr{name: "title", type: :string, semantic_purpose: "title"}],
        binding_projections: [
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_title",
            projection_kind: :scalar_attr,
            public_attr_name: "title",
            target_node_id: @heading_id
          }
        ]
      )

    document = %{
      document
      | value_bindings: %{
          "vb_title" => %ValueBinding{
            value_binding_id: "vb_title",
            target_node_id: @heading_id,
            target_kind: :text,
            value_kind: :field,
            scope: :site,
            value_key: "title",
            normalization_status: :normalized,
            modifier_status: :none
          }
        }
    }

    p = plan_for(c, document)
    source = generate_source(c, p, document)
    assert source =~ "{Map.get(assigns, :title)}"
  end

  test "optional scalar asset binding omits image unit when src absent" do
    image_id = DesignNode.deterministic_id([1, 1])
    node = section_node([%DesignNode{node_id: image_id, semantic_type: "image"}])
    document = %DesignDocument{root_nodes: [node]}

    c =
      approved_contract(
        public_attrs: [
          %Attr{
            name: "photo",
            type: :string,
            semantic_purpose: "photo",
            accessibility: %{"image_alt_policy" => "decorative"}
          }
        ],
        binding_projections: [
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_photo",
            projection_kind: :scalar_attr,
            public_attr_name: "photo",
            target_node_id: image_id
          }
        ]
      )

    document = %{
      document
      | value_bindings: %{
          "vb_photo" => %ValueBinding{
            value_binding_id: "vb_photo",
            target_node_id: image_id,
            target_kind: :asset,
            value_kind: :field,
            scope: :site,
            value_key: "photo",
            normalization_status: :normalized,
            modifier_status: :none
          }
        }
    }

    p = plan_for(c, document)
    source = generate_source(c, p, document)
    assert source =~ "if (lf_src = Map.get(assigns, :photo)) != nil"
    refute source =~ "<img src={Map.get(assigns, :photo)}"
  end

  test "numeric count min 1.5 is accepted and embedded in helper call" do
    paragraph_id = DesignNode.deterministic_id([1, 1])

    node =
      section_node([
        %DesignNode{
          node_id: paragraph_id,
          semantic_type: "paragraph",
          attributes: %{"tag" => "p"}
        }
      ])

    document = %DesignDocument{root_nodes: [node]}

    c =
      approved_contract(
        public_attrs: [
          %Attr{name: "items", type: :list, semantic_purpose: "items"},
          %Attr{
            name: "total",
            type: :integer,
            semantic_purpose: "total",
            validation: %{"min" => 1.5}
          }
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
            target_node_id: paragraph_id
          },
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_count",
            projection_kind: :collection_count_attr,
            public_attr_name: "total",
            source_collection_binding_id: "cb_x",
            target_node_id: paragraph_id
          }
        ]
      )

    document = %{
      document
      | collection_bindings: %{
          "cb_x" => %CollectionBinding{
            collection_binding_id: "cb_x",
            owner_node_id: @boundary_id,
            repeat_root_node_id: paragraph_id
          }
        },
        value_bindings: %{
          "vb_count" => %ValueBinding{
            value_binding_id: "vb_count",
            target_node_id: paragraph_id,
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
    p = plan_for(c, document)
    source = generate_source(c, p, document)
    assert source =~ "when is_number(min)"
    assert source =~ "lf_validate_count!(Map.get(assigns, :total), 1.5)"
  end

  test "ItemField integer values validation is emitted" do
    document = %DesignDocument{root_nodes: [section_node()]}

    c =
      approved_contract(
        public_attrs: [%Attr{name: "items", type: :list, semantic_purpose: "items"}],
        collection_inputs: [
          %CollectionInput{
            source_collection_binding_id: "cb_a",
            public_attr_name: "items",
            item_fields: [
              %ItemField{
                name: "level",
                type: :integer,
                semantic_purpose: "level",
                validation: %{"values" => [1, 2, 3, 4, 5, 6]}
              }
            ]
          }
        ],
        binding_projections: [
          %BindingProjection{
            source_binding_kind: :collection,
            source_binding_id: "cb_a",
            projection_kind: :collection_attr,
            public_attr_name: "items",
            source_collection_binding_id: "cb_a",
            target_node_id: @boundary_id
          }
        ]
      )

    document = %{
      document
      | collection_bindings: %{
          "cb_a" => %CollectionBinding{
            collection_binding_id: "cb_a",
            owner_node_id: @boundary_id,
            repeat_root_node_id: @boundary_id
          }
        }
    }

    assert :ok = IR.validate(document)
    source = generate_source(c, plan_for(c, document), document)
    assert source =~ "value in 1..6"
  end

  test "safe static aria-label on section boundary" do
    document =
      %DesignDocument{
        root_nodes: [
          section_node([
            %DesignNode{
              node_id: @heading_id,
              semantic_type: "heading",
              attributes: %{"tag" => "h2"}
            }
          ])
        ]
      }

    c =
      approved_contract(
        public_attrs: [%Attr{name: "title", type: :string, semantic_purpose: "title"}]
      )

    p =
      plan_for(c, document,
        render_projections: [
          %RenderProjection{
            public_attr_name: "title",
            target_node_id: @heading_id,
            render_role: :text_content
          }
        ]
      )

    source = generate_source(c, p, document)
    assert source =~ ~s(aria-label="Hero")
  end

  test "rich_text with nil static content generates after plan gate" do
    rt_id = DesignNode.deterministic_id([1, 1])

    node =
      section_node([
        %DesignNode{
          node_id: rt_id,
          semantic_type: "rich_text",
          attributes: %{"tag" => "div"},
          content: nil
        }
      ])

    document = %DesignDocument{root_nodes: [node]}

    c =
      approved_contract(
        public_attrs: [%Attr{name: "body", type: :string, semantic_purpose: "body"}],
        binding_projections: [
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_body",
            projection_kind: :scalar_attr,
            public_attr_name: "body",
            target_node_id: rt_id
          }
        ]
      )

    document = %{
      document
      | value_bindings: %{
          "vb_body" => %ValueBinding{
            value_binding_id: "vb_body",
            target_node_id: rt_id,
            target_kind: :text,
            value_kind: :field,
            scope: :site,
            value_key: "body",
            normalization_status: :normalized,
            modifier_status: :none
          }
        }
    }

    p = plan_for(c, document)
    assert {:ok, _} = NativeGenerator.generate(c, p, document)
  end

  test "float literal round-trips through Literal renderer" do
    assert {:ok, "1.25"} = LiveFrames.NativeGenerator.Literal.render(1.25)
  end

  test "static button navigation emits blank protection" do
    button_id = DesignNode.deterministic_id([1, 1])

    node =
      section_node([
        %DesignNode{
          node_id: button_id,
          semantic_type: "button",
          attributes: %{
            "tag" => "button",
            "navigation" => %{"href" => "/go", "target" => "_blank"}
          },
          content: "Go"
        }
      ])

    document = %DesignDocument{root_nodes: [node]}
    c = approved_contract()
    p = plan_for(c, document)
    source = generate_source(c, p, document)
    assert source =~ ~s(target="_blank")
    assert source =~ ~s(rel="noopener noreferrer")
  end

  test "nested collection count reads parent item field via lf_ci_1 ordinal" do
    paragraph_id = DesignNode.deterministic_id([1, 1])
    container_id = DesignNode.deterministic_id([1, 2])

    node =
      section_node([
        %DesignNode{
          node_id: paragraph_id,
          semantic_type: "paragraph",
          attributes: %{"tag" => "p"}
        },
        %DesignNode{node_id: container_id, semantic_type: "container"}
      ])

    document = %DesignDocument{root_nodes: [node]}

    c =
      approved_contract(
        public_attrs: [%Attr{name: "items", type: :list, semantic_purpose: "items"}],
        collection_inputs: [
          %CollectionInput{
            source_collection_binding_id: "cb_root",
            public_attr_name: "items",
            item_fields: [
              %ItemField{name: "kids", type: :list, semantic_purpose: "kids"},
              %ItemField{
                name: "child_count",
                type: :integer,
                semantic_purpose: "child_count",
                validation: %{"min" => 1}
              }
            ]
          },
          %CollectionInput{
            source_collection_binding_id: "cb_child",
            parent_collection_binding_id: "cb_root",
            parent_item_field_name: "kids",
            count_item_field_name: "child_count"
          }
        ],
        binding_projections: [
          %BindingProjection{
            source_binding_kind: :collection,
            source_binding_id: "cb_root",
            projection_kind: :collection_attr,
            public_attr_name: "items",
            source_collection_binding_id: "cb_root",
            target_node_id: @boundary_id
          },
          %BindingProjection{
            source_binding_kind: :collection,
            source_binding_id: "cb_child",
            projection_kind: :collection_item_field,
            source_collection_binding_id: "cb_child",
            parent_collection_binding_id: "cb_root",
            parent_item_field_name: "kids",
            target_node_id: container_id
          },
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_count",
            projection_kind: :collection_item_field,
            source_collection_binding_id: "cb_child",
            parent_collection_binding_id: "cb_root",
            parent_item_field_name: "child_count",
            target_node_id: paragraph_id
          }
        ]
      )

    document = %{
      document
      | collection_bindings: %{
          "cb_root" => %CollectionBinding{
            collection_binding_id: "cb_root",
            owner_node_id: @boundary_id,
            repeat_root_node_id: @boundary_id
          },
          "cb_child" => %CollectionBinding{
            collection_binding_id: "cb_child",
            owner_node_id: container_id,
            repeat_root_node_id: container_id,
            parent_collection_binding_id: "cb_root"
          }
        },
        value_bindings: %{
          "vb_count" => %ValueBinding{
            value_binding_id: "vb_count",
            target_node_id: paragraph_id,
            target_kind: :text,
            value_kind: :collection_count,
            scope: :collection,
            collection_binding_id: "cb_child",
            normalization_status: :normalized,
            modifier_status: :none
          }
        }
    }

    assert :ok = IR.validate(document)
    source = generate_source(c, plan_for(c, document), document)
    assert source =~ "for lf_ci_1 <- Map.get(assigns, :items)"
    assert source =~ ~s/lf_item_field(lf_ci_1, 1, "child_count")/
    assert source =~ "case lf_item_field(lf_ci_1, 1, \"kids\") do"
    assert source =~ "for lf_ci_2 <- nested_list"
    refute source =~ "lf_item_field(nil, 1,"
    refute source =~ "__lf_missing__"
  end

  defp nested_kids_document(kids_field, inner_content \\ "inner") do
    paragraph_id = DesignNode.deterministic_id([1, 1])
    container_id = DesignNode.deterministic_id([1, 2])

    node =
      section_node([
        %DesignNode{
          node_id: paragraph_id,
          semantic_type: "paragraph",
          attributes: %{"tag" => "p"}
        },
        %DesignNode{
          node_id: container_id,
          semantic_type: "container",
          content: inner_content
        }
      ])

    document = %DesignDocument{root_nodes: [node]}

    c =
      approved_contract(
        public_attrs: [
          %Attr{name: "items", type: :list, semantic_purpose: "items", required: true}
        ],
        collection_inputs: [
          %CollectionInput{
            source_collection_binding_id: "cb_root",
            public_attr_name: "items",
            item_fields: [kids_field]
          },
          %CollectionInput{
            source_collection_binding_id: "cb_child",
            parent_collection_binding_id: "cb_root",
            parent_item_field_name: "kids"
          }
        ],
        binding_projections: [
          %BindingProjection{
            source_binding_kind: :collection,
            source_binding_id: "cb_root",
            projection_kind: :collection_attr,
            public_attr_name: "items",
            source_collection_binding_id: "cb_root",
            target_node_id: @boundary_id
          },
          %BindingProjection{
            source_binding_kind: :collection,
            source_binding_id: "cb_child",
            projection_kind: :collection_item_field,
            source_collection_binding_id: "cb_child",
            parent_collection_binding_id: "cb_root",
            parent_item_field_name: "kids",
            target_node_id: container_id
          }
        ]
      )

    document = %{
      document
      | collection_bindings: %{
          "cb_root" => %CollectionBinding{
            collection_binding_id: "cb_root",
            owner_node_id: @boundary_id,
            repeat_root_node_id: @boundary_id
          },
          "cb_child" => %CollectionBinding{
            collection_binding_id: "cb_child",
            owner_node_id: container_id,
            repeat_root_node_id: container_id,
            parent_collection_binding_id: "cb_root"
          }
        }
    }

    {c, document, container_id}
  end

  test "required nested collection attaches repeat loop to the list case branch" do
    kids = %ItemField{name: "kids", type: :list, semantic_purpose: "kids", required: true}
    {c, document, _container_id} = nested_kids_document(kids)
    assert :ok = IR.validate(document)
    source = generate_source(c, plan_for(c, document), document)

    {list_pos, _} = :binary.match(source, "nested_list when is_list(nested_list)")
    {for_pos, _} = :binary.match(source, "for lf_ci_2 <- nested_list")
    {nil_pos, _} = :binary.match(source, "<% nil -> %>")
    assert list_pos < for_pos
    assert for_pos < nil_pos
  end

  test "optional nested collection omits subtree when kids field is missing" do
    kids = %ItemField{name: "kids", type: :list, semantic_purpose: "kids", required: false}
    {c, document, _container_id} = nested_kids_document(kids)
    assert :ok = IR.validate(document)
    source = generate_source(c, plan_for(c, document), document)
    {nil_pos, _} = :binary.match(source, "<% nil -> %>")
    {list_pos, _} = :binary.match(source, "nested_list when is_list(nested_list)")
    {for_pos, _} = :binary.match(source, "for lf_ci_2 <- nested_list")
    assert nil_pos < list_pos
    assert for_pos > list_pos
  end

  test "nested collection with explicit default empty list uses list branch" do
    kids = %ItemField{
      name: "kids",
      type: :list,
      semantic_purpose: "kids",
      required: false,
      default: []
    }

    {c, document, _container_id} = nested_kids_document(kids)
    assert :ok = IR.validate(document)
    source = generate_source(c, plan_for(c, document), document)
    assert source =~ "{1, \"kids\"} -> []"
    {list_pos, _} = :binary.match(source, "nested_list when is_list(nested_list)")
    {for_pos, _} = :binary.match(source, "for lf_ci_2 <- nested_list")
    assert list_pos < for_pos
  end

  test "nested collection non-list kids value raises deterministic list error" do
    kids = %ItemField{name: "kids", type: :list, semantic_purpose: "kids", required: true}
    {c, document, _container_id} = nested_kids_document(kids)
    assert :ok = IR.validate(document)
    source = generate_source(c, plan_for(c, document), document)
    assert source =~ ~s(raise ArgumentError, "collection item field kids must be a list")
  end

  test "generated lf_item_field rejects non-map items with ArgumentError" do
    kids = %ItemField{name: "kids", type: :list, semantic_purpose: "kids", required: true}
    {c, document, _} = nested_kids_document(kids)
    source = generate_source(c, plan_for(c, document), document)
    assert source =~ "defp lf_item_field(_item, _collection_ordinal, _field) do"
    assert source =~ ~s(raise ArgumentError, "collection item must be a map")
  end

  test "same item field name stays scoped by collection ordinal in generated validators" do
    document = %DesignDocument{root_nodes: [section_node()]}

    c =
      approved_contract(
        public_attrs: [
          %Attr{name: "left", type: :list, semantic_purpose: "left", required: true},
          %Attr{name: "right", type: :list, semantic_purpose: "right", required: true}
        ],
        collection_inputs: [
          %CollectionInput{
            source_collection_binding_id: "cb_a",
            public_attr_name: "left",
            item_fields: [
              %ItemField{name: "code", type: :string, semantic_purpose: "code", required: true}
            ]
          },
          %CollectionInput{
            source_collection_binding_id: "cb_b",
            public_attr_name: "right",
            item_fields: [
              %ItemField{
                name: "code",
                type: :string,
                semantic_purpose: "code",
                required: false,
                default: "guest"
              }
            ]
          }
        ],
        binding_projections: [
          %BindingProjection{
            source_binding_kind: :collection,
            source_binding_id: "cb_a",
            projection_kind: :collection_attr,
            public_attr_name: "left",
            source_collection_binding_id: "cb_a",
            target_node_id: @boundary_id
          },
          %BindingProjection{
            source_binding_kind: :collection,
            source_binding_id: "cb_b",
            projection_kind: :collection_attr,
            public_attr_name: "right",
            source_collection_binding_id: "cb_b",
            target_node_id: @boundary_id
          }
        ]
      )

    document = %{
      document
      | collection_bindings: %{
          "cb_a" => %CollectionBinding{
            collection_binding_id: "cb_a",
            owner_node_id: @boundary_id,
            repeat_root_node_id: @boundary_id
          },
          "cb_b" => %CollectionBinding{
            collection_binding_id: "cb_b",
            owner_node_id: @boundary_id,
            repeat_root_node_id: @boundary_id
          }
        }
    }

    assert :ok = IR.validate(document)
    source = generate_source(c, plan_for(c, document), document)

    assert source =~
             "{1, \"code\"} -> raise ArgumentError, \"missing required collection item field code\""

    assert source =~ "{2, \"code\"} -> \"guest\""
  end

  test "float item field default is emitted in generated collection accessor" do
    document = %DesignDocument{root_nodes: [section_node()]}

    c =
      approved_contract(
        public_attrs: [
          %Attr{name: "items", type: :list, semantic_purpose: "items", required: true}
        ],
        collection_inputs: [
          %CollectionInput{
            source_collection_binding_id: "cb",
            public_attr_name: "items",
            item_fields: [
              %ItemField{
                name: "weight",
                type: :integer,
                semantic_purpose: "weight",
                required: false,
                default: 1.25
              }
            ]
          }
        ],
        binding_projections: [
          %BindingProjection{
            source_binding_kind: :collection,
            source_binding_id: "cb",
            projection_kind: :collection_attr,
            public_attr_name: "items",
            source_collection_binding_id: "cb",
            target_node_id: @boundary_id
          }
        ]
      )

    document = %{
      document
      | collection_bindings: %{
          "cb" => %CollectionBinding{
            collection_binding_id: "cb",
            owner_node_id: @boundary_id,
            repeat_root_node_id: @boundary_id
          }
        }
    }

    assert :ok = IR.validate(document)
    source = generate_source(c, plan_for(c, document), document)
    assert source =~ "{1, \"weight\"} -> 1.25"
  end

  test "optional collection item image source omits image unit before alt evaluation" do
    image_id = DesignNode.deterministic_id([1, 1])
    node = section_node([%DesignNode{node_id: image_id, semantic_type: "image"}])
    document = %DesignDocument{root_nodes: [node]}

    c =
      approved_contract(
        public_attrs: [
          %Attr{name: "items", type: :list, semantic_purpose: "items", required: true}
        ],
        collection_inputs: [
          %CollectionInput{
            source_collection_binding_id: "cb",
            public_attr_name: "items",
            item_fields: [
              %ItemField{
                name: "photo",
                type: :string,
                semantic_purpose: "photo",
                required: false,
                accessibility: %{"image_alt_policy" => "decorative"}
              }
            ]
          }
        ],
        binding_projections: [
          %BindingProjection{
            source_binding_kind: :collection,
            source_binding_id: "cb",
            projection_kind: :collection_attr,
            public_attr_name: "items",
            source_collection_binding_id: "cb",
            target_node_id: @boundary_id
          },
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_photo",
            projection_kind: :collection_item_field,
            source_collection_binding_id: "cb",
            item_field_name: "photo",
            target_node_id: image_id
          }
        ]
      )

    document = %{
      document
      | collection_bindings: %{
          "cb" => %CollectionBinding{
            collection_binding_id: "cb",
            owner_node_id: @boundary_id,
            repeat_root_node_id: @boundary_id
          }
        },
        value_bindings: %{
          "vb_photo" => %ValueBinding{
            value_binding_id: "vb_photo",
            target_node_id: image_id,
            target_kind: :asset,
            value_kind: :field,
            scope: :collection_item,
            collection_binding_id: "cb",
            value_key: "photo",
            normalization_status: :normalized,
            modifier_status: :none
          }
        }
    }

    assert :ok = IR.validate(document)
    source = generate_source(c, plan_for(c, document), document)
    assert source =~ "if (lf_src = lf_item_field(lf_ci_1, 1, \"photo\")) != nil"
  end

  test "required nested collection module source compiles as a Phoenix component" do
    kids = %ItemField{name: "kids", type: :list, semantic_purpose: "kids", required: true}
    {c, document, _} = nested_kids_document(kids)
    source = generate_source(c, plan_for(c, document), document)
    uniq = System.unique_integer([:positive])
    module_name = "LiveFrames.GeneratedNestedProof#{uniq}"
    compiled = String.replace(source, "LiveFrames.Components.Sections.Proof", module_name)
    assert [{module, _binary}] = Code.compile_string(compiled)
    :code.delete(module)
  end
end
