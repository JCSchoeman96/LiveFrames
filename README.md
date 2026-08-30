# LiveFrames

LiveFrames is being built as a reusable Phoenix LiveView component compiler
with a separate preview and conversion lab. The repository is currently at
Phase 3 of [docs/00_LIVEFRAMES_MASTER_SPEC.md](docs/00_LIVEFRAMES_MASTER_SPEC.md):
the Design IR is frozen at 1.0.0, and the initial Automatic.css TokenSet
adapter is implemented without making Automatic.css a runtime dependency.

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

Storybook and the lab use the CSS-first Tailwind v4 bundle. The ACSS settings
adapter normalizes only the initial semantic subset documented in
[docs/06_ACSS_TOKEN_ADAPTER.md](docs/06_ACSS_TOKEN_ADAPTER.md). Bricks parsing,
utility-class reconstruction, real catalogue content and code generation
remain deferred.

## Repository boundaries

- `apps/live_frames` is the reusable library. It owns the frozen Design IR,
  generic TokenSet contract and initial Automatic.css settings adapter; source
  adapters remain conversion-time code.
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
recorded beside the fixtures. The Phase 3 adapter consumes only the documented
ACSS settings subset; the Bricks export has no parser yet.

## Phase 3 boundary

This phase includes the Phase 1 preview foundation, the Phase 2 Design IR
contract, and the Phase 3 versioned TokenSet/Automatic.css adapter. It does not
include Bricks parsing, Hero India conversion, HEEx generation, Tailwind token
bridging, SCSS generation or Phase 4 work.
