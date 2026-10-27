# Feature Milan IR6 BehaviorContract reissue candidate

## Lifecycle and authority

This document proposes a Feature Milan BehaviorContract for review against the exact IR6 DesignDocument below. It does not approve the contract or authorize downstream work. The contract must be merged and accepted before a separate review candidate is derived.

```text
LIFECYCLE=ir6_behavior_reissue_review_ready
TERMINAL_STATE=IR6_BEHAVIOR_REISSUE_REVIEW_READY
IR6_BEHAVIOR_CONTRACT_AUTHORITY_CREATED=YES
IR6_BEHAVIOR_REVIEW_CREATED=NO
IR6_BEHAVIOR_REVIEW_ID=NONE
IR6_BEHAVIOR_REVIEW_AUTHORIZED=NO
TASK10_IR6_TRANSITION_AUTHORIZED=NO
T6B_REBASE_AUTHORIZED=NO
PR342_MERGE_AUTHORIZED=NO
```

The governing IR6 identity compatibility authority is [C09C6B](c09c6b_behavior_identity_ir6_compatibility_authority.md). Operative current Milan behavior evidence is `BEH-P007` in [the interaction model](../09_INTERACTION_MODEL.md) and the [timed selection preflight](feature_milan_timed_selection_mapping_preflight.md). Historical continuity evidence is the accepted [IR5 BehaviorContract](feature_milan_ir5_behavior_contract_reissue.md) and [IR5 BehaviorReviewResult](feature_milan_ir5_behavior_review_result.md) authorities; those frozen artifacts demonstrate continuity for the exact IR5 document only and are not operative evidence for the current IR6 document. This candidate is a new exact-document BehaviorContract with unchanged Selection semantics against the IR6 DesignDocument identity below; it does not migrate or rewrite historical Behavior artifacts.

## Base and source identities

```text
BASE_SHA=585621a865434d927f0f13c078302d478e027d39
BASE_TREE=46518615bcd6d1c0ac48236e21ded287999c585c
BASE_CI_RUN=40495420797
BASE_CI_RESULT=SUCCESS
PRIVATE_SOURCE=private_reference/frames/staging-2026-09/feature-section-milan/bricks-component-ybsqrl-feature-section-milan.json
PRIVATE_SOURCE_SHA256=f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132
PRIVATE_SOURCE_BYTES=17017
ACSS_SOURCE=fixtures/automatic_css/acss_settings.json
ACSS_SHA256=19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05
BREAKPOINT_AUTHORITY=sources/work/feature_milan/fidelity/breakpoint_authority.json
BREAKPOINT_AUTHORITY_SHA256=e507d7d6ff33bbb4fb0880d46c44f3b5337d6c95c227154e11510e6a7a2c1b34
```

The source export and ACSS fixture were read as data. No proprietary or source runtime was executed, and no source JavaScript was reinterpreted. The accepted preflight distinguishes observed positional synchronization and timer behavior from target policy. Actual rendered cardinality equality and durable cross-collection identity are not established.

## Current IR6 DesignDocument

Two separate BEAM processes loaded the ACSS fixture using `source_version: "4.0.1"`, `source_version_status: "fixture_reference"`, `strict: true`, and `profile: :hero_foundation`; normalized component `ybsqrl` with the resulting token set; loaded the breakpoint authority using `BreakpointAuthority.from_file/1`; resolved the document with `DesignDocumentResolver.resolve/2`; validated it; and encoded it with the current IR serializer. Both canonical byte sequences matched.

```text
IR6_IR_VERSION=6.0.0
IR6_DESIGN_DOCUMENT_SHA256=d4b945741cb088ff7c739224f5cddc9904f3655741f74fa4bf17318cf3242ca9
IR6_DESIGN_DOCUMENT_BYTES=412682
IR6_NODE_COUNT=17
CANONICALIZATION_ID=lf-ir-serializer-v1
DIGEST_ALGORITHM=sha-256
```

## Historical IR5 continuity

```text
IR5_DESIGN_DOCUMENT_SHA256=9ae73053d9224bebcb71833b77094a17c3ef7c3a25f0b5b1c4dbad5aaf9d2229
IR5_BEHAVIOR_BINDING_ID=bnd_abf701b79aba7597825525c7ddf5065e89a2fdcfb378797f63e3d9fb74ff8ee2
IR5_BEHAVIOR_CONTRACT_DIGEST=1e0095418d96f392594a155d9c6ea9610b6b5f4d62c6d0205df66dedea57506a
IR5_BEHAVIOR_REVIEW_ID=brv_b4bc3ab7f4284cf20ae6f0aaf73da3fd2c242e42d18f1ab049acc6f1e62e9c11
IR5_HISTORICAL_BYTES_UNCHANGED=YES
IR5_BEHAVIOR_BYTES_IMMUTABLE=YES
IR5_BEHAVIOR_ARTIFACTS=HISTORICAL_EXACT_IR5_EVIDENCE
IR5_CONTRACT_STANDALONE_VALID=YES
IR5_CONTRACT_ATTACHES_TO_IR6=NO
IR5_TO_IR6_ATTACHMENT_DIAGNOSTIC=behavior.design_document.identity_mismatch
IR6_DOCUMENT_IDENTITY=d4b945741cb088ff7c739224f5cddc9904f3655741f74fa4bf17318cf3242ca9
```

The historical typed IR5 BehaviorContract encoded to the existing canonical bytes and digest and passed standalone semantic validation. Production validation rejected attachment to the current IR6 document with `behavior.design_document.identity_mismatch`. IR5 BehaviorContract and IR5 BehaviorReviewResult artifacts remain historical exact-IR5 evidence only; they are not operative current-document evidence for IR6.

## Source evidence classification

```text
OPERATIVE_BEHAVIOR_EVIDENCE:
  BEH-P007
  docs/development/feature_milan_timed_selection_mapping_preflight.md

IR6_IDENTITY_COMPATIBILITY_AUTHORITY:
  docs/development/c09c6b_behavior_identity_ir6_compatibility_authority.md

HISTORICAL_CONTINUITY_EVIDENCE:
  docs/development/feature_milan_ir5_behavior_contract_reissue.md
  docs/development/feature_milan_ir5_behavior_review_result.md

SUPERSEDED_CONTEXT:
  BEH-P006
```

`BEH-P007` records the operative Milan v1 evidence for positional synchronization, ordered wrap, the 5,000 ms timer, and stopping on manual activation. The timed-selection mapping preflight limits the mapping to Selection and the exact seven-key TimerPolicy. C09C6B supplies the closed IR6 compatibility set and requires exact DesignDocument identity matching for attachment.

Historical IR5 BehaviorContract and BehaviorReviewResult records remain immutable canonical bytes for their exact IR5 document. They may demonstrate semantic continuity only; they are not valid attachment authority for the current IR6 document. `BEH-P006` remains superseded context for Milan v1 under `BEH-P007`; it is not claimed as independently operative current evidence. Do not infer new semantics from historical contracts.

## IR6 typed contract and derived identity

The contract has format version `1.0.0`, one primary `selection@1.0.0` binding, owner `node_000001`, nil initial state, and positional alignment with wrap. Its activate trigger and control collection point to `node_000001_000001_000001_000002_000001`; its timer trigger has no origin. Presentation targets are `node_000001_000001_000001_000002_000001_000002_000001` and `node_000001_000001_000002_000001`. The timer advances every 5000 ms, starts on initialization, stops on manual activation, never restarts, does not reset, and disables automatic advance under reduced motion. Focus, keyboard, motion and source trace are nil; responsive overrides and diagnostics are empty, and provenance is empty.

Before calling `BindingIdentity.assign/1`, the candidate binding ID and ordinal were nil. The production serializer derived the canonical contract bytes and digest.

```text
PRE_ASSIGNMENT_BINDING_ID=nil
PRE_ASSIGNMENT_BINDING_ORDINAL=nil
IR6_BEHAVIOR_BINDING_ID=bnd_38bcdc5dd2a7d55e0274ba1435a2e775cac877b3f28c7377a30140c67f4e59e1
IR6_BEHAVIOR_CONTRACT_DIGEST=610029d848ec480d7cadeba7267b0cbd91607ea6246685212fa4aaa7971f51c6
IR6_BEHAVIOR_CONTRACT_DIGEST_ALGORITHM=lf-behavior-v1-jcs-sha256
IR6_BEHAVIOR_CONTRACT_CANONICAL_BYTES_LENGTH=1365
```

The exact canonical JSON follows. The code block's terminating newline is not part of the 1365 canonical bytes.

```json
{"behavior_contract_format_version":"1.0.0","bindings":[{"binding_id":"bnd_38bcdc5dd2a7d55e0274ba1435a2e775cac877b3f28c7377a30140c67f4e59e1","binding_role":"primary","controlled_targets":[{"node_id":"node_000001_000001_000001_000002_000001","role":"control_collection"},{"node_id":"node_000001_000001_000001_000002_000001_000002_000001","role":"presentation_collection"},{"node_id":"node_000001_000001_000002_000001","role":"presentation_collection"}],"diagnostics":[],"focus_policy":null,"initial_state":null,"keyboard_policy":null,"motion_policy":null,"ordinal":0,"owner_node_id":"node_000001","primitive_policy_values":{"advance_boundary":"wrap","alignment":"position"},"primitive_ref":{"definition_version":"1.0.0","kind":"selection"},"provenance":{},"responsive_overrides":[],"source_trace":null,"timer_policy":{"interval_ms":5000,"manual_activation":"stop","purpose":"advance_selection","reduced_motion":"disable_automatic_advance","reset":"none","restart":"never","start":"on_initialization"},"triggers":[{"kind":"activate","origin_node_id":"node_000001_000001_000001_000002_000001"},{"kind":"timer","origin_node_id":null}]}],"design_document_identity":{"canonicalization_id":"lf-ir-serializer-v1","digest":"d4b945741cb088ff7c739224f5cddc9904f3655741f74fa4bf17318cf3242ca9","digest_algorithm":"sha-256","ir_version":"6.0.0"},"diagnostics":[],"provenance":{}}
```

## Contract comparison and validation

A recursive comparison of every field in the normalized serialized typed contracts found exactly these differences:

```text
EXPECTED_IDENTITY_DIFFERENCE_PATHS=design_document_identity.digest,design_document_identity.ir_version
EXPECTED_DERIVED_ID_DIFFERENCE_PATHS=bindings[0].binding_id
UNEXPECTED_SEMANTIC_DIFFERENCE_PATHS=NONE
UNEXPECTED_SEMANTIC_DIFFERENCE_COUNT=0
SEMANTIC_DELTA_ONLY_IDENTITY_DERIVED_FIELDS=YES
BEHAVIOR_CONTRACT_FORMAT_VERSION_CHANGED=NO
BINDING_ORDINAL_CHANGED=NO
PRIMITIVE_REF_CHANGED=NO
OWNER_NODE_ID_CHANGED=NO
BINDING_ROLE_CHANGED=NO
INITIAL_STATE_CHANGED=NO
PRIMITIVE_POLICY_CHANGED=NO
TRIGGERS_CHANGED=NO
CONTROLLED_TARGETS_CHANGED=NO
TIMER_POLICY_CHANGED=NO
FOCUS_POLICY_CHANGED=NO
KEYBOARD_POLICY_CHANGED=NO
MOTION_POLICY_CHANGED=NO
RESPONSIVE_OVERRIDES_CHANGED=NO
DIAGNOSTICS_CHANGED=NO
PROVENANCE_CHANGED=NO
SOURCE_TRACE_CHANGED=NO
```

The contract digest changes because the canonical contract bytes change. The two independent runs produced matching binding IDs, digests, and canonical bytes. Production structure, semantics, and complete validation passed against the exact IR6 document. An otherwise valid document with altered provenance was rejected with `behavior.design_document.identity_mismatch`.

```text
IR6_BINDING_ID_DETERMINISTIC=YES
IR6_CONTRACT_DIGEST_DETERMINISTIC=YES
IR6_CONTRACT_BYTES_DETERMINISTIC=YES
IR6_CONTRACT_STRUCTURE_VALID=YES
IR6_CONTRACT_SEMANTIC_VALID=YES
IR6_CONTRACT_CURRENT_DOCUMENT_VALID=YES
IR6_VALIDATION_DIAGNOSTIC_CODES=NONE
IR6_MISMATCHED_DOCUMENT_REJECTED=YES
```

## Boundaries and performance

This candidate adds no Tabs semantics, keyboard navigation, focus movement or trapping, server state, LiveView events, or runtime changes. It creates no BehaviorReviewResult, Task 10 transition authority, component review, or T6B change. This is cold local artifact construction, with no runtime network or database calls and no change to runtime architecture.

```text
DATA_LAYER=COLD_LOCAL_ARTIFACT
NETWORK_CALLS_RUNTIME=0
DB_CALLS=0
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
