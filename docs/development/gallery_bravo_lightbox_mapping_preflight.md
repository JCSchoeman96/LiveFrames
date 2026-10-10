# Gallery Bravo lightbox and asset evidence preflight

**Lane:** Frames Conversion / Evidence

**Template:** Gallery Bravo

**Base:** `6ac4902ff029809ed75d21c08cf9da5531e39db3`

**Scope:** Source-neutral evidence and mapping only. This preflight does not authorize implementation.

## Decision

Gallery Bravo has one accepted repeated attachment collection, owned by QS-07 `c74cb5`. The repeat boundary is supported, while the two values needed to render the source faithfully are not: `{post_id}` does not map to a renderable asset value, and the wrapped `{query_results_count:c74cb5}` text does not map to a count value. There is also no accepted stable item identity for Lightbox state.

The generic Lightbox family is already defined by the accepted Interaction Model as `Dialog + CollectionNavigation`. This preflight applies that vocabulary without creating a Gallery BehaviorBinding or choosing occurrence policies. The source evidence does not establish its complete runtime, accessibility behavior, controls, or history behavior.

P7 has a separate repository-truth discrepancy. PR #170 merged B1 code onto main, while the P7 plan still marks version 1.0.6 as a proposed amendment and B1 as authorized but blocked and not implemented. This preflight records both facts and does not reconcile them.

## Accepted source evidence

The repository authorities record:

```text
GALLERY_BRAVO_PRESENT=YES
ATTACHMENT_QUERY_PRESENT=YES
SOURCE_RANDOM_ORDERING_PRESENT=YES
SOURCE_UNBOUNDED_LIMIT_PRESENT=YES
LIGHTBOX_LINK_SETTINGS_PRESENT=YES
RESULT_COUNT_SOURCE_PRESENT=YES
RESPONSIVE_GRID_PRESENT=YES
EXPANDED_LIGHTBOX_CAPTURE_PRESENT=YES
CAPTURE_SHOWS_ITEM_POSITION=5_OF_24
SOURCE_LIGHTBOX_COMPLETE_RUNTIME=NOT_PROVEN
```

The `5 of 24` text is capture evidence. It does not establish a fixed collection size, initial active item, or source navigation behavior. Source query configuration is provenance. LiveFrames does not execute or reproduce that query.

## Collection and host data boundary

C09C2 admits QS-07 because it has a JSON query object, `hasLoop=true`, and a linked image child. The wrapper is the repeat root. There is no admitted Gallery parent collection.

```text
QS07_OWNER=c74cb5
GALLERY_QUERY_OWNER_COUNT=1
GALLERY_COLLECTION_BINDING_COUNT=1
GALLERY_REPEAT_BOUNDARY=SUPPORTED
GALLERY_COLLECTION_BINDING=SUPPORTED
GALLERY_COLLECTION_OWNER=c74cb5
GALLERY_PARENT_COLLECTION_BINDING=NONE
```

The query records attachment source, taxonomy filtering, `orderby=rand`, and `posts_per_page=-1`. These support source intent only:

```text
SOURCE_RANDOM_ORDERING_INTENT=SUPPORTED
SOURCE_UNBOUNDED_LIMIT_INTENT=SUPPORTED
SOURCE_QUERY_EXECUTION_IN_LIVEFRAMES=NO
SOURCE_RANDOMIZATION_IN_LIVEFRAMES=NO
CALLER_COLLECTION_REQUIRED=YES
```

The caller supplies a bounded collection. Host Phoenix owns data fetching, database/Ash/API/CMS access, authorization, tenant isolation, taxonomy and filter meaning, ordering and randomization, pagination and windowing, result bounds, and caching. LiveFrames must not carry the source's unbounded limit into a frontend input contract.

## Renderable asset gap

The source image element `bbf168` uses `{post_id}` under collection `c74cb5`. C09C2 identifies an attachment ID but admits no asset `ValueBinding`, because it does not establish a value the frontend asset target can consume.

```text
GALLERY_POST_ID_SOURCE_EXISTENCE=SUPPORTED
GALLERY_ASSET_VALUE_BINDING=NO
GALLERY_RENDERABLE_ASSET_BINDING=NOT_ESTABLISHED
GALLERY_COLLECTION_ITEM_ASSET_KEY=NOT_ESTABLISHED
GALLERY_RENDERABLE_MEDIA_FROM_COLLECTION=NOT_ESTABLISHED
POST_ID_AS_MEDIA_PRIMARY=NOT_AUTHORIZED
POST_ID_AS_MEDIA_ID=NOT_AUTHORIZED
POST_ID_AS_ASSET_URL=NOT_AUTHORIZED
```

Do not map this value to `media.primary`, `media.id`, `asset.id`, `asset.url`, or `attachment.url`. The `{featured_image}` mapping used by Slider or Milan does not transfer to `{post_id}`. If native Gallery reproduction needs an invented renderable asset key, stop with `STOP=GALLERY_ASSET_BINDING_INVENTION_REQUIRED` and route the gap to frontend-data and asset-binding authority.

## Stable item identity

The Lightbox state model uses `active_item_id`, but Gallery has no accepted normalized stable collection-item identity. The Interaction Model permits caller-supplied stable repeated-item identity when state must survive reorder. No source ID or position is an authorized substitute.

```text
GALLERY_STABLE_ITEM_IDENTITY=NOT_ESTABLISHED
POST_ID_AS_STABLE_ITEM_ID=NOT_AUTHORIZED
ARRAY_INDEX_AS_STABLE_ITEM_ID=NOT_AUTHORIZED
```

Do not use `{post_id}`, raw Bricks element IDs, array indexes, DOM order, query result position, or capture position as durable `active_item_id`. Route stable Gallery item identity to frontend-data and componentization authority. If a complete occurrence needs fabricated identity, stop with `STOP=GALLERY_STABLE_ITEM_IDENTITY_INVENTION_REQUIRED`.

## Result-count gap

The source has count token `{query_results_count:c74cb5}` in text element `22de9a`. C09A records a 43-character setting with non-empty text before and after the token. C09C2 admits count binding only for an exact whole-token setting, so this occurrence has no `ValueBinding`.

```text
RESULT_COUNT_SEMANTIC_SOURCE_EXISTENCE=SUPPORTED
RESULT_COUNT_REFERENCED_COLLECTION=c74cb5
RESULT_COUNT_EXACT_WHOLE_TOKEN=NO
RESULT_COUNT_VALUE_BINDING=NO
RESULT_COUNT_NORMALIZATION=UNSUPPORTED_INTERPOLATION
GALLERY_RESULT_COUNT_RENDERING=NOT_ESTABLISHED
```

Do not discard surrounding text, emit a count-only binding, calculate the array length and call it source-equivalent, or add interpolation-template support here. If reproducing the text requires a Design IR change or interpolation, stop with `STOP=RESULT_COUNT_INTERPOLATION_ARCHITECTURE_REQUIRED` and route it to frontend-data and componentization authority.

## Lightbox family and lifecycle

The current accepted Interaction Model resolves the older matrix's open Lightbox/Dialog choice. The generic target family is:

```text
GENERIC_LIGHTBOX_TARGET_FAMILY=SUPPORTED
GENERIC_DIALOG_TARGET_FAMILY=SUPPORTED
GENERIC_COLLECTION_NAVIGATION=SUPPORTED
GALLERY_LIGHTBOX_TARGET_FAMILY=SUPPORTED
HISTORICAL_MATRIX_LIGHTBOX_DIALOG_CHOICE=OPEN
CURRENT_ACCEPTED_BEHAVIOR_LIGHTBOX_COMPOSITION=DIALOG_PLUS_COLLECTION_NAVIGATION
```

The accepted semantic lifecycle is recorded here as a requirement, not implemented behavior:

```text
state: closed | open(active_item_id)
initial_state: closed

closed --open(valid_item + valid_dialog_binding)--> open(active_item_id)
open(item) --next(valid_collection_transition)--> open(next_item)
open(item) --previous(valid_collection_transition)--> open(previous_item)
open(item) --jump(valid_target_item)--> open(target_item)
open(item) --close--> closed
open(item) --Escape--> closed
```

Next, previous, and jump stay within the owning collection. Collection boundary policy is `clamp | wrap`, with canonical default `clamp` when an occurrence does not select a policy. Gallery has not selected one. Guards require a valid collection item, membership in the owning collection, a valid Dialog relationship, and valid target references. Effects open or close the Dialog, synchronize its active media item, apply Dialog accessibility state, and manage focus and inertness through Dialog ownership.

```text
LIGHTBOX_COLLECTION_CANDIDATE=c74cb5
SOURCE_COLLECTION_BOUNDARY_POLICY=NOT_ESTABLISHED
CANONICAL_LIGHTBOX_DEFAULT_BOUNDARY_POLICY=CLAMP
GALLERY_OCCURRENCE_BOUNDARY_POLICY_SELECTED=NO
GALLERY_LIGHTBOX_BEHAVIOR_BINDING_CREATED=NO
EXACT_LIGHTBOX_COLLECTION_TARGET_RELATION=NOT_CREATED
```

The source proves one Gallery collection and that the lightbox opens an image set. Treat `c74cb5` as the only candidate source collection. Evidence does not establish an exact controlled-target relation, so do not create one.

Lightbox link settings exist, but they do not identify an exact trigger node, generated `href`, DOM selector, event listener, or source runtime call.

```text
LIGHTBOX_OPEN_TRIGGER_CONFIGURATION_EXISTENCE=SUPPORTED
LIGHTBOX_OPEN_TRIGGER_NORMALIZED_MAPPING=PARTIAL
```

Do not use arbitrary source selectors or invent Gallery-specific transitions. If the occurrence mapping requires either, stop with `STOP=ARBITRARY_SELECTOR_MAPPING_REQUIRED` or `STOP=LIGHTBOX_STATE_MACHINE_REDESIGN_ATTEMPT` as applicable.

## Source evidence and target accessibility

The source captures do not prove the following behaviors:

```text
SOURCE_ESCAPE_BEHAVIOR=NOT_PROVEN
SOURCE_INITIAL_FOCUS=NOT_PROVEN
SOURCE_FOCUS_CONTAINMENT=NOT_PROVEN
SOURCE_FOCUS_RESTORATION=NOT_PROVEN
SOURCE_BACKGROUND_INERTNESS=NOT_PROVEN
SOURCE_ACCESSIBLE_NAMES=NOT_PROVEN
SOURCE_NESTED_DIALOG_POLICY=NOT_PROVEN
SOURCE_NEXT_CONTROL_EXISTENCE=NOT_PROVEN
SOURCE_PREVIOUS_CONTROL_EXISTENCE=NOT_PROVEN
SOURCE_ITEM_PICKER_EXISTENCE=NOT_PROVEN
SOURCE_ARROW_KEY_NAVIGATION=NOT_PROVEN
```

Separately, accepted target Dialog authority requires an accessible name, a focus destination, Escape dismissal, focus containment, focus restoration, and modal background inertness. Do not treat target requirements as proof of source compliance.

```text
TARGET_DIALOG_ESCAPE_REQUIREMENT=SUPPORTED_BY_AUTHORITY
TARGET_DIALOG_FOCUS_CONTAINMENT=SUPPORTED_BY_AUTHORITY
TARGET_DIALOG_FOCUS_RESTORATION=SUPPORTED_BY_AUTHORITY
TARGET_DIALOG_MODALITY_INERTNESS=SUPPORTED_BY_AUTHORITY
ACCESSIBILITY=PARTIAL
```

Lightbox history is opt-in. Source evidence does not establish it:

```text
SOURCE_HISTORY_BEHAVIOR=NOT_PROVEN
TARGET_HISTORY_REQUIRED=NO
GALLERY_HISTORY_POLICY_SELECTED=NO
```

## Runtime, fallback, performance, and security

Gallery data belongs to `caller_data`; Lightbox state belongs to `browser_local`. No current evidence requires server events, server-owned state, or polling.

```text
GALLERY_DATA_LAYER=caller_data
LIGHTBOX_STATE_LAYER=browser_local
SERVER_EVENT_REQUIRED=NO_CURRENT_EVIDENCE
SERVER_STATE_REQUIRED=NO_CURRENT_EVIDENCE
SERVER_POLLING=NO
REDIS=N/A
POSTGRES_LIGHTBOX_STATE=N/A
ETS=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
```

The shared RuntimeInstance lifecycle remains the future owner of mounted resources:

```text
no instance -> mounted
mounted -> active
mounted/active -> unavailable on recoverable invalidity
unavailable -> active after valid reconciliation
mounted/active/unavailable -> destroyed when owner removed
```

`destroyed` is terminal. Future cleanup releases owned listeners, focus ownership, Dialog/inertness state, scroll lock when applicable, and transient navigation state. No runtime code is authorized here.

The target requires a useful no-JavaScript fallback, with media visible or a normal media link usable. The Gallery occurrence cannot realize that requirement until the asset binding is resolved:

```text
NO_JS_LIGHTBOX_FALLBACK_REQUIRED=YES
GALLERY_NO_JS_MEDIA_FALLBACK_REALIZATION=BLOCKED_BY_ASSET_BINDING
```

Expected rendering work is O(items), Lightbox state is O(1), and server interaction-state cost is zero by default. Reuse the caller collection rather than copying the media list into behavior state. The host must bound results. At 100,000 concurrent users, Redis Lightbox state, Postgres Lightbox writes, PubSub Lightbox traffic, and a GenServer per Gallery are all N/A. Media delivery and CDN concerns are separate from behavior state.

Security requirements for any later implementation:

- Never execute source query configuration, proprietary runtime code, imported scripts, or markup.
- Keep `{post_id}` as inert source evidence. Do not turn an attachment ID into a URL without accepted asset authority.
- Validate eventual asset and navigation URLs through existing URL and asset rules.
- Do not turn source IDs, classes, or selectors into arbitrary runtime selectors.
- Keep caller authorization and tenant isolation, random ordering, and taxonomy semantics host-owned.
- Scope Dialog focus and inertness ownership to each runtime instance.
- Do not create input-derived atoms, modules, or event names.
- Missing asset or item identity fails closed.

## Responsive and static mapping

The evidence supports a responsive grid but no exact Gallery breakpoint. The global breakpoint vocabulary does not establish a Gallery-specific value. Generic native styling integration is present on main; Gallery-specific style work remains partial.

```text
RESPONSIVE_GRID_EXISTENCE=SUPPORTED
GALLERY_RESPONSIVE_BREAKPOINT=NOT_ESTABLISHED
GENERIC_NATIVE_STYLING_INTEGRATION=PRESENT_ON_MAIN
GALLERY_SPECIFIC_STYLE_MAPPING=PARTIAL
STATIC=PARTIAL
```

Unmapped static details include grid columns and gaps, responsive columns and gaps, media sizing and aspect handling, lightbox trigger presentation, focus-visible presentation, and fallback media/link presentation. This preflight adds no CSS.

## Dependency and P7 governance

The historical conversion matrix records an external decision as required because it predates the accepted source-neutral Lightbox contract. Current evidence and accepted behavior do not require a third-party runtime package.

```text
HISTORICAL_MATRIX_EXTERNAL_STATUS=EXTERNAL_DECISION_REQUIRED
CURRENT_LIGHTBOX_SEMANTIC_TARGET=SUPPORTED
THIRD_PARTY_LIGHTBOX_LIBRARY_REQUIRED=NO_CURRENT_EVIDENCE
SOURCE_LIGHTBOX_RUNTIME_DEPENDENCY_CARRIED_FORWARD=NO
EXTERNAL_DEPENDENCY=NONE
```

`NONE` means current evidence and authority require no external dependency. It does not authorize implementation or a package choice.

The P7 plan on this base records version 1.0.6 as a proposed authority amendment, version 1.0.5 as accepted, and B1 as authorized but blocked and not implemented. Main also contains the B1 code merged by PR #170. These repository facts conflict; this preflight records the discrepancy and makes no authority decision.

```text
P7_PLAN_VERSION_PRESENT_ON_MAIN=1.0.6
P7_1_0_6_STATUS=PROPOSED_AUTHORITY_AMENDMENT
P7_1_0_5_STATUS=ACCEPTED
P7_B1_CODE_PRESENT_ON_MAIN=YES
P7_B1_MERGED_PR=170
P7_B1_IMPLEMENTED=NO
P7_B1_CODE_VS_PLAN_LEDGER_DISCREPANCY=PRESENT
P7_1_0_6_OWNER_ACCEPTANCE=NOT_ESTABLISHED_BY_THIS_PREFLIGHT
P7_B1_OWNER_ACCEPTANCE=NOT_ESTABLISHED_BY_THIS_PREFLIGHT
```

The evidence pass relies on accepted Interaction Model semantics and does not create P7-B1 persisted bindings. If it required treating the B1 struct implementation as accepted authority, stop with `STOP=P7_AUTHORITY_LEDGER_RECONCILIATION_REQUIRED`. Do not edit the P7 plan or infer owner acceptance from the merge.

## Implementation boundary

This preflight creates no `BehaviorContract`, `BehaviorBinding`, `PrimitiveRef`, controlled targets, `FocusPolicy`, `KeyboardPolicy`, initial state, primitive policy values, binding ID, or ordinal.

```text
GALLERY_BEHAVIOR_BINDING_CREATED=NO
PRIMITIVE_DEFINITION_VERSION_SELECTED=NO
BEHAVIOR_IMPLEMENTATION_AUTHORIZED=NO
```

The exact Gallery caller API belongs to componentization. The generic Lightbox state machine and Dialog focus, Escape, and restoration semantics are already owned by the accepted Interaction Model. Gallery occurrence mapping follows only after the data identity and relationships are accepted.

## Evidence ledger

```text
GALLERY_BRAVO_PRESENT=YES

GALLERY_QUERY_OWNER_COUNT=1
QS07_OWNER=c74cb5
GALLERY_COLLECTION_BINDING_COUNT=1
GALLERY_REPEAT_BOUNDARY=SUPPORTED
GALLERY_COLLECTION_BINDING=SUPPORTED
GALLERY_PARENT_COLLECTION_BINDING=NONE

SOURCE_RANDOM_ORDERING_INTENT=SUPPORTED
SOURCE_UNBOUNDED_LIMIT_INTENT=SUPPORTED
SOURCE_QUERY_EXECUTION_IN_LIVEFRAMES=NO
SOURCE_RANDOMIZATION_IN_LIVEFRAMES=NO
CALLER_COLLECTION_REQUIRED=YES

GALLERY_POST_ID_SOURCE_EXISTENCE=SUPPORTED
GALLERY_ASSET_VALUE_BINDING=NO
GALLERY_RENDERABLE_ASSET_BINDING=NOT_ESTABLISHED
GALLERY_COLLECTION_ITEM_ASSET_KEY=NOT_ESTABLISHED
GALLERY_RENDERABLE_MEDIA_FROM_COLLECTION=NOT_ESTABLISHED

GALLERY_STABLE_ITEM_IDENTITY=NOT_ESTABLISHED
POST_ID_AS_STABLE_ITEM_ID=NOT_AUTHORIZED
ARRAY_INDEX_AS_STABLE_ITEM_ID=NOT_AUTHORIZED

RESULT_COUNT_SEMANTIC_SOURCE_EXISTENCE=SUPPORTED
RESULT_COUNT_REFERENCED_COLLECTION=c74cb5
RESULT_COUNT_EXACT_WHOLE_TOKEN=NO
RESULT_COUNT_VALUE_BINDING=NO
RESULT_COUNT_NORMALIZATION=UNSUPPORTED_INTERPOLATION
GALLERY_RESULT_COUNT_RENDERING=NOT_ESTABLISHED

LIGHTBOX_LINK_SETTINGS_PRESENT=YES
EXPANDED_LIGHTBOX_CAPTURE_PRESENT=YES
CAPTURE_SHOWS_ITEM_POSITION=5_OF_24
GALLERY_FIXED_ITEM_COUNT=NOT_AUTHORIZED

GENERIC_LIGHTBOX_TARGET_FAMILY=SUPPORTED
GENERIC_DIALOG_TARGET_FAMILY=SUPPORTED
GENERIC_COLLECTION_NAVIGATION=SUPPORTED
CURRENT_ACCEPTED_BEHAVIOR_LIGHTBOX_COMPOSITION=DIALOG_PLUS_COLLECTION_NAVIGATION
LIGHTBOX_COLLECTION_CANDIDATE=c74cb5
LIGHTBOX_OPEN_TRIGGER_CONFIGURATION_EXISTENCE=SUPPORTED
LIGHTBOX_OPEN_TRIGGER_NORMALIZED_MAPPING=PARTIAL

SOURCE_NEXT_CONTROL_EXISTENCE=NOT_PROVEN
SOURCE_PREVIOUS_CONTROL_EXISTENCE=NOT_PROVEN
SOURCE_ITEM_PICKER_EXISTENCE=NOT_PROVEN
SOURCE_ARROW_KEY_NAVIGATION=NOT_PROVEN

SOURCE_ESCAPE_BEHAVIOR=NOT_PROVEN
SOURCE_INITIAL_FOCUS=NOT_PROVEN
SOURCE_FOCUS_CONTAINMENT=NOT_PROVEN
SOURCE_FOCUS_RESTORATION=NOT_PROVEN
SOURCE_BACKGROUND_INERTNESS=NOT_PROVEN

TARGET_DIALOG_ESCAPE_REQUIREMENT=SUPPORTED_BY_AUTHORITY
TARGET_DIALOG_FOCUS_CONTAINMENT=SUPPORTED_BY_AUTHORITY
TARGET_DIALOG_FOCUS_RESTORATION=SUPPORTED_BY_AUTHORITY
TARGET_DIALOG_MODALITY_INERTNESS=SUPPORTED_BY_AUTHORITY

SOURCE_COLLECTION_BOUNDARY_POLICY=NOT_ESTABLISHED
CANONICAL_LIGHTBOX_DEFAULT_BOUNDARY_POLICY=CLAMP
GALLERY_OCCURRENCE_BOUNDARY_POLICY_SELECTED=NO

SOURCE_HISTORY_BEHAVIOR=NOT_PROVEN
TARGET_HISTORY_REQUIRED=NO
GALLERY_HISTORY_POLICY_SELECTED=NO

HISTORICAL_MATRIX_EXTERNAL_STATUS=EXTERNAL_DECISION_REQUIRED
THIRD_PARTY_LIGHTBOX_LIBRARY_REQUIRED=NO_CURRENT_EVIDENCE
EXTERNAL_DEPENDENCY=NONE

RESPONSIVE_GRID_EXISTENCE=SUPPORTED
GALLERY_RESPONSIVE_BREAKPOINT=NOT_ESTABLISHED
GENERIC_NATIVE_STYLING_INTEGRATION=PRESENT_ON_MAIN
GALLERY_SPECIFIC_STYLE_MAPPING=PARTIAL

NO_JS_LIGHTBOX_FALLBACK_REQUIRED=YES
GALLERY_NO_JS_MEDIA_FALLBACK_REALIZATION=BLOCKED_BY_ASSET_BINDING

P7_PLAN_VERSION_PRESENT_ON_MAIN=1.0.6
P7_1_0_6_STATUS=PROPOSED_AUTHORITY_AMENDMENT
P7_1_0_5_STATUS=ACCEPTED
P7_B1_CODE_PRESENT_ON_MAIN=YES
P7_B1_MERGED_PR=170
P7_B1_IMPLEMENTED=NO
P7_B1_CODE_VS_PLAN_LEDGER_DISCREPANCY=PRESENT
P7_1_0_6_OWNER_ACCEPTANCE=NOT_ESTABLISHED_BY_THIS_PREFLIGHT
P7_B1_OWNER_ACCEPTANCE=NOT_ESTABLISHED_BY_THIS_PREFLIGHT

GALLERY_BEHAVIOR_BINDING_CREATED=NO
PRIMITIVE_DEFINITION_VERSION_SELECTED=NO
BEHAVIOR_IMPLEMENTATION_AUTHORIZED=NO

LIGHTBOX_STATE_LAYER=browser_local
GALLERY_DATA_LAYER=caller_data
SERVER_EVENT_REQUIRED=NO_CURRENT_EVIDENCE
SERVER_STATE_REQUIRED=NO_CURRENT_EVIDENCE
SERVER_POLLING=NO

STATIC=PARTIAL
BEHAVIOR=PARTIAL
DATA=PARTIAL
ACCESSIBILITY=PARTIAL
EXTERNAL_DEPENDENCY=NONE
OVERALL=NOT_READY
NATIVE_READY=NO

PRIVATE_SOURCE_INSPECTION_REQUIRED=NO
PRIVATE_SOURCE_EXECUTION=NO
PRIVATE_SOURCE_NEW_SEMANTICS=NONE
IMPLEMENTATION_AUTHORIZED=NO
```

`DATA=PARTIAL` because the collection boundary is supported but renderable asset binding, result-count binding, and stable item identity remain unresolved. `BEHAVIOR=PARTIAL` because generic Lightbox semantics exist but Gallery occurrence inputs and relationships remain incomplete, and no BehaviorBinding is authorized. `ACCESSIBILITY=PARTIAL` because target Dialog semantics are known while source behavior and occurrence relationships remain unproven.

## Blocker routing

| Gap | Owner |
| --- | --- |
| Gallery collection boundary | Existing C09C2 authority |
| `{post_id}` renderable asset | Frontend-data / asset-binding authority |
| Wrapped result-count interpolation | Frontend-data and componentization |
| Stable repeated-item identity | Frontend-data and componentization |
| Generic Lightbox state machine | Accepted Interaction Model |
| Gallery-specific Lightbox occurrence mapping | Behavior/P7 after data identity is resolved |
| Dialog focus, Escape, and restoration semantics | Accepted Interaction Model |
| Responsive grid styles | Static lane |
| Final Gallery caller API | Componentization |
| Query, randomization, and taxonomy execution | Host Phoenix |
| P7-B1 code versus plan discrepancy | P7 governance owner |

## Source authority references

- `docs/development/frames_native_conversion_matrix.md`
- `docs/development/c07x_unsupported_surface_inventory.md`
- `docs/development/c09a_query_dynamic_data_contract.md`
- `docs/development/c09b_frontend_binding_authority.md`
- `docs/development/c09c2_bricks_binding_mapping_authority.md`
- `docs/09_INTERACTION_MODEL.md`
- `docs/development/p7_interaction_conversion_implementation_plan.md`
- `docs/development/c09d6_native_generation_authority.md`
- `docs/04_SOURCE_AND_PROVENANCE.md`
