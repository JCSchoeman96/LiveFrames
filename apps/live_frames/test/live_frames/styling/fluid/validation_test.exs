defmodule LiveFrames.Styling.Fluid.ValidationTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Styling.Fluid.Validation
  alias LiveFrames.Tokens.Token

  @domain_path "layout.fluid.viewport.default"
  @scale_path "typography.scale.primary"
  @value_path "spacing.fluid.gap"
  @step_path "typography.heading.h1"

  @domain %{
    "type" => "fluid_domain",
    "format_version" => "1.0.0",
    "input" => "viewport_width",
    "start" => %{"value" => 500, "unit" => "px"},
    "end" => %{"value" => 1000, "unit" => "px"},
    "clamp_policy" => "bounded"
  }

  @value %{
    "type" => "fluid_value",
    "format_version" => "1.0.0",
    "domain_ref" => @domain_path,
    "start_value" => %{"value" => 1.0, "unit" => "rem"},
    "end_value" => %{"value" => 1.125, "unit" => "rem"},
    "interpolation" => "linear"
  }

  @scale %{
    "type" => "fluid_scale",
    "format_version" => "1.0.0",
    "domain_ref" => @domain_path,
    "base_start" => %{"value" => 1.0, "unit" => "rem"},
    "base_end" => %{"value" => 1.125, "unit" => "rem"},
    "ratio_start" => 1.2,
    "ratio_end" => 1.414
  }

  @step %{
    "type" => "fluid_scale_step",
    "format_version" => "1.0.0",
    "scale_ref" => @scale_path,
    "power" => 4
  }

  test "accepts a valid Fluid authority graph" do
    assert Validation.validate_registry(valid_graph()) == []
  end

  test "reports intrinsically malformed recognized semantics as value diagnostics" do
    registry =
      replace(valid_graph(), @value_path,
        resolved_value: Map.put(@value, "interpolation", "cubic")
      )

    assert [diagnostic] = Validation.validate_registry(registry)
    assert_diagnostic(diagnostic, "fluid.semantic.invalid", :value, @value_path)
    assert diagnostic.metadata == %{}
  end

  test "fails closed for unsupported fluid-prefixed semantic tags" do
    registry =
      replace(valid_graph(), @value_path, resolved_value: %{"type" => "fluid_unknown"})

    assert [diagnostic] = Validation.validate_registry(registry)
    assert_diagnostic(diagnostic, "fluid.semantic.invalid", :value, @value_path)
  end

  test "fluid domains must not declare any references" do
    for references <- [[@value_path], [@domain_path]] do
      registry = replace(valid_graph(), @domain_path, references: references)

      assert [diagnostic] = Validation.validate_registry(registry), inspect(references)
      assert_diagnostic(diagnostic, "fluid.reference.invalid", :reference, @domain_path)
      assert diagnostic.metadata == %{"expected_references" => []}
    end
  end

  test "fluid values require exactly their domain reference" do
    for references <- [
          [],
          ["layout.other"],
          [@domain_path, "layout.other"],
          [@domain_path, @domain_path]
        ] do
      registry = replace(valid_graph(), @value_path, references: references)

      assert [diagnostic] = Validation.validate_registry(registry), inspect(references)
      assert_diagnostic(diagnostic, "fluid.reference.invalid", :reference, @value_path)
    end
  end

  test "fluid values reject a non-list reference shape without crashing" do
    registry = replace(valid_graph(), @value_path, references: @domain_path)

    assert [diagnostic] = Validation.validate_registry(registry)
    assert_diagnostic(diagnostic, "fluid.reference.invalid", :reference, @value_path)
  end

  test "fluid scales require exactly their domain reference" do
    for references <- [[], ["layout.other"], [@domain_path, @domain_path]] do
      registry = replace(valid_graph(), @scale_path, references: references)

      assert [diagnostic] = Validation.validate_registry(registry), inspect(references)
      assert_diagnostic(diagnostic, "fluid.reference.invalid", :reference, @scale_path)
    end
  end

  test "fluid scale steps require exactly their scale reference" do
    for references <- [
          [],
          [@domain_path],
          [@scale_path, @scale_path],
          [@scale_path, @domain_path]
        ] do
      registry = replace(valid_graph(), @step_path, references: references)

      assert [diagnostic] = Validation.validate_registry(registry), inspect(references)
      assert_diagnostic(diagnostic, "fluid.reference.invalid", :reference, @step_path)
      assert diagnostic.metadata == %{"expected_references" => [@scale_path]}
    end
  end

  test "fluid value must not reference a fluid scale" do
    registry =
      replace(valid_graph(), @value_path,
        resolved_value: Map.put(@value, "domain_ref", @scale_path),
        references: [@scale_path]
      )

    assert [diagnostic] = Validation.validate_registry(registry)
    assert_diagnostic(diagnostic, "fluid.reference.type_mismatch", :reference, @value_path)

    assert diagnostic.metadata == %{
             "expected_type" => "fluid_domain",
             "actual_type" => "fluid_scale",
             "reference" => @scale_path
           }
  end

  test "fluid scale must not reference a fluid value" do
    registry =
      replace(valid_graph(), @scale_path,
        resolved_value: Map.put(@scale, "domain_ref", @value_path),
        references: [@value_path]
      )

    assert [diagnostic] = Validation.validate_registry(registry)
    assert_diagnostic(diagnostic, "fluid.reference.type_mismatch", :reference, @scale_path)

    assert diagnostic.metadata == %{
             "expected_type" => "fluid_domain",
             "actual_type" => "fluid_value",
             "reference" => @value_path
           }
  end

  test "fluid scale step must not reference a fluid domain" do
    registry =
      replace(valid_graph(), @step_path,
        resolved_value: Map.put(@step, "scale_ref", @domain_path),
        references: [@domain_path]
      )

    assert [diagnostic] = Validation.validate_registry(registry)
    assert_diagnostic(diagnostic, "fluid.reference.type_mismatch", :reference, @step_path)

    assert diagnostic.metadata == %{
             "expected_type" => "fluid_scale",
             "actual_type" => "fluid_domain",
             "reference" => @domain_path
           }
  end

  test "fluid references to ordinary semantic targets are type mismatches" do
    registry =
      valid_graph()
      |> Map.put("color.primary", token("color.primary", :color, "#32a2c1", []))
      |> replace(@value_path,
        resolved_value: Map.put(@value, "domain_ref", "color.primary"),
        references: ["color.primary"]
      )

    assert [diagnostic] = Validation.validate_registry(registry)
    assert_diagnostic(diagnostic, "fluid.reference.type_mismatch", :reference, @value_path)
    assert diagnostic.metadata["actual_type"] == "non_fluid"
  end

  test "unresolved dependencies without semantic evidence are not classified" do
    registry =
      replace(valid_graph(), @domain_path,
        resolved_value: nil,
        resolution_status: :unresolved
      )

    assert Validation.validate_registry(registry) == []
  end

  test "missing targets are left to TokenSet reference authority" do
    registry = Map.delete(valid_graph(), @domain_path)

    assert Validation.validate_registry(registry) == []
  end

  test "ordinary semantic maps produce no Fluid diagnostics" do
    registry = %{
      "color.primary" => token("color.primary", :color, "#32a2c1", []),
      "spacing.derived" =>
        token(
          "spacing.derived",
          :spacing,
          %{"type" => "derived", "recipe" => "acss.clamp", "inputs" => %{}},
          []
        ),
      "spacing.responsive" =>
        token(
          "spacing.responsive",
          :spacing,
          %{"type" => "responsive", "min" => "16px", "max" => "18px"},
          []
        )
    }

    assert Validation.validate_registry(registry) == []
  end

  test "repeated validation of the same invalid registry is identical" do
    registry =
      valid_graph()
      |> replace(@value_path, references: [])
      |> replace(@step_path, references: [@domain_path])
      |> replace(@domain_path, references: [@value_path])

    first = Validation.validate_registry(registry)

    assert first != []
    assert Validation.validate_registry(registry) == first
  end

  defp valid_graph do
    %{
      @domain_path => token(@domain_path, :layout, @domain, []),
      @value_path => token(@value_path, :spacing, @value, [@domain_path]),
      @scale_path => token(@scale_path, :typography, @scale, [@domain_path]),
      @step_path => token(@step_path, :typography, @step, [@scale_path])
    }
  end

  defp token(path, category, resolved_value, references) do
    %Token{
      path: path,
      category: category,
      value: nil,
      resolved_value: resolved_value,
      resolution_status: :resolved,
      references: references
    }
  end

  defp replace(registry, path, attrs) do
    Map.update!(registry, path, &struct!(&1, attrs))
  end

  defp assert_diagnostic(diagnostic, code, category, path) do
    assert diagnostic.code == code
    assert diagnostic.severity == :error
    assert diagnostic.category == category
    assert diagnostic.path == path
  end
end
