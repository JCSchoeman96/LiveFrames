defmodule LiveFrames.BricksDependencyExtractorStructuralTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.Bricks.DependencyExtractor
  alias LiveFrames.Styles.StructuralVariableAuthority
  alias LiveFrames.Tokens.VariableAuthority

  defp structural_index do
    assert {:ok, index} =
             AutomaticCSS.structural_variable_authority("4.0.1", grid_variables_enabled: true)

    index
  end

  test "without structural authority --grid-1 remains a source variable dependency" do
    [variable] =
      DependencyExtractor.variables(["var(--grid-1)"], authority_index: %VariableAuthority{})

    assert variable.status == :source_variable
    assert variable.resolution_reason == "mapping_unproven"
  end

  test "with structural authority --grid-1 resolves as resolved_structural" do
    [variable] =
      DependencyExtractor.variables(
        ["var(--grid-1)"],
        authority_index: %VariableAuthority{},
        structural_authority_index: structural_index()
      )

    assert variable.status == :resolved_structural
    assert variable.structural_authority_id == "automatic-css-4.0.1:structural-grid:grid-1"
    assert variable.structural_resolved_value == "repeat(1, minmax(0, 1fr))"
    assert variable.structural_authority_state == :unique_candidate
  end

  test "token ambiguity prevents structural resolution in dependencies" do
    authority = %{
      "variable" => "--grid-1",
      "kind" => "source_reference",
      "authority_id" => "synthetic:grid-1:a",
      "source_key" => "grid-1",
      "source_version" => "4.0.1"
    }

    token = %LiveFrames.Tokens.Token{
      path: "layout.grid.alpha",
      category: :layout,
      value: "repeat(1, minmax(0, 1fr))",
      resolved_value: "repeat(1, minmax(0, 1fr))",
      source_expression: "repeat(1, minmax(0, 1fr))",
      resolution_status: :resolved,
      metadata: %{"variable_authorities" => [authority]}
    }

    {:ok, authority_index} =
      VariableAuthority.build(
        LiveFrames.Tokens.TokenSet.new(
          tokens: %{
            "layout.grid.alpha" => token,
            "layout.grid.zulu" => %{token | path: "layout.grid.zulu"}
          }
        )
      )

    [variable] =
      DependencyExtractor.variables(
        ["var(--grid-1)"],
        authority_index: authority_index,
        structural_authority_index: structural_index()
      )

    assert variable.status == :ambiguous_token
    assert variable.resolution_reason == "mapping_ambiguous"
  end

  test "ambiguous structural authority remains unresolved in dependencies" do
    assert {:ok, ambiguous_index} =
             StructuralVariableAuthority.build([
               %{
                 "variable" => "--grid-1",
                 "resolved_value" => "repeat(1, minmax(0, 1fr))",
                 "authority_id" => "id-a",
                 "source_system" => "automatic_css",
                 "source_version" => "4.0.1",
                 "authority_type" => "PROJECT_SOURCE_ENVIRONMENT_GENERATED_CSS"
               },
               %{
                 "variable" => "--grid-1",
                 "resolved_value" => "repeat(1, minmax(0, 1fr))",
                 "authority_id" => "id-b",
                 "source_system" => "automatic_css",
                 "source_version" => "4.0.1",
                 "authority_type" => "PROJECT_SOURCE_ENVIRONMENT_GENERATED_CSS"
               }
             ])

    [variable] =
      DependencyExtractor.variables(
        ["var(--grid-1)"],
        authority_index: %VariableAuthority{},
        structural_authority_index: ambiguous_index
      )

    assert variable.status == :ambiguous_structural
    assert variable.resolution_reason == "structural_ambiguous"
  end

  test "resolved structural variables are not classified as source variables" do
    [variable] =
      DependencyExtractor.variables(
        ["var(--grid-1)"],
        authority_index: %VariableAuthority{},
        structural_authority_index: structural_index()
      )

    assert variable.status == :resolved_structural
    refute variable.status == :source_variable
  end
end
