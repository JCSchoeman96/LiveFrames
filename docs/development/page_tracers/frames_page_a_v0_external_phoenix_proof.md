# Page A v0 external Phoenix consumer proof

## Outcome

Terminal outcome: `PASSED`.

- ConsumerProofRun: `page-a-v0-phoenix-20261020t075455z-2156130`
- Consumer root: `/tmp/liveframes_page_a_v0_consumer_20261020t075455z_2156130`
- LiveFrames worktree: `/home/jcschoeman96/projects/current/LiveFrame/.worktrees/lead3-page-a-v0-implementation`
- Branch and starting HEAD: `feat/lead3-page-a-v0`, `b484ef7536a840e18ead81214da304f509f7aede`

The lifecycle completed in this order:

1. `DEFINED`: the consumer proof used the Task 3 requirements in `docs/superpowers/plans/2026-10-20-lead3-page-a-v0.md` and its bounded brief.
2. `ENVIRONMENT_READY`: Phoenix installer 1.8.1 generated a new app under `/tmp`. Elixir was 1.19.3, OTP was 28, and Mix was 1.19.3.
3. `DEPENDENCY_RESOLVED`: `mix deps.get` resolved the single local LiveFrames path dependency and the Hex dependencies. Phoenix resolved to 1.8.15 and Phoenix LiveView to 1.2.12.
4. `PAGE_RENDERED`: the consumer's `GET /` test returned HTTP 200 and asserted exactly one `lf-hero` section and two `lf-section-media-call-to-action` sections. It checked their distinct IDs and synthetic headings.
5. `ASSETS_VERIFIED`: the consumer's `GET /live_frames/css/live_frames.css` test returned HTTP 200 through the host endpoint's `Plug.Static`. The response contained both component selectors. The host file was byte-identical to the package's precompiled CSS, SHA-256 `cf50491747fd67abbc76625f2532debf1f64b62c50ff2870fafb97960b7043f4`.
6. `PASSED`: the requested dependency, compile, and test commands passed, and the consumer boundary checks below passed.

## Consumer setup

The successful generator command used the Task 3 profile exactly:

```sh
mix phx.new /tmp/liveframes_page_a_v0_consumer_20261020t075455z_2156130 \
  --no-install --no-ecto --no-mailer --no-dashboard --no-gettext \
  --no-tailwind --no-version-check
```

The consumer declares one local path dependency:

```text
/home/jcschoeman96/projects/current/LiveFrame/.worktrees/lead3-page-a-v0-implementation/apps/live_frames
```

The package source identity is LiveFrames commit `b484ef7536a840e18ead81214da304f509f7aede`, package tree `ca3cff9c20d463d987e389861be7e85d77a9a7d0`. Mix resolved the path directly from the supplied checkout. The consumer has no `deps/live_frames` copy or symlink.

The generated host initially declared Phoenix LiveView `~> 1.1.0`; the LiveFrames package requires `~> 1.2.11`. The consumer constraint was set to `~> 1.2.11` before dependency resolution. Mix resolved 1.2.12.

The consumer page imports `LiveFrames.Components.Sections.Hero.hero/1` and `LiveFrames.Components.Sections.MediaCallToAction.media_call_to_action/1`. It renders one Hero and two CTA instances with distinct caller-owned text, image descriptions, IDs, and links. All values are synthetic.

The host Plug.Static serves `priv/static/live_frames/css/live_frames.css` and returns HTTP 200. The copied package CSS matches the package asset byte for byte, SHA-256 `cf50491747fd67abbc76625f2532debf1f64b62c50ff2870fafb97960b7043f4`. The host copied no LiveFrames CSS source files and ran no CSS build.

## Commands and results

All commands below ran from the consumer root.

| Command | Result |
| --- | --- |
| `mix deps.get` | PASS. Phoenix 1.8.15, Phoenix LiveView 1.2.12, and all dependencies resolved. |
| `mix compile --warnings-as-errors` | PASS. Exit 0, no warnings. |
| `mix test` | PASS. 6 tests, 0 failures. |
| `mix precommit` | PASS. Exit 0, 6 tests, 0 failures. |

The focused consumer test first ran before the page and static path were implemented. It reported 2 expected failures: the generated Phoenix page had no Page A sections, and the CSS request returned 404. After implementation, that focused test passed with 2 tests and 0 failures.

The first invocation was `mix phx.new /tmp/liveframes-page-a-v0-consumer-20261020T075439Z-2154295 --no-install --no-ecto --no-mailer --no-dashboard --no-gettext --no-tailwind --no-version-check`. Phoenix rejected the inferred app name because the path contained hyphens and an uppercase timestamp; no files were created. The successful command used a lowercase, underscore-only path.

## Boundary checks

- The consumer root resolves to `/tmp/liveframes_page_a_v0_consumer_20261020t075455z_2156130`, outside the LiveFrames repository and every LiveFrames worktree.
- `mix.exs` contains exactly one local path dependency, to the specified `apps/live_frames` path. No `live_frames_preview` or `phoenix_storybook` dependency resolved.
- The consumer source and configuration scan found no `private_reference`, Bricks export, ACSS data, WordPress runtime, or source-system runtime markers. No `fixtures`, `acss`, `private_reference`, or `apps/live_frames_preview` directory exists in the consumer. The only copied LiveFrames file is the precompiled CSS asset recorded above.
- No Ecto, Phoenix Ecto, PostgreSQL, or Postgres dependency resolved. The consumer has no database repository configuration.
- The consumer has no Tailwind dependency in its own `mix.exs`, Tailwind configuration, or Tailwind build command. `mix deps` lists Tailwind 0.5.1 because the LiveFrames package declares it as `runtime: false`. The host serves precompiled CSS without a Tailwind build. Its `assets.build` alias is for the host's esbuild bundle and was not needed for this proof.
- No browser proof was run. Browser verification belongs to Task 4.

## Repository state

Before the proof document was created, `git status --porcelain=v1` was empty at starting HEAD `b484ef7536a840e18ead81214da304f509f7aede`. The `apps/live_frames` package path was clean before and after the consumer run. After committing this proof document, `git status --porcelain=v1` was empty.

The repository-wide gate set was not run, as Task 3 explicitly excludes it. No readiness report was changed. No later task was started. No PR was opened, and no CI run was started.
