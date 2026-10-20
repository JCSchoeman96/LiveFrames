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
CSS_COMPOUND_VALUE_SHAPE_COUNTS=FUNCTION_CALL:2;MULTI_TOKEN_VALUE:5;VAR_REFERENCE_WITH_OPERATION:1

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
  -> extract embedded local-reference occurrences
  -> resolve occurrences through SourceLocalCustomPropertyResolver (unchanged contract)
  -> reconstruct one bounded terminal string
  -> existing CSSDeclaration safety / value normalization
  -> existing StyleValue emission
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

Transition guards must include: supported bounded production; byte, token, and
reference bounds; deterministic occurrence ordering; accepted owner/provenance
scope; successful existing resolver results (one ordered result per reference
record, unchanged contract); bounded reconstruction; existing CSS safety
validation. Any failed guard transitions to `FAIL_CLOSED_RESIDUAL` with no
fallback to external authority.

## Count model

Keep these units distinct. Do not equate findings, template identities,
embedded `var(` occurrences, resolver reference records, or residual
fingerprints.

```text
COMPOUND_FINDING_COUNT=8
COMPOUND_TEMPLATE_IDENTITY_COUNT=2
OWNER_EXPANSION_COUNT=4

COMPOUND_FINDING_SHAPE_COUNTS=
  FUNCTION_CALL:2
  MULTI_TOKEN_VALUE:5
  VAR_REFERENCE_WITH_OPERATION:1

REFERENCE_OCCURRENCE_COUNT=SEPARATE_UNIT_NOT_EQUAL_TO_FINDING_COUNT
RESOLVER_REFERENCE_RECORD_COUNT=SEPARATE_UNIT_NOT_EQUAL_TO_FINDING_COUNT
RESIDUAL_FINGERPRINT_COUNT=SEPARATE_UNIT_NOT_EQUAL_TO_FINDING_COUNT
```

The eight findings expand as four owners × two template identities. Template-level
safe inspection observed embedded `var(` declaration and occurrence totals
separate from the eight finding count (see dependency matrix).

## Grammar (three bounded productions)

Canonical evidence requires **three distinct productions** for eight confirmed
required findings. They share one normalization owner; they are not one
interchangeable production.

### Production `FUNCTION_CALL`

**Intent:** Outermost value is a single function invocation.

**Supported shape (bounded):**

- One ASCII identifier (with optional internal `-`) immediately followed by `(`.
- Balanced parentheses with a **bounded argument span** scanned as opaque
  source text subject to delimiter, string, and nesting limits below.
- No additional top-level tokens outside the call (after trim).

**Explicit rejects:** multiple top-level calls, unbalanced parens, disallowed
nesting depth, argument spans exceeding byte/token limits, nested function calls
inside arguments unless a future authority revision explicitly authorizes them
(current authority: **argument spans are not recursively evaluated**).

**Canonical template evidence (authority record only, not an implementation
branch):** overlay template identity carries **two** `FUNCTION_CALL` compound
declarations among twelve properties.

### Production `MULTI_TOKEN_VALUE`

**Intent:** Whitespace-separated sequence of bounded tokens without a single
outer function call.

**Supported shape (bounded):**

- One to `MAX_COMPOUND_TOKEN_COUNT` tokens separated by ASCII whitespace.
- Each token is one of: keyword (finite allowed set aligned with existing
  `@keyword_values` where applicable), dimension/number literal matching
  existing literal acceptance, identifier, or a `var(--name)` span subject to
  local-reference extraction.

**Explicit rejects:** unbounded tokenization, `calc(`, expression operators
beyond the separate `VAR_REFERENCE_WITH_OPERATION` production, semicolons,
commas as token separators at top level (comma only inside function argument
spans owned by `FUNCTION_CALL`).

**Romeo evidence:** five of eight findings use this shape class across owners
(gap decomposition safe inspection).

### Production `VAR_REFERENCE_WITH_OPERATION`

**Intent:** Two or more `var(--name)` occurrences and/or a bounded arithmetic
or juxtaposition pattern between spans that the direct-reference regex does not
cover as a whole.

**Supported shape (bounded):**

- At least one `var(--name)` substring.
- Optional single operator token from a fixed set: `+`, `-`, `*`, `/` (ASCII
  only), with bounded whitespace.
- Operands are `var(--name)` or bounded numeric/dimension literals already
  permitted elsewhere.

**Explicit rejects:** chained operators, parentheses groups, `calc()`, nested
functions, more than `MAX_VAR_REFERENCE_WITH_OPERATION_OPERANDS` operands.

**Canonical template evidence:** state template identity — one transition
declaration, **two** embedded `var(` occurrences, classified
`VAR_REFERENCE_WITH_OPERATION`.

### Grammar classification rule

```text
GRAMMAR_CLASSIFIED
  = exactly one primary production per declaration value
  | FAIL_CLOSED_RESIDUAL (ambiguous or multi-production)
```

Classification uses the value after property-level trim. Direct-only
`var(--name)` values remain on the **existing direct-reference path**, not this
grammar.

## Local reference extraction and resolver integration

### Extraction

After `PARSED_SUPPORTED`, scan the bounded parse tree for `var(--name)` spans
that match `CSSDeclaration.safe_property?/1` local names (`--` prefix).

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
| `{:ok, terminal}` | Substitute into reconstruction input |
| `:no_local_definition` | `FAIL_CLOSED_RESIDUAL` |
| `:unsupported_nested_reference` | `FAIL_CLOSED_RESIDUAL` |
| Other closed errors | `FAIL_CLOSED_RESIDUAL` |
| `:resource_limit_exceeded` | `FAIL_CLOSED_RESIDUAL` (batch) |

**FRAME C and FRAME D must not become executable** because compound parsing
succeeds. In particular:

```text
compound grammar supported
+ embedded definition resolves to UNSUPPORTED_NESTED_REFERENCE
= FAIL_CLOSED_RESIDUAL (whole rule if atomicity applies)
```

### Reconstruction

After all embedded references for a declaration resolve `{:ok, terminal}`:

1. Substitute terminals into the bounded parse representation.
2. Emit **one** bounded UTF-8 string (`TERMINAL_RECONSTRUCTED`).
3. Pass that string through existing `CSSDeclaration` checks and
   `normalize_declaration_value/3` **only as a consumer of a fully reconstructed
   literal** — not as a second resolver.

Reconstruction must not introduce new `var(` spans. If substitution would exceed
`MAX_RECONSTRUCTED_TERMINAL_BYTES`, fail closed.

## Finding dependency matrix (eight confirmed required)

There are **eight** owner findings: four card owners × two template identities
(overlay layout rule + state opacity/transition rule). Safe inspection on joined
Romeo export templates (no selectors, values, or names published):

| Template identity (declaration-key signature) | Findings per owner | Primary compound shapes | Embedded `var(` declarations | Embedded occurrence total |
| --- | ---: | --- | ---: | ---: |
| `a885b67246be9e14a0308dc3f1c4f32848026ff3c94509c2730aa5d82a3509bf` (overlay) | 4 | `FUNCTION_CALL` ×2, `VAR_REFERENCE_WITH_OPERATION` ×1 per template | 3 | 4 |
| `3e15d9729224a0b73fc1df3485917774b748bb3641204800957595c455f90eaa` (state) | 4 | `VAR_REFERENCE_WITH_OPERATION` ×1 (transition) | 1 | 2 |

```text
COMPOUND_FINDING_COUNT=8
COMPOUND_TEMPLATE_IDENTITY_COUNT=2
OWNER_EXPANSION_COUNT=4
```

### Per-finding dependency columns (authority closure)

Each of the eight findings must be evaluated at implementation verification
time with this matrix. **Do not assume all eight become non-residual.**

| Finding class | Grammar required | Embedded local refs | Preliminary resolver dependency | Expected post-compound disposition |
| --- | --- | --- | --- | --- |
| Overlay ×4 | `FUNCTION_CALL` + `MULTI_TOKEN_VALUE` + possible `VAR_REFERENCE_WITH_OPERATION` on subset of properties | Yes (3 decls / 4 occurrences per template) | Each occurrence must resolve under **accepted** direct-target / proven-ancestor contract; nested definition terminals remain fail-closed | **PARTIAL** — grammar may parse while some occurrences still `UNSUPPORTED_NESTED_REFERENCE` or `NO_LOCAL_DEFINITION` |
| State ×4 | `VAR_REFERENCE_WITH_OPERATION` on transition | Yes (2 occurrences per template) | Same; two occurrences must both succeed for transition declaration to reconstruct | **PARTIAL** — same fail-closed coupling |

```text
COMPOUND_SUCCESS_CRITERION_8_TO_0=REJECTED
EXPECTED_CANONICAL_DELTA=DERIVE_FROM_MATRIX_AT_IMPLEMENTATION_VERIFY
PRELIMINARY_EXPECTATION=SOME_FINDINGS_REMAIN_RESIDUAL_IF_RESOLVER_FAIL_CLOSED
```

Implementation verification must publish observed counts, not a predetermined
zero residual target.

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
| `MAX_FUNCTION_ARGUMENT_BYTES` | 2048 | opaque argument span |
| `MAX_COMPOUND_PARSE_DEPTH` | 1 | no nested top-level productions |

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
  implementation logic (canonical evidence hashes in this authority record are
  not implementation selectors);
- emit custom-property definitions into Design IR;
- change Design IR version or `StyleValue` schema for compound success paths
  (success still produces ordinary literals/keywords/token refs via existing
  normalization).

## Design IR impact

```text
COMPOUND_PARSE_IR_EMISSION=NO
COMPOUND_AST_IN_DESIGN_IR=NO
DESIGN_IR_SCHEMA_CHANGED=NO
DESIGN_IR_VERSION_BUMP_REQUIRED=NO
STYLE_VALUE_SCHEMA_CHANGE_REQUIRED=NO
```

Success terminates in existing normalized style values.

## Open items for implementation plan (not this record)

The implementation plan must close executable test vectors for:

1. Exact token/operator allowlists per production.
2. Occurrence-index collision tests across multi-target selector rules.
3. Resolver batch cardinality when compound references share a declaration.
4. Canonical Romeo rerun expectations derived from the matrix row outcomes.
5. TDD ordering: `CompoundCssValue` pure tests first, then normalizer integration.

```text
NEXT_GATE=CSS_COMPOUND_VALUE_ARCHITECTURE_AUTHORITY_REVIEW
THEN=CSS_COMPOUND_VALUE_IMPLEMENTATION_PLAN
IMPLEMENTATION_AUTHORIZED=NO
```
