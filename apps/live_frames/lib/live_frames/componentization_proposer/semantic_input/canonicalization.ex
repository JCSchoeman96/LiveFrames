defmodule LiveFrames.ComponentizationProposer.SemanticInput.Canonicalization do
  @moduledoc false
  alias LiveFrames.ComponentizationProposer.SemanticInput
  alias LiveFrames.ComponentizationProposer.Diagnostic

  # Called only after record shapes have been checked. Enum ranks are explicit;
  # all remaining identity components are UTF-8 binaries.
  def canonicalize(input) do
    Enum.reduce(SemanticInput.repeatable_families(), {:ok, input}, fn family, result ->
      decisions = Map.fetch!(input, family)

      {_, conflicts} =
        Enum.reduce(decisions, {MapSet.new(), []}, fn decision, {seen, errors} ->
          key = identity(family, decision)

          errors =
            if MapSet.member?(seen, key),
              do: [
                %Diagnostic{
                  code: "componentization_proposer.input.conflict",
                  path: Atom.to_string(family),
                  message: "Duplicate canonical identity #{inspect(key)}"
                }
                | errors
              ],
              else: errors

          {MapSet.put(seen, key), errors}
        end)

      case {result, conflicts} do
        {{:ok, canonical}, []} ->
          {:ok, Map.put(canonical, family, Enum.sort_by(decisions, &sort_key(family, &1)))}

        {{:ok, _}, errors} ->
          {:error, errors}

        {{:error, errors}, more} ->
          {:error, more ++ errors}
      end
    end)
  end

  def identity(:public_attrs, d), do: d.name
  def identity(:public_slots, d), do: d.name

  def identity(family, d) when family in [:collection_admissions, :collection_count_links],
    do: d.source_collection_binding_id

  def identity(:item_fields, d), do: {d.source_collection_binding_id, d.name}

  def identity(family, d) when family in [:binding_assignments, :evidence_handling],
    do: {d.source_binding_kind, d.source_binding_id}

  def identity(:render_placements, d),
    do: {d.public_target_kind, d.public_target_name}

  def identity(:image_accessibility, %{target_kind: :attr} = d), do: {:attr, d.target_name}

  def identity(:image_accessibility, d),
    do: {:item_field, d.source_collection_binding_id, d.target_name}

  def identity(:static_content_dispositions, %{target_kind: :internal_node} = d),
    do: {:internal_node, d.design_node_id}

  def identity(:static_content_dispositions, %{target_kind: :promote_attr} = d),
    do: {:promote_attr, d.public_target_name}

  def identity(:static_content_dispositions, d), do: {:promote_slot, d.public_target_name}

  defp sort_key(family, d) when family in [:binding_assignments, :evidence_handling],
    do: {binding_rank(d.source_binding_kind), d.source_binding_id}

  defp sort_key(:render_placements, d),
    do: {target_rank(d.public_target_kind), d.public_target_name}

  defp sort_key(:image_accessibility, %{target_kind: :attr} = d), do: {"attr", "", d.target_name}

  defp sort_key(:image_accessibility, d),
    do: {"item_field", d.source_collection_binding_id, d.target_name}

  defp sort_key(:static_content_dispositions, %{target_kind: :internal_node} = d),
    do: {"internal_node", d.design_node_id}

  defp sort_key(:static_content_dispositions, d),
    do: {Atom.to_string(d.target_kind), d.public_target_name}

  defp sort_key(family, d), do: identity(family, d)
  defp binding_rank(:collection), do: 0
  defp binding_rank(:value), do: 1
  defp target_rank(:attr), do: 0
  defp target_rank(:slot), do: 1
end
