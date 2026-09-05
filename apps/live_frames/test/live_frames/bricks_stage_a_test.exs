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

  test "resolves content-gap against the frozen TokenSet" do
    token_set = %TokenSet{tokens: %{"spacing.content_gap" => %Token{path: "spacing.content_gap"}}}
    result = DependencyExtractor.variables(["var(--content-gap)"], token_set: token_set)

    assert [%{name: "--content-gap", status: :resolved_token, token_path: "spacing.content_gap"}] =
             result
  end

  test "preserves unresolved nested variables" do
    token_set = %TokenSet{}
    values = ["var(--overlay-bg, var(--neutral-ultra-dark-trans-60))"]
    result = DependencyExtractor.variables(values, token_set: token_set)

    assert Enum.any?(result, &(&1.name == "--overlay-bg" and &1.status == :unresolved_external))

    assert Enum.any?(
             result,
             &(&1.name == "--neutral-ultra-dark-trans-60" and &1.status == :unresolved_external)
           )
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

    css = CSSRenderer.render(resolved)

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
