defmodule LiveFrames.Catalogue.StorybookReferenceTest do
  use ExUnit.Case, async: false

  alias LiveFrames.Catalogue.Manifest
  alias LiveFrames.Catalogue.StorybookReference

  defmodule ResolvedStory do
  end

  @base_manifest %{
    "schema_version" => 1,
    "id" => "live_frames.component.synthetic",
    "kind" => "component",
    "display_name" => "Synthetic component",
    "state" => "DRAFT",
    "component" => %{
      "module" => "LiveFrames.Components.Synthetic",
      "function" => "synthetic"
    },
    "storybook" => %{},
    "docs" => %{},
    "provenance" => %{}
  }

  test "accepts a decoded Storybook reference for the supplied module" do
    manifest =
      decode_storybook(%{
        "module" => "LiveFrames.Catalogue.StorybookReferenceTest.ResolvedStory",
        "variation_ids" => ["informative_media", "minimal"]
      })

    assert manifest.storybook["module"] ==
             "LiveFrames.Catalogue.StorybookReferenceTest.ResolvedStory"

    assert StorybookReference.validate(manifest, ResolvedStory) == :ok
  end

  test "accepts a Storybook reference without variation IDs" do
    manifest = decode_storybook(%{"module" => module_name(ResolvedStory)})

    assert StorybookReference.validate(manifest, ResolvedStory) == :ok
  end

  test "accepts variation IDs without requiring default or sorted input" do
    first =
      decode_storybook(%{
        "module" => module_name(ResolvedStory),
        "variation_ids" => ["minimal", "informative_media"]
      })

    second =
      decode_storybook(%{
        "module" => module_name(ResolvedStory),
        "variation_ids" => ["informative_media", "minimal"]
      })

    only_additional =
      decode_storybook(%{
        "module" => module_name(ResolvedStory),
        "variation_ids" => ["minimal"]
      })

    assert StorybookReference.validate(first, ResolvedStory) == :ok
    assert StorybookReference.validate(second, ResolvedStory) == :ok
    assert StorybookReference.validate(only_additional, ResolvedStory) == :ok
  end

  test "rejects values that are not decoded manifests" do
    assert_diagnostic(
      StorybookReference.validate(%{}, ResolvedStory),
      "catalogue.storybook_reference.manifest_invalid",
      "$"
    )
  end

  test "rejects a malformed Storybook object in a manually built manifest" do
    manifest = %Manifest{storybook: []}

    assert_diagnostic(
      StorybookReference.validate(manifest, ResolvedStory),
      "catalogue.storybook_reference.storybook_invalid",
      "storybook"
    )
  end

  test "rejects missing, non-string, and invalid UTF-8 module references" do
    for storybook <- [
          %{},
          %{"module" => 7},
          %{"module" => <<255>>}
        ] do
      manifest = %Manifest{storybook: storybook}

      assert_diagnostic(
        StorybookReference.validate(manifest, ResolvedStory),
        "catalogue.storybook_reference.module_invalid",
        "storybook.module"
      )
    end
  end

  test "an empty module string reaches exact target agreement" do
    manifest = decode_storybook(%{"module" => ""})

    assert_diagnostic(
      StorybookReference.validate(manifest, ResolvedStory),
      "catalogue.storybook_reference.module_mismatch",
      "storybook.module"
    )
  end

  test "rejects a non-atom resolved module without converting it" do
    manifest = decode_storybook(%{"module" => module_name(ResolvedStory)})

    assert_diagnostic(
      StorybookReference.validate(manifest, module_name(ResolvedStory)),
      "catalogue.storybook_reference.resolved_module_invalid",
      "storybook.module"
    )
  end

  test "rejects a module reference that does not exactly match the target" do
    manifest = decode_storybook(%{"module" => module_name(OtherStory)})

    assert_diagnostic(
      StorybookReference.validate(manifest, ResolvedStory),
      "catalogue.storybook_reference.module_mismatch",
      "storybook.module"
    )
  end

  test "does not trim the module reference before comparison" do
    manifest = decode_storybook(%{"module" => " #{module_name(ResolvedStory)} "})

    assert_diagnostic(
      StorybookReference.validate(manifest, ResolvedStory),
      "catalogue.storybook_reference.module_mismatch",
      "storybook.module"
    )
  end

  test "does not check whether the supplied module exists" do
    target = :"Elixir.LiveFrames.Catalogue.StorybookReferenceTest.IntentionallyUndefinedStory"
    refute Code.ensure_loaded?(target)

    manifest = decode_storybook(%{"module" => module_name(target)})

    assert StorybookReference.validate(manifest, target) == :ok
  end

  test "rejects variation IDs containers that are not proper lists" do
    for variation_ids <- [nil, "minimal", 7, false, %{}] do
      manifest =
        decode_storybook(%{
          "module" => module_name(ResolvedStory),
          "variation_ids" => variation_ids
        })

      assert_diagnostic(
        StorybookReference.validate(manifest, ResolvedStory),
        "catalogue.storybook_reference.variation_ids_invalid",
        "storybook.variation_ids"
      )
    end

    improper_list = ["minimal" | :improper_tail]

    manifest = %Manifest{
      storybook: %{
        "module" => module_name(ResolvedStory),
        "variation_ids" => improper_list
      }
    }

    assert_diagnostic(
      StorybookReference.validate(manifest, ResolvedStory),
      "catalogue.storybook_reference.variation_ids_invalid",
      "storybook.variation_ids"
    )
  end

  test "rejects invalid variation members at their source index" do
    for variation_id <- ["", 7, nil, false, %{}, []] do
      manifest =
        decode_storybook(%{
          "module" => module_name(ResolvedStory),
          "variation_ids" => [variation_id]
        })

      assert_diagnostic(
        StorybookReference.validate(manifest, ResolvedStory),
        "catalogue.storybook_reference.variation_id_invalid",
        "storybook.variation_ids[0]"
      )
    end

    manifest = %Manifest{
      storybook: %{
        "module" => module_name(ResolvedStory),
        "variation_ids" => [<<255>>]
      }
    }

    assert_diagnostic(
      StorybookReference.validate(manifest, ResolvedStory),
      "catalogue.storybook_reference.variation_id_invalid",
      "storybook.variation_ids[0]"
    )
  end

  test "reports the first invalid variation member in source order" do
    manifest =
      decode_storybook(%{
        "module" => module_name(ResolvedStory),
        "variation_ids" => ["minimal", 7, false]
      })

    assert_diagnostic(
      StorybookReference.validate(manifest, ResolvedStory),
      "catalogue.storybook_reference.variation_id_invalid",
      "storybook.variation_ids[1]"
    )
  end

  test "rejects exact duplicate variation IDs" do
    manifest =
      decode_storybook(%{
        "module" => module_name(ResolvedStory),
        "variation_ids" => ["minimal", "minimal"]
      })

    assert_diagnostic(
      StorybookReference.validate(manifest, ResolvedStory),
      "catalogue.storybook_reference.variation_id_duplicate",
      "storybook.variation_ids"
    )
  end

  test "keeps case-sensitive variation IDs distinct" do
    manifest =
      decode_storybook(%{
        "module" => module_name(ResolvedStory),
        "variation_ids" => ["minimal", "Minimal"]
      })

    assert StorybookReference.validate(manifest, ResolvedStory) == :ok
  end

  test "does not create atoms from module references" do
    marker = "untrusted_storybook_module_#{System.unique_integer([:positive, :monotonic])}"

    assert_raise ArgumentError, fn ->
      String.to_existing_atom(marker)
    end

    manifest = decode_storybook(%{"module" => marker})

    assert_diagnostic(
      StorybookReference.validate(manifest, ResolvedStory),
      "catalogue.storybook_reference.module_mismatch",
      "storybook.module"
    )

    assert_raise ArgumentError, fn ->
      String.to_existing_atom(marker)
    end
  end

  test "does not create atoms from variation IDs" do
    marker = "untrusted_variation_id_#{System.unique_integer([:positive, :monotonic])}"

    assert_raise ArgumentError, fn ->
      String.to_existing_atom(marker)
    end

    manifest =
      decode_storybook(%{
        "module" => module_name(ResolvedStory),
        "variation_ids" => [marker]
      })

    assert StorybookReference.validate(manifest, ResolvedStory) == :ok

    assert_raise ArgumentError, fn ->
      String.to_existing_atom(marker)
    end
  end

  defmodule OtherStory do
  end

  defp decode_storybook(storybook) do
    json = @base_manifest |> Map.put("storybook", storybook) |> Jason.encode!()
    assert {:ok, manifest} = Manifest.decode(json)
    manifest
  end

  defp module_name(module) do
    module
    |> Atom.to_string()
    |> String.replace_prefix("Elixir.", "")
  end

  defp assert_diagnostic({:error, [%{code: code, path: path, message: message}]}, code, path) do
    assert is_binary(message)
  end
end
