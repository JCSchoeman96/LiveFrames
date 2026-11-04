defmodule LiveFrames.Adapters.AutomaticCSS.Loader do
  @moduledoc """
  Loads and recognizes the initial flat Automatic.css settings envelope.
  """

  alias LiveFrames.Tokens.Diagnostic
  alias LiveFrames.Adapters.AutomaticCSS.Normalizer

  @adapter_version "1.0.0"
  @reference_size_bytes 92_199
  @reference_sha256 "19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05"
  @reference_source_version "4.0.1"
  @reference_source_version_status "fixture_reference"
  @reference_export_version nil
  @max_reference_read_bytes @reference_size_bytes + 1

  def from_file(path, opts \\ [])

  @spec from_file(term(), keyword()) ::
          {:ok, map(), map()} | {:error, [Diagnostic.t()]}
  def from_file(path, opts) when is_binary(path) and is_list(opts) do
    case File.read(path) do
      {:ok, json} ->
        from_json(json, opts)

      {:error, reason} ->
        {:error,
         [
           diagnostic(
             "acss.source.invalid",
             "Automatic.css settings file could not be read",
             metadata: %{"reason" => inspect(reason)}
           )
         ]}
    end
  end

  def from_file(_path, _opts) do
    {:error, [diagnostic("acss.source.invalid", "Automatic.css file path must be a binary")]}
  end

  @spec from_reference_file(term()) ::
          {:ok, map(), map()} | {:error, [Diagnostic.t()]}
  def from_reference_file(path) when is_binary(path) do
    with {:ok, bytes} <- read_reference_file(path),
         :ok <- verify_reference_bytes(bytes),
         {:ok, settings} <- decode_reference_bytes(bytes),
         {:ok, recognized_settings, metadata} <- recognize(settings, []) do
      {:ok, recognized_settings, trusted_reference_metadata(metadata)}
    else
      {:error, :read_failed} ->
        {:error,
         [
           diagnostic(
             "acss.source.invalid",
             "Trusted Automatic.css reference could not be read"
           )
         ]}

      {:error, :reference_mismatch} ->
        {:error,
         [
           diagnostic(
             "acss.source.reference_mismatch",
             "Automatic.css reference bytes do not match the accepted identity"
           )
         ]}

      {:error, :unsupported_source} ->
        {:error,
         [
           diagnostic(
             "acss.source.reference_unavailable",
             "The trusted Automatic.css reference binding is unavailable"
           )
         ]}

      {:error, :invalid_json} ->
        {:error,
         [
           diagnostic(
             "acss.source.json_invalid",
             "The trusted Automatic.css reference could not be decoded"
           )
         ]}

      {:error, diagnostics} when is_list(diagnostics) ->
        {:error, diagnostics}
    end
  end

  def from_reference_file(_path) do
    {:error,
     [diagnostic("acss.source.invalid", "Trusted Automatic.css reference path must be a binary")]}
  end

  def from_json(json, opts \\ [])

  @spec from_json(term(), keyword()) ::
          {:ok, map(), map()} | {:error, [Diagnostic.t()]}
  def from_json(json, opts) when is_binary(json) and is_list(opts) do
    case Jason.decode(json) do
      {:ok, settings} ->
        recognize(settings, opts)

      {:error, reason} ->
        {:error,
         [
           diagnostic(
             "acss.source.json_invalid",
             "Automatic.css settings JSON could not be decoded",
             metadata: %{"reason" => Exception.message(reason)}
           )
         ]}
    end
  end

  def from_json(_json, _opts) do
    {:error,
     [diagnostic("acss.source.json_invalid", "Automatic.css JSON input must be a binary")]}
  end

  def recognize(settings, opts \\ [])

  @spec recognize(term(), keyword()) ::
          {:ok, map(), map()} | {:error, [Diagnostic.t()]}
  def recognize(settings, opts) when is_list(opts) do
    cond do
      not flat_settings_map?(settings) ->
        {:error,
         [diagnostic("acss.source.invalid", "expected a flat Automatic.css settings map")]}

      not recognized_settings?(settings) ->
        {:error,
         [
           diagnostic(
             "acss.source.invalid",
             "settings map does not contain a recognized Automatic.css source key"
           )
         ]}

      true ->
        {:ok, settings, source_metadata(settings, opts)}
    end
  end

  def recognize(_settings, _opts) do
    {:error,
     [diagnostic("acss.source.invalid", "Automatic.css source options must be a keyword list")]}
  end

  defp flat_settings_map?(settings) when is_map(settings) and not is_struct(settings) do
    Enum.all?(settings, fn {key, value} ->
      is_binary(key) and key != "" and json_value?(value)
    end)
  end

  defp flat_settings_map?(_settings), do: false

  defp recognized_settings?(settings) do
    Enum.any?(Normalizer.source_keys(), &Map.has_key?(settings, &1))
  end

  defp source_metadata(settings, opts) do
    source_version = Keyword.get(opts, :source_version)

    %{
      "source_system" => "automatic_css",
      "source_type" => "automatic_css_settings",
      "source_shape" => "flat_settings_map",
      "source_version" => source_version,
      "source_version_status" =>
        Keyword.get(opts, :source_version_status, source_version_status(source_version)),
      "export_version" => Keyword.get(opts, :export_version),
      "adapter" => "automatic_css",
      "adapter_version" => @adapter_version,
      "source_key_count" => map_size(settings),
      "compatibility" => "recognized_with_unknown_fields"
    }
  end

  defp source_version_status(nil), do: "not_embedded"
  defp source_version_status(_source_version), do: "caller_supplied"

  defp read_reference_file(path) do
    case File.open(path, [:read, :binary]) do
      {:ok, io_device} -> read_bounded_reference_bytes(io_device)
      {:error, _reason} -> {:error, :read_failed}
    end
  rescue
    _error -> {:error, :read_failed}
  end

  defp read_bounded_reference_bytes(io_device) do
    try do
      case IO.binread(io_device, @max_reference_read_bytes) do
        bytes when is_binary(bytes) -> {:ok, bytes}
        :eof -> {:ok, <<>>}
        {:error, _reason} -> {:error, :read_failed}
        _other -> {:error, :read_failed}
      end
    rescue
      _error -> {:error, :read_failed}
    catch
      _kind, _reason -> {:error, :read_failed}
    after
      File.close(io_device)
    end
  end

  defp verify_reference_bytes(bytes) do
    if reference_binding_available?() do
      digest = :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

      if byte_size(bytes) == @reference_size_bytes and digest == @reference_sha256 do
        :ok
      else
        {:error, :reference_mismatch}
      end
    else
      {:error, :unsupported_source}
    end
  end

  defp reference_binding_available? do
    is_integer(@reference_size_bytes) and @reference_size_bytes > 0 and
      is_binary(@reference_sha256) and byte_size(@reference_sha256) == 64 and
      @reference_source_version == "4.0.1" and
      @reference_source_version_status == "fixture_reference" and
      is_nil(@reference_export_version)
  end

  defp decode_reference_bytes(bytes) do
    case Jason.decode(bytes) do
      {:ok, settings} -> {:ok, settings}
      {:error, _reason} -> {:error, :invalid_json}
    end
  rescue
    _error -> {:error, :invalid_json}
  catch
    _kind, _reason -> {:error, :invalid_json}
  end

  defp trusted_reference_metadata(source_metadata) do
    Map.merge(source_metadata, %{
      "source_version" => @reference_source_version,
      "source_version_status" => @reference_source_version_status,
      "export_version" => @reference_export_version
    })
  end

  defp diagnostic(code, message, opts \\ []) do
    Diagnostic.new(
      [
        code: code,
        severity: :error,
        category: :source,
        message: message
      ] ++ opts
    )
  end

  defp json_value?(nil), do: true
  defp json_value?(value) when is_binary(value), do: true
  defp json_value?(value) when is_boolean(value), do: true
  defp json_value?(value) when is_integer(value), do: true
  defp json_value?(value) when is_float(value), do: true
  defp json_value?(value) when is_list(value), do: Enum.all?(value, &json_value?/1)

  defp json_value?(value) when is_map(value) and not is_struct(value),
    do:
      Enum.all?(value, fn {key, nested} ->
        (is_binary(key) or is_atom(key)) and json_value?(nested)
      end)

  defp json_value?(_value), do: false
end
