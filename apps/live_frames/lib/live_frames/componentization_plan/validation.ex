defmodule LiveFrames.ComponentizationPlan.Validation do
  @moduledoc false

  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.ComponentizationPlan.Diagnostic
  alias LiveFrames.ComponentizationPlan.Json
  alias LiveFrames.ComponentizationPlan.RenderProjection

  @fingerprint_pattern ~r/^[0-9a-f]{64}$/

  @spec validate(term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate(%ComponentizationPlan{} = plan) do
    diagnostics = []
    diagnostics = validate_version(diagnostics, plan.plan_format_version)

    diagnostics =
      validate_non_empty_string(
        diagnostics,
        plan.contract_id,
        "componentization_plan.plan.invalid",
        "contract_id must be a non-empty string",
        "contract_id"
      )

    diagnostics = validate_fingerprint(diagnostics, plan.design_document_sha256)

    diagnostics =
      validate_non_empty_string(
        diagnostics,
        plan.boundary_node_id,
        "componentization_plan.boundary.invalid",
        "boundary_node_id must be a non-empty string",
        "boundary_node_id"
      )

    {diagnostics, _targets} = validate_render_projections(plan.render_projections, diagnostics)
    diagnostics = validate_diagnostics(plan.diagnostics, diagnostics)

    diagnostics =
      if Json.object?(plan.provenance) do
        diagnostics
      else
        add(
          diagnostics,
          error_at(
            "componentization_plan.metadata.invalid",
            "provenance must be an inert JSON object with unique normalized keys",
            "provenance"
          )
        )
      end

    finish(diagnostics)
  end

  def validate(_plan) do
    finish([
      error(
        "componentization_plan.plan.invalid",
        "expected a ComponentizationPlan struct"
      )
    ])
  end

  defp validate_version(diagnostics, "1.0.0"), do: diagnostics

  defp validate_version(diagnostics, version) when is_binary(version) do
    add(
      diagnostics,
      error_at(
        "componentization_plan.version.unsupported",
        "plan_format_version is not supported",
        "plan_format_version"
      )
    )
  end

  defp validate_version(diagnostics, _version) do
    add(
      diagnostics,
      error_at(
        "componentization_plan.version.invalid",
        "plan_format_version must be a string",
        "plan_format_version"
      )
    )
  end

  defp validate_non_empty_string(diagnostics, value, code, message, path) do
    if valid_string?(value) and byte_size(value) > 0 do
      diagnostics
    else
      add(diagnostics, error_at(code, message, path))
    end
  end

  defp validate_fingerprint(diagnostics, value) do
    if valid_string?(value) and Regex.match?(@fingerprint_pattern, value) do
      diagnostics
    else
      add(
        diagnostics,
        error_at(
          "componentization_plan.design_document.fingerprint_invalid",
          "design_document_sha256 must be 64 lowercase hexadecimal characters",
          "design_document_sha256"
        )
      )
    end
  end

  defp validate_render_projections(projections, diagnostics) do
    if proper_list?(projections) do
      validate_render_projection_list(projections, diagnostics)
    else
      diagnostic =
        error_at(
          "componentization_plan.render_projection.invalid",
          "render_projections must be a proper list",
          "render_projections"
        )

      {add(diagnostics, diagnostic), MapSet.new()}
    end
  end

  defp validate_render_projection_list(projections, diagnostics) do
    Enum.reduce(Enum.with_index(projections), {diagnostics, MapSet.new()}, fn
      {projection, index}, {diagnostics, targets} ->
        path = "render_projections[#{index}]"

        case projection do
          %RenderProjection{} = render_projection ->
            diagnostics = validate_render_projection(diagnostics, render_projection, path)
            identity = projection_identity(render_projection)

            if identity && MapSet.member?(targets, identity) do
              diagnostic =
                error_at(
                  "componentization_plan.render_projection.duplicate_target",
                  "each public attr or slot may have one RenderProjection",
                  path
                )

              {add(diagnostics, diagnostic), targets}
            else
              {diagnostics, if(identity, do: MapSet.put(targets, identity), else: targets)}
            end

          _ ->
            {add(
               diagnostics,
               error_at(
                 "componentization_plan.render_projection.invalid",
                 "render_projections must contain RenderProjection structs",
                 path
               )
             ), targets}
        end
    end)
  end

  defp validate_render_projection(diagnostics, projection, path) do
    diagnostics =
      validate_non_empty_string(
        diagnostics,
        projection.target_node_id,
        "componentization_plan.render_projection.invalid",
        "target_node_id must be a non-empty string",
        path <> ".target_node_id"
      )

    {attr?, diagnostics} =
      validate_optional_name(
        diagnostics,
        projection.public_attr_name,
        path <> ".public_attr_name"
      )

    {slot?, diagnostics} =
      validate_optional_name(
        diagnostics,
        projection.public_slot_name,
        path <> ".public_slot_name"
      )

    diagnostics =
      if attr? != slot? do
        diagnostics
      else
        add(
          diagnostics,
          error_at(
            "componentization_plan.render_projection.invalid",
            "exactly one non-empty public attr or slot name is required",
            path
          )
        )
      end

    if projection.render_role in RenderProjection.render_roles() do
      diagnostics
    else
      add(
        diagnostics,
        error_at(
          "componentization_plan.render_projection.invalid",
          "render_role is not supported",
          path <> ".render_role"
        )
      )
    end
  end

  defp validate_optional_name(diagnostics, nil, _path), do: {false, diagnostics}

  defp validate_optional_name(diagnostics, value, path) do
    if valid_string?(value) and byte_size(value) > 0 do
      {true, diagnostics}
    else
      {false,
       add(
         diagnostics,
         error_at(
           "componentization_plan.render_projection.invalid",
           "public target names must be non-empty strings or nil",
           path
         )
       )}
    end
  end

  defp projection_identity(%RenderProjection{public_attr_name: name, public_slot_name: nil})
       when is_binary(name) and name != "",
       do: {:attr, name}

  defp projection_identity(%RenderProjection{public_attr_name: nil, public_slot_name: name})
       when is_binary(name) and name != "",
       do: {:slot, name}

  defp projection_identity(_projection), do: nil

  defp validate_diagnostics(values, diagnostics) do
    if proper_list?(values) do
      validate_diagnostic_list(values, diagnostics)
    else
      add(
        diagnostics,
        error_at(
          "componentization_plan.metadata.invalid",
          "diagnostics must be a proper list",
          "diagnostics"
        )
      )
    end
  end

  defp validate_diagnostic_list(values, diagnostics) do
    Enum.reduce(Enum.with_index(values), diagnostics, fn
      {%Diagnostic{} = diagnostic, index}, diagnostics ->
        validate_diagnostic(diagnostics, diagnostic, "diagnostics[#{index}]")

      {_invalid, index}, diagnostics ->
        add(
          diagnostics,
          error_at(
            "componentization_plan.metadata.invalid",
            "diagnostics must contain Diagnostic structs",
            "diagnostics[#{index}]"
          )
        )
    end)
  end

  defp validate_diagnostic(diagnostics, diagnostic, path) do
    diagnostics =
      if valid_string?(diagnostic.code) and
           String.starts_with?(diagnostic.code, "componentization_plan.") do
        diagnostics
      else
        add(
          diagnostics,
          error_at(
            "componentization_plan.metadata.invalid",
            "diagnostic code must use the componentization_plan. prefix",
            path <> ".code"
          )
        )
      end

    diagnostics =
      if diagnostic.severity in Diagnostic.severities() do
        diagnostics
      else
        add(
          diagnostics,
          error_at(
            "componentization_plan.metadata.invalid",
            "diagnostic severity is not supported",
            path <> ".severity"
          )
        )
      end

    diagnostics =
      if valid_string?(diagnostic.message) and byte_size(diagnostic.message) > 0 do
        diagnostics
      else
        add(
          diagnostics,
          error_at(
            "componentization_plan.metadata.invalid",
            "diagnostic message must be a non-empty string",
            path <> ".message"
          )
        )
      end

    diagnostics
    |> validate_optional_string(diagnostic.path, path <> ".path")
    |> validate_optional_string(diagnostic.suggested_action, path <> ".suggested_action")
    |> then(fn d ->
      if Json.object?(diagnostic.metadata) do
        d
      else
        add(
          d,
          error_at(
            "componentization_plan.metadata.invalid",
            "diagnostic metadata must be an inert JSON object",
            path <> ".metadata"
          )
        )
      end
    end)
  end

  defp validate_optional_string(diagnostics, nil, _path), do: diagnostics

  defp validate_optional_string(diagnostics, value, path) do
    if valid_string?(value) do
      diagnostics
    else
      add(
        diagnostics,
        error_at(
          "componentization_plan.metadata.invalid",
          "value must be a string or nil",
          path
        )
      )
    end
  end

  defp valid_string?(value), do: is_binary(value) and String.valid?(value)

  defp finish([]), do: :ok

  defp finish(diagnostics) do
    {:error,
     diagnostics
     |> Enum.sort_by(fn diagnostic ->
       {diagnostic.path || "", diagnostic.code || "", diagnostic.message || ""}
     end)}
  end

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_tail), do: false

  defp add(diagnostics, diagnostic), do: [diagnostic | diagnostics]

  defp error(code, message),
    do: %Diagnostic{code: code, severity: :error, message: message}

  defp error_at(code, message, path),
    do: %Diagnostic{code: code, severity: :error, message: message, path: path}
end
