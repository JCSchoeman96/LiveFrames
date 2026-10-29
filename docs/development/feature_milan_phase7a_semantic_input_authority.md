# Feature Milan Phase 7A semantic input authority

## Objective and authority

This review candidate records the owner-approved SemanticInput decisions and their in-memory validation. SemanticInput has no serialized format. This record does not create a contract or plan, run a proposer, approve a component, or authorize generation. Independent review, merge, and post-merge CI are required before a Phase 7A retry.

The historical Milan preflight recorded `OWNER_DECISIONS_RECORDED=NO` and `A1_SEMANTIC_INPUT_FROZEN=NO`. Those statements describe its historical state and remain unchanged. Later accepted R1A public API, IR6 transition, source-node disposition, and collection-item alt-companion authority allow the owner decisions recorded here.

```text
HISTORICAL_OWNER_DECISIONS_RECORDED=NO
OWNER_DECISIONS_RECORDED=YES
A1_SEMANTIC_INPUT_FROZEN=YES
AUTHORITY_ACCEPTED=NO_PENDING_REVIEW
PHASE_7A_RETRY_AUTHORIZED=NO_PENDING_AUTHORITY_REVIEW
```

## Base and document identity

The base is commit `d03f635c779e86af907d9c1225b0bcba846bae62`, tree `6196463ecaa7c2a0dcc37015bb9e7e142e70346d`. CI run `40827422909` succeeded on that commit. The accepted IR6 reconstruction path loaded the source as data, normalized with the accepted token fixture, resolved the accepted breakpoint authority, and validated the DesignDocument.

```text
IR_VERSION=6.0.0
DESIGN_DOCUMENT_SHA256=d4b945741cb088ff7c739224f5cddc9904f3655741f74fa4bf17318cf3242ca9
DESIGN_DOCUMENT_CANONICAL_BYTES_LENGTH=412682
DESIGN_DOCUMENT_NODE_COUNT=17
BEHAVIOR_BINDING_ID=bnd_38bcdc5dd2a7d55e0274ba1435a2e775cac877b3f28c7377a30140c67f4e59e1
BEHAVIOR_CONTRACT_DIGEST=610029d848ec480d7cadeba7267b0cbd91607ea6246685212fa4aaa7971f51c6
BEHAVIOR_REVIEW_ID=brv_3dd12192602c0be16ba84627917887b157ba52fe2c81a0672659c367fc240d9d
```

The Behavior identities above are accepted authority references, not newly reconstructed review evidence. IR5 authority is not reused.

## Identity and boundary

```text
contract_id=component_feature_showcase
category=component
module_intent=feature_showcase
function_intent=feature_showcase
boundary_node_id=node_000001
multi_root_unsupported=false
```

These public names describe the reusable role and do not use source identifiers, classes, paths, or editor labels.

## Public attrs and slot

| Name | Type | Required | Default | Semantic purpose | Validation |
| --- | --- | --- | --- | --- | --- |
| id | string | true | nil | component root id | {} |
| features | list | true | nil | feature content items | {} |
| feature_media | list | true | nil | feature presentation media items | {} |
| feature_heading_level | integer | false | 3 | feature title semantic heading level | {"values":[1,2,3,4,5,6]} |

All attrs have empty accessibility and provenance maps. No other public attrs are authorized.

The sole slot is `intro`, cardinality `0..1`, `required=false`, semantic purpose `consumer-owned introductory content`, consumer responsibility `caller owns intro markup and content`, with empty validation, accessibility, and provenance maps. R1A requires the contract to expose the slot; an invocation may supply zero or one entry.

## Collections and item fields

Both admissions have nil parent collection and parent item field, and empty provenance.

| Collection binding | Public attr |
| --- | --- |
| cb_node_000001_000001_000001_000002_000001 | features |
| cb_node_000001_000001_000002_000001 | feature_media |

| Collection | Name | Type | Required | Default | Semantic purpose |
| --- | --- | --- | --- | --- | --- |
| features | title | string | true | nil | feature title |
| features | description | string | true | nil | feature description text |
| features | image_src | string | true | nil | feature image source |
| features | image_alt | string | false | nil | consumer supplied feature image alternative text |
| feature_media | image_src | string | true | nil | feature presentation image source |
| feature_media | image_alt | string | false | nil | consumer supplied feature presentation image alternative text |

All item fields have empty validation and provenance. Non-image-source fields have empty accessibility. Each `image_src` carries the same accessibility map as its ImageAccessibilityDecision:

```text
{"image_alt_policy":"consumer_supplied","alt_item_field_name":"image_alt","required_when_source_present":true}
```

Both decisions have `target_kind=item_field`, `target_name=image_src`, and the respective collection binding ID. Neither image is decorative. The alt fields are unbound companions, with no binding assignment or projection. The description is caller-supplied transformed text; no word-limit input or runtime truncation is authorized. The collections remain separate; positional synchronization belongs to Behavior authority.

## Binding assignments

| Kind | Source binding ID | Assignment | Collection | Public target |
| --- | --- | --- | --- | --- |
| collection | cb_node_000001_000001_000001_000002_000001 | collection_attr | cb_node_000001_000001_000001_000002_000001 | features |
| collection | cb_node_000001_000001_000002_000001 | collection_attr | cb_node_000001_000001_000002_000001 | feature_media |
| value | vb_node_000001_000001_000001_000002_000001_000001_text_000001 | collection_item_field_value | cb_node_000001_000001_000001_000002_000001 | title |
| value | vb_node_000001_000001_000001_000002_000001_000002_000001_text_000001 | collection_item_field_value | cb_node_000001_000001_000001_000002_000001 | description |
| value | vb_node_000001_000001_000001_000002_000001_000002_000002_000001_asset_000001 | collection_item_field_value | cb_node_000001_000001_000001_000002_000001 | image_src |
| value | vb_node_000001_000001_000002_000001_000001_asset_000001 | collection_item_field_value | cb_node_000001_000001_000002_000001 | image_src |

Unused fields in each assignment are nil. Collection assignments set `public_attr_name`; value assignments set `item_field_name`.

## Render placements and static disposition

| Target kind | Public name | Target node | Render role |
| --- | --- | --- | --- |
| attr | id | node_000001 | root_id |
| attr | feature_heading_level | node_000001_000001_000001_000002_000001_000001 | heading_level |
| slot | intro | node_000001_000001_000001_000001 | subtree_slot |

The intro target is the wrapper containing the static heading and rich-text children. The caller-owned slot replaces that subtree. One static disposition has `target_kind=promote_slot`, `design_node_id=nil`, and `public_target_name=intro`. No source literals are published as public inputs.

## Source-node disposition

```text
design_node_id=node_000001_000002
outcome=exclude_source_runtime_carrier
behavior_binding_id=bnd_38bcdc5dd2a7d55e0274ba1435a2e775cac877b3f28c7377a30140c67f4e59e1
```

The evidence references, in canonical order, are:

```text
docs/development/feature_milan_ir6_behavior_review_result.md
docs/development/feature_milan_task10_ir6_transition_authority.md
docs/development/feature_milan_task10_source_neutral_realization_authority.md
```

These opaque review pointers confer no Behavior authority and are not runtime predicates. Source type, source ID, Behavior contract digest, and review ID are derived later through accepted document and Behavior authority paths, not supplied in SemanticInput. Collection count links and evidence handling are empty.

## Validation and boundary

The exact decisions were constructed in memory and passed to `SemanticInput.validate/2` against the reconstructed DesignDocument. The validator returned `{:ok, canonical_input}`. Comparison of every decision field found no semantic drift; deterministic family ordering and evidence-reference ordering are the only allowed differences.

```text
SEMANTIC_INPUT_VALIDATION=PASS
CANONICALIZATION_SEMANTIC_DRIFT=NO
PUBLIC_ATTR_COUNT=4
PUBLIC_SLOT_COUNT=1
COLLECTION_ADMISSION_COUNT=2
ITEM_FIELD_COUNT=6
BINDING_ASSIGNMENT_COUNT=6
RENDER_PLACEMENT_COUNT=3
IMAGE_ACCESSIBILITY_DECISION_COUNT=2
STATIC_CONTENT_DISPOSITION_COUNT=1
SOURCE_NODE_DISPOSITION_COUNT=1
COLLECTION_COUNT_LINKS=[]
EVIDENCE_HANDLING=[]
PROPOSER_RUN=NO
COMPONENT_CONTRACT_CREATED=NO
COMPONENTIZATION_PLAN_CREATED=NO
COMPONENT_REVIEW_STARTED=NO
NATIVE_GENERATION_STARTED=NO
ARTICLE_JULIET_P4B=DEFERRED
```

This validation does not prove generation eligibility or approve the candidate. No source JavaScript or PHP was executed, no source runtime was copied, and no dependency or serialized schema was added.

## Performance and lifecycle

This is cold compile/review-time work. PostgreSQL, Redis, Cachex, ETS, GenServer, PubSub, and Oban are not involved. Runtime database and network calls are zero.

The authority is review-ready only. Phase 7A retry, Phase 7B, and Phase 8 remain closed pending their respective gates.
