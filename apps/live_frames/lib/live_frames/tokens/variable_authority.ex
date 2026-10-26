defmodule LiveFrames.Tokens.VariableAuthority do
  @moduledoc """
  Builds a deterministic inverse index of validated CSS-variable authority
  records stored on Token metadata.

  The index is source-independent. It does not infer relationships from token
  names or values and keeps authority candidates separate from token
  resolution status.
  """

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
          | {:error, :no_authority | :ambiguous_candidates | :token_missing | :token_unresolved}

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

  @doc "Returns the resolved value for one unique, present authority candidate."
  @spec resolve_terminal(t(), String.t()) :: terminal_result()
  def resolve_terminal(%__MODULE__{} = index, variable) when is_binary(variable) do
    case resolve(index, variable) do
      %{state: :no_authority} ->
        {:error, :no_authority}

      %{state: :ambiguous_candidates} ->
        {:error, :ambiguous_candidates}

      %{state: :unique_candidate, candidates: [candidate]} ->
        case Map.fetch(index.tokens_by_path, candidate.token_path) do
          {:ok, %Token{resolution_status: :resolved} = token} ->
            {:ok, candidate, token.resolved_value}

          {:ok, _token} ->
            {:error, :token_unresolved}

          :error ->
            {:error, :token_missing}
        end
    end
  end

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
