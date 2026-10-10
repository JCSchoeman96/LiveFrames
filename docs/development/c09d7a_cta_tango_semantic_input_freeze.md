# C09D7-A1: CTA Tango semantic input freeze

## 1. Objective and non-goals

This document records the owner-approved ComponentizationSemanticInput decisions for the CTA Tango DesignDocument and the result of validating that input in memory.

A1 does not run ComponentizationProposer.propose/2, construct a ComponentContract or ComponentizationPlan, execute ComponentReview, or call NativeGenerator. It adds no production or test code. SemanticInput has no serialized format or persistence API, so this freeze records the decisions as authority and validates them in memory. It does not define a JSON, YAML, TOML, or other persistence format.

## 2. Accepted authority chain

- C09D7-A0 is accepted. Its canonical fragment-map DesignDocument digest is recorded below.
- A1-G0 is accepted. It authorizes the explicit owner decision and validation slice only.
- A1-G1 is accepted by PR #173. Approved head dfd8dfef70f035cb5bf3bd5f83597f89ca043493 was merged as bbb9f5248698b4ba59f3b92e2733113c34f46937, tree 6570f24cc9fdbc45acaa605a56446bbe3fc6c24e. Merge parents were d0fe1dc5804ee0d28a6982522a9e70e96b864b68 and the approved G1 head. The merge signature was valid. Post-merge CI run 38032967861 passed.
- The exact current base for this work is bbb9f5248698b4ba59f3b92e2733113c34f46937, tree 6570f24cc9fdbc45acaa605a56446bbe3fc6c24e.

These authorities do not accept a Contract or Plan and do not authorize A2, A3, or C09D7-B.

## 3. Source identity and canonical ingestion boundary

The one local evidence artifact used for reproduction was:

private_reference/frames/staging-2026-09/cta-section-tango/bricks-component-hxambs-cta-section-tango.json

| Evidence | Verified value |
| --- | --- |
| Artifact SHA-256 | 73f866a27070c010584babe230b5ffd0c78dc704388fd8b6c286e149a3d93a87 |
| Bytes | 10224 |
| Component ID | hxambs |
| Element count | 15 |
| Global class count | 13 |

The canonical A0 source boundary is the decoded fragment map containing only components and globalClasses. Bricks receives this in-memory map, the component ID, the fixture TokenSet, and the explicit Automatic.css 4.0.1 structural-variable authority. The private artifact is not committed and its literal content and CSS are not copied here.

The reproduced DesignDocument has source label inline and source hash ad6ca88c5e814da4829d9785293e0b63bf3f4358bb6a352cfaca4800f465c1e9. The hash identifies the map encoded as source bytes for provenance. It is evidence identity, not a component API member.

## 4. DesignDocument identity and reconciliation

The canonical fragment-map construction passed LiveFrames.IR.validate/1 and produced:

IR_VALIDATION=PASS
DESIGN_DOCUMENT_SHA256=4b90b3ce32f8fcec640cea40499e861951137e3c2466931ead3c4436e2c6c9c5
ROOT_NODE_COUNT=1
TOTAL_NODE_COUNT=15
VALUE_BINDINGS=0
COLLECTION_BINDINGS=0

The accepted R5 file-path construction has digest 647b4e633c6bcb7dce3f278577e109fc04cae5606c38260c3fad1b1e3875b79b. Both documents have the same normalized semantic surface. Their identity difference is limited to source_metadata.source_label, source_metadata.source_hash, and provenance.source_hash. The file-path construction uses the filename as its source label and hashes the original file bytes. The fragment-map construction uses inline and hashes the encoded fragment map. The two TokenSets are deeply equal. The accepted A0 digest remains 4b90b3ce32f8fcec640cea40499e861951137e3c2466931ead3c4436e2c6c9c5; no fingerprint or serializer authority changed.

## 5. Owner-approved identity, classification, and boundary

| Decision | Frozen value |
| --- | --- |
| Contract ID | section_media_call_to_action |
| Category | section |
| Module intent | media_call_to_action |
| Function intent | media_call_to_action |
| Boundary node | node_000001 |
| Multi-root unsupported | false |

These names describe the reusable component role. They do not derive from source IDs, classes, labels, paths, or traces.

## 6. Public attrs

Exactly eleven attrs are accepted.

| Name | Type | Required | Default | Semantic purpose | Validation | Accessibility |
| --- | --- | --- | --- | --- | --- | --- |
| heading | string | yes | nil | primary heading text | {} | {} |
| heading_level | integer | no | 2 | heading semantic level | {"values":[1,2,3,4,5,6]} | {} |
| eyebrow | string | no | nil | eyebrow text | {} | {} |
| image_1_src | string | yes | nil | first collage image source | {} | consumer-supplied alt via image_1_alt, required when source is present |
| image_1_alt | string | yes | nil | first collage image alternative text | {} | {} |
| image_2_src | string | yes | nil | second collage image source | {} | consumer-supplied alt via image_2_alt, required when source is present |
| image_2_alt | string | yes | nil | second collage image alternative text | {} | {} |
| image_3_src | string | yes | nil | third collage image source | {} | consumer-supplied alt via image_3_alt, required when source is present |
| image_3_alt | string | yes | nil | third collage image alternative text | {} | {} |
| class | string | no | nil | additive root CSS class | {} | {} |
| rest | global | no | nil | additional root global attributes | {} | {} |

Every attr has an empty provenance map. Each image source accessibility map is exactly {"image_alt_policy":"consumer_supplied","alt_attr_name":"image_N_alt","required_when_source_present":true} with its matching number. No image is classified decorative. No id, destination, navigation, event, button-label, variant, layout, or theme attr is part of this API.

## 7. Public slots

Exactly two slots are accepted.

| Name | Cardinality | Required | Semantic purpose | Consumer responsibility |
| --- | --- | --- | --- | --- |
| body | 0..1 | no | consumer-owned rich body markup | caller |
| primary_action | 0..1 | yes | primary call-to-action markup | caller owns action element, label, destination, navigation, and events |

Both slots have empty validation, accessibility, and provenance maps. The caller supplies the action markup and behavior. The contract invents no destination or navigation/event semantics.

## 8. Empty collection, binding, and evidence decisions

These decision families are empty:

COLLECTION_ADMISSIONS=[]
ITEM_FIELDS=[]
COLLECTION_COUNT_LINKS=[]
BINDING_ASSIGNMENTS=[]
EVIDENCE_HANDLING=[]

The DesignDocument has zero value bindings and zero collection bindings. EvidenceHandlingDecision is not an audit-record container; no evidence-handling decision is needed for this input.

## 9. Render placements

Exactly thirteen placements are accepted.

| Target kind | Public name | Design node | Render role |
| --- | --- | --- | --- |
| attr | class | node_000001 | root_class |
| attr | rest | node_000001 | root_global_attrs |
| attr | heading | node_000001_000001_000002_000001 | text_content |
| attr | heading_level | node_000001_000001_000002_000001 | heading_level |
| attr | eyebrow | node_000001_000001_000002_000002 | text_content |
| slot | body | node_000001_000001_000002_000003 | subtree_slot |
| slot | primary_action | node_000001_000001_000002_000004 | subtree_slot |
| attr | image_1_src | node_000001_000001_000001_000001_000001_000001 | asset_src |
| attr | image_1_alt | node_000001_000001_000001_000001_000001_000001 | asset_alt |
| attr | image_2_src | node_000001_000001_000001_000001_000002_000001 | asset_src |
| attr | image_2_alt | node_000001_000001_000001_000001_000002_000001 | asset_alt |
| attr | image_3_src | node_000001_000001_000001_000001_000003_000001 | asset_src |
| attr | image_3_alt | node_000001_000001_000001_000001_000003_000001 | asset_alt |

## 10. Image accessibility decisions

Exactly three decisions target image_1_src, image_2_src, and image_3_src. Each has target_kind=attr, a nil source_collection_binding_id, and the matching consumer_supplied alt policy with required_when_source_present=true. Alt values come from the consumer, not the source artifact.

## 11. Static-content dispositions

Exactly four dispositions promote static content to the public API. Each has design_node_id=nil.

| Target kind | Public target |
| --- | --- |
| promote_attr | heading |
| promote_attr | eyebrow |
| promote_slot | body |
| promote_slot | primary_action |

No private source text is recorded as a component constant.

## 12. SemanticInput validation and canonicalization

The exact owner-approved LiveFrames.ComponentizationProposer.SemanticInput was constructed in memory and passed to SemanticInput.validate/2 with the canonical A0 DesignDocument.

SEMANTIC_INPUT_VALIDATION=PASS
CANONICALIZATION_SEMANTIC_DRIFT=NO
PUBLIC_ATTR_COUNT=11
PUBLIC_SLOT_COUNT=2
RENDER_PLACEMENT_COUNT=13
IMAGE_ACCESSIBILITY_DECISION_COUNT=3
STATIC_CONTENT_DISPOSITION_COUNT=4

The validator returned {:ok, canonical_input}. A field-by-field comparison found no change to identity, classification, boundary, attrs, slots, validation/default/accessibility/provenance maps, placements, targets, roles, cardinality, or decision membership. Only deterministic ordering of repeatable decision lists is allowed. No serialized input or persistence format was created.

## 13. Source-independence review

PUBLIC_SOURCE_IDS=0
PUBLIC_SOURCE_CLASSES=0
PUBLIC_EDITOR_LABELS=0
PUBLIC_SOURCE_PATHS=0
PUBLIC_SOURCE_TRACES=0

BRICKS_PUBLIC_API=NO
FRAMES_PUBLIC_API=NO
TANGO_PUBLIC_API=NO

BEHAVIOR_INVENTED=NO
NAVIGATION_INVENTED=NO
QUERY_RUNTIME_INVENTED=NO

Source hashes and ingestion identity appear only as audit evidence above. Public names and decisions do not use source IDs, classes, labels, paths, or traces. No destination or interaction behavior was inferred.

## 14. Known downstream B risks

These risks do not change the semantic freeze.

- B-RISK-01, primary-action presentation. primary_action is a subtree_slot, so the caller owns its markup and behavior. Current subtree-slot style pruning removes generated styling for the target node. CTA button presentation may need generator or presentation authority in B. A1 does not replace the slot with a destination or behavior attr or an internal button.
- B-RISK-02, image/figure style locus. The three image nodes have normalized styles. If B cannot mechanically assign those styles to the correct native element when output uses compound figure/image markup, B must stop with a style-locus authority gap. A1 does not move those styles or change image semantics.

## 15. Performance and scaling review

This is a cold build-time normalization and validation path. It adds no hot or warm runtime data layer and makes no database, network, CSS-generation, or runtime-concurrency claim.

DATA_LAYER=COLD_BUILD_TIME
HOT_DATA=N/A
WARM_DATA=N/A
REDIS=N/A
POSTGRES=N/A
PUBSUB=N/A
GENSERVER=N/A
OBAN=N/A

RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
RUNTIME_CSS_GENERATION=0
100K_RUNTIME_CONCURRENCY=N/A

DESIGN_IR_NORMALIZATION=O(source+styles)
SEMANTIC_VALIDATION=O(nodes+decisions+references)
NO_NEW_WHOLE_TREE_SCAN=YES

## 16. Lifecycle

awaiting_owner_decisions
-> owner_decisions_accepted
-> design_document_identity_reconciled
-> semantic_input_constructed
-> semantic_input_validated
-> semantic_input_freeze_recorded
-> A1_review_ready

Failure terminals are source_identity_mismatch, a0_identity_regression, semantic_input_validation_failed, canonicalization_semantic_drift, authority_change_required, source_specific_api_required, and behavior_required.

## 17. Verdict and next authorization boundary

A1_REVIEW_READY
A1_ACCEPTED=NO
A2_AUTHORIZED=NO
A3_AUTHORIZED=NO
C09D7_B_AUTHORIZED=NO

This document freezes the accepted owner decisions and records successful in-memory validation. A1 remains subject to independent review, merge at the exact approved PR head, and passing post-merge CI. Only after those gates may the owner authorize A2 to run the proposer against this exact frozen input. No proposer, Contract, Plan, ComponentReview, or native generator was run in A1.
