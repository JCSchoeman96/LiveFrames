# Feature Milan IR7 R3 Stage B BG-only implementation authorization

This decision records the project owner's approval for a later implementation
of the accepted `--bg-ultra-light` scope. Implementation remains unauthorized
until the independent-review, merge, and post-merge CI gates below pass.

```text
TASK=FEATURE_MILAN_IR7_R3_STAGE_B_AUTHORIZATION
OWNER_DECISION=APPROVE_BG_ONLY_SCOPE
OWNER_APPROVAL_STATUS=APPROVED
OWNER_APPROVAL_DATE=2026-11-04
OWNER_APPROVAL_SOURCE=EXPLICIT_OWNER_DECISION_IN_CONVERSATION

AUTHORIZATION_STATE=OWNER_APPROVED_PENDING_INDEPENDENT_REVIEW_AND_MERGE

STAGE_A_IMPLEMENTED=YES
STAGE_A_MERGED=YES
STAGE_A_MERGE_PR=375
STAGE_A_MERGE_SHA=bc0de5f31001af4e2eba1c3ef425b3211b9ebe00
STAGE_A_POST_MERGE_CI_RUN=41800744735
STAGE_A_POST_MERGE_CI=SUCCESS

BG_IMPLEMENTATION_AUTHORITY_ACCEPTANCE=PENDING_INDEPENDENT_REVIEW
BG_IMPLEMENTATION_AUTHORIZED=NO
BG_IMPLEMENTED=NO

R3_ACCEPTED_SCOPE=BG_ULTRA_LIGHT_ONLY
R4_AUTHORIZED=NO
R5_AUTHORIZED=NO
FINAL_GENERATION_AUTHORIZED=NO

VERIFIED_BASE_MAIN_SHA=bc0de5f31001af4e2eba1c3ef425b3211b9ebe00
VERIFIED_BASE_MAIN_TREE=80ea5d935e1de95ce64747456fd17d88f1b12506
VERIFIED_BASE_CI_STATUS=SUCCESS
BG_IMPLEMENTATION_AUTHORITY_BLOB=b304c7adac037efdef0555937b66fd1378fed9c2
SOURCE_PROOF_DESIGN_BLOB=4f9018c2fe5ae2fce57275a9c807026a53f94fbd
R3_COLOR_AUTHORITY_BLOB=361c1811f485e414fe323565334f4ddb27b31e83
PROOF_IMPLEMENTATION_AUTHORIZATION_BLOB=0cf0994bc59ee21cd37cf47314acf61d11308b2d
PROVENANCE_BLOB=98d20e0c8172501ebc366499c4d7b8fc7b034d65
```

The owner decision was supplied explicitly in the conversation on
2026-11-04. This record does not claim an approval URL, GitHub review, or owner
signature. The verified Stage A outcome is recorded by [merged PR
#375](https://github.com/JCSchoeman96/LiveFrames/pull/375) and its [successful
post-merge CI run](https://github.com/JCSchoeman96/LiveFrames/actions/runs/41800744735).
Earlier `NO` and `PROOF_IMPLEMENTED=NO` fields remain as historical records;
this decision does not rewrite them.

The [canonical source and provenance record](../04_SOURCE_AND_PROVENANCE.md#feature-milan-r3-bg-only-implementation-authorization)
links this decision. The existing [BG implementation authority](feature_milan_ir7_r3_bg_ultra_light_implementation_authority.md)
defines the accepted implementation contract. The [proof design](feature_milan_ir7_r3_source_identity_proof_authority.md),
[R3 color-variable authority](feature_milan_ir7_color_variable_authority.md),
and [proof implementation authorization](feature_milan_ir7_r3_proof_implementation_authorization.md)
remain governing inputs. Their recorded blobs are listed above.

## Conditional authorization gates

The decision becomes effective only after all four conditions pass:

1. The owner decision is recorded in this document.
2. Independent review accepts the existing BG implementation contract and
   this decision's exact scope.
3. This authorization PR merges successfully.
4. Post-merge CI succeeds on the exact merge commit, and the governing
   authorities remain unchanged.

Only the first condition has passed. The later states below are conditional
future states, not current accomplishments. The current record uses
`OWNER_APPROVED_PENDING_INDEPENDENT_REVIEW_AND_MERGE` for the first state.

| State | Guard or transition | Effect |
| --- | --- | --- |
| `OWNER_APPROVED_PENDING_REVIEW_AND_MERGE` | Owner approval is recorded; independent review or merge remains outstanding. | Implementation is blocked. The current `AUTHORIZATION_STATE` uses the longer identifier above for this state. |
| `MERGED_AWAITING_CI` | Independent review accepts the exact scope and the authorization PR merges. | Implementation remains blocked until post-merge CI succeeds on the exact merge SHA. |
| `AUTHORIZED_BG_ONLY` | Post-merge CI succeeds on the exact merge SHA and all governing authorities remain unchanged. | The BG-only implementation may begin. |
| `REJECTED_OR_STALE` | Review rejects the decision, CI fails, or a material authority changes. | Terminal hold. Fresh independent review is required before a new authorization decision. |

Before `AUTHORIZED_BG_ONLY`, `BG_IMPLEMENTATION_AUTHORIZED=NO` and
`BG_IMPLEMENTED=NO`. A failed CI run or changed authority does not grant
permission. Any later implementation must stop and return for fresh review if
one of those conditions occurs.

## Exact accepted BG contract

The later implementation is limited to this one conditional source-output
alias and package mapping:

```text
SOURCE=Automatic.css
SOURCE_VERSION=4.0.1

VARIABLE=--bg-ultra-light
SOURCE_KEY=bg-ultra-light
TOKEN_PATH=color.background.ultra_light

AUTHORITY_KIND=source_output_alias
AUTHORITY_ID=automatic-css-4.0.1:contextual-background:bg-ultra-light

REQUIRED_FEATURE_OPTION=option-contextual-color-variables
REQUIRED_FEATURE_VALUE=on

PACKAGE_VARIABLE=--lf-color-background-ultra-light
```

The accepted authority record belongs in the existing token's
`variable_authorities` metadata. Keep the TokenSet map key at
`color.background.ultra_light` and preserve the existing token value and
reference semantics. Add the metadata before final TokenSet validation.

## Trust boundary and implementation limits

Any later Stage B implementation must follow the accepted BG implementation
authority and these limits:

- Use the existing trusted `AutomaticCSS.from_reference_file/2` conversion
  flow verified by Stage A.
- Add the BG alias only inside that trusted adapter conversion path, after
  checking the exact feature option, source key, and token path above.
- Do not infer trusted identity from `source_version`,
  `source_version_status`, `export_version`, a Loader-returned metadata map, a
  filename, caller options, or a decoded map.
- Leave `AutomaticCSS.Normalizer`, `from_file/2`, `from_json/2`, and
  `normalize/2` unchanged. Do not add BG alias authority to a generic or public
  legacy path.
- Use the existing `VariableAuthority.resolve_direct_owner/2` and
  `resolve_direct_owner_terminal/2` APIs. Leave unsupported and ambiguous
  direct expressions unresolved.
- Include the accepted native package mapping, focused regression tests, and
  deterministic regeneration of both CSS assets: `apps/live_frames/assets/css/theme/lf_theme.css`
  and `apps/live_frames/priv/static/live_frames/css/live_frames.css`.
- Preserve the existing value and reference behavior. Do not add implementation
  behavior beyond the accepted BG authority.

This is a conversion-time metadata decision. It requires no Redis, ETS,
database, GenServer, PubSub, or cache layer. Do not add per-token hashing or
extra source reads. Reuse the single verified ingestion from Stage A.

## Fixture permissions and historical identities

The accepted trusted conversion remains limited to the approved internal
conversion context:

```text
REFERENCE_FIXTURE=fixtures/automatic_css/acss_settings.json
REFERENCE_FIXTURE_SIZE_BYTES=92199
REFERENCE_FIXTURE_SHA256=19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05

FIXTURE_CONTENT_REDISTRIBUTION_STATUS=unknown
BROADER_FIXTURE_PROJECT_USE_STATUS=unknown
BROADER_AUTOMATIC_CSS_REDISTRIBUTION_STATUS=unknown

CONTROL_SHA256=bddf757881a116070e1973cad280115f5e6c30cb6a70beeb70f166bf61420a64
R2_SHA256=b607eff3f51ca12ec3db6ae5aa29ca43588e1e7716061850d27e5ac35058f8a5
```

The 2026-11-03 publication approval remains limited to fixture identity and
version-provenance metadata. This decision does not approve redistribution,
publication of fixture bytes, or broader project use. The `CONTROL_SHA256`
and `R2_SHA256` identities remain unchanged historical records.

## Explicit exclusions

This authorization covers only `--bg-ultra-light` after the gates above pass.
It excludes `--black-trans-10`, `--text-dark-muted`, new source versions,
R4, R5, and final generation. It changes no production code, tests, token
mapping, CSS asset, Design IR, or R2 reconstruction file in this decision PR.

```text
BG_IMPLEMENTATION_AUTHORIZED=NO
BG_IMPLEMENTED=NO
R4_AUTHORIZED=NO
R5_AUTHORIZED=NO
FINAL_GENERATION_AUTHORIZED=NO
```

Before the gates pass, the next step is independent review of this decision
and the exact BG-only scope.

## Post-merge verification and R4 handoff

The `AUTHORIZATION_STATE=OWNER_APPROVED_PENDING_INDEPENDENT_REVIEW_AND_MERGE`
field above is the historical document-creation snapshot. It remains unchanged.
This section records the later effective state after the authorization and
implementation merges and their exact-head CI runs.

The independent review acceptance was recorded in this conversation. No
GitHub approving review is recorded.

```text
POST_MERGE_VERIFICATION_DATE=2026-11-04

OWNER_APPROVAL=APPROVE_BG_ONLY_SCOPE
INDEPENDENT_REVIEW=ACCEPTED_IN_CONVERSATION
INDEPENDENT_REVIEW_SOURCE=THIS_CONVERSATION
GITHUB_APPROVING_REVIEW=NONE_RECORDED

AUTHORIZATION_PR=376
AUTHORIZATION_MERGE_SHA=2055d79cd916afb2fcdd675bc4396fbd1a06d8bd
AUTHORIZATION_PR_MERGED=YES
AUTHORIZATION_POST_MERGE_CI_RUN=41804065360
AUTHORIZATION_POST_MERGE_CI_HEAD=2055d79cd916afb2fcdd675bc4396fbd1a06d8bd
AUTHORIZATION_POST_MERGE_CI=SUCCESS

GOVERNING_AUTHORITIES_UNCHANGED_THROUGH_IMPLEMENTATION=YES
BG_IMPLEMENTATION_AUTHORIZED_EFFECTIVE=YES

IMPLEMENTATION_PR=377
IMPLEMENTATION_MERGE_SHA=54d05a33f89c942c72607c851fbf782e18febe3e
IMPLEMENTATION_PR_MERGED=YES
IMPLEMENTATION_POST_MERGE_CI_RUN=41812875916
IMPLEMENTATION_POST_MERGE_CI_HEAD=54d05a33f89c942c72607c851fbf782e18febe3e
IMPLEMENTATION_POST_MERGE_CI=SUCCESS
BG_IMPLEMENTED=YES

R3_ACCEPTED_SCOPE=BG_ULTRA_LIGHT_ONLY
R3_PACKAGE_VARIABLE=--lf-color-background-ultra-light
BLACK_TRANS_10=UNRESOLVED
TEXT_DARK_MUTED=UNRESOLVED

R4_AUTHORIZED=NO
R5_AUTHORIZED=NO
FINAL_GENERATION_AUTHORIZED=NO
```

The authorization and implementation merges are recorded by [PR #376](https://github.com/JCSchoeman96/LiveFrames/pull/376)
and [PR #377](https://github.com/JCSchoeman96/LiveFrames/pull/377). The exact-head
CI runs are [41804065360](https://github.com/JCSchoeman96/LiveFrames/actions/runs/41804065360)
and [41812875916](https://github.com/JCSchoeman96/LiveFrames/actions/runs/41812875916).
The implementation status does not change source-publication or redistribution
permissions.

R4 technical readiness does not grant R4 implementation or public-output
clearance:

```text
R4_TASK=R4_SPACING_SCALE_S_PACKAGE_MAPPING
TOKEN_PATH=spacing.scale.s
PACKAGE_VARIABLE=--lf-space-scale-s

R4_TECHNICALLY_READY=YES
R4_PUBLIC_OUTPUT_CLEARANCE=NOT_ESTABLISHED
R4_OWNER_IMPLEMENTATION_APPROVAL=NOT_GRANTED
R4_IMPLEMENTATION_AUTHORIZED=NO

R5_AUTHORIZED=NO
FINAL_GENERATION_AUTHORIZED=NO
```
