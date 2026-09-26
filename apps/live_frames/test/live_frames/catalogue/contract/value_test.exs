defmodule LiveFrames.Catalogue.Contract.ValueTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Catalogue.CanonicalJSON
  alias LiveFrames.Catalogue.Contract.Value

  test "preserves null, booleans, and exact Unicode strings" do
    assert_normalized(nil, nil)
    assert_normalized(true, true)
    assert_normalized(false, false)
    assert_normalized("héllo 🌍", "héllo 🌍")

    composed = "é"
    decomposed = "é"

    assert_normalized(composed, composed)
    assert_normalized(decomposed, decomposed)
    refute Value.normalize(composed) == Value.normalize(decomposed)
  end

  test "encodes integers as canonical decimal strings without a safe-integer limit" do
    large = 12_345_678_901_234_567_890_123_456_789_012_345_678_901_234_567_890

    for {value, decimal} <- [
          {0, "0"},
          {1, "1"},
          {-1, "-1"},
          {9_007_199_254_740_992, "9007199254740992"},
          {large, "12345678901234567890123456789012345678901234567890"},
          {-large, "-12345678901234567890123456789012345678901234567890"}
        ] do
      assert_normalized(value, tagged_integer(decimal))
    end
  end

  test "encodes floats as exact binary64 bits and preserves negative zero" do
    assert_normalized(0.0, tagged_float("0000000000000000"))
    assert_normalized(-0.0, tagged_float("8000000000000000"))
    assert_normalized(1.5, tagged_float("3ff8000000000000"))

    refute Value.normalize(0.0) == Value.normalize(-0.0)
  end

  test "tags existing atoms while leaving nil and booleans as JSON scalars" do
    assert_normalized(:existing_atom, %{"$type" => "atom", "value" => "existing_atom"})
    assert_normalized(nil, nil)
    assert_normalized(true, true)
    assert_normalized(false, false)
  end

  test "normalizes proper lists recursively and preserves their order" do
    assert_normalized(
      [1, [:nested, "value"], false],
      %{
        "$type" => "list",
        "items" => [
          tagged_integer("1"),
          %{
            "$type" => "list",
            "items" => [%{"$type" => "atom", "value" => "nested"}, "value"]
          },
          false
        ]
      }
    )
  end

  test "rejects improper lists with a stable item path" do
    assert_error([1, 2 | :tail], "catalogue.contract.value.unsupported", "$.items[2]")
  end

  test "tags tuples and keeps them distinct from lists" do
    assert_normalized(
      {1, :two},
      %{
        "$type" => "tuple",
        "items" => [tagged_integer("1"), %{"$type" => "atom", "value" => "two"}]
      }
    )

    assert {:ok, list_value} = Value.normalize([1, 2])
    assert {:ok, tuple_value} = Value.normalize({1, 2})
    refute list_value == tuple_value
  end

  test "normalizes ascending, descending, and stepped finite ranges without expansion" do
    assert_normalized(1..5, tagged_range(1, 5, 1))
    assert_normalized(Range.new(5, 1, -1), tagged_range(5, 1, -1))
    assert_normalized(Range.new(2, 10, 4), tagged_range(2, 10, 4))
  end

  test "rejects malformed ranges" do
    assert_error(
      %Range{first: 1, last: 3, step: 0},
      "catalogue.contract.value.invalid_range"
    )

    assert_error(
      struct(Range, first: 1, last: :three, step: 1),
      "catalogue.contract.value.invalid_range"
    )

    assert_error(
      %{__struct__: Range, first: 1, last: 3},
      "catalogue.contract.value.invalid_range"
    )

    assert_error(
      %{__struct__: Range, first: 1, last: 3, step: 1, extra: :field},
      "catalogue.contract.value.invalid_range"
    )
  end

  test "normalizes mixed map key types and orders entries by canonical key bytes" do
    entries = [
      {"string", :string_value},
      {1, [2, :three]},
      {:atom_key, {3, 4}},
      {{:tuple_key, 5}, "tuple value"},
      {[:list_key, 6], :list_value}
    ]

    assert {:ok, %{"$type" => "map", "entries" => normalized_entries}} =
             Value.normalize(Map.new(entries))

    normalized_keys = Enum.map(normalized_entries, & &1["key"])
    expected_keys = Enum.map(entries, fn {key, _value} -> elem(Value.normalize(key), 1) end)

    assert Enum.sort_by(normalized_keys, &canonical_bytes!/1) ==
             Enum.sort_by(expected_keys, &canonical_bytes!/1)

    key_bytes = Enum.map(normalized_entries, &canonical_bytes!(&1["key"]))
    assert key_bytes == Enum.sort(key_bytes)

    assert Enum.any?(normalized_entries, fn entry ->
             entry["value"] == %{
               "$type" => "list",
               "items" => [tagged_integer("2"), atom("three")]
             }
           end)
  end

  test "produces the same normalized map regardless of its insertion order" do
    entries = [{"z", [3, :three]}, {2, {"two"}}, {:one, true}]
    first = Map.new(entries)
    second = Map.new(Enum.reverse(entries))

    assert Value.normalize(first) == Value.normalize(second)
  end

  test "chooses map value failures in canonical key order" do
    entries = [{"z", fn -> :unsupported end}, {"a", make_ref()}]
    first = Map.new(entries)
    second = Map.new(Enum.reverse(entries))

    assert {:error, [diagnostic]} = result = Value.normalize(first)
    assert result == Value.normalize(second)
    assert diagnostic.code == "catalogue.contract.value.unsupported"
    assert diagnostic.path == "$.entries[0].value"
  end

  test "chooses map key failures deterministically" do
    invalid_utf8 = <<0xFF>>
    unsupported_key = fn -> :unsupported end
    first = Map.new([{invalid_utf8, :value}, {unsupported_key, :value}])
    second = Map.new([{unsupported_key, :value}, {invalid_utf8, :value}])

    assert {:error, [diagnostic]} = result = Value.normalize(first)
    assert result == Value.normalize(second)
    assert diagnostic.code == "catalogue.contract.value.invalid_string"
    assert diagnostic.path == "$.entries.key"
  end

  test "normalizes a full nested value recursively" do
    input = %{
      {:lookup, :hero} => [
        9_007_199_254_740_992,
        1.5,
        :primary,
        Range.new(2, 10, 4)
      ]
    }

    expected = %{
      "$type" => "map",
      "entries" => [
        %{
          "key" => %{
            "$type" => "tuple",
            "items" => [atom("lookup"), atom("hero")]
          },
          "value" => %{
            "$type" => "list",
            "items" => [
              tagged_integer("9007199254740992"),
              tagged_float("3ff8000000000000"),
              atom("primary"),
              tagged_range(2, 10, 4)
            ]
          }
        }
      ]
    }

    assert_normalized(input, expected)
  end

  test "rejects invalid UTF-8 and Unicode noncharacters" do
    for value <- [<<0xFF>>, <<0xED, 0xA0, 0x80>>, <<0xFDD0::utf8>>] do
      assert_error(value, "catalogue.contract.value.invalid_string")
    end
  end

  test "rejects functions, references, and non-Range structs" do
    for value <- [fn -> :unsupported end, make_ref(), Date.new!(2020, 1, 1)] do
      assert_error(value, "catalogue.contract.value.unsupported")
    end
  end

  defp assert_normalized(value, expected) do
    assert {:ok, ^expected} = Value.normalize(value)
    assert {:ok, _canonical_bytes} = CanonicalJSON.encode(expected)
  end

  defp assert_error(value, code, path \\ "$") do
    assert {:error, [diagnostic]} = Value.normalize(value)
    assert diagnostic.code == code
    assert diagnostic.path == path
    assert is_binary(diagnostic.message)
  end

  defp canonical_bytes!(value) do
    {:ok, bytes} = CanonicalJSON.encode(value)
    bytes
  end

  defp tagged_integer(decimal), do: %{"$type" => "integer", "value" => decimal}

  defp tagged_float(bits), do: %{"$type" => "float64", "bits" => bits}

  defp tagged_range(first, last, step) do
    %{
      "$type" => "range",
      "first" => tagged_integer(Integer.to_string(first)),
      "last" => tagged_integer(Integer.to_string(last)),
      "step" => tagged_integer(Integer.to_string(step))
    }
  end

  defp atom(name), do: %{"$type" => "atom", "value" => name}
end
