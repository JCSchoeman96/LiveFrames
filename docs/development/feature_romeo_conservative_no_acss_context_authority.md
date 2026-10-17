# Feature Romeo conservative no-ACSS canonical-context authority

## Decision and scope

This record captures the owner decision to authorize a conservative
no-ACSS context for canonical Romeo normalization. It sets LiveFrames'
conversion authority boundary. It makes no claim about which tools or settings
were used to create the historical Romeo source.

The bounded source-environment and Automatic.css recovery is complete and
accepted in [the recovery record](feature_romeo_source_environment_acss_authority_recovery.md)
and PR #230. That search found no sufficient binding. This task does not
repeat it. No further provenance search is authorized unless new direct source
evidence is supplied.

```text
PR_230=ACCEPTED
PR_230_MERGE_SHA=f5733441f767ad615d27c9b523d0c46bce5b42b2
PR_230_MERGE_TREE=ec46896cd3f0dac60d4dd97c1b666097ac0110c9
PR_230_POST_MERGE_CI=39047071308 SUCCESS

BASE_SHA=ee39969b5d9b848aef25f825189d7646b70390f6
BASE_TREE=c13cec5a65c1fe477e027e9810689aa8d13a9b2e
BASE_CI=39047078001 SUCCESS
CURRENT_MAIN=ee39969b5d9b848aef25f825189d7646b70390f6
CURRENT_MAIN_TREE=c13cec5a65c1fe477e027e9810689aa8d13a9b2e
CURRENT_MAIN_CI=39047078001 SUCCESS
MAIN_MOVEMENT_WITH_MATERIAL_ROMEO_CONTEXT_CONFLICT=NO
SEARCH_BOUND_COMPLETE=YES
ADDITIONAL_PROVENANCE_SEARCH_AUTHORIZED=NO
SUFFICIENT_BINDING_COUNT=0
```

## Accepted evidence and historical claim boundary

The accepted recovery establishes these evidence states:

```text
ROMEO_SOURCE_ENVIRONMENT_BINDING=UNPROVEN
ROMEO_ACSS_CONFIG_BINDING=UNPROVEN
ROMEO_ACSS_VERSION=UNPROVEN
ROMEO_GRID_VARIABLE_SETTING=UNPROVEN
ROMEO_NAMED_BREAKPOINT_AUTHORITY=UNPROVEN
ROMEO_ACSS_AUTHORITY_APPLICABILITY=UNPROVEN_AFTER_BOUNDED_SEARCH
```

The canonical Romeo source identity remains the artifact recorded in
`feature_romeo_source_semantics_authority.md`:
`private_reference/frames/staging-2026-09/feature-section-romeo/bricks-component-eiwwbh-feature-section-romeo.json`, SHA-256
`0cf29929a25bc2485ece90375d8c0f90fa1710eac0439bc5decc13af11f03f63`,
24,944 bytes, component `eiwwbh`. Its identity and accepted direct semantics
remain intact.

The decision records these exact historical claims as unknown:

```text
HISTORICAL_ROMEO_USED_ACSS=UNPROVEN
HISTORICAL_ROMEO_DID_NOT_USE_ACSS=UNPROVEN
```

LiveFrames withholds ACSS semantics from Romeo unless exact source provenance
proves that the authority applies. This does not infer historical use or
non-use of Automatic.css.

## Canonical authority decision

```text
ROMEO_CANONICAL_EXTERNAL_TOKEN_AUTHORITY=NONE
ROMEO_CANONICAL_ACSS_AUTHORITY=NONE
ROMEO_CANONICAL_STRUCTURAL_VARIABLE_AUTHORITY=NONE
ROMEO_CANONICAL_NAMED_BREAKPOINT_AUTHORITY=NONE

ROMEO_CONSERVATIVE_NO_ACSS_CONTEXT=AUTHORIZED
```

LiveFrames may normalize Romeo using directly proven Romeo source semantics
and generic source-neutral compiler capability. A source value or variable
name that resembles an ACSS convention does not authorize a token,
structural-grid, source-version, settings-profile, or named-breakpoint mapping.

## Canonical future adapter context

The next normalization gate is authorized to use an empty external TokenSet
with the normal public Bricks adapter:

```elixir
token_set = LiveFrames.Tokens.TokenSet.new()
```

Its input context is:

```text
ACSS_FIXTURE_LOADED=NO
ACSS_PROFILE_SELECTED=NO
ACSS_SOURCE_VERSION_ASSIGNED=NO
STRUCTURAL_VARIABLE_AUTHORITY_SUPPLIED=NO
NAMED_BREAKPOINT_AUTHORITY_SUPPLIED=NO
```

The absence of external authority is intentional. The next gate may invoke
`LiveFrames.Adapters.Bricks.to_ir/2` with the canonical Romeo source and this
TokenSet after this authority record is reviewed and merged. This PR does not
invoke the adapter or run normalization.

## Preserved direct Romeo source authority

The no-ACSS context preserves all accepted direct Romeo evidence and leaves
these facts intact:

- The exact canonical artifact identity recorded above.
- Four independent card-owner subtrees.
- The exact reversible pointer pair on the same proven effective layer:

  ```text
  trigger="mouseenter", action="setAttribute",
  actionAttributeKey="class", actionAttributeValue=X

  trigger="mouseleave", action="removeAttribute",
  actionAttributeKey="class", actionAttributeValue=X
  ```

- The transient alias `X -> hover` is valid only when that exact pair proves
  it. The source action and class remain inert evidence.
- Literal `:focus-within` selectors retain browser focus-within semantics.
- Direct custom CSS declarations remain eligible when the existing generic
  source-neutral grammar and safety checks support them.
- Literal `@media (min-width: 767px)` remains direct source evidence.
- Literal `@media (max-width: 767px)` remains direct source evidence.
- Both inclusive media conditions match at 767px. Preserve that overlap as
  source evidence without inferring a net presentation.
- Source focus suppression remains inert and non-generatable. It does not
  replace the target's visible-focus requirement.

```text
DIRECT_MIN_767_AUTHORITY_PRESERVED=YES
DIRECT_MAX_767_AUTHORITY_PRESERVED=YES
```

## Source-local variables and structural-grid names

A source custom-property reference is not automatically an ACSS token. Without
proven external authority, `var(--something)` may resolve only when existing
generic source-neutral authority proves its meaning from permitted source
input. Otherwise it remains unresolved and follows the existing diagnostic
and residual path:

```text
RESOLUTION=UNRESOLVED
```

This task creates no token mapping and does not treat unresolved variables as
computed literals.

Names such as `--grid-1` or `--grid-gap` do not establish structural-grid
meaning:

```text
STRUCTURAL_GRID_MAPPING_INFERRED_FROM_NAME=NO
ROMEO_STRUCTURAL_VARIABLE_AUTHORITY_CALL=NOT_AUTHORIZED
```

No call to `AutomaticCSS.structural_variable_authority(...)` is authorized in
Romeo's canonical context. That mapping remains unavailable until new direct
source provenance authorizes it.

## Breakpoint and settings policy

Romeo has two separate breakpoint authority classes:

| Class | Romeo authority |
| --- | --- |
| Direct CSS media conditions `min-width: 767px` and `max-width: 767px` | Preserved as exact source CSS evidence, including inclusive overlap |
| Named settings such as `tablet_portrait` and `mobile_landscape` | No Romeo-specific mapping |

```text
ROMEO_NAMED_BREAKPOINT_MAPPING=NONE
```

The Feature Milan direct-breakpoint record and its provenance-register entry
apply only to Milan. They do not provide Romeo authority. Romeo's literal
767px CSS does not imply a named breakpoint. No Milan value or mapping is
imported here.

Unsupported source settings remain visible through the existing source-neutral
diagnostics. They are not silently discarded:

```text
UNSUPPORTED_SETTING_POLICY=FAIL_CLOSED_DIAGNOSTIC
```

Unknown values and settings receive no inferred authority. They remain
unresolved or unsupported through the existing diagnostic and residual paths.

## Independent navigation, asset, and CSS findings

The heading-link carrier gap is independent of ACSS authority:

```text
HEADING_LINK_GAP_RESOLVED_BY_NO_ACSS_DECISION=NO
```

It remains a generic capability family for a later gate. This record does not
implement it.

Unresolved asset diagnostics are independent of ACSS authority:

```text
ASSET_GAPS_RESOLVED_BY_NO_ACSS_DECISION=NO
```

This record does not alter asset resolution.

The old empty-authority probe produced diagnostic-only residual counts. Keep
them historical and provisional until the newly authorized canonical
normalization runs:

```text
PREVIOUS_EMPTY_AUTHORITY_RESIDUAL_COUNT=48
PREVIOUS_REQUIRED_RESIDUAL_CLASSIFICATION=44_PROVISIONAL
PREVIOUS_UNRESOLVED_VALUE_COUNT=32

CURRENT_CANONICAL_RESIDUAL_COUNT=NOT_YET_ESTABLISHED
CURRENT_CANONICAL_REQUIRED_RESIDUAL_COUNT=NOT_YET_ESTABLISHED
```

These counts are not canonical results. The next gate recomputes them from
scratch. It does not carry them forward based on an expectation that the
output will be similar.

## Authority lifecycle

This decision has an explicit lifecycle:

```text
UNRESOLVED
CONSERVATIVE_NO_ACSS_AUTHORIZED
SUPERSEDED_BY_PROVEN_SOURCE_AUTHORITY
```

The transition to `CONSERVATIVE_NO_ACSS_AUTHORIZED` is guarded by all of the
following:

```text
bounded provenance search complete
AND no sufficient environment/config binding found
AND owner authorizes conservative conversion policy
```

The bounded search and owner authorization satisfy this guard. The current
state is:

```text
CURRENT_AUTHORITY_LIFECYCLE_STATE=CONSERVATIVE_NO_ACSS_AUTHORIZED
```

That transition sets an empty external TokenSet context for canonical Romeo
conversion, supplies no structural-grid authority, supplies no named
breakpoint authority, and allows the future canonical normalization gate to
proceed after post-merge acceptance.

`CONSERVATIVE_NO_ACSS_AUTHORIZED` is terminal for the current evidence set. It
is not irreversible. A later transition to
`SUPERSEDED_BY_PROVEN_SOURCE_AUTHORITY` requires new direct evidence that
proves both:

```text
Romeo source environment
AND
bound configuration/settings identity
```

When superseded, the previous Romeo normalization is stale and canonical
normalization must run again under the newly proven authority. The earlier
conservative decision remains correct for the evidence available when it was
made.

## Canonical-normalization authorization boundary

This authority PR may authorize the next normalization evidence task. It does
not run that task. Until this PR is reviewed, merged, and its post-merge CI is
accepted, normalization remains unauthorized:

```text
CANONICAL_ROMEO_NORMALIZATION_AUTHORIZED=NO_PENDING_THIS_PR_ACCEPTANCE
```

After that acceptance, the recorded transition permits:

```text
CANONICAL_ROMEO_NORMALIZATION_AUTHORIZED=YES_AFTER_POST_MERGE_ACCEPTANCE
```

The following remain unauthorized:

```text
ROMEO_COMPONENTIZATION_AUTHORIZED=NO
ROMEO_IMPLEMENTATION_AUTHORIZED=NO
ROMEO_NATIVE_GENERATION_AUTHORIZED=NO
```

## Requirements for the next normalization gate

The next gate must run canonical Romeo normalization once under the context
above and recompute, from scratch:

- Design IR determinism.
- State-rule owner, rule, and residual counts.
- Every unresolved-value cause.
- Unsupported-selector inventory.
- Focus-suppression residuals.
- Visually required unsupported residuals.
- Unknown-requirement residuals.
- Navigation diagnostics.
- Asset diagnostics.
- Unsupported-setting diagnostics.
- Named-breakpoint diagnostics.

It must not assume the previous values `48`, `44`, or `32`, even if fresh
results happen to match them.

The gate must separate blockers into these independent families:

```text
TOKEN_OR_VALUE_GRAMMAR
SOURCE_LOCAL_VARIABLE
SELECTOR_OR_PSEUDO_ELEMENT
NAVIGATION_CARRIER
ASSET_RESOLUTION
SOURCE_SETTING
NAMED_BREAKPOINT
ACCESSIBILITY
OTHER
```

This authority record does not design or implement solutions for those gaps.

## Performance and runtime classification

This is build-time authority work:

```text
DATA_LAYER=COLD
RUNTIME_DB_CALLS=0

REDIS=N/A
POSTGRES=N/A
CACHE=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
```

## Scope and verdict

This PR records the owner policy only. It changes no source, production code,
tests, conversion matrix, generated artifact, adapter behavior, or Romeo
normalization result. No componentization or NativeGenerator work is
authorized here.

```text
CANONICAL_ROMEO_NORMALIZATION_RUN=NO
ROMEO_COMPONENTIZATION_AUTHORIZED=NO
ROMEO_IMPLEMENTATION_AUTHORIZED=NO
ROMEO_NATIVE_GENERATION_AUTHORIZED=NO
NEXT_GATE=CANONICAL_ROMEO_NO_ACSS_NORMALIZATION
STOP=NONE
```
