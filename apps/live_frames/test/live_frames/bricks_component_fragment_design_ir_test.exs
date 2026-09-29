defmodule LiveFrames.BricksComponentFragmentDesignIRTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.IR
  alias LiveFrames.IR.StyleValue

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

  defp fragment_source(components) do
    %{
      "components" => components,
      "globalClasses" => []
    }
  end

  defp fragment_component(id, elements) do
    %{
      "id" => id,
      "name" => "Synthetic fragment component",
      "category" => "section",
      "_version" => "7.8.9",
      "elements" => elements
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

  defp flatten(nodes), do: Enum.flat_map(nodes, &[&1 | flatten(&1.children)])

  defp node_by_source_id(document, source_id) do
    Enum.find(flatten(document.root_nodes), fn node ->
      node.source_trace.source_id == source_id
    end)
  end

  test "admits one component fragment without copied-envelope provenance" do
    source =
      fragment_source([
        fragment_component("fragment-a", [source_element("root-a", "div", 0, %{})])
      ])

    bytes = Jason.encode!(source)

    assert {:ok, document} =
             Bricks.to_ir(bytes,
               source_label: "synthetic-fragment.json",
               token_set: token_set()
             )

    metadata = document.source_metadata
    source_hash = :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

    assert metadata["source_shape"] == "component_fragment"
    assert metadata["source"] == nil
    assert metadata["source_url"] == nil
    assert metadata["payload_version"] == nil
    assert metadata["source_label"] == "synthetic-fragment.json"
    assert metadata["source_hash"] == source_hash

    assert metadata["component_id"] == "fragment-a"
    assert metadata["component_name"] == "Synthetic fragment component"
    assert metadata["component_category"] == "section"
    assert metadata["component_version"] == "7.8.9"
    assert metadata["source_element_count"] == 1
    assert metadata["root_count"] == 1
    assert metadata["source_order"] == ["root-a"]
    assert metadata["component_proxy_id"] == nil
    assert metadata["component_proxy_name"] == nil
    assert metadata["component_proxy_label"] == nil

    assert document.provenance["source_shape"] == "component_fragment"
    assert document.provenance["source_of_truth"] == "structured_bricks_source_model"

    assert node_by_source_id(document, "root-a").source_trace.source_path ==
             "components[0].elements[0]"

    refute metadata["source"] == "bricksCopiedElements"
    refute Map.has_key?(metadata, "bricks_version")
  end

  test "uses the requested component from a multi-component fragment" do
    source =
      fragment_source([
        fragment_component("fragment-a", [source_element("root-a", "div", 0, %{})]),
        fragment_component("fragment-b", [source_element("root-b", "section", 0, %{})])
      ])

    assert {:ok, document} =
             Bricks.to_ir(source,
               component_id: "fragment-b",
               token_set: token_set()
             )

    assert document.source_metadata["component_id"] == "fragment-b"
    assert node_by_source_id(document, "root-a") == nil

    assert node_by_source_id(document, "root-b").source_trace.source_path ==
             "components[1].elements[0]"
  end

  test "rejects a multi-component fragment when selection is omitted" do
    source =
      fragment_source([
        fragment_component("fragment-a", [source_element("root-a", "div", 0, %{})]),
        fragment_component("fragment-b", [source_element("root-b", "section", 0, %{})])
      ])

    assert {:error, diagnostics} = Bricks.to_ir(source, token_set: token_set())
    assert Enum.any?(diagnostics, &(&1.code == "bricks.component.ambiguous"))
  end

  test "rejects an explicitly requested component that is absent" do
    source =
      fragment_source([
        fragment_component("fragment-a", [source_element("root-a", "div", 0, %{})])
      ])

    assert {:error, diagnostics} =
             Bricks.to_ir(source,
               component_id: "missing",
               token_set: token_set()
             )

    assert Enum.any?(diagnostics, &(&1.code == "bricks.component.missing"))
  end

  test "preserves an unresolved responsive fragment value without numeric authority" do
    source =
      fragment_source([
        fragment_component("fragment-a", [
          source_element("root-a", "div", 0, %{"_width:mobile_landscape" => "100%"})
        ])
      ])

    assert {:ok, document} = Bricks.to_ir(source, token_set: token_set())

    override = node_by_source_id(document, "root-a").responsive["mobile_landscape"]

    assert override.breakpoint_id == "mobile_landscape"
    assert override.source_name == "mobile_landscape"
    assert override.min_width == nil
    assert override.max_width == nil
    assert override.resolution_status == :unresolved
    assert %StyleValue{kind: :literal, value: "100%"} = override.styles["width"]

    assert override.source_trace.source_path ==
             "components[0].elements[0].settings._width:mobile_landscape"
  end

  test "keeps a fragment variable unresolved when VariableAuthority has no candidate" do
    source =
      fragment_source([
        fragment_component("fragment-a", [
          source_element("root-a", "div", 0, %{"_width:mobile_landscape" => "var(--grid-1)"})
        ])
      ])

    assert {:ok, document} = Bricks.to_ir(source, token_set: token_set())

    assert %StyleValue{
             kind: :unresolved,
             value: "var(--grid-1)",
             metadata: %{
               "source_variable" => "--grid-1",
               "resolution_reason" => "mapping_unproven",
               "authority_state" => "no_authority",
               "candidate_paths" => []
             }
           } =
             node_by_source_id(document, "root-a").responsive["mobile_landscape"].styles["width"]
  end

  test "serializes the same fragment bytes deterministically" do
    source =
      fragment_source([
        fragment_component("fragment-a", [source_element("root-a", "div", 0, %{})])
      ])

    bytes = Jason.encode!(source)
    tokens = token_set()

    assert {:ok, first} = Bricks.to_ir(bytes, token_set: tokens)
    assert {:ok, second} = Bricks.to_ir(bytes, token_set: tokens)
    assert IR.encode!(first) == IR.encode!(second)
  end
end
