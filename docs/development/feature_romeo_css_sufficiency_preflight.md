# Feature Romeo CSS sufficiency preflight

## 1. Purpose and non-goals

This preflight checks whether accepted repository evidence proves that Feature Romeo's pointer and focus presentation can use browser CSS state, or whether Romeo requires managed behavior. It records the current LiveFrames structure and style capabilities without implementing Romeo.

This document does not authorize CSS, JavaScript, hooks, Behavior IR, component, generator, or browser-verification work. This preflight does not amend, implement, or widen the accepted BehaviorContract authority in `docs/09_INTERACTION_MODEL.md`. That authority sets source-neutral behavior semantics; it does not provide missing Romeo source facts. Source interactions are evidence of an implementation mechanism, not proof that the target needs the same mechanism.

## 2. Accepted base and CI identity

The original gate named PR #146's accepted merge identity:

```text
MERGED_PR=146
MERGED_HEAD=9bf5326c5d224ccbf0b253cfba06c8a2ee6b6663
MAIN_SHA=753dd81e8cad4597a68deddf211d62fc15ccf21f
MAIN_TREE=38ab67d5e3b29c2ca49dad14219ccd4cf9a0a757
POST_MERGE_CI=37919656255
POST_MERGE_CI_STATUS=completed
POST_MERGE_CI_CONCLUSION=success
POST_MERGE_CI_HEAD=753dd81e8cad4597a68deddf211d62fc15ccf21f
```

After `main` moved, the branch continued from the then-current `origin/main`. This base is now historical because PR #145 has merged:

```text
HISTORICAL_BASE_SHA=20a171bd35187354548eeaea4a58d631d37bd056
HISTORICAL_BASE_TREE=48901643d71ee56048e2f3980a98bcc38195a4ce
HISTORICAL_BASE_CI=37920340234
HISTORICAL_BASE_CI_STATUS=completed
HISTORICAL_BASE_CI_CONCLUSION=success
HISTORICAL_BASE_CI_HEAD=20a171bd35187354548eeaea4a58d631d37bd056
HISTORICAL_BASE_CI_EVENT=push
```

The earlier successful CI run remains historical evidence for the PR #146 merge commit. Run `37920340234` is historical CI for the pre-PR #145 base. The current accepted base includes PR #145's BehaviorContract authority:

```text
BASE_SHA=1b404caf92a8923e7a0593ade7ef983e04ebd3b6
BASE_TREE=cdc20f97a4f4be191f27f5784998c1f4be3bf777
CURRENT_MAIN_CI=37922030243
CURRENT_MAIN_CI_STATUS=completed
CURRENT_MAIN_CI_CONCLUSION=success
CURRENT_MAIN_CI_HEAD=1b404caf92a8923e7a0593ade7ef983e04ebd3b6
```

PR #145 merged the accepted revision of `docs/09_INTERACTION_MODEL.md` as the current source-neutral BehaviorContract authority.

## 3. Authority chain

The sources below govern separate claims. None authorizes new source semantics for Romeo.

| Authority | Role in this preflight |
| --- | --- |
| `docs/development/frames_native_conversion_matrix.md` | Current programme order and Romeo's unresolved CSS-versus-managed-state question. It says CSS is the first candidate and JavaScript must wait for an accepted managed-state requirement. |
| `docs/development/c07x_unsupported_surface_inventory.md` | Accepted historical Romeo export summary and explicit limits on what the source inventory proves. |
| `docs/development/c09d1_component_contract_authority.md` | Component API and accessibility boundary. Source classes are not public inputs; consumer navigation and behavior are not inferred. |
| `docs/development/c09d3_componentization_plan_authority.md` | Static public-input placement boundary. It does not define runtime behavior or CSS generation. |
| `docs/development/c09d5_componentization_proposer_authority.md` | Requires explicit semantic decisions and prohibits semantic guessing, CSS/JS generation, and source-runtime integration in its scope. |
| `docs/development/c09d6_native_generation_authority.md` | Review-gated native generation and package-owned styling boundaries. A selected tracer needs style-coverage evidence; Fidelity is not the native style generator. |
| `docs/09_INTERACTION_MODEL.md` | Accepted authority revision 1.0.1 for BehaviorContract artifact 1.0.0. It prefers native HTML/CSS when they satisfy the semantic contract, requires hooks only for browser lifecycle, DOM reconciliation, or native-platform needs, and keeps interactive generation gated by behavior/componentization integration. It does not resolve Romeo's missing source interaction effects. |
| `docs/03_DESIGN_IR_SPEC.md` | Style values may preserve unresolved or complex CSS. An Interaction records intent and does not select CSS, LiveView JS, hooks, or server behavior. |
| `docs/04_SOURCE_AND_PROVENANCE.md` | Governs source provenance and permitted use. Technical inspection or possession does not grant permission to publish or infer new semantics. |

The audit used only the accepted repository summaries and current LiveFrames code. It did not open proprietary implementation bodies or execute source JavaScript, PHP, Frames, Bricks, or ACSS runtimes.

## 4. Accepted Romeo facts

The accepted C-07X inventory and conversion matrix record:

- four linked cards;
- hover and `focus-within` presentation;
- Bricks `mouseenter` and `mouseleave` source interactions;
- a mobile column layout;
- a default card state that changes on pointer entry and exit;
- a keyboard-related visual state supplied by CSS `focus-within`;
- source interactions and custom state classes are not compiled by LiveFrames.

The conversion matrix also says no independent browser behavior was tested. It leaves unresolved whether authored CSS fully reproduces the pointer state, or whether Romeo requires a non-CSS lifecycle, touch behavior, or another state effect. The accepted BehaviorContract authority prefers native HTML/CSS when they satisfy accepted semantics. It strengthens the rule that source JavaScript does not imply target JavaScript or a hook, but it does not establish Romeo's semantic contract.

## 5. Facts not established

Accepted evidence does not establish:

- whether the source interactions only change presentation or also change content, data, ARIA, focus, URL, history, storage, or another state;
- whether an interaction toggles a class, what that class means, or whether the class survives pointer exit;
- whether timers, asynchronous work, observers, or cleanup exist;
- whether cards coordinate so only one card can be active;
- how pointer and focus overlap, including any precedence rule;
- the exact hover and focus declarations, their cascade, or whether focus-within matches the meaningful hover presentation;
- whether essential content is hidden until hover or focus;
- which element owns each card's link and navigation;
- the behavior required on touch and other non-hover devices;
- whether animated transitions exist or need reduced-motion handling;
- exact responsive breakpoints or an accessibility acceptance result.

These are unknowns, not evidence that an effect is absent. Resolving source-only semantic facts requires an authorized source-evidence authority. This preflight does not fill those gaps by reading private implementation bodies.

## 6. Lifecycle and state model

The states and transitions below are candidate descriptions derived from the accepted labels. They are not approved implementation semantics. A browser selector condition is kept separate from application-managed state.

### Candidate states

| State | Candidate entry and exit condition | Event or CSS condition and guard | Visible effect | DOM, ARIA, focus, timer, URL, and persistence | Cross-card coordination, cleanup, invalid/no-op |
| --- | --- | --- | --- | --- | --- |
| `DEFAULT` | Candidate entry when the pointer is not over the card and focus is not within it. Candidate exit when pointer or focus enters. | No active `:hover` or `:focus-within` condition. Exact target ownership is not established. | Baseline card presentation. Exact baseline declarations are unknown. | No mutation is established. Whether source behavior mutates DOM, ARIA, focus, timers, URL/history, or storage is unknown. | Coordination and cleanup are unknown. Empty/missing targets and no-op behavior are not described. |
| `POINTER_ACTIVE` | Candidate entry on pointer entry and exit on pointer leave. | Accepted inventory records `mouseenter`/`mouseleave`; `:hover` is the source-neutral CSS candidate. No guard beyond pointer relation is established. | A pointer-related card presentation change is accepted; exact properties and content effects are unknown. | No specific mutation is established. Class, ARIA, focus, timer, URL/history, and persistence effects remain unknown. | Whether cards coordinate, whether listeners need cleanup, and invalid/no-op behavior are unknown. |
| `FOCUS_ACTIVE` | Candidate entry when focus is within the card and exit when focus leaves it. | Accepted inventory records `focus-within` styling. The focused descendant and any additional guard are unknown. | A keyboard-related visual state is accepted; its equivalence to pointer presentation is unknown. | No specific mutation is established. ARIA, focus movement, DOM, timer, URL/history, and persistence effects remain unknown. | Coordination, cleanup, and invalid/no-op behavior are unknown. |

### Candidate transitions

| Transition | Entry/exit event or selector condition | Guard | Visible effect | DOM / ARIA / focus mutation | Timer / URL / persistence | Cross-card coordination | Cleanup | Invalid or no-op case |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `DEFAULT -> POINTER_ACTIVE` | `mouseenter` is recorded; `:hover` is the CSS candidate. | Pointer is over a card, as a candidate guard only. | Pointer presentation changes; the exact change is unknown. | Unknown. | Unknown. | Unknown. | Unknown. | Not established. |
| `POINTER_ACTIVE -> DEFAULT` | `mouseleave` is recorded; `:hover` becomes false as the CSS candidate. | Pointer is no longer over the card, as a candidate guard only. | Candidate return to baseline; the exact change is unknown. | Unknown. | Unknown. | Unknown. | Unknown. | Not established. |
| `DEFAULT -> FOCUS_ACTIVE` | Focus enters a card descendant; `:focus-within` is the accepted visual condition. | The focused element is within the card, as a candidate guard only. | A keyboard-related visual state is recorded; equivalence and exact declarations are unknown. | Unknown. The evidence does not establish scripted focus movement or ARIA updates. | Unknown. | Unknown. | Unknown. | Not established. |
| `FOCUS_ACTIVE -> DEFAULT` | Focus leaves the card; `:focus-within` becomes false as the CSS candidate. | No focused descendant remains within the card, as a candidate guard only. | Candidate return to baseline; the exact change is unknown. | Unknown. | Unknown. | Unknown. | Unknown. | Not established. |

When pointer and focus overlap, native CSS can evaluate both conditions at once. The accepted evidence gives no ordering or precedence rule, and this preflight does not invent one. The transient CSS candidate has no terminal state. Accepted evidence neither requires nor rules out a separate persistent state.

## 7. CSS-only sufficiency criteria

`CSS_ONLY_CANDIDATE` requires accepted evidence for every criterion. No criterion below is contradicted by an accepted requirement, but the unknowns prevent that verdict.

| Criterion | Evidence status | Finding |
| --- | --- | --- |
| State derives only from pointer/focus conditions | Unknown | Pointer and focus presentation are recorded, but the full source interaction effect is not. |
| No state survives loss of hover/focus | Unknown | No persistence behavior is described. |
| No timer or asynchronous state | Unknown | The Romeo summary does not describe timer or async behavior. |
| No cross-card synchronization | Unknown | Four cards are recorded; coordination is not described. |
| No content/data change outside presentation | Unknown | The accepted summary does not describe the interaction effect beyond card presentation. |
| No ARIA mutation beyond link/focus semantics | Unknown | No interaction-specific ARIA behavior is recorded. |
| No DOM insertion, removal, or reparenting | Unknown | No DOM lifecycle is described. |
| No URL, history, or storage side effect | Unknown | Link presence is accepted; destinations and interaction side effects are not. |
| Keyboard users reach equivalent meaningful presentation | Partial | `focus-within` supplies a keyboard-related visual state, but equivalence and per-card focus behavior are unproved. |
| Touch/non-hover needs no separate managed-state contract | Unknown | Mobile column layout is recorded; touch interaction requirements are not. |
| Required styling has an accepted/current path, or only a styling gap remains | Unproven | Current selector helpers and native style generation are described in §8. Romeo style coverage is not accepted. |
| Cleanup needs no listener, timer, or observer teardown | Unknown | Source interactions are recorded, but lifecycle and teardown are not. |

There is no accepted requirement proving a CSS-unrepresentable side effect. There is also not enough evidence to prove the full CSS-only criteria. The result is therefore `EVIDENCE_INSUFFICIENT`, not a managed-behavior finding and not a CSS-only approval.

## 8. Current LiveFrames styling capability

### Static structure

The C09D6 native tag contract supports nested `container` nodes as `div` elements and `link` nodes as `a` elements with child content. This provides a source-neutral path for static linked-card structure. It does not establish Romeo's exact card-to-link mapping, link destinations, or an approved Romeo component contract.

### Stateful selectors and generation

- `LiveFrames.Fidelity.CSSDeclaration` accepts only `&:hover` and `&:focus-visible` state selectors. Its selector validator rejects other selector strings. `:focus-within` is not represented by this helper.
- The helper's serialization is not the native component styling path. `LiveFrames.NativeGenerator` currently returns a generated Elixir module artifact; C09D6 keeps package-owned CSS in a separate styling authority and requires a tracer-specific style-coverage preflight.
- Design IR can preserve `complex_css` or unresolved style values, but preservation is not CSS execution or proof of native selector support.
- C09D1 says source classes do not become public component inputs. If `.is-hover` were the active-state selector, reproducing that mechanism would require class mutation. Accepted evidence does not establish that this exact class exists, what it means, or that it must be retained. Native CSS pseudo-state could express the presentation without the source class if accepted semantics allow it.
- The present gap around `:focus-within` is a styling capability and style-authority gap. It does not prove managed behavior or a hook is required. Arbitrary source selectors must not be executed or added to preserve source syntax.
- The accepted BehaviorContract authority prefers native HTML/CSS when they satisfy the accepted semantics. A hook is required only when browser lifecycle, DOM reconciliation, or native-platform support requires it. Romeo's source use of pointer interactions does not establish any of those requirements.

The current code can represent static nested links. It does not provide accepted native Romeo styling for hover plus focus-within. A future style authority must map the required visual states to a bounded, source-neutral style representation and reject arbitrary selector execution.

## 9. Accessibility assessment

### `ACCESSIBILITY_REQUIREMENT`

Each of the four cards is described as linked. Keyboard users need a reachable link for each card and a visible focus-related presentation. The accepted `focus-within` fact shows a keyboard-related visual state, but does not prove it is meaningful or equivalent to hover. Evidence does not say whether the whole card or a child owns navigation, whether any content is hidden/revealed, whether hidden descendants remain focusable, or whether touch users lose essential information. No transition or reduced-motion requirement is established.

### `IMPLEMENTATION_DECISION`

Do not add ARIA attributes or focus mutation without accepted semantic evidence. Preserve native link/focus semantics when a future component contract is approved. Keep essential content available without hover, provide visible focus, and test touch/non-hover behavior as accessibility requirements are clarified. If motion is later evidenced, establish reduced-motion behavior in the style authority. This document does not choose exact markup or ARIA.

## 10. Security assessment

- **Unsafe `href` and open redirect:** Romeo's destinations and any destination allowlist are not established. A later generated link must use the existing validated static-navigation path or an explicitly authorized URL binding. This preflight does not approve any destination or its redirect policy.
- **Source classes and custom selectors:** Source classes are not public component inputs. Do not carry source `.is-hover` or source custom selectors into output as executable authority.
- **Arbitrary selector execution:** The bounded Fidelity declaration helper accepts only its two state selectors and rejects other selector values. Do not widen it to execute arbitrary source selectors for Romeo.
- **Generated/scoped selector collisions:** Use only package-owned selectors under a future accepted style authority. Romeo does not yet have an accepted style scope or collision proof; source IDs and classes do not supply one.
- **Hidden focusable content:** The accepted evidence does not say that content is hidden or revealed. A later mapping must ensure that CSS hiding does not leave required focusable content inaccessible.
- **Hover-only essential information:** Not established. Do not make essential information hover-only without an accessibility requirement and an equivalent keyboard/touch path.

No source code was executed. Imported source scripts and styles remain untrusted data.

## 11. Runtime and performance classification

For the CSS-only candidate path, browser CSS would own transient selector state. This is a conditional classification, not the final verdict:

```text
RUNTIME_STATE_OWNER=browser_css
DB_INDEX=N/A
CACHE=N/A
CACHE_TTL=N/A
REDIS=N/A
POSTGRES=N/A
OBAN=N/A
PUBSUB=N/A
SERVER_POLLING=N/A
PERFORMANCE_CLASS=O(cards)
```

No backend state or polling is appropriate for browser-local hover/focus presentation. The managed-behavior finding remains:

```text
MANAGED_BEHAVIOR_REQUIRED=NOT_PROVEN
BEHAVIOR_CONTRACT_MAPPING_REQUIRED=ONLY_IF_MANAGED_SEMANTICS_ARE_PROVEN
```

If accepted Romeo evidence later proves managed state or effects, map the exact semantic requirement through the accepted BehaviorContract authority. Interactive native generation still requires the separately defined behavior/componentization integration and normal C09D6 generation gates. This preflight does not design that mapping or runtime.

## 12. Evidence conflicts and gaps

There is no conflict between the accepted inventory and the conversion matrix. Both record hover/focus presentation and pointer interactions. The matrix expressly leaves the state effects, touch behavior, CSS coverage, accessibility evidence, and independent browser behavior unresolved. The accepted BehaviorContract authority now exists, but the missing Romeo source semantics still do not. That authority explains how accepted semantics should be represented and when native or hook realization is appropriate. It does not invent Romeo's mouseenter/mouseleave effects. C09D6's package-owned styling model does not prove Romeo's style coverage; it requires that coverage to be established before styling implementation.

The decision-changing missing facts are the exact mouseenter/mouseleave effects; whether state is transient or persists; pointer/focus overlap; DOM, content, or data changes; ARIA or focus effects; cross-card coordination; timers, asynchronous work, and cleanup; keyboard equivalence; and touch/non-hover semantics. A project-approved private-source evidence authority must accept any new source interpretation; C-07X currently supplies only the recorded historical summary. The static style/accessibility authority owns the source-neutral Romeo style and accessibility mapping. If the evidence proves presentation only, proceed toward bounded native CSS/style authority. If it proves managed state or effects, map the exact requirement into the accepted BehaviorContract model and satisfy the behavior/componentization integration gate.

## 13. Final verdict

```text
CSS_ONLY_CANDIDATE=NOT_PROVEN
MANAGED_BEHAVIOR_REQUIRED=NOT_PROVEN
VERDICT=EVIDENCE_INSUFFICIENT
STOP=PRIVATE_SOURCE_AUTHORITY_UNCLEAR
STYLE_AUTHORITY_REQUIRED=YES
FIDELITY_HOVER_SUPPORT=YES
FIDELITY_FOCUS_VISIBLE_SUPPORT=YES
FIDELITY_FOCUS_WITHIN_SUPPORT=NO
FOCUS_WITHIN_GAP=STYLING_CAPABILITY_GAP
FOCUS_WITHIN_GAP_IS_PROOF_OF_MANAGED_BEHAVIOR=NO
```

The accepted evidence does not justify managed behavior, but it also does not prove that every CSS-only sufficiency criterion holds. BehaviorContract authority now exists; Romeo's missing source semantics still do not. The missing facts cannot be supplied by interpreting proprietary implementation bodies under this preflight's authority. No CSS-only, native-ready, implementation-authorized, or browser-verified status is granted.

## 14. Required next authority

Obtain accepted Romeo semantic evidence that answers the unknown effects in §5 and §6, including exact mouseenter/mouseleave effects, transient versus persistent state, pointer/focus overlap, DOM/content/data effects, ARIA/focus effects, cross-card coordination, timers/asynchronous work/cleanup, keyboard equivalence, and touch/non-hover behavior. Then run a Romeo-specific style-coverage and accessibility authority against the approved Design IR, TokenSet, responsive data, and package styling rules. If evidence establishes presentation-only semantics, proceed toward bounded native CSS/style authority; use no hook when native HTML/CSS satisfies the contract. If evidence proves managed state or effects, map the exact requirement through the accepted BehaviorContract model and separately satisfy its behavior/componentization integration and native-generation gates. Do not define that mapping here.

## 15. Invalidation conditions

Revisit this verdict if any of the following changes:

- accepted Romeo evidence specifies interaction effects, link ownership, touch behavior, ARIA/focus effects, timers, persistence, or cleanup;
- the accepted `docs/09_INTERACTION_MODEL.md` authority revision 1.0.1 changes its source-neutral native-versus-hook rules; reconcile that behavior-authority assumption here, but do not treat the revision alone as new Romeo source evidence;
- an accepted Romeo style-coverage authority proves a bounded native selector representation, including focus behavior;
- LiveFrames changes its native style-generation path or selector allowlist;
- an accessibility authority requires a state or effect not expressible by CSS;
- the accepted source identity or provenance decision changes;
- the `origin/main` base or the post-merge CI identity for this branch is superseded.
