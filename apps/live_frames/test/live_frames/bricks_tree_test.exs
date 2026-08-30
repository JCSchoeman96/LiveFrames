defmodule LiveFrames.BricksTreeTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Adapters.Bricks.Component
  alias LiveFrames.Adapters.Bricks.Element

  defp fixture_path do
    Path.expand("../../../../fixtures/bricks/bricks_components.json", __DIR__)
  end

  defp hero_component do
    {:ok, document, _} = Bricks.from_file(fixture_path())
    {:ok, _proxy, component, _} = Bricks.resolve(document, component_id: "sqhmmc")
    component
  end

  defp assert_error_with_code(component, code) do
    assert {:error, diagnostics} = Bricks.build_tree(component)

    assert Enum.any?(diagnostics, &(&1.code == code)),
           "expected #{code}, got #{inspect(diagnostics)}"
  end

  defp element(id, parent, children \\ []) do
    %Element{id: id, name: "div", parent: parent, children: children, settings: %{}}
  end

  test "reconstructs Hero India in declared order" do
    assert {:ok, tree, diagnostics} = Bricks.build_tree(hero_component())
    assert tree.root_ids == ["sqhmmc"]
    assert tree.children_by_id["sqhmmc"] == ["2ef2fa", "1c85d9"]
    assert tree.children_by_id["2ef2fa"] == ["561d75", "3f6ee6", "8ae908"]
    assert tree.source_order == Enum.map(hero_component().elements, & &1.id)
    assert diagnostics == []
  end

  test "rejects duplicate IDs" do
    component = %Component{elements: [element("root", 0), element("root", 0)]}
    assert_error_with_code(component, "bricks.element.duplicate")
  end

  test "rejects missing parents and children" do
    assert_error_with_code(
      %Component{elements: [element("root", 0), element("child", "missing")]},
      "bricks.parent.missing"
    )

    assert_error_with_code(
      %Component{elements: [element("root", 0, ["missing"])]},
      "bricks.child.missing"
    )
  end

  test "rejects relationship reciprocity mismatches" do
    assert_error_with_code(
      %Component{elements: [element("root", 0, ["child"]), element("child", 0)]},
      "bricks.tree.reciprocity"
    )

    assert_error_with_code(
      %Component{elements: [element("root", 0), element("child", "root")]},
      "bricks.tree.reciprocity"
    )
  end

  test "rejects duplicate children and cycles" do
    assert_error_with_code(
      %Component{
        elements: [element("root", 0, ["child", "child"]), element("child", "root")]
      },
      "bricks.tree.duplicate_child"
    )

    assert_error_with_code(
      %Component{elements: [element("a", "b"), element("b", "a")]},
      "bricks.tree.cycle"
    )

    assert_error_with_code(
      %Component{elements: [element("self", "self")]},
      "bricks.tree.cycle"
    )
  end

  test "retains multiple roots as an ordered warning" do
    assert {:ok, tree, diagnostics} =
             Bricks.build_tree(%Component{elements: [element("a", 0), element("b", "0")]})

    assert tree.root_ids == ["a", "b"]
    assert Enum.any?(diagnostics, &(&1.code == "bricks.tree.multiple_roots"))
  end
end
