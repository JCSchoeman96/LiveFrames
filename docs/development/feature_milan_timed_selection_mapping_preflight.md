# Feature Milan timed selection mapping preflight

## Purpose and decision

This preflight maps the accepted Feature Milan evidence to the current frontend-data and Behavior authorities. It does not authorize implementation. Unknown source behavior remains unknown, and no source script was executed or interpreted.

Milan has two admitted frontend collections and three source query owners. Its title and primary media bindings are normalized. The `{post_content:16}` occurrence remains an evidence-insufficient `content.body` binding with an opaque modifier. The accepted evidence establishes selection, interval-based active-item changes, click effects, and selected/hidden presentation, but it does not establish complete Tabs semantics, timer policy, or the identity relationship between the feature and media collections.

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

The current P7 implementation plan is used only to report its authority status. Version 1.0.6 is merged but remains a proposed authority amendment; version 1.0.5 is accepted. This preflight does not treat the 1.0.6 structure as accepted authority.

The accepted historical evidence records dynamic feature data, tab-like ARIA markup, separate desktop/mobile media groups, interval-based active-feature changes, click effects on the active feature or rotation, selected/hidden changes, and media-position changes. It does not prove exact tab/panel relationships, a timer lifecycle, or cross-collection identity.

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

FEATURE_TO_MEDIA_SYNCHRONIZATION_EXISTENCE=SUPPORTED_AT_PRESENTATION_LEVEL
CROSS_COLLECTION_ITEM_CORRELATION=NOT_ESTABLISHED
CROSS_COLLECTION_STABLE_IDENTITY=NOT_ESTABLISHED
POSITIONAL_INDEX_COUPLING_AS_TARGET=NOT_AUTHORIZED

FEATURE_SELECTION_EXISTENCE=SUPPORTED
TAB_LIKE_ARIA_MARKUP_PRESENT=YES
GENERIC_TABS_TARGET_FAMILY=AVAILABLE
FEATURE_MILAN_TABS_CANDIDATE=YES
TAB_TO_PANEL_RELATIONSHIP=NOT_ESTABLISHED
ARIA_CONTROLS_RELATIONSHIP=NOT_PROVEN
TAB_FOCUS_MODEL=NOT_ESTABLISHED
TAB_KEYBOARD_MODEL=NOT_ESTABLISHED
TAB_ACTIVATION_MODE=NOT_ESTABLISHED
TAB_ORIENTATION=NOT_ESTABLISHED
FEATURE_MILAN_TABS_MAPPING=PARTIAL

TIMED_ROTATION_EXISTENCE=SUPPORTED
ACTIVE_FEATURE_INDEX_ADVANCES_ON_INTERVAL=SUPPORTED
CLICK_AFFECTS_ACTIVE_FEATURE_OR_ROTATION=SUPPORTED
MEDIA_POSITION_CHANGE_EXISTENCE=SUPPORTED
CLICK_ROTATION_SIDE_EFFECT=SUPPORTED_BUT_CONDITION_AMBIGUOUS

SOURCE_TIMER_INTERVAL=NOT_ESTABLISHED
SOURCE_TIMER_INITIAL_START_POLICY=NOT_ESTABLISHED
SOURCE_TIMER_RESTART_POLICY=NOT_ESTABLISHED
SOURCE_TIMER_RESET_POLICY=NOT_ESTABLISHED
SOURCE_PAUSE_ON_FOCUS_POLICY=NOT_ESTABLISHED
SOURCE_PAUSE_ON_HOVER_POLICY=NOT_ESTABLISHED
SOURCE_REDUCED_MOTION_TIMER_POLICY=NOT_ESTABLISHED
SOURCE_TIMER_CLEANUP=NOT_ESTABLISHED
TIMER_RESOURCE_CLEANUP_OWNER=SHARED_RUNTIME_LIFECYCLE

TIMER_POLICY_REQUIRED_IF_TIMED_ROTATION_RETAINED=YES
FEATURE_MILAN_TIMER_MAPPING=PARTIAL
FEATURE_MILAN_CAROUSEL_MAPPING=NOT_ESTABLISHED
FEATURE_MILAN_AUTOMATIC_TABS_MAPPING=NOT_ESTABLISHED

DESKTOP_MEDIA_GROUP_PRESENT=YES
MOBILE_MEDIA_GROUP_PRESENT=YES
RESPONSIVE_PRESENTATION_EXISTENCE=SUPPORTED
FEATURE_MILAN_RESPONSIVE_BREAKPOINT=NOT_ESTABLISHED
GENERIC_NATIVE_STYLING_INTEGRATION=PRESENT_ON_MAIN
FEATURE_MILAN_SPECIFIC_STYLE_MAPPING=PARTIAL

P7_PLAN_VERSION_PRESENT_ON_MAIN=1.0.6
P7_1_0_6_STATUS=PROPOSED_AUTHORITY_AMENDMENT
P7_1_0_6_MERGED=YES
P7_1_0_6_OWNER_ACCEPTANCE=NOT_ESTABLISHED_BY_THIS_PREFLIGHT
P7_1_0_5_STATUS=ACCEPTED

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

The accepted evidence says active selection changes media position. That establishes a presentation-level synchronization effect only. It does not establish correspondence between items in `ebbb6e` and `b71f5d`.

Do not infer equal indexes, matching post IDs, matching order or cardinality, a one-to-one pairing, or a shared stable key. If native reproduction requires one of those assumptions, stop with `STOP=CROSS_COLLECTION_IDENTITY_INVENTION_REQUIRED` and route the gap to frontend-data and componentization authority.

### Query ownership

Source `post_type`, `posts_per_page`, taxonomy/filter settings, nested query settings, ordering, and other query configuration remain SourceTrace evidence. LiveFrames does not execute those queries or define a backend query abstraction.

```text
SOURCE_QUERY_EXECUTION_IN_LIVEFRAMES=NO
CALLER_DATA_REQUIRED=YES
```

The host Phoenix application owns fetching, Ash/database/API/CMS access, authorization, tenant isolation, filtering, ordering, pagination, caching, and result bounds. LiveFrames consumes caller-provided collections and values for frontend rendering.

## Selection and Tabs fit

Feature selection exists, and the source has tab-like ARIA markup. Those facts make generic Tabs a candidate target family; they do not establish a complete Tabs binding. The accepted evidence does not prove tab-to-panel identity, `aria-controls`, ordered tab membership, selected/focused state separation, activation mode, orientation, roving tab stop, or keyboard behavior.

The canonical Tabs target requires distinct `selected_tab_id` and `focused_tab_id`, an ordered tab set, one panel per tab, explicit activation and orientation, and keyboard behavior. ARIA role-like markup does not supply those semantics. Do not create tab/panel relationships or infer keyboard behavior from attributes.

```text
FEATURE_MILAN_TABS_MAPPING=PARTIAL
```

Keep these concepts separate until accepted evidence and authority resolve them:

- user selection;
- keyboard focus;
- timed active-item changes;
- media synchronization;
- presentation animation.

The evidence does not establish Carousel autoplay semantics or automatic-activation Tabs:

```text
FEATURE_MILAN_CAROUSEL_MAPPING=NOT_ESTABLISHED
FEATURE_MILAN_AUTOMATIC_TABS_MAPPING=NOT_ESTABLISHED
```

No `BehaviorBinding`, `PrimitiveRef`, `initial_state`, `primitive_policy_values`, `FocusPolicy`, or `KeyboardPolicy` is created by this preflight.

## Timed rotation boundary

The source evidence establishes that the active feature advances on an interval and that a click stops or changes rotation. It does not establish the interval duration, startup, restart or reset rules, focus or hover pause behavior, reduced-motion behavior, or timer cleanup. The click condition remains ambiguous and cannot be converted into a permanent stop, pause, reset, or restart rule.

The Behavior authority requires an explicit TimerPolicy when timed behavior is retained. TimerPolicy owns purpose, bounded duration or interval, eligibility, start, stop, restart/reset, and reduced-motion interaction. Current Milan evidence does not supply enough of those values, so no TimerPolicy is populated and timed rotation remains partial.

A later accepted Milan behavior mapping must decide whether focus, pointer hover, or explicit user interaction changes timer eligibility or triggers stop/restart transitions. Current source evidence does not establish those rules, and this preflight does not assign them to a specific serialized policy field. The shared RuntimeInstance lifecycle owns release of actual timer handles. Source timer cleanup remains unestablished.

Do not borrow Slider/Carousel autoplay rules for Milan. The source does not prove that Milan is a Carousel. A later normalized design may combine selection semantics with TimerPolicy and MotionPolicy, after their requirements have authority.

## Focus, keyboard, and accessibility

P7 plan 1.0.6 is present on main and marked `proposed authority amendment`; 1.0.5 is marked accepted, and P7-B1 is recorded as authorized but blocked pending 1.0.6 acceptance. Merge status does not establish owner acceptance. This preflight does not treat the 1.0.6 FocusPolicy reference shape as accepted Milan authority.

The accessibility evidence remains partial. Review each item independently:

| Area | Evidence status |
| --- | --- |
| Tab-like roles and attributes | Present, exact relationships unproven |
| Selected state exposure | Selected presentation changes; complete state exposure is unproven |
| Hidden state exposure | Hidden presentation changes; focus exclusion is unproven |
| Tab-to-panel relationship | Not established |
| Keyboard activation and focus movement | Not established |
| Roving tab stop | Not established |
| Timer behavior while focus is within the feature | Not established |
| Timed changes under reduced motion | Not established |
| Desktop/mobile content duplication and its accessibility effects | Separate media groups exist; relationship and duplication consequences are unproven |

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
| Cross-collection item correlation | Frontend-data and componentization |
| Exact Tabs semantic fit | Behavior/P7 |
| Timer lifecycle and click/timer interaction | Behavior/P7 |
| Focus and keyboard semantics | Behavior/P7 and accessibility |
| Active/hidden and responsive styles | Static lane |
| Final caller-data API | Componentization |
| Query execution and filtering | Host Phoenix application |

## Stop conditions

The evidence gaps above remain recorded as partial or not established; they do not require new source inspection. Stop if satisfying the mapping would require inventing a collection boundary, body modifier semantics, cross-collection identity, Tabs relationships, keyboard policy, or TimerPolicy values. Also stop if work enters Behavior, static styling, data architecture, or componentization implementation.

```text
STOP_CONDITIONS_TRIGGERED=NONE
```
