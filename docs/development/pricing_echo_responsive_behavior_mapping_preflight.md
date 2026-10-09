# Pricing Echo responsive behavior mapping preflight

## 1. Purpose and non-goals

This preflight maps accepted Pricing Echo evidence to the accepted BehaviorContract Tabs, Accordion, and `ResponsiveBehaviorOverride` concepts. It records what the repository supports and what remains unknown before any implementation work.

This document does not implement Pricing Echo, Tabs, Accordion, behavior normalization, runtime code, styling, Design IR changes, componentization, icons, or generated output. It does not inspect proprietary implementation bodies for new semantics, execute source code, or authorize downstream work.

## 2. Exact accepted base and CI identity

```text
REPOSITORY=JCSchoeman96/LiveFrames
PRE_REBASE_HEAD=cd790f8de7e6e7423a905553fb7c3176ca0f2a7b
BASE_SHA=df03f19f61549d2d4e3e4028f2567b4bb134ab4e
BASE_TREE=5314cb74606f1385e70d10ccdf35c23355e2fc4e
POST_MERGE_CI=37948504085
BASE_CI=37948504085 completed/success
POST_MERGE_CI_STATUS=completed
POST_MERGE_CI_CONCLUSION=success
POST_MERGE_CI_HEAD=df03f19f61549d2d4e3e4028f2567b4bb134ab4e
PRE_REBASE_WORKTREE_CLEAN=YES
PRIVATE_SOURCE_NEW_SEMANTICS=NONE
```

The document branch starts from the exact accepted base. No behavior or production code changes are in scope.

## 3. Authority chain

- `docs/09_INTERACTION_MODEL.md` is the accepted source-neutral BehaviorContract authority. It defines Tabs state, Accordion policy dimensions, and the semantic, reversible first-wave Tabs-to-Accordion mapping. It does not authorize implementation.
- `docs/development/frames_native_conversion_matrix.md` records Pricing Echo's monthly/yearly tab presentation and mobile accordion setting. It places Pricing after disclosure and selection authority and identifies continuity as unresolved.
- `docs/development/c07x_unsupported_surface_inventory.md` records the accepted Pricing facts and evidence boundary. This preflight uses only the facts permitted in this document's evidence boundary.
- `docs/development/slide_menu_alpha_disclosure_mapping_preflight.md` establishes the Disclosure foundation. It expressly does not establish Pricing's Accordion policy.
- `docs/03_DESIGN_IR_SPEC.md` owns normalized document and responsive style representation. A responsive style override does not itself represent a behavior-mode transition.
- `docs/04_SOURCE_AND_PROVENANCE.md` keeps provenance, internal-use, and publication authority distinct. Source possession or inspection does not create new permission or semantic authority.
- `docs/development/c09d1_component_contract_authority.md` and `c09d3_componentization_plan_authority.md` own component API and boundary decisions.
- `docs/development/c09d5_componentization_proposer_authority.md` owns proposal construction and leaves approval and generation downstream.
- `docs/development/c09d6_native_generation_authority.md` requires approved component and plan inputs and generation prerequisites. Behavior review cannot replace those gates.

These authorities agree on the supported facts and the unresolved implementation boundary. No conflicting canonical authority was found.

## Current implementation-boundary context

`docs/09_INTERACTION_MODEL.md` remains the canonical BehaviorContract authority. `BehaviorPrimitiveDefinition` owns `BehaviorStateModel`. The model owns `Transition` definitions. Each `Transition` owns its guards and effects. A `BehaviorBinding` represents one occurrence. It owns occurrence triggers, controlled targets, permitted binding policies, and may carry bounded occurrence initial-state assignments. A Pricing binding does not own a Tabs or Accordion state-machine definition. Pricing source evidence supplies occurrence requirements and unresolved policy facts.

P7-A2 implementation is present on main, but its acceptance remains unestablished and Pricing does not depend on that acceptance. The D1B native styling foundation is present and provides deterministic private styling identity and TokenBridge lookup. It does not establish Pricing card-grid styling, Tabs styling, Accordion styling, Pricing spacing, motion values, or icon rendering.

## 4. Accepted Pricing facts

Accepted repository evidence establishes that Pricing Echo contains Frames tabs, monthly/yearly pricing panels, repeated feature rows, icon content, accordion-on-device settings, and responsive card grids. The BehaviorContract evidence ledger records tabs with responsive accordion mode. The matrix also records that the pricing panels change through tab interaction.

These facts establish a responsive presentation relationship, the monthly/yearly logical choices, and accepted cross-mode correspondence: the monthly/yearly panels themselves become accordion-style at `mobile_portrait`. C-07X's accepted responsive authority defines `mobile_portrait` as `max-width 478px`. These facts do not establish normalized stable item IDs, detailed Accordion state policy, accessibility behavior, or runtime lifecycle.

## 5. Facts not established

Accepted evidence does not establish:

- the viewport observation mechanism or mode-change timing;
- stable typed IDs for the logical monthly/yearly options, or normalized tab-to-panel-to-Accordion binding records;
- the initial monthly/yearly selection or initial Accordion open item;
- source tab activation, focus, orientation, disabled-item, or keyboard policy;
- Accordion `single|multiple`, closure policy, item enabled state, item order, or multi-open behavior;
- focus movement during responsive mode changes, state persistence, or resize behavior;
- source reconciliation, patch behavior, listener lifecycle, or cleanup;
- whether the target needs a hook, server event, or a particular implementation technique.

Unknown source facts remain unknown. The source widget name, labels, visual proximity, and target defaults do not fill these gaps.

## 6. Domain and resource map

```text
Domain:
  Pricing Echo responsive pricing selection

Concepts:
  PricingSelector
  PricingMode
  PricingOption
  PricingPanel
  TabsBinding
  AccordionBinding
  ResponsiveBehaviorOverride
  BreakpointAuthority
  FocusPolicy
  AccessibilityEffect

Relationships:
  one pricing option identifies one logical pricing panel
  Tabs mode selects one logical pricing option
  Accordion mode exposes logical pricing options according to an accepted policy
  ResponsiveBehaviorOverride maps logical selection between the presentation modes
  presentation mode does not create another business-data state

Invariants:
  monthly/yearly meaning is independent of presentation mode
  responsive conversion does not change the selected pricing meaning
  a claimed reversible mapping round-trips the current semantic selection
  no viewport threshold is invented
  source selectors and source JavaScript do not become runtime authority
```

These are conceptual terms only. They do not define implementation structs or freeze a public API.

## 7. Logical pricing selection

The accepted meaning is a choice between monthly and yearly pricing panels. This is the logical selection, separate from whether the page presents it as tabs or accordion controls. Neither CSS layout nor viewport size is itself a pricing choice.

| Lifecycle | State | Initial state | Transition and guard | Effects and accessibility | Invalid/no-op cases | Side effects and cleanup |
|---|---|---|---|---|---|---|
| Logical selection | One conceptual selected pricing option | `UNKNOWN` from source evidence | A user choice changes the logical option only when the corresponding option is identified and enabled. | The matching pricing meaning and panel remain associated across presentation changes. Accessibility exposure follows the active presentation binding. | Unknown or ambiguous option identity cannot be guessed. | Browser-local presentation state is the target default. No server or data-store effect is implied. |

The target may use an explicit default under future authority, but that would not prove the source's initial selection.

## 8. Tabs mapping

BehaviorContract defines ordered tabs, one associated panel per tab, separate `selected_tab_id` and `focused_tab_id`, disabled-item guards, and manual or automatic activation. Its default initial selection is the first enabled tab unless a valid explicit selection exists. These are target semantics, not Pricing source facts.

| Lifecycle | State | Initial state | Transition and guard | Effects and accessibility | Invalid/no-op cases | Side effects and cleanup |
|---|---|---|---|---|---|---|
| Tabs mode | Ordered option/panel set; `selected_tab_id`; `focused_tab_id` | Source selection and source focus are unknown. Target default remains as stated in BehaviorContract. | Activation selects an enabled tab. Under manual target policy, focus movement alone does not select; under automatic policy, focus movement selects. Pricing source activation policy is unknown. | Selection exposes the corresponding panel and synchronizes selected state, tab-to-panel relationships, and roving tab stop. Focus follows the chosen keyboard policy. | Missing or duplicate identity, no associated panel, or an empty/all-disabled set invalidates the target binding. | Target interaction state is client-local unless a future accepted requirement makes selection server-authoritative. Runtime resource ownership and cleanup follow the selected realization. |

Accepted Pricing evidence supports the existence of tab selection between pricing panels. It does not establish tab count/cardinality beyond the accepted monthly/yearly pair, source disabled options, orientation, initial selection, or keyboard behavior. Do not infer activation or arrow-key policy from the Frames widget name.

```text
TAB_OPTION_SET=PARTIAL
SELECTED_OPTION_MEANING=SUPPORTED
INITIAL_SELECTED_OPTION=UNKNOWN
TAB_TO_PANEL_CARDINALITY=PARTIAL
DISABLED_OPTIONS=UNKNOWN
TAB_ACTIVATION_POLICY=UNKNOWN
TAB_ORIENTATION=UNKNOWN
```

The accepted option labels and pricing meaning are known. Exact stable identity and one-to-one tab/panel references remain unestablished.

## 9. Accordion mapping

BehaviorContract defines `open_item_ids` and independent target policy dimensions: `mode=single|multiple`, `closure=allow_all_closed|require_one_open`, and per-item `enabled`. Items have stable typed IDs. Target defaults are not evidence of Pricing source configuration.

| Lifecycle | State | Initial state | Transition and guard | Effects and accessibility | Invalid/no-op cases | Side effects and cleanup |
|---|---|---|---|---|---|---|
| Accordion mode | `open_item_ids` | Source open items are unknown. BehaviorContract target initialization depends on an explicitly selected policy. | Activating an enabled item opens or closes it, subject to the accepted mode and closure policy. | Reveal/conceal the associated panel and synchronize expanded state; focus stays on the activated control. | Unknown or duplicate IDs, missing panels, disabled activation, or an invariant-breaking close cannot be normalized by guesswork. | State is local to the rendered group by default. Cleanup releases only resources owned by this group. |

```text
SOURCE_ACCORDION_MODE=UNKNOWN
SOURCE_ACCORDION_CLOSURE_POLICY=UNKNOWN
SOURCE_MULTI_OPEN_ALLOWED=UNKNOWN
SOURCE_INITIAL_OPEN_ITEMS=UNKNOWN
SOURCE_DISABLED_ITEMS=UNKNOWN
SOURCE_ITEM_ORDER=UNKNOWN
```

Responsive Accordion existence does not establish any of these settings. Slide Menu Alpha supplies Disclosure evidence only and is not proof of Pricing Accordion behavior.

## 10. ResponsiveBehaviorOverride mapping

BehaviorContract treats Tabs-to-Accordion as a semantic mode transition. Accepted C-07X responsive authority supplies Pricing's `mobile_portrait` condition at `max-width 478px`; C-07X also says the monthly/yearly panels become accordion-style at that condition. The semantic correspondence and mode direction are supported. A reversible target mapping still requires normalized stable item identity and one canonical selection in both modes for the first wave. BehaviorContract rejects lossy conversion from multiple open Accordion items to one selected tab.

| Lifecycle | State | Initial state | Transition and guard | Effects and accessibility | Invalid/no-op cases | Side effects and cleanup |
|---|---|---|---|---|---|---|
| Responsive presentation mode | Conceptual `tabs_mode` or `accordion_mode`; not a business state | Pricing's accepted responsive condition is `mobile_portrait`, `max-width 478px`. Source initial pricing selection is unknown. | At the accepted `mobile_portrait` condition, the monthly/yearly panels become Accordion-style. The reverse presentation applies outside that condition. A complete binding still requires stable typed identity and reversible state compatibility. | Preserve the same logical pricing option. Map focus to the corresponding control only if the old focused control is removed. Update exposed control/panel relationships with the new presentation. | Missing typed identity or a non-reversible Accordion state prevents claiming a complete override. The accepted threshold does not resolve source Accordion policy. | Do not assume CSS alone, a hook, or a server event. If a managed runtime is later justified, mount, patch reconciliation, reconnect, and destruction must follow shared BehaviorContract lifecycle rules. |

The two questions remain distinct: A. which pricing option is selected; B. how that option is presented in Tabs mode; C. how it is presented in Accordion mode. Responsive layout does not create another business-data state.

## 11. Item identity analysis

Accepted C-07X evidence says the monthly/yearly panels themselves become Accordion-style at `mobile_portrait`. This supports the logical correspondence across presentation modes: monthly remains the monthly pricing meaning, and yearly remains the yearly pricing meaning. It does not establish the normalized, stable typed IDs or binding records required by BehaviorContract. Labels must not become durable runtime IDs by assumption.

```text
LABEL_SIMILARITY=ACCEPTED_MONTHLY_YEARLY_LABELS
CROSS_MODE_LOGICAL_CORRESPONDENCE=SUPPORTED
STABLE_TYPED_ITEM_IDENTITY=NOT_ESTABLISHED
ITEM_IDENTITY_MAPPING=PARTIAL
```

No IDs are invented here. A later authority must accept a typed, stable relationship among each pricing option, its tab, panel, and Accordion item.

## 12. Reversibility analysis

The BehaviorContract first-wave rule is:

```text
Tabs(selected=X) → Accordion(open={X})
Accordion(open={X}) → Tabs(selected=X)
```

For each accepted pricing meaning, the conceptual test is:

```text
Tabs(monthly) → Accordion(monthly) → Tabs(monthly)
Tabs(yearly)  → Accordion(yearly)  → Tabs(yearly)
```

Accepted cross-mode correspondence supports the logical meaning of both paths. Stable typed identity and normalized binding records remain unresolved, and the source Accordion policy is unknown. Therefore these paths are supported as a target mapping shape but do not prove a complete or reversible Pricing instance.

The state `Accordion(open={X,Y})` cannot losslessly map to single-selection Tabs under the accepted first-wave rule. Pricing evidence does not prove that the source forbids this state. Do not silently choose one option or normalize multiple open items.

## 13. Breakpoint authority

Accepted C-07X evidence records that the monthly/yearly panels become Accordion-style at `mobile_portrait`. C-07X responsive authority defines `mobile_portrait` as `max-width 478px` and records that the accepted authority and Fidelity tests emit that condition. This source breakpoint authority is not a public component API.

```text
SOURCE_RESPONSIVE_BREAKPOINT_NAME=mobile_portrait
SOURCE_RESPONSIVE_BREAKPOINT_CONDITION=max-width 478px
BREAKPOINT_AUTHORITY=SUPPORTED
RESPONSIVE_MODE_DIRECTION=SUPPORTED
RESPONSIVE_PRESENTATION_CONDITION=SUPPORTED
VIEWPORT_OBSERVATION_MECHANISM=UNKNOWN
```

The accepted condition informs future normalized responsive authority. Do not expose `mobile_portrait` or `478px` as a public component attribute. The accepted threshold does not establish how a runtime observes viewport conditions.

## 14. Initial state

The accepted evidence does not establish whether monthly or yearly is initially selected, which Accordion item is initially open, or whether the source initializes a mode-specific state.

```text
LOGICAL_INITIAL_SELECTION=UNKNOWN
SOURCE_INITIAL_SELECTION=UNKNOWN
TABS_INITIAL_SELECTION=UNKNOWN
ACCORDION_INITIAL_OPEN_ITEM=UNKNOWN
```

BehaviorContract defaults describe future target behavior if no valid explicit state is supplied. They do not replace or establish source initial state.

## 15. Focus and keyboard lifecycle

BehaviorContract defines separate selected and focused Tabs state, manual/automatic activation, orientation-specific arrow keys, optional Home/End, and ordinary exit by Tab/Shift+Tab. For Accordion, Enter/Space toggles enabled items; Tab order remains ordinary and focus is not trapped. On responsive conversion, semantic selection stays stable and focus moves only if its control is removed, mapping to the corresponding control.

| Question | Pricing evidence | Classification |
|---|---|---|
| Tab activation and keyboard behavior | Not established | `EVIDENCE_INSUFFICIENT` |
| Accordion keyboard behavior | Not established | `EVIDENCE_INSUFFICIENT` |
| Mode-change focus requirement | BehaviorContract requires conditional continuity | `SUPPORTED` as target policy |
| Pricing source focus continuity | Not established | `EVIDENCE_INSUFFICIENT` |

Do not claim that the source meets target keyboard policy because the target architecture defines it.

## 16. Accessibility

Target behavior must expose meaningful pricing option names, selected state, tab-to-panel relationships, Accordion expanded state, and suitable heading/control semantics. It must preserve logical identity across modes, avoid duplicate visible or accessible content, keep inactive content from exposing unintended focusable descendants, and maintain focus when a mode change removes a focused control.

Accepted Pricing evidence does not establish accessible names, roles, relationships, ARIA, hidden-panel behavior, duplicate content handling, or focus continuity. Do not invent ARIA or claim that visual labels prove accessible names.

```text
ACCESSIBILITY_MAPPING=PARTIAL
BEHAVIOR=PARTIAL
ACCESSIBILITY=PARTIAL
```

The target requirements are supported by BehaviorContract; Pricing-specific source mapping is incomplete.

## 17. Runtime realization

Candidates remain unselected. The accepted breakpoint does not determine the realization technique:

| Candidate | Current evidence |
|---|---|
| `CSS_MEDIA_QUERY_ONLY` | Not established. A semantic mode change may change control and keyboard relationships, so CSS-only treatment cannot be assumed. |
| `CLIENT_RESPONSIVE_BINDING` | Not established. Source JavaScript is not target runtime authority. |
| `SERVER_RENDERED_MODE` | Not established. No accepted server-owned mode requirement exists. |
| `LIVEVIEW_SERVER_EVENT` | No accepted server workflow or server-owned selection requirement exists. |

```text
MANAGED_RESPONSIVE_RUNTIME_REQUIRED=NOT_PROVEN
CLIENT_HOOK_REQUIRED=NOT_PROVEN
SERVER_EVENT_REQUIRED=NOT_PROVEN
MODE_CHANGE_RUNTIME_TECHNIQUE=UNKNOWN
```

A server round trip must not be added merely to switch presentation mode. A later authority may select a realization only after semantic and breakpoint requirements are known.

## 18. Reconciliation and cleanup

No accepted Pricing evidence establishes a managed runtime or its lifecycle needs. Therefore:

```text
RUNTIME_LIFECYCLE_MAPPING=DEFERRED_UNTIL_MANAGED_RUNTIME_IS_PROVEN
MOUNT_MODE_DETECTION=UNKNOWN
BREAKPOINT_CROSSING=UNKNOWN
LIVEVIEW_PATCH_RECONCILIATION=UNKNOWN
DISCONNECT_RECONNECT=UNKNOWN
DESTROY_CLEANUP=UNKNOWN
DUPLICATE_LISTENER_PROTECTION=UNKNOWN
```

If managed behavior is later required, shared BehaviorContract authority requires valid mount, reconciliation after server patches without duplicate resources, applicable disconnect/reconnect handling, and cleanup on actual owner destruction. This preflight does not design a hook.

For any future managed realization, `RuntimeInstance.destroyed` is terminal only when its actual owner is removed. Destruction releases that instance's listeners, observers, timers, focus references, and other owned resources. A mode change or ordinary patch is not destruction.

## 19. Data boundary

Accepted Pricing evidence records static monthly/yearly pricing panels and feature rows. It does not establish a source query or caller data binding. No backend query is required by current evidence.

```text
SOURCE_QUERY_OBJECTS=NONE_ACCEPTED
BACKEND_QUERY_REQUIRED=NO
DATA=N/A
EXTERNAL_DEPENDENCY=NONE
CALLER_DATA_BINDING_REQUIRED=NO_CURRENT_EVIDENCE

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

Do not create a Post Query or Pricing Query abstraction.

## 20. Icon boundary

Pricing Echo includes icon content. Icon renderability and licensing are separate unresolved authority and are outside this behavior mapping.

```text
ICON_CONTENT_PRESENT=YES
ICON_RENDERABILITY_AUTHORITY=SEPARATE_BLOCKER
ICON_AUTHORITY_SOLVED_HERE=NO
```

No icon assets, licenses, libraries, or C08B changes are selected.

## 21. Styling boundary

This preflight establishes the accepted Pricing source-responsive `mobile_portrait` condition at `max-width 478px`. It does not establish target styling values such as Pricing card-grid CSS, Tabs or Accordion visual treatment, spacing, icon CSS, or motion values.

```text
STYLE_AUTHORITY_REQUIRED=YES
GENERIC_NATIVE_STYLING_FOUNDATION=PRESENT
PRICING_SPECIFIC_STYLE_MAPPING=PARTIAL
STATIC=PARTIAL
```

## 22. Security review

- Do not execute source JavaScript or translate it into target code.
- Do not use arbitrary source selectors, source classes, or untrusted strings as generated IDs, module names, shell arguments, or paths.
- Resolve targets through typed, document-local references; reject cross-binding escape and mismatched tab/panel identities.
- Reject malformed or ambiguous Accordion target identities instead of guessing from labels or DOM proximity.
- Validate any pricing CTA URL under the closed URL policy; current evidence does not establish CTA URLs for this mapping.
- Keep inactive content from leaving unintended focusable descendants exposed.
- Viewport width is presentation context, not a security boundary. Spoofing it must not grant access or change business data.

## 23. Performance and scaling review

Pricing selection and presentation mode are browser-local under current evidence. Complexity is bounded by the number of Pricing options and panels. A presentation change must not cause a database query, server poll, or per-user server process.

```text
STATE_LAYER=browser_local
HOT_CACHE=N/A
WARM_CACHE=N/A
COLD_DB=N/A
REDIS_STRUCTURE=N/A
INVALIDATION=N/A
PUBSUB=N/A

DB_CALLS_PER_SELECTION=0
NETWORK_CALLS_PER_SELECTION=0
SERVER_POLLING=NO
```

No server load should be introduced to switch Tabs and Accordion presentation, including at 100,000 concurrent users.

## 24. Mapping table

| Capability | Accepted Pricing evidence | BehaviorContract concept | Evidence status | Target implication | Missing authority |
|---|---|---|---|---|---|
| Monthly/yearly option set | Monthly/yearly pricing panels | Logical pricing option and panel | `SUPPORTED` | Preserve the choice independently of presentation | Stable option IDs and exact panel relationship |
| Tabs mode | Frames tabs | Tabs binding | `SUPPORTED` | Model selection separately from focus | Pricing item details and initial state |
| Tab selection | Panels change by tab interaction | Selected tab and associated panel | `PARTIAL` | Selection must retain pricing meaning | Stable item-to-panel mapping and source initial selection |
| Tabs keyboard policy | None accepted | Focus/selection/keyboard policy | `EVIDENCE_INSUFFICIENT` | Apply target policy only under future authority | Activation, orientation, disabled state, keyboard details |
| Accordion mode existence | Accordion-on-device setting | Accordion binding and responsive mode | `SUPPORTED` | Treat as a distinct semantic presentation mode | Source open behavior and precise item set |
| Accordion open policy | None accepted | `single|multiple`; `open_item_ids` | `EVIDENCE_INSUFFICIENT` | Select no source policy by assumption | Source mode and multi-open facts |
| Accordion closure policy | None accepted | `allow_all_closed|require_one_open` | `EVIDENCE_INSUFFICIENT` | Do not infer from defaults | Source closure configuration |
| Cross-mode logical correspondence | C-07X says the monthly/yearly panels themselves become Accordion-style at `mobile_portrait` | Same logical option across presentation modes | `SUPPORTED` | Preserve monthly/yearly meaning across modes | Normalized typed binding records |
| Stable typed item identity | Monthly/yearly logical correspondence is accepted | Stable typed BehaviorContract item identity | `NOT_ESTABLISHED` | Do not use labels as runtime IDs | Accepted typed IDs and option/tab/panel/Accordion relationships |
| Tab-to-Accordion item identity | Monthly/yearly panels undergo responsive conversion | Typed identity plus responsive binding | `PARTIAL` | Use accepted logical correspondence; require typed binding for implementation | Stable normalized identity and binding records |
| Responsive mode existence | Accordion-on-device behavior | `ResponsiveBehaviorOverride` | `SUPPORTED` | Model a semantic mode transition | Pricing mode lifecycle details |
| Breakpoint | C-07X maps the Pricing Accordion-style panels to `mobile_portrait`; accepted condition is `max-width 478px` | Breakpoint authority | `SUPPORTED` | Future normalized responsive authority uses the accepted condition; keep it out of public API | Viewport observation mechanism and mode-change timing |
| Forward mapping | Monthly/yearly panels become Accordion-style at the responsive condition | Selected tab → open item | Target rule `SUPPORTED`; Pricing logical correspondence `SUPPORTED`; typed binding `PARTIAL` | Preserve the same logical option with one canonical item | Stable typed identity and source Accordion compatibility |
| Reverse mapping | Same monthly/yearly panels return to tab presentation outside the condition | Open item → selected tab | Target rule `SUPPORTED`; Pricing logical correspondence `SUPPORTED`; typed binding `PARTIAL` | Preserve the same option | Stable typed identity and source Accordion compatibility |
| Round-trip reversibility | Logical correspondence is supported; source state compatibility is unknown | Reversible mapping | Target rule `SUPPORTED`; Pricing instance `NOT_PROVEN` | Require both directions before claiming reversible | Typed identity and source open-state policy |
| Focus continuity | No source focus evidence | Responsive focus policy | Target requirement `SUPPORTED`; source mapping `EVIDENCE_INSUFFICIENT` | Map focus only when the old control is removed | Source controls and transition behavior |
| Accessibility | No Pricing-specific semantic details | Synchronized selection, expansion, relationships, focus | `PARTIAL` | Meet target semantics without inventing source ARIA | Names, relationships, inactive content, focus facts |
| Managed runtime need | Breakpoint is known; no target lifecycle evidence | Runtime realization and lifecycle | `NOT_PROVEN` | Do not select a runtime yet | DOM lifecycle and semantic realization authority |
| Cleanup | No managed source lifecycle evidence | Runtime destruction cleanup | `DEFERRED` | If managed, apply shared lifecycle contract | Proof that managed runtime is required |
| Icons | Icon content present | Separate asset/renderability authority | `SEPARATE_BLOCKER` | Keep icon decision out of this mapping | Icon authority |
| Styling | Responsive card grids and conversion condition accepted | Style authority | `PARTIAL` | Styling authority remains required | Grid, tabs, Accordion and spacing values |

## 25. Evidence gaps and conflicts

The repository supports monthly/yearly panels, tab selection, conversion of those panels to Accordion-style presentation at `mobile_portrait`, and the accepted `max-width 478px` condition. It also supports logical monthly/yearly correspondence across those modes. Stable typed identity, source Accordion policy, initial selection, keyboard behavior, accessibility details, and runtime lifecycle remain unresolved.

`docs/03_DESIGN_IR_SPEC.md` can represent responsive style overrides separately from the semantic mode transition. The accepted source condition does not establish the runtime observation mechanism or make source breakpoint naming part of a public component API. No conflict requires a stop; unresolved source interpretation remains row-local.

## 26. Final classifications

```text
PRICING_OPTION_SET=SUPPORTED
TABS_CORE_MAPPING=SUPPORTED
TAB_SELECTION_MAPPING=PARTIAL
TAB_KEYBOARD_SOURCE_EVIDENCE=EVIDENCE_INSUFFICIENT

RESPONSIVE_MODE_EXISTENCE=SUPPORTED
ACCORDION_CORE_MAPPING=PARTIAL
SOURCE_ACCORDION_MODE=UNKNOWN
SOURCE_ACCORDION_CLOSURE_POLICY=UNKNOWN
SOURCE_MULTI_OPEN_ALLOWED=UNKNOWN
SOURCE_INITIAL_OPEN_ITEMS=UNKNOWN

SOURCE_RESPONSIVE_BREAKPOINT_NAME=mobile_portrait
SOURCE_RESPONSIVE_BREAKPOINT_CONDITION=max-width 478px
BREAKPOINT_AUTHORITY=SUPPORTED
RESPONSIVE_MODE_DIRECTION=SUPPORTED
RESPONSIVE_PRESENTATION_CONDITION=SUPPORTED

CROSS_MODE_LOGICAL_CORRESPONDENCE=SUPPORTED
STABLE_TYPED_ITEM_IDENTITY=NOT_ESTABLISHED
ITEM_IDENTITY_MAPPING=PARTIAL

FORWARD_MAPPING=SUPPORTED_BY_BEHAVIOR_AUTHORITY; PRICING_LOGICAL_CORRESPONDENCE=SUPPORTED; TYPED_BINDING=PARTIAL
REVERSE_MAPPING=SUPPORTED_BY_BEHAVIOR_AUTHORITY; PRICING_LOGICAL_CORRESPONDENCE=SUPPORTED; TYPED_BINDING=PARTIAL
ROUND_TRIP_REVERSIBLE=SUPPORTED_AS_TARGET_RULE; PRICING_INSTANCE=NOT_PROVEN
PRICING_INSTANCE_REVERSIBILITY=NOT_PROVEN
SOURCE_COMPATIBILITY_WITH_SINGLE_CANONICAL_ITEM=NOT_PROVEN

ACCESSIBILITY_MAPPING=PARTIAL
BEHAVIOR=PARTIAL
ACCESSIBILITY=PARTIAL
FOCUS_CONTINUITY_MAPPING=PARTIAL

MANAGED_RESPONSIVE_RUNTIME_REQUIRED=NOT_PROVEN
CLIENT_HOOK_REQUIRED=NOT_PROVEN
SERVER_EVENT_REQUIRED=NOT_PROVEN
VIEWPORT_OBSERVATION_MECHANISM=UNKNOWN
MODE_CHANGE_RUNTIME_TECHNIQUE=UNKNOWN

BACKEND_QUERY_REQUIRED=NO
DATA=N/A
EXTERNAL_DEPENDENCY=NONE
ICON_RENDERABILITY_AUTHORITY=SEPARATE_BLOCKER
STYLE_AUTHORITY_REQUIRED=YES
GENERIC_NATIVE_STYLING_FOUNDATION=PRESENT
PRICING_SPECIFIC_STYLE_MAPPING=PARTIAL
STATIC=PARTIAL

BEHAVIOR_IMPLEMENTATION_AUTHORIZED=NO
PRIVATE_SOURCE_NEW_SEMANTICS=NONE
```

## 27. Overall verdict

```text
OVERALL_VERDICT=PARTIAL_RESPONSIVE_BEHAVIOR_MAPPING
OVERALL=NOT_READY
```

The responsive Tabs/Accordion relationship, `mobile_portrait` breakpoint condition, and monthly/yearly logical correspondence are supported. Pricing-specific reversible mapping remains unproven because stable typed identity and source Accordion compatibility are not established. This preflight does not authorize implementation.

## Remaining blocker ownership

- Pricing-specific style conversion and evidence, including card grid, Tabs, Accordion, spacing, and motion → Static leg.
- Generic Tabs and Accordion lifecycle or runtime realization → Behavior / P7 leg.
- Stable typed behavior or component identity → Behavior/componentization integration authority.
- Source Accordion mode, closure, multi-open policy, initial state, and Pricing-specific accessibility evidence → Frames Conversion / Evidence leg.
- Generic accessibility realization → Behavior leg.
- Icons → separate icon/asset authority.
- Backend query and data abstraction → N/A under current Pricing evidence.
- External runtime or library → none established; any future runtime choice belongs to the Behavior leg.
## 28. Next-required-authority graph

```text
Accepted Pricing logical option semantics
+ accepted Tabs semantics
+ accepted Accordion semantics
+ accepted `mobile_portrait` responsive condition
+ accepted cross-mode logical correspondence
→ partial responsive behavior mapping

stable typed item identity/projection
+ accepted Accordion compatibility and policy
→ complete reversible ResponsiveBehaviorOverride mapping

then:
responsive behavior authority
+ Pricing styling authority
+ icon authority
+ behavior↔componentization integration
→ ComponentizationProposer
→ ComponentReview
→ interactive generation prerequisites
→ native generation
→ browser/accessibility verification
→ Catalogue admission
```

Each downstream step retains its existing authority and review gates. This graph authorizes none of them.

## 29. Invalidation conditions

Revisit this mapping if accepted Pricing evidence changes, stable typed identity or a Pricing-specific binding is accepted, source Accordion policy or initial state becomes accepted, the `mobile_portrait` breakpoint authority changes, accessibility or focus evidence changes, or the BehaviorContract mapping rule changes. New evidence must enter through its accepted authority; private source facts do not become accepted by this document.
