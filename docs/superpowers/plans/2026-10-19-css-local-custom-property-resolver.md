# CSS local custom-property resolver implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task by task. Steps use checkbox syntax for tracking.

**Goal:** Resolve bounded direct local `var(--name)` references during Bricks custom CSS normalization and emit only existing normalized Design IR values.

**Architecture:** `CustomCssNormalizer` will pass already parsed, selector-resolved records and exact `StylePrecedence` provenance to a batch `SourceLocalCustomPropertyResolver`. The resolver returns terminal source text or a closed failure state. The normalizer will run successful text through the existing declaration and value checks, while keeping definitions internal and preserving residual behavior.

**Spec:** `docs/development/css_local_custom_property_resolution_authority.md`

**Tech Stack:** Elixir umbrella application, Mix, ExUnit, `CustomCssParser`, `CustomCssNormalizer`, `StylePrecedence` provenance, `CSSDeclaration`, `VariableAuthority`, and existing Design IR style values.

---

## Global Constraints

- Resolve direct `var(--name)` only. Do not expand selector grammar or send raw selector text to the resolver.
- A local-lane failure never falls back to external authority. Do not change Design IR, schema, or generator behavior.
- The implementation boundary is exactly four production/test files. Keep limits at 65,536 CSS bytes, 256 definitions, 1,024 references, 64 relative ancestry hops, and 4,096 terminal bytes; substitution depth is one and dependency edges are capped at 1,024.
- Observe a failing TDD assertion before production code. Private Romeo source must not enter repository tests.

## Authority and preflight

The source-neutral contract is `docs/development/css_local_custom_property_resolution_authority.md` on current `main`. Treat its selector, ownership, scope, safety, and resource decisions as fixed. This plan records the narrower input contract accepted in PR #257 and does not authorize implementation execution.

```text
PLAN_BASE_SHA=c2e460c8eba51d1678905b2cac2421bc2a1ab13b
PLAN_BASE_TREE=8c40e3cca8eb9b267fa4fa260428f006ae64f141
PR_257=MERGED
PR_257_APPROVED_HEAD=4e8da24344a9b17dcc0d1178717d17810e53874d
PR_257_MERGE_SHA=3dd020cd3d5922ab38ede7c70ce8c5b4a4c7963d
PR_257_MERGE_TREE=b5b759f504db0e230cc668b35886e3d9ca7cde21
PR_257_MERGE_SIGNATURE=VERIFIED
PR_257_APPROVED_HEAD_IS_MERGE_PARENT=YES
RESOLVER_INPUT_CONTRACT_BYTES_ON_MAIN=YES
CURRENT_MAIN=c2e460c8eba51d1678905b2cac2421bc2a1ab13b
CURRENT_MAIN_TREE=8c40e3cca8eb9b267fa4fa260428f006ae64f141
PR_257_EXACT_MERGE_CI=39202214865 SUCCESS
PR_257_EXACT_MERGE_CI_HEAD=3dd020cd3d5922ab38ede7c70ce8c5b4a4c7963d
CURRENT_MAIN_CI=39202232933 SUCCESS
IMPLEMENTATION_PLAN_MAY_PROCEED=YES
IMPLEMENTATION_PLAN_AUTHORIZED=YES
IMPLEMENTATION_EXECUTION_AUTHORIZED=NO
CSS_LOCAL_CUSTOM_PROPERTY_IMPLEMENTATION_AUTHORIZED=NO
STOP=NONE
```

Run `39202214865` completed successfully on the exact PR #257 merge SHA. This clears the exact-SHA CI stop recorded before the run completed. It does not authorize implementation. Implementation must wait for independent review of this plan and explicit owner authorization. Recheck `main`, authority files, and exact-SHA CI before implementation starts. Stop if an authority or planned implementation file changed in a way that affects this contract.

## Scope

Implement only bounded source-local resolution for a direct `var(--name)` declaration in the existing `CustomCssNormalizer` flow. A successful lookup yields one terminal string. The current declaration and value normalizer decides whether that string can become an existing literal or keyword `StyleValue`.

The implementation does not add compound-value grammar, `FUNCTION_CALL`, `MULTI_TOKEN_VALUE`, `VAR_REFERENCE_WITH_OPERATION`, general CSS variables, browser cascade behavior, selector grammar, runtime variables, IR fields, generator behavior, componentization, or a Romeo canonical rerun.

The observed canonical source has confirmed-required and unknown findings. Apply the same generic eligibility checks to every declaration. Do not add source IDs, source classes, Romeo-specific names, values, selectors, fixtures, or policy branches. An unknown declaration remains residual whenever ownership, scope, resolution, or safety cannot be proved.

## File structure

The later implementation PR may change exactly these four files:

- Create `apps/live_frames/lib/live_frames/adapters/bricks/source_local_custom_property_resolver.ex`. Own local-name validation, bounded definition indexing, scope selection, duplicate handling, dependency classification, and closed resolver states.
- Create `apps/live_frames/test/live_frames/bricks_source_local_custom_property_resolver_test.exs`. Cover resolver behavior with synthetic records.
- Modify `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex`. Own CSS byte limits, selector identity, observed local names, eligible record construction, resolver batching, revalidation, and residual atomicity.
- Modify `apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`. Cover local definition consumption, ordinary style output, external routing, rule atomicity, and revalidation.

Do not modify `custom_css_parser.ex`, `style_precedence.ex`, `variable_authority.ex`, `css_declaration.ex`, Design IR modules, `StyleValue`, serializers, `NativeGenerator`, conversion matrices, dependency files, assets, or private source material. Stop with `STOP=PLANNED_IMPLEMENTATION_BOUNDARY_EXPANDED` if any of those changes appears necessary.

## Frozen resolver contract

Use one batch call:

```elixir
SourceLocalCustomPropertyResolver.resolve(definition_records, reference_records, opts)
# => {:ok, ordered_results} | {:error, batch_failure_state}
# valid batches return one entry per reference, in reference input order
# each entry is {:ok, terminal_text} or {:error, resolver_state_atom}
```

The required `opts` are `owner_source_id`, the exact trusted owner source ID; `effective_provenance_identity`, the exact trusted provenance tuple; and `authority_index`, used only for presence checks. `CustomCssNormalizer` supplies the trusted batch identity. Never infer it from a first record, record order, or record contents, and never group multiple owners or provenance identities inside one resolver call.

Freeze the provenance identity as this tuple, preserving `authority_ids` exactly as supplied by `StylePrecedence`:

```elixir
{source_id, origin, class_id, resolution_source, authority_ids, class_reference_index}
```

Before candidate lookup, require every definition and reference record to match the trusted owner and provenance scope. A supplied foreign-owner record fails closed as `CROSS_OWNER_REFERENCE`; do not create another batch for it or infer a different scope.

For a valid batch, return exactly one result per reference, preserving reference input order. Do not return an `ordered_results` value for an invalid oversized batch. Preflight counts must stop as soon as they observe `LIMIT + 1`; never scan arbitrary excess input to compute its total.

```text
BATCH_RESOURCE_FAILURE=TOP_LEVEL_ERROR
PARTIAL_BATCH_PROCESSING=NO
OVER_LIMIT_RESULT_AMPLIFICATION=NO
BATCH_IDENTITY_OWNER=CustomCssNormalizer
BATCH_IDENTITY_INFERRED_FROM_RECORDS=NO
MULTI_OWNER_RESOLVER_CALL=NO
MULTI_PROVENANCE_RESOLVER_CALL=NO
```

Do not expose the index, add public reference IDs, create a stateful API, or create a general CSS-variable service. Keep normalizer-only correlation metadata outside resolver records:

```text
{rule_id, target_source_id, selector_identity, property}
```

Each post-selector resolver record contains only the already parsed values required by the authority:

```text
owner_source_id
effective_provenance_identity
target_source_id
target_path
selector_identity
viewport_scope
state_scope
source_order
local_name
record_kind
terminal_text_if_definition (definition records only)
```

`record_kind` is `:definition` or `:reference`. `source_order` is `{source_index, frame.source_order}` and exists only for stable diagnostics. It never chooses a winning definition. The exact effective provenance identity is the tuple frozen above. Do not include responsive source keys or viewport keys in this identity.

Pass the existing `:authority_index` through required `opts` only for the presence-only external-name collision check. The resolver must discard candidate paths and values after checking whether an exact-name candidate exists.

`CustomCssNormalizer` owns selector parsing and target matching. It creates an opaque, non-serialized parsed identity equivalent to:

```text
{:selector_identity_v1, ordered_descendant_compounds, parsed_marker, parsed_condition}
```

Each compound retains its parsed marker and has its classes sorted and
deduplicated. Preserve the order of descendant compounds.

Preserve descendant order. Sort classes only within each parsed compound. Exclude raw selector text. Do not hash, serialize, expose, or send raw selectors to the resolver. The resolver compares this term for equality only.

## Resolution rules

### Local-name routing

- Validate the exact spelling with `CSSDeclaration.safe_property?/1` and require the `--` prefix. Do not add a second name regex, case fold, or normalize a name.
- Track `OBSERVED_LOCAL_DEFINITION_NAMES` separately from `ELIGIBLE_LOCAL_DEFINITION_RECORDS`.
- A safely parsed definition name in the selected layer enters the local lane even if its selector or scope cannot produce an eligible record. If local resolution then fails, keep the consumer unresolved. Never route it to external authority.
- Only a direct `var(--name)` whose exact name has no parsed local definition in the selected layer may use the existing independent `VariableAuthority` path.
- If a local definition and any `VariableAuthority` candidate share the exact name, fail with `EXTERNAL_AUTHORITY_COLLISION`. Use authority presence only. Never use its token path or candidate value to substitute a local definition.
- Custom-property definitions are compiler inputs only. Do not emit them as node styles, responsive styles, token references, Design IR values, or generated CSS.
- Do not expand the accepted direct-variable grammar. Any compound value containing `var()` remains unresolved for the separate compound-value lane.

### Owner, provenance, target, and duplicate scope

- Batch exactly one `owner_source_id` and one `effective_provenance_identity`, both supplied by `CustomCssNormalizer` in required `opts`. Include only the already selected base records and selected responsive records for that identity. Keep each record's viewport scope separate so responsive references can use an eligible base definition. Do not search shadowed layers, other owners, other components, or global classes.
- Require exact owner and effective provenance equality before candidate lookup. A supplied foreign-owner record fails closed as `CROSS_OWNER_REFERENCE`; never group it into an additional batch.
- Direct target definitions always take priority over ancestors. Otherwise, consider only the nearest proven ancestor, where `definition.target_path` is a strict structural component prefix of `reference.target_path` inside the same owner and provenance.
- A sibling is never an ancestor. Paths are structural lists, not text prefixes. `MAX_OWNER_ANCESTRY_HOPS=64` measures the relative structural distance from a reference target to a candidate definition target within the current owner subtree, not absolute path length from a component or document root. Distance 64 is allowed; distance 65 returns `RESOURCE_LIMIT_EXCEEDED`. For example, paths of lengths 100 and 101 with a parent-child relation have distance 1 and are allowed.
- At the selected target, one selector identity with one definition selects it. Multiple definitions with that identity and byte-identical terminal text coalesce. Different terminal text with one identity returns `CONFLICTING_SOURCE_ORDER`. More than one identity returns `AMBIGUOUS_DEFINITION`, even if terminal text matches.
- Source order stabilizes diagnostics only. Never use it as cascade precedence.

### Responsive and state scope

- Base definition to base reference is allowed within exact owner and provenance.
- Base definition to responsive reference is allowed only within exact owner and provenance at the same target or nearest proven ancestor.
- State-scoped lookup is unsupported.
- Responsive definitions do not resolve in this slice. For a responsive reference, choose the selected relation using direct target first, otherwise the nearest proven ancestor, considering eligible definitions at either base or responsive scope. Then inspect that relation for an eligible responsive definition in the same exact responsive viewport scope. If one exists, fail `UNSUPPORTED_SCOPE` before using any base definition at that relation; do not silently fall back. This applies to both a same-target responsive definition and a nearest-ancestor responsive definition.
- Responsive-to-responsive, responsive-to-base, responsive-to-state, base-to-state, and state-to-state transitions fail closed. Do not compare media ranges, infer named breakpoints, or change media boundaries.

### Dependency and terminal handling

- Do not recursively substitute definition values. A local lookup followed by one terminal value is the maximum depth.
- Classify a direct self-edge as `SELF_REFERENCE`, a cycle in the bounded local definition graph as `CYCLE`, a fallback form as `UNSUPPORTED_FALLBACK`, and any other downstream `var()` dependency as `UNSUPPORTED_NESTED_REFERENCE`.
- Dependency analysis is diagnostic only. Use at most 256 definitions and 1,024 edges. It never expands a value.
- Reject terminal text over 4,096 bytes before returning it.
- The resolver returns terminal text only. `CustomCssNormalizer` must pass it through the existing property safety and declaration value normalization with the `:source_resolver` origin where accepted. Map safety rejection to `UNSAFE_TERMINAL_VALUE` and unsupported value normalization to `UNSUPPORTED_TERMINAL_VALUE` for diagnostics. Do not duplicate CSS safety rules in the resolver.

### Limits and complexity

```text
MAX_EFFECTIVE_LAYER_CSS_BYTES=65536
MAX_LOCAL_DEFINITIONS_PER_OWNER_LAYER=256
MAX_LOCAL_REFERENCES_PER_OWNER_LAYER=1024
MAX_OWNER_ANCESTRY_HOPS=64
MAX_TERMINAL_VALUE_BYTES=4096
MAX_LOCAL_SUBSTITUTION_DEPTH=1
MAX_DEPENDENCY_EDGES=1024
```

Check the CSS byte limit in `CustomCssNormalizer` before calling `CustomCssParser.parse/1`. Apply definition and reference counts to the post-selector records passed into each single-owner/single-provenance resolver call, across its selected base and responsive records. More than 256 definitions or more than 1,024 references returns top-level `{:error, :resource_limit_exceeded}`. Count only through `LIMIT + 1`; never truncate, partially process, or allocate one error result per excess reference. Build one index per owner/provenance call. Target complexity is `O(D + R * H)` where `D <= 256`, `R <= 1024`, and `H <= 64`. Do not rescan the full source for each reference.

### Closed failure states

Resolver or integration failures must remain in this closed state set:

```text
INVALID_LOCAL_NAME
NO_LOCAL_DEFINITION
AMBIGUOUS_DEFINITION
CONFLICTING_SOURCE_ORDER
UNSUPPORTED_SCOPE
CROSS_OWNER_REFERENCE
UNSUPPORTED_INHERITANCE
UNSUPPORTED_FALLBACK
UNSUPPORTED_NESTED_REFERENCE
SELF_REFERENCE
CYCLE
UNSAFE_TERMINAL_VALUE
UNSUPPORTED_TERMINAL_VALUE
EXTERNAL_AUTHORITY_COLLISION
CROSS_COMPONENT_REFERENCE
RESOURCE_LIMIT_EXCEEDED
```

Do not turn any local-lane failure into external substitution. Keep the canonical residual reason `unresolved_value` where that is current behavior. A stable resolver state may appear in diagnostic metadata, but do not change canonical residual fingerprints or their reason/raw-source inputs.

## Normalizer lifecycle and atomicity

For each owner and exact effective provenance group, the integration follows this order. A batch may include already selected base records and responsive records with that same provenance identity; each record retains its viewport scope:

```text
selected effective CSS and provenance
  -> enforce 65,536-byte limit
  -> parse with existing CustomCssParser
  -> retain parsed selector identity and proven target paths
  -> collect observed local names
  -> build eligible definition and direct-reference records
  -> resolve references once for the owner/provenance batch
  -> correlate ordered results with private normalizer metadata
  -> rerun existing CSSDeclaration and value normalization
  -> emit existing StyleValue values or preserve residuals
```

Do not modify the parser or selector grammar. An unsupported-selector definition may block external fallback by name, but it cannot enable its own selector, ordinary declarations in its rule, or a consumer. Preserve rule atomicity: if one target or declaration in a selector rule fails, emit none of that rule's normalized styles and retain the rule as residual. Remove successful definition declarations from output as compiler inputs only.

## Task 1: resolver core

**Files:**
- Create `apps/live_frames/test/live_frames/bricks_source_local_custom_property_resolver_test.exs`.
- Create `apps/live_frames/lib/live_frames/adapters/bricks/source_local_custom_property_resolver.ex`.

**Interface:** Implement only `resolve/3` with required `owner_source_id`, `effective_provenance_identity`, and `authority_index` options. Valid batches return ordered one-result-per-reference output; a definition or reference hard-limit failure returns top-level `{:error, :resource_limit_exceeded}` with no partial results. Records use the frozen fields above. This task covers validation, exact trusted owner/provenance checks, direct target and nearest-ancestor selection, duplicate behavior, and bounds.

Every resolver test supplies explicit synthetic batch options: one expected `owner_source_id`, its exact provenance tuple as `effective_provenance_identity`, and an `authority_index` (empty when no external candidate is needed).

- [ ] **Step 1: Add synthetic failing resolver tests.** Add these ExUnit tests before production code:
  - `test "validates exact local names with the existing property boundary"`: the valid name `"--local-name"` is accepted; safe ordinary property `"color"` without the `--` prefix and a malformed name rejected by `CSSDeclaration.safe_property?/1` each return `{:ok, [{:error, :invalid_local_name}]}`. Do not test a value with `safe_property?/1` or duplicate its name regex.
  - `test "isolates definitions by exact effective provenance"`: pass `owner_source_id`, the exact six-field `effective_provenance_identity` tuple, and `authority_index` in opts; a definition from a different class reference, authority ID order, or other provenance field never supplies the reference; the one-reference result is `{:ok, [{:error, :no_local_definition}]}`.
  - `test "rejects foreign owner records supplied to one owner batch"`: pass the expected owner and provenance explicitly in opts; a mixed-owner one-reference call returns `{:ok, [{:error, :cross_owner_reference}]}` and never selects the foreign record or creates another batch.
  - `test "prefers a direct target definition over every ancestor"`: the direct terminal is returned even when an ancestor has a different terminal.
  - `test "selects only the nearest proven ancestor"`: nearest ancestor terminal wins; a sibling and a farther ancestor do not compete.
  - `test "coalesces byte-identical definitions with one selector identity"`: identical same-identity terminals return one success.
  - `test "rejects conflicting same-identity definitions without source-order selection"`: differing terminals produce the per-reference result `{:error, :conflicting_source_order}` regardless of input order.
  - `test "keeps different selector identities ambiguous when terminals match"`: two identities with equal terminal text produce `{:error, :ambiguous_definition}` for that reference.
  - `test "preserves reference result order and cardinality"`: result entries zip one-for-one with references in their input order.
  - `test "allows exactly 256 definitions and rejects 257 at batch level"`: exactly 256 definition records return a valid `{:ok, ordered_results}` batch; 257 definition records return top-level `{:error, :resource_limit_exceeded}` with no `ordered_results`.
  - `test "allows exactly 1024 references and rejects 1025 at batch level"`: 1,024 references return 1,024 ordered results; 1,025 references return top-level `{:error, :resource_limit_exceeded}`, with no partial results or error result per reference.
  - `test "rejects terminal text above 4096 bytes"`: a 4,097-byte terminal produces `{:error, :resource_limit_exceeded}` for its reference.
  - `test "limits relative ancestry distance rather than absolute path length"`: definition/reference paths of lengths 100 and 101 at distance 1 resolve; relative distance 64 resolves; relative distance 65 returns `:resource_limit_exceeded` for the reference.
- [ ] **Step 2: Run the resolver test file and observe RED.** Run `mix test apps/live_frames/test/live_frames/bricks_source_local_custom_property_resolver_test.exs`. Expected: the new assertions fail because `SourceLocalCustomPropertyResolver.resolve/3` is not implemented. Do not add production code before observing this failure.
- [ ] **Step 3: Implement the minimum resolver core.** Add the batch function and private bounded index. Require the trusted owner/provenance and authority options; do not infer batch identity from records. Preflight definition/reference counts and stop at `LIMIT + 1`, returning top-level `{:error, :resource_limit_exceeded}` without partial processing. Validate names with `CSSDeclaration.safe_property?/1` plus the `--` prefix. Match owner and provenance exactly; compare selector identity only for equality; prefer direct target then nearest structural ancestor; measure the 64-hop bound as relative structural distance; enforce duplicate rules. Keep `source_order` out of winner selection.
- [ ] **Step 4: Run resolver tests and observe GREEN.** Run `mix test apps/live_frames/test/live_frames/bricks_source_local_custom_property_resolver_test.exs`. Expected: every Task 1 assertion passes and results remain ordered and bounded.
- [ ] **Step 5: Commit Task 1.** Run `git diff --check`, stage only the resolver and resolver test, then create one signed commit: `feat: add bounded local custom property resolver`.

## Task 2: scope and dependency safety

**Files:**
- Modify `apps/live_frames/lib/live_frames/adapters/bricks/source_local_custom_property_resolver.ex`.
- Modify `apps/live_frames/test/live_frames/bricks_source_local_custom_property_resolver_test.exs`.

**Interface:** Keep `resolve/3`, its required trusted batch options, and record fields unchanged. Add only bounded responsive/state classification, presence-only external authority collision detection, dependency classification, and closed failure results.

- [ ] **Step 1: Add synthetic failing scope and dependency tests.** Add these tests before modifying the resolver:
  - `test "allows a base definition for a responsive reference in exact owner provenance"`: same-target and nearest-ancestor one-reference calls return `{:ok, [{:ok, terminal}]}`.
  - `test "same-target responsive definition blocks base fallback"`: an eligible responsive definition at the selected same-target relation produces `{:ok, [{:error, :unsupported_scope}]}` even when a base definition could match.
  - `test "responsive ancestor shadowing blocks base fallback"`: an eligible responsive definition at the selected nearest-ancestor relation produces `{:ok, [{:error, :unsupported_scope}]}` even when a base definition could match.
  - `test "rejects state-scoped references and responsive definitions"`: each unsupported scope transition produces a per-reference `:unsupported_scope` result.
  - `test "rejects sibling and unproven ancestry"`: sibling paths return `:no_local_definition`; a path that is not a strict structural prefix never resolves.
  - `test "rejects an external authority collision without reading its token value"`: a local definition plus any exact-name `VariableAuthority` candidate produces `:external_authority_collision` for its reference.
  - `test "classifies fallback and nested references without substitution"`: fallback produces `:unsupported_fallback`; another downstream local reference produces `:unsupported_nested_reference`.
  - `test "classifies self references and multi-definition cycles"`: a self edge produces `:self_reference`; a bounded cycle produces `:cycle`.
  - `test "rejects dependency graphs above 1024 edges"`: a synthetic graph with 1,025 dependency edges produces `{:error, :resource_limit_exceeded}` for the affected reference.
  - `test "returns no local definition for an ordinary miss"`: an absent exact name produces `{:ok, [{:error, :no_local_definition}]}`.
- [ ] **Step 2: Run resolver tests and observe RED.** Run `mix test apps/live_frames/test/live_frames/bricks_source_local_custom_property_resolver_test.exs`. Expected: the new tests fail on missing scope and dependency classification while Task 1 tests remain green.
- [ ] **Step 3: Implement bounded classification only.** Add no recursive substitution. For a responsive reference, first select the direct-target or nearest-ancestor relation, then inspect that relation for an eligible responsive definition in the exact responsive viewport scope. If one exists, fail `UNSUPPORTED_SCOPE` before considering a base definition. Do not resolve responsive definitions or compare media ranges. Reject state transitions. Inspect `VariableAuthority.resolve/2` only for candidate presence, then discard its candidate data. Detect self edges and cycles with a bounded graph of at most 256 definitions and 1,024 edges. Reject fallback and all other downstream dependencies with their exact states.
- [ ] **Step 4: Run resolver tests and observe GREEN.** Run `mix test apps/live_frames/test/live_frames/bricks_source_local_custom_property_resolver_test.exs`. Expected: Task 1 and Task 2 tests pass; no terminal is expanded recursively.
- [ ] **Step 5: Commit Task 2.** Run `git diff --check`, stage only the resolver and resolver test, then create one signed commit: `feat: enforce local resolver scope and dependency limits`.

## Task 3: CustomCssNormalizer integration

**Files:**
- Modify `apps/live_frames/lib/live_frames/adapters/bricks/custom_css_normalizer.ex`.
- Modify `apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`.

**Interface:** Keep the existing `CustomCssNormalizer.normalize/5` entry point, parser, selector grammar, `StylePrecedence`, `VariableAuthority`, `CSSDeclaration`, Design IR, and output types unchanged. Call the resolver once per owner and exact provenance batch and zip results to private `{rule_id, target_source_id, selector_identity, property}` metadata.

- [ ] **Step 1: Add integration tests and observe RED.** Add synthetic tests before production changes:
  - `test "resolves a direct local reference to an ordinary literal style"`: local definition plus direct consumer yields `%StyleValue{kind: :literal, value: "12px"}`; no custom-property style or custom-property definition remains in output.
  - `test "resolves a base definition for a responsive consumer"`: the ordinary resolved value appears in the existing responsive override.
  - `test "resource-limited resolver batch keeps its entire owner provenance scope residual"`: generate more than 1,024 eligible direct references within the CSS byte limit; on top-level `{:error, :resource_limit_exceeded}`, emit no normalized output from the affected owner/provenance batch, preserve the affected source as residual, expose the state only as stable diagnostic metadata, and route no local reference to `VariableAuthority`.
  - `test "unsupported local definition blocks external VariableAuthority fallback"`: an unsupported-selector rule containing both a local definition and an ordinary declaration cannot emit either declaration; with a populated external authority for the exact name, the consumer has no `token_ref`, retains `"unresolved_value"`, and has no normalized property style.
  - `test "keeps external VariableAuthority resolution when no local definition exists"`: a direct reference with no exact local definition follows the existing external path and yields its existing token reference.
  - `test "different selector identities remain ambiguous for equal local terminals"`: a direct consumer remains unresolved when two selector identities target the same definition node with equal values.
  - `test "an exact responsive definition prevents base fallback"`: the responsive consumer remains unresolved with `"unresolved_value"`.
  - `test "one failed target keeps a multi-target rule wholly residual"`: no target receives a style from the rule and the original rule is retained as residual.
  - `test "revalidates a resolved terminal with existing property and value safety"`: a local terminal rejected by consumer safety remains residual with `"unresolved_value"`; no raw terminal reaches a `StyleValue`.
  - `test "leaves compound var expressions residual"`: a consumer such as a mixed token-and-literal value does not enter the resolver and remains residual.
  - `test "rejects effective CSS above 65536 bytes before parsing"`: the size-limit diagnostic is recorded before parser output can be consumed, no style is emitted, and source text remains residual under the existing residual reason contract.
  - `test "canonicalizes class order only inside a selector compound"`: `.owner.a.b` and `.owner.b.a` definitions have equal internal identity and identical terminals coalesce; changing descendant compound order keeps identities distinct.
  - `test "does not change residual identity for local resolution failures"`: reason and raw source inputs match the pre-existing unresolved residual contract.
- [ ] **Step 2: Run the normalizer test file and observe RED.** Run `mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`. Expected: new local resolution assertions fail against the current external-only direct-variable path; existing normalizer assertions remain green.
- [ ] **Step 3: Add selector identity and bounded record collection.** Preserve the accepted parsed selector group. Canonicalize class order and duplicates inside each compound, preserve descendant order, and retain parsed marker and condition. Keep raw selector text out of resolver records. Derive exact provenance from the existing selected owner provenance fields. Check the 65,536-byte limit before `CustomCssParser.parse/1`.
- [ ] **Step 4: Collect observed and eligible local definitions separately.** Collect exact local definition names from safely parsed selected CSS before selector eligibility can discard a definition. Create definition records only after the existing selector matcher proves target and path inside the current owner subtree. Create reference records only for the existing exact direct `var(--name)` form. Retain normalizer-private correlation metadata outside the resolver. Count the resulting post-selector records against the 256 definition and 1,024 reference limits for the owner/provenance batch.
- [ ] **Step 5: Resolve once, revalidate, and preserve atomicity.** Send one definition/reference batch for each owner and exact provenance identity, including the already selected base and responsive records for that identity. Use the external authority only for collision presence on the local lane. After a successful terminal, run the existing declaration check and value normalization with source-resolver origin. A local-lane failure never calls the external substitution path. If `resolve/3` returns `{:error, :resource_limit_exceeded}`, emit no normalized output from the affected owner/provenance batch; preserve its affected source as residual; expose `RESOURCE_LIMIT_EXCEEDED` only as stable diagnostic state/metadata; do not consume the first permitted records partially or route any local reference to `VariableAuthority`. Keep the existing canonical residual identity. Consume definition declarations as compiler inputs only. If any target or declaration fails, discard all normalized output for that selector rule and retain the rule with its existing `unresolved_value` residual identity.
- [ ] **Step 6: Run the normalizer test file and observe GREEN.** Run `mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`. Expected: all new cases and existing selector, responsive, residual, and state tests pass.
- [ ] **Step 7: Commit Task 3.** Run `git diff --check`, stage only the normalizer and its existing test file, then create one signed commit: `feat: integrate local custom property resolution`.

## Task 4: regression, repository gates, and implementation PR

**Files:**
- No production or test file beyond the four files listed above.
- Review the exact four-file implementation diff before opening the implementation PR.

- [ ] **Step 1: Run both focused suites.** Run:
  - `mix test apps/live_frames/test/live_frames/bricks_source_local_custom_property_resolver_test.exs`
  - `mix test apps/live_frames/test/live_frames/bricks_custom_css_normalizer_test.exs`
  Expected: both pass.
- [ ] **Step 2: Run repository gates.** Run `mix deps.get`, `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix assets.build`, `mix test`, `mix deps.unlock --check-unused`, and `git diff --check`. Also run:

  ```sh
  git diff --exit-code -- \
    apps/live_frames/assets/css/theme/lf_theme.css \
    apps/live_frames/priv/static/live_frames/css/live_frames.css
  ```

  Expected: every command exits successfully, generated styling artifacts remain unchanged, and no gate is hidden or weakened. Report skipped commands with their reason. Do not run a Romeo canonical rerun.
- [ ] **Step 3: Review scope and history.** Confirm the implementation diff contains exactly the four allowed implementation/test files, no private source data, no dependency changes, and signed commits. Confirm the current `main` has no material conflict in the resolver authority or those four files. Stop on a full-suite failure, unexpected file, private-source publication risk, or material conflict.
- [ ] **Step 4: Open the implementation PR without merging.** Include the exact head SHA, tree, focused results, all repository gate results, branch, commit signatures, and CI evidence. Register the PR with the current T3 thread immediately after creation. Do not merge it and do not run the private Romeo canonical rerun.

## Review focus

The reviewer should verify these five high-risk cases directly:

1. An unsupported or ineligible local definition blocks external fallback for the same exact name.
2. Different selector identities at one target remain ambiguous even when terminal text matches.
3. An exact responsive definition prevents silent fallback to a base definition.
4. One failed target in a multi-target rule prevents partial output for that rule.
5. A resolved terminal that fails the consumer property's existing safety or value normalization remains residual.

Also verify that definitions never enter IR or generated CSS, the external path remains available only when no exact local definition was observed, source order never selects a winner, ancestry uses structural path components, and residual identity stays stable.

## Stops and next gates

```text
STOP=MAIN_MOVED_WITH_MATERIAL_LOCAL_RESOLVER_CONFLICT
STOP=PLAN_SCOPE_EXPANDED
STOP=IMPLEMENTATION_FILE_CHANGED
STOP=TEST_FILE_CHANGED
STOP=IMPLEMENTATION_STARTED
STOP=RESOURCE_BOUND_WEAKENED
STOP=BATCH_IDENTITY_REMAINS_INFERRED
STOP=RESPONSIVE_BASE_FALLBACK_REMAINS_AMBIGUOUS
STOP=AUTHORITY_CHANGED
STOP=PLANNED_IMPLEMENTATION_BOUNDARY_EXPANDED
STOP=POST_MERGE_EXACT_SHA_CI_NOT_SUCCESS
STOP=CUSTOM_CSS_PARSER_CHANGE_REQUIRED
STOP=STYLE_PRECEDENCE_CHANGE_REQUIRED
STOP=VARIABLE_AUTHORITY_CHANGE_REQUIRED
STOP=DESIGN_IR_CHANGE_REQUIRED
STOP=NATIVE_GENERATOR_CHANGE_REQUIRED
STOP=SELECTOR_GRAMMAR_EXPANSION_REQUIRED
STOP=GENERAL_CASCADE_ENGINE_REQUIRED
STOP=CSS_COMPOUND_VALUE_IMPLEMENTATION_STARTED
STOP=ROMEO_CANONICAL_RERUN_STARTED
STOP=ROMEO_COMPONENTIZATION_STARTED
STOP=ROMEO_NATIVE_GENERATION_STARTED
STOP=TDD_RED_NOT_OBSERVED
STOP=FULL_SUITE_FAILURE
STOP=PRIVATE_SOURCE_PUBLICATION_RISK
```

The `POST_MERGE_EXACT_SHA_CI_NOT_SUCCESS` stop is inactive because run `39202214865` is successful on `3dd020cd3d5922ab38ede7c70ce8c5b4a4c7963d`. Reapply that stop if the recorded exact-SHA result is not successful when implementation preflight runs. `IMPLEMENTATION_EXECUTION_AUTHORIZED` remains `NO` until independent review of this plan and explicit authorization. After the implementation PR is accepted and merged, use a separate gate to authorize any Romeo canonical rerun.

```text
IMPLEMENTATION_FILE_COUNT=4
IMPLEMENTATION_PLAN_AUTHORIZED=YES
IMPLEMENTATION_EXECUTION_AUTHORIZED=NO
NEXT_GATE=INDEPENDENT_REVIEW_CSS_LOCAL_CUSTOM_PROPERTY_RESOLVER_IMPLEMENTATION_PLAN
AFTER_IMPLEMENTATION_ACCEPTANCE=INDEPENDENT_REVIEW_CSS_LOCAL_CUSTOM_PROPERTY_RESOLVER_IMPLEMENTATION
ROMEO_CANONICAL_RERUN_IN_THIS_TASK=NO
```
