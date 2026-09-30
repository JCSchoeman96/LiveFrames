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

  @required_string_fields ~w(
    variable
    resolved_value
    authority_id
    source_system
    source_version
    authority_type
  )

  @spec build([map()]) ::
          {:ok, t()} | {:error, [LiveFrames.Styles.StructuralVariableAuthority.BuildError.t()]}
  def build(records) when is_list(records) do
    {normalized, errors} =
      records
      |> Enum.with_index()
      |> Enum.reduce({[], []}, fn {record, index}, {ok_acc, err_acc} ->
        case normalize_record(record) do
          {:ok, candidate} ->
            {[candidate | ok_acc], err_acc}

          {:error, reason} ->
            {ok_acc,
             [
               LiveFrames.Styles.StructuralVariableAuthority.BuildError.new(index, reason)
               | err_acc
             ]}
        end
      end)

    if errors != [] do
      {:error, Enum.sort_by(errors, & &1.index)}
    else
      normalized =
        normalized
        |> dedupe_records()
        |> Enum.sort_by(&record_sort_key/1)

      by_variable =
        normalized
        |> Enum.group_by(& &1.variable)
        |> Map.new(fn {variable, candidates} -> {variable, candidates} end)

      {:ok, %__MODULE__{by_variable: by_variable}}
    end
  end

  @spec resolve(t(), String.t()) :: map()
  def resolve(%__MODULE__{} = index, variable) when is_binary(variable) do
    candidates =
      index.by_variable
      |> Map.get(variable, [])
      |> Enum.sort_by(&record_sort_key/1)

    state =
      case candidates do
        [] -> :no_authority
        [_candidate] -> :unique_candidate
        _candidates -> :ambiguous_candidates
      end

    %{state: state, variable: variable, candidates: candidates}
  end

  defp normalize_record(record) when is_map(record) do
    with :ok <- validate_required_fields(record),
         :ok <- validate_string_fields(record),
         :ok <- validate_metadata(record) do
      {:ok,
       %{
         variable: Map.fetch!(record, "variable"),
         resolved_value: Map.fetch!(record, "resolved_value"),
         authority_id: Map.fetch!(record, "authority_id"),
         source_system: Map.fetch!(record, "source_system"),
         source_version: Map.fetch!(record, "source_version"),
         authority_type: Map.fetch!(record, "authority_type"),
         metadata: Map.get(record, "metadata", %{})
       }}
    end
  end

  defp normalize_record(_record), do: {:error, :invalid_record_shape}

  defp validate_required_fields(record) do
    if Enum.all?(@required_string_fields, &Map.has_key?(record, &1)) do
      :ok
    else
      {:error, :missing_required_field}
    end
  end

  defp validate_string_fields(record) do
    if Enum.all?(@required_string_fields, fn field ->
         value = Map.get(record, field)
         is_binary(value) and value != ""
       end) do
      :ok
    else
      {:error, :invalid_field_type}
    end
  end

  defp validate_metadata(record) do
    case Map.get(record, "metadata", %{}) do
      metadata when is_map(metadata) -> :ok
      _other -> {:error, :invalid_metadata}
    end
  end

  defp dedupe_records(records) do
    Enum.uniq_by(records, &record_identity/1)
  end

  defp record_identity(record) do
    {record.variable, record.resolved_value, record.authority_id, record.source_system,
     record.source_version, record.authority_type, record.metadata}
  end

  defp record_sort_key(record) do
    {record.variable, record.authority_id, record.resolved_value, record.source_system,
     record.source_version, record.authority_type, record.metadata}
  end
end

defmodule LiveFrames.Styles.StructuralVariableAuthority.BuildError do
  @moduledoc false

  @type t :: %__MODULE__{
          index: non_neg_integer(),
          reason: atom()
        }

  defstruct [:index, :reason]

  @spec new(non_neg_integer(), atom()) :: t()
  def new(index, reason) when is_integer(index) and index >= 0 and is_atom(reason) do
    %__MODULE__{index: index, reason: reason}
  end
end
