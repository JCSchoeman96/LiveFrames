# FRAME D bounded nested local resolution authority

## Authority status

This document defines C2, FRAME D bounded nested local resolution. It is an
authority-planning record for independent review. It does not authorize
implementation or an implementation plan.

~~~text
C2=FRAME_D_BOUNDED_NESTED_LOCAL_RESOLUTION
AUTHORITY_STATUS=READY_FOR_FINAL_REVIEW
AUTHORITY_SCOPE=DOCS_ONLY
C2_IMPLEMENTATION_AUTHORIZED=NO
IMPLEMENTATION_PLAN_AUTHORIZED=NO
ROMEO_COMPONENTIZATION_AUTHORIZED=NO
NATIVE_GENERATION_AUTHORIZED=NO
~~~

C2 adds one bounded source-local passthrough hop to the existing
SourceLocalCustomPropertyResolver. It does not create another resolver or a
general CSS custom-property engine.

## Entry evidence

The authority is based on the accepted C1 merge and canonical post-C1
public-adapter evidence.

~~~text
REPOSITORY=JCSchoeman96/LiveFrames
BASE_SHA=0a409a1f41f9cf493a1efb4884ff4251bc1d3d7e
BASE_TREE=718a64cc2196e72d3183ff4dd7cb17fae706ad49
BASE_CI=39911038953 completed/success

C1_APPROVED_HEAD=a6857961bccce1579ef6da1e3418e054e289ab27
C1_MERGE_SHA=5e2a1775f786f13cc3598cd6d58c5409efec42cd
C1_MERGE_IN_BASE_ANCESTRY=YES
C1_POST_MERGE_CI=39911029984 completed/success
C1_AUTHORITY_PRESENT=YES
C1_IMPLEMENTATION_PRESENT=YES
C2_MATERIAL_MOVEMENT_SINCE_ACCEPTED_BASE=NO
~~~

The exact accepted post-C1 state is:

~~~text
C1_CAUSAL_OBJECTIVE_MET=YES
C1_ACTUAL_DIRECT_UNLOCK_COUNT=12
C1_ACCEPTANCE=PASS
C1_PROGRAMME_STATUS=ACCEPTED

POST_C1_TOTAL_DIAGNOSTICS=77
POST_C1_CUSTOM_CSS_RESIDUALS=32
POST_C1_UNRESOLVED_VALUE=16
POST_C1_UNSUPPORTED_SELECTOR=16
POST_C1_REQUIRED=8
POST_C1_UNKNOWN=20
POST_C1_BLOCKING=28

POST_C1_REQUIRED_FINGERPRINT_COUNT=8
POST_C1_REQUIRED_PREFIX_DIGEST=383b426ac85d6a4958d3fc95d2c799e2abe85d6c4a57156ee24e6171947b50fa
POST_C1_INTERNAL_CAUSAL_RETRACE=NO
~~~

The eight unchanged required fingerprint prefixes are:

~~~text
4e38d541683a
65924823bba3
99893c69ecce
999f3ce30356
9a0ea1e06064
a99f584aeb79
e9adc28bb056
fa494ac736ae
~~~

The accepted pre-C1 causal record labelled these same eight fingerprints
FRAME_D_NESTED_LOCAL_REFERENCE. That historical label is carried forward
because the fingerprints survived unchanged. No fresh internal causal trace
was performed after C1.

## Problem statement and sanitized evidence

The existing resolver supports a selected local definition whose value is
terminal. Its frozen maximum local substitution depth is one. If that selected
definition contains a downstream var() dependency, resolution currently fails
closed with unsupported_nested_reference.

The measured FRAME D source shape is one exact passthrough:

~~~text
consumer -> var(A)
A -> var(B)
B -> terminal
~~~

The causal record found one SINGLE_VAR_PASSTHROUGH shape among the eight
required FRAME D findings. Four are LOCAL findings and four are COMPOUND
findings. The same generic nested-definition shape was also present in
12 definition records across four owners in the unknown set. The record did not
reclassify those findings.

~~~text
FRAME_D_REQUIRED_FINDINGS=8
FRAME_D_LOCAL_REQUIRED_FINDINGS=4
FRAME_D_COMPOUND_REQUIRED_FINDINGS=4
FRAME_D_REQUIRED_SHAPE=SINGLE_VAR_PASSTHROUGH
UNKNOWN_SET_NESTED_DEFINITION_RECORDS=12
UNKNOWN_SET_OWNER_COUNT=4
POST_C1_PRIVATE_RETRACE=NO
~~~

These are accepted, sanitized observations. They do not authorize source IDs,
owner IDs, CSS-property conditions, private names, or fingerprint branches in
implementation.

## Architecture options

| Option | Decision | Reason |
| --- | --- | --- |
| A. Extend SourceLocalCustomPropertyResolver for one exact passthrough hop | Selected | The resolver already owns the definition index, selection, owner and provenance isolation, dependency edges, ancestry lookup, cycle detection, and limits. One bounded non-recursive lookup reuses that authority. |
| B. Add a generic recursive resolver | Rejected | The evidence establishes one passthrough hop. General recursion would add unmeasured cascade and expression semantics and increase failure complexity. |
| C. Pre-expand definitions in CustomCssNormalizer | Rejected | It would duplicate definition selection, ownership, provenance, ancestry, and dependency semantics already owned by the resolver. |
| D. Use VariableAuthority for the second hop | Rejected | A source-local dependency remains source-local. An external token candidate cannot supply the value or act as fallback. |

~~~text
SELECTED_C2_ARCHITECTURE=OPTION_A_EXISTING_RESOLVER_ONE_HOP_PASSTHROUGH
SECOND_RESOLVER=NO
GENERIC_RECURSION=NO
VARIABLE_AUTHORITY_FALLBACK=NO
NORMALIZER_OWNS_NESTED_RESOLUTION=NO
~~~

Repository inspection confirms that Option A fits the current boundary.
SourceLocalCustomPropertyResolver already indexes definitions by local name,
path, and scope; selects one deterministic candidate; discovers dependency
edges; finds dependency definitions at the same path or nearest accepted
ancestor; identifies cycles; checks external-name collisions; and enforces the
existing caps. Its current dependency-state classification rejects every
non-self downstream dependency as unsupported_nested_reference. C2 changes that
bounded classification and resolves one selected dependency within this
existing resolver.

## Exact passthrough grammar

Only a definition whose entire value matches this production is eligible for
the additional hop:

~~~text
PASSTHROUGH_DEFINITION :=
  CSS_WS* "var(" CSS_WS* LOCAL_NAME CSS_WS* ")" CSS_WS*

CSS_WS :=
  U+0020 SPACE
  U+0009 TAB
  U+000A LF
  U+000D CR
  U+000C FF
~~~

LOCAL_NAME uses the resolver's existing local-name validator. C2 adds no
second local-name regex or name authority. The definition must contain exactly
one reference and no other value tokens. The grammar is literal as written:
comments and other spellings are not added as whitespace or syntax.

The following remain unsupported:

~~~text
var(--b, fallback)
prefix var(--b)
var(--b) suffix
calc(var(--b))
var(--b) var(--c)
nested function composition
NBSP as CSS syntactic whitespace
~~~

No other syntax becomes eligible through this authority.

## Resolution and scope semantics

The consumer's first definition is selected using the current resolver's
owner, effective provenance, viewport, state, path, and definition selection
rules. A direct definition at the target path wins. If none exists, only the
nearest proven ancestor within the owner and existing ancestry bound may be
selected. Existing ambiguity and conflicting-source-order behavior remains
unchanged.

If the selected root definition is an exact passthrough A -> var(B), select B
with the existing dependency lookup rules:

- B must be a local definition in the same effective owner and exact effective
  provenance identity.
- Dependency selection uses a base definition scope.
- A definition for B at the selected A definition's target path wins.
- Otherwise use the nearest accepted ancestor of that path.
- A sibling or foreign owner, component, or provenance is ineligible.
- The existing maximum of 64 owner ancestry hops remains in force.
- Existing deterministic selection, ambiguity, duplicate, and conflict rules
  apply to B.
- The selected B definition must be terminal. It must not require another
  substitution.
- External-authority collision checks apply to every selected local name,
  including B. A collision fails closed and never supplies a value.

~~~text
MAX_NESTED_LOCAL_PASSTHROUGH_HOPS=1
MAX_LOCAL_SUBSTITUTION_DEPTH=2
~~~

Substitution depth counts selected local definitions, not recursive calls:
the consumer may select A and then B, and B must return a terminal value.
This authority does not authorize A -> B -> C. Implement the bounded second
selection without recursive expansion. Reuse the existing dependency lookup
and graph analysis; do not add a second ancestry algorithm.

The terminal returned by the resolver still passes the existing
consumer-specific CSS declaration and value safety checks. Successful output
remains the ordinary normalized literal style value. Definitions remain
internal compiler inputs and never enter Design IR or generated CSS.

## Definition compiler-input policy

CustomCssNormalizer currently calls
SourceLocalCustomPropertyResolver.definition_compiler_input_state/3 before
treating a local definition as internal compiler input. C2 cannot work if that
guard rejects the exact passthrough before batch resolution.

~~~text
EXACT_ONE_HOP_PASSTHROUGH_DEFINITION_COMPILER_INPUT=SUPPORTED
FALLBACK=UNSUPPORTED
SELF_REFERENCE=UNSUPPORTED
CYCLE=UNSUPPORTED
MULTI_HOP=UNSUPPORTED
ARBITRARY_VAR_BEARING_VALUE=UNSUPPORTED
~~~

The guard accepts only the entire exact passthrough production above. It
classifies syntax for the existing batch resolver; it does not select B or
resolve a value itself. Batch resolution remains responsible for B's
existence, selection, scope, collision, cycle, terminal, and resource checks.
No normalizer bypass or pre-expansion is authorized.

## Failure taxonomy

Preserve the existing fail-closed resolver outcomes:

| Input or failed guard | Resolver outcome |
| --- | --- |
| A -> A | self_reference |
| A -> B -> A | cycle |
| A -> var(B, fallback) | unsupported_fallback |
| A -> B -> C | unsupported_nested_reference |
| B has no eligible local definition | no_local_definition |
| B has multiple distinct eligible selector identities | ambiguous_definition |
| B has conflicting definitions for one selector identity | conflicting_source_order |
| B requires a responsive or state-scoped definition outside the accepted scope rules | unsupported_scope |
| A or B collides with an exact name in external authority | external_authority_collision |
| Foreign owner data or unproven ancestry | existing cross_owner_reference or unsupported_inheritance outcome |
| Definition, reference, dependency-edge, ancestry, or terminal-byte cap exceeded | resource_limit_exceeded |

An ordinary direct local reference continues to use its existing behavior.
Malformed passthroughs, unsupported value composition, and any downstream
dependency beyond the one admitted hop fail closed. Do not add a public
diagnostic reason for C2. CustomCssNormalizer retains its existing residual
mapping and fail-closed behavior.

## Unknown-set side-effect policy

Carry forward Policy P1, the transparent source-syntax policy, for C2.

~~~text
C2_POLICY=P1_TRANSPARENT_SOURCE_SYNTAX_CARRY_FORWARD
REQUIREMENT_GATING=NO
ROMEO_SPECIFIC_BRANCHING=NO
GENERIC_SIDE_EFFECT=ACCEPTED_ONLY_IF_EXPLICITLY_RECORDED_BY_C2_AUTHORITY
REQUIREMENT_CLASSIFICATION=UNCHANGED
C2_AUTHORITY_RECORDS_GENERIC_SIDE_EFFECT_ACCEPTANCE=YES
~~~

An exact one-hop passthrough may become executable for any source only when
the same generic owner, provenance, scope, dependency, collision, terminal,
consumer-grammar, and CSS safety guards pass. The owner accepts that this
source-neutral rule may make an unknown requirement finding executable.
Requirement labels remain unchanged. Do not infer that all unknowns become
executable or predict a post-C2 unknown count.

This policy follows the existing local custom-property authority, which
rejected requirement-gated resolution because it would need source IDs,
fingerprints, an allowlist, or another per-property condition. The accepted
unknown-set evidence establishes that nested definitions exist; it does not
authorize Romeo-specific exceptions.

## Lifecycle

The lifecycle is internal resolver behavior. It does not imply a public state
machine struct.

~~~text
NOT_APPLICABLE
    |
    v
ROOT_DEFINITION_SELECTED
    |
    | exact terminal
    +--------------------------> TERMINAL_RESOLVED
    |
    | exact one-hop passthrough
    v
PASSTHROUGH_CLASSIFIED
    |
    v
DEPENDENCY_DEFINITION_SELECTED
    |
    v
DEPENDENCY_TERMINAL_VALIDATED
    |
    v
TERMINAL_RESOLVED
~~~

| Transition | Required guards | Side effect |
| --- | --- | --- |
| NOT_APPLICABLE to ROOT_DEFINITION_SELECTED | Consumer reference, local name, owner, provenance, scope, path, and batch limits pass existing checks. | Reuse the existing definition index and selection rules. |
| ROOT_DEFINITION_SELECTED to TERMINAL_RESOLVED | The selected definition has no dependency calls and passes existing terminal byte and definition checks. | Return the existing terminal string for consumer safety validation. |
| ROOT_DEFINITION_SELECTED to PASSTHROUGH_CLASSIFIED | The complete selected definition matches the exact single-reference grammar; fallback, self-reference, and resource guards pass. | Record one bounded dependency name. |
| PASSTHROUGH_CLASSIFIED to DEPENDENCY_DEFINITION_SELECTED | B is found by the existing same-owner, same-provenance, base-scope, same-target-or-nearest-ancestor lookup; selection is unique and collision checks pass. | Reuse the selected B record; do not consult external authority. |
| DEPENDENCY_DEFINITION_SELECTED to DEPENDENCY_TERMINAL_VALIDATED | B is terminal, within the byte limit, has no fallback or unresolved dependency, is not cyclic, and meets existing definition constraints. | Accept one terminal value for the existing consumer safety checks. |
| Any active state to FAIL_CLOSED | Any grammar, lookup, scope, provenance, cycle, collision, safety, or resource guard fails. | Return the existing resolver failure and preserve normalizer residual behavior. |

TERMINAL_RESOLVED and FAIL_CLOSED are terminal states. No transition leaves
either terminal state. Every failure stops expansion; no failure enters
VariableAuthority.

## Resource and performance review

This work runs during cold build-time normalization. Preserve the existing
limits and add only the one structural C2 bound:

~~~text
MAX_LOCAL_DEFINITIONS=256
MAX_LOCAL_REFERENCES=1024
MAX_LOCAL_DEFINITIONS_PER_OWNER_LAYER=256
MAX_LOCAL_REFERENCES_PER_OWNER_LAYER=1024
MAX_OWNER_ANCESTRY_HOPS=64
MAX_TERMINAL_VALUE_BYTES=4096
MAX_DEPENDENCY_EDGES=1024
MAX_NESTED_LOCAL_PASSTHROUGH_HOPS=1

DATA_LAYER=BUILD_TIME_COLD
REDIS=NOT_APPLICABLE
ETS_CACHEX=NOT_APPLICABLE
POSTGRES=NOT_APPLICABLE
PUBSUB=NOT_APPLICABLE
OBAN=NOT_APPLICABLE
PGBouncer=NOT_APPLICABLE

UNBOUNDED_RECURSION=NO
UNBOUNDED_GRAPH_WALK=NO
EXISTING_EDGE_CAP_PRESERVED=YES
EXISTING_REFERENCE_CAP_PRESERVED=YES
~~~

Compute each bounded passthrough outcome once during the existing definition
index or dependency-analysis phase, then reuse it for consumer references.
Do not walk a dependency chain once per reference. Work remains bounded by the
existing definition, reference, edge, and ancestry caps plus one additional
dependency selection per eligible definition. Do not add runtime caches,
database calls, network calls, or service infrastructure.

## Security and privacy constraints

Treat imported CSS and definition values as untrusted data. Preserve the
existing local-name validator, owner and provenance isolation, deterministic
selection, external collision checks, byte and graph limits, and terminal
consumer safety checks. Never emit raw definition text, source selectors,
private variable names, or private values in diagnostics or Design IR.

No raw private Romeo source, raw CSS, private selector, private variable name,
private value, or private path is included in this authority. Evidence is
limited to accepted counts, shape classes, and the already accepted short
fingerprint prefixes and digest above. The examples use generic synthetic
symbols only.

## Expected implementation boundary

This authority does not authorize implementation. If later authorized, the
expected minimal implementation surface is:

~~~text
EXPECTED_PRODUCTION_FILE:
  apps/live_frames/lib/live_frames/adapters/bricks/source_local_custom_property_resolver.ex

EXPECTED_TEST_FILES:
  apps/live_frames/test/live_frames/bricks_source_local_custom_property_resolver_test.exs
  apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs

CUSTOM_CSS_NORMALIZER_PRODUCTION_CHANGE=NO
COMPOUND_CSS_VALUE_CHANGE=NO
CUSTOM_CSS_PARSER_CHANGE=NO
STYLE_PRECEDENCE_CHANGE=NO
DESIGN_IR_CHANGE=NO
CSS_DECLARATION_CHANGE=NO
VARIABLE_AUTHORITY_CHANGE=NO
NATIVE_GENERATOR_CHANGE=NO
RUNTIME_CHANGE=NO
~~~

If implementation requires a production file outside this boundary, stop for
owner review with C2_EXPECTED_IMPLEMENTATION_BOUNDARY_INVALID. Do not silently
broaden the feature.

## Future implementation test obligations

Use source-neutral synthetic records. The focused tests must prove:

- A -> B -> terminal resolves successfully.
- A -> B -> C fails closed with unsupported_nested_reference.
- The definition compiler-input guard accepts the exact passthrough and
  rejects prefix, suffix, calc composition, multiple references, comments, and
  NBSP whitespace forms.
- Self-reference, a two-node cycle, and fallback fail closed with the existing
  outcomes.
- A missing B, ambiguous B, and conflicting B fail closed with the existing
  outcomes.
- A downstream external-authority collision fails closed and never substitutes
  the external candidate.
- Cross-owner and cross-provenance dependencies fail closed.
- Unsupported state scope fails closed, and unsupported responsive definition
  scope remains unchanged.
- The 64-hop ancestry boundary remains unchanged.
- Dependency-edge, definition, reference, and terminal-byte caps remain
  enforced.
- A resolved terminal still passes consumer-specific CSS safety.
- C1 transition behavior remains unchanged.
- C1 implementation behavior is unchanged by the C2 resolver path.
- Legacy direct local resolution remains unchanged.
- Compound behavior remains unchanged.
- FRAME C remains fail-closed.
- Generic behavior does not branch on Romeo component IDs, owner IDs, residual
  fingerprints, specific CSS properties, private-source names, or source IDs.

## Non-goals and authorization gates

C2 does not authorize:

- A -> B -> C or deeper resolution, arbitrary recursion, or a configurable
  depth.
- Arbitrary expression substitution, fallback var(), or browser cascade
  simulation.
- Cross-owner, cross-provenance, responsive-definition, or state-scoped
  dependency resolution.
- Local-to-external fallback, token inference, ACSS authority, or named
  breakpoint authority.
- Changes to StylePrecedence, CustomCssParser, CompoundCssValue, Design IR,
  CSSDeclaration, VariableAuthority, NativeGenerator, or runtime behavior.
- FRAME C, C3A, C3B, componentization, or Romeo native generation.
- A Romeo fingerprint allowlist or requirement-gated behavior.

The accepted causal record measured four marginal required unlocks for C2
after C1: four LOCAL findings. This is an expectation from pre-C1 causal
analysis, not a post-C2 measurement. Four COMPOUND findings remain dependent
on later C3 work.

~~~text
C2_EXPECTED_REQUIRED_MARGINAL_UNLOCK=4
C3A_IMPLEMENTATION_AUTHORIZED=NO
C3B_IMPLEMENTATION_AUTHORIZED=NO

AUTHORITY_REVIEW_AND_MERGE_REQUIRED_BEFORE_IMPLEMENTATION_PLAN=YES
C2_IMPLEMENTATION_AUTHORIZED=NO
~~~

After independent authority review and merge, a separate implementation plan
and authorization gate are required. This document does not start that phase.
