# C2 FRAME D Bounded Nested Local Resolution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the existing source-local resolver to accept one exact `var(B)` passthrough in a selected local definition while keeping all other nested forms fail-closed.

**Architecture:** Extend `LiveFrames.Adapters.Bricks.SourceLocalCustomPropertyResolver` only. Reuse its selected-definition index, dependency graph, cycle detection, path tries, nearest-ancestor lookup, and resource bounds. Precompute one outcome per selected base definition and let consumer references read that outcome without walking the dependency graph.

**Tech Stack:** Elixir, ExUnit, LiveFrames Bricks adapter

**Spec:** `docs/development/frame_d_bounded_nested_local_resolution_authority.md`

## Plan gate and verified base

~~~text
PLAN_STATUS=PROPOSED_FOR_REVIEW
C2_IMPLEMENTATION_AUTHORIZED=NO
C2_IMPLEMENTATION_PLAN_ACCEPTED=NO
PRIVATE_ROMEO_SOURCE_ACCESS=FORBIDDEN

BASE_SHA=5a4c48f3a283f8720ef33fe6292f55cbc0083ea7
BASE_TREE=ea927f30931cd6be8dd8c8024e9ac9cb2eb31c6b
C2_AUTHORITY_MERGE_SHA=3889309b9b1273a05df53d6f2f195513edf1387b
C2_AUTHORITY_MERGE_IN_BASE_ANCESTRY=YES
~~~

This plan does not authorize implementation or code changes until it is independently reviewed, merged, and followed by an explicit implementation authorization. Implementation must use the fresh `origin/main` head after this plan PR merges.

## Global Constraints

- The accepted authority does not authorize implementation. This plan only defines work for a later implementation authorization.
- Use source-neutral synthetic records and frames. `PRIVATE_ROMEO_SOURCE_ACCESS=FORBIDDEN`.
- The only production file is `apps/live_frames/lib/live_frames/adapters/bricks/source_local_custom_property_resolver.ex`. The only test files are the resolver test and `CustomCssNormalizer` test listed below.
- Do not change `CustomCssNormalizer` production code, `CompoundCssValue`, `CustomCssParser`, `CSSDeclaration`, `VariableAuthority`, Design IR, style precedence, `NativeGenerator`, runtime code, dependencies, or assets.
- Keep the selected architecture and bounds fixed:

  ```text
  SELECTED_C2_ARCHITECTURE=OPTION_A_EXISTING_RESOLVER_ONE_HOP_PASSTHROUGH
  PRODUCTION_OWNER=LiveFrames.Adapters.Bricks.SourceLocalCustomPropertyResolver
  MAX_NESTED_LOCAL_PASSTHROUGH_HOPS=1
  MAX_LOCAL_SUBSTITUTION_DEPTH=2
  GENERAL_RECURSION=NO
  SECOND_RESOLVER=NO
  VARIABLE_AUTHORITY_FALLBACK=NO
  NORMALIZER_PRODUCTION_CHANGE=NO
  COMPOUND_PRODUCTION_CHANGE=NO
  NORMALIZER_OWNS_NESTED_RESOLUTION=NO
  DEPENDENCY_SELECTION_SCOPE=BASE_ONLY
  ```

- Accept only `consumer -> var(A)`, `A -> exact var(B)`, `B -> terminal`. Reject `A -> B -> C`. Do not add configurable depth or a recursive CSS substitution engine.
- Preserve owner and exact effective-provenance checks, base-only dependency selection, external collision checks, deterministic selector choice, terminal safety, and all current resource limits.
- Preserve generic P1 behavior. Do not branch on component ID, source ID, owner ID, residual fingerprint, CSS property, private name, private selector, or requirement classification.
- Do not use private source evidence to choose names, fixtures, values, selectors, or outcomes. Do not predict a post-C2 unknown count.

## Review Focus

- `dependency_outcomes` is computed once for each selected base definition during index construction. No consumer reference starts a graph walk.
- A successful outcome contains either the definition's own terminal or the terminal from one exact passthrough. A passthrough can consume only a dependency outcome tagged as an ordinary terminal. This makes `A -> B -> C` fail with `:unsupported_nested_reference` even if B has its own independently valid one-hop outcome.
- The existing `find_dependency_definition/3` selects B at A's path or its nearest accepted ancestor. `farther_ancestor_exists_in_scope?/3` distinguishes an eligible base B beyond the 64-hop cap without scanning past the cap. These helpers use opposite path orientations; the plan freezes the correct pairing in **Frozen path orientation**.
- Missing, foreign-provenance, sibling-only, responsive-only, and state-scoped **nested B** records map to `:no_local_definition`. Responsive and state records are not scanned to manufacture a different C2 B failure. Existing **consumer/root-reference** scope behavior remains frozen separately in Task 2.
- `CustomCssNormalizer` production remains unchanged. The resolver result follows its existing consumer-specific declaration safety and whole-rule residual path.

## File map

Implementation may change exactly these files:

- `apps/live_frames/lib/live_frames/adapters/bricks/source_local_custom_property_resolver.ex`: exact passthrough compiler-input classifier and bounded per-definition dependency outcomes.
- `apps/live_frames/test/live_frames/bricks_source_local_custom_property_resolver_test.exs`: classifier, batch outcome, failure, path, ownership, provenance, cycle, and resource-bound tests.
- `apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`: source-neutral integration and regression tests only. Production `CustomCssNormalizer` remains unchanged.

The plan itself changes only `docs/superpowers/plans/2026-10-23-c2-frame-d-bounded-nested-local-resolution.md`.

## Frozen internal interfaces

Keep the public resolver contract unchanged:

```elixir
resolve(definition_records, reference_records, opts)
definition_compiler_input_state(local_name, terminal_text, opts)
```

Add this private classifier in the resolver:

```elixir
exact_passthrough_name(terminal_text) ::
  {:ok, local_name} | :no_match
```

It recognizes the entire byte string as the **literal** production `CSS_WS* "var(" CSS_WS* LOCAL_NAME CSS_WS* ")" CSS_WS*`. Use the existing `css_whitespace?/1` byte predicate, which already matches SPACE, TAB, LF, CR, and FF. The function name token is case-sensitive lowercase `var` only. Do not use `String.trim/1` for this grammar and do not add another local-name rule.

Return `{:ok, local_name}` only when the captured candidate passes the existing `valid_local_name?/1` boundary. Any other captured candidate returns `:no_match`. The classifier determines **admission only**; it does not reclassify failures.

Preserve existing compiler-input failure boundaries:

```text
INVALID_DEFINITION_LOCAL_NAME_ARGUMENT=invalid_local_name
INVALID_CAPTURED_DEPENDENCY_NAME=unsupported_nested_reference
```

`definition_compiler_input_state/3` still rejects an invalid **definition** `local_name` argument with `:invalid_local_name` before terminal analysis. When `exact_passthrough_name/1` returns `:no_match` but `dependency_calls/2` found a dependency (including an invalid captured name converted to `nil` in the scanner list), retain the established `:unsupported_nested_reference` outcome. Do not introduce a new failure atom and do not map malformed `var(...)` syntax to `:invalid_local_name`.

Keep the existing `dependency_calls/2` scanner unchanged for edge accounting, fallback detection, direct-self detection, CSS escape decoding, and ASCII case-folding of function identifiers during **discovery**. C2 admission must not inherit that broader scanner grammar:

```text
DEPENDENCY_DISCOVERY_GRAMMAR_BROADENED=NO
C2_ADMISSION_USES_LITERAL_PRODUCTION=YES
EXISTING_SCANNER_BEHAVIOR_CHANGED=NO
LITERAL_VAR_CASE_SENSITIVE=YES
ESCAPED_VAR_ADMITTED=NO
ESCAPED_LOCAL_NAME_ADMITTED=NO
```

The guard admits the exact literal syntax only; it does not look up B or resolve a value.

Replace the private `build_dependency_states/1` result with:

```elixir
build_dependency_outcomes(selected_by_path_scope, tries_by_name, external_collisions)
```

Replace the definition index field `:dependency_states` with `:dependency_outcomes` in `do_build_definition_index/4` and update `resolve_target/3` / `resolve_scope_selection/4` to read the new field. Key outcomes by `{local_name, reversed_target_path, {:base, nil}}`. Use exactly these values:

```text
{:terminal, terminal_text}
  selected definition is dependency-free and terminal

{:passthrough, terminal_text}
  selected definition is an exact passthrough and B is an ordinary terminal

{:error, existing_failure_atom}
  preserve the existing closed failure taxonomy
```

Include one outcome for each successfully selected base definition. Existing candidate-selection errors from `select_definition/2` remain in `selected_by_path_scope` and continue to return before outcome lookup. `resolve_scope_selection/4` reads `:dependency_outcomes` and returns the terminal carried by either success tag.

`build_dependency_outcomes/3` must reuse `collect_dependency_data/1`, `dependency_cycle_members/1`, `find_dependency_definition/3`, and `farther_ancestor_exists_in_scope?/3`. Compute in two bounded passes: classify each selected base definition's own syntax and cycle state, then resolve each exact passthrough outcome once against the already classified outcome at B's selected base path. A B tagged `{:passthrough, _}` is not terminal for A and makes A `{:error, :unsupported_nested_reference}`. Propagate B's existing failure atom when B fails. Do not add another ancestry helper or call this work from `resolve_reference/4`.

```text
DEPENDENCY_OUTCOME_COMPUTED_PER_DEFINITION=YES
DEPENDENCY_GRAPH_WALK_PER_REFERENCE=NO
NO_PROCESS_STATE_OR_CACHE=YES
```

### Frozen path orientation

Outcome keys, `find_dependency_definition/3`, and A's selected definition path use the **reversed** target path representation already stored in the index.

```text
A_SELECTED_PATH_INTERNAL=reversed_path

DEPENDENCY_LOOKUP_PATH=reversed_path
B_BOUNDED_LOOKUP=find_dependency_definition(base_definitions, b_name, reversed_path)

FARTHER_ANCESTOR_TRIE_PATH=Enum.reverse(reversed_path)
B_BEYOND_64_TRIE_PROBE=
  farther_ancestor_exists_in_scope?(tries_by_name[b_name], Enum.reverse(reversed_path), {:base, nil})
```

`tries_by_name` is built from forward `target_path` values on definition records. `farther_ancestor_exists_in_scope?/3` walks that forward path trie. Never pass `reversed_path` to the trie probe. Do not add another ancestry algorithm.

## Task 1: Admit only the exact passthrough compiler input

**Files:**

- Modify `apps/live_frames/lib/live_frames/adapters/bricks/source_local_custom_property_resolver.ex`.
- Test `apps/live_frames/test/live_frames/bricks_source_local_custom_property_resolver_test.exs`.

- [ ] **Step 1: Write focused classifier tests.** Add these named tests:

  - `"admits only an exact single-var passthrough compiler input"`: for local name `"--a"`, `"var(--b)"` returns `:ok`; `"12px"`, `"0.5"`, and `"auto"` remain `:ok`; `"var(--b, 4px)"` returns `{:error, :unsupported_fallback}`; `"var(--local-name)"` for local name `"--local-name"` returns `{:error, :self_reference}`.
  - `"uses only the five CSS whitespace bytes in passthrough syntax"`: each of SPACE, TAB, LF, CR, and FF is accepted before `var(`, after `(`, after the name, and after `)`; a mixed run in those positions is accepted. NBSP in any position returns `{:error, :unsupported_nested_reference}`.
  - `"rejects non-exact passthrough compiler inputs"`: the following remain fail-closed with the existing `:unsupported_nested_reference` compiler-input outcome (not C2 admission): CSS comments; a prefix token; a suffix token; `calc(var(--b))`; two `var()` calls; case-altered function spellings `VAR(--b)` and `VaR(--b)`; escaped `var` spellings such as `v\\61 r(--b)`; escaped local names inside the argument such as `var(--escaped\\2dname)`; NBSP (U+00A0) in any syntactic-whitespace position.
  - `"preserves compiler-input name and byte boundaries"`: an invalid **definition** `local_name` argument returns `{:error, :invalid_local_name}`; `var(color)` and other terminals whose captured dependency is not a valid local name return `{:error, :unsupported_nested_reference}`; a dependency-free 4,096-byte value is accepted; 4,097 bytes returns `{:error, :resource_limit_exceeded}`.

- [ ] **Step 2: Run the focused resolver test and prove RED.**

  Run: `mix test apps/live_frames/test/live_frames/bricks_source_local_custom_property_resolver_test.exs`

  Expected: the new exact-passthrough assertion fails because `definition_compiler_input_state/3` currently classifies `var(--b)` as `:unsupported_nested_reference` when called for a different local name. Existing dependency-free, fallback, self-reference, invalid-name, and byte-boundary assertions remain as characterization checks.

- [ ] **Step 3: Implement the minimal guard extension.** Add `exact_passthrough_name/1` returning only `{:ok, valid_local_name}` or `:no_match`; extend `isolated_definition_compiler_input_failure/3` on main to accept `terminal_text` and admit only when `exact_passthrough_name/1` is `{:ok, captured}` and `dependency_calls/2` reports exactly `[captured]` with no fallback. When admission is `:no_match` but dependencies were discovered, preserve the existing `:unsupported_nested_reference` path. Preserve direct-self, invalid definition name, and fallback precedence. Keep the 4,096-byte check before scanning. Do not change `dependency_calls/2` discovery behavior.

- [ ] **Step 4: Run the focused resolver test and prove GREEN.**

  Run: `mix test apps/live_frames/test/live_frames/bricks_source_local_custom_property_resolver_test.exs`

  Expected: all classifier tests pass. A call to the isolated guard with `var(--b)` returns `:ok` without any definition records or B lookup, proving the guard does not resolve a graph.

- [ ] **Step 5: Run focused regression checks.** Re-run the resolver test file. Confirm the existing exact-name validator, dependency-free classifier, fallback, self-reference, and scanner behavior remain unchanged. The aggregate 1,024-edge boundary is checked in Task 2 because the per-terminal 4,096-byte cap bounds what a single guard call can scan.

- [ ] **Step 6: Review and make the signed task commit.** Review the resolver and test diff. Confirm no new name regex, Unicode trim, lookup, or value substitution entered the guard. Commit only the two task files with `git commit -S -m "feat: admit exact C2 passthrough inputs"`.

## Task 2: Precompute and resolve one base dependency hop

**Files:**

- Modify `apps/live_frames/lib/live_frames/adapters/bricks/source_local_custom_property_resolver.ex`.
- Test `apps/live_frames/test/live_frames/bricks_source_local_custom_property_resolver_test.exs`.
- Add the first normalizer integration sentinel to `apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs` before changing the batch resolver.

- [ ] **Step 1: Write the focused resolver and integration tests.** Add these tests before production changes:

  - `"resolves an exact passthrough to a same-path base terminal"`: A=`var(--b)`, B=`12px`, and a consumer of A at the selected path return `{:ok, [{:ok, "12px"}]}`.
  - `"selects the nearest base ancestor for a passthrough dependency"`: with no same-path B, the nearest eligible B ancestor supplies the terminal; a same-path B beats an eligible ancestor B.
  - `"resolves an exact passthrough through the normalizer flow"`: synthetic CSS `".owner { --b: 12px; --a: var(--b); color: var(--a); }"` yields a literal `color` value of `"12px"`, emits neither definition, and has no residual.
  - `"rejects a second dependency hop without expanding it"`: A=`var(--b)`, B=`var(--c)`, C=`12px` returns `{:error, :unsupported_nested_reference}` for A.
  - `"preserves downstream definition failures for a passthrough"`: table cases where B has a fallback, directly self-references, participates in a cycle, or contains another ordinary dependency return respectively `:unsupported_fallback`, `:self_reference`, `:cycle`, and `:unsupported_nested_reference`.
  - `"keeps nested dependency failures within the existing closed taxonomy"`: A self-reference returns `:self_reference`; A-to-B-to-A returns `:cycle`; A with a fallback returns `:unsupported_fallback`; missing B returns `:no_local_definition`.

  Freeze these batch outcomes (no new diagnostic atom):

  | Case | Expected result |
  | --- | --- |
  | `A -> A` | `:self_reference` |
  | `A -> B -> A` | `:cycle` |
  | `A -> B -> C` | `:unsupported_nested_reference` |
  | `A -> var(B, fallback)` | `:unsupported_fallback` |
  | missing B | `:no_local_definition` |
  | cross-provenance B | `:no_local_definition` |
  | sibling-only B | `:no_local_definition` |
  | responsive-only B | `:no_local_definition` |
  | state-only B | `:no_local_definition` |
  | foreign-owner batch | `:cross_owner_reference` |
  | malformed `target_path` | `:unsupported_inheritance` |
  | ambiguous B | `:ambiguous_definition` |
  | conflicting B | `:conflicting_source_order` |
  | external collision on A or B | `:external_authority_collision` |
  | B at exactly 64 hops | success |
  | eligible B only beyond 64 hops | `:resource_limit_exceeded` |

- [ ] **Step 2: Run both focused files and prove RED.**

  Run: `mix test apps/live_frames/test/live_frames/bricks_source_local_custom_property_resolver_test.exs`

  Expected: the direct one-hop resolver assertion fails with the current `:unsupported_nested_reference` result. The second-hop and existing failure-taxonomy cases remain fail-closed.

  Run: `mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`

  Expected: the integration sentinel leaves `color` unresolved with a whole-rule residual because the current resolver rejects A's dependency.

- [ ] **Step 3: Implement the outcome map with existing index mechanisms.** Replace `build_dependency_states/1` with `build_dependency_outcomes/3` and store `:dependency_outcomes`. Preserve the graph edge counter and cycle calculation. For each selected base definition, classify its own terminal or existing failure. For an exact passthrough, use `find_dependency_definition/3` with A's **reversed** selected path, require a base B in the same already-filtered owner/provenance index, and check `external_collisions` for B. If no B is selected within the bound, call `farther_ancestor_exists_in_scope?/3` with `Enum.reverse(reversed_path)` per **Frozen path orientation** to return `:resource_limit_exceeded` only when an otherwise eligible base B exists beyond 64 hops; otherwise return `:no_local_definition`. Return B's terminal only when B's own outcome is `{:terminal, value}`. Propagate existing B errors. Convert a B outcome tagged `:passthrough` to `:unsupported_nested_reference` for A.

- [ ] **Step 4: Run both focused files and prove GREEN.**

  Run: `mix test apps/live_frames/test/live_frames/bricks_source_local_custom_property_resolver_test.exs`

  Expected: the same-path and nearest-ancestor A-to-B cases resolve to B's terminal; A-to-B-to-C remains `:unsupported_nested_reference`; all failure atoms match the assertions.

  Run: `mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`

  Expected: the integration sentinel emits literal `color: 12px`, hides both definitions, and produces no residual.

- [ ] **Step 5: Add and run the path, scope, collision, selection, and boundary matrix.** Use synthetic records and assert:

  | Case | Expected result |
  | --- | --- |
  | B missing, in another provenance, on a sibling path, responsive-only, or state-scoped | `:no_local_definition` |
  | Foreign-owner record in a batch | `:cross_owner_reference` |
  | Malformed or non-list consumer `target_path` | `:unsupported_inheritance` |
  | B has multiple selector identities | `:ambiguous_definition` |
  | B has conflicting candidates for one selector identity | `:conflicting_source_order` |
  | B collides with external authority | `:external_authority_collision`, without using the external candidate |
  | B is exactly 64 ancestry hops from A's selected definition path | Success |
  | Eligible B exists only beyond 64 hops | `:resource_limit_exceeded` |
  | B is dependency-free and exactly 4,096 bytes | Success |
  | B is 4,097 bytes | `:resource_limit_exceeded` |

  Add `"distinguishes 64-hop success from beyond-64 resource failure with non-palindromic paths"`: use distinct, non-palindromic synthetic path components (for example `[101, 202, 303, …]` rather than symmetric segments) so accidentally passing `reversed_path` to `farther_ancestor_exists_in_scope?/3` cannot still pass. Assert B exactly 64 ancestors from A succeeds and the same B placed only beyond 64 returns `:resource_limit_exceeded`.

  Add root-reference scope characterization (existing behavior; not RED unless baseline already fails):

  - `"keeps state-scoped consumer references fail closed"`: a state-scoped consumer reference returns `:unsupported_scope`.
  - `"keeps responsive consumer references that select responsive definitions fail closed"`: a responsive consumer that would select only a responsive-scoped definition retains existing `:unsupported_scope` behavior.
  - `"keeps responsive consumer base fallback unchanged"`: a responsive consumer with no responsive definition but an eligible base definition at the same path or accepted ancestor still resolves through base per existing rules.

  Keep nested-dependency B rules unchanged: responsive-only B and state-scoped B remain `:no_local_definition`. Keep existing `select_definition/2` candidate outcomes intact. Do not scan responsive or state scopes to manufacture a different B failure.

- [ ] **Step 6: Prove all resource bounds and reference ordering.** Re-run the existing exact boundary assertions: 256 definitions pass and 257 fail; 1,024 references pass and 1,025 fail; 1,024 dependency edges pass and 1,025 fail; 64 relative hops pass and a candidate found only past the bound is a resource failure; 4,096 terminal bytes pass and 4,097 fail. Add `"resolves one nested definition across the maximum ordered reference batch"` with 1,024 references alternating A and a direct terminal reference. Assert exactly 1,024 results in input order with the corresponding alternating values. Use no mocks or private-helper call counters.

  Run: `mix test apps/live_frames/test/live_frames/bricks_source_local_custom_property_resolver_test.exs`

  Expected: every exact limit passes; each first-excess case returns the existing top-level or per-reference resource outcome; the 1,024-result batch preserves cardinality and order.

- [ ] **Step 7: Run focused regression tests.** Run both focused test files again. Review every result in order and confirm there is no per-reference dependency walk, new failure atom, external fallback, scope scan, or recursion.

- [ ] **Step 8: Review and make the signed task commit.** Review the resolver and both test diffs. Commit only those files with `git commit -S -m "feat: resolve one bounded C2 passthrough hop"`.

## Task 3: Lock normalizer integration and generic-policy regressions

**Files:**

- Test `apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs` only.
- No production file changes are allowed in this task.

The one-hop normalizer assertion was written and observed RED in Task 2 before the resolver change. This task adds characterization and regression assertions for surrounding behavior. Assertions that the existing implementation already satisfies are not described as RED tests.

- [ ] **Step 1: Add source-neutral integration and regression tests.** Add or extend these named cases:

  - `"keeps an ordinary dependency-free local definition unchanged"`: preserve the existing direct local resolution output and keep the definition absent from emitted styles.
  - `"keeps a multi-hop local definition whole-rule fail-closed"`: A=`var(--b)`, B=`var(--c)`, C=`12px`; assert no style is emitted and the original selector rule remains one `unresolved_value` residual.
  - `"keeps fallback and missing downstream definitions fail-closed"`: test A=`var(--b, 4px)` and A=`var(--missing)`; assert no consumer style and a whole-rule `unresolved_value` residual.
  - `"applies consumer declaration safety to a one-hop terminal"`: A points to B and B contains an unsafe terminal such as `url(https://example.test/a.png)`; assert no style and the existing `unsafe_declaration` residual.
  - `"does not use external authority to rescue a failed local chain"`: provide external candidates for the local chain's names while A's downstream local value requires a second hop; assert no token or literal style and retain the local rule as unresolved.
  - `"keeps C1 transition grammar and routing unchanged after C2"`: retain existing C1 transition parser, property routing, reconstruction, and whole-rule atomicity without production changes.
  - `"resolves a one-hop nested local definition for transition"`: `--duration: var(--base-duration)` with terminal `--base-duration` and an admitted C1 transition reference to `--duration` succeeds.
  - `"keeps a multi-hop nested local definition fail-closed for transition"`: a two-hop duration chain remains one `unresolved_value` residual with no emitted `transition` style.
  - `"keeps legacy direct resolution, compound behavior, and FRAME C fail-closed"`: retain the existing direct local, compound `calc(var(...))`, and compound residual assertions without changing their expected output.
  - `"applies the same passthrough syntax across synthetic source metadata"`: use the same generic grammar with different synthetic owner IDs, source IDs, selector identities, properties, and irrelevant synthetic component, residual-fingerprint, and requirement-classification fields. Assert equal eligibility wherever owner and exact provenance match. Do not add a Romeo-specific name, value, selector, fingerprint, or requirement gate.

- [ ] **Step 2: Run the focused normalizer file and prove the integration behavior.**

  Run: `mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`

  Expected: the new regression assertions pass. The one-hop success test remains covered by the Task 2 RED/GREEN cycle. Treat the tests for dependency-free resolution, C1 transition behavior, legacy direct resolution, compound behavior, and FRAME C as characterization checks because the pre-C2 implementation already passed them.

- [ ] **Step 3: Review the generic-policy and module-boundary diff.** Verify that only the normalizer test file changed in this task; no production branch keys on component ID, source ID, owner ID, residual fingerprint, property, private names/selectors, or requirement classification. Confirm all fixtures are synthetic and source-neutral.

- [ ] **Step 4: Run focused regression tests.**

  Run: `mix test apps/live_frames/test/live_frames/bricks_source_local_custom_property_resolver_test.exs`

  Run: `mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`

  Expected: both focused suites pass with the resolver and integration assertions together.

- [ ] **Step 5: Run the full implementation verification gate.** Use the current umbrella CI workflow, `.github/workflows/ci.yml`, and run:

  ```sh
  mix deps.get
  mix format --check-formatted
  mix compile --warnings-as-errors
  mix assets.build
  git diff --exit-code -- apps/live_frames/assets/css/theme/lf_theme.css apps/live_frames/priv/static/live_frames/css/live_frames.css
  mix test apps/live_frames/test/live_frames/bricks_source_local_custom_property_resolver_test.exs
  mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs
  mix test
  mix deps.unlock --check-unused
  git diff --check
  ```

  `mix test` is the repository's umbrella test command; the current workflow has no separate preview-only test command. The CI package-content verification step in `.github/workflows/ci.yml` remains required through exact-head push and PR CI. No dependency or asset changes are expected. If a gate reports drift or a failure, stop and report it; do not weaken the gate.

- [ ] **Step 6: Review and make the signed task commit.** Inspect the full diff and verify the production boundary still contains one resolver file. Commit the normalizer regression tests with `git commit -S -m "test: cover C2 normalizer regressions"`.

## Full-plan review checklist

Before implementation begins, compare this plan line-by-line with `docs/development/frame_d_bounded_nested_local_resolution_authority.md` and confirm:

- one-hop only, base-only B, same owner, exact provenance, same-path then nearest ancestor, 64-hop distinction, external collision, ambiguity, conflict, self-reference, cycle, fallback, and multi-hop rejection are assigned to Task 1, 2, or 3;
- dependency-free guard behavior, 256 definitions, 1,024 references, 1,024 dependency edges, 4,096 terminal bytes, cold-build performance, P1 policy, and no recursion are covered;
- responsive-only and state-scoped B are ineligible and are not scanned for another failure reason;
- root consumer state-scoped references, responsive-only consumer selection, and responsive consumer base fallback remain frozen by characterization tests;
- terminal B values go through existing consumer safety and definitions stay out of emitted styles;
- C1 transition grammar/routing (not one-hop FRAME D unlock), legacy direct resolution, compound behavior, and FRAME C remain unchanged;
- no required behavior needs a production change outside the resolver file.

If any authority requirement cannot map to a task and assertion within these three files, stop with `STOP=C2_PLAN_CANNOT_IMPLEMENT_ACCEPTED_AUTHORITY_WITHIN_BOUNDARY`.

## Non-goals

- No implementation work in this plan-authoring PR.
- No second resolver, recursive substitution, configurable depth, browser cascade, arbitrary expression substitution, or fallback expansion.
- No external token or VariableAuthority fallback for a failed local chain.
- No responsive or state-scoped B resolution, Romeo-specific policy, unknown-count prediction, private corpus access, dependency change, asset change, or generated artifact.
- No changes to `CustomCssNormalizer` production, `CompoundCssValue`, `CustomCssParser`, `CSSDeclaration`, `VariableAuthority`, Design IR, style precedence, `NativeGenerator`, or runtime code.
- After an implementation merge and its post-merge gate, a canonical Romeo public-adapter rerun is a separate evidence gate. Its expected marginal required unlock is `4`; do not force that result or predict the unknown count.

## Stop conditions

Stop at the first applicable condition and report its exact value:

```text
STOP=C2_PLAN_BASELINE_CHANGED
STOP=C2_AUTHORITY_NOT_IN_MAIN_ANCESTRY
STOP=C2_EXPECTED_IMPLEMENTATION_BOUNDARY_INVALID
STOP=C2_PLAN_CANNOT_IMPLEMENT_ACCEPTED_AUTHORITY_WITHIN_BOUNDARY
STOP=SECOND_RESOLVER_REQUIRED
STOP=GENERAL_RECURSION_REQUIRED
STOP=NORMALIZER_PRODUCTION_CHANGE_REQUIRED
STOP=COMPOUND_PRODUCTION_CHANGE_REQUIRED
STOP=IR_CHANGE_REQUIRED
STOP=VARIABLE_AUTHORITY_CHANGE_REQUIRED
STOP=FAILURE_TAXONOMY_AMBIGUOUS
STOP=BASE_ONLY_DEPENDENCY_POLICY_AMBIGUOUS
STOP=RESOURCE_BOUNDARY_AMBIGUOUS
STOP=PRIVATE_SOURCE_REQUIRED
STOP=PRIVATE_SOURCE_LEAK
STOP=MORE_THAN_ONE_PLAN_FILE_CHANGED
STOP=PRODUCTION_FILE_CHANGED
STOP=TEST_FILE_CHANGED
STOP=EXISTING_AUTHORITY_CHANGED
STOP=UNSIGNED_HISTORY
STOP=CI_FAILURE
```

## Docs-only publication

Create the plan PR from the accepted `origin/main` head on branch `docs/c2-frame-d-bounded-nested-local-resolution-plan`. Change exactly this file:

```text
docs/superpowers/plans/2026-10-23-c2-frame-d-bounded-nested-local-resolution.md
```

Run `git diff --check`, create one signed commit, push the branch, and open one PR to `main`. Require successful exact-head push CI and PR CI. Leave the PR open and unmerged. Do not start implementation.

The current plan base is `5a4c48f3a283f8720ef33fe6292f55cbc0083ea7`, tree `ea927f30931cd6be8dd8c8024e9ac9cb2eb31c6b`. The accepted C2 authority merge `3889309b9b1273a05df53d6f2f195513edf1387b` is in its ancestry. Recheck the exact pushed head and both CI runs before reporting the PR ready.
