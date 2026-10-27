# Bricks canonical ingestion runtime and deployment authority

**Status:** Owner-approved architecture recorded for review and merge. This document does not authorize implementation or provisioning, and is not evidence that any deployment exists. It supplements the [execution-security metadata retention authority](bricks_execution_security_metadata_retention_authority.md), [private release authority](bricks_canonical_ingestion_private_release_authority.md), and [storage and operations authority](bricks_canonical_ingestion_storage_operations_authority.md). Their restrictions and implementation prerequisites continue to apply.

```text
CONTROL_PLANE_APP=apps/live_frames_canonical_control
EXECUTION_MODEL=ON_DEMAND_MANAGED_AWS_TASK
AWS_EXECUTION_PROVIDER=ECS_FARGATE
ALWAYS_ON_SERVICE=NO_FOR_MVP
PRIMARY_AWS_REGION=af-south-1
BACKUP_AWS_REGION=eu-west-1
PRIMARY_PRIVATE_OBJECT_STORE=AMAZON_S3
AUTHORITY_WITNESS_STORE=AMAZON_S3_SEPARATE_PRIVATE_BUCKET
BACKUP_OBJECT_STORE=AMAZON_S3_SEPARATE_REGION_PRIVATE_COPY
POSTGRES_PROVIDER=AMAZON_RDS_FOR_POSTGRESQL
POSTGRES_ISOLATION=DEDICATED_CANONICAL_CONTROL_DATABASE
RDS_PUBLIC_ACCESS=DENY
TLS_REQUIRED=YES
PITR_REQUIRED=YES
AWS_APPLICATION_CREDENTIAL_MODEL=ECS_TASK_ROLE_SHORT_LIVED_CREDENTIALS
DEPLOYMENT_SECRET_STORE=AWS_SECRETS_MANAGER
OBJECT_LOCK_MODE=GOVERNANCE
OBJECT_LOCK_DEFAULT_RETENTION=365_DAYS
OBJECT_LOCK_REVIEW_INTERVAL=QUARTERLY
PUBLIC_HTTP_ENDPOINT=NO
ALWAYS_ON_API=NO
LIVE_FRAMES_LIBRARY_INFRASTRUCTURE_INDEPENDENT=YES
PREVIEW_APP_NOT_CONTROL_PLANE=YES
AUTHORIZED_ARTIFACT_DELIVERY_MECHANISM_REQUIRED_BEFORE_CONSUMER_PHASE=YES
IMPLEMENTATION_AUTHORIZED=NO
INFRASTRUCTURE_PROVISIONING_AUTHORIZED=NO
PHASE_0_PROVISIONING_AUTHORIZED=NO
```

## Application and execution boundaries

A future dedicated OTP application at `apps/live_frames_canonical_control` owns the PostgreSQL Repo, canonical lifecycle persistence, S3 adapters, witness protocol, access authorization, retention, recovery, audit, owner commands, and deployment configuration. It may depend on `apps/live_frames` for approved conversion and domain functionality. The dependency must never run in the reverse direction. `apps/live_frames` remains the reusable design compiler and UI library; it does not own the Repo, AWS credentials, release persistence, witness reconciliation, owner control or deployment secrets. Pure domain structures may be extracted later only under an approved implementation plan. `apps/live_frames_preview` remains the preview and storybook app and does not hold private source or production control credentials.

Use explicitly authorized, on-demand ECS Fargate tasks for bounded control commands, including future ingestion, verification, acceptance, promotion, revocation, consumption authorization, recovery, audit and retention operations. This document defines no CLI syntax. It authorizes no public endpoint, always-on API, inbound internet traffic, ALB, API Gateway or dashboard. A task uses an Elixir release in a container image from Amazon ECR. Release tags must be immutable, and provenance-sensitive runs must record and use the exact image digest. A run whose image identity cannot be proved is not accepted for provenance-sensitive work.

AWS documents Fargate on-demand quotas in Cape Town and VPC networking and task roles for Fargate. Its conventional Lambda function timeout is 15 minutes, making Lambda a less suitable initial fit for potentially longer bounded ingestion or recovery; AWS also documents longer limits for certain managed-instance invocations. The choice does not imply unlimited runtime or remove the need for task time and resource bounds. See [ECS quotas](https://docs.aws.amazon.com/general/latest/gr/ecs-service.html), [Fargate task networking](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-task-networking.html), [task IAM roles](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html), and [Lambda quotas](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html).

## Network, database and secrets

Attach the control task to a VPC, preferably in private application subnets. Place RDS in private database subnets with public access disabled. Security groups allow only the required PostgreSQL path from authorized task identities, and database connections require TLS. Choose an S3 gateway endpoint and, where useful, interface endpoints for ECR, CloudWatch Logs and Secrets Manager, or a narrowly scoped NAT path when that is simpler. Verify the complete image-pull and logging paths, including ECR image-layer access to S3. Do not record VPC or subnet identifiers as authority. Endpoint availability, networking and cost must be verified during provisioning.

Use a dedicated LiveFrames-only canonical control database on RDS for PostgreSQL. Do not assume reuse of EventSales, FastCheck or any unrelated database. Cross-project reuse requires separate owner authority. Require private connectivity, TLS, continuous WAL backup and daily base backup, PITR, backup integrity and coverage verification, separate recovery failure-domain protection, and quarterly restore exercises as required by the storage authority. Use a dedicated least-privilege service database credential with clear ownership, rotation and recovery. RDS IAM database authentication is not required for the initial deployment.

AWS Secrets Manager is the deployment secret store for database credentials and any other actual deployment secrets. Prefer ECS-supported secret injection at task start with permission to retrieve only the named secret; the application must not enumerate secrets. Use separate service credentials, never shared human credentials. AWS access uses short-lived ECS task-role credentials, not static access keys. Separate the ECS execution role, task roles, witness-writer permission set, backup role and owner break-glass role. Region names, safe bucket references and retention settings are non-secret deployment configuration; do not treat them as credentials. No secret belongs in Git, fixtures, manifests, IR, logs, snapshots or CI artifacts. Restrict task-definition and runtime inspection because injected secrets may be visible to privileged operators and processes.

AWS lists [RDS for PostgreSQL in Cape Town](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RDS_Fea_Regions_DB-eng.Feature.MultiAZDBClusters.html), a [Secrets Manager endpoint](https://docs.aws.amazon.com/general/latest/gr/asm.html), and [RDS point-in-time recovery](https://docs.aws.amazon.com/AmazonRDS/latest/gettingstartedguide/managing-backup-restore.html). This does not prove a particular account, instance, backup configuration or restore is ready.

## Service identities

- **OWNER** is the human authorization identity for acceptance, promotion, revocation, access grants, retention disposal and any separately authorized disclosure. It is not a routine application credential.
- **INGESTION_WRITER** reads specifically authorized source evidence, writes staging and immutable candidate blobs, and records ingestion facts. It cannot accept, promote, revoke, grant access, bypass governance or delete witness history.
- **PRIVATE_CONSUMER** requests a specific approved release through the control-plane authorization path. It has no broad S3 listing, arbitrary blob access, source-evidence read, witness write, object deletion or governance bypass. Direct storage access must not bypass the transactional gate.
- **BACKUP_OPERATOR** has only the copy and recovery permissions required by policy, with no ability to create positive canonical authority.
- **AUTHORITY_WITNESS_WRITER** appends correctly constructed witness records. It cannot mint positive authority, read raw source by default, delete witness versions, bypass governance, change bucket policy or grant itself permissions. A witness alone never establishes positive authority.
- **OWNER_BREAK_GLASS** is a separately audited human emergency role with strong authentication and MFA and an explicit use procedure. It is not an application credential. If governance bypass is provisioned, only this role may hold it.

Map these logical boundaries to separately scoped task roles, database privileges and human roles in Phase 0. Do not combine them into a broad application principal. Owner authorization remains distinct from a task's technical ability to perform an operation.

## Object storage and retention

Use three logical, private, versioned buckets. The primary blob and separate witness buckets are in `af-south-1`; the separate protected backup bucket is in `eu-west-1`. Block public access, require TLS and encryption at rest, and retain the accepted initial SSE-S3 encryption authority. Deployment-specific bucket names are configuration, not repository authority. Verify copied bytes, protection and retention semantics. A backup copy is required before promotion of an artifact. If S3 replication copies Object Lock objects, the destination must also have Object Lock enabled; replication is asynchronous and must not be treated as proof of a completed backup. AWS documents [cross-region replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html) and its [Object Lock destination requirement](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-requirements.html).

Staging uses the primary blob bucket under a separately constrained `staging/` prefix, with opaque temporary keys that cannot be confused with retained content. Expire staging 48 hours after terminal attempt or lease expiry, never during a demonstrably active lease or applicable hold. Retained keys use `<artifact-class>/<algorithm>/<digest>` and witness records use `authority/v1/<zero-padded-sequence>.json`. Keys must not contain private bodies, filesystem paths, credentials, execution signatures, Code or Query Editor bodies, or unreviewed customer or site identities. Content identity alone is not access authority.

The witness bucket uses Object Lock Governance mode with a 365-day default and quarterly review. This is an operational safety default, not a regulatory claim. A future monitor and operational procedure must identify each witness version approaching expiry and extend its retention before expiry while the version remains required by authoritative control history. Expiry does not authorize deletion. Application identities cannot shorten or bypass retention, delete witness versions, overwrite records, alter policy or disable versioning. Governance protects object versions, not against unexpected versions or delete markers: the accepted witness verification and fail-closed recovery rules still apply. See [S3 Object Lock](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html).

## Consumer, freshness and failure boundaries

An authorized invocation starts a canonical-control task. The task proves witness freshness, checks the transactional PostgreSQL eligibility and pending-deny gate, identifies the exact retained artifact, verifies its digest and performs a bounded authorized consumption operation. The future implementation plan must specify how the artifact reaches an approved downstream consumer without arbitrary bucket access. This unresolved delivery mechanism blocks the consumer-delivery phase, not later authorized foundational schema or witness work.

New authorization fails closed when RDS is unavailable. An unavailable witness leaves freshness unproven and denies new authorization. Unavailable AWS services or secrets cause the affected control task to fail closed. Recovery cannot reactivate a revoked promotion or recreate positive authority from a permissive witness alone. Availability never overrides authority safety. Ordinary logs may use CloudWatch Logs but must exclude private source, ACSS values, Code and Query Editor bodies, execution signatures, credentials and raw private exception payloads. Use opaque identities and safe reason codes. Private audit records remain distinct from operational logs.

Redis, Cachex and PubSub are not required. A GenServer is not durable authority. OTP processes may exist, but process memory or a cache cannot decide authorization or replace PostgreSQL and the witness.

## Phase 0 and acceptance evidence

`PHASE_0=CANONICAL_CONTROL_INFRASTRUCTURE_PROVISIONING_AND_VERIFICATION` is a future, separately authorized infrastructure lane. It covers the owner-controlled account and billing boundary, both regions, VPC and private network paths, ECS/Fargate, ECR, S3 and Object Lock, IAM roles, Secrets Manager, RDS and PITR, separate-region protected copies, CloudTrail data-event or equivalent audit, and operational monitoring. It must verify the selected account supports the required services, permissions, quotas and region opt-in, and verify the owner-approved billing. No account number, secret value, access key, password or unnecessary private ARN belongs in public evidence.

Safe Phase 0 evidence must establish all of the following, without disclosing secrets:

```text
OWNER_CONTROLLED_AWS_ACCOUNT_REQUIRED=YES
AWS_ACCOUNT_VERIFICATION_REQUIRED_BEFORE_PROVISIONING=YES
AWS_BILLING_APPROVAL_REQUIRED_BEFORE_PROVISIONING=YES
AWS_ACCOUNT_OWNER_VERIFIED=YES
PRIMARY_REGION=af-south-1
BACKUP_REGION=eu-west-1
FARGATE_EXECUTION_VERIFIED=YES
RDS_PRIVATE_ACCESS=YES
RDS_TLS=YES
RDS_PITR=YES
S3_PUBLIC_ACCESS_BLOCK=YES
S3_VERSIONING=YES
WITNESS_OBJECT_LOCK=GOVERNANCE
WITNESS_DEFAULT_RETENTION=365_DAYS
APPLICATION_CAN_BYPASS_GOVERNANCE=NO
TASK_ROLE_SHORT_LIVED_CREDENTIALS=YES
SECRET_BOUNDARY_VERIFIED=YES
BACKUP_COPY_REGION=eu-west-1
```

Evidence must also demonstrate scoped identities, the renewal monitor, protected copies and restore tests, rather than asserting them from configuration alone. Merging this authority does not authorize Phase 0 or application implementation. The infrastructure prerequisites required by the storage authority remain mandatory before implementation. A separate owner authorization is required for each future phase. No private ingestion, promotion, disclosure or componentization is authorized by this document.
