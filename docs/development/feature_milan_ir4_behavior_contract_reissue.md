# Feature Milan IR4 BehaviorContract reissue

## Accepted base and evidence

```text
BASE_SHA=1fdc0e163cc4cc2a578f86c9dc192628e96df91d
BASE_TREE=ac15ba10c3fb3823706cf556ca30167c3cbe715c
BASE_CI_RUN=38448417769
BASE_CI_HEAD=1fdc0e163cc4cc2a578f86c9dc192628e96df91d
BASE_CI_STATUS=completed
BASE_CI_RESULT=success

IR4_NORMALIZATION_PR=199
IR4_NORMALIZATION_MERGE_SHA=d70ce20e8af67338a4679d5d3d18f1132b5cf2af
IR4_NORMALIZATION_POST_MERGE_CI=38448377174
IR4_NORMALIZATION_POST_MERGE_CI_RESULT=success

PRIVATE_MILAN_PATH=/home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/feature-section-milan/bricks-component-ybsqrl-feature-section-milan.json
PRIVATE_MILAN_SHA256=f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132
PRIVATE_SOURCE_EXECUTED=NO

ACSS_FIXTURE_PATH=/home/jcschoeman96/projects/current/LiveFrame/fixtures/automatic_css/acss_settings.json
ACSS_FIXTURE_SHA256=19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05
ACSS_SOURCE_VERSION=4.0.1
ACSS_SOURCE_VERSION_STATUS=fixture_reference
ACSS_STRICT=true
ACSS_PROFILE=hero_foundation
```

The private Milan JSON was read as inert data. Its embedded JavaScript was not executed. The contract was derived using the accepted ACSS fixture and options above.

## Reproduced IR4 DesignDocument identity

Each reconstruction loaded the ACSS fixture with `AutomaticCSS.from_file/2`, passed the resulting token set and Milan source path to `Bricks.to_ir/2` with `component_id=ybsqrl`, validated the in-memory document with `IR.validate/1`, and derived the identity with `IR.Identity.from_document/1`.

```text
IR4_DOCUMENT_REPRODUCED=YES
IR4_IR_VERSION=4.0.0
IR4_CANONICALIZATION_ID=lf-ir-serializer-v1
IR4_DIGEST_ALGORITHM=sha-256
IR4_DESIGN_DOCUMENT_DIGEST=52544dcc0d279d91d3d56d054c9785b18f96e77a5520b782726b678c404db864

BEHAVIOR_OWNER=node_000001
CONTROL_COLLECTION=node_000001_000001_000001_000002_000001
FEATURE_DESCRIPTION_PRESENTATION=node_000001_000001_000001_000002_000001_000002_000001
DESKTOP_MEDIA_PRESENTATION=node_000001_000001_000002_000001
MOBILE_MEDIA_WRAPPER_SELECTION_TARGET=NO
```

The new BehaviorContract contains no `word_limit(16)` behavior. The word limit remains in the DesignDocument value-binding layer.

## Historical IR3 boundary

```text
HISTORICAL_IR3_IR_VERSION=3.0.0
HISTORICAL_IR3_DESIGN_DOCUMENT_DIGEST=b75c599cc0b8718f00897e8686d946db85c3c94014225b0612b892421ec9e114
HISTORICAL_IR3_BINDING_ID=bnd_dd2783c867d80d5de15ea16cabae5ccdba59daaf6b975ad2e5d3d5c3f0647a06
HISTORICAL_IR3_BEHAVIOR_CONTRACT_DIGEST=3a5173b0c873bb502a7e949c3bdfa13eb97f97e8acf229c9c240c758856cd9cc
HISTORICAL_IR3_REVIEW_ID=brv_ee78cac37236ffd7b50cc216e4e7d2c899f0d776972a2cf267edf705d17a3810

HISTORICAL_IR3_ARTIFACTS_CHANGED=NO
HISTORICAL_BINDING_ID_REUSED=NO
HISTORICAL_CONTRACT_DIGEST_REUSED=NO
HISTORICAL_REVIEW_REUSED=NO
```

The accepted historical IR3 canonical contract was read from `feature_milan_behavior_contract_review.md` and compared with the new serialized contract after replacing only the IR version, DesignDocument digest, and binding ID values with their corresponding new identity values. The remaining serialized values matched.

## Preserved BehaviorContract semantics

The pre-identity input binding used `binding_id=nil` and `ordinal=nil`. `BindingIdentity.assign/1` assigned the ID and ordinal. No identity value was set manually.

```text
contract_format_version=1.0.0
bindings_count=1
diagnostics=[]
provenance={}

primitive_ref.kind=selection
primitive_ref.definition_version=1.0.0
binding_role=primary
owner_node_id=node_000001
initial_state=nil
primitive_policy_values={"alignment":"position","advance_boundary":"wrap"}

trigger_activate_origin=node_000001_000001_000001_000002_000001
trigger_timer_origin=nil

target_control_collection=node_000001_000001_000001_000002_000001
target_presentation_collection=node_000001_000001_000001_000002_000001_000002_000001
target_presentation_collection=node_000001_000001_000002_000001

timer_policy={"purpose":"advance_selection","interval_ms":5000,"start":"on_initialization","manual_activation":"stop","restart":"never","reset":"none","reduced_motion":"disable_automatic_advance"}

focus_policy=nil
keyboard_policy=nil
motion_policy=nil
responsive_overrides=[]
binding_diagnostics=[]
binding_provenance={}
binding_source_trace=nil
```

No Tabs behavior, keyboard navigation, focus movement, responsive behavior, mobile target synchronization, durable cross-collection item IDs, new timer cleanup authority, or accessibility runtime behavior was added.

## New canonical BehaviorContract

```text
BINDING_ORDINAL=0
NEW_BINDING_ID=bnd_caf04646aa92bbf2026ec3a2a1298a448ab03c624d27519c0740f874e64d22a7
BEHAVIOR_CONTRACT_DIGEST_ALGORITHM=lf-behavior-v1-jcs-sha256
CANONICAL_BYTES_LENGTH=1365
BEHAVIOR_CONTRACT_DIGEST=303273984f180ea671ba968c841672603f0a0604368385b8f295e1cfcc64f826
```

Canonical BehaviorContract JSON:

```json
{"behavior_contract_format_version":"1.0.0","bindings":[{"binding_id":"bnd_caf04646aa92bbf2026ec3a2a1298a448ab03c624d27519c0740f874e64d22a7","binding_role":"primary","controlled_targets":[{"node_id":"node_000001_000001_000001_000002_000001","role":"control_collection"},{"node_id":"node_000001_000001_000001_000002_000001_000002_000001","role":"presentation_collection"},{"node_id":"node_000001_000001_000002_000001","role":"presentation_collection"}],"diagnostics":[],"focus_policy":null,"initial_state":null,"keyboard_policy":null,"motion_policy":null,"ordinal":0,"owner_node_id":"node_000001","primitive_policy_values":{"advance_boundary":"wrap","alignment":"position"},"primitive_ref":{"definition_version":"1.0.0","kind":"selection"},"provenance":{},"responsive_overrides":[],"source_trace":null,"timer_policy":{"interval_ms":5000,"manual_activation":"stop","purpose":"advance_selection","reduced_motion":"disable_automatic_advance","reset":"none","restart":"never","start":"on_initialization"},"triggers":[{"kind":"activate","origin_node_id":"node_000001_000001_000001_000002_000001"},{"kind":"timer","origin_node_id":null}]}],"design_document_identity":{"canonicalization_id":"lf-ir-serializer-v1","digest":"52544dcc0d279d91d3d56d054c9785b18f96e77a5520b782726b678c404db864","digest_algorithm":"sha-256","ir_version":"4.0.0"},"diagnostics":[],"provenance":{}}
```

## Determinism and validation

Two separate `mix run --no-start` processes each reproduced the IR4 document, derived its identity, constructed the pre-identity semantic contract, assigned binding identity, serialized and digested the contract, compared semantic fields with the historical canonical contract, and validated against the reproduced document.

```text
RUN_1_BINDING_ID=bnd_caf04646aa92bbf2026ec3a2a1298a448ab03c624d27519c0740f874e64d22a7
RUN_1_CANONICAL_BYTES_LENGTH=1365
RUN_1_BEHAVIOR_CONTRACT_DIGEST=303273984f180ea671ba968c841672603f0a0604368385b8f295e1cfcc64f826
RUN_1_STRUCTURE_VALIDATION=PASS
RUN_1_SEMANTIC_VALIDATION=PASS
RUN_1_FULL_VALIDATION=PASS

RUN_2_BINDING_ID=bnd_caf04646aa92bbf2026ec3a2a1298a448ab03c624d27519c0740f874e64d22a7
RUN_2_CANONICAL_BYTES_LENGTH=1365
RUN_2_BEHAVIOR_CONTRACT_DIGEST=303273984f180ea671ba968c841672603f0a0604368385b8f295e1cfcc64f826
RUN_2_STRUCTURE_VALIDATION=PASS
RUN_2_SEMANTIC_VALIDATION=PASS
RUN_2_FULL_VALIDATION=PASS

CANONICAL_BYTES_IDENTICAL=YES
BINDING_IDS_IDENTICAL=YES
CONTRACT_DIGESTS_IDENTICAL=YES
SEMANTIC_DELTA_ONLY_IDENTITY_FIELDS=YES
```

The canonical byte files were written under `/tmp` and compared byte-for-byte. They were not added to the repository. The structure validation checked exact DesignDocument identity, deterministic binding ID, resolvable references, and owner-subtree containment. Semantic validation accepted the `selection@1.0.0` contract.

## Review and downstream boundary

```text
CONTRACT_REISSUED=YES
CONTRACT_CANDIDATE_FROZEN=YES

OWNER_APPROVAL_RECORDED=NO
BEHAVIOR_REVIEW_RESULT_ISSUED=NO
BEHAVIOR_REVIEW_ID=NONE

REAL_MILAN_D0_EXECUTED=NO
SEMANTIC_INPUT_CREATED=NO
COMPONENT_PROPOSER_EXECUTED=NO
COMPONENT_REVIEW_EXECUTED=NO
P7_D1_STARTED=NO
P7_E_STARTED=NO
RUNTIME_STARTED=NO
```

This record does not supply an owner decision or a `BehaviorReviewResult`. The next required gate is owner review of this exact IR4 contract candidate. If the owner approves it, a separate slice must issue a new immutable `BehaviorReviewResult` before any downstream work.

## Performance classification

```text
DATA_LAYER=COLD_COMPILE_REVIEW_TIME
HOT_DATA=N/A
WARM_DATA=N/A
REDIS=N/A
POSTGRES=N/A
PGBouncer=N/A
READ_REPLICA=N/A
ETS=N/A
CACHEX=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
TTL=N/A
DB_INDEX=N/A
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
```
