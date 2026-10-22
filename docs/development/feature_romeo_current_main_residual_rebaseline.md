# Feature Romeo current-main residual rebaseline

## Scope and authority

This record rebaselines the canonical Romeo residuals against exact current `main` after the Design IR 5 and executable-source translation commits. It compares the result with the accepted PR #281 post-compound canonical rerun.

It is evidence only. It does not change production code or tests, does not create a Romeo component contract or plan, does not run `NativeGenerator`, and does not authorize implementation or componentization.

Main movement is not treated as a stop condition. Movement is accounted for by byte-level comparison against the accepted baseline.

## Frozen baseline

```text
CURRENT_MAIN_SHA=3689b2e302cd5afe96430b72c127a3ffcec2ef98
CURRENT_MAIN_TREE=1e1bba48559540fec4313eed3e14e51e594c221b
CURRENT_MAIN_CI_RUN=39772910940
CURRENT_MAIN_CI=SUCCESS
CURRENT_MAIN_MOVEMENT_DURING_RUN=NONE

PR281_MERGE_SHA=676a77e63730e157cfcb6b472ab006a67e4177cd
PR281_APPROVED_HEAD=b8607b005457d990c9ee97d4ba53b79fd0179c84
PR281_IN_CURRENT_MAIN_ANCESTRY=YES
PR281_REPRODUCTION_BASE_SHA=bd8bc4daae8b0b3b0ad79c1711a798b5028b7784
PR281_MERGE_DIFF_FROM_BASE=DOCS_AND_AGENTS_MD_ONLY
COMMITS_ON_MAIN_SINCE_PR281=15
```

## Private source identity

The private Romeo corpus and artifact were verified before the conversions and again at finalization. No source bytes changed.

```text
PRIVATE_SOURCE_IDENTITY=VERIFIED
CORPUS_RECORDS=34
CORPUS_DIGEST=074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e
ROMEO_SHA256=0cf29929a25bc2485ece90375d8c0f90fa1710eac0439bc5decc13af11f03f63
ROMEO_BYTES=24944
COMPONENT_ID=eiwwbh
```

## Canonical context

Each run used the public Bricks adapter with component identity `eiwwbh` and a fresh empty `TokenSet`. Each returned document was validated with `LiveFrames.IR.validate/1` and serialized with `LiveFrames.IR.encode!/1`.

```text
ACSS_FIXTURE_LOADED=NO
ACSS_PROFILE_SELECTED=NO
ACSS_AUTHORITY_USED=NO
STRUCTURAL_VARIABLE_AUTHORITY_SUPPLIED=NO
NAMED_BREAKPOINT_AUTHORITY_SUPPLIED=NO
```

This is the conservative no-ACSS context authorized by `feature_romeo_conservative_no_acss_context_authority.md`.

## Baseline reproduction

The accepted PR #281 IR was regenerated from its base commit. Its code is identical to the PR #281 merge, because the merge changed only docs and `AGENTS.md`.

```text
PR281_BASELINE_REPRODUCED=YES
PR281_BASELINE_IR_VERSION=4.0.0
PR281_BASELINE_IR_SHA256=6da5c8309fadb75f133ce89a52d2ca4b344aa1d792a63113a4470af062fb6bb1
PR281_BASELINE_IR_BYTES=1508446
```

## Current-main runs

Two independent conversions were run on the frozen `main` checkout.

```text
CURRENT_RUN_1=SUCCESS
CURRENT_RUN_2=SUCCESS
CURRENT_IR_VERSION=5.0.0
CURRENT_IR_SHA256_RUN_1=498049598e03be5119a380a6c5230400d23b9a29a766e620fd69c719d0dec5e8
CURRENT_IR_SHA256_RUN_2=498049598e03be5119a380a6c5230400d23b9a29a766e620fd69c719d0dec5e8
CURRENT_IR_BYTES=1508446
CURRENT_RUNS_BYTE_IDENTICAL=YES
```

The current hash differs from the accepted PR #281 hash. The difference is explained below. The accepted hash is comparison evidence only, and current `main` is not required to reproduce it.

## Delta accounting

The two serialized documents were compared path by path over 17,819 leaves and byte by byte.

```text
LEAVES_COMPARED=17819
LEAVES_CHANGED=1
LEAVES_ADDED=0
LEAVES_REMOVED=0
CHANGED_PATH=/ir_version
BASELINE_VALUE=4.0.0
CURRENT_VALUE=5.0.0
BYTE_DIFFERENCES=1
BYTE_DIFFERENCE_OFFSET=397421
DIAGNOSTICS_CHANGED=NO
RESIDUALS_CHANGED=NO
UNEXPLAINED_DELTA=0
```

The only change is the Design IR version string. It is caused by the Design IR 5 commit on `main`. Residual and diagnostic content is byte-identical, so any fingerprint derived from that content is also unchanged.

## Residual and diagnostic inventory

```text
TOTAL_DIAGNOSTICS=89
bricks.custom_css.unresolved_value=28
bricks.custom_css.unsupported_selector=16
bricks.variable.unresolved=25
bricks.setting.unsupported=13
bricks.asset.unresolved=4
bricks.breakpoint.unresolved=3
CUSTOM_CSS_RESIDUALS=44
```

The custom-CSS diagnostics mirror the residual set. They are not counted again. These counts match the accepted PR #281 inventory exactly.

## Required-set carry-forward

Because the residual content is identical to the accepted baseline, the accepted requirement classification carries forward. This run did not re-derive those classifications, and it did not perform a per-finding causal decomposition.

```text
REQUIREMENT_CLASSIFICATION_CARRY_FORWARD=YES
CONFIRMED_REQUIRED_RESIDUAL_COUNT=20
CONFIRMED_REQUIRED_LOCAL_PROPERTY_COUNT=12
CONFIRMED_REQUIRED_COMPOUND_COUNT=8
UNKNOWN_REQUIREMENT_RESIDUAL_COUNT=20

CURRENT_CAUSAL_DECOMPOSITION_RUN=NO
CURRENT_REQUIRED_PRIMARY_CAUSES_CLASSIFIED=0
CURRENT_REQUIRED_FINDINGS_PENDING_CAUSAL_DECOMPOSITION=20
```

The 20 requirement classifications are inherited from accepted authority, and their source and requirement lane descriptions remain accepted. The current terminal compiler cause for each of the 20 findings has not been established by this record. The twenty findings are requirement-classified but causally undecomposed. They are not unexplained in the requirement sense.

The accepted requirement classifications and lane descriptions remain in `feature_romeo_canonical_gap_decomposition.md` and `feature_romeo_post_compound_css_canonical_rerun.md`. They do not record a current per-finding compiler cause. Selecting the next generic capability therefore remains a separate gate.

## Movement classification

Path triage over the 40 files changed since the PR #281 merge classified 18 as potentially material and 22 as non-material. The byte-level comparison supersedes that triage. For canonical Romeo output, the only effect of the movement is the IR version string.

```text
ROMEO_OUTPUT_EFFECT_OF_MAIN_MOVEMENT=IR_VERSION_ONLY
```

## Tooling note

An attempted resolver call trace during the interrupted run was not used as evidence. It enabled call tracing without return tracing, and its only observed call was the probe's own direct invocation. No conclusion is drawn from it.

## Next gate

No next capability is selected in this record. The per-finding terminal compiler cause for the 20 confirmed-required findings is still undecomposed. The current evidence does not establish which required finding class is the dominant shared causal blocker. Selecting the next generic capability therefore needs a separate causal decomposition gate.

## Verification

```text
MIX_FORMAT_CHECK=PASS
MIX_COMPILE_WARNINGS_AS_ERRORS=PASS
MIX_ASSETS_BUILD=PASS
MIX_TEST_LIVE_FRAMES=2162 tests, 0 failures
MIX_TEST_PREVIEW=35 tests, 0 failures
MIX_DEPS_UNLOCK_CHECK_UNUSED=PASS
PRODUCTION_FILES_CHANGED=NO
TEST_FILES_CHANGED=NO
ROMEO_COMPONENT_CONTRACT_CREATED=NO
ROMEO_NATIVE_GENERATION_RUN=NO
PRIVATE_SOURCE_LEAK=NO
```

Dependency audit output from `mix deps.get` reported known advisories for `bandit` 1.12.5 and `lazy_html` 0.1.12. Dependency changes are out of scope for this evidence record, so they were not changed here.
