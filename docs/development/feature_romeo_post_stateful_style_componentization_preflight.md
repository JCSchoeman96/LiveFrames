# Feature Romeo Post-Stateful-Style Componentization Preflight

**Result:** `BLOCKED`

This document records the prior empty-authority public-adapter probe as
diagnostic evidence and corrects its authority interpretation. It does not
establish a canonical Romeo adapter context, create a contract or plan, run
Romeo native generation, or authorize implementation.

## Correction status: adapter authority applicability is unproven

The accepted records establish the identity and semantics of the Romeo export,
but do not establish that its source environment used the Automatic.css 4.0.1
settings represented by the accepted TokenSet fixture, or that ACSS grid
variables were enabled for that export. Canonical Romeo normalization stops at
this gate.

| Evidence | What it establishes | What it does not establish |
| --- | --- | --- |
| `feature_romeo_source_semantics_authority.md` §§4–5 | The private corpus and exact Romeo artifact identity, component ID, and hash | An ACSS version, settings-export identity, site/source-environment binding, or enabled grid-variable setting |
| `feature_romeo_css_style_authority.md` §§2, 4–7 | Romeo artifact identity, accepted presentation semantics, and source-neutral style requirements | The source environment's token or structural-variable authority |
| `docs/04_SOURCE_AND_PROVENANCE.md` and `fixtures/automatic_css/SOURCE.md` | The ACSS fixture is an internally approved deterministic adapter input with 4.0.1 reference provenance | A link between that fixture and the Romeo export |
| `docs/06_ACSS_TOKEN_ADAPTER.md` | The fixture's source version is caller-supplied reference metadata; structural grid authority requires explicit enabled evidence | Compatibility with an arbitrary Bricks export or proof that Romeo used that configuration |
| `docs/evidence/c09d6_d0e1_acss_4_0_1_grid_authority.md` | Scoped ACSS 4.0.1 values for `--grid-1`, `--grid-2`, and `--grid-3-2` | That Romeo's source configuration enabled those grid variables |
| CTA Tango records (`c09d6d`, `c09d7a`) | CTA Tango's own conversion used the 4.0.1 fixture and accepted structural authority | Applicability to Romeo |
| Feature Milan records (original and post-PR213) | Milan's own conversion used the 4.0.1 fixture and `:hero_foundation` profile | Applicability to Romeo |

The accepted fixture identity is
`fixtures/automatic_css/acss_settings.json` with SHA-256
`19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05`. The
scoped structural-grid evidence is real and remains accepted within its stated
scope; it does not identify Romeo's site configuration or prove that the grid
option was enabled there.

The provenance register has no Romeo source-environment record that binds the
canonical Romeo hash to the ACSS fixture or to the enabled structural-grid
configuration. The CTA and Milan precedents bind their own artifacts to their
normalization inputs only. A shared corpus directory, matching CSS variable
spelling, another component's successful conversion, and the profile name do
not supply the missing provenance. The named Bricks breakpoint mapping is
also unproven; the source's literal 767px media conditions remain separate,
direct source evidence.

```text
ROMEO_ACSS_AUTHORITY_APPLICABILITY=UNPROVEN
ROMEO_ACSS_APPLICABILITY_EVIDENCE=NO_ACCEPTED_SOURCE_ENVIRONMENT_BINDING
ROMEO_CANONICAL_ADAPTER_CONTEXT=UNRESOLVED
ROMEO_NAMED_BREAKPOINT_AUTHORITY=UNPROVEN
CANONICAL_ROMEO_ADAPTER_CONVERSION=NOT_RUN
```

No authorized-context conversion or residual recount was performed after this
gate failed. The prior empty-authority conversion is retained below only as a
diagnostic baseline. Its unresolved values are not classified as compiler
capability gaps, and no implementation plan is derived from them.

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
OLD_HEAD=900e27ba722c2fc50219d554d6583390794d57e5
OLD_TREE=fc61c6125d6aca404fcbe8ef63192f6d0dc61bb0
OLD_PUSH_CI=39016107204 SUCCESS
OLD_PR_CI=39016111272 FAILURE
OLD_PR_CI_FAILURE=AutomaticCSSAdapterTest global atom-count assertion
OLD_PR_CI_TEST_SEED=192258
OLD_PR_CI_FAILED_TEST=apps/live_frames/test/live_frames/automatic_css_adapter_test.exs:920
OLD_PR_CI_ATOM_COUNT=before:69279,after:69313
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

## Historical empty-authority diagnostic probe

The old probe decoded the export as data and passed it twice through the
public adapter with `TokenSet.new()` and without structural authority. This was
an empty-authority diagnostic, not an accepted Romeo source context. The prior
document incorrectly described its unresolved-value results as canonical
Romeo capability gaps. This correction withdraws that conclusion.

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
EMPTY_AUTHORITY_RUN_1=SUCCESS
EMPTY_AUTHORITY_RUN_2=SUCCESS
SOURCE_MUTATED=NO
EMPTY_AUTHORITY_IR_SERIALIZATION_IDENTICAL=YES
EMPTY_AUTHORITY_PROBE_STATUS=DIAGNOSTIC_ONLY
CURRENT_EMPTY_AUTHORITY_PROBE=DIAGNOSTIC_ONLY
EMPTY_AUTHORITY_RESIDUAL_COUNT=48
EMPTY_AUTHORITY_UNRESOLVED_VALUE_COUNT=32
ROMEO_TO_IR_AUTHORIZED_RUN_1=NOT_RUN
ROMEO_TO_IR_AUTHORIZED_RUN_2=NOT_RUN
AUTHORIZED_CONTEXT_RUN=NOT_RUN
AUTHORIZED_IR_SERIALIZATION_IDENTICAL=NOT_ESTABLISHED
AUTHORIZED_CONTEXT_RUN_1=NOT_RUN
AUTHORIZED_CONTEXT_RUN_2=NOT_RUN
AUTHORIZED_CONTEXT_RESIDUAL_COUNT=NOT_ESTABLISHED
AUTHORIZED_CONTEXT_UNRESOLVED_VALUE_COUNT=NOT_ESTABLISHED
SERIALIZER=LiveFrames.IR.encode!/1
IR_VERSION=4.0.0
TOKEN_SET_AUTHORITY_USED=NO_AUTHORITY_EMPTY_TOKENSET_DIAGNOSTIC_ONLY
STRUCTURAL_VARIABLE_AUTHORITY_USED=NO
NAMED_BREAKPOINT_AUTHORITY_USED=NO
ROMEO_PUBLIC_ADAPTER_NORMALIZATION=NOT_ESTABLISHED_FOR_CANONICAL_CONTEXT
```

The two historical documents produced identical `LiveFrames.IR.encode!/1`
bytes. This proves determinism only for that empty-authority diagnostic input;
it does not prove Romeo's canonical adapter context or complete source
coverage. The accepted ACSS `from_file/2` and structural-authority setup was
not invoked because applicability to Romeo is unproven.

## Diagnostic-only observation boundary

All DesignNode IDs, normalized style coverage, state-rule counts, residual
counts, and conversion diagnostics in the following sections come from the
historical empty-authority run. They are retained to make the prior evidence
auditable, not as a canonical Romeo conversion. The accepted Romeo source
authority continues to own the source semantics; the adapter findings below
must be reproduced only after the missing source-environment authority is
established.

## Four card owners: diagnostic normalized owner map

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

## Effective-layer and interaction proof: pinned positive findings

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

## Conditionless base and responsive presentation: empty-authority observations

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

## Stateful viewport and owner scope: pinned positive findings

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
STATE_RULE_COUNT_BASIS=EMPTY_AUTHORITY_DIAGNOSTIC_ONLY
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

## Empty-authority residual inventory: diagnostic only

The following inventory describes the previous empty-authority probe. It is
not a canonical Romeo residual classification. The four card owners each had
the same eleven `state_rules.residual` entries. Four additional legacy
`custom_css` values, one on each inner-content node, retained an unsupported
pseudo-element rule. The old probe therefore observed 48 residual source
rules. No new residual recount was run because Romeo's authority context is
unresolved.

| Observed residual meaning | Owner source ID(s) | Reason | Sanitized property inventory | Source meaning evidence | Diagnostic disposition |
| --- | --- | --- | --- | --- | --- |
| Card custom-property definitions used by presentation rules; names and values omitted | `28c2a3`, `640a40`, `07d0e9`, `336877` (one each) | `unresolved_value` | Custom-property declarations only | Referenced by presentation declarations; source-local values are not automatically ACSS TokenSet tokens | Cause and canonical support status not established |
| Card base layout | Same four card owners (one each) | `unresolved_value` | `flex-basis`, `height`, `isolation`, `min-height`, `overflow`, `position`, `transition` | Required base card presentation | Cause and canonical support status not established |
| Focused-descendant source suppression | Same four card owners (one each) | `unsupported_selector` | `outline`, `box-shadow` | Source focus suppression; accepted style authority forbids generating it | `SOURCE_FOCUS_SUPPRESSION`; inert only |
| Card corner treatment | Same four card owners (one each) | `unresolved_value` | `border-radius` | Visible card presentation | Cause and canonical support status not established |
| Normal-heading desktop collapsed default | Same four card owners (one each) | `unresolved_value` | `align-items`, `max-width`, `opacity`, `width` | Required collapsed/default presentation | Cause and canonical support status not established |
| Lede desktop collapsed default | Same four card owners (one each) | `unresolved_value` | `max-width`, `opacity`, `transition`, `translate`, `width` | Required collapsed/default presentation | Cause and canonical support status not established |
| Visible generated marker on linked heading pseudo-element | Same four card owners (one each) | `unsupported_selector` | `content`, `margin-left`, `order` | Presentation-bearing generated marker; no equivalent target appeared in the old IR | Potential visual selector gap; diagnostic only |
| Media/image geometry rule | Same four card owners (one each) | `unsupported_selector` | `height`, `min-height`, `min-width`, `position`, `width`, `z-index`; one custom property omitted | Presentation-bearing geometry; old IR represented only part of the image fit meaning | Potential visual selector gap; diagnostic only |
| Overlay unconditional default | Same four card owners (one each) | `unresolved_value` | `opacity`, `transition` | Required overlay default; mobile hiding and state presentation do not establish this default | Cause and canonical support status not established |
| Inner-content base presentation | Same four card owners (one each) | `unresolved_value` | `align-items`, `background-image`, `display`, `flex-direction`, `gap`, `height`, `justify-content`, `padding`, `position`, `transition`, `width`, `z-index` | Required base presentation; the old IR represented the 767px opacity only | Cause and canonical support status not established |
| Vertical-heading unconditional default | Same four card owners (one each) | `unresolved_value` | `inset-block-start`, `inset-inline-end`, `line-height`, `opacity`, `position`, `transition`, `translate` | Required default presentation; the old IR represented mobile hiding and state presentation | Cause and canonical support status not established |
| Inner-content pseudo-element paint and geometry | `3a2656` → `node_000001_000001_000002_000001_000004`; `dd9991` → `node_000001_000001_000002_000002_000004`; `35ade1` → `node_000001_000001_000002_000003_000004`; `27edbc` → `node_000001_000001_000002_000004_000004` | `unsupported_selector` (legacy inert `custom_css`) | `background-color`, `content`, `height`, `inset`, `position`, `width` | Accepted style authority treats pseudo-element residuals as potentially presentation-bearing, not decorative by default | Potential visual selector gap; diagnostic only |

The old output included 12 non-focus `unsupported_selector` records in addition
to four focus-suppression records. Those 12 selector residuals are an
independent review surface: token-value resolution cannot add selector or
pseudo-element grammar. They remain potential visual blockers, but their
count and classification have not been reproduced under an authorized Romeo
context. No pseudo-element was dismissed as decorative.

```text
EMPTY_AUTHORITY_RESIDUAL_SOURCE_RULE_COUNT=48
EMPTY_AUTHORITY_RESIDUAL_REASON_COUNTS=unresolved_value:32;unsupported_selector:16
EMPTY_AUTHORITY_SOURCE_FOCUS_SUPPRESSION_RESIDUALS=4
EMPTY_AUTHORITY_NON_FOCUS_UNSUPPORTED_SELECTOR_RESIDUALS=12
SOURCE_FOCUS_SUPPRESSION_RESIDUALS=4 (EMPTY_AUTHORITY_DIAGNOSTIC_ONLY)
CURRENT_EMPTY_AUTHORITY_REQUIRED_RESIDUAL_COUNT=44
CURRENT_EMPTY_AUTHORITY_UNRESOLVED_VALUE_COUNT=32
CANONICAL_REQUIRED_RESIDUAL_COUNT=NOT_ESTABLISHED
RESIDUAL_REASON_COUNTS=NOT_ESTABLISHED_FOR_CANONICAL_CONTEXT
CANONICAL_RESIDUAL_REASON_COUNTS=NOT_ESTABLISHED
CANONICAL_UNRESOLVED_VALUE_CAUSE_CLASSIFICATION=NOT_RUN
RESOLVED_BY_TOKEN_AUTHORITY=NOT_ESTABLISHED
RESOLVED_BY_STRUCTURAL_AUTHORITY=NOT_ESTABLISHED
STILL_UNRESOLVED_AFTER_ACCEPTED_AUTHORITY=NOT_ESTABLISHED
VISUALLY_REQUIRED_UNSUPPORTED_RESIDUALS=NOT_ESTABLISHED
UNKNOWN_REQUIREMENT_RESIDUALS=NOT_ESTABLISHED
```

The 32 historical `unresolved_value` entries are not declared compiler
capability gaps. Without the applicable token and structural authorities, the
probe cannot classify them as `NO_TOKEN_AUTHORITY`,
`TOKEN_AUTHORITY_UNRESOLVED`, `STRUCTURAL_AUTHORITY_NOT_APPLICABLE`,
`SOURCE_LOCAL_CUSTOM_PROPERTY_DEPENDENCY`, `COMPOUND_EXPRESSION_UNREPRESENTED`,
`UNSUPPORTED_VALUE_GRAMMAR`, or another proven cause. No values or variable
names are published here.

## Historical empty-authority diagnostic inventory

These are the diagnostic counts emitted by the old empty-authority probe;
they are not counts from an authorized Romeo conversion. No diagnostic is
ignored. The `unresolved_value` and `variable.unresolved` entries show what
the adapter reports without the applicable value authorities; they do not by
themselves prove a compiler capability gap.

| Diagnostic code | Severity/category | Empty-authority count | Current assessment |
| --- | --- | ---: | --- |
| `bricks.asset.unresolved` | warning / `asset_missing` | 4 | Separate asset-authority gap; no URI is invented. |
| `bricks.breakpoint.unresolved` | warning / `ambiguous_semantics` | 3 | Named source breakpoint authority remains unproven; no widths are assigned. |
| `bricks.custom_css.unresolved_value` | warning / `provenance` | 32 | Empty-authority observation only; unresolved cause and canonical support status are not established. |
| `bricks.custom_css.unsupported_selector` | warning / `provenance` | 16 | Four focus-suppression rules are inert by authority; twelve other selector residuals are potential presentation gaps, diagnostic only. |
| `bricks.navigation.unsupported_carrier` | warning / `ambiguous_semantics` | 4 | Separate heading-link navigation gap; the current `StaticNavigation` accepts `text-link` and static linked buttons, not heading carriers. |
| `bricks.setting.unsupported` | warning / `unsupported_style` | 13 | Separate source-setting gap; this old count is not a style residual count. |
| `bricks.variable.unresolved` | warning / `unresolved_token` | 25 | Empty-authority observation only; no Romeo token/structural authority has been established. |

```text
EMPTY_AUTHORITY_DIAGNOSTIC_ERROR_COUNT=0
EMPTY_AUTHORITY_DIAGNOSTIC_WARNING_COUNT=97
EMPTY_AUTHORITY_DIAGNOSTIC_INFORMATION_COUNT=0
EMPTY_AUTHORITY_UNCLASSIFIED_DIAGNOSTICS=0
EMPTY_AUTHORITY_DIAGNOSTIC_COUNTS=asset:4;breakpoint:3;custom_css.unresolved_value:32;custom_css.unsupported_selector:16;navigation:4;setting:13;variable:25
AUTHORIZED_CONTEXT_DIAGNOSTIC_COUNTS=NOT_ESTABLISHED

NAVIGATION_GAPS=4 heading-link carriers; source navigation authority required
ASSET_GAPS=4 unresolved asset diagnostics; asset authority required
SOURCE_SETTING_GAPS=13 unsupported-setting diagnostics; source-setting review required
NAMED_BREAKPOINT_GAPS=3 unresolved breakpoint diagnostics; mapping unproven
CUSTOM_CSS_RESIDUAL_GAPS=NOT_CANONICAL; empty-authority diagnostic only (48 residuals: 32 unresolved_value, 16 unsupported_selector)
VARIABLE_UNRESOLVED_COUNT=25 (EMPTY_AUTHORITY_DIAGNOSTIC_ONLY)
CUSTOM_CSS_UNRESOLVED_VALUE_COUNT=32 (EMPTY_AUTHORITY_DIAGNOSTIC_ONLY)
```

The current `StaticNavigation` limitation is a separate generic capability
boundary, not a custom-CSS residual. It remains a componentization-critical
gap even if a future authorized token context resolves all CSS values.

## Focus safety and source-leakage audit: pinned positive findings

The serialized Design IR retains source evidence in `SourceTrace`, `source_expression`, inert residuals, and diagnostic metadata. Executable state-rule records use generated `target_node_id` values and only the closed `hover` and `focus_within` conditions. Source interaction actions and the transient event class do not occur in executable state rules or the interaction registry.

```text
FOUR_OWNER_SCOPE_ISOLATION=PASS
HOVER_ALIAS_PROVEN=YES
FOCUS_WITHIN_RULES_PRESENT=YES
CROSS_CARD_TARGETS=0
MIN_767_PRESENT=YES
MAX_767_PRESENT=YES
SOURCE_FOCUS_SUPPRESSION_IN_GENERATABLE_RULES=NO
SOURCE_CLASS_AS_TARGET_SELECTOR=NO
IS_HOVER_AS_STATE_CONDITION=NO
SOURCE_EVENT_CLASS_IN_EXECUTABLE_RULES=NO
SOURCE_ACTION_AS_RUNTIME_BEHAVIOR=NO
SOURCE_TRACE_AND_RESIDUAL_EVIDENCE_REMAINS_INERT=YES
```

These are pinned positive results from the unchanged-source empty-authority
probe and the accepted source/style authorities. The exact source media bounds
remain separate as `min_width=767` and `max_width=767`; no named breakpoint is
inferred from them.

## Private-output handling

The review identified that the earlier diagnostic probe printed raw residual
text to transient local output. No private payload was committed or observed
in the public repository. This correction did not repeat that probe and
printed no raw private source, CSS body, JSON, or custom-property value.

```text
PRIOR_PROBE_TRANSIENT_RAW_RESIDUAL_OUTPUT=YES
CORRECTION_RAW_PRIVATE_SOURCE_PRINTED=NO
PRIVATE_PAYLOAD_COMMITTED=NO
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
CONVERSION_MATRIX_ROMEO_ROW=STALE_PENDING_AUTHORITY_APPLICABILITY_PREFLIGHT
```

After opening the preflight PR, stop. Do not merge, update the conversion matrix, create the Romeo contract, or create the Romeo plan.

## Required verdict

The existing empty-authority probe is deterministic and records useful
positive structural/state findings, but it is not an accepted Romeo
normalization context. The 44 previously reported required residuals and 32
unresolved values are provisional diagnostic counts; the canonical residual
count has not been established. No ACSS applicability, token cause, or
structural-variable cause has been inferred. The independent selector,
navigation, asset, source-setting, and named-breakpoint review families also
remain open. Browser accessibility acceptance is a later gate and is not
itself a componentization-readiness blocker. This evidence does not authorize
componentization.

```text
PRIVATE_SOURCE_IDENTITY=VERIFIED
GENERIC_STATEFUL_STYLE_PROGRAMME=ACCEPTED
ROMEO_ACSS_AUTHORITY_APPLICABILITY=UNPROVEN
ROMEO_CANONICAL_ADAPTER_CONTEXT=UNRESOLVED
EMPTY_AUTHORITY_PROBE_STATUS=DIAGNOSTIC_ONLY
CURRENT_EMPTY_AUTHORITY_REQUIRED_RESIDUAL_COUNT=44
CURRENT_EMPTY_AUTHORITY_UNRESOLVED_VALUE_COUNT=32
CANONICAL_REQUIRED_RESIDUAL_COUNT=NOT_ESTABLISHED
ROMEO_PUBLIC_ADAPTER_NORMALIZATION=NOT_ESTABLISHED_FOR_CANONICAL_CONTEXT
ROMEO_COMPONENTIZATION_READINESS=BLOCKED
BLOCKING_GAPS=
  - Romeo source-environment and ACSS authority applicability is unproven
  - canonical custom-CSS residual and unresolved-value counts are not established
  - 12 non-focus unsupported-selector findings remain a separate potential presentation blocker in the diagnostic baseline
  - named breakpoint authority is unproven
  - four heading link carriers lack normalized navigation semantics
  - unresolved assets and unsupported source settings require separate authority review
ROMEO_COMPONENTIZATION_AUTHORIZED=NO
ROMEO_IMPLEMENTATION_AUTHORIZED=NO
ROMEO_COMPONENT_CONTRACT_CREATED=NO
ROMEO_COMPONENTIZATION_PLAN_CREATED=NO
ROMEO_NATIVE_GENERATION_RUN=NO
BROWSER_ACCEPTANCE_COMPLETE=NO
NEXT_GATE=ESTABLISH_ROMEO_SOURCE_ENVIRONMENT_AND_ACSS_AUTHORITY
STOP=ROMEO_ADAPTER_INPUT_AUTHORITY_GAP
```
