defmodule LiveFrames.Styling.Fluid.ScaleTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Styling.Fluid.Scale

  @valid_scale %{
    "type" => "fluid_scale",
    "format_version" => "1.0.0",
    "domain_ref" => "layout.fluid.viewport.default",
    "base_start" => %{"value" => 1.0, "unit" => "rem"},
    "base_end" => %{"value" => 1.25, "unit" => "rem"},
    "ratio_start" => 1.2,
    "ratio_end" => 1.5
  }

  test "accepts px, rem, and compatible mixed length bases" do
    px_scale = put_in(@valid_scale, ["base_start", "unit"], "px")
    px_scale = put_in(px_scale, ["base_end", "unit"], "px")
    rem_scale = @valid_scale
    mixed_scale = put_in(@valid_scale, ["base_start", "unit"], "px")

    assert :ok = Scale.validate(px_scale)
    assert :ok = Scale.validate(rem_scale)
    assert :ok = Scale.validate(mixed_scale)
  end

  test "accepts ascending, descending, and equal ratios" do
    ascending = Map.merge(@valid_scale, %{"ratio_start" => 1.2, "ratio_end" => 1.5})
    descending = Map.merge(@valid_scale, %{"ratio_start" => 1.5, "ratio_end" => 1.2})
    equal = Map.merge(@valid_scale, %{"ratio_start" => 1.25, "ratio_end" => 1.25})

    assert :ok = Scale.validate(ascending)
    assert :ok = Scale.validate(descending)
    assert :ok = Scale.validate(equal)
  end

  test "rejects zero and negative ratios" do
    for ratio <- [0, 0.0, -1, -0.25] do
      assert {:error, :invalid_scale} =
               Scale.validate(Map.put(@valid_scale, "ratio_start", ratio))
    end
  end

  test "rejects non-number ratios" do
    assert {:error, :invalid_scale} = Scale.validate(Map.put(@valid_scale, "ratio_start", "1.2"))
    assert {:error, :invalid_scale} = Scale.validate(Map.put(@valid_scale, "ratio_end", nil))
  end

  test "rejects bare number bases and unsupported length units" do
    assert {:error, :invalid_scale} = Scale.validate(Map.put(@valid_scale, "base_start", 1.0))

    unsupported_unit = put_in(@valid_scale, ["base_end", "unit"], "vw")
    assert {:error, :invalid_scale} = Scale.validate(unsupported_unit)
  end

  test "rejects malformed bases" do
    assert {:error, :invalid_scale} =
             Scale.validate(
               Map.put(@valid_scale, "base_start", %{"value" => "1", "unit" => "rem"})
             )

    assert {:error, :invalid_scale} = Scale.validate(Map.put(@valid_scale, "base_end", %URI{}))
  end

  test "rejects blank and non-string domain references" do
    for reference <- ["", "   ", 1] do
      assert {:error, :invalid_scale} =
               Scale.validate(Map.put(@valid_scale, "domain_ref", reference))
    end
  end

  test "recognizes its type tag independently of validity" do
    malformed = %{"type" => "fluid_scale", "ratio_start" => 0}

    assert Scale.type?(malformed)
    assert {:error, :invalid_scale} = Scale.validate(malformed)
    refute Scale.type?(%{"type" => "fluid_value"})
  end

  test "rejects missing and unknown fields" do
    assert {:error, :invalid_scale} = Scale.validate(Map.delete(@valid_scale, "ratio_end"))
    assert {:error, :invalid_scale} = Scale.validate(Map.put(@valid_scale, "extra", true))
  end

  test "rejects wrong type and format version" do
    assert {:error, :invalid_scale} = Scale.validate(Map.put(@valid_scale, "type", "fluid_value"))

    assert {:error, :invalid_scale} =
             Scale.validate(Map.put(@valid_scale, "format_version", "2.0.0"))
  end
end
