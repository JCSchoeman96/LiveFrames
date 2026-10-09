defmodule LiveFrames.AutomaticCSSAdapterTest do
  use ExUnit.Case, async: false

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.AutomaticCSS.FluidClamp
  alias LiveFrames.Adapters.AutomaticCSS.IconTokens
  alias LiveFrames.Adapters.AutomaticCSS.Normalizer
  alias LiveFrames.Tokens
  alias LiveFrames.Tokens.VariableAuthority

  defp fixture_path do
    Path.expand("../../../../fixtures/automatic_css/acss_settings.json", __DIR__)
  end

  defp fixture_settings do
    Jason.decode!(File.read!(fixture_path()))
  end

  defp authority(token, variable, kind) do
    token.metadata
    |> Map.get("variable_authorities", [])
    |> Enum.find(&(&1["variable"] == variable and &1["kind"] == kind))
  end

  defp minimal_settings do
    %{
      "color-primary" => "#32a2c1",
      "primary-hover-h" => 193,
      "primary-hover-s" => 59,
      "primary-hover-l" => 55.2,
      "primary-light-h" => 193,
      "primary-light-s" => 59,
      "primary-light-l" => 85,
      "primary-ultra-dark-h" => 193,
      "primary-ultra-dark-s" => 59,
      "primary-ultra-dark-l" => 10,
      "color-neutral" => "#000000",
      "option-bw-color-variables" => "on",
      "auto-color-scheme" => "on",
      "text-dark" => "var(--black)",
      "text-light" => "var(--white)",
      "bg-ultra-dark" => "var(--neutral-ultra-dark)",
      "bg-ultra-dark-text" => "var(--text-light)",
      "bg-ultra-dark-heading" => "var(--text-light)",
      "neutral-ultra-dark-h" => 0,
      "neutral-ultra-dark-s" => 0,
      "neutral-ultra-dark-l" => 10,
      "base-space" => 30,
      "base-space-min" => 24,
      "mob-space-scale" => 1.333,
      "space-scale" => 1.5,
      "contextual-content-gap" => "var(--space-m)",
      "contextual-grid-gap" => "var(--space-m)",
      "contextual-container-gap" => "var(--space-xl)",
      "section-padding-block" => "var(--section-space-m)",
      "gutter-min" => 16,
      "gutter-max" => 80,
      "base-text-desk" => 18,
      "base-text-mob" => 16,
      "base-text-lh" => "calc(6px + 2ex)",
      "base-heading-desk" => 20,
      "base-heading-mob" => 18,
      "base-heading-lh" => "calc(4px + 2ex)",
      "heading-scale" => 1.333,
      "mob-heading-scale" => 1.2,
      "text-scale" => 1.333,
      "mob-text-scale" => 1.2,
      "vp-min" => 360,
      "vp-max" => 1366,
      "btn-primary-bg" => "var(--primary)",
      "btn-primary-hover" => "var(--primary-hover)",
      "btn-primary-text" => "var(--primary-ultra-dark)",
      "btn-primary-border-color" => "var(--btn-background)",
      "btn-primary-focus-color" => "var(--primary-light)",
      "btn-border-radius" => "var(--radius)",
      "base-radius" => "5px",
      "btn-padding-inline" => "1.25em",
      "btn-padding-block" => ".5em",
      "btn-min-width" => 140,
      "btn-font-size" => "--text-m",
      "btn-font-weight" => "400",
      "btn-line-height" => 1,
      "btn-border-width" => "1.5px",
      "btn-border-style" => "solid",
      "btn-primary-outline-background" => "transparent",
      "btn-primary-outline-background-hover" => "var(--primary-hover)",
      "btn-primary-outline-border-color" => "var(--primary)",
      "btn-primary-outline-border-hover" => "var(--btn-background-hover)",
      "btn-primary-outline-focus-color" => "var(--primary-semi-light)",
      "primary-outline-btn-text" => "var(--primary)",
      "primary-outline-hover-text" => "var(--primary-ultra-light)"
    }
  end

  test "recognizes and normalizes the approved fixture through from_file" do
    assert {:ok, token_set, diagnostics} = AutomaticCSS.from_file(fixture_path())
    assert token_set.token_set_version == "1.0.0"
    assert is_list(diagnostics)
    assert token_set.source_metadata["source_shape"] == "flat_settings_map"
  end

  test "does not claim a source version when the input has no embedded version" do
    json = Jason.encode!(%{"color-primary" => "#32a2c1"})

    assert {:ok, token_set, _diagnostics} = AutomaticCSS.from_json(json)
    assert token_set.source_metadata["source_version"] == nil
    assert token_set.source_metadata["source_version_status"] == "not_embedded"
  end

  test "returns structured diagnostics for malformed JSON" do
    assert {:error, diagnostics} = AutomaticCSS.from_json("{not-json")
    assert Enum.any?(diagnostics, &(&1.code == "acss.source.json_invalid"))
  end

  test "rejects unsupported top-level data without crashing" do
    assert {:error, diagnostics} = AutomaticCSS.normalize([{"color-primary", "#fff"}])
    assert Enum.any?(diagnostics, &(&1.code == "acss.source.invalid"))

    assert {:error, diagnostics} = AutomaticCSS.normalize(%{"unrelated" => true})
    assert Enum.any?(diagnostics, &(&1.code == "acss.source.invalid"))
  end

  test "returns structured diagnostics for an unreadable file" do
    assert {:error, diagnostics} =
             AutomaticCSS.from_file("/tmp/liveframes-phase-3-missing-acss.json")

    assert Enum.any?(diagnostics, &(&1.code == "acss.source.invalid"))
  end

  test "normalizes representative categories and relationships" do
    assert {:ok, token_set, diagnostics} = AutomaticCSS.normalize(minimal_settings())
    assert diagnostics == token_set.diagnostics
    assert token_set.tokens["color.primary"].resolved_value == "#32a2c1"
    assert token_set.tokens["color.primary.hover"].resolved_value == "hsl(193 59% 55.2%)"
    assert token_set.tokens["spacing.base.max"].resolved_value == "30px"
    assert token_set.tokens["spacing.gutter.min"].resolved_value == "16px"
    assert token_set.tokens["typography.body.line_height"].resolved_value == "calc(6px + 2ex)"
    assert token_set.tokens["button.primary.background"].references == ["color.primary"]
    assert token_set.tokens["button.primary.border"].references == ["button.primary.background"]

    assert token_set.tokens["button.primary.font_size"].references == [
             "typography.body.scale.medium"
           ]

    assert token_set.tokens["layout.viewport.min"].resolved_value == "360px"
  end

  test "derives all six spacing sizes from their mobile and desktop scales" do
    settings =
      minimal_settings()
      |> Map.put("base-space-min", 32)
      |> Map.put("base-space", 96)
      |> Map.put("mob-space-scale", 2)
      |> Map.put("space-scale", 3)
      |> Map.put("vp-min", 400)
      |> Map.put("vp-max", 800)

    assert {:ok, token_set, _diagnostics} = AutomaticCSS.normalize(settings)

    cases = [
      {"space-xs", "spacing.scale.xs", 8.0, 96 / 9},
      {"space-s", "spacing.scale.s", 16.0, 32.0},
      {"space-m", "spacing.scale.medium", 32.0, 96.0},
      {"space-l", "spacing.scale.l", 64.0, 288.0},
      {"space-xl", "spacing.scale.xl", 128.0, 864.0},
      {"space-xxl", "spacing.scale.xxl", 256.0, 2592.0}
    ]

    for {variable, path, mobile_px, desktop_px} <- cases do
      token = token_set.tokens[path]
      assert is_map(token), "missing canonical spacing token #{path}"
      inputs = token.value["inputs"]

      assert token.resolution_status == :resolved
      assert token.value["type"] == "derived"
      assert token.value["recipe"] == "acss.clamp"
      assert token.value["variable"] == variable
      assert token.resolved_value == token.value
      assert token.source_expression == inputs

      assert token.references == [
               "spacing.base.min",
               "spacing.base.max",
               "layout.viewport.min",
               "layout.viewport.max"
             ]

      assert inputs == %{
               "mobile_base" => 32.0,
               "desktop_base" => 96.0,
               "mobile_scale" => 2.0,
               "desktop_scale" => 3.0,
               "viewport_min" => 400.0,
               "viewport_max" => 800.0,
               "calculation_group" => "spacing"
             }

      css_expression = token.metadata["css_expression"]

      assert css_expression == FluidClamp.from_px_pair(mobile_px, desktop_px, 400, 800)
      assert String.starts_with?(css_expression, "clamp(")
      assert css_expression =~ "calc("
      assert css_expression =~ "vw"

      assert authority(token, "--#{variable}", "source_output_alias") == %{
               "variable" => "--#{variable}",
               "kind" => "source_output_alias",
               "authority_id" =>
                 "automatic-css-4.0.1:calculated-variable-group:spacing:#{variable}",
               "source_key" => nil,
               "source_version" => "4.0.1"
             }
    end
  end

  test "preserves the existing space-m and space-xl CSS expressions" do
    assert {:ok, token_set, _diagnostics} = AutomaticCSS.from_file(fixture_path())

    settings = fixture_settings()

    inputs = %{
      "mobile_base" => settings["base-space-min"] * 1.0,
      "desktop_base" => settings["base-space"] * 1.0,
      "mobile_scale" => settings["mob-space-scale"] * 1.0,
      "desktop_scale" => settings["space-scale"] * 1.0,
      "viewport_min" => settings["vp-min"] * 1.0,
      "viewport_max" => settings["vp-max"] * 1.0,
      "calculation_group" => "spacing"
    }

    for {path, variable, css_expression} <- [
          {
            "spacing.scale.medium",
            "space-m",
            "clamp(1.5rem, calc(0.5964214712vw + 1.365805169rem), 1.875rem)"
          },
          {
            "spacing.scale.xl",
            "space-xl",
            "clamp(2.6653335rem, calc(2.4706425447vw + 2.1094389274rem), 4.21875rem)"
          }
        ] do
      token = token_set.tokens[path]

      assert token.value == %{
               "type" => "derived",
               "recipe" => "acss.clamp",
               "variable" => variable,
               "inputs" => inputs
             }

      assert token.resolved_value == token.value
      assert token.source_expression == inputs

      assert token.references == [
               "spacing.base.min",
               "spacing.base.max",
               "layout.viewport.min",
               "layout.viewport.max"
             ]

      assert token.provenance["source_keys"] == [
               "base-space-min",
               "base-space",
               "mob-space-scale",
               "space-scale",
               "vp-min",
               "vp-max"
             ]

      assert token.metadata["calculation_group"] == "spacing"
      assert token.metadata["css_expression"] == css_expression

      assert token.metadata["variable_authorities"] == [
               %{
                 "variable" => "--#{variable}",
                 "kind" => "source_output_alias",
                 "authority_id" =>
                   "automatic-css-4.0.1:calculated-variable-group:spacing:#{variable}",
                 "source_key" => nil,
                 "source_version" => "4.0.1"
               }
             ]
    end
  end

  test "orders clamp bounds while preserving descending viewport endpoints" do
    assert FluidClamp.from_px_pair(24, 16, 400, 800) ==
             "clamp(1rem, calc(-2vw + 2rem), 1.5rem)"
  end

  test "serializes the approved fixture space-xs with ordered descending bounds" do
    assert {:ok, token_set, _diagnostics} = AutomaticCSS.from_file(fixture_path())

    assert token_set.tokens["spacing.scale.xs"].metadata["css_expression"] ==
             "clamp(0.8333333333rem, calc(-0.0172384889vw + 0.8480506933rem), 0.8441720333rem)"
  end

  test "css_expression fails closed on arithmetic and formatting overflow" do
    for {desktop_base, viewport_max} <- [{-1.0e308, 400.0000000001}, {1.0e308, 800}] do
      inputs = %{
        "mobile_base" => 1.0e308,
        "desktop_base" => desktop_base,
        "mobile_scale" => 1,
        "desktop_scale" => 1,
        "viewport_min" => 400,
        "viewport_max" => viewport_max
      }

      assert is_nil(
               FluidClamp.css_expression(%{
                 "recipe" => "acss.clamp",
                 "variable" => "space-m",
                 "inputs" => inputs
               })
             )
    end
  end

  test "from_px_pair fails closed on arithmetic and formatting overflow" do
    assert is_nil(FluidClamp.from_px_pair(1.0e308, -1.0e308, 400, 400.0000000001))
    assert is_nil(FluidClamp.from_px_pair(1.0e308, 1.0e308, 400, 800))
  end

  test "fails all standard spacing tokens closed for invalid derived inputs" do
    settings = minimal_settings()

    invalid_cases = [
      {"missing mobile base", Map.delete(settings, "base-space-min")},
      {"missing desktop base", Map.delete(settings, "base-space")},
      {"missing mobile scale", Map.delete(settings, "mob-space-scale")},
      {"missing desktop scale", Map.delete(settings, "space-scale")},
      {"invalid mobile scale", Map.put(settings, "mob-space-scale", "not-a-number")},
      {"invalid desktop scale", Map.put(settings, "space-scale", "not-a-number")},
      {"zero mobile scale", Map.put(settings, "mob-space-scale", 0)},
      {"zero desktop scale", Map.put(settings, "space-scale", 0)},
      {"negative mobile scale", Map.put(settings, "mob-space-scale", -1)},
      {"negative desktop scale", Map.put(settings, "space-scale", -1)},
      {"missing viewport bound", Map.delete(settings, "vp-max")}
    ]

    paths = [
      "spacing.scale.xs",
      "spacing.scale.s",
      "spacing.scale.medium",
      "spacing.scale.l",
      "spacing.scale.xl",
      "spacing.scale.xxl"
    ]

    for {case_name, invalid_settings} <- invalid_cases do
      assert {:ok, token_set, _diagnostics} = AutomaticCSS.normalize(invalid_settings)

      for path <- paths do
        assert Map.has_key?(token_set.tokens, path), "missing canonical spacing token #{path}"

        assert token_set.tokens[path].resolution_status == :unresolved,
               "#{case_name} left #{path} resolved"

        assert token_set.tokens[path].resolved_value == nil,
               "#{case_name} produced a value for #{path}"
      end
    end
  end

  test "FluidClamp rejects zero, negative, and non-numeric spacing scales" do
    inputs = %{
      "mobile_base" => 32,
      "desktop_base" => 96,
      "mobile_scale" => 2,
      "desktop_scale" => 3,
      "viewport_min" => 400,
      "viewport_max" => 800
    }

    for {variable, key, value} <- [
          {"space-xs", "mobile_scale", 0},
          {"space-xs", "desktop_scale", 0},
          {"space-s", "mobile_scale", 0},
          {"space-s", "desktop_scale", 0},
          {"space-xl", "mobile_scale", -1},
          {"space-xl", "mobile_scale", "invalid"},
          {"space-xl", "desktop_scale", -1},
          {"space-xl", "desktop_scale", "invalid"},
          {"space-xxl", "mobile_scale", 1.0e308}
        ] do
      assert is_nil(
               FluidClamp.css_expression(%{
                 "recipe" => "acss.clamp",
                 "variable" => variable,
                 "inputs" => Map.put(inputs, key, value)
               })
             )
    end
  end

  test "materializes source-map and calculated-group output aliases" do
    assert {:ok, token_set, _diagnostics} = AutomaticCSS.normalize(minimal_settings())

    cases = [
      {"typography.heading.line_height", "--line-height", "base-heading-lh"},
      {"radius.base", "--radius", "base-radius"},
      {"layout.viewport.max", "--content-width", "vp-max"},
      {"typography.body.line_height", "--line-height", "base-text-lh"},
      {"color.background.ultra_dark.heading", "--color", "bg-ultra-dark-heading"},
      {"button.primary.radius", "--btn-radius", "btn-border-radius"},
      {"button.primary.border_style", "--btn-border-style", "btn-border-style"},
      {"button.primary.border", "--btn-border-color", "btn-primary-border-color"},
      {"button.primary.focus", "--focus-color", "btn-primary-focus-color"},
      {"button.primary.background_hover", "--btn-background-hover", "btn-primary-hover"},
      {"button.primary.outline.background_hover", "--btn-background-hover",
       "btn-primary-outline-background-hover"},
      {"button.primary.outline.border", "--btn-border-color", "btn-primary-outline-border-color"},
      {"button.primary.outline.border_hover", "--btn-border-color-hover",
       "btn-primary-outline-border-hover"},
      {"button.primary.outline.focus", "--focus-color", "btn-primary-outline-focus-color"},
      {"button.primary.text", "--btn-text-color", "btn-primary-text"},
      {"spacing.content_gap", "--content-gap", "contextual-content-gap"},
      {"spacing.container_gap", "--container-gap", "contextual-container-gap"},
      {"spacing.grid_gap", "--grid-gap", "contextual-grid-gap"},
      {"button.primary.background", "--btn-background", "btn-primary-bg"},
      {"button.primary.outline.background", "--btn-background", "btn-primary-outline-background"},
      {"typography.heading.font_weight", "--font-weight", "heading-weight"},
      {"button.primary.outline.text", "--btn-text-color", "primary-outline-btn-text"},
      {"button.primary.outline.text_hover", "--btn-text-color-hover",
       "primary-outline-hover-text"},
      {"spacing.scale.medium", "--space-m", nil},
      {"spacing.scale.xl", "--space-xl", nil},
      {"spacing.scale.xs", "--space-xs", nil},
      {"spacing.scale.s", "--space-s", nil},
      {"spacing.scale.l", "--space-l", nil},
      {"spacing.scale.xxl", "--space-xxl", nil},
      {"spacing.section", "--section-space-m", nil},
      {"typography.body.scale.medium", "--text-m", nil},
      {"typography.body.scale.small", "--text-s", nil},
      {"typography.heading.scale.h1", "--h1", nil}
    ]

    for {path, variable, source_key} <- cases do
      token = token_set.tokens[path]
      assert is_map(token), "missing canonical token #{path}"
      record = authority(token, variable, "source_output_alias")

      assert record, "missing output authority for #{path} / #{variable}"

      message = inspect({path, variable, record})
      assert record["source_key"] == source_key, message
      assert record["source_version"] == "4.0.1", message
      assert is_binary(record["authority_id"]) and record["authority_id"] != "", message
    end

    actual_aliases =
      Enum.flat_map(token_set.tokens, fn {path, token} ->
        token.metadata
        |> Map.get("variable_authorities", [])
        |> Enum.filter(&(&1["kind"] == "source_output_alias"))
        |> Enum.map(&{path, &1["variable"], &1["source_key"]})
      end)

    assert Enum.sort(actual_aliases) == Enum.sort(cases)

    calculated_aliases =
      Enum.flat_map(token_set.tokens, fn {path, token} ->
        token.metadata
        |> Map.get("variable_authorities", [])
        |> Enum.filter(&(&1["authority_id"] =~ ":calculated-variable-group:"))
        |> Enum.map(&{path, &1["variable"], &1["source_key"]})
      end)

    assert Enum.sort(calculated_aliases) ==
             Enum.sort([
               {"spacing.scale.medium", "--space-m", nil},
               {"spacing.scale.xl", "--space-xl", nil},
               {"spacing.scale.xs", "--space-xs", nil},
               {"spacing.scale.s", "--space-s", nil},
               {"spacing.scale.l", "--space-l", nil},
               {"spacing.scale.xxl", "--space-xxl", nil},
               {"spacing.section", "--section-space-m", nil},
               {"typography.body.scale.medium", "--text-m", nil},
               {"typography.body.scale.small", "--text-s", nil},
               {"typography.heading.scale.h1", "--h1", nil}
             ])

    calculated_ids = [
      {"spacing.scale.medium", "--space-m", "spacing"},
      {"spacing.scale.xl", "--space-xl", "spacing"},
      {"spacing.scale.xs", "--space-xs", "spacing"},
      {"spacing.scale.s", "--space-s", "spacing"},
      {"spacing.scale.l", "--space-l", "spacing"},
      {"spacing.scale.xxl", "--space-xxl", "spacing"},
      {"spacing.section", "--section-space-m", "section-spacing"},
      {"typography.body.scale.medium", "--text-m", "text"},
      {"typography.body.scale.small", "--text-s", "text"},
      {"typography.heading.scale.h1", "--h1", "headings"}
    ]

    for {path, variable, group} <- calculated_ids do
      record = authority(token_set.tokens[path], variable, "source_output_alias")

      assert record["authority_id"] ==
               "automatic-css-4.0.1:calculated-variable-group:#{group}:#{String.trim_leading(variable, "--")}"
    end

    assert Enum.map(actual_aliases, &elem(&1, 1))
           |> Enum.count(&(&1 == "--content-width")) == 1

    for {_path, token} <- token_set.tokens do
      authorities = Map.get(token.metadata, "variable_authorities", [])

      assert authorities == Enum.uniq(authorities)

      assert authorities ==
               Enum.sort_by(authorities, fn record ->
                 {record["variable"], record["kind"], record["authority_id"],
                  record["source_key"] || ""}
               end)
    end

    width_authority =
      authority(token_set.tokens["layout.viewport.max"], "--content-width", "source_output_alias")

    assert %{"authority_id" => "automatic-css-4.0.1:setting:vp-max:css-variable-reference"} =
             width_authority
  end

  test "content gap retains output-alias and explicit project authority" do
    assert {:ok, token_set, _diagnostics} = AutomaticCSS.normalize(minimal_settings())
    token = token_set.tokens["spacing.content_gap"]

    assert %{"source_key" => "contextual-content-gap"} =
             authority(token, "--content-gap", "source_output_alias")

    assert authority(token, "--content-gap", "explicit_project_contract") == %{
             "variable" => "--content-gap",
             "kind" => "explicit_project_contract",
             "authority_id" => "liveframes:project:content-gap:v1",
             "source_key" => nil,
             "source_version" => nil
           }
  end

  test "source references come from successful resolver and foundation contracts" do
    assert {:ok, token_set, _diagnostics} = AutomaticCSS.normalize(minimal_settings())

    assert %{
             "source_key" => "contextual-content-gap",
             "source_version" => "4.0.1"
           } =
             authority(token_set.tokens["spacing.content_gap"], "--space-m", "source_reference")

    assert %{
             "authority_id" => "automatic-css-4.0.1:foundation-contract:--black",
             "source_key" => nil,
             "source_version" => "4.0.1"
           } = authority(token_set.tokens["color.black"], "--black", "source_reference")
  end

  test "ambiguous variables retain every independently proven owning path" do
    assert {:ok, token_set, _diagnostics} = AutomaticCSS.normalize(minimal_settings())
    assert {:ok, index} = VariableAuthority.build(token_set)

    primary = VariableAuthority.resolve(index, "--primary")
    assert primary.state == :ambiguous_candidates

    assert Enum.map(primary.candidates, & &1.token_path) == [
             "button.primary.background",
             "button.primary.outline.border",
             "button.primary.outline.text"
           ]

    space_m = VariableAuthority.resolve(index, "--space-m")
    assert space_m.state == :ambiguous_candidates

    assert Enum.map(space_m.candidates, & &1.token_path) == [
             "spacing.content_gap",
             "spacing.grid_gap",
             "spacing.scale.medium"
           ]

    for {variable, path} <- [
          {"--space-xs", "spacing.scale.xs"},
          {"--space-s", "spacing.scale.s"},
          {"--space-l", "spacing.scale.l"},
          {"--space-xxl", "spacing.scale.xxl"}
        ] do
      assert %{
               state: :unique_candidate,
               candidates: [%{token_path: ^path, resolution_status: :resolved}]
             } = VariableAuthority.resolve(index, variable)
    end

    assert %{
             state: :ambiguous_candidates,
             candidates: [
               %{token_path: "spacing.container_gap", resolution_status: :resolved},
               %{token_path: "spacing.scale.xl", resolution_status: :resolved}
             ]
           } = VariableAuthority.resolve(index, "--space-xl")

    assert Enum.map(VariableAuthority.resolve(index, "--radius").candidates, & &1.token_path) == [
             "button.primary.radius",
             "radius.base"
           ]

    assert Enum.map(
             VariableAuthority.resolve(index, "--line-height").candidates,
             & &1.token_path
           ) == ["typography.body.line_height", "typography.heading.line_height"]

    assert Enum.map(VariableAuthority.resolve(index, "--white").candidates, & &1.token_path) == [
             "color.text.light",
             "color.white"
           ]

    assert Enum.map(VariableAuthority.resolve(index, "--text-m").candidates, & &1.token_path) == [
             "button.primary.font_size",
             "typography.body.scale.medium"
           ]

    section_space = VariableAuthority.resolve(index, "--section-space-m")
    assert section_space.state == :ambiguous_candidates

    assert Enum.map(section_space.candidates, & &1.token_path) == [
             "spacing.section",
             "spacing.section.padding_block"
           ]

    section_alias =
      authority(
        token_set.tokens["spacing.section"],
        "--section-space-m",
        "source_output_alias"
      )

    section_reference =
      authority(
        token_set.tokens["spacing.section.padding_block"],
        "--section-space-m",
        "source_reference"
      )

    assert section_alias["authority_id"] ==
             "automatic-css-4.0.1:calculated-variable-group:section-spacing:section-space-m"

    assert section_reference["source_key"] == "section-padding-block"

    candidates_by_path = Map.new(section_space.candidates, &{&1.token_path, &1.authorities})
    assert section_alias in candidates_by_path["spacing.section"]
    assert section_reference in candidates_by_path["spacing.section.padding_block"]

    content_width = VariableAuthority.resolve(index, "--content-width")
    assert content_width.state == :unique_candidate
    assert hd(content_width.candidates).token_path == "layout.viewport.max"
  end

  test "approved fixture resolves each spacing variable through its existing authority state" do
    assert {:ok, token_set, _diagnostics} =
             AutomaticCSS.from_file(fixture_path(),
               source_version: "4.0.1",
               source_version_status: "fixture_reference"
             )

    assert {:ok, index} = VariableAuthority.build(token_set)

    for {variable, path} <- [
          {"--space-xs", "spacing.scale.xs"},
          {"--space-s", "spacing.scale.s"},
          {"--space-l", "spacing.scale.l"},
          {"--space-xxl", "spacing.scale.xxl"}
        ] do
      assert %{
               state: :unique_candidate,
               candidates: [%{token_path: ^path, resolution_status: :resolved}]
             } = VariableAuthority.resolve(index, variable)
    end

    assert %{
             state: :ambiguous_candidates,
             candidates: [
               %{token_path: "spacing.content_gap", resolution_status: :resolved},
               %{token_path: "spacing.grid_gap", resolution_status: :resolved},
               %{token_path: "spacing.scale.medium", resolution_status: :resolved}
             ]
           } = VariableAuthority.resolve(index, "--space-m")

    assert %{
             state: :ambiguous_candidates,
             candidates: [
               %{token_path: "spacing.container_gap", resolution_status: :resolved},
               %{token_path: "spacing.scale.xl", resolution_status: :resolved}
             ]
           } = VariableAuthority.resolve(index, "--space-xl")
  end

  test "resolves the proven BW foundation and ultra-dark contextual relationships" do
    assert {:ok, token_set, _diagnostics} = AutomaticCSS.normalize(minimal_settings())
    primary = token_set.tokens["color.primary"]
    black = token_set.tokens["color.black"]
    white = token_set.tokens["color.white"]
    text_dark = token_set.tokens["color.text.dark"]
    text_light = token_set.tokens["color.text.light"]
    ultra_dark_text = token_set.tokens["color.background.ultra_dark.text"]
    ultra_dark_heading = token_set.tokens["color.background.ultra_dark.heading"]

    assert primary.provenance["source_keys"] == ["color-primary"]
    assert primary.provenance["raw_value"] == "#32a2c1"
    assert primary.provenance["adapter"] == "automatic_css"
    assert primary.provenance["adapter_version"] == "1.0.0"
    assert primary.provenance["transformation"] == "direct"

    assert black.value["type"] == "derived"
    assert black.value["recipe"] == "acss.bw_foundation"
    assert black.value["variable"] == "--black"
    assert black.references == []
    refute black.value == token_set.tokens["color.neutral"].value
    assert black.resolved_value == "light-dark(#000, #fff)"
    assert black.source_expression["variable"] == "--black"
    assert black.source_expression["inputs"]["option_bw_color_variables"] == "on"
    assert black.source_expression["inputs"]["auto_color_scheme"] == "on"
    assert black.provenance["source_type"] == "automatic_css_reference_contract"
    assert black.provenance["source_variable"] == "--black"
    assert black.provenance["source_contract_version"] == "4.0.1"
    assert black.provenance["transformation"] == "acss_generated_foundation"

    assert white.value["type"] == "derived"
    assert white.value["variable"] == "--white"
    assert white.resolved_value == "light-dark(#fff, #000)"
    assert white.provenance["source_variable"] == "--white"

    assert text_dark.source_expression == "var(--black)"
    assert text_dark.references == ["color.black"]
    assert text_dark.resolution_status == :resolved
    assert text_dark.resolved_value == black.resolved_value
    assert text_light.source_expression == "var(--white)"
    assert text_light.references == ["color.white"]
    assert text_light.resolution_status == :resolved
    assert text_light.resolved_value == white.resolved_value

    assert ultra_dark_text.source_expression == "var(--text-light)"
    assert ultra_dark_text.references == ["color.text.light"]
    assert ultra_dark_text.resolution_status == :resolved
    assert ultra_dark_text.resolved_value == white.resolved_value
    assert ultra_dark_heading.references == ["color.text.light"]
    assert ultra_dark_heading.resolution_status == :resolved
    assert ultra_dark_heading.resolved_value == white.resolved_value

    refute Enum.any?(_diagnostics, &(&1.path in ["color.text.dark", "color.text.light"]))
  end

  test "preserves the proven literal BW foundation when auto color scheme is off" do
    settings = Map.put(minimal_settings(), "auto-color-scheme", "off")

    assert {:ok, token_set, _diagnostics} = AutomaticCSS.normalize(settings)
    assert token_set.tokens["color.black"].resolved_value == "#000"
    assert token_set.tokens["color.white"].resolved_value == "#fff"
    assert token_set.tokens["color.black"].source_expression["expression"] == "#000"
    assert token_set.tokens["color.white"].source_expression["expression"] == "#fff"
  end

  test "tolerates unrelated settings and applies strict required-token profiles" do
    settings = Map.put(minimal_settings(), "future-unrelated-setting", "ignored")
    assert {:ok, token_set, diagnostics} = AutomaticCSS.normalize(settings)
    assert Map.get(token_set.tokens, "future-unrelated-setting") == nil

    unknown = Enum.find(diagnostics, &(&1.code == "acss.setting.unknown"))
    assert unknown.severity == :info
    assert unknown.metadata["count"] >= 1
    assert Enum.all?(unknown.metadata["sample_keys"], &is_binary/1)

    fixture = File.read!(fixture_path())

    assert {:ok, _token_set, _diagnostics} =
             AutomaticCSS.from_json(fixture, strict: true, profile: :hero_foundation)

    missing_required = Map.delete(minimal_settings(), "color-primary")

    assert {:error, diagnostics} =
             AutomaticCSS.normalize(missing_required, strict: true, profile: :hero_foundation)

    assert Enum.any?(diagnostics, &(&1.code == "tokens.required.missing"))

    missing_text = Map.delete(minimal_settings(), "text-dark")

    assert {:error, diagnostics} =
             AutomaticCSS.normalize(missing_text,
               strict: true,
               required_paths: ["color.text.dark"]
             )

    assert Enum.any?(diagnostics, &(&1.code == "tokens.required.missing"))

    fixture_settings = Jason.decode!(fixture)
    unrelated_removed = Map.delete(fixture_settings, "option-width")

    assert {:ok, _token_set, _diagnostics} =
             AutomaticCSS.normalize(unrelated_removed, strict: true, profile: :hero_foundation)

    unrelated_mapped_removed = Map.delete(fixture_settings, "text-dark")

    assert {:ok, _token_set, _diagnostics} =
             AutomaticCSS.normalize(unrelated_mapped_removed,
               strict: true,
               profile: :hero_foundation
             )
  end

  test "hero_foundation requires every proven Hero semantic dependency" do
    cases = [
      {"text-light", "color.text.light"},
      {"bg-ultra-dark", "color.background.ultra_dark"},
      {"bg-ultra-dark-text", "color.background.ultra_dark.text"},
      {"bg-ultra-dark-heading", "color.background.ultra_dark.heading"},
      {"primary-outline-btn-text", "button.primary.outline.text"},
      {"btn-border-width", "button.primary.border_width"},
      {"btn-border-style", "button.primary.border_style"}
    ]

    for {source_key, required_path} <- cases do
      assert {:error, diagnostics} =
               AutomaticCSS.normalize(Map.delete(fixture_settings(), source_key),
                 strict: true,
                 profile: :hero_foundation
               ),
             source_key

      assert Enum.any?(diagnostics, fn diagnostic ->
               diagnostic.code == "tokens.required.missing" and
                 diagnostic.path == required_path
             end),
             source_key
    end
  end

  test "hero_foundation does not include undocumented generated transparency variables" do
    assert {:ok, token_set, _diagnostics} =
             AutomaticCSS.normalize(fixture_settings(),
               strict: true,
               profile: :hero_foundation
             )

    required_paths = AutomaticCSS.required_paths(:hero_foundation)

    refute "--neutral-ultra-dark-trans-60" in required_paths
    refute "color.neutral.ultra_dark.alpha_60" in required_paths
    refute Map.has_key?(token_set.tokens, "color.neutral.ultra_dark.alpha_60")

    refute Enum.any?(Normalizer.mapping(), fn entry ->
             entry.path == "color.neutral.ultra_dark.alpha_60" or
               "--neutral-ultra-dark-trans-60" in entry.source_keys
           end)
  end

  test "does not let explicit required paths bypass a named profile" do
    assert {:error, diagnostics} =
             AutomaticCSS.normalize(minimal_settings(),
               strict: true,
               profile: :hero_foundation,
               required_paths: []
             )

    assert Enum.any?(diagnostics, &(&1.code == "tokens.required.conflict"))
  end

  test "does not resolve an unrelated CSS variable against a proven target" do
    settings = Map.put(minimal_settings(), "btn-primary-bg", "var(--unrelated)")

    assert {:ok, token_set, diagnostics} = AutomaticCSS.normalize(settings)
    token = token_set.tokens["button.primary.background"]
    assert token.resolution_status == :unresolved
    assert token.resolved_value == nil

    assert %{"source_key" => "btn-primary-bg"} =
             authority(token, "--btn-background", "source_output_alias")

    refute Enum.any?(token.metadata["variable_authorities"], fn record ->
             record["kind"] == "source_reference" and record["variable"] == "--unrelated"
           end)

    assert Enum.any?(diagnostics, &(&1.path == "button.primary.background"))

    assert {:error, strict_diagnostics} =
             AutomaticCSS.normalize(settings, strict: true, profile: :hero_foundation)

    assert Enum.any?(strict_diagnostics, fn diagnostic ->
             diagnostic.code == "tokens.required.missing" and
               diagnostic.path == "button.primary.background"
           end)
  end

  test "does not accept unsupported direct color hex lengths" do
    for invalid_color <- ["#12345", "#1234567"] do
      settings = Map.put(minimal_settings(), "color-primary", invalid_color)

      assert {:ok, token_set, diagnostics} = AutomaticCSS.normalize(settings)
      assert token_set.tokens["color.primary"].resolution_status == :unresolved

      assert Enum.any?(diagnostics, fn diagnostic ->
               diagnostic.code == "acss.value.unresolved" and
                 diagnostic.path == "color.primary"
             end)
    end
  end

  test "records proven breakpoints and never invents generic thresholds" do
    assert {:ok, token_set, _diagnostics} =
             AutomaticCSS.normalize(
               Map.put(minimal_settings(), "auto-staggered-grid-breakpoint", 992)
             )

    assert token_set.tokens["layout.breakpoint.auto_grid"].resolved_value == "992px"

    assert {:ok, token_set, _diagnostics} = AutomaticCSS.normalize(minimal_settings())
    refute Map.has_key?(token_set.tokens, "layout.breakpoint.tablet")
    refute Map.has_key?(token_set.tokens, "layout.breakpoint.mobile")
  end

  test "normalization and serialization are deterministic and do not create atoms from source keys" do
    settings = Map.put(minimal_settings(), "measured-untrusted-key-9931", "value")
    reversed = Map.new(Enum.reverse(Map.to_list(settings)))

    warmup_settings = Map.put(minimal_settings(), "warmup-untrusted-key-9930", "value")
    assert {:ok, _warmup_tokens, _warmup_diagnostics} = AutomaticCSS.normalize(warmup_settings)

    atom_count_before = :erlang.system_info(:atom_count)

    assert {:ok, first, first_diagnostics} = AutomaticCSS.normalize(settings)
    assert {:ok, second, second_diagnostics} = AutomaticCSS.normalize(reversed)
    atom_count_after = :erlang.system_info(:atom_count)

    assert first == second
    assert first_diagnostics == second_diagnostics
    assert Tokens.encode!(first) == Tokens.encode!(second)
    assert atom_count_after == atom_count_before
  end

  test "normalizes the complete approved fixture into the versioned token vocabulary" do
    assert {:ok, token_set, diagnostics} =
             AutomaticCSS.from_file(fixture_path(),
               strict: true,
               profile: :hero_foundation,
               source_version: "4.0.1",
               source_version_status: "fixture_reference"
             )

    assert map_size(token_set.tokens) == length(Normalizer.mapping(fixture_settings()))
    assert map_size(token_set.tokens) == 101

    assert Enum.frequencies_by(token_set.tokens, fn {_path, token} -> token.category end) == %{
             button: 21,
             color: 27,
             icon: 24,
             layout: 3,
             radius: 1,
             spacing: 15,
             typography: 10
           }

    required_paths = AutomaticCSS.required_paths(:hero_foundation)
    assert length(required_paths) == 44

    assert Enum.all?(required_paths, fn path ->
             token_set.tokens[path].resolution_status == :resolved
           end)

    assert Enum.all?(Map.keys(token_set.tokens), &String.contains?(&1, "."))
    refute Map.has_key?(token_set.tokens, "color-primary")
    assert diagnostics == token_set.diagnostics
  end

  test "retains fixture source-version evidence and resolves the BW foundation" do
    assert {:ok, token_set, diagnostics} =
             AutomaticCSS.from_file(fixture_path(),
               source_version: "4.0.1",
               source_version_status: "fixture_reference"
             )

    assert token_set.source_metadata["source_version"] == "4.0.1"
    assert token_set.source_metadata["export_version"] == nil
    assert token_set.source_metadata["source_version_status"] == "fixture_reference"

    assert token_set.tokens["color.black"].resolved_value == "light-dark(#000, #fff)"
    assert token_set.tokens["color.white"].resolved_value == "light-dark(#fff, #000)"
    assert token_set.tokens["color.text.dark"].source_expression == "var(--black)"
    assert token_set.tokens["color.text.dark"].references == ["color.black"]
    assert token_set.tokens["color.text.dark"].resolution_status == :resolved
    assert token_set.tokens["color.text.light"].source_expression == "var(--white)"
    assert token_set.tokens["color.text.light"].references == ["color.white"]
    assert token_set.tokens["color.text.light"].resolution_status == :resolved
    assert token_set.tokens["color.background.ultra_dark.text"].references == ["color.text.light"]

    assert token_set.tokens["color.background.ultra_dark.heading"].references == [
             "color.text.light"
           ]

    unknown = Enum.find(diagnostics, &(&1.code == "acss.setting.unknown"))
    assert unknown.metadata["count"] > 0

    recognized_keys =
      Normalizer.source_keys()
      |> Kernel.++(["option-icons"] ++ IconTokens.omitted_source_keys())
      |> MapSet.new()

    expected_unknown_count =
      fixture_settings()
      |> Map.keys()
      |> Enum.reject(&MapSet.member?(recognized_keys, &1))
      |> length()

    assert unknown.metadata["count"] == expected_unknown_count

    assert Enum.all?(unknown.metadata["sample_keys"], &is_binary/1)
    refute Map.has_key?(token_set.tokens, "overlay.background")
    refute Map.has_key?(token_set.tokens, "layout.breakpoint.tablet")
    refute Map.has_key?(token_set.tokens, "layout.breakpoint.mobile")
    assert token_set.tokens["layout.breakpoint.auto_grid"].resolved_value == "992px"
  end

  defp d0e2_text_scale_settings(overrides \\ %{}) do
    minimal_settings()
    |> Map.merge(%{
      "base-text-mob" => 16,
      "base-text-desk" => 18,
      "mob-text-scale" => 1.2,
      "text-scale" => 1.333,
      "vp-min" => 360,
      "vp-max" => 1366
    })
    |> Map.merge(overrides)
  end

  defp text_s_token(token_set) do
    token_set.tokens["typography.body.scale.small"]
  end

  describe "typography.body.scale.small (text-s)" do
    test "optional override source keys are included in Normalizer.source_keys/0" do
      keys = Normalizer.source_keys()
      assert "text-s-min" in keys
      assert "text-s-max" in keys
    end

    test "exists with acss.clamp recipe, text-s variable, and scale_power -1 defaults" do
      assert {:ok, token_set, _diagnostics} = AutomaticCSS.normalize(d0e2_text_scale_settings())
      token = text_s_token(token_set)

      assert token.resolution_status == :resolved
      assert token.value["type"] == "derived"
      assert token.value["recipe"] == "acss.clamp"
      assert token.value["variable"] == "text-s"
      assert token.value["inputs"]["scale_power"] == -1

      inputs = token.value["inputs"]

      assert inputs["mobile_base"] == 16.0
      assert inputs["desktop_base"] == 18.0
      assert inputs["mobile_scale"] == 1.2
      assert inputs["desktop_scale"] == 1.333
      assert inputs["calculation_group"] == "text"
      refute Map.has_key?(inputs, "mobile_endpoint_override_px")
      refute Map.has_key?(inputs, "desktop_endpoint_override_px")

      assert token.metadata["css_expression"] ==
               FluidClamp.from_px_pair(16 / 1.2, 18 / 1.333, 360, 1366)

      assert authority(token, "--text-s", "source_output_alias") == %{
               "variable" => "--text-s",
               "kind" => "source_output_alias",
               "authority_id" => "automatic-css-4.0.1:calculated-variable-group:text:text-s",
               "source_key" => nil,
               "source_version" => "4.0.1"
             }

      assert {:ok, index} = VariableAuthority.build(token_set)

      assert %{state: :unique_candidate, candidates: [%{token_path: path}]} =
               VariableAuthority.resolve(index, "--text-s")

      assert path == "typography.body.scale.small"
    end

    test "D0E2 published endpoint overrides produce the frozen clamp expression" do
      settings =
        d0e2_text_scale_settings(%{
          "text-s-min" => 14,
          "text-s-max" => 15
        })

      assert {:ok, token_set, _diagnostics} = AutomaticCSS.normalize(settings)
      token = text_s_token(token_set)

      assert token.metadata["css_expression"] ==
               "clamp(0.875rem, calc(0.0994035785vw + 0.8526341948rem), 0.9375rem)"

      assert token.value["inputs"]["mobile_endpoint_override_px"] == 14.0
      assert token.value["inputs"]["desktop_endpoint_override_px"] == 15.0
    end

    test "mobile-only override keeps default desktop endpoint" do
      assert {:ok, token_set, _} =
               AutomaticCSS.normalize(d0e2_text_scale_settings(%{"text-s-min" => 14}))

      token = text_s_token(token_set)

      assert token.value["inputs"]["mobile_endpoint_override_px"] == 14.0
      refute Map.has_key?(token.value["inputs"], "desktop_endpoint_override_px")

      assert token.metadata["css_expression"] ==
               FluidClamp.from_px_pair(14, 18 / 1.333, 360, 1366)
    end

    test "desktop-only override keeps default mobile endpoint" do
      assert {:ok, token_set, _} =
               AutomaticCSS.normalize(d0e2_text_scale_settings(%{"text-s-max" => 15}))

      token = text_s_token(token_set)

      assert token.value["inputs"]["desktop_endpoint_override_px"] == 15.0
      refute Map.has_key?(token.value["inputs"], "mobile_endpoint_override_px")

      assert token.metadata["css_expression"] ==
               FluidClamp.from_px_pair(16 / 1.2, 15, 360, 1366)
    end

    test "present numeric zero is not treated as absent" do
      assert {:ok, token_set, _} =
               AutomaticCSS.normalize(d0e2_text_scale_settings(%{"text-s-min" => 0}))

      token = text_s_token(token_set)
      assert token.value["inputs"]["mobile_endpoint_override_px"] == 0.0
      assert token.resolution_status == :resolved
    end

    test "numeric string overrides fail closed with diagnostics" do
      for {key, value} <- [{"text-s-min", "14"}, {"text-s-max", "15.0"}, {"text-s-min", " 14 "}] do
        assert {:ok, token_set, diagnostics} =
                 AutomaticCSS.normalize(d0e2_text_scale_settings(%{key => value}))

        token = text_s_token(token_set)
        assert token.resolution_status == :unresolved

        assert Enum.any?(diagnostics, fn diagnostic ->
                 diagnostic.path == "typography.body.scale.small" and
                   diagnostic.code == "acss.value.unresolved"
               end)
      end
    end

    test "malformed present overrides fail closed with diagnostics" do
      for {key, value} <- [{"text-s-min", "bad"}, {"text-s-max", "bad"}] do
        assert {:ok, token_set, diagnostics} =
                 AutomaticCSS.normalize(d0e2_text_scale_settings(%{key => value}))

        token = text_s_token(token_set)
        assert token.resolution_status == :unresolved

        assert Enum.any?(diagnostics, fn diagnostic ->
                 diagnostic.path == "typography.body.scale.small" and
                   diagnostic.code == "acss.value.unresolved"
               end)
      end
    end
  end

  test "FluidClamp text-m and text-l regressions stay unchanged" do
    inputs = %{
      "mobile_base" => 16.0,
      "desktop_base" => 18.0,
      "mobile_scale" => 1.2,
      "desktop_scale" => 1.333,
      "viewport_min" => 360.0,
      "viewport_max" => 1366.0,
      "calculation_group" => "text"
    }

    assert FluidClamp.css_expression(%{
             "recipe" => "acss.clamp",
             "variable" => "text-m",
             "inputs" => inputs
           }) == FluidClamp.from_px_pair(16, 18, 360, 1366)

    assert FluidClamp.css_expression(%{
             "recipe" => "acss.clamp",
             "variable" => "text-l",
             "inputs" => inputs
           }) == FluidClamp.from_px_pair(16 * 1.2, 18 * 1.333, 360, 1366)
  end

  test "serializes the complete fixture deterministically across source map orders" do
    settings = Jason.decode!(File.read!(fixture_path()))
    reversed = Map.new(Enum.reverse(Map.to_list(settings)))

    assert {:ok, first, first_diagnostics} = AutomaticCSS.normalize(settings)
    assert {:ok, second, second_diagnostics} = AutomaticCSS.normalize(reversed)

    assert first == second
    assert first_diagnostics == second_diagnostics
    assert Tokens.encode!(first) == Tokens.encode!(second)
  end
end
