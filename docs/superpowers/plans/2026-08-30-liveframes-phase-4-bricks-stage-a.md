# LiveFrames Phase 4 Bricks Stage A implementation plan

> For agentic workers: use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Implement a source-specific Bricks adapter that turns the approved Hero India copied-elements fixture into deterministic Stage A HTML, CSS, and report artifacts without generating Design IR, HEEx, Tailwind, or a catalogue component.

**Architecture:** Keep the public LiveFrames.Adapters.Bricks façade thin and split the work into source loading, component resolution, flat-tree validation, dependency extraction, and Stage A rendering. Use small Bricks-only structs and a result status model. The artifact writer and Mix task delegate to the same pure generation API, and the drift verifier compares temporary output against committed files.

**Tech Stack:** Elixir 1.19, ExUnit, Jason, Mix tasks, the existing Phase 3 LiveFrames.TokenSet, committed Bricks and Automatic.css JSON fixtures, and GitHub Actions.

---

## File map

Create these source files under apps/live_frames/lib/live_frames/adapters/bricks/:

- diagnostic.ex: Bricks diagnostic struct, severity/category normalization, and constructors.
- document.ex: recognized Bricks envelope and source metadata.
- content_proxy.ex: copied-content proxy fields.
- component.ex: resolved component fields and ordered source elements.
- element.ex: raw source element fields and preserved JSON.
- global_class.ex: global class fields and preserved JSON.
- tree.ex: element lookup, ordered roots, ordered child IDs, and source order.
- dependency.ex: source dependency fields and dependency status values.
- result.ex: lifecycle status, partial pipeline data, artifacts, and diagnostics.
- loader.ex: file/JSON decoding, envelope recognition, version checks, and model construction.
- resolver.ex: explicit content proxy and component lookup.
- tree_builder.ex: one-pass element indexing and relationship/cycle validation.
- class_resolver.ex: _cssGlobalClasses lookup and button style class resolution.
- settings.ex: explicit supported setting table, suffix parsing, safe values, and setting records.
- dependency_extractor.ex: variables, TokenSet links, classes, assets, custom CSS, and runtime dependencies.
- serializer.ex: recursively ordered JSON encoding used by the report and raw preserved values.
- stage_a/html_renderer.ex: escaped deterministic source-tree HTML.
- stage_a/css_renderer.ex: explicit Stage A CSS mapping and preserved custom/responsive source CSS.
- stage_a/report.ex: machine-readable report construction and counts.
- stage_a.ex: public generation, artifact writing, lifecycle orchestration, and drift verification.

Create the Mix task at apps/live_frames/lib/mix/tasks/live_frames.bricks.stage_a.ex.

Create focused tests at:

- apps/live_frames/test/live_frames/bricks_adapter_test.exs
- apps/live_frames/test/live_frames/bricks_tree_test.exs
- apps/live_frames/test/live_frames/bricks_stage_a_test.exs
- apps/live_frames/test/live_frames/bricks_drift_test.exs

Update docs/07_BRICKS_ADAPTER.md with the approved Stage A contract. Generate, never hand-edit:

- sources/work/hero_india/stage_a/index.html
- sources/work/hero_india/stage_a/styles.css
- sources/work/hero_india/stage_a/report.json

Do not modify apps/live_frames/lib/live_frames/ir/, apps/live_frames/lib/live_frames/tokens/, or their contract documentation.

## Task 1: Define Bricks source models and diagnostics

**Files:**

- Create: apps/live_frames/lib/live_frames/adapters/bricks/diagnostic.ex
- Create: apps/live_frames/lib/live_frames/adapters/bricks/document.ex
- Create: apps/live_frames/lib/live_frames/adapters/bricks/content_proxy.ex
- Create: apps/live_frames/lib/live_frames/adapters/bricks/component.ex
- Create: apps/live_frames/lib/live_frames/adapters/bricks/element.ex
- Create: apps/live_frames/lib/live_frames/adapters/bricks/global_class.ex
- Create: apps/live_frames/lib/live_frames/adapters/bricks/tree.ex
- Create: apps/live_frames/lib/live_frames/adapters/bricks/dependency.ex
- Create: apps/live_frames/lib/live_frames/adapters/bricks/result.ex
- Test: apps/live_frames/test/live_frames/bricks_adapter_test.exs

- [ ] Step 1: Write failing model and diagnostic tests.

~~~elixir
test "diagnostics normalize only supported severities" do
  assert Diagnostic.new(code: "bricks.source.invalid", severity: :fatal).severity == :fatal
  assert Diagnostic.new(code: "bricks.source.invalid", severity: "warning").severity == :warning
  assert Diagnostic.new(code: "bricks.source.invalid", severity: "unknown").severity == :error
end

test "source models preserve independent versions" do
  document = %Document{
    source: "bricksCopiedElements",
    payload_version: "2.3.1",
    adapter_version: "1.0.0",
    components: %{"sqhmmc" => %Component{id: "sqhmmc", version: "2.3.5"}}
  }

  assert document.components["sqhmmc"].version == "2.3.5"
  assert document.payload_version != document.components["sqhmmc"].version
end

test "result tracks the lifecycle without starting a process" do
  result = Result.new()
  assert result.status == :received
  assert result.lifecycle == [:received]
  assert Result.advance(result, :recognized).lifecycle == [:received, :recognized]
end
~~~

- [ ] Step 2: Run mix test apps/live_frames/test/live_frames/bricks_adapter_test.exs.

Expected: FAIL because the Bricks modules do not exist.

- [ ] Step 3: Implement plain JSON-safe structs. Diagnostic fields are code, severity, category, message, source_path, source_id, raw_value, and metadata. Use severities :info, :warning, :error, and :fatal. Define Result with status, lifecycle, document, proxy, component, tree, dependencies, artifacts, artifact_paths, report, and diagnostics. Result.advance/2 accepts only the next lifecycle state; Result.reject/2 and Result.fail/2 set terminal statuses.

- [ ] Step 4: Run the model tests and expect PASS.
- [ ] Step 5: Commit with message feat: add Bricks source models.

## Task 2: Recognize and validate the copied-elements envelope

**Files:**

- Create: apps/live_frames/lib/live_frames/adapters/bricks/loader.ex
- Modify: apps/live_frames/lib/live_frames/adapters/bricks.ex
- Modify: apps/live_frames/test/live_frames/bricks_adapter_test.exs

- [ ] Step 1: Write tests for the approved fixture, malformed JSON, wrong envelope, missing collections, duplicate component/class IDs, missing proxy cid, and unknown payload version.

~~~elixir
test "recognizes the approved fixture and preserves source versions" do
  assert {:ok, document, diagnostics} = Bricks.from_file(fixture_path())
  assert document.source == "bricksCopiedElements"
  assert document.source_url == "http://localhost:10049"
  assert document.payload_version == "2.3.1"
  assert document.component_count == 39
  assert document.global_class_count == 468
  assert diagnostics == []
end

test "returns structured diagnostics for malformed JSON" do
  assert {:error, diagnostics} = Bricks.from_json("{bad")
  assert Enum.any?(diagnostics, &(&1.code == "bricks.source.json_invalid"))
end

test "rejects wrong envelope and unsupported version" do
  assert {:error, diagnostics} = Bricks.from_json(Jason.encode!(%{"source" => "other"}))
  assert Enum.any?(diagnostics, &(&1.code == "bricks.source.invalid"))

  source = fixture_map() |> Map.put("version", "9.9.9") |> Jason.encode!()
  assert {:error, diagnostics} = Bricks.from_json(source)
  assert Enum.any?(diagnostics, &(&1.code == "bricks.source.version_unsupported"))
end
~~~

- [ ] Step 2: Run the focused test and expect FAIL because Loader and the public façade are absent.
- [ ] Step 3: Implement Loader.from_file/2, from_json/2, and recognize/2 with File.read/1 and Jason.decode/1. Require source = "bricksCopiedElements", non-empty sourceUrl and version strings, and list-valued content, components, and globalClasses. Accept only payload version "2.3.1" unless allow_unknown_version: true is explicit. Store a logical source_label, defaulting to the basename, and a SHA-256 source hash. Never store an expanded input path in report data. Convert JSON empty settings lists to empty maps, retain raw objects, validate IDs/children/settings, require every content proxy cid, and reject duplicate component/global-class IDs.
- [ ] Step 4: Run the focused and full suites. Expect recognition tests and the Phase 0 to Phase 3 baseline to pass.
- [ ] Step 5: Commit with message feat: recognize Bricks copied-elements exports.

## Task 3: Resolve the component proxy

**Files:**

- Create: apps/live_frames/lib/live_frames/adapters/bricks/resolver.ex
- Modify: apps/live_frames/lib/live_frames/adapters/bricks.ex
- Modify: apps/live_frames/test/live_frames/bricks_adapter_test.exs

- [ ] Step 1: Write tests for explicit sqhmmc resolution, missing components, duplicate matches, and calls without a component ID.

~~~elixir
test "resolves explicit Hero India cid" do
  {:ok, document, _} = Bricks.from_file(fixture_path())
  assert {:ok, proxy, component, diagnostics} = Bricks.resolve(document, component_id: "sqhmmc")
  assert proxy.cid == "sqhmmc"
  assert component.id == "sqhmmc"
  assert component.version == "2.3.5"
  assert diagnostics == []
end

test "rejects a missing component without falling back" do
  {:ok, document, _} = Bricks.from_file(fixture_path())
  assert {:error, diagnostics} = Bricks.resolve(document, component_id: "missing")
  assert Enum.any?(diagnostics, &(&1.code == "bricks.component.missing"))
end

test "requires explicit selection when multiple proxies exist" do
  {:ok, document, _} = Bricks.from_file(fixture_path())
  assert {:error, diagnostics} = Bricks.resolve(document, [])
  assert Enum.any?(diagnostics, &(&1.code == "bricks.component.ambiguous"))
end
~~~

- [ ] Step 2: Run the focused test and expect FAIL for the absent resolver.
- [ ] Step 3: Implement Resolver.resolve/2. Use component_id when supplied. Without it, select only one unique cid. Reject missing/duplicate cids, missing components, and malformed resolved elements. Preserve proxy label, component category, nullable component name, and both source versions. Expose Bricks.resolve/2 as a thin delegation.
- [ ] Step 4: Run focused and full tests and expect PASS.
- [ ] Step 5: Commit with message feat: resolve Bricks component proxies.

## Task 4: Rebuild and validate the flat source tree

**Files:**

- Create: apps/live_frames/lib/live_frames/adapters/bricks/tree_builder.ex
- Modify: apps/live_frames/lib/live_frames/adapters/bricks.ex
- Create: apps/live_frames/test/live_frames/bricks_tree_test.exs

- [ ] Step 1: Write tests for Hero order, duplicate IDs, missing parents, missing children, duplicate child IDs, reciprocity mismatches, self-ancestry, cycles, and multiple roots.

~~~elixir
test "reconstructs Hero India in declared order" do
  {:ok, document, _} = Bricks.from_file(fixture_path())
  {:ok, _proxy, component, _} = Bricks.resolve(document, component_id: "sqhmmc")
  assert {:ok, tree, diagnostics} = Bricks.build_tree(component)
  assert tree.root_ids == ["sqhmmc"]
  assert tree.children_by_id["sqhmmc"] == ["2ef2fa", "1c85d9"]
  assert tree.children_by_id["2ef2fa"] == ["561d75", "3f6ee6", "8ae908"]
  assert diagnostics == []
end

test "rejects duplicate IDs and invalid relationships" do
  assert_error_with_code(component_with_duplicate_ids(), "bricks.element.duplicate")
  assert_error_with_code(component_with_missing_parent(), "bricks.parent.missing")
  assert_error_with_code(component_with_missing_child(), "bricks.child.missing")
  assert_error_with_code(component_with_reciprocity_mismatch(), "bricks.tree.reciprocity")
  assert_error_with_code(component_with_cycle(), "bricks.tree.cycle")
end
~~~

- [ ] Step 2: Run the tree test and expect FAIL.
- [ ] Step 3: Implement TreeBuilder.build/1. Index the ordered element list once. Accept root markers 0, "0", and nil. Build children_by_id, validate IDs, parents, child IDs, duplicate children, reciprocity, and parent-chain cycles with MapSet, then derive roots in source order. Return no tree for tree errors. Retain multiple roots in order with a warning; Stage A freezes Hero root count one. Expose Bricks.build_tree/1.
- [ ] Step 4: Run tree and full tests and expect PASS.
- [ ] Step 5: Commit with message feat: rebuild Bricks source trees.

## Task 5: Resolve classes and map the supported setting subset

**Files:**

- Create: apps/live_frames/lib/live_frames/adapters/bricks/class_resolver.ex
- Create: apps/live_frames/lib/live_frames/adapters/bricks/settings.ex
- Modify: apps/live_frames/test/live_frames/bricks_stage_a_test.exs

- [ ] Step 1: Write class and setting tests.

~~~elixir
test "resolves applied global classes and ACSS names" do
  {:ok, source, _} = Bricks.from_file(fixture_path())
  {:ok, _proxy, component, _} = Bricks.resolve(source, component_id: "sqhmmc")
  {:ok, tree, _} = Bricks.build_tree(component)
  {:ok, resolved, diagnostics} = ClassResolver.resolve(tree, source)
  assert resolved.elements["sqhmmc"].class_names == ["fr-hero-india", "bg--ultra-dark"]
  assert diagnostics == []
end

test "maps representative settings and preserves raw expressions" do
  result = Settings.extract(%{
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

test "does not invent a unit for bare margin" do
  result = Settings.extract(%{"_margin" => %{"top" => "400"}})
  assert result.unresolved_values["_margin.top"] == "400"
end
~~~

- [ ] Step 2: Run the focused test and expect FAIL.
- [ ] Step 3: Resolve each _cssGlobalClasses list in order through document.global_classes. Preserve missing IDs as diagnosed provenance. For button elements, copy a validated style string and add btn--outline when outline is true. Keep empty ACSS settings meaningful without inventing declarations.
- [ ] Step 4: Implement the explicit setting map:

~~~elixir
@style_properties %{
  "_position" => "position",
  "_isolation" => "isolation",
  "_rowGap" => "row-gap",
  "_columnGap" => "column-gap",
  "_alignItems" => "align-items",
  "_justifyContent" => "justify-content",
  "_zIndex" => "z-index",
  "_width" => "width",
  "_widthMax" => "max-width",
  "_height" => "height",
  "_display" => "display",
  "_flexWrap" => "flex-wrap",
  "_direction" => "flex-direction",
  "_top" => "top",
  "_right" => "right",
  "_bottom" => "bottom",
  "_left" => "left",
  "_objectFit" => "object-fit",
  "_objectPosition" => "object-position"
}
~~~

Handle _margin sides, _border.radius sides, _background.color.raw, _gradient, and _cssCustom in dedicated functions. Split only the first colon in a key. Count text, tag, style, outline, image, and caption as semantic consumption, and _cssGlobalClasses as class-reference consumption. Accept explicit CSS units, valid keywords, and zero. Permit numeric z-index and gradient angles. Preserve nonzero bare margin values as unresolved raw values, never append px. Reject or preserve declaration separators/braces as unsafe. Unknown keys and nested fields produce bricks.setting.unsupported.
- [ ] Step 5: Run focused and full tests and expect PASS.
- [ ] Step 6: Commit with message feat: map Bricks classes and Stage A settings.

## Task 6: Extract dependencies and implement deterministic serialization

**Files:**

- Create: apps/live_frames/lib/live_frames/adapters/bricks/dependency_extractor.ex
- Create: apps/live_frames/lib/live_frames/adapters/bricks/serializer.ex
- Modify: apps/live_frames/test/live_frames/bricks_stage_a_test.exs

- [ ] Step 1: Write tests for the exact variable mapping, unresolved nested variables, attachment 880 with url false, ACSS class names, and interaction/query settings.

~~~elixir
test "resolves content-gap against the frozen TokenSet" do
  token_set = %TokenSet{tokens: %{"spacing.content_gap" => %Token{path: "spacing.content_gap"}}}
  result = DependencyExtractor.variables(["var(--content-gap)"], token_set: token_set)
  assert [%{name: "--content-gap", status: :resolved_token, token_path: "spacing.content_gap"}] = result
end

test "preserves unresolved nested variables" do
  values = ["var(--overlay-bg, var(--neutral-ultra-dark-trans-60))"]
  result = DependencyExtractor.variables(values, token_set: token_set())
  assert Enum.any?(result, &(&1.name == "--overlay-bg" and &1.status == :unresolved_external))
  assert Enum.any?(result, &(&1.name == "--neutral-ultra-dark-trans-60" and &1.status == :unresolved_external))
end

test "reports unresolved attachment data" do
  [asset] = DependencyExtractor.assets([hero_image_settings()])
  assert asset.attachment_id == 880
  assert asset.status == :unresolved
  assert asset.url == false
end
~~~

- [ ] Step 2: Run the focused test and expect FAIL.
- [ ] Step 3: Implement explicit dependency collection with only %{"--content-gap" => "spacing.content_gap"}. Verify the target exists in the supplied TokenSet and never mutate that TokenSet. Scan supported values and custom CSS for var references, retain occurrences and source paths, and deduplicate only summary counts.
- [ ] Step 4: Collect applied classes, unique ACSS class names, responsive entries, custom CSS, image evidence, and raw interaction/dynamic/query/script/hook settings. Preserve values and never execute them.
- [ ] Step 5: Implement Serializer.encode!/1 with string-keyed recursively sorted maps, source-order lists, JSON-safe values, and no inspect/1 in artifact content.
- [ ] Step 6: Run focused and full tests and commit with message feat: extract Bricks Stage A dependencies.

## Task 7: Render deterministic Stage A HTML and CSS

**Files:**

- Create: apps/live_frames/lib/live_frames/adapters/bricks/stage_a/html_renderer.ex
- Create: apps/live_frames/lib/live_frames/adapters/bricks/stage_a/css_renderer.ex
- Modify: apps/live_frames/test/live_frames/bricks_stage_a_test.exs

- [ ] Step 1: Write tests asserting all seven Hero element types, source classes, button classes, escaped source text, about:blank for the unresolved asset, mapped base CSS, gradient output, base custom CSS, and named responsive preservation without guessed media queries.

~~~elixir
test "renders supported Hero elements and source classes" do
  html = generate_fixture().artifacts["index.html"]
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

test "escapes source text" do
  html = generate_with_text("<script>alert(1)</script>").artifacts["index.html"]
  refute html =~ "<script>alert(1)</script>"
  assert html =~ "&lt;script&gt;"
end

test "renders base CSS and preserves custom CSS" do
  css = generate_fixture().artifacts["styles.css"]
  assert css =~ "position: relative;"
  assert css =~ "row-gap: var(--content-gap);"
  assert css =~ "linear-gradient(90deg"
  assert css =~ ".fr-background-alpha__image img"
  refute css =~ "@media (min-width: 768px)"
  assert css =~ "tablet_portrait"
  assert css =~ "mobile_portrait"
end
~~~

- [ ] Step 2: Run the focused test and expect FAIL.
- [ ] Step 3: Implement a fixed standalone HTML shell with generated-file comment, doctype, charset, title, stylesheet link, body, and recursive source tree. Use section, div/container, validated heading/text tags, button, and figure/image. Escape text and attrs. Use type="button" when no link exists. Use about:blank only for an unresolved asset. Preserve source classes followed by deterministic bricks-element--source-id scope class. Never render raw source HTML as trusted markup.
- [ ] Step 4: Implement CSS class/scope rules and explicit setting output. Escape CSS selectors. Render validated gradients and raw var expressions. Emit deterministic comments with breakpoint, source key, target property, and ordered raw JSON for unresolved responsive entries. Copy base _cssCustom source text and preserve responsive custom CSS without activating it without a threshold.
- [ ] Step 5: Run focused and full suites and commit with message feat: render Bricks Stage A HTML and CSS.

## Task 8: Build the report and public Stage A pipeline

**Files:**

- Create: apps/live_frames/lib/live_frames/adapters/bricks/stage_a/report.ex
- Create: apps/live_frames/lib/live_frames/adapters/bricks/stage_a.ex
- Modify: apps/live_frames/lib/live_frames/adapters/bricks/result.ex
- Modify: apps/live_frames/test/live_frames/bricks_stage_a_test.exs

- [ ] Step 1: Write lifecycle, counts, and scope-boundary tests.

~~~elixir
test "generates a completed Hero India Stage A result" do
  assert {:ok, result} = generate_fixture()
  assert result.status == :completed
  assert result.lifecycle == [
           :received, :recognized, :validated, :resolved, :tree_built,
           :dependencies_extracted, :rendered, :verified, :completed
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

test "does not create a DesignDocument" do
  {:ok, result} = generate_fixture()
  refute Map.has_key?(result, :design_document)
  refute Enum.any?(result.artifacts, fn {_name, bytes} -> String.contains?(bytes, "DesignDocument") end)
end
~~~

- [ ] Step 2: Run the focused test and expect FAIL.
- [ ] Step 3: Implement StageA.generate_from_file/2 and generate/2 in this order: Loader, Resolver, TreeBuilder, DependencyExtractor, HTMLRenderer, CSSRenderer, Report. Advance Result after every successful stage. Preserve non-fatal diagnostics, reject source/tree failures, and fail renderer/filesystem exceptions. Freeze expected_root_count: 1 in the task options. Accept an optional Phase 3 TokenSet and never mutate it.
- [ ] Step 4: Build report groups named report_schema_version, stage_a_schema_version, adapter_version, source, source_versions, component, lifecycle, roots, element_count, supported_element_count, unsupported_element_count, classes, settings, responsive, custom_css, variables, assets, runtime_dependencies, diagnostics, and source_trace. Include logical source label/hash, exact raw evidence, all element traces, and severity counts. Exclude absolute paths, timestamps, host/process data, and random values.
- [ ] Step 5: Run focused and full suites and commit with message feat: add Bricks Stage A pipeline report.

## Task 9: Add drift verification and determinism tests

**Files:**

- Create: apps/live_frames/test/live_frames/bricks_drift_test.exs
- Modify: apps/live_frames/lib/live_frames/adapters/bricks/stage_a.ex

- [ ] Step 1: Write tests for two successive generations, committed artifact parity, modified expected artifact, missing generated artifact, unexpected generated artifact, and forbidden metadata.

~~~elixir
test "two successive generations are byte-identical" do
  assert read_artifacts(generate_to_temp_dir()) == read_artifacts(generate_to_temp_dir())
end

test "modified expected output is detected without touching committed files" do
  expected = copy_artifact_dir_to_temp()
  File.write!(Path.join(expected, "index.html"), "changed")
  assert {:error, diagnostics} = verify_against(expected)
  assert Enum.any?(diagnostics, &(&1.code == "bricks.artifact.different"))
end

test "missing and unexpected files are detected" do
  temporary = unique_temp_dir()
  File.write!(Path.join(temporary, "extra.txt"), "unexpected")
  assert {:error, diagnostics} = verify_with_existing_temp(temporary)
  assert Enum.any?(diagnostics, &(&1.code == "bricks.artifact.unexpected"))
end
~~~

- [ ] Step 2: Run the drift test and expect failure until StageA.verify_drift/1 and artifacts exist.
- [ ] Step 3: Implement verify_drift/1 requiring expected_dir, temporary_dir, source_path, component_id, and token_set. Generate only into temporary_dir, compare exactly index.html, styles.css, and report.json, and return sorted diagnostics for missing/different/unexpected files. Never write expected_dir.
- [ ] Step 4: Decode report JSON in tests and recursively assert no generated_at, process ID, host, absolute path, random ID, or environment value occurs. Assert source trace coverage for all ten fixture elements.
- [ ] Step 5: Run focused and full tests and commit with message test: verify deterministic Bricks Stage A artifacts.

## Task 10: Add the stable Mix task and generate artifacts

**Files:**

- Create: apps/live_frames/lib/mix/tasks/live_frames.bricks.stage_a.ex
- Modify: apps/live_frames/test/live_frames/bricks_drift_test.exs
- Create: sources/work/hero_india/stage_a/index.html
- Create: sources/work/hero_india/stage_a/styles.css
- Create: sources/work/hero_india/stage_a/report.json

- [ ] Step 1: Run this delegation check against a temporary directory:

~~~bash
mix live_frames.bricks.stage_a --source fixtures/bricks/bricks_components.json --component-id sqhmmc --acss-source fixtures/automatic_css/acss_settings.json --output-dir /tmp/liveframes-phase-4-stage-a
~~~

Expected: exit 0 and exactly three files. The public StageA API produces identical bytes for the same options.

- [ ] Step 2: Implement only OptionParser and delegation. Use switches source, component_id, acss_source, and output_dir. Freeze defaults to the approved fixture, sqhmmc, approved ACSS fixture, and sources/work/hero_india/stage_a. Resolve paths for filesystem access but pass logical labels to StageA. Load the Phase 3 TokenSet with source version 4.0.1, fixture_reference status, strict true, and hero_foundation profile. Do not decode JSON or render anything in the task.
- [ ] Step 3: Run mix live_frames.bricks.stage_a from repository root. Expect exactly the three required files under sources/work/hero_india/stage_a/. Do not hand-edit them.
- [ ] Step 4: Run drift tests and generate a second temporary output. Compare SHA-256 hashes for all three files.
- [ ] Step 5: Commit task and artifacts with message feat: add Bricks Stage A regeneration task.

## Task 11: Document the boundary and review failure modes

**Files:**

- Modify: docs/07_BRICKS_ADAPTER.md
- Modify: apps/live_frames/test/live_frames/bricks_adapter_test.exs
- Modify: apps/live_frames/test/live_frames/bricks_stage_a_test.exs

- [ ] Step 1: Add tests for malformed JSON, unsupported shape, independent source/component versions, missing cid/component, duplicate IDs, missing relationships, reciprocity, cycles, multiple roots, unsupported element/setting, malformed style, unknown breakpoint, custom CSS, unresolved ACSS class, unresolved variables, missing image URL, dynamic/interaction data, unsafe source text, and nondeterministic output. Assert raw values are retained or diagnosed.
- [ ] Step 2: Document payload shape, version policy, proxy resolution, tree rules, seven supported types, class provenance, setting mapping table, responsive policy, custom CSS policy, dependency states, asset policy, lifecycle/report/diagnostic contracts, security, scaling, bare margin limitation, and the stop boundary before Design IR.
- [ ] Step 3: Run mix format --check-formatted and the complete focused suite. Expect no formatting failure and all focused tests passing.
- [ ] Step 4: Commit with message docs: record Bricks Stage A extraction contract.

## Task 12: Run local gates and verify frozen contracts

**Files:**

- Verify: all changed files and the diff from main

- [ ] Step 1: Run the focused suite separately.

~~~bash
mix test apps/live_frames/test/live_frames/bricks_adapter_test.exs apps/live_frames/test/live_frames/bricks_tree_test.exs apps/live_frames/test/live_frames/bricks_stage_a_test.exs apps/live_frames/test/live_frames/bricks_drift_test.exs
~~~

Expected: all focused tests pass.

- [ ] Step 2: Run every required gate:

~~~bash
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix assets.build
mix test
mix deps.unlock --check-unused
git diff --check
~~~

Expected: every command exits successfully.

- [ ] Step 3: Verify no IR or TokenSet source file changed and no DesignDocument, HEEx, Tailwind, Hero catalogue, or Storybook implementation was added.

~~~bash
git diff --name-only main...HEAD | rg '(^|/)(ir|tokens)(/|\\.)' && exit 1 || true
git diff main...HEAD -- apps/live_frames/lib/live_frames/ir apps/live_frames/lib/live_frames/tokens
~~~

Expected: no forbidden source changes and an empty frozen-contract diff.

- [ ] Step 4: Regenerate into a temporary directory, compare SHA-256 hashes with committed artifacts, run git diff --check, and confirm only intentional Phase 4 files are present.
- [ ] Step 5: If a formatting-only correction is needed, commit it and repeat every relevant focused test, gate, artifact hash, and drift check before recording the final SHA.

## Task 13: Publish and verify the dedicated PR

**Files:**

- Verify: GitHub branch and workflow runs

- [ ] Step 1: Push the exact final head with git push -u origin feature/phase-4-bricks-stage-a and record its SHA.
- [ ] Step 2: Open an unmerged PR against main titled Phase 4: add Bricks Stage A extraction. The body must include fixture, versions, artifact paths, diagnostics, focused/full results, frozen-contract confirmation, and the Phase 5 stop boundary.
- [ ] Step 3: Use gh pr view and gh run list to confirm one push run and one pull_request run both use the final SHA and both succeed. Do not report completion while either is pending, failed, or points at an older SHA. Do not merge.
- [ ] Step 4: Confirm the PR is open, its head OID equals the final local SHA, both CI contexts passed, and the Phase 4 worktree is clean.

## Plan self-review

- Recognition, version preservation, proxy resolution, tree validation, supported elements, classes, settings, responsive handling, custom CSS, variables, TokenSet comparison, assets, dynamic data, diagnostics, security, scaling, artifacts, report fields, drift, documentation, tests, local gates, and exact-head CI each have a task.
- No task changes Design IR 1.0.0 or TokenSet 1.0.0.
- No task generates a DesignDocument, HEEx, Tailwind, LiveView component, or Storybook catalogue item.
- Only the three required Stage A artifacts are generated. Normal tests compare temporary output and never rewrite committed artifacts.
- The bare 400 margin unit, responsive thresholds, external CSS variables, unresolved attachment URL, and runtime behavior remain visible as preserved diagnostics.
- No TODO, TBD, or unspecified implementation step remains.

