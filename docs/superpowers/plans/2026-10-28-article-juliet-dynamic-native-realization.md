# Lead 1 Article Juliet dynamic native realization implementation plan

**Plan version:** 1.0.0
**Date:** 2026-10-28
**Status:** implementation plan for review; no realization work authorized by this document
**Authority:** `docs/development/c09c7_article_juliet_dynamic_native_realization_authority.md`
**Base:** `f43a3f44eb1b14b2b8c0300a4a5be6ebee5b63d2`
**Tree:** `9b44ea7711b19a378c0e51aa4ca0c2e3a126ae1c`
**Base CI:** `40732110724 PASS`
**PR #349:** merged and accepted

```text
TASK=LEAD1_ARTICLE_JULIET_IMPLEMENTATION_PLAN_PUBLICATION
PLAN_PUBLICATION_ONLY=YES
IMPLEMENTATION_STARTED=NO
PRODUCTION_FILES_CHANGED=NO
TEST_FILES_CHANGED=NO
DATA_LAYER=COLD_COMPILE_AND_GENERATION
DB_INDEX=N/A
CACHE=NONE
TTL=N/A
REDIS=N/A
INVALIDATION=N/A
PUBSUB=N/A
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
```

## 1. Purpose and authority

This plan breaks the accepted C09C7 Article Juliet dynamic-native authority into gated Lead 1 work. It does not implement code or authorize Article Juliet realization. Each implementation phase needs its own focused change, signed commit, independent PR review, merge, and successful post-merge CI before the next phase starts.

The accepted flow is:

```text
Bricks source
-> source-independent Design IR 6.0.0
-> explicit SemanticInput
-> ComponentizationProposer
-> human-reviewed ComponentContract
-> matching ComponentizationPlan
-> NativeGenerator
-> Phoenix-native Article Juliet output
-> static fidelity/tracer acceptance
```

The reusable `apps/live_frames` library must stay independent from the preview application, Bricks, WordPress, and source runtimes. The host Phoenix application supplies collection data and final date strings. LiveFrames performs no backend query, source-expression execution, date-format execution, or runtime database or network access.

The plan follows these accepted authorities:

- `docs/development/c09c5_bricks_article_metadata_binding_authority.md`
- `docs/development/c09c6_datetime_attribute_representation_authority.md`
- `docs/development/c09d1_component_contract_authority.md`
- `docs/development/c09d3_componentization_plan_authority.md`
- `docs/development/c09d5_componentization_proposer_authority.md`
- `docs/development/c09d6_native_generation_authority.md`
- `docs/development/nav_carrier_heading_link_representation_authority.md`
- `docs/development/c09c7_article_juliet_dynamic_native_realization_authority.md`

The C09C7 decisions remain closed. Design IR stays at `6.0.0`. ComponentContract and ComponentizationPlan stay at `1.0.0`. The plan adds no serialized field, projection kind, public RenderProjection role, DesignNode semantic type, generic attribute system, or evidence waiver.

## 2. Repository baseline and locked decisions

PR #349 merged at the exact base above. Its post-merge CI run `40732110724` completed successfully. The tree is clean at plan start.

The base already contains these accepted capabilities:

```text
DESIGN_IR=6.0.0
VALUE_BINDING_TARGET_KIND=datetime_attribute
ARTICLE_JULIET_METADATA_TEXT_BINDINGS=IMPLEMENTED
ARTICLE_JULIET_CONTENT_URL_BINDING=link_url
ARTICLE_JULIET_DATETIME_BINDING=
  value_kind=field
  scope=collection_item
  value_key=content.published_at
  modifier=Opaque
  normalization_status=evidence_insufficient
DATETIME_AND_VISIBLE_TEXT_BINDINGS=SEPARATE_VALUE_BINDINGS
```

Do not redo or reinterpret the upstream IR and Bricks-normalization work. The source expression and date-format literal remain inert `SourceTrace` evidence. The `value_key` is an IR concept, not a public component field name.

The exact C09C7 caller-supplied path is the only evidence-insufficient exception. All other evidence-insufficient bindings keep the existing blocking behavior. The datetime binding and visible date-text binding continue to target the same source/native node, but they must project to distinct item fields.

## 3. Domain model and boundaries

| Record or stage | Owns | Frozen boundary for this programme |
| --- | --- | --- |
| `ValueBinding` | Source-neutral frontend destination and binding evidence | Datetime tuple remains `datetime_attribute`, `field`, `collection_item`, `Opaque`, `evidence_insufficient`. No source parser runs downstream. |
| `EvidenceHandlingDecision` | Transient proposal-time caller ownership decision | Add only `caller_supplied_destination_value` for the exact C09C7 tuple. Keep this decision non-serialized. |
| `BindingAssignmentDecision` | Explicit item-field assignment | Exactly one assignment for the datetime binding, using the ordinary `collection_item_field_value` path. |
| `ItemField` | Public collection-item input | Datetime destination is a required `:string` field with `default: nil`, distinct from the visible date-text field. |
| `BindingProjection` | Persisted binding-to-public-input link | Reuse ordinary `collection_item_field` with `source_binding_kind: :value`; add no projection kind. |
| `ComponentContract` provenance | Inert audit record | Record `provenance["evidence_handling"][binding_id] = %{"outcome" => "caller_supplied_destination_value"}`. |
| `ComponentizationPlan` | Placement and generation references | Validate the exact persisted opaque-datetime tuple after proposal and review. Do not recover transient decisions from prose. |
| `RenderProjection` | Existing unbound top-level public placement roles | Do not serialize `datetime_attribute` as a render role. |
| Native binding-role index | Mechanical binding-to-native locus mapping | Derive internal `datetime_attribute` role from the exact IR binding. Keep the role private to generation. |
| `NativeGenerator` | Phoenix-native markup from an approved tuple | Emit a closed heading/link structure and fixed `time datetime={value}` structure. Never parse source expressions or accept attribute names from callers. |

The dynamic heading stays one `DesignNode` with `semantic_type=heading`, a proven static `h1` through `h6` tag, no children, one `link_url` binding, and either a text binding or separately proven non-empty static text. The caller supplies a string heading-text field and owns its non-empty accessible-name contract. Do not add fallback text. The renderer-created inner anchor has no `DesignNode` identity. Heading attributes, classes, and styles stay on the heading. Its internal anchor receives only the established `color: inherit` and `text-decoration: inherit` neutralization. Native focus stays visible.

The datetime carrier preserves the current node semantic type. For Article Juliet, the adapter currently represents the source custom `time` tag on a `rich_text` node. Native validation may admit `time` only for the closed datetime-binding shape. It must not add `semantic_type=time`.

## 4. File map

Keep implementation within the current validator, proposer, and renderer boundaries. Reuse existing indexes and closed validators. Do not split files or introduce a new architectural layer unless repository evidence shows that doing so removes duplicated authority logic.

| File | Planned responsibility |
| --- | --- |
| `apps/live_frames/lib/live_frames/componentization_proposer/semantic_input.ex` | Add the new transient outcome to the `EvidenceHandlingDecision` type only. |
| `apps/live_frames/lib/live_frames/componentization_proposer/semantic_input/validation.ex` | Validate the exact outcome/binding tuple, one-to-one matching assignment, required string field shape, and date-text field distinctness. |
| `apps/live_frames/lib/live_frames/componentization_proposer/construction.ex` | Build the ordinary item-field `BindingProjection`, persist the inert audit, and omit the existing blocking diagnostic only for the exact valid caller decision. |
| `apps/live_frames/lib/live_frames/componentization_proposer.ex` | Preserve `:needs_review` for the exact opaque datetime candidate and keep every other evidence-insufficient binding on its current review path. |
| `apps/live_frames/lib/live_frames/component_contract/reference_validation.ex` | Admit only the exact persisted opaque datetime tuple; leave every generic evidence-insufficient binding blocked. |
| `apps/live_frames/lib/live_frames/componentization_plan/reference_validation.ex` | Validate the persisted tuple, heading-link closed shape, and scoped `time` carrier. Keep serialized render-role validation unchanged. |
| `apps/live_frames/lib/live_frames/native_generator/renderer.ex` | Emit the heading-owned wrapper with renderer-owned internal anchor, derive the private datetime binding role, and emit the fixed `datetime` attribute on `time`. |
| `apps/live_frames/lib/live_frames/native_generator/style_integration.ex` | Supporting file for P4C1 only if its existing heading-anchor detector must recognize the new dynamic shape. Reuse its bounded direct-child rule. |
| `apps/live_frames/lib/live_frames/native_generator/stylesheet_renderer.ex` | No change expected. Its existing bounded rule already expresses the required anchor neutralization. Stop for review if this assumption is false. |
| `apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs` | Exact semantic-input tuple, assignment cardinality, and negative cases. |
| `apps/live_frames/test/live_frames/componentization_proposer_test.exs` | Construction audit, projection, diagnostics, and `needs_review` outcome. |
| `apps/live_frames/test/live_frames/component_contract_reference_validation_test.exs` | Exact persisted tuple acceptance and generic evidence-insufficient rejection. |
| `apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs` | Plan tuple checks, heading carrier conflicts, and scoped `time` admission. |
| `apps/live_frames/test/live_frames/native_generator_test.exs` | Generated heading/link and `time datetime` output, escaping, and regressions. |
| `apps/live_frames/test/live_frames/native_generator/style_integration_test.exs` | P4C1 anchor-style ownership and focus-preservation regression. |
| `apps/live_frames/test/live_frames/article_juliet_native_tracer_test.exs` | P4E real-source integration proof, if a dedicated test gives the tracer a clear bounded responsibility. |
| `docs/development/article_juliet_componentization_preflight.md` | P4D review artifact with explicit human-selected public semantics for every admitted binding. Create only during P4D. |
| `docs/development/article_juliet_static_fidelity_residuals.md` | P5 classified residual inventory. Create only if P5 has residuals or a formal `NONE` record is needed. |

The named production/test files are the expected primary map. A phase may touch another existing file only when a focused test proves it owns the required behavior and the phase authority already covers it. Do not refactor unrelated large files.

## 5. State machines and phase gates

### 5.1 Proposal, review, and generation

```text
valid DesignDocument
-> exact SemanticInput validation
-> deterministic ComponentContract + ComponentizationPlan construction
-> intrinsic validation
-> reference validation
-> needs_review candidate
-> human ComponentReview
-> approved contract + matching valid plan
-> NativeGenerator
-> static fidelity/tracer acceptance
```

The exact caller-supplied destination path changes only candidate validity. It never changes the proposer outcome to `:proposed`. Human review remains required before generation. A malformed decision is `invalid_input`; an intrinsic construction defect is `construction_failed`; an otherwise valid exact candidate is `needs_review`.

### 5.2 Datetime decision and persisted tuple

```text
evidence_insufficient datetime_attribute binding
-> caller_destination_ownership_explicit
-> exactly_one matching collection_item_field_value assignment
-> required string field with nil default, distinct from visible date text
-> ordinary collection_item_field BindingProjection
-> inert provenance audit
-> needs_review candidate
-> human approval
-> persisted tuple revalidated by contract and plan validators
-> internal datetime_attribute binding role
-> fixed time/datetime emission
```

Proposal-time validation uses the transient decision and exact assignment. After persistence, contract and plan reference validation use the exact C09C7 tuple: datetime target, field value, collection-item scope, opaque modifier, evidence-insufficient status, valid collection ownership, one ordinary item-field projection, assigned `:string` item field, `required: true`, `default: nil`, a field distinct from visible date text, and a `time` carrier. The audit remains inert provenance. No other evidence-insufficient tuple passes.

Terminal outcomes include missing caller ownership, missing or duplicate assignment, public-field alias, wrong scope or modifier, wrong field type/default, wrong node, wrong carrier, and any need for a generic waiver, generic attribute, or source-format execution.

### 5.3 Dynamic heading link

```text
normalized collection-item text and link_url bindings
-> one explicit text field and one explicit URL field
-> one childless heading with proven static h1-h6 tag
-> no static navigation, dynamic heading_level, or subtree slot conflict
-> validated heading carrier
-> heading-owned outer attrs/classes/styles
-> renderer-owned direct-child anchor with escaped href and text
```

Reject a missing or unproven tag, children, static navigation conflict, heading-level projection, subtree slot, multiple destination owners, invalid binding, or missing text owner. Do not change URL trust or safety rules, infer Phoenix navigation, or synthesize a DesignNode.

### 5.4 Required sequencing

```text
L1-J1 / P4B
-> merge and successful exact post-merge CI
-> L1-J2 / P4C1
-> merge and successful exact post-merge CI
-> L1-J3 / P4C2
-> merge and successful exact post-merge CI
-> L1-J4 / P4D review acceptance
-> L1-J5 / P4E real-source proof
-> merge and successful exact post-merge CI
-> L1-J6 / P5 residual review
-> L1-J7 / Lead 1 closure or cross-lane handoff
```

Do not start a downstream phase while its named prerequisite is open or has failed post-merge CI. An authority conflict or any hard STOP condition ends the phase for review.

## 6. Implementation phases

Every code phase follows the same change lifecycle: write the focused failing test first, run it and record the real RED evidence, make the smallest authorized implementation, run focused GREEN tests, run all repository gates, create a signed commit, open a phase PR, obtain independent PR review, resolve required findings, merge only after approval, and verify successful post-merge CI at the exact merge head. Do not claim RED when an assertion already passes. Record characterization evidence and continue only if the capability is still missing.

Use a signed commit for every implementation PR and verify it before push:

```sh
git commit -S -m "feat: implement the authorized Article Juliet phase"
git verify-commit HEAD
```

For each code phase, the complete repository gate is:

```sh
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix assets.build
mix test
mix deps.unlock --check-unused
git diff --check
```

If `.devcore/project.conf` governs a future checkout, follow its local test/runtime command contract and run database-dependent commands through `devcore-project run test -- ...` or `devcore-project run dev -- ...`. This programme adds no database-dependent work. Never introduce or copy database credentials. No test, format, or compile failure may be hidden or weakened.

### L1-J1 / P4B: caller-supplied datetime componentization

**Goal:** Let only the exact C09C7 opaque datetime destination form a structurally valid candidate, preserve human review, and keep all other evidence-insufficient bindings blocked.

**Files:** the SemanticInput, validation, construction, proposer, ComponentContract reference-validation, and ComponentizationPlan reference-validation files in the file map; their four named focused test files.

**Test-first sequence:**

1. Add a valid semantic-input case for the exact `datetime_attribute` / `field` / `collection_item` / `Opaque` / `evidence_insufficient` binding, one matching `collection_item_field_value` assignment, and a required string item field with nil default. Give the visible date text a separate item field.
2. Add malformed cases for each changed tuple member, zero or multiple matching assignments, wrong assignment kind, wrong field type, optional field, non-nil default, and field alias with visible date text. Keep existing `omit_public_projection` tests as unchanged regressions.
3. Add contract and plan reference cases proving the exact persisted tuple passes and a generic evidence-insufficient projection remains blocked. Add proposer assertions for the ordinary item-field projection, exact provenance audit, no blocking evidence diagnostic for the one authorized tuple, no uncovered diagnostic for that binding, and final `outcome: :needs_review`.
4. Run the four focused test files before implementation:

   ```sh
   mix test apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs apps/live_frames/test/live_frames/componentization_proposer_test.exs apps/live_frames/test/live_frames/component_contract_reference_validation_test.exs apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs
   ```

   Expected RED: SemanticInput rejects the new outcome, construction emits no accepted candidate, and current reference validators block evidence-insufficient projection. Record any assertions that already pass as characterization; do not alter expectations to manufacture RED.
5. Implement only the exact closed decision and persisted-tuple rules. Keep `omit_public_projection` unchanged. Build or reuse indexes once; do not add a generic waiver flag or scan the full binding registry per decision.
6. Rerun the four focused test files. GREEN requires the exact tuple to produce an ordinary `collection_item_field` projection and `:needs_review`; all malformed and generic evidence-insufficient cases stay blocked; omission behavior is unchanged.
7. Run the full repository gates above. Create one signed implementation commit, open the P4B PR, obtain independent review, merge after approval, and verify exact-head post-merge CI before P4C1.

**P4B acceptance:**

```text
EXACT_CALLER_DATETIME_SEMANTIC_INPUT=VALID
EXACT_CALLER_DATETIME_PROJECTION=VALID
PROPOSER_RESULT=needs_review
GENERIC_EVIDENCE_INSUFFICIENT_PROJECTION=BLOCKED
OMIT_PUBLIC_PROJECTION_BEHAVIOR=UNCHANGED
```

### L1-J2 / P4C1: dynamic heading-link realization

**Prerequisite:** P4B merged with successful post-merge CI.

**Goal:** Render a collection-item title and URL through one semantic heading containing a renderer-owned anchor, for the closed C09C7 shape only.

**Files:** `apps/live_frames/lib/live_frames/componentization_plan/reference_validation.ex`, `apps/live_frames/lib/live_frames/native_generator/renderer.ex`, and, only if the current heading-anchor detection requires it, `apps/live_frames/lib/live_frames/native_generator/style_integration.ex`. Tests belong in `componentization_plan_reference_validation_test.exs`, `native_generator_test.exs`, and `native_generator/style_integration_test.exs`.

**Test-first sequence:**

1. Add positive cases for a childless heading with each proven static tag `h1` through `h6`, one `link_url` binding, and a text binding. Add the separately proven non-empty static-text variant only if the test fixture proves that shape without relaxing the dynamic-title path.
2. Assert generated shape keeps heading attrs/classes/styles on the outer heading and places escaped caller text inside a direct-child `<a href={caller_value}>`. Assert the anchor has no DesignNode identity and gets only `color: inherit` and `text-decoration: inherit` from the existing renderer-owned style rule.
3. Add rejection cases for children, absent/unproven tag, static navigation conflict, `heading_level` projection, subtree slot, duplicate destination owners, missing text owner, and incompatible binding. Assert no precedence silently selects one destination.
4. Run the focused plan, renderer, and style-integration tests:

   ```sh
   mix test apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs apps/live_frames/test/live_frames/native_generator_test.exs apps/live_frames/test/live_frames/native_generator/style_integration_test.exs
   ```

   Expected RED is a blocked current heading carrier or missing nested dynamic href. Record any already-passing shape as characterization.
5. Extend only the closed native compatibility check and renderer branch. Reuse the existing heading direct-child anchor neutralization. Do not add a global anchor reset, suppress focus, add JavaScript, infer Phoenix navigate/patch behavior, or change URL safety.
6. Rerun the focused tests. GREEN requires all six tags on the outer heading, dynamic escaped `href` and text on the renderer-owned anchor, preserved heading ownership, visible focus behavior, and every conflict rejection.
7. Run the full repository gates, create one signed implementation commit, open the P4C1 PR, obtain independent review, merge after approval, and verify exact-head post-merge CI before P4C2.

### L1-J3 / P4C2: fixed datetime native realization

**Prerequisite:** P4C1 merged with successful post-merge CI.

**Goal:** Emit a caller-supplied destination-ready string as the fixed `datetime` attribute on a proven `time` carrier.

**Files:** `apps/live_frames/lib/live_frames/componentization_plan/reference_validation.ex`, `apps/live_frames/lib/live_frames/native_generator/renderer.ex`, `componentization_plan_reference_validation_test.exs`, and `native_generator_test.exs`.

**Test-first sequence:**

1. Add the exact persisted tuple positive test using a current `rich_text` node with normalized `attributes["tag"] = "time"`, a distinct visible date text field, and an opaque datetime field. Assert the private role derives from the IR binding and is absent from `RenderProjection.render_roles/0` and serialized plans.
2. Assert generation emits `<time datetime={caller_value}>caller_visible_date</time>` with normal HEEx escaping. Assert the compiler fixes the attribute name while callers control only the value.
3. Add negative tests for wrong carrier, wrong target, wrong scope, non-field value, non-Opaque modifier, non-evidence-insufficient status in the special path, missing caller decision at proposal time, wrong item-field type/default, and reuse of the visible date-text field.
4. Run the focused plan-reference and native-generator tests:

   ```sh
   mix test apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs apps/live_frames/test/live_frames/native_generator_test.exs
   ```

   Expected RED is current evidence-insufficient blocking and unsupported `time` tag for this `rich_text` carrier. Record already-passing assertions as characterization.
5. Add the internal `datetime_attribute` binding-native role and admit `time` only for the exact tuple. Preserve the DesignNode semantic type. Render only the fixed `datetime` attribute from the assigned item field. Add no serialized role, generic attribute map, dynamic attribute name, parser, formatter, or timezone logic.
6. Rerun the focused tests. GREEN requires exact tuple emission and every near-miss to stay blocked; existing rich_text carriers and all other evidence-insufficient cases retain current behavior.
7. Run the full repository gates, create one signed implementation commit, open the P4C2 PR, obtain independent review, merge after approval, and verify exact-head post-merge CI before P4D.

### L1-J4 / P4D: Article Juliet semantic componentization preflight

**Prerequisite:** P4B, P4C1, and P4C2 are merged and green.

**Goal:** Freeze the real reusable component semantics through a human-reviewed artifact before a tracer implementation chooses public names or assignments.

**Output:** `docs/development/article_juliet_componentization_preflight.md`, a docs-only review artifact. Do not change production code or tests in this phase.

The preflight must inspect the accepted `sources/bricks_components.json` component `idjmjz`, the resulting current IR 6 document, and the accepted C09C2/C09C4/C09C5/C09C6/C09C7 evidence. It must inventory every currently admitted in-boundary `ValueBinding` and `CollectionBinding`; do not assume every source expression in the export is an admitted binding. The preflight must record the evidence reference for each decision without using source IDs or expressions as production predicates.

The reviewer must explicitly accept:

| Decision | Required contents |
| --- | --- |
| Contract identity | Stable source-independent ID and reason. |
| Classification | Category, module intent, and function intent. |
| Boundary | One exact DesignNode boundary and collection ownership. |
| Collection API | Public list name and its item collection input. |
| Item fields | Human-selected names for every admitted item binding, type, required/default rule, and semantic purpose. |
| Date pair | Separate public names and purposes for visible published-date text and caller-supplied datetime destination. |
| Binding assignments | One explicit assignment for every admitted binding, including content title, URL, metadata, image, and both date bindings wherever present in the current IR. |
| Evidence handling | Exact `caller_supplied_destination_value` decision for the opaque datetime binding and no broader exception. |
| Consumer duties | Identify caller-supplied final datetime string and heading/link data responsibilities. |

Names such as `published_at_text` and `published_at_datetime` are examples only. The reviewer must choose actual names. Never derive public names from `value_key`, Bricks source IDs, source expressions, editor labels, CSS classes, or filenames. Do not approve the preflight until every admitted in-boundary binding has an explicit assignment or a documented authority-backed exclusion. P4E must not mechanically fill any missing semantic decision.

### L1-J5 / P4E: real Article Juliet end-to-end acceptance

**Prerequisite:** P4D accepted and the three generic P4B/P4C capabilities merged-green.

**Goal:** Prove the accepted real source through IR, explicit semantic input, proposal, human approval, matching plan, NativeGenerator, and static fidelity/tracer acceptance.

**Files:** Prefer a dedicated `apps/live_frames/test/live_frames/article_juliet_native_tracer_test.exs` for the bounded real-source proof. Reuse the existing Bricks adapter, IR, proposer, review, plan, fidelity, and NativeGenerator entry points. Production changes are outside the expected scope; if a failing test shows an authorized generic P4B/P4C rule is still absent, stop and reauthorize that phase instead of adding a Juliet-specific branch.

**Test-first sequence:**

1. Build a real-source test from `sources/bricks_components.json` and component `idjmjz`. Feed its accepted source through the existing adapter to validated IR 6. Use the explicit P4D SemanticInput decisions. Do not derive public names from the source fixture.
2. Assert the proposer returns a `needs_review` candidate with the exact caller-destination audit and no generic evidence waiver. Exercise the existing human ComponentReview path to an approved contract. Validate the matching ComponentizationPlan against the same DesignDocument identity.
3. Generate and render caller data for dynamic title, content URL, visible published date, final datetime destination, and every other accepted P4D public field. Assert the heading anchor and `time datetime` structure, field distinctness, HTML escaping, required/default rules, and data values.
4. Assert generated module and stylesheet contain no Bricks source IDs, raw source expressions, source query settings, `post_date` parser, `post_url` parser, source-runtime module, or format literal execution. The test may reference source IDs only to locate source evidence in the fixture. No runtime DB or network call is allowed.
5. Add or update static fidelity/tracer acceptance using the repository's established acceptance path. Compare the accepted static node/content/style evidence with the generated one-item Phoenix-native output. Record any difference without assigning it to Lead 1 until P5 classifies it.
6. Run the focused tracer test:

   ```sh
   mix test apps/live_frames/test/live_frames/article_juliet_native_tracer_test.exs
   ```

   If its behavior assertions fail, capture the real RED and fix only an already-authorized generic rule. If the assertions already pass, report characterization evidence honestly and keep P4E proof-only; do not make an artificial change to obtain RED.
7. Run the full repository gates, create one signed proof/test commit, open the P4E PR, obtain independent review, merge after approval, and verify exact-head post-merge CI before P5.

### L1-J6 / P5: static fidelity residual review

**Prerequisite:** P4E accepted with real-source static fidelity/tracer evidence.

**Goal:** Classify each remaining Article Juliet mismatch before authorizing any broader compiler work.

Produce a residual inventory in `docs/development/article_juliet_static_fidelity_residuals.md` when residuals remain. If no mismatches remain, record `LEAD1_STATIC_RESIDUALS=NONE` in the P4E/P5 acceptance record. For every mismatch, include the observed source evidence, the generated output, its cause, owner, and one classification:

```text
existing generic capability
Lead 1 missing generic static capability
Fluid-owned capability
Behavior-owned capability
source-evidence gap
component-specific composition
unsupported / accepted limitation
```

Only a proven Lead 1 generic static-capability gap may support a separate implementation proposal. Do not expand CSS/native compiler behavior speculatively. Keep Romeo parked. A Fluid or Behavior issue becomes a handoff; do not implement it in this programme. This phase is review/documentation work and has no production or test-file changes.

### L1-J7: Lead 1 closure or handoff

Close Lead 1 only when all of these are supported by accepted artifacts and exact CI evidence:

```text
ARTICLE_JULIET_SOURCE_SEMANTICS=ACCEPTED
ARTICLE_JULIET_IR=ACCEPTED
ARTICLE_JULIET_COMPONENTIZATION=ACCEPTED
ARTICLE_JULIET_NATIVE_REALIZATION=ACCEPTED
LEAD1_STATIC_RESIDUALS=NONE|EXPLICITLY_CLASSIFIED
ROMEO_STATUS=PARKED
```

If the only remaining blocker belongs to Fluid or Behavior, stop with `STOP=CROSS_LANE_HANDOFF_REQUIRED` and name the receiving lane and evidence. Do not implement another lane's work. If a residual is a Lead 1 generic capability gap, submit it for separate authorization; it is outside this plan's approved scope.

## 7. Future micro-prompts

Each micro-prompt inherits the sequence, signed-commit, independent-review, full-gate, security, and stop rules in this plan. These prompts do not authorize work before their prerequisites are accepted.

### P4B micro-prompt

| Field | Content |
| --- | --- |
| Task | Implement the exact `caller_supplied_destination_value` componentization path. |
| Objective | Allow the opaque Article Juliet datetime destination to become a structurally valid candidate while preserving human review and the global evidence-insufficient fail-closed rule. |
| Output | SemanticInput, proposer construction/outcome, contract/plan reference-validation changes, and focused tests. |
| Note | No generic evidence waiver; exact tuple only; result `needs_review`; existing `omit_public_projection` unchanged; no native renderer work. `DATA_LAYER=COLD_COMPILE_AND_GENERATION`; `DB_INDEX=N/A`; `CACHE=NONE`; `TTL=N/A`; `REDIS=N/A`; `INVALIDATION=N/A`; `PUBSUB=N/A`; `RUNTIME_DB_CALLS=0`; `RUNTIME_NETWORK_CALLS=0`. |

### P4C1 micro-prompt

| Field | Content |
| --- | --- |
| Task | Add closed dynamic heading-link native realization. |
| Objective | Render normalized collection-item title and URL bindings as a semantic heading containing a renderer-owned anchor. |
| Output | Native compatibility/renderer changes and focused NAV-CARRIER regressions, including bounded style-integration coverage. |
| Note | Static h1-h6 only; children forbidden; static-navigation, heading-level, subtree-slot, and multiple-destination conflicts fail closed; no JS; no global anchor reset; preserve visible focus; no URL safety change. `DATA_LAYER=COLD_COMPILE_AND_GENERATION`; `DB_INDEX=N/A`; `CACHE=NONE`; `TTL=N/A`; `REDIS=N/A`; `INVALIDATION=N/A`; `PUBSUB=N/A`; `RUNTIME_DB_CALLS=0`; `RUNTIME_NETWORK_CALLS=0`. |

### P4C2 micro-prompt

| Field | Content |
| --- | --- |
| Task | Add fixed `datetime_attribute` native realization on a proven `time` carrier. |
| Objective | Emit caller-supplied destination-ready datetime strings without source-format execution or a generic attribute system. |
| Output | Internal binding-role/native-carrier/renderer changes and exact-tuple tests. |
| Note | Keep current DesignNode semantic type; add no serialized RenderProjection role; use fixed `datetime` name; no parsing, formatting, or timezone logic. `DATA_LAYER=COLD_COMPILE_AND_GENERATION`; `DB_INDEX=N/A`; `CACHE=NONE`; `TTL=N/A`; `REDIS=N/A`; `INVALIDATION=N/A`; `PUBSUB=N/A`; `RUNTIME_DB_CALLS=0`; `RUNTIME_NETWORK_CALLS=0`. |

### P4D micro-prompt

| Field | Content |
| --- | --- |
| Task | Freeze real Article Juliet componentization decisions. |
| Objective | Prevent implementation agents from inventing public component semantics from source identifiers or `value_key`. |
| Output | Reviewable Article Juliet semantic preflight/authority artifact with explicit contract and item-field decisions. |
| Note | Visible date and datetime fields are distinct; cover every admitted real binding; make no production changes. `DATA_LAYER=COLD_COMPILE_AND_GENERATION`; `DB_INDEX=N/A`; `CACHE=NONE`; `TTL=N/A`; `REDIS=N/A`; `INVALIDATION=N/A`; `PUBSUB=N/A`; `RUNTIME_DB_CALLS=0`; `RUNTIME_NETWORK_CALLS=0`. |

### P4E micro-prompt

| Field | Content |
| --- | --- |
| Task | Prove the real Article Juliet end-to-end native tracer. |
| Objective | Demonstrate real source through IR, componentization, human approval, and NativeGenerator with no source-runtime dependency. |
| Output | Real-source integration proof/tests and accepted native generation evidence. |
| Note | Use `sources/bricks_components.json` / `idjmjz`; no source IDs in production branching; no raw expression reaches generated output; classify RED or existing behavior honestly. `DATA_LAYER=COLD_COMPILE_AND_GENERATION`; `DB_INDEX=N/A`; `CACHE=NONE`; `TTL=N/A`; `REDIS=N/A`; `INVALIDATION=N/A`; `PUBSUB=N/A`; `RUNTIME_DB_CALLS=0`; `RUNTIME_NETWORK_CALLS=0`. |

### P5 micro-prompt

| Field | Content |
| --- | --- |
| Task | Classify real tracer static-fidelity residuals. |
| Objective | Determine whether a remaining mismatch is genuinely Lead 1 generic compiler work before expanding the compiler. |
| Output | Residual inventory with ownership classification and any separately authorized generic follow-up. |
| Note | No speculative CSS/compiler expansion; Romeo remains parked; cross-lane gaps become handoffs; no production/test changes. `DATA_LAYER=COLD_COMPILE_AND_GENERATION`; `DB_INDEX=N/A`; `CACHE=NONE`; `TTL=N/A`; `REDIS=N/A`; `INVALIDATION=N/A`; `PUBSUB=N/A`; `RUNTIME_DB_CALLS=0`; `RUNTIME_NETWORK_CALLS=0`. |

## 8. Performance and security review

All programme work is cold compile, validation, generation, or static fidelity review. Keep the required bounds:

```text
semantic validation=O(bindings + decisions + references)
reference indexing=O(nodes + bindings + projections)
rendering=O(nodes + bindings)
```

Build or reuse indexes once per validation/render pass. Do not repeat a full-document or full-binding scan inside per-binding loops. Do not add cache, database, queue, pub/sub, network, or runtime lookup work.

Every phase must preserve:

```text
ARBITRARY_DYNAMIC_ATTRIBUTES=FORBIDDEN
DYNAMIC_ATTRIBUTE_NAME_FROM_CALLER=FORBIDDEN
EVENT_HANDLER_BINDINGS=FORBIDDEN
RAW_HTML=FORBIDDEN
SOURCE_EXPRESSION_EXECUTION=FORBIDDEN
SOURCE_FORMAT_EXECUTION=FORBIDDEN
DYNAMIC_CODE_EVALUATION=FORBIDDEN
GENERIC_EVIDENCE_WAIVER=FORBIDDEN
SOURCE_SPECIFIC_PRODUCTION_BRANCHING=FORBIDDEN
```

The datetime compiler owns the literal attribute name `datetime`; the caller supplies only the escaped string value. The heading URL uses existing caller-supplied `link_url` safety and normal HEEx escaping. Neither path accepts arbitrary HTML attributes, source formats, callbacks, or executable terms.

## 9. Risks and stop conditions

| Risk | Required control |
| --- | --- |
| Evidence exception widens beyond the exact datetime tuple | Test each tuple member, one-to-one assignment, exact field, and generic evidence-insufficient regressions in both proposal and persisted reference validation. |
| Visible date and datetime destination collapse into one field | Require distinct public ItemFields and assert the plan reference validator rejects aliases. |
| Dynamic heading silently beats static navigation or heading-level behavior | Reject static navigation, `heading_level`, subtree-slot, children, unproven tag, and duplicate destination owners. |
| Renderer-owned anchor loses heading styles or focus behavior | Keep heading attrs/classes/styles on the outer heading; reuse only bounded `color: inherit` and `text-decoration: inherit`; keep native visible focus. |
| `time` becomes a new generic semantic type or accepted rich-text tag | Admit the normalized `time` tag only for the exact datetime binding carrier; preserve current semantic type. |
| Implementation infers public names from source material | Require accepted P4D decisions before P4E; do not use source IDs, expressions, labels, `value_key`, classes, or paths to name public inputs. |
| Article Juliet requires another lane | Stop and hand off Fluid or Behavior work; no page-composition or source runtime work in Lead 1. |
| Validation/rendering grows superlinear | Index nodes, bindings, projections, fields, and decisions once per pass and keep the stated complexity bounds. |

Stop on any of these conditions:

```text
STOP=MAIN_MOVED_WITH_RELEVANT_AUTHORITY_CONFLICT
STOP=C09C7_CONTRADICTED
STOP=GENERIC_EVIDENCE_WAIVER_REQUIRED
STOP=SERIALIZED_FORMAT_CHANGE_REQUIRED
STOP=NEW_DESIGN_NODE_SEMANTIC_TYPE_REQUIRED
STOP=GENERIC_DYNAMIC_ATTRIBUTE_SYSTEM_REQUIRED
STOP=SOURCE_FORMAT_EXECUTION_REQUIRED
STOP=DYNAMIC_LINK_URL_SAFETY_MODEL_CHANGE_REQUIRED
STOP=SOURCE_SPECIFIC_PRODUCTION_BRANCH_REQUIRED
STOP=BEHAVIOR_RUNTIME_REQUIRED
STOP=FLUID_IMPLEMENTATION_REQUIRED
STOP=PAGE_COMPOSITION_REQUIRED
STOP=NON_DOC_FILE_CHANGED
STOP=IMPLEMENTATION_STARTED
STOP=PR_MERGED
```

For P4A plan publication, any production/test file change is out of scope. Open the docs-only PR, leave it unmerged, and stop for final plan review.

## 10. Acceptance and handoff report

At each phase handoff, record the exact base/merge SHA, tree, signed commit, PR head, review state, CI run and result, changed files, focused test results, full-gate results, and any skipped gate with its reason. Use exact commit references; do not report a green CI result against a different head.

The Article Juliet programme is complete only when L1-J7 records:

```text
ARTICLE_JULIET_SOURCE_SEMANTICS=ACCEPTED
ARTICLE_JULIET_IR=ACCEPTED
ARTICLE_JULIET_COMPONENTIZATION=ACCEPTED
ARTICLE_JULIET_NATIVE_REALIZATION=ACCEPTED
LEAD1_STATIC_RESIDUALS=NONE|EXPLICITLY_CLASSIFIED
ROMEO_STATUS=PARKED
```

If only a Fluid or Behavior blocker remains, use `STOP=CROSS_LANE_HANDOFF_REQUIRED`. Do not mark the Lead 1 programme complete until every required proof and handoff record exists.
