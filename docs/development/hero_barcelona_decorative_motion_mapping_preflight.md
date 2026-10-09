# Hero Barcelona decorative motion mapping preflight

This evidence preflight maps accepted Hero Barcelona facts to current LiveFrames authorities. It records the boundary between decorative continuous motion and discrete Carousel behavior. It does not authorize implementation.

## Evidence and decision summary

Hero Barcelona has headings, calls to action, three decorative query-based moving columns, duplicated wrappers marked `aria-hidden`, motion, and responsive presentation. C-07X records responsive CTA width and slider height changes. These facts do not establish discrete slide selection, Carousel controls, autoplay policy, animation settings, or a target runtime mechanism.

Six query owners pass the current CollectionBinding admission rules: two QS-05 owners and four QS-06 owners. Each owner has its own repeat root and no parent collection. The evidence establishes repeated attachment-context subtrees, but it does not establish a Hero per-item media ValueBinding. In particular, `media.primary` is not authorized for Hero.

The generic Carousel family exists, and the historical matrix recommends reuse only when Hero motion fits its approved contract. The canonical Carousel has stable active-slide identity, rotation state, movement state, and discrete transitions. Hero evidence establishes none of those discrete semantics. The mapping therefore remains unestablished.

The accepted Behavior authorities contain no source-neutral decorative continuous-motion capability that fits Hero without importing Carousel semantics. Record `GENERIC_DECORATIVE_MOTION_CAPABILITY=UNMODELED` and route the gap to Behavior/P7. This is an evidence blocker, not authorization to design a primitive or runtime. Continue using the supported static, collection, accessibility, and provenance evidence below.

## Accepted authorities

This document relies only on these repository authorities:

- [Frames native conversion matrix](frames_native_conversion_matrix.md), especially the Hero rows and Carousel sequencing note.
- [C-07X unsupported surface inventory](c07x_unsupported_surface_inventory.md), including the Hero export summary and template behavior assessment.
- [C-09A query and dynamic data contract](c09a_query_dynamic_data_contract.md), including QS-05/QS-06 and provider boundaries.
- [C-09B frontend binding authority](c09b_frontend_binding_authority.md).
- [C-09C2 Bricks binding mapping authority](c09c2_bricks_binding_mapping_authority.md), including collection admission and the closed ValueBinding classifier.
- [Interaction Model](../09_INTERACTION_MODEL.md), especially the Carousel and MotionPolicy contracts.
- [P7 interaction conversion implementation plan](p7_interaction_conversion_implementation_plan.md), version 1.0.5.
- [C-09D6 native generation authority](c09d6_native_generation_authority.md), for the generic native styling integration boundary.
- [Source and provenance policy](../04_SOURCE_AND_PROVENANCE.md).
- [Slider Basel Carousel mapping preflight](slider_basel_carousel_mapping_preflight.md), as reviewed context for the generic Carousel boundary only. It is not evidence of Hero owner acceptance.

No private source was inspected or executed. No new source semantics are introduced.

## Static structure and collection evidence

The accepted Hero summary establishes headings and calls to action, three decorative moving columns, duplicated `aria-hidden` wrappers, responsive layout, CTA width changes, and slider-height changes. It does not establish dynamic CTA values or destinations. Any target URL must follow existing static navigation and URL safety authority.

The six query owners are:

| Query family | Owners | Count | Accepted evidence |
| --- | --- | ---: | --- |
| QS-05 | `895a32`, `4976fc` | 2 | Attachment plus taxonomy filter; no offset. |
| QS-06 | `307070`, `dc20fb`, `10f903`, `6309a6` | 4 | Attachment plus taxonomy filter; numeric offset observed as 8 or 12. |

C-09C2 confirms that all six owners have a query object, `hasLoop: true`, and a linked child subtree. Each owner is a separate repeat root. None has an emitted collection ancestor. These six owners therefore pass CollectionBinding admission.

The three visual columns and six query owners are independent evidence counts. No accepted authority maps query owners to visual columns or duplicate wrappers. Do not infer two owners per column, visible/duplicate pairs, or a relationship between QS-05/QS-06 and visual order.

### Source query and caller-data boundary

The query filters and offset values remain inert SourceTrace provenance. The QS-06 offsets of 8 or 12 do not establish animation delay, phase, direction, carousel index, item identity, or visual ordering. LiveFrames does not execute the source query, choose taxonomy semantics, fetch records, or interpret offsets.

The caller supplies all six collections. The host Phoenix application owns database or API access, authorization, tenant isolation, filter interpretation, ordering, offset and window semantics, pagination, caching, and result bounds. LiveFrames owns the collection contract after the caller supplies data. Host policy must bound every collection.

### Per-item media binding remains unestablished

C-09A describes the Hero query children as static image elements in attachment context. C-09C2's closed ValueBinding classifier does not admit a Hero-specific image binding. Other templates' `media.primary` mappings do not transfer to Hero. Do not emit or claim `media.primary`, `media.url`, `media.id`, `attachment.id`, `post_id`, or `featured_image` for Hero.

Collection repetition is supported, while per-record renderable media is not. Classify Hero data as partial. Route media value semantics to frontend-data/binding authority, and route the final caller media API to componentization authority. If useful Hero output requires inventing an item media key, stop at that boundary.

## Decorative motion and Carousel compatibility

The canonical Carousel contract in the Interaction Model includes:

```text
lifecycle: active | destroyed
active_slide: stable slide ID
rotation: manual | playing | paused
movement: idle | transitioning | dragging
```

It also defines previous, next, jump, play, pause, drag-start, drag-end/cancel, and destroy transitions. Those fields and transitions describe discrete item selection, control, and movement semantics. Hero's three decorative moving columns do not establish those semantics.

The matrix lists Carousel reuse as a historical candidate, conditional on a semantic fit. It does not establish the fit. Keep the generic Carousel family available, but leave Hero's Carousel mapping unestablished. Do not create placeholder active slides, controls, or policy values to make Hero fit.

No accepted source-neutral Behavior capability models continuous decorative tracks without those discrete Carousel semantics. Do not define a Hero state machine, animation phases, direction, offsets, timers, or transitions here. Route the unmodeled capability and any future Carousel reuse decision to Behavior/P7. The P7 1.0.5 plan is a corrected authority candidate for independent review; owner acceptance is not established. P7-B1 remains planned and unauthorized.

## Responsive styling and runtime placement

Hero has responsive layout, CTA width changes, and visual height changes. The exact Hero breakpoints and detailed column, track, overflow, duplicate-positioning, and motion styles are not established. Global breakpoint vocabulary does not prove which breakpoints Hero uses. Hero-specific style mapping is partial, and motion style realization is unestablished. Route responsive layout and static styling to the Static lane. Do not add CSS in this preflight.

The presence of motion does not establish a target technique. CSS animation, Web Animations, browser timers, observers, Phoenix hooks, LiveView events, and server processes remain unselected. A client hook is not proven necessary. There is no current evidence for a server event or server-side motion state. If an authorized later behavior requires runtime state, that presentation state belongs in the browser. Media data remains caller supplied. Server polling is not justified.

The target must address reduced motion because Hero has visible motion. The source reduced-motion policy and target realization remain unestablished. Do not import Slider autoplay rules unless Hero first proves Carousel semantics. The target policy must follow the eventual accepted decorative-motion model.

The native styling integration is present on the current base. That generic infrastructure does not establish Hero-specific styles or a motion realization. No CSS or style mapping is implemented here.

## Accessibility evidence and target invariant

C-07X records duplicate Hero content marked `aria-hidden` and `tabindex="-1"`. This supports the presence of hidden duplicate wrappers, but it does not establish the exact primary-to-duplicate relationship or prove that all descendants are excluded from keyboard focus. The number and behavior of focusable descendants remain unknown. Do not claim full source accessibility correctness based on the wrapper attributes.

The target invariant is:

```text
ARIA_HIDDEN_SUBTREE_HAS_NO_UNINTENDED_FOCUSABLE_CONTENT=YES
```

Apply that invariant independently of visual duplication. Keep exact image `alt` and role policies unknown. The high-level decorative-media classification does not prove `alt=""`, `role="presentation"`, or `aria-hidden` on each image. Accessibility remains partial pending a supported duplicate-content and focus policy.

## External dependencies, performance, and security

The historical Hero external status is shared with the Carousel decision. That does not prove Hero uses Splide or the Auto Scroll extension. The target currently requires no external motion package. This does not decide the eventual native realization.

The final design should keep rendering work proportional to the total repeated media nodes. Behavior state should remain O(1) or O(number of visual tracks), depending on the later accepted motion model. Server animation-state cost is zero by default. Do not copy media payloads into behavior state. Continuous presentation motion stays client-local. These are implementation constraints, not a mechanism choice.

Security requirements:

- Never execute imported Frames or Bricks scripts or source query configuration.
- Keep source taxonomy and offset values inert as provenance.
- Keep caller authorization and tenant isolation in the host application.
- Validate dynamic asset URLs with existing URL and asset authority.
- Do not turn raw Bricks IDs, classes, or selectors into unsafe runtime selectors.
- Do not duplicate unintended actionable or focusable content inside hidden duplicate subtrees.
- Do not copy a source or vendor runtime package into LiveFrames.
- Fail closed when collection or media identity is missing; do not fabricate a binding.
- Do not derive atoms, modules, or events from input.

## Authority routing and implementation boundary

| Finding | Owning authority |
| --- | --- |
| Six admitted collection boundaries | Existing frontend-data authority. |
| Hero item media value semantics | Frontend-data and C-09 binding authority. |
| Final caller-data API | Componentization authority. |
| Decorative motion semantics and any Carousel reuse decision | Behavior/P7, after semantic fit is proven. |
| Motion style realization | Static and Behavior boundary. |
| Responsive columns, CTA width, visual height | Static lane. |
| Duplicate `aria-hidden` and focus rules | Evidence and accessibility/Behavior realization. |
| Query execution, taxonomy, and offset meaning | Host application only. |
| Any future external motion package | Separate dependency decision, only if later implementation proves it necessary. |

This preflight creates no `BehaviorPrimitiveDefinition`, `BehaviorBinding`, `PrimitiveRef`, definition-version selection, initial state, policy values, binding ID, or ordinal. It does not authorize Behavior/P7, static styling, frontend-data architecture, componentization, dependency adoption, or implementation.

## Compact classification

```text
STATIC=PARTIAL
BEHAVIOR=PARTIAL
DATA=PARTIAL
ACCESSIBILITY=PARTIAL
EXTERNAL_DEPENDENCY=NONE
OVERALL=NOT_READY
NATIVE_READY=NO
```

The main partial-data boundary is:

```text
COLLECTION_REPETITION=SUPPORTED
PER_ITEM_MEDIA_BINDING=NOT_ESTABLISHED
```

## Detailed evidence ledger

Unknown values remain unknown. `NOT_PROVEN` means the cited accepted authorities do not establish the claim.

```text
HERO_BARCELONA_PRESENT=YES

HEADINGS_PRESENT=YES
CALLS_TO_ACTION_PRESENT=YES

VISUAL_MOVING_COLUMN_COUNT=3
DECORATIVE_MOTION_EXISTENCE=SUPPORTED
ARIA_HIDDEN_DUPLICATE_WRAPPERS_PRESENT=YES

HERO_QUERY_OWNER_COUNT=6
QS05_OWNER_COUNT=2
QS06_OWNER_COUNT=4

QS05_OWNERS=895a32,4976fc
QS06_OWNERS=307070,dc20fb,10f903,6309a6

HERO_COLLECTION_BINDING_COUNT=6
HERO_REPEAT_BOUNDARIES=SUPPORTED
HERO_COLLECTION_BINDINGS=SUPPORTED
HERO_PARENT_COLLECTION_BINDINGS=NONE

SOURCE_QUERY_OFFSET_PRESENT=YES_ON_QS06
SOURCE_QUERY_OFFSET_VALUES=8_OR_12
SOURCE_QUERY_OFFSET_TARGET_SEMANTICS=NOT_ESTABLISHED

QUERY_OWNER_TO_VISUAL_COLUMN_MAPPING=NOT_ESTABLISHED
DUPLICATE_WRAPPER_TO_QUERY_OWNER_MAPPING=NOT_ESTABLISHED

SOURCE_QUERY_EXECUTION_IN_LIVEFRAMES=NO
CALLER_COLLECTION_REQUIRED=YES

HERO_ATTACHMENT_COLLECTION_CONTEXT=SUPPORTED
HERO_MEDIA_VALUE_BINDING=NOT_ESTABLISHED
HERO_ASSET_VALUE_BINDING=NOT_ESTABLISHED
HERO_COLLECTION_ITEM_MEDIA_KEY=NOT_ESTABLISHED
HERO_RENDERABLE_MEDIA_FROM_COLLECTION=NOT_ESTABLISHED

GENERIC_CAROUSEL_TARGET_FAMILY=AVAILABLE
HERO_CAROUSEL_REUSE_CANDIDATE=YES_BY_HISTORICAL_MATRIX
HERO_DISCRETE_CAROUSEL_SEMANTICS=NOT_PROVEN
HERO_CAROUSEL_MAPPING=NOT_ESTABLISHED

HERO_STABLE_ACTIVE_SLIDE_REQUIRED_BY_SOURCE=NOT_PROVEN
HERO_DISCRETE_ITEM_SELECTION_PRESENT=NOT_PROVEN
HERO_USER_NAVIGATION_PRESENT=NOT_PROVEN
HERO_PLAY_PAUSE_PRESENT=NOT_PROVEN
HERO_DRAG_PRESENT=NOT_PROVEN
HERO_JUMP_TO_ITEM_PRESENT=NOT_PROVEN
HERO_MANUAL_ROTATION_MODE_PRESENT=NOT_PROVEN

GENERIC_DECORATIVE_MOTION_CAPABILITY=UNMODELED
BEHAVIOR_CAPABILITY_OWNER=Behavior/P7
HERO_SOURCE_STATE_MACHINE=NOT_ESTABLISHED
HERO_TARGET_STATE_MACHINE=UNMODELED

TARGET_MOTION_MECHANISM=UNKNOWN
HERO_MOTION_STATE_LAYER=browser_local_if_runtime_required
HERO_MEDIA_DATA_LAYER=caller_data
CLIENT_HOOK_REQUIRED=NOT_PROVEN
SERVER_EVENT_REQUIRED=NO_CURRENT_EVIDENCE
SERVER_STATE_REQUIRED=NO_CURRENT_EVIDENCE
SERVER_POLLING=NO

RESPONSIVE_LAYOUT_EXISTENCE=SUPPORTED
CTA_WIDTH_RESPONSIVE_CHANGE_EXISTENCE=SUPPORTED
HERO_MEDIA_HEIGHT_RESPONSIVE_CHANGE_EXISTENCE=SUPPORTED
HERO_RESPONSIVE_BREAKPOINTS=NOT_ESTABLISHED

DECORATIVE_MEDIA_PRESENTATION=SUPPORTED
EXACT_IMAGE_ALT_POLICY=NOT_ESTABLISHED
EXACT_IMAGE_ROLE_POLICY=NOT_ESTABLISHED

DUPLICATE_WRAPPER_RELATIONSHIP=ARIA_HIDDEN_AND_TABINDEX_MINUS_ONE_PRESENT; PRIMARY_DUPLICATE_MAPPING_NOT_ESTABLISHED
DUPLICATE_CONTENT_ACCESSIBILITY_EXCLUSION=ARIA_HIDDEN_WRAPPER_PRESENT; COMPLETE_DESCENDANT_EXCLUSION_NOT_ESTABLISHED
DUPLICATE_CONTENT_FOCUS_EXCLUSION=WRAPPER_TABINDEX_MINUS_ONE_PRESENT; DESCENDANT_FOCUS_EXCLUSION_NOT_ESTABLISHED
SOURCE_DUPLICATE_FOCUSABLE_DESCENDANTS=NOT_ESTABLISHED
ARIA_HIDDEN_SUBTREE_HAS_NO_UNINTENDED_FOCUSABLE_CONTENT=YES_TARGET_INVARIANT

REDUCED_MOTION_REQUIREMENT=REQUIRED_FOR_TARGET
SOURCE_REDUCED_MOTION_POLICY=NOT_ESTABLISHED
TARGET_REDUCED_MOTION_REALIZATION=NOT_ESTABLISHED

GENERIC_NATIVE_STYLING_INTEGRATION=PRESENT_ON_MAIN
HERO_SPECIFIC_STYLE_MAPPING=PARTIAL
HERO_MOTION_STYLE_REALIZATION=NOT_ESTABLISHED

HISTORICAL_HERO_EXTERNAL_STATUS=SHARED_WITH_CAROUSEL_DECISION
HERO_SOURCE_SPLIDE_USAGE=NOT_PROVEN
HERO_SOURCE_AUTO_SCROLL_USAGE=NOT_PROVEN
SPLIDE_TARGET_DEPENDENCY=NO
AUTO_SCROLL_TARGET_DEPENDENCY=NO
GENERIC_EXTERNAL_MOTION_LIBRARY_REQUIRED=NOT_PROVEN
EXTERNAL_DEPENDENCY=NONE

P7_PLAN_VERSION_PRESENT_ON_MAIN=1.0.5
P7_PLAN_STATUS=CORRECTED_AUTHORITY_CANDIDATE_FOR_INDEPENDENT_REVIEW
P7_1_0_5_OWNER_ACCEPTANCE=NOT_ESTABLISHED
P7_A1_STATUS=IMPLEMENTED_ACCEPTED
P7_A2_STATUS=IMPLEMENTED_ACCEPTED
P7_B1_STATUS=PLANNED_NOT_AUTHORIZED
P7_B1_AUTHORIZED=NO
HERO_BEHAVIOR_BINDING_CREATED=NO
PRIMITIVE_DEFINITION_VERSION_SELECTED=NO
PRIMITIVE_POLICY_VALUES_SELECTED_FOR_HERO=NO

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

## Stop condition

```text
STOP=GENERIC_BEHAVIOR_CAPABILITY_UNMODELED
```

Record this blocker for Behavior/P7. Do not design the missing primitive, define a Hero state machine, choose a runtime mechanism, or force Hero into Carousel semantics in this evidence lane. Independent static, collection, data-gap, responsive, accessibility, security, and provenance findings above remain documented.
