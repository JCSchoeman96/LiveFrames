defmodule LiveFrames.BricksExecutableSourceSemanticTranslatorTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Element
  alias LiveFrames.Adapters.Bricks.ExecutableSourceSemanticTranslator
  alias LiveFrames.IR.SourceTrace
  alias LiveFrames.IR.ValueModifier

  @sentinel "PRIVATE_EXECUTABLE_SOURCE_SENTINEL_7f49c3"
  @source "<?php /* #{@sentinel} */ $product = wc_get_product(get_the_ID()); " <>
            "$description = $product->get_description(); if ($product) { echo $description; } ?>"

  test "returns one normalized generic binding candidate with a redacted trace" do
    source_trace = %SourceTrace{
      source_type: "bricks_element",
      source_id: "source-code-1",
      source_path: "components[0].elements[0]",
      source_name: "code",
      source_settings: %{"code" => @sentinel},
      adapter: "bricks",
      adapter_version: "1.2.3",
      metadata: %{"effective_settings" => %{"code" => @sentinel}}
    }

    candidate = %{
      element: %Element{id: "source-code-1", name: "code"},
      target_node_id: "node_000001",
      source_bytes: @source,
      execution_enabled: true,
      source_trace: source_trace
    }

    assert {:ok, binding_candidate, %Diagnostic{} = diagnostic} =
             ExecutableSourceSemanticTranslator.translate(
               candidate,
               {:ok, :current_entity_full_description}
             )

    assert binding_candidate.target_node_id == "node_000001"
    assert binding_candidate.target_kind == :rich_text
    assert binding_candidate.value_kind == :field
    assert binding_candidate.scope == :current_entity
    assert binding_candidate.value_key == "commerce.product.full_description"
    assert binding_candidate.collection_binding_id == nil
    assert binding_candidate.normalization_status == :normalized
    assert %ValueModifier.None{} = binding_candidate.modifier

    translated_trace = binding_candidate.source_trace
    assert %SourceTrace{source_settings: %{}} = translated_trace
    assert translated_trace.source_id == "source-code-1"
    assert translated_trace.source_path == "components[0].elements[0]"
    assert translated_trace.source_type == "bricks_executable_source"
    assert translated_trace.adapter == "bricks"
    assert translated_trace.adapter_version == "1.2.3"
    assert translated_trace.source_name == nil
    assert translated_trace.source_classes == []

    assert translated_trace.metadata["execution_enabled"] == true
    assert translated_trace.metadata["recognizer_version"] == "php-semantic-v1"
    assert translated_trace.metadata["recognized_semantic"] == "commerce.product.full_description"
    assert translated_trace.metadata["translation_status"] == "normalized"

    fingerprint = translated_trace.metadata["source_fingerprint"]
    assert is_binary(fingerprint)
    assert String.match?(fingerprint, ~r/\A[0-9a-f]{64}\z/)
    assert fingerprint == :crypto.hash(:sha256, @source) |> Base.encode16(case: :lower)

    assert diagnostic.code == "bricks.executable_source.translated"

    assert diagnostic.message ==
             "Bricks executable source normalized as current entity full description"

    assert diagnostic.raw_value == nil
    assert diagnostic.metadata == %{}
    assert diagnostic.source_id == nil
    assert diagnostic.source_path == nil

    returned = inspect({binding_candidate, diagnostic})
    refute returned =~ @sentinel
    refute returned =~ @source
  end

  test "returns fixed unsupported diagnostics without source or trace" do
    candidate = %{
      element: %Element{id: "source-code-2", name: "code"},
      target_node_id: "node_000002",
      source_bytes: @source,
      execution_enabled: true,
      source_trace: %SourceTrace{
        source_id: "source-code-2",
        source_path: "components[0].elements[1]",
        source_settings: %{"code" => @source},
        metadata: %{"code" => @source}
      }
    }

    for {reason, code} <- [
          {:parse_failed, "bricks.executable_source.parse_failed"},
          {:unsafe, "bricks.executable_source.unsafe"},
          {:semantic_unsupported, "bricks.executable_source.semantic_unsupported"},
          {:semantic_ambiguous, "bricks.executable_source.semantic_ambiguous"},
          {:resource_limit_exceeded, "bricks.executable_source.resource_limit_exceeded"}
        ] do
      assert {:unsupported, %Diagnostic{} = diagnostic} =
               ExecutableSourceSemanticTranslator.translate(candidate, {:error, reason})

      assert diagnostic.code == code
      assert is_binary(diagnostic.message)
      assert diagnostic.raw_value == nil
      assert diagnostic.metadata == %{}
      assert diagnostic.source_id == nil
      assert diagnostic.source_path == nil
      refute Map.has_key?(diagnostic, :source_trace)
      refute inspect(diagnostic) =~ @sentinel
      refute inspect(diagnostic) =~ @source
    end
  end

  test "fails closed for disabled or non-code candidates" do
    disabled = %{
      element: %Element{id: "source-code-3", name: "code"},
      target_node_id: "node_000003",
      source_bytes: @source,
      execution_enabled: false,
      source_trace: %SourceTrace{source_id: "source-code-3", source_path: "elements[0]"}
    }

    assert {:unsupported, %Diagnostic{raw_value: nil}} =
             ExecutableSourceSemanticTranslator.translate(
               disabled,
               {:ok, :current_entity_full_description}
             )

    non_code = put_in(disabled, [:element, Access.key(:name)], "heading")

    assert {:unsupported, %Diagnostic{raw_value: nil}} =
             ExecutableSourceSemanticTranslator.translate(
               non_code,
               {:ok, :current_entity_full_description}
             )
  end
end
