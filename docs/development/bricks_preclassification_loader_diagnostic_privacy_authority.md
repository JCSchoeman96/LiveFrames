STATUS=ACCEPTED
IMPLEMENTATION_AUTHORIZED=NO
TEST_IMPLEMENTATION_AUTHORIZED=NO
TASK_1_AUTHORIZED=NO
COMPONENTIZATION_AUTHORIZED=NO
CANONICAL_INGESTION_PUBLICATION_AUTHORIZED=NO
AUTHORITY_ACCEPTANCE_AUTHORIZED=YES

# Bricks pre-classification Loader diagnostic privacy authority

**Date:** 2026-10-23
**Scope:** Proposed structural diagnostic hygiene for malformed Bricks settings

This document records the accepted structural diagnostic hygiene authority.
Publication of this authority is authorized. Acceptance authorizes no
production or test changes. The accepted execution-security authority and
executable-source specification remain unchanged.

## Acceptance evidence

```text
ACCEPTED_PUBLICATION_PR=301
ACCEPTED_PUBLICATION_HEAD=0476d1e54e41df1cdc9f90903c16c547031ab71d
ACCEPTED_PUBLICATION_TREE=b8bfa12d8037ba74bb3c01d189388232265b2d42

PUBLICATION_MERGE_SHA=92b5155da3657b3d86b1692340c89d77d9de5802
PUBLICATION_MERGE_TREE=55b5db64f63aaea3631342ce7c32dbe2a6b87b44
PUBLICATION_MERGE_SIGNATURE=VERIFIED

POST_MERGE_CI_RUN=39906486336
POST_MERGE_CI_RESULT=success
```

## Evidence

Task 0 used only a synthetic malformed Bricks source. Its baseline suites passed
before the characterization tests were added.

```text
TASK0_BASE_SHA=ccd31b77d4eb0debe212d75963660339242f9986
TASK0_BASE_TREE=999bf7a5282a310f219304eca6e0e5583c055b8b
TASK0_BASE_CI_RUN=39832172176
TASK0_BASE_CI_RESULT=success

TASK0_STAGE_A_BASELINE=26 tests, 0 failures
TASK0_DESIGN_IR_BASELINE=72 tests, 0 failures

PRE_SANITIZATION_LOADER_ERRORS_SAFE=NO
PRE_SANITIZATION_LOADER_ERROR_PRIVACY_LEAK=CONFIRMED
```

The observed propagation was:

```text
Loader.settings_value/2
  -> Diagnostic.raw_value
  -> Stage A returned diagnostic

Loader.settings_value/2
  -> Diagnostic.raw_value
  -> Design IR diagnostic metadata["raw_value"]
```

The body and signature markers each appeared once in the returned error. Stage A
placed each in `Diagnostic.raw_value`. Design IR placed each in translated
diagnostic metadata under `raw_value`. The tests found no marker in the
diagnostic message or source path.

Task 0 proved only that opaque bytes in a malformed rejected `settings`
composite can escape through public diagnostics. The malformed value did not
provide a typed execution context.

## Classification boundary

```text
MALFORMED_SETTINGS_VALUE
!=
CLASSIFIED_EXECUTABLE_SOURCE_BODY

MALFORMED_SETTINGS_VALUE
!=
CLASSIFIED_BRICKS_EXECUTION_AUTHENTICATOR
```

Task 0 did not prove any of the following:

```text
CODE_EXECUTION_SIGNATURE
QUERY_EDITOR_SIGNATURE
PHP_SEMANTICS
EXECUTION_AUTHENTICATOR_VALIDITY
```

This proposal does not broaden either existing execution-security classifier.
Loader must not scan a malformed value to infer executable semantics or
signature ownership.

## Proposed decision

When `Loader.settings_value/2` rejects the entire `settings` field because
the value is not an accepted settings object shape:

```text
DIAGNOSTIC_CODE=bricks.setting.invalid
REJECTED_COMPOSITE_RAW_VALUE_PUBLICLY_RETAINED=NO
```

The public diagnostic may retain its existing stable code, severity and
category, message, source path, source ID where otherwise applicable, and safe
structural metadata.

The diagnostic must not retain:

- the rejected settings value;
- a serialization of that value;
- a hash or fingerprint of that value;
- a prefix, suffix, or sample of that value;
- a presence boolean derived from sensitive-looking content.

This omission is structural diagnostic hygiene. It is not secret detection or
execution classification.

## Exact scope

This rule applies only when `Loader.settings_value/2` reaches its error branch
because the whole `settings` field has an invalid object shape. It does not
change unrelated Loader diagnostics.

```text
GLOBAL_DIAGNOSTIC_RAW_VALUE_REMOVAL=NO
GENERIC_LOADER_REDACTION=NO
GENERIC_SECRET_DETECTION=NO
GLOBAL_SIGNATURE_SCANNING=NO
PHP_SCANNING=NO
ARBITRARY_SOURCE_CONTENT_CLASSIFICATION=NO
```

Existing harmless scalar `raw_value` behavior for unrelated diagnostics
remains governed by its existing semantics.

### Empty-list compatibility

The current Loader treats `settings=[]` as an empty settings map. That accepted
compatibility behavior is outside this malformed-settings error case and must
remain unchanged. This proposal applies only when `settings_value/2` returns
an error.

## Public API coverage

The rule applies to each public surface that propagates this Loader error,
including:

- Stage A returned errors;
- Design IR returned errors;
- translated Design IR diagnostic metadata;
- future ordinary APIs that consume the same Loader diagnostic.

No downstream API may restore the omitted rejected settings value.

## Private-source preservation

This diagnostic rule does not rewrite the input:

```text
PRIVATE_SOURCE_INPUT_MUTATED=NO
SOURCE_HASH_POLICY_CHANGED=NO
SOURCE_IDENTITY_POLICY_CHANGED=NO
```

The caller or private ingestion boundary retains the malformed input according
to existing source ownership rules. The public diagnostic does not echo the
rejected composite. No source identity is calculated from a sanitized value.

## Relationship to existing authorities

This proposal supplements, and does not modify, these documents:

- [Executable-source semantic translation design](../superpowers/specs/2026-10-22-executable-source-semantic-translation-design.md)
- [Bricks execution-security metadata retention authority](bricks_execution_security_metadata_retention_authority.md)

The executable-source specification says public diagnostics must not contain
raw executable source. The execution-security authority requires the same
privacy policy on success and blocking or error paths. Neither document defines
the structural-error case where Loader rejects `settings` before it has enough
structure to classify the contents. This proposal covers that
pre-classification gap without changing the admitted Code and Query Editor
signature families.

## Lifecycle

```text
RAW_SOURCE
  ->
LOADER_SHAPE_VALIDATION
```

The valid path continues through the existing private-source lifecycle:

```text
LOADER_SHAPE_VALIDATION
  -> VALID_SETTINGS_OBJECT
  -> PRIVATE_STRUCTURED_SOURCE
  -> later execution-security classification
```

The invalid path ends before a private structured document exists:

```text
LOADER_SHAPE_VALIDATION
  -> INVALID_SETTINGS_SHAPE
  -> SAFE_STRUCTURAL_ERROR
  -> TERMINAL_FAILURE
```

`SAFE_STRUCTURAL_ERROR` means Loader rejected the whole settings value. Loader
emits its stable structural diagnostic, omits the rejected composite from the
ordinary diagnostic, and does not inspect or classify its contents. No
execution-security sanitizer runs because Loader did not produce a valid
private structured document.

## Invariants

| ID | Proposed invariant |
| --- | --- |
| P1 | Malformed rejected settings values are not echoed in public diagnostics. |
| P2 | Malformed contents are not promoted into an execution-security classification. |
| P3 | No generic secret scanner is introduced. |
| P4 | No global `raw_value` deletion is authorized. |
| P5 | Unrelated Loader diagnostics preserve their existing contracts. |
| P6 | Stage A and Design IR expose the same safe Loader diagnostic semantics. |
| P7 | Source input and source identity are not mutated. |
| P8 | Valid settings continue into the existing private-to-ordinary security lifecycle. |
| P9 | Empty-list settings compatibility remains unchanged. |

## Future TDD acceptance contract

The checks below define future implementation evidence only. They do not
authorize implementation or test changes.

### T0A: Stage A malformed settings

Use synthetic malformed settings containing two distinct markers. Require:

```text
RETURNED_ERROR_BODY_MARKER_HITS=0
RETURNED_ERROR_SIGNATURE_MARKER_HITS=0
DIAGNOSTIC_RAW_VALUE_BODY_HITS=0
DIAGNOSTIC_RAW_VALUE_SIGNATURE_HITS=0
```

### T0B: Design IR malformed settings

Use the same malformed shape through the public Design IR API. Require:

```text
RETURNED_ERROR_BODY_MARKER_HITS=0
RETURNED_ERROR_SIGNATURE_MARKER_HITS=0
DIAGNOSTIC_METADATA_RAW_VALUE_BODY_HITS=0
DIAGNOSTIC_METADATA_RAW_VALUE_SIGNATURE_HITS=0
```

### T0C: Unrelated raw-value regression

Select an existing Loader error whose harmless scalar `raw_value` is
intentionally retained. Prove that behavior remains unchanged. Do not invent a
new Loader behavior for this test.

### T0D: Empty-list compatibility

Prove the existing `settings=[]` compatibility behavior remains unchanged.

### T0E: No content inspection

The implementation must not:

- search malformed settings for `signature`;
- search for PHP markers;
- hash rejected contents;
- classify execution semantics.

## Performance

```text
DATA_LAYER=COLD_BUILD_TIME
TARGET_COMPLEXITY=O(1) additional work on malformed-settings error path

REDIS=NOT_APPLICABLE
ETS=NOT_APPLICABLE
CACHEX=NOT_APPLICABLE
GENSERVER=NOT_APPLICABLE
PUBSUB=NOT_APPLICABLE
OBAN=NOT_APPLICABLE
POSTGRES=NOT_APPLICABLE
NETWORK=NOT_APPLICABLE
```

The future implementation should omit the rejected composite when it creates
the structural diagnostic. It needs no additional inspection, lookup, or
persistent state.

## Explicit exclusions

```text
NO_PRODUCTION_IMPLEMENTATION
NO_TEST_IMPLEMENTATION
NO_SANITIZER_IMPLEMENTATION
NO_GLOBAL_LOADER_PRIVACY_REDESIGN
NO_GENERIC_SECRET_CLASSIFIER
NO_SIGNATURE_CLASSIFIER_EXPANSION
NO_PHP_EXECUTION
NO_WORDPRESS_RUNTIME
NO_TEMPLATE_124_SOURCE
NO_COMPONENTIZATION
NO_CANONICAL_INGESTION_PUBLICATION
```

## Stop conditions

Do not implement under this proposal if any of the following holds:

```text
STOP=MAIN_MOVED_WITH_AUTHORITY_OVERLAP
STOP=TASK0_EVIDENCE_NO_LONGER_REPRODUCIBLE_FROM_RECORDED_REPORT
STOP=AUTHORITY_REQUIRES_GENERIC_SECRET_DETECTION
STOP=AUTHORITY_REQUIRES_GLOBAL_RAW_VALUE_REMOVAL
STOP=AUTHORITY_EXPANDS_SIGNATURE_CLASSIFICATION
STOP=AUTHORITY_CHANGES_SOURCE_IDENTITY
STOP=AUTHORITY_CHANGES_SETTINGS_EMPTY_LIST_COMPATIBILITY
STOP=TASK0_WORKTREE_MODIFIED
STOP=PRODUCTION_OR_TEST_FILE_CHANGE_REQUIRED
```

## Review status

```text
DOCUMENT_STATUS=ACCEPTED
OWNER_ACCEPTANCE_REQUIRED=NO
IMPLEMENTATION_AUTHORIZED=NO
TEST_IMPLEMENTATION_AUTHORIZED=NO
TASK_1_AUTHORIZED=NO
COMPONENTIZATION_AUTHORIZED=NO
CANONICAL_INGESTION_PUBLICATION_AUTHORIZED=NO
```

The owner must review and accept the exact published document before any
Loader, sanitizer, or test implementation begins.
