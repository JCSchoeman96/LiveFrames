# Feature Romeo source semantics authority

## 1. Purpose and non-goals

This document records source facts from the canonical private Feature Romeo
export. It resolves the source-effect gap identified in
`feature_romeo_css_sufficiency_preflight.md`.

This document does not decide whether LiveFrames should implement the
presentation with CSS, does not authorize CSS or behavior implementation, and
does not amend the preflight or conversion matrix. It does not implement
Romeo, create a component, or run componentization or native generation.
Private source content remains outside the public repository.

## 2. Current repository/base identity

```text
REPOSITORY=JCSchoeman96/LiveFrames
BASE_BRANCH=origin/main
BASE_SHA=bdc2b8b80a1ef8f0ffaa9f155d154144afae66e9
BASE_TREE=29a3798ac9864155eadb4dc7b024bb9fc1559b9b
LATEST_ACCEPTED_PR=192
DESIGN_IR_VERSION=4.0.0
INTERACTION_AUTHORITY_REVISION=1.0.2
BEHAVIOR_CONTRACT_VERSION=1.0.0
```

The fetched `origin/main` matched the expected SHA and tree. The current main
history includes PR #192; no intervening change conflicts with this bounded
evidence task. The repository worktree was clean before the audit.

## 3. Authority chain

The authorities govern separate claims:

| Authority | Claim owned here |
| --- | --- |
| `docs/04_SOURCE_AND_PROVENANCE.md` | Private/reference placement, evidence recording, and publication boundaries. Hashing or technical inspection does not establish redistribution permission. |
| `docs/03_DESIGN_IR_SPEC.md` | Design IR 4.0.0 structure. An `Interaction` records intent and does not select CSS, LiveView JS, hooks, server events, or LiveComponents. |
| `docs/09_INTERACTION_MODEL.md` | BehaviorContract 1.0.0 source-neutral behavior authority, revision 1.0.2. Private exports are evidence of source intent, not runtime authority. |
| `docs/development/c07x_unsupported_surface_inventory.md` | Accepted historical summary of Romeo's cards, pointer interactions, focus styling, and mobile layout. It does not record the complete interaction effects. |
| `docs/development/frames_native_conversion_matrix.md` | Programme order. Romeo's CSS-versus-managed-state question remains open, and CSS is the first candidate to assess. |
| `docs/development/feature_romeo_css_sufficiency_preflight.md` | Existing preflight and its unresolved facts. This document supplies source evidence only; the preflight remains unchanged. |
| `docs/development/c09c2_bricks_binding_mapping_authority.md` | Canonical corpus digest algorithm and inert-data inspection boundary. |
| `docs/development/c09d1_component_contract_authority.md` | Public component API boundary. |
| `docs/development/c09d3_componentization_plan_authority.md` | Input placement boundary. |
| `docs/development/c09d5_componentization_proposer_authority.md` | Explicit semantic-decision and proposer boundary. |
| `docs/development/c09d6_native_generation_authority.md` | Review-gated native generation and style-coverage boundary. |

Current repository authority and current `main` take precedence over historical
summaries. The C09D authorities were consulted for their scope and do not
authorize componentization or generation in this slice. No authority conflict
was found for the source facts recorded below.

## 4. Canonical private corpus identity

```text
CANONICAL_CORPUS=/home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/
CANONICAL_CORPUS_DIGEST=074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e
EXPECTED_CANONICAL_CORPUS_DIGEST=074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e
CANONICAL_CORPUS_DIGEST_MATCH=YES
CORPUS_RECORD_COUNT=34
```

The digest was recomputed over lexicographically sorted relative-path records
of `path<TAB>size<TAB>lowercase-sha256<NL>`, excluding `Archive.tar.gz`, then
SHA-256 hashed. The required external `fixtures`, `acss`, and
`private_reference` roots exist. Only the canonical Romeo directory was used
for source interpretation.

## 5. Exact Romeo artifact identity

```text
ROMEO_DIRECTORY=/home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/feature-section-romeo/
ROMEO_ARTIFACT=/home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/feature-section-romeo/bricks-component-eiwwbh-feature-section-romeo.json
ROMEO_ARTIFACT_SHA256=0cf29929a25bc2485ece90375d8c0f90fa1710eac0439bc5decc13af11f03f63
ROMEO_ARTIFACT_BYTES=24944
ROMEO_COMPONENT_ID=eiwwbh
ROMEO_ROOT_ELEMENT_ID=eiwwbh
ROMEO_ROOT_ELEMENT_TYPE=section
```

The directory has one JSON component export and three supplied screenshots.
The JSON was inspected as data. No screenshot was needed because the export's
CSS states the relevant visibility and responsive rules directly. No source
runtime was executed.

## 6. Observed structural facts

The artifact has one component record, 36 element records, and 17 global-class
records. Four `li` card roots use the global-class record that owns the
interactions. Their source element IDs are `28c2a3`, `640a40`, `07d0e9`, and
`336877`. Each card contains a heading element with its own string-valued
`settings.link.url` field. These link settings are separate from the
interaction records.

The interaction-owning global-class ID is `cIqHGddxkez`. The two interaction
records are `hnhofk` and `nafkin`. These private IDs appear only to correlate
the inspected source records. They are not LiveFrames public identifiers,
component inputs, or target selectors.

The complete export was checked for every `_interactions` occurrence and for
other effect-bearing fields across its component, elements, global classes,
settings, and CSS data. The single interaction occurrence is
`globalClasses[9].settings._interactions`. No second occurrence exists.

## 7. Observed interaction records

| Source record | Owner and target relationship | Trigger | Action and effect |
| --- | --- | --- | --- |
| `hnhofk` | Declared on global class `cIqHGddxkez`, used by the four card roots above. No separate target ID or selector is present in the record. | `mouseenter` | `setAttribute` with attribute key `class` and value `is-hover`. |
| `nafkin` | Same owner class and four card roots. No separate target ID or selector is present in the record. | `mouseleave` | `removeAttribute` with attribute key `class` and value `is-hover`. |

The action data names only the `is-hover` class value. It contains no content,
data, ARIA, focus, URL, storage, network, timer, or cross-card action. The
enter/leave pair is transient in the exported record: pointer entry sets the
class value, and pointer exit removes it. No toggle or persistent state action
is recorded. The export does not specify guards or an invalid-target fallback.

## 8. Observed presentation/style evidence

The owning class's custom CSS contains both the pointer-state selectors and
`:focus-within` selectors. The CSS groups pointer and focus conditions for the
same expanded presentation effects:

- The normal heading and lede change from zero opacity to visible opacity.
- The vertical heading changes from visible opacity to zero opacity.
- The overlay changes to zero opacity.
- The inner content's expanded-state opacity is nonzero.
- The lede has a translated expanded presentation.
- The currently focused descendant receives a separate outline rule under
  `:focus-within :focus`.

CSS transition declarations are present. These declarations describe visual
transitions; the export contains no timer action for them. The state selectors
are source CSS evidence only. The source class and `is-hover` value are not
LiveFrames public contracts or approved target selectors.

Pointer-active and focus-within presentation overlap: the grouped rules give
them the same expanded content treatment. Focus-within also supplies a focus
outline. They are not identical in every visual detail. No source rule defines
precedence when pointer and focus conditions are both true. Each condition
continues to apply according to its own browser state; the export records no
application-managed precedence rule.

## 9. Explicit lifecycle/state machine

The pointer class is a source event-action effect. `:focus-within` is a
browser selector condition, not an application-managed state record.

| State | Entry and exit | Guard | Side effect and presentation | Cross-card effect | Cleanup, persistence, invalid/no-op, terminal |
| --- | --- | --- | --- | --- | --- |
| `DEFAULT(i)` | Initial card condition when its pointer class is absent and no descendant is focused. | No guard is encoded. | Default CSS presentation. | None recorded. | No terminal state. Missing-target behavior is unspecified. No persistence is recorded. |
| `POINTER_ACTIVE(i)` | `DEFAULT(i) -- mouseenter --> POINTER_ACTIVE(i)`; `POINTER_ACTIVE(i) -- mouseleave --> DEFAULT(i)`. | Trigger is attached to the shared owner class; no further guard is encoded. | Set/remove the `is-hover` class value. CSS presents the expanded state. | No action references another card. | The leave action removes the class value. No other cleanup or persistence action is encoded. No terminal state. |
| `FOCUS_ACTIVE(i)` | Enters while browser focus is within a descendant of card `i`; exits when focus leaves the card. | Native `:focus-within` selector condition. | No event action is recorded. CSS presents the expanded state and focus outline. | No action references another card. | Browser selector condition ends with focus leaving. No persistence or application cleanup is encoded. No terminal state. |
| `POINTER_AND_FOCUS_ACTIVE(i)` | Both preceding conditions hold for the same card. | No precedence guard is encoded. | Grouped expanded rules overlap; the focus outline also applies. | No cross-card coordination is recorded. | Pointer class removal does not remove the independent focus selector condition. No terminal state. |

These states describe observed class and selector conditions. They do not
claim that the target requires an application state machine. The export does
not specify behavior for invalid targets or a missing event owner.

## 10. Responsive and touch/non-hover evidence

Responsive data records a `tablet_portrait` grid override that selects
`var(--grid-1)`; this document does not resolve that token's value. At
`mobile_landscape`, the containing layout direction is `column` and its row
gap uses the source grid-gap variable. The custom CSS also contains
`min-width: 767px` rules for the collapsed heading/inner opacity and
`max-width: 767px` rules that hide the overlay and vertical heading. At
widths below 767px, the desktop collapsed-opacity rules do not apply. The
mobile rules hide the overlay and vertical heading. The normal heading is not
hidden by the desktop rule, but the base lede opacity remains zero until a
pointer or focus state applies. At exactly 767px, both inclusive CSS media
conditions match; that source boundary overlap is recorded here, without
assigning precedence.

The interaction records use mouse entry and leave. No touch-specific action or
separate touch-active state is encoded. Below 767px the normal heading is
visible by default, while the lede remains at zero opacity until pointer or
focus presentation activates. The four heading link settings remain present.
The source does not label content as essential or specify how touch focus and
link activation interact, so this document records visibility rather than
making an accessibility or content-importance judgment.

## 11. Accessibility-relevant source facts

Each card root is a list item and has a heading descendant with a link setting.
The focus-within CSS applies the expanded presentation and a separate outline
to the focused descendant. No interaction record changes ARIA attributes or
moves focus. The artifact contains no `aria-*` source setting in the inspected
component records. These facts do not establish an accessibility acceptance
result.

## 12. Negative-effects audit

The bounded JSON has one interaction array with two records. The full export
contains no additional `_interactions` occurrence and no script/code, timer,
async, observer, listener, storage, or network action record. The exact source
effects observed are limited to setting and removing the `is-hover` class
value for presentation.

| Effect class | Bounded source observation |
| --- | --- |
| DOM nodes | No node insertion, removal, or reparenting action. A class-attribute action is present as described above. |
| Content or data | No content or data mutation action. |
| ARIA | No ARIA mutation action or source ARIA setting observed. |
| Script-controlled focus | No focus action. Focus styling uses the browser `:focus-within` condition. |
| Persistence | No storage or other persistence action. The pointer class is paired with a leave removal. |
| Timer or asynchronous work | No timer or asynchronous action. CSS transitions are presentation declarations. |
| URL, history, network | No interaction action changes URL/history or performs network work. Four card headings have separate link URL settings. |
| Cross-card coordination | No interaction target or reference names another card. No coordinator state is encoded. |
| Listener/observer/timer cleanup | No registration or cleanup record is present. The Bricks runtime that realizes event triggers is not part of this export, so its internal listener lifecycle is outside the evidence. |

`NON_PRESENTATION_SIDE_EFFECTS=NONE_OBSERVED_IN_BOUNDED_ROMEO_SOURCE` means
that the inspected export records no effect beyond the transient visual class
state. It is not a claim about code absent from the export.

## 13. Evidence limitations

The JSON records trigger and action data, class ownership, element usage,
link-setting presence, responsive settings, and custom CSS. It does not include
the Bricks runtime implementation. No JavaScript, PHP, Bricks, Frames,
WordPress, or ACSS runtime was executed. The artifact therefore cannot prove
how Bricks internally installs event listeners or cleans them up, nor does it
prove behavior outside the bounded Romeo component export. No browser behavior
or accessibility conformance was tested. Supplied screenshots were not
needed to resolve these source questions.

The source does not mark which text is essential. At desktop collapsed widths,
the normal heading, inner content, and lede are visually hidden until pointer
or focus presentation activates. Below 767px, the normal heading is visible by
default, while the lede remains visually hidden until pointer or focus
presentation activates. The source alone does not classify these visibility
facts as an information-access failure or establish touch-focus behavior.

## 14. Performance/runtime classification

This work is bounded build-time evidence inspection and documentation. It
introduces no runtime service or data dependency.

```text
DATA_LAYER=COLD_BUILD_TIME
HOT_DATA=N/A
WARM_DATA=N/A
REDIS=N/A
POSTGRES=N/A
PUBSUB=N/A
GENSERVER=N/A
OBAN=N/A
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
```

## 15. Final evidence verdict

The source records two pointer-triggered class actions and corresponding CSS
presentation. The bounded artifact shows no additional managed effect. This
verdict does not decide whether native CSS is semantically complete for
LiveFrames and does not authorize CSS implementation.

```text
PRIVATE_SOURCE_IDENTITY=VERIFIED
ROMEO_INTERACTION_EFFECTS=PROVEN
NON_PRESENTATION_SIDE_EFFECTS=NONE_OBSERVED_IN_BOUNDED_ROMEO_SOURCE
MANAGED_BEHAVIOR_REQUIRED_BY_SOURCE=NO_EVIDENCE
SOURCE_PRESENTATION_STATE=TRANSIENT
CSS_ONLY_ARCHITECTURE_AUTHORIZED=NO
NEXT_GATE=CSS_SUFFICIENCY_AND_STYLE_AUTHORITY_DECISION
```
