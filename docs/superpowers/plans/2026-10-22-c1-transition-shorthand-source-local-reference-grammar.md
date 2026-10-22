# C1 transition shorthand source-local reference grammar implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL:
> Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task.
> This plan does not authorize implementation until owner approval.

**Goal:** Add the bounded, property-scoped transition shorthand production that resolves local duration and timing references through the existing compound pipeline.

**Architecture:** Keep `CompoundCssValue.parse/1` unchanged and add `parse_transition_shorthand/1` as a separate bounded production. Declaration properties and values are normalized using CSS syntactic whitespace only. `CustomCssNormalizer` selects the new production only for an admitted `transition` declaration after the existing parser returns `:no_match`, then sends its occurrences through the current per-provenance resolver batch, reconstruction, CSS safety, and whole-rule atomicity.

**Tech Stack:** Elixir umbrella application, Mix, ExUnit, `CompoundCssValue`, `CustomCssNormalizer`, `SourceLocalCustomPropertyResolver`, and `LiveFrames.Fidelity.CSSDeclaration`.

**Spec:** `docs/development/transition_shorthand_source_local_reference_grammar_authority.md`, with supporting contracts in `docs/development/feature_romeo_required_residual_causal_decomposition.md`, `docs/development/bounded_compound_css_value_authority.md`, and `docs/development/css_local_custom_property_resolution_authority.md`.

## Global Constraints

- Implement C1 only after the owner approves this plan. This plan does not authorize code or test changes.
- Keep the implementation to exactly six files: the existing `CompoundCssValue` and `CustomCssNormalizer` modules and their tests, plus the bounded declaration-whitespace boundary in `CustomCssParser` and its test file. Do not add a module or refactor other compound productions.
- Keep `CompoundCssValue.parse/1` behaviorally unchanged. The new `:transition_shorthand` production is available only through `parse_transition_shorthand/1` and the normalizer's exact-property route.
- Preserve the existing local custom-property definition path and exact direct `var(--name)` path. Direct references continue to win before compound discovery, including on `transition`.
- Keep the existing bare `VAR WS VAR` production property-agnostic and unchanged. C1 scopes only the new IDENT-prefixed production to `property == "transition"`.
- Keep the existing shared `SourceLocalCustomPropertyResolver.resolve/3` pipeline, occurrence correlation, per-provenance batch, owner/provenance reference counter, and 1,024-reference limit. Do not add another resolver, budget, external fallback, or VariableAuthority re-entry.
- Keep resolved transition values on the existing literal `StyleValue` path after reconstruction, validation against the same transition production, `safe_declaration_value("transition", reconstructed, :source_resolver)`, and CSSDeclaration validation.
- Preserve existing whole-selector-rule atomicity and public residual reasons. Do not add a diagnostic or residual reason.
- Do not change `SourceLocalCustomPropertyResolver`, `LiveFrames.Fidelity.CSSDeclaration`, `VariableAuthority`, CSS framing, selectors, at-rule parsing, IR structs or schemas, `NativeGenerator`, componentization, runtime processes, FRAME D, C3A, or C3B. The only `CustomCssParser` change is CSS-syntactic-whitespace-only trimming at declaration property/value boundaries, as defined in Task 3.
- Use generic public fixtures only. Add no private source names, values, selectors, paths, Romeo fixtures, fingerprints, or implementation branches.
- If implementation needs any file or contract outside the six-file boundary, stop and return for authority review.

## Review Focus

1. `parse/1` remains unchanged for IDENT-prefixed input, and the legacy bare `var(--duration) var(--timing)` production retains its current behavior.
2. Property-aware routing admits the new production only for `transition`, after the direct path and existing generic parser have had their current precedence.
3. The grammar has one or two specs, exactly two references per spec, strict ASCII whitespace, an independent strict duration slot, and the existing timing slot.
4. Reconstruction canonicalizes whitespace, preserves property/spec/reference order, and emits no residual `var(`.
5. Declaration-boundary normalization preserves non-ASCII whitespace for grammar and safety validation; NBSP is not silently removed.
6. Transition records use the existing shared per-provenance resolver batch and owner reference budget, with no resolver contract or selection-rule changes.
7. Existing CSS safety, external-authority fail-closed behavior, FRAME D behavior, and whole-rule atomicity remain in force.
8. Every parser and normalizer test uses synthetic public values and generic local names.

---

## Plan gate and verified base

~~~text
PLAN_STATUS=PROPOSED_FOR_REVIEW
C1_IMPLEMENTATION_AUTHORIZED=NO_PENDING_AUTHORITY_MERGE
C1_WHITESPACE_BOUNDARY_CORRECTION_REQUIRED=YES
C1_PRE_NORMALIZATION_NBSP_GAP=CONFIRMED
ROOT_CAUSE=UNICODE_TRIM_BEFORE_C1_GRAMMAR
AUTHORITY_CORRECTION_REQUIRED=YES
EXISTING_TASK1_TASK2_ARCHITECTURE_CHANGED=NO
PLAN_FILE_BOUNDARY_EXPANDED_TO_SIX=YES
PARSER_TEST_FILE_AUTHORIZED=YES
TASK3_BOUNDARY_CORRECTION_DEFINED=YES
CSS_DECLARATION_SYNTACTIC_WHITESPACE=U+0020,U+0009,U+000A,U+000D,U+000C
UNICODE_STRING_TRIM_FOR_C1_DECLARATION_BOUNDARY=FORBIDDEN
NBSP_U+00A0_IS_CSS_SYNTACTIC_WHITESPACE=NO
NBSP_MUST_NOT_BE_ERASED_BEFORE_C1_GRAMMAR_VALIDATION=YES
AUTHORITY_CORRECTION_STATUS=PROPOSED_FOR_REVIEW

BASE_SHA=c6e689353ce4a26263fcbe10bd77c08ba403d115
BASE_TREE=e4e02e9ea15f41cd724e17cd97851361c464cf05
BASE_CI=39819732247
BASE_CI_RESULT=SUCCESS

MAIN_MOVEMENT_RECONCILED=YES
MAIN_MOVEMENT_AFTER_AUTHORITY=PR_293_DOCS_ONLY
C1_MATERIAL_FILES_CHANGED_SINCE_AUTHORITY=NO
C1_BASELINE_REOPEN_REQUIRED=NO
PRIVATE_ROMEO_RERUN_REQUIRED_FOR_PLANNING=NO
~~~

PR #292 merged at `2bdb005d9c1900d4853a2d34d863e84c0bc62853`. One docs-only commit, PR #293, followed it on `main`. A fresh fetch confirmed that none of the C1 parser, normalizer, resolver, CSS safety, or test files changed after the authority merge. The plan uses the current `main` SHA and tree above.

These SHA and tree values record the plan-authoring base only. They are not the permanent implementation base. The implementation must use the fresh `origin/main` selected by the execution preflight below, after this plan PR has merged.

The predicted causal result after implementation and the separate canonical rerun remains a prediction:

~~~text
C1_DIRECT_UNLOCK_PREDICTION=12
REMAINING_REQUIRED_PREDICTION=8
POST_IMPLEMENTATION_CANONICAL_RERUN=REQUIRED
POST_IMPLEMENTATION_EXPECTED_C1_UNLOCK=12
POST_IMPLEMENTATION_EXPECTED_REQUIRED_REMAINDER=8
C1_PRODUCTION_RESOLVER_OUTCOME=MUST_BE_MEASURED_AFTER_IMPLEMENTATION
C1_CANONICAL_ROMEO_RERUN=REQUIRED_AFTER_IMPLEMENTATION
CANONICAL_ROMEO_RERUN_AUTHORIZED_BY_IMPLEMENTATION_PLAN=NO
~~~

Do not encode these counts as tests. The production resolver outcome is a separate implementation acceptance obligation: complete the bounded synthetic production-path proof below without instrumentation. The canonical rerun is a separate post-implementation evidence gate and is not authorized by this plan. Do not access or rerun private source evidence while implementing C1.

## Implementation file boundary

After the authority correction is accepted and merged, the later C1 implementation may touch exactly these six files:

- Modify `apps/live_frames/lib/live_frames/adapters/bricks/compound_css_value.ex`. Add the separate transition parser entry, production identity, duration slot, canonical transition pieces, and resolved-form validation using the existing private `Parsed`, `Occurrence`, and `reconstruct/2` machinery.
- Test `apps/live_frames/test/live_frames/bricks_compound_css_value_test.exs`. Cover the pure grammar, slot checks, bounds, occurrence order, and canonical reconstruction with generic fixtures.
- Modify `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex`. Make private compound routing property-aware and pass admitted transition occurrences through the current shared pipeline.
- Test `apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`. Cover admission, resolver integration, safety, provenance, budget, output, and rule atomicity.
- Modify `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_parser.ex`. At declaration property/value boundaries only, trim CSS syntactic whitespace as defined in Task 3. Preserve framing, selectors, at-rules, and unrelated parser behavior.
- Test `apps/live_frames/test/live_frames/bricks_custom_css_parser_test.exs`. Cover CSS-whitespace boundary normalization and preservation of non-ASCII whitespace.

~~~text
EXPECTED_PRODUCTION_FILES=3
EXPECTED_TEST_FILES=3
EXPECTED_TOTAL_CHANGED_FILES=6
SOURCE_LOCAL_RESOLVER_CHANGED=NO
CSS_DECLARATION_CHANGED=NO
VARIABLE_AUTHORITY_CHANGED=NO
IR_SHAPE_CHANGED=NO
DIAGNOSTIC_SCHEMA_CHANGED=NO
NATIVE_GENERATOR_CHANGED=NO
COMPONENTIZATION_CHANGED=NO
RUNTIME_PROCESS_CHANGED=NO
~~~

## Frozen parser and grammar contract

### Public entry and representation

Keep `CompoundCssValue.parse/1` behaviorally unchanged. Add:

~~~text
CompoundCssValue.parse_transition_shorthand/1
  :: {:ok, Parsed.t()} | :no_match | {:error, :resource_limit_exceeded}
~~~

Unauthorized grammar shapes normally return `:no_match`. Source, token, or reconstructed-size overflow returns the existing `:resource_limit_exceeded` result. Do not add a public parser reason.

Extend only the existing private nested representation:

~~~text
Parsed.production += :transition_shorthand
Occurrence.slot_grammar += :transition_duration_operand
~~~

Transition timing occurrences use the existing `:juxtaposition_right_operand` slot. One spec has occurrence indexes `0 = duration`, `1 = timing`. Two specs have `0 = spec 1 duration`, `1 = spec 1 timing`, `2 = spec 2 duration`, and `3 = spec 2 timing`. Preserve each extracted local name and its case using the existing local-reference mechanism.

The parser must construct fixed transition pieces at parse time so `reconstruct/2` can substitute validated terminal values through its existing machinery. Add the transition clause to resolved-form validation against the same production. Do not duplicate reconstruction or introduce a struct, module, public field, or IR value.

### Source grammar and bounds

Implement exactly:

~~~text
TRANSITION_SHORTHAND := SPEC
                      | SPEC WS? "," WS? SPEC

SPEC := PROPERTY_IDENTIFIER WS DURATION_REF WS TIMING_REF

WS := one or more ASCII whitespace characters from [\x20\t\r\n\f]
WS around a comma := zero or more ASCII whitespace characters from [\x20\t\r\n\f]

PROPERTY_IDENTIFIER := [a-z][a-z0-9]* ( "-" [a-z0-9]+ )*
RESERVED := { inherit, initial, unset, revert, revert-layer, none, all }

DURATION_REF := the existing local-reference span var( WS? --name WS? )
TIMING_REF   := the existing local-reference span var( WS? --name WS? )
~~~

The property identifier is syntax-checked only. Do not resolve it or add a property allowlist. Reject reserved identifiers, duplicate property identifiers in a two-spec value, uppercase letters, escapes, custom-property names, function syntax, additional tokens, and malformed list punctuation. Reject literal source durations and timings, delay tokens, transition-behavior tokens, fallback `var(...)`, non-ASCII whitespace including NBSP, and third or later specs. Do not add a general CSS transition parser or timing-function grammar.

~~~text
MIN_SPECS=1
MAX_SPECS=2
REFERENCES_PER_SPEC=2
MAX_REFERENCES_PER_DECLARATION=4
MAX_SOURCE_BYTES=4096
MAX_TOKENS=32 (transition production uses at most 7)
MAX_RECONSTRUCTED_BYTES=4096
~~~

An over-two-spec value is an unauthorized grammar shape and returns `:no_match`; it is not a resource overflow. A source or output size above its existing bound returns `:resource_limit_exceeded`.

### Terminal slots

Add only the transition-specific duration slot `:transition_duration_operand`. Its lexical contract is:

~~~text
^(\d+(\.\d+)?|\.\d+)(s|ms)\z
~~~

Then require a finite, non-negative numeric value. Accept `0ms`, positive millisecond values, and positive fractional-second values. Reject negative values, explicit plus signs, unitless values, exponent notation, a trailing line feed, and overflow/non-finite values. Do not change `:juxtaposition_left_operand` or its legacy anchoring behavior.

Reuse `:juxtaposition_right_operand` for timing. Do not change or expand its contract: it accepts only the currently approved `ease-in-out` terminal. Other timing keywords and all timing functions fail closed.

### Reconstruction

Emit exactly one canonical structure:

~~~text
PROPERTY SP DURATION SP TIMING
PROPERTY SP DURATION SP TIMING, SP PROPERTY SP DURATION SP TIMING
~~~

Use one ASCII space between each property, terminal, and timing value, and exactly comma plus one space between specs. Do not retain source newline, indentation, or other whitespace runs. Preserve property identifiers, property order, spec order, and reference occurrence order. Revalidate the resolved transition form under `:transition_shorthand`, reject any remaining `var(`, then continue through the existing CSS safety path. Legacy juxtaposition reconstruction remains source-preserving.

## Implementation execution preflight

The values below distinguish the base used to author this plan from the implementation base selected after the plan is approved and merged:

~~~text
PLAN_AUTHORING_BASE=c6e689353ce4a26263fcbe10bd77c08ba403d115
ACCEPTED_C1_IMPLEMENTATION_BASELINE=c6e689353ce4a26263fcbe10bd77c08ba403d115
IMPLEMENTATION_BASE=fresh origin/main at the moment implementation begins
PLAN_PR_MERGE_MUST_BE_IN_IMPLEMENTATION_BASE_ANCESTRY=YES
~~~

After the authority correction PR has been accepted, merged, and its post-merge CI is green, before Task 1 the implementation agent must:

1. Fetch `origin` and record the fresh `origin/main` SHA and tree as `MAIN_SHA` and `MAIN_TREE`.
2. Verify PR #296 and the authority-correction PR are merged. Record both approved heads and merge commits. Verify both merge commits are ancestors of `origin/main`; verify the corrected authority and plan blobs on `origin/main` match the approved correction PR head byte-for-byte.
3. Compare movement from `ACCEPTED_C1_IMPLEMENTATION_BASELINE` to the fresh implementation base, including changed paths and all listed material surfaces. The original plan addition and the exact authority/plan correction are accepted only when their approved blob identities match the merge.
4. Perform at most one bounded reconciliation. If movement is limited to the exact approved authority/plan correction and unrelated work, and no other material C1 surface changed, record it and continue from fresh `origin/main`. If any additional C1 implementation or authority surface changed, or corrected document blobs do not match, stop for owner review. Do not silently rebase architectural assumptions or repeat reconciliation.
5. Create a fresh implementation branch from the verified `origin/main`. Do not continue on or push the existing stopped implementation branch.
6. Reapply the original signed Task 1 and Task 2 commits in order with valid signatures, record the new commit SHAs, and verify the resulting history. Preserve the original commits below as evidence; do not modify or push them.

Original implementation evidence:

~~~text
TASK1_ORIGINAL_COMMIT=f474b524ce3fc1ecc49ab45813124b026264b9d9
TASK2_ORIGINAL_COMMIT=ea194e9c2532cd06c1dff1a5a9882ed9072047fd
EXISTING_IMPLEMENTATION_COMMITS_MODIFIED=NO
EXISTING_IMPLEMENTATION_PUSHED=NO
~~~

The material surfaces are:

~~~text
apps/live_frames/lib/live_frames/adapters/bricks/compound_css_value.ex
apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex
apps/live_frames/lib/live_frames/adapters/bricks/source_local_custom_property_resolver.ex
LiveFrames.Fidelity.CSSDeclaration implementation
relevant custom-CSS parsing
compound residual/error semantics
docs/development/transition_shorthand_source_local_reference_grammar_authority.md
this approved implementation plan
~~~

The expected plan-file addition from PR #296 and the exact authority/plan correction are accepted only after their approved blob checks above. Any other change to a material C1 surface, or a document blob that differs from its approved PR bytes, requires:

~~~text
STOP=C1_IMPLEMENTATION_BASELINE_CHANGED
~~~

## Task 1: bounded transition parser and reconstruction

**Files:**

- Modify `apps/live_frames/lib/live_frames/adapters/bricks/compound_css_value.ex`
- Test `apps/live_frames/test/live_frames/bricks_compound_css_value_test.exs`

**Interfaces:**

~~~text
Consumes:
  CompoundCssValue.parse/1
  CompoundCssValue.reconstruct/2
  existing Parsed representation
  existing Occurrence representation

Produces:
  CompoundCssValue.parse_transition_shorthand/1

  Parsed.production includes:
    :transition_shorthand

  Occurrence.slot_grammar includes:
    :transition_duration_operand

Preserves:
  CompoundCssValue.parse/1 signature and behavior
  CompoundCssValue.reconstruct/2 signature
  all legacy production identities and slot contracts
~~~

- [ ] **Step 1: Add parser tests before production changes.** Add the following named tests. Use generic identifiers such as `opacity`, `transform`, and `unknown-property`, and generic local names such as `--duration`, `--timing`, `--duration-b`, and `--timing-b`.

  - `parses a single transition shorthand spec` checks a property plus duration and timing references yields `:transition_shorthand`.
  - `parses a two-spec transition shorthand` checks two specs and exactly four occurrences.
  - `accepts ASCII whitespace variants in transition shorthand` checks space, tab, carriage return, line feed, and form feed between required tokens, plus zero or more permitted ASCII whitespace characters around the comma.
  - `reconstructs transition specs with canonical comma and space` checks source newlines and indentation become the exact canonical one-space form for one and two specs.
  - `assigns transition occurrence indexes and slot grammars in source order` checks indexes `0..1` for one spec and `0..3` for two specs, duration slots at even indexes, and timing occurrences on `:juxtaposition_right_operand`.
  - `preserves transition property identifiers and local reference case` checks property spelling and extracted local-name spelling/case survive parse and reconstruction.
  - `accepts safe unknown lowercase hyphenated property identifiers` checks syntax-only acceptance without semantic property lookup.
  - `rejects reserved transition property identifiers` covers `inherit`, `initial`, `unset`, `revert`, `revert-layer`, `none`, and `all`.
  - `rejects duplicate transition property identifiers` checks a two-spec list cannot repeat its property identifier.
  - `rejects uppercase transition property identifiers` checks uppercase letters do not match the grammar.
  - `rejects escaped and custom transition property identifiers` checks escapes and `--custom` identifiers fail closed.
  - `rejects a third transition spec` checks more than two specs return `:no_match`.
  - `rejects a transition spec with no duration reference` checks the duration position is required.
  - `rejects a transition spec with no timing reference` checks the timing position is required.
  - `rejects extra transition tokens` checks a fourth token after the timing reference fails closed.
  - `rejects literal transition durations` checks source duration literals are not admitted.
  - `rejects literal transition timings` checks source timing keywords are not admitted.
  - `rejects delay and transition behavior tokens` checks a delay-like fourth token and a transition-behavior token fail closed.
  - `rejects function syntax in transition shorthand` checks arbitrary functions cannot appear as a property identifier or source operand.
  - `rejects malformed transition comma layouts` covers leading, trailing, repeated, missing, and misplaced commas.
  - `rejects transition var fallback syntax` checks `var(--name, fallback)` is not treated as a local reference.
  - `rejects malformed transition var references` checks an unclosed or otherwise malformed local reference fails the full transition grammar.
  - `rejects non-ASCII transition whitespace` checks NBSP does not act as a separator.
  - `accepts zero and positive finite transition duration terminals` checks `0ms`, a positive `ms` terminal, and a positive fractional `s` terminal during reconstruction.
  - `rejects invalid transition duration terminals` checks negative, explicitly positive, unitless, exponent, trailing-line-feed, overflow, and non-finite terminals.
  - `rejects timing terminals outside the existing right-slot contract` checks other keywords and timing functions fail the existing slot.
  - `enforces the transition parser 4096-byte source boundary` pads a syntactically valid generic property identifier so the complete source is exactly 4096 bytes, then checks the first byte beyond it returns `:resource_limit_exceeded`.
  - `canonical transition reconstruction leaves no var reference` checks successful reconstruction contains no `var(`.
  - `keeps parse one unchanged for IDENT-prefixed transition values` checks `parse/1` retains its pre-C1 `:no_match` result for generic IDENT-prefixed fixtures.
  - `keeps the existing bare var juxtaposition production unchanged` checks `parse/1` still parses and reconstructs `var(--duration) var(--timing)` with its existing production and slot behavior.

- [ ] **Step 2: Run the compound parser test file and observe the new tests fail.**

  Run: `mix test apps/live_frames/test/live_frames/bricks_compound_css_value_test.exs`

  Expected: new transition parser and reconstruction assertions fail; existing production tests remain the baseline.

- [ ] **Step 3: Add only the bounded parser entry and required representation clauses.** Implement the frozen grammar, transition production identity, transition duration slot validator, canonical pieces, occurrence ordering, and same-production resolved-form check in the existing module. Reuse the current substitution and terminal-validation machinery. Keep `parse/1`, its existing productions, and legacy juxtaposition slots unchanged.

- [ ] **Step 4: Re-run the compound parser test file.**

  Run: `mix test apps/live_frames/test/live_frames/bricks_compound_css_value_test.exs`

  Expected: all new transition cases and all pre-existing compound cases pass. Unauthorized grammar returns `:no_match`; only bound overflow returns `:resource_limit_exceeded`.

**Task 1 completion gate:**

- The compound parser test file passes.
- No normalizer file has changed yet.
- `parse/1` regression tests pass.
- `git diff --check` passes for Task 1 changes.
- Create one signed Task 1 commit. Do not require full repository CI after Task 1.

## Property-scoped normalizer routing

Keep the current lifecycle and owner responsibility:

~~~text
analyze_local_records
 -> compound discovery
 -> shared reference batches
 -> SourceLocalCustomPropertyResolver.resolve/3
 -> reconstruction
 -> safe_declaration_value("transition", reconstructed, :source_resolver)
 -> existing CSSDeclaration safety
 -> whole-rule atomicity
~~~

The existing `analyze_compound_values/1` already has `{property, value}`. Task 2 changes the current private one-argument helpers to exactly `compound_route(property, value)` and `compound_analysis(property, value)`. No additional routing abstraction or module is authorized.

Freeze the exact private routing algorithm:

~~~text
compound_route(property, value):

1. Trim value using the existing route behavior.
2. Exact direct var reference:
   -> existing direct-reference route.
3. Existing two-dimension value:
   -> compound_analysis(property, trimmed).
4. Existing var-bearing OR calc-bearing compound admission:
   -> compound_analysis(property, trimmed).
5. Otherwise:
   -> :generic.

compound_analysis(property, value):

A. Call CompoundCssValue.parse(value) first.

B. {:ok, parsed}
   -> existing compound success tuple.

C. {:error, reason}
   -> existing compound error tuple.
   -> DO NOT call the transition parser.

D. :no_match AND
   property == "transition" AND
   value contains "var(" case-insensitively
   -> call CompoundCssValue.parse_transition_shorthand(value).

E. Every other :no_match
   -> existing compound :no_match tuple.
~~~

When the transition parser returns `{:ok, parsed}`, use the existing compound success tuple. Map its resource error through the existing compound error tuple. Its `:no_match` stays the existing compound `:no_match` tuple; it does not return to the generic path. Therefore the new parser is not attempted for a non-`transition` property, as recovery from a `parse/1` error, merely because `calc(` was present, or for an ordinary transition literal without `var(`. A grammar failure after compound discovery remains fail-closed.

Do not route by property for the legacy production and do not narrow its existing property-agnostic behavior. Do not change occurrence records, correlation keys, resolver records, resolver result ordering, local selection, provenance, or batch count units. Four transition occurrences per declaration join the same owner/provenance `reference_count`; they do not create another counter or resolver call.

## Task 2: property-scoped normalizer admission

**Files:**

- Modify `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex`
- Test `apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`

**Interfaces:**

~~~text
Consumes:
  CompoundCssValue.parse/1
  CompoundCssValue.parse_transition_shorthand/1
  CompoundCssValue.occurrences/1
  CompoundCssValue.reconstruct/2

Produces private routing:
  compound_route(property, value)
  compound_analysis(property, value)

Preserves:
  compound-analysis result tuple shapes
  reference_id correlation shape
  shared per-provenance resolver batches
  public residual reasons
  literal StyleValue output path
~~~

- [ ] **Step 1: Add transition integration tests before normalizer changes.** Add the following named tests using synthetic public CSS and local definitions.

  - `resolves a one-spec transition shorthand to a literal StyleValue` checks both local references resolve through the shared batch and emit an existing literal style value.
  - `resolves a two-spec transition shorthand with canonical whitespace` checks four references resolve in occurrence order and the emitted value uses the canonical comma and spacing.
  - `keeps transition literals without var on the ordinary generic path` checks a literal transition value does not enter the new parser route.
  - `keeps bare transition var juxtaposition on the existing path` checks legacy `transition: var(--duration) var(--timing)` remains supported.
  - `does not route IDENT-prefixed references on non-transition properties` checks an IDENT plus two references under another property cannot use the new parser.
  - `maps malformed transition shorthand to unresolved_value` covers malformed commas, missing items, extra tokens, malformed references, and fallback syntax through the existing public reason.
  - `keeps a missing transition local definition fail closed` checks one missing reference prevents emission.
  - `does not rescue transition references through external-only authority` checks an external candidate cannot satisfy a missing local definition.
  - `keeps nested local-reference definitions fail closed for transition` checks the existing FRAME D resolver outcome remains unresolved.
  - `preserves existing local resolver selection and scope for transition references` checks existing exact owner/provenance/target selection and ambiguity outcomes without changing resolver rules.
  - `keeps a transition timing-slot mismatch fail closed` checks a resolved terminal outside the existing timing slot returns the existing unresolved reason.
  - `keeps a transition duration-slot mismatch fail closed` checks a resolved terminal outside the strict transition duration contract returns the existing unresolved reason.
  - `keeps an unsafe sibling declaration atomic with a transition declaration` checks an unsafe sibling retains the whole selector rule with no partial transition style.
  - `reconstructs transition values deterministically for multiple target nodes` checks each matched target receives the same ordered literal for identical inputs.
  - `preserves base and responsive provenance for transition resolution` checks transition occurrences use the already selected base or responsive provenance and do not cross those scopes.
  - `shares the owner reference budget across direct and four-reference transition values` uses the existing `wide_tree/1` helper. Four direct local references on the owner plus a four-reference transition declaration targeting 255 children consume exactly 1,024 records and succeed. The 256-child case contributes 1,028 records and fails with the existing `resource_limit_exceeded` reason. All records stay in the same owner/provenance batch.
  - `keeps transition failures within existing public residual reasons` checks malformed grammar and closed resolver failures use `unresolved_value`, and budget overflow uses `resource_limit_exceeded`; no new reason is emitted.

- [ ] **Step 2: Run the normalizer test file and observe the new transition success tests fail.**

  Run: `mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`

  Expected: the new IDENT-prefixed transition cases do not yet resolve. Existing direct, legacy juxtaposition, generic, provenance, safety, and atomicity tests remain the baseline.

- [ ] **Step 3: Make the private route property-aware.** Preserve the frozen route order above. Call the new parser only for exact `transition` declarations that reached existing var-bearing compound admission and whose `parse/1` result is `:no_match`. Keep an existing parse error terminal. Feed accepted occurrences into the current shared reference batches and keep the existing reconstruction, CSS safety, residual mapping, and rule-emission code.

- [ ] **Step 4: Re-run the normalizer test file.**

  Run: `mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`

  Expected: the new transition integration cases and existing normalizer cases pass. Other properties cannot reach the new parser; the direct and legacy paths retain their prior outcomes.

**Task 2 completion gate:**

- Both targeted test files pass.
- Implementation remains within the six-file boundary; only the Task 1/Task 2 subset has changed so far.
- `SourceLocalCustomPropertyResolver` is unchanged.
- `CSSDeclaration` is unchanged.
- No private evidence was accessed.
- `git diff --check` passes.
- Create one signed Task 2 commit.

## Task 3: C1 CSS whitespace boundary correction

~~~text
TASK3=C1_CSS_WHITESPACE_BOUNDARY_CORRECTION
~~~

Task 3 runs on the fresh post-correction implementation branch after the signed Task 1 and Task 2 commits have been reapplied. It does not redesign either task or change the transition grammar, routing order, resolver, or public error semantics.

**Task 3 files:**

- Modify `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_parser.ex` only at declaration property/value normalization and blank-value checks.
- Modify `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex` only at `compound_route(property, value)` trimming.
- Test `apps/live_frames/test/live_frames/bricks_custom_css_parser_test.exs`.
- Test `apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`.

Freeze:

~~~text
CSS_DECLARATION_SYNTACTIC_WHITESPACE=U+0020,U+0009,U+000A,U+000D,U+000C
UNICODE_STRING_TRIM_FOR_C1_DECLARATION_BOUNDARY=FORBIDDEN
NBSP_U+00A0_IS_CSS_SYNTACTIC_WHITESPACE=NO
NBSP_MUST_NOT_BE_ERASED_BEFORE_C1_GRAMMAR_VALIDATION=YES
CSS_WHITESPACE_TRIM_IS_CHARACTER_SET_BASED=YES
STRING_TRIM_2_WITH_MULTI_CHARACTER_ARGUMENT=FORBIDDEN
TRIM_SPACE_ONLY=YES
TRIM_TAB_ONLY=YES
TRIM_CR_ONLY=YES
TRIM_LF_ONLY=YES
TRIM_FF_ONLY=YES
TRIM_MIXED_ASCII_CSS_WHITESPACE_RUN=YES
PRESERVE_NBSP=YES
~~~

- [ ] **Step 1: Add declaration-parser regression tests before production changes.** Use synthetic declarations with no private source material. Cover:

  - Each CSS whitespace character (space, tab, CR, LF, and FF) independently at declaration property and value boundaries retains existing normalization behavior.
  - A mixed boundary run trims any ordering of the five characters. Include a value boundary such as `\t \f\r\n<value>\n \t`; its order differs from `SPACE,TAB,CR,LF,FF` and must trim fully. This case must fail if implemented with `String.trim/2` and the multi-character argument `" \t\r\n\f"`.
  - A leading NBSP before an ordinary property is not stripped into a valid property.
  - A trailing NBSP after an ordinary property is not stripped into a valid property.
  - A leading NBSP in a declaration value remains in the parsed value.
  - A trailing NBSP in a declaration value remains in the parsed value.
  - An NBSP-only value is not classified as ordinary CSS whitespace and remains a non-empty parsed value.

- [ ] **Step 2: Run the parser test file and observe the new boundary tests fail.**

  Run: `mix test apps/live_frames/test/live_frames/bricks_custom_css_parser_test.exs`

  Expected: current Unicode trimming removes NBSP or accepts an NBSP-padded property where the new CSS-whitespace contract requires preservation/rejection.

- [ ] **Step 3: Add the C1 end-to-end regression before production changes.** In `bricks_custom_css_normalizer_test.exs`, prove leading and trailing NBSP around an otherwise valid IDENT-prefixed transition declaration fail closed with the existing `unresolved_value` residual and no emitted transition. Include a control proving ordinary ASCII boundary whitespace still normalizes and resolves through the existing production path.

- [ ] **Step 4: Run the parser and normalizer test files and observe the new regressions fail.**

  Run:

  ~~~sh
  mix test apps/live_frames/test/live_frames/bricks_custom_css_parser_test.exs
  mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs
  ~~~

  Expected: the new NBSP preservation and fail-closed cases fail against current Unicode trimming; existing C1 behavior remains the baseline.

- [ ] **Step 5: Implement the smallest boundary correction.** In `CustomCssParser.parse_declaration_segment/2`, trim leading and trailing runs consisting of any characters in exactly the five CSS syntactic whitespace characters for the property source, returned declaration value, and comment-stripped blank-value check. Keep the three paths on the same contract. In `CustomCssNormalizer.compound_route/2`, use exactly the same character-set boundary trim. The approved mechanism is an anchored bounded ASCII character-class replacement, for example `Regex.replace(~r/\A[\x20\t\r\n\f]+|[\x20\t\r\n\f]+\z/, value, "")`, or an exactly equivalent bounded implementation. `CSS_WHITESPACE_TRIM_IS_CHARACTER_SET_BASED=YES`; `String.trim/2` with a multi-character argument and Unicode `String.trim/1` are forbidden. Mixed runs must trim in any order; NBSP and other non-ASCII whitespace remain untouched. A private helper inside an already-authorized module is allowed only to encapsulate this exact operation, with no routing or grammar abstraction. Do not replace other trim call sites, change framing/selectors/at-rules, add C1-specific parsing to `CustomCssParser`, or add a helper module.

- [ ] **Step 6: Re-run both targeted test files.**

  Run:

  ~~~sh
  mix test apps/live_frames/test/live_frames/bricks_custom_css_parser_test.exs
  mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs
  ~~~

  Expected: ASCII CSS whitespace retains existing normalization; NBSP is preserved for C1 validation, is rejected in property syntax, and fails closed at transition boundaries.

**Task 3 completion gate:**

- Both targeted parser and normalizer test files pass.
- Task 3 changes are limited to its four listed files.
- The combined implementation differs from its verified base in exactly the six authorized files.
- `compound_route(property, value)` routing order and property scope are unchanged.
- Resolver behavior, `CSSDeclaration`, residual reasons, and IR shapes are unchanged.
- `git diff --check` passes.
- Create one signed Task 3 commit.

## Bounded production resolver acceptance

Complete this step after Task 3 and before the full repository gates. Use the ordinary synthetic normalizer integration tests already planned; add no implementation file, production instrumentation, logging, mock, counter, or separate resolver. Prove required occurrence participation from parser cardinality plus successful and negative production-path outcomes. Do not claim direct observation of internal resolver result counts unless an existing test-visible interface exposes them. In particular, timing references must use distinct local names but may resolve only to the one authorized successful terminal, `ease-in-out`.

### One-spec proof

Use distinct local names for duration and timing, a distinct valid duration terminal such as `250ms`, and `ease-in-out` as the timing terminal. Assert parser occurrence cardinality and slots, then exercise the ordinary normalizer path:

~~~text
parser occurrences=2
duration occurrence slot=:transition_duration_operand
timing occurrence slot=:juxtaposition_right_operand

successful normalizer result contains:
  chosen duration terminal
  ease-in-out

no var( remains
literal StyleValue emitted
~~~

Run independent negative controls for a missing duration definition, an invalid duration terminal, a missing timing definition, and an invalid timing terminal. Each must produce the existing `unresolved_value` result. The positive output plus these controls proves both references are required without widening either terminal contract.

### Two-spec proof

Use four distinct local reference names and two distinct valid duration terminals. Both timing definitions resolve to `ease-in-out`:

~~~text
--duration-a
--timing-a
--duration-b
--timing-b
~~~

Assert the parser yields four occurrences in this exact correlation order:

~~~text
occurrence 0 = duration-a
occurrence 1 = timing-a
occurrence 2 = duration-b
occurrence 3 = timing-b
~~~

The ordinary normalizer path must emit a literal containing duration A, `ease-in-out`, duration B, and `ease-in-out` in canonical spec order, with no residual `var(`. Run independent negative controls showing that a missing or invalid `timing-a` makes the whole declaration `unresolved_value`; do the same for `timing-b`. Also make either duration occurrence missing or invalid and require fail-closed `unresolved_value`. This establishes that all four references are required while both timing slots retain the single approved terminal.

~~~text
PUBLIC_SYNTHETIC_PRODUCTION_RESOLVER_PROOF=PASS

ONE_SPEC_TRANSITION:
  produced_occurrences=2
  required_occurrences_proven=2
  emitted_literal=YES

TWO_SPEC_TRANSITION:
  produced_occurrences=4
  required_occurrences_proven=4
  emitted_literal=YES

TIMING_TERMINAL_DISTINCT_VALUES_REQUIRED=NO
TIMING_REFERENCE_NAMES_DISTINCT=YES
TIMING_OCCURRENCE_NEGATIVE_CONTROLS=PASS

RESOLVER_CALL_MODEL=EXISTING_SHARED_PER_PROVENANCE_BATCH
SECOND_RESOLVER=NO
PRIVATE_SOURCE_USED=NO
~~~

This is a bounded implementation acceptance measurement, separate from the later canonical Romeo evidence gate. Do not encode private aggregate counts in tests. The plan does not authorize the canonical rerun:

~~~text
C1_CANONICAL_ROMEO_RERUN=REQUIRED_AFTER_IMPLEMENTATION
CANONICAL_ROMEO_RERUN_AUTHORIZED_BY_IMPLEMENTATION_PLAN=NO
~~~

## Resolver, safety, and failure invariants

The implementation does not modify:

~~~text
apps/live_frames/lib/live_frames/adapters/bricks/source_local_custom_property_resolver.ex
LiveFrames.Fidelity.CSSDeclaration
~~~

Freeze these contracts:

~~~text
RESOLVER_INTERFACE_CHANGED=NO
RESOLVER_SELECTION_RULES_CHANGED=NO
RESOLVER_ANCESTRY_CHANGED=NO
RESOLVER_SCOPE_CHANGED=NO
FRAME_D_POLICY_CHANGED=NO
TRANSITION_AWARE_RESOLVER=NO
SECOND_RESOLVER=NO
VARIABLE_AUTHORITY_REENTRY=NO
EXTERNAL_TOKEN_FALLBACK=NO
CSS_DECLARATION_CHANGED=NO
CSS_SAFETY_BYPASS=NO
GENERIC_UNSAFE_FRAGMENT_PROTECTION=UNCHANGED
NEW_IR_SHAPE=NO
NEW_RESIDUAL_REASON=NO
~~~

Transition references are ordinary new occurrences entering the existing per-provenance batch. A missing local definition, external-authority-only name, cross-owner reference, unsupported scope, ambiguous selection, nested local definition, timing mismatch, duration mismatch, or residual `var()` fails closed with existing public reason semantics. Resource overflow uses the existing `resource_limit_exceeded` path. The reconstructed value still passes `safe_declaration_value("transition", reconstructed, :source_resolver)` and the current CSSDeclaration safety check. Any unsafe sibling still makes the entire selector rule residual.

## Existing behavior that must not drift

Keep regression coverage for:

- `CompoundCssValue.parse/1` and the existing linear-gradient, calc, two-dimension, and legacy `VAR WS VAR` productions.
- Direct local-reference handling and generic non-compound declarations.
- Existing parser and resolver resource-limit mapping.
- Whole-rule atomicity, external-authority fail-closed behavior, FRAME D fail-closed behavior, and the shared 1,024-reference budget.
- Source-local resolver selection, owner/provenance scope, responsive/base provenance, and output as existing literal `StyleValue` values.

Do not alter existing production clauses or test expectations unrelated to the new route. The plan adds no generalized CSS shorthand support and no abstraction beyond the private property-aware routing needed for C1.

## Performance and scaling

This remains static conversion work at cold build time. Parse each declaration in `O(value_bytes)` with bounded specs and references. Use the existing shared resolver batch once per provenance; do not call the resolver per occurrence or add a second budget.

~~~text
DATA_LAYER=COLD_BUILD_TIME
RUNTIME_REDIS=NOT_REQUIRED
RUNTIME_POSTGRES=NOT_REQUIRED
RUNTIME_CACHEX=NOT_REQUIRED
RUNTIME_GENSERVER=NOT_REQUIRED
RUNTIME_PUBSUB=NOT_REQUIRED
RUNTIME_OBAN=NOT_REQUIRED
RUNTIME_PGBOUNCER=NOT_REQUIRED
RUNTIME_READ_REPLICA=NOT_REQUIRED

TARGET_COMPLEXITY=O(value_bytes)
MAX_SOURCE_BYTES=4096
MAX_TRANSITION_SPECS=2
MAX_TRANSITION_REFERENCES=4
EXISTING_OWNER_REFERENCE_BUDGET=1024
~~~

Do not use unbounded or backtracking-heavy patterns, repeatedly parse per target, add recursion, or make repeated resolver calls.

## Security review

The tests and review must keep all of these failure modes fail-closed through existing public semantics. Grammar, slot, and closed local-resolution failures use `unresolved_value`; resource overflow uses `resource_limit_exceeded`; CSS safety failures retain the existing `unsafe_declaration` mapping.

| Input or condition | Required guard and outcome |
| --- | --- |
| `url()`, `expression()`, `javascript:`, `behavior:`, or `-moz-binding` | Grammar and slot checks reject unsupported transition terminals; existing CSS safety still runs on every reconstruction and rejects unsafe sibling or other unsafe declarations as `unsafe_declaration`. Whole-rule atomicity remains in force. |
| Malformed `var()` or a fallback `var(...)` | Transition grammar returns `:no_match`; the admitted declaration maps to `unresolved_value`. |
| Residual `var()` after reconstruction | Same-production resolved-form validation rejects it as `unresolved_value`. |
| Oversized source or reconstructed value | Existing byte bound maps to `resource_limit_exceeded`. |
| Malformed comma list or more than two specs | Bounded grammar returns `:no_match`; no partial spec is emitted. |
| Arbitrary function or transition timing function | Grammar or existing timing slot rejects it as `unresolved_value`. |
| CSS-wide keyword used as property identifier | Reserved-identifier check returns `:no_match`. |
| Custom-property property identifier | Identifier grammar returns `:no_match`. |
| External-authority-only name or local/external collision | Existing source-local resolver fails closed; no external fallback or VariableAuthority re-entry. |
| Cross-owner resolution attempt | Existing owner boundary fails closed. |
| Nested local-reference definition / FRAME D | Existing depth contract fails closed; C1 does not add nested expansion. |
| Unsafe sibling declaration | Existing whole-selector-rule atomicity prevents partial style emission. |

Do not add a transition safety bypass or make raw declaration text a diagnostic value in the new parser path.

## Verification commands for the later implementation PR

Run the targeted test files during the red/green steps:

~~~sh
mix test apps/live_frames/test/live_frames/bricks_custom_css_parser_test.exs
mix test apps/live_frames/test/live_frames/bricks_compound_css_value_test.exs
mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs
~~~

Before the later implementation PR is ready for review, run the repository gates that mirror CI:

~~~sh
mix format --check-formatted
mix compile --warnings-as-errors
mix assets.build
git diff --exit-code -- \
  apps/live_frames/assets/css/theme/lf_theme.css \
  apps/live_frames/priv/static/live_frames/css/live_frames.css
mix test
mix deps.unlock --check-unused
git diff --check
~~~

No implementation test may depend on private source material. The authority-correction PR changes only the authority and plan documents, so it requires `git diff --check` and exact-head CI; local Mix tests are not required for that docs-only PR.

Before later implementation tests, run `mix deps.get` if dependencies are missing or stale in the isolated checkout. This is dependency setup. The final gate list above remains the exact CI-mirroring verification set.

## Implementation PR handoff

After the final CI-mirroring commands pass, prepare the implementation PR with these requirements:

~~~text
IMPLEMENTATION_PR_REQUIREMENTS:

- implementation branch starts from verified implementation base
- exactly the six authorized implementation/test files differ
- all implementation commits are signed
- targeted tests pass
- full repository gates pass
- open PR
- exact-head push CI SUCCESS
- exact-head PR CI SUCCESS
- leave PR open and unmerged
- do NOT run the private canonical Romeo rerun as part of implementation
  unless separately authorized
~~~

Keep the signed Task 1 and Task 2 commit boundaries in history. Signed history from the implementation base through the final PR head must verify. Do not squash away the task boundary before final review unless separately authorized.

Required implementation report:

~~~text
IMPLEMENTATION_BASE_SHA=
IMPLEMENTATION_BASE_TREE=
PLAN_MERGE_IN_ANCESTRY=

TASK1_COMMIT=
TASK2_COMMIT=
TASK3_COMMIT=
SIGNED_HISTORY=

CHANGED_FILES=
EXPECTED_PRODUCTION_FILES=3
EXPECTED_TEST_FILES=3
EXPECTED_TOTAL_CHANGED_FILES=6

PARSE_1_UNCHANGED=
LEGACY_JUXTAPOSITION_UNCHANGED=
PROPERTY_SCOPED_TRANSITION_ROUTE=
TRANSITION_DURATION_SLOT_SEPARATE=
TIMING_SLOT_REUSED=

PUBLIC_SYNTHETIC_PRODUCTION_RESOLVER_PROOF=
ONE_SPEC_OCCURRENCES=
ONE_SPEC_REQUIRED_OCCURRENCES_PROVEN=
TWO_SPEC_OCCURRENCES=
TWO_SPEC_REQUIRED_OCCURRENCES_PROVEN=
TIMING_OCCURRENCE_NEGATIVE_CONTROLS=

SHARED_RESOLVER_BATCH_REUSED=
SHARED_REFERENCE_BUDGET_REUSED=
SOURCE_LOCAL_RESOLVER_CHANGED=NO
CSS_DECLARATION_CHANGED=NO
EXTERNAL_FALLBACK=NO

TARGETED_TESTS=
FULL_TEST_SUITE=
FORMAT=
COMPILE_WARNINGS_AS_ERRORS=
ASSETS_BUILD=
STYLING_DRIFT=
UNUSED_DEPS=
DIFF_CHECK=

PR_URL=
PR_HEAD=
PUSH_CI=
PR_CI=
MERGED=NO

PRIVATE_SOURCE_ACCESSED=NO
CANONICAL_ROMEO_RERUN_PERFORMED=NO

STOP=
~~~

## Plan self-review

Before any later implementation starts, verify each item against the three tasks above:

~~~text
AUTHORITY_REQUIREMENTS_COVERED=YES
GENERIC_PARSE_1_UNCHANGED=YES
PROPERTY_SCOPE_EXPLICIT=YES
NEW_DURATION_SLOT_EXPLICIT=YES
TIMING_SLOT_REUSE_EXPLICIT=YES
CANONICAL_RECONSTRUCTION_EXPLICIT=YES
REFERENCE_BUDGET_REUSE_EXPLICIT=YES
RESOLVER_UNCHANGED=YES
CSS_DECLARATION_UNCHANGED=YES
EXTERNAL_FALLBACK=NO
FRAME_D_IMPLEMENTATION=NO
C3A_IMPLEMENTATION=NO
C3B_IMPLEMENTATION=NO
PRIVATE_SOURCE_DEPENDENCY=NO
IMPLEMENTATION_EXECUTION_PREFLIGHT_EXPLICIT=YES
NORMALIZER_PRIVATE_SIGNATURES_FROZEN=YES
TASK_INTERFACES_EXPLICIT=YES
SIGNED_TASK_COMMIT_BOUNDARIES_EXPLICIT=YES
DECLARATION_WHITESPACE_CONTRACT_EXPLICIT=YES
PARSER_BOUNDARY_TESTS_AUTHORIZED=YES
TASK3_BOUNDARY_CORRECTION_DEFINED=YES
EXACT_SIX_FILE_BOUNDARY=YES
PRODUCTION_RESOLVER_ACCEPTANCE_EXPLICIT=YES
IMPLEMENTATION_STOP_CONDITIONS_EXPLICIT=YES
IMPLEMENTATION_PR_HANDOFF_EXPLICIT=YES
~~~

Review the plan for extra abstractions. If an implementation proposal requires generic parser broadening, a second resolver, resolver contract changes, CSSDeclaration changes, external-authority fallback, a new IR shape, a new residual reason, FRAME D, C3A, C3B, private source material, a raw-source reparse, or any file outside the six-file implementation boundary, stop and return for authority review.

## Implementation STOP conditions

Stop implementation immediately if any of these conditions occurs:

~~~text
STOP=C1_IMPLEMENTATION_BASELINE_CHANGED
STOP=PLAN_MERGE_NOT_IN_BASE_ANCESTRY
STOP=GENERIC_PARSE_1_CHANGE_REQUIRED
STOP=NEW_MODULE_REQUIRED
STOP=SECOND_RESOLVER_REQUIRED
STOP=RESOLVER_INTERFACE_CHANGE_REQUIRED
STOP=RESOLVER_SELECTION_CHANGE_REQUIRED
STOP=CSS_DECLARATION_CHANGE_REQUIRED
STOP=VARIABLE_AUTHORITY_REENTRY_REQUIRED
STOP=EXTERNAL_AUTHORITY_FALLBACK_REQUIRED
STOP=NEW_IR_SHAPE_REQUIRED
STOP=NEW_RESIDUAL_REASON_REQUIRED
STOP=FRAME_D_REQUIRED
STOP=C3A_OR_C3B_REQUIRED
STOP=PRIVATE_SOURCE_REQUIRED
STOP=PRIVATE_SOURCE_LEAK
STOP=IMPLEMENTATION_SCOPE_EXCEEDED
STOP=IMPLEMENTATION_BASELINE_CHANGED
STOP=MORE_THAN_SIX_FILES_REQUIRED
STOP=C1_ROUTING_ORDER_CHANGE_REQUIRED
STOP=GENERIC_PARSE_1_CHANGE_REQUIRED
STOP=RESOLVER_CHANGE_REQUIRED
STOP=IR_CHANGE_REQUIRED
STOP=GLOBAL_CUSTOM_CSS_TRIM_REWRITE_REQUIRED
STOP=RAW_SOURCE_REPARSING_REQUIRED
STOP=TARGETED_TEST_FAILURE
STOP=FULL_GATE_FAILURE
STOP=UNSIGNED_HISTORY
~~~

Do not spend more than one reconciliation cycle on moving `main`.

## Authority-correction STOP conditions

Stop the docs-only correction if any of these conditions occurs:

~~~text
STOP=MAIN_MOVED_MATERIALLY
STOP=AUTHORITY_CORRECTION_REQUIRES_NEW_ARCHITECTURE
STOP=NEW_MODULE_REQUIRED
STOP=RAW_SOURCE_REPARSING_REQUIRED
STOP=IR_CHANGE_REQUIRED
STOP=RESOLVER_CHANGE_REQUIRED
STOP=CSS_DECLARATION_CHANGE_REQUIRED
STOP=GLOBAL_CUSTOM_CSS_TRIM_REWRITE_REQUIRED
STOP=NEW_RESIDUAL_REASON_REQUIRED
STOP=PRIVATE_SOURCE_REQUIRED
STOP=PRIVATE_SOURCE_LEAK
STOP=DOCS_PR_CONTAINS_CODE
STOP=UNSIGNED_HISTORY
STOP=CI_FAILURE
~~~

## Pull request gate

The authority-correction PR must contain only these two documents, run exact-head push and PR CI, and remain open and unmerged:

- `docs/development/transition_shorthand_source_local_reference_grammar_authority.md`
- `docs/superpowers/plans/2026-10-22-c1-transition-shorthand-source-local-reference-grammar.md`

This docs-only PR does not authorize C1 implementation. Implementation may begin only after the correction is accepted, merged, and post-merge CI is green, followed by the fresh-main preflight above.

~~~text
PLAN_PR_SIGNED_HISTORY_REQUIRED=YES
PLAN_PR_UNSIGNED_COMMITS_ALLOWED=NO
PLAN_STATUS=PROPOSED_FOR_REVIEW
C1_IMPLEMENTATION_AUTHORIZED=NO_PENDING_AUTHORITY_MERGE
FRAME_D_IMPLEMENTATION_AUTHORIZED=NO
C3A_IMPLEMENTATION_AUTHORIZED=NO
C3B_IMPLEMENTATION_AUTHORIZED=NO
PRIVATE_SOURCE_ACCESSED=NO
PRIVATE_SOURCE_LEAK=NO
~~~

Every commit in the plan PR must be validly signed, and signed history from the PR base through the approved head must verify. Review corrections may be separate signed commits. Do not squash or rewrite history merely to force the PR into one commit. Approval of this plan is separate from authorization to implement C1.

Required docs-correction report:

~~~text
BASE_SHA=
BASE_TREE=
CURRENT_MAIN_CI=

ROOT_CAUSE_CONFIRMED=
CUSTOM_CSS_PARSER_UNICODE_TRIM_CONFIRMED=
CUSTOM_CSS_NORMALIZER_UNICODE_TRIM_CONFIRMED=

AUTHORITY_WHITESPACE_CONTRACT_CORRECTED=
PLAN_FILE_BOUNDARY_EXPANDED_TO_SIX=
PARSER_TEST_FILE_AUTHORIZED=
TASK3_BOUNDARY_CORRECTION_DEFINED=

TASK1_ORIGINAL_COMMIT=f474b524ce3fc1ecc49ab45813124b026264b9d9
TASK2_ORIGINAL_COMMIT=ea194e9c2532cd06c1dff1a5a9882ed9072047fd
EXISTING_IMPLEMENTATION_COMMITS_MODIFIED=NO
EXISTING_IMPLEMENTATION_PUSHED=NO

CHANGED_FILES=
SIGNED_HISTORY=
PR_URL=
PR_HEAD=
PUSH_CI=
PR_CI=
MERGED=NO

C1_IMPLEMENTATION_AUTHORIZED=NO_PENDING_AUTHORITY_MERGE
STOP=
~~~
