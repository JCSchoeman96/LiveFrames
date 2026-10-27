# C09C6B Behavior identity compatibility for Design IR 6.0.0

## Status and scope

This candidate supplements C09B2A and C09B2B and addresses the Behavior identity compatibility prerequisite for C09C6. It requires owner acceptance and merge before it becomes authority. It does not authorize implementation. The current Design IR writer remains 5.0.0.

```text
AUTHORITY=C09C6B
C09C6B_AUTHORITY_REQUIRED_BEFORE_IR6_CURRENT_VERSION_PROMOTION=YES
DESIGN_IR6_IMPLEMENTATION_AUTHORIZED=NO
P3A_IMPLEMENTATION_AUTHORIZED=NO
```

Once this authority is merged and accepted, the owner may separately authorize coordinated P3A implementation of Design IR 6 core and the narrow Behavior identity compatibility addition specified here. This document does not authorize P3A itself.

## Closed compatibility set

For standalone BehaviorContract 1.0.0 and BehaviorReviewResult 1.0.0 artifacts, the future supported DesignDocumentIdentity `ir_version` set is exactly:

```text
3.0.0
4.0.0
5.0.0
6.0.0
```

```text
CLOSED_VERSION_SET=YES
IR1_SUPPORTED=NO
IR2_SUPPORTED=NO
UNKNOWN_FUTURE_IR_SUPPORTED=NO
DERIVE_SUPPORTED_SET_FROM_CURRENT_IR_VERSION=NO
```

A future implementation may add only the literal `"6.0.0"` to the existing closed list. It must not accept any non-empty version, use semantic-version ranges or `>=` comparisons, or automatically admit the current version. Further versions require separate authority.

An IR6 identity is valid for a standalone Behavior artifact only with the existing exact identity shape:

```text
ir_version=6.0.0
canonicalization_id=lf-ir-serializer-v1
digest_algorithm=sha-256
digest=<lowercase 64-character hexadecimal sha256>
```

This permits an artifact to name an IR6 document identity. It does not establish equality between IR5 and IR6 identities.

## Frozen artifact and identity decisions

```text
BehaviorContract.format_version=1.0.0
BehaviorReviewResult.format_version=1.0.0
canonicalization_id=lf-ir-serializer-v1
digest_algorithm=sha-256
BEHAVIOR_CONTRACT_SERIALIZED_FIELD_SET=UNCHANGED
BEHAVIOR_REVIEW_SERIALIZED_FIELD_SET=UNCHANGED
BINDING_ID_ALGORITHM=UNCHANGED
BEHAVIOR_CONTRACT_DIGEST_ALGORITHM=UNCHANGED
BEHAVIOR_REVIEW_ID_ALGORITHM=UNCHANGED
EXACT_DOCUMENT_IDENTITY_MATCH=REQUIRED
EXACT_IDENTITY_EQUALITY=MANDATORY
```

No new fields, fallback identity, cross-version equivalence, or resemblance matching are authorized. Behavior sees only an exact DesignDocument identity. It does not incorporate the reason for IR6, datetime semantics, source IDs, or source expressions into Behavior code or identity contracts.

```text
IR3_BEHAVIOR_BYTES_IMMUTABLE=YES
IR4_BEHAVIOR_BYTES_IMMUTABLE=YES
IR5_BEHAVIOR_BYTES_IMMUTABLE=YES
IR3_BINDING_IDS_IMMUTABLE=YES
IR4_BINDING_IDS_IMMUTABLE=YES
IR5_BINDING_IDS_IMMUTABLE=YES
IR3_REVIEW_IDS_IMMUTABLE=YES
IR4_REVIEW_IDS_IMMUTABLE=YES
IR5_REVIEW_IDS_IMMUTABLE=YES
```

Historical canonical bytes, digests, and IDs remain unchanged. IR6 does not rewrite or migrate Behavior artifacts. Existing Feature Milan IR5 BehaviorContract and BehaviorReviewResult records remain immutable historical evidence for their exact IR5 document. Do not update historical authority records merely because the current writer later becomes IR6.

C09C6 establishes that fresh or migrated IR6 documents receive newly computed canonical bytes and identity. A new Behavior artifact intentionally created for an IR6 document may therefore derive new binding IDs, a new contract digest, and a new review ID when those values depend on the exact document identity. Do not preserve an IR5 derived identifier by weakening exact identity semantics or require corresponding IR5 and IR6 IDs to match.

## Exact-document attachment

Standalone validity is separate from attachment. Structural validation validates the current DesignDocument, derives its identity, and requires full equality with the BehaviorContract identity. BehaviorReviewResult continues to require exact equality with its contract identity, serializer algorithm, and recomputed contract digest.

| Behavior identity | Supplied document | Result |
| --- | --- | --- |
| Exact IR6 identity | Its exact IR6 document | Valid |
| IR3 identity | Current IR6 document | Reject |
| IR4 identity | Current IR6 document | Reject |
| IR5 identity | Current IR6 document | Reject |
| IR6 identity | Different IR6 document | Reject |
| Malformed IR6 identity | Any document | Reject |

Standalone historical IR3, IR4, and IR5 artifacts may remain structurally valid under their existing compatibility authority. That does not permit attachment to a different current IR6 document.

## Future implementation and proofs

The expected production file is `apps/live_frames/lib/live_frames/behavior/design_document_identity.ex`. The only authorized semantic change is the literal addition shown below:

```elixir
@supported_ir_versions ["3.0.0", "4.0.0", "5.0.0", "6.0.0"]
```

Do not derive the set from `DesignDocument.current_ir_version/0`. Do not change Behavior.Serializer canonicalization, Behavior.ReviewResult canonicalization, the Behavior.BindingIdentity algorithm, Behavior.Validation exact identity comparison, or either Behavior format version.

A future implementation must test:

- Serializer and ReviewResult each accept IR3, IR4, IR5, and IR6 identities, and reject IR1, IR2, unknown future versions, and malformed identities, including invalid canonicalization, digest algorithm, and digest syntax.
- The unchanged binding-ID algorithm includes an IR6 DesignDocument identity and produces deterministic IDs. No equality with IR5 IDs is required.
- Structural validation accepts the exact current IR6 document and exact IR6 contract identity. It rejects IR3, IR4, and IR5 identities against that document and rejects a different IR6 document.
- Existing exact IR3, IR4, and IR5 canonical-byte, digest, binding-ID, and review-ID goldens remain unchanged. Do not regenerate historical goldens to make a failing test pass.

## Lifecycle and terminal states

The following describes the required validation decisions, not a new serialized state machine:

```text
ir6_identity_received
→ exact_identity_shape_valid
→ ir_version_closed_set_checked
→ canonicalization_id_checked
→ digest_algorithm_checked
→ digest_syntax_checked
→ standalone_behavior_identity_valid
```

For structural attachment:

```text
standalone_behavior_identity_valid
→ current_design_document_valid
→ current_document_identity_derived
→ exact_identity_compared
→ behavior_attachment_valid
```

Terminal states are `unsupported_ir_version`, `malformed_identity`, `unsupported_canonicalization`, `unsupported_digest_algorithm`, `malformed_digest`, `exact_document_identity_mismatch`, and `historical_identity_mismatch`. No terminal state may fall back to approximate matching.

## Security and performance

This is bounded metadata validation in cold, local artifact validation. The closed membership lookup remains constant-size.

```text
DYNAMIC_ATOM_CREATION=NO
VERSION_RANGE_PARSING=NO
RUNTIME_SOURCE_EXPRESSION_PARSING=NO
NETWORK_CALLS=0
DB_CALLS=0
DATA_LAYER=COLD/LOCAL_ARTIFACT_VALIDATION
TIME_COMPLEXITY=O(1) VERSION MEMBERSHIP
ETS=N/A
CACHEX=N/A
REDIS=N/A
POSTGRES=N/A
PGBouncer=N/A
PUBSUB=N/A
GENSERVER=N/A
OBAN=N/A
TTL=N/A
DB_INDEX=N/A
```

## Exclusions

This authority does not authorize Design IR 6 implementation, current-version promotion, 5-to-6 migration implementation, datetime attribute implementation, or Bricks datetime normalization. It does not authorize BehaviorContract 2.0.0, BehaviorReviewResult 2.0.0, new Behavior fields, a new identity or binding-ID algorithm, or historical artifact rewrite. It does not authorize P3A, P3B, P4, FLUID11B, or FLUID12 implementation.
