defmodule LiveFrames.Styling.Fluid.CSSSerializerTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet

  @serializer LiveFrames.Styling.Fluid.CSSSerializer
  @domain_path "layout.fluid.viewport.default"
  @value_path "spacing.fluid.gap"
  @second_value_path "typography.fluid.body"
  @scale_path "typography.scale.primary"
  @step_path "typography.heading.h1"
  @ordinary_path "color.primary"
  @ordinary_scalar_path "opacity.base"

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
    "start_value" => %{"value" => 1, "unit" => "rem"},
    "end_value" => %{"value" => 1.125, "unit" => "rem"},
    "interpolation" => "linear"
  }

  @scale %{
    "type" => "fluid_scale",
    "format_version" => "1.0.0",
    "domain_ref" => @domain_path,
    "base_start" => %{"value" => 1, "unit" => "rem"},
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

  @fallback_progress "clamp(0, tan(atan2(calc(100vw - 500px), calc(1000px - 500px))), 1)"

  test "serializes an ascending FluidValue as a self-contained exact expression" do
    assert {:ok, expression} = call(:legacy_value, [token_set(), @value_path])

    assert expression ==
             "calc(1rem + ((1.125rem - 1rem) * " <>
               @fallback_progress <>
               "))"

    refute String.contains?(expression, "progress(")
    refute String.contains?(expression, "16px")
    refute String.contains?(expression, "16rem")
  end

  test "serializes descending endpoints with the same interpolation equation" do
    descending =
      put_endpoints(@value, %{"value" => 2, "unit" => "rem"}, %{"value" => 1, "unit" => "rem"})

    set = put_token(token_set(), @value_path, token(@value_path, descending))

    assert {:ok, expression} = call(:legacy_value, [set, @value_path])

    assert expression ==
             "calc(2rem + ((1rem - 2rem) * " <>
               @fallback_progress <>
               "))"
  end

  test "serializes constant endpoints without changing their value" do
    constant =
      put_endpoints(@value, %{"value" => 1.25, "unit" => "rem"}, %{
        "value" => 1.25,
        "unit" => "rem"
      })

    set = put_token(token_set(), @value_path, token(@value_path, constant))

    assert {:ok, expression} = call(:legacy_value, [set, @value_path])

    assert expression ==
             "calc(1.25rem + ((1.25rem - 1.25rem) * " <>
               @fallback_progress <>
               "))"
  end

  test "serializes unitless values without inventing a unit" do
    unitless = put_endpoints(@value, 1, 3.5)
    set = put_token(token_set(), @value_path, token(@value_path, unitless))

    assert {:ok, expression} = call(:legacy_value, [set, @value_path])

    assert expression ==
             "calc(1 + ((3.5 - 1) * " <>
               @fallback_progress <>
               "))"

    refute String.contains?(expression, "1px")
    refute String.contains?(expression, "3.5px")
    refute String.contains?(expression, "rem")
  end

  test "preserves px units" do
    px_value =
      put_endpoints(@value, %{"value" => 12, "unit" => "px"}, %{"value" => 24, "unit" => "px"})

    set = put_token(token_set(), @value_path, token(@value_path, px_value))

    assert {:ok, expression} = call(:legacy_value, [set, @value_path])

    assert expression ==
             "calc(12px + ((24px - 12px) * " <>
               @fallback_progress <>
               "))"
  end

  test "preserves rem units" do
    rem_value =
      put_endpoints(@value, %{"value" => 1, "unit" => "rem"}, %{"value" => 2, "unit" => "rem"})

    set = put_token(token_set(), @value_path, token(@value_path, rem_value))

    assert {:ok, expression} = call(:legacy_value, [set, @value_path])

    assert expression ==
             "calc(1rem + ((2rem - 1rem) * " <>
               @fallback_progress <>
               "))"
  end

  test "preserves mixed px and rem endpoints without a root-size conversion" do
    mixed =
      put_endpoints(@value, %{"value" => 16, "unit" => "px"}, %{"value" => 1.5, "unit" => "rem"})

    set = put_token(token_set(), @value_path, token(@value_path, mixed))

    assert {:ok, expression} = call(:legacy_value, [set, @value_path])

    assert expression ==
             "calc(16px + ((1.5rem - 16px) * " <>
               @fallback_progress <>
               "))"

    refute String.contains?(expression, "16rem")
    refute String.contains?(expression, "24px")
  end

  test "the progressive plan uses modern progress for the shared domain variable" do
    assert {:ok, plan} = call(:plan, [token_set(), [@value_path]])

    assert plan.modern_overrides == [
             %{
               name: "--lf-fluid-domain-layout-fluid-viewport-default-progress",
               expression: "progress(100vw, 500px, 1000px)"
             }
           ]
  end

  test "the progressive plan uses the exact bounded fallback progress expression" do
    assert {:ok, plan} = call(:plan, [token_set(), [@value_path]])

    assert plan.fallback_dependencies == [
             %{
               name: "--lf-fluid-domain-layout-fluid-viewport-default-progress",
               expression: @fallback_progress
             }
           ]
  end

  test "a FluidValue-only plan keeps the accepted FLUID-04 output exactly" do
    assert call(:plan, [token_set(), [@value_path]]) ==
             {:ok,
              %{
                fallback_dependencies: [
                  %{
                    name: "--lf-fluid-domain-layout-fluid-viewport-default-progress",
                    expression: @fallback_progress
                  }
                ],
                modern_overrides: [
                  %{
                    name: "--lf-fluid-domain-layout-fluid-viewport-default-progress",
                    expression: "progress(100vw, 500px, 1000px)"
                  }
                ],
                values: [
                  %{
                    path: @value_path,
                    expression:
                      "calc(1rem + ((1.125rem - 1rem) * " <>
                        "var(--lf-fluid-domain-layout-fluid-viewport-default-progress)))"
                  }
                ]
              }}
  end

  test "serializes all supported powers with the same coupled scale formula" do
    for power <- [-4, -1, 0, 1, 4] do
      step = Map.put(@step, "power", power)
      set = put_token(token_set(), @step_path, token(@step_path, step))

      assert {:ok, plan} = call(:plan, [set, [@step_path]])
      assert [value] = plan.values

      assert value.expression ==
               "calc(var(--lf-fluid-scale-typography-scale-primary-base) * " <>
                 "pow(var(--lf-fluid-scale-typography-scale-primary-ratio), #{power}))"

      assert length(plan.fallback_dependencies) == 3
      assert length(plan.modern_overrides) == 1

      assert Enum.count(plan.fallback_dependencies, &String.contains?(&1.expression, "clamp(")) ==
               1
    end
  end

  test "deduplicates one scale's dependencies across multiple steps" do
    second_step_path = "typography.heading.h2"

    set =
      token_set()
      |> put_token(second_step_path, token(second_step_path, scale_step(@scale_path, 1)))

    assert {:ok, plan} = call(:plan, [set, [@step_path, second_step_path]])

    assert length(plan.fallback_dependencies) == 3
    assert length(plan.modern_overrides) == 1
    assert length(plan.values) == 2
    assert Enum.map(plan.values, & &1.path) == Enum.sort([@step_path, second_step_path])
  end

  test "deduplicates one domain shared by two scales" do
    second_scale_path = "spacing.scale.secondary"
    second_step_path = "spacing.gap.large"

    set =
      token_set()
      |> put_token(
        second_scale_path,
        token(second_scale_path, scale(@domain_path, 2, 3, 1.1, 1.3))
      )
      |> put_token(second_step_path, token(second_step_path, scale_step(second_scale_path, -1)))

    assert {:ok, plan} = call(:plan, [set, [@step_path, second_step_path]])

    assert length(plan.fallback_dependencies) == 5
    assert length(plan.modern_overrides) == 1
    assert length(plan.values) == 2

    fallback_names = Enum.map(plan.fallback_dependencies, & &1.name)
    assert Enum.count(fallback_names, &(&1 == domain_variable_name(@domain_path))) == 1
    assert Enum.count(fallback_names, &String.ends_with?(&1, "-base")) == 2
    assert Enum.count(fallback_names, &String.ends_with?(&1, "-ratio")) == 2
    assert Enum.map(plan.modern_overrides, & &1.name) == [domain_variable_name(@domain_path)]
  end

  test "sorts dependencies and values across multiple domains and scales" do
    alpha_domain_path = "alpha.fluid.viewport"
    zeta_domain_path = "zeta.fluid.viewport"
    alpha_scale_path = "alpha.scale.primary"
    zeta_scale_path = "zeta.scale.primary"
    alpha_step_path = "spacing.alpha"
    zeta_step_path = "typography.zeta"

    set = token_set()
    set = put_token(set, alpha_domain_path, token(alpha_domain_path, domain(400, 900)))
    set = put_token(set, zeta_domain_path, token(zeta_domain_path, domain(600, 1200)))

    set =
      put_token(
        set,
        alpha_scale_path,
        token(alpha_scale_path, scale(alpha_domain_path, 1, 1.25, 1.1, 1.3))
      )

    set =
      put_token(
        set,
        zeta_scale_path,
        token(zeta_scale_path, scale(zeta_domain_path, 2, 3, 1.2, 1.4))
      )

    set = put_token(set, alpha_step_path, token(alpha_step_path, scale_step(alpha_scale_path, 2)))
    set = put_token(set, zeta_step_path, token(zeta_step_path, scale_step(zeta_scale_path, -2)))

    assert {:ok, plan} = call(:plan, [set, [zeta_step_path, alpha_step_path]])

    fallback_names = Enum.map(plan.fallback_dependencies, & &1.name)
    modern_names = Enum.map(plan.modern_overrides, & &1.name)
    value_paths = Enum.map(plan.values, & &1.path)

    assert fallback_names == Enum.sort(fallback_names)
    assert modern_names == Enum.sort(modern_names)
    assert value_paths == Enum.sort([alpha_step_path, zeta_step_path])
    assert length(plan.fallback_dependencies) == 6
    assert length(plan.modern_overrides) == 2
  end

  test "plans mixed FluidValue and FluidScaleStep roots with shared dependencies" do
    assert {:ok, plan} = call(:plan, [token_set(), [@step_path, @value_path]])

    assert length(plan.fallback_dependencies) == 3
    assert length(plan.modern_overrides) == 1
    assert Enum.map(plan.values, & &1.path) == Enum.sort([@step_path, @value_path])

    assert {:ok, reverse} = call(:plan, [token_set(), [@value_path, @step_path]])
    assert reverse == plan
    assert {:ok, duplicate} = call(:plan, [token_set(), [@step_path, @value_path, @step_path]])
    assert duplicate == plan
  end

  test "preserves mixed px and rem units in the scale base expression" do
    mixed_scale =
      scale(
        @domain_path,
        %{"value" => 16, "unit" => "px"},
        %{"value" => 1.5, "unit" => "rem"},
        1.2,
        1.5
      )

    set = put_token(token_set(), @scale_path, token(@scale_path, mixed_scale))

    assert {:ok, plan} = call(:plan, [set, [@step_path]])

    assert Enum.find(plan.fallback_dependencies, &String.ends_with?(&1.name, "-base")) == %{
             name: "--lf-fluid-scale-typography-scale-primary-base",
             expression:
               "calc(16px + ((1.5rem - 16px) * " <>
                 "var(--lf-fluid-domain-layout-fluid-viewport-default-progress)))"
           }

    refute Enum.any?(plan.fallback_dependencies, &String.contains?(&1.expression, "16rem"))
  end

  test "propagates missing, unresolved, and wrong scale errors from the resolver" do
    missing = delete_token(token_set(), @scale_path)

    unresolved =
      put_token(token_set(), @scale_path, token(@scale_path, @scale, :unresolved))

    wrong_type =
      put_token(token_set(), @scale_path, token(@scale_path, %{"type" => "fluid_domain"}))

    assert call(:plan, [missing, [@step_path]]) ==
             {:error, {:token_not_found, @scale_path}}

    assert call(:plan, [unresolved, [@step_path]]) ==
             {:error, {:unresolved_dependency, @scale_path}}

    assert call(:plan, [wrong_type, [@step_path]]) ==
             {:error, {:invalid_dependency_type, @scale_path, "fluid_scale"}}
  end

  test "propagates missing, unresolved, and wrong domain errors through a scale step" do
    missing = delete_token(token_set(), @domain_path)

    unresolved =
      put_token(token_set(), @domain_path, token(@domain_path, nil))

    wrong_type =
      put_token(token_set(), @domain_path, token(@domain_path, %{"type" => "color"}))

    assert call(:plan, [missing, [@step_path]]) ==
             {:error, {:token_not_found, @domain_path}}

    assert call(:plan, [unresolved, [@step_path]]) ==
             {:error, {:unresolved_dependency, @domain_path}}

    assert call(:plan, [wrong_type, [@step_path]]) ==
             {:error, {:invalid_dependency_type, @domain_path, "fluid_domain"}}
  end

  test "keeps direct FluidScale roots unsupported and legacy serialization FluidValue-only" do
    assert call(:plan, [token_set(), [@scale_path]]) ==
             {:error, {:unsupported_realization, @scale_path}}

    assert call(:legacy_value, [token_set(), @step_path]) ==
             {:error, {:unsupported_realization, @step_path}}
  end

  test "scale-step fallback matches the coupled reference for required powers and samples" do
    domain_start = 500.0
    domain_end = 1000.0
    base_start = 1.0
    base_end = 1.125
    ratio_start = 1.2
    ratio_end = 1.414

    samples = [
      domain_start - 100,
      domain_start,
      domain_start + (domain_end - domain_start) * 0.25,
      domain_start + (domain_end - domain_start) * 0.5,
      domain_start + (domain_end - domain_start) * 0.75,
      domain_end,
      domain_end + 100
    ]

    for power <- [-4, -1, 0, 1, 4], viewport <- samples do
      semantic_progress = bounded_progress(viewport, domain_start, domain_end)

      semantic =
        scale_step_value(
          base_start,
          base_end,
          ratio_start,
          ratio_end,
          power,
          semantic_progress
        )

      fallback =
        fallback_scale_step_value(
          base_start,
          base_end,
          ratio_start,
          ratio_end,
          power,
          viewport,
          domain_start,
          domain_end
        )

      assert_in_delta fallback, semantic, 1.0e-9
    end
  end

  test "coupled scale-step interpolation differs from endpoint linearization" do
    base_start = 1.0
    base_end = 2.0
    ratio_start = 1.2
    ratio_end = 1.5
    power = 4
    progress = 0.5

    coupled =
      scale_step_value(base_start, base_end, ratio_start, ratio_end, power, progress)

    endpoint_linearized =
      linear(
        base_start * integer_power(ratio_start, power),
        base_end * integer_power(ratio_end, power),
        progress
      )

    assert abs(coupled - endpoint_linearized) > 1.0e-6

    fallback =
      fallback_scale_step_value(
        base_start,
        base_end,
        ratio_start,
        ratio_end,
        power,
        750.0,
        500.0,
        1000.0
      )

    assert_in_delta fallback, coupled, 1.0e-9

    assert {:ok, plan} = call(:plan, [token_set(), [@step_path]])
    assert [step_value] = plan.values
    assert step_value.expression =~ "var(--lf-fluid-scale-typography-scale-primary-base)"
    assert step_value.expression =~ "var(--lf-fluid-scale-typography-scale-primary-ratio)"
    assert step_value.expression =~ "pow("
    refute step_value.expression =~ "clamp("
  end

  test "fallback progress matches bounded semantic interpolation at required samples" do
    domain_start = 500.0
    domain_end = 1000.0

    samples = [
      domain_start - 100,
      domain_start,
      domain_start + (domain_end - domain_start) * 0.25,
      domain_start + (domain_end - domain_start) * 0.5,
      domain_start + (domain_end - domain_start) * 0.75,
      domain_end,
      domain_end + 100
    ]

    values = [{1.0, 2.0}, {2.0, 1.0}, {1.5, 1.5}]

    for viewport <- samples, {start_value, end_value} <- values do
      reference =
        reference_value(
          start_value,
          end_value,
          reference_progress(viewport, domain_start, domain_end)
        )

      fallback = fallback_value(start_value, end_value, viewport, domain_start, domain_end)

      assert_in_delta fallback, reference, 1.0e-9
    end
  end

  test "deduplicates fallback and modern dependencies for values sharing a domain" do
    second_value = Map.put(@value, "start_value", %{"value" => 8, "unit" => "px"})
    second_value = Map.put(second_value, "end_value", %{"value" => 16, "unit" => "px"})

    set = put_token(token_set(), @second_value_path, token(@second_value_path, second_value))
    assert {:ok, plan} = call(:plan, [set, [@second_value_path, @value_path]])

    assert plan == %{
             fallback_dependencies: [
               %{
                 name: domain_variable_name(@domain_path),
                 expression: @fallback_progress
               }
             ],
             modern_overrides: [
               %{
                 name: domain_variable_name(@domain_path),
                 expression: "progress(100vw, 500px, 1000px)"
               }
             ],
             values: [
               %{
                 path: @value_path,
                 expression:
                   "calc(1rem + ((1.125rem - 1rem) * " <>
                     "var(--lf-fluid-domain-layout-fluid-viewport-default-progress)))"
               },
               %{
                 path: @second_value_path,
                 expression:
                   "calc(8px + ((16px - 8px) * " <>
                     "var(--lf-fluid-domain-layout-fluid-viewport-default-progress)))"
               }
             ]
           }

    assert length(plan.fallback_dependencies) == 1
    assert length(plan.modern_overrides) == 1
    assert length(plan.values) == 2
  end

  test "sorts dependencies by generated variable name across domains" do
    alpha_path = "alpha.fluid.viewport"
    zeta_path = "zeta.fluid.viewport"
    alpha_value_path = "spacing.fluid.alpha"
    zeta_value_path = "spacing.fluid.zeta"

    set = token_set()
    set = put_token(set, alpha_path, token(alpha_path, domain(400, 900)))
    set = put_token(set, zeta_path, token(zeta_path, domain(600, 1200)))
    set = put_token(set, alpha_value_path, token(alpha_value_path, value(alpha_path, 1, 2)))
    set = put_token(set, zeta_value_path, token(zeta_value_path, value(zeta_path, 3, 4)))

    assert {:ok, plan} = call(:plan, [set, [zeta_value_path, alpha_value_path]])

    names = Enum.map(plan.fallback_dependencies, & &1.name)
    assert names == Enum.sort(names)
    assert Enum.map(plan.modern_overrides, & &1.name) == names
  end

  test "plan output is independent of requested path order" do
    second_value = Map.put(@value, "start_value", %{"value" => 8, "unit" => "px"})
    second_value = Map.put(second_value, "end_value", %{"value" => 16, "unit" => "px"})
    set = put_token(token_set(), @second_value_path, token(@second_value_path, second_value))

    assert {:ok, forward} = call(:plan, [set, [@value_path, @second_value_path]])
    assert {:ok, reverse} = call(:plan, [set, [@second_value_path, @value_path]])
    assert forward == reverse
  end

  test "duplicate requested paths appear once in the values plan" do
    assert {:ok, plan} = call(:plan, [token_set(), [@value_path, @value_path]])

    assert plan.values == [
             %{
               path: @value_path,
               expression:
                 "calc(1rem + ((1.125rem - 1rem) * var(--lf-fluid-domain-layout-fluid-viewport-default-progress)))"
             }
           ]
  end

  test "returns the exact empty plan for no requested paths" do
    assert call(:plan, [token_set(), []]) ==
             {:ok, %{fallback_dependencies: [], modern_overrides: [], values: []}}
  end

  test "propagates missing and unresolved dependency errors from the resolver" do
    missing = delete_token(token_set(), @domain_path)
    unresolved = put_token(token_set(), @domain_path, token(@domain_path, nil, :unresolved))

    assert call(:legacy_value, [missing, @value_path]) ==
             {:error, {:token_not_found, @domain_path}}

    assert call(:plan, [unresolved, [@value_path]]) ==
             {:error, {:unresolved_dependency, @domain_path}}
  end

  test "propagates invalid dependency and unknown Fluid root errors unchanged" do
    wrong_domain = %{"type" => "color", "value" => "#123456"}
    wrong_dependency = put_token(token_set(), @domain_path, token(@domain_path, wrong_domain))
    unknown_path = "fluid.unknown"
    unknown_type = %{"type" => "fluid_unknown"}
    unknown_root = put_token(token_set(), unknown_path, token(unknown_path, unknown_type))

    assert call(:plan, [wrong_dependency, [@value_path]]) ==
             {:error, {:invalid_dependency_type, @domain_path, "fluid_domain"}}

    assert call(:legacy_value, [unknown_root, unknown_path]) ==
             {:error, {:invalid_root_type, unknown_path}}

    assert call(:plan, [unknown_root, [unknown_path]]) ==
             {:error, {:invalid_root_type, unknown_path}}
  end

  test "rejects unsupported domain, scale, and ordinary token roots" do
    set = token_set()

    set =
      put_token(
        set,
        @ordinary_path,
        token(@ordinary_path, %{"type" => "color", "value" => "#123456"})
      )

    set = put_token(set, @ordinary_scalar_path, token(@ordinary_scalar_path, 0.5))

    for path <- [@domain_path, @scale_path, @ordinary_path, @ordinary_scalar_path] do
      assert call(:legacy_value, [set, path]) == {:error, {:unsupported_realization, path}}
      assert call(:plan, [set, [path]]) == {:error, {:unsupported_realization, path}}
    end
  end

  test "rejects malformed path-list input without raising" do
    assert call(:plan, [token_set(), "spacing.fluid.gap"]) == {:error, :invalid_paths}
    assert call(:plan, [token_set(), [@value_path, 1]]) == {:error, :invalid_paths}
  end

  test "keeps underscored canonical path segments distinct in domain variable names" do
    first_domain = "spacing.fluid_gap"
    second_domain = "spacing_fluid.gap"
    first_value = "fluid.value.first"
    second_value = "fluid.value.second"

    set = token_set()
    set = put_token(set, first_domain, token(first_domain, domain(500, 1000)))
    set = put_token(set, second_domain, token(second_domain, domain(500, 1000)))
    set = put_token(set, first_value, token(first_value, value(first_domain, 1, 2)))
    set = put_token(set, second_value, token(second_value, value(second_domain, 1, 2)))

    assert {:ok, plan} = call(:plan, [set, [first_value, second_value]])

    assert Enum.map(plan.fallback_dependencies, & &1.name) == [
             "--lf-fluid-domain-spacing-fluid_gap-progress",
             "--lf-fluid-domain-spacing_fluid-gap-progress"
           ]
  end

  test "formats signed zero as zero and keeps small finite floats" do
    tiny = put_endpoints(@value, -0.0, 1.0e-30)
    set = put_token(token_set(), @value_path, token(@value_path, tiny))

    assert {:ok, expression} = call(:legacy_value, [set, @value_path])
    assert expression =~ "calc(0 + ((1.0e-30 - 0) * "
    assert expression =~ @fallback_progress
  end

  test "repeated serialization is byte-for-byte deterministic" do
    set = token_set()
    before = set

    assert call(:legacy_value, [set, @value_path]) == call(:legacy_value, [set, @value_path])
    assert call(:plan, [set, [@value_path]]) == call(:plan, [set, [@value_path]])
    assert set == before
    assert set.token_set_version == "1.0.0"
  end

  test "scale-step serialization is deterministic and leaves the TokenSet unchanged" do
    set = token_set()
    before = set

    first = call(:plan, [set, [@step_path]])
    second = call(:plan, [set, [@step_path]])

    assert first == second
    assert set == before
    assert set.token_set_version == "1.0.0"
  end

  defp call(function, arguments) do
    if Code.ensure_loaded?(@serializer) and
         function_exported?(@serializer, function, length(arguments)) do
      apply(@serializer, function, arguments)
    else
      flunk("#{inspect(@serializer)}.#{function}/#{length(arguments)} is not implemented")
    end
  end

  defp token_set do
    %TokenSet{
      tokens: %{
        @domain_path => token(@domain_path, @domain),
        @value_path => token(@value_path, @value),
        @scale_path => token(@scale_path, @scale),
        @step_path => token(@step_path, @step)
      }
    }
  end

  defp token(path, resolved_value, resolution_status \\ :resolved) do
    %Token{path: path, resolved_value: resolved_value, resolution_status: resolution_status}
  end

  defp value(domain_ref, start_value, end_value) do
    %{
      "type" => "fluid_value",
      "format_version" => "1.0.0",
      "domain_ref" => domain_ref,
      "start_value" => start_value,
      "end_value" => end_value,
      "interpolation" => "linear"
    }
  end

  defp scale(domain_ref, base_start, base_end, ratio_start, ratio_end) do
    %{
      "type" => "fluid_scale",
      "format_version" => "1.0.0",
      "domain_ref" => domain_ref,
      "base_start" => base_start,
      "base_end" => base_end,
      "ratio_start" => ratio_start,
      "ratio_end" => ratio_end
    }
  end

  defp scale_step(scale_ref, power) do
    %{
      "type" => "fluid_scale_step",
      "format_version" => "1.0.0",
      "scale_ref" => scale_ref,
      "power" => power
    }
  end

  defp domain_variable_name(path) do
    "--lf-fluid-domain-#{String.replace(path, ".", "-")}-progress"
  end

  defp domain(start_value, end_value) do
    %{
      "type" => "fluid_domain",
      "format_version" => "1.0.0",
      "input" => "viewport_width",
      "start" => %{"value" => start_value, "unit" => "px"},
      "end" => %{"value" => end_value, "unit" => "px"},
      "clamp_policy" => "bounded"
    }
  end

  defp put_endpoints(value, start_value, end_value) do
    value
    |> Map.put("start_value", start_value)
    |> Map.put("end_value", end_value)
  end

  defp put_token(%TokenSet{} = set, path, token) do
    %{set | tokens: Map.put(set.tokens, path, token)}
  end

  defp delete_token(%TokenSet{} = set, path) do
    %{set | tokens: Map.delete(set.tokens, path)}
  end

  defp reference_progress(input, start_value, end_value) do
    input
    |> Kernel.-(start_value)
    |> Kernel./(end_value - start_value)
    |> max(0.0)
    |> min(1.0)
  end

  defp fallback_progress(input, start_value, end_value) do
    input
    |> Kernel.-(start_value)
    |> then(&:math.atan2(&1, end_value - start_value))
    |> :math.tan()
    |> max(0.0)
    |> min(1.0)
  end

  defp reference_value(start_value, end_value, progress) do
    start_value + (end_value - start_value) * progress
  end

  defp bounded_progress(input, start_value, end_value) do
    input
    |> Kernel.-(start_value)
    |> Kernel./(end_value - start_value)
    |> max(0.0)
    |> min(1.0)
  end

  defp linear(start_value, end_value, progress) do
    start_value + (end_value - start_value) * progress
  end

  defp linear_base(start_value, end_value, progress) do
    linear(start_value, end_value, progress)
  end

  defp linear_ratio(start_value, end_value, progress) do
    linear(start_value, end_value, progress)
  end

  defp integer_power(_value, 0), do: 1.0

  defp integer_power(value, power) when power < 0 do
    1.0 / integer_power(value, -power)
  end

  defp integer_power(value, power) when power > 0 do
    Enum.reduce(1..power, 1.0, fn _index, result -> result * value end)
  end

  defp scale_step_value(base_start, base_end, ratio_start, ratio_end, power, progress) do
    base = linear_base(base_start, base_end, progress)
    ratio = linear_ratio(ratio_start, ratio_end, progress)
    base * integer_power(ratio, power)
  end

  defp fallback_scale_step_value(
         base_start,
         base_end,
         ratio_start,
         ratio_end,
         power,
         viewport,
         domain_start,
         domain_end
       ) do
    progress = fallback_progress(viewport, domain_start, domain_end)

    scale_step_value(base_start, base_end, ratio_start, ratio_end, power, progress)
  end

  defp fallback_value(start_value, end_value, input, domain_start, domain_end) do
    reference_value(start_value, end_value, fallback_progress(input, domain_start, domain_end))
  end
end
