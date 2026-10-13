# C09D7-C1 external Phoenix consumer proof

## Authority and scope

- C1 authority: `docs/development/c09d7c_external_consumer_catalogue_handoff_authority.md`
- Authority merge: `51d958e05627e7291b57d75f857cdf4332e37814`
- Owner authorization: C09D7-C1 only
- Base post-merge CI: run `38435558502`, result `PASS`
- Proof run: `C09D7-C1-ATTEMPT-3`
- PR #98 remained closed at reviewed head `f889b3231c673625c604b2fab712f7d353a5944f`. Other open PRs changed unrelated documentation only.
- Attempts 1 and 2 remain preserved terminal evidence. Attempt 1 stopped at dependency resolution with `phx_new` 1.8.7. Attempt 2 stopped when its isolated generator download timed out.
- This proof covers the CTA consumer path only. It does not test Catalogue reflection.

## Frozen source

```text
SOURCE_ROOT=/home/jcschoeman96/projects/current/LiveFrame/.worktrees/c09d7c-c1-source
SOURCE_ROOT_REALPATH=/home/jcschoeman96/projects/current/LiveFrame/.worktrees/c09d7c-c1-source
SOURCE_HEAD=51d958e05627e7291b57d75f857cdf4332e37814
SOURCE_TREE=20c5f0851d7c7c615c3ec46a444a68077361dd01
SOURCE_STATUS_BEFORE=CLEAN
SOURCE_STATUS_AFTER=CLEAN
SOURCE_DETACHED=YES
```

SHA-256 values before and after the runtime checks:

| Source file | Before and after SHA-256 |
| --- | --- |
| `apps/live_frames/lib/live_frames/components/sections/media_call_to_action.ex` | `795a32ca11c2e2bd456f79b81adaa801fa9d9dc72e1def5d1fba0718fe8bb8a5` |
| `apps/live_frames/priv/static/live_frames/css/live_frames.css` | `cf50491747fd67abbc76625f2532debf1f64b62c50ff2870fafb97960b7043f4` |
| `apps/live_frames/mix.exs` | `b7b3f1e96d5350aba6a5b58aa7682582cb47b2f9079180c8081c972441d9a986` |

`SOURCE_MUTATION=NO`.

## Toolchain and generator

```text
ELIXIR_VERSION=1.19.3
OTP_VERSION=28.1.1
MIX_VERSION=1.19.3
GLOBAL_PHX_NEW_VERSION=1.8.7
ATTEMPT_PHX_NEW_VERSION=1.8.15
HEX_VERSION=2.5.2
GLOBAL_PHX_NEW_MODIFIED=NO
```

Attempt 3 used isolated tooling:

```text
TOOL_ROOT=/tmp/liveframes-c09d7c-c1-tools-attempt3.BCthjs
MIX_ARCHIVES=/tmp/liveframes-c09d7c-c1-tools-attempt3.BCthjs/archives
HEX_HOME=/tmp/liveframes-c09d7c-c1-tools-attempt3.BCthjs/hex
HEX_HTTP_TIMEOUT=120
GLOBAL_ARCHIVE_STATE_BEFORE=c1c0544300d5b49feb117d0ee5a48fd04bbce3bd8caaef42cfc892478f9f7914
GLOBAL_ARCHIVE_STATE_AFTER=c1c0544300d5b49feb117d0ee5a48fd04bbce3bd8caaef42cfc892478f9f7914
GLOBAL_ARCHIVES_MUTATED_BY_ATTEMPT_3=NO
HEX_INSTALLED_UNDER_MIX_ARCHIVES=YES
HEX_AVAILABLE_IN_ISOLATED_ENV=YES
GLOBAL_PHX_NEW_VISIBLE_INSIDE_ISOLATED_ENV=NO
PHX_NEW_ARCHIVE_ISOLATED=YES
```

The isolated install commands were `mix local.hex --force` and `mix archive.install hex phx_new 1.8.15 --force`. The global `phx_new` archive was not visible from the isolated archive directory before installation.

The exact generator command was:

```bash
mix phx.new "$HOST_ROOT" \
  --no-install \
  --no-ecto \
  --no-mailer \
  --no-dashboard \
  --no-gettext \
  --no-tailwind \
  --no-version-check
```

The generated host had no Ecto/Postgres dependency, Repo module or Repo configuration. It had no Tailwind dependency, Tailwind configuration, or Tailwind build alias. Generation created no `deps`, `_build`, or `mix.lock`, and installed no dependencies. Phoenix 1.8.15 emits `priv/static/assets/default.css` as a default fallback even with `--no-tailwind`; the generated file identifies its CSS as Tailwind CSS 4.0.9. The host did not add or run a Tailwind build. The resolved dependency tree includes LiveFrames' own `tailwind ~> 0.5.1` dependency marked `runtime: false`; Mix compiled that dependency, but no Tailwind task or host asset build ran.

```text
PHX_NEW_PROFILE_MATCH=YES
ECTO_GENERATED=NO
ECTO_PRESENT=NO
TAILWIND_GENERATED=NO (no host Tailwind integration; Phoenix default CSS fallback noted above)
TAILWIND_PRESENT=NO (no host dependency, config, or build alias; LiveFrames runtime:false dependency noted above)
DEPENDENCIES_INSTALLED_DURING_GENERATION=NO
GENERATOR_DEP_INSTALL=NO
GENERATED_PHOENIX_LIVE_VIEW_REQUIREMENT=~> 1.2.0
DEPENDENCY_CONSTRAINTS_MANUALLY_EDITED=NO
```

## External dependency resolution and compile

```text
HOST_ROOT=/tmp/liveframes-c09d7c-c1-attempt3.oVaceH/live_frames_consumer
HOST_OUTSIDE_LIVEFRAMES=YES
DEPENDENCY_MODE=LOCAL_PATH_TO_EXACT_LIVE_FRAMES_APP
LIVE_FRAMES_RESOLVED_PATH=/home/jcschoeman96/projects/current/LiveFrame/.worktrees/c09d7c-c1-source/apps/live_frames
LIVE_FRAMES_RESOLVED_COMMIT=51d958e05627e7291b57d75f857cdf4332e37814
HOST_PHOENIX_LIVE_VIEW_REQUIREMENT=~> 1.2.0
LIVEFRAMES_PHOENIX_LIVE_VIEW_REQUIREMENT=~> 1.2.11
MIX_DEPS_GET=PASS
DEPENDENCY_TREE_RECORDED=YES
PHOENIX_VERSION=1.8.15
PHOENIX_LIVE_VIEW_VERSION=1.2.12
LIVE_FRAMES_PREVIEW_DEPENDENCY=ABSENT
PHOENIX_STORYBOOK_DEPENDENCY=ABSENT
COMPILE_WARNINGS_AS_ERRORS=PASS
```

The path dependency was the only LiveFrames declaration added to the disposable host. The host did not change its Phoenix, LiveView, or `phoenix_html` constraints. The resolved versions establish this run only, not a broader compatibility range.

## Runtime checks

The host test application and endpoint handled both requests through `Phoenix.ConnTest`. `mix test` completed with 6 tests and 0 failures.

The consumer page called `LiveFrames.Components.Sections.MediaCallToAction.media_call_to_action/1` and rendered test-owned heading, three test-owned image source/alt pairs, caller-owned link markup, the fixed root class, and the additive `c09d7c-c1-consumer` class.

The host served the package-owned precompiled stylesheet through its own `Plug.Static` at:

```text
/assets/liveframes/live_frames/css/live_frames.css
```

The CSS request returned HTTP 200. The served response contained:

```text
.lf-section-media-call-to-action__n-000001
.lf-section-media-call-to-action__n-000001-000001
.lf-section-media-call-to-action__n-000001-000001-000002-000004 > :where(a, button)
```

Nested generated selector names are evidence of artifact delivery, not a stable consumer API.

```text
TEST_ENDPOINT_BOOT=PASS
CTA_COMPONENT_INVOCATION=PASS
CTA_HEADING_RENDER=PASS
CTA_IMAGE_PAIRS_RENDER=PASS
CTA_PRIMARY_ACTION_RENDER=PASS
CTA_ROOT_CLASS_RENDER=PASS
CTA_ADDITIVE_CLASS_RENDER=PASS
PRECOMPILED_CSS_HTTP=200
CTA_ROOT_SELECTOR_PRESENT=YES
CTA_COMPONENT_SELECTOR_FAMILY_PRESENT=YES
CTA_ACTION_SELECTOR_FAMILY_PRESENT=YES
TAILWIND_HOST_BUILD_REQUIREMENT=NO
POSTGRES_C1=N/A
```

A scan of the disposable host, excluding dependency and build directories, found no private-reference, ACSS, Bricks, fixture, builder-ID, or source-class material.

```text
PRIVATE_REFERENCE_LEAK=NO
SOURCE_MUTATION=NO
```

## Outcome and limits

```text
C1_OUTCOME=PASS
C1_STATE=PASSED
PRIMARY_CSS_PROOF=PRECOMPILED
CATALOGUE_REFLECTION_COMPATIBILITY_PROVEN=NO
HEX_PUBLICATION_PROVEN=NO
PACKAGE_BOUNDARY_PROVEN=NO
DISTRIBUTION_LIBRARY_SUPPORTED=NO
CATALOGUE_ADMISSION_EXECUTED=NO
CATALOGUE_RELEASED=NO
P10_EXECUTED=NO
```

This run proves that one Phoenix 1.8.15 / Phoenix LiveView 1.2.12 application consumed the exact accepted LiveFrames source dependency, rendered the native CTA, and served its precompiled CSS. It does not prove Hex publication, package-boundary behavior, Catalogue admission or release, Catalogue reflection compatibility, or P10.

Runtime scaling classification:

```text
DATA_LAYER=BUILD_TEST_ONLY
POSTGRES=N/A
REDIS=N/A
ETS=N/A
CACHEX=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
PGBouncer=N/A
READ_REPLICA=N/A
RUNTIME_DB_CALLS=0
RUNTIME_EXTERNAL_SERVICE_REQUIREMENTS=0
RUNTIME_POLLING=0
```
