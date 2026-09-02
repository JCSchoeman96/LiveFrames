defmodule LiveFrames.Fidelity.CSSDeclarationTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Fidelity.CSSDeclaration

  test "moves a safe declaration through accepted and serialized states" do
    assert {:ok, declaration} =
             CSSDeclaration.normalize(
               %{property: "color", path: "color.text", value: "red", selector: "&:hover"},
               :source_resolver
             )

    assert declaration.state == :accepted
    assert declaration.selector == :hover

    assert {:ok, serialized, "  color: red;"} = CSSDeclaration.serialize(declaration)
    assert serialized.state == :serialized
  end

  test "moves an unsafe declaration to the rejected terminal state" do
    assert {:rejected, declaration, :invalid_css_property} =
             CSSDeclaration.normalize(
               %{property: "color; background:red", value: "red", selector: nil},
               :ir
             )

    assert declaration.state == :rejected
    assert {:error, :not_accepted} = CSSDeclaration.serialize(declaration)
  end

  test "keeps an unresolved value distinct from a rejected declaration" do
    assert {:unresolved, declaration} =
             CSSDeclaration.normalize(
               %{property: "color", path: "missing.color", value: nil, selector: nil},
               :source_resolver
             )

    assert declaration.state == :unresolved
    assert {:error, :not_accepted} = CSSDeclaration.serialize(declaration)
  end

  test "accepts current normal and custom property syntax" do
    for property <- [
          "background-color",
          "color",
          "border-color",
          "border-width",
          "border-style",
          "border-radius",
          "padding-inline",
          "padding-block",
          "min-width",
          "font-size",
          "font-weight",
          "line-height",
          "outline-color",
          "object-fit",
          "object-position",
          "--lf-context-heading-color"
        ] do
      assert {:ok, %{property: ^property, state: :accepted}} =
               CSSDeclaration.normalize(%{property: property, value: "safe", selector: nil}, :ir)
    end
  end

  test "rejects empty, non-binary, and structural property inputs" do
    for property <- ["", 123, "color; background:red", "color: red", "*", ":root"] do
      assert {:rejected, _declaration, :invalid_css_property} =
               CSSDeclaration.normalize(%{property: property, value: "red", selector: nil}, :ir)
    end
  end

  test "rejects escaped external and javascript URL schemes" do
    for value <- [
          "url(\\68ttps://attacker.example/x)",
          "url(\\6aavascript:alert(1))",
          "url(\"https://attacker.example/x\")",
          "url(\"javascript:alert(1)\")"
        ] do
      assert {:rejected, _declaration, :unsafe_css_value} =
               CSSDeclaration.normalize(%{property: "background-image", value: value}, :ir)
    end
  end

  test "accepts only the supported selector representations" do
    assert {:ok, %{selector: :hover}} =
             CSSDeclaration.normalize(
               %{property: "color", value: "red", selector: "&:hover"},
               :ir
             )

    assert {:ok, %{selector: :focus_visible}} =
             CSSDeclaration.normalize(
               %{property: "color", value: "red", selector: "&:focus-visible"},
               :ir
             )

    assert {:rejected, _declaration, :unsupported_selector} =
             CSSDeclaration.normalize(%{property: "color", value: "red", selector: "body"}, :ir)
  end

  test "rejects the custom-css sentinel from normal declarations" do
    assert {:rejected, _declaration, :custom_css_forbidden} =
             CSSDeclaration.normalize(
               %{property: "custom-css", value: "body { color: red; }", selector: nil},
               :source_resolver
             )
  end

  test "serializer does not trust a forged accepted declaration" do
    declaration = %CSSDeclaration{
      property: "color; body { background:red",
      value: "red",
      selector: nil,
      state: :accepted
    }

    assert {:error, :not_accepted} = CSSDeclaration.serialize(declaration)
  end
end
