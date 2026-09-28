defmodule LiveFrames.Catalogue.Registry.BuilderTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Catalogue.Manifest
  alias LiveFrames.Catalogue.Registry.Builder

  @logical_root "apps/live_frames/priv/catalogue"

  test "requires a binary physical root" do
    for source_root <- [nil, [], ~c"catalogue"] do
      assert {:error, [diagnostic]} = Builder.build(source_root)
      assert diagnostic.code == "catalogue.registry.builder.root_invalid"
      assert diagnostic.path == @logical_root
    end
  end

  test "a missing root produces an empty manifest set" do
    root = new_catalogue_root()

    refute File.exists?(root)
    assert {:ok, []} = Builder.build(root)
    refute File.exists?(root)
  end

  test "a regular file cannot be the root" do
    root = new_catalogue_root()
    File.write!(root, "not a directory")

    assert {:error, [diagnostic]} = Builder.build(root)
    assert diagnostic.code == "catalogue.registry.builder.root_invalid"
    assert diagnostic.path == @logical_root
  end

  test "a root symlink is rejected without following it" do
    root = new_catalogue_root()
    target = Path.join(Path.dirname(root), "real-catalogue")
    File.mkdir_p!(target)
    assert :ok = File.ln_s(target, root)

    assert {:error, [diagnostic]} = Builder.build(root)
    assert diagnostic.code == "catalogue.registry.builder.root_invalid"
    assert diagnostic.path == @logical_root
  end

  test "a recognized kind directory symlink is rejected" do
    root = new_catalogue_root()
    target = Path.join(Path.dirname(root), "real-sections")
    File.mkdir_p!(target)
    File.mkdir_p!(root)
    assert :ok = File.ln_s(target, Path.join(root, "sections"))

    assert {:error, [diagnostic]} = Builder.build(root)
    assert diagnostic.code == "catalogue.registry.builder.layout_invalid"
    assert diagnostic.path == "#{@logical_root}/sections"
    refute String.contains?(diagnostic.path, root)
  end

  test "rejects invalid root entries" do
    for invalid_entry <- [
          :unknown_directory,
          :root_json_file,
          :root_text_file,
          :hidden_entry,
          :root_symlink,
          :invalid_utf8_name
        ] do
      root = new_catalogue_root()
      add_invalid_root_entry(root, invalid_entry)

      assert {:error, [diagnostic]} = Builder.build(root)
      assert diagnostic.code == "catalogue.registry.builder.layout_invalid"
    end
  end

  test "reports the first root layout failure by binary path order" do
    root = new_catalogue_root()
    File.mkdir_p!(root)
    File.mkdir_p!(Path.join(root, "z_unknown"))
    File.mkdir_p!(Path.join(root, "a_unknown"))

    assert {:error, [diagnostic]} = Builder.build(root)
    assert diagnostic.code == "catalogue.registry.builder.layout_invalid"
    assert diagnostic.path == "#{@logical_root}/a_unknown"
  end

  test "rejects invalid direct children of recognized kind directories" do
    for invalid_entry <- [:nested_directory, :hidden_file, :non_json_file, :json_symlink] do
      root = new_catalogue_root()
      section_dir = Path.join(root, "sections")
      File.mkdir_p!(section_dir)
      add_invalid_kind_entry(root, section_dir, invalid_entry)

      assert {:error, [diagnostic]} = Builder.build(root)
      assert diagnostic.code == "catalogue.registry.builder.layout_invalid"
      assert String.starts_with?(diagnostic.path, "#{@logical_root}/sections/")
    end
  end

  test "rejects invalid UTF-8 names inside recognized kind directories" do
    root = new_catalogue_root()
    section_dir = Path.join(root, "sections")
    File.mkdir_p!(section_dir)
    File.write!(Path.join(section_dir, <<255>>), "invalid name")

    assert {:error, [diagnostic]} = Builder.build(root)
    assert diagnostic.code == "catalogue.registry.builder.layout_invalid"
    assert diagnostic.path == "#{@logical_root}/sections"
    refute String.contains?(diagnostic.path, root)
  end

  test "accepts an empty root and absent kind directories" do
    root = new_catalogue_root()
    File.mkdir_p!(root)

    assert {:ok, []} = Builder.build(root)
  end

  test "accepts a root with only empty recognized kind directories" do
    root = new_catalogue_root()

    for directory <- ~w(primitives components patterns sections pages templates) do
      File.mkdir_p!(Path.join(root, directory))
    end

    assert {:ok, []} = Builder.build(root)
  end

  test "decodes one valid manifest from an arbitrary physical root" do
    root = new_catalogue_root()
    write_manifest(root, "sections", "synthetic", valid_manifest())

    assert {:ok, manifests = [%Manifest{id: "live_frames.section.synthetic"}]} =
             Builder.build(root)

    refute String.contains?(inspect(manifests), root)
  end

  test "identity validation receives the fixed logical path instead of the physical path" do
    root = new_catalogue_root()
    source = write_manifest(root, "sections", "synthetic", valid_manifest())

    assert {:ok, [%Manifest{id: "live_frames.section.synthetic"}]} = Builder.build(root)

    wrong_name = Path.join(root, "sections/synthetic_wrong.json")
    File.rename!(source, wrong_name)

    assert {:error, [diagnostic]} = Builder.build(root)
    assert diagnostic.code == "catalogue.identity.path_mismatch"
    assert diagnostic.path == "path"
    assert String.contains?(diagnostic.message, "#{@logical_root}/sections/synthetic_wrong.json")
    refute String.contains?(diagnostic.message, root)
  end

  test "propagates Manifest invalid JSON diagnostics" do
    root = new_catalogue_root()
    write_manifest(root, "sections", "synthetic", "{invalid json")

    assert {:error, [diagnostic]} = Builder.build(root)
    assert diagnostic.code == "catalogue.manifest.invalid_json"
    assert diagnostic.path == "$"
  end

  test "reports unreadable manifests with their logical path" do
    root = new_catalogue_root()
    path = write_manifest(root, "sections", "synthetic", valid_manifest())
    assert :ok = File.chmod(path, 0)
    assert {:error, _reason} = File.read(path)

    assert {:error, [diagnostic]} = Builder.build(root)
    assert diagnostic.code == "catalogue.registry.builder.read_failed"
    assert diagnostic.path == "#{@logical_root}/sections/synthetic.json"
    refute String.contains?(diagnostic.path, root)
    refute String.contains?(diagnostic.message, root)
  end

  test "propagates Manifest schema diagnostics" do
    root = new_catalogue_root()
    write_manifest(root, "sections", "synthetic", %{"schema_version" => 1})

    assert {:error, [diagnostic]} = Builder.build(root)
    assert diagnostic.code == "catalogue.manifest.field_missing"
    assert diagnostic.path == "id"
  end

  test "propagates Identity diagnostics for manifest kind and path disagreement" do
    root = new_catalogue_root()

    manifest =
      valid_manifest(
        "live_frames.component.synthetic",
        "component"
      )

    write_manifest(root, "sections", "synthetic", manifest)

    assert {:error, [diagnostic]} = Builder.build(root)
    assert diagnostic.code == "catalogue.identity.path_mismatch"
    assert diagnostic.path == "path"
  end

  test "propagates Lifecycle snapshot diagnostics" do
    root = new_catalogue_root()

    manifest =
      valid_manifest(
        "live_frames.section.synthetic",
        "section",
        "DRAFT",
        transition("validate", "DRAFT", "VALIDATED")
      )

    write_manifest(root, "sections", "synthetic", manifest)

    assert {:error, [diagnostic]} = Builder.build(root)
    assert diagnostic.code == "catalogue.lifecycle.snapshot_state_mismatch"
    assert diagnostic.path == "state"
  end

  test "includes coherent snapshots for every lifecycle state" do
    root = new_catalogue_root()

    states = [
      {"draft", "DRAFT", transition("admit_to_catalogue", nil, "DRAFT")},
      {"validated", "VALIDATED", transition("validate", "DRAFT", "VALIDATED")},
      {"reviewed", "REVIEWED", transition("review", "VALIDATED", "REVIEWED")},
      {"approved", "APPROVED", transition("approve", "REVIEWED", "APPROVED")},
      {"released", "RELEASED", transition("release", "APPROVED", "RELEASED")},
      {"deprecated", "DEPRECATED", transition("deprecate", "RELEASED", "DEPRECATED")},
      {"retired", "RETIRED", transition("retire", "DEPRECATED", "RETIRED")},
      {"withdrawn", "WITHDRAWN", transition("withdraw", "DRAFT", "WITHDRAWN")}
    ]

    for {slug, state, last_transition} <- states do
      manifest = valid_manifest("live_frames.section.#{slug}", "section", state, last_transition)
      write_manifest(root, "sections", slug, manifest)
    end

    assert {:ok, manifests} = Builder.build(root)
    assert Enum.sort(Enum.map(manifests, & &1.state)) == Enum.sort(Enum.map(states, &elem(&1, 1)))
  end

  test "validates manifest failures in canonical logical path order" do
    root = new_catalogue_root()

    write_manifest(root, "sections", "z", %{"schema_version" => 1})
    write_manifest(root, "components", "a", "{invalid json")

    assert {:error, [diagnostic]} = Builder.build(root)
    assert diagnostic.code == "catalogue.manifest.invalid_json"
  end

  test "validates the complete filesystem layout before decoding manifests" do
    root = new_catalogue_root()
    write_manifest(root, "sections", "synthetic", "{invalid json")
    File.mkdir_p!(Path.join(root, "unknown"))

    assert {:error, [diagnostic]} = Builder.build(root)
    assert diagnostic.code == "catalogue.registry.builder.layout_invalid"
    assert diagnostic.path == "#{@logical_root}/unknown"
  end

  test "orders layout failures by logical path across root and kind entries" do
    root = new_catalogue_root()
    File.mkdir_p!(Path.join(root, "components"))
    File.write!(Path.join(root, "components/z.yaml"), "not a manifest")
    File.write!(Path.join(root, "components/a.yaml"), "not a manifest")
    File.mkdir_p!(Path.join(root, "z_unknown"))

    assert {:error, [diagnostic]} = Builder.build(root)
    assert diagnostic.code == "catalogue.registry.builder.layout_invalid"
    assert diagnostic.path == "#{@logical_root}/components/a.yaml"
    refute String.contains?(diagnostic.path, root)
  end

  test "keeps an earlier root layout failure ahead of kind entries" do
    root = new_catalogue_root()
    File.mkdir_p!(Path.join(root, "a_unknown"))
    File.mkdir_p!(Path.join(root, "templates"))
    File.write!(Path.join(root, "templates/z.yaml"), "not a manifest")

    assert {:error, [diagnostic]} = Builder.build(root)
    assert diagnostic.code == "catalogue.registry.builder.layout_invalid"
    assert diagnostic.path == "#{@logical_root}/a_unknown"
    refute String.contains?(diagnostic.path, root)
  end

  test "returns manifests sorted by ID regardless of file creation order" do
    root = new_catalogue_root()

    write_manifest(
      root,
      "templates",
      "zeta",
      valid_manifest("live_frames.template.zeta", "template")
    )

    write_manifest(
      root,
      "components",
      "alpha",
      valid_manifest("live_frames.component.alpha", "component")
    )

    write_manifest(
      root,
      "sections",
      "beta",
      valid_manifest("live_frames.section.beta", "section")
    )

    assert {:ok, manifests} = Builder.build(root)
    ids = Enum.map(manifests, & &1.id)
    assert ids == Enum.sort(ids)

    assert ids == [
             "live_frames.component.alpha",
             "live_frames.section.beta",
             "live_frames.template.zeta"
           ]

    assert Enum.all?(manifests, &is_struct(&1, Manifest))
  end

  test "a later build sees additions and removals without a cache" do
    root = new_catalogue_root()
    File.mkdir_p!(root)

    assert {:ok, []} = Builder.build(root)

    manifest_path = write_manifest(root, "sections", "synthetic", valid_manifest())
    assert {:ok, [%Manifest{id: "live_frames.section.synthetic"}]} = Builder.build(root)

    File.rm!(manifest_path)
    assert {:ok, []} = Builder.build(root)
    assert File.ls!(root) == ["sections"]
    assert File.ls!(Path.join(root, "sections")) == []
  end

  defp new_catalogue_root do
    base =
      Path.join(
        System.tmp_dir!(),
        "liveframes-builder-#{System.unique_integer([:positive, :monotonic])}"
      )

    root = Path.join(base, "catalogue")
    File.mkdir_p!(base)
    on_exit(fn -> File.rm_rf!(base) end)
    root
  end

  defp add_invalid_root_entry(root, :unknown_directory) do
    File.mkdir_p!(Path.join(root, "unknown"))
  end

  defp add_invalid_root_entry(root, :root_json_file) do
    File.mkdir_p!(root)
    File.write!(Path.join(root, "index.json"), "{invalid json")
  end

  defp add_invalid_root_entry(root, :root_text_file) do
    File.mkdir_p!(root)
    File.write!(Path.join(root, "notes.txt"), "not a manifest")
  end

  defp add_invalid_root_entry(root, :hidden_entry) do
    File.mkdir_p!(root)
    File.write!(Path.join(root, ".DS_Store"), "hidden")
  end

  defp add_invalid_root_entry(root, :root_symlink) do
    File.mkdir_p!(root)
    target = Path.join(Path.dirname(root), "sections-target")
    File.mkdir_p!(target)
    assert :ok = File.ln_s(target, Path.join(root, "sections-link"))
  end

  defp add_invalid_root_entry(root, :invalid_utf8_name) do
    File.mkdir_p!(root)
    File.write!(Path.join(root, <<255>>), "invalid name")
  end

  defp add_invalid_kind_entry(_root, section_dir, :nested_directory) do
    File.mkdir_p!(Path.join(section_dir, "nested"))
  end

  defp add_invalid_kind_entry(_root, section_dir, :hidden_file) do
    File.write!(Path.join(section_dir, ".hidden.json"), "{}")
  end

  defp add_invalid_kind_entry(_root, section_dir, :non_json_file) do
    File.write!(Path.join(section_dir, "manifest.yaml"), "not JSON")
  end

  defp add_invalid_kind_entry(root, section_dir, :json_symlink) do
    target = Path.join(Path.dirname(root), "manifest-target.json")
    File.write!(target, Jason.encode!(valid_manifest()))
    assert :ok = File.ln_s(target, Path.join(section_dir, "synthetic.json"))
  end

  defp write_manifest(root, directory, filename, content) do
    path = Path.join([root, directory, "#{filename}.json"])
    File.mkdir_p!(Path.dirname(path))
    encoded = if is_binary(content), do: content, else: Jason.encode!(content)
    File.write!(path, encoded)
    path
  end

  defp valid_manifest(
         id \\ "live_frames.section.synthetic",
         kind \\ "section",
         state \\ "DRAFT",
         last_transition \\ transition("admit_to_catalogue", nil, "DRAFT")
       ) do
    %{
      "schema_version" => 1,
      "id" => id,
      "kind" => kind,
      "display_name" => "Synthetic #{kind}",
      "state" => state,
      "component" => %{
        "module" => "LiveFrames.Components.Synthetic",
        "function" => "synthetic"
      },
      "storybook" => %{"module" => "LiveFrames.Stories.Synthetic"},
      "docs" => %{},
      "provenance" => %{},
      "lifecycle" => %{"last_transition" => last_transition}
    }
  end

  defp transition(action, from, to) do
    %{
      "action" => action,
      "from" => from,
      "to" => to,
      "evidence_refs" => ["synthetic:admission"]
    }
  end
end
