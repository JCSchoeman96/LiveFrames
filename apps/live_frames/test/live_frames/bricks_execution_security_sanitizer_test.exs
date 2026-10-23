defmodule LiveFrames.BricksExecutionSecuritySanitizerTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks.Component
  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Document
  alias LiveFrames.Adapters.Bricks.Element
  alias LiveFrames.Adapters.Bricks.ExecutionSecuritySanitizer
  alias LiveFrames.Adapters.Bricks.Loader

  @code_body "synthetic-code-body-marker"
  @query_body "synthetic-query-editor-body-marker"
  @signature :binary.copy("s", 32)

  test "CODE_BODY_REMOVED_WITHOUT_SIGNATURE" do
    settings = %{"executeCode" => true, "code" => @code_body, "htmlTag" => "div"}
    document = document_with_element("code", settings)

    assert {:ok, sanitized} = ExecutionSecuritySanitizer.sanitize(document)
    sanitized_element = first_element(sanitized)

    refute Map.has_key?(sanitized_element.settings, "code")
    assert sanitized_element.settings["executeCode"]
    assert sanitized_element.settings["htmlTag"] == "div"
  end

  test "CODE_BODY_AND_VALID_SIGNATURE_REMOVED" do
    settings = %{
      "executeCode" => true,
      "code" => @code_body,
      "signature" => @signature,
      "htmlTag" => "div"
    }

    document = document_with_element("code", settings)

    assert {:ok, sanitized} = ExecutionSecuritySanitizer.sanitize(document)
    sanitized_settings = first_element(sanitized).settings

    refute Map.has_key?(sanitized_settings, "code")
    refute Map.has_key?(sanitized_settings, "signature")
    assert sanitized_settings == %{"executeCode" => true, "htmlTag" => "div"}
  end

  test "CODE_MALFORMED_SIGNATURE_FAILS_CLOSED" do
    private_signature = "synthetic-code-signature-marker"

    settings = %{
      "executeCode" => true,
      "code" => @code_body,
      "signature" => private_signature
    }

    document = document_with_element("code", settings)

    assert {:error, [%Diagnostic{} = diagnostic]} = ExecutionSecuritySanitizer.sanitize(document)
    assert diagnostic.code == "bricks.execution_security.unclassified_signature"
    refute inspect(diagnostic) =~ private_signature
    refute inspect(diagnostic) =~ @code_body
    assert first_element(document).settings == settings
  end

  test "NON_SECURITY_SIBLING_SETTINGS_PRESERVED" do
    settings = %{
      "executeCode" => true,
      "code" => @code_body,
      "htmlTag" => "section",
      "customValue" => %{"nested" => [1, "keep"]}
    }

    assert {:ok, sanitized} =
             document_with_element("code", settings)
             |> ExecutionSecuritySanitizer.sanitize()

    assert first_element(sanitized).settings == %{
             "executeCode" => true,
             "htmlTag" => "section",
             "customValue" => %{"nested" => [1, "keep"]}
           }
  end

  test "QUERY_BODY_REMOVED_WITHOUT_SIGNATURE" do
    settings = %{
      "query" => %{
        "useQueryEditor" => true,
        "queryEditor" => @query_body,
        "queryMode" => "custom"
      },
      "htmlTag" => "div"
    }

    assert {:ok, sanitized} =
             document_with_element("div", settings)
             |> ExecutionSecuritySanitizer.sanitize()

    assert first_element(sanitized).settings == %{
             "query" => %{"useQueryEditor" => true, "queryMode" => "custom"},
             "htmlTag" => "div"
           }
  end

  test "QUERY_BODY_AND_VALID_SIGNATURE_REMOVED" do
    settings = %{
      "query" => %{
        "useQueryEditor" => true,
        "queryEditor" => @query_body,
        "signature" => @signature,
        "queryMode" => "custom"
      }
    }

    assert {:ok, sanitized} =
             document_with_element("div", settings)
             |> ExecutionSecuritySanitizer.sanitize()

    assert first_element(sanitized).settings == %{
             "query" => %{"useQueryEditor" => true, "queryMode" => "custom"}
           }
  end

  test "QUERY_MALFORMED_SIGNATURE_FAILS_CLOSED" do
    private_signature = "synthetic-query-signature-marker!"
    assert byte_size(private_signature) != 32

    settings = %{
      "query" => %{
        "useQueryEditor" => true,
        "queryEditor" => @query_body,
        "signature" => private_signature
      }
    }

    document = document_with_element("div", settings)

    assert {:error, [%Diagnostic{} = diagnostic]} = ExecutionSecuritySanitizer.sanitize(document)
    assert diagnostic.code == "bricks.execution_security.unclassified_signature"
    refute inspect(diagnostic) =~ private_signature
    refute inspect(diagnostic) =~ @query_body
    assert first_element(document).settings == settings
  end

  test "RAW_ELEMENT_MIRROR_SANITIZED" do
    settings = %{"executeCode" => true, "code" => @code_body, "signature" => @signature}
    document = document_with_element("code", settings)

    assert {:ok, sanitized} = ExecutionSecuritySanitizer.sanitize(document)
    sanitized_raw_settings = first_element(sanitized).raw["settings"]

    refute Map.has_key?(sanitized_raw_settings, "code")
    refute Map.has_key?(sanitized_raw_settings, "signature")
  end

  test "RAW_COMPONENT_MIRROR_SANITIZED" do
    settings = %{"executeCode" => true, "code" => @code_body, "signature" => @signature}
    document = document_with_element("code", settings)

    assert {:ok, sanitized} = ExecutionSecuritySanitizer.sanitize(document)
    [raw_element] = sanitized.components["component-1"].raw["elements"]

    refute Map.has_key?(raw_element["settings"], "code")
    refute Map.has_key?(raw_element["settings"], "signature")
  end

  test "RAW_DOCUMENT_MIRROR_SANITIZED" do
    settings = %{"executeCode" => true, "code" => @code_body, "signature" => @signature}
    document = document_with_element("code", settings)

    assert {:ok, sanitized} = ExecutionSecuritySanitizer.sanitize(document)
    [raw_component] = sanitized.raw["components"]
    [raw_element] = raw_component["elements"]

    refute Map.has_key?(raw_element["settings"], "code")
    refute Map.has_key?(raw_element["settings"], "signature")
  end

  test "ORDINARY_NON_SECURITY_FIELDS_EXACTLY_PRESERVED" do
    settings = %{
      "executeCode" => true,
      "code" => @code_body,
      "signature" => @signature,
      "htmlTag" => "section",
      "customValue" => %{"nested" => [1, "keep"]}
    }

    document = document_with_element("code", settings)
    expected_settings = Map.drop(settings, ["code", "signature"])

    expected_element_raw =
      Map.put(first_element(document).raw, "settings", expected_settings)

    expected_component_raw =
      Map.put(document.components["component-1"].raw, "elements", [expected_element_raw])

    expected_document_raw = Map.put(document.raw, "components", [expected_component_raw])

    assert {:ok, sanitized} = ExecutionSecuritySanitizer.sanitize(document)
    assert first_element(sanitized).raw == expected_element_raw
    assert sanitized.components["component-1"].raw == expected_component_raw
    assert sanitized.raw == expected_document_raw
  end

  test "PRIVATE_INPUT_UNCHANGED" do
    settings = %{"executeCode" => true, "code" => @code_body, "signature" => @signature}
    document = document_with_element("code", settings)
    before = document

    assert {:ok, _sanitized} = ExecutionSecuritySanitizer.sanitize(document)
    assert document == before
  end

  test "SOURCE_HASH_UNCHANGED" do
    settings = %{"executeCode" => true, "code" => @code_body, "signature" => @signature}
    document = document_with_element("code", settings)

    assert {:ok, sanitized} = ExecutionSecuritySanitizer.sanitize(document)
    assert sanitized.source_hash == document.source_hash
  end

  test "LOADER_SOURCE_HASH_UNCHANGED" do
    source = %{
      "source" => "bricksCopiedElements",
      "sourceUrl" => "https://example.invalid",
      "version" => "2.3.1",
      "content" => [],
      "components" => [
        %{
          "id" => "component-1",
          "elements" => [
            %{
              "id" => "element-1",
              "name" => "code",
              "settings" => %{
                "executeCode" => true,
                "code" => @code_body,
                "signature" => @signature
              }
            }
          ]
        }
      ],
      "globalClasses" => []
    }

    source_bytes = Jason.encode!(source)
    assert {:ok, private_document, []} = Loader.from_json(source_bytes)
    assert {:ok, sanitized} = ExecutionSecuritySanitizer.sanitize(private_document)
    assert sanitized.source_hash == private_document.source_hash
  end

  test "UNKNOWN_SIGNATURE_CONTEXT_FAILS_CLOSED" do
    private_signature = "synthetic-unknown-signature-marker"

    cases = [
      {"div", %{"signature" => private_signature}},
      {"code", %{"executeCode" => true, "signature" => private_signature}},
      {"div", %{"query" => %{"useQueryEditor" => true, "signature" => private_signature}}}
    ]

    Enum.each(cases, fn {name, settings} ->
      document = document_with_element(name, settings)
      before = document

      assert {:error, [%Diagnostic{} = diagnostic]} =
               ExecutionSecuritySanitizer.sanitize(document)

      assert diagnostic.code == "bricks.execution_security.unclassified_signature"
      assert diagnostic.raw_value == nil
      assert diagnostic.source_id == nil
      assert diagnostic.source_path == nil
      assert diagnostic.metadata == %{}
      refute inspect(diagnostic) =~ private_signature
      refute inspect(diagnostic) =~ @code_body
      refute inspect(diagnostic) =~ @query_body
      assert document == before
      assert first_element(document).settings == settings
      assert inspect(first_element(document).raw["settings"]) =~ private_signature
    end)

    raw_only_document =
      document_with_element("div", %{"htmlTag" => "div"})
      |> add_raw_only_signature(private_signature)

    before = raw_only_document

    assert {:error, [%Diagnostic{} = diagnostic]} =
             ExecutionSecuritySanitizer.sanitize(raw_only_document)

    assert diagnostic.code == "bricks.execution_security.unclassified_signature"
    refute inspect(diagnostic) =~ private_signature
    assert raw_only_document == before
    refute Map.has_key?(first_element(raw_only_document).settings, "signature")
    assert first_element(raw_only_document).raw["settings"]["signature"] == private_signature
  end

  test "DETERMINISTIC_SANITIZED_OUTPUT" do
    settings = %{
      "executeCode" => true,
      "code" => @code_body,
      "signature" => @signature,
      "safe" => %{"values" => [1, "same"]}
    }

    document = document_with_element("code", settings)

    assert {:ok, first} = ExecutionSecuritySanitizer.sanitize(document)
    assert {:ok, second} = ExecutionSecuritySanitizer.sanitize(document)
    assert first == second
  end

  defp document_with_element(name, settings) do
    element_raw = %{
      "id" => "element-1",
      "name" => name,
      "settings" => settings,
      "element_only_sentinel" => %{"exact" => ["keep", 1]}
    }

    element = %Element{
      id: "element-1",
      name: name,
      settings: settings,
      raw: element_raw
    }

    component_raw = %{
      "id" => "component-1",
      "elements" => [element_raw],
      "component_only_sentinel" => %{"exact" => ["keep", 2]}
    }

    component = %Component{
      id: "component-1",
      elements: [element],
      raw: component_raw
    }

    %Document{
      source_hash: "synthetic-original-source-hash",
      component_order: ["component-1"],
      components: %{"component-1" => component},
      raw: %{
        "components" => [component_raw],
        "document_only_sentinel" => %{"exact" => ["keep", 3]}
      }
    }
  end

  defp first_element(%Document{components: components}) do
    components["component-1"].elements |> hd()
  end

  defp add_raw_only_signature(document, signature) do
    component = document.components["component-1"]
    [element] = component.elements
    raw_settings = Map.put(element.raw["settings"], "signature", signature)
    raw_element = Map.put(element.raw, "settings", raw_settings)
    element = %{element | raw: raw_element}
    raw_component = Map.put(component.raw, "elements", [raw_element])
    component = %{component | elements: [element], raw: raw_component}
    raw_document = Map.put(document.raw, "components", [raw_component])

    %{
      document
      | components: Map.put(document.components, "component-1", component),
        raw: raw_document
    }
  end
end
