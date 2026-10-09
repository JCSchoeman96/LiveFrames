# Header Basel navigation and data mapping preflight

**Lane:** Frames Conversion / Evidence
**Status:** Evidence preflight only
**Base:** `91917eee9984a4ae215692c881fe981164d4217f`
**Base tree:** `b124af76b924398a4a7da6ba5737920f33ff7485`
**Base CI:** `37954932693 completed/success`

## Purpose and boundary

This document maps accepted Header Basel navigation, dropdown, mobile-state,
styling, accessibility, and frontend-data evidence to current LiveFrames
capabilities. It records requirements and gaps. It does not implement Header,
Behavior/P7, styling, query architecture, or icons. It does not inspect or
execute proprietary source bodies.

Canonical behavior semantics remain in
[`docs/09_INTERACTION_MODEL.md`](../09_INTERACTION_MODEL.md). The P7 plan is
implementation-boundary context only. P7-A1 and P7-A2 are accepted; P7-B1 and
later work remain unauthorized.

The source inventory reports exported settings, states, and scripts as
evidence. It does not establish complete browser behavior, generated target
markup, focus order, cleanup, or target runtime mechanisms. Source JavaScript
remains inert evidence.

## Accepted requirements and target mapping

| Requirement | Accepted evidence | Current mapping | Owner for remaining work |
| --- | --- | --- | --- |
| Header navigation and nested mobile navigation | The Header export contains nested mobile navigation. | Requirement supported; complete target structure and menu data are not established. | Frames Conversion / Evidence for missing source facts; Static for structure/style mapping. |
| Dropdown and trigger | Dropdowns and a trigger widget are present. | Existence supported. Ordinary navigation dropdowns map to the Disclosure Popup capability family. Header-specific target and state mapping is partial. | Behavior / P7 for generic lifecycle and realization; Evidence for Header-specific facts. |
| Mobile collapsed/open states | The source evidence records collapsed and open states. | State existence supported. Initial state, trigger relation, close policy, and focus behavior remain unknown unless separately accepted. | Behavior / P7. |
| Back control | A back control exists in the mobile navigation evidence. | Existence supported. Target identity and exact transition are not established. | Evidence for source identity; Behavior / P7 for an accepted target transition. |
| Height updates | The source evidence records height updates and load, resize, and DOM-change observation. | The sizing requirement is supported. Target mechanism and lifecycle are unknown. | Static for layout mapping; Behavior / P7 if a managed lifecycle proves necessary. |
| Responsive navigation | Responsive navigation exists. | Header mobile-mode threshold is not established. | Frames Conversion / Evidence for Header-specific responsive evidence; Static for style mapping. |
| Site URL | A site-scoped URL binding is accepted as `site.url`. | Supported separately from menu readiness. | Existing frontend-data authority. |
| Menu query owners | QS-01 has fifteen query-configured `Item` owners with `hasLoop=false`. | No repeat boundary or menu collection binding is established. | Frames Conversion / Evidence and existing frontend-data mapping authority. |

Source observations do not require the target to use JavaScript,
`MutationObserver`, `ResizeObserver`, a window resize handler, a LiveView hook,
a server event, a LiveComponent, a GenServer, or PubSub. These remain
unproven target mechanisms.

## Dropdown semantics and state

The canonical behavior authority defines Disclosure Popup for content revealed
from a trigger, including ordinary site-navigation dropdowns. It explicitly
keeps this family separate from the composite Menu pattern. Dropdown appearance,
nested navigation, source names/classes, scripts, and trigger-widget existence
do not establish `menu` or `menuitem` roles or composite keyboard behavior.

Do not infer arrow-key navigation, Home/End, typeahead, first-item focus,
disabled-menuitem navigation, or Menu focus management. Navigation links may
remain ordinary links inside a disclosure.

The generic disclosure state is `closed | open`, with `closed` as the generic
initial state unless accepted occurrence evidence says otherwise. This default
does not establish Header source configuration. Missing or ambiguous trigger
and target identity must fail closed; no selector search or proximity-based
target inference is permitted.

| Classification | Value |
| --- | --- |
| `DROPDOWN_DISCLOSURE_FAMILY` | `SUPPORTED_AS_TARGET_FAMILY` |
| `HEADER_SPECIFIC_DISCLOSURE_MAPPING` | `PARTIAL` |
| `HEADER_DROPDOWN_INITIAL_STATE` | `UNKNOWN_UNLESS_ACCEPTED` |
| `HEADER_TRIGGER_TARGET_IDENTITY` | `PARTIAL_OR_UNKNOWN` |
| `COMPOSITE_MENU_SEMANTICS` | `NOT_PROVEN` |
| `ARIA_MENU_PATTERN_REQUIRED` | `NOT_PROVEN` |
| `MANAGED_RUNTIME_REQUIRED` | `NOT_PROVEN` |
| `CLIENT_HOOK_REQUIRED` | `NOT_PROVEN` |
| `SERVER_EVENT_REQUIRED` | `NOT_PROVEN` |

## Mobile navigation, back control, and height updates

The accepted source facts prove that collapsed and open mobile navigation
states exist. They do not establish the initial state or open-trigger relation.
Close behavior, outside activation, Escape, focus entry, and focus return remain
unknown. A visual overlay does not prove dialog semantics or a focus trap.

The back control exists, but its target identity, exact state transition,
keyboard policy, and focus effect are not established. Do not invent a
navigation hierarchy to explain it. Caller data and behavior state are separate
concerns.

Height updates are a supported source-neutral requirement: navigation
presentation must remain correctly sized when relevant content or layout
changes. The source evidence records load, resize, and DOM-change observation.
It does not prescribe an observer or listener strategy for LiveFrames. If the
requirement later proves to need an unmodeled generic Behavior capability, stop
that implementation and route the gap to the Behavior leg.

| Classification | Value |
| --- | --- |
| `MOBILE_NAV_STATE_EXISTENCE` | `SUPPORTED` |
| `MOBILE_NAV_INITIAL_STATE` | `UNKNOWN_UNLESS_ACCEPTED` |
| `MOBILE_OPEN_TRIGGER_RELATION` | `PARTIAL_OR_UNKNOWN` |
| `MOBILE_CLOSE_POLICY` | `UNKNOWN` |
| `OUTSIDE_ACTIVATION_POLICY` | `UNKNOWN` |
| `ESCAPE_POLICY` | `UNKNOWN` |
| `FOCUS_ENTRY_POLICY` | `UNKNOWN` |
| `FOCUS_RETURN_POLICY` | `UNKNOWN` |
| `FOCUS_TRAP_REQUIRED` | `NOT_PROVEN` |
| `DIALOG_SEMANTICS_REQUIRED` | `NOT_PROVEN` |
| `BACK_CONTROL_TARGET_IDENTITY` | `NOT_ESTABLISHED` |
| `BACK_CONTROL_STATE_TRANSITION` | `PARTIAL` |
| `BACK_CONTROL_KEYBOARD_POLICY` | `NOT_PROVEN` |
| `BACK_CONTROL_FOCUS_EFFECT` | `NOT_PROVEN` |
| `HEIGHT_UPDATE_REQUIREMENT` | `SUPPORTED` |
| `SOURCE_HEIGHT_UPDATE_MECHANISM_PRESENT` | `YES` |
| `TARGET_HEIGHT_UPDATE_MECHANISM` | `UNKNOWN` |

## Responsive and stylesheet boundary

Responsive navigation is present, but no accepted Header-specific mobile-mode
breakpoint is established. Global breakpoint values such as 991px, 767px, and
478px do not prove Header's mode threshold. D1C's support for resolved
`max-width` stylesheet output is a serialization capability, not breakpoint
evidence for this component.

PR #158 adds generic native stylesheet serialization, including safe
`StyleValue` CSS-value serialization, TokenBridge CSS-variable resolution,
frozen token multiplication, deterministic private-class stylesheet blocks,
resolved `max-width` responsive rendering, fail-closed unsafe-CSS diagnostics,
and a stylesheet artifact kind. This does not establish Header-specific CSS,
style completeness, full generator wiring, or complete HEEx and stylesheet
artifact bundling.

Header-specific mapping remains partial for desktop layout, responsive layout,
mobile/off-canvas presentation if required, dropdown treatment, trigger and
back-control presentation, height/layout behavior, icons, and Header-specific
responsive values. Route these gaps to the Static leg. No CSS is defined here.

| Classification | Value |
| --- | --- |
| `RESPONSIVE_NAVIGATION_EXISTENCE` | `SUPPORTED` |
| `HEADER_MOBILE_MODE_BREAKPOINT` | `NOT_ESTABLISHED` |
| `GENERIC_NATIVE_STYLESHEET_SERIALIZATION` | `PRESENT` |
| `HEADER_SPECIFIC_STYLE_MAPPING` | `PARTIAL` |
| `STATIC` | `PARTIAL` |

## Frontend-data boundary

QS-01 records fifteen Header Basel query owners. Each has query configuration,
but `hasLoop` is false. Static sibling items and links do not establish
repetition, a repeat root, a collection parent, menu hierarchy, or record-to-
label/link mapping. No `CollectionBinding` is emitted for these owners.

Do not create `MenuQuery`, `NavigationQuery`, `HeaderQuery`, or `PostQuery`.
Future caller-data fetching, authorization, tenant isolation, filtering,
ordering, pagination, caching, and result bounds belong to the host Phoenix
application. The reusable library does not fetch menu data.

The site URL is a separate accepted scalar mapping. `{site_url}` at the
accepted source path maps to site-scoped `link_url` key `site.url`. This proves
the logo link destination only; it does not prove logo asset renderability or
menu readiness.

| Data claim | Classification |
| --- | --- |
| `QUERY_OWNER_COUNT` | `15` |
| `HAS_LOOP` | `false` |
| `QUERY_CONFIGURATION_PRESENT` | `YES` |
| `REPEAT_BOUNDARY_PROVEN` | `NO` |
| `MENU_REPEAT_BOUNDARY` | `NOT_PROVEN` |
| `MENU_COLLECTION_BINDING_EMIT` | `NO` |
| `MENU_COLLECTION_BINDING` | `NOT_ESTABLISHED` |
| `MENU_LABEL_BINDING` | `NOT_PROVEN` |
| `MENU_DESTINATION_BINDING` | `NOT_PROVEN` |
| `MENU_HIERARCHY_BINDING` | `NOT_PROVEN` |
| `MENU_CURRENT_PAGE_BINDING` | `NOT_PROVEN` |
| `SITE_URL_SOURCE_EVIDENCE` | `SUPPORTED` |
| `SITE_URL_VALUE_BINDING` | `SUPPORTED` |
| `SITE_URL_KEY` | `site.url` |
| `LOGO_LINK_DESTINATION` | `SUPPORTED` |
| `LOGO_LINK_DESTINATION_KEY` | `site.url` |
| `LOGO_ASSET_BINDING` | `NOT_ESTABLISHED` |
| `NAVIGATION_HIERARCHY_DATA` | `NOT_PROVEN` |
| `HEADER_CURRENT_PAGE_STATE` | `NOT_PROVEN` |

Do not import Slide Menu Alpha's current-page behavior into Header. A reusable
capability does not prove that Header uses it.

## Accessibility mapping

Accessibility is partial. The available evidence does not establish all
Header-specific roles, names, relationships, states, keyboard paths, or focus
effects. Assess each item separately before native conversion:

| Accessibility item | Current evidence status |
| --- | --- |
| Navigation landmark | Must be verified for Header; do not infer from a component name. |
| Dropdown trigger name | Not established by the accepted mapping. |
| Trigger/control relationship | Partial or unknown until typed target identity is accepted. |
| Expanded/collapsed exposure | Required for a disclosure realization; Header-specific mapping remains partial. |
| Ordinary-link keyboard operation | Ordinary links retain native link behavior; Header focus paths still need evidence. |
| Focus visibility | Header-specific evidence not established. |
| Hidden-content focus exclusion | Must be verified for the selected realization. |
| Mobile open/close focus behavior | Unknown. |
| Back-control naming | Not established. |
| Current-page semantics | Not proven for Header. |
| Composite Menu semantics | Not proven and not implied by a dropdown. |

Generic accessibility realization belongs to the Behavior leg. Missing
Header-specific accessibility facts belong to Frames Conversion / Evidence.

## Blocker routing and capability status

| Gap | Owning lane |
| --- | --- |
| Header-specific responsive and static styling | Static leg |
| Generic Disclosure Popup lifecycle and realization | Behavior / P7 leg |
| Mobile navigation lifecycle | Behavior / P7 leg |
| Height-update lifecycle, if managed behavior is proven necessary | Behavior / P7 leg |
| Menu repetition, labels, destinations, and hierarchy | Frames Conversion / Evidence plus existing frontend-data authority |
| `site.url` | Existing supported frontend-data authority |
| Header current-page evidence | Frames Conversion / Evidence |
| Header-specific accessibility evidence | Frames Conversion / Evidence |
| Generic accessibility realization | Behavior leg |
| Icon rendering and asset authority | Icon/asset authority |
| External runtime package | None required on current evidence |

```text
STATIC=PARTIAL
BEHAVIOR=PARTIAL
DATA=PARTIAL
ACCESSIBILITY=PARTIAL
EXTERNAL_DEPENDENCY=NONE
OVERALL=NOT_READY
NATIVE_READY=NO
```

## P7 boundary

P7-A1 and P7-A2 are implemented and accepted. P7-B1 is planned but not
authorized. This preflight identifies only a generic primitive family where
appropriate. It does not create a `BehaviorBinding` or `PrimitiveRef`, select a
`definition_version`, assign binding IDs or ordinals, implement P7-B1, or define
a Header-specific state machine.

```text
P7_A1_STATUS=IMPLEMENTED_ACCEPTED
P7_A2_STATUS=IMPLEMENTED_ACCEPTED
P7_B1_STATUS=PLANNED_NOT_AUTHORIZED
P7_B1_AUTHORIZED=NO
HEADER_BEHAVIOR_BINDING_CREATED=NO
PRIMITIVE_DEFINITION_VERSION_SELECTED=NO
```

## Runtime placement, performance, and security

Navigation open/close state belongs in the browser. Caller menu/site data is a
separate input. Local interaction does not require Postgres, Redis, a cache or
TTL, ETS, GenServer, Oban, PubSub, or server polling. Open/close must not cause
database or network work. Rendering cost scales with the number of menu nodes.

```text
NAVIGATION_STATE_LAYER=browser_local
CALLER_DATA_LAYER=caller_data
POSTGRES=N/A
REDIS=N/A
CACHE=N/A
CACHE_TTL=N/A
ETS=N/A
GENSERVER=N/A
OBAN=N/A
PUBSUB=N/A
SERVER_POLLING=NO
COMPLEXITY=O(menu nodes)
```

Security requirements for any later conversion:

- Validate navigation URL schemes under a closed policy.
- Resolve runtime targets through typed, scoped identity; reject missing,
  duplicate, or ambiguous targets.
- Do not interpret source selectors as arbitrary runtime selectors.
- Keep source JavaScript inert; never execute or translate it into target code.
- Do not turn untrusted strings into atoms, modules, events, or file paths.
- Ensure hidden navigation does not expose unintended focusable content.
- Keep menu-data authorization and tenant isolation in the host Phoenix app.

## Evidence ledger

```text
HEADER_NAVIGATION_PRESENT=YES
NESTED_MOBILE_NAVIGATION_PRESENT=YES

MOBILE_COLLAPSED_OPEN_STATES=SUPPORTED
DROPDOWN_EXISTENCE=SUPPORTED
TRIGGER_EXISTENCE=SUPPORTED
BACK_CONTROL_EXISTENCE=SUPPORTED
HEIGHT_UPDATE_REQUIREMENT=SUPPORTED
HEIGHT_UPDATE_EFFECT_EXISTENCE=SUPPORTED
SOURCE_LOAD_OBSERVATION=SUPPORTED
SOURCE_RESIZE_OBSERVATION=SUPPORTED
SOURCE_DOM_CHANGE_OBSERVATION=SUPPORTED

DROPDOWN_DISCLOSURE_FAMILY=SUPPORTED_AS_TARGET_FAMILY
HEADER_DROPDOWN_MAPPING=PARTIAL
HEADER_DROPDOWN_INITIAL_STATE=UNKNOWN_UNLESS_ACCEPTED
HEADER_TRIGGER_TARGET_IDENTITY=PARTIAL_OR_UNKNOWN
COMPOSITE_MENU_SEMANTICS=NOT_PROVEN
ARIA_MENU_PATTERN_REQUIRED=NOT_PROVEN

RESPONSIVE_NAVIGATION_EXISTENCE=SUPPORTED
HEADER_MOBILE_MODE_BREAKPOINT=NOT_ESTABLISHED

SITE_URL_VALUE_BINDING=SUPPORTED
SITE_URL_KEY=site.url

MENU_REPEAT_BOUNDARY=NOT_PROVEN
MENU_COLLECTION_BINDING=NOT_ESTABLISHED
MENU_LABEL_BINDING=NOT_PROVEN
MENU_DESTINATION_BINDING=NOT_PROVEN
MENU_HIERARCHY_DATA=NOT_PROVEN
HEADER_CURRENT_PAGE_STATE=NOT_PROVEN

MANAGED_RUNTIME_REQUIRED=NOT_PROVEN
CLIENT_HOOK_REQUIRED=NOT_PROVEN
SERVER_EVENT_REQUIRED=NOT_PROVEN

P7_B1_AUTHORIZED=NO
HEADER_BEHAVIOR_BINDING_CREATED=NO
PRIMITIVE_DEFINITION_VERSION_SELECTED=NO

GENERIC_NATIVE_STYLESHEET_SERIALIZATION=PRESENT
HEADER_SPECIFIC_STYLE_MAPPING=PARTIAL

ICON_CONTENT_PRESENT=YES
ICON_RENDERABILITY_AUTHORITY=SEPARATE_BLOCKER

STATIC=PARTIAL
BEHAVIOR=PARTIAL
DATA=PARTIAL
ACCESSIBILITY=PARTIAL
EXTERNAL_DEPENDENCY=NONE
OVERALL=NOT_READY

PRIVATE_SOURCE_INSPECTION_REQUIRED=NO
PRIVATE_SOURCE_EXECUTION=NO
PRIVATE_SOURCE_NEW_SEMANTICS=NONE
IMPLEMENTATION_AUTHORIZED=NO
```

## Authorities

- [Frames native conversion matrix](frames_native_conversion_matrix.md),
  Header row and runtime/security classifications.
- [C-07X unsupported surface inventory](c07x_unsupported_surface_inventory.md),
  Header source requirements and source-evidence limitations.
- [C09A query and dynamic data contract](c09a_query_dynamic_data_contract.md),
  QS-01 query stubs and collection-boundary rules.
- [C09B frontend binding authority](c09b_frontend_binding_authority.md),
  scalar-versus-collection binding boundaries.
- [C09C2 Bricks binding mapping authority](c09c2_bricks_binding_mapping_authority.md),
  fail-closed QS-01 and `site.url` mapping.
- [Interaction model](../09_INTERACTION_MODEL.md),
  canonical Disclosure Popup, Menu, accessibility, security, and runtime semantics.
- [Slide Menu Alpha disclosure mapping preflight](slide_menu_alpha_disclosure_mapping_preflight.md),
  related disclosure evidence that must not be transferred to Header.
- [Pricing Echo responsive behavior mapping preflight](pricing_echo_responsive_behavior_mapping_preflight.md),
  generic responsive and icon boundaries; not Header breakpoint evidence.
- [P7 interaction conversion implementation plan](p7_interaction_conversion_implementation_plan.md),
  implementation boundary context; not behavior source evidence.
- [Source and provenance](../04_SOURCE_AND_PROVENANCE.md),
  source inspection and redistribution boundary.

```text
PRIVATE_SOURCE_NEW_SEMANTICS=NONE
IMPLEMENTATION_AUTHORIZED=NO
```
