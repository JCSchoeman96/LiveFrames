defmodule LiveFrames.Catalogue.Versioning do
  @moduledoc false

  alias LiveFrames.Catalogue.Manifest

  @stable_core ~r/\A(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\z/

  @spec validate_initial_release(term(), term()) ::
          {:ok, [String.t()]} | {:error, [Manifest.diagnostic()]}
  def validate_initial_release(%Manifest{release: release}, version_review) do
    with {:ok, version} <- release_version(release),
         :ok <- validate_version(version),
         {:ok, evidence_refs} <- version_review_evidence(version_review) do
      {:ok, evidence_refs}
    end
  end

  def validate_initial_release(_manifest, _version_review) do
    error(
      "catalogue.versioning.manifest_invalid",
      "$",
      "Expected a decoded Catalogue manifest."
    )
  end

  defp release_version(%{"version" => version} = release) when map_size(release) == 1 do
    if is_binary(version) and String.valid?(version) do
      {:ok, version}
    else
      error(
        "catalogue.versioning.version_invalid",
        "release.version",
        "Expected a valid UTF-8 version string."
      )
    end
  end

  defp release_version(_release) do
    error(
      "catalogue.versioning.release_invalid",
      "release",
      "Expected an object containing only version."
    )
  end

  defp validate_version(version) do
    if Regex.match?(@stable_core, version) do
      :ok
    else
      error(
        "catalogue.versioning.version_invalid",
        "release.version",
        "Expected a stable MAJOR.MINOR.PATCH version."
      )
    end
  end

  defp version_review_evidence(%{"evidence_refs" => evidence_refs} = version_review)
       when map_size(version_review) == 1 do
    with :ok <- validate_evidence_list(evidence_refs),
         :ok <- validate_evidence_members(evidence_refs),
         :ok <- validate_unique_evidence(evidence_refs) do
      {:ok, evidence_refs}
    end
  end

  defp version_review_evidence(_version_review) do
    error(
      "catalogue.versioning.version_review_invalid",
      "version_review",
      "Expected an object containing only evidence_refs."
    )
  end

  defp validate_evidence_list(evidence_refs) do
    if proper_list?(evidence_refs) and evidence_refs != [] do
      :ok
    else
      error(
        "catalogue.versioning.evidence_refs_invalid",
        "version_review.evidence_refs",
        "Expected a non-empty proper list."
      )
    end
  end

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_value), do: false

  defp validate_evidence_members(evidence_refs), do: validate_evidence_members(evidence_refs, 0)

  defp validate_evidence_members([], _index), do: :ok

  defp validate_evidence_members([evidence_ref | rest], index) do
    if is_binary(evidence_ref) and byte_size(evidence_ref) > 0 and String.valid?(evidence_ref) do
      validate_evidence_members(rest, index + 1)
    else
      error(
        "catalogue.versioning.evidence_ref_invalid",
        "version_review.evidence_refs[#{index}]",
        "Expected a non-empty valid UTF-8 string."
      )
    end
  end

  defp validate_unique_evidence(evidence_refs),
    do: validate_unique_evidence(evidence_refs, MapSet.new(), 0)

  defp validate_unique_evidence([], _seen, _index), do: :ok

  defp validate_unique_evidence([evidence_ref | rest], seen, index) do
    if MapSet.member?(seen, evidence_ref) do
      error(
        "catalogue.versioning.evidence_ref_duplicate",
        "version_review.evidence_refs[#{index}]",
        "Evidence references must be unique."
      )
    else
      validate_unique_evidence(rest, MapSet.put(seen, evidence_ref), index + 1)
    end
  end

  defp error(code, path, message), do: {:error, [%{code: code, path: path, message: message}]}
end
