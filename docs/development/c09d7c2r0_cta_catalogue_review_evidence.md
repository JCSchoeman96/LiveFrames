# C09D7-C2R0 CTA Catalogue review evidence

## Review boundary

This independent review was run from a fresh worktree at the accepted `main` base. The reviewer recomputed each result from that tree. C2V1 conclusions were not used as evidence. The review records the current validated Catalogue item and recommends a later review transition. It does not execute that transition or grant owner or release approval.

```text
REVIEW_DATE=2026-10-15
BASE_SHA=7e2b1b5bb82f9da8425724a2f68b638883339aa0
BASE_TREE=a95aa627f752bf85bd91303b6a1a50c004606a87
BASE_CI=38684535929
BASE_CI_RESULT=PASS

CATALOGUE_ID=live_frames.section.media_call_to_action
CANONICAL_PATH=apps/live_frames/priv/catalogue/sections/media_call_to_action.json
VALIDATED_MANIFEST_SHA256=d41873f5720b4360d60b423cb439763dd30849efc90110dca6f45f65f67d8156
CATALOGUE_STATE=VALIDATED

COMPONENT_MODULE=LiveFrames.Components.Sections.MediaCallToAction
COMPONENT_FUNCTION=media_call_to_action

FINGERPRINT_ALGORITHM=lf-contract-v1-jcs-sha256
FINGERPRINT=14550b34d1d8820ffdddd59e0e354d89e8a6a043eced8dc5afe472a5dc2ec05b

STORYBOOK_MODULE=LiveFramesPreviewWeb.Storybook.Components.MediaCallToAction
DEFAULT_VARIATION=:default
STORYBOOK_ROUTE=/storybook/components/media_call_to_action

PROVENANCE_AUTHORITY=docs/04_SOURCE_AND_PROVENANCE.md
PROVENANCE_SOURCE_GROUP=Bricks copied-elements export / CTA Tango
```

The base was `origin/main` when the review worktree was created. Its SHA and tree matched the supplied values. The worktree was clean before review. No open PRs were listed at preflight, so no competing Catalogue or CTA lifecycle change was present.

## Manifest identity and lifecycle

The real `LiveFrames.Catalogue.Manifest.decode/1` decoder decoded the manifest. The decoded values were:

```text
schema_version=1
id=live_frames.section.media_call_to_action
kind=section
display_name=Media Call to Action
state=VALIDATED

component.module=LiveFrames.Components.Sections.MediaCallToAction
component.function=media_call_to_action
storybook.module=LiveFramesPreviewWeb.Storybook.Components.MediaCallToAction

lifecycle.last_transition.action=validate
lifecycle.last_transition.from=DRAFT
lifecycle.last_transition.to=VALIDATED
```

The real identity and lifecycle validators returned `:ok`:

```text
Identity.canonical_path=apps/live_frames/priv/catalogue/sections/media_call_to_action.json
Identity.validate=PASS
Lifecycle.validate_snapshot=PASS
```

The raw decoded JSON has no `distribution` or `release` key. The manifest was not changed during review.

```text
DISTRIBUTION_FIELD_PRESENT=NO
RELEASE_FIELD_PRESENT=NO
```

## Current production contract

The reviewer called `LiveFrames.Catalogue.Fingerprint.compute/2` against the current production export. It returned the persisted algorithm and digest. `Fingerprint.verify/3` returned `:ok`.

```text
FINGERPRINT_COMPUTE=PASS
FINGERPRINT_VERIFY=PASS
FINGERPRINT_ALGORITHM=lf-contract-v1-jcs-sha256
FINGERPRINT=14550b34d1d8820ffdddd59e0e354d89e8a6a043eced8dc5afe472a5dc2ec05b
```

`LiveFrames.Catalogue.Contract.Reflection.read/2` reflected the production export:

```text
PUBLIC_ATTR_COUNT=11
PUBLIC_SLOT_COUNT=2

CAPABILITY_COUNT=4
CSS_THEME_CONTRACT_COUNT=22
GLOBAL_PREFIXES_EMPTY=YES

BODY_CARDINALITY=0..1
PRIMARY_ACTION_CARDINALITY=1..1

HEADING_LEVEL_DEFAULT=2
HEADING_LEVEL_ALLOWED=1..6
```

The reflected API and metadata matched those values. No component or metadata changes were made.

## Storybook reference and render

The Storybook module resolved, and `LiveFrames.Catalogue.StorybookReference.validate/2` returned `:ok`. Its `function/0` returned exactly `&LiveFrames.Components.Sections.MediaCallToAction.media_call_to_action/1`.

The trusted variation IDs were `:default`, `:without_body`, and `:heading_level_variant`, in that order. They had no duplicates, and exactly one `:default` variation existed.

The real CTA regression was run with:

```text
mix test apps/live_frames_preview/test/live_frames_preview_web/native_cta_storybook_test.exs
```

It completed with 3 tests and 0 failures. Its Phoenix route request to `/storybook/components/media_call_to_action` returned HTTP 200. The response assertions found the production CTA heading and `lf-section-media-call-to-action` class.

The test environment logged that the Storybook CSS and JavaScript bundles were not built. This review did not run the asset generation task. The required route and server-rendered production CTA assertions passed.

```text
STORYBOOK_REFERENCE_VALIDATE=PASS
STORYBOOK_TARGET_VALIDATE=PASS
DEFAULT_VARIATION_PRESENT=YES
DEFAULT_RENDER_VALIDATE=PASS
STORYBOOK_ROUTE=/storybook/components/media_call_to_action
HTTP_STATUS=200
PRODUCTION_CTA_RENDERED=YES
```

## Documentation references

All three current manifest documentation references resolved to files:

```text
docs/development/c09d7a_cta_tango_component_review.md
docs/development/c09d7b_cta_tango_ir4_reauthorization.md
docs/development/c09d7c1_external_consumer_proof.md
```

These are historical or supporting evidence. The A3 component review concerns the earlier ComponentContract review. The C1 record concerns an external Phoenix consumer and explicitly does not prove Catalogue reflection compatibility. Neither record proves the exact current component bytes after C2V0.

```text
C1_ACCEPTED_HISTORICAL_EVIDENCE=YES
C1_EXACT_CURRENT_COMPONENT_BYTE_PROOF=NO
DOCUMENTATION_REFERENCES_RESOLVED=YES
```

## Provenance and clearance

The manifest's structured provenance reference resolved against the CTA Tango entry in `docs/04_SOURCE_AND_PROVENANCE.md`. The authority record declares:

```text
source_group=Bricks copied-elements export / CTA Tango
authority=docs/04_SOURCE_AND_PROVENANCE.md
evidence_refs=
  docs/development/c09d7a_cta_tango_semantic_input_freeze.md
  docs/development/c09d7a_cta_tango_component_review.md

redistribution_status=unknown
publication_state=classified
clearance_evidence_refs=[]
```

The evidence references resolve, and `LiveFrames.Catalogue.ProvenanceReference.validate/2` returned `:ok`. The reviewer did not call `ProvenanceReference.release_clearance/2`. The review establishes neither redistribution nor publication clearance.

```text
PROVENANCE_REFERENCE_VALIDATE=PASS
PROVENANCE_RELEASE_CLEARANCE_EXECUTED=NO
REDISTRIBUTION_CLEARANCE_ESTABLISHED=NO
PUBLICATION_CLEARANCE_ESTABLISHED=NO
```

## Registry and public discovery

`LiveFrames.Catalogue.Registry.Builder.build/1` returned `{:ok, manifests}`. The built registry contained one item with this Catalogue ID, and its state was `VALIDATED`.

The public discovery API returned `:error` for `LiveFrames.Catalogue.fetch/1`. `LiveFrames.Catalogue.list/0` did not include the item.

```text
REGISTRY_BUILD=PASS
REGISTRY_ITEM_COUNT=1
REGISTRY_CTA_MATCH_COUNT=1
REGISTRY_ITEM_STATE=VALIDATED

PUBLIC_FETCH_RESULT=:error
PUBLIC_LIST_EXPOSES_ITEM=NO
```

## Review questions

| # | Question | Result | Evidence |
| --- | --- | --- | --- |
| 1 | Does the immutable ID match the kind and canonical path? | YES, PASS | `Identity.validate/2` passed for the canonical section path. |
| 2 | Is the persisted manifest a valid `VALIDATED` lifecycle snapshot? | YES, PASS | The real decoder and `Lifecycle.validate_snapshot/1` passed. The last transition is `validate / DRAFT -> VALIDATED`. |
| 3 | Does the persisted fingerprint match the current production export? | YES, PASS | Compute returned the persisted digest, and verify returned `:ok`. |
| 4 | Does current reflection describe the accepted public API? | YES, PASS | Reflection returned 11 attributes, 2 slots, 4 capabilities, 22 CSS theme entries, no global prefixes, and the recorded cardinalities and heading level. |
| 5 | Does Storybook target the exact production export? | YES, PASS | Reference validation passed, and `function/0` matched the production export exactly. |
| 6 | Does an exact `:default` variation exist and render successfully? | YES, PASS | One exact default exists. The real route test returned 200 and asserted production CTA markup. |
| 7 | Do all manifest documentation references resolve? | YES, PASS | All three paths resolve to files. |
| 8 | Do all structured provenance references resolve? | YES, PASS | The provenance validator passed against the current authority record and its evidence paths. |
| 9 | Is redistribution and release clearance correctly not claimed? | YES, PASS | Redistribution remains `unknown`; publication remains `classified`; clearance refs are empty. No release-clearance function was called. |
| 10 | Are distribution and release fields absent? | YES, PASS | Neither key is present in the raw decoded manifest. |
| 11 | Is the item hidden from public discovery? | YES, PASS | Public fetch returned `:error`, and public listing omitted the item. |
| 12 | Is there an unresolved defect that should prevent human review acceptance? | NO, PASS | No defect was found in these checks. Clearance remains unresolved by design and is not represented as established. |

## Review result

```text
INDEPENDENT_CATALOGUE_REVIEW=PASS
REVIEWED_ITEM_ID=live_frames.section.media_call_to_action

REVIEWED_CONTRACT_ALGORITHM=lf-contract-v1-jcs-sha256
REVIEWED_CONTRACT_FINGERPRINT=14550b34d1d8820ffdddd59e0e354d89e8a6a043eced8dc5afe472a5dc2ec05b

REVIEW_RECOMMENDATION=ADVANCE_TO_REVIEWED

CATALOGUE_STATE_BEFORE=VALIDATED
CATALOGUE_STATE_AFTER=VALIDATED

REVIEW_TRANSITION_EXECUTED=NO
OWNER_APPROVAL_RECORDED=NO
RELEASE_CLEARANCE_ESTABLISHED=NO
CATALOGUE_RELEASE_AUTHORIZED=NO
P10_AUTHORIZED=NO
```

This record is independent review evidence. It is not owner approval, release approval, redistribution clearance, or an executed Catalogue lifecycle transition.

## Scope and runtime classification

```text
REVIEW_EVIDENCE_DOCUMENT=docs/development/c09d7c2r0_cta_catalogue_review_evidence.md

PRIVATE_SOURCE_RECONSTRUCTION_EXECUTED=NO
PRIVATE_R3_R5_REPROOF_REQUIRED=NO

DATA_LAYER=DOCUMENTATION_AND_REVIEW_EVIDENCE
RUNTIME_EFFECT=NONE

POSTGRES=N/A
REDIS=N/A
ETS=N/A
CACHEX=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
PGBouncer=N/A
READ_REPLICA=N/A

RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
RUNTIME_POLLING=0
```
