# Feature Milan IR7 R3 `--bg-ultra-light` implementation authority

Status: proposed for independent review. This document records a future BG-only
implementation contract. It changes no production code, tests, token maps,
generated assets, or Design IR. It grants no implementation permission.

```text
AUTHORITY_STATE=AWAITING_INDEPENDENT_REVIEW
SOURCE_PROOF_DESIGN_STATE=ACCEPTED_PROOF_DESIGN
SOURCE_PROOF_IMPLEMENTED=NO
SOURCE_PROOF_IMPLEMENTATION_AUTHORIZED=NO
PROOF_IMPLEMENTED=NO
PROOF_IMPLEMENTATION_AUTHORIZED=NO
R3_BG_EVIDENCE_ACCEPTED=YES
R3_EVIDENCE_GATE_ACCEPTED=YES
R3_ACCEPTED_SCOPE=BG_ULTRA_LIGHT_ONLY
BG_IMPLEMENTATION_AUTHORITY_ACCEPTED=NO
PRODUCTION_IMPLEMENTATION_AUTHORIZED=NO
FINAL_GENERATION_AUTHORIZED=NO
IMPLEMENTATION_MAY_START=NO
R4_WORK_PERFORMED=NO
R5_WORK_PERFORMED=NO

AUTHORITY_DRAFT_BASE_SHA=b2ce594c6f8e48fe6093966e328b3a1a0969d471
AUTHORITY_DRAFT_BASE_TREE=b89711063cf364513edb372dd81784fc8da8ece5
AUTHORITY_DRAFT_BASE_SIGNATURE=VALID
AUTHORITY_DRAFT_BASE_CI_RUN=41685653586
AUTHORITY_DRAFT_BASE_CI_RESULT=SUCCESS
HISTORICAL_MAIN_SHA_AT_AUTHORITY_DRAFT=20b0acb2c808ec2746d09fd218317aa8513f3a9f
HISTORICAL_MAIN_TREE_AT_AUTHORITY_DRAFT=d7a9964f90aa20fc635befebb60baaa92ba12b52
R3_EVIDENCE_CANDIDATE_BLOB_AT_AUTHORITY_DRAFT=fb550ca5ee17e9693f62967e39d964c98b0bee5e
PROVENANCE_BASE_BLOB_AT_AUTHORITY_DRAFT=839f7d060e06aa0fcb9e70d964821f442e6dacd8

RECONCILIATION_BASE_SHA=83331d923df29e0fb933d7f865502154be7d4ec4
RECONCILIATION_BASE_TREE=1cda76b30233e90530945e08a650fb946b38d3df
RECONCILIATION_BASE_POST_MERGE_CI_RUN=41778480449
RECONCILIATION_BASE_POST_MERGE_CI_RESULT=SUCCESS
R3_SOURCE_OUTPUT_ALIAS_STATUS=ACCEPTED_CONDITIONAL_OWNER
R3_LIFECYCLE=EVIDENCE_GATE_ACCEPTED_WITH_UNRESOLVED_BLOCKERS
```

The `AUTHORITY_DRAFT_BASE_*` values record the original proposal branch base.
The `HISTORICAL_*_AT_AUTHORITY_DRAFT` and `*_BLOB_AT_AUTHORITY_DRAFT` values
record the refs and document blobs inspected for that draft. They are
historical identities, not current `main` identities. The `RECONCILIATION_*`
values record the verified base for this update.

The source identity proof design is accepted, but it has not been implemented
or authorized for implementation. The R3 evidence gate accepts BG ownership
only. This proposal remains unaccepted, and production implementation and
final generation remain unauthorized.

## 1. Frozen BG owner

The current [R3 color-variable authority](feature_milan_ir7_color_variable_authority.md)
and [scoped provenance decision](../04_SOURCE_AND_PROVENANCE.md#feature-milan-r3-scoped-color-variable-publication-decision)
record this conditional source-output owner:

```text
SOURCE=Automatic.css
VARIABLE=--bg-ultra-light
TOKEN_PATH=color.background.ultra_light
SOURCE_KEY=bg-ultra-light
SOURCE_VERSION=4.0.1
AUTHORITY_KIND=source_output_alias
AUTHORITY_ID=automatic-css-4.0.1:contextual-background:bg-ultra-light
REQUIRED_FEATURE_OPTION=option-contextual-color-variables
REQUIRED_FEATURE_VALUE=on
OTHER_COLOR_VARIABLES=UNRESOLVED
```

The scoped provenance decision publishes one output condition only:

| Source | Option | State | Approved fact |
| --- | --- | --- | --- |
| Automatic.css 4.0.1 | `option-contextual-color-variables` | `on` | The `--bg-ultra-light` contextual output is emitted. |
| Automatic.css 4.0.1 | `option-contextual-color-variables` | `off` | The `--bg-ultra-light` contextual output is not emitted. |

No other output conditions are approved by that decision.

The feature option must equal the exact string `on`. The existing normalized
entry must have the exact token path and source key above. Source identity
must pass the separate accepted fixture proof described below. A path, source
key, option value, caller version label, or token value cannot establish that
identity.

The alias belongs in the existing token's `variable_authorities` metadata.
The TokenSet map key remains `color.background.ultra_light`; the authority
record does not repeat the path or change the token value. The record shape is:

```json
{
  "variable": "--bg-ultra-light",
  "kind": "source_output_alias",
  "authority_id": "automatic-css-4.0.1:contextual-background:bg-ultra-light",
  "source_key": "bg-ultra-light",
  "source_version": "4.0.1"
}
```

The current Normalizer maps `bg-ultra-light` to a semantic reference from
`color.background.ultra_light` to `color.neutral.ultra_light`. The future
alias does not change that value or reference. `--black-trans-10` and
`--text-dark-muted` remain unresolved.

## 2. Accepted source identity and use scope

The accepted proof design permits only this reference identity:

| Field | Accepted value |
| --- | --- |
| Fixture | `fixtures/automatic_css/acss_settings.json` |
| Exact byte length | `92199` |
| SHA-256 | `19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05` |
| Version binding | Automatic.css 4.0.1 reference set, recorded by `fixtures/automatic_css/SOURCE.md` and the scoped provenance decision |
| Fixture option | `option-contextual-color-variables=on` |

The digest identifies the exact repository fixture bytes. It is not a vendor
signature and does not establish vendor version by itself. The version
binding comes from the reviewed provenance record. The proof does not cover
arbitrary Automatic.css 4.0.1 exports.

The accepted fixture is distinct from S5, which identifies the separate
source-environment settings export. Their hashes must not be treated as
interchangeable or described as byte-identical. The future trusted conversion
is limited to the already approved internal-conversion context. The 2026-11-03
publication approval covers the exact fixture identity and version-provenance
metadata only. It does not approve fixture-content redistribution or expand
project-use permission. Fixture contents, configuration exports, plugin
source, generated stylesheets, and other Automatic.css material remain
outside this approval. Broader fixture project use and redistribution remain
unknown. A project owner must separately authorize any broader use.

```text
R3_FIXTURE_METADATA_PUBLICATION_APPROVED=YES
APPROVAL_SCOPE=R3_SOURCE_IDENTITY_VERIFICATION_METADATA_ONLY
APPROVAL_DATE=2026-11-03
FIXTURE_CONTENT_REDISTRIBUTION_STATUS=unknown
BROADER_FIXTURE_PROJECT_USE_STATUS=unknown
BROADER_AUTOMATIC_CSS_REDISTRIBUTION_STATUS=unknown
PROOF_IMPLEMENTATION_AUTHORIZED=NO
BG_IMPLEMENTATION_AUTHORIZED=NO
FINAL_GENERATION_AUTHORIZED=NO
```

## 3. Trusted ingestion boundary

The future trusted entrypoint is `AutomaticCSS.from_reference_file/2`. Its
contract is:

1. The Loader reads at most `REFERENCE_FIXTURE_SIZE_BYTES + 1` bytes from one
   input. It checks the exact length and digest against the fixed accepted
   fixture identity before decoding.
2. Verification and JSON decoding use the same byte sequence. The Loader does
   not read the file again for decoding.
3. The path only locates the bytes. A different path with the exact approved
   bytes may pass; the expected path with different bytes must fail. The
   digest, source version, and provenance binding are fixed internally. The
   trusted call does not use caller `source_version` or
   `source_version_status` values, and caller options cannot select or replace
   the fixed binding.
4. The adapter consumes successful verification immediately in its private
   trusted conversion flow. It returns no reusable proof object and stores no
   proof field, verification flag, or attestation in TokenSet metadata.
5. A read, size, digest, provenance-binding, decode, or supported-input
   failure returns an error. Diagnostics stay bounded and omit source bytes,
   input contents, caller assertions, and untrusted paths. The operation does
   not retry through a legacy API or turn a rejected input into a decoded-map
   claim.

Keep `AutomaticCSS.from_file/2`, `from_json/2`, and `normalize/2` backward
compatible. Their existing descriptive `source_version` and
`source_version_status` behavior remains descriptive only. Caller-supplied
versions, statuses, metadata, filenames, paths, or decoded maps cannot grant
BG authority. The public Normalizer entrypoint also cannot grant that
authority from its arguments.

The private trusted adapter flow may run the existing Normalizer, then add
the one BG alias only after the byte proof, accepted provenance binding,
exact feature guard, source-key check, and token-path check pass. It does so
before final TokenSet validation. Do not add BG proof handling, a proof option,
or a BG metadata case to the generic Normalizer. Do not add a public proof
object or a new TokenSet schema field.

A successful proof does not bypass direct-owner validation. The future alias
is usable only when direct-owner selection finds one owner path and its token
is present, resolved, and has a terminal supported by the CSS consumer. Do
not add usable BG authority if that terminal gate fails. Keep the source
expression unresolved when an owner or terminal check fails. If source
verification fails, trusted ingestion returns an error.

## 4. Alias and terminal outcomes

Use the existing `VariableAuthority.resolve_direct_owner/2` and
`resolve_direct_owner_terminal/2` APIs. Leave `resolve/2`, `resolve_terminal/2`,
and the direct-owner APIs unchanged. The TokenSet key remains the owner path;
source references do not count as owners.

| State | Result |
| --- | --- |
| `UNVERIFIED` | Legacy calls receive no new BG authority, regardless of caller-supplied labels or metadata. |
| `REJECTED_MISMATCH` | A byte length or digest mismatch returns a terminal source error. No fallback conversion runs. |
| `REJECTED_UNSUPPORTED_SOURCE` | A missing or unsupported fixed provenance binding returns a terminal source error. Caller labels cannot supply the binding. |
| `REJECTED_INVALID_INPUT` | An unreadable, malformed, or unsupported input returns a terminal source error. |
| `FEATURE_DISABLED` | A missing, `off`, or invalid feature value adds no BG alias; the direct expression stays unresolved. |
| `NO_OWNER` | No direct-owner record exists; the direct expression stays unresolved. |
| `AMBIGUOUS_OWNERS` | More than one distinct owner path exists; do not choose by order or equal value. The expression stays unresolved. |
| `OWNER_TOKEN_MISSING` | The selected owner path is absent; the expression stays unresolved. |
| `OWNER_TOKEN_UNRESOLVED` | The selected token is unresolved; the expression stays unresolved. |
| `OWNER_TERMINAL_UNAVAILABLE` | The token has no supported terminal; the expression stays unresolved. |
| `UNIQUE_OWNER` | Resolve only when the exact BG guards pass and the direct-owner terminal API returns a supported terminal. |

The approved fixture has the exact feature value `on`. Modified bytes with the
option changed, removed, or invalid fail identity verification before decode.
Tests may exercise the feature guard separately, but those tests must not
claim that modified bytes passed verification.

## 5. Native package boundary

`TokenBridge.package_css_variable/1` is defined in
`apps/live_frames/lib/live_frames/styling/token_bridge.ex`. The proposed native
mapping remains:

```text
TOKEN_PATH=color.background.ultra_light
PACKAGE_VARIABLE=--lf-color-background-ultra-light
PACKAGE_COLLISION_COUNT=0
TOKEN_PATH_COLLISION_COUNT=0
```

The future implementation must add this mapping to
`apps/live_frames/priv/token_maps/native_shared_v3.json` in the same change as
the private trusted adapter alias. It must use the existing resolved token
reference and CSS safety checks. Do not add a literal color or pass through a
source variable. Missing, unresolved, non-serializable, ambiguous, or unsafe
token values must fail closed.

The future authorized implementation must regenerate these assets
reproducibly and commit the generated output:

- `apps/live_frames/assets/css/theme/lf_theme.css`
- `apps/live_frames/priv/static/live_frames/css/live_frames.css`

Do not hand-edit either asset. Do not inline `var(--bg-ultra-light)` or a
guessed color.

## 6. Later implementation tests and identity controls

The later implementation must cover the following behavior:

- Exact fixture ingestion through `from_reference_file/2`, including one
  bounded read, one digest calculation, and verification and decoding of the
  same bytes.
- Exact-byte identity, wrong length, modified bytes, unsupported binding,
  unreadable input, malformed JSON, and rejected-input behavior without a
  legacy fallback.
- Caller-spoofing rejection for `source_version`, `source_version_status`,
  caller metadata, filenames, paths, and decoded maps.
- Backward compatibility for `from_file/2`, `from_json/2`, `normalize/2`,
  and the public Normalizer entrypoint.
- Exact BG alias selection, including the fixture proof, feature value `on`,
  source key, token path, and authority record fields.
- Missing, disabled, or invalid feature values add no alias. Isolated feature
  guard tests must not manufacture a proof.
- No-owner, ambiguous-owner, missing-token, unresolved-token, unsupported
  terminal, and supported-terminal cases. The source expression remains
  unresolved whenever an authority or terminal gate fails.
- `--black-trans-10` and `--text-dark-muted` remain unresolved.
- Exact and unique package mapping, TokenBridge terminal safety and
  determinism, and deterministic generated asset output with drift coverage.

Keep the relevant focused coverage in these existing test files:

- `apps/live_frames/test/live_frames/automatic_css_adapter_test.exs`
- `apps/live_frames/test/live_frames/tokens/variable_authority_test.exs`
- `apps/live_frames/test/live_frames/bricks_design_ir_test.exs`
- `apps/live_frames/test/live_frames/styling/token_bridge_test.exs`
- `apps/live_frames/test/live_frames/styling/assets_drift_test.exs`

The historical R2 map-input procedure and identities remain fixed:

```text
CONTROL_PROCEDURE=HISTORICAL_DECODED_MAP_INPUT
CONTROL_INPUT_BOUNDARY=decoded Bricks map + decoded ACSS map
CONTROL_SHA256=bddf757881a116070e1973cad280115f5e6c30cb6a70beeb70f166bf61420a64
CONTROL_CANONICAL_BYTES=411416
R2_SHA256=b607eff3f51ca12ec3db6ae5aa29ca43588e1e7716061850d27e5ac35058f8a5
R2_CANONICAL_BYTES=411535
```

The historical `AutomaticCSS.normalize/2` map route must continue to reproduce
the R2 control. A new R3 DesignDocument identity requires separate approval.
This proposal issues no new DesignDocument identity, changes no Design IR
schema, and authorizes no final generation.

Do not add or run the future implementation tests in this authority-only
change.

## 7. Publication, performance, and scope limits

Fixture metadata publication does not publish fixture contents and does not
broaden project-use permission. Keep future trusted conversion within the
approved internal-conversion context unless the project owner records a
separate authorization.

Verification runs once per trusted conversion. Read no more than the fixture
size bound plus one sentinel byte, hash once, and decode the same byte
sequence. Do not hash per token. Do not add Redis, ETS, a database,
GenServer, PubSub, a cache, or another runtime component.

This authority covers one conditional BG source-output alias and the required
native package mapping. It does not authorize `--text-dark-muted`,
`--black-trans-10`, other source versions or exports, a generic proof system,
R4, R5, production implementation, or final generation.

Stop if any of these conditions occurs:

```text
STOP=MAIN_AUTHORITY_MOVED
STOP=SOURCE_PROOF_DESIGN_CONFLICT
STOP=TRUST_BOUNDARY_WIDENED
STOP=CALLER_FORGEABLE_VERIFICATION
STOP=FIXTURE_PERMISSION_SCOPE_EXPANDED
STOP=GENERIC_NORMALIZER_AUTHORITY_REQUIRED
STOP=UNRESOLVED_COLOR_AUTHORITY_ADDED
STOP=R2_IDENTITY_MODIFIED
STOP=OUT_OF_SCOPE_FILE_CHANGE
STOP=PRODUCTION_IMPLEMENTATION_STARTED
STOP=CI_FAILURE
```

This proposal's next step is independent review. It does not authorize proof
implementation, BG implementation, or final generation.

```text
STOP=AWAIT_BG_IMPLEMENTATION_AUTHORITY_PR_REVIEW
```
