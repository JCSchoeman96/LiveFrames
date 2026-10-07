defmodule LiveFrames.ComponentContract do
  @moduledoc """
  Public API for the source-independent ComponentContract format.
  """

  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentContract.CollectionInput
  alias LiveFrames.ComponentContract.Diagnostic
  alias LiveFrames.ComponentContract.ReferenceValidation
  alias LiveFrames.ComponentContract.Serializer
  alias LiveFrames.ComponentContract.Slot
  alias LiveFrames.ComponentContract.Validation
  alias LiveFrames.ComponentContract.ValidationError

  @current_format_version "1.0.0"
  @categories [:primitive, :component, :pattern, :section]
  @approval_statuses [:proposed, :approved, :needs_review, :rejected]

  @type t :: %__MODULE__{
          contract_format_version: String.t(),
          contract_id: String.t() | nil,
          category: atom(),
          module_intent: String.t() | nil,
          function_intent: String.t() | nil,
          public_attrs: [Attr.t()],
          public_slots: [Slot.t()],
          collection_inputs: [CollectionInput.t()],
          binding_projections: [BindingProjection.t()],
          diagnostics: [Diagnostic.t()],
          provenance: map(),
          approval_status: atom()
        }

  defstruct contract_format_version: @current_format_version,
            contract_id: nil,
            category: :component,
            module_intent: nil,
            function_intent: nil,
            public_attrs: [],
            public_slots: [],
            collection_inputs: [],
            binding_projections: [],
            diagnostics: [],
            provenance: %{},
            approval_status: :proposed

  @spec current_format_version() :: String.t()
  def current_format_version, do: @current_format_version

  @spec categories() :: [atom()]
  def categories, do: @categories

  @spec approval_statuses() :: [atom()]
  def approval_statuses, do: @approval_statuses

  @spec new(keyword()) :: t()
  def new(attrs \\ []) when is_list(attrs), do: struct(__MODULE__, attrs)

  @spec validate(term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate(contract), do: Validation.validate(contract)

  @spec validate!(t()) :: t()
  def validate!(contract) do
    case validate(contract) do
      :ok -> contract
      {:error, diagnostics} -> raise ValidationError, diagnostics: diagnostics
    end
  end

  @spec validate_ir_references(t(), LiveFrames.IR.DesignDocument.t()) ::
          :ok | {:error, [Diagnostic.t()]}
  def validate_ir_references(contract, design_document),
    do: ReferenceValidation.validate(contract, design_document)

  @spec validate_for_generation(t(), LiveFrames.IR.DesignDocument.t()) ::
          :ok | {:error, [Diagnostic.t()]}
  def validate_for_generation(contract, design_document),
    do: Validation.validate_for_generation(contract, design_document)

  @spec validate_generation_prerequisites(term(), term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate_generation_prerequisites(contract, design_document),
    do: Validation.validate_generation_prerequisites(contract, design_document)

  @spec to_map(t()) :: map()
  def to_map(contract), do: Serializer.to_map(contract)

  @spec encode(t()) :: {:ok, String.t()} | {:error, [Diagnostic.t()]}
  def encode(contract) do
    case validate(contract) do
      :ok -> Serializer.encode(contract)
      {:error, diagnostics} -> {:error, diagnostics}
    end
  end

  @spec encode!(t()) :: String.t()
  def encode!(contract) do
    contract
    |> validate!()
    |> Serializer.encode!()
  end
end
