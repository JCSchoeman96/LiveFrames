# Roadmap

**Authoritative architecture roadmap:** [`00_LIVEFRAMES_MASTER_SPEC.md`](00_LIVEFRAMES_MASTER_SPEC.md)

**Current repository checkpoint:** `3e75c70433aac1f783221b0c6de3af43679598da` (D1D merged on main; post-merge CI run `37961704551` passed; tree `ea85c0adcaf484c8616e114a8680f5a82ac18ee1`)

## Execution status (post–Phase 6, C09 programme)

- **Phase 6:** CLOSED / accepted
- **First native Hero tracer:** accepted (terminal for that native tracer lifecycle only; see `docs/19`)
- **C09D5 (proposer):** complete — authority and `ComponentizationProposer` implementation
- **Catalogue library infrastructure:** implemented (schema, manifest, lifecycle, Registry, fingerprint, versioning, discovery in `LiveFrames.Catalogue`)
- **Production Catalogue:** `apps/live_frames/priv/catalogue/` **absent**; compile-time Registry membership **empty**; canonical Hero Catalogue manifest **absent**
- **G1 architecture/spec (docs/23–24):** approved written architecture; historical “implementation NOT AUTHORIZED” language refers to the pre-#48 programme gate, not denial that library Catalogue code exists today
- **Native Phoenix/HEEx generator (C09D6-C):** implemented / merged on `main` (PR #135 — `c09e6fd721e003ce65ffd46c359adc027cf70efb`); emission surface frozen in [`docs/development/c09d6_native_generation_authority.md`](development/c09d6_native_generation_authority.md) **v6 / C09D6-C0** (§10.4.1, §10.10–§10.17)
- **Reviewer approval (C09D6-B):** implemented / accepted on `main` (PR #134 — `ComponentReview`, shared `validate_generation_prerequisites/3`)
- **C09D6-D0 (CTA Tango style-coverage preflight):** R5 is **complete / merged / accepted** (PR #147; approved head `48d932e616da0a0a9a3c96f1ddd7a6d3cce19c8a`; merge `20a171bd35187354548eeaea4a58d631d37bd056`; post-merge CI `37920340234` PASS). The existing 30-row evidence remains in [`docs/development/c09d6d_cta_tango_style_coverage_preflight.md`](development/c09d6d_cta_tango_style_coverage_preflight.md) and is not changed here.
- **D0E1 (ACSS 4.0.1 structural grid evidence):** **complete / merged** (PR #138) — [`docs/evidence/c09d6_d0e1_acss_4_0_1_grid_authority.md`](evidence/c09d6_d0e1_acss_4_0_1_grid_authority.md)
- **D0E2 (ACSS 4.0.1 text-scale evidence):** **complete / merged** (PR #139) — [`docs/evidence/c09d6_d0e2_acss_4_0_1_text_scale_authority.md`](evidence/c09d6_d0e2_acss_4_0_1_text_scale_authority.md)
- **C09D6-D0R1 (upstream styling gap authority):** **complete / merged / accepted** (PR #140 — `fa5a6f3991427d5af4ffa0d1bb66313f920a8660`) — [`docs/development/c09d6d_upstream_style_gap_resolution_authority.md`](development/c09d6d_upstream_style_gap_resolution_authority.md); freezes G-* architecture for R2–R5
- **R1:** complete / merged / accepted (PR #140)
- **R2 (G-GRID-STRUCT):** complete / merged / accepted (PR #141)
- **C09D6-D0R2A (Design IR 3.0.0 + `docs/03` + structured semantic calculation):** complete / merged / accepted (PR #142)
- **R3 (shared token / value normalization):** complete / merged / accepted (PR #143 — `518b382c73418da97cd6908c84f49b1d03f78bfa`)
- **R4 (G-CUSTOM-CSS bounded normalization):** complete / merged / accepted (PR #144; approved head `1e6e99615abcaab1d68f5aaa29376263bcdc526b`)
- **R5 (CTA Tango full style-coverage rerun):** **complete / merged / accepted** (PR #147; merge `20a171bd35187354548eeaea4a58d631d37bd056`; post-merge CI `37920340234` PASS)
- **D1A–D1D (C09D6-D1 authority and styling implementation):** **complete / merged / accepted**. D1D merged as `3e75c70433aac1f783221b0c6de3af43679598da`; post-merge CI `37961704551` passed.
- **C09D7-A (CTA Tango componentization):** **authorized to begin**. No component contract or plan decisions are accepted by this status.
- **C09D7-B (CTA generation and browser verification):** **not authorized**
- **C09D7-C (consumer proof and Catalogue handoff):** **not authorized**
- **P10 consumer ejection:** **not implemented** / not authorized
- **Next static native tracer:** CTA Tango; its componentization phase may now begin under C09D7-A.

```text
R5=COMPLETE_MERGED_ACCEPTED
R5_PR=147
R5_MERGE_SHA=20a171bd35187354548eeaea4a58d631d37bd056
R5_POST_MERGE_CI=37920340234
R5_POST_MERGE_CI=PASS
D1A=ACCEPTED
D1B=ACCEPTED
D1C=ACCEPTED
D1D=ACCEPTED
D1D_MERGE_SHA=3e75c70433aac1f783221b0c6de3af43679598da
D1D_POST_MERGE_CI=37961704551
D1D_POST_MERGE_CI_RESULT=PASS
D1=COMPLETE_MERGED_ACCEPTED
C09D7_A_AUTHORIZED=YES
C09D7_B_AUTHORIZED=NO
C09D7_C_AUTHORIZED=NO
P9_AUTHORIZED=NO
P10_AUTHORIZED=NO
```

### Near-term sequence (pointer)

```text
C09D6-A → C09D6-B → C09D6-C0 → C09D6-C → R5 accepted → D1 accepted → C09D7-A → C09D7-B → C09D7-C → P9 → P10
```

Details: C09D6-A authority §18.

Later implementation phases require explicit owner authorization. This file is a short status pointer, not a second master specification.
