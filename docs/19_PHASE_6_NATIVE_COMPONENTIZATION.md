# Phase 6 Native Componentization

**Status:** Phase 6 authorized; P6.1 API approved; P6.2 implemented; P6.3
`semantic_verified`; P6.4 workstream **`verified`** (P6.4B1 merged; P6.4B2 browser
verification owner-accepted in
`docs/21_P6_4B2_NATIVE_HERO_BROWSER_VERIFICATION.md`); Hero lifecycle =
**`storybook_verified`**; P6.5 documentation = **documented / owner accepted**
(owner-reviewed head `31416d7f545fa194b92303afe0a2503142516227`); P6.6 =
**storybook_verified / owner accepted** (`docs/22_P6_6_NATIVE_HERO_STORYBOOK_VERIFICATION.md`);
Phase 6 exit = **not yet authorized**

This document is the execution authority for the native componentization
programme. It records the proposed public API for the first native Hero
section. It records the P6.1 approval and the durable prerequisite for P6.2;
it does not begin implementation, styling work, Storybook work, catalogue
work, or any other P6 slice.

## 1. Goal

Turn the accepted, source-independent Hero visual and semantic intent into a
deliberate reusable Phoenix function-component contract. The contract must
work for direct library consumers, Storybook, catalogue metadata, future
generation/ejection, multiple themes, and a later structurally different
tracer without exposing source-system vocabulary.

P6.1 answers what a consumer-facing API means. It does not mechanically clean
up generated HEEx and does not implement the component.

## 2. Starting repository state

P6.1 starts from clean `main` at:

```text
964c11c47bad43bd80138f1fffa380f9d03cb0ba
```

PR #26 is merged at that same SHA. Master Phase 5 is closed. P5-H0, P5-H1,
and P5-H2 are complete. Phase 6 is explicitly owner-authorized. P6.1 is
approved. P6.2 is implemented. P6.3 semantic verification is complete. P6.4A
styling-bridge architecture is approved in
`docs/20_P6_4A_NATIVE_STYLING_BRIDGE_ARCHITECTURE.md`. P6.4B1 is merged;
P6.4B2 browser verification is verified / owner accepted (`docs/21`); P6.4 =
verified. P6.5 documentation is **documented / owner accepted**; Hero lifecycle
= **storybook_verified**. P6.6 Storybook verification is **storybook_verified /
owner accepted** (`docs/22`). Phase 6 exit / Hero **accepted** = **not yet
authorized** (requires PR #34 merge, clean synchronized `main`, and separate
owner authorization).

The accepted fidelity evidence establishes a dark section with a large
heading, bounded lede, two action roles, a full-section cover backdrop,
responsive focal and overlay composition, narrow-screen full-width actions,
and ordinary hover and focus-visible states. The semantic shape is a section
with content (heading, lede, and actions) plus background (optional media and
overlay); those internal child names are not public API. The primary action is
filled and the secondary action is outlined. It establishes no required
JavaScript interaction, hook, server event, or component-owned state.

Attachment 880 remains unavailable. The native API must not depend on it or
imply that a replacement image reproduces it. The Phase 5 truth remains:

```text
fidelity_state = unavailable
never_resolved = true
waiver_granted = true
image_asset_fidelity = unavailable
redistribution_status = unknown
full_visual_fidelity = not_claimed
```

## 3. Backward plan

The long-term path is:

```text
source design
→ Design IR
→ accepted fidelity reproduction
→ native semantic component
→ Storybook
→ catalogue
→ generator/ejection
→ reusable consumer API
```

This slice defines the native semantic component boundary that later slices
may implement and verify. It authorizes P6.2 only under the clean-`main`
prerequisite recorded below. It does not authorize P6.3 or later steps.

## 4. Native candidate lifecycle

The narrow lifecycle for a native component candidate is:

```text
authorized
→ api_proposed
→ api_approved
→ implemented
→ semantic_verified
→ styling_verified
→ documented
→ storybook_verified
→ accepted
```

`blocked` is an exceptional state and must carry an explicit blocking reason.
It is not a retry or recovery mechanism. `accepted` is terminal for this
tracer lifecycle. It is distinct from a future CatalogueItem lifecycle.

The reviewed lifecycle transition is:

```text
authorized → api_proposed → api_approved
```

The approved API proposal records reviewed input head
`6eda7ba9a66e16c2902868a82a3621d2d3267c92`. `api_approved` does not imply
implementation.

## 5. Component category and boundary

The candidate category is **section**. The approved boundary is one
section-level function component. The background, overlay, content, and action
markup are internal structure, not separate public components yet.

Do not extract `HeroContent`, `HeroOverlay`, `HeroActions`, or `HeroBackground`
solely because those nodes exist in the rendered tree. A child becomes a
separate component only after independent semantics, consumers, and reuse are
proven, preferably by the second tracer.

The candidate is a stateless `Phoenix.Component` function component. Current
evidence does not justify `Phoenix.LiveComponent`, nested LiveView, hook,
custom JavaScript, GenServer, PubSub, or component-owned server events.

## 6. Proposed module and function

```text
module:  LiveFrames.Components.Sections.Hero
function: hero/1
```

`Sections.Hero` names the semantic role and its taxonomy without binding the
API to an editor, fixture, asset, or one media treatment. `hero/1` follows the
normal Phoenix function-component convention.

Rejected alternatives:

| Alternative | Reason rejected |
| --- | --- |
| `HeroIndia` | Encodes one accepted fixture and would make provenance part of the public taxonomy. |
| `BackdropHero` | Describes one implementation detail rather than the section's semantic role. |
| `MediaHero` | Implies mandatory media and would prematurely broaden the Hero taxonomy. |
| `HeroSection` | Semantically valid but redundant with the `Sections` namespace; the shorter name is clearer without losing the category. |
| A universal Hero framework | One tracer does not prove a variant DSL, taxonomy, or generalized content model. |

If later evidence requires a materially different contract, propose a new
source-independent candidate rather than widening this API by default.

## 7. Public attr contract

The following is the complete P6.1 attr proposal. It is an API contract, not
an implementation file.

| Name | Phoenix type | Required/default | Allowed values | Semantic purpose | Accessibility implications | Why public |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `:string` | Optional; default `nil` | A consumer-provided HTML id | Identifies the section for linking, labels, tests, or application integration. | Consumers must keep ids unique and use them consistently with any external label or landmark relationship. | Normal section identity is a stable Phoenix convention. |
| `heading` | `:string` | Required | Plain text; no raw HTML | Supplies the section's primary heading content. | A deterministic heading is required for the section's hierarchy and naming. HEEx escapes it. | The accepted Hero has one plain heading and every instance needs semantic content. |
| `heading_level` | `:integer` | Optional; default `2` | Exactly `1`, `2`, `3`, `4`, `5`, or `6` | Selects the document heading level without accepting an arbitrary tag. | Consumers preserve the surrounding document hierarchy; invalid values cannot create arbitrary elements. | Reusable sections cannot assume they are always the page `h1`. |
| `lede` | `:string` | Optional; default `nil` | Plain text; omitted when `nil` | Supplies the optional supporting paragraph. | When present it is rendered as ordinary paragraph content; absence does not leave an empty semantic node. | Current evidence proves simple paragraph content, not arbitrary rich markup. |
| `image_src` | `:string` | Optional; default `nil` | Consumer-approved image source | Supplies optional backdrop media. It is not an attachment-880 dependency. | If supplied, `image_alt` must make the informative/decorative decision explicit. | Consumers need a safe way to provide their own media while allowing no-image use. |
| `image_alt` | `:string` | Optional at the type level; required when `image_src` is supplied; default `nil` | Non-empty meaningful text or the explicit empty string `""`; `nil` with an image is invalid/unknown | Declares whether supplied imagery conveys meaning or is decorative. | Non-empty text is informative. `""` is an explicit decorative decision. `nil` is not inferred to mean decorative. | The accessibility decision belongs with the consumer who knows the image's purpose. |
| `class` | `:string` | Optional; default `nil` | Consumer class tokens | Extends the section root with consumer-owned styling or hooks while internal semantic classes remain component-owned. | Must not remove required focus or contrast styling through an undocumented contract. | Standard Phoenix component ergonomics without exposing source classes. |
| `rest` | `:global` capture | Optional; default empty | Normal global attributes such as `aria-*`, `data-*`, `title`, and `role` where appropriate | Passes through standard consumer attributes on the section root. | Consumers remain responsible for valid ARIA and global-attribute use; native semantics are preferred. | Global attr passthrough is idiomatic Phoenix and avoids a growing one-off attr list. |

The implementation must merge `class` deliberately with its internal root
classes and must define which explicitly owned attrs cannot be overridden by
`rest`. `id` and `class` are not duplicated in `rest`. Raw inline `style` is
not the primary customization system.

The API does not expose source breakpoint names, pixel thresholds, source
classes or IDs, media focal-position controls, overlay variants, arbitrary
tags, a button variant DSL, or source-runtime values.

## 8. Slot contract

| Slot | Required/optional | Cardinality | Slot attrs | Consumer responsibility | Fallback |
| --- | --- | --- | --- | --- | --- |
| `primary_action` | Optional | 0 or 1 slot entries | None in the first API | Provide one normal Phoenix action root such as a `<.link>`, `<button>`, or another appropriate action element, including its label, destination, events, and application semantics. | Omit the action entirely when absent; no placeholder is rendered. |
| `secondary_action` | Optional | 0 or 1 slot entries | None in the first API | Provide one normal Phoenix action root and all application-owned behavior. | Omit the action entirely when absent; no placeholder is rendered. |

Named action slots are deliberately chosen over one repeatable `actions`
slot. Accepted evidence proves two stable semantic roles with distinct visual
treatment. A repeatable slot would require an ordering and variant contract
that is not yet evidenced. This is not a generalized button system.

P6.2 must validate slot-entry cardinality before rendering. Each supplied slot
entry must conceptually render one interactive action root, such as an `<a>`,
`<button>`, a Phoenix `<.link>` that resolves to one anchor, or an equivalent
consumer component that resolves to one appropriate interactive root. The
component validates slot entries, not nested descendants inside arbitrary
HEEx. It must not reinterpret a group of links or buttons as one action.

The consumer supplies one action role per slot, a meaningful accessible name,
an appropriate native action element, and all navigation, event, and business
behavior. Representative semantic markup tests belong to P6.3.

There is no media slot in the first API. One optional backdrop is adequately
represented by `image_src` and `image_alt`; arbitrary media markup would add a
contract that the current tracer does not prove. Heading and lede remain attrs
because current evidence is plain text, not arbitrary Phoenix markup.

## 9. Content decisions

- **Heading:** required plain-text attr plus constrained `heading_level`.
- **Lede:** optional plain-text attr. A rich-text slot can be proposed only
  when a later tracer proves a durable need.
- **Primary and secondary actions:** named optional slots because consumers
  must provide arbitrary Phoenix markup and own behavior.
- **Background/media:** optional image attrs. No image is a valid state, and
  attachment 880 is never a native dependency.

The absence of lede, one or both actions, or an image is ordinary valid input,
not an error state. Long heading and lede values must flow through the same
semantic layout and remain readable; no length-specific API knob is proposed.

## 10. Heading semantics

The component maps the constrained integer `heading_level` to one of the
static elements `h1` through `h6`. It must not accept an arbitrary tag string
or interpolate a tag from source data. The default is `2` because a reusable
section is commonly placed below a page heading, while consumers can select
`1` when this section is the document's main heading. The consumer remains
responsible for the surrounding document hierarchy.

## 10.1 Runtime validation contract

P6.2 must perform deterministic validation before rendering. Phoenix
declarative attrs and slots alone do not enforce every invariant, especially
when values are dynamic. Literal `heading_level` values may also use
`attr ... values:` for compile-time warnings, but that warning is not the
runtime guard.

The required runtime behavior is:

| Invalid condition | Required result and message |
| --- | --- |
| `heading_level` is not an integer in `1..6` | Raise `ArgumentError` with `heading_level must be an integer between 1 and 6`. |
| `image_src != nil` and `image_alt == nil` | Raise `ArgumentError` with `image_alt is required when image_src is provided`. |
| More than one `primary_action` slot entry | Raise `ArgumentError` with `primary_action accepts at most one slot entry`. |
| More than one `secondary_action` slot entry | Raise `ArgumentError` with `secondary_action accepts at most one slot entry`. |

Validation must not silently fall back, coerce values, correct a heading
level, infer that a missing image alt is decorative, or render before the
guard completes.

These ordinary absences remain valid:

```text
image_src = nil and image_alt = nil
lede = nil
no action slot entries
```

## 11. Action and behavior contract

The component lays out the two named action slots and gives them the semantic
primary or secondary presentation. It does not own:

```text
navigate
patch
href
phx-click
business events
checkout logic
analytics
application state
```

Those values belong to the consumer-supplied Phoenix markup and consuming
application. The Hero's interaction class is `static/local presentation`.
There is no component-owned state machine, server event, polling, hook, or
network lifecycle.

## 12. Image and background contract

- With no `image_src`, the section remains usable with its semantic content
  over the solid section background. No placeholder and no unavailable source
  asset is fabricated.
- With an image, a non-`nil` `image_alt` is required by the contract. Non-empty
  text means informative image content. The explicit empty string means the
  image is decorative. `nil` does not silently mean decorative.
- Image loading failure has no component-owned retry or JavaScript behavior.
  Content remains usable over the section fallback; a consumer controls any
  source or application-level fallback.
- The first API does not expose focal position. Responsive composition may
  choose an internal focal treatment, but a public position attr requires
  later semantic evidence and token authority.
- No native API field names, resolves, or claims attachment 880. A future demo
  may use clearly identified substitute media without changing Phase 5 truth.

## 13. Class and global-attribute ergonomics

The eventual P6.2 implementation must use Phoenix's declarative global-attr
contract, conceptually `attr :rest, :global`. It must not replace that
contract with a large ad-hoc whitelist or accept a caller-supplied `rest={...}`
map as an alternative API.

The explicit `id` and `class` attrs are component-owned API fields. They are not
also controlled through `rest`. Internal semantic classes must always remain
present, and the consumer's `class` value is additive and merged with them.
`rest` is applied only as the global passthrough map produced by Phoenix's
declarative attr handling.

Consumer global attrs may alter root semantics, focus behavior, visibility,
ARIA, data attributes, LiveView bindings, and appearance. Those effects belong
to the consumer and are outside the component-owned accessibility and isolated
visual guarantees. Consumers must not claim LiveFrames' isolated verification
after overriding required styling or semantics.

Source-export classes never become part of the public contract. HEEx escaping
remains authoritative. The component does not turn consumer strings into
arbitrary tags, HTML, CSS selectors, executable code, or raw markup.

## 14. Responsive contract

Responsive behavior is internal. The public API has no breakpoint attrs and no
knowledge of source names or thresholds such as `tablet_portrait`,
`mobile_portrait`, `991px`, or `478px`.

| Viewport intent | Required native behavior |
| --- | --- |
| Desktop | Keep the dark section, bounded container and gutters, readable heading and lede, usable action row, cover-media composition, and readable overlay. |
| Tablet | Preserve usable content, adapt media focal treatment and overlay composition as needed, and keep both action roles usable without exposing a breakpoint control. |
| Mobile | Keep heading and lede readable, preserve overlay contrast, and make present actions full width/stacked at narrow widths. |

Consumers do not customize these behaviors through source breakpoints. A later
semantic need can propose a new public contract after evidence, but P6.1 has
none.

## 15. Accessibility contract

### Component-owned guarantees

- Use a semantic section root and one deterministic heading element.
- Render no fabricated image semantics. Apply the explicit `image_alt`
  contract when media exists.
- Preserve native link and button semantics supplied through slots.
- Keep visible keyboard focus styling for interactive action presentation,
  including `:focus-visible` support.
- LiveFrames-owned markup does not itself introduce positive `tabindex`, hidden
  focus targets, inappropriate ARIA replacing native semantics, or
  component-owned root event behavior.
- Omit absent optional content rather than emitting empty semantic nodes.
- Keep output deterministic for the same attrs and slots.

### Consumer responsibilities

- Choose a heading level that fits the surrounding document hierarchy.
- Supply meaningful action text and appropriate native action markup.
- Own link destinations, events, navigation, and all application behavior.
- Decide whether each supplied image is informative or decorative and provide
  `image_alt` accordingly.
- Keep ids unique and use global ARIA/data attributes validly. Consumer-supplied
  global attrs may alter semantics, focus, visibility, ARIA, data attributes,
  LiveView bindings, and appearance; those effects are consumer-owned and
  outside the component-owned guarantee.

This contract does not claim complete WCAG compliance for an application.

## 16. Token responsibility map

P6.1 maps accepted styling intent to existing authority and records gaps. It
does not add tokens.

| Styling intent | Existing authority | Native responsibility | Gap or note |
| --- | --- | --- | --- |
| Section background | `color.background.ultra_dark` | Root section background | Existing token is adequate. |
| Section text | `color.background.ultra_dark.heading` and `.text` | Heading and body text contrast | Existing authority is adequate. |
| Native Hero/display heading visual scale | `typography.heading.scale.h1`, weight, and line height are valid Phase 5 fidelity authority | Keep the Hero's visual scale independent of the selected HTML heading level | **Resolved in P6.4A** — Hero display typography via `--lf-typography-display-*` on `.lf-hero__heading`; see `docs/20` §15. |
| Body typography | `typography.body.scale.medium`, line height | Lede paragraph type | Existing authority is adequate. |
| Section padding | `spacing.section.padding_block` | Section block padding | Existing authority is adequate. |
| Gutter | `spacing.gutter.max` and `.min` | Responsive container gutters | Existing authority is adequate. |
| Content gap | `spacing.content_gap` | Gaps between heading, lede, and actions | Existing authority is adequate. |
| Container width | `layout.viewport.max` | Capped content container | Existing authority is adequate. |
| Primary action colors | `button.primary.background` and `.text` | Primary action surface and text | Existing authority is adequate. |
| Primary action typography | Primary button font size, weight, and line height | Slotted primary action typography | Existing authority is adequate. |
| Primary action border/radius | Primary border, style, width, and radius tokens | Primary action shape | Existing authority is adequate. |
| Primary action hover | `button.primary.background_hover` | Ordinary hover state | Existing authority is adequate. |
| Primary action focus-visible | Primary focus token | Visible keyboard focus state | Existing authority is adequate. |
| Outline action colors | Outline background, text, and border tokens | Secondary action surface and text | Existing authority is adequate. |
| Outline action hover | Outline background-hover, text-hover, and border-hover tokens | Ordinary hover state | Existing authority is adequate. |
| Outline action focus-visible | Outline focus token | Visible keyboard focus state | Existing authority is adequate. |
| Action padding/minimum size | Primary button padding and minimum-width tokens | Usable action hit area | Existing authority is adequate. |
| Overlay | No adequate native semantic overlay token is proven; accepted evidence contains an unresolved overlay expression | Preserve readable content and keep implementation scoped | **Resolved in P6.4A** — component-private `--lf-hero-overlay-*` in `hero.css`; no global overlay token. See `docs/20` §16. |
| Image positioning | No native semantic focal-position token is proven | Preserve responsive composition internally | **Resolved in P6.4A** — component-private focal variables; no public attr. See `docs/20` §17. |

The native Hero/display heading visual-scale gap is separate from heading
semantics. P6.1 recorded display heading scale, overlay, and focal positioning
as gaps without adding tokens. P6.4A now resolves their **architectural**
treatment in `docs/20`: Hero display typography uses source-independent native
visual aliases independent of HTML heading level; overlay remains
component-private; focal positioning remains component-private with no public
breakpoint attrs. P6.4B **implemented and visually verified** those decisions;
owner acceptance records Hero lifecycle **`styling_verified`** (evidence in
`docs/21`).

## 17. Tailwind and CSS boundary

P6.4 owns actual style implementation. P6.1 proposes the boundary only.

### Likely semantic Tailwind responsibilities

Use readable utilities for structural layout: display, positioning, inset,
width, max-width, overflow, flex direction, alignment, gap, and basic
responsive arrangement. Utilities should reference semantic token variables and
must not reproduce source classes or require Automatic.css at runtime.

### Likely theme/token-variable responsibilities

CSS-first `@theme` and the existing TokenSet authority should supply colors,
typography, spacing, container width, radii, and action state values. P6.1
does not create missing overlay or image-position tokens.

### Likely scoped or colocated CSS responsibilities

Keep full-bleed media/overlay layering, gradient direction, responsive focal
position, and direct slotted-action selectors in scoped/colocated CSS when that
is clearer than a long utility string. This is also the natural home for
`:hover`, `:focus-visible`, `:disabled`, `::before`, and `::after` rules that
belong to the component's semantic root.

## 18. Selector and pseudo-state policy

LiveFrames styling must retain ordinary CSS capability. The architecture may
use `:hover`, `:focus-visible`, `:disabled`, `:nth-child(...)` when a future
component genuinely proves it, `::before`, `::after`, and other justified
selectors. Hero evidence currently requires `:hover` and `:focus-visible`.
P6.1 does not invent `:nth-child()` behavior for this Hero. Tailwind
integration must not remove the ability to express legitimate selectors.

## 19. Edge-case behavior

| Case | Contract response |
| --- | --- |
| No image | Valid solid-background section; no placeholder or source asset claim. |
| Decorative image | Consumer supplies `image_alt=""` explicitly. |
| Meaningful image | Consumer supplies non-empty `image_alt`. |
| `image_src` with `image_alt=nil` | Invalid/unknown contract; do not infer decorative semantics. |
| `image_alt` without `image_src` | No image is rendered; the consumer should omit the unused attr. |
| Heading level choice | Integer `1..6` only; default `2`; no arbitrary tag. |
| No lede | Omit paragraph. |
| No actions | Omit action region or empty action output without placeholders. |
| Primary only | Render the primary slot and omit secondary. |
| Two actions | Render named primary and secondary roles. |
| Long heading or lede | Preserve semantic flow and readable responsive layout; no new knob. |
| Consumer action events/links | Render consumer markup; behavior remains consumer-owned. |
| Narrow viewport | Keep content readable and present actions full width/stacked. |
| Consumer classes/global attrs | Merge/pass through according to the documented root contract. |
| Absent optional content | Omit it deterministically. |

## 20. Trust boundary

Attrs and slots are consumer-authored Phoenix values, not raw source-system
strings. The eventual implementation must retain HEEx escaping, must not use
`raw/1` for ordinary content, must not interpolate untrusted values into class
names, must not accept arbitrary tag strings, and must not execute source
JavaScript. This component proposal does not duplicate the Phase 5 compiler
serialization model.

## 21. Performance and scaling

The candidate is render-only static markup:

```text
ETS = N/A
Cachex = N/A
Redis = N/A
Postgres = N/A
PgBouncer = N/A
GenServer = N/A
Oban = N/A
PubSub = N/A
```

It owns no process, database call, network call, polling, or server state.
Avoid abstractions that add runtime work to static presentation.

The known AutomaticCSS atom-count flaky test is unrelated technical debt. It is
not fixed, widened, or used as a P6.1 acceptance gate.

## 22. P6.2 implementation boundary

P6.2 is implemented. It implemented only this approved contract as a Phoenix
function component under the `LiveFrames.Components.Sections` family, starting
from clean `main` containing the approved P6.1 authority.

P6.2 did not broaden the API into a universal Hero framework, add
source-specific names, replace attachment 880, create a media catalogue item,
or claim full visual fidelity.

The library location is
`apps/live_frames/lib/live_frames/components/sections/hero.ex`. Its tests
live under `apps/live_frames/test/live_frames/components/sections/`. A future
Storybook story belongs under
`apps/live_frames_preview/storybook/components/`.

P6.2 does not authorize the semantic Tailwind bridge, native Storybook Hero,
catalogue integration, ejection, or a second tracer. Those require their own
gates.

## 23. Phase 6 STOP conditions

Stop the Phase 6 work and record the exact blocker if:

- owner approval is missing for a contract change;
- a source-specific name, class, ID, attachment, or breakpoint enters the
  public API;
- the component requires state, a LiveComponent, a hook, or server events
  without new evidence;
- implementation would require changing compiler or generated artifacts;
- attachment 880 would be resolved, redistributed, or reclassified;
- a generic Hero taxonomy or variant DSL is being invented from one tracer;
- P6.2 begins before approved P6.1 authority is present on a clean `main`;
- P6.3 or a later phase begins without its authorization;
- a required semantic, accessibility, or responsive behavior cannot be
  represented by this contract;
- tests or CI fail.

## 24. Acceptance gates

These are the gates for the remaining native-component slices. P6.1 is approved. P6.2 is implemented. P6.3 semantic verification is complete. P6.4A architecture is approved; P6.4B1 is merged; P6.4B2 browser verification is owner-accepted; P6.4 workstream is `verified`; Hero lifecycle is **`storybook_verified`**; P6.5 documentation is **owner accepted**; P6.6 Storybook verification is **owner accepted** (§29). Phase 6 exit remains **not yet authorized**.

| Slice | Required result | Current state |
| --- | --- | --- |
| P6.1 API proposal | Owner-approved proposal records category, module/function, complete attrs and slots, runtime guards, semantics, accessibility, behavior ownership, token map, responsive boundary, styling boundary, rejected alternatives, and stop conditions. | `authorized → api_proposed → api_approved` complete. |
| P6.2 implementation | Approved contract implemented as one stateless Phoenix function component with no production or source-runtime leakage, starting from clean `main` containing this authority. | `api_approved → implemented` complete. |
| P6.3 semantic verification | Rendered markup, heading semantics, slots, image semantics, semantic keyboard focus, escaping, runtime guards, and edge cases verified. | `implemented → semantic_verified` complete. |
| P6.4 styling bridge | Token-backed Tailwind/CSS implementation preserves responsive intent and ordinary selectors/pseudo-states without new unapproved tokens. | P6.4 workstream: `verified` (`docs/20`, `docs/21`). P6.4B1 merged; P6.4B2 owner-accepted. |
| P6.5 documentation | Consumer integration, CSS import paths, theme override boundaries, and styling contract documented. | **`documented` / owner accepted** — surfaces in §28; consumer guides: `docs/11`, `docs/16`; module docs in `hero.ex`; README navigation. Hero lifecycle: **`documented`**. |
| P6.6 PhoenixStorybook verification | Native Hero story uses approved API, documents consumer responsibilities, and verifies representative states without claiming source-asset fidelity. | **`storybook_verified` / owner accepted** — `docs/22`; evidence `docs/evidence/p6_6_native_hero_storybook/`; tested source `ad1c6164afbdc3ee42b47ff7b814a89d5c647935`; independent browser review PASS; owner P6.6 approval APPROVED (§29). Hero lifecycle: **`storybook_verified`**. |
| Phase 6 exit / catalogue | Owner accepts semantic, styling, documentation, and Storybook evidence before catalogue or generation/ejection exposure. | **Not yet authorized** — next gate only after PR #34 merged, clean synchronized `main`, and separate owner authorization. Do not begin catalogue, generator/ejection exposure, another tracer, or Hero **`accepted`**. |

## 25. P6.1 completion record

```text
component category = section
component state ownership = none
implementation type = Phoenix function component
module = LiveFrames.Components.Sections.Hero
function = hero/1
source-specific public names = 0
source class/ID leakage in public API = 0
source breakpoint API = 0
Bricks/ACSS public API leakage = 0
ACSS runtime dependency = 0
business-logic leakage = 0
production code changed = 0
generated artifacts changed = 0
reviewed API proposal head = 6eda7ba9a66e16c2902868a82a3621d2d3267c92
P6 lifecycle = authorized → api_proposed → api_approved → implemented → semantic_verified
P6.1 = api_approved
P6.2 = implemented
P6.3 = semantic_verified
P6.4 workstream = architecture_approved
P6.4 implementation = not authorized
P6.4B implementation = not started; not yet authorized
P6.5+ = not authorized
```

P6.4A proposed styling-bridge architecture → independent architecture review
PASS → owner architecture approval (PR #30 branch). P6.2 implementation is present in
`apps/live_frames/lib/live_frames/components/sections/hero.ex`. P6.3 semantic
verification is complete in
`apps/live_frames/test/live_frames/components/sections/hero_semantics_test.exs`.
P6.4A styling-bridge architecture is recorded in `docs/20`. P6.4B styling
implementation, P6.5 documentation, P6.6 Storybook, and Phase 6 acceptance
remain unstarted and unauthorized.

## 26. P6.3 semantic verification record

P6.3 authorized the transition from `implemented` to `semantic_verified` for
the native Hero. It verified semantic HEEx behavior only. It did not verify
visual focus styling, contrast, responsive CSS, Tailwind/token integration,
Storybook, or browser visual acceptance. Those remain P6.4 and later work.

```text
semantic structure = pass
HEEx escaping = pass
image semantics = pass
action semantics = pass
runtime guards = pass
semantic keyboard behavior = pass
source leakage = 0
production corrections = 0
visual focus styling = not verified (deferred to P6.4)
contrast = not verified (deferred to P6.4)
responsive styling = not started
P6 lifecycle = authorized → api_proposed → api_approved → implemented → semantic_verified
P6.1 = api_approved
P6.2 = implemented
P6.3 = semantic_verified
P6.4 workstream = architecture_approved
P6.4 implementation = not authorized
P6.4B implementation = not started; not yet authorized
P6.5+ = not authorized
```

Evidence:

- root semantic structure, exactly-one heading, optional-content omission, and
  deterministic rendering verified in `hero_semantics_test.exs`;
- heading, lede, id, class, image_src, and image_alt escaping verified with
  adversarial values; HEEx remains the serializer authority;
- global consumer attrs (`data-*`, `aria-*`, `title`, explicit `tabindex`)
  pass through; default LiveFrames output does not introduce component-owned
  `tabindex`, `phx-click`, `role`, `aria-label`, or `hidden`;
- image states (absent, informative, decorative, alt-without-src, missing-alt
  guard) verified; no fabricated image ARIA;
- native primary button and secondary link slot content preserved unchanged;
  component-owned positive tabindex = 0; component-owned hidden focus target =
  0; component-owned event behavior = 0;
- slot cardinality guards and O(1) validation preserved; P6.2 contract tests
  remain authoritative for the heading-level matrix and duplicate-slot errors;
- production `hero.ex` unchanged; no semantic defect required correction.

## 27. P6.4 styling verification record

Owner evidence gate **APPROVED** after independent browser review **PASS** on PR
#32 (`docs/21`). This records durable lifecycle transitions only; PR #32 merge
to clean synchronized `main` remains the publication gate.

```text
P6.3 = semantic_verified
P6.4 workstream = verified
Hero lifecycle at P6.4 close = styling_verified
P6.4B1 = merged
P6.4B2 = verified / owner accepted
```

Current Hero lifecycle and P6.5 acceptance are recorded in §28.

## 28. P6.5 documentation owner acceptance record

Owner documentation review **APPROVED** at head
`31416d7f545fa194b92303afe0a2503142516227` (PR #33). P6.5 records
consumer-facing documentation only; no Hero markup, attrs, slots, CSS, tokens,
or preview runtime changes were in scope.

```text
P6.3 = semantic_verified
P6.4 = verified
Hero lifecycle = documented
P6.5 = documented / owner accepted
P6.6 = not yet authorized
```

Owner-approved documentation surfaces:

| Surface | Role |
| --- | --- |
| `docs/11_CSS_AND_TAILWIND_STRATEGY.md` | Cross-cutting CSS/Tailwind strategy and theme boundaries |
| `docs/16_PACKAGE_AND_GENERATOR_MODEL.md` | Phoenix consumer package guide, CSS paths, Plug.Static, Hero API |
| `apps/live_frames/lib/live_frames/components/sections/hero.ex` | `@moduledoc` / `@doc` consumer contract at source |
| `README.md` | Concise consumer navigation |

Durable consumer homes: **`docs/16`** for integration, **`docs/11`** for styling
boundaries. Architecture history remains **`docs/20`**; browser evidence remains
**`docs/21`**.

P6.6 Storybook verification owner acceptance is recorded in **`docs/22`** and §29.
Do not advance Hero to **`accepted`** or authorize Phase 6 exit without the merge
and authorization gates in §24.

## 29. P6.6 Storybook verification owner acceptance record

Owner P6.6 gate **APPROVED** after independent browser review **PASS** on PR #34.
This records durable lifecycle transitions only; PR #34 merge to clean synchronized
`main` remains the publication gate. Production Hero and library CSS were unchanged
for browser-tested source `ad1c6164afbdc3ee42b47ff7b814a89d5c647935`.

```text
P6.4 = verified
P6.5 = documented / owner accepted
Hero lifecycle = storybook_verified
P6.6 = storybook_verified / owner accepted
Phase 6 exit = not yet authorized
```

```text
tested Storybook source = ad1c6164afbdc3ee42b47ff7b814a89d5c647935
independently reviewed candidate head = bab0d7e6024c452d20abb8e2137c7720a0bffc9b
independent browser review = PASS
owner P6.6 approval = APPROVED
```

Owner-accepted evidence surfaces:

| Surface | Role |
| --- | --- |
| `apps/live_frames_preview/storybook/components/hero.story.exs` | PhoenixStorybook story module |
| `apps/live_frames_preview/assets/css/storybook.css` | Storybook CSS entry (package artifact import) |
| `apps/live_frames_preview/test/live_frames_preview_web/native_hero_storybook_test.exs` | Structural ExUnit verification |
| `docs/22_P6_6_NATIVE_HERO_STORYBOOK_VERIFICATION.md` | Verification authority and browser evidence summary |
| `docs/evidence/p6_6_native_hero_storybook/` | Manifest and screenshots |

Story module: `LiveFramesPreviewWeb.Storybook.Components.Hero`. Route:
`/storybook/components/hero`.
