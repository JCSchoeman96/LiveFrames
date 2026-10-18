# Feature Romeo canonical rerun after NAV-CARRIER

## Scope and authority

This record captures two fresh no-ACSS normalizations after the accepted
NAV-CARRIER implementation. Each run used the public Bricks adapter and ended
at its validated Design IR. The rerun does not create a component contract or
plan, run NativeGenerator, or authorize implementation.

The starting repository authority was:

```text
BASE_SHA=f75c9a19fb1965648b6e4c6dce2c88e4c376f014
BASE_TREE=1ee056644312c65acb006d4f48c84d8ab16cfae1
BASE_CI=39119253153 SUCCESS
CURRENT_MAIN=f75c9a19fb1965648b6e4c6dce2c88e4c376f014
CURRENT_MAIN_TREE=1ee056644312c65acb006d4f48c84d8ab16cfae1
CURRENT_MAIN_CI=39119253153 SUCCESS
MAIN_MOVEMENT_DURING_RERUN=NONE

PR_244_APPROVED_HEAD=cf5bc7b735c5f13821736759d890b44184533ae0
PR_244_MERGE_SHA=d5e2421f64766dffe328bc992e357e1854308fa2
PR_244_MERGE_TREE=4cdf14fb99cf8b42b620bb31c1569cbd2ec169b5
PR_244_POST_MERGE_CI=39119235318 SUCCESS
```

The five required authority records were read. The current Bricks adapter,
DesignIRNormalizer, and StaticNavigation implementation were inspected and
left unchanged.

## Canonical source and no-ACSS context

The canonical corpus and exact Romeo artifact were hashed before normalization.
The corpus digest used lexicographic relative paths and records of
`path<TAB>size<TAB>lowercase-sha256<NL>`, excluding `Archive.tar.gz`.

```text
CANONICAL_SOURCE=private_reference/frames/staging-2026-09/feature-section-romeo/bricks-component-eiwwbh-feature-section-romeo.json
CORPUS_RECORDS=34
CORPUS_DIGEST=074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e
CORPUS_DIGEST_MATCH=YES
ROMEO_SHA256=0cf29929a25bc2485ece90375d8c0f90fa1710eac0439bc5decc13af11f03f63
ROMEO_SHA256_MATCH=YES
ROMEO_BYTES=24944
ROMEO_BYTES_MATCH=YES
COMPONENT_ID=eiwwbh
COMPONENT_ID_MATCH=YES

CANONICAL_CONTEXT=public LiveFrames.Adapters.Bricks.to_ir/2; component_id=eiwwbh; fresh empty TokenSet.new() per run
ACSS_FIXTURE_LOADED=NO
ACSS_PROFILE_SELECTED=NO
ACSS_SOURCE_VERSION_ASSIGNED=NO
STRUCTURAL_VARIABLE_AUTHORITY_SUPPLIED=NO
NAMED_BREAKPOINT_AUTHORITY_SUPPLIED=NO
ROMEO_CANONICAL_EXTERNAL_TOKEN_AUTHORITY=NONE
ROMEO_CANONICAL_ACSS_AUTHORITY=NONE
ROMEO_CANONICAL_STRUCTURAL_VARIABLE_AUTHORITY=NONE
ROMEO_CANONICAL_NAMED_BREAKPOINT_AUTHORITY=NONE
```

Each invocation supplied only the canonical source path, `component_id`, and a
fresh empty `TokenSet`. It supplied no ACSS fixture or profile, source version,
structural-variable or named-breakpoint authority, external token mapping,
Milan authority, or CTA authority.

## Independent normalization runs

Each run read the source path again, created a new empty TokenSet, called only
`LiveFrames.Adapters.Bricks.to_ir/2`, received a `DesignDocument`, and
serialized it with `LiveFrames.IR.encode!/1`.

```text
CANONICAL_RUN_1=SUCCESS
CANONICAL_RUN_2=SUCCESS
IR_SHA256_RUN_1=97838ec71153c1e0fe8b54baf58765417d9d9e9ef5b02c2bfbd1c130ca546438
IR_SHA256_RUN_2=97838ec71153c1e0fe8b54baf58765417d9d9e9ef5b02c2bfbd1c130ca546438
IR_BYTES_RUN_1=1395099
IR_BYTES_RUN_2=1395099
IR_BYTES_IDENTICAL=YES

OLD_CANONICAL_IR_SHA256=352f355a798f74562dd475068e2829c017a6bee4040ee4a54ae8d8cecfb2acf3
NEW_CANONICAL_IR_SHA256=97838ec71153c1e0fe8b54baf58765417d9d9e9ef5b02c2bfbd1c130ca546438
IR_HASH_CHANGED=YES

SOURCE_SHA256_AFTER_RUNS=0cf29929a25bc2485ece90375d8c0f90fa1710eac0439bc5decc13af11f03f63
SOURCE_BYTES_UNCHANGED=YES
```

The hash change is expected. Each of the four linked heading nodes now carries
validated navigation metadata. The run outputs were compared byte for byte.

## NAV-CARRIER target proof

The task's supplied IDs (`28c2a3`, `640a40`, `07d0e9`, and `336877`) identify
the four `li` card roots in the accepted source-semantics authority. They are
not heading nodes. The canonical source gives each card a separate heading
node. The rerun therefore checked the actual linked heading nodes by their
source IDs:

```text
CANONICAL_NAVIGABLE_HEADING_SOURCE_IDS=1af9fe,65c992,d5fa27,dbd8d0
REQUESTED_SOURCE_IDS_ARE_CARD_ROOTS=YES
REQUESTED_SOURCE_IDS_MATCH_HEADINGS=NO
ROMEO_NAVIGABLE_HEADING_COUNT=4
ROMEO_VALID_NAVIGATION_MAP_COUNT=4
```

| Source ID | Semantic type | Tag | Navigation present | Map valid | Target | Href SHA-256 |
| --- | --- | --- | --- | --- | --- | --- |
| 1af9fe | heading | h3 | YES | YES | none | 334359b90efed75da5f0ada1d5e6b256f4a6bd0aee7eb39c0f90182a021ffc8b |
| 65c992 | heading | h3 | YES | YES | none | 334359b90efed75da5f0ada1d5e6b256f4a6bd0aee7eb39c0f90182a021ffc8b |
| d5fa27 | heading | h3 | YES | YES | none | 334359b90efed75da5f0ada1d5e6b256f4a6bd0aee7eb39c0f90182a021ffc8b |
| dbd8d0 | heading | h3 | YES | YES | none | 334359b90efed75da5f0ada1d5e6b256f4a6bd0aee7eb39c0f90182a021ffc8b |

Each map passed `LiveFrames.StaticNavigation.validate_navigation_map/1`. No
destination string was printed or recorded.

```text
OLD_BRICKS_NAVIGATION_UNSUPPORTED_CARRIER=4
NEW_BRICKS_NAVIGATION_UNSUPPORTED_CARRIER=0
NAVIGATION_DIAGNOSTIC_DELTA=-4
NAV_CARRIER_CANONICAL_TARGET_MET=YES
```

## State and owner-scope invariants

```text
CARD_OWNER_COUNT=4
CARD_OWNER_NODE_IDS=node_000001_000001_000002_000001,node_000001_000001_000002_000002,node_000001_000001_000002_000003,node_000001_000001_000002_000004
EFFECTIVE_LAYER_PROVENANCE_MATCH=YES
HOVER_ALIAS_PROVEN=YES
FOCUS_WITHIN_RULES_PRESENT=YES
SOURCE_ACTION_IN_EXECUTABLE_RULES=NO
SOURCE_TRANSIENT_TOKEN_AS_STATE_CONDITION=NO
CROSS_CARD_TARGETS=0
SIBLING_TARGETS=0
ESCAPED_BOUNDARY_TARGETS=0
FOUR_OWNER_SCOPE_ISOLATION=PASS
```

Each owner retains its effective class-reference provenance. State rules use
only the accepted `hover` and `focus_within` conditions, and every target stays
inside its owner subtree.

## Responsive and state invariants

```text
DIRECT_MIN_767_PRESENT=YES
DIRECT_MAX_767_PRESENT=YES
BOUNDARY_REWRITTEN_TO_766=NO
BOUNDARY_REWRITTEN_TO_768=NO
NAMED_BREAKPOINT_MAPPING_APPLIED=NO

COMPLEX_CSS_COUNT=8
STATE_RULE_OWNER_COUNT=4
STATE_RULE_RULE_COUNT=48
STATE_RULE_SET_VALID_COUNT=4
CUSTOM_CSS_RESIDUAL_COUNT=4
STATE_RULE_RESIDUAL_COUNT=44
STATE_RULE_VIEWPORT_TUPLES=viewport none:32; min_width 767,max_width none:16
COMPLEX_CSS_SUBTYPE_COUNTS=custom_css:4;state_rules:4
UNKNOWN_COMPLEX_CSS_SUBTYPE=NO
SOURCE_FOCUS_SUPPRESSION_IN_GENERATABLE_IR=NO
```

## Residual and diagnostic inventory

The fresh custom-CSS residual fingerprints match the accepted PR #236
canonical inventory exactly. The existing classifications therefore remain
unchanged.

| Metric | PR #236 baseline | Post NAV-CARRIER | Delta | Expected? | Verdict |
| --- | --- | --- | --- | --- | --- |
| IR SHA-256 | `352f355a798f74562dd475068e2829c017a6bee4040ee4a54ae8d8cecfb2acf3` | `97838ec71153c1e0fe8b54baf58765417d9d9e9ef5b02c2bfbd1c130ca546438` | changed | Yes | Expected navigation metadata change |
| `bricks.navigation.unsupported_carrier` diagnostics | 4 | 0 | -4 | Yes | Expected target change |
| Valid heading navigation maps | 0 | 4 | +4 | Yes | Expected target change |
| Canonical residual count | 48 | 48 | 0 | Yes | Unchanged |
| Blocking residual count | 44 | 44 | 0 | Yes | Unchanged |
| Unresolved-value residual count | 32 | 32 | 0 | Yes | Unchanged |
| `bricks.custom_css.unresolved_value` diagnostics | 32 | 32 | 0 | Yes | Unchanged |
| `bricks.custom_css.unsupported_selector` diagnostics | 16 | 16 | 0 | Yes | Unchanged |
| Asset diagnostics | 4 | 4 | 0 | Yes | Unchanged |
| Source-setting diagnostics | 13 | 13 | 0 | Yes | Unchanged |
| Named-breakpoint diagnostics | 3 | 3 | 0 | Yes | Unchanged |
| Variable diagnostics | 25 | 25 | 0 | Yes | Unchanged |
| State-rule count | 48 | 48 | 0 | Yes | Unchanged |
| State-rule residual count | 44 | 44 | 0 | Yes | Unchanged |
| Focus-suppression generatable flag | `NO` | `NO` | unchanged | Yes | Unchanged |

```text
CANONICAL_RESIDUAL_COUNT=48
CANONICAL_CONFIRMED_REQUIRED_RESIDUAL_COUNT=24
CANONICAL_BLOCKING_UNKNOWN_RESIDUAL_COUNT=20
CANONICAL_BLOCKING_RESIDUAL_COUNT=44
CANONICAL_SOURCE_FOCUS_SUPPRESSION_RESIDUALS=4
CANONICAL_UNRESOLVED_VALUE_COUNT=32
CANONICAL_VISUALLY_REQUIRED_UNSUPPORTED_RESIDUALS=24
CANONICAL_UNKNOWN_REQUIREMENT_RESIDUALS=20
CANONICAL_DUPLICATE_RESIDUALS=0
CANONICAL_NON_REQUIRED_RESIDUALS=0
RESIDUAL_REASON_COUNTS=unresolved_value:32;unsupported_selector:16
BLOCKING_RESIDUAL_INVARIANT=PASS; 24+20=44
TOTAL_RESIDUAL_INVARIANT=PASS; 24+20+4=48

SOURCE_LOCAL_CUSTOM_PROPERTY=20
EXTERNAL_VALUE_AUTHORITY_MISSING=4
UNSUPPORTED_COMPOUND_EXPRESSION=8
UNRESOLVED_VALUE_CAUSE_COUNTS=SOURCE_LOCAL_CUSTOM_PROPERTY:20;EXTERNAL_VALUE_AUTHORITY_MISSING:4;UNSUPPORTED_COMPOUND_EXPRESSION:8;OTHER:0

DELTA_CANONICAL_RESIDUAL_COUNT=0
DELTA_CANONICAL_BLOCKING_RESIDUAL_COUNT=0
DELTA_CANONICAL_UNRESOLVED_VALUE_COUNT=0
CANONICAL_RESIDUAL_FINGERPRINT_SET_MATCH=YES
```

Fresh diagnostic counts:

```text
bricks.asset.unresolved=4
bricks.breakpoint.unresolved=3
bricks.custom_css.unresolved_value=32
bricks.custom_css.unsupported_selector=16
bricks.navigation.unsupported_carrier=0
bricks.setting.unsupported=13
bricks.variable.unresolved=25

ASSET_DIAGNOSTIC_DELTA=0
BREAKPOINT_DIAGNOSTIC_DELTA=0
CUSTOM_CSS_UNRESOLVED_VALUE_DELTA=0
CUSTOM_CSS_UNSUPPORTED_SELECTOR_DELTA=0
SOURCE_SETTING_DIAGNOSTIC_DELTA=0
VARIABLE_UNRESOLVED_DELTA=0
```

Navigation diagnostics are an independent non-CSS gap. Their reduction does
not change the 48 CSS residuals. No combined blocker total was created.

The other blocker classifications remain frozen:

```text
ASSET_RESOLUTION_BLOCKERS=4
SOURCE_SETTING_BLOCKERS=13
NAMED_BREAKPOINT_BLOCKERS=3
ACCESSIBILITY_BLOCKERS=0
CSS_LOCAL_CUSTOM_PROPERTY=20
CSS_COMPOUND_VALUE=8
CSS_SELECTOR_BLOCKERS=12
EXTERNAL_VALUE_AUTHORITY=4

UNKNOWN_REQUIREMENT_RECLASSIFIED=NO
EXTERNAL_AUTHORITY_INFERRED=NO
NAMED_BREAKPOINT_VALUE_INFERRED=NO
ASSET_IDENTITY_INFERRED=NO
```

## Scope, privacy, and performance

```text
PRODUCTION_FILES_CHANGED=NO
TEST_FILES_CHANGED=NO
CONVERSION_MATRIX_CHANGED=NO
IMPLEMENTATION_STARTED=NO
ROMEO_COMPONENT_CONTRACT_CREATED=NO
ROMEO_COMPONENTIZATION_PLAN_CREATED=NO
ROMEO_NATIVE_GENERATION_RUN=NO
ROMEO_COMPONENTIZATION_STARTED=NO
ROMEO_NATIVE_GENERATION_STARTED=NO
NEXT_CAPABILITY_IMPLEMENTATION_STARTED=NO

RAW_ROMEO_JSON_PUBLISHED=NO
RAW_PRIVATE_CSS_PUBLISHED=NO
RAW_PRIVATE_HREF_PUBLISHED=NO
PRIVATE_ASSET_URL_PUBLISHED=NO
PRIVATE_SETTING_VALUE_PUBLISHED=NO

DATA_LAYER=COLD_BUILD_TIME
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
REDIS=N/A
POSTGRES=N/A
CACHE=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
100K_CONCURRENT_USERS_IMPACT=NONE
```

## Lifecycle and next gate

```text
NAV_CARRIER_STATE=CANONICAL_RERUN_VERIFIED_PENDING_PR_ACCEPTANCE
ROMEO_COMPONENTIZATION_READINESS=BLOCKED
ROMEO_COMPONENTIZATION_AUTHORIZED=NO
ROMEO_IMPLEMENTATION_AUTHORIZED=NO
ROMEO_NATIVE_GENERATION_AUTHORIZED=NO
NEXT_GATE=REVIEW_AND_ACCEPT_NAV_CARRIER_CANONICAL_RERUN
STOP=NONE
```

NAV-CARRIER remains pending independent review, merge, and post-merge
verification of this rerun record. This record does not mark the lane
`ACCEPTED` and does not choose another blocker lane.
