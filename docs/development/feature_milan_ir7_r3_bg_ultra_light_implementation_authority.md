# Feature Milan IR7 R3 `--bg-ultra-light` implementation authority

Status: proposed for independent review. This PR freezes a documentation-only
implementation contract. It does not change production code, tests, token maps,
generated assets, or Design IR.

```text
AUTHORITY_STATE=AWAITING_INDEPENDENT_REVIEW
IMPLEMENTATION_MAY_START=NO_CURRENT_SOURCE_VERSION_PROOF_CONTRACT
BASE_SHA=b2ce594c6f8e48fe6093966e328b3a1a0969d471
BASE_TREE=b89711063cf364513edb372dd81784fc8da8ece5
BASE_SIGNATURE=VALID
BASE_CI_RUN=41685653586
BASE_CI_RESULT=SUCCESS
CURRENT_MAIN_SHA=20b0acb2c808ec2746d09fd218317aa8513f3a9f
CURRENT_MAIN_TREE=d7a9964f90aa20fc635befebb60baaa92ba12b52
CURRENT_R3_EVIDENCE_CANDIDATE_BLOB=fb550ca5ee17e9693f62967e39d964c98b0bee5e
CURRENT_PROVENANCE_BASE_BLOB=839f7d060e06aa0fcb9e70d964821f442e6dacd8
R3_SOURCE_OUTPUT_ALIAS_STATUS=REVIEWED_EVIDENCE_CANDIDATE
R3_LIFECYCLE=AWAITING_INDEPENDENT_REVIEW
R3_ACCEPTED=NO
```

The `BASE_*` identities above record this PR branch's historical base. The
`CURRENT_MAIN_*` identities record the current main commit and tree; they do
not replace the branch-base identities.

## 1. Frozen owner

The current [R3 color-variable authority candidate](feature_milan_ir7_color_variable_authority.md)
and its [scoped provenance decision](../04_SOURCE_AND_PROVENANCE.md#feature-milan-r3-scoped-color-variable-publication-decision)
record this exact source-output evidence candidate:

```text
SOURCE=Automatic.css
SOURCE_VERSION=4.0.1
SOURCE_KEY=bg-ultra-light
VARIABLE=--bg-ultra-light
TOKEN_PATH=color.background.ultra_light
AUTHORITY_KIND=source_output_alias
OTHER_COLOR_VARIABLES=UNRESOLVED
```

The `--bg-ultra-light` source-output alias is a reviewed evidence candidate,
not an accepted R3 authority. The full R3 lifecycle remains
`AWAITING_INDEPENDENT_REVIEW`, and `R3_ACCEPTED=NO`.

The owner has also approved the single contextual-output condition recorded
in the [scoped provenance decision](../04_SOURCE_AND_PROVENANCE.md#feature-milan-r3-scoped-color-variable-publication-decision):
Automatic.css 4.0.1 emits this output when
`option-contextual-color-variables` is `on`; when it is `off`, the output is
not emitted. No other output conditions are authorized by that approval.

That token path already exists in `AutomaticCSS.Normalizer`. Its current
mapping treats `bg-ultra-light` as a semantic reference to
`color.neutral.ultra_light`. If a trusted source identity can be established
under a separately authorized proof contract, the proposed metadata will
record the conditional `--bg-ultra-light` output as an alias for this same
token path. It will not change the token's value or create a new color
interpretation.

Use this exact authority identifier and existing metadata record shape:

```text
AUTHORITY_ID=automatic-css-4.0.1:contextual-background:bg-ultra-light
```

```json
{
  "variable": "--bg-ultra-light",
  "kind": "source_output_alias",
  "authority_id": "automatic-css-4.0.1:contextual-background:bg-ultra-light",
  "source_key": "bg-ultra-light",
  "source_version": "4.0.1"
}
```

The owning path remains the TokenSet map key. Do not add a path field to the
metadata record.

## 2. Source identity and output enablement guards

The source/version guard is stricter than comparing a metadata string.
`AutomaticCSS.Loader` sets `source_version` from caller options and marks it
`caller_supplied` by default; `source_version_status` is also caller
overridable. `AutomaticCSS` passes those options through and does not verify
the settings input against the accepted fixture identity. The accepted
fixture hash therefore does not independently authenticate an input passed
through the current adapter boundary.

The testable fail-closed rule is:

- An externally verified Automatic.css 4.0.1 fixture/input is the only
  eligible source identity. A caller-provided `source_version == "4.0.1"`,
  including a caller-provided `source_version_status`, is not proof.
- Missing, unsupported, or caller-asserted source identity does not receive
  the alias authority. Do not default the missing version or infer it from
  adapter or compile-time versions.
- Even for an independently verified 4.0.1 input, emit the metadata record
  only when `option-contextual-color-variables` is exactly `on` and the
  existing entry has path `color.background.ultra_light` and source key
  `bg-ultra-light`. An `off`, missing, or other option value emits no alias
  authority and leaves the direct variable unresolved.

The current `AutomaticCSS.Loader` and `AutomaticCSS` APIs expose no
independent input-verification result for the Normalizer to consume. Under
those APIs, no caller option can establish the required source proof, so the
Normalizer must not emit this alias authority for an adapted input. A
Normalizer-only extension is not implementable safely until a separate
source-version proof contract is authorized. Do not change the Loader API or
add a provenance subsystem in this work. The current stop is
`STOP=R3_SOURCE_VERSION_PROOF_CONTRACT_MISSING`.

The existing direct-variable path applies only to an exact source expression
such as `var(--bg-ultra-light)`. Use the current Bricks normalization path and
the current direct-owner APIs. Do not add a Bricks property branch or a
Milan-specific production condition.

Do not add aliases for any other source variable or source key. Do not infer
ownership from variable spelling, token spelling, value equality, property
name, or candidate order. In particular, `--black-trans-10` and
`--text-dark-muted` remain unresolved.

## 3. Existing authority APIs and outcomes

Use `VariableAuthority.resolve_direct_owner/2` to select direct owners and
`VariableAuthority.resolve_direct_owner_terminal/2` to obtain a usable token
terminal. Leave ordinary `resolve/2` and `resolve_terminal/2` unchanged.
Do not change the existing direct-owner APIs, add a resolver module, or let
Bricks read `tokens_by_path` directly.

Resolve the owner during generation from the TokenSet. This operation needs no
mutable runtime state, cache, database, Redis, GenServer, or PubSub component.

A unique owner is usable only when its token is present, resolved, and exposes
a terminal accepted by the CSS consumer. These outcomes apply to the new
direct-owner path:

| State | Guard and API result | Normalization outcome |
| --- | --- | --- |
| `NO_OWNER` | No `source_output_alias` or `explicit_project_contract` path exists. `resolve_direct_owner/2` and its terminal companion return `{:error, :no_authority}`. Reference-only paths do not count as owners. | Keep the direct expression unresolved. |
| `UNIQUE_OWNER` | Exactly one distinct owner path exists. `resolve_direct_owner/2` returns `{:ok, candidate}`. The candidate must be present and resolved, and the terminal API must return `{:ok, candidate, terminal}`. | Succeed only after the CSS consumer accepts the terminal. |
| `AMBIGUOUS_OWNERS` | More than one distinct owner path exists. The direct-owner APIs return `{:error, :ambiguous_candidates}`. Equal terminal values do not remove ambiguity. | Keep unresolved; do not select by ordering. |
| `OWNER_TOKEN_MISSING` | The selected owner path is absent from the TokenSet. The terminal API returns `{:error, :token_missing}`. | Keep unresolved. |
| `OWNER_TOKEN_UNRESOLVED` | The selected token has unresolved status. The terminal API returns `{:error, :token_unresolved}`. | Keep unresolved. |
| `OWNER_TERMINAL_UNAVAILABLE` | The resolved token has no supported CSS terminal. The terminal API returns `{:error, :token_value_unavailable}`. | Keep unresolved. |

Multiple owner records on one path remain one owner path. A distinct second
path carrying either owner kind remains ambiguous. Do not fall back to
`source_reference` evidence.

## 4. Native package boundary

A native package mapping is required. `TokenBridge.package_css_variable/1`
returns an unknown-path error when no direct mapping exists. Neither
`native_shared_v3.json` nor `native_hero_v1.json` currently maps
`color.background.ultra_light`.

The exact package mapping proposed for the later implementation is:

```text
TOKEN_PATH=color.background.ultra_light
PACKAGE_VARIABLE=--lf-color-background-ultra-light
PACKAGE_COLLISION_COUNT=0
TOKEN_PATH_COLLISION_COUNT=0
```

The candidate follows TokenBridge's existing token-path and CSS-variable
patterns. Its terminal representation uses the existing Normalizer reference
from `color.background.ultra_light` to `color.neutral.ultra_light`.
`resolve_reference_values` resolves that reference from the TokenSet. The
existing direct-owner terminal API and `CSSValue.candidate/1` accept only
supported resolved terminal forms; TokenBridge then applies its CSS safety
checks. This mapping adds no literal color or source-variable passthrough.
If the token is missing, unresolved, non-serializable, or unsafe, generation
must fail closed.

The later production change must update
`apps/live_frames/priv/token_maps/native_shared_v3.json` with this mapping in
the same implementation change as the Normalizer metadata case. Focused tests
must cover:

- `apps/live_frames/test/live_frames/automatic_css_adapter_test.exs`
- `apps/live_frames/test/live_frames/tokens/variable_authority_test.exs`
- `apps/live_frames/test/live_frames/bricks_design_ir_test.exs`
- `apps/live_frames/test/live_frames/styling/token_bridge_test.exs`
- `apps/live_frames/test/live_frames/styling/assets_drift_test.exs`

Because the package map feeds generated CSS, regenerate and commit both
`apps/live_frames/assets/css/theme/lf_theme.css` and
`apps/live_frames/priv/static/live_frames/css/live_frames.css`
deterministically. Do not hand-edit either asset or inline
`var(--bg-ultra-light)` or a guessed color value.

## 5. Later implementation tests

The implementation change must verify:

- The exact alias record appears on `color.background.ultra_light`, with the
  exact source version, source key, and authority ID above.
- A caller-supplied `source_version == "4.0.1"` and caller-supplied status do
  not establish source compatibility or emit this authority.
- Missing or unsupported source identity does not emit this authority.
- With the current adapter APIs, an option `on` value does not overcome the
  missing source proof; alias metadata remains absent and the direct variable
  unresolved.
- The approved source-level condition is `on` emits and `off` does not emit.
  Missing or other option values fail closed. Positive adapter-resolution
  tests require a separate authorized source-version proof contract and must
  not simulate proof with caller-supplied metadata.
- Existing `VariableAuthority` direct-owner APIs resolve the alias without
  changing generic candidate behavior.
- Missing tokens, unresolved tokens, unsupported terminals, and distinct
  conflicting owner paths fail closed.
- `--black-trans-10` and `--text-dark-muted` remain unresolved.
- No unrelated TokenSet authority metadata changes.
- The package mapping is exact and unique, TokenBridge output is deterministic,
  and both generated assets match deterministic build output.
- No Design IR schema version bump occurs.

Do not add or run these tests in this authority-freeze change.

## 6. Scope and stop conditions

This authority proposes only the one `--bg-ultra-light` source-output alias
and its necessary native package mapping. The contextual-output condition is
limited to the owner-approved `on`/`off` fact cited above. It does not
authorize production implementation before independent acceptance and merge.
Implementation remains blocked until a separate source-version proof contract
is authorized. This document does not change the Loader or Normalizer trust
boundary, `VariableAuthority.resolve/2`, `resolve_terminal/2`, generic
variable candidate rules, other color authority, TokenSet schema, or Design
IR schema. It does not start R4 or R5.

Stop without a workaround if any of these conditions occurs:

```text
STOP=MAIN_OR_R3_AUTHORITY_CHANGED
STOP=UNPROVEN_SOURCE_OUTPUT_ALIAS
STOP=UNSUPPORTED_SOURCE_VERSION
STOP=BG_ULTRA_LIGHT_PACKAGE_BOUNDARY_UNRESOLVED
STOP=NEW_TOKEN_PATH_REQUIRED
STOP=DIRECT_OWNER_API_CHANGE_REQUIRED
STOP=GENERIC_VARIABLE_AUTHORITY_CHANGE_REQUIRED
STOP=R3_OTHER_COLOR_AUTHORITY_REQUIRED
STOP=R3_PROVENANCE_SCOPE_EXPANSION_REQUIRED
STOP=R3_SOURCE_VERSION_PROOF_CONTRACT_MISSING
STOP=IMPLEMENTATION_STARTED_DURING_AUTHORITY_FREEZE
STOP=DOC_SCOPE_EXPANSION_REQUIRED
STOP=PRIMARY_CHECKOUT_MUTATED
STOP=REPEATED_FIX_FAILURE_ROOT_CAUSE_REVIEW_REQUIRED
```

The next action after this authority candidate is independent review:

```text
STOP=AWAIT_R3_BG_IMPLEMENTATION_AUTHORITY_REVIEW
```
