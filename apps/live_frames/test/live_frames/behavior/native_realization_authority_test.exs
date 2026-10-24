defmodule LiveFrames.Behavior.NativeRealizationAuthorityTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Behavior.Binding
  alias LiveFrames.Behavior.Binding.ControlledTarget
  alias LiveFrames.Behavior.Binding.PrimitiveRef
  alias LiveFrames.Behavior.Binding.Trigger
  alias LiveFrames.Behavior.BindingIdentity
  alias LiveFrames.Behavior.Contract, as: BehaviorContract
  alias LiveFrames.Behavior.NativeRealizationAuthority
  alias LiveFrames.Behavior.ReviewResult
  alias LiveFrames.Behavior.Serializer
  alias LiveFrames.Behavior.Validation
  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentContract.CollectionInput
  alias LiveFrames.ComponentContract.ItemField
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.RenderProjection
  alias LiveFrames.IR.CollectionBinding
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Identity
  alias LiveFrames.IR.Interaction
  alias LiveFrames.IR.ValueBinding
  alias LiveFrames.IR.ValueModifier

  test "valid synthetic Selection tuple derives transient authority with exact tuple identity" do
    tuple = valid_tuple()
    {component_contract, plan, document, behavior_contract, review} = tuple

    assert :ok = ComponentContract.validate_for_generation(component_contract, document)
    assert :ok = Validation.validate_structure(document, behavior_contract)
    assert {:ok, _digest} = Serializer.digest(behavior_contract)
    assert {:ok, ^review} = ReviewResult.require_approved([review], behavior_contract)
    assert {:ok, _review_id} = ReviewResult.id(review)

    assert :ok =
             ComponentizationPlan.validate_references_with_behavior_authority(
               plan,
               component_contract,
               document,
               behavior_contract,
               review
             )

    assert :ok = Validation.validate_semantics(document, behavior_contract)

    assert {:ok, authority} = derive(tuple)
    assert authority.component_contract_id == component_contract.contract_id
    assert authority.plan_contract_id == plan.contract_id
    assert authority.design_document_identity == elem(Identity.from_document(document), 1)
    assert authority.plan_design_document_sha256 == plan.design_document_sha256
    assert authority.boundary_node_id == ids().boundary
    assert authority.behavior_contract_digest == elem(Serializer.digest(behavior_contract), 1)
    assert authority.behavior_review_result_id == elem(ReviewResult.id(review), 1)
    assert authority.behavior_binding_id == hd(behavior_contract.bindings).binding_id
    assert authority.control_node_id == ids().control
    assert authority.activation_carrier_node_id == ids().carrier

    assert authority.presentation_node_ids ==
             Enum.sort([ids().presentation_a, ids().presentation_b])

    assert Enum.sort(Map.keys(authority)) ==
             Enum.sort([
               :__struct__,
               :component_contract_id,
               :plan_contract_id,
               :design_document_identity,
               :plan_design_document_sha256,
               :boundary_node_id,
               :behavior_contract_digest,
               :behavior_review_result_id,
               :behavior_binding_id,
               :control_node_id,
               :activation_carrier_node_id,
               :presentation_node_ids
             ])

    refute function_exported?(NativeRealizationAuthority, :encode, 1)
    refute function_exported?(NativeRealizationAuthority, :to_map, 1)
  end

  test "a valid topology with different synthetic IDs derives authority" do
    assert {:ok, authority} = valid_tuple(ids: ids(:alternate)) |> derive()
    assert authority.boundary_node_id == ids(:alternate).boundary
    assert authority.control_node_id == ids(:alternate).control
    assert authority.activation_carrier_node_id == ids(:alternate).carrier
  end

  test "Selection timer trigger remains accepted with one activate trigger" do
    timer_policy = %{
      "purpose" => "advance_selection",
      "interval_ms" => 5_000,
      "start" => "on_initialization",
      "manual_activation" => "stop",
      "restart" => "never",
      "reset" => "none",
      "reduced_motion" => "disable_automatic_advance"
    }

    tuple =
      valid_tuple(
        binding_transform: fn binding ->
          %{
            binding
            | timer_policy: timer_policy,
              triggers: binding.triggers ++ [%Trigger{kind: "timer", origin_node_id: nil}]
          }
        end
      )

    assert {:ok, _authority} = derive(tuple)
  end

  test "an ordinary generic button and a valid plan alone derive no authority" do
    tuple =
      valid_tuple(behavior_contract_transform: fn contract -> %{contract | bindings: []} end)

    assert_code(tuple, "behavior.native_realization.selection_missing")
  end

  test "Layer A diagnostics pass through unchanged" do
    tuple =
      valid_tuple(
        component_contract_transform: fn contract -> %{contract | approval_status: :proposed} end
      )

    {contract, _plan, document, _behavior, _review} = tuple
    assert {:error, diagnostics} = ComponentContract.validate_for_generation(contract, document)
    assert derive(tuple) == {:error, diagnostics}
  end

  test "B1 structural diagnostics pass through unchanged for a document mismatch" do
    tuple =
      valid_tuple(
        behavior_contract_transform: fn contract ->
          identity = %{contract.design_document_identity | digest: String.duplicate("0", 64)}
          %{contract | design_document_identity: identity}
        end
      )

    {_component, _plan, document, behavior, _review} = tuple
    assert {:error, diagnostics} = Validation.validate_structure(document, behavior)
    assert derive(tuple) == {:error, diagnostics}
  end

  test "B1 review approval and contract matching diagnostics pass through unchanged" do
    unapproved =
      valid_tuple(review_transform: fn review -> %{review | decision: "needs_review"} end)

    mismatched =
      valid_tuple(
        review_transform: fn review ->
          %{review | behavior_contract_digest: String.duplicate("0", 64)}
        end
      )

    for tuple <- [unapproved, mismatched] do
      {_component, _plan, _document, behavior, review} = tuple
      assert {:error, diagnostics} = ReviewResult.require_approved([review], behavior)
      assert derive(tuple) == {:error, diagnostics}
    end
  end

  test "B2 reference diagnostics pass through unchanged" do
    tuple = valid_tuple(plan_transform: fn plan -> %{plan | contract_id: "another-contract"} end)
    {contract, plan, document, behavior, review} = tuple

    assert {:error, diagnostics} =
             ComponentizationPlan.validate_references_with_behavior_authority(
               plan,
               contract,
               document,
               behavior,
               review
             )

    assert derive(tuple) == {:error, diagnostics}
  end

  test "structurally valid but semantically invalid Selection cannot derive authority" do
    tuple =
      valid_tuple(
        binding_transform: fn binding ->
          %{binding | initial_state: %{"unknown_dimension" => 1}}
        end
      )

    {_contract, _plan, document, behavior, _review} = tuple
    assert :ok = Validation.validate_structure(document, behavior)
    assert {:error, diagnostics} = Validation.validate_semantics(document, behavior)
    assert Enum.any?(diagnostics, &(&1.code == "behavior.semantic.initial_state_invalid"))
    assert derive(tuple) == {:error, diagnostics}
  end

  test "outside Selection does not count as the contained realization candidate" do
    tuple =
      valid_tuple(
        document_transform: &with_outside_selection/1,
        binding_transform: &outside_selection_binding(&1, ids())
      )

    assert_code(tuple, "behavior.native_realization.selection_missing")
  end

  test "split Behavior references deny authority with the binding identified" do
    tuple =
      valid_tuple(
        binding_transform: fn binding ->
          targets =
            List.update_at(binding.controlled_targets, 2, fn target ->
              %{target | node_id: ids().outside}
            end)

          %{binding | owner_node_id: ids().root, controlled_targets: targets}
        end
      )

    assert_code(tuple, "behavior.native_realization.binding_not_contained")
  end

  test "unresolved Behavior references fail closed at the structural gate" do
    tuple =
      valid_tuple(
        binding_transform: fn binding ->
          %{binding | triggers: [%Trigger{kind: "activate", origin_node_id: "missing-node"}]}
        end
      )

    {_contract, _plan, document, behavior, _review} = tuple
    assert {:error, diagnostics} = Validation.validate_structure(document, behavior)
    assert derive(tuple) == {:error, diagnostics}
  end

  test "an unrelated outside-candidate Behavior binding does not block authority" do
    tuple =
      valid_tuple(
        document_transform: &with_outside_selection/1,
        additional_bindings: fn _opts, ids ->
          [outside_selection_binding(selection_binding(ids), ids)]
        end
      )

    assert {:ok, _authority} = derive(tuple)
  end

  test "unsupported Selection version is denied by Behavior semantic validation" do
    tuple =
      valid_tuple(
        binding_transform: fn binding ->
          %{
            binding
            | primitive_ref: %PrimitiveRef{kind: "selection", definition_version: "2.0.0"}
          }
        end
      )

    {_contract, _plan, document, behavior, _review} = tuple
    assert {:error, diagnostics} = Validation.validate_semantics(document, behavior)
    assert Enum.any?(diagnostics, &(&1.code == "behavior.semantic.primitive_unsupported"))
    assert derive(tuple) == {:error, diagnostics}
  end

  test "multiple contained Selection bindings are ambiguous" do
    tuple =
      valid_tuple(
        additional_bindings: fn _ids, ids ->
          [selection_binding(ids, binding_role: "secondary")]
        end
      )

    assert_code(tuple, "behavior.native_realization.selection_ambiguous")
  end

  test "Selection control and activation cardinality failures are denied" do
    invalid_bindings = [
      fn binding ->
        %{
          binding
          | controlled_targets:
              Enum.reject(binding.controlled_targets, &(&1.role == "control_collection"))
        }
      end,
      fn binding ->
        [control | rest] = binding.controlled_targets
        assert %ControlledTarget{role: "control_collection"} = control

        %{binding | controlled_targets: [control, control | rest]}
      end,
      fn binding -> %{binding | triggers: []} end,
      fn binding -> %{binding | triggers: binding.triggers ++ binding.triggers} end,
      fn binding ->
        %{binding | triggers: [%Trigger{kind: "activate", origin_node_id: ids().presentation_a}]}
      end
    ]

    for transform <- invalid_bindings do
      assert {:error, _diagnostics} = valid_tuple(binding_transform: transform) |> derive()
    end
  end

  test "presentation collections require exactly two distinct targets" do
    one_target =
      valid_tuple(
        binding_transform: fn binding ->
          %{binding | controlled_targets: List.delete_at(binding.controlled_targets, 2)}
        end
      )

    three_targets =
      valid_tuple(
        binding_transform: fn binding ->
          %{
            binding
            | controlled_targets:
                binding.controlled_targets ++
                  [
                    %ControlledTarget{
                      role: "presentation_collection",
                      node_id: ids().presentation_c
                    }
                  ]
          }
        end
      )

    duplicate_target =
      valid_tuple(
        binding_transform: fn binding ->
          %{
            binding
            | controlled_targets:
                binding.controlled_targets ++
                  [
                    %ControlledTarget{
                      role: "presentation_collection",
                      node_id: ids().presentation_a
                    }
                  ]
          }
        end
      )

    assert_code(one_target, "behavior.native_realization.presentation_invalid")
    assert {:error, _diagnostics} = derive(three_targets)
    assert {:error, _diagnostics} = derive(duplicate_target)
  end

  test "N2 must remain a generic DesignNode with normalized button tag" do
    not_generic =
      valid_tuple(
        document_transform: fn document ->
          update_node(document, ids().control, &%{&1 | semantic_type: "button"})
        end
      )

    wrong_tag =
      valid_tuple(
        document_transform: fn document ->
          update_node(document, ids().control, &%{&1 | attributes: %{"tag" => "div"}})
        end
      )

    assert_code(not_generic, "behavior.native_realization.control_invalid")
    assert_code(wrong_tag, "behavior.native_realization.control_invalid")
  end

  test "activation carrier must be a direct heading child and uniquely eligible" do
    nested = nested_carrier_tuple()

    not_heading =
      valid_tuple(
        document_transform: fn document ->
          update_node(document, ids().carrier, &%{&1 | semantic_type: "paragraph"})
        end
      )

    multiple = multiple_carrier_tuple()

    assert {:error, _diagnostics} = derive(nested)
    assert {:error, _diagnostics} = derive(not_heading)
    assert_code(multiple, "behavior.native_realization.carrier_invalid")
  end

  test "title ValueBinding projection and normalized text target are required" do
    missing_projection =
      valid_tuple(
        component_contract_transform: fn contract ->
          %{
            contract
            | binding_projections:
                Enum.reject(contract.binding_projections, &(&1.source_binding_kind == :value))
          }
        end
      )

    ambiguous_projection =
      valid_tuple(
        component_contract_transform: fn contract ->
          [projection] =
            Enum.filter(contract.binding_projections, &(&1.source_binding_kind == :value))

          %{contract | binding_projections: contract.binding_projections ++ [projection]}
        end
      )

    missing_value =
      valid_tuple(document_transform: fn document -> %{document | value_bindings: %{}} end)

    wrong_target_kind =
      valid_tuple(
        document_transform: fn document ->
          update_value_binding(document, "title-value", &%{&1 | target_kind: :asset})
        end
      )

    wrong_target_node =
      valid_tuple(
        document_transform: fn document ->
          update_value_binding(
            document,
            "title-value",
            &%{&1 | target_node_id: ids().presentation_a}
          )
        end
      )

    unnormalized =
      valid_tuple(
        document_transform: fn document ->
          update_value_binding(
            document,
            "title-value",
            &%{&1 | normalization_status: :evidence_insufficient}
          )
        end
      )

    for tuple <- [
          missing_projection,
          ambiguous_projection,
          missing_value,
          wrong_target_kind,
          wrong_target_node,
          unnormalized
        ] do
      assert {:error, _diagnostics} = derive(tuple)
    end
  end

  test "heading-level RenderProjection must be exact and unambiguous" do
    missing = valid_tuple(plan_transform: fn plan -> %{plan | render_projections: []} end)

    ambiguous =
      valid_tuple(
        plan_transform: fn plan ->
          [projection] = plan.render_projections
          %{plan | render_projections: plan.render_projections ++ [projection]}
        end
      )

    for tuple <- [missing, ambiguous] do
      assert {:error, _diagnostics} = derive(tuple)
    end
  end

  test "heading-level public attribute name is derived from the approved plan" do
    tuple =
      valid_tuple(
        component_contract_transform: fn contract ->
          %{
            contract
            | public_attrs:
                Enum.map(contract.public_attrs, fn attr ->
                  if attr.name == "heading_level", do: %{attr | name: "visible_level"}, else: attr
                end)
          }
        end,
        plan_transform: fn plan ->
          %{
            plan
            | render_projections:
                Enum.map(plan.render_projections, fn projection ->
                  %{projection | public_attr_name: "visible_level"}
                end)
          }
        end
      )

    assert {:ok, authority} = derive(tuple)
    assert authority.activation_carrier_node_id == ids().carrier
  end

  test "Design IR interaction refs and targets on N2 or N3 conflict with realization" do
    n2_ref =
      valid_tuple(
        document_transform: fn document ->
          document =
            update_node(document, ids().control, &%{&1 | interaction_refs: ["ir-control"]})

          %{
            document
            | interactions: %{
                "ir-control" => %Interaction{
                  interaction_id: "ir-control",
                  intent: "activate",
                  target_node_ids: [ids().presentation_a]
                }
              }
          }
        end
      )

    n3_target =
      valid_tuple(
        document_transform: fn document ->
          %{
            document
            | interactions: %{
                "ir-carrier" => %Interaction{
                  interaction_id: "ir-carrier",
                  intent: "activate",
                  target_node_ids: [ids().carrier]
                }
              }
          }
        end
      )

    assert_code(n2_ref, "behavior.native_realization.interaction_conflict")
    assert_code(n3_target, "behavior.native_realization.interaction_conflict")
  end

  test "link_url ValueBindings on N2 or N3 conflict with realization" do
    for node_id <- [ids().control, ids().carrier] do
      tuple =
        valid_tuple(
          document_transform: &with_link_binding(&1, node_id),
          component_contract_transform: &with_link_projection(&1, node_id)
        )

      {_component_contract, _plan, _document, behavior_contract, _review} = tuple
      [selected_binding] = behavior_contract.bindings

      assert {:error, diagnostics} = derive(tuple)

      assert [diagnostic] =
               Enum.filter(
                 diagnostics,
                 &(&1.code == "behavior.native_realization.link_binding_conflict")
               )

      assert diagnostic.binding_id == selected_binding.binding_id
      assert diagnostic.node_id == node_id
      assert diagnostic.severity == "error"
      assert diagnostic.category == "realization"
      assert diagnostic.source_trace == nil
    end
  end

  test "another Selection binding that claims N2 or N3 is denied as ambiguous" do
    for claimed_node <- [ids().control, ids().carrier] do
      tuple =
        valid_tuple(
          additional_bindings: fn _opts, ids ->
            targets = [
              %ControlledTarget{role: "control_collection", node_id: ids.control},
              %ControlledTarget{role: "presentation_collection", node_id: ids.presentation_a},
              %ControlledTarget{role: "presentation_collection", node_id: ids.presentation_b}
            ]

            targets =
              if claimed_node == ids.carrier do
                List.replace_at(targets, 1, %ControlledTarget{
                  role: "presentation_collection",
                  node_id: ids.carrier
                })
              else
                targets
              end

            [
              %Binding{
                primitive_ref: %PrimitiveRef{kind: "selection", definition_version: "1.0.0"},
                owner_node_id: ids.boundary,
                binding_role: "secondary",
                primitive_policy_values: %{
                  "alignment" => "position",
                  "advance_boundary" => "wrap"
                },
                triggers: [%Trigger{kind: "activate", origin_node_id: ids.control}],
                controlled_targets: targets
              }
            ]
          end
        )

      assert {:error, diagnostics} = derive(tuple)

      assert Enum.any?(
               diagnostics,
               &(&1.code == "behavior.native_realization.selection_ambiguous")
             )
    end
  end

  defp derive({component_contract, plan, document, behavior_contract, review}) do
    NativeRealizationAuthority.derive(
      component_contract,
      plan,
      document,
      behavior_contract,
      review
    )
  end

  defp assert_code(tuple, code) do
    assert {:error, diagnostics} = derive(tuple)
    assert Enum.any?(diagnostics, &(&1.code == code))
  end

  defp valid_tuple(opts \\ []) do
    ids = Keyword.get(opts, :ids, ids())
    document = document(ids)
    document = Keyword.get(opts, :document_transform, &Function.identity/1).(document)

    binding = selection_binding(ids)
    binding = Keyword.get(opts, :binding_transform, &Function.identity/1).(binding)
    additional_bindings = Keyword.get(opts, :additional_bindings, [])

    additional_bindings =
      if is_function(additional_bindings, 2),
        do: additional_bindings.(opts, ids),
        else: additional_bindings

    {:ok, document_identity} = Identity.from_document(document)

    {:ok, behavior_contract} =
      BindingIdentity.assign(%BehaviorContract{
        design_document_identity: document_identity,
        bindings: [binding | additional_bindings]
      })

    behavior_contract =
      Keyword.get(opts, :behavior_contract_transform, &Function.identity/1).(behavior_contract)

    review = approved_review(document, behavior_contract)
    review = Keyword.get(opts, :review_transform, &Function.identity/1).(review)

    component_contract = component_contract(ids)

    component_contract =
      Keyword.get(opts, :component_contract_transform, &Function.identity/1).(component_contract)

    {:ok, document_sha256} = ComponentizationPlan.design_document_sha256(document)

    plan = %ComponentizationPlan{
      contract_id: component_contract.contract_id,
      design_document_sha256: document_sha256,
      boundary_node_id: ids.boundary,
      render_projections: [
        %RenderProjection{
          public_attr_name: "heading_level",
          target_node_id: ids.carrier,
          render_role: :heading_level
        }
      ]
    }

    plan = Keyword.get(opts, :plan_transform, &Function.identity/1).(plan)
    {component_contract, plan, document, behavior_contract, review}
  end

  defp document(ids) do
    leading_roots =
      if ids.root == DesignNode.deterministic_id([2]) do
        [%DesignNode{node_id: DesignNode.deterministic_id([1]), semantic_type: "section"}]
      else
        []
      end

    %DesignDocument{
      root_nodes:
        leading_roots ++
          [
            %DesignNode{
              node_id: ids.root,
              semantic_type: "section",
              children: [
                %DesignNode{
                  node_id: ids.boundary,
                  semantic_type: "section",
                  children: [
                    %DesignNode{
                      node_id: ids.control,
                      semantic_type: "generic",
                      attributes: %{"tag" => "button"},
                      children: [
                        %DesignNode{
                          node_id: ids.carrier,
                          semantic_type: "heading",
                          attributes: %{"tag" => "h3"}
                        }
                      ]
                    },
                    %DesignNode{node_id: ids.presentation_a, semantic_type: "paragraph"},
                    %DesignNode{node_id: ids.presentation_b, semantic_type: "paragraph"},
                    %DesignNode{node_id: ids.presentation_c, semantic_type: "paragraph"}
                  ]
                },
                %DesignNode{node_id: ids.outside, semantic_type: "paragraph"}
              ]
            }
          ],
      collection_bindings: %{
        "cb_cards" => %CollectionBinding{
          collection_binding_id: "cb_cards",
          owner_node_id: ids.boundary,
          repeat_root_node_id: ids.boundary
        }
      },
      value_bindings: %{
        "title-value" => %ValueBinding{
          value_binding_id: "title-value",
          target_node_id: ids.carrier,
          target_kind: :text,
          value_kind: :field,
          scope: :collection_item,
          value_key: "title",
          collection_binding_id: "cb_cards",
          normalization_status: :normalized,
          modifier: %ValueModifier.None{}
        }
      }
    }
  end

  defp component_contract(ids) do
    %ComponentContract{
      contract_id: "synthetic-selection-contract",
      module_intent: "selection_component",
      function_intent: "selection_component",
      public_attrs: [
        %Attr{name: "items", type: :list, semantic_purpose: "items"},
        %Attr{
          name: "heading_level",
          type: :integer,
          required: true,
          semantic_purpose: "heading level",
          validation: %{"values" => [1, 2, 3, 4, 5, 6]}
        }
      ],
      collection_inputs: [
        %CollectionInput{
          source_collection_binding_id: "cb_cards",
          public_attr_name: "items",
          item_fields: [%ItemField{name: "title", type: :string, semantic_purpose: "title"}]
        }
      ],
      binding_projections: [
        %BindingProjection{
          source_binding_kind: :collection,
          source_binding_id: "cb_cards",
          projection_kind: :collection_attr,
          public_attr_name: "items",
          source_collection_binding_id: "cb_cards",
          target_node_id: ids.boundary
        },
        %BindingProjection{
          source_binding_kind: :value,
          source_binding_id: "title-value",
          projection_kind: :collection_item_field,
          source_collection_binding_id: "cb_cards",
          item_field_name: "title",
          target_node_id: ids.carrier
        }
      ],
      approval_status: :approved
    }
  end

  defp selection_binding(ids, attrs \\ []) do
    defaults = %Binding{
      primitive_ref: %PrimitiveRef{kind: "selection", definition_version: "1.0.0"},
      owner_node_id: ids.boundary,
      binding_role: "primary",
      primitive_policy_values: %{"alignment" => "position", "advance_boundary" => "wrap"},
      triggers: [%Trigger{kind: "activate", origin_node_id: ids.control}],
      controlled_targets: [
        %ControlledTarget{role: "control_collection", node_id: ids.control},
        %ControlledTarget{role: "presentation_collection", node_id: ids.presentation_a},
        %ControlledTarget{role: "presentation_collection", node_id: ids.presentation_b}
      ]
    }

    struct!(defaults, attrs)
  end

  defp approved_review(document, behavior_contract) do
    {:ok, identity} = Identity.from_document(document)
    {:ok, behavior_digest} = Serializer.digest(behavior_contract)

    %ReviewResult{
      review_format_version: "1.0.0",
      design_document_identity: identity,
      behavior_contract_digest_algorithm: Serializer.algorithm(),
      behavior_contract_digest: behavior_digest,
      decision: "approved",
      reviewer_identity: "reviewer:synthetic-selection",
      reviewed_at: "2026-10-20T00:00:00.000000Z",
      review_note: nil,
      evidence_refs: ["synthetic-selection-review"]
    }
  end

  defp with_outside_selection(document) do
    ids = ids()
    [root] = document.root_nodes
    [boundary, _outside] = root.children

    outside = %DesignNode{
      node_id: ids.outside,
      semantic_type: "section",
      children: [
        %DesignNode{
          node_id: ids.outside_control,
          semantic_type: "generic",
          attributes: %{"tag" => "button"}
        },
        %DesignNode{node_id: ids.outside_presentation_a, semantic_type: "paragraph"},
        %DesignNode{node_id: ids.outside_presentation_b, semantic_type: "paragraph"}
      ]
    }

    %{document | root_nodes: [%{root | children: [boundary, outside]}]}
  end

  defp outside_selection_binding(binding, ids) do
    %{
      binding
      | owner_node_id: ids.outside,
        triggers: [%Trigger{kind: "activate", origin_node_id: ids.outside_control}],
        controlled_targets: [
          %ControlledTarget{role: "control_collection", node_id: ids.outside_control},
          %ControlledTarget{role: "presentation_collection", node_id: ids.outside_presentation_a},
          %ControlledTarget{role: "presentation_collection", node_id: ids.outside_presentation_b}
        ]
    }
  end

  defp multiple_carrier_tuple do
    ids = ids()
    second_id = DesignNode.deterministic_id([1, 1, 1, 2])
    second_value_id = "second-title-value"

    valid_tuple(
      document_transform: fn document ->
        document =
          update_node(document, ids.control, fn control ->
            second = %DesignNode{
              node_id: second_id,
              semantic_type: "heading",
              attributes: %{"tag" => "h4"}
            }

            %{control | children: control.children ++ [second]}
          end)

        second_value = %ValueBinding{
          value_binding_id: second_value_id,
          target_node_id: second_id,
          target_kind: :text,
          value_kind: :field,
          scope: :collection_item,
          value_key: "summary",
          collection_binding_id: "cb_cards",
          normalization_status: :normalized,
          modifier: %ValueModifier.None{}
        }

        %{
          document
          | value_bindings: Map.put(document.value_bindings, second_value_id, second_value)
        }
      end,
      component_contract_transform: fn contract ->
        [collection_input] = contract.collection_inputs

        collection_input = %{
          collection_input
          | item_fields:
              collection_input.item_fields ++
                [%ItemField{name: "summary", type: :string, semantic_purpose: "summary"}]
        }

        contract = %{
          contract
          | public_attrs:
              contract.public_attrs ++
                [
                  %Attr{
                    name: "secondary_heading_level",
                    type: :integer,
                    required: true,
                    semantic_purpose: "secondary heading level",
                    validation: %{"values" => [1, 2, 3, 4, 5, 6]}
                  }
                ],
            collection_inputs: [collection_input],
            binding_projections:
              contract.binding_projections ++
                [
                  %BindingProjection{
                    source_binding_kind: :value,
                    source_binding_id: second_value_id,
                    projection_kind: :collection_item_field,
                    source_collection_binding_id: "cb_cards",
                    item_field_name: "summary",
                    target_node_id: second_id
                  }
                ]
        }

        contract
      end,
      plan_transform: fn plan ->
        %{
          plan
          | render_projections:
              plan.render_projections ++
                [
                  %RenderProjection{
                    public_attr_name: "secondary_heading_level",
                    target_node_id: second_id,
                    render_role: :heading_level
                  }
                ]
        }
      end
    )
  end

  defp nested_carrier_tuple do
    ids = ids()
    nested_carrier_id = DesignNode.deterministic_id([1, 1, 1, 1, 1])

    valid_tuple(
      document_transform: fn document ->
        document =
          update_node(document, ids.control, fn control ->
            [carrier] = control.children

            wrapper = %DesignNode{
              node_id: ids.carrier,
              semantic_type: "container",
              children: [%{carrier | node_id: nested_carrier_id}]
            }

            %{control | children: [wrapper]}
          end)

        update_value_binding(document, "title-value", &%{&1 | target_node_id: nested_carrier_id})
      end,
      component_contract_transform: fn contract ->
        %{
          contract
          | binding_projections:
              Enum.map(contract.binding_projections, fn projection ->
                if projection.source_binding_id == "title-value",
                  do: %{projection | target_node_id: nested_carrier_id},
                  else: projection
              end)
        }
      end,
      plan_transform: fn plan ->
        %{
          plan
          | render_projections:
              Enum.map(plan.render_projections, &%{&1 | target_node_id: nested_carrier_id})
        }
      end
    )
  end

  defp with_link_binding(document, node_id) do
    binding = %ValueBinding{
      value_binding_id: "link-value",
      target_node_id: node_id,
      target_kind: :link_url,
      value_kind: :field,
      scope: :site,
      value_key: "url",
      normalization_status: :normalized,
      modifier: %ValueModifier.None{}
    }

    %{
      document
      | value_bindings: Map.put(document.value_bindings, binding.value_binding_id, binding)
    }
  end

  defp with_link_projection(contract, node_id) do
    %{
      contract
      | public_attrs:
          contract.public_attrs ++
            [%Attr{name: "outbound_url", type: :string, semantic_purpose: "outbound url"}],
        binding_projections:
          contract.binding_projections ++
            [
              %BindingProjection{
                source_binding_kind: :value,
                source_binding_id: "link-value",
                projection_kind: :scalar_attr,
                public_attr_name: "outbound_url",
                target_node_id: node_id
              }
            ]
    }
  end

  defp update_value_binding(document, id, update) do
    %{document | value_bindings: Map.update!(document.value_bindings, id, update)}
  end

  defp update_node(%DesignDocument{} = document, node_id, update) do
    %{document | root_nodes: update_nodes(document.root_nodes, node_id, update)}
  end

  defp update_nodes(nodes, node_id, update) do
    Enum.map(nodes, fn node ->
      node = if node.node_id == node_id, do: update.(node), else: node
      %{node | children: update_nodes(node.children, node_id, update)}
    end)
  end

  defp ids, do: ids(:default)

  defp ids(:default) do
    %{
      root: DesignNode.deterministic_id([1]),
      boundary: DesignNode.deterministic_id([1, 1]),
      control: DesignNode.deterministic_id([1, 1, 1]),
      carrier: DesignNode.deterministic_id([1, 1, 1, 1]),
      presentation_a: DesignNode.deterministic_id([1, 1, 2]),
      presentation_b: DesignNode.deterministic_id([1, 1, 3]),
      presentation_c: DesignNode.deterministic_id([1, 1, 4]),
      outside: DesignNode.deterministic_id([1, 2]),
      outside_control: DesignNode.deterministic_id([1, 2, 1]),
      outside_presentation_a: DesignNode.deterministic_id([1, 2, 2]),
      outside_presentation_b: DesignNode.deterministic_id([1, 2, 3])
    }
  end

  defp ids(:alternate) do
    %{
      root: DesignNode.deterministic_id([2]),
      boundary: DesignNode.deterministic_id([2, 1]),
      control: DesignNode.deterministic_id([2, 1, 1]),
      carrier: DesignNode.deterministic_id([2, 1, 1, 1]),
      presentation_a: DesignNode.deterministic_id([2, 1, 2]),
      presentation_b: DesignNode.deterministic_id([2, 1, 3]),
      presentation_c: DesignNode.deterministic_id([2, 1, 4]),
      outside: DesignNode.deterministic_id([2, 2]),
      outside_control: DesignNode.deterministic_id([2, 2, 1]),
      outside_presentation_a: DesignNode.deterministic_id([2, 2, 2]),
      outside_presentation_b: DesignNode.deterministic_id([2, 2, 3])
    }
  end
end
