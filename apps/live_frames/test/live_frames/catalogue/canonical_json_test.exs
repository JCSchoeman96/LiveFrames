defmodule LiveFrames.Catalogue.CanonicalJSONTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Catalogue.CanonicalJSON

  test "encodes objects deterministically and sorts nested objects recursively" do
    first = Map.new([{"b", 2}, {"a", 1}])
    second = Map.new([{"a", 1}, {"b", 2}])

    assert {:ok, "{\"a\":1,\"b\":2}"} = CanonicalJSON.encode(first)
    assert {:ok, bytes} = CanonicalJSON.encode(second)
    assert bytes == "{\"a\":1,\"b\":2}"
    assert {:ok, "[null,false,true,0,\"ok\"]"} = CanonicalJSON.encode([nil, false, true, 0, "ok"])

    nested = %{
      "z" => 0,
      "a" => [%{"b" => 2, "a" => 1}, %{"x" => 3}],
      "m" => [2, 1]
    }

    assert {:ok, "{\"a\":[{\"a\":1,\"b\":2},{\"x\":3}],\"m\":[2,1],\"z\":0}"} =
             CanonicalJSON.encode(nested)
  end

  test "uses RFC 8785 UTF-16 property ordering" do
    input = %{
      "€" => "Euro Sign",
      "\r" => "Carriage Return",
      "דּ" => "Hebrew Letter Dalet With Dagesh",
      "1" => "One",
      "😀" => "Emoji: Grinning Face",
      <<0x80::utf8>> => "Control",
      "ö" => "Latin Small Letter O With Diaeresis"
    }

    expected =
      ~S({"\r":"Carriage Return","1":"One","":"Control","ö":"Latin Small Letter O With Diaeresis","€":"Euro Sign","😀":"Emoji: Grinning Face","דּ":"Hebrew Letter Dalet With Dagesh"})

    assert {:ok, ^expected} = CanonicalJSON.encode(input)
  end

  test "preserves Unicode strings without normalization" do
    composed = %{"value" => "é"}
    decomposed = %{"value" => "é"}

    assert {:ok, composed_bytes} = CanonicalJSON.encode(composed)
    assert {:ok, decomposed_bytes} = CanonicalJSON.encode(decomposed)
    assert composed_bytes == "{\"value\":\"é\"}"
    assert decomposed_bytes == "{\"value\":\"é\"}"
    refute composed_bytes == decomposed_bytes
  end

  test "uses canonical JSON escaping without whitespace" do
    value = "quote\" slash\\ tab\t newline\n carriage\r control " <> <<1>>
    expected = ~S({"text":"quote\" slash\\ tab\t newline\n carriage\r control \u0001"})

    assert {:ok, ^expected} = CanonicalJSON.encode(%{"text" => value})
  end

  test "encodes the normalized lf-contract-v1 document shape" do
    contract = %{
      "format" => "lf-contract-v1",
      "component" => %{
        "module" => "LiveFrames.Components.Sections.Hero",
        "function" => "hero"
      },
      "attrs" => [],
      "slots" => [],
      "capabilities" => [],
      "css_theme_contract" => []
    }

    expected =
      "{\"attrs\":[],\"capabilities\":[],\"component\":{\"function\":\"hero\",\"module\":\"LiveFrames.Components.Sections.Hero\"},\"css_theme_contract\":[],\"format\":\"lf-contract-v1\",\"slots\":[]}"

    assert {:ok, ^expected} = CanonicalJSON.encode(contract)
  end

  test "treats the tagged float64 representation as ordinary strings and maps" do
    input = %{"$type" => "float64", "bits" => "8000000000000000"}

    assert {:ok, "{\"$type\":\"float64\",\"bits\":\"8000000000000000\"}"} =
             CanonicalJSON.encode(input)
  end

  test "rejects raw floats at every depth with stable diagnostics" do
    for value <- [0.0, -0.0, 1.5, 1.0e23] do
      assert_invalid(value, "catalogue.canonical_json.invalid_value")
    end

    assert_invalid(
      %{"nested" => [nil, 1.5]},
      "catalogue.canonical_json.invalid_value",
      "$.nested[1]"
    )

    first = Map.new([{"z", 1.5}, {"a", :unsupported}])
    second = Map.new([{"a", :unsupported}, {"z", 1.5}])

    assert {:error, [diagnostic]} = first_error = CanonicalJSON.encode(first)
    assert first_error == CanonicalJSON.encode(second)
    assert diagnostic.path == "$.a"
  end

  test "rejects non-string object keys without coercion" do
    for value <- [%{foo: "bar"}, %{1 => "bar"}] do
      assert_invalid(value, "catalogue.canonical_json.invalid_object_key")
    end
  end

  test "rejects unsupported Elixir terms" do
    for value <- [:some_atom, {:tuple, 1}] do
      assert_invalid(value, "catalogue.canonical_json.invalid_value")
    end
  end

  test "rejects invalid UTF-8 in values and object keys" do
    assert_invalid(%{"value" => <<0xFF>>}, "catalogue.canonical_json.invalid_string", "$.value")

    assert_invalid(
      %{"value" => <<0xED, 0xA0, 0x80>>},
      "catalogue.canonical_json.invalid_string",
      "$.value"
    )

    assert_invalid(
      %{<<0xFF>> => "value"},
      "catalogue.canonical_json.invalid_object_key",
      "$"
    )
  end

  test "rejects Unicode noncharacters" do
    assert_invalid(
      %{"value" => <<0xFDD0::utf8>>},
      "catalogue.canonical_json.invalid_string",
      "$.value"
    )
  end

  test "accepts safe integer bounds and rejects integers outside them" do
    assert {:ok, "-9007199254740991"} = CanonicalJSON.encode(-9_007_199_254_740_991)
    assert {:ok, "9007199254740991"} = CanonicalJSON.encode(9_007_199_254_740_991)

    assert_invalid(-9_007_199_254_740_992, "catalogue.canonical_json.invalid_value")
    assert_invalid(9_007_199_254_740_992, "catalogue.canonical_json.invalid_value")
  end

  defp assert_invalid(value, code, path \\ "$") do
    assert {:error, [diagnostic]} = first = CanonicalJSON.encode(value)
    assert first == CanonicalJSON.encode(value)
    assert diagnostic.code == code
    assert diagnostic.path == path
    assert is_binary(diagnostic.message)
  end
end
