defmodule LiveFrames.ComponentizationPlanTest do
  use ExUnit.Case, async: true

  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.Diagnostic
  alias LiveFrames.ComponentizationPlan.RenderProjection
  alias LiveFrames.ComponentizationPlan.Serializer
  alias LiveFrames.ComponentizationPlan.ValidationError

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentContract.Slot
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.ValueBinding

  defp native_tuple(node, attrs \\ [], projections \\ [], bindings \\ []) do
    document = %DesignDocument{root_nodes: [node]}

    contract = %ComponentContract{
      contract_id: "native",
      module_intent: "native",
      function_intent: "native",
      public_attrs: attrs,
      binding_projections: bindings
    }

    {:ok, fingerprint} = ComponentizationPlan.design_document_sha256(document)

    plan = %ComponentizationPlan{
      contract_id: contract.contract_id,
      design_document_sha256: fingerprint,
      boundary_node_id: node.node_id,
      render_projections: projections
    }

    {plan, contract, document}
  end

  defp native_result({plan, contract, document}),
    do: ComponentizationPlan.validate_generation_prerequisites(plan, contract, document)

  defp assert_native_block(tuple, suffix) do
    {plan, contract, document} = tuple
    assert ComponentizationPlan.validate_references(plan, contract, document) == :ok
    assert {:error, diagnostics} = native_result(tuple)

    assert Enum.any?(
             diagnostics,
             &(&1.code == "componentization_plan.native_generation." <> suffix)
           )

    assert Enum.all?(diagnostics, &String.starts_with?(&1.code, "componentization_plan."))
  end

  test "C0 blocks icons only inside the selected boundary, including slot descendants" do
    icon = %DesignNode{node_id: "node_000001_000001", semantic_type: "icon"}
    root = %DesignNode{node_id: "node_000001", semantic_type: "section", children: [icon]}
    assert_native_block(native_tuple(root), "icon_unsupported")

    {plan, contract, document} = native_tuple(%{root | children: []})
    document = %{document | root_nodes: document.root_nodes ++ [%{icon | node_id: "node_000002"}]}
    {:ok, fingerprint} = ComponentizationPlan.design_document_sha256(document)

    assert native_result({%{plan | design_document_sha256: fingerprint}, contract, document}) ==
             :ok

    actions = %{
      root
      | children: [
          %DesignNode{
            node_id: "node_000001_000001",
            semantic_type: "actions",
            children: [%{icon | node_id: "node_000001_000001_000001"}]
          }
        ]
    }

    slot = %Slot{name: "actions", semantic_purpose: "actions", consumer_responsibility: "markup"}

    projection = %RenderProjection{
      public_slot_name: "actions",
      target_node_id: "node_000001_000001",
      render_role: :subtree_slot
    }

    {plan, contract, document} = native_tuple(actions, [], [projection])
    assert_native_block({plan, %{contract | public_slots: [slot]}, document}, "icon_unsupported")
  end

  test "C0 rejects incompatible, malformed and missing native tags without changing references" do
    for {semantic, tag} <- [
          {"container", "nav"},
          {"paragraph", "div"},
          {"link", "a"},
          {"image", "img"},
          {"rich_text", nil},
          {"rich_text", "section"},
          {"section", false}
        ] do
      attributes = if is_nil(tag), do: %{}, else: %{"tag" => tag}
      node = %DesignNode{node_id: "node_000001", semantic_type: semantic, attributes: attributes}
      tuple = if semantic == "image", do: native_image_tuple(node, true), else: native_tuple(node)
      assert_native_block(tuple, "tag_unsupported")
    end
  end

  test "C0 accepts every frozen structural and rich text tag" do
    for {semantic, tags} <- [
          {"section", [nil, "section", "div"]},
          {"container", [nil, "div"]},
          {"wrapper", [nil, "div"]},
          {"stack", [nil, "div"]},
          {"grid", [nil, "div"]},
          {"generic", [nil, "div"]},
          {"background", [nil, "div"]},
          {"overlay", [nil, "div"]},
          {"actions", [nil, "div"]},
          {"paragraph", [nil, "p"]},
          {"rich_text", ["div", "p", "span"]},
          {"button", [nil, "button"]},
          {"link", [nil]}
        ],
        tag <- tags do
      attributes = if is_nil(tag), do: %{}, else: %{"tag" => tag}

      assert native_result(
               native_tuple(%DesignNode{
                 node_id: "node_000001",
                 semantic_type: semantic,
                 attributes: attributes,
                 content: "Text"
               })
             ) == :ok
    end
  end

  defp native_image_tuple(node, required, default \\ nil) do
    source = %Attr{
      name: "image",
      type: :string,
      semantic_purpose: "image",
      required: required,
      default: default,
      accessibility: %{"image_alt_policy" => "decorative"}
    }

    projection = %RenderProjection{
      public_attr_name: "image",
      target_node_id: node.node_id,
      render_role: :asset_src
    }

    native_tuple(node, [source], [projection])
  end

  test "C0 blocks an optional boundary image but admits explicit defaults and optional child images" do
    image = %DesignNode{node_id: "node_000001", semantic_type: "image"}
    assert_native_block(native_image_tuple(image, false), "boundary_optional_image")
    assert native_result(native_image_tuple(image, true)) == :ok
    assert native_result(native_image_tuple(image, false, "/image.jpg")) == :ok
    {plan, contract, document} = native_image_tuple(image, false)

    root = %DesignNode{
      node_id: "node_000001",
      semantic_type: "section",
      children: [%{image | node_id: "node_000001_000001"}]
    }

    document = %{document | root_nodes: [root]}
    [projection] = plan.render_projections
    plan = %{plan | render_projections: [%{projection | target_node_id: "node_000001_000001"}]}
    {:ok, fingerprint} = ComponentizationPlan.design_document_sha256(document)

    assert native_result(
             {%{plan | boundary_node_id: "node_000001", design_document_sha256: fingerprint},
              contract, document}
           ) == :ok
  end

  test "C0 blocks a slot replacing the component boundary" do
    node = %DesignNode{node_id: "node_000001", semantic_type: "actions"}

    projection = %RenderProjection{
      public_slot_name: "actions",
      target_node_id: "node_000001",
      render_role: :subtree_slot
    }

    {plan, contract, document} = native_tuple(node, [], [projection])
    slot = %Slot{name: "actions", semantic_purpose: "actions", consumer_responsibility: "markup"}

    assert_native_block(
      {plan, %{contract | public_slots: [slot]}, document},
      "boundary_subtree_slot"
    )
  end

  test "C0 static navigation uses shared safety validation for links and buttons" do
    for semantic <- ["link", "button"],
        navigation <- [
          nil,
          false,
          %{},
          %{"href" => "javascript:alert(1)"},
          %{"href" => "bad host"}
        ] do
      node = %DesignNode{
        node_id: "node_000001",
        semantic_type: semantic,
        content: "Go",
        attributes: %{"navigation" => navigation}
      }

      assert_native_block(native_tuple(node), "static_navigation_invalid")
    end

    for semantic <- ["link", "button"], href <- ["#", "/path", "https://example.com/path"] do
      node = %DesignNode{
        node_id: "node_000001",
        semantic_type: semantic,
        content: "Go",
        attributes: %{"navigation" => %{"href" => href, "target" => "_blank"}}
      }

      assert native_result(native_tuple(node)) == :ok
    end
  end

  test "C0 public link URL suppresses internal navigation validation" do
    node = %DesignNode{
      node_id: "node_000001",
      semantic_type: "link",
      content: "Go",
      attributes: %{"navigation" => %{"href" => "javascript:ignored"}}
    }

    attr = %Attr{name: "destination", type: :string, semantic_purpose: "destination"}

    projection = %RenderProjection{
      public_attr_name: "destination",
      target_node_id: "node_000001",
      render_role: :link_url
    }

    assert native_result(native_tuple(node, [attr], [projection])) == :ok
  end

  test "C0 public heading level cannot borrow the static tag as a default" do
    node = %DesignNode{
      node_id: "node_000001",
      semantic_type: "heading",
      attributes: %{"tag" => "h2"}
    }

    attr = %Attr{
      name: "level",
      type: :integer,
      semantic_purpose: "level",
      validation: %{"values" => [1, 2, 3, 4, 5, 6]}
    }

    projection = %RenderProjection{
      public_attr_name: "level",
      target_node_id: "node_000001",
      render_role: :heading_level
    }

    assert_native_block(native_tuple(node, [attr], [projection]), "heading_level_optional")
    assert native_result(native_tuple(node)) == :ok

    for accepted <- [%{attr | required: true}, %{attr | default: 3}] do
      assert native_result(native_tuple(node, [accepted], [projection])) == :ok

      assert native_result(native_tuple(%{node | attributes: %{}}, [accepted], [projection])) ==
               :ok
    end
  end

  test "C0 rejects a binding without a frozen native emission row" do
    node = %DesignNode{node_id: "node_000001", semantic_type: "button", content: "Static"}
    attr = %Attr{name: "label", type: :string, semantic_purpose: "label"}

    projection = %BindingProjection{
      source_binding_kind: :value,
      source_binding_id: "value",
      projection_kind: :scalar_attr,
      public_attr_name: "label",
      target_node_id: "node_000001"
    }

    {plan, contract, document} = native_tuple(node, [attr], [], [projection])

    binding = %ValueBinding{
      value_binding_id: "value",
      target_node_id: "node_000001",
      target_kind: :text,
      value_kind: :field,
      scope: :site,
      value_key: "text"
    }

    document = %{document | value_bindings: %{"value" => binding}}
    {:ok, fingerprint} = ComponentizationPlan.design_document_sha256(document)

    assert_native_block(
      {%{plan | design_document_sha256: fingerprint}, contract, document},
      "binding_emission_unsupported"
    )
  end

  defp valid_plan(attrs \\ []) do
    struct!(
      %ComponentizationPlan{
        contract_id: "hero",
        design_document_sha256: String.duplicate("a", 64),
        boundary_node_id: "node_000001"
      },
      attrs
    )
  end

  test "exposes only the versioned plan fields with stable defaults" do
    plan = %ComponentizationPlan{}

    assert ComponentizationPlan.current_format_version() == "1.0.0"
    assert plan.plan_format_version == "1.0.0"
    assert plan.render_projections == []
    assert plan.diagnostics == []
    assert plan.provenance == %{}

    assert Map.keys(plan) |> Enum.sort() ==
             [
               :__struct__,
               :boundary_node_id,
               :contract_id,
               :design_document_sha256,
               :diagnostics,
               :plan_format_version,
               :provenance,
               :render_projections
             ]
  end

  test "validates an empty structural plan" do
    assert ComponentizationPlan.validate(valid_plan()) == :ok
  end

  test "nested JSON surfaces reject invalid UTF-8 without raising" do
    diagnostic = %Diagnostic{code: "componentization_plan.note", message: "Note"}

    for value <- [
          %{<<255>> => "v"},
          %{"k" => <<255>>},
          %{nested: [1 | :tail]},
          %{nested: [[], %{key: [true | "tail"]}]},
          %{:foo => 1, "foo" => 2}
        ] do
      for plan <- [
            valid_plan(provenance: value),
            valid_plan(diagnostics: [%{diagnostic | metadata: value}])
          ] do
        assert {:error, diagnostics} = ComponentizationPlan.validate(plan)
        assert Enum.any?(diagnostics, &(&1.code == "componentization_plan.metadata.invalid"))
        assert ComponentizationPlan.validate(plan) == {:error, diagnostics}
        assert {:error, _} = ComponentizationPlan.encode(plan)
      end
    end
  end

  test "serialized ordinary plan strings require valid UTF-8" do
    projection = %RenderProjection{
      public_attr_name: "label",
      target_node_id: "node",
      render_role: :text_content
    }

    diagnostic = %Diagnostic{code: "componentization_plan.note", message: "Note"}

    plans =
      for field <- [
            :plan_format_version,
            :contract_id,
            :design_document_sha256,
            :boundary_node_id
          ],
          do: Map.put(valid_plan(), field, <<255>>)

    projections =
      for field <- [:public_attr_name, :public_slot_name, :target_node_id],
          do: valid_plan(render_projections: [Map.put(projection, field, <<255>>)])

    diagnostics =
      for field <- [:message, :path, :suggested_action],
          do: valid_plan(diagnostics: [Map.put(diagnostic, field, <<255>>)])

    bad_code =
      valid_plan(diagnostics: [%{diagnostic | code: "componentization_plan." <> <<255>>}])

    for plan <- plans ++ projections ++ diagnostics ++ [bad_code] do
      assert {:error, errors} = ComponentizationPlan.validate(plan)
      assert ComponentizationPlan.validate(plan) == {:error, errors}
      assert {:error, _} = ComponentizationPlan.encode(plan)
    end
  end

  test "validated plans encode valid deterministic JSON across supported recursive values" do
    values = [
      nil,
      false,
      true,
      0,
      -123,
      1.5,
      1.0e308,
      "héllo",
      [],
      [1, true, nil],
      %{:foo => %{"bar" => [1, true, nil]}, "baz" => "ok"}
    ]

    projection = %RenderProjection{
      public_attr_name: "label",
      target_node_id: "node",
      render_role: :text_content
    }

    for value <- values do
      plan =
        valid_plan(
          provenance: %{payload: value},
          render_projections: [projection],
          diagnostics: [
            %Diagnostic{
              code: "componentization_plan.note",
              message: "Note",
              path: "páth",
              suggested_action: "Réview",
              metadata: %{payload: value}
            }
          ]
        )

      assert ComponentizationPlan.validate(plan) == :ok
      assert {:ok, encoded} = ComponentizationPlan.encode(plan)
      assert {:ok, _} = Jason.decode(encoded)
      assert ComponentizationPlan.encode(plan) == {:ok, encoded}
    end
  end

  test "validates each closed render role" do
    for role <- ComponentizationPlan.render_roles() do
      projection = %RenderProjection{
        public_attr_name: "value",
        target_node_id: "node_000001",
        render_role: role
      }

      assert ComponentizationPlan.validate(valid_plan(render_projections: [projection])) == :ok
    end
  end

  test "rejects an unsupported render role" do
    projection = %RenderProjection{
      public_attr_name: "value",
      target_node_id: "node_000001",
      render_role: :template
    }

    assert {:error, diagnostics} =
             ComponentizationPlan.validate(valid_plan(render_projections: [projection]))

    assert Enum.any?(diagnostics, &(&1.code == "componentization_plan.render_projection.invalid"))
  end

  test "requires one non-empty public attr or slot target" do
    for projection <- [
          %RenderProjection{
            public_attr_name: "",
            target_node_id: "node_000001",
            render_role: :text_content
          },
          %RenderProjection{
            public_attr_name: "title",
            public_slot_name: "body",
            target_node_id: "node_000001",
            render_role: :text_content
          },
          %RenderProjection{target_node_id: "node_000001", render_role: :text_content},
          %RenderProjection{
            public_slot_name: "body",
            target_node_id: "",
            render_role: :subtree_slot
          }
        ] do
      assert {:error, diagnostics} =
               ComponentizationPlan.validate(valid_plan(render_projections: [projection]))

      assert Enum.any?(
               diagnostics,
               &(&1.code == "componentization_plan.render_projection.invalid")
             )
    end
  end

  test "rejects duplicate attr and slot projection targets" do
    duplicate_attr = %RenderProjection{
      public_attr_name: "title",
      target_node_id: "node_000001",
      render_role: :text_content
    }

    duplicate_slot = %RenderProjection{
      public_slot_name: "actions",
      target_node_id: "node_000001",
      render_role: :subtree_slot
    }

    for projections <- [[duplicate_attr, duplicate_attr], [duplicate_slot, duplicate_slot]] do
      assert {:error, diagnostics} =
               ComponentizationPlan.validate(valid_plan(render_projections: projections))

      assert Enum.any?(
               diagnostics,
               &(&1.code == "componentization_plan.render_projection.duplicate_target")
             )
    end
  end

  test "rejects invalid roots, versions, diagnostics and provenance" do
    malformed = [
      valid_plan(plan_format_version: :future),
      valid_plan(plan_format_version: "2.0.0"),
      valid_plan(contract_id: ""),
      valid_plan(design_document_sha256: String.upcase(String.duplicate("a", 64))),
      valid_plan(design_document_sha256: "abc"),
      valid_plan(boundary_node_id: ""),
      valid_plan(render_projections: :not_a_list),
      valid_plan(render_projections: [%RenderProjection{} | :tail]),
      valid_plan(diagnostics: [%{}]),
      valid_plan(diagnostics: [%Diagnostic{} | :tail]),
      valid_plan(provenance: %{callback: fn -> :unsafe end}),
      valid_plan(provenance: %{:foo => 1, "foo" => 2})
    ]

    Enum.each(malformed, fn plan ->
      assert {:error, [_ | _]} = ComponentizationPlan.validate(plan)
    end)
  end

  test "rejects tuples, structs, improper lists and executable values in JSON metadata" do
    values = [
      %{tuple: {:not, :json}},
      %{nested_struct: %RenderProjection{}},
      %{improper_list: [1 | :tail]},
      %{pid: self()},
      %{reference: make_ref()},
      %{function: fn -> :unsafe end}
    ]

    Enum.each(values, fn provenance ->
      assert {:error, diagnostics} =
               ComponentizationPlan.validate(valid_plan(provenance: provenance))

      assert Enum.any?(diagnostics, &(&1.code == "componentization_plan.metadata.invalid"))
    end)
  end

  test "validates stored plan diagnostic shape but leaves blocking severity to the gate" do
    diagnostic = %Diagnostic{
      code: "componentization_plan.review.required",
      severity: :error,
      message: "review required"
    }

    assert ComponentizationPlan.validate(valid_plan(diagnostics: [diagnostic])) == :ok

    assert {:error, diagnostics} =
             ComponentizationPlan.validate(
               valid_plan(diagnostics: [%{diagnostic | code: "component_contract.invalid"}])
             )

    assert Enum.any?(diagnostics, &(&1.code == "componentization_plan.metadata.invalid"))
  end

  test "encodes deterministically with inert enums and sorted JSON keys" do
    left = valid_plan(provenance: %{"z" => 1, "a" => %{"b" => true, "a" => false}})
    right = valid_plan(provenance: %{"a" => %{"a" => false, :b => true}, "z" => 1})

    assert {:ok, encoded} = ComponentizationPlan.encode(left)
    assert {:ok, ^encoded} = ComponentizationPlan.encode(right)
    map = ComponentizationPlan.to_map(left)
    assert map["design_document_sha256"] == left.design_document_sha256
    assert not String.contains?(encoded, "__struct__")
    assert {:ok, decoded} = Jason.decode(encoded)
    assert decoded["provenance"] == %{"a" => %{"a" => false, "b" => true}, "z" => 1}
  end

  test "preserves render projection list order while serializing role names as strings" do
    first = %RenderProjection{
      public_attr_name: "title",
      target_node_id: "node_000001",
      render_role: :text_content
    }

    second = %RenderProjection{
      public_slot_name: "actions",
      target_node_id: "node_000001_000001",
      render_role: :subtree_slot
    }

    assert {:ok, encoded} =
             ComponentizationPlan.encode(valid_plan(render_projections: [first, second]))

    assert {:ok, decoded} = Jason.decode(encoded)

    assert Enum.map(decoded["render_projections"], & &1["render_role"]) == [
             "text_content",
             "subtree_slot"
           ]

    assert Enum.map(
             decoded["render_projections"],
             &(&1["public_attr_name"] || &1["public_slot_name"])
           ) ==
             ["title", "actions"]
  end

  test "bang validation and encoding raise the plan ValidationError" do
    invalid = valid_plan(contract_id: "")

    assert_raise ValidationError, fn -> ComponentizationPlan.validate!(invalid) end
    assert_raise ValidationError, fn -> ComponentizationPlan.encode!(invalid) end
  end

  test "C0 blocks paragraph child subtrees and structured rich_text content" do
    paragraph =
      %DesignNode{
        node_id: "node_000001",
        semantic_type: "paragraph",
        children: [%DesignNode{node_id: "node_000001_000001", semantic_type: "generic"}]
      }

    assert_native_block(native_tuple(paragraph), "paragraph_children_forbidden")

    rich_text =
      %DesignNode{
        node_id: "node_000001",
        semantic_type: "rich_text",
        attributes: %{"tag" => "div"},
        content: %{"blocks" => []}
      }

    assert_native_block(native_tuple(rich_text), "rich_text_structured_content")
  end

  test "the serializer to_map API returns diagnostics for malformed plans" do
    malformed = valid_plan(render_projections: [%{}])
    assert {:error, diagnostics} = Serializer.to_map(malformed)
    assert Enum.any?(diagnostics, &(&1.code == "componentization_plan.render_projection.invalid"))
  end
end
