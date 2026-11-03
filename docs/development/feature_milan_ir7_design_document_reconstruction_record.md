# Feature Milan IR7 R2 DesignDocument reconstruction record

```text
TASK=FEATURE_MILAN_IR7_R2_MILAN_STRUCTURAL_AUTHORITY_RECONSTRUCTION
R2_EVIDENCE_CLASS=INTERMEDIATE_RECONSTRUCTION
R2_INTERMEDIATE_RECONSTRUCTION_EVIDENCE=YES
NOT_FINAL_IR7_DESIGN_DOCUMENT_IDENTITY=YES
NOT_BEHAVIOR_AUTHORITY=YES
NOT_COMPONENT_APPROVAL=YES
NOT_NATIVE_GENERATION_AUTHORITY=YES

BASE_SHA=eabd7b5f901e33050b42b26d5eca3e04ca87e692
BASE_TREE=ea688f34b907cf1ac4d466178d4eef571213b340
BASE_POST_MERGE_CI_RUN=41174851898
BASE_POST_MERGE_CI_RESULT=SUCCESS

PRIVATE_SOURCE=private_reference/frames/staging-2026-09/feature-section-milan/bricks-component-ybsqrl-feature-section-milan.json
PRIVATE_SOURCE_SHA256=f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132
PRIVATE_SOURCE_BYTES=17017
ACSS_SOURCE=fixtures/automatic_css/acss_settings.json
ACSS_SHA256=19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05
ACSS_SOURCE_VERSION=4.0.1
BREAKPOINT_AUTHORITY=sources/work/feature_milan/fidelity/breakpoint_authority.json
BREAKPOINT_AUTHORITY_SHA256=e507d7d6ff33bbb4fb0880d46c44f3b5337d6c95c227154e11510e6a7a2c1b34
COMPONENT_ID=ybsqrl

CONTROL_PROCEDURE=HISTORICAL_DECODED_MAP_INPUT
CONTROL_INPUT_BOUNDARY=decoded Bricks map + decoded ACSS map
CONTROL_SHA256=bddf757881a116070e1973cad280115f5e6c30cb6a70beeb70f166bf61420a64
CONTROL_CANONICAL_BYTES=411416
CONTROL_NODE_COUNT=17

NONCANONICAL_FILENAME_PROCEDURE_SHA256=68024f1b71a2e69e1e938678796ddc105c639666d088ae47a6b11bab05fae06b
NONCANONICAL_FILENAME_PROCEDURE_USED_FOR_R2=NO

STRUCTURAL_AUTHORITY_RECORD_COUNT=3
R2_SHA256=b607eff3f51ca12ec3db6ae5aa29ca43588e1e7716061850d27e5ac35058f8a5
R2_CANONICAL_BYTES=411535
R2_NODE_COUNT=17
R2_DETERMINISTIC=YES
IR_VERSION=6.0.0

GRID_OCCURRENCE_COUNT=3
GRID_OCCURRENCES_RESOLVED=3
GRID_STYLEVALUE_CHANGE_COUNT=3
GRID_VALUE_SOURCE_VARIABLE_LEAK=NO

NON_GRID_STYLEVALUE_CHANGE_COUNT=0
NON_GRID_DEPENDENCY_TOP_LEVEL_SEMANTIC_CHANGE_COUNT=0
NON_GRID_CONTEXT_DIFF_PATH_COUNT=45
NON_GRID_EXPRESSION_CHANGE_COUNT=0
DEPENDENCY_EXPRESSIONS_NULL_COUNT=0

DEPENDENCY_VARIABLE_COUNT_CONTROL=11
DEPENDENCY_VARIABLE_COUNT_R2=11
DEPENDENCY_VARIABLE_NAME_SET_EQUAL=YES
DEPENDENCY_VARIABLE_DUPLICATES=NONE
DEPENDENCY_VARIABLE_RECORDS_ALIGNED_BY_NAME=YES
UNEXPLAINED_VARIABLE_RECORD_CONTENT_CHANGE_COUNT=0

DELTA_CLASS_A_COUNT=27
DELTA_CLASS_B_COUNT=101
DELTA_CLASS_C1_COUNT=45
DELTA_CLASS_C2_COUNT=1
DELTA_CLASS_D_COUNT=0
CLASS_A=AUTHORIZED_GRID_STYLEVALUE_SEMANTIC_DELTA
CLASS_B=AUTHORIZED_GRID_DEPENDENCY_STRUCTURAL_RESOLUTION_DELTA
CLASS_C1=AUTHORIZED_NON_GRID_OCCURRENCE_CONTEXT_ENRICHMENT
CLASS_C2=AUTHORIZED_DEPENDENCY_VARIABLE_COLLECTION_ORDER_ONLY
CLASS_D=UNEXPECTED
CLASS_C2_PATH=$.provenance.dependency_summary.variables#order
CLASS_C2_SEMANTIC_EFFECT=NONE
CLASS_C2_RECORD_MEMBERSHIP_EFFECT=NONE
CLASS_C2_RECORD_CONTENT_EFFECT=NONE

R2A_FIX_PRESENT=YES
R2A_EXPRESSION_RETENTION_VERIFIED=YES
GRID_TOKENSET_CHANGE=NO
GRID_PUBLIC_LF_API_CHANGE=NO
DESIGN_IR_SCHEMA_CHANGE_REQUIRED=NO

R3_WORK_PERFORMED=NO
R4_WORK_PERFORMED=NO
R5_DESIGN_DOCUMENT_ISSUED=NO
IR7_FINAL_DESIGN_DOCUMENT_IDENTITY_FROZEN=NO
BEHAVIOR_WORK_PERFORMED=NO
COMPONENT_WORK_PERFORMED=NO
NATIVE_GENERATOR_WORK_PERFORMED=NO
LEAD3_WORK_STARTED=NO
ARTICLE_JULIET_P4B_STARTED=NO
```

This record describes the R2 intermediate reconstruction only. It does not issue a final IR7 DesignDocument identity or grant authority for Behavior, Component approval, or native generation.

## Reconstruction procedure

The canonical Control and R2 used the accepted historical map-input procedure. The Bricks source bytes were read and decoded with `Jason.decode!`; `Bricks.to_ir/2` received that decoded map. The ACSS fixture bytes were also decoded with `Jason.decode!`; `AutomaticCSS.normalize/2` received that map with `source_version: "4.0.1"`, `source_version_status: "fixture_reference"`, `strict: true`, and `profile: :hero_foundation`. The procedure then loaded the breakpoint authority, resolved the DesignDocument, validated the IR, and encoded it with `lf-ir-serializer-v1` before computing SHA-256.

The private source is identified by path, byte count, and SHA-256 above. Its bytes are not included in this record.

## Input-boundary matrix

All cases used the same source bytes and options. Only the Bricks and ACSS input forms changed.

| Case | Bricks input | ACSS input | Canonical SHA-256 | Canonical bytes | Nodes |
| --- | --- | --- | --- | ---: | ---: |
| A, canonical Control | decoded map | decoded map via `AutomaticCSS.normalize/2` | `bddf757881a116070e1973cad280115f5e6c30cb6a70beeb70f166bf61420a64` | 411416 | 17 |
| B | file path | decoded map via `AutomaticCSS.normalize/2` | `68024f1b71a2e69e1e938678796ddc105c639666d088ae47a6b11bab05fae06b` | 411460 | 17 |
| C | decoded map | file path via `AutomaticCSS.from_file/2` | `bddf757881a116070e1973cad280115f5e6c30cb6a70beeb70f166bf61420a64` | 411416 | 17 |
| D, filename procedure | file path | file path via `AutomaticCSS.from_file/2` | `68024f1b71a2e69e1e938678796ddc105c639666d088ae47a6b11bab05fae06b` | 411460 | 17 |

Case A matched the historical Control in two fresh BEAM processes on the accepted base and in one fresh process on the preserved old base. The two accepted-base runs matched each other. Case D reproduced the previously observed filename-procedure identity.

```text
HISTORICAL_MAP_CONTROL_REPRODUCED=YES
OLD_NEW_HISTORICAL_MAP_CONTROL_IDENTICAL=YES
HISTORICAL_MAP_CONTROL_DETERMINISTIC=YES
INPUT_BOUNDARY_DELTA_OWNER=BRICKS_FILE_LOADING
INPUT_BOUNDARY_STYLEVALUE_CHANGE_COUNT=0
INPUT_BOUNDARY_SEMANTIC_CHANGE_COUNT=0
```

The complete Case A to Case D recursive diff contained these three provenance-only paths:

| JSON path | Case A | Case D | Classification |
| --- | --- | --- | --- |
| `$.provenance.source_hash` | `7fb1f70e2a23c5348c426a4b0c6967a9ebe44402b8d150c8ba5735f23f31b2df` | `f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132` | `INPUT_BOUNDARY_PROVENANCE` |
| `$.source_metadata.source_hash` | `7fb1f70e2a23c5348c426a4b0c6967a9ebe44402b8d150c8ba5735f23f31b2df` | `f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132` | `INPUT_BOUNDARY_PROVENANCE` |
| `$.source_metadata.source_label` | `inline` | `bricks-component-ybsqrl-feature-section-milan.json` | `INPUT_BOUNDARY_PROVENANCE` |

Cases B and C isolate the cause. Changing Bricks from a decoded map to a file path produces the three provenance changes. Changing ACSS from a decoded map to `AutomaticCSS.from_file/2` produces no canonical change. No adapter was changed. R2 uses Case A's historical map/map boundary.

## Structural authority and grid result

R2 built its index with `StructuralVariables.authority("4.0.1", grid_variables_enabled: true)`. The returned index contained these three records. No grid TokenSet paths were added.

| Variable | Resolved value | Authority ID |
| --- | --- | --- |
| `--grid-1` | `repeat(1, minmax(0, 1fr))` | `automatic-css-4.0.1:structural-grid:grid-1` |
| `--grid-2` | `repeat(2, minmax(0, 1fr))` | `automatic-css-4.0.1:structural-grid:grid-2` |
| `--grid-3-2` | `minmax(0, 3fr) minmax(0, 2fr)` | `automatic-css-4.0.1:structural-grid:grid-3-2` |

The only three StyleValue changes were the accepted grid declarations:

| Node | Property | Breakpoint | Control StyleValue | R2 StyleValue | Authority |
| --- | --- | --- | --- | --- | --- |
| `node_000001_000001` | `grid-template-columns` | base | unresolved, source `var(--grid-2)` | literal `repeat(2, minmax(0, 1fr))` | `automatic-css-4.0.1:structural-grid:grid-2` |
| `node_000001_000001` | `grid-template-rows` | base | unresolved, source `var(--grid-1)` | literal `repeat(1, minmax(0, 1fr))` | `automatic-css-4.0.1:structural-grid:grid-1` |
| `node_000001_000001` | `grid-template-columns` | `mobile_landscape` | unresolved, source `var(--grid-1)` | literal `repeat(1, minmax(0, 1fr))` | `automatic-css-4.0.1:structural-grid:grid-1` |

The R2 values contain no `var(--grid-1)`, `var(--grid-2)`, or `var(--grid-3-2)` source-variable leak. Structural metadata identifies the matching authority record. The grid dependency records report `status=resolved_structural`, `structural_authority_state=unique_candidate`, the accepted authority ID, and the corresponding resolved recipe. Their source expressions remain present.

## Dependency variable identity and collection order

The recursive comparison aligned the two dependency-variable collections by each record's exact `name`. Both collections have 11 records and 11 unique names. Their name sets are equal:

```text
--animation-duration
--bg-ultra-light
--black-trans-10
--container-gap
--content-gap
--grid-1
--grid-2
--primary
--space-m
--space-s
--text-dark-muted
```

There are no missing or added names and no duplicate names. All 11 records align by name. Their membership is unchanged, and no record content changed because of the array order. After allowing only the grid structural-resolution fields and the approved occurrence-context fields, there are zero unexplained record-content changes.

`provenance.dependency_summary.variables` has a different deterministic array order in the structural extraction result. Semantic analysis in this evidence compares these records by variable name. This conclusion applies only to this exact collection and this R2 evidence. No positional meaning is assigned to this collection here. This record does not set a repository-wide rule for other arrays.

The sole order-only path is:

```text
CLASS_C2_PATH=$.provenance.dependency_summary.variables#order
CLASS_C2_SEMANTIC_EFFECT=NONE
CLASS_C2_RECORD_MEMBERSHIP_EFFECT=NONE
CLASS_C2_RECORD_CONTENT_EFFECT=NONE
```

The complete machine-derived Control to R2 inventory contained 174 changed paths. It classified every path as follows:

| Class | Meaning | Paths |
| --- | --- | ---: |
| A | Authorized grid StyleValue semantic delta | 27 |
| B | Authorized grid dependency structural-resolution delta | 101 |
| C1 | Authorized non-grid occurrence-context enrichment | 45 |
| C2 | Authorized dependency-variable collection order only | 1 |
| D | Unexpected | 0 |

No other order-only path appeared.

## Non-grid occurrence context

The 45 C1 paths add `property`, `breakpoint`, and `resolution_status` to the 15 existing non-grid occurrences. Control omitted these keys. R2 records the following values; `null` is the explicit R2 value.

| Variable | Occurrence source path | Property | Breakpoint | Resolution status |
| --- | --- | --- | --- | --- |
| `--animation-duration` | `ebbb6e`, `settings.class_refs[0].settings._cssCustom` | `null` | `null` | `mapping_unproven_occurrence` |
| `--bg-ultra-light` | `ybsqrl`, `settings.class_refs[0].settings._background.color.raw` | `background` | `null` | `source_variable` |
| `--black-trans-10` | `ebbb6e`, `settings.class_refs[0].settings._border.color.raw` | `border-color` | `null` | `source_variable` |
| `--primary` | `ebbb6e`, `settings.class_refs[0].settings._cssCustom` | `null` | `null` | `ambiguous_token` |
| `--text-dark-muted` | `b41076`, `settings.class_refs[0].settings._typography.color.raw` | `color` | `null` | `source_variable` |
| `--container-gap` | `0325c3`, `settings.class_refs[0].settings._gridGap` | `gap` | `null` | `resolved_token` |
| `--container-gap` | `61d9dd`, `settings.class_refs[0].settings._rowGap` | `row-gap` | `null` | `resolved_token` |
| `--content-gap` | `c9cb4b`, `settings.class_refs[0].settings._rowGap` | `row-gap` | `null` | `resolved_token` |
| `--content-gap` | `6c0b5f`, `settings.class_refs[0].settings._rowGap` | `row-gap` | `null` | `resolved_token` |
| `--space-m` | `ebbb6e`, `settings.class_refs[0].settings._padding.left` | `padding-left` | `null` | `ambiguous_token` |
| `--space-m` | `ebbb6e`, `settings.class_refs[0].settings._padding.right` | `padding-right` | `null` | `ambiguous_token` |
| `--space-s` | `61d9dd`, `settings.class_refs[0].settings._padding.bottom` | `padding-bottom` | `null` | `resolved_token` |
| `--space-s` | `61d9dd`, `settings.class_refs[0].settings._padding.top` | `padding-top` | `null` | `resolved_token` |
| `--space-s` | `ebbb6e`, `settings.class_refs[0].settings._rowGap` | `row-gap` | `null` | `resolved_token` |
| `--space-s` | `966841`, `settings.class_refs[0].settings._rowGap` | `row-gap` | `null` | `resolved_token` |

This is 15 occurrences times three context fields, or 45 paths. The context enriches dependency provenance; it does not change breakpoint authority or responsive StyleValues.

## Expression and StyleValue preservation

All nine non-grid dependency expressions below match Control exactly. The two custom-CSS expressions retain their complete original text and ordering; the private CSS text is not copied into this record.

| Variable | Expression comparison |
| --- | --- |
| `--animation-duration` | unchanged, custom-CSS containing expression |
| `--bg-ultra-light` | unchanged, `var(--bg-ultra-light)` |
| `--black-trans-10` | unchanged, `var(--black-trans-10)` |
| `--primary` | unchanged, custom-CSS containing expression |
| `--text-dark-muted` | unchanged, `var(--text-dark-muted)` |
| `--container-gap` | unchanged, `var(--container-gap)` |
| `--content-gap` | unchanged, `var(--content-gap)` |
| `--space-m` | unchanged, `var(--space-m)` |
| `--space-s` | unchanged, `var(--space-s)` |

The complete serialized non-grid StyleValue comparison covered all 14 declarations involving these variables. It compared `kind`, `value`, `source_expression`, `source_trace`, `metadata`, node, property, and responsive placement. Every non-grid StyleValue is byte-identical between Control and R2. No top-level non-grid dependency semantic field changed.

```text
NON_GRID_STYLEVALUE_CHANGE_COUNT=0
NON_GRID_DEPENDENCY_TOP_LEVEL_SEMANTIC_CHANGE_COUNT=0
NON_GRID_CONTEXT_DIFF_PATH_COUNT=45
NON_GRID_EXPRESSION_CHANGE_COUNT=0
DEPENDENCY_EXPRESSIONS_NULL_COUNT=0
```

The `--space-m` StyleValue remains `kind=token_ref`, `value=spacing.scale.medium`. Its generic dependency-summary record remains `status=ambiguous_token`, `authority_state=ambiguous_candidates`, and `resolution_reason=mapping_ambiguous`. These APIs retain their distinct authority results.

## Open R3 and R4 blockers

| Variable | R2 StyleValue or status | Pending work |
| --- | --- | --- |
| `--bg-ultra-light` | unresolved | R3 color authority |
| `--black-trans-10` | unresolved | R3 color authority |
| `--text-dark-muted` | unresolved | R3 color authority |
| `--space-s` | `kind=token_ref`, `value=spacing.scale.s` | Native package mapping remains pending R4 |

No R3 or R4 work was performed. No token map or generated asset changed.

## Verification and repository scope

The two fresh BEAM R2 reconstructions produced the same IR version, node count, canonical byte length, and SHA-256. Both produced 17 nodes and the R2 identity recorded above.

The focused structural regression set passed 157 tests. It covers the required fail-closed behavior:

| Check | Existing regression case |
| --- | --- |
| Missing structural authority remains unresolved | `without structural authority --grid-1 remains a source variable dependency` |
| Ambiguous structural authority fails closed | `ambiguous structural authority for --grid-2 fails closed in extract` |
| Invalid property pairing produces no structural literal | `valid structural value on width remains non-structural in extract` |
| Unsupported source version fails authority construction | `unsupported versions return an error` |
| Unsafe structural value does not resolve | `unsafe structural candidate does not resolve structurally in extract` |

The full test suite passed 2,646 tests. Formatting, warnings-as-errors compilation, asset build, unused-dependency check, and whitespace check also passed.

```text
FOCUSED_TESTS=PASS (157 tests)
FORMAT=PASS
COMPILE=PASS
FULL_TEST_SUITE=PASS (2646 tests)
ASSETS_BUILD=PASS
UNUSED_DEPS=PASS
GIT_DIFF_CHECK=PASS
```

The only authorized repository change for this task is this reconstruction record. Production code, tests, token maps, generated assets, the Design IR schema, and the public LiveFrames API were not changed.

```text
R3_WORK_PERFORMED=NO
R4_WORK_PERFORMED=NO
R5_DESIGN_DOCUMENT_ISSUED=NO
IR7_FINAL_DESIGN_DOCUMENT_IDENTITY_FROZEN=NO
BEHAVIOR_WORK_PERFORMED=NO
COMPONENT_WORK_PERFORMED=NO
NATIVE_GENERATOR_WORK_PERFORMED=NO
LEAD3_WORK_STARTED=NO
ARTICLE_JULIET_P4B_STARTED=NO
```
