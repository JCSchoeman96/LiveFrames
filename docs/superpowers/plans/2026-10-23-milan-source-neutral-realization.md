# Milan Task 10 Source-Neutral Realization Implementation Plan

> Execute one numbered slice at a time. Each slice has its own review gate. Do not begin the next slice until the prior exact head is accepted.

**Goal:** Make Feature Milan generation-capable using the exact Behavior-authorized Selection runtime and bounded picture support. Preserve source-neutral output, closed ordinary generation, and the existing IR identity and serialized schemas.

**Authority:** [Feature Milan Task 10 Source-Neutral Realization Authority](../../development/feature_milan_task10_source_neutral_realization_authority.md)

**Tech stack:** Elixir 1.19, Phoenix 1.8+, Phoenix LiveView 1.2.11, HEEx, colocated hooks, and the existing NativeGenerator and StyleIntegration infrastructure.

## Global constraints

- Base commit: 0a409a1f41f9cf493a1efb4884ff4251bc1d3d7e
- Base tree: 718a64cc2196e72d3183ff4dd7cb17fae706ad49
- IR version: 5.0.0
- DesignDocument SHA-256: 9ae73053d9224bebcb71833b77094a17c3ef7c3a25f0b5b1c4dbad5aaf9d2229
- Behavior binding ID: bnd_abf701b79aba7597825525c7ddf5065e89a2fdcfb378797f63e3d9fb74ff8ee2
- Behavior contract digest: 1e0095418d96f392594a155d9c6ea9610b6b5f4d62c6d0205df66dedea57506a
- Behavior review ID: brv_b4bc3ab7f4284cf20ae6f0aaf73da3fd2c242e42d18f1ab049acc6f1e62e9c11
- Review canonical byte length: 905
- Review canonical SHA-256: b4bc3ab7f4284cf20ae6f0aaf73da3fd2c242e42d18f1ab049acc6f1e62e9c11
- Do not mutate the DesignDocument, reissue Behavior authority, or widen serialized schemas.
- Do not copy source JavaScript, CSS, runtime code, or selectors into generated output.
- Do not reproduce Tabs semantics or use server-side interaction state.
- Do not widen ordinary generic-button generation.
- `generate/3` receives no `NativeRealizationAuthority` and follows ordinary native rules only; `generic + tag=button` remains blocked.
- Deriving native realization authority must not depend on native-generation eligibility that this authority is intended to grant. Any realization-specific eligibility exception depends on successfully derived transient authority.
- Do not add a generated JavaScript artifact type.
- Use existing dependencies except for the approved direct Phoenix ~> 1.8 package requirement.
- Use TDD for behavior changes. Keep each slice small and focused.
- Stop on a listed STOP condition. Report the evidence and do not work around it.

## Phase 0 — Publish repository authority

### Slice 0A — Publish the accepted A1 and A2 policy

**Status:** authorized documentation-only slice.

**Files**

- Create docs/development/feature_milan_task10_source_neutral_realization_authority.md.
- Create this implementation plan.
- Update docs/17_ROADMAP.md only if a canonical Task 10 status entry is required.

**Work**

- [ ] Verify the exact base and the frozen IR5 Behavior authority tuple.
- [ ] Publish the R1A public API, N2/N3, Selection, and picture policy from the authority document.
- [ ] Publish this phased plan with the exact accepted BehaviorReviewResult ID.
- [ ] Review the diff for documentation-only scope and run git diff --check.
- [ ] Create the authorized signed documentation commit and open a review PR.
- [ ] Stop for review. Do not begin T1.

**STOP**

- STOP=AUTHORITY_DOCUMENT_DRIFT
- STOP=DESIGN_IDENTITY_MISMATCH
- STOP=BEHAVIOR_AUTHORITY_MISMATCH
- STOP=IMPLEMENTATION_CHANGE_IN_DOCS_SLICE

**Success**

One signed docs-only commit and review PR; no production or test files changed.

### Slice 0B — Correct Native Realization gate sequencing

**Status:** authorized documentation-only correction. This records the stopped initial T2 attempt and corrects implementation order only; the approved A1/A2 semantics do not change.

```text
T2_INITIAL_ATTEMPT=STOPPED
STOP=T2_EXISTING_AUTHORITY_GATE_INSUFFICIENT
```

The initial T2 sequence required `ComponentizationPlan.validate_for_generation_with_behavior_authority/5` before deriving `NativeRealizationAuthority`. That full generation gate also checks native-generation eligibility. N2 is currently `generic + tag=button`, which ordinary native-generation authority correctly rejects. `NativeRealizationAuthority` is intended to authorize only this exact Behavior-backed structural realization, so full native-generation validation cannot run before the authority is derived. This is an ordering cycle, not a defect in ordinary generation.

Freeze these validation layers:

**Layer A — approved contract gate**

```elixir
ComponentContract.validate_for_generation(approved_component_contract, design_document)
```

This proves the ComponentContract is approved for generation and its DesignDocument references are valid.

**Layer B1 — exact Behavior authority, always**

Run these existing Behavior primitives regardless of whether `plan.node_dispositions` is empty:

```elixir
Behavior.Validation.validate_structure(design_document, behavior_contract)
# => :ok

Behavior.Serializer.digest(behavior_contract)
# => {:ok, digest}

Behavior.ReviewResult.require_approved(
  [selected_behavior_review_result],
  behavior_contract
)
# => {:ok, selected_behavior_review_result}

Behavior.ReviewResult.id(selected_behavior_review_result)
# => {:ok, review_id}
```

These checks establish the exact BehaviorContract/DesignDocument structure and identity, canonical contract digest, approved singleton review for that contract, and canonical review ID. Use their existing diagnostics and result semantics. Do not create another Behavior format, review system, or serialized authority object.

**Layer B2 — plan, reference, and disposition authority**

```elixir
ComponentizationPlan.validate_references_with_behavior_authority(
  plan,
  approved_component_contract,
  design_document,
  behavior_contract,
  selected_behavior_review_result
)
```

This validates plan structure, the plan/document fingerprint and references, and node-disposition authority when dispositions are present. When `plan.node_dispositions` is empty, this API falls back to ordinary plan/reference validation and does not consume the supplied Behavior authority. It is therefore not the sole exact Behavior approval gate. Layer B1 always establishes that authority independently. B2 must not require every node to satisfy ordinary native-generation tag eligibility.

**Layer C — transient native realization authority**

```elixir
NativeRealizationAuthority.derive(...)
```

This proves the exact Selection 1.0.0 topology and N2/N3 realization permission, then returns transient, source-neutral native permission.

**Layer D — authority-aware native-generation eligibility (T3)**

Ordinary nodes use existing native rules. Exact nodes covered by `NativeRealizationAuthority` may use bounded realization-specific rules. Everything else remains fail-closed. The exception is node-specific, Behavior-specific, plan-specific, DesignDocument-specific, and transient; it must not be semantic-type-global. Do not widen the global native-tag map.

T2-R1 must pass Layer A, Layer B1, and Layer B2 before running realization-specific guards. Layer B1 runs regardless of whether `plan.node_dispositions` is empty. Diagnostics from these existing checks pass through unchanged. It must not call `ComponentizationPlan.validate_for_generation_with_behavior_authority/5` before deriving realization authority, and it must not bypass any of these gates.

T2-R1 must not modify `@native_tags`, native-generation validation, NativeGenerator, Renderer, or StyleIntegration, and must not create an exception in ordinary generation.

T3 generation order is: Layer A, Layer B1, Layer B2, derive Layer C, run Layer D, pass the existing exact-authority ComponentReview gate, build `FilteredStructure`, then call `StyleIntegration(authority)` and `Renderer(authority)`. ComponentReview placement may remain consistent with its current identity responsibilities, but generation must not render unless both ComponentReview authority and native realization authority pass when the Selection exception applies.

The ordinary-generation invariant remains: `generate/3` has no realization authority; `generic + tag=button` stays blocked. `generate/7` with missing or incorrect Behavior authority, or with failed realization guards, also leaves that shape blocked. Only the exact successfully derived transient authority can authorize the exceptional realization.

This correction does not change Selection 1.0.0 semantics, the N2 structural div realization, the N3 heading/button carrier, `aria-pressed` policy, hidden presentation policy, timer lifecycle, picture policy, BehaviorContract, BehaviorReviewResult, DesignDocument, R1A public surface, or serialized schemas. No Behavior or review reissue is required.

## Phase 1 — Shared binding containment

### Slice 1A — Extract one binding-containment implementation

**Files**

- Create apps/live_frames/lib/live_frames/behavior/binding_containment.ex.
- Modify apps/live_frames/lib/live_frames/behavior/componentization_decision.ex.
- Add apps/live_frames/test/live_frames/behavior/binding_containment_test.exs.
- Update apps/live_frames/test/live_frames/behavior/componentization_decision_test.exs.

**Interface**

LiveFrames.Behavior.BindingContainment.classify(binding, design_document, boundary_node_id) returns one of:

- {:ok, :contained}
- {:ok, :outside_candidate}
- {:ok, :split}
- {:error, reason}

Use all Behavior reference roles already used by ComponentizationDecision: binding owner, controlled targets, trigger origins, focus references, and IR interaction references and targets. ComponentizationDecision calls this module; it must not retain a parallel containment implementation.

**Tests**

- [ ] All references inside classify as contained.
- [ ] All references outside classify as outside candidate.
- [ ] Mixed references classify as split.
- [ ] Missing targets fail closed.
- [ ] Focus references, trigger origins, controlled targets, and IR interaction references and targets are included.

**Avoid**

Do not change proposer output, add serialized fields, optimize before tests prove parity, or break public APIs.

**STOP**

- STOP=EXISTING_COMPONENTIZATION_DECISION_BEHAVIOR_CHANGES
- STOP=SECOND_CONTAINMENT_ALGORITHM_REQUIRED
- STOP=PUBLIC_API_BREAK_REQUIRED

## Phase 2 — Final native realization authority

### Slice 2A — Derive transient Selection realization authority

**Files**

- Create apps/live_frames/lib/live_frames/behavior/native_realization_authority.ex.
- Add apps/live_frames/test/live_frames/behavior/native_realization_authority_test.exs.
- Reuse shared validation in apps/live_frames/lib/live_frames/componentization_plan/reference_validation.ex only where needed.

**Interface**

NativeRealizationAuthority.derive(approved_component_contract, plan, design_document, behavior_contract, approved_behavior_review) returns {:ok, authority} or {:error, diagnostics}.

The result is transient generation-time permission and is never serialized. It may identify N2 as the control owner and N3 as its heading-button activation carrier.

Before realization-specific guards run, require Layer A (`ComponentContract.validate_for_generation/2`), Layer B1 (all four exact Behavior checks), and Layer B2 (`ComponentizationPlan.validate_references_with_behavior_authority/5`) from Slice 0B to pass. Run Layer B1 even when the plan has no node dispositions. Preserve diagnostics from all three layers unchanged. Do not use `ComponentizationPlan.validate_for_generation_with_behavior_authority/5` as the upstream gate: its native-generation eligibility check rejects the exact generic-button shape that this authority must prove.

**Exact Selection guards**

Require all of the following before granting authority:

- The exact approved Behavior review matches the DesignDocument and BehaviorContract.
- The binding is selection@1.0.0.
- There is exactly one control collection at N2 and one activate origin at N2.
- The binding is contained against the final plan.boundary_node_id.
- N2 is generic with tag button.
- N3 is a direct child of N2 and has semantic type heading.
- The existing title ValueBinding targets N3.
- heading_level RenderProjection targets N3.
- There is no conflicting navigation or interactivity.

A failed guard grants no permission.

**Tests**

- [ ] Each guard can fail independently.
- [ ] Layer A, Layer B1, or Layer B2 failure returns its existing diagnostics unchanged and grants no authority.
- [ ] With no node dispositions, an unapproved selected review denies NativeRealizationAuthority.
- [ ] With no node dispositions, a selected review/BehaviorContract mismatch denies NativeRealizationAuthority.
- [ ] With no node dispositions, a BehaviorContract/DesignDocument mismatch denies NativeRealizationAuthority.
- [ ] A valid source-neutral Selection tuple with no node dispositions may proceed to realization-specific guards.
- [ ] An ordinary generic button receives no authority.
- [ ] Wrong primitive, unapproved review, control-only, activate-only, split binding, outside binding, changed N3 topology, or missing heading-level projection is blocked.
- [ ] A plan alone cannot forge authority.

**STOP**

- STOP=BEHAVIOR_NATIVE_GUARD_UNPROVABLE
- STOP=TABS_SEMANTICS_REQUIRED
- STOP=SERIALIZED_HANDOFF_REQUIRED

## Phase 3 — Thread authority through generation

### Slice 3A — Preserve Behavior authority after generator gates

**Files**

- Modify apps/live_frames/lib/live_frames/native_generator.ex.
- Modify apps/live_frames/lib/live_frames/native_generator/renderer.ex.
- Modify apps/live_frames/lib/live_frames/native_generator/style_integration.ex if needed.
- Update apps/live_frames/test/live_frames/native_generator_test.exs.

**Required flow**

Behavior-aware generate/7 passes Layer A, Layer B1, and Layer B2 from Slice 0B, derives `NativeRealizationAuthority`, then applies authority-aware native-generation eligibility before passing authority through filtered structure, StyleIntegration, renderer indexes, and rendering. The existing exact-authority ComponentReview gate must also pass before rendering. Do not discard Behavior context before rendering.

Ordinary generate/3 receives no `NativeRealizationAuthority` and follows ordinary native rules, so generic + tag=button remains blocked. Preserve the public generate/7 signature; derive authority from its final approved inputs. Missing/wrong Behavior authority or failed realization guards must not authorize the exceptional shape. Do not modify the global native-tag map or create an ordinary-generation exception.

T3 introduces only the authority-aware eligibility surface needed by this flow. The exact internal API is left to implementation review; its behavior is equivalent to:

```text
ordinary_native_eligible?(node)
OR
authorized_native_realization?(node, authority)
```

The realization branch requires the successfully derived exact `NativeRealizationAuthority`; all other shapes fail closed. Native realization authority derivation must not depend on the native eligibility exception it grants.

**Tests**

- [ ] Ordinary generic-button generation remains blocked.
- [ ] Exact Selection authority reaches the renderer.
- [ ] Wrong Behavior identity does not reach the renderer.
- [ ] A plan alone cannot create authority.

**STOP**

- STOP=GENERATE_7_SIGNATURE_CHANGE_REQUIRED
- STOP=ORDINARY_GENERATION_WIDENED
- STOP=COMPONENTIZATION_DECISION_RUNTIME_DEPENDENCY_REQUIRED

## Phase 4 — Selection structure and styling

### Slice 4A — N2 wrapper and N3 title-button carrier

**Files**

- Modify apps/live_frames/lib/live_frames/native_generator/renderer.ex.
- Modify apps/live_frames/lib/live_frames/native_generator/style_integration.ex.
- Add focused rendering and style tests alongside the NativeGenerator tests, using apps/live_frames/test/live_frames/native_generator/milan_selection_realization_test.exs if a dedicated fixture keeps them isolated.

**Structure and attributes**

- N2 renders as a structural div.
- N3 renders as the approved h1 through h6 heading.
- The heading contains one native title button, and the title binding appears once inside it.
- The button has type=button, data-lf-selection-activate, and aria-pressed.
- The N2 occurrence has data-lf-selection-control and data-lf-selection-state.
- Do not emit role=tab, aria-selected, aria-controls, tabpanel, a tabindex policy, source selectors, or source custom CSS.

**Style ownership**

Keep these normalized N2 base properties on the wrapper only:

- background
- border-color
- border-left-width
- border-style
- display
- grid-template-columns
- grid-template-rows
- padding-left
- padding-right
- position
- row-gap
- transition

Do not copy them onto the button. Do not emit N2 opaque complex_css.

Use package-owned button neutralization for font and color inheritance, transparent background, no border, zero padding and margin, inherited text alignment, and pointer cursor. Keep native focus indication visible.

**Tests**

- [ ] Assert exact HTML nesting and required attributes.
- [ ] Assert prohibited Tabs attributes and source styling are absent.
- [ ] Cover heading levels 1 through 6 and default level 3.
- [ ] Prove N2 wrapper properties are not copied to the button.
- [ ] Prove keyboard focus remains visible.

**STOP**

- STOP=SOURCE_CUSTOM_CSS_REQUIRED
- STOP=SOURCE_ARIA_REQUIRED
- STOP=HEADING_INSIDE_BUTTON
- STOP=N2_STYLE_COPY_TO_BUTTON_REQUIRED

## Phase 5 — Selection runtime

### Slice 5A — Package and build capability

**Files**

- Modify apps/live_frames/mix.exs.
- Modify config/config.exs.

**Requirements**

- Add the approved direct Phoenix ~> 1.8 requirement to the reusable LiveFrames package. Do not raise the minimum to 1.8.13.
- Retain phoenix_live_view ~> 1.2.11.
- Enable the :phoenix_live_view compiler.
- Add Mix.Project.build_path() to the host esbuild NODE_PATH alongside repository dependencies.
- Keep GeneratedArtifactBundle artifact kinds unchanged: :elixir_module and :stylesheet.
- No JavaScript artifact kind exists and none may be added.
- The Selection hook will use LiveView component-colocated hook extraction.

**Checks**

- [ ] Existing package compilation succeeds.
- [ ] The existing asset build succeeds.
- [ ] GeneratedArtifactBundle still has exactly the :elixir_module and :stylesheet kinds, with no JavaScript kind.

**STOP**

- STOP=NEW_RUNTIME_DEPENDENCY_REQUIRED
- STOP=GENERATED_JS_ARTIFACT_KIND_REQUIRED

### Slice 5B — Add and register the colocated Selection hook

**Files**

- Add generated hook source through apps/live_frames/lib/live_frames/native_generator/renderer.ex.
- Modify apps/live_frames_preview/assets/js/app.js.
- Add focused tests in apps/live_frames/test/live_frames/native_generator/milan_selection_runtime_test.exs.
- Add browser or integration proof under the existing preview browser-test location; do not introduce a new testing framework.

This is the first slice that creates and consumes a LiveFrames colocated hook.

**Hook registration**

- [ ] Import the phoenix-colocated/live_frames manifest in app.js.
- [ ] Pass the manifest hooks to LiveSocket.
- [ ] Prove the manifest resolves and the preview registers the hook.

**Instance states**

- UNMOUNTED
- ACTIVE
- UNAVAILABLE
- DESTROYED

**Timer states**

- RUNNING
- STOPPED_BY_USER
- SUPPRESSED_REDUCED_MOTION
- SUSPENDED_UNAVAILABLE
- SUSPENDED_DISCONNECTED
- DESTROYED

**Mount**

Within this.el only:

- Resolve controls and both presentation collections.
- Validate equal, nonzero cardinality.
- Initialize selected_position=0 and project it.
- Attach one delegated click listener.
- Start at most one timer when eligible.

**Activation**

Resolve the nearest owning N2 control from the activation carrier, derive its zero-based rendered position, and activate that position. Update the N2 selected marker and button aria-pressed; remove hidden from the selected item in both presentation collections and add it to all other items. Manual activation permanently stops the timer.

**Timer and reduced motion**

Advance every 5000 ms with wraparound. A timer tick never changes focus. Reduced-motion preference suppresses automatic advancement but leaves manual activation available.

**Reconciliation and lifecycle**

- On update, re-resolve collections without duplicating resources.
- Preserve numeric position only while valid; do not clamp it.
- Suspend and clear the interval on disconnect.
- Reconnect only if the timer was previously eligible and running.
- Never restart after manual activation.
- On destruction, remove the listener and timer permanently.

**Tests**

- [ ] Initial position zero.
- [ ] Manual activation.
- [ ] Synchronized projection across both presentation collections.
- [ ] Hidden and aria-pressed projection.
- [ ] Timer wrap and permanent manual stop.
- [ ] Reduced motion.
- [ ] Cardinality mismatch enters unavailable state.
- [ ] Valid recovery without clamping.
- [ ] Multiple-instance isolation.
- [ ] Disconnect/reconnect and destroy cleanup.
- [ ] Prove the manifest resolves and LiveSocket has the Selection hook registered.

**STOP**

- STOP=HOST_CANNOT_RESOLVE_COLOCATED_MANIFEST
- STOP=SERVER_EVENT_REQUIRED
- STOP=SERVER_STATE_REQUIRED
- STOP=DOCUMENT_GLOBAL_SELECTOR_REQUIRED
- STOP=SOURCE_SELECTOR_REQUIRED
- STOP=MORE_THAN_ONE_TIMER_PER_INSTANCE_REQUIRED

## Phase 6 — Picture support

This phase is independent of Selection after the shared generator infrastructure is accepted.

### Slice 6A — Closed picture > img structure

**Files**

- Modify apps/live_frames/lib/live_frames/componentization_plan/reference_validation.ex.
- Modify apps/live_frames/lib/live_frames/native_generator/renderer.ex.
- Add focused reference-validation and rendering tests, including apps/live_frames/test/live_frames/native_generator/picture_realization_test.exs.

**Matrix**

| Input | Output |
| --- | --- |
| Image with no explicit tag | Existing img behavior, unchanged |
| Image with tag figure | Existing figure > img behavior, unchanged |
| Image with tag picture | picture > img |
| Image with another explicit tag | Blocked |

For picture, put the private class on the outer picture, asset source and alt on the inner img, and add no source elements. Avoid global StaticMarkupContract widening where image-specific validation can express the closed case.

**STOP**

- STOP=GLOBAL_STATIC_MARKUP_WIDENING_REQUIRED
- STOP=EXPLICIT_IMG_AUTHORITY_CHANGE_REQUIRED
- STOP=PICTURE_SOURCE_CHILD_INVENTION_REQUIRED

### Slice 6B — Closed picture style loci

**Files**

- Modify apps/live_frames/lib/live_frames/native_generator/style_integration.ex.
- Update StyleIntegration tests and/or the focused picture realization test.

**Property matrix**

| Property | Locus |
| --- | --- |
| position | Outer picture |
| object-fit | Direct child img |
| width | Both |
| height | Both |

The private class remains on the outer element. Use a direct-child selector for the inner image. Fail closed for any other base property, responsive styles, pseudo styles, a StateRuleSet on the compound target, or custom CSS requiring a second locus. Preserve existing no-tag and figure output.

**STOP**

- STOP=PICTURE_UNSUPPORTED_STYLE_PROPERTY
- STOP=PICTURE_RESPONSIVE_LOCUS_UNAUTHORIZED
- STOP=PICTURE_STATE_LOCUS_UNAUTHORIZED
- STOP=PICTURE_CUSTOM_CSS_LOCUS_UNAUTHORIZED

## Phase 7 — Milan R1A and R1B re-entry

Start only after Phases 0 through 6 have been accepted individually.

### Slice 7A — Recreate final SemanticInput

Use the exact final owner tuple: the id attribute, features, feature_media, feature_heading_level, intro slot, six existing projections and bindings, and the N1 source-runtime-carrier disposition. Add no source interpretation.

Run Behavior.ComponentizationDecision.propose/5 and require result=:proposed with no diagnostics. Run generation prerequisites against the exact Behavior authority and require zero blockers. Do not approve ComponentReview in this slice.

### Slice 7B — Freeze candidate fingerprints

Capture ComponentContract and ComponentizationPlan canonical bytes and digests, DesignDocument identity, Behavior contract digest, Behavior review ID, and all disposition identities. Do not mutate the candidate after freezing.

**STOP**

- STOP=PROPOSER_NOT_PROPOSED
- STOP=GENERATION_PREREQUISITE_FAILURE
- STOP=CONTRACT_PLAN_IDENTITY_DRIFT

## Phase 8 — R1C ComponentReview

This is a human review gate. Review the exact frozen candidate and confirm:

- Behavior owns the source runtime responsibility.
- N1 slot ownership is correct.
- N2/N3 source-neutral realization is acceptable.
- Loss of opaque source CSS is accepted.
- The disposed carrier has no remaining source presentation, content, or accessibility duty.
- Picture source-neutral policy is acceptable.
- All exact fingerprints match.

Only after that review may the authorized reviewer call ComponentReview.approve_with_result/8. Require the exact ComponentReviewResult ID and final generation validation. Do not auto-approve.

## Final repository gates

After implementation, run from the repository root:

- mix format --check-formatted
- mix compile --warnings-as-errors
- mix assets.build
- mix test
- mix deps.unlock --check-unused
- git diff --check

Run mix deps.get only if dependency resolution requires the already-approved Phoenix constraint change. Also run focused browser and preview verification for two simultaneous Milan instances, manual selection, timer progression and stop, reduced motion, LiveView update, disconnect/reconnect, picture output, and keyboard focus.

## Performance review

Selection state stays in the browser. Each active instance owns at most one timer and one delegated listener. Activation performs no server round trip. Mount/reconcile is O(n); activation is O(n) for bounded caller collections. Behavior authority derivation and tree indexing are O(nodes + references), without repeated whole-tree scans for each guard.

## Global STOP conditions

- STOP=MAIN_MOVED
- STOP=DESIGN_DOCUMENT_MUTATION_REQUIRED
- STOP=BEHAVIOR_REISSUE_REQUIRED
- STOP=SERIALIZED_SCHEMA_CHANGE_REQUIRED
- STOP=SOURCE_RUNTIME_EXECUTION_REQUIRED
- STOP=SOURCE_RUNTIME_COPY_REQUIRED
- STOP=SOURCE_SELECTOR_RUNTIME_REQUIRED
- STOP=TABS_SEMANTICS_REQUIRED
- STOP=SERVER_STATE_REQUIRED
- STOP=ORDINARY_GENERIC_BUTTON_WIDENING_REQUIRED
- STOP=GLOBAL_IMAGE_TAG_WIDENING_REQUIRED
- STOP=NEW_GENERATED_ARTIFACT_KIND_REQUIRED
- STOP=NEW_UNAPPROVED_DEPENDENCY_REQUIRED
- STOP=FULL_GATE_REGRESSION
- STOP=MILAN_GOLDEN_IDENTITY_MISMATCH
