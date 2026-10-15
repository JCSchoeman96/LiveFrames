# C09D7-C2O0 CTA Catalogue owner approval evidence

This document records durable owner approval evidence for a later Catalogue `approve` transition. It records the owner's decision and its exact target. It does not execute the transition.

## Approval boundary

```text
APPROVAL_DATE=2026-10-15

BASE_SHA=c22c35e0f90e4dd54d22104ffa5b8c1a64e36c83
BASE_TREE=fa3a95d042979f2cc8b56fb44eabe819b7dfca7f
BASE_CI=38700519867
BASE_CI_RESULT=PASS

CATALOGUE_ID=live_frames.section.media_call_to_action
CATALOGUE_STATE=REVIEWED

CANONICAL_PATH=
apps/live_frames/priv/catalogue/sections/media_call_to_action.json

REVIEWED_MANIFEST_SHA256=
2308b2592fd858f62765f5c732fab70cceedea1f6b80b95fdc9829023df6ded3

CONTRACT_FINGERPRINT_ALGORITHM=
lf-contract-v1-jcs-sha256

CONTRACT_FINGERPRINT=
14550b34d1d8820ffdddd59e0e354d89e8a6a043eced8dc5afe472a5dc2ec05b

INDEPENDENT_REVIEW_EVIDENCE=
docs/development/c09d7c2r0_cta_catalogue_review_evidence.md

C2R1_MERGE_SHA=
cbc9334bc28f41b5c984582e41930bcdc84be605
```

The accepted lifecycle contract defines `approve` as `REVIEWED -> APPROVED`, guarded by owner approval evidence. `APPROVED` records owner approval for eventual Catalogue release. It does not grant publication or redistribution clearance.

## Exact owner approval statement

> I approve Catalogue item `live_frames.section.media_call_to_action`, currently in `REVIEWED` state with contract fingerprint `14550b34d1d8820ffdddd59e0e354d89e8a6a043eced8dc5afe472a5dc2ec05b`, for eventual Catalogue release and authorize the `REVIEWED -> APPROVED` approval workflow.
>
> This approval does **not** grant redistribution or publication clearance, does **not** authorize the `APPROVED -> RELEASED` transition, does **not** authorize package publication, and does **not** authorize P10.

## Normalized approval record

```text
OWNER_APPROVAL_DECISION=APPROVE

OWNER_APPROVAL_ITEM_ID=
live_frames.section.media_call_to_action

OWNER_APPROVAL_ITEM_STATE=REVIEWED

OWNER_APPROVAL_CONTRACT_FINGERPRINT_ALGORITHM=
lf-contract-v1-jcs-sha256

OWNER_APPROVAL_CONTRACT_FINGERPRINT=
14550b34d1d8820ffdddd59e0e354d89e8a6a043eced8dc5afe472a5dc2ec05b

OWNER_APPROVAL_PURPOSE=
eventual Catalogue release

REVIEWED_TO_APPROVED_WORKFLOW_AUTHORIZED=YES
```

## Explicit non-authorizations

```text
REDISTRIBUTION_CLEARANCE_ESTABLISHED=NO
PUBLICATION_CLEARANCE_ESTABLISHED=NO

APPROVED_TO_RELEASED_AUTHORIZED=NO
CATALOGUE_RELEASE_AUTHORIZED=NO

PACKAGE_PUBLICATION_AUTHORIZED=NO
P10_AUTHORIZED=NO
```

The separate provenance authority remains unresolved for release clearance. This document does not modify that authority or establish clearance.

## Transition boundary

```text
CATALOGUE_STATE_BEFORE=REVIEWED
CATALOGUE_STATE_AFTER=REVIEWED

APPROVE_TRANSITION_EXECUTED=NO
LIFECYCLE_MANIFEST_MUTATED=NO

NEXT_PERMITTED_WORKFLOW=
separate C2O1 REVIEWED -> APPROVED transition after this evidence is merged and independently accepted
```

## Performance and scaling review

```text
DATA_LAYER=DOCUMENTATION_AND_OWNER_AUTHORITY
RUNTIME_EFFECT=NONE

HOT_DATA=N/A
WARM_DATA=N/A
COLD_DATA=REPOSITORY_DOCUMENT

POSTGRES=N/A
REDIS=N/A
ETS=N/A
CACHEX=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
PGBouncer=N/A
READ_REPLICA=N/A

REQUIRED_INDEXES=N/A
CACHE_TTL=N/A
CACHE_INVALIDATION=N/A
REDIS_STRUCTURE=N/A
PUBSUB_BROADCAST=N/A

RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
RUNTIME_POLLING=0
100K_CONCURRENT_USERS=N/A
```

## Verification record

The current manifest decoded with `LiveFrames.Catalogue.Manifest.decode/1`. The real identity and lifecycle snapshot validators returned `:ok`. Fingerprint computation returned the algorithm and fingerprint recorded above, and `LiveFrames.Catalogue.Fingerprint.verify/3` returned `:ok` for the production CTA component. The independent C2R0 evidence records `INDEPENDENT_CATALOGUE_REVIEW=PASS`, the same Catalogue ID and fingerprint, and `REVIEW_RECOMMENDATION=ADVANCE_TO_REVIEWED`.

```text
PRIVATE_SOURCE_RECONSTRUCTION_EXECUTED=NO
PRIVATE_R3_R5_REPROOF_REQUIRED=NO
```
