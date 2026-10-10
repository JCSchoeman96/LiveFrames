# C09D7-A2: CTA Tango proposer output

## Objective and non-goals

This record captures the candidate `ComponentContract` and `ComponentizationPlan` returned by `ComponentizationProposer.propose/2` for the exact A1-frozen tuple. The proposer returned `:proposed`. The pair remains a proposal and has not been reviewed or approved.

A2 does not execute `ComponentReview`, generation-prerequisite validation, or `NativeGenerator`. It does not change production code, tests, the private source artifact, or the A1 SemanticInput.

## Accepted A1 authority

```ini
A1_APPROVED_HEAD=21128cdf9d7ef3216c3c76d0cb9e37c86bbb2ac7
A1_MERGE_SHA=c81cc93ad4ba6c1a8ffbab7bd074eaf379e23137
A1_MERGE_TREE=488965bdce5a4b8e14deac198002b5e04eb6235c
A1_MERGE_PARENT_1=31dc63b9182d7016cb8e6fca841964a891bd7e22
A1_MERGE_PARENT_2=21128cdf9d7ef3216c3c76d0cb9e37c86bbb2ac7
A1_MERGE_SIGNATURE=VALID
A1_POST_MERGE_CI=38037317672
A1_POST_MERGE_CI_RESULT=PASS
```

The A1 freeze in `docs/development/c09d7a_cta_tango_semantic_input_freeze.md` is the sole SemanticInput authority. No frozen decision was changed during A2.

## Canonical A0 DesignDocument

The private JSON was decoded as data. Bricks received a fragment map containing only `components` and `globalClasses`, with the fixture TokenSet and the explicit Automatic.css 4.0.1 structural-variable authority.

```ini
SOURCE_SHA256=73f866a27070c010584babe230b5ffd0c78dc704388fd8b6c286e149a3d93a87
SOURCE_BYTES=10224
COMPONENT_ID=hxambs
ELEMENT_COUNT=15
GLOBAL_CLASS_COUNT=13

CANONICAL_SOURCE_BOUNDARY=fragment-map
SOURCE_LABEL=inline
SOURCE_HASH=ad6ca88c5e814da4829d9785293e0b63bf3f4358bb6a352cfaca4800f465c1e9

IR_VALIDATION=PASS
DESIGN_DOCUMENT_SHA256=4b90b3ce32f8fcec640cea40499e861951137e3c2466931ead3c4436e2c6c9c5
ROOT_NODE_COUNT=1
TOTAL_NODE_COUNT=15
VALUE_BINDINGS=0
COLLECTION_BINDINGS=0
```

The private source file was not added to the repository. No private source text or CSS is included here.

## Accepted SemanticInput summary

The tuple used `contract_id=section_media_call_to_action`, category `section`, module and function intent `media_call_to_action`, boundary `node_000001`, and `multi_root_unsupported=false`.

The eleven public attrs are `heading`, `heading_level`, `eyebrow`, `image_1_src`, `image_1_alt`, `image_2_src`, `image_2_alt`, `image_3_src`, `image_3_alt`, `class`, and `rest`. Their complete shapes appear in the candidate Contract table below and match A1.

The public slots are `body` and `primary_action`. `body` is optional. `primary_action` is required, and its caller owns the action element, label, destination, navigation, and events.

The input contains thirteen A1 render placements, three consumer-supplied image-alt decisions, and four static-content dispositions: promote `heading` and `eyebrow` to attrs, and `body` and `primary_action` to slots. Collection admissions, item fields, collection-count links, binding assignments, and evidence-handling decisions are empty.

```ini
RECOVERY_SEMANTIC_INPUT_VALIDATION=PASS
RECOVERY_CANONICALIZATION_SEMANTIC_DRIFT=NO
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

## Proposer invocation and recovery record

The proposer call was:

```elixir
LiveFrames.ComponentizationProposer.propose(
  design_document,
  canonical_input
)
```

The first execution returned `:proposed`, with zero input diagnostics, zero construction diagnostics, and both candidate structs returned. Terminal truncation lost its detailed candidate and serializer output. That first execution is recorded here and was not concealed.

The accepted proposer authority defines deterministic, side-effect-free construction for identical canonical inputs. The user authorized one replay solely to recover evidence. The replay reproduced the retained first-run outcome and result shape. The first candidate bytes were unavailable, so a direct byte comparison is not claimed.

```ini
INITIAL_PROPOSER_EXECUTION_COUNT=1
INITIAL_PROPOSER_OUTCOME=proposed
RECOVERY_PROPOSER_EXECUTION_COUNT=1
TOTAL_PROPOSER_EXECUTION_COUNT=2
RECOVERY_PROPOSER_OUTCOME=proposed

INITIAL_VS_RECOVERY_OUTCOME_MATCH=YES
INITIAL_VS_RECOVERY_RESULT_SHAPE_MATCH=YES
INITIAL_CANDIDATE_BYTES_AVAILABLE=NO
BYTE_EQUALITY_TO_INITIAL_DIRECTLY_PROVEN=NO
DETERMINISTIC_RECONSTRUCTION_AUTHORITY_USED=YES

RESULT_INPUT_DIAGNOSTIC_COUNT=0
RESULT_CONSTRUCTION_DIAGNOSTIC_COUNT=0
CONTRACT_RETURNED=YES
PLAN_RETURNED=YES
```

## Candidate ComponentContract

```ini
CONTRACT_FORMAT_VERSION=1.0.0
CONTRACT_ID=section_media_call_to_action
CONTRACT_CATEGORY=section
CONTRACT_MODULE_INTENT=media_call_to_action
CONTRACT_FUNCTION_INTENT=media_call_to_action
CONTRACT_APPROVAL_STATUS=proposed
CONTRACT_COLLECTION_INPUT_COUNT=0
CONTRACT_BINDING_PROJECTION_COUNT=0
```

Every attr and slot matches the complete A1 record, including type, required/default values, semantic purpose, validation, accessibility, and provenance. All per-member provenance maps are empty.

| Name | Type | Required | Default | Semantic purpose | Validation | Accessibility |
| --- | --- | --- | --- | --- | --- | --- |
| `class` | string | no | `nil` | additive root CSS class | `{}` | `{}` |
| `eyebrow` | string | no | `nil` | eyebrow text | `{}` | `{}` |
| `heading` | string | yes | `nil` | primary heading text | `{}` | `{}` |
| `heading_level` | integer | no | `2` | heading semantic level | `{"values":[1,2,3,4,5,6]}` | `{}` |
| `image_1_alt` | string | yes | `nil` | first collage image alternative text | `{}` | `{}` |
| `image_1_src` | string | yes | `nil` | first collage image source | `{}` | `{"image_alt_policy":"consumer_supplied","alt_attr_name":"image_1_alt","required_when_source_present":true}` |
| `image_2_alt` | string | yes | `nil` | second collage image alternative text | `{}` | `{}` |
| `image_2_src` | string | yes | `nil` | second collage image source | `{}` | `{"image_alt_policy":"consumer_supplied","alt_attr_name":"image_2_alt","required_when_source_present":true}` |
| `image_3_alt` | string | yes | `nil` | third collage image alternative text | `{}` | `{}` |
| `image_3_src` | string | yes | `nil` | third collage image source | `{}` | `{"image_alt_policy":"consumer_supplied","alt_attr_name":"image_3_alt","required_when_source_present":true}` |
| `rest` | global | no | `nil` | additional root global attributes | `{}` | `{}` |

| Name | Cardinality | Required | Semantic purpose | Consumer responsibility | Validation | Accessibility | Provenance |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `body` | `0..1` | no | consumer-owned rich body markup | caller | `{}` | `{}` | `{}` |
| `primary_action` | `0..1` | yes | primary call-to-action markup | caller owns action element, label, destination, navigation, and events | `{}` | `{}` | `{}` |

Contract provenance has no keys. The candidate has no extra or missing public attrs or slots.

## Candidate ComponentizationPlan

```ini
PLAN_FORMAT_VERSION=1.0.0
PLAN_CONTRACT_ID=section_media_call_to_action
PLAN_DESIGN_DOCUMENT_SHA256=4b90b3ce32f8fcec640cea40499e861951137e3c2466931ead3c4436e2c6c9c5
PLAN_BOUNDARY_NODE_ID=node_000001
PLAN_RENDER_PROJECTION_COUNT=13
```

Every projection matches the A1 target, Design IR node ID, and role. These node IDs are normalized Design IR identities.

| Target kind | Public name | Design node ID | Render role |
| --- | --- | --- | --- |
| attr | `class` | `node_000001` | `root_class` |
| attr | `eyebrow` | `node_000001_000001_000002_000002` | `text_content` |
| attr | `heading` | `node_000001_000001_000002_000001` | `text_content` |
| attr | `heading_level` | `node_000001_000001_000002_000001` | `heading_level` |
| attr | `image_1_alt` | `node_000001_000001_000001_000001_000001_000001` | `asset_alt` |
| attr | `image_1_src` | `node_000001_000001_000001_000001_000001_000001` | `asset_src` |
| attr | `image_2_alt` | `node_000001_000001_000001_000001_000002_000001` | `asset_alt` |
| attr | `image_2_src` | `node_000001_000001_000001_000001_000002_000001` | `asset_src` |
| attr | `image_3_alt` | `node_000001_000001_000001_000001_000003_000001` | `asset_alt` |
| attr | `image_3_src` | `node_000001_000001_000001_000001_000003_000001` | `asset_src` |
| attr | `rest` | `node_000001` | `root_global_attrs` |
| slot | `body` | `node_000001_000001_000002_000003` | `subtree_slot` |
| slot | `primary_action` | `node_000001_000001_000002_000004` | `subtree_slot` |

Plan provenance has no keys.

## Diagnostics and validation

The proposer returned no input or construction diagnostics. The candidate Contract and Plan each have no stored diagnostics.

```ini
CONTRACT_DIAGNOSTIC_COUNT=0
CONTRACT_ERROR_DIAGNOSTICS=0
CONTRACT_FATAL_DIAGNOSTICS=0
CONTRACT_INTRINSIC_VALIDATION=PASS
CONTRACT_REFERENCE_VALIDATION=PASS

PLAN_DIAGNOSTIC_COUNT=0
PLAN_ERROR_DIAGNOSTICS=0
PLAN_FATAL_DIAGNOSTICS=0
PLAN_INTRINSIC_VALIDATION=PASS
PLAN_REFERENCE_VALIDATION=PASS
```

Only `ComponentContract.validate/1`, `ComponentContract.validate_ir_references/2`, `ComponentizationPlan.validate/1`, and `ComponentizationPlan.validate_references/3` were called for candidate validation. No generation validator ran.

## Serializer audit hashes

The existing Contract and Plan serializers returned these exact byte strings. Their bytes and hashes are retained as review evidence only.

```ini
CONTRACT_ENCODE_SHA256=cc62191c5f154e20a9abb9091693b56b59d4595662adabfbb82334babf8caf9c
CONTRACT_ENCODE_BYTES=2970
PLAN_ENCODE_SHA256=19d3a3cc31919239b4cb05e7b3ab37e06820bc514d17ee6edc27dea4a2719c8f
PLAN_ENCODE_BYTES=2082
SERIALIZATION_HASHES_ARE_CANONICAL_IDENTITY=NO
```

The recovery process retained the exact encoded bytes in temporary files outside the repository. Those files are not repository artifacts and were not added to Git.

## Source-independence review

```ini
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
```

The candidate uses the A1 public names and normalized Design IR node identities. It adds no source-specific public member, destination, navigation rule, behavior, or query runtime.

## Downstream risks

Carry both A1 risks forward without solving them in A2:

```ini
KNOWN_DOWNSTREAM_RISK_01=PRIMARY_ACTION_SLOT_PRESENTATION
KNOWN_DOWNSTREAM_RISK_02=FIGURE_IMAGE_STYLE_LOCUS
```

The proposed result does not establish that either risk is resolved.

## Performance and scaling

```ini
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

PROPOSER_SIDE_EFFECTS=NONE
INITIAL_PROPOSER_EXECUTION_COUNT=1
RECOVERY_PROPOSER_EXECUTION_COUNT=1
TOTAL_PROPOSER_EXECUTION_COUNT=2
NO_NEW_WHOLE_TREE_SCAN=YES
```

## A2 lifecycle and A3 boundary

```text
A1_accepted
→ exact_tuple_reconstructed
→ semantic_input_revalidated
→ initial_proposer_execution_recorded_as_proposed
→ evidence_recovery_replay_executed_once
→ recovery_result_classified_as_proposed
→ candidate_pair_verified
→ candidate_pair_recorded
→ A2_review_ready
```

```ini
A2_REVIEW_READY=YES
A2_ACCEPTED=NO
A3_AUTHORIZED=NO
C09D7_B_AUTHORIZED=NO

COMPONENT_REVIEW_EXECUTED=NO
GENERATION_PREREQUISITES_EXECUTED=NO
NATIVE_GENERATOR_EXECUTED=NO
```

This record captures proposer output only. A3 owns the later reviewer gate and any decision to change `approval_status` from `proposed`.
