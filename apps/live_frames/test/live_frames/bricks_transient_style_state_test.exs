defmodule LiveFrames.BricksTransientStyleStateTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks.TransientStyleState

  @token "pointer-active"
  @css ".card.pointer-active { opacity: 1; }"

  test "a valid global-class pair produces one hover alias" do
    assert resolve(global_provenance([enter(), leave()])) == %{@token => :hover}
  end

  test "a valid element-local pair produces one hover alias" do
    provenance =
      global_provenance([enter(), leave()])
      |> Map.merge(%{
        origin: :element_local,
        class_id: nil,
        resolution_source: nil,
        authority_ids: [],
        class_reference_index: nil
      })

    assert resolve(provenance) == %{@token => :hover}
  end

  test "the pair is independent of array order" do
    assert resolve(global_provenance([leave(), enter()])) == %{@token => :hover}
  end

  test "a missing enter record produces no alias" do
    assert resolve(global_provenance([leave()])) == %{}
  end

  test "a missing leave record produces no alias" do
    assert resolve(global_provenance([enter()])) == %{}
  end

  test "different enter and leave tokens produce no alias" do
    assert resolve(global_provenance([enter(@token), leave("focus-marker")])) == %{}
  end

  test "a wrong trigger produces no alias" do
    wrong_trigger = Map.put(enter(), "trigger", "pointerenter")

    assert resolve(global_provenance([wrong_trigger, leave()])) == %{}
  end

  test "a wrong action produces no alias" do
    wrong_action = Map.put(enter(), "action", "toggleAttribute")

    assert resolve(global_provenance([wrong_action, leave()])) == %{}
  end

  test "a wrong attribute key produces no alias" do
    wrong_attribute = Map.put(enter(), "actionAttributeKey", "data-state")

    assert resolve(global_provenance([wrong_attribute, leave()])) == %{}
  end

  test "an empty token produces no alias" do
    assert resolve(global_provenance([enter(""), leave("")])) == %{}
  end

  test "a whitespace-only token produces no alias" do
    assert resolve(global_provenance([enter(" \t"), leave(" \t")])) == %{}
  end

  test "a composite class value produces no alias" do
    composite = "pointer-active secondary-marker"

    assert resolve(global_provenance([enter(composite), leave(composite)])) == %{}
  end

  test "exact duplicate records deduplicate to one alias" do
    assert resolve(global_provenance([enter(), leave(), enter(), leave()])) == %{@token => :hover}
  end

  test "two distinct complete token pairs fail closed" do
    assert resolve(
             global_provenance([
               enter(@token),
               leave(@token),
               enter("focus-marker"),
               leave("focus-marker")
             ])
           ) == %{}
  end

  test "contradictory evidence for a candidate token fails closed" do
    contradiction = Map.put(enter(), "action", "toggleAttribute")

    assert resolve(global_provenance([enter(), leave(), contradiction])) == %{}
  end

  test "invalid global-class provenance fails closed" do
    invalid_provenance = [
      %{source_id: nil},
      %{source_id: ""},
      %{class_id: nil},
      %{class_id: ""},
      %{class_reference_index: nil},
      %{class_reference_index: -1},
      %{resolution_source: nil},
      %{resolution_source: :unresolved},
      %{authority_ids: "authority"},
      %{layer_settings: []}
    ]

    Enum.each(invalid_provenance, fn invalid ->
      assert resolve(global_provenance([enter(), leave()], invalid)) == %{}
    end)
  end

  test "invalid element-local provenance fails closed" do
    provenance =
      global_provenance([enter(), leave()])
      |> Map.merge(%{
        origin: :element_local,
        class_id: "unexpected-class",
        resolution_source: nil,
        authority_ids: [],
        class_reference_index: nil
      })

    assert resolve(provenance) == %{}
  end

  test "an unrelated inert record does not establish an alias" do
    unrelated = record("click", "toggleAttribute", "class", "secondary-marker")

    assert resolve(global_provenance([unrelated])) == %{}
  end

  test "a harmless unrelated valid-shape record does not add an alias" do
    unrelated = record("click", "toggleAttribute", "class", "secondary-marker")

    assert resolve(global_provenance([enter(), unrelated, leave()])) == %{@token => :hover}
  end

  test "a non-array interactions collection fails closed" do
    provenance =
      put_interactions(global_provenance([]), %{"enter" => enter(), "leave" => leave()})

    assert resolve(provenance) == %{}
  end

  test "a non-object array member fails the whole collection closed" do
    assert resolve(global_provenance([enter(), leave(), "unsupported-member"])) == %{}
  end

  test "a record missing a required key fails the whole collection closed" do
    incomplete = Map.delete(enter(), "id")

    assert resolve(global_provenance([incomplete, leave()])) == %{}
  end

  test "a record with an additional key fails the whole collection closed" do
    extended = Map.put(enter(), "enabled", "true")

    assert resolve(global_provenance([extended, leave()])) == %{}
  end

  test "a non-string record value fails the whole collection closed" do
    invalid_value = Map.put(enter(), "id", 17)

    assert resolve(global_provenance([invalid_value, leave()])) == %{}
  end

  test "nested record values and nested record members fail closed" do
    nested_value = Map.put(enter(), "actionAttributeValue", %{"token" => @token})

    assert resolve(global_provenance([nested_value, leave()])) == %{}
    assert resolve(global_provenance([[enter(), leave()]])) == %{}
  end

  test "a static token without a complete pair produces no alias" do
    assert resolve(global_provenance([])) == %{}
  end

  test "the resolver leaves CSS and provenance maps unchanged" do
    provenance = global_provenance([enter(), leave()])
    css_before = @css
    provenance_before = provenance

    assert resolve(provenance) == %{@token => :hover}
    assert @css == css_before
    assert provenance == provenance_before
  end

  test "the resolver reads only the supplied layer settings" do
    provenance =
      global_provenance([])
      |> Map.put(:settings, %{"_interactions" => [enter(), leave()]})
      |> Map.put(:resolved, %{settings: %{"_interactions" => [enter(), leave()]}})

    assert resolve(provenance) == %{}
  end

  test "class-layer interactions cannot authorize element-local CSS" do
    provenance =
      global_provenance([])
      |> Map.merge(%{
        origin: :element_local,
        class_id: nil,
        resolution_source: nil,
        authority_ids: [],
        class_reference_index: nil
      })
      |> Map.put(:settings, %{"_interactions" => [enter(), leave()]})

    assert resolve(provenance) == %{}
  end

  test "an unknown provenance origin fails closed" do
    provenance = global_provenance([enter(), leave()], %{origin: :unknown_layer})

    assert resolve(provenance) == %{}
  end

  test "an unsupported global-class resolution source fails closed" do
    provenance = global_provenance([enter(), leave()], %{resolution_source: :conflicted})

    assert resolve(provenance) == %{}
  end

  test "an empty interaction record id fails closed" do
    invalid_id = Map.put(enter(), "id", "")

    assert resolve(global_provenance([invalid_id, leave()])) == %{}
  end

  test "a non-binary effective CSS value fails closed" do
    assert TransientStyleState.resolve_aliases(nil, global_provenance([enter(), leave()])) == %{}
  end

  defp resolve(provenance), do: TransientStyleState.resolve_aliases(@css, provenance)

  defp global_provenance(interactions, overrides \\ %{}) do
    %{
      origin: :global_class,
      class_id: "global-class-1",
      resolution_source: :local,
      authority_ids: [],
      class_reference_index: 0,
      source_id: "element-owner-1",
      layer_settings: %{"_interactions" => interactions}
    }
    |> Map.merge(overrides)
  end

  defp put_interactions(provenance, interactions) do
    put_in(provenance, [:layer_settings, "_interactions"], interactions)
  end

  defp enter(token \\ @token),
    do: record("mouseenter", "setAttribute", "class", token, "enter-id")

  defp leave(token \\ @token),
    do: record("mouseleave", "removeAttribute", "class", token, "leave-id")

  defp record(trigger, action, attribute_key, attribute_value, id \\ "record-id") do
    %{
      "action" => action,
      "actionAttributeKey" => attribute_key,
      "actionAttributeValue" => attribute_value,
      "id" => id,
      "trigger" => trigger
    }
  end
end
