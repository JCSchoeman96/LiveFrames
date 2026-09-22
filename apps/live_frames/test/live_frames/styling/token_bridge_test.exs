defmodule LiveFrames.Styling.TokenBridgeTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Styling.TokenBridge
  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet

  @fixture Path.expand("../../../../../fixtures/automatic_css/acss_settings.json", __DIR__)
  @mapping Path.expand("../../../priv/token_maps/native_hero_v1.json", __DIR__)
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

  test "rejects unsafe css values" do
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
        %{"token_set_path" => "color.background.ultra_dark", "css_variable" => "--lf-x"}
      ])

    assert {:error, {:unresolved_token, "color.background.ultra_dark", :unresolved}} =
             TokenBridge.generate(token_set, mapping)
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
    mapping = TokenBridge.load_mapping!(@mapping)
    token_set = hero_token_set()

    assert {:ok, generated} = TokenBridge.generate(token_set, mapping)
    assert File.read!(@committed_theme) == generated
  end
end
