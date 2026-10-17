# Feature Romeo Post-Stateful-Style Componentization Preflight

**Result:** `BLOCKED`

This document records a read-only conversion of the canonical Feature Romeo export through the accepted public Bricks adapter. It does not create a contract or plan, run Romeo native generation, or authorize implementation.

## Repository and authority state

```text
BASE_SHA=6d681cbee6e5e715605e4761dd96961fa844141d
BASE_TREE=f2febc9a5c8670b362a4cb874c8a40a66b4875c9
BASE_CI=38709455133 SUCCESS
CURRENT_MAIN=6d681cbee6e5e715605e4761dd96961fa844141d
CURRENT_MAIN_TREE=f2febc9a5c8670b362a4cb874c8a40a66b4875c9
CURRENT_MAIN_CI=38709455133 SUCCESS
CURRENT_MAIN_MATCHED_AUTHORIZED_BASE=YES
INTERVENING_MAIN_FILES=NONE

TASK_7_MERGE_SHA=02c91ea620643e1ce038a51e0de2e7c82824e6a5
TASK_7_MERGE_TREE=f88da0c84627aa39bd943c1acc327892e2ce0d54
TASK_7_PARENT_1=18e5353115496fb3a18cbe6f881b8ddd2886a2aa
TASK_7_PARENT_2=81ea5c0d6d41099c055a01f9cf59bf0914085b86
TASK_7_MERGE_SIGNATURE=VERIFIED
TASK_7_POST_MERGE_CI=38709441971 SUCCESS
GENERIC_STATEFUL_STYLE_PROGRAMME=ACCEPTED

PREFLIGHT_BRANCH=docs/feature-romeo-post-stateful-style-preflight
```

`origin/main` matched the authorized base after fetch. The intervening PR #225 added only `docs/development/c09d7c2o0_cta_catalogue_owner_approval.md`; it changed no Romeo or compiler surface. The Task 7 merge is recorded with its exact approved head as parent two and a verified signature.

## Canonical private source identity

Only file identity and sanitized conversion evidence are recorded here. The private JSON and CSS bodies are not included.

```text
PRIVATE_CORPUS=/home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/
CORPUS_FILE_COUNT=34
EXPECTED_CORPUS_DIGEST=074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e
CORPUS_DIGEST=074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e
CORPUS_DIGEST_MATCH=YES

ROMEO_ARTIFACT=bricks-component-eiwwbh-feature-section-romeo.json
EXPECTED_COMPONENT_ID=eiwwbh
ROMEO_SHA256=0cf29929a25bc2485ece90375d8c0f90fa1710eac0439bc5decc13af11f03f63
EXPECTED_ROMEO_SHA256=0cf29929a25bc2485ece90375d8c0f90fa1710eac0439bc5decc13af11f03f63
ROMEO_BYTES=24944
EXPECTED_ROMEO_BYTES=24944
PRIVATE_SOURCE_IDENTITY=VERIFIED
```

## Public adapter boundary and determinism

The export was decoded as data and passed twice, unchanged, through the public adapter. The token setup is the accepted source-neutral empty `TokenSet` used by the merged Task 7 proof. No Romeo token profile, breakpoint map, or structural-variable mapping is established by the read authorities, so no such mapping was supplied. The optional structural-variable authority was omitted, leaving the adapter’s documented empty default.

```elixir
{:ok, document} =
  LiveFrames.Adapters.Bricks.to_ir(source,
    component_id: "eiwwbh",
    token_set: LiveFrames.Tokens.TokenSet.new()
  )
```

```text
PRIMARY_PROOF_PATH=LiveFrames.Adapters.Bricks.to_ir/2
PRIVATE_NORMALIZER_DIRECT_CALLS=NO
ROMEO_TO_IR_RUN_1=SUCCESS
ROMEO_TO_IR_RUN_2=SUCCESS
SOURCE_MUTATED=NO
IR_SERIALIZATION_IDENTICAL=YES
ROMEO_IR_DETERMINISTIC=YES
SERIALIZER=LiveFrames.IR.encode!/1
IR_VERSION=4.0.0
ROMEO_PUBLIC_ADAPTER_CONVERSION=PASS
ROMEO_PUBLIC_ADAPTER_NORMALIZATION=BLOCKED_BY_REQUIRED_RESIDUALS
```

The two independently returned documents produced identical `LiveFrames.IR.encode!/1` bytes. This proves deterministic conversion for the chosen supported input setup; it does not prove complete source coverage.

## Four card owners and normalized structure

Card owners were found by matching `source_trace.source_id`. Generated DesignNode IDs below are the IDs returned by the adapter, not hand-assigned IDs. Each card has six descendants, one heading node, and a source link setting retained as source evidence. The heading link is **not** normalized as native navigation: each heading has no normalized `navigation` attribute, and the adapter reports `bricks.navigation.unsupported_carrier`.

| Card source ID | Generated owner node ID | Type | Heading node ID | Source link setting | Normalized navigation |
| --- | --- | --- | --- | --- | --- |
| `28c2a3` | `node_000001_000001_000002_000001` | `generic` | `node_000001_000001_000002_000001_000004_000001` | Present in source evidence | No |
| `640a40` | `node_000001_000001_000002_000002` | `generic` | `node_000001_000001_000002_000002_000004_000001` | Present in source evidence | No |
| `07d0e9` | `node_000001_000001_000002_000003` | `generic` | `node_000001_000001_000002_000003_000004_000001` | Present in source evidence | No |
| `336877` | `node_000001_000001_000002_000004` | `generic` | `node_000001_000001_000002_000004_000004_000001` | Present in source evidence | No |

```text
CARD_OWNER_COUNT=4
FOUR_DISTINCT_OWNER_NODES=YES
FOUR_INDEPENDENT_CARD_SUBTREES=YES
HEADING_NODES_PRESENT=4
SOURCE_LINK_SETTINGS_PRESENT=4
NORMALIZED_NATIVE_NAVIGATION_NODES=0
```

## Effective-layer and interaction proof

For each card owner, the `custom-css` style provenance points to `class_refs[0].settings._cssCustom`; that reference resolves to the accepted interaction-owning source class `cIqHGddxkez`. In the same referenced source layer, both `_cssCustom` and `_interactions` are present, and the interaction pair is the exact reversible pair recorded by the source authority. The merged resolver passes that same effective provenance to transient interaction alias resolution. Each owner’s normalized state rules contain six `hover` rules and six `focus_within` rules.

```text
EFFECTIVE_LAYER_PROVENANCE_MATCH=YES
EFFECTIVE_LAYER_MATCHING_OWNER_COUNT=4
HOVER_ALIAS_PROVEN_FROM_EXACT_PAIR=YES
HOVER_RULE_COUNT=24
FOCUS_WITHIN_RULE_COUNT=24
FOCUS_WITHIN_RULES_PRESENT=YES
SOURCE_EVENT_CLASS_EXECUTED=NO
SOURCE_EVENT_CLASS_IN_EXECUTABLE_RULES=NO
```

The source interaction evidence is exactly `mouseenter + setAttribute(class, is-hover)` paired with `mouseleave + removeAttribute(class, is-hover)`. It is retained only as source evidence; the executable rules use `condition="hover"`.

`cIqHGddxkez` is source evidence only. It is not emitted as a selector, target, public API, contract field, or runtime behavior.

## Conditionless base and responsive presentation

The inventory below lists normalized target/property names only. It omits source CSS selectors and values. The same structural property pattern appears in each card subtree; target IDs are shown per card where the responsive rule is present.

| Required source meaning | Normalized target/property inventory | Result |
| --- | --- | --- |
| Unconditional card base | Each card owner has `align-items`, `display`, `flex-direction`, `flex-grow`. The source CSS card layout rule’s `flex-basis`, `height`, `isolation`, `min-height`, `overflow`, `position`, and `transition` remain residual. | Partial; required layout residuals remain |
| Unconditional overlay base | Per-card overlay nodes `node_000001_000001_000002_000001_000002`, `node_000001_000001_000002_000002_000002`, `node_000001_000001_000002_000003_000002`, `node_000001_000001_000002_000004_000002` have `background`, edge positioning, and `z-index`. The default `opacity` rule remains residual. | Partial; default opacity remains residual |
| Unconditional vertical-heading base | Per-card vertical-heading nodes `node_000001_000001_000002_000001_000003`, `node_000001_000001_000002_000002_000003`, `node_000001_000001_000002_000003_000003`, `node_000001_000001_000002_000004_000003` have color, typography, rotation, and writing-mode properties. Default position and opacity declarations remain residual. | Partial; required defaults remain residual |
| Desktop collapsed/default at `min-width: 767px` | Inner-content nodes `node_000001_000001_000002_000001_000004`, `node_000001_000001_000002_000002_000004`, `node_000001_000001_000002_000003_000004`, `node_000001_000001_000002_000004_000004` each have `opacity` in `custom_min_767`. Normal-heading and lede collapsed width/opacity declarations remain residual. | Partial; heading and lede defaults are missing |
| Mobile normal heading and lede default | No `custom_max_767` hiding override is emitted for the normal heading or lede. The desktop collapse rules remain scoped to `min-width: 767px`; below that bound these nodes have no normalized mobile hide rule. | Default visibility preserved |
| Mobile overlay hiding at `max-width: 767px` | Overlay targets listed above each have `display` in `custom_max_767`. | Present |
| Mobile vertical-heading hiding at `max-width: 767px` | Vertical-heading targets listed above each have `display` in `custom_max_767`. | Present |

The normal heading and lede nodes also retain source color styling, but the required collapsed desktop defaults are not represented by those base styles. Expanded state rules do not replace conditionless collapsed/default presentation.

```text
MIN_767_PRESENT=YES
MIN_767_CONDITIONLESS_TARGET_COUNT=4
MAX_767_PRESENT=YES
MAX_767_CONDITIONLESS_TARGET_COUNT=8
BOUNDARIES_REWRITTEN_TO_766_OR_768=NO
CONDITIONLESS_RESPONSIVE_OVERLAP_CONFLICTS=0
```

The emitted `ResponsiveOverride` records keep `custom_min_767` as `{min_width: 767.0, max_width: null}` and `custom_max_767` as `{min_width: null, max_width: 767.0}`. Both inclusive queries remain separate. No precedence is inferred at 767px. The source’s named responsive overrides also include unresolved breakpoint evidence; no widths were invented for them.

## Stateful viewport and owner scope

Each card owns twelve rules: one `hover` and one `focus_within` rule for each target row below. The table lists all generated target IDs and declaration properties. `viewport=null` is emitted for unscoped rules; the exact inclusive desktop viewport remains on the scoped heading and lede rules.

| Card source ID | Card owner target | Heading target | Lede target | Overlay target | Inner-content target | Vertical-heading target |
| --- | --- | --- | --- | --- | --- | --- |
| `28c2a3` | `node_000001_000001_000002_000001`; `viewport=null`; `cursor`, `flex-basis` | `node_000001_000001_000002_000001_000004_000001`; `{min_width: 767.0, max_width: null}`; `opacity` | `node_000001_000001_000002_000001_000004_000002`; `{min_width: 767.0, max_width: null}`; `opacity`, `translate` | `node_000001_000001_000002_000001_000002`; `viewport=null`; `opacity` | `node_000001_000001_000002_000001_000004`; `viewport=null`; `opacity` | `node_000001_000001_000002_000001_000003`; `viewport=null`; `opacity`, `translate` |
| `640a40` | `node_000001_000001_000002_000002`; `viewport=null`; `cursor`, `flex-basis` | `node_000001_000001_000002_000002_000004_000001`; `{min_width: 767.0, max_width: null}`; `opacity` | `node_000001_000001_000002_000002_000004_000002`; `{min_width: 767.0, max_width: null}`; `opacity`, `translate` | `node_000001_000001_000002_000002_000002`; `viewport=null`; `opacity` | `node_000001_000001_000002_000002_000004`; `viewport=null`; `opacity` | `node_000001_000001_000002_000002_000003`; `viewport=null`; `opacity`, `translate` |
| `07d0e9` | `node_000001_000001_000002_000003`; `viewport=null`; `cursor`, `flex-basis` | `node_000001_000001_000002_000003_000004_000001`; `{min_width: 767.0, max_width: null}`; `opacity` | `node_000001_000001_000002_000003_000004_000002`; `{min_width: 767.0, max_width: null}`; `opacity`, `translate` | `node_000001_000001_000002_000003_000002`; `viewport=null`; `opacity` | `node_000001_000001_000002_000003_000004`; `viewport=null`; `opacity` | `node_000001_000001_000002_000003_000003`; `viewport=null`; `opacity`, `translate` |
| `336877` | `node_000001_000001_000002_000004`; `viewport=null`; `cursor`, `flex-basis` | `node_000001_000001_000002_000004_000004_000001`; `{min_width: 767.0, max_width: null}`; `opacity` | `node_000001_000001_000002_000004_000004_000002`; `{min_width: 767.0, max_width: null}`; `opacity`, `translate` | `node_000001_000001_000002_000004_000002`; `viewport=null`; `opacity` | `node_000001_000001_000002_000004_000004`; `viewport=null`; `opacity` | `node_000001_000001_000002_000004_000003`; `viewport=null`; `opacity`, `translate` |

```text
STATE_RULE_OWNER_COUNT=4
STATE_RULE_RULE_COUNT=48
STATE_RULE_RESIDUAL_COUNT=44
STATE_RULES_PER_OWNER=12
STATE_RULE_VIEWPORT_TUPLES_PER_OWNER=viewport:null x 8; min_width=767.0,max_width=null x 4
CROSS_CARD_TARGETS=0
SIBLING_TARGETS=0
ANCESTOR_TARGETS=0
ESCAPED_BOUNDARY_TARGETS=0
OWNER_SCOPE_ISOLATION=PASS
FOUR_OWNER_SCOPE_ISOLATION=PASS
```

Every state target is the owning card or a descendant of that card’s exact normalized subtree. The four card subtrees have no shared DesignNode IDs.

## Residual inventory

The four card owners each contain the same eleven `state_rules.residual` entries. Four additional legacy `custom_css` values, one on each inner-content node, preserve one unsupported pseudo-element rule each. In total there are 48 residual source rules. The `custom_css` legacy subtype is inert and is not generatable under the accepted style authority.

| Residual meaning | Owner source ID(s) | Reason | Sanitized property inventory | Visible source effect? | Fully represented elsewhere? | Source authority proves non-required? | Classification |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Card custom-property definitions used by required layout/presentation rules; eight custom properties per owner, names and values omitted | `28c2a3`, `640a40`, `07d0e9`, `336877` (one each) | `unresolved_value` | Custom-property declarations only | Yes, through required declarations that depend on them | No | No | `VISUALLY_REQUIRED_UNSUPPORTED` |
| Card base layout | Same four card owners (one each) | `unresolved_value` | `flex-basis`, `height`, `isolation`, `min-height`, `overflow`, `position`, `transition` | Yes | No; some independent base styles exist, but these declarations are absent | No | `VISUALLY_REQUIRED_UNSUPPORTED` |
| Focused-descendant source suppression | Same four card owners (one each) | `unsupported_selector` | `outline`, `box-shadow` | Yes; it suppresses visible focus presentation | No; intentionally kept inert | No; authority instead forbids generating this suppression | `SOURCE_FOCUS_SUPPRESSION` |
| Card corner treatment | Same four card owners (one each) | `unresolved_value` | `border-radius` | Yes | No; no equivalent normalized value is established | No | `VISUALLY_REQUIRED_UNSUPPORTED` |
| Normal-heading desktop collapsed default | Same four card owners (one each) | `unresolved_value` | `align-items`, `max-width`, `opacity`, `width` | Yes | No; expanded state rules do not represent the collapsed default | No | `VISUALLY_REQUIRED_UNSUPPORTED` |
| Lede desktop collapsed default | Same four card owners (one each) | `unresolved_value` | `max-width`, `opacity`, `transition`, `translate`, `width` | Yes | No; expanded state rules do not represent the collapsed default | No | `VISUALLY_REQUIRED_UNSUPPORTED` |
| Visible generated marker on linked heading pseudo-element | Same four card owners (one each) | `unsupported_selector` | `content`, `margin-left`, `order` | Yes | No; the normalized heading has no equivalent generated marker or pseudo target | No | `VISUALLY_REQUIRED_UNSUPPORTED` |
| Media/image geometry rule | Same four card owners (one each) | `unsupported_selector` | `height`, `min-height`, `min-width`, `position`, `width`, `z-index`; one custom property omitted | Yes | Partial; image fit properties exist, but the residual geometry does not | No | `VISUALLY_REQUIRED_UNSUPPORTED` |
| Overlay unconditional default | Same four card owners (one each) | `unresolved_value` | `opacity`, `transition` | Yes | Partial; mobile hiding and state opacity are represented, but not this default | No | `VISUALLY_REQUIRED_UNSUPPORTED` |
| Inner-content base presentation | Same four card owners (one each) | `unresolved_value` | `align-items`, `background-image`, `display`, `flex-direction`, `gap`, `height`, `justify-content`, `padding`, `position`, `transition`, `width`, `z-index` | Yes | Partial; the `min-width: 767px` opacity is represented, but the base layout and background are not | No | `VISUALLY_REQUIRED_UNSUPPORTED` |
| Vertical-heading unconditional default | Same four card owners (one each) | `unresolved_value` | `inset-block-start`, `inset-inline-end`, `line-height`, `opacity`, `position`, `transition`, `translate` | Yes | Partial; mobile hiding and state presentation are represented, but the base position/default is not | No | `VISUALLY_REQUIRED_UNSUPPORTED` |
| Inner-content pseudo-element paint and geometry | `3a2656` → `node_000001_000001_000002_000001_000004`; `dd9991` → `node_000001_000001_000002_000002_000004`; `35ade1` → `node_000001_000001_000002_000003_000004`; `27edbc` → `node_000001_000001_000002_000004_000004` | `unsupported_selector` (legacy inert `custom_css`) | `background-color`, `content`, `height`, `inset`, `position`, `width` | Yes | No; no generated pseudo-element target or equivalent paint layer exists | No | `VISUALLY_REQUIRED_UNSUPPORTED` |

The pseudo-element residuals are not treated as decorative or non-required. Their generated content, paint, and geometry affect visible presentation, and the normalized IR contains no equivalent pseudo-element target. The accepted source evidence does not authorize dropping them.

```text
ROMEO_RESIDUAL_SOURCE_RULE_COUNT=48
RESIDUAL_REASON_COUNTS=unresolved_value:32;unsupported_selector:16
SOURCE_FOCUS_SUPPRESSION_RESIDUALS=4
DUPLICATE_PRESENTATION_RESIDUALS=0
NON_REQUIRED_RESIDUALS=0
VISUALLY_REQUIRED_UNSUPPORTED_RESIDUALS=44
UNKNOWN_REQUIREMENT_RESIDUALS=0
```

## Diagnostics inventory

Every adapter warning is counted below. There were no error or fatal diagnostics. `bricks.custom_css.unsupported_selector` includes twelve entries in the card owners’ `state_rules.residual` arrays and four legacy pseudo-element residuals on inner-content nodes.

| Diagnostic code | Severity/category | Count | Assessment |
| --- | --- | ---: | --- |
| `bricks.asset.unresolved` | warning / `asset_missing` | 4 | Asset resolution authority gap; no URI is invented. |
| `bricks.breakpoint.unresolved` | warning / `ambiguous_semantics` | 3 | Source breakpoint authority gap; unresolved source breakpoints remain unresolved. |
| `bricks.custom_css.unresolved_value` | warning / `provenance` | 32 | Required CSS values remain inert residuals because no accepted token/structural-variable mapping resolves them. |
| `bricks.custom_css.unsupported_selector` | warning / `provenance` | 16 | Four focus-suppression rules are expected inert evidence. The other eight card residuals and four legacy pseudo-element rules are required presentation gaps. |
| `bricks.navigation.unsupported_carrier` | warning / `ambiguous_semantics` | 4 | Heading link settings remain source evidence; the adapter does not establish safe normalized navigation. |
| `bricks.setting.unsupported` | warning / `unsupported_style` | 13 | Unsupported source settings remain outside normalized IR semantics; capability gap. |
| `bricks.variable.unresolved` | warning / `unresolved_token` | 25 | Source variables have no authorized token/variable mapping; authority gap. |

```text
DIAGNOSTIC_ERROR_COUNT=0
DIAGNOSTIC_WARNING_COUNT=97
DIAGNOSTIC_INFORMATION_COUNT=0
UNCLASSIFIED_DIAGNOSTICS=0
```

## Focus safety and source-leakage audit

The serialized Design IR retains source evidence in `SourceTrace`, `source_expression`, inert residuals, and diagnostic metadata. Executable state-rule records use generated `target_node_id` values and only the closed `hover` and `focus_within` conditions. Source interaction actions and the transient event class do not occur in executable state rules or the interaction registry.

```text
SOURCE_FOCUS_SUPPRESSION_IN_GENERATABLE_RULES=NO
SOURCE_CLASS_AS_TARGET_SELECTOR=NO
IS_HOVER_AS_STATE_CONDITION=NO
SOURCE_EVENT_CLASS_IN_EXECUTABLE_RULES=NO
SOURCE_ACTION_AS_RUNTIME_BEHAVIOR=NO
SOURCE_TRACE_AND_RESIDUAL_EVIDENCE_REMAINS_INERT=YES
```

## Componentization and browser boundaries

```text
ROMEO_COMPONENT_CONTRACT_CREATED=NO
ROMEO_COMPONENTIZATION_PLAN_CREATED=NO
ROMEO_COMPONENTIZATION_PROPOSER_RUN=NO
ROMEO_NATIVE_GENERATION_RUN=NO
PACKAGE_ARTIFACT_GENERATION_RUN=NO
BROWSER_EXECUTION_RUN=NO
BROWSER_ACCEPTANCE_COMPLETE=NO
```

Later browser acceptance must still check visible keyboard focus, focus-within expansion, pointer expansion, mobile/touch layout, and inclusive behavior around 767px. That work is not part of this preflight.

```text
DATA_LAYER=COLD_BUILD_TIME
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
REDIS=N/A
POSTGRES=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
CACHE=N/A
```

## Matrix and next gate

The Romeo row in `docs/development/frames_native_conversion_matrix.md` still reflects the historical pre-extension state, including missing `:focus-within` capability. It was not changed here.

```text
CONVERSION_MATRIX_ROMEO_ROW=STALE_PENDING_THIS_PREFLIGHT
```

After opening the preflight PR, stop. Do not merge, update the conversion matrix, create the Romeo contract, or create the Romeo plan.

## Required verdict

The public adapter converts Romeo deterministically and proves owner isolation, hover aliasing, focus-within rules, and separate 767px conditionless bounds. The source does **not** map completely enough into the accepted generatable IR: required base and responsive declarations remain unresolved, pseudo-element presentation remains unsupported, and other source authorities remain unresolved in diagnostics. This evidence does not authorize componentization.

```text
ROMEO_COMPONENTIZATION_READINESS=BLOCKED
BLOCKING_GAPS=
  - 44 visually required unsupported residual rules, including required card, heading, lede, media, overlay, inner-content, vertical-heading, and pseudo-element presentation
  - no approved token or structural-variable mapping for unresolved source CSS values
  - unresolved named source breakpoints
  - four heading link carriers lack normalized navigation semantics
  - unresolved assets and unsupported source settings remain diagnostic gaps
ROMEO_COMPONENTIZATION_AUTHORIZED=NO
ROMEO_IMPLEMENTATION_AUTHORIZED=NO
NEXT_GATE=RESOLVE_REPORTED_AUTHORITY_OR_CAPABILITY_GAP
STOP=ROMEO_REQUIRED_RESIDUAL_UNRESOLVED
```
