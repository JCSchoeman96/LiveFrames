# Feature Milan ComponentReview / NativeRealization Sequencing Authority

## Status and scope

```text
AUTHORITY_KIND=TASK10_LIFECYCLE_SEQUENCING_AMENDMENT
MOTIVATING_TRACER=FEATURE_MILAN
AUTHORITY_ACCEPTED=NO_PENDING_INDEPENDENT_REVIEW

BEHAVIOR_SEMANTICS_CHANGE=NO
COMPONENT_PUBLIC_API_CHANGE=NO
SERIALIZED_SCHEMA_CHANGE=NO

PHASE_7B_AUTHORIZED=NO
PHASE_8_AUTHORIZED=NO
ARTICLE_JULIET_P4B=DEFERRED
```

This later amendment clarifies the Phase 7A readiness statement in the accepted [Task 10 IR6 transition authority](feature_milan_task10_ir6_transition_authority.md) and the generation ordering in the accepted [Task 10 source-neutral realization authority](feature_milan_task10_source_neutral_realization_authority.md). Those historical documents remain unchanged. This amendment applies only to the lifecycle gate described below; it does not change Milan's frozen `SemanticInput`, Selection semantics, native-tag policy, or public component API.

The amendment becomes authoritative only after independent review, merge, and successful post-merge CI. It does not itself authorize Phase 7B, ComponentReview approval, or Phase 8.

## Characterization base

```text
BASE_SHA=49b4d8000107f2e8ec5e7f55cd34cec4b0d96786
BASE_TREE=7c6116e6b7e3452d756ea5a99f2e9f18de100cbf
BASE_CI_RUN=41009356370
BASE_CI_RESULT=success
```

## Read-only characterization

The characterization used the accepted IR6 DesignDocument, BehaviorContract, BehaviorReviewResult, frozen Milan `SemanticInput`, and exact breakpoint authority. `Behavior.ComponentizationDecision.propose/5` was called once and returned `proposed` with no diagnostics. The candidate's ComponentContract and ComponentizationPlan structure, references, and Behavior-aware references validated; both diagnostic counts were zero, and static item review was not triggered.

The only diagnostic from the ordinary pre-review generation-prerequisite check was:

```text
code=componentization_plan.native_generation.tag_unsupported
severity=error
path=nodes[node_000001_000001_000001_000002_000001]
message=node has no compatible native tag
```

The target record is:

```text
node_id=node_000001_000001_000001_000002_000001
semantic_type=generic
tag=button
Behavior_roles=control_collection+activate_origin
```

This is the exact Selection control collection. The other disputed node, `node_000001_000001_000002_000001`, is the presentation collection, has no explicit `tag` attribute, and was not the blocker. There was exactly one generation-prerequisite diagnostic.

The ordinary native-tag rule in `ComponentizationPlan` remains closed:

```text
generic compatible native tags=div
generic default native tag=div
generic + explicit tag=button -> native_tag error
```

The sole bounded exception is available only with a transient `NativeRealizationAuthority` whose `control_node_id` matches the DesignNode, when that node has `semantic_type=generic` and `tag=button`. No exception is serialized, and the global native-tag map remains unchanged.

The lifecycle cycle is confirmed by the current implementation:

```text
NativeRealizationAuthority.derive/5
  requires ComponentContract.validate_for_generation/2
  on an approved ComponentContract

ComponentReview.approve_with_result/8
  runs ordinary Behavior-aware generation prerequisites
  before creating the approved contract
  and runs ordinary Behavior-aware final generation validation
  again after creating it
```

Neither `ComponentReview` validation call supplies `NativeRealizationAuthority`. The Milan control therefore fails ordinary native eligibility before the approval transition can return the approved contract needed to derive that authority.

The current behavior-aware `NativeGenerator.generate/7` path already has the required final order: it validates the approved contract and exact Behavior authority, checks Behavior-aware references, derives `NativeRealizationAuthority` when Selection realization applies, runs authority-aware native-generation validation, validates the exact ComponentReviewResult authority, and then builds and renders the filtered structure. No NativeGenerator or NativeRealizationAuthority production change is expected.

## Phase 7A readiness clarification

Phase 7A pre-review readiness requires all of the following:

```text
Behavior.ComponentizationDecision.propose/5
  -> proposed

proposer diagnostics
  -> []

ComponentContract structure and reference validation
  -> pass

ComponentizationPlan structure and reference validation
  -> pass

Behavior-aware reference and disposition validation
  -> pass

static item review
  -> not triggered
```

For a candidate that requires the exact Selection native realization above, this one ordinary-generation diagnostic is a deferred lifecycle gate, not a generic Phase 7A componentization defect:

```text
code=componentization_plan.native_generation.tag_unsupported
path=nodes[node_000001_000001_000001_000002_000001]
target semantic_type=generic
target tag=button
target Behavior role=exact accepted Selection control
```

```text
PHASE_7A_DEFERRED_NATIVE_REALIZATION_GATE_COUNT=1
```

Only this exact diagnostic on this exact accepted Selection control may be deferred. A second generation prerequisite diagnostic, any different diagnostic code, or a diagnostic on any other node remains blocking. No general diagnostic waiver is created. The Phase 7A readiness clarification does not mean ordinary native generation passed; it records that the one native eligibility check must be completed after ComponentReview has created the transient approved contract required for authority derivation.

## ComponentReview sequencing authority

Preserve the public operation `ComponentReview.approve_with_result/8`. Do not add a second public human-approval API. The operation remains one atomic pure transition:

```text
failure
  => no approved contract returned
  => no ComponentReviewResult returned
```

For disposition-bearing candidates, the corrected internal order is:

1. Validate total input shapes.
2. Require a proposed ComponentContract.
3. Validate exact candidate identity across the ComponentContract, ComponentizationPlan, and DesignDocument.
4. Require a disposition-bearing plan.
5. Validate Behavior input shapes.
6. Validate ComponentContract generation prerequisites without requiring `approval_status=:approved`.
7. Validate ComponentizationPlan references and dispositions against the exact Behavior authority, without ordinary native-generation eligibility.
8. Construct the approved ComponentContract and matching ComponentReviewResult transiently in memory.
9. Attempt ordinary final generation validation with the exact Behavior authority.
10. Choose the final generation gate:
    - If ordinary validation passes, preserve the existing ordinary disposition behavior.
    - If ordinary validation fails, attempt `NativeRealizationAuthority.derive/5` using the transient approved ComponentContract.
11. If derivation succeeds, run `validate_for_generation_with_behavior_and_native_realization_authority/6`.
12. Validate the ComponentReviewResult against the exact approved ComponentContract, plan, and DesignDocument, and return only if the chosen final generation gate passes.

This ordering does not persist an approval artifact between checks. The transient approved contract exists only within the call. `NativeRealizationAuthority.derive/5` continues to require an approved contract through `ComponentContract.validate_for_generation/2`; that invariant must not be weakened.

### Failure diagnostics

For ordinary candidates, behavior remains unchanged. If ordinary final generation validation fails and `NativeRealizationAuthority.derive/5` also fails, return the original ordinary-generation diagnostics. Do not replace an ordinary native-generation defect with `selection_missing`, `selection_invalid`, or another Selection diagnostic when Selection realization does not apply.

If derivation succeeds but authority-aware generation validation fails, return the authority-aware generation diagnostics. On every failed final gate, return neither the approved ComponentContract nor the ComponentReviewResult.

### Expected Milan path

```text
proposed contract
-> candidate identity and references PASS
-> transient approved contract and matching ComponentReviewResult created
-> ordinary generation detects generic + tag=button
-> exact NativeRealizationAuthority derives
-> authority-aware native generation PASS
-> ComponentReviewResult validates against exact inputs
-> approved contract + ComponentReviewResult returned
```

```text
ORDINARY_GENERIC_BUTTON_RULE_CHANGED=NO
```

## Unchanged native generation boundaries

The global ordinary rule remains:

```text
ORDINARY_GENERIC_BUTTON_GENERATION=BLOCKED
ORDINARY_GENERIC_BUTTON_WIDENING=FORBIDDEN
```

The exception remains exact, transient, Behavior-bound, plan-bound, DesignDocument-bound, and node-bound. It is available only for the matching generic button control identified by successfully derived `NativeRealizationAuthority`. No serialized exception or generic native-tag widening is allowed.

The existing behavior-aware `NativeGenerator.generate/7` final architecture remains unchanged:

```text
approved contract gate
-> exact Behavior authority
-> Behavior reference validation
-> derive NativeRealizationAuthority when Selection requires it
-> authority-aware generation validation
-> exact ComponentReviewResult authority
-> FilteredStructure
-> StyleIntegration
-> Renderer
```

```text
NATIVE_GENERATOR_PRODUCTION_CHANGE_EXPECTED=NO
NATIVE_REALIZATION_AUTHORITY_PRODUCTION_CHANGE_EXPECTED=NO
```

If implementation requires changing NativeGenerator, stop with `STOP=NATIVE_GENERATOR_SEQUENCE_AUTHORITY_INCOMPLETE`. If it requires weakening the approved-contract invariant, stop with `STOP=APPROVED_CONTRACT_INVARIANT_CHANGE_REQUIRED`.

## Expected implementation scope

The expected later implementation surfaces are:

```text
apps/live_frames/lib/live_frames/component_review.ex
apps/live_frames/test/live_frames/component_review_test.exs
```

No other production file is expected. If implementation requires changes to `behavior/native_realization_authority.ex`, `native_generator.ex`, or `componentization_plan/reference_validation.ex`, stop with `STOP=IMPLEMENTATION_SCOPE_EXPANDED` and explain why. If it requires changing Selection topology, timers, ARIA, runtime state, or BehaviorContract meaning, stop with `STOP=CROSS_LANE_CAPABILITY_REQUIRED`.

Stop and request separate authority if implementation requires any of the following:

```text
STOP=BEHAVIOR_SEMANTICS_CHANGE_REQUIRED
STOP=SERIALIZED_SCHEMA_CHANGE_REQUIRED
STOP=NEW_PUBLIC_REVIEW_API_REQUIRED
```

## Required future tests

The implementation must use TDD and cover at least these cases:

### Existing ordinary disposition candidate

```text
ordinary candidate
ordinary generation eligible
=> approve_with_result/8 succeeds exactly as before
```

### Exact Selection realization candidate

```text
before fix:
ordinary pre-review native validation => tag_unsupported

after fix:
approve_with_result/8
=> approved ComponentContract + ComponentReviewResult
through exact transient NativeRealizationAuthority
```

### Fail-closed and authority identity

Verify that generic plus `tag=button` without exact Selection authority remains blocked; wrong Behavior contract, wrong Behavior review, wrong DesignDocument identity, split Selection, and invalid Selection topology return no approval.

### Selection plus unrelated native defect

When a candidate has the exact valid Selection control plus a second unrelated native-generation defect, authority derivation may clear only the exact control-node exception. The second defect must remain blocking.

### Atomic failure

For every failed final generation gate:

```text
approved_contract_returned=NO
component_review_result_returned=NO
```

### Review identity

The successful ComponentReviewResult must continue hashing the approved ComponentContract bytes, exact ComponentizationPlan bytes, and exact DesignDocument digest. No review identity format or digest input changes.

## Phase and ownership boundary

After this sequencing authority is independently accepted and merged green:

```text
MILAN_PHASE_7A_NATIVE_BLOCKER_CLASSIFICATION=
EXPECTED_DEFERRED_NATIVE_REALIZATION_GATE
```

The recommended sequence is:

1. Accept this sequencing authority.
2. Implement ComponentReview sequencing; review, merge, and require green post-merge CI.
3. Rerun final Milan Phase 7A using the corrected readiness classification.
4. Freeze candidate fingerprints in Phase 7B.
5. Independently review the exact candidate.
6. Perform human ComponentReview in Phase 8.
7. Prove final Behavior-aware NativeGenerator generation.

Article Juliet remains deferred until the shared Milan path is stable.

```text
LEAD1_CHANGE=ComponentReview lifecycle sequencing
LEAD2_BEHAVIOR_SEMANTICS_CHANGE=NO
NATIVE_REALIZATION_TOPOLOGY_CHANGE=NO
```

This amendment records a lifecycle ordering correction only. It grants no ComponentReview approval, starts no implementation, does not execute Phase 7B or Phase 8, and does not authorize Article Juliet P4B.
