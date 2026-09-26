defmodule LiveFrames.Catalogue.Fingerprint do
  @moduledoc false

  alias LiveFrames.Catalogue.CanonicalJSON
  alias LiveFrames.Catalogue.Contract

  @algorithm "lf-contract-v1-jcs-sha256"

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
end
