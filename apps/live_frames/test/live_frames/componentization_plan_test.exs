defmodule LiveFrames.ComponentizationPlanTest do
  use ExUnit.Case, async: true

  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.Diagnostic
  alias LiveFrames.ComponentizationPlan.RenderProjection
  alias LiveFrames.ComponentizationPlan.Serializer
  alias LiveFrames.ComponentizationPlan.ValidationError

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

  test "the serializer to_map API returns diagnostics for malformed plans" do
    malformed = valid_plan(render_projections: [%{}])
    assert {:error, diagnostics} = Serializer.to_map(malformed)
    assert Enum.any?(diagnostics, &(&1.code == "componentization_plan.render_projection.invalid"))
  end
end
