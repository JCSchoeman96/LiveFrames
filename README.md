# LiveFrames

LiveFrames is a Phoenix/LiveView design compiler and reusable UI-component
platform. It adapts design sources into source-independent compiler contracts,
preserves provenance, and produces deterministic fidelity output before later
native componentization.

## Current status

`Master Phase 5 = CLOSED`

P5-H0, P5-H1, and Phase 5B responsive generation and exact browser-boundary
verification are complete. Phase 5C-D is accepted, and the verification
lifecycle is `accepted`.

The Hero source asset is `unavailable` under explicit owner acceptance.
Visual comparison is complete, accessibility is verified, and runtime is
clean. Image asset fidelity remains `unavailable`, redistribution remains
`unknown`, and full visual fidelity is `not_claimed`.

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

Master Phase 5 is closed. P5-H2 Bricks Result lifecycle hardening is complete.
Hero India is accepted with the authorized unavailable-image limitation.
Phase 6 is authorized. The P6.1 native Hero API is approved. The P6.2 native
Hero implementation is present. P6.3 semantic verification is complete. P6.4A
styling-bridge architecture is approved in
`docs/20_P6_4A_NATIVE_STYLING_BRIDGE_ARCHITECTURE.md`. P6.4B1 native Hero styling
bridge is **merged** (PR #31). P6.4B2 browser verification is **verified**
(`docs/21_P6_4B2_NATIVE_HERO_BROWSER_VERIFICATION.md`). P6.4 workstream =
**verified**; Hero lifecycle = **documented**. P6.5 = **documented / owner
accepted**; P6.6 Storybook = **storybook_verified candidate**
(`docs/22_P6_6_NATIVE_HERO_STORYBOOK_VERIFICATION.md`).

## Consumer quick start (native Hero)

Assumes `:live_frames` is already a Mix dependency. Load CSS (precompiled path
preferred), then render `LiveFrames.Components.Sections.Hero.hero/1`; consumer
owns action behavior and public `--lf-*` theme overrides.

- [Package and consumer integration](docs/16_PACKAGE_AND_GENERATOR_MODEL.md)
- [CSS and Tailwind strategy](docs/11_CSS_AND_TAILWIND_STRATEGY.md)
- [Phase 6 lifecycle authority](docs/19_PHASE_6_NATIVE_COMPONENTIZATION.md)
- [P6.4B2 browser verification](docs/21_P6_4B2_NATIVE_HERO_BROWSER_VERIFICATION.md)
- [P6.6 Storybook verification (candidate)](docs/22_P6_6_NATIVE_HERO_STORYBOOK_VERIFICATION.md)

## Authority and navigation

- [Master specification](docs/00_LIVEFRAMES_MASTER_SPEC.md) — architecture and
  product authority.
- [Phase 5 hardening and acceptance authority](docs/18_PHASE_5_HARDENING_AND_ACCEPTANCE.md)
  — current execution order and gates.
- [Phase 6 native componentization authority](docs/19_PHASE_6_NATIVE_COMPONENTIZATION.md)
  — P6.1 native Hero API proposal and later-slice gates.
- [CSS and Tailwind strategy](docs/11_CSS_AND_TAILWIND_STRATEGY.md) — public/private
  CSS boundaries and override rules.
- [Package and generator model](docs/16_PACKAGE_AND_GENERATOR_MODEL.md) — consumer
  integration, Plug.Static, and Hero API usage.
- [P6.4A native styling bridge architecture](docs/20_P6_4A_NATIVE_STYLING_BRIDGE_ARCHITECTURE.md)
  — P6.4 architecture history; integration details in docs/11 and docs/16.
- [P6.4B2 native Hero browser verification](docs/21_P6_4B2_NATIVE_HERO_BROWSER_VERIFICATION.md)
  — verified browser evidence record (owner accepted).
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
