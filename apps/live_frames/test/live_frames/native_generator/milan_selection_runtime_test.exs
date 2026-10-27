defmodule LiveFrames.NativeGenerator.MilanSelectionRuntimeTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveFrames.Behavior.Binding
  alias LiveFrames.Behavior.Binding.ControlledTarget
  alias LiveFrames.Behavior.Binding.PrimitiveRef
  alias LiveFrames.Behavior.Binding.Trigger
  alias LiveFrames.Behavior.BindingIdentity
  alias LiveFrames.Behavior.Contract
  alias LiveFrames.Behavior.ReviewResult, as: BehaviorReviewResult
  alias LiveFrames.Behavior.Serializer
  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentContract.CollectionInput
  alias LiveFrames.ComponentContract.ItemField
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.RenderProjection
  alias LiveFrames.ComponentReviewResult
  alias LiveFrames.IR.CollectionBinding
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Identity
  alias LiveFrames.IR.ValueBinding
  alias LiveFrames.NativeGenerator

  @boundary_id DesignNode.deterministic_id([1])
  @control_id DesignNode.deterministic_id([1, 1])
  @heading_id DesignNode.deterministic_id([1, 1, 1])
  @presentation_0_id DesignNode.deterministic_id([1, 2])
  @presentation_1_id DesignNode.deterministic_id([1, 3])

  test "authorized Selection emits one colocated root hook and no JavaScript artifact" do
    {bundle, source} = generated_selection()

    assert length(:binary.matches(source, ~s|phx-hook=".Selection"|)) == 1

    assert source =~
             ~r/<section\b[^>]*phx-hook="\.Selection"[^>]*data-lf-selection-root="true"/

    assert length(:binary.matches(source, ~s|name=".Selection"|)) == 1
    assert source =~ "type={Phoenix.LiveView.ColocatedHook}"
    refute source =~ ~s|name=".Selection" runtime|
    assert Enum.map(bundle.artifacts, & &1.kind) == [:stylesheet, :elixir_module]

    html = render_generated_component(source)
    assert html =~ ~s|phx-hook="LiveFrames.GeneratedMilanSelectionRuntime|
    assert length(:binary.matches(html, ~s|data-lf-selection-root="true"|)) == 1
    refute html =~ "hidden"
  end

  test "authorized Selection marks presentation roots in authority order" do
    {_bundle, source} = generated_selection()

    assert length(Regex.scan(~r/\sdata-lf-selection-presentation="0"/, source)) == 1
    assert length(Regex.scan(~r/\sdata-lf-selection-presentation="1"/, source)) == 1
    refute source =~ "data-lf-selection-index"
    assert source =~ ~s|data-lf-selection-control="true"|
    assert source =~ ~s|data-lf-selection-state="unselected"|
    assert source =~ ~s|data-lf-selection-activate="true"|
    assert source =~ ~s|aria-pressed="false"|
  end

  test "ordinary generation has no Selection runtime and no Tabs or server behavior" do
    {contract, _plan, document, _behavior, _behavior_review, _component_review, _review_id} =
      selection_tuple(ordinary?: true)

    assert {:ok, bundle} =
             NativeGenerator.generate(contract, ordinary_plan(contract, document), document)

    source = Enum.find(bundle.artifacts, &(&1.kind == :elixir_module)).content

    refute source =~ "phx-hook"
    assert length(:binary.matches(source, "phx-hook")) == 0
    assert length(:binary.matches(source, "data-lf-selection-root")) == 0
    refute source =~ "ColocatedHook"
    refute source =~ "setInterval"
    refute source =~ "data-lf-selection"
    refute source =~ "pushEvent"
    refute source =~ "phx-click"
    refute source =~ "role=\"tab"
    refute source =~ "aria-selected"
    refute source =~ "aria-controls"
    refute source =~ "tabpanel"
  end

  test "Selection hook source uses only package selectors and browser-local state" do
    {_bundle, source} = generated_selection()

    assert source =~ "UNMOUNTED"
    assert source =~ "ACTIVE"
    assert source =~ "UNAVAILABLE"
    assert source =~ "DESTROYED"
    assert source =~ "RUNNING"
    assert source =~ "STOPPED_BY_USER"
    assert source =~ "SUPPRESSED_REDUCED_MOTION"
    assert source =~ "SUSPENDED_UNAVAILABLE"
    assert source =~ "SUSPENDED_DISCONNECTED"
    assert source =~ "element.closest(ROOT_SELECTOR) === hook.el"
    assert source =~ "carrier.closest(ROOT_SELECTOR) !== hook.el"
    assert source =~ "control.closest(ROOT_SELECTOR) !== hook.el"
    assert source =~ "ownedElements(hook, ACTIVATE_SELECTOR)"
    assert source =~ "controlPositions.get(carrier.closest(CONTROL_SELECTOR))"
    assert length(:binary.matches(source, "setInterval(")) == 1
    assert source =~ "5000"
    assert source =~ "prefers-reduced-motion: reduce"
    refute source =~ "document.querySelector"
    refute source =~ "document.querySelectorAll"
    refute source =~ "stopPropagation"
    refute source =~ "stopImmediatePropagation"

    package_selectors =
      Regex.scan(~r/const [A-Z0-9_]+_SELECTOR = '([^']+)'/, source, capture: :all_but_first)
      |> Enum.map(&hd/1)

    assert Enum.sort(package_selectors) ==
             Enum.sort([
               ~s([data-lf-selection-root="true"]),
               ~s([data-lf-selection-control="true"]),
               ~s([data-lf-selection-activate="true"]),
               ~s([data-lf-selection-presentation="0"]),
               ~s([data-lf-selection-presentation="1"])
             ])

    refute source =~ ~r/(?:querySelectorAll|closest)\s*\(\s*['"]/
    refute source =~ "new Function"
    refute source =~ "eval("
    refute source =~ "pushEvent"
    refute source =~ "pushEventTo"
    refute source =~ "handle_event"
    refute source =~ "PubSub"
    refute source =~ "GenServer"
    refute source =~ "Redis"
    refute source =~ "setTimeout"
    refute source =~ "role=\"tab"
    refute source =~ "aria-selected"
    refute source =~ "aria-controls"
    refute source =~ "tabindex"
  end

  defp generated_selection do
    {contract, plan, document, behavior, behavior_review, component_review, review_id} =
      selection_tuple()

    assert {:ok, bundle} =
             NativeGenerator.generate(
               contract,
               plan,
               document,
               behavior,
               behavior_review,
               component_review,
               review_id
             )

    source = Enum.find(bundle.artifacts, &(&1.kind == :elixir_module)).content
    {bundle, source}
  end

  defp render_generated_component(source) do
    module_name = "LiveFrames.GeneratedMilanSelectionRuntime#{System.unique_integer([:positive])}"

    compiled =
      String.replace(source, "LiveFrames.Components.Sections.SelectionRuntime", module_name)

    [{module, _binary}] = Code.compile_string(compiled)

    try do
      render_component(Function.capture(module, :selection_runtime, 1), %{
        id: "selection-root",
        items: [%{"title" => "Synthetic title"}],
        heading_level: 3
      })
    after
      :code.delete(module)
    end
  end

  defp selection_tuple(opts \\ []) do
    ordinary? = Keyword.get(opts, :ordinary?, false)

    control = %DesignNode{
      node_id: @control_id,
      semantic_type: "generic",
      attributes: %{"tag" => if(ordinary?, do: "div", else: "button")},
      children: [
        %DesignNode{
          node_id: @heading_id,
          semantic_type: "heading",
          attributes: %{"tag" => "h3"}
        }
      ]
    }

    boundary = %DesignNode{
      node_id: @boundary_id,
      semantic_type: "section",
      children: [
        control,
        %DesignNode{node_id: @presentation_0_id, semantic_type: "paragraph"},
        %DesignNode{node_id: @presentation_1_id, semantic_type: "paragraph"}
      ]
    }

    document = %DesignDocument{
      root_nodes: [boundary],
      collection_bindings: %{
        "cb_items" => %CollectionBinding{
          collection_binding_id: "cb_items",
          owner_node_id: @boundary_id,
          repeat_root_node_id: @boundary_id
        }
      },
      value_bindings: %{
        "vb_title" => %ValueBinding{
          value_binding_id: "vb_title",
          target_node_id: @heading_id,
          target_kind: :text,
          value_kind: :field,
          scope: :collection_item,
          collection_binding_id: "cb_items",
          value_key: "title",
          normalization_status: :normalized,
          modifier: %LiveFrames.IR.ValueModifier.None{}
        }
      }
    }

    {:ok, document_identity} = Identity.from_document(document)

    {:ok, behavior} =
      BindingIdentity.assign(%Contract{
        design_document_identity: document_identity,
        bindings: [
          %Binding{
            primitive_ref: %PrimitiveRef{kind: "selection", definition_version: "1.0.0"},
            owner_node_id: @boundary_id,
            binding_role: "primary",
            primitive_policy_values: %{
              "alignment" => "position",
              "advance_boundary" => "wrap"
            },
            triggers: [%Trigger{kind: "activate", origin_node_id: @control_id}],
            controlled_targets: [
              %ControlledTarget{role: "control_collection", node_id: @control_id},
              %ControlledTarget{
                role: "presentation_collection",
                node_id: @presentation_0_id
              },
              %ControlledTarget{
                role: "presentation_collection",
                node_id: @presentation_1_id
              }
            ]
          }
        ]
      })

    {:ok, behavior_digest} = Serializer.digest(behavior)

    behavior_review = %BehaviorReviewResult{
      review_format_version: "1.0.0",
      design_document_identity: document_identity,
      behavior_contract_digest_algorithm: Serializer.algorithm(),
      behavior_contract_digest: behavior_digest,
      decision: "approved",
      reviewer_identity: "reviewer:synthetic-selection-runtime",
      reviewed_at: "2026-10-20T00:00:00.000000Z",
      evidence_refs: ["synthetic-selection-runtime-evidence"]
    }

    contract = %ComponentContract{
      contract_id: "synthetic-selection-runtime-contract",
      category: :section,
      module_intent: "selection_runtime",
      function_intent: "selection_runtime",
      approval_status: :approved,
      public_attrs: [
        %Attr{name: "id", type: :string, required: true, semantic_purpose: "root id"},
        %Attr{name: "rest", type: :global, semantic_purpose: "root attrs"},
        %Attr{name: "items", type: :list, required: true, semantic_purpose: "items"},
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
          source_collection_binding_id: "cb_items",
          public_attr_name: "items",
          item_fields: [%ItemField{name: "title", type: :string, semantic_purpose: "title"}]
        }
      ],
      binding_projections: [
        %BindingProjection{
          source_binding_kind: :collection,
          source_binding_id: "cb_items",
          projection_kind: :collection_attr,
          public_attr_name: "items",
          source_collection_binding_id: "cb_items",
          target_node_id: @boundary_id
        },
        %BindingProjection{
          source_binding_kind: :value,
          source_binding_id: "vb_title",
          projection_kind: :collection_item_field,
          source_collection_binding_id: "cb_items",
          item_field_name: "title",
          target_node_id: @heading_id
        }
      ]
    }

    {:ok, fingerprint} = ComponentizationPlan.design_document_sha256(document)

    plan = %ComponentizationPlan{
      contract_id: contract.contract_id,
      design_document_sha256: fingerprint,
      boundary_node_id: @boundary_id,
      render_projections: [
        %RenderProjection{
          public_attr_name: "id",
          render_role: :root_id,
          target_node_id: @boundary_id
        },
        %RenderProjection{
          public_attr_name: "rest",
          render_role: :root_global_attrs,
          target_node_id: @boundary_id
        },
        %RenderProjection{
          public_attr_name: "heading_level",
          render_role: :heading_level,
          target_node_id: @heading_id
        }
      ]
    }

    {:ok, component_contract_bytes} = ComponentContract.encode(contract)
    {:ok, plan_bytes} = ComponentizationPlan.encode(plan)

    component_review = %ComponentReviewResult{
      review_format_version: "1.0.0",
      component_contract_id: contract.contract_id,
      component_contract_digest_algorithm: "sha-256",
      component_contract_digest: sha256(component_contract_bytes),
      design_document_sha256: fingerprint,
      componentization_plan_digest_algorithm: "sha-256",
      componentization_plan_digest: sha256(plan_bytes),
      decision: "approved",
      reviewer_identity: "reviewer:synthetic-selection-component",
      reviewed_at: "2026-10-20T00:00:00.000000Z",
      evidence_refs: ["synthetic-selection-component-evidence"]
    }

    {:ok, review_id} = ComponentReviewResult.id(component_review)

    {contract, plan, document, behavior, behavior_review, component_review, review_id}
  end

  defp ordinary_plan(contract, document) do
    {:ok, fingerprint} = ComponentizationPlan.design_document_sha256(document)

    %ComponentizationPlan{
      contract_id: contract.contract_id,
      design_document_sha256: fingerprint,
      boundary_node_id: @boundary_id,
      render_projections: [
        %RenderProjection{
          public_attr_name: "id",
          render_role: :root_id,
          target_node_id: @boundary_id
        },
        %RenderProjection{
          public_attr_name: "rest",
          render_role: :root_global_attrs,
          target_node_id: @boundary_id
        },
        %RenderProjection{
          public_attr_name: "heading_level",
          render_role: :heading_level,
          target_node_id: @heading_id
        }
      ]
    }
  end

  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
end
