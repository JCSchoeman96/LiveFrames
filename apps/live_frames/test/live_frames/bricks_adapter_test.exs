defmodule LiveFrames.BricksAdapterTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks.Component
  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Document
  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Adapters.Bricks.Result

  defp fixture_path do
    Path.expand("../../../../fixtures/bricks/bricks_components.json", __DIR__)
  end

  defp fixture_map, do: Jason.decode!(File.read!(fixture_path()))

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
