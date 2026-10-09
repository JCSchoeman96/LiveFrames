defmodule LiveFrames.CanonicalJSONTest do
  use ExUnit.Case, async: true

  alias LiveFrames.CanonicalJSON

  test "encodes accepted scalar and collection values" do
    assert {:ok, "null"} = CanonicalJSON.encode(nil)
    assert {:ok, "true"} = CanonicalJSON.encode(true)
    assert {:ok, "false"} = CanonicalJSON.encode(false)
    assert {:ok, "-9007199254740991"} = CanonicalJSON.encode(-9_007_199_254_740_991)
    assert {:ok, "9007199254740991"} = CanonicalJSON.encode(9_007_199_254_740_991)
    assert {:ok, "\"é\""} = CanonicalJSON.encode("é")
    assert {:ok, "[null,false,true,0,\"ok\"]"} = CanonicalJSON.encode([nil, false, true, 0, "ok"])

    assert {:ok, "{\"a\":[{\"x\":1}],\"z\":0}"} =
             CanonicalJSON.encode(%{"z" => 0, "a" => [%{"x" => 1}]})
  end

  test "emits established canonical bytes for JCS fixtures" do
    value = %{
      "text" => "quote\" slash\\ tab\t newline\n carriage\r control " <> <<1>>,
      "composed" => "é",
      "decomposed" => "é"
    }

    assert {:ok,
            "{\"composed\":\"é\",\"decomposed\":\"é\",\"text\":\"quote\\\" slash\\\\ tab\\t newline\\n carriage\\r control \\u0001\"}"} =
             CanonicalJSON.encode(value)

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

    assert {:ok,
            "{\"attrs\":[],\"capabilities\":[],\"component\":{\"function\":\"hero\",\"module\":\"LiveFrames.Components.Sections.Hero\"},\"css_theme_contract\":[],\"format\":\"lf-contract-v1\",\"slots\":[]}"} =
             CanonicalJSON.encode(contract)
  end

  test "orders properties by RFC 8785 UTF-16 ordering" do
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

  test "does not normalize composed and decomposed Unicode" do
    assert {:ok, composed} = CanonicalJSON.encode(%{"value" => "é"})
    assert {:ok, decomposed} = CanonicalJSON.encode(%{"value" => "é"})

    assert composed == "{\"value\":\"é\"}"
    assert decomposed == "{\"value\":\"é\"}"
    refute composed == decomposed
  end

  test "returns neutral reasons for unsupported values" do
    float_values = [0.0, -0.0, 1.5, 1.0e23]

    for value <- float_values do
      assert {:error, %{reason: :invalid_value, path: "$"}} = CanonicalJSON.encode(value)
    end

    values = [
      {:atom, :invalid_value, "$"},
      {{:tuple, 1}, :invalid_value, "$"},
      {%URI{}, :invalid_value, "$"},
      {[1 | :tail], :invalid_value, "$[1]"},
      {9_007_199_254_740_992, :invalid_value, "$"},
      {<<0xFF>>, :invalid_string, "$"},
      {<<0xFDD0::utf8>>, :invalid_string, "$"},
      {%{1 => "value"}, :invalid_object_key, "$"},
      {%{<<0xFF>> => "value"}, :invalid_object_key, "$"}
    ]

    for {value, reason, path} <- values do
      assert {:error, %{reason: ^reason, path: ^path}} = CanonicalJSON.encode(value)
    end
  end

  test "rejects invalid object keys before validating their values" do
    assert {:error, %{reason: :invalid_object_key, path: "$"}} =
             CanonicalJSON.encode(%{1 => 1.5})
  end

  test "reports nested value errors with list indexes" do
    assert {:error, %{reason: :invalid_value, path: "$.nested[1]"}} =
             CanonicalJSON.encode(%{"nested" => [nil, 1.5]})
  end

  test "selects map value failures independently of insertion order" do
    first = Map.new([{"z", 1.5}, {"a", :unsupported}])
    second = Map.new([{"a", :unsupported}, {"z", 1.5}])

    expected = {:error, %{reason: :invalid_value, path: "$.a"}}
    assert CanonicalJSON.encode(first) == expected
    assert CanonicalJSON.encode(second) == expected

    mixed_first = Map.new([{"x", <<0xFF>>}, {"a", :unsupported}])
    mixed_second = Map.new([{"a", :unsupported}, {"x", <<0xFF>>}])

    assert CanonicalJSON.encode(mixed_first) ==
             {:error, %{reason: :invalid_value, path: "$.a"}}

    assert CanonicalJSON.encode(mixed_second) ==
             {:error, %{reason: :invalid_value, path: "$.a"}}
  end

  test "returns identical bytes for maps with different insertion order" do
    first = Map.new([{"b", 2}, {"a", 1}])
    second = Map.new([{"a", 1}, {"b", 2}])

    assert CanonicalJSON.encode(first) == {:ok, "{\"a\":1,\"b\":2}"}
    assert CanonicalJSON.encode(second) == {:ok, "{\"a\":1,\"b\":2}"}
  end
end
