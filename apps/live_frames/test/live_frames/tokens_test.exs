defmodule LiveFrames.TokensTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Tokens
  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet

  defp valid_token_set do
    %TokenSet{
      source_metadata: %{"source_version" => "4.0.1", "export_version" => nil},
      tokens: %{
        "color.primary" => %Token{
          path: "color.primary",
          category: :color,
          value: "#32a2c1",
          resolved_value: "#32a2c1",
          source_expression: "#32a2c1",
          resolution_status: :resolved,
          provenance: %{
            "source_keys" => ["color-primary"],
            "raw_value" => "#32a2c1",
            "adapter" => "automatic_css",
            "adapter_version" => "1.0.0",
            "transformation" => "direct"
          }
        },
        "button.primary.background" => %Token{
          path: "button.primary.background",
          category: :button,
          value: %{"type" => "reference", "path" => "color.primary"},
          resolved_value: "#32a2c1",
          source_expression: "var(--primary)",
          resolution_status: :resolved,
          references: ["color.primary"],
          provenance: %{"source_keys" => ["btn-primary-bg"]}
        }
      }
    }
  end

  test "owns an independent versioned TokenSet contract" do
    assert Tokens.current_token_set_version() == "1.0.0"
    assert TokenSet.new().token_set_version == "1.0.0"
    assert Tokens.validate(valid_token_set()) == :ok
  end

  test "rejects unsupported TokenSet versions" do
    assert {:error, diagnostics} =
             Tokens.validate(%{valid_token_set() | token_set_version: "2.0.0"})

    assert Enum.any?(diagnostics, &(&1.code == "tokens.version.unsupported"))
  end

  test "rejects invalid paths, categories, statuses, and provenance" do
    token = valid_token_set().tokens["color.primary"]

    invalid = %{
      valid_token_set()
      | tokens: %{
          "bad path" => %{
            token
            | path: "bad path",
              category: :unknown,
              resolution_status: :pending,
              provenance: %{"bad" => self()}
          }
        }
    }

    assert {:error, diagnostics} = Tokens.validate(invalid)
    codes = Enum.map(diagnostics, & &1.code)
    assert "tokens.path.invalid" in codes
    assert "tokens.category.invalid" in codes
    assert "tokens.status.invalid" in codes
    assert "tokens.provenance.invalid" in codes
  end

  test "reports a missing reference and a reference cycle" do
    token = valid_token_set().tokens["color.primary"]

    missing = %{
      token
      | path: "spacing.content_gap",
        value: %{"type" => "reference", "path" => "spacing.missing"},
        references: ["spacing.missing"]
    }

    missing_set = %{
      valid_token_set()
      | tokens: Map.put(valid_token_set().tokens, missing.path, missing)
    }

    assert {:error, diagnostics} = Tokens.validate(missing_set)
    assert Enum.any?(diagnostics, &(&1.code == "tokens.reference.missing"))

    a = %{
      token
      | path: "cycle.a",
        value: %{"type" => "reference", "path" => "cycle.b"},
        references: ["cycle.b"]
    }

    b = %{
      token
      | path: "cycle.b",
        value: %{"type" => "reference", "path" => "cycle.a"},
        references: ["cycle.a"]
    }

    cycle_set = %{valid_token_set() | tokens: %{"cycle.a" => a, "cycle.b" => b}}

    assert {:error, diagnostics} = Tokens.validate(cycle_set)
    assert Enum.any?(diagnostics, &(&1.code == "tokens.reference.cycle"))
  end

  test "strict validation reports only missing required paths" do
    assert {:error, diagnostics} =
             Tokens.validate(valid_token_set(),
               required_paths: ["color.primary", "spacing.content_gap"],
               strict: true
             )

    assert Enum.any?(diagnostics, &(&1.code == "tokens.required.missing"))

    assert Tokens.validate(valid_token_set(), required_paths: ["color.primary"], strict: true) ==
             :ok
  end

  test "reports malformed reference fields without crashing" do
    token = valid_token_set().tokens["color.primary"]
    malformed = %{token | resolution_status: "pending", references: :not_a_list}
    token_set = %{valid_token_set() | tokens: %{"color.primary" => malformed}}

    assert {:error, diagnostics} = Tokens.validate(token_set)
    codes = Enum.map(diagnostics, & &1.code)
    assert "tokens.status.invalid" in codes
    assert "tokens.reference.invalid" in codes
  end

  test "requires a reference value to declare its semantic edge" do
    token = valid_token_set().tokens["button.primary.background"]
    malformed = %{token | references: []}

    token_set = %{
      valid_token_set()
      | tokens: Map.put(valid_token_set().tokens, token.path, malformed)
    }

    assert {:error, diagnostics} = Tokens.validate(token_set)
    assert Enum.any?(diagnostics, &(&1.code == "tokens.reference.invalid"))
  end

  test "encoding is deterministic and contains no struct internals" do
    first = %{
      valid_token_set()
      | source_metadata: Map.new([{"z", %{"b" => 2, "a" => 1}}, {"a", "first"}])
    }

    second = %{
      valid_token_set()
      | source_metadata: Map.new([{"a", "first"}, {"z", %{"a" => 1, "b" => 2}}])
    }

    assert Tokens.encode!(first) == Tokens.encode!(second)

    decoded = first |> Tokens.encode!() |> Jason.decode!()
    assert decoded["token_set_version"] == "1.0.0"
    assert decoded["tokens"]["button.primary.background"]["value"]["type"] == "reference"
    assert decoded["tokens"]["button.primary.background"]["references"] == ["color.primary"]
    refute Tokens.encode!(first) =~ "__struct__"
  end
end
