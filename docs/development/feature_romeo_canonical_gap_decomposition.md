# Feature Romeo canonical gap decomposition

## Decision record

This is a documentation-only architecture gate. It assigns every accepted
blocking finding to one source-neutral lane, records its authority state, and
orders future work. It does not authorize implementation, componentization,
or native generation.

```text
ACCEPTED_PR_236_APPROVED_HEAD=7574db396e1ea3ca2ebd4777cf3b091cd3b15ac4
ACCEPTED_PR_236_MERGE_SHA=db0c689c5e3277622e57873dc54f1b815a6370b0
ACCEPTED_PR_236_MERGE_TREE=110b153d576ecba74a744a045f0d604675d56f40
ACCEPTED_PR_236_POST_MERGE_CI=39064490618_SUCCESS

BASE_SHA=e1f31831f2fe4e1f8d836c1d668879d406272220
BASE_TREE=315cdc6b090a76cf0684d72e8ea999d81d4a6283
BASE_CI=39064498270_SUCCESS

CANONICAL_ROMEO_NORMALIZATION=ACCEPTED
IMPLEMENTATION_STARTED=NO
ROMEO_COMPONENTIZATION_READINESS=BLOCKED
ROMEO_COMPONENTIZATION_AUTHORIZED=NO
ROMEO_IMPLEMENTATION_AUTHORIZED=NO
ROMEO_NATIVE_GENERATION_AUTHORIZED=NO
```

The current main commit equals the accepted base. The fetched `origin/main`
has the same commit and tree. There is no intervening movement to review.
PR #236's accepted head is parent two of the signed merge. The canonical
normalization record remains unchanged.

The authority set for this review is the accepted Romeo source-semantics,
CSS-style, source-environment, conservative no-ACSS, canonical normalization,
post-stateful-style preflight, Design IR, source/provenance, Bricks adapter,
interaction-model, and generic stateful-style plan documents. The no-ACSS
context is binding. No external framework mapping, runtime, source fixture, or
new provenance is inferred here.

The implementation-owner review covered `CustomCssNormalizer`,
`StylePrecedence`, `StaticNavigation`, `DependencyExtractor`, `Settings`,
`DesignIRNormalizer`, and `StateRuleSet`, plus their corresponding tests.
Those owners retain their current fail-closed behavior. No production or test
file is changed by this record.

## Frozen count model

The 48 canonical residuals divide into 24 confirmed required residuals, 20
unknown-requirement blocking residuals, and four inert source-focus-suppression
residuals. The 44 blocking residuals are the first two sets. The four inert
focus findings are excluded from implementation work.

The 44 blocking CSS residuals comprise 20 source-local custom-property
findings, eight required compound-value findings, 12 unsupported-selector
findings, and four external-value-authority findings. Within those 44, the
confirmed required set is 16 local-property findings plus eight compound-value
findings. The unknown set is four local-property findings, 12 selector
findings, and four external-value findings.

Navigation, assets, source settings, and named breakpoints are independent
non-CSS gap counts. They are not residuals in the 48-item canonical residual
set. Custom-CSS diagnostics mirror residuals and are not counted again. This
record does not create a combined total across those sets.

```text
CANONICAL_RESIDUAL_COUNT=48
CANONICAL_CONFIRMED_REQUIRED_RESIDUAL_COUNT=24
CANONICAL_BLOCKING_UNKNOWN_RESIDUAL_COUNT=20
CANONICAL_BLOCKING_RESIDUAL_COUNT=44
CANONICAL_SOURCE_FOCUS_SUPPRESSION_RESIDUALS=4

CANONICAL_UNRESOLVED_VALUE_COUNT=32
SOURCE_LOCAL_CUSTOM_PROPERTY=20
EXTERNAL_VALUE_AUTHORITY_MISSING=4
UNSUPPORTED_COMPOUND_EXPRESSION=8
UNKNOWN_CAUSE=0

INDEPENDENT_NON_CSS_GAP_COUNTS=
  NAVIGATION_CARRIER:4
  ASSET_RESOLUTION:4
  SOURCE_SETTING:13
  NAMED_BREAKPOINT:3
  ACCESSIBILITY:0

SOURCE_FOCUS_SUPPRESSION_IN_GENERATABLE_IR=NO
VISIBLE_FOCUS_BROWSER_ACCEPTANCE_REQUIRED=YES
```

The four focus-suppression findings are inert under accepted authority. They
are assigned the disposition `INERT_BY_ACCEPTED_AUTHORITY`; they are not a
ninth work lane and do not create an accessibility implementation lane.

## Gate classes and lane lifecycle

Every blocker has exactly one primary gate class. Cross-lane dependencies are
recorded separately in the dependency table.

```text
GENERIC_CAPABILITY_CONFIRMED_REQUIRED
GENERIC_CAPABILITY_PENDING_AUTHORITY
SOURCE_REQUIREMENT_AUTHORITY_REQUIRED
EXTERNAL_PROVENANCE_REQUIRED
SOURCE_ASSET_EVIDENCE_REQUIRED
DUPLICATE_OR_NON_REQUIRED_REVIEW
INERT_BY_ACCEPTED_AUTHORITY
```

No blocking finding is currently classified as duplicate or non-required.
Those remain valid future outcomes only when accepted authority establishes
them. The inert focus findings have no primary blocker lane.

Each lane follows the same lifecycle:

```text
DISCOVERED
  -> REQUIREMENT_CLASSIFIED
  -> AUTHORITY_READY
  -> IMPLEMENTATION_READY
  -> IMPLEMENTED
  -> CANONICAL_RERUN_VERIFIED
  -> ACCEPTED
```

Allowed terminal blocked states are:

```text
BLOCKED_REQUIREMENT_UNKNOWN
BLOCKED_EXTERNAL_AUTHORITY
BLOCKED_SOURCE_EVIDENCE
BLOCKED_ARCHITECTURE_AUTHORITY
```

No lane may enter `IMPLEMENTATION_READY` while its required source, external,
or architecture authority remains unresolved. An implementation-ready
candidate is a planning status only; it does not authorize implementation.

## Authoritative lane table

The first four rows below are independent non-CSS gap counts. The CSS rows are
the 44 blocking members of the canonical residual set. They use the accepted
requirement classifications without rerunning or changing the canonical
normalization. Counts across these two sets are intentionally not summed.

| Lane ID | Canonical family | Canonical count | Confirmed required count | Unknown requirement count | Primary owning subsystem | Primary gate class | Authority/evidence prerequisite | Implementation dependency | Potential side-effect unlock | Implementation-ready candidate | Canonical rerun required | Terminal/current state |
| --- | --- | ---: | ---: | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `NAV-CARRIER` | Independent non-CSS: navigation carrier | 4 | 4 | 0 | `StaticNavigation`, then native renderer | `GENERIC_CAPABILITY_CONFIRMED_REQUIRED` | Accepted source authority establishes four heading link settings with string destinations, separate from interaction records. A source-neutral IR/rendering decision is still needed because current native anchor rendering accepts only `link` and `button` semantic types. | None among the other lanes. Requires the heading-link representation decision. | Makes the same bounded static-navigation carrier available to other generic Bricks heading nodes. It must not add runtime URL effects or alter heading semantics. | NO | YES, after any accepted capability change. | `BLOCKED_ARCHITECTURE_AUTHORITY` |
| `ASSET-RESOLUTION` | Independent non-CSS: asset resolution | 4 | 0 | 4 | `DependencyExtractor` and asset evidence pipeline | `SOURCE_REQUIREMENT_AUTHORITY_REQUIRED` | Inert source metadata classifies all four findings as placeholders. A source requirement decision must establish whether each placeholder is required. If required, obtain authorized identity evidence for that concrete asset. | None among the other lanes. Asset identity evidence follows a required classification. | Could make only evidence-backed asset references resolvable. It does not authorize substitutions, URL inference, or dynamic source execution. | NO | YES, if a later accepted capability changes Romeo IR. | `BLOCKED_REQUIREMENT_UNKNOWN` |
| `SOURCE-SETTING` | Independent non-CSS: unsupported source settings | 13 | 0 | 13 | `Settings` and `DesignIRNormalizer` | `SOURCE_REQUIREMENT_AUTHORITY_REQUIRED` | Requirement and semantic ownership review for every canonical finding. Sanitized category totals are layout: 4, other: 4, runtime: 4, typography: 1. These labels do not establish that a setting is required, already represented, or editor-only. | None established. Keep parallel with breakpoint and selector authority review. | Any accepted support may make the same setting category executable across other Bricks sources, including currently unknown runtime or editor-only meaning. Scope must stay source-neutral and bounded. | NO | YES, after any accepted capability change. | `BLOCKED_REQUIREMENT_UNKNOWN` |
| `NAMED-BREAKPOINT` | Independent non-CSS: named breakpoint | 3 | 0 | 3 | `Settings` breakpoint handling and responsive normalization | `SOURCE_REQUIREMENT_AUTHORITY_REQUIRED` | Determine for each associated setting whether its meaning is required, duplicates direct CSS, is non-required, or remains unknown. If required, obtain external breakpoint provenance. Accepted authority supplies no named mapping. | None established. The literal custom-CSS `767px` bounds are separate evidence and are not a mapping prerequisite. | A future mapping would make responsive behavior available to any generic source using that named breakpoint. It must not infer a numeric width or affect unrelated ranges. | NO | YES, after any accepted capability change. | `BLOCKED_REQUIREMENT_UNKNOWN` |
| `CSS-LOCAL-CUSTOM-PROPERTY` | Blocking residual: source-local custom property | 20 | 16 | 4 | `CustomCssNormalizer`, with effective-layer provenance from `StylePrecedence` | `GENERIC_CAPABILITY_PENDING_AUTHORITY` | Decide the requirement for the four unknown border-radius findings, or accept an explicit source-neutral policy that governs their execution. Define bounded scope and resolution semantics before implementation. | The eight compound values reference source-local definitions. Their resolved-value implementation depends on this lane. | **Yes.** A generic resolver could make the four currently unknown border-radius rules generatable. It could also affect declarations across owners, responsive rules, and states. No Romeo allowlist is permitted. | NO | YES, after any accepted capability change. | `BLOCKED_REQUIREMENT_UNKNOWN` |
| `CSS-COMPOUND-VALUE` | Blocking residual: unsupported compound expression | 8 | 8 | 0 | `CustomCssNormalizer.normalize_declaration_value/3` | `GENERIC_CAPABILITY_PENDING_AUTHORITY` | Requirement is confirmed. Define a closed, deterministic grammar from observed syntax and its value semantics. No general CSS expression evaluator is authorized. | The observed expressions reference source-local definitions. Grammar parsing can be designed in parallel, but resolved-value implementation depends on `CSS-LOCAL-CUSTOM-PROPERTY`. | Enables these syntax categories for generic Bricks CSS declarations. It may also unlock other declarations with the same shapes; source-neutral unknown-value policy must be explicit. | NO | YES, after any accepted capability change. | `BLOCKED_ARCHITECTURE_AUTHORITY` |
| `CSS-SELECTOR` | Blocking residual: selector or pseudo-element | 12 | 0 | 12 | `CustomCssNormalizer` selector grammar | `SOURCE_REQUIREMENT_AUTHORITY_REQUIRED` | Requirement review by sanitized shape: pseudo-element, 8; other unsupported selector geometry, 4. Each group needs a `REQUIRED`, `PROVEN_NON_REQUIRED`, `DUPLICATE_PRESENTATION_ALREADY_NORMALIZED`, or `UNKNOWN` decision. All 12 are currently unknown. | No dependency on variable or value grammar is established. | A closed extension could enable the same selector form throughout generic Bricks CSS. It must not enable arbitrary selectors, raw CSS passthrough, selector evaluation, or Romeo-specific tables. | NO | YES, after any accepted capability change. | `BLOCKED_REQUIREMENT_UNKNOWN` |
| `EXTERNAL-VALUE-AUTHORITY` | Blocking residual: external value authority missing | 4 | 0 | 4 | `CustomCssNormalizer` value authority boundary | `EXTERNAL_PROVENANCE_REQUIRED` | Supply new provenance that establishes the value meaning; prove the affected presentation non-required; or obtain explicit owner authority for a new source-neutral representation. These findings are not parser bugs. | No dependency on the local-variable or compound grammar lane is established. | New provenance could authorize these four meanings only. A new generic representation could affect other sources and needs its own closed authority. | NO | YES, if a later accepted representation changes Romeo IR. | `BLOCKED_EXTERNAL_AUTHORITY` |

The 13 source-setting findings retain `UNKNOWN_REQUIREMENT` individually. Their
sanitized category distribution is descriptive only. No finding is currently
classified as already represented, visually or semantically required, or
editor/source-only. The 13 approved canonical fingerprints are:

```text
2b95f3e6ffd078b1886e30b3dc530e13aec38991930ec4ce76655f1e4600d0dd
34160fc1baf552f46a0cff30b1b552365b65187cca66d12f1d953c5fea2b3d84
66f636f6de2f5c8ae9b27a63b8c4a62b2edc62e0411062355cb29dca6e2a98d4
695ad5b101baa309c17e5b34fcbe19be3c93b4473dd076169de652b08b849637
73b83ad27b2fa6e5f38a6fca19b7c21da2373de7bb48384e1b4beafbb1d293e0
92574be91dcf1465b63b717095ff7f60453f89307d1cd9424718fcc24e72c89e
9731bdb779d640c8dc40eb383192eefc7e58a8bbfca21163785662bcca1a7f9c
a4a4490318ea5278d78a3cbe226147eac372fa9655fab877b0715b951a5db88f
b422271028822837280ef1e7308d52aa7e28e13120868e4f222c6d6a89f5fc0e
b9bbf1a6d871a0eab11c2041b1c3dfc9399bd159a0f9cc959b0e2b48c77ac65a
cf4126866bec71597a502df80a351de8b6943340021efae092aff6cde5a61d51
fb901688858cc8b57a43f88005135668c5715089e31b1fe688a22cb59c7ee518
fdea3da6cf6c93554d8d694392ac99aa6ae3cd95979326ed242bac72cf90b764
```

## Lane authority findings

### `NAV-CARRIER`

Accepted source authority records a string-valued link URL on each of the four
headings. Those settings are separate from the pointer interaction records.
The interactions contain no URL, history, or network action. The source
therefore supports a static native navigation requirement; no runtime-only
navigation behavior is needed to represent the recorded link. Activation
details beyond the static destination are not specified by the export.

The current `StaticNavigation` owner deliberately rejects a heading with a
link object as `bricks.navigation.unsupported_carrier`. The source-neutral
`DesignNode` semantic type remains `heading`; renderer logic emits a static
anchor only for `link` or `button` semantic types. The current representation
therefore cannot produce an anchor while preserving heading semantics. The
lane needs an architecture decision on a generic heading-link representation
before implementation. It remains independent of styles, assets, settings,
and breakpoints.

The bounded future capability would accept validated static navigation on a
heading semantic node, retain heading semantics, and generate native anchor
markup using the existing destination safety checks. It would not create a
Romeo-specific branch, accept dynamic destinations, or add application-managed
navigation behavior.

```text
LANE_NAVIGATION_REQUIREMENT=CONFIRMED
LANE_NAVIGATION_GATE_CLASS=GENERIC_CAPABILITY_CONFIRMED_REQUIRED
NAVIGATION_DEPENDENCY_CLASS=INDEPENDENT
EXISTING_NATIVE_NAVIGATION_REPRESENTATION_SUFFICIENT=NO
```

### `CSS-COMPOUND-VALUE`

All eight findings are confirmed required. Safe inspection observed three
sanitized expression shapes:

```text
FUNCTION_CALL=2
MULTI_TOKEN_VALUE=5
VAR_REFERENCE_WITH_OPERATION=1
DISTINCT_EXPRESSION_SHAPES=3
```

The eight occurrences share the same generic declaration-value normalization
boundary in `CustomCssNormalizer.normalize_declaration_value/3`. The observed
shapes do not establish one interchangeable grammar production: function
calls, multi-token values, and a variable reference with an operation need
separate bounded grammar cases and semantics. They remain one lane because
they share one owner and one required-value normalization boundary. No general
CSS evaluator or arbitrary function execution is authorized.

```text
LANE_COMPOUND_VALUE_REQUIREMENT=CONFIRMED
DISTINCT_EXPRESSION_SHAPES=3
MULTIPLE_BOUNDED_GRAMMAR_CASES_REQUIRED=YES
MULTIPLE_INDEPENDENT_IMPLEMENTATION_LANES_REQUIRED=NO
```

The observed compound values depend on source-local definitions. Their
resolved-value implementation therefore waits for `CSS-LOCAL-CUSTOM-PROPERTY`
authority and a bounded resolver. The grammar can be designed in parallel,
but cannot enter `IMPLEMENTATION_READY` ahead of that authority.

### `CSS-LOCAL-CUSTOM-PROPERTY`

Sixteen findings are confirmed required. Four border-radius findings remain
`UNKNOWN_REQUIREMENT`; their classification does not change in this record.

```text
LOCAL_VAR_IMPLEMENTATION_WOULD_ENABLE_UNKNOWN_RULES=YES
```

A generic resolver that resolves and applies all discovered source-local
definitions would make those four unknown rules executable. Before
implementation, authority must either decide each affected requirement or
approve a source-neutral execution policy that governs such rules. A Romeo-only
allowlist would conceal the generic side effect and is prohibited.

Any future bounded resolver authority must address definition scope, owner
and class scope, multiple definitions, source order, inheritance, fallbacks,
cycles, self-reference, nested `var()` references, cross-owner leakage,
responsive and state scope, and custom-property names that resemble external
framework tokens. The resolver must use effective style-layer provenance and
must not become a browser cascade engine. The current record does not choose
those semantics.

### `CSS-SELECTOR`

The 12 findings split into eight pseudo-element shapes and four other
unsupported selector-geometry shapes. Every finding remains
`UNKNOWN_REQUIREMENT`. For each shape, source authority must decide whether its
effect is required, proven non-required, a duplicate of already normalized
presentation, or unknown. Unknown results remain blocking. Only required
shapes may inform a closed, source-neutral grammar. No source selector is
executed or passed through.

### `EXTERNAL-VALUE-AUTHORITY`

All four findings remain `UNKNOWN_REQUIREMENT` and
`EXTERNAL_VALUE_AUTHORITY_MISSING`. The no-ACSS context remains binding. The
allowed outcomes are new provenance for the value meaning, accepted proof that
the affected requirement is non-required, or explicit owner authority for a
new source-neutral representation. A provenance result must state its source,
scope, and supported values. No fixture, name, unrelated feature, or copied
conversion authority can supply that evidence.

### `SOURCE-SETTING`

The 13 canonical findings remain unknown. Inert-data inspection yielded only
these sanitized semantic category totals:

| Sanitized category | Count | Requirement status |
| --- | ---: | --- |
| Layout | 4 | Unknown for each finding |
| Other | 4 | Unknown for each finding |
| Runtime | 4 | Unknown for each finding |
| Typography | 1 | Unknown for this finding |

No category label proves that a setting is already represented, required, or
editor/source-only. All 13 findings therefore remain blocked until a source
owner classifies their meaning. Support must remain closed and generic; the
existence of settings keys does not authorize broad passthrough.

### `NAMED-BREAKPOINT`

The three named-breakpoint findings remain unknown. Accepted source authority
provides no named mapping. The literal custom-CSS `767px` bounds are direct
source evidence with separate semantics. They do not map any named breakpoint
and must not supply a width. Resolve each finding as required, duplicate of
direct CSS, non-required, or unknown. If a required meaning depends on a named
breakpoint, new external provenance is required before any implementation.

### `ASSET-RESOLUTION`

The four canonical `resolution_reason` findings are all
`unresolved_placeholder`. They are placeholders, not dynamic/runtime values
and not concrete identities recoverable from the current authorized evidence.
Whether each placeholder is a required visual asset remains unknown. First
obtain requirement authority. If an asset is required, obtain source-authorized
asset identity evidence. If proven non-required, record that disposition. Do
not infer a URL, filename, identifier, CDN location, or substitute.

## Cross-lane side-effect review

`GENERIC` does not mean side-effect free. The following scope applies to each
future lane:

| Lane ID | New syntax or semantic class enabled | Unknown Romeo findings also unlocked | Other compiler surfaces affected | Authority required before implementation |
| --- | --- | --- | --- | --- |
| `NAV-CARRIER` | Static navigation carried by a heading semantic node | None identified in the frozen inventory | Generic Bricks heading nodes and native rendering | Generic IR and renderer authority for a heading that retains heading semantics inside native link markup |
| `CSS-LOCAL-CUSTOM-PROPERTY` | Bounded local-definition lookup and substitution | Four unknown border-radius findings | Every supported custom-CSS owner, layer, responsive rule, and state rule | Decision on all four unknown rules or accepted generic policy; bounded resolution semantics |
| `CSS-COMPOUND-VALUE` | Three observed value shapes | No compound finding is currently unknown; shared syntax may match unreviewed values in other sources | Base, responsive, and state custom-CSS declarations | Bounded grammar and value semantics; local-variable authority first |
| `CSS-SELECTOR` | Only any individually accepted closed selector shapes | All 12 remain unknown until classified; none may be unlocked by implementation before a required decision | Generic Bricks custom-CSS selector normalization | Requirement decision for every proposed shape and closed grammar authority |
| `EXTERNAL-VALUE-AUTHORITY` | Only value meanings covered by new evidence or explicit owner authority | Four unknown external-value findings until resolved | Other sources only if a new generic representation is authorized | New provenance, non-required proof, or explicit representation authority |
| `SOURCE-SETTING` | Only individually accepted source-setting semantics | All 13 remain unknown until classified | Any Bricks source carrying the same setting category | Requirement classification and closed source-neutral setting authority |
| `NAMED-BREAKPOINT` | A named breakpoint only after its mapping is evidenced | All three remain unknown until classified | Responsive normalization for any consumer of the accepted name | Requirement outcome and external mapping if required |
| `ASSET-RESOLUTION` | Asset identity recovery only from authorized evidence | All four remain unknown until requirement is decided | Dependency extraction and downstream asset references | Requirement classification, followed by source asset evidence if required |

No row authorizes arbitrary CSS, raw selector execution, source runtime
execution, dynamic URL evaluation, or fallback to external framework tokens.

## Dependency DAG and parallel work

The lanes below are independent unless the table names a dependency. Authority
review can proceed in parallel across independent lanes. Code work remains
separate by subsystem and starts only after its own authority is accepted.

| Lane ID | Prerequisites | Can run in parallel with | Blocks | Blocked by |
| --- | --- | --- | --- | --- |
| `NAV-CARRIER` | Decide the generic heading-link IR and rendering contract; accepted source evidence is already available | Asset, source-setting, named-breakpoint, selector, external-value, and local-variable authority work | Its own implementation and post-change canonical rerun | `BLOCKED_ARCHITECTURE_AUTHORITY`; no dependency on style, assets, settings, or breakpoints |
| `ASSET-RESOLUTION` | Decide whether each placeholder is required; obtain source asset identity evidence only for required assets | Navigation, source-setting, named-breakpoint, selector, external-value, and local-variable authority work | Any evidence-based asset resolution PR | `BLOCKED_REQUIREMENT_UNKNOWN`, then `BLOCKED_SOURCE_EVIDENCE` if required |
| `SOURCE-SETTING` | Requirement and semantic-owner decision for each finding | Navigation, asset, named-breakpoint, selector, external-value, and local-variable authority work | One future settings capability PR per accepted subsystem responsibility | `BLOCKED_REQUIREMENT_UNKNOWN` |
| `NAMED-BREAKPOINT` | Per-finding requirement decision; external mapping if required | Navigation, asset, source-setting, selector, external-value, and local-variable authority work | A future breakpoint mapping capability, if required | `BLOCKED_REQUIREMENT_UNKNOWN`; no 767px mapping is available |
| `CSS-SELECTOR` | Per-shape requirement decision; closed grammar authority for shapes proven required | Navigation, asset, source-setting, named-breakpoint, external-value, and local-variable authority work | A future selector capability PR only for accepted required shapes | `BLOCKED_REQUIREMENT_UNKNOWN` |
| `EXTERNAL-VALUE-AUTHORITY` | New provenance, proof of non-requirement, or explicit owner authority | Navigation, asset, source-setting, named-breakpoint, selector, and local-variable authority work | A future value representation PR only if new authority calls for one | `BLOCKED_EXTERNAL_AUTHORITY` |
| `CSS-LOCAL-CUSTOM-PROPERTY` | Decide the four unknown border-radius rules or accept a source-neutral policy; define resolver scope and failure rules | Navigation, asset, source-setting, named-breakpoint, selector, and external-value authority work. Compound grammar design may proceed in parallel. | Resolved-value implementation for `CSS-COMPOUND-VALUE` | `BLOCKED_REQUIREMENT_UNKNOWN` and `BLOCKED_ARCHITECTURE_AUTHORITY` |
| `CSS-COMPOUND-VALUE` | Bounded grammar and semantic design; local-variable authority and resolver for resolved values | Grammar design may run alongside every independent authority lane | Compound-value implementation and its canonical rerun | `CSS-LOCAL-CUSTOM-PROPERTY` for implementation; syntax semantics for grammar acceptance |

There is no evidence-based dependency between heading navigation, asset
evidence, source-setting authority, named-breakpoint authority, selector
requirement authority, and external-value authority. They can be investigated
in parallel. The only established implementation dependency among the style
value lanes is that the eight compound values use source-local definitions.
Grammar design can proceed independently; resolved-value implementation
waits for the local-property resolver authority. No reverse dependency is
assumed.

## Recommended programme order

1. Review this decomposition and accept its authority boundaries. Keep all
   independent evidence and requirement investigations parallel.
2. Resolve the heading-link representation contract. If accepted, make
   `NAV-CARRIER` the first implementation slice. It is isolated from style,
   assets, settings, and breakpoints, but it is not implementation-ready in
   this record because the current renderer cannot preserve heading semantics
   while emitting navigation.
3. In parallel, classify the 13 settings, three named-breakpoint findings,
   12 selector findings, four asset placeholders, four external-value
   findings, and four unknown local-variable rules. Each evidence decision
   must stay in its own authority record or evidence PR.
4. If local-property authority permits the four unknown rules, design and
   implement the bounded source-neutral resolver in its own subsystem PR.
   Do not include compound grammar in that PR.
5. After local-variable resolution is accepted, implement the three bounded
   compound-value shapes in a separate value-grammar PR. Do not add a general
   evaluator.
6. Implement any selector, setting, breakpoint, value-provenance, or asset
   capability only after its own lane reaches `AUTHORITY_READY`. Keep one
   subsystem responsibility per PR.
7. Rerun canonical Romeo normalization after each accepted capability that
   can change Romeo IR. Record exact residual and requirement deltas without
   reclassifying unrelated findings. Verify deterministic output.
8. Reassess componentization readiness only after all canonical blockers have
   an accepted outcome. Visible-focus browser acceptance remains a later
   gate.

No lane currently reaches `IMPLEMENTATION_READY_CANDIDATE`. The first
recommended implementation lane is conditional on a generic navigation
representation decision. The first recommended authority lane is
`NAV-CARRIER` representation review. Independently, the highest-risk authority
review is `CSS-LOCAL-CUSTOM-PROPERTY` because a resolver would enable unknown
rules.

## Counting and privacy rules

```text
BLOCKING_RESIDUALS=44
INDEPENDENT_NON_CSS_GAP_COUNTS_REMAIN_SEPARATE=YES
CUSTOM_CSS_DIAGNOSTICS_ADDED_AGAIN=NO
GRAND_TOTAL_CREATED=NO
```

This record uses canonical fingerprints, approved counts, and sanitized
categories. It contains no private JSON, raw CSS, raw selector text, raw
custom-property names, private setting values, private asset URLs, or private
domains. Private exports were treated only as inert data. No source, CSS,
settings, or asset value was executed or copied into this record.

## Performance and runtime boundary

```text
DATA_LAYER=COLD_BUILD_TIME
HOT_DATA=N/A
WARM_DATA=N/A
COLD_DATA=DOCUMENTATION_AND_COMPILER_INPUT
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
REDIS=N/A
POSTGRES=N/A
CACHE=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
100K_CONCURRENT_USERS_IMPACT=NONE
CACHE_INVALIDATION=N/A
```

Any future parser or resolver must be bounded to component-size input and
produce deterministic output. No general CSS engine or unbounded browser
cascade simulation is authorized.

## Decomposition result

```text
LANE_NAMED_BREAKPOINT_GATE_CLASS=SOURCE_REQUIREMENT_AUTHORITY_REQUIRED
LANE_NAMED_BREAKPOINT_COMPONENTIZATION_BLOCKING=YES
NAMED_BREAKPOINT_FINDING_CLASSIFICATION=UNKNOWN:3
```

```text
LANE_COUNT=8
CANONICAL_BLOCKERS_ACCOUNTED_FOR=YES
BLOCKERS_WITHOUT_PRIMARY_LANE=0
BLOCKERS_WITH_MULTIPLE_PRIMARY_LANES=0

NAV_CARRIER_VERDICT=AUTHORITY_REVIEW_REQUIRED
CSS_COMPOUND_VALUE_VERDICT=DEPENDENT_ON_OTHER_LANE
CSS_LOCAL_CUSTOM_PROPERTY_VERDICT=AUTHORITY_REVIEW_REQUIRED
CSS_SELECTOR_VERDICT=AUTHORITY_REVIEW_REQUIRED
EXTERNAL_VALUE_AUTHORITY_VERDICT=EXTERNAL_EVIDENCE_REQUIRED
SOURCE_SETTING_VERDICT=AUTHORITY_REVIEW_REQUIRED
NAMED_BREAKPOINT_VERDICT=AUTHORITY_REVIEW_REQUIRED
ASSET_RESOLUTION_VERDICT=AUTHORITY_REVIEW_REQUIRED

LOCAL_VAR_IMPLEMENTATION_WOULD_ENABLE_UNKNOWN_RULES=YES
DEPENDENCY_DAG_STATUS=EXPLICIT; NO_UNSUPPORTED_CROSS_LANE_DEPENDENCIES
PARALLEL_AUTHORITY_LANES=NAV-CARRIER,ASSET-RESOLUTION,SOURCE-SETTING,NAMED-BREAKPOINT,CSS-SELECTOR,EXTERNAL-VALUE-AUTHORITY,CSS-LOCAL-CUSTOM-PROPERTY

IMPLEMENTATION_READY_CANDIDATE_LANES=NONE
AUTHORITY_REVIEW_REQUIRED_LANES=NAV-CARRIER,CSS-LOCAL-CUSTOM-PROPERTY,CSS-SELECTOR,SOURCE-SETTING,NAMED-BREAKPOINT,ASSET-RESOLUTION
EXTERNAL_EVIDENCE_REQUIRED_LANES=EXTERNAL-VALUE-AUTHORITY
NON_BLOCKING_LANES=NONE; INERT_FOCUS_SUPPRESSION_IS_NOT_A_LANE
DEPENDENT_LANES=CSS-COMPOUND-VALUE

FIRST_RECOMMENDED_IMPLEMENTATION_LANE=NAV-CARRIER_AFTER_GENERIC_REPRESENTATION_AUTHORITY
FIRST_RECOMMENDED_AUTHORITY_LANE=NAV-CARRIER_REPRESENTATION_REVIEW

PRODUCTION_FILES_CHANGED=NO
TEST_FILES_CHANGED=NO
CONVERSION_MATRIX_CHANGED=NO
IMPLEMENTATION_STARTED=NO
ROMEO_COMPONENTIZATION_READINESS=BLOCKED
ROMEO_COMPONENTIZATION_AUTHORIZED=NO
ROMEO_IMPLEMENTATION_AUTHORIZED=NO
ROMEO_NATIVE_GENERATION_AUTHORIZED=NO
```

The canonical blocker inventory has one primary lane per finding. No unknown
requirement is promoted. No external authority, named breakpoint value, or
asset identity is inferred. The decomposition does not begin componentization
or native generation.
