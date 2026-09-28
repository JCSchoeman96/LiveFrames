defmodule LiveFrames.Catalogue.Registry.Compilation do
  @moduledoc false

  alias LiveFrames.Catalogue.Identity
  alias LiveFrames.Catalogue.Registry.Builder

  @logical_root "apps/live_frames/priv/catalogue"

  @spec prepare!(term()) :: %{
          manifests: [struct()],
          external_resources: [Path.t()],
          membership_signature: binary()
        }
  def prepare!(source_root) do
    case Builder.build(source_root) do
      {:ok, manifests} ->
        %{
          manifests: manifests,
          external_resources: external_resources(source_root, manifests),
          membership_signature: membership_signature(source_root)
        }

      {:error, diagnostics} ->
        raise CompileError,
          description: format_builder_diagnostics(diagnostics)
    end
  end

  @spec membership_signature(term()) :: binary()
  def membership_signature(source_root) when is_binary(source_root) do
    source_root
    |> root_membership()
    |> :erlang.term_to_binary([:deterministic])
  end

  def membership_signature(_source_root) do
    :erlang.term_to_binary({:invalid_root, :not_binary}, [:deterministic])
  end

  defp external_resources(source_root, manifests) do
    Enum.map(manifests, fn manifest ->
      {:ok, logical_path} = Identity.canonical_path(manifest.id, manifest.kind)
      relative_path = Path.relative_to(logical_path, @logical_root)
      Path.join(source_root, relative_path)
    end)
  end

  defp format_builder_diagnostics(diagnostics) do
    details =
      Enum.map_join(diagnostics, "\n", fn
        %{code: code, path: path, message: message} ->
          "#{code} at #{path}: #{message}"

        diagnostic ->
          inspect(diagnostic, charlists: :as_lists, limit: :infinity, printable_limit: :infinity)
      end)

    "Catalogue Registry compilation failed because Builder rejected its source:\n#{details}"
  end

  defp root_membership(source_root) do
    case File.lstat(source_root) do
      {:ok, %File.Stat{type: :directory} = stat} ->
        {:directory, stat.type, directory_entries(source_root)}

      {:ok, stat} ->
        {:entry, stat.type}

      {:error, reason} ->
        {:lstat_error, reason}
    end
  end

  defp directory_entries(directory) do
    case raw_directory_names(directory) do
      {:ok, names} ->
        names
        |> Enum.sort()
        |> Enum.map(fn name ->
          case direct_entry_path(directory, name) do
            {:ok, path} ->
              case File.lstat(path) do
                {:ok, %File.Stat{type: :directory} = stat} ->
                  {name, stat.type, direct_child_entries(path)}

                {:ok, stat} ->
                  {name, stat.type}

                {:error, reason} ->
                  {name, :lstat_error, reason}
              end

            :invalid_name ->
              {name, :invalid_name}
          end
        end)

      {:error, reason} ->
        {:list_error, reason}
    end
  end

  defp direct_child_entries(directory) do
    case raw_directory_names(directory) do
      {:ok, names} ->
        names
        |> Enum.sort()
        |> Enum.map(fn name ->
          case direct_entry_path(directory, name) do
            {:ok, path} ->
              case File.lstat(path) do
                {:ok, stat} -> {name, stat.type}
                {:error, reason} -> {name, :lstat_error, reason}
              end

            :invalid_name ->
              {name, :invalid_name}
          end
        end)

      {:error, reason} ->
        {:list_error, reason}
    end
  end

  defp raw_directory_names(directory) do
    case :file.list_dir_all(directory) do
      {:ok, names} -> normalize_raw_names(names)
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_raw_names(names) do
    Enum.reduce_while(names, {:ok, []}, fn name, {:ok, normalized} ->
      case raw_name(name) do
        {:ok, binary} -> {:cont, {:ok, [binary | normalized]}}
        :error -> {:halt, {:error, :invalid_entry_name}}
      end
    end)
    |> case do
      {:ok, normalized} -> {:ok, Enum.reverse(normalized)}
      error -> error
    end
  end

  defp raw_name(name) when is_binary(name), do: {:ok, name}

  defp raw_name(name) when is_list(name) do
    if Enum.all?(name, &(is_integer(&1) and &1 >= 0 and &1 <= 255)) do
      {:ok, :erlang.list_to_binary(name)}
    else
      case :unicode.characters_to_binary(name, :unicode, :utf8) do
        binary when is_binary(binary) -> {:ok, binary}
        _invalid -> :error
      end
    end
  end

  defp raw_name(_name), do: :error

  defp direct_entry_path(directory, name) do
    if direct_entry_name?(name) do
      {:ok, Path.join(directory, name)}
    else
      :invalid_name
    end
  end

  defp direct_entry_name?(name) do
    name not in ["", ".", ".."] and
      :binary.match(name, <<"/">>) == :nomatch and
      :binary.match(name, <<0>>) == :nomatch
  end
end
