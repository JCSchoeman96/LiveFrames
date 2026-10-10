defmodule LiveFrames.Behavior.ReviewResult do
  @moduledoc """
  Immutable human review evidence for one exact BehaviorContract.
  """

  alias LiveFrames.Behavior.Diagnostic
  alias LiveFrames.Behavior.Serializer
  alias LiveFrames.CanonicalJSON
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.Identity

  @review_format_version "1.0.0"
  @id_algorithm "lf-behavior-review-v1-jcs-sha256"
  @digest_pattern ~r/\A[0-9a-f]{64}\z/
  @timestamp_pattern ~r/\A[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{6}Z\z/
  @fields [
    :review_format_version,
    :design_document_identity,
    :behavior_contract_digest_algorithm,
    :behavior_contract_digest,
    :decision,
    :reviewer_identity,
    :reviewed_at,
    :review_note,
    :evidence_refs
  ]

  @type t :: %__MODULE__{
          review_format_version: String.t(),
          design_document_identity: Identity.t(),
          behavior_contract_digest_algorithm: String.t(),
          behavior_contract_digest: String.t(),
          decision: String.t(),
          reviewer_identity: String.t(),
          reviewed_at: String.t(),
          review_note: String.t() | nil,
          evidence_refs: [String.t()]
        }

  defstruct [
    :review_format_version,
    :design_document_identity,
    :behavior_contract_digest_algorithm,
    :behavior_contract_digest,
    :decision,
    :reviewer_identity,
    :reviewed_at,
    :review_note,
    :evidence_refs
  ]

  @spec algorithm() :: String.t()
  def algorithm, do: @id_algorithm

  @spec validate(term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate(%__MODULE__{} = review_result) do
    cond do
      not exact_fields?(review_result, @fields) ->
        invalid()

      review_result.review_format_version != @review_format_version ->
        diagnostic("behavior.review.format_unsupported", "structure")

      not identity_valid?(review_result.design_document_identity) ->
        invalid()

      review_result.behavior_contract_digest_algorithm != Serializer.algorithm() ->
        invalid()

      not digest?(review_result.behavior_contract_digest) ->
        invalid()

      review_result.decision not in ["approved", "needs_review", "rejected"] ->
        invalid()

      not nonempty_unicode?(review_result.reviewer_identity) ->
        invalid()

      not timestamp_valid?(review_result.reviewed_at) ->
        invalid()

      not optional_unicode?(review_result.review_note) ->
        invalid()

      not evidence_refs_valid?(review_result.evidence_refs) ->
        invalid()

      true ->
        :ok
    end
  end

  def validate(_review_result), do: invalid()

  @spec encode(term()) :: {:ok, binary()} | {:error, [Diagnostic.t()]}
  def encode(review_result) do
    with :ok <- validate(review_result),
         {:ok, bytes} <- CanonicalJSON.encode(canonical_value(review_result)) do
      {:ok, bytes}
    else
      {:error, [%Diagnostic{} | _] = diagnostics} -> {:error, diagnostics}
      {:error, _reason} -> invalid()
    end
  end

  @spec id(term()) :: {:ok, String.t()} | {:error, [Diagnostic.t()]}
  def id(review_result) do
    case encode(review_result) do
      {:ok, bytes} ->
        digest = :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
        {:ok, "brv_" <> digest}

      {:error, diagnostics} ->
        {:error, diagnostics}
    end
  end

  @spec validate_against_contract(term(), term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate_against_contract(review_result, behavior_contract) do
    with :ok <- validate(review_result),
         {:ok, contract_digest} <- contract_digest(behavior_contract),
         :ok <- matching_document_identity(review_result, behavior_contract),
         :ok <- matching_digest_algorithm(review_result),
         :ok <- matching_contract_digest(review_result, contract_digest) do
      :ok
    end
  end

  @spec require_approved(term(), term()) :: {:ok, t()} | {:error, [Diagnostic.t()]}
  def require_approved(review_results, behavior_contract) do
    if proper_list?(review_results) do
      case review_results do
        [] ->
          diagnostic("behavior.review.result_missing", "structure")

        [review_result] ->
          with :ok <- validate_against_contract(review_result, behavior_contract),
               true <- review_result.decision == "approved" do
            {:ok, review_result}
          else
            false -> diagnostic("behavior.review.not_approved", "semantic")
            {:error, diagnostics} -> {:error, diagnostics}
          end

        [_first, _second | _rest] ->
          diagnostic("behavior.review.result_ambiguous", "structure")
      end
    else
      invalid()
    end
  end

  defp canonical_value(review_result) do
    identity = review_result.design_document_identity

    %{
      "review_format_version" => review_result.review_format_version,
      "design_document_identity" => %{
        "ir_version" => identity.ir_version,
        "canonicalization_id" => identity.canonicalization_id,
        "digest_algorithm" => identity.digest_algorithm,
        "digest" => identity.digest
      },
      "behavior_contract_digest_algorithm" => review_result.behavior_contract_digest_algorithm,
      "behavior_contract_digest" => review_result.behavior_contract_digest,
      "decision" => review_result.decision,
      "reviewer_identity" => review_result.reviewer_identity,
      "reviewed_at" => review_result.reviewed_at,
      "review_note" => review_result.review_note,
      "evidence_refs" => Enum.sort(review_result.evidence_refs)
    }
  end

  defp identity_valid?(%Identity{} = identity) do
    exact_fields?(identity, [:ir_version, :canonicalization_id, :digest_algorithm, :digest]) and
      identity.ir_version == DesignDocument.current_ir_version() and
      Identity.supported_canonicalization_id?(identity.canonicalization_id) and
      Identity.supported_digest_algorithm?(identity.digest_algorithm) and
      digest?(identity.digest)
  end

  defp identity_valid?(_identity), do: false

  defp exact_fields?(struct, fields) do
    Enum.sort(Map.keys(struct)) == Enum.sort([:__struct__ | fields])
  end

  defp digest?(value), do: is_binary(value) and Regex.match?(@digest_pattern, value)

  defp nonempty_unicode?(value),
    do: is_binary(value) and value != "" and unicode?(value)

  defp optional_unicode?(nil), do: true
  defp optional_unicode?(value), do: is_binary(value) and unicode?(value)

  defp unicode?(value) do
    match?({:ok, _bytes}, CanonicalJSON.encode(value))
  end

  defp timestamp_valid?(value) when is_binary(value) do
    Regex.match?(@timestamp_pattern, value) and
      case DateTime.from_iso8601(value) do
        {:ok, %DateTime{}, 0} -> true
        _ -> false
      end
  end

  defp timestamp_valid?(_value), do: false

  defp evidence_refs_valid?(refs) do
    proper_list?(refs) and Enum.all?(refs, &nonempty_unicode?/1) and
      length(refs) == MapSet.size(MapSet.new(refs))
  end

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_tail), do: false

  defp contract_digest(behavior_contract) do
    case Serializer.digest(behavior_contract) do
      {:ok, digest} -> {:ok, digest}
      {:error, _diagnostics} -> diagnostic("behavior.review.contract_digest_mismatch", "identity")
    end
  end

  defp matching_document_identity(review_result, behavior_contract) do
    if review_result.design_document_identity == behavior_contract.design_document_identity do
      :ok
    else
      diagnostic("behavior.review.document_identity_mismatch", "identity")
    end
  end

  defp matching_digest_algorithm(review_result) do
    if review_result.behavior_contract_digest_algorithm == Serializer.algorithm() do
      :ok
    else
      diagnostic("behavior.review.contract_digest_algorithm_mismatch", "identity")
    end
  end

  defp matching_contract_digest(review_result, contract_digest) do
    if review_result.behavior_contract_digest == contract_digest do
      :ok
    else
      diagnostic("behavior.review.contract_digest_mismatch", "identity")
    end
  end

  defp invalid do
    diagnostic("behavior.review.invalid", "structure")
  end

  defp diagnostic(code, category) do
    {:error,
     [
       %Diagnostic{
         code: code,
         severity: "error",
         category: category,
         message: "BehaviorReviewResult structure is invalid"
       }
     ]}
  end
end
