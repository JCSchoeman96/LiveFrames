defmodule LiveFrames.BricksDependencyExtractorStructuralTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Adapters.Bricks.DependencyExtractor
  alias LiveFrames.Styles.StructuralVariableAuthority
  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet
  alias LiveFrames.Tokens.VariableAuthority

  @token_fixture_path Path.expand(
                        "../../../../fixtures/automatic_css/acss_settings.json",
                        __DIR__
                      )

  defp structural_index do
    assert {:ok, index} =
             AutomaticCSS.structural_variable_authority("4.0.1", grid_variables_enabled: true)

    index
  end

  defp token_set do
    {:ok, token_set, _diagnostics} =
      AutomaticCSS.from_file(
        @token_fixture_path,
        source_version: "4.0.1",
        source_version_status: "fixture_reference",
        strict: true,
        profile: :hero_foundation
      )

    token_set
  end

  defp synthetic_source(settings) do
    %{
      "source" => "bricksCopiedElements",
      "sourceUrl" => "https://example.test/export.json",
      "version" => "2.3.1",
      "content" => [%{"id" => "proxy-a", "cid" => "component-a", "name" => "section"}],
      "components" => [
        %{
          "id" => "component-a",
          "elements" => [
            %{
              "id" => "root",
              "name" => "block",
              "parent" => 0,
              "settings" => settings
            }
          ]
        }
      ],
      "globalClasses" => []
    }
  end

  defp dependency_variable(document, name) do
    Enum.find(document.provenance["dependency_summary"]["variables"], &(&1["name"] == name))
  end

  defp to_ir!(settings, opts \\ []) do
    opts =
      Keyword.merge(
        [component_id: "component-a", token_set: token_set()],
        opts
      )

    assert {:ok, document} = Bricks.to_ir(synthetic_source(settings), opts)
    document
  end

  test "without structural authority --grid-1 remains a source variable dependency" do
    document = to_ir!(%{"_gridTemplateColumns" => "var(--grid-1)"})
    variable = dependency_variable(document, "--grid-1")

    assert variable["status"] == "source_variable"
    assert variable["resolution_reason"] == "mapping_unproven"
  end

  test "standalone variables/2 does not claim resolved_structural without property context" do
    [variable] =
      DependencyExtractor.variables(
        ["var(--grid-1)"],
        authority_index: %VariableAuthority{},
        structural_authority_index: structural_index()
      )

    assert variable.status == :source_variable
    assert variable.resolution_reason == "mapping_unproven"
    refute Map.has_key?(variable, :structural_authority_id)
  end

  test "valid grid-template-columns occurrence resolves structurally in extract" do
    document =
      to_ir!(%{"_gridTemplateColumns" => "var(--grid-1)"},
        structural_variable_authority: structural_index()
      )

    variable = dependency_variable(document, "--grid-1")

    assert variable["status"] == "resolved_structural"
    assert variable["structural_authority_id"] == "automatic-css-4.0.1:structural-grid:grid-1"
    assert variable["structural_resolved_value"] == "repeat(1, minmax(0, 1fr))"

    [occurrence] = variable["occurrences"]
    assert occurrence["property"] == "grid-template-columns"
    assert occurrence["resolution_status"] == "resolved_structural"
  end

  test "valid grid-template-rows occurrence resolves structurally in extract" do
    document =
      to_ir!(%{"_gridTemplateRows" => "var(--grid-1)"},
        structural_variable_authority: structural_index()
      )

    variable = dependency_variable(document, "--grid-1")
    assert variable["status"] == "resolved_structural"

    [occurrence] = variable["occurrences"]
    assert occurrence["property"] == "grid-template-rows"
    assert occurrence["resolution_status"] == "resolved_structural"
  end

  test "unsafe structural candidate does not resolve structurally in extract" do
    assert {:ok, unsafe_index} =
             StructuralVariableAuthority.build([
               %{
                 "variable" => "--grid-1",
                 "resolved_value" => "url(javascript:evil)",
                 "authority_id" => "unsafe-grid-1",
                 "source_system" => "automatic_css",
                 "source_version" => "4.0.1",
                 "authority_type" => "PROJECT_SOURCE_ENVIRONMENT_GENERATED_CSS"
               }
             ])

    document =
      to_ir!(%{"_gridTemplateColumns" => "var(--grid-1)"},
        structural_variable_authority: unsafe_index
      )

    variable = dependency_variable(document, "--grid-1")
    assert variable["status"] == "source_variable"
    assert variable["resolution_reason"] == "structural_value_invalid"
    assert hd(variable["occurrences"])["resolution_status"] == "structural_value_invalid"
  end

  test "valid structural value on width remains non-structural in extract" do
    document =
      to_ir!(%{"_width" => "var(--grid-1)"}, structural_variable_authority: structural_index())

    variable = dependency_variable(document, "--grid-1")
    assert variable["status"] == "source_variable"
    assert variable["resolution_reason"] == "structural_value_invalid"
    assert hd(variable["occurrences"])["resolution_status"] == "structural_value_invalid"
  end

  test "token ambiguity prevents structural resolution in dependencies" do
    authority = %{
      "variable" => "--grid-1",
      "kind" => "source_reference",
      "authority_id" => "synthetic:grid-1:a",
      "source_key" => "grid-1",
      "source_version" => "4.0.1"
    }

    token = %Token{
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
        TokenSet.new(
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

    document =
      to_ir!(%{"_gridTemplateColumns" => "var(--grid-1)"},
        token_set:
          TokenSet.new(
            tokens: %{
              "layout.grid.alpha" => token,
              "layout.grid.zulu" => %{token | path: "layout.grid.zulu"}
            }
          ),
        structural_variable_authority: structural_index()
      )

    variable = dependency_variable(document, "--grid-1")
    assert variable["status"] == "ambiguous_token"
  end

  test "token unique resolved remains token resolution in extract" do
    authority = %{
      "variable" => "--gap",
      "kind" => "source_reference",
      "authority_id" => "synthetic:gap",
      "source_key" => "gap",
      "source_version" => "4.0.1"
    }

    token = %Token{
      path: "spacing.gap",
      category: :spacing,
      value: "16px",
      resolved_value: "16px",
      source_expression: "16px",
      resolution_status: :resolved,
      metadata: %{"variable_authorities" => [authority]}
    }

    document =
      to_ir!(%{"_gridGap" => "var(--gap)"},
        token_set: TokenSet.new(tokens: %{"spacing.gap" => token})
      )

    variable = dependency_variable(document, "--gap")
    assert variable["status"] == "resolved_token"
    assert variable["token_path"] == "spacing.gap"
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

    document =
      to_ir!(%{"_gridTemplateColumns" => "var(--grid-1)"},
        structural_variable_authority: ambiguous_index
      )

    variable = dependency_variable(document, "--grid-1")
    assert variable["status"] == "ambiguous_structural"
    assert variable["resolution_reason"] == "structural_ambiguous"
  end

  test "multiple valid structural occurrences aggregate as resolved_structural" do
    document =
      to_ir!(
        %{
          "_gridTemplateColumns" => "var(--grid-1)",
          "_gridTemplateRows" => "var(--grid-1)"
        },
        structural_variable_authority: structural_index()
      )

    variable = dependency_variable(document, "--grid-1")
    assert variable["status"] == "resolved_structural"
    assert length(variable["occurrences"]) == 2
    assert Enum.all?(variable["occurrences"], &(&1["resolution_status"] == "resolved_structural"))
  end

  test "mixed valid and invalid structural occurrences do not aggregate as fully resolved" do
    document =
      to_ir!(
        %{
          "_gridTemplateColumns" => "var(--grid-1)",
          "_width" => "var(--grid-1)"
        },
        structural_variable_authority: structural_index()
      )

    variable = dependency_variable(document, "--grid-1")
    assert variable["status"] == "source_variable"
    assert variable["resolution_reason"] == "structural_partial_application"

    statuses = Enum.map(variable["occurrences"], & &1["resolution_status"])
    assert "resolved_structural" in statuses
    assert "structural_value_invalid" in statuses
  end

  test "parsed declaration reconciles with raw layer occurrence without duplication" do
    document =
      to_ir!(%{"_gridTemplateColumns" => "var(--grid-1)"},
        structural_variable_authority: structural_index()
      )

    variable = dependency_variable(document, "--grid-1")
    assert length(variable["occurrences"]) == 1

    [occurrence] = variable["occurrences"]
    assert occurrence["property"] == "grid-template-columns"
    assert occurrence["resolution_status"] == "resolved_structural"
    assert occurrence["source_path"] == "settings._gridTemplateColumns"
  end

  test "global class grid declaration retains canonical source path under structural authority" do
    source = %{
      "source" => "bricksCopiedElements",
      "sourceUrl" => "https://example.test/export.json",
      "version" => "2.3.1",
      "content" => [%{"id" => "proxy-a", "cid" => "component-a", "name" => "section"}],
      "components" => [
        %{
          "id" => "component-a",
          "elements" => [
            %{
              "id" => "root",
              "name" => "block",
              "parent" => 0,
              "settings" => %{"_cssGlobalClasses" => ["grid-class"]}
            }
          ]
        }
      ],
      "globalClasses" => [
        %{
          "id" => "grid-class",
          "name" => "grid-class",
          "settings" => %{"_gridTemplateColumns" => "var(--grid-1)"}
        }
      ]
    }

    assert {:ok, document} =
             Bricks.to_ir(source,
               component_id: "component-a",
               token_set: token_set(),
               structural_variable_authority: structural_index()
             )

    variable = dependency_variable(document, "--grid-1")
    assert variable["status"] == "resolved_structural"

    [occurrence] = variable["occurrences"]
    assert occurrence["source_path"] == "settings.class_refs[0].settings._gridTemplateColumns"
    assert occurrence["property"] == "grid-template-columns"
    assert occurrence["resolution_status"] == "resolved_structural"
  end

  test "unrelated variables keep canonical source paths when structural authority is active" do
    document =
      to_ir!(
        %{"_width" => "var(--unknown-width)"},
        structural_variable_authority: structural_index()
      )

    variable = dependency_variable(document, "--unknown-width")

    [occurrence] = variable["occurrences"]
    assert occurrence["source_path"] == "settings._width"
  end

  test "parsed valid plus unparsed custom CSS occurrence does not aggregate as resolved" do
    document =
      to_ir!(
        %{
          "_gridTemplateColumns" => "var(--grid-1)",
          "_cssCustom" => ".x { width: var(--grid-1); }"
        },
        structural_variable_authority: structural_index()
      )

    variable = dependency_variable(document, "--grid-1")
    assert variable["status"] == "source_variable"
    assert variable["resolution_reason"] == "structural_partial_application"
    assert length(variable["occurrences"]) == 2

    statuses = Enum.map(variable["occurrences"], & &1["resolution_status"])
    assert "resolved_structural" in statuses
    assert "unverified_occurrence" in statuses

    paths = Enum.map(variable["occurrences"], & &1["source_path"]) |> Enum.sort()
    assert paths == ["settings._cssCustom", "settings._gridTemplateColumns"]

    custom_occurrence =
      Enum.find(variable["occurrences"], fn occurrence ->
        occurrence["source_path"] == "settings._cssCustom"
      end)

    assert custom_occurrence["property"] == nil
    assert custom_occurrence["resolution_status"] == "unverified_occurrence"

    assert Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.variable.unresolved" and
               diagnostic.metadata["source_variable"] == "--grid-1"
           end)
  end

  test "valid structural dependency does not emit false unresolved diagnostic" do
    document =
      to_ir!(%{"_gridTemplateColumns" => "var(--grid-1)"},
        structural_variable_authority: structural_index()
      )

    refute Enum.any?(document.diagnostics, fn diagnostic ->
             diagnostic.code == "bricks.variable.unresolved" and
               diagnostic.metadata["source_variable"] == "--grid-1"
           end)
  end
end
