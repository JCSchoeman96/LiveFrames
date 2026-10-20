# Lead 3 Page Tracer Architecture Design

**Status:** DESIGN — awaiting owner review and approval. This document does not authorize implementation.

**Date:** 2026-10-19

## 1. Frozen design base

```text
BASE_SHA=1d2110e98b3db50b6c7c1ba82fe832ec347caecf
BASE_TREE=d9d20998ab1ff06965a7b76d17b37f4af5e19ff4
BASE_MAIN_CI=39304376510
BASE_MAIN_CI_RESULT=PASS
```

The design branch starts exactly at this accepted `main` identity. Subsequent implementation must freeze its own accepted base and must not silently treat this design base as an implementation authorization.

## 2. Programme shift and preserved authority

Lead 3 is now responsible for proving that genuinely converted LiveFrames sections can be composed into increasingly complete real pages and consumed by normal Phoenix and Ash applications.

Public release is no longer the immediate critical path. The following accepted state remains authoritative and must not be weakened:

```text
C2D3=MERGED_ACCEPTED
CTA_STATE=APPROVED
CTA_LIBRARY_CAPABILITY=SUPPORTED

REDISTRIBUTION_STATUS=unknown
PUBLICATION_STATE=classified

APPROVED_TO_RELEASED=NOT_AUTHORIZED
CATALOGUE_PUBLIC_RELEASE=NOT_AUTHORIZED
PACKAGE_PUBLICATION=NOT_AUTHORIZED
P10_PUBLIC_RELEASE=NOT_AUTHORIZED
```

Technical internal/private usability is a separate question from public redistribution. This design proves technical consumption only. It does not establish legal permission, provenance clearance, package-publication authority, Catalogue release authority, or P10 authority.

## 3. Ultimate goal

The long-term Lead 3 outcome is:

```text
real source page
  -> LiveFrames conversion
  -> genuine native components
  -> page composition
  -> ordinary Phoenix application
  -> ordinary Ash/Phoenix application
  -> real project usability
```

A consuming developer must not need knowledge of Bricks IDs, Frames selectors, ACSS source classes, private-reference payloads, `ComponentizationPlan` internals, or `DesignDocument` internals.

Page composition must expose generic compiler/runtime gaps rather than bypass them.

## 4. Backward plan from real-project usability

Real-project usability requires these systems in dependency order:

1. Genuine native component supply from Leads 1 and 2.
2. A durable page-scenario contract describing intended composition without requiring unavailable components to be faked.
3. A readiness/report model that records supported, partial, blocked, and not-required states per capability.
4. A fast in-repository preview page for visual/composition feedback.
5. A clean external Phoenix consumer proof of the same scenario using the accepted LiveFrames library/CSS boundary.
6. Browser-level multi-viewport and collision evidence.
7. Later Ash/Phoenix consumption that feeds host-owned data into the same ordinary Phoenix component APIs.
8. Repetition across Frames-heavy, ordinary Bricks+ACSS, and mixed source-family page tracers.

The MVP is the smallest slice of this final architecture: one Page A scenario using only the native sections already available on `main`, while recording unavailable intended sections honestly as blockers.

## 5. Current component reality

At this design base the production section directory contains two concrete native sections:

```text
LiveFrames.Components.Sections.Hero.hero/1
LiveFrames.Components.Sections.MediaCallToAction.media_call_to_action/1
```

The first page tracer must therefore use those components as genuine supported anchors. It must not manufacture Header, Romeo, Milan, Pricing, Gallery, Slider, FAQ, or other sections with handwritten replacement HTML/CSS/JavaScript and then classify them as converted.

## 6. Architectural decision

Adopt a **dual-layer Page Tracer architecture**:

```text
PageScenario
  |
  +-- Preview Page Lab
  |     fast in-repository visual/composition feedback
  |
  +-- External Phoenix Consumer Proof
        independent dependency/asset/consumer-boundary evidence
```

These surfaces prove different things and must remain distinct.

The preview application must never be treated as proof of clean external consumption.

The external consumer proof must not become the primary visual-development environment.

Both surfaces consume the same public LiveFrames component APIs and the same scenario intent.

## 7. Host-owned page composition

Page composition remains host-owned.

Do not introduce a `LiveFrames.PageRuntime`, `LiveFrames.AshComponent`, page-specific server process, or second compiler path for Page A v0.

A page is a separate generation/composition target. It is not another `ComponentContract.category`.

The normal boundary is:

```text
host route / LiveView / controller
  -> host assigns or view model
  -> ordinary LiveFrames function components
  -> package-owned LiveFrames CSS
```

Later Ash consumption is:

```text
Ash resource/action/query
  -> host application
  -> host assigns / presentation view model
  -> ordinary LiveFrames function components
```

LiveFrames components must not query Ash resources merely because an owner project uses Ash.

## 8. Domain resource map

### 8.1 PageScenario

Represents one stable page-scale tracer definition.

Required conceptual fields:

```text
id
source_type
source_digest_or_identity
consumer_intent
ordered_sections
expected_consumer_targets
```

`PageScenario` is repository-owned test/design metadata. It is not runtime application domain state.

### 8.2 ScenarioSection

Represents one intended section in page order.

Conceptual fields:

```text
id
label
order
component_identity_or_nil
owning_lead
readiness
blocker_refs
```

A missing component identity is permitted when the section is intentionally tracked as blocked. It must not cause a bypass implementation.

### 8.3 ReadinessMatrix

Records each section against the following capability axes:

```text
Source admitted
Design IR
Componentized
Generated HEEx
Generated CSS
Responsive
Navigation
Behavior
Browser verified
Consumer verified
Ash/data ready
```

Allowed states are exactly:

```text
SUPPORTED
PARTIAL
BLOCKED
NOT_REQUIRED
```

The matrix is evidence/reporting state, not a Catalogue lifecycle.

### 8.4 ConsumerProofRun

Represents one bounded execution of one `PageScenario` against one consumer target and one exact LiveFrames identity.

Conceptual fields:

```text
scenario_id
consumer_target
liveframes_sha
liveframes_tree
proof_state
commands_or_checks
browser_result
report_ref
```

### 8.5 Blocker

Represents one reproducible generic gap.

Conceptual fields:

```text
code
section_id
capability
owner_lead
summary
reproduction
blocking_reason
```

Routing is fixed:

```text
converter/style/navigation -> Lead 1
behavior/runtime            -> Lead 2
consumer/composition        -> Lead 3
```

### 8.6 BrowserProof

Records page-level evidence that isolated components cannot establish:

```text
viewport
layout_result
overflow_result
focus_result
navigation_result
interaction_result
stacking_result
css_isolation_result
multi_instance_result
```

Structural, functional, and visual fidelity must be reported separately.

## 9. ConsumerProofRun lifecycle

The proof lifecycle is:

```text
DEFINED
  -> ENVIRONMENT_READY
  -> DEPENDENCY_RESOLVED
  -> PAGE_RENDERED
  -> ASSETS_VERIFIED
  -> BROWSER_VERIFIED
  -> PASSED
```

Exceptional terminal states:

```text
BLOCKED
FAILED
PASSED
```

### 9.1 Transition guards and side effects

| Transition | Guard | Side effect |
|---|---|---|
| `DEFINED -> ENVIRONMENT_READY` | consumer environment is independent and contains no copied LiveFrames source/private material | create proof environment only |
| `ENVIRONMENT_READY -> DEPENDENCY_RESOLVED` | exact accepted LiveFrames identity resolves through the authorized dependency mode | install/resolve consumer dependencies |
| `DEPENDENCY_RESOLVED -> PAGE_RENDERED` | host compiles and renders only genuine supported LiveFrames components for the scenario | render page |
| `PAGE_RENDERED -> ASSETS_VERIFIED` | package-owned LiveFrames CSS is served once and required selectors/assets are present | record asset evidence |
| `ASSETS_VERIFIED -> BROWSER_VERIFIED` | page is available for browser proof and has no known fail-fast collision | record viewport/composition evidence |
| `BROWSER_VERIFIED -> PASSED` | all required assertions and report fields are independently reviewable | freeze proof report |

A failed guard may not be downgraded to a warning simply to advance the state.

At any nonterminal state, an unavailable external prerequisite may terminate as `BLOCKED`. A violated contract, bypass, source leak, collision, or false readiness claim terminates as `FAILED`.

## 10. Page A v0 scenario

### 10.1 Intent

Page A ultimately represents a Frames-heavy page. v0 deliberately starts before all desired sections are available.

Target conceptual composition:

```text
Hero                       SUPPORTED
Feature Romeo              BLOCKED_LEAD_1
Feature Milan              BLOCKED_LEAD_1_OR_2
Pricing Echo               BLOCKED_LEAD_1
Gallery Bravo              BLOCKED_LEAD_1
Slider Basel               BLOCKED_LEAD_2
CTA Tango                  SUPPORTED
```

The rendered v0 page contains only genuine supported sections.

### 10.2 Rendered v0 composition

Use exactly these supported component instances for the first tracer:

```text
Hero instance A
CTA Tango instance A
CTA Tango instance B
```

The two CTA instances must use intentionally different caller-owned content so repeated-instance behavior is actually exercised:

```text
different headings
different image values
different action destinations
different body slot content
different additive root classes
```

The page must not use copied source markup as filler between those components.

### 10.3 Why two CTA instances

A single Hero + single CTA would prove little beyond isolated component coexistence. Two independent CTA instances immediately exercise:

- repeated component classes;
- repeated nested generated selector families;
- caller-owned content independence;
- additive root-class isolation;
- DOM/behavior identity assumptions;
- stylesheet deduplication expectations.

## 11. Preview Page Lab

The in-repository preview application owns a page-scale visual harness.

Recommended route namespace:

```text
/liveframes/pages/frames-a-v0
```

Recommended module naming:

```text
LiveFramesPreviewWeb.PageTracers.FramesPageAV0Live
```

The implementation plan may adjust exact file placement to match existing preview conventions, but it must retain the `PageTracers` responsibility boundary rather than extending the existing isolated Hero preview into an unrelated catch-all.

The preview page must:

- render the supported scenario instances through the production component modules;
- use test-owned/synthetic caller content and public assets only;
- load LiveFrames CSS through the preview application's existing accepted asset integration;
- expose no private source bytes, Bricks IDs, Frames selectors, or ACSS source configuration;
- contain no handwritten substitutes for blocked scenario sections;
- surface the scenario/readiness report near the page or through a deterministic test/report artifact rather than hiding unavailable sections.

## 12. External Phoenix consumer proof

The external consumer proof extends the accepted C1 philosophy rather than replacing it.

The proof environment must remain outside the LiveFrames repository and worktrees.

Initial dependency mode remains conceptually:

```text
LOCAL_PATH_TO_EXACT_LIVE_FRAMES_APP
```

until a separately authorized proof intentionally changes that mode.

The consumer must:

- resolve one exact accepted LiveFrames revision;
- compile without depending on `live_frames_preview` or Phoenix Storybook;
- render Hero + CTA A + CTA B using normal public Phoenix component APIs;
- serve the package-owned precompiled LiveFrames stylesheet through host-owned static delivery;
- require no host Tailwind build for the primary proof;
- contain no copied private-reference, Bricks, Frames, fixture, or ACSS source material;
- leave the accepted LiveFrames checkout unchanged.

The Page A proof supersedes neither C1 history nor Catalogue evidence. It is new page-scale consumer evidence.

## 13. Page report contract

Every page-scale run must emit a deterministic human-readable report containing at least:

```text
PAGE_ID
SOURCE_TYPE
SOURCE_DIGEST

CONSUMER_TARGET
LIVEFRAMES_SHA
LIVEFRAMES_TREE

SECTIONS_DISCOVERED
SECTIONS_GENERATED
SECTIONS_PARTIAL
SECTIONS_BLOCKED

SECTION_MATRIX

GENERIC_GAPS
BEHAVIOR_GAPS
DATA_GAPS
CONSUMER_GAPS

STRUCTURAL_FIDELITY
FUNCTIONAL_FIDELITY
VISUAL_FIDELITY

BROWSER_RESULT
```

For Page A v0, blocked intended sections are part of the report even though they are not rendered.

Do not convert `BLOCKED` to `PARTIAL` merely because a handwritten approximation exists. Handwritten approximations are outside the proof.

## 14. Component reuse proof requirements

Every rendered component family in a mature tracer should eventually prove:

```text
one instance
multiple instances
different content
different destinations
different images
different slot contents
different parent layouts
```

Page A v0 begins this programme with one Hero instance and two CTA instances. Hero multi-instance proof may follow when it adds value; it is not required to inflate the first tracer.

## 15. Browser proof

Page-level browser verification must move beyond isolated Storybook/component rendering.

Required viewport classes:

```text
desktop
tablet
mobile
```

Required observations:

```text
layout
overflow
focus
navigation
interaction
visual stacking
CSS isolation
multiple components
multiple instances
```

For noninteractive Page A v0 components, unsupported behavior checks are `NOT_REQUIRED`, not fabricated `SUPPORTED` claims.

Browser evidence reports separately:

```text
STRUCTURAL_FIDELITY
FUNCTIONAL_FIDELITY
VISUAL_FIDELITY
```

Pixel-perfect source fidelity is not a prerequisite for basic practical usability, but known visual deltas must not be hidden.

## 16. Collision and composition invariants

Page tracers specifically own failure classes that isolated component tests may miss.

The following are hard invariants:

```text
ONE_LIVEFRAMES_STYLESHEET_PER_PAGE
NO_CSS_DUPLICATION_PER_COMPONENT_INSTANCE
NO_TOKEN_REEMISSION_PER_INSTANCE
NO_DOM_ID_COLLISION
NO_BEHAVIOR_INSTANCE_COLLISION
NO_ASSET_COLLISION
NO_DUPLICATED_GLOBAL_LISTENERS
NO_POLLING
NO_PER_COMPONENT_SERVER_PROCESS_BY_DEFAULT
NO_SOURCE_IR_WALK_ON_EVERY_RENDER
```

A collision is a proof failure, not an opportunity to patch the page with one-off selectors or JavaScript.

## 17. Ash boundary

Ash is deliberately not part of Page A v0 implementation.

After ordinary Phoenix page consumption is accepted, reuse the same ordinary component APIs in an Ash/Phoenix consumer.

Default architecture:

```text
Ash resource/action/query
  -> host-owned efficient fetch/load
  -> host-owned presentation shaping
  -> LiveFrames Phoenix component
```

Rules:

- no Ash dependency is added to the `live_frames` library solely for consumer convenience;
- components do not execute Ash queries;
- host applications own authorization, query/load strategy, pagination, preload/load behavior, and N+1 avoidance;
- components own presentation of caller-provided values/collections;
- inability to express a collection through the existing component contract must be reported as a generic binding/component-contract gap rather than solved by embedding Ash inside presentation code.

`STOP=ASH_COUPLING_WITHOUT_AUTHORITY` if the proof requires Ash-specific component changes without separate architecture approval.

## 18. Source-family tracer roadmap

### Page A — Frames-heavy

Purpose:

```text
stress Frames conversion breadth
stress reusable Behavior primitives
stress shared source assumptions
```

Starts immediately with v0 and expands as Leads 1/2 provide genuinely supported sections.

### Page B — ordinary Bricks + ACSS

Must eventually exercise a real representative page containing ordinary Bricks structure, headings, links, buttons, images, responsive layout, ACSS classes/tokens, and realistic local styling/custom CSS.

Purpose:

```text
prove LiveFrames is not Frames-specific
prove ordinary Bricks + ACSS conversion
```

The owner should build/export this representative source page only after the Page A harness architecture is proven, so Page B tests conversion rather than debugging the harness itself.

### Page C — mixed

Combines normal Bricks, Frames sections, ACSS, local custom CSS, and interaction.

Purpose:

```text
prove messy real-project composition
```

Page C is the strongest long-term tracer but must not be the first implementation slice.

## 19. Folder and naming architecture

The implementation plan should preserve these responsibility boundaries.

Recommended repository structure:

```text
docs/superpowers/specs/
  2026-10-19-lead3-page-tracer-design.md

docs/development/page_tracers/
  <accepted evidence and page reports only>

apps/live_frames_preview/lib/live_frames_preview_web/live/page_tracers/
  frames_page_a_v0_live.ex

apps/live_frames_preview/test/live_frames_preview_web/page_tracers/
  frames_page_a_v0_live_test.exs
```

External consumer environments remain disposable/outside the repository unless a later design explicitly creates a committed consumer fixture.

Naming rules:

- `PageTracer` means proof/integration infrastructure, not compiler output.
- `PageScenario` means intended page composition/reporting metadata.
- production converted components remain under `LiveFrames.Components.*` according to existing component naming authority.
- do not place Lead 3 page-specific code inside converter, IR, or componentization contexts.
- do not create a `LiveFrames.Pages` production namespace merely to house the preview tracer.

## 20. Security and provenance boundaries

Page tracer inputs and caller content are untrusted application data where applicable.

Do not execute or evaluate source JavaScript/PHP/modules as part of page assembly.

Do not copy private-reference payloads into public consumer proof applications.

Do not expose builder IDs, source-only classes, source filesystem paths, credentials, or private screenshots as consumer APIs.

Technical private/internal consumption evidence does not establish legal internal-use authority. Rights remain a human governance question.

Public redistribution remains blocked when provenance authority says it is blocked.

## 21. Performance and scaling review

Page-scale integration must ask these questions on every tracer:

- Is CSS emitted or loaded once, rather than per component instance?
- Are semantic token variables emitted repeatedly?
- Are hooks/listeners duplicated?
- Are assets fetched repeatedly without reason?
- Does generation repeatedly traverse entire IR trees for each component?
- Can shared lookups be indexed once per conversion/page build?
- Can many components coexist without one server process per component?

For client-local interactions:

```text
polling=forbidden
per_component_server_process=not_default
```

For Ash-backed data:

```text
host_owns_query=true
host_owns_loading=true
component_owns_presentation=true
n_plus_one_must_be_prevented_by_host=true
```

Page A v0 itself is static integration proof work and must introduce no Postgres, Redis, ETS, Cachex, GenServer, PubSub, Oban, PgBouncer, or read-replica dependency.

Performance classification for Page A v0:

```text
DATA_LAYER=BUILD_TEST_AND_BROWSER_PROOF
POSTGRES=N/A
REDIS=N/A
ETS=N/A
CACHEX=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
PGBouncer=N/A
READ_REPLICA=N/A
RUNTIME_DB_CALLS=0
RUNTIME_POLLING=0
```

## 22. Failure modes and ownership

### Lead 1 failures

```text
converter/style normalization gap
responsive conversion gap
navigation/static semantic gap
CSS output insufficiency
unsupported native component output
```

### Lead 2 failures

```text
missing behavior primitive
behavior ownership unresolved
runtime interaction gap
behavior-instance collision
timer/disclosure/dropdown/carousel runtime gap
```

### Lead 3 failures

```text
consumer dependency mismatch
package/static asset integration failure
page composition collision
multiple-instance collision
consumer-only CSS ordering issue
browser page failure
Ash/data-boundary failure
```

Lead 3 investigates enough to produce a reproducible blocker before routing it. Lead 3 must not fix Lead 1/2 gaps with page-local bypasses.

## 23. Hard STOP conditions

```text
STOP=PAGE_COMPLETION_REQUIRES_BYPASS
STOP=COMPONENT_NOT_ACTUALLY_CONVERTED
STOP=CONSUMER_REQUIRES_SOURCE_RUNTIME
STOP=PRIVATE_SOURCE_LEAK
STOP=CSS_COMPONENT_COLLISION
STOP=DOM_ID_COLLISION
STOP=BEHAVIOR_INSTANCE_COLLISION
STOP=ASH_COUPLING_WITHOUT_AUTHORITY
STOP=DATA_OWNERSHIP_UNDEFINED
STOP=PUBLIC_RELEASE_REQUIRES_PROVENANCE
STOP=ACTIVE_SHARED_AUTHORITY_CONFLICT
```

Additional implementation-safety STOPs:

```text
STOP=MAIN_MOVED
STOP=UNEXPECTED_SCOPE_EXPANSION
STOP=PARALLEL_COMPILER_PATH_REQUIRED
STOP=PREVIEW_USED_AS_EXTERNAL_CONSUMER_PROOF
STOP=EXTERNAL_PROOF_MUTATES_LIVEFRAMES
```

If three implementation hypotheses fail for one blocker, stop and route the reproducible gap rather than continuing open-ended experiments.

## 24. Page A v0 acceptance criteria

The first implementation tranche is successful only when all of these are true:

```text
REAL_PAGE_COMPOSITION_STARTED=YES
SUPPORTED_COMPONENTS_BYPASSED=NO
UNSUPPORTED_COMPONENTS_FAKED=NO

HERO_CONSUMER=PASS
CTA_INSTANCE_A=PASS
CTA_INSTANCE_B=PASS

PREVIEW_PAGE_RENDER=PASS
EXTERNAL_PHOENIX_PAGE_RENDER=PASS

SINGLE_PRECOMPILED_CSS_PATH=PASS
CSS_COMPONENT_COLLISION=NO
DOM_ID_COLLISION=NO
BEHAVIOR_INSTANCE_COLLISION=NO_OR_NOT_REQUIRED

PRIVATE_SOURCE_LEAK=NO
SOURCE_RUNTIME_REQUIRED=NO

READINESS_MATRIX=PRODUCED
BLOCKERS_ROUTED_TO_CORRECT_LEAD=YES

STRUCTURAL_FIDELITY=RECORDED
FUNCTIONAL_FIDELITY=RECORDED
VISUAL_FIDELITY=RECORDED

PUBLIC_RELEASE_STATE=UNCHANGED
PROVENANCE_STATE=UNCHANGED
```

## 25. Non-goals for the first implementation plan

Do not include any of these in Page A v0:

- public package or Hex publication;
- Catalogue `APPROVED -> RELEASED`;
- provenance mutation or clearance inference;
- P10 consumer-project ejection;
- Ash integration;
- Page B or Page C source-page conversion;
- new behavior runtime primitives;
- new Frames section conversion owned by Lead 1/2;
- a generic production page runtime;
- a committed standalone consumer application unless the implementation plan separately justifies it;
- one-off JavaScript or handwritten copied source markup to fill unavailable sections.

## 26. Implementation planning boundary

After this design is owner-approved, create a separate implementation plan for **Page A v0 only**.

The implementation plan must use TDD, exact file paths, isolated worktree execution, minimal code, and independently reviewable task boundaries.

It should decompose Page A v0 into the smallest reviewable units rather than asking one agent to "make the whole page work".

A later plan may extend the scenario with new Lead 1/2 components after those components are independently accepted.

No implementation is authorized by this design document until the owner reviews and approves this written specification.
