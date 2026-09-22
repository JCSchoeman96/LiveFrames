# P6.4A — Native styling bridge architecture

**Plan ID:** `p6-4a-styling-bridge-architecture`

**Plan version:** `v3`

**Status:** `architecture_approved` (active styling contract); **P6.4B1
implementation candidate complete** on PR #31 (`implemented candidate`);
P6.4B2 browser verification **not authorized**, **not started**

**Scope:** First native Hero styling bridge, package CSS contract, Tailwind v4
boundary, token bridge, P6.4B verification plan, and future generator/editor
compilation posture.

**Authority:** This document is the active contract for P6.4 styling architecture.
`docs/00_LIVEFRAMES_MASTER_SPEC.md` wins on Master phase numbering.
`docs/19_PHASE_6_NATIVE_COMPONENTIZATION.md` remains P6 API and lifecycle
authority. On conflict for styling delivery, this document wins until amended.

**Last updated:** 2026-09-22

**Base repository head:** `d13609e3f7b68479b65481897039cc9b3121dd89`

### Revision log

- `v1` — Initial P6.4A architecture proposal (docs only).
- `v2` — Owner architecture gate: P6.4 workstream lifecycle, evidence-backed
  breakpoints only, `@theme` alias model, repository vs package paths, Hex
  inclusion contract, library build-tool ownership, committed-artifact drift
  gates, token-map single authority, action direct-root selectors.
- `v3` — Owner architecture approval recorded (`architecture_approved`);
  explicit P6.4B visual accessibility verification checklist (§21); P6.4B
  implementation remains not authorized until merge, clean `main`, and separate
  owner implementation authorization.

## 1. Goal

Define one unambiguous styling authority so that:

- the **`live_frames` library** owns component styling **source** and the
  **public CSS contract**;
- **`live_frames_preview`** consumes that contract for build and browser
  verification only — it is **not** the consumer-distribution authority;
- P6.4B may implement Hero CSS without redesigning package boundaries;
- future generator/ejection and optional candidate compilation have stable
  handoff points.

P6.4A does **not** authorize P6.4B implementation, dependency changes, Hero
HEEx edits, or Storybook work.

## 2. Non-goals

- No `tailwind_compiler`, NIF, or WASM dependencies.
- No replacement of the official Tailwind v4 compiler as compatibility authority.
- No runtime CSS generation, DB, network, polling, GenServer, or Oban in the
  styling path.
- No attachment 880 resolution, placeholder-asset fidelity claims, or
  `chore/placeholder-assets` demo media without separate owner authorization.
- No P6.6 Storybook implementation (verification plan only; Storybook remains
  P6.6).

## 3. Lifecycle truth

### Main native Hero lifecycle (unchanged on `main`)

```text
authorized
→ api_proposed
→ api_approved
→ implemented
→ semantic_verified
→ styling_verified
→ documented
→ storybook_verified
→ accepted
```

On `main` today the Hero stops at `semantic_verified`. `styling_verified` is
**not** claimed. Workstream `architecture_approved` does not advance the main
Hero lifecycle.

P6.4 workstream `verified` is the evidence required for the main transition:

```text
semantic_verified → styling_verified
```

### P6.4 workstream lifecycle (subordinate)

```text
unplanned
→ architecture_proposed        ← P6.4A architecture proposal (recorded)
→ architecture_approved        ← independent review PASS + owner approval (current)
→ implemented                  ← P6.4B styling implementation (not started)
→ verified                     ← P6.4B browser/visual verification
```

Rules:

- **Current P6.4 workstream state** = `architecture_approved` (independent
  architecture review PASS; owner architecture approval granted on PR #30).
- `architecture_proposed → architecture_approved` is complete on this branch;
  merge to clean `main` remains the durable publication gate for the contract.
- **P6.4B implementation** is **not** authorized by architecture approval alone.
  P6.4B requires PR #30 merged, clean `main` verification, and **separate**
  owner implementation authorization.
- When authorized, P6.4B implementation: `architecture_approved → implemented`.
- P6.4B verification: `implemented → verified`.

Do **not** conflate workstream `verified` with main `styling_verified`; the
latter is recorded on the main Hero lifecycle after P6.4B evidence is accepted.

### Master-aligned phase gates

```text
P6.3 → semantic_verified
P6.4 → styling_verified
P6.5 → documented
P6.6 → storybook_verified
Phase 6 exit → accepted
```

Catalogue / generation exposure remains **after** P6.6 acceptance, not in place
of P6.6.

## 4. Styling authority

```text
library owns component styling source + public CSS contract
preview consumes + verifies (build/verification host only)
```

Reject:

```text
preview owns component CSS
```

Fidelity CSS under `apps/live_frames_preview/priv/static/assets/fidelity/` remains
Phase 5 reference material only. Native Hero styling does **not** extend fidelity
static assets as the canonical native contract.

## 5. Canonical paths (repository vs package-relative)

All paths belong to the `:live_frames` application. **Hex and Git consumers must
use package-relative paths**, not `apps/live_frames/...` repository paths.

### Source CSS

| Role | Repository path | Package-relative path |
| --- | --- | --- |
| Package CSS entry (Tailwind v4 input) | `apps/live_frames/assets/css/live_frames.css` | `assets/css/live_frames.css` |
| Token bridge output | `apps/live_frames/assets/css/theme/lf_theme.css` | `assets/css/theme/lf_theme.css` |
| Hero semantic stylesheet | `apps/live_frames/assets/css/components/sections/hero.css` | `assets/css/components/sections/hero.css` |

### Compiled CSS and token map

| Role | Repository path | Package-relative path |
| --- | --- | --- |
| Compiled package CSS | `apps/live_frames/priv/static/live_frames/css/live_frames.css` | `priv/static/live_frames/css/live_frames.css` |
| Token map (mapping metadata only) | `apps/live_frames/priv/token_maps/native_hero_v1.json` | `priv/token_maps/native_hero_v1.json` |

HEEx in `hero.ex` keeps **semantic classes** (`lf-hero`, `lf-hero__heading`,
etc.). It does **not** carry large utility strings to prove Tailwind usage.

## 6. Source vs compiled artifact

| Question | Decision |
| --- | --- |
| Canonical **source** | `assets/css/**` (see §5) |
| Canonical **compiled** artifact | `priv/static/live_frames/css/live_frames.css` |
| Committed compiled CSS? | **Yes** — developers commit source and generated artifact together after a deterministic local/CI-equivalent build. |
| Who compiles? | **`:live_frames` build** via official Tailwind v4 (`mix live_frames.assets.build` — **P6.4B**). |
| What preview consumes? | The **same compiled artifact** (or the same library build alias) on verification routes only. Preview Tailwind (`storybook.css`) is Storybook chrome only. |

### Committed-artifact workflow (no CI commits)

```text
developer / build task
→ deterministically generates compiled artifact
→ source + generated artifact committed together

CI
→ reruns deterministic build
→ verifies committed artifact has zero drift

release / Hex package
→ ships the already-verified committed artifact
```

CI must **not** be described as committing repository changes. P6.4B must add a
drift gate conceptually equivalent to:

```text
mix live_frames.assets.build
git diff --exit-code -- <compiled styling outputs>
```

(exact paths and Mix task name may match P6.4B implementation).

Two sources of truth are forbidden: Hero native CSS is **not** authored primarily
in `apps/live_frames_preview/assets/css/`.

## 7. Hex package inclusion contract (P6.4B)

The architecture documents public styling artifacts that **must** appear in the
published `:live_frames` Hex package. Today `apps/live_frames/mix.exs` has no
`package/0` file list; **P6.4B must** update package file declarations so
consumers receive every documented artifact.

Required package content:

```text
assets/css/**
priv/static/live_frames/css/live_frames.css
priv/token_maps/native_hero_v1.json
```

P6.4A does **not** modify `mix.exs`. The architecture must not promise source
CSS that the package omits.

## 8. Consumer CSS acquisition (distribution model)

P6.4A fixes the **stable public artifact** and import contract. Preview is not
the distribution channel.

### Primary consumer path (runtime / no local Tailwind)

1. Add `{:live_frames, ...}` to the host application.
2. Import precompiled package CSS:

```text
priv/static/live_frames/css/live_frames.css
```

(package-relative within the `:live_frames` dependency)

3. Expose via host `Endpoint` / `Plug.Static` from the `:live_frames`
   application (host integration documented in P6.5).

### Optional integrator path (host already runs Tailwind v4)

1. Depend on `:live_frames`.
2. `@import` the package **source entry**:

```text
assets/css/live_frames.css
```

3. Host Tailwind compile must register LiveFrames library sources per Tailwind
   v4 `@source` rules (P6.5). Host owns merge conflicts and build time.

### Future generator / ejection (relationship only)

The generator **must** emit the same entry or prebuilt
`priv/static/live_frames/css/live_frames.css`, documented `@import` or vendor
copy, and no required `.live-frames` wrapper.

## 9. Tailwind v4 compiler and build-tool ownership

| Context | Owner | Compiler |
| --- | --- | --- |
| Native package CSS | `:live_frames` | Official Tailwind v4 (version pinned with umbrella; preview currently pins `4.1.12` in `config/config.exs`) |
| Preview Storybook chrome | `:live_frames_preview` | Official Tailwind v4 (`tailwind storybook`) |
| Future generator preview | Generator tool / host app | Official Tailwind v4 for **release** artifacts |
| Future candidate fast paths | Editor / generator (optional) | Alternate compiler only behind parity gate (§22) |

**Compatibility authority for P6.4 Hero:** official Tailwind v4 only.

### Library build tooling (P6.4B)

Preserve:

```text
live_frames
does NOT depend on
live_frames_preview
```

The canonical library CSS build **must not** work only because the preview app
installed Tailwind.

P6.4B rule:

```text
:live_frames owns its build-time Tailwind tooling
official Tailwind Mix package as non-runtime build/dev dependency
runtime dependency on Tailwind = 0
```

Recommended: `{:tailwind, ..., runtime: false}` (or equivalent) on `:live_frames`
only. Exact Mix `only:` / environment options are P6.4B implementation detail.
The build must be **reproducible without** `live_frames_preview`.

P6.4A does **not** add the dependency.

## 10. TokenSet → public CSS variables (stable theme surface)

```text
approved TokenSet values (authority)
        +
native_hero_v1.json (mapping only: TokenSet path → LiveFrames name)
        ↓
focused deterministic bridge builder (P6.4B — required, not optional)
        ↓
lf_theme.css
        ↓
ordinary public CSS custom properties --lf-*
        ↓
semantic component CSS (+ selective Tailwind utilities)
```

### `native_hero_v1.json` role

- Contains **deterministic mapping metadata** only, for example:
  - approved TokenSet path → LiveFrames CSS variable name;
  - optional Tailwind theme alias name when a utility is required.
- **Must not** duplicate authoritative token **values**. Values come from the
  approved TokenSet input at build time.
- Same TokenSet + same mapping version ⇒ same `lf_theme.css` (deterministic).

P6.4B must implement **one bounded** bridge build/validation path. No generic
token framework. No universal token compiler.

### CI token drift gate (P6.4B)

```text
same TokenSet + same mapping version = same lf_theme.css
```

CI fails if regenerated `lf_theme.css` differs from committed output (analogous
to compiled CSS drift in §6).

### Public `--lf-*` variables

Examples (exact names are deterministic and source-independent):

```text
--lf-color-background-ultra-dark
--lf-color-text-on-dark
--lf-typography-display-size
--lf-space-content-gap
```

These are the **stable LiveFrames theme surface** for hosts and semantic CSS.
They do **not** automatically become Tailwind utilities merely by existing.

Rules:

- **Source-independent names** — no ACSS or Bricks identifiers in public names.
- **Global vs component** — shared tokens in `lf_theme.css`; Hero overlay and
  focal composition as `--lf-hero-*` on `.lf-hero` (§15–17).
- **No ACSS runtime** on `:live_frames`.

## 11. Tailwind `@theme` aliases (utility layer only)

Tailwind v4 utilities are driven by **recognized theme namespaces** (for
example `--color-*`, `--spacing-*`, `--radius-*`, `--breakpoint-*`). Arbitrary
`--lf-*` variables are ordinary CSS unless aliased.

When a token **needs** a Tailwind utility, map through a recognized namespace:

```css
:root {
  --lf-color-brand: ...;
}

@theme inline {
  --color-lf-brand: var(--lf-color-brand);
}
```

Then utilities such as `bg-lf-brand` / `text-lf-brand` may be used where
appropriate.

If a token is consumed **only** by semantic component CSS:

```text
no Tailwind @theme alias is required
```

Do **not** place arbitrary `--lf-*` inside `@theme` and assume Tailwind will
generate utilities.

Preview `storybook.css` `@theme` (if any) remains **preview-only**.

## 12. `@apply` policy

- **Default:** avoid `@apply` for layout-heavy or variant-heavy rules.
- **Allowed:** narrow use inside `@layer components` in `hero.css` when it
  reduces duplication without raising specificity above a single semantic class
  per element.
- **Forbidden:** high-specificity chains copied from fidelity CSS.

Ordinary CSS remains preferred for pseudo-elements, overlays, and slotted action
states.

## 13. Class and custom-property namespaces

| Namespace | Use |
| --- | --- |
| `lf-` prefix | Public semantic component classes |
| `--lf-` | Public theme variables (ordinary CSS custom properties) |
| `--lf-hero-` | Component-private variables |
| `data-lf-theme` (optional) | Future host theme root; not required per component |

## 14. Cascade, layers, and overrides

Low-specificity semantic classes; `@layer components`; consumer `class` on root;
hosts may override `--lf-*` on a documented theme root. **No required
`.live-frames` wrapper** for consumers.

## 15. Hero display heading (semantic vs visual scale)

- **Semantics:** `heading_level` → `<h1>`–`<h6>`.
- **Visual scale:** `.lf-hero__heading` uses Hero display tokens
  (`--lf-typography-display-*`) independent of heading level.

## 16. Overlay strategy (component-private)

Component-private `--lf-hero-overlay-*`; no global overlay token in P6.4;
pseudo-elements preferred over extra HEEx overlay nodes when sufficient.

## 17. Image focal position (component-private)

No public focal attr; private `--lf-hero-media-focal-*` in `hero.css` only.

## 18. Responsive threshold policy

```text
public source breakpoint attrs = 0
```

Distinguish:

```text
internal behavior breakpoint
≠ verification viewport
≠ public API breakpoint
```

### Evidence-backed behavior bands

Phase 5 max-width authorities map to native **min-width** transitions:

| Behavior band | Width | Basis |
| --- | --- | --- |
| Base / narrow | `<= 478px` | Below `mobile_portrait` authority (`478`) |
| Intermediate | `479px–991px` | From `479` until below `tablet_portrait` authority (`991`) |
| Desktop | `>= 992px` | From `992` upward |

Internal CSS uses `@media (min-width: 479px)` and `@media (min-width: 992px)`
only. **Do not** invent additional behavior breakpoints (for example **no**
`1280px` styling threshold). `1280×800` is a **verification viewport only**
(§21), not evidence of a third layout transition.

Unless later visual evidence proves another behavior transition, these two
min-width boundaries are the full native responsive threshold set for Hero P6.4.

## 19. Action hover and focus-visible

The slot contract requires **one interactive root** per named action slot.
Style **direct** action roots only — do not broadly target nested links/buttons
inside arbitrary consumer markup.

Preferred pattern (or equivalent low-specificity direct-root selectors):

```css
.lf-hero__action--primary > :where(a, button) { ... }
.lf-hero__action--secondary > :where(a, button) { ... }
```

Include `:hover` and `:focus-visible` in P6.4B. No slot parsing, no LiveView
behavior, no new Button component. Consumer owns semantics and behavior; Hero
owns presentation.

## 20. Alternate Tailwind compilers (research)

See prior evaluation of
[BeaconCMS/tailwind_compiler](https://github.com/BeaconCMS/tailwind_compiler).
**No dependency added.**

Parity rule:

```text
alternate Tailwind compiler feature support MUST NOT be treated as
official-Tailwind parity until the exact LiveFrames candidate subset has been
verified against the official Tailwind compiler.
```

Three responsibilities for future candidate pipelines:

```text
Design IR / editor state
        ↓
deterministic candidate generation
        ↓
candidate completeness validation
        ↓
compiler
```

### Decision table

| Use case | Official Tailwind v4 | Candidate compiler | Current decision |
| --- | --- | --- | --- |
| Native package styling | `@theme` aliases + component CSS + library build | Utility subsets | **Adopt now:** official v4. **Reject** alternate as canonical. |
| Preview Storybook chrome | `tailwind storybook` | Dev speedup | **Adopt now:** official v4. |
| Generator / converter | Files → official compile | IR → candidates | **Borrow / evaluate later** |
| Server visual editor | CLI compile | NIF | **Evaluate later** |
| Browser visual editor | — | WASM | **Borrow / evaluate later** |

Hero must never invoke a compiler at request time.

## 21. P6.4B browser verification plan (before P6.6 Storybook)

P6.4B visual accessibility verification plan = **explicit** (checklist below).
None of these checks pass until P6.4B implementation and browser evidence exist.
Do **not** claim contrast verified, focus styling verified, WCAG compliance, or
a full accessibility pass from P6.4A architecture approval alone.

| Item | Specification |
| --- | --- |
| Verification host | `live_frames_preview` (`mix phx.server`) |
| Route (P6.4B) | `/liveframes/native/hero` |
| **Verification viewports** | `375×667`, `478×800`, `479×800`, `991×800`, `992×800`, `1280×800` |
| Boundary intent | `478/479` = narrow transition; `991/992` = intermediate/desktop transition; `1280` = representative desktop check **only** (no CSS behavior invented at 1280) |
| Demo media | Synthetic/demo-owned image only; attachment 880 unavailable |
| Authority CSS | Package-relative `priv/static/live_frames/css/live_frames.css` from library build |

### P6.4B mandatory acceptance evidence (not yet performed)

**Contrast (styled presentation):**

- heading text contrast
- lede text contrast
- primary action text/background/border contrast
- secondary action text/background/border contrast

**Interaction visibility:**

- primary `:hover` visibly distinguishable
- secondary `:hover` visibly distinguishable
- primary `:focus-visible` clearly visible
- secondary `:focus-visible` clearly visible

**Keyboard:**

- Tab traversal reaches supplied native action roots
- focus order follows DOM/action order
- action slot wrappers do not become extra focus targets

**Responsive actions** (at viewports `375`, `478`, `479`, `991`, `992`, `1280`):

- narrow action stacking/full-width behavior verified
- intermediate behavior verified
- desktop behavior verified

**Media and overlay:**

- overlay preserves text readability
- image `object-fit` behavior verified
- image focal shift verified across `478/479` and `991/992` boundaries

Storybook remains P6.6.

## 22. Performance and runtime constraints

```text
runtime CSS generation = 0
DB calls = 0
network calls = 0
polling = 0
runtime Tailwind dependency = 0
```

## 23. Selector capability

Ordinary CSS for states and pseudo-elements; Hero does not invent `:nth-child()`.

## 24. Asset policy

```text
attachment 880 = unavailable
```

## 25. P6.4A completion record

```text
P6.4A architecture = approved
P6.4 workstream = implemented candidate (P6.4B1 PR #31)
P6.4B2 browser verification = not authorized; not started
main P6 lifecycle on main = ... → semantic_verified (unchanged)
styling_verified = NOT CLAIMED
P6.4 workstream verified = NOT CLAIMED
```

## 26. P6.4B authorization prerequisites

P6.4 architecture is **approved**. P6.4B1 implementation candidate is **complete**
on PR #31 (`architecture_approved → implemented candidate`). P6.4B2 browser
verification is **not** authorized and **not** started.

P6.4B2 may begin only after:

```text
P6.4B1 merged to clean main
+ owner authorization for browser/WCAG verification
```

Architecture approval alone is **not** P6.4B2 verification authorization.

P6.4B must deliver: `:live_frames` Tailwind build tooling (`runtime: false`),
`mix live_frames.assets.build`, Hex `package/0` file inclusion, bounded token
bridge builder + drift gates, `hero.css`, compiled CSS drift gate, verification
route, and workstream `implemented → verified` before main `styling_verified`.
