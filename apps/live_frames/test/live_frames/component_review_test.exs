defmodule LiveFrames.ComponentReviewTest do
  use ExUnit.Case, async: true

  alias LiveFrames.ComponentReview
  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentContract.CollectionInput
  alias LiveFrames.ComponentContract.Diagnostic, as: ContractDiagnostic
  alias LiveFrames.ComponentContract.ItemField
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.Diagnostic
  alias LiveFrames.ComponentizationPlan.RenderProjection
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.ValueBinding

  @boundary_id DesignNode.deterministic_id([1])
  @heading_id DesignNode.deterministic_id([1, 1])
  @outside_id DesignNode.deterministic_id([2])

  defp document do
    DesignDocument.new(
      root_nodes: [
        %DesignNode{
          node_id: @boundary_id,
          semantic_type: "section",
          children: [%DesignNode{node_id: @heading_id, semantic_type: "heading"}]
        },
        %DesignNode{node_id: @outside_id, semantic_type: "paragraph"}
      ]
    )
  end

  defp candidate(contract_options \\ [], plan_options \\ [], design_document \\ document()) do
    contract =
      struct!(
        ComponentContract.new(
          contract_id: "review-candidate",
          category: :section,
          module_intent: "marketing_block",
          function_intent: "hero"
        ),
        contract_options
      )

    {:ok, fingerprint} = ComponentizationPlan.design_document_sha256(design_document)

    plan =
      struct!(
        %ComponentizationPlan{
          contract_id: contract.contract_id,
          design_document_sha256: fingerprint,
          boundary_node_id: @boundary_id
        },
        plan_options
      )

    {contract, plan, design_document}
  end

  defp attr(name, type \\ :string, options \\ []) do
    struct!(%Attr{name: name, type: type, semantic_purpose: name}, options)
  end

  defp text_projection(name, target \\ @heading_id) do
    %RenderProjection{public_attr_name: name, target_node_id: target, render_role: :text_content}
  end

  defp codes({:error, diagnostics}), do: Enum.map(diagnostics, & &1.code)

  test "proposed candidate approval passes both generation gates without changing inputs" do
    {contract, plan, design_document} = candidate()
    original_plan = plan
    original_document = design_document

    assert ComponentReview.validate_generation_prerequisites(contract, plan, design_document) ==
             :ok

    assert ComponentizationPlan.validate_generation_prerequisites(
             plan,
             contract,
             design_document
           ) == :ok

    assert {:ok, approved} = ComponentReview.approve(contract, plan, design_document)
    assert approved.approval_status == :approved
    assert ComponentContract.validate_for_generation(approved, design_document) == :ok
    assert ComponentizationPlan.validate_for_generation(plan, approved, design_document) == :ok
    assert contract.approval_status == :proposed
    assert plan == original_plan
    assert design_document == original_document
  end

  test "approval is available only from proposed" do
    for status <- [:needs_review, :approved, :rejected] do
      {contract, plan, design_document} = candidate(approval_status: status)

      if status == :needs_review do
        assert ComponentReview.validate_generation_prerequisites(contract, plan, design_document) ==
                 :ok
      end

      assert {:error, diagnostics} = ComponentReview.approve(contract, plan, design_document)
      assert Enum.any?(diagnostics, &(&1.code == "component_contract.approval_blocked"))
    end
  end

  test "proposed and needs_review candidates can be rejected" do
    for status <- [:proposed, :needs_review] do
      {contract, plan, design_document} = candidate(approval_status: status)

      assert {:ok, rejected} = ComponentReview.reject(contract, plan, design_document)
      assert rejected.approval_status == :rejected
      assert contract.approval_status == status
    end
  end

  test "approved and rejected candidates cannot be rejected again" do
    for status <- [:approved, :rejected] do
      {contract, plan, design_document} = candidate(approval_status: status)

      assert {:error, diagnostics} = ComponentReview.reject(contract, plan, design_document)
      assert Enum.any?(diagnostics, &(&1.code == "component_contract.approval_blocked"))
    end
  end

  test "any public attr blocks approval" do
    {contract, plan, design_document} =
      candidate(
        [public_attrs: [attr("title", :any)]],
        render_projections: [text_projection("title")]
      )

    assert {:error, diagnostics} = ComponentReview.approve(contract, plan, design_document)
    assert "componentization_plan.contract.mismatch" in codes({:error, diagnostics})
  end

  test "any collection ItemField blocks approval" do
    {contract, plan, design_document} =
      candidate(
        [
          public_attrs: [attr("items", :list)],
          collection_inputs: [
            %CollectionInput{
              source_collection_binding_id: "collection-1",
              public_attr_name: "items",
              item_fields: [%ItemField{name: "label", type: :any, semantic_purpose: "label"}]
            }
          ]
        ],
        render_projections: [text_projection("items")]
      )

    assert {:error, diagnostics} = ComponentReview.approve(contract, plan, design_document)
    assert "componentization_plan.contract.mismatch" in codes({:error, diagnostics})
  end

  test "generation module intent must use the token grammar" do
    {contract, plan, design_document} = candidate(module_intent: "Marketing-Block")

    assert ComponentContract.validate(contract) == :ok
    assert {:error, _diagnostics} = ComponentReview.approve(contract, plan, design_document)
  end

  test "generation function intent must use the token grammar" do
    {contract, plan, design_document} = candidate(function_intent: "Hero!")

    assert ComponentContract.validate(contract) == :ok
    assert {:error, _diagnostics} = ComponentReview.approve(contract, plan, design_document)
  end

  test "evidence-insufficient references block approval" do
    design_document = %{
      document()
      | value_bindings: %{
          "value-title" => %ValueBinding{
            value_binding_id: "value-title",
            target_node_id: @heading_id,
            target_kind: :text,
            value_kind: :field,
            scope: :site,
            value_key: "title",
            normalization_status: :evidence_insufficient,
            modifier_status: :opaque
          }
        }
    }

    {contract, plan, design_document} =
      candidate(
        [
          public_attrs: [attr("title")],
          binding_projections: [
            %BindingProjection{
              source_binding_kind: :value,
              source_binding_id: "value-title",
              projection_kind: :scalar_attr,
              public_attr_name: "title",
              target_node_id: @heading_id
            }
          ]
        ],
        [],
        design_document
      )

    assert {:error, diagnostics} = ComponentReview.approve(contract, plan, design_document)
    assert "componentization_plan.contract.mismatch" in codes({:error, diagnostics})

    assert {:error, prerequisite_diagnostics} =
             ComponentReview.validate_generation_prerequisites(contract, plan, design_document)

    assert "componentization_plan.contract.mismatch" in codes({:error, prerequisite_diagnostics})

    assert {:ok, %{approval_status: :rejected}} =
             ComponentReview.reject(contract, plan, design_document)
  end

  test "stored blocking Contract diagnostics block approval" do
    diagnostic = %ContractDiagnostic{
      code: "component_contract.fixture.blocker",
      severity: :error,
      message: "review required"
    }

    {contract, plan, design_document} = candidate(diagnostics: [diagnostic])

    assert {:error, _diagnostics} = ComponentReview.approve(contract, plan, design_document)
  end

  test "stored blocking Plan diagnostics block approval" do
    diagnostic = %Diagnostic{
      code: "componentization_plan.fixture.blocker",
      severity: :fatal,
      message: "review required"
    }

    {contract, plan, design_document} = candidate([], diagnostics: [diagnostic])

    assert {:error, _diagnostics} = ComponentReview.approve(contract, plan, design_document)
  end

  test "contract identity mismatch blocks approval and rejection" do
    {contract, plan, design_document} = candidate([], contract_id: "another-candidate")

    assert {:error, diagnostics} = ComponentReview.approve(contract, plan, design_document)
    assert "componentization_plan.contract.mismatch" in codes({:error, diagnostics})

    assert {:error, reject_diagnostics} = ComponentReview.reject(contract, plan, design_document)
    assert "componentization_plan.contract.mismatch" in codes({:error, reject_diagnostics})
  end

  test "DesignDocument fingerprint mismatch blocks approval and rejection" do
    {contract, plan, design_document} = candidate()
    changed_document = %{design_document | source_metadata: %{"revision" => "changed"}}

    assert {:error, diagnostics} = ComponentReview.approve(contract, plan, changed_document)
    assert "componentization_plan.design_document.mismatch" in codes({:error, diagnostics})

    assert {:error, reject_diagnostics} =
             ComponentReview.reject(contract, plan, changed_document)

    assert "componentization_plan.design_document.mismatch" in codes({:error, reject_diagnostics})
  end

  test "indexed Plan reference failures block approval" do
    {contract, plan, design_document} =
      candidate(
        [public_attrs: [attr("title")]],
        render_projections: [text_projection("title", @outside_id)]
      )

    assert {:error, diagnostics} = ComponentReview.approve(contract, plan, design_document)

    assert "componentization_plan.render_projection.target_outside_boundary" in codes(
             {:error, diagnostics}
           )
  end

  test "rejection remains available when generation prerequisites fail" do
    {any_attr_contract, any_attr_plan, any_attr_document} =
      candidate(
        [public_attrs: [attr("title", :any)]],
        render_projections: [text_projection("title")]
      )

    blocker = %Diagnostic{
      code: "componentization_plan.fixture.blocker",
      severity: :error,
      message: "generation blocker"
    }

    {plan_blocked_contract, plan_blocked_plan, plan_blocked_document} =
      candidate([], diagnostics: [blocker])

    candidates = [
      {any_attr_contract, any_attr_plan, any_attr_document},
      {plan_blocked_contract, plan_blocked_plan, plan_blocked_document}
    ]

    for {contract, plan, design_document} <- candidates do
      assert {:error, _} =
               ComponentReview.validate_generation_prerequisites(contract, plan, design_document)

      assert {:ok, %{approval_status: :rejected}} =
               ComponentReview.reject(contract, plan, design_document)
    end
  end

  test "rejection rejects a needs_review candidate with blockers" do
    diagnostic = %ContractDiagnostic{
      code: "component_contract.fixture.blocker",
      severity: :error,
      message: "review required"
    }

    {contract, plan, design_document} =
      candidate(approval_status: :needs_review, diagnostics: [diagnostic])

    assert {:ok, %{approval_status: :rejected}} =
             ComponentReview.reject(contract, plan, design_document)
  end

  test "malformed values, improper lists and invalid UTF-8 return errors" do
    assert {:error, _} = ComponentReview.approve(%{}, %{}, %{})
    assert {:error, _} = ComponentReview.reject(%{}, %{}, %{})

    {contract, plan, design_document} = candidate()
    improper_contract = %{contract | public_attrs: [%Attr{name: "title"} | :tail]}
    improper_plan = %{plan | render_projections: [text_projection("title") | :tail]}
    invalid_utf8_contract = %{contract | module_intent: <<255>>}

    for {bad_contract, bad_plan, bad_document} <- [
          {improper_contract, plan, design_document},
          {contract, improper_plan, design_document},
          {invalid_utf8_contract, plan, design_document}
        ] do
      assert {:error, _} =
               ComponentReview.validate_generation_prerequisites(
                 bad_contract,
                 bad_plan,
                 bad_document
               )

      assert {:error, _} = ComponentReview.approve(bad_contract, bad_plan, bad_document)
      assert {:error, _} = ComponentReview.reject(bad_contract, bad_plan, bad_document)
    end
  end

  test "equivalent approval calls return equal contracts" do
    {contract, plan, design_document} = candidate()

    assert ComponentReview.approve(contract, plan, design_document) ==
             ComponentReview.approve(contract, plan, design_document)
  end
end
