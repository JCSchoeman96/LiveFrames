# Feature Milan IR7 Style Remediation Authority

Status: proposed for owner review. This document freezes the remediation
architecture; it does not authorize implementation, IR7 issuance, downstream
authority issuance, component review, or native generation.

## 1. Programme state and accepted historical identities

```text
IR6_FINAL_NATIVE_GENERATION=BLOCKED
IR6_STYLE_REMEDIATION_REQUIRES_DESIGN_DOCUMENT_CHANGE=YES
IR6_DOWNSTREAM_AUTHORITIES_REUSABLE_ON_CHANGED_DOCUMENT=NO
TARGET_SUCCESSOR_IDENTITY=IR7
```

The accepted starting point is commit
`0f50d7a66af5c2f559dfd9431189ed2b73ba150d`, tree
`c408cae874015200fc4b0b7757c9b432fcc38269`. The exact IR6 document digest is
`d4b945741cb088ff7c739224f5cddc9904f3655741f74fa4bf17318cf3242ca9`.

These IR6 identities remain historical evidence only. They cannot authorize
generation from a corrected DesignDocument:

```text
IR6_VERSION=6.0.0
IR6_BEHAVIOR_CONTRACT_DIGEST=610029d848ec480d7cadeba7267b0cbd91607ea6246685212fa4aaa7971f51c6
IR6_BEHAVIOR_REVIEW_ID=brv_3dd12192602c0be16ba84627917887b157ba52fe2c81a0672659c367fc240d9d
IR6_PROPOSED_COMPONENT_CONTRACT_SHA256=fd5bcc8d2589ef4b5f3c5661d40892057ebdf4792701b937ccf67a4b86dc1ddf
IR6_COMPONENTIZATION_PLAN_SHA256=43154bb61c4255bcd13dd05489de0650dc7b4ade8796559313ed9bbef4c3c9af
IR6_APPROVED_COMPONENT_CONTRACT_SHA256=6c6b7403a0a169c1b1250cb8b449876b771ada91c583dad890d3f2fd09e49a0e
IR6_COMPONENT_REVIEW_RESULT_ID=crv_3dec716883843b6c9db0d34984822055341f861080b112a19a52f2a04fc03298
```

## 2. Frozen blocker inventory

The accepted final-generation diagnostic established exactly twelve
unserializable style occurrences. This authority does not add further Milan
style blockers.

```text
STRUCTURAL_GRID_OCCURRENCES=3
UNRESOLVED_NON_GRID_OCCURRENCES=5
SPACING_SCALE_S_PACKAGE_MAPPING_BLOCKERS=4
TOTAL_UNSERIALIZABLE_OCCURRENCES=12
```

The three grid occurrences are the two declarations using `--grid-1` and the
one declaration using `--grid-2`. They are on
`node_000001_000001`: `grid-template-columns` with `--grid-2`,
`grid-template-rows` with `--grid-1`, and `grid-template-columns` with
`--grid-1`.

The five non-grid unresolved occurrences are:

| Node | Property | Exact source expression |
| --- | --- | --- |
| `node_000001` | `background` | `var(--bg-ultra-light)` |
| `node_000001_000001_000001_000002_000001` | `border-color` | `var(--black-trans-10)` |
| `node_000001_000001_000001_000002_000001` | `padding-left` | `var(--space-m)` |
| `node_000001_000001_000001_000002_000001` | `padding-right` | `var(--space-m)` |
| `node_000001_000001_000001_000002_000001_000002_000001` | `color` | `var(--text-dark-muted)` |

The four other blocked occurrences are resolved TokenSet references to
`spacing.scale.s` used by `padding-bottom`, `padding-top`, and two `row-gap`
declarations. Their semantic token is valid; the native package mapping is
missing.

## 3. Structural grid authority

The accepted structural authority remains the only owner of grid recipes:

```text
GRID_REMEDIATION_OWNER=LiveFrames.Adapters.AutomaticCSS.StructuralVariables + LiveFrames.Styles.StructuralVariableAuthority + Bricks DesignIRNormalizer
--grid-1 -> repeat(1, minmax(0, 1fr))
--grid-2 -> repeat(2, minmax(0, 1fr))
GRID_OUTPUT=StyleValue.literal
GRID_SOURCE_VARIABLE_RETAINED_IN_VALUE=NO
GRID_NATIVE_GENERATOR_KNOWLEDGE=NONE
```

The accepted grid evidence is
`docs/evidence/c09d6_d0e1_acss_4_0_1_grid_authority.md` and the governing
implementation authority is
`docs/development/c09d6d_upstream_style_gap_resolution_authority.md` §5.
The records are not TokenSet tokens and must not be recreated as grid tokens.
The accepted Milan IR6 reconstruction omitted the existing
`StructuralVariableAuthority` when it called Bricks normalization. R2 wires
the existing authority into the reconstruction; it does not add grid policy.

Required fail-closed behavior remains: absent, malformed, duplicate, or
ambiguous structural authority, unsupported source version, or invalid
property pairing must not emit a literal. The accepted property pairing is
only `grid-template-columns` and `grid-template-rows`.

## 4. Direct-variable ownership rule

The terms in `docs/06_ACSS_TOKEN_ADAPTER.md` retain their distinct meanings:

- `source_output_alias` is an explicit source setting or calculated-variable
  contract that emits the CSS variable for the owning token path.
- `source_reference` records a source expression consuming a CSS variable for
  the token path; it is consumer evidence, not ownership evidence.
- `explicit_project_contract` is a frozen, exact LiveFrames variable-to-path
  ownership record.

The generic direct-variable decision is:

```text
DIRECT_VARIABLE_OWNER_SELECTION=A_OUTPUT_ALIAS_IS_EXACT_OWNER_WHEN_UNIQUE
DIRECT_VARIABLE_RULE_SUPERSEDES=docs/06_ACSS_TOKEN_ADAPTER.md current inverse-candidate rule
ONLY_FOR=direct var(--x) ownership resolution
```

Once this authority is accepted, §4 supersedes the current inverse-candidate
rule in `docs/06_ACSS_TOKEN_ADAPTER.md` only for direct
`var(--x)` ownership resolution. It does not change ordinary
semantic-reference normalization. This PR freezes the rule; it does not
authorize implementation.

For an exact direct expression `var(--x)`, the owner candidate set consists
only of exact `source_output_alias` and `explicit_project_contract` records.
`source_reference` records never become owner candidates and cannot compete
with an owner. Apply these guards:

1. There must be exactly one distinct owner token path.
2. The owner token must be present in the TokenSet and resolved.
3. The token must expose a representation accepted by the consuming CSS
   serializer.
4. Multiple distinct output aliases or project contracts remain ambiguous
   and fail closed, even if their resolved values happen to match.
5. A missing, unresolved, invalid, or unserializable owner fails closed; do
   not fall back to `source_reference` records.
6. Do not infer an owner from variable spelling, token path, value equality,
   property name, map ordering, or candidate ordering.
7. Do not add a Milan-specific property branch.

The direct-variable lookup state machine is frozen as follows. “Owner paths”
means distinct paths carrying `source_output_alias` or
`explicit_project_contract`; reference-only paths are counted separately and
are never owner candidates.

| Case | Exact authority state | Result |
| --- | --- | --- |
| 1 | Exactly one resolved `source_output_alias` owner path, with no conflicting explicit project owner | Select that path, subject to presence and terminal-value checks. |
| 2 | Exactly one output-alias owner path plus `source_reference` records on other paths | Select the output-alias path; references do not compete. |
| 3 | More than one distinct `source_output_alias` owner path | `{:error, :ambiguous_candidates}`; fail closed. |
| 4 | No output-alias owner, no explicit project owner, and exactly one `source_reference` path | `{:error, :no_authority}`; keep the direct expression unresolved. One reference path is not an owner. |
| 5 | No output-alias owner, no explicit project owner, and multiple `source_reference` paths | `{:error, :no_authority}`; keep the direct expression unresolved. Reference cardinality does not create owners or owner ambiguity. |
| 6 | A selected owner path has no TokenSet token | `{:error, :token_missing}`; fail closed. |
| 7 | A selected owner token is unresolved | `{:error, :token_unresolved}`; fail closed. |
| 8 | A selected owner has no valid CSS terminal representation | `{:error, :token_value_unavailable}`; fail closed. |

One exact `explicit_project_contract` path may own a direct variable when no
output alias exists; conflicting distinct owner paths across either owner
kind return `{:error, :ambiguous_candidates}`. Multiple records for the same
owner path remain one path after the existing exact-record deduplication.
An exact `source_reference` without an exact owner record never authorizes a
direct source-variable expression. Existing semantic-reference
normalization continues to use its validated semantic reference and is not
converted into a direct-variable owner by this rule.

### `--space-m`

The accepted TokenSet contains one output alias for `spacing.scale.medium`
and source-reference records for `spacing.content_gap` and
`spacing.grid_gap`. Under the generic rule above, the owner is:

```text
SPACE_M_REMEDIATION=A_OUTPUT_ALIAS_IS_EXACT_OWNER_WHEN_UNIQUE
SPACE_M_TOKEN_PATH=spacing.scale.medium
```

The two consumer references remain recorded as evidence and do not make the
owner ambiguous. No value or token-path inference is permitted. If the exact
TokenSet no longer has one resolved output alias for `--space-m`, it remains
unresolved and the reconstruction stops.

## 5. Non-grid source-variable decisions

### `--bg-ultra-light`

The accepted AutomaticCSS 4.0.1 normalizer models source key
`bg-ultra-light` as the semantic concept
`color.background.ultra_light`, whose value references
`color.neutral.ultra_light` through
`--neutral-ultra-light`. This establishes the semantic concept
and source key. It does not establish that `--bg-ultra-light` is
emitted or owned by that path as a project-wide direct-variable contract.

```text
EXISTING_SEMANTIC_CONCEPT=color.background.ultra_light
EXISTING_SOURCE_KEY=bg-ultra-light
BG_ULTRA_LIGHT_REMEDIATION=B_NEW_EVIDENCE_REQUIRED
BG_ULTRA_LIGHT_TOKEN_PATH=NONE_AUTHORIZED_FOR_DIRECT_VARIABLE_OWNERSHIP
BG_ULTRA_LIGHT_DIRECT_OWNER_AUTHORIZED=NO
BG_ULTRA_LIGHT_EXACT_SOURCE_VERSION_EVIDENCE_REQUIRED=YES
```

The existing semantic model does not by itself prove
`--bg-ultra-light -> color.background.ultra_light`. Separate
exact source/version evidence must establish that relationship before this
authority can authorize either a `source_output_alias` or a
genuinely project-wide `explicit_project_contract`. The global
`AutomaticCSS.Normalizer.project_contract_authorities/1`
function cannot claim Milan-only scope. This authority adds no Milan-specific
production branch or scoping mechanism.

Keep the direct expression unresolved until the exact evidence and its
resulting authority are accepted. NativeGenerator has no knowledge of this
variable.

### `--black-trans-10`

No accepted repository authority proves an exact token path, value, opacity,
or ownership relationship for this variable. Its spelling is not evidence.

```text
BLACK_TRANS_10_REMEDIATION=B_NEW_EVIDENCE_REQUIRED
BLACK_TRANS_10_TOKEN_PATH=NONE_AUTHORIZED
```

Keep it unresolved until a separate reviewed source/version authority or
explicit project contract names the exact path and value authority. No code
may emit, map, approximate, or guess it before then.

### `--text-dark-muted`

Existing tests preserve this expression inside an icon color-mix value, but
that proves source-expression preservation only; it does not establish a
semantic token or direct-variable owner.

```text
TEXT_DARK_MUTED_REMEDIATION=B_NEW_EVIDENCE_REQUIRED
TEXT_DARK_MUTED_TOKEN_PATH=NONE_AUTHORIZED
```

Keep it unresolved until a separate reviewed source/version authority or
explicit project contract names the exact path and value authority. No code
may infer a token from its spelling or emit a guessed value.

R3 closes with an explicit disposition for each of the three variables:
accepted exact authority, or unresolved with final generation blocked. No
variable may be authorized from the semantic concept or source key alone.

## 6. `spacing.scale.s` package mapping

The accepted TokenSet contains `spacing.scale.s` as a present, resolved
semantic token with ACSS 4.0.1 calculated-variable authority. The native
package token bridge currently has an `.xs` mapping to
`--lf-space-scale-xs`, but no `.s` entry. The inspected v3 map, v2 map,
committed generated theme CSS, and public CSS strategy contain no existing
`--lf-space-scale-s` variable.

Freeze the exact public package mapping:

```text
SPACING_SCALE_S_PACKAGE_VARIABLE=--lf-space-scale-s
SPACING_SCALE_S_MAPPING_AUTHORIZED=YES
NO_EXISTING_VARIABLE_COLLISION=YES
CONSISTENT_WITH_EXISTING_SPACING_SCALE_PACKAGE_SURFACE=YES
TOKEN_MAP_OWNER=apps/live_frames/priv/token_maps/native_shared_v3.json
THEME_REGENERATION_REQUIRED=YES
TOKEN_INLINE_BYPASS=FORBIDDEN
PUBLIC_LF_VARIABLE_ADDED=--lf-space-scale-s
```

This is a package-boundary mapping only. It does not change the semantic
TokenSet value or authorize inlining values into component styles. The
committed theme and application CSS assets must be regenerated deterministically
from the token map. Do not hand-edit generated CSS.

## 7. Design IR schema and document identity

The proposed remediation changes values and authority records represented by
the existing IR contract. It adds no StyleValue kind, serialized field,
validation rule, or schema transition. Therefore:

```text
DESIGN_IR_SCHEMA_CHANGE_REQUIRED=NO
TARGET_IR_VERSION=6.0.0
```

“IR7” is the Milan programme successor label. Milan remediation generation
does not mean the Design IR schema version changes. Do not bump the schema
version solely because the document digest changes.

The corrected DesignDocument must be canonically serialized and assigned a
fresh digest. If its bytes differ, every downstream identity bound to the IR6
document is stale. Never carry an old authority forward because the public
component API or behavior appears unchanged.

The only currently frozen blocker inventory is the twelve occurrences in §2.
After R1–R4, reconstruct and inspect the corrected document. The two grid
values must be literals; `--space-m` must resolve only through the unique
owner rule; `spacing.scale.s` must map at the native package boundary; and
the remaining color variables must each be either backed by newly accepted
exact authority or remain visibly unresolved. No unresolved value may be
silently dropped or serialized.

## 8. SemanticInput preservation

Preserve the existing public component intent unless validation against the
corrected document proves it impossible:

```text
contract_id=component_feature_showcase
category=component
module_intent=feature_showcase
function_intent=feature_showcase
attrs=id,features,feature_media,feature_heading_level
slot=intro
SEMANTIC_INPUT_INTENT=PRESERVE_EXISTING
```

Revalidate the unchanged SemanticInput against the corrected DesignDocument
before reproposal. Any required public API change is outside this authority and
stops the transition for a separate owner decision. Do not copy IR6
ComponentContract or ComponentizationPlan bytes.

## 9. Downstream identity transition

After the corrected DesignDocument is frozen, recreate all dependent
authorities in this exact order:

```text
correct upstream authority implementation
-> reconstruct DesignDocument
-> freeze new DesignDocument identity
-> issue exact BehaviorContract
-> approve exact BehaviorReviewResult
-> revalidate unchanged-or-revised SemanticInput
-> repropose ComponentContract + ComponentizationPlan
-> freeze fingerprints
-> independent candidate review
-> human ComponentReview
-> new ComponentReviewResult
-> final NativeGenerator proof
```

Required identity effects are:

```text
DESIGN_DOCUMENT_REISSUE_REQUIRED=YES
BEHAVIOR_CONTRACT_REISSUE_REQUIRED=YES
BEHAVIOR_REVIEW_RESULT_REISSUE_REQUIRED=YES
SEMANTIC_INPUT_REVALIDATION_REQUIRED=YES
COMPONENT_CONTRACT_REPROPOSAL_REQUIRED=YES
COMPONENTIZATION_PLAN_REPROPOSAL_REQUIRED=YES
COMPONENT_REVIEW_REAPPROVAL_REQUIRED=YES
```

No BehaviorContract, BehaviorReviewResult, SemanticInput validation result,
ComponentContract, ComponentizationPlan, or ComponentReviewResult from IR6
may authorize a changed DesignDocument. There is no shortcut between these
steps.

## 10. NativeGenerator invariants

These constraints do not change:

```text
NATIVE_GENERATOR_MUST_NOT_PARSE_SOURCE_VARIABLE_NAMES=YES
STYLEVALUE_UNRESOLVED_EMISSION=FORBIDDEN
TOKEN_REF_REQUIRES_PACKAGE_MAPPING=YES
SOURCE_VARIABLE_NAME_GUESSING=FORBIDDEN
DROP_STYLE_TO_FORCE_GENERATION=FORBIDDEN
OPAQUE_SOURCE_CSS_COPY=FORBIDDEN
GLOBAL_STYLEVALUE_SERIALIZER_WIDENING=FORBIDDEN
ORDINARY_GENERIC_BUTTON_WIDENING=FORBIDDEN
```

NativeGenerator consumes validated `StyleValue.literal`, `StyleValue.keyword`,
authorized `StyleValue.token_ref`, and authorized bounded calculations. It
does not interpret unresolved source syntax. The exact Selection exception
remains the transient `NativeRealizationAuthority` lifecycle already accepted
for ComponentReview; it does not widen generic `button` generation.

## 11. Serial remediation slices

Each slice is gated by owner acceptance of this document and the previous
slice's success. The files below are the complete planned edit/evidence
surfaces for that slice; any additional production surface requires a new
authority review before work begins.

### R1 — `R1_GENERIC_DIRECT_VARIABLE_AUTHORITY`

**Owner and authority:** `LiveFrames.Tokens.VariableAuthority`, using the
relationship definitions in `docs/06_ACSS_TOKEN_ADAPTER.md` and this §4.

**Files:**

- Production: `apps/live_frames/lib/live_frames/tokens/variable_authority.ex`.
- Tests: `apps/live_frames/test/live_frames/tokens/variable_authority_test.exs`,
  `apps/live_frames/test/live_frames/automatic_css_adapter_test.exs`,
  `apps/live_frames/test/live_frames/bricks_design_ir_test.exs`.
- Documentation: `docs/06_ACSS_TOKEN_ADAPTER.md`.

Update the canonical Token Adapter documentation, `VariableAuthority`,
and its focused tests together in this implementation slice. This authority PR
does not authorize those implementation changes.

**Focused tests:** one unique resolved output alias wins over unrelated
reference consumers; distinct owner aliases fail; unresolved or missing owner
fails without reference fallback; exactly one and multiple reference-only
paths both return `:no_authority`; explicit project contract remains exact;
token path ordering has no effect; unrelated property behavior is unchanged.

**Forbidden widening:** no variable-name/value inference, no property-specific
rule, no preference by path order, and no NativeGenerator change.

**Identity effect:** no schema change. Any reconstructed DesignDocument whose
direct variable changes from unresolved to token_ref receives a new document
digest and requires all downstream authorities to be reissued.

**STOP:** `STOP=DIRECT_VARIABLE_OWNER_RULE_UNPROVABLE`,
`STOP=SPACE_M_REMAINS_AMBIGUOUS`, `STOP=SERIALIZED_SCHEMA_CHANGE_DISCOVERED`,
or `STOP=AUTHORITY_CONFLICT`.

**Success:** the accepted exact TokenSet resolves `--space-m` to the single
resolved `spacing.scale.medium` owner while `source_reference` records remain
consumer evidence.

### R2 — `R2_MILAN_STRUCTURAL_AUTHORITY_WIRING`

**Owner and authority:** existing
`LiveFrames.Adapters.AutomaticCSS.StructuralVariables` and
`LiveFrames.Styles.StructuralVariableAuthority`, consumed by
`LiveFrames.Adapters.Bricks.DesignIRNormalizer` using the accepted D0E1 grid
evidence.

**Files:**

- Production: none authorized. The existing normalization option and
  structural resolver are the required implementation surface. A production
  change means the accepted wiring premise was wrong and requires a new
  authority decision.
- Tests: `apps/live_frames/test/live_frames/automatic_css_structural_variables_test.exs`,
  `apps/live_frames/test/live_frames/styles/structural_variable_authority_test.exs`,
  `apps/live_frames/test/live_frames/bricks_design_ir_test.exs`, and the
  exact-candidate reconstruction proof executed from its temporary harness.
- Documentation/evidence: create
  `docs/development/feature_milan_ir7_design_document_reconstruction_record.md`
  after reconstruction; do not edit the canonical Task 10 plan.

**Focused tests:** exact Milan `--grid-1/2` declarations become the authorized
literal recipes only with the structural authority supplied; missing or
ambiguous authority remains unresolved; invalid property pairing remains
blocked; no `--grid-*` remains in those normalized values.

**Forbidden widening:** no grid TokenSet paths, no NativeGenerator grid
knowledge, and no additional structural variable names.

**Identity effect:** normalized StyleValues and DesignDocument bytes change;
all dependent authorities are reissued under §9.

**STOP:** `STOP=GRID_AUTHORITY_CONFLICT`,
`STOP=STRUCTURAL_AUTHORITY_NOT_CONSUMED`, or
`STOP=SERIALIZED_SCHEMA_CHANGE_DISCOVERED`.

**Success:** all three existing grid occurrences normalize to the specified
literal values in the accepted Milan reconstruction.

### R3 — `R3_COLOR_VARIABLE_EVIDENCE_GATE`

**Owner and authority:** separate exact source/version evidence for each
currently unsupported direct color variable: `--bg-ultra-light`,
`--black-trans-10`, and `--text-dark-muted`. The
existing semantic concept for `--bg-ultra-light` does not
establish direct-variable ownership. No exact path or value authority is
frozen for any of the three variables.

**Files:**

- Production: none authorized in this evidence gate. In particular, no edit
  to `apps/live_frames/lib/live_frames/adapters/automatic_css/normalizer.ex`
  is authorized until exact evidence is accepted and a separate
  implementation authority permits the change.
- Tests after evidence acceptance:
  `apps/live_frames/test/live_frames/automatic_css_adapter_test.exs`,
  `apps/live_frames/test/live_frames/tokens/variable_authority_test.exs`,
  `apps/live_frames/test/live_frames/bricks_design_ir_test.exs`.
- Documentation/evidence: submit exact source/version evidence for review in
  `docs/development/feature_milan_ir7_color_variable_authority.md`.
  Evidence must prove the exact variable-to-path relationship at the proposed
  authority's scope before either `source_output_alias` or a
  project-wide `explicit_project_contract` can be accepted.

**Focused checks after evidence acceptance:** each approved record names the
exact variable and token path; absent or insufficient evidence leaves the
direct expression unresolved; a project contract applies project-wide; no
unrelated source or project receives an inferred mapping.

**Forbidden widening:** no variable-name inference, no arbitrary source-CSS
scan, no guessed output value, no Milan-specific production branch, no global
source variable table, and no NativeGenerator serializer change.

**Identity effect:** accepting a later authority record changes TokenSet
authority metadata and the reconstructed DesignDocument identity. R5 and all
downstream issuance steps remain required.

**STOP:** `STOP=BG_ULTRA_LIGHT_REQUIRES_EXACT_SOURCE_EVIDENCE`,
`STOP=BLACK_TRANS_10_REQUIRES_EXACT_SOURCE_EVIDENCE`,
`STOP=TEXT_DARK_MUTED_REQUIRES_EXACT_SOURCE_EVIDENCE`, or
`STOP=AUTHORITY_CONFLICT`.

**Success:** exact evidence is accepted for any color variable to be
authorized. Every variable without accepted evidence remains unresolved and
blocks final generation.

### R4 — `R4_SPACING_SCALE_S_PACKAGE_MAPPING`

**Owner and authority:** `LiveFrames.Styling.TokenBridge` package mapping and
the exact public variable `--lf-space-scale-s` frozen in §6.

**Files:**

- Production: `apps/live_frames/priv/token_maps/native_shared_v3.json`.
- Tests: `apps/live_frames/test/live_frames/styling/token_bridge_test.exs`,
  `apps/live_frames/test/live_frames/styling/assets_drift_test.exs`.
- Documentation: `docs/11_CSS_AND_TAILWIND_STRATEGY.md`.
- Deterministically generated assets:
  `apps/live_frames/assets/css/theme/lf_theme.css` and
  `apps/live_frames/priv/static/live_frames/css/live_frames.css`.

**Focused tests:** the exact token path maps to the exact public variable;
token bridge output is unchanged for other mappings; generated theme includes
the variable from the resolved TokenSet; committed assets match deterministic
build output; no collision or inline-value bypass exists.

**Forbidden widening:** no semantic token change, no inline values, no
NativeGenerator mapping, and no unrelated token-map additions.

**Identity effect:** no Design IR schema change. Package fingerprints and
generated theme assets change; the corrected DesignDocument still gets a new
identity from R1–R3. Downstream authorities follow §9.

**STOP:** `STOP=PACKAGE_VARIABLE_NAME_CONFLICT`,
`STOP=SPACING_SCALE_S_TOKEN_NOT_GENERATION_READY`,
`STOP=THEME_ASSET_REGENERATION_NOT_DETERMINISTIC`, or
`STOP=AUTHORITY_CONFLICT`.

**Success:** all four `spacing.scale.s` references resolve through the
package-owned `--lf-space-scale-s` mapping and regenerated assets.

### R5 — `R5_CORRECTED_DESIGN_DOCUMENT_ISSUANCE`

**Owner and authority:** exact accepted ACSS structural authority, the R1
owner rule, the R3 accepted color contracts, the R4 package mapping, and the
existing Design IR 6.0.0 schema.

**Files:**

- Production: none authorized unless a prior slice's accepted implementation
  requires a separately reviewed correction.
- Tests: `apps/live_frames/test/live_frames/bricks_design_ir_test.exs`,
  `apps/live_frames/test/live_frames/ir_identity_test.exs`, and relevant
  focused TokenBridge tests from R4.
- Documentation/evidence: create
  `docs/development/feature_milan_ir7_design_document_identity.md` containing
  the exact reconstruction inputs, validation results, canonical bytes length,
  and fresh DesignDocument digest.
- Reconstruction code, if needed, remains in a temporary harness outside the
  repository.

**Focused checks:** structure and serialization validation pass; all three
grid declarations are literals; `--space-m` has exact owner resolution; all
four `.s` token refs map; every remaining style is either authorized or
explicitly unresolved; no style is deleted; the output is deterministic.

**Forbidden widening:** no IR schema bump, no reusing IR6 downstream
artifacts, and no manually edited DesignDocument bytes.

**Identity effect:** a fresh DesignDocument digest is issued. All downstream
IR6 identities are stale.

**STOP:** `STOP=SERIALIZED_SCHEMA_CHANGE_DISCOVERED`,
`STOP=IR7_DESIGN_DOCUMENT_VALIDATION_FAILURE`,
`STOP=UNRESOLVED_STYLE_REMAINS_FOR_FINAL_GENERATION`,
`STOP=NONDETERMINISTIC_OUTPUT`, or `STOP=AUTHORITY_CONFLICT`.

**Success:** a deterministic corrected DesignDocument is frozen at a new
digest under schema 6.0.0, and no unresolved style remains on the required
native generation path.

### R6 — `R6_BEHAVIOR_AUTHORITY_REISSUE`

**Owner and authority:** exact new DesignDocument identity and the accepted
Behavior contract/review APIs. Reconstruct Behavior authority from the IR7
document; do not carry forward IR6 identity-bound results.

**Files:**

- Production: none planned.
- Tests: `apps/live_frames/test/live_frames/behavior/serializer_test.exs`,
  `apps/live_frames/test/live_frames/behavior/binding_identity_test.exs`,
  `apps/live_frames/test/live_frames/behavior/review_result_test.exs`.
- Evidence: create
  `docs/development/feature_milan_ir7_behavior_contract_reissue.md` and
  `docs/development/feature_milan_ir7_behavior_review_result.md` only after
  the exact new artifacts pass independent review.

**Focused checks:** contract digest binds the new DesignDocument; binding IDs
and source references validate; the exact review result binds the new
contract; no IR6 digest or review ID is embedded.

**Forbidden widening:** no Behavior semantic changes unless the corrected
DesignDocument proves they are necessary and a separate authority process
approves them.

**Identity effect:** new BehaviorContract digest and BehaviorReviewResult ID.

**STOP:** `STOP=BEHAVIOR_SEMANTICS_CHANGE_REQUIRED`,
`STOP=BEHAVIOR_AUTHORITY_MISMATCH`, or `STOP=AUTHORITY_CONFLICT`.

**Success:** exact Behavior artifacts for the new DesignDocument are issued
and approved.

### R7 — `R7_COMPONENT_REPROPOSAL_AND_REVIEW`

**Owner and authority:** the new DesignDocument, new BehaviorContract, new
BehaviorReviewResult, and the preserved SemanticInput intent in §8.

**Files:**

- Production: none planned.
- Tests: `apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs`,
  `apps/live_frames/test/live_frames/behavior/componentization_decision_test.exs`,
  `apps/live_frames/test/live_frames/component_review_test.exs`,
  `apps/live_frames/test/live_frames/component_review_result_test.exs`.
- Evidence: create
  `docs/development/feature_milan_ir7_phase7a_semantic_input_authority.md`,
  `docs/development/feature_milan_ir7_phase7b_candidate_freeze.md`, and
  `docs/development/feature_milan_ir7_component_review_result.md` for their
  respective revalidation, fingerprint review, and human review stages.

**Focused checks:** SemanticInput validates against the new document;
ComponentContract and ComponentizationPlan are reproposed from exact new
Behavior authority; all references/dispositions validate; candidate bytes
are frozen and independently reviewed; human ComponentReview binds the new
contract, plan, and DesignDocument.

**Forbidden widening:** no reuse of IR6 contract/plan/review bytes, no
automatic approval, and no native output generation during candidate review.

**Identity effect:** new proposed and approved ComponentContract digests,
ComponentizationPlan digest, and ComponentReviewResult ID.

**STOP:** `STOP=PUBLIC_COMPONENT_API_CHANGE_REQUIRED`,
`STOP=SEMANTIC_INPUT_AUTHORITY_MISMATCH`,
`STOP=COMPONENT_CANDIDATE_IDENTITY_MISMATCH`,
`STOP=HUMAN_COMPONENT_REVIEW_REQUIRED`, or `STOP=AUTHORITY_CONFLICT`.

**Success:** exact new candidate is frozen, independently reviewed, and
human-approved against the corrected DesignDocument.

### R8 — `R8_FINAL_NATIVE_GENERATION_PROOF`

**Owner and authority:** the exact approved IR7 ComponentContract,
ComponentizationPlan, DesignDocument, BehaviorContract,
BehaviorReviewResult, and ComponentReviewResult. The existing transient
NativeRealizationAuthority exception is limited to the accepted Selection
control.

**Files:**

- Production: none planned.
- Tests: focused existing
  `apps/live_frames/test/live_frames/native_generator_test.exs`,
  `apps/live_frames/test/live_frames/native_generator/style_value_css_test.exs`,
  `apps/live_frames/test/live_frames/native_generator/style_integration_test.exs`,
  `apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs`,
  and `apps/live_frames/test/live_frames/native_generator/milan_selection_runtime_test.exs`.
- Proof harness: temporary and outside the repository; do not persist the
  generated bundle.
- Documentation/evidence: create
  `docs/development/feature_milan_ir7_final_native_generation_proof.md` after
  independent verification.

**Focused checks:** ordinary `generate/3` remains blocked for the
disposition-bearing candidate; behavior-aware `generate/7` succeeds exactly
once; artifact identities and kinds are exact; Selection, source-neutrality,
picture, intro slot, browser-local runtime, and timer invariants pass; no
unresolved style reaches output.

**Forbidden widening:** no NativeGenerator parsing of source variable names,
no unresolved-style serializer, no dropped declaration, no generic button
policy change, no source runtime, and no consumer/browser integration.

**Identity effect:** no further authority reissue if all exact R7 identities
are unchanged. Any input identity change returns to its owning phase.

**STOP:** `STOP=BEHAVIOR_AWARE_NATIVE_GENERATION_BLOCKED`,
`STOP=UNRESOLVED_STYLE_REMAINS_FOR_FINAL_GENERATION`,
`STOP=ORDINARY_GENERIC_BUTTON_POLICY_WIDENED`,
`STOP=SOURCE_RUNTIME_COPY_DETECTED`, `STOP=NONDETERMINISTIC_OUTPUT`, or
`STOP=AUTHORITY_CONFLICT`.

**Success:** the exact approved IR7 tuple passes production behavior-aware
NativeGenerator generation and its complete output invariants.

## 12. Global STOP conditions

Stop without workaround or scope expansion on any of:

```text
STOP=GRID_AUTHORITY_CONFLICT
STOP=DIRECT_VARIABLE_OWNER_RULE_UNPROVABLE
STOP=BG_ULTRA_LIGHT_REQUIRES_EXACT_SOURCE_EVIDENCE
STOP=BLACK_TRANS_10_REQUIRES_EXACT_SOURCE_EVIDENCE
STOP=TEXT_DARK_MUTED_REQUIRES_EXACT_SOURCE_EVIDENCE
STOP=SPACE_M_REMAINS_AMBIGUOUS
STOP=PACKAGE_VARIABLE_NAME_CONFLICT
STOP=SERIALIZED_SCHEMA_CHANGE_DISCOVERED
STOP=BEHAVIOR_SEMANTICS_CHANGE_REQUIRED
STOP=PUBLIC_COMPONENT_API_CHANGE_REQUIRED
STOP=NATIVE_GENERATOR_WIDENING_REQUIRED
STOP=SOURCE_SPECIFIC_GENERATOR_BRANCH_REQUIRED
STOP=AUTHORITY_CONFLICT
```

The authority task itself changes no production code, tests, token maps, or
generated assets. No implementation slice is authorized until the owner
accepts this document.
