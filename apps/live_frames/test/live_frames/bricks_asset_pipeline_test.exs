defmodule LiveFrames.BricksAssetPipelineTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Tokens.TokenSet

  @image_uri "http://images.example.test:8443/uploads/synthetic-image.webp"

  test "normalizes one corpus-shaped static image URI as a resolved asset" do
    source_image = %{
      "url" => @image_uri,
      "full" => @image_uri,
      "path" => "/uploads/synthetic-image.webp",
      "isPlaceholder" => true
    }

    document = to_ir(%{"image" => source_image, "tag" => "picture"})
    [asset] = Map.values(document.assets)
    [image_node] = document.root_nodes

    assert document.ir_version == "1.0.0"
    assert asset.status == :resolved
    assert asset.kind == "image"
    assert asset.uri == @image_uri
    assert asset.metadata["url"] == @image_uri
    assert asset.metadata["source_image"]["full"] == @image_uri
    assert asset.metadata["resolution_reason"] == "resolved_static"
    assert image_node.attributes["tag"] == "picture"
    assert image_node.asset_refs == [asset.asset_id]
    assert asset.source_trace.inference =~ "static image URI"
  end

  test "retains dynamic image-mode evidence as one unresolved asset" do
    document =
      to_ir(%{
        "image" => %{"size" => "full", "useDynamicData" => "{featured_image}"}
      })

    [asset] = Map.values(document.assets)

    assert asset.status == :unresolved
    assert asset.uri == nil
    assert asset.metadata["resolution_reason"] == "unresolved_dynamic"
    assert asset.metadata["source_image"]["useDynamicData"] == "{featured_image}"
  end

  test "keeps missing and non-string image URLs unresolved" do
    image_values = [
      %{"url" => false},
      %{"url" => nil},
      %{},
      nil,
      false,
      :missing
    ]

    for image_value <- image_values do
      settings = if image_value == :missing, do: %{}, else: %{"image" => image_value}
      document = to_ir(settings)

      assert map_size(document.assets) == 1
      [asset] = Map.values(document.assets)
      assert asset.status == :unresolved
      assert asset.uri == nil
      assert asset.metadata["resolution_reason"] == "unresolved_missing"
      assert hd(document.root_nodes).asset_refs == [asset.asset_id]
    end
  end

  test "keeps unsafe and malformed source URI evidence out of AssetReference.uri" do
    for {url, resolution_reason} <- [
          {"javascript:alert(1)", "unresolved_unsafe"},
          {"//images.example.test/uploads/image.webp", "unresolved_unsafe"},
          {"images.example.test/uploads/image.webp", "unresolved_malformed"},
          {"http://images.example.test:70000/uploads/image.webp", "unresolved_malformed"}
        ] do
      document = to_ir(%{"image" => %{"id" => 77, "url" => url}})
      [asset] = Map.values(document.assets)

      assert asset.status == :unresolved
      assert asset.uri == nil
      assert asset.metadata["url"] == url
      assert asset.metadata["resolution_reason"] == resolution_reason
      assert Enum.any?(document.diagnostics, &(&1.code == "bricks.asset.unresolved"))
    end
  end

  test "does not choose between conflicting full and URL image candidates" do
    document =
      to_ir(%{
        "image" => %{
          "url" => @image_uri,
          "full" => "https://images.example.test/uploads/other-image.webp"
        }
      })

    [asset] = Map.values(document.assets)
    assert asset.status == :unresolved
    assert asset.uri == nil
    assert asset.metadata["resolution_reason"] == "unresolved_malformed"
  end

  test "generic Bricks _attributes src and srcset remain outside the asset pipeline" do
    document =
      to_ir(%{
        "image" => %{"url" => @image_uri},
        "_attributes" => [
          %{"name" => "src", "value" => "javascript:alert(1)"},
          %{"name" => "srcset", "value" => "javascript:alert(1) 1x"}
        ]
      })

    image_node = hd(document.root_nodes)
    assert image_node.asset_refs == ["asset_000001"]
    refute Map.has_key?(image_node.attributes, "src")
    refute Map.has_key?(image_node.attributes, "srcset")
    assert Enum.any?(document.diagnostics, &(&1.code == "bricks.attribute.unsupported"))
  end

  test "uses a lone explicit alt value without inventing a source precedence" do
    image_alt = to_ir(%{"image" => %{"url" => @image_uri, "alt" => "Image alt"}})
    settings_alt = to_ir(%{"image" => %{"url" => @image_uri}, "alt" => "Image alt"})

    equal_alts =
      to_ir(%{"image" => %{"url" => @image_uri, "alt" => "Image alt"}, "alt" => "Image alt"})

    assert Enum.map([image_alt, settings_alt, equal_alts], fn document ->
             hd(Map.values(document.assets)).alt
           end) == ["Image alt", "Image alt", "Image alt"]
  end

  test "omits a conflicting pair of alt values instead of choosing one" do
    document =
      to_ir(%{
        "image" => %{"url" => @image_uri, "alt" => "Image alt"},
        "alt" => "Different alt"
      })

    [asset] = Map.values(document.assets)

    assert asset.status == :resolved
    assert asset.alt == nil
    assert asset.metadata["alt_resolution"] == "conflicting_source_values"
  end

  test "allocates one deterministic asset reference per image source" do
    source = %{"image" => %{"url" => @image_uri}}
    first = to_ir(source)
    second = to_ir(source)

    assert map_size(first.assets) == 1
    assert first.root_nodes |> hd() |> Map.fetch!(:asset_refs) == ["asset_000001"]
    assert first.assets == second.assets
  end

  defp to_ir(settings) do
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

    document
  end
end
