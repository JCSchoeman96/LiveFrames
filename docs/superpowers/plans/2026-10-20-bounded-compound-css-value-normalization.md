# Bounded compound CSS value normalization implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the accepted bounded compound CSS value capability without changing resolver semantics, Design IR schemas, selector grammar, `VariableAuthority`, `CSSDeclaration`, or generator behavior.

**Architecture:** `CompoundCssValue` will parse, classify, validate, and reconstruct only the frozen compound productions. `CustomCssNormalizer` will parse each frame declaration once, send only evidenced local occurrences through its existing per-provenance resolver batches, correlate results privately, and hand successful reconstructed values to the existing literal `StyleValue` path after `CSSDeclaration` revalidation.

**Tech Stack:** Elixir umbrella application, Mix, ExUnit.

**Spec:** `docs/development/bounded_compound_css_value_authority.md`

## Global Constraints

- Implement only the three frozen compound productions and their four frozen slot grammars.
- Route local custom-property definitions before compound discovery; definitions remain compiler inputs only.
- Route the exact existing direct `var(--name)` form before compound discovery.
- Admit remaining declarations only when the value contains case-insensitive `var(` or `calc(`, or exactly matches the frozen two-dimension production.
- Once admitted to `DISCOVERED`, fail closed if zero or multiple productions match. Never return an admitted declaration to the generic path.
- Keep direct and compound references in one existing per-provenance `reference_count`, capped at `1024`.
- Preserve `MAX_EFFECTIVE_LAYER_CSS_BYTES=65536`, `MAX_LOCAL_DEFINITIONS_PER_OWNER_LAYER=256`, `MAX_OWNER_ANCESTRY_HOPS=64`, `MAX_TERMINAL_VALUE_BYTES=4096`, `MAX_LOCAL_SUBSTITUTION_DEPTH=1`, `MAX_COMPOUND_VALUE_BYTES=4096`, `MAX_RECONSTRUCTED_TERMINAL_BYTES=4096`, `MAX_COMPOUND_TOKEN_COUNT=32`, `MAX_EMBEDDED_LOCAL_REFERENCES_PER_DECLARATION=16`, `MAX_FUNCTION_ARGUMENT_BYTES=2048`, `MAX_LINEAR_GRADIENT_STOPS=8`, `MAX_STOP_SEGMENT_TOKENS=4`, and `MAX_COMPOUND_PARSE_DEPTH=1`.
- Keep the resolver input schema, resolver API, `VariableAuthority`, `CSSDeclaration`, StyleValue schema, Design IR, selector grammar, and generator unchanged.
- Parse at most once per non-definition frame/property and reuse the result across all targets.
- Map compound failures to existing residual reasons only; emit no new public reason codes.
- Keep the implementation boundary to the four files listed below. This plan does not authorize implementation.
- Run the canonical conversion only after implementation exists and its separate gate authorizes that run.

## Review Focus

1. An admitted `:no_match` result returns `"unresolved_value"`, never the generic path. Pin this in Task 2's malformed juxtaposition route test.
2. Ordinary values outside admission keep their existing generic result. Pin `teal`, `center center`, `10 20px`, and an unknown function without `var(`/`calc(` in Task 2's routing-table tests.
3. A definition value containing nested `var()` syntax creates no compound references and remains subject to FRAME D. Pin this in Task 2's definition-exclusion test.
4. Target expansion does not reparse or duplicate occurrence records. Pin this in Task 2's multi-target cardinality test.
5. Two occurrences in one declaration keep distinct indices and terminals. Pin this in Task 2's two-occurrence correlation test.
6. Direct and compound records share the same `1024` limit. Pin the `1024` pass and `1025` fail cases in Task 2's mixed-budget test.
7. A compound local name never reaches `VariableAuthority`. Pin this in Task 3's external-candidate failure test.
8. A CSS-safe terminal can still fail its slot grammar. Pin this in Task 3's wrong-slot test.
9. A successful compound declaration cannot leak through a partially failing rule. Pin this in Task 3's mixed-rule atomicity test.
10. Compound failures introduce no public residual reason strings. Pin the exact reason table in Task 3's residual-mapping tests.

---

## Gate record

```text
PLAN_GATE=IMPLEMENTATION_PLAN_ONLY
BASE_SHA=64855802b347a710fb60bdb6054ce62d4390b8c2
BASE_TREE=ac869f2df3cc7f2004d0c6f5fee53950ff5f1768
BASE_CI=39412560656 SUCCESS

PR_269=MERGED
PR_269_APPROVED_HEAD=e06819d003cbec21d3e34245c958ee54ddc26f6d
PR_269_MERGE_SHA=539ffa09e7b957c7dd48ec03c1ce4d1b6a823e97
PR_269_MERGE_TREE=afc0c3c0328329f08c5566cd8284338c0e4d5953
PR_269_POST_MERGE_CI=39383739868 SUCCESS
PR275_DISCOVERY_AUTHORITY=MERGED_ACCEPTED
PR275_MERGE_SHA=64855802b347a710fb60bdb6054ce62d4390b8c2

COMPOUND_ARCHITECTURE_AUTHORITY=ACCEPTED
COMPOUND_DISCOVERY_AUTHORITY=ACCEPTED
COMPOUND_IMPLEMENTATION_PLAN_AUTHORIZED=YES
COMPOUND_IMPLEMENTATION_AUTHORIZED=NO
```

The accepted architecture and discovery authority is [`docs/development/bounded_compound_css_value_authority.md`](../../development/bounded_compound_css_value_authority.md). PR #275 merged the discovery-boundary amendment at the current base SHA. This plan follows that accepted routing contract. The implementation remains unauthorized.

The accepted architecture is fixed. This plan schedules implementation work and does not reopen production grammar, resolver behavior, scope rules, or count units.

## Implementation file boundary

The implementation tasks may touch exactly these four files:

- Create `apps/live_frames/lib/live_frames/adapters/bricks/compound_css_value.ex`. Own the pure bounded compound parser, occurrence descriptors, slot validation, deterministic reconstruction, resolved-form validation, and closed parser error classification.
- Create `apps/live_frames/test/live_frames/bricks_compound_css_value_test.exs`. Cover the pure grammar and reconstruction contract with synthetic values only.
- Modify `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex`. Own declaration analysis reuse, local record integration, private occurrence correlation, existing resolver batching, shared declaration safety, final literal handoff, and rule atomicity.
- Modify `apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`. Cover record integration, batching behavior, safety and residual behavior, final output, and whole-rule atomicity.

Freeze these implementation exclusions:

```text
CUSTOM_CSS_PARSER_CHANGE_REQUIRED=NO
SOURCE_LOCAL_CUSTOM_PROPERTY_RESOLVER_CHANGE_REQUIRED=NO
VARIABLE_AUTHORITY_CHANGE_REQUIRED=NO
CSS_DECLARATION_CHANGE_REQUIRED=NO
STYLE_VALUE_SCHEMA_CHANGE_REQUIRED=NO
DESIGN_IR_SCHEMA_CHANGE_REQUIRED=NO
DESIGN_IR_NORMALIZER_CHANGE_REQUIRED=NO
NATIVE_GENERATOR_CHANGE_REQUIRED=NO
RESOLVER_REFERENCE_RECORD_SCHEMA_CHANGED=NO
RESOLVER_PUBLIC_INTERFACE_CHANGED=NO
```

If implementation requires another production or test file, stop with `PLANNED_IMPLEMENTATION_BOUNDARY_EXPANDED`. Do not widen the boundary in code or tests.

## Frozen private module contract

Use the exact module name `LiveFrames.Adapters.Bricks.CompoundCssValue` and these three private-use functions only:

```text
parse(value :: binary())
  :: {:ok, LiveFrames.Adapters.Bricks.CompoundCssValue.Parsed.t()}
   | :no_match
   | {:error, :unsupported_grammar | :resource_limit_exceeded}

occurrences(parsed :: LiveFrames.Adapters.Bricks.CompoundCssValue.Parsed.t())
  :: [LiveFrames.Adapters.Bricks.CompoundCssValue.Occurrence.t()]

reconstruct(
  parsed :: LiveFrames.Adapters.Bricks.CompoundCssValue.Parsed.t(),
  terminals_by_occurrence_index :: %{non_neg_integer() => binary()}
)
  :: {:ok, binary()}
   | {:error,
      :occurrence_terminal_mismatch
      | :invalid_slot_terminal
      | :resolved_grammar_mismatch
      | :resource_limit_exceeded}
```

Define nested private-use types in the same production file:

- `LiveFrames.Adapters.Bricks.CompoundCssValue.Parsed` has `production`, `function_name`, `pieces`, and `occurrences` fields. `production` is one of `:function_call`, `:multi_token_value`, or `:var_reference_with_operation`. `function_name` is `:linear_gradient` or `:calc` for `:function_call`, and `nil` for the other two productions. `pieces` is the ordered source spelling split into literal binaries and `{:occurrence, occurrence_index}` markers. It contains no owner, selector, source ID, hash, or resolver data.
- `LiveFrames.Adapters.Bricks.CompoundCssValue.Occurrence` has `occurrence_index`, `local_name`, and `slot_grammar` fields. `slot_grammar` is one of the four frozen slot atoms. Indices start at zero and follow left-to-right discovery order, which is depth-first within the frozen bounded grammar.

`occurrences/1` returns the descriptors in that order. `reconstruct/2` accepts a map keyed by every occurrence index and requires the key set to match exactly. It validates each terminal against that occurrence's `slot_grammar`, reconstructs from `pieces`, checks the reconstructed byte bound, then validates the same `production` and, for `:function_call`, the same `function_name` under its resolved-form grammar. It rejects a missing or extra terminal, an invalid slot terminal, any remaining `var(`, and a resolved-form mismatch. `MULTI_TOKEN_VALUE` has no occurrences on this freeze, so reconstruction accepts only an empty terminal map and revalidates the unchanged two-dimension form.

`parse/1` returns `:no_match` for arbitrary values outside the three frozen productions, including an exact direct `var(--name)` supplied to the pure module. This is only a parse result; the pure module does not decide admission. In production the normalizer calls `parse/1` only after `DISCOVERED` admission. Any `:no_match` after admission maps to the existing public reason `"unresolved_value"`; it never returns to the generic path. A malformed admitted production returns `{:error, :unsupported_grammar}`, and a frozen resource violation returns `{:error, :resource_limit_exceeded}`.

No function in this module calls `SourceLocalCustomPropertyResolver`, `VariableAuthority`, `CSSDeclaration.normalize/2`, or any selector, owner, provenance, Design IR, or generator code.

## Frozen grammar and flow

Classify the entire trimmed declaration value against the three disjoint productions. Do not introduce a precedence order. The existing exact direct `var(--name)` form remains on the direct-reference path.

1. `FUNCTION_CALL`: outer names `linear-gradient` and `calc` only, using ASCII case-insensitive matching. The outer call is depth 1. `var(--name)` is the only permitted nested call-like form, does not increase depth, and is scanned only for occurrence extraction. Reject quoted strings, other nested functions, extra operators, commas in `calc`, and tokens outside the outer call. Enforce the frozen gradient and `calc` source and resolved grammars.
2. `MULTI_TOKEN_VALUE`: exactly two `DIMENSION_LITERAL` tokens separated by permitted ASCII whitespace. Both tokens use `^-?\d+(\.\d+)?(px|rem|em|vh|vw|fr|deg|%)$` with case-sensitive units. It has no embedded reference. Do not allow keywords, a separate percentage class, unitless numbers, identifiers, operators, commas, functions, or another token count into this production.
3. `VAR_REFERENCE_WITH_OPERATION`: exactly `LOCAL_REF WS LOCAL_REF`, with ASCII whitespace and no operator. The resolved form is exactly `JUXTAPOSITION_LEFT_OPERAND WS JUXTAPOSITION_RIGHT_OPERAND`.

Use these exact function argument grammars. The permitted ASCII whitespace set is space, tab, carriage return, line feed, and form feed. Use that same set for function token spacing, multi-token separation, stop-segment separation, and juxtaposition separation.

- `linear-gradient` has one argument span of at most 2,048 bytes. It is `<angle>, <stop-list>`, where `<angle>` is `\d+(\.\d+)?deg`. The stop list has one through eight comma-separated stop segments. Between stop segments, a comma may be followed by ASCII whitespace. Each segment has one through four ASCII-whitespace-separated atoms. Each atom is exactly `transparent`, `\d+(\.\d+)?%`, or one embedded direct local `var(--name)` occurrence. A general identifier, operator, hash, or nested `(` is rejected.
- `calc` has one argument span of at most 2,048 bytes and matches exactly `var(--name)` or `var(--name) * <positive-finite-number>`. ASCII whitespace may surround these tokens. The factor has lexical form `(?:\d+(?:\.\d+)?|\.\d+)` and must pass a private `CompoundCssValue` predicate with the same contract as `CustomCssNormalizer.positive_finite_number/1`: `Float.parse(text)`, exact empty suffix, number greater than zero, `number == number`, and number at most `1.7976931348623157e308`. Do not change the normalizer helper's visibility. The lexical grammar runs before this numeric predicate. No comma, second `var(`, other operator, or nested function is allowed.
- An embedded local reference uses the existing name shape, `var\([ \t\r\n\f]*(--[A-Za-z0-9_-]+)[ \t\r\n\f]*\)`. The normalizer applies the existing `CSSDeclaration.safe_property?/1` and `--` local-definition check before it builds a resolver record. Preserve the exact extracted name.

The four occurrence slot grammars are `GRADIENT_STOP_ATOM`, `CALC_OPERAND`, `JUXTAPOSITION_LEFT_OPERAND`, and `JUXTAPOSITION_RIGHT_OPERAND`. Preserve every frozen terminal class and rejection rule in the authority:

- Gradient stop atoms accept `transparent`, percentages, bounded dimensions, and the exact bounded `rgb(...)` / `rgba(...)` grammar. RGB and RGBA are single compound-parser atoms. Do not split their commas or bounded internals as top-level tokens. Reject internal RGB whitespace, invalid channels, RGBA alpha outside finite `0..1`, alpha percentages, hex colors, arbitrary identifiers, and other functions.
- Gradient percentages match `^\d+(\.\d+)?%$`. Gradient dimensions match `^-?\d+(\.\d+)?(px|rem|em|vh|vw|fr|deg|%)$` with case-sensitive units. RGB/RGBA names are ASCII case-insensitive. The `rgb` form has exactly three `\d{1,3}` channels whose numeric values are 0 through 255. The `rgba` form has those channels and alpha exactly `0`, `1`, or a decimal matching `^(\d+\.\d+|\d*\.\d+)$` whose parsed numeric value is finite and between 0 and 1. No spaces, percent alpha, slash, nesting, or other argument spelling is allowed.
- Calc operands accept unitless numbers matching `^-?\d+(\.\d+)?$`, dimensions matching `^-?\d+(\.\d+)?(px|rem|em|vh|vw|fr|deg|%)$`, or percentages matching `^\d+(\.\d+)?%$`. Use the existing positive finite number contract where the source grammar requires a multiplication factor.
- A juxtaposition left operand accepts only a finite, non-negative time duration matching `^(\d+(\.\d+)?|\.\d+)(s|ms)$`, with no leading sign.
- A juxtaposition right operand accepts only `ease-in-out`. Reject arbitrary identifiers and all function forms, including `cubic-bezier(...)`, `steps(...)`, and `linear(...)`.
- Every resolved slot contains exactly one top-level token. The RGB/RGBA function is one token even though its arguments contain commas. The internal `MULTI_TOKEN_ATOM`, if used by a shared private helper, accepts only `DIMENSION_LITERAL` and is never attached to a resolver occurrence on this freeze.
- Do not use `CSSDeclaration.safe_value?/1` as a catch-all grammar. `CSSDeclaration` runs only at the final safety boundary.

Apply these exact limits. Count bytes as bytes and do not split an RGB/RGBA atom into top-level tokens:

```text
MAX_EFFECTIVE_LAYER_CSS_BYTES=65536
MAX_LOCAL_DEFINITIONS_PER_OWNER_LAYER=256
MAX_LOCAL_REFERENCES_PER_OWNER_LAYER=1024
MAX_OWNER_ANCESTRY_HOPS=64
MAX_TERMINAL_VALUE_BYTES=4096
MAX_LOCAL_SUBSTITUTION_DEPTH=1

MAX_COMPOUND_VALUE_BYTES=4096
MAX_RECONSTRUCTED_TERMINAL_BYTES=4096
MAX_COMPOUND_TOKEN_COUNT=32
MAX_EMBEDDED_LOCAL_REFERENCES_PER_DECLARATION=16
MAX_FUNCTION_ARGUMENT_BYTES=2048
MAX_LINEAR_GRADIENT_STOPS=8
MAX_STOP_SEGMENT_TOKENS=4
MAX_COMPOUND_PARSE_DEPTH=1
```

Count grammar atoms for `MAX_COMPOUND_TOKEN_COUNT`: each multi-token dimension is one; the gradient angle is one and each stop atom is one; the calc `var()` and optional factor are one each; each juxtaposition `var()` is one. A bounded RGB/RGBA terminal is one slot atom. Do not count punctuation as an atom. Production 4's effective token count remains exactly two. Do not add recursion, an evaluator, a whole-document walk, a selector expansion, or hash-based production selection.

The complete success flow is:

```text
bounded source parse
  -> occurrence descriptors with SLOT_GRAMMAR
  -> existing SourceLocalCustomPropertyResolver records and per-provenance batch
  -> require one successful resolver result for every occurrence
  -> validate each terminal against its SLOT_GRAMMAR
  -> bounded reconstruction
  -> same-production resolved-form validation with no var()
  -> CSSDeclaration.normalize(..., :source_resolver)
  -> existing literal StyleValue
```

Embedded compound names stay on the local lane. If a local name is not observed or the existing resolver returns any closed error, fail the declaration closed. Do not infer a token, consult `VariableAuthority`, pass raw source through, or salvage an external name. `FRAME C` stays fail-closed for `:no_local_definition`. `FRAME D` stays fail-closed for `:unsupported_nested_reference`. Any non-`nil` `state_scope` stays fail-closed for `:unsupported_scope`.

Freeze the output and batching rules:

```text
COMPOUND_PARSE_ONCE_PER_FRAME_DECLARATION=YES
COMPOUND_PARSE_PER_TARGET=NO
PRODUCTION_RESOLVER_BATCHING=EXISTING_PER_PROVENANCE_BATCH
PER_OCCURRENCE_RESOLVER_CALL_IMPLEMENTATION=NO
COMPOUND_SUCCESS_VALUE_CLASSIFICATION=BYPASS_GENERIC_VAR_CALC_CLASSIFIER
COMPOUND_SUCCESS_STYLE_KIND=LITERAL
CSS_DECLARATION_REVALIDATION=REQUIRED
VARIABLE_AUTHORITY_REENTRY=NO
LOCAL_COMPOUND_TOKEN_INFERENCE=NO
LOCAL_COMPOUND_EXTERNAL_FALLBACK=NO
MULTI_TOKEN_LOCAL_RESOLVER_REFERENCES_CURRENT_CAPABILITY=0
```

## Normalizer integration contract

`CustomCssNormalizer` remains the only owner of owner and provenance scope, selector and target routing, observed local names, resolver record construction, batching, private correlation, rule atomicity, final safety, and `StyleValue` emission.

### Pre-lifecycle routing and declaration analysis

The normalizer decides admission in this exact order for each declaration:

1. If `local_definition_name?(property)` is true, skip compound discovery and do not call `CompoundCssValue.parse/1`. Keep the value on the existing definition record and `SourceLocalCustomPropertyResolver` definition-dependency path. Definitions are compiler inputs only. Do not extract compound occurrences from their values. Preserve the existing `SELF_REFERENCE`, `CYCLE`, `UNSUPPORTED_FALLBACK`, and `UNSUPPORTED_NESTED_REFERENCE` behavior; FRAME D remains fail-closed.
2. Otherwise trim the value and check the entire value against the existing exact direct `var(--name)` grammar. If it matches, route through the existing direct-reference path before compound discovery. Do not change the direct grammar.
3. For remaining consumer declarations, admit to `DISCOVERED` when `String.downcase(trimmed_value)` contains `"var("` or `"calc("`, or when the whole trimmed value exactly matches two frozen `DIMENSION_LITERAL` tokens separated by one or more permitted ASCII whitespace characters. The admission predicate for the two-dimension case must use the exact frozen `DIMENSION_LITERAL` grammar, including case-sensitive units. It may be a small normalizer-private predicate; it must not call `CompoundCssValue.parse/1` while deciding admission.
4. Route every other value through the existing generic declaration-value path unchanged. Do not call `CompoundCssValue.parse/1` for it.

The permitted ASCII whitespace set is space, tab, carriage return, line feed, and form feed. The two-dimension admission is exactly `DIMENSION_LITERAL WS+ DIMENSION_LITERAL`, with `DIMENSION_LITERAL` matching `^-?\d+(\.\d+)?(px|rem|em|vh|vw|fr|deg|%)$`. It admits exactly two tokens and does not authorize keywords, identifiers, unitless numbers, or any other multi-token shape.

Freeze the routing contract:

```text
COMPOUND_DISCOVERY_BOUNDARY=COMPATIBILITY_PRESERVING
COMPOUND_DISCOVERY_REUSES_EXISTING_GENERIC_CLOSED_TRIGGER=YES
DIRECT_VAR_ROUTED_BEFORE_COMPOUND_DISCOVERY=YES
LOCAL_DEFINITION_ROUTED_BEFORE_COMPOUND_DISCOVERY=YES
OUTSIDE_COMPOUND_LANE_USES_EXISTING_GENERIC_PATH=YES
COMPOUND_PARSE_CALLED_FOR_OUTSIDE_LANE=NO
DISCOVERED_COMPOUND_CAN_FALL_BACK_TO_GENERIC=NO
NO_MATCH_SEMANTICS=CONTEXTUAL_PRIVATE_PARSE_RESULT
DISCOVERED_PARSE_NO_MATCH=FAIL_CLOSED_RESIDUAL
DISCOVERED_PARSE_NO_MATCH_PUBLIC_REASON=unresolved_value
COMPOUND_ANALYSIS_LOCAL_DEFINITION_PROPERTIES=SKIP
COMPOUND_OCCURRENCES_FROM_DEFINITION_VALUES=0
CUSTOM_PROPERTY_DEFINITIONS_REMAIN_COMPILER_INPUTS_ONLY=YES
```

After admission, require exactly one frozen production. A successful match is parsed once. Zero matches (`:no_match`) and multiple production matches fail closed. There is no `DISCOVERED -> GENERIC_PATH` transition. The parser may return `:no_match` for arbitrary out-of-lane values in pure-module tests, but production integration treats it as `"unresolved_value"` because production calls the parser only after admission.

Create one normalizer-private route-aware analysis map keyed by `{rule_id, property}`, where `rule_id` is the existing `{source_index, source_order}` returned by `frame_rule_id/1`. The map contains only non-definition consumer declarations. Record the routing result once. Call `CompoundCssValue.parse/1` exactly once for each admitted frame/property and retain its exact result (`{:ok, parsed}`, `:no_match`, or `{:error, reason}`). Reuse a successful parsed value and its occurrence list for extraction, correlation, every matching target, and reconstruction. Direct and generic declarations retain their existing routes. Do not create a generalized compiler cache.

Keep direct-reference behavior unchanged. Its correlation key remains:

```text
{rule_id, target_source_id, selector_identity, property}
```

Compound-only correlation adds one field in normalizer-private data:

```text
{rule_id, target_source_id, selector_identity, property, occurrence_index}
```

For each compound occurrence whose local name is established by the existing observed-local-name collection, append one ordinary resolver reference record per routed target. Preserve the exact existing record schema and values: `owner_source_id`, `effective_provenance_identity`, `target_source_id`, `target_path`, `selector_identity`, `viewport_scope`, `state_scope`, `source_order`, `local_name`, and `record_kind: :reference`. Do not add `occurrence_index`, `reference_id`, or compound fields to resolver input records. If a compound name is not observed, add no resolver record for it and mark the compound declaration as unresolved on the local lane so it cannot enter `VariableAuthority`.

Append compound records to the existing provenance batch and existing `reference_count`. Do not add a second reference counter. `MULTI_TOKEN_VALUE` contributes zero records. Resolve each existing provenance batch once through the existing `resolve/3`, then correlate its ordered results to private occurrence keys. Never call `resolve/3` once per occurrence.

Extract the smallest shared declaration safety boundary from the existing `normalize_declaration/4` path. Freeze its private name and signature as:

```text
safe_declaration_value(property, value, origin)
  :: {:ok, trimmed_safe_value} | {:error, existing_reason}
```

It performs the existing unsafe-fragment check, property check, and `CSSDeclaration.normalize/2` call with the supplied origin. The generic route calls it before `normalize_declaration_value/3`. The compound success route calls it with `:source_resolver`, then tags the returned value directly as `{"kind" => "literal", "value" => trimmed_safe_value}`. Do not route reconstructed `calc(...)` through `normalize_declaration_value/3`. Keep existing safety and diagnostic reasons for failures.

Freeze the public residual mapping. No resolver result atom may appear as a public reason, and no new reason string or fingerprint input may be added:

| Failure | Public residual reason |
| --- | --- |
| Unsupported compound grammar, including `DISCOVERED + :no_match` | `"unresolved_value"` |
| Embedded local name not observed | `"unresolved_value"` |
| Any closed resolver outcome | `"unresolved_value"` |
| Occurrence-terminal mismatch | `"unresolved_value"` |
| Slot grammar rejection | `"unresolved_value"` |
| Resolved-form grammar mismatch | `"unresolved_value"` |
| Declaration-local compound resource limit | `"resource_limit_exceeded"` |
| Existing combined owner/provenance reference overflow | Existing `"resource_limit_exceeded"` path |
| Existing unsafe-fragment or `CSSDeclaration` safety rejection | Existing `"unsafe_declaration"` |
| Existing unsupported-property rejection | Existing `"unsupported_declaration"` |

Freeze `COMPOUND_NEW_RESIDUAL_REASON_CODES=0`, `CLOSED_RESOLVER_RESULT_PUBLIC_REASON=unresolved_value`, `SLOT_FAILURE_PUBLIC_REASON=unresolved_value`, `RESOLVED_GRAMMAR_FAILURE_PUBLIC_REASON=unresolved_value`, `COMPOUND_RESOURCE_LIMIT_PUBLIC_REASON=resource_limit_exceeded`, and `RESOLVER_INTERNAL_ERROR_ATOM_PUBLICATION=NO`. Preserve whole-rule atomicity.

### Task 1: pure `CompoundCssValue`

**Files:**

- Create `apps/live_frames/lib/live_frames/adapters/bricks/compound_css_value.ex`.
- Create `apps/live_frames/test/live_frames/bricks_compound_css_value_test.exs`.

**Interfaces:**
- Consumes: The three frozen source productions, four frozen `SLOT_GRAMMAR` contracts, byte/token/depth limits, and positive-finite numeric contract in `docs/development/bounded_compound_css_value_authority.md`. The module does not decide normalizer admission.
- Produces: `CompoundCssValue.parse(binary()) :: {:ok, Parsed.t()} | :no_match | {:error, :unsupported_grammar | :resource_limit_exceeded}`; `occurrences(Parsed.t()) :: [Occurrence.t()]`; and `reconstruct(Parsed.t(), %{non_neg_integer() => binary()}) :: {:ok, binary()} | {:error, :occurrence_terminal_mismatch | :invalid_slot_terminal | :resolved_grammar_mismatch | :resource_limit_exceeded}`. `Parsed` and `Occurrence` fields are exactly those defined in the frozen private module contract above.

The pure module accepts only the three frozen source productions, exposes ordered occurrence descriptors, validates resolver terminals by slot, reconstructs within bounds, and revalidates the same production after substitution. It does not call a resolver or select values by hashes.

- [ ] **Step 1: Add synthetic tests before production code.** Organize focused ExUnit cases around these inputs and expected outcomes:

  | Case | Synthetic input or terminal | Expected result |
  | --- | --- | --- |
  | Gradient source with two stops | `linear-gradient(90deg, transparent 0%, var(--accent) 100%)` | `:function_call`; one occurrence named `--accent` in `GRADIENT_STOP_ATOM` |
  | ASCII case-insensitive outer name | `LINEAR-GRADIENT(90deg, var(--accent))` | `:function_call`; retain the same function identity after reconstruction |
  | Calc source without a factor | `calc(var(--measure))` | `:function_call`; one occurrence in `CALC_OPERAND` |
  | Calc source with the allowed factor form | `calc(var(--measure) * 2)` | `:function_call`; one occurrence in `CALC_OPERAND` |
  | Multi-token literal | `10px 2rem` | `:multi_token_value`; zero occurrences |
  | Juxtaposition source | `var(--duration) var(--timing)` | `:var_reference_with_operation`; ordered indices `0`, `1` and slots left then right |
  | Ordinary non-compound value | `teal` | `:no_match` |
  | Existing direct reference | `var(--local-space)` | `:no_match` |
  | Non-dimension multi-token values | `center center`, `10 20px`, `10px 20px 30px`, `10px + 2px`, and `var(--x) 2px` | No `MULTI_TOKEN_VALUE` parse match; normalizer admission is tested in Task 2 |
  | Unknown outer function | `radial-gradient(90deg, red, blue)` | `:no_match`; no general function parser |
  | Unknown outer function with admitted trigger | `unknown-function(var(--x))` | `:no_match`; production normalizer maps this admitted no-match to `"unresolved_value"` |
  | Malformed allowlisted function | `calc(var(--x) + 2px)`, quoted arguments, an extra outer token, an unmatched parenthesis, or a nested non-`var()` function | `{:error, :unsupported_grammar}` |
  | Invalid juxtaposition lookalikes | `var(--a) var(--b) var(--c)`, `var(--a) + var(--b)`, and `var(--a) 2px var(--b)` | No `VAR_REFERENCE_WITH_OPERATION` match |

  Add gradient rejects for a signed or unit-bearing angle, no angle/comma boundary, an empty stop list, a ninth stop, a fifth atom in one stop segment, a general identifier atom, an operator, a hash, and a nested function. Add calc rejects for a comma, a second reference, `+`, `-`, `/`, a second `*`, a zero or negative multiplication factor, a unit-bearing factor, and nested parentheses beyond `var()`.

  Exercise the private positive-finite predicate through `calc(var(--x) * factor)` source cases. Accept a positive integer, positive decimal, and leading-dot positive decimal where the frozen lexical grammar permits them. Reject zero, a negative value, suffix or junk, overflow/non-finite input. Preserve the exact contract: `Float.parse(text)`, empty suffix, number greater than zero, `number == number`, and number at most `1.7976931348623157e308`. Implement this as a private equivalent in `CompoundCssValue`; do not call or expose `CustomCssNormalizer.positive_finite_number/1`.

  Add terminal acceptance and rejection tables for every slot. Include RGB channels `0` and `255`; reject `256`, fractional channels, hex, and interior RGB whitespace. For RGBA, accept alpha `0`, `1`, and finite fractions in range; reject negative, greater than one, non-finite, percentage, slash, nested, or whitespace forms. For durations, accept `0ms`, `250ms`, and `.5s`; reject signed, negative, unitless, and non-finite values. For timing, accept only `ease-in-out` and reject other identifiers and function forms.

  Add resource cases at each frozen maximum and one unit over it for compound bytes, reconstructed bytes, token count, embedded references, function argument bytes, gradient stops, stop-segment tokens, and parse depth. Assert production 4 always has exactly two tokens and no occurrences. Use different local names with the same grammar shape to prove production and occurrence selection do not depend on a fingerprint or hash.

  Add reconstruction cases for a valid gradient terminal, a valid calc terminal, and valid juxtaposition terminals. Assert that missing or extra occurrence keys return `:occurrence_terminal_mismatch`, a terminal outside its slot returns `:invalid_slot_terminal`, a resolved form outside the same production returns `:resolved_grammar_mismatch`, and an oversized output returns `:resource_limit_exceeded`. Assert no successful reconstruction contains `var(`.

- [ ] **Step 2: Run the new test file and observe RED.** Run `mix test apps/live_frames/test/live_frames/bricks_compound_css_value_test.exs`. Expected: tests fail because the module and its types do not exist. Do not add production code before recording the failing result.
- [ ] **Step 3: Implement only the frozen pure contract.** Add the parser, occurrence representation, slot validators, bounded piece reconstruction, and same-production resolved grammar validation. Keep parser depth at one. Do not add resolver calls, authority lookups, CSS emission, hashes, or source-specific branches.
- [ ] **Step 4: Run the focused parser tests and observe GREEN.** Rerun the same command. Expected: every positive, negative, slot, reconstruction, and limit assertion passes.
- [ ] **Step 5: Check formatting for the two Task 1 files.** Run `mix format --check-formatted apps/live_frames/lib/live_frames/adapters/bricks/compound_css_value.ex apps/live_frames/test/live_frames/bricks_compound_css_value_test.exs`. Expected: both files are formatted.
- [ ] **Step 6: Create the signed Task 1 commit.** After the focused tests pass and formatting is clean, commit only the two Task 1 files with `git commit -S -m "feat: add bounded compound CSS value parser"`.

### Task 2: declaration analysis, reference extraction, and batching

**Files:**

- Modify `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex`.
- Modify `apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`.

**Interfaces:**
- Consumes: Task 1's `CompoundCssValue.parse/1`, `occurrences/1`, `Parsed`, and `Occurrence` contracts; the accepted pre-lifecycle routing order; and the existing local resolver record schema and `resolve/3` batch flow.
- Produces: A route-aware analysis map keyed by `{rule_id, property}` for non-definition declarations only. Its values are `{:direct_reference, local_name}`, `:generic`, `{:compound, {:ok, parsed, occurrences}}`, `{:compound, :no_match}`, or `{:compound, {:error, reason}}`. Admitted declarations are parsed once. Resolver input records keep the current schema. Private compound correlation uses `{rule_id, target_source_id, selector_identity, property, occurrence_index}`; direct correlation remains `{rule_id, target_source_id, selector_identity, property}`. Direct and compound references share the existing per-provenance `reference_count`.

Each admitted non-definition declaration is parsed once per frame/property and reused across target expansion. Compound local references join the existing per-provenance batch with occurrence correlation kept outside resolver records.

- [ ] **Step 1: Add failing normalizer tests first.** Add a synthetic routing-table test for non-definition consumer declarations:

  | Value | Expected route and outcome |
  | --- | --- |
  | `teal` | Existing generic path; preserve its current generic result |
  | `center center` | Existing generic path; preserve its current generic result |
  | `10 20px` | Existing generic path; preserve its current generic result |
  | `unknown-function(...)` without `var(` or `calc(` | Existing generic path; preserve its current generic result |
  | Any `linear-gradient(...)` without `var(` or `calc(` that is not the exact two-dimension production, including malformed arguments | Existing generic path; preserve its current generic result or existing generic safety residual |
  | Exact `var(--x)` | Existing direct-reference path; do not enter compound lifecycle |
  | Supported `linear-gradient(...)` containing `var(` | `DISCOVERED`, then frozen `FUNCTION_CALL` |
  | Malformed `linear-gradient(...)` containing `var(` | `DISCOVERED`, then fail closed with `"unresolved_value"` |
  | `unknown-function(var(--x))` | `DISCOVERED`, then `:no_match` maps to `"unresolved_value"` |
  | Malformed or unsupported `calc(...)` | `DISCOVERED`, then fail closed with `"unresolved_value"` |
  | Exact `var(--a) var(--b)` | `DISCOVERED`, then frozen `VAR_REFERENCE_WITH_OPERATION` |
  | Malformed var juxtaposition such as `var(--a) + var(--b)` | `DISCOVERED`, then fail closed with `"unresolved_value"` |
  | Exact `10px 2rem` | `DISCOVERED`, then frozen `MULTI_TOKEN_VALUE` |

  For generic cases, use properties and synthetic values already accepted by the existing generic path and assert the exact prior result. The pure parser's `:no_match` must never return an admitted declaration to generic normalization.

  Add an ordered two-occurrence test in which `var(--duration) var(--timing)` maps occurrence indices `0` and `1` to the distinct terminals `250ms` and `ease-in-out`. Add a multi-target compound declaration test proving each target receives its expected value with no duplicate reference effects. Do not use production instrumentation to count parse or resolver calls.

  Add a local-definition exclusion regression. Define `--derived: calc(var(--base))` and consume it from a synthetic compound declaration. Assert that the definition remains a resolver definition record, creates zero compound reference records, and the consumer occurrence reaches the existing resolver, which reports the existing `UNSUPPORTED_NESTED_REFERENCE` outcome. Keep FRAME D fail-closed with no emitted style.

  Add the mixed exact-budget test in one effective provenance. Create 511 child targets, each with a compound declaration containing two local references, for 1,022 compound reference records. Add two direct local-reference declarations on one matching owner target in the same provenance. The combined total of 1,024 must pass. Add one further direct local reference and assert the combined total of 1,025 follows the existing `resource_limit_exceeded` residual path with no partial output. This case must fail if direct and compound records use separate counters. Also retain the existing direct-reference correlation case, an unobserved embedded local name with a matching external authority candidate, and a non-`nil` `state_scope` closed case.

- [ ] **Step 2: Run the normalizer test file and observe RED.** Run `mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`. Expected: the new admitted compound cases fail because compound routing is not implemented; ordinary generic and direct-reference cases retain their current results.
- [ ] **Step 3: Build the route-aware declaration analysis once.** Exclude every property where `local_definition_name?(property)` is true. For other declarations, apply the frozen routing order: exact direct reference first; then case-insensitive `var(`/`calc(` presence or exact two-dimension predicate; otherwise generic. Use the existing direct-reference matcher. Implement the two-dimension admission predicate in the normalizer as a bounded exact check using `DIMENSION_LITERAL WS+ DIMENSION_LITERAL`; it must not call `CompoundCssValue.parse/1`. Key the route result by `{frame_rule_id(frame), property}`.
- [ ] **Step 4: Parse each admitted declaration once and reuse its analysis.** Call `CompoundCssValue.parse/1` exactly once per admitted frame/property. Store `{:compound, {:ok, parsed, occurrences}}`, `{:compound, :no_match}`, or `{:compound, {:error, reason}}` with the route result. Reuse the stored parsed value and occurrence list for extraction, correlation, target normalization, and reconstruction. Map admitted `:no_match` and unsupported grammar to `"unresolved_value"`; map compound resource errors to `"resource_limit_exceeded"`.
- [ ] **Step 5: Append compound records and private occurrence correlation.** For each evidenced local occurrence and routed target, use the existing record builder and schema. Add no occurrence metadata to resolver records. Keep direct correlation unchanged and key compound correlation with `occurrence_index`. Definition values never create compound reference records. Production 4 contributes zero resolver references.
- [ ] **Step 6: Reuse the existing per-provenance batch and shared reference counter.** Append compound records to the same `references` list and increment the same `reference_count` used for direct references. Preserve the collect, group by effective provenance identity, single `resolve/3` call per provenance, and ordered cardinality-preserving result correlation. Do not create a parallel counter or a per-occurrence resolver call path.
- [ ] **Step 7: Run the focused normalizer tests and observe GREEN.** Rerun `mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`. Expected: the routing table, definition exclusion, occurrence ordering, exact mixed 1,024 pass, 1,025 fail, direct path, generic path, state-scope failure, and no-external-fallback assertions pass.
- [ ] **Step 8: Check formatting for the modified normalizer and its test.** Run `mix format --check-formatted apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`. Expected: both files are formatted.
- [ ] **Step 9: Create the signed Task 2 commit.** After the focused tests pass and formatting is clean, commit only the two Task 2 files with `git commit -S -m "feat: collect compound CSS references"`.

### Task 3: reconstruction, final literal handoff, and atomicity

**Files:**

- Modify `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex`.
- Modify `apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`.

**Interfaces:**
- Consumes: Task 1's `CompoundCssValue.reconstruct/2` contract and Task 2's route-aware analysis, ordered resolver results, unchanged resolver records, and private occurrence correlation keys.
- Produces: For each compound declaration, either the existing tagged literal `{"kind" => "literal", "value" => binary()}` after slot validation, reconstruction, resolved-form revalidation, and `CSSDeclaration.normalize(..., :source_resolver)`, or an existing public residual reason. It adds no `StyleValue`, Design IR, resolver, or diagnostic schema.

Every compound occurrence must resolve and pass its slot check before reconstruction. The same production is checked again, `CSSDeclaration` revalidates with `:source_resolver`, and success emits an existing literal value without generic `var()` / `calc()` classification.

- [ ] **Step 1: Add failing output and failure tests first.** Cover these cases:

  | Case | Synthetic declarations | Expected result |
  | --- | --- | --- |
  | Gradient success | Local `--accent: rgb(1,2,3)` used by `linear-gradient(90deg, var(--accent) 100%)` | The target style is a literal gradient with the terminal substituted |
  | Calc success | Local `--measure: 12px` used by `calc(var(--measure) * 2)` | The target style is literal `calc(12px * 2)` |
  | Juxtaposition success | Local duration `250ms` and timing `ease-in-out` used as two embedded refs | One literal `250ms ease-in-out`; each occurrence uses its own result |
  | Production 4 success | `gap: 10px 20px` | One literal two-dimension value and zero resolver references |
  | Wrong slot | `ease-in-out` resolves into the left duration slot | Whole declaration and rule remain residual |
  | `:no_local_definition` | A referenced name is observed in an ineligible scoped definition, so no eligible definition reaches the resolver; supply no external authority candidate | Whole declaration remains residual |
  | No local definition with external candidate present | Embedded name has no observed local definition; `VariableAuthority` contains that name | Whole declaration remains residual; no token reference is emitted |
  | Unsupported nested dependency | Embedded local definition depends on another `var()` | Whole declaration remains residual for `:unsupported_nested_reference` |
  | Unsupported state scope | Compound consumer has a non-`nil` `state_scope` | Whole declaration remains residual for `:unsupported_scope` |
  | Mixed declaration rule | One compound declaration can resolve, while a sibling declaration contains an unsafe URL value | No base or responsive output from that rule; the original rule remains residual |
  | Existing paths | Existing direct local `var(--name)`, direct external authority, and ordinary literal declarations | Existing direct correlation and ordinary outputs remain unchanged |

  Assert the public failure mapping explicitly: admitted `:no_match`, unsupported compound grammar, unobserved compound local, any closed resolver result, occurrence mismatch, slot rejection, and resolved-form rejection all produce `"unresolved_value"`; per-declaration compound limits and combined provenance overflow produce `"resource_limit_exceeded"`; existing unsafe declaration and unsupported property cases retain `"unsafe_declaration"` and `"unsupported_declaration"`. Assert no resolver error atom or new reason string appears in residuals.

- [ ] **Step 2: Run the normalizer tests and observe RED.** Run `mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`. Expected: the compound success cases remain unresolved and the failure-path assertions confirm no fallback. Do not implement until the new assertions fail for the intended missing compound path.
- [ ] **Step 3: Reconstruct and revalidate every compound result.** Require the resolver result count to equal its reference count and require an actual successful result for every occurrence index. Pass all occurrence terminals together to `CompoundCssValue.reconstruct/2`. Any resolver error, missing result, slot failure, reconstruction error, unresolved `var(`, or resolved-form failure makes the declaration residual. Preserve `FRAME C` and `FRAME D` closed outcomes.
- [ ] **Step 4: Share final declaration safety.** Extract `safe_declaration_value/3` from the current safety checks. Keep generic normalization as safety, then `normalize_declaration_value/3`. For compound success, call it with `:source_resolver`, then return the existing literal tagged value directly. Do not send reconstructed `calc(...)` back through the generic classifier and do not enter `VariableAuthority` from the compound lane.
- [ ] **Step 5: Preserve existing frame atomicity.** Keep the current target/frame reduction behavior. If any declaration or target in one rule fails, discard all base and responsive candidates from that rule. Do not emit successful compound siblings from a partially failed rule.
- [ ] **Step 6: Pin the residual reason mapping.** Assert the exact public reasons from the Task 3 table for unsupported grammar, admitted `:no_match`, missing/unobserved locals, closed resolver outcomes including `:no_local_definition`, `:unsupported_nested_reference`, and `:unsupported_scope`, occurrence mismatch, wrong slot, resolved-form mismatch, declaration-local resource limits, shared batch overflow, unsafe CSS, and unsupported properties. Assert resolver atoms never leak and no new residual code appears.
- [ ] **Step 7: Run focused parser and normalizer tests.** Run:

  ```sh
  mix test apps/live_frames/test/live_frames/bricks_compound_css_value_test.exs
  mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs
  ```

  Expected: both files pass, compound success is literal, every failure case remains residual, direct-reference behavior is unchanged, and whole-rule atomicity holds.
- [ ] **Step 8: Check formatting for all four implementation files.** Run `mix format --check-formatted` with the four paths listed under the implementation file boundary. Expected: all four files are formatted.
- [ ] **Step 9: Create the signed Task 3 commit.** After focused tests pass and formatting is clean, commit only the Task 3 changes in the two normalizer files with `git commit -S -m "feat: finalize bounded compound CSS values"`.

### Task 4: full regression and canonical rerun protocol

**Files:** No additional implementation files. Use only the four files listed in the implementation boundary.

**Interfaces:**
- Consumes: The completed Task 1 parser/reconstructor, Task 2 routing and batched references, and Task 3 literal finalization and residual mapping.
- Produces: Fresh focused, full-suite, formatting, compile, quality-gate, and authorized canonical-verification evidence. Task 4 adds no production behavior or implementation file.

The implementation passes focused and repository checks. The same canonical Romeo conversion runs only after implementation exists and the implementation gate authorizes that run. The committed evidence contains no private source, raw values, selector text, local names, or paths.

- [ ] **Step 1: Run the complete `apps/live_frames` suite.** Run `mix test apps/live_frames/test`. Expected: all tests in that child app pass.
- [ ] **Step 2: Run the repository CI quality commands.** Run each command from the umbrella root and record its exit status:

  ```sh
  mix deps.get
  mix format --check-formatted
  mix compile --warnings-as-errors
  mix assets.build
  git diff --exit-code -- apps/live_frames/assets/css/theme/lf_theme.css apps/live_frames/priv/static/live_frames/css/live_frames.css
  mix test
  mix deps.unlock --check-unused
  git diff --check
  ```

  These are the current CI and repository gates. Report any skipped command with its reason. Do not weaken or hide a failing gate.
- [ ] **Step 3: Recheck the routing and resolver regressions before canonical verification.** Run the focused parser and normalizer test files. Confirm ordinary generic literals remain unchanged, exact direct `var(--name)` behavior remains unchanged, admitted malformed compound syntax fails closed, custom-property definitions remain compiler inputs and FRAME D remains fail-closed, and the combined direct-plus-compound reference budget passes at 1,024 and fails at 1,025. Do not use production instrumentation or private canonical source for these checks.
- [ ] **Step 4: Rerun the existing canonical Romeo conversion after implementation exists and the separate implementation gate authorizes that run.** Use `LiveFrames.Adapters.Bricks.to_ir/2` with the same accepted input identity, component identity, and no-ACSS context as the accepted canonical baseline. Supply a fresh empty `TokenSet` for each independent run, no ACSS fixture or profile, no external token authority, and no structural-variable or named-breakpoint authority. Serialize the returned document with `LiveFrames.IR.encode!/1`. Do not create or commit a substitute canonical fixture. Keep the source in its existing private location and inspect it as inert JSON only. Publish safe evidence only:

  - Resulting canonical IR SHA and byte count.
  - Residual counts by diagnostic surface.
  - Old and new residual fingerprint sets.
  - Compound finding disposition by the frozen dependency matrix.
  - Resolver success and error counts by frozen outcome.
  - Confirmation that no new diagnostic fingerprints appeared.
  - Confirmation that `FRAME C` and `FRAME D` remain fail-closed.
  - Selector residual inventory unchanged unless a separate accepted authority authorizes a change.
  - Existing `767` minimum and maximum boundary counts unchanged.
  - No token-reference emission from the local compound lane and no external fallback.

  Do not publish raw declarations, source paths, local names, selector text, resolver terminals, or private source JSON. If the existing canonical conversion cannot run from its accepted entry point without exposing private material, stop with `STOP=PRIVATE_SOURCE_PUBLICATION_RISK` and report the blocker.
- [ ] **Step 5: Derive the canonical delta from the accepted matrix.** Do not define success as eight compound findings becoming zero. Record `EXPECTED_CANONICAL_DELTA=DERIVE_FROM_MATRIX_AT_IMPLEMENTATION_VERIFY` and `COMPOUND_SUCCESS_CRITERION_8_TO_0=REJECTED`. Keep any resolver error, unsupported scope, unsafe terminal, or atomicity failure residual as required by the authority.
- [ ] **Step 6: Review scope and handoff.** Confirm the implementation diff contains exactly the four planned files and no private canonical source. Confirm the resolver schema and interface, `VariableAuthority`, `CSSDeclaration`, Design IR, selector grammar, and generator are unchanged. Report branch, exact commit and tree, signed history, changed files, focused and full gate results, canonical evidence status, PR state, and whether implementation remains authorized. Do not merge unless a later user instruction authorizes it.

## Performance and scaling review

```text
DATA_LAYER=COLD_BUILD_TIME
REDIS=N/A
POSTGRES=N/A
PUBSUB=N/A
OBAN=N/A
CACHEX=N/A
CDN=N/A
100K_CONCURRENT_USERS=N/A
```

The reviewer must confirm that implementation:

- Parses one bounded declaration at a time and stores only its bounded private analysis.
- Uses no general CSS evaluator and no recursion beyond `MAX_COMPOUND_PARSE_DEPTH=1`.
- Does not scan the full document once per occurrence or parse again for each target.
- Adds compound references to the existing per-provenance resolver batch.
- Enumerates bounded frames, declarations, targets, and occurrences without introducing an O(N^2) document walk.
- Uses the existing 1,024 reference bound rather than a parallel unbounded counter.
- Adds no runtime infrastructure. This conversion path runs at cold build time.

## Plan self-review

The writing-plans self-review is complete against the accepted discovery authority, the older local resolver plan, the current normalizer, and the current normalizer tests:

- **Spec coverage:** Tasks 1 through 4 cover admission, the frozen productions and four slots, local-definition exclusion, numeric and resource bounds, parse-once reuse, ordered records, the shared direct-plus-compound reference limit, literal finalization, exact failure mapping, atomicity, full regression, and gated canonical verification.
- **Step granularity:** Tasks 1 through 3 start with failing tests, then implementation, green verification, formatting, and a signed commit. Task 4 owns repository-wide checks and canonical verification.
- **Interface consistency:** `parse/1`, `occurrences/1`, and `reconstruct/2` use the frozen `Parsed` and `Occurrence` types. Task 2 produces the route-aware analysis and private correlation consumed by Task 3. Resolver record fields remain unchanged.
- **Review focus:** All ten listed risks map to named Task 2 or Task 3 tests.
- **Proportion:** The plan authorizes implementation changes in exactly four files and contains no production implementation body.
- **Placeholder scan:** The plan contains no `TODO`, `TBD`, or deferred semantic decision.

The accepted compound authority takes precedence over assumptions in the older local resolver plan. The exact comparison files are `docs/development/bounded_compound_css_value_authority.md`, `docs/superpowers/plans/2026-10-19-css-local-custom-property-resolver.md`, `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex`, and `apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`.

## Stop conditions

Stop implementation if any of these occurs: `MAIN_MOVED_WITH_MATERIAL_COMPOUND_AUTHORITY_CONFLICT`, `ACCEPTED_AUTHORITY_MISSING_FROM_MAIN`, `ACCEPTED_DISCOVERY_AUTHORITY_CONTRADICTION`, `AUTHORITY_SEMANTICS_REQUIRE_REOPENING`, `PLANNED_IMPLEMENTATION_BOUNDARY_EXPANDED`, `LOCAL_DEFINITION_COMPOUND_ANALYSIS_REQUIRED`, `SHARED_REFERENCE_BUDGET_CANNOT_BE_PROVEN`, `NEW_PUBLIC_RESIDUAL_REASON_REQUIRED`, `PRIVATE_HELPER_INTERFACE_CHANGE_REQUIRED`, `SOURCE_LOCAL_RESOLVER_CHANGE_REQUIRED`, `SECOND_VARIABLE_RESOLUTION_PATH_REQUIRED`, `VARIABLE_AUTHORITY_FALLBACK_REQUIRED`, `DESIGN_IR_SCHEMA_CHANGE_REQUIRED`, `SELECTOR_GRAMMAR_CHANGE_REQUIRED`, `SOURCE_SPECIFIC_HACK_REQUIRED`, `UNBOUNDED_PARSER_REQUIRED`, `REPEATED_PER_TARGET_PARSE_REQUIRED`, or `PRIVATE_SOURCE_PUBLICATION_RISK`. During this plan-correction PR, any code change, test change, implementation start, or merge is out of scope. Report the exact condition. Do not continue by widening the plan or changing the accepted authority.

## Frozen implementation outcomes

```text
COMPOUND_PARSE_ONCE_PER_FRAME_DECLARATION=YES
COMPOUND_PARSE_PER_TARGET=NO
COMPOUND_DISCOVERY_BOUNDARY=COMPATIBILITY_PRESERVING
COMPOUND_DISCOVERY_REUSES_EXISTING_GENERIC_CLOSED_TRIGGER=YES
DIRECT_VAR_ROUTED_BEFORE_COMPOUND_DISCOVERY=YES
LOCAL_DEFINITION_ROUTED_BEFORE_COMPOUND_DISCOVERY=YES
OUTSIDE_COMPOUND_LANE_USES_EXISTING_GENERIC_PATH=YES
COMPOUND_PARSE_CALLED_FOR_OUTSIDE_LANE=NO
DISCOVERED_COMPOUND_CAN_FALL_BACK_TO_GENERIC=NO
NO_MATCH_SEMANTICS=CONTEXTUAL_PRIVATE_PARSE_RESULT
DISCOVERED_PARSE_NO_MATCH=FAIL_CLOSED_RESIDUAL
DISCOVERED_PARSE_NO_MATCH_PUBLIC_REASON=unresolved_value
COMPOUND_ANALYSIS_LOCAL_DEFINITION_PROPERTIES=SKIP
COMPOUND_OCCURRENCES_FROM_DEFINITION_VALUES=0
CUSTOM_PROPERTY_DEFINITIONS_REMAIN_COMPILER_INPUTS_ONLY=YES
DIRECT_AND_COMPOUND_REFERENCE_COUNTER_SHARED=YES
PARALLEL_COMPOUND_REFERENCE_COUNTER=NO
MAX_LOCAL_REFERENCES_PER_OWNER_LAYER=1024
COMPOUND_NEW_RESIDUAL_REASON_CODES=0
CLOSED_RESOLVER_RESULT_PUBLIC_REASON=unresolved_value
SLOT_FAILURE_PUBLIC_REASON=unresolved_value
RESOLVED_GRAMMAR_FAILURE_PUBLIC_REASON=unresolved_value
COMPOUND_RESOURCE_LIMIT_PUBLIC_REASON=resource_limit_exceeded
RESOLVER_INTERNAL_ERROR_ATOM_PUBLICATION=NO
CUSTOM_CSS_NORMALIZER_POSITIVE_FINITE_HELPER_VISIBILITY_CHANGED=NO
COMPOUND_POSITIVE_FINITE_CONTRACT=SEMANTICALLY_IDENTICAL_PRIVATE_PREDICATE
SOURCE_LOCAL_CUSTOM_PROPERTY_RESOLVER_CHANGE_REQUIRED=NO
RESOLVER_REFERENCE_RECORD_SCHEMA_CHANGED=NO
RESOLVER_PUBLIC_INTERFACE_CHANGED=NO
VARIABLE_AUTHORITY_CHANGE_REQUIRED=NO
CSS_DECLARATION_CHANGE_REQUIRED=NO
DESIGN_IR_SCHEMA_CHANGED=NO
NATIVE_GENERATOR_CHANGE_REQUIRED=NO
PRODUCTION_RESOLVER_BATCHING=EXISTING_PER_PROVENANCE_BATCH
PER_OCCURRENCE_RESOLVER_CALL_IMPLEMENTATION=NO
COMPOUND_SUCCESS_STYLE_KIND=LITERAL
VARIABLE_AUTHORITY_REENTRY=NO
EXPECTED_CANONICAL_DELTA=DERIVE_FROM_MATRIX_AT_IMPLEMENTATION_VERIFY
COMPOUND_SUCCESS_CRITERION_8_TO_0=REJECTED
COMPOUND_IMPLEMENTATION_AUTHORIZED=NO
```
