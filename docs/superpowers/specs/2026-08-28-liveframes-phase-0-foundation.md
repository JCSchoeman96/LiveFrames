# LiveFrames Phase 0 foundation design

## Authority

`docs/00_LIVEFRAMES_MASTER_SPEC.md` is the source of truth. This design
records only the authorized Phase 0 work and must not be read as permission to
start the compiler roadmap.

## Goal

Establish a clean umbrella repository with a reusable `live_frames` package, a
separate Phoenix LiveView `live_frames_preview` application, deterministic
source-fixture boundaries, provenance records, and quality gates.

## Boundaries

```text
live_frames_preview -> live_frames
```

`live_frames` has no Phoenix, browser, Bricks, ACSS or JSON runtime
dependency. The preview app is a minimal bootable Phoenix endpoint. It does
not contain a catalogue, Storybook, conversion lab, parser, Design IR or
generated component.

The supplied `sources/bricks_components.json` and `acss/acss.json` files are
copied into `fixtures/` as deterministic inputs with `SOURCE.md` records. The
ACSS/plugin research remains reference material only and is never loaded by
the applications.

## Repository contracts

- `imports/` is mutable intake and review state.
- `fixtures/` is for reviewed, deterministic inputs safe for repository use.
- `private_reference/` is for local vendor/plugin references and archives.
- `placeholders/` is split by landscape, portrait and square aspect ratio.
- `docs/01` through `docs/17` are subordinate placeholders under the master.
- CI checks formatting, warnings-as-errors compilation, tests and whitespace.

## Phase 0 gate

The phase is complete when the umbrella compiles, tests pass, the preview
endpoint boots, dependency direction is proven, source/privacy structure and
provenance records exist, and no Phase 1+ implementation has begun.
