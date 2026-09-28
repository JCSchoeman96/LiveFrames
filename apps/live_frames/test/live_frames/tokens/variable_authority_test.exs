defmodule LiveFrames.Tokens.VariableAuthorityTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet
  alias LiveFrames.Tokens.VariableAuthority

  defp authority(variable, kind, authority_id, source_key) do
    %{
      "variable" => variable,
      "kind" => kind,
      "authority_id" => authority_id,
      "source_key" => source_key,
      "source_version" => "4.0.1"
    }
  end

  defp token(path, authorities, status \\ :resolved) do
    %Token{
      path: path,
      category: :spacing,
      value: if(status == :resolved, do: "16px", else: nil),
      resolved_value: if(status == :resolved, do: "16px", else: nil),
      source_expression: if(status == :resolved, do: "16px", else: "var(--gap)"),
      resolution_status: status,
      metadata: %{"variable_authorities" => authorities}
    }
  end

  defp token_set(tokens) do
    TokenSet.new(tokens: Map.new(tokens, &{&1.path, &1}))
  end

  defp build!(token_set) do
    assert {:ok, index} = VariableAuthority.build(token_set)
    index
  end

  test "records with one owning path produce one unique candidate and retain all authorities" do
    output_alias = authority("--gap", "source_output_alias", "acss-4.0.1:output:gap", "gap")

    source_reference =
      authority("--gap", "source_reference", "acss-4.0.1:reference:gap", "gap-ref")

    index = build!(token_set([token("spacing.content_gap", [output_alias, source_reference])]))

    assert %{
             state: :unique_candidate,
             variable: "--gap",
             candidates: [
               %{
                 token_path: "spacing.content_gap",
                 authorities: [^output_alias, ^source_reference],
                 token_present?: true,
                 resolution_status: :resolved
               }
             ]
           } = VariableAuthority.resolve(index, "--gap")
  end

  test "distinct owning paths remain ambiguous and are returned in path order" do
    first = authority("--gap", "source_reference", "acss-4.0.1:reference:first", "first")
    second = authority("--gap", "source_reference", "acss-4.0.1:reference:second", "second")

    index =
      build!(
        token_set([
          token("spacing.zulu", [second]),
          token("spacing.alpha", [first])
        ])
      )

    assert %{
             state: :ambiguous_candidates,
             variable: "--gap",
             candidates: [
               %{token_path: "spacing.alpha", authorities: [^first]},
               %{token_path: "spacing.zulu", authorities: [^second]}
             ]
           } = VariableAuthority.resolve(index, "--gap")
  end

  test "unproven variables return no authority" do
    index = build!(token_set([token("spacing.content_gap", [])]))

    assert VariableAuthority.resolve(index, "--unknown") == %{
             state: :no_authority,
             variable: "--unknown",
             candidates: []
           }
  end

  test "unique candidates expose token presence separately from unresolved status" do
    unresolved = authority("--gap", "source_reference", "acss-4.0.1:reference:gap", "gap")
    index = build!(token_set([token("spacing.content_gap", [unresolved], :unresolved)]))

    assert %{
             state: :unique_candidate,
             candidates: [
               %{
                 token_path: "spacing.content_gap",
                 token_present?: true,
                 resolution_status: :unresolved
               }
             ]
           } = VariableAuthority.resolve(index, "--gap")
  end

  test "does not infer authority from path or variable-name similarity" do
    index = build!(token_set([token("spacing.content_gap", [])]))

    assert VariableAuthority.resolve(index, "--content-gap") == %{
             state: :no_authority,
             variable: "--content-gap",
             candidates: []
           }
  end

  test "lookup ordering is independent of token and authority input order" do
    first = authority("--gap", "source_reference", "authority-a", "source-a")
    second = authority("--gap", "source_output_alias", "authority-b", "source-b")

    first_index =
      build!(
        token_set([
          token("spacing.zulu", [first]),
          token("spacing.alpha", [second])
        ])
      )

    second_index =
      build!(
        token_set([
          token("spacing.alpha", [second]),
          token("spacing.zulu", [first])
        ])
      )

    assert VariableAuthority.resolve(first_index, "--gap") ==
             VariableAuthority.resolve(second_index, "--gap")
  end
end
