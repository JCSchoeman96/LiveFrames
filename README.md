# LiveFrames

LiveFrames is being built as a reusable Phoenix LiveView component compiler
with a separate preview and conversion lab. The repository is currently at
Phase 0 of [`docs/00_LIVEFRAMES_MASTER_SPEC.md`](docs/00_LIVEFRAMES_MASTER_SPEC.md):
the project boundary is established, but compiler behavior is deliberately
not implemented yet.

## Local requirements

- Elixir 1.19.3
- OTP 28
- Phoenix 1.8.9-generation dependencies
- Phoenix LiveView 1.1-generation dependencies

Run the baseline checks with:

```sh
mix setup
mix check
```

The preview foundation can be started with:

```sh
mix phx.server
```

It listens on `http://localhost:4000/` in development. `/health` is the
minimal boot check for the preview application.

## Repository boundaries

- `apps/live_frames` is the reusable library. It has no Phoenix dependency.
- `apps/live_frames_preview` is the Phoenix/LiveView preview application and
  may depend on `live_frames`, never the reverse.
- `imports/` is mutable source intake and review state.
- `fixtures/` contains deterministic inputs that are safe to use in tests.
- `private_reference/` is reserved for local, gitignored vendor and plugin
  references. It is never a runtime dependency.
- `placeholders/` contains future asset placeholders by aspect ratio.
- `sources/` preserves the supplied raw experiments and exports.

The supplied Bricks export is staged at
`fixtures/bricks/bricks_components.json`; the supplied ACSS settings export is
staged at `fixtures/automatic_css/acss_settings.json`. Their provenance is
recorded beside the fixtures. No parser or adapter consumes them in Phase 0.

## Phase 0 boundary

This phase includes only the umbrella, package/preview split, source/privacy
folders, provenance records, documentation placeholders, formatter, tests, CI
and a bootable preview endpoint. Design IR, Bricks parsing, ACSS normalization,
real catalogue components, Tailwind, Storybook and code generation begin in
later phases and must not be added under this gate.
