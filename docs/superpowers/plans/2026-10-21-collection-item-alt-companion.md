# Collection-item alt companion implementation plan

> This plan describes G2-B work. It may be executed only after G2-A is reviewed and merged and G2-B is separately authorized.

**Goal:** Allow a binding-backed collection-item image source to use one explicit caller-owned sibling `:string` ItemField as consumer-supplied alt when the source Design IR has no alt ValueBinding.

**Architecture:** Preserve the current binding-backed sibling alt path. Add one closed unbound accessibility-companion path, validated in SemanticInput and `ReferenceValidation`, then rendered through the existing `lf_item_field/3` accessor. The companion has `required: false` and `default: nil`; runtime requires a non-empty value only while the image source is present.

**Tech stack:** Elixir, ExUnit, `ComponentizationSemanticInput`, `ComponentizationPlan`, and the Phoenix native generator.

## Constraints

- Do not change `ComponentContract`, `ComponentizationPlan`, or `SemanticInput` serialized schemas or format versions.
- Do not add a decision family, marker field, RenderProjection role, binding kind, runtime accessor, or dependency.
- Do not change proposer construction unless a failing test proves that the current constructor cannot materialize the companion ItemField without a BindingAssignmentDecision. If that happens, stop with `STOP=UNEXPECTED_PROPOSER_CONSTRUCTION_CHANGE_REQUIRED`.
- Preserve `VALUE_BINDING_COVERAGE_RULE`: every real in-boundary ValueBinding still needs its ordinary BindingProjection.
- Build reverse companion-reference and projection indexes once. Do not rescan the whole contract or DesignDocument for each image source.
- This work runs at validation or generation time. It adds no runtime database, network, polling, Redis, Postgres, PubSub, GenServer, or Oban work.
- Do not create Milan SemanticInput, choose Milan owner decisions, call ComponentReview, resume Task 10, or classify Milan images decorative.

## Task 1 — Validate the companion relationship in SemanticInput

**Production file:** `apps/live_frames/lib/live_frames/componentization_proposer/semantic_input/validation.ex`

**Test files:**

- `apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs`
- `apps/live_frames/test/live_frames/componentization_proposer_test.exs`

1. Write failing tests for a binding-backed image source with an unbound, same-collection companion ItemField. Assert the SemanticInput validates, construction emits that ordinary ItemField, and construction emits no BindingProjection for it.
2. Write failing tests for each invalid relationship: missing companion, companion in another collection, non-string type, `required: true`, non-nil default, a BindingAssignmentDecision targeting the companion, and two consumer-supplied image sources referencing the same companion.
3. Run the focused tests and confirm the new cases fail for the expected validation reason while the existing binding-backed sibling cases still pass.
4. Add only SemanticInput validation for the closed relationship. Reuse the existing decision structs. Do not change record fields or proposer construction.
5. Run the focused tests again. Confirm the valid case and every rejection case pass, and confirm there is no BindingProjection for the companion.

## Task 2 — Validate the XOR paths in `ReferenceValidation`

**Production file:** `apps/live_frames/lib/live_frames/componentization_plan/reference_validation.ex`

**Test file:** `apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs`

1. Add failing tests proving the legacy same-node text-binding consumer-alt path still passes and the new zero-projection companion path passes.
2. Add failing tests proving rejection when the companion has any projection, wrong type, `required: true`, non-nil default, is missing, belongs to another collection, or is reused by two image sources. Confirm decorative policy behavior remains unchanged.
3. Run the focused test file and confirm each new case reaches the intended reference-validation result.
4. Build one reverse index for companion references and reuse existing field and projection indexes. Validate that the source has one binding-backed collection-item asset projection to a Design IR image node, and validate every companion guard from D1/D3.
5. Run the focused test file again. Confirm both XOR branches pass only under their own rules and that the existing ValueBinding coverage check remains unchanged.

## Task 3 — Render the unbound companion through the existing item accessor

**Production file:** `apps/live_frames/lib/live_frames/native_generator/renderer.ex`

**Test file:** `apps/live_frames/test/live_frames/native_generator_test.exs`

1. Add a focused compile/render integration test for a validated plan with an unbound accessibility companion. Assert the generated component reads the exact `alt_item_field_name` from the current collection item and ordinal through `lf_item_field/3`.
2. Prove a non-empty companion renders as `alt`; a nil or empty companion with a present image source raises the existing deterministic accessibility error; an optional absent image source omits the image without evaluating or requiring the companion.
3. Prove string-keyed and existing atom-keyed collection items both work. Keep tests free of `String.to_atom/1`, `String.to_existing_atom/1`, source execution, or arbitrary substring-only assertions.
4. Confirm the existing binding-backed `asset_alt` output remains byte- and behavior-compatible.
5. Add the smallest renderer branch that reads the validated companion via the existing `lf_item_field/3` accessor. Do not create a new accessor, BindingProjection, RenderProjection, render role, or runtime dependency.
6. Run the focused native generator test file and confirm all legacy and companion cases pass.

## Completion checks

After all three tasks, review the diff and run the focused tests listed above. Confirm no schema or version changes, no generic unbound ItemField support, no new render role or binding kind, no new dependency, and no per-item or per-node whole-document rescans. Implementation completion does not authorize or resume Task 10.
