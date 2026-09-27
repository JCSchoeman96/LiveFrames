defmodule LiveFrames.BricksDesignIRTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Fidelity
  alias LiveFrames.IR
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.StyleValue

  @fixture_path Path.expand("../../../../fixtures/bricks/bricks_components.json", __DIR__)
  @token_fixture_path Path.expand(
                        "../../../../fixtures/automatic_css/acss_settings.json",
                        __DIR__
                      )

  @source_ids [
    "sqhmmc",
    "2ef2fa",
    "561d75",
    "3f6ee6",
    "8ae908",
    "8ca7e4",
    "7ea788",
    "1c85d9",
    "a1745a",
    "be2b65"
  ]

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

  defp synthetic_copied_elements_source do
    %{
      "source" => "bricksCopiedElements",
      "sourceUrl" => "https://example.test/export.json",
      "version" => "2.3.1",
      "content" => [%{"id" => "proxy-a", "cid" => "component-a", "label" => "Synthetic"}],
      "components" => [
        %{
          "id" => "component-a",
          "elements" => [
            %{
              "id" => "root",
              "name" => "div",
              "parent" => 0,
              "settings" => %{"_cssGlobalClasses" => ["opaque-class-id"]}
            }
          ]
        }
      ],
      "globalClasses" => []
    }
  end

  defp synthetic_external_class_authority do
    %{
      id: "synthetic-site-classes",
      global_classes: [
        %{"id" => "opaque-class-id", "name" => "synthetic-class", "settings" => %{}}
      ]
    }
  end

  defp synthetic_source(elements) do
    source = synthetic_copied_elements_source()
    [component] = source["components"]
    %{source | "components" => [%{component | "elements" => elements}]}
  end

  defp source_element(id, name, parent, settings, children \\ []) do
    %{
      "id" => id,
      "name" => name,
      "parent" => parent,
      "children" => children,
      "settings" => settings
    }
  end

  defp document do
    assert {:ok, document} =
             Bricks.to_ir(@fixture_path,
               component_id: "sqhmmc",
               token_set: token_set()
             )

    document
  end

  defp flatten(nodes), do: Enum.flat_map(nodes, &[&1 | flatten(&1.children)])

  defp node_by_source_id(document, source_id) do
    Enum.find(flatten(document.root_nodes), fn node ->
      node.source_trace.source_id == source_id
    end)
  end

  test "normalizes a valid DesignDocument with the complete ordered Hero tree" do
    document = document()

    assert IR.validate(document) == :ok
    assert document.ir_version == "1.0.0"
    assert length(document.root_nodes) == 1

    nodes = flatten(document.root_nodes)
    assert Enum.map(nodes, & &1.source_trace.source_id) == @source_ids

    assert Enum.map(nodes, & &1.semantic_type) == [
             "section",
             "container",
             "heading",
             "paragraph",
             "generic",
             "button",
             "button",
             "generic",
             "image",
             "generic"
           ]

    assert Enum.map(nodes, & &1.node_id) == [
             DesignNode.deterministic_id([1]),
             DesignNode.deterministic_id([1, 1]),
             DesignNode.deterministic_id([1, 1, 1]),
             DesignNode.deterministic_id([1, 1, 2]),
             DesignNode.deterministic_id([1, 1, 3]),
             DesignNode.deterministic_id([1, 1, 3, 1]),
             DesignNode.deterministic_id([1, 1, 3, 2]),
             DesignNode.deterministic_id([1, 2]),
             DesignNode.deterministic_id([1, 2, 1]),
             DesignNode.deterministic_id([1, 2, 2])
           ]

    refute Enum.any?(nodes, fn node -> node.node_id in @source_ids end)

    assert node_by_source_id(document, "2ef2fa").children |> Enum.map(& &1.source_trace.source_id) ==
             [
               "561d75",
               "3f6ee6",
               "8ae908"
             ]
  end

  test "normalizes static block and text types without changing existing semantic types" do
    source =
      synthetic_source([
        source_element("root", "block", 0, %{}, ["text", "div", "text-basic"]),
        source_element("text", "text", "root", %{"text" => "Synthetic text"}),
        source_element("div", "div", "root", %{}),
        source_element("text-basic", "text-basic", "root", %{"tag" => "p", "text" => "Body"})
      ])

    assert {:ok, document} =
             Bricks.to_ir(source,
               component_id: "component-a",
               token_set: token_set()
             )

    root = node_by_source_id(document, "root")
    text = node_by_source_id(document, "text")
    div = node_by_source_id(document, "div")
    text_basic = node_by_source_id(document, "text-basic")

    assert root.semantic_type == "generic"
    assert text.semantic_type == "rich_text"
    assert text.content == "Synthetic text"
    assert div.semantic_type == "generic"
    assert text_basic.semantic_type == "paragraph"
    refute Enum.any?(document.diagnostics, &(&1.code == "bricks.element.unsupported"))

    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ "<div class=\"lf-fidelity-node-000001\">"
    assert bundle.heex =~ ~s(<%= "Synthetic text" %>)
  end

  test "preserves corpus-proven native tags through Design IR and Fidelity" do
    source =
      synthetic_source([
        source_element("root", "block", 0, %{"tag" => "div"}, [
          "unordered",
          "ordered",
          "details",
          "button"
        ]),
        source_element("unordered", "block", "root", %{"tag" => "ul"}, ["unordered-item"]),
        source_element("unordered-item", "block", "unordered", %{"tag" => "li"}),
        source_element("ordered", "container", "root", %{"tag" => "ol"}, ["ordered-item"]),
        source_element("ordered-item", "block", "ordered", %{"tag" => "li"}),
        source_element(
          "details",
          "div",
          "root",
          %{
            "tag" => "custom",
            "customTag" => "details",
            "_attributes" => [
              %{"id" => "details-name", "name" => "name", "value" => "faq-group"}
            ]
          },
          ["summary"]
        ),
        source_element("summary", "text-basic", "details", %{
          "tag" => "custom",
          "customTag" => "summary"
        }),
        source_element("button", "div", "root", %{
          "tag" => "custom",
          "customTag" => "button",
          "_attributes" => [
            %{"id" => "type-entry", "name" => "type", "value" => "submit"}
          ]
        })
      ])

    assert {:ok, document} =
             Bricks.to_ir(source,
               component_id: "component-a",
               token_set: token_set()
             )

    assert Enum.map(
             [
               "root",
               "unordered",
               "unordered-item",
               "ordered",
               "ordered-item",
               "details",
               "summary",
               "button"
             ],
             fn source_id ->
               node_by_source_id(document, source_id).semantic_type
             end
           ) == [
             "generic",
             "generic",
             "generic",
             "container",
             "generic",
             "generic",
             "rich_text",
             "generic"
           ]

    assert node_by_source_id(document, "unordered").attributes["tag"] == "ul"
    assert node_by_source_id(document, "details").attributes["tag"] == "details"
    assert node_by_source_id(document, "details").attributes["name"] == "faq-group"
    assert node_by_source_id(document, "summary").attributes["tag"] == "summary"
    assert node_by_source_id(document, "button").attributes["type"] == "submit"

    assert node_by_source_id(document, "details").source_trace.metadata["native_semantics"] == %{
             "decision" => "customTag",
             "native_tag" => "details",
             "attributes" => ["name"]
           }

    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ "<ul class=\"lf-fidelity-node-000001-000001\">"
    assert bundle.heex =~ "<ol class=\"lf-fidelity-node-000001-000002\">"
    assert bundle.heex =~ "<li class=\"lf-fidelity-node-000001-000001-000001\">"
    assert bundle.heex =~ "<details class=\"lf-fidelity-node-000001-000003\" name=\"faq-group\">"
    assert bundle.heex =~ "<summary class=\"lf-fidelity-node-000001-000003-000001\">"
    assert bundle.heex =~ "<button class=\"lf-fidelity-node-000001-000004\" type=\"submit\">"
  end

  test "accepts only explicit native button type overrides" do
    source =
      synthetic_source([
        source_element("root", "block", 0, %{}, ["button", "details"]),
        source_element("button", "div", "root", %{
          "tag" => "custom",
          "customTag" => "button",
          "_attributes" => [
            %{"id" => "type-entry", "name" => "type", "value" => "javascript"}
          ]
        }),
        source_element("details", "div", "root", %{
          "tag" => "custom",
          "customTag" => "details",
          "_attributes" => [
            %{"id" => "type-entry", "name" => "type", "value" => "submit"}
          ]
        })
      ])

    assert {:ok, document} =
             Bricks.to_ir(source,
               component_id: "component-a",
               token_set: token_set()
             )

    assert node_by_source_id(document, "button").attributes["type"] == nil
    assert node_by_source_id(document, "details").attributes["type"] == nil

    assert Enum.count(document.diagnostics, &(&1.code == "bricks.attribute.unsupported")) == 2

    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ "<button class=\"lf-fidelity-node-000001-000001\" type=\"button\">"
    assert bundle.heex =~ "<details class=\"lf-fidelity-node-000001-000002\">"
    refute bundle.heex =~ "type=\"javascript\""
    refute bundle.heex =~ "type=\"submit\""
  end

  test "retains the rich text inference for text-basic elements without paragraph semantics" do
    source =
      synthetic_source([
        source_element("root", "text-basic", 0, %{"tag" => "span", "text" => "Inline text"})
      ])

    assert {:ok, document} =
             Bricks.to_ir(source,
               component_id: "component-a",
               token_set: token_set()
             )

    node = node_by_source_id(document, "root")

    assert node.semantic_type == "rich_text"

    assert node.source_trace.inference ==
             "text-basic element kept as rich text because paragraph semantics were not proven"

    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ "<span class=\"lf-fidelity-node-000001\">"
    assert bundle.heex =~ ~s(<%= "Inline text" %>)
    assert bundle.heex =~ "</span>"
  end

  test "normalizes safe source attributes and emits them in stable escaped order" do
    label = ~s(He said "go" & <stay>)

    source =
      synthetic_source([
        source_element("root", "block", 0, %{
          "_attributes" => [
            %{"id" => "role-entry", "name" => "role", "value" => "region"},
            %{"id" => "label-entry", "name" => "aria-label", "value" => label},
            %{"id" => "live-entry", "name" => "aria-live", "value" => "polite"},
            %{"id" => "mode-entry", "name" => "data-mode", "value" => "dark"},
            %{"id" => "empty-entry", "name" => "data-empty"},
            %{"id" => "tabindex-entry", "name" => "tabindex", "value" => "-1"}
          ],
          "ariaLabel" => label
        })
      ])

    assert {:ok, document} =
             Bricks.to_ir(source,
               component_id: "component-a",
               token_set: token_set()
             )

    node = node_by_source_id(document, "root")

    assert node.attributes["role"] == "region"
    assert node.attributes["aria-label"] == label
    assert node.attributes["aria-live"] == "polite"
    assert node.attributes["data-mode"] == "dark"
    assert node.attributes["data-empty"] == ""
    assert node.attributes["tabindex"] == "-1"
    assert node.source_trace.source_settings["ariaLabel"] == label
    assert node.source_trace.metadata["native_semantics"]["native_tag"] == nil

    assert node.source_trace.metadata["native_semantics"]["attributes"] == [
             "aria-label",
             "aria-live",
             "data-empty",
             "data-mode",
             "role",
             "tabindex"
           ]

    refute Enum.any?(document.diagnostics, &(&1.code == "bricks.setting.unsupported"))

    assert {:ok, first} = Fidelity.generate(document)
    assert {:ok, second} = Fidelity.generate(document)
    assert first.heex == second.heex

    assert first.heex =~
             ~s(<div class="lf-fidelity-node-000001" aria-label="He said &quot;go&quot; &amp; &lt;stay&gt;" aria-live="polite" data-empty="" data-mode="dark" role="region" tabindex="-1">)
  end

  test "rejects unsafe passthrough attributes and preserves their source evidence" do
    source =
      synthetic_source([
        source_element("root", "block", 0, %{
          "style" => "display:none",
          "outline" => "danger",
          "caption" => "source caption",
          "link" => %{"url" => "https://example.test/destination"},
          "url" => "https://example.test/destination",
          "alt" => "Source alt",
          "_attributes" => [
            %{"id" => "class-entry", "name" => "class", "value" => "injected-class"},
            %{"id" => "style-entry", "name" => "style", "value" => "display:none"},
            %{"id" => "event-entry", "name" => "onclick", "value" => "alert(1)"},
            %{"id" => "href-entry", "name" => "href", "value" => "javascript:alert(1)"},
            %{"id" => "src-entry", "name" => "src", "value" => "data:text/html,bad"},
            %{"id" => "id-entry", "name" => "id", "value" => "source-id"},
            %{"id" => "tabindex-entry", "name" => "tabindex", "value" => "0"},
            %{"id" => "runtime-entry", "name" => "data-slide-navigation"},
            %{"id" => "internal-entry", "name" => "data-lf-node-id", "value" => "owned"}
          ]
        })
      ])

    assert {:ok, document} =
             Bricks.to_ir(source,
               component_id: "component-a",
               token_set: token_set()
             )

    node = node_by_source_id(document, "root")
    assert node.attributes["class"] == nil
    assert node.attributes["style"] == "display:none"
    assert node.attributes["outline"] == "danger"
    assert node.attributes["caption"] == "source caption"
    assert node.attributes["link"] == %{"url" => "https://example.test/destination"}
    assert node.attributes["url"] == "https://example.test/destination"
    assert node.attributes["alt"] == "Source alt"
    assert node.attributes["onclick"] == nil
    assert node.attributes["href"] == nil
    assert node.attributes["src"] == nil
    assert node.attributes["id"] == nil

    assert node.source_trace.source_settings["_attributes"] ==
             source["components"]
             |> hd()
             |> Map.fetch!("elements")
             |> hd()
             |> Map.fetch!("settings")
             |> Map.fetch!("_attributes")

    assert node.source_trace.source_settings["style"] == "display:none"
    assert node.source_trace.source_settings["outline"] == "danger"
    assert node.source_trace.source_settings["caption"] == "source caption"

    assert Enum.count(document.diagnostics, &(&1.code == "bricks.attribute.unsupported")) == 9

    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ "class=\"lf-fidelity-node-000001\""
    refute bundle.heex =~ "injected-class"
    refute bundle.heex =~ "display:none"
    refute bundle.heex =~ "danger"
    refute bundle.heex =~ "source caption"
    refute bundle.heex =~ "onclick="
    refute bundle.heex =~ "javascript:"
    refute bundle.heex =~ "data:text/html"
    refute bundle.heex =~ "example.test/destination"
    refute bundle.heex =~ "source-id"
    refute bundle.heex =~ "data-slide-navigation"
    refute bundle.heex =~ "data-lf-node-id"
  end

  test "diagnoses conflicting source tag and attribute representations" do
    source =
      synthetic_source([
        source_element("root", "block", 0, %{
          "tag" => "custom",
          "customTag" => "details",
          "_attributes" => [
            %{"id" => "label-entry", "name" => "aria-label", "value" => "attribute"}
          ],
          "ariaLabel" => "setting"
        })
      ])

    assert {:ok, document} =
             Bricks.to_ir(source,
               component_id: "component-a",
               token_set: token_set()
             )

    assert {:ok, repeated_document} =
             Bricks.to_ir(source,
               component_id: "component-a",
               token_set: token_set()
             )

    assert IR.encode!(document) == IR.encode!(repeated_document)

    node = node_by_source_id(document, "root")
    refute Map.has_key?(node.attributes, "aria-label")
    assert node.source_trace.source_settings["tag"] == "custom"
    assert node.source_trace.source_settings["customTag"] == "details"

    assert Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.attribute.conflict" and
               diagnostic.source_trace.source_id == "root"
           end)

    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.heex =~ "aria-label="
    assert bundle.heex =~ "<details"
  end

  test "falls back safely when native tags are unsupported or ambiguous" do
    source =
      synthetic_source([
        source_element("root", "block", 0, %{"tag" => "custom", "customTag" => "x-private"}, [
          "conflict"
        ]),
        source_element("conflict", "block", "root", %{
          "tag" => "section",
          "customTag" => "details"
        })
      ])

    assert {:ok, document} =
             Bricks.to_ir(source,
               component_id: "component-a",
               token_set: token_set()
             )

    assert node_by_source_id(document, "root").attributes["tag"] == nil
    assert node_by_source_id(document, "conflict").attributes["tag"] == nil

    assert node_by_source_id(document, "root").source_trace.source_settings["customTag"] ==
             "x-private"

    assert Enum.count(document.diagnostics, &(&1.code == "bricks.tag.unsupported")) == 1
    assert Enum.count(document.diagnostics, &(&1.code == "bricks.tag.conflict")) == 1

    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ "<div class=\"lf-fidelity-node-000001\">"
    assert bundle.heex =~ "<div class=\"lf-fidelity-node-000001-000001\">"
    refute bundle.heex =~ "<x-private"
    refute bundle.heex =~ "<details"
  end

  test "normalizes an external class authority through the existing Design IR provenance" do
    source = synthetic_copied_elements_source()

    assert {:ok, document} =
             Bricks.to_ir(source,
               component_id: "component-a",
               token_set: token_set(),
               external_class_authorities: [synthetic_external_class_authority()]
             )

    assert IR.validate(document) == :ok
    refute Enum.any?(document.diagnostics, &(&1.code == "bricks.class.unresolved_external"))
    assert node_by_source_id(document, "root").source_trace.source_classes == ["synthetic-class"]

    assert [class_dependency] =
             document.provenance["dependency_summary"]["class_dependencies"]

    assert class_dependency["class_id"] == "opaque-class-id"
    assert class_dependency["name"] == "synthetic-class"
    assert class_dependency["resolution_status"] == "external_resolved"
    assert class_dependency["authority_ids"] == ["synthetic-site-classes"]
  end

  test "does not consume native tag or attribute settings supplied by a class" do
    source =
      synthetic_source([
        source_element("root", "block", 0, %{"_cssGlobalClasses" => ["opaque-class-id"]})
      ])

    authority = %{
      id: "synthetic-site-classes",
      global_classes: [
        %{
          "id" => "opaque-class-id",
          "name" => "synthetic-class",
          "settings" => %{
            "tag" => "custom",
            "customTag" => "details",
            "_attributes" => [%{"name" => "aria-label", "value" => "class label"}]
          }
        }
      ]
    }

    assert {:ok, document} =
             Bricks.to_ir(source,
               component_id: "component-a",
               token_set: token_set(),
               external_class_authorities: [authority]
             )

    node = node_by_source_id(document, "root")
    refute Map.has_key?(node.attributes, "tag")
    refute Map.has_key?(node.attributes, "aria-label")

    assert Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.setting.unsupported" and
               diagnostic.source_trace.source_id == "root"
           end)

    assert Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.setting.unsupported" and
               diagnostic.source_trace.source_id == "root" and
               diagnostic.metadata["source_path"] == "tag"
           end)

    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ "<div class=\"lf-fidelity-node-000001 synthetic-class\">"
    refute bundle.heex =~ "<details"
    refute bundle.heex =~ "aria-label=\"class label\""
  end

  test "retains source content, classes, settings, and ten source traces" do
    document = document()
    nodes = flatten(document.root_nodes)

    assert Enum.count(nodes, &match?(%{source_trace: %LiveFrames.IR.SourceTrace{}}, &1)) == 10

    assert node_by_source_id(document, "561d75").content == "Hero heading"

    assert node_by_source_id(document, "3f6ee6").content ==
             "This is just placeholder text. Don’t be alarmed, this is just here to fill up space since your finalized copy isn’t ready yet. Once we have your content finalized, we’ll replace this placeholder text with your real content."

    assert node_by_source_id(document, "561d75").attributes == %{"tag" => "h1"}
    assert node_by_source_id(document, "3f6ee6").attributes == %{"tag" => "p"}

    assert node_by_source_id(document, "sqhmmc").source_trace.source_classes == [
             "fr-hero-india",
             "bg--ultra-dark"
           ]

    assert node_by_source_id(document, "sqhmmc").source_trace.source_settings == %{
             "_cssGlobalClasses" => ["6lGpftooejv", "acss_import_bg--ultra-dark"]
           }
  end

  test "normalizes literal, keyword, token, fallback, calculation, and unresolved styles" do
    document = document()

    assert %StyleValue{kind: :keyword, value: "relative"} =
             node_by_source_id(document, "sqhmmc").styles["position"]

    assert %StyleValue{
             kind: :token_ref,
             value: "spacing.content_gap",
             source_expression: "var(--content-gap)"
           } = node_by_source_id(document, "2ef2fa").styles["row-gap"]

    assert %StyleValue{kind: :literal, value: "70ch"} =
             node_by_source_id(document, "3f6ee6").styles["max-width"]

    assert %StyleValue{
             kind: :token_ref,
             value: "spacing.content_gap",
             source_expression: "var(--content-gap, 30px)",
             metadata: %{"fallback" => "30px", "source_variable" => "--content-gap"}
           } = node_by_source_id(document, "8ae908").styles["column-gap"]

    assert %StyleValue{kind: :literal, value: "400px", source_expression: "400px"} =
             node_by_source_id(document, "2ef2fa").styles["margin-top"]

    assert %StyleValue{kind: :keyword, value: "flex"} =
             node_by_source_id(document, "2ef2fa").styles["display"]

    assert %StyleValue{kind: :keyword, value: "column"} =
             node_by_source_id(document, "2ef2fa").styles["flex-direction"]

    assert %StyleValue{
             kind: :unresolved,
             value: "var(--overlay-bg, var(--neutral-ultra-dark-trans-60))",
             source_expression: "var(--overlay-bg, var(--neutral-ultra-dark-trans-60))"
           } = node_by_source_id(document, "be2b65").styles["background"]

    assert %StyleValue{kind: :complex_css, value: %{"type" => "custom_css"}} =
             node_by_source_id(document, "1c85d9").styles["custom-css"]

    calculation_source =
      File.read!(@fixture_path)
      |> Jason.decode!()
      |> put_in(["globalClasses", Access.filter(&(&1["id"] == "6lGpfjmaoto")), "settings"], %{
        "_width" => "calc(100% - 1rem)"
      })

    assert {:ok, calculation_document} =
             Bricks.to_ir(calculation_source, token_set: token_set(), component_id: "sqhmmc")

    assert %StyleValue{kind: :calculation, value: "calc(100% - 1rem)"} =
             node_by_source_id(calculation_document, "2ef2fa").styles["width"]
  end

  test "preserves base and responsive gradients as complex CSS" do
    document = document()
    overlay = node_by_source_id(document, "be2b65")

    assert %StyleValue{kind: :complex_css, value: base_gradient} =
             overlay.styles["background-image"]

    assert base_gradient["type"] == "gradient"
    assert base_gradient["value"]["angle"] == "90"
    assert length(base_gradient["value"]["colors"]) == 3

    assert %StyleValue{kind: :complex_css, value: responsive_gradient} =
             overlay.responsive["tablet_portrait"].styles["background-image"]

    assert responsive_gradient["value"]["angle"] == "180"

    assert responsive_gradient["value"]["colors"] == [
             %{
               "color" => %{"raw" => "hsla(0, 0%, 0%, 0)"},
               "id" => "oqyyja",
               "stop" => "5%"
             },
             %{
               "color" => %{"raw" => "hsla(0, 0%, 5%, 0.39)"},
               "id" => "gzslth",
               "stop" => "20%"
             },
             %{
               "color" => %{"raw" => "hsla(0, 1%, 4%, 0.91)"},
               "id" => "wnuidn",
               "stop" => "65%"
             }
           ]
  end

  test "retains every responsive record without inventing thresholds" do
    document = document()
    nodes = flatten(document.root_nodes)
    overrides = Enum.flat_map(nodes, &Map.values(&1.responsive))

    assert Enum.sum(Enum.map(overrides, &map_size(&1.styles))) == 4

    assert Enum.map(overrides, & &1.source_name) == [
             "mobile_portrait",
             "tablet_portrait",
             "tablet_portrait"
           ]

    assert Enum.all?(overrides, fn override ->
             override.breakpoint_id == override.source_name and
               override.min_width == nil and
               override.max_width == nil and
               override.resolution_status == :unresolved and
               match?(%LiveFrames.IR.SourceTrace{}, override.source_trace)
           end)

    assert node_by_source_id(document, "8ae908").responsive["mobile_portrait"].styles[
             "custom-css"
           ].value["rules"] == [".fr-cta-links-alpha > * {\n  width: 100% !important;\n}"]
  end

  test "creates one unresolved image asset and no synthetic interactions" do
    document = document()

    assert map_size(document.assets) == 1
    assert document.interactions == %{}

    {asset_id, asset} = Enum.at(document.assets, 0)
    assert asset_id == asset.asset_id
    assert asset.kind == "image"
    assert asset.status == :unresolved
    assert asset.uri == nil
    assert asset.alt == nil
    assert asset.metadata["attachment_id"] == 880
    assert asset.metadata["filename"] == "cordallman-man-8493246_1920.webp"
    assert asset.metadata["url"] == false
    assert asset.source_trace.source_id == "a1745a"
    assert node_by_source_id(document, "a1745a").asset_refs == [asset_id]
  end

  test "preserves Stage A unresolved diagnostics and deterministic lifecycle evidence" do
    document = document()
    codes = Enum.map(document.diagnostics, & &1.code)

    assert length(document.diagnostics) == 7
    assert Enum.count(codes, &(&1 == "bricks.breakpoint.unresolved")) == 4
    assert Enum.count(codes, &(&1 == "bricks.variable.unresolved")) == 2
    refute "bricks.setting.value_unresolved" in codes
    assert "bricks.asset.unresolved" in codes

    assert Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.variable.unresolved" and
               diagnostic.metadata["raw_value"] == "--overlay-bg"
           end)

    assert Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.asset.unresolved" and
               diagnostic.source_trace.source_id == "a1745a"
           end)

    assert document.provenance["normalization_lifecycle"] == [
             "source_model_ready",
             "token_set_bound",
             "nodes_normalized",
             "styles_normalized",
             "responsive_normalized",
             "dependencies_bound",
             "document_assembled",
             "ir_validated",
             "serialized"
           ]

    assert document.provenance["normalization_status"] == "serialized"
    refute Map.has_key?(document.provenance, "artifact")

    refute inspect(document.provenance) =~
             "sources/work/hero_india/design_ir/design_document.json"
  end

  test "embeds the validated TokenSet JSON object without changing its contract" do
    document = document()
    assert document.token_set == LiveFrames.Tokens.to_map(token_set())
    assert document.token_set["token_set_version"] == "1.0.0"
    assert document.token_set["tokens"]["spacing.content_gap"]["path"] == "spacing.content_gap"
  end

  test "equivalent conversions produce byte-identical deterministic JSON" do
    first = document()
    second = document()

    assert IR.encode!(first) == IR.encode!(second)
    assert first.root_nodes == second.root_nodes
  end
end
