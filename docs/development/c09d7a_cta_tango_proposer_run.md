# C09D7-A2: CTA Tango proposer run

## Objective and non-goals

This record captures the candidate `ComponentContract` and matching
`ComponentizationPlan` produced by the existing
`LiveFrames.ComponentizationProposer.propose/2` from the accepted CTA Tango A0
DesignDocument and frozen A1 semantic input.

A2 does not approve the contract, run `ComponentReview`, call
`NativeGenerator`, generate HEEx or CSS, resolve either downstream B risk, or
authorize A3, C09D7-B, or C09D7-C. No production or test code changed. The
SemanticInput remains an in-memory compile-time bundle, and the candidate
artifacts are recorded here rather than persisted as separate JSON files.

## Owner authorization and base

```text
C09D7_A0=ACCEPTED
C09D7_A1=ACCEPTED_BY_OWNER
C09D7_A2=AUTHORIZED_BY_OWNER
C09D7_A3=NOT_AUTHORIZED
C09D7_B=NOT_AUTHORIZED
C09D7_C=NOT_AUTHORIZED

BASE_SHA=c81cc93ad4ba6c1a8ffbab7bd074eaf379e23137
BASE_TREE=488965bdce5a4b8e14deac198002b5e04eb6235c
BASE_CI=38037317672
BASE_CI_STATUS=completed
BASE_CI_CONCLUSION=success
```

The base was verified against `origin/main` before worktree creation. The
cleanroom branch is `docs/c09d7a-cta-proposer-run` at the exact base SHA.

## A0 and A1 identities

```text
SOURCE_COMPONENT_ID=hxambs
PRIVATE_ARTIFACT=private_reference/frames/staging-2026-09/cta-section-tango/bricks-component-hxambs-cta-section-tango.json
PRIVATE_ARTIFACT_SHA256=73f866a27070c010584babe230b5ffd0c78dc704388fd8b6c286e149a3d93a87
PRIVATE_ARTIFACT_BYTES=10224
FRAMES_CORPUS_DIGEST=074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e

DESIGN_DOCUMENT_SHA256=4b90b3ce32f8fcec640cea40499e861951137e3c2466931ead3c4436e2c6c9c5
ROOT_NODE_COUNT=1
TOTAL_NODE_COUNT=15
VALUE_BINDINGS=0
COLLECTION_BINDINGS=0
```

The private JSON was read and decoded as data. Each reproduction passed only
the decoded `components` and `globalClasses` fragment map to the existing
Bricks adapter. Each independently loaded
`fixtures/automatic_css/acss_settings.json` with source version `4.0.1`, status
`fixture_reference`, strict validation, and the `hero_foundation` profile. Both
used the existing `4.0.1` structural-variable authority with grid variables
enabled. No adapter behavior changed.

```text
DESIGN_DOCUMENT_REPRODUCTION=PASS
IR_VALIDATION=PASS
```

The frozen A1 `SemanticInput` was reconstructed independently for each
DesignDocument. Validation and field-by-field canonicalized-value comparison
passed. Canonicalization changed decision ordering only.

```text
SEMANTIC_INPUT_VALIDATION=PASS
CANONICALIZATION_SEMANTIC_DRIFT=NO
PUBLIC_ATTR_COUNT=11
PUBLIC_SLOT_COUNT=2
RENDER_PLACEMENT_COUNT=13
IMAGE_ACCESSIBILITY_DECISION_COUNT=3
STATIC_CONTENT_DISPOSITION_COUNT=4
COLLECTION_ADMISSIONS=0
ITEM_FIELDS=0
COLLECTION_COUNT_LINKS=0
BINDING_ASSIGNMENTS=0
EVIDENCE_HANDLING=0
```

## Proposer result

Both independent calls used the public `ComponentizationProposer.propose/2`
entry point. Neither call used internal construction functions.

```text
PROPOSER_OUTCOME=proposed
CONTRACT_APPROVAL_STATUS=proposed
A2_REVIEW_READY=YES
```

The candidate contract has format version `1.0.0`, id
`section_media_call_to_action`, category `section`, and module and function
intent `media_call_to_action`. It contains 11 public attrs, 2 public slots, no
collection inputs, and no binding projections. Its diagnostics are empty.

The candidate plan has format version `1.0.0`, contract id
`section_media_call_to_action`, the exact A0 DesignDocument digest above,
boundary `node_000001`, and 13 render projections. Its diagnostics are empty.

```text
CONTRACT_DIAGNOSTICS=[]
PLAN_DIAGNOSTICS=[]
CONTRACT_INTRINSIC_VALIDATION=PASS
CONTRACT_IR_REFERENCE_VALIDATION=PASS
PLAN_INTRINSIC_VALIDATION=PASS
PLAN_REFERENCE_VALIDATION=PASS
CONTRACT_PUBLIC_ATTR_COUNT=11
CONTRACT_PUBLIC_SLOT_COUNT=2
CONTRACT_COLLECTION_INPUT_COUNT=0
CONTRACT_BINDING_PROJECTION_COUNT=0
PLAN_RENDER_PROJECTION_COUNT=13
PLAN_BOUNDARY_NODE_ID=node_000001
CANDIDATE_SEMANTIC_MEANING_CHECK=PASS
```

The probe compared every candidate attr field and slot field with its frozen
A1 decision, and compared all plan render projection fields with the frozen
placement decisions. The comparisons passed without semantic changes.

## Determinism

Each run independently read and decoded the private source, reconstructed the
DesignDocument, built the frozen SemanticInput, and called the proposer. The
two encoded contracts and the two encoded plans were byte-equal.

```text
COMPONENT_CONTRACT_SHA256=cc62191c5f154e20a9abb9091693b56b59d4595662adabfbb82334babf8caf9c
COMPONENTIZATION_PLAN_SHA256=19d3a3cc31919239b4cb05e7b3ab37e06820bc514d17ee6edc27dea4a2719c8f
PROPOSER_OUTCOME_DETERMINISTIC=YES
CONTRACT_SERIALIZATION_DETERMINISTIC=YES
PLAN_SERIALIZATION_DETERMINISTIC=YES
```

The following fenced blocks contain the exact canonical JSON strings returned
by `ComponentContract.encode!/1` and `ComponentizationPlan.encode!/1`.

### Candidate ComponentContract

```json
{"approval_status":"proposed","binding_projections":[],"category":"section","collection_inputs":[],"contract_format_version":"1.0.0","contract_id":"section_media_call_to_action","diagnostics":[],"function_intent":"media_call_to_action","module_intent":"media_call_to_action","provenance":{},"public_attrs":[{"accessibility":{},"default":null,"name":"class","provenance":{},"required":false,"semantic_purpose":"additive root CSS class","type":"string","validation":{}},{"accessibility":{},"default":null,"name":"eyebrow","provenance":{},"required":false,"semantic_purpose":"eyebrow text","type":"string","validation":{}},{"accessibility":{},"default":null,"name":"heading","provenance":{},"required":true,"semantic_purpose":"primary heading text","type":"string","validation":{}},{"accessibility":{},"default":2,"name":"heading_level","provenance":{},"required":false,"semantic_purpose":"heading semantic level","type":"integer","validation":{"values":[1,2,3,4,5,6]}},{"accessibility":{},"default":null,"name":"image_1_alt","provenance":{},"required":true,"semantic_purpose":"first collage image alternative text","type":"string","validation":{}},{"accessibility":{"alt_attr_name":"image_1_alt","image_alt_policy":"consumer_supplied","required_when_source_present":true},"default":null,"name":"image_1_src","provenance":{},"required":true,"semantic_purpose":"first collage image source","type":"string","validation":{}},{"accessibility":{},"default":null,"name":"image_2_alt","provenance":{},"required":true,"semantic_purpose":"second collage image alternative text","type":"string","validation":{}},{"accessibility":{"alt_attr_name":"image_2_alt","image_alt_policy":"consumer_supplied","required_when_source_present":true},"default":null,"name":"image_2_src","provenance":{},"required":true,"semantic_purpose":"second collage image source","type":"string","validation":{}},{"accessibility":{},"default":null,"name":"image_3_alt","provenance":{},"required":true,"semantic_purpose":"third collage image alternative text","type":"string","validation":{}},{"accessibility":{"alt_attr_name":"image_3_alt","image_alt_policy":"consumer_supplied","required_when_source_present":true},"default":null,"name":"image_3_src","provenance":{},"required":true,"semantic_purpose":"third collage image source","type":"string","validation":{}},{"accessibility":{},"default":null,"name":"rest","provenance":{},"required":false,"semantic_purpose":"additional root global attributes","type":"global","validation":{}}],"public_slots":[{"accessibility":{},"cardinality":"0..1","consumer_responsibility":"caller","name":"body","provenance":{},"required":false,"semantic_purpose":"consumer-owned rich body markup","validation":{}},{"accessibility":{},"cardinality":"0..1","consumer_responsibility":"caller owns action element, label, destination, navigation, and events","name":"primary_action","provenance":{},"required":true,"semantic_purpose":"primary call-to-action markup","validation":{}}]}
```

### Candidate ComponentizationPlan

```json
{"boundary_node_id":"node_000001","contract_id":"section_media_call_to_action","design_document_sha256":"4b90b3ce32f8fcec640cea40499e861951137e3c2466931ead3c4436e2c6c9c5","diagnostics":[],"plan_format_version":"1.0.0","provenance":{},"render_projections":[{"public_attr_name":null,"public_slot_name":"body","render_role":"subtree_slot","target_node_id":"node_000001_000001_000002_000003"},{"public_attr_name":"class","public_slot_name":null,"render_role":"root_class","target_node_id":"node_000001"},{"public_attr_name":"eyebrow","public_slot_name":null,"render_role":"text_content","target_node_id":"node_000001_000001_000002_000002"},{"public_attr_name":"heading","public_slot_name":null,"render_role":"text_content","target_node_id":"node_000001_000001_000002_000001"},{"public_attr_name":"heading_level","public_slot_name":null,"render_role":"heading_level","target_node_id":"node_000001_000001_000002_000001"},{"public_attr_name":"image_1_alt","public_slot_name":null,"render_role":"asset_alt","target_node_id":"node_000001_000001_000001_000001_000001_000001"},{"public_attr_name":"image_1_src","public_slot_name":null,"render_role":"asset_src","target_node_id":"node_000001_000001_000001_000001_000001_000001"},{"public_attr_name":"image_2_alt","public_slot_name":null,"render_role":"asset_alt","target_node_id":"node_000001_000001_000001_000001_000002_000001"},{"public_attr_name":"image_2_src","public_slot_name":null,"render_role":"asset_src","target_node_id":"node_000001_000001_000001_000001_000002_000001"},{"public_attr_name":"image_3_alt","public_slot_name":null,"render_role":"asset_alt","target_node_id":"node_000001_000001_000001_000001_000003_000001"},{"public_attr_name":"image_3_src","public_slot_name":null,"render_role":"asset_src","target_node_id":"node_000001_000001_000001_000001_000003_000001"},{"public_attr_name":null,"public_slot_name":"primary_action","render_role":"subtree_slot","target_node_id":"node_000001_000001_000002_000004"},{"public_attr_name":"rest","public_slot_name":null,"render_role":"root_global_attrs","target_node_id":"node_000001"}]}
```

## B risks and boundaries

```text
B_RISK_01=primary_action is subtree_slot; caller owns markup and behavior; subtree-slot style pruning may leave CTA button presentation unresolved
B_RISK_02=image nodes contain normalized styles; later native image/figure output may require a style-locus authority decision
B_RISK_01_RESOLVED_BY_A2=NO
B_RISK_02_RESOLVED_BY_A2=NO

A3_AUTHORIZED=NO
C09D7_B_AUTHORIZED=NO
C09D7_C_AUTHORIZED=NO
```

## Performance and scaling

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

DesignDocument reconstruction=bounded O(source + styles)
SemanticInput validation=O(nodes + decisions + references)
Proposer construction and validation=bounded O(nodes + decisions + references)
```

The only local task-specific execution was the bounded `mix run --no-start`
probe. `mix deps.get` fetched the existing lockfile dependencies; it reported
no dependency changes. No full local umbrella suite was run for this single-file
documentation evidence change. Exact-head repository CI remains required.

## Lifecycle and next authorization boundary

```text
A2_AUTHORIZED
-> base_verified
-> design_document_reproduced
-> frozen_semantic_input_reconstructed
-> frozen_semantic_input_validated
-> proposer_run
-> proposed_candidate
-> deterministic_candidate_verified
-> A2_REVIEW_READY
```

The candidate is proposed and ready for independent A2 review. It is not
approved. A3 may begin only after the owner independently reviews and accepts
this A2 evidence and separately authorizes A3. C09D7-B and C09D7-C remain
unauthorized.
