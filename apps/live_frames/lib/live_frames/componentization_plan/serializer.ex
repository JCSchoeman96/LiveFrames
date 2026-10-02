defmodule LiveFrames.ComponentizationPlan.Serializer do
  @moduledoc false

  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.Diagnostic
  alias LiveFrames.ComponentizationPlan.Json
  alias LiveFrames.ComponentizationPlan.RenderProjection
  alias LiveFrames.ComponentizationPlan.Validation

  @spec to_map(term()) :: map() | {:error, [Diagnostic.t()]}
  def to_map(%ComponentizationPlan{} = plan) do
    case Validation.validate(plan) do
      :ok -> to_map_valid(plan)
      {:error, diagnostics} -> {:error, diagnostics}
    end
  end

  def to_map(plan), do: Validation.validate(plan)

  @spec encode(term()) :: {:ok, String.t()} | {:error, [Diagnostic.t()]}
  def encode(plan) do
    case to_map(plan) do
      {:error, diagnostics} ->
        {:error, diagnostics}

      mapped when is_map(mapped) ->
        try do
          {:ok, Jason.encode!(ordered(mapped), maps: :strict)}
        rescue
          _error ->
            {:error,
             [
               %Diagnostic{
                 code: "componentization_plan.metadata.invalid",
                 severity: :error,
                 message: "plan could not be encoded as JSON"
               }
             ]}
        end
    end
  end

  @spec encode!(term()) :: String.t()
  def encode!(plan) do
    case encode(plan) do
      {:ok, encoded} ->
        encoded

      {:error, diagnostics} ->
        raise ComponentizationPlan.ValidationError, diagnostics: diagnostics
    end
  end

  defp to_map_valid(plan) do
    {:ok, provenance} = Json.normalize(plan.provenance)

    %{
      "plan_format_version" => plan.plan_format_version,
      "contract_id" => plan.contract_id,
      "design_document_sha256" => plan.design_document_sha256,
      "boundary_node_id" => plan.boundary_node_id,
      "render_projections" => Enum.map(plan.render_projections, &render_projection_to_map/1),
      "diagnostics" => Enum.map(plan.diagnostics, &diagnostic_to_map/1),
      "provenance" => provenance
    }
  end

  defp render_projection_to_map(%RenderProjection{} = projection) do
    %{
      "public_attr_name" => projection.public_attr_name,
      "public_slot_name" => projection.public_slot_name,
      "target_node_id" => projection.target_node_id,
      "render_role" => Atom.to_string(projection.render_role)
    }
  end

  defp diagnostic_to_map(%Diagnostic{} = diagnostic) do
    {:ok, metadata} = Json.normalize(diagnostic.metadata)

    %{
      "code" => diagnostic.code,
      "severity" => Atom.to_string(diagnostic.severity),
      "message" => diagnostic.message,
      "path" => diagnostic.path,
      "suggested_action" => diagnostic.suggested_action,
      "metadata" => metadata
    }
  end

  defp ordered(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} -> {key, ordered(value)} end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Jason.OrderedObject.new()
  end

  defp ordered(list) when is_list(list), do: Enum.map(list, &ordered/1)
  defp ordered(value), do: value
end
