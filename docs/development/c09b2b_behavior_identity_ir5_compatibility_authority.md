# C-09B2B: Behavior identity compatibility for Design IR 5.0.0

**Date:** 2026-10-22

## 1. Status and scope

**Status:** Accepted by the owner on 2026-10-22. No implementation is authorized.

This candidate addresses the compatibility boundary between immutable BehaviorContract 1.0.0 / BehaviorReviewResult 1.0.0 artifacts and Design IR 5.0.0. It proposes a narrow addition to the closed DesignDocumentIdentity compatibility set. It does not authorize IR 5.0.0 implementation by itself.

The candidate applies only to the `DesignDocumentIdentity` embedded in BehaviorContract 1.0.0 and BehaviorReviewResult 1.0.0. It supplements `docs/development/c09b2a_behavior_identity_version_compatibility_authority.md`. It does not alter Design IR identity generation or `LiveFrames.IR.Identity`.

Candidate base:

```text
REPOSITORY=JCSchoeman96/LiveFrames
MAIN_SHA=69e4ca84acd14de3e27c41818aa59d1651889044
MAIN_TREE=4a19e3960c292c0b6ec75948c43de04f02788de7
EXECUTABLE_SOURCE_SPEC=docs/superpowers/specs/2026-10-22-executable-source-semantic-translation-design.md
EXECUTABLE_SOURCE_SPEC_COMMIT=69e4ca84acd14de3e27c41818aa59d1651889044
```

## 2. Proposed frozen artifact decisions

The following remain unchanged:

- BehaviorContract format version is `1.0.0`.
- BehaviorReviewResult format version is `1.0.0`.
- Both serialized Behavior field sets remain unchanged.
- Behavior canonicalization algorithms remain unchanged.
- `canonicalization_id` remains `lf-ir-serializer-v1`.
- `digest_algorithm` remains `sha-256`.
- Exact DesignDocument identity matching remains mandatory.
- Frozen historical IR3 and IR4 Behavior canonical bytes, digests, binding IDs, and review IDs remain byte-for-byte/value-for-value unchanged. Before implementation, pin the current-base IR4 outputs as exact test goldens if existing tests do not already do so.
- Historical Behavior artifacts are not rewritten or reissued because the current Design IR writer moves to `5.0.0`.

This proposal changes only the closed set of Design IR versions that a standalone Behavior artifact may name. New IR5 Behavior artifacts naturally carry a different exact DesignDocumentIdentity. Their derived binding IDs, BehaviorContract digests, and review IDs may therefore differ from corresponding IR4 artifacts.

## 3. Proposed closed supported Design IR versions

For BehaviorContract 1.0.0 and BehaviorReviewResult 1.0.0, a structurally valid `DesignDocumentIdentity.ir_version` is exactly one of:

```text
3.0.0
4.0.0
5.0.0
```

Versions `1.0.0`, `2.0.0`, malformed version strings, and unknown future versions remain rejected. This is a closed compatibility set. It must not accept every non-empty version or derive the set from `DesignDocument.current_ir_version/0`.

The Behavior-side identity policy continues to require the exact `Identity` struct field set (`ir_version`, `canonicalization_id`, `digest_algorithm`, and `digest`), canonicalization ID `lf-ir-serializer-v1`, digest algorithm `sha-256`, and a lowercase 64-character hexadecimal digest. Unknown canonicalization IDs, digest algorithms, malformed identities, and unsupported IR versions fail closed.

## 4. Exact-document binding remains mandatory

Standalone artifact validity and structural document binding remain separate checks. `Behavior.Validation.validate_structure/2` validates the supplied current DesignDocument, derives its identity through `LiveFrames.IR.Identity`, and requires full equality with the BehaviorContract identity. The expansion to IR5 does not add resemblance matching, fallback hashing, cross-version attachment, or a second identity algorithm.

The valid and invalid current-document pairings are:

| BehaviorContract identity | Supplied DesignDocument | Result |
| --- | --- | --- |
| Exact IR 5.0.0 identity | Its exact current IR 5.0.0 document | Valid current pair |
| IR 3.0.0 identity | Current IR 5.0.0 document | Reject identity mismatch |
| IR 4.0.0 identity | Current IR 5.0.0 document | Reject identity mismatch |
| IR 5.0.0 identity | A different IR 5.0.0 document | Reject identity mismatch |

Standalone historical BehaviorContract and BehaviorReviewResult artifacts with IR3 or IR4 identities remain structurally valid. Their frozen bytes and derived IDs remain unchanged. A historical IR3 or IR4 BehaviorContract cannot be revalidated against a current IR5 DesignDocument through the current structural validation API because exact identity comparison rejects it.

`BehaviorReviewResult` continues to require exact equality with its BehaviorContract's DesignDocumentIdentity, Behavior serializer algorithm, and recomputed BehaviorContract digest. Standalone compatibility never permits attaching a review or contract to a different document.

## 5. Implementation direction if accepted

Keep Behavior-specific compatibility in `LiveFrames.Behavior.DesignDocumentIdentity` at `apps/live_frames/lib/live_frames/behavior/design_document_identity.ex`. Add only the literal `5.0.0` member to its closed version list. Keep the exact identity fields, canonicalization ID, digest algorithm, and digest syntax unchanged.

`Behavior.Serializer` and `Behavior.ReviewResult` continue to delegate identity validation to this module. Do not move the Behavior-specific version policy into `LiveFrames.IR.Identity`; that module remains the generic DesignDocument identity mechanism and derives identity from a valid supplied DesignDocument.

Do not change Behavior field mappings, serialized field sets, canonicalization, sorting, digest calculation, binding-ID calculation, review-ID calculation, or exact structural identity matching. Do not bump either Behavior format version.

## 6. Required compatibility proofs if accepted

Behavior serializer tests must prove:

- frozen IR3 canonical bytes and digest remain byte-identical;
- the current-base IR4 canonical bytes and digest remain byte-identical and are pinned as exact test goldens;
- valid IR3, IR4, and IR5 identities are accepted;
- IR1, IR2, and unknown future versions are rejected; and
- malformed canonicalization IDs and digest values remain rejected.

Behavior review-result tests must prove:

- frozen IR3 canonical bytes and review ID remain byte-identical;
- the current-base IR4 canonical bytes and review ID remain byte-identical and are pinned as exact test goldens;
- IR3, IR4, and IR5 identities are accepted;
- IR1, IR2, and unknown versions are rejected; and
- exact contract identity, digest algorithm, and digest matching remain required.

Behavior structural validation tests must prove that the exact current IR5 contract/document pair succeeds, while IR3 and IR4 identities do not attach to a current IR5 document and a different IR5 document is rejected. Binding-identity tests retain the exact IR3 ID, capture the current-base IR4 ID as a golden, and prove that an IR5 identity derives the appropriate distinct ID from the unchanged B2 payload contract.

## 7. Explicit exclusions and stop conditions

This candidate does not authorize a BehaviorContract format change, a BehaviorReviewResult format change, a serializer algorithm change, a historical fixture rewrite, reissuance of an existing Behavior artifact, or runtime work. It authorizes only the closed identity compatibility addition described above if the owner accepts this document.

Stop if any of the following is required:

```text
STOP=BEHAVIOR_SERIALIZED_SHAPE_CHANGE_REQUIRED
STOP=BEHAVIOR_ALGORITHM_CHANGE_REQUIRED
STOP=HISTORICAL_BYTES_OR_IDS_WOULD_CHANGE
STOP=IR1_OR_IR2_BEHAVIOR_SUPPORT_REQUIRED
STOP=UNKNOWN_FUTURE_IR_VERSION_WOULD_BE_ACCEPTED
STOP=EXACT_DOCUMENT_MATCH_WOULD_BE_WEAKENED
STOP=HISTORICAL_DOCUMENT_REVALIDATION_REQUIRED
```

No implementation may begin until this authority candidate is accepted, installed as repository authority, and the implementation plan is approved against its exact committed bytes.
