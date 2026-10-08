defmodule LiveFrames.BricksAssetPipelineTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Tokens.TokenSet

  @large_uri "http://images.example.test:8443/uploads/synthetic-large.webp"
  @medium_uri "https://images.example.test/uploads/synthetic-medium.webp"
  @full_uri "https://images.example.test/uploads/synthetic-original.webp"

  test "resolves complete non-placeholder media identity using the selected rendition" do
    cases = [
      %{"size" => "large", "url" => @large_uri, "full" => @full_uri},
      %{"size" => "full", "url" => @full_uri, "full" => @full_uri},
      %{"size" => "medium", "url" => @medium_uri, "full" => @full_uri}
    ]

    for image_fields <- cases do
      document = to_ir(%{"image" => media_image(image_fields), "tag" => "picture"})
      [asset] = Map.values(document.assets)
      [image_node] = document.root_nodes

      assert document.ir_version == "3.0.0"
      assert asset.status == :resolved
      assert asset.kind == "image"
      assert asset.uri == image_fields["url"]
      assert asset.metadata["attachment_id"] == 42
      assert asset.metadata["filename"] == "synthetic-image.webp"
      assert asset.metadata["source_image"]["full"] == image_fields["full"]
      assert asset.metadata["resolution_reason"] == "resolved_static"
      assert asset.alt == nil
      assert image_node.attributes["tag"] == "picture"
      assert image_node.asset_refs == [asset.asset_id]
      assert asset.source_trace.inference =~ "media-backed Bricks image"
    end
  end

  test "placeholder image records stay unresolved even when their URIs are safe" do
    placeholder = %{
      "url" => @large_uri,
      "full" => @full_uri,
      "path" => "/uploads/synthetic-placeholder.webp",
      "isPlaceholder" => true
    }

    document = to_ir(%{"image" => placeholder})
    [asset] = Map.values(document.assets)

    assert asset.status == :unresolved
    assert asset.uri == nil
    assert asset.metadata["resolution_reason"] == "unresolved_placeholder"
    assert asset.metadata["source_image"] == placeholder

    assert Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.asset.unresolved" and
               diagnostic.metadata["resolution_reason"] == "unresolved_placeholder"
           end)
  end

  test "a valid URI alone does not establish media identity" do
    document = to_ir(%{"image" => %{"url" => @large_uri}})
    [asset] = Map.values(document.assets)

    assert asset.status == :unresolved
    assert asset.uri == nil
    assert asset.metadata["resolution_reason"] == "unresolved_missing"
    assert asset.metadata["url"] == @large_uri
  end

  test "a path remains provenance and never replaces a missing URL" do
    image = media_image(%{"url" => false, "path" => "/uploads/synthetic-image.webp"})
    document = to_ir(%{"image" => image})
    [asset] = Map.values(document.assets)

    assert asset.status == :unresolved
    assert asset.uri == nil
    assert asset.metadata["resolution_reason"] == "unresolved_missing"
    assert asset.metadata["source_image"]["path"] == "/uploads/synthetic-image.webp"
  end

  test "dynamic image declarations never become static assets" do
    image =
      media_image(%{
        "url" => @large_uri,
        "useDynamicData" => "{featured_image}"
      })

    document = to_ir(%{"image" => image})

    assert document.assets == %{}
    assert hd(document.root_nodes).asset_refs == []
    assert document.value_bindings == %{}

    assert Enum.any?(document.diagnostics, &(&1.code == "bricks.binding.evidence_insufficient"))

    refute Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.asset.unresolved" and
               diagnostic.metadata["resolution_reason"] == "unresolved_dynamic"
           end)
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

  test "requires a positive integer attachment ID and non-empty filename and size" do
    malformed_images = [
      media_image(%{"id" => 42.5}),
      media_image(%{"id" => "42"}),
      media_image(%{"filename" => 42}),
      media_image(%{"size" => []})
    ]

    for image <- malformed_images do
      document = to_ir(%{"image" => image})
      [asset] = Map.values(document.assets)

      assert asset.status == :unresolved
      assert asset.uri == nil
      assert asset.metadata["resolution_reason"] == "unresolved_malformed"
    end

    missing_id = media_image() |> Map.delete("id")
    document = to_ir(%{"image" => missing_id})
    [asset] = Map.values(document.assets)
    assert asset.status == :unresolved
    assert asset.metadata["resolution_reason"] == "unresolved_missing"
  end

  test "keeps unsafe and malformed source URI evidence out of AssetReference.uri" do
    for {url, resolution_reason} <- [
          {"javascript:alert(1)", "unresolved_unsafe"},
          {"//images.example.test/uploads/image.webp", "unresolved_unsafe"},
          {"images.example.test/uploads/image.webp", "unresolved_malformed"},
          {"/uploads/image.webp", "unresolved_malformed"},
          {"http://images.example.test:70000/uploads/image.webp", "unresolved_malformed"}
        ] do
      image = media_image(%{"url" => url})
      document = to_ir(%{"image" => image})
      [asset] = Map.values(document.assets)

      assert asset.status == :unresolved
      assert asset.uri == nil
      assert asset.metadata["url"] == url
      assert asset.metadata["resolution_reason"] == resolution_reason
      assert Enum.any?(document.diagnostics, &(&1.code == "bricks.asset.unresolved"))
    end
  end

  test "validates full independently without requiring it to equal the selected URL" do
    document =
      to_ir(%{
        "image" =>
          media_image(%{
            "url" => @large_uri,
            "full" => "javascript:alert(1)"
          })
      })

    [asset] = Map.values(document.assets)

    assert asset.status == :unresolved
    assert asset.uri == nil
    assert asset.metadata["resolution_reason"] == "unresolved_unsafe"
  end

  test "preserves responsive source evidence and reports it as unsupported" do
    responsive_sources = [
      %{
        "id" => "source-mobile",
        "breakpoint" => "mobile_portrait",
        "image" => media_image(%{"size" => "medium", "url" => @medium_uri})
      }
    ]

    document =
      to_ir(%{
        "image" => media_image(%{"size" => "large", "url" => @large_uri}),
        "sources" => responsive_sources
      })

    [asset] = Map.values(document.assets)
    diagnostic = Enum.find(document.diagnostics, &(&1.code == "bricks.asset.sources_unsupported"))

    assert map_size(document.assets) == 1
    assert asset.status == :resolved
    assert asset.uri == @large_uri
    assert asset.source_trace.source_settings["sources"] == responsive_sources
    assert diagnostic.severity == :warning
    assert diagnostic.metadata["source_count"] == 1
  end

  test "does not infer Bricks alt from unproven image or settings fields" do
    image_alt = to_ir(%{"image" => media_image(%{"alt" => "Synthetic alt"})})
    settings_alt = to_ir(%{"image" => media_image(), "alt" => "Synthetic alt"})
    empty_alt = to_ir(%{"image" => media_image(%{"alt" => ""})})

    assert Enum.map([image_alt, settings_alt, empty_alt], fn document ->
             hd(Map.values(document.assets)).alt
           end) == [nil, nil, nil]
  end

  test "generic Bricks _attributes src and srcset remain outside the asset pipeline" do
    document =
      to_ir(%{
        "image" => media_image(),
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

  test "allocates one deterministic asset reference per primary image source" do
    source = %{"image" => media_image()}
    first = to_ir(source)
    second = to_ir(source)

    assert map_size(first.assets) == 1
    assert first.root_nodes |> hd() |> Map.fetch!(:asset_refs) == ["asset_000001"]
    assert first.assets == second.assets
  end

  defp media_image(overrides \\ %{}) do
    Map.merge(
      %{
        "id" => 42,
        "filename" => "synthetic-image.webp",
        "size" => "full",
        "full" => @full_uri,
        "url" => @full_uri
      },
      overrides
    )
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
