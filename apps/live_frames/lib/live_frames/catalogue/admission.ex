defmodule LiveFrames.Catalogue.Admission do
  @moduledoc """
  Admits a fresh DRAFT manifest into a repository Catalogue.

  The canonical manifest file is created exclusively and reserves its identity.
  """

  alias LiveFrames.Catalogue.CanonicalJSON
  alias LiveFrames.Catalogue.Identity
  alias LiveFrames.Catalogue.Lifecycle
  alias LiveFrames.Catalogue.Manifest
  alias LiveFrames.Catalogue.Registry.Builder

  @logical_root "apps/live_frames/priv/catalogue"

  @type diagnostic :: %{code: String.t(), path: String.t(), message: String.t()}

  @spec admit(binary(), map(), term()) ::
          {:ok, Manifest.t(), String.t()} | {:error, [diagnostic()] | diagnostic()}
  def admit(catalogue_root, candidate_map, guard_result) do
    with {:ok, candidate_json} <- CanonicalJSON.encode(candidate_map),
         {:ok, manifest} <- Manifest.decode(candidate_json),
         {:ok, logical_path} <- Identity.canonical_path(manifest.id, manifest.kind),
         :ok <- Identity.validate(manifest, logical_path),
         {:ok, existing_manifests} <- Builder.build(catalogue_root),
         :ok <- ensure_identity_is_available(existing_manifests, manifest),
         {:ok, admitted_manifest} <-
           Lifecycle.transition(manifest, "admit_to_catalogue", guard_result),
         {:ok, bytes} <- CanonicalJSON.encode(manifest_document(admitted_manifest)),
         :ok <- reserve_manifest(catalogue_root, logical_path, bytes) do
      {:ok, admitted_manifest, logical_path}
    end
  end

  defp ensure_identity_is_available(existing_manifests, candidate) do
    with {:ok, existing_entries} <- existing_entries(existing_manifests),
         {:ok, candidate_path} <- Identity.canonical_path(candidate.id, candidate.kind) do
      Identity.validate_collection(existing_entries ++ [{candidate, candidate_path}])
    end
  end

  defp existing_entries(manifests) do
    Enum.reduce_while(manifests, {:ok, []}, fn manifest, {:ok, entries} ->
      case Identity.canonical_path(manifest.id, manifest.kind) do
        {:ok, path} -> {:cont, {:ok, [{manifest, path} | entries]}}
        {:error, diagnostics} -> {:halt, {:error, diagnostics}}
      end
    end)
    |> case do
      {:ok, entries} -> {:ok, Enum.reverse(entries)}
      error -> error
    end
  end

  defp reserve_manifest(catalogue_root, logical_path, bytes) do
    relative_path = String.replace_prefix(logical_path, @logical_root <> "/", "")
    physical_path = Path.join(catalogue_root, relative_path)

    with :ok <- ensure_directory(Path.dirname(physical_path)),
         {:ok, file} <- exclusive_open(physical_path),
         :ok <- write_and_close(file, physical_path, bytes) do
      :ok
    end
  end

  defp ensure_directory(path) do
    case File.mkdir_p(path) do
      :ok -> :ok
      {:error, _reason} -> write_failed()
    end
  end

  defp exclusive_open(path) do
    case File.open(path, [:write, :binary, :exclusive]) do
      {:ok, file} -> {:ok, file}
      {:error, :eexist} -> already_reserved()
      {:error, _reason} -> write_failed()
    end
  end

  defp write_and_close(file, path, bytes) do
    write_result = IO.binwrite(file, bytes)
    close_result = File.close(file)

    case {write_result, close_result} do
      {:ok, :ok} ->
        :ok

      _ ->
        File.rm(path)
        write_failed()
    end
  end

  defp manifest_document(manifest) do
    manifest
    |> Map.from_struct()
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new(fn {key, value} -> {Atom.to_string(key), value} end)
  end

  defp already_reserved do
    {:error,
     [
       %{
         code: "catalogue.admission.path_reserved",
         path: "path",
         message: "Canonical Catalogue manifest path is already reserved."
       }
     ]}
  end

  defp write_failed do
    {:error,
     [
       %{
         code: "catalogue.admission.write_failed",
         path: "path",
         message: "Canonical Catalogue manifest could not be created."
       }
     ]}
  end
end
