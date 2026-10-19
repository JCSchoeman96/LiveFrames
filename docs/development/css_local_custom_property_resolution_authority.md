# CSS local custom-property resolution authority

## Authority status

This record defines a source-neutral policy for resolving bounded CSS custom
properties during Bricks normalization. It does not authorize resolver code,
compound-value grammar, another Romeo normalization, componentization, or native
generation.

```text
PR_251_MERGED=YES
PR_251_AUTHORITY_ACCEPTED=NO
PR_251_POST_MERGE_REVIEW_FOUND_OPEN_SCOPE_CONTRACTS=YES
PR_251_HEAD=d0f055b62f70a21fda311e8ceb653f9dcd116870
PR_251_MERGE_SHA=64a6ee93d9eeb6c23cc810235184c6ebece7b2f5
PR_251_MERGE_TREE=57cae5cd5176552d309f3dfb6c5efaa08469f8c1
PR_251_POST_MERGE_CI=39136736344 SUCCESS

CORRECTION_BASE_SHA=4d0388606831562dc1b344a2bbf2e1169af52c42
CORRECTION_BASE_TREE=7bed181b96aabbe2afeed23a4f57d0d31e998082
CORRECTION_BASE_CI=39136743693 SUCCESS
CORRECTION_REASON=TARGET_RELATION_AND_SELECTOR_SCOPE_WERE_NOT_CLOSED

CSS_LOCAL_CUSTOM_PROPERTY_STATE=AUTHORITY_READY_PENDING_PR_ACCEPTANCE
CSS_LOCAL_CUSTOM_PROPERTY_IMPLEMENTATION_AUTHORIZED=NO
CSS_COMPOUND_VALUE_IMPLEMENTATION_AUTHORIZED=NO
ROMEO_COMPONENTIZATION_AUTHORIZED=NO
ROMEO_NATIVE_GENERATION_AUTHORIZED=NO
```

Implementation remains unauthorized until this authority PR is independently
reviewed, merged, and verified against its exact merge SHA.

PR #251's merge and passing CI did not constitute authority acceptance. This
post-merge correction closes the required target and selector-scope contracts
from accepted canonical evidence. Its own PR must still be independently
reviewed and accepted before implementation can be authorized.

The accepted programme records are [the post-NAV-CARRIER canonical rerun](feature_romeo_post_nav_carrier_canonical_rerun.md), [the canonical gap decomposition](feature_romeo_canonical_gap_decomposition.md), and [the no-ACSS normalization record](feature_romeo_canonical_no_acss_normalization.md). Source privacy follows [source and provenance](../04_SOURCE_AND_PROVENANCE.md). The IR boundary follows [the Design IR specification](../03_DESIGN_IR_SPEC.md).

## Decision

Select **Option A, a bounded normalization-time source-local resolver**. A
resolver consumes only the effective CSS layer and provenance already selected
by `StylePrecedence`. It indexes local definitions for one owner and layer,
resolves only a unique permitted reference, sends the resulting terminal value
through the existing declaration and value checks, then emits an ordinary
Design IR style value.

```text
SELECTED_ARCHITECTURE=OPTION_A
OPTION_A_VERDICT=SELECTED_BOUNDED_NORMALIZATION_TIME_RESOLVER
```

The resolver consumes custom-property definitions as internal input. It emits
no definition into Design IR or generated CSS. It does not use `VariableAuthority`
to obtain a local value, infer token authority from a name, search shadowed
layers, or simulate browser cascade behavior.

Adopt **Policy P1, the transparent source-syntax policy**, for the four
currently unknown border-radius findings. Their requirement status remains
unknown. A generic local resolver may make an unknown declaration executable
only when the same source-neutral eligibility checks used for every declaration
pass. The owner accepts that generic side effect. In the current canonical
evidence, the border-radius frame's target relation is unprovable under the
accepted selector authority, so all four owner findings remain fail-closed
residuals. This is not a Romeo-specific exception and does not change P1.

```text
UNKNOWN_BORDER_RADIUS_REQUIREMENT_STATUS_REMAINS=UNKNOWN
GENERIC_POLICY_MAY_RENDER_THEM_EXECUTABLE=YES
OWNER_POLICY_ACCEPTS_THIS_SIDE_EFFECT=YES
UNKNOWN_BORDER_RADIUS_OWNER_FINDING_COUNT=4
UNKNOWN_BORDER_RADIUS_FINDINGS_EXECUTABLE=0
UNKNOWN_BORDER_RADIUS_FINDINGS_REMAIN_FAIL_CLOSED=4
UNPROVABLE_UNKNOWN_REFERENCE_DISPOSITION=FAIL_CLOSED_RESIDUAL
SELECTED_UNKNOWN_RULE_POLICY=P1
POLICY_P1_VERDICT=SELECTED_TRANSPARENT_SOURCE_SYNTAX_POLICY
P1_POLICY_CHANGED=NO
```

This policy does not relabel any finding as required. A failed ownership,
scope, resolution, or safety check leaves the declaration unresolved.

## Accepted finding counts

```text
ACCEPTED_LOCAL_PROPERTY_FINGERPRINT_COUNT=20
ACCEPTED_CONFIRMED_REQUIRED_FINGERPRINT_COUNT=16
ACCEPTED_UNKNOWN_BORDER_RADIUS_FINGERPRINT_COUNT=4

MATCHED_CANONICAL_LOCAL_PROPERTY_FRAME_IDENTITY_COUNT=5
MATCHED_OWNER_FINDINGS_PER_FRAME_IDENTITY=4
CONFIRMED_REQUIRED_FRAME_IDENTITY_COUNT=4
UNKNOWN_BORDER_RADIUS_FRAME_IDENTITY_COUNT=1

CONFIRMED_REQUIRED_OWNER_FINDING_COUNT=16
CONFIRMED_REQUIRED_OWNER_FINDINGS_COVERED=16
CONFIRMED_REQUIRED_OWNER_FINDINGS_UNRESOLVED=0

LOCAL_REFERENCE_COUNT=25
LOCAL_REFERENCE_OCCURRENCES_IN_CANONICAL_LOCAL_PROPERTY_FRAMES=19
LOCAL_REFERENCE_OCCURRENCES_OUTSIDE_CANONICAL_LOCAL_PROPERTY_FINDINGS=6
OUTSIDE_REFERENCE_PRIMARY_LANE=CSS_COMPOUND_VALUE

CANONICAL_SELECTOR_FINDING_COUNT=12
CONFIRMED_REQUIRED_SELECTOR_FINDING_COUNT=0
UNKNOWN_SELECTOR_FINDING_COUNT=12
CSS_SELECTOR_LANE_COUNT_CHANGED=NO
CSS_SELECTOR_REQUIREMENT_CLASSIFICATION_CHANGED=NO

CSS_COMPOUND_VALUE_TOTAL=8
COMPOUND_VALUE_DEPENDENT_FINDINGS=8
COMPOUND_VALUE_CONFIRMED_REQUIRED=8
CSS_COMPOUND_VALUE_IMPLEMENTATION_AUTHORIZED=NO
CSS_COMPOUND_VALUE_LANE_CHANGED=NO
```

The accepted canonical residual fingerprints reconstruct five source-frame
identities with four owner-specific findings each: four confirmed-required
frame identities produce 16 required findings, and one unknown border-radius
frame identity produces four unknown findings. The 25 source local-reference
occurrences are a separate unit. Nineteen occur in those five canonical
local-property frames; six occur in two compound-value frames and are not
additional local-property findings. Those six remain within the existing
compound-value lane. The eight compound-value findings depend on local-variable
resolution, but this record does not authorize grammar for `FUNCTION_CALL`,
`MULTI_TOKEN_VALUE`, or `VAR_REFERENCE_WITH_OPERATION`.

## Local-name validation

The canonical local definition and reference names pass the selected validator.
The resolver validates the exact source spelling with the existing
`CSSDeclaration.safe_property?/1` boundary and the custom-property prefix
requirement. This is the sole resolver name contract; it does not add a regex
or normalize names.

```text
LOCAL_NAME_VALIDATOR=CSSDeclaration.safe_property?/1 AND String.starts_with?(name, "--")
CANONICAL_LOCAL_DEFINITION_NAMES_PASS_SELECTED_VALIDATOR=YES
CANONICAL_LOCAL_REFERENCE_NAMES_PASS_SELECTED_VALIDATOR=YES
LOCAL_NAME_CASE_SENSITIVE=YES
LOCAL_NAME_NORMALIZATION=NONE
LOCAL_NAME_CASE_FOLDING=NO
LOCAL_NAME_REGEX_DUPLICATED_IN_RESOLVER=NO
CUSTOM_CSS_PARSER_IMPLEMENTATION_OWNER_REQUIRED=NO
```

Lookup preserves exact string identity after validation.

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

CANONICAL_LOCAL_PROPERTY_FRAME_REFERENCE_COUNT=19
CONFIRMED_REQUIRED_BASE_REFERENCE_COUNT=10
CONFIRMED_REQUIRED_BASE_SAME_TARGET_COUNT=4
CONFIRMED_REQUIRED_BASE_ANCESTOR_COUNT=6
CONFIRMED_REQUIRED_BASE_UNRESOLVED_COUNT=0
CONFIRMED_REQUIRED_RESPONSIVE_REFERENCE_COUNT=8
CONFIRMED_REQUIRED_RESPONSIVE_SAME_TARGET_COUNT=0
CONFIRMED_REQUIRED_RESPONSIVE_ANCESTOR_COUNT=8
CONFIRMED_REQUIRED_RESPONSIVE_UNRESOLVED_COUNT=0
UNKNOWN_BORDER_RADIUS_UNRESOLVED_REFERENCE_COUNT=1

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
the local definitions.

The accepted identity join links the 19 local references in the five
canonical local-property frames to their owner-specific residual findings.
Across the four confirmed-required frames, all 18 references have established
same-target or proven-ancestor relations: the ten base references split into
four same-target and six ancestor relations, and all eight responsive
references use proven ancestors. The remaining reference belongs to the
unknown border-radius frame; its target relation is unprovable, so its four
owner findings stay fail-closed. This is consistent with P1 because generic
eligibility is conditional on proven scope.

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
must consume only those values and provenance records. `CustomCssNormalizer`
constructs the internal exact provenance identity from the provenance already
selected by `StylePrecedence`, using only these existing fields:
`source_id`, `origin`, `class_id`, `resolution_source`, `authority_ids`, and
`class_reference_index`. Responsive source keys and viewport keys are not
provenance identity fields. This contract does not require a `StylePrecedence`
change or a lookup of shadowed layers.

```text
EFFECTIVE_LAYER_PROVENANCE_REQUIRED=YES
EFFECTIVE_PROVENANCE_IDENTITY_FIELDS=source_id,origin,class_id,resolution_source,authority_ids,class_reference_index
STYLE_PRECEDENCE_CHANGE_REQUIRED=NO
SHADOWED_LAYER_LOOKUP=NO
SHADOWED_SOURCE_LAYER_LOOKUP=NO
ARBITRARY_GLOBAL_CLASS_SEARCH=NO
```

A class-layer definition belongs to the exact selected class reference and
owner provenance. An element-local definition belongs to that same owner. A
responsive layer may use a base definition only when both records have the
same effective provenance identity and owner source ID. Responsive source keys
may differ only by the already selected viewport key. A different class
reference, element owner, or component is a different scope.

The scope used for a lookup is the tuple:

```text
(owner source ID, effective layer provenance, target node, viewport scope, state scope)
```

### Owner and selector scope

Definitions are available only to declarations within the owner subtree already
passed to `CustomCssNormalizer`. `CustomCssNormalizer` owns selector parsing and
target matching under the accepted selector grammar. It resolves the selector
and source-tree relationship before handing bounded scope records to the local
resolver. For each accepted parsed selector group,
`CustomCssNormalizer` also produces an opaque `selector_identity` from that
already-parsed group representation. The identity is deterministic for
semantically identical parsed groups within one normalization call. It is not
raw selector text. `SourceLocalCustomPropertyResolver` treats it as opaque and
uses it only for exact equality comparison. The resolver does not parse,
serialize, emit, or expose the identity. It is never serialized to Design IR,
generated CSS, or public diagnostics, and it does not expand selector grammar.
The resolver receives no raw selector text and does not implement a second
selector grammar.

The `CustomCssNormalizer` invocation and supplied owner subtree define the
component boundary. There is no new component database, registry, ID lookup, or
global search. Reject foreign targets before or during bounded scope
validation.

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
SELECTOR_PARSE_OWNER=CustomCssNormalizer
SELECTOR_TARGET_MATCH_OWNER=CustomCssNormalizer
SELECTOR_SEMANTICS_OWNER=CustomCssNormalizer_OR_SEPARATELY_ACCEPTED_SHARED_BRICKS_SELECTOR_HELPER
SELECTOR_IDENTITY_OWNER=CustomCssNormalizer
SELECTOR_IDENTITY_RAW_TEXT=NO
RESOLVER_SELECTOR_IDENTITY_OPERATION=EQUALITY_ONLY
RESOLVER_SELECTOR_PARSE=NO
SELECTOR_GRAMMAR_EXPANSION=NO
EMITTABLE_STYLE_SELECTOR_GRAMMAR_EXPANDED=NO
CSS_SELECTOR_IMPLEMENTATION_AUTHORIZED=NO
INTERNAL_DEFINITION_SCOPE_SELECTOR_MAY_ENABLE_ORDINARY_STYLE_RULE=NO
LOCAL_DEFINITION_INDEX_OWNER=SourceLocalCustomPropertyResolver
LOCAL_REFERENCE_RESOLUTION_OWNER=SourceLocalCustomPropertyResolver
RESOLVER_ACCEPTS_RAW_SELECTOR_TEXT=NO
RESOLVER_REIMPLEMENTS_SELECTOR_GRAMMAR=NO
CROSS_OWNER_LOOKUP=NO
CROSS_COMPONENT_LOOKUP=NO
FOREIGN_SCOPE_DISCOVERY_SEARCH=NO
ARBITRARY_SELECTOR_SEARCH=NO
```

The resolver does not search foreign owners or components to determine whether
a missing definition exists elsewhere. An ordinary bounded miss returns
`NO_LOCAL_DEFINITION`. `CROSS_OWNER_REFERENCE` and
`CROSS_COMPONENT_REFERENCE` are invariant-failure states only if foreign scope
data is supplied to the resolver.

An unsupported selector never becomes generatable through local-definition
processing. If an unsupported-selector frame contains ordinary declarations,
those declarations remain residual unless the CSS-SELECTOR lane separately
authorizes their selector. Consuming an internal definition cannot enable a
mixed frame's ordinary style declarations.

The adapter-to-resolver input is an internal bounded record containing only
already parsed data: `owner_source_id`, `effective_provenance_identity`,
`target_source_id`, `target_path`, `selector_identity`, `viewport_scope`,
`state_scope`, `source_order`, `local_name`, `record_kind`, and
`terminal_text_if_definition`. `CustomCssNormalizer` proves each accepted
selector group's target node and path inside the current owner subtree before
passing it to the resolver. `record_kind` is `definition` or `reference`;
terminal text is present only for a definition. This conceptual contract adds
no Design IR struct, serialized shape, or style-value field.

Ancestry is a definition/reference relationship derived from their already
proven target paths, not a per-record input field. Compare structural path
components, not textual prefixes. The resolver performs no selector
interpretation or general tree search.

```text
SAME_TARGET=
  definition.target_path equals reference.target_path

PROVEN_ANCESTOR=
  definition.target_path is a strict structural prefix of reference.target_path
  inside the same owner_source_id and effective_provenance_identity

NOT_INHERITABLE=otherwise
```

A sibling path is never an ancestor. A path outside the owner scope is never
eligible. The resolver considers at most `MAX_OWNER_ANCESTRY_HOPS` (64) owner
ancestry hops/components; if it cannot prove the relationship within that
bound, resolution fails closed.

### Source order and duplicate definitions

`CustomCssParser` provides deterministic frame order inside the selected CSS
source. The resolver uses that order for stable diagnostics. It does not
simulate specificity or use later source order to hide conflicting definitions.
After owner, provenance, viewport, state, and name eligibility, it evaluates
direct target candidates first. If any direct definition exists, ancestor
candidates do not compete with it. If there is no direct definition, only
candidates on the nearest proven ancestor are eligible. At that selected
target node, the resolver applies these rules:

1. One `selector_identity` and one definition selects that definition.
2. One `selector_identity` and multiple definitions with byte-identical
   terminal text coalesces them.
3. One `selector_identity` and multiple definitions with different terminal
   text fails with `CONFLICTING_SOURCE_ORDER`.
4. More than one distinct `selector_identity` fails with
   `AMBIGUOUS_DEFINITION`, even when the terminal texts match.

Source order is for stable diagnostics only and never chooses a winner. A
duplicate property in one rule remains subject to the parser's existing
rejection.

```text
SOURCE_ORDER_RULE=USE_PARSER_ORDER_FOR_STABLE_DIAGNOSTICS; NEVER_PICK_A_CONFLICTING_WINNER
MULTIPLE_DEFINITION_RULE=ONE_UNAMBIGUOUS_CANDIDATE_OR_FAIL
DIRECT_TARGET_PRECEDENCE=YES
NEAREST_PROVEN_ANCESTOR_PRECEDENCE=YES
CROSS_SELECTOR_COALESCE=NO
SAME_SELECTOR_IDENTICAL_TERMINAL_COALESCE=YES
SAME_SELECTOR_CONFLICTING_TERMINAL=CONFLICTING_SOURCE_ORDER
DIFFERENT_SELECTOR_SAME_NODE=AMBIGUOUS_DEFINITION
IDENTICAL_DUPLICATE_RULE=COALESCE_ONLY_FOR_ONE_SELECTOR_IDENTITY_AND_BYTE_IDENTICAL_TERMINAL_TEXT
CONFLICTING_DUPLICATE_RULE=ONE_SELECTOR_IDENTITY_WITH_DIFFERENT_TERMINAL_TEXT_FAILS_CLOSED
```

### Responsive and state scope

The source evidence has base definitions and responsive references. It has no
responsive or state definitions and no state-scoped local references. The
following rules support the observed base-to-responsive shape and fail closed
for unobserved scope transitions.

```text
BASE_TO_BASE_REFERENCE=YES_WITHIN_THE_SAME_OWNER_AND_EFFECTIVE_LAYER
BASE_TO_RESPONSIVE_REFERENCE=YES_IF_SAME_TARGET_OR_NEAREST_PROVEN_ANCESTOR_WITHIN_SAME_OWNER_AND_EXACT_EFFECTIVE_PROVENANCE
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

The accepted required topology contains ten base references: four resolve on
the same target and six use a proven ancestor. It contains eight required
responsive references: none resolves from a same-target base definition, and
all eight use a proven base ancestor. All 18 required references have
established relations. Accordingly, responsive lookup may use a base definition
only for the same owner, exact selected effective provenance identity, and same
component, when no selected responsive definition overrides it. The definition
must resolve on the consumer target or its nearest proven ancestor within that
owner and layer. A direct target definition wins; otherwise the nearest proven
ancestor may supply the base definition. The source-tree path and unique
candidate must be established deterministically. Siblings, foreign owners or
components, and browser-cascade inference are excluded; an unproven path fails
closed. The rule does not infer a named breakpoint, combine or compare media
ranges, use an overlapping responsive definition, or change a source media
boundary. State-scoped variable lookup remains unsupported, even when the state
itself is an accepted generic state condition.

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
| `AMBIGUOUS_DEFINITION` | More than one distinct parsed selector identity supplies candidates at the selected target node and scope. |
| `CONFLICTING_SOURCE_ORDER` | One selector identity supplies different terminal values, and source order cannot choose a cascade winner. |
| `UNSUPPORTED_SCOPE` | The viewport or state transition is outside the explicit rules above. |
| `CROSS_OWNER_REFERENCE` | Foreign owner scope data was supplied despite the owner boundary. |
| `UNSUPPORTED_INHERITANCE` | The source-tree ancestry or selector target cannot be proven within the owner subtree. |
| `UNSUPPORTED_FALLBACK` | The reference has a fallback argument. |
| `UNSUPPORTED_NESTED_REFERENCE` | A definition value requires a second local substitution step. |
| `SELF_REFERENCE` | A definition refers to its own name. |
| `CYCLE` | The bounded local dependency graph contains a cycle. |
| `UNSAFE_TERMINAL_VALUE` | Existing CSS declaration safety rejects the terminal value. |
| `UNSUPPORTED_TERMINAL_VALUE` | Safety passes, but existing value normalization does not support the terminal form. |
| `EXTERNAL_AUTHORITY_COLLISION` | A local definition and an external authority candidate use the same exact name. |
| `CROSS_COMPONENT_REFERENCE` | Foreign component scope data was supplied despite the component boundary. |
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

This correction closes architecture, unknown-rule policy, canonical target
topology, responsive inheritance, selector ownership, failure behavior, IR
impact, bounds, and implementation ownership. It establishes
`AUTHORITY_READY_PENDING_PR_ACCEPTANCE` only. The correction PR must be
independently reviewed and accepted; a later implementation PR must wait for
that acceptance, merge, and exact-head post-merge verification.

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
NEXT_GATE=INDEPENDENT_REVIEW_CSS_LOCAL_CUSTOM_PROPERTY_AUTHORITY_CORRECTION
STOP=NONE
```
