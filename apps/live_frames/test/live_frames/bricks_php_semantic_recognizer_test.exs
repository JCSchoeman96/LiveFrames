defmodule LiveFrames.BricksPhpSemanticRecognizerTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks.PhpSemanticRecognizer

  @canonical "<?php $product = wc_get_product(get_the_ID()); $description = $product->get_description(); if ($product) { echo $description; } ?>"

  test "recognizes only the current entity full description flow" do
    assert PhpSemanticRecognizer.recognize(@canonical) ==
             {:ok, :current_entity_full_description}

    source =
      "<?php /* start */ $item = wc_get_product ( get_the_ID ( ) ) ; // product\n" <>
        "$body = $item -> get_description ( ) ; if ( $item ) { echo $body ; } ?>"

    assert PhpSemanticRecognizer.recognize(source) ==
             {:ok, :current_entity_full_description}
  end

  test "rejects other data sources, output meanings, and aliases" do
    unsupported = [
      "$product = wc_get_product(767); $description = $product->get_description(); if ($product) { echo $description; }",
      "$product = wc_get_product(get_the_ID()); $description = $product->get_short_description(); if ($product) { echo $description; }",
      "$product = wc_get_product(get_the_ID()); $description = $product->get_description(); if ($description) { echo $description; }",
      "$product = wc_get_product(get_the_ID()); $description = $product->get_description(); if ($other) { echo $description; }",
      "$product = wc_get_product(get_the_ID()); $description = $product->get_description(); if ($product && $description) { echo $description; }",
      "$product = wc_get_product(get_the_ID()); $description = $product->get_description(); $other = $product->get_description(); if ($product) { echo $description; }",
      "$product = wc_get_product(get_the_ID()); $description = $product->get_description(); if ($product) { echo $description; } echo $description;",
      "$product = wc_get_product(get_the_ID()); $description = $product->get_description(); if ($product) { echo $description; echo $description; }",
      "$product = wc_get_product(get_the_ID()); $description = $product->get_description(); if ($product) { echo $description; } else { echo 'x'; }",
      "$product = wc_get_product(get_the_ID()); $description = $product->get_description(); if ($product) { echo $description; } elseif ($other) { echo 'x'; }",
      "$product = wc_get_product(get_the_ID()); $description = $product->get_description(); if ($product) { if ($other) { echo $description; } }",
      "$product = wc_get_product(get_the_ID()); $description = $product->get_description(); if ($product) { $product = null; echo $description; }",
      "$product = wc_get_product(get_the_ID()); $description = $product->get_description(); if ($product) { echo $description; } if ($product) { echo $description; }",
      "$product = wc_get_product(get_the_ID()); $description = $product->get_description(); ?>inline html<?php if ($product) { echo $description; }",
      "$product = wc_get_product(get_the_ID()); $description = $product->get_description(); if ($product) { echo $product->get_name(); }",
      "$product = wc_get_product(get_the_ID()); $description = $product->get_description(); if ($product) { print $description; }"
    ]

    for source <- unsupported do
      assert {:error, reason} = PhpSemanticRecognizer.recognize(source)

      assert reason in [
               :parse_failed,
               :semantic_unsupported,
               :semantic_ambiguous,
               :resource_limit_exceeded
             ]
    end
  end

  test "rejects unsafe calls and executable constructs without exposing source" do
    unsafe = [
      "eval($code);",
      "include $path;",
      "exec($command);",
      "file_get_contents($path);",
      "wp_remote_get($url);",
      "$function = 'get_description'; $function();"
    ]

    for source <- unsafe do
      assert {:error, reason} = PhpSemanticRecognizer.recognize(source)
      assert reason in [:unsafe, :semantic_unsupported, :parse_failed]
      refute inspect(reason) =~ source
    end
  end

  test "fails closed on malformed and ambiguous inputs" do
    assert {:error, _} = PhpSemanticRecognizer.recognize("<?php $product = wc_get_product(")
    assert {:error, _} = PhpSemanticRecognizer.recognize(@canonical <> " trailing")

    ambiguous =
      "$product = wc_get_product(get_the_ID()); $description = $product->get_description(); " <>
        "$description = $product->get_description(); if ($product) { echo $description; }"

    assert {:error, reason} = PhpSemanticRecognizer.recognize(ambiguous)
    assert reason in [:semantic_ambiguous, :semantic_unsupported, :parse_failed]
  end

  test "PHP line comments stop at a closing tag before inline HTML" do
    source =
      "$product = wc_get_product(get_the_ID()); $description = $product->get_description(); " <>
        "// comment ?> inline html <?php\nif ($product) { echo $description; }"

    assert {:error, _reason} = PhpSemanticRecognizer.recognize(source)
  end

  test "rejects malformed variables that begin with a digit" do
    source =
      "$1 = wc_get_product(get_the_ID()); $description = $1->get_description(); " <>
        "if ($1) { echo $description; }"

    assert {:error, :parse_failed} = PhpSemanticRecognizer.recognize(source)
  end

  test "rejects comments before the opening PHP tag as inline output" do
    assert {:error, _reason} =
             PhpSemanticRecognizer.recognize("// leading comment\n" <> @canonical)
  end

  test "rejects comments after the closing PHP tag as inline output" do
    assert {:error, _reason} = PhpSemanticRecognizer.recognize(@canonical <> "/* outside PHP */")
  end

  test "rejects PHP attributes instead of treating them as line comments" do
    source = String.replace_prefix(@canonical, "<?php ", "<?php #[Foo]\n")

    assert {:error, :parse_failed} = PhpSemanticRecognizer.recognize(source)
  end

  test "enforces each frozen parser cap at and above its limit" do
    padding = 16_384 - byte_size(@canonical) - 4
    source_with_internal_comment = String.replace_suffix(@canonical, "?>", "/*PAD*/?>")

    at_byte_limit =
      String.replace(source_with_internal_comment, "PAD", String.duplicate(" ", padding))

    assert byte_size(at_byte_limit) == 16_384

    assert PhpSemanticRecognizer.recognize(at_byte_limit) ==
             {:ok, :current_entity_full_description}

    assert {:error, :resource_limit_exceeded} =
             PhpSemanticRecognizer.recognize(@canonical <> String.duplicate(" ", 16_384))

    assert {:error, :parse_failed} =
             PhpSemanticRecognizer.recognize(Enum.map_join(1..2_048, " ", fn _ -> "foo" end))

    assert {:error, :resource_limit_exceeded} =
             PhpSemanticRecognizer.recognize(Enum.map_join(1..2_049, " ", fn _ -> "foo" end))

    assert {:error, :resource_limit_exceeded} =
             PhpSemanticRecognizer.recognize(String.duplicate(";", 2_049))

    assert {:error, within_limit_reason} =
             PhpSemanticRecognizer.recognize(Enum.map_join(1..32, " ", &"$v#{&1}"))

    refute within_limit_reason == :resource_limit_exceeded

    assert {:error, :resource_limit_exceeded} =
             PhpSemanticRecognizer.recognize(Enum.map_join(1..33, " ", &"$v#{&1}"))

    assert {:error, :parse_failed} =
             PhpSemanticRecognizer.recognize(Enum.map_join(1..8, ";", &"call#{&1}()"))

    assert {:error, :resource_limit_exceeded} =
             PhpSemanticRecognizer.recognize(Enum.map_join(1..9, ";", &"call#{&1}()"))

    assert {:error, :parse_failed} =
             PhpSemanticRecognizer.recognize(String.duplicate("$x = 1;", 16))

    assert {:error, :resource_limit_exceeded} =
             PhpSemanticRecognizer.recognize(String.duplicate("$x = 1;", 17))

    assert {:error, :parse_failed} = PhpSemanticRecognizer.recognize("if ($x) {}")

    assert {:error, :resource_limit_exceeded} =
             PhpSemanticRecognizer.recognize(String.duplicate("if ($x) {}", 2))

    assert {:error, :parse_failed} =
             PhpSemanticRecognizer.recognize(
               String.duplicate("(", 16) <> "$x" <> String.duplicate(")", 16)
             )

    assert {:error, :resource_limit_exceeded} =
             PhpSemanticRecognizer.recognize(
               String.duplicate("(", 17) <> "$x" <> String.duplicate(")", 17)
             )

    assert {:error, :parse_failed} =
             PhpSemanticRecognizer.recognize(Enum.map_join(1..129, " ", fn _ -> "$x" end))
  end
end
