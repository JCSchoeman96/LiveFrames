defmodule LiveFrames.Behavior.DiagnosticTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Behavior.Diagnostic

  test "exposes the frozen severity and category strings" do
    assert Diagnostic.severities() == ["info", "warning", "error", "fatal"]

    assert Diagnostic.categories() == [
             "structure",
             "identity",
             "reference",
             "semantic",
             "accessibility",
             "provenance",
             "projection",
             "realization",
             "runtime"
           ]
  end

  test "has exactly the persisted diagnostic fields" do
    diagnostic = %Diagnostic{}

    assert diagnostic |> Map.keys() |> Enum.sort() ==
             [
               :__struct__,
               :code,
               :severity,
               :category,
               :binding_id,
               :node_id,
               :evidence_id,
               :message,
               :suggested_action,
               :source_trace
             ]
             |> Enum.sort()
  end
end
