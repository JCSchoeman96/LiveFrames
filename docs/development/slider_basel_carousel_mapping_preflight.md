# Slider Basel carousel mapping preflight

## Purpose and result

This document maps accepted Slider Basel evidence to the source-independent Carousel contract, frontend-data authorities, native styling, accessibility, icon/asset, and dependency authorities. It is an evidence preflight only. It does not authorize Carousel/P7, Slider, styling, data, icon, or dependency implementation.

The current base is:

```text
BASE_SHA=4c74d914643027d54843c676635ad3c991a038cc
BASE_TREE=35c7e9aa5a6285b7234deffe5454eae2db587cd5
BASE_CI=37973482591 completed/success
PR_162=P7 primitive-specific occurrence policy values
P7_PLAN_VERSION=1.0.5
```

PR #160, `C09D6-D1D: integrate native styling generation`, and PR #162 are merged at this base. P7 1.0.5 remains a plan authority. It does not authorize implementation.

The selected Slider Basel export (`T-SLIDER`) and reusable Frames widgets (`W-SLIDER`, `W-SLIDER-CONTROLS`) are separate evidence sources. Widget capability evidence does not prove exact selected-export implementation equivalence. Generic Carousel policy below is target policy, not a claim about Slider Basel's exact source settings.

## Source evidence

The accepted Slider Basel export evidence records a Frames slider with loop, previous/next arrows, play/pause controls, one slide per page, query-backed repeated slides, active/inactive slide styling, and a mobile layout. The selected export's Slider evidence also records rotation configuration. These facts establish the presence of those features/configurations, not their complete runtime semantics.

| Claim | Classification | Evidence boundary |
| --- | --- | --- |
| `SLIDER_BASEL_PRESENT` | `YES` | Selected export `slider-section-basel`; C-07X export summary and Interaction Model evidence ledger `BEH-P003`. |
| `CAROUSEL_EXISTENCE` | `SUPPORTED` | Selected export contains a Frames slider. |
| `LOOP_EXISTENCE` | `SUPPORTED` | Selected export evidence records loop. |
| `PREVIOUS_CONTROL_EXISTENCE` | `SUPPORTED` | Selected export evidence records arrow controls. |
| `NEXT_CONTROL_EXISTENCE` | `SUPPORTED` | Selected export evidence records arrow controls. |
| `PLAY_PAUSE_CONTROL_EXISTENCE` | `SUPPORTED` | Selected export evidence records play/pause controls. |
| `ONE_SLIDE_PER_PAGE` | `SUPPORTED` | C-07X Slider Basel export summary. |
| `AUTOPLAY_CONFIGURATION_EXISTENCE` | `SUPPORTED` | Selected-export evidence records rotation configuration. This does not establish enabled state, initial state, or timing. |
| `ACTIVE_INACTIVE_SLIDE_STYLE_EXISTENCE` | `SUPPORTED` | Selected export evidence records distinct active/inactive slide styling. |
| `RESPONSIVE_MOBILE_LAYOUT_EXISTENCE` | `SUPPORTED` | Selected export evidence records a mobile layout. |
| `SOURCE_DRAG_BEHAVIOR` | `NOT_PROVEN` | The reusable Slider widget exposes drag settings, but that is not proof that this selected export uses drag. |
| `CAROUSEL_PICKER_OR_PAGINATION_CONTROL_EXISTENCE` | `NOT_PROVEN` | No accepted Slider Basel export evidence establishes a picker/pagination control. Query pagination is a separate host concern. |
| `DOM_CLONING_REQUIRED` | `NOT_PROVEN` | Source runtime mechanisms do not set target markup requirements. |

The reusable widget corpus records Splide, a Splide Auto Scroll extension, and widget-level configuration capabilities. Keep these as `W-SLIDER`/`W-SLIDER-CONTROLS` evidence. Do not infer that Slider Basel uses Auto Scroll, pagination, drag, synchronization, or the widget's full runtime behavior.

## Generic Carousel target contract

The canonical [Interaction Model, Carousel section](../09_INTERACTION_MODEL.md#97-carousel) defines orthogonal target state:

```text
lifecycle: active | destroyed
active_slide: stable slide ID
rotation: manual | playing | paused
movement: idle | transitioning | dragging
```

Additional target policy dimensions cover loop mode, autoplay permission, timer policy, pause reasons, user-stop latch, and reduced-motion preference. Initial target state is the first valid slide, `rotation=manual` unless an explicitly approved autoplay policy exists, and `movement=idle`. `destroyed` is terminal.

Generic transitions are previous, next, jump, play, pause, drag-start, drag-end/cancel, and destroy. Guards require a valid active slide and target, stable slide identity, an explicit loop/boundary policy, an explicit bounded timer policy before autoplay, an accessible rotation control before autoplay, and a valid mounted owner. Previous/next at a non-loop boundary are no-ops. Drag is part of the generic model, not evidence that Slider Basel supports dragging.

Destroy stops owned timers, pending transitions, drag/pointer ownership, observers, media control, and listeners. Autoplay requires bounded timing, an accessible rotation control, pause on focus and pointer hover, no automatic resume after a user/focus stop, explicit rotation-control activation to resume, and autoplay disabled by default for reduced motion. These are target requirements, not source facts.

```text
CAROUSEL_TARGET_FAMILY=SUPPORTED
SLIDER_BASEL_CAROUSEL_INSTANCE_MAPPING=PARTIAL
```

The mapping remains partial because source evidence does not establish item identity, complete autoplay settings, or the required runtime and accessibility details.

## Frontend data and slide identity

QS-04 proves the repeated slide collection and its linked content/media subtree. The accepted [C09C2 mapping](c09c2_bricks_binding_mapping_authority.md#3-collectionbinding-admission) records:

```text
QS04_OWNER=118bbd
QS04_HAS_LOOP=true
SLIDE_REPEAT_BOUNDARY=SUPPORTED
SLIDE_COLLECTION_BINDING=SUPPORTED
SLIDE_REPEAT_ROOT=QS-04 owner DesignNode
PARENT_COLLECTION_BINDING=nil
```

The accepted value mappings are:

```text
{post_title}
→ collection_item, value_key=content.title, text target
→ Slider collection 118bbd

{featured_image}
→ collection_item, value_key=media.primary, asset target
→ Slider collection 118bbd
```

Therefore `SLIDE_TITLE_BINDING=SUPPORTED` and `SLIDE_MEDIA_BINDING=SUPPORTED`. No post ID, permalink, location ID, caption, alt text, URL, slug, or other field is established for Slider by these mappings.

The frontend contract defines deterministic identity for a collection binding and value binding. It does not define a stable source-independent identity for each item in the supplied collection. The collection binding ID identifies the repeat contract, not one slide. Neither the source row order nor its node ID is a slide identity.

```text
STABLE_SLIDE_IDENTITY=NOT_ESTABLISHED
SOURCE_QUERY_EXECUTION_IN_LIVEFRAMES=NO
CALLER_COLLECTION_REQUIRED=YES
DATA=PARTIAL
```

Do not substitute array index, render position, source traversal order, raw Bricks element ID, source post ID, or DOM position for stable slide identity. The host Phoenix application owns querying, authorization, tenant isolation, filtering, sorting, pagination, caching, result bounds, and adaptation. LiveFrames consumes caller-provided data and renders the repeat boundary. The final component caller contract is also not established.

This is a Behavior/P7 plus frontend-data/componentization blocker. Keep the proven QS-04 repeat, title, and media mappings; do not downgrade them to insufficient evidence.

## Source autoplay and target rotation policy

The selected export evidence supports autoplay/rotation configuration existence only. It does not establish the following source settings:

| Source fact | Classification |
| --- | --- |
| `SOURCE_INITIAL_ROTATION_STATE` | `NOT_ESTABLISHED` |
| `SOURCE_AUTOPLAY_INTERVAL` | `NOT_ESTABLISHED` |
| `SOURCE_FOCUS_PAUSE_POLICY` | `NOT_ESTABLISHED` |
| `SOURCE_POINTER_HOVER_PAUSE_POLICY` | `NOT_ESTABLISHED` |
| `SOURCE_USER_STOP_LATCH` | `NOT_ESTABLISHED` |
| `SOURCE_RESUME_POLICY` | `NOT_ESTABLISHED` |

Do not copy the generic Carousel initial state or pause/resume policy into the source record. If target autoplay is later authorized, it must meet the Interaction Model's timer, accessible-control, focus/hover, user-stop, resume, and reduced-motion rules.

The accepted source evidence establishes play/pause control presence. It does not establish button labels, accessible names, pressed state, initial label, icon semantics, or exact resume behavior. Generic target controls use native buttons and ordinary Enter/Space behavior. Previous/next controls use normal tab order; arrow-key carousel navigation is not inferred from arrow-shaped controls.

```text
ARROW_KEY_CAROUSEL_NAVIGATION=NOT_PROVEN
CAROUSEL_PICKER_OR_PAGINATION_CONTROL_EXISTENCE=NOT_PROVEN
```

Backend query pagination and carousel picker controls are separate concepts. No carousel picker is inferred from the query.

## Styling and responsive mapping

Slider Basel evidence establishes active/inactive slide styling and a mobile layout. It does not establish the exact breakpoint or the source-independent style mapping for track layout, slide sizing, state-dependent active/inactive styling, control placement, movement transitions, reduced-motion realization, or icon presentation.

PR #160 merged the generic native styling integration at the pinned base. The current `LiveFrames.NativeGenerator.StyleIntegration` implementation confirms the repository capability. That infrastructure does not map Slider Basel's styles or prove a state-dependent style trigger/target contract.

```text
SLIDER_MOBILE_BREAKPOINT=NOT_ESTABLISHED
GENERIC_NATIVE_STYLING_INTEGRATION=PRESENT_ON_MAIN
SLIDER_SPECIFIC_STYLE_MAPPING=PARTIAL
STATE_DEPENDENT_SLIDE_STYLE_REALIZATION=NOT_ESTABLISHED
STATIC=PARTIAL
```

Slider-specific style mapping remains in the Static lane. State-dependent styling also needs a Static/Behavior integration decision.

## Icon and asset authority

The accepted [C-08B1 icon inventory](c08b1_icon_source_contract.md#41-summary) records Slider Basel `fr-slider` control icon configuration:

```text
SLIDER_CONTROL_ICON_CONTENT_PRESENT=YES
PLAY_PAUSE_ICON_SOURCE=THEMIFY_CONFIGURATION
PREV_NEXT_ICON_SOURCE=SVG_REFERENCE_CONFIGURATION
ICON_RENDERABILITY_AUTHORITY=SEPARATE_BLOCKER
```

The Themify control value is a glyph configuration, not a renderable icon asset. The SVG arrow settings are references, not admitted SVG bytes. C-08 authority leaves the glyph font/external CSS and SVG asset/renderability unresolved. Do not fetch or copy SVG bytes, ship source paths, adopt Themify, or invent replacement icons in this preflight.

## Splide and Auto Scroll reconciliation

The historical conversion matrix and C-07X inventory record Splide and Auto Scroll as source widget dependencies and previously leave their target choice open. The later canonical Interaction Model explicitly says the LiveFrames Carousel target must not depend on Splide. Resolve the chronology as follows:

```text
HISTORICAL_MATRIX_EXTERNAL_STATUS=EXTERNAL_DECISION_REQUIRED
SOURCE_SPLIDE_EVIDENCE=SUPPORTED
SOURCE_AUTO_SCROLL_EVIDENCE=SUPPORTED_AS_SOURCE_DEPENDENCY_FAMILY
SPLIDE_TARGET_DEPENDENCY=NO
AUTO_SCROLL_TARGET_DEPENDENCY=NO
SLIDER_BASEL_AUTO_SCROLL_USAGE=NOT_PROVEN
GENERIC_EXTERNAL_CAROUSEL_LIBRARY_REQUIRED=NOT_PROVEN
EXTERNAL_DEPENDENCY=NONE
```

`EXTERNAL_DEPENDENCY=NONE` means current accepted evidence requires no external carousel runtime for the target. It does not mean icon renderability is resolved, and it does not preclude a separately authorized future package decision if a concrete implementation requirement calls for one. Do not treat reusable widget Auto Scroll capability as Slider Basel usage.

## Runtime, P7, and accessibility boundaries

Full interactive Carousel semantics require managed browser behavior. The current evidence does not establish the exact client implementation mechanism or any server event/state requirement.

```text
MANAGED_RUNTIME_REQUIRED=YES_FOR_FULL_CAROUSEL_SEMANTICS
CLIENT_HOOK_REQUIRED=NOT_YET_PROVEN
SERVER_EVENT_REQUIRED=NO_CURRENT_EVIDENCE
SERVER_STATE_REQUIRED=NO_CURRENT_EVIDENCE

P7_B1_STATUS=PLANNED_NOT_AUTHORIZED
P7_B1_AUTHORIZED=NO
P7_A1_STATUS=IMPLEMENTED_ACCEPTED
P7_A2_STATUS=IMPLEMENTED_ACCEPTED
SLIDER_BEHAVIOR_BINDING_CREATED=NO
PRIMITIVE_DEFINITION_VERSION_SELECTED=NO
BEHAVIOR_IMPLEMENTATION_AUTHORIZED=NO
```

### P7 1.0.5 occurrence-policy boundary

The current [P7 implementation plan](p7_interaction_conversion_implementation_plan.md) is version 1.0.5. It distinguishes occurrence-selected primitive STATE assignments in `initial_state` from primitive-specific POLICY assignments in `primitive_policy_values`. Shared cross-primitive fields remain separate: `timer_policy`, `focus_policy`, `keyboard_policy`, `motion_policy`, and `responsive_overrides`.

The Carousel policy concepts listed earlier, including loop mode, autoplay permission, pause reasons, and user-stop latch, are generic target concepts. This preflight does not assign them serialized keys or freeze their value shapes. The exact primitive definition and later P7-C authority must define allowed policy keys and values. No inferred Carousel map belongs in this evidence document.

For future authorized implementation, primitive-specific Carousel occurrence policies belong in `primitive_policy_values` only after an exact `BehaviorPrimitiveDefinition` is authorized and available. Timer configuration belongs in `timer_policy`. Reduced-motion behavior belongs in `motion_policy`. Focus, keyboard, and responsive rules remain in their respective shared policy fields. `primitive_policy_values` does not replace those fields.

```text
PRIMITIVE_POLICY_VALUES_FIELD=PLANNED_IN_P7_1_0_5
PRIMITIVE_POLICY_VALUES_IMPLEMENTED=NO
PRIMITIVE_POLICY_VALUES_SELECTED_FOR_SLIDER=NO
CAROUSEL_PRIMITIVE_POLICY_KEY_SET=NOT_FROZEN_BY_THIS_PREFLIGHT
CAROUSEL_PRIMITIVE_POLICY_VALUE_SHAPES=NOT_FROZEN_BY_THIS_PREFLIGHT
TIMER_CONFIGURATION_OWNER=timer_policy
REDUCED_MOTION_OWNER=motion_policy
P7_B1_AUTHORIZED=NO
```

P7 1.0.5 keeps DesignNode and other node/reference identity in typed structural fields. Primitive policy values cannot contain or encode DesignNode references. This preflight also does not copy source IDs into policy values. Source IDs remain provenance and do not resolve Slider's stable per-item identity:

```text
STABLE_SLIDE_IDENTITY=NOT_ESTABLISHED
DATA=PARTIAL
```

No BehaviorPrimitiveDefinition, BehaviorBinding, PrimitiveRef, version selection, binding ID, or ordinal is created by this preflight. P7-A1 and P7-A2 are accepted; P7-B1 and later work remain unauthorized.

Slider-specific accessibility evidence is incomplete. Assess control names, rotation label/state synchronization, active/inactive slide exposure, inactive focusability, slide position/name semantics, carousel region/group naming, focus continuity, pause on focus, reduced motion, announcements, any picker semantics, and future clone accessibility as separate requirements. Source feature existence does not establish these relationships. Generic Carousel policy informs target work but does not prove complete APG compliance or license invented live-region announcements.

```text
ACCESSIBILITY=PARTIAL
BEHAVIOR=PARTIAL
```

## Runtime placement, performance, and security

```text
CAROUSEL_STATE_LAYER=browser_local
SLIDE_DATA_LAYER=caller_data
POSTGRES=N/A
REDIS=N/A
CACHE=N/A
CACHE_TTL=N/A
ETS=N/A
GENSERVER=N/A
OBAN=N/A
PUBSUB=N/A
SERVER_POLLING=NO
```

Manual previous/next/play/pause and slide changes need no server round trip unless an application explicitly couples them to domain state. Rendering is O(slides × slide subtree). Behavior state is O(1) plus mounted slide/control references. Use one bounded client timer only when approved autoplay is active. Caller applications must bound the collection and must not copy complete media payloads into behavior state. At 100,000 connected clients, default server carousel-state cost is approximately zero; a timer exists only in rendered autoplay-enabled clients.

Security requirements for future implementation:

- Keep imported source scripts inert. Never execute them.
- Do not turn raw source selectors into target runtime selectors.
- Use typed, scoped, unique, deterministic target IDs. Missing or duplicate slide/control identity fails closed.
- Validate dynamic media URLs through the existing asset/URL policy.
- Keep caller collection authorization and tenant isolation host-owned.
- Do not turn source query settings into executable backend logic.
- Give timers, listeners, observers, and pointer capture bounded ownership and cleanup.
- Do not copy or bundle Splide or source package code.
- Review supply chain, license, and version separately before any future external dependency adoption.

## Blocker routing and classification

| Gap | Owner |
| --- | --- |
| Stable slide identity | Behavior/P7 plus frontend-data/componentization authority |
| Carousel runtime realization | Behavior/P7 |
| Autoplay timer, pause, and resume realization | Behavior/P7 |
| Slider active/inactive, control, and mobile styles | Static lane |
| State-dependent style integration | Static and Behavior boundary |
| Caller collection/title/media mapping | Existing frontend-data authority; mappings are already accepted |
| Final component caller API | Componentization authority |
| Play/pause and arrow icon renderability | Icon/asset authority |
| Splide/Auto Scroll | Source evidence only; no target dependency |
| Any future alternative package | Separate dependency decision only if implementation establishes a need |
| Slider-specific accessibility evidence | Frames Conversion / Evidence |
| Generic Carousel accessibility realization | Behavior/P7 |

```text
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

No private source implementation was inspected or executed. Unknown values remain unknown. This preflight creates no implementation authority.

## Authority references

- [Frames native conversion matrix](frames_native_conversion_matrix.md), Slider rows and Carousel dependency history.
- [C-07X unsupported surface inventory](c07x_unsupported_surface_inventory.md), selected-export evidence, reusable Slider widget evidence, and source dependency inventory.
- [C09A query and dynamic data contract](c09a_query_dynamic_data_contract.md), QS-04 and Slider dynamic source occurrences.
- [C09B frontend binding authority](c09b_frontend_binding_authority.md), collection/value binding contract and its identity scope.
- [C09C2 Bricks binding mapping authority](c09c2_bricks_binding_mapping_authority.md), QS-04 repeat boundary and accepted `content.title`/`media.primary` mappings.
- [Interaction Model](../09_INTERACTION_MODEL.md), especially Carousel, runtime ownership, security, and performance policy.
- [P7 interaction conversion implementation plan](p7_interaction_conversion_implementation_plan.md), P7-B1 authorization status.
- [C-08B1 icon source contract](c08b1_icon_source_contract.md) and [C-08B2A icon asset authority](c08b2a_icon_asset_authority.md), control icon source and renderability boundary.
- [C09D3 componentization authority](c09d3_componentization_plan_authority.md), final caller contract ownership.
- [Source and provenance policy](../04_SOURCE_AND_PROVENANCE.md), treatment of imported and third-party material.
