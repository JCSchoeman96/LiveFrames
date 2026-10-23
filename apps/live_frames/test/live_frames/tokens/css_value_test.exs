defmodule LiveFrames.Tokens.CSSValueTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Tokens
  alias LiveFrames.Tokens.CSSValue
  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet
  alias LiveFrames.Styling.Fluid.CSSSerializer

  @fluid_domain_path "layout.fluid.viewport.default"
  @fluid_value_path "spacing.fluid.gap"
  @fluid_scale_path "typography.scale.primary"
  @fluid_step_path "typography.heading.h1"

  @fluid_domain %{
    "type" => "fluid_domain",
    "format_version" => "1.0.0",
    "input" => "viewport_width",
    "start" => %{"value" => 500, "unit" => "px"},
    "end" => %{"value" => 1000, "unit" => "px"},
    "clamp_policy" => "bounded"
  }

  @fluid_value %{
    "type" => "fluid_value",
    "format_version" => "1.0.0",
    "domain_ref" => @fluid_domain_path,
    "start_value" => %{"value" => 1, "unit" => "rem"},
    "end_value" => %{"value" => 1.125, "unit" => "rem"},
    "interpolation" => "linear"
  }

  @fluid_scale %{
    "type" => "fluid_scale",
    "format_version" => "1.0.0",
    "domain_ref" => @fluid_domain_path,
    "base_start" => %{"value" => 1, "unit" => "rem"},
    "base_end" => %{"value" => 1.125, "unit" => "rem"},
    "ratio_start" => 1.2,
    "ratio_end" => 1.414
  }

  @fluid_step %{
    "type" => "fluid_scale_step",
    "format_version" => "1.0.0",
    "scale_ref" => @fluid_scale_path,
    "power" => 4
  }

  @fallback_progress "clamp(0, tan(atan2(calc(100vw - 500px), calc(1000px - 500px))), 1)"

  defp token(attrs) do
    struct(
      Token,
      [path: "color.primary", category: :color, resolution_status: :resolved] ++ attrs
    )
  end

  defp serialized(token) do
    Tokens.to_map(%TokenSet{tokens: %{token.path => token}})["tokens"][token.path]
  end

  test "returns the strongest supported CSS candidate for structs and serialized token maps" do
    cases = [
      {token(resolved_value: "red", metadata: %{"css_expression" => "var(--brand)"}),
       "var(--brand)"},
      {token(resolved_value: "red", metadata: %{css_expression: "var(--brand)"}), "var(--brand)"},
      {token(resolved_value: "red"), "red"},
      {token(resolved_value: 0), "0"},
      {token(resolved_value: 1.5), "1.5"},
      {token(resolved_value: 7, metadata: %{"css_expression" => ""}), "7"},
      {token(resolved_value: %{"type" => "derived"}, source_expression: "--legacy-value"),
       "var(--legacy-value)"},
      {token(resolved_value: %{type: "derived"}, source_expression: "--legacy-value"),
       "var(--legacy-value)"}
    ]

    for {value, expected} <- cases do
      assert CSSValue.candidate(value) == {:ok, expected}
      assert CSSValue.candidate(serialized(value)) == {:ok, expected}
    end
  end

  test "returns candidates without applying CSS safety policy" do
    unsafe = token(resolved_value: "red; } body { color: red")

    assert CSSValue.candidate(unsafe) == {:ok, "red; } body { color: red"}
    assert CSSValue.candidate(serialized(unsafe)) == {:ok, "red; } body { color: red"}
  end

  test "reports unresolved, missing, and non-serializable token values" do
    rejected = [
      {token(resolution_status: :unresolved, resolved_value: nil), {:error, :unresolved}},
      {token(resolved_value: nil), {:error, :resolved_value_missing}},
      {
        token(resolved_value: nil, metadata: %{"css_expression" => "var(--brand)"}),
        {:error, :resolved_value_missing}
      },
      {
        token(resolved_value: %{"type" => "responsive", "min" => "16px", "max" => "18px"}),
        {:error, :non_serializable}
      },
      {token(resolved_value: %{"unknown" => "structured value"}), {:error, :non_serializable}},
      {token(resolved_value: ""), {:error, :non_serializable}}
    ]

    for {value, expected} <- rejected do
      assert CSSValue.candidate(value) == expected
      assert CSSValue.candidate(serialized(value)) == expected
    end
  end

  test "matches candidate/1 for non-Fluid tokens at every valid target" do
    values = [
      token(resolved_value: "red", metadata: %{"css_expression" => "var(--brand)"}),
      token(resolved_value: "red"),
      token(resolved_value: 7),
      token(resolved_value: 1.5),
      token(resolved_value: %{"type" => "derived"}, source_expression: "--legacy-value"),
      token(resolution_status: :unresolved, resolved_value: nil),
      token(resolved_value: nil),
      token(resolved_value: %{"type" => "responsive", "min" => "16px", "max" => "18px"}),
      token(resolved_value: "red; } body { color: red")
    ]

    for fluid_target <- [:legacy, :fallback, :modern], value <- values do
      assert CSSValue.candidate(%TokenSet{}, value, fluid_target: fluid_target) ==
               CSSValue.candidate(value)
    end
  end

  test "adds candidate/3 without adding candidate/2 and defaults Fluid to legacy" do
    token = token(path: @fluid_value_path, resolved_value: @fluid_value)
    token_set = fluid_token_set()

    assert function_exported?(CSSValue, :candidate, 2) == false

    assert CSSValue.candidate(token_set, token, []) ==
             CSSSerializer.legacy_value(token_set, @fluid_value_path)

    assert CSSValue.candidate(token_set, token, fluid_target: :legacy) ==
             {:ok,
              "calc(1rem + ((1.125rem - 1rem) * " <>
                @fallback_progress <>
                "))"}
  end

  test "returns the dependency-backed FluidValue expression for fallback and modern" do
    token_set = fluid_token_set()
    value_token = Map.fetch!(token_set.tokens, @fluid_value_path)

    assert {:ok, fallback} =
             CSSValue.candidate(token_set, value_token, fluid_target: :fallback)

    assert fallback ==
             "calc(1rem + ((1.125rem - 1rem) * " <>
               "var(--lf-fluid-domain-layout-fluid-viewport-default-progress)))"

    assert {:ok, modern} = CSSValue.candidate(token_set, value_token, fluid_target: :modern)
    assert modern == fallback
    assert fallback =~ "var(--lf-fluid-domain-"
    refute fallback =~ "progress("
  end

  test "returns the coupled FluidScaleStep expression for fallback and modern" do
    token_set = fluid_token_set()
    step_token = Map.fetch!(token_set.tokens, @fluid_step_path)

    assert {:ok, fallback} = CSSValue.candidate(token_set, step_token, fluid_target: :fallback)

    assert fallback ==
             "calc(var(--lf-fluid-scale-typography-scale-primary-base) * " <>
               "pow(var(--lf-fluid-scale-typography-scale-primary-ratio), 4))"

    assert {:ok, modern} = CSSValue.candidate(token_set, step_token, fluid_target: :modern)
    assert modern == fallback
    assert fallback =~ "var(--lf-fluid-scale-typography-scale-primary-base)"
    assert fallback =~ "var(--lf-fluid-scale-typography-scale-primary-ratio)"
    assert fallback =~ "pow("
  end

  test "rejects FluidScaleStep legacy realization without endpoint approximation" do
    token_set = fluid_token_set()
    step_token = Map.fetch!(token_set.tokens, @fluid_step_path)

    assert CSSValue.candidate(token_set, step_token, fluid_target: :legacy) ==
             {:error, {:unsupported_realization, @fluid_step_path}}
  end

  test "does not realize direct FluidScale or FluidDomain roots for any target" do
    token_set = fluid_token_set()

    for {path, target} <- [
          {@fluid_scale_path, @fluid_scale},
          {@fluid_domain_path, @fluid_domain}
        ],
        fluid_target <- [:legacy, :fallback, :modern] do
      root_token = Map.fetch!(token_set.tokens, path)
      assert root_token.resolved_value == target

      assert CSSValue.candidate(token_set, root_token, fluid_target: fluid_target) ==
               {:error, {:unsupported_realization, path}}
    end
  end

  test "rejects an invalid target before checking token resolution or Fluid semantics" do
    unresolved = token(resolution_status: :unresolved, resolved_value: nil)
    fluid = token(path: @fluid_value_path, resolved_value: @fluid_value)

    for value <- [unresolved, fluid] do
      assert CSSValue.candidate(%TokenSet{}, value, fluid_target: :experimental) ==
               {:error, {:invalid_fluid_target, :experimental}}
    end
  end

  test "contextual Fluid semantics take precedence over historical CSS metadata" do
    token =
      token(
        path: @fluid_value_path,
        resolved_value: @fluid_value,
        metadata: %{"css_expression" => "var(--historical)"}
      )

    token_set = put_fluid_token(fluid_token_set(), @fluid_value_path, token)

    assert CSSValue.candidate(token) == {:ok, "var(--historical)"}

    assert CSSValue.candidate(token_set, token, fluid_target: :fallback) ==
             {:ok,
              "calc(1rem + ((1.125rem - 1rem) * " <>
                "var(--lf-fluid-domain-layout-fluid-viewport-default-progress)))"}
  end

  test "propagates missing, unresolved, and wrong-type Fluid dependency errors" do
    token_set = fluid_token_set()
    value_token = Map.fetch!(token_set.tokens, @fluid_value_path)
    step_token = Map.fetch!(token_set.tokens, @fluid_step_path)

    missing_domain = delete_fluid_token(token_set, @fluid_domain_path)

    unresolved_domain =
      put_fluid_token(
        token_set,
        @fluid_domain_path,
        token(path: @fluid_domain_path, resolution_status: :unresolved, resolved_value: nil)
      )

    wrong_domain =
      put_fluid_token(
        token_set,
        @fluid_domain_path,
        token(path: @fluid_domain_path, resolved_value: %{"type" => "color", "value" => "red"})
      )

    missing_scale = delete_fluid_token(token_set, @fluid_scale_path)

    wrong_scale =
      put_fluid_token(
        token_set,
        @fluid_scale_path,
        token(path: @fluid_scale_path, resolved_value: @fluid_domain)
      )

    cases = [
      {missing_domain, value_token, {:token_not_found, @fluid_domain_path}},
      {unresolved_domain, value_token, {:unresolved_dependency, @fluid_domain_path}},
      {wrong_domain, value_token, {:invalid_dependency_type, @fluid_domain_path, "fluid_domain"}},
      {missing_scale, step_token, {:token_not_found, @fluid_scale_path}},
      {wrong_scale, step_token, {:invalid_dependency_type, @fluid_scale_path, "fluid_scale"}}
    ]

    for fluid_target <- [:legacy, :fallback, :modern],
        {set, root_token, reason} <- cases do
      assert CSSValue.candidate(set, root_token, fluid_target: fluid_target) == {:error, reason}
    end
  end

  test "Fluid candidates leave the TokenSet unchanged and are deterministic" do
    token_set = fluid_token_set()
    before = token_set

    for path <- [@fluid_value_path, @fluid_step_path],
        fluid_target <- [:legacy, :fallback, :modern] do
      value = Map.fetch!(token_set.tokens, path)
      first = CSSValue.candidate(token_set, value, fluid_target: fluid_target)

      assert CSSValue.candidate(token_set, value, fluid_target: fluid_target) == first
    end

    assert token_set == before
    assert token_set.token_set_version == "1.0.0"
  end

  defp fluid_token_set do
    %TokenSet{
      tokens: %{
        @fluid_domain_path => token(path: @fluid_domain_path, resolved_value: @fluid_domain),
        @fluid_value_path => token(path: @fluid_value_path, resolved_value: @fluid_value),
        @fluid_scale_path => token(path: @fluid_scale_path, resolved_value: @fluid_scale),
        @fluid_step_path => token(path: @fluid_step_path, resolved_value: @fluid_step)
      }
    }
  end

  defp put_fluid_token(%TokenSet{} = token_set, path, fluid_token) do
    %{token_set | tokens: Map.put(token_set.tokens, path, fluid_token)}
  end

  defp delete_fluid_token(%TokenSet{} = token_set, path) do
    %{token_set | tokens: Map.delete(token_set.tokens, path)}
  end
end
