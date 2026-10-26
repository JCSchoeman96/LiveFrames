# LiveFrames A1B derived Token CSS candidate bridge authority

```text
A1B=DERIVED_TOKEN_CSS_CANDIDATE_BRIDGE
A1B_AUTHORITY=PASS
A1B_AUTHORITY_STATUS=READY_FOR_INDEPENDENT_REVIEW
A1B_SCOPE=DOCS_ONLY
A1B_AUTHORITY_DESIGN=AUTHORIZED
A1B_IMPLEMENTATION_AUTHORIZED=NO

BASE_SHA=22c590dca62ab55d0baee95f3c71e6345aebbcb3
BASE_TREE=8acfd09d408425399aa84bf990b3c817e8584bad

A1_AUTHORITY=ACCEPTED
A1_IMPLEMENTATION=ACCEPTED
POST_MERGE_CI_RUN=40367864858
POST_MERGE_CI=PASS
```

This document defines one narrow extension to the accepted [A1 authority](source_local_to_external_variable_authority_handoff_authority.md). A1B keeps the selected authority, local-first lookup, collision handling, terminal validation, and public failure behavior intact. It authorizes no Romeo conversion and no A2 work.

## Authority decision

The existing representation boundary remains `LiveFrames.Tokens.CSSValue`. A1B does not add another Token or TokenSet projection API.

```text
CSS_REPRESENTATION_OWNER=LiveFrames.Tokens.CSSValue

NEW_TOKEN_API=NO
NEW_TOKENSET_API=NO
TOKEN_SCHEMA_CHANGE=NO
TOKENSET_SCHEMA_CHANGE=NO

AUTOMATIC_CSS_DEPENDENCY_FROM_VARIABLE_AUTHORITY=NO
AUTOMATIC_CSS_DEPENDENCY_FROM_BRICKS_RESOLVER=NO

CSSVALUE_CANDIDATE_1_SEMANTICS_CHANGED=NO
CSSVALUE_CANDIDATE_3_SEMANTICS_CHANGED=NO
CSSVALUE_CANDIDATE_TRUSTED_TERMINAL=NO
```

`CSSValue.candidate/1` selects a CSS-value candidate. It does not certify safe or executable CSS. `VariableAuthority.resolve_terminal/2` may use it only for the single resolved structured shape authorized below. The existing `SourceLocalCustomPropertyResolver` continues to validate every returned terminal.

The Fluid sizing authority keeps `CSSValue` as the candidate boundary and keeps `AutomaticCSS.FluidClamp` as an adapter compatibility surface. A1B does not move `FluidClamp` or make VariableAuthority or Bricks depend on Automatic.css.

## Narrow supersession of A1

The A1 authority currently requires:

> The selected token's `resolved_value` is a terminal binary CSS value.

A1B supersedes only that representation requirement, and only inside `VariableAuthority.resolve_terminal/2`. The representation selection becomes:

```text
binary Token.resolved_value
OR
binary CSSValue.candidate(token), only for a resolved structured-derived Token
```

The public `VariableAuthority.resolve/2` contract and candidate evidence do not change. The Bricks resolver must still use the public `resolve_terminal/2` result. It must not read `VariableAuthority.tokens_by_path` or another internal index.

Successful `resolve_terminal/2` results retain the existing shape `{:ok, candidate_evidence, terminal}`. A1B changes only how the third element is selected.

All other A1 authority remains in force. A1B does not change exact local-reference admission, local-first semantics, collision behavior, unique external authority selection, owner or provenance checks, resource bounds, fail-closed handling, terminal validation, or public diagnostics. It does not add general external fallback or recursive external resolution.

## Exact terminal selection

`VariableAuthority.resolve_terminal/2` first follows its existing checks for authority uniqueness, token presence, and `resolution_status == :resolved`. It then selects the representation in this order:

```text
if is_binary(token.resolved_value):
    return exactly token.resolved_value

else if is_map(token.resolved_value)
        and token.resolved_value["type"] == "derived":
    result = CSSValue.candidate(token)
    if result is {:ok, candidate} and is_binary(candidate):
        return candidate
    otherwise:
        fail closed

else:
    fail closed
```

A binary `resolved_value` always wins. The implementation must not call `CSSValue.candidate/1` first for that case because the existing function prefers `metadata["css_expression"]` over a binary `resolved_value`.

The structured-derived branch may use any candidate returned by the existing `CSSValue.candidate/1` implementation, including an ACSS-generated metadata expression. That candidate is untrusted input to the existing A1 terminal checks. A1B does not validate, normalize, or otherwise change `CSSValue.candidate/1`.

The authority selects by the exact existing unique authority record. It does not infer a recipe from a token name, variable name, provenance, or source profile. It does not resolve dependencies inside a derived token.

## Unsupported resolved shapes

Only a map whose string-keyed `type` equals `derived` can enter the candidate branch. These shapes remain unavailable to A1B, even when their metadata contains a `css_expression`:

```text
responsive
fluid_domain
fluid_value
fluid_scale
fluid_scale_step
unknown semantic maps
arbitrary JSON objects
```

Dedicated Fluid and TokenBridge realization paths remain unchanged. Their existence does not authorize them through the A1 external terminal bridge.

## Candidate trust and terminal validation

`CSSValue.candidate/1` remains a representation selector. The following stay false:

```text
METADATA_CSS_EXPRESSION_GLOBALLY_TRUSTED=NO
TOKEN_VALIDATION_CSS_EXPRESSION_TRUST_CHANGE=NO
```

Do not change Token validation to make A1B work. Do not treat `metadata["css_expression"]` as globally trusted. A1B changes only which resolved-token shapes `VariableAuthority.resolve_terminal/2` can hand to the existing resolver.

The existing `SourceLocalCustomPropertyResolver` terminal validation remains mandatory for both the preserved binary path and the derived candidate path:

```text
binary candidate
within the existing terminal byte limit
CSSDeclaration.safe_value? passes
no unresolved var(...)
no fallback syntax
no recursive external resolution
```

If the terminal passes, `CustomCssNormalizer` continues applying its property-specific declaration normalization. A candidate that fails any existing check follows the current A1 failure path and public diagnostic behavior.

The terminal API may return this new internal failure reason when a resolved token has an unsupported representation, `CSSValue.candidate/1` returns an error, or the candidate is not binary:

```text
:token_value_unavailable
```

This reason is internal to `VariableAuthority.resolve_terminal/2`. The Bricks resolver maps it through its existing unavailable path. It adds no public Bricks diagnostic and does not alter A1's public failure taxonomy.

## Lifecycle

```text
UNIQUE_EXTERNAL_TOKEN_SELECTED
    ↓
TOKEN_RESOLVED?
    ├─ NO -> UNAVAILABLE
    └─ YES
          ↓
REPRESENTATION_SHAPE
    ├─ binary resolved_value
    │      -> REPRESENTATION_CANDIDATE, exact binary
    │
    ├─ structured map with type "derived"
    │      ↓
    │   CSSValue.candidate/1
    │      ├─ error or non-binary -> UNAVAILABLE
    │      └─ binary candidate -> REPRESENTATION_CANDIDATE
    │
    └─ all other shapes
           -> UNAVAILABLE
                 ↓
EXISTING_A1_TERMINAL_VALIDATION
    ├─ invalid -> FAIL_CLOSED
    └─ valid   -> CSS_TERMINAL
```

Terminal states are:

```text
CSS_TERMINAL
UNAVAILABLE
FAIL_CLOSED
```

The bridge performs deterministic build-time Token representation work. It has no side effects and introduces no runtime or browser dependency.

## Required source-neutral proof

Implementation evidence must use synthetic `Token` and `TokenSet` values. Do not use Romeo conversion or a Romeo fixture.

Positive controls:

| Synthetic token | Expected result |
| --- | --- |
| Resolved Token with a binary `resolved_value`, including conflicting CSS metadata | `resolve_terminal/2` returns the exact binary `resolved_value`. |
| Resolved structured-derived Token with a safe binary CSS candidate | The candidate reaches the existing A1 terminal validation. |

Negative controls:

| Synthetic token or candidate | Expected result |
| --- | --- |
| Structured-derived Token with no candidate | Unavailable through the existing A1 path. |
| Structured-derived Token with a `var(...)` candidate | Existing terminal validation rejects it. |
| Structured-derived Token with an unsafe candidate | Existing terminal validation rejects it. |
| Structured-derived Token with an oversized candidate | Existing resource-limit behavior rejects it. |
| Responsive map with CSS metadata | Unavailable before candidate selection. |
| `fluid_value` with CSS metadata | Unavailable before candidate selection. |
| Unknown map with CSS metadata | Unavailable before candidate selection. |
| `fluid_domain`, `fluid_scale`, or `fluid_scale_step` | Unavailable through A1B. |

Use the existing focused Token, VariableAuthority, and source-local resolver tests as the implementation test locations. Do not modify tests in this authority-only task.

## Future effect, without authority movement

The current ACSS normalization path can resolve `spacing.content_gap` through `spacing.scale.medium` and preserve structured derived data as the effective `resolved_value`. Its deterministic CSS representation remains in metadata. A1B would let this class of resolved structured-derived Token reach A1's existing terminal validation.

This is a technical compiler capability only:

```text
DERIVED_ACSS_SPACING_TECHNICALLY_PROJECTABLE=YES

ROMEO_EXTERNAL_AUTHORITY_CHANGED=NO
ROMEO_ACSS_AUTHORITY_CHANGED=NO
ROMEO_CANONICAL_TOKEN_SET_CHANGED=NO
ROMEO_RESIDUAL_MOVEMENT_CLAIM_AUTHORIZED=NO
```

No claim is made that Romeo may use this ACSS authority.

## A2 boundary

The known compound form is:

```css
calc(var(--content-gap) / 2)
```

Its current external `--content-gap` authority resolves to a structured-derived Token. A2 grammar support alone cannot make this ACSS-backed path executable while A1B is absent.

```text
A2_MATERIAL_PATH_DEPENDS_ON_A1B=YES
A2_IMPLEMENTATION_AUTHORIZED=NO
```

This document does not define or authorize A2 grammar.

## Performance and scaling

A1B is bounded build-time work over the already selected Token. It adds no traversal or dependency expansion. Do not introduce ETS, GenServer, Redis, Cachex, PubSub, Oban, database persistence, or runtime caches.

## Change boundary

The later implementation may change only the representation branch in `VariableAuthority.resolve_terminal/2` and add focused synthetic tests. It must preserve these contracts:

```text
VariableAuthority.resolve/2
CSSValue.candidate/1
CSSValue.candidate/3
Token
TokenSet
TokenBridge
AutomaticCSS.Normalizer output bytes
AutomaticCSS.FluidClamp
SourceLocalCustomPropertyResolver local-first semantics
local/external collision behavior
GENERAL_EXTERNAL_FALLBACK=NO
RECURSIVE_EXTERNAL_RESOLUTION=NO
```

The A1 binary path, its priority, all existing A1 validation, and downstream property-specific normalization remain unchanged.

## Authority status

```text
VARIABLE_AUTHORITY_TERMINAL_BRIDGE_EXTENSION=AUTHORIZED
BINARY_A1_PATH_PRESERVED=YES
BINARY_RESOLVED_VALUE_PRIORITY=YES
STRUCTURED_DERIVED_CANDIDATE_ALLOWED=YES

RESPONSIVE_A1B_PROJECTION=NO
FLUID_VALUE_A1B_PROJECTION=NO
FLUID_SCALE_A1B_PROJECTION=NO
FLUID_SCALE_STEP_A1B_PROJECTION=NO
UNKNOWN_MAP_A1B_PROJECTION=NO

A1_EXISTING_TERMINAL_VALIDATION_PRESERVED=YES
TOKEN_SCHEMA_CHANGE=NO
TOKENSET_SCHEMA_CHANGE=NO
TOKEN_VALIDATION_CHANGE=NO

AUTOMATIC_CSS_DEPENDENCY_FROM_VARIABLE_AUTHORITY=NO
AUTOMATIC_CSS_DEPENDENCY_FROM_BRICKS_RESOLVER=NO

A2_MATERIAL_PATH_DEPENDS_ON_A1B=YES
A2_IMPLEMENTATION_AUTHORIZED=NO

ROMEO_AUTHORITY_CHANGED=NO
ROMEO_RESIDUAL_MOVEMENT_CLAIM_AUTHORIZED=NO

IMPLEMENTATION_AUTHORIZED=NO
```

Implementation remains outside this task and requires independent authority review.
