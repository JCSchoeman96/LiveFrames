# Bricks Execution-Security Sanitization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent admitted Bricks executable-source bodies and execution-authenticator metadata from entering ordinary Stage A and Design IR representations while preserving exact original source identity and the bounded private Code recognizer input.

**Architecture:** Preserve Loader output and original source bytes as the private source model. Derive a separate sanitized ordinary-consumer Document by surgically removing only admitted execution-security fields from typed and raw mirrors, fail closed on remaining unclassified signature keys, then route ordinary consumers through that view while keeping explicitly authorized private Code recognizer input separate.

**Tech Stack:** Elixir, ExUnit, LiveFrames Bricks adapter.

**Spec:** `docs/development/bricks_execution_security_metadata_retention_authority.md`

Also consult:

- `docs/development/bricks_preclassification_loader_diagnostic_privacy_authority.md`
- `docs/superpowers/specs/2026-10-22-executable-source-semantic-translation-design.md`

## Scope and prerequisites

This plan covers the bounded sanitization programme in Tasks 1 through 4. Do not begin Task 1 until this plan is reviewed, merged, and its post-merge CI is green. Do not combine Tasks 1 through 4 into one implementation PR. Do not implement any task during this docs-only publication.

Before each implementation task, fetch origin/main and verify that the accepted authority and relevant Bricks production or test files have not changed since the task's authorized base. If main moved, inspect the delta. Stop with STOP=MAIN_MOVED_WITH_RELEVANT_OVERLAP if it touches any of these paths:

~~~~text
apps/live_frames/lib/live_frames/adapters/bricks/
apps/live_frames/test/live_frames/bricks_*
docs/development/bricks_execution_security_metadata_retention_authority.md
docs/development/bricks_preclassification_loader_diagnostic_privacy_authority.md
docs/superpowers/specs/2026-10-22-executable-source-semantic-translation-design.md
~~~~

Unrelated Milan, Fluid, CSS, componentization, and other programme changes do not block this work. Require green CI for the current main commit before starting an implementation task.

The Loader pre-classification privacy fix is a completed prerequisite. Record it as evidence and do not reimplement it:

~~~~text
PR307_APPROVED_HEAD=6bf0beff1e485c2ab75f9420b3f510bc84203b19
PR307_MERGE_SHA=0ea7af94e044525b91bccba0967f248b3ea2b6a8
PR307_POST_MERGE_CI_RUN=39949991798
PR307_POST_MERGE_CI_RESULT=success
~~~~

Do not touch the preserved Task 0 characterization worktree or recreate Task 0.

## Global invariants

Every implementation task must preserve these invariants:

~~~~text
SOURCE_HASH_INPUT=ORIGINAL_UNMODIFIED_SOURCE_BYTES
PRIVATE_DOCUMENT_MUTATED=NO

ADMITTED_SIGNATURE_CONTEXTS=
  CODE_EXECUTION_SIGNATURE
  QUERY_EDITOR_SIGNATURE

KNOWN_UNADMITTED_CONTEXTS=
  SVG_SOURCE_CODE
  COMPONENT_QUERY_PROPERTIES
  GLOBAL_QUERY_RECORDS

UNKNOWN_EXECUTION_LIKE_CONTEXT_POLICY=FAIL_CLOSED

GLOBAL_SIGNATURE_DELETE=FORBIDDEN
GENERIC_SECRET_DETECTOR=FORBIDDEN
WORDPRESS_SIGNATURE_VALIDATION=FORBIDDEN

DIRECT_SIGNATURE_DERIVATIVE=FORBIDDEN
SAFE_RETAINED_SIGNATURE_FACT=NONE

QUERY_EDITOR_BODY_FINGERPRINT=FORBIDDEN
EXISTING_APPROVED_CODE_BODY_FINGERPRINT=ALLOWED

PRIVATE_TEMPLATE_FIXTURE_IN_REPOSITORY=NO
PHP_EXECUTION=NO
QUERY_EDITOR_EXECUTION=NO

DATA_LAYER=COLD_BUILD_TIME
~~~~

Performance review:

~~~~text
REDIS=NOT_APPLICABLE
ETS=NOT_APPLICABLE
CACHEX=NOT_APPLICABLE
GENSERVER=NOT_APPLICABLE
PUBSUB=NOT_APPLICABLE
OBAN=NOT_APPLICABLE
POSTGRES=NOT_APPLICABLE
NETWORK=NOT_APPLICABLE
~~~~

Keep implementation deterministic. Traverse only the bounded imported source data. Do not add runtime services, network access, caching, or database work.

## Task 1: standalone sanitizer

This is the first implementation PR. At the end of Task 1 implementation, leave its PR open and unmerged. Merge requires exact-head independent review and separate merge authorization.

Files:

~~~~text
Create: apps/live_frames/lib/live_frames/adapters/bricks/execution_security_sanitizer.ex
Test:   apps/live_frames/test/live_frames/bricks_execution_security_sanitizer_test.exs
~~~~

Expose this interface:

~~~~elixir
ExecutionSecuritySanitizer.sanitize(document)
  -> {:ok, sanitized_document}
  | {:error, diagnostics}
~~~~

Input is the private Loader Document. Return a separate sanitized ordinary-consumer Document. Never mutate the input.

### Code execution body and signature

Recognize a Code executable body only when all three conditions hold:

~~~~text
element.name == "code"
settings.executeCode == true
settings.code is binary
~~~~

Remove settings.code from the ordinary view even when no signature exists.

Recognize a Code execution signature only when all of these conditions hold:

~~~~text
element.name == "code"
settings.executeCode == true
settings.code is binary
settings.signature is binary
byte_size(settings.signature) == 32
~~~~

Remove settings.signature from the ordinary view when the signature matches that admitted shape. Fail closed when a signature is present in this execution-like Code context but its shape is malformed. Do not inspect its contents or infer validity.

### Query Editor body and signature

Recognize a Query Editor body only when all of these conditions hold:

~~~~text
settings.query is map
settings.query.useQueryEditor == true
settings.query.queryEditor is binary
~~~~

Remove settings.query.queryEditor from the ordinary view.

Recognize a Query Editor signature only when all of these conditions hold:

~~~~text
settings.query is map
settings.query.useQueryEditor == true
settings.query.queryEditor is binary
settings.query.signature is binary
byte_size(settings.query.signature) == 32
~~~~

Remove settings.query.signature from the ordinary view when it matches that admitted shape. Fail closed when a signature is present in this execution-like Query Editor context but its shape is malformed. Do not inspect its contents or infer validity.

### Typed and raw mirror handling

Sanitize the same admitted fields across:

~~~~text
Element.settings
Element.raw

Component.elements
Component.raw

Document.components
Document.raw
~~~~

Copy original raw maps, remove only admitted execution-security fields, and replace only nested element collections with sanitized raw equivalents. Preserve unrelated raw fields exactly. Never reconstruct raw maps from typed structs. A raw map may hold ordinary Bricks fields that the typed structs do not model.

### Unknown signature guard

After admitted sanitization, recursively inspect the full ordinary source and raw graph for the exact map key signature. If any such key remains, return an error and do not delete or reinterpret it. The error must not include the signature value, a fragment, presence fact, hash, fingerprint, or any other derivative. Keep the original private evidence unchanged.

### Task 1 tests and TDD order

Use synthetic public-safe fixtures only. Use arbitrary synthetic 32-byte binaries. Do not copy real signature values or put Template 124/Product 767 source in the repository.

For each behavioral group below, write the failing test first, run the focused test and confirm the expected failure, add the smallest implementation that makes that group pass, then rerun the focused test. Keep each red-to-green cycle separate.

~~~~text
CODE_BODY_REMOVED_WITHOUT_SIGNATURE
CODE_BODY_AND_VALID_SIGNATURE_REMOVED
CODE_MALFORMED_SIGNATURE_FAILS_CLOSED

QUERY_BODY_REMOVED_WITHOUT_SIGNATURE
QUERY_BODY_AND_VALID_SIGNATURE_REMOVED
QUERY_MALFORMED_SIGNATURE_FAILS_CLOSED

NON_SECURITY_SIBLING_SETTINGS_PRESERVED

RAW_ELEMENT_MIRROR_SANITIZED
RAW_COMPONENT_MIRROR_SANITIZED
RAW_DOCUMENT_MIRROR_SANITIZED

PRIVATE_INPUT_UNCHANGED
SOURCE_HASH_UNCHANGED

UNKNOWN_SIGNATURE_CONTEXT_FAILS_CLOSED

ORDINARY_NON_SECURITY_FIELDS_EXACTLY_PRESERVED
DETERMINISTIC_SANITIZED_OUTPUT
~~~~

The raw mirror tests must inspect each typed and raw level, including nested component element collections. The preservation tests must compare unrelated raw fields exactly. The source identity test must prove that the existing source hash still uses the original bytes. The unknown-context test must prove the key remains in private evidence, conversion fails closed, and neither the ordinary result nor returned diagnostics contain the value or a derivative.

Run the focused sanitizer test file after each red-to-green group and run the relevant Bricks tests before opening the Task 1 PR. Do not weaken or skip a failing test to get green.

### Task 1 execution checklist

Use a synthetic document whose typed elements and raw maps mirror the same Code and Query Editor fields. Put at least one unrelated field that is absent from the typed structs in each raw mirror. Use a synthetic signature such as `:binary.copy("s", 32)`.

- [ ] **Step 1: Add the Code body and signature tests.** Add CODE_BODY_REMOVED_WITHOUT_SIGNATURE, CODE_BODY_AND_VALID_SIGNATURE_REMOVED, CODE_MALFORMED_SIGNATURE_FAILS_CLOSED, and NON_SECURITY_SIBLING_SETTINGS_PRESERVED. Keep the executable body a harmless synthetic string.
- [ ] **Step 2: Run the sanitizer test file and confirm RED.** Run `mix test apps/live_frames/test/live_frames/bricks_execution_security_sanitizer_test.exs`. The new Code assertions must fail because the sanitizer does not yet return the required ordinary view.
- [ ] **Step 3: Implement the smallest Code sanitizer path.** Copy the Document and its typed/raw element maps. Remove only the admitted Code body and valid execution signature from the copy. Return a fixed diagnostic for malformed execution signatures without copying the signature value or a derivative.
- [ ] **Step 4: Rerun the sanitizer test file and confirm GREEN for the Code group.** Run `mix test apps/live_frames/test/live_frames/bricks_execution_security_sanitizer_test.exs`. The Code tests must pass; no Query Editor behavior is required by this group.
- [ ] **Step 5: Add the Query Editor body and signature tests.** Add QUERY_BODY_REMOVED_WITHOUT_SIGNATURE, QUERY_BODY_AND_VALID_SIGNATURE_REMOVED, and QUERY_MALFORMED_SIGNATURE_FAILS_CLOSED using a separate synthetic Document.
- [ ] **Step 6: Run the sanitizer test file and confirm RED for the Query Editor group.** Run `mix test apps/live_frames/test/live_frames/bricks_execution_security_sanitizer_test.exs`. The new Query Editor assertions must fail before Query Editor handling is added.
- [ ] **Step 7: Implement the smallest Query Editor sanitizer path.** Copy the nested query map and remove only queryEditor and a valid signature under the admitted guard. Return a fixed diagnostic for malformed execution signatures.
- [ ] **Step 8: Rerun the sanitizer test file and confirm GREEN for the Query Editor group.** Run `mix test apps/live_frames/test/live_frames/bricks_execution_security_sanitizer_test.exs`.
- [ ] **Step 9: Add raw mirror and exact-preservation tests.** Add RAW_ELEMENT_MIRROR_SANITIZED, RAW_COMPONENT_MIRROR_SANITIZED, RAW_DOCUMENT_MIRROR_SANITIZED, and ORDINARY_NON_SECURITY_FIELDS_EXACTLY_PRESERVED. Assert the unmodeled raw-only fields retain their exact values.
- [ ] **Step 10: Run the sanitizer test file and confirm RED for raw mirrors.** Run `mix test apps/live_frames/test/live_frames/bricks_execution_security_sanitizer_test.exs`. Each failing assertion must identify a raw mirror that still contains an admitted field or lost an unrelated field.
- [ ] **Step 11: Implement raw mirror copying.** Copy each original raw map, replace only the nested sanitized element collections, and preserve all other keys. Do not build a raw map from a typed struct.
- [ ] **Step 12: Rerun the sanitizer test file and confirm GREEN for raw mirrors.** Run `mix test apps/live_frames/test/live_frames/bricks_execution_security_sanitizer_test.exs`.
- [ ] **Step 13: Add immutability, identity, unknown-context, and determinism tests.** Add PRIVATE_INPUT_UNCHANGED, SOURCE_HASH_UNCHANGED, UNKNOWN_SIGNATURE_CONTEXT_FAILS_CLOSED, and DETERMINISTIC_SANITIZED_OUTPUT. Assert the original Document equals its pre-call copy and that unknown signature evidence remains only in that private input.
- [ ] **Step 14: Run the sanitizer test file and confirm RED for the remaining guards.** Run `mix test apps/live_frames/test/live_frames/bricks_execution_security_sanitizer_test.exs`. Confirm the failures expose missing guards and do not print test signature values.
- [ ] **Step 15: Implement the fail-closed scan and final immutability handling.** After admitted removals, scan the full ordinary typed/raw graph for the exact key signature. Return an opaque diagnostic if one remains. Keep source_hash and the private input unchanged.
- [ ] **Step 16: Rerun the sanitizer test file and confirm GREEN.** Run `mix test apps/live_frames/test/live_frames/bricks_execution_security_sanitizer_test.exs`. All Task 1 cases must pass, including exact ordinary-field preservation and deterministic output.
- [ ] **Step 17: Run relevant existing Bricks tests.** Run `mix test apps/live_frames/test/live_frames/bricks_adapter_test.exs apps/live_frames/test/live_frames/bricks_executable_source_semantic_translator_test.exs`. Confirm the Loader model and approved private Code recognizer behavior remain intact.
- [ ] **Step 18: Run applicable repository gates, review the exact diff, and create a signed Task 1 commit.** Keep the PR limited to the sanitizer module and its focused test file. Open the PR and stop with it unmerged for exact-head independent review and merge authorization.

Stop Task 1 if any of these conditions applies:

~~~~text
STOP=SANITIZER_REQUIRES_SOURCE_HASH_RECOMPUTATION
STOP=GLOBAL_SIGNATURE_DELETE_REQUIRED
STOP=THIRD_EXECUTION_CONTEXT_REQUIRED
STOP=PRIVATE_SOURCE_MUTATION_REQUIRED
STOP=RAW_MAP_RECONSTRUCTION_REQUIRED
STOP=SIGNATURE_DERIVATIVE_REQUIRED
STOP=WORDPRESS_RUNTIME_OR_SECRET_REQUIRED
STOP=PRIVATE_TEMPLATE_FIXTURE_REQUIRED
STOP=PHP_EXECUTION_REQUIRED
STOP=QUERY_EDITOR_EXECUTION_REQUIRED
STOP=THREE_FAILED_FIX_ATTEMPTS
~~~~

## Task 2: Design IR integration

Plan this as a separate implementation PR after Task 1 has merged with green post-merge CI.

Files expected:

~~~~text
apps/live_frames/lib/live_frames/adapters/bricks/design_ir_normalizer.ex
apps/live_frames/lib/live_frames/adapters/bricks/frontend_binding_normalizer.ex
relevant Design IR and executable-source tests
~~~~

Route ordinary consumers through the sanitized Document:

~~~~text
Loader
  -> PRIVATE Document
  -> ExecutionSecuritySanitizer
      -> ORDINARY sanitized Document

ORDINARY Document
  -> Resolver
  -> TreeBuilder
  -> ClassResolver
  -> DependencyExtractor
  -> SourceTrace
  -> diagnostics
  -> provenance
  -> Design IR
~~~~

Keep the existing bounded private Code recognizer input on its separate private path:

~~~~text
PRIVATE Document/tree
  -> only the existing bounded approved Code semantic recognizer
~~~~

The private tree must never become the ordinary consumer tree. Query Editor bodies must never become semantic input. Preserve these dispositions:

~~~~text
CODE3=NORMALIZED
CODE1=PRESERVED_UNSUPPORTED
CODE2=PRESERVED_UNSUPPORTED
~~~~

Use TDD for the integration. Add tests for the authority's required coverage:

~~~~text
T1_CODE_SIGNATURE_SUCCESS_PATH
T2_QUERY_EDITOR_SIGNATURE_SUCCESS_PATH
T3_BLOCKING_ERROR_PATH
T4_UNKNOWN_SIGNATURE_CONTEXT_FAILS_CLOSED
T6_SOURCE_IDENTITY
T7_DETERMINISM
T8_EXISTING_EXECUTABLE_BODY_PRIVACY
T9_CLASSIFIED_SIGNATURE_DIAGNOSTIC_SUPPRESSION
~~~~

Prove that the Code recognizer can still use its approved private body while ordinary consumers cannot see that body. Prove that no Query Editor body or signature reaches ordinary semantic, dependency, trace, diagnostic, provenance, or Design IR paths. Prove that classified signatures do not become unsupported-setting diagnostics:

~~~~text
CLASSIFIED_EXECUTION_SIGNATURE_IS_UNSUPPORTED_SETTING=NO
CLASSIFIED_EXECUTION_SIGNATURE_EMITS_UNSUPPORTED_SETTING_DIAGNOSTIC=NO
~~~~

Keep the Task 2 PR limited to Design IR integration and its relevant tests. Do not implement Stage A integration in this task.

### Task 2 execution checklist

- [ ] **Step 1: Add failing Design IR success-path tests.** Cover T1_CODE_SIGNATURE_SUCCESS_PATH and T2_QUERY_EDITOR_SIGNATURE_SUCCESS_PATH with synthetic Documents. Inspect serialized Design IR, raw maps, traces, dependencies, diagnostics, and provenance for body, signature, and derivative leaks.
- [ ] **Step 2: Run the focused Design IR and executable-source tests and confirm RED.** Run `mix test apps/live_frames/test/live_frames/bricks_design_ir_test.exs apps/live_frames/test/live_frames/bricks_frontend_binding_test.exs apps/live_frames/test/live_frames/bricks_executable_source_semantic_translator_test.exs`. Confirm the new assertions expose the unsanitized ordinary path.
- [ ] **Step 3: Route ordinary Design IR consumers through the sanitizer.** Keep the private input available only to the existing approved Code recognizer. Build Resolver, TreeBuilder, ClassResolver, DependencyExtractor, SourceTrace, diagnostics, provenance, and Design IR from the sanitized Document.
- [ ] **Step 4: Rerun the focused Design IR and executable-source tests.** Run the same three test files. Confirm CODE3=NORMALIZED, CODE1 and CODE2 remain PRESERVED_UNSUPPORTED, and ordinary output contains no admitted body or signature.
- [ ] **Step 5: Add failing blocking-path, unknown-context, identity, determinism, and diagnostic-suppression tests.** Cover T3_BLOCKING_ERROR_PATH, T4_UNKNOWN_SIGNATURE_CONTEXT_FAILS_CLOSED, T6_SOURCE_IDENTITY, T7_DETERMINISM, T8_EXISTING_EXECUTABLE_BODY_PRIVACY, and T9_CLASSIFIED_SIGNATURE_DIAGNOSTIC_SUPPRESSION.
- [ ] **Step 6: Run the focused tests and confirm RED for the uncovered paths.** Use the same focused command. Confirm the failing assertions identify contaminated diagnostics, a changed hash, a lost private Code input, or an emitted classified-signature diagnostic.
- [ ] **Step 7: Fix only the failing Design IR integration paths.** Keep Query Editor bodies out of semantic input and keep classified signatures out of unsupported-setting diagnostics. Do not patch downstream report serialization as the privacy boundary.
- [ ] **Step 8: Rerun the focused tests and confirm GREEN.** Run the same focused command, then applicable repository gates. Review the diff and create a signed Task 2 PR with no Stage A changes.

## Task 3: Stage A integration

Plan this as a separate implementation PR after Task 2 has merged with green post-merge CI.

After Loader success, Stage A must pass a private Document through the sanitizer and keep the sanitized ordinary Document separate:

~~~~text
private Document
-> sanitizer
-> sanitized ordinary Document
~~~~

The public Stage A Result.document must be sanitized. Do not expose the private Loader Document through Stage A. Use the sanitized source for every ordinary consumer:

~~~~text
Resolver
TreeBuilder
ClassResolver
DependencyExtractor
renderer
Report.build
report.json
~~~~

Use TDD to prove that admitted bodies and signatures are absent from all these returned surfaces:

~~~~text
Result.document
Result.component
Result.tree
Result.dependencies

report map
index.html
styles.css
report.json

settings_unsupported
runtime_dependencies
diagnostics
source_trace
unsupported_elements
~~~~

Also prove that identity still uses the original unmodified source bytes and that blocking/error paths cannot return contaminated ordinary output. Do not patch Report as the primary privacy boundary. Keep Task 3 limited to Stage A integration and its tests.

### Task 3 execution checklist

- [ ] **Step 1: Add failing Stage A success and error-path assertions.** Use synthetic imported source and assert body and signature absence from Result.document, Result.component, Result.tree, Result.dependencies, report maps, index.html, styles.css, report.json, settings_unsupported, runtime_dependencies, diagnostics, source_trace, and unsupported_elements.
- [ ] **Step 2: Run the Stage A tests and confirm RED.** Run `mix test apps/live_frames/test/live_frames/bricks_stage_a_test.exs apps/live_frames/test/live_frames/bricks_result_lifecycle_test.exs`. Confirm public Stage A output currently reaches at least one assertion with the admitted body or signature.
- [ ] **Step 3: Sanitize after Loader success and before Stage A ordinary consumers.** Keep the private Loader Document separate. Route all ordinary consumers through the sanitized Document and return only sanitized public fields.
- [ ] **Step 4: Rerun the Stage A tests and confirm GREEN.** Run the same two test files. Confirm both success and blocking/error results omit the admitted fields while identity still uses the original bytes.
- [ ] **Step 5: Run applicable repository gates and review the exact diff.** Keep the PR limited to Stage A integration and its tests. Create a signed Task 3 PR, then require exact-head independent review, merge authorization, merge, and green post-merge CI.

## Task 4: final gates and private acceptance

Plan this as a separate implementation PR after Task 3 has merged with green post-merge CI.

Run the repository gates:

~~~~sh
mix format --check-formatted
mix compile --warnings-as-errors
mix assets.build
mix test
mix deps.unlock --check-unused
git diff --check
~~~~

After those gates pass, run the private Template 124 acceptance out of band. Do not add its source to the repository or execute imported source:

~~~~text
PRIVATE_SIGNATURE_COUNT=4
ORDINARY_IR_RAW_SIGNATURE_HITS=0

SOURCE_ELEMENT_COUNT=82
IR_NODE_COUNT=82
ROOT_COUNT=5

CODE1=PRESERVED_UNSUPPORTED
CODE2=PRESERVED_UNSUPPORTED
CODE3=NORMALIZED

SOURCE_CODE_EXECUTED=NO
QUERY_EDITOR_BODY_ORDINARY_HITS=0
~~~~

Do not pin the historical DesignDocument digest. Privacy sanitization intentionally changes diagnostics, provenance, and serialized bytes. Only after this private acceptance passes may the blocked canonical-ingestion authority be revisited.

### Task 4 execution checklist

- [ ] **Step 1: Run every repository gate.** Run each command in the gate block above from the umbrella root and record its exit result. Fix failures only within Task 4 scope.
- [ ] **Step 2: Run the private acceptance out of band.** Verify each listed count, body-privacy assertion, Code disposition, and no-execution assertion against the private source without copying that source into the repository.
- [ ] **Step 3: Recheck the privacy and identity invariants.** Confirm the ordinary IR has zero raw signature hits, Query Editor body hits remain zero, and the source hash uses original bytes.
- [ ] **Step 4: Review the exact diff and create a signed Task 4 PR.** Do not pin the historical DesignDocument digest or publish the blocked canonical-ingestion authority as part of this PR. Require exact-head independent review, merge authorization, merge, and green post-merge CI.

## Sequential authorization and PR gates

Freeze these dependencies:

~~~~text
PROGRAMME_IMPLEMENTATION_AUTHORIZED=YES

TASK1_EXECUTION_AFTER_PLAN_ACCEPTANCE=YES

TASK2_EXECUTION_REQUIRES_TASK1_MERGED_GREEN=YES
TASK3_EXECUTION_REQUIRES_TASK2_MERGED_GREEN=YES
TASK4_EXECUTION_REQUIRES_TASK3_MERGED_GREEN=YES

COMPONENTIZATION_AUTHORIZED=NO
CANONICAL_INGESTION_PUBLICATION_AUTHORIZED=NO
~~~~

Do not combine Tasks 1 through 4 into one implementation PR. For every implementation task, require this sequence:

1. TDD red-to-green cycles.
2. Targeted verification, followed by every applicable repository gate.
3. A signed PR limited to that task.
4. Exact-head independent review.
5. Merge authorization, then merge.
6. Green post-merge CI before authorizing the next task.

Task 1 must stop with its own PR open and unmerged until review and merge authorization. Do not start Task 2 before Task 1 is merged and green, or Task 3 before Task 2 is merged and green, or Task 4 before Task 3 is merged and green.

## Highest-risk failures and required tests

| Risk | Owning task | Required test |
| --- | --- | --- |
| Typed settings are sanitized but Element.raw still leaks security fields. | Task 1 | RAW_ELEMENT_MIRROR_SANITIZED |
| Component.raw or Document.raw retains nested unsanitized element maps. | Task 1 | RAW_COMPONENT_MIRROR_SANITIZED and RAW_DOCUMENT_MIRROR_SANITIZED |
| An unknown signature context is silently deleted instead of failing closed. | Task 1 | UNKNOWN_SIGNATURE_CONTEXT_FAILS_CLOSED |
| Sanitization changes the source bytes or hash used for identity. | Tasks 1 and 2 | SOURCE_HASH_UNCHANGED and T6_SOURCE_IDENTITY |
| Code body is removed before the approved private semantic recognizer can use it. | Task 2 | CODE3 remains NORMALIZED from the private Code recognizer input while ordinary surfaces contain no body |
| Raw-map reconstruction drops unknown ordinary Bricks fields. | Task 1 | ORDINARY_NON_SECURITY_FIELDS_EXACTLY_PRESERVED |
| Query Editor body or signature survives through dependency or diagnostic paths. | Tasks 2 and 3 | T2_QUERY_EDITOR_SIGNATURE_SUCCESS_PATH, T3_BLOCKING_ERROR_PATH, and the Task 3 ordinary-surface absence checks |

## Global stop conditions

Stop the affected task and report the exact stop code if any of these conditions applies:

~~~~text
STOP=MAIN_MOVED_WITH_RELEVANT_OVERLAP
STOP=AUTHORITY_CONFLICT

STOP=SANITIZED_BYTES_REQUIRED_FOR_SOURCE_HASH
STOP=PRIVATE_SOURCE_MODEL_MUST_BE_MUTATED

STOP=GLOBAL_SIGNATURE_DELETE_REQUIRED
STOP=UNADMITTED_BRICKS_CONTEXT_REQUIRED
STOP=FABRICATED_ORDINARY_SIGNATURE_SCHEMA

STOP=WORDPRESS_RUNTIME_OR_SECRET_REQUIRED
STOP=PHP_EXECUTION_REQUIRED
STOP=QUERY_EDITOR_EXECUTION_REQUIRED

STOP=CODE3_REGRESSION
STOP=CODE1_OR_CODE2_REGRESSION

STOP=STAGE_A_PRIVATE_RAW_REQUIRED_IN_ORDINARY_OUTPUT

STOP=PRIVATE_TEMPLATE_SOURCE_ADDED_TO_REPOSITORY

STOP=GENERIC_SECRET_DETECTOR_PROPOSED
STOP=GLOBAL_LOADER_RAW_VALUE_DELETION_PROPOSED_WITHOUT_AUTHORITY

STOP=THREE_FAILED_FIX_ATTEMPTS
~~~~
