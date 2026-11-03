# Feature Milan IR7 R3 source identity proof authority

Status: proposed for independent review. This document freezes a source input
proof contract for the reviewed Automatic.css 4.0.1 fixture. It does not
authorize production implementation.

```text
AUTHORITY_STATE=AWAITING_INDEPENDENT_REVIEW
BASE_MAIN_SHA=7437c0bf1d0dc1d4009a1c9aaa6b7626d64ae0fa
BASE_MAIN_TREE=0af3268e6367455f28a0d4d7421a3584f32bead8
BASE_POST_MERGE_CI=41696448929
BASE_POST_MERGE_CI_RESULT=SUCCESS
REFERENCE_FIXTURE=fixtures/automatic_css/acss_settings.json
REFERENCE_FIXTURE_SIZE_BYTES=92199
REFERENCE_FIXTURE_SHA256=19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05
REFERENCE_DIGEST_STATUS=PROPOSED_FOR_REVIEW
SOURCE_VERSION=Automatic.css 4.0.1 reference set
R3_LIFECYCLE=EVIDENCE_GATE_ACCEPTED_WITH_UNRESOLVED_BLOCKERS
R3_ACCEPTED=YES
R3_ACCEPTED_MEANING=EVIDENCE_GATE_ACCEPTANCE_WITH_UNRESOLVED_BLOCKERS_NOT_IMPLEMENTATION_COMPLETION
R3_ACCEPTED_SCOPE=BG_ULTRA_LIGHT_ONLY
R3_BG_IMPLEMENTATION_AUTHORIZED=NO
R4_AUTHORIZED=NO
R5_AUTHORIZED=NO
```

`R3_ACCEPTED=YES` reflects the BG-only evidence-gate acceptance recorded on
current main. It does not expand or reapprove R3 evidence, or accept this
source-identity proof authority. This authority remains pending independent
review, and its implementation authorization remains `NO`.

The proposed digest identifies the exact bytes of the checked-in fixture. The
fixture provenance record names Automatic.css 4.0.1 as its reference-set
version. The source/version association comes from that reviewed provenance,
not from the digest alone, the fixture's JSON fields, or caller metadata. This
does not assert that the digest authenticates a vendor release or that
arbitrary Automatic.css 4.0.1 exports are compatible.

The fixture digest is distinct from S5 in the scoped provenance decision.
S5 identifies a separate source-environment settings export. The two digests
must not be treated as interchangeable or described as byte-identical. This
authority covers only the exact repository fixture named above.

## 1. Scope and authorized result

The later implementation may use verified fixture identity to authorize only
this conditional source-output alias:

```text
VARIABLE=--bg-ultra-light
TOKEN_PATH=color.background.ultra_light
AUTHORITY_KIND=source_output_alias
AUTHORITY_ID=automatic-css-4.0.1:contextual-background:bg-ultra-light
SOURCE_KEY=bg-ultra-light
SOURCE_VERSION=4.0.1
FEATURE_OPTION=option-contextual-color-variables
REQUIRED_VALUE=on
```

The source option must equal the exact string `on`. The existing normalized
entry must have path `color.background.ultra_light` and source key
`bg-ultra-light`. These guards qualify this one alias. A path, source key, or
option value does not establish source identity.

`--black-trans-10` and `--text-dark-muted` remain unresolved. This contract
does not add other source versions, exports, aliases, token paths, or
Automatic.css compatibility claims. It does not change TokenSet,
VariableAuthority, or Design IR contracts. It adds no Bricks or
NativeGenerator branch.

## 2. Accepted identity record

The only eligible reference identity is this pair:

| Field | Accepted value |
| --- | --- |
| Fixture | `fixtures/automatic_css/acss_settings.json` at the pinned base |
| Exact byte length | `92199` |
| SHA-256 | `19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05` |
| Source system | Automatic.css configuration JSON |
| Source version provenance | `fixtures/automatic_css/SOURCE.md` and the scoped Feature Milan R3 decision in `docs/04_SOURCE_AND_PROVENANCE.md` |
| Version scope | Automatic.css 4.0.1 reference set for this fixture only |
| Contextual feature option in the fixture | `option-contextual-color-variables=on` |

The proposed digest is a byte identity for the repository fixture. It is not
a vendor signature, and a matching digest alone does not establish vendor
version. The accepted version binding is the reviewed provenance record named
above. If that record no longer supports this fixture's 4.0.1 reference-set
identity, stop with `STOP=SOURCE_VERSION_PROVENANCE_INSUFFICIENT`.

The source sidecar records internal conversion approval and unknown broader
project-use and redistribution status. This document publishes no fixture
contents or private source bytes. The digest must not be reused to identify
the distinct S5 artifact or any other export. A future change to the fixture
bytes requires a new reviewed identity record before implementation.

## 3. Owning layer and proof boundary

`LiveFrames.Adapters.AutomaticCSS.Loader` owns source-byte ingestion. Keep
`AutomaticCSS.from_file/2`, `from_json/2`, and `normalize/2` backward
compatible. Their current recognition, normalization, and descriptive
`source_version` and `source_version_status` metadata behavior remains
unchanged. Those values do not prove identity and cannot authorize the new
`--bg-ultra-light` alias.

Add one distinct adapter operation, `AutomaticCSS.from_reference_file/2`, for
the single approved reference identity. It takes a path only to locate bytes.
The Loader reads those bytes once, checks the size and exact digest against the
fixed reviewed reference/version binding, and decodes that same byte sequence
only after a match. A different path containing the exact approved bytes may
pass. The expected path containing different bytes must fail. The operation
uses a fixed internal reference record; caller options cannot select its
reference, source version, or provenance binding.

The Loader's successful return is consumed immediately by the adapter's
private normalization path. Keep the handoff in that control flow. Do not
return a reusable proof value or put proof fields in TokenSet metadata. Do not
accept a caller-supplied proof flag, struct, public metadata map, filename,
source-version label, status label, or decoded settings map as proof. Any
legacy `source_version` or `source_version_status` options remain descriptive
only and cannot change the fixed reference binding or the alias authority's
version.

The adapter's private trusted path may run the existing Normalizer and then
add the one alias after the byte proof, source-option, token-path, and source
key guards pass. Do not add proof handling or a proof option to the
Normalizer. Its existing public entrypoint must not emit this new alias from
caller options, metadata, or an arbitrary map. Keep `normalize(map, opts)` as
the historical decoded-map route and preserve the exact R2 reconstruction
input procedure. Such a map remains `UNVERIFIED` for this alias.

If reading, byte verification, or decoding fails, return a terminal error.
Do not retry through `from_file/2`, `from_json/2`, `normalize/2`, or another
caller-asserted fallback. A separate legacy conversion may still be invoked by
the caller, but it must not inherit verified identity from the rejected
operation.

## 4. Per-ingestion lifecycle

These are logical states for one conversion. They do not require a stored
state-machine resource.

| State | Transition and guard | Diagnostics and result |
| --- | --- | --- |
| `UNVERIFIED` | An ordinary `from_file/2`, `from_json/2`, or `normalize/2` call runs without entering trusted verification. A trusted-reference call starts here and immediately enters `VERIFYING`. | No proof diagnostic for ordinary conversion. The new alias is unavailable. |
| `VERIFYING` | `from_reference_file/2` asks Loader to check the bounded byte length and exact bytes against the one accepted fixture/version binding before decode. | Internal state only. No success diagnostic. |
| `VERIFIED_REFERENCE` | Exact fixture bytes and the reviewed 4.0.1 reference binding match. Loader decodes the same binary value and returns it directly to the adapter operation. | No diagnostic. Eligible to continue through guarded normalization. |
| `REJECTED_MISMATCH` | Byte length, bytes, or the fixed expected identity differs. | Terminal source error diagnostic. Return an error; do not produce verified authority or retry through an unverified fallback. |
| `REJECTED_UNSUPPORTED_SOURCE` | The fixed internal record has no accepted source/version binding. The current operation exposes no caller-selected reference or version. | Terminal source error diagnostic. Caller version or status labels cannot create or change the binding. |
| `REJECTED_INVALID_INPUT` | Input is unreadable, malformed, or outside the supported JSON settings shape. | Terminal source error diagnostic. Do not decode another read or fall back to a map claim. |
| `FEATURE_DISABLED` | A verified reference has `option-contextual-color-variables` missing, set to `off`, or set to an invalid value. | No alias and no proof error. Other supported tokens may normalize. Keep `var(--bg-ultra-light)` unresolved. This state is unreachable for the sole currently accepted fixture, whose option is exactly `on`; it applies only if a future independently reviewed reference identity supports a disabled value. |
| `ELIGIBLE_FOR_BG_ALIAS` | Verified settings have the exact option value `on`, and the normalized entry has the exact path and source key in section 1. | No proof diagnostic. Only the existing direct-owner pathway may resolve the alias. |

The three `REJECTED_*` states are terminal. They produce a bounded source
diagnostic without source bytes, caller assertions, or untrusted paths. They
produce no trusted TokenSet. In the consuming Design IR flow, the source
expression remains unresolved. `FEATURE_DISABLED` is terminal for this alias
only. It cannot be reached by changing the approved fixture bytes because
those bytes then fail verification first. `ELIGIBLE_FOR_BG_ALIAS` does not
bypass existing owner-token or terminal checks; any missing, ambiguous,
unresolved, or unsupported result keeps the expression unresolved.

The proof path does not use `source_version` or `source_version_status` from
caller options. Existing descriptive metadata behavior may remain for legacy
conversion, but those fields are not proof and cannot change any state above.

## 5. Existing authority behavior

For the one eligible record, the current TokenSet map key remains
`color.background.ultra_light`; the authority record does not repeat a path.
The existing `VariableAuthority.resolve/2`, `resolve_terminal/2`,
`resolve_direct_owner/2`, and `resolve_direct_owner_terminal/2` APIs remain
unchanged. Generic candidate behavior remains unchanged.

The later implementation may add the approved authority only after the proof
and feature guards pass. It must not make Normalizer source metadata, caller
options, a Bricks-specific path, or a NativeGenerator branch serve as proof.
The exact later unresolved outcomes remain:

```text
BLACK_TRANS_10=UNRESOLVED
TEXT_DARK_MUTED=UNRESOLVED
```

## 6. Focused tests for the later implementation

Do not add or run these tests in this authority-freeze change. The later
authorized implementation must cover:

- Existing `from_file/2`, `from_json/2`, and `normalize/2` callers retain their
  current behavior. Caller `source_version` and `source_version_status`
  options on those calls do not grant the new alias authority.
- The exact fixture passes `from_reference_file/2` end to end and authorizes
  the R3 alias because its `option-contextual-color-variables`
  value is exactly `on`.
- Temporary byte variants that change the option to `off`, remove it, or set
  it to an invalid value fail the exact-byte proof before decoding. Do not
  treat those modified bytes as verified inputs.
- Test the feature guard separately for `on`, `off`, missing, and invalid
  values at its isolated decision boundary. These tests assert only whether
  the option enables the guard; they do not construct verified identity,
  claim that modified bytes passed proof, or assert an alias for an unverified
  map.
- A modified byte, substituted input, wrong length, or unsupported internal
  reference binding fails before decoding.
- On `from_reference_file/2`, a correct `source_version` label with incorrect
  bytes still receives a mismatch error.
- On `from_reference_file/2`, a correct `source_version_status` label with
  unverified bytes still receives a mismatch error.
- An ordinary `from_file/2` or `from_json/2` call with a correct
  `source_version_status` label and non-reference bytes remains an unverified
  legacy conversion and cannot produce the new alias.
- A missing, malformed, or unknown trusted source identity binding fails
  closed.
- Verification and JSON decoding consume the same byte sequence, with one
  bounded read and one digest computation per trusted ingestion.
- Existing `normalize(map, opts)` and the Normalizer's public entrypoint
  cannot acquire this alias authority through caller options, caller
  metadata, or a reconstructed decoded map.
- The separate feature-guard tests confirm `off`, missing, and invalid values
  disable the alias without claiming a verified reference. If a future
  independently approved identity supports one of those values, its trusted
  ingestion test must also confirm that the expression remains unresolved.
- No public proof-forging route is added for tests. The positive proof test
  uses the exact fixture through the trusted-reference operation; guard tests
  do not manufacture a proof handoff.
- The exact contextual option `on`, exact path, and exact source key are all
  required before the alias can reach the direct-owner pathway.
- The proof alone changes no unrelated TokenSet metadata.
- Existing source-neutral and generic variable-resolution behavior remains
  unchanged, including the unresolved `--black-trans-10` and
  `--text-dark-muted` outcomes.
- A proof rejection cannot retry through the historical map API.

## 7. Serialization, performance, and security

The proof is transient. It adds no TokenSet root field, token metadata, or
Design IR field. Proof verification alone does not change canonical TokenSet
or DesignDocument bytes. `normalize(map, opts)` must continue to reproduce the
accepted R2 historical map input.

The later authorized alias record is a TokenSet token-metadata change. If it
changes canonical TokenSet output or the DesignDocument output, the existing
R3 identity and R2 reconstruction gates apply. Re-run the accepted
reconstruction controls and canonical serializer checks, then issue any new
DesignDocument identity only under a separate identity-reissue approval.
This authority issues no new TokenSet or DesignDocument digest and does not
bump either schema. The final IR7 DesignDocument identity remains unfrozen.

Verification runs at generation time. Read at most the reference-size bound
plus one sentinel byte, hash once per ingestion, and reuse the same bytes for
decoding. Do not hash per token or add Redis, ETS, Cachex, PgBouncer, Oban,
PubSub, a database, a key service, or a cache. Never include private source
bytes or full input values in diagnostics.

## 8. Scope and stop conditions

This proposal grants no production implementation authority. It does not
change the existing TokenSet, VariableAuthority, or Design IR contracts. It
does not expand or reapprove the R3 evidence gate, which current main records
as accepted for `BG_ULTRA_LIGHT_ONLY` with unresolved blockers. This
source-identity proof authority remains pending its own independent review
and acceptance. It does not authorize BG implementation, R4, or R5, add a
generic attestation system, or claim compatibility with arbitrary
Automatic.css exports.

Stop if any of these conditions occurs:

```text
STOP=MAIN_OR_AUTHORITY_CHANGED
STOP=REFERENCE_FIXTURE_IDENTITY_MISMATCH
STOP=SOURCE_VERSION_PROVENANCE_INSUFFICIENT
STOP=TRUST_BOUNDARY_CAN_BE_SPOOFED
STOP=TRUSTED_INGESTION_API_BOUNDARY_UNRESOLVED
STOP=HISTORICAL_MAP_INPUT_CONFLICT
STOP=NEW_PUBLICATION_APPROVAL_REQUIRED
STOP=UNRELATED_API_WIDENING_REQUIRED
STOP=PRODUCTION_IMPLEMENTATION_STARTED
STOP=PRIVATE_SOURCE_PUBLICATION_REQUIRED
STOP=REPEATED_FIX_FAILURE_ROOT_CAUSE_REVIEW_REQUIRED
```

After independent review and acceptance of this proof authority, the next
permitted step is a separate implementation-authorization decision. This
document does not start that implementation.

```text
R3_LIFECYCLE=EVIDENCE_GATE_ACCEPTED_WITH_UNRESOLVED_BLOCKERS
R3_ACCEPTED=YES
R3_ACCEPTED_MEANING=EVIDENCE_GATE_ACCEPTANCE_WITH_UNRESOLVED_BLOCKERS_NOT_IMPLEMENTATION_COMPLETION
R3_ACCEPTED_SCOPE=BG_ULTRA_LIGHT_ONLY
R3_BG_IMPLEMENTATION_AUTHORIZED=NO
R4_AUTHORIZED=NO
R5_AUTHORIZED=NO
PRODUCTION_CHANGED=NO
STOP=AWAIT_R3_SOURCE_IDENTITY_PROOF_AUTHORITY_REVIEW
```
