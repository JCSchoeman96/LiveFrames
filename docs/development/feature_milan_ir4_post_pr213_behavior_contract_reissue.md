# Feature Milan IR4 post-PR213 BehaviorContract reissue

## Status

```text
TERMINAL_STATE=BEHAVIOR_REISSUE_REVIEW_READY
STOP=NONE
N0=ACCEPTED
N1_BEHAVIOR_REISSUE=AUTHORIZED
N2_BEHAVIOR_REVIEW=NOT_AUTHORIZED
BREAKPOINT_AUTHORITY=NOT_AUTHORIZED
A1=NOT_AUTHORIZED
P7_D0=NOT_AUTHORIZED
```

This record reissues the accepted `selection@1.0.0` BehaviorContract for the accepted current DesignDocument identity. The contract preserves the prior behavior fields and changes only its DesignDocument digest and the deterministic binding ID that depends on that identity. It does not create a review result or authorize downstream work.

## Accepted base and CI

```text
BASE_SHA=7e2b1b5bb82f9da8425724a2f68b638883339aa0
BASE_TREE=a95aa627f752bf85bd91303b6a1a50c004606a87
BASE_CI_RUN=38684535929
BASE_CI_HEAD=7e2b1b5bb82f9da8425724a2f68b638883339aa0
BASE_CI_RESULT=success
BASE_CI_URL=https://github.com/JCSchoeman96/LiveFrames/actions/runs/38684535929
BASE_CI_FORMAT=PASS
BASE_CI_WARNINGS_AS_ERRORS_COMPILE=PASS
BASE_CI_ASSETS=PASS
BASE_CI_STYLING_DRIFT=PASS
BASE_CI_TESTS=PASS
BASE_CI_UNUSED_DEPENDENCIES=PASS
BASE_CI_WHITESPACE=PASS

PR216_APPROVED_HEAD=ee342aac945d5fe3638558981e98c857e89ea58d
PR216_MERGE_SHA=7e2b1b5bb82f9da8425724a2f68b638883339aa0
PR216_MERGE_TREE=a95aa627f752bf85bd91303b6a1a50c004606a87
CURRENT_MAIN_SHA=7e2b1b5bb82f9da8425724a2f68b638883339aa0
CURRENT_MAIN_TREE=a95aa627f752bf85bd91303b6a1a50c004606a87

PR215_MILAN_N0_CLASSIFICATION=SAFE
PR215_PRODUCTION_SCOPE=closed StateRuleSet validator; no adapter, serialization, IR schema/version, native generation, or CSS serialization changes
```

`origin/main`, `HEAD`, and their trees matched the accepted values before reconstruction. The base CI run completed with success. This N1 reissue does not modify the normalization record or either historical Behavior record.

## Accepted N0 identity

The accepted normalization identity is recorded in `feature_milan_ir4_post_pr213_normalization_record.md`.

```text
IR_VERSION=4.0.0
CANONICALIZATION_ID=lf-ir-serializer-v1
DIGEST_ALGORITHM=sha-256
DESIGN_DOCUMENT_DIGEST=74cf822d0b0346a5d0526de387d42773b0bcc4a03475ea2dd6f64fe458690d59
DESIGN_DOCUMENT_CANONICAL_BYTES=412691
HISTORICAL_DESIGN_DOCUMENT_DIGEST=52544dcc0d279d91d3d56d054c9785b18f96e77a5520b782726b678c404db864
```

The older digest remains valid for its historical normalization pipeline. It is not used for this reissue.

## Source identities and replay

```text
PRIVATE_MILAN_PATH=/home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/feature-section-milan/bricks-component-ybsqrl-feature-section-milan.json
PRIVATE_MILAN_SHA256=f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132
ACSS_FIXTURE_PATH=/home/jcschoeman96/projects/current/LiveFrame/fixtures/automatic_css/acss_settings.json
ACSS_FIXTURE_SHA256=19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05
PRIVATE_SOURCE_EXECUTED=NO
```

The private Milan export was read as JSON data. Its embedded JavaScript was not executed. The replay passed the file path to the Bricks adapter and used no other Bricks options.

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

```text
SOURCE_ARGUMENT_FORM=file_path
STRUCTURAL_VARIABLE_AUTHORITY_OPTION=omitted
THEME_STYLES_OPTION=omitted
EXTERNAL_CLASS_AUTHORITIES_OPTION=omitted
CONTAINER_WIDTH_OPTION=omitted
EXPECTED_ROOT_COUNT_OPTION=omitted
```

The replay called `LiveFrames.IR.validate/1` and `LiveFrames.IR.Identity.from_document/1`.

```text
DESIGN_DOCUMENT_IR_VERSION=4.0.0
DESIGN_DOCUMENT_CANONICAL_BYTES=412691
DESIGN_DOCUMENT_DIGEST=74cf822d0b0346a5d0526de387d42773b0bcc4a03475ea2dd6f64fe458690d59
DESIGN_DOCUMENT_IDENTITY_MATCH=YES
```

## Historical Behavior authority

The source records `feature_milan_ir4_behavior_contract_reissue.md` and `feature_milan_ir4_behavior_review_result.md` were read and left unchanged. These identities are historical and are not reused for the current DesignDocument identity.

```text
OLD_BINDING_ID=bnd_caf04646aa92bbf2026ec3a2a1298a448ab03c624d27519c0740f874e64d22a7
OLD_BEHAVIOR_CONTRACT_DIGEST=303273984f180ea671ba968c841672603f0a0604368385b8f295e1cfcc64f826
OLD_REVIEW_ID=brv_5159f503fec2bb56c416642e6ea2151c402a2d9a70670d50b9fe153d5dd62e1d
HISTORICAL_ARTIFACTS_CHANGED=NO
```

## Preserved typed contract

The replay constructed one pre-identity `LiveFrames.Behavior.Contract` with one typed binding. `binding_id` and `ordinal` were `nil` before `BindingIdentity.assign/1` ran.

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

This reissue adds no Tabs behavior, keyboard navigation, focus movement, focus trapping, responsive Behavior override, mobile-wrapper selection target, durable item/source/database identity alignment, server-owned selection state, LiveView event, PubSub, GenServer, Redis, polling, timer restart or cleanup rule, accessibility runtime behavior, `word_limit` behavior, custom-CSS behavior, or state-rule behavior. `word_limit(count=16)` remains a DesignDocument value-binding detail. PR #213's base-style extraction does not authorize a BehaviorContract change.

## Derived identities and validation

`LiveFrames.Behavior.BindingIdentity.assign/1` assigned the binding identity. No binding ID or ordinal was manually supplied.

```text
BINDING_ORDINAL=0
BINDING_ID_MANUALLY_ASSIGNED=NO
NEW_BINDING_ID=bnd_3ba524068d30cd5d86515658bbbc1152bcebcaf92c521bd5369f6d12ef45061c
EXPECTED_BINDING_ID=bnd_3ba524068d30cd5d86515658bbbc1152bcebcaf92c521bd5369f6d12ef45061c
EXPECTED_BINDING_ID_MATCH=YES

CONTRACT_FORMAT_VERSION=1.0.0
BINDINGS_COUNT=1
EXPECTED_CANONICAL_BYTES_LENGTH=1365
BEHAVIOR_CONTRACT_CANONICAL_BYTES_LENGTH=1365
BEHAVIOR_CONTRACT_DIGEST_ALGORITHM=lf-behavior-v1-jcs-sha256
BEHAVIOR_CONTRACT_DIGEST=9a8987588431c6455f4017c1bedee3e55f31bd37dd73870f1fd2cfe43d0df57f
EXPECTED_BEHAVIOR_CONTRACT_DIGEST=9a8987588431c6455f4017c1bedee3e55f31bd37dd73870f1fd2cfe43d0df57f
EXPECTED_CONTRACT_DIGEST_MATCH=YES

STRUCTURE_VALIDATION=PASS
SEMANTIC_VALIDATION=PASS
FULL_VALIDATION=PASS
VALIDATION_DIAGNOSTIC_CODES=NONE
```

The validation calls were `LiveFrames.Behavior.Validation.validate_structure/2`, `validate_semantics/2`, and `validate/2` against the reproduced DesignDocument.

## Canonical BehaviorContract JSON

The repository `LiveFrames.Behavior.Serializer.encode/1` and `digest/1` APIs produced this exact canonical JSON:

```json
{"behavior_contract_format_version":"1.0.0","bindings":[{"binding_id":"bnd_3ba524068d30cd5d86515658bbbc1152bcebcaf92c521bd5369f6d12ef45061c","binding_role":"primary","controlled_targets":[{"node_id":"node_000001_000001_000001_000002_000001","role":"control_collection"},{"node_id":"node_000001_000001_000001_000002_000001_000002_000001","role":"presentation_collection"},{"node_id":"node_000001_000001_000002_000001","role":"presentation_collection"}],"diagnostics":[],"focus_policy":null,"initial_state":null,"keyboard_policy":null,"motion_policy":null,"ordinal":0,"owner_node_id":"node_000001","primitive_policy_values":{"advance_boundary":"wrap","alignment":"position"},"primitive_ref":{"definition_version":"1.0.0","kind":"selection"},"provenance":{},"responsive_overrides":[],"source_trace":null,"timer_policy":{"interval_ms":5000,"manual_activation":"stop","purpose":"advance_selection","reduced_motion":"disable_automatic_advance","reset":"none","restart":"never","start":"on_initialization"},"triggers":[{"kind":"activate","origin_node_id":"node_000001_000001_000001_000002_000001"},{"kind":"timer","origin_node_id":null}]}],"design_document_identity":{"canonicalization_id":"lf-ir-serializer-v1","digest":"74cf822d0b0346a5d0526de387d42773b0bcc4a03475ea2dd6f64fe458690d59","digest_algorithm":"sha-256","ir_version":"4.0.0"},"diagnostics":[],"provenance":{}}
```

## Semantic identity-delta proof

The new serialized contract was compared with the accepted pre-PR213 IR4 canonical contract. The comparison normalized only `design_document_identity.digest` and `bindings[0].binding_id` to their historical values. Every other serialized field matched.

```text
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

## Determinism proof

Two separate clean `mix run --no-start` processes each reproduced the DesignDocument, derived its identity, constructed the typed contract, assigned its binding identity, ran all three Behavior validations, serialized the contract, and calculated its digest. The canonical DesignDocument and BehaviorContract bytes were compared byte-for-byte from temporary files under `/tmp`; those files are not committed.

```text
RUN_1_DESIGN_DIGEST=74cf822d0b0346a5d0526de387d42773b0bcc4a03475ea2dd6f64fe458690d59
RUN_2_DESIGN_DIGEST=74cf822d0b0346a5d0526de387d42773b0bcc4a03475ea2dd6f64fe458690d59

RUN_1_BINDING_ID=bnd_3ba524068d30cd5d86515658bbbc1152bcebcaf92c521bd5369f6d12ef45061c
RUN_2_BINDING_ID=bnd_3ba524068d30cd5d86515658bbbc1152bcebcaf92c521bd5369f6d12ef45061c
RUN_1_STRUCTURE_VALIDATION=PASS
RUN_2_STRUCTURE_VALIDATION=PASS
RUN_1_SEMANTIC_VALIDATION=PASS
RUN_2_SEMANTIC_VALIDATION=PASS
RUN_1_FULL_VALIDATION=PASS
RUN_2_FULL_VALIDATION=PASS
RUN_1_CANONICAL_BYTES_LENGTH=1365
RUN_2_CANONICAL_BYTES_LENGTH=1365
BINDING_IDS_IDENTICAL=YES

RUN_1_CONTRACT_DIGEST=9a8987588431c6455f4017c1bedee3e55f31bd37dd73870f1fd2cfe43d0df57f
RUN_2_CONTRACT_DIGEST=9a8987588431c6455f4017c1bedee3e55f31bd37dd73870f1fd2cfe43d0df57f
CONTRACT_DIGESTS_IDENTICAL=YES

CANONICAL_DESIGN_BYTES_IDENTICAL=YES
CANONICAL_BYTES_IDENTICAL=YES
```

## Artifact lifecycle and N2 boundary

```text
LIFECYCLE=unstarted
  → base_authority_verified
  → design_document_reproduced
  → semantic_contract_reconstructed
  → binding_identity_assigned
  → structure_validated
  → semantics_validated
  → full_validation_passed
  → canonical_contract_frozen
  → behavior_reissue_review_ready

BEHAVIOR_BINDING_REISSUED=YES
BEHAVIOR_CONTRACT_REISSUED=YES
CONTRACT_CANDIDATE_FROZEN=YES
OWNER_APPROVAL_RECORDED=NO
NEW_BEHAVIOR_REVIEW_RESULT_CREATED=NO
NEW_BEHAVIOR_REVIEW_ID=NONE
```

The binding assignment required `binding_id=nil` and `ordinal=nil`. The frozen contract required all three validations to pass and both reconstruction runs to produce identical identities and canonical bytes. Review readiness required the semantic delta proof above. This record stops before owner review and before N2.

## Downstream gates

```text
COMPONENTIZATION_A0_REFRESH_STARTED=NO
BREAKPOINT_EVIDENCE_RECOVERY_STARTED=NO
BREAKPOINT_AUTHORITY_CREATED=NO
DESIGN_DOCUMENT_RESOLVED=NO
A1_SEMANTIC_INPUT_FROZEN=NO
REAL_MILAN_D0_EXECUTED=NO
COMPONENT_PROPOSER_EXECUTED=NO
COMPONENT_REVIEW_EXECUTED=NO
P7_D1_STARTED=NO
P7_E_STARTED=NO
RUNTIME_STARTED=NO
```

## Performance classification

This is compile and review-time identity work.

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
TTL=N/A
DB_INDEX=N/A
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
```

## Scope and next gate

```text
CHANGED_FILES=docs/development/feature_milan_ir4_post_pr213_behavior_contract_reissue.md
PRODUCTION_CODE_CHANGED=NO
TEST_CODE_CHANGED=NO
PRIVATE_SOURCE_COMMITTED=NO
GENERATED_CANONICAL_ARTIFACT_COMMITTED=NO
HISTORICAL_ARTIFACTS_CHANGED=NO
```

The next required gate is owner review of this exact reissued BehaviorContract candidate. If accepted, N2 may issue one new immutable `BehaviorReviewResult` tied to the current DesignDocument digest and this contract digest.
