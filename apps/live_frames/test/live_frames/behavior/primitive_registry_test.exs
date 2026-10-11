defmodule LiveFrames.Behavior.PrimitiveRegistryTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Behavior.Binding.PrimitiveRef
  alias LiveFrames.Behavior.PrimitiveRegistry

  test "resolves only the exact selection definition version" do
    assert {:ok, {:selection_v1, 0}} =
             PrimitiveRegistry.resolve(%PrimitiveRef{
               kind: "selection",
               definition_version: "1.0.0"
             })
  end

  test "unknown kinds and versions do not fall back" do
    assert :error =
             PrimitiveRegistry.resolve(%PrimitiveRef{
               kind: "future-primitive",
               definition_version: "9.9.9"
             })

    assert :error =
             PrimitiveRegistry.resolve(%PrimitiveRef{
               kind: "selection",
               definition_version: "9.9.9"
             })

    assert :error =
             PrimitiveRegistry.resolve(%PrimitiveRef{
               kind: "selection",
               definition_version: "latest"
             })
  end

  test "malformed and non-reference inputs do not become dynamic lookups" do
    assert :error =
             PrimitiveRegistry.resolve(%PrimitiveRef{kind: nil, definition_version: "1.0.0"})

    assert :error =
             PrimitiveRegistry.resolve(
               Map.put(
                 %PrimitiveRef{kind: "selection", definition_version: "1.0.0"},
                 :extra,
                 "value"
               )
             )

    assert :error = PrimitiveRegistry.resolve(%{kind: "selection", definition_version: "1.0.0"})
    assert :error = PrimitiveRegistry.resolve("selection@1.0.0")
  end
end
