defmodule LiveFrames.GenerationMixTaskRequirementsTest do
  use ExUnit.Case, async: true

  test "Bricks Design IR generation requires current application code" do
    assert Mix.Task.requirements(Mix.Tasks.LiveFrames.Bricks.DesignIr) == ["app.config"]
  end

  test "Fidelity generation requires current application code" do
    assert Mix.Task.requirements(Mix.Tasks.LiveFrames.Fidelity.Generate) == ["app.config"]
  end
end
