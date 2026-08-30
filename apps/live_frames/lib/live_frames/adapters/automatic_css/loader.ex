defmodule LiveFrames.Adapters.AutomaticCSS.Loader do
  @moduledoc """
  Loads and recognizes the initial flat Automatic.css settings envelope.
  """

  alias LiveFrames.Tokens.Diagnostic
  alias LiveFrames.Adapters.AutomaticCSS.Normalizer

  @source_version "4.0.1"
  @adapter_version "1.0.0"

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
    %{
      "source_system" => "automatic_css",
      "source_type" => "automatic_css_settings",
      "source_shape" => "flat_settings_map",
      "source_version" => Keyword.get(opts, :source_version, @source_version),
      "source_version_status" => Keyword.get(opts, :source_version_status, "fixture_reference"),
      "export_version" => Keyword.get(opts, :export_version),
      "adapter" => "automatic_css",
      "adapter_version" => @adapter_version,
      "source_key_count" => map_size(settings),
      "compatibility" => "recognized_with_unknown_fields"
    }
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
