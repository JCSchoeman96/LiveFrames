defmodule LiveFrames.Catalogue.AdmissionTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Catalogue.Admission
  alias LiveFrames.Catalogue.CanonicalJSON
  alias LiveFrames.Catalogue.Identity
  alias LiveFrames.Catalogue.Lifecycle
  alias LiveFrames.Catalogue.Manifest
  alias LiveFrames.Catalogue.Registry.Builder

  @logical_root "apps/live_frames/priv/catalogue"
  @guard_result {:ok, ["synthetic:guard-evidence"]}

  test "admits a fresh candidate to an absent catalogue root at its canonical path" do
    root = new_catalogue_root()
    candidate = candidate("live_frames.section.synthetic_empty")
    {:ok, logical_path} = Identity.canonical_path(candidate["id"], candidate["kind"])

    refute File.exists?(root)

    assert {:ok, admitted, ^logical_path} = Admission.admit(root, candidate, @guard_result)
    assert admitted.state == "DRAFT"

    assert admitted.lifecycle["last_transition"] == %{
             "action" => "admit_to_catalogue",
             "from" => nil,
             "to" => "DRAFT",
             "evidence_refs" => ["synthetic:guard-evidence"]
           }

    persisted_path = physical_path(root, logical_path)
    assert File.regular?(persisted_path)
    assert {:ok, bytes} = File.read(persisted_path)
    assert {:ok, decoded} = Manifest.decode(bytes)
    assert decoded == admitted
    assert {:ok, encoded} = CanonicalJSON.encode(manifest_map(admitted))
    assert bytes == encoded
    assert {:ok, [%Manifest{id: "live_frames.section.synthetic_empty"}]} = Builder.build(root)
  end

  test "admits a unique ID into an existing valid catalogue" do
    root = new_catalogue_root()
    existing = candidate("live_frames.section.synthetic_existing")
    write_admitted(root, existing)
    candidate = candidate("live_frames.section.synthetic_new")

    assert {:ok, %Manifest{id: "live_frames.section.synthetic_new"}, _path} =
             Admission.admit(root, candidate, @guard_result)

    assert {:ok, manifests} = Builder.build(root)

    assert Enum.sort(Enum.map(manifests, & &1.id)) == [
             "live_frames.section.synthetic_existing",
             "live_frames.section.synthetic_new"
           ]
  end

  test "rejects duplicate IDs without changing existing bytes" do
    root = new_catalogue_root()
    existing = candidate("live_frames.section.synthetic_duplicate")
    path = write_admitted(root, existing)
    original = File.read!(path)

    assert {:error, diagnostics} = Admission.admit(root, existing, @guard_result)
    assert Enum.any?(diagnostics, &(&1.code == "catalogue.identity.id_duplicate"))
    assert File.read!(path) == original
    assert {:ok, [_]} = Builder.build(root)
    assert File.ls!(Path.join(root, "sections")) == ["synthetic_duplicate.json"]
  end

  test "does not overwrite a file already at the canonical path" do
    root = new_catalogue_root()
    candidate = candidate("live_frames.section.synthetic_reserved_path")
    {:ok, logical_path} = Identity.canonical_path(candidate["id"], candidate["kind"])
    path = physical_path(root, logical_path)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, "reserved bytes")

    assert {:error, _diagnostics} = Admission.admit(root, candidate, @guard_result)
    assert File.read!(path) == "reserved bytes"
  end

  test "only one concurrent admission can reserve a previously unused path" do
    root = new_catalogue_root()
    candidate = candidate("live_frames.section.synthetic_concurrent")
    parent = self()

    tasks =
      for _ <- 1..2 do
        Task.async(fn ->
          send(parent, {:ready, self()})
          receive do: (:admit -> Admission.admit(root, candidate, @guard_result))
        end)
      end

    pids = for _ <- 1..2, do: receive(do: ({:ready, pid} -> pid))
    Enum.each(pids, &send(&1, :admit))
    results = Enum.map(tasks, &Task.await(&1, 5_000))
    successes = Enum.count(results, &match?({:ok, %Manifest{}, _}, &1))
    failures = Enum.count(results, &match?({:error, [_ | _]}, &1))

    assert successes == 1
    assert failures == 1

    assert {:ok, [%Manifest{id: "live_frames.section.synthetic_concurrent"}]} =
             Builder.build(root)
  end

  test "preserves a rejected guard result and writes no manifest" do
    root = new_catalogue_root()
    diagnostics = [%{code: "synthetic.guard_rejected", path: "guard", message: "rejected"}]

    assert {:error, ^diagnostics} =
             Admission.admit(
               root,
               candidate("live_frames.section.synthetic_guard"),
               {:error, diagnostics}
             )

    refute File.exists?(root)
  end

  test "rejects invalid candidates without writing a manifest" do
    valid = candidate("live_frames.section.synthetic_invalid")

    invalid_candidates = [
      Map.put(valid, "id", "live_frames.section.bad-key"),
      Map.put(valid, "kind", "component"),
      Map.put(valid, "state", "VALIDATED"),
      Map.put(valid, "lifecycle", %{"last_transition" => %{"action" => "admit_to_catalogue"}}),
      put_in(valid, ["component", "module"], 7)
    ]

    for {invalid_candidate, index} <- Enum.with_index(invalid_candidates) do
      root = new_catalogue_root()
      assert {:error, _diagnostics} = Admission.admit(root, invalid_candidate, @guard_result)
      refute File.exists?(root), "invalid candidate #{index} wrote to disk"
    end
  end

  test "fails closed when the existing catalogue is invalid" do
    root = new_catalogue_root()
    invalid_path = Path.join([root, "sections", "broken.json"])
    File.mkdir_p!(Path.dirname(invalid_path))
    File.write!(invalid_path, "{invalid json")

    assert {:error, [diagnostic]} =
             Admission.admit(
               root,
               candidate("live_frames.section.synthetic_broken"),
               @guard_result
             )

    assert diagnostic.code == "catalogue.manifest.invalid_json"
    assert File.ls!(Path.join(root, "sections")) == ["broken.json"]
  end

  defp candidate(id) do
    %{
      "schema_version" => 1,
      "id" => id,
      "kind" => "section",
      "display_name" => "Synthetic section",
      "state" => "DRAFT",
      "component" => %{"module" => "LiveFrames.Components.Synthetic", "function" => "synthetic"},
      "storybook" => %{"module" => "LiveFrames.Stories.Synthetic"},
      "docs" => %{},
      "provenance" => %{}
    }
  end

  defp write_admitted(root, candidate) do
    {:ok, manifest} = Manifest.decode(Jason.encode!(candidate))
    {:ok, admitted} = Lifecycle.transition(manifest, "admit_to_catalogue", @guard_result)
    {:ok, logical_path} = Identity.canonical_path(admitted.id, admitted.kind)
    path = physical_path(root, logical_path)
    File.mkdir_p!(Path.dirname(path))
    {:ok, bytes} = CanonicalJSON.encode(manifest_map(admitted))
    File.write!(path, bytes)
    path
  end

  defp manifest_map(manifest) do
    manifest
    |> Map.from_struct()
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new(fn {key, value} -> {Atom.to_string(key), value} end)
  end

  defp new_catalogue_root do
    base =
      Path.join(
        System.tmp_dir!(),
        "liveframes-admission-#{System.unique_integer([:positive, :monotonic])}"
      )

    root = Path.join(base, "catalogue")
    File.mkdir_p!(base)
    on_exit(fn -> File.rm_rf!(base) end)
    root
  end

  defp physical_path(root, logical_path) do
    relative_path = String.replace_prefix(logical_path, @logical_root <> "/", "")
    Path.join(root, relative_path)
  end
end
