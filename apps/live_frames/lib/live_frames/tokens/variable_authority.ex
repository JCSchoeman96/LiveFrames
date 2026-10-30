defmodule LiveFrames.Tokens.VariableAuthority do
  @moduledoc """
  Builds a deterministic inverse index of validated CSS-variable authority
  records stored on Token metadata.

  The index is source-independent. It does not infer relationships from token
  names or values and keeps authority candidates separate from token
  resolution status.
  """

  alias LiveFrames.Tokens.CSSValue
  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet

  @type candidate :: %{
          token_path: String.t(),
          authorities: [map()],
          token_present?: boolean(),
          resolution_status: :resolved | :unresolved | nil
        }

  @type terminal_result ::
          {:ok, candidate(), term()}
          | {:error,
             :no_authority
             | :ambiguous_candidates
             | :token_missing
             | :token_unresolved
             | :token_value_unavailable}

  @type direct_owner_result ::
          {:ok, candidate()} | {:error, :no_authority | :ambiguous_candidates}

  @type t :: %__MODULE__{
          by_variable: %{optional(String.t()) => %{optional(String.t()) => [map()]}},
          tokens_by_path: %{optional(String.t()) => Token.t()}
        }

  defstruct by_variable: %{}, tokens_by_path: %{}

  @spec build(TokenSet.t()) :: {:ok, t()} | {:error, [LiveFrames.Tokens.Diagnostic.t()]}
  def build(%TokenSet{} = token_set) do
    with :ok <- LiveFrames.Tokens.validate(token_set) do
      sorted_tokens = Enum.sort_by(token_set.tokens, &elem(&1, 0))
      tokens_by_path = Map.new(sorted_tokens)

      by_variable =
        sorted_tokens
        |> Enum.flat_map(fn {path, token} ->
          token.metadata
          |> Map.get("variable_authorities", [])
          |> Enum.map(&{&1["variable"], path, &1})
        end)
        |> Enum.sort_by(fn {variable, path, authority} ->
          {variable, path, authority_sort_key(authority)}
        end)
        |> Enum.group_by(&elem(&1, 0), fn {_variable, path, authority} ->
          {path, authority}
        end)
        |> Map.new(fn {variable, path_authorities} ->
          paths =
            path_authorities
            |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
            |> Map.new(fn {path, authorities} -> {path, Enum.uniq(authorities)} end)

          {variable, paths}
        end)

      {:ok, %__MODULE__{by_variable: by_variable, tokens_by_path: tokens_by_path}}
    end
  end

  @spec resolve(t(), String.t()) :: map()
  def resolve(%__MODULE__{} = index, variable) when is_binary(variable) do
    candidates =
      index.by_variable
      |> Map.get(variable, %{})
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {path, authorities} -> candidate(index, path, authorities) end)

    state =
      case candidates do
        [] -> :no_authority
        [_candidate] -> :unique_candidate
        _candidates -> :ambiguous_candidates
      end

    %{state: state, variable: variable, candidates: candidates}
  end

  @doc """
  Selects the unique token path backed by direct-owner authority records.

  Source references remain generic candidates and do not count as owners.
  """
  @spec resolve_direct_owner(t(), String.t()) :: direct_owner_result()
  def resolve_direct_owner(%__MODULE__{} = index, variable) when is_binary(variable) do
    owner_paths =
      index.by_variable
      |> Map.get(variable, %{})
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.flat_map(fn {path, authorities} ->
        if Enum.any?(authorities, &direct_owner_authority?/1),
          do: [{path, authorities}],
          else: []
      end)

    case owner_paths do
      [] ->
        {:error, :no_authority}

      [{path, authorities}] ->
        {:ok, candidate(index, path, authorities)}

      _multiple_paths ->
        {:error, :ambiguous_candidates}
    end
  end

  @doc """
  Returns a CSS terminal candidate for one unique, present, resolved authority
  candidate.

  Binary resolved values are returned directly. Resolved structured-derived
  Tokens may use `CSSValue.candidate/1`. The returned value remains a candidate
  and must be validated by the consumer.
  """
  @spec resolve_terminal(t(), String.t()) :: terminal_result()
  def resolve_terminal(%__MODULE__{} = index, variable) when is_binary(variable) do
    case resolve(index, variable) do
      %{state: :no_authority} ->
        {:error, :no_authority}

      %{state: :ambiguous_candidates} ->
        {:error, :ambiguous_candidates}

      %{state: :unique_candidate, candidates: [candidate]} ->
        terminal_candidate(index, candidate)
    end
  end

  @doc """
  Selects a direct owner and returns its available bounded CSS terminal value.
  """
  @spec resolve_direct_owner_terminal(t(), String.t()) :: terminal_result()
  def resolve_direct_owner_terminal(%__MODULE__{} = index, variable) when is_binary(variable) do
    case resolve_direct_owner(index, variable) do
      {:ok, candidate} -> terminal_candidate(index, candidate)
      {:error, reason} -> {:error, reason}
    end
  end

  defp terminal_candidate(index, candidate) do
    case Map.fetch(index.tokens_by_path, candidate.token_path) do
      {:ok, %Token{resolution_status: :resolved} = token} ->
        with {:ok, terminal} <- terminal_value(token) do
          {:ok, candidate, terminal}
        end

      {:ok, _token} ->
        {:error, :token_unresolved}

      :error ->
        {:error, :token_missing}
    end
  end

  defp direct_owner_authority?(%{"kind" => kind}),
    do: kind in ["source_output_alias", "explicit_project_contract"]

  defp direct_owner_authority?(_authority), do: false

  defp terminal_value(%Token{resolved_value: resolved_value}) when is_binary(resolved_value),
    do: {:ok, resolved_value}

  defp terminal_value(%Token{resolved_value: %{"type" => "derived"}} = token) do
    case CSSValue.candidate(token) do
      {:ok, candidate} when is_binary(candidate) -> {:ok, candidate}
      _ -> {:error, :token_value_unavailable}
    end
  end

  defp terminal_value(_token), do: {:error, :token_value_unavailable}

  defp candidate(index, path, authorities) do
    token = Map.get(index.tokens_by_path, path)

    %{
      token_path: path,
      authorities: Enum.sort_by(authorities, &authority_sort_key/1),
      token_present?: not is_nil(token),
      resolution_status: if(token, do: token.resolution_status, else: nil)
    }
  end

  defp authority_sort_key(authority) do
    {Map.get(authority, "kind", ""), Map.get(authority, "authority_id", ""),
     Map.get(authority, "source_key", "") || ""}
  end
end
