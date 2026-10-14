# Feature Milan breakpoint authority evidence preflight

```text
STATUS=BREAKPOINT_AUTHORITY_PREFLIGHT_REVIEW_READY
BREAKPOINT_AUTHORITY_EVIDENCE_COMPLETE=NO
AUTHORITY_CREATION_READY=NO
PRIVATE_SOURCE_EXECUTED=NO
```

## Scope and lifecycle

This record audits whether Milan-applicable evidence supports a future accepted
`BreakpointAuthority` entry for `mobile_landscape`. It does not create or accept
authority, resolve the DesignDocument, calculate a post-resolution digest,
reissue Behavior artifacts, freeze `SemanticInput`, or run D0 or the component
proposer.

The audit reached `review_ready` after verifying evidence identity, inventorying
responsive evidence, classifying source-environment applicability and breakpoint
semantics, and deciding evidence sufficiency. The evidence is insufficient for
authority creation. This is a review-ready preflight with recorded gaps, not a
hard stop.

| Lifecycle state | Result |
| --- | --- |
| `unstarted` | complete |
| `evidence_identity_verified` | complete |
| `Milan_responsive_evidence_inventoried` | complete |
| `source_environment_applicability_classified` | complete |
| `breakpoint_semantics_classified` | complete |
| `evidence_sufficiency_decided` | complete, insufficient |
| `review_ready` | complete |

## Accepted base and preserved Milan identity

| Field | Value |
| --- | --- |
| `BASE_SHA` | `96b3db4111bc99e9f3c04dc49b582c76649b8c68` |
| `BASE_TREE` | `9ed3bc4345b75044b9516c01a4b00a05c1c31aae` |
| `BASE_CI_RUN` | `38568000497` |
| `BASE_CI_RESULT` | `success`, completed push on the exact base SHA |
| `A0` | `ACCEPTED` |
| `PRE_RESOLUTION_IR_VERSION` | `4.0.0` |
| `PRE_RESOLUTION_DESIGN_DOCUMENT_DIGEST` | `52544dcc0d279d91d3d56d054c9785b18f96e77a5520b782726b678c404db864` |
| `PRE_RESOLUTION_BINDING_ID` | `bnd_caf04646aa92bbf2026ec3a2a1298a448ab03c624d27519c0740f874e64d22a7` |
| `PRE_RESOLUTION_BEHAVIOR_CONTRACT_DIGEST` | `303273984f180ea671ba968c841672603f0a0604368385b8f295e1cfcc64f826` |
| `PRE_RESOLUTION_BEHAVIOR_REVIEW_ID` | `brv_5159f503fec2bb56c416642e6ea2151c402a2d9a70670d50b9fe153d5dd62e1d` |

The accepted A0 record is
[`feature_milan_ir4_componentization_preflight.md`](feature_milan_ir4_componentization_preflight.md).
Its SHA-256 is
`1b17d70c196aac488f58d78254042f111cffc848cf8c0bf0c56f810c804ac844`.
These are pre-resolution identities. No post-resolution identity is derived in
this preflight.

```text
BREAKPOINT_AUTHORITY_ACCEPTED=NO
RESOLVED_DESIGN_DOCUMENT_CREATED=NO
RESOLVED_DESIGN_DOCUMENT_IDENTITY_FROZEN=NO
POST_RESOLUTION_BEHAVIOR_BINDING_REISSUED=NO
POST_RESOLUTION_BEHAVIOR_CONTRACT_REISSUED=NO
POST_RESOLUTION_BEHAVIOR_REVIEW_ISSUED=NO
A1_SEMANTIC_INPUT_FROZEN=NO
REAL_MILAN_D0_EXECUTED=NO
COMPONENT_PROPOSER_EXECUTED=NO
```

## Evidence identity and scope

| Evidence | SHA-256 | Observed scope |
| --- | --- | --- |
| `/home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/feature-section-milan/bricks-component-ybsqrl-feature-section-milan.json` | `f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132` | Exact supplied Milan component artifact; top-level keys are `components` and `globalClasses`; component ID is `ybsqrl`; the component has a nested `_version` value of `2.3.1`. |
| `/home/jcschoeman96/projects/current/LiveFrame/fixtures/automatic_css/acss_settings.json` | `19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05` | ACSS settings fixture. Relevant keys include `auto-staggered-grid-breakpoint=992` and `option-btn-full-width-mobile-breakpoint=480`; neither names nor maps the Bricks `mobile_landscape` breakpoint. |
| `docs/development/feature_milan_ir4_componentization_preflight.md` | `1b17d70c196aac488f58d78254042f111cffc848cf8c0bf0c56f810c804ac844` | Accepted Milan normalization record tied to the exact private artifact hash. It reports three unresolved responsive overrides and six property values. |
| `sources/work/hero_india/fidelity/breakpoint_authority.json` | `5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0` | Hero India authority only. Its source context is LocalWP `DanBricks`, domain `danbricks.local`, Bricks `2.3.1`, component `sqhmmc`; it records `mobile_landscape=767px`, `max-width`, and cascade order 3. |
| `fixtures/bricks/bricks_components.json` | `bb584f35b160f5095dc67fc367884f51cff35b59693c84374426f5cecf56a1a1` | Supporting fixture has top-level `version=2.3.1` and uses `mobile_landscape` settings, but contains no component with ID `ybsqrl` and no Milan environment identity. |

The Milan evidence directory contains the component JSON and two images, with
no sibling metadata file or manifest. The private reference manifest
`/home/jcschoeman96/projects/current/LiveFrame/private_reference/REFERENCE_MANIFEST.md`
has SHA-256
`d4679f25cc37f1a3441f8f9c3bbea7f53e9f7f308f591e5cb3b677a049f63314`; it has no
reference to the Milan artifact, `ybsqrl`, or the `staging-2026-09` directory.

The Milan JSON has no source URL, site or environment identifier, explicit
`bricks_version`, breakpoint mapping, media condition, or custom breakpoint
setting. Its nested `_version=2.3.1` is not identified by the artifact as the
source environment's Bricks runtime version. The same number in the separate
Bricks fixture does not link that fixture to Milan. The ACSS fixture provides
style settings only; its breakpoint-named values do not establish Bricks
responsive mapping.

The accepted A0 record identifies the normalized source name
`mobile_landscape`, with `CURRENT_MIN_WIDTH=nil`, `CURRENT_MAX_WIDTH=nil`, and
`CURRENT_RESOLUTION_STATUS=unresolved`. Its three overrides affect six
properties. Those unresolved values do not supply a numeric width or query.

## Future authority fields and evidence matrix

The repository validator requires a non-negative numeric `source_width`,
`unit=px`, one of `query_semantics=max-width|min-width`, a matching media
condition, `enabled=true`, positive `cascade_order` and `authority_level`,
non-empty `authority_type`, `status=accepted`, top-level
`authority_status=accepted`, and `cascade.ordering=descending_width`. A
breakpoint name by itself cannot pass validation or resolve an override.

Proof classes used below are `DIRECT_MILAN_SOURCE_ENVIRONMENT`,
`MILAN_VERSION_MATCHED_DEFAULT_WITH_SOURCE_FALLBACK_PROOF`,
`CROSS_ENVIRONMENT_REFERENCE_ONLY`, `GENERAL_PRODUCT_DOCUMENTATION_ONLY`, and
`UNPROVEN`.

| FACT | REQUIRED_BY_FUTURE_AUTHORITY | OBSERVED_VALUE | EVIDENCE_FILE | EVIDENCE_SHA256 | EVIDENCE_SCOPE | PROOF_CLASS | CONFLICTING_EVIDENCE | SUFFICIENT | REASON |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Source environment identity | Yes | `UNPROVEN`; export has no site, domain, source URL, or environment ID | Milan component JSON; private reference manifest | `f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132`; `d4679f25cc37f1a3441f8f9c3bbea7f53e9f7f308f591e5cb3b677a049f63314` | Artifact is hash-verified, but no source environment is identified or linked | `UNPROVEN` | None found | No | The staging directory name and component ID do not identify a source site or runtime. |
| Source system | Yes | Bricks component export and `Bricks.to_ir/2` ingestion are recorded; exact site/runtime remains unknown | Milan component JSON; accepted A0 record | `f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132`; `1b17d70c196aac488f58d78254042f111cffc848cf8c0bf0c56f810c804ac844` | Identifies export/parser family, not the source environment | `DIRECT_MILAN_SOURCE_ENVIRONMENT` | None found | Yes, for source-system label only | It does not prove version or environment applicability. |
| Bricks version | Yes | `UNPROVEN`; nested component `_version=2.3.1` has no runtime-version definition | Milan component JSON; Bricks fixture | `f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132`; `bb584f35b160f5095dc67fc367884f51cff35b59693c84374426f5cecf56a1a1` | Milan artifact has a nested version-like field; separate fixture has global `version=2.3.1` but lacks `ybsqrl` | `UNPROVEN` | Values are not contradictory, but neither establishes Milan runtime version | No | No source-environment record defines the nested field or links the separate fixture to Milan. |
| `mobile_landscape` source name | Yes | `mobile_landscape` | Accepted A0 record | `1b17d70c196aac488f58d78254042f111cffc848cf8c0bf0c56f810c804ac844` | Normalized Milan record tied to the exact artifact SHA; current resolution remains unresolved | `DIRECT_MILAN_SOURCE_ENVIRONMENT` | Hero India uses the same name in its own environment | Yes, for the source name only | The normalized Milan record proves the name, not its numeric or media semantics. |
| Source width | Yes | `UNPROVEN`; normalized `min_width` and `max_width` are nil while unresolved | Accepted A0 record; Hero India authority | `1b17d70c196aac488f58d78254042f111cffc848cf8c0bf0c56f810c804ac844`; `5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0` | Milan has no resolved width; Hero India records 767 in a different environment | `CROSS_ENVIRONMENT_REFERENCE_ONLY` | Hero India `767` is not Milan evidence | No | A matching name or number cannot transfer authority between environments. |
| Unit | Yes | `UNPROVEN` | Milan component JSON; accepted A0 record | `f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132`; `1b17d70c196aac488f58d78254042f111cffc848cf8c0bf0c56f810c804ac844` | No Milan unit is recorded for the unresolved breakpoint | `UNPROVEN` | Hero India uses `px`, but is not applicable | No | Do not infer CSS pixels from the name or from Hero India. |
| Minimum width | Yes | `UNPROVEN`; normalized value is nil while unresolved | Accepted A0 record; Hero India authority | `1b17d70c196aac488f58d78254042f111cffc848cf8c0bf0c56f810c804ac844`; `5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0` | No Milan range is resolved; Hero entry has nil minimum width | `CROSS_ENVIRONMENT_REFERENCE_ONLY` | Hero India has `min_width=nil`, but does not apply to Milan | No | The normalized nil is unresolved input, not a proven source configuration. |
| Maximum width | Yes | `UNPROVEN`; normalized value is nil while unresolved | Accepted A0 record; Hero India authority | `1b17d70c196aac488f58d78254042f111cffc848cf8c0bf0c56f810c804ac844`; `5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0` | Milan has no resolved maximum; Hero entry records 767 | `CROSS_ENVIRONMENT_REFERENCE_ONLY` | Hero India `max_width=767` is not Milan evidence | No | No Milan source or applicable fallback proves a maximum. |
| Query semantics | Yes | `UNPROVEN` | Milan component JSON; accepted A0 record; Hero India authority | `f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132`; `1b17d70c196aac488f58d78254042f111cffc848cf8c0bf0c56f810c804ac844`; `5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0` | Milan has no `max-width` or `min-width` evidence; Hero India uses `max-width` | `CROSS_ENVIRONMENT_REFERENCE_ONLY` | Hero India `max-width` does not establish Milan semantics | No | No Milan rule or version-matched Bricks source proves the direction. |
| Media condition | Yes | `UNPROVEN` | Milan component JSON; accepted A0 record; Hero India authority | `f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132`; `1b17d70c196aac488f58d78254042f111cffc848cf8c0bf0c56f810c804ac844`; `5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0` | No Milan media condition; Hero India records `@media (max-width: 767px)` | `CROSS_ENVIRONMENT_REFERENCE_ONLY` | Hero India condition is not Milan evidence | No | Exact condition and numeric semantics are both absent for Milan. |
| Enabled status | Yes | `UNPROVEN` | Milan component JSON; accepted A0 record | `f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132`; `1b17d70c196aac488f58d78254042f111cffc848cf8c0bf0c56f810c804ac844` | No enable/disable field is present in the inspected Milan breakpoint evidence | `UNPROVEN` | None found | No | The future validator requires `enabled=true`; absence from this component export does not prove enabled state. |
| Custom breakpoint state | Yes | `UNPROVEN`; no custom-breakpoint state is present in the Milan component export | Milan component JSON; private reference manifest | `f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132`; `d4679f25cc37f1a3441f8f9c3bbea7f53e9f7f308f591e5cb3b677a049f63314` | Component export does not establish site-level responsive settings | `UNPROVEN` | Hero India confirms defaults only for DanBricks | No | A component export cannot prove that Milan's site setting is absent or disabled. |
| Default fallback applicability | Yes | `UNPROVEN` | Milan component JSON; Hero India authority | `f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132`; `5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0` | Hero India documents its own fallback; Milan has no linked version or custom-setting proof | `CROSS_ENVIRONMENT_REFERENCE_ONLY` | Hero India fallback proof is scoped to DanBricks | No | The default path requires Milan version and configuration proof first. |
| Cascade ordering | Yes | `UNPROVEN` | Milan component JSON; accepted A0 record; Hero India authority | `f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132`; `1b17d70c196aac488f58d78254042f111cffc848cf8c0bf0c56f810c804ac844`; `5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0` | Milan ordering is absent; validator accepts only `descending_width`; Hero India records that ordering for DanBricks | `CROSS_ENVIRONMENT_REFERENCE_ONLY` | Hero India ordering is not Milan evidence | No | Repository schema constraints do not prove source cascade behavior. |
| `mobile_landscape` cascade order | Yes | `UNPROVEN` | Milan component JSON; accepted A0 record; Hero India authority | `f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132`; `1b17d70c196aac488f58d78254042f111cffc848cf8c0bf0c56f810c804ac844`; `5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0` | No Milan ordinal; Hero India assigns order 3 in its own list | `CROSS_ENVIRONMENT_REFERENCE_ONLY` | Hero India order 3 is not Milan evidence | No | Matching source name does not establish the source order index. |
| Authority level | Yes | `UNPROVEN` | Breakpoint authority validator; Hero India authority | `apps/live_frames/lib/live_frames/responsive/breakpoint_authority.ex`; `5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0` | Validator requires a positive integer; Hero India uses level 3 in its own accepted record | `CROSS_ENVIRONMENT_REFERENCE_ONLY` | No Milan authority-level decision exists | No | A source-specific accepted level has not been established for Milan. |
| Authority type | Yes | `UNPROVEN` | Breakpoint authority validator; Hero India authority | `apps/live_frames/lib/live_frames/responsive/breakpoint_authority.ex`; `5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0` | Validator requires a non-empty string; Hero India uses a version-matched-default type for its source | `CROSS_ENVIRONMENT_REFERENCE_ONLY` | Hero India type does not apply to Milan without fallback proof | No | Milan evidence has not established direct authority or a version-matched default path. |
| Authority status | Yes | Not accepted; no Milan authority artifact exists | Breakpoint authority validator; accepted A0 record | `apps/live_frames/lib/live_frames/responsive/breakpoint_authority.ex`; `1b17d70c196aac488f58d78254042f111cffc848cf8c0bf0c56f810c804ac844` | Validator requires accepted status; A0 says no exact Milan authority is present | `UNPROVEN` | None found | No | This evidence-only slice cannot set accepted status. |

No row establishes the complete set of future authority fields. `HERO_INDIA_AUTHORITY_REUSED_AS_MILAN_AUTHORITY=NO`. The Hero India record remains a process and schema precedent only.

## Source-environment applicability gate

```text
MILAN_SOURCE_ENVIRONMENT_IDENTIFIED=NO
MILAN_SOURCE_ENVIRONMENT_LINK_PROVEN=NO
MILAN_BRICKS_VERSION_PROVEN=NO
MILAN_CUSTOM_BREAKPOINT_STATE_PROVEN=NO
VERSION_MATCHED_DEFAULT_SOURCE_AVAILABLE=NO
DEFAULT_FALLBACK_APPLICABILITY_PROVEN=NO
```

No candidate Milan source environment was identified, so there is no nearby
environment to attach to the artifact and no environment-link mismatch to
assert. The directory label `staging-2026-09` and the nested component
`_version` are insufficient to identify the source site or its runtime. The
Hero India source is explicitly excluded from Milan applicability.

## Breakpoint semantic gate

```text
MOBILE_LANDSCAPE_WIDTH_PROVEN=NO
QUERY_SEMANTICS_PROVEN=NO
MEDIA_CONDITION_PROVEN=NO
ENABLED_STATE_PROVEN=NO
CASCADE_ORDER_PROVEN=NO
BREAKPOINT_AUTHORITY_EVIDENCE_COMPLETE=NO
AUTHORITY_CREATION_READY=NO
```

Candidate values are not recorded because the evidence is incomplete. In
particular, this preflight does not nominate `767px`, `max-width`, or a cascade
ordinal for Milan.

## Missing evidence register

| Gap | Classification | Minimum additional evidence |
| --- | --- | --- |
| Source environment | `MISSING_SOURCE_ENVIRONMENT` | A source-site identity, such as site/domain or environment ID, with a cryptographic or structural link to the exact Milan export hash. |
| Bricks runtime version | `MISSING_VERSION_IDENTITY` | An explicit Bricks runtime version from that same linked environment. A nested `_version` field is not enough unless the source schema defines it as the runtime version. |
| Custom breakpoint state | `MISSING_CUSTOM_BREAKPOINT_STATE` | The source environment's exact breakpoint settings or a source-backed proof that custom breakpoints are absent or disabled. |
| Default fallback applicability | `MISSING_DEFAULT_FALLBACK_PROOF` | Proof that the exact Milan environment uses Bricks default breakpoint fallback, plus version-matched source/configuration evidence for the default mapping, query direction, and cascade. |
| Numeric mapping | `MISSING_NUMERIC_MAPPING` | Milan-applicable `mobile_landscape` width and unit, from direct source settings or the complete version-matched fallback path. |
| Query semantics and media condition | `MISSING_QUERY_SEMANTICS` | Milan-applicable `max-width` or `min-width` semantics and the exact matching media condition. |
| Cascade ordering and entry order | `MISSING_CASCADE_ORDER` | Milan-applicable full ordering plus the `mobile_landscape` position in that ordering. |
| Enabled state and authority classification | `OTHER` | Source proof that the breakpoint is enabled, plus a later authority decision for `authority_level`, `authority_type`, and accepted status. |

`CONFLICTING_EVIDENCE=NONE`. The Hero India values and the unrelated Bricks
fixture are scoped references, not conflicting Milan observations.

## Runtime and lifecycle restrictions

```text
DATA_LAYER=COLD_COMPILE_REVIEW_TIME
ETS=N/A
CACHEX=N/A
REDIS=N/A
POSTGRES=N/A
PGBouncer=N/A
READ_REPLICA=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
TTL=N/A
DB_INDEX=N/A
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0

BREAKPOINT_AUTHORITY_JSON_CREATED=NO
BREAKPOINT_AUTHORITY_ACCEPTED=NO
RESOLVED_DESIGN_DOCUMENT_CREATED=NO
RESOLVED_DESIGN_DOCUMENT_IDENTITY_FROZEN=NO
POST_RESOLUTION_BEHAVIOR_REISSUED=NO
A1_SEMANTIC_INPUT_FROZEN=NO
REAL_MILAN_D0_EXECUTED=NO
COMPONENT_PROPOSER_EXECUTED=NO
```

## Decision and next gate

The supplied Milan evidence does not prove enough to create an accepted
`BreakpointAuthority`. The only Milan-specific breakpoint fact established is
the unresolved source name `mobile_landscape`. Numeric width, unit, query
direction, media condition, enabled state, custom/default state, and cascade
remain unproven. The matching Hero India name and `767px` value do not change
that result.

```text
PREFLIGHT_REVIEW_READY=YES
NEXT_REQUIRED_GATE=
Obtain the exact missing Milan source-environment evidence listed above. Do
not create breakpoint authority until that evidence exists.
```
