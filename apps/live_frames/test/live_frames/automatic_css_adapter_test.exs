defmodule LiveFrames.AutomaticCSSAdapterTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.AutomaticCSS.Normalizer
  alias LiveFrames.Tokens

  defp fixture_path do
    Path.expand("../../../../fixtures/automatic_css/acss_settings.json", __DIR__)
  end

  defp fixture_settings do
    Jason.decode!(File.read!(fixture_path()))
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
    settings = Map.put(minimal_settings(), "arbitrary-untrusted-key-9931", "value")
    reversed = Map.new(Enum.reverse(Map.to_list(settings)))
    _ = AutomaticCSS.normalize(minimal_settings())
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

    assert map_size(token_set.tokens) == length(Normalizer.mapping())
    assert map_size(token_set.tokens) == 71

    assert Enum.frequencies_by(token_set.tokens, fn {_path, token} -> token.category end) == %{
             button: 21,
             color: 27,
             layout: 3,
             radius: 1,
             spacing: 11,
             typography: 8
           }

    required_paths = AutomaticCSS.required_paths(:hero_foundation)
    assert length(required_paths) == 43

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

    assert unknown.metadata["count"] ==
             token_set.source_metadata["source_key_count"] - length(Normalizer.source_keys())

    assert Enum.all?(unknown.metadata["sample_keys"], &is_binary/1)
    refute Map.has_key?(token_set.tokens, "overlay.background")
    refute Map.has_key?(token_set.tokens, "layout.breakpoint.tablet")
    refute Map.has_key?(token_set.tokens, "layout.breakpoint.mobile")
    assert token_set.tokens["layout.breakpoint.auto_grid"].resolved_value == "992px"
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
