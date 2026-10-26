defmodule LiveFrames.Styling.Fluid.NativeFixtureTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Styling.TokenBridge
  alias LiveFrames.Tokens
  alias LiveFrames.Tokens.CSSValue
  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet

  @fixture_path Path.expand("../../../fixtures/fluid/native_coordinated_v1.tokens.json", __DIR__)

  @domain_path "layout.fluid.viewport.default"
  @typography_scale_path "typography.scale.primary"
  @spacing_scale_path "spacing.scale.primary"
  @descending_path "spacing.fluid.descending"

  @domain_progress_var "--lf-fluid-domain-layout-fluid-viewport-default-progress"
  @typography_base_var "--lf-fluid-scale-typography-scale-primary-base"
  @typography_ratio_var "--lf-fluid-scale-typography-scale-primary-ratio"
  @spacing_base_var "--lf-fluid-scale-spacing-scale-primary-base"
  @spacing_ratio_var "--lf-fluid-scale-spacing-scale-primary-ratio"
  @supports_query "@supports (opacity: progress(1px, 0px, 1px))"

  @domain %{
    "type" => "fluid_domain",
    "format_version" => "1.0.0",
    "input" => "viewport_width",
    "start" => %{"value" => 500, "unit" => "px"},
    "end" => %{"value" => 1000, "unit" => "px"},
    "clamp_policy" => "bounded"
  }

  @typography_scale %{
    "type" => "fluid_scale",
    "format_version" => "1.0.0",
    "domain_ref" => @domain_path,
    "base_start" => %{"value" => 1.0, "unit" => "rem"},
    "base_end" => %{"value" => 1.125, "unit" => "rem"},
    "ratio_start" => 1.2,
    "ratio_end" => 1.414
  }

  @spacing_scale %{
    "type" => "fluid_scale",
    "format_version" => "1.0.0",
    "domain_ref" => @domain_path,
    "base_start" => %{"value" => 0.5, "unit" => "rem"},
    "base_end" => %{"value" => 1.0, "unit" => "rem"},
    "ratio_start" => 1.1,
    "ratio_end" => 1.25
  }

  @descending_value %{
    "type" => "fluid_value",
    "format_version" => "1.0.0",
    "domain_ref" => @domain_path,
    "start_value" => %{"value" => 2, "unit" => "rem"},
    "end_value" => %{"value" => 1, "unit" => "rem"},
    "interpolation" => "linear"
  }

  @typography_steps [
    {"typography.fluid.body", 0, "--lf-native-type-body"},
    {"typography.fluid.h4", 1, "--lf-native-type-h4"},
    {"typography.fluid.h3", 2, "--lf-native-type-h3"},
    {"typography.fluid.h2", 3, "--lf-native-type-h2"},
    {"typography.fluid.h1", 4, "--lf-native-type-h1"}
  ]

  @spacing_steps [
    {"spacing.fluid.xs", -2, "--lf-native-space-xs"},
    {"spacing.fluid.s", -1, "--lf-native-space-s"},
    {"spacing.fluid.m", 0, "--lf-native-space-m"},
    {"spacing.fluid.l", 1, "--lf-native-space-l"},
    {"spacing.fluid.xl", 2, "--lf-native-space-xl"},
    {"spacing.fluid.xxl", 3, "--lf-native-space-xxl"}
  ]

  @scale_steps Enum.map(@typography_steps, fn {path, power, variable} ->
                 {path, power, variable, @typography_base_var, @typography_ratio_var}
               end) ++
                 Enum.map(@spacing_steps, fn {path, power, variable} ->
                   {path, power, variable, @spacing_base_var, @spacing_ratio_var}
                 end)

  @mapped_declarations Enum.map(@typography_steps, fn {path, _power, variable} ->
                         {path, variable}
                       end) ++
                         Enum.map(@spacing_steps, fn {path, _power, variable} ->
                           {path, variable}
                         end) ++
                         [{@descending_path, "--lf-native-space-descending"}]

  @scale_dependency_vars [
    @typography_base_var,
    @typography_ratio_var,
    @spacing_base_var,
    @spacing_ratio_var
  ]

  test "serializes and progressively materializes the coordinated native fixture" do
    token_set = build_token_set()
    token_set_before = token_set

    assert :ok = Tokens.validate(token_set)
    assert token_set_count(token_set) == 15

    assert semantic_type_counts(token_set) == %{
             "fluid_domain" => 1,
             "fluid_value" => 1,
             "fluid_scale" => 2,
             "fluid_scale_step" => 11
           }

    assert_reference_authority(token_set)
    assert_scale_values(token_set)

    encoded_before = Tokens.encode!(token_set)
    assert encoded_before == Tokens.encode!(token_set)
    assert encoded_before == File.read!(@fixture_path)
    assert Tokens.encode!(build_token_set(:reversed)) == encoded_before

    mapping = package_mapping()
    assert length(mapping["entries"]) == 12

    refute Enum.any?(mapping["entries"], fn entry ->
             entry["token_set_path"] in [
               @domain_path,
               @typography_scale_path,
               @spacing_scale_path
             ]
           end)

    assert {:ok, css} = TokenBridge.generate(token_set, mapping, fluid_output: :progressive)

    assert {:ok, repeated_css} =
             TokenBridge.generate(token_set, mapping, fluid_output: :progressive)

    reversed_mapping = Map.put(mapping, "entries", Enum.reverse(mapping["entries"]))

    assert {:ok, reversed_mapping_css} =
             TokenBridge.generate(token_set, reversed_mapping, fluid_output: :progressive)

    assert css == repeated_css
    assert css == reversed_mapping_css

    fallback = fallback_block(css)
    modern = modern_block(css)
    dependency_vars = [@domain_progress_var | @scale_dependency_vars]

    assert Enum.map(dependency_vars, &declaration_count(fallback, &1)) == [1, 1, 1, 1, 1]
    assert Enum.sum(Enum.map(dependency_vars, &declaration_count(fallback, &1))) == 5
    assert Enum.sum(Enum.map(dependency_vars, &declaration_count(css, &1))) == 6
    assert declaration_count(fallback, @domain_progress_var) == 1
    assert declaration_count(modern, @domain_progress_var) == 1
    assert declaration_count(css, @domain_progress_var) == 2
    assert fallback_declaration_count(modern) == 1

    assert Enum.sum(
             Enum.map(@mapped_declarations, fn {_path, variable} ->
               declaration_count(fallback, variable)
             end)
           ) == 12

    assert Enum.all?(@mapped_declarations, fn {_path, variable} ->
             declaration_count(css, variable) == 1 and declaration_count(modern, variable) == 0
           end)

    assert Enum.all?(@scale_dependency_vars, fn variable ->
             declaration_count(modern, variable) == 0
           end)

    assert fallback_declaration_count(fallback) == 17

    assert_scale_step_realization(token_set, css)
    assert_descending_realization(token_set, css)
    assert_source_neutral(encoded_before, css)

    assert token_set == token_set_before
    assert Tokens.encode!(token_set) == encoded_before
  end

  defp build_token_set(order \\ :forward) do
    definitions = token_definitions()
    definitions = if order == :reversed, do: Enum.reverse(definitions), else: definitions

    tokens =
      Map.new(definitions, fn {path, category, semantic, references} ->
        {path, token(path, category, semantic, references)}
      end)

    %TokenSet{
      token_set_version: Tokens.current_token_set_version(),
      source_metadata: %{},
      tokens: tokens,
      diagnostics: []
    }
  end

  defp token_definitions do
    [
      {@domain_path, :layout, @domain, []},
      {@typography_scale_path, :typography, @typography_scale, [@domain_path]},
      {@spacing_scale_path, :spacing, @spacing_scale, [@domain_path]}
    ] ++
      Enum.map(@typography_steps, fn {path, power, _variable} ->
        {path, :typography, scale_step(@typography_scale_path, power), [@typography_scale_path]}
      end) ++
      Enum.map(@spacing_steps, fn {path, power, _variable} ->
        {path, :spacing, scale_step(@spacing_scale_path, power), [@spacing_scale_path]}
      end) ++
      [{@descending_path, :spacing, @descending_value, [@domain_path]}]
  end

  defp token(path, category, semantic, references) do
    Token.new(
      path: path,
      category: category,
      value: semantic,
      resolved_value: semantic,
      source_expression: nil,
      resolution_status: :resolved,
      references: references,
      provenance: %{},
      metadata: %{}
    )
  end

  defp scale_step(scale_path, power) do
    %{
      "type" => "fluid_scale_step",
      "format_version" => "1.0.0",
      "scale_ref" => scale_path,
      "power" => power
    }
  end

  defp package_mapping do
    %{
      "schema_version" => "1.0.0",
      "mapping_version" => "native_fluid_fixture_v1",
      "entries" =>
        Enum.map(@mapped_declarations, fn {path, variable} ->
          %{"token_set_path" => path, "css_variable" => variable}
        end)
    }
  end

  defp token_set_count(token_set), do: map_size(token_set.tokens)

  defp semantic_type_counts(token_set) do
    token_set.tokens
    |> Map.values()
    |> Enum.map(& &1.resolved_value["type"])
    |> Enum.frequencies()
  end

  defp assert_reference_authority(token_set) do
    assert Map.fetch!(token_set.tokens, @domain_path).references == []

    for {path, token} <- token_set.tokens do
      {expected_references, expected_category} =
        case token.resolved_value["type"] do
          "fluid_domain" ->
            {[], :layout}

          "fluid_value" ->
            assert token.resolved_value["domain_ref"] == @domain_path
            {[@domain_path], :spacing}

          "fluid_scale" ->
            assert token.resolved_value["domain_ref"] == @domain_path
            category = if path == @typography_scale_path, do: :typography, else: :spacing
            {[@domain_path], category}

          "fluid_scale_step" ->
            scale_path = token.resolved_value["scale_ref"]
            category = if scale_path == @typography_scale_path, do: :typography, else: :spacing
            {[scale_path], category}
        end

      assert token.references == expected_references, path
      assert token.category == expected_category, path
      assert token.resolution_status == :resolved, path
      assert token.path == path, path
      assert token.value == token.resolved_value, path
      assert token.source_expression == nil, path
      assert token.provenance == %{}, path
      assert token.metadata == %{}, path
    end
  end

  defp assert_scale_values(token_set) do
    assert Map.fetch!(token_set.tokens, @domain_path).resolved_value == @domain

    assert Map.fetch!(token_set.tokens, @typography_scale_path).resolved_value ==
             @typography_scale

    assert Map.fetch!(token_set.tokens, @spacing_scale_path).resolved_value == @spacing_scale
    assert Map.fetch!(token_set.tokens, @descending_path).resolved_value == @descending_value

    assert Enum.map(@typography_steps, fn {path, _power, _variable} ->
             Map.fetch!(token_set.tokens, path).resolved_value["power"]
           end) == [0, 1, 2, 3, 4]

    assert Enum.map(@spacing_steps, fn {path, _power, _variable} ->
             Map.fetch!(token_set.tokens, path).resolved_value["power"]
           end) == [-2, -1, 0, 1, 2, 3]
  end

  defp assert_scale_step_realization(token_set, css) do
    for {path, power, variable, base_variable, ratio_variable} <- @scale_steps do
      token = Map.fetch!(token_set.tokens, path)
      assert {:ok, expected} = CSSValue.candidate(token_set, token, fluid_target: :fallback)
      assert expected =~ "var(#{base_variable})"
      assert expected =~ "pow(var(#{ratio_variable}), #{power})"
      assert css =~ "#{variable}: #{expected};"
      refute expected =~ "500px"
      refute expected =~ "1000px"
    end
  end

  defp assert_descending_realization(token_set, css) do
    token = Map.fetch!(token_set.tokens, @descending_path)
    assert {:ok, expected} = CSSValue.candidate(token_set, token, fluid_target: :fallback)
    assert Regex.match?(~r/^calc\(2rem \+ \(\(1rem - 2rem\)/, expected)
    assert css =~ "--lf-native-space-descending: #{expected};"
  end

  defp assert_source_neutral(encoded_fixture, css) do
    for source_name <- ["automatic", "acss", "bricks", "frames", "wordpress"] do
      refute String.contains?(encoded_fixture, source_name)
      refute String.contains?(css, source_name)
    end
  end

  defp fallback_block(css), do: css |> String.split(@supports_query, parts: 2) |> hd()

  defp modern_block(css) do
    case String.split(css, @supports_query, parts: 2) do
      [_fallback, modern] -> modern
      [_fallback] -> flunk("progressive stylesheet has no modern override")
    end
  end

  defp declaration_count(css, variable) do
    Regex.scan(~r/^\s*#{Regex.escape(variable)}:/m, css) |> length()
  end

  defp fallback_declaration_count(css) do
    Regex.scan(~r/^\s*--[^:\s]+:/m, css) |> length()
  end
end
