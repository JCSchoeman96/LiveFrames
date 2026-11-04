# Feature Milan IR7 R3 proof implementation authorization

Proposal status: pending owner approval and independent review. This document
asks the project owner to approve only the proof-only trusted-ingestion scope
below. No owner approval is recorded, and this proposal does not authorize
implementation.

```text
AUTHORIZATION_STATE=PROPOSED_PENDING_OWNER_APPROVAL_AND_INDEPENDENT_REVIEW
PROPOSED_OWNER_DECISION=APPROVE_PROOF_ONLY_SCOPE
OWNER_APPROVAL_STATUS=PENDING
OWNER_APPROVAL_DATE=NOT_RECORDED
PROOF_DESIGN_ACCEPTED=YES
PROOF_IMPLEMENTATION_AUTHORIZED=NO
PROOF_IMPLEMENTED=NO
BG_ALIAS_IMPLEMENTATION_AUTHORIZED=NO

R3_ACCEPTED=YES
R3_ACCEPTED_SCOPE=BG_ULTRA_LIGHT_ONLY
R4_AUTHORIZED=NO
R5_AUTHORIZED=NO
FINAL_GENERATION_AUTHORIZED=NO
```

## Owner decision record

The proposed decision is to approve only the scope in this document. The
project owner has not recorded that approval. Before merge, the owner must
record an explicit `APPROVE_PROOF_ONLY_SCOPE` decision and its date here and in
the pull request. A generic pull-request approval does not record this
scope-specific decision. A separate independent review must also confirm that
the changed documents preserve this boundary.

Until the explicit owner decision, independent review, and successful merge
are all recorded, proof implementation remains unauthorized. Pull request
[#371](https://github.com/JCSchoeman96/LiveFrames/pull/371) merged the prior
proposal document; that merge did not authorize implementation.

After owner approval and independent review, record the owner's explicit
decision and date, and set the proposal state to
`APPROVED_PENDING_MERGE`. Keep `PROOF_IMPLEMENTATION_AUTHORIZED=NO` until that
approved revision merges. The conditional state below becomes effective only
after the successful merge. If the owner decision is missing or remains
pending, merging this document does not authorize implementation.

## Conditional state after approval and merge

This is the only effective state this proposal may establish. It applies only
after explicit owner approval of this scope, independent review, and a
successful merge of the updated decision. It does not apply while the proposal
is open or pending review, or if it merges without the recorded owner decision.

```text
PROOF_DESIGN_ACCEPTED=YES
PROOF_IMPLEMENTATION_AUTHORIZED=YES
PROOF_IMPLEMENTED=NO

BG_ALIAS_IMPLEMENTATION_AUTHORIZED=NO
R3_ACCEPTED=YES
R3_ACCEPTED_SCOPE=BG_ULTRA_LIGHT_ONLY
R4_AUTHORIZED=NO
R5_AUTHORIZED=NO
FINAL_GENERATION_AUTHORIZED=NO
```

## Review boundary

The accepted proof design is recorded in
[`feature_milan_ir7_r3_source_identity_proof_authority.md`](feature_milan_ir7_r3_source_identity_proof_authority.md).
The R3 color-variable authority accepts the conditional `--bg-ultra-light`
owner for the BG-only evidence gate. Its separate implementation authority
remains proposed and unaccepted. This candidate requests permission to verify
the fixed reference input only. It does not grant the BG alias, clear other R3
blockers, or authorize R4 or R5 work.

`R3_ACCEPTED=YES` records evidence-gate acceptance only. It does not mean proof
or BG implementation is complete or authorized.

The proposed state remains `PROOF_IMPLEMENTATION_AUTHORIZED=NO` while this
decision awaits owner approval, independent review, and merge. The decision
must not authorize BG alias implementation.

## Verified authority baseline

The live main branch, tree, authority blobs, and CI run were checked before
this proposal was prepared:

```text
EXPECTED_MAIN=77ce052be82d76c409bea9f279d26cc12111b468
EXPECTED_TREE=b7d5e3f5700c11bad3e61c9d0242813b12434e0b
POST_MERGE_CI=41782456503
POST_MERGE_CI_RESULT=SUCCESS

PROOF_IMPLEMENTATION_AUTHORIZATION_BLOB=1c1daf60e5a4dd7ae6597f15258fdbd99bb22b93
ACCEPTED_PROOF_DESIGN_BLOB=4f9018c2fe5ae2fce57275a9c807026a53f94fbd
R3_AUTHORITY_BLOB=361c1811f485e414fe323565334f4ddb27b31e83
BG_IMPLEMENTATION_AUTHORITY_BLOB=5e5b4a0fd66931614cd4e24d625b1438993fccf6
PROVENANCE_BLOB=2aeeabebbfcda185ab08ae3200e59e7455fef9df
```

These blob IDs identify the verified inputs at `EXPECTED_MAIN`, before this
proposal's documentation changes. The changes below add decision-boundary
notes only. They do not change the accepted proof contract, BG authority, or
fixture-publication permissions.

The accepted proof-design document remains unchanged. Its
`PROOF_IMPLEMENTATION_AUTHORIZED=NO` field records the state when that design
was accepted. This decision record controls any later implementation
permission.

These blobs identify the accepted proof design in
[`feature_milan_ir7_r3_source_identity_proof_authority.md`](feature_milan_ir7_r3_source_identity_proof_authority.md),
the R3 color-variable authority in
[`feature_milan_ir7_color_variable_authority.md`](feature_milan_ir7_color_variable_authority.md),
the proposed BG implementation authority in
[`feature_milan_ir7_r3_bg_ultra_light_implementation_authority.md`](feature_milan_ir7_r3_bg_ultra_light_implementation_authority.md),
and the canonical source-provenance record in
[`04_SOURCE_AND_PROVENANCE.md`](../04_SOURCE_AND_PROVENANCE.md). Stop if main
or any authority changes before approval or implementation.

The sole accepted reference identity is:

```text
REFERENCE_FIXTURE=fixtures/automatic_css/acss_settings.json
REFERENCE_FIXTURE_SIZE_BYTES=92199
REFERENCE_FIXTURE_SHA256=19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05
REFERENCE_SOURCE_VERSION=Automatic.css 4.0.1 reference set
```

The source-provenance record permits publication of this fixture path, size,
digest, and reference-set version for R3 identity verification. Fixture
contents, broader project use, and redistribution remain unknown:

```text
R3_FIXTURE_METADATA_PUBLICATION_APPROVED=YES
APPROVAL_SCOPE=R3_SOURCE_IDENTITY_VERIFICATION_METADATA_ONLY
APPROVAL_DATE=2026-11-03
FIXTURE_CONTENT_REDISTRIBUTION_STATUS=unknown
BROADER_FIXTURE_PROJECT_USE_STATUS=unknown
BROADER_AUTOMATIC_CSS_REDISTRIBUTION_STATUS=unknown
```

This proposal publishes no fixture contents and does not change the
permissions in [`04_SOURCE_AND_PROVENANCE.md`](../04_SOURCE_AND_PROVENANCE.md).

## Files covered if approval is granted

The later proof-only implementation may change only these files:

```text
apps/live_frames/lib/live_frames/adapters/automatic_css/loader.ex
apps/live_frames/lib/live_frames/adapters/automatic_css.ex
apps/live_frames/test/live_frames/automatic_css_adapter_test.exs
```

The candidate itself changes documentation only. Any implementation must be a
separate change after independent approval.

## Trusted reference operation

If separately approved, the implementation may add the public opt-in
`AutomaticCSS.from_reference_file/2` operation for the one accepted reference
identity. The input path locates bytes. It does not select a source version or
prove identity by its name.

The operation must meet these requirements:

- Read at most 92,200 bytes in one bounded ingestion. The 92,200nd byte is an
  oversize sentinel. Accept only an input with exactly 92,199 bytes.
- Compare the exact byte length and
  `:crypto.hash(:sha256, bytes)` with the accepted reference identity before
  JSON decoding.
- Decode the same in-memory byte sequence with the existing Jason decoder.
  Do not reread the path for verification, decoding, or fallback.
- Bind the match to the fixed internal Automatic.css 4.0.1 reference record
  and its reviewed provenance. Caller options, including `source_version` and
  `source_version_status`, cannot select or establish that identity.
- Pass recognized settings through the existing adapter normalization path.
  Keep any verified handoff private to that call. Do not return a reusable
  proof value or expose a proof field in TokenSet metadata.
- Return a bounded source diagnostic for rejection. Do not include fixture
  bytes, raw file contents, untrusted paths, caller claims, or unbounded parser
  text in a diagnostic.
- Return a terminal error after rejection. Do not fall back to `from_file/2`,
  `from_json/2`, `normalize/2`, or another caller-asserted input route.

Use only `:crypto.hash(:sha256, bytes)` and the existing Jason decoder for this
proof. Do not add a library, verification service, database, Redis cache, or
persistent proof resource.

The verified operation permits existing normalization only. It does not add
`--bg-ultra-light` alias metadata or change token authority. The proof result
must not become a public capability that callers can forge or reuse.

## Per-ingestion lifecycle

These states apply to one conversion. They do not require persistent state.

| State | Guard | Outcome |
| --- | --- | --- |
| `UNVERIFIED` | An ordinary adapter call runs, or a trusted reference call begins. | An ordinary call keeps its existing conversion behavior and gains no BG authority. A trusted call enters `VERIFYING`. |
| `VERIFYING` | The trusted operation performs the bounded read and checks the fixed identity. | Internal state only. Do not decode before the byte checks pass. |
| `VERIFIED_REFERENCE` | Exact byte length, digest, and accepted internal reference record match. | Decode the same bytes. Existing adapter normalization may proceed. No BG alias authority is added. |
| `REJECTED_MISMATCH` | Byte length or digest differs. | Return a bounded source diagnostic and terminal error. |
| `REJECTED_UNSUPPORTED_SOURCE` | The fixed trusted reference is unavailable or has no accepted source/version binding. | Return a bounded source diagnostic and terminal error. Caller metadata cannot supply the missing binding. |
| `REJECTED_INVALID_INPUT` | Reading fails, JSON is malformed, or the decoded value has an unsupported settings shape. | Return a bounded source diagnostic and terminal error. |

Every `REJECTED_*` state is terminal. No rejected trusted operation may
transition to ordinary ingestion or produce verified authority.

## Existing behavior and scope exclusions

The implementation must preserve the current behavior of
`AutomaticCSS.from_file/2`, `AutomaticCSS.from_json/2`, and
`AutomaticCSS.normalize/2`, including their existing valid inputs and
descriptive source metadata. Those paths remain unverified and cannot gain BG
authority from caller metadata or settings maps.

Keep `normalize(map, opts)` as the historical decoded-map route. Preserve the
accepted R2 reconstruction input procedure.

This proposal explicitly excludes:

- New `--bg-ultra-light` TokenSet alias metadata.
- Changes to `AutomaticCSS.Normalizer` or `VariableAuthority`.
- Native token-map or package CSS changes.
- Changes to Bricks, NativeGenerator, Design IR, or the Milan reconstruction.
- New source versions or trusted reference identities.
- Copying, publishing, or inlining fixture contents.
- Changes to existing source-provenance permissions.

The canonical R2 reconstruction identity remains the SHA-256 and byte length
recorded in the [R3 color-variable authority](feature_milan_ir7_color_variable_authority.md):
`b607eff3f51ca12ec3db6ae5aa29ca43588e1e7716061850d27e5ac35058f8a5` and
`411535` bytes. Keep both values unchanged. Full R2 reproduction is a separate
integration control, not an adapter-test requirement.

## Required focused tests for a later implementation

Add focused adapter tests in
`apps/live_frames/test/live_frames/automatic_css_adapter_test.exs` for:

- Successful verification and normalization of the exact approved fixture,
  with no new BG alias authority.
- Modified bytes, malformed JSON variants, invalid settings variants,
  wrong-length files, and oversized files rejected at the byte-proof boundary
  before JSON decoding or settings-shape recognition. Malformed JSON and
  unsupported settings shapes cannot pass the current exact-fixture digest.
- Existing ordinary adapter diagnostics for malformed JSON through
  `from_file/2` and `from_json/2`, and for unsupported settings shapes through
  `from_json/2` and `normalize/2`.
- Unreadable trusted-reference paths returning a terminal source error.
- Caller-supplied `source_version` and `source_version_status` values not
  selecting or changing the fixed reference binding.
- Terminal rejection with no fallback to ordinary ingestion.
- Compatibility with existing valid adapter inputs and unchanged TokenSet
  behavior, including no verified BG authority through ordinary APIs.

Keep an unavailable or unsupported fixed reference binding as a defensive
fail-closed condition. Do not add caller-controlled reference selection or a
test-only proof override to make that condition reachable.

Verify through the implementation's direct control flow that the trusted
operation performs one bounded read and passes the same bytes to the digest
check and Jason decoder. Do not add an injectable filesystem abstraction only
to count reads.

Full canonical R2 reproduction is a separate integration control. Use the
accepted historical reconstruction procedure and its required private Bricks
reference input. If that input is unavailable, report:

```text
R2_FULL_RECONSTRUCTION=NOT_VERIFIED_MISSING_REFERENCE
```

Do not report the control as passed, invent or substitute reconstruction
input, or modify the recorded R2 digest.

## Stop conditions

Stop if any of these conditions occurs:

```text
STOP=MAIN_OR_AUTHORITY_CHANGED
STOP=OWNER_APPROVAL_NOT_EXPLICIT
STOP=PUBLICATION_SCOPE_CHANGE_REQUIRED
STOP=FIXTURE_IDENTITY_CHANGED
STOP=CONFLICTING_EFFECTIVE_AUTHORIZATION_STATES
STOP=TRUST_BOUNDARY_CHANGE_REQUIRED
STOP=UNRELATED_FILE_CHANGE
STOP=PRODUCTION_IMPLEMENTATION_STARTED
STOP=CI_FAILURE_REQUIRES_ROOT_CAUSE_REVIEW
STOP=AWAIT_PROOF_ONLY_AUTHORIZATION_DECISION_REVIEW
```

This pending state applies while owner approval is not recorded:

```text
AUTHORIZATION_STATE=PROPOSED_PENDING_OWNER_APPROVAL_AND_INDEPENDENT_REVIEW
PROPOSED_OWNER_DECISION=APPROVE_PROOF_ONLY_SCOPE
OWNER_APPROVAL_STATUS=PENDING
PROOF_DESIGN_ACCEPTED=YES
PROOF_IMPLEMENTATION_AUTHORIZED=NO
PROOF_IMPLEMENTED=NO
BG_ALIAS_IMPLEMENTATION_AUTHORIZED=NO

R3_ACCEPTED=YES
R3_ACCEPTED_SCOPE=BG_ULTRA_LIGHT_ONLY
R4_AUTHORIZED=NO
R5_AUTHORIZED=NO
FINAL_GENERATION_AUTHORIZED=NO
```

If owner approval and independent review are completed, update this record
before merge. Keep the approved pre-merge state unauthorized. After that
approved revision merges, the conditional state above is effective and this
pending block records the earlier proposal state.
