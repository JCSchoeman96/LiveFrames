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
R3_ACCEPTED=NO
R3_BG_IMPLEMENTATION_AUTHORIZED=NO
R4_AUTHORIZED=NO
R5_AUTHORIZED=NO
```

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

`LiveFrames.Adapters.AutomaticCSS.Loader` owns source-byte ingestion. It is
the correct place to verify the digest because `from_file/2` reads the source
and `from_json/2` receives its raw bytes before decoding. The adapter owns
the later decision to apply the verified result to the one alias. The
Normalizer does not establish source identity.

The minimum implementation change is an internal Loader-to-adapter handoff
for a verified reference result. The trusted `AutomaticCSS.from_file/2` and
`from_json/2` flows must use that result directly. Do not add a
caller-controlled `verified` option, proof flag, accepted path, filename,
source-version field, status label, or public metadata map as proof. Do not
put the proof in TokenSet metadata or return it as a reusable caller claim.

The verified result is transient and is consumed beside the decoded settings
inside the existing adapter flow. The adapter must not reconstruct it from
`source_version`, `source_version_status`, `export_version`, path, filename,
or settings-map contents. The alias record's `source_version` is the fixed
version in the reviewed identity record.

The byte sequence is processed in this order:

1. Read source bytes once at the Loader boundary. For file input, limit the
   trusted-reference read to `92199` bytes plus one sentinel byte so larger
   inputs reject before hashing or decoding. For an already supplied binary,
   reject it before hashing when its length exceeds `92199` bytes.
2. Compare the exact bytes and byte length with the reviewed reference
   identity. Do this before JSON decoding.
3. On a match, decode that same binary value. Do not reread the path, rebuild
   bytes from a decoded map, or hash once per token.
4. Pass the verified result and the map decoded from those exact bytes
   directly through the adapter's internal normalization flow.

`from_file/2` must not use the path or basename as identity. The path only
locates bytes. A different path with the exact approved bytes can pass the
same fixture identity check; different bytes at the expected path cannot.

The existing `normalize(map, opts)` boundary remains the historical decoded
map route. It may preserve its current output for the accepted R2 reconstruction,
but it always has `UNVERIFIED` identity. Caller options cannot promote it to
verified status or authorize this alias. Preserve the exact historical map
input procedure recorded in the R2 reconstruction record.

If trusted byte verification or decoding fails, return the error. Do not retry
through `normalize/2` or any caller-asserted fallback. A caller may separately
use the legacy map API for historical reconstruction, but that result has no
verified identity and cannot authorize the R3 alias.

## 4. Per-ingestion lifecycle

These are logical states for one conversion. They do not require a stored
state-machine resource.

| State | Transition and guard | Diagnostics and result |
| --- | --- | --- |
| `UNVERIFIED` | Trusted byte ingestion starts with source bytes. Historical `normalize(map, opts)` stays unverified and does not enter the trusted transitions. | No proof diagnostic. The alias is unavailable. |
| `VERIFYING` | Loader checks byte length, exact bytes, and the accepted fixture/version binding before decode. | Internal state only. No success diagnostic. |
| `VERIFIED_REFERENCE` | Exact fixture bytes and the reviewed 4.0.1 reference binding match. Loader decodes the same binary value. | No diagnostic. Eligible to continue through guarded normalization. |
| `REJECTED_MISMATCH` | Byte length, bytes, or expected reference identity differs. | Terminal source error diagnostic. Return an error; do not produce verified authority or retry through an unverified fallback. |
| `REJECTED_UNSUPPORTED_SOURCE` | The trusted reference record has no accepted source/version binding for the input. | Terminal source error diagnostic. Caller version or status labels cannot create or change the binding. |
| `REJECTED_INVALID_INPUT` | Input is unreadable, malformed, or outside the supported JSON settings shape. | Terminal source error diagnostic. Do not decode another read or fall back to a map claim. |
| `FEATURE_DISABLED` | Verified settings do not have `option-contextual-color-variables` exactly equal to `on`, including missing, `off`, or invalid values. | No alias and no proof error. Other supported tokens may normalize. Keep `var(--bg-ultra-light)` unresolved. |
| `ELIGIBLE_FOR_BG_ALIAS` | Verified settings have the exact option value `on`, and the normalized entry has the exact path and source key in section 1. | No proof diagnostic. Only the existing direct-owner pathway may resolve the alias. |

The three `REJECTED_*` states are terminal. They produce a bounded source
diagnostic without source bytes, caller assertions, or untrusted paths. They
produce no trusted TokenSet. In the consuming Design IR flow, the source
expression remains unresolved. `FEATURE_DISABLED` is terminal for this alias
only. `ELIGIBLE_FOR_BG_ALIAS` does not bypass existing owner-token or terminal
checks; any missing, ambiguous, unresolved, or unsupported result keeps the
expression unresolved.

The proof path does not use `source_version` or `source_version_status` from
caller options. Existing descriptive metadata behavior may remain for legacy
map reconstruction, but those fields are not proof and cannot change any
state above.

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

- The exact fixture bytes pass the proof boundary.
- The exact fixture succeeds when the trusted reference binding exists,
  without requiring caller `source_version` or `source_version_status` values.
- A modified byte, substituted input, wrong length, or unsupported reference
  fails before decoding.
- A correct `source_version` with incorrect bytes fails.
- A correct `source_version_status` with unverified bytes fails.
- A missing, malformed, or unknown trusted source identity binding fails
  closed.
- Verification and JSON decoding consume the same byte sequence, with one
  read and one digest computation per ingestion.
- Existing `normalize(map, opts)` cannot acquire verified authority through
  caller options, caller metadata, or a reconstructed decoded map.
- A verified input with the contextual option `off`, missing, or invalid
  emits no background alias and leaves its direct expression unresolved.
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
does not accept R3, authorize R4 or R5, add a generic attestation system, or
claim compatibility with arbitrary Automatic.css exports.

Stop if any of these conditions occurs:

```text
STOP=MAIN_OR_AUTHORITY_CHANGED
STOP=REFERENCE_FIXTURE_IDENTITY_MISMATCH
STOP=SOURCE_VERSION_PROVENANCE_INSUFFICIENT
STOP=TRUST_BOUNDARY_CAN_BE_SPOOFED
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
R3_ACCEPTED=NO
R3_BG_IMPLEMENTATION_AUTHORIZED=NO
R4_AUTHORIZED=NO
R5_AUTHORIZED=NO
PRODUCTION_CHANGED=NO
STOP=AWAIT_R3_SOURCE_IDENTITY_PROOF_AUTHORITY_REVIEW
```
