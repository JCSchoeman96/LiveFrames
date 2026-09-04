# LiveFrames

LiveFrames is a Phoenix/LiveView design compiler and reusable UI-component
platform. It adapts design sources into source-independent compiler contracts,
preserves provenance, and produces deterministic fidelity output before later
native componentization.

## Current status

`Master Phase 5 = OPEN`

P5-H0 and P5-H1 are complete. Phase 5B responsive generation and exact
browser-boundary verification are complete, and Phase 5B is CLOSED. Phase 5C
is the current and next slice for fidelity acceptance.

Master Phase 5 remains OPEN. The Hero source asset remains `unresolved`.
Visual comparison remains `not_started`, and accessibility remains
`not_started`.

Completed foundations include:

- Phoenix umbrella/library foundation, preview application, and Storybook
  foundation.
- Design IR `1.0.0` and TokenSet `1.0.0`.
- Automatic.css settings adapter for the current required TokenSet semantics.
- Bricks structured adapter and Bricks → Design IR conversion.
- Deterministic artifacts and drift verification.
- Phase 5A fidelity HEEx/CSS generation.
- P5-H0 repository truth and provenance governance.
- P5-H1 Fidelity CSS serialization safety.
- Phase 5B authority-bound responsive generation and browser verification.
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

Remaining Phase 5 work is Phase 5C fidelity acceptance and later lifecycle
hardening before Phase 6. Hero India is not yet visually, accessibly, or
overall accepted because its source asset remains `unresolved` and visual
comparison and accessibility remain `not_started`.

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
