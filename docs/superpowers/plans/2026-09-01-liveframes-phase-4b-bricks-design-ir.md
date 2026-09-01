# LiveFrames Phase 4B Bricks Design IR Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the approved structured Hero India Bricks source and frozen Phase 3 TokenSet into a validated, deterministic Design IR `1.0.0` artifact.

**Architecture:** Keep the public `LiveFrames.Adapters.Bricks.to_ir/2` boundary thin. It runs the existing structured loader/resolver/tree/class/dependency pipeline and delegates node, style, responsive, asset, diagnostic, document assembly, and lifecycle work to a source-specific normalizer. The normalizer embeds `LiveFrames.Tokens.to_map/1`, validates through `LiveFrames.IR.validate!/1`, and delegates canonical bytes to `LiveFrames.IR.encode!/1`; it never parses Stage A artifacts.

**Tech Stack:** Elixir 1.19, ExUnit, Jason, Mix tasks, frozen LiveFrames Design IR and TokenSet contracts, committed Bricks/Automatic.css fixtures, and deterministic filesystem drift checks.

---

## File structure

- Create `apps/live_frames/lib/live_frames/adapters/bricks/design_ir_normalizer.ex` for the pure structured pipeline-to-IR conversion, mapping table, tagged style normalization, grouped responsive overrides, registry/diagnostic assembly, and lifecycle metadata.
- Modify `apps/live_frames/lib/live_frames/adapters/bricks.ex` to expose only `to_ir/2` as the public Bricks normalization boundary.
- Create `apps/live_frames/lib/mix/tasks/live_frames.bricks.design_ir.ex` for option parsing, fixture/TokenSet loading, `Bricks.to_ir/2` delegation, validation-backed serialization, and artifact writing.
- Create `apps/live_frames/test/live_frames/bricks_design_ir_test.exs` for the focused normalizer contract and TDD regression tests.
- Create `apps/live_frames/test/live_frames/bricks_design_ir_drift_test.exs` for temporary-output byte drift checks.
- Modify `docs/07_BRICKS_ADAPTER.md` with the Phase 4B boundary, mapping, lifecycle, artifact, and stop rules.
- Create `sources/work/hero_india/design_ir/design_document.json` only through the Mix task; it is generated review evidence and must never be hand-edited.
- Keep `apps/live_frames/lib/live_frames/ir/**` and `apps/live_frames/lib/live_frames/tokens/**` unchanged.

## Task 1: Specify the public conversion boundary and contract tests

**Files:**

- Create: `apps/live_frames/test/live_frames/bricks_design_ir_test.exs`
- Modify: `apps/live_frames/lib/live_frames/adapters/bricks.ex`

- [ ] **Step 1: Write the first failing test** for `Bricks.to_ir/2` using the approved fixture path and a validated Hero foundation TokenSet. Assert the intended call shape and that the result is a `DesignDocument` with IR version `1.0.0`.

- [ ] **Step 2: Run the focused test and verify the expected RED failure**:

```sh
mix test apps/live_frames/test/live_frames/bricks_design_ir_test.exs
```

Expected: compilation/test failure because `LiveFrames.Adapters.Bricks.to_ir/2` is not yet defined.

- [ ] **Step 3: Add only the public delegation signature**:

```elixir
@spec to_ir(term(), keyword()) :: {:ok, LiveFrames.IR.DesignDocument.t()} | {:error, list()}
def to_ir(source, opts \\ []), do: DesignIRNormalizer.normalize(source, opts)
```

Add the alias and leave all conversion logic in the new normalizer module.

- [ ] **Step 4: Re-run the focused test and verify the new RED failure** now comes from the missing normalizer module/result, not an API typo.

## Task 2: Implement the structured source pipeline and deterministic nodes

**Files:**

- Create: `apps/live_frames/lib/live_frames/adapters/bricks/design_ir_normalizer.ex`
- Test: `apps/live_frames/test/live_frames/bricks_design_ir_test.exs`

- [ ] **Step 1: Add failing assertions** for exactly one root, the ten source IDs in source order, traversal IDs generated with `DesignNode.deterministic_id/1`, and the semantic sequence `section, container, heading, paragraph, generic, button, button, generic, image, generic`.

- [ ] **Step 2: Run the focused test and confirm it fails** because no normalized tree is assembled.

- [ ] **Step 3: Implement the smallest pipeline**: accept a `Document`, source map, JSON text, or explicit source file; require a validated TokenSet; call `Loader`, `Resolver`, `TreeBuilder`, `ClassResolver`, and `DependencyExtractor`; reject source/tree errors, unexpected root counts, and error/fatal diagnostics; traverse `tree.root_ids` and `children_by_id` in declared order; assign only traversal IDs; and map source types exactly as recorded in the design document.

- [ ] **Step 4: Build each `DesignNode`** with exact text content, proven tag/button attributes, source class/settings metadata, source trace, ordered children, and empty interaction refs. Use a generic type for all three structural `div` elements; do not inspect class names to create native concepts.

- [ ] **Step 5: Run the focused structure/type/ID tests and verify they pass** while the remaining style/registry tests stay visibly failing.

## Task 3: Normalize styles, responsive values, assets, diagnostics, and document metadata

**Files:**

- Modify: `apps/live_frames/lib/live_frames/adapters/bricks/design_ir_normalizer.ex`
- Test: `apps/live_frames/test/live_frames/bricks_design_ir_test.exs`

- [ ] **Step 1: Add failing tests** for literal, keyword, calculation, token reference, fallback-preserving unresolved values, complex CSS/custom CSS, nested unresolved variables, lossless base/tablet gradients, raw `"400"`, four responsive records with source names and nil thresholds, one unresolved attachment `880` registry entry, empty interactions, all eight Stage A warning facts, embedded TokenSet JSON, and lifecycle provenance.

- [ ] **Step 2: Run the focused tests and confirm expected RED failures** identify missing style/registry/diagnostic fields.

- [ ] **Step 3: Normalize base style maps** from `Settings.extract/1` using a conservative classifier: exact `var(--content-gap)` becomes `StyleValue.token_ref("spacing.content_gap", source_expression: raw)`; token-plus-fallback and unknown variables remain `StyleValue.unresolved` with complete `source_expression` and JSON metadata; `calc`/`clamp` become calculations; proven CSS keywords become keywords; safe remaining values become literals; unresolved setting values become unresolved styles keyed by their normalized property.

- [ ] **Step 4: Normalize gradients/custom CSS** as `StyleValue.complex_css` JSON objects containing raw values, property/source key, gradient kind or custom-CSS kind, and raw rules. Preserve source map key order semantically and never convert gradient stops or colors into simplified CSS.

- [ ] **Step 5: Group the four dependency responsive records** by node and breakpoint into `ResponsiveOverride` structs with matching map keys, exact source names, nil dimensions, unresolved status, source traces, and tagged style values.

- [ ] **Step 6: Create the deterministic asset registry** entry and image reference. Set `asset_id` to the normalizer’s stable encounter ID, `kind: "image"`, `uri: nil`, `status: :unresolved`, and preserve attachment ID, filename, original URL value, alt, dimensions, and source node in metadata/trace. Leave interactions `%{}`.

- [ ] **Step 7: Map Bricks diagnostics** to valid IR categories while preserving stable source code/message/raw value/source ID/path in diagnostic metadata/trace. Ensure the unitless margin, four breakpoint warnings, two unresolved variables, and asset warning remain present.

- [ ] **Step 8: Assemble `DesignDocument`** with exact source metadata, `LiveFrames.Tokens.to_map(token_set)`, roots, registries, mapped diagnostics, and deterministic provenance/lifecycle. Validate with `LiveFrames.IR.validate!/1` before returning `{:ok, document}`.

- [ ] **Step 9: Run all focused normalizer tests and verify they pass.**

## Task 4: Add regeneration Mix task and generated artifact

**Files:**

- Create: `apps/live_frames/lib/mix/tasks/live_frames.bricks.design_ir.ex`
- Create: `sources/work/hero_india/design_ir/design_document.json`
- Test: `apps/live_frames/test/live_frames/bricks_design_ir_test.exs`

- [ ] **Step 1: Add a failing task/integration test** that runs the task against the approved defaults into a temporary output directory and asserts the output is valid JSON with IR version `1.0.0`.

- [ ] **Step 2: Run the task test and confirm it fails** before the task exists.

- [ ] **Step 3: Implement only OptionParser and delegation** with switches `source`, `component_id`, `acss_source`, and `output`. Default them to `fixtures/bricks/bricks_components.json`, `sqhmmc`, `fixtures/automatic_css/acss_settings.json`, and `sources/work/hero_india/design_ir/design_document.json`. Load the TokenSet using `AutomaticCSS.from_file/2` with source version `4.0.1`, fixture-reference status, strict validation, and `hero_foundation`; call `Bricks.to_ir/2`; serialize with `LiveFrames.IR.encode!/1`; write only the requested output file; and raise on errors. Do not parse JSON or normalize inside the task.

- [ ] **Step 4: Generate the committed artifact** from the approved defaults:

```sh
mix live_frames.bricks.design_ir
```

- [ ] **Step 5: Inspect the generated JSON** for no timestamps, random IDs, absolute paths, host/process values, Stage A `about:blank`, fabricated URL, or source IDs used as node IDs.

## Task 5: Add deterministic drift verification and documentation

**Files:**

- Create: `apps/live_frames/test/live_frames/bricks_design_ir_drift_test.exs`
- Modify: `docs/07_BRICKS_ADAPTER.md`

- [ ] **Step 1: Add failing drift tests** that generate to two temporary directories and byte-compare the output to one another and to `sources/work/hero_india/design_ir/design_document.json`; include a modified expected file case; ensure the committed file is never the output target of a test.

- [ ] **Step 2: Run the drift test and verify the expected RED failure** until the generated artifact and comparison helper exist.

- [ ] **Step 3: Implement the test-only comparison helper** using the Mix task/API into a temporary directory, `File.read!`, and exact byte equality. Do not add a second serializer or alter the committed file.

- [ ] **Step 4: Document** the Phase 4B mapping table, public API, style-loss rules, responsive policy, asset/interaction registry policy, diagnostics, lifecycle, regeneration command, drift policy, static-only scaling/security, and explicit Phase 5 stop boundary.

- [ ] **Step 5: Run the focused tests and inspect `git diff --check`.**

## Task 6: Execute repository gates and review scope

**Files:**

- Review all changed files; do not add HEEx/Tailwind/native Hero/Storybook or modify frozen IR/TokenSet files.

- [ ] **Step 1: Run focused Phase 4B tests, IR validation, and drift verification.**

- [ ] **Step 2: Run every repository gate:**

```sh
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix assets.build
mix test
mix deps.unlock --check-unused
git diff --check
```

- [ ] **Step 3: Re-run the generator/drift test after all formatting and build commands** and verify the committed artifact remains byte-identical.

- [ ] **Step 4: Review the final diff, worktree, branch, and exact commit head.** Confirm the only generated artifact is `design_document.json` and no frozen contract changed.

- [ ] **Step 5: Commit the implementation and evidence** with a focused message after fresh verification.

- [ ] **Step 6: Push `feature/phase-4b-bricks-design-ir`, open PR `Phase 4B: normalize Bricks Hero to Design IR` against `main`, wait for push CI and pull-request CI, verify both statuses against the exact PR head, and do not merge.**
