defmodule LiveFrames.Catalogue.IdentityTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Catalogue.Identity
  alias LiveFrames.Catalogue.Manifest

  @valid_cases [
    {"live_frames.primitive.icon", "primitive",
     "apps/live_frames/priv/catalogue/primitives/icon.json"},
    {"live_frames.component.avatar", "component",
     "apps/live_frames/priv/catalogue/components/avatar.json"},
    {"live_frames.pattern.command_palette", "pattern",
     "apps/live_frames/priv/catalogue/patterns/command_palette.json"},
    {"live_frames.section.hero", "section", "apps/live_frames/priv/catalogue/sections/hero.json"},
    {"live_frames.page.marketing_home", "page",
     "apps/live_frames/priv/catalogue/pages/marketing_home.json"},
    {"live_frames.template.saas_marketing", "template",
     "apps/live_frames/priv/catalogue/templates/saas_marketing.json"}
  ]

  @invalid_ids [
    "live_frames.sections.hero",
    "live_frames.section.Hero",
    "live_frames.section.hero-split",
    "live_frames.section.hero.split",
    "live_frames.section._hero",
    "live_frames.section.hero__split",
    "live_frames.hero",
    "other.section.hero",
    "Live_Frames.Section.Hero"
  ]

  @windows_reserved_keys ["con", "prn", "aux", "nul"] ++
                           for(n <- 1..9, prefix <- ["com", "lpt"], do: "#{prefix}#{n}")

  describe "valid v1 identities for all kinds" do
    for {id, kind, path} <- @valid_cases do
      test "accepts #{id}" do
        manifest = synthetic_manifest(unquote(id), unquote(kind))
        assert :ok = Identity.validate(manifest, unquote(path))
        assert {:ok, key} = Identity.slug(unquote(id))
        assert key == String.split(unquote(id), ".") |> List.last()
        assert {:ok, unquote(path)} = Identity.canonical_path(unquote(id), unquote(kind))
      end
    end
  end

  describe "invalid ID grammar" do
    for id <- @invalid_ids do
      test "rejects #{id}" do
        manifest = synthetic_manifest(unquote(id), segment_kind(unquote(id)))
        path = guessed_path(unquote(id))

        assert {:error, diagnostics} = Identity.validate(manifest, path)
        assert Enum.any?(diagnostics, &(&1.code in identity_failure_codes()))
      end
    end
  end

  describe "slug/1 derivation" do
    test "rejects invalid namespace" do
      assert {:error, diagnostics} = Identity.slug("other.section.hero")
      assert diagnostic(diagnostics, "catalogue.identity.id_invalid")
    end

    test "rejects invalid ID kind" do
      assert {:error, diagnostics} = Identity.slug("live_frames.sections.hero")
      assert diagnostic(diagnostics, "catalogue.identity.kind_invalid")
    end
  end

  describe "canonical_path/2 derivation" do
    test "rejects invalid namespace" do
      assert {:error, diagnostics} = Identity.canonical_path("other.section.hero", "section")
      assert diagnostic(diagnostics, "catalogue.identity.id_invalid")
    end

    test "rejects invalid ID kind" do
      assert {:error, diagnostics} =
               Identity.canonical_path("live_frames.sections.hero", "section")

      assert diagnostic(diagnostics, "catalogue.identity.kind_invalid")
    end

    test "rejects ID kind vs supplied kind mismatch" do
      assert {:error, diagnostics} =
               Identity.canonical_path("live_frames.page.hero", "section")

      assert diagnostic(diagnostics, "catalogue.identity.kind_mismatch")
    end
  end

  test "rejects manifest kind mismatch when ID grammar is otherwise valid" do
    manifest = synthetic_manifest("live_frames.section.hero", "page")
    path = "apps/live_frames/priv/catalogue/sections/hero.json"

    assert {:error, diagnostics} = Identity.validate(manifest, path)
    assert diagnostic(diagnostics, "catalogue.identity.kind_mismatch")
  end

  test "rejects incorrect plural directory in supplied path" do
    manifest = synthetic_manifest("live_frames.section.hero", "section")
    path = "apps/live_frames/priv/catalogue/section/hero.json"

    assert {:error, diagnostics} = Identity.validate(manifest, path)
    assert diagnostic(diagnostics, "catalogue.identity.path_mismatch")
  end

  test "rejects incorrect basename in supplied path" do
    manifest = synthetic_manifest("live_frames.section.hero", "section")
    path = "apps/live_frames/priv/catalogue/sections/hero_v2.json"

    assert {:error, diagnostics} = Identity.validate(manifest, path)
    assert diagnostic(diagnostics, "catalogue.identity.path_mismatch")
  end

  test "rejects incorrect extension in supplied path" do
    manifest = synthetic_manifest("live_frames.section.hero", "section")
    path = "apps/live_frames/priv/catalogue/sections/hero.yaml"

    assert {:error, diagnostics} = Identity.validate(manifest, path)
    assert diagnostic(diagnostics, "catalogue.identity.path_mismatch")
  end

  test "rejects otherwise valid path in the wrong kind directory" do
    manifest = synthetic_manifest("live_frames.section.hero", "section")
    path = "apps/live_frames/priv/catalogue/pages/hero.json"

    assert {:error, diagnostics} = Identity.validate(manifest, path)
    assert diagnostic(diagnostics, "catalogue.identity.path_mismatch")
  end

  describe "Windows-reserved derived slugs" do
    for key <- @windows_reserved_keys do
      @tag key: key
      test "rejects reserved key #{key}" do
        key = unquote(key)
        id = "live_frames.section.#{key}"
        manifest = synthetic_manifest(id, "section")
        path = "apps/live_frames/priv/catalogue/sections/#{key}.json"

        assert {:error, diagnostics} = Identity.validate(manifest, path)
        assert diagnostic(diagnostics, "catalogue.identity.slug_reserved")

        assert {:error, slug_diagnostics} = Identity.slug(id)
        assert diagnostic(slug_diagnostics, "catalogue.identity.slug_reserved")
      end
    end
  end

  describe "validate_collection/1" do
    test "detects duplicate IDs" do
      first = entry("live_frames.section.hero", "section", "WITHDRAWN")
      second = entry("live_frames.section.hero", "section", "DRAFT")

      assert {:error, diagnostics} = Identity.validate_collection([first, second])
      assert diagnostic(diagnostics, "catalogue.identity.id_duplicate")
    end

    test "detects duplicate canonical paths" do
      shared_path = "apps/live_frames/priv/catalogue/sections/hero.json"

      first = {synthetic_manifest("live_frames.section.hero", "section"), shared_path}

      second =
        {synthetic_manifest("live_frames.section.hero_alt", "section"), shared_path}

      assert {:error, diagnostics} = Identity.validate_collection([first, second])
      assert diagnostic(diagnostics, "catalogue.identity.path_duplicate")
    end

    test "rejects duplicate ID when the first manifest is WITHDRAWN" do
      first = entry("live_frames.component.avatar", "component", "WITHDRAWN")
      second = entry("live_frames.component.avatar", "component", "DRAFT")

      assert {:error, diagnostics} = Identity.validate_collection([first, second])
      assert diagnostic(diagnostics, "catalogue.identity.id_duplicate")
    end

    test "rejects duplicate ID when the first manifest is RETIRED" do
      first = entry("live_frames.component.avatar", "component", "RETIRED")
      second = entry("live_frames.component.avatar", "component", "DRAFT")

      assert {:error, diagnostics} = Identity.validate_collection([first, second])
      assert diagnostic(diagnostics, "catalogue.identity.id_duplicate")
    end

    test "collection order does not change duplicate detection" do
      a = entry("live_frames.page.marketing_home", "page", "DRAFT")
      b = entry("live_frames.page.marketing_home", "page", "WITHDRAWN")

      forward = Identity.validate_collection([a, b])
      reverse = Identity.validate_collection([b, a])

      assert forward == reverse
      assert match?({:error, _}, forward)
    end

    test "accepts a collection with distinct valid entries" do
      entries =
        Enum.map(@valid_cases, fn {id, kind, path} ->
          {synthetic_manifest(id, kind), path}
        end)

      assert :ok = Identity.validate_collection(entries)
    end
  end

  test "Manifest struct does not define a slug field" do
    manifest = synthetic_manifest("live_frames.section.hero", "section")
    refute Map.has_key?(Map.from_struct(manifest), :slug)
  end

  defp synthetic_manifest(id, kind, state \\ "DRAFT") do
    %Manifest{
      schema_version: 1,
      id: id,
      kind: kind,
      display_name: "Synthetic",
      state: state,
      component: %{"module" => "LiveFrames.Components.Synthetic", "function" => "synthetic"},
      storybook: %{"module" => "LiveFrames.Stories.Synthetic"},
      docs: %{},
      provenance: %{}
    }
  end

  defp entry(id, kind, state) do
    path =
      case Identity.canonical_path(id, kind) do
        {:ok, canonical} -> canonical
        _ -> "apps/live_frames/priv/catalogue/invalid.json"
      end

    {synthetic_manifest(id, kind, state), path}
  end

  defp segment_kind(id) do
    case String.split(id, ".") do
      [_namespace, kind, _key] -> kind
      _ -> "section"
    end
  end

  defp guessed_path(id) do
    case String.split(id, ".") do
      [_namespace, kind, key] ->
        dir =
          %{
            "primitive" => "primitives",
            "component" => "components",
            "pattern" => "patterns",
            "section" => "sections",
            "sections" => "sections",
            "page" => "pages",
            "template" => "templates",
            "Section" => "sections",
            "Hero" => "sections"
          }
          |> Map.get(kind, "sections")

        "apps/live_frames/priv/catalogue/#{dir}/#{String.downcase(key)}.json"

      _ ->
        "apps/live_frames/priv/catalogue/sections/hero.json"
    end
  end

  defp diagnostic(diagnostics, code) do
    assert Enum.any?(diagnostics, &(&1.code == code))
  end

  defp identity_failure_codes do
    [
      "catalogue.identity.id_invalid",
      "catalogue.identity.kind_invalid",
      "catalogue.identity.kind_mismatch",
      "catalogue.identity.slug_reserved",
      "catalogue.identity.path_mismatch"
    ]
  end
end
