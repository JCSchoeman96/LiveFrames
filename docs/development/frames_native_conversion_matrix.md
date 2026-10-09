# Frames native conversion programme

## Purpose and baseline

This is the cross-corpus programme map for converting the supplied Frames templates into source-independent LiveFrames capabilities. It is an evidence and planning document. It does not authorize component implementation, Behavior IR, runtime hooks, native styling generation, Catalogue admission, dependency adoption, R5, C09D6-D1, or C09D7.

| Fact | Verified value |
| --- | --- |
| Repository | `JCSchoeman96/LiveFrames` |
| Base branch, commit | `main`, `3b18f94bb0ca960a4dcb6af441776addb8109b7a` |
| Base tree | `b0ae20b5bf05a29e39c665547f0d877c532c7a4a` |
| Work branch | `docs/frames-native-conversion-matrix` |
| Worktree at creation | Clean isolated worktree from exact `origin/main` |
| Exact-main CI | LiveFrames CI run `37911792128`, completed successfully; `headSha` matches the base |
| Latest main merge | PR #144, bounded CTA image-group custom CSS normalization (R4) |

The original workspace had a separate local change in `docs/09_INTERACTION_MODEL.md`. It was left untouched. The new branch was created in `.worktrees/frames-native-conversion-matrix` from the pinned remote main commit.

### Corpus identity

The three private reference trees were inventoried read-only with the C-07X digest rule: sort regular files by relative path, form each record as `path<TAB>byte-size<TAB>lowercase-file-sha256<NL>`, then SHA-256 the concatenated records. No source script was executed.

| Corpus | Records | Digest | Result |
| --- | ---: | --- | --- |
| Frames exports, `private_reference/frames/staging-2026-09/`, excluding `Archive.tar.gz` | 34 | `074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e` | Match |
| Extracted Frames widget source, `private_reference/frames/frames-components/` | 43 | `630332dcedf3807064affcbe22cfed9d16859fdd771b815a8b06d4960774de9e` | Match |
| ACSS icon subset, `private_reference/frames/acss-icons/` | 5 | `f196729484d67241ea3dc1ce066f24062a25677104907219d5660ba2654704f0` | Match |

C-08B1 records a different observed component-tree digest from its earlier worktree. The current files match the canonical C-07X digest. That resolves the current identity check; it does not retroactively change C-08B1's historical observation or add permission to interpret, use, or redistribute proprietary source. This matrix reuses accepted C-07X semantic observations and later repository authorities. It makes no new semantic claim from private implementation bodies.

## Authority and provenance boundary

`docs/04_SOURCE_AND_PROVENANCE.md` owns mutable provenance, internal-use, redistribution, publication, and human-governance facts. A digest establishes identity only. Possession, hashing, technical inspection, a private-reference path, or successful conversion does not establish internal-use scope, ownership, license, or redistribution permission. No permission transition is made here.

Evidence in this document uses two separate vocabularies:

| Evidence state | Meaning |
| --- | --- |
| `observed` | A recorded source or repository observation that has not been reproduced against its pinned identity. |
| `verified` | The observation was reproduced against the stated source identity or current repository artifact. |
| `accepted` | A repository authority or project owner explicitly accepts the claim for its stated scope. |
| `conflicted` | Valid evidence disagrees; neither value is silently selected. |
| `superseded` | Newer accepted authority explicitly replaces the earlier claim. |

Allowed movement is `observed → verified → accepted`, `observed|verified → conflicted`, and `accepted → superseded`. Technical verification alone cannot mark a claim accepted. A source identity change invalidates verified claims tied to that identity. A newer authority invalidates only the claims it explicitly replaces.

If an implementation lane needs a new interpretation of proprietary source, record `EVIDENCE_INSUFFICIENT`, `blocking_authority=PRIVATE_SOURCE_AUTHORITY`, and `STOP=PRIVATE_SOURCE_AUTHORITY_UNCLEAR` for that inference. The lane may continue on accepted evidence that does not depend on the missing interpretation.

## Deterministic readiness vocabulary

These labels describe independent layers. Keep multiple blockers visible in the row tables instead of collapsing them into one status.

| Status | Definition |
| --- | --- |
| `STATIC_READY` | Required static semantics and styling authorities are accepted and implemented for the stated scope. This does not imply full component readiness. |
| `STATIC_PARTIAL` | Some static semantics or styling are supported; at least one required static or style case remains unresolved. |
| `STATIC_BLOCKED` | A required static path is blocked by an explicit upstream authority or implementation gate. |
| `BEHAVIOR_REQUIRED` | A required interaction lifecycle lacks accepted behavior authority, implementation, or both. |
| `BEHAVIOR_PARTIAL` | Some behavior is represented or implemented, but a required lifecycle segment remains unresolved. |
| `N/A` | The layer is not established as a requirement for this row; it is not a support verdict. |
| `QUERY_REQUIRED` | Historical compatibility label for a source collection/value surface with no accepted frontend-data representation. LiveFrames does not execute a source query. |
| `QUERY_PARTIAL` | Historical compatibility label for partial frontend collection/value support or unresolved source-to-input mapping. |
| `EXTERNAL_DECISION_REQUIRED` | A needed external capability has no accepted project decision. |
| `EVIDENCE_INSUFFICIENT` | Available accepted evidence cannot establish the specific claim. |
| `NATIVE_READY` | Every required static, styling, behavior, frontend-data, accessibility, external-dependency, generation, and browser-verification layer is accepted and implemented, with no required Frames, Bricks, ACSS, or source-runtime dependency. |

`NATIVE_READY` does not follow from parsing, normalization, an IR record, or generator availability. No selected template is `NATIVE_READY` in this matrix.

## Source-class taxonomy and corpus inventory

These are distinct evidence and implementation classes. A source query setting is evidence, not a LiveFrames backend primitive. A source widget existing in the extracted source tree does not prove that a selected export uses it.

| Source class | Examples in this programme | LiveFrames boundary |
| --- | --- | --- |
| Template/export | Nine Bricks fragments and associated captures | Input evidence; no source runtime is carried forward. |
| Reusable Frames widget/component | Modal, Trigger, Slider, Slider Controls, Tabs, Accordion, Color Scheme, Table of Contents, Switch, Notes | Independent source inventory; selected-template consumption must be separately evidenced. |
| ACSS utility/framework capability | Token values, icon styles, responsive variables, spacing, typography, grid recipes | Source styling evidence; only accepted source-independent semantics enter LiveFrames. |
| Bricks native primitive | `nav-nested`, dropdown, image/lightbox settings, code element, section/container/image/text | Source serialization/configuration evidence, not a runtime dependency or query engine. |
| External runtime dependency | Splide, Splide Auto Scroll, Flubber; possible future dialog/focus helper | Requires a separate project decision before dependent implementation. |
| LiveFrames-native primitive | Section, Container, Heading, Text, Image, Link, Button, collection/value inputs, future behavior capabilities | Source-neutral target concepts; this matrix does not authorize their implementation. |

The nine canonical exports are:

| Template | Accepted C-07X capability evidence | Main dependency families |
| --- | --- | --- |
| CTA Tango | Static composition, grid/layout, image composition, typography, CTA, responsive styling | Static styling and native style emission; R5 remains the gate. |
| Feature Milan | Repeated feature data, selection/tabs, timed rotation, active/hidden state, frontend collection/value bindings | Selection, timer lifecycle, caller data, responsive behavior. |
| Feature Romeo | Linked cards, hover/focus-within presentation, pointer interactions, responsive layout | Static styling, pointer/focus semantics, accessibility. |
| Gallery Bravo | Repeated media collection, result count, responsive grid, lightbox configuration and captures | Caller collection/count, renderable asset semantics, overlay behavior. |
| Header Basel | Nested navigation, dropdowns, trigger, responsive/mobile navigation, site URL binding, query/menu evidence | Navigation lifecycle, site binding, unresolved menu repetition semantics. |
| Hero Barcelona | Decorative moving columns, repeated media collections, motion, duplicated `aria-hidden` content | Collection input, carousel/motion reuse, decorative content accessibility. |
| Pricing Echo | Monthly/yearly selection, feature rows, icons, mobile accordion conversion | Tabs, accordion, responsive continuity, icons/assets. |
| Slide Menu Alpha | `details`/`summary` groups, current-page presentation, transitions, reduced motion | Disclosure, nested groups, current-page state, accessibility. |
| Slider Basel | Carousel, loop, controls, play/pause, autoplay, repeated slide data, responsive layout | Carousel lifecycle, caller collection, playback, dependency decision. |

The extracted reusable widget inventory is separate: Modal; Trigger; Slider; Slider Controls; Tabs; Accordion; Color Scheme; Table of Contents; Switch; Notes. C-07X records source-only or builder-specific behavior for each. The selected exports do not establish a consumer for every source widget. Notes is builder annotation metadata rather than a frontend conversion target on current evidence.

## Canonical matrix fields

The following tables join on `ID`. Each row carries the requested schema across identity/evidence, dependencies/readiness, target/consumers, and runtime/risk. `SOURCE_NODE_OR_SETTING_ID` is explicit even when accepted repository evidence does not preserve a stable node/setting ID. In that case it says so rather than inventing one.

### Identity and evidence

| ID | source_class | source_component_or_template | source_capability | source_node_or_setting_id | source_evidence | source_sha_or_digest | primitive_family | provenance_status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T-CTA | template/export | CTA Tango | Static structure, responsive composition, image group | Not present in the cited accepted summary; no ID inferred | C-07X §53; C09D6-D0R1 and D0E/R authority chain | Export digest above | Static structure; native styling | Accepted historical repository evidence; current status rebased below |
| T-MILAN | template/export | Feature Milan | Collection repetition, feature values, selection, timer | Not present in cited accepted summary; no ID inferred | C-07X §53 and §519; C09A/C09B/C09C2 | Export digest above | Frontend data; selection; timed state | Accepted historical repository evidence |
| T-ROMEO | template/export | Feature Romeo | Linked card structure; hover/focus presentation | Not present in cited accepted summary; no ID inferred | C-07X §53 and §519 | Export digest above | Static structure; pointer/focus | Accepted historical repository evidence |
| T-GALLERY | template/export | Gallery Bravo | Repeated media, result count, lightbox | Not present in cited accepted summary; no ID inferred | C-07X §53 and §519; C09A/C09C2 | Export digest above | Frontend data; overlay | Accepted historical repository evidence; asset semantics remain limited |
| T-HEADER | template/export | Header Basel | Navigation, menu/query evidence, site URL | Not present in cited accepted summary; no ID inferred | C-07X §53; C09A/C09B/C09C2 | Export digest above | Navigation; frontend data | Accepted historical repository evidence; query mapping is fail-closed |
| T-HERO | template/export | Hero Barcelona | Repeated media, decorative motion, hidden duplicate content | Not present in cited accepted summary; no ID inferred | C-07X §53 and §519; C09A/C09B/C09C2 | Export digest above | Frontend data; carousel/motion; accessibility | Accepted historical repository evidence |
| T-PRICING | template/export | Pricing Echo | Tabs, static feature rows, icon content, responsive accordion | Not present in cited accepted summary; no ID inferred | C-07X §53; C09A §5 (Pricing has no query owner); C08B1/C08B2A | Export digest above | Selection; accordion; icon/assets | Accepted historical repository evidence |
| T-MENU | template/export | Slide Menu Alpha | Nested disclosure, current-page presentation, reduced motion | Not present in cited accepted summary; no ID inferred | C-07X §53 and §519 | Export digest above | Disclosure; navigation; accessibility | Accepted historical repository evidence |
| T-SLIDER | template/export | Slider Basel | Repeated slides, loop, controls, playback | Not present in cited accepted summary; no ID inferred | C-07X §53 and §519; C09A/C09B/C09C2 | Export digest above | Carousel; playback; frontend data | Accepted historical repository evidence |
| W-MODAL | reusable Frames widget | Modal | Overlay, trigger, close, focus and media lifecycle evidence | C-07X F01; no source node ID asserted | C-07X §168, §273 | Component digest above | Overlay; accessibility; behavior | Accepted historical repository evidence; no new source interpretation |
| W-TRIGGER | reusable Frames widget | Trigger | Button, target relation, expanded state | C-07X F02; no source node ID asserted | C-07X §168, §297 | Component digest above | Navigation trigger; behavior | Accepted historical repository evidence; no new source interpretation |
| W-SLIDER | reusable Frames widget | Slider | Carousel state and autoplay | C-07X F03; no source node ID asserted | C-07X §168, §321 | Component digest above | Carousel; playback | Accepted historical repository evidence; no new source interpretation |
| W-SLIDER-CONTROLS | reusable Frames widget | Slider Controls | Synchronization to owning slider | C-07X F04; no source node ID asserted | C-07X §168, §347 | Component digest above | Carousel controls | Accepted historical repository evidence; no new source interpretation |
| W-TABS | reusable Frames widget | Tabs | Selection and responsive accordion mode | C-07X F05; no source node ID asserted | C-07X §168, §371 | Component digest above | Selection; accordion | Accepted historical repository evidence; no new source interpretation |
| W-ACCORDION | reusable Frames widget | Accordion | Disclosure, keyboard/hash and legacy/new variant evidence | C-07X F06; no source node ID asserted | C-07X §168, §396 | Component digest above | Disclosure; accordion | Accepted historical repository evidence; canonical source flag unresolved |
| W-SCHEME | reusable Frames widget | Color Scheme | Theme state and icon morph | C-07X F07; no source node ID asserted | C-07X §168, §421 | Component digest above | Theme state; icons; external decision | Accepted historical repository evidence; no new source interpretation |
| W-TOC | reusable Frames widget | Table of Contents | Heading discovery and active heading evidence | C-07X F08; no source node ID asserted | C-07X §168, §446 | Component digest above | Page-derived UI | Accepted historical repository evidence; canonical source flag unresolved |
| W-SWITCH | reusable Frames widget | Switch | Two-content selection | C-07X F09; no source node ID asserted | C-07X §168, §471 | Component digest above | Content switch; behavior | Accepted historical repository evidence; no new source interpretation |
| W-NOTES | reusable Frames widget | Notes | Bricks editor annotation | C-07X F10; no source node ID asserted | C-07X §168, §495 | Component digest above | Builder-only metadata | Accepted historical repository evidence |

### Dependencies and readiness

| ID | static_semantic_dependency | styling_dependency | behavior_dependency | frontend_data_dependency | accessibility_dependency | external_dependency | static_status | behavior_status | data_status | external_status | current_support_status | blocking_authority |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T-CTA | Static tree and image/CTA semantics | R2/R2A/R3/R4 accepted; native style generation remains gated | None for the static tracer | None established | Image alt and link/button semantics | None | `STATIC_BLOCKED` | N/A | N/A | N/A | `STATIC_BLOCKED` | R5 D0 rerun; D1 not authorized before R5 |
| T-MILAN | Feature-card structure | Responsive style and state visibility | Selection, timer guards/effects, pause and cleanup | Collection/item values; current bindings do not prove every source target | Selected/hidden state and keyboard model | None proven | `STATIC_PARTIAL` | `BEHAVIOR_REQUIRED` | `QUERY_PARTIAL` | None proven | Static + behavior + frontend-data blockers | Behavior Architecture; C09C mapping; componentization |
| T-ROMEO | Four linked card structure | Card layout and responsive rules | Pointer/focus state; CSS-only sufficiency not yet accepted | None established | Focus visibility and link semantics | None | `STATIC_PARTIAL` | `BEHAVIOR_REQUIRED` pending CSS-versus-managed-state decision | N/A | N/A | Static styling and behavior decision | Styling authority; Behavior Architecture if CSS cannot carry all semantics |
| T-GALLERY | Grid and media structure | Responsive grid | Lightbox lifecycle | Collection/count input; renderable asset semantics are not established for this case | Dialog entry/exit, focus, Escape, restoration, names | Lightbox/dialog choice open | `STATIC_PARTIAL` | `BEHAVIOR_REQUIRED` | `EVIDENCE_INSUFFICIENT` | `EXTERNAL_DECISION_REQUIRED` | Data, behavior, asset and overlay blockers | C09C2; Behavior Architecture; dialog/lightbox decision owner |
| T-HEADER | Static navigation structure | Responsive layout | Dropdown, trigger, resize/update/cleanup lifecycle | Site value has accepted mapping; menu repetition/label/destination/hierarchy not proven | Navigation semantics, expanded/current state, keyboard | None accepted | `STATIC_PARTIAL` | `BEHAVIOR_REQUIRED` | `EVIDENCE_INSUFFICIENT` for menu collection; site binding is separate | None | Data and behavior blockers | C09A/C09C2 fail-closed mapping; Behavior Architecture |
| T-HERO | Static hero and duplicate-content structure | Responsive columns and motion styles | Carousel/motion state and cleanup | Repeated media collection inputs | `aria-hidden` duplicate relationship and focus exclusion | Carousel dependency decision shared with Slider | `STATIC_PARTIAL` | `BEHAVIOR_REQUIRED` | `QUERY_PARTIAL` | `EXTERNAL_DECISION_REQUIRED` for carousel only if chosen | Multiple blockers | Behavior Architecture; C09C2; carousel decision |
| T-PRICING | Pricing structure and feature rows | Responsive tabs-to-accordion presentation; icon CSS/asset path | Selection continuity through responsive mode change | Static feature rows; no caller-data binding established | Tabs/accordion relationship, names, selected/expanded state | Icon asset source decision is unresolved | `STATIC_PARTIAL` | `BEHAVIOR_REQUIRED` | `N/A` | `EVIDENCE_INSUFFICIENT` for icon renderability | Static/style, behavior, responsive continuity, icon and accessibility blockers | Behavior Architecture; C08B; componentization authority |
| T-MENU | Nested disclosure/navigation structure | Reduced-motion and transition styling | Disclosure/current-page lifecycle | No source collection established | Details/summary semantics; current-page and nested keyboard behavior | None | `STATIC_PARTIAL` | `BEHAVIOR_REQUIRED` | N/A | None | Static mapping and behavior authority blockers | Behavior Architecture; accessibility authority |
| T-SLIDER | Slide structure and controls | Responsive slide presentation | Index, loop, control, autoplay/play/pause, reduced motion, destroy | Repeated slide collection | Control names, focus, announcements, clone/DOM ownership | Splide and Auto Scroll undecided | `STATIC_PARTIAL` | `BEHAVIOR_REQUIRED` | `QUERY_PARTIAL` | `EXTERNAL_DECISION_REQUIRED` | Carousel, data, accessibility and dependency blockers | Behavior Architecture; external dependency decision owner; C09C2 |

### Target, phase, runtime and risk

| ID | recommended_native_primitive | recommended_implementation_phase | recommended_tracer | downstream_consumers | runtime_state_owner | security_risks | performance_scaling_class | invalidation_trigger | next_required_authority |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T-CTA | Section, Container, Heading, Text, Image, Link, Button; package-owned node styles | External R5 → authorized D1 → C09D7 only after gates | CTA Tango remains the static styling tracer | Static templates | `caller_data` only if later API exposes values; otherwise `browser_local` | Unsafe URL/HTML/attributes, CSS source leakage, generated ID collision | O(nodes + styles); browser-local output | R5 rerun, style authority, Design IR or generator change | R5 authority; later D1/C09D7 authority |
| T-MILAN | Collection Input, Repeater, Collection Item Scope, Value Binding, Selection | After Behavior and mapping authority; after simpler disclosure/selection prerequisites | Feature Milan | Feature cards; later content lists | `browser_local` state; `caller_data` input | Unsafe dynamic text/URL/attributes, data leakage, timer/listener cleanup | O(items × subtree); host owns data size | C09C2 or Behavior authority changes; new source evidence | Behavior Architecture; frontend-data mapping authority |
| T-ROMEO | Link cards plus Hover/Focus State | CSS candidate first, then managed behavior only if required | Feature Romeo | Card patterns | `browser_local` if runtime is required | Unsafe href/open redirect; focus escape or hidden focus | O(cards); no backend work | Style/accessibility evidence or pointer lifecycle authority | Static styling and accessibility authority; Behavior Architecture if needed |
| T-GALLERY | Collection Input, Repeater, Asset Value Binding, Count Binding, Dialog/Lightbox | After data and overlay decisions | Gallery Bravo | Media galleries | `caller_data` collection; `browser_local` overlay state | Unsafe asset URL, query/data leakage, focus escape, DOM target collision | O(items); host bounds query/results | Accepted asset semantics or overlay decision changes | C09C2 asset-target authority; Behavior Architecture; dialog decision |
| T-HEADER | Navigation, Dropdown, Trigger, Site Value Binding | After Disclosure foundation and separate menu-data resolution | Header Basel | Navigation patterns | `browser_local`; `caller_data` site/menu inputs | Unsafe URL/open redirect, data leakage, selector collision, observer cleanup | O(menu items); host supplies bounded list | Any accepted menu repeat evidence or C09C2 remapping | Behavior Architecture; C09A/C09C2 evidence owner |
| T-HERO | Section/Container, Collection Input, Repeater, Asset/Link bindings, carousel presentation | Reuse approved Carousel capability after Slider | Hero Barcelona | Decorative media section | `browser_local` animation; `caller_data` media | Unsafe asset/link URL, duplicate focusable content, data leakage | O(items × tracks); host bounds list | Accessibility or carousel authority change | Behavior Architecture; caller-data authority; carousel decision |
| T-PRICING | Tabs, Disclosure/Accordion, static feature rows, icon reference | After Disclosure and Selection authorities | Pricing Echo | Pricing sections and responsive selectors | `browser_local` | Unsafe URLs, untrusted asset references, focus/ARIA mismatch | O(features); static subtree | C08B, componentization, or responsive state authority changes | Behavior Architecture; C08B icon authority; componentization |
| T-MENU | Disclosure group, nested Navigation, Current-page State | Disclosure tracer before Pricing/Header | Slide Menu Alpha | Header, Accordion | `browser_local` | Unsafe href, invalid nested target, focus/ARIA mismatch | O(menu nodes); no backend work | Current-page evidence or Behavior/accessibility authority change | Behavior Architecture; accessibility authority |
| T-SLIDER | Slider/Carousel, Carousel Controls, Collection Input, Timed Rotation, Play/Pause | Primary functional carousel tracer after decision | Slider Basel | Hero Barcelona, future carousel users | `browser_local`; caller supplies slides | External package supply chain, unsafe URLs, DOM collision, observer/listener cleanup | O(slides); bounded caller input; no server polling | Dependency, Behavior, collection or accessibility authority change | Behavior Architecture; external dependency decision owner; C09C2 |

### Reusable widget capability rows

These rows account for all ten source widgets independently from the nine selected exports. They use the same IDs and identity/evidence records above. A widget row is not a claim that a selected template consumes it or that its source behavior is ready for LiveFrames.

| ID | static_semantic_dependency | styling_dependency | behavior_dependency | frontend_data_dependency | accessibility_dependency | external_dependency | static_status | behavior_status | data_status | external_status | current_support_status | blocking_authority | recommended_native_primitive | recommended_implementation_phase | recommended_tracer | downstream_consumers | runtime_state_owner | security_risks | performance_scaling_class | invalidation_trigger | next_required_authority |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| W-MODAL | Overlay/trigger/close structure | Overlay and placement styles | Focus, close, media and scroll lifecycle | No selected data consumer established | Focus entry/trap/restore, Escape, trigger relation | YouTube/Vimeo behavior; dialog helper undecided | `STATIC_PARTIAL` | `BEHAVIOR_REQUIRED` | N/A | `EXTERNAL_DECISION_REQUIRED` for media/dialog scope | No selected-template consumer; source behavior not native | Behavior Architecture; dialog/media decision | Dialog/Overlay | Consumer-led later phase | No selected tracer | Future overlay consumers | `browser_local` | Selector injection, focus escape, unsafe embed URL, scroll/listener cleanup | O(overlays); no backend work | New consumer or accepted overlay contract | Behavior Architecture; dependency owner |
| W-TRIGGER | Button and target relation | Button/burger presentation | Toggle and expanded-state lifecycle | Target may be caller markup; no query implied | Name, controls relation, expanded state | None established | `STATIC_PARTIAL` | `BEHAVIOR_REQUIRED` | N/A | None | No selected consumer confirmed as exact widget mapping | Behavior Architecture; target/ID authority | Button + Navigation Trigger | With Disclosure/Navigation foundations | Slide Menu only if equivalence is accepted | Header/navigation consumers | `browser_local` | DOM target collision, arbitrary selector, ARIA relation mismatch | O(1) per trigger; no backend work | Target model or selected consumer changes | Behavior Architecture; accessibility authority |
| W-SLIDER | Track/slide/control structure | Carousel layout | Index, loop, sync, autoplay, teardown | No accepted frontend-data mapping for this separate widget | Controls, focus, announcements, clone policy | Splide and Auto Scroll undecided | `STATIC_PARTIAL` | `BEHAVIOR_REQUIRED` | `N/A` | `EXTERNAL_DECISION_REQUIRED` | Slider Basel is a related tracer, not proof of exact widget equivalence | Behavior Architecture; dependency owner; data mapping only if a later consumer requires it | Slider/Carousel | After lifecycle and dependency decisions | Slider Basel candidate | Hero Barcelona if accepted reuse | `browser_local` | Supply-chain, URL, clone focus, ID collision, cleanup | O(slides); local presentation state | Dependency/API or behavior contract changes | Behavior Architecture; external decision owner |
| W-SLIDER-CONTROLS | Control buttons and synchronization identity | Control layout | State synchronization with owning slider | No independent data input | Button names, disabled/current state | Coupled to Slider decision | `STATIC_PARTIAL` | `BEHAVIOR_REQUIRED` | N/A | `EXTERNAL_DECISION_REQUIRED` through Slider | Requires an accepted owning Slider contract | Behavior Architecture; Slider decision | Carousel Controls | With Slider | Slider Basel candidate | Future carousel users | `browser_local` | Unmatched IDs, target collision, stale owner reference | O(controls); no backend work | Slider contract or ID model changes | Behavior Architecture |
| W-TABS | Tab/panel structure | Tab/selected/hidden styling | Selection and responsive mode transition | Optional panel values; no query assumed | Roles, selected state, keyboard and panel relation | None established | `STATIC_PARTIAL` | `BEHAVIOR_REQUIRED` | N/A absent a selected data consumer | None | Pricing/Milan are related exports; exact widget mapping still needs authority | Behavior Architecture; accessibility authority | Tabs + Selection | After Disclosure semantics | Pricing Echo | Feature Milan only after mapping | `browser_local` | Focus/state mismatch, generated ID collision | O(panels); no backend work | Behavior contract or responsive mode change | Behavior Architecture |
| W-ACCORDION | Disclosure group | Expanded/collapsed and transition styles | Single/multi-open, keyboard/hash lifecycle | Optional repeated panels; no backend query implied | Heading/button semantics, expanded state | None established | `STATIC_PARTIAL` | `BEHAVIOR_REQUIRED` | N/A absent selected data consumer | None | Legacy/new source variant unresolved | Behavior Architecture; source-variant evidence owner | Disclosure Group / Accordion | After Slide Menu disclosure tracer | Slide Menu Alpha is related but not proof of widget equivalence | Pricing Echo if policy accepted | `browser_local` | Invalid target, focus/state mismatch, listener cleanup | O(panels); no backend work | Canonical source variant or behavior contract changes | Behavior Architecture; source evidence owner |
| W-SCHEME | Scheme control and icon | Theme tokens and transition styles | Preference, global state and motion lifecycle | No caller data established | Control name, pressed state, preference semantics | Flubber undecided; ACSS runtime excluded | `STATIC_PARTIAL` | `BEHAVIOR_REQUIRED` | N/A | `EXTERNAL_DECISION_REQUIRED` for morph only | No selected-template consumer established | Theme/Behavior authority; dependency owner | Theme State | Consumer-led later phase | None in selected exports | Future theme consumers | `browser_local` | Global state collision, persistence/privacy, motion cleanup | O(1); no backend work unless persistence is approved | Theme preference or motion authority changes | Behavior Architecture; theme decision owner |
| W-TOC | Heading inventory/list structure | Active item and scroll presentation | Active-heading tracking and observer cleanup | Page headings are input context, not a backend collection | Link names, active state and scroll/focus behavior | No library established | `STATIC_PARTIAL` | `BEHAVIOR_REQUIRED` | N/A | None | No selected-template consumer; legacy/new path unresolved | Behavior Architecture; source-variant evidence owner | Page-derived TOC | Consumer-led later phase | None in selected exports | Future long-form content | `browser_local` | Unsafe href, selector collision, observer cleanup | O(headings) per rebuild; no backend work | Heading model or observer lifecycle changes | Behavior Architecture |
| W-SWITCH | Two-content/control structure | Indicator and content visibility | Two-state selection | No caller data established | Button name and pressed state | None established | `STATIC_PARTIAL` | `BEHAVIOR_REQUIRED` | N/A | None | No selected-template consumer established | Behavior Architecture; accessibility authority | Content Switch | Consumer-led later phase | None in selected exports | Future two-panel patterns | `browser_local` | Missing target, unexpected child count, state/ARIA mismatch | O(1); no backend work | Consumer or behavior contract changes | Behavior Architecture |
| W-NOTES | Builder annotation only | Bricks editor decoration | Editor polling/subscription lifecycle only | No frontend data | No frontend accessibility contract established | Bricks editor runtime is out of scope | N/A for frontend | N/A for frontend | N/A | N/A | `EVIDENCE_INSUFFICIENT` for any frontend conversion; defer builder feature | Product/editor authority | No frontend primitive | Defer unless editor integration is authorized | None | None in selected templates | `browser_local` only for a future editor UI | Untrusted editor markup, polling and observer cleanup | N/A to frontend conversion | Authorized editor integration scope | Product/repository authority |

## Evidence ledger

The ledger records the evidence lifecycle and limits for the claims used above. `SOURCE_NODE_OR_SETTING_ID` is marked unavailable where the cited accepted authority does not expose one. A future source-specific claim must add a focused record rather than silently widening these summaries.

### E-CORPUS-01

```text
EVIDENCE_ID=E-CORPUS-01
CAPABILITY_ID=CORPUS
CLAIM=The current supplied export, extracted widget, and ACSS icon trees match the canonical C-07X identities.
STATE=verified
SOURCE_TYPE=private source identity metadata and file bytes
SOURCE_PATH=private_reference/frames/staging-2026-09/; private_reference/frames/frames-components/; private_reference/frames/acss-icons/
SOURCE_SHA_OR_DIGEST=074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e; 630332dcedf3807064affcbe22cfed9d16859fdd771b815a8b06d4960774de9e; f196729484d67241ea3dc1ce066f24062a25677104907219d5660ba2654704f0
SOURCE_COMPONENT=34 export records; 43 widget source records; 5 icon records
SOURCE_NODE_OR_SETTING_ID=not applicable to tree identity
OBSERVATION=Read-only deterministic record hashing produced the counts and digests in the corpus table.
WHAT_THIS_PROVES=Identity of the current supplied bytes relative to the recorded canonical digests.
WHAT_THIS_DOES_NOT_PROVE=Ownership, license, internal-use scope, redistribution, or new semantic permission.
REPRODUCTION_METHOD=Sorted relative paths; path, byte size, file SHA-256 records; SHA-256 of concatenated records.
DOWNSTREAM_CONSUMERS=All matrix rows, subject to accepted evidence scope.
INVALIDATION_TRIGGER=Any byte or path change, different archive exclusion, or changed canonical digest rule.
```

### E-TEMPLATES-01

```text
EVIDENCE_ID=E-TEMPLATES-01
CAPABILITY_ID=T-CTA..T-SLIDER
CLAIM=The nine named exports have the capability families summarized in this matrix.
STATE=accepted
SOURCE_TYPE=repository audit authority
SOURCE_PATH=docs/development/c07x_unsupported_surface_inventory.md §53 and §519
SOURCE_SHA_OR_DIGEST=074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e
SOURCE_COMPONENT=CTA Tango; Feature Milan; Feature Romeo; Gallery Bravo; Header Basel; Hero Barcelona; Pricing Echo; Slide Menu Alpha; Slider Basel
SOURCE_NODE_OR_SETTING_ID=not preserved in the cited C-07X summary; none inferred here
OBSERVATION=C-07X records template-level evidence, behavior limits, query/data evidence, and screenshot limits.
WHAT_THIS_PROVES=The repository-accepted historical inventory can guide this programme map.
WHAT_THIS_DOES_NOT_PROVE=Current implementation readiness, behavior between screenshots, node-level mappings, or new proprietary-source semantics.
REPRODUCTION_METHOD=Reference C-07X claim and its recorded canonical export digest; do not execute source scripts.
DOWNSTREAM_CONSUMERS=All nine template rows.
INVALIDATION_TRIGGER=New accepted source identity, a superseding evidence audit, or authority correction.
```

### E-WIDGETS-01

```text
EVIDENCE_ID=E-WIDGETS-01
CAPABILITY_ID=W-MODAL..W-NOTES
CLAIM=The ten named widget families are present in the historical C-07X source inventory.
STATE=accepted
SOURCE_TYPE=repository audit authority
SOURCE_PATH=docs/development/c07x_unsupported_surface_inventory.md §168 and §265–518
SOURCE_SHA_OR_DIGEST=630332dcedf3807064affcbe22cfed9d16859fdd771b815a8b06d4960774de9e
SOURCE_COMPONENT=Modal; Trigger; Slider; Slider Controls; Tabs; Accordion; Color Scheme; Table of Contents; Switch; Notes
SOURCE_NODE_OR_SETTING_ID=C-07X F01–F10 family IDs; not source node IDs
OBSERVATION=C-07X separates source implementation inventory from selected export behavior.
WHAT_THIS_PROVES=These reusable source widget families are accounted for in prior accepted repository evidence.
WHAT_THIS_DOES_NOT_PROVE=That every widget is consumed by a selected template, that a source flag is active, or that new private-source interpretation is permitted.
REPRODUCTION_METHOD=Review the cited C-07X inventory against its canonical identity; no script execution.
DOWNSTREAM_CONSUMERS=Widget inventory; overlay, navigation, carousel, selection, disclosure, theme, page-derived and builder-only families.
INVALIDATION_TRIGGER=Component corpus identity changes or a superseding accepted widget authority.
```

### E-DATA-01

```text
EVIDENCE_ID=E-DATA-01
CAPABILITY_ID=FRONTEND-DATA
CLAIM=LiveFrames consumes caller-supplied collection and value inputs; host applications own queries and backend policy.
STATE=accepted
SOURCE_TYPE=repository authority
SOURCE_PATH=docs/development/c09a_query_dynamic_data_contract.md; docs/development/c09b_frontend_binding_authority.md; docs/development/c09c2_bricks_binding_mapping_authority.md
SOURCE_SHA_OR_DIGEST=export digest recorded by C09A: 074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e
SOURCE_COMPONENT=frontend collection/value contract
SOURCE_NODE_OR_SETTING_ID=C09A/C09C2 evidence IDs where cited by those authorities; no extra source IDs inferred
OBSERVATION=C09B defines CollectionBinding and ValueBinding; C09C2 has a closed source mapping and rejects unproven Header repetition.
WHAT_THIS_PROVES=The compiler-facing model is frontend-only and fail-closed.
WHAT_THIS_DOES_NOT_PROVE=That a host query is authorized, that every source expression is supported, or that an attachment has a renderable asset target.
REPRODUCTION_METHOD=Read accepted C09A/C09B/C09C2 contracts and inspect current binding structs/normalizer without using source runtime.
DOWNSTREAM_CONSUMERS=Feature Milan, Gallery Bravo, Header Basel, Hero Barcelona, Slider Basel.
INVALIDATION_TRIGGER=C09B/C09C authority amendment, Design IR version change, or new accepted mapping evidence.
```

### E-IMPLEMENTATION-01

```text
EVIDENCE_ID=E-IMPLEMENTATION-01
CAPABILITY_ID=GENERATOR-AND-BINDINGS
CLAIM=Current main contains Design IR 3.0.0, collection/value binding models and NativeGenerator.
STATE=verified
SOURCE_TYPE=current repository code
SOURCE_PATH=apps/live_frames/lib/live_frames/ir/design_document.ex; apps/live_frames/lib/live_frames/ir/collection_binding.ex; apps/live_frames/lib/live_frames/ir/value_binding.ex; apps/live_frames/lib/live_frames/native_generator.ex
SOURCE_SHA_OR_DIGEST=main 3b18f94bb0ca960a4dcb6af441776addb8109b7a
SOURCE_COMPONENT=IR and deterministic native Phoenix/HEEx generation code
SOURCE_NODE_OR_SETTING_ID=not applicable
OBSERVATION=DesignDocument declares current IR 3.0.0; binding structs and generator entry point are present.
WHAT_THIS_PROVES=These current repository capabilities exist at the base commit.
WHAT_THIS_DOES_NOT_PROVE=That an interactive Frames template is componentized, behavior is implemented, native styling is complete, or browser verification passed.
REPRODUCTION_METHOD=Read the pinned main source files; no tests or runtime code were executed for this documentation slice.
DOWNSTREAM_CONSUMERS=All future native generation lanes.
INVALIDATION_TRIGGER=Generator, IR or binding code changes, or a new accepted generation authority.
```

### E-CTA-01

```text
EVIDENCE_ID=E-CTA-01
CAPABILITY_ID=T-CTA
CLAIM=CTA Tango remains blocked pending R5, despite accepted and merged upstream R2/R2A/R3/R4 work.
STATE=accepted
SOURCE_TYPE=repository styling authority
SOURCE_PATH=docs/development/c09d6d_upstream_style_gap_resolution_authority.md; docs/development/c09d6d_cta_tango_style_coverage_preflight.md
SOURCE_SHA_OR_DIGEST=main 3b18f94bb0ca960a4dcb6af441776addb8109b7a
SOURCE_COMPONENT=CTA Tango static D0 coverage lane
SOURCE_NODE_OR_SETTING_ID=CTA-D0 identifiers in the historical preflight; no new source IDs introduced
OBSERVATION=R2/R2A/R3/R4 close upstream representation gaps; the authority assigns the D0 rerun to R5 and says D1 waits for R5 PASS.
WHAT_THIS_PROVES=The current status is not `NATIVE_READY` or `STATIC_READY`.
WHAT_THIS_DOES_NOT_PROVE=That R5 passes, that D1 is authorized, or that componentization is complete.
REPRODUCTION_METHOD=Read current C09D6-D0R1 authority and historical preflight; compare with PR #144 main head.
DOWNSTREAM_CONSUMERS=CTA Tango only; no later phase starts in this slice.
INVALIDATION_TRIGGER=Accepted R5 result or revised C09D6-D authority.
```

### E-HEADER-01 and E-GALLERY-01

```text
EVIDENCE_ID=E-HEADER-01
CAPABILITY_ID=T-HEADER
CLAIM=Header query settings do not establish a repeated menu boundary or dynamic menu label/destination semantics.
STATE=accepted
SOURCE_TYPE=frontend binding authority
SOURCE_PATH=docs/development/c09b_frontend_binding_authority.md §4–5; docs/development/c09c2_bricks_binding_mapping_authority.md §3–5
SOURCE_SHA_OR_DIGEST=074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e
SOURCE_COMPONENT=Header Basel QS-01
SOURCE_NODE_OR_SETTING_ID=QS-01 as named by C09A/C09C2; no inferred repeat root
OBSERVATION=C09B preserves source query settings as provenance; C09C2 fails closed when owner and repeat subtree are not proven.
WHAT_THIS_PROVES=Do not define or emit a Header menu CollectionBinding from query settings alone.
WHAT_THIS_DOES_NOT_PROVE=That a menu cannot later be supported with new accepted evidence.
REPRODUCTION_METHOD=Follow the accepted QS-01 mapping row and collection admission rules.
DOWNSTREAM_CONSUMERS=T-HEADER navigation and caller-data API.
INVALIDATION_TRIGGER=New accepted source evidence and explicit C09C2 mapping authority.

EVIDENCE_ID=E-GALLERY-01
CAPABILITY_ID=T-GALLERY
CLAIM=The accepted attachment/query evidence does not by itself prove a renderable frontend asset binding or complete lightbox behavior.
STATE=accepted
SOURCE_TYPE=repository authorities and capture limits
SOURCE_PATH=docs/development/c09a_query_dynamic_data_contract.md; docs/development/c09c2_bricks_binding_mapping_authority.md; docs/development/c07x_unsupported_surface_inventory.md §519 and §637
SOURCE_SHA_OR_DIGEST=074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e
SOURCE_COMPONENT=Gallery Bravo
SOURCE_NODE_OR_SETTING_ID=Gallery attachment evidence IDs recorded in C09A; no asset node ID inferred here
OBSERVATION=Query and capture evidence are narrower than a renderable asset contract; screenshots do not establish focus, keyboard, ARIA, or restoration behavior.
WHAT_THIS_PROVES=Data and overlay readiness remain blocked.
WHAT_THIS_DOES_NOT_PROVE=That a future accepted binding or native dialog cannot satisfy the requirement.
REPRODUCTION_METHOD=Read C09A/C09C2 mapping and C-07X capture limitations.
DOWNSTREAM_CONSUMERS=T-GALLERY collection, Asset Value Binding, Dialog/Lightbox.
INVALIDATION_TRIGGER=Accepted asset mapping or behavior/dialog authority.
```

## Current authority reconciliation

| Authority | Current use in this matrix | Reconciliation |
| --- | --- | --- |
| `docs/development/c07x_unsupported_surface_inventory.md` | Historical source evidence, corpus IDs, widget/template observations and explicit evidence limits | Reuse as accepted repository evidence. Do not copy its old end-to-end unsupported classifications forward as current support truth. |
| `docs/development/c09a_query_dynamic_data_contract.md` | Source query and binding occurrence evidence | Use as provenance; C09B and C09C2 own the frontend semantics and mapping limits. |
| `docs/development/c09b_frontend_binding_authority.md` | Frontend-only collection and value model | Host Phoenix owns data fetching, authorization, filtering, ordering, pagination, caching and data adaptation. LiveFrames owns caller inputs, repetition and rendering. |
| `docs/development/c09b1_ir_version_policy.md` and current Design IR spec | Versioned serialized IR policy | Current main code declares IR 3.0.0. Preserve version/migration authority; do not add IR schema in this slice. |
| `docs/development/c09c2_bricks_binding_mapping_authority.md` | Closed source-to-frontend binding mapping | Header QS-01 does not admit a collection without a proven repeat root. Unsupported targets remain diagnostic-only; no inference from a source query. |
| C08B1 and C08B2A icon authorities | Icon source form, asset identity and packaging limits | Current Bricks icon normalization preserves an asset reference without trusted renderable geometry. C08B2A marks the placeholder asset `EVIDENCE_INSUFFICIENT` for packaging; no icon bytes are copied or approved here. Reconcile Pricing/Header/Slider icon needs before readiness. |
| C09D1 / C09D3 / C09D5 | Component public API, render placement and explicit semantic decision/proposer rules | Component boundaries, caller inputs, placements and accessibility decisions require evidence and explicit decisions. The proposer must not guess or auto-approve. |
| C09D6 native generation authority | Review-gated generator and output boundary | Its historical repository-truth table predates current main: the pinned main now has `NativeGenerator`, Design IR 3.0.0, and binding models. Those code-presence facts are verified here; generation availability is not template readiness. |
| C09D6-D0R1 styling authority | R2/R2A/R3/R4 implementation and R5/D1 ordering | Upstream style representations are implemented through R4 at PR #144. CTA remains `STATIC_BLOCKED` until R5 reruns D0 and accepts the result. D1 is not authorized before that; C09D7 is outside this programme slice. |

## Capability-family handoffs

Each family ends with the same seven handoff fields. State records only what current accepted authorities establish. A dependency marker means the family can be mapped now, but its implementation decision remains owned elsewhere.

### Static structure

Native concepts: Section, Container, Heading, Text, Image, Link, Button.

- **ACCEPTED_FACTS:** C09D1 separates source normalization, component API selection and code generation. CTA is the current static tracer but remains blocked at R5.
- **VERIFIED_BUT_NOT_YET_ACCEPTED:** Current code contains the IR and native generator paths listed in E-IMPLEMENTATION-01; this confirms code presence only.
- **UNRESOLVED:** Per-template component boundaries, exact public attributes/slots, image alt decisions, and complete static styling coverage outside CTA.
- **CONFLICTS:** None identified for this family.
- **FUTURE_IMPLEMENTATION_CONSUMERS:** All nine templates.
- **INVALIDATION_CONDITIONS:** Design IR, static semantic tags, component contract, generator or accepted template evidence changes.
- **NEXT_REQUIRED_AUTHORITY:** R5 for CTA; later componentization decisions under C09D1/C09D3/C09D5 and the applicable styling authority.

### Native styling and responsive rules

Native concepts: normalized node styles, responsive overrides, semantic tokens and structured calculations. Source ACSS classes/variables must not leak into generated package CSS.

- **ACCEPTED_FACTS:** C09D6-D0R1 accepts the upstream R2/R2A/R3/R4 resolution chain and places R5 before D1. The native CSS generator remains separately gated at D1.
- **VERIFIED_BUT_NOT_YET_ACCEPTED:** PR #144 adds the bounded `_cssCustom` normalization code at this base. This code-presence fact is verified only; this matrix does not rerun CTA coverage.
- **UNRESOLVED:** R5 acceptance, D1 authorization, styling support for the eight non-CTA exports and remaining ACSS recipes.
- **CONFLICTS:** C-07X's historical classification is stale for upstream style gaps now addressed by R2/R2A/R3/R4; it remains valid as an audit snapshot, not current support status.
- **FUTURE_IMPLEMENTATION_CONSUMERS:** CTA Tango first; all other exports as they receive their own accepted styling evidence.
- **INVALIDATION_CONDITIONS:** R5 result, D1 authority, Design IR/token mapping change, source identity change.
- **NEXT_REQUIRED_AUTHORITY:** R5 owns the CTA D0 rerun. Do not start D1 before R5 PASS.

### Frontend data and repetition

Native concepts: Collection Input, Repeater/repeated subtree, Collection Item Scope, Text/Asset/Link Value Binding, Collection Count Binding, Site Value Binding.

- **ACCEPTED_FACTS:** LiveFrames is a frontend compiler. CollectionBinding marks a proven repeat subtree; ValueBinding identifies a caller-supplied value. Host applications own Ash/database/API/CMS queries, tenant authorization, sorting, filtering, pagination and caching.
- **VERIFIED_BUT_NOT_YET_ACCEPTED:** Current main contains IR 3.0.0 binding structs and generator support. Code presence does not accept every source mapping.
- **UNRESOLVED:** Header menu repetition; Gallery attachment-to-renderable-asset target; binding/public API coverage for query-owning templates; safe update and invalidation semantics for host-provided lists.
- **CONFLICTS:** Source query settings are not evidence of a LiveFrames backend query primitive. Do not introduce Post/Attachment/Menu Query runtime concepts.
- **FUTURE_IMPLEMENTATION_CONSUMERS:** Milan, Gallery, Header, Hero, Slider.
- **INVALIDATION_CONDITIONS:** C09B/C09C2 mapping amendment, accepted source evidence, IR contract change, or host-input contract change.
- **NEXT_REQUIRED_AUTHORITY:** C09C2-scoped source mapping for each unresolved target; C09D1/C09D3 for public API and placement.

### Disclosure and accordion

Native concepts: Disclosure, nested disclosure groups, Accordion single/multi-open policy.

- **ACCEPTED_FACTS:** Slide Menu Alpha uses native `details`/`summary` in the accepted export summary. The reusable Accordion widget has source evidence but competing legacy/new paths remain unresolved.
- **VERIFIED_BUT_NOT_YET_ACCEPTED:** None beyond corpus identity; no new source review occurred.
- **UNRESOLVED:** Nested state policy, current-page opening, keyboard/ARIA guarantees, transition timing, cleanup, and which Accordion source variant is canonical.
- **CONFLICTS:** No accepted authority selects the legacy/new Accordion variant; do not pick one from local file presence.
- **FUTURE_IMPLEMENTATION_CONSUMERS:** Slide Menu Alpha as the disclosure tracer; Pricing Echo responsive accordion; reusable Accordion only if later consumers justify it.
- **INVALIDATION_CONDITIONS:** Behavior Architecture decision, accepted source flag evidence, accessibility authority, or changed export.
- **NEXT_REQUIRED_AUTHORITY:** Behavior Architecture owns state, transition, guard, effect, accessibility mutation and cleanup semantics.

### Selection and responsive mode change

Native concepts: active item/panel, Tabs, Accordion mode and a Responsive Behavior Switch if later evidence requires it.

- **ACCEPTED_FACTS:** Pricing Echo has monthly/yearly tab presentation and a mobile accordion setting. Feature Milan has selection alongside timed rotation.
- **VERIFIED_BUT_NOT_YET_ACCEPTED:** Current IR supports data bindings, not these interaction lifecycles.
- **UNRESOLVED:** Whether selected/open state survives tabs-to-accordion-to-tabs transitions; keyboard model; Milan click/timer interaction; responsive transition guards and cleanup.
- **CONFLICTS:** No accepted authority freezes a tabs-to-accordion lifecycle.
- **FUTURE_IMPLEMENTATION_CONSUMERS:** Pricing Echo, then Feature Milan.
- **INVALIDATION_CONDITIONS:** Behavior Architecture or responsive source evidence changes.
- **NEXT_REQUIRED_AUTHORITY:** Behavior Architecture; C09D componentization authority for public inputs and accessibility decisions.

### Navigation and current-page state

Native concepts: Navigation/Menu, Dropdown, responsive Trigger, Current-page State, Site Value Binding.

- **ACCEPTED_FACTS:** Header Basel contains navigation and menu query evidence; C09A/C09C2 do not accept a menu repeat boundary from query settings alone. C09C2 separately defines closed frontend binding outcomes.
- **VERIFIED_BUT_NOT_YET_ACCEPTED:** Current site URL binding implementation exists only within its accepted mapping scope; menu rendering is not established by that fact.
- **UNRESOLVED:** Menu labels, destinations, hierarchy, repeat semantics, mobile state, dropdown keyboard lifecycle, resize/load behavior and cleanup.
- **CONFLICTS:** Treating query configuration as a repeated menu is expressly unsupported by C09B/C09C2.
- **FUTURE_IMPLEMENTATION_CONSUMERS:** Slide Menu Alpha and Header Basel.
- **INVALIDATION_CONDITIONS:** New accepted menu evidence, C09C2 amendment, Behavior Architecture decision.
- **NEXT_REQUIRED_AUTHORITY:** Evidence/mapping authority for menu semantics, then Behavior Architecture for lifecycle.

### Pointer and focus presentation

Native concepts: Hover/Focus State, focus-within, selected presentation.

- **ACCEPTED_FACTS:** Feature Romeo includes linked cards, source hover interactions and focus-within styling in the accepted C-07X summary.
- **VERIFIED_BUT_NOT_YET_ACCEPTED:** No independent browser behavior was tested here.
- **UNRESOLVED:** Whether authored CSS fully reproduces the visible pointer state and whether any non-CSS lifecycle, touch behavior or state effect is required.
- **CONFLICTS:** Do not assume JavaScript is required merely because source interaction records exist; do not assume CSS suffices without accepted styling and accessibility evidence.
- **FUTURE_IMPLEMENTATION_CONSUMERS:** Feature Romeo and future card patterns.
- **INVALIDATION_CONDITIONS:** Accepted CSS mapping, keyboard/focus requirements or new source evidence.
- **NEXT_REQUIRED_AUTHORITY:** Static style/accessibility authority first; Behavior Architecture only for semantics CSS cannot represent.

### Carousel and playback

Native concepts: Slider/Carousel, index state, arrows, pagination, loop, Timed Rotation, Play/Pause, reduced-motion policy.

- **ACCEPTED_FACTS:** Slider Basel is the functional carousel candidate; Hero Barcelona has decorative moving columns. C-07X records Splide and Auto Scroll evidence as dependencies, not LiveFrames decisions.
- **VERIFIED_BUT_NOT_YET_ACCEPTED:** No library compatibility or browser lifecycle research was done in this documentation slice.
- **UNRESOLVED:** DOM ownership, mount/update/destroy, clone focusability, synchronization, generated controls, autoplay stop rules, reduced motion and accessibility behavior.
- **CONFLICTS:** None accepted for project choice; source use of Splide does not require LiveFrames to adopt it.
- **FUTURE_IMPLEMENTATION_CONSUMERS:** Slider Basel first; Hero Barcelona should reuse the accepted capability if suitable.
- **INVALIDATION_CONDITIONS:** Behavior Architecture or dependency ADR changes; upstream library release/license/maintenance changes before a later decision.
- **NEXT_REQUIRED_AUTHORITY:** Behavior Architecture lifecycle contract and separate external dependency decision.

### Overlay, dialog and lightbox

Native concepts: Dialog, Lightbox, focus management, background/scroll policy.

- **ACCEPTED_FACTS:** Gallery captures include collapsed and expanded lightbox states; C-07X states these captures do not prove focus entry, Escape, restoration, scroll locking, ARIA or keyboard navigation. Modal source widget is a separate inventory item.
- **VERIFIED_BUT_NOT_YET_ACCEPTED:** No browser interaction evidence was collected.
- **UNRESOLVED:** Whether native `<dialog>` is sufficient, whether a narrow helper is needed, Gallery item semantics, nested overlay rules, focus containment/restoration and LiveView patch behavior.
- **CONFLICTS:** A screenshot is not interaction proof. A source Modal widget does not establish Gallery's lightbox implementation contract.
- **FUTURE_IMPLEMENTATION_CONSUMERS:** Gallery Bravo; Modal only if a selected consumer appears.
- **INVALIDATION_CONDITIONS:** Accepted Behavior/accessibility authority or browser verification.
- **NEXT_REQUIRED_AUTHORITY:** Behavior Architecture; external dialog/focus decision owner after lifecycle requirements are known.

### Icons and assets

Native concepts: Icon source/render contract, Asset Value Binding, safe static SVG admission where independently authorized.

- **ACCEPTED_FACTS:** C08B1 separates export icon shape from icon framework styling. C08B2A identifies an S1 Bricks placeholder asset and leaves internal-use and redistribution unknown.
- **VERIFIED_BUT_NOT_YET_ACCEPTED:** Current main has icon token/normalization code, and the normalizer preserves recognized asset references without trusted renderable geometry. These code-presence facts are verified only; they do not establish icon rendering or asset clearance.
- **UNRESOLVED:** Pricing/Header/Slider icon occurrences against current implementation; S2/other icon families; safe caller asset contract; ACSS icon class/render behavior; exact informative/decorative alt semantics.
- **CONFLICTS:** Do not treat a 43-file corpus match as icon permission. Do not package the placeholder SVG or infer icon identity from a reference-only asset.
- **FUTURE_IMPLEMENTATION_CONSUMERS:** Pricing Echo, Header Basel, Slider Basel, Color Scheme only if a selected consumer warrants it.
- **INVALIDATION_CONDITIONS:** C08B amendment, asset authority change, icon renderer/token implementation change, corpus digest change.
- **NEXT_REQUIRED_AUTHORITY:** Reconcile C08B1/C08B2A with current icon implementation and the actual selected-template targets before assigning readiness.

### Timed state, theme state and page-derived UI

Native concepts: Timed Rotation, Reduced-motion Policy, Color Scheme, Table of Contents, Switch.

- **ACCEPTED_FACTS:** C-07X inventories Milan timing plus source-only Color Scheme, TOC and Switch widgets. It records legacy/new TOC paths and does not establish deployed feature flags.
- **VERIFIED_BUT_NOT_YET_ACCEPTED:** No current browser or host flag evidence was checked.
- **UNRESOLVED:** Timer reset/pause/hidden-page behavior; theme persistence/ownership; active heading generation and observer cleanup; whether source-only Switch has downstream demand.
- **CONFLICTS:** Do not treat source presence as a selected template consumer or as a canonical variant choice.
- **FUTURE_IMPLEMENTATION_CONSUMERS:** Milan timing; TOC, Color Scheme and Switch only after a consumer and leverage case is approved.
- **INVALIDATION_CONDITIONS:** Accepted Behavior authority, flag evidence, source version, or downstream consumer decision.
- **NEXT_REQUIRED_AUTHORITY:** Behavior Architecture for lifecycle; evidence owner for source flags and selected-consumer need.

### Builder-only metadata

Native concept: Notes is not a frontend component on current evidence.

- **ACCEPTED_FACTS:** C-07X classifies Notes as Bricks editor annotation behavior with no frontend widget markup.
- **VERIFIED_BUT_NOT_YET_ACCEPTED:** No editor integration was inspected or tested in this slice.
- **UNRESOLVED:** Whether LiveFrames will ever support Bricks editor metadata.
- **CONFLICTS:** None. Builder-only implementation is not implied by reusable source inventory.
- **FUTURE_IMPLEMENTATION_CONSUMERS:** None in the selected nine templates.
- **INVALIDATION_CONDITIONS:** A separately authorized editor integration requirement.
- **NEXT_REQUIRED_AUTHORITY:** Product/repository authority for a Bricks editor feature; otherwise defer.

## Lifecycle requirements for Behavior Architecture

This matrix records requirements and owners; it does not define a Behavior IR, hook protocol, state API, event protocol, or LiveView/client ownership contract. Every interactive family must receive an accepted Behavior Architecture decision covering:

| Requirement | Questions the later authority must answer |
| --- | --- |
| States | What named states exist? Which are stable, terminal, invalid or no-op? |
| Transitions | Which events change state, and what happens on repeated or competing events? |
| Guards | What target, mode, visibility, permission or lifecycle precondition must hold? |
| Effects | Which DOM, focus, timer, media, observer or URL effects occur? |
| Accessibility mutations | Which roles, names, `aria-*`, focus order and announcements change with state? |
| Cleanup | What is disconnected, cancelled, restored or destroyed on update/removal? |
| Responsive transitions | Does state persist, reset or map when a presentation mode changes? |
| Invalid/no-op cases | What happens for missing targets, invalid selectors, empty collections or repeated teardown? |

Until that authority exists, use `DEPENDENCY=BEHAVIOR_ARCHITECTURE`, record the evidence-backed requirement, and stop only that behavior conclusion. Continue unrelated static/data evidence work.

## External-dependency decision register

All choices remain `UNDECIDED`. This table prepares later research; it does not recommend or select a package.

| DEPENDENCY | STATUS | OPTIONS | EVIDENCE | TRADEOFFS | RECOMMENDATION | BLOCKS | DECISION_OWNER | INVALIDATION_TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Splide | `UNDECIDED` | Native browser implementation; wrap a maintained library; another library | C-07X historical use only; no current upstream research | DOM ownership, cloning, focus, sync, bundle, license, LiveView lifecycle | No choice in this slice; research official repository/docs against accepted Behavior requirements | Slider Basel and possible Hero reuse | Carousel decision owner after Behavior Architecture | Library maintenance, license, compatibility or requirement change |
| Splide Auto Scroll | `UNDECIDED` | Retain compatible extension; implement bounded native motion; omit if not required | C-07X historical use only | Core compatibility, teardown, pause on interaction/reduced motion | No choice | Continuous auto-scroll only | Carousel decision owner | Core/extension release or reduced-motion contract change |
| Lightbox implementation | `UNDECIDED` | Native dialog plus project code; narrow helper; omit unsupported source behavior | Screenshot and source setting evidence do not prove a full lifecycle | Focus, Escape, restoration, scroll lock, asset data and patch behavior | No choice; first freeze behavior requirements | Gallery Bravo | Behavior and overlay decision owners | Browser/accessibility evidence or asset mapping change |
| Dialog/focus management | `UNDECIDED` | Native `<dialog>`; narrow helper; managed native elements | No browser matrix or lifecycle verification in this slice | Browser support, nested overlays, inert background, LiveView patching | No choice | Gallery and any future Modal consumer | Behavior/accessibility owner | Supported browser matrix or lifecycle requirement changes |
| Flubber | `UNDECIDED` | Keep morphing; use CSS/state swap; omit path morph | C-07X says source Color Scheme uses it; no selected-template need proven | Bundle/supply-chain cost versus whether path interpolation is needed | No choice; assess whether any selected consumer needs this effect | Only Color Scheme if selected for delivery | Theme/motion decision owner | Confirmed consumer or upstream/source change |
| Animation/transition helpers | `UNDECIDED` | CSS/native browser primitives; small helper; library | C-07X captures motion and reduced-motion evidence | Runtime weight, cancellation, accessibility, cleanup | No choice; research only after exact behavior requirement | Hero, disclosure, slider, theme motion | Behavior/accessibility owner | Reduced-motion or performance evidence changes |

Later research must separate `REPOSITORY_EVIDENCE`, `UPSTREAM_LIBRARY_FACT`, `COMMUNITY_SIGNAL`, and `PROJECT_DECISION`. Current official repository and documentation sources are required for upstream facts.

## Performance and security classification

Local interaction state stays in the browser unless accepted Behavior authority proves server-authoritative state is required. For tabs, disclosure, accordion, dropdown, carousel controls, lightbox local state, hover/focus and timer state:

```text
DB_INDEX=N/A
CACHE=N/A
CACHE_TTL=N/A
REDIS=N/A
POSTGRES=N/A
OBAN=N/A
PUBSUB=N/A
```

Caller-data surfaces use `runtime_state_owner=caller_data`; backend query, cache, index, authorization and result-size policy belongs to the host Phoenix application. Do not invent a LiveFrames query engine. If a later accepted authority proves server-authoritative shared state is needed, it must specify push updates without polling, bounded or streamed collections, tenant isolation, and a no-peak-scan plan.

| Risk class | Applies to | Required later control/evidence |
| --- | --- | --- |
| Untrusted scripts and markup | Embedded source scripts, rich text, HTML and generated markup | Never execute source scripts. Keep source values as data; define safe text/HTML emission authority. |
| Unsafe URLs and open redirects | Link, Image, Asset, Site and menu bindings | Validate URL schemes and target behavior; never forward arbitrary source URLs into navigation. |
| Dynamic attributes and selectors | Source custom attributes, trigger selectors, custom CSS | Closed allowlists and bounded selector semantics; no arbitrary selector interpreter. |
| DOM target and generated-ID collision | Modal, dropdown, trigger, tabs, slider, nested repeats | Stable scoped identity, collision rules, and missing-target invalid states. |
| Focus escape and accessibility mismatch | Dialog, navigation, tabs, disclosure, carousel, hidden duplicates | Accepted roles/names/state relationships, keyboard paths, focus entry/exit and restoration. |
| Dependency supply chain | Splide, Auto Scroll, Flubber, future helpers | Pin/version/license/maintenance review and bundle/runtime audit before adoption. |
| Data and tenant leakage | Caller collections and site/menu/media values | Host application authorizes and scopes data; LiveFrames never fetches or broadens it. |
| Observer/listener/timer cleanup | Header resize/mutation, TOC observers, timers, slider instances | Behavior authority defines mount/update/destroy, cancellation, and repeated-init safety. |
| Unsafe SVG/asset bytes | Icon and media assets | Require explicit asset authority and bounded sanitizer/renderer; reference hashes alone are not render permission. |

## Backward programme graph

```text
Released / consumable native LiveFrames Catalogue component
  ↑ reviewed Catalogue admission
  ↑ browser and accessibility verification
  ↑ complete native artifact: deterministic HEEx + package-owned CSS
    + native behavior where required + caller-data inputs where required
  ↑ approved generation tuple: ComponentContract + ComponentizationPlan
    + exact DesignDocument
  ↑ accepted static, styling, Behavior, frontend-data, accessibility and
    external-dependency authorities
  ↑ source-neutral capability decomposition
  ↑ accepted evidence ledger
  ↑ verified corpus identity and permitted evidence use
```

Catalogue is a later reviewed lane, not an implementation shortcut. Generator, IR and collection binding presence do not waive the evidence, behavior, styling, accessibility, browser verification, provenance or admission gates.

## Recommended tracer order by dependency leverage

1. **CTA Tango static path remains externally owned:** R5 reruns D0; only a passing accepted result may authorize D1; C09D7 remains outside this slice. No status is promoted here.
2. **Feature Romeo:** decide whether the accepted hover/focus appearance can be represented by native CSS and focus styling. Do not add JavaScript until an accepted requirement needs managed state.
3. **Slide Menu Alpha:** use as the simplest Disclosure tracer, after Behavior Architecture accepts its lifecycle.
4. **Accordion capability:** reuse the Disclosure foundation and resolve single/multi-open plus legacy/new source ambiguity before implementation.
5. **Pricing Echo:** prove Tabs and responsive Accordion continuity, then reconcile icon capability and the static feature-row component boundary.
6. **Header Basel:** add navigation/dropdown/trigger after Disclosure foundations; resolve menu data independently. Do not infer repetition from query settings.
7. **Slider Basel:** use as the primary functional carousel tracer after Behavior and dependency decisions; it exercises controls, playback, collection input and teardown.
8. **Hero Barcelona:** reuse the carousel and collection capabilities where its decorative motion maps to the approved contract.
9. **Feature Milan:** add selection, caller data and timed rotation after selection and lifecycle foundations.
10. **Gallery Bravo:** resolve media collection/asset semantics and dialog/lightbox behavior before conversion.
11. **Source-only widgets:** schedule Modal, TOC, Switch, Color Scheme and Notes by a proven downstream consumer and dependency leverage, not by source availability.

This order keeps the interaction foundations reusable. It differs from the old C-07X order where upstream style support had not yet landed. Romeo can reduce behavior scope if CSS is sufficient; Disclosure supplies a smaller stateful tracer before the Tabs/Accordion mode change; Slider Basel exercises the full carousel contract before Hero reuse. None of these sequencing judgments authorizes implementation.

## Required critique of earlier assumptions

| Question | Current answer and limit |
| --- | --- |
| Does every source widget need a native component? | No. Notes is builder metadata, source-only widgets have no selected-template consumer, and source existence alone has no implementation priority. |
| Does Feature Romeo need JavaScript? | Not established. Its hover/focus appearance may be CSS-only; verify styling and accessibility requirements before assigning managed behavior. |
| Should disclosure precede tabs? | Recommended. Slide Menu Alpha is the smaller stateful tracer and can establish a reusable disclosure contract before responsive tab/accordion continuity. Behavior authority must accept the semantics first. |
| Should Slider Basel be the carousel tracer rather than Hero? | Yes, as a candidate. Slider Basel exercises controls, looping, playback and slide data; Hero can then test reuse. This is a programme recommendation, not a dependency decision. |
| Does LiveFrames need an external lightbox library? | Unknown. A screenshot only proves a displayed state. First accept focus, Escape, restoration, scroll and patch requirements; then compare native dialog and helper options. |
| Is Flubber justified? | Not for the selected nine on current evidence. It appears in a source-only Color Scheme widget; defer unless a consumer requires path morphing. |
| Do Header query settings prove menu repetition? | No. C09B/C09C2 explicitly require an evidenced repeat owner and subtree; QS-01 remains fail-closed. |
| Are screenshots interaction proof? | No. C-07X says captures show named static states, not transitions, keyboard paths, focus, cleanup or intermediate behavior. |
| Are C-07X unsupported statuses current? | No. Reuse its evidence, not its old pipeline verdicts. In particular, frontend bindings, IR 3.0.0, NativeGenerator, R2/R2A/R3/R4 changed repository capability since that audit. |

## Invalidation rules and next authorities

Re-evaluate only the affected row when one of these events occurs:

| Trigger | Rows or conclusions to revisit | Required authority |
| --- | --- | --- |
| Export/component/icon digest or file set changes | All source-derived claims tied to that corpus | Provenance and focused evidence review; no silent repin |
| New private-source semantic interpretation is needed | Only claims requiring that interpretation | Explicit private-source authority; otherwise lane-local `STOP=PRIVATE_SOURCE_AUTHORITY_UNCLEAR` |
| Behavior Architecture changes lifecycle rules | Interactive families and any readiness derived from them | Behavior Architecture owner |
| C09B/C09C2 mapping or IR version changes | Frontend-data rows, caller API and generator assumptions | Frontend-data/Design IR authority |
| C08B icon/asset authority or renderer changes | Icon consumers and asset-dependent readiness | C08B owner; reconcile with current code |
| R5 result or C09D6-D1 authorization changes | CTA static/style status and downstream CTA plan | R5 / C09D6 authority owner |
| External library maintenance, license, API or browser behavior changes | Only dependent carousel/overlay/theme rows | External dependency decision owner, using current official sources |
| ComponentContract, ComponentizationPlan or NativeGenerator changes | Component boundaries and output assumptions | C09D1/C09D3/C09D5/C09D6 authorities |
| Browser/accessibility verification result | Only verified capabilities in tested scope | Browser evidence owner; record exact browser, state and artifact |

Current required next authorities are: R5 for CTA Tango; Behavior Architecture for lifecycle-bearing families; focused C09C2 mapping for Header and Gallery; C08B/current implementation reconciliation for icon consumers; and separate external-dependency decisions only after exact requirements are accepted. This document does not authorize any of those later actions.
