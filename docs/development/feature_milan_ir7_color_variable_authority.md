# Feature Milan IR7 R3 color variable authority candidate

Status: evidence candidate for independent review. This record does not
authorize production implementation or close the remaining style blockers.

```text
TASK=FEATURE_MILAN_IR7_R3_EXACT_COLOR_VARIABLE_EVIDENCE
R3_LIFECYCLE=AWAITING_INDEPENDENT_REVIEW
R3_EVIDENCE_CORPUS_COMPLETE=YES

CURRENT_MAIN_SHA=5c4c307ef38c264dd0da41d23a907688df2f619e
CURRENT_MAIN_TREE=e3c53f87d62a4c5b5cf34faf2112fe1658a73309
CURRENT_MAIN_SIGNATURE=VALID
CURRENT_MAIN_CI_RUN=41648772191
CURRENT_MAIN_CI_EVENT=push
CURRENT_MAIN_CI_RESULT=SUCCESS
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

The review inspected the accepted corpus without modifying it. It includes
the R2 authority and reconstruction record, the ACSS token adapter document,
the two accepted ACSS 4.0.1 evidence records, the Milan source and ACSS
settings under `private_reference/`, `fixtures/automatic_css/`, and the
owner-controlled Automatic.css 4.0.1 installation and generated outputs
identified below. No web source, tests, or current implementation behavior
supplied ownership proof.

The exact source/version identity is:

Paths under `assets/` in the source-artifact tables are relative to the
Automatic.css plugin root `wp-content/plugins/automatic-css/`.

| ID | Artifact | Evidence location | SHA-256 |
| --- | --- | --- | --- |
| S1 | Automatic.css plugin version metadata, version 4.0.1 | Local Site danbricks `wp-content/plugins/automatic-css/automatic-css.php:12` | `fbb07573733b46f941c49d69153d9c4797bb0bf686da4fbc2d6f8f32cdd14276` |
| S2 | Contextual variable output template | `assets/scss/modules/contextual-colors/_contextual-tokens.scss:6-12` | `6ef43c18e6ac854a3b96174a2786affe8da314ab33c026bfedcb4ff6b283c1ac` |
| S3 | Contextual color source categories | `assets/scss/modules/contextual-colors/_contextual-maps.scss:1-14` | `312565b672a29142e226bb8c89c13a3c1a1bc7480ddedab9d7ded5142e8970c5` |
| S4 | Contextual variable defaults | `assets/scss/modules/contextual-colors/_contextual-vars.scss:13-18` | `a851bf7c50e0bfe4b2f5700d6ca5379fef2faf6663db0848974ffb9574712d09` |
| S5 | Accepted project settings export | `private_reference/frames/staging-2026-09/environment/acss-settings.json` | `3347240b2837dc28854020b0fa0f1d2100086d259123f8b964ac8f31114cad32` |
| S6 | Checked-in ACSS settings fixture | `fixtures/automatic_css/acss_settings.json` | `19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05` |
| S7 | Generated variables stylesheet, header version 4.0.1 | `wp-content/uploads/automatic-css/automatic-variables.css:363-374` | `34127351b41a2496c5be9a9f238aba2fcffd63dc8a790eefc8f03d6b3becd093` |
| S11 | ACSS background class cheatsheet | `assets/scss/modules/background-classes/_cheatsheet.json:437` | `02a58c26da8e771ac91208fd5c903c699894e7478cc313e13849f2fc5934f1dd` |

The accepted ACSS 4.0.1 grid authority record also identifies the generated
variables stylesheet. The review checked three other generated outputs. Each
contains the same declarations:

| ID | Generated output | SHA-256 |
| --- | --- | --- |
| S8 | `automatic.css` | `77823f526e62ae945c5e295ced9179aa75cfd6fb6dc797cfec1acbc50299b4b5` |
| S9 | `automatic-core-for-block-editor.css` | `2c29b31bbaba284a29e35c9a8e37284dc4e3232e187532b8063f2ae47424f533` |
| S10 | `automatic-core-for-iframe-editor.css` | `49d18b654600a861e6048fcfae14ed0c2a340a02a563ee953c81c737359e5ff1` |

The ACSS settings export is 95,919 bytes. This record publishes its identity
and the presence or absence of the three exact setting keys, not its contents.
The private plugin source and generated stylesheets were inspected locally;
this record contains no source excerpts or stylesheet contents.

The accepted ACSS token adapter document lists
`color.background.ultra_light` in its canonical token set, and the R2
authority records that the exact source setting key `bg-ultra-light` maps to
that semantic concept. The canonical list does not contain an exact muted
dark text path. The accepted D0E1 and D0E2 records corroborate the version
metadata and generated stylesheet identity, but their approved publication
scope does not establish either color mapping.

The R2 reconstruction record is the source for each current Milan occurrence
and its unresolved state. No DesignDocument was changed or regenerated for
this R3 evidence gate.

## `--bg-ultra-light`

```text
VARIABLE=--bg-ultra-light
R2_STATE=unresolved source_variable
R2_OCCURRENCE=node_000001 property=background
R2_EVIDENCE=docs/development/feature_milan_ir7_design_document_reconstruction_record.md:203
PROJECT_SEMANTIC_EVIDENCE=docs/development/feature_milan_ir7_style_remediation_authority.md:233-255; docs/06_ACSS_TOKEN_ADAPTER.md:271
SOURCE_VERSION=Automatic.css 4.0.1
EVIDENCE_ARTIFACTS=S1,S2,S3,S5,S6,S7,S8,S9,S10
OWNERSHIP_PROVEN=YES
SETTING_KEY_PRESENT=YES
ACSS_4_0_1_OUTPUT_DECLARATION=YES
EXACT_TOKEN_PATH=color.background.ultra_light
AUTHORITY_KIND=source_output_alias
DISPOSITION=EXACT_OWNER_AUTHORITY_CANDIDATE
IMPLEMENTATION_REQUIRED=YES
```

The accepted R2 authority identifies `bg-ultra-light` as the source setting
key for the semantic concept `color.background.ultra_light`, while correctly
leaving direct-variable ownership unproven at that time. The project settings
export contains that exact setting key. In the ACSS 4.0.1 source, the
contextual map places the background token in the `background-colors` output
group, and the contextual token template emits a CSS variable for each item in
that group. The generated 4.0.1 variables stylesheet contains the resulting
declaration in its global `:root` block at line 366. The same declaration is
present at line 366 in each of the three other generated outputs listed
above.

The existing exact source-key-to-semantic-concept record and the
version-matched source output contract establish the owner path
`color.background.ultra_light`. The review did not use the declaration's value
to derive the path. The settings value that consumes the neutral variable is
`source_reference` evidence only; it does not compete with the output alias.

The corpus also contains a scoped custom CSS override in
`private_reference/frames/staging-2026-09/slider-section-basel/bricks-component-kpajhw-slider-section-basel.json:341`
(`SHA-256=6c1f7b20be95e3110db84ba4adc847da5da3d225ebfd12fb7b2713170a2e271f`).
It redefines the same CSS custom property inside one component selector. It
does not provide a token path or a competing ACSS output alias, so it is not
owner evidence and does not displace the global source owner established
above.

This candidate records only the ACSS `source_output_alias` relationship for
the existing semantic path. It does not authorize implementation. Since R2
leaves the Milan occurrence unresolved, realizing this candidate would
require a separately authorized production change after review.

## `--black-trans-10`

```text
VARIABLE=--black-trans-10
R2_STATE=unresolved source_variable
R2_OCCURRENCE=node_000001_000001_000001_000002_000001 property=border-color
R2_EVIDENCE=docs/development/feature_milan_ir7_design_document_reconstruction_record.md:204
PROJECT_SEMANTIC_EVIDENCE=docs/development/feature_milan_ir7_style_remediation_authority.md:265-277
SOURCE_VERSION=Automatic.css 4.0.1
EVIDENCE_ARTIFACTS=S1,S2,S3,S5,S7,S8,S9,S10,S11
OWNERSHIP_PROVEN=NO
SETTING_KEY_PRESENT=NO
ACSS_4_0_1_OUTPUT_DECLARATION=NO
EXACT_TOKEN_PATH=NONE
AUTHORITY_KIND=NONE_AUTHORIZED
DISPOSITION=UNRESOLVED_INSUFFICIENT_EXACT_EVIDENCE
IMPLEMENTATION_REQUIRED=NO
```

The accepted settings export has no exact key for this variable, and none of
the four version-matched generated stylesheets declares it. The ACSS source
cheatsheet contains the class label `bg--black-trans-10`, but a class label
does not establish a direct-variable output alias, token path, value,
transparency, or owner. No exact source/version evidence supplies those
missing facts. No owner is inferred from the spelling or the Milan consumer.

## `--text-dark-muted`

```text
VARIABLE=--text-dark-muted
R2_STATE=unresolved source_variable
R2_OCCURRENCE=node_000001_000001_000001_000002_000001_000002_000001 property=color
R2_EVIDENCE=docs/development/feature_milan_ir7_design_document_reconstruction_record.md:206
PROJECT_SEMANTIC_EVIDENCE=docs/06_ACSS_TOKEN_ADAPTER.md:271-276; docs/development/feature_milan_ir7_style_remediation_authority.md:279-287
SOURCE_VERSION=Automatic.css 4.0.1
EVIDENCE_ARTIFACTS=S1,S2,S3,S5,S6,S7,S8,S9,S10
SOURCE_VARIABLE_EMISSION_PROVEN=YES
TOKEN_PATH_OWNERSHIP_PROVEN=NO
SETTING_KEY_PRESENT=YES
ACSS_4_0_1_OUTPUT_DECLARATION=YES
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
semantic token path. The accepted canonical token inventory lists
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
