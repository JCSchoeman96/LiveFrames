# Page A v0 Ash/Phoenix consumer proof

## Identity

```text
PAGE_ID=FRAMES_PAGE_A_V0
CONSUMER_TARGET=ASH_PHOENIX
LIVEFRAMES_SHA=25e6179657c0885c19a40674faf2c42f39466a97
LIVEFRAMES_TREE=6c9a844bcfddeb2777ba1153d0df83985f0427d2
LIVEFRAMES_PACKAGE_TREE=0d3def9e966d8c7a3ad97d30b4bf9328a55f23f2
BASE_CI=39425896439
BASE_CI_RESULT=SUCCESS
CONSUMER_ROOT=/tmp/liveframes-page-a-v0-ash-proof
DEPENDENCY_MODE=LOCAL_PATH_TO_EXACT_APPS_LIVE_FRAMES
```

The external host depends on the `apps/live_frames` directory in the isolated
proof worktree. The proof worktree was created from the exact current-main
identity above, and PR #276's accepted merge is an ancestor of that base.

## Host and Ash model

```text
ASH_VERSION=3.36.1
ASH_PHOENIX_VERSION=2.3.25
PHOENIX_VERSION=1.8.16
LIVEVIEW_VERSION=1.2.13
ELIXIR_VERSION=1.19.3
OTP_VERSION=28
MIX_VERSION=1.19.3

ASH_DOMAIN=PageAAshProof.Content
ASH_RESOURCE=PageAAshProof.Content.PageAContent
ASH_READ_ACTION=read
ASH_DATA_LAYER=Ash.DataLayer.Simple with per-read static proof data
ASH_QUERY_COUNT_PER_INITIAL_RENDER=1

PRESENTATION_BOUNDARY=HOST_OWNED
ASH_STRUCT_PASSED_TO_LIVEFRAMES=NO
LIVEFRAMES_ASH_DEPENDENCY=NO
```

`PageAContentContext.fetch_page_a!/0` makes one Ash read for the page request.
`PageAViewModel.from_resource/1` maps the record to plain nested maps, strings,
and image attributes before the controller calls LiveFrames. Tests recursively
check that the view model contains no structs. Hero and CTA headings, body
content, and destinations come from the Ash record; the host supplies synthetic
SVG images.

Ash is installed in the external host only. The host has no direct Ecto, SQL,
Postgres, or database adapter dependency and no Repo. Ash 3.36.1 resolves the
`ecto` core package transitively; it is not used as a persistence layer in this
proof. No `ecto_sql`, `ash_postgres`, or `postgrex` package is present in the
host dependency tree.

## Page and asset boundary

```text
HERO_RENDERED=YES
CTA_A_RENDERED=YES
CTA_B_RENDERED=YES
CTA_A_HREF=/enrol/apply
CTA_B_HREF=/programmes/flexible
CTA_ROOT_CLASSES=page-a-cta-a,page-a-cta-b

PRECOMPILED_CSS_HTTP=200
CSS_URL=/assets/liveframes/live_frames/css/live_frames.css
CSS_SELECTOR_CHECKS=.lf-hero:PASS;.lf-section-media-call-to-action:PASS
CSS_SHA256=cf50491747fd67abbc76625f2532debf1f64b62c50ff2870fafb97960b7043f4
COPIED_LIVEFRAMES_FILES=NONE
HOST_PRIV_STATIC_LIVE_FRAMES_DIRECTORY=ABSENT
ONE_LIVEFRAMES_STYLESHEET_PER_PAGE=YES
```

The host serves the package-owned CSS with `Plug.Static` from `:live_frames`.
The page has two linked stylesheets total: Phoenix's generated static
`/assets/default.css` reset and one LiveFrames stylesheet. The reset is needed
to avoid browser-default figure margins causing horizontal overflow at tablet
width; it is generated Phoenix static CSS, not a host Tailwind build. No
LiveFrames CSS or component file is copied into the host.

The rendered components use the existing public `Hero.hero/1` and
`MediaCallToAction.media_call_to_action/1` APIs. The two CTA roots have distinct
headings, body text, destinations, image values, and additive classes.

## Automated checks

The external host ran:

```text
mix deps.get                              PASS
mix compile --warnings-as-errors          PASS
mix test                                  PASS (12 tests, 0 failures)
mix deps.unlock --check-unused             PASS
```

Focused tests cover the exact Ash record, deterministic plain-map shaping, no
Ash structs in presentation data, one Ash read per initial render, one Hero,
two independent CTA roots, Ash-derived copy and links, CSS HTTP delivery and
selectors, no copied LiveFrames assets, no direct database/Tailwind/preview
dependencies, no source-material directories, no Ash dependency in the
LiveFrames package, and no Phoenix telemetry poller.

The LiveFrames repository quality gates ran from the isolated proof worktree:

```text
mix deps.get                              PASS
mix format --check-formatted              PASS
mix compile --warnings-as-errors          PASS
mix assets.build                          PASS
mix test                                  PASS (2,131 tests, 0 failures)
mix deps.unlock --check-unused             PASS
git diff --check                           PASS
```

The first repository test attempt timed out while the asset-drift test waited
for the Tailwind executable download. After `mix assets.build` populated the
tool cache, the full suite passed. `mix deps.get` also reported existing Hex
advisories for Bandit 1.12.5 and LazyHTML 0.1.12; no dependency changes were
made for this proof.

## Browser verification

The external Phoenix host was checked in the collaborative browser at desktop,
tablet, and mobile sizes. At each size the Ash-derived Hero and both CTA
headings were visible, the two CTA links had their expected distinct
destinations, and the two CTA sections did not overlap.

| Viewport | Result |
| --- | --- |
| Desktop, 1440 × 900 | No horizontal overflow; one Hero; two CTAs; no duplicate IDs |
| Tablet, 768 × 1024 | No horizontal overflow; one Hero; two CTAs; no duplicate IDs |
| Mobile, 390 × 844 | No horizontal overflow; one Hero; two CTAs; no duplicate IDs |

All seven synthetic images loaded. Each viewport had one LiveFrames stylesheet
and no visible composition collision. The page had no script elements or
LiveView socket, no console errors, and no duplicate IDs. At mobile size, the
browser's resource list remained unchanged during a three-second idle interval.

```text
BROWSER_RESULT=PASS
STRUCTURAL_FIDELITY=PASS
FUNCTIONAL_FIDELITY=PASS
VISUAL_FIDELITY=PARTIAL
```

Visual fidelity remains partial because this proof uses synthetic SVG images
and does not compare the rendering against a source reference screenshot.

## Performance and source boundary

```text
DATA_CLASS=PROOF_STATIC
HOT_CACHE=NOT_REQUIRED
DB_CALLS=0
POSTGRES=NOT_REQUIRED
REDIS=NOT_REQUIRED
CACHEX=NOT_REQUIRED
GENSERVER=NOT_REQUIRED
PUBSUB=NOT_REQUIRED_FOR_PAGE_DATA
OBAN=NOT_REQUIRED
POLLING=0
SOURCE_IR_RUNTIME_WALKS=0
LIVEFRAMES_ASH_QUERIES=0

PRIVATE_SOURCE_LEAK=NONE
SOURCE_RUNTIME_REQUIRED=NO
```

Phoenix's generated PubSub child remains part of the default host supervision
tree, but the Page A route and content path do not use PubSub. The generated
telemetry poller was removed from the disposable host. There is no database,
cache, page process, background job, or polling loop in the Page A data path.

## Consumer proof lifecycle

```text
DEFINED
-> ENVIRONMENT_READY
-> DEPENDENCY_RESOLVED
-> PAGE_RENDERED
-> ASSETS_VERIFIED
-> BROWSER_VERIFIED
-> PASSED
```
