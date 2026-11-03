# Feature Milan IR7 R3 color variable authority candidate

Status: evidence candidate for independent review. This record does not
authorize production implementation or close the remaining style blockers.

Scoped publication status and approved source/version identities are recorded in the [canonical provenance decision](../04_SOURCE_AND_PROVENANCE.md#feature-milan-r3-scoped-color-variable-publication-decision). This candidate does not broaden that scope.

```text
TASK=FEATURE_MILAN_IR7_R3_EXACT_COLOR_VARIABLE_EVIDENCE
R3_LIFECYCLE=AWAITING_INDEPENDENT_REVIEW
R3_BOUNDED_APPROVED_EVIDENCE_SET_INSPECTED=YES
R3_EVIDENCE_SCOPE=S1,S2,S3,S5,S7,S8,S9,S10
MATCHING_STAGING_ENVIRONMENT_EVIDENCE_COMPLETE=NO

R3_EVIDENCE_BASE_SHA=5c4c307ef38c264dd0da41d23a907688df2f619e
R3_EVIDENCE_BASE_TREE=e3c53f87d62a4c5b5cf34faf2112fe1658a73309
R3_EVIDENCE_BASE_SIGNATURE=VALID
R3_EVIDENCE_BASE_CI_RUN=41648772191
R3_EVIDENCE_BASE_CI_EVENT=push
R3_EVIDENCE_BASE_CI_RESULT=SUCCESS
SOURCE_VERSION_IDENTITY_PROVEN=YES
SOURCE_ENVIRONMENT=Local Site danbricks
SOURCE_VERSION=Automatic.css 4.0.1

R1_ACCEPTED=YES
R2_ACCEPTED=YES
R2_CONTROL_SHA256=bddf757881a116070e1973cad280115f5e6c30cb6a70beeb70f166bf61420a64
R2_SHA256=b607eff3f51ca12ec3db6ae5aa29ca43588e1e7716061850d27e5ac35058f8a5
R2_INTERMEDIATE_SHA256=b607eff3f51ca12ec3db6ae5aa29ca43588e1e7716061850d27e5ac35058f8a5
STRUCTURAL_GRID_BLOCKERS=0
UNRESOLVED_COLOR_VARIABLE_BLOCKERS=3
SPACING_SCALE_S_PACKAGE_MAPPING_BLOCKERS=4

R3_COLOR_VARIABLE_COUNT=3
R3_TERMINAL_DISPOSITION_COUNT=3
R3_PRODUCTION_CHANGE=NO
R3_TEST_CHANGE=NO
PRODUCTION_IMPLEMENTATION_AUTHORIZED=NO
R4_WORK_PERFORMED=NO
R5_WORK_PERFORMED=NO
R3_ACCEPTED=NO
```

## Evidence standard and corpus

The authority distinguishes three relationships:

| Relationship | Evidence meaning |
| --- | --- |
| `source_output_alias` | An exact source setting or calculated-variable contract emits a CSS variable for an owning token path. |
| `source_reference` | A source expression consumes a CSS variable. This does not establish ownership. |
| `explicit_project_contract` | A frozen LiveFrames contract names an exact variable-to-path owner. |

Only a `source_output_alias` or a separately justified
`explicit_project_contract` can establish direct ownership. Variable spelling,
token-path spelling, value equality, CSS property, consumer occurrence, and
candidate ordering were not used to select an owner.

The exact source/version identities and hashes approved for publication are
recorded in the [canonical provenance decision](../04_SOURCE_AND_PROVENANCE.md#feature-milan-r3-scoped-color-variable-publication-decision).
The artifact identifiers used below refer only to that approved set:
S1, S2, S3, S5, S7, S8, S9, and S10. This candidate publishes no source,
generated stylesheet, or configuration-export contents.

The matching staging global-variable registry and custom-code/style export
were unavailable, so completeness is claimed only for the identified bounded
evidence set.

The accepted ACSS token adapter inventory contains
`color.background.ultra_light`; the R2 authority records the source-key
mapping for `bg-ultra-light`. The inventory contains no exact LiveFrames
token path for `text-dark-muted`. No DesignDocument was changed or regenerated
for this R3 evidence gate.

## `--bg-ultra-light`

```text
VARIABLE=--bg-ultra-light
R2_STATE=unresolved source_variable
R2_OCCURRENCE=node_000001 property=background
R2_EVIDENCE=docs/development/feature_milan_ir7_design_document_reconstruction_record.md:203
PROJECT_SEMANTIC_EVIDENCE=docs/development/feature_milan_ir7_style_remediation_authority.md:233-255; docs/06_ACSS_TOKEN_ADAPTER.md:271
SOURCE_VERSION=Automatic.css 4.0.1
EVIDENCE_ARTIFACTS=S1,S2,S3,S5,S7,S8,S9,S10
OWNERSHIP_PROVEN=YES
SETTING_KEY_PRESENT=YES
ACSS_4_0_1_OUTPUT_DECLARATION=YES
SOURCE_OUTPUT_FEATURE_GUARD=option-contextual-color-variables=on
EXACT_TOKEN_PATH=color.background.ultra_light
AUTHORITY_KIND=source_output_alias
DISPOSITION=EXACT_OWNER_AUTHORITY_CANDIDATE
IMPLEMENTATION_REQUIRED=YES
```

The existing repository mapping associates source key `bg-ultra-light` with
`color.background.ultra_light`. The version-matched source map and template
establish that this setting emits the exact CSS variable, and the four
identified generated outputs agree. Together these facts prove the
`source_output_alias`; no declaration value or spelling similarity was used
to choose the token path. This exact output-alias candidate applies only while
the ACSS 4.0.1 contextual-variable emission feature is enabled. A disabled or
unproven feature state does not establish direct-output authority. This
candidate does not authorize implementation.
Since R2 leaves the Milan occurrence unresolved, realizing it would require
separate production-change authority after review.

## `--black-trans-10`

```text
VARIABLE=--black-trans-10
R2_STATE=unresolved source_variable
R2_OCCURRENCE=node_000001_000001_000001_000002_000001 property=border-color
R2_EVIDENCE=docs/development/feature_milan_ir7_design_document_reconstruction_record.md:204
PROJECT_SEMANTIC_EVIDENCE=docs/development/feature_milan_ir7_style_remediation_authority.md:265-277
SOURCE_VERSION=Automatic.css 4.0.1
EVIDENCE_ARTIFACTS=S1,S2,S3,S5,S7,S8,S9,S10
OWNERSHIP_PROVEN=NO
SETTING_KEY_PRESENT=NO
ACSS_4_0_1_OUTPUT_DECLARATION=NO
EXACT_TOKEN_PATH=NONE
AUTHORITY_KIND=NONE_AUTHORIZED
DISPOSITION=UNRESOLVED_INSUFFICIENT_EXACT_EVIDENCE
IMPLEMENTATION_REQUIRED=NO
```

The exact setting key is absent from the identified settings artifact, and
none of the four version-matched generated outputs declares this variable.
The approved evidence set establishes no direct owner or token path, so the
variable remains unresolved. No owner is inferred from spelling or from the
Milan consumer.

## `--text-dark-muted`

```text
VARIABLE=--text-dark-muted
R2_STATE=unresolved source_variable
R2_OCCURRENCE=node_000001_000001_000001_000002_000001_000002_000001 property=color
R2_EVIDENCE=docs/development/feature_milan_ir7_design_document_reconstruction_record.md:206
PROJECT_SEMANTIC_EVIDENCE=docs/06_ACSS_TOKEN_ADAPTER.md:271-276; docs/development/feature_milan_ir7_style_remediation_authority.md:279-287
SOURCE_VERSION=Automatic.css 4.0.1
EVIDENCE_ARTIFACTS=S1,S2,S3,S5,S7,S8,S9,S10
SOURCE_VARIABLE_EMISSION_PROVEN=YES
TOKEN_PATH_OWNERSHIP_PROVEN=NO
SETTING_KEY_PRESENT=YES
ACSS_4_0_1_OUTPUT_DECLARATION=YES
SOURCE_OUTPUT_FEATURE_GUARD=option-contextual-color-variables=on
EXACT_TOKEN_PATH=NONE
AUTHORITY_KIND=NONE_AUTHORIZED
DISPOSITION=UNRESOLVED_INSUFFICIENT_EXACT_EVIDENCE
IMPLEMENTATION_REQUIRED=NO
```

The exact project setting key is present. The ACSS 4.0.1 contextual map
places its source value in the `text-colors` group, the source template emits
that group as contextual CSS variables, and the generated variables
stylesheet contains the declaration in its global `:root` block at line 373.
The other three generated outputs contain the declaration at line 373. This
proves that ACSS emits the variable, but it does not establish a LiveFrames
semantic token path. This guard records the source-emission condition only;
it does not establish ownership. The accepted canonical token inventory lists
`color.text.dark` and `color.text.light`,
but no exact path for this source item, and no separate explicit project
contract supplies one. The source expression preserved in R2 is consumer
evidence only. Assigning a path from the variable or map key spelling would
be an unsupported inference, so the variable remains unresolved.

## Terminal state

```text
BG_ULTRA_LIGHT_DISPOSITION=EXACT_OWNER_AUTHORITY_CANDIDATE
BG_ULTRA_LIGHT_TOKEN_PATH=color.background.ultra_light
BG_ULTRA_LIGHT_AUTHORITY_KIND=source_output_alias

BLACK_TRANS_10_DISPOSITION=UNRESOLVED_INSUFFICIENT_EXACT_EVIDENCE
BLACK_TRANS_10_TOKEN_PATH=NONE
BLACK_TRANS_10_AUTHORITY_KIND=NONE_AUTHORIZED

TEXT_DARK_MUTED_DISPOSITION=UNRESOLVED_INSUFFICIENT_EXACT_EVIDENCE
TEXT_DARK_MUTED_TOKEN_PATH=NONE
TEXT_DARK_MUTED_AUTHORITY_KIND=NONE_AUTHORIZED

R3_IMPLEMENTATION_REQUIRED=YES_FOR_BG_ULTRA_LIGHT_CANDIDATE_ONLY
AUTOMATIC_CSS_NORMALIZER_CHANGED=NO
VARIABLE_AUTHORITY_CHANGED=NO
BRICKS_NORMALIZER_CHANGED=NO
TOKEN_MAP_CHANGED=NO
GENERATED_ASSETS_CHANGED=NO

PRODUCTION_CHANGED=NO
TESTS_CHANGED=NO
R4_WORK_PERFORMED=NO
R5_WORK_PERFORMED=NO
```

The candidate path is not an accepted owner mapping until independent review
accepts this record. The two unresolved variables remain unresolved, and the
overall final-generation style blockers are not cleared by this R3 result.
