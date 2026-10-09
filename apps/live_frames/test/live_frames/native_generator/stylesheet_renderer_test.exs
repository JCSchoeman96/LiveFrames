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
    assert String.starts_with?(css, "@media (max-width: 991px) {")
    assert String.match?(css, ~r/991px[\s\S]*767px/)
    assert css =~ "    display: grid;\n    gap: 3;"

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

  test "blocks unresolved or unsupported responsive width authority" do
    unresolved = %ResponsiveOverride{resolution_status: :unresolved, max_width: 767, styles: %{}}
    no_width = %ResponsiveOverride{resolution_status: :resolved, styles: %{}}
    min_only = %ResponsiveOverride{resolution_status: :resolved, min_width: 500, styles: %{}}

    bounded = %ResponsiveOverride{
      resolution_status: :resolved,
      min_width: 500,
      max_width: 900,
      styles: %{}
    }

    text_width = %ResponsiveOverride{
      resolution_status: :resolved,
      max_width: "mobile",
      styles: %{}
    }

    for override <- [unresolved, no_width, min_only, bounded, text_width] do
      assert {:error, diagnostic} =
               StylesheetRenderer.render(@private_class, %{}, [override])

      assert diagnostic.code == "native_generator.styling.responsive_cascade_authority_gap"
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
end
