# Roadmap

**Authoritative architecture roadmap:** [`00_LIVEFRAMES_MASTER_SPEC.md`](00_LIVEFRAMES_MASTER_SPEC.md)

**Current repository checkpoint:** `98c464b4ba92d0a14e7a95b397496717c15b4835`

## Execution status (post–Phase 6, C09 programme)

- **Phase 6:** CLOSED / accepted
- **First native Hero tracer:** accepted (terminal for that native tracer lifecycle only; see `docs/19`)
- **C09D5 (proposer):** complete — authority and `ComponentizationProposer` implementation
- **Catalogue library infrastructure:** implemented (schema, manifest, lifecycle, Registry, fingerprint, versioning, discovery in `LiveFrames.Catalogue`)
- **Production Catalogue:** `apps/live_frames/priv/catalogue/` **absent**; compile-time Registry membership **empty**; canonical Hero Catalogue manifest **absent**
- **G1 architecture/spec (docs/23–24):** approved written architecture; historical “implementation NOT AUTHORIZED” language refers to the pre-#48 programme gate, not denial that library Catalogue code exists today
- **Native component generator:** **not implemented**; authority in [`docs/development/c09d6_native_generation_authority.md`](development/c09d6_native_generation_authority.md) (C09D6-A)
- **Reviewer approval (C09D6-B):** not implemented
- **P10 consumer ejection:** **not implemented** / not authorized
- **Next static native tracer (provisional):** CTA Tango — componentization/generation **not authorized** until C09D6-B+ slices land

### Near-term sequence (pointer)

```text
C09D6-A → C09D6-B → C09D6-C → C09D6-D → C09D7-A → C09D7-B → C09D7-C → P9 → P10
```

Details: C09D6-A authority §18.

Later implementation phases require explicit owner authorization. This file is a short status pointer, not a second master specification.
