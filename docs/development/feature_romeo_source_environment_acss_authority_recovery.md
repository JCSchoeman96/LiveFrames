# Feature Romeo source environment and Automatic.css authority recovery

## Decision

The bounded search found no accepted evidence that binds the exact Romeo
artifact to a source environment or an Automatic.css settings export. An
adjacent private settings file is a candidate artifact, but its filename and
directory location do not bind it to Romeo.

The Romeo artifact, canonical corpus, and accepted ACSS fixture hashes match
their recorded identities. The source environment and ACSS authority remain
unproven. This is the terminal result for this recovery gate.

SEARCH_BOUND_COMPLETE=YES
ROMEO_SOURCE_ENVIRONMENT_BINDING=UNPROVEN
ROMEO_ACSS_CONFIG_BINDING=UNPROVEN
ROMEO_ACSS_AUTHORITY_APPLICABILITY=UNPROVEN_AFTER_BOUNDED_SEARCH
ROMEO_ACSS_AUTHORITY_EVIDENCE=INSUFFICIENT
CANONICAL_ROMEO_NORMALIZATION_AUTHORIZED=NO
ROMEO_COMPONENTIZATION_AUTHORIZED=NO
ROMEO_IMPLEMENTATION_AUTHORIZED=NO
NEXT_GATE=OWNER_DECIDE_CONSERVATIVE_NO_ACSS_CONTEXT_OR_SUPPLY_NEW_SOURCE_EVIDENCE
STOP=ROMEO_SOURCE_ENVIRONMENT_BINDING_NOT_FOUND

## Accepted base and PR #228

The repository was clean on main before the search. After fetching origin,
both local main and origin/main matched the accepted base and tree. No
intervening commit required a material-authority conflict review.

| Record | Value |
| --- | --- |
| Repository | JCSchoeman96/LiveFrames |
| Accepted base SHA | 5870f4cc3580f53f4ec6d8f589807aec63bd2186 |
| Accepted base tree | 690651936019354f8d1a513ef500668e307dd45d |
| Accepted base CI | 39018792399 SUCCESS |
| PR #228 approved head | b936d2bb0411695561b2909234fe4884bedc6250 |
| PR #228 merge SHA | 5870f4cc3580f53f4ec6d8f589807aec63bd2186 |
| PR #228 merge tree | 690651936019354f8d1a513ef500668e307dd45d |
| PR #228 post-merge CI | 39018792399 SUCCESS |
| Fetched local main | 5870f4cc3580f53f4ec6d8f589807aec63bd2186 |
| Fetched origin/main | 5870f4cc3580f53f4ec6d8f589807aec63bd2186 |
| Main movement during preflight | NONE |

The current-main check was performed before the evidence search. This record
does not change the provenance register or any source authority.

## Authority reviewed

The following current repository authorities were read before searching:

- docs/04_SOURCE_AND_PROVENANCE.md
- docs/06_ACSS_TOKEN_ADAPTER.md
- docs/07_BRICKS_ADAPTER.md
- docs/development/feature_romeo_source_semantics_authority.md
- docs/development/feature_romeo_css_style_authority.md
- docs/development/feature_romeo_post_stateful_style_componentization_preflight.md
- docs/evidence/c09d6_d0e1_acss_4_0_1_grid_authority.md
- docs/development/c09d6d_cta_tango_style_coverage_preflight.md
- docs/development/c09d7a_cta_tango_componentization_preflight.md
- docs/development/feature_milan_ir4_normalization_record.md
- docs/development/feature_milan_ir4_post_pr213_normalization_record.md
- docs/development/feature_milan_ir4_post_pr213_breakpoint_evidence_recovery.md

The adapter authority supplies a 4.0.1 reference version for the accepted
fixture. It does not claim that an arbitrary export used that fixture.
Structural grid authority requires explicit enabled evidence:
grid_variables_enabled: true or option-grid-variables: on. The Romeo preflight
remains blocked until the source environment and its ACSS settings identity
are bound.

CTA Tango and Feature Milan records were read as comparison evidence. Their
settings and conversion histories apply to their own source artifacts. They do
not bind Romeo to the accepted fixture or transfer grid enablement. The
accepted grid authority proves a setting only for its documented source
environment.

## Canonical Romeo identity

The canonical corpus and exact artifact were hashed without printing payload
content. The prescribed corpus digest uses sorted
path, size, lowercase SHA-256 records and excludes Archive.tar.gz.

| Identity | Expected | Observed | Match |
| --- | --- | --- | --- |
| Canonical corpus | private_reference/frames/staging-2026-09/ | 074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e | YES |
| Corpus records | 34 | 34 | YES |
| Romeo artifact | private_reference/frames/staging-2026-09/feature-section-romeo/bricks-component-eiwwbh-feature-section-romeo.json | SHA-256 0cf29929a25bc2485ece90375d8c0f90fa1710eac0439bc5decc13af11f03f63, 24944 bytes | YES |
| Romeo component identity | Field value checked in the exact artifact | SHA-256 cc2c13d2af1bc02d979331e07a6062d759001d909756c8618e59a155ab9007ac | YES |
| Accepted ACSS fixture | fixtures/automatic_css/acss_settings.json | SHA-256 19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05 | YES |

The component identifier is recorded only as a hash. The source JSON was
decoded as inert data. No source runtime, plugin code, PHP, JavaScript, or CSS
was executed.

## Bounded roots and filename inventory

The search was limited to these authorized roots and current repository
authority documents:

- /home/jcschoeman96/projects/current/LiveFrame/private_reference
- /home/jcschoeman96/projects/current/LiveFrame/fixtures
- /home/jcschoeman96/projects/current/LiveFrame/acss

Filename-only inventory used rg --files --hidden --no-ignore for the exact
Romeo directory, its staging-2026-09 parent, private-reference manifests,
Bricks fixture metadata, Automatic.css fixture metadata, and ACSS
manifest/research metadata.

The exact Romeo directory listed the JSON artifact and three PNG screenshots.
The screenshots were not opened, inspected for metadata, or processed with
OCR. The staging parent inventory covered the 34 corpus records. It included
the adjacent environment/acss-settings.json and sibling copied-element
exports. Sibling files were not treated as Romeo authority.

The metadata filename inventory found:

- private_reference/REFERENCE_MANIFEST.md
- fixtures/automatic_css/SOURCE.md
- fixtures/automatic_css/acss_settings.json
- fixtures/bricks/SOURCE.md
- fixtures/bricks/bricks_components.json
- fixtures/bricks/bricks_theme_styles.json
- acss/README.md
- acss/4.0.1/RESEARCH_MANIFEST.yaml
- acss/4.0.1/foundations/settings/NB_ACSS_SETTINGS_SCHEMA_SOURCE_MAP_v0.1.0.md

No filesystem timestamps, inode order, directory order, or archive order were
used as authority.

## Search passes and candidate files

The search used one metadata inventory pass, one targeted sanitized content
pass, and one candidate verification pass.

| Pass | Method | Result |
| --- | --- | --- |
| Metadata inventory | Filename-only rg --files --hidden --no-ignore over the listed paths | Complete |
| Content search | One allowlisted script over the 11 files below; parsed JSON and metadata text as inert data | Complete |
| Candidate verification | One allowlisted check of the adjacent settings candidate; field categories and value hashes only | Complete |

The content pass checked counts for exact Romeo path, basename, and SHA
references; source environment/site/origin metadata; ACSS configuration
references; runtime or generator metadata; and explicit named-breakpoint
configuration metadata. It emitted file paths, metadata categories, counts,
file hashes, and hashes of candidate string values. It did not emit matching
lines or raw values.

| File ID | Candidate filename | File SHA-256 |
| --- | --- | --- |
| C01 | private_reference/frames/staging-2026-09/feature-section-romeo/bricks-component-eiwwbh-feature-section-romeo.json | 0cf29929a25bc2485ece90375d8c0f90fa1710eac0439bc5decc13af11f03f63 |
| C02 | private_reference/REFERENCE_MANIFEST.md | d4679f25cc37f1a3441f8f9c3bbea7f53e9f7f308f591e5cb3b677a049f63314 |
| C03 | private_reference/frames/staging-2026-09/environment/acss-settings.json | 3347240b2837dc28854020b0fa0f1d2100086d259123f8b964ac8f31114cad32 |
| C04 | fixtures/automatic_css/SOURCE.md | 356d83ab90e9363426e3ca9f80416067230f49a54804a8ad051692b94427a07e |
| C05 | fixtures/automatic_css/acss_settings.json | 19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05 |
| C06 | fixtures/bricks/SOURCE.md | 04c18c0463ac2416f37a3b278d93957594ac44a28bac7364c9f10d233eba8bfe |
| C07 | fixtures/bricks/bricks_components.json | bb584f35b160f5095dc67fc367884f51cff35b59693c84374426f5cecf56a1a1 |
| C08 | fixtures/bricks/bricks_theme_styles.json | 2fb1ad7156e10a0e606b701d4e7bd799698e2094b4f8e95a3be84d6935aadec5 |
| C09 | acss/README.md | b00e15eb2b88eb587ff53146887d79b6ffe274daebd94936415beb64db9f5b19 |
| C10 | acss/4.0.1/RESEARCH_MANIFEST.yaml | f46b9343a51945bba0014b30d7d9a23fc2f09ca02ba370ff46444c947182d03e |
| C11 | acss/4.0.1/foundations/settings/NB_ACSS_SETTINGS_SCHEMA_SOURCE_MAP_v0.1.0.md | 3fd2dc7c424569d61367501bbdf60a922292134780ff0d74be67fdd35d25be3b |

The initial metadata-key matcher reported one broad environment-like
substring in C03. The sole candidate verification pass used explicit
environment, snapshot, site, origin, and domain key categories. It found no
such identity field in C03. It found one ACSS-configuration-reference value
and one plugin/runtime metadata value. Their value hashes were
b8d31e852725afb1e26d53bab6095b2bff1749c9275be13ed1c05a56ed31ec09 and
b4dc66dde806261bdda8607d8707aa727d308cd80272381a5583f63899918467. These
are hashes of metadata values, not a bound settings artifact identity. No
grid enablement value was inspected.

The Bricks fixture and ACSS research manifest produced metadata-like
fingerprints under the broad category scan. They are not linked to the
Romeo artifact. The candidate table records their sanitized fingerprints
without assigning source-environment meaning.

## Candidate evidence assessment

Candidate count refers to the six evidence bundles below. The 11 filenames
above were the files covered by the content pass.

| Candidate | Romeo-side evidence identity | Environment identity hash | ACSS-side evidence identity | Snapshot/configuration link | Evidence state | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| R01 | Exact Romeo artifact path, SHA, byte count, and component identity hash verified from C01 | None found | None in the artifact | No exact Romeo path or SHA reference found in other candidates | IDENTITY_VERIFIED then INSUFFICIENT | INSUFFICIENT |
| R02 | C02 has no exact Romeo path or SHA reference | None | Private-reference manifest identity only | No link to Romeo or an ACSS settings artifact | IDENTITY_VERIFIED then INSUFFICIENT | INSUFFICIENT |
| R03 | No Romeo path or SHA reference in C03 | No explicit environment, snapshot, site, origin, or domain identity found in verification | Adjacent private settings candidate, file SHA recorded above; metadata-value fingerprints only | Adjacency does not link it to Romeo | IDENTITY_VERIFIED then INSUFFICIENT | SUPPORTING_ONLY |
| R04 | No Romeo path or SHA reference in C04 or C05 | None tied to Romeo | Accepted fixture identity and its 4.0.1 reference provenance | No exact environment/configuration link to Romeo | IDENTITY_VERIFIED then INSUFFICIENT | SUPPORTING_ONLY |
| R05 | No Romeo path or SHA reference in C06 through C08 | Fixture metadata includes a hashed environment-like candidate value, SHA-256 bd794701ab82bcc6eb942458478bf19f1d1f9f4a3af8b61bb7765f0d8a65b2ed; it is not bound to Romeo | Separate Bricks fixture metadata | No manifest or snapshot link to Romeo | IDENTITY_VERIFIED then INSUFFICIENT | SUPPORTING_ONLY |
| R06 | No Romeo path or SHA reference in C09 through C11 | ACSS research metadata includes a hashed metadata-like candidate value, SHA-256 b5bea41b6c623f7c09f1bf24dcae58ebab3c0cdd90ad966bc43a45b44867e12b; no Romeo link | Generic ACSS research and schema metadata | No source-environment or snapshot binding to Romeo | IDENTITY_VERIFIED then INSUFFICIENT | SUPPORTING_ONLY |

No candidate reached ENVIRONMENT_BOUND, CONFIG_BOUND, or AUTHORITY_READY.
No candidate was contradicted by a competing direct Romeo-bound record.

| Decision count | Count |
| --- | ---: |
| Sufficient binding | 0 |
| Supporting only | 4 |
| Insufficient | 2 |
| Contradicted | 0 |

## Rejected and insufficient evidence

| Evidence | Classification | Reason |
| --- | --- | --- |
| Same staging-2026-09 directory and adjacent settings filename | INSUFFICIENT | Directory adjacency does not bind the settings file to Romeo. |
| Repeated Bricks component _version values | INSUFFICIENT | A component field does not identify a source site, runtime, or snapshot. |
| Similar CSS variable names or Romeo's use of a grid variable | INSUFFICIENT | Variable spelling does not prove the ACSS version or enabled setting. |
| Accepted ACSS fixture and its 4.0.1 reference provenance | SUPPORTING_ONLY | The fixture has no exact Romeo environment binding. |
| CTA Tango fixture use and structural authority | SUPPORTING_ONLY | Those records bind CTA Tango's own conversion context only. |
| Feature Milan fixture use | SUPPORTING_ONLY | Those records bind Milan's own normalization input only. |
| ACSS 4.0.1 grid authority | SUPPORTING_ONLY | Its explicit enabled setting applies to its documented source environment, not Romeo. |
| Bricks fixture origin metadata | SUPPORTING_ONLY | It identifies a separate fixture and has no exact Romeo path or hash link. |
| Screenshots | NOT_SEARCHED | No OCR or visual inference was used. Screenshot metadata was skipped. |

The accepted grid authority is not applied to Romeo. The adjacent settings
candidate was not treated as Romeo's settings export, and the accepted
fixture was not used as a fallback.

## Authority verdicts

| Question | Verdict | Evidence |
| --- | --- | --- |
| Exact Romeo source identity | Verified | Corpus digest, artifact SHA, byte count, and component identity hash match |
| Romeo source environment | UNPROVEN | The exact artifact has no environment metadata; no exact path/hash binding was found |
| Romeo ACSS configuration | UNPROVEN | No Romeo-bound settings artifact or shared snapshot record was found |
| Bound settings SHA-256 | NONE | No settings artifact reached CONFIG_BOUND |
| Accepted fixture SHA match | IDENTITY_UNAVAILABLE | No Romeo-bound settings artifact exists to compare with the accepted fixture |
| Romeo ACSS version | UNPROVEN | Fixture reference provenance does not establish Romeo applicability |
| Romeo grid-variable setting | UNPROVEN | Grid state was not inspected because no configuration was bound |
| Romeo structural-grid authority | UNPROVEN | Accepted values and enablement evidence belong to another source environment |
| Romeo named Bricks breakpoint authority | UNPROVEN | No environment-bound named-breakpoint configuration was found |

The source authority records literal min-width: 767px and max-width: 767px
conditions. They remain direct Romeo source evidence and do not establish a
named Bricks breakpoint mapping.

## Search and privacy audit

METADATA_INVENTORY_PASS_COUNT=1
CONTENT_SEARCH_PASS_COUNT=1
CANDIDATE_VERIFICATION_PASS_COUNT=1
CONTENT_SEARCH_FILES=11
CANDIDATE_EVIDENCE_BUNDLES=6

RAW_PRIVATE_SOURCE_PRINTED=NO
PRIVATE_PAYLOAD_COMMITTED=NO
PRIVATE_IDENTIFIER_PUBLISHED=NO
SCREENSHOT_OCR_USED=NO
SOURCE_RUNTIME_EXECUTED=NO

The content pass emitted only relative filenames, allowlisted field
categories, counts, file hashes, and SHA-256 fingerprints of candidate string
values. It did not print JSON, CSS, matching lines, URLs, domains, settings
values, or source payload. Sensitive source identifiers were represented by
category and value hash only. The user-supplied canonical artifact path is
retained solely as required identity metadata.

The adjacent private settings file was hashed but not committed. Its
grid-variable setting was not read. No raw export, screenshot, source CSS,
setting value, or plugin/runtime code was published.

## Scope, performance, and downstream boundary

This task changed no production code, tests, fixtures, ACSS data, private
reference data, provenance register, or conversion matrix. It did not run the
canonical Romeo Bricks adapter, create a ComponentContract or
ComponentizationPlan, or run NativeGenerator.

CANONICAL_ROMEO_NORMALIZATION_RUN=NO
ROMEO_COMPONENT_CONTRACT_CREATED=NO
ROMEO_COMPONENTIZATION_PLAN_CREATED=NO
ROMEO_NATIVE_GENERATION_RUN=NO

DATA_LAYER=COLD
RUNTIME_DB_CALLS=0
NETWORK_CALLS=0
REDIS=N/A
POSTGRES=N/A
CACHE=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A

The result follows outcome D. The next action requires an owner decision:
provide new evidence that binds Romeo to a source environment and settings
configuration, or authorize a conservative no-ACSS canonical context.

ROMEO_ACSS_AUTHORITY_EVIDENCE=INSUFFICIENT
ROMEO_ACSS_AUTHORITY_APPLICABILITY=UNPROVEN_AFTER_BOUNDED_SEARCH
CANONICAL_ROMEO_NORMALIZATION_AUTHORIZED=NO
ROMEO_COMPONENTIZATION_AUTHORIZED=NO
ROMEO_IMPLEMENTATION_AUTHORIZED=NO
NEXT_GATE=OWNER_DECIDE_CONSERVATIVE_NO_ACSS_CONTEXT_OR_SUPPLY_NEW_SOURCE_EVIDENCE
STOP=ROMEO_SOURCE_ENVIRONMENT_BINDING_NOT_FOUND
