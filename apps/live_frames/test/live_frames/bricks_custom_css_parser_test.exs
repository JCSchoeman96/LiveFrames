defmodule LiveFrames.BricksCustomCssParserTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks.CustomCssParser

  test "parses one flat qualified rule" do
    css = ".card { opacity: 0; }"

    assert %{
             frames: [
               %{
                 raw: ^css,
                 selector: ".card",
                 body: " opacity: 0; ",
                 declarations: %{"opacity" => "0"},
                 min_width: nil,
                 max_width: nil,
                 source_order: 0
               }
             ],
             rejects: []
           } = CustomCssParser.parse(css)
  end

  test "preserves source order across flat rules" do
    result =
      CustomCssParser.parse(".card { opacity: 0; }\n.card__title { color: red; }")

    assert Enum.map(result.frames, &{&1.selector, &1.source_order}) == [
             {".card", 0},
             {".card__title", 1}
           ]

    assert result.rejects == []
  end

  test "preserves comma-separated selector text" do
    frame = parse_single(".group-a, .group-b { display: block; }")

    assert frame.selector == ".group-a, .group-b"
  end

  test "does not split quoted semicolons or colons into declarations" do
    frame = parse_single(".card { font-family: \"A;color:red\"; }")

    assert frame.declarations == %{"font-family" => "\"A;color:red\""}
  end

  test "does not split semicolons inside single-quoted strings" do
    frame = parse_single(".card { content: 'A;color:red'; opacity: 1; }")

    assert frame.declarations == %{"content" => "'A;color:red'", "opacity" => "1"}
  end

  test "does not split escaped quotes or semicolons inside strings" do
    frame = parse_single(~s(.card { content: "A\\\";B"; opacity: 1; }))

    assert frame.declarations == %{"content" => "\"A\\\";B\"", "opacity" => "1"}
  end

  test "does not treat comment markers inside strings as comments" do
    frame = parse_single(".card { content: \"/* ; display:block */\"; opacity: 1; }")

    assert frame.declarations == %{
             "content" => "\"/* ; display:block */\"",
             "opacity" => "1"
           }
  end

  test "ignores declaration delimiters inside CSS comments" do
    frame = parse_single(".card { color: red /* ; display:block */; opacity: 1; }")

    assert frame.declarations == %{
             "color" => "red /* ; display:block */",
             "opacity" => "1"
           }
  end

  test "does not split semicolons or colons inside nested function values" do
    frame = parse_single(".card { background-image: synthetic(data;part:value); opacity: 1; }")

    assert frame.declarations == %{
             "background-image" => "synthetic(data;part:value)",
             "opacity" => "1"
           }
  end

  test "does not split semicolons inside bracketed custom property values" do
    frame = parse_single(".card { --raw: [left;right]; opacity: 1; }")

    assert frame.declarations == %{"--raw" => "[left;right]", "opacity" => "1"}
  end

  test "rejects a complete rule with an unterminated declaration string" do
    assert_rejected(
      ".card { font-family: \"unfinished; color: red; }",
      :malformed_framing
    )
  end

  test "rejects a complete rule with an unterminated declaration comment" do
    assert_rejected(".card { color: red /* unfinished; opacity: 1; }", :malformed_framing)
  end

  test "rejects a complete rule with unbalanced function or bracket nesting" do
    assert_rejected(".card { background: synthetic(data; opacity: 1; }", :invalid_declaration)
    assert_rejected(".card { --raw: [left; opacity: 1; }", :invalid_declaration)
  end

  test "rejects crossed function and bracket nesting" do
    assert_rejected(".card { --raw: ([)]; }", :invalid_declaration)
  end

  test "preserves custom property case while lowercasing ordinary property names" do
    frame = parse_single(".card { COLOR: red; --ThemeColor: blue; --themecolor: green; }")

    assert frame.declarations == %{
             "color" => "red",
             "--ThemeColor" => "blue",
             "--themecolor" => "green"
           }
  end

  test "trims each CSS whitespace character at the declaration property boundary" do
    for whitespace <- [" ", "\t", "\r", "\n", "\f"] do
      frame = parse_single(".card { #{whitespace}color#{whitespace}: red; }")

      assert frame.declarations == %{"color" => "red"}
    end
  end

  test "trims each CSS whitespace character at the declaration value boundary" do
    for whitespace <- [" ", "\t", "\r", "\n", "\f"] do
      frame = parse_single(".card { color: #{whitespace}red#{whitespace}; }")

      assert frame.declarations == %{"color" => "red"}
    end
  end

  test "trims mixed CSS whitespace runs at both declaration boundaries" do
    frame = parse_single(".card { \t \f\r\ncolor\n \t: \t \f\r\nred\n \t; }")

    assert frame.declarations == %{"color" => "red"}
  end

  test "preserves leading NBSP at the declaration property boundary" do
    nbsp = <<0xC2, 0xA0>>
    css = ".card { #{nbsp}color: red; }"

    assert_rejected(css, :invalid_declaration)
  end

  test "preserves trailing NBSP at the declaration property boundary" do
    nbsp = <<0xC2, 0xA0>>
    css = ".card { color#{nbsp}: red; }"

    assert_rejected(css, :invalid_declaration)
  end

  test "preserves leading NBSP in the declaration value" do
    nbsp = <<0xC2, 0xA0>>
    frame = parse_single(".card { color: #{nbsp}red; }")

    assert frame.declarations == %{"color" => nbsp <> "red"}
  end

  test "preserves trailing NBSP in the declaration value" do
    nbsp = <<0xC2, 0xA0>>
    frame = parse_single(".card { color: red#{nbsp}; }")

    assert frame.declarations == %{"color" => "red" <> nbsp}
  end

  test "does not treat an NBSP-only declaration value as CSS whitespace" do
    nbsp = <<0xC2, 0xA0>>
    frame = parse_single(".card { color: #{nbsp}; }")

    assert frame.declarations == %{"color" => nbsp}
  end

  test "accepts a complete property token followed by a comment" do
    frame = parse_single(".card { color/**/: red; }")

    assert frame.declarations == %{"color" => "red"}
  end

  test "accepts a complete property token preceded by a comment" do
    frame = parse_single(".card { /**/color: red; }")

    assert frame.declarations == %{"color" => "red"}
  end

  test "rejects comments that fuse ordinary property-name tokens" do
    assert_rejected(".card { co/**/lor: red; }", :invalid_declaration)
  end

  test "rejects comments that fuse custom property-name tokens" do
    assert_rejected(".card { --Theme/**/Color: red; }", :invalid_declaration)
  end

  test "rejects comments that fuse custom property prefix tokens" do
    assert_rejected(".card { -/**/-Theme: red; }", :invalid_declaration)
  end

  test "quoted braces in selectors do not change generic block framing" do
    css = ~s([data-x="{"] { color: red; })
    frame = parse_single(css)

    assert frame.selector == ~s([data-x="{"])
    assert frame.declarations == %{"color" => "red"}
  end

  test "frames a min-width media rule" do
    css = "@media (min-width: 600px) { .card { opacity: 0; } }"
    frame = parse_single(css)

    assert frame.raw == ".card { opacity: 0; }"
    assert frame.container_raw == css
    assert frame.selector == ".card"
    assert frame.min_width == 600
    assert frame.max_width == nil
  end

  test "rejects statement at-rules atomically and preserves the following rule" do
    cases = [
      {"@import url(\"x.css\");", :unsupported_at_rule},
      {"@charset \"UTF;8\";", :unsupported_at_rule},
      {"@import \"x;{.css\";", :unsupported_at_rule},
      {"@import url(x;part.css);", :unsupported_at_rule},
      {"@import url(x.css)/* ; { */;", :unsupported_at_rule}
    ]

    for {statement, reason} <- cases do
      css = statement <> "\n.card { opacity: 1; }"
      result = CustomCssParser.parse(css)

      assert [%{raw: ^statement, reason: ^reason, source_order: 0}] = result.rejects
      assert [%{raw: ".card { opacity: 1; }", selector: ".card", source_order: 1}] = result.frames
    end
  end

  test "unsupported block at-rules do not consume following rules" do
    at_rule = "@supports (display: grid) { .group-a { opacity: 0; } }"
    result = CustomCssParser.parse(at_rule <> "\n.card { opacity: 1; }")

    assert [%{raw: ^at_rule, reason: :unsupported_at_rule, source_order: 0}] = result.rejects
    assert [%{selector: ".card", source_order: 1}] = result.frames
  end

  test "keeps bounded media child rules and rejects independently with atomic raw text" do
    container_raw =
      "@media (min-width: 767px) {\n" <>
        "  .group-a { opacity: 0; }\n" <>
        "  .group-b { opacity: 0; opacity: 1; }\n" <>
        "  .group-c { color: red; }\n" <>
        "}"

    css = container_raw <> "\n.card { opacity: 1; }"
    result = CustomCssParser.parse(css)

    assert [
             %{
               raw: ".group-a { opacity: 0; }",
               container_raw: ^container_raw,
               min_width: 767.0,
               source_order: 0
             },
             %{
               raw: ".group-c { color: red; }",
               container_raw: ^container_raw,
               min_width: 767.0,
               source_order: 2
             },
             %{raw: ".card { opacity: 1; }", container_raw: nil, min_width: nil, source_order: 3}
           ] = result.frames

    assert [
             %{
               raw: ".group-b { opacity: 0; opacity: 1; }",
               reason: :duplicate_property,
               container_raw: ^container_raw,
               min_width: 767.0,
               max_width: nil,
               source_order: 1
             }
           ] = result.rejects
  end

  test "rejects an unsupported media child at-rule without dropping valid siblings" do
    container_raw =
      "@media (max-width: 900px) {\n" <>
        "  .group-a { opacity: 0; }\n" <>
        "  @supports (display: grid) { .group-b { opacity: 1; } }\n" <>
        "  .group-c { color: red; }\n" <>
        "}"

    result = CustomCssParser.parse(container_raw)

    assert Enum.map(result.frames, &{&1.selector, &1.source_order, &1.raw, &1.container_raw}) == [
             {".group-a", 0, ".group-a { opacity: 0; }", container_raw},
             {".group-c", 2, ".group-c { color: red; }", container_raw}
           ]

    assert [
             %{
               raw: "@supports (display: grid) { .group-b { opacity: 1; } }",
               reason: :unsupported_at_rule,
               source_order: 1,
               min_width: nil,
               max_width: 900.0,
               container_raw: ^container_raw
             }
           ] = result.rejects
  end

  test "fails a malformed media container closed as one raw item" do
    css = "@media (min-width: 767px) { .group-a { opacity: 0; }"

    assert_rejected(css, :malformed_framing)
  end

  test "frames a max-width media rule" do
    frame = parse_single("@media (max-width: 767px) { .card { opacity: 1; } }")

    assert frame.min_width == nil
    assert frame.max_width == 767
  end

  test "frames a bounded min-width and max-width media rule" do
    frame =
      parse_single("@media (min-width: 600px) and (max-width: 900px) { .card { opacity: 1; } }")

    assert frame.min_width == 600
    assert frame.max_width == 900
  end

  test "accepts numeric and whitespace variants in bounded media syntax" do
    frame =
      parse_single(
        "@media ( min-width : 0.5px ) and ( max-width : 767.25px ) { .card { opacity: 1; } }"
      )

    assert frame.min_width == 0.5
    assert frame.max_width == 767.25
  end

  test "rejects negative media widths" do
    assert_rejected(
      "@media (min-width: -1px) { .card { opacity: 1; } }",
      :invalid_viewport
    )
  end

  test "rejects a media range whose minimum exceeds its maximum" do
    assert_rejected(
      "@media (min-width: 901px) and (max-width: 900px) { .card { opacity: 1; } }",
      :invalid_viewport
    )
  end

  test "rejects unsupported media conditions" do
    assert_rejected(
      "@media screen and (min-width: 600px) { .card { opacity: 1; } }",
      :unsupported_media_condition
    )
  end

  test "rejects unknown at-rules atomically" do
    assert_rejected("@supports (display: grid) { .card { opacity: 1; } }", :unsupported_at_rule)
  end

  test "rejects nested unsupported constructs atomically" do
    assert_rejected(
      ".card { @supports (display: grid) { opacity: 1; } }",
      :nested_construct
    )
  end

  test "rejects malformed and unclosed framing as the complete source" do
    css = ".card { opacity: 0; }\n.card__title { color: red;"

    assert_rejected(css, :malformed_framing)
  end

  test "rejects malformed declarations" do
    assert_rejected(".card { opacity }", :invalid_declaration)
  end

  test "rejects duplicate properties in one generic rule" do
    assert_rejected(".card { opacity: 0; opacity: 1; }", :duplicate_property)
  end

  test "retains the complete rejected rule as one raw item" do
    css = ".card { opacity: 0; opacity: 1; }"
    result = CustomCssParser.parse(css)

    assert result.frames == []
    assert [%{raw: ^css, source_order: 0, reason: :duplicate_property}] = result.rejects
  end

  defp parse_single(css) do
    assert %{frames: [frame], rejects: []} = CustomCssParser.parse(css)
    frame
  end

  defp assert_rejected(css, reason) do
    assert %{frames: [], rejects: [%{raw: ^css, reason: ^reason}]} =
             CustomCssParser.parse(css)
  end
end
