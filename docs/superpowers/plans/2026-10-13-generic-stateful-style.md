# Generic stateful style implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task by task. Steps use checkbox syntax for tracking.

**Goal:** Add a bounded, source-neutral Bricks CSS normalization and native rendering capability for conditionless, responsive, hover, and focus-within styles.

**Architecture:** Parse source CSS with a bounded Bricks parser, resolve supported selector meaning to normalized DesignNode relationships, and store safe declarations in existing style and responsive IR or the closed `complex_css` `state_rules` subtype. The native generator resolves owner and target identities with `NodeStyleIdentity`, validates component topology, and emits only closed package-private selectors through the existing `StyleValueCSS` serializer.

**Tech Stack:** Elixir umbrella application, Mix, ExUnit, existing Bricks adapters, Design IR 4.0.0, `ResponsiveOverride`, `NodeStyleIdentity`, `StyleValueCSS`, and `StylesheetRenderer`.

**Spec:** `docs/development/feature_romeo_css_style_authority.md` controls this plan. `docs/development/feature_romeo_source_semantics_authority.md`, `docs/development/c09d6_native_generation_authority.md`, `docs/development/c09d6d_upstream_style_gap_resolution_authority.md`, and the listed LiveFrames specifications define adjacent boundaries. The accepted source-neutral wire contract and fail-closed rules below are binding for every task.

**Global Constraints:**

- This plan does not authorize implementation. The implementation phase requires a separate owner gate after review of this plan PR.
- Keep the accepted `BoundedCustomCssNormalizer` rule table frozen to CTA Tango. The generic pass must skip every source owner claimed by that pass.
- Keep `DesignDocument.ir_version` at `4.0.0`. Do not make general `LiveFrames.IR.Validation` reject previously preservable `complex_css` values.
- Treat imported JSON and CSS as inert, untrusted data. Never evaluate CSS or source runtime, convert source strings to atoms, or perform dynamic module/function lookup.
- Never add source IDs, source classes, source selectors, or Romeo-specific production branches/constants. Componentization must receive source-neutral IR only.
- Reuse `StyleValueCSS`, safe CSS property validation, `TokenBridge`, existing `ResponsiveOverride` fields, and `NodeStyleIdentity`. Do not create a second CSS value serializer, selector engine, or general cascade engine.
- Keep unsupported or conflicting rules atomic and inert. Residual text never reaches native selector or value generation.
- Keep hover and focus-within as ephemeral browser CSS conditions. Add no BehaviorContract runtime, JavaScript hooks, server state, persistence, polling, database, network, Redis, Postgres, PubSub, GenServer, or Oban work.
- Keep analysis linear or near-linear in bounded source rules and normalized nodes. Build source-ID-to-node, node-ID-to-node, and node-ID-to-ancestry/private-class indexes once per compilation.
- Scope the implementation phase to the six tasks below. Run each task's tests first, prove RED, implement the minimum, prove GREEN, run its regressions, and commit before starting the next task.

**Review Focus:**

1. Tango owner is not processed by both the specialized and generic normalizers. Task 2 must test claimed-owner skipping, including residual and topology-failure cases.
2. Residual source text never enters native selector or value generation. Tasks 3 and 5 must test mixed normalized/residual data and assert residual text is absent from output CSS.
3. A state target cannot escape its owner subtree or component boundary. Task 5 must test self, descendant, sibling, ancestor, missing, and outside-boundary targets.
4. Responsive intervals cannot acquire source-order or map-order semantics. Tasks 2 and 4 must test inclusive overlap conflicts, same-value exact duplicates, and deterministic output.
5. Existing `:focus-visible`, Tango output, and ordinary max-width responsive output remain unchanged. Tasks 1, 4, 5, and 6 must run their named regression suites and assert those outputs.

---

## Accepted entry state and movement check

The plan was created on `origin/main` at `51d958e05627e7291b57d75f857cdf4332e37814`, tree `20c5f0851d7c7c615c3ec46a444a68077361dd01`. PR #197 merge `3f91039beccbb533da839e9ce47b8cd9e23d962a`, tree `680f6e14e38f704d188fc833a62d8a31e3283546`, and approved head `7bbcdae…` are in its ancestry. Post-merge run `38435499252` and current-main run `38435558502` succeeded. The intervening #196 and #198 changes do not modify the Bricks style normalizer, Design IR, native styling integration, or controlling style authority.

Before implementation begins, fetch `origin` and compare its current SHA and tree with the exact owner-supplied implementation base. Inspect commits after this plan base. Main movement alone is not a stop; stop only if a commit changes or contradicts the named styling/compiler authorities or owned files. Reconfirm PR #197 ancestry and current-main CI. Stop on any hard-stop condition in the source authority or this plan.

## File structure and layer boundaries

- `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_parser.ex`: generic bounded framing and declaration parsing only. It has no Tango/Romeo semantic IDs and does not mutate DesignNodes.
- `apps/live_frames/lib/live_frames/adapters/bricks/bounded_custom_css_normalizer.ex`: retains the frozen Tango rule table and delegates only reusable framing/declaration work to the parser. Its result gains the smallest explicit claimed-owner set needed by the generic pass.
- `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex`: resolves supported Bricks selector meaning through existing source class/tree relationships and emits base styles, `ResponsiveOverride` values, closed state-rule maps, diagnostics, and inert residual entries. It performs no native CSS rendering.
- `apps/live_frames/lib/live_frames/adapters/bricks/design_ir_normalizer.ex`: runs the bounded Tango pass first, then the generic normalizer, then merges source-neutral results into DesignNodes. A claimed owner is never reinterpreted by the generic pass.
- `apps/live_frames/lib/live_frames/ir/state_rule_set.ex`: pure validation and construction for ordinary JSON-compatible `state_rules` maps. It does not add structs to nested serialized data or change general IR validation.
- `apps/live_frames/lib/live_frames/native_generator/stylesheet_renderer.ex`: serializes safe declarations and inclusive min-only, max-only, and range media conditions; renders only the closed state selector forms.
- `apps/live_frames/lib/live_frames/native_generator/style_integration.ex`: validates state-rule maps and component-boundary topology, resolves private classes through `NodeStyleIdentity`, attaches required owner/target classes, and orchestrates ordinary, responsive, and state rendering.

Keep `apps/live_frames/lib/live_frames/ir/validation.ex` preservation-compatible. Do not add Romeo source fixtures or tests. Use synthetic selectors and source-neutral node names in all new tests.

## Frozen behavior and wire contracts

### Tango ownership and migration

Run `BoundedCustomCssNormalizer.normalize/1` first. Add `claimed_source_ids` as a `MapSet` to its result. When the frozen owner exists in the source tree, mark that source ID claimed before checking its class, topology, effective CSS, or framing. This means the generic pass skips the owner even when the Tango path emits only residual evidence or a topology/class diagnostic. This metadata does not change existing styles, residual strings, diagnostics, or Tango output. The generic normalizer receives the set from that existing result and processes only unclaimed owners.

Task 1 must leave existing `parse_blocks/1` and `parse_parts/1` outputs and Tango behavior byte-for-byte equivalent. If extraction requires changing the frozen semantic table, stop the task and report the unresolved parser boundary.

### Bounded parser and generic source-selector subset

The parser preserves source order and each complete raw rule. It frames flat qualified rule blocks and bounded `@media` blocks with min-width, max-width, or both numeric bounds. A media rule is representable only when each threshold is finite and non-negative and the lower bound does not exceed the upper bound. It accepts comma-separated closed selector groups only when every member parses and resolves. It parses ordinary declaration blocks without applying semantic normalization.

Use a balanced-brace scanner with explicit framing states; do not parse whole CSS with a regex. Unsupported at-rules, nested unknown constructs, malformed framing, pseudo-elements, unsupported pseudo-classes, unsupported combinators, invalid declaration framing, and unsupported selectors remain atomic residuals. The normalizer's source selector grammar is limited to source class compounds separated by descendant whitespace, with at most one `:hover` or `:focus-within` on the owner compound. A conditionless simple class resolves to a target node; a conditionless descendant chain resolves to its final node only when the source class ancestry maps uniquely. A browser-state selector resolves its first compound as the state owner and its final compound as self or descendant target. Every comma-group member must resolve under the same rules. Other syntax fails closed.

The normalizer maps classes through existing Bricks class-resolution and tree data, never through hard-coded class strings or IDs. A target set must be non-empty and unambiguous. A rule is atomic across all selectors and declarations: if any member is unsupported, unresolved, unsafe, colliding, or ambiguous, retain the complete source rule as residual and apply none of its declarations.

### Style placement, collision, and overlap policy

- No browser condition and no viewport: put safe declarations on each target's `DesignNode.styles`.
- No browser condition and a resolved viewport: put declarations on each target's existing `responsive` map as a resolved `ResponsiveOverride` using `min_width` and `max_width`.
- Browser state: store a JSON-compatible `complex_css` value of type `state_rules` on the state-owning node under `custom-css`.
- Unsupported, unresolved, unsafe, ambiguous, or colliding rule: preserve the whole rule as inert residual evidence.

Never synthesize `condition="default"`; never overwrite an existing base or same-key responsive property. Use responsive keys `custom_min_<dimension>`, `custom_max_<dimension>`, and `custom_range_<min>_<max>`. Canonical dimensions are finite decimal text, omit trailing `.0`, and replace `.` with `p`. A key collision fails closed. Compare candidates by target node, property, inclusive interval, and normalized value before committing them. Missing min/max bounds mean unbounded lower/upper ends. Different values for the same target/property in intersecting inclusive intervals fail closed, including min/max intervals that meet at their shared endpoint. Retain all involved complete source rules as residual, remove their candidate styles, and emit `style.conditionless_responsive_overlap_conflict`. Exact interval/value duplicates may deduplicate deterministically. Do not add an order field or infer source/map/min/max precedence. An overlap with an existing responsive value of different or unresolved authority also fails closed.

### Closed `state_rules` JSON data

`LiveFrames.IR.StateRuleSet` validates and constructs ordinary JSON maps with exactly these top-level keys:

```json
{
  "type": "state_rules",
  "rules": [
    {
      "condition": "hover",
      "target_node_id": "node_000001_000001",
      "declarations": {"opacity": {"kind": "literal", "value": 1}},
      "viewport": null,
      "order": 0
    }
  ],
  "residual": []
}
```

`rules` is non-empty. Each rule has exactly `condition`, `target_node_id`, `declarations`, `viewport`, and `order`. Conditions are the strings `hover` or `focus_within`; `focus_visible` remains the existing accessibility path. `target_node_id` is a non-empty resolved node ID. `declarations` is non-empty and uses safe CSS property strings. `viewport` is `null` or an object with exactly `min_width` and `max_width`; each value is `null` or a finite non-negative number, and at least one bound is numeric. `order` is a unique non-negative integer. Assign zero-based order after expansion by original stylesheet rule order, condition order (`hover` before `focus_within`), then canonical numeric DesignNode traversal path.

Each tagged declaration value is an object with exactly `kind` and `value`. Allowed kinds are `literal`, `keyword`, `token_ref`, and `calculation`. Literal values are strings or finite JSON numbers. Keyword and token-ref values are non-empty strings. Calculation accepts only the existing structured multiply form in `docs/03_DESIGN_IR_SPEC.md`. Reject unknown keys, malformed tagged values, `complex_css`, `responsive`, `unresolved`, and unsupported calculation forms. The generator validates each JSON map, converts allowed tags through a closed mapping to existing `StyleValue` structs, then uses `StyleValueCSS`; never derive atoms from input.

Residual is a list of exact two-key objects: `reason` and `source_text`. Reasons are `ambiguous_selector`, `malformed_block`, `responsive_collision`, `responsive_overlap_conflict`, `style_collision`, `unresolved_target`, `unresolved_value`, `unsupported_declaration`, `unsupported_selector`, or `unsafe_declaration`. `source_text` is inert evidence. When at least one state rule is generatable, the single `custom-css` value contains both `rules` and `residual`. If no state rule is generatable but residual text remains, preserve the existing `type="custom_css"` shape. Never put competing values under `custom-css`.

### Rendering and lifecycle boundaries

Resolved responsive rendering supports min-only, max-only, and bounded min/max inclusive media queries. Preserve the existing broader-max-before-narrower-max order and same-width merge behavior. Reject unresolved authority, invalid/negative/non-finite thresholds, invalid ranges, and conflicting overlapping values. Add no `ResponsiveOverride.order` field.

The state owner is the containing DesignNode. The target must equal that owner or be its descendant, and both nodes must lie inside the selected component boundary. Reject missing, ambiguous, sibling, ancestor, or outside-boundary targets. Resolve owner and target private classes only from `NodeStyleIdentity`. Emit only `.owner:hover`, `.owner:hover .target`, `.owner:focus-within`, and `.owner:focus-within .target`, with optional exact inclusive viewport wrappers. Add generated classes to owner and target nodes even when one has no ordinary declarations. No source class or source selector appears in package CSS.

The generator validates and renders only `rules`. It ignores residual entries completely and never parses or serializes their text. Unknown complex CSS subtypes and residual-only raw `custom_css` remain non-generatable. Existing primary-action `:focus-visible` output remains intact. Never reproduce source `outline: 0` or `box-shadow: none`; visible focus remains on the actual focusable control or link. These browser conditions have no managed application lifecycle, side effects, cleanup, or persistence.

## Task 1: Generic custom-CSS parsing foundation

**Files:**

- Create: `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_parser.ex`
- Modify: `apps/live_frames/lib/live_frames/adapters/bricks/bounded_custom_css_normalizer.ex`
- Create: `apps/live_frames/test/live_frames/bricks_custom_css_parser_test.exs`
- Test: `apps/live_frames/test/live_frames/bricks_bounded_custom_css_normalizer_test.exs`

- [ ] **Step 1: Write failing parser and compatibility tests.** Cover ordered flat frames, declarations, closed comma groups, bounded min/max/range media frames, malformed/unclosed blocks, nested unknown constructs, arbitrary at-rules, unsupported media conditions, duplicate declarations, and atomic raw-source retention. Pin the existing Tango parser results and all current frozen normalization/residual assertions before extraction.
- [ ] **Step 2: Run the focused tests and prove RED.** Run `mix test apps/live_frames/test/live_frames/bricks_custom_css_parser_test.exs apps/live_frames/test/live_frames/bricks_bounded_custom_css_normalizer_test.exs`. The new parser contract must fail because `CustomCssParser` does not exist; the pre-existing Tango assertions must still pass.
- [ ] **Step 3: Implement the minimum parser and extraction.** Move reusable framing/declaration parsing into `CustomCssParser`; keep ordered raw frames and bounded viewport metadata. Make `BoundedCustomCssNormalizer.parse_blocks/1` and `parse_parts/1` delegate while preserving their exact return shapes and keep the Tango selector/semantic table unchanged.
- [ ] **Step 4: Re-run and prove GREEN.** Run the same focused command. Confirm parser tests pass and all pre-existing Tango style, residual, and diagnostic expectations are unchanged.
- [ ] **Step 5: Run relevant regressions.** Run `mix test apps/live_frames/test/live_frames/bricks_bounded_custom_css_normalizer_test.exs apps/live_frames/test/live_frames/bricks_design_ir_test.exs` and compare the frozen Tango normalized output and residual strings byte-for-byte against the pre-extraction assertions.
- [ ] **Step 6: Commit the task.** `git add apps/live_frames/lib/live_frames/adapters/bricks/custom_css_parser.ex apps/live_frames/lib/live_frames/adapters/bricks/bounded_custom_css_normalizer.ex apps/live_frames/test/live_frames/bricks_custom_css_parser_test.exs apps/live_frames/test/live_frames/bricks_bounded_custom_css_normalizer_test.exs && git commit -S -m "feat: add bounded Bricks custom CSS parser"`.

Stop this task if extraction requires changing the frozen Tango semantic table or changes accepted Tango normalized styles, residuals, or diagnostics.

## Task 2: Generic conditionless and state normalization

**Files:**

- Create: `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex`
- Modify: `apps/live_frames/lib/live_frames/adapters/bricks/bounded_custom_css_normalizer.ex`
- Modify: `apps/live_frames/lib/live_frames/adapters/bricks/design_ir_normalizer.ex`
- Create: `apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`
- Test: `apps/live_frames/test/live_frames/bricks_design_ir_test.exs`

- [ ] **Step 1: Write failing normalization and integration tests.** Use synthetic classes and Bricks nodes. Cover base relocation, min/max/range relocation, safe selector and declaration handling, base-style collision, responsive-key collision, inclusive overlap conflict and removal of every involved rule, exact duplicate deduplication, unsupported selector/declaration, malformed framing, whole-rule atomic rejection, deterministic state order, self/descendant owner targets, sibling/ancestor/outside-boundary rejection, and mixed normalized rules with inert residual. Assert no `default` condition is created.
- [ ] **Step 2: Run the focused tests and prove RED.** Run `mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs apps/live_frames/test/live_frames/bricks_design_ir_test.exs`. New generic cases must fail because the generic normalizer and claimed-owner contract are absent; the existing bounded Tango tests must remain green.
- [ ] **Step 3: Implement the generic pass and exact Tango migration boundary.** Add `claimed_source_ids: MapSet.new()` to the bounded result and mark the frozen owner claimed as soon as it exists in the tree. Run the bounded pass first. Pass its claimed set to the generic normalizer and skip every claimed owner, including owners whose bounded path ends in residual or topology/class diagnostics. Resolve remaining selectors through existing class/tree indexes, normalize complete rules atomically, apply base/responsive styles only without collisions, create closed JSON state-rule candidates on the state owner, and preserve unsupported source as residual with stable diagnostics.
- [ ] **Step 4: Run the focused tests and prove GREEN.** Re-run the focused command. Confirm claimed Tango owners are not generically reinterpreted, including residual and topology-failure cases, and synthetic unclaimed owners normalize as specified.
- [ ] **Step 5: Run relevant regressions.** Run `mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs apps/live_frames/test/live_frames/bricks_bounded_custom_css_normalizer_test.exs apps/live_frames/test/live_frames/bricks_design_ir_test.exs apps/live_frames/test/live_frames/bricks_structured_styles_test.exs`. Existing Tango Design IR output, ordinary styles, and responsive records must remain unchanged.
- [ ] **Step 6: Commit the task.** `git add apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex apps/live_frames/lib/live_frames/adapters/bricks/bounded_custom_css_normalizer.ex apps/live_frames/lib/live_frames/adapters/bricks/design_ir_normalizer.ex apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs apps/live_frames/test/live_frames/bricks_design_ir_test.exs && git commit -S -m "feat: normalize generic Bricks custom CSS"`.

## Task 3: Closed state-rule wire validation

**Files:**

- Create: `apps/live_frames/lib/live_frames/ir/state_rule_set.ex`
- Create: `apps/live_frames/test/live_frames/ir/state_rule_set_test.exs`
- Test: `apps/live_frames/test/live_frames/ir_test.exs`
- Test: `apps/live_frames/test/live_frames/native_generator/style_value_css_test.exs`

- [ ] **Step 1: Write failing validator and constructor tests.** Cover valid hover and focus-within rules, null and min/max viewport values, unique non-negative order, exact top-level/rule/declaration/viewport/residual keys, every allowed residual reason, malformed residuals, unknown condition/key, empty rules/declarations, invalid bounds, duplicate order, and safe literal/keyword/token-ref/structured-multiply tagged values. Reject nested `complex_css`, `responsive`, `unresolved`, legacy calculation strings, non-finite numbers, and malformed tagged maps.
- [ ] **Step 2: Run the focused tests and prove RED.** Run `mix test apps/live_frames/test/live_frames/ir/state_rule_set_test.exs apps/live_frames/test/live_frames/ir_test.exs`. New subtype tests must fail because `StateRuleSet` is not defined.
- [ ] **Step 3: Implement the pure JSON-map boundary.** Add `new/1` and `validate/1` or equivalent named functions that accept and return ordinary JSON-compatible maps. Enforce exact keys and closed values without adding a serialized struct or changing `LiveFrames.IR.Validation` behavior for generic `complex_css`.
- [ ] **Step 4: Run the focused tests and prove GREEN.** Re-run the focused command and confirm valid state-rule maps pass while every malformed or unknown subtype case fails closed.
- [ ] **Step 5: Run relevant regressions.** Run `mix test apps/live_frames/test/live_frames/ir_test.exs apps/live_frames/test/live_frames/native_generator/style_value_css_test.exs apps/live_frames/test/live_frames/bricks_design_ir_test.exs`. Existing arbitrary-but-JSON `complex_css` preservation and IR 4.0.0 serialization must remain intact.
- [ ] **Step 6: Commit the task.** `git add apps/live_frames/lib/live_frames/ir/state_rule_set.ex apps/live_frames/test/live_frames/ir/state_rule_set_test.exs apps/live_frames/test/live_frames/ir_test.exs && git commit -S -m "feat: validate closed state rule maps"`.

## Task 4: Generic responsive CSS rendering

**Files:**

- Modify: `apps/live_frames/lib/live_frames/native_generator/stylesheet_renderer.ex`
- Test: `apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs`

- [ ] **Step 1: Write failing responsive tests.** Cover max-only, min-only, bounded min/max inclusive media, zero thresholds, invalid/reversed/negative/non-finite bounds, unresolved authority, same exact-width merging, conflicting same-width values, inclusive overlap conflicts, deterministic mixed-interval rendering, and identical repeat output. Keep existing max-width expected output assertions unchanged.
- [ ] **Step 2: Run the focused tests and prove RED.** Run `mix test apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs`. Min-only, bounded ranges, and new interval validation must fail against the current max-only renderer.
- [ ] **Step 3: Implement minimum interval rendering.** Render only resolved `ResponsiveOverride` values with finite non-negative inclusive bounds. Keep the legacy broader-max-before-narrower-max ordering and same-width merge behavior. Give min-only and range rules deterministic canonical order. Reject invalid ranges and different values for the same property over intersecting inclusive intervals; do not add an order field or pick a map/source/min/max winner.
- [ ] **Step 4: Run the focused tests and prove GREEN.** Re-run the renderer suite and verify all new interval cases pass while max-only output bytes and order stay unchanged.
- [ ] **Step 5: Run relevant regressions.** Run `mix test apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs apps/live_frames/test/live_frames/native_generator/style_integration_test.exs apps/live_frames/test/live_frames/fidelity_responsive_test.exs apps/live_frames/test/live_frames/responsive/design_document_resolver_test.exs`. Existing ordinary responsive and fidelity media ordering must remain unchanged.
- [ ] **Step 6: Commit the task.** `git add apps/live_frames/lib/live_frames/native_generator/stylesheet_renderer.ex apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs && git commit -S -m "feat: render resolved responsive ranges"`.

## Task 5: State-rule native integration

**Files:**

- Modify: `apps/live_frames/lib/live_frames/native_generator/style_integration.ex`
- Modify: `apps/live_frames/lib/live_frames/native_generator/stylesheet_renderer.ex`
- Test: `apps/live_frames/test/live_frames/native_generator/style_integration_test.exs`
- Test: `apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs`

- [ ] **Step 1: Write failing topology and output tests.** Cover owner self/descendant hover and focus-within, viewport-scoped state rules, state-rule order, owner/target private class assignment including unstyled targets, missing/sibling/ancestor/outside-component targets, malformed and unknown complex CSS subtype blocking, residual-only raw `custom_css` blocking, mixed residual exclusion, unsafe declaration blocking, no source class leakage, and unchanged focus-visible output.
- [ ] **Step 2: Run the focused tests and prove RED.** Run `mix test apps/live_frames/test/live_frames/native_generator/style_integration_test.exs apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs`. New state-rule cases must fail because the integration path does not consume this subtype.
- [ ] **Step 3: Implement closed native integration.** Validate JSON maps with `StateRuleSet`; derive component ancestry from the one-time `NodeStyleIdentity` path index; require owner and target within the boundary and target self/descendant; resolve only generated private classes; assign classes to every emitted owner/target; convert safe tagged declaration values through the closed `StyleValue` mapping and existing `StyleValueCSS`; render only the four authorized selectors with optional viewport wrappers. Render `rules` only and ignore `residual` entirely. Keep the primary-action `:focus-visible` path and visible focus declarations unchanged.
- [ ] **Step 4: Run the focused tests and prove GREEN.** Re-run both focused suites and verify no residual bytes or source selectors/classes appear in generated CSS.
- [ ] **Step 5: Run relevant regressions.** Run `mix test apps/live_frames/test/live_frames/native_generator/style_integration_test.exs apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs apps/live_frames/test/live_frames/native_generator/style_value_css_test.exs apps/live_frames/test/live_frames/native_generator_test.exs`. Existing `:focus-visible`, image style loci, primary-action selectors, and ordinary styles must remain unchanged.
- [ ] **Step 6: Commit the task.** `git add apps/live_frames/lib/live_frames/native_generator/style_integration.ex apps/live_frames/lib/live_frames/native_generator/stylesheet_renderer.ex apps/live_frames/test/live_frames/native_generator/style_integration_test.exs apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs && git commit -S -m "feat: render closed browser state rules"`.

## Task 6: End-to-end generic proof and regression gate

**Files:**

- Create: `apps/live_frames/test/live_frames/native_generator/stateful_style_pipeline_test.exs`
- Test: `apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`
- Test: `apps/live_frames/test/live_frames/native_generator/style_integration_test.exs`
- Test: `apps/live_frames/test/live_frames/bricks_bounded_custom_css_normalizer_test.exs`

- [ ] **Step 1: Write a failing source-neutral end-to-end test.** Use a synthetic owner card and descendant heading/content with conditionless base styles, min/max/range-responsive styles, hover, focus-within, and one unsupported inert residual. Run the adapter into Design IR, then through the native generator. Assert normalized node styles and responsive overrides, closed state-rule JSON, only private owner/target selectors in output, no residual text, deterministic bytes, and no source-specific constants.
- [ ] **Step 2: Run the focused test and prove RED.** Run `mix test apps/live_frames/test/live_frames/native_generator/stateful_style_pipeline_test.exs`. It must fail because the complete adapter-to-generator capability does not yet exist.
- [ ] **Step 3: Implement only integration fixes required by the failing test.** Do not add Romeo branches, component contracts, componentization plans, arbitrary selector support, new IR fields, or runtime behavior.
- [ ] **Step 4: Run the focused test and prove GREEN.** Re-run the pipeline test twice and verify identical serialized IR and stylesheet output.
- [ ] **Step 5: Run all focused suites, then the repository gates.** First run the parser, generic normalizer, Tango normalizer, state-rule, renderer, style-integration, IR, and synthetic pipeline tests. Then run:

  ```bash
  mix deps.get
  mix format --check-formatted
  mix compile --warnings-as-errors
  mix assets.build
  mix test
  mix deps.unlock --check-unused
  git diff --check
  ```

  Also run the repository's CI styling/artifact drift checks if they are separate from `mix assets.build`. Report every skipped gate and its reason. Do not suppress or weaken any failing gate.
- [ ] **Step 6: Review the complete diff and commit the task.** Confirm only authorized generic parser, normalizer, IR validator, generator, and synthetic tests changed. Run `git status --short` and `git diff --check`, inspect the complete diff, then commit with `git add apps/live_frames/test/live_frames/native_generator/stateful_style_pipeline_test.exs && git commit -S -m "test: prove generic stateful style pipeline"` plus any explicitly required integration fixes.

## Explicit non-goals

```text
FEATURE_ROMEO_COMPONENTIZATION=NOT_AUTHORIZED
FEATURE_ROMEO_NATIVE_GENERATION=NOT_AUTHORIZED
FEATURE_ROMEO_BROWSER_ACCEPTANCE=NOT_IN_SCOPE

BEHAVIOR_CONTRACT_RUNTIME=NOT_REQUIRED
JAVASCRIPT_HOOKS=NOT_REQUIRED

DESIGN_IR_VERSION_CHANGE=NOT_AUTHORIZED
ARBITRARY_CSS_SELECTOR_ENGINE=NOT_AUTHORIZED
GENERAL_CSS_CASCADE_ENGINE=NOT_AUTHORIZED
```

Romeo remains only authority/tracer context and a later acceptance target. No Romeo fixture, source class, source ID, component, contract, or production branch belongs in the implementation slice.

## Plan self-review

- **Spec coverage:** Tasks 1–6 cover parser extraction, generic normalization, claimed Tango ownership, the exact state-rule JSON contract, resolved interval rendering, topology validation, residual coexistence, accessibility preservation, synthetic end-to-end proof, and repository gates.
- **Step granularity:** Each task uses an explicit failing test, focused RED run, minimum implementation, focused GREEN run, regression run, and signed commit.
- **Type and interface consistency:** The parser returns ordered source frames/residuals; the bounded result exposes a `MapSet` of claimed source IDs; the generic pass consumes that set; state rules remain JSON maps; responsive data uses existing `ResponsiveOverride`; generation consumes DesignNode IDs and private classes from `NodeStyleIdentity`.
- **Review-focus tests:** Every risk in the Review Focus maps to a named scenario and owner task above.
- **Plan/code proportion:** The document fixes boundaries, data shapes, failure rules, and test evidence. It leaves implementation bodies to the coding phase except where exact parsing, overlap, ordering, ownership, or selector behavior would otherwise be ambiguous.

Before implementation-plan approval, run the required prohibited-architecture search against this file, then run `git diff --check` and `git status --short`. Any source-specific names may appear only as authority/tracer context or explicit non-goals; no source-specific implementation input or executable-source pattern may appear. Confirm that the PR changes only this plan file. The plan is complete only when each task gives a coding agent a concrete file boundary, test command, RED/GREEN expectation, regression set, and commit point.
