# C09D7-A3: CTA Tango component review

## Objective and non-goals

This record documents the review and the owner-authorized approval transition for the accepted CTA Tango A2 `ComponentContract`, `ComponentizationPlan`, and `DesignDocument` tuple. The transition changes only `ComponentContract.approval_status` from `proposed` to `approved`.

A3 does not call `ComponentReview.reject/3`, run `NativeGenerator`, generate HEEx or CSS, resolve the known B risks, start C09D7-B, or authorize C09D7-C. No production or test file changed.

## Owner authority and historical A3 preflight base

```text
C09D7_A0=ACCEPTED
C09D7_A1=ACCEPTED
C09D7_A2=ACCEPTED
C09D7_A3=AUTHORIZED
C09D7_B=NOT_AUTHORIZED
C09D7_C=NOT_AUTHORIZED

A3_PREFLIGHT_BASE_SHA=5ea3b0b597eaeebec5524998db93a29e5f7225e8
A3_PREFLIGHT_BASE_TREE=4a4edf77a826db6840407626155cd68bce39149d
A3_PREFLIGHT_BASE_SIGNATURE=VALID
A3_PREFLIGHT_BASE_CI=38044213077
A3_PREFLIGHT_BASE_CI_STATUS=completed
A3_PREFLIGHT_BASE_CI_CONCLUSION=success
```

For the original A3 review preflight, the exact `origin/main` SHA and tree matched that supplied historical base before its cleanroom was created. CI run 38044213077 completed successfully on that base. The owner-authorized approval continuation ran later on the PR #182 merge base recorded in the Owner approval transition section.

## Accepted A2 candidate identity

The accepted candidate is `section_media_call_to_action`. Its Contract and Plan both use format version `1.0.0`. The Contract status is `proposed`.

```text
CONTRACT_ID=section_media_call_to_action
CONTRACT_FORMAT_VERSION=1.0.0
CONTRACT_APPROVAL_STATUS=proposed
PLAN_FORMAT_VERSION=1.0.0
PLAN_CONTRACT_ID=section_media_call_to_action

DESIGN_DOCUMENT_SHA256=4b90b3ce32f8fcec640cea40499e861951137e3c2466931ead3c4436e2c6c9c5
COMPONENT_CONTRACT_SHA256=cc62191c5f154e20a9abb9091693b56b59d4595662adabfbb82334babf8caf9c
COMPONENTIZATION_PLAN_SHA256=19d3a3cc31919239b4cb05e7b3ab37e06820bc514d17ee6edc27dea4a2719c8f

PUBLIC_ATTR_COUNT=11
PUBLIC_SLOT_COUNT=2
COLLECTION_INPUT_COUNT=0
BINDING_PROJECTION_COUNT=0
RENDER_PROJECTION_COUNT=13
CONTRACT_DIAGNOSTICS=[]
PLAN_DIAGNOSTICS=[]
```

PR #177 records the owner-reviewed A2 proposer candidate that was subsequently accepted by the owner. Merged PR #178 records corroborating A2 evidence for the same candidate. Its Contract and Plan hashes match the accepted #177 candidate, so it does not introduce a competing candidate or supersede the #177 owner acceptance. The `A2_ACCEPTED=NO` and `A3_AUTHORIZED=NO` values in PR #178 describe the historical state when that record was written. Current authority is recorded at the top of this section.

## DesignDocument recovery

The private artifact was read as JSON data from the existing local reference directory. No source code was executed and no private content was added to this repository.

```text
PRIVATE_ARTIFACT=private_reference/frames/staging-2026-09/cta-section-tango/bricks-component-hxambs-cta-section-tango.json
PRIVATE_ARTIFACT_SHA256=73f866a27070c010584babe230b5ffd0c78dc704388fd8b6c286e149a3d93a87
PRIVATE_ARTIFACT_BYTES=10224
SOURCE_COMPONENT_ID=hxambs

CANONICAL_SOURCE_BOUNDARY=fragment-map
FRAGMENT_MAP_FIELDS=components,globalClasses
SOURCE_LABEL=inline
ACSS_SOURCE_VERSION=4.0.1
ACSS_SOURCE_VERSION_STATUS=fixture_reference
ACSS_PROFILE=hero_foundation
STRUCTURAL_VARIABLE_AUTHORITY=4.0.1,grid_variables_enabled

DESIGN_DOCUMENT_REPRODUCTION=PASS
DESIGN_DOCUMENT_SHA256=4b90b3ce32f8fcec640cea40499e861951137e3c2466931ead3c4436e2c6c9c5
IR_VALIDATION=PASS
```

The source identity matched the accepted A0 record. The fragment map contained only `components` and `globalClasses`. The accepted fixture and 4.0.1 structural-variable authority produced the accepted DesignDocument digest. The fixture loader reported informational or warning diagnostics for fixture values; these did not change the normalized document identity or candidate diagnostics.

## Accepted candidate recovery and byte proof

The accepted A1 decisions were reconstructed in memory from `c09d7a_cta_tango_semantic_input_freeze.md`. The existing `ComponentizationProposer.propose/2` call was used only to recover the candidate structs needed by the review API. The recovered Contract and Plan were encoded with their existing encoders and hashed before any review validation.

```text
RECOVERY_PROPOSER_OUTCOME=proposed
RECOVERY_CONTRACT_STATUS=proposed
RECOVERY_CONTRACT_DIAGNOSTICS=[]
RECOVERY_PLAN_DIAGNOSTICS=[]

ACCEPTED_COMPONENT_CONTRACT_SHA256=cc62191c5f154e20a9abb9091693b56b59d4595662adabfbb82334babf8caf9c
RECOVERED_COMPONENT_CONTRACT_SHA256=cc62191c5f154e20a9abb9091693b56b59d4595662adabfbb82334babf8caf9c

ACCEPTED_COMPONENTIZATION_PLAN_SHA256=19d3a3cc31919239b4cb05e7b3ab37e06820bc514d17ee6edc27dea4a2719c8f
RECOVERED_COMPONENTIZATION_PLAN_SHA256=19d3a3cc31919239b4cb05e7b3ab37e06820bc514d17ee6edc27dea4a2719c8f

A2_CANDIDATE_IDENTITY_MATCH=YES
```

The proposal call returned `:proposed`, and both serialized hashes matched the owner-accepted A2 identities. No decoder was added. The candidate was not mutated.

## Structural and reference validation

The probe asserted each required check against the recovered tuple before calling the shared generation-prerequisite validator.

```text
IR_VALIDATION=PASS
CONTRACT_INTRINSIC_VALIDATION=PASS
CONTRACT_IR_REFERENCE_VALIDATION=PASS
PLAN_INTRINSIC_VALIDATION=PASS
PLAN_REFERENCE_VALIDATION=PASS

PLAN_CONTRACT_ID_MATCH=YES
PLAN_DESIGN_DOCUMENT_SHA256_MATCH=YES
```

## Shared generation-prerequisite result

The review used only `LiveFrames.ComponentReview.validate_generation_prerequisites/3` for the shared prerequisite boundary.

```elixir
LiveFrames.ComponentReview.validate_generation_prerequisites(
  contract,
  plan,
  design_document
)
# => :ok
```

```text
GENERATION_PREREQUISITES=PASS
GENERATION_PREREQUISITE_DIAGNOSTICS=[]
```

The validator returned `:ok`; it returned no diagnostics. Under the accepted review authority, the Contract status is `proposed` and the shared non-status generation prerequisites pass. This establishes eligibility for a human decision. It does not perform that decision.

## Reviewer judgment

Each check below was evaluated against the recovered, hash-matched candidate and the accepted A1 decisions.

| Check | Result | Basis |
| --- | --- | --- |
| `CANDIDATE_STATUS_IS_PROPOSED` | YES | Recovered Contract status is `proposed`. |
| `PUBLIC_API_SOURCE_INDEPENDENT` | YES | Exact accepted A1 names and semantics; empty Contract and member provenance. |
| `PUBLIC_API_MATCHES_ACCEPTED_A1` | YES | Recovered Contract hash matches A2; all 11 attrs and 2 slots match the frozen decisions. |
| `PLAN_MATCHES_ACCEPTED_A1` | YES | Recovered Plan hash matches A2; all 13 projections match the frozen placements. |
| `NO_BRICKS_PUBLIC_API` | YES | No Bricks-named API member or source field. |
| `NO_FRAMES_PUBLIC_API` | YES | No Frames-named API member or source field. |
| `NO_ACSS_PUBLIC_API` | YES | No Automatic.css-named API member or source field. |
| `NO_SOURCE_IDS_IN_PUBLIC_API` | YES | No source IDs appear in public names or provenance. |
| `NO_SOURCE_CLASSES_IN_PUBLIC_API` | YES | No source classes appear in public names or provenance. |
| `NO_EDITOR_LABELS_IN_PUBLIC_API` | YES | No editor labels appear in public names or provenance. |
| `NO_NAVIGATION_SEMANTICS_INVENTED` | YES | `primary_action` remains caller-owned markup with caller-owned destination and navigation. |
| `NO_BEHAVIOR_SEMANTICS_INVENTED` | YES | No event, button behavior, or interaction input was added. |
| `NO_QUERY_RUNTIME_INVENTED` | YES | There are no collection inputs, binding projections, or IR bindings. |
| `PRIMARY_ACTION_REMAINS_CALLER_OWNED_SLOT` | YES | The required `primary_action` slot remains a `subtree_slot`. |
| `IMAGE_ALT_POLICY_REMAINS_CONSUMER_SUPPLIED` | YES | Each image source retains its matching consumer-supplied alt attr policy. |
| `NO_ERROR_CONTRACT_DIAGNOSTICS` | YES | Contract diagnostics are empty. |
| `NO_FATAL_CONTRACT_DIAGNOSTICS` | YES | Contract diagnostics are empty. |
| `NO_ERROR_PLAN_DIAGNOSTICS` | YES | Plan diagnostics are empty. |
| `NO_FATAL_PLAN_DIAGNOSTICS` | YES | Plan diagnostics are empty. |

No semantic decision was added during this review.

## Known B risks

The accepted A1 risks remain open. The shared prerequisite validator passed, so neither risk blocks the A3 review recommendation under the accepted authority. A3 does not resolve or reinterpret either risk.

```text
B_RISK_01=primary_action subtree-slot presentation/style ownership
B_RISK_02=image/figure native style locus

B_RISK_01_RESOLVED_BY_A3=NO
B_RISK_02_RESOLVED_BY_A3=NO
```

Both remain for downstream C09D7-B review. C09D7-B remains unauthorized.

## Performance and scaling

A3 is a cold build-time recovery and review. It adds no runtime data layer or service calls.

```text
DATA_LAYER=COLD_BUILD_TIME
HOT_DATA=N/A
WARM_DATA=N/A
REDIS=N/A
POSTGRES=N/A
ETS=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
CACHE_TTL=N/A

RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
RUNTIME_POLLING=0
100K_RUNTIME_CONCURRENCY=N/A
```

## Lifecycle

```text
A3_AUTHORIZED
-> review_preflight
-> recommendation_approve
-> human_decision_pending
-> human_approval_granted
-> ComponentReview.approve/3
-> contract_approved
-> approved_contract_identity_frozen
-> A3_APPROVAL_TRANSITION_REVIEW_READY
```

## Recommendation and human decision boundary

```text
REVIEW_RECOMMENDATION=APPROVE
REVIEW_RECOMMENDATION_PHASE=historical_pre_transition_evidence
HUMAN_APPROVAL_REQUIRED=YES
HUMAN_REVIEW_DECISION=APPROVE
COMPONENT_REVIEW_APPROVE_EXECUTED=YES
COMPONENT_REVIEW_REJECT_EXECUTED=NO
CONTRACT_APPROVAL_STATUS_BEFORE_REVIEW=proposed
CONTRACT_APPROVAL_STATUS_AFTER_A3_APPROVAL=approved
A3_HUMAN_DECISION_PENDING=NO
OWNER_REVIEW_DECISION=APPROVE
C09D7_A3_APPROVAL_TRANSITION=AUTHORIZED
C09D7_B=NOT_AUTHORIZED
C09D7_C=NOT_AUTHORIZED

NATIVE_GENERATION_EXECUTED=NO
HEEX_GENERATION_EXECUTED=NO
CSS_GENERATION_EXECUTED=NO
C09D7_B_STARTED=NO
C09D7_C_STARTED=NO
```

C09D6-A §6.5 permits a reviewer to approve a `proposed` candidate when the shared generation prerequisites return `:ok`. The pre-transition recommendation above remains historical evidence. The owner decision and the single authorized transition are recorded below.

## Owner approval transition

The owner approved the review recommendation and authorized this continuation. The transition used the recovered A2 tuple, rechecked the shared prerequisites, and called `LiveFrames.ComponentReview.approve/3` once. No candidate semantic field or downstream authority was changed.

```text
OWNER_REVIEW_DECISION=APPROVE
COMPONENT_CONTRACT_APPROVAL_TRANSITION=AUTHORIZED
C09D7_A3_APPROVAL_TRANSITION=AUTHORIZED
A3_APPROVAL_TRANSITION_EXECUTED=YES
C09D7_B=NOT_AUTHORIZED
C09D7_C=NOT_AUTHORIZED

EXECUTION_BASE_SHA=341807144ba5c7e5e75a9f5c5cc301d6675c708c
EXECUTION_BASE_TREE=a6f9ae2aa81abbb5c735cdd576a7c5e8607005f6
BASE_MERGE_SIGNATURE=VALID
PR_182=MERGED
PR_182_APPROVED_HEAD=d1f26154c4c2d40c72b1ebff60a4bbc0f435947d
PR_182_MERGE_SHA=341807144ba5c7e5e75a9f5c5cc301d6675c708c
PR_182_MERGE_TREE=a6f9ae2aa81abbb5c735cdd576a7c5e8607005f6
PR_182_POST_MERGE_CI=38045951757
PR_182_POST_MERGE_CI_STATUS=completed
PR_182_POST_MERGE_CI_CONCLUSION=success

PRIVATE_ARTIFACT_SHA256=73f866a27070c010584babe230b5ffd0c78dc704388fd8b6c286e149a3d93a87
PRIVATE_ARTIFACT_BYTES=10224
SOURCE_COMPONENT_ID=hxambs
DESIGN_DOCUMENT_SHA256=4b90b3ce32f8fcec640cea40499e861951137e3c2466931ead3c4436e2c6c9c5

RECOVERY_PROPOSER_OUTCOME=proposed
RECOVERED_PROPOSED_CONTRACT_SHA256=cc62191c5f154e20a9abb9091693b56b59d4595662adabfbb82334babf8caf9c
RECOVERED_CONTRACT_STATUS=proposed
RECOVERED_PLAN_SHA256=19d3a3cc31919239b4cb05e7b3ab37e06820bc514d17ee6edc27dea4a2719c8f

CONTRACT_ID=section_media_call_to_action
PUBLIC_ATTR_COUNT=11
PUBLIC_SLOT_COUNT=2
COLLECTION_INPUT_COUNT=0
BINDING_PROJECTION_COUNT=0
RENDER_PROJECTION_COUNT=13
CONTRACT_DIAGNOSTICS=[]
PLAN_DIAGNOSTICS=[]

PROPOSED_COMPONENT_CONTRACT_SHA256=cc62191c5f154e20a9abb9091693b56b59d4595662adabfbb82334babf8caf9c
PROPOSED_CONTRACT_APPROVAL_STATUS=proposed
COMPONENTIZATION_PLAN_SHA256=19d3a3cc31919239b4cb05e7b3ab37e06820bc514d17ee6edc27dea4a2719c8f
PRE_APPROVAL_GENERATION_PREREQUISITES=PASS
PRE_APPROVAL_DIAGNOSTICS=[]
COMPONENT_REVIEW_APPROVE_RESULT={:ok, approved_contract}
COMPONENT_REVIEW_APPROVE_EXECUTION_COUNT=1
APPROVED_CONTRACT_APPROVAL_STATUS=approved
CONTRACT_NON_STATUS_FIELDS_UNCHANGED=YES
PLAN_UNCHANGED=YES
DESIGN_DOCUMENT_UNCHANGED=YES
APPROVED_COMPONENT_CONTRACT_SHA256=8cb4a8361711f31b7ad428fbd8e8198ef91ed96396bed69c137daa471083856a
APPROVED_COMPONENT_CONTRACT_BYTES=2970
APPROVED_CONTRACT_SERIALIZATION_DETERMINISTIC=YES

APPROVAL_SIDE_EFFECTS=returned approved ComponentContract struct only
FILESYSTEM_WRITE_BY_COMPONENT_REVIEW=NO
DATABASE_WRITE=NO
REDIS_WRITE=NO
PUBSUB_BROADCAST=NO
GENSERVER_WRITE=NO
NETWORK_CALL=NO

B_RISK_01=primary_action subtree-slot presentation/style ownership
B_RISK_02=image/figure native style locus
B_RISK_01_RESOLVED_BY_A3_APPROVAL=NO
B_RISK_02_RESOLVED_BY_A3_APPROVAL=NO

DATA_LAYER=COLD_BUILD_TIME
HOT_DATA=N/A
WARM_DATA=N/A
REDIS=N/A
POSTGRES=N/A
ETS=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
CACHE_TTL=N/A
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
RUNTIME_POLLING=0
100K_RUNTIME_CONCURRENCY=N/A

NATIVE_GENERATOR_EXECUTED=NO
HEEX_GENERATION_EXECUTED=NO
CSS_GENERATION_EXECUTED=NO
BROWSER_VERIFICATION_EXECUTED=NO
CATALOGUE_ADMISSION_AUTHORIZED=NO
C09D7_B_STARTED=NO
C09D7_C_STARTED=NO
A3_APPROVAL_TRANSITION_REVIEW_READY=YES
```

`ComponentReview.approve/3` returned the approved Contract struct. A term comparison after removing `approval_status` found the other Contract fields unchanged: `contract_format_version`, `contract_id`, `category`, `module_intent`, `function_intent`, `public_attrs`, `public_slots`, `collection_inputs`, `binding_projections`, `diagnostics`, and `provenance`. The original Plan and DesignDocument terms also remained equal to their pre-call values. The existing review function performed no persistence, messaging, network, or filesystem write.

The approved Contract's exact canonical JSON is:

```json
{"approval_status":"approved","binding_projections":[],"category":"section","collection_inputs":[],"contract_format_version":"1.0.0","contract_id":"section_media_call_to_action","diagnostics":[],"function_intent":"media_call_to_action","module_intent":"media_call_to_action","provenance":{},"public_attrs":[{"accessibility":{},"default":null,"name":"class","provenance":{},"required":false,"semantic_purpose":"additive root CSS class","type":"string","validation":{}},{"accessibility":{},"default":null,"name":"eyebrow","provenance":{},"required":false,"semantic_purpose":"eyebrow text","type":"string","validation":{}},{"accessibility":{},"default":null,"name":"heading","provenance":{},"required":true,"semantic_purpose":"primary heading text","type":"string","validation":{}},{"accessibility":{},"default":2,"name":"heading_level","provenance":{},"required":false,"semantic_purpose":"heading semantic level","type":"integer","validation":{"values":[1,2,3,4,5,6]}},{"accessibility":{},"default":null,"name":"image_1_alt","provenance":{},"required":true,"semantic_purpose":"first collage image alternative text","type":"string","validation":{}},{"accessibility":{"alt_attr_name":"image_1_alt","image_alt_policy":"consumer_supplied","required_when_source_present":true},"default":null,"name":"image_1_src","provenance":{},"required":true,"semantic_purpose":"first collage image source","type":"string","validation":{}},{"accessibility":{},"default":null,"name":"image_2_alt","provenance":{},"required":true,"semantic_purpose":"second collage image alternative text","type":"string","validation":{}},{"accessibility":{"alt_attr_name":"image_2_alt","image_alt_policy":"consumer_supplied","required_when_source_present":true},"default":null,"name":"image_2_src","provenance":{},"required":true,"semantic_purpose":"second collage image source","type":"string","validation":{}},{"accessibility":{},"default":null,"name":"image_3_alt","provenance":{},"required":true,"semantic_purpose":"third collage image alternative text","type":"string","validation":{}},{"accessibility":{"alt_attr_name":"image_3_alt","image_alt_policy":"consumer_supplied","required_when_source_present":true},"default":null,"name":"image_3_src","provenance":{},"required":true,"semantic_purpose":"third collage image source","type":"string","validation":{}},{"accessibility":{},"default":null,"name":"rest","provenance":{},"required":false,"semantic_purpose":"additional root global attributes","type":"global","validation":{}}],"public_slots":[{"accessibility":{},"cardinality":"0..1","consumer_responsibility":"caller","name":"body","provenance":{},"required":false,"semantic_purpose":"consumer-owned rich body markup","validation":{}},{"accessibility":{},"cardinality":"0..1","consumer_responsibility":"caller owns action element, label, destination, navigation, and events","name":"primary_action","provenance":{},"required":true,"semantic_purpose":"primary call-to-action markup","validation":{}}]}
```

Approval does not settle either downstream B risk. C09D7-B and C09D7-C remain unauthorized. This record ends at `A3_APPROVAL_TRANSITION_REVIEW_READY`; it does not authorize native generation, browser verification, or Catalogue admission.
