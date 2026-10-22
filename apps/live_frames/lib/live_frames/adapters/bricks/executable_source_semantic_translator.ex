defmodule LiveFrames.Adapters.Bricks.ExecutableSourceSemanticTranslator do
  @moduledoc """
  Turns one closed Bricks executable-source recognition into a generic binding.

  Source bytes are used only for bounded provenance fingerprinting. They are
  never copied to a binding, trace, or diagnostic.
  """

  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Element
  alias LiveFrames.IR.SourceTrace
  alias LiveFrames.IR.ValueModifier

  @max_source_bytes 16_384
  @max_source_id_bytes 256
  @max_source_path_bytes 2_048
  @max_adapter_version_bytes 64
  @recognizer_version "php-semantic-v1"
  @semantic_key "commerce.product.full_description"

  @type candidate :: %{
          required(:element) => Element.t(),
          required(:target_node_id) => String.t(),
          required(:source_bytes) => binary(),
          required(:execution_enabled) => boolean(),
          required(:source_trace) => SourceTrace.t()
        }

  @spec translate(candidate(), term()) ::
          {:ok, map(), Diagnostic.t()} | {:unsupported, Diagnostic.t()}
  def translate(candidate, recognition_result) do
    with :ok <- validate_candidate(candidate),
         {:ok, source_bytes, source_trace, target_node_id} <- candidate_fields(candidate),
         :ok <- check_source_size(source_bytes),
         {:ok, :current_entity_full_description} <- validate_recognition(recognition_result) do
      trace = translated_trace(source_trace, source_bytes)

      binding_candidate = %{
        target_node_id: target_node_id,
        target_kind: :rich_text,
        value_kind: :field,
        scope: :current_entity,
        value_key: @semantic_key,
        collection_binding_id: nil,
        modifier: %ValueModifier.None{},
        normalization_status: :normalized,
        source_trace: trace
      }

      {:ok, binding_candidate, diagnostic(:translated)}
    else
      {:error, reason} -> {:unsupported, diagnostic(reason)}
      _other -> {:unsupported, diagnostic(:semantic_unsupported)}
    end
  end

  defp validate_candidate(%{
         element: %Element{name: "code"},
         target_node_id: target_node_id,
         source_bytes: source_bytes,
         execution_enabled: true,
         source_trace: %SourceTrace{}
       })
       when is_binary(target_node_id) and byte_size(target_node_id) > 0 and
              is_binary(source_bytes),
       do: :ok

  defp validate_candidate(_candidate), do: {:error, :semantic_unsupported}

  defp candidate_fields(%{
         target_node_id: target_node_id,
         source_bytes: source_bytes,
         source_trace: %SourceTrace{} = source_trace
       }) do
    {:ok, source_bytes, source_trace, target_node_id}
  end

  defp candidate_fields(_candidate), do: {:error, :semantic_unsupported}

  defp check_source_size(source_bytes) do
    if byte_size(source_bytes) <= @max_source_bytes,
      do: :ok,
      else: {:error, :resource_limit_exceeded}
  end

  defp validate_recognition({:ok, :current_entity_full_description}),
    do: {:ok, :current_entity_full_description}

  defp validate_recognition({:error, reason})
       when reason in [
              :parse_failed,
              :unsafe,
              :semantic_unsupported,
              :semantic_ambiguous,
              :resource_limit_exceeded
            ],
       do: {:error, reason}

  defp validate_recognition(_result), do: {:error, :semantic_unsupported}

  defp translated_trace(source_trace, source_bytes) do
    %SourceTrace{
      source_type: "bricks_executable_source",
      source_id: bounded_string(source_trace.source_id, @max_source_id_bytes),
      source_path: bounded_string(source_trace.source_path, @max_source_path_bytes),
      source_settings: %{},
      adapter: "bricks",
      adapter_version: bounded_string(source_trace.adapter_version, @max_adapter_version_bytes),
      metadata: %{
        "execution_enabled" => true,
        "source_fingerprint" => fingerprint(source_bytes),
        "recognizer_version" => @recognizer_version,
        "recognized_semantic" => @semantic_key,
        "translation_status" => "normalized"
      }
    }
  end

  defp fingerprint(source_bytes) do
    :crypto.hash(:sha256, source_bytes)
    |> Base.encode16(case: :lower)
  end

  defp diagnostic(:translated) do
    Diagnostic.new(
      code: "bricks.executable_source.translated",
      severity: :info,
      raw_value: nil,
      message: "Bricks executable source normalized as current entity full description",
      metadata: %{}
    )
  end

  defp diagnostic(reason) do
    {code, message} = diagnostic_details(reason)

    Diagnostic.new(
      code: code,
      severity: :warning,
      raw_value: nil,
      message: message,
      metadata: %{}
    )
  end

  defp diagnostic_details(:parse_failed),
    do:
      {"bricks.executable_source.parse_failed",
       "Bricks executable source could not be parsed by the closed recognizer"}

  defp diagnostic_details(:unsafe),
    do:
      {"bricks.executable_source.unsafe", "Bricks executable source contains an unsafe construct"}

  defp diagnostic_details(:semantic_ambiguous),
    do:
      {"bricks.executable_source.semantic_ambiguous",
       "Bricks executable source has ambiguous semantics"}

  defp diagnostic_details(:resource_limit_exceeded),
    do:
      {"bricks.executable_source.resource_limit_exceeded",
       "Bricks executable source exceeds parser limits"}

  defp diagnostic_details(_reason),
    do:
      {"bricks.executable_source.semantic_unsupported",
       "Bricks executable source has an unsupported semantic"}

  defp bounded_string(value, limit) when is_binary(value) and byte_size(value) <= limit,
    do: value

  defp bounded_string(_value, _limit), do: nil
end
