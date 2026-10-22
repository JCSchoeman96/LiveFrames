defmodule LiveFrames.Styling.Fluid.ValueTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Styling.Fluid.Value

  @valid_value %{
    "type" => "fluid_value",
    "format_version" => "1.0.0",
    "domain_ref" => "layout.fluid.viewport.default",
    "start_value" => %{"value" => 1.0, "unit" => "rem"},
    "end_value" => %{"value" => 2.0, "unit" => "rem"},
    "interpolation" => "linear"
  }

  test "accepts ascending, descending, and constant length values" do
    assert :ok = Value.validate(@valid_value)

    descending = put_in(@valid_value, ["start_value", "value"], 2.0)
    descending = put_in(descending, ["end_value", "value"], 1.0)
    constant = put_in(@valid_value, ["end_value", "value"], 1.0)

    assert :ok = Value.validate(descending)
    assert :ok = Value.validate(constant)
  end

  test "accepts ascending, descending, and constant unitless numbers" do
    number_value = Map.merge(@valid_value, %{"start_value" => 1, "end_value" => 3.5})
    descending = Map.merge(number_value, %{"start_value" => 3.5, "end_value" => 1})
    constant = Map.merge(number_value, %{"start_value" => 2, "end_value" => 2.0})

    assert :ok = Value.validate(number_value)
    assert :ok = Value.validate(descending)
    assert :ok = Value.validate(constant)
  end

  test "accepts px and rem as compatible length dimensions" do
    px_to_rem = put_in(@valid_value, ["end_value", "unit"], "px")
    rem_to_px = put_in(@valid_value, ["start_value", "unit"], "px")

    assert :ok = Value.validate(px_to_rem)
    assert :ok = Value.validate(rem_to_px)
  end

  test "rejects number and length dimension mismatches" do
    number_to_length = Map.put(@valid_value, "start_value", 1)
    length_to_number = Map.put(@valid_value, "end_value", 2)

    assert {:error, :invalid_value} = Value.validate(number_to_length)
    assert {:error, :invalid_value} = Value.validate(length_to_number)
  end

  test "recognizes its type tag independently of validity" do
    malformed = %{"type" => "fluid_value", "interpolation" => "cubic"}

    assert Value.type?(malformed)
    assert {:error, :invalid_value} = Value.validate(malformed)
    refute Value.type?(%{"type" => "fluid_scale"})
  end

  test "rejects unsupported units and malformed typed values" do
    unsupported_unit = put_in(@valid_value, ["start_value", "unit"], "vw")
    malformed_length = Map.put(@valid_value, "end_value", %{"value" => 1.0})

    assert {:error, :invalid_value} = Value.validate(unsupported_unit)
    assert {:error, :invalid_value} = Value.validate(malformed_length)
  end

  test "rejects blank and non-string domain references" do
    for reference <- ["", "   ", 1] do
      assert {:error, :invalid_value} =
               Value.validate(Map.put(@valid_value, "domain_ref", reference))
    end
  end

  test "rejects unsupported interpolation" do
    assert {:error, :invalid_value} =
             Value.validate(Map.put(@valid_value, "interpolation", "cubic"))
  end

  test "rejects missing and unknown fields" do
    assert {:error, :invalid_value} = Value.validate(Map.delete(@valid_value, "domain_ref"))
    assert {:error, :invalid_value} = Value.validate(Map.put(@valid_value, "extra", true))
  end

  test "rejects wrong type and format version" do
    assert {:error, :invalid_value} = Value.validate(Map.put(@valid_value, "type", "fluid_scale"))

    assert {:error, :invalid_value} =
             Value.validate(Map.put(@valid_value, "format_version", "2.0.0"))
  end
end
