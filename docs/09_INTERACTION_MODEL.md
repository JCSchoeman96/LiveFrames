# Interaction model

**Status:** accepted architecture authority for future behavior work. This document authorizes no implementation.

**Authority revision:** 1.0.0

**Revision date:** 2026-10-09

## 1. Authority, scope, and status

`docs/00_LIVEFRAMES_MASTER_SPEC.md` remains the product and architecture authority. This document owns the source-neutral behavior contract, primitive semantics, and boundary between normalized behavior and runtime realization. The Design IR, source/provenance, and native-generation authorities keep their existing scopes.

This document replaces the interaction-model placeholder. It defines the contract required before interactive source conversion, behavior normalization, runtime hooks, or interactive native generation may begin. It does not create implementation structs, change schemas, select a vendor runtime, or authorize a later phase.

The conceptual artifact is **BehaviorContract 1.0.0**. Its format version is independent of Design IR. A later implementation must define canonical serialization and digest calculation before relying on a DesignDocument digest. This authority alone does not freeze a serializer or cryptographic algorithm.

## 2. Baseline and repository truth

The accepted starting point for this authority is:

```text
BASE_SHA=3b18f94bb0ca960a4dcb6af441776addb8109b7a
BASE_TREE=b0ae20b5bf05a29e39c665547f0d877c532c7a4a
DESIGN_IR_VERSION=3.0.0
PHOENIX_LIVE_VIEW=1.2.11 (repository lockfile)
```

At this baseline, `LiveFrames.IR.Interaction` contains an interaction ID, intent, optional trigger, target node IDs, parameters, and source trace. The Design IR specification says that this records intent and does not choose CSS, `Phoenix.LiveView.JS`, hooks, server events, or LiveComponents. Nodes can reference the interaction registry, but the Bricks normalizer currently emits an empty registry and empty node references. C-07X already records the missing shared behavior and browser-runtime path. C09D6 defers Behavior IR and interactive generation. These authorities agree with this document; no existing authority conflict was found.

## 3. Authority hierarchy and evidence classes

Use evidence in this order for its stated domain:

1. W3C Recommendation text, HTML Living Standard, and the applicable Phoenix LiveView release documentation for platform facts.
2. This document for accepted LiveFrames behavior architecture decisions.
3. Accepted repository authorities and their recorded implementation facts.
4. Private source and exports as constrained evidence of source intent only.
5. Inference, which must be labeled and must never be presented as observed source or platform behavior.

The evidence ledger uses these source classes:

| Class | Meaning |
| --- | --- |
| `REPOSITORY_EVIDENCE` | A versioned repository file or observed implementation fact. |
| `PRIVATE_REFERENCE` | Read-only source/export evidence that is not redistributed and is not runtime authority. |
| `EXTERNAL_STANDARD` | A cited platform specification or guidance document, with its status named. |
| `ARCHITECTURAL_DECISION` | A contract choice made here for LiveFrames. |
| `INFERENCE` | A conclusion derived from evidence; it remains explicitly provisional until accepted. |

WAI-ARIA 1.2 is a W3C Recommendation. The WAI-ARIA Authoring Practices Guide (APG) supplies recommended authoring patterns and examples; its examples are not normative specification text. Native HTML semantics take priority where they correctly express the behavior. Phoenix integration claims are limited to the project's pinned LiveView 1.2.11 docs/API and must be checked against that release during implementation.

## 4. Goals and non-goals

The contract must let adapters preserve behavior evidence, let reviewers approve source-neutral semantics, and let generators choose an appropriate native or client realization without importing source-system behavior. It must support accessible state changes, predictable cleanup, deterministic references, progressive enhancement, and diagnostics for unsupported input.

This authority does not define a Frames or Bricks runtime, copy source JavaScript, specify generated markup, add Design IR fields, select a carousel library, define a generic event bus, or authorize interaction implementation. It does not assume that screenshots establish transition behavior.

## 5. BehaviorContract and Design IR relationship

BehaviorContract is a separate, versioned semantic artifact linked to one exact DesignDocument. The conceptual flow is:

```text
admitted source
  ├─ structural/style/data normalization → DesignDocument 3.x
  └─ behavior evidence normalization → BehaviorContract 1.0.0
                                          ├─ exact DesignDocument version and digest
                                          ├─ document-local DesignNode references
                                          ├─ source-neutral bindings and state models
                                          ├─ accessibility and runtime policies
                                          └─ diagnostics and source provenance
```

The contract identity must include its format version, exact DesignDocument IR version, digest of that exact document under a named canonicalization, document-local node IDs, bindings, diagnostics, and provenance. A missing digest, unresolved reference, or unrecognized canonicalization is invalid; consumers fail closed rather than attach behavior to a merely similar document.

The existing Design IR 3.x `Interaction` remains a coarse intent record. It may coexist as legacy intent evidence, but cannot become a competing state-machine authority. A future explicit Design IR migration may decide whether interaction refs point to, absorb, or are superseded by BehaviorContract bindings.

Rejected for this phase:

1. Expanding `LiveFrames.IR.Interaction` into a complete state machine. That would change field meaning and serialized/validated behavior, and risks mixing semantic intent with runtime implementation. Any such change requires a deliberate Design IR version and migration decision.
2. Adding a required `behaviors` registry to DesignDocument now. A required root field changes the current Design IR 3.0.0 contract and likewise requires an explicit future version/migration decision.

Neither option is permanently prohibited. This authority does not pre-authorize either change.

## 6. Domain model and relationship rules

These are conceptual domain terms, not implementation structs. Every reference is typed and resolves within the exact DesignDocument or BehaviorContract named by its owner. No relationship uses a source-provided selector.

| Term | Owner and cardinality | Allowed references and invariant | Invalid or missing relationship |
| --- | --- | --- | --- |
| `BehaviorContract` | Conversion result; one exact DesignDocument per contract; zero or more bindings and diagnostics | Holds BehaviorContract version, DesignDocument version/digest, provenance, bindings, diagnostics. Digest and versions must identify one immutable input. | Reject the contract; never attach to a different document by resemblance. |
| `BehaviorPrimitiveDefinition` | Behavior vocabulary; one definition per normalized primitive kind/version | May be referenced by many bindings. Defines closed semantics and policies, not source runtime code. | Unknown primitive is unsupported and diagnosed. |
| `BehaviorBinding` | One occurrence in one contract; exactly one primitive and one owner node | Owner and targets are document-local DesignNode IDs. Binding identity is deterministic from document context, primitive kind, owner, and stable role/ordinal. | Reject unresolved, ambiguous, or out-of-scope references. |
| `Trigger` | Owned by one binding; zero or more typed trigger records | Closed vocabulary such as activate, key, pointer, focus, timer, visibility, or platform preference. Optional origin node must belong to the binding scope. | Unknown trigger is diagnosed and disabled; never parse it as an event name. |
| `ControlledTarget` | Owned by one binding; zero or more typed targets with role-specific cardinality | References a node in the same DesignDocument and binding scope, with a role such as content, panel, tab, item, dialog, or control. Each primitive defines required roles/cardinality. | Missing required target prevents that binding from being generated. No selector fallback. |
| `BehaviorStateModel` | Owned by one primitive definition; one or more state dimensions | Each dimension has a finite domain, initial value, invariants, and terminal rule where applicable. Product state must satisfy every invariant. | Invalid combinations are rejected, not normalized by guessing. |
| `Transition` | Owned by one state model; zero or more named transitions | Names a source condition, trigger, destination, guards, and effects. It may target one dimension or a documented atomic set. | A transition that violates an invariant is invalid and produces no effects. |
| `TransitionGuard` | Owned by one transition; zero or more pure predicates | Reads normalized state, enabled policy, and typed local context only. It has no side effects or I/O. | False guard is a no-op; unknown guard is unsupported and diagnosed. |
| `BehaviorEffect` | Owned by one transition; zero or more effects | Closed semantic effects such as reveal, conceal, select, focus, move, start/stop timer, or synchronize state. | Unrecognized effects fail closed; no arbitrary DOM mutation. |
| `AccessibilityEffect` | Owned by one transition/effect; zero or more synchronized updates | Updates the semantic state, relationships, focus policy, and exposed accessibility state as one transition outcome. | If accessible state cannot match semantic state, the transition must not be emitted as complete behavior. |
| `RuntimeEffect` | Owned by a realization plan for a binding; zero or more operations | Maps semantic effects to an approved platform/runtime operation. It is not executable source embedded in BehaviorContract. | No realization is emitted when the runtime cannot represent the contract safely. |
| `TimerPolicy` | Owned by a binding; zero or one policy unless a primitive defines named timers | Defines purpose, eligibility, start/stop/restart/reset behavior, and reduced-motion interaction. Runtime timer handles are never serialized. | Missing or unbounded timer policy disables timed behavior and emits a diagnostic. |
| `FocusPolicy` | Owned by a binding; zero or one named policy | Defines initial focus, focus containment/roving, restoration, and owner scope as applicable. | Unresolvable focus destination uses the documented safe fallback or rejects modal behavior. |
| `KeyboardPolicy` | Owned by a binding; zero or one policy per keyboard interaction model | Maps a closed set of keys and modifiers to transitions and focus movement. | Unknown key mapping is unsupported; no source string becomes a listener. |
| `MotionPolicy` | Owned by a binding; zero or one policy | Defines animation permission, reduced-motion behavior, and whether time affects semantic state. | Missing policy defaults to no autoplay and reduced/non-motion realization. |
| `ResponsiveBehaviorOverride` | Owned by a binding; zero or more named mode mappings | References accepted responsive authority and defines a reversible semantic state mapping between modes. It is not a CSS style override. | Missing authority or non-reversible mapping prevents the mode conversion and emits a diagnostic. |
| `BehaviorDiagnostic` | Owned by a contract and optionally linked to one binding/node/evidence item; zero or more | Uses stable category/severity and records source evidence and the unsupported/ambiguous condition. | A diagnostic may not silently be dropped when the behavior is dropped. |
| `RuntimeInstance` | Ephemeral runtime for one binding and one component/repeated-item scope; zero or more per binding | Holds live DOM references, timer handles, observers, focus ownership, and transient state only while mounted. Never serialized. | On invalid mount/update it disables that instance and releases resources; destruction is terminal. |

No binding may target a node owned by another component by default. A future cross-component contract needs an explicit typed capability and owner-approved scope. It cannot be inferred from matching IDs, classes, or DOM proximity.

## 7. Identity, repeated instances, and targeting

Compile-time binding identity derives only from stable normalized document context: the DesignNode owner ID, primitive kind, stable binding role/ordinal, and contract identity. It must not depend on random IDs, Frames/Bricks IDs, vendor names, or unstable source traversal artifacts beyond the deterministic normalized node identity already accepted by Design IR.

Runtime scope is separate from compile-time identity:

```text
BehaviorBinding identity
  × component-instance scope
  × stable repeated-item identity where applicable
  = RuntimeInstance scope
```

For repeated collections, one binding may create one runtime instance per rendered item. If state must survive reorder, each item needs a stable caller-provided key. An array index alone is not durable identity for a reorderable collection. If no stable identity exists, state preservation across reorder is unsupported and must be diagnosed.

Targets are typed document-local references, never arbitrary CSS selectors, source IDs, HTML strings, or URL fragments. Runtime-generated DOM IDs must be unique within the document and derived from safe instance scope. A collision prevents mounting the affected binding and is diagnosed.

## 8. Shared lifecycle contract

The semantic lifecycle describes behavior states. Runtime lifecycle is separate:

```text
no instance --mount--> mounted --valid--> active --destroy--> destroyed
mounted --invalid--> unavailable --cleanup--> destroyed
active --invalid update--> unavailable --cleanup--> destroyed
```

`unmounted` means no `RuntimeInstance` exists; it is not an instance state. Mount creates the instance in `mounted`. Successful target and policy validation permits `active`. Missing targets, duplicate IDs, invalid state, or unsupported capability at mount or update lead to `unavailable` with cleanup. `destroyed` is terminal. Reconnection or a LiveView patch does not create a second active instance for the same scope.

Every implementation must define mount, post-patch reconciliation, disconnect/reconnect behavior where relevant, and destruction. Cleanup releases all resources owned by that instance: event listeners, timers, observers, drag/pointer capture, media/autoplay control, focus ownership, and scroll-lock ownership. Shared resources use scoped ownership/reference counting so destroying one instance cannot unlock or stop a different active instance.

Prefer native HTML and CSS where they satisfy the semantic contract. A hook is required only when browser lifecycle, DOM reconciliation, or native platform support requires it. `phx-update="ignore"` is not a general state-retention mechanism.

## 9. Primitive state models

Each model below defines state, initial state, transitions, guards, effects, invalid transitions, terminal behavior, and cleanup. The state models describe semantics. Animation phases and browser handles remain runtime details unless they change valid semantic transitions.

Every primitive inherits `RuntimeInstance.destroyed` as its terminal state and the resource-release rules in §8. Primitive-specific destruction effects below add to that shared cleanup contract.

### 9.1 Disclosure / Toggle

**State:** `closed | open`. `enabled` is a guard/policy dimension, not a third lifecycle state. Runtime lifecycle follows §8.

**Initial state:** source-independent normalization must use explicit accepted initial state; if absent, `closed`. Native `<details>/<summary>` is the preferred realization when the content is a disclosure and native semantics meet the contract.

Keyboard: a native `<summary>` uses its platform disclosure activation. A custom disclosure control supports `Enter` and `Space` activation. Neither form adds arrow-key behavior.

| Transition | Trigger and guard | Effects |
| --- | --- | --- |
| `closed → open` | Activate trigger; enabled and one content target resolves | Reveal target; set native `open` or synchronized expanded state; retain focus on trigger unless a separate policy says otherwise. |
| `open → closed` | Activate trigger; enabled | Conceal target; synchronize collapsed state; if focus is inside content that will be hidden, return focus to the trigger first. |

Invalid transitions: disabled activation is a no-op; duplicate/missing target or mismatched exposed state rejects the binding. Terminal state is `RuntimeInstance.destroyed`, never a third disclosure state. Cleanup removes only runtime resources this binding owns. Native platform state must reconcile after a server patch without duplicate listeners.

### 9.2 Accordion

**State:** `open_item_ids`, a set constrained by configuration. Independent policy dimensions are `mode=single|multiple`, `closure=allow_all_closed|require_one_open`, and per-item `enabled`. The item set has stable typed IDs. Nested accordions have separate ownership and state.

**Initial state:** explicit valid source-neutral state, otherwise empty for `allow_all_closed`; for `require_one_open`, the first enabled item in normalized order. If none is enabled, validation fails.

Keyboard: `Enter` and `Space` on an enabled item control toggle its panel. `Tab` and `Shift+Tab` follow the document tab order; the accordion does not trap focus.

Transitions use item activation. Opening an enabled item in `single` mode atomically replaces the open set; in `multiple` mode it adds the item. Closing removes it only if `allow_all_closed`, or if another enabled item remains under `require_one_open`. Disabled items cannot transition. Invariants are `single ⇒ |open_item_ids| ≤ 1` and `require_one_open ⇒ |open_item_ids| ≥ 1`.

Effects reveal/conceal each associated panel and synchronize each control's expanded state. Focus remains on the activated control. An attempted transition that violates an invariant is a no-op; malformed IDs, duplicate items, or missing panels invalidate the binding. Cleanup is per owned runtime instance and must not disturb nested accordion state.

Destruction ends the runtime instance and removes its listeners without changing another accordion's state.

Prefer native `<details>` groups where the required semantics match. HTML's `details[name]` supplies exclusive grouping, but it does not by itself prove every accordion heading/region requirement; validate the requested contract before choosing it.

### 9.3 Tabs

**State:** `selected_tab_id` and `focused_tab_id` are separate dimensions. Configuration is `activation=manual|automatic`, `orientation=horizontal|vertical`, plus an ordered tab set and disabled-tab guards. Each tab has exactly one associated panel.

**Initial state:** first enabled tab unless an explicit valid initial selection exists. Focus initially follows the selected tab when focus enters the tablist.

Focus movement updates only `focused_tab_id` under manual activation. Under automatic activation, focus movement also selects the focused enabled tab. `Enter` or `Space` selects the focused tab under manual activation. Horizontal lists use Left/Right; vertical lists use Up/Down; Home/End may move focus to first/last enabled tabs. Wrapping is allowed. Disabled tabs are skipped and cannot be selected. Tab/Shift+Tab leave the composite according to normal page order.

Selection effects show only the selected panel, synchronize selected state, tab-to-panel relationships, and roving tab stop. Focus effects move focus only as required by the keyboard policy. If selected/focused IDs disappear in an update, reconciliation selects the first enabled tab and sets focus to selected only when focus was owned by the tablist; otherwise it preserves external focus. Empty/all-disabled sets are invalid. Cleanup releases owned listeners and transient focus references.

Manual activation is the safe default when panels may load or update with noticeable latency. APG recommends automatic activation only when panel content appears without noticeable latency.

Destruction ends the runtime instance and releases its keyboard listeners and any focus references it owns.

#### Responsive Tabs → Accordion

This is a semantic mode transition, not a style override. The `ResponsiveBehaviorOverride` must cite accepted breakpoint authority and provide a reversible mapping. The initial mapping carries the selected tab into the one open accordion item; reverse mapping selects that same item. The first-wave rule keeps one canonical selected/open item in both modes. Multi-open accordion state cannot be losslessly mapped to single-selection tabs and is rejected for this conversion unless a future authority defines reconciliation.

When mode changes, keep semantic selection stable, move focus only if the focused control is removed, and preserve keyboard position by mapping to the corresponding control. Without known breakpoint authority, do not infer the mode change from arbitrary viewport thresholds.

### 9.4 Disclosure Popup / Dropdown

This primitive represents content revealed from a trigger, including ordinary site navigation dropdowns. It does not imply `menu` semantics.

**State:** `closed | open`, initial `closed` unless explicit accepted state says otherwise. `enabled`, pointer-hover availability, and dismiss policy are guard/policy dimensions.

`Enter` and `Space` on the trigger activate the disclosure; pointer activation may use the same transition. Escape closes and returns focus to the trigger when focus was in the popup. Outside activation may close only when that policy is explicitly accepted and the trigger/target relationship is scoped. Pointer leave may close only when the source semantics and usable pointer/focus treatment are established; hover alone cannot be the only way to access content. Tab navigation follows ordinary document order and does not trap focus. Focus entering the popup keeps it open; focus leaving its owner scope may close it if policy says so.

Effects reveal/conceal content and synchronize expanded state. Links remain native links. Invalid trigger/target or a popup that requires unsupported placement/ownership behavior is diagnosed; no selector search is attempted. Destroy closes the popup and releases owned listeners.

### 9.5 Menu Button / Menu

Use this primitive only for an actual command menu with menu-item semantics and composite keyboard navigation. Navigation links in a website dropdown remain a Disclosure Popup unless evidence establishes application-menu behavior.

**State dimensions:** `open=closed|open`; when open, `focused_item_id` is one enabled/focusable item or `nil` before focus entry. Disabled menu items may remain focusable according to the accepted menu policy but cannot activate. Submenus have separately owned menu bindings.

**Initial state:** closed. Activation of the menu button opens and moves focus to the first enabled item. Down/Up moves through items with defined wrapping; Home/End moves to first/last; printable-character search may be supported only as an explicit policy. Enter activates or opens a submenu; Space behavior follows item type. Escape closes the active menu level and returns focus to its invoker. Tab/Shift+Tab leave the menu and close it. An item activation closes the menu unless it opens a submenu or the item type defines a persistent checked-state change.

Effects synchronize expanded state on the button, menu visibility, focused item, and any checked/selected item state. Focus is not trapped. Missing invoker, invalid item role/relationship, or unknown command type prevents menu semantics from being generated. Cleanup closes owned levels and restores focus only when the invoker still exists and remains in scope.

### 9.6 Dialog / Modal

**Semantic state:** `closed | open`. `opening` and `closing` are presentation phases only unless an approved runtime contract proves they alter valid transitions. Nested dialogs form an owner stack; only the top modal owns active focus and dismissal.

**Initial state:** closed. Open requires an explicit trigger or platform event and one valid dialog target. Initial focus follows a `FocusPolicy`: usually the first appropriate focusable element, or a static title/content anchor for long structured content. The contract defines return-focus destination.

`closed → open` moves focus into the dialog, makes background content inert, acquires scoped scroll-lock ownership if needed, and records the invoking element. While open, Tab/Shift+Tab remain within the modal, Escape closes unless an explicit accepted policy forbids it, and background interaction is unavailable. `open → closed` releases inertness and owned scroll lock, removes the dialog, and returns focus to the invoker if it still exists; otherwise it chooses an explicit logical fallback. Nested open pushes the stack; close affects only the top dialog.

Semantic modal state is invalid if `aria-modal` or equivalent claims modality while background content remains operable. Missing label, focus destination, backdrop/close policy, or target rejects modal generation. Destroying the instance forcibly releases all owned inertness, scroll lock, listeners, and focus state. Native `<dialog>` is preferred when it satisfies these rules and the supported browser baseline.

### 9.7 Carousel

Do not combine playback, transition, drag, and destruction into one enum. Model orthogonal dimensions:

```text
lifecycle: active | destroyed
active_slide: stable slide ID
rotation: manual | playing | paused
movement: idle | transitioning | dragging
```

Additional policy dimensions include loop mode, autoplay permission, pause reasons, user-stop latch, and reduced-motion preference. Initial state is first valid slide, `rotation=manual` unless explicitly approved autoplay policy exists, and `movement=idle`.

Keyboard: native previous, next, picker, and rotation buttons use `Enter` and `Space`. They follow ordinary tab order; focus stays on the control after activation. Arrow-key navigation is only present when a separately defined tabs picker policy applies. Previous/next/jump transitions update `active_slide`; at a non-loop boundary they are no-ops. Movement may pass `idle → transitioning → idle`, or `idle → dragging → transitioning/idle`; drag cancellation returns to the original or nearest valid slide according to explicit policy. Destroy is terminal and stops timers, drag capture, observers, and media control.

Autoplay may start only with an explicit timer policy and accessible rotation control. Focus entering or pointer hover pauses rotation. After a user or focus stop, rotation does not resume automatically; explicit activation of the rotation control is required. Reduced-motion preference disables autoplay by default and removes or shortens non-essential movement. Manual slide navigation remains available. Effects update the active slide, control state/labels, slide exposure, and any selected picker state together.

Missing stable slide IDs, invalid active slide, unbounded timing, or unavailable pause/resume semantics rejects autoplay; the carousel may still be emitted as a static sequence with a diagnostic. Cleanup cancels every timer and pending movement operation.

### 9.8 Lightbox

Lightbox composes **Dialog + CollectionNavigation**; it is not a separate focus-management system.

**State:** `closed | open(active_item_id)`. Initial state is closed. Open requires a valid collection item and dialog binding. Next, previous, and jump change the active item only within that collection. At collection boundaries, behavior follows explicit `clamp | wrap` policy; absent policy defaults to clamp. Escape/close follows Dialog. It inherits Dialog initial focus, containment, return focus, inertness, nested ownership, and cleanup rules.

Keyboard: Escape, Tab, and Shift+Tab follow the inherited Dialog policy. Native previous, next, and item-picker buttons use Enter/Space; focus remains on the activated control. Arrow keys are optional and require an explicit collection-navigation policy.

The underlying media or a normal media link remains available without the lightbox runtime. Collection changes that remove the active item close the lightbox and restore focus to its originating control if present. Missing item relationship, dialog semantics, or label rejects the composed behavior. History/deep-link behavior is optional and must never be inferred from a source widget name or DOM ID.

Destruction ends the runtime instance and releases the composed Dialog and collection-navigation resources.

## 10. Accessibility, keyboard, and motion authority

Accessibility state is part of semantic transitions, not a later decoration. When a transition changes visibility, selection, expansion, modality, or active slide, the realization updates the matching native state or ARIA state in the same transition. It must not report a completed transition while DOM visibility, focus, and exposed state disagree.

Use semantic HTML first. Add ARIA only where required to express a relationship or widget contract that native HTML does not provide. WAI-ARIA 1.2 defines roles, states, and properties; adding roles does not supply widget behavior. APG provides recommended keyboard and widget patterns, not normative requirements. Where this authority adopts an APG pattern, it is an explicit LiveFrames decision and remains subject to browser and assistive-technology verification.

Keyboard behavior is explicit per primitive. Do not add global key handlers. Escape handling, roving focus, tab activation, and focus restoration are scoped to the owning binding. A disabled guard blocks activation; focusability behavior is primitive-specific and must not be guessed from a source attribute.

`MotionPolicy` treats `prefers-reduced-motion` as a user preference input, not a semantic state. Reduced motion suppresses non-essential animation and autoplay; it does not remove required controls or content. A timer is never required for comprehension or access to essential content.

## 11. Runtime ownership and state placement

Each binding is classified as `CLIENT_LOCAL`, `SERVER_AUTHORITATIVE`, or `HYBRID`:

| Primitive | Default owner | Reason to change default |
| --- | --- | --- |
| Disclosure / Toggle | `CLIENT_LOCAL` | Only if activation changes server-owned application data. |
| Accordion | `CLIENT_LOCAL` | Only if open state itself is domain state or server output depends on it. |
| Tabs | `CLIENT_LOCAL` | Only if selection loads or mutates server-authoritative content. |
| Disclosure Popup | `CLIENT_LOCAL` | Only if opening triggers a server workflow. |
| Menu Button / Menu | `CLIENT_LOCAL` | A command may separately invoke a server event; focus/menu state remains local. |
| Dialog / Modal | `CLIENT_LOCAL` | Form submission or server workflow may be hybrid; open/focus state stays local by default. |
| Carousel | `CLIENT_LOCAL` | Only if slide changes mutate domain state. |
| Lightbox | `CLIENT_LOCAL` | Only if the application explicitly stores viewing state. |

Purely local presentation state requires no server round trip, polling, Redis write, Postgres write, GenServer, or per-user server process. Its cache, Redis structure, database index, and PubSub requirement are all `N/A`. Server ownership is used only when application/domain data requires it. Server-driven updates use LiveView push/update mechanisms, not polling.

## 12. LiveView DOM lifecycle and reconciliation

For the repository's Phoenix LiveView 1.2.11 baseline, a future hook-backed realization must use the lifecycle callbacks documented for that pinned release, not assume behavior from a newer version. Conceptually:

1. **Mount:** validate binding identity, targets, and unique IDs; attach only scoped resources; initialize from valid server-rendered semantic state.
2. **Server DOM patch:** allow LiveView to own server markup. Do not replace patched DOM with stale cached HTML.
3. **Post-patch reconciliation:** re-resolve only typed owned targets, reconcile changed node membership and values, preserve valid client-local state where the contract permits, and update ARIA/native state without duplicating listeners.
4. **Disconnect/reconnect:** pause timers and transient work when a disconnected client must not continue; on reconnect reconcile from current server markup and policy before resuming.
5. **Destruction:** cancel timers, disconnect observers, remove listeners, release pointer capture, media/autoplay, focus and scroll-lock ownership, and discard DOM references.

Pure HTML/CSS/native behavior needs no hook when it already satisfies these rules. Never use a hook solely because the source used JavaScript.

## 13. Progressive enhancement and unsupported behavior

The server-rendered or no-JS form must retain meaningful content and ordinary links. When a runtime is missing or unsupported, behavior fails closed and `BehaviorDiagnostic` preserves the reason. Do not emit fake interactive semantics or copy source JavaScript.

| Primitive | No-JS or unsupported-runtime outcome |
| --- | --- |
| Disclosure | Prefer native `<details>/<summary>` when compatible. Otherwise keep the content reachable. |
| Accordion | Use native disclosures when their group semantics match; otherwise render reachable sections. |
| Tabs | Render all panel content reachable; do not leave essential content permanently hidden. |
| Disclosure Popup navigation | Keep navigation links usable in normal document flow. |
| Menu Button / Menu | Do not claim menu roles without its keyboard/focus behavior; render a usable list of actions/links. |
| Dialog | Essential content/action has a usable inline or non-modal fallback. |
| Carousel | Render a readable static sequence; autoplay is off. |
| Lightbox | Keep media visible or provide a normal link to the media. |

## 14. Security contract

All imported JSON, HTML, CSS, JavaScript, PHP, selectors, and paths are untrusted data. Behavior normalization must not execute or evaluate them. It must not emit `eval`, dynamic function construction, source module/function names, source event names, arbitrary CSS selectors, cross-component selector traversal, arbitrary attribute mutation, HTML injection, unvalidated navigation URLs, or source-defined code.

Triggers, target roles, states, guards, effects, key mappings, and mutations use a closed normalized vocabulary. Text and labels remain escaped data. Navigation URLs pass an explicit closed validation policy before emission. Runtime-generated IDs are unique and scoped. Focus cannot leave the binding's permitted ownership scope except through its explicit focus policy. Timers, listeners, observers, drag handlers, and scroll locks have bounded ownership and mandatory cleanup.

If source behavior cannot be represented safely, preserve its evidence and emit a `BehaviorDiagnostic`. Do not approximate it with broader selectors or invented semantics.

## 15. Performance and scaling

| Primitive | Server round trip / polling / per-widget server process | Local-state and large-collection rule | 100,000 connected clients |
| --- | --- | --- | --- |
| Disclosure | None by default | Native state; no cache/Redis/database/PubSub. | No per-client server state is allocated for the interaction. |
| Accordion | None by default | State only for rendered group; lazy-init only when it preserves initial semantics. | Same local rule; server cost follows rendered page updates, not open-state changes. |
| Tabs | None by default | Store selected/focused IDs for mounted set; do not eagerly initialize offscreen unrelated widgets. | No polling or server process per tab set. |
| Disclosure Popup | None by default | Keep listeners scoped to mounted owner; use CSS/native disclosure where sufficient. | No persistent service or storage requirement. |
| Menu Button / Menu | None for menu/focus; command may be server-owned | Initialize only the rendered menu; keyboard navigation is local. | No per-menu process; server work only for actual commands. |
| Dialog / Modal | None for open/close | One scoped stack for nested dialogs; share no global state without ownership. | No per-dialog backend process; lock/focus bookkeeping is browser-local. |
| Carousel | None for manual movement; autoplay uses one bounded client timer | Lazy-init large collections and destroy offscreen instances only if state contract allows it. | No polling or Redis; timer work exists only in clients that render autoplay-enabled carousels. |
| Lightbox | None for navigation | Reuse the owning dialog and collection binding; do not copy all media into client state. | No per-view server process; network/media cost is separate from behavior state. |

Browser-local interaction state does not become a cache layer merely because it is temporary. Server rendering cost, asset delivery, and media transfer remain separate capacity questions. Do not design infrastructure for state that never leaves the browser.

## 16. Private Frames evidence boundary

Private Frames exports and extracted source are read-only, untrusted evidence. Permitted inspection is limited to safe text/file listing, hashing, and search. Never execute, evaluate, import, run embedded scripts, or copy proprietary implementation. Never add a vendor runtime or make the reusable library depend on WordPress, ACSS, Bricks, Frames, Splide, or private material.

C-07X records these corpus identities:

| Evidence set | Records | SHA-256 |
| --- | ---: | --- |
| `private_reference/frames/frames-components/` extracted Frames component corpus | 43 | `630332dcedf3807064affcbe22cfed9d16859fdd771b815a8b06d4960774de9e` |
| `private_reference/frames/staging-2026-09/` export corpus, archive excluded | 34 | `074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e` |

The C-09A authority explicitly marks the extracted component corpus as drifted and prohibited for its Bricks 2.3.1 query conclusions. Here it is only a semantic clue, not source authority. The staging export hash and the C-07X observations are the accepted source evidence for the named examples. Hashes establish corpus identity, not license or redistribution permission.

## 17. Evidence ledger

Each record uses the same fields. `STATE` means `observed`, `verified`, `accepted`, `conflicted`, or `superseded`. Evidence statements do not grant source permission.

### Repository and architecture records

| EVIDENCE_ID | CLAIM | STATE | SOURCE_TYPE | SOURCE | SOURCE_SHA_OR_VERSION | RELEVANT_COMPONENTS | OBSERVATION | DECISION | DOWNSTREAM_CONSUMERS | INVALIDATION_TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `BEH-R001` | Design IR Interaction is intent-only. | verified | REPOSITORY_EVIDENCE | `docs/03_DESIGN_IR_SPEC.md`, `apps/live_frames/lib/live_frames/ir/interaction.ex` | Design IR `3.0.0`; repository base `3b18f94bb0ca960a4dcb6af441776addb8109b7a` | Interaction, DesignDocument | Current fields carry intent, trigger, node targets, parameters, and trace; specification leaves runtime strategy undecided. | Keep Design IR 3.x meaning unchanged. | Behavior normalization, validation, generator | Accepted Design IR version migration. |
| `BEH-R002` | Bricks behavior is not normalized into the current IR. | verified | REPOSITORY_EVIDENCE | `apps/live_frames/lib/live_frames/adapters/bricks/design_ir_normalizer.ex` | repository base `3b18f94bb0ca960a4dcb6af441776addb8109b7a` | Bricks adapter | Normalizer constructs `interactions: %{}` and nodes with `interaction_refs: []`. | A separate behavior evidence/normalization path is required. | Bricks adapter, BehaviorContract | Adapter implementation changes and passes review. |
| `BEH-R003` | A shared behavior/runtime path is a known gap. | accepted | REPOSITORY_EVIDENCE | `docs/development/c07x_unsupported_surface_inventory.md` | repository base `3b18f94bb0ca960a4dcb6af441776addb8109b7a`; C-07X corpus hashes above | Frames widget behavior, LiveFrames runtime | Audit identifies missing behavior/runtime translation and classifies relevant families unsupported or partial. | Resolve through this contract before interactive component admission. | Behavior normalizer, runtime, Catalogue | Accepted replacement audit supersedes C-07X. |
| `BEH-R004` | C09D6 defers Behavior IR and interactive generation. | verified | REPOSITORY_EVIDENCE | `docs/development/c09d6_native_generation_authority.md` | repository base `3b18f94bb0ca960a4dcb6af441776addb8109b7a` | Native generation | Explicit non-goal: Behavior IR or interactive component generation. | Keep behavior implementation separate and downstream of this authority. | Native generator, roadmap | C09D6 authority is formally amended. |
| `BEH-R005` | Source provenance and clean-room boundaries prohibit private runtime coupling. | accepted | REPOSITORY_EVIDENCE | `AGENTS.md`, `docs/04_SOURCE_AND_PROVENANCE.md` | repository base `3b18f94bb0ca960a4dcb6af441776addb8109b7a` | Private references, adapters, release | Private/vendor code is untrusted and is not a runtime dependency; redistribution remains separately governed. | Store semantics and provenance only; never vendor code. | All adapters and generators | Provenance authority is amended. |

### Private example records

For each example, `SOURCE` is the corresponding folder in the 34-record staging corpus plus C-07X's source/export evidence table. `SOURCE_SHA_OR_VERSION` is `staging-2026-09 corpus: 074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e`; the C-07X component corpus digest is not treated as accepted implementation authority. The private extracted files were inspected only for semantic clues.

| EVIDENCE_ID | CLAIM | STATE | SOURCE_TYPE | SOURCE | SOURCE_SHA_OR_VERSION | RELEVANT_COMPONENTS | OBSERVATION | DECISION | DOWNSTREAM_CONSUMERS | INVALIDATION_TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `BEH-P001` | Pricing Echo indicates tabs with responsive accordion mode. | observed | PRIVATE_REFERENCE | staging export `pricing-echo/`; C-07X Pricing Echo record | staging-2026-09 corpus digest above | Tabs, panels, responsive cards | Export records monthly/yearly tabs and accordion-on-device settings; it does not prove focus or keyboard behavior. | Model tabs and accordion separately; require reversible semantic mapping and breakpoint authority. | Source normalizer, tabs, accordion | New admitted export or verified browser evidence changes semantics. |
| `BEH-P002` | Slide Menu Alpha indicates native disclosure groups and reduced-motion styling. | observed | PRIVATE_REFERENCE | staging export `slide-menu-alpha/`; C-07X Slide Menu Alpha record | staging-2026-09 corpus digest above | Disclosure, navigation | Export/audit records `details`/`summary`, current-page link behavior, disclosure transitions, and reduced-motion rules. | Prefer native disclosure; keep navigation links usable. | Disclosure normalizer, native renderer | New export evidence or platform behavior invalidates this observation. |
| `BEH-P003` | Slider Basel indicates carousel controls and rotation configuration. | observed | PRIVATE_REFERENCE | staging export `slider-section-basel/`; C-07X Slider Basel record | staging-2026-09 corpus digest above | Carousel | Export/audit records loop, arrows, play/pause, slide source, and responsive layout. It does not establish safe runtime or full accessibility behavior. | Use orthogonal carousel state and APG-informed stop/resume rules; do not depend on Splide. | Carousel normalizer/runtime | New export or browser evidence changes observed controls. |
| `BEH-P004` | Gallery Bravo indicates gallery/lightbox composition. | observed | PRIVATE_REFERENCE | staging export `gallery-bravo/`; C-07X Gallery Bravo record | staging-2026-09 corpus digest above | Lightbox, collection | Export/audit records gallery collection and lightbox link settings/capture, not complete focus, Escape, or history behavior. | Model as Dialog plus collection navigation; history is opt-in only. | Gallery normalizer, dialog, lightbox | New source evidence proves a different interaction model. |
| `BEH-P005` | Header Basel indicates nested navigation and dropdown/trigger evidence. | observed | PRIVATE_REFERENCE | staging export `header-basel/`; C-07X Header Basel record | staging-2026-09 corpus digest above | Disclosure Popup, Menu Button | Export/audit records nested navigation, dropdowns, and a trigger widget; it does not prove application-menu semantics. | Default website navigation to disclosure semantics; require evidence for Menu. | Navigation adapter, popup, menu | Verified keyboard/DOM evidence establishes a different primitive. |
| `BEH-P006` | Feature Milan indicates timed active-item rotation and interaction stopping. | observed | PRIVATE_REFERENCE | staging export `feature-section-milan/`; C-07X Feature Milan record | staging-2026-09 corpus digest above | Tabs, carousel-like rotation, TimerPolicy | Export/audit records tab-like ARIA markup, separate media groups, and interval-based active-item changes; it does not prove proper tab relations or cleanup. | Timed changes require explicit TimerPolicy, pause rules, reduced-motion policy, and diagnostics where relations are incomplete. | Tabs, timer validation, runtime | New admitted source or browser observation changes behavior facts. |

### External standards and platform records

| EVIDENCE_ID | CLAIM | STATE | SOURCE_TYPE | SOURCE | SOURCE_SHA_OR_VERSION | RELEVANT_COMPONENTS | OBSERVATION | DECISION | DOWNSTREAM_CONSUMERS | INVALIDATION_TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `BEH-S001` | Disclosure and accordion interaction guidance. | verified | EXTERNAL_STANDARD | [APG Disclosure](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/), [APG Accordion](https://www.w3.org/WAI/ARIA/apg/patterns/accordion/) | APG pages checked 2026-10-09; guidance, not normative WAI-ARIA text | Disclosure, Accordion | APG describes activation, expanded state, accordion heading/panel relationships, and permitted collapse variations. | Adopt the stated semantics as LiveFrames policy; validate native HTML alternatives. | Disclosure, Accordion | APG guidance changes or implementation testing finds incompatibility. |
| `BEH-S002` | Tabs distinguish focus from selection and manual from automatic activation. | verified | EXTERNAL_STANDARD | [APG Tabs](https://www.w3.org/WAI/ARIA/apg/patterns/tabs/) | APG pages checked 2026-10-09; guidance | Tabs | Arrow keys move focus; activation policy determines whether selection follows; latency affects automatic-activation suitability. | Keep `focused_tab_id` and `selected_tab_id` distinct. | Tabs, keyboard policy | APG guidance or browser/AT verification changes the accepted policy. |
| `BEH-S003` | Menu semantics include composite keyboard/focus behavior and differ from disclosure navigation. | verified | EXTERNAL_STANDARD | [APG Menu Button](https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/), [APG Menu and Menubar](https://www.w3.org/WAI/ARIA/apg/patterns/menubar/), [APG Disclosure Navigation](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/) | APG pages checked 2026-10-09; guidance | Menu, Disclosure Popup | APG menu pattern models command choices and managed focus; disclosure navigation uses disclosure controls and ordinary links. | Do not label every dropdown a menu. | Menu, navigation | APG guidance or verification changes the primitive decision. |
| `BEH-S004` | A modal dialog contains focus and makes background content inert. | verified | EXTERNAL_STANDARD | [APG Modal Dialog](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/) | APG page checked 2026-10-09; guidance | Dialog, Lightbox | APG covers initial focus, containment, Escape, return focus, and actual modality. | `aria-modal` cannot substitute for modal behavior. | Dialog, Lightbox | APG guidance or native platform verification changes the implementation contract. |
| `BEH-S005` | Auto-rotating carousels need controls and stop/resume rules. | verified | EXTERNAL_STANDARD | [APG Carousel](https://www.w3.org/WAI/ARIA/apg/patterns/carousel/) | APG page checked 2026-10-09; guidance | Carousel, TimerPolicy | APG recommends a rotation control, stop on focus/hover, and no automatic resume after focus enters. | Autoplay is opt-in; user/focus stop requires explicit restart. | Carousel runtime | APG guidance or accessibility verification changes policy. |
| `BEH-S006` | HTML `details` is a disclosure primitive and supports exclusive named groups. | verified | EXTERNAL_STANDARD | [WHATWG HTML Living Standard, `details`](https://html.spec.whatwg.org/multipage/interactive-elements.html#the-details-element) | Living Standard accessed 2026-10-09 | Disclosure, Accordion | Native open/close behavior and `name` grouping exist; the standard says not to use details to represent tabs or menus. | Prefer it only when the requested semantics are disclosure-compatible. | Native renderer | HTML standard or supported browser baseline changes. |
| `BEH-S007` | Reduced-motion is a user preference signal for reducing non-essential motion. | verified | EXTERNAL_STANDARD | [CSS Media Queries Level 5](https://www.w3.org/TR/mediaqueries-5/#prefers-reduced-motion), [MDN `prefers-reduced-motion`](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/prefers-reduced-motion) | CSS Media Queries Level 5; MDN accessed 2026-10-09 | MotionPolicy, Carousel, Disclosure | The media feature represents a device/user preference and can reduce or replace motion. | Treat as policy input; turn off autoplay by default when reduced motion is requested. | CSS/runtime motion policy | Media Queries specification or browser support changes. |
| `BEH-S008` | LiveView hook lifecycle must match the pinned 1.2.11 runtime. | verified | EXTERNAL_STANDARD | [Phoenix LiveView JavaScript interoperability](https://hexdocs.pm/phoenix_live_view/1.2.11/js-interop.html) | repository lockfile `phoenix_live_view 1.2.11`; docs target 1.2.11 | Hook mount/update/disconnect/reconnect/destroy | Version 1.2.11 documents `mounted`, `beforeUpdate`, `updated`, `destroyed`, `disconnected`, and `reconnected`. `destroyed` runs when a parent update removes the hooked element or the parent is removed. | Reconcile on updates and release resources on destruction using these release-specific callbacks. | Hook-backed runtime | Lockfile update or 1.2.11 docs/API change. |
| `BEH-S009` | WAI-ARIA defines roles/states/properties; APG is authoring guidance. | verified | EXTERNAL_STANDARD | [WAI-ARIA 1.2 Recommendation](https://www.w3.org/TR/wai-aria-1.2/), [W3C ARIA overview](https://www.w3.org/WAI/standards-guidelines/aria/) | WAI-ARIA 1.2 Recommendation 2023-06-06; overview accessed 2026-10-09 | All primitives | WAI-ARIA is normative specification text; W3C describes APG as recommendations for authors. Roles do not implement behavior. | Keep specification requirements and adopted APG guidance visibly distinct. | All accessibility contracts | W3C publishes a new ARIA version or updates APG status. |

## 18. Future implementation boundaries and sequence

Recommended namespace only; do not create these modules in this authority slice:

```text
LiveFrames.Behavior
LiveFrames.Behavior.Contract
LiveFrames.Behavior.Binding
LiveFrames.Behavior.StateModel
LiveFrames.Behavior.Validation
LiveFrames.Behavior.Diagnostic

LiveFrames.Behavior.Primitives.Disclosure
LiveFrames.Behavior.Primitives.Accordion
LiveFrames.Behavior.Primitives.Tabs
LiveFrames.Behavior.Primitives.Menu
LiveFrames.Behavior.Primitives.Dialog
LiveFrames.Behavior.Primitives.Carousel
LiveFrames.Behavior.Primitives.Lightbox
```

Do not name native-domain modules after Frames, Bricks, Splide, or another input/runtime vendor. Source-specific extraction belongs in adapters and evidence, not the native behavior vocabulary.

The backward dependency sequence is:

```text
safe behavior evidence
→ source-neutral normalization
→ BehaviorContract
→ validation and review
→ native generation
→ semantic HEEx
→ minimal runtime where required
→ lifecycle cleanup
→ accessibility and browser verification
→ Catalogue admission
→ consumer ejection without Frames
```

The first proofs should be:

1. **Disclosure / Slide Menu Alpha:** validate native `details`/`summary`, usable links, reduced-motion behavior, and the absence of unnecessary JavaScript.
2. **Tabs:** prove separate focused/selected state, keyboard policy, client runtime, LiveView patch reconciliation, and destruction cleanup.
3. **Accordion and responsive tabs/accordion:** prove state mapping is reversible and obeys `single|multiple` and closure policy.
4. **Disclosure Popup vs Menu:** prove classification follows semantics and keyboard behavior.
5. **Dialog:** prove modality, focus ownership, nesting, and cleanup.
6. **Carousel:** prove orthogonal state, autoplay controls, pause/resume, and reduced motion.
7. **Lightbox:** prove Dialog composition and collection navigation.

## 19. Open decisions and stop conditions

These decisions remain downstream and do not block this source-neutral contract: the exact BehaviorContract serialization/digest algorithm; supported browser matrix; responsive breakpoint authority; whether future Design IR should reference or absorb BehaviorContract; optional lightbox history behavior; and any third-party carousel dependency. Splide is not a domain dependency.

Stop future implementation and escalate rather than guess if any of these occur:

```text
STOP=MAIN_MOVED
STOP=EXISTING_AUTHORITY_CONFLICT
STOP=BEHAVIOR_DOMAIN_INSUFFICIENTLY_DEFINED
STOP=ACCESSIBILITY_CONTRACT_UNRESOLVED
STOP=RUNTIME_BOUNDARY_UNRESOLVED
STOP=EXTERNAL_DEPENDENCY_DECISION_REQUIRED
STOP=IMPLEMENTATION_REQUIRED_TO_PROVE_ARCHITECTURE
```

No stop condition is active for this documentation slice. Implementation must stop if a required primitive cannot meet its declared accessibility behavior, if a target cannot be resolved safely, or if platform/runtime ownership is ambiguous. Do not resolve a stop by changing production code in an authority-only phase.

## 20. Acceptance criteria and scope confirmation

This authority is ready for independent review when it defines the versioned artifact and Design IR relationship; records domain ownership, cardinality, references, invariants, and failure behavior; specifies lifecycle transitions for every required primitive; distinguishes native semantics, ARIA specification, and APG guidance; defines identity, runtime ownership, LiveView reconciliation, no-JS behavior, security, performance, and cleanup; and includes evidence records with invalidation triggers.

This authority changes no Design IR schema, Elixir implementation, JavaScript, CSS, hook, generator, Catalogue runtime, dependency, roadmap, or private source. Its canonical owner is this file: `docs/09_INTERACTION_MODEL.md`.
