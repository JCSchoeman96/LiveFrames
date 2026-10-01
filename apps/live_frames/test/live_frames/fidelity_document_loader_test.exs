defmodule LiveFrames.FidelityDocumentLoaderTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Fidelity
  alias LiveFrames.Fidelity.DocumentLoader
  alias LiveFrames.IR
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Migration

  @hero_input Path.expand(
                "../../../../sources/work/hero_india/design_ir/design_document.json",
                __DIR__
              )

  defp minimal_v2_map(overrides \\ %{}) do
    Map.merge(
      %{
        "ir_version" => "2.0.0",
        "source_metadata" => %{},
        "token_set" => %{},
        "root_nodes" => [
          %{
            "node_id" => DesignNode.deterministic_id([1]),
            "semantic_type" => "section",
            "semantic_role" => nil,
            "label" => nil,
            "content" => nil,
            "attributes" => %{},
            "styles" => %{},
            "responsive" => %{},
            "interaction_refs" => [],
            "asset_refs" => [],
            "children" => [],
            "source_trace" => nil
          }
        ],
        "assets" => %{},
        "interactions" => %{},
        "collection_bindings" => %{},
        "value_bindings" => %{},
        "diagnostics" => [],
        "provenance" => %{}
      },
      overrides
    )
  end

  defp minimal_v1_map do
    minimal_v2_map()
    |> Map.delete("collection_bindings")
    |> Map.delete("value_bindings")
    |> Map.put("ir_version", "1.0.0")
  end

  test "migrates valid v1 maps to 2.0.0 with empty binding registries" do
    assert {:ok, migrated} = Migration.to_current(minimal_v1_map())

    assert migrated["ir_version"] == "2.0.0"
    assert migrated["collection_bindings"] == %{}
    assert migrated["value_bindings"] == %{}
    refute migrated["provenance"] == %{}

    assert get_in(migrated, ["provenance", "liveframes_ir_migrations"]) == [
             %{
               "source_version" => "1.0.0",
               "target_version" => "2.0.0",
               "kind" => "structural",
               "frontend_semantics_recovered" => false
             }
           ]
  end

  test "migration provenance does not overwrite existing provenance keys" do
    v1 =
      minimal_v1_map()
      |> put_in(["provenance", "source_hash"], "abc123")

    assert {:ok, migrated} = Migration.to_current(v1)
    assert migrated["provenance"]["source_hash"] == "abc123"
  end

  test "v1 migration rejects missing, nil, or non-object provenance" do
    assert {:error, missing} = Migration.to_current(Map.delete(minimal_v1_map(), "provenance"))
    assert Enum.any?(missing, &(&1.code == "ir.migration.provenance_missing"))

    assert {:error, nil_provenance} =
             Migration.to_current(put_in(minimal_v1_map(), ["provenance"], nil))

    assert Enum.any?(nil_provenance, &(&1.code == "ir.migration.provenance_invalid"))

    assert {:error, bad_provenance} =
             Migration.to_current(put_in(minimal_v1_map(), ["provenance"], "bad"))

    assert Enum.any?(bad_provenance, &(&1.code == "ir.migration.provenance_invalid"))
  end

  test "v1 migration rejects reserved v2 binding roots" do
    assert {:error, diagnostics} =
             Migration.to_current(Map.put(minimal_v1_map(), "collection_bindings", %{}))

    assert Enum.any?(diagnostics, &(&1.code == "ir.migration.v1_shape_invalid"))

    assert {:error, value_diagnostics} =
             Migration.to_current(Map.put(minimal_v1_map(), "value_bindings", %{}))

    assert Enum.any?(value_diagnostics, &(&1.code == "ir.migration.v1_shape_invalid"))
  end

  test "migration fails closed on provenance collision" do
    v1 =
      put_in(minimal_v1_map(), ["provenance", "liveframes_ir_migrations"], %{
        "unexpected" => true
      })

    assert {:error, diagnostics} = Migration.to_current(v1)
    assert Enum.any?(diagnostics, &(&1.code == "ir.migration.provenance_collision"))
  end

  test "unknown and malformed versions are rejected distinctly" do
    assert {:error, missing} = Migration.to_current(%{})
    assert Enum.any?(missing, &(&1.code == "ir.document.version_missing"))

    assert {:error, invalid} = Migration.to_current(%{"ir_version" => 2})
    assert Enum.any?(invalid, &(&1.code == "ir.document.version_invalid"))

    assert {:error, unsupported} = Migration.to_current(%{"ir_version" => "3.0.0"})
    assert Enum.any?(unsupported, &(&1.code == "ir.document.version_unsupported"))
  end

  test "loader rejects serialized v2 maps missing required root fields" do
    v2 = minimal_v2_map() |> Map.delete("collection_bindings")
    assert {:error, diagnostics} = DocumentLoader.from_map(v2)
    assert Enum.any?(diagnostics, &(&1.code == "ir.document.required_root_missing"))
  end

  test "loader rejects wrong v2 root container types without raising" do
    for {field, invalid} <- [
          {"root_nodes", nil},
          {"root_nodes", %{}},
          {"assets", []},
          {"interactions", []},
          {"collection_bindings", []},
          {"value_bindings", []},
          {"diagnostics", %{}}
        ] do
      assert {:error, diagnostics} =
               DocumentLoader.from_map(put_in(minimal_v2_map(), [field], invalid))

      assert Enum.any?(diagnostics, &(&1.code == "ir.document.root_shape_invalid"))
    end
  end

  test "loader rejects malformed registry entries without coercing array registries" do
    assert {:error, asset_diagnostics} =
             DocumentLoader.from_map(
               put_in(minimal_v2_map(), ["assets"], %{"asset_001" => "invalid"})
             )

    assert Enum.any?(asset_diagnostics, &(&1.code == "ir.asset.invalid"))

    assert {:error, interaction_diagnostics} =
             DocumentLoader.from_map(
               put_in(minimal_v2_map(), ["interactions"], %{"interaction_001" => 123})
             )

    assert Enum.any?(interaction_diagnostics, &(&1.code == "ir.interaction.invalid"))

    assert {:error, collection_diagnostics} =
             DocumentLoader.from_map(
               put_in(minimal_v2_map(), ["collection_bindings"], %{"collection_001" => []})
             )

    assert Enum.any?(collection_diagnostics, &(&1.code == "ir.collection_binding.invalid"))

    assert {:error, value_diagnostics} =
             DocumentLoader.from_map(
               put_in(minimal_v2_map(), ["value_bindings"], %{"value_001" => "bad"})
             )

    assert Enum.any?(value_diagnostics, &(&1.code == "ir.value_binding.invalid"))
  end

  test "loader rejects malformed source_trace without raising" do
    map =
      update_in(minimal_v2_map(), ["root_nodes", Access.at(0)], fn node ->
        Map.put(node, "source_trace", "bad")
      end)

    assert {:error, diagnostics} = DocumentLoader.from_map(map)
    assert Enum.any?(diagnostics, &(&1.code == "ir.trace.invalid"))
  end

  test "interactions and binding registries survive loader round-trip" do
    node_id = DesignNode.deterministic_id([1])
    repeat_id = DesignNode.deterministic_id([1, 1])
    target_id = DesignNode.deterministic_id([1, 1, 1])

    map =
      put_in(minimal_v2_map(), ["root_nodes"], [
        %{
          "node_id" => node_id,
          "semantic_type" => "section",
          "semantic_role" => nil,
          "label" => nil,
          "content" => nil,
          "attributes" => %{},
          "styles" => %{},
          "responsive" => %{},
          "interaction_refs" => ["interaction_001"],
          "asset_refs" => [],
          "children" => [
            %{
              "node_id" => repeat_id,
              "semantic_type" => "container",
              "semantic_role" => nil,
              "label" => nil,
              "content" => nil,
              "attributes" => %{},
              "styles" => %{},
              "responsive" => %{},
              "interaction_refs" => [],
              "asset_refs" => [],
              "children" => [
                %{
                  "node_id" => target_id,
                  "semantic_type" => "heading",
                  "semantic_role" => nil,
                  "label" => nil,
                  "content" => "Title",
                  "attributes" => %{},
                  "styles" => %{},
                  "responsive" => %{},
                  "interaction_refs" => [],
                  "asset_refs" => [],
                  "children" => [],
                  "source_trace" => nil
                }
              ],
              "source_trace" => nil
            }
          ],
          "source_trace" => nil
        }
      ])
      |> put_in(["interactions"], %{
        "interaction_001" => %{
          "interaction_id" => "interaction_001",
          "intent" => "toggle_visibility",
          "trigger" => "click",
          "target_node_ids" => [node_id],
          "parameters" => %{},
          "source_trace" => nil
        }
      })
      |> put_in(["collection_bindings"], %{
        "collection_001" => %{
          "collection_binding_id" => "collection_001",
          "owner_node_id" => node_id,
          "repeat_root_node_id" => repeat_id,
          "parent_collection_binding_id" => nil,
          "normalization_status" => "normalized",
          "source_trace" => nil
        }
      })
      |> put_in(["value_bindings"], %{
        "value_001" => %{
          "value_binding_id" => "value_001",
          "target_node_id" => target_id,
          "target_kind" => "text",
          "value_kind" => "field",
          "scope" => "collection_item",
          "value_key" => "content.title",
          "collection_binding_id" => "collection_001",
          "modifier_status" => "none",
          "normalization_status" => "normalized",
          "source_trace" => nil
        }
      })

    assert {:ok, document} = DocumentLoader.from_map(map)
    assert map_size(document.interactions) == 1
    assert map_size(document.collection_bindings) == 1
    assert map_size(document.value_bindings) == 1

    round_trip = document |> IR.to_map() |> DocumentLoader.from_map()
    assert round_trip == {:ok, document}
  end

  test "unsupported enum strings fail validation cleanly through the loader" do
    map =
      put_in(minimal_v2_map(), ["value_bindings"], %{
        "value_001" => %{
          "value_binding_id" => "value_001",
          "target_node_id" => DesignNode.deterministic_id([1]),
          "target_kind" => "not_a_kind",
          "value_kind" => "field",
          "scope" => "site",
          "value_key" => "content.title",
          "collection_binding_id" => nil,
          "modifier_status" => "none",
          "normalization_status" => "normalized",
          "source_trace" => nil
        }
      })

    assert {:error, diagnostics} = DocumentLoader.from_map(map)
    assert Enum.any?(diagnostics, &(&1.code == "ir.value_binding.target_kind_invalid"))
  end

  test "v1 migration preserves represented semantics without inferring bindings" do
    v1 = minimal_v1_map() |> put_in(["provenance", "source_hash"], "fixture")

    assert {:ok, document} = DocumentLoader.from_map(v1)
    assert document.ir_version == "2.0.0"
    assert document.collection_bindings == %{}
    assert document.value_bindings == %{}
    assert document.provenance["source_hash"] == "fixture"
  end

  test "fidelity fails closed on non-empty binding registries" do
    {:ok, document} =
      DocumentLoader.from_map(
        put_in(minimal_v2_map(), ["collection_bindings"], %{
          "collection_001" => %{
            "collection_binding_id" => "collection_001",
            "owner_node_id" => DesignNode.deterministic_id([1]),
            "repeat_root_node_id" => DesignNode.deterministic_id([1]),
            "parent_collection_binding_id" => nil,
            "normalization_status" => "normalized",
            "source_trace" => nil
          }
        })
      )

    assert {:error, diagnostics} = Fidelity.generate(document)
    assert Enum.any?(diagnostics, &(&1.code == "fidelity.bindings.unsupported"))
  end

  test "hero india v1 fixture migrates and fidelity drift inputs stay controlled" do
    assert {:ok, document} = DocumentLoader.from_file(@hero_input)
    assert document.ir_version == "2.0.0"
    assert document.collection_bindings == %{}
    assert document.value_bindings == %{}
    assert Jason.decode!(File.read!(@hero_input))["ir_version"] == "1.0.0"
  end
end
