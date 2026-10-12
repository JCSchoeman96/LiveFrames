# C-09B2A: Behavior identity version compatibility authority

## 1. Status and scope

This authority resolves the compatibility boundary between immutable
BehaviorContract 1.0.0 / BehaviorReviewResult 1.0.0 artifacts and the current
Design IR writer version. It is a narrow amendment required before the
Design IR 4.0.0 ValueModifier implementation resumes. It does not authorize
that implementation by itself.

The authority applies to the `DesignDocumentIdentity` embedded in
BehaviorContract 1.0.0 and BehaviorReviewResult 1.0.0. It supplements
`docs/09_INTERACTION_MODEL.md`, the accepted P7 implementation plan, and
C-09B2. It does not alter Design IR identity generation or the generic
`LiveFrames.IR.Identity` mechanism.

## 2. Frozen artifact decisions

The following remain unchanged:

- BehaviorContract format version is `1.0.0`.
- BehaviorReviewResult format version is `1.0.0`.
- Neither serialized field set changes.
- Neither canonicalization algorithm changes.
- Existing frozen IR3 BehaviorContract canonical bytes and digest remain
  byte-identical.
- Existing frozen IR3 BehaviorReviewResult canonical bytes and derived ID
  remain byte-identical.
- Historical artifacts are not rewritten or reissued solely because the
  current Design IR writer moves to `4.0.0`.

This compatibility rule changes only which Design IR versions a standalone
Behavior artifact may name. It does not change the contents or identity of
any Behavior artifact.

## 3. Closed supported Design IR versions

For BehaviorContract 1.0.0 and BehaviorReviewResult 1.0.0, a structurally
valid `DesignDocumentIdentity.ir_version` is exactly one of:

```text
3.0.0
4.0.0
```

Versions `1.0.0`, `2.0.0`, malformed version strings, and unknown future
versions are rejected. This is a closed compatibility set. It must not be
implemented as acceptance of any non-empty version, nor by comparing the
identity version to `DesignDocument.current_ir_version/0`. Adding a future
Design IR version requires explicit compatibility authority.

The Behavior-side identity policy also requires the exact `Identity` struct
field set (`ir_version`, `canonicalization_id`, `digest_algorithm`, and
`digest`), the supported canonicalization ID
`lf-ir-serializer-v1`, the supported digest algorithm `sha-256`, and a
lowercase 64-character hexadecimal digest. Unknown canonicalization or
digest algorithms and malformed identity records fail closed.

## 4. Exact-document binding remains mandatory

Standalone artifact validity and structural document binding are separate
checks. `Behavior.Validation.validate_structure/2` continues to validate the
supplied DesignDocument, compute its exact identity through
`LiveFrames.IR.Identity`, and require full equality with the identity stored
in the BehaviorContract. Historical version support must not weaken this
comparison or introduce resemblance matching, fallback hashing, or a second
identity algorithm.

The valid pairings are:

| BehaviorContract identity | Supplied DesignDocument | Result |
| --- | --- | --- |
| Exact IR 3.0.0 identity | Its exact IR 3.0.0 document | Valid historical pair |
| Exact IR 4.0.0 identity | Its exact IR 4.0.0 document | Valid current pair |
| IR 3.0.0 identity | IR 4.0.0 document | Reject identity mismatch |
| IR 4.0.0 identity | IR 3.0.0 document | Reject identity mismatch |

BehaviorReviewResult continues to require exact equality with its
BehaviorContract's DesignDocumentIdentity, Behavior serializer algorithm,
and recomputed BehaviorContract digest. Standalone compatibility never
permits attaching a review or contract to a different document.

## 5. Implementation direction for the IR4 plan

Prefer one shared Behavior-owned policy module, equivalent to:

```text
LiveFrames.Behavior.DesignDocumentIdentity
```

at `apps/live_frames/lib/live_frames/behavior/design_document_identity.ex`.
It centralizes the exact Identity field shape, the closed supported IR set
`3.0.0` and `4.0.0`, supported canonicalization ID, supported digest
algorithm, and lowercase 64-hex digest syntax. `Behavior.Serializer` and
`Behavior.ReviewResult` delegate identity validation to it.

Do not move this Behavior-specific version policy into
`LiveFrames.IR.Identity`. That module remains the generic DesignDocument
identity mechanism and continues to derive identity from the supplied valid
DesignDocument.

Only compatibility validation is authorized. The implementation must not
change Behavior artifact mappings, field sets, canonicalization, sorting,
digest calculation, review ID calculation, diagnostics beyond those needed
to reject unsupported identities, or structural identity matching.

## 6. Required compatibility proofs

Behavior serializer tests must prove:

- frozen IR3 canonical bytes and digest are unchanged exactly;
- a valid IR4 DesignDocumentIdentity is accepted;
- IR2 and an unknown future version are rejected; and
- malformed canonicalization IDs and digest values remain rejected.

Behavior review-result tests must prove:

- frozen IR3 canonical bytes and review ID are unchanged exactly;
- an IR4 identity is accepted;
- IR2 and unknown versions are rejected; and
- exact contract identity, digest algorithm, and digest matching remain
  required.

Behavior structural validation tests must prove that the exact current IR4
contract/document pair succeeds after IR4, and historical compatibility
does not permit cross-document or cross-version attachment. Binding
identity tests retain the frozen IR3 binding-ID proofs. An exact IR4
DesignDocument identity naturally changes the binding ID because the
identity tuple participates in the B2 payload; old IDs must not be reused
for IR4.

## 7. Explicit exclusions and stop conditions

This authority is not a BehaviorContract format change, a
BehaviorReviewResult format change, a serializer algorithm change, a
historical fixture rewrite, Milan behavior reissuance, Milan
re-normalization, or P7-D1/runtime work. It authorizes no source-specific
resolved-word-limit mapping, SemanticInput, real Milan D0, proposer
execution, or componentization work.

Compatibility work is compile/review-time only. It adds no database,
Redis, Cachex, ETS, GenServer, PubSub, Oban, or network behavior.

Stop if any condition below is required:

```text
STOP=MAIN_MOVED
STOP=BEHAVIOR_SERIALIZED_SHAPE_CHANGE_REQUIRED
STOP=BEHAVIOR_ALGORITHM_CHANGE_REQUIRED
STOP=HISTORICAL_BYTES_OR_IDS_WOULD_CHANGE
STOP=IR1_OR_IR2_BEHAVIOR_SUPPORT_REQUIRED
STOP=UNKNOWN_FUTURE_IR_VERSION_WOULD_BE_ACCEPTED
STOP=EXACT_DOCUMENT_MATCH_WOULD_BE_WEAKENED
STOP=MILAN_REISSUE_STARTED
STOP=PRODUCTION_CODE_CHANGED
```
