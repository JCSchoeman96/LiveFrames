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

  @spec validate_publish_new_version(term(), Manifest.t(), term()) ::
          {:ok, [String.t()]} | {:error, [Manifest.diagnostic()]}
  def validate_publish_new_version(current_version, candidate_manifest, compatibility_review) do
    with {:ok, current_components} <- current_version_components(current_version),
         {:ok, release} <- candidate_release(candidate_manifest),
         {:ok, proposed_version} <- release_version(release),
         {:ok, proposed_components} <- proposed_version_components(proposed_version),
         {:ok, compatibility_class, evidence_refs} <-
           compatibility_review(compatibility_review),
         :ok <- validate_version_is_greater(proposed_components, current_components),
         :ok <- validate_increment(compatibility_class, proposed_components, current_components) do
      {:ok, evidence_refs}
    end
  end

  defp candidate_release(%Manifest{release: release}), do: {:ok, release}

  defp candidate_release(_candidate_manifest) do
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
    case parse_stable_version(version) do
      {:ok, _components} ->
        :ok

      :error ->
        error(
          "catalogue.versioning.version_invalid",
          "release.version",
          "Expected a stable MAJOR.MINOR.PATCH version."
        )
    end
  end

  defp current_version_components(current_version) do
    case current_version do
      version when is_binary(version) ->
        if String.valid?(version) do
          case parse_stable_version(version) do
            {:ok, components} ->
              {:ok, components}

            :error ->
              current_version_error()
          end
        else
          current_version_error()
        end

      _value ->
        current_version_error()
    end
  end

  defp current_version_error do
    error(
      "catalogue.versioning.current_version_invalid",
      "current_version",
      "Expected a stable MAJOR.MINOR.PATCH version string."
    )
  end

  defp proposed_version_components(version) do
    case parse_stable_version(version) do
      {:ok, components} ->
        {:ok, components}

      :error ->
        error(
          "catalogue.versioning.version_invalid",
          "release.version",
          "Expected a stable MAJOR.MINOR.PATCH version."
        )
    end
  end

  defp parse_stable_version(version) do
    case Regex.run(@stable_core, version, capture: :all_but_first) do
      [major, minor, patch] ->
        {:ok, {String.to_integer(major), String.to_integer(minor), String.to_integer(patch)}}

      _match ->
        :error
    end
  end

  defp compatibility_review(%{"class" => class, "evidence_refs" => evidence_refs} = review)
       when map_size(review) == 2 do
    with :ok <- validate_compatibility_class(class),
         :ok <- validate_evidence_list(evidence_refs, "compatibility_review.evidence_refs"),
         :ok <-
           validate_evidence_members(evidence_refs, "compatibility_review.evidence_refs"),
         :ok <-
           validate_unique_evidence(evidence_refs, "compatibility_review.evidence_refs") do
      {:ok, class, evidence_refs}
    end
  end

  defp compatibility_review(_review) do
    error(
      "catalogue.versioning.compatibility_review_invalid",
      "compatibility_review",
      "Expected an object containing only class and evidence_refs."
    )
  end

  defp validate_compatibility_class(class) when class in ["major", "minor", "patch"], do: :ok

  defp validate_compatibility_class(_class) do
    error(
      "catalogue.versioning.compatibility_class_invalid",
      "compatibility_review.class",
      "Expected major, minor, or patch."
    )
  end

  defp validate_version_is_greater(proposed, current) do
    if version_greater?(proposed, current) do
      :ok
    else
      error(
        "catalogue.versioning.version_not_greater",
        "release.version",
        "Expected the proposed version to be greater than the current version."
      )
    end
  end

  defp version_greater?(
         {proposed_major, proposed_minor, proposed_patch},
         {current_major, current_minor, current_patch}
       ) do
    proposed_major > current_major or
      (proposed_major == current_major and proposed_minor > current_minor) or
      (proposed_major == current_major and proposed_minor == current_minor and
         proposed_patch > current_patch)
  end

  defp validate_increment(class, proposed, current) do
    if exact_increment?(class, current, proposed) do
      :ok
    else
      error(
        "catalogue.versioning.increment_mismatch",
        "release.version",
        "Expected the proposed version to match the reviewed compatibility class."
      )
    end
  end

  defp exact_increment?(
         "patch",
         {current_major, current_minor, current_patch},
         {proposed_major, proposed_minor, proposed_patch}
       ) do
    proposed_major == current_major and proposed_minor == current_minor and
      proposed_patch == current_patch + 1
  end

  defp exact_increment?(
         "minor",
         {current_major, current_minor, _current_patch},
         {proposed_major, proposed_minor, proposed_patch}
       ) do
    proposed_major == current_major and proposed_minor == current_minor + 1 and
      proposed_patch == 0
  end

  defp exact_increment?(
         "major",
         {current_major, _current_minor, _current_patch},
         {proposed_major, proposed_minor, proposed_patch}
       ) do
    proposed_major == current_major + 1 and proposed_minor == 0 and proposed_patch == 0
  end

  defp version_review_evidence(%{"evidence_refs" => evidence_refs} = version_review)
       when map_size(version_review) == 1 do
    with :ok <- validate_evidence_list(evidence_refs, "version_review.evidence_refs"),
         :ok <- validate_evidence_members(evidence_refs, "version_review.evidence_refs"),
         :ok <- validate_unique_evidence(evidence_refs, "version_review.evidence_refs") do
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

  defp validate_evidence_list(evidence_refs, path) do
    if proper_list?(evidence_refs) and evidence_refs != [] do
      :ok
    else
      error(
        "catalogue.versioning.evidence_refs_invalid",
        path,
        "Expected a non-empty proper list."
      )
    end
  end

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_value), do: false

  defp validate_evidence_members(evidence_refs, path),
    do: validate_evidence_members(evidence_refs, path, 0)

  defp validate_evidence_members([], _path, _index), do: :ok

  defp validate_evidence_members([evidence_ref | rest], path, index) do
    if is_binary(evidence_ref) and byte_size(evidence_ref) > 0 and String.valid?(evidence_ref) do
      validate_evidence_members(rest, path, index + 1)
    else
      error(
        "catalogue.versioning.evidence_ref_invalid",
        "#{path}[#{index}]",
        "Expected a non-empty valid UTF-8 string."
      )
    end
  end

  defp validate_unique_evidence(evidence_refs, path),
    do: validate_unique_evidence(evidence_refs, path, MapSet.new(), 0)

  defp validate_unique_evidence([], _path, _seen, _index), do: :ok

  defp validate_unique_evidence([evidence_ref | rest], path, seen, index) do
    if MapSet.member?(seen, evidence_ref) do
      error(
        "catalogue.versioning.evidence_ref_duplicate",
        "#{path}[#{index}]",
        "Evidence references must be unique."
      )
    else
      validate_unique_evidence(rest, path, MapSet.put(seen, evidence_ref), index + 1)
    end
  end

  defp error(code, path, message), do: {:error, [%{code: code, path: path, message: message}]}
end
