defmodule LiveFrames.BricksStylePrecedenceTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Fidelity
  alias LiveFrames.IR
  alias LiveFrames.IR.StyleValue
  alias LiveFrames.Tokens.TokenSet

  defp class(id, settings) do
    %{"id" => id, "name" => id, "settings" => settings}
  end

  defp document(class_refs, class_definitions, element_settings \\ %{}, opts \\ []) do
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
              "name" => "div",
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
               Keyword.merge([component_id: "component-a", token_set: TokenSet.new()], opts)
             )

    document
  end

  defp root(document), do: hd(document.root_nodes)

  defp precedence_diagnostics(document) do
    Enum.filter(document.diagnostics, &(&1.code == "bricks.style.precedence_conflict"))
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

    refute Map.has_key?(root(document).styles, "width")
    assert length(precedence_diagnostics(document)) == 1
  end
end
