# Bounded fluid clamp calc operand authority

## Status and scope

This document authorizes the exact terminal grammar below for a future change to `LiveFrames.Adapters.Bricks.CompoundCssValue`. It does not authorize implementation or tests. The A2 division authority remains accepted, but its implementation remains unauthorized. A2B authority and implementation must each be independently accepted before A2 division implementation begins. Do not combine the implementations in one PR.

```text
BASE_SHA=aaba6aefce2866f3def62e8a1b5d005f5bf8f45f
BASE_TREE=9df32b0656b750c1221cc60360fc237fd03e4791
BASE_CI_RUN=40470820870
BASE_CI=PASS
A1=ACCEPTED
A1B=ACCEPTED
A2_DIVISION_AUTHORITY=ACCEPTED
A2B_OPERAND_AUTHORITY=AUTHORIZED
BOUNDED_FLUID_CLAMP_CALC_OPERAND=AUTHORIZED
A2_IMPLEMENTATION_AUTHORIZED=NO
IMPLEMENTATION_AUTHORIZED=NO
```

## Grammar

A `:calc_operand` may be one atomic terminal matching this entire, case-sensitive shape. `WS` is zero or more ASCII spaces, tabs, carriage returns, line feeds or form feeds. The literal function names, punctuation and units are exact.

```text
WS    = [\x20\t\r\n\f]*
NUM   = -?\d+(?:\.\d+)?
REM   = NUM "rem"
VW    = NUM "vw"
INNER = "calc(" WS VW WS "+" WS REM WS ")"
CLAMP = "clamp(" WS REM WS "," WS INNER WS "," WS REM WS ")"
```

The clamp has exactly three arguments. Its preferred expression has exactly one fixed inner `calc`, containing one `vw` dimension, a plus sign, and one `rem` dimension. Signed numeric components are allowed, including `calc(0vw + -0.5rem)`. No semantic ordering check on the outer arguments is authorized. The terminal is validated as syntax, not as a fluid domain.

```text
OUTER_MIN_UNIT=rem
PREFERRED_SLOPE_UNIT=vw
PREFERRED_INTERCEPT_UNIT=rem
OUTER_MAX_UNIT=rem
INNER_OPERATOR=+
INNER_CALC_COUNT=1
SIGNED_NUMERIC_COMPONENTS_ALLOWED=YES
LEADING_PLUS=REJECT
SCIENTIFIC_NOTATION=REJECT
LEADING_DOT=REJECT
NAN=NO
INFINITY=NO
UNIT_EXPONENTS=NO
GENERAL_CLAMP_GRAMMAR=NO
GENERAL_CSS_FUNCTION_OPERAND=NO
GENERAL_NESTED_MATH=NO
GENERAL_NESTED_CSS_MATH=NO
A2_SOURCE_NESTED_CALC_REMAINS_NO=YES
A2B_FIXED_INTERNAL_CALC=AUTHORIZED
```

Reject arbitrary units, other operators, additional arguments, remaining `var(...)`, other nested functions, extra arithmetic, unbalanced parentheses and trailing tokens. Do not accept arbitrary CSS clamp or recursively evaluate CSS math. The A2 source division grammar still prohibits nested `calc()`; the fixed internal `calc()` here belongs to the resolved terminal at a different grammar layer.

`AutomaticCSS.FluidClamp` is evidence for this shape: its `clamp_from_px` emits `clamp(<number>rem, calc(<number>vw + <number>rem), <number>rem)` and its formatter uses fixed decimal output, trimming trailing zeroes and the decimal point. It does not own consumer validation.

## Ownership and blast radius

The audit of direct `:calc_operand` uses found occurrence assignments only in `CompoundCssValue.parse_calc/2` for the existing bare-reference and positive-scalar multiplication productions. `valid_slot?/2` validates that slot, and `calc_resolved_valid?/1` reuses it for the corresponding reconstructed calc forms. No non-calc occurrence uses this slot. Tests assert the calc occurrence and existing atomic operands. A2 division is authorized but not implemented.

Widening this slot is intentional across all three calc contexts. Future implementation must prove that reconstructed bare and multiplication calc forms accept the bounded clamp as one `:calc_operand` while preserving all existing production boundaries. Prefer satisfying this by extending the `:calc_operand` validation boundary only. Do not modify `calc_resolved_valid?/1` unless a focused RED test proves its existing operand capture cannot carry the bounded clamp correctly. This is not authority for a general function parser.

```text
CALC_OPERAND_OWNER=CompoundCssValue
CALC_RESOLVED_VALID_CHANGE_REQUIRED=NO_UNLESS_RED_PROVES_REQUIRED
PREFERRED_IMPLEMENTATION_SURFACE=CALC_OPERAND_VALIDATION
CALC_OPERAND_BLAST_RADIUS_SAFE=YES
BOUNDED_CLAMP_IS_GENERIC_CALC_OPERAND=YES
APPLIES_TO_EXISTING_BARE_CALC=YES
APPLIES_TO_EXISTING_MULTIPLICATION_CALC=YES
APPLIES_TO_AUTHORIZED_DIVISION_CALC=YES
NEW_PARSED_PRODUCTION=NO
NEW_PARSED_FIELD=NO
NEW_OCCURRENCE_GRAMMAR=NO
AUTOMATIC_CSS_RUNTIME_DEPENDENCY=NO
VARIABLE_AUTHORITY_CHANGE_REQUIRED=NO
CSSVALUE_CHANGE_REQUIRED=NO
TOKEN_CHANGE_REQUIRED=NO
TOKENSET_CHANGE_REQUIRED=NO
SOURCE_LOCAL_RESOLVER_CHANGE_REQUIRED=NO
```

The division applicability is authorized future behavior, not a claim that division currently parses. The A2 document's existing operand restriction describes its baseline; this document separately authorizes this bounded widening.

## Validation and diagnostics

Validate the candidate atomically at the `:calc_operand` boundary. Preserve existing numeric, dimension and percentage operands. If an existing atomic operand fails, check the candidate against the bounded clamp shape. Do not recursively call `CompoundCssValue.parse/1` or resolver logic. A shallow, finite recognizer is preferred; avoid unbounded regex backtracking and general function parsing.

```text
CALC_OPERAND_CANDIDATE
  -> EXISTING_ATOMIC_OPERAND? -> VALID
  -> BOUNDED_CLAMP_ATTEMPT
       wrong function, argument count, unit, number or inner operator -> INVALID
       remaining var or extra nesting -> INVALID
       exact bounded shape -> VALID
TERMINAL_STATES=VALID|INVALID|RESOURCE_LIMIT
NEW_PUBLIC_DIAGNOSTIC=NO
INVALID_CLAMP_DIAGNOSTIC=:invalid_slot_terminal
```

Retain existing reconstructed-grammar and resource diagnostics. Reuse `@max_bytes` and `@max_argument_bytes`; reconstruction enforces its overall limits. The recognizer must itself remain bounded and shallow, without unbounded token lists or nested-parenthesis traversal. No side effects are authorized.

## Future proof expectations

Use synthetic terminal strings to prove the consumer grammar. Positive controls include:

```css
clamp(1rem, calc(2vw + 0.5rem), 2rem)
clamp(1.5rem, calc(-0.25vw + 2rem), 3rem)
clamp(-1rem, calc(0vw + -0.5rem), 1rem)
```

Prove unchanged acceptance of existing atomic operands, and acceptance in bare and multiplication calc contexts. Division is tested only when separately authorized for implementation. Reject wrong functions and argument counts, each substituted unit, leading plus, scientific notation, leading-dot numbers, remaining `var(...)`, nested clamp, extra inner functions, inner subtraction, multiplication and division, extra top-level arithmetic, unbalanced parentheses, trailing tokens and oversized values. Preserve existing resource-limit behavior. No ACSS fixture is needed to prove this consumer grammar.

## Boundaries

```text
ROMEO_AUTHORITY_CHANGED=NO
ROMEO_ACSS_AUTHORITY_CHANGED=NO
ROMEO_CANONICAL_TOKEN_SET_CHANGED=NO
ROMEO_RESIDUAL_MOVEMENT_CLAIM_AUTHORIZED=NO
DATA_LAYER=BUILD_TIME_IN_MEMORY
REDIS_REQUIRED=NO
ETS_REQUIRED=NO
GENSERVER_REQUIRED=NO
PUBSUB_REQUIRED=NO
OBAN_REQUIRED=NO
DATABASE_REQUIRED=NO
```

No Romeo conversion or private source access is authorized. The known compound path is motivation only. This document changes no code or tests.
