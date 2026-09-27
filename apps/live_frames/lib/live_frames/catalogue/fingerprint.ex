defmodule LiveFrames.Catalogue.Fingerprint do
  @moduledoc false

  alias LiveFrames.Catalogue.CanonicalJSON
  alias LiveFrames.Catalogue.Contract
  alias LiveFrames.Catalogue.Manifest

  @algorithm "lf-contract-v1-jcs-sha256"
  @fingerprint_pattern ~r/\A[0-9a-f]{64}\z/

  @spec algorithm() :: String.t()
  def algorithm, do: @algorithm

  @spec compute(module(), atom()) :: {:ok, map()} | {:error, [Contract.diagnostic()]}
  def compute(module, function) do
    with {:ok, document} <- Contract.normalize(module, function),
         {:ok, canonical_bytes} <- CanonicalJSON.encode(document) do
      fingerprint =
        :crypto.hash(:sha256, canonical_bytes)
        |> Base.encode16(case: :lower)

      {:ok,
       %{
         "fingerprint_algorithm" => @algorithm,
         "fingerprint" => fingerprint
       }}
    end
  end

  @spec verify(Manifest.t(), module(), atom()) :: :ok | {:error, [Manifest.diagnostic()]}
  def verify(%Manifest{} = manifest, module, function) do
    with {:ok, contract} <- require_contract(manifest.contract),
         {:ok, algorithm} <- contract_algorithm(contract),
         :ok <- supported_algorithm(algorithm),
         {:ok, stored_fingerprint} <- stored_fingerprint(contract),
         {:ok, current} <- compute(module, function),
         :ok <- validate_target(manifest.component, module, function),
         :ok <- compare_fingerprint(stored_fingerprint, current["fingerprint"]) do
      :ok
    end
  end

  def verify(_manifest, _module, _function),
    do:
      error(
        "catalogue.fingerprint.manifest_invalid",
        "$",
        "Expected a decoded Catalogue manifest."
      )

  defp require_contract(contract) when is_map(contract), do: {:ok, contract}

  defp require_contract(_contract),
    do:
      error(
        "catalogue.fingerprint.contract_missing",
        "contract",
        "A contract fingerprint block is required for verification."
      )

  defp contract_algorithm(contract) do
    case Map.fetch(contract, "fingerprint_algorithm") do
      {:ok, algorithm} when is_binary(algorithm) ->
        {:ok, algorithm}

      _ ->
        error(
          "catalogue.fingerprint.algorithm_invalid",
          "contract.fingerprint_algorithm",
          "Fingerprint algorithm must be a string."
        )
    end
  end

  defp supported_algorithm(@algorithm), do: :ok

  defp supported_algorithm(_algorithm),
    do:
      error(
        "catalogue.fingerprint.algorithm_unsupported",
        "contract.fingerprint_algorithm",
        "Fingerprint algorithm is not supported."
      )

  defp stored_fingerprint(contract) do
    case Map.fetch(contract, "fingerprint") do
      {:ok, fingerprint} when is_binary(fingerprint) ->
        if Regex.match?(@fingerprint_pattern, fingerprint) do
          {:ok, fingerprint}
        else
          invalid_fingerprint()
        end

      _ ->
        invalid_fingerprint()
    end
  end

  defp validate_target(component, module, function) do
    with :ok <- validate_module_reference(component, module),
         :ok <- validate_function_reference(component, function) do
      :ok
    end
  end

  defp validate_module_reference(component, module) do
    reference = if is_map(component), do: Map.get(component, "module"), else: nil
    expected = module |> Atom.to_string() |> String.replace_prefix("Elixir.", "")

    if reference == expected do
      :ok
    else
      error(
        "catalogue.fingerprint.target_mismatch",
        "component.module",
        "Manifest module reference does not match the supplied target."
      )
    end
  end

  defp validate_function_reference(component, function) do
    reference = if is_map(component), do: Map.get(component, "function"), else: nil

    if reference == Atom.to_string(function) do
      :ok
    else
      error(
        "catalogue.fingerprint.target_mismatch",
        "component.function",
        "Manifest function reference does not match the supplied target."
      )
    end
  end

  defp compare_fingerprint(stored, current) when stored == current, do: :ok

  defp compare_fingerprint(_stored, _current),
    do:
      error(
        "catalogue.fingerprint.stale",
        "contract.fingerprint",
        "Stored contract fingerprint does not match the current production contract."
      )

  defp invalid_fingerprint,
    do:
      error(
        "catalogue.fingerprint.value_invalid",
        "contract.fingerprint",
        "Fingerprint must be 64 lowercase hexadecimal characters."
      )

  defp error(code, path, message), do: {:error, [%{code: code, path: path, message: message}]}
end
