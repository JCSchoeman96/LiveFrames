# Feature Romeo post-compound CSS canonical rerun

## Scope and authority

This record reports two fresh canonical conversions on exact current `main` after the accepted source-local custom-property and bounded compound CSS implementations. Each run used the public Bricks adapter with a fresh empty `TokenSet`, validated the returned Design IR, and serialized it through `LiveFrames.IR.encode!/1`.

The run did not modify production code or tests. It did not create a Romeo component contract or plan, run `NativeGenerator`, or authorize implementation.

```text
BASE_SHA=bd8bc4daae8b0b3b0ad79c1711a798b5028b7784
BASE_TREE=9a84c992bcf0cc35d8affb2b808958c3baa9dece
BASE_CI=39485466591 SUCCESS
LIVE_FRAMES_PACKAGE_TREE=a6c84b203960a61a4e936a8f4a58433176408bf8
PR279_MERGE_SHA=a2f3944fbe1199d7532811c835ac6330cd676497
PR279_APPROVED_HEAD=c51a0edfa647078ebdd57f95c2608fc8c5cf784c
MAIN_MOVEMENT_DURING_RERUN=NONE
```

The current-main CI run completed successfully at the recorded base SHA. PR #279 is merged at the recorded merge SHA.

## Canonical source identity and context

The corpus digest, record count, Romeo artifact hash and byte count, and component identity were verified before normalization. The public adapter returned the requested component identity on both runs. The corpus and artifact hashes were checked again after both runs.

```text
PRIVATE_SOURCE_IDENTITY=VERIFIED
CORPUS_RECORDS=34
CORPUS_DIGEST=074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e
ROMEO_SHA256=0cf29929a25bc2485ece90375d8c0f90fa1710eac0439bc5decc13af11f03f63
ROMEO_BYTES=24944
COMPONENT_ID_MATCH=YES
SOURCE_BYTES_UNCHANGED=YES

CANONICAL_CONTEXT=public LiveFrames.Adapters.Bricks.to_ir/2; component_id=eiwwbh; fresh empty TokenSet per run
ACSS_FIXTURE_LOADED=NO
ACSS_PROFILE_SELECTED=NO
ACSS_SOURCE_VERSION_ASSIGNED=NO
STRUCTURAL_VARIABLE_AUTHORITY_SUPPLIED=NO
NAMED_BREAKPOINT_AUTHORITY_SUPPLIED=NO
ACSS_AUTHORITY_USED=NO
```

The conservative no-ACSS context remains authorized by `feature_romeo_conservative_no_acss_context_authority.md`. No adjacent private settings export, Milan authority, CTA authority, or named-breakpoint mapping was used.

## Independent normalization runs

Each run reread the canonical input path through `LiveFrames.Adapters.Bricks.to_ir/2`, created a new empty `TokenSet`, validated the returned document with `LiveFrames.IR.validate/1`, and serialized it with `LiveFrames.IR.encode!/1`. The serialized bytes were compared directly in memory. The run state and encoded bytes were discarded after comparison.

```text
RUN_1=SUCCESS
RUN_2=SUCCESS
IR_SHA256_RUN_1=6da5c8309fadb75f133ce89a52d2ca4b344aa1d792a63113a4470af062fb6bb1
IR_SHA256_RUN_2=6da5c8309fadb75f133ce89a52d2ca4b344aa1d792a63113a4470af062fb6bb1
IR_BYTES_RUN_1=1508446
IR_BYTES_RUN_2=1508446
IR_BYTES_IDENTICAL=YES
```

## Baseline and residual delta

The latest accepted canonical no-ACSS rerun on current main is `feature_romeo_post_nav_carrier_canonical_rerun.md`, merged in PR #249. It recorded 48 residual fingerprints, including 20 source-local custom-property findings and eight compound-value findings. Its fingerprint set matched the accepted canonical inventory in `feature_romeo_canonical_no_acss_normalization.md`.

No accepted canonical Romeo rerun after the local custom-property resolver implementation was found:

```text
BASELINE_RECORD=feature_romeo_post_nav_carrier_canonical_rerun.md
BASELINE_POST_LOCAL_PROPERTY_CANONICAL=NOT_FOUND
BASELINE_RESIDUAL_COUNT=48
CANONICAL_RESIDUAL_COUNT=44
CANONICAL_BLOCKING_RESIDUAL_COUNT=40
CANONICAL_CONFIRMED_REQUIRED_RESIDUAL_COUNT=20
CANONICAL_BLOCKING_UNKNOWN_RESIDUAL_COUNT=20
CANONICAL_UNRESOLVED_VALUE_COUNT=28
RESIDUAL_REASON_COUNTS=unresolved_value:28;unsupported_selector:16
```

Four old fingerprints disappeared. Each mapped to a confirmed required `SOURCE_LOCAL_CUSTOM_PROPERTY` finding in the accepted baseline. These removals match the merged generic local-property resolver capability. No other baseline fingerprint disappeared, and no new fingerprint appeared.

```text
REMOVED_FINGERPRINT_COUNT=4
REMOVED_FINGERPRINTS=9c301f6e3bb52d7d1765c3ea5e8332e7361a9ee10a441d7ebf121763c94d0e93,e40736eb3a7ba24791b285411a4f33ea6a57f4116427e5d8c7b5f35112fbe2a7,e8921b20135635c66775a69f43c51a763647cdd852bab2db78dc4b7c2abe58c1,f7c6c544077d326584455d1541df7b0e96d2b5bd146cfa4f60eb92ad57d9563b
REMOVED_CAUSE_COUNTS=SOURCE_LOCAL_CUSTOM_PROPERTY:4
ADDED_FINGERPRINT_COUNT=0
UNEXPLAINED_RESIDUAL_DELTA=NO
```

The residual fingerprints use the accepted stable scheme: SHA-256 of the sanitized owner identity, residual reason, and source residual text. No residual text or private source value is recorded here.

## Fresh residual and blocker inventory

```text
SOURCE_LOCAL_CUSTOM_PROPERTY=16
SOURCE_LOCAL_CUSTOM_PROPERTY_CONFIRMED_REQUIRED=12
SOURCE_LOCAL_CUSTOM_PROPERTY_UNKNOWN_REQUIREMENT=4
UNSUPPORTED_COMPOUND_EXPRESSION=8
EXTERNAL_VALUE_AUTHORITY_MISSING=4
CSS_SELECTOR_BLOCKERS=12
ASSET_RESOLUTION_BLOCKERS=4
SOURCE_SETTING_BLOCKERS=13
NAMED_BREAKPOINT_BLOCKERS=3
ACCESSIBILITY_BLOCKERS=0
```

The eight compound-value fingerprints are unchanged from the accepted baseline. The public adapter exposes their existing `unresolved_value` residuals but does not retain resolver outcome atoms. This run used no private normalizer instrumentation and does not infer why an individual compound reference closed. The bounded compound authority keeps unresolved references fail-closed and rejects an assumed `8 → 0` success criterion.

Selector, asset, source-setting, named-breakpoint, external-value-authority, and inert focus-suppression fingerprints are unchanged. Their counts remain separate. Custom-CSS diagnostics mirror residuals and are not counted again.

```text
bricks.custom_css.unresolved_value=28
bricks.custom_css.unsupported_selector=16
bricks.asset.unresolved=4
bricks.setting.unsupported=13
bricks.breakpoint.unresolved=3
bricks.navigation.unsupported_carrier=0
bricks.variable.unresolved=25
```

## Navigation, state, and owner-scope invariants

```text
NAVIGATION_UNSUPPORTED_CARRIER=0
NAVIGABLE_HEADING_COUNT=4
VALID_NAVIGATION_MAP_COUNT=4

CARD_OWNER_COUNT=4
STATE_RULE_OWNER_COUNT=4
STATE_RULE_RULE_COUNT=48
STATE_RULE_SET_VALID_COUNT=4
OWNER_SCOPE_ISOLATION=PASS
CROSS_CARD_TARGETS=0
SIBLING_TARGETS=0
ESCAPED_BOUNDARY_TARGETS=0

DIRECT_MIN_767_PRESENT=YES
DIRECT_MAX_767_PRESENT=YES
BOUNDARY_REWRITTEN_TO_766=NO
BOUNDARY_REWRITTEN_TO_768=NO

SOURCE_ACTION_IN_EXECUTABLE_RULES=NO
SOURCE_TRANSIENT_TOKEN_AS_STATE_CONDITION=NO
SOURCE_FOCUS_SUPPRESSION_IN_GENERATABLE_IR=NO
```

All four emitted heading navigation maps passed `LiveFrames.StaticNavigation.validate_navigation_map/1`. Each state-rule set passed `LiveFrames.IR.StateRuleSet.validate/1`. Every target remained within its card owner subtree. Executable conditions remained within the accepted `hover` and `focus_within` set. Source focus suppression remains residual evidence and did not enter generatable IR.

## Runtime and scope boundary

```text
DATA_CLASS=COLD_BUILD_TIME
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
REDIS=NOT_REQUIRED
POSTGRES=NOT_REQUIRED
PGBOUNCER=NOT_REQUIRED
READ_REPLICA=NOT_REQUIRED
CACHEX=NOT_REQUIRED
GENSERVER=NOT_REQUIRED
PUBSUB=NOT_REQUIRED
OBAN=NOT_REQUIRED
POLLING=0
SOURCE_IR_RUNTIME_WALKS=0
100K_CONCURRENT_USERS_IMPACT=NONE

PRODUCTION_FILES_CHANGED=NO
TEST_FILES_CHANGED=NO
PAGE_A_CHANGED=NO
ROMEO_COMPONENT_CONTRACT_CREATED=NO
ROMEO_COMPONENTIZATION_PLAN_CREATED=NO
ROMEO_NATIVE_GENERATION_RUN=NO
ROMEO_COMPONENTIZATION_STARTED=NO
ROMEO_IMPLEMENTATION_STARTED=NO
PRIVATE_SOURCE_LEAK=NO
```

## Rerun result

```text
LIFECYCLE=PASSED
ROMEO_COMPONENTIZATION_AUTHORIZED=NO
ROMEO_IMPLEMENTATION_AUTHORIZED=NO
ROMEO_NATIVE_GENERATION_AUTHORIZED=NO
NEXT_GATE=INDEPENDENT_REVIEW_OF_THIS_CANONICAL_RERUN_EVIDENCE
STOP=NONE
```
