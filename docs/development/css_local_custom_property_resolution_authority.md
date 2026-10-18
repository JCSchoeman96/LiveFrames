# CSS local custom-property resolution authority

## Authority status

This record defines a source-neutral policy for resolving bounded CSS custom
properties during Bricks normalization. It does not authorize resolver code,
compound-value grammar, another Romeo normalization, componentization, or native
generation.

```text
BASE_SHA=b30778d04ee016b8815a222a85c92869bc5e60a9
BASE_TREE=c9d21c2c6e6f00b35c1a00f32a031b3384d14664
BASE_CI=39128177913 SUCCESS

CSS_LOCAL_CUSTOM_PROPERTY_STATE=AUTHORITY_READY_PENDING_PR_ACCEPTANCE
CSS_LOCAL_CUSTOM_PROPERTY_IMPLEMENTATION_AUTHORIZED=NO
CSS_COMPOUND_VALUE_IMPLEMENTATION_AUTHORIZED=NO
ROMEO_COMPONENTIZATION_AUTHORIZED=NO
ROMEO_NATIVE_GENERATION_AUTHORIZED=NO
```

Implementation remains unauthorized until this authority PR is independently
reviewed, merged, and verified against its exact merge SHA.

The accepted programme records are [the post-NAV-CARRIER canonical rerun](feature_romeo_post_nav_carrier_canonical_rerun.md), [the canonical gap decomposition](feature_romeo_canonical_gap_decomposition.md), and [the no-ACSS normalization record](feature_romeo_canonical_no_acss_normalization.md). Source privacy follows [source and provenance](../04_SOURCE_AND_PROVENANCE.md). The IR boundary follows [the Design IR specification](../03_DESIGN_IR_SPEC.md).

## Decision

Select **Option A, a bounded normalization-time source-local resolver**. A
resolver consumes only the effective CSS layer and provenance already selected
by `StylePrecedence`. It indexes local definitions for one owner and layer,
resolves only a unique permitted reference, sends the resulting terminal value
through the existing declaration and value checks, then emits an ordinary
Design IR style value.

The resolver consumes custom-property definitions as internal input. It emits
no definition into Design IR or generated CSS. It does not use `VariableAuthority`
to obtain a local value, infer token authority from a name, search shadowed
layers, or simulate browser cascade behavior.

Adopt **Policy P1, the transparent source-syntax policy**, for the four
currently unknown border-radius findings. Their requirement status remains
unknown. A generic local resolver may make them executable when the same
source-neutral eligibility checks used for every declaration pass. The owner
accepts that side effect because the resolver only removes indirection from
declarations already inside the generic selector, property, viewport, and state
grammar. The observed border-radius source shape has a finite numeric or
dimensional terminal value, and the existing property and value safety checks
still apply.

```text
UNKNOWN_BORDER_RADIUS_REQUIREMENT_STATUS_REMAINS=UNKNOWN
GENERIC_POLICY_MAY_RENDER_THEM_EXECUTABLE=YES
OWNER_POLICY_ACCEPTS_THIS_SIDE_EFFECT=YES
```

This policy does not relabel any finding as required. A failed ownership,
scope, resolution, or safety check leaves the declaration unresolved.

## Accepted finding counts

```text
CSS_LOCAL_CUSTOM_PROPERTY_TOTAL=20
CONFIRMED_REQUIRED=16
UNKNOWN_REQUIREMENT=4

CSS_COMPOUND_VALUE_TOTAL=8
COMPOUND_VALUE_DEPENDENT_FINDINGS=8
COMPOUND_VALUE_CONFIRMED_REQUIRED=8
CSS_COMPOUND_VALUE_IMPLEMENTATION_AUTHORIZED=NO
```

The eight compound-value findings depend on local-variable resolution. This
record defines the resolver interface only. It does not authorize grammar for
`FUNCTION_CALL`, `MULTI_TOKEN_VALUE`, or `VAR_REFERENCE_WITH_OPERATION`.

## Sanitized source-shape inventory

The canonical private artifact was treated as inert data. The inventory used
`CustomCssParser.parse/1` to count declaration and reference shapes. It did not
call the Bricks adapter or run a normalization.
No source CSS was executed, and no custom-property name, value, selector, raw
CSS, URL, or private source path is recorded here.

The evidence scan found two CSS-bearing strings and 21 parser frames, with no
parser rejects. Counts below describe source occurrences before per-owner
normalization. The accepted canonical inventory separately records four owner
scopes and four border-radius findings.

```text
CANONICAL_SOURCE_SHA256=0cf29929a25bc2485ece90375d8c0f90fa1710eac0439bc5decc13af11f03f63
CSS_STRING_COUNT=2
CSS_FRAME_COUNT=21
PARSER_REJECT_COUNT=0

LOCAL_DEFINITION_COUNT=9
LOCAL_REFERENCE_COUNT=25
DEFINITION_SCOPE_SHAPES=base/single-compound-selector:8;base/descendant-selector:1
REFERENCE_SCOPE_SHAPES=base/single-compound-selector:16;responsive/single-compound-selector:9

BASE_DEFINITION_COUNT=9
RESPONSIVE_DEFINITION_COUNT=0
STATE_DEFINITION_COUNT=0

SAME_RULE_DEFINITION_AND_USE_COUNT=0
ANCESTOR_TO_DESCENDANT_REFERENCE_COUNT=NOT_ESTABLISHED
CROSS_SELECTOR_REFERENCE_COUNT=21

MULTIPLE_DEFINITION_NAME_COUNT=0
DUPLICATE_IDENTICAL_DEFINITION_COUNT=0
CONFLICTING_DEFINITION_COUNT=0

ALL_VAR_REFERENCE_COUNT=30
DIRECT_VAR_REFERENCE_COUNT=13
DIRECT_LOCAL_VAR_REFERENCE_COUNT=10
NESTED_VAR_REFERENCE_COUNT=3
SYNTACTICALLY_NESTED_VAR_CALL_COUNT=0
VAR_WITH_FALLBACK_COUNT=0
SELF_REFERENCE_COUNT=0
CYCLE_COUNT=0

EXTERNAL_AUTHORITY_NAME_COLLISION_COUNT=NOT_ESTABLISHED
TERMINAL_VALUE_SHAPES=definition_leaves:numeric_or_dimension:4,single_keyword:1,other_single_token:1;local_reference_results:numeric_or_dimension:10,single_keyword:7,other_single_token:4,unbound_downstream_reference:4
```

`LOCAL_REFERENCE_COUNT` counts references whose exact name has a definition in
the same parsed CSS source. Five of the 30 `var()` calls have no such
same-source definition. Three of those five occur inside definition values;
their downstream names also have no local definition. Neither group is treated
as external authority.

`NESTED_VAR_REFERENCE_COUNT=3` counts definition values that themselves
contain a `var()` call. None points to another local definition. There are no
syntactically nested `var()` calls, fallbacks, self-references, or cycles among
the local definitions. `ANCESTOR_TO_DESCENDANT_REFERENCE_COUNT` remains
`NOT_ESTABLISHED` because the sanitized CSS selector scan alone does not prove
how those selectors map to ancestor nodes in each owner tree. The resolver must
prove that mapping from its bounded owner input before it uses inheritance.

The one source border-radius declaration shape has a same-source local
reference and a numeric or dimensional terminal shape. The canonical record
classifies its four owner findings as unknown. This supports P1 without
changing their requirement status.

## Architecture options

| Option | Source-neutral | Preserves authority boundaries | Requires IR change | Requires browser cascade semantics | Handles observed required findings | Unknown-rule side effect | Complexity | Decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A. Bounded normalization-time source-local resolver | Yes | Yes, if local and external namespaces remain separate | No | No | Yes, for uniquely owned local references with supported scope and terminal values; unresolved cases stay residuals | P1 may emit an unknown border-radius declaration when generic eligibility checks pass | Medium | **Selected** |
| B. Treat local definitions as `VariableAuthority` tokens | No | No | No schema change, but it changes token meaning | No | Only after false token authority is assigned | Promotes local source data and may leak it into token or ACSS paths | Low initially, high authority risk | Rejected |
| C. Preserve definitions and references in Design IR and generated CSS | Yes | Partly | Yes | Yes | Requires consumers to preserve runtime variable semantics | Unknown rules remain live in generated CSS | High across IR, renderer, serializer, and runtime | Rejected |
| D. General CSS custom-property and cascade engine | Broadly | No | Likely | Yes | Broader than the accepted required subset | Makes additional CSS behaviors executable | Very high and unbounded for this task | Rejected |

Option A keeps source-local substitution inside the adapter. The compiler can
produce ordinary normalized values without adding browser-time lookup,
Design IR fields, generator behavior, or runtime dependencies.

## Policy decision for unknown requirements

| Policy | Decision | Reason |
| --- | --- | --- |
| P1. Transparent source-syntax policy | **Selected** | A local variable is syntax indirection when ownership, scope, determinism, bounded terminal value, existing safety checks, and the existing generic consumer grammar all pass. The same rule applies to every source and finding. |
| P2. Requirement-gated local resolution | Rejected | The generic normalizer has no source-neutral fact that distinguishes the four unknown findings from otherwise identical required declarations. Gating these occurrences would require Romeo IDs, fingerprints, a source allowlist, or another per-property policy. |
| P3. Keep implementation blocked | Rejected | P1 provides a source-neutral rule for the side effect. P3 would keep the confirmed local-reference lane blocked without resolving the authority question. |

P1 applies only when every condition below is true:

- `StylePrecedence` supplies the effective layer and matching provenance.
- The local name passes the existing custom-property name boundary.
- The definition belongs to the same effective owner and layer as the
  reference.
- The target and definition scopes produce one deterministic local result.
- The terminal value stays within fixed size limits and contains no unresolved
  local or external reference.
- The terminal value passes the existing CSS safety and value normalization
  checks.
- The consumer selector, property, viewport, and state are already accepted
  by generic normalization.
- No token, TokenSet, ACSS, or named framework authority is inferred.

P1 does not grant a general right to render unknown declarations. It governs
only declarations that already use accepted generic syntax and pass these
checks. Unknown requirement labels remain unchanged in source evidence and
programme records.

## Separate variable namespaces

The implementation must keep these concepts distinct:

```text
SOURCE_LOCAL_CUSTOM_PROPERTY
EXTERNAL_VARIABLE_AUTHORITY
```

A source-local definition is not a `Token`, a `TokenSet` authority, ACSS
authority, external token provenance, or a named framework variable. Textual
name similarity grants no authority.

If the same exact name has both a local definition and a
`VariableAuthority` candidate, resolution fails with
`EXTERNAL_AUTHORITY_COLLISION`. The authority permits a presence-only collision
check against `VariableAuthority`; the implementation must discard its token
path and candidate values. It must not use `VariableAuthority.resolve/2` to
substitute a local definition.

The local resolver never falls back to external authority after a missing,
ambiguous, unsafe, or unsupported local lookup. The existing external-variable
path remains separate for a declaration that is independently routed through
its current external-authority contract. A failed local lookup cannot enter
that path as a fallback.

```text
EXTERNAL_VARIABLE_FALLBACK=NO
CUSTOM_PROPERTY_NAME_COLLISION_WITH_EXTERNAL_AUTHORITY=FAIL_CLOSED
```

The canonical run supplied an empty `TokenSet`, so the private evidence cannot
establish whether any local name collides with a populated external authority.
The collision count is therefore `NOT_ESTABLISHED`, not zero.

## Effective-layer provenance and scope

`StylePrecedence.resolve_with_custom_css_provenance/2` selects the effective
base custom-CSS layer and selected responsive custom-CSS layers. The resolver
must consume only those values and provenance records.

```text
EFFECTIVE_LAYER_PROVENANCE_REQUIRED=YES
SHADOWED_SOURCE_LAYER_LOOKUP=NO
ARBITRARY_GLOBAL_CLASS_SEARCH=NO
```

A class-layer definition belongs to the exact selected class reference and
owner provenance. An element-local definition belongs to that same owner. A
responsive layer may use a base definition only when both records have the
same effective provenance identity: owner source ID, layer origin, class ID,
class-reference index, and resolution authority identifiers. Responsive source
keys may differ only by the already selected viewport key. A different class
reference, element owner, or component is a different scope.

The scope used for a lookup is the tuple:

```text
(owner source ID, effective layer provenance, target node, viewport scope, state scope)
```

### Owner and selector scope

Definitions are available only to declarations within the owner subtree already
passed to `CustomCssNormalizer`. The resolver may use the current accepted
selector grammar and the supplied source-tree paths to prove that a definition
matches the reference target or an ancestor of that target.

A proven definition on the target node wins over inherited definitions. If no
direct definition exists, a definition on the nearest proven ancestor may
supply the value. All candidates at that node and scope must be unique or
identical duplicates under the rule below. A selector match that yields
multiple possible nodes, no proven ancestry, or a path outside the owner scope
fails closed. Siblings never inherit from one another.

```text
DEFINITION_SCOPE_OWNER=ONE_CUSTOM_CSS_OWNER_SOURCE_ID
DEFINITION_SCOPE_CLASS=EXACT_STYLEPRECEDENCE_SELECTED_CLASS_REFERENCE_OR_ELEMENT_LOCAL_LAYER
DESCENDANT_INHERITANCE=YES_ONLY_FOR_A_PROVEN_ANCESTOR_WITHIN_THE_SAME_OWNER_AND_LAYER
CROSS_OWNER_LOOKUP=NO
CROSS_COMPONENT_LOOKUP=NO
```

### Source order and duplicate definitions

`CustomCssParser` provides deterministic frame order inside the selected CSS
source. The resolver uses that order for stable diagnostics. It does not
simulate specificity or use later source order to hide conflicting definitions.

- A single definition at the resolved node and scope is selected.
- Identical definitions may coalesce only when name, owner, layer, selector,
  viewport, state, and terminal text all match.
- Different values for the same name and exact scope fail with
  `CONFLICTING_SOURCE_ORDER`.
- Candidates from different selectors that may both apply to the same node
  fail with `AMBIGUOUS_DEFINITION` unless the owner-tree match identifies one
  nearest ancestor under the inheritance rule.
- A duplicate property in one rule remains subject to the parser's existing
  rejection.

```text
SOURCE_ORDER_RULE=USE_PARSER_ORDER_FOR_STABLE_DIAGNOSTICS; NEVER_PICK_A_CONFLICTING_WINNER
MULTIPLE_DEFINITION_RULE=ONE_UNAMBIGUOUS_CANDIDATE_OR_FAIL
IDENTICAL_DUPLICATE_RULE=COALESCE_ONLY_IF_ALL_SCOPE_FIELDS_AND_TERMINAL_TEXT_MATCH
CONFLICTING_DUPLICATE_RULE=FAIL_CLOSED
```

### Responsive and state scope

The source evidence has base definitions and responsive references. It has no
responsive or state definitions and no state-scoped local references. The
following rules support the observed base-to-responsive shape and fail closed
for unobserved scope transitions.

```text
BASE_TO_BASE_REFERENCE=YES_WITHIN_THE_SAME_OWNER_AND_EFFECTIVE_LAYER
BASE_TO_RESPONSIVE_REFERENCE=YES_IF_PROVENANCE_MATCHES_AND_NO_RESPONSIVE_DEFINITION_OVERRIDES_IT
BASE_TO_STATE_REFERENCE=NO
RESPONSIVE_TO_RESPONSIVE_REFERENCE=NO
STATE_TO_STATE_REFERENCE=NO
RESPONSIVE_TO_STATE_REFERENCE=NO
RESPONSIVE_TO_BASE_REFERENCE=NO
VAR_FALLBACK_SUPPORTED=NO
NESTED_VAR_SUPPORTED=NO
SELF_REFERENCE_POLICY=FAIL_CLOSED
CYCLE_POLICY=FAIL_CLOSED
```

Responsive lookup may use a base definition only for the same target and exact
effective provenance identity. It does not infer a named breakpoint, combine
or compare media ranges, use an overlapping responsive definition, or change
a source media boundary. State-scoped variable lookup remains unsupported,
even when the state itself is an accepted generic state condition.

The three definition values with downstream `var()` references point to names
with no local definition in the evidence. They remain unresolved. The resolver
does not substitute a fallback, follow an unbounded chain, or consult external
authority for them.

## Resolution state machine

A successful reference follows this closed path:

```text
REFERENCE_DISCOVERED
  -> LOCAL_NAME_VALIDATED
  -> SCOPE_CANDIDATES_COLLECTED
  -> UNIQUE_DEFINITION_SELECTED
  -> TERMINAL_VALUE_RESOLVED
  -> SAFETY_REVALIDATED
  -> ACCEPTED
```

The following states stop resolution and retain the declaration as unresolved
or rejected with a stable diagnostic:

| State | Meaning |
| --- | --- |
| `INVALID_LOCAL_NAME` | The name does not pass the existing custom-property name boundary. |
| `NO_LOCAL_DEFINITION` | The name has no definition in the selected owner and effective layer. There is no local-to-external fallback. |
| `AMBIGUOUS_DEFINITION` | More than one different candidate applies at the same resolved node and scope. |
| `CONFLICTING_SOURCE_ORDER` | Conflicting values would require choosing a cascade winner. |
| `UNSUPPORTED_SCOPE` | The viewport or state transition is outside the explicit rules above. |
| `CROSS_OWNER_REFERENCE` | The definition and consumer have different owner source IDs. |
| `UNSUPPORTED_INHERITANCE` | The source-tree ancestry or selector target cannot be proven within the owner subtree. |
| `UNSUPPORTED_FALLBACK` | The reference has a fallback argument. |
| `UNSUPPORTED_NESTED_REFERENCE` | A definition value requires a second local substitution step. |
| `SELF_REFERENCE` | A definition refers to its own name. |
| `CYCLE` | The bounded local dependency graph contains a cycle. |
| `UNSAFE_TERMINAL_VALUE` | Existing CSS declaration safety rejects the terminal value. |
| `UNSUPPORTED_TERMINAL_VALUE` | Safety passes, but existing value normalization does not support the terminal form. |
| `EXTERNAL_AUTHORITY_COLLISION` | A local definition and an external authority candidate use the same exact name. |
| `CROSS_COMPONENT_REFERENCE` | A candidate would leave the current component boundary. |
| `RESOURCE_LIMIT_EXCEEDED` | A fixed input, graph, reference, ancestry, or terminal-value limit is exceeded. |

The resolver validates the local name before lookup. It builds a bounded
dependency graph from selected local definitions to identify self-reference
and cycles before accepting a terminal value. It does not recursively expand
source values. The supported resolution depth is one local lookup followed by
one terminal value.

## Terminal-value safety

A local definition is untrusted source data. A successful lookup must pass the
same property and value boundary as any other declaration:

```text
resolve local definition
  -> obtain bounded terminal source value
  -> validate the declaration with CSSDeclaration
  -> run existing CSS value normalization
  -> emit only the ordinary normalized Design IR value
```

The implementation must use the source-resolver origin where it accepts a
resolved declaration. It must retain existing rejection of unsafe external
URLs, expression-style content, structural delimiters, invalid property names,
and unsupported value forms. A value is not safe merely because a local
definition supplied it. No raw source text passes through to Design IR or CSS.

Source-local resolution returns a terminal string to the later bounded value
grammar. The resolver contract must be callable by future normalization of
`FUNCTION_CALL`, `MULTI_TOKEN_VALUE`, and `VAR_REFERENCE_WITH_OPERATION` forms.
This record does not define or authorize those grammar productions.

## Design IR and generator impact

The resolver terminates before ordinary style values enter Design IR. Source
custom-property definitions remain internal compiler inputs.

```text
LOCAL_DEFINITION_IR_EMISSION=NO
LOCAL_DEFINITION_NATIVE_CSS_EMISSION=NO

DESIGN_IR_DATA_SHAPE_CHANGE_REQUIRED=NO
DESIGN_IR_VERSION_BUMP_REQUIRED=NO
STYLE_VALUE_SCHEMA_CHANGE_REQUIRED=NO
IR_SERIALIZER_CHANGE_REQUIRED=NO
NATIVE_GENERATOR_CONTRACT_CHANGE_REQUIRED=NO
```

The resolved declaration uses existing literal or keyword style values. It does
not become a token reference because its source spelling resembles a token.
`NativeGenerator` receives no new runtime variable or cascade behavior. The
Fidelity declaration boundary must revalidate resolved values but requires no
schema or generator contract change.

## Bounds and performance

This is cold compiler work. The future implementation must enforce fixed
source-neutral limits and reject input that exceeds them. It must not truncate,
recursively expand, or rescan the whole document for each reference.

```text
DATA_LAYER=COLD_BUILD_TIME
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
RUNTIME_CACHE_CALLS=0
REDIS=N/A
POSTGRES=N/A
PGBouncer=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
100K_RUNTIME_CONCURRENCY=N/A

MAX_EFFECTIVE_LAYER_CSS_BYTES=65536
MAX_LOCAL_DEFINITIONS_PER_OWNER_LAYER=256
MAX_LOCAL_REFERENCES_PER_OWNER_LAYER=1024
MAX_OWNER_ANCESTRY_HOPS=64
MAX_TERMINAL_VALUE_BYTES=4096
MAX_LOCAL_SUBSTITUTION_DEPTH=1
```

Build one definition index per owner and effective layer. Key it by a validated
local name and exact viewport/state scope. Candidate lookup must be bounded by
the index; an ancestry walk stops at 64 nodes. Cycle detection uses a bounded
work list over at most 256 definitions and 1,024 edges. A resolver that reaches
a limit returns `RESOURCE_LIMIT_EXCEEDED`.

The expected work is `O(D + R * H)`, where `D` is the bounded definition count,
`R` is the bounded reference count, and `H` is the owner ancestry limit. It
must not perform a whole-document scan per reference, unbounded recursive
substitution, unbounded inheritance walks, or exponential expansion. No
runtime cache or service is needed.

## Future implementation ownership

The minimum likely production owners are:

```text
apps/live_frames/lib/live_frames/adapters/bricks/source_local_custom_property_resolver.ex
apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex
```

The focused resolver should own local-name validation, the one-layer
definition index, owner-bounded scope selection, dependency checks, terminal
value limits, and stable failure states. `CustomCssNormalizer` should pass the
`StylePrecedence` provenance and effective owner context, invoke the resolver
before ordinary value normalization, and retain existing residual behavior on
failure. It should not become a general cascade engine. No parser, Design IR,
conversion matrix, NativeGenerator, or production authority module needs to
change under this decision.

Expected focused tests are:

```text
apps/live_frames/test/live_frames/bricks_source_local_custom_property_resolver_test.exs
apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs
```

Use synthetic source-neutral cases. Cover exact layer provenance, base and
responsive scopes, proven ancestry, ambiguity, identical and conflicting
definitions, missing definitions, external-name collision, fallback and
nested-reference rejection, self-reference, cycles, terminal safety, size
limits, and preservation of unresolved diagnostics. Add integration cases for
ordinary base and responsive IR values. Do not add Romeo-specific production
policy or fixtures.

## Lifecycle and next gate

This record closes architecture, unknown-rule policy, scope, failure behavior,
IR impact, bounds, and implementation ownership. It therefore establishes
`AUTHORITY_READY_PENDING_PR_ACCEPTANCE` only. A later implementation PR must
wait for independent review, merge, and exact-head post-merge verification of
this authority.

```text
CSS_LOCAL_CUSTOM_PROPERTY_STATE=AUTHORITY_READY_PENDING_PR_ACCEPTANCE
CSS_LOCAL_CUSTOM_PROPERTY_IMPLEMENTATION_AUTHORIZED=NO
CSS_COMPOUND_VALUE_IMPLEMENTATION_AUTHORIZED=NO

PRODUCTION_FILES_CHANGED=NO
TEST_FILES_CHANGED=NO
CONVERSION_MATRIX_CHANGED=NO
IMPLEMENTATION_STARTED=NO

ROMEO_COMPONENTIZATION_AUTHORIZED=NO
ROMEO_NATIVE_GENERATION_AUTHORIZED=NO
NEXT_GATE=REVIEW_AND_ACCEPT_CSS_LOCAL_CUSTOM_PROPERTY_RESOLUTION_AUTHORITY
STOP=NONE
```
