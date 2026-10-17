# C2L0 CTA Catalogue release-readiness preflight

This record audits the approved CTA Catalogue item for a future
`APPROVED -> RELEASED` workflow. It does not change the manifest, select a
version, decide provenance clearance, or execute a lifecycle transition.

Audit date: 2026-10-17

## Scope and frozen base

The shared checkout was clean on `main`. After fetching `origin`, its commit and
tree matched the frozen base. The preflight used a new worktree at that commit.

```text
BASE_SHA=5870f4cc3580f53f4ec6d8f589807aec63bd2186
BASE_TREE=690651936019354f8d1a513ef500668e307dd45d
BASE_CI=39018792399
BASE_CI_RESULT=PASS

C2O1_MERGE_SHA=7431246034056b19dbdb1475db2a69544ea2f9cb
C2O1_POST_MERGE_CI=39018775242
C2O1_POST_MERGE_CI_RESULT=PASS

CATALOGUE_ID=live_frames.section.media_call_to_action
CATALOGUE_STATE_BEFORE=APPROVED
APPROVED_MANIFEST_SHA256=971bbf50e17295dc9012187ed3578ec9b3be174d0a230e6046f43e1bd485aa5d
```

The current manifest has the required ID and `APPROVED` state. Its last
transition is `approve`, from `REVIEWED` to `APPROVED`, with the sole evidence
reference `docs/development/c09d7c2o0_cta_catalogue_owner_approval.md`. Its
fingerprint algorithm is `lf-contract-v1-jcs-sha256`; its fingerprint is
`14550b34d1d8820ffdddd59e0e354d89e8a6a043eced8dc5afe472a5dc2ec05b`. The
manifest has no `distribution` or `release` field.

## Release authority

The release edge is `release / APPROVED -> RELEASED` in
[`lifecycle.ex`](../../apps/live_frames/lib/live_frames/catalogue/lifecycle.ex)
and [Catalogue architecture](../23_CATALOGUE_ARCHITECTURE.md). Its guard
requires:

- a valid initial CatalogueItem SemVer;
- the current contract fingerprint;
- validated capability claims;
- human-governed provenance release clearance.

The versioning policy assigns composition of versioning, fingerprint,
capability, Storybook, and provenance results to a separate release
orchestrator. `Lifecycle.transition/3` accepts a generic guard result and does
not compose those checks. Catalogue `RELEASED` is separate from package
publication. P10 is also separate and remains unauthorized.

The authorities inspected were
[docs/23](../23_CATALOGUE_ARCHITECTURE.md),
[docs/24](../24_CATALOGUE_VERSIONING_POLICY.md),
[docs/04](../04_SOURCE_AND_PROVENANCE.md), and the Catalogue modules
`lifecycle.ex`, `versioning.ex`, `fingerprint.ex`, `storybook_reference.ex`,
`provenance_reference.ex`, and `discovery.ex`.

## Guard results

### Lifecycle and fingerprint

The transition matrix contains `release / APPROVED -> RELEASED`.
`Lifecycle.validate_snapshot/1` returned `:ok`; the item is eligible by source
state and lifecycle history. No transition was called.

`Fingerprint.compute/2` returned algorithm
`lf-contract-v1-jcs-sha256` and fingerprint
`14550b34d1d8820ffdddd59e0e354d89e8a6a043eced8dc5afe472a5dc2ec05b`.
`Fingerprint.verify/3` returned `:ok` against the manifest and production CTA
component.

```text
LIFECYCLE_SOURCE_STATE=APPROVED
LIFECYCLE_RELEASE_EDGE_PRESENT=YES
LIFECYCLE_ELIGIBILITY=PASS
CURRENT_FINGERPRINT_GUARD=PASS
FINGERPRINT_COMPUTE=PASS
FINGERPRINT_VERIFY=PASS
FINGERPRINT=14550b34d1d8820ffdddd59e0e354d89e8a6a043eced8dc5afe472a5dc2ec05b
```

### Storybook and current component evidence

The current inert manifest reference names
`LiveFramesPreviewWeb.Storybook.Components.MediaCallToAction`.
`StorybookReference.validate/2` returned `:ok` for that trusted module.

The existing C2R0 review evidence records one `:default` variation and a
successful render through `/storybook/components/media_call_to_action`. The
focused current test
`mix test apps/live_frames_preview/test/live_frames_preview_web/native_cta_storybook_test.exs`
passed with 3 tests and 0 failures. It requested that route, received HTTP 200,
and asserted the CTA heading in the response. Mix logged that the optional
Storybook CSS and JavaScript bundles were not built; the route and server
render assertions passed without them.

```text
STORYBOOK_REFERENCE_VALIDATE=PASS
DEFAULT_VARIATION_PRESENT=YES
DEFAULT_RENDER_EVIDENCE=PASS
```

### Initial CatalogueItem SemVer

The manifest has no `release` object. There is no CTA version-review evidence.
`Versioning.validate_initial_release/2` validates a supplied candidate version
and separate review evidence; it does not choose a version. Docs/24 allows any
valid stable `MAJOR.MINOR.PATCH` for an initial release, subject to the other
guards. C2L0 makes no version decision and does not infer one from the Mix
package version, schema version, Git tags, or package linkage fields.

```text
INITIAL_RELEASE_VERSION_PRESENT=NO
INITIAL_RELEASE_FIELD_PRESENT=NO
INITIAL_RELEASE_VERSION_SELECTED=NO
VERSION_REVIEW_EVIDENCE_PRESENT=NO
INITIAL_SEMVER_GUARD_READY=NO
```

### Distribution capability claims

The current normalized, fingerprinted public-contract capability identifiers
are:

```text
liveframes.consumer.owns_action_navigation_and_events
liveframes.consumer.owns_global_root_attributes
liveframes.integration.requires_liveframes_css
liveframes.validation.argument_error_on_contract_violation
```

Those identifiers describe the component contract. They are not claims about
Catalogue distribution capabilities. The manifest has no `distribution`
field. A search of Catalogue production code found no dedicated validator for
`distribution.library`, `distribution.generator`, or `distribution.ejection`,
and no release orchestrator. The current code therefore cannot positively
validate a `distribution.library` claim from accepted evidence. A dedicated
distribution capability contract and validation slice is required. C1 passing
does not establish that claim.

Docs/23 says generator and ejection remain unsupported and unauthorized. P10
is not authorized.

```text
NORMALIZED_PUBLIC_CONTRACT_CAPABILITIES=4 existing fingerprinted identifiers, listed above
MANIFEST_DISTRIBUTION_FIELD_PRESENT=NO
DEDICATED_DISTRIBUTION_CAPABILITY_VALIDATOR_PRESENT=NO
DISTRIBUTION_CAPABILITY_VALIDATOR_PRESENT=NO
DISTRIBUTION_CAPABILITY_GUARD_READY=NO
LIBRARY_DISTRIBUTION_CLAIM=UNPROVEN
GENERATOR_DISTRIBUTION_SUPPORTED_CLAIM=NOT_AUTHORIZED
EJECTION_DISTRIBUTION_SUPPORTED_CLAIM=NOT_AUTHORIZED
GENERATOR_SUPPORTED_CLAIM=NOT_AUTHORIZED
EJECTION_SUPPORTED_CLAIM=NOT_AUTHORIZED
P10_AUTHORIZED=NO
```

### Provenance release clearance

The CTA references the source group `Bricks copied-elements export / CTA
Tango`, resolved through `docs/04_SOURCE_AND_PROVENANCE.md`. That authority
records:

```text
redistribution_status=unknown
publication_state=classified
clearance_evidence_refs=[]
HUMAN_REVIEW=YES
HUMAN_CLEARANCE_DECISION=NOT_RECORDED
```

The read-only call to
`ProvenanceReference.release_clearance/2`, using those canonical facts,
returned `catalogue.provenance_reference.redistribution_not_approved` at
`provenance.references[0]`. This is the first failure. The predicate requires
redistribution status `approved`, publication state `public_safe`, a non-empty
clearance evidence list, and every clearance reference to occur in the
record's `evidence_refs`.

No provenance fact or evidence reference was changed or inferred. A human
governance decision is required.

```text
PROVENANCE_RELEASE_CLEARANCE=FAIL
PROVENANCE_RELEASE_CLEARANCE_DIAGNOSTIC=catalogue.provenance_reference.redistribution_not_approved
HUMAN_PROVENANCE_GOVERNANCE_REQUIRED=YES
PROVENANCE_SOURCE_GROUP=Bricks copied-elements export / CTA Tango
PROVENANCE_REDISTRIBUTION_STATUS=unknown
PROVENANCE_PUBLICATION_STATE=classified
PROVENANCE_CLEARANCE_EVIDENCE_REFS=[]
PROVENANCE_RELEASE_CLEARANCE_RESULT=FAIL
```

### Release orchestration

Catalogue production code contains the separate primitives, but no production
workflow composing versioning, fingerprint, distribution capability
validation, Storybook, `ProvenanceReference.release_clearance/2`, and
`Lifecycle.transition/3` before a release transition. The only production
`Lifecycle.transition/3` call found is in admission code for the
`admit_to_catalogue` action. The lifecycle module itself is not the release
orchestrator.

```text
RELEASE_ORCHESTRATOR_PRESENT=NO
SAFE_RELEASE_EXECUTION_PATH_PRESENT=NO
RELEASE_IMPLEMENTATION_PREREQUISITE_REQUIRED=YES
```

### Programme security readiness

`mix deps.get --check-locked` resolved the locked dependency set without
changing `mix.lock` or `mix.exs`. It reported:

```text
Bandit 1.12.5
  HIGH   CVE-2026-105659
  MEDIUM CVE-2026-105660

LazyHTML 0.1.12
  LOW    CVE-2026-92106
```

These advisories are programme release-readiness findings, not docs/23
Catalogue lifecycle predicates. The Bandit HIGH requires remediation or an
explicit owner/security risk disposition before the public-release baseline
can be described as hardened. C2L0 does not change dependencies.

```text
SECURITY_IS_DOCS23_CATALOGUE_GUARD=NO
PROGRAMME_RELEASE_SECURITY_READINESS=CURRENTLY_UNRESOLVED
BANDIT_HIGH_OPEN=YES
BANDIT_MEDIUM_OPEN=YES
LAZY_HTML_LOW_OPEN=YES
```

## Future prerequisite slices

This ordering records dependencies between work. It does not authorize any
slice.

1. Human provenance governance records a clearance decision and its evidence.
2. A distribution capability contract defines the evidence required for each
   claim, then a dedicated validator checks it. Library support remains
   unproven until that work accepts evidence. Generator and ejection remain
   unauthorized.
3. A release orchestrator composes versioning, fingerprint, capability,
   Storybook, and provenance results into one fail-closed guard before calling
   the lifecycle transition.
4. Security owners remediate the open advisories or record an explicit risk
   disposition. The HIGH finding must be resolved before claiming a hardened
   public-release baseline.
5. A separate version review deliberately selects a stable CatalogueItem
   SemVer and records durable evidence for it.
6. A final preflight checks the exact release candidate against every guard.
7. A separately authorized action may execute `APPROVED -> RELEASED` only
   after the preceding guards pass.

Package publication requires its own evidence and authorization. P10 remains a
separate workstream.

## Verification record

The focused read-only Mix probe returned:

```text
Manifest.decode=PASS
Identity.validate=:ok
Lifecycle.validate_snapshot=:ok
Fingerprint.compute=14550b34d1d8820ffdddd59e0e354d89e8a6a043eced8dc5afe472a5dc2ec05b
Fingerprint.verify=:ok
StorybookReference.validate=:ok
Registry.Builder.build=PASS
ProvenanceReference.release_clearance=FAIL: catalogue.provenance_reference.redistribution_not_approved
Manifest.release=ABSENT
Manifest.distribution=ABSENT
```

The initial probe from the nested preview-app directory could not find the
umbrella dependencies. The same probe then ran successfully from the umbrella
root after locked dependency setup with `mix deps.get --check-locked`. That
setup reported the advisories above and left the dependency files unchanged.

The following full gates were skipped because this branch changes one
documentation file only. The focused Storybook test above was run instead of
the full test suite.

```text
mix format --check-formatted       SKIPPED: no Elixir source changed
mix compile --warnings-as-errors   SKIPPED: no Elixir source changed; focused Mix probe compiled the umbrella
mix assets.build                  SKIPPED: no assets changed
mix test                          SKIPPED: full suite not needed for a documentation-only change
mix deps.unlock --check-unused    SKIPPED: no dependency declarations or lock entries changed
git diff --check                  REQUIRED before commit
```

The local C2L0 preflight used `mix deps.get --check-locked` to verify locked
dependency resolution without changing the dependency files. Repository CI
separately uses `mix deps.get` in its `Fetch dependencies` step. No private CTA
source was reconstructed or executed.

## Performance and scaling

```text
DATA_LAYER=REPOSITORY_RELEASE_AUTHORITY_AUDIT
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

The dependency resolution above is a one-time preflight tool operation. It is
not part of runtime behavior.

## Result

```text
RELEASE_READINESS_RESULT=BLOCKED

CATALOGUE_ID=live_frames.section.media_call_to_action
CATALOGUE_STATE_BEFORE=APPROVED
CATALOGUE_STATE_AFTER=APPROVED
RELEASE_TRANSITION_EXECUTED=NO

LIFECYCLE_ELIGIBILITY=PASS
CURRENT_FINGERPRINT_GUARD=PASS

INITIAL_RELEASE_VERSION_SELECTED=NO
INITIAL_SEMVER_GUARD_READY=NO
STORYBOOK_REFERENCE_VALIDATE=PASS

PROVENANCE_RELEASE_CLEARANCE=FAIL

RELEASE_ORCHESTRATOR_PRESENT=NO
SAFE_RELEASE_EXECUTION_PATH_PRESENT=NO

DISTRIBUTION_CAPABILITY_GUARD_READY=NO
PROGRAMME_RELEASE_SECURITY_READINESS=CURRENTLY_UNRESOLVED

APPROVED_TO_RELEASED_AUTHORIZED=NO
CATALOGUE_RELEASE_AUTHORIZED=NO
PACKAGE_PUBLICATION_AUTHORIZED=NO
P10_AUTHORIZED=NO
```
