defmodule LiveFrames.ComponentizationPlan do
  @moduledoc """
  Source-independent placement artifact for a ComponentContract and DesignDocument.
  """

  alias LiveFrames.ComponentizationPlan.Diagnostic
  alias LiveFrames.ComponentizationPlan.NodeDisposition
  alias LiveFrames.ComponentizationPlan.ReferenceValidation
  alias LiveFrames.ComponentizationPlan.RenderProjection
  alias LiveFrames.ComponentizationPlan.Serializer
  alias LiveFrames.ComponentizationPlan.Validation
  alias LiveFrames.ComponentizationPlan.ValidationError
  alias LiveFrames.IR.Identity

  @current_format_version "1.1.0"

  @type t :: %__MODULE__{
          plan_format_version: String.t(),
          contract_id: String.t() | nil,
          design_document_sha256: String.t() | nil,
          boundary_node_id: String.t() | nil,
          render_projections: [RenderProjection.t()],
          node_dispositions: [NodeDisposition.t()],
          diagnostics: [Diagnostic.t()],
          provenance: map()
        }

  defstruct plan_format_version: @current_format_version,
            contract_id: nil,
            design_document_sha256: nil,
            boundary_node_id: nil,
            render_projections: [],
            node_dispositions: [],
            diagnostics: [],
            provenance: %{}

  @spec current_format_version() :: String.t()
  def current_format_version, do: @current_format_version

  @spec render_roles() :: [atom()]
  def render_roles, do: RenderProjection.render_roles()

  @spec validate(term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate(plan), do: Validation.validate(plan)

  @spec validate!(t()) :: t()
  def validate!(plan) do
    case validate(plan) do
      :ok -> plan
      {:error, diagnostics} -> raise ValidationError, diagnostics: diagnostics
    end
  end

  @spec validate_references(term(), term(), term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate_references(plan, component_contract, design_document),
    do: ReferenceValidation.validate(plan, component_contract, design_document)

  @spec validate_references_with_behavior_authority(
          term(),
          term(),
          term(),
          term(),
          term()
        ) :: :ok | {:error, [Diagnostic.t()]}
  def validate_references_with_behavior_authority(
        plan,
        component_contract,
        design_document,
        behavior_contract,
        selected_behavior_review_result
      ),
      do:
        ReferenceValidation.validate_with_behavior_authority(
          plan,
          component_contract,
          design_document,
          behavior_contract,
          selected_behavior_review_result
        )

  @spec validate_for_generation(term(), term(), term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate_for_generation(plan, component_contract, design_document),
    do: ReferenceValidation.validate_for_generation(plan, component_contract, design_document)

  @spec validate_generation_prerequisites(term(), term(), term()) ::
          :ok | {:error, [Diagnostic.t()]}
  def validate_generation_prerequisites(plan, component_contract, design_document),
    do:
      ReferenceValidation.validate_generation_prerequisites(
        plan,
        component_contract,
        design_document
      )

  @spec validate_generation_prerequisites_with_behavior_authority(
          term(),
          term(),
          term(),
          term(),
          term()
        ) :: :ok | {:error, [Diagnostic.t()]}
  def validate_generation_prerequisites_with_behavior_authority(
        plan,
        component_contract,
        design_document,
        behavior_contract,
        selected_behavior_review_result
      ),
      do:
        ReferenceValidation.validate_generation_prerequisites_with_behavior_authority(
          plan,
          component_contract,
          design_document,
          behavior_contract,
          selected_behavior_review_result
        )

  @spec validate_for_generation_with_behavior_authority(
          term(),
          term(),
          term(),
          term(),
          term()
        ) :: :ok | {:error, [Diagnostic.t()]}
  def validate_for_generation_with_behavior_authority(
        plan,
        approved_component_contract,
        design_document,
        behavior_contract,
        selected_behavior_review_result
      ),
      do:
        ReferenceValidation.validate_for_generation_with_behavior_authority(
          plan,
          approved_component_contract,
          design_document,
          behavior_contract,
          selected_behavior_review_result
        )

  @spec validate_for_generation_with_behavior_and_native_realization_authority(
          term(),
          term(),
          term(),
          term(),
          term(),
          term()
        ) :: :ok | {:error, [Diagnostic.t()]}
  def validate_for_generation_with_behavior_and_native_realization_authority(
        plan,
        approved_component_contract,
        design_document,
        behavior_contract,
        selected_behavior_review_result,
        native_realization_authority
      ),
      do:
        ReferenceValidation.validate_for_generation_with_behavior_and_native_realization_authority(
          plan,
          approved_component_contract,
          design_document,
          behavior_contract,
          selected_behavior_review_result,
          native_realization_authority
        )

  @spec design_document_sha256(term()) :: {:ok, String.t()} | {:error, [Diagnostic.t()]}
  def design_document_sha256(design_document) do
    try do
      case Identity.from_document(design_document) do
        {:ok, identity} ->
          {:ok, identity.digest}

        {:error, _ir_diagnostics} ->
          {:error, [fingerprint_error()]}
      end
    rescue
      _error -> {:error, [fingerprint_error()]}
    end
  end

  @spec to_map(term()) :: map() | {:error, [Diagnostic.t()]}
  def to_map(plan) do
    case validate(plan) do
      :ok -> Serializer.to_map(plan)
      {:error, diagnostics} -> {:error, diagnostics}
    end
  end

  @spec encode(term()) :: {:ok, String.t()} | {:error, [Diagnostic.t()]}
  def encode(plan), do: Serializer.encode(plan)

  @spec encode!(term()) :: String.t()
  def encode!(plan), do: Serializer.encode!(plan)

  defp fingerprint_error do
    %Diagnostic{
      code: "componentization_plan.design_document.fingerprint_invalid",
      severity: :error,
      message: "DesignDocument must be valid before its canonical bytes can be fingerprinted"
    }
  end
end
