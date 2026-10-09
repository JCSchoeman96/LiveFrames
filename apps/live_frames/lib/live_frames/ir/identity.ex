defmodule LiveFrames.IR.Identity do
  @moduledoc """
  Deterministic identity for a validated DesignDocument.
  """

  alias LiveFrames.IR

  @canonicalization_id "lf-ir-serializer-v1"
  @digest_algorithm "sha-256"

  @type t :: %__MODULE__{
          ir_version: String.t(),
          canonicalization_id: String.t(),
          digest_algorithm: String.t(),
          digest: String.t()
        }

  defstruct [:ir_version, :canonicalization_id, :digest_algorithm, :digest]

  @spec canonicalization_id() :: String.t()
  def canonicalization_id, do: @canonicalization_id

  @spec digest_algorithm() :: String.t()
  def digest_algorithm, do: @digest_algorithm

  @spec supported_canonicalization_id?(term()) :: boolean()
  def supported_canonicalization_id?(@canonicalization_id), do: true
  def supported_canonicalization_id?(_value), do: false

  @spec supported_digest_algorithm?(term()) :: boolean()
  def supported_digest_algorithm?(@digest_algorithm), do: true
  def supported_digest_algorithm?(_value), do: false

  @spec from_document(term()) :: {:ok, t()} | {:error, [IR.Diagnostic.t()]}
  def from_document(document) do
    case IR.validate(document) do
      :ok ->
        digest =
          document
          |> IR.encode!()
          |> then(&:crypto.hash(:sha256, &1))
          |> Base.encode16(case: :lower)

        {:ok,
         %__MODULE__{
           ir_version: document.ir_version,
           canonicalization_id: canonicalization_id(),
           digest_algorithm: digest_algorithm(),
           digest: digest
         }}

      {:error, diagnostics} ->
        {:error, diagnostics}
    end
  end
end
