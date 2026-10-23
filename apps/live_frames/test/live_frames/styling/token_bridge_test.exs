defmodule LiveFrames.Styling.TokenBridgeTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Styling.TokenBridge
  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet

  @fixture Path.expand("../../../../../fixtures/automatic_css/acss_settings.json", __DIR__)
  @mapping Path.expand("../../../priv/token_maps/native_hero_v1.json", __DIR__)
  @shared_mapping Path.expand("../../../priv/token_maps/native_shared_v3.json", __DIR__)
  @previous_shared_mapping Path.expand("../../../priv/token_maps/native_shared_v2.json", __DIR__)
  @legacy_shared_mapping Path.expand("../../../priv/token_maps/native_shared_v1.json", __DIR__)
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

  test "rejects a repeated token path with the same css variable across package layers" do
    mappings = [
      %{
        "schema_version" => "1.0.0",
        "mapping_version" => "layer_a",
        "entries" => [%{"token_set_path" => "radius.base", "css_variable" => "--lf-radius-base"}]
      },
      %{
        "schema_version" => "1.0.0",
        "mapping_version" => "layer_b",
        "entries" => [%{"token_set_path" => "radius.base", "css_variable" => "--lf-radius-base"}]
      }
    ]

    assert {:error, {:duplicate_css_variables, ["--lf-radius-base"]}} =
             LiveFrames.Styling.TokenBridge.PackageMappingIndex.build(mappings)
  end

  test "package mapping lookup returns unknown when a path has no candidates" do
    assert {:error, {:unknown_token_path, "radius.missing"}} =
             LiveFrames.Styling.TokenBridge.PackageMappingIndex.lookup(%{}, "radius.missing")
  end

  test "package mapping lookup returns the single candidate" do
    assert {:ok, "--lf-radius-base"} =
             LiveFrames.Styling.TokenBridge.PackageMappingIndex.lookup(
               %{"radius.base" => ["--lf-radius-base"]},
               "radius.base"
             )
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
    assert {:ok, "--lf-space-scale-xs"} = TokenBridge.package_css_variable("spacing.scale.xs")

    assert {:ok, "--lf-typography-heading-size-h2"} =
             TokenBridge.package_css_variable("typography.heading.scale.h2")
  end

  test "native_shared_v2 extends immutable v1 with only the xs scale mapping" do
    v1 = TokenBridge.load_mapping!(@legacy_shared_mapping)
    v2 = TokenBridge.load_mapping!(@previous_shared_mapping)

    assert v2["mapping_version"] == "native_shared_v2"
    assert Enum.all?(v1["entries"], &(&1 in v2["entries"]))

    assert v2["entries"] -- v1["entries"] == [
             %{
               "token_set_path" => "spacing.scale.xs",
               "css_variable" => "--lf-space-scale-xs"
             }
           ]

    assert {:ok, v1_index} =
             LiveFrames.Styling.TokenBridge.PackageMappingIndex.build([v1])

    assert {:error, {:unknown_token_path, "spacing.scale.xs"}} =
             LiveFrames.Styling.TokenBridge.PackageMappingIndex.lookup(
               v1_index,
               "spacing.scale.xs"
             )

    assert {:ok, _v2_index} =
             LiveFrames.Styling.TokenBridge.PackageMappingIndex.build([v2])
  end

  test "native_shared_v3 extends immutable v2 with only the h2 heading scale mapping" do
    v2 = TokenBridge.load_mapping!(@previous_shared_mapping)
    v3 = TokenBridge.load_mapping!(@shared_mapping)

    assert v3["mapping_version"] == "native_shared_v3"
    assert Enum.all?(v2["entries"], &(&1 in v3["entries"]))

    assert v3["entries"] -- v2["entries"] == [
             %{
               "token_set_path" => "typography.heading.scale.h2",
               "css_variable" => "--lf-typography-heading-size-h2"
             }
           ]

    assert {:ok, v2_index} =
             LiveFrames.Styling.TokenBridge.PackageMappingIndex.build([v2])

    assert {:error, {:unknown_token_path, "typography.heading.scale.h2"}} =
             LiveFrames.Styling.TokenBridge.PackageMappingIndex.lookup(
               v2_index,
               "typography.heading.scale.h2"
             )

    assert {:ok, _v3_index} =
             LiveFrames.Styling.TokenBridge.PackageMappingIndex.build([v3])
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

  test "allows direct token paths to repeat across package layers" do
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

    assert {:ok, index} = LiveFrames.Styling.TokenBridge.PackageMappingIndex.build(mappings)

    assert index == %{
             "radius.base" => ["--lf-radius-a", "--lf-radius-b"]
           }
  end

  test "reports ambiguous package lookup candidates in sorted order" do
    mappings = [
      %{
        "schema_version" => "1.0.0",
        "mapping_version" => "layer_b",
        "entries" => [%{"token_set_path" => "radius.base", "css_variable" => "--lf-radius-z"}]
      },
      %{
        "schema_version" => "1.0.0",
        "mapping_version" => "layer_a",
        "entries" => [%{"token_set_path" => "radius.base", "css_variable" => "--lf-radius-a"}]
      }
    ]

    assert {:ok, index} = LiveFrames.Styling.TokenBridge.PackageMappingIndex.build(mappings)

    assert {:error, {:ambiguous_token_mapping, "radius.base", ["--lf-radius-a", "--lf-radius-z"]}} =
             LiveFrames.Styling.TokenBridge.PackageMappingIndex.lookup(index, "radius.base")

    assert {:ok, reversed_index} =
             LiveFrames.Styling.TokenBridge.PackageMappingIndex.build(Enum.reverse(mappings))

    assert LiveFrames.Styling.TokenBridge.PackageMappingIndex.lookup(
             reversed_index,
             "radius.base"
           ) ==
             LiveFrames.Styling.TokenBridge.PackageMappingIndex.lookup(index, "radius.base")
  end

  test "rejects duplicate direct token paths within one package layer" do
    mappings = [
      %{
        "schema_version" => "1.0.0",
        "mapping_version" => "one_layer",
        "entries" => [
          %{"token_set_path" => "radius.base", "css_variable" => "--lf-radius-a"},
          %{"token_set_path" => "radius.base", "css_variable" => "--lf-radius-b"}
        ]
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

  describe "progressive fluid_output" do
    alias LiveFrames.Tokens.CSSValue

    @domain_path "layout.fluid.viewport.default"
    @underscore_domain_path "layout.fluid.viewport_default"
    @value_path "spacing.fluid.gap"
    @second_value_path "typography.fluid.body"
    @scale_path "typography.scale.primary"
    @second_scale_path "spacing.scale.primary"
    @step_path "typography.heading.h1"
    @second_step_path "typography.heading.h2"
    @fallback_progress "clamp(0, tan(atan2(calc(100vw - 500px), calc(1000px - 500px))), 1)"
    @domain_progress_var "--lf-fluid-domain-layout-fluid-viewport-default-progress"
    @underscore_domain_progress_var "--lf-fluid-domain-layout-fluid-viewport_default-progress"
    @progress_supports_condition "(opacity: progress(1px, 0px, 1px))"
    @supports_query "@supports #{@progress_supports_condition}"
    @token_bridge_source Path.expand("../../../lib/live_frames/styling/token_bridge.ex", __DIR__)

    defp progressive_mapping(entries) do
      %{
        "schema_version" => "1.0.0",
        "mapping_version" => "progressive_fixture",
        "entries" => entries
      }
    end

    defp progressive_token_set(extra_tokens \\ %{}) do
      domain = %{
        "type" => "fluid_domain",
        "format_version" => "1.0.0",
        "input" => "viewport_width",
        "start" => %{"value" => 500, "unit" => "px"},
        "end" => %{"value" => 1000, "unit" => "px"},
        "clamp_policy" => "bounded"
      }

      value = %{
        "type" => "fluid_value",
        "format_version" => "1.0.0",
        "domain_ref" => @domain_path,
        "start_value" => %{"value" => 1, "unit" => "rem"},
        "end_value" => %{"value" => 1.125, "unit" => "rem"},
        "interpolation" => "linear"
      }

      scale = %{
        "type" => "fluid_scale",
        "format_version" => "1.0.0",
        "domain_ref" => @domain_path,
        "base_start" => %{"value" => 1, "unit" => "rem"},
        "base_end" => %{"value" => 1.125, "unit" => "rem"},
        "ratio_start" => 1.2,
        "ratio_end" => 1.414
      }

      step = %{
        "type" => "fluid_scale_step",
        "format_version" => "1.0.0",
        "scale_ref" => @scale_path,
        "power" => 4
      }

      second_value =
        Map.put(value, "start_value", %{"value" => 0.875, "unit" => "rem"})

      second_step = Map.put(step, "power", 2)

      second_scale = %{
        "type" => "fluid_scale",
        "format_version" => "1.0.0",
        "domain_ref" => @domain_path,
        "base_start" => %{"value" => 0.5, "unit" => "rem"},
        "base_end" => %{"value" => 1, "unit" => "rem"},
        "ratio_start" => 1.1,
        "ratio_end" => 1.25
      }

      underscore_domain = Map.put(domain, "start", %{"value" => 400, "unit" => "px"})

      base = %{
        @domain_path =>
          Token.new(path: @domain_path, resolution_status: :resolved, resolved_value: domain),
        @value_path =>
          Token.new(path: @value_path, resolution_status: :resolved, resolved_value: value),
        @second_value_path =>
          Token.new(
            path: @second_value_path,
            resolution_status: :resolved,
            resolved_value: second_value
          ),
        @scale_path =>
          Token.new(path: @scale_path, resolution_status: :resolved, resolved_value: scale),
        @second_scale_path =>
          Token.new(
            path: @second_scale_path,
            resolution_status: :resolved,
            resolved_value: second_scale
          ),
        @step_path =>
          Token.new(path: @step_path, resolution_status: :resolved, resolved_value: step),
        @second_step_path =>
          Token.new(
            path: @second_step_path,
            resolution_status: :resolved,
            resolved_value: second_step
          ),
        @underscore_domain_path =>
          Token.new(
            path: @underscore_domain_path,
            resolution_status: :resolved,
            resolved_value: underscore_domain
          ),
        "color.primary" =>
          Token.new(
            path: "color.primary",
            resolution_status: :resolved,
            resolved_value: "#336699"
          )
      }

      %TokenSet{tokens: Map.merge(base, extra_tokens), source_metadata: %{}, diagnostics: []}
    end

    defp supports_block(css) do
      case :binary.split(css, @supports_query) do
        [_, rest] -> @supports_query <> rest
        _ -> ""
      end
    end

    defp domain_progress_declarations(css, domain_progress_var) do
      length(:binary.matches(css, domain_progress_var <> ":"))
    end

    defp count_declarations(css, variable_prefix) do
      Regex.scan(~r/^\s*(#{Regex.escape(variable_prefix)}[^:]*):/m, css) |> length()
    end

    defp root_body_lines(root_block) do
      root_block
      |> String.split("\n}\n", parts: 2)
      |> hd()
      |> String.split("\n", trim: true)
    end

    test "legacy generate/2 bytes match explicit fluid_output: :legacy" do
      token_set = hero_token_set()
      mapping = TokenBridge.load_mapping!(@mapping)

      assert {:ok, legacy} = TokenBridge.generate(token_set, mapping)
      assert {:ok, explicit} = TokenBridge.generate(token_set, mapping, fluid_output: :legacy)
      assert legacy == explicit
    end

    test "rejects unknown fluid_output values" do
      token_set = progressive_token_set()
      mapping = progressive_mapping([])

      assert {:error, {:invalid_fluid_output, :experimental}} =
               TokenBridge.generate(token_set, mapping, fluid_output: :experimental)
    end

    test "progressive output matches legacy bytes for ordinary mappings only" do
      token_set = progressive_token_set()

      mapping =
        progressive_mapping([
          %{"token_set_path" => "color.primary", "css_variable" => "--lf-color-primary"}
        ])

      assert {:ok, legacy} = TokenBridge.generate(token_set, mapping)

      assert {:ok, progressive} =
               TokenBridge.generate(token_set, mapping, fluid_output: :progressive)

      assert progressive == legacy
      refute progressive =~ "@supports"
      refute progressive =~ "--lf-fluid-"
    end

    test "native hero generate/2 bytes stay unchanged while progressive mode remains available" do
      token_set = hero_token_set()
      mapping = TokenBridge.load_mapping!(@mapping)

      assert {:ok, legacy} = TokenBridge.generate(token_set, mapping)

      assert {:ok, progressive} =
               TokenBridge.generate(token_set, mapping, fluid_output: :progressive)

      assert progressive == legacy
      assert legacy =~ "--lf-space-gutter:"
    end

    test "layered shared and hero generate/2 bytes stay unchanged" do
      token_set = hero_token_set()
      shared = TokenBridge.load_mapping!(@shared_mapping)
      hero = TokenBridge.load_mapping!(@mapping)

      assert {:ok, legacy} = TokenBridge.generate(token_set, [shared, hero])

      assert {:ok, progressive} =
               TokenBridge.generate(token_set, [shared, hero], fluid_output: :progressive)

      assert progressive == legacy
    end

    test "uses one explicit CSSSerializer.plan call in TokenBridge source" do
      source = File.read!(@token_bridge_source)
      assert length(:binary.matches(source, "CSSSerializer.plan(")) == 1
    end

    test "keeps fallback dependencies before mapped package declarations" do
      token_set = progressive_token_set()

      mapping =
        progressive_mapping([
          %{"token_set_path" => @value_path, "css_variable" => "--lf-aaa-mapped-first-lexically"}
        ])

      assert {:ok, css} = TokenBridge.generate(token_set, mapping, fluid_output: :progressive)

      [_, root_block | _] = :binary.split(css, ":root {\n", [])

      root_lines =
        root_body_lines(root_block)
        |> Enum.reject(&(String.starts_with?(&1, "@supports") or &1 == "}"))

      assert hd(root_lines) =~ "#{@domain_progress_var}:"
      assert List.last(root_lines) =~ "--lf-aaa-mapped-first-lexically:"
    end

    test "production obtains mapped Fluid candidates through CSSValue.candidate/3" do
      source = File.read!(@token_bridge_source)

      assert source =~ "CSSValue.candidate(token_set, token, fluid_target: :fallback)"
      refute source =~ "plan_value_expression"
      refute source =~ "plan.values"
    end

    test "contextual Fluid semantics ignore metadata css_expression and match fallback candidates" do
      token_set =
        put_in(
          progressive_token_set(),
          [Access.key!(:tokens), @value_path, Access.key!(:metadata)],
          %{"css_expression" => "999px"}
        )

      mapping =
        progressive_mapping([
          %{"token_set_path" => @value_path, "css_variable" => "--lf-space-fluid-gap"}
        ])

      token = Map.fetch!(token_set.tokens, @value_path)

      assert {:ok, expected} = CSSValue.candidate(token_set, token, fluid_target: :fallback)
      assert {:ok, css} = TokenBridge.generate(token_set, mapping, fluid_output: :progressive)
      refute css =~ "999px"
      assert css =~ "--lf-space-fluid-gap: #{expected};"
    end

    test "uses a valid progress feature query for progressive enhancement" do
      token_set = progressive_token_set()

      mapping =
        progressive_mapping([
          %{"token_set_path" => @value_path, "css_variable" => "--lf-space-fluid-gap"}
        ])

      assert {:ok, css} = TokenBridge.generate(token_set, mapping, fluid_output: :progressive)
      assert css =~ "@supports #{@progress_supports_condition}"
      refute css =~ "width: progress"
      refute css =~ "progress(0%, 0px, 1px)"
    end

    test "emits the exact approved progressive FluidValue stylesheet" do
      token_set = progressive_token_set()

      mapping =
        progressive_mapping([
          %{"token_set_path" => @value_path, "css_variable" => "--lf-space-fluid-gap"}
        ])

      assert {:ok, css} = TokenBridge.generate(token_set, mapping, fluid_output: :progressive)

      assert css ==
               "/* Generated by LiveFrames.Styling.TokenBridge — do not edit. */\n" <>
                 ":root {\n" <>
                 "  #{@domain_progress_var}: #{@fallback_progress};\n" <>
                 "  --lf-space-fluid-gap: calc(1rem + ((1.125rem - 1rem) * var(#{@domain_progress_var})));\n" <>
                 "}\n\n" <>
                 "#{@supports_query} {\n" <>
                 "  :root {\n" <>
                 "    #{@domain_progress_var}: progress(100vw, 500px, 1000px);\n" <>
                 "  }\n}\n"
    end

    test "materializes a progressive FluidScaleStep with deduplicated scale dependencies" do
      token_set = progressive_token_set()

      mapping =
        progressive_mapping([
          %{"token_set_path" => @step_path, "css_variable" => "--lf-type-heading-h1"}
        ])

      assert {:ok, css} = TokenBridge.generate(token_set, mapping, fluid_output: :progressive)

      assert count_declarations(css, "--lf-fluid-scale-typography-scale-primary-base") == 1
      assert count_declarations(css, "--lf-fluid-scale-typography-scale-primary-ratio") == 1
      assert domain_progress_declarations(css, @domain_progress_var) == 2

      block = supports_block(css)
      refute block =~ "--lf-fluid-scale-typography-scale-primary-base"
      refute block =~ "--lf-type-heading-h1"
    end

    test "deduplicates one domain across multiple FluidValues" do
      token_set = progressive_token_set()

      mapping =
        progressive_mapping([
          %{"token_set_path" => @value_path, "css_variable" => "--lf-space-fluid-gap"},
          %{"token_set_path" => @second_value_path, "css_variable" => "--lf-type-fluid-body"}
        ])

      assert {:ok, css} = TokenBridge.generate(token_set, mapping, fluid_output: :progressive)
      assert domain_progress_declarations(css, @domain_progress_var) == 2
      assert count_declarations(css, "--lf-space-fluid-gap") == 1
      assert count_declarations(css, "--lf-type-fluid-body") == 1
    end

    test "deduplicates one scale across multiple FluidScaleSteps" do
      token_set = progressive_token_set()

      mapping =
        progressive_mapping([
          %{"token_set_path" => @step_path, "css_variable" => "--lf-type-heading-h1"},
          %{"token_set_path" => @second_step_path, "css_variable" => "--lf-type-heading-h2"}
        ])

      assert {:ok, css} = TokenBridge.generate(token_set, mapping, fluid_output: :progressive)
      assert domain_progress_declarations(css, @domain_progress_var) == 2
      assert count_declarations(css, "--lf-fluid-scale-typography-scale-primary-base") == 1
      assert count_declarations(css, "--lf-fluid-scale-typography-scale-primary-ratio") == 1
      assert count_declarations(css, "--lf-type-heading-h1") == 1
      assert count_declarations(css, "--lf-type-heading-h2") == 1
    end

    test "deduplicates one domain across two scales" do
      spacing_step = %{
        "type" => "fluid_scale_step",
        "format_version" => "1.0.0",
        "scale_ref" => @second_scale_path,
        "power" => 1
      }

      token_set =
        put_in(
          progressive_token_set(),
          [Access.key!(:tokens), "spacing.step.primary"],
          Token.new(
            path: "spacing.step.primary",
            resolution_status: :resolved,
            resolved_value: spacing_step
          )
        )

      mapping =
        progressive_mapping([
          %{"token_set_path" => @step_path, "css_variable" => "--lf-type-heading-h1"},
          %{
            "token_set_path" => "spacing.step.primary",
            "css_variable" => "--lf-space-step-primary"
          }
        ])

      assert {:ok, css} = TokenBridge.generate(token_set, mapping, fluid_output: :progressive)
      assert domain_progress_declarations(css, @domain_progress_var) == 2
      assert count_declarations(css, "--lf-fluid-scale-typography-scale-primary-base") == 1
      assert count_declarations(css, "--lf-fluid-scale-spacing-scale-primary-base") == 1
      assert count_declarations(css, "--lf-fluid-scale-typography-scale-primary-ratio") == 1
      assert count_declarations(css, "--lf-fluid-scale-spacing-scale-primary-ratio") == 1
    end

    test "deduplicates shared domain dependencies across mixed FluidValue and FluidScaleStep mappings" do
      token_set = progressive_token_set()

      mapping =
        progressive_mapping([
          %{"token_set_path" => @value_path, "css_variable" => "--lf-space-fluid-gap"},
          %{"token_set_path" => @step_path, "css_variable" => "--lf-type-heading-h1"}
        ])

      assert {:ok, css} = TokenBridge.generate(token_set, mapping, fluid_output: :progressive)
      assert domain_progress_declarations(css, @domain_progress_var) == 2

      reversed =
        progressive_mapping([
          %{"token_set_path" => @step_path, "css_variable" => "--lf-type-heading-h1"},
          %{"token_set_path" => @value_path, "css_variable" => "--lf-space-fluid-gap"}
        ])

      assert {:ok, reversed_css} =
               TokenBridge.generate(token_set, reversed, fluid_output: :progressive)

      assert reversed_css == css
    end

    test "emits both mapped declarations when the same Fluid path appears across layers" do
      token_set = progressive_token_set()

      first_layer = %{
        "schema_version" => "1.0.0",
        "mapping_version" => "fluid_layer_a",
        "entries" => [
          %{"token_set_path" => @value_path, "css_variable" => "--lf-space-fluid-gap-a"}
        ]
      }

      second_layer = %{
        "schema_version" => "1.0.0",
        "mapping_version" => "fluid_layer_b",
        "entries" => [
          %{"token_set_path" => @value_path, "css_variable" => "--lf-space-fluid-gap-b"}
        ]
      }

      assert {:ok, css} =
               TokenBridge.generate(token_set, [first_layer, second_layer],
                 fluid_output: :progressive
               )

      assert domain_progress_declarations(css, @domain_progress_var) == 2
      assert count_declarations(css, "--lf-space-fluid-gap-a") == 1
      assert count_declarations(css, "--lf-space-fluid-gap-b") == 1
    end

    test "rejects mapped variables that collide with generated Fluid dependencies" do
      token_set = progressive_token_set()

      mapping =
        progressive_mapping([
          %{"token_set_path" => @value_path, "css_variable" => @domain_progress_var}
        ])

      assert {:error, {:duplicate_css_variables, [@domain_progress_var]}} =
               TokenBridge.generate(token_set, mapping, fluid_output: :progressive)
    end

    test "preserves underscore segments in generated Fluid domain variable names" do
      underscore_value = %{
        "type" => "fluid_value",
        "format_version" => "1.0.0",
        "domain_ref" => @underscore_domain_path,
        "start_value" => %{"value" => 1, "unit" => "rem"},
        "end_value" => %{"value" => 1.25, "unit" => "rem"},
        "interpolation" => "linear"
      }

      token_set =
        put_in(
          progressive_token_set(),
          [Access.key!(:tokens), "spacing.fluid.underscore"],
          Token.new(
            path: "spacing.fluid.underscore",
            resolution_status: :resolved,
            resolved_value: underscore_value
          )
        )

      mapping =
        progressive_mapping([
          %{
            "token_set_path" => "spacing.fluid.underscore",
            "css_variable" => "--lf-space-underscore"
          }
        ])

      assert {:ok, css} = TokenBridge.generate(token_set, mapping, fluid_output: :progressive)
      assert css =~ "#{@underscore_domain_progress_var}:"
      refute css =~ "--lf-fluid-domain-layout-fluid-viewport-default-progress"
    end

    test "rejects direct FluidDomain mappings" do
      token_set = progressive_token_set()

      mapping =
        progressive_mapping([
          %{"token_set_path" => @domain_path, "css_variable" => "--lf-fluid-domain-direct"}
        ])

      assert {:error, {:non_serializable_resolved_value, @domain_path}} =
               TokenBridge.generate(token_set, mapping, fluid_output: :progressive)
    end

    test "rejects direct FluidScale mappings" do
      token_set = progressive_token_set()

      mapping =
        progressive_mapping([
          %{"token_set_path" => @scale_path, "css_variable" => "--lf-fluid-scale-direct"}
        ])

      assert {:error, {:non_serializable_resolved_value, @scale_path}} =
               TokenBridge.generate(token_set, mapping, fluid_output: :progressive)
    end

    test "preserves missing token errors in progressive mode" do
      token_set = progressive_token_set()

      mapping =
        progressive_mapping([
          %{"token_set_path" => "spacing.missing.token", "css_variable" => "--lf-space-missing"}
        ])

      assert {:error, {:missing_token, "spacing.missing.token"}} =
               TokenBridge.generate(token_set, mapping, fluid_output: :progressive)
    end

    test "preserves unresolved token errors in progressive mode" do
      token_set =
        put_in(
          progressive_token_set(),
          [Access.key!(:tokens), "color.secondary"],
          Token.new(path: "color.secondary", resolution_status: :unresolved, resolved_value: nil)
        )

      mapping =
        progressive_mapping([
          %{"token_set_path" => "color.secondary", "css_variable" => "--lf-color-secondary"}
        ])

      assert {:error, {:unresolved_token, "color.secondary", :unresolved}} =
               TokenBridge.generate(token_set, mapping, fluid_output: :progressive)
    end

    test "rejects mixed progressive Fluid and unsafe ordinary mappings" do
      token_set =
        put_in(
          progressive_token_set(),
          [Access.key!(:tokens), "color.secondary"],
          Token.new(
            path: "color.secondary",
            resolution_status: :resolved,
            resolved_value: "red; } body { color: red"
          )
        )

      mapping =
        progressive_mapping([
          %{"token_set_path" => @value_path, "css_variable" => "--lf-space-fluid-gap"},
          %{"token_set_path" => "color.secondary", "css_variable" => "--lf-color-secondary"}
        ])

      assert {:error, {:unsafe_css_value, "--lf-color-secondary", _}} =
               TokenBridge.generate(token_set, mapping, fluid_output: :progressive)
    end

    test "progressive output is deterministic" do
      token_set = progressive_token_set()

      mapping =
        progressive_mapping([
          %{"token_set_path" => @value_path, "css_variable" => "--lf-space-fluid-gap"},
          %{"token_set_path" => @step_path, "css_variable" => "--lf-type-heading-h1"}
        ])

      assert {:ok, first} = TokenBridge.generate(token_set, mapping, fluid_output: :progressive)
      assert {:ok, second} = TokenBridge.generate(token_set, mapping, fluid_output: :progressive)
      assert first == second
    end

    test "does not mutate the TokenSet during progressive generation" do
      token_set = progressive_token_set()

      mapping =
        progressive_mapping([
          %{"token_set_path" => @value_path, "css_variable" => "--lf-space-fluid-gap"}
        ])

      before = token_set
      assert {:ok, _css} = TokenBridge.generate(token_set, mapping, fluid_output: :progressive)
      assert before == token_set
    end

    test "keeps fluid_px_pair compose mappings unchanged in progressive mode" do
      token_set =
        progressive_token_set()
        |> put_in(
          [Access.key!(:tokens), "spacing.gutter.min"],
          Token.new(
            path: "spacing.gutter.min",
            resolution_status: :resolved,
            resolved_value: "16px"
          )
        )
        |> put_in(
          [Access.key!(:tokens), "spacing.gutter.max"],
          Token.new(
            path: "spacing.gutter.max",
            resolution_status: :resolved,
            resolved_value: "32px"
          )
        )
        |> put_in(
          [Access.key!(:tokens), "layout.viewport.min"],
          Token.new(
            path: "layout.viewport.min",
            resolution_status: :resolved,
            resolved_value: "768px"
          )
        )
        |> put_in(
          [Access.key!(:tokens), "layout.viewport.max"],
          Token.new(
            path: "layout.viewport.max",
            resolution_status: :resolved,
            resolved_value: "1200px"
          )
        )

      mapping =
        progressive_mapping([
          %{
            "compose" => %{
              "type" => "fluid_px_pair",
              "min" => "spacing.gutter.min",
              "max" => "spacing.gutter.max",
              "viewport_min" => "layout.viewport.min",
              "viewport_max" => "layout.viewport.max"
            },
            "css_variable" => "--lf-space-gutter"
          }
        ])

      assert {:ok, progressive_css} =
               TokenBridge.generate(token_set, mapping, fluid_output: :progressive)

      assert {:ok, legacy_css} = TokenBridge.generate(token_set, mapping, fluid_output: :legacy)
      assert progressive_css == legacy_css
    end

    test "still rejects unsafe css values in progressive mode" do
      token_set =
        put_in(
          progressive_token_set(),
          [Access.key!(:tokens), "color.primary"],
          Token.new(
            path: "color.primary",
            resolution_status: :resolved,
            resolved_value: "red; background: url(javascript:alert(1))"
          )
        )

      mapping =
        progressive_mapping([
          %{"token_set_path" => "color.primary", "css_variable" => "--lf-color-primary"}
        ])

      assert {:error, {:unsafe_css_value, "--lf-color-primary", _}} =
               TokenBridge.generate(token_set, mapping, fluid_output: :progressive)
    end
  end
end
