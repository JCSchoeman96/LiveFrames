defmodule LiveFrames.Tokens.CSSValueTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Tokens
  alias LiveFrames.Tokens.CSSValue
  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet

  defp token(attrs) do
    struct(
      Token,
      [path: "color.primary", category: :color, resolution_status: :resolved] ++ attrs
    )
  end

  defp serialized(token) do
    Tokens.to_map(%TokenSet{tokens: %{token.path => token}})["tokens"][token.path]
  end

  test "returns the strongest supported CSS candidate for structs and serialized token maps" do
    cases = [
      {token(resolved_value: "red", metadata: %{"css_expression" => "var(--brand)"}),
       "var(--brand)"},
      {token(resolved_value: "red", metadata: %{css_expression: "var(--brand)"}), "var(--brand)"},
      {token(resolved_value: "red"), "red"},
      {token(resolved_value: 0), "0"},
      {token(resolved_value: 1.5), "1.5"},
      {token(resolved_value: 7, metadata: %{"css_expression" => ""}), "7"},
      {token(resolved_value: %{"type" => "derived"}, source_expression: "--legacy-value"),
       "var(--legacy-value)"},
      {token(resolved_value: %{type: "derived"}, source_expression: "--legacy-value"),
       "var(--legacy-value)"}
    ]

    for {value, expected} <- cases do
      assert CSSValue.candidate(value) == {:ok, expected}
      assert CSSValue.candidate(serialized(value)) == {:ok, expected}
    end
  end

  test "returns candidates without applying CSS safety policy" do
    unsafe = token(resolved_value: "red; } body { color: red")

    assert CSSValue.candidate(unsafe) == {:ok, "red; } body { color: red"}
    assert CSSValue.candidate(serialized(unsafe)) == {:ok, "red; } body { color: red"}
  end

  test "reports unresolved, missing, and non-serializable token values" do
    rejected = [
      {token(resolution_status: :unresolved, resolved_value: nil), {:error, :unresolved}},
      {token(resolved_value: nil), {:error, :resolved_value_missing}},
      {
        token(resolved_value: nil, metadata: %{"css_expression" => "var(--brand)"}),
        {:error, :resolved_value_missing}
      },
      {
        token(resolved_value: %{"type" => "responsive", "min" => "16px", "max" => "18px"}),
        {:error, :non_serializable}
      },
      {token(resolved_value: %{"unknown" => "structured value"}), {:error, :non_serializable}},
      {token(resolved_value: ""), {:error, :non_serializable}}
    ]

    for {value, expected} <- rejected do
      assert CSSValue.candidate(value) == expected
      assert CSSValue.candidate(serialized(value)) == expected
    end
  end
end
