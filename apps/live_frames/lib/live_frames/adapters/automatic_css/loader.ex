defmodule LiveFrames.Adapters.AutomaticCSS.Loader do
  @moduledoc """
  Loads and recognizes the initial flat Automatic.css settings envelope.
  """

  alias LiveFrames.Tokens.Diagnostic
  alias LiveFrames.Adapters.AutomaticCSS.Normalizer

  @adapter_version "1.0.0"
  @reference_size 92_199
  @reference_read_limit @reference_size + 1
  @reference_sha256 "19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05"
  @reference_identity_options [
    source_version: "4.0.1",
    source_version_status: "fixture_reference",
    export_version: nil
  ]
  @source_identity_option_keys [:source_version, :source_version_status, :export_version]

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

  def from_reference_file(path, opts \\ [])

  @spec from_reference_file(term(), keyword()) ::
          {:ok, map(), map()} | {:error, [Diagnostic.t()]}
  def from_reference_file(path, opts) when is_binary(path) and is_list(opts) do
    if Keyword.keyword?(opts) do
      with {:ok, bytes} <- read_reference_bytes(path),
           :ok <- verify_reference_bytes(bytes),
           {:ok, settings} <- decode_reference_bytes(bytes),
           {:ok, settings, source_metadata} <-
             recognize(settings, trusted_identity_options(opts)) do
        {:ok, settings, source_metadata}
      end
    else
      {:error,
       [diagnostic("acss.source.invalid", "Automatic.css source options must be a keyword list")]}
    end
  end

  def from_reference_file(_path, _opts) do
    {:error,
     [diagnostic("acss.source.invalid", "Automatic.css reference path and options are invalid")]}
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

  defp read_reference_bytes(path) do
    case File.open(path, [:read, :binary]) do
      {:ok, device} ->
        result =
          try do
            {:ok, IO.binread(device, @reference_read_limit)}
          rescue
            _error -> :read_error
          after
            File.close(device)
          end

        case result do
          {:ok, bytes} when is_binary(bytes) -> {:ok, bytes}
          {:ok, :eof} -> {:ok, <<>>}
          _ -> reference_read_error()
        end

      {:error, _reason} ->
        reference_read_error()
    end
  end

  defp verify_reference_bytes(bytes) when byte_size(bytes) == @reference_size do
    digest = :crypto.hash(:sha256, bytes)

    if Base.encode16(digest, case: :lower) == @reference_sha256 do
      :ok
    else
      reference_mismatch()
    end
  end

  defp verify_reference_bytes(_bytes), do: reference_mismatch()

  defp decode_reference_bytes(bytes) do
    case Jason.decode(bytes) do
      {:ok, settings} ->
        {:ok, settings}

      {:error, _reason} ->
        {:error,
         [
           diagnostic(
             "acss.source.invalid",
             "Automatic.css reference file contains invalid settings"
           )
         ]}
    end
  end

  defp trusted_identity_options(opts) do
    opts
    |> Keyword.drop(@source_identity_option_keys)
    |> then(fn normalization_opts ->
      Enum.reduce(@reference_identity_options, normalization_opts, fn {key, value}, acc ->
        Keyword.put(acc, key, value)
      end)
    end)
  end

  defp reference_read_error do
    {:error,
     [diagnostic("acss.source.invalid", "Automatic.css reference file could not be read")]}
  end

  defp reference_mismatch do
    {:error,
     [
       diagnostic(
         "acss.source.reference_mismatch",
         "Automatic.css reference file does not match the approved fixture"
       )
     ]}
  end

  defp source_version_status(nil), do: "not_embedded"
  defp source_version_status(_source_version), do: "caller_supplied"

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
