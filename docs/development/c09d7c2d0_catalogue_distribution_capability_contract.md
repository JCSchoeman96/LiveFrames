# C09D7-C2D0 Catalogue distribution capability contract

**Status:** C2D0 freezes documentation authority only. The design is owner-approved. C2D1 and all implementation remain unauthorized.

**Frozen base:** `59e81aaf431e7b4031c25366e86614e81322f8c1`, tree `cf3d9a050900bf042c48720224068cf5aa884fdc`. The accepted C2P0 post-merge CI run is `39053281280`, result `PASS`.

## 1. Authority and scope

[Catalogue architecture §10](../23_CATALOGUE_ARCHITECTURE.md) remains authoritative for the conceptual separation of provenance and distribution capabilities. [Catalogue versioning policy §4](../24_CATALOGUE_VERSIONING_POLICY.md) remains authoritative for release-guard composition.

This document adds the exact G1 nested `distribution` manifest contract and defines the boundary between pure structural validation and separate capability evidence review. It specializes the two authorities above. It does not supersede unrelated Catalogue architecture or alter their text.

C2D0 is documentation authority only. It does not implement a validator, change `Schema.V1`, alter any manifest, review CTA capability evidence, execute a lifecycle transition, choose SemVer, implement release orchestration, change provenance, publish a package, or authorize P10.

The authority sources for this contract are:

- [C1 external consumer Catalogue handoff authority](c09d7c_external_consumer_catalogue_handoff_authority.md)
- [C2L0 CTA Catalogue release readiness](c09d7c2l0_cta_catalogue_release_readiness.md)
- [C2P0 CTA provenance clearance evidence](c09d7c2p0_cta_provenance_clearance_evidence.md)
- [Catalogue architecture](../23_CATALOGUE_ARCHITECTURE.md)
- [Catalogue versioning policy](../24_CATALOGUE_VERSIONING_POLICY.md)

## 2. Capability model

The independent G1 distribution capabilities are:

```text
distribution.library
distribution.generator
distribution.ejection
```

These fields are Catalogue distribution declarations. They are separate from the normalized component `capabilities` defined in docs/23 §8.4 and from provenance facts governed by docs/23 §10 and docs/04.

A positive capability claim requires accepted evidence covering implementation, tests, documentation, and the compatibility contract. The exact claim shape is validated separately from the substantive evidence. C1 proves a bounded external consumer result; C1 alone does not prove any `distribution.*=supported` claim.

Generator and ejection remain not authorized and have no positive claim in the CTA manifest. Catalogue release does not require either capability.

## 3. Exact G1 wire contract

The positive representation is:

```json
{
  "distribution": {
    "library": {
      "status": "supported",
      "evidence_refs": [
        "docs/development/example_library_distribution_evidence.md"
      ]
    }
  }
}
```

The path above is illustrative. It does not claim that the evidence exists or has been accepted.

### `distribution`

At the generic manifest level, `distribution` remains optional. If it is absent, no positive distribution capability is claimed.

When present, `distribution` must be a JSON object with at least one capability claim. Its only permitted keys are `library`, `generator`, and `ejection`. An empty object and unknown capability keys are invalid.

G1 does not introduce competing representations named `supported_capabilities`, `capabilities`, `distribution_status`, `enabled`, `disabled`, `pending`, or `unsupported`.

### Capability object

Each present capability value must be a JSON object with exactly these keys:

```text
status
evidence_refs
```

Unknown or missing keys are invalid. The only G1 persisted `status` value is the exact, case-sensitive string `supported`.

Do not accept or persist `unsupported`, `pending`, `unknown`, `experimental`, booleans, or numeric status values. An absent capability key means no positive support claim. It does not represent a persisted negative or unsupported state.

### Evidence references

`evidence_refs` must be a non-empty JSON array. Each member must be an exact, non-empty, valid UTF-8 string. Duplicate strings are invalid.

References remain inert authority strings. Their supplied order may be preserved as data, but order does not increase or reduce authority. Validation must not trim, case-fold, Unicode-normalize, sort, silently deduplicate, atomize, parse as a module, resolve as a filesystem path, check file existence, make network calls, parse Markdown, or scan the repository.

## 4. Pure distribution validator

A future dedicated pure validator owns only the structural and reference-integrity checks below:

- `distribution` object shape and non-emptiness when present
- allowed capability names
- exact capability object keys and value types
- exact `status` value
- `evidence_refs` array type and non-emptiness
- exact, non-empty, valid UTF-8 reference strings
- duplicate reference detection
- unknown-key rejection

The validator checks claim shape and evidence-reference integrity. It does not judge whether the referenced evidence is substantively sufficient. It does not inspect evidence contents, decide whether the implementation, tests, documentation, or compatibility contract exist, or infer support from repository state. It does not make legal or provenance decisions and has no side effects.

This validator does not call `Lifecycle.transition/3`. It does not mutate a manifest. C2D0 does not authorize its implementation.

## 5. Separate capability evidence review

A separate evidence-review workflow determines whether the exact `evidence_refs` attached to a proposed capability establish all requirements for that positive support claim. Across the exact referenced evidence, the review must establish:

- implementation evidence
- tests evidence
- documentation evidence
- compatibility-contract evidence

The review binds its conclusion to the Catalogue item identity, capability name, exact proposed status, exact `evidence_refs` list, and relevant contract or version identity where applicable.

The evidence review produces durable review evidence. It does not automatically mutate the Catalogue manifest or replace structural validation. A positive capability claim requires both a structurally valid claim and separately accepted capability evidence.

```text
VALID_SHAPE
!=
CAPABILITY_EVIDENCE_ACCEPTED

CAPABILITY_EVIDENCE_ACCEPTED
!=
PROVENANCE_CLEARANCE

CAPABILITY_EVIDENCE_ACCEPTED
!=
CATALOGUE_RELEASE
```

## 6. Evidence-first persistence and capability state

Distribution capability is not an independent Catalogue lifecycle. For one capability, the G1 persisted claim states are conceptually:

```text
ABSENT
SUPPORTED
```

`ABSENT` means no positive support claim is persisted. `SUPPORTED` means a structurally valid positive claim exists and separate evidence review accepted the exact evidence for that claim. There are no persisted intermediate states or separate terminal state.

The evidence-first sequence is:

```text
candidate capability
        ↓
separate evidence review
        ↓
accepted durable evidence
        ↓
separately authorized manifest mutation
        ↓
supported capability claim
```

The later manifest mutation must cite the exact accepted evidence references required by the capability contract. C2D0 performs none of these steps. Later changes or removal of a released supported capability remain consumer-contract and versioning concerns under the Catalogue lifecycle and docs/24. C2D0 creates no capability lifecycle.

## 7. Initial Catalogue release requirement

For G1, `APPROVED → RELEASED` requires a validated positive claim with:

```text
distribution.library.status=supported
```

The library claim must have structurally valid references and accepted capability evidence review. `distribution.generator` and `distribution.ejection` are not required for Catalogue release. They remain not authorized and must have no positive claim unless separately proven and authorized later.

This requirement adds a minimum library capability guard to the existing release requirements. It does not replace the current fingerprint, versioning, Storybook, or provenance guards in docs/23 and docs/24.

## 8. Release-guard composition

The future initial-release flow conceptually composes these results:

```text
INITIAL RELEASE CANDIDATE
        │
        ├─ Versioning guard
        ├─ Current contract fingerprint guard
        ├─ Distribution capability structural validation
        ├─ Accepted capability evidence review
        ├─ Storybook/current component evidence where required
        └─ Provenance release-clearance guard
                ↓
      future release orchestration
                ↓
      Lifecycle.transition("release", ...)
```

The distribution validator and capability evidence reviewer do not call `Lifecycle.transition/3`. A future release orchestrator owns composition, as described in docs/24 §4. C2D0 does not define or implement that orchestrator.

## 9. Current CTA state

The accepted CTA state is:

```text
CATALOGUE_ID=live_frames.section.media_call_to_action
CATALOGUE_STATE=APPROVED

MANIFEST_DISTRIBUTION_FIELD_PRESENT=NO

DISTRIBUTION_LIBRARY_SUPPORTED_CLAIM=NO
DISTRIBUTION_GENERATOR_SUPPORTED_CLAIM=NO
DISTRIBUTION_EJECTION_SUPPORTED_CLAIM=NO

C1_CONSUMER_PROOF_EXISTS=YES
C1_ALONE_PROVES_LIBRARY_DISTRIBUTION_SUPPORT=NO

CTA_LIBRARY_CAPABILITY_EVIDENCE_REVIEW_ACCEPTED=NO
CTA_DISTRIBUTION_CAPABILITY_RELEASE_GUARD=NOT_READY
```

C1 remains technical consumer evidence. The CTA manifest remains unchanged by C2D0.

## 10. Provenance boundary

Distribution capability evidence and provenance clearance are independent release guards:

```text
distribution capability evidence
!=
provenance redistribution/publication clearance
```

The current CTA provenance facts remain:

```text
redistribution_status=unknown
publication_state=classified
clearance_evidence_refs=[]
```

C2P0 found no explicit positive clearance evidence and no human clearance decision. A future valid `distribution.library=supported` claim would not establish provenance clearance. Future provenance clearance would not establish library, generator, or ejection support. C2D0 does not mutate or reinterpret provenance.

## 11. Schema boundary

The current generic `LiveFrames.Catalogue.Schema.V1` decoder intentionally treats `distribution` as an optional object and checks only that it is an object when present. It does not validate the nested capability contract.

C2D0 does not authorize modifying `Schema.V1`. The future nested contract belongs to a dedicated validator, proposed conceptually as `LiveFrames.Catalogue.DistributionCapability`. The exact module and function implementation are not authorized by C2D0.

## 12. Pure-validation invariants

```text
VALIDATOR_IS_PURE=YES
VALIDATOR_SIDE_EFFECTS=NONE

FILESYSTEM_READS=0
NETWORK_CALLS=0
DATABASE_CALLS=0

MARKDOWN_PARSING=NO
REPOSITORY_SCANNING=NO
PATH_EXISTENCE_VALIDATION=NO

ATOM_CREATION_FROM_MANIFEST_VALUES=NO
SILENT_NORMALIZATION=NO
SILENT_DEDUPLICATION=NO
```

All manifest values remain inert data.

## 13. Failure behavior and diagnostics

The validator fails closed when any of these conditions occurs:

- `distribution` is present but is not an object
- `distribution` is present but empty
- a capability key is unknown
- a capability value is not an object
- `status` is missing or is not exactly `supported`
- `evidence_refs` is missing, is not an array, or is empty
- an evidence reference is not a string, is empty, or is not valid UTF-8
- an evidence reference is duplicated
- a capability object contains an unknown key

The validator does not silently ignore or repair malformed claims. Diagnostics identify the failing logical path, such as:

```text
distribution
distribution.library
distribution.library.status
distribution.library.evidence_refs
distribution.library.evidence_refs[1]
```

C2D0 does not freeze diagnostic code strings. C2D1 may define deterministic identifiers while preserving these failure semantics.

## 14. Security, performance, and scaling

The distribution contract describes static repository manifest metadata. C2D0 adds no runtime behavior or infrastructure.

```text
DATA_LAYER=STATIC_REPOSITORY_MANIFEST_METADATA
RUNTIME_EFFECT=C2D0_NONE

HOT_DATA=N/A
WARM_DATA=N/A
COLD_DATA=REPOSITORY_ARTIFACT

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

VALIDATOR_RUNTIME_DB_CALLS=0
VALIDATOR_RUNTIME_NETWORK_CALLS=0
VALIDATOR_RUNTIME_FILESYSTEM_SCANS=0
100K_CONCURRENT_USERS=N/A
```

## 15. Next stage and explicit non-authorization

After this authority is independently reviewed and merged, the expected next stage is C2D1, implementation of the dedicated pure distribution-capability validator. C2D0 does not authorize C2D1.

```text
C09D7_C2D0=AUTHORITY_ONLY

C09D7_C2D1=NOT_AUTHORIZED
DISTRIBUTION_VALIDATOR_IMPLEMENTATION_AUTHORIZED=NO

CTA_DISTRIBUTION_MANIFEST_MUTATION_AUTHORIZED=NO
CTA_LIBRARY_SUPPORTED_CLAIM_AUTHORIZED=NO

CTA_CAPABILITY_EVIDENCE_REVIEW_AUTHORIZED=NO

SEMVER_SELECTION_AUTHORIZED=NO
RELEASE_ORCHESTRATOR_IMPLEMENTATION_AUTHORIZED=NO

PROVENANCE_MUTATION_AUTHORIZED=NO
PROVENANCE_CLEARANCE_ESTABLISHED=NO

APPROVED_TO_RELEASED_AUTHORIZED=NO
CATALOGUE_RELEASE_AUTHORIZED=NO
PACKAGE_PUBLICATION_AUTHORIZED=NO
P10_AUTHORIZED=NO
```
