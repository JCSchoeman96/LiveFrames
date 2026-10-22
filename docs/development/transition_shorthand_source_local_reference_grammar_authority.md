# Transition shorthand source-local reference grammar authority

## Authority status

This record freezes the transition-scoped admission boundary and grammar for capability C1, `TRANSITION_SHORTHAND_SOURCE_LOCAL_REFERENCE_GRAMMAR`. It is authority only. It does not implement C1, change production code or tests, componentize Romeo, or run native generation.

```text
C1_AUTHORITY_STATUS=PROPOSED_FOR_REVIEW
C1_IMPLEMENTATION_AUTHORIZED=NO
FRAME_D_IMPLEMENTATION_AUTHORIZED=NO
C3A_IMPLEMENTATION_AUTHORIZED=NO
C3B_IMPLEMENTATION_AUTHORIZED=NO
ROMEO_COMPONENTIZATION_AUTHORIZED=NO
ROMEO_NATIVE_GENERATION_AUTHORIZED=NO
PRODUCTION_FILES_CHANGED=NO
TEST_FILES_CHANGED=NO
C1_PRE_NORMALIZATION_NBSP_GAP=CONFIRMED
ROOT_CAUSE=UNICODE_TRIM_BEFORE_C1_GRAMMAR
C1_WHITESPACE_BOUNDARY_CORRECTION_REQUIRED=YES
AUTHORITY_CORRECTION_REQUIRED=YES
EXISTING_TASK1_TASK2_ARCHITECTURE_CHANGED=NO
```

Programme records: [required residual causal decomposition](feature_romeo_required_residual_causal_decomposition.md), [bounded compound CSS value authority](bounded_compound_css_value_authority.md), [CSS local custom-property resolution authority](css_local_custom_property_resolution_authority.md).

## Entry evidence

```text
PR289_MERGE_SHA=f199b12ba4442e0ab00d742282685a25cfab2ba0
PR289_POST_MERGE_CI=39789011093
PR289_POST_MERGE_CI_RESULT=SUCCESS
PR289_IN_BASE_ANCESTRY=YES

BASE_SHA=9f0d2df1161a715f79c526dae49fbd4c6ca97117
BASE_TREE=4611b8f62861a2c21d129d36f682eaa2600678e2
BASE_CI=39791454675
BASE_CI_RESULT=SUCCESS

MAIN_MOVEMENT_FROM_PR289_FILES=15
CUSTOM_CSS_NORMALIZER_CHANGED_SINCE_PR289=NO
COMPOUND_CSS_VALUE_CHANGED_SINCE_PR289=NO
SOURCE_LOCAL_RESOLVER_CHANGED_SINCE_PR289=NO
CSS_DECLARATION_CHANGED_SINCE_PR289=NO
FIDELITY_CHANGED_SINCE_PR289=NO
DESIGN_IR_NORMALIZER_CHANGED_SINCE_PR289=YES
```

`DesignIRNormalizer` changed in #288, which redacts execution-enabled source bodies from final diagnostics. The canonical revalidation below reproduces the accepted required-finding set and the accepted IR digest, so the causal assignment is not reopened.

## Canonical revalidation

The bounded revalidation ran the public Bricks adapter with component identity `eiwwbh` and a fresh empty `TokenSet`, twice, on `BASE_SHA`. No ACSS, structural-variable, named-breakpoint, or external-token authority was supplied. Private source bytes, names, values, selectors and paths are not recorded here.

```text
PRIVATE_SOURCE_IDENTITY=VERIFIED
CORPUS_RECORDS=34
CORPUS_DIGEST=074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e
ROMEO_SHA256=0cf29929a25bc2485ece90375d8c0f90fa1710eac0439bc5decc13af11f03f63
ROMEO_BYTES=24944
COMPONENT_ID=eiwwbh

CURRENT_ROMEO_RUN_DETERMINISTIC=YES
IR_VALID=YES
IR_ENCODED_SHA256=498049598e03be5119a380a6c5230400d23b9a29a766e620fd69c719d0dec5e8
IR_ENCODED_BYTES=1508446
IR_DIGEST_EQUALS_ACCEPTED_CURRENT_MAIN_RUN=YES

DIAGNOSTICS_TOTAL=89
CUSTOM_CSS_RESIDUALS_TOTAL=44
CUSTOM_CSS_UNRESOLVED_VALUE=28
CUSTOM_CSS_UNSUPPORTED_SELECTOR=16

CONFIRMED_REQUIRED_FINDINGS=20
REQUIRED_FINGERPRINT_SET_MATCH=YES
REQUIRED_REASON_COUNTS=unresolved_value:20
REQUIRED_FINGERPRINT_SET_DIGEST=5fd50d2196eda302196183ed0f6119cb3fbdef5418c7f706d4db15fa9c5cc4b9
REQUIRED_FINGERPRINT_SET_DIGEST_DEFINITION=SHA-256 of the 20 sorted 12-character prefixes joined by newline
NON_REQUIRED_CUSTOM_CSS_UNRESOLVED=8

TRANSITION_PRIMARY=12
FRAME_D_PRIMARY=8
CAUSAL_ASSIGNMENT_REOPEN_REQUIRED=NO
```

The 12-character fingerprint is the SHA-256 of owner, reason and raw value concatenated with no separator. It reproduces the accepted 20-member required set exactly. The required set is unchanged, `CustomCssNormalizer`, `CompoundCssValue` and `SourceLocalCustomPropertyResolver` are unchanged since #289, and the causal primary split is carried forward under those invariants. It was not re-traced.

## Measured transition evidence

These measurements are token classes, counts, and short hashes only. They were taken from an ignored evidence fork of `origin/main` that exports the analysed frames and resolver batches. The fork is not repository code and was deleted after measurement.

```text
SOURCE_GRAMMAR_INVENTORY_DECLARATIONS=20
SINGLE_SPEC_DECLARATIONS=12
LIST_OF_TWO_SPEC_DECLARATIONS=8
TOTAL_TRANSITION_DECLARATIONS=20
ALL_TRANSITION_DECLARATIONS_IDENT_FIRST_PER_SPEC=YES
BARE_VAR_VAR_TRANSITION_DECLARATIONS=0

LOCAL_REFERENCE_OCCURRENCES=56
DURATION_POSITION_OCCURRENCES=28
TIMING_POSITION_OCCURRENCES=28
REFERENCE_ORDER_IS_DURATION_THEN_TIMING_PER_SPEC=YES
ZERO_DEFINITION_REFERENCES=0
MULTI_VALUE_REFERENCE_NAMES=0
```

Private measurement values and names remain unpublished:

```text
PRIVATE_MEASUREMENT_RAW_VALUES_PUBLISHED=NO
PRIVATE_MEASUREMENT_NAMES_PUBLISHED=NO
PRIVATE_MEASUREMENT_DISCLOSURE=SANITIZED_CLASSES_COUNTS_HASHES_ONLY
```

Candidate terminal classes (owner-scoped, every candidate of each name):

```text
DURATION_CANDIDATE_CLASSES=TIME_LITERAL:28
TIMING_CANDIDATE_CLASSES=EXISTING_JUXTAPOSITION_RIGHT_OPERAND_CONTRACT:28
TIMING_CANDIDATE_HASH16=16c2539d96224e3c
```

The opaque timing-terminal hash matches the accepted public juxtaposition right-operand contract fingerprint in [the causal record](feature_romeo_required_residual_causal_decomposition.md).

Resolver outcomes, measured by one batched `resolve/3` call per provenance with transition reference records injected in the evidence fork:

```text
TRANSITION_RESOLVER_REFERENCES=56
TRANSITION_RESOLVER_RESULTS=ok_time_literal:28,ok_existing_right_operand_contract:28
TRANSITION_DECLARATIONS_ALL_REFERENCES_OK=20 OF 20
TRANSITION_DECLARATION_REFERENCE_COUNTS=2:12,4:8
```

Production today creates zero transition reference records, because `CompoundCssValue.parse/1` returns `:no_match` for the IDENT-first shape before any reference is extracted. Therefore the production resolver outcome is not measured. The fork outcome above is the first measured resolver result for these references. The earlier "2/2 ok" in the causal record was a batch-size-1 hypothetical and is superseded by this measurement.

Property identifiers and separators:

```text
PROPERTY_IDENTIFIER_OCCURRENCES=28
PROPERTY_IDENTIFIER_DISTINCT=3
PROPERTY_IDENTIFIER_LOWERCASE_SAFE_SYNTAX=28
PROPERTY_IDENTIFIER_CSS_WIDE_KEYWORD=0
PROPERTY_IDENTIFIER_NONE_OR_ALL=0
PROPERTY_IDENTIFIER_UPPERCASE_OR_ESCAPE_OR_CUSTOM_PREFIX=0
INTRA_SPEC_WHITESPACE_RUNS=single_SP:56
LIST_COMMA_CONTEXT=no_space_before_comma,newline_then_indent_after_comma:8
SPEC_PATTERN_MATCHES=20 OF 20
```

Existing behaviour that must be preserved:

```text
CANONICAL_VAR_BEARING_DECLARATIONS=84
CANONICAL_NON_TRANSITION_PARSE_V1_OUTCOMES=function_call_ok:4,no_match:56,unsupported_grammar:4
CANONICAL_TRANSITION_PARSE_V1_OUTCOMES=no_match:20
CANONICAL_BARE_VAR_VAR_DECLARATIONS_ANY_PROPERTY=0
```

## Architecture decision

```text
SELECTED_TRANSITION_GRAMMAR_ARCHITECTURE=PROPERTY_SCOPED_SEPARATE_PRODUCTION
ARCHITECTURE_OPTION_A_SELECTED=YES
ARCHITECTURE_OPTION_B_REJECTED=YES
ARCHITECTURE_OPTION_C_REJECTED=YES
COMPOUND_VALUE_PARSE_V1_CONTRACT_CHANGED=NO
GENERIC_PARSE_V1_BROADENED=NO
SECOND_LOCAL_RESOLVER=NO
```

The admission decision is made by the normalizer, which knows the declaration property. The pure compound module knows only the value.

- **Option A, selected.** `CustomCssNormalizer` routes a declaration to the transition production only when its property is exactly `transition` after CSS-syntax-whitespace-only declaration normalization. The pure module exposes one additional entry, `CompoundCssValue.parse_transition_shorthand/1`. `parse/1` is unchanged, and no caller other than the property-scoped route can reach the transition production.
- **Option B, rejected.** `parse(value, grammar: :transition_shorthand)` lets any caller select a grammar through an option. The grammar would then be chosen by data at a call site instead of by the declaration's property. A separately named entry point keeps selection explicit.
- **Option C, rejected.** Teaching `parse/1` the IDENT-prefixed shape would admit it for every property. The canonical evidence shows only `transition` uses the shape, so no property-neutral justification exists.

## Admission boundary

Routing is evaluated per consumer declaration, before the compound lifecycle, in this order:

1. Local custom-property definition: unchanged. The transition route is never consulted.
2. Exact direct reference `var(--name)`: unchanged. The direct path is taken for any property, including `transition`.
3. Property is not exactly `transition`: unchanged. The IDENT-prefixed production is unreachable.
4. Property is `transition` and the value contains `var(` case-insensitively: `DISCOVERED`. Otherwise the value stays on the generic path, as today.
5. For `DISCOVERED` `transition` values, exactly one of the following may match:
   - the existing juxtaposition production `VAR WS VAR` through `parse/1`, unchanged, which is locked by existing tests;
   - the transition production through `parse_transition_shorthand/1`.
   Zero matches, or any other outcome, is `FAIL_CLOSED_RESIDUAL`.

The two productions are syntactically disjoint: juxtaposition starts with `var(` and the transition production starts with an identifier. Exactly-one matching is therefore structural, not a precedence list.

```text
C1_IDENT_PREFIXED_PRODUCTION_SCOPE=PROPERTY_EQUALS_TRANSITION_ONLY
C1_IDENT_PREFIXED_PRODUCTION_REACHABLE_FROM_OTHER_PROPERTIES=NO
LEGACY_JUXTAPOSITION_SCOPE=PRE_EXISTING_PROPERTY_AGNOSTIC_UNCHANGED
DISCOVERED_TRANSITION_FALLBACK_TO_GENERIC=NO
DISCOVERED_TRANSITION_FALLBACK_TO_EXTERNAL_AUTHORITY=NO
```

**Pre-existing breadth, not changed by C1.** The existing juxtaposition production is already property-agnostic. Current tests in `bricks_custom_css_normalizer_test.exs` lock `width: var(--duration) var(--timing)` to the literal `250ms ease-in-out`, and they also expect the bare `transition: var(--duration) var(--timing)` form to succeed. C1 keeps this behaviour unchanged, so `TRANSITION_ONLY` is true for the new IDENT-prefixed production only. Narrowing the legacy bare form is an owner decision requiring updated tests, and must not be folded into C1 silently:

```text
LEGACY_JUXTAPOSITION_PROPERTY_BREADTH=PRE_EXISTING_NOT_CHANGED_BY_C1
LEGACY_JUXTAPOSITION_NARROWING_DECISION=DEFERRED_SEPARATE_OWNER_DECISION
```

## CSS declaration whitespace boundary

The C1 review regression and code inspection confirmed a pre-normalization gap: `CustomCssParser` trims declaration property/value boundaries with Unicode-aware `String.trim/1` before the C1 route receives them, and `CustomCssNormalizer.compound_route/2` applies Unicode-aware trimming again. A leading or trailing NBSP can therefore be erased before the strict transition grammar validates the declaration. The C1 grammar itself correctly rejects NBSP as a separator; the loss happens at the declaration boundaries.

Freeze the declaration-boundary whitespace contract:

```text
C1_PRE_NORMALIZATION_NBSP_GAP=CONFIRMED
ROOT_CAUSE=UNICODE_TRIM_BEFORE_C1_GRAMMAR
C1_WHITESPACE_BOUNDARY_CORRECTION_REQUIRED=YES
AUTHORITY_CORRECTION_REQUIRED=YES
EXISTING_TASK1_TASK2_ARCHITECTURE_CHANGED=NO

CSS_DECLARATION_SYNTACTIC_WHITESPACE=
  U+0020 SPACE
  U+0009 TAB
  U+000A LF
  U+000D CR
  U+000C FF

UNICODE_STRING_TRIM_FOR_C1_DECLARATION_BOUNDARY=FORBIDDEN
NBSP_U+00A0_IS_CSS_SYNTACTIC_WHITESPACE=NO
NBSP_MUST_NOT_BE_ERASED_BEFORE_C1_GRAMMAR_VALIDATION=YES
```

Use the repository's bounded CSS-whitespace trim idiom, `String.trim(value, " \t\r\n\f")`, or an exactly equivalent implementation. Apply it only to declaration property/value normalization in `CustomCssParser` and to `compound_route/2` in `CustomCssNormalizer`. The parser remains responsible for declaration framing and whitespace normalization only; it does not select or implement C1 grammar. The normalizer remains responsible for the property-scoped grammar route.

After CSS-syntax-whitespace-only declaration normalization, a leading or trailing NBSP in an ordinary property name remains present and fails the existing property-name validation. A leading or trailing NBSP in a declaration value remains present for downstream grammar and safety checks. An NBSP-only value is not treated as empty CSS whitespace. Do not pass raw-source metadata through IR, reparse `frame.raw`, add C1-specific parsing to `CustomCssParser`, add a module, or broaden CSS tokenization.

## Lifecycle

The transition-specific entity is `TransitionShorthandCandidate`: a `transition` declaration admitted to `DISCOVERED`. It is implemented as the existing private compound route tuple, with no new struct, public field, or IR shape.

`NOT_APPLICABLE` is a routing outcome outside the candidate lifecycle. Routing enters `DISCOVERED` under the admission rules above.

| Conceptual state | Meaning |
| --- | --- |
| `NOT_APPLICABLE` | The transition candidate route does not apply. |
| `DISCOVERED` | Routing admitted the transition candidate. |
| `GRAMMAR_CLASSIFIED` | Exactly one authorized production matched within limits. |
| `LOCAL_REFERENCES_COLLECTED` | Valid, bounded occurrence records are ready for the shared batch. |
| `LOCAL_REFERENCES_RESOLVED` | The shared batch returned one correlated result per occurrence. |
| `TERMINALS_VALIDATED` | Every correlated result is `{:ok, terminal}` and every duration/timing terminal passed its exact slot contract. |
| `TRANSITION_RECONSTRUCTED` | The canonical string is built from the validated terminals. |
| `CSS_REVALIDATED` | The canonical string passed resolved transition-production revalidation and CSS safety validation, contains no `var()`, and remains bounded. |
| `EMITTED` | CSS safety succeeded and the existing caller emitted the literal `StyleValue` under whole-rule atomicity. |
| `FAIL_CLOSED_RESIDUAL` | A guard failed; the candidate cannot emit. |

The conceptual state names identify checkpoints. The explicit guards define which validation has completed.

| From | Guard | To |
| --- | --- | --- |
| `DISCOVERED` | Exactly one authorized production matches; byte, token and production limits pass. | `GRAMMAR_CLASSIFIED` |
| `GRAMMAR_CLASSIFIED` | Occurrence structure is valid and bounded. | `LOCAL_REFERENCES_COLLECTED` |
| `LOCAL_REFERENCES_COLLECTED` | The shared resolver batch returns one correlated result per occurrence. | `LOCAL_REFERENCES_RESOLVED` |
| `LOCAL_REFERENCES_RESOLVED` | Every result is `{:ok, terminal}` and every duration/timing terminal passes its exact slot contract. | `TERMINALS_VALIDATED` |
| `TERMINALS_VALIDATED` | Canonical reconstruction succeeds using the validated terminals. | `TRANSITION_RECONSTRUCTED` |
| `TRANSITION_RECONSTRUCTED` | The canonical resolved form passes transition-production revalidation, contains no `var()`, remains within bounds, and passes `safe_declaration_value("transition", reconstructed, :source_resolver)` / `CSSDeclaration` validation. | `CSS_REVALIDATED` |
| `CSS_REVALIDATED` | The existing caller permits selector-rule emission under whole-rule atomicity. | `EMITTED` |

Any failed guard goes to `FAIL_CLOSED_RESIDUAL`. Nothing leaves either terminal state. `EMITTED` is reached through the existing caller only when whole-rule atomicity permits the selector rule to emit. If another declaration fails later, the caller discards the whole selector rule. It does not mutate the already-evaluated transition candidate into a new semantic result.

The mapping below is separate from the authoritative lifecycle. It describes current internal compound checkpoints, not additional conceptual states or a new public interface:

| Conceptual checkpoint | Current internal compound checkpoint |
| --- | --- |
| `DISCOVERED` | `DISCOVERED` |
| `GRAMMAR_CLASSIFIED` | `GRAMMAR_CLASSIFIED` |
| `LOCAL_REFERENCES_COLLECTED` | `LOCAL_REFERENCES_COLLECTED` |
| `LOCAL_REFERENCES_RESOLVED`, `TERMINALS_VALIDATED` | Parts of `LOCAL_REFERENCES_RESOLVED` |
| `TRANSITION_RECONSTRUCTED` | `TERMINAL_RECONSTRUCTED` |
| `CSS_REVALIDATED` | `CSS_REVALIDATED`, after resolved-form and CSS safety checks |
| `EMITTED` | `EMITTED`, subject to caller atomicity |
| `FAIL_CLOSED_RESIDUAL` | `FAIL_CLOSED_RESIDUAL` |

```text
SIDE_EFFECTS_DURING_PARSE=NONE
SIDE_EFFECTS_DURING_RESOLUTION_CORRELATION=NONE
SIDE_EFFECTS_DURING_RECONSTRUCTION=NONE
TERMINAL_STATES=EMITTED,FAIL_CLOSED_RESIDUAL
TRANSITION_GRAMMAR_FAILURE_FALLBACK_TO_GENERIC=NO
NO_AMBIGUOUS_INTERMEDIATE_RESULT_LEAKS_INTO_IR=YES
```

## Source grammar

```text
TRANSITION_SHORTHAND := SPEC
                      | SPEC WS? "," WS? SPEC

SPEC := PROPERTY_IDENTIFIER WS DURATION_REF WS TIMING_REF

WS := one ASCII whitespace character from [\x20\t\r\n\f], one or more where shown

PROPERTY_IDENTIFIER := [a-z][a-z0-9]* ( "-" [a-z0-9]+ )*
                       and not in RESERVED

RESERVED := { inherit, initial, unset, revert, revert-layer, none, all }

DURATION_REF := existing local reference span  var( WS? --name WS? )
TIMING_REF   := existing local reference span  var( WS? --name WS? )
```

Freeze:

```text
TRANSITION_SPEC_COUNT_MIN=1
TRANSITION_SPEC_COUNT_MAX=2
TRANSITION_REFERENCES_PER_SPEC=2
TRANSITION_REFERENCES_PER_DECLARATION_MAX=4
TRANSITION_SPEC_ORDER_PRESERVED=YES
TRANSITION_LIST_ORDER_PRESERVED=YES
NO_IMPLICIT_THIRD_OR_FOURTH_ITEM=YES
NO_TRANSITION_DELAY_TOKEN=YES
NO_TRANSITION_BEHAVIOUR_TOKEN=YES
NO_LITERAL_DURATION=YES
NO_LITERAL_TIMING_FUNCTION=YES
NO_FUNCTION_FORM_TIMING=YES
NO_NESTED_TRANSITION_LISTS=YES
NO_ARBITRARY_CSS_SHORTHAND_PARSER=YES
WHITESPACE_WITHIN_SPEC=one_or_more_ASCII_whitespace
WHITESPACE_AROUND_LIST_COMMA=zero_or_more_ASCII_whitespace
NON_ASCII_OR_NBSP_WHITESPACE=FAIL_CLOSED
EXACTLY_ONE_COMMA_BETWEEN_SPECS=YES
COMMA_IN_OTHER_POSITIONS=FAIL_CLOSED
```

## Property identifier policy

```text
TRANSITION_PROPERTY_IDENTIFIER_POLICY=P2_SAFE_CSS_IDENTIFIER_MINUS_RESERVED
P1_EXISTING_SAFE_PROPERTY_SYNTAX_EXCLUDING_CUSTOM=CONSIDERED
P2_NARROW_GENERIC_WITH_RESERVED_EXCLUSIONS=SELECTED
P3_GENERAL_CUSTOM_IDENT=REJECTED
IDENTIFIER_RESOLVED_THROUGH_LOCAL_RESOLVER=NO
IDENTIFIER_ALLOWLIST_BY_SOURCE_OR_FINGERPRINT=NO
```

`P2` uses the same lowercase syntax as the existing safe-property check, excluding `--` custom names. Evidence: all 28 measured identifiers match it. CSS-wide keywords, `none` and `all` are reserved and fail closed because they are not evidenced as property names in a transition list. Anything else not matching the syntax, including uppercase letters, escapes, functions, commas, custom prefixes, or a further token, fails closed. Duplicate identifiers within one declaration are not evidenced and fail closed.

```text
TRANSITION_DUPLICATE_PROPERTY_IDENTIFIER=FAIL_CLOSED
TRANSITION_PROPERTY_IDENTIFIER_SEMANTIC_VALIDATION=NONE
```

## Duration slot

```text
TRANSITION_DURATION_SLOT_GRAMMAR=TIME_DURATION_LITERAL_Z_ANCHORED
TRANSITION_DURATION_LEXICAL=^(\d+(\.\d+)?|\.\d+)(s|ms)\z
TRANSITION_DURATION_SEMANTIC=finite, non-negative
TRANSITION_DURATION_REUSES_EXISTING_SLOT=NO
TRANSITION_DURATION_SEMANTICALLY_EQUIVALENT_TO_EXISTING_SLOT=YES
LEGACY_JUXTAPOSITION_DURATION_SLOT_CHANGED_BY_C1=NO
LEGACY_DURATION_ANCHOR_HARDENING=DEFERRED_SEPARATE_NON_BLOCKING
SECOND_LOCAL_RESOLVER=NO
NEW_RESOLVER_INTERFACE=NO
NEW_IR_SHAPE=NO
```

The existing `juxtaposition_left_operand` slot has the same intended semantics, a non-negative finite time with an explicit unit. Its current regex uses the weaker `$` end anchor, which also matches before a trailing newline. C1 must leave that legacy behaviour unchanged. The transition-specific production gets its own strict `\z`-anchored duration terminal contract inside `CompoundCssValue`. This is a slot validator, not a new resolver. Legacy anchor hardening is deferred separately and does not block the C1 implementation plan. A signed exponent, `calc()`, `var()`, a unitless number, or a list is rejected.

## Timing slot

```text
TRANSITION_TIMING_SLOT_GRAMMAR=TRANSITION_TIMING_KEYWORD_EASE_IN_OUT_ONLY
TRANSITION_TIMING_ACCEPTED_TERMINAL=ease-in-out
TRANSITION_TIMING_REUSES_EXISTING_SLOT=YES
TRANSITION_TIMING_KEYWORD_EXPANSION=NO
```

The shared slot `juxtaposition_right_operand` accepts exactly `ease-in-out`. Private measurement uses the opaque contract classification above. No other easing keyword, `linear`, `ease`, `step-*`, `cubic-bezier()`, `steps()` or `linear()` is authorized, because no evidence exists for them. Any other terminal fails the slot and fails closed. The check is exact string equality, so it has no anchoring issue.

## Occurrence and reference accounting

- Occurrences are numbered left to right, depth first within the grammar: spec 1 duration = 0, spec 1 timing = 1, spec 2 duration = 2, spec 2 timing = 3.
- The occurrence key stays the existing private correlation key `{rule_id, target_source_id, selector_identity, property, occurrence_index}`. The resolver record schema is unchanged, and the resolver receives no `transition` field.
- Transition records join the same per-provenance batch as direct and other compound references and consume the same `reference_count`. There is one `resolve/3` call per provenance batch and no per-occurrence call.

```text
DIRECT_AND_COMPOUND_REFERENCE_COUNTER_SHARED=YES
TRANSITION_PARALLEL_REFERENCE_BUDGET=NO
TRANSITION_REFERENCES_PER_SPEC=2
TRANSITION_REFERENCES_PER_DECLARATION_MAX=4
PER_DECLARATION_PARSE_CAP_REUSED=YES (existing 16; the grammar cap of 4 is stricter)
OWNER_LAYER_REFERENCE_CAP_REUSED=YES (existing 1024)
```

## Resolver reuse

```text
SOURCE_LOCAL_RESOLVER_PUBLIC_INTERFACE_CHANGED=NO
SOURCE_LOCAL_RESOLVER_SELECTION_RULES_CHANGED=NO
SOURCE_LOCAL_RESOLVER_ANCESTRY_RULES_CHANGED=NO
SOURCE_LOCAL_RESOLVER_SCOPE_RULES_CHANGED=NO
SOURCE_LOCAL_RESOLVER_FRAME_D_POLICY_CHANGED=NO
SOURCE_LOCAL_RESOLVER_TRANSITION_AWARENESS=NO
VARIABLE_AUTHORITY_REENTRY=NO
EXTERNAL_AUTHORITY_FALLBACK=NO
```

Closed resolver outcomes map as in the existing compound authority. `ok` is used. Every other outcome, including `no_local_definition`, `unsupported_nested_reference`, `unsupported_scope`, `external_authority_collision`, `cross_owner_reference`, `unsupported_inheritance`, `unsupported_terminal_value`, `unsupported_fallback`, `self_reference`, `cycle`, and `conflicting_source_order`, fails closed to `unresolved_value`. `resource_limit_exceeded` maps to the existing `resource_limit_exceeded` path.

## Reconstruction

```text
TRANSITION_RECONSTRUCTION_WHITESPACE=CANONICAL_WHITESPACE_EMITTED
TRANSITION_CANONICAL_FORM=PROPERTY_IDENTIFIER SP DURATION SP TIMING [ ", " PROPERTY_IDENTIFIER SP DURATION SP TIMING ]
PROPERTY_IDENTIFIER_PRESERVED=YES
SPEC_ORDER_PRESERVED=YES
LIST_ORDER_PRESERVED=YES
REFERENCE_OCCURRENCE_ORDER_PRESERVED=YES
PRODUCTION_IDENTITY_PRESERVED=YES
NO_RESIDUAL_var_AFTER_RECONSTRUCTION=YES
```

Canonical whitespace is chosen because the measured source contains newline and indentation after list commas. Emitting those runs would put newlines into a literal style value. Reconstruction is a fixed structural serialisation, so the canonical output is deterministic. It reuses the existing `reconstruct/2` substitution and terminal validation through a transition-specific piece list. The legacy juxtaposition reconstruction keeps its source-preserving behaviour.

## Post-substitution validation

```text
POST_SUBSTITUTION_TRANSITION_REVALIDATION=YES
POST_SUBSTITUTION_REVALIDATION_FORM=RESOLVED_TRANSITION_FORM
RESOLVED_TRANSITION_FORM := RESOLVED_SPEC ( ", " RESOLVED_SPEC )?
RESOLVED_SPEC := PROPERTY_IDENTIFIER " " DURATION_TERMINAL " " "ease-in-out"
DURATION_TERMINAL := TIME_DURATION_LITERAL_Z_ANCHORED (\z-anchored, finite, non-negative)
RESOLVED_FORM_CONTAINS_var=NO
CSS_DECLARATION_REVALIDATION=YES
```

Revalidation re-checks the same production identity on the canonical output, and does not depend on raw substitution. `CSSDeclaration.safe_value?/1` alone is not sufficient, because it does not check transition grammar.

## CSS safety validation

```text
CSS_SAFETY_ENTRY=safe_declaration_value("transition", reconstructed, :source_resolver)
UNSAFE_FRAGMENT_CHECK=EXISTING
CSS_PROPERTY_BOUNDARY=EXISTING_SAFE_PROPERTY_SYNTAX_ONLY
CSS_DECLARATION_ALLOWLIST_CHANGED=NO
COMPOUND_SUCCESS_STYLE_KIND=LITERAL
GENERIC_VAR_CALC_CLASSIFIER_BYPASSED=YES
```

Downstream fidelity emission already emits literal values that pass `safe_value?/1`, with no property allowlist, so a `transition` literal is not blocked there. NativeGenerator behaviour is not evaluated here and is not authorized.

## Whole-rule atomicity

```text
WHOLE_RULE_ATOMICITY=UNCHANGED
ONE_DECLARATION_FAILS -> WHOLE_SELECTOR_RULE_RESIDUAL
NO_PARTIAL_SELECTOR_RULE_EMISSION=YES
```

## Fail-closed matrix

Every unauthorized shape fails closed. The public reason is `unresolved_value` unless the row says otherwise.

| Input shape | Outcome | Public reason |
| --- | --- | --- |
| Non-`transition` `IDENT VAR VAR` | Transition production unreachable; existing path | `unresolved_value` |
| `transition` with empty or comma-only spec list | No match | `unresolved_value` |
| `transition` with more than 2 specs | No match (grammar bound, not a resource budget) | `unresolved_value` |
| Missing duration reference (`IDENT VAR`) | No match | `unresolved_value` |
| Missing timing reference | No match | `unresolved_value` |
| Extra token (fourth item in a spec) | No match | `unresolved_value` |
| Delay token (second time) | No match | `unresolved_value` |
| Unsupported identifier: reserved, uppercase, escape, function, custom prefix | No match | `unresolved_value` |
| Literal duration in a spec | No match | `unresolved_value` |
| Literal timing keyword or function in a spec | No match | `unresolved_value` |
| Unresolved duration reference | Closed resolver outcome | `unresolved_value` |
| Unresolved timing reference | Closed resolver outcome | `unresolved_value` |
| FRAME D resolver outcome (`unsupported_nested_reference`) | Closed resolver outcome | `unresolved_value` |
| External-authority collision | Closed resolver outcome | `unresolved_value` |
| Fallback `var(--a, …)` | Not a local reference span; no match | `unresolved_value` |
| `var(` remaining after resolution | Resolved-form mismatch | `unresolved_value` |
| Resource-limit overflow (bytes, tokens, shared owner budget) | Limit | `resource_limit_exceeded` |
| Malformed commas (leading, trailing, double, missing) | No match | `unresolved_value` |
| Function-form timing token | No match | `unresolved_value` |
| Timing terminal other than `ease-in-out` | Slot rejection | `unresolved_value` |
| Duration terminal not a non-negative finite time | Slot rejection | `unresolved_value` |
| Negative or signed duration | Slot rejection | `unresolved_value` |
| Canonical output failing CSS safety | Existing safety check | `unsafe_declaration` |

```text
COMPOUND_NEW_RESIDUAL_REASON_CODES=0
TRANSITION_GRAMMAR_FAILURE_FALLBACK_TO_GENERIC=NO
EXTERNAL_AUTHORITY_FALLBACK=NO
```

## Resource limits

```text
MAX_SOURCE_BYTES=4096               (existing compound value cap)
MAX_TRANSITION_SPECS=2              (new grammar bound)
MAX_REFERENCES_PER_SPEC=2           (new grammar bound)
MAX_REFERENCES_PER_DECLARATION=4    (new grammar bound; existing 16 cap still holds)
MAX_TOKENS=32                       (existing; transition maximum is 7)
MAX_RECONSTRUCTED_BYTES=4096        (existing)
MAX_LOCAL_REFERENCES_PER_OWNER_LAYER=1024 (existing shared budget)
MAX_LOCAL_DEFINITIONS_PER_OWNER_LAYER=256 (existing)
MAX_OWNER_ANCESTRY_HOPS=64          (existing)
MAX_LOCAL_SUBSTITUTION_DEPTH=1      (existing)
```

No second budget is created. Transition references use the shared batch and counter.

## External authority policy

```text
EXTERNAL_TOKEN_FALLBACK=NO
TOKEN_INFERENCE_FROM_LOCAL_NAME=NO
ACSS_OR_NAMED_FRAMEWORK_AUTHORITY=NO
EXTERNAL_COLLISION=FAIL_CLOSED
```

## Module boundary

Corrected implementation boundary, proposed for owner review:

```text
apps/live_frames/lib/live_frames/adapters/bricks/compound_css_value.ex
  + :transition_shorthand production (type, clause in resolved_valid?/2)
  + parse_transition_shorthand/1 (pure)
  + transition-specific strict \z-anchored duration slot validator
  legacy juxtaposition slots unchanged
  parse/1 unchanged

apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex
  + compound routing receives the property
  + transition route, used only when property == "transition" and parse/1 returns :no_match
  + compound_route/2 trims only CSS syntactic whitespace

apps/live_frames/lib/live_frames/adapters/bricks/custom_css_parser.ex
  + declaration property/value normalization trims only CSS syntactic whitespace
  + framing, selectors, at-rule preludes, and unrelated parser behavior unchanged

apps/live_frames/test/live_frames/bricks_compound_css_value_test.exs
apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs
apps/live_frames/test/live_frames/bricks_custom_css_parser_test.exs
```

A new module is not justified. The transition route shares `Parsed`, `Occurrence`, reconstruction and terminal-validation machinery. It reuses the public timing slot contract and adds its own strict duration slot contract. A separate module would require exporting those private helpers or duplicating them. No Romeo-specific module, name, fixture, or fingerprint branch is permitted.

## Required decisions

```text
1. SELECTED_TRANSITION_GRAMMAR_ARCHITECTURE=PROPERTY_SCOPED_SEPARATE_PRODUCTION
2. EXACT_SOURCE_GRAMMAR=TRANSITION_SHORTHAND (see Source grammar)
3. PROPERTY_IDENTIFIER_GRAMMAR=P2_SAFE_CSS_IDENTIFIER_MINUS_RESERVED
4. SPEC_COUNT_BOUND=1..2
5. COMMA_AND_WHITESPACE_GRAMMAR=ASCII_WS_ONE_OR_MORE_WITHIN_SPEC_ZERO_OR_MORE_AROUND_COMMA
6. DURATION_TERMINAL_GRAMMAR=TIME_DURATION_LITERAL_Z_ANCHORED
7. TIMING_TERMINAL_GRAMMAR=ease-in-out_ONLY
8. OCCURRENCE_REFERENCE_ACCOUNTING=SHARED_BATCH_SHARED_COUNTER
9. RECONSTRUCTION_POLICY=CANONICAL_WHITESPACE_EMITTED
10. POST_SUBSTITUTION_VALIDATION=RESOLVED_TRANSITION_FORM_REVALIDATED
11. CSS_SAFETY_VALIDATION=safe_declaration_value_source_resolver
12. WHOLE_RULE_ATOMICITY=UNCHANGED
13. FAIL_CLOSED_BEHAVIOUR=MATRIX_ABOVE_NO_FALLBACK
14. RESOLVER_REUSE=UNCHANGED_PUBLIC_CONTRACT_NO_TRANSITION_AWARENESS
15. EXTERNAL_AUTHORITY_POLICY=NO_FALLBACK
16. RESOURCE_LIMITS=TABLE_ABOVE
17. MODULE_BOUNDARY=COMPOUND_CSS_VALUE_CUSTOM_CSS_NORMALIZER_WITH_BOUNDED_DECLARATION_WHITESPACE_NORMALIZATION
18. DECLARATION_WHITESPACE_NORMALIZATION=CSS_SYNTAX_WHITESPACE_ONLY
19. NBSP_PRESERVED_FOR_C1_GRAMMAR_AND_SAFETY_VALIDATION=YES
```

## Stated evidence boundary

```text
SOURCE_GRAMMAR_INVENTORY=20 declarations
DIRECT_UNLOCK_FINDINGS=12 (carried forward from the causal record; not re-derived)
REFERENCE_TERMINAL_EVIDENCE=candidate classes 56 of 56 in slot; resolver outcome 56 of 56 ok in batch in evidence fork; production outcome not measured (zero transition records today)
ALL_20_TRANSITION_REFERENCES_PROVEN_END_TO_END_SUCCESS=NO
```

The 12 direct unlocks are a prediction until the C1 implementation is rerun canonically. The 8 findings with FRAME D blockers, and the 4 with C3A and C3B blockers, remain outside C1.

## Performance and scaling

```text
DATA_CLASS=COLD_BUILD_TIME
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
POLLING=0
SOURCE_IR_RUNTIME_WALKS=0
REDIS=NOT_REQUIRED
POSTGRES=NOT_REQUIRED
CACHEX=NOT_REQUIRED
GENSERVER=NOT_REQUIRED
PUBSUB=NOT_REQUIRED
OBAN=NOT_REQUIRED
PGBOUNCER=NOT_REQUIRED
READ_REPLICA=NOT_REQUIRED
100K_CONCURRENT_USERS_RUNTIME_IMPACT=NONE
PARSER_COMPLEXITY=O(value_bytes), at most 7 tokens and 4 references per declaration
```

## Security review

Protected against: arbitrary CSS execution, `url()`, `expression()`, `javascript:`, `behavior:`, `-moz-binding`, residual `var()`, unbounded token growth, unbounded list size, parser ambiguity (the productions are disjoint and exactly one must match), cross-owner local resolution, and external-authority fallback. Final reconstructed declarations stay subject to the existing unsafe-fragment, property, and `CSSDeclaration` checks. Parsing and reconstruction take no source text beyond the declaration value and emit no source text into diagnostics.

## Authority freeze and follow-up categories

```text
C1_SOURCE_GRAMMAR=FULLY_BOUNDED
PROPERTY_SCOPE=FROZEN
PROPERTY_IDENTIFIER_POLICY=FROZEN
DURATION_SLOT_POLICY=FROZEN
TIMING_SLOT_POLICY=FROZEN
SPEC_COUNT_BOUND=FROZEN
REFERENCE_ACCOUNTING=FROZEN
RECONSTRUCTION_POLICY=FROZEN
POST_SUBSTITUTION_VALIDATION=FROZEN
FAIL_CLOSED_POLICY=FROZEN
PRE_IMPLEMENTATION_PLAN_BLOCKERS=CSS_WHITESPACE_BOUNDARY_AUTHORITY_CORRECTION_REVIEW_AND_MERGE_REQUIRED
```

### Deferred, non-blocking

```text
LEGACY_JUXTAPOSITION_NARROWING_DECISION=DEFERRED_SEPARATE_OWNER_DECISION
LEGACY_DURATION_ANCHOR_HARDENING=DEFERRED_SEPARATE_NON_BLOCKING
```

These pre-existing behaviours remain unchanged by C1 and do not block its implementation plan.

### Implementation acceptance obligations

```text
C1_PRODUCTION_RESOLVER_OUTCOME=MUST_BE_MEASURED_AFTER_IMPLEMENTATION
C1_CANONICAL_ROMEO_RERUN=REQUIRED_AFTER_IMPLEMENTATION
```

The production resolver measurement requires the production grammar to emit transition reference records. It is an implementation acceptance criterion. The CSS-whitespace boundary correction must be accepted, merged, and pass post-merge CI before implementation continues. These corrections do not authorize implementation during the docs-only review or a private evidence rerun.

### Out of scope

```text
NATIVE_GENERATOR_TREATMENT=OUT_OF_SCOPE_NOT_AUTHORIZED
```

NativeGenerator work does not block the C1 implementation plan.

## Gates

- `git diff --check`: run on the docs-only authority correction.
- Local Mix format, compile, assets, test, and dependency checks: skipped because the correction changes only the authority and implementation-plan documents. Exact-head push and PR CI are required.
