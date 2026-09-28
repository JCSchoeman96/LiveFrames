defmodule LiveFrames.BricksStylePrecedenceTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Adapters.Bricks.StageA
  alias LiveFrames.Fidelity
  alias LiveFrames.IR
  alias LiveFrames.IR.StyleValue
  alias LiveFrames.Tokens.TokenSet

  defp class(id, settings) do
    %{"id" => id, "name" => id, "settings" => settings}
  end

  defp document(class_refs, class_definitions, element_settings \\ %{}, opts \\ []) do
    element_name = Keyword.get(opts, :element_name, "div")
    converter_opts = Keyword.delete(opts, :element_name)

    source = %{
      "source" => "bricksCopiedElements",
      "sourceUrl" => "https://example.test/source.json",
      "version" => "2.3.1",
      "content" => [%{"id" => "proxy-a", "cid" => "component-a", "label" => "Synthetic"}],
      "components" => [
        %{
          "id" => "component-a",
          "elements" => [
            %{
              "id" => "root",
              "name" => element_name,
              "parent" => 0,
              "settings" => Map.put(element_settings, "_cssGlobalClasses", class_refs)
            }
          ]
        }
      ],
      "globalClasses" => class_definitions
    }

    assert {:ok, document} =
             Bricks.to_ir(
               source,
               Keyword.merge(
                 [component_id: "component-a", token_set: TokenSet.new()],
                 converter_opts
               )
             )

    document
  end

  defp root(document), do: hd(document.root_nodes)

  defp precedence_diagnostics(document) do
    Enum.filter(document.diagnostics, &(&1.code == "bricks.style.precedence_conflict"))
  end

  defp stage_a_result(
         class_refs,
         class_definitions,
         element_settings \\ %{},
         element_name \\ "div"
       ) do
    source = %{
      "source" => "bricksCopiedElements",
      "sourceUrl" => "https://example.test/source.json",
      "version" => "2.3.1",
      "content" => [%{"id" => "proxy-a", "cid" => "component-a", "label" => "Synthetic"}],
      "components" => [
        %{
          "id" => "component-a",
          "elements" => [
            %{
              "id" => "root",
              "name" => element_name,
              "parent" => 0,
              "settings" => Map.put(element_settings, "_cssGlobalClasses", class_refs)
            }
          ]
        }
      ],
      "globalClasses" => class_definitions
    }

    assert {:ok, result} = StageA.generate(source, component_id: "component-a")
    result
  end

  test "preserves non-overlapping margin leaves from separate class layers" do
    document =
      document(
        ["class-a", "class-b"],
        [
          class("class-a", %{"_margin" => %{"top" => "1rem"}}),
          class("class-b", %{"_margin" => %{"bottom" => "2rem"}})
        ]
      )

    assert %StyleValue{value: "1rem"} = root(document).styles["margin-top"]
    assert %StyleValue{value: "2rem"} = root(document).styles["margin-bottom"]
    assert precedence_diagnostics(document) == []
  end

  test "container width conflict blocks intrinsic and Theme Styles fallback" do
    conflicting_classes = [
      class("class-a", %{"_width" => "100px"}),
      class("class-b", %{"_width" => "200px"})
    ]

    document =
      document(
        ["class-a", "class-b"],
        conflicting_classes,
        %{},
        element_name: "container",
        theme_styles: %{
          "source" => "bricks_theme_styles",
          "active_style_id" => "active",
          "styles" => %{"active" => %{"settings" => %{"container" => %{"width" => "1400px"}}}}
        }
      )

    refute Map.has_key?(root(document).styles, "width")
    assert [diagnostic] = precedence_diagnostics(document)
    assert diagnostic.metadata["property"] == "width"

    assert {:ok, bundle} = Fidelity.generate(document)
    refute Regex.match?(~r/^\\s*width:/m, bundle.css)
    refute bundle.css =~ "1100px"
    refute bundle.css =~ "1400px"

    configured_width_document =
      document(
        ["class-a", "class-b"],
        conflicting_classes,
        %{},
        element_name: "container",
        container_width: "1300px"
      )

    refute Map.has_key?(root(configured_width_document).styles, "width")
    assert {:ok, configured_bundle} = Fidelity.generate(configured_width_document)
    refute configured_bundle.css =~ "1300px"
  end

  test "container display conflict blocks the intrinsic flex fallback" do
    document =
      document(
        ["class-a", "class-b"],
        [class("class-a", %{"_display" => "block"}), class("class-b", %{"_display" => "grid"})],
        %{},
        element_name: "container"
      )

    refute Map.has_key?(root(document).styles, "display")
    assert Enum.any?(precedence_diagnostics(document), &(&1.metadata["property"] == "display"))
    assert root(document).styles["flex-direction"].value == "column"
  end

  test "container flex-direction conflict blocks the intrinsic column fallback" do
    document =
      document(
        ["class-a", "class-b"],
        [
          class("class-a", %{"_direction" => "row"}),
          class("class-b", %{"_direction" => "column-reverse"})
        ],
        %{},
        element_name: "container"
      )

    refute Map.has_key?(root(document).styles, "flex-direction")

    assert Enum.any?(
             precedence_diagnostics(document),
             &(&1.metadata["property"] == "flex-direction")
           )

    assert root(document).styles["display"].value == "flex"
  end

  test "section align-items conflict blocks its intrinsic center fallback" do
    document =
      document(
        ["class-a", "class-b"],
        [
          class("class-a", %{"_alignItems" => "start"}),
          class("class-b", %{"_alignItems" => "end"})
        ],
        %{},
        element_name: "section"
      )

    refute Map.has_key?(root(document).styles, "align-items")

    assert Enum.any?(
             precedence_diagnostics(document),
             &(&1.metadata["property"] == "align-items")
           )
  end

  test "intrinsic defaults unrelated to a conflict remain available" do
    document =
      document(
        ["class-a", "class-b"],
        [class("class-a", %{"_width" => "100px"}), class("class-b", %{"_width" => "200px"})],
        %{},
        element_name: "container"
      )

    refute Map.has_key?(root(document).styles, "width")
    assert root(document).styles["display"].value == "flex"
    assert root(document).styles["flex-direction"].value == "column"
    assert root(document).styles["max-width"].value == "100%"
    assert root(document).styles["margin-left"].value == "auto"
    assert root(document).styles["margin-right"].value == "auto"
  end

  test "container max-width and margin conflicts suppress only matching intrinsics" do
    document =
      document(
        ["class-a", "class-b"],
        [
          class("class-a", %{"_widthMax" => "80%", "_margin" => %{"left" => "1rem"}}),
          class("class-b", %{"_widthMax" => "90%", "_margin" => %{"left" => "2rem"}})
        ],
        %{},
        element_name: "container"
      )

    refute Map.has_key?(root(document).styles, "max-width")
    refute Map.has_key?(root(document).styles, "margin-left")
    assert root(document).styles["display"].value == "flex"
    assert root(document).styles["margin-right"].value == "auto"

    assert Enum.map(precedence_diagnostics(document), & &1.metadata["property"]) == [
             "margin-left",
             "max-width"
           ]
  end

  test "Stage A consumed evidence retains disjoint margin leaves from both class layers" do
    result =
      stage_a_result(
        ["class-a", "class-b"],
        [
          class("class-a", %{"_margin" => %{"top" => "1rem"}}),
          class("class-b", %{"_margin" => %{"bottom" => "2rem"}})
        ]
      )

    consumed = result.report["settings"]["consumed"]
    margin_records = Enum.filter(consumed, &(&1["property"] in ["margin-top", "margin-bottom"]))

    assert Enum.map(margin_records, & &1["property"]) == ["margin-top", "margin-bottom"]
    assert Enum.map(margin_records, & &1["class_id"]) == ["class-a", "class-b"]
    assert Enum.map(margin_records, & &1["class_reference_index"]) == [0, 1]
    assert Enum.map(margin_records, & &1["origin"]) == ["global_class", "global_class"]
    assert Enum.map(margin_records, & &1["source_id"]) == ["root", "root"]

    assert Enum.map(margin_records, & &1["source_key"]) == [
             "_margin.top",
             "_margin.bottom"
           ]

    assert result.artifacts["styles.css"] =~ "margin-top: 1rem;"
    assert result.artifacts["styles.css"] =~ "margin-bottom: 2rem;"
  end

  test "Stage A reports an earlier unsupported border layer after a later radius layer" do
    result =
      stage_a_result(
        ["class-a", "class-b"],
        [
          class("class-a", %{"_border" => %{"style" => "solid"}}),
          class("class-b", %{"_border" => %{"radius" => %{"top" => "4px"}}})
        ]
      )

    [unsupported] =
      Enum.filter(result.report["settings"]["unsupported"], &(&1["class_id"] == "class-a"))

    assert unsupported["source_key"] == "_border"
    assert unsupported["origin"] == "global_class"
    assert unsupported["class_reference_index"] == 0
    assert unsupported["source_id"] == "root"

    [diagnostic] =
      Enum.filter(result.report["diagnostics"]["items"], fn diagnostic ->
        diagnostic["code"] == "bricks.setting.unsupported" and
          diagnostic["metadata"]["class_id"] == "class-a"
      end)

    assert diagnostic["source_path"] == "_border"

    assert result.dependencies.style_results["root"].base_styles["border-top-left-radius"].value ==
             "4px"
  end

  test "Stage A responsive evidence retains non-overlapping declarations from both class layers" do
    result =
      stage_a_result(
        ["class-a", "class-b"],
        [
          class("class-a", %{"_margin:mobile_landscape" => %{"top" => "1rem"}}),
          class("class-b", %{"_margin:mobile_landscape" => %{"bottom" => "2rem"}})
        ]
      )

    responsive = result.report["responsive"]["entries"]
    margin_records = Enum.filter(responsive, &(&1["property"] in ["margin-top", "margin-bottom"]))

    assert Enum.map(margin_records, & &1["property"]) == ["margin-top", "margin-bottom"]
    assert Enum.map(margin_records, & &1["class_id"]) == ["class-a", "class-b"]
    assert Enum.map(margin_records, & &1["class_reference_index"]) == [0, 1]
    assert Enum.all?(margin_records, &(&1["breakpoint"] == "mobile_landscape"))
  end

  test "Stage A responsive conflict preserves both observations and omits a resolved winner" do
    result =
      stage_a_result(
        ["class-a", "class-b"],
        [
          class("class-a", %{"_rowGap:mobile_landscape" => "1rem"}),
          class("class-b", %{"_rowGap:mobile_landscape" => "2rem"})
        ]
      )

    responsive = result.report["responsive"]["entries"]
    row_gap_records = Enum.filter(responsive, &(&1["property"] == "row-gap"))

    [diagnostic] =
      Enum.filter(
        result.report["diagnostics"]["items"],
        &(&1["code"] == "bricks.style.precedence_conflict")
      )

    assert Enum.map(row_gap_records, & &1["class_id"]) == ["class-a", "class-b"]
    assert Enum.map(row_gap_records, & &1["class_reference_index"]) == [0, 1]
    assert diagnostic["metadata"]["property"] == "row-gap"
    assert result.dependencies.style_results["root"].responsive == []
  end

  test "tags malformed recognized layers on their existing Settings diagnostic" do
    document =
      document(
        ["class-a", "class-b"],
        [
          class("class-a", %{"_margin" => "not-an-object"}),
          class("class-b", %{"_rowGap" => "2rem"})
        ]
      )

    [diagnostic] = Enum.filter(document.diagnostics, &(&1.code == "bricks.setting.unsupported"))
    assert diagnostic.metadata["style_layer_state"] == "malformed_layer"
    assert diagnostic.metadata["class_id"] == "class-a"
    assert diagnostic.metadata["source_path"] == "_margin"
    assert root(document).styles["row-gap"].value == "2rem"
  end

  test "tags malformed structured leaves on their existing Settings diagnostic" do
    document =
      document(
        ["class-a"],
        [class("class-a", %{"_background" => %{"color" => %{"raw" => 42}}})]
      )

    [diagnostic] = Enum.filter(document.diagnostics, &(&1.code == "bricks.setting.unsupported"))
    assert diagnostic.metadata["style_layer_state"] == "malformed_layer"
    assert diagnostic.metadata["class_id"] == "class-a"
    assert diagnostic.metadata["source_path"] == "_background.color.raw"
  end

  test "omits a conflicting class margin property and retains both contributors" do
    document =
      document(
        ["class-a", "class-b"],
        [
          class("class-a", %{"_margin" => %{"top" => "1rem"}}),
          class("class-b", %{"_margin" => %{"top" => "2rem"}})
        ]
      )

    refute Map.has_key?(root(document).styles, "margin-top")
    assert [diagnostic] = precedence_diagnostics(document)
    assert diagnostic.severity == :warning
    assert diagnostic.metadata["property"] == "margin-top"
    assert diagnostic.metadata["resolution"] == "unresolved_precedence"

    assert Enum.map(diagnostic.metadata["contributors"], & &1["class_id"]) == [
             "class-a",
             "class-b"
           ]

    refute Enum.any?(document.diagnostics, &(&1.code == "bricks.setting.value_unresolved"))
  end

  test "a single unsafe value remains unresolved with its layer provenance" do
    document = document(["class-a"], [class("class-a", %{"_width" => 12})])

    style = root(document).styles["width"]
    assert %StyleValue{kind: :unresolved, value: 12} = style
    assert [contributor] = style.metadata["contributors"]
    assert contributor["class_id"] == "class-a"
    assert contributor["source_path"] == "_width"
  end

  test "identical unsafe values retain evidence without claiming a normalized duplicate" do
    document =
      document(
        ["class-a", "class-b"],
        [class("class-a", %{"_width" => 12}), class("class-b", %{"_width" => 12})]
      )

    style = root(document).styles["width"]
    assert %StyleValue{kind: :unresolved, value: 12} = style
    assert style.metadata["precedence"] == "identical_unresolved_evidence"
    assert length(style.metadata["contributors"]) == 2
    assert precedence_diagnostics(document) == []
  end

  test "a conflict suppresses only its property" do
    document =
      document(
        ["class-a", "class-b"],
        [
          class("class-a", %{
            "_margin" => %{"top" => "1rem", "bottom" => "2rem"},
            "_rowGap" => "3rem"
          }),
          class("class-b", %{"_margin" => %{"top" => "4rem"}})
        ]
      )

    refute Map.has_key?(root(document).styles, "margin-top")
    assert %StyleValue{value: "2rem"} = root(document).styles["margin-bottom"]
    assert %StyleValue{value: "3rem"} = root(document).styles["row-gap"]
    assert length(precedence_diagnostics(document)) == 1
  end

  test "collapses exact duplicate declarations and retains all contributors" do
    document =
      document(
        ["class-a", "class-b"],
        [
          class("class-a", %{"_margin" => %{"top" => "1rem"}}),
          class("class-b", %{"_margin" => %{"top" => "1rem"}})
        ]
      )

    style = root(document).styles["margin-top"]
    assert %StyleValue{value: "1rem"} = style
    assert style.metadata["precedence"] == "equivalent_duplicate"
    assert Enum.map(style.metadata["contributors"], & &1["class_id"]) == ["class-a", "class-b"]
    assert precedence_diagnostics(document) == []
  end

  test "does not treat zero and zero pixels as equivalent values" do
    document =
      document(
        ["class-a", "class-b"],
        [class("class-a", %{"_width" => "0"}), class("class-b", %{"_width" => "0px"})]
      )

    refute Map.has_key?(root(document).styles, "width")
    assert [diagnostic] = precedence_diagnostics(document)
    assert diagnostic.metadata["property"] == "width"
    assert diagnostic.metadata["conflict"] == "class_conflict"
  end

  test "different unsafe values from class layers do not select an unresolved style winner" do
    document =
      document(
        ["class-a", "class-b"],
        [class("class-a", %{"_width" => 12}), class("class-b", %{"_width" => 24})]
      )

    refute Map.has_key?(root(document).styles, "width")
    assert [diagnostic] = precedence_diagnostics(document)
    assert diagnostic.metadata["property"] == "width"

    assert Enum.map(diagnostic.metadata["contributors"], & &1["class_id"]) == [
             "class-a",
             "class-b"
           ]
  end

  test "same direct scalar source key keeps the established element-local override" do
    document =
      document(
        ["class-a"],
        [class("class-a", %{"_width" => "100px"})],
        %{"_width" => "50%"}
      )

    style = root(document).styles["width"]
    assert %StyleValue{value: "50%"} = style
    assert style.metadata["precedence"] == "element_local_same_source_key_project_contract"

    assert Enum.map(style.metadata["contributors"], & &1["origin"]) == [
             "global_class",
             "element_local"
           ]

    assert hd(style.metadata["contributors"])["resolution_source"] == "local"

    assert precedence_diagnostics(document) == []
  end

  test "external class contributors retain authority and resolution provenance" do
    external_class = class("class-a", %{"_width" => "100px"})

    document =
      document(["class-a"], [], %{},
        external_class_authorities: [
          %{id: "site-classes", global_classes: [external_class]}
        ]
      )

    [contributor] = root(document).styles["width"].metadata["contributors"]
    assert contributor["resolution_source"] == "external"
    assert contributor["authority_ids"] == ["site-classes"]
  end

  test "different alias keys with different class and local values remain unresolved" do
    document =
      document(
        ["class-a"],
        [class("class-a", %{"_alignItemsGrid" => "start"})],
        %{"_alignItems" => "center"}
      )

    refute Map.has_key?(root(document).styles, "align-items")
    assert [diagnostic] = precedence_diagnostics(document)
    assert diagnostic.metadata["property"] == "align-items"

    assert Enum.map(diagnostic.metadata["contributors"], & &1["source_root_key"]) == [
             "_alignItemsGrid",
             "_alignItems"
           ]
  end

  test "different alias keys with exact equal values collapse as equivalent" do
    document =
      document(
        ["class-a"],
        [class("class-a", %{"_alignItemsGrid" => "center"})],
        %{"_alignItems" => "center"}
      )

    style = root(document).styles["align-items"]
    assert %StyleValue{value: "center"} = style
    assert style.metadata["precedence"] == "equivalent_duplicate"
    assert length(style.metadata["contributors"]) == 2
    assert precedence_diagnostics(document) == []
  end

  test "class reference order never selects a differing class value" do
    classes = [
      class("class-a", %{"_margin" => %{"top" => "1rem"}}),
      class("class-b", %{"_margin" => %{"top" => "2rem"}})
    ]

    first = document(["class-a", "class-b"], classes)
    reversed = document(["class-b", "class-a"], classes)

    refute Map.has_key?(root(first).styles, "margin-top")
    refute Map.has_key?(root(reversed).styles, "margin-top")
    assert length(precedence_diagnostics(first)) == 1
    assert length(precedence_diagnostics(reversed)) == 1
  end

  test "precedence diagnostics serialize deterministically across repeated conversion" do
    classes = [
      class("class-a", %{"_margin" => %{"top" => "1rem"}}),
      class("class-b", %{"_margin" => %{"top" => "2rem"}})
    ]

    first = classes |> then(&document(["class-a", "class-b"], &1))
    second = classes |> then(&document(["class-a", "class-b"], &1))

    assert IR.encode!(first) == IR.encode!(second)
  end

  test "contributors follow reference order with element-local last" do
    document =
      document(
        ["class-b", "class-a"],
        [
          class("class-a", %{"_margin" => %{"top" => "1rem"}}),
          class("class-b", %{"_margin" => %{"top" => "1rem"}})
        ],
        %{"_margin" => %{"top" => "1rem"}}
      )

    contributors = root(document).styles["margin-top"].metadata["contributors"]
    assert Enum.map(contributors, & &1["class_id"]) == ["class-b", "class-a", nil]
    assert Enum.map(contributors, & &1["class_reference_index"]) == [0, 1, nil]
    assert List.last(contributors)["origin"] == "element_local"
  end

  test "responsive declarations in distinct exact labels do not conflict" do
    document =
      document(
        ["class-a", "class-b"],
        [
          class("class-a", %{"_rowGap:mobile_landscape" => "1rem"}),
          class("class-b", %{"_rowGap:tablet_portrait" => "2rem"})
        ]
      )

    assert %StyleValue{value: "1rem"} =
             root(document).responsive["mobile_landscape"].styles["row-gap"]

    assert %StyleValue{value: "2rem"} =
             root(document).responsive["tablet_portrait"].styles["row-gap"]

    assert precedence_diagnostics(document) == []
  end

  test "keeps Design IR version 1.0.0" do
    document = document([], [], %{"_width" => "100px"})
    assert document.ir_version == "1.0.0"
  end

  test "contributor metadata survives the Design IR serializer" do
    document =
      document(
        ["class-a"],
        [class("class-a", %{"_margin" => %{"top" => "1rem"}})]
      )

    serialized = document |> IR.encode!() |> Jason.decode!()

    contributors =
      serialized["root_nodes"]
      |> hd()
      |> get_in(["styles", "margin-top", "metadata", "contributors"])

    assert length(contributors) == 1
    assert hd(contributors)["class_id"] == "class-a"
    assert hd(contributors)["source_path"] == "_margin.top"
  end

  test "Fidelity emits resolved properties and omits the conflicted property" do
    document =
      document(
        ["class-a", "class-b"],
        [
          class("class-a", %{"_margin" => %{"top" => "1rem", "bottom" => "2rem"}}),
          class("class-b", %{"_margin" => %{"top" => "4rem"}})
        ]
      )

    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.css =~ "margin-top:"
    assert bundle.css =~ "margin-bottom: 2rem;"
  end

  test "existing C-05A scalar mappings remain available across layers" do
    document =
      document(
        ["class-a"],
        [
          class("class-a", %{
            "_alignItems" => "center",
            "_gridTemplateColumns" => "repeat(2, 1fr)",
            "_width" => "100px"
          })
        ],
        %{"_opacity" => "0.75"}
      )

    styles = root(document).styles
    assert styles["align-items"].value == "center"
    assert styles["grid-template-columns"].value == "repeat(2, 1fr)"
    assert styles["width"].value == "100px"
    assert styles["opacity"].value == "0.75"
  end

  test "variables from every class layer remain in dependency provenance" do
    document =
      document(
        ["class-a", "class-b"],
        [
          class("class-a", %{"_width" => "var(--class-a-width)"}),
          class("class-b", %{"_width" => "var(--class-b-width)"})
        ]
      )

    variables = document.provenance["dependency_summary"]["variables"]

    assert Enum.map(variables, & &1["name"]) |> Enum.sort() == [
             "--class-a-width",
             "--class-b-width"
           ]

    assert Enum.find(variables, &(&1["name"] == "--class-a-width"))["occurrences"]
           |> Enum.map(& &1["source_path"]) == ["settings.class_refs[0].settings._width"]

    assert Enum.find(variables, &(&1["name"] == "--class-b-width"))["occurrences"]
           |> Enum.map(& &1["source_path"]) == ["settings.class_refs[1].settings._width"]

    refute Map.has_key?(root(document).styles, "width")
    assert length(precedence_diagnostics(document)) == 1
  end

  test "equivalent variable declarations retain every class source path" do
    document =
      document(
        ["class-a", "class-b"],
        [
          class("class-a", %{"_width" => "var(--shared-width)"}),
          class("class-b", %{"_width" => "var(--shared-width)"})
        ]
      )

    variable =
      Enum.find(
        document.provenance["dependency_summary"]["variables"],
        &(&1["name"] == "--shared-width")
      )

    assert Enum.map(variable["occurrences"], & &1["source_path"]) == [
             "settings.class_refs[0].settings._width",
             "settings.class_refs[1].settings._width"
           ]
  end
end
