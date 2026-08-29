# LiveFrames

LiveFrames is being built as a reusable Phoenix LiveView component compiler
with a separate preview and conversion lab. The repository is currently at
Phase 1 of [`docs/00_LIVEFRAMES_MASTER_SPEC.md`](docs/00_LIVEFRAMES_MASTER_SPEC.md):
the preview environment is mounted, but compiler behavior is deliberately not
implemented yet.

## Local requirements

- Elixir 1.19.3
- OTP 28
- Phoenix 1.8.13
- Phoenix LiveView 1.2.11

Run the baseline checks with:

```sh
mix setup
mix check
```

Build the preview browser assets with:

```sh
mix assets.build
```

Start the preview application with:

```sh
mix phx.server
```

It listens on `http://localhost:4000/` in development. `/health` is the
minimal boot check for the preview application. Use `PORT=4400 mix phx.server`
when port 4000 is already occupied.

## Phase 1 preview tools

- `/storybook` contains the single architecture-proof story.
- `/liveframes/lab` is the empty conversion-lab shell.

Storybook and the lab use the CSS-first Tailwind v4 bundle. ACSS settings,
Bricks JSON, Design IR and real catalogue content remain deferred.

## Repository boundaries

- `apps/live_frames` is the reusable library. It owns the Phase 1 proof
  component and depends only on the LiveView component runtime.
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
recorded beside the fixtures. No parser or adapter consumes them under the
Phase 1 gate.

## Phase 1 boundary

This phase includes the PhoenixStorybook mount, one library-owned proof
component, CSS-first Tailwind v4 assets, the empty conversion-lab shell and
development watchers. Design IR, Bricks parsing, ACSS normalization, real
catalogue components, conversion logic and code generation remain deferred.
