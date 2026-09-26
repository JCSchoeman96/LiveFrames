defmodule LiveFrames.FidelityAssetTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Fidelity
  alias LiveFrames.IR.AssetReference
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.Tokens.TokenSet

  @image_uri "https://images.example.test/uploads/synthetic-image.webp"

  test "renders a validated inner image while the wrapper retains source classes" do
    document = image_document(%{"url" => @image_uri, "alt" => "A & < \"view\""})
    assert {:ok, bundle} = Fidelity.generate(document)

    assert bundle.heex =~ "<figure class=\"lf-fidelity-node-000001 source-frame\">"

    assert bundle.heex =~
             "<img src=\"#{@image_uri}\" alt=\"A &amp; &lt; &quot;view&quot;\">"

    refute bundle.heex =~ "class=\"lf-fidelity-node-000001 source-frame\"><img class="
  end

  test "preserves explicit empty alt and omits alt when source evidence is absent" do
    empty_alt = image_document(%{"url" => @image_uri, "alt" => ""})
    no_alt = image_document(%{"url" => @image_uri})

    assert {:ok, empty_bundle} = Fidelity.generate(empty_alt)
    assert empty_bundle.heex =~ "<img src=\"#{@image_uri}\" alt=\"\">"

    assert {:ok, no_alt_bundle} = Fidelity.generate(no_alt)
    assert no_alt_bundle.heex =~ "<img src=\"#{@image_uri}\">"
    refute no_alt_bundle.heex =~ "alt=\""
  end

  test "preserves the picture wrapper around one validated image" do
    document = image_document(%{"url" => @image_uri}, %{"tag" => "picture"})

    assert {:ok, bundle} = Fidelity.generate(document)

    assert bundle.heex =~
             "<picture class=\"lf-fidelity-node-000001 source-frame\"><img src=\"#{@image_uri}\"></picture>"

    refute bundle.heex =~ "<source"
    refute bundle.heex =~ "srcset="
  end

  test "unsafe, dynamic, malformed, and query-backed sources stay placeholders" do
    image_values = [
      %{"url" => "javascript:alert(1)"},
      %{"useDynamicData" => "{featured_image}"},
      %{"url" => "images.example.test/uploads/image.webp"},
      %{"url" => "//images.example.test/uploads/image.webp"},
      %{"url" => "https://images.example.test/uploads\\image.webp"},
      %{"url" => "https://images.example.test/uploads/image.webp?size=large"}
    ]

    for image <- image_values do
      assert {:ok, bundle} = Fidelity.generate(image_document(image))
      assert bundle.heex =~ "data-lf-asset-status=\"unresolved\""
      refute bundle.heex =~ "<img"
      refute bundle.heex =~ "src=\""
      refute bundle.heex =~ "javascript:"
      refute bundle.heex =~ "srcset="
    end
  end

  test "revalidates manually constructed resolved assets before emitting src" do
    document = image_document(%{"url" => @image_uri})
    [asset_id] = hd(document.root_nodes).asset_refs
    %AssetReference{} = asset = Map.fetch!(document.assets, asset_id)
    unsafe_asset = %{asset | status: :resolved, uri: "javascript:alert(1)"}
    document = %{document | assets: Map.put(document.assets, asset_id, unsafe_asset)}

    assert {:ok, bundle} = Fidelity.generate(document)

    assert bundle.heex =~ "data-lf-asset-status=\"unresolved\""
    assert bundle.heex =~ "data-lf-asset-id=\"#{asset_id}\""
    refute bundle.heex =~ "<img"
    refute bundle.heex =~ "src=\"javascript:"
    assert bundle.manifest["diagnostic_counts"]["warning"] >= 2
  end

  test "keeps unresolved assets as placeholders and omits them only when resolved" do
    unresolved = image_document(%{"useDynamicData" => "{featured_image}"})
    resolved = image_document(%{"url" => @image_uri})

    assert {:ok, unresolved_bundle} = Fidelity.generate(unresolved)
    assert unresolved_bundle.heex =~ "data-lf-asset-status=\"unresolved\""
    assert unresolved_bundle.heex =~ "data-lf-asset-id=\"asset_000001\""
    refute unresolved_bundle.heex =~ "src=\""

    assert [%{"status" => "unresolved"}] =
             unresolved_bundle.manifest["asset_substitutions"]

    assert {:ok, resolved_bundle} = Fidelity.generate(resolved)
    assert resolved_bundle.heex =~ "<img src=\"#{@image_uri}\">"
    assert resolved_bundle.manifest["asset_substitutions"] == []
  end

  test "does not choose among multiple malformed image references" do
    document = image_document(%{"url" => @image_uri})
    [asset_id] = hd(document.root_nodes).asset_refs
    %AssetReference{} = asset = Map.fetch!(document.assets, asset_id)
    second_asset = %AssetReference{asset | asset_id: "asset_second"}
    %DesignNode{} = image_node = hd(document.root_nodes)
    image_node = %DesignNode{image_node | asset_refs: [asset_id, "asset_second"]}

    document = %{
      document
      | root_nodes: [image_node],
        assets: Map.put(document.assets, "asset_second", second_asset)
    }

    assert {:ok, bundle} = Fidelity.generate(document)

    refute bundle.heex =~ "<img"
    assert bundle.heex =~ "data-lf-asset-status=\"unresolved\""
    assert bundle.manifest["diagnostic_counts"]["warning"] >= 2

    assert [%{"status" => "unresolved", "asset_id" => nil}] =
             bundle.manifest["asset_substitutions"]
  end

  test "image URL and lightbox link modes do not create navigation anchors" do
    for link_mode <- ["url", "lightbox"] do
      document =
        image_document(%{"url" => @image_uri}, %{
          "link" => link_mode,
          "url" => "https://example.test/"
        })

      assert {:ok, bundle} = Fidelity.generate(document)
      refute bundle.heex =~ "<a "
      assert bundle.heex =~ "<img src=\"#{@image_uri}\">"
    end
  end

  test "generic source src and srcset values cannot replace the asset pipeline" do
    document = image_document(%{"url" => @image_uri})
    %DesignNode{} = image_node = hd(document.root_nodes)

    image_node = %DesignNode{
      image_node
      | attributes:
          Map.merge(image_node.attributes, %{
            "src" => "javascript:alert(1)",
            "srcset" => "javascript:alert(1) 1x"
          })
    }

    assert {:ok, bundle} = Fidelity.generate(%{document | root_nodes: [image_node]})
    assert bundle.heex =~ "<img src=\"#{@image_uri}\">"
    refute bundle.heex =~ "javascript:"
    refute bundle.heex =~ "srcset="
  end

  defp image_document(image, extra_settings \\ %{}) do
    settings = Map.merge(%{"image" => image, "tag" => "figure"}, extra_settings)

    source = %{
      "source" => "bricksCopiedElements",
      "sourceUrl" => "https://example.test/export.json",
      "version" => "2.3.1",
      "content" => [%{"id" => "proxy-a", "cid" => "component-a", "label" => "Synthetic"}],
      "components" => [
        %{
          "id" => "component-a",
          "elements" => [
            %{
              "id" => "image-1",
              "name" => "image",
              "parent" => 0,
              "children" => [],
              "settings" => settings
            }
          ]
        }
      ],
      "globalClasses" => []
    }

    assert {:ok, document} =
             Bricks.to_ir(source, component_id: "component-a", token_set: TokenSet.new())

    [node] = document.root_nodes
    node = %{node | source_trace: %{node.source_trace | source_classes: ["source-frame"]}}
    %{document | root_nodes: [node]}
  end
end
