defmodule LiveFrames.BricksStageATest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Adapters.Bricks.ClassResolver
  alias LiveFrames.Adapters.Bricks.DependencyExtractor
  alias LiveFrames.Adapters.Bricks.ExecutionSecuritySanitizer
  alias LiveFrames.Adapters.Bricks.Loader
  alias LiveFrames.Adapters.Bricks.Settings
  alias LiveFrames.Adapters.Bricks.StageA.CSSRenderer
  alias LiveFrames.Adapters.Bricks.StageA.HTMLRenderer
  alias LiveFrames.Adapters.Bricks.StageA
  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Tokens.AuthorityGate
  alias LiveFrames.Tokens.Diagnostic, as: TokenDiagnostic
  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet

  defp fixture_path do
    Path.expand("../../../../fixtures/bricks/bricks_components.json", __DIR__)
  end

  defp token_set do
    {:ok, token_set, _diagnostics} =
      AutomaticCSS.from_file(
        Path.expand("../../../../fixtures/automatic_css/acss_settings.json", __DIR__),
        source_version: "4.0.1",
        source_version_status: "fixture_reference",
        strict: true,
        profile: :hero_foundation
      )

    token_set
  end

  defp token_diagnostic(severity) do
    TokenDiagnostic.new(
      code: "test.processing.#{severity}",
      severity: severity,
      category: :source,
      message: "Synthetic processing diagnostic",
      path: "spacing.content_gap",
      source_key: "content-gap",
      metadata: %{"source" => "fixture"}
    )
  end

  defp token_set_with_diagnostic(severity) do
    token_set = token_set()
    %{token_set | diagnostics: [token_diagnostic(severity)]}
  end

  defp fragment_source do
    %{
      "components" => [
        %{
          "id" => "component-a",
          "elements" => [
            %{
              "id" => "root",
              "name" => "div",
              "parent" => 0,
              "settings" => %{"_cssGlobalClasses" => ["opaque-class-id"]}
            }
          ]
        }
      ],
      "globalClasses" => []
    }
  end

  defp copied_elements_source do
    fragment_source()
    |> Map.merge(%{
      "source" => "bricksCopiedElements",
      "sourceUrl" => "https://example.test/export.json",
      "version" => "2.3.1",
      "content" => [%{"id" => "proxy-a", "cid" => "component-a", "label" => "Synthetic"}]
    })
  end

  defp source_with_element(name, settings) do
    source_with_elements([
      %{"id" => "root", "name" => name, "parent" => 0, "children" => [], "settings" => settings}
    ])
  end

  defp source_with_elements(elements) do
    copied_elements_source()
    |> put_in(["components", Access.at(0), "elements"], elements)
  end

  defp synthetic_signature(marker), do: String.pad_trailing(marker, 32, "s")

  defp assert_markers_absent(term, markers) do
    Enum.each(markers, fn marker ->
      refute marker_count(term, marker) > 0, "found private marker #{inspect(marker)}"
    end)
  end

  defp assert_markers_present(term, markers) do
    Enum.each(markers, fn marker ->
      assert marker_count(term, marker) > 0, "expected private marker #{inspect(marker)}"
    end)
  end

  defp private_marker_values(markers) do
    Enum.flat_map(markers, fn marker ->
      fragment = binary_part(marker, 0, min(byte_size(marker), 12))
      digest = :crypto.hash(:sha256, marker) |> Base.encode16(case: :lower)
      [marker, fragment, digest]
    end)
    |> Enum.uniq()
  end

  defp contains_any_key?(%_{} = struct, keys),
    do: struct |> Map.from_struct() |> contains_any_key?(keys)

  defp contains_any_key?(map, keys) when is_map(map) do
    Enum.any?(map, fn {key, value} -> key in keys or contains_any_key?(value, keys) end)
  end

  defp contains_any_key?(list, keys) when is_list(list),
    do: Enum.any?(list, &contains_any_key?(&1, keys))

  defp contains_any_key?(tuple, keys) when is_tuple(tuple),
    do: tuple |> Tuple.to_list() |> contains_any_key?(keys)

  defp contains_any_key?(_term, _keys), do: false

  defp marker_count(term, marker) when is_binary(term),
    do: length(:binary.matches(term, marker))

  defp marker_count(%_{} = struct, marker),
    do: struct |> Map.from_struct() |> marker_count(marker)

  defp marker_count(term, marker) when is_map(term) do
    Enum.reduce(term, 0, fn {key, value}, count ->
      count + marker_count(key, marker) + marker_count(value, marker)
    end)
  end

  defp marker_count(term, marker) when is_list(term),
    do: Enum.reduce(term, 0, &(marker_count(&1, marker) + &2))

  defp marker_count(term, marker) when is_tuple(term),
    do: term |> Tuple.to_list() |> marker_count(marker)

  defp marker_count(_term, _marker), do: 0

  defp diagnostic_field_hits(diagnostics, field, marker) do
    Enum.reduce(diagnostics, 0, fn diagnostic, count ->
      count + marker_count(Map.get(diagnostic, field), marker)
    end)
  end

  defp external_class_authority do
    %{
      id: "synthetic-site-classes",
      global_classes: [
        %{"id" => "opaque-class-id", "name" => "synthetic-class", "settings" => %{}}
      ]
    }
  end

  test "characterizes marker retention in pre-sanitization Loader errors" do
    body_marker = "TASK0_SYNTHETIC_BODY_MARKER_6f7c31"
    signature_marker = "TASK0_SYNTHETIC_SIGNATURE_MARKER_a2048d"

    source =
      copied_elements_source()
      |> put_in(
        ["components", Access.at(0), "elements", Access.at(0), "settings"],
        [body_marker, signature_marker]
      )

    result = StageA.generate(source, component_id: "component-a")

    assert if(match?({:error, _}, result), do: 1, else: 0) == 1
    {:error, diagnostics} = result

    observed_counts = %{
      result_body: marker_count(result, body_marker),
      result_signature: marker_count(result, signature_marker),
      raw_value_body: diagnostic_field_hits(diagnostics, :raw_value, body_marker),
      raw_value_signature: diagnostic_field_hits(diagnostics, :raw_value, signature_marker),
      metadata_body: diagnostic_field_hits(diagnostics, :metadata, body_marker),
      metadata_signature: diagnostic_field_hits(diagnostics, :metadata, signature_marker),
      message_body: diagnostic_field_hits(diagnostics, :message, body_marker),
      message_signature: diagnostic_field_hits(diagnostics, :message, signature_marker),
      source_path_body: diagnostic_field_hits(diagnostics, :source_path, body_marker),
      source_path_signature: diagnostic_field_hits(diagnostics, :source_path, signature_marker)
    }

    assert observed_counts == %{
             result_body: 0,
             result_signature: 0,
             raw_value_body: 0,
             raw_value_signature: 0,
             metadata_body: 0,
             metadata_signature: 0,
             message_body: 0,
             message_signature: 0,
             source_path_body: 0,
             source_path_signature: 0
           }
  end

  test "sanitizes admitted Code execution data before Stage A consumers" do
    code_body = "TASK3_CODE_BODY_MARKER_6db2a1"
    signature = synthetic_signature("TASK3_CODE_SIGNATURE_MARKER_19c3")
    assert byte_size(signature) == 32

    source =
      source_with_element("code", %{
        "executeCode" => true,
        "code" => code_body,
        "signature" => signature
      })

    assert {:ok, result} = StageA.generate(source, component_id: "component-a")

    markers = private_marker_values([code_body, signature])

    for surface <- [
          result.document,
          result.proxy,
          result.component,
          result.tree,
          result.dependencies,
          result.diagnostics,
          result.report,
          result.artifacts,
          result.artifacts["index.html"],
          result.artifacts["styles.css"],
          result.artifacts["report.json"],
          result.report["settings"]["unsupported"],
          result.report["runtime_dependencies"],
          result.report["diagnostics"],
          result.report["source_trace"],
          result.report["unsupported_elements"],
          result.dependencies.unsupported_settings,
          result.dependencies.runtime_dependencies,
          result.dependencies.diagnostics
        ] do
      assert_markers_absent(surface, markers)
    end

    assert result.status == :completed
    assert Enum.any?(result.report["unsupported_elements"], &(&1["type"] == "code"))
    unsupported_code = Enum.find(result.report["unsupported_elements"], &(&1["type"] == "code"))
    assert marker_count(unsupported_code, code_body) == 0
    assert marker_count(unsupported_code, signature) == 0
  end

  test "sanitizes Query Editor data from the JSON entry point without derivatives" do
    query_body = "TASK3_QUERY_EDITOR_BODY_MARKER_e919 SELECT * FROM synthetic_posts"
    signature = synthetic_signature("TASK3_QUERY_SIG_MARKER_ab12")
    assert byte_size(signature) == 32

    source =
      source_with_element("div", %{
        "query" => %{
          "useQueryEditor" => true,
          "queryEditor" => query_body,
          "signature" => signature
        }
      })

    assert {:ok, result} = StageA.generate(Jason.encode!(source), component_id: "component-a")

    markers = private_marker_values([query_body, signature])

    for surface <- [
          result.document,
          result.proxy,
          result.component,
          result.tree,
          result.dependencies,
          result.diagnostics,
          result.report,
          result.artifacts,
          result.artifacts["index.html"],
          result.artifacts["styles.css"],
          result.artifacts["report.json"],
          result.report["settings"]["unsupported"],
          result.report["runtime_dependencies"],
          result.report["diagnostics"],
          result.report["source_trace"],
          result.report["unsupported_elements"],
          result.dependencies.unsupported_settings,
          result.dependencies.runtime_dependencies,
          result.dependencies.diagnostics
        ] do
      assert_markers_absent(surface, markers)
    end
  end

  test "sanitizes a Loader Document and preserves its source identity" do
    code_body = "TASK3_IDENTITY_CODE_BODY_511d"
    signature = synthetic_signature("TASK3_IDENTITY_SIG_663e")
    query_body = "TASK3_IDENTITY_QUERY_BODY_a7c0 SELECT id FROM private_posts"
    query_signature = synthetic_signature("TASK3_IDENTITY_QUERY_SIG_10ef")

    source =
      source_with_elements([
        %{
          "id" => "code-root",
          "name" => "code",
          "parent" => 0,
          "children" => [],
          "settings" => %{"executeCode" => true, "code" => code_body, "signature" => signature}
        },
        %{
          "id" => "query-root",
          "name" => "div",
          "parent" => 0,
          "children" => [],
          "settings" => %{
            "query" => %{
              "useQueryEditor" => true,
              "queryEditor" => query_body,
              "signature" => query_signature
            }
          }
        }
      ])

    source_bytes = Jason.encode!(source)
    private_values = [code_body, signature, query_body, query_signature]
    markers = private_marker_values(private_values)

    assert {:ok, private_document, _loader_diagnostics} = Loader.from_json(source_bytes)
    private_document_before = private_document
    source_hash = private_document.source_hash

    assert source_hash == Base.encode16(:crypto.hash(:sha256, source_bytes), case: :lower)
    assert_markers_present(private_document, private_values)

    assert {:ok, result} =
             StageA.generate(private_document,
               component_id: "component-a",
               expected_root_count: 2
             )

    assert result.document.source_hash == source_hash
    assert result.report["source"]["sha256"] == source_hash
    assert result == generate_from_sanitized_document(private_document)
    assert_markers_absent(result, markers)
    assert private_document == private_document_before
    assert_markers_present(private_document, private_values)
  end

  defp generate_from_sanitized_document(private_document) do
    assert {:ok, sanitized_document} = ExecutionSecuritySanitizer.sanitize(private_document)

    assert {:ok, result} =
             StageA.generate(sanitized_document,
               component_id: "component-a",
               expected_root_count: 2
             )

    result
  end

  test "keeps blocking Stage A diagnostics clear of admitted execution data" do
    code_body = "TASK3_BLOCKED_CODE_BODY_73f9"
    signature = synthetic_signature("TASK3_BLOCKED_SIG_ee13")
    query_body = "TASK3_BLOCKED_QUERY_BODY_912c SELECT id FROM blocked_posts"
    query_signature = synthetic_signature("TASK3_BLOCKED_QUERY_SIG_81a0")

    source =
      source_with_elements([
        %{
          "id" => "code-root",
          "name" => "code",
          "parent" => 0,
          "children" => [],
          "settings" => %{"executeCode" => true, "code" => code_body, "signature" => signature}
        },
        %{
          "id" => "query-root",
          "name" => "div",
          "parent" => 0,
          "children" => [],
          "settings" => %{
            "query" => %{
              "useQueryEditor" => true,
              "queryEditor" => query_body,
              "signature" => query_signature
            }
          }
        }
      ])

    assert {:error, diagnostics} =
             StageA.generate(source, component_id: "component-a", expected_root_count: 1)

    assert Enum.any?(diagnostics, &(&1.code == "bricks.tree.root_count"))

    assert_markers_absent(
      diagnostics,
      private_marker_values([code_body, signature, query_body, query_signature])
    )

    refute contains_any_key?(diagnostics, [
             :signature,
             "signature",
             :signature_present,
             "signature_present",
             :signature_hash,
             "signature_hash",
             :signature_fragment,
             "signature_fragment",
             :has_signature,
             "has_signature"
           ])
  end

  test "rejects an unknown signature context before creating artifacts" do
    signature = synthetic_signature("TASK3_UNKNOWN_SIG_5c21")
    source = source_with_element("div", %{"signature" => signature})

    output_dir =
      Path.join(
        System.tmp_dir!(),
        "stage-a-unknown-signature-#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf(output_dir) end)

    assert {:error, diagnostics} =
             StageA.generate(source,
               component_id: "component-a",
               output_dir: output_dir
             )

    assert Enum.any?(
             diagnostics,
             &(&1.code == "bricks.execution_security.unclassified_signature")
           )

    assert_markers_absent(diagnostics, private_marker_values([signature]))
    refute File.exists?(output_dir)
  end

  test "writes only sanitized artifacts after loading a source file" do
    code_body = "TASK3_FILE_CODE_BODY_0a82"
    signature = synthetic_signature("TASK3_FILE_SIG_9d40")

    source =
      source_with_element("code", %{
        "executeCode" => true,
        "code" => code_body,
        "signature" => signature
      })

    temporary_root =
      Path.join(System.tmp_dir!(), "stage-a-private-source-#{System.unique_integer([:positive])}")

    input_path = Path.join(temporary_root, "source.json")
    output_dir = Path.join(temporary_root, "artifacts")
    File.mkdir_p!(temporary_root)
    File.write!(input_path, Jason.encode!(source))
    on_exit(fn -> File.rm_rf(temporary_root) end)

    assert {:ok, result} =
             StageA.generate_from_file(input_path,
               component_id: "component-a",
               output_dir: output_dir
             )

    for artifact_name <- ["index.html", "styles.css", "report.json"] do
      artifact_path = Path.join(output_dir, artifact_name)
      assert File.regular?(artifact_path)

      assert_markers_absent(
        File.read!(artifact_path),
        private_marker_values([code_body, signature])
      )

      assert result.artifact_paths[artifact_name] == artifact_path
    end
  end

  test "Stage A accepts informational and warning TokenSet diagnostics" do
    for severity <- [:info, :warning] do
      assert {:ok, result} =
               StageA.generate(copied_elements_source(),
                 component_id: "component-a",
                 token_set: token_set_with_diagnostic(severity)
               )

      assert result.status == :completed
    end
  end

  test "Stage A rejects error TokenSet diagnostics before writing artifacts" do
    diagnostic = token_diagnostic(:error)

    output_dir =
      Path.join(
        System.tmp_dir!(),
        "stage-a-authority-error-#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf(output_dir) end)

    assert {:error, [^diagnostic]} =
             StageA.generate(copied_elements_source(),
               component_id: "component-a",
               token_set: token_set_with_diagnostic(:error),
               output_dir: output_dir
             )

    refute File.exists?(output_dir)
  end

  test "Stage A rejects fatal TokenSet diagnostics before writing artifacts" do
    diagnostic = token_diagnostic(:fatal)

    output_dir =
      Path.join(
        System.tmp_dir!(),
        "stage-a-authority-fatal-#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf(output_dir) end)

    assert {:error, [^diagnostic]} =
             StageA.generate(copied_elements_source(),
               component_id: "component-a",
               token_set: token_set_with_diagnostic(:fatal),
               output_dir: output_dir
             )

    refute File.exists?(output_dir)
  end

  test "rejects component fragments at the Stage A source boundary" do
    assert {:error, [diagnostic]} =
             StageA.generate(fragment_source(), component_id: "component-a")

    assert diagnostic.code == "bricks.source.fragment_stage_a_unsupported"
    assert diagnostic.severity == :error
    refute diagnostic.code == "bricks.stage_a.failed"
  end

  test "generates Stage A artifacts and external class provenance from a copied-elements source" do
    assert {:ok, result} =
             StageA.generate(copied_elements_source(),
               component_id: "component-a",
               external_class_authorities: [external_class_authority()]
             )

    assert result.status == :completed
    assert result.artifacts["index.html"] =~ "synthetic-class"
    refute result.artifacts["index.html"] =~ "opaque-class-id"
    refute result.artifacts["index.html"] =~ "bricks-source-class"

    assert [class_dependency] = result.report["classes"]["applied"]
    assert class_dependency["class_id"] == "opaque-class-id"
    assert class_dependency["name"] == "synthetic-class"
    assert class_dependency["resolution_status"] == "external_resolved"
    assert class_dependency["authority_ids"] == ["synthetic-site-classes"]
    assert Jason.decode!(result.artifacts["report.json"]) == result.report
  end

  test "keeps the harmless raw value on an unrelated copied-elements envelope error" do
    source_marker = "synthetic-unrecognized-source-marker"
    source = Map.put(copied_elements_source(), "source", source_marker)

    assert {:error, [diagnostic]} = StageA.generate(source, component_id: "component-a")
    assert diagnostic.code == "bricks.source.invalid"
    assert diagnostic.raw_value == source_marker
  end

  test "treats empty-list settings as equivalent to empty-object settings" do
    source_with_settings = fn settings ->
      copied_elements_source()
      |> put_in(["components", Access.at(0), "elements", Access.at(0), "settings"], settings)
    end

    assert {:ok, empty_list_result} =
             StageA.generate(source_with_settings.([]), component_id: "component-a")

    assert {:ok, empty_object_result} =
             StageA.generate(source_with_settings.(%{}), component_id: "component-a")

    assert empty_list_result.status == :completed
    assert empty_object_result.status == :completed

    assert hd(empty_list_result.document.components["component-a"].elements).settings == %{}
    assert hd(empty_object_result.document.components["component-a"].elements).settings == %{}

    assert empty_list_result.artifacts["index.html"] ==
             empty_object_result.artifacts["index.html"]

    assert empty_list_result.artifacts["styles.css"] ==
             empty_object_result.artifacts["styles.css"]
  end

  test "rejects a structurally invalid supplied TokenSet deterministically" do
    invalid_token_set = %TokenSet{tokens: :invalid}

    assert {:error, diagnostics} =
             StageA.generate(copied_elements_source(), token_set: invalid_token_set)

    assert {:error, ^diagnostics} =
             StageA.generate(copied_elements_source(), token_set: invalid_token_set)
  end

  test "resolves applied global classes and ACSS names" do
    {:ok, source, _} = Bricks.from_file(fixture_path())
    {:ok, _proxy, component, _} = Bricks.resolve(source, component_id: "sqhmmc")
    {:ok, tree, _} = Bricks.build_tree(component)
    assert {:ok, resolved, diagnostics} = ClassResolver.resolve(tree, source)
    assert resolved.elements["sqhmmc"].class_names == ["fr-hero-india", "bg--ultra-dark"]
    assert diagnostics == []
  end

  test "maps representative settings and preserves raw expressions" do
    result =
      Settings.extract(%{
        "_position" => "absolute",
        "_rowGap" => "var(--content-gap)",
        "_widthMax" => "70ch",
        "_objectPosition:tablet_portrait" => "50% 50%",
        "_cssCustom" => ".source img { height: 100%; }"
      })

    assert result.base_styles["position"] == "absolute"
    assert result.base_styles["row-gap"] == "var(--content-gap)"
    assert result.base_styles["max-width"] == "70ch"
    assert hd(result.responsive).breakpoint == "tablet_portrait"
    assert result.custom_css.base == [".source img { height: 100%; }"]
  end

  test "keeps C-03 semantic settings outside the shared Stage A settings allowlist" do
    result =
      Settings.extract(%{
        "_attributes" => [],
        "ariaLabel" => "Synthetic label",
        "customTag" => "details"
      })

    assert Enum.map(result.unsupported, & &1.source_key) == [
             "_attributes",
             "ariaLabel",
             "customTag"
           ]
  end

  test "applies Bricks spacing defaultUnit px for bare nonzero margin" do
    # Authority: Bricks 2.3.1 includes/assets.php spacing/dimensions controls
    # append defaultUnit px when the number is numeric and nonzero without a unit.
    result = Settings.extract(%{"_margin" => %{"top" => "400"}})
    assert result.base_styles["margin-top"] == "400px"
    refute Map.has_key?(result.unresolved_values, "_margin.top")
  end

  test "preserves unsupported settings and runtime dependencies as diagnostics" do
    settings =
      Settings.extract(%{"_futureSetting" => "preserve", "_cssCustom" => ".x { color: red; }"})

    assert hd(settings.unsupported).source_key == "_futureSetting"
    assert Enum.any?(settings.diagnostics, &(&1.code == "bricks.setting.unsupported"))

    element = %LiveFrames.Adapters.Bricks.Element{
      id: "root",
      name: "div",
      parent: 0,
      settings: %{"_interaction" => %{"event" => "click"}}
    }

    tree = %LiveFrames.Adapters.Bricks.Tree{
      elements: %{"root" => element},
      ordered_elements: [element],
      root_ids: ["root"],
      children_by_id: %{"root" => []},
      parent_by_id: %{"root" => 0},
      source_order: ["root"]
    }

    resolved = %{
      tree: tree,
      elements: %{
        "root" => %{
          element: element,
          class_ids: [],
          class_names: [],
          class_refs: [],
          settings: element.settings,
          source_settings: element.settings,
          semantic_classes: []
        }
      }
    }

    dependencies = DependencyExtractor.extract(resolved, %LiveFrames.Adapters.Bricks.Document{})
    assert [%{kind: :interaction, status: :unsupported}] = dependencies.runtime_dependencies
    assert Enum.any?(dependencies.diagnostics, &(&1.code == "bricks.runtime.unsupported"))
  end

  test "uses VariableAuthority for resolved aliases and ambiguous source references" do
    result =
      DependencyExtractor.variables(
        [
          "var(--content-gap)",
          "var(--content-width)",
          "var(--container-gap)",
          "var(--space-m)",
          "var(--section-space-m)",
          "var(--radius)",
          "var(--primary)",
          "var(--white)",
          "var(--unknown)"
        ],
        token_set: token_set()
      )

    assert %{status: :resolved_token, token_path: "spacing.content_gap"} =
             Enum.find(result, &(&1.name == "--content-gap"))

    assert %{status: :resolved_token, token_path: "layout.viewport.max"} =
             Enum.find(result, &(&1.name == "--content-width"))

    assert %{status: :resolved_token, token_path: "spacing.container_gap"} =
             Enum.find(result, &(&1.name == "--container-gap"))

    assert %{
             status: :ambiguous_token,
             candidate_paths: ["spacing.content_gap", "spacing.grid_gap", "spacing.scale.medium"]
           } =
             Enum.find(result, &(&1.name == "--space-m"))

    assert %{
             status: :ambiguous_token,
             candidate_paths: ["spacing.section", "spacing.section.padding_block"]
           } =
             Enum.find(result, &(&1.name == "--section-space-m"))

    assert %{status: :ambiguous_token} = Enum.find(result, &(&1.name == "--radius"))
    assert %{status: :ambiguous_token} = Enum.find(result, &(&1.name == "--primary"))
    assert %{status: :ambiguous_token} = Enum.find(result, &(&1.name == "--white"))

    assert %{
             status: :source_variable,
             token_path: nil,
             resolution_reason: "mapping_unproven"
           } = Enum.find(result, &(&1.name == "--unknown"))

    assert Enum.find(result, &(&1.name == "--section-space-m")).authority_evidence == [
             %{
               token_path: "spacing.section",
               resolution_status: :resolved,
               authorities: [
                 %{
                   "authority_id" =>
                     "automatic-css-4.0.1:calculated-variable-group:section-spacing:section-space-m",
                   "kind" => "source_output_alias",
                   "source_key" => nil,
                   "source_version" => "4.0.1",
                   "variable" => "--section-space-m"
                 }
               ]
             },
             %{
               token_path: "spacing.section.padding_block",
               resolution_status: :resolved,
               authorities: [
                 %{
                   "authority_id" =>
                     "automatic-css-4.0.1:validated-reference:section-padding-block:--section-space-m",
                   "kind" => "source_reference",
                   "source_key" => "section-padding-block",
                   "source_version" => "4.0.1",
                   "variable" => "--section-space-m"
                 }
               ]
             }
           ]
  end

  test "direct variable extraction gates processing diagnostics by severity" do
    for severity <- [:info, :warning] do
      assert [%{status: :resolved_token, token_path: "spacing.content_gap"}] =
               DependencyExtractor.variables(["var(--content-gap)"],
                 token_set: token_set_with_diagnostic(severity)
               )
    end

    for severity <- [:error, :fatal] do
      assert_raise ArgumentError,
                   "Bricks TokenSet variable authority could not be authorized",
                   fn ->
                     DependencyExtractor.variables(["var(--content-gap)"],
                       token_set: token_set_with_diagnostic(severity)
                     )
                   end
    end
  end

  test "direct variable extraction trusts a supplied authority index without rescanning TokenSet" do
    trusted_token_set = token_set()
    assert {:ok, trusted_index} = AuthorityGate.authorize(trusted_token_set)
    blocked_token_set = %{trusted_token_set | diagnostics: [token_diagnostic(:error)]}

    assert [%{status: :resolved_token, token_path: "spacing.content_gap"}] =
             DependencyExtractor.variables(["var(--content-gap)"],
               authority_index: trusted_index,
               token_set: blocked_token_set
             )
  end

  test "an authority candidate only resolves when its owning token is resolved" do
    authority = %{
      "variable" => "--gap",
      "kind" => "source_reference",
      "authority_id" => "synthetic:gap",
      "source_key" => "gap",
      "source_version" => "4.0.1"
    }

    token = %Token{
      path: "spacing.gap",
      category: :spacing,
      source_expression: "var(--gap)",
      resolution_status: :unresolved,
      metadata: %{"variable_authorities" => [authority]}
    }

    token_set = TokenSet.new(tokens: %{"spacing.gap" => token})

    assert [
             %{
               name: "--gap",
               status: :unresolved_token,
               token_path: "spacing.gap",
               token_status: :unresolved,
               resolution_reason: "token_unresolved",
               authority_state: :unique_candidate
             }
           ] = DependencyExtractor.variables(["var(--gap)"], token_set: token_set)
  end

  test "variable extraction without structural authority leaves --grid-1 as a source variable" do
    [variable] = DependencyExtractor.variables(["var(--grid-1)"], token_set: token_set())

    assert variable.status == :source_variable
    assert variable.resolution_reason == "mapping_unproven"
  end

  test "known external variables remain non-token authorities unless B1 authorizes one" do
    external =
      DependencyExtractor.variables(["var(--overlay-bg)"], token_set: token_set())
      |> hd()

    assert external.status == :unresolved_external
    assert external.token_path == nil
    assert external.resolution_reason == "external_unresolved"

    authority = %{
      "variable" => "--overlay-bg",
      "kind" => "source_output_alias",
      "authority_id" => "synthetic:overlay-bg",
      "source_key" => "overlay-bg",
      "source_version" => "4.0.1"
    }

    token = %Token{
      path: "color.overlay",
      category: :color,
      value: "#000000",
      resolved_value: "#000000",
      source_expression: "#000000",
      resolution_status: :resolved,
      metadata: %{"variable_authorities" => [authority]}
    }

    authorized_external =
      DependencyExtractor.variables(
        ["var(--overlay-bg)"],
        token_set: TokenSet.new(tokens: %{"color.overlay" => token})
      )
      |> hd()

    assert authorized_external.status == :resolved_token
    assert authorized_external.token_path == "color.overlay"
  end

  test "preserves unresolved nested variables" do
    values = ["var(--overlay-bg, var(--neutral-ultra-dark-trans-60))"]
    result = DependencyExtractor.variables(values)

    assert Enum.any?(result, &(&1.name == "--overlay-bg" and &1.status == :unresolved_external))

    assert Enum.any?(
             result,
             &(&1.name == "--neutral-ultra-dark-trans-60" and &1.status == :unresolved_external)
           )
  end

  test "keeps one variable diagnostic while retaining repeated source occurrences" do
    source =
      copied_elements_source()
      |> put_in(
        [
          "components",
          Access.filter(&(&1["id"] == "component-a")),
          "elements",
          Access.at(0),
          "settings"
        ],
        %{"_width" => "var(--unknown)", "_widthMax" => "var(--unknown)"}
      )

    assert {:ok, result} =
             StageA.generate(source,
               component_id: "component-a",
               external_class_authorities: [external_class_authority()]
             )

    assert [dependency] = result.report["variables"]["dependencies"]
    assert dependency["name"] == "--unknown"
    assert dependency["status"] == "source_variable"
    assert dependency["token_path"] == nil
    assert length(dependency["occurrences"]) == 2
    assert dependency["expressions"] == ["var(--unknown)"]

    assert [diagnostic] =
             Enum.filter(result.report["diagnostics"]["items"], fn diagnostic ->
               diagnostic["code"] == "bricks.variable.unresolved"
             end)

    assert diagnostic["metadata"]["resolution_reason"] == "mapping_unproven"
  end

  test "reports unresolved attachment data" do
    [asset] =
      DependencyExtractor.assets([
        %{
          "id" => 880,
          "filename" => "cordallman-man-8493246_1920.webp",
          "url" => false
        }
      ])

    assert asset.attachment_id == 880
    assert asset.status == :unresolved
    assert asset.url == false
  end

  test "renders all supported Hero element semantics and source classes" do
    {:ok, source, _} = Bricks.from_file(fixture_path())
    {:ok, _proxy, component, _} = Bricks.resolve(source, component_id: "sqhmmc")
    {:ok, tree, _} = Bricks.build_tree(component)
    {:ok, resolved, _} = ClassResolver.resolve(tree, source)

    html = HTMLRenderer.render(resolved)

    assert html =~ "<section"
    assert html =~ "<h1"
    assert html =~ "<p"
    assert html =~ "<button type=\"button\""
    assert html =~ "fr-hero-india"
    assert html =~ "bg--ultra-dark"
    assert html =~ "btn--primary"
    assert html =~ "btn--outline"
    assert html =~ "about:blank"
  end

  test "renders mapped base CSS and preserves named responsive source entries" do
    {:ok, source, _} = Bricks.from_file(fixture_path())
    {:ok, _proxy, component, _} = Bricks.resolve(source, component_id: "sqhmmc")
    {:ok, tree, _} = Bricks.build_tree(component)
    {:ok, resolved, _} = ClassResolver.resolve(tree, source)

    dependencies = DependencyExtractor.extract(resolved, source)
    css = CSSRenderer.render(resolved, dependencies.style_results)

    assert css =~ "position: relative;"
    assert css =~ "row-gap: var(--content-gap);"
    assert css =~ "linear-gradient(90deg"
    assert css =~ ".fr-background-alpha__image img"
    refute css =~ "@media (min-width: 768px)"
    assert css =~ "tablet_portrait"
    assert css =~ "mobile_portrait"
  end

  test "generated text artifacts have stable clean line endings" do
    {:ok, result} = StageA.generate_from_file(fixture_path(), token_set: token_set())

    for name <- ["index.html", "styles.css"] do
      bytes = result.artifacts[name]
      refute bytes =~ " \n"
      refute bytes =~ "\t\n"
      refute String.ends_with?(bytes, "\n\n")
    end
  end

  test "escapes source text instead of rendering raw HTML" do
    element = %LiveFrames.Adapters.Bricks.Element{
      id: "root",
      name: "heading",
      parent: 0,
      settings: %{"text" => "<script>alert(1)</script>", "tag" => "h1"}
    }

    tree = %LiveFrames.Adapters.Bricks.Tree{
      elements: %{"root" => element},
      ordered_elements: [element],
      root_ids: ["root"],
      children_by_id: %{"root" => []},
      parent_by_id: %{"root" => 0},
      source_order: ["root"]
    }

    {:ok, resolved, _} = ClassResolver.resolve(tree, %LiveFrames.Adapters.Bricks.Document{})
    html = HTMLRenderer.render(resolved)
    refute html =~ "<script>alert(1)</script>"
    assert html =~ "&lt;script&gt;alert(1)&lt;/script&gt;"
  end

  test "generates a completed deterministic Hero India Stage A result" do
    assert {:ok, result} =
             StageA.generate_from_file(fixture_path(),
               component_id: "sqhmmc",
               token_set: token_set()
             )

    assert result.status == :completed

    assert result.lifecycle == [
             :received,
             :recognized,
             :validated,
             :resolved,
             :tree_built,
             :dependencies_extracted,
             :rendered,
             :verified,
             :completed
           ]

    report = result.report
    assert report["source_versions"]["payload"] == "2.3.1"
    assert report["source_versions"]["component"] == "2.3.5"
    assert report["source_versions"]["adapter"] == "1.0.0"
    assert report["element_count"] == 10
    assert report["supported_element_count"] == 10
    assert report["unsupported_element_count"] == 0
    assert report["root_count"] == 1
    assert report["global_class_count"] == 468
    assert report["responsive"]["source_breakpoints"] == ["mobile_portrait", "tablet_portrait"]
    assert report["variables"]["token_resolved_count"] == 1
    assert "--neutral-ultra-dark-trans-60" in report["variables"]["unresolved_names"]

    [content_gap] =
      Enum.filter(report["variables"]["dependencies"], &(&1["name"] == "--content-gap"))

    assert content_gap["status"] == "resolved_token"
    assert content_gap["token_path"] == "spacing.content_gap"
    assert "var(--content-gap, 30px)" in content_gap["expressions"]
    assert content_gap["authority_evidence"] != []
    assert result.artifacts["styles.css"] =~ "var(--content-gap, 30px)"

    assert report["assets"]["count"] == 1
    assert report["assets"]["unresolved_count"] == 1
    assert length(report["source_trace"]["elements"]) == 10
  end

  test "Stage A does not create a DesignDocument or normalization artifacts" do
    {:ok, result} = StageA.generate_from_file(fixture_path(), token_set: token_set())
    refute Map.has_key?(result, :design_document)

    refute Enum.any?(result.artifacts, fn {_name, bytes} ->
             String.contains?(bytes, "DesignDocument")
           end)
  end
end
