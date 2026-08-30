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
end
