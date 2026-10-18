# C09D7-C2D2 CTA library capability evidence review

**Decision: BLOCKED**

This review asks whether accepted evidence supports a future
`distribution.library.status=supported` claim for the CTA Catalogue item. The
review does not add a distribution field, change the manifest, or authorize a
release or package publication.

## Frozen review target

```text
BASE_SHA=7d905f67575fab3aa22e3ed2e9eb53a75f2b2c53
BASE_TREE=67a185cc558a8eafc0248cbba061449847d52315
BASE_CI=39098261911
BASE_CI_RESULT=PASS

C2D1_MERGE_SHA=6f0d1c034b45e1ff2087f55c7baf1a23b2b1d181
C2D1_MERGE_TREE=7ccbcc983b1c2539a85a04021ad75f829a6bb4a6
C2D1_POST_MERGE_CI=39098250874
C2D1_POST_MERGE_CI_RESULT=PASS

CATALOGUE_ID=live_frames.section.media_call_to_action
CATALOGUE_STATE=APPROVED
CONTRACT_FINGERPRINT=14550b34d1d8820ffdddd59e0e354d89e8a6a043eced8dc5afe472a5dc2ec05b

CAPABILITY=library
PROPOSED_STATUS=supported
CURRENT_DISTRIBUTION_FIELD=ABSENT
```

The current manifest at
`apps/live_frames/priv/catalogue/sections/media_call_to_action.json` has the
recorded ID, `APPROVED` state, and fingerprint. It has no `distribution` key.

## Authority applied

C2D0 §5 requires evidence for implementation, tests, documentation, and the
compatibility contract. C2D0 §4 says the validator checks claim shape and
reference integrity only. `VALID_SHAPE` is not `CAPABILITY_EVIDENCE_ACCEPTED`.
Catalogue architecture §10 repeats the four evidence requirements. Docs/16 and
Catalogue architecture §11 establish the package requirement: when
`priv/catalogue/` exists, the `:live_frames` source package must include that
canonical tree.

The C1 authority limits C1 to a local path dependency on the exact LiveFrames
application. It says C1 does not prove package-boundary behavior or
`distribution.library=supported`. Its accepted version record proves only the
resolved versions used in that run, not a wider compatibility range.

The current authority matches these requirements. No authority change was
found.

## Findings

### Implementation

```text
CTA_COMPONENT_IMPLEMENTATION_PRESENT=YES
CTA_SOURCE_CSS_PRESENT=YES
CTA_PRECOMPILED_CSS_PRESENT=YES

PRIV_CATALOGUE_TREE_PRESENT=YES
PRIV_CATALOGUE_INCLUDED_IN_PACKAGE_FILES=NO
```

The component is present in
`apps/live_frames/lib/live_frames/components/sections/media_call_to_action.ex`.
Its source stylesheet is present at
`apps/live_frames/assets/css/components/sections/media_call_to_action.css`, and
`apps/live_frames/assets/css/live_frames.css` imports it. The committed
precompiled stylesheet contains the CTA selectors at
`apps/live_frames/priv/static/live_frames/css/live_frames.css`.

The current package file list in `apps/live_frames/mix.exs:24-27` is
`lib mix.exs assets/css priv/token_maps priv/static/live_frames`. It excludes
`priv/catalogue`, although the tree contains the production CTA manifest.
Docs/16 §1 and Catalogue architecture §11 require that tree in the source
package whenever it exists. A consumer package built from the current list can
therefore omit the canonical CTA Catalogue source.

```text
IMPLEMENTATION_CRITERION=BLOCKED
```

The CTA module and CSS artifacts exist, but the package configuration does not
meet the documented package requirement for the current Catalogue tree.

### Tests

The focused tests ran against the exact frozen source. The fresh worktree had no
local dependency directory, so the runs reused the existing C2D1 dependency
tree through `MIX_DEPS_PATH`. No dependencies were fetched or changed.

```text
FOCUSED_COMPONENT_TESTS=PASS (4 tests, 0 failures)
FOCUSED_DISTRIBUTION_VALIDATOR_TESTS=PASS (16 tests, 0 failures)
FOCUSED_STORYBOOK_TESTS=PASS (3 tests, 0 failures)
```

The accepted C1 external consumer record reports 6 tests and 0 failures. It
used `LOCAL_PATH_TO_EXACT_LIVE_FRAMES_APP`, rendered the CTA, and served the
precompiled CSS. C1 explicitly records:

```text
C1_OUTCOME=PASS
C1_PACKAGE_BOUNDARY_PROVEN=NO
C1_DISTRIBUTION_LIBRARY_SUPPORTED=NO
HEX_PUBLICATION_PROVEN=NO
```

The C1 source `mix.exs` and precompiled CSS have the same SHA-256 values as the
current files. The CTA component changed only by adding its persisted public
contract metadata block; its function body and public API did not change. The
current component test also passes. C1 still supports use of the current
source-path API. It does not provide package-boundary evidence.

```text
TESTS_CRITERION=PASS
```

The tests cover component behavior, Storybook rendering, and validator
structure. They do not prove that the actual built package contains the
canonical Catalogue tree.

### Package-boundary question

```text
C1_EXTERNAL_CONSUMER_RESULT=PASS
C1_DEPENDENCY_MODE=LOCAL_PATH_TO_EXACT_LIVE_FRAMES_APP
C1_PACKAGE_BOUNDARY_PROVEN=NO
C1_DISTRIBUTION_LIBRARY_SUPPORTED=NO

PR98_STATE=CLOSED
PR98_MERGED=NO
PR98_ACCEPTED_EVIDENCE=NO

PACKAGE_BOUNDARY_EVIDENCE_ACCEPTED=NO
```

PR #98 (`Catalogue #51A package boundary`) is closed with no merge commit. Its
branch results are not accepted evidence. The current `mix.exs` file list is
configuration evidence only. C1 explicitly used a path dependency and declined
to prove the package boundary. No later accepted current-main evidence closes
this gap.

### Documentation

```text
DOCUMENTATION_INTEGRATION_GUIDANCE_PRESENT=YES
DOCUMENTATION_CURRENT_TRUTH_ACCURATE=NO
```

Docs/16 contains the CTA function API and its CSS requirement. Several
current-facing status statements no longer match accepted current-main state:

- `README.md:65-71` says a clean external CTA consumer has not been proven,
  Catalogue production content is absent, and the C09D7-C handoff is unproven.
  C1 is accepted, and the production CTA manifest exists.
- `docs/16_PACKAGE_AND_GENERATOR_MODEL.md:32-35,49` says production Catalogue
  content and the `priv/catalogue/` directory are absent.
- `docs/16_PACKAGE_AND_GENERATOR_MODEL.md:91-93,313-318,347-350` says the clean
  external CTA consumer boundary has not been established. The C1 source path
  consumer proof is accepted.
- `docs/17_ROADMAP.md:5-12,23-32` carries an older main checkpoint and says C1
  handoff proof and production Catalogue content are absent.
- `docs/11_CSS_AND_TAILWIND_STRATEGY.md:63-71` lists the source CSS composition
  without CTA, while `apps/live_frames/assets/css/live_frames.css:7` imports
  the CTA stylesheet.

The integration instructions are present. The current-facing status is stale,
so a reader cannot use those statements to determine the accepted state
accurately.

```text
DOCUMENTATION_CRITERION=BLOCKED
STALE_CURRENT_FACING_DOCS=README.md; docs/16_PACKAGE_AND_GENERATOR_MODEL.md; docs/17_ROADMAP.md; docs/11_CSS_AND_TAILWIND_STRATEGY.md
```

### Compatibility contract

The current declaration in `apps/live_frames/mix.exs:8-14` is:

```text
ELIXIR_REQUIREMENT=~> 1.19
PHOENIX_LIVE_VIEW_REQUIREMENT=~> 1.2.11
COMPATIBILITY_CONTRACT_DECLARED=YES
```

C1 records Elixir `1.19.3`, Phoenix `1.8.15`, and Phoenix LiveView `1.2.12`.
The recorded Elixir and LiveView versions fall within the current declared
constraints. The dependency declaration and the C1 run apply to the same
`mix.exs` content.

```text
COMPATIBILITY_EXAMPLE_PROVEN=YES
COMPATIBILITY_RANGE_PROVEN=NO
COMPATIBILITY_CONTRACT_CRITERION=PASS
```

C2D0 §5 and Catalogue architecture §10 require a compatibility contract. The
reviewed authority does not specify a matrix covering every version admitted by
the declared constraints. C1 authority §§5 and 7 limits its proof to the exact
versions recorded and explicitly rejects a broader range inference. This
review accepts the declared contract and the accepted in-range example without
claiming that the full range has been tested.

## Structural candidate probe

The candidate below was constructed in memory as a `LiveFrames.Catalogue.Manifest`
and passed to `LiveFrames.Catalogue.DistributionCapability.validate/1`. It was
not written to the CTA manifest.

```json
{
  "library": {
    "status": "supported",
    "evidence_refs": ["synthetic-review-ref"]
  }
}
```

The initial `mix run` attempted to start the preview endpoint and found port
4000 occupied. The probe then ran with `MIX_ENV=test mix run --no-start` and
returned `:ok`.

```text
PROPOSED_LIBRARY_CLAIM_SHAPE=PASS
EVIDENCE_SUFFICIENCY_FROM_VALIDATOR=NO
```

The result establishes structural validity only. It does not establish that the
synthetic reference or any current evidence is sufficient for library support.

## Decision and next evidence order

```text
IMPLEMENTATION_CRITERION=BLOCKED
TESTS_CRITERION=PASS
DOCUMENTATION_CRITERION=BLOCKED
COMPATIBILITY_CONTRACT_CRITERION=PASS

LIBRARY_CAPABILITY_EVIDENCE_REVIEW=BLOCKED

PACKAGE_BOUNDARY_REMEDIATION_REQUIRED=YES
CURRENT_DOC_TRUTH_REMEDIATION_REQUIRED=YES
COMPATIBILITY_EVIDENCE_REMEDIATION_REQUIRED=NO
```

The package requirement and current-facing documentation gaps prevent an
accepted `distribution.library=supported` claim. The next evidence work should
proceed in this order:

1. Resolve and verify the package boundary for the existing canonical
   `priv/catalogue/` tree.
2. Update current-facing package and consumer status documentation to match
   accepted evidence.
3. Repeat the library capability evidence review against the resulting accepted
   main state.
4. Only after an `ACCEPTED` review, consider a separate authorized manifest
   mutation.

This review performs none of those remediation or mutation steps.

```text
CANDIDATE_EVIDENCE_INSPECTED=
  apps/live_frames/lib/live_frames/components/sections/media_call_to_action.ex
  apps/live_frames/assets/css/components/sections/media_call_to_action.css
  apps/live_frames/assets/css/live_frames.css
  apps/live_frames/priv/static/live_frames/css/live_frames.css
  apps/live_frames/mix.exs
  apps/live_frames/priv/catalogue/sections/media_call_to_action.json
  apps/live_frames/test/live_frames/components/sections/media_call_to_action_test.exs
  apps/live_frames_preview/test/live_frames_preview_web/native_cta_storybook_test.exs
  apps/live_frames/lib/live_frames/catalogue/distribution_capability.ex
  apps/live_frames/test/live_frames/catalogue/distribution_capability_test.exs
  README.md
  docs/11_CSS_AND_TAILWIND_STRATEGY.md
  docs/16_PACKAGE_AND_GENERATOR_MODEL.md
  docs/17_ROADMAP.md
  docs/23_CATALOGUE_ARCHITECTURE.md
  docs/24_CATALOGUE_VERSIONING_POLICY.md
  docs/development/c09d7c2d0_catalogue_distribution_capability_contract.md
  docs/development/c09d7c_external_consumer_catalogue_handoff_authority.md
  docs/development/c09d7c1_external_consumer_proof.md
  docs/development/c09d7c2r0_cta_catalogue_review_evidence.md

ACCEPTED_LIBRARY_EVIDENCE_REFS=[]
```

## Scope and authorization

```text
CTA_MANIFEST_MUTATED=NO
CTA_DISTRIBUTION_FIELD_PRESENT=NO
CTA_LIBRARY_SUPPORTED_CLAIM_PERSISTED=NO

PROVENANCE_MUTATED=NO
RELEASE_TRANSITION_EXECUTED=NO

C09D7_C2D3_AUTHORIZED=NO
CTA_LIBRARY_SUPPORTED_CLAIM_AUTHORIZED=NO
APPROVED_TO_RELEASED_AUTHORIZED=NO
CATALOGUE_RELEASE_AUTHORIZED=NO
PACKAGE_PUBLICATION_AUTHORIZED=NO
P10_AUTHORIZED=NO
```

## Performance and scaling

```text
DATA_LAYER=REPOSITORY_EVIDENCE_REVIEW
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

```text
STOP=AWAIT_C2D2_INDEPENDENT_REVIEW
```
