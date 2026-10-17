# Feature Milan post-PR213 breakpoint evidence recovery

## Decision

```text
BREAKPOINT_EVIDENCE_RECOVERY_RESULT=INSUFFICIENT
BREAKPOINT_AUTHORITY_EVIDENCE_COMPLETE=NO
AUTHORITY_CREATION_READY=NO
TERMINAL_STATE=BREAKPOINT_EVIDENCE_RECOVERY_REVIEW_READY_INSUFFICIENT
```

The bounded search found no source-environment record that links the exact Milan export to a Bricks site or runtime. The export proves the source name `mobile_landscape`. It does not prove a numeric width, unit, query direction, media condition, enabled state, custom/default configuration, or cascade position.

The component field `_version=2.3.1` remains a component field. The official current Bricks component schema lists `_version` as a string without defining it as the source site's runtime version. Its schema page is not version-matched to Milan. No Milan runtime version is established.

## Base gate

```text
BASE_SHA=6d681cbee6e5e715605e4761dd96961fa844141d
BASE_TREE=f2febc9a5c8670b362a4cb874c8a40a66b4875c9
BASE_CI_RUN=38709455133
BASE_CI_RESULT=success
ORIGIN_MAIN_SHA=6d681cbee6e5e715605e4761dd96961fa844141d
ORIGIN_MAIN_TREE=f2febc9a5c8670b362a4cb874c8a40a66b4875c9
BASE_WORKTREE_CLEAN=YES
```

The CI run completed successfully on the exact base SHA. The evidence pass ran in an isolated clean worktree at /home/jcschoeman96/projects/current/LiveFrame/.worktrees/feature-milan-post-pr213-breakpoint-evidence-recovery, on branch docs/feature-milan-post-pr213-breakpoint-evidence-recovery.

## Accepted programme state

```text
N0=ACCEPTED
N1=ACCEPTED
N2=ACCEPTED
A0_R=ACCEPTED

BREAKPOINT_EVIDENCE_RECOVERY=AUTHORIZED

BREAKPOINT_AUTHORITY=NOT_AUTHORIZED
DESIGN_DOCUMENT_RESOLUTION=NOT_AUTHORIZED
POST_RESOLUTION_BEHAVIOR_REISSUE=NOT_AUTHORIZED
A1=NOT_AUTHORIZED
P7_D0=NOT_AUTHORIZED

CURRENT_A0_EXACT_IDENTITY_APPLICABLE=YES
HISTORICAL_BREAKPOINT_PREFLIGHT_EXACT_IDENTITY_CURRENT=NO
HISTORICAL_BREAKPOINT_PREFLIGHT_SOURCE_EVIDENCE_REUSABLE=YES
```

The accepted current pre-resolution tuple is:

```text
DESIGN_DOCUMENT_DIGEST=74cf822d0b0346a5d0526de387d42773b0bcc4a03475ea2dd6f64fe458690d59
BEHAVIOR_BINDING_ID=bnd_3ba524068d30cd5d86515658bbbc1152bcebcaf92c521bd5369f6d12ef45061c
BEHAVIOR_CONTRACT_DIGEST=9a8987588431c6455f4017c1bedee3e55f31bd37dd73870f1fd2cfe43d0df57f
BEHAVIOR_REVIEW_ID=brv_bfe7f43e8cca65805439347ea6460837faf59d17b2a7c874cd1fc1ac4865a0b9
```

The current A0 refresh accepts that tuple and re-confirms the current breakpoint prerequisite. The older breakpoint preflight has a stale exact identity. Its source findings remain reusable. Its result was BREAKPOINT_AUTHORITY_EVIDENCE_COMPLETE=NO and AUTHORITY_CREATION_READY=NO. This record starts from those open gaps.

## Milan facts already established

```text
SOURCE_SYSTEM=Bricks component export
BREAKPOINT_SOURCE_NAME=mobile_landscape
RESPONSIVE_OVERRIDE_COUNT=3
RESPONSIVE_PROPERTY_VALUE_COUNT=6
RESPONSIVE_RESOLUTION_STATUS=unresolved
PRIVATE_MILAN_SHA256=f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132
ACSS_FIXTURE_SHA256=19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05
PRIVATE_SOURCE_EXECUTED=NO
```

The exact export has top-level keys components and globalClasses. Component ybsqrl has a nested _version string of 2.3.1. The export has no source URL, site or environment identifier, explicit bricks_version, numeric breakpoint mapping, or site breakpoint settings. The accepted normalization record reports three unresolved overrides and six property values. Its unresolved minimum and maximum values do not establish source bounds.

The adjacent file /home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/environment/acss-settings.json contains ACSS settings. Its breakpoint-named keys are auto-staggered-grid-breakpoint=992 and option-btn-full-width-mobile-breakpoint=480; it also contains vp-min=360 and vp-max=1366. These values have no demonstrated mapping to Bricks mobile_landscape.

## Bounded search

```text
SEARCH_ROOTS=
/home/jcschoeman96/projects/current/LiveFrame/private_reference
/home/jcschoeman96/projects/current/LiveFrame/fixtures
/home/jcschoeman96/projects/current/LiveFrame/acss

SEARCH_TERMS=
ybsqrl
feature-section-milan
staging-2026-09
mobile_landscape
bricks_version
breakpoint
breakpoints
custom breakpoint
2.3.1

SEARCH_BOUND_COMPLETE=YES
```

Metadata-only filename discovery and one targeted content pass with rg --no-ignore covered each approved root. A preliminary default-ignore scan omitted ignored private files, so it was superseded by the complete pass before classifying candidates. The follow-up search for the separately discovered fixture URL localhost:10049 found it in other copied-element exports and the Bricks fixture. It did not occur in the exact Milan export, the adjacent ACSS settings file, or the private reference manifest. No Milan source domain or environment identifier was discovered.

The private_reference search also matched an unrelated example JSON and frames-component PHP/JavaScript files on generic breakpoint or version terms. They have no Milan environment link, so they are not evidence candidates. The PHP and JavaScript files were not executed. The acss matches are ACSS settings research and schema files. They describe ACSS and do not define Bricks breakpoint mapping.

No versioned Bricks defaults were researched. The Milan runtime version and default-fallback applicability are both unproven, so product defaults could not establish Milan semantics. The current official Components Schema was checked only for the meaning of _version:

- Source: [Bricks Academy, Components Schema](https://academy.bricksbuilder.io/developer/schema/global/components/)
- Version applicability: current Bricks Data Model schema page; the parent schema page reports schema version 2.4.3. It is not a version-matched 2.3.1 source.
- Retrieved: 2026-10-17
- Fact supported: _version is listed as a string property. The field description is blank. The page does not define _version as a site runtime version.
- Proof class: GENERAL_PRODUCT_DOCUMENTATION_ONLY
- Sufficiency: no

## Candidate evidence inventory

All private/reference artifacts, fixtures, and sibling exports in this inventory were hashed before reading relevant portions. Repository records and validator code are read-only sources; their hashes are recorded below. Private files remain outside the repository. No downloaded source material was committed.

| ID | Absolute path | SHA-256 | Scope and classification |
| --- | --- | --- | --- |
| M01 | /home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/feature-section-milan/bricks-component-ybsqrl-feature-section-milan.json | f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132 | Exact Milan artifact. Proves the component ID and its nested _version field. It has no source environment metadata, numeric breakpoint mapping, or source conditions. |
| M02 | /home/jcschoeman96/projects/current/LiveFrame/private_reference/REFERENCE_MANIFEST.md | d4679f25cc37f1a3441f8f9c3bbea7f53e9f7f308f591e5cb3b677a049f63314 | Local reference manifest. It does not mention Milan, ybsqrl, or the staging-2026-09 directory. |
| M03 | /home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/environment/acss-settings.json | 3347240b2837dc28854020b0fa0f1d2100086d259123f8b964ac8f31114cad32 | Adjacent ACSS settings. It does not identify a Bricks site, link to the Milan export, or map its values to Bricks breakpoints. |
| M04a | /home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/cta-section-tango/bricks-component-hxambs-cta-section-tango.json | 73f866a27070c010584babe230b5ffd0c78dc704388fd8b6c286e149a3d93a87 | Sibling copied-element export. It has component hxambs with nested _version=2.3.1; it does not identify Milan's runtime. |
| M04b | /home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/hero-barcelona/bricks-component-gplgbn-hero-barcelona.json | 5defe5aef50955c5f03634f25a4ae068ddfe9b571c820d862bab60790b10291c | Sibling copied-element export. It has component gplgbn with nested _version=2.3.1; it does not identify Milan's runtime. |
| M04c | /home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/slide-menu-alpha/bricks-component-njwzgj-slide-navigation-alpha-(css).json | 2d3f0978ff33421f8c2d24cdf329188d4340b685b9ce31de6fedb619e56d7d7c | Sibling copied-element export. It has component njwzgj with nested _version=2.3.1; it does not identify Milan's runtime. |
| M04d | /home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/gallery-bravo/bricks-component-ohflag-gallery-bravo-(css).json | 9a6b06e2275fb4db79920e101efa8c2ea5b8fc542519f674625d50fcd22e762f | Sibling copied-element export. It has component ohflag with nested _version=2.3.1; it does not identify Milan's runtime. |
| M04e | /home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/slider-section-basel/bricks-component-kpajhw-slider-section-basel.json | 6c1f7b20be95e3110db84ba4adc847da5da3d225ebfd12fb7b2713170a2e271f | Sibling copied-element export. It has component kpajhw with nested _version=2.3.1; it does not identify Milan's runtime. |
| M04f | /home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/feature-section-romeo/bricks-component-eiwwbh-feature-section-romeo.json | 0cf29929a25bc2485ece90375d8c0f90fa1710eac0439bc5decc13af11f03f63 | Sibling copied-element export. It has component eiwwbh with nested _version=2.3.1; it does not identify Milan's runtime. |
| M04g | /home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/pricing-section-echo/bricks-component-iqnoio-pricing-section-echo.json | b81ed696e483334a8ae154f5f3a6f2c9557cd99b14ea49675fad56f23fa22a35 | Sibling copied-element export. It has component iqnoio with nested _version=2.3.1; it does not identify Milan's runtime. |
| M04h | /home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/header-basel/bricks-component-mcpgcr-header-basel-(controls).json | 1e57f7413ab01f865a93f6bf18c8814d11d01ee4e1b6163716e0acb020d71298 | Sibling copied-element export. It has component mcpgcr with nested _version=2.3.1; it does not identify Milan's runtime. |
| F01 | /home/jcschoeman96/projects/current/LiveFrame/fixtures/automatic_css/acss_settings.json | 19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05 | ACSS fixture. Its breakpoint-named values do not map to Bricks mobile_landscape. |
| F02 | /home/jcschoeman96/projects/current/LiveFrame/fixtures/bricks/bricks_components.json | bb584f35b160f5095dc67fc367884f51cff35b59693c84374426f5cecf56a1a1 | Separate Bricks fixture. Its top-level version is 2.3.1 and its sourceUrl is http://localhost:10049; it contains no ybsqrl component or Milan environment identity. |
| F03 | /home/jcschoeman96/projects/current/LiveFrame/fixtures/bricks/SOURCE.md | 04c18c0463ac2416f37a3b278d93957594ac44a28bac7364c9f10d233eba8bfe | Provenance for the separate fixture. It describes that fixture's local source and does not link it to Milan. |
| H01 | /home/jcschoeman96/projects/current/LiveFrame/sources/work/hero_india/fidelity/breakpoint_authority.json | 5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0 | Hero India and DanBricks only. Its 767px, max-width, media condition, enabled state, and order 3 are CROSS_ENVIRONMENT_REFERENCE_ONLY. |
| D01 | /home/jcschoeman96/projects/current/LiveFrame/docs/development/feature_milan_ir4_post_pr213_componentization_preflight_refresh.md | f91e4c99be06b7aec8343f8a2a126b2898e30bcba0023e72dbcbd949fb8d4ada | Accepted current A0 refresh. Confirms the current tuple, unresolved responsive inventory, reusable historical evidence, and Q13 blocker. |
| D02 | /home/jcschoeman96/projects/current/LiveFrame/docs/development/feature_milan_ir4_post_pr213_normalization_record.md | 46fc3f87b94058a4033ef39aff40c7bb035bf2255b7634834f53d614606bece6 | Current normalization evidence. Establishes the Milan source name and unresolved status. |
| D03 | /home/jcschoeman96/projects/current/LiveFrame/docs/development/feature_milan_breakpoint_authority_preflight.md | 93bbd98561d2c3142b88d475f92a5bc7cc90cb339da3dfa61ee8f8813d791f27 | Historical gap matrix. Its exact identity is stale; its source findings remain reusable. |
| D04 | /home/jcschoeman96/projects/current/LiveFrame/docs/development/feature_milan_ir4_post_pr213_behavior_contract_reissue.md | 0617dcfd74f349f0e32fe6847288c847099bc40abe7b8b6a69f0b2d200b96a16 | Accepted N1 record. Confirms the current Behavior binding and contract digest. |
| D05 | /home/jcschoeman96/projects/current/LiveFrame/docs/development/feature_milan_ir4_post_pr213_behavior_review_result.md | 91f11877e7daa1067b2978438aca3b0101d40b2985be9bf0cd3b9dd9fda8701f | Accepted N2 review record. Confirms the current review ID and downstream restrictions. |
| D06 | /home/jcschoeman96/projects/current/LiveFrame/apps/live_frames/lib/live_frames/responsive/breakpoint_authority.ex | 89a1198e0e6d03ae011102f513fcc18b91137ea4d23cd8a658aa9c85fe832d46 | Current read-only authority validator contract. It states schema requirements, not Milan source facts. |

The shared directory label and repeated nested _version values do not define an environment link or runtime-version field. Several sibling exports contain sourceUrl=http://localhost:10049. Milan's exact artifact has no sourceUrl; the private manifest does not link the sibling exports to ybsqrl. The separate Bricks fixture has the same URL but no Milan component. These files do not prove Milan applicability.

## Evidence matrix

| Fact | Required | Observed value | Evidence | SHA-256 or URL | Scope | Proof class | Conflict | Sufficient | Reason |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Source environment identity | yes | Unproven | M01, M02, M03 | f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132; d4679f25cc37f1a3441f8f9c3bbea7f53e9f7f308f591e5cb3b677a049f63314; 3347240b2837dc28854020b0fa0f1d2100086d259123f8b964ac8f31114cad32 | Exact artifact and adjacent ACSS file; no site, domain, or environment identifier linked to ybsqrl | UNPROVEN | None | no | A directory label and adjacent ACSS file do not link the artifact to a source site. |
| Source system | yes | Bricks component export | M01, current normalization record | f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132; 46fc3f87b94058a4033ef39aff40c7bb035bf2255b7634834f53d614606bece6 | Export/parser family only; no site or runtime identity | DIRECT_MILAN_SOURCE_ENVIRONMENT | None | yes, for source-system label only | The accepted Milan normalization record and exact component export establish the source family. |
| Bricks runtime version | yes | Unproven; component _version=2.3.1 | M01, M04a-M04h, F02, official Components Schema | f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132; sibling and fixture hashes above; https://academy.bricksbuilder.io/developer/schema/global/components/ | Milan component field; sibling fields; current general schema | UNPROVEN | None | no | The schema lists _version as a string but gives no runtime meaning. No source-environment record defines or links it. |
| mobile_landscape source name | yes | mobile_landscape | M01, current normalization record | f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132; 46fc3f87b94058a4033ef39aff40c7bb035bf2255b7634834f53d614606bece6 | Exact Milan export and current normalized record; status remains unresolved | DIRECT_MILAN_SOURCE_ENVIRONMENT | Same name appears in Hero India | yes, for source name only | The Milan record establishes the name. It does not give numeric or query semantics. |
| Source width | yes | Unproven | M01, current normalization record, H01 | f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132; 46fc3f87b94058a4033ef39aff40c7bb035bf2255b7634834f53d614606bece6; 5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0 | Milan has no resolved width; Hero India records 767 in another environment | CROSS_ENVIRONMENT_REFERENCE_ONLY | Hero India 767 | no | No Milan source or applicable fallback gives a numeric width. |
| Unit | yes | Unproven | M01, current normalization record, H01 | f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132; 46fc3f87b94058a4033ef39aff40c7bb035bf2255b7634834f53d614606bece6; 5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0 | No Milan unit is recorded; Hero India uses px in its own authority | CROSS_ENVIRONMENT_REFERENCE_ONLY | Hero India px | no | Schema acceptance of px does not establish Milan's source unit. |
| Minimum width | yes | Unproven; normalized nil is unresolved | Current normalization record, H01 | 46fc3f87b94058a4033ef39aff40c7bb035bf2255b7634834f53d614606bece6; 5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0 | Milan range remains unresolved; Hero India min is nil in its own record | CROSS_ENVIRONMENT_REFERENCE_ONLY | Hero India range does not apply | no | An unresolved normalized nil is not proof that the source has no minimum. |
| Maximum width | yes | Unproven; normalized nil is unresolved | Current normalization record, H01 | 46fc3f87b94058a4033ef39aff40c7bb035bf2255b7634834f53d614606bece6; 5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0 | Milan range remains unresolved; Hero India max is 767 in its own record | CROSS_ENVIRONMENT_REFERENCE_ONLY | Hero India 767 does not apply | no | No Milan source or applicable fallback proves the upper bound. |
| Query semantics | yes | Unproven | M01, current normalization record, H01 | f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132; 46fc3f87b94058a4033ef39aff40c7bb035bf2255b7634834f53d614606bece6; 5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0 | Milan has no max-width or min-width evidence; Hero India uses max-width | CROSS_ENVIRONMENT_REFERENCE_ONLY | Hero India max-width | no | The word mobile does not prove query direction. |
| Media condition | yes | Unproven | M01, current normalization record, H01 | f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132; 46fc3f87b94058a4033ef39aff40c7bb035bf2255b7634834f53d614606bece6; 5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0 | No Milan media condition; Hero India records @media (max-width: 767px) | CROSS_ENVIRONMENT_REFERENCE_ONLY | Hero India condition is not Milan evidence | no | The matching condition needs a Milan width and direction. |
| Enabled status | yes | Unproven | M01, current normalization record | f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132; 46fc3f87b94058a4033ef39aff40c7bb035bf2255b7634834f53d614606bece6 | No Milan enable/disable field is present in the inspected breakpoint evidence | UNPROVEN | None | no | The authority validator requires enabled=true; absence from the component export proves neither state. |
| Custom breakpoint state | yes | Unproven | M01, M02, M03 | f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132; d4679f25cc37f1a3441f8f9c3bbea7f53e9f7f308f591e5cb3b677a049f63314; 3347240b2837dc28854020b0fa0f1d2100086d259123f8b964ac8f31114cad32 | Component export has no Bricks site settings; adjacent file is ACSS | UNPROVEN | None | no | The ACSS file does not prove Bricks custom breakpoint state. |
| Default fallback applicability | yes | Unproven | M01, M02, M03, H01 | f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132; d4679f25cc37f1a3441f8f9c3bbea7f53e9f7f308f591e5cb3b677a049f63314; 3347240b2837dc28854020b0fa0f1d2100086d259123f8b964ac8f31114cad32; 5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0 | Hero India fallback evidence applies to DanBricks only; Milan version and config are unproven | CROSS_ENVIRONMENT_REFERENCE_ONLY | Hero India fallback has another environment | no | Route B requires Milan environment, runtime version, and default applicability first. |
| Cascade position/order | yes | Unproven | M01, current normalization record, H01, authority validator | f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132; 46fc3f87b94058a4033ef39aff40c7bb035bf2255b7634834f53d614606bece6; 5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0; 89a1198e0e6d03ae011102f513fcc18b91137ea4d23cd8a658aa9c85fe832d46 | Milan order is absent; repository schema constraints are not source evidence; Hero India order is 3 in its own environment | CROSS_ENVIRONMENT_REFERENCE_ONLY | Hero India order 3 and ordering do not apply | no | Milan needs its full applicable breakpoint ordering and mobile_landscape position. |

CONFLICTING_BREAKPOINT_EVIDENCE=NO. The Hero India values are comparative evidence only. The separate Bricks fixture and sibling exports are not conflicting Milan observations.

## Route evaluation

```text
E01_SOURCE_ENVIRONMENT_IDENTITY=UNPROVEN
E01_PROOF_CLASS=UNPROVEN
E01_SUFFICIENT=NO

E02_BRICKS_RUNTIME_VERSION=UNPROVEN
E02_PROOF_CLASS=UNPROVEN
E02_SUFFICIENT=NO

E03_CUSTOM_BREAKPOINT_STATE=UNPROVEN
E03_PROOF_CLASS=UNPROVEN
E03_SUFFICIENT=NO

E04_SOURCE_WIDTH=UNPROVEN
E04_PROOF_CLASS=CROSS_ENVIRONMENT_REFERENCE_ONLY
E04_SUFFICIENT=NO

E05_UNIT=UNPROVEN
E05_PROOF_CLASS=CROSS_ENVIRONMENT_REFERENCE_ONLY
E05_SUFFICIENT=NO

E06_QUERY_SEMANTICS=UNPROVEN
E06_PROOF_CLASS=CROSS_ENVIRONMENT_REFERENCE_ONLY
E06_SUFFICIENT=NO

E07_MIN_WIDTH=UNPROVEN
E07_MAX_WIDTH=UNPROVEN
E07_PROOF_CLASS=CROSS_ENVIRONMENT_REFERENCE_ONLY
E07_SUFFICIENT=NO

E08_MEDIA_CONDITION=UNPROVEN
E08_PROOF_CLASS=CROSS_ENVIRONMENT_REFERENCE_ONLY
E08_SUFFICIENT=NO

E09_ENABLED=UNPROVEN
E09_PROOF_CLASS=UNPROVEN
E09_SUFFICIENT=NO

E10_CASCADE_POSITION=UNPROVEN
E10_PROOF_CLASS=CROSS_ENVIRONMENT_REFERENCE_ONLY
E10_SUFFICIENT=NO

DEFAULT_FALLBACK_APPLICABILITY=UNPROVEN
DEFAULT_FALLBACK_PROOF_CLASS=CROSS_ENVIRONMENT_REFERENCE_ONLY
DEFAULT_FALLBACK_SUFFICIENT=NO

BREAKPOINT_EVIDENCE_RECOVERY_RESULT=INSUFFICIENT
BREAKPOINT_AUTHORITY_EVIDENCE_COMPLETE=NO
AUTHORITY_CREATION_READY=NO

MINIMUM_ADDITIONAL_EVIDENCE_REQUIRED=
E01=Source-site or environment record with identifier and exact Milan export hash link
E02=Bricks runtime-version record from that linked environment
E03=Bricks site settings showing custom breakpoint state and default applicability
E04_E09=Exact-environment Bricks breakpoint export with width, unit, direction, one bound, media condition, and enabled state
E10=Exact-environment Bricks breakpoint ordering with mobile_landscape position
```

Route A is unavailable. No direct Milan environment record proves the source site, runtime, Bricks settings, breakpoint mapping, enabled state, or cascade.

Route B is unavailable. The required Milan environment identity, runtime version, and default-fallback applicability are unproven. The official current schema page is general documentation and has no version-matched default mapping.

```text
PROOF_CLASS=DIRECT_MILAN_SOURCE_ENVIRONMENT
DIRECT_MILAN_ROUTE_COMPLETE=NO

PROOF_CLASS=MILAN_VERSION_MATCHED_DEFAULT_WITH_SOURCE_FALLBACK_PROOF
VERSION_MATCHED_DEFAULT_ROUTE_COMPLETE=NO

HERO_INDIA_CLASSIFICATION=CROSS_ENVIRONMENT_REFERENCE_ONLY
HERO_INDIA_PROMOTED_TO_MILAN_AUTHORITY=NO
ACSS_BREAKPOINTS_PROMOTED_TO_BRICKS=NO
```

## Current BreakpointAuthority contract

The read-only validator is /home/jcschoeman96/projects/current/LiveFrame/apps/live_frames/lib/live_frames/responsive/breakpoint_authority.ex, SHA-256 89a1198e0e6d03ae011102f513fcc18b91137ea4d23cd8a658aa9c85fe832d46.

It requires schema version 1.0.0, top-level accepted status, positive top-level authority level, non-empty authority type, and cascade ordering descending_width. Each entry requires the exact source name, non-negative numeric source width, unit px, one query direction, a matching media condition, exactly one corresponding min or max bound, enabled status, positive cascade order, positive authority level, non-empty authority type, and accepted entry status.

This slice does not choose authority level or authority type. Validator requirements do not establish Milan source facts.

## Remaining gaps and minimum evidence

```text
REMAINING_GAPS=
E01 source environment identity
E02 Milan Bricks runtime version
E03 custom breakpoint configuration state
Default fallback applicability
E04 mobile_landscape source width
E05 unit
E06 query semantics
E07 resolved range and exactly one bound
E08 matching media condition
E09 enabled status
E10 cascade ordering and mobile_landscape position
```

Minimum additional evidence:

| Gap | Minimum additional evidence artifact |
| --- | --- |
| E01 source environment identity | A source-site or environment record with a site/domain/environment identifier and a structural or cryptographic link to the exact Milan export hash. |
| E02 runtime version | A Bricks runtime-version record from that same linked source environment. The component _version field alone does not close this gap. |
| E03 custom state and default applicability | Bricks site settings from the exact source environment that show whether custom breakpoints are enabled, configured, or absent. A default fallback needs source-backed proof that no custom configuration overrides it. |
| E04-E09 width, unit, direction, range, media condition, enabled state | The exact environment's Bricks breakpoint configuration export with the mobile_landscape definition and its enabled state. It must expose the source width and unit, one query direction, the corresponding single bound, and matching media condition. |
| E10 order | The same source settings export, or an associated Bricks breakpoint list, with the full applicable ordering and the mobile_landscape position. |
| Route B if direct mapping is absent | First provide E01, E02, and explicit default-applicability proof. Then use primary Bricks documentation or versioned source matching the proven Milan runtime to establish default mapping and cascade semantics. |

A later authority-creation gate still owns authority level, authority type, accepted status, and creation of the authority record.

## Lifecycle and downstream boundary

```text
unstarted=complete
base_verified=complete
current_a0_authority_verified=complete
historical_gap_matrix_loaded=complete
search_scope_frozen=complete
direct_milan_evidence_searched=complete
environment_linkage_classified=complete
version_and_configuration_classified=complete
breakpoint_semantics_classified=complete
evidence_sufficiency_decided=complete
recovery_review_ready=complete

BREAKPOINT_AUTHORITY_CREATED=NO
BREAKPOINT_AUTHORITY_VALIDATED=NO
DESIGN_DOCUMENT_RESOLVED=NO
RESOLVED_DESIGN_DOCUMENT_DIGEST=NONE
POST_RESOLUTION_BEHAVIOR_BINDING_CREATED=NO
POST_RESOLUTION_BEHAVIOR_CONTRACT_CREATED=NO
POST_RESOLUTION_BEHAVIOR_REVIEW_CREATED=NO
POST_RESOLUTION_BEHAVIOR_REISSUE_STARTED=NO

UNSUPPORTED_NODE_ID=node_000001_000002
UNSUPPORTED_NODE_BLOCKER_CURRENT=YES
Q13_RESOLVED=NO
OWNER_DECISION_RECORDED=NO
SEMANTIC_INPUT_CREATED=NO
P7_D0_STARTED=NO
COMPONENT_PROPOSER_STARTED=NO
COMPONENT_CONTRACT_CREATED=NO
COMPONENTIZATION_PLAN_CREATED=NO
```

This recovery addresses A1-Q12 only. It does not clear A1-Q13 or authorize D0.

## Scope and verification

```text
CHANGED_FILES=docs/development/feature_milan_ir4_post_pr213_breakpoint_evidence_recovery.md
PRODUCTION_CODE_CHANGED=NO
TEST_CODE_CHANGED=NO
FIXTURE_CHANGED=NO
PRIVATE_EVIDENCE_COMMITTED=NO
BREAKPOINT_AUTHORITY_CREATED=NO
DESIGN_DOCUMENT_RESOLVED=NO
```

The local verification for this documentation-only change is git diff --check and a one-file name-status review. Repository Mix quality gates are left to exact-head CI. No tests were added or run for this evidence record.
