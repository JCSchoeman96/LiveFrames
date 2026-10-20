# Bounded compound CSS value authority

## Authority status

This record defines source-neutral architecture and policy for bounded compound
declaration-value normalization during Bricks custom-CSS processing. It does not
authorize implementation, componentization, native generation, resolver changes,
selector expansion, or a Romeo-specific branch.

```text
REVIEW_NEXT_ROMEO_GENERIC_CAPABILITY=ACCEPTED

BASE_SHA=1d2110e98b3db50b6c7c1ba82fe832ec347caecf
BASE_TREE=d9d20998ab1ff06965a7b76d17b37f4af5e19ff4

CSS_LOCAL_DIRECT_RESOLVER_SLICE=ACCEPTED
CSS_LOCAL_RESOLVER_DEFECT=NO
CSS_LOCAL_RESOLVER_REOPENED=NO

FRAME_C=FAIL_CLOSED_NO_ELIGIBLE_DEFINITION
FRAME_C_IMPLEMENTATION_AUTHORIZED=NO

FRAME_D=FAIL_CLOSED_UNSUPPORTED_NESTED_REFERENCE
FRAME_D_IMPLEMENTATION_AUTHORIZED=NO

CSS_COMPOUND_VALUE_REQUIREMENT=CONFIRMED
CSS_COMPOUND_VALUE_COUNT=8
CSS_COMPOUND_VALUE_SHAPES=3

GRAMMAR_PRODUCTIONS_MUTUALLY_EXCLUSIVE=YES
GRAMMAR_CLASSIFICATION_PRECEDENCE_REQUIRED=NO
FUNCTION_CALL_EMBEDDED_VAR_POLICY=PROVEN_AND_FROZEN
FUNCTION_CALL_NESTING_ACCOUNTING=FROZEN
FUNCTION_ALLOWLIST_OR_CATEGORY=FROZEN
MULTI_TOKEN_GRAMMAR=FROZEN
VAR_OPERATION_GRAMMAR=FROZEN
RESOLVED_TERMINAL_SLOT_VALIDATION=REQUIRED
POST_SUBSTITUTION_COMPOUND_REVALIDATION=REQUIRED
POST_SUBSTITUTION_REVALIDATION_USES_RESOLVED_FORM=YES
PRODUCTION_IDENTITY_PRESERVED_AFTER_RESOLUTION=YES
SOURCE_FORM_GRAMMAR_FROZEN=YES
RESOLVED_FORM_GRAMMAR_FROZEN=YES
SLOT_GRAMMAR_CONTRACTS_FROZEN=YES
MULTI_TOKEN_HASH_USED_AS_EVIDENCE_ONLY=YES
MULTI_TOKEN_HASH_USED_AS_IMPLEMENTATION_SELECTOR=NO
MULTI_TOKEN_TOKEN_COUNT_MIN=2
MULTI_TOKEN_TOKEN_COUNT_MAX=2
MULTI_TOKEN_KEYWORD_AUTHORIZED=NO
MULTI_TOKEN_SEPARATE_PERCENTAGE_CLASS_AUTHORIZED=NO
MULTI_TOKEN_UNITLESS_NUMBER_AUTHORIZED=NO
MULTI_TOKEN_EMBEDDED_LOCAL_REFERENCE_AUTHORIZED=NO
MULTI_TOKEN_UNEVIDENCED_TOKEN_CLASS_AUTHORIZED=NO
MULTI_TOKEN_UNEVIDENCED_TOKEN_COUNT_AUTHORIZED=NO
MULTI_TOKEN_LOCAL_RESOLVER_REFERENCES_CURRENT_CAPABILITY=0
CANONICAL_COMPOUND_REFERENCE_RECORD_COUNT=48
CANONICAL_ACTUAL_RESOLVER_OK_COUNT=40
CANONICAL_ACTUAL_RESOLVER_ERROR_COUNT=8
CANONICAL_ACTUAL_RESOLVER_OK_SLOT_ACCEPTED_COUNT=40
RESOLVER_TERMINAL_EVIDENCE=ACTUAL_RESOLVE_3_OUTPUT
DEFINITION_TERMINAL_PROXY_USED_FOR_ACCEPTANCE=NO
JUXTAPOSITION_SAFE_VALUE_FALLBACK=NO
JUXTAPOSITION_SLOT_GRAMMAR_SOURCE_NEUTRAL=YES
JUXTAPOSITION_SLOT_GRAMMAR_FROZEN=YES
JUXTAPOSITION_RIGHT_ARBITRARY_IDENTIFIER=NO
JUXTAPOSITION_RIGHT_TIMING_KEYWORD_GRAMMAR=FROZEN
JUXTAPOSITION_RIGHT_FUNCTION_FORMS_AUTHORIZED=NO
NEGATIVE_TRANSITION_DURATION_AUTHORIZED=NO
TIME_DURATION_FINITE_REQUIRED=YES
TIME_DURATION_NON_NEGATIVE_REQUIRED=YES
RGB_COLOR_ARGUMENT_GRAMMAR=FROZEN
RGB_COLOR_ARBITRARY_INNER_TEXT=NO
RGB_COLOR_SAFE_VALUE_ONLY_VALIDATION=NO
RGB_FUNCTION_PARSER_ATOM=YES
RGB_TOP_LEVEL_TOKEN_SPLIT_INSIDE_FUNCTION=NO
RGB_INTERNAL_WHITESPACE_POLICY=FROZEN
RGB_WHITESPACE_CONTRADICTION=NO
RGBA_ALPHA_MIN=0
RGBA_ALPHA_MAX=1
RGBA_ALPHA_PERCENT_AUTHORIZED=NO
RGBA_ALPHA_FINITE_REQUIRED=YES
HEX_COLOR_LITERAL=NOT_AUTHORIZED_BY_CURRENT_EVIDENCE
EVIDENCE_HARNESS_BATCH_SIZE_1_ONLY=YES
PRODUCTION_RESOLVER_BATCHING=EXISTING_PER_PROVENANCE_BATCH
PER_OCCURRENCE_RESOLVER_CALL_IMPLEMENTATION=NO
RESOLVER_TERMINAL_CONTRACT_CHANGED=NO
SUBSTITUTION_CAN_EXPAND_GRAMMAR=NO
COMPOUND_SUCCESS_VALUE_CLASSIFICATION=BYPASS_GENERIC_VAR_CALC_CLASSIFIER
COMPOUND_SUCCESS_STYLE_KIND=LITERAL
CSS_DECLARATION_REVALIDATION=REQUIRED
VARIABLE_AUTHORITY_REENTRY=NO
MULTI_TOKEN_INVENTORY_SPECIMEN_COUNT=5
MULTI_TOKEN_INVENTORY_PROVEN_ACCEPTED_COUNT=5
DISCOVERED_TO_CLASSIFIED_GUARD_COMPLETE=YES
IMPLEMENTATION_PLAN_SEMANTIC_DECISIONS_REQUIRED=NO
LOCAL_COMPOUND_TOKEN_INFERENCE=NO
LOCAL_COMPOUND_EXTERNAL_FALLBACK=NO

LIFECYCLE_STATE_NAMES_MATCH_COMPLETED_WORK=YES
EMITTED_TERMINAL_SUCCESS=YES
FUNCTION_ARGUMENT_GRAMMAR=FROZEN
FUNCTION_QUOTING_POLICY=FROZEN
MULTI_TOKEN_IDENTIFIER_POLICY=REJECT_ALL_IDENTIFIERS
MULTI_TOKEN_LITERAL_POLICY=FROZEN
OWNER_FINDING_TO_INVENTORY_SPECIMEN_BIJECTION=NOT_ASSERTED
RESOLVER_STATE_SCOPE_CONTRACT_CHANGED=NO
UNSUPPORTED_SCOPE_BYPASS_AUTHORIZED=NO

BOUNDED_COMPOUND_VALUE_NORMALIZATION=SELECTED_NEXT_GENERIC_CAPABILITY

COMPOUND_ARCHITECTURE_AUTHORITY_STATE=DRAFT_PENDING_INDEPENDENT_REVIEW
COMPOUND_ARCHITECTURE_AUTHORITY_READY=NO
COMPOUND_IMPLEMENTATION_READY=NO
COMPOUND_IMPLEMENTATION_AUTHORIZED=NO

RESOLVER_REFERENCE_RECORD_SCHEMA_CHANGED=NO
RESOLVER_PUBLIC_INTERFACE_CHANGED=NO
DESIGN_IR_SCHEMA_CHANGED=NO
COMPOUND_OCCURRENCE_CORRELATION=NORMALIZER_PRIVATE_ONLY

ROMEO_COMPONENTIZATION_AUTHORIZED=NO
ROMEO_NATIVE_GENERATION_AUTHORIZED=NO
```

Implementation remains unauthorized until this authority is independently
reviewed, merged, and followed by an accepted implementation plan and
`COMPOUND_IMPLEMENTATION_AUTHORIZED=YES`.

Programme records: [canonical gap decomposition](feature_romeo_canonical_gap_decomposition.md),
[CSS local custom-property resolution authority](css_local_custom_property_resolution_authority.md),
[no-ACSS normalization record](feature_romeo_canonical_no_acss_normalization.md).

## Decision

Compound-value work is **architectural**, not a one-function extension of
`normalize_declaration_value/3`.

Today `CustomCssNormalizer` creates `SourceLocalCustomPropertyResolver`
reference records only when a declaration value is an **exact direct**
`var(--name)` spelling. Compound values do not produce those records. Resolver
results correlate back to declarations before value normalization. Teaching
`normalize_declaration_value/3` alone to accept function or multi-token syntax
would skip proven owner, provenance, ancestry, and authority checks for
embedded local references and would risk a second variable-resolution path.

**Select Option B — bounded compound parse with existing resolver integration.**

```text
SELECTED_ARCHITECTURE=OPTION_B
OPTION_B_VERDICT=BOUNDED_COMPOUND_PARSE_PLUS_EXISTING_LOCAL_RESOLVER
```

### Required dataflow

```text
bounded compound parse
  -> extract embedded local-reference occurrences (each with frozen SLOT_GRAMMAR)
  -> resolve occurrences through SourceLocalCustomPropertyResolver (unchanged contract)
  -> validate each {:ok, terminal} against its occurrence SLOT_GRAMMAR
  -> reconstruct one bounded terminal string
  -> revalidate the SAME production identity using RESOLVED_FORM_GRAMMAR
  -> CSSDeclaration.normalize(..., :source_resolver) safety acceptance
  -> existing literal StyleValue emission (no generic var()/calc() classifier)
```

`SourceLocalCustomPropertyResolver` remains the single local-definition
authority. It must not gain general compound CSS grammar or recursive
substitution.

### Rejected alternatives

| Alternative | Verdict |
| --- | --- |
| Resolve embedded `var()` only inside `normalize_declaration_value/3` | **REJECTED** — duplicates provenance and ancestry semantics |
| Teach `SourceLocalCustomPropertyResolver` compound or recursive CSS grammar | **REJECTED** — resolver stays selection + fail-closed dependency classification |
| General CSS evaluator or arbitrary function execution | **REJECTED** — gap authority |
| External authority fallback when compound or embedded local resolution fails | **REJECTED** — same fail-closed posture as local slice |
| Partial selector-rule emission when one declaration fails | **REJECTED** — whole-rule atomicity preserved |

### Module boundary (implementation target, not authorized yet)

```text
apps/live_frames/lib/live_frames/adapters/bricks/compound_css_value.ex
apps/live_frames/test/live_frames/bricks_compound_css_value_test.exs
```

`CompoundCssValue` (name frozen at plan time) is a **pure** bounded parser and
reconstructor. It returns a private representation or a closed error atom. It
emits no Design IR, no executable CSS, and no token inference.

`CustomCssNormalizer` retains source/provenance scope, selector/target
correlation, resolver batching, **occurrence correlation** (private), reference
record construction, whole-rule atomicity, final `CSSDeclaration` validation,
and `StyleValue` emission.

`CompoundCssValue` owns only bounded syntax parse, embedded-reference occurrence
representation, and deterministic bounded reconstruction. It must not call
`VariableAuthority`, select definitions, perform ancestry lookup, infer tokens,
emit `StyleValue`, know source-specific IDs, or parse selectors.

## Compiler lifecycle

Every compound declaration follows this lifecycle. Each transition has a hard
guard. Failure at any step is terminal for that declaration on that canonical
run and maps to **fail-closed residual** (whole rule retained when atomicity
applies).

```text
DISCOVERED
  -> GRAMMAR_CLASSIFIED
  -> PARSED_SUPPORTED
  -> LOCAL_REFERENCES_COLLECTED
  -> LOCAL_REFERENCES_RESOLVED
  -> TERMINAL_RECONSTRUCTED
  -> CSS_REVALIDATED
  -> EMITTED
```

```text
FAIL_CLOSED_RESIDUAL
  = unsupported syntax
  | unresolved embedded local reference
  | closed resolver outcome (including NO_LOCAL_DEFINITION, UNSUPPORTED_NESTED_REFERENCE)
  | unsafe reconstructed terminal
  | limit exceeded
  | external-authority ambiguity on local lane
  | CSS revalidation failure
```

```text
WHOLE_RULE_ATOMICITY=UNCHANGED
one declaration fails
  -> no partial selector-rule emission
  -> original rule remains residual
```

No lifecycle state may route into `VariableAuthority` as a substitute for
failed embedded local resolution.

Any failed guard transitions to `FAIL_CLOSED_RESIDUAL` with no recovery or
external-authority fallback.

### Lifecycle transition table

State names denote **completed work**. `EMITTED` is terminal success.
`FAIL_CLOSED_RESIDUAL` is terminal failure. There is no transition out of
`FAIL_CLOSED_RESIDUAL`.

| From | Guard | Side effect (on success) | Success state | Failure state |
| --- | --- | --- | --- | --- |
| `DISCOVERED` | Value is not an exact direct `var(--name)`; byte length ≤ `MAX_COMPOUND_VALUE_BYTES`; exactly one frozen compound production matches disjoint rules (2)–(4) | Attach the matching production identity | `GRAMMAR_CLASSIFIED` | `FAIL_CLOSED_RESIDUAL` |
| `GRAMMAR_CLASSIFIED` | Selected production parses within all frozen production bounds | Build private bounded parse representation | `PARSED_SUPPORTED` | `FAIL_CLOSED_RESIDUAL` |
| `PARSED_SUPPORTED` | Embedded occurrence count within bounds; every embedded local name passes the accepted local-name boundary | Extract occurrences; assign normalizer-private `occurrence_index`; append unchanged resolver reference records | `LOCAL_REFERENCES_COLLECTED` | `FAIL_CLOSED_RESIDUAL` |
| `LOCAL_REFERENCES_COLLECTED` | When embedded occurrence count is zero, vacuous success. Otherwise existing `resolve/3` returns one ordered result per routed record and every result required for this declaration is `{:ok, terminal}` | Correlate returned terminals with occurrence correlation (or none) | `LOCAL_REFERENCES_RESOLVED` | `FAIL_CLOSED_RESIDUAL` |
| `LOCAL_REFERENCES_RESOLVED` | Every `{:ok, terminal}` satisfies that occurrence's frozen `SLOT_GRAMMAR`; deterministic substitution succeeds within `MAX_RECONSTRUCTED_TERMINAL_BYTES` | Substitute validated terminals into the private parse representation | `TERMINAL_RECONSTRUCTED` | `FAIL_CLOSED_RESIDUAL` |
| `TERMINAL_RECONSTRUCTED` | Reconstructed value satisfies the **same production identity** as `GRAMMAR_CLASSIFIED` under that production's frozen **resolved-form** grammar; no `var(` remains; byte/token/depth limits hold; `CSSDeclaration` accepts on `:source_resolver` without generic `var()`/`calc()` value classification | Hold bounded literal declaration candidate (`COMPOUND_SUCCESS_STYLE_KIND=LITERAL`) | `CSS_REVALIDATED` | `FAIL_CLOSED_RESIDUAL` |
| `CSS_REVALIDATED` | All declarations in the selector rule pass existing whole-rule atomicity | Emit normalized style as existing literal `StyleValue` (no `VariableAuthority` reentry) | `EMITTED` | `FAIL_CLOSED_RESIDUAL` |

```text
LIFECYCLE_STATE_NAMES_MATCH_COMPLETED_WORK=YES
EMITTED_TERMINAL_SUCCESS=YES
DISCOVERED_TO_CLASSIFIED_GUARD_COMPLETE=YES
```

## Count model

Do not equate owner findings, template identities, sanitized inventory specimens,
declaration-level compound shapes, embedded `var(` occurrences, resolver
reference records, or residual fingerprints.

```text
COMPOUND_OWNER_FINDING_COUNT=8
COMPOUND_TEMPLATE_IDENTITY_COUNT=2
OWNER_COUNT=4

SOURCE_EXPRESSION_OCCURRENCE_INVENTORY_COUNT=8
SOURCE_EXPRESSION_OCCURRENCE_INVENTORY_SHAPE_COUNTS=
  FUNCTION_CALL:2
  MULTI_TOKEN_VALUE:5
  VAR_REFERENCE_WITH_OPERATION:1

OWNER_EXPANDED_COMPOUND_DECLARATION_OCCURRENCE_COUNT=SEPARATE_UNIT
EMBEDDED_VAR_OCCURRENCE_COUNT=SEPARATE_UNIT
RESOLVER_REFERENCE_RECORD_COUNT=SEPARATE_UNIT
RESIDUAL_FINGERPRINT_COUNT=SEPARATE_UNIT
```

**`COMPOUND_OWNER_FINDING_COUNT` (8):** one confirmed required compound
residual per card owner per template identity — four owners × overlay template
plus four owners × state template. This is the lane finding unit from accepted
gap and no-ACSS records.

**`SOURCE_EXPRESSION_OCCURRENCE_INVENTORY_COUNT` (8):** the accepted gap
decomposition safe-inspection inventory — eight sanitized expression specimens
each assigned exactly one grammar shape label (`2 + 5 + 1 = 8`). The inventory
shape counts describe **these eight specimens only**, not template-declaration
totals and not resolver record counts.

```text
OWNER_FINDING_TO_INVENTORY_SPECIMEN_BIJECTION=NOT_ASSERTED
```

Equal counts (`8` and `8`) do **not** prove a bijection between owner findings
and inventory specimens. Joined-template re-verification shows multiple compound
declarations inside a single overlay owner finding. Gap decomposition does not
publish a per-finding specimen map in this record.

**`OWNER_EXPANDED_COMPOUND_DECLARATION_OCCURRENCE_COUNT`:** supplementary
re-verification on joined export templates counts compound declarations that
require this capability (overlay template: three compound declarations; state
template: one). Owner expansion of declaration occurrences is **not** equal to
eight and is **not** labeled by the `2 / 5 / 1` inventory.

**`EMBEDDED_VAR_OCCURRENCE_COUNT`:** supplementary joined-template scan —
overlay template three declarations containing embedded `var(` with four total
occurrences; state template one declaration with two occurrences. This unit
feeds resolver batching estimates only.

## Grammar (three mutually exclusive productions)

Three productions are required by confirmed evidence. They share one
normalizer owner. Each value matches **at most one** production; there is no
classification precedence list.

Direct-only `var(--name)` values remain on the **existing direct-reference
path**, not this grammar.

**Disjoint classification (exhaustive, in this order):**

1. **Direct path** — entire trimmed value matches direct `var(--name)` → not
   compound grammar (existing local-reference path).
2. **`FUNCTION_CALL`** — trimmed value matches a frozen outer call (see
   below).
3. **`VAR_REFERENCE_WITH_OPERATION`** — trimmed value matches frozen
   juxtaposition syntax (see below). Despite the lane name, canonical evidence
   contains **no** binary-operator specimens; operator tokens are not
   authorized.
4. **`MULTI_TOKEN_VALUE`** — trimmed value is exactly two `DIMENSION_LITERAL`
   tokens separated by one or more ASCII whitespace characters; does not match
   (2) or (3); contains no `var(`; no outer frozen function call at position
   zero.
5. Otherwise → `FAIL_CLOSED_RESIDUAL`.

```text
GRAMMAR_PRODUCTIONS_MUTUALLY_EXCLUSIVE=YES
GRAMMAR_CLASSIFICATION_PRECEDENCE_REQUIRED=NO
```

**Explicit rejects (all productions):** general CSS evaluation; outer function
names other than the frozen allowlist (`linear-gradient`, `calc`); binary
operators in `VAR_REFERENCE_WITH_OPERATION` and `MULTI_TOKEN_VALUE` (zero
inventory specimens); `*` only where explicitly authorized inside frozen
`calc` argument grammar; recursive expression evaluation; unbounded nesting;
raw source passthrough to Design IR or generated CSS.

### Production `FUNCTION_CALL`

**Frozen allowlist (outer name only):** `linear-gradient`, `calc` (case-insensitive
ASCII identifier before `(`).

**Shape:** entire trimmed value is one allowlisted name, `(`, a bounded argument
span, and a closing `)` with no tokens outside the call.

**Embedded local references (`FUNCTION_CALL_EMBEDDED_VAR_POLICY`):** Canonical
joined-template evidence shows **both** allowlisted calls carry embedded
`var(--name)` spans inside the argument region. Policy:

- `var(--name)` is the **only** permitted nested call-like form inside the
  argument span.
- It is tokenized for occurrence extraction; it is **not** modeled as a nested
  `FUNCTION_CALL` production and does **not** increment `MAX_COMPOUND_PARSE_DEPTH`.
- Any other `(`-initiated function form inside the argument span →
  `FAIL_CLOSED_RESIDUAL`.
- Argument spans are not recursively evaluated; no inner `linear-gradient` /
  `calc` parsing.

**Frozen argument grammars (`FUNCTION_ARGUMENT_GRAMMAR=FROZEN`):**

Canonical joined-template safe inspection (boolean flags only; no raw source
published) shows: **no quoted strings** in either allowlisted call; both carry
embedded `var(--name)`; `linear-gradient` uses comma-separated inner segments
with angle/percentage/keyword/var atoms; `calc` inner span is comma-free with
embedded `var(--name)`.

```text
FUNCTION_QUOTING_POLICY=REJECT_ALL_QUOTED_STRING_ARGUMENTS
QUOTED_STRING_ARGUMENTS=REJECT
```

**`linear-gradient` argument** (single inner span, ≤ `MAX_FUNCTION_ARGUMENT_BYTES`):

- Must match: `<angle> , <stop-list>` where `<angle>` is
  `\d+(\.\d+)?deg` (ASCII digits, optional fraction, literal suffix `deg`).
- `<stop-list>` is one to `MAX_LINEAR_GRADIENT_STOPS` comma-separated **stop
  segments** (comma + optional ASCII whitespace only as delimiter between
  segments).
- Each **stop segment** is one to `MAX_STOP_SEGMENT_TOKENS` whitespace-separated
  atoms; each atom is exactly one of:
  - literal keyword `transparent`;
  - percentage `\d+(\.\d+)?%`;
  - embedded direct `var(--name)` (local name per existing boundary);
  - **not** a general identifier.
- Operators, hashes, and nested `(` except embedded `var(--name)` → reject.

**`calc` argument** (single inner span, ≤ `MAX_FUNCTION_ARGUMENT_BYTES`):

- Must match exactly one of these forms (ASCII whitespace flexible around
  tokens):
  - `var(--name)`;
  - `var(--name) * <positive-finite-number>` where
    `<positive-finite-number>` uses the same `positive_finite_number/1` contract
    as `CustomCssNormalizer` (positive finite float, empty suffix, no unit).
- No comma, no second `var(`, no operators other than the single `*` form above,
  no nested `(` besides `var(`.

```text
FUNCTION_CALL_EMBEDDED_VAR_POLICY=PROVEN_AND_FROZEN
FUNCTION_CALL_NESTING_ACCOUNTING=
  OUTER_ALLOWLISTED_CALL_COUNTS_AS_DEPTH_1
  EMBEDDED_var_COUNTS_AS_DEPTH_0
  OTHER_NESTED_FUNCTIONS=REJECT
FUNCTION_ARGUMENT_GRAMMAR=FROZEN
FUNCTION_QUOTING_POLICY=FROZEN
MAX_COMPOUND_PARSE_DEPTH=1
MAX_LINEAR_GRADIENT_STOPS=8
MAX_STOP_SEGMENT_TOKENS=4
```

**`FUNCTION_CALL` source form vs resolved form (`PRODUCTION_IDENTITY` unchanged):**

| Phase | Grammar |
| --- | --- |
| **Source form** | Frozen outer `linear-gradient` / `calc` argument spans above, with embedded `var(--name)` atoms where authorized. |
| **Resolved form** | Same outer call shape and argument span bounds; every former embedded `var(--name)` atom is replaced by one `GRADIENT_STOP_ATOM` or `CALC_OPERAND` terminal that already passed slot validation. No `var(` remains anywhere in the value. |

### Production `MULTI_TOKEN_VALUE`

**Frozen shape (evidence-backed):** exactly **two** tokens, one ASCII
whitespace run between them (`MULTI_TOKEN_TOKEN_COUNT_MIN=2`,
`MULTI_TOKEN_TOKEN_COUNT_MAX=2`). Value does not satisfy `FUNCTION_CALL` or
`VAR_REFERENCE_WITH_OPERATION`.

**Frozen literal class (`MULTI_TOKEN_LITERAL_POLICY=FROZEN`):** both tokens
must be **`DIMENSION_LITERAL`** — matches
`~r/^-?\d+(\.\d+)?(px|rem|em|vh|vw|fr|deg|%)$/` (case-sensitive unit suffix;
unary minus only inside the dimension token, not a separate operator token).
Values with `%` use this same class when `%` is the unit suffix; there is no
separate production-4 percentage token class
(`MULTI_TOKEN_SEPARATE_PERCENTAGE_CLASS_AUTHORIZED=NO`).

**Explicit rejects:** keyword tokens (`MULTI_TOKEN_KEYWORD_AUTHORIZED=NO`);
embedded `var(--name)` (`MULTI_TOKEN_EMBEDDED_LOCAL_REFERENCE_AUTHORIZED=NO`);
unitless number literals (`MULTI_TOKEN_UNITLESS_NUMBER_AUTHORIZED=NO`); token
counts other than two (`MULTI_TOKEN_UNEVIDENCED_TOKEN_COUNT_AUTHORIZED=NO`);
general identifiers; top-level commas; semicolons; `calc(` at position zero;
values matching production 3; any `(`-initiated function token (not production
2); ASCII whitespace-separated binary operators (`+`, `-`, `*`, `/` between
tokens).

```text
MULTI_TOKEN_HASH_USED_AS_EVIDENCE_ONLY=YES
MULTI_TOKEN_HASH_USED_AS_IMPLEMENTATION_SELECTOR=NO
MULTI_TOKEN_TOKEN_COUNT_MIN=2
MULTI_TOKEN_TOKEN_COUNT_MAX=2
MULTI_TOKEN_KEYWORD_AUTHORIZED=NO
MULTI_TOKEN_SEPARATE_PERCENTAGE_CLASS_AUTHORIZED=NO
MULTI_TOKEN_UNITLESS_NUMBER_AUTHORIZED=NO
MULTI_TOKEN_EMBEDDED_LOCAL_REFERENCE_AUTHORIZED=NO
MULTI_TOKEN_UNEVIDENCED_TOKEN_CLASS_AUTHORIZED=NO
MULTI_TOKEN_UNEVIDENCED_TOKEN_COUNT_AUTHORIZED=NO
MULTI_TOKEN_LOCAL_RESOLVER_REFERENCES_CURRENT_CAPABILITY=0
```

**Resolver integration (current freeze):** all five inventory specimens have
`EMBEDDED_LOCAL_REFERENCE_COUNT=0`. Production 4 must not append resolver
reference records or invoke `resolve/3` for that declaration (vacuous
`LOCAL_REFERENCES_RESOLVED`). Resolver batching remains required for productions
2 and 3 only.

**`MULTI_TOKEN_VALUE` source form vs resolved form:**

| Phase | Grammar |
| --- | --- |
| **Source form** | `DIMENSION_LITERAL` + ASCII whitespace + `DIMENSION_LITERAL` (exactly two dimension tokens). |
| **Resolved form** | Identical to source form on the current freeze (no embedded locals; no substitution). |

### MULTI_TOKEN inventory structural proof (five gap specimens)

Gap authority assigns **five** sanitized inventory specimens the
`MULTI_TOKEN_VALUE` label (`SOURCE_EXPRESSION_OCCURRENCE_INVENTORY_SHAPE_COUNTS`).
This record proves each inventory slot against the **frozen** production above
using safe hashes only (no raw specimen strings).

**Proof method:** Romeo canonical joined-export declaration scan plus multiset
reconciliation. Three unique value safe hashes reproduce all five inventory
slots: two slots share the `77976a3c…` structure, two share `f37901a6…`, one
uses `ae28d73e…`. A separate joined-export declaration safe hash
`d1b725ae…` is **not** an inventory MULTI specimen — it contains top-level
commas and function tokens and is excluded from production 4 (supplementary
loose-shape scan only).

```text
MULTI_TOKEN_INVENTORY_SPECIMEN_COUNT=5
MULTI_TOKEN_INVENTORY_PROVEN_ACCEPTED_COUNT=5
MULTI_TOKEN_JOINED_EXPORT_UNIQUE_FROZEN_MULTI_VALUE_COUNT=3
MULTI_TOKEN_TOKEN_COUNT_MIN=2
MULTI_TOKEN_TOKEN_COUNT_MAX=2
MULTI_TOKEN_KEYWORD_AUTHORIZED=NO
MULTI_TOKEN_SEPARATE_PERCENTAGE_CLASS_AUTHORIZED=NO
MULTI_TOKEN_UNITLESS_NUMBER_AUTHORIZED=NO
MULTI_TOKEN_EMBEDDED_LOCAL_REFERENCE_AUTHORIZED=NO
MULTI_TOKEN_UNEVIDENCED_TOKEN_CLASS_AUTHORIZED=NO
MULTI_TOKEN_UNEVIDENCED_TOKEN_COUNT_AUTHORIZED=NO
MULTI_TOKEN_LOCAL_RESOLVER_REFERENCES_CURRENT_CAPABILITY=0
```

| Inventory slot | `SPECIMEN_SAFE_HASH` | `TOKEN_COUNT` | `TOKEN_CLASS_SEQUENCE` | `EMBEDDED_LOCAL_REFERENCE_COUNT` | `TOP_LEVEL_COMMA` | `FUNCTION_TOKEN` | `OPERATOR_TOKEN` | `FROZEN_MULTI_TOKEN_GRAMMAR_ACCEPTS` |
| ---: | --- | ---: | --- | ---: | --- | --- | --- | --- |
| 1 | `77976a3cd61c02d4dfff52f29ba10490ed91a8862d2b569a8cbdbedb2a9fc7eb` | 2 | `DIMENSION,DIMENSION` | 0 | NO | NO | NO | YES |
| 2 | `f37901a6d5aa5afc748505d0bf0739fe019c70f71e5d1aafdf849e846584de78` | 2 | `DIMENSION,DIMENSION` | 0 | NO | NO | NO | YES |
| 3 | `f37901a6d5aa5afc748505d0bf0739fe019c70f71e5d1aafdf849e846584de78` | 2 | `DIMENSION,DIMENSION` | 0 | NO | NO | NO | YES |
| 4 | `ae28d73e456a6b2f07d4ff7064d44218457d7aff8b2e51323d1b563d68992f36` | 2 | `DIMENSION,DIMENSION` | 0 | NO | NO | NO | YES |
| 5 | `77976a3cd61c02d4dfff52f29ba10490ed91a8862d2b569a8cbdbedb2a9fc7eb` | 2 | `DIMENSION,DIMENSION` | 0 | NO | NO | NO | YES |

Slot 5 is structurally identical to slot 1 (same `SPECIMEN_SAFE_HASH` and
token-class sequence). Joined-export reproduction shows one declaration
occurrence for that hash; the second gap inventory slot with the same structure
is proven by **signature equality** to slot 1, not by a second distinct export
occurrence.

### Production `VAR_REFERENCE_WITH_OPERATION`

**Frozen syntax (canonical evidence):** exactly **two** direct `var(--name)`
spans separated by **ASCII whitespace only** (one or more space characters).
No operator token appears between the spans in accepted evidence.

**Explicit rejects:** three or more `var(` spans; any `+`, `-`, `*`, `/`
between spans; `calc(`; outer function call; literals between spans unless a
future authority revision documents a specimen.

**Inventory mapping:** one of eight inventory specimens carries this label
(gap decomposition). Joined-template re-verification shows the same juxtaposition
class on one overlay transition declaration and one state transition declaration
(supplementary; not a second inventory unit).

**`VAR_REFERENCE_WITH_OPERATION` source form vs resolved form:**

| Phase | Grammar |
| --- | --- |
| **Source form** | `LOCAL_REF WS LOCAL_REF` — exactly two embedded direct `var(--name)` spans separated by ASCII whitespace only. |
| **Resolved form** | `JUXTAPOSITION_LEFT_OPERAND WS JUXTAPOSITION_RIGHT_OPERAND` — same whitespace rule; each operand is one slot-validated resolver terminal. No `var(`. |

### Grammar classification rule

```text
GRAMMAR_CLASSIFIED
  = exactly one production from disjoint rules (2)–(4)
  | FAIL_CLOSED_RESIDUAL
```

### Source form vs resolved form (all productions)

Classification and initial parse use **source-form** grammars (embedded
`var(--name)` permitted where frozen above). After substitution, revalidation
uses **resolved-form** grammars for the **same production identity**. Resolved
forms never require `var(`.

```text
PRODUCTION_IDENTITY_PRESERVED_AFTER_RESOLUTION=YES
SOURCE_FORM_GRAMMAR_FROZEN=YES
RESOLVED_FORM_GRAMMAR_FROZEN=YES
POST_SUBSTITUTION_REVALIDATION_USES_RESOLVED_FORM=YES
POST_SUBSTITUTION_VAR_REMAINS=NO
```

Revalidation does **not** re-run disjoint classification from raw text alone; it
checks the private parse tree / reconstructed string against the frozen
resolved-form production attached at `GRAMMAR_CLASSIFIED`.

## Local reference extraction and resolver integration

### Extraction

After `PARSED_SUPPORTED`, scan the bounded parse tree for `var(--name)` spans
that match `CSSDeclaration.safe_property?/1` local names (`--` prefix).
Production `MULTI_TOKEN_VALUE` on the current freeze embeds none
(`MULTI_TOKEN_LOCAL_RESOLVER_REFERENCES_CURRENT_CAPABILITY=0`); those
declarations contribute zero reference records.

For each occurrence:

1. Build a resolver **reference** record with the **unchanged** schema and
   trust rules as today's direct-reference path (owner, provenance, target path,
   viewport, state scope). The resolver record does not gain `reference_id`,
   `occurrence_index`, or any compound-specific field.
2. Assign a deterministic **occurrence correlation** private to
   `CustomCssNormalizer` for mapping ordered resolver results back into the
   compound parse.

```text
RESOLVER_REFERENCE_RECORD_SCHEMA_CHANGED=NO
RESOLVER_PUBLIC_INTERFACE_CHANGED=NO
COMPOUND_OCCURRENCE_CORRELATION=NORMALIZER_PRIVATE_ONLY
```

### Occurrence correlation (normalizer-private)

The accepted local-resolver architecture keeps correlation **outside** the
resolver reference record. Today the normalizer-private declaration key is:

```text
{
  rule_id,
  target_source_id,
  selector_identity,
  property
}
```

Compound values extend **only** that private correlation key:

```text
{
  rule_id,
  target_source_id,
  selector_identity,
  property,
  occurrence_index
}
```

`occurrence_index` is a zero-based stable order of discovery in the bounded
parse (left-to-right, depth-first within the compound grammar). This tuple is
not part of `SourceLocalCustomPropertyResolver` input records and is not
serialized to Design IR.

The resolver continues to receive existing reference record structures and
returns ordered **one result per reference record** in batch order. The
normalizer maps each result to the matching private occurrence correlation
before reconstruction.

### Batching

Embedded references from all declarations in an owner/provenance batch merge
into the **existing** resolver batch for that provenance identity. No
per-declaration resolver invocation is required if the current batching contract
already groups by provenance; occurrence cardinality must respect
`MAX_LOCAL_REFERENCES_PER_OWNER_LAYER`.

### Resolver outcomes

Apply resolver results **without reinterpretation**:

| Resolver result | Compound lifecycle |
| --- | --- |
| `{:ok, terminal}` | Validate terminal against occurrence `SLOT_GRAMMAR`, then substitute |
| `:no_local_definition` | `FAIL_CLOSED_RESIDUAL` |
| `:unsupported_nested_reference` | `FAIL_CLOSED_RESIDUAL` |
| `:unsupported_scope` | `FAIL_CLOSED_RESIDUAL` |
| Other closed errors | `FAIL_CLOSED_RESIDUAL` |
| `:resource_limit_exceeded` | `FAIL_CLOSED_RESIDUAL` (batch) |

### Resolver `state_scope` (unchanged contract)

`SourceLocalCustomPropertyResolver` rejects every reference record with
`state_scope != nil` with `:unsupported_scope`. This authority does not change
that contract (`RESOLVER_STATE_SCOPE_CONTRACT_CHANGED=NO`,
`UNSUPPORTED_SCOPE_BYPASS_AUTHORIZED=NO`).

Reference records inherit `state_scope` from `selection.condition` when built
by `CustomCssNormalizer`. Supplementary joined-template safe inspection (no raw
selectors published) shows **no pseudo-state token** in overlay or state
template selectors for the two compound template identities. Embedded local
references routed from those templates therefore have
`state_scope == nil` in this evidence pass.

```text
COMPOUND_REFERENCE_STATE_SCOPE_NIL_COUNT_JOINED_TEMPLATE_EMBEDDED_OCCURRENCES=6
COMPOUND_REFERENCE_STATE_SCOPE_NON_NIL_COUNT_JOINED_TEMPLATE_EMBEDDED_OCCURRENCES=0
OWNER_EXPANDED_STATE_SCOPE_COUNTS=NOT_ASSERTED_IN_THIS_RECORD
```

If a future owner export routes compound embedded references with non-`nil`
`state_scope`, expect `UNSUPPORTED_SCOPE` and `FAIL_CLOSED_RESIDUAL` without
resolver changes.

**FRAME C and FRAME D must not become executable** because compound parsing
succeeds. In particular:

```text
compound grammar supported
+ embedded definition resolves to UNSUPPORTED_NESTED_REFERENCE
= FAIL_CLOSED_RESIDUAL (whole rule if atomicity applies)
```

### Post-resolution grammar safety (`SLOT_GRAMMAR`)

`SourceLocalCustomPropertyResolver` returns bounded terminal strings but does
**not** guarantee that a terminal is syntactically valid for the compound slot
into which it will be substituted. `CSSDeclaration.safe_value?/1` is a safety
boundary, not compound grammar validation.

```text
RESOLVER_TERMINAL_CONTRACT_CHANGED=NO
RESOLVED_TERMINAL_SLOT_VALIDATION=REQUIRED
POST_SUBSTITUTION_COMPOUND_REVALIDATION=REQUIRED
SUBSTITUTION_CAN_EXPAND_GRAMMAR=NO
SLOT_GRAMMAR_CONTRACTS_FROZEN=YES
```

The private bounded parse representation must carry, for every embedded
occurrence, a frozen **`SLOT_GRAMMAR`** class (location + resolved terminal
contract).

#### Frozen `SLOT_GRAMMAR` semantic contracts (resolved terminals)

All slots share these global bounds unless a row narrows further:

- `TERMINAL_TOKEN_COUNT=1` at **top-level** compound tokenization (exactly one
  whitespace-delimited token per slot). `RGB_COLOR_FUNCTION_LITERAL` is a
  **compound-parser atom**: commas and bounded internal delimiter whitespace
  inside the function do **not** split the value into multiple top-level tokens
  (`RGB_TOP_LEVEL_TOKEN_SPLIT_INSIDE_FUNCTION=NO`).
- `MAX_BYTES=MAX_TERMINAL_VALUE_BYTES` (4096, resolver cap).
- `VAR_REMAINS=NO`, `SEMICOLON=NO`, `TOP_LEVEL_COMMA=NO`, `UNMATCHED_PAREN=NO`.
- `FUNCTION_POLICY=NO` except the frozen `RGB_COLOR_FUNCTION_LITERAL` grammar
  below.

| `SLOT_GRAMMAR` | Permitted resolved terminal classes |
| --- | --- |
| `GRADIENT_STOP_ATOM` | `GRADIENT_KEYWORD_TRANSPARENT` (`transparent`); `PERCENTAGE_LITERAL` (`\d+(\.\d+)?%`); `DIMENSION_LITERAL` (`^-?\d+(\.\d+)?(px|rem|em|vh|vw|fr|deg|%)$`); `RGB_COLOR_FUNCTION_LITERAL` (frozen grammar below). `HEX_COLOR_LITERAL` is **not** authorized on this slot until a canonical `{:ok, terminal}` tracer documents a hex stop (`HEX_COLOR_LITERAL=NOT_AUTHORIZED_BY_CURRENT_EVIDENCE`). |
| `CALC_OPERAND` | `UNITLESS_NUMBER_LITERAL` (`^-?\d+(\.\d+)?$` matching `positive_finite_number/1` when used as calc factor); `DIMENSION_LITERAL`; `PERCENTAGE_LITERAL`. |
| `MULTI_TOKEN_ATOM` | `DIMENSION_LITERAL` only — same bounded class as production 4 tokens (`MULTI_TOKEN_LITERAL_POLICY=FROZEN`). Not used on the current freeze because production 4 has no embedded locals; reserved for a future evidence-backed extension. |
| `JUXTAPOSITION_LEFT_OPERAND` | `TIME_DURATION_LITERAL` only — lexical form `^(\d+(\.\d+)?|\.\d+)(s|ms)$` with **no** leading `+` or `-`. Semantic guard: parsed numeric magnitude is finite and `>= 0` (`NEGATIVE_TRANSITION_DURATION_AUTHORIZED=NO`, `TIME_DURATION_FINITE_REQUIRED=YES`, `TIME_DURATION_NON_NEGATIVE_REQUIRED=YES`). |
| `JUXTAPOSITION_RIGHT_OPERAND` | `TRANSITION_TIMING_KEYWORD` only — exact member of the frozen finite allowlist below (no function forms, no arbitrary identifiers). |

**Frozen `JUXTAPOSITION_RIGHT_OPERAND` timing keywords (`JUXTAPOSITION_RIGHT_TIMING_KEYWORD_GRAMMAR=FROZEN`):**

Canonical actual `resolve/3` juxtaposition successes (safe hash
`16c2539d96224e3c2de41c934cc96810ef4876a45ab4b911f35f98a2e7b1ab3e` for every
right-hand operand) require exactly **one** source-neutral keyword in the
no-parentheses transition-timing-function category:

```text
ease-in-out
```

```text
JUXTAPOSITION_RIGHT_ARBITRARY_IDENTIFIER=NO
JUXTAPOSITION_RIGHT_TIMING_KEYWORD_GRAMMAR=FROZEN
JUXTAPOSITION_RIGHT_FUNCTION_FORMS_AUTHORIZED=NO
```

Do not accept `cubic-bezier(...)`, `steps(...)`, `linear(...)`, or other
function-shaped timing values on this lane unless a future authority revision
documents a specimen and extends the grammar.

**Frozen `RGB_COLOR_FUNCTION_LITERAL` (`RGB_COLOR_ARGUMENT_GRAMMAR=FROZEN`):**

`RGB_COLOR_FUNCTION_LITERAL` is **one compound-parser atom**
(`RGB_FUNCTION_PARSER_ATOM=YES`). Top-level whitespace tokenization must not
split inside the function (`RGB_TOP_LEVEL_TOKEN_SPLIT_INSIDE_FUNCTION=NO`).

**Internal whitespace (`RGB_INTERNAL_WHITESPACE_POLICY=FROZEN`):** canonical
joined-template safe inspection reports **no** interior ASCII whitespace in
observed `rgb` / `rgba` color literals on this lane. Internal whitespace is
**not** authorized unless a future tracer documents a specimen. Lexical form is
tightly parenthesized comma-separated arguments with **no** spaces:

- `rgb(` + three channel arguments + `)`
- `rgba(` + three channel arguments + `,` + alpha + `)`

Function name is exactly `rgb` or `rgba` (case-insensitive ASCII).

- **`rgb` form:** exactly three channel arguments.
- **`rgba` form:** exactly four arguments (three channels + alpha).

Each channel argument: integer `0`–`255` (`\d{1,3}` with numeric value ≤ 255).
Alpha argument (rgba only): lexical `0`, lexical `1`, or a decimal fraction
matching `^(\d+\.\d+|\d*\.\d+)$` whose parsed numeric value satisfies
`0.0 <= alpha <= 1.0` (`RGBA_ALPHA_MIN=0`, `RGBA_ALPHA_MAX=1`,
`RGBA_ALPHA_FINITE_REQUIRED=YES`, `RGBA_ALPHA_PERCENT_AUTHORIZED=NO`). No
percent signs, no nested `var(`, no nested `(` functions, no slash syntax.

```text
RGB_COLOR_ARGUMENT_GRAMMAR=FROZEN
RGB_COLOR_ARBITRARY_INNER_TEXT=NO
RGB_COLOR_SAFE_VALUE_ONLY_VALIDATION=NO
RGB_FUNCTION_PARSER_ATOM=YES
RGB_TOP_LEVEL_TOKEN_SPLIT_INSIDE_FUNCTION=NO
RGB_INTERNAL_WHITESPACE_POLICY=FROZEN
RGB_WHITESPACE_CONTRADICTION=NO
RGBA_ALPHA_MIN=0
RGBA_ALPHA_MAX=1
RGBA_ALPHA_PERCENT_AUTHORIZED=NO
RGBA_ALPHA_FINITE_REQUIRED=YES
HEX_COLOR_LITERAL=NOT_AUTHORIZED_BY_CURRENT_EVIDENCE
```

**Juxtaposition operand structural evidence (canonical `{:ok, terminal}` shapes,
safe hashes only):**

| Operand slot | `TERMINAL_SAFE_HASH` | `STRUCTURAL_CLASS` | `TOKEN_COUNT` | `IDENTIFIER_SHAPE` | `DURATION_SHAPE` | `NUMBER_SHAPE` | `DIMENSION_SHAPE` | `FUNCTION_SHAPE` |
| --- | --- | --- | ---: | --- | --- | --- | --- | --- |
| `JUXTAPOSITION_LEFT_OPERAND` | `6de8efede839b10ea1411d26c351cc848986e3742e33aa89581e8cd6ec3030f2` | `TIME_DURATION_LITERAL` | 1 | NO | YES | NO | NO | NO |
| `JUXTAPOSITION_RIGHT_OPERAND` | `16c2539d96224e3c2de41c934cc96810ef4876a45ab4b911f35f98a2e7b1ab3e` | `TRANSITION_TIMING_KEYWORD` | 1 | NO | NO | NO | NO | NO |

```text
JUXTAPOSITION_SAFE_VALUE_FALLBACK=NO
JUXTAPOSITION_SLOT_GRAMMAR_SOURCE_NEUTRAL=YES
JUXTAPOSITION_SLOT_GRAMMAR_FROZEN=YES
```

Slot validation runs **before** substitution. Implementation must not hash
tokens or compare specimen digests.

#### Post-substitution flow

After `resolve/3` returns `{:ok, terminal}` for an occurrence:

1. `terminal` must satisfy that occurrence's frozen `SLOT_GRAMMAR` contract.
2. Substitute into the private representation.
3. Reconstructed value must satisfy the **same production identity** using that
   production's **resolved-form** grammar (`POST_SUBSTITUTION_REVALIDATION_USES_RESOLVED_FORM=YES`).
4. Reconstructed value must remain inside byte/token/depth limits and contain
   no unresolved `var(` (`POST_SUBSTITUTION_VAR_REMAINS=NO`).
5. `CSSDeclaration.normalize(..., :source_resolver)` then literal `StyleValue`.

Any failure → `FAIL_CLOSED_RESIDUAL`. If canonical resolver terminals would
require syntax outside these contracts, stop with
`STOP=RESOLVED_TERMINAL_GRAMMAR_UNPROVEN` (resolver contract must not change).

#### Canonical resolver-terminal evidence (`resolve/3` output)

Evidence-only harness on Romeo canonical joined export (no raw terminals, local
names, selectors, paths, or CSS published). Method:

1. Derive `generic_custom_css` owners, node index, and children map using the
   same public Bricks pipeline inputs as `DesignIRNormalizer` (`DependencyExtractor`,
   `TreeBuilder`, `Bricks.to_ir` node paths).
2. Replay `analyze_local_records` field derivation (evidence fork of
   `CustomCssNormalizer` record builder only; **not** repository code) to obtain
   definition records and selector/target routing.
3. Synthesize compound embedded-reference records with the **unchanged**
   resolver reference schema (same fields as today's direct-reference path).
4. Call existing `SourceLocalCustomPropertyResolver.resolve/3` once per unique
   compound reference record (**batch size 1 in the evidence harness only**).

```text
EVIDENCE_HARNESS_BATCH_SIZE_1_ONLY=YES
PRODUCTION_RESOLVER_BATCHING=EXISTING_PER_PROVENANCE_BATCH
PER_OCCURRENCE_RESOLVER_CALL_IMPLEMENTATION=NO
RESOLVER_TERMINAL_EVIDENCE=ACTUAL_RESOLVE_3_OUTPUT
DEFINITION_TERMINAL_PROXY_USED_FOR_ACCEPTANCE=NO
CANONICAL_COMPOUND_REFERENCE_RECORD_COUNT=48
CANONICAL_ACTUAL_RESOLVER_OK_COUNT=40
CANONICAL_ACTUAL_RESOLVER_ERROR_COUNT=8
CANONICAL_ACTUAL_RESOLVER_OK_SLOT_ACCEPTED_COUNT=40
```

Acceptance requires `CANONICAL_ACTUAL_RESOLVER_OK_COUNT ==
CANONICAL_ACTUAL_RESOLVER_OK_SLOT_ACCEPTED_COUNT` (satisfied on this evidence
pass).

| `RESOLVER_RESULT` (compound embedded references) | Count | Notes |
| --- | ---: | --- |
| `{:ok, terminal}` | 40 | All 40 pass frozen `SLOT_GRAMMAR` contracts |
| `:unsupported_nested_reference` | 4 | Gradient-stop embedded locals (FRAME D closed) |
| `:no_local_definition` | 4 | Includes `calc(` embedded locals without eligible definition |

Per-occurrence `OCCURRENCE_SAFE_ID` digests are reproducible from
`(production identity, declaration-value safe hash, occurrence index)` using the
harness above. Implementation verification must publish the full per-occurrence
table on rerun.

**Production batching (not the evidence harness):** `CustomCssNormalizer` must
continue to collect reference records, group by `effective_provenance_identity`,
and invoke **one** existing `resolve/3` batch per provenance with
cardinality-preserving correlation. The harness's batch-size-1 calls classify
terminal shapes only; they are **not** the implementation architecture.

### Reconstruction and final `StyleValue` handoff

After all embedded references for a declaration resolve and pass slot validation:

1. Substitute validated terminals into the bounded parse representation.
2. Emit **one** bounded UTF-8 string (`TERMINAL_RECONSTRUCTED`).
3. Revalidate the **same production identity** on the reconstructed string using
   the frozen **resolved-form** grammar (`POST_SUBSTITUTION_REVALIDATION_USES_RESOLVED_FORM=YES`).
4. Accept through `CSSDeclaration.normalize(..., :source_resolver)` /
   existing safety checks on the local-compound lane.
5. Emit as existing **literal** `StyleValue` — **without** routing the
   reconstructed string through generic `normalize_declaration_value/3`
   `var()`/`calc()` classification.

**Code fact (frozen boundary):** today's `CustomCssNormalizer.normalize_declaration_value/3`
accepts only the specialized `calc(var(--grid-gap) * factor)` case; any other
value containing `calc(` is returned as unresolved. Reconstructed local compound
`calc(...)` values therefore **must not** use that generic classifier on success.

```text
COMPOUND_SUCCESS_VALUE_CLASSIFICATION=BYPASS_GENERIC_VAR_CALC_CLASSIFIER
COMPOUND_SUCCESS_STYLE_KIND=LITERAL
CSS_DECLARATION_REVALIDATION=REQUIRED
VARIABLE_AUTHORITY_REENTRY=NO
```

This is not raw CSS passthrough. A value reaches literal `StyleValue` only
after: frozen compound parse; bounded resolver success; slot validation;
reconstruction; same-production revalidation; `CSSDeclaration` acceptance.

Reconstruction must not introduce new `var(` spans. If substitution would exceed
`MAX_RECONSTRUCTED_TERMINAL_BYTES`, fail closed.

**Local-compound lane isolation:** embedded occurrences route only through
`SourceLocalCustomPropertyResolver`. Reconstructed values must not contain
`var(`. If acceptance would consult `VariableAuthority` because a
non-observed-local or external name appears, the declaration **fails closed** on
this lane rather than inferring tokens or substituting externally.

```text
LOCAL_COMPOUND_TOKEN_INFERENCE=NO
LOCAL_COMPOUND_EXTERNAL_FALLBACK=NO
```

## Finding dependency matrix (eight confirmed required)

### Unit reconciliation

| Unit | Count | Meaning |
| --- | ---: | --- |
| `COMPOUND_OWNER_FINDING_COUNT` | 8 | One compound residual finding per owner per template identity |
| `COMPOUND_TEMPLATE_IDENTITY_COUNT` | 2 | Overlay layout rule pattern; state opacity/transition rule pattern |
| `OWNER_COUNT` | 4 | Card owners in canonical Romeo export |
| `SOURCE_EXPRESSION_OCCURRENCE_INVENTORY_COUNT` | 8 | Gap safe-inspection specimens (`2+5+1` shape labels) |
| `OWNER_EXPANDED_COMPOUND_DECLARATION_OCCURRENCE` (supplementary) | 3× overlay + 1× state **per joined template** | Compound declarations requiring grammar, not owner-finding count |
| `EMBEDDED_VAR_OCCURRENCE` (supplementary) | 4 overlay + 2 state **per joined template** | `var(` spans inside compound declarations |

The `2 / 5 / 1` figures describe **`SOURCE_EXPRESSION_OCCURRENCE_INVENTORY_SHAPE_COUNTS` only**. They do not describe declaration totals on templates, embedded-var totals, or resolver record counts.

### Inventory shape distribution (gap authority)

| Inventory shape label | Specimen count | Role |
| --- | ---: | --- |
| `FUNCTION_CALL` | 2 | Two inventory specimens (allowlisted outer calls) |
| `MULTI_TOKEN_VALUE` | 5 | Five inventory specimens (whitespace token sequences) |
| `VAR_REFERENCE_WITH_OPERATION` | 1 | One inventory specimen (two-`var` whitespace juxtaposition) |

Owner-level assignment of which of the eight findings carries which inventory
label is **not** published in gap records; implementation verification must map
specimens without assuming uniform template-level shape.

### Template supplementary evidence (joined export, no raw source)

| Template identity | Owner findings using template | Compound declarations per template | Frozen outer / juxtaposition forms observed |
| --- | ---: | ---: | --- |
| Overlay layout | 4 | 3 | `linear-gradient`, `calc`, two-`var` juxtaposition (transition) |
| State opacity/transition | 4 | 1 | two-`var` juxtaposition (transition) |

### Per-finding-class dependency (verification)

| Owner-finding class | Count | Grammar productions implicated | Embedded locals | Resolver | Expected disposition |
| --- | ---: | --- | --- | --- | --- |
| Overlay template | 4 | Inventory mix includes `FUNCTION_CALL`, `MULTI_TOKEN_VALUE`, and juxtaposition specimens per gap `2+5+1`; template scan adds frozen `linear-gradient`, `calc`, juxtaposition declarations | Yes (supplementary occurrence totals) | `state_scope == nil` in joined-template evidence; each occurrence must succeed under accepted resolver semantics or fail closed (`NO_LOCAL_DEFINITION`, `UNSUPPORTED_NESTED_REFERENCE`, `UNSUPPORTED_SCOPE`, …) | **DERIVE** — grammar may parse while resolver closed outcomes keep rule residual |
| State template | 4 | Juxtaposition production on transition; inventory includes one juxtaposition specimen | Yes (two occurrences per template) | Same `state_scope` evidence; both occurrences must resolve for transition declaration to reconstruct | **DERIVE** — same fail-closed coupling |

Non-`nil` `state_scope` on any embedded reference record:
`EXPECTED_RESOLVER_RESULT=UNSUPPORTED_SCOPE`,
`EXPECTED_COMPOUND_DISPOSITION=FAIL_CLOSED_RESIDUAL`.

```text
COMPOUND_SUCCESS_CRITERION_8_TO_0=REJECTED
EXPECTED_CANONICAL_DELTA=DERIVE_FROM_MATRIX_AT_IMPLEMENTATION_VERIFY
COUNT_MODEL_RECONCILED=YES
```

Implementation verification must publish observed counts per unit, not a
predetermined zero residual target.

## Bounds and performance

Cold build-time only. Reuse existing limits where they govern the same
resource. Do not add runtime infrastructure.

```text
DATA_LAYER=COLD_BUILD_TIME
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
REDIS=N/A
POSTGRES=N/A
PUBSUB=N/A
OBAN=N/A
```

| Limit | Value | Source |
| --- | ---: | --- |
| `MAX_EFFECTIVE_LAYER_CSS_BYTES` | 65536 | `CustomCssNormalizer` |
| `MAX_LOCAL_DEFINITIONS_PER_OWNER_LAYER` | 256 | normalizer / resolver |
| `MAX_LOCAL_REFERENCES_PER_OWNER_LAYER` | 1024 | normalizer / resolver |
| `MAX_OWNER_ANCESTRY_HOPS` | 64 | resolver |
| `MAX_TERMINAL_VALUE_BYTES` | 4096 | resolver |
| `MAX_LOCAL_SUBSTITUTION_DEPTH` | 1 | local authority (no recursive expand) |
| `MAX_COMPOUND_VALUE_BYTES` | 4096 | aligned with terminal cap |
| `MAX_RECONSTRUCTED_TERMINAL_BYTES` | 4096 | reconstruction output |
| `MAX_COMPOUND_TOKEN_COUNT` | 32 | new compound grammar |
| `MAX_EMBEDDED_LOCAL_REFERENCES_PER_DECLARATION` | 16 | occurrence extraction |
| `MAX_FUNCTION_ARGUMENT_BYTES` | 2048 | function inner span |
| `MAX_LINEAR_GRADIENT_STOPS` | 8 | `linear-gradient` comma segments |
| `MAX_STOP_SEGMENT_TOKENS` | 4 | atoms per gradient stop segment |
| `MAX_COMPOUND_PARSE_DEPTH` | 1 | outer allowlisted call only |

No whole-document rescan per occurrence. Parsing is per declaration value within
already-selected effective CSS. No unbounded recursion, no general expression
evaluator, and no O(N²) tree walk over the document for compound work.
PgBouncer: N/A.

## Authority isolation

The compound capability must not:

- infer tokens from local names or externals;
- expand selector grammar;
- resolve FRAME C (`NO_LOCAL_DEFINITION`) or FRAME D
  (`UNSUPPORTED_NESTED_REFERENCE`) by bypass;
- add source-specific IDs, owner allowlists, or fingerprint-driven branches in
  implementation logic;
- use canonical evidence safe hashes, specimen digests, or Romeo-derived token
  hashes as parser selectors (`MULTI_TOKEN_HASH_USED_AS_IMPLEMENTATION_SELECTOR=NO`);
- emit custom-property definitions into Design IR;
- change Design IR version or `StyleValue` schema for compound success paths;
- use `VariableAuthority` or token inference to salvage failed embedded local
  resolution on the compound lane.

Successful compound normalization emits only values that pass existing
`CSSDeclaration` checks after reconstruction and slot/top-level revalidation.
Permitted success representation on this lane is **literal** `StyleValue` only
(`COMPOUND_SUCCESS_STYLE_KIND=LITERAL`). Token-reference emission on this lane
requires an independent external-authority path not driven by embedded local
`var(` occurrences.

## Design IR impact

```text
COMPOUND_PARSE_IR_EMISSION=NO
COMPOUND_AST_IN_DESIGN_IR=NO
DESIGN_IR_SCHEMA_CHANGED=NO
DESIGN_IR_VERSION_BUMP_REQUIRED=NO
STYLE_VALUE_SCHEMA_CHANGE_REQUIRED=NO
```

Success terminates in existing normalized style values.

## Implementation plan scope (after authority acceptance)

The implementation plan may schedule work only. It must **not** decide grammar
semantics, production boundaries, or count units — those are frozen here.

Permitted plan contents:

1. TDD sequencing (`CompoundCssValue` pure tests, then normalizer integration).
2. Test vectors exercising the frozen productions and fail-closed paths.
3. Occurrence-correlation collision cases across multi-target selector rules.
4. Resolver batch cardinality checks when multiple embedded references share a
   declaration.
5. Canonical rerun protocol publishing **per-unit** deltas from the dependency
   matrix.

```text
IMPLEMENTATION_PLAN_SEMANTIC_DECISIONS_REQUIRED=NO
NEXT_GATE=CSS_COMPOUND_VALUE_ARCHITECTURE_AUTHORITY_REVIEW
THEN=CSS_COMPOUND_VALUE_IMPLEMENTATION_PLAN
IMPLEMENTATION_AUTHORIZED=NO
```
