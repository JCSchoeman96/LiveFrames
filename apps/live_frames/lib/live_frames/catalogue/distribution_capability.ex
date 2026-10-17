defmodule LiveFrames.Catalogue.DistributionCapability do
  @moduledoc false

  alias LiveFrames.Catalogue.Manifest

  @capabilities ["library", "generator", "ejection"]
  @capability_keys ["status", "evidence_refs"]
  @supported_status "supported"

  @spec validate(Manifest.t()) :: :ok | {:error, [Manifest.diagnostic()]}
  def validate(%Manifest{distribution: nil}), do: :ok

  def validate(%Manifest{distribution: distribution}) when is_map(distribution) do
    cond do
      map_size(distribution) == 0 ->
        distribution_invalid()

      unknown_capability_key?(distribution) ->
        capability_unknown()

      true ->
        validate_capabilities(distribution, @capabilities)
    end
  end

  def validate(%Manifest{}), do: distribution_invalid()

  def validate(_manifest) do
    error(
      "catalogue.distribution_capability.manifest_invalid",
      "$",
      "Expected a decoded Catalogue manifest."
    )
  end

  defp unknown_capability_key?(distribution) do
    Enum.any?(Map.keys(distribution), fn key ->
      not is_binary(key) or key not in @capabilities
    end)
  end

  defp validate_capabilities(_distribution, []), do: :ok

  defp validate_capabilities(distribution, [capability | rest]) do
    case Map.fetch(distribution, capability) do
      :error ->
        validate_capabilities(distribution, rest)

      {:ok, value} ->
        with :ok <- validate_capability(value, capability) do
          validate_capabilities(distribution, rest)
        end
    end
  end

  defp validate_capability(capability, name) when is_map(capability) do
    if exact_capability_keys?(capability) do
      with :ok <- validate_status(capability["status"], name),
           :ok <- validate_evidence_refs(capability["evidence_refs"], name) do
        :ok
      end
    else
      capability_invalid(name)
    end
  end

  defp validate_capability(_capability, name), do: capability_invalid(name)

  defp exact_capability_keys?(capability) do
    map_size(capability) == length(@capability_keys) and
      Enum.all?(@capability_keys, &Map.has_key?(capability, &1))
  end

  defp validate_status(@supported_status, _name), do: :ok

  defp validate_status(_status, name) do
    error(
      "catalogue.distribution_capability.status_invalid",
      "distribution.#{name}.status",
      "Expected the exact status \"supported\"."
    )
  end

  defp validate_evidence_refs(evidence_refs, name) do
    path = "distribution.#{name}.evidence_refs"

    if non_empty_proper_list?(evidence_refs) do
      validate_evidence_members(evidence_refs, path, 0, MapSet.new())
    else
      error(
        "catalogue.distribution_capability.evidence_refs_invalid",
        path,
        "Expected a non-empty proper list of evidence references."
      )
    end
  end

  defp validate_evidence_members([], _path, _index, _seen), do: :ok

  defp validate_evidence_members([reference | rest], path, index, seen) do
    cond do
      not non_empty_utf8_string?(reference) ->
        error(
          "catalogue.distribution_capability.evidence_ref_invalid",
          "#{path}[#{index}]",
          "Expected a non-empty valid UTF-8 evidence reference."
        )

      MapSet.member?(seen, reference) ->
        error(
          "catalogue.distribution_capability.evidence_ref_duplicate",
          path,
          "Evidence references must be unique."
        )

      true ->
        validate_evidence_members(rest, path, index + 1, MapSet.put(seen, reference))
    end
  end

  defp non_empty_proper_list?([_head | tail]), do: proper_list?(tail)
  defp non_empty_proper_list?(_value), do: false

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_value), do: false

  defp non_empty_utf8_string?(value) do
    is_binary(value) and byte_size(value) > 0 and String.valid?(value)
  end

  defp distribution_invalid do
    error(
      "catalogue.distribution_capability.distribution_invalid",
      "distribution",
      "Expected a non-empty distribution object."
    )
  end

  defp capability_unknown do
    error(
      "catalogue.distribution_capability.capability_unknown",
      "distribution",
      "Distribution contains an unknown or non-string capability key."
    )
  end

  defp capability_invalid(name) do
    error(
      "catalogue.distribution_capability.capability_invalid",
      "distribution.#{name}",
      "Expected a capability object with exactly status and evidence_refs."
    )
  end

  defp error(code, path, message), do: {:error, [%{code: code, path: path, message: message}]}
end
