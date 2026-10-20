# Page A v0 external Phoenix consumer proof

## Outcome

```text
PAGE_ID=frames_page_a_v0
CONSUMER_PROOF_RUN=page-a-v0-phoenix-correction-20261020T103945Z
CONSUMER_ROOT=/tmp/liveframes-page-a-v0-correction.2wbH27/consumer_app
TERMINAL_OUTCOME=PASSED
```

This run replaces the earlier consumer run that copied LiveFrames CSS into the host. That earlier run is superseded and does not support this outcome.

The proof used the implementation checkout at `feat/lead3-page-a-v0`, starting HEAD `86f04bb51b9e4dcfd5e0cc1dd14c076de8a67a20`. The accepted base remained `main` at `14133f14fc7d1d18e74e3786abab25c49d99b49c`. The LiveFrames package subtree was `ca3cff9c20d463d987e389861be7e85d77a9a7d0`.

## ConsumerProofRun lifecycle

1. `DEFINED`: the correction reran Task 3's consumer proof against the current implementation checkout, with package-owned static delivery as an explicit acceptance condition.
2. `ENVIRONMENT_READY`: isolated Mix and Hex homes were used to install `phx_new` 1.8.15. The fresh Phoenix host was generated under `/tmp`, outside the LiveFrames repository and all LiveFrames worktrees. Elixir was 1.19.3, OTP was 28, and Mix was 1.19.3.
3. `DEPENDENCY_RESOLVED`: `mix deps.get` passed with one local path dependency to `/home/jcschoeman96/projects/current/LiveFrame/.worktrees/lead3-page-a-v0-implementation/apps/live_frames`. The generated Phoenix, Phoenix LiveView, and Phoenix HTML requirements were left unchanged. Phoenix resolved to 1.8.16, Phoenix LiveView to 1.2.12, and Phoenix HTML to 4.3.0.
4. `PAGE_RENDERED`: the host's `GET /` endpoint test returned HTTP 200. It asserted one Hero root and two CTA roots rendered through the public Hero and MediaCallToAction APIs. The caller-owned headings, body text, links, and additive CTA classes were distinct for CTA A and CTA B.
5. `ASSETS_VERIFIED`: the host endpoint served the stylesheet directly from the `:live_frames` application. Its GET test returned HTTP 200 at `/assets/liveframes/live_frames/css/live_frames.css`; the response contained `.lf-hero` and `.lf-section-media-call-to-action`. No LiveFrames CSS or other LiveFrames file was copied into the host.
6. `PASSED`: `mix compile --warnings-as-errors` and the complete host test suite passed. Boundary checks found no private or source-system material, no preview or Storybook dependency, no Postgres requirement, and no host Tailwind build requirement.

## Generator and dependency

The isolated generator was `phx_new` 1.8.15. The host was generated with the accepted profile:

```sh
mix phx.new "$HOST_ROOT" \
  --no-install \
  --no-ecto \
  --no-mailer \
  --no-dashboard \
  --no-gettext \
  --no-tailwind \
  --no-version-check
```

Before adding the path dependency, the generated requirements were Phoenix `~> 1.8.15`, Phoenix LiveView `~> 1.2.0`, and Phoenix HTML `~> 4.1`. They were not manually edited:

```text
PHX_NEW_VERSION=1.8.15
DEPENDENCY_CONSTRAINTS_MANUALLY_EDITED=NO
DEPENDENCY_MODE=LOCAL_PATH_TO_EXACT_LIVE_FRAMES_APP
LIVE_FRAMES_RESOLVED_SHA=86f04bb51b9e4dcfd5e0cc1dd14c076de8a67a20
LIVE_FRAMES_PACKAGE_TREE=ca3cff9c20d463d987e389861be7e85d77a9a7d0
ELIXIR_VERSION=1.19.3
OTP_VERSION=28
MIX_VERSION=1.19.3
PHOENIX_VERSION=1.8.16
PHOENIX_LIVE_VIEW_VERSION=1.2.12
PHOENIX_HTML_VERSION=4.3.0
```

The host declares the local `apps/live_frames` path dependency. Mix resolved it directly from the implementation checkout; the application was not copied into the host.

## Page and CSS evidence

The host page imports and calls:

```elixir
LiveFrames.Components.Sections.Hero.hero/1
LiveFrames.Components.Sections.MediaCallToAction.media_call_to_action/1
```

It renders one synthetic Hero and two synthetic CTAs. The consumer test checks each heading and action destination, CTA A and CTA B's different body text, their independent additive classes, and the root counts:

```text
HERO_INSTANCE_COUNT=1
CTA_INSTANCE_COUNT=2
CTA_A_CONTENT_INDEPENDENT=YES
CTA_B_CONTENT_INDEPENDENT=YES
HERO_CONSUMER=PASS
CTA_A_CONSUMER=PASS
CTA_B_CONSUMER=PASS
```

The host owns the URL prefix and serves the LiveFrames package asset through `Plug.Static`:

```elixir
plug Plug.Static,
  at: "/assets/liveframes",
  from: :live_frames,
  gzip: false,
  only: ~w(live_frames)
```

The tested URL and package asset evidence are:

```text
CSS_DELIVERY=PLUG_STATIC_FROM_LIVE_FRAMES_APPLICATION
CSS_URL=/assets/liveframes/live_frames/css/live_frames.css
PRECOMPILED_CSS_HTTP=200
CSS_SELECTOR_HERO=.lf-hero
CSS_SELECTOR_CTA=.lf-section-media-call-to-action
CSS_SELECTOR_CHECKS=PASS
PACKAGE_CSS_SHA256=cf50491747fd67abbc76625f2532debf1f64b62c50ff2870fafb97960b7043f4
COPIED_LIVEFRAMES_FILES=NONE
```

The status and selector assertions run through the consumer endpoint using `Phoenix.ConnTest`. The consumer's `priv/static` contains only its generated host assets; `priv/static/live_frames` does not exist.

## Commands and results

All commands ran from the disposable consumer root with its isolated Mix and Hex homes.

| Command | Result |
| --- | --- |
| `mix deps.get` | PASS. The generated dependency requirements resolved without manual edits. |
| `mix compile --warnings-as-errors` | PASS. Exit 0. |
| `mix test test/consumer_app_web/controllers/page_controller_test.exs` | PASS after implementation: 2 tests, 0 failures. |
| `mix test` | PASS: 6 tests, 0 failures. |

The focused test ran before the page and dependency-backed static plug were added. Its two expected failures were the missing caller-owned Hero heading and the CSS URL returning 404. With the consumer page and `Plug.Static from: :live_frames` configured, both focused tests passed.

## Consumer boundary checks

```text
LIVE_FRAMES_PREVIEW_DEPENDENCY=ABSENT
PHOENIX_STORYBOOK_DEPENDENCY=ABSENT
HOST_TAILWIND_BUILD_REQUIRED=NO
POSTGRES_REQUIRED=NO
PRIVATE_SOURCE_LEAK=NO
SOURCE_RUNTIME_REQUIRED=NO
```

The host dependency list contains neither `live_frames_preview` nor `phoenix_storybook`. No `ecto` or `postgrex` dependency or database repository is present. Phoenix was generated with `--no-tailwind`; the host has no Tailwind build configuration or build command. Tailwind 0.5.1 appears in the resolved lock graph through LiveFrames' `runtime: false` dependency, and is not used to build host assets.

No LiveFrames file was copied into host `priv/static`. A scan of the host working files found none of `private_reference`, `bricks-component-`, `ComponentizationPlan`, `DesignDocument`, or `ACSS`. The consumer contains no private-reference data, Bricks exports, ACSS data, WordPress runtime, or source-system runtime.

No browser verification was run here; that evidence is recorded separately in the Page A v0 browser proof.

## LiveFrames repository state

The implementation worktree was clean at starting HEAD `86f04bb51b9e4dcfd5e0cc1dd14c076de8a67a20` before the consumer run and remained clean afterward. The `apps/live_frames` subtree was unchanged. The consumer application and its build output remain under `/tmp`.
