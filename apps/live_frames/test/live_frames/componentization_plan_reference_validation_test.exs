defmodule LiveFrames.ComponentizationPlanReferenceValidationTest do
  use ExUnit.Case, async: true

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentContract.CollectionInput
  alias LiveFrames.ComponentContract.ItemField
  alias LiveFrames.ComponentContract.Slot
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.Diagnostic
  alias LiveFrames.ComponentizationPlan.NodeDisposition
  alias LiveFrames.ComponentizationPlan.RenderProjection
  alias LiveFrames.Behavior.Binding, as: BehaviorBinding
  alias LiveFrames.Behavior.Binding.ControlledTarget
  alias LiveFrames.Behavior.Binding.FocusPolicy
  alias LiveFrames.Behavior.Binding.PrimitiveRef
  alias LiveFrames.Behavior.Binding.Trigger
  alias LiveFrames.Behavior.BindingIdentity
  alias LiveFrames.Behavior.Contract, as: BehaviorContract
  alias LiveFrames.Behavior.ReviewResult
  alias LiveFrames.Behavior.Serializer, as: BehaviorSerializer
  alias LiveFrames.IR.CollectionBinding
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR
  alias LiveFrames.IR.Identity
  alias LiveFrames.IR.Interaction
  alias LiveFrames.IR.SourceTrace
  alias LiveFrames.IR.ValueBinding

  @boundary_id DesignNode.deterministic_id([1])
  @heading_id DesignNode.deterministic_id([1, 1])
  @image_id DesignNode.deterministic_id([1, 2])
  @actions_id DesignNode.deterministic_id([1, 3])
  @outside_id DesignNode.deterministic_id([2])
  @disposition_target_id DesignNode.deterministic_id([1, 4])
  @second_disposition_target_id DesignNode.deterministic_id([1, 5])
  @disposition_source_type "synthetic-builder"
  @disposition_source_id "synthetic-node-42"

  defp document(overrides \\ []) do
    roots = [
      %DesignNode{
        node_id: @boundary_id,
        semantic_type: "section",
        children: [
          %DesignNode{
            node_id: @heading_id,
            semantic_type: "heading",
            attributes: %{"tag" => "h2"}
          },
          %DesignNode{node_id: @image_id, semantic_type: "paragraph"},
          %DesignNode{
            node_id: @actions_id,
            semantic_type: "actions",
            children: [
              %DesignNode{
                node_id: DesignNode.deterministic_id([1, 3, 1]),
                semantic_type: "button"
              }
            ]
          }
        ]
      },
      %DesignNode{node_id: @outside_id, semantic_type: "paragraph"}
    ]

    struct!(%DesignDocument{root_nodes: roots}, overrides)
  end

  defp image_document do
    design_document = document()
    [boundary, outside] = design_document.root_nodes
    [heading, image, actions] = boundary.children

    %{
      design_document
      | root_nodes: [
          %{boundary | children: [heading, %{image | semantic_type: "image"}, actions]},
          outside
        ]
    }
  end

  defp role_document do
    design_document = document()
    [boundary, outside] = design_document.root_nodes
    link = %DesignNode{node_id: DesignNode.deterministic_id([1, 4]), semantic_type: "link"}
    link_slot = %DesignNode{node_id: DesignNode.deterministic_id([1, 5]), semantic_type: "link"}

    %{
      design_document
      | root_nodes: [%{boundary | children: boundary.children ++ [link, link_slot]}, outside]
    }
  end

  defp semantic_boundary_document(semantic_type) do
    design_document = document()
    [_boundary, outside] = design_document.root_nodes
    boundary = %DesignNode{node_id: @boundary_id, semantic_type: semantic_type}
    %{design_document | root_nodes: [boundary, outside]}
  end

  defp contract(overrides \\ []) do
    struct!(
      %ComponentContract{
        contract_id: "hero-contract",
        module_intent: "marketing_block",
        function_intent: "hero",
        approval_status: :approved
      },
      overrides
    )
  end

  defp plan(contract, design_document, overrides \\ []) do
    {:ok, fingerprint} = ComponentizationPlan.design_document_sha256(design_document)

    struct!(
      %ComponentizationPlan{
        contract_id: contract.contract_id,
        design_document_sha256: fingerprint,
        boundary_node_id: @boundary_id
      },
      overrides
    )
  end

  defp attr(name, type \\ :string, options \\ []) do
    struct!(%Attr{name: name, type: type, semantic_purpose: name}, options)
  end

  defp render_attr(name, role, target \\ @heading_id) do
    %RenderProjection{public_attr_name: name, render_role: role, target_node_id: target}
  end

  defp binding_projection(id, name, target \\ @heading_id) do
    %BindingProjection{
      source_binding_kind: :value,
      source_binding_id: id,
      projection_kind: :scalar_attr,
      public_attr_name: name,
      target_node_id: target
    }
  end

  defp value_binding(id, target, options \\ []) do
    %ValueBinding{
      value_binding_id: id,
      target_node_id: target,
      target_kind: Keyword.get(options, :target_kind, :text),
      value_kind: Keyword.get(options, :value_kind, :field),
      scope: Keyword.get(options, :scope, :site),
      value_key: Keyword.get(options, :value_key, "field"),
      collection_binding_id: Keyword.get(options, :collection_binding_id),
      normalization_status: Keyword.get(options, :normalization_status, :normalized),
      modifier: Keyword.get(options, :modifier, %LiveFrames.IR.ValueModifier.None{})
    }
  end

  defp rich_text_generation_fixture(location \\ :inside) do
    design_document = document()
    [boundary, outside] = design_document.root_nodes
    [heading | tail] = boundary.children

    {target_id, roots} =
      case location do
        :inside ->
          {@heading_id,
           [%{boundary | children: [%{heading | semantic_type: "rich_text"} | tail]}, outside]}

        :outside ->
          {@outside_id, [boundary, %{outside | semantic_type: "rich_text"}]}
      end

    binding =
      value_binding("vb_description", target_id,
        target_kind: :rich_text,
        scope: :current_entity,
        value_key: "commerce.product.full_description"
      )

    design_document = %{
      design_document
      | root_nodes: roots,
        value_bindings: %{binding.value_binding_id => binding}
    }

    projection = %BindingProjection{
      source_binding_kind: :value,
      source_binding_id: binding.value_binding_id,
      projection_kind: :scalar_attr,
      public_attr_name: "description",
      target_node_id: target_id
    }

    component_contract =
      contract(
        public_attrs: if(location == :inside, do: [attr("description")], else: []),
        binding_projections: if(location == :inside, do: [projection], else: [])
      )

    component_plan = plan(component_contract, design_document)
    {component_plan, component_contract, design_document}
  end

  defp empty_behavior_authority(design_document) do
    {:ok, identity} = Identity.from_document(design_document)

    {:ok, behavior_contract} =
      BindingIdentity.assign(%BehaviorContract{design_document_identity: identity, bindings: []})

    {:ok, digest} = BehaviorSerializer.digest(behavior_contract)
    {behavior_contract, approved_review(identity, digest)}
  end

  defp navigable_heading_document(options \\ []) do
    attributes =
      if Keyword.get(options, :navigable?, true) do
        %{"tag" => "h2", "navigation" => %{"href" => "#"}}
      else
        %{"tag" => "h2"}
      end

    heading = %DesignNode{
      node_id: @heading_id,
      semantic_type: "heading",
      attributes: Map.merge(attributes, Keyword.get(options, :attributes, %{})),
      content: Keyword.get(options, :content, "Title"),
      children: Keyword.get(options, :children, [])
    }

    %DesignDocument{
      root_nodes: [
        %DesignNode{node_id: @boundary_id, semantic_type: "section", children: [heading]}
      ]
    }
  end

  defp codes({:error, diagnostics}), do: Enum.map(diagnostics, & &1.code)

  defp disposition_tuple(options \\ []) do
    reference_role = Keyword.get(options, :reference_role)
    location = Keyword.get(options, :target_location, :inside)
    target_id = if location == :outside, do: @outside_id, else: @disposition_target_id
    disposition_target_id = Keyword.get(options, :disposition_target_id, target_id)

    target = %DesignNode{
      node_id: @disposition_target_id,
      semantic_type: Keyword.get(options, :target_semantic_type, "unsupported"),
      source_trace:
        Keyword.get(options, :target_source_trace, %SourceTrace{
          source_type: @disposition_source_type,
          source_id: @disposition_source_id
        }),
      children: Keyword.get(options, :target_children, []),
      interaction_refs:
        if(reference_role == :ir_interaction_ref, do: ["task5-interaction"], else: [])
    }

    boundary_prefix = [
      %DesignNode{
        node_id: @heading_id,
        semantic_type: "heading",
        attributes: %{"tag" => "h2"}
      },
      %DesignNode{node_id: @image_id, semantic_type: "paragraph"},
      %DesignNode{
        node_id: @actions_id,
        semantic_type: "actions",
        children: [
          %DesignNode{
            node_id: DesignNode.deterministic_id([1, 3, 1]),
            semantic_type: "button"
          }
        ]
      }
    ]

    boundary_children =
      if location == :inside, do: boundary_prefix ++ [target], else: boundary_prefix

    second_target = %DesignNode{
      node_id:
        if(location == :inside, do: @second_disposition_target_id, else: @disposition_target_id),
      semantic_type: "unknown",
      source_trace: %SourceTrace{
        source_type: @disposition_source_type,
        source_id: "synthetic-node-43"
      }
    }

    outside_node =
      if location == :outside do
        %DesignNode{
          node_id: @outside_id,
          semantic_type: "unsupported",
          source_trace: %SourceTrace{
            source_type: @disposition_source_type,
            source_id: @disposition_source_id
          }
        }
      else
        %DesignNode{node_id: @outside_id, semantic_type: "paragraph"}
      end

    boundary_children =
      if Keyword.get(options, :second_target, false),
        do: boundary_children ++ [second_target],
        else: boundary_children

    boundary = %DesignNode{
      node_id: @boundary_id,
      semantic_type: "section",
      children: boundary_children
    }

    interactions =
      if reference_role in [:ir_interaction_ref, :ir_interaction_target] do
        %{
          "task5-interaction" => %Interaction{
            interaction_id: "task5-interaction",
            intent: "activate",
            target_node_ids: [@disposition_target_id]
          }
        }
      else
        %{}
      end

    design_document = %DesignDocument{
      root_nodes: [boundary, outside_node],
      interactions: interactions
    }

    binding = behavior_binding(reference_role, @disposition_target_id)
    {:ok, identity} = Identity.from_document(design_document)

    {:ok, behavior_contract} =
      BindingIdentity.assign(%BehaviorContract{
        design_document_identity: identity,
        bindings: [binding]
      })

    {:ok, behavior_digest} = BehaviorSerializer.digest(behavior_contract)
    behavior_binding = hd(behavior_contract.bindings)
    review = approved_review(identity, behavior_digest)
    {:ok, review_id} = ReviewResult.id(review)

    disposition = %NodeDisposition{
      design_node_id: disposition_target_id,
      disposition: :exclude_source_runtime_carrier,
      source_type: @disposition_source_type,
      source_id: @disposition_source_id,
      behavior_binding_id: behavior_binding.binding_id,
      behavior_contract_digest: behavior_digest,
      behavior_review_id: review_id,
      evidence_refs: ["synthetic-evidence-1"]
    }

    disposition =
      struct!(disposition, Keyword.get(options, :disposition_overrides, []))

    dispositions =
      if Keyword.get(options, :duplicate_disposition, false),
        do: [disposition, disposition],
        else: [disposition]

    diagnostics =
      Keyword.get(options, :stored_diagnostics, [
        %Diagnostic{
          code: "componentization_plan.unsupported_node",
          severity: :error,
          message: "candidate-stage unsupported node blocker"
        },
        %Diagnostic{
          code: "componentization_plan.node_disposition.behavior_authority_mismatch",
          severity: :error,
          message: "candidate-stage authority blocker"
        }
      ])

    component_contract = contract()

    plan =
      plan(component_contract, design_document,
        node_dispositions: dispositions,
        diagnostics: diagnostics
      )

    review = Keyword.get(options, :selected_review, review)
    behavior_contract = Keyword.get(options, :behavior_contract, behavior_contract)

    {plan, component_contract, design_document, behavior_contract, review, behavior_binding}
  end

  defp behavior_binding(reference_role, target_id) do
    %BehaviorBinding{
      primitive_ref: %PrimitiveRef{kind: "synthetic-task5", definition_version: "1.0.0"},
      owner_node_id: if(reference_role == :binding_owner, do: target_id, else: @boundary_id),
      binding_role: "task5-reference-validation",
      controlled_targets:
        if(reference_role == :controlled_target,
          do: [%ControlledTarget{role: "controlled", node_id: target_id}],
          else: []
        ),
      triggers:
        if(reference_role == :trigger_origin,
          do: [%Trigger{kind: "activate", origin_node_id: target_id}],
          else: []
        ),
      focus_policy:
        if(reference_role == :focus_reference,
          do: %FocusPolicy{initial_target_node_id: target_id},
          else: nil
        )
    }
  end

  defp approved_review(identity, behavior_digest) do
    %ReviewResult{
      review_format_version: "1.0.0",
      design_document_identity: identity,
      behavior_contract_digest_algorithm: BehaviorSerializer.algorithm(),
      behavior_contract_digest: behavior_digest,
      decision: "approved",
      reviewer_identity: "reviewer:synthetic-task5",
      reviewed_at: "2026-10-18T00:00:00.000000Z",
      review_note: nil,
      evidence_refs: ["synthetic-review-evidence"]
    }
  end

  defp authority_result(
         {plan, component_contract, document, behavior_contract, review, _binding},
         api \\ :validate_references_with_behavior_authority
       ) do
    apply(ComponentizationPlan, api, [
      plan,
      component_contract,
      document,
      behavior_contract,
      review
    ])
  end

  defp disposition_codes(result), do: codes(result)

  test "exact disposition and Behavior authority pass all three authority-aware APIs" do
    tuple = disposition_tuple()

    assert authority_result(tuple) == :ok

    assert authority_result(
             tuple,
             :validate_generation_prerequisites_with_behavior_authority
           ) == :ok

    assert authority_result(tuple, :validate_for_generation_with_behavior_authority) == :ok
  end

  test "ordinary reference validation fails closed without Behavior authority" do
    {plan, component_contract, document, _behavior_contract, _review, _binding} =
      disposition_tuple()

    result = ComponentizationPlan.validate_references(plan, component_contract, document)
    result_codes = codes(result)

    assert "componentization_plan.node_disposition.behavior_authority_mismatch" in result_codes
    assert "componentization_plan.unsupported_node" in result_codes

    generation_result =
      ComponentizationPlan.validate_generation_prerequisites(
        plan,
        component_contract,
        document
      )

    assert "componentization_plan.node_disposition.behavior_authority_mismatch" in codes(
             generation_result
           )

    assert "componentization_plan.unsupported_node" in codes(generation_result)

    for_generation_result =
      ComponentizationPlan.validate_for_generation(plan, component_contract, document)

    assert "componentization_plan.node_disposition.behavior_authority_mismatch" in codes(
             for_generation_result
           )

    assert "componentization_plan.unsupported_node" in codes(for_generation_result)
  end

  test "authority-aware generation validation recomputes disposition blockers" do
    tuple = disposition_tuple()

    assert authority_result(
             tuple,
             :validate_generation_prerequisites_with_behavior_authority
           ) == :ok

    {plan, component_contract, document, behavior_contract, review, _binding} = tuple

    unrelated = %Diagnostic{
      code: "componentization_plan.accessibility.review_required",
      severity: :error,
      message: "independent stored blocker"
    }

    plan = %{
      plan
      | diagnostics: [
          unrelated,
          %Diagnostic{
            code: "componentization_plan.unsupported_node",
            severity: :error,
            message: "stale candidate blocker"
          },
          %Diagnostic{
            code: "componentization_plan.node_disposition.behavior_authority_mismatch",
            severity: :error,
            message: "stale candidate authority blocker"
          }
        ]
    }

    result =
      apply(ComponentizationPlan, :validate_generation_prerequisites_with_behavior_authority, [
        plan,
        component_contract,
        document,
        behavior_contract,
        review
      ])

    assert "componentization_plan.accessibility.review_required" in codes(result)
    refute "componentization_plan.unsupported_node" in codes(result)
    refute "componentization_plan.node_disposition.behavior_authority_mismatch" in codes(result)

    for_generation_result =
      apply(ComponentizationPlan, :validate_for_generation_with_behavior_authority, [
        plan,
        component_contract,
        document,
        behavior_contract,
        review
      ])

    assert "componentization_plan.generation_blocked" in codes(for_generation_result)
    assert "componentization_plan.accessibility.review_required" in codes(for_generation_result)
  end

  test "one valid disposition consumes only its exact target" do
    tuple = disposition_tuple(second_target: true)
    assert {:error, diagnostics} = authority_result(tuple)

    assert Enum.count(diagnostics, &(&1.code == "componentization_plan.unsupported_node")) == 1
    assert Enum.any?(diagnostics, &(&1.path == "nodes[#{@second_disposition_target_id}]"))
  end

  test "missing, outside, supported and non-leaf targets remain unconsumed" do
    cases = [
      {disposition_tuple(disposition_target_id: "missing-node"),
       "componentization_plan.node_disposition.target_missing",
       "componentization_plan.unsupported_node"},
      {disposition_tuple(target_location: :outside, second_target: true),
       "componentization_plan.node_disposition.target_outside_boundary",
       "componentization_plan.unsupported_node"},
      {disposition_tuple(target_semantic_type: "heading"),
       "componentization_plan.node_disposition.target_semantic_incompatible", nil},
      {disposition_tuple(
         target_semantic_type: "raw",
         target_children: [
           %DesignNode{
             node_id: DesignNode.deterministic_id([1, 4, 1]),
             semantic_type: "paragraph"
           }
         ]
       ), "componentization_plan.node_disposition.target_semantic_incompatible",
       "componentization_plan.unsupported_node"}
    ]

    for {tuple, expected, unsupported_code} <- cases do
      result_codes = disposition_codes(authority_result(tuple))
      assert expected in result_codes

      if unsupported_code do
        assert unsupported_code in result_codes
      end
    end
  end

  test "missing and changed SourceTrace identity never consume the target" do
    cases = [
      disposition_tuple(target_source_trace: nil),
      disposition_tuple(
        target_source_trace: %SourceTrace{
          source_type: "changed-builder",
          source_id: @disposition_source_id
        }
      ),
      disposition_tuple(
        target_source_trace: %SourceTrace{
          source_type: @disposition_source_type,
          source_id: "changed-node"
        }
      )
    ]

    for tuple <- cases do
      result_codes = disposition_codes(authority_result(tuple))
      assert "componentization_plan.node_disposition.source_identity_mismatch" in result_codes
      assert "componentization_plan.unsupported_node" in result_codes
    end
  end

  test "digest, review identity, changed review and approval status are revalidated" do
    wrong_digest =
      disposition_tuple(
        disposition_overrides: [behavior_contract_digest: String.duplicate("f", 64)]
      )

    wrong_review_id =
      disposition_tuple(
        disposition_overrides: [behavior_review_id: "brv_" <> String.duplicate("0", 64)]
      )

    changed_review = disposition_tuple()

    changed_review =
      put_elem(changed_review, 4, %{elem(changed_review, 4) | review_note: "changed"})

    unapproved_review = disposition_tuple()

    unapproved_review =
      put_elem(unapproved_review, 4, %{elem(unapproved_review, 4) | decision: "needs_review"})

    for tuple <- [wrong_digest, wrong_review_id, changed_review, unapproved_review] do
      result_codes = disposition_codes(authority_result(tuple))
      assert "componentization_plan.node_disposition.behavior_authority_mismatch" in result_codes
      assert "componentization_plan.unsupported_node" in result_codes
    end
  end

  test "BehaviorContract bound to another DesignDocument fails exact authority validation" do
    tuple = disposition_tuple()
    {plan, component_contract, document, _behavior_contract, _review, _binding} = tuple

    other_document = %{document | source_metadata: %{"variant" => "other"}}
    {:ok, other_identity} = Identity.from_document(other_document)
    {:ok, original_contract_digest} = BehaviorSerializer.digest(elem(tuple, 3))
    binding = behavior_binding(nil, @boundary_id)

    {:ok, original_contract} =
      BindingIdentity.assign(%BehaviorContract{
        design_document_identity: other_identity,
        bindings: [binding]
      })

    {:ok, digest} = BehaviorSerializer.digest(original_contract)
    review = approved_review(other_identity, digest)
    {:ok, review_id} = ReviewResult.id(review)
    [disposition] = plan.node_dispositions

    plan = %{
      plan
      | node_dispositions: [
          %{
            disposition
            | behavior_binding_id: hd(original_contract.bindings).binding_id,
              behavior_contract_digest: digest,
              behavior_review_id: review_id
          }
        ]
    }

    refute original_contract_digest == digest

    result =
      apply(ComponentizationPlan, :validate_references_with_behavior_authority, [
        plan,
        component_contract,
        document,
        original_contract,
        review
      ])

    assert "componentization_plan.node_disposition.behavior_authority_mismatch" in codes(result)
    assert "componentization_plan.unsupported_node" in codes(result)
  end

  test "binding selector must resolve exactly once" do
    missing_binding =
      disposition_tuple(disposition_overrides: [behavior_binding_id: "missing-binding"])

    assert "componentization_plan.node_disposition.behavior_binding_mismatch" in disposition_codes(
             authority_result(missing_binding)
           )

    duplicate_authority = disposition_tuple()

    {plan, component_contract, document, behavior_contract, review, _binding} =
      duplicate_authority

    [binding] = behavior_contract.bindings
    duplicate_contract = %{behavior_contract | bindings: [binding, binding]}

    result =
      apply(ComponentizationPlan, :validate_references_with_behavior_authority, [
        plan,
        component_contract,
        document,
        duplicate_contract,
        review
      ])

    assert "componentization_plan.node_disposition.behavior_binding_mismatch" in codes(result)
    assert "componentization_plan.unsupported_node" in codes(result)
  end

  test "all six frozen Behavior and IR reference roles block disposition consumption" do
    roles = [
      :binding_owner,
      :controlled_target,
      :trigger_origin,
      :focus_reference,
      :ir_interaction_ref,
      :ir_interaction_target
    ]

    for role <- roles do
      tuple = disposition_tuple(reference_role: role)
      result_codes = disposition_codes(authority_result(tuple))

      assert "componentization_plan.node_disposition.behavior_reference_conflict" in result_codes
      assert "componentization_plan.unsupported_node" in result_codes
    end
  end

  test "duplicate, unsupported and malformed dispositions preserve intrinsic diagnostics and blockers" do
    duplicate = disposition_tuple(duplicate_disposition: true)

    result_codes = disposition_codes(authority_result(duplicate))

    assert Enum.any?(
             result_codes,
             &String.starts_with?(&1, "componentization_plan.node_disposition.")
           )

    assert "componentization_plan.node_disposition.duplicate" in result_codes
    assert "componentization_plan.unsupported_node" in result_codes

    unsupported = disposition_tuple(disposition_overrides: [disposition: :omit_runtime])
    result_codes = disposition_codes(authority_result(unsupported))
    assert "componentization_plan.node_disposition.outcome_unsupported" in result_codes
    assert "componentization_plan.unsupported_node" in result_codes

    malformed = disposition_tuple()
    {plan, component_contract, document, behavior_contract, review, _binding} = malformed
    [disposition] = plan.node_dispositions
    plan = %{plan | node_dispositions: [Map.put(disposition, :extra_field, "invalid")]}

    result =
      apply(ComponentizationPlan, :validate_references_with_behavior_authority, [
        plan,
        component_contract,
        document,
        behavior_contract,
        review
      ])

    assert "componentization_plan.node_disposition.invalid" in codes(result)
    assert "componentization_plan.unsupported_node" in codes(result)
  end

  test "list-wide disposition ordering failure leaves every unsupported target unconsumed" do
    tuple = disposition_tuple(second_target: true)
    {plan, component_contract, document, behavior_contract, review, _binding} = tuple
    [first] = plan.node_dispositions

    second = %{
      first
      | design_node_id: @second_disposition_target_id,
        source_id: "synthetic-node-43"
    }

    plan = %{plan | node_dispositions: [second, first]}

    result =
      apply(ComponentizationPlan, :validate_references_with_behavior_authority, [
        plan,
        component_contract,
        document,
        behavior_contract,
        review
      ])

    result_codes = codes(result)
    assert Enum.any?(result_codes, &String.ends_with?(&1, ".design_node_id.order_invalid"))
    assert Enum.count(result_codes, &(&1 == "componentization_plan.unsupported_node")) == 2
  end

  test "empty-disposition authority entry point preserves ordinary and historical behavior" do
    design_document = document()
    component_contract = contract()
    ordinary_plan = plan(component_contract, design_document)

    ordinary =
      ComponentizationPlan.validate_references(
        ordinary_plan,
        component_contract,
        design_document
      )

    assert apply(ComponentizationPlan, :validate_references_with_behavior_authority, [
             ordinary_plan,
             component_contract,
             design_document,
             nil,
             nil
           ]) == ordinary

    ordinary_prerequisites =
      ComponentizationPlan.validate_generation_prerequisites(
        ordinary_plan,
        component_contract,
        design_document
      )

    assert apply(
             ComponentizationPlan,
             :validate_generation_prerequisites_with_behavior_authority,
             [ordinary_plan, component_contract, design_document, nil, nil]
           ) == ordinary_prerequisites

    ordinary_generation =
      ComponentizationPlan.validate_for_generation(
        ordinary_plan,
        component_contract,
        design_document
      )

    assert apply(ComponentizationPlan, :validate_for_generation_with_behavior_authority, [
             ordinary_plan,
             component_contract,
             design_document,
             nil,
             nil
           ]) == ordinary_generation

    historical_plan = %{ordinary_plan | plan_format_version: "1.0.0"}

    assert ComponentizationPlan.validate_references(
             historical_plan,
             component_contract,
             design_document
           ) == :ok
  end

  test "fingerprint hashes canonical bytes and distinguishes documents with colliding node ids" do
    first = document()
    [boundary | rest] = first.root_nodes
    second = %{first | root_nodes: [%{boundary | label: "different content"} | rest]}

    assert {:ok, first_hash} = ComponentizationPlan.design_document_sha256(first)
    assert {:ok, ^first_hash} = ComponentizationPlan.design_document_sha256(first)
    expected = :crypto.hash(:sha256, IR.encode!(first)) |> Base.encode16(case: :lower)
    assert {:ok, second_hash} = ComponentizationPlan.design_document_sha256(second)
    assert first_hash =~ ~r/^[0-9a-f]{64}$/
    assert first_hash == expected
    refute first_hash == second_hash

    plan = plan(contract(), first)

    assert "componentization_plan.design_document.mismatch" in codes(
             ComponentizationPlan.validate_references(plan, contract(), second)
           )
  end

  test "accepts a structurally valid empty plan and contract" do
    design_document = document()
    component_contract = contract()

    assert ComponentizationPlan.validate_references(
             plan(component_contract, design_document),
             component_contract,
             design_document
           ) == :ok
  end

  test "validates unbound top-level attr placement against role type and node matrices" do
    design_document = document()

    component_contract =
      contract(public_attrs: [attr("title")])

    good_plan =
      plan(component_contract, design_document,
        render_projections: [render_attr("title", :text_content)]
      )

    assert ComponentizationPlan.validate_references(
             good_plan,
             component_contract,
             design_document
           ) == :ok

    wrong_type = contract(public_attrs: [attr("title", :integer)])

    wrong_type_plan =
      plan(wrong_type, design_document, render_projections: [render_attr("title", :text_content)])

    assert "componentization_plan.render_projection.role_type_mismatch" in codes(
             ComponentizationPlan.validate_references(
               wrong_type_plan,
               wrong_type,
               design_document
             )
           )

    wrong_node_plan =
      plan(component_contract, design_document,
        render_projections: [render_attr("title", :text_content, @actions_id)]
      )

    assert "componentization_plan.render_projection.role_node_mismatch" in codes(
             ComponentizationPlan.validate_references(
               wrong_node_plan,
               component_contract,
               design_document
             )
           )
  end

  test "accepts each closed render role with its authorized attr, slot and node type" do
    design_document = role_document()
    link_id = DesignNode.deterministic_id([1, 4])
    link_slot_id = DesignNode.deterministic_id([1, 5])

    component_contract =
      contract(
        public_attrs: [
          attr("title"),
          attr("level", :integer, validation: %{"values" => [1, 2, 3, 4, 5, 6]}),
          attr("href"),
          attr("id"),
          attr("class"),
          attr("rest", :global)
        ],
        public_slots: [
          %Slot{name: "actions", semantic_purpose: "actions", consumer_responsibility: "caller"},
          %Slot{
            name: "link_actions",
            semantic_purpose: "actions",
            consumer_responsibility: "caller"
          }
        ]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [
          render_attr("title", :text_content),
          render_attr("level", :heading_level),
          render_attr("href", :link_url, link_id),
          render_attr("id", :root_id, @boundary_id),
          render_attr("class", :root_class, @boundary_id),
          render_attr("rest", :root_global_attrs, @boundary_id),
          %RenderProjection{
            public_slot_name: "actions",
            target_node_id: @actions_id,
            render_role: :subtree_slot
          },
          %RenderProjection{
            public_slot_name: "link_actions",
            target_node_id: link_slot_id,
            render_role: :subtree_slot
          }
        ]
      )

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok

    wrong_root = contract(public_attrs: [attr("id")])

    wrong_root_plan =
      plan(wrong_root, design_document, render_projections: [render_attr("id", :root_id)])

    assert "componentization_plan.render_projection.role_node_mismatch" in codes(
             ComponentizationPlan.validate_references(
               wrong_root_plan,
               wrong_root,
               design_document
             )
           )
  end

  test "allows semantic render roles on a heading boundary" do
    design_document = semantic_boundary_document("heading")

    text_contract = contract(public_attrs: [attr("title")])

    text_plan =
      plan(text_contract, design_document,
        render_projections: [render_attr("title", :text_content, @boundary_id)]
      )

    assert ComponentizationPlan.validate_references(text_plan, text_contract, design_document) ==
             :ok

    component_contract =
      contract(
        public_attrs: [
          attr("title"),
          attr("level", :integer, validation: %{"values" => [1, 2, 3, 4, 5, 6]})
        ]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [
          render_attr("title", :text_content, @boundary_id),
          render_attr("level", :heading_level, @boundary_id)
        ]
      )

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok

    root_contract = contract(public_attrs: [attr("id"), attr("class")])

    root_plan =
      plan(root_contract, design_document,
        render_projections: [
          render_attr("id", :root_id, @boundary_id),
          render_attr("class", :root_class, @boundary_id)
        ]
      )

    assert ComponentizationPlan.validate_references(root_plan, root_contract, design_document) ==
             :ok
  end

  test "allows accessible image source and alt roles on an image boundary" do
    design_document = semantic_boundary_document("image")

    decorative_contract =
      contract(
        public_attrs: [
          attr("src", :string, accessibility: %{"image_alt_policy" => "decorative"})
        ]
      )

    decorative_plan =
      plan(decorative_contract, design_document,
        render_projections: [render_attr("src", :asset_src, @boundary_id)]
      )

    assert ComponentizationPlan.validate_references(
             decorative_plan,
             decorative_contract,
             design_document
           ) == :ok

    consumer_contract =
      contract(
        public_attrs: [
          attr("src", :string,
            accessibility: %{
              "image_alt_policy" => "consumer_supplied",
              "alt_attr_name" => "alt",
              "required_when_source_present" => true
            }
          ),
          attr("alt")
        ]
      )

    consumer_plan =
      plan(consumer_contract, design_document,
        render_projections: [
          render_attr("src", :asset_src, @boundary_id),
          render_attr("alt", :asset_alt, @boundary_id)
        ]
      )

    assert ComponentizationPlan.validate_references(
             consumer_plan,
             consumer_contract,
             design_document
           ) == :ok
  end

  test "allows link_url on a link boundary" do
    design_document = semantic_boundary_document("link")
    component_contract = contract(public_attrs: [attr("href")])

    component_plan =
      plan(component_contract, design_document,
        render_projections: [render_attr("href", :link_url, @boundary_id)]
      )

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok
  end

  test "allows subtree_slot on an actions boundary without bindings" do
    design_document = semantic_boundary_document("actions")

    component_contract =
      contract(
        public_slots: [
          %Slot{name: "actions", semantic_purpose: "actions", consumer_responsibility: "caller"}
        ]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [
          %RenderProjection{
            public_slot_name: "actions",
            target_node_id: @boundary_id,
            render_role: :subtree_slot
          }
        ]
      )

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok
  end

  test "allows a rich_text node to be replaced by a subtree slot" do
    rich_text_id = DesignNode.deterministic_id([1, 1])

    design_document = %DesignDocument{
      root_nodes: [
        %DesignNode{
          node_id: @boundary_id,
          semantic_type: "section",
          children: [
            %DesignNode{
              node_id: rich_text_id,
              semantic_type: "rich_text",
              content: "Static rich text"
            }
          ]
        }
      ]
    }

    assert :ok = IR.validate(design_document)
    assert {:ok, _fingerprint} = ComponentizationPlan.design_document_sha256(design_document)

    component_contract =
      contract(
        public_slots: [
          %Slot{
            name: "body",
            semantic_purpose: "body",
            consumer_responsibility: "caller"
          }
        ]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [
          %RenderProjection{
            public_slot_name: "body",
            target_node_id: rich_text_id,
            render_role: :subtree_slot
          }
        ]
      )

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok

    assert ComponentizationPlan.validate_generation_prerequisites(
             component_plan,
             component_contract,
             design_document
           ) == :ok
  end

  test "rejects a paragraph node as a subtree slot" do
    paragraph_id = DesignNode.deterministic_id([1, 1])

    design_document = %DesignDocument{
      root_nodes: [
        %DesignNode{
          node_id: @boundary_id,
          semantic_type: "section",
          children: [%DesignNode{node_id: paragraph_id, semantic_type: "paragraph"}]
        }
      ]
    }

    assert :ok = IR.validate(design_document)
    assert {:ok, _fingerprint} = ComponentizationPlan.design_document_sha256(design_document)

    component_contract =
      contract(
        public_slots: [
          %Slot{
            name: "body",
            semantic_purpose: "body",
            consumer_responsibility: "caller"
          }
        ]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [
          %RenderProjection{
            public_slot_name: "body",
            target_node_id: paragraph_id,
            render_role: :subtree_slot
          }
        ]
      )

    assert "componentization_plan.render_projection.role_node_mismatch" in codes(
             ComponentizationPlan.validate_references(
               component_plan,
               component_contract,
               design_document
             )
           )
  end

  test "rejects mixed root and semantic render roles on a boundary" do
    heading_document = semantic_boundary_document("heading")
    heading_contract = contract(public_attrs: [attr("id"), attr("title")])

    heading_plan =
      plan(heading_contract, heading_document,
        render_projections: [
          render_attr("id", :root_id, @boundary_id),
          render_attr("title", :text_content, @boundary_id)
        ]
      )

    image_document = semantic_boundary_document("image")

    image_contract =
      contract(
        public_attrs: [
          attr("class"),
          attr("src", :string, accessibility: %{"image_alt_policy" => "decorative"})
        ]
      )

    image_plan =
      plan(image_contract, image_document,
        render_projections: [
          render_attr("class", :root_class, @boundary_id),
          render_attr("src", :asset_src, @boundary_id)
        ]
      )

    link_document = semantic_boundary_document("link")
    link_contract = contract(public_attrs: [attr("rest", :global), attr("href")])

    link_plan =
      plan(link_contract, link_document,
        render_projections: [
          render_attr("rest", :root_global_attrs, @boundary_id),
          render_attr("href", :link_url, @boundary_id)
        ]
      )

    for {component_plan, component_contract, design_document} <- [
          {heading_plan, heading_contract, heading_document},
          {image_plan, image_contract, image_document},
          {link_plan, link_contract, link_document}
        ] do
      assert "componentization_plan.render_projection.role_conflict" in codes(
               ComponentizationPlan.validate_references(
                 component_plan,
                 component_contract,
                 design_document
               )
             )
    end
  end

  test "rejects unsupported render role co-location" do
    design_document = document()
    component_contract = contract(public_attrs: [attr("title"), attr("label")])

    component_plan =
      plan(component_contract, design_document,
        render_projections: [
          render_attr("title", :text_content),
          render_attr("label", :text_content)
        ]
      )

    assert "componentization_plan.render_projection.role_conflict" in codes(
             ComponentizationPlan.validate_references(
               component_plan,
               component_contract,
               design_document
             )
           )
  end

  test "a link subtree slot excludes link_url projection on the same node" do
    design_document = role_document()
    link_id = DesignNode.deterministic_id([1, 4])

    component_contract =
      contract(
        public_attrs: [attr("href")],
        public_slots: [
          %Slot{
            name: "link_actions",
            semantic_purpose: "actions",
            consumer_responsibility: "caller"
          }
        ]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [
          render_attr("href", :link_url, link_id),
          %RenderProjection{
            public_slot_name: "link_actions",
            target_node_id: link_id,
            render_role: :subtree_slot
          }
        ]
      )

    assert "componentization_plan.slot.subtree_conflict" in codes(
             ComponentizationPlan.validate_references(
               component_plan,
               component_contract,
               design_document
             )
           )
  end

  test "requires exactly one placement for every top-level public attr and slot" do
    design_document = document()

    component_contract =
      contract(
        public_attrs: [attr("title")],
        public_slots: [
          %Slot{name: "actions", semantic_purpose: "actions", consumer_responsibility: "caller"}
        ]
      )

    missing_plan = plan(component_contract, design_document)

    assert "componentization_plan.public_input.placement_missing" in codes(
             ComponentizationPlan.validate_references(
               missing_plan,
               component_contract,
               design_document
             )
           )

    placed_plan =
      plan(component_contract, design_document,
        render_projections: [
          render_attr("title", :text_content),
          %RenderProjection{
            public_slot_name: "actions",
            target_node_id: @actions_id,
            render_role: :subtree_slot
          }
        ]
      )

    assert ComponentizationPlan.validate_references(
             placed_plan,
             component_contract,
             design_document
           ) == :ok
  end

  test "rejects a public input with both binding and render placement" do
    design_document = %{
      document()
      | value_bindings: %{"vb_title" => value_binding("vb_title", @heading_id)}
    }

    component_contract =
      contract(
        public_attrs: [attr("title")],
        binding_projections: [binding_projection("vb_title", "title")]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [render_attr("title", :text_content)]
      )

    assert "componentization_plan.public_input.placement_conflict" in codes(
             ComponentizationPlan.validate_references(
               component_plan,
               component_contract,
               design_document
             )
           )
  end

  test "requires complete in-boundary value binding coverage" do
    design_document = %{
      document()
      | value_bindings: %{"vb_title" => value_binding("vb_title", @heading_id)}
    }

    component_contract = contract()

    assert "componentization_plan.binding.uncovered" in codes(
             ComponentizationPlan.validate_references(
               plan(component_contract, design_document),
               component_contract,
               design_document
             )
           )
  end

  test "accepts one value projection and rejects duplicate binding projections" do
    design_document = %{
      document()
      | value_bindings: %{"vb_title" => value_binding("vb_title", @heading_id)}
    }

    projection = binding_projection("vb_title", "title")

    component_contract =
      contract(public_attrs: [attr("title")], binding_projections: [projection])

    assert ComponentizationPlan.validate_references(
             plan(component_contract, design_document),
             component_contract,
             design_document
           ) == :ok

    duplicate_contract = %{
      component_contract
      | binding_projections: [projection, projection]
    }

    diagnostic_codes =
      ComponentizationPlan.validate_references(
        plan(duplicate_contract, design_document),
        duplicate_contract,
        design_document
      )
      |> codes()

    assert "componentization_plan.binding.duplicate" in diagnostic_codes
    assert "componentization_plan.public_input.placement_conflict" in diagnostic_codes
  end

  test "rejects bindings whose targets fall outside the selected boundary" do
    design_document = %{
      document()
      | value_bindings: %{"vb_title" => value_binding("vb_title", @outside_id)}
    }

    component_contract =
      contract(
        public_attrs: [attr("title")],
        binding_projections: [binding_projection("vb_title", "title", @outside_id)]
      )

    assert "componentization_plan.render_projection.target_outside_boundary" in codes(
             ComponentizationPlan.validate_references(
               plan(component_contract, design_document),
               component_contract,
               design_document
             )
           )
  end

  test "rejects collection bindings that cross the selected boundary" do
    design_document = %{
      document()
      | collection_bindings: %{
          "cb_root" => %CollectionBinding{
            collection_binding_id: "cb_root",
            owner_node_id: @boundary_id,
            repeat_root_node_id: @outside_id
          }
        }
    }

    component_contract = contract()

    assert "componentization_plan.boundary.binding_crosses" in codes(
             ComponentizationPlan.validate_references(
               plan(component_contract, design_document),
               component_contract,
               design_document
             )
           )
  end

  test "covers in-boundary collection bindings and ignores wholly external ones" do
    collection_binding = %CollectionBinding{
      collection_binding_id: "cb_items",
      owner_node_id: @boundary_id,
      repeat_root_node_id: @image_id
    }

    design_document = %{
      document()
      | collection_bindings: %{"cb_items" => collection_binding}
    }

    input = %CollectionInput{
      source_collection_binding_id: "cb_items",
      public_attr_name: "items"
    }

    projection = %BindingProjection{
      source_binding_kind: :collection,
      source_binding_id: "cb_items",
      projection_kind: :collection_attr,
      public_attr_name: "items",
      source_collection_binding_id: "cb_items",
      target_node_id: @image_id
    }

    component_contract =
      contract(
        public_attrs: [attr("items", :list)],
        collection_inputs: [input],
        binding_projections: [projection]
      )

    assert ComponentizationPlan.validate_references(
             plan(component_contract, design_document),
             component_contract,
             design_document
           ) == :ok

    uncovered_contract = %{component_contract | binding_projections: []}

    assert "componentization_plan.binding.uncovered" in codes(
             ComponentizationPlan.validate_references(
               plan(uncovered_contract, design_document),
               uncovered_contract,
               design_document
             )
           )

    external_binding = %{
      collection_binding
      | owner_node_id: @outside_id,
        repeat_root_node_id: @outside_id
    }

    external_document = %{
      document()
      | collection_bindings: %{
          "cb_external" => %{external_binding | collection_binding_id: "cb_external"}
        }
    }

    assert ComponentizationPlan.validate_references(
             plan(contract(), external_document),
             contract(),
             external_document
           ) == :ok
  end

  test "reports both collection boundary crossing directions and missing targets" do
    crossing = %CollectionBinding{
      collection_binding_id: "cb_crossing",
      owner_node_id: @outside_id,
      repeat_root_node_id: @heading_id
    }

    design_document = %{
      document()
      | collection_bindings: %{"cb_crossing" => crossing}
    }

    assert "componentization_plan.boundary.binding_crosses" in codes(
             ComponentizationPlan.validate_references(
               plan(contract(), design_document),
               contract(),
               design_document
             )
           )

    component_contract = contract(public_attrs: [attr("title")])

    missing_target_plan =
      plan(component_contract, document(),
        render_projections: [render_attr("title", :text_content, "node_missing")]
      )

    assert "componentization_plan.render_projection.target_missing" in codes(
             ComponentizationPlan.validate_references(
               missing_target_plan,
               component_contract,
               document()
             )
           )

    missing_boundary_plan = plan(contract(), document(), boundary_node_id: "node_missing")

    assert "componentization_plan.boundary.missing" in codes(
             ComponentizationPlan.validate_references(
               missing_boundary_plan,
               contract(),
               document()
             )
           )
  end

  test "blocks unsupported nodes and static internal images" do
    for semantic_type <- ["raw", "unsupported", "unknown"] do
      base = document()
      [boundary, outside] = base.root_nodes
      [heading | rest] = boundary.children

      unsupported_document = %{
        base
        | root_nodes: [
            %{boundary | children: [%{heading | semantic_type: semantic_type} | rest]},
            outside
          ]
      }

      assert "componentization_plan.unsupported_node" in codes(
               ComponentizationPlan.validate_references(
                 plan(contract(), unsupported_document),
                 contract(),
                 unsupported_document
               )
             )
    end

    base = document()
    [boundary, outside] = base.root_nodes
    external_document = %{base | root_nodes: [boundary, %{outside | semantic_type: "raw"}]}

    assert ComponentizationPlan.validate_references(
             plan(contract(), external_document),
             contract(),
             external_document
           ) == :ok

    assert "componentization_plan.accessibility.static_image_unsupported" in codes(
             ComponentizationPlan.validate_references(
               plan(contract(), image_document()),
               contract(),
               image_document()
             )
           )
  end

  test "a subtree slot owns and replaces a static image in its subtree" do
    base = document()
    [boundary, outside] = base.root_nodes
    [heading, paragraph, actions] = boundary.children
    child_image = %{hd(actions.children) | semantic_type: "image"}

    design_document = %{
      base
      | root_nodes: [
          %{boundary | children: [heading, paragraph, %{actions | children: [child_image]}]},
          outside
        ]
    }

    component_contract =
      contract(
        public_slots: [
          %Slot{name: "actions", semantic_purpose: "actions", consumer_responsibility: "caller"}
        ]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [
          %RenderProjection{
            public_slot_name: "actions",
            target_node_id: @actions_id,
            render_role: :subtree_slot
          }
        ]
      )

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok
  end

  test "validates top-level consumer-supplied and decorative image accessibility" do
    design_document = image_document()

    accessibility = %{
      "image_alt_policy" => "consumer_supplied",
      "alt_attr_name" => "alt",
      "required_when_source_present" => true
    }

    component_contract =
      contract(public_attrs: [attr("image", :string, accessibility: accessibility), attr("alt")])

    component_plan =
      plan(component_contract, design_document,
        render_projections: [
          render_attr("image", :asset_src, @image_id),
          render_attr("alt", :asset_alt, @image_id)
        ]
      )

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok

    decorative_contract =
      contract(
        public_attrs: [
          attr("image", :string, accessibility: %{"image_alt_policy" => "decorative"})
        ]
      )

    decorative_plan =
      plan(decorative_contract, design_document,
        render_projections: [render_attr("image", :asset_src, @image_id)]
      )

    assert ComponentizationPlan.validate_references(
             decorative_plan,
             decorative_contract,
             design_document
           ) == :ok
  end

  test "consumer-supplied image accessibility requires exactly one matching asset_alt projection" do
    design_document = image_document()

    source_accessibility = %{
      "image_alt_policy" => "consumer_supplied",
      "alt_attr_name" => "alt",
      "required_when_source_present" => true
    }

    component_contract =
      contract(
        public_attrs: [attr("image", :string, accessibility: source_accessibility), attr("alt")]
      )

    matching_plan =
      plan(component_contract, design_document,
        render_projections: [
          render_attr("image", :asset_src, @image_id),
          render_attr("alt", :asset_alt, @image_id)
        ]
      )

    assert ComponentizationPlan.validate_references(
             matching_plan,
             component_contract,
             design_document
           ) == :ok

    missing_alt_plan = %{
      matching_plan
      | render_projections: [render_attr("image", :asset_src, @image_id)]
    }

    assert "componentization_plan.accessibility.alt_projection_mismatch" in codes(
             ComponentizationPlan.validate_references(
               missing_alt_plan,
               component_contract,
               design_document
             )
           )

    multiple_contract =
      contract(
        public_attrs: [
          attr("image", :string, accessibility: source_accessibility),
          attr("alt"),
          attr("other_alt")
        ]
      )

    multiple_alt_plan =
      plan(multiple_contract, design_document,
        render_projections: [
          render_attr("image", :asset_src, @image_id),
          render_attr("alt", :asset_alt, @image_id),
          render_attr("other_alt", :asset_alt, @image_id)
        ]
      )

    assert "componentization_plan.accessibility.alt_projection_mismatch" in codes(
             ComponentizationPlan.validate_references(
               multiple_alt_plan,
               multiple_contract,
               design_document
             )
           )
  end

  test "decorative image accessibility rejects any asset_alt projection" do
    design_document = image_document()
    accessibility = %{"image_alt_policy" => "decorative"}

    no_alt_contract =
      contract(public_attrs: [attr("image", :string, accessibility: accessibility)])

    no_alt_plan =
      plan(no_alt_contract, design_document,
        render_projections: [render_attr("image", :asset_src, @image_id)]
      )

    assert ComponentizationPlan.validate_references(no_alt_plan, no_alt_contract, design_document) ==
             :ok

    one_alt_contract =
      contract(
        public_attrs: [
          attr("image", :string, accessibility: accessibility),
          attr("alt")
        ]
      )

    one_alt_plan =
      plan(one_alt_contract, design_document,
        render_projections: [
          render_attr("image", :asset_src, @image_id),
          render_attr("alt", :asset_alt, @image_id)
        ]
      )

    assert "componentization_plan.accessibility.image_policy_invalid" in codes(
             ComponentizationPlan.validate_references(
               one_alt_plan,
               one_alt_contract,
               design_document
             )
           )

    multiple_alt_contract =
      contract(
        public_attrs: [
          attr("image", :string, accessibility: accessibility),
          attr("alt"),
          attr("other_alt")
        ]
      )

    multiple_alt_plan =
      plan(multiple_alt_contract, design_document,
        render_projections: [
          render_attr("image", :asset_src, @image_id),
          render_attr("alt", :asset_alt, @image_id),
          render_attr("other_alt", :asset_alt, @image_id)
        ]
      )

    assert "componentization_plan.accessibility.image_policy_invalid" in codes(
             ComponentizationPlan.validate_references(
               multiple_alt_plan,
               multiple_alt_contract,
               design_document
             )
           )
  end

  test "validates many image sources sharing one node without changing diagnostics" do
    design_document = image_document()
    source_names = Enum.map(1..64, &"image_#{&1}")

    component_contract =
      contract(
        public_attrs:
          Enum.map(source_names, fn name ->
            attr(name, :string, accessibility: %{"image_alt_policy" => "decorative"})
          end)
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: Enum.map(source_names, &render_attr(&1, :asset_src, @image_id))
      )

    assert "componentization_plan.render_projection.role_conflict" in codes(
             ComponentizationPlan.validate_references(
               component_plan,
               component_contract,
               design_document
             )
           )
  end

  test "checks accessibility when the top-level image source is binding-backed" do
    design_document = %{
      image_document()
      | value_bindings: %{
          "vb_image" => value_binding("vb_image", @image_id, target_kind: :asset, scope: :site)
        }
    }

    accessibility = %{
      "image_alt_policy" => "consumer_supplied",
      "alt_attr_name" => "alt",
      "required_when_source_present" => true
    }

    component_contract =
      contract(
        public_attrs: [attr("image", :string, accessibility: accessibility), attr("alt")],
        binding_projections: [binding_projection("vb_image", "image", @image_id)]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [render_attr("alt", :asset_alt, @image_id)]
      )

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok
  end

  test "rejects missing and contradictory top-level image accessibility policies" do
    design_document = image_document()

    missing_policy =
      contract(public_attrs: [attr("image")])

    missing_policy_plan =
      plan(missing_policy, design_document,
        render_projections: [render_attr("image", :asset_src, @image_id)]
      )

    assert "componentization_plan.accessibility.image_policy_missing" in codes(
             ComponentizationPlan.validate_references(
               missing_policy_plan,
               missing_policy,
               design_document
             )
           )

    invalid_policy = %{
      "image_alt_policy" => "consumer_supplied",
      "alt_attr_name" => "alt",
      "required_when_source_present" => false
    }

    invalid_contract =
      contract(public_attrs: [attr("image", :string, accessibility: invalid_policy), attr("alt")])

    invalid_plan =
      plan(invalid_contract, design_document,
        render_projections: [
          render_attr("image", :asset_src, @image_id),
          render_attr("alt", :asset_alt, @image_id)
        ]
      )

    assert "componentization_plan.accessibility.image_policy_invalid" in codes(
             ComponentizationPlan.validate_references(
               invalid_plan,
               invalid_contract,
               design_document
             )
           )

    decorative_contract =
      contract(
        public_attrs: [
          attr("image", :string,
            accessibility: %{"image_alt_policy" => "decorative", "alt_attr_name" => "alt"}
          ),
          attr("alt")
        ]
      )

    decorative_plan =
      plan(decorative_contract, design_document,
        render_projections: [
          render_attr("image", :asset_src, @image_id),
          render_attr("alt", :asset_alt, @image_id)
        ]
      )

    assert "componentization_plan.accessibility.image_policy_invalid" in codes(
             ComponentizationPlan.validate_references(
               decorative_plan,
               decorative_contract,
               design_document
             )
           )
  end

  test "validates collection-item image accessibility through sibling binding projections" do
    design_document = image_document()

    collection_binding = %CollectionBinding{
      collection_binding_id: "cb_members",
      owner_node_id: @boundary_id,
      repeat_root_node_id: @image_id
    }

    image_binding =
      value_binding("vb_image", @image_id,
        target_kind: :asset,
        scope: :collection_item,
        collection_binding_id: "cb_members",
        value_key: "photo"
      )

    alt_binding =
      value_binding("vb_alt", @image_id,
        target_kind: :text,
        scope: :collection_item,
        collection_binding_id: "cb_members",
        value_key: "alt"
      )

    design_document = %{
      design_document
      | collection_bindings: %{"cb_members" => collection_binding},
        value_bindings: %{"vb_image" => image_binding, "vb_alt" => alt_binding}
    }

    accessibility = %{
      "image_alt_policy" => "consumer_supplied",
      "alt_item_field_name" => "alt",
      "required_when_source_present" => true
    }

    component_contract =
      contract(
        public_attrs: [attr("members", :list)],
        collection_inputs: [
          %CollectionInput{
            source_collection_binding_id: "cb_members",
            public_attr_name: "members",
            item_fields: [
              %ItemField{
                name: "photo",
                type: :string,
                semantic_purpose: "photo",
                accessibility: accessibility
              },
              %ItemField{name: "alt", type: :string, semantic_purpose: "alt"}
            ]
          }
        ],
        binding_projections: [
          %BindingProjection{
            source_binding_kind: :collection,
            source_binding_id: "cb_members",
            projection_kind: :collection_attr,
            public_attr_name: "members",
            source_collection_binding_id: "cb_members",
            target_node_id: @image_id
          },
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_image",
            projection_kind: :collection_item_field,
            source_collection_binding_id: "cb_members",
            item_field_name: "photo",
            target_node_id: @image_id
          },
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_alt",
            projection_kind: :collection_item_field,
            source_collection_binding_id: "cb_members",
            item_field_name: "alt",
            target_node_id: @image_id
          }
        ]
      )

    component_plan = plan(component_contract, design_document)

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok

    missing_alt_projection = %{
      component_contract
      | binding_projections:
          Enum.reject(component_contract.binding_projections, &(&1.source_binding_id == "vb_alt"))
    }

    assert "componentization_plan.accessibility.alt_item_projection_mismatch" in codes(
             ComponentizationPlan.validate_references(
               plan(missing_alt_projection, design_document),
               missing_alt_projection,
               design_document
             )
           )
  end

  test "applies collection-item image validation to nested CollectionInputs" do
    design_document = document()
    [boundary, outside] = design_document.root_nodes
    [heading, paragraph, actions] = boundary.children
    child_image_id = DesignNode.deterministic_id([1, 3, 1])
    image_child = %{hd(actions.children) | semantic_type: "image"}
    actions = %{actions | children: [image_child]}

    design_document = %{
      design_document
      | root_nodes: [%{boundary | children: [heading, paragraph, actions]}, outside]
    }

    parent_collection = %CollectionBinding{
      collection_binding_id: "cb_parent",
      owner_node_id: @boundary_id,
      repeat_root_node_id: @actions_id
    }

    child_collection = %CollectionBinding{
      collection_binding_id: "cb_child",
      owner_node_id: child_image_id,
      repeat_root_node_id: child_image_id,
      parent_collection_binding_id: "cb_parent"
    }

    image_binding =
      value_binding("vb_nested_image", child_image_id,
        target_kind: :asset,
        scope: :collection_item,
        collection_binding_id: "cb_child",
        value_key: "photo"
      )

    alt_binding =
      value_binding("vb_nested_alt", child_image_id,
        target_kind: :text,
        scope: :collection_item,
        collection_binding_id: "cb_child",
        value_key: "alt"
      )

    design_document = %{
      design_document
      | collection_bindings: %{
          "cb_parent" => parent_collection,
          "cb_child" => child_collection
        },
        value_bindings: %{"vb_nested_image" => image_binding, "vb_nested_alt" => alt_binding}
    }

    accessibility = %{
      "image_alt_policy" => "consumer_supplied",
      "alt_item_field_name" => "alt",
      "required_when_source_present" => true
    }

    component_contract =
      contract(
        public_attrs: [attr("members", :list)],
        collection_inputs: [
          %CollectionInput{
            source_collection_binding_id: "cb_parent",
            public_attr_name: "members",
            item_fields: [%ItemField{name: "features", type: :list, semantic_purpose: "features"}]
          },
          %CollectionInput{
            source_collection_binding_id: "cb_child",
            parent_collection_binding_id: "cb_parent",
            parent_item_field_name: "features",
            item_fields: [
              %ItemField{
                name: "photo",
                type: :string,
                semantic_purpose: "photo",
                accessibility: accessibility
              },
              %ItemField{name: "alt", type: :string, semantic_purpose: "alt"}
            ]
          }
        ],
        binding_projections: [
          %BindingProjection{
            source_binding_kind: :collection,
            source_binding_id: "cb_parent",
            projection_kind: :collection_attr,
            public_attr_name: "members",
            source_collection_binding_id: "cb_parent",
            target_node_id: @actions_id
          },
          %BindingProjection{
            source_binding_kind: :collection,
            source_binding_id: "cb_child",
            projection_kind: :collection_item_field,
            source_collection_binding_id: "cb_child",
            parent_collection_binding_id: "cb_parent",
            parent_item_field_name: "features",
            target_node_id: child_image_id
          },
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_nested_image",
            projection_kind: :collection_item_field,
            source_collection_binding_id: "cb_child",
            item_field_name: "photo",
            target_node_id: child_image_id
          },
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_nested_alt",
            projection_kind: :collection_item_field,
            source_collection_binding_id: "cb_child",
            item_field_name: "alt",
            target_node_id: child_image_id
          }
        ]
      )

    component_plan = plan(component_contract, design_document)

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok
  end

  test "a subtree slot replaces its static subtree but cannot conceal a binding" do
    design_document = document()

    component_contract =
      contract(
        public_slots: [
          %Slot{name: "actions", semantic_purpose: "actions", consumer_responsibility: "caller"}
        ]
      )

    slot_projection = %RenderProjection{
      public_slot_name: "actions",
      target_node_id: @actions_id,
      render_role: :subtree_slot
    }

    component_plan =
      plan(component_contract, design_document, render_projections: [slot_projection])

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok

    action_child_id = DesignNode.deterministic_id([1, 3, 1])

    bound_document = %{
      design_document
      | value_bindings: %{"vb_action" => value_binding("vb_action", action_child_id)}
    }

    bound_contract =
      contract(
        public_attrs: [attr("label")],
        public_slots: component_contract.public_slots,
        binding_projections: [binding_projection("vb_action", "label", action_child_id)]
      )

    bound_plan = plan(bound_contract, bound_document, render_projections: [slot_projection])

    assert "componentization_plan.slot.subtree_conflict" in codes(
             ComponentizationPlan.validate_references(bound_plan, bound_contract, bound_document)
           )
  end

  test "a subtree slot cannot contain another render projection" do
    design_document = document()
    button_id = DesignNode.deterministic_id([1, 3, 1])

    component_contract =
      contract(
        public_slots: [
          %Slot{name: "actions", semantic_purpose: "actions", consumer_responsibility: "caller"},
          %Slot{name: "primary", semantic_purpose: "primary", consumer_responsibility: "caller"}
        ]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [
          %RenderProjection{
            public_slot_name: "actions",
            target_node_id: @actions_id,
            render_role: :subtree_slot
          },
          %RenderProjection{
            public_slot_name: "primary",
            target_node_id: button_id,
            render_role: :subtree_slot
          }
        ]
      )

    assert "componentization_plan.slot.subtree_conflict" in codes(
             ComponentizationPlan.validate_references(
               component_plan,
               component_contract,
               design_document
             )
           )
  end

  test "reports evidence-insufficient bindings in the plan diagnostic namespace" do
    design_document = %{
      document()
      | value_bindings: %{
          "vb_title" =>
            value_binding("vb_title", @heading_id,
              normalization_status: :evidence_insufficient,
              modifier: %LiveFrames.IR.ValueModifier.Opaque{}
            )
        }
    }

    component_contract =
      contract(
        public_attrs: [attr("title")],
        binding_projections: [binding_projection("vb_title", "title")]
      )

    assert "componentization_plan.binding.evidence_insufficient" in codes(
             ComponentizationPlan.validate_references(
               plan(component_contract, design_document),
               component_contract,
               design_document
             )
           )
  end

  test "generation requires an approved contract and blocks stored errors" do
    design_document = document()
    approved = contract()
    valid_plan = plan(approved, design_document)

    assert ComponentizationPlan.validate_for_generation(valid_plan, approved, design_document) ==
             :ok

    proposed = %{approved | approval_status: :proposed}

    assert {:error, approval_diagnostics} =
             ComponentizationPlan.validate_for_generation(valid_plan, proposed, design_document)

    assert Enum.any?(
             approval_diagnostics,
             &(&1.code == "componentization_plan.generation_blocked")
           )

    stored = %Diagnostic{
      code: "componentization_plan.review.required",
      severity: :error,
      message: "review required"
    }

    blocked_plan = %{valid_plan | diagnostics: [stored]}

    assert {:error, blocked_diagnostics} =
             ComponentizationPlan.validate_for_generation(blocked_plan, approved, design_document)

    assert Enum.any?(
             blocked_diagnostics,
             &(&1.code == "componentization_plan.generation_blocked")
           )
  end

  test "generation blocks current-entity rich-text bindings through both plan APIs" do
    {component_plan, component_contract, design_document} = rich_text_generation_fixture()
    {behavior_contract, review} = empty_behavior_authority(design_document)

    assert component_plan.render_projections == []
    assert length(component_contract.binding_projections) == 1

    assert ComponentizationPlan.validate_references(
             component_plan,
             component_contract,
             design_document
           ) == :ok

    for result <- [
          ComponentizationPlan.validate_for_generation(
            component_plan,
            component_contract,
            design_document
          ),
          ComponentizationPlan.validate_for_generation_with_behavior_authority(
            component_plan,
            component_contract,
            design_document,
            behavior_contract,
            review
          )
        ] do
      assert {:error, diagnostics} = result

      assert Enum.any?(diagnostics, fn diagnostic ->
               diagnostic.code == "componentization_plan.binding.rich_text_trust_required"
             end)
    end
  end

  test "out-of-boundary rich-text bindings do not block selected component generation" do
    {component_plan, component_contract, design_document} =
      rich_text_generation_fixture(:outside)

    assert ComponentizationPlan.validate_for_generation(
             component_plan,
             component_contract,
             design_document
           ) == :ok
  end

  test "generation blocks navigable headings with whitespace-only static text" do
    design_document = navigable_heading_document(content: " \t ")
    component_contract = contract()
    component_plan = plan(component_contract, design_document)

    assert {:error, diagnostics} =
             ComponentizationPlan.validate_generation_prerequisites(
               component_plan,
               component_contract,
               design_document
             )

    assert "componentization_plan.native_generation.heading_navigation_invalid" in Enum.map(
             diagnostics,
             & &1.code
           )
  end

  test "generation accepts the closed static heading navigation shape" do
    design_document = navigable_heading_document()
    component_contract = contract()
    component_plan = plan(component_contract, design_document)

    assert :ok =
             ComponentizationPlan.validate_generation_prerequisites(
               component_plan,
               component_contract,
               design_document
             )
  end

  test "generation blocks navigable headings with absent static text" do
    design_document = navigable_heading_document(content: nil)
    component_contract = contract()
    component_plan = plan(component_contract, design_document)

    assert {:error, diagnostics} =
             ComponentizationPlan.validate_generation_prerequisites(
               component_plan,
               component_contract,
               design_document
             )

    assert "componentization_plan.native_generation.heading_navigation_invalid" in Enum.map(
             diagnostics,
             & &1.code
           )
  end

  test "generation blocks navigable headings with dynamic text ownership" do
    design_document = navigable_heading_document()
    component_contract = contract(public_attrs: [attr("title")])

    component_plan =
      plan(component_contract, design_document,
        render_projections: [render_attr("title", :text_content)]
      )

    assert {:error, diagnostics} =
             ComponentizationPlan.validate_generation_prerequisites(
               component_plan,
               component_contract,
               design_document
             )

    assert "componentization_plan.native_generation.heading_navigation_invalid" in Enum.map(
             diagnostics,
             & &1.code
           )
  end

  test "generation blocks navigable headings with dynamic heading levels" do
    design_document = navigable_heading_document()

    component_contract =
      contract(
        public_attrs: [
          attr("level", :integer, required: true, validation: %{"values" => [1, 2, 3, 4, 5, 6]})
        ]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [render_attr("level", :heading_level)]
      )

    assert {:error, diagnostics} =
             ComponentizationPlan.validate_generation_prerequisites(
               component_plan,
               component_contract,
               design_document
             )

    assert "componentization_plan.native_generation.heading_navigation_invalid" in Enum.map(
             diagnostics,
             & &1.code
           )
  end

  test "generation blocks navigable headings owned by a content slot" do
    design_document = navigable_heading_document()

    component_contract =
      contract(
        public_slots: [
          %Slot{
            name: "heading_content",
            semantic_purpose: "heading content",
            consumer_responsibility: "caller"
          }
        ]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [
          %RenderProjection{
            public_slot_name: "heading_content",
            target_node_id: @heading_id,
            render_role: :subtree_slot
          }
        ]
      )

    assert {:error, diagnostics} =
             ComponentizationPlan.validate_generation_prerequisites(
               component_plan,
               component_contract,
               design_document
             )

    assert "componentization_plan.render_projection.role_node_mismatch" in Enum.map(
             diagnostics,
             & &1.code
           )
  end

  test "generation blocks navigable headings with an invalid static navigation map" do
    design_document =
      navigable_heading_document(attributes: %{"navigation" => %{"href" => "javascript:bad"}})

    component_contract = contract()
    component_plan = plan(component_contract, design_document)

    assert {:error, diagnostics} =
             ComponentizationPlan.validate_generation_prerequisites(
               component_plan,
               component_contract,
               design_document
             )

    assert "componentization_plan.native_generation.static_navigation_invalid" in Enum.map(
             diagnostics,
             & &1.code
           )
  end

  test "generation blocks navigable headings without a proven heading tag" do
    design_document = navigable_heading_document(attributes: %{"tag" => "div"})
    component_contract = contract()
    component_plan = plan(component_contract, design_document)

    assert {:error, diagnostics} =
             ComponentizationPlan.validate_generation_prerequisites(
               component_plan,
               component_contract,
               design_document
             )

    assert "componentization_plan.native_generation.tag_unsupported" in Enum.map(
             diagnostics,
             & &1.code
           )
  end

  test "generation blocks navigable headings with child subtrees" do
    child = %DesignNode{
      node_id: DesignNode.deterministic_id([1, 1, 1]),
      semantic_type: "paragraph",
      content: "Child"
    }

    design_document = navigable_heading_document(children: [child])
    component_contract = contract()
    component_plan = plan(component_contract, design_document)

    assert {:error, diagnostics} =
             ComponentizationPlan.validate_generation_prerequisites(
               component_plan,
               component_contract,
               design_document
             )

    assert "componentization_plan.native_generation.heading_children_forbidden" in Enum.map(
             diagnostics,
             & &1.code
           )
  end

  test "generation blocks navigable headings with a link_url projection" do
    design_document = navigable_heading_document()
    component_contract = contract(public_attrs: [attr("href")])

    component_plan =
      plan(component_contract, design_document,
        render_projections: [render_attr("href", :link_url)]
      )

    assert {:error, _diagnostics} =
             ComponentizationPlan.validate_generation_prerequisites(
               component_plan,
               component_contract,
               design_document
             )
  end

  test "ordinary dynamic headings remain generation eligible without navigation" do
    design_document =
      navigable_heading_document(navigable?: false)

    component_contract = contract(public_attrs: [attr("title")])

    component_plan =
      plan(component_contract, design_document,
        render_projections: [render_attr("title", :text_content)]
      )

    assert :ok =
             ComponentizationPlan.validate_generation_prerequisites(
               component_plan,
               component_contract,
               design_document
             )
  end

  test "ordinary dynamic heading levels remain generation eligible without navigation" do
    design_document = navigable_heading_document(navigable?: false)

    component_contract =
      contract(
        public_attrs: [
          attr("level", :integer, required: true, validation: %{"values" => [1, 2, 3, 4, 5, 6]})
        ]
      )

    component_plan =
      plan(component_contract, design_document,
        render_projections: [render_attr("level", :heading_level)]
      )

    assert :ok =
             ComponentizationPlan.validate_generation_prerequisites(
               component_plan,
               component_contract,
               design_document
             )
  end

  test "info and warning plan diagnostics do not block generation" do
    design_document = document()
    component_contract = contract()
    base_plan = plan(component_contract, design_document)

    for severity <- [:info, :warning] do
      stored = %Diagnostic{
        code: "componentization_plan.review.note",
        severity: severity,
        message: "non-blocking note"
      }

      assert ComponentizationPlan.validate_for_generation(
               %{base_plan | diagnostics: [stored]},
               component_contract,
               design_document
             ) == :ok
    end
  end

  test "binding-backed slots satisfy placement and remain generation-blocked" do
    design_document = %{
      document()
      | value_bindings: %{"vb_actions" => value_binding("vb_actions", @actions_id)}
    }

    component_contract =
      contract(
        public_slots: [
          %Slot{name: "actions", semantic_purpose: "actions", consumer_responsibility: "caller"}
        ],
        binding_projections: [
          %BindingProjection{
            source_binding_kind: :value,
            source_binding_id: "vb_actions",
            projection_kind: :slot,
            public_slot_name: "actions",
            target_node_id: @actions_id
          }
        ]
      )

    component_plan = plan(component_contract, design_document)

    assert "componentization_plan.slot.binding_backed_unsupported" in codes(
             ComponentizationPlan.validate_references(
               component_plan,
               component_contract,
               design_document
             )
           )

    assert {:error, diagnostics} =
             ComponentizationPlan.validate_for_generation(
               component_plan,
               component_contract,
               design_document
             )

    assert Enum.any?(
             diagnostics,
             &(&1.code == "componentization_plan.slot.binding_backed_unsupported")
           )
  end

  test "malformed plans, contracts and documents fail closed without raising" do
    malformed_plan = %ComponentizationPlan{
      contract_id: "hero-contract",
      design_document_sha256: String.duplicate("a", 64),
      boundary_node_id: @boundary_id,
      render_projections: [%{}],
      diagnostics: :invalid,
      provenance: %{bad: self()}
    }

    assert {:error, _} =
             ComponentizationPlan.validate_references(malformed_plan, contract(), document())

    assert {:error, _} =
             ComponentizationPlan.validate_for_generation(malformed_plan, contract(), document())

    assert {:error, _} =
             ComponentizationPlan.validate_references(
               plan(contract(), document()),
               %{},
               document()
             )

    assert {:error, _} =
             ComponentizationPlan.validate_references(
               plan(contract(), document()),
               contract(),
               %{}
             )
  end
end
