# C09D7-C2D2R1 CTA library capability evidence review

**Decision: ACCEPTED**

This review evaluates whether the accepted evidence supports a future
`distribution.library.status=supported` claim for the CTA Catalogue item. It
does not add that claim to the manifest or authorize a later capability
mutation, release, or package publication.

## Frozen review target

```text
BASE_SHA=4d0388606831562dc1b344a2bbf2e1169af52c42
BASE_TREE=7bed181b96aabbe2afeed23a4f57d0d31e998082
BASE_CI=39136743693
BASE_CI_RESULT=PASS

CATALOGUE_ID=live_frames.section.media_call_to_action
CATALOGUE_STATE=APPROVED
CONTRACT_FINGERPRINT=14550b34d1d8820ffdddd59e0e354d89e8a6a043eced8dc5afe472a5dc2ec05b

CAPABILITY=library
PROPOSED_STATUS=supported
CURRENT_DISTRIBUTION_FIELD=ABSENT
```

At the frozen base, the canonical manifest at
`apps/live_frames/priv/catalogue/sections/media_call_to_action.json` has the
recorded ID, state, and 64-character contract fingerprint. It has no
`distribution` key.

The proposed future evidence reference is exactly:

```text
docs/development/c09d7c2d2r1_cta_library_capability_evidence_review.md
```

## Authority applied

C2D0 §§2, 4, and 5 require separate accepted evidence for implementation,
tests, documentation, and the compatibility contract. The distribution
validator owns only structural validation and reference integrity. Its
acceptance of a structurally valid object cannot establish substantive
capability evidence:

```text
VALID_SHAPE
!=
CAPABILITY_EVIDENCE_ACCEPTED
```

Catalogue architecture §§8.4, 10, and 11 keep distribution claims separate
from normalized component capabilities and provenance, require the four
evidence classes for a supported capability, and define the package boundary.
The versioning policy keeps Catalogue release, package publication, and
Catalogue item SemVer separate.

The accepted C1 proof is limited to a clean Phoenix consumer using a local
path dependency to the exact LiveFrames application. It establishes one
source-path consumer example, not package-boundary proof, Hex publication,
`distribution.library=supported`, Catalogue release, or P10.

The original C2D2 review remains a truthful historical `BLOCKED` result at its
frozen base. This review does not edit or replace that history. C2D2A package
boundary remediation and C2D2B current-facing documentation remediation are
reviewed here as accepted evidence on the frozen current base.

```text
C2D2B_PR=250
C2D2B_REVIEWED_HEAD=1c4762b223b72a0dffb19710e88f67373ab314ea
C2D2B_MERGE_SHA=95965eb11b2c63d59dd4a8721c996fcdb50cc577
C2D2B_MERGE_TREE=d997b97db8788137c734df4f730ef5aa77861f52
C2D2B_POST_MERGE_CI=39136727257
C2D2B_POST_MERGE_CI_RESULT=PASS
```

The frozen `main` base also includes the unrelated accepted PR #251 CSS
authority update and PR #252 ComponentizationPlan update. Neither changed the
CTA Catalogue, CTA distribution, package boundary, or C2D2B documentation.

## Criterion A: implementation evidence

The CTA function component is present at
`apps/live_frames/lib/live_frames/components/sections/media_call_to_action.ex`.
Its source stylesheet exists at
`apps/live_frames/assets/css/components/sections/media_call_to_action.css` and
`apps/live_frames/assets/css/live_frames.css` imports it. The committed
precompiled artifact at
`apps/live_frames/priv/static/live_frames/css/live_frames.css` contains the
CTA selector family.

The canonical `priv/catalogue/` tree exists and contains the CTA manifest.
`apps/live_frames/mix.exs` package files include all required roots and files:

```text
lib
mix.exs
assets/css
priv/token_maps
priv/static/live_frames
priv/catalogue
LICENSE-PROPRIETARY.txt
```

The proprietary notice exists and is included in the package file list. The
package configuration is backed by the accepted C2D2A implementation, not
configuration inspection alone:

```text
C2D2A_PR=248
C2D2A_PR_STATE=MERGED
C2D2A_REVIEWED_HEAD=1afd51a7abb8f9ceb11b5d356ad003472d87b358
C2D2A_MERGE_SHA=9967642fd6ed5c8ab9425f3cc409b2e30da71358
C2D2A_PR_CI=39126353218
C2D2A_PR_CI_RESULT=PASS
```

The accepted change updates `.github/workflows/ci.yml` to run the real
`mix hex.build --unpack --output <temporary-directory>` command, then inspect
the unpacked package. The verifier checks required package directories, the
CTA source and precompiled CSS files, every canonical Catalogue JSON file by
byte comparison, the proprietary notice by byte comparison, and absence of
preview-app files. It also removes the temporary output and checks that no
synthetic probe remains.

The exact package-verification step passed on the frozen current-main CI run:

```text
PACKAGE_BOUNDARY_IMPLEMENTATION_PRESENT=YES
PACKAGE_BOUNDARY_CI_PRESENT=YES
PACKAGE_BOUNDARY_CURRENT_MAIN_CI=PASS
PACKAGE_BOUNDARY_CURRENT_MAIN_CI_RUN=39136743693
HEX_BUILD_UNPACK=PASS
SYNTHETIC_PROBE_USED=NO
CANONICAL_CATALOGUE_JSON_COUNT=1
PACKAGED_CATALOGUE_PRESENT=YES
PACKAGED_CTA_MANIFEST_PRESENT=YES
PACKAGED_CTA_MANIFEST_BYTE_IDENTICAL=YES
ALL_CANONICAL_CATALOGUE_JSON_PRESENT=YES
ALL_CANONICAL_CATALOGUE_JSON_BYTE_IDENTICAL=YES
PACKAGED_PROPRIETARY_NOTICE_PRESENT=YES
PACKAGED_PROPRIETARY_NOTICE_BYTE_IDENTICAL=YES
PACKAGED_CTA_SOURCE_CSS_PRESENT=YES
PACKAGED_CTA_PRECOMPILED_CSS_PRESENT=YES
PACKAGED_PREVIEW_PRESENT=NO
GENERATED_PACKAGE_ARTIFACT_REMAINS=NO
SYNTHETIC_PROBE_REMAINS=NO
PACKAGE_BOUNDARY_EVIDENCE_ACCEPTED=YES
```

The accepted verifier is embedded in the GitHub Actions workflow; the
repository has no standalone local verifier script. The current-main CI log
shows the real package build, unpack, content assertions, byte comparisons,
and cleanup all passed. No local copy of that verifier was created.

```text
CTA_COMPONENT_IMPLEMENTATION_PRESENT=YES
CTA_SOURCE_CSS_PRESENT=YES
CTA_SOURCE_CSS_IMPORTED=YES
CTA_PRECOMPILED_CSS_PRESENT=YES

PRIV_CATALOGUE_TREE_PRESENT=YES
PRIV_CATALOGUE_INCLUDED_IN_PACKAGE_FILES=YES
PROPRIETARY_LICENSE_INCLUDED_IN_PACKAGE_FILES=YES

IMPLEMENTATION_CRITERION=PASS
```

The component, source CSS, precompiled CSS, and actual package boundary required
for library consumption are evidenced on the frozen base.

## Criterion B: tests evidence

The focused tests ran against the frozen source. The existing dependency tree
from the accepted C2D2A worktree was reused through `MIX_DEPS_PATH`; its
`mix.lock` SHA-256 matched this worktree. No dependencies were fetched or
changed.

```text
FOCUSED_COMPONENT_TESTS=PASS (4 tests, 0 failures)
FOCUSED_DISTRIBUTION_VALIDATOR_TESTS=PASS (16 tests, 0 failures)
FOCUSED_STORYBOOK_TESTS=PASS (3 tests, 0 failures)
```

The preview application emitted missing Storybook CSS/JS asset warnings while
Mix compiled the umbrella during the focused component run. The focused
Storybook route test returned HTTP 200 and all three assertions passed. The
asset build was outside this review's focused test set.

The accepted C1 proof records six tests with zero failures. It used
`LOCAL_PATH_TO_EXACT_LIVE_FRAMES_APP` and establishes source-path consumer
compatibility only. It explicitly does not establish package-boundary proof,
library distribution support, or Hex publication. C2D2A supplies the separate
actual-package proof.

The package boundary was verified by the accepted current-main CI step
`Verify LiveFrames Hex package contents` in run `39136743693`. This verifier is
an inline workflow step, with no separate local script to run.

```text
C1_OUTCOME=PASS
C1_DEPENDENCY_MODE=LOCAL_PATH_TO_EXACT_LIVE_FRAMES_APP
C1_PACKAGE_BOUNDARY_PROVEN=NO
C1_DISTRIBUTION_LIBRARY_SUPPORTED=NO
HEX_PUBLICATION_PROVEN=NO

FOCUSED_PACKAGE_BOUNDARY_VERIFICATION=PASS (current-main CI run 39136743693)
TESTS_CRITERION=PASS
```

## Criterion C: documentation evidence

Current-facing documentation gives a usable CTA integration path and matches
the accepted repository state:

- `README.md` identifies the native CTA, its tests and CSS, the accepted C1
  source-path proof, the separate C2D2A package proof, the `APPROVED` Catalogue
  state, and the absent `distribution` field. It does not claim publication,
  redistribution permission, or P10 support.
- `docs/11_CSS_AND_TAILWIND_STRATEGY.md` includes
  `components/sections/media_call_to_action.css` in the current source CSS
  graph and identifies the precompiled artifact as the primary consumer path.
- `docs/16_PACKAGE_AND_GENERATOR_MODEL.md` documents the CTA API and CSS
  integration, package contents and verification, and the separate limits of
  C1, C2D2A, library support, package publication, and P10.
- `docs/17_ROADMAP.md` keeps the original C2D2 result historical, records the
  accepted C2D2A and C2D2B remediations, says C2D2R1 is a separate evidence
  review, and states that C2D3 and `APPROVED -> RELEASED` are not authorized.

Across those documents, the current facts remain distinct:

```text
C1_SOURCE_PATH_EXTERNAL_CONSUMER_PROOF=ACCEPTED
C1_PACKAGE_BOUNDARY_PROOF=NO
C2D2A_PACKAGE_BOUNDARY_PROOF=ACCEPTED
CTA_CATALOGUE_STATE=APPROVED
CTA_DISTRIBUTION_FIELD=ABSENT
DISTRIBUTION_LIBRARY_SUPPORTED=NOT_PERSISTED
C2D2R1=EVIDENCE_REVIEW_ONLY
C2D3=NOT_AUTHORIZED
HEX_OR_PUBLIC_PACKAGE_PUBLICATION=NOT_AUTHORIZED_OR_PROVEN
APPROVED_TO_RELEASED=NOT_AUTHORIZED
P10=NOT_IMPLEMENTED
```

No stale current-facing claim was found in the four required documents.

```text
DOCUMENTATION_INTEGRATION_GUIDANCE_PRESENT=YES
DOCUMENTATION_CURRENT_TRUTH_ACCURATE=YES
STALE_CURRENT_FACING_DOCS=[]
DOCUMENTATION_CRITERION=PASS
```

## Criterion D: compatibility-contract evidence

`apps/live_frames/mix.exs` declares the package compatibility constraints:

```text
ELIXIR_REQUIREMENT=~> 1.19
PHOENIX_LIVE_VIEW_REQUIREMENT=~> 1.2.11
COMPATIBILITY_CONTRACT_DECLARED=YES
```

The accepted C1 run proves one resolved example:

```text
ELIXIR=1.19.3
PHOENIX=1.8.15
PHOENIX_LIVE_VIEW=1.2.12
COMPATIBILITY_EXAMPLE_PROVEN=YES
COMPATIBILITY_RANGE_PROVEN=NO
```

C1's authority limits its result to the exact resolved versions in that run.
This review does not infer that every version allowed by the constraints has
been tested. C2D0 requires a declared compatibility contract with appropriate
supporting evidence; it does not require a matrix for every admitted version.
The declaration and the accepted in-range example satisfy that criterion.

```text
COMPATIBILITY_CONTRACT_CRITERION=PASS
```

## Structural candidate probe

The following candidate was constructed in memory and passed to
`LiveFrames.Catalogue.DistributionCapability.validate/1` with
`MIX_ENV=test mix run --no-start`. The preview endpoint did not start, and the
candidate was not written to disk.

```json
{
  "library": {
    "status": "supported",
    "evidence_refs": [
      "docs/development/c09d7c2d2r1_cta_library_capability_evidence_review.md"
    ]
  }
}
```

The validator returned `:ok`. Its result proves only that the proposed object
matches the structural contract. The four evidence criteria above supply the
separate sufficiency decision.

```text
PROPOSED_LIBRARY_CLAIM_SHAPE=PASS
EVIDENCE_SUFFICIENCY_FROM_VALIDATOR=NO
```

## Decision

All required criteria pass, and the actual package boundary has accepted
current-main CI evidence. The exact proposed evidence reference is this
review document:

```text
IMPLEMENTATION_CRITERION=PASS
TESTS_CRITERION=PASS
DOCUMENTATION_CRITERION=PASS
COMPATIBILITY_CONTRACT_CRITERION=PASS

PACKAGE_BOUNDARY_EVIDENCE_ACCEPTED=YES
PROPOSED_LIBRARY_CLAIM_SHAPE=PASS

LIBRARY_CAPABILITY_EVIDENCE_REVIEW=ACCEPTED
ACCEPTED_LIBRARY_EVIDENCE_REFS=[
  docs/development/c09d7c2d2r1_cta_library_capability_evidence_review.md
]
```

This decision records durable evidence only. It does not persist a library
capability claim or authorize C2D3.

## Scope and non-authorization

```text
CTA_MANIFEST_MUTATED=NO
CTA_DISTRIBUTION_FIELD_PRESENT=NO
CTA_LIBRARY_SUPPORTED_CLAIM_PERSISTED=NO

PROVENANCE_MUTATED=NO
PROVENANCE_CLEARANCE_ESTABLISHED=NO

SEMVER_SELECTED=NO
RELEASE_ORCHESTRATOR_IMPLEMENTED=NO
RELEASE_TRANSITION_EXECUTED=NO

C09D7_C2D3_AUTHORIZED=NO
CTA_LIBRARY_SUPPORTED_CLAIM_AUTHORIZED=NO
APPROVED_TO_RELEASED_AUTHORIZED=NO
CATALOGUE_RELEASE_AUTHORIZED=NO

PACKAGE_PUBLICATION_AUTHORIZED=NO
HEX_PUBLICATION_EXECUTED=NO

P10_AUTHORIZED=NO
P10_EXECUTED=NO
```

## Performance and scaling

This is static repository evidence work and has no runtime effect.

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
STOP=AWAIT_C2D2R1_INDEPENDENT_REVIEW
```
