defmodule LiveFrames.BricksCompoundCssValueTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks.CompoundCssValue
  alias LiveFrames.Adapters.Bricks.CompoundCssValue.Occurrence
  alias LiveFrames.Adapters.Bricks.CompoundCssValue.Parsed

  test "parses a bounded gradient and retains outer function spelling" do
    assert {:ok, parsed} =
             CompoundCssValue.parse("linear-gradient(90deg, transparent 0%, var(--accent) 100%)")

    assert parsed.production == :function_call
    assert parsed.function_name == :linear_gradient

    assert [%{occurrence_index: 0, local_name: "accent", slot_grammar: :gradient_stop_atom}] =
             CompoundCssValue.occurrences(parsed)

    assert {:ok, "linear-gradient(90deg, transparent 0%, rgb(1,2,3) 100%)"} =
             CompoundCssValue.reconstruct(parsed, %{0 => "rgb(1,2,3)"})

    assert {:ok, upper} = CompoundCssValue.parse("LINEAR-GRADIENT(90deg, var(--stop))")

    assert {:ok, "LINEAR-GRADIENT(90deg, 10%)"} =
             CompoundCssValue.reconstruct(upper, %{0 => "10%"})
  end

  test "parses calc references with and without a positive factor" do
    for value <- [
          "calc(var(--space))",
          "calc(var(--space) * .5)",
          "calc(var(--space) * 2.25)",
          "calc(var( \t--space\n) * 2)"
        ] do
      assert {:ok, parsed} = CompoundCssValue.parse(value)
      assert parsed.function_name == :calc

      assert [%{local_name: "space", slot_grammar: :calc_operand}] =
               CompoundCssValue.occurrences(parsed)
    end

    assert {:ok, spaced} = CompoundCssValue.parse("calc(\nvar(--space)\r\n)")
    assert {:ok, "calc(\n2px\r\n)"} = CompoundCssValue.reconstruct(spaced, %{0 => "2px"})
  end

  test "classifies two dimensions and two local references" do
    assert {:ok, multi} = CompoundCssValue.parse("10px 2rem")
    assert multi.production == :multi_token_value
    assert CompoundCssValue.occurrences(multi) == []

    assert {:ok, juxtaposition} = CompoundCssValue.parse("var(--duration) var(--timing)")
    assert juxtaposition.production == :var_reference_with_operation

    assert [
             %{occurrence_index: 0, slot_grammar: :juxtaposition_left_operand},
             %{occurrence_index: 1, slot_grammar: :juxtaposition_right_operand}
           ] =
             CompoundCssValue.occurrences(juxtaposition)

    assert {:ok, spaced} = CompoundCssValue.parse("var( \t--duration)\r\nvar(--timing \f)")

    assert {:ok, "0ms\r\nease-in-out"} =
             CompoundCssValue.reconstruct(spaced, %{0 => "0ms", 1 => "ease-in-out"})
  end

  test "returns no match outside the frozen productions" do
    for value <- [
          "teal",
          "var(--local-space)",
          "radial-gradient(circle, red, blue)",
          "unknown-function(var(--x))",
          "center center",
          "10 20px",
          "10px 2rem 3em",
          "10px + 2px",
          "var(--x) 2px",
          "var(--a) var(--b) var(--c)",
          "var(--a) + var(--b)",
          "var(--a) 2px var(--b)"
        ] do
      assert CompoundCssValue.parse(value) == :no_match, value
    end
  end

  test "reports malformed attempts at allowlisted productions" do
    for value <- [
          "calc(var(--x) + 2px)",
          "calc('x')",
          "calc(var(--x)) extra",
          "calc(var(--x)",
          "calc(foo(var(--x)))",
          "linear-gradient(90, red)",
          "linear-gradient(90deg red)",
          "linear-gradient(90deg, red,,blue)",
          "linear-gradient(90deg, red, foo)",
          "linear-gradient(90deg, red + blue)",
          "linear-gradient(90deg, stop var(--x))",
          "linear-gradient(90deg, var(--x)))",
          "linear-gradient(90deg, #fff)",
          "linear-gradient(90deg, rgb(1,2,3))"
        ] do
      assert CompoundCssValue.parse(value) == {:error, :unsupported_grammar}, value
    end
  end

  test "enforces gradient structure and bounds" do
    assert {:ok, _} = CompoundCssValue.parse("linear-gradient(0deg, transparent, 10%)")
    assert {:ok, _} = CompoundCssValue.parse("linear-gradient(90.5deg, 0% 10%, transparent)")

    for angle <- ["-90deg", "+90deg", "90rad", "90", "90deg red"] do
      assert CompoundCssValue.parse("linear-gradient(#{angle}, red)") ==
               {:error, :unsupported_grammar}
    end

    for value <- ["linear-gradient(90deg)", "linear-gradient(90deg,)"] do
      assert CompoundCssValue.parse(value) == {:error, :unsupported_grammar}
    end

    assert CompoundCssValue.parse("linear-gradient(90deg, red 1% 2% 3% 4%)") ==
             {:error, :resource_limit_exceeded}

    stops = Enum.map_join(1..9, ", ", fn n -> "#{n}%" end)

    assert CompoundCssValue.parse("linear-gradient(90deg, #{stops})") ==
             {:error, :resource_limit_exceeded}
  end

  test "counts a whitespace-spaced gradient var as one stop atom" do
    assert {:ok, parsed} =
             CompoundCssValue.parse("linear-gradient(90deg, var( --accent ) 0% 10%)")

    assert [%{occurrence_index: 0, local_name: "accent"}] =
             CompoundCssValue.occurrences(parsed)

    assert {:ok, "linear-gradient(90deg, rgb(1,2,3) 0% 10%)"} =
             CompoundCssValue.reconstruct(parsed, %{0 => "rgb(1,2,3)"})
  end

  test "enforces calc expression grammar and positive factor predicate" do
    for factor <- ["1", "2.25", ".5"] do
      assert {:ok, _} = CompoundCssValue.parse("calc(var(--x) * #{factor})")
    end

    for factor <- ["0", "-1", ".", "1junk", "1e999"] do
      assert CompoundCssValue.parse("calc(var(--x) * #{factor})") ==
               {:error, :unsupported_grammar}
    end

    for expression <- [
          "var(--x), 2",
          "var(--x) var(--y)",
          "var(--x) + 2",
          "var(--x) - 2",
          "var(--x) / 2",
          "var(--x) * 2 * 3",
          "var(--x) * 2px",
          "var(--x) * (2)"
        ] do
      assert CompoundCssValue.parse("calc(#{expression})") == {:error, :unsupported_grammar}
    end
  end

  test "validates reconstruction slots for every production" do
    assert {:ok, gradient} = CompoundCssValue.parse("linear-gradient(90deg, var(--stop))")

    for atom <- ["transparent", "0%", "10px", "rgb(0,255,2)", "rgba(1,2,3,.5)"] do
      assert {:ok, result} = CompoundCssValue.reconstruct(gradient, %{0 => atom})
      refute result =~ "var("
    end

    for atom <- [
          "rgb(0,0,0)",
          "rgb(255,255,255)",
          "rgba(1,2,3,0)",
          "rgba(1,2,3,1)",
          "rgba(1,2,3,0.5)"
        ] do
      assert {:ok, _} = CompoundCssValue.reconstruct(gradient, %{0 => atom})
    end

    for atom <- [
          "#fff",
          "rgb(256,0,0)",
          "rgb(1.5,0,0)",
          "rgb(0000,0,0)",
          "rgb(0,0,0,0.5)",
          "rgb(1, 0,0)",
          "rgba(0,0,0)",
          "rgba(0,0,0,-.1)",
          "rgba(0,0,0,1.1)",
          "rgba(0,0,0,50%)",
          "rgba(0,0,0,.5/2)",
          "rgba(0,0,0,foo)",
          "rgba(0,0,0,NaN)",
          "rgba(0,0,0,.5  )",
          "-1%",
          "red()"
        ] do
      assert CompoundCssValue.reconstruct(gradient, %{0 => atom}) ==
               {:error, :invalid_slot_terminal}
    end

    assert {:ok, calc} = CompoundCssValue.parse("calc(var(--x))")

    for atom <- ["0", "-2.5", "10px", "2%"] do
      assert {:ok, _} = CompoundCssValue.reconstruct(calc, %{0 => atom})
    end

    assert {:ok, juxtaposition} = CompoundCssValue.parse("var(--duration) var(--timing)")

    for duration <- ["0ms", "250ms", ".5s"] do
      assert {:ok, _} =
               CompoundCssValue.reconstruct(juxtaposition, %{0 => duration, 1 => "ease-in-out"})
    end

    for duration <- ["-1s", "+1s", "1", "1e999"] do
      assert CompoundCssValue.reconstruct(juxtaposition, %{0 => duration, 1 => "ease-in-out"}) ==
               {:error, :invalid_slot_terminal}
    end

    assert CompoundCssValue.reconstruct(juxtaposition, %{0 => "1s", 1 => "ease"}) ==
             {:error, :invalid_slot_terminal}
  end

  test "enforces parser resource bounds at the boundary" do
    max_value = String.duplicate("1", 4090) <> "px 1px"
    assert byte_size(max_value) == 4096
    assert {:ok, _} = CompoundCssValue.parse(max_value)
    assert CompoundCssValue.parse(max_value <> " ") == {:error, :resource_limit_exceeded}

    max_argument = "0deg, " <> String.duplicate("1", 2041) <> "%"
    assert byte_size(max_argument) == 2048
    assert {:ok, _} = CompoundCssValue.parse("linear-gradient(" <> max_argument <> ")")

    assert CompoundCssValue.parse("linear-gradient(" <> max_argument <> "1)") ==
             {:error, :resource_limit_exceeded}

    max_stops = Enum.map_join(1..8, ", ", fn _ -> "0%" end)
    assert {:ok, _} = CompoundCssValue.parse("linear-gradient(0deg, #{max_stops})")

    segment_at_limit = Enum.join(List.duplicate("0%", 4), " ")
    assert {:ok, _} = CompoundCssValue.parse("linear-gradient(0deg, #{segment_at_limit})")

    assert CompoundCssValue.parse("linear-gradient(0deg, #{segment_at_limit} 0%)") ==
             {:error, :resource_limit_exceeded}

    args_32 =
      Enum.map_join(1..8, ", ", fn index ->
        Enum.join(List.duplicate("0%", if(index == 8, do: 3, else: 4)), " ")
      end)

    assert {:ok, _} = CompoundCssValue.parse("linear-gradient(0deg, #{args_32})")

    args_33 = Enum.map_join(1..8, ", ", fn _ -> Enum.join(List.duplicate("0%", 4), " ") end)

    assert CompoundCssValue.parse("linear-gradient(0deg, #{args_33})") ==
             {:error, :resource_limit_exceeded}

    sixteen_refs = Enum.map_join(1..8, ", ", fn index -> "var(--a#{index}) var(--b#{index})" end)
    assert {:ok, _} = CompoundCssValue.parse("linear-gradient(0deg, #{sixteen_refs})")

    seventeen_refs = "var(--extra) " <> sixteen_refs

    assert CompoundCssValue.parse("linear-gradient(0deg, #{seventeen_refs})") ==
             {:error, :resource_limit_exceeded}

    assert CompoundCssValue.parse("calc(" <> String.duplicate("x", 2049) <> ")") ==
             {:error, :resource_limit_exceeded}

    assert CompoundCssValue.parse("linear-gradient(0deg, rgb(1,2,3))") ==
             {:error, :unsupported_grammar}

    assert CompoundCssValue.parse("linear-gradient(0deg, 10px)") ==
             {:error, :unsupported_grammar}
  end

  test "enforces reconstructed byte limit at the boundary" do
    max_value = String.duplicate("1", 4090) <> "px 1px"
    assert byte_size(max_value) == 4096
    assert {:ok, parsed} = CompoundCssValue.parse(max_value)
    assert CompoundCssValue.reconstruct(parsed, %{}) == {:ok, max_value}

    oversized = %Parsed{
      production: :multi_token_value,
      function_name: nil,
      pieces: [max_value <> "1"],
      occurrences: []
    }

    assert CompoundCssValue.reconstruct(oversized, %{}) == {:error, :resource_limit_exceeded}
  end

  test "enforces the resolved function argument byte limit" do
    assert {:ok, parsed} = CompoundCssValue.parse("calc(var(--x))")

    max_argument = String.duplicate("1", 2048)

    assert {:ok, "calc(" <> ^max_argument <> ")"} =
             CompoundCssValue.reconstruct(parsed, %{0 => max_argument})

    oversized_argument = String.duplicate("1", 2049)

    assert CompoundCssValue.reconstruct(parsed, %{0 => oversized_argument}) ==
             {:error, :resource_limit_exceeded}
  end

  test "checks terminal keys and resolved production grammar" do
    assert {:ok, parsed} = CompoundCssValue.parse("var(--duration) var(--timing)")

    assert CompoundCssValue.reconstruct(parsed, %{0 => "1s"}) ==
             {:error, :occurrence_terminal_mismatch}

    assert CompoundCssValue.reconstruct(parsed, %{0 => "1s", 1 => "ease-in-out", 2 => "x"}) ==
             {:error, :occurrence_terminal_mismatch}

    assert {:ok, "1s ease-in-out"} =
             CompoundCssValue.reconstruct(parsed, %{0 => "1s", 1 => "ease-in-out"})

    assert {:ok, dimensions} = CompoundCssValue.parse("10px 2rem")
    assert CompoundCssValue.reconstruct(dimensions, %{}) == {:ok, "10px 2rem"}

    assert CompoundCssValue.reconstruct(dimensions, %{0 => "x"}) ==
             {:error, :occurrence_terminal_mismatch}

    malformed = %Parsed{
      production: :var_reference_with_operation,
      function_name: nil,
      pieces: ["", {:occurrence, 0}],
      occurrences: [
        %Occurrence{
          occurrence_index: 0,
          local_name: "time",
          slot_grammar: :juxtaposition_right_operand
        }
      ]
    }

    assert CompoundCssValue.reconstruct(malformed, %{0 => "ease-in-out"}) ==
             {:error, :resolved_grammar_mismatch}
  end

  test "preserves distinct local names without selecting by a digest" do
    assert {:ok, first} = CompoundCssValue.parse("calc(var(--first))")
    assert {:ok, second} = CompoundCssValue.parse("calc(var(--other))")
    assert [%{local_name: "first"}] = CompoundCssValue.occurrences(first)
    assert [%{local_name: "other"}] = CompoundCssValue.occurrences(second)
  end
end
