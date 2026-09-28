defmodule LiveFrames.BricksStructuredStylesTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Adapters.Bricks.Settings
  alias LiveFrames.Fidelity
  alias LiveFrames.IR.StyleValue
  alias LiveFrames.Tokens.TokenSet

  @mappings [
    {"_alignContentGrid", "align-content"},
    {"_alignItemsGrid", "align-items"},
    {"_alignSelf", "align-self"},
    {"_aspectRatio", "aspect-ratio"},
    {"_cssTransition", "transition"},
    {"_cursor", "cursor"},
    {"_flexGrow", "flex-grow"},
    {"_gridTemplateColumns", "grid-template-columns"},
    {"_gridTemplateRows", "grid-template-rows"},
    {"_heightMax", "max-height"},
    {"_heightMin", "min-height"},
    {"_justifyItemsGrid", "justify-items"},
    {"_opacity", "opacity"},
    {"_order", "order"},
    {"_overflow", "overflow"}
  ]

  @values %{
    "_alignContentGrid" => "space-between",
    "_alignItemsGrid" => "center",
    "_alignSelf" => "stretch",
    "_aspectRatio" => "16 / 9",
    "_cssTransition" => "opacity 200ms ease",
    "_cursor" => "pointer",
    "_flexGrow" => "1.5",
    "_gridTemplateColumns" => "repeat(3, minmax(0, 1fr))",
    "_gridTemplateRows" => "auto 1fr",
    "_heightMax" => "80vh",
    "_heightMin" => "20rem",
    "_justifyItemsGrid" => "center",
    "_opacity" => "0.65",
    "_order" => "-1",
    "_overflow" => "auto"
  }

  test "registers exactly the approved explicit mappings" do
    assert map_size(Settings.style_properties()) == 34

    assert Map.take(Settings.style_properties(), Enum.map(@mappings, &elem(&1, 0))) ==
             Map.new(@mappings)

    result = Settings.extract(@values)

    assert result.base_styles ==
             Map.new(@mappings, fn {source_key, property} ->
               {property, Map.fetch!(@values, source_key)}
             end)

    assert result.unsupported == []
    assert result.unresolved_values == %{}
  end

  test "propagates every mapping through Design IR and Fidelity CSS" do
    assert {:ok, document} =
             Bricks.to_ir(source(@values), component_id: "component-a", token_set: TokenSet.new())

    [node] = document.root_nodes

    for {source_key, property} <- @mappings do
      value = Map.fetch!(@values, source_key)
      assert %StyleValue{source_expression: ^value} = node.styles[property]
    end

    assert {:ok, bundle} = Fidelity.generate(document)

    for {_source_key, property} <- @mappings do
      assert bundle.css =~ "#{property}:"
    end
  end

  test "applies narrow numeric rules to order, flex-grow, opacity, and aspect-ratio" do
    for order <- ["7", "0", "-2", "-1", "+3"] do
      assert %{"order" => ^order} = Settings.extract(%{"_order" => order}).base_styles
    end

    accepted_css_numbers = [
      "0",
      "1",
      "+1",
      "1.0",
      "0.5",
      ".5",
      "1e2",
      "1e+2",
      "1e-2",
      "1.25e-2"
    ]

    for number <- accepted_css_numbers do
      assert %{"flex-grow" => ^number} = Settings.extract(%{"_flexGrow" => number}).base_styles
    end

    for number <- ["0", "1", "+1", "1.0", "0.5", ".5", "1e-2", "1.25e-2"] do
      assert %{"opacity" => ^number} = Settings.extract(%{"_opacity" => number}).base_styles
    end

    assert %{"opacity" => "1e-9999"} = Settings.extract(%{"_opacity" => "1e-9999"}).base_styles
    assert %{"flex-grow" => "inherit"} = Settings.extract(%{"_flexGrow" => "inherit"}).base_styles

    assert %{"aspect-ratio" => "16 / 9"} =
             Settings.extract(%{"_aspectRatio" => "16 / 9"}).base_styles

    assert %{"aspect-ratio" => "auto"} =
             Settings.extract(%{"_aspectRatio" => "auto"}).base_styles

    assert %{"aspect-ratio" => "auto 16 / 9"} =
             Settings.extract(%{"_aspectRatio" => "auto 16 / 9"}).base_styles

    assert %{"aspect-ratio" => "1.5"} =
             Settings.extract(%{"_aspectRatio" => "1.5"}).base_styles

    assert %{"aspect-ratio" => ".75"} =
             Settings.extract(%{"_aspectRatio" => ".75"}).base_styles

    assert %{"aspect-ratio" => "1e-9999"} =
             Settings.extract(%{"_aspectRatio" => "1e-9999"}).base_styles

    for keyword <- ["inherit", "initial", "revert", "revert-layer", "unset"] do
      assert %{"aspect-ratio" => ^keyword} =
               Settings.extract(%{"_aspectRatio" => keyword}).base_styles
    end

    for expression <- ["var(--c05-aspect-ratio, 16 / 9)", "calc(16 / 9)"] do
      assert %{"aspect-ratio" => ^expression} =
               Settings.extract(%{"_aspectRatio" => expression}).base_styles
    end

    rejected = [
      {"_flexGrow", "1."},
      {"_flexGrow", "1.e2"},
      {"_flexGrow", "."},
      {"_flexGrow", "1e"},
      {"_flexGrow", "1e+"},
      {"_flexGrow", "1e-"},
      {"_order", "1.2"},
      {"_order", "1e2"},
      {"_order", "1e"},
      {"_order", "auto"},
      {"_opacity", "1."},
      {"_opacity", "1.e2"},
      {"_opacity", "."},
      {"_opacity", "1e"},
      {"_opacity", "1e+"},
      {"_opacity", "1e-"},
      {"_opacity", "1e2"},
      {"_flexGrow", "-1"},
      {"_flexGrow", "-0e-9999"},
      {"_flexGrow", "1e"},
      {"_flexGrow", "auto"},
      {"_opacity", "1.01"},
      {"_opacity", "-0.01"},
      {"_opacity", "-0e-9999"},
      {"_opacity", "0.5%"},
      {"_opacity", "auto"},
      {"_opacity", "1e"},
      {"_opacity", "1.00000000000000001"},
      {"_aspectRatio", "0"},
      {"_aspectRatio", "-1"},
      {"_aspectRatio", "1."},
      {"_aspectRatio", "1.e2"},
      {"_aspectRatio", "1e"},
      {"_aspectRatio", "0 / 1"},
      {"_aspectRatio", "-1 / 2"},
      {"_aspectRatio", "1 / 0"},
      {"_aspectRatio", "foo"},
      {"_aspectRatio", "wide"},
      {"_aspectRatio", "ratio"},
      {"_aspectRatio", "16px"},
      {"_aspectRatio", "foo/bar"}
    ]

    for {source_key, value} <- rejected do
      result = Settings.extract(%{source_key => value})
      assert result.base_styles == %{}
      assert result.unresolved_values[source_key] == value
    end

    assert {:ok, document} =
             Bricks.to_ir(source(%{"_aspectRatio" => "foo"}),
               component_id: "component-a",
               token_set: TokenSet.new()
             )

    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.css =~ "aspect-ratio:"
  end

  test "rejects unsafe declarations before they reach generated CSS" do
    unsafe_settings = %{
      "_cursor" => "url(https://attacker.example/cursor.cur)",
      "_gridTemplateColumns" => "repeat(2, 1fr); color: red",
      "_overflow" => "hidden} body { color: red"
    }

    result = Settings.extract(unsafe_settings)
    assert result.base_styles == %{}

    assert {:ok, document} =
             Bricks.to_ir(source(unsafe_settings),
               component_id: "component-a",
               token_set: TokenSet.new()
             )

    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.css =~ "cursor:"
    refute bundle.css =~ "grid-template-columns:"
    refute bundle.css =~ "overflow:"
    refute bundle.css =~ "attacker.example"
  end

  test "preserves a grid-template variable through existing unresolved handling" do
    expression = "var(--c05-grid-columns)"

    assert {:ok, document} =
             Bricks.to_ir(source(%{"_gridTemplateColumns" => expression}),
               component_id: "component-a",
               token_set: TokenSet.new()
             )

    [node] = document.root_nodes

    assert %StyleValue{
             kind: :unresolved,
             value: ^expression,
             source_expression: ^expression
           } = node.styles["grid-template-columns"]

    assert [%{"name" => "--c05-grid-columns", "status" => "source_variable", "token_path" => nil}] =
             document.provenance["dependency_summary"]["variables"]

    assert Enum.any?(document.diagnostics, &(&1.code == "bricks.variable.unresolved"))
  end

  test "preserves responsive names without inventing thresholds or media queries" do
    property_value = "repeat(2, minmax(0, 1fr))"

    assert {:ok, document} =
             Bricks.to_ir(source(%{"_gridTemplateColumns:mobile_landscape" => property_value}),
               component_id: "component-a",
               token_set: TokenSet.new()
             )

    [node] = document.root_nodes
    override = node.responsive["mobile_landscape"]

    assert override.source_name == "mobile_landscape"
    assert override.resolution_status == :unresolved
    assert override.min_width == nil
    assert override.max_width == nil
    assert %StyleValue{value: ^property_value} = override.styles["grid-template-columns"]
    assert Enum.any?(document.diagnostics, &(&1.code == "bricks.breakpoint.unresolved"))

    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.css =~ "@media"
    refute bundle.css =~ "grid-template-columns:"
  end

  test "maps padding sides with the existing box-value rules and exact paths" do
    result =
      Settings.extract(%{
        "_padding" => %{
          "top" => 12,
          "right" => 0,
          "bottom" => "1.5rem",
          "left" => "var(--padding-left)"
        }
      })

    assert result.base_styles == %{
             "padding-top" => "12px",
             "padding-right" => "0",
             "padding-bottom" => "1.5rem",
             "padding-left" => "var(--padding-left)"
           }

    assert Enum.map(result.declarations, &{&1.source_root_key, &1.source_path}) == [
             {"_padding", "_padding.top"},
             {"_padding", "_padding.right"},
             {"_padding", "_padding.bottom"},
             {"_padding", "_padding.left"}
           ]

    partial = Settings.extract(%{"_padding" => %{"left" => "clamp(1rem, 2vw, 3rem)"}})

    assert partial.base_styles == %{
             "padding-left" => "clamp(1rem, 2vw, 3rem)"
           }
  end

  test "keeps unsafe padding unresolved and diagnoses a malformed root once" do
    unsafe =
      Settings.extract(%{
        "_padding" => %{
          "top" => "2rem; color: red",
          "left" => ["1rem"]
        }
      })

    assert unsafe.base_styles == %{}
    assert unsafe.unresolved_values["_padding.top"] == "2rem; color: red"
    assert unsafe.unresolved_values["_padding.left"] == ["1rem"]

    malformed = Settings.extract(%{"_padding" => []})
    assert malformed.declarations == []
    assert [%{source_key: "_padding"}] = malformed.unsupported
    assert [diagnostic] = malformed.diagnostics
    assert diagnostic.source_path == "_padding"
  end

  test "maps the eight approved typography leaves independently" do
    result =
      Settings.extract(%{
        "_typography" => %{
          "color" => %{"raw" => "#34495e"},
          "font-size" => "1.25rem",
          "font-weight" => "650",
          "letter-spacing" => "0.03em",
          "line-height" => "1.4",
          "text-align" => "center",
          "text-transform" => "uppercase",
          "text-wrap" => "balance"
        }
      })

    assert result.base_styles == %{
             "color" => "#34495e",
             "font-size" => "1.25rem",
             "font-weight" => "650",
             "letter-spacing" => "0.03em",
             "line-height" => "1.4",
             "text-align" => "center",
             "text-transform" => "uppercase",
             "text-wrap" => "balance"
           }

    assert Enum.map(result.declarations, &{&1.property, &1.source_root_key, &1.source_path}) == [
             {"color", "_typography", "_typography.color.raw"},
             {"font-size", "_typography", "_typography.font-size"},
             {"font-weight", "_typography", "_typography.font-weight"},
             {"letter-spacing", "_typography", "_typography.letter-spacing"},
             {"line-height", "_typography", "_typography.line-height"},
             {"text-align", "_typography", "_typography.text-align"},
             {"text-transform", "_typography", "_typography.text-transform"},
             {"text-wrap", "_typography", "_typography.text-wrap"}
           ]
  end

  test "propagates compound declarations through Design IR and Fidelity" do
    expected = %{
      "padding-top" => "1rem",
      "padding-left" => "0",
      "color" => "#34495e",
      "font-size" => "1.25rem",
      "font-weight" => "600",
      "letter-spacing" => "0.03em",
      "line-height" => "1.4",
      "text-align" => "center",
      "text-transform" => "uppercase",
      "text-wrap" => "balance",
      "border-style" => "solid",
      "border-color" => "#123456",
      "border-top-width" => "1px",
      "border-top-left-radius" => "2px"
    }

    settings = %{
      "_padding" => %{"top" => "1rem", "left" => "0"},
      "_typography" => %{
        "color" => %{"raw" => "#34495e"},
        "font-size" => "1.25rem",
        "font-weight" => "600",
        "letter-spacing" => "0.03em",
        "line-height" => "1.4",
        "text-align" => "center",
        "text-transform" => "uppercase",
        "text-wrap" => "balance"
      },
      "_border" => %{
        "style" => "solid",
        "color" => %{"raw" => "#123456"},
        "width" => %{"top" => "1px"},
        "radius" => %{"top" => "2px"}
      }
    }

    assert {:ok, document} =
             Bricks.to_ir(source(settings),
               component_id: "component-a",
               token_set: TokenSet.new()
             )

    [node] = document.root_nodes

    for {property, value} <- expected do
      assert %StyleValue{value: ^value} = node.styles[property]
    end

    assert {:ok, bundle} = Fidelity.generate(document)

    for {property, value} <- expected do
      assert bundle.css =~ "#{property}: #{value};"
    end
  end

  test "accepts only the bounded font-weight grammar" do
    accepted_numbers = [
      {1, "1"},
      {100, "100"},
      {400, "400"},
      {"500.5", "500.5"},
      {1000, "1000"}
    ]

    accepted_keywords = [
      "normal",
      "bold",
      "bolder",
      "lighter",
      "inherit",
      "initial",
      "revert",
      "revert-layer",
      "unset"
    ]

    accepted_expressions = [
      "var(--font-weight)",
      "calc(300 + 100)",
      "clamp(100, 400, 900)",
      "min(400, 700)",
      "max(400, 700)"
    ]

    for {source_value, css_value} <-
          accepted_numbers ++
            Enum.map(accepted_keywords ++ accepted_expressions, &{&1, &1}) do
      result = Settings.extract(%{"_typography" => %{"font-weight" => source_value}})
      assert result.base_styles == %{"font-weight" => css_value}
      assert_fidelity_css_value("font-weight", css_value)
    end
  end

  test "keeps rejected font-weight values unresolved and out of Fidelity CSS" do
    for value <- [
          0,
          -1,
          1000.1,
          1001,
          "400px",
          "400foo",
          "banana",
          "medium",
          "1.",
          "1e",
          "400; color: red"
        ] do
      assert_unresolved_fidelity_style("font-weight", value)
    end
  end

  test "accepts only the bounded line-height grammar" do
    accepted_numbers = [
      {0, "0"},
      {1, "1"},
      {"1.4", "1.4"},
      {".8", ".8"},
      {"1e2", "1e2"},
      {"1e-2", "1e-2"}
    ]

    accepted_dimensions = [
      "0px",
      "0%",
      "+1px",
      "24px",
      "1em",
      "1.5rem",
      "120%",
      "2vh",
      "2vw",
      "2vmin",
      "2vmax",
      "2ch",
      "2ex",
      "2cm",
      "2mm",
      "2in",
      "2pt",
      "2pc"
    ]

    accepted_keywords = ["normal", "inherit", "initial", "revert", "revert-layer", "unset"]

    accepted_expressions = [
      "var(--line-height)",
      "calc(1 + 0.4)",
      "clamp(1.2, 2vw, 1.8)",
      "min(1.2, 1.8)",
      "max(1.2, 1.8)"
    ]

    accepted_values =
      accepted_numbers ++
        Enum.map(accepted_dimensions ++ accepted_keywords ++ accepted_expressions, &{&1, &1})

    for {source_value, css_value} <- accepted_values do
      result = Settings.extract(%{"_typography" => %{"line-height" => source_value}})
      assert result.base_styles == %{"line-height" => css_value}
      assert_fidelity_css_value("line-height", css_value)
    end
  end

  test "keeps rejected line-height values unresolved and out of Fidelity CSS" do
    for value <- [
          -1,
          "-1",
          "banana",
          "compact",
          "tight",
          "12banana",
          "12pixels",
          "1solid",
          "-1px",
          "-2rem",
          "-20%",
          "-1vh",
          "-1e2px",
          "1.",
          "1e",
          "1.4; color: red"
        ] do
      assert_unresolved_fidelity_style("line-height", value)
    end
  end

  test "does not extend bare-number support to unrelated dimensional properties" do
    for value <- ["12", 12] do
      result = Settings.extract(%{"_width" => value})
      assert result.base_styles == %{}
      assert Map.has_key?(result.unresolved_values, "_width")
    end

    for {source_leaf, value} <- [{"font-size", 24}, {"letter-spacing", "2"}] do
      result = Settings.extract(%{"_typography" => %{source_leaf => value}})
      assert result.base_styles == %{}
      assert Map.has_key?(result.unresolved_values, "_typography.#{source_leaf}")
    end
  end

  defp assert_unresolved_fidelity_style(property, value) do
    result = Settings.extract(%{"_typography" => %{property => value}})
    source_path = "_typography.#{property}"

    assert result.base_styles == %{}
    assert result.unresolved_values[source_path] == value

    assert {:ok, document} =
             Bricks.to_ir(source(%{"_typography" => %{property => value}}),
               component_id: "component-a",
               token_set: TokenSet.new()
             )

    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.css =~ "#{property}:"
  end

  defp assert_fidelity_css_value(property, value) do
    assert {:ok, document} =
             Bricks.to_ir(source(%{"_typography" => %{property => value}}),
               component_id: "component-a",
               token_set: TokenSet.new()
             )

    if String.starts_with?(value, "var(") do
      [node] = document.root_nodes
      assert %StyleValue{kind: :unresolved, value: ^value} = node.styles[property]

      assert [%{"name" => variable_name, "token_path" => nil}] =
               document.provenance["dependency_summary"]["variables"]

      assert String.starts_with?(variable_name, "--")
    else
      assert {:ok, bundle} = Fidelity.generate(document)
      assert bundle.css =~ "#{property}: #{value};"
    end
  end

  test "keeps typography variables and unsafe values on the established paths" do
    expression = "var(--content-color)"

    assert {:ok, document} =
             Bricks.to_ir(
               source(%{"_typography" => %{"color" => %{"raw" => expression}}}),
               component_id: "component-a",
               token_set: TokenSet.new()
             )

    [node] = document.root_nodes

    assert %StyleValue{kind: :unresolved, value: ^expression} = node.styles["color"]

    assert [%{"name" => "--content-color", "token_path" => nil}] =
             document.provenance["dependency_summary"]["variables"]

    unsafe_settings = %{
      "_padding" => %{"top" => "2rem; color: red"},
      "_border" => %{
        "style" => "solid; color: red",
        "color" => %{"raw" => "red; color: blue"},
        "width" => %{"left" => "1px; color: red"}
      },
      "_typography" => %{
        "font-size" => "2rem; color: red",
        "line-height" => "1.4"
      }
    }

    result = Settings.extract(unsafe_settings)
    assert result.base_styles == %{"line-height" => "1.4"}
    assert result.unresolved_values["_padding.top"] == "2rem; color: red"
    assert result.unresolved_values["_border.style"] == "solid; color: red"
    assert result.unresolved_values["_border.color.raw"] == "red; color: blue"
    assert result.unresolved_values["_border.width.left"] == "1px; color: red"

    assert {:ok, unsafe_document} =
             Bricks.to_ir(source(unsafe_settings),
               component_id: "component-a",
               token_set: TokenSet.new()
             )

    assert {:ok, bundle} = Fidelity.generate(unsafe_document)
    refute bundle.css =~ "padding-top:"
    refute bundle.css =~ "border-style:"
    refute bundle.css =~ "border-color:"
    refute bundle.css =~ "border-left-width:"
    refute bundle.css =~ "font-size:"
    assert bundle.css =~ "line-height: 1.4;"
  end

  test "diagnoses unknown typography children without mapping them" do
    result =
      Settings.extract(%{
        "_typography" => %{
          "font-size" => "1rem",
          "fontSize" => "2rem",
          "font-family" => %{"raw" => "Inter"}
        }
      })

    assert result.base_styles == %{"font-size" => "1rem"}
    assert [%{source_key: "_typography"}] = result.unsupported
    refute Map.has_key?(result.base_styles, "font-family")
    refute Map.has_key?(result.base_styles, "font-size-legacy")
  end

  test "diagnoses an empty-list typography root once" do
    result = Settings.extract(%{"_typography" => []})

    assert result.declarations == []
    assert [%{source_key: "_typography"}] = result.unsupported
    assert [diagnostic] = result.diagnostics
    assert diagnostic.source_path == "_typography"
  end

  test "requires typography color raw values to be present as strings" do
    result = Settings.extract(%{"_typography" => %{"color" => %{}}})

    assert result.declarations == []
    assert [%{source_key: "_typography.color.raw"}] = result.unsupported
    assert [diagnostic] = result.diagnostics
    assert diagnostic.message =~ "must be a string"
  end

  test "maps border style, color, widths, and radius independently" do
    result =
      Settings.extract(%{
        "_border" => %{
          "style" => "solid",
          "color" => %{"raw" => "var(--border-color)"},
          "width" => %{
            "top" => 2,
            "right" => 0,
            "bottom" => "0.25rem",
            "left" => "var(--border-left-width)"
          },
          "radius" => %{"top" => "4px"}
        }
      })

    assert result.base_styles == %{
             "border-style" => "solid",
             "border-color" => "var(--border-color)",
             "border-top-width" => "2px",
             "border-right-width" => "0",
             "border-bottom-width" => "0.25rem",
             "border-left-width" => "var(--border-left-width)",
             "border-top-left-radius" => "4px"
           }

    assert Enum.map(result.declarations, &{&1.source_root_key, &1.source_path}) == [
             {"_border", "_border.radius.top"},
             {"_border", "_border.style"},
             {"_border", "_border.color.raw"},
             {"_border", "_border.width.top"},
             {"_border", "_border.width.right"},
             {"_border", "_border.width.bottom"},
             {"_border", "_border.width.left"}
           ]

    partial = Settings.extract(%{"_border" => %{"width" => %{"left" => 3}}})
    assert partial.base_styles == %{"border-left-width" => "3px"}

    malformed_width =
      Settings.extract(%{
        "_border" => %{"style" => "dashed", "width" => "2px"}
      })

    assert malformed_width.base_styles == %{"border-style" => "dashed"}
    assert [%{source_key: "_border.width"}] = malformed_width.unsupported

    unknown =
      Settings.extract(%{
        "_border" => %{"style" => "solid", "shadow" => %{"color" => "red"}}
      })

    assert unknown.base_styles == %{"border-style" => "solid"}
    assert [%{source_key: "_border"}] = unknown.unsupported
  end

  test "keeps unsafe border leaves unresolved and rejects malformed color shapes" do
    result =
      Settings.extract(%{
        "_border" => %{
          "style" => "solid; color: red",
          "color" => %{"raw" => 42},
          "width" => %{"top" => "1px; color: red"}
        }
      })

    assert result.base_styles == %{}
    assert result.unresolved_values["_border.style"] == "solid; color: red"
    assert result.unresolved_values["_border.width.top"] == "1px; color: red"
    assert [%{source_key: "_border.color.raw"}] = result.unsupported

    malformed = Settings.extract(%{"_border" => []})
    assert malformed.declarations == []
    assert [%{source_key: "_border"}] = malformed.unsupported
  end

  test "keeps exact responsive source labels, paths, and unresolved thresholds" do
    result =
      Settings.extract(%{
        "_padding:mobile_landscape" => %{"top" => "2"},
        "_typography:mobile_landscape" => %{"line-height" => "1.5"}
      })

    assert Enum.map(result.declarations, &{&1.source_root_key, &1.source_path, &1.breakpoint}) ==
             [
               {"_padding", "_padding:mobile_landscape.top", "mobile_landscape"},
               {
                 "_typography",
                 "_typography:mobile_landscape.line-height",
                 "mobile_landscape"
               }
             ]

    assert Enum.all?(result.responsive, fn record ->
             record.threshold_status == :unresolved and is_nil(record.min_width) and
               is_nil(record.max_width)
           end)
  end

  test "keeps unapproved and stopped properties unsupported" do
    settings = %{
      "_gridGap" => "1rem",
      "_boxShadow" => "0 1px 2px black",
      "_hidden" => true,
      "_cssCustomSass" => "$color: red;"
    }

    result = Settings.extract(settings)

    assert result.base_styles == %{}

    assert MapSet.new(Enum.map(result.unsupported, & &1.source_key)) ==
             MapSet.new([
               "_gridGap",
               "_boxShadow",
               "_hidden",
               "_cssCustomSass"
             ])
  end

  defp source(settings) do
    %{
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
              "settings" => settings
            }
          ]
        }
      ],
      "globalClasses" => []
    }
  end
end
