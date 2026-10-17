# Feature Milan post-resolution BehaviorContract reissue

## Status

```text
LIFECYCLE=post_resolution_behavior_reissue_review_ready
TERMINAL_STATE=POST_RESOLUTION_BEHAVIOR_REISSUE_REVIEW_READY
STOP=NONE
```

This record reissues the accepted `selection@1.0.0` BehaviorBinding and BehaviorContract for the resolved Feature Milan DesignDocument identity. It preserves the accepted behavior semantics. Only the DesignDocument digest and the derived binding ID changed, so the resulting BehaviorContract digest changed as well. This record does not create a BehaviorReviewResult or start downstream work.

## Exact base and accepted identity chain

```text
BASE_SHA=59e81aaf431e7b4031c25366e86614e81322f8c1
BASE_TREE=cf3d9a050900bf042c48720224068cf5aa884fdc
BASE_CI_RUN=39053281280
BASE_CI_HEAD=59e81aaf431e7b4031c25366e86614e81322f8c1
BASE_CI_RESULT=success
BASE_CI_URL=https://github.com/JCSchoeman96/LiveFrames/actions/runs/39053281280

PR233_APPROVED_HEAD=9de8742ed6364dedc5ba04ae8afa2c09b7edf13a
PR233_MERGE_SHA=3b25591d965a9bc832979757c603da51f044538d
PR233_POST_MERGE_CI=39053271709
PR233_POST_MERGE_CI_HEAD=3b25591d965a9bc832979757c603da51f044538d
PR233_POST_MERGE_CI_RESULT=success

PR234_MERGE_SHA=59e81aaf431e7b4031c25366e86614e81322f8c1
PR234_SCOPE=CTA_provenance_document_only

PRE_RESOLUTION_IR_VERSION=4.0.0
PRE_RESOLUTION_CANONICALIZATION_ID=lf-ir-serializer-v1
PRE_RESOLUTION_DIGEST_ALGORITHM=sha-256
PRE_RESOLUTION_DESIGN_DOCUMENT_DIGEST=74cf822d0b0346a5d0526de387d42773b0bcc4a03475ea2dd6f64fe458690d59
PRE_RESOLUTION_CANONICAL_BYTES_LENGTH=412691

RESOLVED_IR_VERSION=4.0.0
RESOLVED_CANONICALIZATION_ID=lf-ir-serializer-v1
RESOLVED_DIGEST_ALGORITHM=sha-256
RESOLVED_DESIGN_DOCUMENT_DIGEST=1fdc6e859bdb624f0931106f78a46b25baae89f807b6bfc7ba3e14ee79da1045
RESOLVED_DESIGN_DOCUMENT_CANONICAL_BYTES_LENGTH=412682
RESOLVED_DESIGN_DOCUMENT_IDENTITY_MATCH=YES
```

The fetched `origin/main` matched the base SHA and tree above. Its CI completed successfully on that SHA. PR #233's accepted head is the second parent of its merge, and its post-merge CI passed on the merge SHA. PR #234 is the intervening CTA provenance document.

## Input identity and replay

```text
PRIVATE_MILAN_PATH=/home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/feature-section-milan/bricks-component-ybsqrl-feature-section-milan.json
PRIVATE_MILAN_SHA256=f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132
PRIVATE_SOURCE_EXECUTED=NO

ACSS_FIXTURE_PATH=/home/jcschoeman96/projects/current/LiveFrame/fixtures/automatic_css/acss_settings.json
ACSS_FIXTURE_SHA256=19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05

BREAKPOINT_AUTHORITY_PATH=sources/work/feature_milan/fidelity/breakpoint_authority.json
BREAKPOINT_AUTHORITY_SHA256=e507d7d6ff33bbb4fb0880d46c44f3b5337d6c95c227154e11510e6a7a2c1b34
AUTHORITY_VALIDATION=PASS
AUTHORITY_STATUS=accepted
AUTHORITY_LEVEL=3
AUTHORITY_TYPE=direct_source_environment_runtime_confirmed
MOBILE_LANDSCAPE_SOURCE_WIDTH=767
MOBILE_LANDSCAPE_MIN_WIDTH=nil
MOBILE_LANDSCAPE_MAX_WIDTH=767
MOBILE_LANDSCAPE_UNIT=px
MOBILE_LANDSCAPE_QUERY=max-width
MOBILE_LANDSCAPE_MEDIA=@media (max-width: 767px)
MOBILE_LANDSCAPE_ENABLED=true
MOBILE_LANDSCAPE_CASCADE_ORDER=3
```

The source JSON was read as data. Its embedded JavaScript and PHP were not executed. The two adapter calls were:

```elixir
LiveFrames.Adapters.AutomaticCSS.from_file(
  acss_path,
  source_version: "4.0.1",
  source_version_status: "fixture_reference",
  strict: true,
  profile: :hero_foundation
)

LiveFrames.Adapters.Bricks.to_ir(
  milan_path,
  component_id: "ybsqrl",
  token_set: token_set
)
```

The pre-resolution document reproduced the accepted digest and byte length. `LiveFrames.Responsive.DesignDocumentResolver.resolve/2` then produced the accepted resolved identity. The resolved document has three responsive overrides, all resolved to `mobile_landscape` with maximum width 767. All four Behavior reference nodes remain present.

## Reissued typed BehaviorContract

Before identity assignment, the typed contract had these top-level values:

```text
behavior_contract_format_version=1.0.0
bindings_count=1
diagnostics=[]
provenance={}

binding_id=nil
ordinal=nil
```

The binding preserves these values:

```text
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

`LiveFrames.Behavior.BindingIdentity.assign/1` assigned ordinal zero and the binding ID. No binding ID or ordinal was supplied manually.

```text
BINDING_ORDINAL=0
BINDING_ID_MANUALLY_ASSIGNED=NO
PRE_RESOLUTION_BINDING_ID=bnd_3ba524068d30cd5d86515658bbbc1152bcebcaf92c521bd5369f6d12ef45061c
PRE_RESOLUTION_BEHAVIOR_CONTRACT_DIGEST=9a8987588431c6455f4017c1bedee3e55f31bd37dd73870f1fd2cfe43d0df57f
PRE_RESOLUTION_BEHAVIOR_CONTRACT_CANONICAL_BYTES_LENGTH=1365
PRE_RESOLUTION_BEHAVIOR_REVIEW_ID=brv_bfe7f43e8cca65805439347ea6460837faf59d17b2a7c874cd1fc1ac4865a0b9

POST_RESOLUTION_BINDING_ID=bnd_fd4b72a566b2c38f00f5396bfc0f2c26453d49a1c19290dfe9dec2a67ee78fe4
POST_RESOLUTION_BEHAVIOR_CONTRACT_DIGEST=5d2b37acbfa357a66357bf7ea09ce21f15353702d85a5d202f275dcb6794a344
POST_RESOLUTION_BEHAVIOR_CONTRACT_CANONICAL_BYTES_LENGTH=1365
BEHAVIOR_CONTRACT_DIGEST_ALGORITHM=lf-behavior-v1-jcs-sha256
```

The accepted pre-resolution binding, contract, and review records remain unchanged and historically valid. They are not reused for the resolved DesignDocument identity.

## Canonical BehaviorContract JSON

`LiveFrames.Behavior.Serializer.encode/1` and `digest/1` produced this canonical JSON:

```json
{"behavior_contract_format_version":"1.0.0","bindings":[{"binding_id":"bnd_fd4b72a566b2c38f00f5396bfc0f2c26453d49a1c19290dfe9dec2a67ee78fe4","binding_role":"primary","controlled_targets":[{"node_id":"node_000001_000001_000001_000002_000001","role":"control_collection"},{"node_id":"node_000001_000001_000001_000002_000001_000002_000001","role":"presentation_collection"},{"node_id":"node_000001_000001_000002_000001","role":"presentation_collection"}],"diagnostics":[],"focus_policy":null,"initial_state":null,"keyboard_policy":null,"motion_policy":null,"ordinal":0,"owner_node_id":"node_000001","primitive_policy_values":{"advance_boundary":"wrap","alignment":"position"},"primitive_ref":{"definition_version":"1.0.0","kind":"selection"},"provenance":{},"responsive_overrides":[],"source_trace":null,"timer_policy":{"interval_ms":5000,"manual_activation":"stop","purpose":"advance_selection","reduced_motion":"disable_automatic_advance","reset":"none","restart":"never","start":"on_initialization"},"triggers":[{"kind":"activate","origin_node_id":"node_000001_000001_000001_000002_000001"},{"kind":"timer","origin_node_id":null}]}],"design_document_identity":{"canonicalization_id":"lf-ir-serializer-v1","digest":"1fdc6e859bdb624f0931106f78a46b25baae89f807b6bfc7ba3e14ee79da1045","digest_algorithm":"sha-256","ir_version":"4.0.0"},"diagnostics":[],"provenance":{}}
```

## Validation and semantic delta

All three validations ran against the resolved DesignDocument. The accepted pre-resolution canonical JSON was compared with the new serializer output after normalizing only `design_document_identity.digest` and `bindings[0].binding_id`.

```text
STRUCTURE_VALIDATION=PASS
SEMANTIC_VALIDATION=PASS
FULL_VALIDATION=PASS
VALIDATION_DIAGNOSTIC_CODES=NONE

DESIGN_DOCUMENT_DIGEST_CHANGED=YES
BINDING_ID_CHANGED=YES

CONTRACT_FORMAT_VERSION_CHANGED=NO
BINDING_ORDINAL_CHANGED=NO
PRIMITIVE_CHANGED=NO
OWNER_CHANGED=NO
BINDING_ROLE_CHANGED=NO
INITIAL_STATE_CHANGED=NO
PRIMITIVE_POLICY_CHANGED=NO
TRIGGERS_CHANGED=NO
CONTROLLED_TARGETS_CHANGED=NO
TIMER_POLICY_CHANGED=NO
FOCUS_POLICY_CHANGED=NO
KEYBOARD_POLICY_CHANGED=NO
MOTION_POLICY_CHANGED=NO
RESPONSIVE_BEHAVIOR_CHANGED=NO
DIAGNOSTICS_CHANGED=NO
PROVENANCE_CHANGED=NO

SEMANTIC_DELTA_ONLY_IDENTITY_FIELDS=YES
```

No Tabs behavior, keyboard navigation, focus movement or trapping, mobile wrapper selection, responsive Behavior override, durable item identity, server-owned selection state, LiveView event, PubSub, GenServer, Redis, polling, timer restart or reset, `word_limit` behavior, custom CSS behavior, or StateRule behavior was added. Reduced motion remains `disable_automatic_advance`; manual interaction remains enabled. Timer semantics remain unchanged.

## Determinism

Two separate `mix run --no-start` processes each reconstructed and resolved the DesignDocument, assigned the binding ID, validated the contract, serialized it, and computed its digest. The canonical files were written under `/tmp` and compared byte-for-byte.

```text
RUN_1_RESOLVED_DESIGN_DIGEST=1fdc6e859bdb624f0931106f78a46b25baae89f807b6bfc7ba3e14ee79da1045
RUN_2_RESOLVED_DESIGN_DIGEST=1fdc6e859bdb624f0931106f78a46b25baae89f807b6bfc7ba3e14ee79da1045

RUN_1_BINDING_ID=bnd_fd4b72a566b2c38f00f5396bfc0f2c26453d49a1c19290dfe9dec2a67ee78fe4
RUN_2_BINDING_ID=bnd_fd4b72a566b2c38f00f5396bfc0f2c26453d49a1c19290dfe9dec2a67ee78fe4

RUN_1_CONTRACT_DIGEST=5d2b37acbfa357a66357bf7ea09ce21f15353702d85a5d202f275dcb6794a344
RUN_2_CONTRACT_DIGEST=5d2b37acbfa357a66357bf7ea09ce21f15353702d85a5d202f275dcb6794a344

RUN_1_CANONICAL_BYTES_LENGTH=1365
RUN_2_CANONICAL_BYTES_LENGTH=1365

RESOLVED_DESIGN_IDENTITIES_IDENTICAL=YES
BINDING_IDS_IDENTICAL=YES
CONTRACT_DIGESTS_IDENTICAL=YES
CANONICAL_BYTES_IDENTICAL=YES
RESOLVED_DESIGN_CANONICAL_BYTES_IDENTICAL=YES
```

## Q13 and downstream boundary

```text
Q12=RESOLVED
Q13_RESOLVED=NO
UNSUPPORTED_NODE_ID=node_000001_000002
UNSUPPORTED_NODE_BLOCKER_CURRENT=YES

POST_RESOLUTION_BEHAVIOR_BINDING_CREATED=YES
POST_RESOLUTION_BEHAVIOR_CONTRACT_CREATED=YES
POST_RESOLUTION_BEHAVIOR_REVIEW_CREATED=NO
NEW_BEHAVIOR_REVIEW_ID=NONE

A1_STARTED=NO
P7_D0_STARTED=NO
COMPONENT_PROPOSER_STARTED=NO
COMPONENT_CONTRACT_CREATED=NO
COMPONENTIZATION_PLAN_CREATED=NO
P7_D1_STARTED=NO
P7_E_STARTED=NO
RUNTIME_STARTED=NO
```

Q13 remains unresolved. This reissue does not waive the unsupported-node blocker. The next gate after independent acceptance is a separate immutable BehaviorReviewResult.

## Performance classification

```text
DATA_LAYER=COLD_COMPILE_REVIEW_TIME
HOT_DATA=N/A
WARM_DATA=N/A

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
```

No runtime infrastructure was added for this identity reissue.
