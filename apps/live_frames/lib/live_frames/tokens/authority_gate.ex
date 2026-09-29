defmodule LiveFrames.Tokens.AuthorityGate do
  @moduledoc """
  Decides whether compiler consumers may trust a TokenSet variable authority
  index.

  VariableAuthority.build/1 performs structural validation and constructs
  the deterministic evidence index. It does not apply the processing
  diagnostic trust policy. authorize/1 builds that index once, then rejects
  it when a valid TokenSet processing diagnostic has severity :error or
  :fatal. Informational and warning diagnostics remain compatible with
  authority consumption.

  The lifecycle is TOKEN_SET_RECEIVED, STRUCTURAL_VALIDATION,
  STRUCTURALLY_VALID, then DIAGNOSTIC_TRUST_GATE. Structural failure ends at
  REJECTED_STRUCTURAL. A blocking processing diagnostic ends at
  REJECTED_PROCESSING_DIAGNOSTICS. Otherwise the result is AUTHORITY_TRUSTED.
  """

  alias LiveFrames.Tokens.Diagnostic
  alias LiveFrames.Tokens.TokenSet
  alias LiveFrames.Tokens.VariableAuthority

  @blocking_severities [:error, :fatal]

  @spec authorize(TokenSet.t()) ::
          {:ok, VariableAuthority.t()} | {:error, [Diagnostic.t()]}
  def authorize(%TokenSet{} = token_set) do
    case VariableAuthority.build(token_set) do
      {:ok, index} ->
        authorize_valid_index(index, token_set.diagnostics)

      {:error, structural_diagnostics} ->
        reject_structural_failure(structural_diagnostics, token_set.diagnostics)
    end
  end

  defp authorize_valid_index(index, diagnostics) do
    blocking_diagnostics =
      Enum.filter(diagnostics, &(&1.severity in @blocking_severities))

    if blocking_diagnostics == [],
      do: {:ok, index},
      else: {:error, diagnostics}
  end

  defp reject_structural_failure(structural_diagnostics, diagnostics) do
    diagnostic_context = valid_diagnostic_context(diagnostics)

    if Enum.any?(diagnostic_context, &(&1.severity in @blocking_severities)) do
      {:error, structural_diagnostics ++ diagnostic_context}
    else
      {:error, structural_diagnostics}
    end
  end

  defp valid_diagnostic_context(diagnostics) when is_list(diagnostics) do
    Enum.filter(diagnostics, &valid_diagnostic?/1)
  end

  defp valid_diagnostic_context(_diagnostics), do: []

  defp valid_diagnostic?(%Diagnostic{} = diagnostic) do
    non_empty_string?(diagnostic.code) and
      diagnostic.severity in Diagnostic.severities() and
      diagnostic.category in Diagnostic.categories() and
      non_empty_string?(diagnostic.message) and
      optional_string?(diagnostic.path) and
      optional_string?(diagnostic.source_key) and
      json_object?(diagnostic.metadata)
  end

  defp valid_diagnostic?(_diagnostic), do: false

  defp non_empty_string?(value), do: is_binary(value) and value != ""

  defp optional_string?(nil), do: true
  defp optional_string?(value), do: is_binary(value)

  defp json_object?(value) when is_map(value) and not is_struct(value) do
    keys = Enum.map(Map.keys(value), &json_key/1)

    Enum.all?(keys, &is_binary/1) and length(keys) == length(Enum.uniq(keys)) and
      Enum.all?(Map.values(value), &json_value?/1)
  end

  defp json_object?(_value), do: false

  defp json_key(key) when is_binary(key), do: key

  defp json_key(key) when is_atom(key) and key not in [nil, true, false],
    do: Atom.to_string(key)

  defp json_key(_key), do: nil

  defp json_value?(nil), do: true
  defp json_value?(value) when is_binary(value), do: true
  defp json_value?(value) when is_boolean(value), do: true
  defp json_value?(value) when is_integer(value) or is_float(value), do: true
  defp json_value?(value) when is_list(value), do: Enum.all?(value, &json_value?/1)
  defp json_value?(value) when is_map(value) and not is_struct(value), do: json_object?(value)
  defp json_value?(_value), do: false
end
