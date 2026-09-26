defmodule LiveFrames.BricksStaticNavigationTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Fidelity
  alias LiveFrames.IR
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.SourceTrace

  @token_fixture_path Path.expand(
                        "../../../../fixtures/automatic_css/acss_settings.json",
                        __DIR__
                      )

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

  defp synthetic_source(elements) do
    %{
      "source" => "bricksCopiedElements",
      "sourceUrl" => "https://example.test/export.json",
      "version" => "2.3.1",
      "content" => [%{"id" => "proxy-a", "cid" => "component-a", "label" => "Synthetic"}],
      "components" => [
        %{
          "id" => "component-a",
          "elements" => elements
        }
      ],
      "globalClasses" => []
    }
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

  defp to_ir(elements) do
    Bricks.to_ir(synthetic_source(elements),
      component_id: "component-a",
      token_set: token_set()
    )
  end

  defp node_by_source_id(document, source_id) do
    document.root_nodes
    |> flatten()
    |> Enum.find(&(&1.source_trace.source_id == source_id))
  end

  defp flatten(nodes), do: Enum.flat_map(nodes, &[&1 | flatten(&1.children)])

  defp external_link(url), do: %{"type" => "external", "url" => url}

  test "non-linked button remains button type=button" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["btn"]),
               source_element("btn", "button", "root", %{"text" => "Click"})
             ])

    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ "<button"
    assert bundle.heex =~ ~s(type="button")
    refute bundle.heex =~ "<a"
  end

  test "text-link with static destination becomes an anchor" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["nav"]),
               source_element("nav", "text-link", "root", %{
                 "text" => "Home",
                 "link" => external_link("/about/")
               })
             ])

    node = node_by_source_id(document, "nav")
    assert node.semantic_type == "link"
    assert node.attributes["navigation"] == %{"href" => "/about/"}

    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ ~s(href="/about/")
    assert bundle.heex =~ "<a"
    assert bundle.heex =~ "Home"
  end

  test "button with proven static link object becomes an anchor" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["btn"]),
               source_element("btn", "button", "root", %{
                 "text" => "Go",
                 "link" => external_link("#section")
               })
             ])

    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ ~s(href="#section")
    assert bundle.heex =~ "<a"
    refute bundle.heex =~ "<button"
  end

  test "safe site-relative destination survives" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["nav"]),
               source_element("nav", "text-link", "root", %{
                 "text" => "Menu",
                 "link" => external_link("/template/slide-navigation-alpha/")
               })
             ])

    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ ~s(href="/template/slide-navigation-alpha/")
  end

  test "safe fragment destination survives" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["nav"]),
               source_element("nav", "text-link", "root", %{
                 "text" => "Top",
                 "link" => external_link("#")
               })
             ])

    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ ~s(href="#")
  end

  @tag :corpus_external_https
  test "safe external https destination survives for corpus external link type" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["nav"]),
               source_element("nav", "text-link", "root", %{
                 "text" => "External",
                 "link" => external_link("https://example.test/safe")
               })
             ])

    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ ~s(href="https://example.test/safe")
  end

  test "javascript destinations are rejected" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["nav"]),
               source_element("nav", "text-link", "root", %{
                 "text" => "Bad",
                 "link" => external_link("javascript:alert(1)")
               })
             ])

    node = node_by_source_id(document, "nav")
    refute node.attributes["navigation"]

    assert Enum.any?(document.diagnostics, &(&1.code == "bricks.navigation.rejected"))

    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.heex =~ "javascript:"
    refute bundle.heex =~ ~s(href=")
  end

  test "data destinations are rejected" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["nav"]),
               source_element("nav", "text-link", "root", %{
                 "text" => "Bad",
                 "link" => external_link("data:text/html,bad")
               })
             ])

    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.heex =~ "data:text/html"
  end

  test "malformed destinations are rejected" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["nav"]),
               source_element("nav", "text-link", "root", %{
                 "text" => "Bad",
                 "link" => external_link("not a valid static url")
               })
             ])

    assert Enum.any?(document.diagnostics, &(&1.code == "bricks.navigation.rejected"))
    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.heex =~ ~s(href="not)
  end

  test "dynamic destinations are preserved as evidence but not emitted" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["nav"]),
               source_element("nav", "text-link", "root", %{
                 "text" => "Site",
                 "url" => %{"type" => "meta", "useDynamicData" => "{site_url}"}
               })
             ])

    node = node_by_source_id(document, "nav")
    assert node.attributes["url"]["useDynamicData"] == "{site_url}"
    refute node.attributes["navigation"]

    assert Enum.any?(document.diagnostics, &(&1.code == "bricks.navigation.dynamic"))

    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.heex =~ ~s(href=")
  end

  test "conflicting link and url destinations are diagnosed and not emitted" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["btn"]),
               source_element("btn", "button", "root", %{
                 "text" => "Go",
                 "link" => external_link("/one"),
                 "url" => "/two"
               })
             ])

    refute node_by_source_id(document, "btn").attributes["navigation"]
    assert Enum.any?(document.diagnostics, &(&1.code == "bricks.navigation.conflict"))

    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.heex =~ ~s(href="/one")
    refute bundle.heex =~ ~s(href="/two")
  end

  test "identical duplicate link evidence normalizes deterministically" do
    assert {:ok, first} =
             to_ir([
               source_element("root", "block", 0, %{}, ["btn"]),
               source_element("btn", "button", "root", %{
                 "text" => "Go",
                 "link" => external_link("/same"),
                 "url" => "/same"
               })
             ])

    assert {:ok, second} =
             to_ir([
               source_element("root", "block", 0, %{}, ["btn"]),
               source_element("btn", "button", "root", %{
                 "text" => "Go",
                 "link" => external_link("/same"),
                 "url" => "/same"
               })
             ])

    node_a = node_by_source_id(first, "btn")
    node_b = node_by_source_id(second, "btn")
    assert node_a.attributes["navigation"] == node_b.attributes["navigation"]

    assert {:ok, bundle_a} = Fidelity.generate(first)
    assert {:ok, bundle_b} = Fidelity.generate(second)
    assert bundle_a.heex == bundle_b.heex
    assert bundle_a.heex =~ ~s(href="/same")
  end

  test "generic _attributes href remains rejected" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["nav"]),
               source_element("nav", "text-link", "root", %{
                 "text" => "Home",
                 "link" => external_link("/safe"),
                 "_attributes" => [
                   %{"id" => "href-entry", "name" => "href", "value" => "javascript:alert(1)"}
                 ]
               })
             ])

    refute node_by_source_id(document, "nav").attributes["href"]
    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ ~s(href="/safe")
    refute bundle.heex =~ "javascript:"
  end

  test "source cannot inject target or rel through generic attributes" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["nav"]),
               source_element("nav", "text-link", "root", %{
                 "text" => "Home",
                 "link" => external_link("/safe"),
                 "_attributes" => [
                   %{"id" => "target-entry", "name" => "target", "value" => "_blank"},
                   %{"id" => "rel-entry", "name" => "rel", "value" => "opener"}
                 ]
               })
             ])

    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.heex =~ "target="
    refute bundle.heex =~ "rel="
  end

  test "pipeline-owned new-tab metadata emits protected rel" do
    document = %DesignDocument{
      ir_version: DesignDocument.current_ir_version(),
      source_metadata: %{},
      token_set: %{},
      root_nodes: [
        DesignNode.new([1],
          semantic_type: "link",
          content: "Away",
          attributes: %{
            "navigation" => %{"href" => "https://example.test/away", "target" => "_blank"}
          },
          source_trace: %SourceTrace{
            source_type: "synthetic",
            source_id: "nav",
            source_path: "synthetic",
            source_name: "text-link",
            adapter: "test",
            adapter_version: "test",
            inference: "test"
          }
        )
      ],
      assets: %{},
      interactions: %{},
      diagnostics: [],
      provenance: %{}
    }

    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ ~s(target="_blank")
    assert bundle.heex =~ ~s(rel="noopener noreferrer")
  end

  test "destination values are HTML-escaped in output" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["nav"]),
               source_element("nav", "text-link", "root", %{
                 "text" => "Quote",
                 "link" => external_link("/path?a=1&b=2")
               })
             ])

    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ ~s(href="/path?a=1&amp;b=2")
  end

  test "attribute output ordering is deterministic for navigation metadata" do
    document = %DesignDocument{
      ir_version: DesignDocument.current_ir_version(),
      source_metadata: %{},
      token_set: %{},
      root_nodes: [
        DesignNode.new([1],
          semantic_type: "button",
          content: "Go",
          attributes: %{
            "navigation" => %{"href" => "https://example.test/go", "target" => "_blank"}
          },
          source_trace: %SourceTrace{
            source_type: "synthetic",
            source_id: "btn",
            source_path: "synthetic",
            source_name: "button",
            adapter: "test",
            adapter_version: "test",
            inference: "test"
          }
        )
      ],
      assets: %{},
      interactions: %{},
      diagnostics: [],
      provenance: %{}
    }

    assert {:ok, first} = Fidelity.generate(document)
    assert {:ok, second} = Fidelity.generate(document)
    assert first.heex == second.heex

    assert first.heex =~ ~s(href="https://example.test/go")
    assert first.heex =~ ~s(target="_blank")
    assert first.heex =~ ~s(rel="noopener noreferrer")
  end

  test "C-03 safe static attributes continue to work alongside navigation" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["nav"]),
               source_element("nav", "text-link", "root", %{
                 "text" => "Home",
                 "link" => external_link("/home"),
                 "ariaLabel" => "Home link"
               })
             ])

    node = node_by_source_id(document, "nav")
    assert node.attributes["aria-label"] == "Home link"

    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ ~s(aria-label="Home link")
    assert bundle.heex =~ ~s(href="/home")
  end

  test "C-02 external class resolution continues to work for navigation carriers" do
    source =
      Map.put(
        synthetic_source([
          source_element("root", "block", 0, %{}, ["nav"]),
          source_element("nav", "text-link", "root", %{
            "text" => "Home",
            "link" => external_link("/home"),
            "_cssGlobalClasses" => ["opaque-class-id"]
          })
        ]),
        "globalClasses",
        [%{"id" => "opaque-class-id", "name" => "synthetic-class", "settings" => %{}}]
      )

    authority = %{
      id: "synthetic-site-classes",
      global_classes: [
        %{"id" => "opaque-class-id", "name" => "synthetic-class", "settings" => %{}}
      ]
    }

    assert {:ok, document} =
             Bricks.to_ir(source,
               component_id: "component-a",
               token_set: token_set(),
               external_class_authorities: [authority]
             )

    node = node_by_source_id(document, "nav")
    assert "synthetic-class" in node.source_trace.source_classes

    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ "synthetic-class"
    assert bundle.heex =~ ~s(href="/home")
  end

  test "protocol-relative destinations are rejected and never emitted" do
    for href <- ["//example.test/path", " //example.test/path"] do
      assert LiveFrames.StaticNavigation.classify_destination(href) == :malformed

      assert {:ok, document} =
               to_ir([
                 source_element("root", "block", 0, %{}, ["nav"]),
                 source_element("nav", "text-link", "root", %{
                   "text" => "Bad",
                   "link" => external_link(href)
                 })
               ])

      refute node_by_source_id(document, "nav").attributes["navigation"]

      assert {:ok, bundle} = Fidelity.generate(document)
      refute bundle.heex =~ ~s(href="#{href}")
      refute bundle.heex =~ "//example.test"
    end
  end

  test "static settings.url alone does not authorize navigation" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["nav"]),
               source_element("nav", "text-link", "root", %{
                 "text" => "Home",
                 "url" => "/home"
               })
             ])

    node = node_by_source_id(document, "nav")
    assert node.attributes["url"] == "/home"
    refute node.attributes["navigation"]
    assert Enum.any?(document.diagnostics, &(&1.code == "bricks.navigation.missing"))

    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.heex =~ ~s(href="/home")
    assert bundle.heex =~ "<span"
  end

  test "unsupported link type with matching settings.url is rejected not duplicated" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["btn"]),
               source_element("btn", "button", "root", %{
                 "text" => "Go",
                 "link" => %{"type" => "internal", "url" => "/same"},
                 "url" => "/same"
               })
             ])

    refute node_by_source_id(document, "btn").attributes["navigation"]
    assert Enum.any?(document.diagnostics, &(&1.code == "bricks.navigation.rejected"))

    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.heex =~ ~s(href="/same")
  end

  test "heading with link object is unsupported carrier without href" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["title"]),
               source_element("title", "heading", "root", %{
                 "text" => "Title",
                 "link" => external_link("#")
               })
             ])

    assert Enum.any?(document.diagnostics, &(&1.code == "bricks.navigation.unsupported_carrier"))
    refute node_by_source_id(document, "title").attributes["navigation"]

    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.heex =~ ~s(href="#")
  end

  test "image link url mode does not become static navigation" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["logo"]),
               source_element("logo", "image", "root", %{
                 "link" => "url",
                 "url" => %{"type" => "meta", "useDynamicData" => "{site_url}"}
               })
             ])

    refute node_by_source_id(document, "logo").attributes["navigation"]
    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.heex =~ ~s(href=")
  end

  test "image lightbox link does not become static navigation" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["shot"]),
               source_element("shot", "image", "root", %{
                 "link" => "lightbox",
                 "image" => %{"url" => "https://example.test/x.jpg"}
               })
             ])

    refute node_by_source_id(document, "shot").attributes["navigation"]
    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.heex =~ "<a"
  end

  test "raw source tag a cannot bypass the navigation pipeline" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["nav"]),
               source_element("nav", "text-link", "root", %{
                 "text" => "Home",
                 "tag" => "a",
                 "link" => external_link("/home")
               })
             ])

    node = node_by_source_id(document, "nav")
    refute node.attributes["tag"] == "a"
    assert node.attributes["navigation"]["href"] == "/home"

    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ ~s(href="/home")
    assert bundle.heex =~ "<a"
  end

  test "accepted navigation does not store tag a in Design IR" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["btn"]),
               source_element("btn", "button", "root", %{
                 "text" => "Go",
                 "link" => external_link("/go")
               })
             ])

    node = node_by_source_id(document, "btn")
    assert node.attributes["navigation"]["href"] == "/go"
    refute node.attributes["tag"] == "a"
  end

  test "Fidelity rejects malicious navigation IR without emitting anchor markup" do
    document = %DesignDocument{
      ir_version: DesignDocument.current_ir_version(),
      source_metadata: %{},
      token_set: %{},
      root_nodes: [
        DesignNode.new([1],
          semantic_type: "link",
          content: "Bad",
          attributes: %{
            "tag" => "a",
            "navigation" => %{"href" => "javascript:alert(1)"}
          },
          source_trace: %SourceTrace{
            source_type: "synthetic",
            source_id: "nav",
            source_path: "synthetic",
            source_name: "text-link",
            adapter: "test",
            adapter_version: "test",
            inference: "test"
          }
        )
      ],
      assets: %{},
      interactions: %{},
      diagnostics: [],
      provenance: %{}
    }

    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ "<span"
    refute bundle.heex =~ "<a"
    refute bundle.heex =~ "javascript:"
    assert bundle.manifest["diagnostic_counts"]["warning"] > 0
  end

  test "Fidelity falls back to button when button navigation revalidation fails" do
    document = %DesignDocument{
      ir_version: DesignDocument.current_ir_version(),
      source_metadata: %{},
      token_set: %{},
      root_nodes: [
        DesignNode.new([1],
          semantic_type: "button",
          content: "Go",
          attributes: %{
            "tag" => "a",
            "navigation" => %{"href" => "data:text/html,bad"}
          },
          source_trace: %SourceTrace{
            source_type: "synthetic",
            source_id: "btn",
            source_path: "synthetic",
            source_name: "button",
            adapter: "test",
            adapter_version: "test",
            inference: "test"
          }
        )
      ],
      assets: %{},
      interactions: %{},
      diagnostics: [],
      provenance: %{}
    }

    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ "<button"
    assert bundle.heex =~ ~s(type="button")
    refute bundle.heex =~ "<a"
  end

  test "ordinary elements do not receive static_navigation provenance metadata" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["box"]),
               source_element("box", "div", "root", %{})
             ])

    node = node_by_source_id(document, "box")
    refute get_in(node.source_trace.metadata, ["static_navigation"])
  end

  test "Design IR version remains 1.0.0" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["nav"]),
               source_element("nav", "text-link", "root", %{
                 "text" => "Home",
                 "link" => external_link("/home")
               })
             ])

    assert document.ir_version == "1.0.0"
    assert IR.validate(document) == :ok
  end
end
