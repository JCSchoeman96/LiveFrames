defmodule LiveFrames.BricksBoundedCustomCssNormalizerTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Adapters.Bricks.BoundedCustomCssNormalizer
  alias LiveFrames.IR.StyleValue

  @token_fixture_path Path.expand(
                        "../../../../fixtures/automatic_css/acss_settings.json",
                        __DIR__
                      )

  @owner_id "0531fc"
  @child_1 "1171e1"
  @child_2 "806d86"
  @child_3 "fc5f68"
  @image_1 "0a0447"
  @image_2 "b3b3c9"
  @image_3 "b266bb"
  @image_group_class_id "cIqHGvqlwpj"
  @wrapper_class_id "cIqHG0n8mdk"
  @image_class_id "cIqHG26nn4v"

  @canonical_css """
  /* Set min height to avoid layout shifts */
  .image-group-tango {
    min-height: 675px;
  }

  /* Shape the 1st image */
  .image-group-tango > *:first-child {
    grid-column: 1/-1;
    width: 90%;
  }

  /* Shape the 2nd image */
  .image-group-tango > *:nth-child(2) {
    width: 100%;
    aspect-ratio: 16/9;
  }

  /* Shape the 3rd image */
  .image-group-tango > *:nth-child(3) {
    width: 100%;
    aspect-ratio: 5/3.5;
  }
  """

  defp token_set do
    {:ok, token_set, _diagnostics} =
      AutomaticCSS.from_file(
        @token_fixture_path,
        source_version: "4.0.1",
        source_version_status: "fixture_reference",
        strict: true,
        profile: :hero_foundation
      )

    token_set
  end

  defp default_global_classes(css_custom) do
    [
      %{
        "id" => @image_group_class_id,
        "name" => "image-group-tango",
        "settings" => %{"_cssCustom" => css_custom}
      },
      %{
        "id" => @wrapper_class_id,
        "name" => "image-group-tango__image-wrapper",
        "settings" => %{}
      },
      %{
        "id" => @image_class_id,
        "name" => "image-group-tango__image",
        "settings" => %{"_width" => "100%", "_height" => "100%", "_objectFit" => "cover"}
      }
    ]
  end

  defp cta_fragment_source(opts \\ []) do
    css_custom = Keyword.get(opts, :css_custom, @canonical_css)
    owner_children = Keyword.get(opts, :owner_children, [@child_1, @child_2, @child_3])

    owner_settings =
      Keyword.get(opts, :owner_settings, %{"_cssGlobalClasses" => [@image_group_class_id]})

    child_1_settings =
      Keyword.get(
        opts,
        :child_1_settings,
        %{"_cssGlobalClasses" => [@wrapper_class_id]}
      )

    global_classes =
      Keyword.get(opts, :global_classes, default_global_classes(css_custom))

    %{
      "source" => "bricksCopiedElements",
      "sourceUrl" => "https://example.test/cta-tango.json",
      "version" => "2.3.1",
      "content" => [%{"id" => "proxy", "cid" => "hxambs", "label" => "CTA Tango"}],
      "components" => [
        %{
          "id" => "hxambs",
          "elements" => [
            %{
              "id" => @owner_id,
              "name" => "div",
              "parent" => 0,
              "children" => owner_children,
              "settings" => owner_settings
            },
            %{
              "id" => @child_1,
              "name" => "div",
              "parent" => @owner_id,
              "children" => [@image_1],
              "settings" => child_1_settings
            },
            %{
              "id" => @image_1,
              "name" => "image",
              "parent" => @child_1,
              "children" => [],
              "settings" => %{"_cssGlobalClasses" => [@image_class_id]}
            },
            %{
              "id" => @child_2,
              "name" => "div",
              "parent" => @owner_id,
              "children" => [@image_2],
              "settings" => %{"_cssGlobalClasses" => [@wrapper_class_id]}
            },
            %{
              "id" => @image_2,
              "name" => "image",
              "parent" => @child_2,
              "children" => [],
              "settings" => %{"_cssGlobalClasses" => [@image_class_id]}
            },
            %{
              "id" => @child_3,
              "name" => "div",
              "parent" => @owner_id,
              "children" => [@image_3],
              "settings" => %{"_cssGlobalClasses" => [@wrapper_class_id]}
            },
            %{
              "id" => @image_3,
              "name" => "image",
              "parent" => @child_3,
              "children" => [],
              "settings" => %{"_cssGlobalClasses" => [@image_class_id]}
            }
          ]
        }
      ],
      "globalClasses" => global_classes
    }
  end

  defp normalize_cta_document(opts \\ []) do
    source = cta_fragment_source(opts)

    assert {:ok, document} =
             Bricks.to_ir(source,
               token_set: token_set(),
               component_id: "hxambs",
               expected_root_count: 1
             )

    document
  end

  defp node_by_source_id(document, source_id) do
    find_node(document.root_nodes, source_id)
  end

  defp find_node(nodes, source_id) do
    Enum.find_value(nodes, fn node ->
      cond do
        node.source_trace.source_id == source_id -> node
        true -> find_node(node.children, source_id)
      end
    end)
  end

  defp refute_complex_custom_css?(node) do
    refute Map.has_key?(node.styles, "custom-css")
  end

  describe "R4 bounded CTA image-group custom CSS" do
    test "R4_CCS_01_OWNER=PASS owner receives min-height 675px" do
      document = normalize_cta_document()
      owner = node_by_source_id(document, @owner_id)

      assert %StyleValue{kind: :literal, value: "675px"} = owner.styles["min-height"]
    end

    test "R4_CCS_02_CHILD_1=PASS first wrapper receives grid-column and width" do
      document = normalize_cta_document()
      child = node_by_source_id(document, @child_1)

      assert %StyleValue{kind: :literal, value: "1 / -1"} = child.styles["grid-column"]
      assert %StyleValue{kind: :literal, value: "90%"} = child.styles["width"]
    end

    test "R4_CCS_03_CHILD_2=PASS second wrapper receives width and aspect-ratio" do
      document = normalize_cta_document()
      child = node_by_source_id(document, @child_2)

      assert %StyleValue{kind: :literal, value: "100%"} = child.styles["width"]
      assert %StyleValue{kind: :literal, value: "16/9"} = child.styles["aspect-ratio"]
    end

    test "R4_CCS_04_CHILD_3=PASS third wrapper receives width and aspect-ratio" do
      document = normalize_cta_document()
      child = node_by_source_id(document, @child_3)

      assert %StyleValue{kind: :literal, value: "100%"} = child.styles["width"]
      assert %StyleValue{kind: :literal, value: "5/3.5"} = child.styles["aspect-ratio"]
    end

    test "R4_WRAPPER_TARGETS=PASS values stay on wrapper nodes not descendant images" do
      document = normalize_cta_document()

      for image_id <- [@image_1, @image_2, @image_3] do
        image = node_by_source_id(document, image_id)
        refute Map.has_key?(image.styles, "grid-column")
        refute Map.has_key?(image.styles, "aspect-ratio")
        width = get_in(image.styles, ["width", Access.key(:value)])
        refute width in ["90%", "16/9", "5/3.5"]
      end
    end

    test "R4_NO_COMPLEX_CSS_FOR_CCS_01_04=PASS supported blob leaves no custom-css on owner" do
      document = normalize_cta_document()
      owner = node_by_source_id(document, @owner_id)
      refute_complex_custom_css?(owner)
    end

    test "R4_SEMANTIC_VALUES_SOURCE_INDEPENDENT=PASS normalized values contain no selector semantics" do
      document = normalize_cta_document()

      forbidden = ~w(.image-group-tango :first-child :nth-child _cssCustom)

      for source_id <- [@owner_id, @child_1, @child_2, @child_3] do
        node = node_by_source_id(document, source_id)

        for {property, %StyleValue{} = style} <- node.styles, property != "custom-css" do
          encoded = inspect(style.value) <> inspect(style.source_expression)

          for fragment <- forbidden do
            refute String.contains?(encoded, fragment)
          end
        end
      end
    end

    test "R4_SOURCE_TRACE_OWNER=PASS relocated declarations retain owner _cssCustom provenance" do
      document = normalize_cta_document()
      child = node_by_source_id(document, @child_1)

      assert %StyleValue{source_trace: trace, metadata: metadata} = child.styles["grid-column"]
      assert trace.source_path =~ "class_refs["
      assert trace.source_path =~ "settings._cssCustom"
      assert metadata["source_owner_id"] == @owner_id
      assert metadata["bounded_rule_id"] == "CCS-02"
    end

    test "R4_UNSUPPORTED_SELECTOR_PRESERVED=PASS extra selector remains complex_css with diagnostic" do
      css =
        @canonical_css <>
          "\n.image-group-tango .extra { color: red; }\n"

      document = normalize_cta_document(css_custom: css)
      owner = node_by_source_id(document, @owner_id)

      assert %StyleValue{kind: :complex_css} = owner.styles["custom-css"]

      assert Enum.any?(document.diagnostics, fn diagnostic ->
               diagnostic.code == "bricks.bounded_custom_css.unsupported_selector"
             end)
    end

    test "R4_EXTRA_DECLARATION_FAILS_CLOSED=PASS extra declaration is not partially guessed" do
      css =
        String.replace(
          @canonical_css,
          "width: 90%;",
          "width: 90%;\n  margin-top: 10px;"
        )

      document = normalize_cta_document(css_custom: css)
      child = node_by_source_id(document, @child_1)

      refute Map.has_key?(child.styles, "grid-column")
      refute Map.has_key?(child.styles, "width")

      assert Enum.any?(document.diagnostics, fn diagnostic ->
               diagnostic.code == "bricks.bounded_custom_css.declaration_mismatch"
             end)
    end

    test "R4_DUPLICATE_RULE_FAILS_CLOSED=PASS duplicate supported rule does not last-write-wins" do
      css = @canonical_css <> "\n.image-group-tango { min-height: 675px; }\n"
      document = normalize_cta_document(css_custom: css)
      owner = node_by_source_id(document, @owner_id)

      refute Map.has_key?(owner.styles, "min-height")

      assert Enum.any?(document.diagnostics, fn diagnostic ->
               diagnostic.code == "bricks.bounded_custom_css.duplicate_rule"
             end)
    end

    test "R4_TRIPLE_DUPLICATE_FAILS_CLOSED=PASS three identical frozen selectors fail closed" do
      css =
        @canonical_css <>
          "\n.image-group-tango { min-height: 675px; }\n.image-group-tango { min-height: 675px; }\n"

      document = normalize_cta_document(css_custom: css)
      owner = node_by_source_id(document, @owner_id)

      refute Map.has_key?(owner.styles, "min-height")

      assert Enum.count(
               document.diagnostics,
               &(&1.code == "bricks.bounded_custom_css.duplicate_rule")
             ) >=
               3
    end

    test "R4_CONFLICTING_DUPLICATE_SELECTOR_FAILS_CLOSED=PASS conflicting duplicate selectors fail closed" do
      css = """
      .image-group-tango { min-height: 675px; }
      .image-group-tango { min-height: 700px; }
      """

      document =
        normalize_cta_document(
          css_custom: css,
          global_classes: default_global_classes(css)
        )

      owner = node_by_source_id(document, @owner_id)
      refute Map.has_key?(owner.styles, "min-height")

      assert Enum.any?(document.diagnostics, fn diagnostic ->
               diagnostic.code == "bricks.bounded_custom_css.duplicate_rule"
             end)
    end

    test "R4_MISSING_CLOSING_BRACE_FAILS_CLOSED=PASS missing closing brace does not consume CCS-01" do
      css = """
      .image-group-tango {
        min-height: 675px;
      """

      document =
        normalize_cta_document(
          css_custom: css,
          global_classes: default_global_classes(css)
        )

      owner = node_by_source_id(document, @owner_id)
      refute Map.has_key?(owner.styles, "min-height")
      assert %StyleValue{kind: :complex_css} = owner.styles["custom-css"]

      assert Enum.any?(document.diagnostics, fn diagnostic ->
               diagnostic.code == "bricks.bounded_custom_css.framing_ambiguous"
             end)
    end

    test "R4_UNMATCHED_CLOSING_BRACE_FAILS_CLOSED=PASS extra closing brace fails the blob closed" do
      css = ".image-group-tango { min-height: 675px; }}"

      document =
        normalize_cta_document(
          css_custom: css,
          global_classes: default_global_classes(css)
        )

      owner = node_by_source_id(document, @owner_id)
      refute Map.has_key?(owner.styles, "min-height")
      assert %StyleValue{kind: :complex_css} = owner.styles["custom-css"]

      assert Enum.any?(document.diagnostics, fn diagnostic ->
               diagnostic.code == "bricks.bounded_custom_css.framing_ambiguous"
             end)
    end

    test "R4_ORPHAN_TEXT_PRESERVED=PASS orphan text without braces preserves full blob" do
      css = """
      .image-group-tango {
        min-height: 675px;
      }

      .future-rule broken declaration
      """

      document =
        normalize_cta_document(
          css_custom: css,
          global_classes: default_global_classes(css)
        )

      owner = node_by_source_id(document, @owner_id)
      refute Map.has_key?(owner.styles, "min-height")

      assert %StyleValue{kind: :complex_css, value: %{"rules" => [rule_text]}} =
               owner.styles["custom-css"]

      assert rule_text =~ "future-rule broken declaration"

      assert Enum.any?(document.diagnostics, fn diagnostic ->
               diagnostic.code == "bricks.bounded_custom_css.framing_ambiguous"
             end)
    end

    test "R4_NESTED_BLOCK_FAILS_CLOSED=PASS nested rule framing is not consumed as CCS-01" do
      css = """
      @media (min-width: 600px) {
        .image-group-tango {
          min-height: 675px;
        }
      }
      """

      document =
        normalize_cta_document(
          css_custom: css,
          global_classes: default_global_classes(css)
        )

      owner = node_by_source_id(document, @owner_id)
      refute Map.has_key?(owner.styles, "min-height")
      assert %StyleValue{kind: :complex_css} = owner.styles["custom-css"]

      assert Enum.any?(document.diagnostics, fn diagnostic ->
               diagnostic.code == "bricks.bounded_custom_css.framing_ambiguous"
             end)
    end

    test "R4_UNTERMINATED_COMMENT_AFTER_VALID_RULE_FAILS_CLOSED=PASS trailing unterminated comment fails blob closed" do
      css = """
      .image-group-tango {
        min-height: 675px;
      }

      /* unterminated comment
      """

      document =
        normalize_cta_document(
          css_custom: css,
          global_classes: default_global_classes(css)
        )

      owner = node_by_source_id(document, @owner_id)
      refute Map.has_key?(owner.styles, "min-height")

      assert %StyleValue{kind: :complex_css, value: %{"rules" => [rule_text]}} =
               owner.styles["custom-css"]

      assert rule_text =~ "unterminated comment"

      assert Enum.any?(document.diagnostics, fn diagnostic ->
               diagnostic.code == "bricks.bounded_custom_css.framing_ambiguous"
             end)
    end

    test "R4_UNTERMINATED_LEADING_COMMENT_FAILS_CLOSED=PASS leading unterminated comment fails blob closed" do
      css = """
      /* unterminated comment
      .image-group-tango {
        min-height: 675px;
      }
      """

      document =
        normalize_cta_document(
          css_custom: css,
          global_classes: default_global_classes(css)
        )

      owner = node_by_source_id(document, @owner_id)
      refute Map.has_key?(owner.styles, "min-height")
      assert %StyleValue{kind: :complex_css} = owner.styles["custom-css"]

      assert Enum.any?(document.diagnostics, fn diagnostic ->
               diagnostic.code == "bricks.bounded_custom_css.framing_ambiguous"
             end)
    end

    test "R4_TERMINATED_COMMENT_TRIVIA_REGRESSION=PASS properly closed comments are skipped as trivia" do
      css = """
      /* trivia before CCS-01 */
      .image-group-tango {
        min-height: 675px;
      }
      """

      document =
        normalize_cta_document(
          css_custom: css,
          global_classes: default_global_classes(css)
        )

      owner = node_by_source_id(document, @owner_id)
      assert %StyleValue{kind: :literal, value: "675px"} = owner.styles["min-height"]
      refute_complex_custom_css?(owner)
    end

    test "R4_PARSED_PLUS_UNPARSEABLE_DUPLICATE_FAILS_CLOSED=PASS malformed duplicate invalidates first occurrence" do
      css = """
      .image-group-tango {
        min-height: 675px;
      }

      .image-group-tango {
        min-height: 675px;
        min-height: 700px;
      }
      """

      document =
        normalize_cta_document(
          css_custom: css,
          global_classes: default_global_classes(css)
        )

      owner = node_by_source_id(document, @owner_id)
      refute Map.has_key?(owner.styles, "min-height")

      assert Enum.any?(document.diagnostics, fn diagnostic ->
               diagnostic.code == "bricks.bounded_custom_css.duplicate_rule"
             end)
    end

    test "R4_MALFORMED_RULE_PRESERVED=PASS malformed block remains in complex_css" do
      css = """
      .image-group-tango { min-height: 675px; }
      .future-rule { broken declaration }
      """

      document =
        normalize_cta_document(
          css_custom: css,
          global_classes: default_global_classes(css)
        )

      owner = node_by_source_id(document, @owner_id)

      assert %StyleValue{kind: :complex_css, value: %{"rules" => [rule_text]}} =
               owner.styles["custom-css"]

      assert rule_text =~ "future-rule"
      assert rule_text =~ "broken declaration"

      assert Enum.any?(document.diagnostics, fn diagnostic ->
               diagnostic.code == "bricks.bounded_custom_css.unparseable_block"
             end)
    end

    test "R4_DUPLICATE_DECLARATION_RULE_PRESERVED=PASS duplicate declarations inside a rule fail closed" do
      css =
        String.replace(
          @canonical_css,
          "grid-column: 1/-1;",
          "width: 80%;\n  width: 90%;\n  grid-column: 1/-1;"
        )

      document = normalize_cta_document(css_custom: css)
      child = node_by_source_id(document, @child_1)

      refute Map.has_key?(child.styles, "grid-column")
      refute Map.has_key?(child.styles, "width")

      assert Enum.any?(document.diagnostics, fn diagnostic ->
               diagnostic.code in [
                 "bricks.bounded_custom_css.unparseable_block",
                 "bricks.bounded_custom_css.declaration_mismatch"
               ]
             end)
    end

    test "R4_UNRESOLVED_STYLE_COLLISION_FAILS_CLOSED=PASS does not overwrite unresolved width" do
      document =
        normalize_cta_document(
          child_1_settings: %{
            "_cssGlobalClasses" => [@wrapper_class_id],
            "_width" => "var(--cta-r4-unknown-width)"
          }
        )

      child = node_by_source_id(document, @child_1)
      assert %StyleValue{kind: :unresolved} = child.styles["width"]
      refute Map.has_key?(child.styles, "grid-column")

      assert Enum.any?(document.diagnostics, fn diagnostic ->
               diagnostic.code == "bricks.bounded_custom_css.style_collision"
             end)
    end

    test "R4_UNRESOLVED_PRECEDENCE_COLLISION_FAILS_CLOSED=PASS does not resolve precedence conflicts" do
      width_a = "width-a-r4"
      width_b = "width-b-r4"

      document =
        normalize_cta_document(
          child_1_settings: %{"_cssGlobalClasses" => [width_a, width_b]},
          global_classes:
            default_global_classes(@canonical_css) ++
              [
                %{"id" => width_a, "name" => "width-a", "settings" => %{"_width" => "40%"}},
                %{"id" => width_b, "name" => "width-b", "settings" => %{"_width" => "50%"}}
              ]
        )

      child = node_by_source_id(document, @child_1)
      refute Map.has_key?(child.styles, "grid-column")

      assert Enum.any?(document.diagnostics, fn diagnostic ->
               diagnostic.code == "bricks.bounded_custom_css.style_collision"
             end)

      assert Enum.any?(document.diagnostics, fn diagnostic ->
               diagnostic.code == "bricks.style.precedence_conflict"
             end)
    end

    test "R4_ELEMENT_LOCAL_COPY_NOT_AUTHORIZED=PASS element-local effective css is not normalized" do
      document =
        normalize_cta_document(
          owner_settings: %{
            "_cssGlobalClasses" => [@image_group_class_id],
            "_cssCustom" => @canonical_css
          },
          global_classes:
            default_global_classes("")
            |> Enum.map(fn
              %{"id" => @image_group_class_id} = gc -> put_in(gc, ["settings"], %{})
              other -> other
            end)
        )

      owner = node_by_source_id(document, @owner_id)
      refute Map.has_key?(owner.styles, "min-height")
      assert %StyleValue{kind: :complex_css} = owner.styles["custom-css"]
    end

    test "R4_OTHER_CLASS_COPY_NOT_AUTHORIZED=PASS later global class css is not normalized as frozen class" do
      other_class_id = "otherCssR4"

      document =
        normalize_cta_document(
          owner_settings: %{"_cssGlobalClasses" => [@image_group_class_id, other_class_id]},
          global_classes:
            (default_global_classes("")
             |> Enum.map(fn
               %{"id" => @image_group_class_id} = gc -> put_in(gc, ["settings"], %{})
               other -> other
             end)) ++
              [
                %{
                  "id" => other_class_id,
                  "name" => "other-css-copy",
                  "settings" => %{"_cssCustom" => @canonical_css}
                }
              ]
        )

      owner = node_by_source_id(document, @owner_id)
      refute Map.has_key?(owner.styles, "min-height")
      assert %StyleValue{kind: :complex_css} = owner.styles["custom-css"]
    end

    test "R4_TARGET_TOPOLOGY_MISMATCH_FAILS_CLOSED=PASS reordered children do not receive relocated styles" do
      document =
        normalize_cta_document(owner_children: [@child_2, @child_1, @child_3])

      refute Map.has_key?(node_by_source_id(document, @child_1).styles, "grid-column")

      assert Enum.any?(document.diagnostics, fn diagnostic ->
               diagnostic.code == "bricks.bounded_custom_css.topology_mismatch"
             end)
    end

    test "R4_EXISTING_STYLE_COLLISION_FAILS_CLOSED=PASS cannot overwrite existing normalized width" do
      document =
        normalize_cta_document(
          child_1_settings: %{
            "_cssGlobalClasses" => [@wrapper_class_id],
            "_width" => "50%"
          }
        )

      child = node_by_source_id(document, @child_1)
      assert child.styles["width"].value == "50%"
      refute Map.has_key?(child.styles, "grid-column")

      assert Enum.any?(document.diagnostics, fn diagnostic ->
               diagnostic.code == "bricks.bounded_custom_css.style_collision"
             end)
    end

    test "unrelated _cssCustom on another element remains complex_css" do
      source =
        cta_fragment_source()
        |> put_in(
          ["components", Access.at(0), "elements", Access.at(0), "settings"],
          %{"_cssCustom" => ".other { color: blue; }"}
        )

      assert {:ok, document} =
               Bricks.to_ir(source,
                 token_set: token_set(),
                 component_id: "hxambs",
                 expected_root_count: 1
               )

      owner = node_by_source_id(document, @owner_id)
      assert %StyleValue{kind: :complex_css} = owner.styles["custom-css"]
    end
  end

  test "parse_blocks recognizes four frozen CTA rules" do
    {rules, rejects} = BoundedCustomCssNormalizer.parse_parts(@canonical_css)
    assert length(rules) == 4
    assert rejects == []
  end

  test "parse_blocks handles a single owner rule" do
    assert [_rule] =
             BoundedCustomCssNormalizer.parse_blocks(".image-group-tango { min-height: 675px; }")
  end

  describe "BoundedCustomCssNormalizer unit contract" do
    test "returns the expected result keys" do
      result = BoundedCustomCssNormalizer.empty_result()

      assert Map.has_key?(result, :styles_by_source_id)
      assert Map.has_key?(result, :residual_custom_css_by_source_id)
      assert Map.has_key?(result, :diagnostics)
    end
  end
end
