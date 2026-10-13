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

  test "quoted braces in selectors do not change generic block framing" do
    css = ~s([data-x="{"] { color: red; })
    frame = parse_single(css)

    assert frame.selector == ~s([data-x="{"])
    assert frame.declarations == %{"color" => "red"}
  end

  test "frames a min-width media rule" do
    css = "@media (min-width: 600px) { .card { opacity: 0; } }"
    frame = parse_single(css)

    assert frame.raw == css
    assert frame.selector == ".card"
    assert frame.min_width == 600
    assert frame.max_width == nil
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
