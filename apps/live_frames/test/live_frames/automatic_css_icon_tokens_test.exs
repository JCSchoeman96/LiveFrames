defmodule LiveFrames.AutomaticCSSIconTokensTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.AutomaticCSS.IconTokens
  alias LiveFrames.Adapters.AutomaticCSS.Normalizer
  alias LiveFrames.Tokens

  defp fixture_path do
    Path.expand("../../../../fixtures/automatic_css/acss_settings.json", __DIR__)
  end

  defp fixture_settings do
    Jason.decode!(File.read!(fixture_path()))
  end

  defp icon_paths(token_set) do
    token_set.tokens
    |> Map.keys()
    |> Enum.filter(&String.starts_with?(&1, "icon."))
    |> Enum.sort()
  end

  test "emits proven icon tokens when option-icons is on" do
    assert {:ok, token_set, _} = AutomaticCSS.normalize(fixture_settings())

    assert icon_paths(token_set) == [
             "icon.background",
             "icon.background_hover",
             "icon.border.color",
             "icon.border.color_hover",
             "icon.border.style",
             "icon.border.width",
             "icon.color",
             "icon.color_hover",
             "icon.list.gap",
             "icon.list.icon_size",
             "icon.padding.default",
             "icon.padding.l",
             "icon.padding.m",
             "icon.padding.s",
             "icon.padding.xl",
             "icon.padding.xs",
             "icon.radius",
             "icon.scheme",
             "icon.size.default",
             "icon.size.l",
             "icon.size.m",
             "icon.size.s",
             "icon.size.xl",
             "icon.size.xs"
           ]

    assert token_set.tokens["icon.scheme"].resolved_value == "inherit"
    assert token_set.tokens["icon.size.default"].resolved_value == "32px"
    assert token_set.tokens["icon.padding.default"].resolved_value == ".15em"
    assert token_set.tokens["icon.radius"].references == ["radius.base"]
    assert token_set.tokens["icon.color_hover"].references == ["color.primary"]
    assert token_set.tokens["icon.padding.m"].references == ["icon.padding.default"]
  end

  test "does not emit icon authority when option-icons is off or missing" do
    off = Map.put(fixture_settings(), "option-icons", "off")
    assert {:ok, off_set, _} = AutomaticCSS.normalize(off)
    assert icon_paths(off_set) == []

    missing = Map.delete(fixture_settings(), "option-icons")
    assert {:ok, missing_set, _} = AutomaticCSS.normalize(missing)
    assert icon_paths(missing_set) == []
  end

  test "does not fabricate icon.size.2xl or icon.padding.2xl paths" do
    assert {:ok, token_set, _} = AutomaticCSS.normalize(fixture_settings())
    refute Map.has_key?(token_set.tokens, "icon.size.2xl")
    refute Map.has_key?(token_set.tokens, "icon.padding.2xl")
  end

  test "icon token normalization is deterministic" do
    settings = fixture_settings()
    reversed = Map.new(Enum.reverse(Map.to_list(settings)))

    assert {:ok, first, _} = AutomaticCSS.normalize(settings)
    assert {:ok, second, _} = AutomaticCSS.normalize(reversed)
    assert first == second
    assert Tokens.encode!(first) == Tokens.encode!(second)
  end

  test "hero_foundation profile stays unchanged when icons are enabled" do
    assert {:ok, token_set, diagnostics} =
             AutomaticCSS.from_file(fixture_path(),
               strict: true,
               profile: :hero_foundation,
               source_version: "4.0.1",
               source_version_status: "fixture_reference"
             )

    required_paths = AutomaticCSS.required_paths(:hero_foundation)

    assert Enum.all?(required_paths, fn path ->
             token_set.tokens[path].resolution_status == :resolved
           end)

    refute Enum.any?(required_paths, &String.starts_with?(&1, "icon."))
    assert diagnostics == token_set.diagnostics
  end

  test "IconTokens.entries respects the option gate" do
    assert IconTokens.enabled?(%{"option-icons" => "on"})
    refute IconTokens.enabled?(%{"option-icons" => "off"})
    refute IconTokens.enabled?(%{})

    assert length(IconTokens.entries(%{"option-icons" => "on"})) == 24
    assert IconTokens.entries(%{"option-icons" => "off"}) == []
  end

  test "disabled gate consumes icon settings without unknown-setting noise" do
    settings = Map.put(fixture_settings(), "option-icons", "off")

    assert {:ok, _token_set, diagnostics} = AutomaticCSS.normalize(settings)

    refute Enum.any?(diagnostics, fn diagnostic ->
             diagnostic.code == "acss.setting.unknown" and
               Enum.any?(
                 diagnostic.metadata["sample_keys"] || [],
                 &String.starts_with?(&1, "icon-")
               )
           end)
  end

  test "mapping size includes icon entries only for enabled settings" do
    assert length(Normalizer.mapping(%{})) == 76
    assert length(Normalizer.mapping(fixture_settings())) == 100
  end

  test "gated icon settings are consumed when icons are enabled" do
    entry_keys =
      Normalizer.mapping(fixture_settings())
      |> Enum.flat_map(& &1.source_keys)
      |> Enum.uniq()

    consumed =
      (entry_keys ++ IconTokens.omitted_source_keys() ++ ["option-icons"])
      |> Enum.uniq()
      |> MapSet.new()

    missing =
      IconTokens.source_keys()
      |> Enum.reject(&MapSet.member?(consumed, &1))

    assert missing == []
  end
end
