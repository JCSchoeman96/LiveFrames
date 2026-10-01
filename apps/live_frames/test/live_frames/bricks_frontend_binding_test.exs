defmodule LiveFrames.BricksFrontendBindingTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Fidelity
  alias LiveFrames.IR.CollectionBinding
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.ValueBinding

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
      "components" => [%{"id" => "component-a", "elements" => elements}],
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

  defp query_settings(has_loop, query \\ %{"post_type" => ["post"]}) do
    %{"query" => query, "hasLoop" => has_loop}
  end

  defp diagnostic_codes(document), do: Enum.map(document.diagnostics, & &1.code)

  defp binding_for(document, source_id) do
    Enum.find(Map.values(document.value_bindings), fn binding ->
      binding.source_trace.source_id == source_id
    end)
  end

  defp loop_with_target(target_id, target_name, target_settings) do
    [
      source_element("loop", "block", 0, query_settings(true), [target_id]),
      source_element(target_id, target_name, "loop", target_settings)
    ]
  end

  defp flatten(nodes), do: Enum.flat_map(nodes, &[&1 | flatten(&1.children)])

  defp node_by_source_id(document, source_id) do
    Enum.find(flatten(document.root_nodes), &(&1.source_trace.source_id == source_id))
  end

  test "admits a query owner with hasLoop and a structurally linked child" do
    assert {:ok, document} =
             to_ir([
               source_element(
                 "loop-owner",
                 "block",
                 0,
                 %{
                   "query" => %{
                     "post_type" => ["post"],
                     "tax_query" => [%{"taxonomy" => "category"}],
                     "disable_query_merge" => true
                   },
                   "hasLoop" => true
                 },
                 ["child"]
               ),
               source_element("child", "text-basic", "loop-owner", %{"text" => "Static"})
             ])

    assert %{"cb_node_000001" => %CollectionBinding{} = binding} = document.collection_bindings
    assert binding.collection_binding_id == "cb_#{DesignNode.deterministic_id([1])}"
    assert binding.owner_node_id == DesignNode.deterministic_id([1])
    assert binding.repeat_root_node_id == binding.owner_node_id
    assert binding.parent_collection_binding_id == nil
    assert binding.normalization_status == :normalized
    assert binding.source_trace.source_id == "loop-owner"
    assert binding.source_trace.source_path =~ ".settings.query"
    assert binding.source_trace.adapter == "bricks"
    assert binding.source_trace.adapter_version == "1.0.0"
    assert binding.source_trace.source_settings["hasLoop"] == true
    assert binding.source_trace.source_settings["query"]["post_type"] == ["post"]

    assert binding.source_trace.source_settings["query"]["tax_query"] == [
             %{"taxonomy" => "category"}
           ]

    assert binding.source_trace.source_settings["query"]["disable_query_merge"] == true
    assert binding.source_trace.inference =~ "repeat boundary"

    refute Enum.any?(document.diagnostics, &(&1.code == "bricks.runtime.unsupported"))
  end

  test "does not admit a query owner without an exact true hasLoop flag" do
    assert {:ok, document} =
             to_ir([
               source_element("owner", "block", 0, query_settings(false), ["child"]),
               source_element("child", "text-basic", "owner", %{"text" => "Static"})
             ])

    assert document.collection_bindings == %{}
    assert "bricks.collection.boundary_unproven" in diagnostic_codes(document)

    refute Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.runtime.unsupported" and
               diagnostic.source_trace.source_id == "owner"
           end)
  end

  test "does not admit a true loop owner without a linked child" do
    assert {:ok, document} =
             to_ir([source_element("owner", "block", 0, query_settings(true))])

    assert document.collection_bindings == %{}
    assert "bricks.collection.boundary_unproven" in diagnostic_codes(document)
  end

  test "query-like owners with a missing or non-object query retain boundary diagnostics" do
    for {owner_id, settings} <- [
          {"missing-query", %{"hasLoop" => true}},
          {"invalid-query", %{"query" => [%{"post_type" => "post"}], "hasLoop" => true}}
        ] do
      assert {:ok, document} =
               to_ir([
                 source_element(owner_id, "block", 0, settings, ["child"]),
                 source_element("child", "text-basic", owner_id, %{})
               ])

      assert document.collection_bindings == %{}
      assert "bricks.collection.boundary_unproven" in diagnostic_codes(document)

      refute Enum.any?(document.diagnostics, fn diagnostic ->
               diagnostic.code == "bricks.runtime.unsupported" and
                 diagnostic.source_trace.source_id == owner_id and
                 diagnostic.metadata["source_path"] == "settings.query"
             end)
    end
  end

  test "nested collections parent to the nearest admitted ancestor" do
    assert {:ok, document} =
             to_ir([
               source_element("outer", "block", 0, query_settings(true), ["middle"]),
               source_element(
                 "middle",
                 "div",
                 "outer",
                 query_settings(false),
                 ["inner"]
               ),
               source_element("inner", "block", "middle", query_settings(true), ["child"]),
               source_element("child", "text-basic", "inner", %{"text" => "Static"})
             ])

    outer = document.collection_bindings["cb_node_000001"]
    inner = document.collection_bindings["cb_node_000001_000001_000001"]

    assert outer.parent_collection_binding_id == nil
    assert inner.parent_collection_binding_id == outer.collection_binding_id
    assert map_size(document.collection_bindings) == 2

    assert Enum.count(document.diagnostics, &(&1.code == "bricks.collection.boundary_unproven")) ==
             1
  end

  test "sibling collections have independent nil parents" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["first", "second"]),
               source_element("first", "block", "root", query_settings(true), ["first-child"]),
               source_element("first-child", "text-basic", "first", %{}),
               source_element("second", "block", "root", query_settings(true), ["second-child"]),
               source_element("second-child", "text-basic", "second", %{})
             ])

    assert document.collection_bindings["cb_node_000001_000001"].parent_collection_binding_id ==
             nil

    assert document.collection_bindings["cb_node_000001_000002"].parent_collection_binding_id ==
             nil
  end

  test "post title maps to collection item content.title and clears static content" do
    assert {:ok, document} =
             to_ir(loop_with_target("title", "heading", %{"text" => "{post_title}"}))

    assert %ValueBinding{} = binding = binding_for(document, "title")
    assert binding.target_node_id == DesignNode.deterministic_id([1, 1])
    assert binding.value_binding_id == "vb_#{binding.target_node_id}_text_000001"
    assert binding.target_kind == :text
    assert binding.value_kind == :field
    assert binding.scope == :collection_item
    assert binding.value_key == "content.title"
    assert binding.collection_binding_id == "cb_#{DesignNode.deterministic_id([1])}"
    assert binding.modifier_status == :none
    assert binding.normalization_status == :normalized
    assert node_by_source_id(document, "title").content == nil
    assert binding.source_trace.source_path =~ ".settings.text"
    assert binding.source_trace.adapter == "bricks"
    assert binding.source_trace.adapter_version == "1.0.0"
    assert binding.source_trace.source_settings == %{"text" => "{post_title}"}
    assert binding.source_trace.metadata["raw_expression"] == "{post_title}"
    assert binding.source_trace.inference =~ "content.title"
  end

  test "exact post content maps to collection item content.body" do
    assert {:ok, document} =
             to_ir(loop_with_target("body", "text-basic", %{"text" => "{post_content}"}))

    assert %ValueBinding{} = binding = binding_for(document, "body")
    assert binding.value_key == "content.body"
    assert binding.scope == :collection_item
    assert binding.normalization_status == :normalized
    assert node_by_source_id(document, "body").content == nil
  end

  test "opaque post content modifier keeps a diagnostic binding and clears content" do
    assert {:ok, document} =
             to_ir(loop_with_target("body", "text-basic", %{"text" => "{post_content:16}"}))

    assert %ValueBinding{} = binding = binding_for(document, "body")
    assert binding.value_key == "content.body"
    assert binding.modifier_status == :opaque
    assert binding.normalization_status == :evidence_insufficient
    assert node_by_source_id(document, "body").content == nil
    assert "bricks.binding.evidence_insufficient" in diagnostic_codes(document)
  end

  test "known collection item text without collection context has no binding" do
    assert {:ok, document} =
             to_ir([source_element("title", "heading", 0, %{"text" => "{post_title}"})])

    assert document.value_bindings == %{}
    assert node_by_source_id(document, "title").content == nil
    assert "bricks.binding.evidence_insufficient" in diagnostic_codes(document)
  end

  test "post content without collection context has no binding and clears content" do
    assert {:ok, document} =
             to_ir([source_element("body", "text-basic", 0, %{"text" => "{post_content}"})])

    assert document.value_bindings == %{}
    assert node_by_source_id(document, "body").content == nil
    assert "bricks.binding.evidence_insufficient" in diagnostic_codes(document)
  end

  test "query-only nested owner leaves descendant text in the outer collection scope" do
    assert {:ok, document} =
             to_ir([
               source_element("outer", "block", 0, query_settings(true), ["query-only"]),
               source_element(
                 "query-only",
                 "div",
                 "outer",
                 query_settings(false),
                 ["title"]
               ),
               source_element("title", "heading", "query-only", %{"text" => "{post_title}"})
             ])

    assert map_size(document.collection_bindings) == 1
    assert %ValueBinding{} = binding_for(document, "title")
    assert binding_for(document, "title").collection_binding_id == "cb_node_000001"
  end

  test "featured image maps to media.primary without an asset reference" do
    assert {:ok, document} =
             to_ir(
               loop_with_target("image", "image", %{
                 "image" => %{"useDynamicData" => "{featured_image}"}
               })
             )

    assert %ValueBinding{} = binding = binding_for(document, "image")
    assert binding.target_kind == :asset
    assert binding.value_kind == :field
    assert binding.scope == :collection_item
    assert binding.value_key == "media.primary"
    assert binding.collection_binding_id == "cb_node_000001"
    assert document.assets == %{}
    assert node_by_source_id(document, "image").asset_refs == []

    refute Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.asset.unresolved" and
               diagnostic.metadata["resolution_reason"] == "unresolved_dynamic"
           end)

    refute Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.runtime.unsupported" and
               diagnostic.source_trace.source_id == "image"
           end)
  end

  test "post ID on a dynamic image is evidence-insufficient and creates no asset" do
    assert {:ok, document} =
             to_ir(
               loop_with_target("image", "image", %{"image" => %{"useDynamicData" => "{post_id}"}})
             )

    assert binding_for(document, "image") == nil
    assert document.assets == %{}
    assert node_by_source_id(document, "image").asset_refs == []
    assert "bricks.binding.evidence_insufficient" in diagnostic_codes(document)

    refute Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.runtime.unsupported" and
               diagnostic.source_trace.source_id == "image"
           end)

    refute Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.asset.unresolved" and
               diagnostic.metadata["resolution_reason"] == "unresolved_dynamic"
           end)
  end

  test "featured image without collection context has no value or static asset" do
    assert {:ok, document} =
             to_ir([
               source_element(
                 "image",
                 "image",
                 0,
                 %{"image" => %{"useDynamicData" => "{featured_image}"}}
               )
             ])

    assert document.value_bindings == %{}
    assert document.assets == %{}
    assert node_by_source_id(document, "image").asset_refs == []
    assert "bricks.binding.evidence_insufficient" in diagnostic_codes(document)
  end

  test "unknown dynamic image expression fails closed without an asset" do
    assert {:ok, document} =
             to_ir(
               loop_with_target(
                 "image",
                 "image",
                 %{"image" => %{"useDynamicData" => "{unknown_image}"}}
               )
             )

    assert binding_for(document, "image") == nil
    assert document.assets == %{}
    assert node_by_source_id(document, "image").asset_refs == []
    assert "bricks.binding.expression_unsupported" in diagnostic_codes(document)

    refute Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.runtime.unsupported" and
               diagnostic.source_trace.source_id == "image"
           end)

    refute Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.asset.unresolved" and
               diagnostic.metadata["resolution_reason"] == "unresolved_dynamic"
           end)
  end

  test "dynamic image classification preserves unrelated asset diagnostics" do
    assert {:ok, document} =
             to_ir([
               source_element(
                 "image",
                 "image",
                 0,
                 %{
                   "image" => %{"useDynamicData" => "{featured_image}"},
                   "sources" => [%{"media" => "(min-width: 40rem)"}],
                   "caption" => "custom"
                 }
               )
             ])

    assert document.assets == %{}
    assert "bricks.asset.sources_unsupported" in diagnostic_codes(document)
    assert "bricks.asset.caption_unsupported" in diagnostic_codes(document)

    refute Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.asset.unresolved" and
               diagnostic.metadata["resolution_reason"] == "unresolved_dynamic"
           end)
  end

  test "site URL maps to a site-scoped link URL and removes the generic URL object" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["link"]),
               source_element(
                 "link",
                 "text-link",
                 "root",
                 %{
                   "text" => "Site",
                   "url" => %{"type" => "meta", "useDynamicData" => "{site_url}"}
                 }
               )
             ])

    assert %ValueBinding{} = binding = binding_for(document, "link")
    assert binding.target_kind == :link_url
    assert binding.value_kind == :field
    assert binding.scope == :site
    assert binding.value_key == "site.url"
    assert binding.collection_binding_id == nil
    assert Map.has_key?(node_by_source_id(document, "link").attributes, "url") == false
    assert node_by_source_id(document, "link").attributes["navigation"] == nil
    refute "bricks.runtime.unsupported" in diagnostic_codes(document)
    refute "bricks.navigation.dynamic" in diagnostic_codes(document)
  end

  test "unknown dynamic URL removes the raw URL object and emits no binding" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["link"]),
               source_element(
                 "link",
                 "text-link",
                 "root",
                 %{
                   "text" => "Site",
                   "url" => %{"useDynamicData" => "{unknown_url}"}
                 }
               )
             ])

    assert binding_for(document, "link") == nil
    refute Map.has_key?(node_by_source_id(document, "link").attributes, "url")
    assert node_by_source_id(document, "link").attributes["navigation"] == nil
    assert "bricks.binding.expression_unsupported" in diagnostic_codes(document)

    refute Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.runtime.unsupported" and
               diagnostic.source_trace.source_id == "link"
           end)
  end

  test "exact query result count points to the admitted owner binding" do
    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["owner", "count"]),
               source_element("owner", "block", "root", query_settings(true), ["item"]),
               source_element("item", "text-basic", "owner", %{}),
               source_element(
                 "count",
                 "text-basic",
                 "root",
                 %{"text" => "{query_results_count:owner}"}
               )
             ])

    assert %ValueBinding{} = binding = binding_for(document, "count")
    assert binding.target_kind == :text
    assert binding.value_kind == :collection_count
    assert binding.scope == :collection
    assert binding.value_key == nil
    assert binding.collection_binding_id == "cb_node_000001_000001"
    assert binding.source_trace.metadata["referenced_bricks_owner_id"] == "owner"

    assert binding.source_trace.metadata["resolved_collection_binding_id"] ==
             "cb_node_000001_000001"

    assert node_by_source_id(document, "count").content == nil
  end

  test "query count for a missing or non-admitted owner has no binding" do
    for {owner_id, owner} <- [{"missing", nil}, {"query-only", :not_admitted}] do
      elements =
        case owner do
          nil ->
            [
              source_element("count", "text-basic", 0, %{
                "text" => "{query_results_count:missing}"
              })
            ]

          :not_admitted ->
            [
              source_element(
                "query-only",
                "block",
                0,
                query_settings(false),
                ["child", "count"]
              ),
              source_element("child", "text-basic", "query-only", %{}),
              source_element(
                "count",
                "text-basic",
                "query-only",
                %{"text" => "{query_results_count:#{owner_id}}"}
              )
            ]
        end

      assert {:ok, document} = to_ir(elements)
      assert binding_for(document, "count") == nil
      assert node_by_source_id(document, "count").content == nil
      assert "bricks.binding.evidence_insufficient" in diagnostic_codes(document)
    end
  end

  test "wrapped known text and query count are cleared as unsupported interpolation" do
    for expression <- ["<p>wrapped {post_content}</p>", "wrapped {query_results_count:owner}"] do
      assert {:ok, document} =
               to_ir([
                 source_element("root", "block", 0, %{}, ["owner", "text"]),
                 source_element("owner", "block", "root", query_settings(true), ["item"]),
                 source_element("item", "text-basic", "owner", %{}),
                 source_element("text", "text-basic", "root", %{"text" => expression})
               ])

      assert binding_for(document, "text") == nil
      assert node_by_source_id(document, "text").content == nil
      assert "bricks.binding.interpolation_unsupported" in diagnostic_codes(document)
    end
  end

  test "unknown brace-bearing text is cleared and rejected" do
    assert {:ok, document} =
             to_ir([source_element("text", "heading", 0, %{"text" => "{unknown_field}"})])

    assert binding_for(document, "text") == nil
    assert node_by_source_id(document, "text").content == nil
    assert "bricks.binding.expression_unsupported" in diagnostic_codes(document)
  end

  test "dynamic alt text remains trace evidence without a static alt attribute" do
    assert {:ok, document} =
             to_ir([
               source_element(
                 "image",
                 "image",
                 0,
                 %{"altText" => "{site_title} Logo"}
               )
             ])

    assert document.value_bindings == %{}
    assert node_by_source_id(document, "image").attributes["altText"] == nil

    assert node_by_source_id(document, "image").source_trace.source_settings["altText"] ==
             "{site_title} Logo"

    assert "bricks.binding.target_unsupported" in diagnostic_codes(document)
  end

  test "unrelated runtime diagnostics remain beside admitted collection bindings" do
    assert {:ok, document} =
             to_ir([
               source_element(
                 "loop",
                 "block",
                 0,
                 Map.put(query_settings(true), "javascriptCode", "return 1;"),
                 ["child"]
               ),
               source_element("child", "text-basic", "loop", %{})
             ])

    assert Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.runtime.unsupported" and
               diagnostic.source_trace.source_id == "loop" and
               diagnostic.metadata["source_path"] == "settings.javascriptCode"
           end)
  end

  test "query reconciliation leaves query-like settings outside the query object" do
    assert {:ok, document} =
             to_ir([
               source_element(
                 "loop",
                 "block",
                 0,
                 Map.merge(query_settings(true), %{"query_preview" => true}),
                 ["child"]
               ),
               source_element("child", "text-basic", "loop", %{})
             ])

    assert Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.runtime.unsupported" and
               diagnostic.source_trace.source_id == "loop" and
               diagnostic.metadata["source_path"] == "settings.query_preview"
           end)
  end

  test "binding documents validate, serialize, and fail closed in Fidelity" do
    assert {:ok, document} =
             to_ir(loop_with_target("title", "heading", %{"text" => "{post_title}"}))

    assert LiveFrames.IR.validate(document) == :ok
    assert is_binary(LiveFrames.IR.encode!(document))
    assert {:error, _diagnostics} = Fidelity.generate(document)
  end

  test "ordinary static source keeps empty binding registries and static output" do
    static_image = %{
      "id" => 42,
      "filename" => "synthetic.webp",
      "size" => "large",
      "url" => "https://images.example.test/synthetic.webp",
      "full" => "https://images.example.test/synthetic.webp"
    }

    assert {:ok, document} =
             to_ir([
               source_element("root", "block", 0, %{}, ["text", "image", "link"]),
               source_element("text", "text-basic", "root", %{"text" => "Static content"}),
               source_element("image", "image", "root", %{"image" => static_image}),
               source_element(
                 "link",
                 "text-link",
                 "root",
                 %{"text" => "Home", "link" => %{"type" => "external", "url" => "/home"}}
               )
             ])

    assert document.collection_bindings == %{}
    assert document.value_bindings == %{}
    assert node_by_source_id(document, "text").content == "Static content"
    assert [asset_id] = node_by_source_id(document, "image").asset_refs
    assert document.assets[asset_id].uri == "https://images.example.test/synthetic.webp"
    assert node_by_source_id(document, "link").attributes["navigation"] == %{"href" => "/home"}
  end

  test "binding IDs and serialized diagnostics ignore source map insertion order" do
    settings_a = %{
      "query" => %{"post_type" => ["post"], "tax_query" => [%{"taxonomy" => "category"}]},
      "hasLoop" => true
    }

    settings_b =
      [
        {"hasLoop", true},
        {"query", %{"tax_query" => [%{"taxonomy" => "category"}], "post_type" => ["post"]}}
      ]
      |> Map.new()

    source_a =
      to_ir([
        source_element("loop", "block", 0, settings_a, ["title", "image"]),
        source_element("title", "heading", "loop", %{"text" => "{post_title}"}),
        source_element("image", "image", "loop", %{
          "image" => %{"useDynamicData" => "{featured_image}"}
        })
      ])

    source_b =
      to_ir([
        source_element("loop", "block", 0, settings_b, ["title", "image"]),
        source_element("title", "heading", "loop", Map.new([{"text", "{post_title}"}])),
        source_element("image", "image", "loop", %{
          "image" => Map.new([{"useDynamicData", "{featured_image}"}])
        })
      ])

    assert {:ok, first} = source_a
    assert {:ok, second} = source_b
    assert Map.keys(first.collection_bindings) == Map.keys(second.collection_bindings)
    assert Map.keys(first.value_bindings) == Map.keys(second.value_bindings)
    assert Enum.map(first.diagnostics, & &1.code) == Enum.map(second.diagnostics, & &1.code)
    assert LiveFrames.IR.encode!(first) == LiveFrames.IR.encode!(second)
  end
end
