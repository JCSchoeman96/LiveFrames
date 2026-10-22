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

    assert [%{occurrence_index: 0, local_name: "--accent", slot_grammar: :gradient_stop_atom}] =
             CompoundCssValue.occurrences(parsed)

    assert {:ok, "linear-gradient(90deg, transparent 0%, rgb(1,2,3) 100%)"} =
             CompoundCssValue.reconstruct(parsed, %{0 => "rgb(1,2,3)"})

    assert {:ok, upper} = CompoundCssValue.parse("LINEAR-GRADIENT(90deg, var(--stop))")

    assert {:ok, "LINEAR-GRADIENT(90deg, 10%)"} =
             CompoundCssValue.reconstruct(upper, %{0 => "10%"})
  end

  test "preserves the full embedded variable name and its case" do
    assert {:ok, parsed} =
             CompoundCssValue.parse("linear-gradient(90deg, var(----accent))")

    assert [%{local_name: "----accent"}] = CompoundCssValue.occurrences(parsed)

    assert {:ok, case_variant} = CompoundCssValue.parse("calc(var(--Accent))")
    assert [%{local_name: "--Accent"}] = CompoundCssValue.occurrences(case_variant)
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

      assert [%{local_name: "--space", slot_grammar: :calc_operand}] =
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

  test "trims the frozen ASCII whitespace around a declaration" do
    for whitespace <- [" ", "\t", "\r", "\n", "\f"] do
      assert {:ok, parsed} = CompoundCssValue.parse(whitespace <> "10px 2rem" <> whitespace)
      assert parsed.production == :multi_token_value
      assert {:ok, "10px 2rem"} = CompoundCssValue.reconstruct(parsed, %{})
    end

    assert CompoundCssValue.parse("10px\u00a02rem") == :no_match
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

    assert [%{occurrence_index: 0, local_name: "--accent"}] =
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

    overflowing_factor = String.duplicate("9", 400)

    assert CompoundCssValue.parse("calc(var(--x) * #{overflowing_factor})") ==
             {:error, :unsupported_grammar}

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
          "rgba(1,2,3,0.5)",
          "-1%"
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
          "red()"
        ] do
      assert CompoundCssValue.reconstruct(gradient, %{0 => atom}) ==
               {:error, :invalid_slot_terminal}
    end

    assert {:ok, calc} = CompoundCssValue.parse("calc(var(--x))")

    for atom <- ["0", "-2.5", "10px", "2%", "-2%"] do
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

    overflowing_number = String.duplicate("9", 400)

    assert CompoundCssValue.reconstruct(juxtaposition, %{
             0 => overflowing_number <> "s",
             1 => "ease-in-out"
           }) == {:error, :invalid_slot_terminal}

    assert {:ok, gradient} = CompoundCssValue.parse("linear-gradient(90deg, var(--stop))")

    assert CompoundCssValue.reconstruct(gradient, %{
             0 => "rgba(1,2,3," <> overflowing_number <> ".0)"
           }) == {:error, :invalid_slot_terminal}

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
    assert [%{local_name: "--first"}] = CompoundCssValue.occurrences(first)
    assert [%{local_name: "--other"}] = CompoundCssValue.occurrences(second)
  end

  test "parses a single transition shorthand spec" do
    assert {:ok, parsed} =
             parse_transition_shorthand("opacity var(--duration) var(--timing)")

    assert parsed.production == :transition_shorthand
    assert parsed.function_name == nil

    assert [
             %{occurrence_index: 0, local_name: "--duration"},
             %{occurrence_index: 1, local_name: "--timing"}
           ] = CompoundCssValue.occurrences(parsed)
  end

  test "parses a two-spec transition shorthand" do
    assert {:ok, parsed} =
             parse_transition_shorthand(
               "opacity var(--duration) var(--timing), transform var(--duration-b) var(--timing-b)"
             )

    assert parsed.production == :transition_shorthand
    assert length(CompoundCssValue.occurrences(parsed)) == 4
  end

  test "accepts ASCII whitespace variants in transition shorthand" do
    for whitespace <- [" ", "\t", "\r", "\n", "\f"] do
      value = "opacity" <> whitespace <> "var( --duration )" <> whitespace <> "var(--timing)"
      assert {:ok, _parsed} = parse_transition_shorthand(value)
    end

    for around_comma <- [",", " ,", ", ", "\t,\f"] do
      value =
        "opacity var(--duration) var(--timing)" <>
          around_comma <> "transform var(--duration-b) var(--timing-b)"

      assert {:ok, _parsed} = parse_transition_shorthand(value)
    end
  end

  test "reconstructs transition specs with canonical comma and space" do
    assert {:ok, single} =
             parse_transition_shorthand("opacity\nvar(--duration)\tvar(--timing)")

    assert {:ok, "opacity 250ms ease-in-out"} =
             CompoundCssValue.reconstruct(single, %{0 => "250ms", 1 => "ease-in-out"})

    assert {:ok, multiple} =
             parse_transition_shorthand(
               "opacity\nvar(--duration)\tvar(--timing)\r\n,\f transform\tvar(--duration-b)\nvar(--timing-b)"
             )

    assert {:ok, "opacity 250ms ease-in-out, transform 1.5s ease-in-out"} =
             CompoundCssValue.reconstruct(multiple, %{
               0 => "250ms",
               1 => "ease-in-out",
               2 => "1.5s",
               3 => "ease-in-out"
             })
  end

  test "assigns transition occurrence indexes and slot grammars in source order" do
    assert {:ok, single} =
             parse_transition_shorthand("opacity var(--duration) var(--timing)")

    assert [
             %{occurrence_index: 0, slot_grammar: :transition_duration_operand},
             %{occurrence_index: 1, slot_grammar: :juxtaposition_right_operand}
           ] = CompoundCssValue.occurrences(single)

    assert {:ok, multiple} =
             parse_transition_shorthand(
               "opacity var(--duration-a) var(--timing-a), transform var(--duration-b) var(--timing-b)"
             )

    assert [
             %{occurrence_index: 0, slot_grammar: :transition_duration_operand},
             %{occurrence_index: 1, slot_grammar: :juxtaposition_right_operand},
             %{occurrence_index: 2, slot_grammar: :transition_duration_operand},
             %{occurrence_index: 3, slot_grammar: :juxtaposition_right_operand}
           ] = CompoundCssValue.occurrences(multiple)
  end

  test "preserves transition property identifiers and local reference case" do
    assert {:ok, parsed} =
             parse_transition_shorthand("unknown-property var(--DurationA) var(--TimingB)")

    assert [
             %{local_name: "--DurationA"},
             %{local_name: "--TimingB"}
           ] = CompoundCssValue.occurrences(parsed)

    assert {:ok, "unknown-property 250ms ease-in-out"} =
             CompoundCssValue.reconstruct(parsed, %{0 => "250ms", 1 => "ease-in-out"})
  end

  test "accepts safe unknown lowercase hyphenated property identifiers" do
    for property <- ["unknown-property", "unknown-property-2", "property3-name"] do
      assert {:ok, _parsed} =
               parse_transition_shorthand("#{property} var(--duration) var(--timing)")
    end
  end

  test "rejects reserved transition property identifiers" do
    for property <- ["inherit", "initial", "unset", "revert", "revert-layer", "none", "all"] do
      assert parse_transition_shorthand("#{property} var(--duration) var(--timing)") == :no_match
    end
  end

  test "rejects duplicate transition property identifiers" do
    assert parse_transition_shorthand(
             "opacity var(--duration) var(--timing), opacity var(--duration-b) var(--timing-b)"
           ) == :no_match
  end

  test "rejects uppercase transition property identifiers" do
    assert parse_transition_shorthand("Opacity var(--duration) var(--timing)") == :no_match
  end

  test "rejects escaped and custom transition property identifiers" do
    for property <- ["\\6f pacity", "--custom"] do
      assert parse_transition_shorthand("#{property} var(--duration) var(--timing)") == :no_match
    end
  end

  test "rejects a third transition spec" do
    assert parse_transition_shorthand(
             "opacity var(--duration) var(--timing), transform var(--duration-b) var(--timing-b), color var(--duration-c) var(--timing-c)"
           ) == :no_match
  end

  test "rejects a transition spec with no duration reference" do
    assert parse_transition_shorthand("opacity var(--timing)") == :no_match
  end

  test "rejects a transition spec with no timing reference" do
    assert parse_transition_shorthand("opacity var(--duration)") == :no_match
  end

  test "rejects extra transition tokens" do
    for extra <- ["2s", "allow-discrete"] do
      assert parse_transition_shorthand("opacity var(--duration) var(--timing) #{extra}") ==
               :no_match
    end
  end

  test "rejects literal transition durations" do
    assert parse_transition_shorthand("opacity 250ms var(--timing)") == :no_match
  end

  test "rejects literal transition timings" do
    assert parse_transition_shorthand("opacity var(--duration) ease-in-out") == :no_match
  end

  test "rejects delay and transition behavior tokens" do
    for extra <- ["1s", "allow-discrete"] do
      assert parse_transition_shorthand("opacity var(--duration) var(--timing) #{extra}") ==
               :no_match
    end
  end

  test "rejects function syntax in transition shorthand" do
    for value <- [
          "opacity var(--duration) cubic-bezier(0,0,1,1)",
          "unknown(var(--duration)) var(--timing) var(--timing-b)",
          "opacity var(--duration) steps(1,end)"
        ] do
      assert parse_transition_shorthand(value) == :no_match
    end
  end

  test "rejects malformed transition comma layouts" do
    first = "opacity var(--duration) var(--timing)"
    second = "transform var(--duration-b) var(--timing-b)"

    for value <- [
          "," <> first,
          first <> ",",
          first <> ",," <> second,
          first <> " " <> second,
          first <> ", " <> second <> ", " <> second
        ] do
      assert parse_transition_shorthand(value) == :no_match
    end
  end

  test "rejects transition var fallback syntax" do
    assert parse_transition_shorthand("opacity var(--duration, 250ms) var(--timing)") == :no_match
  end

  test "rejects malformed transition var references" do
    for value <- [
          "opacity var(--duration var(--timing)",
          "opacity var(--duration)) var(--timing)",
          "opacity var(--duration) var(--timing"
        ] do
      assert parse_transition_shorthand(value) == :no_match
    end
  end

  test "rejects non-ASCII transition whitespace" do
    assert parse_transition_shorthand("opacity\u00a0var(--duration) var(--timing)") ==
             :no_match
  end

  test "accepts zero and positive finite transition duration terminals" do
    assert {:ok, parsed} = parse_transition_shorthand("opacity var(--duration) var(--timing)")

    for duration <- ["0ms", "250ms", ".5s"] do
      assert {:ok, "opacity " <> ^duration <> " ease-in-out"} =
               CompoundCssValue.reconstruct(parsed, %{0 => duration, 1 => "ease-in-out"})
    end
  end

  test "rejects invalid transition duration terminals" do
    assert {:ok, parsed} = parse_transition_shorthand("opacity var(--duration) var(--timing)")
    overflow = String.duplicate("9", 400) <> "s"

    for duration <- ["-1s", "+1s", "1", "1e3s", "250ms\n", overflow, "NaNs"] do
      assert CompoundCssValue.reconstruct(parsed, %{0 => duration, 1 => "ease-in-out"}) ==
               {:error, :invalid_slot_terminal},
             duration
    end
  end

  test "rejects timing terminals outside the existing right-slot contract" do
    assert {:ok, parsed} = parse_transition_shorthand("opacity var(--duration) var(--timing)")

    for timing <- [
          "ease",
          "linear",
          "ease-in",
          "ease-out",
          "steps(1,end)",
          "cubic-bezier(0,0,1,1)"
        ] do
      assert CompoundCssValue.reconstruct(parsed, %{0 => "250ms", 1 => timing}) ==
               {:error, :invalid_slot_terminal},
             timing
    end
  end

  test "enforces the transition parser 4096-byte source boundary" do
    suffix = " var(--duration) var(--timing)"
    property = String.duplicate("a", 4096 - byte_size(suffix))
    max_value = property <> suffix

    assert byte_size(max_value) == 4096
    assert {:ok, _parsed} = parse_transition_shorthand(max_value)
    assert parse_transition_shorthand(max_value <> " ") == {:error, :resource_limit_exceeded}
  end

  test "canonical transition reconstruction leaves no var reference" do
    assert {:ok, parsed} =
             parse_transition_shorthand(
               "opacity var(--duration) var(--timing), transform var(--duration-b) var(--timing-b)"
             )

    assert {:ok, reconstructed} =
             CompoundCssValue.reconstruct(parsed, %{
               0 => "250ms",
               1 => "ease-in-out",
               2 => "1.5s",
               3 => "ease-in-out"
             })

    refute reconstructed =~ "var("
  end

  test "keeps parse one unchanged for IDENT-prefixed transition values" do
    assert CompoundCssValue.parse("opacity var(--duration) var(--timing)") == :no_match

    assert CompoundCssValue.parse(
             "opacity var(--duration) var(--timing), transform var(--d) var(--t)"
           ) == :no_match
  end

  test "keeps the existing bare var juxtaposition production unchanged" do
    value = "var(--duration) var(--timing)"
    assert {:ok, parsed} = CompoundCssValue.parse(value)
    assert parsed.production == :var_reference_with_operation

    assert [
             %{occurrence_index: 0, slot_grammar: :juxtaposition_left_operand},
             %{occurrence_index: 1, slot_grammar: :juxtaposition_right_operand}
           ] = CompoundCssValue.occurrences(parsed)

    assert CompoundCssValue.reconstruct(parsed, %{0 => "250ms", 1 => "ease-in-out"}) ==
             {:ok, "250ms ease-in-out"}
  end

  defp parse_transition_shorthand(value) do
    Code.ensure_loaded!(CompoundCssValue)

    if function_exported?(CompoundCssValue, :parse_transition_shorthand, 1) do
      apply(CompoundCssValue, :parse_transition_shorthand, [value])
    else
      :no_match
    end
  end
end
