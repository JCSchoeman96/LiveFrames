# Bricks canonical ingestion storage and operations authority

**Status:** Owner-directed docs-only authority proposal for final review. It selects the storage architecture and specifies operating policy. It does not authorize implementation, resource provisioning, ingestion, acceptance, promotion, disclosure, or componentization. Acceptance and merge of this document are separate from those actions.

This proposal supplements the accepted [private release authority](bricks_canonical_ingestion_private_release_authority.md) and [execution-security metadata retention authority](bricks_execution_security_metadata_retention_authority.md). Their lifecycle, sanitization, privacy, and owner-only decision rules remain in force. The earlier release authority deliberately left storage unselected; this document makes the separate selection if accepted. No source runtime is executed. Storage identity does not grant access, acceptance, promotion, or disclosure.

```text
AMAZON_S3_SELECTED=YES
POSTGRESQL_SELECTED=YES
PRIMARY_PRIVATE_OBJECT_STORE=AMAZON_S3
CONTROL_STORE=POSTGRESQL
AUTHORITY_WITNESS_STORE=AMAZON_S3_SEPARATE_PRIVATE_BUCKET
BACKUP_OBJECT_STORE=AMAZON_S3_SEPARATE_REGION_PRIVATE_COPY
S3_AUTHORITY_WITNESS_ACCEPTED=YES
WITNESS_RECORD_MODEL=COMMAND_EFFECTIVE_ABORTED
GLOBAL_WITNESS_SEQUENCE=YES
MAX_UNRESOLVED_SECURITY_DECISIONS=1
RESTRICTIVE_PENDING_DENY_REQUIRED=YES
RESTRICTIVE_COMMAND_CANNOT_AUTO_ABORT=YES
CANONICAL_ACCEPTANCE_ACCEPTED=PERMISSIVE
CANONICAL_ACCEPTANCE_INVALIDATED=RESTRICTIVE
DEFAULT_CLASSIFICATION=RESTRICTIVE
WITNESS_WRITER_CANNOT_CREATE_POSITIVE_AUTHORITY=YES
PERMISSIVE_WITNESS_ALONE_SUFFICIENT_FOR_POSITIVE_AUTHORITY=NO
PERMISSIVE_EFFECTIVE_WITNESS_REQUIRED_BEFORE_CONSUMPTION=YES
PERMISSIVE_INCOMPLETE_COMMAND_DEFAULTS_NON_EFFECTIVE=YES
STARTUP_FRESHNESS_GATE_DEFINED=YES
PER_CONSUMPTION_TRANSACTIONAL_GATE_DEFINED=YES
RESTORE_FRESHNESS_GATE_DEFINED=YES
RECOVERY_CAN_RESURRECT_REVOKED_AUTHORITY=NO
ACCESS_CONTROL_POLICY_COMPLETE=YES
RETENTION_POLICY_COMPLETE=YES
BACKUP_POLICY_COMPLETE=YES
RECOVERY_POLICY_COMPLETE=YES
AUDIT_POLICY_COMPLETE=YES
ENCRYPTION_POLICY_COMPLETE=YES
IMPLEMENTATION_PREREQUISITES_COMPLETE=AUTHORITY_DEFINED_PENDING_DOC_MERGE_AND_CONCRETE_RESOURCE_CONFIGURATION
IMPLEMENTATION_AUTHORIZED=NO
```

These statements describe required policy and protocol, not evidence that a deployed system satisfies them. Before implementation, the owner must verify the owner-controlled AWS account, approve regions and billing, provision separate identities, select the PostgreSQL deployment, and verify the secret boundary and exact Object Lock retention configuration. Account IDs, bucket names, credentials, and private paths do not belong in repository authority. Implementation requires separate authorization.

## Storage, integrity, and trust

The primary S3 bucket stores private immutable content-addressed evidence, approved ACSS evidence, sealed manifests, IR artifacts, and approved evidence bundles. Use opaque keys of the form `<artifact-class>/<algorithm>/<digest>`, not source names, private paths, executable content, credentials, or unreviewed site identifiers. Conditional creation is mandatory. No in-place overwrite is permitted. A duplicate may be reused only after exact-byte digest, byte-count, and access-domain verification. Record expected and observed digest, algorithm, byte count, and result for every retained blob. Verify artifact bytes against the authoritative digest before consumption. Neither key, database reference, path, nor ETag alone proves integrity or authority. Stream transfer and hashing where possible and bound memory where not.

PostgreSQL holds transactional active control state, canonical lifecycle records, references, decisions, grants, retention, audit references, and scope pointers. It is not the default home for large blobs. Foreign keys, unique identities, append-only decisions, transactions, and compare-and-swap enforce eligibility and at most one active promotion per scope. Revocation and invalidation cannot be overridden by stale pointers. The witness is durable freshness and restrictive control evidence, not the active control store or an independent positive authority trust anchor. Positive authority requires current finalized PostgreSQL state and the current owner authorization path. An owner identity in a witness record records attribution; it is not cryptographic proof of owner authorization. S3 witness records alone cannot create acceptance, promotion, grants, consumable restoration, or disclosure. A restored PostgreSQL state is not proven current merely because it is internally consistent.

All buckets and objects deny public access. TLS and encryption at rest are required. SSE-S3 is the initial encryption authority; SSE-KMS needs separate future authority, and application-level encryption is not authorized. S3 versioning is required. The dedicated witness bucket also requires Object Lock in governance mode and Block Public Access. Separate-region private copies with a separate backup identity protect retained objects; the primary bucket is not its own backup. AWS-wide or account-wide unavailability denies canonical consumption. Provider-independent recovery is not required for the initial MVP.

The owner break-glass identity alone may bypass governance retention. Application identities cannot delete objects or versions in the witness bucket, bypass or shorten retention, change lock configuration or bucket policy, disable versioning, or overwrite records. Governance is defense in depth, not the sole protection. Object Lock protects versions, not a key from new versions or delete markers. Reject unexpected versions, delete markers, gaps, or forks. Recovery inspects version history, not only ordinary listings. Retention configuration must exceed the approved detection and recovery window and cannot allow required witness history to become disposable while its control history remains authoritative. The exact value and extension/monitoring procedure must be documented before implementation plan acceptance. Privileged changes are separately controlled and audited; if protection or history cannot be proven, fail closed.

## Access and credentials

Separate logical identities are OWNER, INGESTION_WRITER, PRIVATE_CONSUMER, BACKUP_OPERATOR, AUTHORITY_WITNESS_WRITER, and OWNER_BREAK_GLASS. Only OWNER authorizes acceptance, promotion, revocation, grants, retention disposal, and disclosure. Automation cannot accept, promote, revoke, grant itself access, change retention policy, or delete active release material. Ingestion reads only specifically authorized evidence and writes staging, verified candidate artifacts, and attempt/result facts. The witness writer appends only correctly authorized records and has no source-evidence access by default. Consumers read only their exact active release and safe control metadata; they cannot write the witness, delete blobs, read raw source evidence, or read other scopes. Backup and break-glass access are separately controlled and audited.

Credentials never enter Git, manifests, IR, logs, CI artifacts, or debug output. Use the verified deployment secret boundary, least privilege, distinct service identities, short-lived credentials where supported, rotation and revocation. On compromise revoke the identity, deny affected operations, investigate, and reissue only under owner authority. No shared long-lived human/service secret is permitted.

## Witness records and sequence

All witness-controlled decisions use one global ordered chain. At most one security decision is unresolved; a later COMMAND cannot reserve its sequence until the preceding decision reaches EFFECTIVE or ABORTED and PostgreSQL reconciliation is complete. PostgreSQL transactional serialization and uniqueness enforce this rule. No distributed lock or concurrent branch is authorized for the MVP.

Every event increments a contiguous sequence and uses `authority/v1/<zero-padded-witness-sequence>.json`. Conditional creation requires the current key to be absent; writes never replace a key. On an existing key, read and verify exact bytes, digest, version and protection. Identical bytes are an idempotent retry; any difference fails closed. After every write, read exact bytes, recompute SHA-256, and verify the expected version and Object Lock protection before considering the event durable. Do not treat a timeout as failure or success without inspecting the exact key and versions. An unexpected version or delete marker fails closed even if the current bytes match.

Each deterministic, versioned canonical record contains witness schema version, sequence, record type, decision ID, decision class and type, opaque target and applicable scope, policy version, safe reason code, previous record SHA-256, creation time, and the canonical safe decision payload or reconstruction fields. EFFECTIVE and ABORTED also bind the COMMAND record SHA-256 and decision identity; EFFECTIVE binds the deterministic prepared decision. Calculate record SHA-256 over canonical bytes excluding the record digest itself, and retain that digest externally without self-reference. The initial record types are exactly COMMAND, EFFECTIVE, and ABORTED. Records never contain source, SQL rows, ACSS values, Code or Query Editor bodies, execution signatures, credentials, private diagnostics, exception payloads, or absolute private paths.

COMMAND must contain enough safe data to reconstruct the exact recorded decision without a PostgreSQL row that could be lost with the database. For permissive commands this reconstructs historical evidence only; the attribution is not proof of authorization. Its safe versioned payload binds the exact target and scope, action, prior and target lifecycle identities/states, authorizing owner identity, policy and criteria references, decision and idempotency identities, and all safe guards and references needed for replay. Promotion and acceptance bind exact artifact, manifest, acceptance, source-version and scope identities as applicable; grant activation/revocation binds principal, scope, operations and validity; invalidation, revocation and quarantine bind their exact targets and effects. If safe reconstruction cannot be established without forbidden material, reject the command and stop: `WITNESS_RECORD_CANNOT_RECONSTRUCT_LOST_DECISION`. Reconciliation never invents missing facts or executes private source. Referenced retained objects and control history must be available and verified; otherwise consumption remains denied.

Restrictive transitions include acceptance invalidation and manifest invalidation, promotion revocation, effective canonical revocation, access-grant revocation, and artifact quarantine affecting consumption. Permissive transitions include acceptance, promotion activation, new grant activation, and restoration from quarantine that enables consumption. Ambiguous transitions default to restrictive until explicitly classified. Witness all transitions and policy changes whose loss could alter consumption eligibility, including their necessary prerequisites; otherwise a replay cannot claim completeness. New transition types require a versioned safe reconstruction contract before use.

## Restrictive decision protocol

1. An owner-authorized command carries decision ID, idempotency key, and payload. No success has been returned.
2. One PostgreSQL transaction validates the transition, reserves the decision and next COMMAND sequence with the expected prior digest, persists pending state, and activates a pending-deny barrier. Its commit is the local restrictive linearization point. Every new affected consumption authorization must observe the barrier.
3. Append COMMAND conditionally and verify its exact bytes, digest, version, and protection. A durable restrictive COMMAND must eventually be applied and cannot be automatically aborted.
4. In PostgreSQL verify the same decision and COMMAND, apply the canonical restrictive state, retain the denial, and mark it awaiting EFFECTIVE.
5. Append and verify EFFECTIVE referencing the COMMAND.
6. In PostgreSQL verify EFFECTIVE, complete the decision, advance the reconciled sequence and digest, and clear only redundant pending state. The restriction remains active. Return success only after this commit.

Before the pending transaction commits there is no durable decision and the caller may retry. After that commit but before COMMAND, PostgreSQL denies consumption; loss of PostgreSQL may lose this unacknowledged request. Retry with the same idempotency identity. The guarantee is zero **acknowledged** restrictive decision loss when the witness protocol is healthy, not zero initiated request loss. Acknowledged permissive history is durable when the witness protocol is healthy, but positive authority is not automatically recovered after control-state loss. Once COMMAND exists, recovery reconstructs and completes the restriction before reopening affected consumption. If EFFECTIVE exists but PostgreSQL completion is missing, reconstruct the restriction and reconcile. A lost response after completion returns the existing outcome on idempotent status lookup or retry, never a second decision.

## Permissive decision protocol

1. Receive an owner-authorized command and idempotency key. In PostgreSQL reserve the decision, COMMAND sequence and previous digest without changing visible eligibility.
2. Append and verify COMMAND. It records a claimed owner-authorized command; the record alone proves neither owner authorization nor consumability.
3. In PostgreSQL recheck guards and persist a deterministic prepared state. No active pointer, grant, or other consumer-visible eligibility is exposed. No other witness-controlled decision proceeds while unresolved.
4. Append and verify EFFECTIVE binding the exact COMMAND and prepared decision. This means the decision reached the effective witness phase. It does not authorize S3 alone to recreate consumable authority after PostgreSQL loss.
5. In one PostgreSQL transaction verify COMMAND, EFFECTIVE and the prepared identity, apply the consumer-visible state, update any active pointer, mark effective, and advance the reconciled sequence and digest. Return success only after commit.

Before COMMAND, retry without assuming an independently durable decision. COMMAND without EFFECTIVE is not effective and cannot authorize consumption. If the owner does not explicitly resume the same idempotent command before recovery finalization, append ABORTED and discard its prepared state. ABORTED is allowed only for a permissive COMMAND without EFFECTIVE; it binds that COMMAND and closes it without granting authority. A later request is a new decision, while an idempotent retry returns the aborted outcome. Never abort a witnessed restrictive command to restore availability.

If EFFECTIVE exists but the restored authoritative PostgreSQL state lacks the finalized permissive decision, recovery may record historical evidence only. It must not activate an acceptance, promotion, grant, or consumable restoration. Keep it non-consumable pending a new owner authorization with a new decision identity, linked to the historical decision for audit. The owner rechecks current manifest validity, acceptance criteria, artifact retention and integrity, source rights, compatibility, access scope, later restrictive witness history, and current policy, then uses the normal witness protocol. The caller may have lost its response; status lookup reports the historical outcome and recovery state. If restored PostgreSQL already contains the finalized permissive decision and the matching witness and all current guards agree, it may remain effective. If PostgreSQL says effective but the matching EFFECTIVE is absent, freshness is unproven and consumption is denied. No owner signing or KMS subsystem is introduced by this authority.

## Witness writer compromise

A compromised witness writer can fabricate a structurally valid record, including an attribution to the owner. It can create false restrictive records, sequence conflicts, or freshness failures and cause service denial. It cannot create positive authority through witness records alone. Recovery enforces a valid restrictive COMMAND even when it cannot distinguish a forged restriction from a legitimate one; the owner investigates before access can be restored under current authority. Availability is subordinate to authority safety. A future authority may consider owner-signed commands if automatic positive recovery becomes necessary.

## Startup, consumption, and restore gates

Every authorizer starts with freshness unproven and consumption denied. Access PostgreSQL and the witness, inspect version history for hidden replacements and delete markers, verify canonical bytes, every hash link, contiguous sequence, protection and the complete chain, then compare its latest event to PostgreSQL's reconciled sequence/digest and inspect pending state. The full-chain check is required for the initial low-frequency MVP; trusted checkpoints require future authority. Equality is necessary but not sufficient. A database behind the witness triggers fenced reconciliation; a database ahead, conflict, gap, unreadable object, unexpected version, delete marker, hash mismatch, or insufficient reconstruction data denies consumption and requires investigation. Never guess a winning chain.

Every **new** consumption authorization consults current transactional PostgreSQL state, not a process-local cache. It requires proven system freshness, no applicable pending deny, valid sealed manifest and acceptance, active unrevoked promotion, retained and consumable artifact, active scoped grant, and compatibility. Serialize the authorization check against the pending-deny transaction so an authorization ordered after its commit observes denial. If PostgreSQL or the freshness gate is unavailable, deny. Mediate delivery; stop further streaming where practical after restriction. A completed read before restriction is a historical output subject to owner withdrawal policy, not a new grant.

After PostgreSQL recovery, fence control writes and consumption in `AUTHORITY_VERIFICATION_REQUIRED`. Verify bucket protection and version history, reject unexpected versions and delete markers, validate the entire chain, compare state, replay and complete restrictive COMMANDs, abort unresolved permissive COMMANDs without EFFECTIVE unless explicitly resumed, and record permissive EFFECTIVE decisions missing from restored PostgreSQL as historical evidence without activating them. After reconciliation, release the control-write fence only for the normal owner authorization path; affected positive decisions remain non-consumable. Require a new owner authorization for each positive decision whose finalized PostgreSQL state was lost. Verify manifests, acceptances, promotions, revocations, grants, and required artifact digests; persist the reconciled latest sequence/digest before proving freshness and reopening. Any missing witness, reconstruction field, current authority, or integrity evidence leaves `AUTHORITY_FRESHNESS_UNPROVEN` and consumption denied. A privileged actor or account failure that can conceal or destroy witness history is outside application-identity protection; detect uncertainty and fail closed rather than infer freshness from a shorter chain.

## Retention, backup, and audit

Staging expires 48 hours after terminal attempt or lease expiry, never while demonstrably active. Failed temporary evidence is retained at most 30 days unless an owner hold applies. Source evidence retention is rights-specific. Disposal may set reproducibility unavailable. IR and sealed manifests remain through active lifetime plus a 90-day rollback window after the final active/rollback dependency ends, or longer under hold. Physical disposal requires owner authority and a transactional dependency recheck. Active release dependencies cannot be disposed. Control decision history lasts for service lifetime; post-service disposal requires a separate owner retirement decision. Witness history lasts at least as long as the control history it proves. Online audit retention is one year, extendable by owner hold; this is an operational default, not a compliance claim. Cleanup handles orphan staging, interrupted uploads and backups without deleting held or active dependencies.

Require PostgreSQL PITR with continuous WAL archive and daily base backup. Daily verification checks backup integrity, decryption, and coverage; it does not require a full restore every day. Require a separate-region verified protected copy of retained objects and a separate backup identity. Protect promoted artifacts before promotion so the copy objective is not bypassed. Exercise full restore and witness freshness quarterly and after material recovery changes. Encrypt backups, restrict access, verify copies and restore digests, and apply owner-approved retention and orphan cleanup. Object-store durability does not replace backup, and PostgreSQL backups do not contain blob bytes.

Initial cold-path objectives are zero acknowledged restrictive decision loss when the witness protocol is healthy, durable acknowledged permissive history when the protocol is healthy, no automatic positive-authority recovery after control-state loss, control-state RTO 24 hours, artifact RPO 24 hours and RTO 48 hours, evidence RPO 24 hours and RTO five days. These are targets, not availability guarantees. If freshness cannot be proven within the target, the service remains closed. AWS provider failure independence is not required for the initial MVP; database restore failure-domain independence is required.

Private append-only audit records contain actor/service principal, operation, opaque resource identity, policy version, prior and new state, safe reason code, timestamp, idempotency identity and applicable witness decision identity. Corrections append; they do not rewrite. Exclude private source, ACSS values, executable bodies, signatures, credentials, raw exception payloads and absolute private paths. Provision CloudTrail S3 data events or equivalent provider audit for witness and protected blob operations. Audit backups and access follow private policy.

## Implementation boundary

```text
IMPLEMENTATION_AUTHORIZED=NO
AWS_RESOURCES_CREATED=NO
POSTGRES_SCHEMA_CREATED=NO
DEPENDENCIES_ADDED=NO
MIGRATIONS_CREATED=NO
STORAGE_ADAPTER_CREATED=NO
PRIVATE_INGESTION_RUN=NO
PRIVATE_RELEASE_PROMOTED=NO
PUBLIC_DISCLOSURE_AUTHORIZED=NO
COMPONENTIZATION_AUTHORIZED=NO
```

No private source, manifest, IR, evidence, or credentials enter this repository or CI. This proposal does not authorize an implementation plan or any private release operation. Final review and acceptance of this document, concrete resource configuration, and separate authorization precede implementation.
