defmodule LiveFrames.ComponentizationPlan.NodeDisposition do
  @moduledoc false

  alias LiveFrames.ComponentizationPlan.Diagnostic

  @digest_pattern ~r/^[0-9a-f]{64}$/
  @review_id_pattern ~r/^brv_[0-9a-f]{64}$/
  @fields [
    :design_node_id,
    :disposition,
    :source_type,
    :source_id,
    :behavior_binding_id,
    :behavior_contract_digest,
    :behavior_review_id,
    :evidence_refs
  ]

  @type t :: %__MODULE__{
          design_node_id: String.t(),
          disposition: :exclude_source_runtime_carrier,
          source_type: String.t(),
          source_id: String.t(),
          behavior_binding_id: String.t(),
          behavior_contract_digest: String.t(),
          behavior_review_id: String.t(),
          evidence_refs: [String.t()]
        }

  defstruct @fields

  @spec validate(term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate(%__MODULE__{} = disposition) do
    if exact_fields?(disposition) do
      diagnostics = []

      diagnostics =
        Enum.reduce(
          [:design_node_id, :source_type, :source_id, :behavior_binding_id],
          diagnostics,
          fn field, diagnostics ->
            validate_non_empty_string(
              diagnostics,
              Map.fetch!(disposition, field),
              Atom.to_string(field)
            )
          end
        )

      diagnostics = validate_disposition(disposition.disposition, diagnostics)

      diagnostics =
        validate_pattern(
          diagnostics,
          disposition.behavior_contract_digest,
          @digest_pattern,
          "behavior_contract_digest",
          "behavior_contract_digest must be 64 lowercase hexadecimal characters"
        )

      diagnostics =
        validate_pattern(
          diagnostics,
          disposition.behavior_review_id,
          @review_id_pattern,
          "behavior_review_id",
          "behavior_review_id must be brv_ followed by 64 lowercase hexadecimal characters"
        )

      diagnostics = validate_evidence_refs(disposition.evidence_refs, diagnostics)
      finish(diagnostics)
    else
      finish([shape_error("NodeDisposition must contain exactly its declared fields")])
    end
  end

  def validate(_term) do
    finish([shape_error("expected a NodeDisposition struct")])
  end

  @spec validate_list(term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate_list(dispositions) do
    if proper_list?(dispositions) do
      {diagnostics, design_node_ids} =
        dispositions
        |> Enum.with_index()
        |> Enum.reduce({[], []}, fn {disposition, index}, {diagnostics, ids} ->
          path = "node_dispositions[#{index}]"

          diagnostics =
            case validate(disposition) do
              :ok -> diagnostics
              {:error, errors} -> diagnostics ++ Enum.map(errors, &prefix_path(&1, path))
            end

          id = valid_design_node_id(disposition)
          {diagnostics, ids ++ [id]}
        end)

      diagnostics = validate_unique_design_node_ids(design_node_ids, diagnostics)
      diagnostics = validate_design_node_id_order(design_node_ids, diagnostics)
      finish(diagnostics)
    else
      finish([
        error_at("list.invalid", "node_dispositions must be a proper list", "node_dispositions")
      ])
    end
  end

  defp exact_fields?(disposition) do
    Map.keys(disposition) |> Enum.sort() == Enum.sort([:__struct__ | @fields])
  end

  defp validate_non_empty_string(diagnostics, value, field) do
    if valid_string?(value) and byte_size(value) > 0 do
      diagnostics
    else
      add(
        diagnostics,
        error_at(
          "field.invalid",
          "#{field} must be a non-empty UTF-8 string",
          field
        )
      )
    end
  end

  defp validate_disposition(:exclude_source_runtime_carrier, diagnostics), do: diagnostics

  defp validate_disposition(_value, diagnostics) do
    add(
      diagnostics,
      error_at(
        "disposition.unsupported",
        "disposition is not supported",
        "disposition"
      )
    )
  end

  defp validate_pattern(diagnostics, value, pattern, field, message) do
    if valid_string?(value) and Regex.match?(pattern, value) do
      diagnostics
    else
      add(diagnostics, error_at(field <> ".invalid", message, field))
    end
  end

  defp validate_evidence_refs(refs, diagnostics) do
    cond do
      not proper_list?(refs) ->
        add(
          diagnostics,
          error_at(
            "evidence_refs.invalid",
            "evidence_refs must be a proper list",
            "evidence_refs"
          )
        )

      refs == [] ->
        add(
          diagnostics,
          error_at("evidence_refs.empty", "evidence_refs must be non-empty", "evidence_refs")
        )

      true ->
        {diagnostics, valid_refs?} =
          refs
          |> Enum.with_index()
          |> Enum.reduce({diagnostics, true}, fn {ref, index}, {diagnostics, valid_refs?} ->
            if valid_string?(ref) and byte_size(ref) > 0 do
              {diagnostics, valid_refs?}
            else
              diagnostic =
                error_at(
                  "evidence_refs.invalid",
                  "evidence references must be non-empty UTF-8 strings",
                  "evidence_refs[#{index}]"
                )

              {add(diagnostics, diagnostic), false}
            end
          end)

        if valid_refs? do
          diagnostics
          |> validate_unique_evidence_refs(refs)
          |> validate_evidence_ref_order(refs)
        else
          diagnostics
        end
    end
  end

  defp validate_unique_evidence_refs(diagnostics, refs) do
    if length(Enum.uniq(refs)) == length(refs) do
      diagnostics
    else
      add(
        diagnostics,
        error_at(
          "evidence_refs.duplicate",
          "evidence_refs must be unique",
          "evidence_refs"
        )
      )
    end
  end

  defp validate_evidence_ref_order(diagnostics, refs) do
    # UTF-8 byte order preserves Unicode scalar order for valid strings.
    if Enum.sort(refs) == refs do
      diagnostics
    else
      add(
        diagnostics,
        error_at(
          "evidence_refs.order_invalid",
          "evidence_refs must use ascending Unicode scalar order",
          "evidence_refs"
        )
      )
    end
  end

  defp valid_design_node_id(%__MODULE__{design_node_id: value} = disposition) do
    if exact_fields?(disposition) and valid_string?(value) and byte_size(value) > 0, do: value
  end

  defp valid_design_node_id(_disposition), do: nil

  defp validate_unique_design_node_ids(ids, diagnostics) do
    valid_ids = Enum.reject(ids, &is_nil/1)

    if length(Enum.uniq(valid_ids)) == length(valid_ids) do
      diagnostics
    else
      add(
        diagnostics,
        error_at(
          "design_node_id.duplicate",
          "each design_node_id may have one NodeDisposition",
          "node_dispositions"
        )
      )
    end
  end

  defp validate_design_node_id_order(ids, diagnostics) do
    if Enum.all?(ids, &(is_binary(&1) and valid_string?(&1))) and Enum.sort(ids) == ids do
      diagnostics
    else
      if Enum.any?(ids, &is_nil/1) do
        diagnostics
      else
        add(
          diagnostics,
          error_at(
            "design_node_id.order_invalid",
            "node_dispositions must use ascending UTF-8 design_node_id byte order",
            "node_dispositions"
          )
        )
      end
    end
  end

  defp prefix_path(%Diagnostic{path: nil} = diagnostic, prefix),
    do: %{diagnostic | path: prefix}

  defp prefix_path(%Diagnostic{} = diagnostic, prefix),
    do: %{diagnostic | path: prefix <> "." <> diagnostic.path}

  defp valid_string?(value), do: is_binary(value) and String.valid?(value)

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_tail), do: false

  defp shape_error(message),
    do: error_at("shape.invalid", message, "node_disposition")

  defp finish([]), do: :ok

  defp finish(diagnostics) do
    {:error,
     diagnostics
     |> Enum.sort_by(fn diagnostic ->
       {diagnostic.path || "", diagnostic.code || "", diagnostic.message || ""}
     end)}
  end

  defp add(diagnostics, diagnostic), do: [diagnostic | diagnostics]

  defp error_at(suffix, message, path),
    do: %Diagnostic{
      code: "componentization_plan.node_disposition." <> suffix,
      severity: :error,
      message: message,
      path: path
    }
end
