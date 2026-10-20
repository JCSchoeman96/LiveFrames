# Page A v0 preview readiness report

This report records Page A v0 readiness against the exact LiveFrames checkout below. `SUPPORTED` means the stated capability has current repository evidence for this page. `PARTIAL` means some evidence exists but the complete section path is unresolved. `BLOCKED` means a required gate prevents rendering that section. `NOT_REQUIRED` means Page A v0 does not need that capability for the stated section. Source admission records repository evidence only; it does not grant license, redistribution, or publication rights.

```text
PAGE_ID=frames_page_a_v0
SOURCE_TYPE=FRAMES_HEAVY_TRACER
SOURCE_DIGEST=074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e
CONSUMER_TARGET=LIVEFRAMES_PREVIEW
LIVEFRAMES_SHA=1ef6d32c4702b792b093e03b8851bee50fef6c35
LIVEFRAMES_TREE=72418fdfed0429440acb9db9de25a784f2b2ded1

SECTIONS_DISCOVERED=Hero, CTA Tango A, CTA Tango B, Feature Romeo, Feature Milan, Pricing Echo, Gallery Bravo, Slider Basel
SECTIONS_GENERATED=Hero, CTA Tango A, CTA Tango B
SECTIONS_GENERATED_MEANING=Section instances rendered through native LiveFrames component APIs in Page A v0; this does not assert that their HEEx or CSS was emitted by the IR generator
SECTIONS_PARTIAL=NONE
SECTIONS_BLOCKED=Feature Romeo, Feature Milan, Pricing Echo, Gallery Bravo, Slider Basel
SECTION_MATRIX=See section matrix below
```

`SOURCE_DIGEST` identifies the accepted Frames export corpus in the native conversion matrix. The Page A preview uses synthetic caller-owned content and does not load that source corpus. The exact digest and corpus scope are recorded in [the native conversion matrix](../frames_native_conversion_matrix.md#corpus-identity). `LIVEFRAMES_SHA` and `LIVEFRAMES_TREE` identify the code and assets assessed here, before this report is added.

## Section matrix

| Section | Readiness | Rendered in Page A v0 | Owning Lead for blocker | Evidence |
| --- | --- | --- | --- | --- |
| Hero | SUPPORTED | Yes, one native Hero instance | None | [Lead 3 design §10](../../superpowers/specs/2026-10-19-lead3-page-tracer-design.md#10-page-a-v0-scenario), [Hero API and package model](../../16_PACKAGE_AND_GENERATOR_MODEL.md), [Page A LiveView](../../../apps/live_frames_preview/lib/live_frames_preview_web/live/page_tracers/frames_page_a_v0_live.ex) |
| CTA Tango A | SUPPORTED | Yes | None | [Lead 3 design §10](../../superpowers/specs/2026-10-19-lead3-page-tracer-design.md#10-page-a-v0-scenario), [current roadmap](../../17_ROADMAP.md), [CTA API and package model](../../16_PACKAGE_AND_GENERATOR_MODEL.md) |
| CTA Tango B | SUPPORTED | Yes | None | [Lead 3 design §10](../../superpowers/specs/2026-10-19-lead3-page-tracer-design.md#10-page-a-v0-scenario), [current roadmap](../../17_ROADMAP.md), [CTA API and package model](../../16_PACKAGE_AND_GENERATOR_MODEL.md) |
| Feature Romeo | BLOCKED | No | Lead 1 | [Romeo post-stateful-style componentization preflight](../feature_romeo_post_stateful_style_componentization_preflight.md) |
| Feature Milan | BLOCKED | No | Lead 1 for componentization; Lead 2 for behavior/runtime | [resolved Milan DesignDocument](../feature_milan_ir4_resolved_design_document_identity.md), [post-resolution behavior review](../feature_milan_ir4_post_resolution_behavior_review_result.md), [Milan timed-selection mapping](../feature_milan_timed_selection_mapping_preflight.md) |
| Pricing Echo | BLOCKED | No | Lead 1 | [Pricing responsive behavior preflight](../pricing_echo_responsive_behavior_mapping_preflight.md), [current conversion matrix](../frames_native_conversion_matrix.md#historical-and-current-status-relationship) |
| Gallery Bravo | BLOCKED | No | Lead 1 | [Gallery lightbox and asset preflight](../gallery_bravo_lightbox_mapping_preflight.md) |
| Slider Basel | BLOCKED | No | Lead 2 | [Slider carousel mapping preflight](../slider_basel_carousel_mapping_preflight.md), [current conversion matrix](../frames_native_conversion_matrix.md#historical-and-current-status-relationship) |

`SECTIONS_GENERATED` names section instances rendered through native LiveFrames component APIs in Page A v0; it does not claim that their HEEx or CSS was emitted by the IR generator. The rendered Hero uses the existing generic `LiveFrames.Components.Sections.Hero.hero/1` API, so its rendered readiness is `SUPPORTED` while its hand-authored HEEx and CSS remain `PARTIAL` on the generated-output axes. It does not claim conversion of Hero Barcelona's query-based decorative motion. The Page A route uses synthetic content and the two CTA instances have separate caller-owned headings, images, action destinations, body content, and root classes, as required by the [Page A implementation plan](../../superpowers/plans/2026-10-20-lead3-page-a-v0.md).

## Capability matrix

Axes appear in the order required by the Lead 3 design. CTA Tango A and B share the same native component and stylesheet; both instance calls render in the Page A LiveView. `PARTIAL` behavior records partial semantic or mapping evidence, not implemented runtime behavior. This matrix reports component and page-level evidence, not browser or external consumer proof.

| Capability | Hero | CTA Tango A | CTA Tango B | Feature Romeo | Feature Milan | Pricing Echo | Gallery Bravo | Slider Basel |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Source admitted | SUPPORTED | SUPPORTED | SUPPORTED | SUPPORTED | SUPPORTED | SUPPORTED | SUPPORTED | SUPPORTED |
| Design IR | NOT_REQUIRED | SUPPORTED | SUPPORTED | PARTIAL | SUPPORTED | PARTIAL | PARTIAL | PARTIAL |
| Componentized | SUPPORTED | SUPPORTED | SUPPORTED | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED |
| Generated HEEx | PARTIAL | SUPPORTED | SUPPORTED | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED |
| Generated CSS | PARTIAL | SUPPORTED | SUPPORTED | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED |
| Responsive | SUPPORTED | SUPPORTED | SUPPORTED | PARTIAL | PARTIAL | PARTIAL | PARTIAL | PARTIAL |
| Navigation | SUPPORTED | SUPPORTED | SUPPORTED | BLOCKED | NOT_REQUIRED | NOT_REQUIRED | NOT_REQUIRED | NOT_REQUIRED |
| Behavior | NOT_REQUIRED | NOT_REQUIRED | NOT_REQUIRED | PARTIAL | PARTIAL | PARTIAL | PARTIAL | PARTIAL |
| Browser verified | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED |
| Consumer verified | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED |
| Ash/data ready | NOT_REQUIRED | NOT_REQUIRED | NOT_REQUIRED | NOT_REQUIRED | PARTIAL | NOT_REQUIRED | BLOCKED | PARTIAL |

Evidence for the rendered APIs: Hero is an accepted hand-authored native section with package CSS; its markup and responsive CSS are in [`hero.ex`](../../../apps/live_frames/lib/live_frames/components/sections/hero.ex) and [`hero.css`](../../../apps/live_frames/assets/css/components/sections/hero.css). The CTA has an approved component contract and delivered native generation; the current roadmap records C09D7-A accepted and C09D7-B delivered. Its output and responsive CSS are in [`media_call_to_action.ex`](../../../apps/live_frames/lib/live_frames/components/sections/media_call_to_action.ex) and [`media_call_to_action.css`](../../../apps/live_frames/assets/css/components/sections/media_call_to_action.css). The Page A route test asserts both CTA contents, links, classes, and a single stylesheet reference in [`frames_page_a_v0_live_test.exs`](../../../apps/live_frames_preview/test/live_frames_preview_web/page_tracers/frames_page_a_v0_live_test.exs). The Hero's `Generated HEEx` and `Generated CSS` axes are `PARTIAL` because its native API is hand-authored, not emitted by the IR generator; the current generation authority records that distinction in §2 [C09D6 native generation authority](../c09d6_native_generation_authority.md).

Evidence for blocked section axes: the [current conversion matrix](../frames_native_conversion_matrix.md#historical-and-current-status-relationship) records partial static, behavior, data, responsive, or identity mapping for these tracers. Romeo's latest componentization preflight keeps canonical normalization and componentization blocked; its partial behavior status reflects source hover/focus evidence with CSS-versus-managed-state sufficiency unresolved, not implemented runtime behavior. Milan's resolved DesignDocument closes the responsive-breakpoint question but retains an unsupported-node blocker; `Responsive=PARTIAL` records resolved breakpoint data without generated component CSS. Pricing has incomplete occurrence identity and cross-mode focus/state continuity; Gallery lacks an accepted renderable asset value and stable item identity; Slider has partial carousel mapping, an unestablished mobile breakpoint, and incomplete lifecycle and accessibility mapping. The specific claims and routing are recorded below.

The approved Lead 3 design assigns `converter/style/navigation` work to Lead 1, `behavior/runtime` work to Lead 2, and `consumer/composition` work to Lead 3 (§8.5). It lists Romeo, Pricing Echo, Gallery Bravo, and Slider Basel as blocked under their section lanes (§10). Feature Milan is recorded there as `BLOCKED_LEAD_1_OR_2`; this report splits its two evidenced blocker lanes rather than assigning every Milan gap to either Lead.

## Blocker routing

| Section and lane | Owning Lead | Reason the section is unavailable | Evidence |
| --- | --- | --- | --- |
| Feature Romeo, conversion/style/navigation | Lead 1 | Canonical source environment and ACSS applicability remain unproven, named breakpoint authority is unproven, unresolved style and asset/settings findings remain, and four heading links lack normalized navigation semantics. The preflight reports componentization readiness `BLOCKED`. | [Romeo componentization preflight](../feature_romeo_post_stateful_style_componentization_preflight.md), [approved Lead 3 responsibility map](../../superpowers/specs/2026-10-19-lead3-page-tracer-design.md#85-blocker) |
| Feature Milan, componentization | Lead 1 | The current resolved DesignDocument still contains an `unsupported` DesignNode inside the root candidate, so componentization plan validation and generation eligibility remain blocked. The responsive-breakpoint question is resolved and is not a current blocker. | [resolved Milan DesignDocument, Q12/Q13 status](../feature_milan_ir4_resolved_design_document_identity.md), [post-resolution behavior review, Q13 status](../feature_milan_ir4_post_resolution_behavior_review_result.md) |
| Feature Milan, behavior/runtime | Lead 2 | The BehaviorContract and post-resolution review are approved for the resolved DesignDocument, but runtime implementation has not started. The current mapping evidence still records partial Tabs and timer mapping and incomplete cross-collection identity/correlation. | [post-resolution behavior review](../feature_milan_ir4_post_resolution_behavior_review_result.md), [Milan timed-selection mapping](../feature_milan_timed_selection_mapping_preflight.md), [current conversion matrix](../frames_native_conversion_matrix.md#historical-and-current-status-relationship), [approved Lead 3 responsibility map](../../superpowers/specs/2026-10-19-lead3-page-tracer-design.md#85-blocker) |
| Pricing Echo, componentization/style | Lead 1 | The responsive tabs-to-accordion direction is recorded, but stable typed item identity, occurrence mapping, cross-mode focus/state continuity, icon renderability, and the static feature-row component boundary are unresolved. | [Pricing responsive behavior preflight](../pricing_echo_responsive_behavior_mapping_preflight.md), [current conversion matrix](../frames_native_conversion_matrix.md#historical-and-current-status-relationship) |
| Gallery Bravo, componentization/data/style | Lead 1 | A repeated collection is mapped, but its attachment ID does not provide a renderable asset value. Result-count binding, stable item identity, and complete lightbox occurrence inputs remain unresolved. | [Gallery lightbox and asset preflight](../gallery_bravo_lightbox_mapping_preflight.md) |
| Slider Basel, behavior/runtime | Lead 2 | Carousel occurrence and lifecycle mapping remain partial, and no Slider Basel runtime implementation has started. The preflight leaves update/destroy behavior, clone focusability, control synchronization, autoplay rules, and accessibility behavior unresolved. Stable slide identity and the section-specific responsive breakpoint remain separate data and style gaps. | [Slider carousel mapping preflight](../slider_basel_carousel_mapping_preflight.md), [approved Lead 3 responsibility map](../../superpowers/specs/2026-10-19-lead3-page-tracer-design.md#85-blocker) |

The Milan Lead 1 row covers the current unsupported-node componentization blocker. The separate Lead 2 row covers behavior/runtime gaps. The current resolved DesignDocument records Q12 as resolved and Q13 as unresolved, so this report does not preserve the earlier breakpoint blocker as current. These rows use the approved design map and current Milan evidence; the other section owners follow the design's listed section assignments and do not assign unrelated frontend-data or accessibility gaps to those Leads.

## Readiness gaps and stops

```text
GENERIC_GAPS=Romeo canonical source/style/navigation mapping; Milan unsupported-node blocker; Pricing component boundary and responsive occurrence mapping; Gallery media/count/item mapping; Slider carousel/style mapping
BEHAVIOR_GAPS=Romeo CSS-versus-managed-state sufficiency; Milan selection/timer runtime and cleanup; Pricing cross-mode focus/state continuity; Gallery lightbox occurrence inputs; Slider carousel lifecycle and accessibility
DATA_GAPS=Milan collection correlation; Gallery renderable asset, result count, and stable item identity; Slider stable slide identity
CONSUMER_GAPS=No clean external Phoenix consumer proof for this LiveFrames identity

STRUCTURAL_FIDELITY=NOT_ASSESSED
FUNCTIONAL_FIDELITY=NOT_ASSESSED
VISUAL_FIDELITY=NOT_ASSESSED
BROWSER_RESULT=NOT_RUN

STOP=NONE
STOP_FALSE_READINESS_CLAIM=NOT_TRIGGERED
STOP_BLOCKED_SECTION_RENDERED_AS_FAKE_COMPONENT=NOT_TRIGGERED
STOP_OWNER_LEAD_UNRESOLVED=NOT_TRIGGERED
```

Page-level browser evidence and the clean external Phoenix consumer proof belong to Tasks 3 and 4 of the [approved implementation plan](../../superpowers/plans/2026-10-20-lead3-page-a-v0.md). They are not claimed here. No blocked intended section is rendered. The owners listed above resolve the Lead 3 design's Feature Milan routing ambiguity by its separate blocker lanes.

## CTA status reconciliation

For Page A v0, the current roadmap records C09D7-A as accepted and C09D7-B as delivered. The approved Lead 3 design names Hero and CTA Tango as the two current genuine native component APIs for the first page tracer. Accordingly, CTA Tango A and B are `SUPPORTED` for in-repository native composition and generation. The older `CTA_NATIVE_READY=NO` row in the conversion matrix predates the accepted C09D7-A/B state and describes a broader native readiness gate; it does not make the current CTA API unavailable. This report does not claim external consumer, browser page, Catalogue distribution, or release readiness. See [current roadmap](../../17_ROADMAP.md), [approved C09D7-A component review](../c09d7a_cta_tango_component_review.md), [C09D7-B IR4 reauthorization](../c09d7b_cta_tango_ir4_reauthorization.md), and [approved Lead 3 design §10](../../superpowers/specs/2026-10-19-lead3-page-tracer-design.md#10-page-a-v0-scenario).
