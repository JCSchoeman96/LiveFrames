defmodule LiveFrames.BricksIconAdmissionTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Fidelity
  alias LiveFrames.IR.Serializer
  alias LiveFrames.Tokens.TokenSet

  @dummy_url "https://example.test/synthetic-icon-ref.svg"
  @dummy_full "https://example.test/synthetic-icon-full.svg"
  @dummy_path "/var/www/synthetic/wp-content/uploads/icon-placeholder.svg"

  @expected_content %{
    "icon_contract_version" => "1",
    "source_shape" => "bricks.icon.library.svg.asset_ref",
    "library" => "svg",
    "embedding" => "bricks_icon_element",
    "is_placeholder" => true,
    "glyph" => nil
  }

  test "S1 standalone icon admits semantic_type icon with contract content" do
    document = to_ir(s1_icon_settings())
    [icon_node] = document.root_nodes

    assert icon_node.semantic_type == "icon"
    assert icon_node.content == @expected_content
  end

  test "S1 icon creates exactly one unresolved icon asset reference" do
    document = to_ir(s1_icon_settings())
    [icon_node] = document.root_nodes
    assert length(icon_node.asset_refs) == 1

    asset = Map.fetch!(document.assets, hd(icon_node.asset_refs))
    assert asset.kind == "icon"
    assert asset.status == :unresolved
    assert asset.uri == nil
    assert asset.alt == nil
  end

  test "icon asset metadata uses hashes only, not raw url full or path" do
    settings = s1_icon_settings()
    document = to_ir(settings)
    asset = Map.fetch!(document.assets, hd(hd(document.root_nodes).asset_refs))
    metadata = asset.metadata

    assert is_binary(metadata["url_hash"])
    assert is_binary(metadata["full_hash"])
    assert is_binary(metadata["path_hash"])
    refute Map.has_key?(metadata, "url")
    refute Map.has_key?(metadata, "full")
    refute Map.has_key?(metadata, "path")
    refute metadata["url_hash"] == @dummy_url
  end

  test "syntactically valid https URL does not resolve placeholder icon asset" do
    document =
      to_ir(
        s1_icon_settings(%{
          "url" => "https://example.test/icon.svg",
          "full" => "https://example.test/icon.svg",
          "path" => "/uploads/icon.svg"
        })
      )

    asset = Map.fetch!(document.assets, hd(hd(document.root_nodes).asset_refs))
    assert asset.status == :unresolved
    assert asset.uri == nil
    assert asset.metadata["resolution_reason"] == "evidence_insufficient_missing_geometry"
  end

  test "emits bricks.icon.asset_unresolved diagnostic with evidence_insufficient reason" do
    document = to_ir(s1_icon_settings())

    diagnostic =
      Enum.find(document.diagnostics, fn d -> d.code == "bricks.icon.asset_unresolved" end)

    assert diagnostic != nil
    assert diagnostic.metadata["resolution_reason"] == "evidence_insufficient_missing_geometry"
    assert diagnostic.metadata["source_shape"] == "bricks.icon.library.svg.asset_ref"
    assert diagnostic.metadata["is_placeholder"] == true
  end

  test "unknown standalone icon shape stays icon without fabricated asset or URI" do
    document =
      to_ir(%{
        "icon" => %{
          "library" => "fontawesome",
          "icon" => "fa-star"
        }
      })

    [icon_node] = document.root_nodes
    assert icon_node.semantic_type == "icon"
    assert icon_node.content == nil
    assert icon_node.asset_refs == []

    assert Enum.any?(document.diagnostics, &(&1.code == "bricks.icon.source_unrecognized"))
    refute Enum.any?(document.diagnostics, &(&1.code == "bricks.icon.asset_unresolved"))
  end

  test "normalization is deterministic for IR assets content metadata and diagnostics" do
    settings = s1_icon_settings()
    first = to_ir(settings)
    second = to_ir(settings)

    assert Serializer.encode!(first) == Serializer.encode!(second)
  end

  test "fidelity produces no glyph markup or leaked icon source strings" do
    document = to_ir(s1_icon_settings())
    assert {:ok, bundle} = Fidelity.generate(document)
    html = bundle.heex

    refute String.contains?(html, "<svg")
    refute String.contains?(html, "<path")
    refute String.contains?(html, "<i")
    refute String.contains?(html, @dummy_url)
    refute String.contains?(html, @dummy_path)
  end

  test "existing image assets remain kind image after icon admission path exists" do
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
              "settings" => %{
                "image" => %{
                  "id" => 42,
                  "filename" => "synthetic-image.webp",
                  "size" => "full",
                  "full" => "https://images.example.test/uploads/synthetic-original.webp",
                  "url" => "https://images.example.test/uploads/synthetic-original.webp"
                }
              }
            }
          ]
        }
      ],
      "globalClasses" => []
    }

    assert {:ok, document} =
             Bricks.to_ir(source, component_id: "component-a", token_set: TokenSet.new())

    [asset] = Map.values(document.assets)
    assert asset.kind == "image"
    assert asset.status == :resolved
  end

  defp s1_icon_settings(svg_overrides \\ %{}) do
    svg =
      Map.merge(
        %{
          "full" => @dummy_full,
          "url" => @dummy_url,
          "path" => @dummy_path,
          "isPlaceholder" => true
        },
        svg_overrides
      )

    %{
      "icon" => %{
        "library" => "svg",
        "svg" => svg
      }
    }
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
              "id" => "icon-1",
              "name" => "icon",
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
