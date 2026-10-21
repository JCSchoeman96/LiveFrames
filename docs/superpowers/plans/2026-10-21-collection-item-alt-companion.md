# Collection-item alt companion implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let each binding-backed collection-item image source use one caller-owned sibling `:string` ItemField as consumer-supplied alt when the source Design IR has no alt ValueBinding.

**Architecture:** Preserve the binding-backed sibling path. Add a closed unbound accessibility-companion path with a per-source 1:1 relationship. Validate it in SemanticInput and `ReferenceValidation`, read the named field through `lf_item_field/3`, then prove the candidate through approval and ordinary `NativeGenerator.generate/3`.

**Tech Stack:** Elixir, ExUnit, `ComponentizationSemanticInput`, `ComponentizationPlan`, `ComponentReview`, Phoenix LiveView, and the native generator.

**Spec:** [C09D1](../../development/c09d1_component_contract_authority.md), [C09D3 §7.2 and §10.2](../../development/c09d3_componentization_plan_authority.md), [C09D5 §6.3.1, §8, and §9](../../development/c09d5_componentization_proposer_authority.md), and [C09D6-A §10.12.1](../../development/c09d6_native_generation_authority.md).

## Global Constraints

- Keep `ComponentContract`, `ComponentizationPlan`, and `SemanticInput` serialized schemas and format versions unchanged.
- Keep `ItemFieldDecision` and `ImageAccessibilityDecision` shapes unchanged. Add no decision family, marker field, RenderProjection role, binding kind, runtime helper, or dependency.
- Ordinary item fields remain binding/projection driven. Only a companion named by a valid consumer-supplied image source may have zero BindingProjections.
- For the unbound path, every image-source ItemField names exactly one same-collection companion. Every companion belongs to exactly one such source. `N` sources require `N` distinct companions. Multiple distinct pairs are allowed in one CollectionInput and one ComponentContract. No shared or orphan companion is allowed.
- The companion has `type: :string`, `required: false`, `default: nil`, no BindingProjection, no RenderProjection, and no BindingAssignmentDecision. Its value is conditionally required only when its source is present.
- Keep `VALUE_BINDING_COVERAGE_RULE`: every real in-boundary ValueBinding still requires its ordinary projection.
- Preserve the legacy same-node binding-backed alt path without behavior changes. Do not infer alt text or classify an image decorative.
- Build validation indexes once. Do not scan a whole contract or DesignDocument once per image source. Complexity remains bounded by input nodes, bindings, public members, and accessibility decisions.
- Do not change ComponentReview production code. If another production module rejects a valid unbound companion after the planned validator and renderer changes, stop and report its exact module and diagnostic.
- Do not create Milan SemanticInput, choose Milan owner decisions, call ComponentReview for Milan, resume Task 10, or add NodeDisposition / `NativeGenerator.generate/7` to this feature.
- Add no Redis, Postgres, PubSub, GenServer, Oban, runtime database, runtime network, or polling work.

## Review Focus

- One source with one companion passes; two sources with two distinct companions pass; a shared or orphan companion fails. Pin this in Task 1 and Task 2.
- One unbound ItemField cannot bypass ordinary projection rules unless exactly one consumer-supplied image source names it. Pin this in Task 1 and Task 2.
- The legacy binding-backed same-node alt path keeps passing. Pin this in Task 2 and Task 3.
- Each image reads its own companion. Present sources reject nil or empty alt; absent optional sources omit the image without requiring alt. Pin this in Task 3.
- The candidate passes every ordinary approval and generation gate without disposition authority. Pin this in Task 4.

---

## Files and responsibilities

- `apps/live_frames/lib/live_frames/componentization_proposer/semantic_input/validation.ex` validates decision relationships and one-to-one cardinality before construction.
- `apps/live_frames/lib/live_frames/componentization_plan/reference_validation.ex` validates the public contract and plan XOR paths and rejects orphan or shared unbound fields.
- `apps/live_frames/lib/live_frames/native_generator/renderer.ex` resolves the current source's exact companion through the existing collection-item accessor.
- `apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs` and `apps/live_frames/test/live_frames/componentization_proposer_test.exs` prove the semantic input relationship and construction output.
- `apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs` proves the reference-validation paths and cardinality.
- `apps/live_frames/test/live_frames/native_generator_test.exs` proves public generation behavior for both sources and companion values.
- `apps/live_frames/test/live_frames/component_review_test.exs` proves the complete ordinary approval/generation path.

## TDD execution order

Write and run Task 4's full-gate regression before implementing Tasks 1–3. Its initial RED proves the current proposer/reference gate rejects the unbound path. Then complete Tasks 1, 2, and 3 in order. Return to Task 4 and rerun its test for GREEN. This checks the full pipeline before and after the implementation work.

### Task 1: Validate companion relationships in SemanticInput

**Files:**

- Modify: `apps/live_frames/lib/live_frames/componentization_proposer/semantic_input/validation.ex`
- Test: `apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs`
- Test: `apps/live_frames/test/live_frames/componentization_proposer_test.exs`

**Interfaces:**

- **Consumes:** `SemanticInput.validate/2`, `ItemFieldDecision`, `BindingAssignmentDecision`, `ImageAccessibilityDecision`, and the supplied DesignDocument. `SemanticInput.validate/2` returns `{:ok, validated_input}` or `{:error, diagnostics}`.
- **Produces:** validation that accepts each valid per-source pair, rejects shared and orphan companions, and lets the existing constructor emit an ordinary ItemField with no BindingProjection.

- [ ] **Step 1: Add the valid cardinality tests.** Add `accepts one unbound image alt companion` and `accepts two distinct unbound image alt companions in one collection`. Assert SemanticInput validation passes. Propose each valid input and assert the companion ItemFields are present with no BindingProjection. The proposal may remain `:needs_review` until Task 2.
- [ ] **Step 2: Add the rejection tests.** Add `rejects an unbound companion shared by two image sources` and `rejects an orphan unbound item field`. Also cover a missing companion, a companion in another collection, non-string type, `required: true`, non-nil default, and an assignment to a would-be companion that does not satisfy the legacy binding-backed sibling path. Keep the valid legacy path as a passing regression.
- [ ] **Step 3: Run the focused tests to verify RED.**

  Run: `mix test apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs apps/live_frames/test/live_frames/componentization_proposer_test.exs`

  Expected: the command exits non-zero because the current validator accepts the shared and orphan relationships. The new rejection assertions receive `{:ok, validated_input}` instead of `{:error, diagnostics}`. Existing binding-backed tests continue to pass.
- [ ] **Step 4: Add the closed relationship validation.** Build the source-to-companion and companion-to-source indexes once. Require every source to name one existing same-collection companion, every unassigned ItemFieldDecision to be named by exactly one source, and each source to have a distinct companion. Do not change SemanticInput structs or proposer construction.
- [ ] **Step 5: Run the focused tests to verify GREEN.**

  Run: `mix test apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs apps/live_frames/test/live_frames/componentization_proposer_test.exs`

  Expected: exit zero. One-to-one and two-pair inputs pass; shared, orphan, missing, mismatched, assigned, and malformed companions fail with `invalid_input`; legacy inputs pass; construction emits no BindingProjection for a companion.

If a RED test proves construction cannot materialize the ItemField without a binding assignment, stop with `STOP=UNEXPECTED_PROPOSER_CONSTRUCTION_CHANGE_REQUIRED`. Do not change the construction module in this plan.

### Task 2: Validate the XOR paths and cardinality in ReferenceValidation

**Files:**

- Modify: `apps/live_frames/lib/live_frames/componentization_plan/reference_validation.ex`
- Test: `apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs`

**Interfaces:**

- **Consumes:** `ComponentizationPlan.validate_references/3`, the ComponentContract, the DesignDocument, existing field and projection indexes, and the SemanticInput guarantees from Task 1.
- **Produces:** `:ok` for either valid XOR branch; blocking diagnostics for malformed, shared, or orphan unbound companions.

- [ ] **Step 1: Add passing-path tests.** Add `preserves the binding-backed same-node image alt path`, `allows one unbound alt companion`, and `allows two distinct unbound alt companions in one collection`.
- [ ] **Step 2: Add negative-path tests.** Add `rejects a companion with any projection`, `rejects an orphan unbound item field`, and `rejects a shared companion`. Also prove rejection for wrong type, `required: true`, non-nil default, and cross-collection ownership. Keep the decorative policy unchanged.
- [ ] **Step 3: Run the reference tests to verify RED.**

  Run: `mix test apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs`

  Expected: exit non-zero. The current validator blocks the zero-projection path with the existing alt-projection mismatch diagnostic. Existing legacy-path tests pass.
- [ ] **Step 4: Implement the XOR validator.** Reuse field and projection indexes. Build a reverse companion-reference index once, check both cardinality directions, reject every orphan unbound ItemField, and preserve `VALUE_BINDING_COVERAGE_RULE`. Do not scan the whole contract or DesignDocument once per image source.
- [ ] **Step 5: Run the reference tests to verify GREEN.**

  Run: `mix test apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs`

  Expected: exit zero. Both XOR branches pass under their own rules; two distinct pairs pass; shared and orphan companions fail; malformed projections fail; decorative and ValueBinding coverage behavior is unchanged.

### Task 3: Render each companion through `lf_item_field/3`

**Files:**

- Modify: `apps/live_frames/lib/live_frames/native_generator/renderer.ex`
- Test: `apps/live_frames/test/live_frames/native_generator_test.exs`

**Interfaces:**

- **Consumes:** a validated contract and plan, each image source's exact `accessibility["alt_item_field_name"]`, the current item/ordinal from the existing collection stack, and `lf_item_field/3`.
- **Produces:** generated Elixir/HEEx that resolves each source's own companion and enforces the existing deterministic non-empty alt error only when that source is present.

- [ ] **Step 1: Add the public-generation mapping test** `each generated image source reads its own alt companion`. Use `NativeGenerator.generate/3` to generate one component with two image-source ItemFields and two distinct companions. Follow the proven generated-module test pattern in `native_generator_v6_proofs_test.exs`: compile only the generated module artifact with `Code.compile_string/1`, capture its generated function, and render it with `Phoenix.LiveViewTest.render_component/2`. Assert source A uses companion A, source B uses companion B, and neither reads the other's value.
- [ ] **Step 2: Add conditional and item-key tests.** Add `requires a non-empty alt only when its source is present` and `reads string-keyed and existing atom-keyed item fields`. Prove present `src` with non-empty alt renders; present `src` with nil or empty alt raises the existing deterministic accessibility error; an absent optional `src` omits that image without requiring alt; string-keyed and existing atom-keyed item maps both work.
- [ ] **Step 3: Run the native generator tests to verify RED.**

  Run: `mix test apps/live_frames/test/live_frames/native_generator_test.exs`

  Expected: exit non-zero because generated output still resolves alt through the binding-backed `asset_alt` projection and emits the literal `"nil"` fallback instead of each named companion. Present-source nil/empty-alt and absent-source assertions fail where the companion is not read conditionally. Existing binding-backed asset-alt output remains passing.
- [ ] **Step 4: Add the renderer branch.** For each bound image source, read the exact companion name from that source ItemField's accessibility map and call the existing `lf_item_field(item, ordinal, field_name)`. Skip that call when the optional source is absent. Add no helper, projection, render role, or global companion state.
- [ ] **Step 5: Run the native generator tests to verify GREEN.**

  Run: `mix test apps/live_frames/test/live_frames/native_generator_test.exs`

  Expected: exit zero. The generated component uses distinct companion values for each source, enforces conditional alt, supports both existing map key forms, and preserves the legacy binding-backed output.

Use the public `NativeGenerator.generate/3` path and generated component behavior as the success proof. Renderer-private calls may supplement, but cannot replace, that proof. Do not call `String.to_atom/1`, `String.to_existing_atom/1`, execute imported source code, or copy a source runtime.

### Task 4: Prove the complete ordinary approval and generation gate

**Files:**

- Test: `apps/live_frames/test/live_frames/component_review_test.exs`
- No ComponentReview production file is expected to change.

**Interfaces:**

- **Consumes:** an ordinary `DesignDocument` and `SemanticInput`; `ComponentizationProposer.propose/2`; `ComponentContract.validate_generation_prerequisites/2`; `ComponentizationPlan.validate_generation_prerequisites/3`; `ComponentReview.validate_generation_prerequisites/3`; `ComponentReview.approve/3`; both `validate_for_generation` functions; and `NativeGenerator.generate/3`.
- **Produces:** one end-to-end regression proving the unbound companion survives validation, proposal, approval, and ordinary generation without NodeDisposition or `generate/7`.

- [ ] **Step 1: Add the full-gate test before Tasks 1–3 production changes.** Build a single-source, single-companion candidate through real `SemanticInput` and `ComponentizationProposer` APIs. Name the test `unbound accessibility companion passes the ordinary generation gate`.
- [ ] **Step 2: Run the ComponentReview test to verify RED.**

  Run: `mix test apps/live_frames/test/live_frames/component_review_test.exs`

  Expected: exit non-zero because the current proposer/reference-validation path does not return `outcome: :proposed` for the unbound companion candidate.
- [ ] **Step 3: After Tasks 1–3, rerun the same test to verify GREEN.** Assert all of the following in the test:

  - `SemanticInput.validate/2` returns `{:ok, validated_input}`.
  - `ComponentizationProposer.propose/2` returns `outcome: :proposed`.
  - `ComponentContract.validate_generation_prerequisites/2` returns `:ok`.
  - `ComponentizationPlan.validate_generation_prerequisites/3` returns `:ok`.
  - `ComponentReview.validate_generation_prerequisites/3` returns `:ok`.
  - `ComponentReview.approve/3` returns `{:ok, approved_contract}` with `approval_status: :approved`.
  - `ComponentContract.validate_for_generation/2` returns `:ok`.
  - `ComponentizationPlan.validate_for_generation/3` returns `:ok`.
  - `NativeGenerator.generate/3` returns `{:ok, generated_bundle}`.

  Run: `mix test apps/live_frames/test/live_frames/component_review_test.exs`

  Expected: exit zero with each gate assertion passing. The test uses no NodeDisposition and does not call `NativeGenerator.generate/7`.
- [ ] **Step 4: Stop if an unplanned production module rejects the candidate.** Record the exact owning module and diagnostic, then stop with `STOP=UNEXPECTED_GENERATION_GATE_CHANGE_REQUIRED`. Do not expand the production file scope or modify ComponentReview in this task.

## Final verification

- [ ] Run every focused suite after all four tasks:

  Run: `mix test apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs apps/live_frames/test/live_frames/componentization_proposer_test.exs apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs apps/live_frames/test/live_frames/native_generator_test.exs apps/live_frames/test/live_frames/component_review_test.exs`

  Expected: exit zero.
- [ ] Run `mix format --check-formatted`. Expected: exit zero and no formatting violations.
- [ ] Run `mix compile --warnings-as-errors`. Expected: exit zero and no warnings.
- [ ] Run `mix test`. Expected: exit zero and all tests pass.
- [ ] Run `git diff --check`. Expected: exit zero with no whitespace errors.
- [ ] Run `git status --porcelain`. Expected: empty after commit.

## Stop conditions

Stop implementation and report the exact evidence if any condition occurs:

```text
STOP=MAIN_MOVED
STOP=AUTHORITY_CHANGED
STOP=SCHEMA_CHANGE_REQUIRED
STOP=FORMAT_VERSION_CHANGE_REQUIRED
STOP=GENERIC_UNBOUND_ITEM_FIELD_REQUIRED
STOP=UNEXPECTED_PROPOSER_CONSTRUCTION_CHANGE_REQUIRED
STOP=UNEXPECTED_GENERATION_GATE_CHANGE_REQUIRED
STOP=LEGACY_BINDING_BACKED_ALT_REGRESSION
STOP=COMPANION_CARDINALITY_REGRESSION
STOP=NEW_RENDER_ROLE_REQUIRED
STOP=NEW_BINDING_KIND_REQUIRED
STOP=NEW_DEPENDENCY_REQUIRED
STOP=SOURCE_ALT_INFERENCE_REQUIRED
STOP=SOURCE_RUNTIME_EXECUTION_REQUIRED
STOP=SOURCE_RUNTIME_COPY_REQUIRED
```

G2-B implementation does not authorize Milan owner decisions or Task 10. The Milan semantic freeze and disposition-aware proof remain separate work.
