# LiveFrames

LiveFrames is a Phoenix/LiveView design compiler and reusable UI-component
platform. It adapts design sources into source-independent compiler contracts,
preserves provenance, and produces deterministic fidelity output before later
native componentization.

## Current status

`Master Phase 5 = OPEN`

The current tracer bullet has completed its Phase 0 through Phase 5A
foundations. The current hardening slice is P5-H0 — repository truth and
provenance governance.

Completed foundations include:

- Phoenix umbrella/library foundation, preview application, and Storybook
  foundation.
- Design IR `1.0.0` and TokenSet `1.0.0`.
- Automatic.css settings adapter for the current required TokenSet semantics.
- Bricks structured adapter and Bricks → Design IR conversion.
- Deterministic artifacts and drift verification.
- Phase 5A fidelity HEEx/CSS generation.
- Source-independent Fidelity with a caller-injected source fidelity resolver.
- Accepted Level 3 Bricks breakpoint authority: `mobile_portrait` at
  `max-width: 478px` and `tablet_portrait` at `max-width: 991px`; tablet
  remains active at mobile widths.

The current pipeline is:

```text
source
→ source adapter
→ Design IR + TokenSet
→ Fidelity
→ HEEx/CSS
→ preview
→ later native componentization
```

Remaining Phase 5 work includes repository/compiler hardening, responsive
fidelity, browser and visual verification, accessibility acceptance, and
lifecycle hardening before Phase 6. Hero India is not yet visually,
responsively, accessibly, or overall accepted.

## Authority and navigation

- [Master specification](docs/00_LIVEFRAMES_MASTER_SPEC.md) — architecture and
  product authority.
- [Phase 5 hardening and acceptance authority](docs/18_PHASE_5_HARDENING_AND_ACCEPTANCE.md)
  — current execution order and gates.
- [Source and provenance policy](docs/04_SOURCE_AND_PROVENANCE.md) — canonical
  publication and provenance governance.
- `apps/live_frames` — reusable compiler library.
- `apps/live_frames_preview` — Phoenix preview and conversion lab.
- `fixtures` — synthetic, sanitized, or explicitly redistribution-cleared
  fixture boundary; see the provenance policy for existing material.
- `sources/work` — deterministic derived compiler artifacts with upstream
  provenance retained.
- `private_reference` — private/local reference boundary, never a runtime
  dependency.

## Local development

Requirements and local commands are defined by the umbrella project. The usual
checks are:

```sh
mix setup
mix check
mix assets.build
mix phx.server
```

The preview runs at `http://localhost:4000/`; useful routes are `/health`,
`/storybook`, and `/liveframes/lab`.
