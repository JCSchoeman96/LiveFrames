# Design IR 4.0.0 ValueModifier Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Add a required, closed ValueModifier tagged union to Design IR 4.0.0 and migrate Design IR 3.0.0 bindings without recovering new source semantics.

**Architecture:** Keep the v3 contract historical and add the v4 model to the existing IR reader, serializer, validator, and migration chain. Serialize one required nested modifier object per ValueBinding; use closed variant structs internally and exact-shape maps at the JSON boundary. The caller owns applying resolved transformations before supplying bound values.

**Tech Stack:** Elixir umbrella app, Jason JSON serialization, Mix ExUnit tests, Markdown authority documents.

---

## Scope and gates

This plan implements the generic Design IR representation and structural
migration only. It does not change the Bricks adapter, re-normalize Feature
Milan, regenerate behavior identities, create SemanticInput, run D0, call the
proposer, or start P7-D1/runtime work. Those activities require separate
source-mapping and exact-document approval gates after IR 4.0.0 is implemented.

Use the accepted base
4b335ac496a0c8536923101dac6770f94d4b994e and its tree
56dfeebca4d0f9f254ab1d19e3e49e4d43800296. Stop if origin/main moves before
implementation begins.

The serialized v4 variants are exactly:

    {"status":"none"}
    {"status":"opaque"}
    {"status":"resolved","kind":"word_limit","arguments":{"count":16}}

none may retain either normalization status allowed by existing evidence
rules. opaque requires evidence_insufficient; resolved requires normalized,
target_kind=text, value_kind=field, and scope=collection_item or site.
Migration preserves old normalization status and never infers resolved
semantics.

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

Do not change
apps/live_frames/lib/live_frames/adapters/bricks/frontend_binding_normalizer.ex
in this implementation slice. A separate source-mapping task will authorize
its generic numeric-text-filter classification and Milan fresh normalization.

## Task 1: Add failing tests for the v4 modifier union

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
v3 sibling modifier_status field.

## Task 2: Implement the closed internal ValueModifier variants

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

Do not run the full IR test module at this intermediate step. Existing tests
still construct the v3 ValueBinding shape until the serializer, loader,
validator, and migration tasks are complete.

## Task 3: Encode, decode, and validate exact v4 modifier objects

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

Expected: direct serialization and modifier-object decoder tests pass.
End-to-end v4 validation and v3 fixture loading complete after Task 4 promotes
the version and adds the migration route.

## Task 4: Add the named 3.0.0 to 4.0.0 structural migration

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
  v4 serializer, loader, validator, and migration route are present.
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

**Files:**
- Modify: docs/03_DESIGN_IR_SPEC.md
- Modify: apps/live_frames/test/live_frames/ir_test.exs
- Modify: apps/live_frames/test/live_frames/ir_identity_test.exs

- [ ] Update docs/03_DESIGN_IR_SPEC.md to define the required nested union
  and named migration semantics. Preserve a historical v3 section or
  migration note so old artifacts remain understandable.
- [ ] Update version assertions and canonical v4 fixtures to expect the
  required modifier object.
- [ ] Add an identity assertion proving a v4 binding with a resolved
  modifier has a different canonical document identity from the equivalent
  v3 binding.
- [ ] Confirm v3 accepted documents load only through migration and are
  serialized as v4. Do not mutate their original stored bytes or historical
  review artifacts.

Run:

    mix test apps/live_frames/test/live_frames/ir_test.exs apps/live_frames/test/live_frames/fidelity_document_loader_test.exs apps/live_frames/test/live_frames/ir_identity_test.exs

Expected: version dispatch, migration, serialization, and identity assertions
pass.

## Task 6: Verify the implemented IR 4 core

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
