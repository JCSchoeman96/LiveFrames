defmodule LiveFrames.NativeGenerator.StyleValueCSSTest do
  use ExUnit.Case, async: true

  alias LiveFrames.IR.StyleValue
  alias LiveFrames.NativeGenerator.StyleValueCSS
  alias LiveFrames.Styling.TokenBridge.PackageMappingIndex

  test "serializes normalized literal and keyword values" do
    assert {:ok, "red"} = StyleValueCSS.serialize(StyleValue.literal("red"))
    assert {:ok, "12"} = StyleValueCSS.serialize(StyleValue.literal(12))
    assert {:ok, "1.25"} = StyleValueCSS.serialize(StyleValue.literal(1.25))
    assert {:ok, "1.0e20"} = StyleValueCSS.serialize(StyleValue.literal(1.0e20))
    assert {:ok, "none"} = StyleValueCSS.serialize(StyleValue.keyword("none"))
  end

  test "resolves only package token mappings" do
    assert {:ok, "var(--lf-space-grid-gap)"} =
             StyleValueCSS.serialize(StyleValue.token_ref("spacing.grid_gap"))

    assert {:error, {:token_mapping_blocked, {:unknown_token_path, "unknown.path"}}} =
             StyleValueCSS.serialize(StyleValue.token_ref("unknown.path"))

    mappings = [
      %{
        "schema_version" => "1.0.0",
        "mapping_version" => "test-one",
        "entries" => [%{"token_set_path" => "spacing.grid_gap", "css_variable" => "--lf-one"}]
      },
      %{
        "schema_version" => "1.0.0",
        "mapping_version" => "test-two",
        "entries" => [%{"token_set_path" => "spacing.grid_gap", "css_variable" => "--lf-two"}]
      }
    ]

    assert {:ok, index} = PackageMappingIndex.build(mappings)

    assert {:error, {:ambiguous_token_mapping, "spacing.grid_gap", ["--lf-one", "--lf-two"]}} =
             PackageMappingIndex.lookup(index, "spacing.grid_gap")
  end

  test "serializes only the exact structured token multiply" do
    calculation = %{
      "operation" => "multiply",
      "operands" => [
        %{"kind" => "token_ref", "path" => "spacing.grid_gap"},
        %{"kind" => "literal", "value" => 2}
      ]
    }

    assert {:ok, "calc(var(--lf-space-grid-gap) * 2)"} =
             StyleValueCSS.serialize(StyleValue.calculation(calculation))

    assert {:error, :unsupported_calculation} =
             StyleValueCSS.serialize(StyleValue.calculation("calc(1 + 2)"))

    assert {:error, :unsupported_calculation} =
             StyleValueCSS.serialize(
               StyleValue.calculation(%{"operation" => "add", "operands" => []})
             )

    assert {:error, :unsupported_calculation} =
             StyleValueCSS.serialize(
               StyleValue.calculation(%{
                 "operation" => "multiply",
                 "operands" => [
                   %{"kind" => "token_ref", "path" => "spacing.grid_gap"},
                   %{"kind" => "literal", "value" => 2},
                   %{"kind" => "literal", "value" => 3}
                 ]
               })
             )

    assert {:error, :unsupported_calculation} =
             StyleValueCSS.serialize(
               StyleValue.calculation(%{
                 "operation" => "multiply",
                 "operands" => [%{"kind" => "token_ref", "path" => "spacing.grid_gap"}, 2]
               })
             )
  end

  test "blocks complex unresolved and nested responsive values" do
    assert {:error, :unsupported_style_value} =
             StyleValueCSS.serialize(StyleValue.complex_css(%{"color" => "red"}))

    assert {:error, :unsupported_style_value} =
             StyleValueCSS.serialize(StyleValue.unresolved("red"))

    assert {:error, :unsupported_style_value} =
             StyleValueCSS.serialize(StyleValue.responsive(%{}))
  end

  test "ignores source fields and serializes finite floats deterministically" do
    first =
      StyleValue.literal(0.000001,
        source_expression: "source one",
        source_trace: %{source_name: "first"}
      )

    second =
      StyleValue.literal(0.000001,
        source_expression: "source two",
        source_trace: %{source_name: "second"}
      )

    assert {:ok, css_value} = StyleValueCSS.serialize(first)
    assert {:ok, css_value} == StyleValueCSS.serialize(second)
  end

  test "rejects unsafe values and non-finite literals" do
    assert {:error, :unsafe_css_value} =
             StyleValueCSS.serialize(StyleValue.literal("red;display:none"))

    assert {:error, :unsafe_css_value} =
             StyleValueCSS.serialize(StyleValue.literal("url(javascript:alert(1))"))

    assert {:error, :unsupported_style_value} =
             StyleValueCSS.serialize(StyleValue.literal(:not_a_css_value))
  end
end
