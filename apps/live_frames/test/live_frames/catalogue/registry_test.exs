defmodule LiveFrames.Catalogue.RegistryTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Catalogue.Manifest
  alias LiveFrames.Catalogue.Registry
  alias LiveFrames.Catalogue.Registry.Compilation

  @logical_root "apps/live_frames/priv/catalogue"
  @kind_directories %{
    "primitive" => "primitives",
    "component" => "components",
    "pattern" => "patterns",
    "section" => "sections",
    "page" => "pages",
    "template" => "templates"
  }

  test "the production Registry compiles the absent canonical root as empty" do
    app_root = Path.expand("../../../", __DIR__)
    source_root = Path.join(app_root, "priv/catalogue")

    assert {:error, :enoent} = File.lstat(source_root)
    assert Registry.all() == []
    assert Registry.fetch("live_frames.section.hero") == :error
    assert Registry.fetch(nil) == :error
    refute Registry.__mix_recompile__?()

    assert Registry.__info__(:functions) ==
             Enum.sort([{:all, 0}, {:fetch, 1}, {:__mix_recompile__?, 0}])
  end

  test "membership signature records root existence and type transitions" do
    root = new_catalogue_root()
    missing = Compilation.membership_signature(root)

    File.mkdir!(root)
    directory = Compilation.membership_signature(root)
    File.rmdir!(root)
    missing_again = Compilation.membership_signature(root)

    File.write!(root, "not a directory")
    regular_file = Compilation.membership_signature(root)
    File.rm!(root)

    target = Path.join(Path.dirname(root), "catalogue-target")
    File.mkdir!(target)
    assert :ok = File.ln_s(target, root)
    symlink = Compilation.membership_signature(root)

    refute missing == directory
    refute directory == missing_again
    refute missing_again == regular_file
    refute directory == regular_file
    refute regular_file == symlink
    refute directory == symlink
  end

  test "membership signature tracks directory and entry changes but ignores contents" do
    root = new_catalogue_root()
    File.mkdir!(root)
    empty_root = Compilation.membership_signature(root)

    kind_directory = Path.join(root, "sections")
    File.mkdir!(kind_directory)
    kind_added = Compilation.membership_signature(root)

    first_path = Path.join(kind_directory, "first.json")
    File.write!(first_path, "{invalid json")
    first_added = Compilation.membership_signature(root)
    File.write!(first_path, "different invalid JSON content")
    content_changed = Compilation.membership_signature(root)

    renamed_path = Path.join(kind_directory, "renamed.json")
    File.rename!(first_path, renamed_path)
    renamed = Compilation.membership_signature(root)

    File.rm!(renamed_path)
    manifest_removed = Compilation.membership_signature(root)
    File.rmdir!(kind_directory)
    kind_removed = Compilation.membership_signature(root)

    File.write!(Path.join(root, "unknown"), "invalid root entry")
    invalid_root_entry_added = Compilation.membership_signature(root)

    refute empty_root == kind_added
    refute kind_added == first_added
    assert first_added == content_changed
    refute content_changed == renamed
    refute renamed == manifest_removed
    refute manifest_removed == kind_removed
    refute kind_removed == invalid_root_entry_added
  end

  test "membership signature sees direct-child type changes without following symlinks" do
    root = new_catalogue_root()
    section_directory = Path.join(root, "sections")
    File.mkdir_p!(section_directory)

    manifest_path = Path.join(section_directory, "synthetic.json")
    File.write!(manifest_path, "{}")
    regular_file = Compilation.membership_signature(root)

    target = Path.join(Path.dirname(root), "synthetic-target.json")
    File.write!(target, "{}")
    File.rm!(manifest_path)
    assert :ok = File.ln_s(target, manifest_path)
    symlink = Compilation.membership_signature(root)

    File.rm!(manifest_path)
    File.mkdir!(manifest_path)
    directory = Compilation.membership_signature(root)

    refute regular_file == symlink
    refute symlink == directory
  end

  test "membership signature retains raw invalid UTF-8 entry names" do
    root = new_catalogue_root()
    File.mkdir!(root)
    before = Compilation.membership_signature(root)

    invalid_name_path = Path.join(root, <<255>>)
    File.write!(invalid_name_path, "invalid UTF-8 filename")

    assert {:ok, [<<255>>]} = :file.list_dir_all(root)
    after_addition = Compilation.membership_signature(root)
    refute before == after_addition
  end

  test "membership signature does not inspect entries through a root symlink" do
    root = new_catalogue_root()
    target = Path.join(Path.dirname(root), "catalogue-target")
    File.mkdir!(target)
    assert :ok = File.ln_s(target, root)

    before = Compilation.membership_signature(root)
    File.mkdir!(Path.join(target, "sections"))
    File.write!(Path.join(target, "sections/synthetic.json"), "{invalid JSON")

    assert Compilation.membership_signature(root) == before
  end

  test "prepare returns an empty result for a missing root without creating it" do
    root = new_catalogue_root()

    refute File.exists?(root)

    assert %{manifests: [], external_resources: [], membership_signature: signature} =
             Compilation.prepare!(root)

    assert signature == Compilation.membership_signature(root)
    refute File.exists?(root)
  end

  test "prepare registers validated manifest paths from Identity authority" do
    root = new_catalogue_root()
    manifest_path = write_manifest(root, "live_frames.section.synthetic", "section")

    assert %{
             manifests: [%Manifest{id: "live_frames.section.synthetic"}],
             external_resources: [^manifest_path]
           } = Compilation.prepare!(root)
  end

  test "prepare raises a deterministic CompileError with Builder diagnostics" do
    root = new_catalogue_root()
    File.mkdir_p!(Path.join(root, "unknown"))

    first_error = assert_raise CompileError, fn -> Compilation.prepare!(root) end
    second_error = assert_raise CompileError, fn -> Compilation.prepare!(root) end

    assert first_error.description == second_error.description
    assert first_error.description =~ "catalogue.registry.builder.layout_invalid"
    assert first_error.description =~ "#{@logical_root}/unknown"
    refute first_error.description =~ root
  end

  test "compiled Registry data survives removal of every source file" do
    root = new_catalogue_root()
    manifest_path = write_manifest(root, "live_frames.section.synthetic", "section")
    {registry_module, _prepared} = compile_registry(root)

    assert {:ok, %Manifest{id: "live_frames.section.synthetic"}} =
             registry_module.fetch("live_frames.section.synthetic")

    File.rm_rf!(Path.dirname(root))

    assert [%Manifest{id: "live_frames.section.synthetic"}] = registry_module.all()
    assert {:ok, %Manifest{}} = registry_module.fetch("live_frames.section.synthetic")
    assert registry_module.__mix_recompile__?()
    refute File.exists?(manifest_path)
  end

  test "a fresh compile sees content edits while an earlier Registry keeps its snapshot" do
    root = new_catalogue_root()

    manifest_path =
      write_manifest(root, "live_frames.section.synthetic", "section", "Version A")

    {registry_a, prepared_a} = compile_registry(root)

    assert prepared_a.external_resources == [manifest_path]

    assert {:ok, %Manifest{display_name: "Version A"}} =
             registry_a.fetch("live_frames.section.synthetic")

    signature_a = prepared_a.membership_signature
    write_manifest(root, "live_frames.section.synthetic", "section", "Version B")

    assert Compilation.membership_signature(root) == signature_a
    {registry_b, _prepared_b} = compile_registry(root)

    assert {:ok, %Manifest{display_name: "Version A"}} =
             registry_a.fetch("live_frames.section.synthetic")

    assert {:ok, %Manifest{display_name: "Version B"}} =
             registry_b.fetch("live_frames.section.synthetic")
  end

  test "a fresh compile sees manifest additions after the old hook reports stale membership" do
    root = new_catalogue_root()
    write_manifest(root, "live_frames.section.first", "section")
    {registry_a, prepared_a} = compile_registry(root)

    write_manifest(root, "live_frames.component.second", "component")

    refute Compilation.membership_signature(root) == prepared_a.membership_signature
    assert registry_a.__mix_recompile__?()

    {registry_b, _prepared_b} = compile_registry(root)

    assert Enum.map(registry_b.all(), & &1.id) == [
             "live_frames.component.second",
             "live_frames.section.first"
           ]
  end

  test "a fresh compile sees manifest removals after the old hook reports stale membership" do
    root = new_catalogue_root()
    first_path = write_manifest(root, "live_frames.section.first", "section")
    write_manifest(root, "live_frames.component.second", "component")
    {registry_a, prepared_a} = compile_registry(root)

    File.rm!(first_path)

    refute Compilation.membership_signature(root) == prepared_a.membership_signature
    assert registry_a.__mix_recompile__?()

    {registry_b, _prepared_b} = compile_registry(root)
    assert Enum.map(registry_b.all(), & &1.id) == ["live_frames.component.second"]
  end

  test "fetch uses exact binary IDs and rejects every other input" do
    root = new_catalogue_root()
    id = "live_frames.section.synthetic"
    write_manifest(root, id, "section")
    {registry_module, _prepared} = compile_registry(root)

    assert {:ok, %Manifest{id: ^id}} = registry_module.fetch(id)
    assert registry_module.fetch("live_frames.section.unknown") == :error
    assert registry_module.fetch(String.upcase(id)) == :error
    assert registry_module.fetch(" #{id}") == :error
    assert registry_module.fetch(String.trim_trailing(id) <> " ") == :error
    assert registry_module.fetch(:synthetic) == :error
    assert registry_module.fetch(nil) == :error
    assert registry_module.fetch(1) == :error
  end

  test "equivalent manifest sets compile deterministically across roots and creation orders" do
    root_a = new_catalogue_root()
    root_b = new_catalogue_root()

    write_manifest(root_a, "live_frames.component.alpha", "component", "Alpha")
    write_manifest(root_a, "live_frames.section.beta", "section", "Beta")
    write_manifest(root_b, "live_frames.section.beta", "section", "Beta")
    write_manifest(root_b, "live_frames.component.alpha", "component", "Alpha")

    {registry_a, prepared_a} = compile_registry(root_a)
    {registry_b, prepared_b} = compile_registry(root_b)

    assert registry_a.all() == registry_b.all()
    assert prepared_a.external_resources != prepared_b.external_resources

    for id <- ["live_frames.component.alpha", "live_frames.section.beta"] do
      assert registry_a.fetch(id) == registry_b.fetch(id)
    end

    refute inspect(registry_a.all()) =~ root_a
    refute inspect(registry_b.all()) =~ root_b
  end

  test "all lifecycle snapshots remain in the internal Registry" do
    root = new_catalogue_root()

    snapshots = [
      {"draft", "DRAFT", transition("admit_to_catalogue", nil, "DRAFT")},
      {"released", "RELEASED", transition("release", "APPROVED", "RELEASED")},
      {"deprecated", "DEPRECATED", transition("deprecate", "RELEASED", "DEPRECATED")},
      {"withdrawn", "WITHDRAWN", transition("withdraw", "DRAFT", "WITHDRAWN")},
      {"retired", "RETIRED", transition("retire", "DEPRECATED", "RETIRED")}
    ]

    for {slug, state, last_transition} <- snapshots do
      id = "live_frames.section.#{slug}"
      write_manifest(root, id, "section", "Synthetic #{slug}", state, last_transition)
    end

    {registry_module, _prepared} = compile_registry(root)

    assert Enum.sort(Enum.map(registry_module.all(), & &1.state)) ==
             Enum.sort(Enum.map(snapshots, &elem(&1, 1)))
  end

  defp compile_registry(root) do
    prepared = Compilation.prepare!(root)

    module =
      Module.concat(__MODULE__, "Compiled#{System.unique_integer([:positive, :monotonic])}")

    external_resources =
      Enum.map(prepared.external_resources, fn path ->
        quote do
          @external_resource unquote(path)
        end
      end)

    body =
      quote do
        unquote_splicing(external_resources)

        @source_root unquote(root)
        @membership_signature unquote(Macro.escape(prepared.membership_signature))
        @manifests unquote(Macro.escape(prepared.manifests))
        @manifest_by_id Map.new(@manifests, &{&1.id, &1})

        def all, do: @manifests

        def fetch(id) when is_binary(id), do: Map.fetch(@manifest_by_id, id)
        def fetch(_id), do: :error

        def __mix_recompile__? do
          unquote(Compilation).membership_signature(@source_root) != @membership_signature
        end
      end

    assert {:module, ^module, _bytecode, _module_info} =
             Module.create(module, body, Macro.Env.location(__ENV__))

    on_exit(fn ->
      :code.purge(module)
      :code.delete(module)
    end)

    {module, prepared}
  end

  defp new_catalogue_root do
    base =
      Path.join(
        System.tmp_dir!(),
        "liveframes-registry-#{System.unique_integer([:positive, :monotonic])}"
      )

    root = Path.join(base, "catalogue")
    File.mkdir_p!(base)
    on_exit(fn -> File.rm_rf!(base) end)
    root
  end

  defp write_manifest(
         root,
         id,
         kind,
         display_name \\ "Synthetic",
         state \\ "DRAFT",
         last_transition \\ nil
       ) do
    directory = Map.fetch!(@kind_directories, kind)
    slug = id |> String.split(".") |> List.last()
    path = Path.join([root, directory, "#{slug}.json"])
    File.mkdir_p!(Path.dirname(path))

    last_transition = last_transition || transition("admit_to_catalogue", nil, "DRAFT")

    File.write!(
      path,
      Jason.encode!(valid_manifest(id, kind, display_name, state, last_transition))
    )

    path
  end

  defp valid_manifest(id, kind, display_name, state, last_transition) do
    %{
      "schema_version" => 1,
      "id" => id,
      "kind" => kind,
      "display_name" => display_name,
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
