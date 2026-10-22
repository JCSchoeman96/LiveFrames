defmodule LiveFrames.Styling.Fluid.ScaleStepTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Styling.Fluid.ScaleStep

  @valid_step %{
    "type" => "fluid_scale_step",
    "format_version" => "1.0.0",
    "scale_ref" => "typography.scale.primary",
    "power" => 0
  }

  test "accepts powers at both bounds and zero" do
    for power <- [-4, 0, 4] do
      assert :ok = ScaleStep.validate(Map.put(@valid_step, "power", power))
    end
  end

  test "rejects powers outside the inclusive bounds" do
    for power <- [-5, 5] do
      assert {:error, :invalid_scale_step} =
               ScaleStep.validate(Map.put(@valid_step, "power", power))
    end
  end

  test "rejects float and non-number powers" do
    assert {:error, :invalid_scale_step} = ScaleStep.validate(Map.put(@valid_step, "power", 1.0))
    assert {:error, :invalid_scale_step} = ScaleStep.validate(Map.put(@valid_step, "power", "1"))
    assert {:error, :invalid_scale_step} = ScaleStep.validate(Map.put(@valid_step, "power", nil))
  end

  test "rejects blank and non-string scale references" do
    for reference <- ["", "   ", 1] do
      assert {:error, :invalid_scale_step} =
               ScaleStep.validate(Map.put(@valid_step, "scale_ref", reference))
    end
  end

  test "recognizes its type tag independently of validity" do
    malformed = %{"type" => "fluid_scale_step", "power" => 9}

    assert ScaleStep.type?(malformed)
    assert {:error, :invalid_scale_step} = ScaleStep.validate(malformed)
    refute ScaleStep.type?(%{"type" => "fluid_scale"})
  end

  test "rejects missing and unknown fields" do
    assert {:error, :invalid_scale_step} = ScaleStep.validate(Map.delete(@valid_step, "power"))
    assert {:error, :invalid_scale_step} = ScaleStep.validate(Map.put(@valid_step, "extra", true))
  end

  test "rejects wrong type and format version" do
    assert {:error, :invalid_scale_step} =
             ScaleStep.validate(Map.put(@valid_step, "type", "fluid_scale"))

    assert {:error, :invalid_scale_step} =
             ScaleStep.validate(Map.put(@valid_step, "format_version", "2.0.0"))
  end
end
