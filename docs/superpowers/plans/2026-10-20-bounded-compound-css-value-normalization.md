# Bounded compound CSS value normalization implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the accepted bounded compound CSS value capability without changing resolver semantics, Design IR schemas, selector grammar, `VariableAuthority`, `CSSDeclaration`, or generator behavior.

**Architecture:** `CompoundCssValue` will parse, classify, validate, and reconstruct only the frozen compound productions. `CustomCssNormalizer` will parse each frame declaration once, send only evidenced local occurrences through its existing per-provenance resolver batches, correlate results privately, and hand successful reconstructed values to the existing literal `StyleValue` path after `CSSDeclaration` revalidation.

**Tech Stack:** Elixir umbrella application, Mix, ExUnit.

---

## Gate record

```text
PLAN_GATE=IMPLEMENTATION_PLAN_ONLY
BASE_SHA=3bc61ed5eba8e9004642c412cb48b68a46704acb
BASE_TREE=78094030d3c88248123af33c3fafd5eeab42cd49
BASE_CI=39383772954 SUCCESS

PR_269=MERGED
PR_269_APPROVED_HEAD=e06819d003cbec21d3e34245c958ee54ddc26f6d
PR_269_MERGE_SHA=539ffa09e7b957c7dd48ec03c1ce4d1b6a823e97
PR_269_MERGE_TREE=afc0c3c0328329f08c5566cd8284338c0e4d5953
PR_269_POST_MERGE_CI=39383739868 SUCCESS
MAIN_ADVANCE_AFTER_269=MATERIAL_COMPOUND_CONFLICT_NO

COMPOUND_ARCHITECTURE_AUTHORITY=ACCEPTED
COMPOUND_IMPLEMENTATION_PLAN_AUTHORIZED=YES
COMPOUND_IMPLEMENTATION_AUTHORIZED=NO
```

The accepted architecture authority is [`docs/development/bounded_compound_css_value_authority.md`](../../development/bounded_compound_css_value_authority.md). The later `main` change in PR #270 touches only component-review implementation and tests. It does not change the compound authority or this plan's implementation boundary.

The authority file retains earlier lifecycle text that marks its architecture review as pending. This plan follows the explicit post-merge gate supplied for PR #269, which records the architecture as accepted and authorizes this plan. The implementation remains unauthorized.

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

`parse/1` returns `:no_match` for the existing direct `var(--name)` form and for values outside the frozen compound productions. `CustomCssNormalizer` must keep those results on their existing path. A malformed value that has entered an allowlisted outer `linear-gradient(...)` or `calc(...)` production returns a closed grammar error; an entered production that exceeds a frozen resource bound returns `:resource_limit_exceeded`. Do not turn `:no_match` into a residual by itself.

No function in this module calls `SourceLocalCustomPropertyResolver`, `VariableAuthority`, `CSSDeclaration.normalize/2`, or any selector, owner, provenance, Design IR, or generator code.

## Frozen grammar and flow

Classify the entire trimmed declaration value against the three disjoint productions. Do not introduce a precedence order. The existing exact direct `var(--name)` form remains on the direct-reference path.

1. `FUNCTION_CALL`: outer names `linear-gradient` and `calc` only, using ASCII case-insensitive matching. The outer call is depth 1. `var(--name)` is the only permitted nested call-like form, does not increase depth, and is scanned only for occurrence extraction. Reject quoted strings, other nested functions, extra operators, commas in `calc`, and tokens outside the outer call. Enforce the frozen gradient and `calc` source and resolved grammars.
2. `MULTI_TOKEN_VALUE`: exactly two `DIMENSION_LITERAL` tokens separated by permitted ASCII whitespace. Both tokens use `^-?\d+(\.\d+)?(px|rem|em|vh|vw|fr|deg|%)$` with case-sensitive units. It has no embedded reference. Do not allow keywords, a separate percentage class, unitless numbers, identifiers, operators, commas, functions, or another token count into this production.
3. `VAR_REFERENCE_WITH_OPERATION`: exactly `LOCAL_REF WS LOCAL_REF`, with ASCII whitespace and no operator. The resolved form is exactly `JUXTAPOSITION_LEFT_OPERAND WS JUXTAPOSITION_RIGHT_OPERAND`.

Use these exact function argument grammars. The permitted ASCII whitespace set is space, tab, carriage return, line feed, and form feed. Use that same set for function token spacing, multi-token separation, stop-segment separation, and juxtaposition separation.

- `linear-gradient` has one argument span of at most 2,048 bytes. It is `<angle>, <stop-list>`, where `<angle>` is `\d+(\.\d+)?deg`. The stop list has one through eight comma-separated stop segments. Between stop segments, a comma may be followed by ASCII whitespace. Each segment has one through four ASCII-whitespace-separated atoms. Each atom is exactly `transparent`, `\d+(\.\d+)?%`, or one embedded direct local `var(--name)` occurrence. A general identifier, operator, hash, or nested `(` is rejected.
- `calc` has one argument span of at most 2,048 bytes and matches exactly `var(--name)` or `var(--name) * <positive-finite-number>`. ASCII whitespace may surround these tokens. The factor has lexical form `(?:\d+(?:\.\d+)?|\.\d+)` and must pass the existing `CustomCssNormalizer.positive_finite_number/1` finite, positive, and unitless check. No comma, second `var(`, other operator, or nested function is allowed.
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

Create one normalizer-private declaration analysis map keyed by `{rule_id, property}`, where `rule_id` is the existing `{source_index, source_order}` returned by `frame_rule_id/1`. Call `CompoundCssValue.parse/1` at most once for a frame/property and retain its exact result (`{:ok, parsed}`, `:no_match`, or `{:error, reason}`). Reuse a successful parsed value and its occurrence list for reference extraction, occurrence correlation, every matching target, and reconstruction. Do not create a generalized compiler cache.

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

Map compound grammar, missing-local, closed resolver, slot, reconstruction, and resolved-form failures to the existing whole-rule residual behavior without adding a diagnostic code or fingerprint input. Keep the existing owner/provenance `resource_limit_exceeded` path for overflow of the shared 1,024-reference batch. Final declaration safety failures retain the current `unsafe_declaration` or `unsupported_declaration` reason.

## Task 1: pure `CompoundCssValue`

**Files:**

- Create `apps/live_frames/lib/live_frames/adapters/bricks/compound_css_value.ex`.
- Create `apps/live_frames/test/live_frames/bricks_compound_css_value_test.exs`.

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
  | Non-dimension multi-token values | `center center`, `10 20px`, `10px 20px 30px`, `10px + 2px`, and `var(--x) 2px` | No `MULTI_TOKEN_VALUE` match; preserve the existing generic path |
  | Unknown outer function | `radial-gradient(90deg, red, blue)` | No `FUNCTION_CALL` match; no general function parser |
  | Malformed allowlisted function | `calc(var(--x) + 2px)`, quoted arguments, an extra outer token, an unmatched parenthesis, or a nested non-`var()` function | `{:error, :unsupported_grammar}` |
  | Invalid juxtaposition lookalikes | `var(--a) var(--b) var(--c)`, `var(--a) + var(--b)`, and `var(--a) 2px var(--b)` | No `VAR_REFERENCE_WITH_OPERATION` match |

  Add gradient rejects for a signed or unit-bearing angle, no angle/comma boundary, an empty stop list, a ninth stop, a fifth atom in one stop segment, a general identifier atom, an operator, a hash, and a nested function. Add calc rejects for a comma, a second reference, `+`, `-`, `/`, a second `*`, a zero or negative multiplication factor, a unit-bearing factor, and nested parentheses beyond `var()`.

  Add terminal acceptance and rejection tables for every slot. Include RGB channels `0` and `255`; reject `256`, fractional channels, hex, and interior RGB whitespace. For RGBA, accept alpha `0`, `1`, and finite fractions in range; reject negative, greater than one, non-finite, percentage, slash, nested, or whitespace forms. For durations, accept `0ms`, `250ms`, and `.5s`; reject signed, negative, unitless, and non-finite values. For timing, accept only `ease-in-out` and reject other identifiers and function forms.

  Add resource cases at each frozen maximum and one unit over it for compound bytes, reconstructed bytes, token count, embedded references, function argument bytes, gradient stops, stop-segment tokens, and parse depth. Assert production 4 always has exactly two tokens and no occurrences. Use different local names with the same grammar shape to prove production and occurrence selection do not depend on a fingerprint or hash.

  Add reconstruction cases for a valid gradient terminal, a valid calc terminal, and valid juxtaposition terminals. Assert that missing or extra occurrence keys return `:occurrence_terminal_mismatch`, a terminal outside its slot returns `:invalid_slot_terminal`, a resolved form outside the same production returns `:resolved_grammar_mismatch`, and an oversized output returns `:resource_limit_exceeded`. Assert no successful reconstruction contains `var(`.

- [ ] **Step 2: Run the new test file and observe RED.** Run `mix test apps/live_frames/test/live_frames/bricks_compound_css_value_test.exs`. Expected: tests fail because the module and its types do not exist. Do not add production code before recording the failing result.
- [ ] **Step 3: Implement only the frozen pure contract.** Add the parser, occurrence representation, slot validators, bounded piece reconstruction, and same-production resolved grammar validation. Keep parser depth at one. Do not add resolver calls, authority lookups, CSS emission, hashes, or source-specific branches.
- [ ] **Step 4: Run the focused parser tests and observe GREEN.** Rerun the same command. Expected: every positive, negative, slot, reconstruction, and limit assertion passes.
- [ ] **Step 5: Check formatting for the two Task 1 files.** Run `mix format --check-formatted apps/live_frames/lib/live_frames/adapters/bricks/compound_css_value.ex apps/live_frames/test/live_frames/bricks_compound_css_value_test.exs`. Expected: both files are formatted.

## Task 2: declaration analysis, reference extraction, and batching

**Files:**

- Modify `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex`.
- Modify `apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`.

Each declaration is parsed once per frame/property and reused across target expansion. Compound local references join the existing per-provenance batch with occurrence correlation kept outside resolver records.

- [ ] **Step 1: Add failing normalizer tests first.** Add tests proving that a two-occurrence juxtaposition declaration resolves two different local names independently; a multi-target compound declaration produces correct styles for each target; and the exact reference bound is preserved. For the bound assertion, define `--duration: 250ms` and `--timing: ease-in-out` on `.owner`, then use `transition: var(--duration) var(--timing)` on `.owner .child`. Create 512 matching child targets. The 512-target case contributes exactly 1,024 references and resolves. The otherwise identical 513-target case exceeds the existing bound and leaves the affected owner/provenance scope residual with no partial output. Also assert that the existing direct local-reference case still correlates and emits the same literal, that an unobserved embedded local name with a matching external authority candidate remains residual, and that a non-`nil` `state_scope` remains residual. The two-occurrence case asserts ordered results from one effective provenance batch; Step 5 verifies that the production code still calls `resolve/3` once per provenance. Do not add resolver-call instrumentation.
- [ ] **Step 2: Run the normalizer test file and observe RED.** Run `mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`. Expected: the compound references do not resolve and the bound/cardinality assertions fail. Keep existing direct-reference assertions passing before implementation.
- [ ] **Step 3: Add one frame/declaration analysis pass.** Key it by `{frame_rule_id(frame), property}` and retain the single `CompoundCssValue.parse/1` result. Use that stored parse for extraction and all target normalization. Do not parse once for each selector target.
- [ ] **Step 4: Add occurrence records to the existing collection path.** For each observed compound local name and routed target, call the same local record builder and append to the existing provenance `references` list. Key compound correlation by `{rule_id, target_source_id, selector_identity, property, occurrence_index}`. Leave direct-reference correlation exactly `{rule_id, target_source_id, selector_identity, property}`. Keep every resolver input field and its value unchanged. Production 4 contributes zero references.
- [ ] **Step 5: Reuse the existing limit and resolver batches.** Count compound records through the existing per-provenance `reference_count` and 1,024 limit. Keep the current collect, group by effective provenance identity, single `resolve/3` call per provenance, and ordered result correlation. Check that each resolver result list has the same cardinality as its reference list before correlating it. Do not create a second counter or per-occurrence call path.
- [ ] **Step 6: Run the focused normalizer tests and observe GREEN.** Rerun `mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`. Expected: both embedded occurrences correlate independently, every matching target receives its value, 1,024 references pass, and the first attempted reference above 1,024 fails closed without partial styles.
- [ ] **Step 7: Check formatting for the modified normalizer and its test.** Run `mix format --check-formatted apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`. Expected: both files are formatted.

## Task 3: reconstruction, final literal handoff, and atomicity

**Files:**

- Modify `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex`.
- Modify `apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`.

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

- [ ] **Step 2: Run the normalizer tests and observe RED.** Run `mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`. Expected: the compound success cases remain unresolved and the failure-path assertions confirm no fallback. Do not implement until the new assertions fail for the intended missing compound path.
- [ ] **Step 3: Reconstruct and revalidate every compound result.** Require the resolver result count to equal its reference count and require an actual successful result for every occurrence index. Pass all occurrence terminals together to `CompoundCssValue.reconstruct/2`. Any resolver error, missing result, slot failure, reconstruction error, unresolved `var(`, or resolved-form failure makes the declaration residual. Preserve `FRAME C` and `FRAME D` closed outcomes.
- [ ] **Step 4: Share final declaration safety.** Extract `safe_declaration_value/3` from the current safety checks. Keep generic normalization as safety, then `normalize_declaration_value/3`. For compound success, call it with `:source_resolver`, then return the existing literal tagged value directly. Do not send reconstructed `calc(...)` back through the generic classifier and do not enter `VariableAuthority` from the compound lane.
- [ ] **Step 5: Preserve existing frame atomicity.** Keep the current target/frame reduction behavior. If any declaration or target in one rule fails, discard all base and responsive candidates from that rule. Do not emit successful compound siblings from a partially failed rule.
- [ ] **Step 6: Run focused parser and normalizer tests.** Run:

  ```sh
  mix test apps/live_frames/test/live_frames/bricks_compound_css_value_test.exs
  mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs
  ```

  Expected: both files pass, compound success is literal, every failure case remains residual, direct-reference behavior is unchanged, and whole-rule atomicity holds.
- [ ] **Step 7: Check formatting for all four implementation files.** Run `mix format --check-formatted` with the four paths listed under the implementation file boundary. Expected: all four files are formatted.

## Task 4: full regression and canonical rerun protocol

**Files:** No additional implementation files. Use only the four files listed in the implementation boundary.

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
- [ ] **Step 3: Rerun the existing canonical Romeo conversion after implementation exists.** Use `LiveFrames.Adapters.Bricks.to_ir/2` with the same accepted input identity, component identity, and no-ACSS context as the accepted canonical baseline. Supply a fresh empty `TokenSet` for each independent run, no ACSS fixture or profile, no external token authority, and no structural-variable or named-breakpoint authority. Serialize the returned document with `LiveFrames.IR.encode!/1`. Do not create or commit a substitute canonical fixture. Keep the source in its existing private location and inspect it as inert JSON only. Publish safe evidence only:

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
- [ ] **Step 4: Derive the canonical delta from the accepted matrix.** Do not define success as eight compound findings becoming zero. Record `EXPECTED_CANONICAL_DELTA=DERIVE_FROM_MATRIX_AT_IMPLEMENTATION_VERIFY` and `COMPOUND_SUCCESS_CRITERION_8_TO_0=REJECTED`. Keep any resolver error, unsupported scope, unsafe terminal, or atomicity failure residual as required by the authority.
- [ ] **Step 5: Review scope and handoff.** Confirm the implementation diff contains exactly the four planned files and no private canonical source. Confirm the resolver schema and interface, `VariableAuthority`, `CSSDeclaration`, Design IR, selector grammar, and generator are unchanged. Report branch, exact commit and tree, signed history, changed files, focused and full gate results, canonical evidence status, PR state, and whether implementation remains authorized. Do not merge unless a later user instruction authorizes it.

## Review focus

Review each risk against its named test before accepting implementation:

1. **Repeated parsing or target expansion duplicates records.** Task 2's 512-target and 513-target reference-bound tests must show exactly two compound references per target through the existing 1,024 limit, with no instrumentation. Review the `{rule_id, property}` cache and ensure the parsed value is reused across target normalization.
2. **Occurrence indices collide within one declaration.** Task 2's two-name juxtaposition test and Task 3's independent duration/timing result test must prove indices `0` and `1` map to different local names and slots.
3. **A compound name reaches `VariableAuthority`.** Task 3's missing local definition test must supply a matching external authority candidate and still assert a residual with no token-reference output.
4. **A safe terminal violates its slot.** Task 3's wrong-slot test must use a resolver-eligible definition whose terminal is CSS-safe but invalid for `JUXTAPOSITION_LEFT_OPERAND`; the rule must stay residual.
5. **A successful compound leaks from a partially failing rule.** Task 3's mixed declaration test must pair a resolvable compound declaration with an unsafe sibling and assert that the rule emits no base or responsive styles.

## Performance and scaling review

```text
DATA_LAYER=COLD_BUILD_TIME
REDIS=N/A
POSTGRES=N/A
PUBSUB=N/A
OBAN=N/A
CACHEX=N/A
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

The writing-plans self-review is complete against the accepted authority, the older local resolver plan, the current normalizer, and the current normalizer tests:

- **Spec coverage:** Tasks 1 through 4 cover the pure grammar, all four slots, bounds, parser reuse, local record extraction, unchanged resolver batching, literal finalization, atomicity, full regression, and safe canonical verification.
- **Step granularity:** Tasks 1 through 3 start with failing tests, then focused implementation, then a named green command. Task 4 owns repository-wide checks and canonical verification.
- **Interface consistency:** `parse/1`, `occurrences/1`, and `reconstruct/2` use one `Parsed` and one `Occurrence` type. `function_name` preserves the exact allowlisted call identity. The normalizer uses `{rule_id, property}` for one-time analysis and adds `occurrence_index` only to private compound correlation.
- **Review focus:** Each required high-risk case maps to concrete Task 2 or Task 3 assertions.
- **Proportion:** The plan authorizes implementation changes in exactly four files and contains no production implementation body.
- **Placeholder scan:** The plan contains no `TODO`, `TBD`, or deferred semantic decision.

The accepted compound authority takes precedence over assumptions in the older local resolver plan. The exact comparison files are `docs/development/bounded_compound_css_value_authority.md`, `docs/superpowers/plans/2026-10-19-css-local-custom-property-resolver.md`, `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex`, and `apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`.

## Stop conditions

Stop implementation if any of these occurs: `MAIN_MOVED_WITH_MATERIAL_COMPOUND_AUTHORITY_CONFLICT`, `ACCEPTED_AUTHORITY_MISSING_FROM_MAIN`, `AUTHORITY_SEMANTICS_REQUIRE_REOPENING`, `PLANNED_IMPLEMENTATION_BOUNDARY_EXPANDED`, `SOURCE_LOCAL_RESOLVER_CHANGE_REQUIRED`, `SECOND_VARIABLE_RESOLUTION_PATH_REQUIRED`, `VARIABLE_AUTHORITY_FALLBACK_REQUIRED`, `DESIGN_IR_SCHEMA_CHANGE_REQUIRED`, `SELECTOR_GRAMMAR_CHANGE_REQUIRED`, `SOURCE_SPECIFIC_HACK_REQUIRED`, `UNBOUNDED_PARSER_REQUIRED`, `REPEATED_PER_TARGET_PARSE_REQUIRED`, or `PRIVATE_SOURCE_PUBLICATION_RISK`. For this plan-authoring gate, any code change, test change, implementation start, or merge is out of scope. Report the exact condition. Do not continue by widening the plan or changing the accepted authority.

## Frozen implementation outcomes

```text
COMPOUND_PARSE_ONCE_PER_FRAME_DECLARATION=YES
COMPOUND_PARSE_PER_TARGET=NO
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
