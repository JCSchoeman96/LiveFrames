defmodule LiveFrames.FidelityDocumentLoaderTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Fidelity
  alias LiveFrames.Fidelity.DocumentLoader
  alias LiveFrames.IR
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Migration

  @hero_v1_input Path.expand(
                   "../fixtures/ir/historical/hero_india_design_document_v1.json",
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

  defp minimal_v3_map(overrides \\ %{}) do
    minimal_v2_map()
    |> Map.merge(overrides)
    |> Map.put("ir_version", "3.0.0")
  end

  defp value_binding_map(overrides \\ %{}) do
    Map.merge(
      %{
        "value_binding_id" => "value_001",
        "target_node_id" => DesignNode.deterministic_id([1]),
        "target_kind" => "text",
        "value_kind" => "field",
        "scope" => "site",
        "value_key" => "content.body",
        "collection_binding_id" => nil,
        "modifier" => %{"status" => "none"},
        "normalization_status" => "normalized",
        "source_trace" => nil
      },
      overrides
    )
  end

  defp legacy_binding_input(version, overrides) do
    binding =
      if version in ["2.0.0", "3.0.0"] do
        value_binding_map()
        |> Map.delete("modifier")
        |> Map.put("modifier_status", "none")
      else
        value_binding_map()
      end
      |> Map.merge(overrides)

    base =
      case version do
        "2.0.0" -> minimal_v2_map()
        "3.0.0" -> minimal_v3_map()
        "4.0.0" -> minimal_v3_map() |> Map.put("ir_version", "4.0.0")
        "5.0.0" -> minimal_v3_map() |> Map.put("ir_version", "5.0.0")
      end

    put_in(base, ["value_bindings"], %{"value_001" => binding})
  end

  defp migration_pairs(document) do
    document
    |> get_in(["provenance", "liveframes_ir_migrations"])
    |> Enum.map(fn entry -> {entry["source_version"], entry["target_version"]} end)
  end

  test "v5 migration preserves represented payload and validates migration history" do
    entry = fn source, target ->
      %{
        "source_version" => source,
        "target_version" => target,
        "kind" => "structural",
        "frontend_semantics_recovered" => false
      }
    end

    v4_to_v5 = entry.("4.0.0", "5.0.0")
    v5_to_v6 = entry.("5.0.0", "6.0.0")

    v5 =
      minimal_v3_map()
      |> Map.put("ir_version", "5.0.0")
      |> put_in(["value_bindings"], %{
        "value_001" =>
          value_binding_map(%{
            "modifier" => %{"status" => "opaque"},
            "normalization_status" => "evidence_insufficient"
          })
      })
      |> put_in(["provenance"], %{
        "other" => "preserved",
        "liveframes_ir_migrations" => [v4_to_v5, v5_to_v6]
      })

    assert {:ok, migrated} = Migration.to_current(v5)
    assert migrated == Map.put(v5, "ir_version", "6.0.0")
    reordered = put_in(v5, ["provenance", "liveframes_ir_migrations"], [v5_to_v6, v4_to_v5])
    assert {:error, diagnostics} = Migration.to_current(reordered)
    assert Enum.any?(diagnostics, &(&1.code == "ir.migration.provenance_collision"))

    conflict =
      put_in(v5, ["provenance", "liveframes_ir_migrations"], [
        Map.put(v5_to_v6, "kind", "inferred")
      ])

    assert {:error, diagnostics} = Migration.to_current(conflict)
    assert Enum.any?(diagnostics, &(&1.code == "ir.migration.provenance_collision"))
  end

  test "loads IR6 datetime targets and rejects unknown targets" do
    id = DesignNode.deterministic_id([1])
    map = minimal_v3_map() |> Map.put("ir_version", "6.0.0")

    map =
      put_in(map, ["collection_bindings"], %{
        "collection_001" => %{
          "collection_binding_id" => "collection_001",
          "owner_node_id" => id,
          "repeat_root_node_id" => id,
          "parent_collection_binding_id" => nil,
          "normalization_status" => "normalized",
          "source_trace" => nil
        }
      })

    binding =
      value_binding_map(%{
        "target_kind" => "datetime_attribute",
        "scope" => "collection_item",
        "collection_binding_id" => "collection_001"
      })

    map = put_in(map, ["value_bindings"], %{"value_001" => binding})
    assert {:ok, document} = DocumentLoader.from_map(map)
    assert document.value_bindings["value_001"].target_kind == :datetime_attribute
    assert {:ok, ^document} = document |> IR.to_map() |> DocumentLoader.from_map()
    unknown = put_in(map, ["value_bindings", "value_001", "target_kind"], "future_attribute_kind")
    assert {:error, diagnostics} = DocumentLoader.from_map(unknown)
    assert Enum.any?(diagnostics, &(&1.code == "ir.value_binding.target_kind_invalid"))
  end

  test "legacy datetime enum fails while IR5 enums are preserved" do
    for version <- ["2.0.0", "3.0.0", "4.0.0", "5.0.0"] do
      input = legacy_binding_input(version, %{"target_kind" => "datetime_attribute"})
      assert {:error, diagnostics} = Migration.to_current(input)
      assert Enum.any?(diagnostics, &(&1.code == "ir.migration.value_binding_invalid"))
    end

    v5 = minimal_v3_map() |> Map.put("ir_version", "5.0.0")

    binding =
      value_binding_map()
      |> Map.put("target_kind", "rich_text")
      |> Map.put("scope", "current_entity")

    v5 = put_in(v5, ["value_bindings"], %{"value_001" => binding})
    assert {:ok, migrated} = Migration.to_current(v5)
    assert migrated["ir_version"] == "6.0.0"
    assert migrated["value_bindings"] == v5["value_bindings"]
  end

  test "all legacy routes reach IR6 in chronological order" do
    inputs = [
      minimal_v1_map(),
      minimal_v2_map(),
      minimal_v3_map(),
      Map.put(minimal_v3_map(), "ir_version", "4.0.0"),
      Map.put(minimal_v3_map(), "ir_version", "5.0.0")
    ]

    transitions = Enum.map(1..5, fn n -> {"#{n}.0.0", "#{n + 1}.0.0"} end)

    for {input, index} <- Enum.with_index(inputs) do
      assert {:ok, migrated} = Migration.to_current(input)
      assert migrated["ir_version"] == "6.0.0"
      assert migration_pairs(migrated) == Enum.drop(transitions, index)

      assert List.last(migrated["provenance"]["liveframes_ir_migrations"]) == %{
               "source_version" => "5.0.0",
               "target_version" => "6.0.0",
               "kind" => "structural",
               "frontend_semantics_recovered" => false
             }
    end

    current = %{"ir_version" => "6.0.0"}
    assert {:ok, ^current} = Migration.to_current(current)
  end

  test "migrates valid v1 maps through all versions to 6.0.0" do
    assert {:ok, migrated} = Migration.to_current(minimal_v1_map())

    assert migrated["ir_version"] == "6.0.0"
    assert migrated["collection_bindings"] == %{}
    assert migrated["value_bindings"] == %{}
    refute migrated["provenance"] == %{}

    assert get_in(migrated, ["provenance", "liveframes_ir_migrations"]) == [
             %{
               "source_version" => "1.0.0",
               "target_version" => "2.0.0",
               "kind" => "structural",
               "frontend_semantics_recovered" => false
             },
             %{
               "source_version" => "2.0.0",
               "target_version" => "3.0.0",
               "kind" => "structural",
               "frontend_semantics_recovered" => false
             },
             %{
               "source_version" => "3.0.0",
               "target_version" => "4.0.0",
               "kind" => "structural",
               "frontend_semantics_recovered" => false
             },
             %{
               "source_version" => "4.0.0",
               "target_version" => "5.0.0",
               "kind" => "structural",
               "frontend_semantics_recovered" => false
             },
             %{
               "source_version" => "5.0.0",
               "target_version" => "6.0.0",
               "kind" => "structural",
               "frontend_semantics_recovered" => false
             }
           ]
  end

  test "migrates v4 to v5 and rejects v5 enums in v4 artifacts" do
    v4 =
      minimal_v3_map()
      |> Map.put("ir_version", "4.0.0")
      |> Map.put("value_bindings", %{"value_001" => value_binding_map()})

    assert {:ok, migrated} = Migration.to_current(v4)
    assert migrated["ir_version"] == "6.0.0"
    assert migration_pairs(migrated) == [{"4.0.0", "5.0.0"}, {"5.0.0", "6.0.0"}]
    assert {:ok, ^migrated} = Migration.to_current(v4)

    for {field, value} <- [{"target_kind", "rich_text"}, {"scope", "current_entity"}] do
      invalid = put_in(v4, ["value_bindings", "value_001", field], value)
      assert {:error, diagnostics} = Migration.to_current(invalid)
      assert Enum.any?(diagnostics, &(&1.code == "ir.migration.value_binding_invalid"))
    end
  end

  test "rejects v5 binding enums in every legacy migration input" do
    for version <- ["2.0.0", "3.0.0", "4.0.0"],
        {field, value} <- [{"target_kind", "rich_text"}, {"scope", "current_entity"}] do
      input = legacy_binding_input(version, %{field => value})
      result = Migration.to_current(input)

      assert {:error, diagnostics} = result
      refute match?({:ok, %{"ir_version" => "5.0.0"}}, result)
      assert input["ir_version"] == version
      assert Enum.any?(diagnostics, &(&1.code == "ir.migration.value_binding_invalid"))
    end

    both_enums =
      legacy_binding_input("2.0.0", %{
        "target_kind" => "rich_text",
        "scope" => "current_entity"
      })

    both_result = Migration.to_current(both_enums)

    assert {:error, diagnostics} = both_result
    refute match?({:ok, %{"ir_version" => "5.0.0"}}, both_result)
    assert both_enums["ir_version"] == "2.0.0"
    assert Enum.any?(diagnostics, &(&1.code == "ir.migration.value_binding_invalid"))
  end

  test "v5 loader decodes rich_text and current_entity without creating atoms" do
    v5 =
      minimal_v3_map()
      |> Map.put("ir_version", "5.0.0")
      |> put_in(["root_nodes", Access.at(0), "semantic_type"], "rich_text")
      |> put_in(["value_bindings"], %{
        "value_001" =>
          value_binding_map(%{
            "target_kind" => "rich_text",
            "value_kind" => "field",
            "scope" => "current_entity",
            "value_key" => "commerce.product.full_description"
          })
      })

    assert {:ok, document} = DocumentLoader.from_map(v5)
    assert document.value_bindings["value_001"].target_kind == :rich_text
    assert document.value_bindings["value_001"].scope == :current_entity

    unknown = put_in(v5, ["value_bindings", "value_001", "scope"], "unrecognized")
    assert {:error, diagnostics} = DocumentLoader.from_map(unknown)
    assert Enum.any?(diagnostics, &(&1.code == "ir.value_binding.scope_invalid"))
  end

  test "migrates v2 values without inference and appends provenance" do
    legacy_calculation = "calc(100% - 1rem)"

    v2 =
      minimal_v2_map()
      |> put_in(["root_nodes", Access.at(0), "styles"], %{
        "gap" => %{"kind" => "calculation", "value" => legacy_calculation}
      })
      |> put_in(["provenance", "existing"], "kept")

    assert {:ok, migrated} = Migration.to_current(v2)
    assert migrated["ir_version"] == "6.0.0"

    assert get_in(migrated, ["root_nodes", Access.at(0), "styles", "gap", "value"]) ==
             legacy_calculation

    assert migrated["provenance"]["existing"] == "kept"

    assert migrated["provenance"]["liveframes_ir_migrations"] == [
             %{
               "source_version" => "2.0.0",
               "target_version" => "3.0.0",
               "kind" => "structural",
               "frontend_semantics_recovered" => false
             },
             %{
               "source_version" => "3.0.0",
               "target_version" => "4.0.0",
               "kind" => "structural",
               "frontend_semantics_recovered" => false
             },
             %{
               "source_version" => "4.0.0",
               "target_version" => "5.0.0",
               "kind" => "structural",
               "frontend_semantics_recovered" => false
             },
             %{
               "source_version" => "5.0.0",
               "target_version" => "6.0.0",
               "kind" => "structural",
               "frontend_semantics_recovered" => false
             }
           ]
  end

  test "migrates v3 binding modifiers structurally and preserves represented values" do
    trace = %{"source_settings" => %{"dynamic_data" => "{post_content:16}"}}

    v3 =
      minimal_v3_map(%{
        "value_bindings" => %{
          "none" =>
            value_binding_map(%{
              "value_binding_id" => "none",
              "modifier_status" => "none",
              "normalization_status" => "evidence_insufficient",
              "source_trace" => trace
            })
            |> Map.delete("modifier"),
          "opaque" =>
            value_binding_map(%{
              "value_binding_id" => "opaque",
              "modifier_status" => "opaque",
              "value_key" => "content.body",
              "normalization_status" => "evidence_insufficient",
              "source_trace" => trace
            })
            |> Map.delete("modifier")
        }
      })
      |> put_in(["provenance", "existing"], "kept")

    assert {:ok, migrated} = Migration.to_current(v3)
    assert migrated["ir_version"] == "6.0.0"
    assert migrated["provenance"]["existing"] == "kept"

    assert migrated["provenance"]["liveframes_ir_migrations"] == [
             %{
               "source_version" => "3.0.0",
               "target_version" => "4.0.0",
               "kind" => "structural",
               "frontend_semantics_recovered" => false
             },
             %{
               "source_version" => "4.0.0",
               "target_version" => "5.0.0",
               "kind" => "structural",
               "frontend_semantics_recovered" => false
             },
             %{
               "source_version" => "5.0.0",
               "target_version" => "6.0.0",
               "kind" => "structural",
               "frontend_semantics_recovered" => false
             }
           ]

    none = migrated["value_bindings"]["none"]
    assert none["modifier"] == %{"status" => "none"}
    assert none["normalization_status"] == "evidence_insufficient"
    assert none["value_key"] == "content.body"
    assert none["source_trace"] == trace
    refute Map.has_key?(none, "modifier_status")

    opaque = migrated["value_bindings"]["opaque"]
    assert opaque["modifier"] == %{"status" => "opaque"}
    assert opaque["normalization_status"] == "evidence_insufficient"
    assert opaque["source_trace"] == trace
    refute Map.has_key?(opaque, "modifier_status")
    refute Map.has_key?(opaque["modifier"], "kind")
  end

  test "v4 migration is structural and unknown versions fail closed" do
    v4 = minimal_v3_map() |> Map.put("ir_version", "4.0.0")
    assert {:ok, migrated} = Migration.to_current(v4)
    assert migrated["ir_version"] == "6.0.0"
    assert migration_pairs(migrated) == [{"4.0.0", "5.0.0"}, {"5.0.0", "6.0.0"}]
    assert {:error, unsupported} = Migration.to_current(%{"ir_version" => "9.0.0"})
    assert Enum.any?(unsupported, &(&1.code == "ir.document.version_unsupported"))
  end

  test "rejects malformed v3 binding registries and modifier statuses" do
    for bindings <- [[], %{"bad" => "record"}, %{"bad" => %{"modifier_status" => "future"}}] do
      v3 = put_in(minimal_v3_map(), ["value_bindings"], bindings)
      assert {:error, diagnostics} = Migration.to_current(v3)
      assert Enum.any?(diagnostics, &String.starts_with?(&1.code, "ir.migration.value_binding"))
    end
  end

  test "v4 decoder requires exact modifier shapes and rejects the legacy top-level field" do
    variants = [
      {Map.delete(value_binding_map(), "modifier"), "ir.value_binding.modifier_invalid"},
      {value_binding_map(%{"modifier" => %{"status" => "future"}}),
       "ir.value_binding.modifier_invalid"},
      {value_binding_map(%{
         "modifier" => %{
           "status" => "resolved",
           "kind" => "future_modifier",
           "arguments" => %{"count" => 16}
         }
       }), "ir.value_binding.modifier_invalid"},
      {value_binding_map(%{"modifier" => %{"status" => "none", "extra" => true}}),
       "ir.value_binding.modifier_invalid"},
      {value_binding_map(%{
         "modifier" => %{
           "status" => "resolved",
           "kind" => "word_limit",
           "arguments" => %{"count" => 0}
         }
       }), "ir.value_binding.modifier_invalid"},
      {value_binding_map(%{"modifier_status" => "none"}), "ir.value_binding.modifier_invalid"}
    ]

    for {binding, code} <- variants do
      v4 =
        minimal_v3_map(%{"value_bindings" => %{"value_001" => binding}})
        |> Map.put("ir_version", "4.0.0")

      assert {:error, diagnostics} = DocumentLoader.from_map(v4)
      assert Enum.any?(diagnostics, &(&1.code == code))
    end
  end

  test "unknown modifier strings do not create atoms" do
    status = "design_ir_4_unknown_modifier_status_atom"
    kind = "design_ir_4_unknown_modifier_kind_atom"

    refute existing_atom?(status)
    refute existing_atom?(kind)

    for modifier <- [
          %{"status" => status},
          %{"status" => "resolved", "kind" => kind, "arguments" => %{"count" => 16}}
        ] do
      v4 =
        minimal_v3_map(%{
          "value_bindings" => %{
            "value_001" => value_binding_map(%{"modifier" => modifier})
          }
        })
        |> Map.put("ir_version", "4.0.0")

      assert {:error, diagnostics} = DocumentLoader.from_map(v4)
      assert Enum.any?(diagnostics, &(&1.code == "ir.value_binding.modifier_invalid"))
    end

    refute existing_atom?(status)
    refute existing_atom?(kind)
  end

  defp existing_atom?(value) do
    String.to_existing_atom(value)
    true
  rescue
    ArgumentError -> false
  end

  test "structured calculation survives serialization and loader round-trip" do
    calculation = %{
      "operation" => "multiply",
      "operands" => [
        %{"kind" => "token_ref", "path" => "spacing.grid_gap"},
        %{"kind" => "literal", "value" => 2}
      ]
    }

    style = %{
      "kind" => "calculation",
      "value" => calculation,
      "source_expression" => "calc(var(--grid-gap) * 2)",
      "source_trace" => nil,
      "metadata" => %{}
    }

    map =
      put_in(
        minimal_v3_map(),
        ["root_nodes", Access.at(0), "styles"],
        %{"gap" => style}
      )

    assert {:ok, document} = DocumentLoader.from_map(map)
    assert document.ir_version == "6.0.0"

    assert {:ok, round_trip} = document |> IR.to_map() |> DocumentLoader.from_map()
    loaded_style = hd(round_trip.root_nodes).styles["gap"]
    assert loaded_style.value == calculation
    assert loaded_style.source_expression == "calc(var(--grid-gap) * 2)"
    assert IR.validate(round_trip) == :ok
  end

  test "migration rejects structured calculations in legacy versions" do
    structured = %{
      "kind" => "calculation",
      "value" => %{
        "operation" => "multiply",
        "operands" => [
          %{"kind" => "token_ref", "path" => "spacing.grid_gap"},
          %{"kind" => "literal", "value" => 2}
        ]
      }
    }

    for legacy <- [minimal_v2_map(), minimal_v1_map()] do
      legacy = put_in(legacy, ["root_nodes", Access.at(0), "styles"], %{"gap" => structured})
      assert {:error, diagnostics} = Migration.to_current(legacy)
      assert Enum.any?(diagnostics, &(&1.code == "ir.migration.legacy_calculation_invalid"))
    end
  end

  test "migration provenance keeps prior entries and rejects conflicts" do
    record = %{
      "source_version" => "2.0.0",
      "target_version" => "3.0.0",
      "kind" => "structural",
      "frontend_semantics_recovered" => false
    }

    with_existing =
      minimal_v2_map()
      |> put_in(["provenance", "other"], true)
      |> put_in(["provenance", "liveframes_ir_migrations"], [record])

    assert {:ok, migrated} = Migration.to_current(with_existing)
    assert migrated["provenance"]["other"]

    assert migrated["provenance"]["liveframes_ir_migrations"] == [
             record,
             %{
               "source_version" => "3.0.0",
               "target_version" => "4.0.0",
               "kind" => "structural",
               "frontend_semantics_recovered" => false
             },
             %{
               "source_version" => "4.0.0",
               "target_version" => "5.0.0",
               "kind" => "structural",
               "frontend_semantics_recovered" => false
             },
             %{
               "source_version" => "5.0.0",
               "target_version" => "6.0.0",
               "kind" => "structural",
               "frontend_semantics_recovered" => false
             }
           ]

    conflict =
      put_in(
        with_existing,
        ["provenance", "liveframes_ir_migrations", Access.at(0), "kind"],
        "inferred"
      )

    assert {:error, collision} = Migration.to_current(conflict)
    assert Enum.any?(collision, &(&1.code == "ir.migration.provenance_collision"))

    malformed = put_in(minimal_v2_map(), ["provenance", "liveframes_ir_migrations"], %{})
    assert {:error, invalid} = Migration.to_current(malformed)
    assert Enum.any?(invalid, &(&1.code == "ir.migration.provenance_collision"))

    malformed_entry =
      put_in(minimal_v2_map(), ["provenance", "liveframes_ir_migrations"], ["bad"])

    assert {:error, invalid_entry} = Migration.to_current(malformed_entry)
    assert Enum.any?(invalid_entry, &(&1.code == "ir.migration.provenance_collision"))
  end

  test "existing migration record stays in place relative to unrelated history" do
    current_record = %{
      "source_version" => "2.0.0",
      "target_version" => "3.0.0",
      "kind" => "structural",
      "frontend_semantics_recovered" => false
    }

    unrelated_record = %{
      "source_version" => "8.0.0",
      "target_version" => "9.0.0",
      "kind" => "structural",
      "frontend_semantics_recovered" => false
    }

    history = [current_record, unrelated_record]

    v2 =
      put_in(
        minimal_v2_map(),
        ["provenance", "liveframes_ir_migrations"],
        history
      )

    assert {:ok, migrated} = Migration.to_current(v2)

    assert migrated["provenance"]["liveframes_ir_migrations"] ==
             history ++
               [
                 %{
                   "source_version" => "3.0.0",
                   "target_version" => "4.0.0",
                   "kind" => "structural",
                   "frontend_semantics_recovered" => false
                 },
                 %{
                   "source_version" => "4.0.0",
                   "target_version" => "5.0.0",
                   "kind" => "structural",
                   "frontend_semantics_recovered" => false
                 },
                 %{
                   "source_version" => "5.0.0",
                   "target_version" => "6.0.0",
                   "kind" => "structural",
                   "frontend_semantics_recovered" => false
                 }
               ]
  end

  test "v1 migration orders existing migration records by transition" do
    v2_to_v3 = %{
      "source_version" => "2.0.0",
      "target_version" => "3.0.0",
      "kind" => "structural",
      "frontend_semantics_recovered" => false
    }

    v1 = put_in(minimal_v1_map(), ["provenance", "liveframes_ir_migrations"], [v2_to_v3])

    assert {:ok, migrated} = Migration.to_current(v1)

    assert Enum.map(migrated["provenance"]["liveframes_ir_migrations"], fn entry ->
             {entry["source_version"], entry["target_version"]}
           end) == [
             {"1.0.0", "2.0.0"},
             {"2.0.0", "3.0.0"},
             {"3.0.0", "4.0.0"},
             {"4.0.0", "5.0.0"},
             {"5.0.0", "6.0.0"}
           ]
  end

  test "v2 migration inserts before an existing 3-to-4 record" do
    v3_to_v4 = %{
      "source_version" => "3.0.0",
      "target_version" => "4.0.0",
      "kind" => "structural",
      "frontend_semantics_recovered" => false
    }

    v2 = put_in(minimal_v2_map(), ["provenance", "liveframes_ir_migrations"], [v3_to_v4])

    assert {:ok, migrated} = Migration.to_current(v2)

    assert migration_pairs(migrated) == [
             {"2.0.0", "3.0.0"},
             {"3.0.0", "4.0.0"},
             {"4.0.0", "5.0.0"},
             {"5.0.0", "6.0.0"}
           ]
  end

  test "v1 migration inserts before an existing 3-to-4 record" do
    v3_to_v4 = %{
      "source_version" => "3.0.0",
      "target_version" => "4.0.0",
      "kind" => "structural",
      "frontend_semantics_recovered" => false
    }

    v1 = put_in(minimal_v1_map(), ["provenance", "liveframes_ir_migrations"], [v3_to_v4])

    assert {:ok, migrated} = Migration.to_current(v1)

    assert migration_pairs(migrated) == [
             {"1.0.0", "2.0.0"},
             {"2.0.0", "3.0.0"},
             {"3.0.0", "4.0.0"},
             {"4.0.0", "5.0.0"},
             {"5.0.0", "6.0.0"}
           ]
  end

  test "v1 migration preserves an existing 2-to-3 and 3-to-4 chain" do
    v2_to_v3 = %{
      "source_version" => "2.0.0",
      "target_version" => "3.0.0",
      "kind" => "structural",
      "frontend_semantics_recovered" => false
    }

    v3_to_v4 = %{
      "source_version" => "3.0.0",
      "target_version" => "4.0.0",
      "kind" => "structural",
      "frontend_semantics_recovered" => false
    }

    v1 =
      put_in(
        minimal_v1_map(),
        ["provenance", "liveframes_ir_migrations"],
        [v2_to_v3, v3_to_v4]
      )

    assert {:ok, migrated} = Migration.to_current(v1)

    assert migration_pairs(migrated) == [
             {"1.0.0", "2.0.0"},
             {"2.0.0", "3.0.0"},
             {"3.0.0", "4.0.0"},
             {"4.0.0", "5.0.0"},
             {"5.0.0", "6.0.0"}
           ]
  end

  test "migration inserts known records without reordering unrelated history" do
    unrelated = %{
      "source_version" => "8.0.0",
      "target_version" => "9.0.0",
      "kind" => "structural",
      "frontend_semantics_recovered" => false
    }

    v3_to_v4 = %{
      "source_version" => "3.0.0",
      "target_version" => "4.0.0",
      "kind" => "structural",
      "frontend_semantics_recovered" => false
    }

    v2 =
      put_in(
        minimal_v2_map(),
        ["provenance", "liveframes_ir_migrations"],
        [unrelated, v3_to_v4]
      )

    assert {:ok, migrated} = Migration.to_current(v2)

    assert migrated["provenance"]["liveframes_ir_migrations"] == [
             unrelated,
             %{
               "source_version" => "2.0.0",
               "target_version" => "3.0.0",
               "kind" => "structural",
               "frontend_semantics_recovered" => false
             },
             v3_to_v4,
             %{
               "source_version" => "4.0.0",
               "target_version" => "5.0.0",
               "kind" => "structural",
               "frontend_semantics_recovered" => false
             },
             %{
               "source_version" => "5.0.0",
               "target_version" => "6.0.0",
               "kind" => "structural",
               "frontend_semantics_recovered" => false
             }
           ]
  end

  test "migration rejects known records in impossible transition order" do
    v2_to_v3 = %{
      "source_version" => "2.0.0",
      "target_version" => "3.0.0",
      "kind" => "structural",
      "frontend_semantics_recovered" => false
    }

    v3_to_v4 = %{
      "source_version" => "3.0.0",
      "target_version" => "4.0.0",
      "kind" => "structural",
      "frontend_semantics_recovered" => false
    }

    v2 =
      put_in(
        minimal_v2_map(),
        ["provenance", "liveframes_ir_migrations"],
        [v3_to_v4, v2_to_v3]
      )

    assert {:error, diagnostics} = Migration.to_current(v2)
    assert Enum.any?(diagnostics, &(&1.code == "ir.migration.provenance_collision"))
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

    assert {:ok, v4} = Migration.to_current(minimal_v3_map())
    assert v4["ir_version"] == "6.0.0"
    assert {:error, unsupported} = Migration.to_current(%{"ir_version" => "9.0.0"})
    assert Enum.any?(unsupported, &(&1.code == "ir.document.version_unsupported"))
  end

  test "loader rejects serialized current maps missing required root fields" do
    v2 = minimal_v2_map() |> Map.delete("collection_bindings")
    assert {:error, diagnostics} = DocumentLoader.from_map(v2)
    assert Enum.any?(diagnostics, &(&1.code == "ir.document.required_root_missing"))
  end

  test "loader rejects wrong current root container types without raising" do
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
               DocumentLoader.from_map(
                 put_in(minimal_v3_map() |> Map.put("ir_version", "4.0.0"), [field], invalid)
               )

      assert Enum.any?(diagnostics, &(&1.code == "ir.document.root_shape_invalid"))
    end
  end

  test "loader rejects malformed registry entries without coercing array registries" do
    assert {:error, asset_diagnostics} =
             DocumentLoader.from_map(
               put_in(
                 minimal_v3_map() |> Map.put("ir_version", "4.0.0"),
                 ["assets"],
                 %{"asset_001" => "invalid"}
               )
             )

    assert Enum.any?(asset_diagnostics, &(&1.code == "ir.asset.invalid"))

    assert {:error, interaction_diagnostics} =
             DocumentLoader.from_map(
               put_in(
                 minimal_v3_map() |> Map.put("ir_version", "4.0.0"),
                 ["interactions"],
                 %{"interaction_001" => 123}
               )
             )

    assert Enum.any?(interaction_diagnostics, &(&1.code == "ir.interaction.invalid"))

    assert {:error, collection_diagnostics} =
             DocumentLoader.from_map(
               put_in(
                 minimal_v3_map() |> Map.put("ir_version", "4.0.0"),
                 ["collection_bindings"],
                 %{"collection_001" => []}
               )
             )

    assert Enum.any?(collection_diagnostics, &(&1.code == "ir.collection_binding.invalid"))

    assert {:error, value_diagnostics} =
             DocumentLoader.from_map(
               put_in(
                 minimal_v3_map() |> Map.put("ir_version", "4.0.0"),
                 ["value_bindings"],
                 %{"value_001" => "bad"}
               )
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
      |> Map.put("ir_version", "3.0.0")
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
      put_in(minimal_v3_map(), ["value_bindings"], %{
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
    assert document.ir_version == "6.0.0"
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
    assert {:ok, document} = DocumentLoader.from_file(@hero_v1_input)
    assert document.ir_version == "6.0.0"
    assert document.collection_bindings == %{}
    assert document.value_bindings == %{}
    refute Map.has_key?(document.token_set["tokens"], "typography.heading.scale.h2")
    assert Jason.decode!(File.read!(@hero_v1_input))["ir_version"] == "1.0.0"
  end
end
