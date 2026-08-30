# LiveFrames

LiveFrames is a Phoenix umbrella project for converting visual-builder design
sources into reusable LiveView components.

## Current status

Phase 3 is complete and merged to `main` in [PR #3](https://github.com/JCSchoeman96/LiveFrames/pull/3).
The merge commit is `eb67286e128526d0a746f8098cfd750cd5f167f2`.

Phase 4 has not started. The next planned task is the Bricks adapter for the
approved Hero India fixture. That work requires separate authorization.

Current work is documentation and repository maintenance only.

## Done

- Phase 0: repository, umbrella apps, quality gates, fixtures, provenance and
  private-reference boundaries.
- Phase 1: Phoenix LiveView preview app, PhoenixStorybook mount, proof
  component and conversion-lab shell.
- Phase 2: framework-independent Design IR `1.0.0` with validation,
  diagnostics and deterministic JSON serialization.
- Phase 3: source-independent TokenSet `1.0.0` and the compile-time
  Automatic.css `4.0.1` settings adapter.

Phase 3 normalizes the approved ACSS settings fixture into a narrow semantic
token set with 71 canonical tokens and a 43-token `hero_foundation` profile. It
preserves provenance, references, unresolved values and strict required-token
diagnostics. It does not make Automatic.css a runtime dependency. The generated
ACSS variable `--neutral-ultra-dark-trans-60` remains a later source-dependency
concern because its value is not proven by the approved settings evidence.

## Architecture

```text
Automatic.css settings -> ACSS adapter -> LiveFrames TokenSet
Bricks JSON             -> future adapter -> Design IR
TokenSet + Design IR    -> future generators
```

The reusable library lives in `apps/live_frames`. The preview application in
`apps/live_frames_preview` may depend on the library, never the reverse.

## Not started

- Bricks parsing, tree reconstruction and global-class resolution
- Hero India conversion to Design IR
- HEEx or LiveView component generation
- Tailwind token bridging or SCSS generation
- runtime ACSS generation, WordPress integration or asset resolution

## Repository map

- `apps/live_frames`: reusable library, Design IR, TokenSet and source adapters
- `apps/live_frames_preview`: Phoenix preview and conversion-lab shell
- `fixtures`: reviewed deterministic inputs
- `imports`: mutable source intake and review state
- `sources`: supplied raw experiments and exports
- `private_reference`: local, gitignored vendor/reference material
- `docs`: specifications, phase notes and compatibility records

The approved inputs are `fixtures/automatic_css/acss_settings.json` and
`fixtures/bricks/bricks_components.json`. The ACSS adapter consumes only its
documented settings subset. No Bricks parser consumes the Bricks fixture yet.

## Local development

Requirements: Elixir 1.19.3, OTP 28, Phoenix 1.8.13 and Phoenix LiveView
1.2.11.

```sh
mix setup
mix check
mix assets.build
mix phx.server
```

The preview runs at `http://localhost:4000/`. Useful routes are `/health`,
`/storybook` and `/liveframes/lab`.

Read [the master specification](docs/00_LIVEFRAMES_MASTER_SPEC.md) for the
authoritative architecture and
[the ACSS adapter notes](docs/06_ACSS_TOKEN_ADAPTER.md) for the current
TokenSet contract.
