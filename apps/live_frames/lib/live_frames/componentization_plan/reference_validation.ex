defmodule LiveFrames.ComponentizationPlan.ReferenceValidation do
  @moduledoc false

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentContract.CollectionInput
  alias LiveFrames.ComponentContract.Diagnostic, as: ContractDiagnostic
  alias LiveFrames.ComponentContract.ItemField
  alias LiveFrames.ComponentContract.Slot
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.Diagnostic
  alias LiveFrames.ComponentizationPlan.Json
  alias LiveFrames.ComponentizationPlan.NodeDisposition
  alias LiveFrames.ComponentizationPlan.RenderProjection
  alias LiveFrames.ComponentizationPlan.Validation
  alias LiveFrames.Behavior.BindingContainment
  alias LiveFrames.Behavior.Contract, as: BehaviorContract
  alias LiveFrames.Behavior.NativeRealizationAuthority
  alias LiveFrames.Behavior.ReviewResult
  alias LiveFrames.Behavior.Serializer, as: BehaviorSerializer
  alias LiveFrames.IR.CollectionBinding
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Identity
  alias LiveFrames.IR.ValueBinding

  @role_types %{
    text_content: :string,
    asset_src: :string,
    asset_alt: :string,
    link_url: :string,
    heading_level: :integer,
    root_id: :string,
    root_class: :string,
    root_global_attrs: :global
  }

  @root_roles [:root_id, :root_class, :root_global_attrs]
  @node_disposition_prefix "componentization_plan.node_disposition."

  @spec validate(term(), term(), term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate(plan, component_contract, design_document) do
    if dispositions_present?(plan) do
      validate_disposition_references(plan, component_contract, design_document, :missing)
    else
      case preflight(plan, component_contract, design_document) do
        {:ok, plan, component_contract, design_document} ->
          validate_indexed(plan, component_contract, design_document)

        {:error, diagnostics} ->
          finish(diagnostics)
      end
    end
  end

  @spec validate_with_behavior_authority(term(), term(), term(), term(), term()) ::
          :ok | {:error, [Diagnostic.t()]}
  def validate_with_behavior_authority(
        plan,
        component_contract,
        design_document,
        behavior_contract,
        selected_behavior_review_result
      ) do
    if dispositions_present?(plan) do
      validate_disposition_references(
        plan,
        component_contract,
        design_document,
        {:provided, behavior_contract, selected_behavior_review_result}
      )
    else
      validate(plan, component_contract, design_document)
    end
  end

  @spec validate_generation_prerequisites(term(), term(), term()) ::
          :ok | {:error, [Diagnostic.t()]}
  def validate_generation_prerequisites(plan, component_contract, design_document) do
    if dispositions_present?(plan) do
      validate_generation_prerequisites_without_authority(
        plan,
        component_contract,
        design_document
      )
    else
      validate_generation_prerequisites_ordinary(plan, component_contract, design_document)
    end
  end

  defp validate_generation_prerequisites_ordinary(
         plan,
         component_contract,
         design_document,
         native_realization_authority \\ nil
       ) do
    case preflight_generation(plan, component_contract, design_document) do
      {:ok, plan, component_contract, design_document} ->
        reference_result =
          validate_indexed(
            plan,
            component_contract,
            design_document,
            true,
            nil,
            [],
            native_realization_authority
          )

        stored_blockers =
          Enum.filter(plan.diagnostics, fn diagnostic ->
            diagnostic.severity in Diagnostic.blocking_severities()
          end)

        diagnostics = [] |> append_result(reference_result) |> Kernel.++(stored_blockers)
        finish(diagnostics)

      {:error, diagnostics} ->
        finish(diagnostics)
    end
  rescue
    _error ->
      finish([
        error(
          "componentization_plan.plan.invalid",
          "generation prerequisite inputs are malformed"
        )
      ])
  catch
    _kind, _reason ->
      finish([
        error(
          "componentization_plan.plan.invalid",
          "generation prerequisite inputs are malformed"
        )
      ])
  end

  defp validate_generation_prerequisites_without_authority(
         plan,
         component_contract,
         design_document
       ) do
    case preflight_disposition_generation(plan, component_contract, design_document) do
      {:ok, plan, component_contract, design_document, intrinsic_diagnostics} ->
        reference_result =
          validate_indexed(
            plan,
            component_contract,
            design_document,
            true,
            :missing,
            intrinsic_diagnostics
          )

        stored_blockers =
          Enum.filter(plan.diagnostics, fn diagnostic ->
            diagnostic.severity in Diagnostic.blocking_severities()
          end)

        diagnostics = [] |> append_result(reference_result) |> Kernel.++(stored_blockers)
        finish(diagnostics)

      {:error, diagnostics} ->
        finish(diagnostics)
    end
  rescue
    _error ->
      finish([
        error(
          "componentization_plan.plan.invalid",
          "generation prerequisite inputs are malformed"
        )
      ])
  catch
    _kind, _reason ->
      finish([
        error(
          "componentization_plan.plan.invalid",
          "generation prerequisite inputs are malformed"
        )
      ])
  end

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
      ) do
    validate_generation_prerequisites_with_behavior_authority_internal(
      plan,
      component_contract,
      design_document,
      behavior_contract,
      selected_behavior_review_result,
      nil
    )
  end

  @spec validate_generation_prerequisites_with_behavior_and_native_realization_authority(
          term(),
          term(),
          term(),
          term(),
          term(),
          term()
        ) :: :ok | {:error, [Diagnostic.t()]}
  def validate_generation_prerequisites_with_behavior_and_native_realization_authority(
        plan,
        approved_component_contract,
        design_document,
        behavior_contract,
        selected_behavior_review_result,
        native_realization_authority
      ) do
    case validate_native_realization_authority_tuple(
           native_realization_authority,
           approved_component_contract,
           plan,
           design_document,
           behavior_contract,
           selected_behavior_review_result
         ) do
      :ok ->
        validate_generation_prerequisites_with_behavior_authority_internal(
          plan,
          approved_component_contract,
          design_document,
          behavior_contract,
          selected_behavior_review_result,
          native_realization_authority
        )

      {:error, diagnostic} ->
        {:error, [diagnostic]}
    end
  end

  defp validate_generation_prerequisites_with_behavior_authority_internal(
         plan,
         component_contract,
         design_document,
         behavior_contract,
         selected_behavior_review_result,
         native_realization_authority
       ) do
    if dispositions_present?(plan) do
      case preflight_disposition_generation(plan, component_contract, design_document) do
        {:ok, plan, component_contract, design_document, intrinsic_diagnostics} ->
          authority =
            derive_disposition_authority(
              design_document,
              behavior_contract,
              selected_behavior_review_result
            )

          reference_result =
            validate_indexed(
              plan,
              component_contract,
              design_document,
              true,
              authority,
              intrinsic_diagnostics,
              native_realization_authority
            )

          stored_blockers =
            plan.diagnostics
            |> Enum.filter(&(&1.severity in Diagnostic.blocking_severities()))
            |> Enum.reject(&revalidatable_disposition_blocker?/1)

          diagnostics = [] |> append_result(reference_result) |> Kernel.++(stored_blockers)
          finish(diagnostics)

        {:error, diagnostics} ->
          finish(diagnostics)
      end
    else
      validate_generation_prerequisites_ordinary(
        plan,
        component_contract,
        design_document,
        native_realization_authority
      )
    end
  rescue
    _error ->
      finish([
        error(
          "componentization_plan.plan.invalid",
          "generation prerequisite inputs are malformed"
        )
      ])
  catch
    _kind, _reason ->
      finish([
        error(
          "componentization_plan.plan.invalid",
          "generation prerequisite inputs are malformed"
        )
      ])
  end

  @spec validate_for_generation(term(), term(), term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate_for_generation(plan, component_contract, design_document) do
    prerequisite_result =
      validate_generation_prerequisites(plan, component_contract, design_document)

    approval_result = contract_approval_result(component_contract)

    diagnostics =
      []
      |> append_result(prerequisite_result)
      |> append_contract_gate(approval_result)

    if diagnostics == [], do: :ok, else: finish([generation_blocked(diagnostics) | diagnostics])
  rescue
    _error ->
      finish([
        error("componentization_plan.generation_blocked", "generation inputs are malformed")
      ])
  catch
    _kind, _reason ->
      finish([
        error("componentization_plan.generation_blocked", "generation inputs are malformed")
      ])
  end

  @spec validate_for_generation_with_behavior_authority(term(), term(), term(), term(), term()) ::
          :ok | {:error, [Diagnostic.t()]}
  def validate_for_generation_with_behavior_authority(
        plan,
        approved_component_contract,
        design_document,
        behavior_contract,
        selected_behavior_review_result
      ) do
    prerequisite_result =
      validate_generation_prerequisites_with_behavior_authority(
        plan,
        approved_component_contract,
        design_document,
        behavior_contract,
        selected_behavior_review_result
      )

    approval_result = contract_approval_result(approved_component_contract)

    diagnostics =
      []
      |> append_result(prerequisite_result)
      |> append_contract_gate(approval_result)

    if diagnostics == [], do: :ok, else: finish([generation_blocked(diagnostics) | diagnostics])
  rescue
    _error ->
      finish([
        error("componentization_plan.generation_blocked", "generation inputs are malformed")
      ])
  catch
    _kind, _reason ->
      finish([
        error("componentization_plan.generation_blocked", "generation inputs are malformed")
      ])
  end

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
      ) do
    case validate_native_realization_authority_tuple(
           native_realization_authority,
           approved_component_contract,
           plan,
           design_document,
           behavior_contract,
           selected_behavior_review_result
         ) do
      :ok ->
        prerequisite_result =
          validate_generation_prerequisites_with_behavior_and_native_realization_authority(
            plan,
            approved_component_contract,
            design_document,
            behavior_contract,
            selected_behavior_review_result,
            native_realization_authority
          )

        approval_result = contract_approval_result(approved_component_contract)

        diagnostics =
          []
          |> append_result(prerequisite_result)
          |> append_contract_gate(approval_result)

        if diagnostics == [],
          do: :ok,
          else: finish([generation_blocked(diagnostics) | diagnostics])

      {:error, diagnostic} ->
        {:error, [diagnostic]}
    end
  rescue
    _error ->
      finish([
        error("componentization_plan.generation_blocked", "generation inputs are malformed")
      ])
  catch
    _kind, _reason ->
      finish([
        error("componentization_plan.generation_blocked", "generation inputs are malformed")
      ])
  end

  defp validate_native_realization_authority_tuple(
         %NativeRealizationAuthority{} = authority,
         %ComponentContract{contract_id: component_contract_id},
         %ComponentizationPlan{} = plan,
         design_document,
         %BehaviorContract{bindings: bindings} = behavior_contract,
         selected_behavior_review_result
       ) do
    with {:ok, document_identity} <- Identity.from_document(design_document),
         {:ok, behavior_contract_digest} <- BehaviorSerializer.digest(behavior_contract),
         {:ok, behavior_review_result_id} <- ReviewResult.id(selected_behavior_review_result),
         true <- authority.component_contract_id == component_contract_id,
         true <- authority.plan_contract_id == plan.contract_id,
         true <- authority.plan_design_document_sha256 == plan.design_document_sha256,
         true <- authority.design_document_identity == document_identity,
         true <- authority.design_document_identity.digest == plan.design_document_sha256,
         true <- authority.boundary_node_id == plan.boundary_node_id,
         true <- authority.behavior_contract_digest == behavior_contract_digest,
         true <- authority.behavior_review_result_id == behavior_review_result_id,
         true <- behavior_binding_count(bindings, authority.behavior_binding_id) == 1 do
      :ok
    else
      _ -> {:error, native_realization_authority_mismatch()}
    end
  rescue
    _error -> {:error, native_realization_authority_mismatch()}
  catch
    _kind, _reason -> {:error, native_realization_authority_mismatch()}
  end

  defp validate_native_realization_authority_tuple(
         _authority,
         _component_contract,
         _plan,
         _design_document,
         _behavior_contract,
         _selected_behavior_review_result
       ),
       do: {:error, native_realization_authority_mismatch()}

  defp behavior_binding_count(bindings, binding_id) when is_list(bindings) do
    Enum.count(bindings, fn
      %{binding_id: candidate_id} -> candidate_id == binding_id
      _binding -> false
    end)
  end

  defp behavior_binding_count(_bindings, _binding_id), do: 0

  defp native_realization_authority_mismatch do
    error(
      "componentization_plan.native_generation.realization_authority_mismatch",
      "transient NativeRealizationAuthority does not match these generation inputs"
    )
  end

  defp validate_disposition_references(plan, component_contract, design_document, authority_input) do
    case preflight_disposition(plan, component_contract, design_document) do
      {:ok, plan, component_contract, design_document, intrinsic_diagnostics} ->
        authority =
          case authority_input do
            :missing ->
              :missing

            {:provided, behavior_contract, selected_review} ->
              derive_disposition_authority(design_document, behavior_contract, selected_review)
          end

        validate_indexed(
          plan,
          component_contract,
          design_document,
          false,
          authority,
          intrinsic_diagnostics
        )

      {:error, diagnostics} ->
        finish(diagnostics)
    end
  rescue
    _error ->
      finish([
        error("componentization_plan.plan.invalid", "reference inputs failed closed validation")
      ])
  catch
    _kind, _reason ->
      finish([
        error("componentization_plan.plan.invalid", "reference inputs failed closed validation")
      ])
  end

  defp preflight_disposition(plan, component_contract, design_document) do
    with {:ok, intrinsic_diagnostics} <- disposition_intrinsic_diagnostics(plan),
         {:ok, plan, component_contract, design_document} <-
           preflight_contract(plan, component_contract, design_document) do
      {:ok, plan, component_contract, design_document, intrinsic_diagnostics}
    end
  end

  defp preflight_disposition_generation(plan, component_contract, design_document) do
    with {:ok, intrinsic_diagnostics} <- disposition_intrinsic_diagnostics(plan),
         {:ok, plan, component_contract, design_document} <-
           preflight_generation_document(plan, component_contract, design_document) do
      {:ok, plan, component_contract, design_document, intrinsic_diagnostics}
    end
  end

  defp disposition_intrinsic_diagnostics(plan) do
    case Validation.validate(plan) do
      :ok ->
        {:ok, []}

      {:error, diagnostics} ->
        if Enum.all?(diagnostics, &disposition_intrinsic_diagnostic?/1) do
          {:ok, diagnostics}
        else
          {:error, diagnostics}
        end
    end
  rescue
    _error ->
      {:error, [error("componentization_plan.plan.invalid", "plan failed intrinsic validation")]}
  end

  defp disposition_intrinsic_diagnostic?(%Diagnostic{code: code}) when is_binary(code),
    do: String.starts_with?(code, @node_disposition_prefix)

  defp disposition_intrinsic_diagnostic?(_diagnostic), do: false

  defp derive_disposition_authority(design_document, behavior_contract, selected_review) do
    binding_counts = behavior_binding_counts(behavior_contract)
    digest_result = BehaviorSerializer.digest(behavior_contract)
    approval_result = ReviewResult.require_approved([selected_review], behavior_contract)
    review_id_result = ReviewResult.id(selected_review)

    reference_result = BindingContainment.reference_index(design_document, behavior_contract)

    valid? =
      match?({:ok, _digest}, digest_result) and
        match?({:ok, _review}, approval_result) and
        match?({:ok, _review_id}, review_id_result) and
        match?({:ok, _reference_index}, reference_result)

    %{
      authority_status: if(valid?, do: :valid, else: :invalid),
      behavior_contract_digest: result_value(digest_result),
      behavior_review_id: result_value(review_id_result),
      binding_counts: binding_counts,
      reference_index: result_value(reference_result) || %{}
    }
  rescue
    _error ->
      %{
        authority_status: :invalid,
        behavior_contract_digest: nil,
        behavior_review_id: nil,
        binding_counts: behavior_binding_counts(behavior_contract),
        reference_index: %{}
      }
  end

  defp behavior_binding_counts(%{bindings: bindings}) when is_list(bindings) do
    if proper_list?(bindings) do
      Enum.reduce(bindings, %{}, fn
        %{binding_id: binding_id}, counts when not is_nil(binding_id) ->
          Map.update(counts, binding_id, 1, &(&1 + 1))

        _binding, counts ->
          counts
      end)
    else
      %{}
    end
  rescue
    _error -> %{}
  end

  defp behavior_binding_counts(_behavior_contract), do: %{}

  defp result_value({:ok, value}), do: value
  defp result_value(_result), do: nil

  defp dispositions_present?(%ComponentizationPlan{node_dispositions: []}), do: false
  defp dispositions_present?(%ComponentizationPlan{}), do: true
  defp dispositions_present?(_plan), do: false

  defp revalidatable_disposition_blocker?(%Diagnostic{
         code: "componentization_plan.unsupported_node"
       }),
       do: true

  defp revalidatable_disposition_blocker?(%Diagnostic{code: code}) when is_binary(code),
    do: String.starts_with?(code, @node_disposition_prefix)

  defp revalidatable_disposition_blocker?(_diagnostic), do: false

  defp preflight_generation(plan, component_contract, design_document) do
    case Validation.validate(plan) do
      :ok ->
        preflight_generation_document(plan, component_contract, design_document)

      {:error, diagnostics} ->
        {:error, diagnostics}
    end
  rescue
    _error ->
      {:error, [error("componentization_plan.plan.invalid", "plan failed intrinsic validation")]}
  end

  defp preflight_generation_document(plan, component_contract, design_document) do
    case LiveFrames.IR.validate(design_document) do
      :ok ->
        preflight_generation_fingerprint(plan, component_contract, design_document)

      {:error, diagnostics} ->
        {:error,
         [
           upstream_error(
             "componentization_plan.design_document.fingerprint_invalid",
             "DesignDocument failed IR validation",
             diagnostics
           )
         ]}
    end
  end

  defp preflight_generation_fingerprint(plan, component_contract, design_document) do
    case ComponentizationPlan.design_document_sha256(design_document) do
      {:ok, fingerprint} when fingerprint != plan.design_document_sha256 ->
        {:error,
         [
           error_at(
             "componentization_plan.design_document.mismatch",
             "plan fingerprint does not match the supplied DesignDocument",
             "design_document_sha256"
           )
         ]}

      {:ok, _fingerprint} ->
        preflight_generation_contract(plan, component_contract, design_document)

      {:error, diagnostics} ->
        {:error, diagnostics}
    end
  end

  defp preflight_generation_contract(plan, component_contract, design_document) do
    case ComponentContract.validate_generation_prerequisites(component_contract, design_document) do
      :ok when plan.contract_id == component_contract.contract_id ->
        {:ok, plan, component_contract, design_document}

      :ok ->
        {:error,
         [
           error_at(
             "componentization_plan.contract.mismatch",
             "plan contract_id does not match the supplied ComponentContract",
             "contract_id"
           )
         ]}

      {:error, diagnostics} ->
        {:error,
         [
           upstream_error(
             "componentization_plan.contract.mismatch",
             "ComponentContract is not generation-eligible",
             diagnostics
           )
         ]}
    end
  end

  defp preflight(plan, component_contract, design_document) do
    case Validation.validate(plan) do
      :ok ->
        preflight_contract(plan, component_contract, design_document)

      {:error, diagnostics} ->
        {:error, diagnostics}
    end
  rescue
    _error ->
      {:error, [error("componentization_plan.plan.invalid", "plan failed intrinsic validation")]}
  end

  defp preflight_contract(plan, component_contract, design_document) do
    case ComponentContract.validate(component_contract) do
      :ok ->
        preflight_document(plan, component_contract, design_document)

      {:error, diagnostics} ->
        {:error,
         [
           upstream_error(
             "componentization_plan.contract.mismatch",
             "ComponentContract failed intrinsic validation",
             diagnostics
           )
         ]}
    end
  end

  defp preflight_document(plan, component_contract, design_document) do
    case LiveFrames.IR.validate(design_document) do
      :ok ->
        preflight_fingerprint(plan, component_contract, design_document)

      {:error, diagnostics} ->
        {:error,
         [
           upstream_error(
             "componentization_plan.design_document.fingerprint_invalid",
             "DesignDocument failed IR validation",
             diagnostics
           )
         ]}
    end
  end

  defp preflight_fingerprint(plan, component_contract, design_document) do
    case ComponentizationPlan.design_document_sha256(design_document) do
      {:ok, fingerprint} ->
        cond do
          fingerprint != plan.design_document_sha256 ->
            {:error,
             [
               error_at(
                 "componentization_plan.design_document.mismatch",
                 "plan fingerprint does not match the supplied DesignDocument",
                 "design_document_sha256"
               )
             ]}

          plan.contract_id != component_contract.contract_id ->
            {:error,
             [
               error_at(
                 "componentization_plan.contract.mismatch",
                 "plan contract_id does not match the supplied ComponentContract",
                 "contract_id"
               )
             ]}

          true ->
            case ComponentContract.validate_ir_references(component_contract, design_document) do
              :ok ->
                {:ok, plan, component_contract, design_document}

              {:error, diagnostics} ->
                if Enum.all?(
                     diagnostics,
                     &(&1.code == "component_contract.binding.evidence_insufficient")
                   ) do
                  {:ok, plan, component_contract, design_document}
                else
                  {:error,
                   [
                     upstream_error(
                       "componentization_plan.contract.mismatch",
                       "ComponentContract references do not validate against the DesignDocument",
                       diagnostics
                     )
                   ]}
                end
            end
        end

      {:error, diagnostics} ->
        {:error, diagnostics}
    end
  end

  defp validate_indexed(plan, contract, document, generation? \\ false),
    do: validate_indexed(plan, contract, document, generation?, nil, [], nil)

  defp validate_indexed(
         plan,
         contract,
         document,
         generation?,
         disposition_authority,
         initial
       ),
       do:
         validate_indexed(
           plan,
           contract,
           document,
           generation?,
           disposition_authority,
           initial,
           nil
         )

  defp validate_indexed(
         plan,
         contract,
         document,
         generation?,
         disposition_authority,
         initial,
         native_realization_authority
       ) do
    indexes = build_indexes(plan, contract, document)

    case Map.fetch(indexes.nodes_by_id, plan.boundary_node_id) do
      :error ->
        finish(
          [
            initial,
            error_at(
              "componentization_plan.boundary.missing",
              "boundary_node_id does not resolve to a DesignNode",
              "boundary_node_id"
            )
          ]
          |> List.flatten()
        )

      {:ok, _boundary} ->
        boundary_ids = indexes.boundary_ids
        slot_owners = indexes.slot_owners

        {consumed_node_ids, disposition_diagnostics} =
          case disposition_authority do
            nil -> {MapSet.new(), []}
            authority -> validate_dispositions(plan, indexes, authority, initial)
          end

        diagnostics = initial ++ disposition_diagnostics
        diagnostics = validate_render_projections(plan, indexes, boundary_ids, diagnostics)
        diagnostics = validate_render_subtrees(plan, slot_owners, diagnostics)
        diagnostics = validate_binding_targets(contract, boundary_ids, slot_owners, diagnostics)
        diagnostics = validate_binding_coverage(indexes, boundary_ids, slot_owners, diagnostics)
        diagnostics = validate_placements(plan, contract, indexes, diagnostics)
        diagnostics = validate_role_colocation(plan, indexes, diagnostics)

        {image_sources, diagnostics} =
          validate_image_sources(plan, contract, indexes, boundary_ids, diagnostics)

        diagnostics = validate_static_images(indexes, image_sources, diagnostics)

        diagnostics = validate_unsupported_nodes(indexes, consumed_node_ids, diagnostics)

        diagnostics =
          if generation?,
            do:
              validate_native_generation(
                plan,
                contract,
                indexes,
                consumed_node_ids,
                diagnostics,
                native_realization_authority
              ),
            else: diagnostics

        finish(diagnostics)
    end
  rescue
    _error ->
      finish([
        error("componentization_plan.plan.invalid", "reference inputs failed closed validation")
      ])
  end

  defp validate_dispositions(plan, indexes, authority, intrinsic_diagnostics) do
    dispositions = plan.node_dispositions

    {dispositions, invalid_list?} =
      if proper_list?(dispositions), do: {dispositions, false}, else: {[], true}

    duplicate_counts = disposition_target_counts(dispositions)

    list_intrinsic_invalid? =
      Enum.any?(intrinsic_diagnostics, &disposition_list_intrinsic_failure?/1)

    initial_diagnostics =
      if authority == :missing or authority.authority_status != :valid do
        [
          error_at(
            "componentization_plan.node_disposition.behavior_authority_mismatch",
            "disposition validation requires exact approved Behavior authority",
            "node_dispositions"
          )
        ]
      else
        []
      end

    initial_diagnostics =
      if invalid_list? do
        [
          error_at(
            "componentization_plan.node_disposition.invalid",
            "node_dispositions must be a proper list of NodeDisposition records",
            "node_dispositions"
          )
          | initial_diagnostics
        ]
      else
        initial_diagnostics
      end

    checked =
      dispositions
      |> Enum.with_index()
      |> Enum.map(fn {disposition, index} ->
        validate_one_disposition(
          disposition,
          index,
          indexes,
          authority,
          duplicate_counts,
          list_intrinsic_invalid?
        )
      end)

    consumed_counts =
      Enum.reduce(checked, %{}, fn
        {:valid, id, _path, _diagnostics}, counts -> Map.update(counts, id, 1, &(&1 + 1))
        _invalid, counts -> counts
      end)

    {consumed_node_ids, diagnostics} =
      Enum.reduce(checked, {MapSet.new(), initial_diagnostics}, fn
        {:valid, id, _path, diagnostics}, {consumed, acc} ->
          consumed = MapSet.put(consumed, id)
          {consumed, diagnostics ++ acc}

        {:invalid, _id, _path, diagnostics}, {consumed, acc} ->
          {consumed, diagnostics ++ acc}
      end)

    diagnostics =
      Enum.reduce(checked, diagnostics, fn
        {:valid, id, path, _entry_diagnostics}, acc ->
          if Map.get(consumed_counts, id, 0) == 1 do
            acc
          else
            add(
              acc,
              error_at(
                "componentization_plan.node_disposition.unused",
                "a valid disposition was not consumed exactly once",
                path
              )
            )
          end

        _checked, acc ->
          acc
      end)

    {consumed_node_ids, diagnostics}
  end

  defp validate_one_disposition(
         disposition,
         index,
         indexes,
         authority,
         duplicate_counts,
         list_intrinsic_invalid?
       ) do
    path = "node_dispositions[#{index}]"
    id = disposition_field(disposition, :design_node_id)

    intrinsic_valid? =
      NodeDisposition.validate(disposition) == :ok and not list_intrinsic_invalid?

    duplicate? = is_binary(id) and Map.get(duplicate_counts, id, 0) > 1

    outcome_valid? =
      disposition_field(disposition, :disposition) == :exclude_source_runtime_carrier

    diagnostics = []

    diagnostics =
      if intrinsic_valid? do
        diagnostics
      else
        add(
          diagnostics,
          error_at(
            "componentization_plan.node_disposition.invalid",
            "NodeDisposition failed its intrinsic closed-record validation",
            path
          )
        )
      end

    diagnostics =
      if duplicate? do
        add(
          diagnostics,
          error_at(
            "componentization_plan.node_disposition.duplicate",
            "a design node may be consumed by only one NodeDisposition",
            path
          )
        )
      else
        diagnostics
      end

    diagnostics =
      if outcome_valid? do
        diagnostics
      else
        add(
          diagnostics,
          error_at(
            "componentization_plan.node_disposition.outcome_unsupported",
            "NodeDisposition outcome is not supported",
            path <> ".disposition"
          )
        )
      end

    {target, target_exists?, target_in_boundary?, target_semantic_valid?, diagnostics} =
      case Map.fetch(indexes.nodes_by_id, id) do
        :error ->
          {nil, false, false, false,
           add(
             diagnostics,
             error_at(
               "componentization_plan.node_disposition.target_missing",
               "disposition design_node_id does not resolve to a DesignNode",
               path <> ".design_node_id"
             )
           )}

        {:ok, node} ->
          in_boundary? = MapSet.member?(indexes.boundary_ids, id)

          semantic_valid? =
            node.semantic_type in ["raw", "unsupported", "unknown"] and node.children == []

          diagnostics =
            if in_boundary? do
              diagnostics
            else
              add(
                diagnostics,
                error_at(
                  "componentization_plan.node_disposition.target_outside_boundary",
                  "disposition target is outside the selected boundary",
                  path <> ".design_node_id"
                )
              )
            end

          diagnostics =
            if semantic_valid? do
              diagnostics
            else
              add(
                diagnostics,
                error_at(
                  "componentization_plan.node_disposition.target_semantic_incompatible",
                  "disposition target must be an unsupported leaf node",
                  path <> ".design_node_id"
                )
              )
            end

          {node, true, in_boundary?, semantic_valid?, diagnostics}
      end

    source_valid? = source_identity_matches?(disposition, target)

    diagnostics =
      if source_valid? do
        diagnostics
      else
        add(
          diagnostics,
          error_at(
            "componentization_plan.node_disposition.source_identity_mismatch",
            "disposition source identity does not match the current target SourceTrace",
            path
          )
        )
      end

    authority_valid? = authority != :missing and authority.authority_status == :valid

    authority_fields_match? =
      authority_valid? and
        disposition_field(disposition, :behavior_contract_digest) ==
          authority.behavior_contract_digest and
        disposition_field(disposition, :behavior_review_id) == authority.behavior_review_id

    diagnostics =
      if authority_valid? and not authority_fields_match? do
        add(
          diagnostics,
          error_at(
            "componentization_plan.node_disposition.behavior_authority_mismatch",
            "disposition digest or selected review ID differs from exact Behavior authority",
            path
          )
        )
      else
        diagnostics
      end

    binding_valid? =
      if authority == :missing do
        false
      else
        Map.get(authority.binding_counts, disposition_field(disposition, :behavior_binding_id), 0) ==
          1
      end

    diagnostics =
      if authority != :missing and not binding_valid? do
        add(
          diagnostics,
          error_at(
            "componentization_plan.node_disposition.behavior_binding_mismatch",
            "behavior_binding_id must identify exactly one binding in the supplied contract",
            path <> ".behavior_binding_id"
          )
        )
      else
        diagnostics
      end

    reference_roles =
      if authority == :missing,
        do: MapSet.new(),
        else: Map.get(authority.reference_index, id, MapSet.new())

    reference_conflict? = MapSet.size(reference_roles) > 0

    diagnostics =
      if reference_conflict? do
        add(
          diagnostics,
          error_at(
            "componentization_plan.node_disposition.behavior_reference_conflict",
            "Behavior or IR references target the disposed node",
            path <> ".design_node_id"
          )
        )
      else
        diagnostics
      end

    valid? =
      intrinsic_valid? and not duplicate? and outcome_valid? and target_exists? and
        target_in_boundary? and target_semantic_valid? and source_valid? and authority_valid? and
        authority_fields_match? and binding_valid? and not reference_conflict?

    status = if valid?, do: :valid, else: :invalid
    {status, id, path, diagnostics}
  end

  defp source_identity_matches?(disposition, %DesignNode{source_trace: trace})
       when is_map(trace) do
    source_type = Map.get(trace, :source_type)
    source_id = Map.get(trace, :source_id)

    nonempty_string?(source_type) and nonempty_string?(source_id) and
      disposition_field(disposition, :source_type) == source_type and
      disposition_field(disposition, :source_id) == source_id
  end

  defp source_identity_matches?(_disposition, _target), do: false

  defp disposition_field(%NodeDisposition{} = disposition, field), do: Map.get(disposition, field)

  defp disposition_field(disposition, field) when is_map(disposition),
    do: Map.get(disposition, field)

  defp disposition_field(_disposition, _field), do: nil

  defp disposition_target_counts(dispositions) do
    Enum.reduce(dispositions, %{}, fn disposition, counts ->
      case disposition_field(disposition, :design_node_id) do
        id when is_binary(id) -> Map.update(counts, id, 1, &(&1 + 1))
        _id -> counts
      end
    end)
  end

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_tail), do: false

  defp disposition_list_intrinsic_failure?(%Diagnostic{code: code}) when is_binary(code) do
    String.ends_with?(code, [
      ".design_node_id.order_invalid",
      ".version_incompatible",
      ".list.invalid"
    ])
  end

  defp disposition_list_intrinsic_failure?(_diagnostic), do: false

  defp nonempty_string?(value),
    do: is_binary(value) and byte_size(value) > 0 and String.valid?(value)

  defp build_indexes(plan, contract, document) do
    slot_targets =
      plan.render_projections
      |> Enum.filter(&(&1.render_role == :subtree_slot))
      |> Enum.map(& &1.target_node_id)
      |> MapSet.new()

    tree_indexes =
      index_nodes(
        document.root_nodes,
        %{
          nodes_by_id: %{},
          boundary_ids: MapSet.new(),
          slot_owners: %{},
          static_image_ids: [],
          unsupported_node_ids: []
        },
        plan.boundary_node_id,
        slot_targets,
        false,
        nil
      )

    nodes_by_id = tree_indexes.nodes_by_id

    attrs_by_name =
      Map.new(contract.public_attrs, fn %Attr{name: name} = attr -> {name, attr} end)

    slots_by_name =
      Map.new(contract.public_slots, fn %Slot{name: name} = slot -> {name, slot} end)

    collection_inputs_by_id =
      Map.new(contract.collection_inputs, fn %CollectionInput{source_collection_binding_id: id} =
                                               input ->
        {id, input}
      end)

    item_fields_by_collection =
      Map.new(contract.collection_inputs, fn %CollectionInput{
                                               source_collection_binding_id: id,
                                               item_fields: fields
                                             } ->
        {id, Map.new(fields, fn %ItemField{name: name} = item -> {name, item} end)}
      end)

    bindings_by_source =
      Enum.group_by(contract.binding_projections, fn %BindingProjection{
                                                       source_binding_kind: kind,
                                                       source_binding_id: id
                                                     } ->
        {kind, id}
      end)

    bindings_by_public_target =
      Enum.reduce(contract.binding_projections, %{}, fn projection, acc ->
        case binding_public_target(projection) do
          nil -> acc
          key -> Map.update(acc, key, [projection], &[projection | &1])
        end
      end)

    item_field_projection_index =
      Enum.reduce(contract.binding_projections, %{}, fn
        %BindingProjection{
          source_binding_kind: :value,
          projection_kind: :collection_item_field,
          source_collection_binding_id: collection_id,
          item_field_name: name,
          source_binding_id: id,
          target_node_id: target
        },
        acc
        when is_binary(collection_id) and is_binary(name) and is_binary(target) ->
          valid_text_binding? =
            match?(
              %ValueBinding{
                value_kind: :field,
                scope: :collection_item,
                target_kind: :text,
                collection_binding_id: ^collection_id,
                target_node_id: ^target
              },
              Map.get(document.value_bindings, id)
            )

          targets = if valid_text_binding?, do: MapSet.new([target]), else: MapSet.new()

          Map.update(acc, {collection_id, name}, {1, targets}, fn {count, indexed_targets} ->
            indexed_targets =
              if valid_text_binding?,
                do: MapSet.put(indexed_targets, target),
                else: indexed_targets

            {count + 1, indexed_targets}
          end)

        _projection, acc ->
          acc
      end)

    item_field_projection_count_index =
      Enum.reduce(contract.binding_projections, %{}, fn projection, acc ->
        case projection_item_field_identity(projection) do
          {collection_id, field_name} = identity
          when is_binary(collection_id) and is_binary(field_name) ->
            Map.update(acc, identity, 1, &(&1 + 1))

          _ ->
            acc
        end
      end)

    collection_item_text_targets =
      Enum.reduce(contract.binding_projections, MapSet.new(), fn
        %BindingProjection{
          source_binding_kind: :value,
          projection_kind: :collection_item_field,
          source_collection_binding_id: collection_id,
          source_binding_id: id,
          target_node_id: target
        },
        acc ->
          case Map.get(document.value_bindings, id) do
            %ValueBinding{} = binding when is_binary(collection_id) and is_binary(target) ->
              if binding.scope == :collection_item and binding.target_kind == :text and
                   binding.collection_binding_id == collection_id do
                MapSet.put(acc, {collection_id, target})
              else
                acc
              end

            _ ->
              acc
          end

        _projection, acc ->
          acc
      end)

    render_by_public_target =
      Map.new(plan.render_projections, fn projection ->
        {render_public_target(projection), projection}
      end)

    render_by_node_role =
      Enum.group_by(plan.render_projections, &{&1.target_node_id, &1.render_role})

    render_by_node = Enum.group_by(plan.render_projections, & &1.target_node_id)

    value_bindings = normalized_registry(document.value_bindings)
    collection_bindings = normalized_registry(document.collection_bindings)

    companion_references_by_candidate =
      companion_reference_index(
        value_bindings,
        bindings_by_source,
        nodes_by_id,
        tree_indexes.boundary_ids,
        item_fields_by_collection
      )

    %{
      nodes_by_id: nodes_by_id,
      boundary_ids: tree_indexes.boundary_ids,
      slot_owners: tree_indexes.slot_owners,
      static_image_ids: Enum.reverse(tree_indexes.static_image_ids),
      unsupported_node_ids: Enum.reverse(tree_indexes.unsupported_node_ids),
      attrs_by_name: attrs_by_name,
      slots_by_name: slots_by_name,
      collection_inputs_by_id: collection_inputs_by_id,
      item_fields_by_collection: item_fields_by_collection,
      bindings_by_source: bindings_by_source,
      bindings_by_public_target: bindings_by_public_target,
      item_field_projection_index: item_field_projection_index,
      item_field_projection_count_index: item_field_projection_count_index,
      collection_item_text_targets: collection_item_text_targets,
      companion_references_by_candidate: companion_references_by_candidate,
      render_by_public_target: render_by_public_target,
      render_by_node_role: render_by_node_role,
      render_by_node: render_by_node,
      value_bindings: value_bindings,
      collection_bindings: collection_bindings
    }
  end

  defp projection_item_field_identity(%BindingProjection{
         projection_kind: :collection_item_field,
         source_binding_kind: :value,
         source_collection_binding_id: collection_id,
         item_field_name: field_name
       }),
       do: {collection_id, field_name}

  defp projection_item_field_identity(%BindingProjection{
         projection_kind: :collection_item_field,
         parent_collection_binding_id: collection_id,
         parent_item_field_name: field_name
       }),
       do: {collection_id, field_name}

  defp projection_item_field_identity(_projection), do: nil

  defp companion_reference_index(
         value_bindings,
         bindings_by_source,
         nodes_by_id,
         boundary_ids,
         item_fields_by_collection
       ) do
    Enum.reduce(value_bindings, %{}, fn
      {id,
       %ValueBinding{
         value_kind: :field,
         scope: :collection_item,
         target_kind: :asset,
         collection_binding_id: collection_id,
         target_node_id: target
       }},
      acc
      when is_binary(collection_id) and is_binary(target) ->
        source_projection =
          case Map.get(bindings_by_source, {:value, id}) do
            [
              %BindingProjection{
                projection_kind: :collection_item_field,
                source_binding_kind: :value,
                source_collection_binding_id: ^collection_id,
                item_field_name: source_name,
                target_node_id: ^target
              }
            ] ->
              Map.get(item_fields_by_collection, collection_id, %{})[source_name]

            _ ->
              nil
          end

        if MapSet.member?(boundary_ids, target) and
             match?(%DesignNode{semantic_type: "image"}, Map.get(nodes_by_id, target)) do
          add_companion_reference(acc, collection_id, source_projection)
        else
          acc
        end

      _other, acc ->
        acc
    end)
  end

  defp add_companion_reference(acc, collection_id, %ItemField{accessibility: accessibility}) do
    with {:ok, policy} <- Json.normalize(accessibility),
         %{
           "image_alt_policy" => "consumer_supplied",
           "alt_item_field_name" => alt_name,
           "required_when_source_present" => true
         } <- policy,
         true <- map_size(policy) == 3,
         true <- nonempty_string?(alt_name) do
      Map.update(acc, {collection_id, alt_name}, 1, &(&1 + 1))
    else
      _ -> acc
    end
  end

  defp add_companion_reference(acc, _collection_id, _source_projection), do: acc

  defp index_nodes(nodes, indexes, boundary_id, slot_targets, in_boundary?, current_slot_owner) do
    Enum.reduce(nodes, indexes, fn %DesignNode{node_id: id, children: children} = node, acc ->
      in_boundary? = in_boundary? or id == boundary_id

      slot_owner =
        if current_slot_owner == nil and MapSet.member?(slot_targets, id),
          do: id,
          else: current_slot_owner

      acc = %{acc | nodes_by_id: Map.put(acc.nodes_by_id, id, node)}

      acc =
        if in_boundary? do
          %{acc | boundary_ids: MapSet.put(acc.boundary_ids, id)}
        else
          acc
        end

      acc =
        if slot_owner == nil do
          acc
        else
          %{acc | slot_owners: Map.put(acc.slot_owners, id, slot_owner)}
        end

      acc =
        if in_boundary? and slot_owner == nil and node.semantic_type == "image" do
          %{acc | static_image_ids: [id | acc.static_image_ids]}
        else
          acc
        end

      acc =
        if in_boundary? and node.semantic_type in ["raw", "unsupported", "unknown"] do
          %{acc | unsupported_node_ids: [id | acc.unsupported_node_ids]}
        else
          acc
        end

      index_nodes(children, acc, boundary_id, slot_targets, in_boundary?, slot_owner)
    end)
  end

  defp validate_render_projections(plan, indexes, boundary_ids, diagnostics) do
    Enum.reduce(Enum.with_index(plan.render_projections), diagnostics, fn {projection, index},
                                                                          acc ->
      path = "render_projections[#{index}]"
      target = Map.get(indexes.nodes_by_id, projection.target_node_id)
      acc = validate_render_target(projection, path, target, boundary_ids, acc)
      acc = validate_render_public_target(projection, path, indexes, acc)
      acc = validate_render_role_type(projection, path, indexes, acc)
      validate_render_role_node(projection, path, target, plan.boundary_node_id, acc)
    end)
  end

  defp validate_render_target(_projection, path, nil, _boundary_ids, diagnostics) do
    add(
      diagnostics,
      error_at(
        "componentization_plan.render_projection.target_missing",
        "target_node_id does not resolve to a DesignNode",
        path
      )
    )
  end

  defp validate_render_target(projection, path, _target, boundary_ids, diagnostics) do
    if MapSet.member?(boundary_ids, projection.target_node_id) do
      diagnostics
    else
      add(
        diagnostics,
        error_at(
          "componentization_plan.render_projection.target_outside_boundary",
          "RenderProjection target is outside the selected boundary",
          path
        )
      )
    end
  end

  defp validate_render_public_target(projection, path, indexes, diagnostics) do
    exists? =
      case render_public_target(projection) do
        {:attr, name} -> Map.has_key?(indexes.attrs_by_name, name)
        {:slot, name} -> Map.has_key?(indexes.slots_by_name, name)
      end

    if exists? do
      diagnostics
    else
      add(
        diagnostics,
        error_at(
          "componentization_plan.render_projection.invalid",
          "RenderProjection public target is absent from the ComponentContract",
          path
        )
      )
    end
  end

  defp validate_render_role_type(projection, path, indexes, diagnostics) do
    valid? =
      case {projection.render_role, render_public_target(projection)} do
        {:subtree_slot, {:slot, name}} ->
          match?(%Slot{cardinality: "0..1"}, Map.get(indexes.slots_by_name, name))

        {role, {:attr, name}} when is_map_key(@role_types, role) ->
          case Map.get(indexes.attrs_by_name, name) do
            %Attr{type: type, validation: validation} ->
              type == Map.fetch!(@role_types, role) and
                (role != :heading_level or Map.get(validation, "values") == [1, 2, 3, 4, 5, 6])

            _ ->
              false
          end

        _ ->
          false
      end

    if valid? do
      diagnostics
    else
      add(
        diagnostics,
        error_at(
          "componentization_plan.render_projection.role_type_mismatch",
          "public target type or slot cardinality is incompatible with render_role",
          path
        )
      )
    end
  end

  defp validate_render_role_node(_projection, _path, nil, _boundary_id, diagnostics),
    do: diagnostics

  defp validate_render_role_node(projection, path, node, boundary_id, diagnostics) do
    valid? =
      case projection.render_role do
        role when role in @root_roles -> projection.target_node_id == boundary_id
        :text_content -> node.semantic_type in ["heading", "paragraph", "rich_text"]
        :asset_src -> node.semantic_type == "image"
        :asset_alt -> node.semantic_type == "image"
        :link_url -> node.semantic_type == "link"
        :heading_level -> node.semantic_type == "heading"
        :subtree_slot -> node.semantic_type in ["actions", "button", "link", "rich_text"]
        _ -> false
      end

    if valid? do
      diagnostics
    else
      add(
        diagnostics,
        error_at(
          "componentization_plan.render_projection.role_node_mismatch",
          "render_role is incompatible with the target node semantic_type",
          path
        )
      )
    end
  end

  defp validate_binding_targets(contract, boundary_ids, slot_owners, diagnostics) do
    Enum.reduce(Enum.with_index(contract.binding_projections), diagnostics, fn {projection, index},
                                                                               acc ->
      path = "binding_projections[#{index}]"

      acc =
        if MapSet.member?(boundary_ids, projection.target_node_id) do
          acc
        else
          add(
            acc,
            error_at(
              "componentization_plan.render_projection.target_outside_boundary",
              "BindingProjection target is outside the selected boundary",
              path
            )
          )
        end

      if Map.get(slot_owners, projection.target_node_id) do
        add(
          acc,
          error_at(
            "componentization_plan.slot.subtree_conflict",
            "BindingProjection targets a subtree replaced by subtree_slot",
            path
          )
        )
      else
        acc
      end
    end)
  end

  defp validate_render_subtrees(plan, slot_owners, diagnostics) do
    Enum.reduce(Enum.with_index(plan.render_projections), diagnostics, fn {projection, index},
                                                                          acc ->
      owner = Map.get(slot_owners, projection.target_node_id)

      owner_projection? =
        projection.render_role == :subtree_slot and projection.target_node_id == owner

      if owner && not owner_projection? do
        add(
          acc,
          error_at(
            "componentization_plan.slot.subtree_conflict",
            "RenderProjection targets a subtree replaced by subtree_slot",
            "render_projections[#{index}]"
          )
        )
      else
        acc
      end
    end)
  end

  defp validate_binding_coverage(indexes, boundary_ids, slot_owners, diagnostics) do
    diagnostics =
      Enum.reduce(indexes.value_bindings, diagnostics, fn {id, %ValueBinding{} = binding}, acc ->
        if MapSet.member?(boundary_ids, binding.target_node_id) do
          matches = Map.get(indexes.bindings_by_source, {:value, id}, [])
          acc = require_binding_count(acc, matches, "value", id)

          acc =
            if binding.normalization_status == :evidence_insufficient do
              add(
                acc,
                error_at(
                  "componentization_plan.binding.evidence_insufficient",
                  "in-boundary ValueBinding has insufficient normalization evidence",
                  "value_bindings[#{id}]"
                )
              )
            else
              acc
            end

          if Map.get(slot_owners, binding.target_node_id) do
            add(
              acc,
              error_at(
                "componentization_plan.slot.subtree_conflict",
                "ValueBinding targets a subtree replaced by subtree_slot",
                "value_bindings[#{id}]"
              )
            )
          else
            acc
          end
        else
          acc
        end
      end)

    Enum.reduce(indexes.collection_bindings, diagnostics, fn {id, %CollectionBinding{} = binding},
                                                             acc ->
      owner_inside = MapSet.member?(boundary_ids, binding.owner_node_id)
      repeat_inside = MapSet.member?(boundary_ids, binding.repeat_root_node_id)

      acc =
        cond do
          owner_inside != repeat_inside ->
            add(
              acc,
              error_at(
                "componentization_plan.boundary.binding_crosses",
                "CollectionBinding owner and repeat root must both lie inside or both outside the boundary",
                "collection_bindings[#{id}]"
              )
            )

          owner_inside ->
            require_binding_count(
              acc,
              Map.get(indexes.bindings_by_source, {:collection, id}, []),
              "collection",
              id
            )

          true ->
            acc
        end

      parent = binding.parent_collection_binding_id

      acc =
        if owner_inside and is_binary(parent) do
          case Map.get(indexes.collection_bindings, parent) do
            %CollectionBinding{} = parent_binding ->
              parent_inside =
                MapSet.member?(boundary_ids, parent_binding.owner_node_id) and
                  MapSet.member?(boundary_ids, parent_binding.repeat_root_node_id)

              if parent_inside do
                acc
              else
                add(
                  acc,
                  error_at(
                    "componentization_plan.boundary.binding_crosses",
                    "in-boundary nested CollectionBinding requires its parent binding inside the boundary",
                    "collection_bindings[#{id}].parent_collection_binding_id"
                  )
                )
              end

            _ ->
              acc
          end
        else
          acc
        end

      if Map.get(slot_owners, binding.owner_node_id) ||
           Map.get(slot_owners, binding.repeat_root_node_id) do
        add(
          acc,
          error_at(
            "componentization_plan.slot.subtree_conflict",
            "CollectionBinding crosses a subtree replaced by subtree_slot",
            "collection_bindings[#{id}]"
          )
        )
      else
        acc
      end
    end)
  end

  defp require_binding_count(diagnostics, [_], _kind, _id), do: diagnostics

  defp require_binding_count(diagnostics, [], kind, id) do
    add(
      diagnostics,
      error_at(
        "componentization_plan.binding.uncovered",
        "in-boundary Design IR binding has no BindingProjection",
        "#{kind}_bindings[#{id}]"
      )
    )
  end

  defp require_binding_count(diagnostics, _many, kind, id) do
    add(
      diagnostics,
      error_at(
        "componentization_plan.binding.duplicate",
        "in-boundary Design IR binding has multiple BindingProjections",
        "#{kind}_bindings[#{id}]"
      )
    )
  end

  defp validate_placements(_plan, contract, indexes, diagnostics) do
    diagnostics =
      Enum.reduce(contract.public_attrs, diagnostics, fn %Attr{name: name}, acc ->
        validate_one_placement(acc, {:attr, name}, name, indexes)
      end)

    Enum.reduce(contract.public_slots, diagnostics, fn %Slot{name: name}, acc ->
      validate_one_placement(acc, {:slot, name}, name, indexes)
    end)
    |> then(fn acc ->
      Enum.reduce(contract.binding_projections, acc, fn
        %BindingProjection{projection_kind: :slot, public_slot_name: name}, d
        when is_binary(name) ->
          add(
            d,
            error_at(
              "componentization_plan.slot.binding_backed_unsupported",
              "binding-backed slots are not generation-eligible in plan format 1.0.0",
              "public_slots[#{name}]"
            )
          )

        _projection, d ->
          d
      end)
    end)
  end

  defp validate_one_placement(diagnostics, target, name, indexes) do
    binding_count = length(Map.get(indexes.bindings_by_public_target, target, []))
    render_count = if Map.has_key?(indexes.render_by_public_target, target), do: 1, else: 0

    if (binding_count == 1 and render_count == 0) or (binding_count == 0 and render_count == 1) do
      diagnostics
    else
      code =
        if binding_count == 0 and render_count == 0,
          do: "componentization_plan.public_input.placement_missing",
          else: "componentization_plan.public_input.placement_conflict"

      add(
        diagnostics,
        error_at(
          code,
          "public input must have exactly one BindingProjection or RenderProjection",
          "public_inputs[#{name}]"
        )
      )
    end
  end

  defp validate_role_colocation(plan, indexes, diagnostics) do
    Enum.reduce(indexes.render_by_node, diagnostics, fn {node_id, projections}, acc ->
      roles = Enum.map(projections, & &1.render_role)
      role_counts = Enum.frequencies(roles)
      duplicate? = Enum.any?(role_counts, fn {_role, count} -> count > 1 end)
      node = Map.get(indexes.nodes_by_id, node_id)
      boundary? = node_id == plan.boundary_node_id
      root_role_present? = Enum.any?(roles, &(&1 in @root_roles))
      semantic_role_present? = Enum.any?(roles, &(&1 not in @root_roles))
      mixed_boundary_roles? = boundary? and root_role_present? and semantic_role_present?

      allowed_roles =
        if boundary? and root_role_present? and not semantic_role_present? do
          @root_roles
        else
          semantic_allowed_roles(node)
        end

      unsupported? =
        mixed_boundary_roles? or Enum.any?(roles, &(&1 not in allowed_roles))

      if duplicate? or unsupported? do
        add(
          acc,
          error_at(
            "componentization_plan.render_projection.role_conflict",
            "render roles on one node are duplicated or cannot be co-located",
            "render_projections[#{node_id}]"
          )
        )
      else
        acc
      end
    end)
  end

  defp semantic_allowed_roles(%DesignNode{semantic_type: "heading"}),
    do: [:text_content, :heading_level]

  defp semantic_allowed_roles(%DesignNode{semantic_type: "paragraph"}),
    do: [:text_content]

  defp semantic_allowed_roles(%DesignNode{semantic_type: "rich_text"}),
    do: [:text_content, :subtree_slot]

  defp semantic_allowed_roles(%DesignNode{semantic_type: "image"}),
    do: [:asset_src, :asset_alt]

  defp semantic_allowed_roles(%DesignNode{semantic_type: "link"}),
    do: [:link_url, :subtree_slot]

  defp semantic_allowed_roles(%DesignNode{semantic_type: type})
       when type in ["actions", "button"],
       do: [:subtree_slot]

  defp semantic_allowed_roles(_node), do: []

  defp validate_image_sources(plan, contract, indexes, boundary_ids, diagnostics) do
    {valid_source_nodes, diagnostics} =
      validate_top_level_image_sources(plan, contract, indexes, boundary_ids, diagnostics)

    validate_collection_item_image_sources(indexes, boundary_ids, valid_source_nodes, diagnostics)
  end

  defp validate_top_level_image_sources(plan, contract, indexes, boundary_ids, diagnostics) do
    render_sources =
      Enum.filter(plan.render_projections, fn projection ->
        projection.render_role == :asset_src and
          MapSet.member?(boundary_ids, projection.target_node_id)
      end)

    binding_sources =
      Enum.flat_map(contract.binding_projections, fn
        %BindingProjection{
          source_binding_kind: :value,
          projection_kind: :scalar_attr,
          public_attr_name: name,
          source_binding_id: id,
          target_node_id: target
        } ->
          case Map.get(indexes.value_bindings, id) do
            %ValueBinding{scope: :site, target_kind: :asset} ->
              if MapSet.member?(boundary_ids, target) and
                   match?(
                     %DesignNode{semantic_type: "image"},
                     Map.get(indexes.nodes_by_id, target)
                   ) do
                [{name, target, "binding_projections[#{id}]"}]
              else
                []
              end

            _ ->
              []
          end

        _projection ->
          []
      end)

    sources =
      Enum.map(
        render_sources,
        &{&1.public_attr_name, &1.target_node_id, "render_projections[#{&1.public_attr_name}]"}
      ) ++
        binding_sources

    Enum.reduce(sources, {MapSet.new(), diagnostics}, fn {name, target, path}, {nodes, acc} ->
      case Map.get(indexes.attrs_by_name, name) do
        %Attr{} = source_attr ->
          {valid?, acc} =
            validate_top_level_image_policy(source_attr, name, target, plan, indexes, path, acc)

          {if(valid?, do: MapSet.put(nodes, target), else: nodes), acc}

        _ ->
          {nodes,
           add(
             acc,
             error_at(
               "componentization_plan.accessibility.image_policy_missing",
               "image source attr does not resolve",
               path
             )
           )}
      end
    end)
  end

  defp validate_top_level_image_policy(
         source_attr,
         source_name,
         target,
         plan,
         indexes,
         path,
         diagnostics
       ) do
    {:ok, policy} = Json.normalize(source_attr.accessibility)

    case Map.get(policy, "image_alt_policy") do
      nil ->
        {false,
         add(
           diagnostics,
           error_at(
             "componentization_plan.accessibility.image_policy_missing",
             "image source requires an explicit accessibility policy",
             path
           )
         )}

      "consumer_supplied" ->
        validate_consumer_alt_policy(
          policy,
          source_name,
          target,
          plan,
          indexes,
          path,
          diagnostics
        )

      "decorative" ->
        validate_decorative_policy(policy, target, indexes, path, diagnostics)

      _unknown ->
        {false,
         add(
           diagnostics,
           error_at(
             "componentization_plan.accessibility.image_policy_invalid",
             "image_alt_policy is not supported",
             path
           )
         )}
    end
  end

  defp validate_consumer_alt_policy(
         policy,
         _source_name,
         target,
         _plan,
         indexes,
         path,
         diagnostics
       ) do
    alt_name = Map.get(policy, "alt_attr_name")
    required? = Map.get(policy, "required_when_source_present") == true
    exact_keys? = map_size(policy) == 3

    diagnostics =
      if required? and exact_keys? do
        diagnostics
      else
        add(
          diagnostics,
          error_at(
            "componentization_plan.accessibility.image_policy_invalid",
            "consumer-supplied alt policy requires exactly the approved keys and required_when_source_present = true",
            path
          )
        )
      end

    case Map.get(indexes.attrs_by_name, alt_name) do
      %Attr{type: :string} when is_binary(alt_name) and alt_name != "" ->
        projections = Map.get(indexes.render_by_node_role, {target, :asset_alt}, [])

        valid_projection? =
          match?([%RenderProjection{public_attr_name: ^alt_name}], projections)

        diagnostics =
          if valid_projection? do
            diagnostics
          else
            add(
              diagnostics,
              error_at(
                "componentization_plan.accessibility.alt_projection_mismatch",
                "consumer alt attr requires one asset_alt RenderProjection for the same image",
                path
              )
            )
          end

        {required? and exact_keys? and valid_projection?, diagnostics}

      _ ->
        {false,
         add(
           diagnostics,
           error_at(
             "componentization_plan.accessibility.alt_attr_missing",
             "alt_attr_name must resolve to a string public attr",
             path
           )
         )}
    end
  end

  defp validate_decorative_policy(policy, target, indexes, path, diagnostics) do
    has_alt_name? = Map.has_key?(policy, "alt_attr_name")
    exact_keys? = map_size(policy) == 1

    has_alt_projection? = Map.has_key?(indexes.render_by_node_role, {target, :asset_alt})

    if has_alt_name? or not exact_keys? or has_alt_projection? do
      {false,
       add(
         diagnostics,
         error_at(
           "componentization_plan.accessibility.image_policy_invalid",
           "decorative image policy cannot declare an alt attr or asset_alt projection",
           path
         )
       )}
    else
      {true, diagnostics}
    end
  end

  defp validate_collection_item_image_sources(
         indexes,
         boundary_ids,
         valid_source_nodes,
         diagnostics
       ) do
    Enum.reduce(indexes.value_bindings, {valid_source_nodes, diagnostics}, fn
      {id,
       %ValueBinding{scope: :collection_item, target_kind: :asset, target_node_id: target} =
           binding},
      {nodes, acc} ->
        if MapSet.member?(boundary_ids, target) and
             match?(%DesignNode{semantic_type: "image"}, Map.get(indexes.nodes_by_id, target)) do
          projections = Map.get(indexes.bindings_by_source, {:value, id}, [])

          case projections do
            [
              %BindingProjection{
                projection_kind: :collection_item_field,
                source_collection_binding_id: collection_id,
                item_field_name: field_name
              }
            ] ->
              source_field =
                get_in(indexes.item_fields_by_collection, [collection_id, field_name])

              case source_field do
                %ItemField{} ->
                  {valid?, acc} =
                    validate_item_image_policy(
                      source_field,
                      field_name,
                      collection_id,
                      binding,
                      target,
                      indexes,
                      acc
                    )

                  {if(valid?, do: MapSet.put(nodes, target), else: nodes), acc}

                _ ->
                  {nodes,
                   add(
                     acc,
                     error_at(
                       "componentization_plan.accessibility.item_image_policy_missing",
                       "collection image source ItemField does not resolve",
                       "value_bindings[#{id}]"
                     )
                   )}
              end

            _ ->
              {nodes,
               add(
                 acc,
                 error_at(
                   "componentization_plan.accessibility.item_image_policy_missing",
                   "collection image source requires one collection item projection",
                   "value_bindings[#{id}]"
                 )
               )}
          end
        else
          {nodes, acc}
        end

      _other, state ->
        state
    end)
  end

  defp validate_item_image_policy(
         source_field,
         field_name,
         collection_id,
         image_binding,
         target,
         indexes,
         diagnostics
       ) do
    {:ok, policy} = Json.normalize(source_field.accessibility)

    case Map.get(policy, "image_alt_policy") do
      nil ->
        {false,
         add(
           diagnostics,
           error_at(
             "componentization_plan.accessibility.item_image_policy_missing",
             "collection image ItemField requires an explicit accessibility policy",
             "item_fields[#{collection_id}.#{field_name}]"
           )
         )}

      "consumer_supplied" ->
        validate_item_consumer_alt(
          policy,
          collection_id,
          image_binding,
          target,
          indexes,
          diagnostics
        )

      "decorative" ->
        validate_item_decorative(
          policy,
          collection_id,
          image_binding,
          target,
          indexes,
          diagnostics
        )

      _unknown ->
        {false,
         add(
           diagnostics,
           error_at(
             "componentization_plan.accessibility.item_image_policy_invalid",
             "image_alt_policy is not supported for a collection image",
             "item_fields[#{collection_id}.#{field_name}]"
           )
         )}
    end
  end

  defp validate_item_consumer_alt(
         policy,
         collection_id,
         image_binding,
         target,
         indexes,
         diagnostics
       ) do
    alt_name = Map.get(policy, "alt_item_field_name")
    exact_keys? = map_size(policy) == 3
    required? = Map.get(policy, "required_when_source_present") == true
    alt_field = get_in(indexes.item_fields_by_collection, [collection_id, alt_name])

    diagnostics =
      if required? and exact_keys? do
        diagnostics
      else
        add(
          diagnostics,
          error_at(
            "componentization_plan.accessibility.item_image_policy_invalid",
            "consumer item alt policy requires exactly the approved keys and required_when_source_present = true",
            "item_fields[#{collection_id}.#{alt_name}]"
          )
        )
      end

    case alt_field do
      %ItemField{type: :string} when is_binary(alt_name) and alt_name != "" ->
        valid_binding_backed? =
          case Map.get(indexes.item_field_projection_index, {collection_id, alt_name}) do
            {1, targets} ->
              MapSet.member?(targets, target) and
                image_binding.collection_binding_id == collection_id

            _ ->
              false
          end

        valid_unbound? =
          Map.get(indexes.item_field_projection_count_index, {collection_id, alt_name}, 0) == 0 and
            alt_field.required == false and alt_field.default == nil and
            Map.get(indexes.companion_references_by_candidate, {collection_id, alt_name}, 0) == 1 and
            image_binding.collection_binding_id == collection_id

        if (valid_binding_backed? or valid_unbound?) and required? and exact_keys? do
          {true, diagnostics}
        else
          {false,
           add(
             diagnostics,
             error_at(
               "componentization_plan.accessibility.alt_item_projection_mismatch",
               "consumer item alt requires one sibling text binding to the same image node and collection",
               "item_fields[#{collection_id}.#{alt_name}]"
             )
           )}
        end

      _ ->
        {false,
         add(
           diagnostics,
           error_at(
             "componentization_plan.accessibility.alt_item_field_missing",
             "alt_item_field_name must resolve to a string ItemField in the same CollectionInput",
             "item_fields[#{collection_id}.#{alt_name}]"
           )
         )}
    end
  end

  defp validate_item_decorative(
         policy,
         collection_id,
         image_binding,
         target,
         indexes,
         diagnostics
       ) do
    alt_name? = Map.has_key?(policy, "alt_item_field_name")
    exact_keys? = map_size(policy) == 1

    sibling_text_binding? =
      MapSet.member?(indexes.collection_item_text_targets, {collection_id, target})

    if alt_name? or not exact_keys? or image_binding.collection_binding_id != collection_id or
         sibling_text_binding? do
      {false,
       add(
         diagnostics,
         error_at(
           "componentization_plan.accessibility.item_image_policy_invalid",
           "decorative collection image cannot name or bind a sibling alt field",
           "item_fields[#{collection_id}]"
         )
       )}
    else
      {true, diagnostics}
    end
  end

  defp validate_static_images(indexes, valid_source_nodes, diagnostics) do
    Enum.reduce(indexes.static_image_ids, diagnostics, fn id, acc ->
      if MapSet.member?(valid_source_nodes, id) do
        acc
      else
        add(
          acc,
          error_at(
            "componentization_plan.accessibility.static_image_unsupported",
            "in-boundary image lacks an authorized public source and accessibility policy",
            "nodes[#{id}]"
          )
        )
      end
    end)
  end

  defp validate_unsupported_nodes(indexes, consumed_node_ids, diagnostics) do
    Enum.reduce(indexes.unsupported_node_ids, diagnostics, fn id, acc ->
      if MapSet.member?(consumed_node_ids, id) do
        acc
      else
        add(
          acc,
          error_at(
            "componentization_plan.unsupported_node",
            "unsupported DesignNode semantic_type blocks plan validation",
            "nodes[#{id}]"
          )
        )
      end
    end)
  end

  @native_tags %{
    "section" => {~w(section div), "section"},
    "container" => {~w(div), "div"},
    "wrapper" => {~w(div), "div"},
    "stack" => {~w(div), "div"},
    "grid" => {~w(div), "div"},
    "generic" => {~w(div), "div"},
    "background" => {~w(div), "div"},
    "overlay" => {~w(div), "div"},
    "actions" => {~w(div), "div"},
    "paragraph" => {~w(p), "p"},
    "rich_text" => {~w(div p span), nil},
    "heading" => {~w(h1 h2 h3 h4 h5 h6), nil},
    "image" => {~w(figure picture), "img"},
    "button" => {~w(button), "button"},
    "link" => {[], "a"}
  }

  @doc false
  def native_tag(%DesignNode{semantic_type: semantic, attributes: attrs}, public_heading?) do
    case Map.fetch(@native_tags, semantic) do
      {:ok, {compatible, default}} ->
        case Map.fetch(attrs, "tag") do
          {:ok, tag} ->
            if LiveFrames.StaticMarkupContract.native_tag?(tag) and tag in compatible,
              do:
                {:ok,
                 if(semantic == "heading" and public_heading?, do: :dynamic_heading, else: tag)},
              else: :error

          :error ->
            cond do
              semantic == "heading" and public_heading? -> {:ok, :dynamic_heading}
              default != nil -> {:ok, default}
              true -> :error
            end
        end

      :error ->
        :error
    end
  end

  defp validate_native_generation(
         plan,
         contract,
         indexes,
         consumed_node_ids,
         diagnostics,
         native_realization_authority
       ) do
    diagnostics =
      Enum.reduce(indexes.value_bindings, diagnostics, fn {id, %ValueBinding{} = binding}, acc ->
        if binding.target_kind == :rich_text and
             MapSet.member?(indexes.boundary_ids, binding.target_node_id) do
          add(
            acc,
            error_at(
              "componentization_plan.binding.rich_text_trust_required",
              "in-boundary rich_text binding has no trusted rendering authority",
              "value_bindings[#{id}]"
            )
          )
        else
          acc
        end
      end)

    {roles, diagnostics} =
      Enum.reduce(contract.binding_projections, {%{}, diagnostics}, fn projection, {roles, acc} ->
        node = Map.get(indexes.nodes_by_id, projection.target_node_id)
        role = native_binding_role(projection, node, indexes)

        if role == :unsupported do
          {roles,
           native_error(
             acc,
             "binding_emission_unsupported",
             "binding has no frozen native emission",
             projection.target_node_id
           )}
        else
          {Map.update(
             roles,
             projection.target_node_id,
             %{role => projection},
             &Map.put(&1, role, projection)
           ), acc}
        end
      end)

    roles =
      Enum.reduce(plan.render_projections, roles, fn projection, acc ->
        Map.update(
          acc,
          projection.target_node_id,
          %{projection.render_role => projection},
          &Map.put(&1, projection.render_role, projection)
        )
      end)

    Enum.reduce(indexes.boundary_ids, diagnostics, fn id, acc ->
      node = Map.fetch!(indexes.nodes_by_id, id)
      node_roles = Map.get(roles, id, %{})

      if MapSet.member?(consumed_node_ids, id) do
        acc
      else
        cond do
          node.semantic_type == "icon" ->
            native_error(acc, "icon_unsupported", "icons have no first-wave native renderer", id)

          id == plan.boundary_node_id and Map.has_key?(node_roles, :subtree_slot) ->
            native_error(
              acc,
              "boundary_subtree_slot",
              "slot replacement would remove the component root",
              id
            )

          Map.has_key?(indexes.slot_owners, id) and
              not (node.semantic_type == "heading" and Map.has_key?(node.attributes, "navigation")) ->
            acc

          true ->
            acc
            |> validate_native_tag(
              node,
              node_roles,
              indexes,
              native_realization_authority
            )
            |> validate_native_node_surface(node)
            |> validate_native_boundary_image(node, node_roles, plan, indexes)
            |> validate_native_navigation(node, node_roles, Map.has_key?(indexes.slot_owners, id))
        end
      end
    end)
  end

  @native_string_or_nil_content ~w(
    section container wrapper stack grid generic background overlay
    paragraph rich_text heading button link
  )

  @native_nil_content_only ~w(image actions)
  @heading_navigation_tags ~w(h1 h2 h3 h4 h5 h6)

  defp validate_native_node_surface(diagnostics, %DesignNode{} = node) do
    diagnostics =
      cond do
        node.semantic_type in @native_string_or_nil_content ->
          validate_string_or_nil_content(
            diagnostics,
            node,
            "#{node.semantic_type}_content_invalid"
          )

        node.semantic_type in @native_nil_content_only ->
          validate_content_absent(diagnostics, node, "#{node.semantic_type}_content_forbidden")

        true ->
          diagnostics
      end

    case node.semantic_type do
      "paragraph" ->
        validate_no_child_subtree(diagnostics, node, "paragraph_children_forbidden")

      "rich_text" ->
        diagnostics
        |> validate_rich_text_content(node)
        |> validate_no_child_subtree(node, "rich_text_children_forbidden")

      "heading" ->
        validate_no_child_subtree(diagnostics, node, "heading_children_forbidden")

      "image" ->
        validate_no_child_subtree(diagnostics, node, "image_children_forbidden")

      _ ->
        diagnostics
    end
  end

  defp validate_content_absent(diagnostics, %DesignNode{content: nil}, _code), do: diagnostics

  defp validate_content_absent(diagnostics, %DesignNode{node_id: id}, code) do
    native_error(diagnostics, code, "node must not carry static content", id)
  end

  defp validate_string_or_nil_content(
         diagnostics,
         %DesignNode{node_id: id, content: content},
         code
       ) do
    if content == nil or is_binary(content) do
      diagnostics
    else
      native_error(diagnostics, code, "node content must be absent or a UTF-8 string", id)
    end
  end

  defp validate_rich_text_content(diagnostics, %DesignNode{node_id: id, content: content}) do
    if content != nil and not is_binary(content) do
      native_error(
        diagnostics,
        "rich_text_structured_content",
        "structured rich_text content is not generation-eligible",
        id
      )
    else
      diagnostics
    end
  end

  defp validate_no_child_subtree(diagnostics, %DesignNode{node_id: id, children: children}, code) do
    if children == [] do
      diagnostics
    else
      native_error(diagnostics, code, "node must not have child subtrees", id)
    end
  end

  @doc false
  def native_binding_role(
        %BindingProjection{source_binding_kind: :collection, projection_kind: kind},
        _node,
        _indexes
      )
      when kind in [:collection_attr, :collection_item_field], do: :repeat

  @doc false
  def native_binding_role(
        %BindingProjection{source_binding_kind: :value} = projection,
        %DesignNode{semantic_type: semantic},
        indexes
      ) do
    binding = Map.fetch!(indexes.value_bindings, projection.source_binding_id)

    case {projection.projection_kind, binding.scope, binding.value_kind, binding.target_kind,
          semantic} do
      {:scalar_attr, :site, :field, :text, kind} when kind in ~w(heading paragraph rich_text) ->
        :text_content

      {:scalar_attr, :current_entity, :field, :rich_text, "rich_text"} ->
        :text_content

      {:scalar_attr, :site, :field, :asset, "image"} ->
        :asset_src

      {:scalar_attr, :site, :field, :link_url, "link"} ->
        :link_url

      {:collection_item_field, :collection_item, :field, :text, kind}
      when kind in ~w(heading paragraph rich_text) ->
        :text_content

      {:collection_item_field, :collection_item, :field, :asset, "image"} ->
        :asset_src

      {:collection_item_field, :collection_item, :field, :text, "image"} ->
        :asset_alt

      {:collection_item_field, :collection_item, :field, :link_url, "link"} ->
        :link_url

      {kind, :collection, :collection_count, :text, node_kind}
      when kind in [:collection_count_attr, :collection_item_field] and
             node_kind in ~w(heading paragraph rich_text) ->
        :text_content

      _ ->
        :unsupported
    end
  end

  @doc false
  def native_binding_role(_projection, _node, _indexes), do: :unsupported

  defp validate_native_tag(diagnostics, node, roles, indexes, native_realization_authority) do
    heading = Map.get(roles, :heading_level)

    diagnostics =
      if native_tag(node, heading != nil) == :error and
           not authorized_selection_control_node?(node, native_realization_authority) do
        native_error(
          diagnostics,
          "tag_unsupported",
          "node has no compatible native tag",
          node.node_id
        )
      else
        diagnostics
      end

    if heading != nil do
      attr = Map.fetch!(indexes.attrs_by_name, heading.public_attr_name)

      if not attr.required and attr.default == nil,
        do:
          native_error(
            diagnostics,
            "heading_level_optional",
            "public heading level requires requiredness or an explicit default",
            node.node_id
          ),
        else: diagnostics
    else
      diagnostics
    end
  end

  defp authorized_selection_control_node?(
         %DesignNode{node_id: node_id, semantic_type: "generic", attributes: attributes},
         %NativeRealizationAuthority{control_node_id: node_id}
       ) do
    Map.get(attributes, "tag") == "button"
  end

  defp authorized_selection_control_node?(_node, _authority), do: false

  defp validate_native_boundary_image(diagnostics, node, roles, plan, indexes) do
    if node.node_id == plan.boundary_node_id and node.semantic_type == "image" do
      case boundary_asset_src_input(Map.get(roles, :asset_src), indexes) do
        {:optional, :no_default} ->
          native_error(
            diagnostics,
            "boundary_optional_image",
            "optional image source would remove the component root",
            node.node_id
          )

        _ ->
          diagnostics
      end
    else
      diagnostics
    end
  end

  defp boundary_asset_src_input(%RenderProjection{public_attr_name: name}, indexes)
       when is_binary(name) do
    boundary_attr_src_input(Map.fetch!(indexes.attrs_by_name, name))
  end

  defp boundary_asset_src_input(
         %BindingProjection{projection_kind: :scalar_attr, public_attr_name: name},
         indexes
       )
       when is_binary(name) do
    boundary_attr_src_input(Map.fetch!(indexes.attrs_by_name, name))
  end

  defp boundary_asset_src_input(
         %BindingProjection{
           projection_kind: :collection_item_field,
           source_collection_binding_id: cb_id,
           item_field_name: field_name
         },
         indexes
       )
       when is_binary(cb_id) and is_binary(field_name) do
    case get_in(indexes.item_fields_by_collection, [cb_id, field_name]) do
      %ItemField{} = field -> boundary_item_field_src_input(field)
      _ -> :unknown
    end
  end

  defp boundary_asset_src_input(_role, _indexes), do: :unknown

  defp boundary_attr_src_input(%Attr{required: true}), do: {:required, :_}

  defp boundary_attr_src_input(%Attr{default: default}) when not is_nil(default),
    do: {:default, :_}

  defp boundary_attr_src_input(%Attr{}), do: {:optional, :no_default}

  defp boundary_item_field_src_input(%ItemField{required: true}), do: {:required, :_}

  defp boundary_item_field_src_input(%ItemField{default: default}) when not is_nil(default),
    do: {:default, :_}

  defp boundary_item_field_src_input(%ItemField{}), do: {:optional, :no_default}

  defp validate_native_navigation(
         diagnostics,
         %DesignNode{semantic_type: "heading"} = node,
         roles,
         slot_owned?
       ) do
    if Map.has_key?(node.attributes, "navigation") do
      if static_heading_navigation_shape?(node, roles, slot_owned?) do
        validate_static_navigation(diagnostics, node)
      else
        native_error(
          diagnostics,
          "heading_navigation_invalid",
          "navigable heading requires a proven heading tag, non-empty static text, no children, and no dynamic or slot placement",
          node.node_id
        )
      end
    else
      diagnostics
    end
  end

  defp validate_native_navigation(diagnostics, node, roles, _slot_owned?) do
    if node.semantic_type in ["link", "button"] and
         Map.has_key?(node.attributes, "navigation") and not Map.has_key?(roles, :link_url) do
      validate_static_navigation(diagnostics, node)
    else
      diagnostics
    end
  end

  defp static_heading_navigation_shape?(
         %DesignNode{attributes: attributes, content: content, children: []},
         roles,
         false
       )
       when is_map(attributes) and is_binary(content) do
    attributes["tag"] in @heading_navigation_tags and String.valid?(content) and
      String.trim(content) != "" and
      Enum.all?([:text_content, :heading_level, :link_url, :subtree_slot], fn role ->
        not Map.has_key?(roles, role)
      end)
  end

  defp static_heading_navigation_shape?(_node, _roles, _slot_owned?), do: false

  defp validate_static_navigation(diagnostics, node) do
    case LiveFrames.StaticNavigation.validate_navigation_map(node.attributes["navigation"]) do
      {:ok, _attrs} ->
        diagnostics

      {:error, _reason} ->
        native_error(
          diagnostics,
          "static_navigation_invalid",
          "internal static navigation is invalid",
          node.node_id
        )
    end
  end

  defp native_error(diagnostics, code, message, id) do
    add(
      diagnostics,
      error_at("componentization_plan.native_generation." <> code, message, "nodes[#{id}]")
    )
  end

  defp normalized_registry(registry) when is_map(registry) and not is_struct(registry),
    do: registry

  defp normalized_registry(_registry), do: %{}

  defp binding_public_target(%BindingProjection{public_attr_name: name}) when is_binary(name),
    do: {:attr, name}

  defp binding_public_target(%BindingProjection{public_slot_name: name}) when is_binary(name),
    do: {:slot, name}

  defp binding_public_target(_projection), do: nil

  defp render_public_target(%RenderProjection{public_attr_name: name, public_slot_name: nil}),
    do: {:attr, name}

  defp render_public_target(%RenderProjection{public_attr_name: nil, public_slot_name: name}),
    do: {:slot, name}

  defp append_result(diagnostics, :ok), do: diagnostics
  defp append_result(diagnostics, {:error, values}), do: diagnostics ++ values

  defp contract_approval_result(%ComponentContract{approval_status: :approved}), do: :ok

  defp contract_approval_result(%ComponentContract{}) do
    {:error,
     [
       %ContractDiagnostic{
         code: "component_contract.approval_blocked",
         severity: :error,
         message: "contract is not approved for generation"
       }
     ]}
  end

  defp contract_approval_result(_contract), do: :ok

  defp append_contract_gate(diagnostics, :ok), do: diagnostics

  defp append_contract_gate(diagnostics, {:error, upstream}) do
    [
      upstream_error(
        "componentization_plan.contract.mismatch",
        "ComponentContract is not generation-eligible",
        upstream
      )
      | diagnostics
    ]
  end

  defp upstream_error(code, message, diagnostics) do
    codes =
      diagnostics
      |> Enum.map(&Map.get(&1, :code))
      |> Enum.filter(&is_binary/1)
      |> Enum.uniq()
      |> Enum.sort()

    %Diagnostic{
      code: code,
      severity: :error,
      message: message,
      metadata: %{"upstream_codes" => codes}
    }
  end

  defp generation_blocked(diagnostics) do
    codes =
      diagnostics
      |> Enum.map(& &1.code)
      |> Enum.filter(&is_binary/1)
      |> Enum.uniq()
      |> Enum.sort()

    %Diagnostic{
      code: "componentization_plan.generation_blocked",
      severity: :error,
      message: "generation inputs contain blocking plan or contract diagnostics",
      metadata: %{"blocking_codes" => codes}
    }
  end

  defp finish([]), do: :ok

  defp finish(diagnostics) do
    {:error,
     diagnostics
     |> Enum.sort_by(fn diagnostic ->
       {diagnostic.path || "", diagnostic.code || "", diagnostic.message || ""}
     end)}
  end

  defp add(diagnostics, diagnostic), do: [diagnostic | diagnostics]

  defp error(code, message),
    do: %Diagnostic{code: code, severity: :error, message: message}

  defp error_at(code, message, path),
    do: %Diagnostic{code: code, severity: :error, message: message, path: path}
end
