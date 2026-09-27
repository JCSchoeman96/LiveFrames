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

  test "leaves compound and stopped properties unsupported" do
    settings = %{
      "_gridGap" => "1rem",
      "_padding" => %{"top" => "1rem", "right" => "2rem"},
      "_typography" => %{"fontSize" => "1rem"},
      "_border" => %{
        "style" => "solid",
        "color" => "#000",
        "width" => %{"top" => "1px"}
      },
      "_boxShadow" => "0 1px 2px black",
      "_hidden" => true,
      "_cssCustomSass" => "$color: red;"
    }

    result = Settings.extract(settings)

    assert result.base_styles == %{}

    assert MapSet.new(Enum.map(result.unsupported, & &1.source_key)) ==
             MapSet.new([
               "_gridGap",
               "_padding",
               "_typography",
               "_border",
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
