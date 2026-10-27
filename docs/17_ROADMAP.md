# Roadmap

**Architecture authority:** [`00_LIVEFRAMES_MASTER_SPEC.md`](00_LIVEFRAMES_MASTER_SPEC.md)

**Status evidence baseline reviewed for this update:** `main` before this
docs-only change.

```text
STATUS_EVIDENCE_BASE_SHA=b30778d04ee016b8815a222a85c92869bc5e60a9
STATUS_EVIDENCE_BASE_TREE=c9d21c2c6e6f00b35c1a00f32a031b3384d14664
STATUS_EVIDENCE_BASE_CI=39128177913
STATUS_EVIDENCE_BASE_CI_RESULT=PASS
```

## Current status

- Design IR current version: `6.0.0`.
- C09D6-B review, C09D6-C native generation, and C09D6-D native styling are
  implemented on `main`.
- C09D7-A CTA Tango componentization and review are accepted (A3 approval
  transition, PR #184).
- C09D7-B native CTA delivery is implemented on `main`. The component API,
  package CSS, and repository Storybook verification exist.
- C09D7-C1 external consumer proof is accepted. It used
  `LOCAL_PATH_TO_EXACT_LIVE_FRAMES_APP`; it proves source-path consumption only,
  not package-boundary behavior, Hex publication, or
  `distribution.library=supported`.
- The production Catalogue contains `live_frames.section.media_call_to_action`
  in state `APPROVED`. Distribution capability claims for the item are governed
  by the C2D2R1 evidence gate and the separate C2D3 manifest-mutation gate below.
- C2D2 remains a `BLOCKED` historical evidence review at its frozen base. It
  accurately recorded the package-boundary and documentation blockers then.
- The package-boundary blocker identified by C2D2 has been remediated on `main`.
  C2D2A proves that the built and unpacked LiveFrames source package contains
  canonical `priv/catalogue/` content and `LICENSE-PROPRIETARY.txt`; package
  boundary CI verifies this content.
- C2D2B current-facing documentation remediation is accepted on `main`. It
  corrected the current-facing package and consumer status documentation; it
  did not perform the repeat capability evidence review.
- C2D2R1 is the separate capability-evidence review gate required before any
  `distribution.library=supported` claim. If it is accepted on `main`, its
  durable decision is recorded in
  `docs/development/c09d7c2d2r1_cta_library_capability_evidence_review.md`.
  The existence of an R1 review does not authorize C2D3.
- C2D3 is the separate manifest-mutation gate for persisting an accepted
  distribution capability claim. It may rely only on accepted C2D2R1 evidence
  and requires its own explicit authorization, implementation review, merge,
  and acceptance. C2D2R1 acceptance does not itself execute C2D3.
- Catalogue `APPROVED → RELEASED`, package publication, and P10 consumer-project
  ejection are independent later gates, each with its own authority and evidence
  requirements. Accepted library capability evidence and a C2D3 manifest
  mutation do not imply or execute any of these gates.

The accepted native-generation semantics remain in
[`development/c09d6_native_generation_authority.md`](development/c09d6_native_generation_authority.md).
Its embedded checkpoint is historical authority context; this file records
current implementation status. Catalogue architecture
history remains in [docs/23](23_CATALOGUE_ARCHITECTURE.md) and [docs/24](24_CATALOGUE_VERSIONING_POLICY.md).

This file is a current-status pointer. It does not replace the architecture or
semantic authority documents.
