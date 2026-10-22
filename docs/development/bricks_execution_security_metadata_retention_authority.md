# Bricks execution-security metadata retention authority

**Date:** 2026-10-22
**Status:** Accepted by the owner on 2026-10-22. No implementation is authorized.
**Scope:** Authority and specification only

~~~~text
AUTHORITY_STATUS=ACCEPTED
ACCEPTED_PR=293
ACCEPTED_HEAD=18cf188b368b877972ac41126adc960f6d2bf3a8
ACCEPTED_MERGE_SHA=c6e689353ce4a26263fcbe10bd77c08ba403d115
ACCEPTED_POST_MERGE_CI_RUN=39819732247
ACCEPTED_POST_MERGE_CI_RESULT=success
IMPLEMENTATION_AUTHORIZED=NO
COMPONENTIZATION_AUTHORIZED=NO
TEMPLATE_124_CANONICAL_INGESTION_PUBLICATION_AUTHORIZED=NO

BASE_SHA=9f0d2df1161a715f79c526dae49fbd4c6ca97117
BASE_TREE=4611b8f62861a2c21d129d36f682eaa2600678e2
BASE_CI_RUN=39791454675
BASE_CI_RESULT=success
~~~~

## Decision

Bricks execution signatures are source-platform execution authenticators and
private source-runtime evidence. They are not semantic meaning or runtime input
for LiveFrames. They are not semantic identity, component identity, or
standalone provenance identity.

They may affect whole-source content identity only indirectly as bytes within
the complete original imported source. That whole-source content identity is
allowed, is not a signature fingerprint, and must never be used to validate a
signature, compare or infer signature validity, or recover a signature.

The normalizer must classify recognized execution signatures in the private
source model, then remove them from every ordinary-consumer representation
before that representation reaches dependency extraction, source traces,
diagnostics, provenance, or Design IR. The original imported bytes remain
unchanged and remain the only input to source identity.

This authority sets a generic privacy and retention policy for Bricks
execution-authenticator metadata. Its current closed structural classifier
admits only the two proven families below. Template 124 is private proof
evidence only. Template or product identity must not affect classification.

## Classification

~~~~text
SECURITY_METADATA_CLASS=BRICKS_EXECUTION_AUTHENTICATOR

SOURCE_RUNTIME_ONLY=YES
LIVEFRAMES_SEMANTIC_INPUT=NO
LIVEFRAMES_RUNTIME_INPUT=NO
STYLE_INPUT=NO
BEHAVIOR_INPUT=NO
COMPONENTIZATION_INPUT=NO
GENERATION_INPUT=NO
~~~~

The accepted diagnostic source contained four execution signatures. Three were
on Bricks Code elements at settings.signature. One was on a div at
settings.query.signature. All four values were binary and 32 bytes long. The
three Code elements had executeCode=true and a binary code field. No observed
signature occurred outside an execution context.

~~~~text
SIGNATURE_OCCURRENCE_COUNT=4
SIGNATURE_ELEMENT_KIND_COUNTS=code:3,div:1
SIGNATURE_SETTING_PATHS=settings.signature:3,settings.query.signature:1
SIGNATURE_VALUE_TYPES=binary
SIGNATURE_BYTE_LENGTH_SET=32

SIGNATURE_WITH_EXECUTE_CODE_TRUE=3
SIGNATURE_WITH_CODE_FIELD=3
SIGNATURE_OUTSIDE_EXECUTION_CONTEXT=0

ALL_CANONICAL_SIGNATURES_CLASSIFIED_AS_EXECUTION_SECURITY_METADATA=YES
~~~~

The initial admitted signature value shape is a 32-byte binary. This is a
structural shape check only. LiveFrames must not inspect signature contents or
infer signature validity.

### Observed leak and propagation

~~~~text
RAW_SOURCE_PRESENT=YES
RESOLVED_SETTINGS_PRESENT=YES
DEPENDENCY_DATA_PRESENT=YES
SOURCE_TRACE_PRESENT=YES
ROOT_NODE_PRESENT=YES
DIAGNOSTIC_PRESENT=YES
PROVENANCE_PRESENT=YES
IR_TO_MAP_PRESENT=YES
SERIALIZED_IR_PRESENT=YES

FIRST_ORDINARY_IR_ESCAPE_BOUNDARY=DesignIRNormalizer.source_trace/4
~~~~

The first ordinary IR escape occurs during SourceTrace construction through
redacted_trace_settings/2. Existing body redaction removes executable code
from ordinary settings but leaves sibling execution signatures and a nested
query signature in those settings.

The primary propagation path is source and resolved settings to SourceTrace
settings and effective settings, then to root nodes, diagnostics, provenance,
IR.to_map, and serialized Design IR. A separate path runs through
DependencyExtractor unsupported-setting records into diagnostics and
provenance and serialized Design IR. In a blocking path,
generic_diagnostic_trace/1 can copy a diagnostic raw value into source_name.
Blocking and error results can expose these paths too, so the shared privacy
rule must protect them before ordinary output is assembled.

### Semantic irrelevance evidence

The four classified signatures are not LiveFrames semantic input. An
ephemeral in-memory conversion with those values removed preserved tree,
style, binding, and executable-body semantics. It removed only two
signature-specific unsupported-setting diagnostics, reducing the diagnostic
count from 299 to 297. The remaining diagnostic code and severity counts
matched. Two independently sanitized conversions validated and serialized
identically.

~~~~text
DIAGNOSTICS_BEFORE=299
DIAGNOSTICS_AFTER=297
SIGNATURE_SPECIFIC_UNSUPPORTED_DIAGNOSTICS_REMOVED=2
CLASSIFIED_EXECUTION_SIGNATURE_IS_UNSUPPORTED_SETTING=NO
CLASSIFIED_EXECUTION_SIGNATURE_EMITS_UNSUPPORTED_SETTING_DIAGNOSTIC=NO
~~~~

A field deliberately removed by the execution-security retention policy must
not also be reported as an unsupported ordinary design setting.

The production normalizer currently has no setting-signature classifier.
Repository inspection found no unrelated Bricks setting named signature in
the tracked code, tests, or fixtures. That observation does not justify
deleting an unrelated future setting by key name.

### Closed execution families

| Family | Required structural guard | Classification |
| --- | --- | --- |
| Code execution | Bricks Code element; settings.executeCode is true; settings.code is binary; sibling settings.signature is a 32-byte binary | BRICKS_EXECUTION_AUTHENTICATOR |
| Query Editor execution | settings.query is a map; query.useQueryEditor is true; query.queryEditor is binary; query.signature is a 32-byte binary | BRICKS_EXECUTION_AUTHENTICATOR |

~~~~text
ADMITTED_NOW=
  CODE_EXECUTION_SIGNATURE
  QUERY_EDITOR_SIGNATURE

KNOWN_BRICKS_SIGNED_CONTEXTS_NOT_YET_STRUCTURALLY_AUTHORIZED=
  SVG_SOURCE_CODE
  COMPONENT_QUERY_PROPERTIES
  GLOBAL_QUERY_RECORDS

KNOWN_BUT_UNADMITTED_EXECUTION_CONTEXT_POLICY=FAIL_CLOSED
~~~~

Bricks Academy also documents signed Code element PHP/HTML with execution
enabled, SVG elements whose source is Code, Query loop editor code, component
query properties, and global query records. The canonical evidence here proves
the stored shapes only for Code execution and Query Editor execution. This
authority does not guess the other shapes or treat them as either admitted
family. [Bricks Academy: Code signatures](https://academy.bricksbuilder.io/builder/features/code-signatures/)

Classification must not depend on a Template or Product ID, element ID, source
ordinal, source file path, signature contents, or a signature-derived value.
The structural setting family and admitted value shape are the only signature
classification inputs.

### Unknown and unrelated contexts

The classifier must return one of these decisions:

| Case | Required decision |
| --- | --- |
| A. A signature matches a closed execution family | Remove that field from every ordinary-consumer view. |
| B. An existing ordinary source schema proves that a setting named signature has unrelated semantics | Preserve its existing ordinary setting semantics. Do not delete it by key name. |
| C. A signature appears execution-related, but the closed security classification cannot be proven | Fail closed before producing ordinary IR. Preserve private evidence and return no contaminated ordinary result. |

A field name alone does not establish either security ownership or ordinary
meaning. Absence of the two admitted execution guards is not enough to prove an
unrelated meaning when other execution evidence makes the context ambiguous.
An unfamiliar context requires an authority update before it can be admitted.
Until then, if the setting cannot be matched to a closed execution family or
positively proven ordinary by an existing schema, stop before ordinary IR.
Keep its evidence private, omit the raw value from the error, and do not delete
the field merely because its name is signature. The error must contain no
signature derivative either.

~~~~text
FUTURE_PROVEN_UNRELATED_SIGNATURE_POLICY=
  If an existing authoritative Bricks schema later proves that a
  signature-named field has unrelated ordinary semantics, preserve that field
  according to that schema rather than deleting it by name.
~~~~

## Retention policy

Raw signatures may exist only in the private imported source and private
evidence needed to classify that source. This does not authorize persistence,
logging, rendering, or serialization of those values. The private source and
ordinary Design IR are separate trust domains.

~~~~text
RAW_VALUE_ALLOWED_IN_EPHEMERAL_PRIVATE_SOURCE=YES

RAW_VALUE_ALLOWED_IN_DESIGN_DOCUMENT=NO
RAW_VALUE_ALLOWED_IN_SOURCE_TRACE=NO
RAW_VALUE_ALLOWED_IN_ROOT_NODES=NO
RAW_VALUE_ALLOWED_IN_DIAGNOSTICS=NO
RAW_VALUE_ALLOWED_IN_DIAGNOSTIC_TRACES=NO
RAW_VALUE_ALLOWED_IN_PROVENANCE=NO
RAW_VALUE_ALLOWED_IN_IR_TO_MAP=NO
RAW_VALUE_ALLOWED_IN_SERIALIZED_IR=NO

RETAIN_RAW_SIGNATURE=NO
RETAIN_SIGNATURE_PREFIX=NO
RETAIN_SIGNATURE_SUFFIX=NO
RETAIN_DIRECT_SIGNATURE_HASH=NO
RETAIN_DIRECT_SIGNATURE_FINGERPRINT=NO
RETAIN_SIGNATURE_VALIDITY=NO
RETAIN_SOURCE_RUNTIME_VALIDATION_RESULT=NO
RETAIN_SIGNATURE_PRESENCE_BOOLEAN=NO

SAFE_RETAINED_SIGNATURE_FACT=NONE
~~~~

No ordinary consumer requires signature presence. Do not add a
signature_present=true field. Do not retain a signature fragment or a
cryptographic or non-cryptographic derivative. Debugging convenience is not a
retention justification.

This policy covers source settings, effective settings, node and root traces,
diagnostic raw_value and metadata, diagnostic source_name and traces,
provenance, the in-memory DesignDocument, IR.to_map output, and serialized
Design IR. Success and blocking/error results follow the same rule.

## Signature validation and source ownership

~~~~text
LIVEFRAMES_VALIDATES_BRICKS_SIGNATURE=NO
WORDPRESS_SECRET_AUTHORITY_IMPORTED=NO
WORDPRESS_SALTS_OR_KEYS_REQUIRED=NO
SIGNATURE_VALIDITY_INFERRED=NO
~~~~

Bricks owns authorization to execute Bricks source. LiveFrames imports source
semantics and does not reproduce Bricks execution authorization. LiveFrames
must not import WordPress secrets, salts, or keys to validate a signature.
There is no LiveFrames transition for executing or cryptographically
validating imported Bricks code.

## Source identity invariant

Privacy sanitization creates an ordinary-consumer view. It must not rewrite or
replace the canonical source used for identity.

~~~~text
ORIGINAL_SOURCE_BYTES_MUTATED=NO
SOURCE_HASH_INPUT=ORIGINAL_UNMODIFIED_SOURCE_BYTES
SOURCE_HASH_RECOMPUTED_FROM_SANITIZED_VIEW=NO

CANONICAL_FRAGMENT_HASH_INPUT=ORIGINAL_CANONICAL_FRAGMENT_BYTES
CANONICAL_FRAGMENT_BYTES_MUTATED_BY_PRIVACY_SANITIZATION=NO

DIRECT_SIGNATURE_DERIVATIVE=
  Any value computed from a classified execution signature field itself
DIRECT_SIGNATURE_DERIVATIVE_RETENTION=FORBIDDEN

WHOLE_SOURCE_CONTENT_IDENTITY=
  Hash of the complete original source bytes under the existing source-identity contract
WHOLE_SOURCE_CONTENT_IDENTITY_ALLOWED=YES
WHOLE_SOURCE_CONTENT_IDENTITY_IS_SIGNATURE_FINGERPRINT=NO
~~~~

The private source identity records the original imported bytes. The ordinary
IR view contains the classified security field removed. Never hash sanitized
settings or sanitized source bytes in place of the original input.

The original whole-source hash remains allowed even though the original bytes
contain classified signatures. It identifies the complete imported source; it
is not a signature fingerprint. Never use it to validate a signature, compare
or infer signature validity, or recover a signature. Do not compute a separate
hash or fingerprint from a signature field.

~~~~text
DIRECT_SIGNATURE_DERIVATIVE_IN_ORDINARY_IR=NO
WHOLE_SOURCE_HASH_USES_ORIGINAL_BYTES=YES
~~~~

## Architecture boundary

The shared classification and sanitization step belongs after the loader has
established identity from the original bytes and before ordinary consumers
receive settings:

    raw Bricks input
          |
          v
    Loader and exact source identity
          |
          v
    private structured source model
          |
          v
    execution-security classification
          |
          v
    sanitized ordinary-consumer representation
          |
          +----------------------+
          |                      |
          v                      v
    DependencyExtractor    SourceTrace construction
          |                      |
          +----------+-----------+
                     v
           diagnostics and provenance
                     |
                     v
                  Design IR

Bounded private analysis may use the private source model when an existing
approved source analysis requires it. Ordinary downstream consumers must use
the sanitized representation.

### Proposed implementation boundary

Recommended ownership is LiveFrames.Adapters.Bricks.DesignIRNormalizer. The
conceptual helper name is sanitize_execution_security_metadata/1. The exact
function signature, visibility, and implementation plan remain undecided.

One shared classification/sanitization mechanism must protect ordinary
settings before DependencyExtractor.extract(...), SourceTrace construction,
effective_settings serialization, unsupported-setting diagnostics,
diagnostic SourceTrace construction, and provenance assembly. Do not rely on
separate downstream patches to remove leaked fields after diagnostics or
traces have been built.

The existing executable-source body privacy rule remains in force. These are
two distinct classes:

| Class | Meaning |
| --- | --- |
| EXECUTABLE_SOURCE_BODY | Imported executable source bytes, including PHP or code bodies |
| BRICKS_EXECUTION_AUTHENTICATOR | Bricks metadata used by its source runtime to authorize execution |

Neither class belongs in ordinary Design IR. Signature sanitization must not
weaken existing executable-source body redaction. Existing body-specific
provenance rules remain governed by the executable-source semantic translation
design.

## Lifecycle

The LiveFrames lifecycle is:

    DISCOVERED
      ->
    CONTEXT_CLASSIFIED
      ->
    SECURITY_CLASSIFIED
      ->
    RETENTION_DECIDED
      ->
    SANITIZED_FOR_ORDINARY_IR

Unknown or ambiguous execution context follows:

    UNKNOWN_EXECUTION_CONTEXT or AMBIGUOUS_SECURITY_CLASSIFICATION
      ->
    PRESERVE_PRIVATE_AND_STOP

The only terminal states are SANITIZED_FOR_ORDINARY_IR and
PRESERVE_PRIVATE_AND_STOP.

SANITIZED_FOR_ORDINARY_IR means privacy classification and retention policy
have completed and the resulting ordinary-consumer view is safe for IR
consumption. It does not mean every setting named signature was removed. A
classified execution authenticator is removed. A future schema-authorized
unrelated setting may be preserved. An unknown execution-like context never
reaches this terminal state.

| From | Guard | Side effect | To |
| --- | --- | --- | --- |
| DISCOVERED | A potential signature-bearing Bricks setting is encountered | Record private structural context only | CONTEXT_CLASSIFIED |
| CONTEXT_CLASSIFIED | The closed context matches an authorized execution-authenticator family | Classify the security role. Do not validate the signature value. | SECURITY_CLASSIFIED |
| CONTEXT_CLASSIFIED | An existing ordinary schema proves the setting has unrelated semantics | Keep it outside the security class and preserve its existing ordinary setting semantics | RETENTION_DECIDED |
| SECURITY_CLASSIFIED | No ordinary semantic or audit retention need exists | Select zero raw, derived, or presence retention | RETENTION_DECIDED |
| RETENTION_DECIDED | A classified security field can be excluded, or a proven ordinary field can be retained safely | Remove only the classified security field, or preserve the proven ordinary setting unchanged, in ordinary-consumer views | SANITIZED_FOR_ORDINARY_IR |
| Any classification state | The context appears execution-related but the authorized classification cannot be proven | Keep private evidence and emit no contaminated ordinary result | PRESERVE_PRIVATE_AND_STOP |

VALIDATED_BY_SOURCE_PLATFORM is not a LiveFrames lifecycle state.
EXECUTED is not a LiveFrames lifecycle state.

## Invariants

| ID | Frozen invariant |
| --- | --- |
| I1 | Imported execution signatures are never executed. |
| I2 | Imported execution signatures are never validated by LiveFrames. |
| I3 | Raw signature values never enter ordinary Design IR. |
| I4 | No direct signature derivative enters ordinary Design IR. The allowed whole-source identity hash is not a signature fingerprint. |
| I5 | This capability retains no signature-presence fact. No ordinary Design IR consumer requires one. |
| I6 | Source identity remains based on original, unmodified source bytes. |
| I7 | Semantic recognition never depends on signature contents or derived values. |
| I8 | Template and product IDs never determine signature classification. |
| I9 | Unknown execution-signature contexts fail closed. |
| I10 | An unrelated ordinary setting named signature is not deleted by name alone. |
| I11 | Success and blocking/error paths enforce the same privacy policy. |
| I12 | Existing executable-source body redaction remains intact. |

~~~~text
RAW_EXECUTION_SIGNATURE_IN_ORDINARY_IR=NO
DIRECT_SIGNATURE_DERIVATIVE_IN_ORDINARY_IR=NO
GLOBAL_DELETE_BY_KEY_NAME=NO
UNKNOWN_EXECUTION_CONTEXT_FAILS_CLOSED=YES
PRIVATE_TEMPLATE_FIXTURE_ADDED_TO_REPO=NO
~~~~

## Future TDD acceptance contract

This section defines future implementation evidence only. It does not authorize
production or test changes. Implementation must use red/green TDD.

| Check | Required proof |
| --- | --- |
| T1_CODE_SIGNATURE_SUCCESS_PATH | An admitted Code execution signature is absent from every ordinary IR surface. |
| T2_QUERY_EDITOR_SIGNATURE_SUCCESS_PATH | An admitted Query Editor signature is absent from every ordinary IR surface. |
| T3_BLOCKING_ERROR_PATH | A raw signature or derivative cannot escape through diagnostic raw_value, metadata, source_name, diagnostic trace, or the returned blocking error. |
| T4_UNKNOWN_SIGNATURE_CONTEXT_FAILS_CLOSED | A signature-bearing field matches neither admitted family and no existing ordinary schema authority proves unrelated semantics. It is not deleted merely by key name; its raw value is absent from ordinary IR and returned diagnostics; conversion fails closed; evidence remains private. |
| T5_CANONICAL_TEMPLATE_124 | Private out-of-band acceptance gate only: prove four private signatures, zero raw signature hits in ordinary IR, 82 source elements, 82 IR nodes, five roots, CODE1/CODE2 preserved unsupported, CODE3 normalized, and no source execution. |
| T6_SOURCE_IDENTITY | Sanitization does not change the source hash derived from the original input bytes. |
| T7_DETERMINISM | Two sanitized conversions of identical source serialize identically. |
| T8_EXISTING_EXECUTABLE_BODY_PRIVACY | Existing executable-source body redaction remains green across ordinary IR surfaces. |
| T9_CLASSIFIED_SIGNATURE_DIAGNOSTIC_SUPPRESSION | Code and Query Editor execution-authenticator fields generate no ordinary unsupported-setting diagnostics; no value, derivative, or presence fact is retained; unrelated unsupported-setting diagnostics remain unchanged. |

The future unrelated-setting policy remains conditional on a real authoritative
Bricks schema proving that setting's ordinary meaning. Current repository
evidence does not provide such a schema, so implementation must not fabricate
one for a test.

~~~~text
T5_CANONICAL_TEMPLATE_124_CLASS=PRIVATE_OUT_OF_BAND_ACCEPTANCE_GATE
T5_REPOSITORY_FIXTURE=NO
PRIVATE_TEMPLATE_124_BYTES_IN_REPOSITORY=FORBIDDEN
~~~~

T5 is a private owner-run acceptance gate after repository implementation
tests pass. Repository CI must use synthetic or public-safe fixtures only; the
private canonical source bytes must never be copied into tracked tests. The
out-of-band rerun must prove:

~~~~text
PRIVATE_SIGNATURE_COUNT=4
ORDINARY_IR_RAW_SIGNATURE_HITS=0

SOURCE_ELEMENT_COUNT=82
IR_NODE_COUNT=82
ROOT_COUNT=5

CODE1=PRESERVED_UNSUPPORTED
CODE2=PRESERVED_UNSUPPORTED
CODE3=NORMALIZED
SOURCE_CODE_EXECUTED=NO
~~~~

CODE3 must normalize to the accepted commerce.product.full_description
binding. The canonical source must not be executed.

## Canonical-ingestion relationship

The existing draft at
docs/development/product_767_template_124_canonical_ingestion_authority.md
remains BLOCKED_UNCHANGED in its separate dedicated worktree. It is not copied
into this worktree and is not modified by this task. This authority does not
publish it.
Canonical Design IR identity may be recomputed only after execution-security
sanitization has been implemented and verified. Historical ingestion evidence
remains evidence and is not rewritten here.

~~~~text
CANONICAL_INGESTION_DRAFT_STATUS=BLOCKED_UNCHANGED
TEMPLATE_124_CANONICAL_INGESTION_PUBLICATION_AUTHORIZED=NO
~~~~

## Performance and scaling

~~~~text
DATA_LAYER=COLD_BUILD_TIME
REDIS=NOT_APPLICABLE
CACHEX=NOT_APPLICABLE
ETS=NOT_APPLICABLE
GENSERVER=NOT_APPLICABLE
PUBSUB=NOT_APPLICABLE
OBAN=NOT_APPLICABLE
POSTGRES=NOT_APPLICABLE
DB_CALLS=NONE
NETWORK_CALLS_DURING_CONVERSION=NONE
TARGET_COMPLEXITY=O(number_of_imported_settings)
~~~~

Classification and sanitization must make one bounded pass over admitted
imported settings. Do not add a second template runtime subsystem, database
lookup, network lookup, or runtime cache.

## Security and multi-tenant rules

Source execution authorization belongs to the source platform, not LiveFrames.
LiveFrames must not import WordPress secret material to validate signatures.
Security-derived signature metadata must not be rendered, componentized, or
exposed through diagnostics. No raw or derived signature retention may be
justified by debugging convenience.

~~~~text
CROSS_TENANT_SIGNATURE_REUSE=FORBIDDEN
SIGNATURE_AS_CACHE_KEY=FORBIDDEN
SIGNATURE_AS_COMPONENT_IDENTITY=FORBIDDEN
SIGNATURE_AS_SEMANTIC_IDENTITY=FORBIDDEN
~~~~

No execution signature may become globally addressable state.

## Scope exclusions

This authority excludes:

- production implementation;
- test implementation;
- WordPress signature validation;
- PHP execution;
- Query Editor execution;
- general-purpose secret detection;
- generic deletion of every field named signature;
- Template 124 componentization;
- NativeGenerator;
- commerce realization;
- canonical-ingestion publication.

## Stop conditions

Stop without implementation if any of these conditions applies:

~~~~text
STOP=MAIN_MOVED_WITH_RELEVANT_OVERLAP
STOP=GOVERNING_AUTHORITY_CONFLICT
STOP=SIGNATURE_SEMANTIC_CLASSIFICATION_NO_LONGER_PROVEN
STOP=NON_SECURITY_SIGNATURE_COLLISION_REQUIRES_BROADER_POLICY
STOP=SOURCE_IDENTITY_REQUIRES_SANITIZED_BYTES
STOP=WORDPRESS_RUNTIME_REQUIRED
STOP=SIGNATURE_VALIDATION_REQUIRED
STOP=TEMPLATE_SPECIFIC_POLICY_REQUIRED
STOP=PRIVATE_SOURCE_VALUE_REQUIRED_IN_AUTHORITY
STOP=SOURCE_HASH_POLICY_CONTRADICTION
STOP=ADDITIONAL_BRICKS_CONTEXT_SHAPE_ASSUMED
STOP=FABRICATED_ORDINARY_SIGNATURE_SCHEMA
STOP=PRIVATE_TEMPLATE_SOURCE_ADDED_TO_REPOSITORY
STOP=AUTHORITY_AUTHORIZES_IMPLEMENTATION
STOP=AUTHORITY_AUTHORIZES_COMPONENTIZATION
~~~~

The draft may not authorize production implementation, test implementation,
componentization, NativeGenerator, or publication of the canonical-ingestion
draft. Owner review and explicit authorization are required before production
or test implementation begins.
