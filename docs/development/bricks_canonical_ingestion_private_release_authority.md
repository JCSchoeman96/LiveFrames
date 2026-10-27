# Bricks canonical ingestion private release authority

**Status:** The owner accepted the private canonical-release contract for docs-only publication. This document is submitted for final review. It grants no implementation, ingestion, promotion, disclosure, or componentization authority.

```text
PRIVATE_CANONICAL_RELEASE_CONTRACT=ACCEPTED
AUTHORITY_DOC_PUBLICATION_AUTHORIZED=YES
AUTHORITY_DOC_CLASS=DOCS_ONLY
IMPLEMENTATION_AUTHORIZED=NO
PRIVATE_RELEASE_PROMOTION_AUTHORIZED=NO
PUBLIC_DISCLOSURE_AUTHORIZED=NO
CANONICAL_INGESTION_PUBLICATION_AUTHORIZED=NO
COMPONENTIZATION_AUTHORIZED=NO
ACCEPTANCE_APPROVER=OWNER_ONLY
PROMOTION_APPROVER=OWNER_ONLY
REVOCATION_APPROVER=OWNER_ONLY
PRIVATE_STORE_OWNERSHIP=OWNER_CONTROLLED
CONCRETE_STORAGE_BACKEND=UNSELECTED
STORAGE_BACKEND_SELECTION_REQUIRED_BEFORE_IMPLEMENTATION=YES
RETENTION_POLICY_REQUIRED_BEFORE_IMPLEMENTATION=YES
RECOVERY_POLICY_REQUIRED_BEFORE_IMPLEMENTATION=YES
ACCESS_CONTROL_POLICY_REQUIRED_BEFORE_IMPLEMENTATION=YES
```

Automation may establish facts and candidate status. It may not accept, promote, revoke, or authorize disclosure. Selection of a storage backend and approval of retention, recovery, and access-control policies require separate authority before implementation. This document selects no storage technology.

## Relationship to prior authority and evidence

The accepted [execution-security metadata retention authority](bricks_execution_security_metadata_retention_authority.md), the bounded executable-source semantic translation design, and their existing privacy rules remain in force. This document does not alter those rules. The private Template 124 acceptance proves a particular conversion under its recorded inputs; it is evidence for a candidate, not a promotion or permission to disclose. Its private manifest must be verified under this contract before a future acceptance decision. Historical hashes are legacy result evidence, not current acceptance oracles.

The earlier `product_767_template_124_canonical_ingestion_authority.md` draft remains unaccepted and outside the repository in its separate worktree. Its earlier diagnostic identities and proposed evidence do not establish the current acceptance or a publication decision. This accepted contract governs the proposed private-release domain; it does not overwrite the draft or turn its historical results into current authority. Any remaining substantive conflict must be identified and resolved before implementation.

## Boundaries and durable release

A durable canonical release comprises immutable ordinary Design IR bytes, a sealed ingestion manifest binding those bytes to their inputs and construction, a separate acceptance, and an append-only promotion decision for a named private consumer scope. The IR and manifest are private by default. Their identities do not grant access or disclosure rights. The manifest alone cannot supply the IR or guarantee reproduction; the IR alone cannot establish provenance or authority.

Private acquisition supplies original bytes and evidence to a private ingestion attempt. The loader establishes identity from original, unmodified bytes. The established execution-security classification and sanitization boundary separates the private source model from ordinary consumers before dependency extraction, traces, diagnostics, provenance, and IR construction. The ordinary IR, manifest, acceptance, and private control records remain in owner-controlled private storage. A downstream consumer receives only an authorized release for its scope. No source, PHP, Query Editor, plugin, or WordPress runtime execution is permitted.

`CanonicalPromotion` is private/internal activation of an accepted release for a named consumer scope. `CanonicalDisclosure` / `PublicationDecision` is a reserved future domain for crossing the private boundary. Its lifecycle and implementation are outside this authority.

```text
PRIVATE_PROMOTION != PUBLIC_DISCLOSURE
PUBLIC_DISCLOSURE_REQUIRES_SEPARATE_AUTHORITY
PUBLIC_DISCLOSURE_DEFAULT=DENY
```

Sanitized IR is not presumed public, licensed, or disclosure-safe. A disclosure requires an independent rights and privacy decision; promotion is not that decision.

## Identities and reproducibility

The sealed manifest must bind, with explicit algorithms, byte counts, format and canonicalization versions where applicable:

- Original source bytes and input kind, source version, original fragment, and acquisition snapshot identities. Whole-source identities are allowed under the existing source-identity authority; they are not signature fingerprints and must never validate or infer a signature.
- Raw stored ACSS value, canonical decoded settings and serialized TokenSet identities, TokenSet version, and construction options. For the reported candidate, distinguish the caller-supplied source version, its status, export version, strictness and profile from the ACSS database version.
- Adapter identity, LiveFrames commit and tree, dependency lock, relevant toolchain and implementation-owned defaults, IR schema, serializer and acceptance-criteria versions.
- All conversion authority values, including explicit nils and empty lists, source label and component identity, and the exact IR byte count and digest.
- The private acceptance evidence identity and decision references. The manifest digest identifies its canonical bytes externally; it is not embedded recursively in the bytes it hashes.

Identity and metadata are private by default, including hashes, paths, labels, counts and provenance. A projection is not automatically public. Changing source bytes or any input authority creates a new immutable input tuple and source version; it never replaces an existing version. A changed implementation, dependency lock, relevant default, serializer or toolchain creates a new attempt and manifest even if the source and output bytes are unchanged. It requires its own acceptance before promotion. A new version alone does not revoke an old one.

Later independent reproduction requires authorized access to retained private inputs, the recorded implementation, dependencies, options and serializer. Recompute and compare the sealed identities in a private environment. If required evidence is unavailable, record `REPRODUCIBILITY_STATUS=UNAVAILABLE`; do not claim independent reproducibility. Artifact usability and reproducibility are separate. A verified artifact may remain valid and consumable after evidence disposal only if the applicable policy explicitly permits that condition and all consumer eligibility guards still hold.

## Domain and lifecycle

Records and decisions are immutable once sealed or terminal. State changes preserve history and record the actor, time, scope, policy version and prior references in private audit records. A retry creates a new attempt or decision where stated; it never rewrites a prior one. Idempotent repeats must not create duplicate effects.

### CanonicalSource

A stable opaque source lineage identifies its owner and access domain, not mutable bytes. `proposed -> approved` requires ownership and acquisition permission; `proposed -> rejected` ends the proposal. `approved -> suspended` blocks new attempts and promotions; `suspended -> approved` requires restored authority. `approved` or `suspended -> retired` prevents new versions and promotions. Rejected and retired are terminal. A new proposal uses a new identity; repeated decisions are idempotent.

### CanonicalSourceVersion

A version freezes the required source and acquisition identities. `recorded -> verified -> eligible` requires integrity, provenance and approved scope. `recorded` or `verified -> rejected` follows a mismatch; `eligible -> withdrawn` blocks new acceptance and promotion and identifies dependent releases for action. Rejected and withdrawn are terminal. Verification may retry against unchanged evidence; changed bytes require a new version. Withdrawal does not silently erase existing decisions, and any affected acceptance must be invalidated when its authority or evidence is no longer valid.

### PrivateSourceEvidence

This resource holds private source, acquisition and acceptance evidence. `captured -> verified -> retained` requires integrity and authorized access. `captured` or `verified -> quarantined` blocks use pending investigation. `retained -> access_restricted` limits access; `access_restricted -> retained` requires restored authorization. `retained` or `access_restricted -> disposed` requires explicit retention authority and satisfaction of holds. Disposal records loss of the evidence and sets `REPRODUCIBILITY_STATUS=UNAVAILABLE` when evidence needed for reproduction is lost. `disposed` is terminal. Failed verification may be retried against unchanged evidence or a newly captured record; disposal requests are idempotent and never delete audit history.

### IngestionAttempt

An attempt binds one eligible input tuple and policy. `requested -> running -> succeeded` or `failed`; `requested -> cancelled`; interrupted `running -> abandoned`. Starting requires authorized private access and fixed inputs. Success records a result atomically; failure, cancellation or interruption publishes no candidate. Succeeded, failed, cancelled and abandoned are terminal. Retry creates a new attempt. An attempt cannot accept itself.

### IngestionResult

An immutable outcome identifies either failure or a candidate manifest and artifact. `produced -> validated` requires schema, identity, deterministic serialization and privacy checks; `produced -> rejected` records failure. `validated -> superseded` or `invalidated` blocks acceptance of that result. Rejected, superseded and invalidated are terminal. Reprocessing creates a new result; identical verified bytes may reuse an immutable blob. A result is not acceptance.

### CanonicalIngestionManifest

`draft -> sealed` requires complete, verified input, implementation, policy and output identities. Sealing fixes canonical bytes and their external digest. `draft -> discarded` abandons the candidate; `sealed -> invalidated` blocks new acceptance and identifies dependent acceptances for invalidation where necessary. Discarded and invalidated are terminal. Corrections create a new manifest; repeated sealing of identical canonical bytes is idempotent.

### CanonicalIRArtifact

The artifact is the exact immutable serialized ordinary IR. `staged -> verified -> retained` requires digest, schema, privacy and access checks. `staged -> rejected` discards a failed candidate. `verified` or `retained -> quarantined` blocks consumption. `retained -> disposed` requires `NO_ACTIVE_PROMOTION_REFERENCES_ARTIFACT` and explicit retention disposal authority. First revoke or supersede the promotion, then verify no active references, then authorize disposal, then dispose. Rejected and disposed are terminal. A retry stages independently and atomically installs only verified bytes. Disposal never deletes release, acceptance, promotion or revocation history.

### CanonicalAcceptance

`proposed -> accepted` requires the owner, a sealed valid manifest, verified available artifact, named criteria and verified evidence with no applicable block. `proposed -> rejected` records the decision. `accepted -> invalidated` applies when evidence or identity is wrong or unverifiable, a relevant privacy, security or correctness defect is found, source rights are withdrawn, criteria were unmet, or policy declares incompatibility. Invalidated and rejected are terminal; reassessment creates a new decision.

Invalidation immediately makes **all dependent promotions non-consumable**, without waiting for any further control record. An append-only revocation or supersession record follows. Acceptance does not promote itself. Loss of reproduction evidence is recorded and reviewed under the explicit policy; it does not automatically erase the historical acceptance or imply continued eligibility.

### CanonicalPromotion

`proposed -> active` requires owner approval, a valid acceptance, an available verified artifact, compatible schema, approved private consumer scope and no applicable block. Activation atomically changes the active pointer for that scope and preserves history. `proposed -> rejected`; `active -> superseded` or `revoked`. Rejected, superseded and revoked are terminal. A rollback creates a new owner-approved promotion after current eligibility checks; it cannot reactivate a revoked or invalid release by deleting history. Repeated requests are idempotent. Promotion is not disclosure.

### CanonicalRevocation

`proposed -> effective` requires the owner to identify the exact release or promotion, scope and safe reason. Effect blocks consumption immediately, atomically removes or replaces affected active pointers, and makes the decision available to affected consumers. `proposed -> rejected` records the decision. Effective and rejected are terminal. Repeated requests are idempotent; reversal requires a new eligible decision, never removal of the revocation record.

### Consumer eligibility

Every new consumption must establish current authorization for its exact release and scope:

```text
promotion.active?
AND acceptance.accepted?
AND NOT acceptance.invalidated?
AND NOT promotion.revoked?
AND artifact.available?
AND compatibility.valid?
```

The consumer also verifies the artifact digest and records the exact manifest, IR and acceptance identities. If current authorization cannot be established, `CONSUMER_RESULT=FAIL_CLOSED`. A stale active pointer cannot override acceptance invalidation. Downstream outputs retain their recorded provenance; the owner decides whether affected outputs require withdrawal, rebuild or other action. Componentization remains unauthorized.

## Required invariants

```text
IMMUTABLE_SOURCE_VERSION=YES
IMMUTABLE_SEALED_MANIFEST=YES
IMMUTABLE_CANONICAL_IR_ARTIFACT=YES
ATTEMPT_CANNOT_ACCEPT_ITSELF=YES
ACCEPTANCE_CANNOT_PROMOTE_ITSELF=YES
INVALID_ACCEPTANCE_CANNOT_BE_CONSUMED=YES
REVOKED_PROMOTION_CANNOT_BE_CONSUMED=YES
ACTIVE_ARTIFACT_CANNOT_BE_DISPOSED=YES
PROMOTION_IS_PRIVATE_SCOPE_ACTIVATION=YES
PROMOTION_IS_NOT_PUBLICATION=YES
PRIVATE_SOURCE_IN_REPOSITORY=FORBIDDEN
PRIVATE_IR_IN_REPOSITORY=FORBIDDEN
PRIVATE_MANIFEST_IN_REPOSITORY=FORBIDDEN
EXECUTION_SIGNATURE_RETENTION_IN_ORDINARY_ARTIFACT=FORBIDDEN
QUERY_EDITOR_BODY_RETENTION_IN_ORDINARY_ARTIFACT=FORBIDDEN
RAW_EXECUTABLE_BODY_RETENTION_IN_ORDINARY_ARTIFACT=FORBIDDEN
```

The bounded executable-source semantic translation design remains the authority for its existing safe source fingerprint, execution-enabled status and safe non-code settings provenance for preserved unsupported executable elements. This exception is not broadened. It does not permit raw executable bodies or any execution-signature value, fragment, direct derivative, validity or presence fact in ordinary output. Unknown execution-signature contexts fail closed under the accepted execution-security authority.

## Repository, privacy and operations

The repository may contain this authority, synthetic fixtures, and future schemas or implementation only when separately authorized. It must not contain Template 124 source, the canonical SQL dump, real ACSS settings, private executable bodies, execution signatures, Query Editor bodies, private canonical IR, private acceptance manifests, private diagnostics or private evidence manifests. The same boundary applies to CI artifacts, logs, crash reports, temporary files, backups and support bundles. A hash or metadata projection requires its own disclosure review.

Exclude credentials, salts, secrets, private paths and raw exceptions from ordinary diagnostics and manifests. Use bounded safe error categories. Treat imported data and paths as untrusted. Private staging must use access-controlled storage and cleanup on success, failure and interrupted runs, with an approved recovery policy. Do not assume secure deletion from every medium. Validate before atomic finalization; privacy failure, identity mismatch, partial writes, unsupported schema or unknown signature context produces no consumable candidate. The sanitizer and private disclosure review are distinct checks; a scan alone is not proof that all proprietary content is absent.

## Performance and concurrency

This is a cold/build-time path. A future plan must bound input size, nesting depth, element count, diagnostic count, artifact size and execution duration. Numeric limits require evidence and may be set in that plan. Specify deterministic serialization and reject unsupported values. Stream hashing and copying when source size and the converter permit; if conversion requires a full in-memory document, measure and bound it. Use isolated staging and atomic finalization for parallel attempts. Idempotency must cover the full source, implementation, options and policy tuple; content-addressed identity does not confer authorization.

Redis, GenServers, PubSub, runtime caching and runtime polling are not authorized without a future demonstrated requirement.

## Next gate

Final review of this docs-only authority precedes any separate implementation proposal. Storage selection and the required operational policies must be decided before implementation. Private acceptance, private promotion and public disclosure remain separate future decisions. No componentization is authorized here.
