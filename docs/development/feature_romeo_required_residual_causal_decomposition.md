# Feature Romeo Required Residual Causal Decomposition

Status: diagnostic evidence only. No production code, tests, generated output, or componentization changed.

## Entry Authority

- BASE_SHA=a4804640cb297f87e6d400b833e11699a99069fd
- BASE_TREE=720069caf357e3b054793c438240b21ef442d998
- BASE_CI=success (LiveFrames CI run 39782195063 on BASE_SHA)
- PR286=MERGED, number 286, merge commit BASE_SHA, merged 2026-10-22T12:54:04Z, head 7ce379498ebcdc955fcad8c638cb6744026dc500
- PR286_URL=https://github.com/JCSchoeman96/LiveFrames/pull/286
- MAIN_MOVEMENT_DURING_TASK=NO (origin/main was BASE_SHA at entry and at the analysis re-fetch; re-checked before commit)

The binding baseline is `docs/development/feature_romeo_current_main_residual_rebaseline.md` (CONFIRMED_REQUIRED_RESIDUAL_COUNT=20, LOCAL=12, COMPOUND=8, UNKNOWN=20, CUSTOM_CSS_RESIDUALS=44, TOTAL_DIAGNOSTICS=89).

## Private Identity

- PRIVATE_SOURCE_IDENTITY=Bricks component export, artifact SHA-256 `0cf29929a25bc2485ece90375d8c0f90fa1710eac0439bc5decc13af11f03f63`
- ROMEO_SHA256=0cf29929a25bc2485ece90375d8c0f90fa1710eac0439bc5decc13af11f03f63
- CORPUS_DIGEST=074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e (34 records, `path<TAB>size<TAB>sha256` manifest, archive excluded)

A hash proves identity only. It creates no redistribution authority. No private bytes are copied into the repository.

## Method

- Public adapter entry: `LiveFrames.Adapters.Bricks.to_ir/2` with no-ACSS context (empty TokenSet).
- Diagnostic reproduction matched the baseline: all 44 custom-CSS residual fingerprints match the accepted inventory, and the public run reproduces the baseline IR diagnostic counts (28 and 16).
- Read-only in-process tracing of the normalizer and resolver. Joined per residual by fingerprint (SHA-256 of owner ‖ reason ‖ raw source text, lowercase hex).
- Reference records were reconstructed from selector results and compared with the real records: 2/2 exact matches for every frame that has references (0 mismatches).
- Two independent captures produced identical per-residual analysis output (76 rows, byte-identical).
- Declaration shapes below are token-class signatures only (identifiers, numbers, `var()` spans). No names or values are recorded.

Diagnostic files were created transiently in temporary storage during analysis, deleted afterward, and not committed. None remain.

## Target Set

- CONFIRMED_REQUIRED_RESIDUAL_COUNT=20
- LOCAL_LABELLED=12 (baseline family SOURCE_LOCAL_VARIABLE)
- COMPOUND_LABELLED=8 (baseline family TOKEN_OR_VALUE_GRAMMAR)
- All 20 were confirmed to halt with reason `unresolved_value`.

## Halting Model

The normalizer sorts a frame's declarations by property name and halts at the first failing declaration. Generic (non-`var()`) declarations cannot emit `unresolved_value`: they fail only as `unsafe_declaration` or `unsupported_declaration`, and no generic declaration in any of the 20 frames fails either way. Therefore the first failing classified declaration is the terminal cause for each frame.

Because the halt hides later declarations, every classified declaration in each frame was also evaluated (not only those before the halt). This produced the dependency sets below.

## Per-Finding Causal Assignment

Fingerprints are 12-character prefixes. Owners are the baseline source identifiers.

| Fingerprint | Owner | Label | Primary terminal cause | Primary declaration | Dependencies recorded separately |
| --- | --- | --- | --- | --- | --- |
| 65924823bba3 | 07d0e9 | LOCAL | FRAME_D_NESTED_LOCAL_REFERENCE | direct, inset-block-start | FRAME_D (inset-inline-end); TRANSITION_GRAMMAR |
| e9adc28bb056 | 28c2a3 | LOCAL | FRAME_D_NESTED_LOCAL_REFERENCE | direct, inset-block-start | FRAME_D (inset-inline-end); TRANSITION_GRAMMAR |
| 99893c69ecce | 640a40 | LOCAL | FRAME_D_NESTED_LOCAL_REFERENCE | direct, inset-block-start | FRAME_D (inset-inline-end); TRANSITION_GRAMMAR |
| fa494ac736ae | 336877 | LOCAL | FRAME_D_NESTED_LOCAL_REFERENCE | direct, inset-block-start | FRAME_D (inset-inline-end); TRANSITION_GRAMMAR |
| 0901cb3b415a | 07d0e9 | LOCAL | TRANSITION_GRAMMAR_NO_MATCH | transition | none |
| 777e98dede7e | 07d0e9 | LOCAL | TRANSITION_GRAMMAR_NO_MATCH | transition | none |
| 0a143f9a4b3c | 28c2a3 | LOCAL | TRANSITION_GRAMMAR_NO_MATCH | transition | none |
| 87b4b639dcb6 | 28c2a3 | LOCAL | TRANSITION_GRAMMAR_NO_MATCH | transition | none |
| 11a537276351 | 336877 | LOCAL | TRANSITION_GRAMMAR_NO_MATCH | transition | none |
| 4c4295d25952 | 336877 | LOCAL | TRANSITION_GRAMMAR_NO_MATCH | transition | none |
| 4f3213b09bf8 | 640a40 | LOCAL | TRANSITION_GRAMMAR_NO_MATCH | transition | none |
| 5aea014b627a | 640a40 | LOCAL | TRANSITION_GRAMMAR_NO_MATCH | transition | none |
| 999f3ce30356 | 07d0e9 | COMPOUND | FRAME_D_NESTED_LOCAL_REFERENCE | background-image (embedded reference) | FRAME_D (padding); GAP_COMPOUND_GRAMMAR; TRANSITION_GRAMMAR |
| a99f584aeb79 | 28c2a3 | COMPOUND | FRAME_D_NESTED_LOCAL_REFERENCE | background-image (embedded reference) | FRAME_D (padding); GAP_COMPOUND_GRAMMAR; TRANSITION_GRAMMAR |
| 9a0ea1e06064 | 336877 | COMPOUND | FRAME_D_NESTED_LOCAL_REFERENCE | background-image (embedded reference) | FRAME_D (padding); GAP_COMPOUND_GRAMMAR; TRANSITION_GRAMMAR |
| 4e38d541683a | 640a40 | COMPOUND | FRAME_D_NESTED_LOCAL_REFERENCE | background-image (embedded reference) | FRAME_D (padding); GAP_COMPOUND_GRAMMAR; TRANSITION_GRAMMAR |
| c5b322a1649b | 07d0e9 | COMPOUND | TRANSITION_GRAMMAR_NO_MATCH | transition | none |
| 1e8aa992f388 | 28c2a3 | COMPOUND | TRANSITION_GRAMMAR_NO_MATCH | transition | none |
| 70f678f1f1c1 | 336877 | COMPOUND | TRANSITION_GRAMMAR_NO_MATCH | transition | none |
| 871df53a6b0d | 640a40 | COMPOUND | TRANSITION_GRAMMAR_NO_MATCH | transition | none |

Result: TOTAL_PRIMARY_CAUSE_COUNT=20, DUPLICATE_CAUSAL_ASSIGNMENTS=0, UNCLASSIFIED_REQUIRED_FINDINGS=0.

Primary counts by cause:

- FRAME_D_NESTED_LOCAL_REFERENCE: 8 (LOCAL 4, COMPOUND 4)
- TRANSITION_GRAMMAR_NO_MATCH: 12 (LOCAL 8, COMPOUND 4)

Primary counts by label:

- LOCAL_PRIMARY_CAUSE_COUNT=12 (FRAME_D 4, TRANSITION 8)
- COMPOUND_PRIMARY_CAUSE_COUNT=8 (FRAME_D 4, TRANSITION 4)

The SOURCE_LOCAL_VARIABLE label is not a terminal cause. Eight of the twelve LOCAL-labelled findings fail only at the transition grammar. Their direct local references already resolve `ok`.

## Dependency Causes (Recorded Separately)

- TRANSITION_GRAMMAR_NO_MATCH: 20 of 20 required frames contain it. 12 as primary, 8 as dependency.
- FRAME_D_NESTED_LOCAL_REFERENCE: 8 frames contain it. 8 as primary, 8 as dependency (inset-inline-end in 4 LOCAL frames, padding in 4 COMPOUND frames).
- GAP_COMPOUND_GRAMMAR (the C3 tail, split below as C3A and C3B): 4 frames (the COMPOUND background-image frames). The `gap` value has the token-class shape `calc(@ / #)` (one variable divided by one number). Two separate blockers:
  - C3A=BOUNDED_CALC_DIVISION_COMPOUND_GRAMMAR: the compound parser rejects this shape at parse level (`unsupported_grammar`).
  - C3B=NONLOCAL_TOKEN_AUTHORITY_OR_RESOLUTION: the referenced name has no source-local definition in the batch (`no_local_definition`), so it needs token authority or resolution outside the source-local resolver.

Dependency totals: TRANSITION 8, FRAME_D 8, GAP 4 (C3A and C3B together).

## FRAME D Test

FRAME D = bounded nested local definition resolution (the resolver returns `unsupported_nested_reference`).

- FRAME_D_REQUIRED_OWNER_RULE_COUNT=8 (4 LOCAL, 4 COMPOUND)
- FRAME_D_REFERENCE_RECORDS=16 (2 per owner-rule finding)
- LOCAL_REQUIRED_FRAME_D_COUNT=4
- LOCAL_REQUIRED_NON_FRAME_D_COUNT=8
- COMPOUND_REQUIRED_WITH_FRAME_D_COUNT=4 (all background-image frames)
- COMPOUND_REQUIRED_WITHOUT_FRAME_D_COUNT=4 (transition-only frames)
- UNIQUE_FRAME_D_GENERIC_SHAPES=1 (class SINGLE_VAR_PASSTHROUGH, hash `c3641f8544d7c02f…`: the selected definition is exactly one `var()` reference)
- FRAME_D_OWNER_FINDING_COUNT=8 (required). Unknown-set nested definitions are reported separately: 12 unique nested definition records across 4 owners, all with the same SINGLE_VAR_PASSTHROUGH shape. They are not classified here.

Hypotheses tested for the 16 nested references:

1. Selected definition missing: refuted. Exactly one definition with the referenced name exists in each batch.
2. Ambiguous or duplicate definitions: refuted. The batch holds one candidate per name.
3. Selected definition contains a nested `var()` dependency: confirmed. The resolver's depth-1 bound (`MAX_LOCAL_SUBSTITUTION_DEPTH=1`) rejects it.

FRAME D is primary for 8 findings but unlocks none of them alone, because each of those frames also contains a transition grammar blocker.

## Candidate Capabilities

Direct unlock means every blocker of the finding is covered by that capability alone. Marginal unlock is the count gained when the capability is added after the capabilities ranked above it.

| Candidate | Direct unlock | Marginal unlock in ranked order | Frames containing the blocker | Notes |
| --- | --- | --- | --- | --- |
| C1 TRANSITION_SHORTHAND_SOURCE_LOCAL_REFERENCE_GRAMMAR | 12 (8 LOCAL, 4 COMPOUND) | 12 | 20 of 20 | Hypothetical resolution of both transition references: 2/2 `ok` in all 12 measurable frames. Resolved classes: one time-like operand, one easing-keyword operand. Grammar acceptance is not measured. |
| C2 FRAME_D_BOUNDED_NESTED_LOCAL_RESOLUTION | 0 | 4 (LOCAL, after C1) | 8 of 20 | Single-hop passthrough only. |
| C3A BOUNDED_CALC_DIVISION_COMPOUND_GRAMMAR | 0 | 4 together with C3B (COMPOUND background-image frames, after C1 and C2) | 4 of 20 | Parse-level rejection of the one-variable, one-number calc-division shape. Alone it unlocks nothing: the same frames also need C3B. |
| C3B NONLOCAL_TOKEN_AUTHORITY_OR_RESOLUTION | 0 | 4 together with C3A (same frames, after C1 and C2) | 4 of 20 | The referenced name has no source-local definition. Requires token authority or resolution outside the source-local resolver. |

Ranking (by direct unlock, then marginal unlock):

1. C1 (12 direct unlocks, present in 20 of 20 frames)
2. C2 (0 direct; 4 marginal after C1)
3. C3A and C3B together (0 direct each; 4 marginal together after C1 and C2)

The 20 required findings are fully unlocked only when C1, C2, and C3A with C3B are all applied (12 + 4 + 4).

The ranking above is a measured marginal-unlock order: it reflects which blockers the measured frames share. It does not claim that the capabilities depend on one another architecturally; each can be designed and reviewed separately. Only C1 is recommended next.

## Next Generic Capability

NEXT_GENERIC_CAPABILITY=C1 TRANSITION_SHORTHAND_SOURCE_LOCAL_REFERENCE_GRAMMAR

The frozen compound authority (`docs/development/bounded_compound_css_value_authority.md`) admits only two direct `var()` spans separated by whitespace, with no leading token. Every measured transition value is `<identifier> var var`, repeated as a two-item list in 8 of 20 frames. Admitting it is an authority change, and it must go through an authority decision before any implementation.

Transition shape classes (token classes only):

- SINGLE_SPEC `IDENT VAR VAR`: 12 declarations
- LIST_OF_TWO_SPECS `IDENT VAR VAR, IDENT VAR VAR`: 8 declarations

## Authorization Gates

- IMPLEMENTATION_AUTHORIZED=NO
- ROMEO_COMPONENTIZATION_AUTHORIZED=NO
- ROMEO_NATIVE_GENERATION_AUTHORIZED=NO
- PRODUCTION_FILES_CHANGED=NO
- TEST_FILES_CHANGED=NO
- PRIVATE_SOURCE_LEAK=NO

## Unknown-Set Observations (Not Reclassified)

- Border-radius findings (4): halt with `no_local_definition`.
- Four OTHER/EXTERNAL_VALUE_AUTHORITY_MISSING findings: halt on a nested local definition at definition-compiler level, not on an external authority.

These are reported for the next baseline review. They are not part of the 20 required findings.

## Gates

- `git diff --check`: passed.
- `mix format --check-formatted`: passed.
- `mix compile --warnings-as-errors`: passed.
- `mix test`: skipped, docs-only change; no code, test, or dependency change.
- `mix assets.build`: skipped, no asset change.
- `mix deps.unlock --check-unused`: skipped, no dependency change.
