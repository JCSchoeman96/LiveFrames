# Generic stateful style implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task by task. Steps use checkbox syntax for tracking.

**Goal:** Add a bounded, source-neutral Bricks CSS normalization and native rendering capability for conditionless, responsive, hover, and focus-within styles.

**Architecture:** Parse source CSS with a bounded Bricks parser, resolve supported selector meaning to normalized DesignNode relationships, and store safe declarations in existing style and responsive IR or the closed `complex_css` `state_rules` subtype. The native generator resolves owner and target identities with `NodeStyleIdentity`, validates component topology, and emits only closed package-private selectors through the existing `StyleValueCSS` serializer.

**Tech Stack:** Elixir umbrella application, Mix, ExUnit, existing Bricks adapters, Design IR 4.0.0, `ResponsiveOverride`, `NodeStyleIdentity`, `StyleValueCSS`, and `StylesheetRenderer`.

**Spec:** `docs/development/feature_romeo_css_style_authority.md` controls this plan. `docs/development/feature_romeo_source_semantics_authority.md`, `docs/development/c09d6_native_generation_authority.md`, `docs/development/c09d6d_upstream_style_gap_resolution_authority.md`, and the listed LiveFrames specifications define adjacent boundaries. The accepted source-neutral wire contract and fail-closed rules below are binding for every task.

**Global Constraints:**

- This plan does not authorize implementation. The implementation phase requires a separate owner gate after review of this plan PR.
- Keep the accepted `BoundedCustomCssNormalizer` rule table frozen to CTA Tango. The generic pass must skip every source owner claimed by that pass.
- Derive a transient pointer-state alias only from the exact paired inert Bricks interaction records defined below. The alias is per effective owner, exists only during selector normalization, and never becomes IR/native/public class authority.
- Keep `DesignDocument.ir_version` at `4.0.0`. Do not make general `LiveFrames.IR.Validation` reject previously preservable `complex_css` values.
- Treat imported JSON and CSS as inert, untrusted data. Never evaluate CSS or source runtime, convert source strings to atoms, or perform dynamic module/function lookup.
- Never add source IDs, source classes, source selectors, or Romeo-specific production branches/constants. Componentization must receive source-neutral IR only.
- Reuse `StyleValueCSS`, safe CSS property validation, `TokenBridge`, existing `ResponsiveOverride` fields, and `NodeStyleIdentity`. Do not create a second CSS value serializer, selector engine, or general cascade engine.
- Keep unsupported or conflicting rules atomic and inert. Residual text never reaches native selector or value generation.
- Keep hover and focus-within as ephemeral browser CSS conditions. Add no BehaviorContract runtime, JavaScript hooks, server state, persistence, polling, database, network, Redis, Postgres, PubSub, GenServer, or Oban work.
- Keep analysis linear or near-linear in bounded source rules and normalized nodes. Build source-ID-to-node, node-ID-to-node, and node-ID-to-ancestry/private-class indexes once per compilation.
- Scope the implementation phase to the seven tasks below. Run each task's tests first, prove RED, implement the minimum, prove GREEN, run its regressions, and commit before starting the next task.

**Review Focus:**

1. A transient pointer class is not treated as an ordinary/static class or emitted as selector authority. Task 2 tests exact paired proof, and Task 3 tests hover alias consumption.
2. A historical Tango source ID cannot suppress generic compilation without frozen class identity proof. Task 3 tests wrong-class, topology-mismatch, residual, and consumed cases.
3. New interval conflict checks cannot break the accepted max-only cascade. Tasks 3 and 5 test custom-CSS overlap rejection separately from the existing 991px/767px renderer order.
4. Repeated shared global CSS resolves only within each effective owner's subtree. Task 3 tests two sibling owners and same-class descendants.
5. Residual source text never enters native output. Tasks 4 and 6 test mixed normalized/residual data and assert residual text is absent from CSS.
6. A state target cannot escape its effective owner subtree or component boundary. Tasks 3 and 6 test self, descendant, sibling, ancestor, missing, and outside-boundary targets.
7. Existing Tango output, `:focus-visible`, and ordinary responsive CSS remain unchanged. Tasks 1, 3, 5, 6, and 7 run their named regression suites and assert those outputs.

---

## Accepted entry state and movement check

The plan was created on `origin/main` at `51d958e05627e7291b57d75f857cdf4332e37814`, tree `20c5f0851d7c7c615c3ec46a444a68077361dd01`. PR #197 merge `3f91039beccbb533da839e9ce47b8cd9e23d962a`, tree `680f6e14e38f704d188fc833a62d8a31e3283546`, and approved head `7bbcdae…` are in its ancestry. Post-merge run `38435499252` and current-main run `38435558502` succeeded. The intervening #196 and #198 changes do not modify the Bricks style normalizer, Design IR, native styling integration, or controlling style authority. The adapter's `Element.settings` retains the inert JSON settings map, including a source `_interactions` list when present, and `Element.raw` retains the original element map. The source interaction resolver can inspect that data without executing it.

Before implementation begins, fetch `origin` and compare its current SHA and tree with the exact owner-supplied implementation base. Inspect commits after this plan base. Main movement alone is not a stop; stop only if a commit changes or contradicts the named styling/compiler authorities or owned files. Reconfirm PR #197 ancestry and current-main CI. Stop on any hard-stop condition in the source authority or this plan.

## File structure and layer boundaries

- `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_parser.ex`: generic bounded framing and declaration parsing only. It has no Tango/Romeo semantic IDs and does not mutate DesignNodes.
- `apps/live_frames/lib/live_frames/adapters/bricks/transient_style_state.ex`: reads inert `_interactions` records on an effective source owner and derives only the closed transient class-to-hover alias. It does not execute actions, mutate nodes, or render CSS.
- `apps/live_frames/lib/live_frames/adapters/bricks/bounded_custom_css_normalizer.ex`: retains the frozen Tango rule table and delegates only reusable framing/declaration work to the parser. Its result gains the smallest explicit claimed-owner set needed by the generic pass.
- `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex`: processes one effective custom-CSS owner node at a time, resolves supported selectors only in that owner's self/descendant subtree, consumes proven transient aliases, and emits base styles, `ResponsiveOverride` values, closed state-rule maps, diagnostics, and inert residual entries. It performs no native CSS rendering.
- `apps/live_frames/lib/live_frames/adapters/bricks/design_ir_normalizer.ex`: runs the bounded Tango pass first, then the generic normalizer, then merges source-neutral results into DesignNodes. A claimed owner is never reinterpreted by the generic pass.
- `apps/live_frames/lib/live_frames/ir/state_rule_set.ex`: pure validation and construction for ordinary JSON-compatible `state_rules` maps. It does not add structs to nested serialized data or change general IR validation.
- `apps/live_frames/lib/live_frames/native_generator/stylesheet_renderer.ex`: serializes safe declarations and inclusive min-only, max-only, and range media conditions; renders only the closed state selector forms.
- `apps/live_frames/lib/live_frames/native_generator/style_integration.ex`: validates state-rule maps and component-boundary topology, resolves private classes through `NodeStyleIdentity`, attaches required owner/target classes, and orchestrates ordinary, responsive, and state rendering.

Keep `apps/live_frames/lib/live_frames/ir/validation.ex` preservation-compatible. Do not add Romeo source fixtures or tests. Use synthetic selectors and source-neutral node names in all new tests.

## Frozen behavior and wire contracts

### Tango ownership and migration

Run `BoundedCustomCssNormalizer.normalize/1` first. Add `claimed_source_ids` as a `MapSet` to its result. Claim the historical source ID only when the existing frozen class-reference check proves both the exact frozen Tango class ID and class name on the resolved owner. Compute this claim as a read-only predicate independent of topology, effective CSS, framing, and successful style conversion. A wrong or unresolved class identity leaves that source node eligible for the generic pass. Once the identity is proven, keep it claimed through topology mismatch, residual CSS, framing failure, or no generatable style. Do not change existing Tango diagnostic or output order. The generic normalizer receives this set and processes only unclaimed owners.

```text
TANGO_CLAIM_REQUIRES_FROZEN_CLASS_IDENTITY=YES
WRONG_CLASS_SAME_SOURCE_ID_CLAIMED=NO
```

Task 1 must leave existing `parse_blocks/1` and `parse_parts/1` outputs and Tango behavior byte-for-byte equivalent. If extraction requires changing the frozen semantic table, stop the task and report the unresolved parser boundary.

### Transient source interaction-state resolution

`LiveFrames.Adapters.Bricks.TransientStyleState` inspects the already-loaded, inert `Element.settings["_interactions"]` records and derives ordinary internal aliases for one effective custom-CSS owner. The adapter data retains these records as JSON maps. The resolver never evaluates or reproduces an action, mutates a class, creates an IR interaction, or generates CSS.

Authorize only this exact reversible pair on the same source owner whose effective CSS is being normalized:

```text
trigger="mouseenter", action="setAttribute",
actionAttributeKey="class", actionAttributeValue=X

trigger="mouseleave", action="removeAttribute",
actionAttributeKey="class", actionAttributeValue=X
```

The enter and leave records must use the same exact non-empty class token `X`, belong to the same proven effective owner/class authority, and establish the presentation condition without any additional effect. The resolver returns a per-owner alias equivalent to `X -> hover`. The normalizer may consume `X` only in that owner's current effective CSS. The owner compound without `X` must resolve to the same source owner whose interaction pair proved the alias, and an effective resolved class reference on that owner must supply the CSS value being normalized. It removes `X` while converting the selector to condition `hover`; `X` never enters `DesignNode`, `state_rules`, native classes, or public output. A source token without a proven pair remains an ordinary unsupported selector token and the complete rule becomes residual.

```text
TRANSIENT_CLASS_TO_HOVER_RULE=PROVEN_PAIRED_INTERACTION_ONLY
SOURCE_TRANSIENT_CLASS_HARDCODED=NO
```

Missing enter/leave halves, differing tokens, wrong trigger/action/attribute, contradictory mappings, ambiguous owner authority, or additional effects needed to establish the condition produce no alias. Exact duplicate copies of the same proven pair may deduplicate. A static class name alone never implies hover. Literal source `:focus-within` continues to map directly to `focus_within`.

### Bounded parser and generic source-selector subset

The parser preserves source order and each complete raw rule. It frames flat qualified rule blocks and bounded `@media` blocks with min-width, max-width, or both numeric bounds. A media rule is representable only when each threshold is finite and non-negative and the lower bound does not exceed the upper bound. It accepts comma-separated closed selector groups only when every member parses and resolves. It parses ordinary declaration blocks without applying semantic normalization.

Use a balanced-brace scanner with explicit framing states; do not parse whole CSS with a regex. Unsupported at-rules, nested unknown constructs, malformed framing, pseudo-elements, unsupported pseudo-classes, unsupported combinators, invalid declaration framing, and unsupported selectors remain atomic residuals. The normalizer's source selector grammar is limited to source class compounds separated by descendant whitespace. The owner compound may contain at most one literal `:hover`, one literal `:focus-within`, or one proven per-owner transient class alias, but not multiple state markers. A transient token is allowed only when its exact interaction pair is proven for that effective owner; remove it when producing `condition="hover"`. A conditionless simple class resolves to matching target nodes in scope; a conditionless descendant chain resolves matching final nodes only along source class ancestry in scope. A browser-state selector resolves matching first compounds as state owners and matching final compounds as self or descendant targets. Every comma-group member must resolve under the same rules. Other syntax fails closed.

The normalizer maps classes through existing Bricks class-resolution and tree data, never through hard-coded class strings or IDs. Its normalization unit is one effective `_cssCustom` owner node, with scope equal to that node and its descendant subtree. Resolve each effective CSS value against that subtree only. A class selector means the deterministic set of matching nodes in scope; a descendant chain expands only matching descendant paths within that scope. This permits the same global class and CSS text on sibling owners without cross-owner matches. Every resolved state owner and target must remain inside the effective scope. For a transient alias, the owner compound without the alias must resolve to the same source owner whose interaction pair proved it, and an effective resolved class reference on that owner must supply the CSS value being normalized. Missing or unsupported matches, unresolved class authority, or ambiguous effective ownership retain the complete rule as residual. Parse identical source-layer/blob pairs at most once if useful, but resolve semantics separately for each owner.

```text
CUSTOM_CSS_NORMALIZATION_SCOPE=COMPOSITE_PER_EFFECTIVE_OWNER_VALUE
NORMALIZATION_UNIT=EFFECTIVE_CUSTOM_CSS_OWNER_NODE
SELECTOR_RESOLUTION_SCOPE=EFFECTIVE_OWNER_SELF_OR_DESCENDANT_SUBTREE
```

A rule is atomic across all selectors and declarations: if any member is unsupported, unresolved, unsafe, colliding, or ambiguous, retain the complete source rule as residual and apply none of its declarations. A repeated property in one generic rule is unsupported because this bounded slice does not implement CSS last-declaration-wins behavior. Retain the whole rule with residual reason `unsupported_declaration`. Keep existing Tango parser entrypoint compatibility unchanged.

### Style placement, collision, and overlap policy

- No browser condition and no viewport: put safe declarations on each target's `DesignNode.styles`.
- No browser condition and a resolved viewport: put declarations on each target's existing `responsive` map as a resolved `ResponsiveOverride` using `min_width` and `max_width`.
- Browser state: store a JSON-compatible `complex_css` value of type `state_rules` on the state-owning node under `custom-css`.
- Unsupported, unresolved, unsafe, ambiguous, or colliding rule: preserve the whole rule as inert residual evidence.

Never synthesize `condition="default"`; never overwrite an existing base or same-key responsive property. Use responsive keys `custom_min_<dimension>`, `custom_max_<dimension>`, and `custom_range_<min>_<max>`. Canonical dimensions are finite decimal text, omit trailing `.0`, and replace `.` with `p`. A key collision fails closed. Compare candidates by target node, property, inclusive interval, and normalized value before committing them. Missing min/max bounds mean unbounded lower/upper ends. Different values for the same target/property in intersecting inclusive intervals fail closed, including min/max intervals that meet at their shared endpoint. Retain all involved complete source rules as residual, remove their candidate styles, and emit `style.conditionless_responsive_overlap_conflict`. Exact interval/value duplicates may deduplicate deterministically. Do not add an order field or infer source/map/min/max precedence. An overlap with an existing responsive value of different or unresolved authority also fails closed.

```text
CONDITIONLESS_RESPONSIVE_OVERLAP_LAYER=ADAPTER_NORMALIZATION
DUPLICATE_PROPERTY_IN_ONE_GENERIC_RULE=FAIL_CLOSED
```

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

Resolved responsive rendering supports min-only, max-only, and bounded min/max inclusive media queries. Preserve the existing broader-max-before-narrower-max order and same-width merge behavior. Reject unresolved authority, invalid/negative/non-finite thresholds, and invalid ranges. The renderer continues to allow the accepted overlapping max-only cascade. A different-value conflict involving a newly supported min-only or range interval fails closed when no existing accepted responsive authority defines its order. Conditionless custom-CSS overlap conflicts are checked upstream in `CustomCssNormalizer`. Add no `ResponsiveOverride.order` field.

```text
LEGACY_MAX_ONLY_CASCADE=PRESERVED
GENERAL_CSS_CASCADE_ENGINE=NO
```

The state owner is the containing DesignNode. The target must equal that owner or be its descendant, and both nodes must lie inside the selected component boundary. Reject missing, ambiguous, sibling, ancestor, or outside-boundary targets. Resolve owner and target private classes only from `NodeStyleIdentity`. Emit only `.owner:hover`, `.owner:hover .target`, `.owner:focus-within`, and `.owner:focus-within .target`, with optional exact inclusive viewport wrappers. Add generated classes to owner and target nodes even when one has no ordinary declarations. No source class or source selector appears in package CSS.

The generator validates and renders only `rules`. It ignores residual entries completely and never parses or serializes their text. Unknown complex CSS subtypes and residual-only raw `custom_css` remain non-generatable. Existing primary-action `:focus-visible` output remains intact. Never reproduce source `outline: 0` or `box-shadow: none`; visible focus remains on the actual focusable control or link. These browser conditions have no managed application lifecycle, side effects, cleanup, or persistence.

## Task 1: Generic custom-CSS parsing foundation

**Files:**

- Create: `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_parser.ex`
- Modify: `apps/live_frames/lib/live_frames/adapters/bricks/bounded_custom_css_normalizer.ex`
- Create: `apps/live_frames/test/live_frames/bricks_custom_css_parser_test.exs`
- Test: `apps/live_frames/test/live_frames/bricks_bounded_custom_css_normalizer_test.exs`

- [ ] **Step 1: Write failing parser and compatibility tests.** Cover ordered flat frames, declarations, closed comma groups, bounded min/max/range media frames, malformed/unclosed blocks, nested unknown constructs, arbitrary at-rules, unsupported media conditions, duplicate properties, and atomic raw-source retention. A repeated property in one generic rule must produce one whole-rule reject, not last-declaration-wins output. Pin existing Tango parser results and frozen normalization/residual assertions before extraction.
- [ ] **Step 2: Run the focused tests and prove RED.** Run `mix test apps/live_frames/test/live_frames/bricks_custom_css_parser_test.exs apps/live_frames/test/live_frames/bricks_bounded_custom_css_normalizer_test.exs`. New parser cases must fail because `CustomCssParser` does not exist; existing Tango assertions must still pass.
- [ ] **Step 3: Implement the minimum parser and extraction.** Move reusable framing/declaration parsing into `CustomCssParser`; keep ordered raw frames and bounded viewport metadata. Mark duplicate generic declarations as unsupported and retain the whole frame for residual handling. Make Tango `parse_blocks/1` and `parse_parts/1` delegate while preserving their exact existing return shapes and duplicate-declaration behavior; add a compatibility adapter if the generic parser's fail-closed policy differs. Keep the Tango semantic table unchanged.
- [ ] **Step 4: Re-run and prove GREEN.** Run the same focused command. Confirm generic duplicate-property cases fail closed and all pre-existing Tango style, residual, and diagnostic expectations stay unchanged.
- [ ] **Step 5: Run relevant regressions.** Run `mix test apps/live_frames/test/live_frames/bricks_bounded_custom_css_normalizer_test.exs apps/live_frames/test/live_frames/bricks_design_ir_test.exs`; compare frozen Tango styles and residual strings byte-for-byte with pinned assertions.
- [ ] **Step 6: Commit the task.** `git add apps/live_frames/lib/live_frames/adapters/bricks/custom_css_parser.ex apps/live_frames/lib/live_frames/adapters/bricks/bounded_custom_css_normalizer.ex apps/live_frames/test/live_frames/bricks_custom_css_parser_test.exs apps/live_frames/test/live_frames/bricks_bounded_custom_css_normalizer_test.exs && git commit -S -m "feat: add bounded Bricks custom CSS parser"`.

Stop if extraction requires changing the Tango semantic table or changes accepted Tango normalized styles, residuals, or diagnostics.

## Task 2: Transient source interaction-state resolver

**Files:**

- Create: `apps/live_frames/lib/live_frames/adapters/bricks/transient_style_state.ex`
- Create: `apps/live_frames/test/live_frames/bricks_transient_style_state_test.exs`
- Test: `apps/live_frames/test/live_frames/bricks_design_ir_test.exs`

- [ ] **Step 1: Write failing resolver tests.** Use an arbitrary synthetic token. Cover a paired enter/set plus leave/remove record producing one per-owner hover alias; missing leave; different tokens; wrong action; wrong attribute; a static class with no pair; contradictory mappings; ambiguous effective owner/class authority; and unrelated inert action data that does not establish the alias. Confirm that resolution reads JSON maps and does not mutate source settings or create Design IR interactions.
- [ ] **Step 2: Run the focused tests and prove RED.** Run `mix test apps/live_frames/test/live_frames/bricks_transient_style_state_test.exs apps/live_frames/test/live_frames/bricks_design_ir_test.exs`. The resolver cases must fail because `TransientStyleState` does not exist; existing Design IR behavior must remain green.
- [ ] **Step 3: Implement the pure alias resolver.** Read `Element.settings["_interactions"]` as inert data. Accept only the exact paired trigger/action/attribute/value pattern on the same owner whose effective custom CSS and resolved owner class authority are proven. Require the owner class compound without the transient token to resolve to that same owner. Return an internal per-owner alias map only; do not mutate settings, construct BehaviorContract data, or reproduce set/remove actions.
- [ ] **Step 4: Run the focused tests and prove GREEN.** Re-run the focused command. Confirm only the exact same-token pair yields the alias and every incomplete, contradictory, ambiguous, or unsupported case yields no alias.
- [ ] **Step 5: Run relevant regressions.** Run `mix test apps/live_frames/test/live_frames/bricks_transient_style_state_test.exs apps/live_frames/test/live_frames/bricks_frontend_binding_test.exs apps/live_frames/test/live_frames/bricks_design_ir_test.exs`. Existing value bindings, node actions, and Design IR interactions must remain unchanged.
- [ ] **Step 6: Commit the task.** `git add apps/live_frames/lib/live_frames/adapters/bricks/transient_style_state.ex apps/live_frames/test/live_frames/bricks_transient_style_state_test.exs && git commit -S -m "feat: resolve transient Bricks style states"`.

If the loaded adapter model cannot expose enough inert data to prove the closed pair, stop with `TRANSIENT_POINTER_STATE_EVIDENCE_UNAVAILABLE`; do not add a source-token exception.

## Task 3: Generic conditionless and state normalization

**Files:**

- Create: `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex`
- Modify: `apps/live_frames/lib/live_frames/adapters/bricks/bounded_custom_css_normalizer.ex`
- Modify: `apps/live_frames/lib/live_frames/adapters/bricks/design_ir_normalizer.ex`
- Modify: `apps/live_frames/lib/live_frames/adapters/bricks/transient_style_state.ex`
- Create: `apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`
- Test: `apps/live_frames/test/live_frames/bricks_bounded_custom_css_normalizer_test.exs`
- Test: `apps/live_frames/test/live_frames/bricks_design_ir_test.exs`

- [ ] **Step 1: Write failing normalizer and integration tests.** Cover base/min/max/range relocation; selector use of a proven transient token becoming `hover` with that token absent from state data; literal `:focus-within`; an unproven token remaining residual; base-style and responsive-key collisions; inclusive conflicting custom-CSS overlap with all involved rules removed; exact interval/value duplicate deduplication; unsupported selector/declaration; duplicate property in one rule; malformed framing; atomic rejection; and deterministic state order. Add Tango claim cases: same historical ID with wrong class is unclaimed and generic-eligible; proven class with topology mismatch, residual CSS, and consumed CSS remains claimed. Add two sibling effective owners with identical shared global CSS and same-class descendants; prove each owner resolves only its own descendant, with no cross-owner target or collision. Cover self/descendant state owner relationships and sibling/ancestor/out-of-scope selector rejection.
- [ ] **Step 2: Run the focused tests and prove RED.** Run `mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs apps/live_frames/test/live_frames/bricks_bounded_custom_css_normalizer_test.exs apps/live_frames/test/live_frames/bricks_design_ir_test.exs`. The generic normalizer and identity-scoped claim cases must fail; the existing Tango suite must remain green.
- [ ] **Step 3: Implement the generic owner-scoped pass and Tango claim rule.** Add `claimed_source_ids` to the bounded result. Populate it only when the existing frozen class-reference check proves the exact frozen ID and name, independent of topology or conversion success. Run the Tango pass first and skip those claimed owners in the generic pass. For every unclaimed effective custom-CSS owner node, get its effective value through existing style precedence, obtain its per-owner transient aliases, and resolve selectors only within that owner and its descendant subtree. Expand deterministic matching nodes in that scope. Apply each complete base or responsive rule only when every selector/declaration is safe and no collision exists. Check all custom-CSS responsive candidates by target, property, inclusive interval, and normalized value before committing them; fail closed on conflicting overlaps and remove all contributions from involved rules. Convert state selectors only when literal `:focus-within` or the owner's proven transient alias establishes the closed condition. Preserve whole unsupported rules as residual.
- [ ] **Step 4: Run the focused tests and prove GREEN.** Re-run the focused command. Confirm wrong-class ID collisions remain generic-eligible, genuine Tango owners never run twice, repeated shared CSS stays within each owner's subtree, and transient tokens never enter normalized state data.
- [ ] **Step 5: Run relevant regressions.** Run `mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs apps/live_frames/test/live_frames/bricks_transient_style_state_test.exs apps/live_frames/test/live_frames/bricks_bounded_custom_css_normalizer_test.exs apps/live_frames/test/live_frames/bricks_design_ir_test.exs apps/live_frames/test/live_frames/bricks_structured_styles_test.exs`. Existing Tango IR, ordinary styles, responsive records, and frontend bindings must remain unchanged.
- [ ] **Step 6: Commit the task.** `git add apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex apps/live_frames/lib/live_frames/adapters/bricks/bounded_custom_css_normalizer.ex apps/live_frames/lib/live_frames/adapters/bricks/design_ir_normalizer.ex apps/live_frames/lib/live_frames/adapters/bricks/transient_style_state.ex apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs apps/live_frames/test/live_frames/bricks_bounded_custom_css_normalizer_test.exs apps/live_frames/test/live_frames/bricks_design_ir_test.exs && git commit -S -m "feat: normalize generic Bricks custom CSS"`.

## Task 4: Closed state-rule wire validation

**Files:**

- Create: `apps/live_frames/lib/live_frames/ir/state_rule_set.ex`
- Create: `apps/live_frames/test/live_frames/ir/state_rule_set_test.exs`
- Test: `apps/live_frames/test/live_frames/ir_test.exs`
- Test: `apps/live_frames/test/live_frames/native_generator/style_value_css_test.exs`

- [ ] **Step 1: Write failing validator and constructor tests.** Cover valid hover and focus-within rules, null and bounded viewport values, unique non-negative order, exact keys at every level, all allowed residual reasons, malformed residuals, unknown condition/key, empty rules/declarations, invalid bounds, duplicate order, and safe literal/keyword/token-ref/structured-multiply tags. Reject nested `complex_css`, `responsive`, `unresolved`, legacy calculation strings, non-finite values, and malformed tagged maps.
- [ ] **Step 2: Run the focused tests and prove RED.** Run `mix test apps/live_frames/test/live_frames/ir/state_rule_set_test.exs apps/live_frames/test/live_frames/ir_test.exs`. New subtype cases must fail because `StateRuleSet` does not exist.
- [ ] **Step 3: Implement the pure JSON-map boundary.** Add named constructor/validator functions that accept and return ordinary JSON-compatible maps. Enforce exact keys and closed values without adding a nested serialized struct or changing general `LiveFrames.IR.Validation` compatibility.
- [ ] **Step 4: Run the focused tests and prove GREEN.** Re-run the focused command and confirm valid state-rule maps pass while malformed and unknown subtypes fail closed.
- [ ] **Step 5: Run relevant regressions.** Run `mix test apps/live_frames/test/live_frames/ir/state_rule_set_test.exs apps/live_frames/test/live_frames/ir_test.exs apps/live_frames/test/live_frames/native_generator/style_value_css_test.exs apps/live_frames/test/live_frames/bricks_design_ir_test.exs`. Existing arbitrary JSON `complex_css` preservation and IR 4.0.0 serialization must remain intact.
- [ ] **Step 6: Commit the task.** `git add apps/live_frames/lib/live_frames/ir/state_rule_set.ex apps/live_frames/test/live_frames/ir/state_rule_set_test.exs apps/live_frames/test/live_frames/ir_test.exs && git commit -S -m "feat: validate closed state rule maps"`.

## Task 5: Generic responsive CSS rendering

**Files:**

- Modify: `apps/live_frames/lib/live_frames/native_generator/stylesheet_renderer.ex`
- Test: `apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs`

- [ ] **Step 1: Write failing responsive tests.** Cover max-only, min-only, bounded min/max inclusive media, zero thresholds, invalid/reversed/negative/non-finite bounds, unresolved authority, exact-width merges, and deterministic repeated output. Pin the existing overlapping max-only regression exactly: `max-width: 991px` with `gap: 2` renders before `max-width: 767px` with `gap: 3`, preserving existing output bytes/order. Add different-value overlap tests for newly introduced min-only, range, and cross-kind pairs, plus identical-value and non-overlapping cases.
- [ ] **Step 2: Run the focused tests and prove RED.** Run `mix test apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs`. Min-only, range, and new validation cases must fail against the current renderer; the existing overlapping max-only test must pass unchanged.
- [ ] **Step 3: Implement only the new media forms.** Render resolved min-only, max-only, and range `ResponsiveOverride` values with inclusive semantics. Preserve the existing max-only broader-before-narrower order and same-width merge exactly. Do not globally reject overlapping max-only rules. For a same-property, different-value overlap involving any newly supported min-only or range form, fail closed unless existing accepted responsive authority already defines its order. Deterministically deduplicate identical exact-interval/value declarations and render non-overlapping new intervals in canonical order. Add no order field or general cascade engine.
- [ ] **Step 4: Run the focused tests and prove GREEN.** Re-run the renderer suite. Confirm the 991px/767px max-only output bytes and order match the pinned existing assertion, while new intervals render and unmodeled new overlap fails closed.
- [ ] **Step 5: Run relevant regressions.** Run `mix test apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs apps/live_frames/test/live_frames/native_generator/style_integration_test.exs apps/live_frames/test/live_frames/fidelity_responsive_test.exs apps/live_frames/test/live_frames/responsive/design_document_resolver_test.exs`. Existing ordinary responsive and fidelity media ordering must remain unchanged.
- [ ] **Step 6: Commit the task.** `git add apps/live_frames/lib/live_frames/native_generator/stylesheet_renderer.ex apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs && git commit -S -m "feat: render resolved responsive ranges"`.

## Task 6: State-rule native integration

**Files:**

- Modify: `apps/live_frames/lib/live_frames/native_generator/style_integration.ex`
- Modify: `apps/live_frames/lib/live_frames/native_generator/stylesheet_renderer.ex`
- Test: `apps/live_frames/test/live_frames/native_generator/style_integration_test.exs`
- Test: `apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs`

- [ ] **Step 1: Write failing topology and output tests.** Cover owner self/descendant hover and focus-within, viewport-scoped rules, state-rule order, classes for unstyled owner/target nodes, missing/sibling/ancestor/outside-component targets, malformed/unknown complex CSS subtypes, residual-only raw `custom_css`, mixed residual exclusion, unsafe declarations, no source class leakage, and unchanged focus-visible output.
- [ ] **Step 2: Run the focused tests and prove RED.** Run `mix test apps/live_frames/test/live_frames/native_generator/style_integration_test.exs apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs`. New state-rule cases must fail because the integration path does not consume this subtype.
- [ ] **Step 3: Implement closed native integration.** Validate JSON maps with `StateRuleSet`; derive component ancestry from the one-time `NodeStyleIdentity` path index; require owner and target inside the component boundary and target self/descendant; resolve only generated private classes; add classes to every emitted owner/target; map allowed tagged values to existing `StyleValue` structs through a closed mapping and serialize with `StyleValueCSS`; render only the four authorized selectors with optional viewport wrappers. Render state `rules` only and ignore residual text. Keep primary-action `:focus-visible` and visible focus declarations unchanged.
- [ ] **Step 4: Run the focused tests and prove GREEN.** Re-run both focused suites and assert residual bytes and source selectors/classes do not appear in generated CSS.
- [ ] **Step 5: Run relevant regressions.** Run `mix test apps/live_frames/test/live_frames/native_generator/style_integration_test.exs apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs apps/live_frames/test/live_frames/native_generator/style_value_css_test.exs apps/live_frames/test/live_frames/native_generator_test.exs`. Existing focus-visible output, image style loci, primary-action selectors, and ordinary styles must remain unchanged.
- [ ] **Step 6: Commit the task.** `git add apps/live_frames/lib/live_frames/native_generator/style_integration.ex apps/live_frames/lib/live_frames/native_generator/stylesheet_renderer.ex apps/live_frames/test/live_frames/native_generator/style_integration_test.exs apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs && git commit -S -m "feat: render closed browser state rules"`.

## Task 7: End-to-end generic proof and regression gate

**Files:**

- Create: `apps/live_frames/test/live_frames/native_generator/stateful_style_pipeline_test.exs`
- Test: `apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`
- Test: `apps/live_frames/test/live_frames/bricks_transient_style_state_test.exs`
- Test: `apps/live_frames/test/live_frames/native_generator/style_integration_test.exs`
- Test: `apps/live_frames/test/live_frames/bricks_bounded_custom_css_normalizer_test.exs`

- [ ] **Step 1: Write failing source-neutral end-to-end tests.** Use two sibling synthetic effective owners sharing the same global class and CSS text. Give each owner one descendant with the same target class and the same synthetic transient token, with the exact paired inert enter/set and leave/remove records on each owner. Include conditionless base and responsive styles, hover, focus-within, and one unsupported residual. Run adapter to Design IR and then NativeGenerator. Assert each state rule targets only its own descendant, the transient token is absent from IR selectors and output, only private selectors are emitted, residual text is absent from CSS, responsive output is deterministic, and the result contains no source-specific constants.
- [ ] **Step 2: Run the focused test and prove RED.** Run `mix test apps/live_frames/test/live_frames/native_generator/stateful_style_pipeline_test.exs`. It must fail because the complete owner-scoped adapter-to-generator capability does not yet exist.
- [ ] **Step 3: Implement only integration changes required by the failing test.** Do not add source-specific branches, component contracts, componentization plans, arbitrary selector support, new IR fields, or runtime behavior.
- [ ] **Step 4: Run the focused test and prove GREEN.** Run the pipeline test twice and verify identical serialized IR and stylesheet bytes.
- [ ] **Step 5: Run all focused suites, then repository gates.** First run parser, transient-state resolver, generic normalizer, Tango normalizer, state-rule, renderer, style-integration, IR, and synthetic pipeline suites. Then run:

  ```bash
  mix deps.get
  mix format --check-formatted
  mix compile --warnings-as-errors
  mix assets.build
  mix test
  mix deps.unlock --check-unused
  git diff --check
  ```

  Also run CI styling/artifact drift checks if they are separate from `mix assets.build`. Report skipped gates and reasons. Do not suppress or weaken a failing gate.
- [ ] **Step 6: Review and commit the task.** Confirm only authorized generic parser, transient-state resolver, normalizer, IR validator, generator, and synthetic tests changed. Run `git status --short`, `git diff --check`, and inspect the complete diff. Commit the new pipeline test with `git add apps/live_frames/test/live_frames/native_generator/stateful_style_pipeline_test.exs && git commit -S -m "test: prove generic stateful style pipeline"`. Commit any required production correction separately in the task that owns that code.

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

- **Spec coverage:** Tasks 1–7 cover parser extraction, transient interaction-state proof, owner-scoped normalization, identity-based Tango claims, the exact state-rule JSON contract, responsive rendering, topology validation, residual coexistence, accessibility preservation, repeated-owner proof, and repository gates.
- **Step granularity:** Each task uses an explicit failing test, focused RED run, minimum implementation, focused GREEN run, regression run, and signed commit.
- **Type and interface consistency:** The parser returns ordered source frames/residuals; the resolver returns per-owner transient aliases; the bounded result exposes a `MapSet` of owners claimed only after class identity proof; the generic pass consumes those results per effective owner; state rules remain JSON maps; responsive data uses existing `ResponsiveOverride`; generation consumes DesignNode IDs and private classes from `NodeStyleIdentity`.
- **Review-focus tests:** All seven risks in Review Focus map to explicit cases in their owning tasks.
- **Plan/code proportion:** The document fixes boundaries, data shapes, failure rules, and test evidence. It leaves implementation bodies to the coding phase except where parsing, alias proof, owner scope, overlap, ordering, or selector behavior would otherwise be ambiguous.

Before implementation-plan approval, run the required prohibited-architecture search against this file, then run `git diff --check` and `git status --short`. Any source-specific names may appear only as authority/tracer context or explicit non-goals; no source-specific implementation input or executable-source pattern may appear. Confirm that the PR changes only this plan file. The plan is complete only when each task gives a coding agent a concrete file boundary, test command, RED/GREEN expectation, regression set, and commit point.
