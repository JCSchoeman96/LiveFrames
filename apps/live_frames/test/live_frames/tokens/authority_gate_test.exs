defmodule LiveFrames.Tokens.AuthorityGateTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Tokens.AuthorityGate
  alias LiveFrames.Tokens.Diagnostic
  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet
  alias LiveFrames.Tokens.VariableAuthority

  defp diagnostic(severity) do
    Diagnostic.new(
      code: "test.processing.#{severity}",
      severity: severity,
      category: :source,
      message: "Synthetic processing diagnostic",
      path: "spacing.gap",
      source_key: "gap",
      metadata: %{"source" => "fixture"}
    )
  end

  defp token(path, variable) do
    authority = %{
      "variable" => variable,
      "kind" => "source_reference",
      "authority_id" => "fixture:#{variable}",
      "source_key" => String.trim_leading(variable, "--"),
      "source_version" => "1.0"
    }

    %Token{
      path: path,
      category: :spacing,
      value: "16px",
      resolved_value: "16px",
      source_expression: "16px",
      resolution_status: :resolved,
      metadata: %{"variable_authorities" => [authority]}
    }
  end

  defp token_set(tokens, diagnostics \\ []) do
    TokenSet.new(
      tokens: Map.new(tokens, &{&1.path, &1}),
      diagnostics: diagnostics
    )
  end

  test "authorizes a structurally valid TokenSet with no processing diagnostics" do
    assert {:ok, %VariableAuthority{}} = AuthorityGate.authorize(TokenSet.new())
  end

  test "authorizes informational and warning TokenSet diagnostics" do
    for severity <- [:info, :warning] do
      assert {:ok, %VariableAuthority{}} =
               AuthorityGate.authorize(TokenSet.new(diagnostics: [diagnostic(severity)]))
    end
  end

  test "rejects error and fatal TokenSet diagnostics" do
    for severity <- [:error, :fatal] do
      diagnostic = diagnostic(severity)

      assert {:error, [^diagnostic]} =
               AuthorityGate.authorize(TokenSet.new(diagnostics: [diagnostic]))
    end
  end

  test "returns the full valid processing diagnostic context in source order" do
    diagnostics = Enum.map([:info, :warning, :error], &diagnostic/1)

    assert {:error, ^diagnostics} =
             AuthorityGate.authorize(TokenSet.new(diagnostics: diagnostics))
  end

  test "returns the existing structural validation diagnostics" do
    token_set = %TokenSet{tokens: :invalid}
    assert {:error, structural_diagnostics} = VariableAuthority.build(token_set)

    assert {:error, ^structural_diagnostics} = AuthorityGate.authorize(token_set)
  end

  test "appends valid blocking context to structural diagnostics deterministically" do
    info = diagnostic(:info)
    warning = diagnostic(:warning)
    error = diagnostic(:error)
    malformed_struct = %Diagnostic{severity: :fatal}

    malformed_metadata =
      diagnostic(:fatal)
      |> Map.update!(:metadata, &Map.put(&1, "invalid", :not_json))

    token_set = %TokenSet{
      tokens: :invalid,
      diagnostics: [info, warning, error, malformed_struct, malformed_metadata, :malformed]
    }

    assert {:error, structural_diagnostics} = VariableAuthority.build(token_set)
    assert {:error, first} = AuthorityGate.authorize(token_set)
    assert {:error, ^first} = AuthorityGate.authorize(token_set)
    assert Enum.take(first, length(structural_diagnostics)) == structural_diagnostics
    assert Enum.drop(first, length(structural_diagnostics)) == [info, warning, error]
  end

  test "returns an authority index with the same candidate graph as VariableAuthority.build" do
    token_set =
      token_set([
        token("spacing.alpha", "--gap"),
        token("spacing.zulu", "--gap")
      ])

    assert {:ok, expected_index} = VariableAuthority.build(token_set)
    assert {:ok, actual_index} = AuthorityGate.authorize(token_set)

    assert VariableAuthority.resolve(actual_index, "--gap") ==
             VariableAuthority.resolve(expected_index, "--gap")
  end
end
