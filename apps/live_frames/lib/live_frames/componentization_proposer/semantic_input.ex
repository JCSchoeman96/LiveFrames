defmodule LiveFrames.ComponentizationProposer.SemanticInput.ContractIdentityDecision do
  @moduledoc "Explicit ContractIdentity decision. No source inference or artifact defaults."
  @type t :: %__MODULE__{contract_id: String.t() | nil}
  defstruct contract_id: nil
end

defmodule LiveFrames.ComponentizationProposer.SemanticInput.ClassificationDecision do
  @moduledoc "Explicit Classification decision. No source inference or artifact defaults."
  @type t :: %__MODULE__{
          category: :primitive | :component | :pattern | :section | nil,
          module_intent: String.t() | nil,
          function_intent: String.t() | nil
        }
  defstruct category: nil, module_intent: nil, function_intent: nil
end

defmodule LiveFrames.ComponentizationProposer.SemanticInput.BoundaryDecision do
  @moduledoc "Explicit Boundary decision. No source inference or artifact defaults."
  @type t :: %__MODULE__{
          boundary_node_id: String.t() | nil,
          multi_root_unsupported: boolean() | nil
        }
  defstruct boundary_node_id: nil, multi_root_unsupported: nil
end

defmodule LiveFrames.ComponentizationProposer.SemanticInput.PublicAttrDecision do
  @moduledoc "Explicit PublicAttr decision. No source inference or artifact defaults."
  @type t :: %__MODULE__{
          name: String.t() | nil,
          type: :string | :integer | :boolean | :list | :map | :global | :any | nil,
          required: boolean() | nil,
          default: term(),
          semantic_purpose: String.t() | nil,
          validation: map() | nil,
          accessibility: map() | nil,
          provenance: map() | nil
        }
  defstruct name: nil,
            type: nil,
            required: nil,
            default: :not_supplied,
            semantic_purpose: nil,
            validation: nil,
            accessibility: nil,
            provenance: nil
end

defmodule LiveFrames.ComponentizationProposer.SemanticInput.PublicSlotDecision do
  @moduledoc "Explicit PublicSlot decision. No source inference or artifact defaults."
  @type t :: %__MODULE__{
          name: String.t() | nil,
          cardinality: String.t() | nil,
          required: boolean() | nil,
          semantic_purpose: String.t() | nil,
          consumer_responsibility: String.t() | nil,
          validation: map() | nil,
          accessibility: map() | nil,
          provenance: map() | nil
        }
  defstruct name: nil,
            cardinality: nil,
            required: nil,
            semantic_purpose: nil,
            consumer_responsibility: nil,
            validation: nil,
            accessibility: nil,
            provenance: nil
end

defmodule LiveFrames.ComponentizationProposer.SemanticInput.CollectionAdmissionDecision do
  @moduledoc "Explicit CollectionAdmission decision. No source inference or artifact defaults."
  @type t :: %__MODULE__{
          source_collection_binding_id: String.t() | nil,
          public_attr_name: String.t() | nil,
          parent_collection_binding_id: String.t() | nil,
          parent_item_field_name: String.t() | nil,
          provenance: map() | nil
        }
  defstruct source_collection_binding_id: nil,
            public_attr_name: nil,
            parent_collection_binding_id: nil,
            parent_item_field_name: nil,
            provenance: nil
end

defmodule LiveFrames.ComponentizationProposer.SemanticInput.ItemFieldDecision do
  @moduledoc "Explicit ItemField decision. No source inference or artifact defaults."
  @type t :: %__MODULE__{
          source_collection_binding_id: String.t() | nil,
          name: String.t() | nil,
          type: :string | :integer | :boolean | :list | :map | :global | :any | nil,
          required: boolean() | nil,
          default: term(),
          semantic_purpose: String.t() | nil,
          validation: map() | nil,
          accessibility: map() | nil,
          provenance: map() | nil
        }
  defstruct source_collection_binding_id: nil,
            name: nil,
            type: nil,
            required: nil,
            default: :not_supplied,
            semantic_purpose: nil,
            validation: nil,
            accessibility: nil,
            provenance: nil
end

defmodule LiveFrames.ComponentizationProposer.SemanticInput.CollectionCountLinkDecision do
  @moduledoc "Explicit CollectionCountLink decision. No source inference or artifact defaults."
  @type t :: %__MODULE__{
          source_collection_binding_id: String.t() | nil,
          count_public_name: String.t() | nil,
          count_value_binding_id: String.t() | nil
        }
  defstruct source_collection_binding_id: nil, count_public_name: nil, count_value_binding_id: nil
end

defmodule LiveFrames.ComponentizationProposer.SemanticInput.BindingAssignmentDecision do
  @moduledoc "Explicit BindingAssignment decision. No source inference or artifact defaults."
  @type t :: %__MODULE__{
          source_binding_kind: :collection | :value | nil,
          source_binding_id: String.t() | nil,
          assignment_kind:
            :scalar_attr
            | :collection_attr
            | :collection_item_field_value
            | :collection_item_field_nested_collection
            | :collection_count_attr
            | :collection_count_item_field
            | :slot
            | nil,
          public_attr_name: String.t() | nil,
          public_slot_name: String.t() | nil,
          item_field_name: String.t() | nil,
          parent_item_field_name: String.t() | nil,
          source_collection_binding_id: String.t() | nil
        }
  defstruct source_binding_kind: nil,
            source_binding_id: nil,
            assignment_kind: nil,
            public_attr_name: nil,
            public_slot_name: nil,
            item_field_name: nil,
            parent_item_field_name: nil,
            source_collection_binding_id: nil
end

defmodule LiveFrames.ComponentizationProposer.SemanticInput.RenderPlacementDecision do
  @moduledoc "Explicit RenderPlacement decision. No source inference or artifact defaults."
  @type t :: %__MODULE__{
          public_target_kind: :attr | :slot | nil,
          public_target_name: String.t() | nil,
          target_node_id: String.t() | nil,
          render_role: atom() | nil
        }
  defstruct public_target_kind: nil,
            public_target_name: nil,
            target_node_id: nil,
            render_role: nil
end

defmodule LiveFrames.ComponentizationProposer.SemanticInput.ImageAccessibilityDecision do
  @moduledoc "Explicit ImageAccessibility decision. No source inference or artifact defaults."
  @type t :: %__MODULE__{
          target_kind: :attr | :item_field | nil,
          target_name: String.t() | nil,
          source_collection_binding_id: String.t() | nil,
          accessibility: map() | nil
        }
  defstruct target_kind: nil,
            target_name: nil,
            source_collection_binding_id: nil,
            accessibility: nil
end

defmodule LiveFrames.ComponentizationProposer.SemanticInput.EvidenceHandlingDecision do
  @moduledoc "Explicit EvidenceHandling decision. No source inference or artifact defaults."
  @type t :: %__MODULE__{
          source_binding_kind: :collection | :value | nil,
          source_binding_id: String.t() | nil,
          outcome: :omit_public_projection | nil
        }
  defstruct source_binding_kind: nil, source_binding_id: nil, outcome: nil
end

defmodule LiveFrames.ComponentizationProposer.SemanticInput.StaticContentDispositionDecision do
  @moduledoc "Explicit StaticContentDisposition decision. No source inference or artifact defaults."
  @type t :: %__MODULE__{
          target_kind: :internal_node | :promote_attr | :promote_slot | nil,
          design_node_id: String.t() | nil,
          public_target_name: String.t() | nil
        }
  defstruct target_kind: nil, design_node_id: nil, public_target_name: nil
end

defmodule LiveFrames.ComponentizationProposer.SemanticInput do
  @moduledoc """
  Explicit compile-time semantic decisions, validated against a supplied validated DesignDocument.

  `validate/2` returns a canonical bundle or deterministic transient diagnostics.
  This input has no serialized format or persistence API. Decision fields default
  to nil, except `default`, whose missing marker distinguishes omission from an
  explicitly supplied nil. No semantic field is filled from artifact defaults.
  """
  @repeatable_families [
    :public_attrs,
    :public_slots,
    :collection_admissions,
    :item_fields,
    :collection_count_links,
    :binding_assignments,
    :render_placements,
    :image_accessibility,
    :evidence_handling,
    :static_content_dispositions
  ]
  @type t :: %__MODULE__{
          contract_identity: __MODULE__.ContractIdentityDecision.t() | nil,
          classification: __MODULE__.ClassificationDecision.t() | nil,
          boundary: __MODULE__.BoundaryDecision.t() | nil,
          public_attrs: [__MODULE__.PublicAttrDecision.t()],
          public_slots: [__MODULE__.PublicSlotDecision.t()],
          collection_admissions: [__MODULE__.CollectionAdmissionDecision.t()],
          item_fields: [__MODULE__.ItemFieldDecision.t()],
          collection_count_links: [__MODULE__.CollectionCountLinkDecision.t()],
          binding_assignments: [__MODULE__.BindingAssignmentDecision.t()],
          render_placements: [__MODULE__.RenderPlacementDecision.t()],
          image_accessibility: [__MODULE__.ImageAccessibilityDecision.t()],
          evidence_handling: [__MODULE__.EvidenceHandlingDecision.t()],
          static_content_dispositions: [__MODULE__.StaticContentDispositionDecision.t()]
        }
  defstruct contract_identity: nil,
            classification: nil,
            boundary: nil,
            public_attrs: [],
            public_slots: [],
            collection_admissions: [],
            item_fields: [],
            collection_count_links: [],
            binding_assignments: [],
            render_placements: [],
            image_accessibility: [],
            evidence_handling: [],
            static_content_dispositions: []

  @spec repeatable_families() :: [atom()]
  def repeatable_families, do: @repeatable_families

  @spec validate(term(), LiveFrames.IR.DesignDocument.t()) ::
          {:ok, t()} | {:error, [LiveFrames.ComponentizationProposer.Diagnostic.t()]}
  defdelegate validate(input, document),
    to: LiveFrames.ComponentizationProposer.SemanticInput.Validation
end
