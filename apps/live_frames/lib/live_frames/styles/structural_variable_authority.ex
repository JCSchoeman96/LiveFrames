defmodule LiveFrames.Styles.StructuralVariableAuthority do
  @moduledoc """
  Builds a deterministic inverse index of structural CSS-variable authority
  records.

  Structural authority is source-independent at this layer. It does not infer
  relationships from token names and keeps candidates separate from TokenSet
  variable authority.
  """

  @type candidate :: %{
          variable: String.t(),
          resolved_value: String.t(),
          authority_id: String.t(),
          source_system: String.t(),
          source_version: String.t(),
          authority_type: String.t(),
          metadata: map()
        }

  @type t :: %__MODULE__{
          by_variable: %{optional(String.t()) => [candidate()]}
        }

  defstruct by_variable: %{}

  @required_fields ~w(
    variable
    resolved_value
    authority_id
    source_system
    source_version
    authority_type
  )

  @spec build([map()]) :: {:ok, t()}
  def build(records) when is_list(records) do
    normalized =
      records
      |> Enum.map(&normalize_record/1)
      |> Enum.reject(&is_nil/1)
      |> dedupe_records()
      |> Enum.sort_by(&record_sort_key/1)

    by_variable =
      normalized
      |> Enum.group_by(& &1.variable)
      |> Map.new(fn {variable, candidates} -> {variable, candidates} end)

    {:ok, %__MODULE__{by_variable: by_variable}}
  end

  @spec resolve(t(), String.t()) :: map()
  def resolve(%__MODULE__{} = index, variable) when is_binary(variable) do
    candidates =
      index.by_variable
      |> Map.get(variable, [])
      |> Enum.sort_by(&record_sort_key/1)

    distinct_values =
      candidates
      |> Enum.map(& &1.resolved_value)
      |> Enum.uniq()

    state =
      case {candidates, distinct_values} do
        {[], _} -> :no_authority
        {[_candidate], [_value]} -> :unique_candidate
        {_candidates, [_value]} -> :unique_candidate
        {_candidates, _values} -> :ambiguous_candidates
      end

    %{state: state, variable: variable, candidates: candidates}
  end

  defp normalize_record(record) when is_map(record) do
    with :ok <- validate_required(record) do
      %{
        variable: Map.fetch!(record, "variable"),
        resolved_value: Map.fetch!(record, "resolved_value"),
        authority_id: Map.fetch!(record, "authority_id"),
        source_system: Map.fetch!(record, "source_system"),
        source_version: Map.fetch!(record, "source_version"),
        authority_type: Map.fetch!(record, "authority_type"),
        metadata: Map.get(record, "metadata", %{})
      }
    else
      :error -> nil
    end
  end

  defp normalize_record(_record), do: nil

  defp validate_required(record) do
    if Enum.all?(@required_fields, &Map.has_key?(record, &1)) do
      :ok
    else
      :error
    end
  end

  defp dedupe_records(records) do
    records
    |> Enum.uniq_by(fn record ->
      {record.variable, record.authority_id, record.resolved_value}
    end)
  end

  defp record_sort_key(record) do
    {record.variable, record.authority_id, record.resolved_value, record.source_system,
     record.source_version}
  end
end
