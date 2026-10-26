defmodule LiveFrames.NativeGenerator do
  @moduledoc """
  Deterministic native Phoenix/HEEx generator for approved component tuples.
  """

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentReviewResult
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.Behavior.Binding, as: BehaviorBinding
  alias LiveFrames.Behavior.BindingContainment
  alias LiveFrames.Behavior.Contract, as: BehaviorContract
  alias LiveFrames.Behavior.NativeRealizationAuthority
  alias LiveFrames.Behavior.ReviewResult, as: BehaviorReviewResult
  alias LiveFrames.Behavior.Serializer, as: BehaviorSerializer
  alias LiveFrames.Behavior.Validation, as: BehaviorValidation
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.NativeGenerator.Artifact
  alias LiveFrames.NativeGenerator.Diagnostic
  alias LiveFrames.NativeGenerator.FilteredStructure
  alias LiveFrames.NativeGenerator.GeneratedArtifactBundle
  alias LiveFrames.NativeGenerator.Renderer
  alias LiveFrames.NativeGenerator.StyleIntegration

  @type diagnostic ::
          LiveFrames.Behavior.Diagnostic.t()
          | ComponentContract.Diagnostic.t()
          | ComponentizationPlan.Diagnostic.t()
          | Diagnostic.t()

  @spec generate(ComponentContract.t(), ComponentizationPlan.t(), DesignDocument.t()) ::
          {:ok, GeneratedArtifactBundle.t()}
          | {:error, :generation_blocked, [diagnostic()]}
          | {:error, :generation_failed, [diagnostic()]}
  def generate(contract, plan, design_document) do
    case plan do
      %ComponentizationPlan{node_dispositions: [_ | _]} ->
        {:error, :generation_blocked,
         [
           Diagnostic.error(
             "native_generator.disposition_authority_required",
             "disposition-bearing plans require explicitly selected review authority"
           )
         ]}

      _ ->
        with :ok <- gate_contract(contract, design_document),
             :ok <- gate_plan(plan, contract, design_document) do
          generate_after_gates(contract, plan, design_document, [], nil)
        else
          {:error, :generation_blocked, diagnostics} ->
            {:error, :generation_blocked, diagnostics}
        end
    end
  end

  @spec generate(
          ComponentContract.t(),
          ComponentizationPlan.t(),
          DesignDocument.t(),
          term(),
          term(),
          term(),
          term()
        ) ::
          {:ok, GeneratedArtifactBundle.t()}
          | {:error, :generation_blocked, [diagnostic()]}
          | {:error, :generation_failed, [diagnostic()]}
  def generate(
        approved_component_contract,
        plan,
        design_document,
        behavior_contract,
        selected_behavior_review_result,
        selected_component_review_result,
        selected_component_review_result_id
      ) do
    with :ok <- gate_contract(approved_component_contract, design_document),
         {:ok, native_realization_authority} <-
           gate_behavior_and_native_realization_authority(
             plan,
             approved_component_contract,
             design_document,
             behavior_contract,
             selected_behavior_review_result
           ),
         :ok <-
           gate_component_review_authority(
             selected_component_review_result,
             selected_component_review_result_id,
             approved_component_contract,
             plan,
             design_document
           ) do
      authorized_disposed_node_ids = Enum.map(plan.node_dispositions, & &1.design_node_id)

      generate_after_gates(
        approved_component_contract,
        plan,
        design_document,
        authorized_disposed_node_ids,
        native_realization_authority
      )
    else
      {:error, :generation_blocked, diagnostics} ->
        {:error, :generation_blocked, diagnostics}

      {:error, diagnostics} ->
        {:error, :generation_blocked, diagnostics}
    end
  end

  defp generate_after_gates(
         contract,
         plan,
         design_document,
         authorized_disposed_node_ids,
         native_realization_authority
       ) do
    case FilteredStructure.build(
           design_document,
           plan.boundary_node_id,
           authorized_disposed_node_ids,
           Renderer.package_root_class(contract)
         ) do
      {:ok, filtered_structure} ->
        generate_from_structure(
          contract,
          plan,
          design_document,
          filtered_structure,
          native_realization_authority
        )

      {:error, %Diagnostic{} = diagnostic} ->
        {:error, :generation_blocked, [diagnostic]}
    end
  end

  defp generate_from_structure(
         contract,
         plan,
         design_document,
         filtered_structure,
         native_realization_authority
       ) do
    with {:ok, styling} <-
           StyleIntegration.build(
             contract,
             plan,
             filtered_structure,
             native_realization_authority
           ),
         {:ok, indexes} <-
           Renderer.build_indexes(
             contract,
             plan,
             filtered_structure,
             normalize_registry(design_document.value_bindings),
             styling.primary_action_slot_targets,
             styling.native_realization_authority
           ),
         indexes <- %{
           indexes
           | private_class_owner_ids: Map.keys(styling.private_class_by_id) |> MapSet.new()
         },
         {:ok, source} <- Renderer.render_module(indexes),
         {:ok, bundle} <- build_bundle(contract, plan, design_document, indexes, source, styling) do
      {:ok, bundle}
    else
      {:error, :generation_blocked, diagnostics} ->
        {:error, :generation_blocked, diagnostics}

      {:error, %Diagnostic{} = diagnostic} ->
        {:error, :generation_failed, [diagnostic]}

      {:error, diagnostics} when is_list(diagnostics) ->
        {:error, :generation_failed, diagnostics}
    end
  end

  defp gate_behavior_and_native_realization_authority(
         plan,
         approved_component_contract,
         design_document,
         behavior_contract,
         selected_behavior_review_result
       ) do
    with {:ok, approved_behavior_review_result} <-
           validate_behavior_authority_layer_b1(
             design_document,
             behavior_contract,
             selected_behavior_review_result
           ),
         :ok <-
           ComponentizationPlan.validate_references_with_behavior_authority(
             plan,
             approved_component_contract,
             design_document,
             behavior_contract,
             approved_behavior_review_result
           ) do
      if selection_realization_required?(plan, design_document, behavior_contract) do
        case NativeRealizationAuthority.derive(
               approved_component_contract,
               plan,
               design_document,
               behavior_contract,
               approved_behavior_review_result
             ) do
          {:ok, native_realization_authority} ->
            case ComponentizationPlan.validate_for_generation_with_behavior_and_native_realization_authority(
                   plan,
                   approved_component_contract,
                   design_document,
                   behavior_contract,
                   approved_behavior_review_result,
                   native_realization_authority
                 ) do
              :ok -> {:ok, native_realization_authority}
              {:error, diagnostics} -> {:error, :generation_blocked, diagnostics}
            end

          {:error, diagnostics} ->
            {:error, :generation_blocked, diagnostics}
        end
      else
        case ComponentizationPlan.validate_for_generation_with_behavior_authority(
               plan,
               approved_component_contract,
               design_document,
               behavior_contract,
               approved_behavior_review_result
             ) do
          :ok -> {:ok, nil}
          {:error, diagnostics} -> {:error, :generation_blocked, diagnostics}
        end
      end
    else
      {:error, :generation_blocked, diagnostics} ->
        {:error, :generation_blocked, diagnostics}

      {:error, diagnostics} ->
        {:error, :generation_blocked, diagnostics}
    end
  end

  defp validate_behavior_authority_layer_b1(
         design_document,
         behavior_contract,
         selected_behavior_review_result
       ) do
    with :ok <- BehaviorValidation.validate_structure(design_document, behavior_contract),
         {:ok, _behavior_contract_digest} <- BehaviorSerializer.digest(behavior_contract),
         {:ok, approved_review_result} <-
           BehaviorReviewResult.require_approved(
             [selected_behavior_review_result],
             behavior_contract
           ),
         {:ok, _behavior_review_result_id} <- BehaviorReviewResult.id(approved_review_result) do
      {:ok, approved_review_result}
    end
  end

  defp selection_realization_required?(
         %ComponentizationPlan{boundary_node_id: boundary_node_id},
         design_document,
         %BehaviorContract{bindings: bindings}
       ) do
    selection_bindings =
      Enum.filter(bindings, fn
        %BehaviorBinding{primitive_ref: %{kind: "selection"}} -> true
        _binding -> false
      end)

    case selection_bindings do
      [] ->
        false

      selection_bindings ->
        context = BindingContainment.prepare(design_document, boundary_node_id)

        Enum.any?(selection_bindings, fn binding ->
          BindingContainment.classify_binding(binding, context) in [
            :contained,
            :split,
            :unresolved
          ]
        end)
    end
  end

  defp gate_component_review_authority(
         selected_component_review_result,
         selected_component_review_result_id,
         approved_component_contract,
         plan,
         design_document
       ) do
    with :ok <- ComponentReviewResult.validate(selected_component_review_result),
         {:ok, recomputed_id} <- ComponentReviewResult.id(selected_component_review_result),
         true <- recomputed_id == selected_component_review_result_id,
         true <- selected_component_review_result.decision == "approved",
         true <-
           selected_component_review_result.component_contract_id ==
             approved_component_contract.contract_id,
         :ok <-
           ComponentReviewResult.validate_against(
             selected_component_review_result,
             approved_component_contract,
             plan,
             design_document
           ) do
      :ok
    else
      _ -> component_review_authority_mismatch()
    end
  rescue
    _error -> component_review_authority_mismatch()
  catch
    _kind, _reason -> component_review_authority_mismatch()
  end

  defp component_review_authority_mismatch do
    {:error, :generation_blocked,
     [
       Diagnostic.error(
         "native_generator.component_review_authority_mismatch",
         "selected ComponentReviewResult does not authorize these exact generation inputs"
       )
     ]}
  end

  defp gate_contract(contract, design_document) do
    case ComponentContract.validate_for_generation(contract, design_document) do
      :ok -> :ok
      {:error, diagnostics} -> {:error, :generation_blocked, diagnostics}
    end
  end

  defp gate_plan(plan, contract, design_document) do
    case ComponentizationPlan.validate_for_generation(plan, contract, design_document) do
      :ok -> :ok
      {:error, diagnostics} -> {:error, :generation_blocked, diagnostics}
    end
  end

  defp normalize_registry(registry) when is_map(registry) do
    Enum.reduce(registry, %{}, fn {id, value}, acc ->
      Map.put(acc, to_string(id), value)
    end)
  end

  defp normalize_registry(_registry), do: %{}

  defp build_bundle(contract, plan, design_document, indexes, source, styling) do
    with {:ok, design_document_sha256} <-
           ComponentizationPlan.design_document_sha256(design_document),
         {:ok, plan_bytes} <- ComponentizationPlan.encode(plan) do
      plan_fingerprint =
        :crypto.hash(:sha256, plan_bytes) |> Base.encode16(case: :lower)

      artifacts =
        [
          %Artifact{
            kind: :elixir_module,
            path: indexes.artifact_path,
            content: source
          },
          %Artifact{
            kind: :stylesheet,
            path: styling.stylesheet_path,
            content: styling.stylesheet_content
          }
        ]
        |> Enum.sort_by(& &1.path)

      {:ok,
       %GeneratedArtifactBundle{
         contract_id: contract.contract_id,
         design_document_sha256: design_document_sha256,
         plan_fingerprint: plan_fingerprint,
         artifacts: artifacts
       }}
    else
      {:error, diagnostics} -> {:error, diagnostics}
    end
  end
end
