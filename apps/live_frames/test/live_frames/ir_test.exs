defmodule LiveFrames.IRTest do
  use ExUnit.Case, async: true

  alias LiveFrames.IR
  alias LiveFrames.IR.AssetReference
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Diagnostic
  alias LiveFrames.IR.CollectionBinding
  alias LiveFrames.IR.Interaction
  alias LiveFrames.IR.ValueBinding
  alias LiveFrames.IR.ResponsiveOverride
  alias LiveFrames.IR.SourceTrace
  alias LiveFrames.IR.StyleValue

  defp valid_document do
    node_id = DesignNode.deterministic_id([1])

    node = %DesignNode{
      node_id: node_id,
      semantic_type: "section",
      semantic_role: "hero",
      content: %{"headline" => "Hello"},
      styles: %{
        "display" => StyleValue.keyword("flex"),
        "background" => StyleValue.token_ref("color.neutral.ultra_dark"),
        "gap" => StyleValue.calculation("var(--space-content)"),
        "custom" => StyleValue.complex_css(%{"rules" => []}),
        "font_size" => StyleValue.literal(18),
        "unknown" =>
          StyleValue.unresolved("var(--unknown)",
            source_expression: "var(--unknown)",
            metadata: %{"preserved" => true}
          )
      },
      responsive: %{
        "tablet_portrait" => %ResponsiveOverride{
          breakpoint_id: "tablet_portrait",
          source_name: "tablet_portrait",
          resolution_status: :unresolved,
          styles: %{"display" => StyleValue.keyword("grid")}
        }
      },
      asset_refs: ["asset_001"],
      interaction_refs: ["interaction_001"],
      source_trace: %SourceTrace{
        source_type: "design_source",
        source_id: "source-1",
        source_settings: %{"display" => "flex"},
        inference: "role inferred from label"
      }
    }

    %DesignDocument{
      source_metadata: %{"source" => "fixture"},
      token_set: %{"color.neutral.ultra_dark" => "#050505"},
      root_nodes: [node],
      assets: %{
        "asset_001" => %AssetReference{
          asset_id: "asset_001",
          kind: "image",
          uri: "fixture://hero.png",
          status: :resolved
        }
      },
      interactions: %{
        "interaction_001" => %Interaction{
          interaction_id: "interaction_001",
          intent: "toggle_visibility",
          trigger: "click",
          target_node_ids: [node_id],
          parameters: %{"target" => node_id}
        }
      },
      diagnostics: [
        %Diagnostic{
          code: "fixture.notice",
          severity: :warning,
          category: :provenance,
          message: "fixture diagnostic"
        }
      ],
      provenance: %{"source_hash" => "abc123"}
    }
  end

  test "deterministic IDs derive from traversal paths" do
    assert DesignNode.deterministic_id([1]) == "node_000001"
    assert DesignNode.deterministic_id([1, 2]) == "node_000001_000002"
    assert DesignNode.deterministic_id([1, 2]) != DesignNode.deterministic_id([2, 1])
    assert DesignNode.deterministic_id([1, 2]) == DesignNode.deterministic_id([1, 2])

    assert_raise ArgumentError, fn -> DesignNode.deterministic_id([]) end
    assert_raise ArgumentError, fn -> DesignNode.deterministic_id(:root) end
  end

  test "exposes the current supported IR version and uses it by default" do
    assert DesignDocument.current_ir_version() == "3.0.0"
    assert IR.current_ir_version() == DesignDocument.current_ir_version()
    assert DesignDocument.new().ir_version == IR.current_ir_version()
    assert DesignDocument.new().collection_bindings == %{}
    assert DesignDocument.new().value_bindings == %{}
  end

  test "validation rejects non-empty unsupported IR versions" do
    assert {:error, diagnostics} =
             IR.validate(%{valid_document() | ir_version: "4.0.0"})

    assert Enum.any?(diagnostics, &(&1.code == "ir.document.version_unsupported"))
    refute Enum.any?(diagnostics, &(&1.code == "ir.document.version_missing"))
  end

  test "validation keeps empty and malformed versions distinct from unsupported versions" do
    assert {:error, empty_diagnostics} = IR.validate(%{valid_document() | ir_version: ""})
    assert Enum.any?(empty_diagnostics, &(&1.code == "ir.document.version_missing"))

    assert {:error, malformed_diagnostics} =
             IR.validate(%{valid_document() | ir_version: :future})

    assert Enum.any?(malformed_diagnostics, &(&1.code == "ir.document.version_invalid"))

    assert {:error, unsupported_diagnostics} =
             IR.validate(%{valid_document() | ir_version: "4.0.0"})

    assert Enum.any?(unsupported_diagnostics, &(&1.code == "ir.document.version_unsupported"))
  end

  test "unknown is a supported semantic preservation type" do
    node = hd(valid_document().root_nodes)
    unknown_node = %{node | semantic_type: "unknown", children: []}

    assert IR.validate(%{valid_document() | root_nodes: [unknown_node]}) == :ok
  end

  test "validates nested node trees with deterministic child positions" do
    root = hd(valid_document().root_nodes)

    first_child = %DesignNode{
      node_id: DesignNode.deterministic_id([1, 1]),
      semantic_type: "container",
      label: "first child"
    }

    second_child = %DesignNode{
      node_id: DesignNode.deterministic_id([1, 2]),
      semantic_type: "unknown",
      label: "second child",
      children: [
        %DesignNode{
          node_id: DesignNode.deterministic_id([1, 2, 1]),
          semantic_type: "raw",
          content: %{"preserved" => true}
        }
      ]
    }

    document = %{valid_document() | root_nodes: [%{root | children: [first_child, second_child]}]}

    assert IR.validate(document) == :ok
  end

  test "valid IR accepts registries and unresolved responsive entries" do
    document = valid_document()
    override = hd(document.root_nodes).responsive["tablet_portrait"]

    assert IR.validate(document) == :ok
    assert override.resolution_status == :unresolved
    assert override.min_width == nil
    assert override.max_width == nil
    assert override.source_name == "tablet_portrait"

    decoded = document |> IR.encode!() |> Jason.decode!()

    decoded_override =
      get_in(decoded, ["root_nodes", Access.at(0), "responsive", "tablet_portrait"])

    assert decoded_override["resolution_status"] == "unresolved"
    assert decoded_override["min_width"] == nil
    assert decoded_override["max_width"] == nil
    assert decoded_override["source_name"] == "tablet_portrait"
  end

  test "preserves unresolved style values through validation and JSON" do
    document = valid_document()
    unresolved = hd(document.root_nodes).styles["unknown"]

    assert IR.validate(document) == :ok
    assert unresolved.kind == :unresolved
    assert unresolved.value == "var(--unknown)"
    assert unresolved.source_expression == "var(--unknown)"
    assert unresolved.metadata == %{"preserved" => true}

    decoded_style =
      document
      |> IR.encode!()
      |> Jason.decode!()
      |> get_in(["root_nodes", Access.at(0), "styles", "unknown"])

    assert decoded_style["kind"] == "unresolved"
    assert decoded_style["value"] == "var(--unknown)"
    assert decoded_style["source_expression"] == "var(--unknown)"
    assert decoded_style["metadata"] == %{"preserved" => true}
  end

  test "validates and serializes all diagnostic severities with source traces" do
    trace = %SourceTrace{
      source_type: "design_source",
      source_id: "source-1",
      source_path: "root.children[0]",
      source_name: "hero",
      source_classes: ["hero", "layout"],
      source_settings: %{"display" => "flex"},
      adapter: "fixture_adapter",
      adapter_version: "1.0.0",
      inference: "role inferred from label",
      metadata: %{"line" => 12}
    }

    diagnostics =
      Enum.map(Diagnostic.severities(), fn severity ->
        %Diagnostic{
          code: "fixture.#{severity}",
          severity: severity,
          category: :provenance,
          message: "fixture #{severity}",
          source_trace: trace
        }
      end)

    document = %{valid_document() | diagnostics: diagnostics}

    assert IR.validate(document) == :ok

    decoded_diagnostics = document |> IR.encode!() |> Jason.decode!() |> Map.fetch!("diagnostics")

    assert Enum.map(decoded_diagnostics, & &1["severity"]) ==
             Enum.map(Diagnostic.severities(), &Atom.to_string/1)

    assert Enum.all?(decoded_diagnostics, fn diagnostic ->
             diagnostic["source_trace"]["source_id"] == "source-1" and
               diagnostic["source_trace"]["source_name"] == "hero" and
               diagnostic["source_trace"]["source_classes"] == ["hero", "layout"] and
               not Enum.member?(Map.keys(diagnostic["source_trace"]), "global" <> "_classes") and
               diagnostic["source_trace"]["source_settings"] == %{"display" => "flex"} and
               diagnostic["source_trace"]["metadata"] == %{"line" => 12}
           end)
  end

  test "asset URI presence matches the resolved and unresolved lifecycle" do
    document = valid_document()
    asset = Map.fetch!(document.assets, "asset_001")

    assert asset.status == :resolved
    assert is_binary(asset.uri)
    assert IR.validate(document) == :ok

    unresolved_without_uri = %{asset | status: :unresolved, uri: nil}
    assert IR.validate(%{document | assets: %{"asset_001" => unresolved_without_uri}}) == :ok

    unresolved_with_uri = %{asset | status: :unresolved}

    assert {:error, diagnostics} =
             IR.validate(%{document | assets: %{"asset_001" => unresolved_with_uri}})

    assert Enum.any?(diagnostics, &(&1.code == "ir.asset.unresolved_uri_present"))
  end

  test "validation reports duplicate nodes and missing references" do
    node = hd(valid_document().root_nodes)

    invalid_node = %{
      node
      | asset_refs: ["missing_asset"],
        interaction_refs: ["missing_interaction"]
    }

    document = %{valid_document() | root_nodes: [node, invalid_node]}

    assert {:error, diagnostics} = IR.validate(document)
    codes = Enum.map(diagnostics, & &1.code)

    assert "ir.node.id_duplicate" in codes
    assert "ir.node.asset_reference_missing" in codes
    assert "ir.node.interaction_reference_missing" in codes
  end

  test "validation enforces deterministic traversal IDs" do
    node = hd(valid_document().root_nodes)
    invalid_node = %{node | node_id: "source-element-42"}

    assert {:error, diagnostics} = IR.validate(%{valid_document() | root_nodes: [invalid_node]})
    assert Enum.any?(diagnostics, &(&1.code == "ir.node.id_not_deterministic"))
  end

  test "validation rejects JSON object keys that collide after normalization" do
    node = hd(valid_document().root_nodes)

    invalid_node = %{
      node
      | attributes: %{"theme" => "dark", theme: "light"},
        styles: %{"display" => StyleValue.keyword("flex"), display: StyleValue.keyword("grid")}
    }

    asset = valid_document().assets["asset_001"]

    document = %{
      valid_document()
      | root_nodes: [invalid_node],
        assets: %{"asset_001" => asset, asset_001: asset}
    }

    assert {:error, diagnostics} = IR.validate(document)
    assert Enum.any?(diagnostics, &(&1.code == "ir.node.attributes_invalid"))
    assert Enum.any?(diagnostics, &(&1.code == "ir.style.property_duplicate"))
    assert Enum.any?(diagnostics, &(&1.code == "ir.asset.registry_key_duplicate"))
  end

  test "validation reports invalid style values and unresolved breakpoints without source names" do
    node = hd(valid_document().root_nodes)

    invalid_node = %{
      node
      | styles: %{"color" => %StyleValue{kind: :unknown, value: "red"}},
        responsive: %{
          "tablet" => %ResponsiveOverride{
            breakpoint_id: "other",
            resolution_status: :unresolved,
            styles: %{}
          }
        }
    }

    assert {:error, diagnostics} = IR.validate(%{valid_document() | root_nodes: [invalid_node]})
    codes = Enum.map(diagnostics, & &1.code)

    assert "ir.style.kind_invalid" in codes
    assert "ir.responsive.key_mismatch" in codes
    assert "ir.responsive.source_name_missing" in codes
  end

  test "encoding returns stable JSON with explicit tagged values" do
    assert {:ok, first} = IR.encode(valid_document())
    assert {:ok, second} = IR.encode(valid_document())
    assert first == second

    decoded = Jason.decode!(first)
    assert decoded["ir_version"] == "3.0.0"
    assert decoded["collection_bindings"] == %{}
    assert decoded["value_bindings"] == %{}

    assert get_in(decoded, ["root_nodes", Access.at(0), "styles", "background", "kind"]) ==
             "token_ref"

    assert decoded["assets"]["asset_001"]["status"] == "resolved"
    assert decoded["root_nodes"] |> hd() |> get_in(["styles", "unknown", "kind"]) == "unresolved"
    assert hd(decoded["diagnostics"])["severity"] == "warning"
    refute first =~ "__struct__"
  end

  test "validates and deterministically serializes structured calculations" do
    calculation = %{
      "operation" => "multiply",
      "operands" => [
        %{"kind" => "token_ref", "path" => "spacing.grid_gap"},
        %{"kind" => "literal", "value" => 2}
      ]
    }

    node = hd(valid_document().root_nodes)
    style = StyleValue.calculation(calculation, source_expression: "calc(var(--grid-gap) * 2)")
    document = %{valid_document() | root_nodes: [%{node | styles: %{"gap" => style}}]}

    assert IR.validate(document) == :ok
    assert IR.encode!(document) == IR.encode!(document)

    encoded = document |> IR.encode!() |> Jason.decode!()
    encoded_style = get_in(encoded, ["root_nodes", Access.at(0), "styles", "gap"])
    assert encoded_style["value"] == calculation
    assert encoded_style["source_expression"] == "calc(var(--grid-gap) * 2)"
  end

  test "legacy calculation strings remain valid" do
    node = hd(valid_document().root_nodes)

    document = %{
      valid_document()
      | root_nodes: [%{node | styles: %{"gap" => StyleValue.calculation("calc(100% - 1rem)")}}]
    }

    assert IR.validate(document) == :ok
  end

  test "rejects invalid structured calculation shapes" do
    valid = %{
      "operation" => "multiply",
      "operands" => [
        %{"kind" => "token_ref", "path" => "spacing.grid_gap"},
        %{"kind" => "literal", "value" => 2}
      ]
    }

    invalid_values = [
      put_in(valid, ["operation"], "divide"),
      Map.delete(valid, "operation"),
      Map.delete(valid, "operands"),
      put_in(valid, ["operands"], []),
      put_in(valid, ["operands"], [
        hd(valid["operands"]),
        List.last(valid["operands"]),
        List.last(valid["operands"])
      ]),
      put_in(valid, ["operands"], 3),
      put_in(valid, ["operands", Access.at(0), "kind"], "literal"),
      put_in(valid, ["operands", Access.at(0), "path"], ""),
      put_in(valid, ["operands", Access.at(0), "path"], "spacing..grid_gap"),
      put_in(valid, ["operands", Access.at(0), "path"], "var(--grid-gap)"),
      put_in(valid, ["operands", Access.at(0), "path"], "--lf-space-grid-gap"),
      put_in(valid, ["operands", Access.at(0), "extra"], true),
      put_in(valid, ["operands", Access.at(1), "kind"], "token_ref"),
      put_in(valid, ["operands", Access.at(1), "value"], "2"),
      put_in(valid, ["operands", Access.at(1)], %{"kind" => "literal"}),
      put_in(valid, ["operands", Access.at(1)], %{"kind" => "calculation", "value" => valid})
    ]

    for value <- invalid_values do
      node = hd(valid_document().root_nodes)

      document = %{
        valid_document()
        | root_nodes: [%{node | styles: %{"gap" => StyleValue.calculation(value)}}]
      }

      assert {:error, diagnostics} = IR.validate(document)
      assert Enum.any?(diagnostics, &(&1.code == "ir.style.calculation_invalid"))
    end

    for number <- [0, -1, 1.5, 2] do
      valid_number = put_in(valid, ["operands", Access.at(1), "value"], number)
      node = hd(valid_document().root_nodes)

      document = %{
        valid_document()
        | root_nodes: [%{node | styles: %{"gap" => StyleValue.calculation(valid_number)}}]
      }

      assert IR.validate(document) == :ok
    end
  end

  test "encoding is bytewise deterministic for equivalent documents" do
    first_document = %{
      valid_document()
      | source_metadata:
          Map.new([
            {"z", %{"b" => 2, "a" => 1}},
            {"a", %{"d" => 4, "c" => 3}}
          ]),
        provenance: Map.new([{"z", "last"}, {"a", "first"}])
    }

    equivalent_document = %{
      valid_document()
      | source_metadata:
          Map.new([
            {"a", %{"c" => 3, "d" => 4}},
            {"z", %{"a" => 1, "b" => 2}}
          ]),
        provenance: Map.new([{"a", "first"}, {"z", "last"}])
    }

    assert first_document == equivalent_document
    assert IR.encode!(first_document) == IR.encode!(equivalent_document)
  end

  test "encoding rejects invalid documents" do
    invalid = %{valid_document() | root_nodes: [%DesignNode{}]}

    assert {:error, diagnostics} = IR.encode(invalid)
    assert Enum.any?(diagnostics, &(&1.code == "ir.node.id_missing"))
  end

  test "strict validation raises with the collected diagnostics" do
    invalid = %{valid_document() | root_nodes: [%DesignNode{}]}

    assert_raise LiveFrames.IR.ValidationError, fn -> IR.validate!(invalid) end
  end

  defp binding_tree do
    owner_id = DesignNode.deterministic_id([1])
    repeat_id = DesignNode.deterministic_id([1, 1])
    target_id = DesignNode.deterministic_id([1, 1, 1])

    owner = %DesignNode{
      node_id: owner_id,
      semantic_type: "section",
      children: [
        %DesignNode{
          node_id: repeat_id,
          semantic_type: "container",
          children: [
            %DesignNode{node_id: target_id, semantic_type: "heading", content: "Title"}
          ]
        }
      ]
    }

    {owner, owner_id, repeat_id, target_id}
  end

  defp binding_document(overrides \\ []) do
    {owner, owner_id, repeat_id, target_id} = binding_tree()

    collection = %CollectionBinding{
      collection_binding_id: "collection_001",
      owner_node_id: owner_id,
      repeat_root_node_id: repeat_id,
      normalization_status: :normalized
    }

    value = %ValueBinding{
      value_binding_id: "value_001",
      target_node_id: target_id,
      target_kind: :text,
      value_kind: :field,
      scope: :collection_item,
      value_key: "content.title",
      collection_binding_id: "collection_001",
      modifier_status: :none,
      normalization_status: :normalized
    }

    document = %DesignDocument{
      source_metadata: %{},
      token_set: %{},
      root_nodes: [owner],
      collection_bindings: %{"collection_001" => collection},
      value_bindings: %{"value_001" => value}
    }

    struct(document, overrides)
  end

  test "accepts valid collection and value bindings" do
    assert IR.validate(binding_document()) == :ok
  end

  test "rejects collection binding registry key mismatch" do
    document = binding_document()

    invalid =
      put_in(document.collection_bindings, %{
        "wrong_key" => Map.fetch!(document.collection_bindings, "collection_001")
      })

    assert {:error, diagnostics} = IR.validate(invalid)
    assert Enum.any?(diagnostics, &(&1.code == "ir.collection_binding.id_mismatch"))
  end

  test "rejects collection binding with missing nodes" do
    document = binding_document()

    invalid =
      update_in(document.collection_bindings["collection_001"], fn binding ->
        %{binding | owner_node_id: "missing"}
      end)

    assert {:error, diagnostics} = IR.validate(invalid)
    assert Enum.any?(diagnostics, &(&1.code == "ir.collection_binding.owner_missing"))
  end

  test "rejects collection binding parent self-reference and cycles" do
    document = binding_document()

    self_parent =
      update_in(document.collection_bindings["collection_001"], fn binding ->
        %{binding | parent_collection_binding_id: "collection_001"}
      end)

    assert {:error, self_diagnostics} = IR.validate(self_parent)
    assert Enum.any?(self_diagnostics, &(&1.code == "ir.collection_binding.parent_self"))

    nested = %CollectionBinding{
      collection_binding_id: "collection_002",
      owner_node_id: DesignNode.deterministic_id([1, 1, 1]),
      repeat_root_node_id: DesignNode.deterministic_id([1, 1, 1]),
      parent_collection_binding_id: "collection_001",
      normalization_status: :normalized
    }

    cycle_document = %{
      document
      | collection_bindings: %{
          "collection_001" => %{
            document.collection_bindings["collection_001"]
            | parent_collection_binding_id: "collection_002"
          },
          "collection_002" => %{nested | parent_collection_binding_id: "collection_001"}
        }
    }

    assert {:error, cycle_diagnostics} = IR.validate(cycle_document)
    assert Enum.any?(cycle_diagnostics, &(&1.code == "ir.collection_binding.parent_cycle"))
  end

  test "rejects nested collection owner outside parent repeat root" do
    document = binding_document()

    outside_owner = %CollectionBinding{
      collection_binding_id: "collection_002",
      owner_node_id: DesignNode.deterministic_id([1]),
      repeat_root_node_id: DesignNode.deterministic_id([1, 1, 1]),
      parent_collection_binding_id: "collection_001",
      normalization_status: :normalized
    }

    invalid = put_in(document.collection_bindings["collection_002"], outside_owner)

    assert {:error, diagnostics} = IR.validate(invalid)
    assert Enum.any?(diagnostics, &(&1.code == "ir.collection_binding.owner_outside_parent"))
  end

  test "accepts site and collection_count value bindings when valid" do
    {owner, _owner_id, repeat_id, target_id} = binding_tree()
    site_target = DesignNode.deterministic_id([2])

    site_document = %DesignDocument{
      root_nodes: [
        owner,
        %DesignNode{node_id: site_target, semantic_type: "paragraph", content: "count"}
      ],
      collection_bindings: %{
        "collection_001" => %CollectionBinding{
          collection_binding_id: "collection_001",
          owner_node_id: DesignNode.deterministic_id([1]),
          repeat_root_node_id: repeat_id,
          normalization_status: :normalized
        }
      },
      value_bindings: %{
        "value_site" => %ValueBinding{
          value_binding_id: "value_site",
          target_node_id: target_id,
          target_kind: :text,
          value_kind: :field,
          scope: :site,
          value_key: "content.title",
          modifier_status: :none,
          normalization_status: :normalized
        },
        "value_count" => %ValueBinding{
          value_binding_id: "value_count",
          target_node_id: site_target,
          target_kind: :text,
          value_kind: :collection_count,
          scope: :collection,
          collection_binding_id: "collection_001",
          modifier_status: :none,
          normalization_status: :normalized
        }
      }
    }

    assert IR.validate(site_document) == :ok
  end

  test "rejects invalid value binding combinations and containment" do
    document = binding_document()

    invalid_combo =
      update_in(document.value_bindings["value_001"], fn binding ->
        %{binding | scope: :collection}
      end)

    assert {:error, combo_diagnostics} = IR.validate(invalid_combo)
    assert Enum.any?(combo_diagnostics, &(&1.code == "ir.value_binding.combination_invalid"))

    outside_target =
      update_in(document.value_bindings["value_001"], fn binding ->
        %{binding | target_node_id: DesignNode.deterministic_id([1])}
      end)

    assert {:error, target_diagnostics} = IR.validate(outside_target)

    assert Enum.any?(
             target_diagnostics,
             &(&1.code == "ir.value_binding.target_outside_repeat_root")
           )

    opaque_invalid =
      update_in(document.value_bindings["value_001"], fn binding ->
        %{binding | modifier_status: :opaque, normalization_status: :normalized}
      end)

    assert {:error, modifier_diagnostics} = IR.validate(opaque_invalid)
    assert Enum.any?(modifier_diagnostics, &(&1.code == "ir.value_binding.modifier_inconsistent"))
  end

  test "ValueBinding modifier and normalization status matrix matches C09B authority" do
    document = binding_document()

    assert IR.validate(document) == :ok

    evidence_without_modifier =
      update_in(document.value_bindings["value_001"], fn binding ->
        %{binding | modifier_status: :none, normalization_status: :evidence_insufficient}
      end)

    assert IR.validate(evidence_without_modifier) == :ok

    opaque_evidence =
      update_in(document.value_bindings["value_001"], fn binding ->
        %{binding | modifier_status: :opaque, normalization_status: :evidence_insufficient}
      end)

    assert IR.validate(opaque_evidence) == :ok

    opaque_normalized =
      update_in(document.value_bindings["value_001"], fn binding ->
        %{binding | modifier_status: :opaque, normalization_status: :normalized}
      end)

    assert {:error, diagnostics} = IR.validate(opaque_normalized)
    assert Enum.any?(diagnostics, &(&1.code == "ir.value_binding.modifier_inconsistent"))
  end

  test "collection parent graph reports missing parent without crashing cycle analysis" do
    document =
      collection_only_document(
        %{"collection_a" => "missing_collection"},
        %{"collection_a" => "trace_missing_parent"}
      )

    assert {:error, diagnostics} = IR.validate(document)
    assert Enum.any?(diagnostics, &(&1.code == "ir.collection_binding.parent_missing"))
    refute "trace_missing_parent" in parent_cycle_trace_ids(diagnostics)
  end

  test "collection parent graph reports tail to missing parent without cycle diagnostics" do
    document =
      collection_only_document(
        %{
          "collection_a" => "missing_collection",
          "collection_b" => "collection_a"
        },
        %{
          "collection_a" => "trace_missing_parent",
          "collection_b" => "trace_tail_b"
        }
      )

    assert {:error, diagnostics} = IR.validate(document)
    assert Enum.any?(diagnostics, &(&1.code == "ir.collection_binding.parent_missing"))
    refute "trace_missing_parent" in parent_cycle_trace_ids(diagnostics)
    refute "trace_tail_b" in parent_cycle_trace_ids(diagnostics)
  end

  test "long acyclic collection parent chain remains valid" do
    {owner, owner_id, repeat_id, inner_owner_id} = binding_tree()
    depth = 100

    {bindings, last_id} =
      Enum.reduce(1..depth, {%{}, nil}, fn index, {acc, parent_id} ->
        id = "collection_#{index}"

        owner_node_id = if parent_id, do: inner_owner_id, else: owner_id

        binding = %CollectionBinding{
          collection_binding_id: id,
          owner_node_id: owner_node_id,
          repeat_root_node_id: repeat_id,
          parent_collection_binding_id: parent_id,
          normalization_status: :normalized
        }

        {Map.put(acc, id, binding), id}
      end)

    document = %DesignDocument{
      root_nodes: [owner],
      collection_bindings: bindings,
      value_bindings: %{}
    }

    assert IR.validate(document) == :ok
    assert last_id == "collection_100"
  end

  defp collection_only_document(bindings, trace_ids \\ %{}) do
    {owner, owner_id, repeat_id, inner_owner_id} = binding_tree()

    bindings =
      Map.new(bindings, fn {id, parent_id} ->
        owner_node_id = if parent_id, do: inner_owner_id, else: owner_id

        trace =
          case Map.get(trace_ids, id) do
            nil -> nil
            source_id -> %SourceTrace{source_id: source_id}
          end

        {id,
         %CollectionBinding{
           collection_binding_id: id,
           owner_node_id: owner_node_id,
           repeat_root_node_id: repeat_id,
           parent_collection_binding_id: parent_id,
           normalization_status: :normalized,
           source_trace: trace
         }}
      end)

    %DesignDocument{
      root_nodes: [owner],
      collection_bindings: bindings,
      value_bindings: %{}
    }
  end

  defp parent_cycle_trace_ids(diagnostics) do
    diagnostics
    |> Enum.filter(&(&1.code == "ir.collection_binding.parent_cycle"))
    |> Enum.map(fn diagnostic ->
      case diagnostic.source_trace do
        %SourceTrace{source_id: source_id} -> source_id
        _other -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort()
  end

  test "collection parent graph marks only actual cycle members for A ↔ B" do
    document =
      collection_only_document(
        %{
          "collection_a" => "collection_b",
          "collection_b" => "collection_a"
        },
        %{"collection_a" => "trace_cycle_a", "collection_b" => "trace_cycle_b"}
      )

    assert {:error, diagnostics} = IR.validate(document)
    assert parent_cycle_trace_ids(diagnostics) == ["trace_cycle_a", "trace_cycle_b"]
  end

  test "collection parent graph marks only cycle members when a tail enters a cycle" do
    document =
      collection_only_document(
        %{
          "collection_a" => "collection_b",
          "collection_b" => "collection_a",
          "collection_c" => "collection_a",
          "collection_d" => "collection_c"
        },
        %{
          "collection_a" => "trace_cycle_a",
          "collection_b" => "trace_cycle_b",
          "collection_c" => "trace_tail_c",
          "collection_d" => "trace_tail_d"
        }
      )

    assert {:error, diagnostics} = IR.validate(document)
    assert parent_cycle_trace_ids(diagnostics) == ["trace_cycle_a", "trace_cycle_b"]
    refute "trace_tail_c" in parent_cycle_trace_ids(diagnostics)
    refute "trace_tail_d" in parent_cycle_trace_ids(diagnostics)
  end

  test "collection parent graph cycle membership is independent of map key order" do
    bindings = [
      {"collection_d", "collection_c"},
      {"collection_c", "collection_a"},
      {"collection_b", "collection_a"},
      {"collection_a", "collection_b"}
    ]

    trace_ids = %{
      "collection_a" => "trace_cycle_a",
      "collection_b" => "trace_cycle_b",
      "collection_c" => "trace_tail_c",
      "collection_d" => "trace_tail_d"
    }

    document = collection_only_document(Map.new(bindings), trace_ids)

    assert {:error, diagnostics} = IR.validate(document)
    assert parent_cycle_trace_ids(diagnostics) == ["trace_cycle_a", "trace_cycle_b"]
  end

  test "collection parent graph marks only cycle members when multiple tails enter a cycle" do
    document =
      collection_only_document(
        %{
          "collection_a" => "collection_b",
          "collection_b" => "collection_a",
          "collection_c" => "collection_a",
          "collection_d" => "collection_a"
        },
        %{
          "collection_a" => "trace_cycle_a",
          "collection_b" => "trace_cycle_b",
          "collection_c" => "trace_tail_c",
          "collection_d" => "trace_tail_d"
        }
      )

    assert {:error, diagnostics} = IR.validate(document)
    assert parent_cycle_trace_ids(diagnostics) == ["trace_cycle_a", "trace_cycle_b"]
  end

  test "collection parent graph accepts multiple independent acyclic chains" do
    document =
      collection_only_document(%{
        "chain_a_1" => nil,
        "chain_a_2" => "chain_a_1",
        "chain_b_1" => nil,
        "chain_b_2" => "chain_b_1",
        "chain_b_3" => "chain_b_2"
      })

    assert IR.validate(document) == :ok
  end

  test "collection parent graph rejects mixed acyclic and cyclic components" do
    assert IR.validate(
             collection_only_document(
               %{
                 "acyclic_1" => nil,
                 "acyclic_2" => "acyclic_1"
               },
               %{"acyclic_1" => "trace_acyclic_1", "acyclic_2" => "trace_acyclic_2"}
             )
           ) == :ok

    document =
      collection_only_document(
        %{
          "acyclic_1" => nil,
          "acyclic_2" => "acyclic_1",
          "cycle_a" => "cycle_b",
          "cycle_b" => "cycle_a"
        },
        %{
          "acyclic_1" => "trace_acyclic_1",
          "acyclic_2" => "trace_acyclic_2",
          "cycle_a" => "trace_cycle_a",
          "cycle_b" => "trace_cycle_b"
        }
      )

    assert {:error, diagnostics} = IR.validate(document)
    assert parent_cycle_trace_ids(diagnostics) == ["trace_cycle_a", "trace_cycle_b"]
    refute "trace_acyclic_1" in parent_cycle_trace_ids(diagnostics)
    refute "trace_acyclic_2" in parent_cycle_trace_ids(diagnostics)
  end

  test "binding registries round-trip through serialization" do
    alias LiveFrames.Fidelity.DocumentLoader

    document = binding_document()
    assert {:ok, json} = IR.encode(document)
    decoded = Jason.decode!(json)

    assert map_size(decoded["collection_bindings"]) == 1
    assert map_size(decoded["value_bindings"]) == 1

    assert {:ok, reloaded} = DocumentLoader.from_map(decoded)
    assert IR.encode!(reloaded) == json
  end
end
