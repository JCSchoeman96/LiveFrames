defmodule LiveFrames.Styling.Fluid.ResolverTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Styling.Fluid.Resolver
  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet

  @domain_path "layout.fluid.viewport.default"
  @value_path "spacing.fluid.gap"
  @scale_path "typography.scale.primary"
  @step_path "typography.heading.h1"
  @ordinary_path "color.primary"

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

  test "resolves a domain without dependencies" do
    token_set = %TokenSet{tokens: %{@domain_path => token(@domain_path, @domain)}}

    assert resolve(token_set, @domain_path) == {:ok, %{semantic: @domain}}
  end

  test "resolves a value with its original domain semantic" do
    assert resolve(token_set(), @value_path) ==
             {:ok, %{semantic: @value, domain: @domain}}
  end

  test "resolves a scale with its original domain semantic" do
    assert resolve(token_set(), @scale_path) ==
             {:ok, %{semantic: @scale, domain: @domain}}
  end

  test "resolves a scale step with its original scale and domain semantics" do
    assert resolve(token_set(), @step_path) ==
             {:ok, %{semantic: @step, scale: @scale, domain: @domain}}
  end

  test "reports a missing requested path" do
    assert resolve(token_set(), "missing.path") ==
             {:error, {:token_not_found, "missing.path"}}
  end

  test "rejects an unresolved requested token" do
    for unresolved <- [
          token(@domain_path, @domain, :unresolved),
          token(@domain_path, nil, :resolved)
        ] do
      token_set = %TokenSet{tokens: %{@domain_path => unresolved}}

      assert resolve(token_set, @domain_path) ==
               {:error, {:unresolved_dependency, @domain_path}}
    end
  end

  test "rejects unresolved value and scale domains" do
    unresolved_domains = [
      token(@domain_path, @domain, :unresolved),
      token(@domain_path, nil, :resolved)
    ]

    for unresolved_domain <- unresolved_domains do
      token_set = token_set() |> put_token(@domain_path, unresolved_domain)

      assert resolve(token_set, @value_path) ==
               {:error, {:unresolved_dependency, @domain_path}}

      assert resolve(token_set, @scale_path) ==
               {:error, {:unresolved_dependency, @domain_path}}
    end
  end

  test "rejects an unresolved scale dependency for a scale step" do
    token_set = token_set() |> put_token(@scale_path, token(@scale_path, @scale, :unresolved))

    assert resolve(token_set, @step_path) ==
             {:error, {:unresolved_dependency, @scale_path}}
  end

  test "rejects an unresolved domain below a resolved scale step" do
    token_set = token_set() |> put_token(@domain_path, token(@domain_path, nil, :resolved))

    assert resolve(token_set, @step_path) ==
             {:error, {:unresolved_dependency, @domain_path}}
  end

  test "rejects wrong dependency types for values, scales, and scale steps" do
    ordinary = token(@domain_path, %{"type" => "color", "value" => "#32a2c1"})
    wrong_domain = token_set() |> put_token(@domain_path, ordinary)

    assert resolve(wrong_domain, @value_path) ==
             {:error, {:invalid_dependency_type, @domain_path, "fluid_domain"}}

    assert resolve(wrong_domain, @scale_path) ==
             {:error, {:invalid_dependency_type, @domain_path, "fluid_domain"}}

    wrong_scale = token_set() |> put_token(@scale_path, token(@scale_path, @domain))

    assert resolve(wrong_scale, @step_path) ==
             {:error, {:invalid_dependency_type, @scale_path, "fluid_scale"}}
  end

  test "reports a missing dependency path" do
    token_set = token_set() |> delete_token(@domain_path)

    assert resolve(token_set, @value_path) ==
             {:error, {:token_not_found, @domain_path}}
  end

  test "rejects a non-Fluid requested root" do
    ordinary = token(@ordinary_path, %{"type" => "color", "value" => "#32a2c1"})
    token_set = %TokenSet{tokens: %{@ordinary_path => ordinary}}

    assert resolve(token_set, @ordinary_path) ==
             {:error, {:invalid_root_type, @ordinary_path}}
  end

  test "returns deterministic results and errors for repeated resolution" do
    token_set = token_set()

    for path <- [@step_path, "missing.path"] do
      result = resolve(token_set, path)

      assert resolve(token_set, path) == result
      assert resolve(token_set, path) == result
    end
  end

  test "leaves the TokenSet unchanged after success and failure" do
    initial_sets = [
      {token_set(), @step_path, {:ok, %{semantic: @step, scale: @scale, domain: @domain}}},
      {token_set() |> put_token(@domain_path, token(@domain_path, nil, :resolved)), @step_path,
       {:error, {:unresolved_dependency, @domain_path}}},
      {token_set(), "missing.path", {:error, {:token_not_found, "missing.path"}}}
    ]

    for {token_set, path, expected} <- initial_sets do
      before = token_set

      assert resolve(token_set, path) == expected
      assert token_set == before
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

  defp resolve(token_set, path) do
    Resolver.resolve(token_set, path)
  end

  defp put_token(%TokenSet{} = token_set, path, token) do
    %{token_set | tokens: Map.put(token_set.tokens, path, token)}
  end

  defp delete_token(%TokenSet{} = token_set, path) do
    %{token_set | tokens: Map.delete(token_set.tokens, path)}
  end
end
