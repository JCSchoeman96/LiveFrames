# C-09B2: Design IR 4.0.0 value modifier authority

## 1. Status and scope

This authority specifies the ValueModifier representation for Design IR
4.0.0. It supplements the historical Design IR 3.0.0 binding authority in
C-09B and applies only to documents whose ir_version is 4.0.0. It does not
change the meaning of serialized Design IR 3.0.0 documents.

The approved change is MAJOR. The target version is 4.0.0. Design IR 3.0.0
remains the current implemented version until a later implementation change
updates the reader, writer, validator, and current version together.

This document freezes a source-neutral representation for a known caller-owned
value transformation. It does not authorize a Bricks runtime dependency,
WordPress access, runtime truncation, or an arbitrary modifier expression
language.

## 2. Design decision

Every serialized Design IR 4.0.0 ValueBinding MUST contain one required
modifier object. The old top-level modifier_status field is removed in
4.0.0. A 4.0.0 record MUST NOT contain both representations.

The serialized modifier is a closed tagged union with exactly these variants:

    {"status":"none"}

    {"status":"opaque"}

    {"status":"resolved","kind":"word_limit","arguments":{"count":16}}

none means the source has no modifier. opaque means a modifier is present,
but its semantics have not been established. resolved means the modifier's
meaning is established and represented by its closed kind and arguments.

The object shape is exact. none and opaque contain only status. resolved
contains only status, kind, and arguments. Unknown fields, unknown statuses,
unknown kinds, or additional argument keys MUST fail validation.
Implementations MUST NOT derive atoms or executable code from serialized
strings.

## 3. Resolved word limit

The only resolved modifier kind authorized by this document is word_limit.
Its arguments object MUST contain exactly one key, count. count MUST be a
positive integer. Missing, zero, negative, fractional, or non-numeric values
are invalid.

A resolved word_limit is valid only when its ValueBinding has:

- target_kind equal to text;
- value_kind equal to field; and
- scope equal to collection_item or site.

It is invalid for collection scope or collection_count values. Future
modifier kinds require separate authority and their own closed argument
schemas. This union is not an expression language and does not allow arbitrary
kind names or argument maps.

## 4. Normalization invariants

normalization_status remains a separate ValueBinding field. The modifier
state imposes these constraints:

| Modifier status | Normalization requirement |
| --- | --- |
| none | Preserve the status allowed by the other ValueBinding evidence rules. It may be normalized or evidence_insufficient. |
| opaque | MUST be evidence_insufficient. |
| resolved | MUST be normalized. |

In particular, none MUST NOT be globally equated with normalized.
Design IR 3.0.0 already permits modifier_status=none together with
normalization_status=evidence_insufficient, and a structural migration must
preserve that valid state.

## 5. Execution ownership

ValueBinding declares the meaning of caller-supplied frontend data. The
caller performs any authorized transformation before supplying the field
value. Execution ownership is global to the ValueBinding authority and is
not repeated on each modifier record.

LiveFrames MUST NOT parse source dynamic-data expressions, query WordPress,
execute Bricks filters, tokenize strings, or truncate values at runtime. A
component consumer receives the already-transformed value through its
ordinary binding assignment.

For Feature Milan, fresh source normalization may produce:

    {
      "value_key": "content.body",
      "modifier": {
        "status": "resolved",
        "kind": "word_limit",
        "arguments": {"count": 16}
      },
      "normalization_status": "normalized"
    }

The caller supplies the post content limited to at most 16 words. This
authority does not claim direct inspection of Bricks 2.3.1 implementation
code. The repository fixture at fixtures/bricks/bricks_components.json has
SHA-256 bb584f35b160f5095dc67fc367884f51cff35b59693c84374426f5cecf56a1a1.
Its envelope version is 2.3.1, its first component version is 2.3.5, and its
text settings include {post_content:60} and {post_excerpt:20}. This proves
that numeric-suffix syntax occurs in the accepted fixture family; it does
not define the suffix unit.

The accepted semantic evidence is current official Bricks documentation at
https://academy.bricksbuilder.io/builder/dynamic-content/dynamic-data/ and
historical community corroboration at
https://forum.bricksbuilder.io/t/how-to-link-an-image-or-container-to-a-single-product-page-in-a-query-loop/12585.
This is cross-version continuity evidence, not direct Bricks 2.3.1
implementation proof. The evidence establishes a maximum word count. It does
not establish HTML stripping, exact tokenization, or suffix/ellipsis behavior.
Source adapters retain the exact source expression and provenance in
SourceTrace.

## 6. Design IR 3.0.0 to 4.0.0 migration

The migration is named 3.0.0 to 4.0.0 and is structural. For every
well-formed 3.0.0 ValueBinding, it MUST:

1. map modifier_status=none to modifier={"status":"none"};
2. map modifier_status=opaque to modifier={"status":"opaque"};
3. remove the old top-level modifier_status field;
4. preserve normalization_status, value_key, target fields, collection
   references, source_trace, and every other represented meaning; and
5. append the migration record to the existing migration provenance list.

The migration MUST reject malformed or unsupported 3.0.0 binding status
values. It MUST NOT infer, resolve, or reinterpret modifiers from
source_trace, raw expressions, source version, or outside evidence. In
particular, an old opaque {post_content:16} binding remains opaque after
migration.

Only fresh source normalization under separately accepted source-mapping
authority may emit a resolved word_limit modifier. Migration does not create
new source knowledge.

Design IR 3.0.0 artifacts remain readable through the explicit migration
path. They are not silently validated as 4.0.0 without migration. A 3.0.0
artifact and approvals tied to it remain historically valid for that exact
artifact.

## 7. Identity and downstream approval impact

The modifier object changes canonical serialized bytes. Re-normalizing a
source document as 4.0.0 therefore requires recomputing its DesignDocument
identity. Every identity derived from that exact document must be recomputed
from the new document; callers MUST NOT assume a dependent identifier or
digest survives.

For Feature Milan, re-normalization requires a new DesignDocument identity.
Behavior-dependent identities, BehaviorContract content/digest, and the
BehaviorReviewResult must be recomputed or reissued when their exact-document
references change. Historical review artifacts remain immutable and
historically accepted for the old DesignDocument. They MUST NOT be mutated
or reused as approval for a new exact document.

The selection primitive, timer semantics, selection semantic authority, and
P7-D0 implementation do not change as part of this value-modifier contract.
Milan componentization remains locked until IR 4.0.0 is implemented and
accepted, Milan has been freshly normalized, and its behavior contract and
review have been reissued against the new exact document.

## 8. Explicit exclusions

This authority does not:

- implement Design IR 4.0.0;
- change the current docs/03_DESIGN_IR_SPEC.md contract before the IR 4.0.0
  implementation is accepted;
- change source-specific Bricks normalization rules;
- re-normalize Feature Milan or regenerate its identities;
- create a Milan ComponentizationSemanticInput;
- execute D0 or call ComponentizationProposer;
- change ComponentContract, ComponentizationPlan, BehaviorContract, or
  BehaviorReviewResult formats; or
- authorize P7-D1 or runtime work.

## 9. Acceptance checks for a later implementation

A Design IR 4.0.0 implementation conforms only if:

- every v4 serialized ValueBinding contains modifier and contains no
  top-level modifier_status;
- the three tagged variants and exact object shapes are validated;
- only word_limit with exactly one positive integer count is accepted as
  resolved;
- opaque and resolved normalization constraints are enforced while none
  preserves valid normalization states;
- migration preserves old represented values and never infers resolved
  semantics;
- v3-to-v4 and v1-to-v4 migration routes preserve migration history;
- round-trip serialization is deterministic and identity tests cover the new
  serialized shape; and
- no LiveFrames runtime code performs modifier execution.
