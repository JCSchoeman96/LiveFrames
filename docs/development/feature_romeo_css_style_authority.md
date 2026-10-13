# Feature Romeo CSS style authority

## 1. Purpose and scope

This authority decides Feature Romeo's CSS sufficiency question and freezes a
generic, source-neutral representation for browser-derived component styling.
It authorizes a later implementation plan for generic stateful styling only.
It does not authorize production implementation, Romeo componentization,
ComponentContract or ComponentizationPlan creation, BehaviorContract
implementation, or native generation.

The accepted source-semantics authority remains
`feature_romeo_source_semantics_authority.md`. The older
`feature_romeo_css_sufficiency_preflight.md` remains a historical record of
the earlier unresolved evidence and is not amended here. Private evidence
remains read-only and is not copied into the public repository.

## 2. Authority and evidence identity

This decision follows the current Design IR, provenance, interaction, styling,
componentization, and native-generation authorities:

| Authority | Decision governed here |
| --- | --- |
| `docs/00_LIVEFRAMES_MASTER_SPEC.md` | Compiler boundaries, client-interaction hierarchy, and CSS-first presentation policy |
| `docs/03_DESIGN_IR_SPEC.md` | Design IR 4.0.0 and the existing `complex_css` meaning |
| `docs/04_SOURCE_AND_PROVENANCE.md` | Private-source handling and publication boundaries |
| `docs/09_INTERACTION_MODEL.md` | BehaviorContract 1.0.0, revision 1.0.2; native HTML/CSS where sufficient |
| `docs/11_CSS_AND_TAILWIND_STRATEGY.md` and `docs/20_P6_4A_NATIVE_STYLING_BRIDGE_ARCHITECTURE.md` | Package-owned static CSS, token boundary, and no request-time CSS generation |
| C09D1, C09D3, C09D5, C09D6, and C09D6-D authorities | Source-independent API, projection, generation, selector, and safe-style boundaries |
| `docs/development/c09d6d_upstream_style_gap_resolution_authority.md` | Accepted bounded custom-CSS normalization pattern and frozen Tango scope |
| `docs/development/feature_romeo_source_semantics_authority.md` | Accepted Romeo source semantics and private artifact identity |

The current base is `origin/main` at `8563a9b5f93594b98c8367c1de21df9e82067fc7`,
tree `2963284a6ca7d7bb0268bbfe38f5dd8f0345bcf4`. PR #194 is in its ancestry.
The intervening PR #195 and PR #193 changes affect README/package/roadmap and
C09C4 authority files only. No required authority file conflicts with this
slice. Open PRs #196 and #98 do not own either file changed here.

The canonical private Romeo JSON was read as inert data. Its SHA-256 matches
the accepted source authority:

```text
ROMEO_ARTIFACT_SHA256=0cf29929a25bc2485ece90375d8c0f90fa1710eac0439bc5decc13af11f03f63
ROMEO_ARTIFACT_MATCH=YES
SOURCE_RUNTIME_EXECUTED=NO
PRIVATE_PAYLOAD_COPIED=NO
```

## 3. Current implementation truth

The audited code has these properties on the accepted base:

| Surface | Current behavior |
| --- | --- |
| `LiveFrames.IR.StyleValue` | Includes `:complex_css`; `complex_css/2` accepts a map value. |
| `LiveFrames.IR.Validation` | Requires `complex_css` values to be JSON objects. It does not validate a closed state-rule subtype. |
| Bricks `DesignIRNormalizer` | Retains custom CSS under the `custom-css` style key as a `complex_css` object with source trace. |
| `BoundedCustomCssNormalizer` | Parses a bounded declaration/block subset, checks collisions and frozen rule matches, retains residual CSS, and records diagnostics. Its owner/child IDs, class, and selector table are frozen to CTA Tango. |
| `NativeGenerator.StyleValueCSS` | Serializes safe literals, keywords, token references resolved through TokenBridge, and the accepted structured multiply calculation. It rejects `:complex_css`. |
| `NativeGenerator.StylesheetRenderer` | Emits ordinary node rules, resolved max-width responsive rules, and same-node `:hover` / `:focus-visible` rules. It does not emit min-width rules. |
| `NativeGenerator.StyleIntegration` | Uses the closed `:hover` and `:focus_visible` pseudo path for primary-action styles. It has no generic `:focus-within` path or owner-to-descendant state-rule path. |
| `NativeGenerator.NodeStyleIdentity` | Derives deterministic private classes from canonical DesignNode traversal paths, not source identity. |

The current generator therefore does not serialize `complex_css`, does not
support generic state-owner-to-descendant targeting, and cannot represent the
required min-width condition. Existing same-node pseudo support is specific to
the approved primary-action styling path; it is not generic state-style
support.

## 4. Accepted Romeo presentation semantics

The export records four separate linked cards. Its pointer entry/leave actions
only add and remove a transient presentation class. The CSS associates pointer
and `:focus-within` conditions with the expanded card presentation. Focus is
browser-derived. The export records no cross-card coordination, content/data
mutation, ARIA mutation, scripted focus movement, timer, asynchronous work,
URL/history/storage mutation, or listener/observer registration. No state
persists after pointer or focus loss. CSS transitions are visual declarations,
not timer state.

These conditions describe browser presentation, not a required application
state machine:

| Condition | Entry and exit | Guard and viewport | Style effects | Cross-card effects | Persistence and cleanup | Invalid/no-op and terminal behavior |
| --- | --- | --- | --- | --- | --- | --- |
| `DESKTOP_DEFAULT(i)` | Applies when card `i` has neither pointer hover nor a focused descendant. It exits when either browser condition becomes true. | The collapsed heading, lede, and inner-content defaults are inside `@media (min-width: 767px)`. | Normal heading and lede are collapsed; vertical heading and overlay use the default presentation; inner content is collapsed. | None. | No state is stored. No cleanup runs. | No target lookup occurs. The condition is inactive outside its viewport rule. No terminal state. |
| `DESKTOP_POINTER_ACTIVE(i)` | Enters when the pointer hovers card `i`; exits when hover ends. | Browser `:hover`; desktop collapsed rules use the inclusive min-width query at 767px and above. | The card expands; normal heading, lede, and inner content use expanded presentation; vertical heading and overlay use their expanded presentation. | None. | Browser CSS recomputes the condition. No class mutation or persisted state is required. | If the pointer is not over the owner, the rule does not match. No terminal state. |
| `DESKTOP_FOCUS_WITHIN_ACTIVE(i)` | Enters when focus moves into a descendant of card `i`; exits when focus leaves its subtree. | Browser `:focus-within`; desktop collapsed rules use the inclusive min-width query at 767px and above. | Same expanded card/content presentation as pointer hover. The source also suppresses outline and box-shadow on the focused descendant; LiveFrames does not reproduce that suppression. | None. | Browser focus determines the condition. No application cleanup or persisted state is required. | With no focused descendant the rule does not match. No terminal state. |
| `DESKTOP_POINTER_AND_FOCUS_ACTIVE(i)` | Applies while both preceding browser conditions hold. Losing either condition leaves the other condition active if it still holds. | Conjunction of `:hover` and `:focus-within`; desktop collapsed rules use the inclusive min-width query. | Shared expanded presentation applies. Source evidence defines no precedence between the conditions. The focused descendant retains the LiveFrames visible-focus requirement. | None. | No shared or persisted state exists. Losing one condition does not clear the other. No cleanup runs. | If either condition is false, this combined condition ends. No terminal state. |
| `MOBILE_STATIC(i)` | Applies while the viewport matches the source mobile max-width query. It exits when that query no longer matches. | `@media (max-width: 767px)`, inclusive. At exactly 767px, both source media queries match. | The normal heading and lede are visible by default. The overlay and vertical heading are hidden. No hover or managed touch state is needed to reveal the heading or lede. | None. | Viewport and browser selector conditions are ephemeral; no state persists and no cleanup runs. | If the viewport does not match, this mobile rule is inactive. No terminal state. |

At exactly 767px, both `@media (min-width: 767px)` and
`@media (max-width: 767px)` match. Preserve these as distinct inclusive
conditions. The accepted source authority does not establish a net visual
result for every overlapping declaration, so this document does not infer one
or replace either boundary with a neighboring value.

Pointer and focus loss return presentation to the remaining browser-derived
condition or the default. There are no managed transitions, side effects,
cross-card effects, persistence, timer lifecycle, asynchronous work, or
application cleanup. The normal mobile heading and lede remain visible without
hover. Therefore:

```text
ROMEO_SOURCE_SEMANTICS=ACCEPTED
ROMEO_MANAGED_BEHAVIOR_REQUIRED=NO
ROMEO_BEHAVIOR_CONTRACT_RUNTIME_REQUIRED=NO
ROMEO_STATE_OWNER=BROWSER_CSS
ROMEO_CSS_SEMANTIC_SUFFICIENCY=PROVEN
SOURCE_MOUSEENTER_LEAVE_REPRODUCED=NO
SOURCE_IS_HOVER_CLASS_REPRODUCED=NO
```

## 5. Accessibility decision

The source declarations that suppress outline and box-shadow are evidence
about the source only. They are not LiveFrames target policy:

```text
SOURCE_FOCUS_SUPPRESSION_REPRODUCED=NO
VISIBLE_FOCUS_ACCEPTANCE_REQUIRED=YES
```

The generated target must retain a visible focus indication on the actual
focusable link or control. `:focus-within` may activate the expanded card
presentation. Do not add ARIA changes or scripted focus movement without new
semantic authority. Romeo acceptance still requires browser verification that
keyboard focus is visible and that focus-driven expansion works at the
required viewport widths.

Touch does not require managed state for this source because the normal mobile
heading and lede are visible by default. This does not remove the requirement
to verify the final touch layout in the later component acceptance gate.

## 6. Generic stateful style representation

Romeo needs generic stateful CSS support. It does not need source selectors or
source event-class mutation. The later implementation plan must use this
source-neutral path:

```text
bounded source parsing
    → resolve source selector meaning to DesignNode relationships
    → normalize closed state-style rules and retain separate provenance
    → Design IR StyleValue.complex_css
    → componentization consumes normalized nodes and rules only
    → NodeStyleIdentity supplies private owner/target classes
    → StylesheetRenderer emits closed selector forms and safe declarations
```

The semantic specialization is stored in the existing node style map under
the existing `custom-css` key as a `StyleValue` of kind `complex_css`. Its
value uses a closed subtype such as `type = "state_rules"` and a `rules` list.
The subtype name and its fields are semantic data, not CSS syntax. A rule
contains:

| Field | Required meaning |
| --- | --- |
| `owner_node_id` | Existing normalized DesignNode whose browser condition owns the state. |
| `condition` | Closed enum `hover` or `focus_within`. `focus_visible` remains an existing accessibility mechanism and is not part of this first state-rule enum. |
| `target_node_id` | Existing normalized DesignNode receiving the declarations. It may equal the owner or identify a descendant. |
| `declarations` | Non-empty CSS-property map to existing tagged StyleValue meanings. No raw CSS string value escape hatch. |
| `viewport` | Optional resolved condition with `min_width`, `max_width`, or both as finite non-negative numbers. Omit unbounded sides. CSS min/max inclusivity is preserved. |
| `order` | Non-negative integer assigned deterministically after semantic normalization. It resolves intentional cascade order; it is not copied from source selector text. |

`rules` are ordered by the validated `order` value. Duplicate or conflicting
order values fail closed unless a future authority defines a stable tie rule.
Source trace and source expressions remain provenance fields on the
`StyleValue`; they do not enter selectors, ordering, or declaration meaning.
Repeated pointer/focus conditions that produce the same target presentation
remain separate closed conditions and emit deterministic equivalent rules.

The renderer may emit only selectors built from generated private classes:

```text
.<owner-private-class>:hover
.<owner-private-class>:hover .<target-private-class>
.<owner-private-class>:focus-within
.<owner-private-class>:focus-within .<target-private-class>
```

Same-node rules omit the descendant suffix. Rules with a viewport are wrapped
in their resolved media condition. No source selector string reaches native
generation. No Romeo-specific branch belongs in `NativeGenerator`.

## 7. Design IR version gate

Design IR 4.0.0 already defines `complex_css` as structured selector/rule data
that needs a CSS renderer. Current validation accepts its value as a JSON
object, and the current generator's refusal to serialize it is a capability
gap, not a different IR meaning. The closed `state_rules` subtype specializes
that existing object value. It adds no DesignDocument root field, required
DesignNode field, serialized root shape, or migration behavior. Existing
validation compatibility remains unchanged; future subtype validation may
reject that subtype for generation without rejecting existing preserved
objects during general IR validation.

The future implementation must recognize only the closed subtype for
generation and leave unknown `complex_css` objects preserved but
non-generatable. If implementation needs a new required IR field, changes
what existing fields mean, changes migration behavior, or makes current valid
4.0.0 documents invalid, stop for explicit Design IR version authority. Do
not introduce a new IR version in the implementation plan.

```text
CAN_STATE_RULES_USE_EXISTING_COMPLEX_CSS_MEANING=YES
DESIGN_IR_VERSION_BUMP_REQUIRED=NO
```

## 8. Existing bounded custom-CSS pattern

CTA Tango proves a reusable normalization pattern, not a reusable rule table.
The future generic implementation may reuse:

- safe block and declaration parsing;
- fail-closed residual preservation with diagnostics;
- duplicate/collision detection;
- source-trace retention separate from semantic values; and
- deterministic matching infrastructure after source meaning is resolved.

Do not generalize or copy these as authority data:

- Tango owner or child IDs;
- Tango class names or selector strings;
- Romeo IDs, classes, or selector strings.

The Bricks adapter may parse a bounded source subset and map it to normalized
DesignNode relationships. Native generation receives only node references,
closed conditions, validated viewport values, declarations, deterministic
order, and trace metadata. Unhandled source CSS remains residual and is never
executed.

## 9. Capability matrix

`CURRENTLY_SUPPORTED` describes the current implementation in its existing
scope. `REQUIRES_GENERIC_EXTENSION` means the capability is absent or only
available in a special path and needs the generic state-style extension.
`FORBIDDEN` means no future implementation in this slice may enable it.

| Capability | Status | Required for Romeo | Current evidence / boundary |
| --- | --- | --- | --- |
| Same-node base declarations | `CURRENTLY_SUPPORTED` | Yes | Safe ordinary node rules are emitted. |
| Same-node `:hover` | `REQUIRES_GENERIC_EXTENSION` | Yes | Only the primary-action pseudo path is current; generic owner-state rules are absent. |
| Same-node `:focus-visible` | `CURRENTLY_SUPPORTED` | Yes, for visible focus on the focusable link/control | Existing primary-action accessibility path; preserve visible focus in target output. |
| Parent `:hover` to descendant styles | `REQUIRES_GENERIC_EXTENSION` | Yes | No state-owner-to-descendant selector generation exists. |
| Parent `:focus-within` to descendant styles | `REQUIRES_GENERIC_EXTENSION` | Yes | No generic `:focus-within` emission exists. |
| Multiple conditions producing identical target presentation | `REQUIRES_GENERIC_EXTENSION` | Yes | Normalize as distinct closed conditions and order deterministically. |
| `min-width` media condition | `REQUIRES_GENERIC_EXTENSION` | Yes | Current renderer supports only resolved `max-width` responsive rules. |
| `max-width` media condition | `CURRENTLY_SUPPORTED` | Yes | Existing resolved max-width node overrides; state-scoped max-width rules still need the generic extension. |
| State rules within a media condition | `REQUIRES_GENERIC_EXTENSION` | Yes | Current responsive and pseudo paths are separate. |
| Deterministic selector ordering | `REQUIRES_GENERIC_EXTENSION` | Yes | Existing ordinary/responsive ordering is deterministic; generic state-rule order is absent. |
| Private generated target classes | `CURRENTLY_SUPPORTED` | Yes | `NodeStyleIdentity` derives identity from canonical paths. |
| Safe declaration serialization | `CURRENTLY_SUPPORTED` | Yes | Existing safe property/value checks and StyleValue/TokenBridge serialization are the boundary to reuse. |
| `token_ref` values | `CURRENTLY_SUPPORTED` | Yes, when mapped by TokenBridge | Existing native serialization resolves approved package mappings. |
| Literal values | `CURRENTLY_SUPPORTED` | Yes, when safe | Existing native CSS value checks apply. |
| Structured calculations | `CURRENTLY_SUPPORTED` | Optional | Only the existing validated token-reference multiply contract serializes. |
| Raw custom CSS | `FORBIDDEN` | No | Residual or raw `complex_css` is not generatable. |
| Arbitrary selector strings | `FORBIDDEN` | No | Semantic input uses a closed enum and DesignNode references. |
| Source class selectors | `FORBIDDEN` | No | Source classes never become native selector authority. |
| Source event-class mutation | `FORBIDDEN` | No | Browser `:hover` owns pointer state; no event class is a public/runtime contract. |

## 10. Security, scope, and failure rules

The generic implementation must fail closed:

```text
ARBITRARY_SELECTOR_INPUT=FORBIDDEN
SOURCE_SELECTOR_EXECUTION=FORBIDDEN
SOURCE_CLASS_TO_PUBLIC_API=FORBIDDEN
SOURCE_CLASS_TO_NATIVE_SELECTOR=FORBIDDEN
STATE_CONDITION_ENUM=CLOSED
OWNER_NODE_REFERENCE=MUST_RESOLVE
TARGET_NODE_REFERENCE=MUST_RESOLVE
TARGET_MUST_BE_IN_COMPONENT_BOUNDARY=YES
CSS_PROPERTIES=MUST_PASS_EXISTING_SAFE_PROPERTY_BOUNDARY
CSS_VALUES=MUST_PASS_EXISTING_STYLEVALUE/TOKENBRIDGE SAFETY
UNKNOWN_COMPLEX_CSS_SUBTYPE=NOT_GENERATABLE
RAW/RESIDUAL_COMPLEX_CSS=NOT_GENERATABLE
```

Only literal string keys may select the closed subtype and condition clauses.
Never convert source strings to atoms, look up arbitrary functions/modules,
interpret browser expressions, or evaluate selector input. The component
boundary must contain both owner and target references; escaped, missing,
ambiguous, or unsupported references block generation with diagnostics. A
componentization step must not need source classes or selector text to recover
the rule meaning.

## 11. Performance and runtime ownership

The conditions are local browser presentation. No server-side state or service
is needed:

```text
STATE_OWNER=BROWSER_CSS
DATA_LAYER=COLD_BUILD_TIME
RUNTIME_SERVER_STATE=NONE
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
REDIS=N/A
POSTGRES=N/A
PUBSUB=N/A
GENSERVER=N/A
OBAN=N/A
SERVER_POLLING=N/A
CLIENT_COMPLEXITY=O(cards + emitted state rules)
```

## 12. Verdict and next gate

CSS is semantically sufficient for the accepted Romeo behavior. Generic stateful
style emission is not currently implemented, so CSS sufficiency does not mean
Romeo can be generated today. The next authorized work is a generic stateful
style implementation plan based on this contract. That plan must not
componentize Romeo or implement Romeo-specific generation. Browser verification
of visible focus remains a later Romeo acceptance requirement.

```text
ROMEO_SOURCE_SEMANTICS=ACCEPTED
ROMEO_MANAGED_BEHAVIOR_REQUIRED=NO
ROMEO_BEHAVIOR_CONTRACT_RUNTIME_REQUIRED=NO
ROMEO_STATE_OWNER=BROWSER_CSS
ROMEO_CSS_SEMANTIC_SUFFICIENCY=PROVEN

SOURCE_MOUSEENTER_LEAVE_REPRODUCED=NO
SOURCE_IS_HOVER_CLASS_REPRODUCED=NO

PARENT_STATE_DESCENDANT_TARGETING_REQUIRED=YES
FOCUS_WITHIN_REQUIRED=YES
MIN_WIDTH_RESPONSIVE_REQUIRED=YES

RAW_SOURCE_SELECTOR_EXECUTION=FORBIDDEN
SOURCE_FOCUS_SUPPRESSION_REPRODUCED=NO
VISIBLE_FOCUS_ACCEPTANCE_REQUIRED=YES

GENERIC_STATEFUL_STYLE_EXTENSION_REQUIRED=YES
CAN_STATE_RULES_USE_EXISTING_COMPLEX_CSS_MEANING=YES
DESIGN_IR_VERSION_BUMP_REQUIRED=NO

ROMEO_COMPONENTIZATION_AUTHORIZED=NO
ROMEO_IMPLEMENTATION_AUTHORIZED=NO
NEXT_GATE=GENERIC_STATEFUL_STYLE_IMPLEMENTATION_PLAN
STOP=NONE
```

This authority is invalidated by changed accepted Romeo source semantics,
changed Design IR 4.0.0 `complex_css` meaning, changed safe declaration or
TokenBridge boundaries, changed normalized node identity, or new evidence that
requires application-managed state.
