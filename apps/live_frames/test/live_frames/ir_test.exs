defmodule LiveFrames.IRTest do
  use ExUnit.Case, async: true

  alias LiveFrames.IR
  alias LiveFrames.IR.AssetReference
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Diagnostic
  alias LiveFrames.IR.Interaction
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
        "unknown" => StyleValue.unresolved("var(--unknown)")
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
    assert DesignNode.deterministic_id([1, 2]) == DesignNode.deterministic_id([1, 2])

    assert_raise ArgumentError, fn -> DesignNode.deterministic_id([]) end
    assert_raise ArgumentError, fn -> DesignNode.deterministic_id(:root) end
  end

  test "valid IR accepts registries and unresolved responsive entries" do
    assert IR.validate(valid_document()) == :ok
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
    assert decoded["ir_version"] == "1.0.0"

    assert get_in(decoded, ["root_nodes", Access.at(0), "styles", "background", "kind"]) ==
             "token_ref"

    assert decoded["assets"]["asset_001"]["status"] == "resolved"
    assert decoded["root_nodes"] |> hd() |> get_in(["styles", "unknown", "kind"]) == "unresolved"
    assert hd(decoded["diagnostics"])["severity"] == "warning"
    refute first =~ "__struct__"
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
end
