defmodule LiveFrames.Styling.TokenBridgeTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Styling.TokenBridge
  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet

  @fixture Path.expand("../../../../../fixtures/automatic_css/acss_settings.json", __DIR__)
  @mapping Path.expand("../../../priv/token_maps/native_hero_v1.json", __DIR__)
  @shared_mapping Path.expand("../../../priv/token_maps/native_shared_v1.json", __DIR__)
  @committed_theme Path.expand("../../../assets/css/theme/lf_theme.css", __DIR__)

  defp hero_token_set do
    {:ok, token_set, _} =
      AutomaticCSS.from_file(@fixture,
        strict: true,
        profile: :hero_foundation,
        source_version: "4.0.1",
        source_version_status: "fixture_reference"
      )

    token_set
  end

  test "rejects mapping with duplicate token paths" do
    mapping =
      TokenBridge.load_mapping!(@mapping)
      |> put_in(["entries", Access.at(0), "token_set_path"], "color.primary")
      |> put_in(["entries", Access.at(1), "token_set_path"], "color.primary")

    assert {:error, {:duplicate_token_set_paths, ["color.primary"]}} =
             TokenBridge.generate(hero_token_set(), mapping)
  end

  test "rejects mapping with duplicate css variables" do
    mapping =
      TokenBridge.load_mapping!(@mapping)
      |> put_in(["entries", Access.at(1), "css_variable"], "--lf-color-background-ultra-dark")

    assert {:error, {:duplicate_css_variables, ["--lf-color-background-ultra-dark"]}} =
             TokenBridge.generate(hero_token_set(), mapping)
  end

  test "rejects unsafe css values containing semicolons" do
    token_set =
      hero_token_set()
      |> put_in(
        [
          Access.key!(:tokens),
          "color.background.ultra_dark",
          Access.key!(:resolved_value)
        ],
        "red; background: url(javascript:alert(1))"
      )

    assert {:error, {:unsafe_css_value, "--lf-color-background-ultra-dark", _}} =
             TokenBridge.generate(token_set, TokenBridge.load_mapping!(@mapping))
  end

  test "rejects unsafe external URL values without relying on semicolon rejection" do
    token_set =
      hero_token_set()
      |> put_in(
        [
          Access.key!(:tokens),
          "color.background.ultra_dark",
          Access.key!(:resolved_value)
        ],
        "url(javascript:alert(1))"
      )

    assert {:error, {:unsafe_css_value, "--lf-color-background-ultra-dark", _}} =
             TokenBridge.generate(token_set, TokenBridge.load_mapping!(@mapping))
  end

  test "serializes numeric token values as deterministic unitless CSS values" do
    token_set = %TokenSet{
      tokens: %{
        "numeric.integer" =>
          Token.new(path: "numeric.integer", resolution_status: :resolved, resolved_value: 1),
        "numeric.float" =>
          Token.new(path: "numeric.float", resolution_status: :resolved, resolved_value: 1.5),
        "numeric.empty_expression" =>
          Token.new(
            path: "numeric.empty_expression",
            resolution_status: :resolved,
            resolved_value: 2,
            metadata: %{"css_expression" => ""}
          )
      }
    }

    mapping =
      TokenBridge.load_mapping!(@mapping)
      |> Map.put("entries", [
        %{"token_set_path" => "numeric.integer", "css_variable" => "--lf-token-integer"},
        %{"token_set_path" => "numeric.float", "css_variable" => "--lf-token-float"},
        %{
          "token_set_path" => "numeric.empty_expression",
          "css_variable" => "--lf-token-empty-expression"
        }
      ])

    assert {:ok, css} = TokenBridge.generate(token_set, mapping)
    assert css =~ "--lf-token-integer: 1;"
    assert css =~ "--lf-token-float: 1.5;"
    assert css =~ "--lf-token-empty-expression: 2;"
  end

  test "rejects unsupported mapping schema version" do
    mapping = TokenBridge.load_mapping!(@mapping) |> Map.put("schema_version", "9.9.9")

    assert {:error, {:unsupported_mapping_schema, "9.9.9"}} =
             TokenBridge.generate(hero_token_set(), mapping)
  end

  test "rejects malformed mapping entries structurally" do
    mapping =
      TokenBridge.load_mapping!(@mapping)
      |> Map.put("entries", [%{"token_set_path" => "color.primary"}])

    assert {:error, {:invalid_css_variable, nil}} =
             TokenBridge.generate(hero_token_set(), mapping)
  end

  test "rejects invalid css variable names" do
    mapping =
      TokenBridge.load_mapping!(@mapping)
      |> Map.put("entries", [
        %{"token_set_path" => "color.primary", "css_variable" => "--not-valid"}
      ])

    assert {:error, {:invalid_css_variable, "--not-valid"}} =
             TokenBridge.generate(hero_token_set(), mapping)
  end

  test "rejects unsupported tailwind aliases" do
    mapping =
      TokenBridge.load_mapping!(@mapping)
      |> update_in(["entries", Access.at(0)], fn entry ->
        Map.put(entry, "tailwind_alias", "color-brand")
      end)

    assert {:error, {:unsupported_tailwind_alias, "color-brand"}} =
             TokenBridge.generate(hero_token_set(), mapping)
  end

  test "rejects unsupported responsive structured values without css_expression" do
    token =
      Token.new(
        path: "color.background.ultra_dark",
        resolution_status: :resolved,
        resolved_value: %{"type" => "responsive", "min" => "16px", "max" => "18px"}
      )

    token_set = %TokenSet{
      tokens: %{"color.background.ultra_dark" => token},
      source_metadata: %{},
      diagnostics: []
    }

    mapping =
      TokenBridge.load_mapping!(@mapping)
      |> Map.put("entries", [
        %{
          "token_set_path" => "color.background.ultra_dark",
          "css_variable" => "--lf-color-background-ultra-dark"
        }
      ])

    assert {:error, {:non_serializable_resolved_value, "color.background.ultra_dark"}} =
             TokenBridge.generate(token_set, mapping)
  end

  test "fails when mapped token is missing" do
    token_set = %TokenSet{tokens: %{}, source_metadata: %{}, diagnostics: []}
    mapping = TokenBridge.load_mapping!(@mapping)

    assert {:error, {:missing_token, "color.background.ultra_dark"}} =
             TokenBridge.generate(token_set, mapping)
  end

  test "fails when mapped token is unresolved" do
    token =
      Token.new(
        path: "color.background.ultra_dark",
        resolution_status: :unresolved,
        resolved_value: nil
      )

    token_set = %TokenSet{
      tokens: %{"color.background.ultra_dark" => token},
      source_metadata: %{},
      diagnostics: []
    }

    mapping =
      TokenBridge.load_mapping!(@mapping)
      |> Map.put("entries", [
        %{
          "token_set_path" => "color.background.ultra_dark",
          "css_variable" => "--lf-color-background-ultra-dark"
        }
      ])

    assert {:error, {:unresolved_token, "color.background.ultra_dark", :unresolved}} =
             TokenBridge.generate(token_set, mapping)
  end

  test "generates byte-identical output regardless of mapping entry order" do
    mapping = TokenBridge.load_mapping!(@mapping)
    reversed = Map.put(mapping, "entries", Enum.reverse(mapping["entries"]))
    token_set = hero_token_set()

    assert {:ok, first} = TokenBridge.generate(token_set, mapping)
    assert {:ok, second} = TokenBridge.generate(token_set, reversed)
    assert first == second
  end

  test "generates deterministic lf_theme.css without acss names in output" do
    mapping = TokenBridge.load_mapping!(@mapping)
    token_set = hero_token_set()

    assert {:ok, first} = TokenBridge.generate(token_set, mapping)
    assert {:ok, second} = TokenBridge.generate(token_set, mapping)
    assert first == second
    refute first =~ "acss"
    refute first =~ "automatic"
    refute first =~ "color.background"
    assert first =~ ":root {"
    assert String.ends_with?(first, "\n")
  end

  test "committed lf_theme.css matches regenerated output" do
    token_set = hero_token_set()
    mappings = [TokenBridge.load_mapping!(@shared_mapping), TokenBridge.load_mapping!(@mapping)]

    assert {:ok, generated} = TokenBridge.generate(token_set, mappings)
    assert File.read!(@committed_theme) == generated
  end

  test "layered shared then hero mappings combine deterministically" do
    token_set = hero_token_set()
    shared = TokenBridge.load_mapping!(@shared_mapping)
    hero = TokenBridge.load_mapping!(@mapping)

    assert {:ok, layered} = TokenBridge.generate(token_set, [shared, hero])
    assert {:ok, repeated} = TokenBridge.generate(token_set, [shared, hero])
    assert layered == repeated

    assert layered =~ "--lf-typography-body-size-small:"
    assert layered =~ "--lf-radius-base:"
    assert layered =~ "--lf-space-grid-gap:"
    refute layered =~ "--text-s:"
    refute layered =~ "--radius:"
    refute layered =~ "--grid-gap:"
  end

  test "allows the same token_set_path across layers when css variables differ" do
    token_set = hero_token_set()

    first_layer = %{
      "schema_version" => "1.0.0",
      "mapping_version" => "synthetic_layer_a",
      "entries" => [
        %{"token_set_path" => "radius.base", "css_variable" => "--lf-radius-shared-alias"}
      ]
    }

    second_layer = %{
      "schema_version" => "1.0.0",
      "mapping_version" => "synthetic_layer_b",
      "entries" => [
        %{"token_set_path" => "radius.base", "css_variable" => "--lf-radius-hero-alias"}
      ]
    }

    assert {:ok, css} = TokenBridge.generate(token_set, [first_layer, second_layer])
    assert css =~ "--lf-radius-shared-alias:"
    assert css =~ "--lf-radius-hero-alias:"
  end

  test "rejects duplicate css variables across mapping layers" do
    token_set = hero_token_set()
    shared = TokenBridge.load_mapping!(@shared_mapping)

    hero =
      TokenBridge.load_mapping!(@mapping)
      |> update_in(["entries", Access.at(0), "css_variable"], fn _ ->
        "--lf-typography-body-size-small"
      end)

    assert {:error, {:duplicate_css_variables, ["--lf-typography-body-size-small"]}} =
             TokenBridge.generate(token_set, [shared, hero])
  end

  test "single-mapping TokenBridge API remains unchanged" do
    mapping = TokenBridge.load_mapping!(@mapping)
    token_set = hero_token_set()

    assert {:ok, css} = TokenBridge.generate(token_set, mapping)
    refute css =~ "--lf-typography-body-size-small:"
  end

  test "looks up shared package CSS variables by exact semantic token path" do
    assert {:ok, "--lf-typography-body-size-small"} =
             TokenBridge.package_css_variable("typography.body.scale.small")

    assert {:ok, "--lf-radius-base"} = TokenBridge.package_css_variable("radius.base")
    assert {:ok, "--lf-space-grid-gap"} = TokenBridge.package_css_variable("spacing.grid_gap")
  end

  test "looks up primary action CSS variables from package metadata" do
    assert {:ok, "--lf-action-primary-background"} =
             TokenBridge.package_css_variable("button.primary.background")
  end

  test "fails explicitly for unknown and composed token paths" do
    assert {:error, {:unknown_token_path, "unknown.path"}} =
             TokenBridge.package_css_variable("unknown.path")

    assert {:error, {:unknown_token_path, "spacing.gutter.min"}} =
             TokenBridge.package_css_variable("spacing.gutter.min")
  end

  test "rejects duplicate direct token paths in package mapping metadata" do
    mappings = [
      %{
        "schema_version" => "1.0.0",
        "mapping_version" => "layer_a",
        "entries" => [%{"token_set_path" => "radius.base", "css_variable" => "--lf-radius-a"}]
      },
      %{
        "schema_version" => "1.0.0",
        "mapping_version" => "layer_b",
        "entries" => [%{"token_set_path" => "radius.base", "css_variable" => "--lf-radius-b"}]
      }
    ]

    assert {:error, {:duplicate_token_set_paths, ["radius.base"]}} =
             LiveFrames.Styling.TokenBridge.PackageMappingIndex.build(mappings)
  end

  test "rejects duplicate CSS variable ownership across package layers" do
    mappings = [
      %{
        "schema_version" => "1.0.0",
        "mapping_version" => "layer_a",
        "entries" => [%{"token_set_path" => "radius.base", "css_variable" => "--lf-radius-base"}]
      },
      %{
        "schema_version" => "1.0.0",
        "mapping_version" => "layer_b",
        "entries" => [
          %{"token_set_path" => "radius.other", "css_variable" => "--lf-radius-base"}
        ]
      }
    ]

    assert {:error, {:duplicate_css_variables, ["--lf-radius-base"]}} =
             LiveFrames.Styling.TokenBridge.PackageMappingIndex.build(mappings)
  end

  test "rejects noncanonical semantic paths in package mapping metadata" do
    mappings = [
      %{
        "schema_version" => "1.0.0",
        "mapping_version" => "invalid_path",
        "entries" => [%{"token_set_path" => "../bad path", "css_variable" => "--lf-radius-base"}]
      }
    ]

    assert {:error, {:invalid_token_set_path, "../bad path"}} =
             LiveFrames.Styling.TokenBridge.PackageMappingIndex.build(mappings)
  end

  test "rejects mappings that combine compose and direct token paths" do
    mappings = [
      %{
        "schema_version" => "1.0.0",
        "mapping_version" => "ambiguous_entry",
        "entries" => [
          %{
            "compose" => %{
              "type" => "fluid_px_pair",
              "min" => "spacing.gutter.min",
              "max" => "spacing.gutter.max",
              "viewport_min" => "layout.viewport.min",
              "viewport_max" => "layout.viewport.max"
            },
            "token_set_path" => "spacing.gutter.min",
            "css_variable" => "--lf-space-gutter"
          }
        ]
      }
    ]

    assert {:error, {:ambiguous_mapping_entry, "spacing.gutter.min"}} =
             LiveFrames.Styling.TokenBridge.PackageMappingIndex.build(mappings)
  end

  test "rejects noncanonical paths in package mapping compositions" do
    mappings = [
      %{
        "schema_version" => "1.0.0",
        "mapping_version" => "invalid_compose_path",
        "entries" => [
          %{
            "compose" => %{
              "type" => "fluid_px_pair",
              "min" => "../bad path",
              "max" => "spacing.gutter.max",
              "viewport_min" => "layout.viewport.min",
              "viewport_max" => "layout.viewport.max"
            },
            "css_variable" => "--lf-space-gutter"
          }
        ]
      }
    ]

    assert {:error, {:invalid_mapping_entry, _entry}} =
             LiveFrames.Styling.TokenBridge.PackageMappingIndex.build(mappings)
  end
end
