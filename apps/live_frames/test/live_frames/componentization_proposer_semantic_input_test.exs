defmodule LiveFrames.ComponentizationProposerSemanticInputTest do
  use ExUnit.Case, async: false

  alias LiveFrames.ComponentizationProposer.SemanticInput, as: Input

  alias LiveFrames.ComponentizationProposer.SemanticInput.{
    ContractIdentityDecision,
    ClassificationDecision,
    BoundaryDecision,
    PublicAttrDecision,
    PublicSlotDecision,
    CollectionAdmissionDecision,
    ItemFieldDecision,
    CollectionCountLinkDecision,
    BindingAssignmentDecision,
    RenderPlacementDecision,
    ImageAccessibilityDecision,
    EvidenceHandlingDecision,
    StaticContentDispositionDecision
  }

  alias LiveFrames.IR.{DesignDocument, DesignNode, CollectionBinding, ValueBinding}

  defp document do
    %DesignDocument{
      root_nodes: [
        %DesignNode{
          node_id: "node_000001",
          semantic_type: "section",
          children: [
            %DesignNode{
              node_id: "node_000001_000001",
              semantic_type: "container",
              children: [
                %DesignNode{node_id: "node_000001_000001_000001", semantic_type: "container"},
                %DesignNode{node_id: "node_000001_000001_000002", semantic_type: "image"}
              ]
            }
          ]
        }
      ]
    }
  end

  defp input(overrides \\ []) do
    struct!(
      %Input{
        contract_identity: %ContractIdentityDecision{contract_id: "card-contract"},
        classification: %ClassificationDecision{
          category: :component,
          module_intent: "Cards",
          function_intent: "card"
        },
        boundary: %BoundaryDecision{boundary_node_id: "node_000001"}
      },
      overrides
    )
  end

  defp attr(name, overrides \\ []) do
    struct!(
      %PublicAttrDecision{
        name: name,
        type: :string,
        required: false,
        default: nil,
        semantic_purpose: "Explicit consumer value",
        validation: %{},
        accessibility: %{},
        provenance: %{}
      },
      overrides
    )
  end

  defp slot(name) do
    %PublicSlotDecision{
      name: name,
      cardinality: "0..1",
      required: false,
      semantic_purpose: "Consumer markup",
      consumer_responsibility: "Supply markup",
      validation: %{},
      accessibility: %{},
      provenance: %{}
    }
  end

  defp field(owner, name, overrides \\ []) do
    struct!(
      %ItemFieldDecision{
        source_collection_binding_id: owner,
        name: name,
        type: :string,
        required: false,
        default: nil,
        semantic_purpose: "Explicit item value",
        validation: %{},
        accessibility: %{},
        provenance: %{}
      },
      overrides
    )
  end

  defp value(id, overrides \\ []) do
    struct!(
      %ValueBinding{
        value_binding_id: id,
        target_node_id: "node_000001",
        target_kind: :text,
        value_kind: :field,
        scope: :site,
        value_key: "opaque"
      },
      overrides
    )
  end

  defp assignment(id, name, overrides \\ []) do
    struct!(
      %BindingAssignmentDecision{
        source_binding_kind: :value,
        source_binding_id: id,
        assignment_kind: :scalar_attr,
        public_attr_name: name
      },
      overrides
    )
  end

  defp render(name, overrides \\ []) do
    struct!(
      %RenderPlacementDecision{
        public_target_kind: :attr,
        public_target_name: name,
        target_node_id: "node_000001",
        render_role: :text_content
      },
      overrides
    )
  end

  defp valid(doc, decisions) do
    assert LiveFrames.IR.validate(doc) == :ok
    assert {:ok, canonical} = Input.validate(decisions, doc)
    canonical
  end

  defp error(decisions, doc \\ document(), suffix \\ "invalid") do
    assert {:error, diagnostics} = Input.validate(decisions, doc)
    assert Enum.any?(diagnostics, &(&1.code == "componentization_proposer.input." <> suffix))
    assert Enum.all?(diagnostics, &(&1.severity == :error))
    diagnostics
  end

  defp collections do
    doc = %{
      document()
      | collection_bindings: %{
          "outer" => %CollectionBinding{
            collection_binding_id: "outer",
            owner_node_id: "node_000001",
            repeat_root_node_id: "node_000001_000001"
          },
          "inner" => %CollectionBinding{
            collection_binding_id: "inner",
            owner_node_id: "node_000001_000001",
            repeat_root_node_id: "node_000001_000001_000001",
            parent_collection_binding_id: "outer"
          }
        }
    }

    decisions =
      input(
        public_attrs: [attr("entries", type: :list)],
        collection_admissions: [
          %CollectionAdmissionDecision{
            source_collection_binding_id: "outer",
            public_attr_name: "entries",
            provenance: %{}
          },
          %CollectionAdmissionDecision{
            source_collection_binding_id: "inner",
            parent_collection_binding_id: "outer",
            parent_item_field_name: "children",
            provenance: %{}
          }
        ],
        item_fields: [field("outer", "children", type: :list)]
      )

    {doc, decisions}
  end

  test "minimal input is explicit and valid" do
    assert valid(document(), input()) == input()
    assert %Input{} = struct(Input)
    assert struct(Input).contract_identity == nil
    assert struct(Input).public_attrs == []
  end

  test "singleton and semantic fields fail closed" do
    for key <- [:contract_identity, :classification, :boundary] do
      error(Map.put(input(), key, nil), document(), "missing_decision")
    end

    for key <- [:semantic_purpose, :validation, :accessibility, :provenance, :required] do
      error(
        input(public_attrs: [Map.put(attr("label"), key, nil)]),
        document(),
        if(key == :semantic_purpose, do: "missing_decision", else: "invalid")
      )
    end

    error(
      input(public_attrs: [%PublicAttrDecision{name: "label"}]),
      document(),
      "missing_decision"
    )

    error(
      input(public_slots: [%{slot("body") | consumer_responsibility: nil}]),
      document(),
      "missing_decision"
    )

    error(%{input() | classification: %{input().classification | category: :unknown}})
    error(input(public_attrs: [attr("label", type: :atom)]))
    error(input(public_slots: [%{slot("body") | cardinality: "0..*"}]))
    error(input(public_attrs: [attr("label", required: true, default: "value")]))
  end

  test "boundary XOR and existing node" do
    error(%{input() | boundary: %BoundaryDecision{boundary_node_id: "missing"}})

    error(
      %{input() | boundary: %BoundaryDecision{multi_root_unsupported: true}},
      document(),
      "multi_root_unsupported"
    )

    error(%{
      input()
      | boundary: %BoundaryDecision{boundary_node_id: "node_000001", multi_root_unsupported: true}
    })
  end

  test "closed record shapes, source vocabulary and JSON safety" do
    error(Map.put(input(), :source_system, "vendor"))
    error(input(public_attrs: [Map.put(attr("label"), :editor_label, "source")]))
    error(input(public_attrs: [Map.from_struct(attr("label"))]))

    for name <- ["bricks_title", "wp_title", "element_1", "post_title", "Not an identifier"] do
      error(input(public_attrs: [attr(name)]))
    end

    for bad <- [
          %{1 => "value"},
          %{true => "value"},
          %{:key => 1, "key" => 2},
          %{key: self()},
          %DesignNode{}
        ] do
      error(input(public_attrs: [attr("label", provenance: bad)]))
      error(input(public_attrs: [attr("label", default: bad)]))
    end

    valid(
      document(),
      input(public_attrs: [attr("label", default: %{key: [nil, true, 1, 1.5, "value"]})])
    )
  end

  test "duplicate identities and public names conflict" do
    error(input(public_attrs: [attr("label"), attr("label")]), document(), "conflict")
    error(input(public_slots: [slot("body"), slot("body")]), document(), "conflict")

    error(
      input(public_attrs: [attr("body")], public_slots: [slot("body")]),
      document(),
      "conflict"
    )

    {doc, decisions} = collections()

    error(
      %{decisions | item_fields: decisions.item_fields ++ decisions.item_fields},
      doc,
      "conflict"
    )

    error(
      %{
        decisions
        | collection_admissions:
            decisions.collection_admissions ++ decisions.collection_admissions
      },
      doc,
      "conflict"
    )
  end

  test "collection admissions and fields agree with IR ownership" do
    {doc, decisions} = collections()
    valid(doc, decisions)
    [root, nested] = decisions.collection_admissions

    for bad <- [
          %{nested | parent_collection_binding_id: "inner"},
          %{nested | parent_item_field_name: "absent"},
          %{nested | public_attr_name: "entries"},
          %{root | source_collection_binding_id: "missing"}
        ] do
      error(%{decisions | collection_admissions: [root, bad]}, doc)
    end

    error(
      %{decisions | collection_admissions: [root, %{root | public_attr_name: nil}]},
      doc,
      "missing_decision"
    )

    error(%{decisions | item_fields: [field("missing", "label")]}, doc)
    error(%{decisions | item_fields: [field("outer", "children", type: :string)]}, doc)
    error(%{decisions | public_attrs: [attr("entries", type: :string)]}, doc)
  end

  test "all seven assignment discriminants resolve and validate their exclusive fields" do
    {doc, decisions} = collections()

    values = [
      value("scalar"),
      value("slot"),
      value("field",
        target_node_id: "node_000001_000001",
        scope: :collection_item,
        collection_binding_id: "outer"
      ),
      value("count",
        value_kind: :collection_count,
        scope: :collection,
        collection_binding_id: "outer",
        value_key: nil
      ),
      value("nested_count",
        target_node_id: "node_000001_000001",
        value_kind: :collection_count,
        scope: :collection,
        collection_binding_id: "inner",
        value_key: nil
      )
    ]

    doc = %{doc | value_bindings: Map.new(values, &{&1.value_binding_id, &1})}

    decisions = %{
      decisions
      | public_attrs:
          decisions.public_attrs ++
            [attr("label"), attr("total", type: :integer, validation: %{"min" => 0})],
        public_slots: [slot("body")],
        item_fields:
          decisions.item_fields ++
            [
              field("outer", "label"),
              field("outer", "total", type: :integer, validation: %{"min" => 0})
            ],
        collection_count_links: [
          %CollectionCountLinkDecision{
            source_collection_binding_id: "outer",
            count_public_name: "total",
            count_value_binding_id: "count"
          },
          %CollectionCountLinkDecision{
            source_collection_binding_id: "inner",
            count_public_name: "total",
            count_value_binding_id: "nested_count"
          }
        ],
        binding_assignments: [
          assignment("scalar", "label"),
          assignment("slot", nil, assignment_kind: :slot, public_slot_name: "body"),
          assignment("outer", "entries",
            source_binding_kind: :collection,
            assignment_kind: :collection_attr,
            source_collection_binding_id: "outer"
          ),
          assignment("inner", nil,
            source_binding_kind: :collection,
            assignment_kind: :collection_item_field_nested_collection,
            source_collection_binding_id: "inner",
            parent_item_field_name: "children"
          ),
          assignment("field", nil,
            assignment_kind: :collection_item_field_value,
            source_collection_binding_id: "outer",
            item_field_name: "label"
          ),
          assignment("count", "total",
            assignment_kind: :collection_count_attr,
            source_collection_binding_id: "outer"
          ),
          assignment("nested_count", nil,
            assignment_kind: :collection_count_item_field,
            source_collection_binding_id: "inner",
            parent_item_field_name: "total"
          )
        ]
    }

    valid(doc, decisions)

    for original <- decisions.binding_assignments,
        bad <- [
          %{original | source_binding_id: "missing"},
          %{original | source_binding_kind: :other},
          %{original | assignment_kind: :other},
          %{original | public_slot_name: "wrong"}
        ] do
      error(%{decisions | binding_assignments: [bad]}, doc)
    end

    for kind <- [
          :collection_attr,
          :collection_item_field_value,
          :collection_item_field_nested_collection,
          :collection_count_attr,
          :collection_count_item_field,
          :slot
        ] do
      error(
        input(
          public_attrs: [attr("label")],
          binding_assignments: [assignment("scalar", "label", assignment_kind: kind)]
        ),
        doc,
        if(kind == :slot, do: "invalid", else: "missing_decision")
      )
    end

    for link <- decisions.collection_count_links do
      error(
        %{decisions | collection_count_links: [%{link | count_value_binding_id: "scalar"}]},
        doc
      )

      error(%{decisions | collection_count_links: [%{link | count_public_name: "absent"}]}, doc)
    end

    for link <- decisions.collection_count_links do
      other_owner = if link.source_collection_binding_id == "outer", do: "inner", else: "outer"

      error(
        %{
          decisions
          | collection_count_links: [%{link | source_collection_binding_id: other_owner}]
        },
        doc
      )

      error(%{decisions | collection_count_links: [link, link]}, doc, "conflict")
    end

    [scalar | _] = decisions.binding_assignments
    error(%{decisions | binding_assignments: [%{scalar | source_binding_kind: :collection}]}, doc)

    error(
      %{
        decisions
        | public_attrs: [
            attr("entries", type: :list),
            attr("label"),
            attr("total", type: :string)
          ]
      },
      doc
    )

    error(%{decisions | binding_assignments: []}, doc)
    error(%{decisions | collection_count_links: []}, doc)
  end

  test "wrong scope and collection ownership cannot become scalar attrs" do
    {doc, decisions} = collections()

    binding =
      value("field",
        target_node_id: "node_000001_000001",
        scope: :collection_item,
        collection_binding_id: "outer"
      )

    doc = %{doc | value_bindings: %{"field" => binding}}

    error(
      %{
        decisions
        | public_attrs: decisions.public_attrs ++ [attr("label")],
          binding_assignments: [assignment("field", "label")]
      },
      doc
    )

    error(
      %{
        decisions
        | item_fields: decisions.item_fields ++ [field("inner", "label")],
          binding_assignments: [
            assignment("field", nil,
              assignment_kind: :collection_item_field_value,
              source_collection_binding_id: "inner",
              item_field_name: "label"
            )
          ]
      },
      doc
    )
  end

  test "one source binding cannot have multiple assignments" do
    doc = %{document() | value_bindings: %{"value" => value("value")}}

    error(
      input(
        public_attrs: [attr("first"), attr("second")],
        binding_assignments: [assignment("value", "first"), assignment("value", "second")]
      ),
      doc,
      "conflict"
    )
  end

  test "binding and render ownership conflict and render references must resolve" do
    doc = %{document() | value_bindings: %{"value" => value("value")}}

    error(
      input(
        public_attrs: [attr("label")],
        binding_assignments: [assignment("value", "label")],
        render_placements: [render("label")]
      ),
      doc,
      "conflict"
    )

    for bad <- [
          render("missing"),
          render("label", target_node_id: "missing"),
          render("label", render_role: :unknown),
          render("label", public_target_kind: :other)
        ] do
      error(input(public_attrs: [attr("label")], render_placements: [bad]))
    end

    valid(
      document(),
      input(
        public_attrs: [attr("label")],
        render_placements: [render("label", render_role: :asset_alt)]
      )
    )
  end

  test "image source via explicit asset_src render requires exactly matching accessibility" do
    policy = %{"image_alt_policy" => "decorative"}

    decisions =
      input(
        public_attrs: [attr("source", accessibility: policy)],
        render_placements: [
          render("source", target_node_id: "node_000001_000001_000002", render_role: :asset_src)
        ]
      )

    image = %ImageAccessibilityDecision{
      target_kind: :attr,
      target_name: "source",
      accessibility: policy
    }

    error(decisions, document(), "missing_decision")
    valid(document(), %{decisions | image_accessibility: [image]})

    error(
      %{
        decisions
        | image_accessibility: [
            %{
              image
              | accessibility: %{
                  "image_alt_policy" => "consumer_supplied",
                  "alt_attr_name" => "alt",
                  "required_when_source_present" => true
                }
            }
          ]
      },
      document(),
      "conflict"
    )

    error(%{decisions | image_accessibility: [image, image]}, document(), "conflict")

    for bad <- [
          %{},
          %{"image_alt_policy" => "unknown"},
          Map.put(policy, "extra", true),
          %{"image_alt_policy" => "consumer_supplied", "alt_attr_name" => "alt"}
        ] do
      error(%{
        decisions
        | public_attrs: [attr("source", accessibility: bad)],
          image_accessibility: [%{image | accessibility: bad}]
      })
    end

    consumer = %{
      "image_alt_policy" => "consumer_supplied",
      "alt_attr_name" => "alt",
      "required_when_source_present" => true
    }

    valid(document(), %{
      decisions
      | public_attrs: [attr("source", accessibility: consumer)],
        image_accessibility: [%{image | accessibility: consumer}]
    })
  end

  test "image source via asset ValueBinding and collection item field" do
    policy = %{"image_alt_policy" => "decorative"}

    doc = %{
      document()
      | value_bindings: %{
          "asset" =>
            value("asset", target_node_id: "node_000001_000001_000002", target_kind: :asset)
        }
    }

    image = %ImageAccessibilityDecision{
      target_kind: :attr,
      target_name: "source",
      accessibility: policy
    }

    decisions =
      input(
        public_attrs: [attr("source", accessibility: policy)],
        binding_assignments: [assignment("asset", "source")]
      )

    error(decisions, doc, "missing_decision")
    valid(doc, %{decisions | image_accessibility: [image]})
    {doc, decisions} = collections()

    doc = %{
      doc
      | value_bindings: %{
          "asset" =>
            value("asset",
              target_node_id: "node_000001_000001_000002",
              target_kind: :asset,
              scope: :collection_item,
              collection_binding_id: "outer"
            )
        }
    }

    decisions = %{
      decisions
      | item_fields: decisions.item_fields ++ [field("outer", "source", accessibility: policy)],
        binding_assignments: [
          assignment("asset", nil,
            assignment_kind: :collection_item_field_value,
            item_field_name: "source",
            source_collection_binding_id: "outer"
          )
        ]
    }

    image = %ImageAccessibilityDecision{
      target_kind: :item_field,
      source_collection_binding_id: "outer",
      target_name: "source",
      accessibility: policy
    }

    error(decisions, doc, "missing_decision")
    valid(doc, %{decisions | image_accessibility: [image]})

    consumer = %{
      "image_alt_policy" => "consumer_supplied",
      "alt_item_field_name" => "alt",
      "required_when_source_present" => true
    }

    valid(doc, %{
      decisions
      | item_fields: [
          field("outer", "children", type: :list),
          field("outer", "source", accessibility: consumer)
        ],
        image_accessibility: [%{image | accessibility: consumer}]
    })
  end

  test "ordinary accessibility alone does not establish image source and extra image decisions fail" do
    policy = %{"image_alt_policy" => "decorative"}
    decisions = input(public_attrs: [attr("label", accessibility: policy)])
    valid(document(), decisions)

    error(%{
      decisions
      | image_accessibility: [
          %ImageAccessibilityDecision{
            target_kind: :attr,
            target_name: "label",
            accessibility: policy
          }
        ]
    })

    doc = %{
      document()
      | value_bindings: %{
          "asset" => value("asset", target_kind: :asset, target_node_id: "node_000001_000001")
        }
    }

    valid(doc, %{decisions | binding_assignments: [assignment("asset", "label")]})
  end

  test "evidence handling is closed and excludes assignment" do
    doc = %{
      document()
      | value_bindings: %{"value" => value("value", normalization_status: :evidence_insufficient)}
    }

    evidence = %EvidenceHandlingDecision{
      source_binding_kind: :value,
      source_binding_id: "value",
      outcome: :omit_public_projection
    }

    decisions = input(evidence_handling: [evidence])
    valid(doc, decisions)

    error(
      %{
        decisions
        | public_attrs: [attr("label")],
          binding_assignments: [assignment("value", "label")]
      },
      doc,
      "conflict"
    )

    error(
      input(public_attrs: [attr("label")], binding_assignments: [assignment("value", "label")]),
      doc,
      "conflict"
    )

    error(%{decisions | evidence_handling: [%{evidence | outcome: :waiver}]}, doc)
    error(%{decisions | evidence_handling: [%{evidence | source_binding_kind: :collection}]}, doc)
    normalized = %{doc | value_bindings: %{"value" => value("value")}}
    error(decisions, normalized)
    valid(doc, input())
  end

  test "static dispositions reference explicit existing targets" do
    for decision <- [
          %StaticContentDispositionDecision{
            target_kind: :internal_node,
            design_node_id: "node_000001"
          },
          %StaticContentDispositionDecision{
            target_kind: :promote_attr,
            public_target_name: "label"
          },
          %StaticContentDispositionDecision{
            target_kind: :promote_slot,
            public_target_name: "body"
          }
        ] do
      valid(
        document(),
        input(
          public_attrs: [attr("label")],
          public_slots: [slot("body")],
          static_content_dispositions: [decision]
        )
      )

      bad =
        if decision.target_kind == :internal_node,
          do: %{decision | design_node_id: "missing"},
          else: %{decision | public_target_name: "missing"}

      error(input(static_content_dispositions: [bad]))
    end
  end

  test "all repeatable families canonicalize independent of caller order" do
    {doc, decisions} = collections()
    values = [value("z"), value("a")]
    doc = %{doc | value_bindings: Map.new(values, &{&1.value_binding_id, &1})}

    decisions = %{
      decisions
      | public_attrs: decisions.public_attrs ++ [attr("z"), attr("a")],
        public_slots: [slot("zslot"), slot("aslot")],
        binding_assignments: [assignment("z", "z"), assignment("a", "a")],
        render_placements: [
          %RenderPlacementDecision{
            public_target_kind: :slot,
            public_target_name: "aslot",
            target_node_id: "node_000001",
            render_role: :subtree_slot
          }
        ],
        static_content_dispositions: [
          %StaticContentDispositionDecision{target_kind: :promote_attr, public_target_name: "z"},
          %StaticContentDispositionDecision{
            target_kind: :internal_node,
            design_node_id: "node_000001"
          }
        ],
        item_fields: decisions.item_fields ++ [field("inner", "z"), field("inner", "a")]
    }

    canonical = valid(doc, decisions)

    reversed =
      Enum.reduce(Input.repeatable_families(), decisions, fn family, acc ->
        Map.update!(acc, family, &Enum.reverse/1)
      end)

    assert valid(doc, reversed) == canonical
    assert Enum.map(canonical.public_attrs, & &1.name) == ["a", "entries", "z"]

    assert Enum.map(canonical.collection_admissions, & &1.source_collection_binding_id) == [
             "inner",
             "outer"
           ]

    assert Enum.map(canonical.binding_assignments, & &1.source_binding_id) == ["a", "z"]
  end

  test "canonical identities, enum ordering and duplicates cover every repeatable family" do
    alias Input.Canonicalization

    families = %{
      public_attrs: [attr("z"), attr("a")],
      public_slots: [slot("z"), slot("a")],
      collection_admissions: [
        %CollectionAdmissionDecision{source_collection_binding_id: "é"},
        %CollectionAdmissionDecision{source_collection_binding_id: "z"}
      ],
      item_fields: [field("z", "a"), field("a", "z"), field("a", "a")],
      collection_count_links: [
        %CollectionCountLinkDecision{source_collection_binding_id: "z"},
        %CollectionCountLinkDecision{source_collection_binding_id: "a"}
      ],
      binding_assignments: [
        assignment("a", "a"),
        assignment("z", "z", source_binding_kind: :collection)
      ],
      render_placements: [render("a", public_target_kind: :slot), render("z")],
      image_accessibility: [
        %ImageAccessibilityDecision{
          target_kind: :item_field,
          source_collection_binding_id: "z",
          target_name: "a"
        },
        %ImageAccessibilityDecision{target_kind: :attr, target_name: "z"},
        %ImageAccessibilityDecision{
          target_kind: :item_field,
          source_collection_binding_id: "a",
          target_name: "z"
        }
      ],
      evidence_handling: [
        %EvidenceHandlingDecision{source_binding_kind: :value, source_binding_id: "z"},
        %EvidenceHandlingDecision{source_binding_kind: :value, source_binding_id: "a"}
      ],
      static_content_dispositions: [
        %StaticContentDispositionDecision{target_kind: :promote_slot, public_target_name: "a"},
        %StaticContentDispositionDecision{target_kind: :promote_attr, public_target_name: "z"},
        %StaticContentDispositionDecision{target_kind: :internal_node, design_node_id: "é"},
        %StaticContentDispositionDecision{target_kind: :internal_node, design_node_id: "z"}
      ]
    }

    decisions = struct!(input(), families)
    {:ok, canonical} = Canonicalization.canonicalize(decisions)

    reversed =
      Enum.reduce(families, decisions, fn {family, ds}, acc ->
        Map.put(acc, family, Enum.reverse(ds))
      end)

    assert Canonicalization.canonicalize(reversed) == {:ok, canonical}

    assert Enum.map(
             canonical.binding_assignments,
             &Canonicalization.identity(:binding_assignments, &1)
           ) == [{:collection, "z"}, {:value, "a"}]

    assert Enum.map(
             canonical.render_placements,
             &Canonicalization.identity(:render_placements, &1)
           ) == [{:attr, "z"}, {:slot, "a"}]

    assert Enum.map(
             canonical.image_accessibility,
             &Canonicalization.identity(:image_accessibility, &1)
           ) == [{:attr, "z"}, {:item_field, "a", "z"}, {:item_field, "z", "a"}]

    assert Enum.map(canonical.collection_admissions, & &1.source_collection_binding_id) == [
             "z",
             "é"
           ]

    assert Enum.map(
             canonical.static_content_dispositions,
             &Canonicalization.identity(:static_content_dispositions, &1)
           ) == [
             {:internal_node, "z"},
             {:internal_node, "é"},
             {:promote_attr, "z"},
             {:promote_slot, "a"}
           ]

    for {family, [decision | _]} <- families do
      assert {:error, diagnostics} =
               Canonicalization.canonicalize(Map.put(input(), family, [decision, decision]))

      assert Enum.all?(diagnostics, &(&1.code == "componentization_proposer.input.conflict"))
    end
  end

  test "invalid decision order has no diagnostic authority" do
    decisions = input(public_attrs: [attr("z", type: :invalid), attr("a", semantic_purpose: nil)])

    assert Input.validate(decisions, document()) ==
             Input.validate(
               %{decisions | public_attrs: Enum.reverse(decisions.public_attrs)},
               document()
             )

    error(input(public_attrs: [Map.delete(attr("label"), :default)]))
    error(%{input() | contract_identity: %ContractIdentityDecision{contract_id: "node_000001"}})
  end

  describe "totality and B0 JSON policy" do
    test "uses ComponentContract.Json rather than local recursive JSON helpers" do
      refute function_exported?(
               LiveFrames.ComponentizationProposer.SemanticInput.Validation,
               :json_value?,
               1
             )

      assert function_exported?(LiveFrames.ComponentContract.Json, :normalize, 1)
      assert function_exported?(LiveFrames.ComponentContract.Json, :object?, 1)
    end

    test "rejects malformed JSON defaults and objects without raising" do
      invalid_utf8 = <<255>>

      for bad_default <- [invalid_utf8, [1 | :tail], [1, [2 | :tail]]] do
        error(input(public_attrs: [attr("label", default: bad_default)]))
      end

      for bad_provenance <- [
            %{"x" => invalid_utf8},
            %{invalid_utf8 => "x"},
            %{:key => 1, "key" => 2}
          ] do
        error(input(public_attrs: [attr("label", provenance: bad_provenance)]))
      end
    end

    test "rejects improper repeatable decision lists without raising" do
      improper = [attr("label") | :tail]

      for family <- Input.repeatable_families() do
        error(Map.put(input(), family, improper))
      end
    end

    test "rejects malformed aggregate missing expected fields without raising" do
      malformed = Map.delete(input(), :boundary)
      assert {:error, _} = Input.validate(malformed, document())
    end

    test "rejects invalid UTF-8 strings without raising" do
      invalid_utf8 = <<255>>

      error(%{input() | contract_identity: %ContractIdentityDecision{contract_id: invalid_utf8}})

      error(%{
        input()
        | classification: %{
            input().classification
            | module_intent: invalid_utf8,
              function_intent: invalid_utf8
          }
      })

      error(input(public_attrs: [attr(invalid_utf8)]))
      error(input(public_slots: [%{slot("body") | name: invalid_utf8}]))
      error(input(public_attrs: [attr("label", semantic_purpose: invalid_utf8)]))

      error(
        input(
          public_attrs: [attr("label")],
          render_placements: [
            %{
              render("label")
              | public_target_name: invalid_utf8
            }
          ]
        )
      )
    end
  end

  test "multiple explicit bindings cannot own the same top-level public attr or slot" do
    doc = %{
      document()
      | value_bindings: %{
          "first" => value("first"),
          "second" => value("second"),
          "slot_a" => value("slot_a"),
          "slot_b" => value("slot_b")
        }
    }

    error(
      input(
        public_attrs: [attr("title"), attr("subtitle")],
        binding_assignments: [
          assignment("first", "title"),
          assignment("second", "title")
        ]
      ),
      doc,
      "conflict"
    )

    error(
      input(
        public_slots: [slot("body"), slot("footer")],
        binding_assignments: [
          assignment("slot_a", nil, assignment_kind: :slot, public_slot_name: "body"),
          assignment("slot_b", nil, assignment_kind: :slot, public_slot_name: "body")
        ]
      ),
      doc,
      "conflict"
    )
  end

  test "many decisions use one node indexing pass, independent of decision count" do
    nodes =
      for n <- 1..128,
          do: %DesignNode{
            node_id: DesignNode.deterministic_id([1, n]),
            semantic_type: "paragraph"
          }

    doc = %{document() | root_nodes: [%{hd(document().root_nodes) | children: nodes}]}

    decisions =
      input(
        public_attrs: for(n <- 1..128, do: attr("value_#{n}")),
        render_placements:
          for(
            n <- 1..128,
            do: render("value_#{n}", target_node_id: DesignNode.deterministic_id([1, n]))
          )
      )

    assert LiveFrames.IR.validate(doc) == :ok
    # A separate process receives trace events. Count non-empty index calls,
    # which correspond exactly to node visits, without timing assertions.
    test_pid = self()
    tracer = spawn_link(fn -> node_index_calls(test_pid, 0) end)
    :erlang.trace_pattern({Input.Validation, :index_nodes, 2}, true, [:local])
    :erlang.trace(self(), true, [:call, {:tracer, tracer}])

    try do
      assert {:ok, _} = Input.validate(decisions, doc)
      :erlang.trace(self(), false, [:call])
      delivered = :erlang.trace_delivered(self())
      assert_receive {:trace_delivered, _, ^delivered}
      send(tracer, :report)
      assert_receive {:node_visits, 129}
    after
      :erlang.trace(self(), false, [:call])
      :erlang.trace_pattern({Input.Validation, :index_nodes, 2}, false, [:local])
      send(tracer, :stop)
    end
  end

  defp node_index_calls(test_pid, count) do
    receive do
      {:trace, _, :call, {Input.Validation, :index_nodes, [[_ | _], _]}} ->
        node_index_calls(test_pid, count + 1)

      {:trace, _, :call, _} ->
        node_index_calls(test_pid, count)

      :report ->
        send(test_pid, {:node_visits, count})

      :stop ->
        :ok
    end
  end
end
