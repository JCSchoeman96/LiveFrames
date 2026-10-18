# Source Node Disposition Architecture

**Status:** Proposed for architectural review; not implementation authority.

This specification defines a narrow, source-neutral authority for excluding a
reviewed source-runtime carrier from generated structure while retaining it in
Design IR. It does not authorize implementation. The exact accepted-base state
for this proposal is:

    BASE_SHA=7d905f67575fab3aa22e3ed2e9eb53a75f2b2c53
    BASE_TREE=67a185cc558a8eafc0248cbba061449847d52315
    BASE_CI_RUN=39098261911
    BASE_CI_RESULT=success

## 1. Goal and decision

> LiveFrames must preserve unsupported/source-specific runtime constructs as
> inert Design IR evidence while allowing a reviewed componentization pipeline
> to omit only those source nodes whose runtime responsibility has been replaced
> by an exact approved source-neutral BehaviorContract.

The authority preserves both invariants:

    UNAUTHORIZED_UNSUPPORTED_NODE=FAIL_CLOSED

    AUTHORIZED_SOURCE_RUNTIME_CARRIER=
      EVIDENCE_PRESERVED
      + NOT_RENDERED
      + SOURCE_RUNTIME_NOT_EXECUTED
      + SOURCE_RUNTIME_NOT_COPIED

Adopt this explicit flow:

    SemanticInput.SourceNodeDispositionDecision
            ↓
    ComponentizationProposer validation
            ↓
    ComponentizationPlan.NodeDisposition
            ↓
    ComponentizationPlan reference/generation validation
            ↓
    ComponentReview of the exact plan
            ↓
    Native generation using validated omission semantics

The DesignDocument remains the evidence source and is never edited to make a
plan pass. The mechanism is generic: it has no source-system, element-name,
site, or project allowlist.

## 2. Existing authority and blocker

ComponentizationPlan 1.0.0 currently defines this behavior:

    raw | unsupported | unknown node
    inside selected boundary
    → componentization_plan.unsupported_node
    → generation ineligible

The validator indexes every such node inside the selected boundary directly
from the DesignDocument and emits the blocker. Its authority says that
structured exclusions require later authority. SemanticInput has no
source-node-disposition decision family. No structured field currently
authorizes an exclusion.

This proposal does not weaken the 1.0.0 rule. In 1.1.0, an unsupported node
continues to block unless one exact, valid, reviewed NodeDisposition targets
it. Invalid, stale, missing, duplicate, or unused disposition data fails
closed. Arbitrary provenance and metadata remain non-authoritative.

## 3. Motivating evidence: Feature Milan

Milan is the first evidence-backed example, not a special case in the design:

    DESIGN_DOCUMENT_DIGEST=
    1fdc6e859bdb624f0931106f78a46b25baae89f807b6bfc7ba3e14ee79da1045

    BEHAVIOR_BINDING_ID=
    bnd_fd4b72a566b2c38f00f5396bfc0f2c26453d49a1c19290dfe9dec2a67ee78fe4

    BEHAVIOR_CONTRACT_DIGEST=
    5d2b37acbfa357a66357bf7ea09ce21f15353702d85a5d202f275dcb6794a344

    BEHAVIOR_REVIEW_ID=
    brv_d19b80b64c3e3281a42ae6763ea95877b45e2728c9a29f89a220777e8b45d2dd

    DESIGN_NODE_ID=node_000001_000002
    SEMANTIC_TYPE=unsupported
    SOURCE_TYPE=bricks_element
    SOURCE_ID=2265d2
    SOURCE_NAME=code
    SOURCE_RUNTIME_CARRIER=YES
    SOURCE_RUNTIME_CATEGORY=script
    INDEPENDENT_PRESENTATION_REQUIREMENT=NO
    INDEPENDENT_CONTENT_REQUIREMENT=NO
    INDEPENDENT_ACCESSIBILITY_REQUIREMENT=NO
    GENERATED_DOM_REQUIREMENT=NO
    BEHAVIOR_REFERENCE_INSIDE_NODE=NO

The accepted selection@1.0.0 BehaviorContract owns the source-neutral
selection behavior with alignment=position, advance_boundary=wrap, and timer
purpose=advance_selection, interval_ms=5000, start=on_initialization,
manual_activation=stop, restart=never, reset=none, and
reduced_motion=disable_automatic_advance. The source script remains inert
evidence. Do not publish, copy, translate, or execute it. This example does
not make 2265d2, code, Milan, or Bricks an authorization key.

## 4. Terms and authority boundary

**Evidence boundary membership** is membership in the original DesignDocument
subtree rooted at ComponentizationPlan.boundary_node_id. A disposed node
remains in that subtree and retains its parentage, SourceTrace, and all other
IR evidence.

**Generated-structure membership** is membership in the filtered structural
view supplied to native generation. A valid disposition removes exactly its
target node from this view. Under the initial outcome, the target must be a
leaf; the authority does not define subtree removal or child hoisting.

**Source runtime carrier** is a source node whose runtime evidence is inert in
Design IR, whose relevant behavior responsibility is covered by the exact
reviewed BehaviorContract, and which has no separately required generated
presentation, content, accessibility, or DOM role.

**Disposition authority** is the conjunction of the structured SemanticInput
decision, a durable plan record, exact Behavior authority references, and an
approved ComponentReviewResult bound to the canonical bytes of the approved
ComponentContract, encoded plan, and DesignDocument. No one part is sufficient
on its own.

## 5. SemanticInput decision

Add the repeatable family source_node_dispositions with the closed decision
shape:

    SourceNodeDispositionDecision
      design_node_id: non-empty string
      outcome: :exclude_source_runtime_carrier
      behavior_binding_id: non-empty string
      evidence_refs: non-empty list of unique non-empty strings

The initial closed outcome set contains only
:exclude_source_runtime_carrier. Do not add ignore, exclude, safe,
unsupported_but_ok, or drop.

evidence_refs is part of canonical SemanticInput state, not provenance-only
metadata. It is a list of opaque references for human review, not a description
that can grant authority. Canonicalize it in ascending Unicode-scalar order
and reject duplicate references. Canonicalize the decision family by
design_node_id; reject a repeated target. SemanticInput remains ephemeral
and has no persistence or serialization API. It cannot itself authorize
generation.

The proposer derives source_type, source_id, the BehaviorContract digest,
and BehaviorReview ID from the exact input authorities. Callers cannot supply
those durable identity fields in SemanticInput.

## 6. Durable plan model

Add ComponentizationPlan.NodeDisposition and a top-level node_dispositions
array to plan format 1.1.0. The exact closed wire schema for each entry is:

    design_node_id             string
    disposition                "exclude_source_runtime_carrier"
    source_type                non-empty string
    source_id                  non-empty string
    behavior_binding_id        non-empty string
    behavior_contract_digest   64 lowercase hexadecimal characters
    behavior_review_id         "brv_" followed by 64 lowercase hexadecimal characters
    evidence_refs              non-empty array of unique non-empty strings

No additional fields are permitted. In particular, do not serialize a source
name, path, classes, settings, raw payload, script, copied Behavior semantics,
free-form metadata, or Boolean claims that bypass review.

| Field | Why required | Who validates it | When | Serialized | Plan identity input |
| --- | --- | --- | --- | --- | --- |
| design_node_id | Identifies one IR node within the document digest | Proposer and plan reference validator | Construction and generation | Yes | Yes |
| disposition | Selects the one closed policy | Intrinsic validator, proposer, and generator gate | All phases | Yes | Yes |
| source_type | Binds the disposition to the node's SourceTrace source family | Proposer and generation reference validator | Construction and generation | Yes | Yes |
| source_id | Detects a changed or substituted SourceTrace identity | Proposer and generation reference validator | Construction and generation | Yes | Yes |
| behavior_binding_id | Names the exact binding whose approved semantics replace the source runtime responsibility | Proposer and generation authority validator | Construction and generation | Yes | Yes |
| behavior_contract_digest | Binds the exact complete BehaviorContract | Proposer and generation authority validator | Construction and generation | Yes | Yes |
| behavior_review_id | Binds the exact approved BehaviorReviewResult | Proposer and generation authority validator | Construction and generation | Yes | Yes |
| evidence_refs | Preserves review evidence pointers without granting authority | SemanticInput canonicalizer, ComponentReview, and plan validator | Construction, review, and generation | Yes | Yes |

The plan-level design_document_sha256 scopes design_node_id; the repeated
source identity is a consistency guard, not a replacement for the document
digest. The exact encoded plan bytes, including this array and its evidence
references, participate in the plan fingerprint. There is no separate plan ID
field.

The exact plan serialization contains the existing 1.0.0 fields plus
node_dispositions for 1.1.0. The field is present in 1.1.0 even when the
array is empty. It is absent from every 1.0.0 serialization.

## 7. Ordering and uniqueness

Sort node_dispositions by ascending UTF-8 design_node_id byte order, which
is the repository's deterministic string ordering. Sort each evidence_refs
list by ascending Unicode-scalar order. Reject duplicate
design_node_id dispositions, even if the entries otherwise match. There is
one effective disposition per node. Reject duplicate evidence references.

Plan encoding uses deterministic JSON object-key ordering. List order is
explicit and identity-significant after canonicalization. A caller's input
order does not change canonical SemanticInput or a newly constructed plan.

## 8. Plan format version decision

Repository inspection found:

    PLAN_AUTHORITY=docs/development/c09d3_componentization_plan_authority.md §17
    UNSUPPORTED_NODE_AUTHORITY=docs/development/c09d3_componentization_plan_authority.md §11
    FORMAT_VERSIONING_PRECEDENT=docs/development/c09d1_component_contract_authority.md §19

    CURRENT_FORMAT_VERSION=1.0.0
    VERSIONING_RULE_FOUND=Plan SemVer over serialized shape; no Plan-specific
      patch/minor/major mapping. The separate ComponentContract format authority
      defines an explicit repository precedent.

    NEW_FORMAT_VERSION=1.1.0

The Plan authority establishes that its format version follows SemVer over
serialized shape, but it does not map changes to patch, minor, or major. The
ComponentContract authority is a separate artifact authority; its explicit
format-only precedent is representation-preserving corrections as PATCH,
backward-compatible optional fields/capabilities as MINOR, and incompatible
shape/meaning or required migration as MAJOR. There is no conflicting
versioning rule. This specification closes the Plan-specific gap by adopting
that same format-only mapping for ComponentizationPlan.

Under that adopted rule, 1.1.0 is correct: the new field is required in the
1.1.0 schema but is an additive capability across versions, and an updated
reader preserves 1.0.0 as an empty disposition list with historical semantics.
1.0.0 would falsely claim the same serialized shape. 2.0.0 would be required
if an old field or meaning changed, a 1.1 reader could not read 1.0.0, or a
mandatory migration were required. None applies here. The ComponentContract
artifact remains a precedent, not the authority for Plan compatibility.

The current 1.0.0 validator accepts only 1.0.0 and rejects 1.1.0 as
componentization_plan.version.unsupported. The repository currently has no
ComponentizationPlan from_map/decode API. A future 1.1.0 reader must accept
the exact historical 1.0.0 schema and interpret its absent disposition list
as empty. An old 1.0.0 implementation is not required to read a 1.1.0
plan; it fails closed at its version gate.

    CURRENT_FORMAT_VERSION=1.0.0
    VERSIONING_RULE_FOUND=Plan SemVer for serialized shape; mapping adopted
      from existing format-only repository precedent in this spec
    NEW_FORMAT_VERSION=1.1.0
    WHY=additive capability under adopted format-only SemVer mapping; 1.0.0 meaning unchanged
    OLD_1_0_0_READER_BEHAVIOR=rejects 1.1.0; no decode API exists at base
    OLD_1_0_0_PLAN_VALIDITY=unchanged; unsupported nodes still block
    MIGRATION_REQUIRED=NO; reissue-only for a plan using the new capability

No migration edits an existing plan. A plan that needs an exclusion is newly
proposed/reissued under 1.1.0; a historical 1.0.0 artifact remains
byte-for-byte immutable and has its original semantics.

## 9. Trust boundary and exact review binding

### 9.1 What proposal construction proves

The proposer must validate all mechanically decidable facts against the exact
validated DesignDocument and supplied authority tuple:

1. Recompute design_document_sha256; require it to match the plan identity.
2. Require the target to exist, lie within the selected boundary, have
   semantic_type raw, unsupported, or unknown, and have no children.
3. Require SourceTrace and copy its exact non-empty source_type and
   source_id into the plan. A missing trace or identity mismatch blocks.
4. Require no behavior reference to the target, from the target, or within its
   disposed subtree. This includes Behavior owners, controlled targets,
   trigger origins, focus references, and relevant IR interaction references.
5. Require the named BehaviorBinding to exist exactly once in the supplied
   BehaviorContract. Require the contract's DesignDocument identity to match
   the exact document.
6. Require one explicitly selected BehaviorReviewResult. Compute its ID and
   require an exact match with the decision's review authority. Validate that
   singleton against the supplied BehaviorContract using the existing
   Behavior.ReviewResult.require_approved/2 rule. Recompute and store the
   BehaviorContract digest and selected review ID.
7. Require non-empty evidence references and construct the disposition only
   from the validated decision. No provenance field may substitute for one.

The proposer cannot establish from identifiers alone that source runtime
responsibility is semantically covered, or that the source node has no
independently required presentation, content, accessibility, or generated-DOM
role. Those are review judgments. Until reviewed, the constructed plan is only
a candidate and is not generation authority.

### 9.2 ComponentReview authority

For any plan with a non-empty node_dispositions array, ComponentReview must
review the exact plan bytes, DesignDocument, ComponentContract, cited evidence,
and the exact Behavior authority tuple. It must reject or require further
evidence if any independent role may be required, if the BehaviorContract does
not own the corresponding runtime responsibility, or if a source runtime would
need to be copied or executed.

The current ComponentReview.approve/3 changes only
ComponentContract.approval_status; it does not bind approval to a plan
fingerprint. A disposition-bearing plan therefore also requires a structured
ComponentReviewResult, with this closed review-time shape:

    review_format_version        "1.0.0"
    component_contract_id        non-empty string
    component_contract_digest_algorithm  "sha-256"
    component_contract_digest            64 lowercase hexadecimal characters
    design_document_sha256       64 lowercase hexadecimal characters
    componentization_plan_digest_algorithm  "sha-256"
    componentization_plan_digest            64 lowercase hexadecimal characters
    decision                     "approved" | "needs_review" | "rejected"
    reviewer_identity            non-empty string
    reviewed_at                  UTC timestamp in YYYY-MM-DDTHH:MM:SS.ffffffZ form
    evidence_refs                non-empty array of unique non-empty strings

component_contract_digest is lowercase SHA-256 of the exact UTF-8 bytes
returned by LiveFrames.ComponentContract.encode/1 for the approved contract.
The hash input MUST have approval_status=:approved. Hash the resulting
approved contract, not the pre-review candidate: approval_status is serialized
and therefore changes the canonical bytes. component_contract_id remains the
stable semantic identity and is not a content digest.

componentization_plan_digest is lowercase SHA-256 of the exact UTF-8 bytes
returned by ComponentizationPlan.encode/1. Define canonical serialization as
the canonical JSON encoding of exactly these fields, with deterministic object
keys and evidence_refs sorted by ascending Unicode-scalar order; duplicate
references are invalid. Both digest algorithm fields are the literal
sha-256. review_format_version is the literal 1.0.0. The derived,
non-serialized identity is:

    COMPONENT_REVIEW_ID_ALGORITHM=lf-component-review-v1-jcs-sha256
    COMPONENT_REVIEW_ID=crv_ + lowercase SHA-256 of canonical encoded result bytes

The successful ComponentReview transition is one atomic authority operation:

    proposed ComponentContract
    + exact ComponentizationPlan
    + exact DesignDocument
    + review evidence
            ↓
    validate candidate and review guards
            ↓
    derive approved ComponentContract
            ↓
    encode that approved contract and derive component_contract_digest
            ↓
    create ComponentReviewResult binding approved contract, plan, and document
            ↓
    return and retain the approved contract with its matching review result

The result is a durable structured review artifact, not a plan field,
provenance text, or BehaviorContract. ComponentReview creates it only after
the exact plan review and retains it beside the approved contract and plan.
Generation receives one explicitly selected ComponentReviewResult and its
derived-ID selector. It recomputes the ID from canonical result bytes and
requires it to equal that selector, then requires decision="approved" plus
the exact approved contract digest, plan digest, and document digest. The
contract ID is checked as an additional semantic-identity consistency guard;
it is not used as the exact contract identity. Generation does not search a
result history or select by timestamp. A result for a changed contract, plan,
or document does not authorize generation. Repeated reviews have distinct
content IDs; the caller must name the exact result to use, and that result
must still match the supplied approved contract, plan, and document.

This result records the review workflow's decision; its digest binding is not
a digital signature or proof of reviewer authentication. Authentication of
the human reviewer remains the responsibility of the existing review
workflow. The structured plan and identity checks prevent accidental or stale
cross-plan reuse and do not claim protection from a malicious trusted
reviewer.

### 9.3 What generation revalidates

Generation must receive these exact values:

    ComponentizationPlan
    approved ComponentContract
    DesignDocument
    BehaviorContract
    one explicitly selected BehaviorReviewResult
    one explicitly selected ComponentReviewResult and its derived-ID selector

Generation does not accept a BehaviorReviewResult collection. The caller
supplies the selected result; generation does not search review history or
choose a result by timestamp or recency.

It revalidates, rather than trusting a previous proposer pass:

    plan format and closed schema
    exact plan digest, DesignDocument digest, and approved ComponentContract digest
    ComponentContract.approval_status=approved
    selected component review contract digest algorithm is sha-256
    SHA256(ComponentContract.encode(supplied_approved_contract))
      == ComponentReviewResult.component_contract_digest
    supplied_contract.contract_id == ComponentReviewResult.component_contract_id
    selected component review plan digest algorithm is sha-256
    SHA256(ComponentizationPlan.encode(supplied_plan))
      == ComponentReviewResult.componentization_plan_digest
    selected component review document digest equals the supplied DesignDocument digest
    boundary, node ID, semantic type, SourceTrace type and source ID
    no behavior reference to the target/subtree
    exact BehaviorBinding ID and BehaviorContract digest
    Behavior.ReviewResult.id(selected_behavior_review)
      == NodeDisposition.behavior_review_id
    Behavior.ReviewResult.require_approved([selected_behavior_review], supplied_behavior_contract)
    ComponentReviewResult.id(selected_component_review_result)
      == selected_component_review_result_id
    selected component review decision is approved
    selected component review contract ID equals the supplied contract's contract_id
    the target is consumed exactly once by generated-structure filtering

Any changed DesignDocument, node, SourceTrace, behavior binding, contract,
review result, plan, or review result identity makes the authority stale and
blocks. A modified ComponentContract fails its canonical digest check even if
it retains the same contract_id. Human review findings about independent roles
remain frozen by the approved exact-plan review result; changing the
node/document changes the plan or document digest and requires review again. A
forged plan with no matching approved plan review is ineligible, even if its
JSON is well-formed.

No source runtime payload, decision prose, or source metadata is interpreted as
a grant of authority.

## 10. Lifecycle and state transitions

These are workflow states, not fields serialized into ComponentizationPlan.
The plan retains its existing valid/invalid model and has no approved lifecycle.

| State or transition | Guards | Side effects and result |
| --- | --- | --- |
| UNCLASSIFIED | Source node is present in a validated DesignDocument | None; it remains evidence |
| UNCLASSIFIED → EVIDENCE_PRESERVED | Normalization produced the node and SourceTrace | Preserve the original node, ancestry, source identity, and diagnostics in IR |
| EVIDENCE_PRESERVED → CLASSIFIED_SOURCE_RUNTIME_CARRIER | Explicit decision, evidence refs, exact supported Behavior authority; mechanical proposal guards pass | Candidate disposition is added to a new plan; source node remains in IR |
| CLASSIFIED_SOURCE_RUNTIME_CARRIER → APPROVED_FOR_GENERATED_STRUCTURE_EXCLUSION | ComponentReview approves the exact plan and emits one matching ComponentReviewResult | Preserve the approved contract and plan with the content-ID-verified review result binding exact plan/document/approved-contract digests |
| APPROVED_FOR_GENERATED_STRUCTURE_EXCLUSION → EXCLUDED_FROM_GENERATED_STRUCTURE | Generation revalidates all identities and guards | Filter exactly the target from generated structure; preserve it in Design IR and SourceTrace |

Blocked terminal states are:

    BLOCKED_REQUIRED_PRESENTATION
    BLOCKED_REQUIRED_CONTENT
    BLOCKED_REQUIRED_ACCESSIBILITY
    BLOCKED_BEHAVIOR_REFERENCE
    BLOCKED_BEHAVIOR_REVIEW
    BLOCKED_SOURCE_IDENTITY
    BLOCKED_EVIDENCE_INSUFFICIENT

A blocked state has no transition to exclusion. Corrected evidence or authority
requires a fresh decision and newly constructed/reviewed plan; do not silently
edit an accepted record or downgrade the failure.

## 11. Mandatory exclusion guards

All guards must pass. Otherwise the node remains a blocker and generation is
ineligible:

    exact DesignDocument identity matches
    design_node_id exists in that document
    node lies inside the selected original component boundary
    node.semantic_type is raw | unsupported | unknown
    node is a leaf under this initial disposition authority
    SourceTrace exists and source_type/source_id match the plan fields exactly
    node and its subtree contain no Behavior reference
    no Behavior reference targets the node
    review confirms no independently required presentation role
    review confirms no independently required content role
    review confirms no independently required accessibility role
    review confirms no independently required generated-DOM role
    exact BehaviorBinding exists exactly once
    exact BehaviorContract belongs to the exact DesignDocument
    exact BehaviorContract is approved by the one explicitly selected BehaviorReviewResult
    selected BehaviorReviewResult ID equals NodeDisposition.behavior_review_id
    singleton BehaviorReviewResult approval validation passes against the supplied BehaviorContract
    review confirms source runtime responsibility is represented by that Behavior authority
    exact approved ComponentReviewResult binds approved contract digest, plan, and document
    source runtime remains inert and is never executed or copied

The ComponentReviewResult is not a replacement for the BehaviorReviewResult.
The former approves the exact componentization plan and exclusion evidence;
the latter approves the exact BehaviorContract. Both must be present and
valid. The ComponentReviewResult ID is derived from its canonical bytes.
Generation receives that explicitly selected ID beside the selected result,
recomputes the ID, and requires equality before validating the exact contract,
plan, and document digests.

## 12. Validation and diagnostics

The default rule remains:

    raw | unsupported | unknown in-boundary node
    + no exact valid structured disposition
    → componentization_plan.unsupported_node
    → ERROR; generation ineligible

The authorized rule is:

    raw | unsupported | unknown in-boundary node
    + one exact valid NodeDisposition
    + exact current Behavior and ComponentReview authority
    → omit target from generated structure

Every 1.1.0 disposition must match exactly one in-boundary node whose
semantic_type is raw, unsupported, or unknown, and be consumed exactly once.
Emit deterministic componentization_plan.*
diagnostics. Reuse existing
componentization_plan.design_document.mismatch for stale DesignDocument
identity. Add only these disposition diagnostics:

    componentization_plan.node_disposition.invalid
    componentization_plan.node_disposition.target_missing
    componentization_plan.node_disposition.target_outside_boundary
    componentization_plan.node_disposition.target_semantic_incompatible
    componentization_plan.node_disposition.duplicate
    componentization_plan.node_disposition.outcome_unsupported
    componentization_plan.node_disposition.source_identity_mismatch
    componentization_plan.node_disposition.behavior_binding_mismatch
    componentization_plan.node_disposition.behavior_authority_mismatch
    componentization_plan.node_disposition.behavior_reference_conflict
    componentization_plan.node_disposition.required_role_conflict
    componentization_plan.node_disposition.review_authority_mismatch
    componentization_plan.node_disposition.unused

Intrinsic validation covers closed fields, enum, strings/digests, reference
lists, ordering, and uniqueness. Reference validation covers exact identities,
boundary membership, IR semantics, references, Behavior authority, and
review. On any failed guard, emit the specific error where applicable and
retain componentization_plan.unsupported_node for every undisposed
raw/unsupported/unknown target
that has no valid disposition. A specific error never converts the node into
an allowed exclusion.

An outcome not in the closed enum is invalid. A target that disappears, moves
outside the boundary, becomes supported by a later IR/adapter change, changes
SourceTrace identity, or is no longer consumed is not silently ignored; it
fails as incompatible, stale, or unused. Multiple dispositions for one node
are invalid, not last-write-wins.

## 13. Generation semantics

“Excluded” means exactly:

    DesignDocument node remains present in evidence IR
    node does not produce generated HTML/HEEx structure
    node does not produce copied source JavaScript
    node does not produce executable source runtime
    node does not create a public attr or slot automatically
    node does not change Behavior ownership
    node SourceTrace/provenance remains available for audit

The generator builds one validated structural view for all native output
passes. The exclusion must be applied before both stylesheet/style traversal
and renderer traversal, so a hidden node cannot emit CSS, classes, or markup
through another pass. Do not filter only at the final HTML renderer. The
approved source-neutral Behavior realization is the sole behavior realization
authority.

NodeDisposition does not change the DesignDocument tree, its parent/child
links, or the original boundary. The original tree continues to answer
“inside this evidence boundary?” The filtered view answers “included in
generated structure?” There is no boundary re-selection, ancestry rewrite,
Behavior ownership change, or node deletion.

## 14. Relationship to Behavior and downstream stages

NodeDisposition is not a second BehaviorContract. It contains no timer
policy, selection state machine, trigger definition, controlled target, ARIA
implementation, or runtime code. It names only the exact reviewed Behavior
authority needed to justify removing source runtime responsibility.

| Area | Disposition awareness | Rule |
| --- | --- | --- |
| ComponentizationPlan canonical identity | Yes | Serialized dispositions participate in exact plan bytes and fingerprint |
| ComponentReview | Yes | Review the exact complete plan and evidence; bind approval to approved-contract, plan, and document SHA-256 digests |
| P7-D1 BehaviorProjection | No | Behavior projection remains solely derived from BehaviorContract |
| Realization selector | No | Selection and realization semantics do not change |
| Runtime | No | Runtime receives no source disposition and no source payload |
| NativeGenerator | Yes | Revalidate authority and use a filtered structural view |
| ComponentContract public API | No | No attrs, slots, types, or ownership are added by disposition |

The exact plan hash in ComponentReviewResult prevents a reviewed plan from
being substituted with another valid-looking plan. The existing
GeneratedArtifactBundle.plan_fingerprint already hashes
ComponentizationPlan.encode/1; when the serializer gains the new field, that
fingerprint includes the disposition records.

The exact approved-contract hash prevents a modified contract from reusing a
review even when its stable semantic contract_id is unchanged.

## 15. Backward compatibility and migration

Preserve these rules:

    existing 1.0.0 plans remain immutable
    1.0.0 serialization bytes remain unchanged
    1.0.0 unsupported-node validation remains exactly historical
    no existing 1.0.0 artifact gains exclusion semantics retroactively

A future reader supports both 1.0.0 and 1.1.0. A 1.0.0 plan has no
node_dispositions field and means an empty list with the old fail-closed
rule. A 1.1.0 plan includes the field and applies the new closed schema.
There is no automatic migration. Re-proposal/reissue is required to opt into
the capability. Old readers reject 1.1.0 at the version check.

The exact format decision is:

    OLD_1_0_0_PLAN_VALIDITY=UNCHANGED
    OLD_1_0_0_READER_BEHAVIOR=REJECTS_1_1_0; NO_DECODE_API_AT_BASE
    MIGRATION=REISSUE_ONLY

## 16. Failure-mode review

| Failure | Required result |
| --- | --- |
| Stale DesignDocument | Digest mismatch; block with componentization_plan.design_document.mismatch |
| Wrong boundary | Target-outside-boundary or missing-boundary error; unsupported blocker remains |
| Wrong or missing node ID | Target-missing error; no exclusion |
| Wrong SourceTrace source ID/type | Source-identity mismatch; no exclusion |
| Duplicate dispositions | Duplicate error; no last-write-wins |
| Unknown outcome | Closed-enum validation error; no exclusion |
| Unsupported type becomes supported later | Semantic-incompatible and/or unused error; reissue and review |
| Behavior binding changes | Binding or Behavior-authority mismatch |
| BehaviorContract changes | Contract digest mismatch; new approved review and plan required |
| Wrong BehaviorReviewResult selected | Its derived ID differs from NodeDisposition.behavior_review_id; generation blocks |
| BehaviorReviewResult is not approved for the supplied BehaviorContract | Singleton approval validation fails |
| Same contract_id but changed public API | Approved ComponentContract digest mismatch |
| Same contract_id but changed binding projection | Approved ComponentContract digest mismatch |
| Same contract_id but changed accessibility | Approved ComponentContract digest mismatch |
| Same contract_id but changed default | Approved ComponentContract digest mismatch |
| Same contract_id but changed validation | Approved ComponentContract digest mismatch |
| Supplied contract has approval_status=:proposed | Contract state guard and approved-contract digest check fail |
| ComponentReviewResult selector differs from its canonical content ID | Selected review result identity validation fails |
| ComponentReviewResult binds another plan or document | Exact plan or document digest mismatch; generation blocks |
| Behavior reference moves into or targets disposed node | Behavior-reference conflict |
| Disposed node gains required content/accessibility responsibility | ComponentReview rejects or reopens review; exact changed IR identity invalidates plan |
| Plan replay against changed source document | Document/source identity validation fails |
| Manually forged plan | Closed-schema and all identity/authority/review guards run; no matching approved plan review blocks |
| Provenance text claims exclusion without a structured field | Text ignored; unsupported-node blocker remains |
| Valid disposition is never consumed | Unused disposition error; generation blocked |
| Required evidence is ambiguous or absent | BLOCKED_EVIDENCE_INSUFFICIENT; no disposition approval |

Every unlisted or ambiguous state fails closed. No fallback silently drops a
node.

## 17. Security

Imported JSON, CSS, JavaScript, PHP, scripts, hooks, and paths remain inert
untrusted data. Preserve the existing boundary:

    no eval
    no dynamic module loading
    no browser execution
    no server execution
    no raw HTML injection
    no URL fetch triggered by source runtime

Do not copy source runtime into generated artifacts. Do not treat SourceTrace,
evidence references, provenance, or metadata as executable instructions.
Native generation consumes only validated source-neutral IR, plan, and
Behavior authority. The exclusion is a structural omission rule, not a
passthrough or sanitizer for raw source.

## 18. Performance and scaling

This is compile/review/generation metadata only:

    DATA_LAYER=COLD_COMPILE_REVIEW_TIME
    HOT_DATA=N/A
    WARM_DATA=N/A

    ETS=N/A
    CACHEX=N/A
    REDIS=N/A
    POSTGRES=N/A
    PGBouncer=N/A
    READ_REPLICA=N/A
    GENSERVER=N/A
    PUBSUB=N/A
    OBAN=N/A

    REQUIRED_INDEXES=N/A
    CACHE_TTL=N/A
    CACHE_INVALIDATION=N/A
    REDIS_STRUCTURE=N/A
    PUBSUB_BROADCAST=N/A

    RUNTIME_DB_CALLS=0
    RUNTIME_NETWORK_CALLS=0
    RUNTIME_POLLING=0

Build the node and boundary indexes once, then look up each disposition by
design_node_id. Validation should be O(IR nodes + behavior references +
dispositions) and must not rescan the whole tree per disposition. Filter the
validated node IDs once for the shared native-generation structural view.

## 19. Implementation ownership map

These existing paths were inspected as likely future owners. This authority
task does not modify them.

    SemanticInput shape:
      apps/live_frames/lib/live_frames/componentization_proposer/semantic_input.ex

    SemanticInput validation and canonicalization:
      apps/live_frames/lib/live_frames/componentization_proposer/semantic_input/validation.ex
      apps/live_frames/lib/live_frames/componentization_proposer/semantic_input/canonicalization.ex

    Plan schema, validation, serialization, and references:
      apps/live_frames/lib/live_frames/componentization_plan.ex
      apps/live_frames/lib/live_frames/componentization_plan/validation.ex
      apps/live_frames/lib/live_frames/componentization_plan/serializer.ex
      apps/live_frames/lib/live_frames/componentization_plan/reference_validation.ex

    Proposer construction and authority handoff:
      apps/live_frames/lib/live_frames/componentization_proposer.ex
      apps/live_frames/lib/live_frames/componentization_proposer/construction.ex

    Exact-plan ComponentReview result and validation:
      apps/live_frames/lib/live_frames/component_review.ex
      new ComponentReviewResult type, validator, canonical serializer, and
      derived content ID defined by this spec

    Exact approved ComponentContract digest:
      apps/live_frames/lib/live_frames/component_contract.ex
      apps/live_frames/lib/live_frames/component_contract/serializer.ex

    Behavior authority identities:
      apps/live_frames/lib/live_frames/behavior/contract.ex
      apps/live_frames/lib/live_frames/behavior/review_result.ex

    Native structural filtering:
      apps/live_frames/lib/live_frames/native_generator.ex
      apps/live_frames/lib/live_frames/native_generator/style_integration.ex
      apps/live_frames/lib/live_frames/native_generator/renderer.ex

    Regression coverage, later only:
      apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs
      apps/live_frames/test/live_frames/componentization_plan_test.exs
      apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs
      apps/live_frames/test/live_frames/component_review_test.exs
      apps/live_frames/test/live_frames/native_generator_test.exs

No dedicated BehaviorProjection or realization-selector module exists under
apps/live_frames/lib/live_frames at this base. Neither downstream area needs
disposition awareness. The existing behavior/componentization_decision.ex
is not an owner for this work and must not be changed as part of this design.

## 20. Future high-level sequencing

These are phase boundaries only, not an implementation plan or agent
micro-prompts:

    Phase 1 — plan/schema/version support
    Phase 2 — SemanticInput decision family
    Phase 3 — proposer construction/guards
    Phase 4 — reference-validation disposition handling
    Phase 5 — native-generation omission
    Phase 6 — Milan exact proof
    Phase 7 — regression/hardening

Each future phase remains unauthorized until this specification is reviewed
and accepted and a separate implementation plan is approved.

## 21. Invariants

    SN-I01 unsupported nodes fail closed by default
    SN-I02 exclusion requires structured authority
    SN-I03 provenance prose cannot authorize exclusion
    SN-I04 DesignDocument evidence is never deleted to bypass validation
    SN-I05 source runtime is never executed or copied
    SN-I06 BehaviorContract remains sole executable behavior authority
    SN-I07 exclusion cannot contain a Behavior-referenced node
    SN-I08 excluded node cannot own independently required presentation/content/accessibility
    SN-I09 stale identity fails closed
    SN-I10 historical plan versions retain historical semantics
    SN-I11 exact node/source identity is deterministic
    SN-I12 generated structure omits only explicitly authorized nodes

Additional invariants:

    SN-I13 one node has at most one effective disposition
    SN-I14 plan review is bound to exact ComponentizationPlan bytes
    SN-I15 a disposition target must be a leaf until subtree semantics receive authority
    SN-I16 all native generation traversals consume the same filtered structure
    SN-I17 ComponentReviewResult binds exact approved ComponentContract canonical bytes
    SN-I18 generation receives one explicitly selected BehaviorReviewResult and verifies its exact ID
    SN-I19 generation receives one explicitly selected ComponentReviewResult, verifies its content-derived ID, and checks its exact contract/plan/document digests

## 22. Explicit non-goals

    no general unsupported-node suppression
    no general raw-node passthrough
    no source runtime execution
    no JavaScript translation
    no Milan allowlist
    no Bricks-code-element allowlist
    no Behavior redesign
    no DesignDocument mutation
    no A1 decisions
    no real D0 execution
    no ComponentContract creation
    no runtime implementation

## 23. Proposal status

    Q12=RESOLVED

    Q13_EVIDENCE_CLASSIFICATION=
    SOURCE_RUNTIME_CARRIER_CANDIDATE

    Q13_EVIDENCE_CONFIRMATION=PASS

    SOURCE_NODE_DISPOSITION_ARCHITECTURE=
    PROPOSED_FOR_REVIEW

    STRUCTURED_EXCLUSION_AUTHORITY=
    NOT_YET_ACCEPTED

    Q13_RESOLVED=NO

    A1_STARTED=NO
    P7_D0_STARTED=NO
    IMPLEMENTATION_AUTHORIZED=NO
