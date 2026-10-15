defmodule LiveFrames.NativeGenerator.StylesheetRendererTest do
  use ExUnit.Case, async: true

  alias LiveFrames.IR.ResponsiveOverride
  alias LiveFrames.IR.StyleValue
  alias LiveFrames.NativeGenerator.Artifact
  alias LiveFrames.NativeGenerator.StylesheetRenderer

  @private_class "lf-section-marketing-block__n-000001"

  test "renders base declarations in property order with a stable trailing newline" do
    styles = %{
      "gap" => StyleValue.literal(2),
      "display" => StyleValue.keyword("grid")
    }

    expected = ".#{@private_class} {\n  display: grid;\n  gap: 2;\n}\n"

    assert {:ok, ^expected} = StylesheetRenderer.render(@private_class, styles)

    reordered = %{
      "display" => StyleValue.keyword("grid"),
      "gap" => StyleValue.literal(2)
    }

    assert {:ok, ^expected} = StylesheetRenderer.render(@private_class, reordered)
  end

  test "renders no selector block for an empty style map" do
    assert {:ok, ""} = StylesheetRenderer.render(@private_class, %{})
  end

  test "renders only the two approved semantic pseudo states" do
    styles = %{"outline-style" => StyleValue.keyword("solid")}

    assert {:ok, ".#{@private_class}:focus-visible {\n  outline-style: solid;\n}\n"} =
             StylesheetRenderer.render_pseudo(@private_class, :focus_visible, styles)

    assert {:error, diagnostic} =
             StylesheetRenderer.render_pseudo(@private_class, :active, styles)

    assert diagnostic.code == "native_generator.styling.css_serialization_failed"
  end

  test "renders only the four generated-class hover and focus-within selectors" do
    styles = %{"opacity" => StyleValue.literal(0.5)}
    target_class = @private_class <> "__target"

    assert {:ok, ".#{@private_class}:hover {\n  opacity: 0.5;\n}\n"} =
             StylesheetRenderer.render_state_rule(
               @private_class,
               @private_class,
               :hover,
               styles,
               nil
             )

    expected = ".#{@private_class}:hover .#{target_class} {\n  opacity: 0.5;\n}\n"

    assert {:ok, ^expected} =
             StylesheetRenderer.render_state_rule(
               @private_class,
               target_class,
               :hover,
               styles,
               nil
             )

    assert {:ok, ".#{@private_class}:focus-within {\n  opacity: 0.5;\n}\n"} =
             StylesheetRenderer.render_state_rule(
               @private_class,
               @private_class,
               :focus_within,
               styles,
               nil
             )

    expected = ".#{@private_class}:focus-within .#{target_class} {\n  opacity: 0.5;\n}\n"

    assert {:ok, ^expected} =
             StylesheetRenderer.render_state_rule(
               @private_class,
               target_class,
               :focus_within,
               styles,
               nil
             )
  end

  test "renders inclusive state-rule min max range and exact-width media queries" do
    styles = %{"gap" => StyleValue.literal(2)}
    target_class = @private_class <> "__target"

    assert {:ok,
            "@media (min-width: 767px) {\n" <>
              "  .#{@private_class}:hover {\n    gap: 2;\n  }\n}\n"} =
             StylesheetRenderer.render_state_rule(
               @private_class,
               @private_class,
               :hover,
               styles,
               %{min_width: 767, max_width: nil}
             )

    expected =
      "@media (max-width: 767px) {\n" <>
        "  .#{@private_class}:hover .#{target_class} {\n    gap: 2;\n  }\n}\n"

    assert {:ok, ^expected} =
             StylesheetRenderer.render_state_rule(
               @private_class,
               target_class,
               :hover,
               styles,
               %{min_width: nil, max_width: 767}
             )

    assert {:ok,
            "@media (min-width: 500px) and (max-width: 900px) {\n" <>
              "  .#{@private_class}:focus-within {\n    gap: 2;\n  }\n}\n"} =
             StylesheetRenderer.render_state_rule(
               @private_class,
               @private_class,
               :focus_within,
               styles,
               %{min_width: 500, max_width: 900}
             )

    expected =
      "@media (min-width: 767px) and (max-width: 767px) {\n" <>
        "  .#{@private_class}:focus-within .#{target_class} {\n    gap: 2;\n  }\n}\n"

    assert {:ok, ^expected} =
             StylesheetRenderer.render_state_rule(
               @private_class,
               target_class,
               :focus_within,
               styles,
               %{min_width: 767, max_width: 767}
             )
  end

  test "canonicalizes zero thresholds for state-rule media queries" do
    assert {:ok,
            "@media (min-width: 0px) and (max-width: 0px) {\n" <>
              "  .#{@private_class}:hover {\n    gap: 2;\n  }\n}\n"} =
             StylesheetRenderer.render_state_rule(
               @private_class,
               @private_class,
               :hover,
               %{"gap" => StyleValue.literal(2)},
               %{min_width: 0.0, max_width: 0}
             )
  end

  test "rejects unsafe classes unsupported state conditions and declarations" do
    styles = %{"opacity" => StyleValue.literal(0.5)}

    assert {:error, owner_diagnostic} =
             StylesheetRenderer.render_state_rule(
               "unsafe .owner",
               @private_class,
               :hover,
               styles,
               nil
             )

    assert owner_diagnostic.code == "native_generator.styling.css_serialization_failed"

    assert {:error, target_diagnostic} =
             StylesheetRenderer.render_state_rule(
               @private_class,
               "unsafe .target",
               :hover,
               styles,
               nil
             )

    assert target_diagnostic.code == "native_generator.styling.css_serialization_failed"

    assert {:error, condition_diagnostic} =
             StylesheetRenderer.render_state_rule(
               @private_class,
               @private_class,
               "hover",
               styles,
               nil
             )

    assert condition_diagnostic.code == "native_generator.styling.css_serialization_failed"

    assert {:error, property_diagnostic} =
             StylesheetRenderer.render_state_rule(
               @private_class,
               @private_class,
               :hover,
               %{"bad property" => StyleValue.literal(1)},
               nil
             )

    assert property_diagnostic.code == "native_generator.styling.css_serialization_failed"

    assert {:error, value_diagnostic} =
             StylesheetRenderer.render_state_rule(
               @private_class,
               @private_class,
               :hover,
               %{"color" => StyleValue.literal("red; display: none")},
               nil
             )

    assert value_diagnostic.code == "native_generator.styling.css_serialization_failed"

    for viewport <- [
          %{min_width: nil, max_width: nil},
          %{min_width: 900, max_width: 500},
          %{min_width: -1, max_width: nil},
          %{"min_width" => 500, "max_width" => nil},
          %{min_width: 500, max_width: nil, source: "untrusted"}
        ] do
      assert {:error, viewport_diagnostic} =
               StylesheetRenderer.render_state_rule(
                 @private_class,
                 @private_class,
                 :hover,
                 styles,
                 viewport
               )

      assert viewport_diagnostic.code == "native_generator.styling.css_serialization_failed"
    end
  end

  test "renders broader responsive max-width overrides before narrower ones" do
    overrides = [
      %ResponsiveOverride{
        resolution_status: :resolved,
        max_width: 767,
        styles: %{"gap" => StyleValue.literal(3), "display" => StyleValue.keyword("grid")}
      },
      %ResponsiveOverride{
        resolution_status: :resolved,
        max_width: 991,
        styles: %{"gap" => StyleValue.literal(2)}
      }
    ]

    assert {:ok, css} = StylesheetRenderer.render(@private_class, %{}, overrides)

    expected =
      """
      @media (max-width: 991px) {
        .#{@private_class} {
          gap: 2;
        }
      }

      @media (max-width: 767px) {
        .#{@private_class} {
          display: grid;
          gap: 3;
        }
      }
      """
      |> String.trim_trailing()
      |> Kernel.<>("\n")

    assert css == expected
    assert String.match?(css, ~r/991px[\s\S]*767px/)

    assert {:ok, reversed_css} =
             StylesheetRenderer.render(@private_class, %{}, Enum.reverse(overrides))

    assert css == reversed_css
  end

  test "renders integer and float zero thresholds as canonical zero pixels" do
    integer_zero = %ResponsiveOverride{
      resolution_status: :resolved,
      max_width: 0,
      styles: %{"display" => StyleValue.keyword("grid")}
    }

    float_zero = %ResponsiveOverride{integer_zero | max_width: 0.0}
    negative_zero = %ResponsiveOverride{integer_zero | max_width: -0.0}

    assert {:ok, integer_css} = StylesheetRenderer.render(@private_class, %{}, [integer_zero])
    assert {:ok, float_css} = StylesheetRenderer.render(@private_class, %{}, [float_zero])

    assert {:ok, negative_zero_css} =
             StylesheetRenderer.render(@private_class, %{}, [negative_zero])

    assert integer_css == float_css
    assert integer_css == negative_zero_css
    assert integer_css =~ "@media (max-width: 0px)"

    negative = %ResponsiveOverride{integer_zero | max_width: -0.1}

    assert {:error, diagnostic} = StylesheetRenderer.render(@private_class, %{}, [negative])
    assert diagnostic.code == "native_generator.styling.responsive_cascade_authority_gap"

    negative_integer = %ResponsiveOverride{integer_zero | max_width: -1}

    assert {:error, negative_integer_diagnostic} =
             StylesheetRenderer.render(@private_class, %{}, [negative_integer])

    assert negative_integer_diagnostic.code ==
             "native_generator.styling.responsive_cascade_authority_gap"
  end

  test "renders inclusive min-only and bounded responsive media queries" do
    min_only = %ResponsiveOverride{
      resolution_status: :resolved,
      min_width: 767,
      styles: %{"display" => StyleValue.keyword("grid")}
    }

    assert {:ok, min_css} = StylesheetRenderer.render(@private_class, %{}, [min_only])

    assert min_css ==
             "@media (min-width: 767px) {\n  .#{@private_class} {\n    display: grid;\n  }\n}\n"

    bounded = %ResponsiveOverride{
      resolution_status: :resolved,
      min_width: 500,
      max_width: 900,
      styles: %{"gap" => StyleValue.literal(2)}
    }

    assert {:ok, range_css} = StylesheetRenderer.render(@private_class, %{}, [bounded])

    assert range_css ==
             "@media (min-width: 500px) and (max-width: 900px) {\n  .#{@private_class} {\n    gap: 2;\n  }\n}\n"
  end

  test "renders a bounded interval whose inclusive thresholds are equal" do
    exact_width = %ResponsiveOverride{
      resolution_status: :resolved,
      min_width: 767,
      max_width: 767,
      styles: %{"gap" => StyleValue.literal(2)}
    }

    assert {:ok, css} = StylesheetRenderer.render(@private_class, %{}, [exact_width])

    assert css ==
             "@media (min-width: 767px) and (max-width: 767px) {\n  .#{@private_class} {\n    gap: 2;\n  }\n}\n"
  end

  test "preserves finite fractional responsive bounds in the media query" do
    fractional_range = %ResponsiveOverride{
      resolution_status: :resolved,
      min_width: 500.5,
      max_width: 900.25,
      styles: %{"gap" => StyleValue.literal(2)}
    }

    assert {:ok, css} = StylesheetRenderer.render(@private_class, %{}, [fractional_range])

    assert css =~ "@media (min-width: 500.5px) and (max-width: 900.25px)"
  end

  test "renders zero min and range thresholds with canonical integer and float bytes" do
    min_zero = %ResponsiveOverride{
      resolution_status: :resolved,
      min_width: 0,
      styles: %{"gap" => StyleValue.literal(2)}
    }

    min_float_zero = %ResponsiveOverride{min_zero | min_width: 0.0}

    assert {:ok, min_css} = StylesheetRenderer.render(@private_class, %{}, [min_zero])
    assert {:ok, min_float_css} = StylesheetRenderer.render(@private_class, %{}, [min_float_zero])
    assert min_css == min_float_css
    assert min_css =~ "@media (min-width: 0px)"

    range_zero = %ResponsiveOverride{
      resolution_status: :resolved,
      min_width: 0,
      max_width: 767,
      styles: %{"gap" => StyleValue.literal(2)}
    }

    range_float_zero = %ResponsiveOverride{range_zero | min_width: 0.0, max_width: 767.0}

    assert {:ok, range_css} = StylesheetRenderer.render(@private_class, %{}, [range_zero])

    assert {:ok, range_float_css} =
             StylesheetRenderer.render(@private_class, %{}, [range_float_zero])

    assert range_css == range_float_css
    assert range_css =~ "@media (min-width: 0px) and (max-width: 767px)"
  end

  test "combines disjoint overrides at one width and rejects property conflicts" do
    first = %ResponsiveOverride{
      resolution_status: :resolved,
      max_width: 767,
      styles: %{"gap" => StyleValue.literal(2)}
    }

    second = %ResponsiveOverride{
      resolution_status: :resolved,
      max_width: 767,
      styles: %{"display" => StyleValue.keyword("grid")}
    }

    assert {:ok, css} = StylesheetRenderer.render(@private_class, %{}, [second, first])
    assert css =~ "    display: grid;\n    gap: 2;"

    conflict = %ResponsiveOverride{second | styles: %{"gap" => StyleValue.literal(3)}}

    assert {:error, diagnostic} =
             StylesheetRenderer.render(@private_class, %{}, [first, conflict])

    assert diagnostic.code == "native_generator.styling.responsive_cascade_authority_gap"
  end

  test "merges and deduplicates exact responsive intervals and rejects conflicts" do
    intervals = [
      %{min_width: nil, max_width: 767},
      %{min_width: 767, max_width: nil},
      %{min_width: 500, max_width: 900}
    ]

    for bounds <- intervals do
      first = %ResponsiveOverride{
        resolution_status: :resolved,
        min_width: bounds.min_width,
        max_width: bounds.max_width,
        styles: %{"gap" => StyleValue.literal(2)}
      }

      disjoint = %ResponsiveOverride{
        first
        | styles: %{"display" => StyleValue.keyword("grid")}
      }

      duplicate_value = %ResponsiveOverride{
        first
        | min_width: to_float_if_integer(bounds.min_width),
          max_width: to_float_if_integer(bounds.max_width)
      }

      assert {:ok, css} =
               StylesheetRenderer.render(@private_class, %{}, [duplicate_value, disjoint, first])

      assert length(String.split(css, "@media ")) == 2
      assert css =~ "display: grid;"
      assert css =~ "gap: 2;"

      conflict = %ResponsiveOverride{first | styles: %{"gap" => StyleValue.literal(3)}}

      assert_responsive_gap(StylesheetRenderer.render(@private_class, %{}, [first, conflict]))
    end
  end

  test "rejects different values on overlapping same-property min and range intervals" do
    overlap_pairs = [
      {
        %ResponsiveOverride{resolution_status: :resolved, min_width: 500},
        %ResponsiveOverride{resolution_status: :resolved, min_width: 767}
      },
      {
        %ResponsiveOverride{
          resolution_status: :resolved,
          min_width: 500,
          max_width: 900
        },
        %ResponsiveOverride{
          resolution_status: :resolved,
          min_width: 767,
          max_width: 1_000
        }
      },
      {
        %ResponsiveOverride{resolution_status: :resolved, max_width: 767},
        %ResponsiveOverride{resolution_status: :resolved, min_width: 500}
      },
      {
        %ResponsiveOverride{resolution_status: :resolved, max_width: 767},
        %ResponsiveOverride{
          resolution_status: :resolved,
          min_width: 500,
          max_width: 900
        }
      },
      {
        %ResponsiveOverride{resolution_status: :resolved, min_width: 500},
        %ResponsiveOverride{
          resolution_status: :resolved,
          min_width: 500,
          max_width: 900
        }
      }
    ]

    for {%ResponsiveOverride{} = first, %ResponsiveOverride{} = second} <- overlap_pairs do
      first = %ResponsiveOverride{first | styles: %{"gap" => StyleValue.literal(2)}}
      second = %ResponsiveOverride{second | styles: %{"gap" => StyleValue.literal(3)}}

      assert_responsive_gap(StylesheetRenderer.render(@private_class, %{}, [first, second]))
    end
  end

  test "allows overlapping max-only values and same-value or different-property overlaps" do
    max_broad = %ResponsiveOverride{
      resolution_status: :resolved,
      max_width: 991,
      styles: %{"gap" => StyleValue.literal(2)}
    }

    max_narrow = %ResponsiveOverride{
      resolution_status: :resolved,
      max_width: 767,
      styles: %{"gap" => StyleValue.literal(3)}
    }

    min_same_value = %ResponsiveOverride{
      resolution_status: :resolved,
      min_width: 767,
      styles: %{"gap" => StyleValue.literal(2)}
    }

    min_other_property = %ResponsiveOverride{
      resolution_status: :resolved,
      min_width: 500,
      styles: %{"display" => StyleValue.keyword("grid")}
    }

    assert {:ok, max_css} =
             StylesheetRenderer.render(@private_class, %{}, [max_narrow, max_broad])

    assert String.match?(max_css, ~r/max-width: 991px[\s\S]*max-width: 767px/)

    assert {:ok, same_value_css} =
             StylesheetRenderer.render(@private_class, %{}, [min_same_value, max_broad])

    assert same_value_css =~ "@media (min-width: 767px)"

    assert {:ok, different_property_css} =
             StylesheetRenderer.render(@private_class, %{}, [min_other_property, max_broad])

    assert different_property_css =~ "@media (min-width: 500px)"
    assert different_property_css =~ "display: grid;"
  end

  test "uses inclusive overlap at a shared max and min boundary" do
    max_767 = %ResponsiveOverride{
      resolution_status: :resolved,
      max_width: 767,
      styles: %{"gap" => StyleValue.literal(2)}
    }

    min_767 = %ResponsiveOverride{
      resolution_status: :resolved,
      min_width: 767,
      styles: %{"gap" => StyleValue.literal(3)}
    }

    assert_responsive_gap(StylesheetRenderer.render(@private_class, %{}, [max_767, min_767]))

    max_766 = %ResponsiveOverride{max_767 | max_width: 766}

    assert {:ok, css} = StylesheetRenderer.render(@private_class, %{}, [max_766, min_767])
    assert css =~ "@media (max-width: 766px)"
    assert css =~ "@media (min-width: 767px)"
  end

  test "serializes allowed mixed intervals in canonical order for list and map inputs" do
    overrides = [
      %ResponsiveOverride{
        resolution_status: :resolved,
        min_width: 767,
        styles: %{"gap" => StyleValue.literal(2)}
      },
      %ResponsiveOverride{
        resolution_status: :resolved,
        min_width: 500,
        max_width: 900,
        styles: %{"color" => StyleValue.keyword("red")}
      },
      %ResponsiveOverride{
        resolution_status: :resolved,
        max_width: 767,
        styles: %{"display" => StyleValue.keyword("grid")}
      },
      %ResponsiveOverride{
        resolution_status: :resolved,
        min_width: 500,
        styles: %{"opacity" => StyleValue.literal(0.5)}
      },
      %ResponsiveOverride{
        resolution_status: :resolved,
        max_width: 991,
        styles: %{"gap" => StyleValue.literal(2)}
      }
    ]

    assert {:ok, css} = StylesheetRenderer.render(@private_class, %{}, overrides)

    assert {:ok, reversed_css} =
             StylesheetRenderer.render(@private_class, %{}, Enum.reverse(overrides))

    map_overrides =
      Enum.reverse(overrides)
      |> Enum.with_index()
      |> Enum.map(fn {override, index} -> {index, override} end)
      |> Map.new()

    assert {:ok, map_css} = StylesheetRenderer.render(@private_class, %{}, map_overrides)

    assert css == reversed_css
    assert css == map_css

    queries = Regex.scan(~r/@media \([^\n]+/, css) |> List.flatten()

    assert queries == [
             "@media (max-width: 991px) {",
             "@media (max-width: 767px) {",
             "@media (min-width: 500px) {",
             "@media (min-width: 500px) and (max-width: 900px) {",
             "@media (min-width: 767px) {"
           ]
  end

  test "blocks unresolved or invalid responsive interval authority" do
    unresolved = %ResponsiveOverride{resolution_status: :unresolved, max_width: 767, styles: %{}}
    unknown_status = %ResponsiveOverride{resolution_status: :unknown, max_width: 767, styles: %{}}
    no_bounds = %ResponsiveOverride{resolution_status: :resolved, styles: %{}}
    negative_min = %ResponsiveOverride{resolution_status: :resolved, min_width: -1, styles: %{}}
    negative_max = %ResponsiveOverride{resolution_status: :resolved, max_width: -1, styles: %{}}

    reversed = %ResponsiveOverride{
      resolution_status: :resolved,
      min_width: 900,
      max_width: 500,
      styles: %{}
    }

    text_min = %ResponsiveOverride{resolution_status: :resolved, min_width: "500", styles: %{}}
    text_max = %ResponsiveOverride{resolution_status: :resolved, max_width: "767", styles: %{}}
    invalid_styles = %ResponsiveOverride{resolution_status: :resolved, max_width: 767, styles: []}

    for override <- [
          unresolved,
          unknown_status,
          no_bounds,
          negative_min,
          negative_max,
          reversed,
          text_min,
          text_max,
          invalid_styles,
          %{}
        ] do
      assert_responsive_gap(StylesheetRenderer.render(@private_class, %{}, [override]))
    end
  end

  test "blocks invalid selectors, declarations, and values without dropping them" do
    assert {:error, _} = StylesheetRenderer.render("safe .injected", %{})

    assert {:error, _} =
             StylesheetRenderer.render(@private_class, %{"bad property" => StyleValue.literal(1)})

    assert {:error, _} =
             StylesheetRenderer.render(@private_class, %{
               "display" => StyleValue.literal("red; color: blue")
             })
  end

  test "represents stylesheet and existing Elixir module artifact kinds" do
    assert %Artifact{kind: :stylesheet, path: "assets/css/example.css", content: ""} =
             %Artifact{kind: :stylesheet, path: "assets/css/example.css", content: ""}

    assert %Artifact{kind: :elixir_module} = %Artifact{}
  end

  defp assert_responsive_gap(result) do
    assert {:error, diagnostic} = result

    assert diagnostic.code ==
             "native_generator.styling.responsive_cascade_authority_gap"

    assert diagnostic.message == "Responsive interval authority is incomplete or conflicting"
  end

  defp to_float_if_integer(nil), do: nil
  defp to_float_if_integer(value) when is_integer(value), do: value * 1.0
end
