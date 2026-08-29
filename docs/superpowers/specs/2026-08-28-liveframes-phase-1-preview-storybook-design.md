# LiveFrames Phase 1 preview and Storybook design

## Authority and scope

`docs/00_LIVEFRAMES_MASTER_SPEC.md` remains the authority. Phase 1 establishes
the rendering environment before catalogue conversion begins. It includes
PhoenixStorybook, one internal architecture-proof function component, a
static conversion-lab shell, and a CSS-first Tailwind v4 build.

It does not parse Bricks JSON, load ACSS settings, define the Design IR, render
Hero India, add a real catalogue, or add database-backed state.

## Architecture

The umbrella keeps the existing dependency direction:

```text
live_frames_preview -> live_frames
```

The reusable `live_frames` package gains the minimum Phoenix LiveView
dependency needed to define a function component. It does not depend on the
preview application, Storybook, source fixtures, ACSS or Bricks. The preview
application owns Storybook mounting, browser assets, the conversion-lab route
and development watchers.

The proof component lives in `LiveFrames.ProofComponent` and is intentionally
non-production. A Storybook story in the preview app points to that function,
which proves the reusable package can be rendered by the preview environment
without moving the component into the preview app.

## Storybook integration

Use the official `phoenix_storybook` 1.3 line. Create
`LiveFramesPreviewWeb.Storybook` with the preview OTP app, the child app’s
`storybook/` content path, `/assets/css/storybook.css`,
`/assets/js/storybook.js`, a `live-frames` sandbox class and an explicit
LiveFrames title.

Mount Storybook at `/storybook`. Mount `storybook_assets()` outside the
browser pipeline because those assets do not need CSRF protection. Mount
`live_storybook/2` inside the browser pipeline and use the existing `/live`
socket. The initial storybook contains exactly one component story for the
proof component.

## Asset pipeline

Use the `tailwind` 0.5 line and `esbuild` 0.10 line. Pin the Tailwind CLI
version in configuration and use the wrapper’s installer. The Storybook CSS
input uses Tailwind v4’s CSS-first directives and explicit `@source` paths for
the preview library and story content. The proof component’s small styles are
scoped beneath the Storybook sandbox class.

The Storybook JavaScript entry point is a small esbuild bundle that registers
empty `Hooks`, `Params` and `Uploaders` objects on `window.storybook`. This
keeps the entry point compatible with PhoenixStorybook without introducing a
third-party JavaScript framework. The development endpoint watches Tailwind,
esbuild, LiveView source and Storybook scripts.

## Conversion-lab shell

Add a LiveView at `/liveframes/lab` using the same preview root layout and
Storybook CSS bundle. It presents a static empty-state message and four
clearly named future inspection regions: source metadata, normalized tokens,
Design IR and diagnostics. The view owns no source loading, conversion state,
or persistence. A future phase can add those behaviors without changing the
route boundary.

The Phase 0 home page links to `/storybook` and `/liveframes/lab`. The existing
`/health` route remains unchanged.

## Error and safety behavior

Storybook uses its own documented route and asset helpers. No user-provided
module names, source paths or HTML are interpolated into the shell. The proof
story uses static attributes. Missing Storybook assets fail the asset-build
check rather than being fetched remotely. No ACSS/plugin archive is loaded by
the runtime.

## Tests and gate

Add tests for:

- rendering `LiveFrames.ProofComponent` as a function component;
- the Storybook backend configuration and proof story contract;
- `/storybook` returning the Storybook shell;
- `/liveframes/lab` rendering its static regions;
- the generated CSS and JavaScript asset files;
- the one-way dependency declaration; and
- the dev watcher configuration.

Run formatting, warnings-as-errors compilation, the full test suite, asset
installation/builds, `git diff --check`, and a dev-server smoke test. The
Phase 1 gate is satisfied only when Storybook loads, the proof component
appears, and the preview’s live-reload configuration is active. Stop there.
