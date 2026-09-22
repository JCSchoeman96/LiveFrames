# P6.4B2 — Native Hero browser verification

**Status:** `verified candidate` (independent browser review and owner approval still required)

**Base SHA:** `29706d0bba4edbea632a6eec4afef4f5fcd4a5d1`

**Tested source SHA:** `6b2baff0119edaa0b642aa3bf59781210abbd41a` — exact commit whose Hero runtime source and compiled library CSS were loaded in Chrome for final styling evidence. Later commits on this branch adjust evidence metadata only (manifest/report); runtime diffs from this SHA to current PR head are **zero**.

**PR review head** is obtained from Git/PR metadata, not stored inside `manifest.json`, because embedding the metadata commit’s own SHA in the same commit is self-referential.

**Route:** `/liveframes/native/hero` (preview server port `4010` in this run; default dev `PORT` is `4000`)

**Browser:** Google Chrome `153.0.8010.52` on Linux x86_64

**Evidence:** `docs/evidence/p6_4b2_native_hero/` (screenshots + `manifest.json`)

## Baseline observation (merged B1, no CSS edits)

Baseline pass ran against merged artifacts with SHA256:

| File | SHA256 |
| --- | --- |
| `hero.ex` | `e91d73fe8b8e4559b6403a92ec926191a491eae11238c9e98573ec1c49d00af8` |
| `hero.css` (pre-correction) | `9596be797fa74f6d236366a35173fdbfd323342a90dccc4cde17662671d2876c` |

Measured failures:

1. **Secondary `:hover` text/background contrast** at `375×667`: canvas-resolved ratio **1.441:1** (required **≥ 4.5:1**). Hover used `oklch(0.95 …)` text on `oklch(1 0 180)` background.
2. **Host `color-scheme: dark`** (document-only, no repo CSS change): heading and lede computed **`rgb(0, 0, 0)`** via `light-dark()` in `--lf-color-*-on-dark` tokens — unreadable on the Hero dark stack.

All other baseline matrix items (six viewports, `478→479` action transition, `991→992` overlay and focal transitions, `object-fit: cover`, no horizontal overflow, primary action contrasts, keyboard order for Hero actions, runtime cleanliness) **passed** without CSS changes.

## Correction (cycle 1)

Smallest Hero-local CSS changes in `apps/live_frames/assets/css/components/sections/hero.css`:

1. `color-scheme: light` on `.lf-hero` so fixed dark Hero presentation keeps `light-dark()` on-dark tokens on the light branch when the host declares dark color-scheme.
2. Secondary `:hover` text color `var(--lf-action-primary-text)` instead of `var(--lf-action-secondary-text-hover)`.

Regenerated library CSS via `mix live_frames.assets.build`. Structural regression: `hero_styling_contract_test.exs` asserts both rules.

**Correction cycle 2:** not required (including after independent composited re-measurement of secondary **normal** actions).

## Evidence integrity (post-review hardening)

Secondary **normal** actions use a transparent fill; text contrast must be measured against **composited** pixels beneath the label (image + overlay + Hero stack), not against `rgba(0,0,0,0)` nor hero fallback alone. Chrome re-measurement at all six viewports used temporary transparent text/border (browser-only, not committed), viewport PNG sampling, and `scrollIntoView` when the control was below the fold at `375×667`.

Manifest schema **`p6_4b2_v2`** replaces invalid `candidate_sha` with **`tested_source_sha`** (see above).

## Final verified evidence

Full six-viewport pass repeated after correction. Composited heading/lede contrast used temporary transparent text + viewport PNG sampling (not committed). Action/hover contrast used real `:hover` via browser automation and canvas-resolved colors.

### Responsive

| viewport | actions | object-position | overlay | horizontal overflow |
| --- | --- | --- | --- | --- |
| 375×667 | column; controls full width (~341px) | 50% 50% | vertical gradient (180deg) | none |
| 478×800 | column; full width (~431px) | 50% 50% | vertical | none |
| 479×800 | row/wrap; controls ~140px | 50% 50% | vertical | none |
| 991×800 | row/wrap; controls ~140px | 50% 50% | vertical | none |
| 992×800 | row/wrap; controls ~140px | 70% 50% | horizontal gradient (90deg) | none |
| 1280×800 | row/wrap; controls ~140px | 70% 50% | horizontal | none |

Boundary notes:

- **478→479:** column → row with full-width → content-sized controls (**PASS**).
- **991→992:** vertical → horizontal overlay; object-position **50% 50% → 70% 50%** (**PASS**).
- **478→479:** no overlay or focal transition (**PASS**).

`.lf-hero__content` `margin-top`: **400px** at all viewports.

### Contrast

| element/state | foreground / effective background | ratio | threshold | result |
| --- | --- | --- | --- | --- |
| heading (composited, all viewports) | white on sampled overlay stack | min **16.858–19.305** | ≥ 3.0 | PASS |
| lede (composited, all viewports) | white on sampled overlay stack | min **18.58–19.305** | ≥ 4.5 | PASS |
| primary normal | dark on primary fill | **14.497** | ≥ 4.5 | PASS |
| primary hover | dark on hover fill | **20.599** | ≥ 4.5 | PASS |
| secondary normal (composited text) | `rgb(255, 212, 78)` on sampled stack under label | per viewport **13.566–14.095**; minimum **13.566** at **375×667**, **478×800**, **479×800** | ≥ 4.5 | PASS |
| secondary normal (composited border) | accent border on sampled stack at border edge | per viewport **13.586–14.095**; minimum **13.586** at **375×667** (also **478×800**, **479×800**, **991×800**) | ≥ 3.0 | PASS |
| secondary hover | dark on hover fill | **20.599** | ≥ 4.5 | PASS |

Per-viewport secondary **normal** composited text minima:

| viewport | text / composited background | border / composited background |
| --- | --- | --- |
| 375×667 | **13.566:1** | **13.586:1** |
| 478×800 | **13.566:1** | **13.586:1** |
| 479×800 | **13.566:1** | **13.586:1** |
| 991×800 | **13.586:1** | **13.586:1** |
| 992×800 | **14.014:1** | **13.934:1** |
| 1280×800 | **14.095:1** | **14.095:1** |

### Keyboard / focus

| step | focused element | focus-visible | outline | result |
| --- | --- | --- | --- | --- |
| 1 | `button` “Get started” | yes | 2px solid accent | PASS |
| 2 | `a` “Learn more” | yes | 2px solid accent | PASS |

Preview `body` received focus after Hero actions (LiveView chrome); Hero-relative order **primary → secondary** (**PASS**). `.lf-hero__action` wrappers: **0** focus targets.

Focus indicator non-text contrast vs hero background: primary **11.002:1**, secondary **5.363:1** (target ≥ 3.0) — **PASS** (not a full WCAG 2.2 focus-appearance audit).

### Runtime

| console | network | result |
| --- | --- | --- |
| 0 Hero-relevant errors | hero route, library CSS, synthetic SVG **200** | CLEAN |

### Color-scheme (host dark)

| viewport | scheme | heading | lede | min composited contrast | result |
| --- | --- | --- | --- | --- | --- |
| 375×667 | host `dark` | `rgb(255,255,255)` | `rgb(255,255,255)` | heading **19.028**, lede **19.305** | PASS |
| 1280×800 | host `dark` | `rgb(255,255,255)` | `rgb(255,255,255)` | heading **17.928**, lede **19.305** | PASS |

### Accessibility structure

- Heading: **h2** with configured text.
- Decorative image: **`alt=""`**.
- Primary: **button**; secondary: **anchor**.
- Overlay pseudo-element not exposed as content.

## Lifecycle claims (candidate only)

```text
P6.4B1 implementation = merged
P6.4B2 browser verification = verified candidate
P6.4 workstream = verified candidate
Main Hero lifecycle = semantic_verified
styling_verified = NOT CLAIMED (independent + owner review pending)
P6.5+ = NOT AUTHORIZED
```

**Do not merge** on browser evidence alone; owner review performs durable `verified` / `styling_verified` transitions.
