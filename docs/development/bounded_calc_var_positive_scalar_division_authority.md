# A2 bounded calc var division authority

## Authority status

This document defines one generic CompoundCssValue grammar capability. It does not authorize implementation, tests, resolver changes, source-system behavior, or Romeo-specific behavior.

~~~text
A2_AUTHORITY=BLOCKED
A2_BLOCKED_SCOPE=KNOWN_DERIVED_CLAMP_TERMINAL
CALC_VAR_DIV_POSITIVE_SCALAR=AUTHORIZED
A2_IMPLEMENTATION_AUTHORIZED=NO
EXISTING_CALC_BARE_VAR=PRESERVED
EXISTING_CALC_MULTIPLICATION=PRESERVED

BASE_SHA=a0f210d4913e047426d5a83d8a1afcf06f2b4205
BASE_TREE=8215c9a186c54c9da7a9eb90e05a0efbfe49f3ab
BASE_CI_RUN=40468002174
BASE_CI=PASS
ORIGIN_MAIN_MOVED=NO
~~~

The division grammar is authorized for terminals that already pass the existing :calc_operand validator. The known projected clamp(...) terminal does not pass that validator. A separate generic operand-grammar authority is required before the known calc(clamp(...) / 2) path can execute. This is the A2 stop condition. It does not widen this authority.

## Accepted implementation baseline

At the accepted baseline, CompoundCssValue.parse_calc/2 accepts a bare var(--name) or that reference followed by multiplication by a positive finite unitless scalar. The scalar spelling is constrained to the existing decimal shape and then checked by positive_finite?/1. Existing accepted examples include 1, 2, 2.25, and .5.

The focused test currently rejects calc(var(--x) / 2) with {:error, :unsupported_grammar}. Division is therefore additive grammar authority. Existing bare-variable and multiplication behavior remains unchanged.

The current representation already carries the needed occurrence and production identity:

~~~text
Parsed.production=:function_call
Parsed.function_name=:calc
Occurrence.slot_grammar=:calc_operand
occurrence_count=1
~~~

build/4 splits the source into literal pieces and one occurrence marker. Reconstruction replaces only that marker. The operator, scalar, function spelling, and intervening source whitespace remain literal source pieces.

## Authorized source grammar

Authorize exactly one local custom-property reference divided by one positive finite unitless scalar:

~~~text
CALC_VAR_DIV_POSITIVE_SCALAR=AUTHORIZED

WS=[\x20\t\r\n\f]
VAR=var(WS* --[A-Za-z0-9_-]+ WS*)
SCALAR=(\d+(\.\d+)?|\.\d+)
DIVISION=calc(WS* VAR WS* / WS* SCALAR WS*)
POSITIVE_SCALAR_REQUIRED=YES
POSITIVE_FINITE_PREDICATE_REUSED=YES
~~~

The custom-property name and ASCII whitespace rules are the existing ones. The grammar does not add fallback arguments or other var() forms. The divisor uses the existing scalar spelling and positive_finite?/1 predicate used by multiplication. Do not add another numeric predicate.

Accepted shapes include:

~~~css
calc(var(--x) / 2)
calc(var( --x ) / 2.25)
calc(
  var(--x)
  /
  .5
)
~~~

There is exactly one / between the reference and scalar. Do not accept addition, subtraction, multiple operators, mixed arithmetic, nested arithmetic, or a parenthesized divisor.
Examples rejected by this division production include calc(var(--x, 10px) / 2), calc((var(--x) + 1) / 2), calc(var(--x) + 2), calc(var(--x) - 2), calc(var(--x) / 2 / 3), calc(var(--x) * 2 / 3), and calc(var(--x) / 2 * 3). The existing calc(var(--x) * 2) multiplication production remains supported separately.

~~~text
ZERO_DIVISOR=NO
NEGATIVE_DIVISOR=NO
NONFINITE_DIVISOR=NO
UNIT_DIVISOR=NO
VAR_DIVISOR=NO
NESTED_CALC=NO
VAR_FALLBACK=NO
MULTIPLE_OPERATOR_EXPRESSION=NO
GENERAL_CSS_MATH=NO
~~~

Reject 0, -1, +1, ., 1e3, 1e999, 2px, 2rem, 2%, var(--n), calc(...), (2), NaN, and Infinity. Malformed or unsupported calc syntax keeps the existing parse result {:error, :unsupported_grammar}.

The existing multiplication production remains separate and supported. Preserve its current tests and all other CompoundCssValue productions, including linear gradients, two-token dimensions, two-var juxtaposition, and transition shorthand.

## Representation and reconstruction

Division uses the existing parsed shape and occurrence grammar:

~~~text
NEW_PARSED_PRODUCTION=NO
NEW_PARSED_FIELD=NO
NEW_OCCURRENCE_GRAMMAR=NO
GENERAL_ARITHMETIC_AST=NO

production=:function_call
function_name=:calc
slot_grammar=:calc_operand
occurrence_count=1
~~~

The / positive_scalar text stays in Parsed.pieces as literal source structure. Only var(...) is an occurrence. Preserve source spelling and ASCII whitespace under the existing parser behavior.

The reconstruction contract requires calc_resolved_valid?/1 to accept the same bounded division grammar after occurrence substitution. For example, when the terminal passes the existing slot validator:

~~~text
source:
calc(var(--gap) / 2)

terminal:
2rem

reconstructed:
calc(2rem / 2)
~~~

The existing :calc_operand terminal validation remains authoritative. Do not loosen valid_slot?(:calc_operand, ...), recursively parse a terminal, or resolve variables in this module. Reconstruction must reject any final calc value that retains var(...).

~~~text
PARSE_DIAGNOSTIC=:unsupported_grammar
RECONSTRUCTION_DIAGNOSTIC=:resolved_grammar_mismatch
NEW_PUBLIC_DIAGNOSTIC=NO
EXISTING_DIAGNOSTIC_MEANINGS_CHANGED=NO
~~~

Keep :invalid_slot_terminal for a terminal rejected by its slot grammar, :resource_limit_exceeded at existing bounds, and :resolved_grammar_mismatch when the reconstructed calc value fails its bounded resolved grammar. Keep the existing occurrence-key mismatch behavior.

## Existing calc operand boundary

The current :calc_operand validator accepts a bounded numeric spelling, a value matching the existing dimension grammar, or a numeric percentage spelling. It does not accept function-valued terminals.

~~~text
DERIVED_CLAMP_VALID_AS_EXISTING_CALC_OPERAND=NO
ADDITIONAL_OPERAND_AUTHORITY_REQUIRED=YES
~~~

The exact generic capability missing for the projected calc(clamp(1rem, 2vw, 2rem) / 2) value is authority for a bounded clamp(minimum, preferred, maximum) function form to count as one :calc_operand terminal, with its argument grammar and numeric, dimension, and percentage constraints defined explicitly. This document does not authorize that capability or change the slot validator. Until it has separate authority, reconstruction of the projected clamp terminal fails with :invalid_slot_terminal before resolved-calc validation.

~~~text
STOP=A2_DIVISION_GRAMMAR_INSUFFICIENT_FOR_DERIVED_TERMINAL
~~~

## Lifecycle

Keep the bounded parse, existing resolution ownership, slot validation, and reconstruction lifecycle:

~~~text
INPUT
  -> FUNCTION_ATTEMPT
  -> CALC_GRAMMAR_CLASSIFICATION
       bare var                  -> EXISTING_CALC
       var * positive_scalar     -> EXISTING_CALC_MULTIPLICATION
       var / positive_scalar     -> A2_CALC_DIVISION
       anything else             -> UNSUPPORTED_GRAMMAR
  -> A2_CALC_DIVISION
  -> BUILD_EXISTING_CALC_PARSED_SHAPE
  -> EXTERNAL/LOCAL OCCURRENCE RESOLUTION
  -> EXISTING SLOT VALIDATION
  -> RECONSTRUCTION
  -> BOUNDED CALC DIVISION VALIDATION
       valid                     -> SUPPORTED
       invalid                   -> FAIL_CLOSED
~~~

Terminal states remain SUPPORTED, UNSUPPORTED_GRAMMAR, and FAIL_CLOSED. The parser has no side effects or runtime state.

## A1 and A1B boundaries

A2 consumes the terminal supplied by existing resolution machinery. It does not select a variable definition or resolve a token.

~~~text
VARIABLE_AUTHORITY_CHANGE_REQUIRED=NO
CSSVALUE_CHANGE_REQUIRED=NO
SOURCE_LOCAL_RESOLVER_CHANGE_REQUIRED=NO
TOKEN_CHANGE_REQUIRED=NO
TOKENSET_CHANGE_REQUIRED=NO
~~~

Do not change LiveFrames.Tokens.VariableAuthority, LiveFrames.Tokens.CSSValue, LiveFrames.Adapters.Bricks.SourceLocalCustomPropertyResolver, Token, TokenSet, or AutomaticCSS.

## Romeo boundary

The motivating generic source shape may be written as calc(var(--content-gap) / 2). This document does not authorize Romeo behavior or claims about Romeo residual movement.

~~~text
ROMEO_AUTHORITY_CHANGED=NO
ROMEO_ACSS_AUTHORITY_CHANGED=NO
ROMEO_CANONICAL_TOKEN_SET_CHANGED=NO
ROMEO_RESIDUAL_MOVEMENT_CLAIM_AUTHORIZED=NO
~~~

No Romeo conversion was run and no private source evidence was accessed.

## Bounds and execution model

Parsing and reconstruction remain deterministic, bounded, and in memory at build time. Reuse the existing @max_bytes, @max_argument_bytes, @max_tokens, and @max_refs limits. Do not add recursive evaluation or unbounded traversal.

~~~text
DATA_LAYER=BUILD_TIME_IN_MEMORY
REDIS_REQUIRED=NO
ETS_REQUIRED=NO
GENSERVER_REQUIRED=NO
PUBSUB_REQUIRED=NO
OBAN_REQUIRED=NO
DATABASE_REQUIRED=NO
~~~

## Change and verification boundary

This is one docs-only authority. It does not authorize implementation or test changes.

~~~text
CHANGED_FILES=docs/development/bounded_calc_var_positive_scalar_division_authority.md
IMPLEMENTATION_CHANGE=NO
TEST_CHANGE=NO
ROMEO_CONVERSION=NO
PRIVATE_REFERENCE_ACCESS=NO
~~~
