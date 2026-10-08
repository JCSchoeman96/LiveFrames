# Roadmap

**Authoritative architecture roadmap:** [`00_LIVEFRAMES_MASTER_SPEC.md`](00_LIVEFRAMES_MASTER_SPEC.md)

**Current repository checkpoint:** `b58e9bc9b561c9367c27fd479323b6ea290fbea2`

## Execution status (post–Phase 6, C09 programme)

- **Phase 6:** CLOSED / accepted
- **First native Hero tracer:** accepted (terminal for that native tracer lifecycle only; see `docs/19`)
- **C09D5 (proposer):** complete — authority and `ComponentizationProposer` implementation
- **Catalogue library infrastructure:** implemented (schema, manifest, lifecycle, Registry, fingerprint, versioning, discovery in `LiveFrames.Catalogue`)
- **Production Catalogue:** `apps/live_frames/priv/catalogue/` **absent**; compile-time Registry membership **empty**; canonical Hero Catalogue manifest **absent**
- **G1 architecture/spec (docs/23–24):** approved written architecture; historical “implementation NOT AUTHORIZED” language refers to the pre-#48 programme gate, not denial that library Catalogue code exists today
- **Native Phoenix/HEEx generator (C09D6-C):** implemented / merged on `main` (PR #135 — `c09e6fd721e003ce65ffd46c359adc027cf70efb`); emission surface frozen in [`docs/development/c09d6_native_generation_authority.md`](development/c09d6_native_generation_authority.md) **v6 / C09D6-C0** (§10.4.1, §10.10–§10.17)
- **Reviewer approval (C09D6-B):** implemented / accepted on `main` (PR #134 — `ComponentReview`, shared `validate_generation_prerequisites/3`)
- **C09D6-D0 (CTA Tango style-coverage preflight):** **complete / BLOCKED** — [`docs/development/c09d6d_cta_tango_style_coverage_preflight.md`](development/c09d6d_cta_tango_style_coverage_preflight.md) (`C09D6_D_STYLE_COVERAGE=BLOCKED`); **D0 must be rerun** after upstream G-* gaps close (R5)
- **D0E1 (ACSS 4.0.1 structural grid evidence):** **complete / merged** (PR #138) — [`docs/evidence/c09d6_d0e1_acss_4_0_1_grid_authority.md`](evidence/c09d6_d0e1_acss_4_0_1_grid_authority.md)
- **D0E2 (ACSS 4.0.1 text-scale evidence):** **complete / merged** (PR #139) — [`docs/evidence/c09d6_d0e2_acss_4_0_1_text_scale_authority.md`](evidence/c09d6_d0e2_acss_4_0_1_text_scale_authority.md)
- **C09D6-D0R1 (upstream styling gap authority):** **in review / not yet accepted on `main`** — [`docs/development/c09d6d_upstream_style_gap_resolution_authority.md`](development/c09d6d_upstream_style_gap_resolution_authority.md); freezes G-* architecture for R2–R5
- **C09D6-D0R2A (Design IR 3.0.0 + structured semantic calculation):** **not implemented** — required after R2 and before R3 for G-GRID-GAP-CALC (see D0R1 §8)
- **R2 / R3 / R4 / R5 (upstream implementation):** **not implemented**
- **Native styling generator (C09D6-D / D1):** **not authorized** — blocked until R5 D0 rerun passes; see D0R1 dependency graph
- **P10 consumer ejection:** **not implemented** / not authorized
- **Next static native tracer (provisional):** CTA Tango — **provisional**; componentization (C09D7-A) **not authorized** until C09D6-D succeeds (sequence remains C → D → D7-A)

### Near-term sequence (pointer)

```text
C09D6-A → C09D6-B → C09D6-C0 → C09D6-C → C09D6-D → C09D7-A → C09D7-B → C09D7-C → P9 → P10
```

Details: C09D6-A authority §18.

Later implementation phases require explicit owner authorization. This file is a short status pointer, not a second master specification.
