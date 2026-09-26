defmodule LiveFrames.BricksAdapterTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks.Component
  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Document
  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Adapters.Bricks.Result
  alias LiveFrames.Tokens.TokenSet

  defp fixture_path do
    Path.expand("../../../../fixtures/bricks/bricks_components.json", __DIR__)
  end

  defp fixture_map, do: Jason.decode!(File.read!(fixture_path()))

  defp component_fragment(component_ids \\ ["component-a"]) do
    %{
      "components" =>
        Enum.map(component_ids, fn id ->
          %{"id" => id, "name" => "Synthetic component", "elements" => []}
        end),
      "globalClasses" => [%{"id" => "class-a", "name" => "synthetic-class", "settings" => %{}}]
    }
  end

  test "diagnostics normalize only supported severities" do
    assert Diagnostic.new(code: "bricks.source.invalid", severity: :fatal).severity == :fatal
    assert Diagnostic.new(code: "bricks.source.invalid", severity: "warning").severity == :warning
    assert Diagnostic.new(code: "bricks.source.invalid", severity: "unknown").severity == :error
  end

  test "source models preserve independent versions" do
    document = %Document{
      source: "bricksCopiedElements",
      payload_version: "2.3.1",
      adapter_version: "1.0.0",
      components: %{"sqhmmc" => %Component{id: "sqhmmc", version: "2.3.5"}}
    }

    assert document.components["sqhmmc"].version == "2.3.5"
    assert document.payload_version != document.components["sqhmmc"].version
  end

  test "result tracks the lifecycle without starting a process" do
    result = Result.new()
    assert result.status == :received
    assert result.lifecycle == [:received]
    assert Result.advance(result, :recognized).lifecycle == [:received, :recognized]
  end

  test "recognizes the approved fixture and preserves source versions" do
    assert {:ok, document, diagnostics} = Bricks.from_file(fixture_path())
    assert document.source_shape == :copied_elements_envelope
    assert document.source == "bricksCopiedElements"
    assert document.source_url == "http://localhost:10049"
    assert document.payload_version == "2.3.1"
    assert document.adapter_version == "1.0.0"
    assert Document.component_count(document) == 39
    assert Document.global_class_count(document) == 468
    assert diagnostics == []
  end

  test "returns structured diagnostics for malformed JSON" do
    assert {:error, diagnostics} = Bricks.from_json("{bad")
    assert Enum.any?(diagnostics, &(&1.code == "bricks.source.json_invalid"))
  end

  test "rejects wrong envelope and unsupported version" do
    assert {:error, diagnostics} = Bricks.from_json(Jason.encode!(%{"source" => "other"}))
    assert Enum.any?(diagnostics, &(&1.code == "bricks.source.invalid"))

    source = fixture_map() |> Map.put("version", "9.9.9") |> Jason.encode!()
    assert {:error, diagnostics} = Bricks.from_json(source)
    assert Enum.any?(diagnostics, &(&1.code == "bricks.source.version_unsupported"))
  end

  test "rejects a malformed copied-elements envelope without fragment fallback" do
    fragment = component_fragment()

    source =
      fragment
      |> Map.put("source", "bricksCopiedElements")
      |> Map.put("version", "9.9.9")
      |> Jason.encode!()

    assert {:error, diagnostics} = Bricks.from_json(source)
    assert Enum.any?(diagnostics, &(&1.code == "bricks.source.version_unsupported"))
    refute Enum.any?(diagnostics, &(&1.code == "bricks.fragment.invalid"))
  end

  test "recognizes a bounded synthetic component fragment without envelope metadata" do
    assert {:ok, document, []} = Bricks.recognize(component_fragment())
    assert document.source_shape == :component_fragment
    assert document.source == nil
    assert document.source_url == nil
    assert document.payload_version == nil
    assert document.content_proxies == %{}
    assert document.content_proxy_order == []
    assert document.component_order == ["component-a"]
    assert Map.has_key?(document.global_classes, "class-a")
  end

  test "rejects unsupported top-level fields in a component fragment" do
    source = Map.put(component_fragment(), "totallyUnknownPayload", %{})

    assert {:error, diagnostics} = Bricks.recognize(source)
    assert Enum.any?(diagnostics, &(&1.code == "bricks.fragment.invalid"))
  end

  test "rejects component fragments with an empty component collection" do
    source = Map.put(component_fragment(), "components", [])

    assert {:error, diagnostics} = Bricks.recognize(source)
    assert Enum.any?(diagnostics, &(&1.code == "bricks.fragment.invalid"))
  end

  test "accepts component fragments with no global classes" do
    source = Map.put(component_fragment(), "globalClasses", [])

    assert {:ok, document, []} = Bricks.recognize(source)
    assert document.source_shape == :component_fragment
    assert document.global_classes == %{}
  end

  test "keeps component fragments outside Design IR normalization" do
    assert {:error, diagnostics} =
             Bricks.to_ir(component_fragment(),
               token_set: %TokenSet{},
               component_id: "component-a"
             )

    assert Enum.any?(diagnostics, &(&1.code == "bricks.source.fragment_conversion_unsupported"))
  end

  test "rejects a component fragment without components" do
    source = component_fragment() |> Map.delete("components")

    assert {:error, diagnostics} = Bricks.recognize(source)
    assert Enum.any?(diagnostics, &(&1.code == "bricks.fragment.invalid"))
  end

  test "rejects a component fragment without global classes" do
    source = component_fragment() |> Map.delete("globalClasses")

    assert {:error, diagnostics} = Bricks.recognize(source)
    assert Enum.any?(diagnostics, &(&1.code == "bricks.fragment.invalid"))
  end

  test "rejects invalid component and global-class collection shapes" do
    invalid_components = Map.put(component_fragment(), "components", %{})
    invalid_classes = Map.put(component_fragment(), "globalClasses", %{})

    assert {:error, component_diagnostics} = Bricks.recognize(invalid_components)
    assert Enum.any?(component_diagnostics, &(&1.code == "bricks.fragment.invalid"))

    assert {:error, class_diagnostics} = Bricks.recognize(invalid_classes)
    assert Enum.any?(class_diagnostics, &(&1.code == "bricks.fragment.invalid"))
  end

  test "rejects component fragments with duplicate component IDs" do
    assert {:error, diagnostics} = Bricks.recognize(component_fragment(["same", "same"]))
    assert Enum.any?(diagnostics, &(&1.code == "bricks.component.duplicate"))
  end

  test "selects the sole component in a fragment without a requested ID" do
    assert {:ok, document, []} = Bricks.recognize(component_fragment())
    assert {:ok, nil, component, []} = Bricks.resolve(document)
    assert component.id == "component-a"
  end

  test "requires an explicit ID for a multi-component fragment" do
    assert {:ok, document, []} =
             Bricks.recognize(component_fragment(["component-a", "component-b"]))

    assert {:error, diagnostics} = Bricks.resolve(document)
    assert Enum.any?(diagnostics, &(&1.code == "bricks.component.ambiguous"))
  end

  test "selects a requested component ID from a fragment" do
    assert {:ok, document, []} =
             Bricks.recognize(component_fragment(["component-a", "component-b"]))

    assert {:ok, nil, component, []} = Bricks.resolve(document, component_id: "component-b")
    assert component.id == "component-b"
  end

  test "rejects a missing requested component ID from a fragment" do
    assert {:ok, document, []} = Bricks.recognize(component_fragment())

    assert {:error, diagnostics} = Bricks.resolve(document, component_id: "missing")
    assert Enum.any?(diagnostics, &(&1.code == "bricks.component.missing"))
  end

  test "fragment source shape and parse results are deterministic" do
    source = component_fragment()

    assert {:ok, first, first_diagnostics} = Bricks.recognize(source)
    assert {:ok, second, second_diagnostics} = Bricks.recognize(source)

    assert first.source_shape == second.source_shape
    assert first.source_hash == second.source_hash
    assert first.component_order == second.component_order
    assert first.components == second.components
    assert first.global_classes == second.global_classes
    assert first_diagnostics == second_diagnostics
  end

  test "rejects missing collections, proxy cid, and duplicate collection IDs" do
    source = fixture_map()

    missing_collection = source |> Map.delete("components") |> Jason.encode!()
    assert {:error, diagnostics} = Bricks.from_json(missing_collection)
    assert Enum.any?(diagnostics, &(&1.code == "bricks.source.invalid"))

    missing_cid =
      update_in(source, ["content", Access.at(0)], fn proxy -> Map.delete(proxy, "cid") end)
      |> Jason.encode!()

    assert {:error, diagnostics} = Bricks.from_json(missing_cid)
    assert Enum.any?(diagnostics, &(&1.code == "bricks.component.cid_missing"))

    duplicate_component =
      update_in(source, ["components"], fn components -> components ++ [hd(components)] end)
      |> Jason.encode!()

    assert {:error, diagnostics} = Bricks.from_json(duplicate_component)
    assert Enum.any?(diagnostics, &(&1.code == "bricks.component.duplicate"))

    duplicate_class =
      update_in(source, ["globalClasses"], fn classes -> classes ++ [hd(classes)] end)
      |> Jason.encode!()

    assert {:error, diagnostics} = Bricks.from_json(duplicate_class)
    assert Enum.any?(diagnostics, &(&1.code == "bricks.class.duplicate"))
  end

  test "resolves explicit Hero India cid" do
    {:ok, document, _} = Bricks.from_file(fixture_path())
    assert {:ok, proxy, component, diagnostics} = Bricks.resolve(document, component_id: "sqhmmc")
    assert proxy.cid == "sqhmmc"
    assert component.id == "sqhmmc"
    assert component.version == "2.3.5"
    assert diagnostics == []
  end

  test "rejects a missing component without falling back" do
    {:ok, document, _} = Bricks.from_file(fixture_path())
    assert {:error, diagnostics} = Bricks.resolve(document, component_id: "missing")
    assert Enum.any?(diagnostics, &(&1.code == "bricks.component.missing"))
  end

  test "requires explicit selection when multiple proxies exist" do
    {:ok, document, _} = Bricks.from_file(fixture_path())
    assert {:error, diagnostics} = Bricks.resolve(document, [])
    assert Enum.any?(diagnostics, &(&1.code == "bricks.component.ambiguous"))
  end
end
