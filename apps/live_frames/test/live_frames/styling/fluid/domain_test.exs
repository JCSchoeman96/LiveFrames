defmodule LiveFrames.Styling.Fluid.DomainTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Styling.Fluid.Domain

  @valid_domain %{
    "type" => "fluid_domain",
    "format_version" => "1.0.0",
    "input" => "viewport_width",
    "start" => %{"value" => 500, "unit" => "px"},
    "end" => %{"value" => 1000, "unit" => "px"},
    "clamp_policy" => "bounded"
  }

  test "accepts integer and float pixel endpoints" do
    assert :ok = Domain.validate(@valid_domain)

    float_domain = put_in(@valid_domain, ["start", "value"], 500.5)
    float_domain = put_in(float_domain, ["end", "value"], 1000.5)

    assert :ok = Domain.validate(float_domain)
  end

  test "recognizes its type tag independently of validity" do
    malformed = %{"type" => "fluid_domain", "start" => nil}

    assert Domain.type?(malformed)
    assert {:error, :invalid_domain} = Domain.validate(malformed)
    refute Domain.type?(%{"type" => "fluid_value"})
  end

  test "rejects non-map and struct input" do
    for term <- [nil, 1, "fluid_domain", [], %URI{}] do
      assert {:error, :invalid_domain} = Domain.validate(term)
    end
  end

  test "rejects atom-key maps" do
    atom_keyed = %{
      type: "fluid_domain",
      format_version: "1.0.0",
      input: "viewport_width",
      start: %{"value" => 500, "unit" => "px"},
      end: %{"value" => 1000, "unit" => "px"},
      clamp_policy: "bounded"
    }

    assert {:error, :invalid_domain} = Domain.validate(atom_keyed)
  end

  test "rejects missing and unknown fields" do
    assert {:error, :invalid_domain} = Domain.validate(Map.delete(@valid_domain, "input"))
    assert {:error, :invalid_domain} = Domain.validate(Map.put(@valid_domain, "extra", true))
  end

  test "rejects unsupported type and format version" do
    assert {:error, :invalid_domain} = Domain.validate(Map.put(@valid_domain, "type", "other"))

    assert {:error, :invalid_domain} =
             Domain.validate(Map.put(@valid_domain, "format_version", "2.0.0"))
  end

  test "rejects unsupported input and clamp policy" do
    assert {:error, :invalid_domain} = Domain.validate(Map.put(@valid_domain, "input", "height"))

    assert {:error, :invalid_domain} =
             Domain.validate(Map.put(@valid_domain, "clamp_policy", "unbounded"))
  end

  test "rejects malformed start and end objects" do
    assert {:error, :invalid_domain} = Domain.validate(Map.put(@valid_domain, "start", nil))
    assert {:error, :invalid_domain} = Domain.validate(Map.put(@valid_domain, "end", %{}))
  end

  test "rejects unsupported endpoint units" do
    start = put_in(@valid_domain, ["start", "unit"], "rem")
    end_value = put_in(@valid_domain, ["end", "unit"], "vw")

    assert {:error, :invalid_domain} = Domain.validate(start)
    assert {:error, :invalid_domain} = Domain.validate(end_value)
  end

  test "rejects non-number endpoints" do
    assert {:error, :invalid_domain} =
             Domain.validate(put_in(@valid_domain, ["start", "value"], "500"))

    assert {:error, :invalid_domain} =
             Domain.validate(put_in(@valid_domain, ["end", "value"], nil))
  end

  test "rejects equal and descending endpoint ranges" do
    equal = put_in(@valid_domain, ["end", "value"], 500)
    descending = put_in(@valid_domain, ["start", "value"], 1001)

    assert {:error, :invalid_domain} = Domain.validate(equal)
    assert {:error, :invalid_domain} = Domain.validate(descending)
  end
end
