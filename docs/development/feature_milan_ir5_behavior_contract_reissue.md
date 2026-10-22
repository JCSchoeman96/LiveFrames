# Feature Milan IR5 BehaviorContract reissue

## Status

```text
LIFECYCLE=ir5_behavior_reissue_review_ready
TERMINAL_STATE=IR5_BEHAVIOR_REISSUE_REVIEW_READY
STOP=NONE
OWNER_DECISION=APPROVE_IR5_BEHAVIOR_REISSUE_CANDIDATE
IR5_BEHAVIOR_CONTRACT_AUTHORITY_CREATED=YES
IR5_BEHAVIOR_REVIEW_CREATED=NO
IR5_BEHAVIOR_REVIEW_ID=NONE
GATE_B2_AUTHORIZED=NO
TASK_10_IMPLEMENTATION_AUTHORIZED=NO
```

This record freezes one owner-approved IR5 BehaviorContract candidate for the exact current Milan DesignDocument. It preserves the accepted Milan `selection@1.0.0` semantics. Its lifecycle remains review-ready until a separate Gate B2 review authorizes one exact BehaviorReviewResult against the merged B1 bytes.

The historical IR3 and IR4 Behavior artifacts remain unchanged and valid for their exact historical DesignDocument identities under the accepted compatibility authority. The historical Milan IR4 contract and review result are independently reconstructed and validated below. The IR4 review result is not reused for this IR5 candidate.

This record does not create or authorize a BehaviorReviewResult, ComponentizationProposer, ComponentReview, SourceNodeDispositionDecision, NativeGenerator, runtime, or Task 10 implementation.

## Base and source identities

```text
REPOSITORY=JCSchoeman96/LiveFrames
BASE_SHA=ccd31b77d4eb0debe212d75963660339242f9986
BASE_TREE=999bf7a5282a310f219304eca6e0e5583c055b8b
BASE_CI=39832172176
BASE_CI_HEAD=ccd31b77d4eb0debe212d75963660339242f9986
BASE_CI_EVENT=push
BASE_CI_RESULT=SUCCESS

PRIVATE_SOURCE=private_reference/frames/staging-2026-09/feature-section-milan/bricks-component-ybsqrl-feature-section-milan.json
PRIVATE_SOURCE_SHA256=f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132
PRIVATE_SOURCE_EXECUTED=NO

ACSS_SOURCE=fixtures/automatic_css/acss_settings.json
ACSS_SHA256=19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05

BREAKPOINT_AUTHORITY=sources/work/feature_milan/fidelity/breakpoint_authority.json
BREAKPOINT_AUTHORITY_SHA256=e507d7d6ff33bbb4fb0880d46c44f3b5337d6c95c227154e11510e6a7a2c1b34
BREAKPOINT_AUTHORITY_VALIDATION=PASS
```

The Bricks export and ACSS fixture were read as data. Embedded JavaScript and PHP were not executed. No executable source was copied into this record or into generated runtime code.

## Current IR5 DesignDocument identity

The current production path loaded the ACSS fixture, normalized the Milan Bricks export through the accepted Bricks adapter, resolved the accepted breakpoint authority, encoded the resulting DesignDocument, and derived its identity through `LiveFrames.IR.Identity`.

```text
CURRENT_IR_VERSION=5.0.0
CURRENT_CANONICALIZATION_ID=lf-ir-serializer-v1
CURRENT_DIGEST_ALGORITHM=sha-256
CURRENT_DESIGN_DOCUMENT_DIGEST=9ae73053d9224bebcb71833b77094a17c3ef7c3a25f0b5b1c4dbad5aaf9d2229
CURRENT_DESIGN_DOCUMENT_CANONICAL_BYTES_LENGTH=412682
CURRENT_DOCUMENT_REPRODUCED=YES
```

The resolved document retains the accepted Milan owner and collection targets. The current source element relationship is:

```text
SOURCE_ELEMENT_ID=2265d2
CURRENT_DESIGN_NODE_ID=node_000001_000002
CURRENT_SEMANTIC_TYPE=unsupported
CURRENT_NORMALIZATION_STATUS=PRESERVED_UNSUPPORTED
CURRENT_SOURCE_TRACE_MATCH=YES
CURRENT_VALUE_BINDING_COUNT=0
CURRENT_GENERATED_DOM_ROLE=NONE_UNSUPPORTED_NO_FROZEN_TAG
IR5_SEMANTIC_OWNER_CONFLICT=NO
TARGET_RELATIONSHIP_UNCHANGED=YES
```

The IR5 document contains no ValueBinding attributed to source element `2265d2`, and the executable-source translation did not add an Interaction for it. The unsupported source node has no frozen semantic role from which a generated DOM role could be derived. Its presence remains a current blocker for Q13 and downstream componentization decisions.

## Historical IR4 Behavior authority

The historical authority records remain the source of the accepted IR4 payload:

```text
HISTORICAL_IR_VERSION=4.0.0
HISTORICAL_DESIGN_DOCUMENT_DIGEST=1fdc6e859bdb624f0931106f78a46b25baae89f807b6bfc7ba3e14ee79da1045
HISTORICAL_BEHAVIOR_BINDING_ID=bnd_fd4b72a566b2c38f00f5396bfc0f2c26453d49a1c19290dfe9dec2a67ee78fe4
HISTORICAL_BEHAVIOR_CONTRACT_DIGEST=5d2b37acbfa357a66357bf7ea09ce21f15353702d85a5d202f275dcb6794a344
HISTORICAL_BEHAVIOR_REVIEW_ID=brv_d19b80b64c3e3281a42ae6763ea95877b45e2728c9a29f89a220777e8b45d2dd
HISTORICAL_BEHAVIOR_CANONICAL_BYTES_LENGTH=1365
HISTORICAL_IR4_BYTES_UNCHANGED=YES
HISTORICAL_IR4_STANDALONE_VALID=YES
HISTORICAL_IR4_MATCHES_CURRENT_DOCUMENT=NO
HISTORICAL_CURRENT_DOCUMENT_DIAGNOSTIC=behavior.design_document.identity_mismatch
```

The IR4 BehaviorContract canonical bytes match its existing authority record. Its binding ID and contract digest match the recorded values. The corresponding IR4 BehaviorReviewResult validates structurally, matches the exact IR4 contract, passes the approved-singleton gate, and retains its recorded review ID. Applying the IR4 contract to the current IR5 DesignDocument fails at exact identity validation with `behavior.design_document.identity_mismatch`.

The compatibility rule remains exact identity equality. IR3 and IR4 artifacts stay valid only for their own historical documents. This record does not change their identities, bytes, digests, binding IDs, or review IDs.

## IR5 typed BehaviorContract candidate

The typed candidate uses the current exact IR5 DesignDocument identity above. Before identity assignment, its format version is `1.0.0`, it has one binding, empty diagnostics and provenance, and the binding's ID and ordinal are unset. `LiveFrames.Behavior.BindingIdentity.assign/1` derives the ordinal and binding ID.

```text
BEHAVIOR_CONTRACT_FORMAT_VERSION=1.0.0
BINDINGS_COUNT=1
CONTRACT_DIAGNOSTICS=[]
CONTRACT_PROVENANCE={}

PRE_ASSIGNMENT_BINDING_ID=nil
PRE_ASSIGNMENT_BINDING_ORDINAL=nil
BINDING_ORDINAL=0
BINDING_ID_MANUALLY_ASSIGNED=NO

PRIMITIVE_REF_KIND=selection
PRIMITIVE_REF_DEFINITION_VERSION=1.0.0
BINDING_ROLE=primary
OWNER_NODE_ID=node_000001
INITIAL_STATE=nil

PRIMITIVE_POLICY_VALUES={"alignment":"position","advance_boundary":"wrap"}

TRIGGER_ACTIVATE_ORIGIN=node_000001_000001_000001_000002_000001
TRIGGER_TIMER_ORIGIN=nil

CONTROLLED_TARGET_CONTROL_COLLECTION=node_000001_000001_000001_000002_000001
CONTROLLED_TARGET_PRESENTATION_COLLECTION_1=node_000001_000001_000001_000002_000001_000002_000001
CONTROLLED_TARGET_PRESENTATION_COLLECTION_2=node_000001_000001_000002_000001

TIMER_POLICY={"purpose":"advance_selection","interval_ms":5000,"start":"on_initialization","manual_activation":"stop","restart":"never","reset":"none","reduced_motion":"disable_automatic_advance"}

FOCUS_POLICY=nil
KEYBOARD_POLICY=nil
MOTION_POLICY=nil
RESPONSIVE_OVERRIDES=[]
BINDING_DIAGNOSTICS=[]
BINDING_PROVENANCE={}
BINDING_SOURCE_TRACE=nil
```

No new behavior is inferred. This contract adds no Tabs semantics, keyboard navigation, focus movement or trapping, server-owned selection state, LiveView events, PubSub, GenServer, Redis, responsive Behavior overrides, timer restart or reset semantics, `word_limit` Behavior, custom CSS Behavior, or StateRule Behavior.

The binding identity algorithm remains `lf-behavior-binding-v1-jcs-sha256`. The BehaviorContract serializer algorithm remains `lf-behavior-v1-jcs-sha256`. Neither algorithm nor the BehaviorContract serialized shape or format version changes.

## Derived IR5 BehaviorContract identity

```text
IR5_BEHAVIOR_BINDING_ID=bnd_abf701b79aba7597825525c7ddf5065e89a2fdcfb378797f63e3d9fb74ff8ee2
IR5_BEHAVIOR_CONTRACT_DIGEST_ALGORITHM=lf-behavior-v1-jcs-sha256
IR5_BEHAVIOR_CONTRACT_DIGEST=1e0095418d96f392594a155d9c6ea9610b6b5f4d62c6d0205df66dedea57506a
IR5_BEHAVIOR_CONTRACT_CANONICAL_BYTES_LENGTH=1365
IR5_CONTRACT_STRUCTURE_VALID=YES
IR5_CONTRACT_CURRENT_DOCUMENT_VALID=YES
```

The canonical JSON below is the exact byte sequence returned by `LiveFrames.Behavior.Serializer.encode/1` for the typed candidate. Its SHA-256 digest, computed through `LiveFrames.Behavior.Serializer.digest/1`, is the recorded contract digest.

```json
{"behavior_contract_format_version":"1.0.0","bindings":[{"binding_id":"bnd_abf701b79aba7597825525c7ddf5065e89a2fdcfb378797f63e3d9fb74ff8ee2","binding_role":"primary","controlled_targets":[{"node_id":"node_000001_000001_000001_000002_000001","role":"control_collection"},{"node_id":"node_000001_000001_000001_000002_000001_000002_000001","role":"presentation_collection"},{"node_id":"node_000001_000001_000002_000001","role":"presentation_collection"}],"diagnostics":[],"focus_policy":null,"initial_state":null,"keyboard_policy":null,"motion_policy":null,"ordinal":0,"owner_node_id":"node_000001","primitive_policy_values":{"advance_boundary":"wrap","alignment":"position"},"primitive_ref":{"definition_version":"1.0.0","kind":"selection"},"provenance":{},"responsive_overrides":[],"source_trace":null,"timer_policy":{"interval_ms":5000,"manual_activation":"stop","purpose":"advance_selection","reduced_motion":"disable_automatic_advance","reset":"none","restart":"never","start":"on_initialization"},"triggers":[{"kind":"activate","origin_node_id":"node_000001_000001_000001_000002_000001"},{"kind":"timer","origin_node_id":null}]}],"design_document_identity":{"canonicalization_id":"lf-ir-serializer-v1","digest":"9ae73053d9224bebcb71833b77094a17c3ef7c3a25f0b5b1c4dbad5aaf9d2229","digest_algorithm":"sha-256","ir_version":"5.0.0"},"diagnostics":[],"provenance":{}}
```

The fenced block markers and the line break after the JSON are Markdown delimiters; the canonical payload itself is 1,365 bytes and contains no trailing newline.

## IR4 to IR5 semantic delta

The machine-derived comparison normalizes the typed IR4 and IR5 contracts, then compares every field path. Only the exact DesignDocument identity and the binding ID derived from that identity differ.

| Field | Changed | Classification |
| --- | --- | --- |
| `design_document_identity.ir_version` | YES | EXPECTED_IDENTITY_DIFFERENCE |
| `design_document_identity.digest` | YES | EXPECTED_IDENTITY_DIFFERENCE |
| `bindings[0].binding_id` | YES | EXPECTED_DERIVED_ID_DIFFERENCE |
| BehaviorContract format version | NO | unchanged |
| Binding ordinal | NO | unchanged |
| Primitive kind and version | NO | unchanged |
| Owner and binding role | NO | unchanged |
| Initial state and primitive policy | NO | unchanged |
| Triggers and controlled targets | NO | unchanged |
| Timer policy | NO | unchanged |
| Focus, keyboard, and motion policies | NO | unchanged |
| Responsive Behavior overrides | NO | unchanged |
| Contract and binding diagnostics | NO | unchanged |
| Contract and binding provenance | NO | unchanged |
| Binding source trace | NO | unchanged |

```text
EXPECTED_IDENTITY_DIFFERENCE_PATHS=design_document_identity.digest,design_document_identity.ir_version
EXPECTED_DERIVED_ID_DIFFERENCE_PATHS=bindings[0].binding_id
UNEXPECTED_SEMANTIC_DIFFERENCE_PATHS=
UNEXPECTED_SEMANTIC_DIFFERENCE_COUNT=0
SEMANTIC_DELTA_ONLY_IDENTITY_FIELDS=YES
BEHAVIOR_TYPE_UNCHANGED=YES
BEHAVIOR_VERSION_UNCHANGED=YES
BEHAVIOR_SEMANTIC_ROLE_UNCHANGED=YES
TARGET_RELATIONSHIP_UNCHANGED=YES
BEHAVIOR_EVIDENCE_STILL_APPLICABLE=YES
```

The contract digest changes because canonical bytes contain the new exact document identity and derived binding ID. The digest change is not a Behavior semantic field.

## Source evidence classification

```text
OPERATIVE_EVIDENCE:
  BEH-P007
  docs/development/feature_milan_timed_selection_mapping_preflight.md
  docs/development/c09b2b_behavior_identity_ir5_compatibility_authority.md

HISTORICAL_CONTINUITY_EVIDENCE:
  docs/development/feature_milan_ir4_post_resolution_behavior_contract_reissue.md
  docs/development/feature_milan_ir4_resolved_design_document_identity.md
  docs/development/feature_milan_ir4_post_resolution_behavior_review_result.md

SUPERSEDED_CONTEXT:
  BEH-P006
```

`BEH-P007` records the operative Milan v1 evidence for positional synchronization, ordered wrap, the 5,000 ms timer, and stopping on manual activation. The timed-selection mapping preflight limits the mapping to Selection and the exact seven-key TimerPolicy. C09B2B supplies the current closed IR compatibility set and preserves exact DesignDocument identity matching.

The three IR4 records provide historical payload and identity continuity evidence. `BEH-P006` remains superseded context for Milan v1 under `BEH-P007`; it is not claimed as independently operative current evidence.

## Validation and determinism

The IR5 contract passed all accepted Behavior validations against the reproduced IR5 DesignDocument. The historical IR4 contract and review remain valid for their exact historical identity; the IR4 contract fails attachment to this current document with the exact mismatch diagnostic recorded above.

```text
STRUCTURE_VALIDATION=PASS
SEMANTIC_VALIDATION=PASS
FULL_VALIDATION=PASS
VALIDATION_DIAGNOSTIC_CODES=NONE

RUN_1_DESIGN_DIGEST=9ae73053d9224bebcb71833b77094a17c3ef7c3a25f0b5b1c4dbad5aaf9d2229
RUN_2_DESIGN_DIGEST=9ae73053d9224bebcb71833b77094a17c3ef7c3a25f0b5b1c4dbad5aaf9d2229
RUN_1_BINDING_ID=bnd_abf701b79aba7597825525c7ddf5065e89a2fdcfb378797f63e3d9fb74ff8ee2
RUN_2_BINDING_ID=bnd_abf701b79aba7597825525c7ddf5065e89a2fdcfb378797f63e3d9fb74ff8ee2
RUN_1_CONTRACT_DIGEST=1e0095418d96f392594a155d9c6ea9610b6b5f4d62c6d0205df66dedea57506a
RUN_2_CONTRACT_DIGEST=1e0095418d96f392594a155d9c6ea9610b6b5f4d62c6d0205df66dedea57506a
RUN_1_CANONICAL_BYTES_LENGTH=1365
RUN_2_CANONICAL_BYTES_LENGTH=1365

DESIGN_IDENTITIES_IDENTICAL=YES
BINDING_IDS_IDENTICAL=YES
CONTRACT_DIGESTS_IDENTICAL=YES
CANONICAL_BYTES_IDENTICAL=YES
HISTORICAL_IR4_BYTES_UNCHANGED=YES
HISTORICAL_IR4_STANDALONE_VALID=YES
```

Each run used a separate `mix run --no-start` BEAM process and independently loaded the source fixtures, normalized and resolved the DesignDocument, reconstructed both contracts, assigned the IR5 binding identity, validated the candidate, and encoded its canonical bytes. No source JavaScript or PHP was executed. The generated contract bytes remained in `/tmp` for byte comparison.

## Review and downstream boundary

```text
IR5_BEHAVIOR_CONTRACT_AUTHORITY_CREATED=YES
IR5_BEHAVIOR_REVIEW_CREATED=NO
IR5_BEHAVIOR_REVIEW_ID=NONE
HISTORICAL_IR4_REVIEW_REUSED=NO
GATE_B2_AUTHORIZED=NO
TASK_10_IMPLEMENTATION_AUTHORIZED=NO

Q13_RESOLVED=NO
UNSUPPORTED_NODE_ID=node_000001_000002
UNSUPPORTED_NODE_BLOCKER_CURRENT=YES

A1_STARTED=NO
SEMANTIC_INPUT_CREATED=NO
COMPONENT_PROPOSER_STARTED=NO
COMPONENT_CONTRACT_CREATED=NO
COMPONENTIZATION_PLAN_CREATED=NO
COMPONENT_REVIEW_CREATED=NO
SOURCE_NODE_DISPOSITION_CREATED=NO
NATIVE_GENERATOR_STARTED=NO
RUNTIME_STARTED=NO
```

Gate B2 is a separate review of one exact BehaviorReviewResult against the merged B1 authority bytes. This candidate does not choose a review timestamp or reuse the historical IR4 review ID. Q13 remains unresolved, and the unsupported-node blocker remains current.

## Performance classification

```text
DATA_LAYER=COLD_COMPILE_REVIEW_TIME

ETS=N/A
CACHEX=N/A
REDIS=N/A
POSTGRES=N/A
PGBouncer=N/A
READ_REPLICA=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A

REQUIRED_INDEXES=N/A
CACHE_TTL=N/A
CACHE_INVALIDATION=N/A
REDIS_STRUCTURE=N/A
PUBSUB_BROADCAST=N/A

RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
RUNTIME_POLLING=0
NEW_DEPENDENCY=NONE
```
