defmodule LiveFrames.NativeGenerator do
  @moduledoc """
  Deterministic native Phoenix/HEEx generator for approved component tuples.
  """

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.NativeGenerator.Artifact
  alias LiveFrames.NativeGenerator.Diagnostic
  alias LiveFrames.NativeGenerator.GeneratedArtifactBundle
  alias LiveFrames.NativeGenerator.Renderer
  alias LiveFrames.NativeGenerator.StyleIntegration

  @type diagnostic ::
          ComponentContract.Diagnostic.t()
          | ComponentizationPlan.Diagnostic.t()
          | Diagnostic.t()

  @spec generate(ComponentContract.t(), ComponentizationPlan.t(), DesignDocument.t()) ::
          {:ok, GeneratedArtifactBundle.t()}
          | {:error, :generation_blocked, [diagnostic()]}
          | {:error, :generation_failed, [diagnostic()]}
  def generate(contract, plan, design_document) do
    with :ok <- gate_contract(contract, design_document),
         :ok <- gate_plan(plan, contract, design_document),
         {:ok, styling} <- StyleIntegration.build(contract, plan, design_document),
         {:ok, indexes} <-
           Renderer.build_indexes(
             contract,
             plan,
             styling.nodes_by_id,
             normalize_registry(design_document.value_bindings),
             styling.private_class_by_id
           ),
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
