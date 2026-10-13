# C09D7-B CTA Tango IR4 reauthorization

Date: 2026-10-13

## Authority transition

PR #191 advanced the current Design IR version from `3.0.0` to `4.0.0`. The
accepted CTA DesignDocument identity from the IR3 tuple is now historical, and
the IR3 ComponentizationPlan fingerprint is invalid for current generation.
The prior Contract semantics remain current.

The IR4 preflight rebuilt the CTA DesignDocument from the same frozen source
and SemanticInput. Serializing that document with only `ir_version` reset to
`3.0.0` reproduced the accepted IR3 DesignDocument SHA-256, so no other
DesignDocument content changed. The proposed Contract encoded byte-for-byte
identically to the accepted Contract. The Plan matched the accepted IR3 Plan in
every field except `design_document_sha256`; all 13 placements remained
unchanged.

```ini
BASE_SHA=028e3f9cff4a30e99ee5a8444f1ec8b50afbd2fc
BASE_TREE=bc52956524c9376b70066e1a6e9c7676b105556d

OLD_IR3_DESIGN_DOCUMENT_SHA256=1c4f3bc9af58cb382ed2e0fc7ba64ec8bbb68c1ad55b7483894317a731272aff
IR4_DESIGN_DOCUMENT_SHA256=4799e7005221118a166a439ac6e6ecf64f7db74f293e0e338b9b1d3b82048148

PROPOSED_COMPONENT_CONTRACT_SHA256=cc62191c5f154e20a9abb9091693b56b59d4595662adabfbb82334babf8caf9c
CONTRACT_BYTE_IDENTICAL_TO_ACCEPTED=YES
CONTRACT_SEMANTICS_CHANGED=NO

OLD_IR3_PLAN_SHA256=a902960f777b684b65ecb5d8d3080da1e4b91b8098959bdd5e90fbd0dd338359
IR4_PLAN_SHA256=b74c681611f26db6c5299f2786d2fbac77a7e1a16f2f634276f07ffe600c85eb
PLAN_CHANGED_FIELDS=design_document_sha256
PLAN_PLACEMENTS_UNCHANGED=YES

GENERATION_PREREQUISITES_BEFORE_APPROVAL=:ok
HUMAN_DECISION=APPROVE
CTA_IR4_TUPLE=APPROVED
COMPONENT_REVIEW_APPROVE_EXECUTION_COUNT=1
APPROVAL_STATUS_TRANSITION=proposed->approved
APPROVAL_OTHER_FIELDS_CHANGED=NO
APPROVED_CONTRACT_SHA256=8cb4a8361711f31b7ad428fbd8e8198ef91ed96396bed69c137daa471083856a

NATIVE_GENERATOR_EXECUTION_COUNT=1
GENERATION_PREREQUISITES_AFTER_APPROVAL=:ok
GENERATED_CTA_MODULE_SHA256=795a32ca11c2e2bd456f79b81adaa801fa9d9dc72e1def5d1fba0718fe8bb8a5
GENERATED_CTA_CSS_SHA256=c7da3189d6f080237d2029df6bd48ec245d53bd921bae2da098d6745c8726746
CTA_MODULE_BYTE_IDENTICAL_TO_EXISTING=YES
CTA_CSS_BYTE_IDENTICAL_TO_EXISTING=YES
CTA_GENERATED_ARTIFACT_WRITE_REQUIRED=NO

SOURCE_ARTIFACT_BYTES_CHANGED_BY_IR4=NO
BROWSER_EVIDENCE_INVALIDATED_BY_IR4=NO
BROWSER_RERUN_REQUIRED=NO
FULL_SUITE=NOT_RUN
COMMIT=NONE
PUSH=NONE
PR=NONE
MERGED=NO
```

## Browser evidence validity

The generated CTA module and stylesheet still match the accepted browser-run
inputs byte-for-byte. PR #191 did not change NativeGenerator, the CTA preview
story or test, package theme CSS, token maps, responsive resolution, or the
breakpoint authority. The IR4 tuple refresh therefore changed identity
metadata without changing rendered CTA input bytes. The prior isolated browser
evidence remains valid; no browser run occurred during this reauthorization.

The accepted browser result remains structural. It does not claim a match for
the canonical action color, font family, or source images.
