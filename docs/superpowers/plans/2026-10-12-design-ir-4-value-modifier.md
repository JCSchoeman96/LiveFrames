# Design IR 4.0.0 ValueModifier Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Add a required, closed ValueModifier tagged union to Design IR 4.0.0 and migrate Design IR 3.0.0 bindings without recovering new source semantics.

**Spec:** [C-09B2 Design IR 4.0.0 value modifier authority](../../development/c09b2_design_ir_4_value_modifier_authority.md). It controls the serialized variants, validation invariants, caller ownership, and migration limits in every task below.

**Behavior identity compatibility:** [C-09B2A Behavior identity version compatibility authority](../../development/c09b2a_behavior_identity_version_compatibility_authority.md) controls which Design IR identity versions BehaviorContract 1.0.0 and BehaviorReviewResult 1.0.0 accept. Read and apply it before implementation. IR4 promotion is gated on the compatibility validation and exact-document tests in that authority.

**Architecture:** Keep the v3 contract historical and add the v4 model to the existing IR reader, serializer, validator, and migration chain. Serialize one required nested modifier object per ValueBinding; use closed variant structs internally and exact-shape maps at the JSON boundary. The caller owns applying resolved transformations before supplying bound values.

**Tech Stack:** Elixir umbrella app, Jason JSON serialization, Mix ExUnit tests, Markdown authority documents.

---

## Scope and gates

This plan implements the generic Design IR representation and structural
migration only. It includes mechanical updates to current Bricks adapter
construction so the repository compiles after removing the v3 struct field.
That compatibility update retains each existing `:none` or `:opaque` result.
It does not authorize new Bricks parsing or semantics. In particular,
`{post_content:16}` remains opaque with `evidence_insufficient`. Do not emit a
resolved `word_limit`, generalize numeric-suffix parsing, or re-normalize
Feature Milan. Do not regenerate Milan behavior identities, create
SemanticInput, run D0, call the proposer, or start P7-D1/runtime work. Those
activities require later source-mapping and exact-document approval gates.

The original IR4 plan was authored at base
`4b335ac496a0c8536923101dac6770f94d4b994e`, tree
`56dfeebca4d0f9f254ab1d19e3e49e4d43800296`. That implementation base is
superseded. Begin or resume implementation only from the exact accepted main
SHA and tree supplied by the review gate after C-09B2A is merged and its exact
post-merge CI passes. The review gate supplies that implementation base; do
not guess a future merge SHA. Stop if `origin/main` differs from the supplied
implementation base.

The serialized v4 variants are exactly:

    {"status":"none"}
    {"status":"opaque"}
    {"status":"resolved","kind":"word_limit","arguments":{"count":16}}

none may retain either normalization status allowed by existing evidence
rules. opaque requires evidence_insufficient; resolved requires normalized,
target_kind=text, value_kind=field, and scope=collection_item or site.
Migration preserves old normalization status and never infers resolved
semantics.

## Global constraints

- Keep Design IR 3.0.0 artifacts and migration fixtures in their historical
  shape. Do not rewrite historical documentation to describe v4.
- Promote `DesignDocument.current_ir_version/0` to `"4.0.0"` only at the
  coherent production integration boundary described below.
- Preserve existing Bricks classifier decisions mechanically. Existing
  `:none` maps to `ValueModifier.None`; existing `:opaque` maps to
  `ValueModifier.Opaque`. The current `{post_content:16}` input stays opaque
  with `evidence_insufficient`.
- Do not add source-specific parsing, infer semantics from `SourceTrace`, or
  add a Bricks or WordPress runtime dependency.
- Do not regenerate Milan source documents, identities, BehaviorContracts, or
  BehaviorReviewResults in this implementation slice.
- Keep BehaviorContract and BehaviorReviewResult at format version 1.0.0,
  with their exact serialized fields and canonicalization unchanged. Preserve
  frozen IR3 Behavior bytes, digests, and review IDs. Implement only the
  C-09B2A compatibility validation: Behavior artifacts support the closed IR
  identity set 3.0.0 and 4.0.0, while exact DesignDocument identity matching
  remains mandatory. Do not rewrite or reissue historical artifacts.
- Never convert serialized modifier strings or argument keys into atoms.
- Keep migration deterministic, side-effect-free, and O(document size).

## Review focus

- The v4 serializer emits exactly one nested `modifier` object and never emits
  top-level `modifier_status`.
- The loader fails closed on malformed tagged variants and routes legacy
  artifacts through explicit migration.
- Migration preserves v3 normalization evidence and provenance, and never
  resolves an opaque source expression.
- Existing adapter behavior stays unchanged except for constructing the new
  modifier structs.
- Identity tests distinguish actual v4 modifier state and never call a
  current-version identity API on an un-migrated v3 document.
- The integrated branch compiles and all current ValueBinding constructors
  use the v4 struct before version promotion is committed.

## File map

- docs/03_DESIGN_IR_SPEC.md: update from the implemented v3 contract to the
  v4 contract in the implementation phase.
- docs/development/c09b2_design_ir_4_value_modifier_authority.md: accepted
  authority for the v4 modifier model and migration rule; keep the v3 C-09B
  document as historical authority.
- apps/live_frames/lib/live_frames/ir/value_modifier.ex: closed internal
  modifier variants and their types.
- apps/live_frames/lib/live_frames/ir/value_binding.ex: require a nested
  modifier and remove the v3 modifier_status field.
- apps/live_frames/lib/live_frames/ir/design_document.ex: promote the
  current IR version only with the complete v4 reader/writer path.
- apps/live_frames/lib/live_frames/ir/migration.ex: extend the existing
  named migration chain through 3.0.0 to 4.0.0.
- apps/live_frames/lib/live_frames/ir/serializer.ex: encode the nested
  tagged union and omit the old top-level field.
- apps/live_frames/lib/live_frames/ir/validation.ex: enforce modifier
  shape, arguments, scope, target, and normalization invariants.
- apps/live_frames/lib/live_frames/fidelity/document_loader.ex: decode
  exact v4 modifier variants without dynamic atom conversion.
- apps/live_frames/test/live_frames/ir_test.exs: test v4 validation and
  serialized shape.
- apps/live_frames/test/live_frames/fidelity_document_loader_test.exs:
  test v3 migration, migration chains, and strict v4 decoding.
- apps/live_frames/test/live_frames/ir_identity_test.exs: test identity
  changes caused by v4 modifier serialization.
- apps/live_frames/lib/live_frames/adapters/bricks/frontend_binding_normalizer.ex:
  mechanically construct the new variants while retaining current source
  classification and parsing behavior.
- apps/live_frames/test/live_frames/bricks_frontend_binding_test.exs: update
  assertions to inspect nested modifier variants without changing expected
  classification.
- apps/live_frames/test/live_frames/component_contract_reference_validation_test.exs,
  apps/live_frames/test/live_frames/component_review_test.exs,
  apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs,
  apps/live_frames/test/live_frames/componentization_plan_test.exs,
  apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs,
  apps/live_frames/test/live_frames/componentization_proposer_test.exs,
  apps/live_frames/test/live_frames/native_generator_test.exs, and
  apps/live_frames/test/live_frames/native_generator_v6_proofs_test.exs:
  mechanically migrate current `%ValueBinding{}` constructors to the nested
  modifier representation.
- apps/live_frames/lib/live_frames/componentization_proposer/construction.ex,
  apps/live_frames/lib/live_frames/component_contract/reference_validation.ex,
  apps/live_frames/lib/live_frames/componentization_plan/reference_validation.ex,
  and apps/live_frames/lib/live_frames/native_generator/renderer.ex: inspect
  struct patterns and consumers; change only actual old-field reads required
  by the new type.
- apps/live_frames/lib/live_frames/behavior/design_document_identity.ex:
  create the shared Behavior-owned policy for exact Identity shape and the
  closed supported Design IR versions, canonicalization ID, digest algorithm,
  and lowercase digest syntax. Do not move this Behavior-specific version
  policy into `LiveFrames.IR.Identity`.
- apps/live_frames/lib/live_frames/behavior/serializer.ex and
  apps/live_frames/lib/live_frames/behavior/review_result.ex: delegate
  standalone DesignDocumentIdentity compatibility validation to the shared
  policy. Change no serialized fields, canonical bytes, digest or review-ID
  algorithms, or exact identity comparisons.
- apps/live_frames/test/live_frames/behavior/serializer_test.exs,
  apps/live_frames/test/live_frames/behavior/review_result_test.exs, and
  apps/live_frames/test/live_frames/behavior/validation_test.exs, and
  apps/live_frames/test/live_frames/behavior/binding_identity_test.exs: prove
  the C-09B2A compatibility and exact-document requirements and retain the
  frozen IR3 binding-ID proof.
- apps/live_frames/test/live_frames/fidelity_document_loader_test.exs: retain
  raw legacy maps with `modifier_status` as migration inputs; update current
  v4 loaded-shape assertions only.

### Constructor and field-reference inventory

The implementation starts by running:

    rg -n 'modifier_status|%ValueBinding\{' apps/live_frames

Classify every match before editing:

| Match class | Files | Treatment |
| --- | --- | --- |
| Current IR definition, serializer, loader, validator | `ir/value_binding.ex`, `ir/serializer.ex`, `fidelity/document_loader.ex`, `ir/validation.ex` | Replace the v3 in-memory field and implement v4 encoding, decoding, validation, and explicit legacy migration handling. |
| Current production source constructors | `adapters/bricks/frontend_binding_normalizer.ex` | Map existing `:none` and `:opaque` outcomes to `None` and `Opaque`. Keep `{post_content:16}` opaque with `evidence_insufficient`; do not parse or resolve it. |
| Current test constructors and assertions | `bricks_frontend_binding_test.exs`, `component_contract_reference_validation_test.exs`, `component_review_test.exs`, `componentization_plan_reference_validation_test.exs`, `componentization_plan_test.exs`, `componentization_proposer_semantic_input_test.exs`, `componentization_proposer_test.exs`, `ir_test.exs`, `native_generator_test.exs`, `native_generator_v6_proofs_test.exs` | Mechanically construct or assert v4 modifier variants. Preserve each test's existing source-semantic expectation. |
| Legacy raw serialized loader inputs | `fidelity_document_loader_test.exs` | Keep old `modifier_status` spelling in raw legacy maps where the test exercises migration or legacy decoding. Make the map version and expected route explicit; update current-v4 output assertions only. |
| Consumers and struct patterns, not old-field constructors | `componentization_proposer/construction.ex`, `component_contract/reference_validation.ex`, `componentization_plan/reference_validation.ex`, `native_generator/renderer.ex` | Inspect for actual old-field reads. No change is expected for patterns that use other fields only. |
| Historical contracts and migration fixtures | C-09B and versioned documentation/fixtures outside current constructors | Keep historical spelling and meaning. Do not bulk-rewrite matches outside the current v4 representation. |

The inventory includes the remaining current `%ValueBinding{}` constructor in
`apps/live_frames/test/live_frames/componentization_plan_test.exs`; update it
mechanically with the other current test constructors. Do not rewrite raw v3
serialized fixtures or versioned historical documents.

If the inventory finds another serialized contract that depends on
`modifier_status`, stop and report it before implementation.

## Task interfaces and outputs

| Task | Input | Output for the next task |
| --- | --- | --- |
| 1. Contract tests | C-09B2 and current IR helpers | Failing tests for exact v4 modifier and migration behavior |
| 2. Internal model | Task 1 cases and C-09B2 | Closed `ValueModifier` variants and `ValueBinding.modifier` type |
| 3. Serialization, loading, validation | Task 2 model | Deterministic v4 round trip and exact-shape validation |
| 3A. Behavior identity compatibility | C-09B2A plus current Behavior serializer/review/validation | Shared Behavior-side policy and proofs preserving historical artifacts and exact-document binding |
| 4. Migration and version dispatch | Task 3 reader, writer, and validator | Explicit v1→2→3→4, v2→3→4, and v3→4 routes with provenance |
| 5. Canonical spec and identity proof | Tasks 3A and 4 current-version path | Canonical v4 spec and corrected identity tests |
| 6. Integrated verification | Tasks 1–5 and constructor inventory | One green, reviewable IR 4 core transition |

## Atomic integration boundary

Develop tasks in sequence and write tests red-first. Do not promote
`current_ir_version` to `4.0.0` or commit a production transition while the
repository has a mixed v3/v4 in-memory contract. Keep intermediate work in the
same uncommitted implementation change. The production transition is coherent
only when `ValueModifier`, `ValueBinding`, serializer, loader, validator,
migration, all current constructor compatibility updates, and
`docs/03_DESIGN_IR_SPEC.md` form one compilable v4 contract. The Behavior
identity compatibility policy and its exact-document tests must also be
complete before promoting `current_ir_version` to `4.0.0`. Include the full
IR transition and compatibility changes in one implementation commit.

### Behavior identity compatibility boundary (C-09B2A)

Before promoting the current IR version, implement only the compatibility
validation authorized by C-09B2A. BehaviorContract 1.0.0 and
BehaviorReviewResult 1.0.0 accept exactly Design IR identity versions 3.0.0
and 4.0.0. Versions 1.0.0, 2.0.0, malformed versions, and unknown future
versions fail closed. Do not compare an artifact identity to
`DesignDocument.current_ir_version/0`, and do not accept arbitrary
non-empty versions.

Prefer the shared `LiveFrames.Behavior.DesignDocumentIdentity` policy module
in `apps/live_frames/lib/live_frames/behavior/design_document_identity.ex`.
It centralizes exact Identity struct shape, supported IR versions,
canonicalization ID, digest algorithm, and lowercase 64-hex digest syntax.
`Behavior.Serializer` and `Behavior.ReviewResult` delegate standalone
identity validation to it. Keep the version policy in the Behavior domain;
`LiveFrames.IR.Identity` remains the generic DesignDocument identity
mechanism.

The authorized compatibility-only files are:

- `apps/live_frames/lib/live_frames/behavior/design_document_identity.ex`
- `apps/live_frames/lib/live_frames/behavior/serializer.ex`
- `apps/live_frames/lib/live_frames/behavior/review_result.ex`
- `apps/live_frames/test/live_frames/behavior/serializer_test.exs`
- `apps/live_frames/test/live_frames/behavior/review_result_test.exs`
- `apps/live_frames/test/live_frames/behavior/validation_test.exs`

Tests retain exact frozen IR3 serializer bytes/digest and review bytes/ID;
accept valid IR4 identities; reject IR1, IR2, unknown future versions,
malformed canonicalization, and malformed digests; and preserve exact
identity, contract digest, and algorithm matching. After the IR4 migration,
structural validation computes the supplied current IR4 DesignDocument's
exact identity and compares the full tuple. Prove that exact IR4 pair passes
and cross-document or cross-version attachment fails. Standalone historical
IR3 Behavior artifacts remain structurally valid, but revalidation of a raw
IR3 DesignDocument through the current in-memory API is not supported. Keep
frozen IR3 binding-ID proofs; an IR4 identity changes the B2 payload and
therefore receives a different binding ID.

This work changes neither Behavior format, serialized field set, serializer
or review-ID algorithm, nor historical fixture. Do not reissue Milan
Behavior artifacts, re-normalize Milan, start P7-D1, or begin runtime work.
The compatibility path is compile/review-time only and adds no database,
cache, process, PubSub, job, or network infrastructure.

## Task 1: Add failing tests for the v4 modifier union

**Interface:** C-09B2 and current IR builders are inputs. The task outputs
focused tests that define valid v4 modifier records, malformed records, and
the expected serialized shape for Tasks 2–4.

**Files:**
- Modify: apps/live_frames/test/live_frames/ir_test.exs
- Modify: apps/live_frames/test/live_frames/fidelity_document_loader_test.exs

- [ ] Add a valid resolved binding with content.body, text target, field
  value, collection-item scope, and word_limit count 16.
- [ ] Add valid none bindings with both normalized and evidence_insufficient
  statuses.
- [ ] Add a valid opaque binding with evidence_insufficient status.
- [ ] Add rejection cases for resolved plus evidence_insufficient, opaque
  plus normalized, non-text targets, non-field values, collection scope, and
  collection_count values.
- [ ] Add rejection cases for unknown kinds, extra modifier keys, extra
  argument keys, absent count, non-integer counts, zero, and negative counts.
- [ ] Assert that a v4 ValueBinding serializes a required nested modifier and
  never emits top-level modifier_status.
- [ ] Assert that the loader rejects a missing modifier and unknown
  status/kind strings without creating atoms.

Run:

    mix test apps/live_frames/test/live_frames/ir_test.exs apps/live_frames/test/live_frames/fidelity_document_loader_test.exs

Expected: the new assertions fail because the current IR supports only the
v3 sibling `modifier_status` field. Keep the red tests uncommitted while
implementing the integrated contract; do not hand off or commit a mixed
in-memory v3/v4 state.

## Task 2: Implement the closed internal ValueModifier variants

**Interface:** Task 1's cases and C-09B2 are inputs. The task outputs the
closed internal modifier type and the required `ValueBinding.modifier` field
for serialization and validation work in Task 3.

**Files:**
- Create: apps/live_frames/lib/live_frames/ir/value_modifier.ex
- Modify: apps/live_frames/lib/live_frames/ir/value_binding.ex

- [ ] Define the internal union as distinct None, Opaque, and Resolved
  variants under LiveFrames.IR.ValueModifier.
- [ ] Use this internal shape or an equivalent closed representation:

      defmodule LiveFrames.IR.ValueModifier do
        defmodule None do
          defstruct []
          @type t :: %__MODULE__{}
        end

        defmodule Opaque do
          defstruct []
          @type t :: %__MODULE__{}
        end

        defmodule Resolved do
          @enforce_keys [:kind, :arguments]
          defstruct [:kind, :arguments]
          @type t :: %__MODULE__{kind: :word_limit, arguments: map()}
        end

        @type t :: None.t() | Opaque.t() | Resolved.t()
      end

- [ ] Give Resolved only kind and arguments payload fields. Do not add an
  arbitrary expression field or executable callback.
- [ ] Define Resolved.kind as the closed atom :word_limit. Represent argument
  key "count" as a positive integer without atomizing input keys.
- [ ] Replace ValueBinding.modifier_status with required
  ValueBinding.modifier and update its type.
- [ ] Keep normalization_status independent so a None modifier can preserve
  evidence_insufficient.
- [ ] Keep LiveFrames transformation execution out of the value model.

The repository will not compile as a v4 contract until the serializer,
loader, validator, migration, adapter construction, and all current test
constructors are updated. Keep those changes in the same uncommitted
implementation work. Do not create an intermediate commit that promotes the
struct while leaving current constructors on the old field.

## Task 3: Encode, decode, and validate exact v4 modifier objects

**Interface:** Task 2's closed model is the input. The task outputs matching
v4 serialization, strict decoding, and validation behavior for the migration
route in Task 4.

**Files:**
- Modify: apps/live_frames/lib/live_frames/ir/serializer.ex
- Modify: apps/live_frames/lib/live_frames/fidelity/document_loader.ex
- Modify: apps/live_frames/lib/live_frames/ir/validation.ex
- Modify: apps/live_frames/test/live_frames/ir_test.exs
- Modify: apps/live_frames/test/live_frames/fidelity_document_loader_test.exs

- [ ] Serialize None as %{"status" => "none"} and Opaque as
  %{"status" => "opaque"}.
- [ ] Serialize Resolved as %{"status" => "resolved", "kind" =>
  "word_limit", "arguments" => %{"count" => count}}.
- [ ] Decode only those exact object key sets. Map known strings through
  fixed clauses and map every unknown value to the existing invalid sentinel.
- [ ] Reject the legacy top-level modifier_status field in current v4 records.
- [ ] Validate exact argument keys, positive integer count, text/field target,
  site or collection-item scope, and the modifier/normalization matrix.
- [ ] Preserve None with evidence_insufficient; do not add a
  None-implies-normalized invariant.
- [ ] Confirm JSON round trips preserve the exact nested shape and canonical
  byte ordering.

Run:

    mix test apps/live_frames/test/live_frames/ir_test.exs apps/live_frames/test/live_frames/fidelity_document_loader_test.exs

Expected: direct serialization, modifier-object decoder tests, and the
coherent v4 contract pass once Tasks 4 and 5 complete. Do not make a partial
version promotion to obtain an intermediate green run.

## Task 3A: Decouple Behavior artifact identity compatibility from the current IR writer

**Interface:** C-09B2A defines the closed Behavior compatibility set and
historical-artifact boundary. This task removes the standalone Behavior
identity checks' dependency on `DesignDocument.current_ir_version/0` without
changing either Behavior artifact format or the generic IR identity API.

Use TDD. Add the compatibility and identity-binding tests first and confirm
the standalone IR4 identity cases fail under the current-version check.
Preserve the frozen IR3 golden fixtures exactly. The current-IR4 document
pair assertion must remain in the focused test set and pass at the coherent
Task 4 version-promotion boundary. Do not commit an intermediate mixed IR3/
IR4 production state.

**Files:**

- Create: `apps/live_frames/lib/live_frames/behavior/design_document_identity.ex`
- Modify: `apps/live_frames/lib/live_frames/behavior/serializer.ex`
- Modify: `apps/live_frames/lib/live_frames/behavior/review_result.ex`
- Modify: `apps/live_frames/test/live_frames/behavior/serializer_test.exs`
- Modify: `apps/live_frames/test/live_frames/behavior/review_result_test.exs`
- Modify: `apps/live_frames/test/live_frames/behavior/validation_test.exs`
- Modify: `apps/live_frames/test/live_frames/behavior/binding_identity_test.exs`

**Red tests first:**

- Keep the frozen IR3 BehaviorContract canonical bytes and digest exact.
- Keep the frozen IR3 BehaviorReviewResult canonical bytes and review ID
  exact.
- Accept a structurally valid standalone IR4 DesignDocumentIdentity.
- Reject IR1, IR2, unknown future versions, malformed identity fields,
  unsupported canonicalization IDs, unsupported digest algorithms, and
  malformed digest syntax.
- Prove an exact current IR4 DesignDocument and BehaviorContract pair passes
  `Behavior.Validation.validate_structure/2` after Task 4 promotes the
  current IR contract. Prove cross-document and IR3-to-IR4 attachment rejects.
- Retain the frozen IR3 B2 binding-ID proof unchanged. Prove a binding ID
  changes when its exact DesignDocumentIdentity changes to IR4; do not reuse
  the IR3 ID.

**Implementation:**

- Add one Behavior-owned identity policy that checks the exact `Identity`
  struct field set and supports only IR versions `3.0.0` and `4.0.0`, the
  existing canonicalization ID, the existing digest algorithm, and lowercase
  64-hex digest syntax.
- Make `Behavior.Serializer` and `Behavior.ReviewResult` delegate standalone
  identity validation to that policy while retaining their existing
  diagnostics.
- Keep the Behavior-specific version policy out of
  `LiveFrames.IR.Identity`. Do not add historical raw-IR3 DesignDocument
  validation, a legacy serializer, or a second identity path.
- Change no serialized fields, sorting, canonicalization, Behavior digest
  algorithm, review-ID algorithm, or frozen fixture bytes.

Run after the Task 4 current-IR4 boundary is assembled, before committing the
coherent production change:

```bash
mix test \
  apps/live_frames/test/live_frames/behavior/serializer_test.exs \
  apps/live_frames/test/live_frames/behavior/review_result_test.exs \
  apps/live_frames/test/live_frames/behavior/validation_test.exs \
  apps/live_frames/test/live_frames/behavior/binding_identity_test.exs
```

Expected: all Behavior compatibility and exact-document tests pass while the
historical IR3 canonical bytes, digests, review ID, and binding-ID proof stay
exact. Standalone IR3 artifacts remain structurally valid; the current
in-memory IR4 document API does not revalidate raw historical IR3 documents.

## Task 4: Add the named 3.0.0 to 4.0.0 structural migration

**Interface:** Task 3's v4 reader, writer, and validator are inputs. The task
outputs a named structural migration and complete version dispatch for Task 5
to document and test.

**Files:**
- Modify: apps/live_frames/lib/live_frames/ir/migration.ex
- Modify: apps/live_frames/lib/live_frames/ir/design_document.ex
- Modify: apps/live_frames/test/live_frames/fidelity_document_loader_test.exs

- [ ] Add the 3.0.0 and 4.0.0 version constants and a migration provenance
  record with kind=structural and frontend_semantics_recovered=false.
- [ ] Map each v3 binding's modifier_status=none or opaque to its exact
  nested status object, delete the old field, and preserve every other
  binding field, including normalization_status and source_trace.
- [ ] Reject malformed v3 value-binding registries, unknown v3 modifier
  statuses, and conflicting migration provenance. Do not fill defaults or
  overwrite data.
- [ ] Route v1 documents through v2, v3, then v4; route v2 through v3 then
  v4; route v3 through v4; accept v4 unchanged; reject unknown versions.
- [ ] Promote DesignDocument.current_ir_version/0 to "4.0.0" only after the
  v4 serializer, loader, validator, and migration route are present and the
  Task 3A identity policy plus standalone Behavior compatibility tests pass.
  Make the promotion in the same uncommitted transition that makes the exact
  current-IR4 Behavior/document test pass, then run Task 3A's full focused
  command before the coherent production commit.
- [ ] Add migration tests for both modifier statuses, both valid none
  normalization states, opaque evidence status, provenance order, malformed
  records, and old opaque {post_content:16} remaining opaque.
- [ ] Assert migration never adds a resolved kind or count argument from
  source trace content.

Run:

    mix test apps/live_frames/test/live_frames/fidelity_document_loader_test.exs

Expected: all legacy routes reach v4 with old modifier knowledge preserved
and no resolved semantics inferred.

## Task 5: Update the canonical v4 spec and verify identity changes

**Interface:** Task 4's current-version path is the input. The task outputs
the canonical v4 spec, v4 identity proofs, and migration identity coverage
without regenerating any Milan artifact.

**Files:**
- Modify: docs/03_DESIGN_IR_SPEC.md
- Modify: apps/live_frames/test/live_frames/ir_test.exs
- Modify: apps/live_frames/test/live_frames/ir_identity_test.exs

- [ ] Update docs/03_DESIGN_IR_SPEC.md to define the required nested union
  and named migration semantics. Preserve a historical v3 section or
  migration note so old artifacts remain understandable.
- [ ] Update version assertions and canonical v4 fixtures to expect the
  required modifier object.
- [ ] Add an identity assertion using the same otherwise-valid v4 document
  with `modifier` set to `None` in one case and `Resolved(word_limit,
  count=16)` in the other. The canonical identities must differ. These are
  two v4 documents; do not call them semantically equivalent to a v3
  document.
- [ ] Optionally pin a historical v3 serialized fixture and digest, migrate
  it through the named v3-to-v4 path, and assert that the migrated v4 identity
  differs from the historical v3 identity. Label this as an artifact-version
  transition, not a semantic equivalence proof. Do not pass an un-migrated v3
  document to the current-version identity API.
- [ ] Confirm v3 accepted documents load only through migration and are
  serialized as v4. Do not mutate their original stored bytes or historical
  review artifacts.

Run:

    mix test apps/live_frames/test/live_frames/ir_test.exs apps/live_frames/test/live_frames/fidelity_document_loader_test.exs apps/live_frames/test/live_frames/ir_identity_test.exs

Expected: version dispatch, migration, serialization, and identity assertions
pass. Milan identities and Behavior artifacts are not regenerated here.

## Task 6: Verify the implemented IR 4 core

**Interface:** Tasks 1–5 and the completed constructor inventory are inputs.
The task outputs a clean, compiling v4 core change with its focused tests and
repository gates recorded.

**Files:**
- Review: all files listed above.

- [ ] Run focused IR, loader, and identity tests.
- [ ] Run repository gates: mix deps.get, mix format --check-formatted,
  mix compile --warnings-as-errors, mix assets.build, mix test,
  mix deps.unlock --check-unused, and git diff --check.
- [ ] Review canonical diffs to confirm there is no top-level
  modifier_status, arbitrary modifier DSL, source-runtime dependency, or
  runtime word truncation.
- [ ] Confirm migration is deterministic, side-effect-free, and O(document
  size).
- [ ] Stop before changing Bricks mapping, regenerating Milan identities, or
  beginning componentization. Those require separate authorized slices.

## Follow-on gates outside this plan

After the IR 4 core is accepted, a separate source-mapping authority and
implementation task may update the Bricks adapter to emit
resolved/word_limit/count for admitted numeric text filters. That task must
retain source spelling and provenance, must not execute source runtime code,
and must freshly normalize Milan before any identity is regenerated.
Behavior-dependent identities and approvals must then be recomputed or
reissued against the exact v4 document. Componentization remains blocked
until those approvals are accepted.
