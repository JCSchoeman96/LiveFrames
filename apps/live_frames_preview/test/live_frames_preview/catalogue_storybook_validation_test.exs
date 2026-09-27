defmodule LiveFramesPreview.CatalogueStorybookValidationTest.FixtureComponent do
  def render(assigns), do: assigns
end

defmodule LiveFramesPreview.CatalogueStorybookValidationTest.OtherFixtureComponent do
  def render(assigns), do: assigns
end

defmodule LiveFramesPreview.CatalogueStorybookValidationTest.ValidStory do
  alias PhoenixStorybook.Stories.Variation

  def function,
    do: &LiveFramesPreview.CatalogueStorybookValidationTest.FixtureComponent.render/1

  def variations do
    [%Variation{id: :minimal}, %Variation{id: :default}]
  end
end

defmodule LiveFramesPreview.CatalogueStorybookValidationTest.WrongTargetStory do
  alias PhoenixStorybook.Stories.Variation

  def function,
    do: &LiveFramesPreview.CatalogueStorybookValidationTest.OtherFixtureComponent.render/1

  def variations, do: [%Variation{id: :default}]
end

defmodule LiveFramesPreview.CatalogueStorybookValidationTest.MissingDefaultStory do
  alias PhoenixStorybook.Stories.Variation

  def function,
    do: &LiveFramesPreview.CatalogueStorybookValidationTest.FixtureComponent.render/1

  def variations, do: [%Variation{id: :minimal}]
end

defmodule LiveFramesPreview.CatalogueStorybookValidationTest.MissingFunctionStory do
  alias PhoenixStorybook.Stories.Variation

  def variations, do: [%Variation{id: :default}]
end

defmodule LiveFramesPreview.CatalogueStorybookValidationTest.MissingVariationsStory do
  def function,
    do: &LiveFramesPreview.CatalogueStorybookValidationTest.FixtureComponent.render/1
end

defmodule LiveFramesPreview.CatalogueStorybookValidationTest.MalformedVariationStory do
  alias PhoenixStorybook.Stories.Variation

  def function,
    do: &LiveFramesPreview.CatalogueStorybookValidationTest.FixtureComponent.render/1

  def variations, do: [%Variation{id: "default"}]
end

defmodule LiveFramesPreview.CatalogueStorybookValidationTest.DuplicateVariationStory do
  alias PhoenixStorybook.Stories.Variation

  def function,
    do: &LiveFramesPreview.CatalogueStorybookValidationTest.FixtureComponent.render/1

  def variations, do: [%Variation{id: :default}, %Variation{id: :default}]
end

defmodule LiveFramesPreview.CatalogueStorybookValidationTest do
  use LiveFramesPreviewWeb.ConnCase

  alias LiveFrames.Catalogue.{Manifest, StorybookReference}
  alias PhoenixStorybook.Stories.Variation

  alias LiveFramesPreview.CatalogueStorybookValidationTest.{
    DuplicateVariationStory,
    FixtureComponent,
    MalformedVariationStory,
    MissingDefaultStory,
    MissingFunctionStory,
    MissingVariationsStory,
    OtherFixtureComponent,
    ValidStory,
    WrongTargetStory
  }

  @missing_story_module LiveFramesPreview.CatalogueStorybookValidationTest.MissingStory
  @hero_story_module LiveFramesPreviewWeb.Storybook.Components.Hero
  @hero_story_path Path.expand("../../storybook/components/hero.story.exs", __DIR__)

  test "a valid fixture story verifies its target and explicitly referenced variation" do
    manifest = decoded_manifest(ValidStory, FixtureComponent, :render, ["minimal"])

    assert verify_storybook_evidence(manifest, ValidStory, FixtureComponent, :render) == :ok
  end

  test "StorybookReference validation runs before module availability" do
    manifest = decoded_manifest(@missing_story_module, FixtureComponent, :render)

    assert :ok = StorybookReference.validate(manifest, @missing_story_module)
    refute Code.ensure_loaded?(@missing_story_module)

    assert {:error, :story_module_unavailable} =
             verify_storybook_evidence(
               manifest,
               @missing_story_module,
               FixtureComponent,
               :render
             )

    mismatched_reference = %{
      manifest
      | storybook: %{"module" => "LiveFramesPreviewWeb.Storybook.Components.Other"}
    }

    assert {:error,
            {:storybook_reference, [%{code: "catalogue.storybook_reference.module_mismatch"}]}} =
             verify_storybook_evidence(
               mismatched_reference,
               @missing_story_module,
               FixtureComponent,
               :render
             )
  end

  test "both required Storybook functions must exist before either is invoked" do
    manifest_without_function = decoded_manifest(MissingFunctionStory, FixtureComponent, :render)

    assert {:error, :missing_story_function} =
             verify_storybook_evidence(
               manifest_without_function,
               MissingFunctionStory,
               FixtureComponent,
               :render
             )

    manifest_without_variations =
      decoded_manifest(MissingVariationsStory, FixtureComponent, :render)

    assert {:error, :missing_story_variations} =
             verify_storybook_evidence(
               manifest_without_variations,
               MissingVariationsStory,
               FixtureComponent,
               :render
             )
  end

  test "a story targeting a different production export is rejected" do
    manifest = decoded_manifest(WrongTargetStory, FixtureComponent, :render)
    actual_target = WrongTargetStory.function()

    assert {:error, :story_target_mismatch} =
             verify_storybook_evidence(manifest, WrongTargetStory, FixtureComponent, :render)

    assert Function.info(actual_target, :module) == {:module, OtherFixtureComponent}
    assert Function.info(actual_target, :name) == {:name, :render}
    assert Function.info(actual_target, :arity) == {:arity, 1}
  end

  test "a story without the exact default variation is rejected" do
    manifest = decoded_manifest(MissingDefaultStory, FixtureComponent, :render)

    assert {:error, :default_variation_missing} =
             verify_storybook_evidence(
               manifest,
               MissingDefaultStory,
               FixtureComponent,
               :render
             )
  end

  test "an explicitly referenced variation must exist in the trusted story" do
    manifest =
      decoded_manifest(ValidStory, FixtureComponent, :render, ["minimal", "does_not_exist"])

    assert :ok = StorybookReference.validate(manifest, ValidStory)

    assert {:error, {:unknown_variation_ids, ["does_not_exist"]}} =
             verify_storybook_evidence(manifest, ValidStory, FixtureComponent, :render)
  end

  test "a trusted variation with a non-atom ID is rejected" do
    manifest = decoded_manifest(MalformedVariationStory, FixtureComponent, :render)

    assert {:error, :malformed_story_variations} =
             verify_storybook_evidence(
               manifest,
               MalformedVariationStory,
               FixtureComponent,
               :render
             )
  end

  test "duplicate trusted variation IDs are rejected" do
    manifest = decoded_manifest(DuplicateVariationStory, FixtureComponent, :render)

    assert {:error, :duplicate_story_variation_ids} =
             verify_storybook_evidence(
               manifest,
               DuplicateVariationStory,
               FixtureComponent,
               :render
             )
  end

  test "the accepted Hero story verifies from an in-memory DRAFT manifest" do
    story = hero_story_module()

    manifest =
      decoded_manifest(story, LiveFrames.Components.Sections.Hero, :hero, [
        "informative_media",
        "minimal"
      ])

    assert manifest.state == "DRAFT"
    assert manifest.id == "live_frames.component.storybook_evidence_test"

    assert manifest.component == %{
             "module" => "LiveFrames.Components.Sections.Hero",
             "function" => "hero"
           }

    assert MapSet.new(Enum.map(story.variations(), & &1.id)) ==
             MapSet.new([:default, :informative_media, :no_media, :minimal])

    assert :ok = StorybookReference.validate(manifest, story)

    assert verify_storybook_evidence(
             manifest,
             story,
             LiveFrames.Components.Sections.Hero,
             :hero
           ) == :ok
  end

  test "the mounted PhoenixStorybook route renders the accepted Hero default", %{conn: conn} do
    _story = hero_story_module()

    # The route is local render-test mechanics and is not stored in the manifest.
    conn = get(conn, "/storybook/components/hero")

    assert conn.status == 200
    assert conn.resp_body =~ "Build faster with native LiveFrames"
    assert conn.resp_body =~ "lf-hero"
  end

  defp verify_storybook_evidence(
         manifest,
         story_module,
         component_module,
         component_function
       ) do
    case StorybookReference.validate(manifest, story_module) do
      :ok ->
        verify_resolved_story(manifest, story_module, component_module, component_function)

      {:error, diagnostics} ->
        {:error, {:storybook_reference, diagnostics}}
    end
  end

  defp verify_resolved_story(manifest, story_module, component_module, component_function) do
    with :ok <- ensure_story_module(story_module),
         :ok <- ensure_story_api(story_module),
         :ok <- verify_story_target(story_module, component_module, component_function),
         {:ok, variation_ids} <- trusted_variation_ids(apply(story_module, :variations, [])),
         :ok <- require_default_variation(variation_ids),
         :ok <- verify_referenced_variations(manifest, variation_ids) do
      :ok
    end
  end

  defp ensure_story_module(story_module) do
    if Code.ensure_loaded?(story_module), do: :ok, else: {:error, :story_module_unavailable}
  end

  defp ensure_story_api(story_module) do
    cond do
      not function_exported?(story_module, :function, 0) ->
        {:error, :missing_story_function}

      not function_exported?(story_module, :variations, 0) ->
        {:error, :missing_story_variations}

      true ->
        :ok
    end
  end

  defp verify_story_target(story_module, component_module, component_function) do
    target = apply(story_module, :function, [])

    if exact_function_target?(target, component_module, component_function) do
      :ok
    else
      {:error, :story_target_mismatch}
    end
  end

  defp exact_function_target?(target, component_module, component_function)
       when is_function(target) do
    metadata = Function.info(target)

    Keyword.get(metadata, :module) == component_module and
      Keyword.get(metadata, :name) == component_function and
      Keyword.get(metadata, :arity) == 1
  end

  defp exact_function_target?(_target, _component_module, _component_function), do: false

  defp trusted_variation_ids(variations) when is_list(variations) do
    case Enum.reduce_while(variations, [], fn
           %Variation{id: id}, ids when is_atom(id) ->
             {:cont, [Atom.to_string(id) | ids]}

           _variation, _ids ->
             {:halt, :malformed}
         end) do
      :malformed ->
        {:error, :malformed_story_variations}

      reversed_ids ->
        ids = Enum.reverse(reversed_ids)

        if length(ids) == length(Enum.uniq(ids)) do
          {:ok, ids}
        else
          {:error, :duplicate_story_variation_ids}
        end
    end
  end

  defp trusted_variation_ids(_variations), do: {:error, :malformed_story_variations}

  defp require_default_variation(variation_ids) do
    if "default" in variation_ids do
      :ok
    else
      {:error, :default_variation_missing}
    end
  end

  defp verify_referenced_variations(manifest, variation_ids) do
    referenced_ids = Map.get(manifest.storybook, "variation_ids", [])
    unknown_ids = Enum.reject(referenced_ids, &(&1 in variation_ids))

    if unknown_ids == [], do: :ok, else: {:error, {:unknown_variation_ids, unknown_ids}}
  end

  defp decoded_manifest(
         story_module,
         component_module,
         component_function,
         variation_ids \\ :absent
       ) do
    storybook = %{"module" => module_name(story_module)}

    storybook =
      if variation_ids == :absent,
        do: storybook,
        else: Map.put(storybook, "variation_ids", variation_ids)

    json =
      Jason.encode!(%{
        "schema_version" => 1,
        "id" => "live_frames.component.storybook_evidence_test",
        "kind" => "component",
        "display_name" => "Storybook evidence test",
        "state" => "DRAFT",
        "component" => %{
          "module" => module_name(component_module),
          "function" => Atom.to_string(component_function)
        },
        "storybook" => storybook,
        "docs" => %{},
        "provenance" => %{}
      })

    assert {:ok, manifest} = Manifest.decode(json)
    manifest
  end

  defp module_name(module) do
    module
    |> Atom.to_string()
    |> String.replace_prefix("Elixir.", "")
  end

  defp hero_story_module do
    unless Code.ensure_loaded?(@hero_story_module) do
      Code.compile_file(@hero_story_path)
    end

    @hero_story_module
  end
end
