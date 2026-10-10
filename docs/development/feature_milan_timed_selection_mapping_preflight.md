# Feature Milan timed selection mapping preflight

## Purpose and decision

This preflight maps the owner-reviewed Feature Milan evidence to the current frontend-data and Behavior authorities. It does not authorize implementation. Unknown source behavior remains unknown. The embedded source script was inspected as text only; it was not executed.

Milan has two admitted frontend collections and three source query owners. Its title and primary media bindings are normalized. The `{post_content:16}` occurrence remains an evidence-insufficient `content.body` binding with an opaque modifier. The owner-supplied Bricks export establishes positional synchronization, the interval occurrence, manual timer stop, and ordered wrap behavior. It does not establish durable cross-collection item identity, actual rendered cardinality equality, complete Tabs semantics, lifecycle timer/listener cleanup, or a Milan-specific responsive breakpoint.

```text
STATIC=PARTIAL
BEHAVIOR=PARTIAL
DATA=PARTIAL
ACCESSIBILITY=PARTIAL
EXTERNAL_DEPENDENCY=NONE
OVERALL=NOT_READY
NATIVE_READY=NO
IMPLEMENTATION_AUTHORIZED=NO
```

## Evidence and authority basis

This mapping relies on the accepted repository authorities below for source evidence and frontend and Behavior rules:

- `docs/development/c07x_unsupported_surface_inventory.md` for the historical Feature Milan behavior summary and source-evidence limits.
- `docs/development/c09a_query_dynamic_data_contract.md` for query-owner and dynamic-expression evidence.
- `docs/development/c09b_frontend_binding_authority.md` and `docs/development/c09c2_bricks_binding_mapping_authority.md` for frontend-only bindings and exact admission outcomes.
- `docs/09_INTERACTION_MODEL.md` for Tabs, TimerPolicy, focus, keyboard, accessibility, motion, runtime, and security rules.
- `docs/development/frames_native_conversion_matrix.md`, `docs/development/c07x_unsupported_surface_inventory.md`, `docs/development/c09d6_native_generation_authority.md`, and `docs/04_SOURCE_AND_PROVENANCE.md` for conversion boundaries and provenance.

The current P7 plan is version 1.0.9, a proposed authority amendment. P7-B4 is implemented and accepted under PR #185. P7-C remains blocked pending acceptance of v1.0.9. This preflight records the tracer evidence and target authority; it does not authorize runtime implementation.

The owner-supplied artifact is `private_reference/frames/staging-2026-09/feature-section-milan/bricks-component-ybsqrl-feature-section-milan.json`, SHA-256 `f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132`. It records dynamic feature data, tab-like ARIA markup, separate desktop/mobile media groups, a 5000 ms interval read from the root custom property `--animation-duration`, first-item selection, collection-order advance with wrap and no skips, and positional media synchronization. Its repeated feature-control template starts with the source animation data flag true. A feature-control click sets every such flag false and clears the interval. The timer callback returns without advancing if any control flag is false; that return does not clear an interval that is still active. The admitted mutation to false occurs on the click path that also clears the interval. The artifact has no false-to-true or restart path. It does not prove durable cross-collection identity, actual rendered cardinality equality, complete Tabs relationships, or lifecycle cleanup.

## Required evidence ledger

```text
FEATURE_MILAN_PRESENT=YES
DYNAMIC_FEATURE_DATA_PRESENT=YES
TAB_LIKE_ARIA_MARKUP_PRESENT=YES
SEPARATE_DESKTOP_AND_MOBILE_MEDIA_GROUPS_PRESENT=YES
TIMED_ACTIVE_FEATURE_ROTATION_PRESENT=YES
SELECTED_HIDDEN_STATE_CHANGES=SUPPORTED

FEATURE_MILAN_QUERY_OWNER_COUNT=3
FEATURE_MILAN_COLLECTION_BINDING_COUNT=2

QS02_OWNER=ebbb6e
QS03_NESTED_OWNER=05e604
QS03_SEPARATE_OWNER=b71f5d

QS02_COLLECTION_BINDING=SUPPORTED
QS03_05E604_COLLECTION_BINDING=NO
QS03_B71F5D_COLLECTION_BINDING=SUPPORTED

FEATURE_TITLE_BINDING=SUPPORTED
FEATURE_PRIMARY_MEDIA_BINDING=SUPPORTED
SEPARATE_MEDIA_COLLECTION_BINDING=SUPPORTED
SEPARATE_MEDIA_VALUE_BINDING=SUPPORTED

FEATURE_BODY_BASE_FIELD=SUPPORTED
FEATURE_BODY_MODIFIER_SEMANTICS=NOT_ESTABLISHED
FEATURE_BODY_BINDING=EVIDENCE_INSUFFICIENT

FEATURE_TO_MEDIA_SYNCHRONIZATION_EXISTENCE=SUPPORTED
FEATURE_MEDIA_CORRELATION=POSITIONAL_INDEX
POSITIONAL_SYNCHRONIZATION_SUPPORTED=YES
CROSS_COLLECTION_ITEM_CORRELATION=POSITIONAL_INDEX
CROSS_COLLECTION_STABLE_IDENTITY=NOT_ESTABLISHED
CROSS_COLLECTION_ONE_TO_ONE_IDENTITY=NOT_CLAIMED
SOURCE_POSITIONAL_SYNCHRONIZATION=PROVEN
SOURCE_CORRELATION_MECHANISM=NUMERIC_POSITION
SOURCE_RENDERED_CARDINALITY_EQUALITY=NOT_PROVEN
SOURCE_BOTH_QUERY_LIMITS=POSTS_PER_PAGE_4
CALLER_ORDER_IS_SEMANTIC_FOR_MILAN_V1=YES
STATE_PRESERVATION_ACROSS_REORDER=NO

INITIAL_ACTIVE_ITEM=FIRST_ITEM
FEATURE_SELECTION_EXISTENCE=SUPPORTED
TAB_LIKE_ARIA_MARKUP_PRESENT=YES
TABLIST_ROLE=YES
TAB_ROLE=YES
ARIA_SELECTED=YES
TABPANEL_ROLE=NO
ARIA_CONTROLS=NO
CONTROL_ID_TO_PANEL_ID_RELATION=NO
ROVING_TABINDEX=NO
KEYDOWN_HANDLER=NO
ARROW_KEY_BEHAVIOR=NO
SOURCE_CONTROL_ELEMENT=button
SOURCE_CONTROL_TYPE=button
ENTER_SPACE_ACTIVATION=NO_CUSTOM_HANDLER; BROWSER_BEHAVIOR_NOT_VERIFIED
GENERIC_TABS_TARGET_FAMILY=NOT_SELECTED_FOR_MILAN_V1
FEATURE_MILAN_TABS_CANDIDATE=NO
TAB_TO_PANEL_RELATIONSHIP=NOT_ESTABLISHED
ARIA_CONTROLS_RELATIONSHIP=NOT_PROVEN
TAB_FOCUS_MODEL=NOT_ESTABLISHED
TAB_KEYBOARD_MODEL=NOT_ESTABLISHED
TAB_ACTIVATION_MODE=NOT_ESTABLISHED
TAB_ORIENTATION=NOT_ESTABLISHED
FEATURE_MILAN_TABS_MAPPING=REJECTED_FOR_V1

TIMED_ROTATION_EXISTENCE=SUPPORTED
ACTIVE_FEATURE_INDEX_ADVANCES_ON_INTERVAL=SUPPORTED
CLICK_AFFECTS_ACTIVE_FEATURE_OR_ROTATION=SUPPORTED
MEDIA_POSITION_CHANGE_EXISTENCE=SUPPORTED
CLICK_ROTATION_SIDE_EFFECT=FEATURE_CONTROL_CLICK_CLEARS_TIMER
ADVANCE_USES_COLLECTION_ORDER=YES
WRAPS_LAST_TO_FIRST=YES
SKIPS_ITEMS=NO

TIMER_INTERVAL_MS=5000
TIMER_INTERVAL_SOURCE=ROOT_CUSTOM_CSS_PROPERTY_--animation-duration
TIMER_START_POLICY=ON_INITIALIZATION
MANUAL_TRIGGER_SET=FEATURE_CONTROL_CLICK
TIMER_CLEARED=YES_ON_CONTROL_CLICK
TIMER_RESTART_PATH=NONE_IN_ARTIFACT
TIMER_RESET_PATH=NONE_IN_ARTIFACT
ROTATION_CAN_RESUME_WITHOUT_REMOUNT=NO
SOURCE_TIMER_ELIGIBILITY_FLAG=data-should-animate
SOURCE_INITIAL_ELIGIBILITY=ALL_REPEATED_FEATURE_CONTROLS_TRUE
SOURCE_MANUAL_ACTIVATION_EFFECT=ALL_FEATURE_CONTROLS_FALSE_AND_INTERVAL_CLEARED
SOURCE_TIMER_CALLBACK_GUARD=ADVANCE_ONLY_IF_ALL_CONTROL_FLAGS_EXACTLY_TRUE
SOURCE_INELIGIBLE_CALLBACK=RETURNS_WITHOUT_SELECTION_ADVANCE
SOURCE_INTERVAL_CAN_EXIST_WHILE_GUARD_FALSE=YES_CALLBACK_RETURN_DOES_NOT_CLEAR_INTERVAL
ADMITTED_SOURCE_MUTATION_PATH_TO_FALSE=MANUAL_CLICK_ALSO_CLEARS_INTERVAL
SOURCE_FALSE_TO_TRUE_PATH=NOT_PRESENT
SOURCE_PAUSE_ON_FOCUS_POLICY=NOT_ESTABLISHED
SOURCE_PAUSE_ON_HOVER_POLICY=NOT_ESTABLISHED
SOURCE_REDUCED_MOTION_COMPLIANCE=NOT_CLAIMED
SOURCE_TIMER_CLEANUP=CLICK_HANDLER_CLEAR_ONLY; LIFECYCLE_CLEANUP_NOT_PROVEN
SOURCE_LISTENER_CLEANUP=NO_EXPLICIT_REMOVAL_PATH_IN_ARTIFACT
TIMER_RESOURCE_CLEANUP_OWNER=SHARED_RUNTIME_LIFECYCLE

TIMER_POLICY_REQUIRED_IF_TIMED_ROTATION_RETAINED=YES
FEATURE_MILAN_TIMER_MAPPING=EXACT_OCCURRENCE_PROPOSED
FEATURE_MILAN_CAROUSEL_MAPPING=REJECTED_FOR_V1
FEATURE_MILAN_AUTOMATIC_TABS_MAPPING=NOT_SELECTED_FOR_V1
SOURCE_TIMER_ELIGIBILITY_FLAG_RUNTIME_AUTHORITY=NO
SOURCE_DATA_ATTRIBUTE_IN_BEHAVIOR_CONTRACT=NO
TIMER_ELIGIBILITY_SERIALIZED_FIELD=NO
NORMALIZED_TIMER_ADVANCE_ELIGIBILITY=timer_lifecycle_running
TARGET_EQUAL_CARDINALITY_RULE=FAIL_CLOSED_RUNTIME_INVARIANT

DESKTOP_MEDIA_GROUP_PRESENT=YES
MOBILE_MEDIA_GROUP_PRESENT=YES
RESPONSIVE_PRESENTATION_EXISTENCE=SUPPORTED
FEATURE_MILAN_RESPONSIVE_BREAKPOINT=NOT_ESTABLISHED
GENERIC_NATIVE_STYLING_INTEGRATION=PRESENT_ON_MAIN
FEATURE_MILAN_SPECIFIC_STYLE_MAPPING=PARTIAL

P7_PLAN_VERSION=1.0.9
P7_1_0_9_STATUS=PROPOSED_AUTHORITY_AMENDMENT
P7_B4=IMPLEMENTED_ACCEPTED
P7_B4_PR=185
P7_B4_MERGE_SHA=777762c6aec915d7fc6b3f1f33ce3b7241fd3b82
P7_B4_POST_MERGE_CI=38051474138
P7_B4_POST_MERGE_CI_RESULT=PASS
P7_C=BLOCKED_PENDING_V1_0_9_ACCEPTANCE

FEATURE_SELECTION_STATE_LAYER=browser_local
FEATURE_TIMER_STATE_LAYER=browser_local
FEATURE_DATA_LAYER=caller_data
CLIENT_HOOK_REQUIRED=NOT_PROVEN
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

## Frontend data mapping

C09C2 admits `ebbb6e` as a QS-02 CollectionBinding because it has `hasLoop: true` and a structurally linked repeated subtree. `b71f5d` is a separate admitted QS-03 CollectionBinding with its own repeat root and no collection parent. `05e604` has a query object but no true `hasLoop` flag, so it emits no CollectionBinding and reports `bricks.collection.boundary_unproven`. Its descendants continue to inherit the admitted `ebbb6e` collection context. The owner count is three; the CollectionBinding count is two.

The accepted ValueBindings are:

| Target | Source | Value key | Scope and collection | Status |
| --- | --- | --- | --- | --- |
| `a34333` | `{post_title}` | `content.title` | `collection_item`, `ebbb6e` | Normalized |
| `2a8181` | `{featured_image}` | `media.primary` | `collection_item`, `ebbb6e` | Normalized |
| `0ba4da` | `{featured_image}` | `media.primary` | `collection_item`, `b71f5d` | Normalized |
| `b41076` | `{post_content:16}` | `content.body` | `collection_item`, `ebbb6e` | `modifier_status: opaque`; `normalization_status: evidence_insufficient` |

The base field for `b41076` is known. The meaning of `:16` is not. Do not interpret the suffix, truncate the content, or emit an ordinary unmodified `content.body` value. Keep its content target cleared and preserve the occurrence as SourceTrace plus its evidence-insufficient diagnostic.

### Cross-collection synchronization

The source script uses one numeric index for the feature controls, descriptions, and slides. Both repeated feature and media queries request four posts. This establishes positional synchronization as the source mechanism, but it does not prove durable identity, one-to-one domain identity, or equal actual rendered cardinality. Milan v1 proposes using `selected_position` against caller-ordered collections without treating position as identity.

As a LiveFrames architectural decision, every synchronized rendered collection must be non-empty and have equal cardinality. A mismatch makes the RuntimeInstance unavailable and releases its owned timer. Do not repair the mismatch by sorting, joining IDs, truncating, padding, zipping, or guessing correspondence. Same-cardinality reorder retains the same numeric selected position and does not preserve item identity.

```text
FEATURE_MEDIA_CORRELATION=POSITIONAL_INDEX
POSITIONAL_SYNCHRONIZATION_SUPPORTED=YES
CROSS_COLLECTION_STABLE_IDENTITY=NOT_ESTABLISHED
SOURCE_RENDERED_CARDINALITY_EQUALITY=NOT_PROVEN
TARGET_EQUAL_CARDINALITY_RULE=FAIL_CLOSED_RUNTIME_INVARIANT
STATE_PRESERVATION_ACROSS_REORDER=NO
RUNTIME_EQUAL_CARDINALITY_REQUIRED=YES
POSITIONAL_CARDINALITY_MISMATCH=UNAVAILABLE
POSITIONAL_CARDINALITY_SILENT_REPAIR=NO
```

### Query ownership

Source `post_type`, `posts_per_page`, taxonomy/filter settings, nested query settings, ordering, and other query configuration remain SourceTrace evidence. LiveFrames does not execute those queries or define a backend query abstraction.

```text
SOURCE_QUERY_EXECUTION_IN_LIVEFRAMES=NO
CALLER_DATA_REQUIRED=YES
```

The host Phoenix application owns fetching, Ash/database/API/CMS access, authorization, tenant isolation, filtering, ordering, pagination, caching, and result bounds. LiveFrames consumes caller-provided collections and values for frontend rendering.

## Selection and Tabs fit

The proposed Milan mapping is Selection 1.0.0, not Tabs. The source contains `tablist`, `tab`, and `aria-selected`, but has no `tabpanel`, `aria-controls`, control/panel ID relation, roving tabindex, keydown handler, or arrow-key behavior. Do not create tab/panel relationships or infer keyboard behavior from attributes. Manual selection remains available through operable controls; the exact generated HTML element and activation realization are selected in the realization slice.

```text
FEATURE_MILAN_TABS_MAPPING=REJECTED_FOR_V1
```

Keep these as distinct concerns. Selection and timer transitions synchronize the ordered presentation groups. Keyboard focus remains outside Selection v1.0.0, and presentation animation remains in the static styling lane.

Timed sequential selection does not establish Carousel or automatic-activation Tabs semantics. Those mappings are rejected for Milan v1.

The M1-A authority records the eventual `PrimitiveRef` and occurrence values; it does not create a `BehaviorBinding` or authorize runtime implementation.

## Timed rotation boundary

The source export defines `--animation-duration: 5000ms` in root custom CSS. Its embedded script reads that property and uses the parsed value as the interval delay. On initialization it starts the interval. A feature-control click clears the interval, and the artifact has no restart or reset path. Rotation cannot resume before a new mount. Focus and hover pause behavior, lifecycle cleanup, and source reduced-motion behavior remain unproven.

The source also gates each interval callback on every feature control's animation data value being exactly true. If the guard is false, the callback returns without selection advance and does not itself clear the interval. The admitted path that changes the values to false is a feature-control click, which also clears the interval. The source does not restore the values to true.

For target semantics, normalize this source mechanism to the derived timer lifecycle. `timer_advance` is eligible only when `timer_lifecycle == running`. Reduced motion prevents automatic entry into `running`; manual selection remains available. Manual activation changes `running` to `stopped_by_user`. Updates and reconciliation do not restart, reset, or resume it. Remount begins a new timer lifecycle. The source flag is provenance only and is not serialized in BehaviorContract, primitive policy, or TimerPolicy.

The exact target TimerPolicy is:

```text
{
  "purpose": "advance_selection",
  "interval_ms": 5000,
  "start": "on_initialization",
  "manual_activation": "stop",
  "restart": "never",
  "reset": "none",
  "reduced_motion": "disable_automatic_advance"
}
```

This is the proposed target policy. Reduced motion is LiveFrames accessibility policy, not an observation of source compliance. It suppresses automatic advance but keeps manual selection available. Manual activation moves the timer from running to stopped_by_user. Updates and reconciliation do not restart, reset, or resume it; remount begins a new timer lifecycle. The runtime releases its browser-local interval on unavailable or destroyed. Source lifecycle timer/listener cleanup remains unproven and does not weaken target cleanup.

## Focus, keyboard, and accessibility

P7 plan v1.0.9 records the Selection semantic accessibility boundary. It does not claim that partial source Tabs markup forms an accessible Tabs widget.

The accessibility evidence remains partial. Review each item independently:

| Area | Evidence status |
| --- | --- |
| Source tab-like roles and attributes | `tablist`, `tab`, and `aria-selected` occur; full Tabs relationships are absent |
| `tabpanel`, `aria-controls`, control/panel IDs | Absent |
| Roving tabindex and arrow-key behavior | Absent |
| Control element | Source config requests a `button` with `type="button"`; no browser verification was performed |
| Enter/Space behavior | No custom key handler is present; exact generated element and activation realization are selected in the realization slice |
| Selected presentation | Target keeps exactly one selected position and exposed selected state synchronized |
| Inactive hidden content | Target must not leave hidden content accidentally interactive or focusable |
| Reduced motion | Target TimerPolicy disables automatic advance; manual selection remains available |
| Desktop/mobile content duplication | Separate media groups exist; their relationship and duplication consequences remain unproven |

Do not claim APG Tabs compliance. ARIA-like attributes do not prove the behavior contract, and tab markup alone does not establish that timed content changes are accessible. Do not invent `aria-controls` or focus rules.

## Responsive and static presentation

The accepted evidence proves separate desktop and mobile media groups and responsive presentation. It does not prove a Milan-specific breakpoint.

```text
DESKTOP_MEDIA_GROUP_PRESENT=YES
MOBILE_MEDIA_GROUP_PRESENT=YES
RESPONSIVE_PRESENTATION_EXISTENCE=SUPPORTED
FEATURE_MILAN_RESPONSIVE_BREAKPOINT=NOT_ESTABLISHED
GENERIC_NATIVE_STYLING_INTEGRATION=PRESENT_ON_MAIN
FEATURE_MILAN_SPECIFIC_STYLE_MAPPING=PARTIAL
STATIC=PARTIAL
```

Unresolved style mapping includes active/inactive feature presentation, hidden-state styles, media positioning, desktop/mobile media switching, responsive layout, timer-related transitions, and focus/selected visual states. This preflight adds no CSS.

## Runtime ownership, performance, and security

Feature selection and any future timer state are presentation-local. Feature data remains caller-owned. Current evidence does not require a client hook, server event, server state, or server polling.

```text
FEATURE_SELECTION_STATE_LAYER=browser_local
FEATURE_TIMER_STATE_LAYER=browser_local
FEATURE_DATA_LAYER=caller_data
CLIENT_HOOK_REQUIRED=NOT_PROVEN
SERVER_EVENT_REQUIRED=NO_CURRENT_EVIDENCE
SERVER_STATE_REQUIRED=NO_CURRENT_EVIDENCE
SERVER_POLLING=NO
```

Keep the target cost bounded: rendering is `O(feature items + media items)`, selection state is `O(1)`, and any later authorized runtime uses at most one bounded timer per rendered Milan instance. Server interaction-state cost is zero by default. Host applications bound caller collections. Do not recreate source query execution, create one server process per instance, broadcast timer ticks through PubSub, or persist per-user active-feature state without a future domain requirement.

Preserve these security boundaries:

- Source JavaScript stays inert and is never executed.
- Raw dynamic expressions are never evaluated.
- Opaque `{post_content:16}` is never treated as executable code or trusted markup.
- Caller authorization and tenant isolation remain host-owned.
- Dynamic asset values pass existing asset and URL validation.
- Source query settings do not become executable backend logic.
- Bricks IDs and selectors do not become arbitrary target selectors.
- Imported strings do not become atoms, modules, or events.
- Any later timer or listener has bounded ownership and cleanup.

```text
PRIVATE_SOURCE_INSPECTION_REQUIRED=NO
PRIVATE_SOURCE_EXECUTION=NO
PRIVATE_SOURCE_NEW_SEMANTICS=NONE
```

## Blocker routing

| Gap | Owner |
| --- | --- |
| `05e604` non-loop query | Existing C09C2 fail-closed authority; no new collection |
| `{post_content:16}` modifier | Frontend-data/binding authority |
| Durable cross-collection identity, if a future feature requires it | Frontend-data and componentization |
| Partial source Tabs markup | Not selected for Milan v1; Selection semantic boundary is frozen in P7-C/Milan |
| Timer lifecycle and click stop | Selection TimerPolicy in P7-C/Milan; browser cleanup in the later runtime slice |
| Focus and keyboard semantics | Behavior/P7 and accessibility |
| Active/hidden and responsive styles | Static lane |
| Final caller-data API | Componentization |
| Query execution and filtering | Host Phoenix application |

## Stop conditions

The evidence gaps above do not block positional synchronization. Stop if implementation requires durable cross-collection identity, Tabs/Carousel semantics, an invented responsive breakpoint, or invented body modifier semantics. Cardinality mismatch must fail closed as unavailable. This authority slice does not implement runtime, styling, data access, or componentization.

```text
STOP_CONDITIONS_TRIGGERED=NONE
M1_A_AUTHORITY=PROPOSED_IN_THIS_SLICE
P7_C_IMPLEMENTED=NO
```


## Proposed Milan v1 semantic closure

The proposed first Milan Behavior binding uses `PrimitiveRef{kind="selection", definition_version="1.0.0"}`. State is `selected_position`, initially zero, with a P7-C static domain of non-negative safe integers and a realization-owned membership invariant `selected_position < rendered_item_count`. It is positional state only.

```text
MILAN_V1_DURABLE_ITEM_IDENTITY=NO
MILAN_V1_POSITIONAL_SYNCHRONIZATION=YES
STATE_PRESERVATION_ACROSS_REORDER=NO
CONTROL_COLLECTION_CARDINALITY=1
PRESENTATION_COLLECTION_CARDINALITY=1_OR_MORE
RUNTIME_EQUAL_CARDINALITY_REQUIRED=YES
POSITIONAL_CARDINALITY_MISMATCH=UNAVAILABLE
POSITIONAL_CARDINALITY_SILENT_REPAIR=NO
P7_C_VALIDATES_STATIC_STATE_DOMAIN=YES
P7_C_VALIDATES_RENDERED_CARDINALITY=NO
RUNTIME_VALIDATES_POSITION_MEMBERSHIP=YES
```

The caller supplies synchronized lists in intended order. A runtime requires each rendered collection to be non-empty and equal in cardinality. On mismatch it becomes unavailable and releases the timer. No sorting, guessed join, truncation, padding, zip, or correspondence inference is allowed. If cardinalities remain equal through reorder, keep the numeric selected position; do not claim identity or reset selection. Remount initializes position zero.

Selection allows only `activate` and `timer` triggers. With `timer_policy=nil`, exactly one `activate` trigger and no `timer` trigger are required. With a TimerPolicy, exactly one of each is required. Activate's origin must equal the node ID of the single `control_collection` target. Timer's origin must be nil. Duplicates, unknown kinds, wrong or missing activate origin, timer origin, timer without policy, and policy without timer trigger reject. Activate(position) requires a position in the static domain and valid runtime membership, sets the position, synchronizes selected/active/hidden presentation, and applies the timer manual-activation effect. Timer advance requires `timer_lifecycle == running` and valid runtime collection membership; it advances in caller order with wrap and no skipped items. No other Selection 1.0.0 transition exists.

The exact proposed TimerPolicy is the map shown above. Its eligibility is derived realization state, not a serialized field. `not_started` becomes `running` at mount/init unless reduced motion suppresses autoplay, in which case it becomes `suppressed`. Manual activation moves `running` to `stopped_by_user`. Unavailable or destroyed runtime releases the mounted timer resource. The manual-stop state survives ordinary updates and reconciliation; remount begins a new timer lifecycle. The browser timer handle remains ephemeral.

Selection does not require tab roles, tabpanel, `aria-controls`, roving tabindex, a custom keyboard policy, or automatic Tabs activation. Exact markup and ARIA are selected and verified during runtime realization.

```text
PRIVATE_SOURCE_EXECUTED=NO
SOURCE_RUNTIME_ADOPTED=NO
SOURCE_JS_EXECUTION=NO
SOURCE_SELECTOR_RUNTIME_AUTHORITY=NO
UNTRUSTED_STRING_TO_ATOM=NO
ARBITRARY_EVENT_NAME_FROM_SOURCE=NO
SOURCE_TIMER_CLEANUP=NOT_PROVEN
SOURCE_LISTENER_CLEANUP=NOT_PROVEN
```
