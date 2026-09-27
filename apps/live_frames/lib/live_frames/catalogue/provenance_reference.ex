defmodule LiveFrames.Catalogue.ProvenanceReference do
  @moduledoc false

  alias LiveFrames.Catalogue.Manifest

  @authority "docs/04_SOURCE_AND_PROVENANCE.md"
  @provenance_keys ["references"]
  @reference_keys ["source_group", "authority", "evidence_refs"]
  @resolved_record_keys [
    "source_group",
    "authority",
    "evidence_refs",
    "redistribution_status",
    "publication_state",
    "clearance_evidence_refs"
  ]

  @spec validate(term(), term()) :: :ok | {:error, [Manifest.diagnostic()]}
  def validate(%Manifest{provenance: provenance}, resolved_records) do
    with {:ok, references} <- validate_provenance(provenance),
         :ok <- validate_unique_references(references),
         {:ok, resolved_records} <- validate_resolved_records(resolved_records),
         :ok <- resolve_references(references, resolved_records) do
      :ok
    end
  end

  def validate(_manifest, _resolved_records) do
    error(
      "catalogue.provenance_reference.manifest_invalid",
      "$",
      "Expected a decoded Catalogue manifest."
    )
  end

  defp validate_provenance(provenance) when is_map(provenance) do
    if exact_keys?(provenance, @provenance_keys) do
      provenance
      |> Map.fetch!("references")
      |> validate_manifest_references()
    else
      provenance_invalid()
    end
  end

  defp validate_provenance(_provenance), do: provenance_invalid()

  defp validate_manifest_references(references) do
    if non_empty_proper_list?(references) do
      case validate_manifest_references(references, 0) do
        :ok -> {:ok, references}
        error -> error
      end
    else
      error(
        "catalogue.provenance_reference.references_invalid",
        "provenance.references",
        "Expected a non-empty proper list of provenance references."
      )
    end
  end

  defp validate_manifest_references([], _index), do: :ok

  defp validate_manifest_references([reference | rest], index) do
    path = "provenance.references[#{index}]"

    with :ok <- validate_manifest_reference(reference, path),
         :ok <- validate_manifest_references(rest, index + 1) do
      :ok
    end
  end

  defp validate_manifest_reference(reference, path) when is_map(reference) do
    if exact_keys?(reference, @reference_keys) do
      with :ok <- validate_non_empty_string(reference["source_group"], "source_group", path),
           :ok <- validate_authority(reference["authority"], path),
           :ok <-
             validate_manifest_evidence_refs(
               reference["evidence_refs"],
               path <> ".evidence_refs"
             ) do
        :ok
      end
    else
      error(
        "catalogue.provenance_reference.reference_invalid",
        path,
        "Expected a reference object with exactly source_group, authority, and evidence_refs."
      )
    end
  end

  defp validate_manifest_reference(_reference, path) do
    error(
      "catalogue.provenance_reference.reference_invalid",
      path,
      "Expected a provenance reference object."
    )
  end

  defp validate_manifest_evidence_refs(evidence_refs, path) do
    if non_empty_proper_list?(evidence_refs) do
      validate_unique_strings(
        evidence_refs,
        path,
        "catalogue.provenance_reference.evidence_ref_invalid",
        "catalogue.provenance_reference.evidence_ref_duplicate"
      )
    else
      error(
        "catalogue.provenance_reference.evidence_refs_invalid",
        path,
        "Expected a non-empty proper list of evidence references."
      )
    end
  end

  defp validate_unique_references(references) do
    identities = Enum.map(references, &{&1["authority"], &1["source_group"]})

    if Enum.uniq(identities) == identities do
      :ok
    else
      error(
        "catalogue.provenance_reference.reference_duplicate",
        "provenance.references",
        "Manifest provenance reference identities must be unique."
      )
    end
  end

  defp validate_resolved_records(records) when is_list(records) do
    if proper_list?(records) do
      case validate_resolved_records(records, 0) do
        :ok -> {:ok, records}
        error -> error
      end
    else
      resolved_records_invalid()
    end
  end

  defp validate_resolved_records(_records), do: resolved_records_invalid()

  defp validate_resolved_records([], _index), do: :ok

  defp validate_resolved_records([record | rest], index) do
    path = "resolved_records[#{index}]"

    with :ok <- validate_resolved_record(record, path),
         :ok <- validate_resolved_records(rest, index + 1) do
      :ok
    end
  end

  defp validate_resolved_record(record, path) when is_map(record) do
    if exact_keys?(record, @resolved_record_keys) do
      with :ok <- validate_non_empty_string(record["source_group"], "source_group", path),
           :ok <- validate_authority(record["authority"], path),
           :ok <- validate_resolved_evidence_refs(record["evidence_refs"], path),
           :ok <-
             validate_status_string(
               record["redistribution_status"],
               "redistribution_status",
               path
             ),
           :ok <- validate_status_string(record["publication_state"], "publication_state", path),
           :ok <- validate_clearance_evidence_refs(record["clearance_evidence_refs"], path) do
        :ok
      end
    else
      resolved_record_invalid(path)
    end
  end

  defp validate_resolved_record(_record, path), do: resolved_record_invalid(path)

  defp validate_resolved_evidence_refs(evidence_refs, path) do
    evidence_path = path <> ".evidence_refs"

    if non_empty_proper_list?(evidence_refs) do
      validate_unique_strings(
        evidence_refs,
        evidence_path,
        "catalogue.provenance_reference.evidence_ref_invalid",
        "catalogue.provenance_reference.evidence_ref_duplicate"
      )
    else
      error(
        "catalogue.provenance_reference.evidence_refs_invalid",
        evidence_path,
        "Expected a non-empty proper list of evidence references."
      )
    end
  end

  defp validate_clearance_evidence_refs(evidence_refs, path) do
    evidence_path = path <> ".clearance_evidence_refs"

    if proper_list?(evidence_refs) do
      validate_unique_strings(
        evidence_refs,
        evidence_path,
        "catalogue.provenance_reference.clearance_evidence_ref_invalid",
        "catalogue.provenance_reference.clearance_evidence_ref_duplicate"
      )
    else
      error(
        "catalogue.provenance_reference.clearance_evidence_refs_invalid",
        evidence_path,
        "Expected a proper list of clearance evidence references."
      )
    end
  end

  defp validate_unique_strings(values, path, invalid_code, duplicate_code) do
    case first_invalid_string_index(values) do
      nil ->
        if Enum.uniq(values) == values do
          :ok
        else
          error(duplicate_code, path, "Evidence references must be unique.")
        end

      index ->
        error(
          invalid_code,
          "#{path}[#{index}]",
          "Expected a non-empty valid UTF-8 string."
        )
    end
  end

  defp first_invalid_string_index(values) do
    values
    |> Enum.with_index()
    |> Enum.find_value(fn {value, index} ->
      if non_empty_utf8_string?(value), do: nil, else: index
    end)
  end

  defp validate_non_empty_string(value, field, path) do
    if non_empty_utf8_string?(value) do
      :ok
    else
      error(
        "catalogue.provenance_reference.source_group_invalid",
        "#{path}.#{field}",
        "Expected a non-empty valid UTF-8 string."
      )
    end
  end

  defp validate_authority(authority, path) do
    if is_binary(authority) and String.valid?(authority) and authority == @authority do
      :ok
    else
      error(
        "catalogue.provenance_reference.authority_invalid",
        "#{path}.authority",
        "Expected the supported provenance authority identifier."
      )
    end
  end

  defp validate_status_string(value, field, path) do
    if is_binary(value) and String.valid?(value) do
      :ok
    else
      error(
        "catalogue.provenance_reference.#{field}_invalid",
        "#{path}.#{field}",
        "Expected a valid UTF-8 string."
      )
    end
  end

  defp resolve_references(references, resolved_records) do
    resolve_references(references, resolved_records, 0)
  end

  defp resolve_references([], _resolved_records, _index), do: :ok

  defp resolve_references([reference | rest], resolved_records, index) do
    matches =
      Enum.filter(resolved_records, fn record ->
        record["authority"] == reference["authority"] and
          record["source_group"] == reference["source_group"]
      end)

    path = "provenance.references[#{index}]"

    case matches do
      [] ->
        error(
          "catalogue.provenance_reference.resolution_missing",
          path,
          "No supplied provenance record matches this reference."
        )

      [record] ->
        with :ok <- validate_resolved_manifest_evidence(reference, record, path),
             :ok <- resolve_references(rest, resolved_records, index + 1) do
          :ok
        end

      _matches ->
        error(
          "catalogue.provenance_reference.resolution_ambiguous",
          path,
          "Multiple supplied provenance records match this reference."
        )
    end
  end

  defp validate_resolved_manifest_evidence(reference, record, path) do
    evidence_refs = reference["evidence_refs"]
    resolved_evidence_refs = record["evidence_refs"]

    case first_unresolved_evidence_index(evidence_refs, resolved_evidence_refs) do
      nil ->
        :ok

      index ->
        error(
          "catalogue.provenance_reference.evidence_ref_dangling",
          "#{path}.evidence_refs[#{index}]",
          "Manifest evidence reference is absent from the matching provenance record."
        )
    end
  end

  defp first_unresolved_evidence_index(evidence_refs, resolved_evidence_refs) do
    evidence_refs
    |> Enum.with_index()
    |> Enum.find_value(fn {evidence_ref, index} ->
      if evidence_ref in resolved_evidence_refs, do: nil, else: index
    end)
  end

  defp exact_keys?(map, keys) do
    map_size(map) == length(keys) and Enum.all?(keys, &Map.has_key?(map, &1))
  end

  defp non_empty_utf8_string?(value) do
    is_binary(value) and byte_size(value) > 0 and String.valid?(value)
  end

  defp non_empty_proper_list?([_head | _tail] = list), do: proper_list?(list)
  defp non_empty_proper_list?(_value), do: false

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_value), do: false

  defp provenance_invalid do
    error(
      "catalogue.provenance_reference.provenance_invalid",
      "provenance",
      "Expected a provenance object containing exactly the references key."
    )
  end

  defp resolved_records_invalid do
    error(
      "catalogue.provenance_reference.resolved_records_invalid",
      "resolved_records",
      "Expected a proper list of supplied provenance records."
    )
  end

  defp resolved_record_invalid(path) do
    error(
      "catalogue.provenance_reference.resolved_record_invalid",
      path,
      "Expected a string-keyed provenance record with exactly the required fields."
    )
  end

  defp error(code, path, message), do: {:error, [%{code: code, path: path, message: message}]}
end
