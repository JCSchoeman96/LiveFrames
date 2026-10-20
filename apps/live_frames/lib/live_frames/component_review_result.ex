defmodule LiveFrames.ComponentReviewResult do
  @moduledoc """
  Immutable review evidence bound to one approved ComponentContract, plan, and DesignDocument.
  """

  alias LiveFrames.CanonicalJSON
  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Diagnostic
  alias LiveFrames.ComponentizationPlan

  @review_format_version "1.0.0"
  @id_algorithm "lf-component-review-v1-jcs-sha256"
  @digest_pattern ~r/\A[0-9a-f]{64}\z/
  @timestamp_pattern ~r/\A[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{6}Z\z/
  @fields [
    :review_format_version,
    :component_contract_id,
    :component_contract_digest_algorithm,
    :component_contract_digest,
    :design_document_sha256,
    :componentization_plan_digest_algorithm,
    :componentization_plan_digest,
    :decision,
    :reviewer_identity,
    :reviewed_at,
    :evidence_refs
  ]

  @type t :: %__MODULE__{
          review_format_version: String.t(),
          component_contract_id: String.t(),
          component_contract_digest_algorithm: String.t(),
          component_contract_digest: String.t(),
          design_document_sha256: String.t(),
          componentization_plan_digest_algorithm: String.t(),
          componentization_plan_digest: String.t(),
          decision: String.t(),
          reviewer_identity: String.t(),
          reviewed_at: String.t(),
          evidence_refs: [String.t()]
        }

  defstruct @fields

  @spec algorithm() :: String.t()
  def algorithm, do: @id_algorithm

  @spec validate(term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate(%__MODULE__{} = review_result) do
    cond do
      not exact_fields?(review_result) ->
        invalid()

      review_result.review_format_version != @review_format_version ->
        diagnostic("component_review_result.format_unsupported", "review format is unsupported")

      not nonempty_unicode?(review_result.component_contract_id) ->
        invalid()

      review_result.component_contract_digest_algorithm != "sha-256" ->
        invalid()

      not digest?(review_result.component_contract_digest) ->
        invalid()

      not digest?(review_result.design_document_sha256) ->
        invalid()

      review_result.componentization_plan_digest_algorithm != "sha-256" ->
        invalid()

      not digest?(review_result.componentization_plan_digest) ->
        invalid()

      review_result.decision not in ["approved", "needs_review", "rejected"] ->
        invalid()

      not nonempty_unicode?(review_result.reviewer_identity) ->
        invalid()

      not timestamp_valid?(review_result.reviewed_at) ->
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
        {:ok, "crv_" <> sha256(bytes)}

      {:error, diagnostics} ->
        {:error, diagnostics}
    end
  end

  @spec validate_against(term(), term(), term(), term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate_against(review_result, approved_component_contract, plan, design_document) do
    with :ok <- validate(review_result),
         :ok <- require_approved(review_result, approved_component_contract),
         {:ok, contract_bytes} <- encode_contract(approved_component_contract),
         :ok <- matching_contract_id(review_result, approved_component_contract),
         :ok <- matching_contract_digest(review_result, sha256(contract_bytes)),
         {:ok, plan_bytes} <- encode_plan(plan),
         :ok <- matching_plan_contract(plan, approved_component_contract),
         :ok <- matching_plan_digest(review_result, sha256(plan_bytes)),
         {:ok, document_digest} <- document_digest(design_document),
         :ok <- matching_document_digest(review_result, document_digest),
         :ok <- matching_plan_document(plan, document_digest) do
      :ok
    end
  rescue
    _error ->
      invalid()
  catch
    _kind, _reason ->
      invalid()
  end

  defp canonical_value(review_result) do
    %{
      "review_format_version" => review_result.review_format_version,
      "component_contract_id" => review_result.component_contract_id,
      "component_contract_digest_algorithm" => review_result.component_contract_digest_algorithm,
      "component_contract_digest" => review_result.component_contract_digest,
      "design_document_sha256" => review_result.design_document_sha256,
      "componentization_plan_digest_algorithm" =>
        review_result.componentization_plan_digest_algorithm,
      "componentization_plan_digest" => review_result.componentization_plan_digest,
      "decision" => review_result.decision,
      "reviewer_identity" => review_result.reviewer_identity,
      "reviewed_at" => review_result.reviewed_at,
      "evidence_refs" => Enum.sort(review_result.evidence_refs)
    }
  end

  defp exact_fields?(review_result) do
    Enum.sort(Map.keys(review_result)) == Enum.sort([:__struct__ | @fields])
  end

  defp digest?(value), do: is_binary(value) and Regex.match?(@digest_pattern, value)

  defp nonempty_unicode?(value) do
    is_binary(value) and value != "" and match?({:ok, _}, CanonicalJSON.encode(value))
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
    proper_list?(refs) and refs != [] and Enum.all?(refs, &nonempty_unicode?/1) and
      length(refs) == MapSet.size(MapSet.new(refs))
  end

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_tail), do: false

  defp require_approved(
         %__MODULE__{decision: "approved"},
         %ComponentContract{approval_status: :approved}
       ),
       do: :ok

  defp require_approved(_review_result, %ComponentContract{approval_status: :approved}),
    do: diagnostic("component_review_result.decision_mismatch", "review result is not approved")

  defp require_approved(_review_result, _contract),
    do: diagnostic("component_review_result.contract_not_approved", "contract is not approved")

  defp encode_contract(%ComponentContract{} = contract) do
    case ComponentContract.encode(contract) do
      {:ok, bytes} ->
        {:ok, bytes}

      {:error, _diagnostics} ->
        diagnostic("component_review_result.contract_mismatch", "approved contract is invalid")
    end
  end

  defp encode_contract(_contract),
    do: diagnostic("component_review_result.contract_mismatch", "expected an approved contract")

  defp matching_contract_id(review_result, contract) do
    if review_result.component_contract_id == contract.contract_id do
      :ok
    else
      diagnostic("component_review_result.contract_mismatch", "contract ID does not match")
    end
  end

  defp matching_contract_digest(review_result, digest) do
    if review_result.component_contract_digest_algorithm == "sha-256" and
         review_result.component_contract_digest == digest do
      :ok
    else
      diagnostic(
        "component_review_result.contract_digest_mismatch",
        "approved contract bytes do not match the review result"
      )
    end
  end

  defp encode_plan(%ComponentizationPlan{} = plan) do
    case ComponentizationPlan.encode(plan) do
      {:ok, bytes} ->
        {:ok, bytes}

      {:error, _diagnostics} ->
        diagnostic("component_review_result.plan_mismatch", "componentization plan is invalid")
    end
  end

  defp encode_plan(_plan),
    do: diagnostic("component_review_result.plan_mismatch", "expected a ComponentizationPlan")

  defp matching_plan_contract(%ComponentizationPlan{} = plan, %ComponentContract{} = contract) do
    if plan.contract_id == contract.contract_id do
      :ok
    else
      diagnostic("component_review_result.plan_mismatch", "plan contract ID does not match")
    end
  end

  defp matching_plan_digest(review_result, digest) do
    if review_result.componentization_plan_digest_algorithm == "sha-256" and
         review_result.componentization_plan_digest == digest do
      :ok
    else
      diagnostic(
        "component_review_result.plan_digest_mismatch",
        "exact plan bytes do not match the review result"
      )
    end
  end

  defp document_digest(design_document) do
    case ComponentizationPlan.design_document_sha256(design_document) do
      {:ok, digest} ->
        {:ok, digest}

      {:error, _diagnostics} ->
        diagnostic("component_review_result.document_mismatch", "DesignDocument is invalid")
    end
  end

  defp matching_document_digest(review_result, digest) do
    if review_result.design_document_sha256 == digest do
      :ok
    else
      diagnostic(
        "component_review_result.document_mismatch",
        "DesignDocument digest does not match"
      )
    end
  end

  defp matching_plan_document(%ComponentizationPlan{} = plan, digest) do
    if plan.design_document_sha256 == digest do
      :ok
    else
      diagnostic(
        "component_review_result.document_mismatch",
        "plan document digest does not match"
      )
    end
  end

  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

  defp invalid,
    do:
      diagnostic("component_review_result.invalid", "ComponentReviewResult structure is invalid")

  defp diagnostic(code, message) do
    {:error, [%Diagnostic{code: code, severity: :error, message: message}]}
  end
end
