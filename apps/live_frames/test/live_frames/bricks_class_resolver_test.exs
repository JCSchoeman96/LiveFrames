defmodule LiveFrames.BricksClassResolverTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Adapters.Bricks.ClassResolver
  alias LiveFrames.Adapters.Bricks.DependencyExtractor
  alias LiveFrames.Adapters.Bricks.Document
  alias LiveFrames.Adapters.Bricks.StageA
  alias LiveFrames.Adapters.Bricks.StageA.HTMLRenderer
  alias LiveFrames.Tokens.TokenSet

  defp class(id, name, settings \\ %{}, extra \\ %{}) do
    Map.merge(
      %{"id" => id, "name" => name, "settings" => settings},
      extra
    )
  end

  defp authority(id, classes), do: %{id: id, global_classes: classes}

  defp source(references, local_classes \\ [], element_settings \\ %{}) do
    element_settings = Map.put(element_settings, "_cssGlobalClasses", references)

    %{
      "components" => [
        %{
          "id" => "component-a",
          "elements" => [
            %{
              "id" => "root",
              "name" => "div",
              "settings" => element_settings
            }
          ]
        }
      ],
      "globalClasses" => local_classes
    }
  end

  defp copied_elements_source(references) do
    source(references)
    |> Map.merge(%{
      "source" => "bricksCopiedElements",
      "sourceUrl" => "https://example.test/export.json",
      "version" => "2.3.1",
      "content" => [%{"id" => "proxy-a", "cid" => "component-a", "label" => "Synthetic"}]
    })
  end

  defp resolve_classes(
         references,
         local_classes \\ [],
         authorities \\ [],
         element_settings \\ %{}
       ) do
    {:ok, document, []} = Bricks.recognize(source(references, local_classes, element_settings))
    {:ok, nil, component, []} = Bricks.resolve(document, component_id: "component-a")
    {:ok, tree, []} = Bricks.build_tree(component)

    ClassResolver.resolve(tree, document, external_class_authorities: authorities)
  end

  test "resolves local definitions with explicit local provenance" do
    local = class("class-a", "alpha", %{"_width" => "100px"})

    assert {:ok, resolved, []} = resolve_classes(["class-a"], [local])
    assert resolved.elements["root"].class_names == ["alpha"]

    assert [ref] = resolved.elements["root"].class_refs
    assert ref.status == :resolved
    assert ref.resolution_status == :local_resolved
    assert ref.resolution_source == :local
    assert ref.authority_ids == []
  end

  test "resolves external-only definitions and records the supplying authority" do
    external = class("class-a", "alpha", %{"_width" => "100px"})

    assert {:ok, resolved, []} =
             resolve_classes(["class-a"], [], [authority("site-classes", [external])])

    assert resolved.elements["root"].class_names == ["alpha"]
    assert resolved.elements["root"].settings["_width"] == "100px"
    assert [ref] = resolved.elements["root"].class_refs
    assert ref.resolution_status == :external_resolved
    assert ref.resolution_source == :external
    assert ref.authority_ids == ["site-classes"]
  end

  test "unresolved references remain provenance and do not become generated class names" do
    assert {:ok, resolved, [diagnostic]} = resolve_classes(["opaque-id"])
    assert resolved.elements["root"].class_ids == ["opaque-id"]
    assert resolved.elements["root"].class_names == []

    assert [%{resolution_status: :unresolved_external, name: nil, authority_ids: []}] =
             resolved.elements["root"].class_refs

    assert diagnostic.code == "bricks.class.unresolved_external"
    assert diagnostic.severity == :warning
    assert diagnostic.metadata["class_id"] == "opaque-id"

    html = HTMLRenderer.render(resolved)
    refute html =~ "opaque-id"
    refute html =~ "bricks-source-class"
  end

  test "local and structurally identical external definitions resolve once to local" do
    local =
      class("class-a", "alpha", %{"_width" => "100px"}, %{
        "future" => %{"left" => 1, "right" => 2}
      })

    external = %{
      "future" => %{"right" => 2, "left" => 1},
      "settings" => %{"_width" => "100px"},
      "name" => "alpha",
      "id" => "class-a"
    }

    assert {:ok, resolved, []} =
             resolve_classes(["class-a"], [local], [authority("shared-classes", [external])])

    assert resolved.elements["root"].class_names == ["alpha"]
    assert [ref] = resolved.elements["root"].class_refs
    assert ref.resolution_status == :local_resolved
    assert ref.resolution_source == :local
    assert ref.authority_ids == ["shared-classes"]

    dependencies = DependencyExtractor.extract(resolved, %Document{})
    assert [record] = dependencies.class_dependencies
    assert record.resolution_status == :local_resolved
    assert record.authority_ids == ["shared-classes"]
  end

  test "equivalent external authorities are independent of input order" do
    first = authority("alpha-authority", [class("class-a", "alpha")])
    second = authority("zeta-authority", [class("class-a", "alpha")])

    assert {:ok, resolved_a, diagnostics_a} = resolve_classes(["class-a"], [], [first, second])
    assert {:ok, resolved_b, diagnostics_b} = resolve_classes(["class-a"], [], [second, first])
    assert resolved_a == resolved_b
    assert diagnostics_a == diagnostics_b

    assert [%{authority_ids: ["alpha-authority", "zeta-authority"]}] =
             resolved_a.elements["root"].class_refs
  end

  test "conflicting local and external records produce a conflicted reference" do
    local = class("class-a", "alpha", %{"_width" => "100px"}, %{"unknown" => "local"})
    external = class("class-a", "alpha", %{"_width" => "100px"}, %{"unknown" => "external"})

    assert {:ok, resolved, diagnostics} =
             resolve_classes(["class-a"], [local], [authority("site-classes", [external])])

    assert [%{resolution_status: :conflicted, name: nil}] =
             resolved.elements["root"].class_refs

    assert resolved.elements["root"].class_names == []
    assert [%{code: "bricks.class.authority_conflict", severity: :error}] = diagnostics
  end

  test "conflicting external authorities produce a hard component blocker" do
    alpha = authority("alpha-authority", [class("class-a", "alpha", %{"a" => 1})])
    zeta = authority("zeta-authority", [class("class-a", "alpha", %{"a" => 2})])

    assert {:ok, resolved, [diagnostic]} = resolve_classes(["class-a"], [], [zeta, alpha])

    assert [
             %{
               resolution_status: :conflicted,
               authority_ids: ["alpha-authority", "zeta-authority"]
             }
           ] =
             resolved.elements["root"].class_refs

    assert diagnostic.severity == :error
    assert diagnostic.metadata["class_id"] == "class-a"

    {:ok, document, []} = Bricks.recognize(copied_elements_source(["class-a"]))

    assert {:error, [stage_a_diagnostic]} =
             StageA.generate(document,
               component_id: "component-a",
               external_class_authorities: [zeta, alpha]
             )

    assert stage_a_diagnostic.code == "bricks.class.authority_conflict"
  end

  test "conflicting unreferenced definitions are reported without blocking selected classes" do
    alpha = authority("alpha-authority", [class("unused", "unused", %{"a" => 1})])
    zeta = authority("zeta-authority", [class("unused", "unused", %{"a" => 2})])
    local = class("class-a", "alpha")

    assert {:ok, resolved, [diagnostic]} =
             resolve_classes(["class-a"], [local], [zeta, alpha])

    assert resolved.elements["root"].class_names == ["alpha"]
    assert diagnostic.code == "bricks.class.authority_conflict"
    assert diagnostic.severity == :warning
    assert diagnostic.metadata["class_id"] == "unused"
  end

  test "authority order does not change conflict diagnostics" do
    first = authority("alpha-authority", [class("unused", "unused", %{"a" => 1})])
    second = authority("zeta-authority", [class("unused", "unused", %{"a" => 2})])

    assert {:ok, resolved_a, diagnostics_a} = resolve_classes([], [], [first, second])
    assert {:ok, resolved_b, diagnostics_b} = resolve_classes([], [], [second, first])
    assert resolved_a == resolved_b
    assert diagnostics_a == diagnostics_b
  end

  test "rejects malformed external authority inputs deterministically" do
    assert {:error, [diagnostic]} = resolve_classes([], [], [%{id: "site-classes"}])
    assert diagnostic.code == "bricks.class.authority_invalid"
    assert diagnostic.severity == :error

    malformed = %{id: "bad-records", global_classes: [%{"id" => "class-a", "settings" => %{}}]}
    assert {:error, [record_diagnostic]} = resolve_classes([], [], [malformed])
    assert record_diagnostic.code == "bricks.class.authority_invalid"
    assert record_diagnostic.metadata["validation_errors"] != []

    authority_a = authority("duplicate", [class("class-a", "alpha")])
    authority_b = authority("duplicate", [class("class-a", "alpha")])
    assert {:error, [duplicate_diagnostic]} = resolve_classes([], [], [authority_b, authority_a])
    assert duplicate_diagnostic.code == "bricks.class.authority_invalid"
    assert duplicate_diagnostic.source_id == "duplicate"

    invalid_one = %{id: "same-invalid-id", global_classes: [%{"id" => "class-a"}]}

    invalid_two = %{
      id: "same-invalid-id",
      global_classes: [%{"id" => "class-a"}, %{"id" => "class-b"}]
    }

    assert {:error, diagnostics_a} = resolve_classes([], [], [invalid_one, invalid_two])
    assert {:error, diagnostics_b} = resolve_classes([], [], [invalid_two, invalid_one])
    assert diagnostics_a == diagnostics_b
  end

  test "fragment class resolution accepts an external authority while IR conversion stays blocked" do
    external = class("class-a", "alpha")
    fragment = source(["class-a"])
    {:ok, document, []} = Bricks.recognize(fragment)
    {:ok, nil, component, []} = Bricks.resolve(document, component_id: "component-a")
    {:ok, tree, []} = Bricks.build_tree(component)

    assert {:ok, resolved, []} =
             ClassResolver.resolve(tree, document,
               external_class_authorities: [authority("site-classes", [external])]
             )

    assert resolved.elements["root"].class_names == ["alpha"]

    assert {:error, diagnostics} =
             Bricks.to_ir(fragment, component_id: "component-a", token_set: %TokenSet{})

    assert Enum.any?(diagnostics, &(&1.code == "bricks.source.fragment_conversion_unsupported"))
  end

  test "authority lookup preserves class reference order and element settings override classes" do
    local_a = class("class-a", "alpha", %{"_width" => "100px", "_height" => "20px"})
    external_b = class("class-b", "beta", %{"_height" => "10px"})

    assert {:ok, resolved, []} =
             resolve_classes(
               ["class-b", "class-a"],
               [local_a],
               [authority("site-classes", [external_b])],
               %{"_width" => "50%"}
             )

    element = resolved.elements["root"]
    assert element.class_ids == ["class-b", "class-a"]
    assert element.class_names == ["beta", "alpha"]
    assert element.settings["_width"] == "50%"
    assert element.settings["_height"] == "20px"
  end

  test "dependency provenance carries external authority resolution" do
    external = class("class-a", "alpha")

    assert {:ok, resolved, []} =
             resolve_classes(["class-a"], [], [authority("site-classes", [external])])

    dependencies = DependencyExtractor.extract(resolved, %Document{})

    assert [record] = dependencies.class_dependencies
    assert record.resolution_status == :external_resolved
    assert record.resolution_source == :external
    assert record.authority_ids == ["site-classes"]
  end
end
