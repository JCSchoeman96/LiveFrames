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
      {diagnostics, id_state, _index} =
        Enum.reduce(dispositions, {[], initial_design_node_id_state(), 0}, fn
          disposition, {diagnostics, id_state, index} ->
            path = "node_dispositions[#{index}]"

            diagnostics =
              case validate(disposition) do
                :ok ->
                  diagnostics

                {:error, errors} ->
                  Enum.reduce(errors, diagnostics, fn error, acc ->
                    [prefix_path(error, path) | acc]
                  end)
              end

            id_state = track_design_node_id(valid_design_node_id(disposition), id_state)
            {diagnostics, id_state, index + 1}
        end)

      diagnostics
      |> validate_design_node_id_state(id_state)
      |> finish()
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
        invalid_evidence_refs_list(diagnostics)

      refs == [] ->
        add(
          diagnostics,
          error_at("evidence_refs.empty", "evidence_refs must be non-empty", "evidence_refs")
        )

      true ->
        {diagnostics, valid_refs?, _index, _seen, _previous, duplicate?, ordered?} =
          Enum.reduce(
            refs,
            {diagnostics, true, 0, MapSet.new(), nil, false, true},
            fn ref, {diagnostics, valid_refs?, index, seen, previous, duplicate?, ordered?} ->
              if valid_string?(ref) and byte_size(ref) > 0 do
                duplicate? = duplicate? or MapSet.member?(seen, ref)
                ordered? = ordered? and (is_nil(previous) or previous <= ref)

                {
                  diagnostics,
                  valid_refs?,
                  index + 1,
                  MapSet.put(seen, ref),
                  ref,
                  duplicate?,
                  ordered?
                }
              else
                diagnostic =
                  error_at(
                    "evidence_refs.invalid",
                    "evidence references must be non-empty UTF-8 strings",
                    "evidence_refs[#{index}]"
                  )

                {add(diagnostics, diagnostic), false, index + 1, seen, previous, duplicate?,
                 ordered?}
              end
            end
          )

        if valid_refs? do
          diagnostics
          |> maybe_add_evidence_duplicate(duplicate?)
          |> maybe_add_evidence_order(not ordered?)
        else
          diagnostics
        end
    end
  end

  defp valid_design_node_id(%__MODULE__{design_node_id: value} = disposition) do
    if exact_fields?(disposition) and valid_string?(value) and byte_size(value) > 0, do: value
  end

  defp valid_design_node_id(_disposition), do: nil

  defp initial_design_node_id_state, do: {MapSet.new(), nil, false, true, false}

  defp track_design_node_id(nil, {seen, previous, duplicate?, ordered?, _invalid?}),
    do: {seen, previous, duplicate?, ordered?, true}

  defp track_design_node_id(id, {seen, previous, duplicate?, ordered?, invalid?}) do
    duplicate? = duplicate? or MapSet.member?(seen, id)
    ordered? = ordered? and (is_nil(previous) or previous <= id)

    {MapSet.put(seen, id), id, duplicate?, ordered?, invalid?}
  end

  defp validate_design_node_id_state(diagnostics, {_, _, duplicate?, ordered?, invalid?}) do
    diagnostics =
      if duplicate? do
        add(
          diagnostics,
          error_at(
            "design_node_id.duplicate",
            "each design_node_id may have one NodeDisposition",
            "node_dispositions"
          )
        )
      else
        diagnostics
      end

    if invalid? or ordered? do
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

  defp invalid_evidence_refs_list(diagnostics) do
    add(
      diagnostics,
      error_at(
        "evidence_refs.invalid",
        "evidence_refs must be a proper list",
        "evidence_refs"
      )
    )
  end

  defp maybe_add_evidence_duplicate(diagnostics, true) do
    add(
      diagnostics,
      error_at(
        "evidence_refs.duplicate",
        "evidence_refs must be unique",
        "evidence_refs"
      )
    )
  end

  defp maybe_add_evidence_duplicate(diagnostics, false), do: diagnostics

  defp maybe_add_evidence_order(diagnostics, true) do
    add(
      diagnostics,
      error_at(
        "evidence_refs.order_invalid",
        "evidence_refs must use ascending Unicode scalar order",
        "evidence_refs"
      )
    )
  end

  defp maybe_add_evidence_order(diagnostics, false), do: diagnostics

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
