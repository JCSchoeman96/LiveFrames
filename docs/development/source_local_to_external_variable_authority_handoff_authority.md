# Source-local to external variable authority handoff

## Authority status

After independent acceptance and merge, this record authorizes one exact
handoff from a source-local custom property to an already accepted external
`VariableAuthority` candidate. It is source-neutral and does not authorize a
general external fallback.

```text
A1=SOURCE_LOCAL_TO_EXTERNAL_VARIABLE_AUTHORITY_HANDOFF
A1_AUTHORITY=PASS
A1_AUTHORITY_STATUS=READY_FOR_INDEPENDENT_ACCEPTANCE
A1_SCOPE=DOCS_ONLY
A1_AUTHORITY_DESIGN_AUTHORIZED=YES
A1_IMPLEMENTATION_AUTHORIZED=NO
SUPERSESSION_EFFECTIVE_AFTER=INDEPENDENT_AUTHORITY_ACCEPTANCE_AND_MERGE

GENERAL_EXTERNAL_FALLBACK=NO
EXACT_LOCAL_TO_EXTERNAL_HANDOFF=AUTHORIZED
DEFINITIVE_LOCAL_ABSENCE_REQUIRED=YES
LOCAL_EXTERNAL_COLLISION_FAIL_CLOSED=YES
EXTERNAL_UNIQUE_CANDIDATE_REQUIRED=YES
EXTERNAL_RESOLVED_TOKEN_REQUIRED=YES
EXTERNAL_TERMINAL_REVALIDATION_REQUIRED=YES
RECURSIVE_EXTERNAL_RESOLUTION=NO
VARIABLE_AUTHORITY_RESOLVE_2_CHANGE=NO
VARIABLE_AUTHORITY_ADDITIVE_TERMINAL_API=AUTHORIZED
DIRECT_TOKENS_BY_PATH_ACCESS_FROM_LOCAL_RESOLVER=NO
```

The [source-local authority](css_local_custom_property_resolution_authority.md)
freezes `EXTERNAL_VARIABLE_FALLBACK=NO`. The [C2 authority](frame_d_bounded_nested_local_resolution_authority.md)
also excludes local-to-external fallback. After this record is independently
accepted and merged, it supersedes those prohibitions only for the production
defined below. The existing documents remain unchanged. All other source-local
lookup and failure rules remain in force.

```text
EXACT_PASSTHROUGH_A_TO_B_HANDOFF=AUTHORIZED
ALL_OTHER_LOCAL_LOOKUP_FAILURES_REMAIN_FAIL_CLOSED=YES
```

## Repository evidence

The requested `main` head moved after authorization. The requested head remains
in the fetched `main` ancestry. The authority, resolver, token, and focused
test files named for this task have no changes between the prior checkout and
the reconciled head.

```text
REQUESTED_MAIN_SHA=f0e8202e7176bf79aa4904a7834a1a9ef9efbd58
REQUESTED_MAIN_TREE=fa081430393c95af4a9e18ec1391138c993534ac
REQUESTED_MAIN_IN_FETCHED_ANCESTRY=YES

BASE_SHA=2a7787c5d928ad4f6fb6e9ea72b62b723ff2dc13
BASE_TREE=26023437d46474aed09603fb31c817d719a1a48a
SCOPED_SURFACE_DIFF_FROM_PRIOR_CHECKOUT=NONE
```

## Namespaces and scope

Keep these namespaces separate:

```text
SOURCE_LOCAL_CUSTOM_PROPERTY
EXTERNAL_VARIABLE_AUTHORITY
```

The local property `A` remains a source-local custom property. The external
property `B` remains an external authority lookup. The compiler must not turn
`A` into a `Token`, create inferred token authority, or infer framework
authority from a variable name, token path, source value, or CSS convention.

A1 applies only to reference records already accepted by the existing
normalizer and resolver. It does not change selector, property, compound-value,
or consumer grammar. It performs no runtime work and has no side effects.

## Exact admitted production

The only new handoff is:

```text
consumer -> var(A)

A = exact var(B)

LOCAL_B_RESULT=NO_ELIGIBLE_LOCAL_DEFINITION

VariableAuthority.resolve(B).state=:unique_candidate
candidate.token_present?=true
candidate.resolution_status=:resolved

Token.resolved_value = accepted terminal CSS value
```

`A` must already pass the existing local-name, owner, provenance, scope,
target, and resource checks. Its complete selected value must match the
existing exact single-`var()` passthrough grammar. A reference with a fallback,
prefix, suffix, composition, or additional dependency is outside A1.

The local lookup for `B` runs first. Definitive absence means the existing
`:no_local_definition` result from this exact dependency lookup after it
completes within the current owner, provenance, scope, path, and resource
bounds. External lookup is allowed only after that result. Ambiguity,
unsupported scope, cross-owner reference, conflicting source order,
self-reference, cycle, unsupported fallback, resource exhaustion, unsupported
terminal, and any other unsafe result stop resolution. The implementation must
not rewrite such a result as local absence to enter the external path.

```text
FAILED_LOCAL_LOOKUP != GENERAL_EXTERNAL_FALLBACK
HANDOFF_PRECONDITION=
  EXACT_PASSTHROUGH_A_TO_B
  + DEFINITIVE_LOCAL_B_ABSENCE
  + UNIQUE_PREEXISTING_EXTERNAL_AUTHORITY_B
```

The existing presence-based collision check remains in force for exact local
names `A` and `B`. If it finds an external authority entry for a local name,
including an eligible local `B`, the resolver returns the existing
`:external_authority_collision` result. Candidate uniqueness or token status
does not override that collision. A1 does not choose local or external meaning
when both namespaces claim the same exact name.

```text
LOCAL_EXTERNAL_COLLISION=FAIL_CLOSED
LOCAL_EXTERNAL_COLLISION_PREFERENCE=NONE
```

An eligible local `B` with no external name collision uses the existing local
resolution path. A missing or rejected external candidate never becomes a
local definition.

## External authority requirements

Use the existing `VariableAuthority` resolution semantics. Handoff requires
all of the following:

- `VariableAuthority.resolve/2` returns `:unique_candidate` for the exact
  validated name `B`.
- The unique candidate has `token_present? == true` and
  `resolution_status == :resolved`.
- The selected token's `resolved_value` is a terminal binary CSS value.
- The value passes the existing size limit, custom-property dependency checks,
  CSS declaration safety, and value normalization for the consumer.

Keep the existing behavior and return shape of `VariableAuthority.resolve/2`
unchanged. Its candidate metadata does not expose `Token.resolved_value`, so
the A1 resolver must not reach into `VariableAuthority.tokens_by_path` or
other internal indexes to retrieve the terminal.

This authority authorizes exactly one additive public `VariableAuthority` API
for retrieving the terminal from an already-authorized unique candidate. Its
conceptual form is `VariableAuthority.resolve_terminal(index, variable)`;
the implementation plan may settle the final function name to match repository
naming conventions. The API must use existing candidate selection and return
candidate evidence plus `Token.resolved_value` only for a unique candidate
whose token is present and resolved. Its internal compiler outcome contract
is:

```text
NO_AUTHORITY
    -> fail closed
AMBIGUOUS_CANDIDATES
    -> fail closed
UNIQUE_CANDIDATE + TOKEN_MISSING
    -> fail closed
UNIQUE_CANDIDATE + TOKEN_UNRESOLVED
    -> fail closed
UNIQUE_CANDIDATE + TOKEN_RESOLVED
    -> return candidate evidence + Token.resolved_value
```

These are API outcomes, not new user-facing diagnostics. The API must not
infer authority, choose among ambiguous candidates, recursively resolve an
external dependency, parse CSS, or validate the terminal. It must not add
Romeo- or ACSS-specific behavior or require a `Token` or `TokenSet` schema
change. The source-local resolver uses this public API and remains responsible
for A1 terminal validation under the existing bounded CSS safety rules.

The handoff must not infer authority from:

- variable or token-path naming;
- ACSS conventions or a selected source profile;
- source-value resemblance;
- Romeo identity, fingerprints, or requirement classification.

No external recursion is allowed. The bridge consumes a token already marked
resolved and does not look up dependencies within its value.

```text
RECURSIVE_EXTERNAL_RESOLUTION=NO
EXTERNAL_CHAIN_A_TO_B_TO_C=NOT_AUTHORIZED
```

## Terminal validation

Revalidate the external terminal under the same bounded consumer rules used
for accepted local terminals:

- require a binary value;
- enforce the existing 4,096-byte terminal limit;
- reject unresolved `var()` dependencies;
- reject fallback syntax;
- pass the value through the existing CSS safety and normalization boundary.

An invalid or unsupported external terminal fails closed. The bridge must not
resolve another external variable, preserve unresolved browser-time lookup, or
turn a malformed value into a literal.

## Lifecycle

```text
DEPENDENCY_DISCOVERED
    |
    v
LOCAL_B_LOOKUP
    ├─ eligible local B, external name collision
    │      -> FAIL_CLOSED
    │
    ├─ eligible local B, no external name collision
    │      -> EXISTING_LOCAL_PATH
    │
    ├─ unsafe, ambiguous, or unsupported local result
    │      -> FAIL_CLOSED
    │
    └─ definitive local absence
           |
           v
       EXTERNAL_B_LOOKUP
           ├─ no authority
           │      -> FAIL_CLOSED
           ├─ ambiguous authority
           │      -> FAIL_CLOSED
           ├─ external token missing
           │      -> FAIL_CLOSED
           ├─ external token unresolved
           │      -> FAIL_CLOSED
           └─ unique resolved token
                  |
                  v
             TERMINAL_VALIDATION
                  ├─ invalid -> FAIL_CLOSED
                  └─ valid   -> RESOLVED
```

Terminal states are `EXISTING_LOCAL_PATH`, `RESOLVED`, and `FAIL_CLOSED`.
Resolution happens during build-time normalization. It has no runtime side
effects.

## Failure and diagnostic behavior

The current adapter turns a failed source-local reference into the existing
`bricks.custom_css.unresolved_value` residual. A1 adds no public diagnostic or
Design IR state. Keep `VariableAuthority` lookup states available to the
resolver for fail-closed decisions, but do not expose a new A1-specific public
reason.

| External or collision result | Outcome | Public diagnostic behavior |
| --- | --- | --- |
| No external authority | Fail closed; produce no terminal | Existing `bricks.custom_css.unresolved_value` residual |
| Ambiguous external authority | Fail closed; select no candidate | Existing `bricks.custom_css.unresolved_value` residual |
| Candidate token missing | Fail closed; produce no terminal | Existing `bricks.custom_css.unresolved_value` residual |
| Candidate token unresolved | Fail closed; produce no terminal | Existing `bricks.custom_css.unresolved_value` residual |
| Invalid external resolved terminal | Reject under existing terminal and CSS checks | Existing resolver or normalizer failure path; no A1-specific diagnostic |
| Local/external exact-name collision | Fail closed with the existing collision result | Existing unresolved residual behavior |

Do not add a diagnostic atom merely to distinguish external lookup failures.
Do not collapse a local ambiguity, scope error, ownership error, conflict,
cycle, fallback, or resource failure into the definitive-local-absence case.

```text
DIAGNOSTIC_MAPPING_FROZEN=YES
NEW_PUBLIC_DIAGNOSTIC_REQUIRED=NO
NEW_DESIGN_IR_STATE=NO
```

## Romeo and ACSS boundaries

The capability is generic. It does not alter Romeo's source authority or
canonical empty-`TokenSet` context.

```text
ROMEO_EXTERNAL_AUTHORITY_CHANGED=NO
ROMEO_ACSS_AUTHORITY_CHANGED=NO
ROMEO_CANONICAL_TOKEN_SET_CHANGED=NO
ROMEO_RESIDUAL_MOVEMENT_CLAIM_AUTHORIZED=NO
```

This work does not resolve `--space-m` producer semantics, add ACSS-specific
authority, or investigate transparency variables. An A1 proof must use a
synthetic `TokenSet` with one unique resolved candidate. The existing
`--content-gap` fixture may be used only for a generic adapter test; it does
not establish ACSS authority for Romeo.

## Implementation constraints

The later implementation may change only the source-local resolver path, add
the one additive public `VariableAuthority` terminal retrieval API defined
above, and add focused tests needed for this exact handoff. The existing
`VariableAuthority.resolve/2` behavior and return shape remain unchanged. This
record does not authorize changes to:

```text
Design IR
NativeGenerator
runtime behavior
Phoenix runtime
browser CSS variable resolution
StylePrecedence
Token schema
TokenSet schema
ACSS normalizer
CustomCssParser
CompoundCssValue
```

No other `VariableAuthority` implementation change is authorized. In
particular, the source-local resolver must not access
`VariableAuthority.tokens_by_path` directly.

Keep processing deterministic and within existing input, dependency, ancestry,
and terminal bounds. Do not add Redis, Cachex, ETS, GenServer, PubSub, Oban,
runtime caching, or database persistence.

The implementation task must use TDD. Its first test must prove that exact
`A -> var(B)` handoff resolves only when local `B` is absent and the external
candidate is unique, present, resolved, and terminal. Run the focused test and
observe the expected failure before implementation. Add separate fail-closed
tests for every external lookup state and for the listed local failure
boundaries. Then implement the smallest resolver change and rerun the focused
tests. Do not use Romeo as a proof fixture.

```text
SPACE_M_WORK_PERFORMED=NO
TRANSPARENCY_TOKEN_WORK_PERFORMED=NO
PRIVATE_CORPUS_ACCESSED=NO
IMPLEMENTATION_CHANGED=NO
```
