defmodule LiveFrames.BricksStageATest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Adapters.Bricks.ClassResolver
  alias LiveFrames.Adapters.Bricks.DependencyExtractor
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

  defp external_class_authority do
    %{
      id: "synthetic-site-classes",
      global_classes: [
        %{"id" => "opaque-class-id", "name" => "synthetic-class", "settings" => %{}}
      ]
    }
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
