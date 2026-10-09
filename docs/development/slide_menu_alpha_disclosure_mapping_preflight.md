# Slide Menu Alpha Disclosure to BehaviorContract mapping preflight

## 1. Purpose and non-goals

This preflight maps accepted Slide Menu Alpha observations to the accepted Disclosure semantics in `docs/09_INTERACTION_MODEL.md`. It separates supported source-neutral meaning from unresolved source details and target realization decisions.

This document does not implement Disclosure or BehaviorContract. It does not define a hook, markup renderer, CSS, Design IR field, component struct, navigation data API, current-page detector, or Accordion policy. It makes no new claim from proprietary implementation bodies and executes no source code.

## 2. Exact accepted base and CI identity

```text
REPOSITORY=JCSchoeman96/LiveFrames
BASE_SHA=ccac7ec157544fceff47eb2cdc959c7095e71a65
BASE_TREE=7bc5400055f7644a03aa6efe4a6532b788d7339c
POST_MERGE_CI=37923655109
POST_MERGE_CI_STATUS=completed
POST_MERGE_CI_CONCLUSION=success
POST_MERGE_CI_HEAD=ccac7ec157544fceff47eb2cdc959c7095e71a65
WORKTREE_CLEAN=YES
```

The branch starts at the exact accepted base above. This preflight is documentation-only.

## 3. Authority chain

- `docs/development/c07x_unsupported_surface_inventory.md` records the accepted historical Slide Menu observations and their evidence limits.
- `docs/development/frames_native_conversion_matrix.md` places Slide Menu Alpha as the Disclosure tracer and leaves nesting, current-page lifecycle, keyboard/ARIA details, transition timing, and cleanup unresolved.
- `docs/09_INTERACTION_MODEL.md` owns the source-neutral BehaviorContract vocabulary, Disclosure state model, native realization preference, runtime lifecycle, client-local default, security, and performance rules.
- `docs/03_DESIGN_IR_SPEC.md` owns Design IR meaning and does not define a Slide Menu current-page input here.
- `docs/04_SOURCE_AND_PROVENANCE.md` owns source-use and provenance boundaries. This document adds no permission or source interpretation.
- `docs/development/c09d1_component_contract_authority.md`, `c09d3_componentization_plan_authority.md`, `c09d5_componentization_proposer_authority.md`, and `c09d6_native_generation_authority.md` retain their respective component boundary, placement, proposer, review, generation, and styling roles. They do not authorize implementation in this preflight.

BehaviorContract governs semantic meaning. Componentization owns native component boundaries. Interactive native generation remains blocked until the BehaviorContract-to-componentization integration is accepted, followed by the existing review and generation gates.

## 4. Accepted Slide Menu facts

The accepted C-07X record establishes that Slide Menu Alpha:

- has a navigation landmark;
- uses native `details`/`summary` disclosure groups, which open and close;
- has current-page link behavior;
- has a script that opens the group containing the current-page link;
- has CSS disclosure transitions; and
- changes transition/interpolation treatment under reduced motion.

These are historical observations accepted for this mapping. They do not authorize copying source classes, selectors, script, or runtime technique.

## 5. Facts not established

Accepted evidence does not establish exclusive one-open behavior, initial state of every group, parent/child coordination, state retention when a parent closes and reopens, current-page identity production, when the containing group opens, route or LiveView update behavior, current-page attributes, exact keyboard/focus behavior, added ARIA mutations, timing/easing values, animation cancellation, source-script cleanup, or a need for a client hook.

Unknowns remain unknown even when native HTML or the BehaviorContract vocabulary can support a possible target design.

## 6. Domain and resource map

```text
Domain:
  Slide Menu navigation disclosure

Entities/concepts:
  DisclosureGroup
  SummaryControl
  DisclosureContent
  NavigationLink
  CurrentPageMarker
  BehaviorBinding
  MotionPolicy

Relationships:
  DisclosureGroup is a stateful occurrence represented by its BehaviorBinding, whose owner node is the group.
  The Disclosure primitive definition owns the closed|open state model.
  SummaryControl is the activation control and typed trigger owned by that binding.
  DisclosureContent is the typed controlled target of the binding, revealed or concealed by its transition effects.
  DisclosureGroup contains navigation descendants
  CurrentPageMarker may identify a descendant link
  containing group may be required open when that relation is accepted

Invariants:
  state is closed|open
  no arbitrary selector targeting
  current-page state does not become a third disclosure state
  native HTML semantics are preferred where sufficient
  reduced-motion changes presentation, not semantic state unless evidence proves otherwise
```

These are conceptual terms only, not code structs. Targets and ownership must resolve through typed, document-local relationships. A source class, selector, or DOM proximity does not establish ownership.

## 7. Disclosure lifecycle

The accepted primitive is Disclosure / Toggle with semantic state `closed | open`. `enabled` is a guard or policy dimension, not a lifecycle state. If there is no explicit accepted initial state, BehaviorContract defaults the state to `closed`. A current-page input may constrain the containing group's initial or reconciled state, but the accepted evidence does not determine when that constraint is applied.

Guards remain pure checks over normalized state, enabled policy, and typed local context. They perform no I/O and do not discover the current page.

| Transition | Trigger or condition | Guard | Effect | Accessibility effect | Invalid or no-op case | Persistence | Cleanup | Runtime owner |
|---|---|---|---|---|---|---|---|---|
| `closed → open` | Summary activation; separately, the accepted current-page condition may require the containing group open | Enabled and the typed content target resolves; current-page effect additionally requires an accepted marker that identifies a descendant link | Reveal content and set native open state; current-page condition has the same `open` result, not a third state | Native details exposes its disclosure state; exact source additions remain unproven. Preserve focus on the summary for activation | Disabled activation is a no-op. Missing, duplicate, or out-of-scope target rejects the binding. Without an accepted current-page input there is no current-page effect to apply | User-activated native state is browser-local while the rendered element exists. Across parent close/reopen or replacement, retention is unknown | No managed resource exists in the native-only realization. A future managed realization follows shared BehaviorContract mount/update/destroy rules | Native browser for the candidate realization; actual source script owner is not inferred |
| `open → closed` | Summary activation | Enabled; no accepted policy says a current-page group must remain open continuously | Conceal content and clear native open state | Native details exposes collapsed state. If focus would be hidden by a managed close, BehaviorContract requires returning focus to the summary; source-specific focus behavior is unknown | Disabled activation is a no-op. Mismatched exposed state or invalid target rejects the binding. Whether a current-page group can be closed by the user is unknown | Same as above; no cross-reopen persistence claim | No managed cleanup for native state. Any future listeners or observers need explicit ownership and cleanup authority | Native browser for the candidate realization; actual source runtime remains unknown |

The current-page fact is an effect condition, not another Disclosure state. The source script proves that the effect existed, not that target code needs a runtime transition. Server-rendered `<details open>` remains a possible realization if an authorized current-page input is available before render.

## 8. Nested-group analysis

C-07X and the matrix establish the presence of disclosure groups and identify nesting as a Slide Menu concern. They do not establish how group states coordinate. Independent native `<details>` can be open simultaneously unless a separate accepted policy constrains them.

```text
CAN_MULTIPLE_GROUPS_BE_OPEN=UNKNOWN
EXCLUSIVE_OPEN_POLICY=NOT_PROVEN
NESTED_PARENT_CHILD_POLICY=UNKNOWN
OPENING_CHILD_OPENS_PARENT=UNKNOWN
CLOSING_PARENT_CLOSES_CHILD_STATE=UNKNOWN
STATE_SURVIVES_REOPEN=UNKNOWN
```

Do not map these groups to the Accordion primitive or choose `single`/`multiple` policy from their count or nesting.

## 9. Current-page semantics

| Part | Classification | Accepted meaning and boundary |
|---|---|---|
| A. Current-page identity | PARTIAL | Evidence records current-page link behavior, but not how a link is identified as current. |
| B. Group-descendant relationship | PARTIAL | The accepted effect refers to the group containing the current-page link. It does not define the target's typed/document-local relationship for a future binding. |
| C. Open effect | ACCEPTED | The containing group is opened when the current-page link is identified. |
| D. Trigger timing | UNKNOWN | The script's existence does not distinguish initialization from a later transition. |
| E. Update lifecycle | UNKNOWN | Route changes, LiveView patches, and updates after mount are not established. |

The supported source-neutral statement is: **if an accepted current-page input identifies a descendant navigation link, the containing disclosure should be open at the point required by the still-unresolved lifecycle authority.** This does not define how that input is produced.

Possible ownership categories remain open:

| Category | Status |
|---|---|
| `caller_data` | Possible, not selected |
| `host_route_context` | Possible, not selected |
| `browser_local` | Possible, not selected |

No repository authority selects among them. Current-page identity needs a separate input/mapping authority before it can enter a binding. LiveFrames does not become a router or backend menu engine.

## 10. Native HTML sufficiency

Conceptually, native `<details><summary>…</summary>…</details>` supports open/closed state, ordinary activation, platform keyboard activation, expanded/collapsed exposure, nested disclosures, and a no-JavaScript baseline. Navigation links inside disclosed content retain ordinary link semantics. Browser behavior supplies focus handling for normal summary activation.

This establishes a sufficient native candidate for the core disclosure lifecycle when the contract needs only the supported native semantics. It does not settle Slide Menu's current-page input/timing, parent-child persistence, exact accessibility additions, or styling values. A hook is not justified by the existence of source JavaScript.

```text
NATIVE_DETAILS_CORE_SUFFICIENCY=SUPPORTED_BY_AUTHORITY
NATIVE_DETAILS_CANDIDATE=YES
```

The overall mapping remains partial because current-page timing, parent/child policy, accessibility details, and style values remain open. The `closed | open` core is supported.

## 11. Accessibility mapping

### Native HTML semantics

`<summary>` provides a native disclosure control and platform activation. `<details>` exposes its open/collapsed state. A visible summary needs an accessible name from its text/content. Links inside disclosure content remain links. Nested details provide separate native disclosure controls.

### LiveFrames additional policy

The source evidence does not establish extra `aria-expanded`, `aria-controls`, focus mutation, custom keyboard handling, or the current-page indicator. Under the native realization, do not add `aria-expanded` or `aria-controls` by default when they duplicate native semantics. Do not invent source ARIA. Keep current-page indication distinct from whether a disclosure is open: the former identifies a navigation destination, the latter exposes group visibility.

The eventual current-page indicator and its accessible meaning require accepted authority. Exact names, focus retention for programmatic opening/closing, hidden descendant behavior beyond native details, and any synchronization policy remain to be verified against the chosen realization.

```text
CURRENT_PAGE_ACCESSIBILITY=EVIDENCE_INSUFFICIENT
```

## 12. Motion and reduced-motion mapping

Accepted evidence proves that disclosure transitions exist and reduced-motion rules change their treatment. This supports `MOTION_PRESENT=YES` and `REDUCED_MOTION_REQUIRED=YES`; it does not establish duration, easing, interpolation values, or cancellation behavior.

Motion is presentation. Reduced-motion preference is an input to `MotionPolicy`, not semantic state. It suppresses or replaces non-essential interpolation while preserving the same open/closed outcome. No animation phase belongs in the Disclosure state machine on current evidence.

```text
MOTION_CHANGES_SEMANTIC_STATE=NO
LIKELY_OWNER=STYLE_MOTION_POLICY
BEHAVIOR_TIMER_POLICY=NOT_INDICATED
STYLE_AUTHORITY_REQUIRED=YES
```

A future style authority must define the target's supported motion values and reduced-motion treatment. It must not infer exact source values from the accepted summary.

## 13. Runtime realization analysis

| Candidate | Requirement it could satisfy | Is that requirement proven? |
|---|---|---|
| `NATIVE_HTML_ONLY` | User activation and open/close semantics with native keyboard and accessibility behavior | Yes for the core Disclosure lifecycle. Current-page input remains unresolved. |
| `SERVER_RENDERED_INITIAL_STATE_PLUS_NATIVE_HTML` | Render the containing group open when accepted current-page context is known before markup | Possible realization only. Input ownership and timing are not accepted. |
| `CLIENT_HOOK` | Reconcile browser-local route changes or DOM updates that must open the group after mount | No. Neither dynamic update requirement nor a lifecycle requiring a hook is proven. |
| `LIVEVIEW_SERVER_EVENT` | Change server-owned domain state or run a server workflow on disclosure activation | No such requirement is established. |

The BehaviorContract authority prefers native HTML/CSS and requires a hook only when browser lifecycle, DOM reconciliation, or native platform support requires it. The source script states an effect; it does not select a target runtime.

```text
HOOK_REQUIRED=NOT_PROVEN
```

## 14. Runtime lifecycle

For native HTML/CSS alone:

```text
RUNTIME_INSTANCE_REQUIRED=NO
LISTENER_CLEANUP=N/A
OBSERVER_CLEANUP=N/A
TIMER_CLEANUP=N/A
```

The source script does not prove a target RuntimeInstance is needed. If later accepted lifecycle requirements require managed updates, the shared BehaviorContract mount, patch reconciliation, and destruction authority applies. This preflight does not redefine it.

## 15. Data and current-page boundary

Slide Menu Alpha does not prove a backend menu query. If current-page identity later comes from the host application, it belongs at a caller/host input boundary. Disclosure activation itself is browser-local.

```text
SOURCE_QUERY_REQUIRED=NO_CURRENT_EVIDENCE
POSTGRES=N/A
REDIS=N/A
CACHE=N/A
CACHE_TTL=N/A
ETS=N/A
GENSERVER=N/A
OBAN=N/A
PUBSUB=N/A
SERVER_POLLING=N/A
SERVER_STATE_REQUIRED=NO_CURRENT_EVIDENCE
```

## 16. Security review

- **Unsafe `href` and open redirect:** validate navigation URLs under the closed URL policy in BehaviorContract authority. Do not accept arbitrary schemes or trust source values.
- **Arbitrary source selector execution:** do not execute selectors or use source-provided selectors as targets. Resolve typed, document-local relationships only.
- **Source class leakage:** source classes remain evidence, not public API or runtime authority.
- **Source JavaScript execution:** treat scripts as untrusted data. Do not execute, translate, or copy them as target behavior.
- **DOM target collisions:** require unique, scoped generated IDs only if a later realization needs IDs. Native nested details do not need selector-based targets.
- **Nested target escape:** enforce the binding's declared owner subtree; reject cross-boundary or escaping references.
- **Current-page spoofing/trust boundary:** define and validate the caller/host input authority before using a marker. No source class or URL substring alone proves identity.
- **Untrusted labels/content:** escape labels and content; do not turn imported markup into executable HTML.
- **Malformed disclosure ownership:** reject missing, duplicate, ambiguous, or out-of-scope content relationships with a diagnostic. Do not guess from DOM proximity.

## 17. Performance and scaling review

```text
STATE_LAYER=browser_local / native browser state
HOT_CACHE=N/A
WARM_CACHE=N/A
COLD_DB=N/A
REDIS_STRUCTURE=N/A
INVALIDATION=N/A
PUBSUB=N/A

COMPLEXITY=O(menu nodes)
100K_CONCURRENT_USERS=No shared server-side disclosure state
DB_CALLS_PER_TOGGLE=0
NETWORK_CALLS_PER_TOGGLE=0
```

Native toggles require no request, polling, persistent storage, or per-user process. If a host-supplied current-page input is adopted later, provide it with page/render context rather than reading a backend on each toggle.

## 18. BehaviorContract mapping table

| Capability | Accepted source evidence | BehaviorContract concept | Evidence status | Runtime implication | Remaining authority |
|---|---|---|---|---|---|
| Disclosure open/close | Native details/summary groups open and close | `BehaviorPrimitiveDefinition`, `BehaviorStateModel`, `Transition`, `BehaviorEffect` | SUPPORTED | Native open state is the first candidate | Exact source-neutral binding and target validation during BehaviorContract implementation planning |
| Native details/summary | Slide Menu uses native details/summary groups | `RuntimeEffect`; native realization preference | SUPPORTED | Native HTML may satisfy the core without a hook | Native rendering and browser/accessibility verification later |
| Nested disclosure groups | Groups are present; matrix identifies nested disclosure | Separate bindings and typed owner subtrees | PARTIAL | Native nesting is possible; coordination is unspecified | Parent/child and persistence policy |
| Current-page link identity | Current-page link behavior exists | Typed local context / binding input, not a source selector | PARTIAL | No detector or route inference | Current-page input/mapping authority |
| Current-page containing-group open effect | Script opens the group containing the current-page link | Guard/condition and open effect on the existing Disclosure state | SUPPORTED | Could be initial `open` markup or a later transition | Accepted input identity and lifecycle timing |
| Current-page trigger timing | Source script exists | Initial state versus transition | UNKNOWN | No target lifecycle chosen | Timing authority |
| Current-page updates after mount | No accepted update behavior | Runtime lifecycle/reconciliation | UNKNOWN | No hook or server event is justified | Route/patch/update requirement authority |
| Keyboard activation | Native summary groups are used; BehaviorContract defines platform activation for native summary | `KeyboardPolicy` or native platform behavior | PARTIAL | Native browser activation candidate; source-specific extra keys are unproven | Browser/accessibility verification; no custom arrow keys inferred |
| Disclosure accessibility state | Native details/summary | `AccessibilityEffect` and native exposed state | PARTIAL | Native state can expose expanded/collapsed semantics | Exact source additions and current-page indication |
| CSS transition | Disclosure transitions exist | `MotionPolicy` plus separate style authority | PARTIAL | CSS presentation only; values not selected | Target style values and authority |
| Reduced motion | Reduced-motion rules change CSS interpolation | `MotionPolicy` preference handling | SUPPORTED | CSS treatment changes; state remains `closed | open` | Target reduced-motion style authority |
| Cleanup | No accepted target cleanup facts; source script existence is not cleanup proof | Shared `RuntimeInstance` cleanup policy | N/A for native-only candidate; source cleanup UNKNOWN | Native-only requires no instance resources | Any future managed requirement must name owned resources and lifecycle |

## 19. Evidence gaps and conflicts

No authority conflict blocks the core mapping. The matrix and C-07X agree on native disclosure groups and reduced motion. The matrix explicitly leaves current-page lifecycle, nesting policy, keyboard/ARIA guarantees, timing, and cleanup unresolved. BehaviorContract supplies target-neutral rules for these topics but cannot fill in Slide Menu-specific facts.

The decision-changing gaps are current-page input ownership and identity, whether its open effect is initial or update-time, group coordination and reopen persistence, current-page accessibility, exact focus/ARIA requirements, and target motion values. Source implementation bodies are outside this preflight's evidence boundary.

## 20. Final classifications

```text
CORE_DISCLOSURE_MAPPING=SUPPORTED
NATIVE_DETAILS_CORE_SUFFICIENCY=SUPPORTED_BY_AUTHORITY
NESTED_DISCLOSURE_MAPPING=PARTIAL
EXCLUSIVE_ACCORDION_POLICY=NOT_PROVEN

CURRENT_PAGE_OPEN_EFFECT=SUPPORTED
CURRENT_PAGE_IDENTITY_INPUT=EVIDENCE_INSUFFICIENT
CURRENT_PAGE_EFFECT_TIMING=UNKNOWN
CURRENT_PAGE_UPDATE_LIFECYCLE=UNKNOWN

ACCESSIBILITY_MAPPING=PARTIAL
MOTION_MAPPING=PARTIAL
HOOK_REQUIRED=NOT_PROVEN
SERVER_STATE_REQUIRED=NO_CURRENT_EVIDENCE

STYLE_AUTHORITY_REQUIRED=YES
BEHAVIOR_CONTRACT_IMPLEMENTATION_AUTHORIZED=NOT_AUTHORIZED
```

## 21. Overall verdict

```text
OVERALL_VERDICT=PARTIAL_BEHAVIOR_CONTRACT_MAPPING
```

The `closed | open` core and native details candidate are supported. Current-page identity/timing, nested policy, and page-specific accessibility and style details remain unresolved. These gaps do not erase the supported core mapping and do not authorize implementation.

## 22. Next-required-authority graph

```text
Accepted native details/summary disclosure semantics
→ core Disclosure BehaviorContract mapping

current-page open effect
+ accepted current-page identity/input authority
→ current-page initialization mapping

accepted motion values
+ reduced-motion policy
→ style/motion authority

all required semantics accepted
→ BehaviorContract implementation planning
→ BehaviorContract ↔ componentization integration
→ ComponentizationProposer
→ ComponentReview
→ interactive generation prerequisites
→ native generation
→ browser/a11y verification
→ Catalogue admission
```

Every arrow is a dependency, not authorization granted by this document. No downstream phase is authorized here.

## 23. Invalidation conditions

Revisit only affected conclusions if:

- an accepted Slide Menu evidence record changes or adds current-page identity, timing, update, keyboard, focus, ARIA, nesting, or cleanup facts;
- the accepted BehaviorContract Disclosure or runtime lifecycle authority changes;
- a current-page input authority selects caller data, host route context, or browser-local ownership;
- a style authority accepts target transition and reduced-motion values;
- a browser/accessibility verification changes the native details sufficiency assessment; or
- componentization integration defines a binding ownership or projection rule that changes the realization boundary.

A request to derive any new source behavior from proprietary implementation bodies requires a separate accepted source-evidence authority. Until then, retain the affected field as unknown and continue relying only on this document's accepted mappings.
