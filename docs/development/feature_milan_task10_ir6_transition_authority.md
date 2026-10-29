# Feature Milan Task 10 IR6 transition authority

## Status and scope

```text
LIFECYCLE=task10_ir6_transition_authority_review_ready
STOP=AWAIT_TASK10_IR6_TRANSITION_AUTHORITY_REVIEW
TASK10_IR6_TRANSITION_ACCEPTED=NO
PHASE_7A_AUTHORIZED=NO
PHASE_7B_AUTHORIZED=NO
PHASE_8_AUTHORIZED=NO
```

This authority records the identity transition from the historical Task 10 IR5 execution state to the accepted IR6 DesignDocument and Behavior authority. It is a documentation-only review candidate. It does not create or authorize a ComponentContract, ComponentizationPlan, ComponentReview, or Phase 7 execution. It does not call `NativeRealizationAuthority.derive/5`.

Historical authority and plan records remain immutable. The accepted IR5 and IR6 Behavior artifacts remain tied to their exact DesignDocument identities. No identity fallback or cross-version review reuse is introduced.

## Current main and characterization base

```text
REPOSITORY=JCSchoeman96/LiveFrames
CURRENT_MAIN_SHA=f43a3f44eb1b14b2b8c0300a4a5be6ebee5b63d2
CURRENT_MAIN_TREE=9b44ea7711b19a378c0e51aa4ca0c2e3a126ae1c
CURRENT_MAIN_SIGNATURE=VALID
CURRENT_MAIN_CI_RUN=40732110724
CURRENT_MAIN_CI_EVENT=push
CURRENT_MAIN_CI_RESULT=SUCCESS

CHARACTERIZED_MAIN_SHA=3285f523e9985bc4342df1191eede84c761e659e
POST_CHARACTERIZATION_DELTA=DOCS_ONLY
POST_CHARACTERIZATION_CHANGED_PATH_COUNT=1
POST_CHARACTERIZATION_CHANGED_PATHS=docs/development/c09c7_article_juliet_dynamic_native_realization_authority.md
MILAN_PRODUCTION_PATH_CHANGED_AFTER_CHARACTERIZATION=NO
MILAN_DESIGNDOCUMENT_RECHARACTERIZATION_REQUIRED=NO
```

The GitHub commit verification for current `main` is valid. CI run `40732110724` completed successfully for the exact current `main` head. The delta from the characterized Milan base is limited to the Article Juliet authority document; no Milan implementation or production path changed.

## Historical IR5 Task 10 identity

```text
HISTORICAL_IR_VERSION=5.0.0

HISTORICAL_DESIGN_DOCUMENT_SHA256=9ae73053d9224bebcb71833b77094a17c3ef7c3a25f0b5b1c4dbad5aaf9d2229
HISTORICAL_DESIGN_DOCUMENT_CANONICAL_BYTES_LENGTH=412682

HISTORICAL_BEHAVIOR_BINDING_ID=bnd_abf701b79aba7597825525c7ddf5065e89a2fdcfb378797f63e3d9fb74ff8ee2
HISTORICAL_BEHAVIOR_CONTRACT_DIGEST=1e0095418d96f392594a155d9c6ea9610b6b5f4d62c6d0205df66dedea57506a
HISTORICAL_BEHAVIOR_REVIEW_ID=brv_b4bc3ab7f4284cf20ae6f0aaf73da3fd2c242e42d18f1ab049acc6f1e62e9c11

IR5_AUTHORITY_STATUS=HISTORICAL_EXACT_DOCUMENT_AUTHORITY
IR5_IDENTITIES_REUSED_FOR_IR6=NO
```

The IR5 identity and review are recorded by the historical [IR5 BehaviorContract reissue](feature_milan_ir5_behavior_contract_reissue.md) and [IR5 BehaviorReviewResult](feature_milan_ir5_behavior_review_result.md). They remain evidence for the exact IR5 document only.

## Accepted exact IR6 identity

```text
IR_VERSION=6.0.0

DESIGN_DOCUMENT_CANONICALIZATION_ID=lf-ir-serializer-v1
DESIGN_DOCUMENT_DIGEST_ALGORITHM=sha-256
DESIGN_DOCUMENT_SHA256=d4b945741cb088ff7c739224f5cddc9904f3655741f74fa4bf17318cf3242ca9
DESIGN_DOCUMENT_CANONICAL_BYTES_LENGTH=412682

BEHAVIOR_CONTRACT_FORMAT_VERSION=1.0.0
BEHAVIOR_BINDING_ID=bnd_38bcdc5dd2a7d55e0274ba1435a2e775cac877b3f28c7377a30140c67f4e59e1
BEHAVIOR_CONTRACT_DIGEST_ALGORITHM=lf-behavior-v1-jcs-sha256
BEHAVIOR_CONTRACT_DIGEST=610029d848ec480d7cadeba7267b0cbd91607ea6246685212fa4aaa7971f51c6

BEHAVIOR_REVIEW_FORMAT_VERSION=1.0.0
BEHAVIOR_REVIEW_ID=brv_3dd12192602c0be16ba84627917887b157ba52fe2c81a0672659c367fc240d9d
BEHAVIOR_REVIEW_CANONICAL_BYTES_LENGTH=905
BEHAVIOR_REVIEW_CANONICAL_SHA256=3dd12192602c0be16ba84627917887b157ba52fe2c81a0672659c367fc240d9d
```

The exact IR6 identities are recorded in the accepted [IR6 BehaviorContract reissue](feature_milan_ir6_behavior_contract_reissue.md) and [IR6 BehaviorReviewResult](feature_milan_ir6_behavior_review_result.md), under the [IR6 Behavior identity compatibility authority](c09c6b_behavior_identity_ir6_compatibility_authority.md).

## DesignDocument continuity characterization

The accepted reconstruction evidence compares the canonical IR5 and IR6 DesignDocuments. The sole changed path is the required IR version identity field.

```text
IR5_RECONSTRUCTED_IR_VERSION=5.0.0
IR5_RECONSTRUCTED_SHA256=9ae73053d9224bebcb71833b77094a17c3ef7c3a25f0b5b1c4dbad5aaf9d2229
IR5_RECONSTRUCTED_CANONICAL_BYTES_LENGTH=412682
IR5_RECONSTRUCTED_NODE_COUNT=17
IR5_EXPECTED_IDENTITY_MATCH=YES

IR6_RECONSTRUCTED_IR_VERSION=6.0.0
IR6_RECONSTRUCTED_SHA256=d4b945741cb088ff7c739224f5cddc9904f3655741f74fa4bf17318cf3242ca9
IR6_RECONSTRUCTED_CANONICAL_BYTES_LENGTH=412682
IR6_RECONSTRUCTED_NODE_COUNT=17
IR6_ACCEPTED_IDENTITY_MATCH=YES

CHANGED_PATH_COUNT=1
CHANGED_PATHS=/ir_version
DOCUMENTS_EQUAL_AFTER_REMOVING_IR_VERSION=YES

IR_VERSION_CHANGED=YES
CANONICAL_IDENTITY_CHANGED=YES
NODE_COUNT_CHANGED=NO
NODE_TOPOLOGY_CHANGED=NO
BINDINGS_CHANGED=NO
INTERACTIONS_CHANGED=NO
STYLES_CHANGED=NO
DIAGNOSTICS_CHANGED=NO
TASK10_REALIZATION_RELEVANT_DESIGN_SEMANTICS_CHANGED=NO

CLASSIFICATION=EXPECTED_IR_VERSION_IDENTITY_CHANGE
SEMANTIC_REDESIGN_REQUIRED=NO
```

The reconstruction and recursive comparison are accepted characterization evidence; this authority does not repeat the private Milan extraction or the comparison.

## Cross-version BehaviorReviewResult rejection

The production Behavior review validation API was exercised with the exact historical IR5 review and accepted IR6 contract:

```text
IR5_BEHAVIOR_REVIEW_ID=brv_b4bc3ab7f4284cf20ae6f0aaf73da3fd2c242e42d18f1ab049acc6f1e62e9c11
IR6_BEHAVIOR_CONTRACT_DIGEST=610029d848ec480d7cadeba7267b0cbd91607ea6246685212fa4aaa7971f51c6
IR5_BEHAVIOR_REVIEW_ATTACHES_TO_IR6_CONTRACT=NO
IR5_REVIEW_REJECTION_DIAGNOSTIC=behavior.review.document_identity_mismatch
CROSS_VERSION_BEHAVIOR_REVIEW_REUSE=FORBIDDEN
```

This is the required fail-closed result. Do not add compatibility equivalence, digest fallback, or historical review reuse.

## ComponentContract and ComponentizationPlan lifecycle

The historical IR5 Behavior authority records that Milan componentization had not started:

```text
SEMANTIC_INPUT_CREATED=NO
COMPONENT_PROPOSER_STARTED=NO
COMPONENT_CONTRACT_CREATED=NO
COMPONENTIZATION_PLAN_CREATED=NO
COMPONENT_REVIEW_CREATED=NO

IR5_COMPONENT_CONTRACT_TO_MIGRATE=NONE
IR5_COMPONENTIZATION_PLAN_TO_MIGRATE=NONE
COMPONENT_CONTRACT_IR6_REISSUE_REQUIRED=NO
COMPONENTIZATION_PLAN_IR6_REISSUE_REQUIRED=NO
```

The final Milan `SemanticInput`, `ComponentContract`, and `ComponentizationPlan` have not yet been created. The canonical [Task 10 plan](../superpowers/plans/2026-10-23-milan-source-neutral-realization.md) intentionally creates them for the first time in Phase 7: 7A recreates the final `SemanticInput` and runs the proposer; 7B freezes the resulting candidate contract and plan; Phase 8 is the human `ComponentReview` gate.

Accordingly, a real Milan `NativeRealizationAuthority.derive/5` call is not a pre-Phase-7 prerequisite:

```text
PRE_PHASE7_REAL_MILAN_DERIVE_5_EXPECTED=NOT_RUNNABLE
DERIVE_5_BLOCKER=REAL_COMPONENT_CONTRACT_AND_PLAN_NOT_CREATED_YET
DERIVE_5_BLOCKER_CLASS=EXPECTED_PROGRAMME_SEQUENCE
DERIVE_5_FAILURE_CLASSIFICATION=NOT_A_PRODUCT_DEFECT
NATIVE_REALIZATION_AUTHORITY_DERIVE_5_RUN=NO
```

Do not invent a synthetic or replacement tuple, rewrite the historical plan or contract, or run `derive/5` before the real Phase 7 artifacts exist.

## Task 10 semantic continuity

This identity transition changes no accepted Selection semantics:

```text
R1A_PUBLIC_API_CHANGED=NO
SELECTION_PRIMITIVE_CHANGED=NO
N2_N3_REALIZATION_POLICY_CHANGED=NO
ARIA_POLICY_CHANGED=NO
TIMER_POLICY_CHANGED=NO
REDUCED_MOTION_POLICY_CHANGED=NO
LIFECYCLE_POLICY_CHANGED=NO
NESTED_INSTANCE_ISOLATION_CHANGED=NO
GENERATION_BOUNDARY_CHANGED=NO
SERIALIZED_SCHEMA_CHANGED=NO
SOURCE_NEUTRALITY_CHANGED=NO
```

```text
Selection != Tabs
Selection != Carousel
```

No Tabs semantics are introduced.

## Phase 6 completion

```text
PR342_STATUS=MERGED
PR342_MERGE_SHA=3285f523e9985bc4342df1191eede84c761e659e
PICTURE_STRUCTURE_SUPPORT=AVAILABLE
PICTURE_STYLE_LOCI_SUPPORT=AVAILABLE
PHASE_6_ACCEPTED=YES
MILAN_LEAD1_STATIC_BLOCKER=NONE
```

PR #342 is accepted as merged into current `main`. This authority does not reopen, amend, or re-review it.

## Reset V2 ownership boundary

```text
LEAD2_OWNER=BEHAVIOR_SEMANTICS_AND_NATIVE_BEHAVIOR_REALIZATION
LEAD1_OWNER=STATIC_COMPILER_AND_GENERAL_COMPONENTIZATION
```

Phase 7 `SemanticInput`, `ComponentContract`, and `ComponentizationPlan` belong to the general componentization capability. After this transition authority is independently accepted and its exact merge passes post-merge CI:

```text
NEXT_EXECUTION_OWNER=LEAD1
NEXT_CAPABILITY=FEATURE_MILAN_PHASE_7A_FINAL_COMPONENTIZATION
```

Lead 2 retains review authority for Selection semantic preservation, exact BehaviorContract and BehaviorReviewResult identity, Behavior containment, the behavior-specific `NativeRealizationAuthority` outcome, accessibility interaction semantics, and runtime/browser proof. `StyleIntegration`, static image structure, and general componentization remain outside Lead 2 ownership.

## Phase 7 authorization and handoff

Before independent acceptance, exact merge, and successful post-merge CI for this authority:

```text
TASK10_IR6_TRANSITION_ACCEPTED=NO
PHASE_7A_AUTHORIZED=NO
PHASE_7B_AUTHORIZED=NO
PHASE_8_AUTHORIZED=NO
```

After those gates pass, this authority may authorize only Phase 7A:

```text
TASK10_IR6_TRANSITION_ACCEPTED=YES
PHASE_7A_AUTHORIZED=YES
PHASE_7B_AUTHORIZED=NO
PHASE_8_AUTHORIZED=NO
```

Phase 7A still requires its own exact review gate. It must not approve `ComponentReview` or authorize Phase 7B automatically.

The next owner must use this exact final `SemanticInput` tuple:

```text
FINAL_SEMANTIC_INPUT_REQUIRES=
  id
  features
  feature_media
  feature_heading_level
  intro_slot
  six_existing_projections_and_bindings
  N1_source_runtime_carrier_disposition
```

Phase 7A must run `Behavior.ComponentizationDecision.propose/5`, require `result=:proposed` and `diagnostics=[]`, then run generation prerequisites against the exact IR6 Behavior authority and require zero blockers. It must not approve `ComponentReview` and must introduce no new source semantics.

The cross-lane request, valid only after transition acceptance, is:

```text
CAPABILITY_REQUEST
REQUESTING_LEAD=2
TRACER=Feature Milan
BLOCKER=Real final SemanticInput / ComponentContract / ComponentizationPlan have not yet been created
CAPABILITY=Phase 7A final general componentization using accepted IR6 DesignDocument and exact accepted IR6 Behavior authority
OWNER=1
WHY_NOT_LEAD2=Reset V2 assigns general componentization to Lead 1
EXPECTED_OUTPUT=One exact proposed Milan candidate tuple ready for Phase 7B fingerprint freeze
BEHAVIOR_OWNER_REVIEW_REQUIRED=YES
```

## Performance and scaling

This is a compile/review-time identity transition only:

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
100K_CONCURRENCY_IMPACT=NONE
```

No runtime infrastructure is added.

## Security and source-neutral boundary

```text
SOURCE_JAVASCRIPT_EXECUTED=NO
SOURCE_PHP_EXECUTED=NO
SOURCE_RUNTIME_COPIED=NO
SOURCE_SELECTOR_COPIED=NO
CROSS_VERSION_IDENTITY_FALLBACK=NO
IR5_REVIEW_REUSED=NO
NEW_DEPENDENCY_INTRODUCED=NO
PRODUCTION_CHANGED=NO
TESTS_CHANGED=NO
```

## Publication and stop boundary

The only authorized repository change for this transition slice is this new authority document. It must be submitted as one signed documentation-only commit and one PR against `main`. Do not merge the PR or start Phase 7A. Independent review, exact merge, and successful post-merge CI are required before the transition may be accepted.

Stop this publication if any of these conditions occurs:

```text
STOP=MAIN_MOVED_BEFORE_TASK10_IR6_TRANSITION_PUBLICATION
STOP=MILAN_CHARACTERIZATION_BASE_INVALIDATED
STOP=IR6_IDENTITY_TUPLE_MISMATCH
STOP=DESIGNDOCUMENT_CONTINUITY_EVIDENCE_CONTRADICTED
STOP=HISTORICAL_TASK10_AUTHORITY_MUTATION_REQUIRED
STOP=COMPONENT_ARTIFACT_INVENTION_REQUIRED
STOP=CROSS_VERSION_BEHAVIOR_REUSE_REQUIRED
STOP=SEMANTIC_REDESIGN_REQUIRED
STOP=DOC_SCOPE_EXPANSION_REQUIRED
STOP=PRODUCTION_CHANGE_REQUIRED
STOP=TEST_CHANGE_REQUIRED
STOP=SIGNATURE_INVALID
STOP=PR_CI_FAILURE
STOP=REPEATED_FIX_FAILURE_ROOT_CAUSE_REVIEW_REQUIRED
```

```text
TASK10_IR6_TRANSITION_ACCEPTED=NO
PHASE_7A_AUTHORIZED=NO
PHASE_7B_AUTHORIZED=NO
PHASE_8_AUTHORIZED=NO
PAGE_A_HANDOFF_READINESS=NOT_READY
NEXT_PRIMITIVE_AFTER_MILAN=HOLD
STOP=AWAIT_TASK10_IR6_TRANSITION_AUTHORITY_REVIEW
```
