# Roadmap

**Authoritative architecture roadmap:** [`00_LIVEFRAMES_MASTER_SPEC.md`](00_LIVEFRAMES_MASTER_SPEC.md)

**Current repository checkpoint:** `c09e6fd721e003ce65ffd46c359adc027cf70efb`

## Execution status (post–Phase 6, C09 programme)

- **Phase 6:** CLOSED / accepted
- **First native Hero tracer:** accepted (terminal for that native tracer lifecycle only; see `docs/19`)
- **C09D5 (proposer):** complete — authority and `ComponentizationProposer` implementation
- **Catalogue library infrastructure:** implemented (schema, manifest, lifecycle, Registry, fingerprint, versioning, discovery in `LiveFrames.Catalogue`)
- **Production Catalogue:** `apps/live_frames/priv/catalogue/` **absent**; compile-time Registry membership **empty**; canonical Hero Catalogue manifest **absent**
- **G1 architecture/spec (docs/23–24):** approved written architecture; historical “implementation NOT AUTHORIZED” language refers to the pre-#48 programme gate, not denial that library Catalogue code exists today
- **Native Phoenix/HEEx generator (C09D6-C):** implemented / merged on `main` (PR #135 — `c09e6fd721e003ce65ffd46c359adc027cf70efb`); emission surface frozen in [`docs/development/c09d6_native_generation_authority.md`](development/c09d6_native_generation_authority.md) **v6 / C09D6-C0** (§10.4.1, §10.10–§10.17)
- **Reviewer approval (C09D6-B):** implemented / accepted on `main` (PR #134 — `ComponentReview`, shared `validate_generation_prerequisites/3`)
- **Native styling generator (C09D6-D):** **preflight active** — [`docs/development/c09d6d_cta_tango_style_coverage_preflight.md`](development/c09d6d_cta_tango_style_coverage_preflight.md); implementation **gated** on D0 style-coverage result
- **P10 consumer ejection:** **not implemented** / not authorized
- **Next static native tracer (provisional):** CTA Tango — **provisional** until C09D6-D0 passes; componentization (C09D7-A) **not authorized** before C → D

### Near-term sequence (pointer)

```text
C09D6-A → C09D6-B → C09D6-C0 → C09D6-C → C09D6-D → C09D7-A → C09D7-B → C09D7-C → P9 → P10
```

Details: C09D6-A authority §18.

Later implementation phases require explicit owner authorization. This file is a short status pointer, not a second master specification.
