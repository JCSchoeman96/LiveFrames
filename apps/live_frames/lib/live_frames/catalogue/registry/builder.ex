defmodule LiveFrames.Catalogue.Registry.Builder do
  @moduledoc false

  alias LiveFrames.Catalogue.Identity
  alias LiveFrames.Catalogue.Lifecycle
  alias LiveFrames.Catalogue.Manifest

  @logical_root "apps/live_frames/priv/catalogue"

  @kind_directories %{
    "primitives" => "primitive",
    "components" => "component",
    "patterns" => "pattern",
    "sections" => "section",
    "pages" => "page",
    "templates" => "template"
  }

  @spec build(term()) :: {:ok, [Manifest.t()]} | {:error, [map()]}
  def build(source_root) when is_binary(source_root) do
    case File.lstat(source_root) do
      {:error, :enoent} ->
        {:ok, []}

      {:ok, %File.Stat{type: :directory}} ->
        build_existing_root(source_root)

      {:ok, _stat} ->
        builder_error(
          "catalogue.registry.builder.root_invalid",
          @logical_root,
          "Catalogue root must be a real directory."
        )

      {:error, _reason} ->
        builder_error(
          "catalogue.registry.builder.root_invalid",
          @logical_root,
          "Catalogue root could not be inspected."
        )
    end
  end

  def build(_source_root) do
    builder_error(
      "catalogue.registry.builder.root_invalid",
      @logical_root,
      "Catalogue root must be supplied as a binary path."
    )
  end

  defp build_existing_root(source_root) do
    with {:ok, {kind_directories, root_layout_errors}} <-
           discover_kind_directories(source_root),
         {:ok, {candidates, kind_layout_errors}} <- discover_candidates(kind_directories) do
      case first_layout_error(root_layout_errors ++ kind_layout_errors) do
        :ok ->
          candidates =
            Enum.sort_by(candidates, fn {_physical_path, logical_path} -> logical_path end)

          validate_and_build(candidates)

        {:error, diagnostics} ->
          {:error, diagnostics}
      end
    end
  end

  defp validate_and_build(candidates) do
    with {:ok, entries} <- validate_candidates(candidates),
         :ok <- Identity.validate_collection(entries) do
      manifests =
        entries
        |> Enum.sort_by(fn {manifest, _logical_path} -> manifest.id end)
        |> Enum.map(fn {manifest, _logical_path} -> manifest end)

      {:ok, manifests}
    end
  end

  defp discover_kind_directories(source_root) do
    with {:ok, names} <- list_directory(source_root, @logical_root) do
      {directories, layout_errors} =
        Enum.reduce(Enum.sort(names), {[], []}, fn name, {directories, errors} ->
          case inspect_kind_directory(source_root, name) do
            {:ok, directory} -> {[directory | directories], errors}
            {:error, diagnostics} -> {directories, Enum.reverse(diagnostics, errors)}
          end
        end)

      {:ok, {Enum.reverse(directories), layout_errors}}
    end
  end

  defp inspect_kind_directory(source_root, name) do
    cond do
      not String.valid?(name) ->
        layout_error(@logical_root, "Root entry name is not valid UTF-8.")

      true ->
        case Map.fetch(@kind_directories, name) do
          :error ->
            layout_error(
              "#{@logical_root}/#{name}",
              "Root entry is not a recognized kind directory."
            )

          {:ok, _kind} ->
            physical_path = Path.join(source_root, name)
            logical_path = "#{@logical_root}/#{name}"

            case File.lstat(physical_path) do
              {:ok, %File.Stat{type: :directory}} ->
                {:ok, {name, physical_path}}

              {:ok, _stat} ->
                layout_error(logical_path, "Kind entry must be a real directory.")

              {:error, _reason} ->
                layout_error(logical_path, "Kind directory could not be inspected.")
            end
        end
    end
  end

  defp discover_candidates(kind_directories) do
    {candidates, layout_errors} =
      Enum.reduce(kind_directories, {[], []}, fn {directory, physical_directory},
                                                 {candidates, errors} ->
        logical_directory = "#{@logical_root}/#{directory}"

        case discover_directory_candidates(
               directory,
               physical_directory,
               logical_directory
             ) do
          {:ok, {directory_candidates, directory_errors}} ->
            {Enum.reverse(directory_candidates, candidates),
             Enum.reverse(directory_errors, errors)}

          {:error, diagnostics} ->
            {candidates, Enum.reverse(diagnostics, errors)}
        end
      end)

    {:ok, {candidates, layout_errors}}
  end

  defp discover_directory_candidates(directory, physical_directory, logical_directory) do
    with {:ok, names} <- list_directory(physical_directory, logical_directory) do
      {candidates, layout_errors} =
        Enum.reduce(Enum.sort(names), {[], []}, fn name, {candidates, errors} ->
          case inspect_candidate(directory, physical_directory, logical_directory, name) do
            {:ok, candidate} -> {[candidate | candidates], errors}
            {:error, diagnostics} -> {candidates, Enum.reverse(diagnostics, errors)}
          end
        end)

      {:ok, {Enum.reverse(candidates), layout_errors}}
    end
  end

  defp inspect_candidate(directory, physical_directory, logical_directory, name) do
    cond do
      not String.valid?(name) ->
        layout_error(logical_directory, "Kind directory entry name is not valid UTF-8.")

      String.starts_with?(name, ".") ->
        layout_error("#{logical_directory}/#{name}", "Hidden entries are not allowed.")

      not String.ends_with?(name, ".json") ->
        layout_error(
          "#{logical_directory}/#{name}",
          "Kind directories may contain only JSON manifests."
        )

      true ->
        physical_path = Path.join(physical_directory, name)
        logical_path = "#{logical_directory}/#{name}"

        case File.lstat(physical_path) do
          {:ok, %File.Stat{type: :regular}} ->
            {:ok, {physical_path, "#{@logical_root}/#{directory}/#{name}"}}

          {:ok, _stat} ->
            layout_error(logical_path, "Manifest candidate must be a regular file.")

          {:error, _reason} ->
            layout_error(logical_path, "Manifest candidate could not be inspected.")
        end
    end
  end

  defp validate_candidates(candidates) do
    Enum.reduce_while(candidates, {:ok, []}, fn candidate, {:ok, entries} ->
      case validate_candidate(candidate) do
        {:ok, entry} -> {:cont, {:ok, [entry | entries]}}
        {:error, diagnostics} -> {:halt, {:error, diagnostics}}
      end
    end)
    |> reverse_success()
  end

  defp validate_candidate({physical_path, logical_path}) do
    case File.read(physical_path) do
      {:ok, bytes} ->
        with {:ok, manifest} <- Manifest.decode(bytes),
             :ok <- Identity.validate(manifest, logical_path),
             :ok <- Lifecycle.validate_snapshot(manifest) do
          {:ok, {manifest, logical_path}}
        end

      {:error, _reason} ->
        builder_error(
          "catalogue.registry.builder.read_failed",
          logical_path,
          "Manifest file could not be read."
        )
    end
  end

  defp list_directory(physical_path, logical_path) do
    # File.ls/1 drops non-UTF-8 names, so keep raw bytes for fail-closed validation.
    case :file.list_dir_all(physical_path) do
      {:ok, names} ->
        case normalize_names(names) do
          {:ok, binary_names} ->
            {:ok, binary_names}

          :error ->
            layout_error(
              logical_path,
              "Directory entries could not be represented as UTF-8 names."
            )
        end

      {:error, _reason} ->
        layout_error(logical_path, "Directory entries could not be inspected.")
    end
  end

  defp normalize_names(names) do
    Enum.reduce_while(names, {:ok, []}, fn
      name, {:ok, acc} when is_binary(name) ->
        {:cont, {:ok, [name | acc]}}

      name, {:ok, acc} when is_list(name) ->
        case :unicode.characters_to_binary(name) do
          binary when is_binary(binary) -> {:cont, {:ok, [binary | acc]}}
          _ -> {:halt, :error}
        end

      _name, {:ok, _acc} ->
        {:halt, :error}
    end)
    |> reverse_success()
  end

  defp reverse_success({:ok, values}), do: {:ok, Enum.reverse(values)}
  defp reverse_success(error), do: error

  defp first_layout_error([]), do: :ok

  defp first_layout_error(diagnostics) do
    first = Enum.min_by(diagnostics, &{&1.path, &1.code, &1.message})
    {:error, [first]}
  end

  defp layout_error(path, message) do
    builder_error("catalogue.registry.builder.layout_invalid", path, message)
  end

  defp builder_error(code, path, message) do
    {:error, [%{code: code, path: path, message: message}]}
  end
end
