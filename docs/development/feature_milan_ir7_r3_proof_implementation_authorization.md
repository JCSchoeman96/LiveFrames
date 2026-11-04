# Feature Milan IR7 R3 proof implementation authorization

Status: proposed for independent review. This candidate requests approval for a
proof-only trusted-ingestion implementation. It does not authorize production
implementation until a separate reviewed decision changes the authorization
state below.

```text
AUTHORIZATION_STATE=PROPOSED_FOR_INDEPENDENT_REVIEW
PROOF_DESIGN_ACCEPTED=YES
PROOF_IMPLEMENTATION_AUTHORIZED=NO
BG_ALIAS_IMPLEMENTATION_AUTHORIZED=NO

R3_ACCEPTED=YES
R3_ACCEPTED_SCOPE=BG_ULTRA_LIGHT_ONLY
R4_AUTHORIZED=NO
R5_AUTHORIZED=NO
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

The values in the state block remain unchanged while this candidate awaits
review. A reviewer must record a separate approval decision before proof
implementation may start. That decision must not authorize BG alias
implementation.

## Verified authority baseline

The candidate was prepared from the following main commit, tree, and CI run:

```text
EXPECTED_MAIN=83331d923df29e0fb933d7f865502154be7d4ec4
EXPECTED_MAIN_TREE=1cda76b30233e90530945e08a650fb946b38d3df
EXPECTED_MAIN_CI=41778480449
EXPECTED_MAIN_CI_RESULT=SUCCESS

PROOF_AUTHORITY_BLOB=4f9018c2fe5ae2fce57275a9c807026a53f94fbd
R3_AUTHORITY_BLOB=361c1811f485e414fe323565334f4ddb27b31e83
BG_IMPLEMENTATION_AUTHORITY_BLOB=5e5b4a0fd66931614cd4e24d625b1438993fccf6
PROVENANCE_BLOB=2aeeabebbfcda185ab08ae3200e59e7455fef9df
```

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

This candidate publishes no fixture contents and does not change the permissions in
[`04_SOURCE_AND_PROVENANCE.md`](../04_SOURCE_AND_PROVENANCE.md).

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

This candidate explicitly excludes:

- New `--bg-ultra-light` TokenSet alias metadata.
- Changes to `AutomaticCSS.Normalizer` or `VariableAuthority`.
- Native token-map or package CSS changes.
- Changes to Bricks, NativeGenerator, Design IR, or the Milan reconstruction.
- New source versions or trusted reference identities.
- Copying, publishing, or inlining fixture contents.
- Changes to existing source-provenance permissions.

The proof-only implementation must leave the canonical R2 reconstruction
output unchanged. The [R3 color-variable authority](feature_milan_ir7_color_variable_authority.md)
records its identity as SHA-256
`b607eff3f51ca12ec3db6ae5aa29ca43588e1e7716061850d27e5ac35058f8a5` and
`411535` bytes.

## Required focused tests for a later implementation

Add focused coverage in
`apps/live_frames/test/live_frames/automatic_css_adapter_test.exs` for:

- Acceptance and normalization of the exact approved fixture, with no new BG
  alias authority.
- Same-length changed bytes, wrong lengths, and files that exceed the
  92,199-byte bound.
- Unreadable paths, malformed JSON, unsupported settings shapes, and an
  unavailable or unsupported fixed source identity.
- Caller-supplied source-version and source-version-status spoofing.
- One bounded read and decoding of the exact byte sequence that passed
  verification.
- Terminal rejection with no fallback to ordinary ingestion.
- Existing valid `from_file/2`, `from_json/2`, and `normalize/2` inputs,
  confirming their behavior remains unchanged and cannot gain verified BG
  authority.
- The canonical R2 reconstruction output, confirming its recorded digest and
  byte length remain unchanged.

## Stop conditions

Stop if any of these conditions occurs:

```text
STOP=MAIN_OR_AUTHORITY_CHANGED
STOP=PROOF_CONTRACT_CONTRADICTION
STOP=FIXTURE_IDENTITY_MISMATCH
STOP=PUBLICATION_APPROVAL_INSUFFICIENT
STOP=LEGACY_ADAPTER_BEHAVIOR_CHANGE_REQUIRED
STOP=PROOF_FORGING_ROUTE_REQUIRED
STOP=UNRELATED_FILE_CHANGE
STOP=PRODUCTION_CODE_STARTED
STOP=CI_FAILURE_REQUIRES_ROOT_CAUSE_REVIEW
STOP=AWAIT_PROOF_IMPLEMENTATION_AUTHORIZATION_REVIEW
```

The proposed state remains:

```text
AUTHORIZATION_STATE=PROPOSED_FOR_INDEPENDENT_REVIEW
PROOF_DESIGN_ACCEPTED=YES
PROOF_IMPLEMENTATION_AUTHORIZED=NO
BG_ALIAS_IMPLEMENTATION_AUTHORIZED=NO

R3_ACCEPTED=YES
R3_ACCEPTED_SCOPE=BG_ULTRA_LIGHT_ONLY
R4_AUTHORIZED=NO
R5_AUTHORIZED=NO
```
