# Feature Milan IR7 R3 proof implementation authorization

Owner decision recorded: the project owner approved only the proof-only
trusted-ingestion scope below on 2026-11-04. Independent review and merge are
still required before implementation is authorized.

```text
AUTHORIZATION_STATE=OWNER_APPROVED_PENDING_INDEPENDENT_REVIEW_AND_MERGE
OWNER_DECISION=APPROVE_PROOF_ONLY_SCOPE
OWNER_APPROVAL_STATUS=APPROVED
OWNER_APPROVAL_DATE=2026-11-04
OWNER_APPROVAL_SOURCE=EXPLICIT_OWNER_DECISION_IN_CONVERSATION
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

The project owner explicitly approved this exact proof-only scope in this
conversation on 2026-11-04. This records the owner's decision; it does not
claim an external approval URL, GitHub review, or owner signature. A separate
independent review must confirm that the changed documents preserve this
boundary.

The current pre-merge state remains `PROOF_IMPLEMENTATION_AUTHORIZED=NO` until
independent review and successful merge. Pull request
[#371](https://github.com/JCSchoeman96/LiveFrames/pull/371) merged the prior
proposal document; that merge did not authorize implementation.

Owner approval is now recorded above. Keep the pre-merge state unauthorized
while independent review or merge remains pending. The effective state below
applies only after independent review and successful merge of this approved
revision.

## Effective state after independent review and merge

This is the post-merge state. It does not apply while independent review or
merge is pending. After both gates pass, the proof-only implementation is
authorized, while the BG alias, R4, R5, and final generation remain
unauthorized.

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
remains proposed and unaccepted. This owner decision covers proof-only
verification of the fixed reference input; implementation remains
unauthorized until independent review and successful merge. It does not grant
the BG alias, clear other R3 blockers, or authorize R4 or R5 work.

`R3_ACCEPTED=YES` records evidence-gate acceptance only. It does not mean proof
or BG implementation is complete or authorized.

The owner-approved pre-merge state remains
`PROOF_IMPLEMENTATION_AUTHORIZED=NO` while independent review and merge are
pending. The decision does not authorize BG alias implementation.

## Historical proposal-preparation baseline

The following identities record the baseline used to prepare the original
proposal. Preserve them as historical records; the approval-time snapshot
below records the later authority state checked for this owner decision.

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
proposal's documentation changes. They do not identify the approval-time
snapshot below. The owner decision does not change the accepted proof
contract, BG authority, or fixture-publication permissions.

## Owner-approval-time verification snapshot

The following live identities were checked before recording this owner
decision. The main commit and CI run identify the same successful main
revision. The PR values identify PR #373 immediately before this amendment.

```text
APPROVAL_TIME=2026-11-04
APPROVAL_TIME_MAIN_SHA=cc01aba34576c9250145bce2ed7ca2cbc3ae6330
APPROVAL_TIME_MAIN_TREE=e02697df24ef227884b26d66a9aeea3295c37309
APPROVAL_TIME_MAIN_CI_RUN=41787617778
APPROVAL_TIME_MAIN_CI_COMMIT=cc01aba34576c9250145bce2ed7ca2cbc3ae6330
APPROVAL_TIME_MAIN_CI_RESULT=SUCCESS
APPROVAL_TIME_BG_AUTHORITY_BLOB=b304c7adac037efdef0555937b66fd1378fed9c2

APPROVAL_TIME_PR=373
APPROVAL_TIME_PR_PREAMENDMENT_HEAD=06c48a8d01d3143d82e3eefa5af28ebc0bf4d4f4
APPROVAL_TIME_PR_PREAMENDMENT_TREE=74b16362dc7359cbb601c794fa13b4f7d56268a7
APPROVAL_TIME_AUTHORIZATION_DOCUMENT_BLOB=cbdada899451d849e09d51f606fe1fa78b5d6d76
APPROVAL_TIME_PROVENANCE_DOCUMENT_BLOB=546f5a75b3ed656a8597aaac420b920f66093dac
```

PR #372's `PROOF_IMPLEMENTATION_AUTHORIZED=NO` fields record the state at
that authority's historical reconciliation and remain true for that snapshot.
Its `BG_IMPLEMENTATION_AUTHORIZED=NO` remains current: this owner decision
authorizes no BG Stage B work. The updated BG authority keeps Stage A and Stage
B separate; Stage B still requires completed and merged Stage A, successful
post-merge CI, and its own BG implementation authorization.

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

This owner decision publishes no fixture contents and does not change the
permissions in [`04_SOURCE_AND_PROVENANCE.md`](../04_SOURCE_AND_PROVENANCE.md).

## Files covered by this proof-only decision

If the authorization becomes effective after independent review and merge,
implementation may change only these files:

```text
apps/live_frames/lib/live_frames/adapters/automatic_css/loader.ex
apps/live_frames/lib/live_frames/adapters/automatic_css.ex
apps/live_frames/test/live_frames/automatic_css_adapter_test.exs
```

This amendment changes documentation only. Any implementation must be a
separate change after independent review and successful merge.

## Trusted reference operation

If this authorization becomes effective after independent review and merge,
the implementation may add the public opt-in
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

This owner-approved scope explicitly excludes:

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
STOP=MAIN_CHANGED_AGAIN
STOP=MAIN_CI_NOT_SUCCESSFUL
STOP=BG_AUTHORITY_CONFLICT
STOP=OWNER_APPROVAL_SCOPE_CHANGED
STOP=UNRELATED_FILE_CHANGED
STOP=PROOF_CONTRACT_CHANGED
STOP=PRODUCTION_IMPLEMENTATION_STARTED
STOP=CI_FAILURE
STOP=AWAIT_PR373_FINAL_INDEPENDENT_REVIEW
```

This is the effective pre-merge state after the explicit owner decision. It
remains in force while independent review or merge is pending:

```text
OWNER_DECISION=APPROVE_PROOF_ONLY_SCOPE
OWNER_APPROVAL_STATUS=APPROVED
OWNER_APPROVAL_DATE=2026-11-04
OWNER_APPROVAL_SOURCE=EXPLICIT_OWNER_DECISION_IN_CONVERSATION
AUTHORIZATION_STATE=OWNER_APPROVED_PENDING_INDEPENDENT_REVIEW_AND_MERGE
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

After independent review and successful merge, the effective state in the
section above applies. The pre-merge `PROOF_IMPLEMENTATION_AUTHORIZED=NO` is
not the post-merge state.
