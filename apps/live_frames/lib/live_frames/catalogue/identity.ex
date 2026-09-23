defmodule LiveFrames.Catalogue.Identity do
  @moduledoc """
  Pure validation for Catalogue v1 identity, slug derivation, and canonical paths.

  Operates on already-decoded manifests and caller-supplied repository-relative
  paths. Does not scan the filesystem or reserve identities outside the supplied
  collection.
  """

  alias LiveFrames.Catalogue.Manifest

  @namespace "live_frames"
  @catalogue_root "apps/live_frames/priv/catalogue"

  @kinds ~w(primitive component pattern section page template)

  @kind_directories %{
    "primitive" => "primitives",
    "component" => "components",
    "pattern" => "patterns",
    "section" => "sections",
    "page" => "pages",
    "template" => "templates"
  }

  @key_regex ~r/^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$/

  @windows_reserved_names ["con", "prn", "aux", "nul"] ++
                            for(n <- 1..9, prefix <- ["com", "lpt"], do: "#{prefix}#{n}")

  @windows_reserved MapSet.new(@windows_reserved_names)

  @type diagnostic :: %{code: String.t(), path: String.t(), message: String.t()}
  @type entry :: {Manifest.t(), String.t()}

  @spec slug(String.t()) :: {:ok, String.t()} | {:error, [diagnostic()]}
  def slug(id) when is_binary(id) do
    case parse_segments(id) do
      {:ok, _namespace, _kind, key} ->
        cond do
          not key_matches?(key) ->
            id_invalid(id, "ID key segment is invalid.")

          windows_reserved?(key) ->
            {:error, [slug_reserved(id, key)]}

          true ->
            {:ok, key}
        end

      {:error, diagnostics} ->
        {:error, diagnostics}
    end
  end

  def slug(_id), do: {:error, [id_invalid("", "ID must be a string.")]}

  @spec canonical_path(String.t(), String.t()) :: {:ok, String.t()} | {:error, [diagnostic()]}
  def canonical_path(id, kind) when is_binary(id) and is_binary(kind) do
    with {:ok, _namespace, _id_kind, key} <- parse_segments(id),
         :ok <- validate_key_for_derivation(id, key),
         {:ok, directory} <- kind_directory(kind) do
      {:ok, "#{@catalogue_root}/#{directory}/#{key}.json"}
    end
  end

  def canonical_path(_id, _kind),
    do: {:error, [id_invalid("", "ID and kind must be strings.")]}

  @spec validate(Manifest.t(), String.t()) :: :ok | {:error, [diagnostic()]}
  def validate(%Manifest{id: id, kind: manifest_kind}, repository_relative_path)
      when is_binary(repository_relative_path) do
    case collect_entry_diagnostics(id, manifest_kind, repository_relative_path) do
      [] -> :ok
      diagnostics -> {:error, diagnostics}
    end
  end

  def validate(_manifest, _path),
    do: {:error, [id_invalid("id", "Manifest and path are required.")]}

  @spec validate_collection([entry()]) :: :ok | {:error, [diagnostic()]}
  def validate_collection(entries) when is_list(entries) do
    entry_diagnostics =
      Enum.flat_map(entries, fn
        {%Manifest{} = manifest, path} when is_binary(path) ->
          collect_entry_diagnostics(manifest.id, manifest.kind, path)

        _ ->
          [id_invalid("id", "Each entry must be a manifest and repository-relative path.")]
      end)

    duplicate_diagnostics = collection_duplicate_diagnostics(entries)

    case entry_diagnostics ++ duplicate_diagnostics do
      [] -> :ok
      diagnostics -> {:error, diagnostics}
    end
  end

  defp collect_entry_diagnostics(id, manifest_kind, repository_relative_path) do
    id_diagnostics = validate_id_structure(id)
    kind_diagnostics = validate_manifest_kind(id, manifest_kind)

    path_diagnostics =
      case canonical_path_for_valid_id(id, manifest_kind) do
        {:ok, expected_path} ->
          if repository_relative_path == expected_path do
            []
          else
            [path_mismatch(id, repository_relative_path, expected_path)]
          end

        :error ->
          []
      end

    id_diagnostics ++ kind_diagnostics ++ path_diagnostics
  end

  defp validate_id_structure(id) when not is_binary(id),
    do: [id_invalid("id", "ID must be a string.")]

  defp validate_id_structure(id) do
    case parse_segments(id) do
      {:error, diagnostics} ->
        diagnostics

      {:ok, namespace, id_kind, key} ->
        []
        |> maybe_add(namespace != @namespace, id_invalid(id, "Namespace must be live_frames."))
        |> maybe_add(id_kind not in @kinds, kind_invalid(id, id_kind))
        |> maybe_add(not key_matches?(key), id_invalid(id, "ID key segment is invalid."))
        |> maybe_add(windows_reserved?(key), slug_reserved(id, key))
    end
  end

  defp validate_manifest_kind(id, manifest_kind) when not is_binary(manifest_kind),
    do: [kind_invalid(id, inspect(manifest_kind))]

  defp validate_manifest_kind(id, manifest_kind) do
    case parse_segments(id) do
      {:ok, _namespace, id_kind, _key} when id_kind != manifest_kind ->
        [kind_mismatch(id, manifest_kind, id_kind)]

      _ ->
        []
    end
  end

  defp canonical_path_for_valid_id(id, manifest_kind) do
    with {:ok, _namespace, id_kind, key} <- parse_segments(id),
         true <- id_kind in @kinds,
         true <- key_matches?(key),
         false <- windows_reserved?(key),
         true <- id_kind == manifest_kind,
         {:ok, directory} <- kind_directory(manifest_kind) do
      {:ok, "#{@catalogue_root}/#{directory}/#{key}.json"}
    else
      _ -> :error
    end
  end

  defp collection_duplicate_diagnostics(entries) do
    {id_counts, path_counts} =
      Enum.reduce(entries, {%{}, %{}}, fn
        {%Manifest{id: id}, path}, {ids, paths} when is_binary(id) and is_binary(path) ->
          {Map.update(ids, id, 1, &(&1 + 1)), Map.update(paths, path, 1, &(&1 + 1))}

        _, acc ->
          acc
      end)

    id_dupes =
      id_counts
      |> Enum.filter(fn {_id, count} -> count > 1 end)
      |> Enum.map(fn {id, _count} -> id_duplicate(id) end)

    path_dupes =
      path_counts
      |> Enum.filter(fn {_path, count} -> count > 1 end)
      |> Enum.map(fn {path, _count} -> path_duplicate(path) end)

    id_dupes ++ path_dupes
  end

  defp parse_segments(id) do
    segments = String.split(id, ".", trim: false)

    cond do
      length(segments) != 3 ->
        {:error, [id_invalid(id, "ID must have exactly three segments.")]}

      Enum.any?(segments, &(&1 == "")) ->
        {:error, [id_invalid(id, "ID must not contain empty segments.")]}

      true ->
        [namespace, kind, key] = segments
        {:ok, namespace, kind, key}
    end
  end

  defp validate_key_for_derivation(id, key) do
    cond do
      not key_matches?(key) ->
        {:error, [id_invalid(id, "ID key segment is invalid.")]}

      windows_reserved?(key) ->
        {:error, [slug_reserved(id, key)]}

      true ->
        :ok
    end
  end

  defp kind_directory(kind) do
    case Map.fetch(@kind_directories, kind) do
      {:ok, directory} -> {:ok, directory}
      :error -> {:error, [kind_invalid(kind, kind)]}
    end
  end

  defp key_matches?(key), do: Regex.match?(@key_regex, key)

  defp windows_reserved?(key), do: MapSet.member?(@windows_reserved, String.downcase(key))

  defp maybe_add(diagnostics, false, _diagnostic), do: diagnostics
  defp maybe_add(diagnostics, true, diagnostic), do: diagnostics ++ [diagnostic]

  defp id_invalid(id, message),
    do: %{
      code: "catalogue.identity.id_invalid",
      path: "id",
      message: message_with_id(id, message)
    }

  defp kind_invalid(id, kind),
    do: %{
      code: "catalogue.identity.kind_invalid",
      path: "kind",
      message: "Kind #{inspect(kind)} is not allowed for ID #{inspect(id)}."
    }

  defp kind_mismatch(id, manifest_kind, id_kind),
    do: %{
      code: "catalogue.identity.kind_mismatch",
      path: "kind",
      message:
        "Manifest kind #{inspect(manifest_kind)} does not match ID kind #{inspect(id_kind)} for #{inspect(id)}."
    }

  defp slug_reserved(id, key),
    do: %{
      code: "catalogue.identity.slug_reserved",
      path: "id",
      message: "Derived slug #{inspect(key)} is Windows-reserved for ID #{inspect(id)}."
    }

  defp path_mismatch(id, supplied, expected),
    do: %{
      code: "catalogue.identity.path_mismatch",
      path: "path",
      message:
        "Supplied path #{inspect(supplied)} does not match canonical path #{inspect(expected)} for ID #{inspect(id)}."
    }

  defp id_duplicate(id),
    do: %{
      code: "catalogue.identity.id_duplicate",
      path: "id",
      message: "Duplicate catalogue ID #{inspect(id)}."
    }

  defp path_duplicate(path),
    do: %{
      code: "catalogue.identity.path_duplicate",
      path: "path",
      message: "Duplicate canonical path #{inspect(path)}."
    }

  defp message_with_id("", message), do: message
  defp message_with_id(id, message), do: "#{message} (#{inspect(id)})"
end
