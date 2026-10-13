defmodule LiveFrames.Behavior.DesignDocumentIdentity do
  @moduledoc """
  Compatibility policy for DesignDocument identities stored in Behavior artifacts.
  """

  alias LiveFrames.IR.Identity

  @supported_ir_versions ["3.0.0", "4.0.0"]
  @digest_pattern ~r/\A[0-9a-f]{64}\z/
  @fields [:ir_version, :canonicalization_id, :digest_algorithm, :digest]

  @spec valid?(term()) :: boolean()
  def valid?(%Identity{} = identity) do
    Enum.sort(Map.keys(identity)) == Enum.sort([:__struct__ | @fields]) and
      identity.ir_version in @supported_ir_versions and
      Identity.supported_canonicalization_id?(identity.canonicalization_id) and
      Identity.supported_digest_algorithm?(identity.digest_algorithm) and
      is_binary(identity.digest) and Regex.match?(@digest_pattern, identity.digest)
  end

  def valid?(_identity), do: false
end
