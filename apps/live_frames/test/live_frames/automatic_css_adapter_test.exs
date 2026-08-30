defmodule LiveFrames.AutomaticCSSAdapterTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS

  test "recognizes and normalizes the approved fixture through from_file" do
    path = Path.expand("../../../../fixtures/automatic_css/acss_settings.json", __DIR__)

    assert {:ok, token_set, diagnostics} = AutomaticCSS.from_file(path)
    assert token_set.token_set_version == "1.0.0"
    assert is_list(diagnostics)
    assert token_set.source_metadata["source_shape"] == "flat_settings_map"
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
end
