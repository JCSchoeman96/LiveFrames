# P6.6 — Native Hero PhoenixStorybook verification

**Status:** `storybook_verified` / **owner accepted** (independent browser review PASS; owner P6.6 gate APPROVED)

**Authorized base SHA:** `35e35a53114088da5e5d6185c69323f87ada22a7`

**Tested source SHA:** `ad1c6164afbdc3ee42b47ff7b814a89d5c647935` — commit whose Storybook story, structural tests, and Storybook CSS import were frozen before browser evidence. Evidence commits after this SHA adjust documentation and manifest only unless a correction cycle is recorded.

**Story module:** `LiveFramesPreviewWeb.Storybook.Components.Hero` (`apps/live_frames_preview/storybook/components/hero.story.exs`)

**Production function:** `LiveFrames.Components.Sections.Hero.hero/1` (unchanged in P6.6)

**Storybook route:** `/storybook/components/hero`

**Browser:** Chromium HeadlessChrome `152.0.0.0` on Linux x86_64 (local preview on port `4521`)

**Evidence:** `docs/evidence/p6_6_native_hero_storybook/` (`manifest.json` + screenshots)

## Governance

```text
P6.4 = verified
P6.5 = documented / owner accepted
P6.6 = storybook_verified / owner accepted
```

P6.6 established Hero lifecycle **`storybook_verified`** only. Terminal
**`accepted`** and Phase 6 **CLOSED / accepted** are separate Phase 6 exit
decisions (`docs/19` §31).

**Current lifecycle handoff:**

```text
Phase 6 exit = owner-approved / CLOSED
Current Hero lifecycle = accepted
```

Catalogue / generator / ejection = **not authorized**.

**Independent browser review:** PASS

**Reviewed candidate head:** `bab0d7e6024c452d20abb8e2137c7720a0bffc9b`

**Owner P6.6 gate:** APPROVED

## Storybook CSS consumption

`apps/live_frames_preview/assets/css/storybook.css` imports the compiled package artifact:

```text
apps/live_frames/priv/static/live_frames/css/live_frames.css
```

via a single `@import` (relative path from the Storybook Tailwind entry). No authored `.lf-hero*` rules were added to Storybook CSS; proof-badge styles are unchanged.

## Variations

| ID | Purpose |
| --- | --- |
| `default` | Full representative state: heading level 2, lede, synthetic image (`image_alt=""`), primary button + secondary anchor |
| `informative_media` | Same synthetic asset with non-empty informative `image_alt` |
| `no_media` | Valid Hero without media; `heading_level` 3 |
| `minimal` | Required heading only |

Synthetic media: `/assets/native/hero-demo.svg` (repository-owned). **Not** attachment 880; does not establish source-image fidelity.

## Browser evidence summary

Full visual-accessibility contrast tables remain in `docs/21_P6_4B2_NATIVE_HERO_BROWSER_VERIFICATION.md`. P6.6 confirms Storybook does not break the verified package presentation.

| Check | Result |
| --- | --- |
| 375×800 default layout | PASS — stacked actions, `object-position: 50% 50%`, `margin-top: 400px` on content, no horizontal overflow |
| 1280×900 default layout | PASS — row/wrap actions, `object-position: 70% 50%`, no horizontal overflow |
| Secondary `:hover` smoke | PASS (real pointer hover) |
| Keyboard focus (primary → secondary) | PASS — visible focus on both controls |
| `informative_media` semantics | PASS — `img` + non-empty alt |
| `no_media` semantics | PASS — no `.lf-hero__media` / `img`, `h3` heading |
| `minimal` semantics | PASS — heading only |
| Runtime console (Hero-related) | 0 errors |
| Network | `/storybook/components/hero`, `/assets/css/storybook.css`, `/assets/native/hero-demo.svg` → 200 |

## Structural verification

ExUnit: `apps/live_frames_preview/test/live_frames_preview_web/native_hero_storybook_test.exs` plus updated Phase 1 proof-story presence test in `phase_1_test.exs`.

## Correction policy

Correction cycles used: **0**. Production Hero and library CSS were not modified.
