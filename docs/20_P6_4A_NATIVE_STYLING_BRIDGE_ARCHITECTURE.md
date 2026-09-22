# P6.4A — Native styling bridge architecture

**Plan ID:** `p6-4a-styling-bridge-architecture`  
**Plan version:** `v1`  
**Status:** `architecture_proposed` (design authority; implementation not authorized)  
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
```

`styling_verified` is **not** claimed by P6.4A.

### P6.4 workstream lifecycle

```text
unplanned
→ architecture_proposed   ← P6.4A (this document)
→ styling_verified        ← P6.4B+ (not authorized yet)
```

### Master-aligned phase gates (after P6.4A)

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

## 5. Canonical source paths (library-owned)

All paths are under the `:live_frames` application.

| Role | Path |
| --- | --- |
| Package CSS entry (Tailwind v4 input) | `apps/live_frames/assets/css/live_frames.css` |
| Token / theme bridge (`@theme`, `--lf-*`) | `apps/live_frames/assets/css/theme/lf_theme.css` |
| Hero semantic stylesheet | `apps/live_frames/assets/css/components/sections/hero.css` |
| Token map authority (deterministic bridge input) | `apps/live_frames/priv/token_maps/native_hero_v1.json` |

`native_hero_v1.json` records **source-independent** LiveFrames token names and
their mapping to CSS custom properties. It is derived from approved TokenSet
semantics, not copied ACSS variable names. P6.4B may add a Mix task to
regenerate bridge fragments from TokenSet JSON; P6.4A does not require that
task to exist yet.

HEEx in `hero.ex` keeps **semantic classes** (`lf-hero`, `lf-hero__heading`,
etc.). It does **not** carry large utility strings to prove Tailwind usage.

## 6. Source vs compiled artifact

| Question | Decision |
| --- | --- |
| Canonical **source** | `apps/live_frames/assets/css/**` (above) |
| Canonical **compiled** artifact | `apps/live_frames/priv/static/live_frames/css/live_frames.css` |
| Committed compiled CSS? | **Yes** — committed after library build in CI/release so consumers can use LiveFrames without running Tailwind locally. Source remains the change authority. |
| Who compiles? | **`:live_frames` build** via official Tailwind v4 (`mix live_frames.assets.build` — **defined in P6.4B**, not P6.4A). |
| What preview consumes? | The **same compiled artifact** (or the same compile inputs through the library alias) on verification routes only. Preview Tailwind config (`storybook.css`) remains for Storybook chrome / proof components, **not** for native Hero ownership. |

Two sources of truth are forbidden: Hero native CSS is **not** authored primarily
in `apps/live_frames_preview/assets/css/`.

## 7. Consumer CSS acquisition (distribution model)

P6.4A fixes the **stable public artifact** and import contract. Preview is not
the distribution channel.

### Primary consumer path (runtime / no local Tailwind)

1. Add `{:live_frames, ...}` to the host application.
2. Import precompiled package CSS using the documented public path:

```text
priv/static/live_frames/css/live_frames.css
```

3. Expose via host `Endpoint` / `Plug.Static` from the `:live_frames`
   application (exact Plug configuration is host documentation in P6.5).

### Optional integrator path (host already runs Tailwind v4)

1. Depend on `:live_frames`.
2. `@import` the package **source entry** from
   `apps/live_frames/assets/css/live_frames.css` (path as published in hex
   package or git dep) into the host stylesheet.
3. Host Tailwind compile must include LiveFrames `@source` paths documented in
   P6.5. Host owns merge conflicts and build time.

### Future generator / ejection (relationship only)

The generator **must** emit:

- the same `live_frames.css` entry or prebuilt `priv/static/live_frames/css/live_frames.css`;
- documented `@import` or static copy into `assets/css/vendor/live_frames.css`;
- no requirement that consumers wrap every component in `.live-frames`.

Generator implementation is **future**; the **source contract above is stable**
for ejection.

## 8. Tailwind v4 compiler ownership

| Context | Owner | Compiler |
| --- | --- | --- |
| Native package CSS | `:live_frames` | Official Tailwind v4 (pinned with umbrella; today preview pins `4.1.12` in `config/config.exs`) |
| Preview Storybook chrome | `:live_frames_preview` | Official Tailwind v4 (`tailwind storybook`) |
| Future generator preview | Generator tool / host app | Official Tailwind v4 for **release** artifacts |
| Future candidate fast paths | Editor / generator (optional) | Alternate compiler only behind parity gate (§19) |

**Compatibility authority for P6.4 Hero:** official Tailwind v4 only.

## 9. TokenSet → CSS variable bridge

```text
TokenSet (approved semantics)
    ↓ deterministic map (native_hero_v1.json)
--lf-* CSS custom properties + @theme entries
    ↓ referenced by
component CSS + selective utilities
```

Rules:

- **Source-independent names** — public theme surface uses `--lf-*` and
  `@theme` keys under LiveFrames namespace, not ACSS or Bricks identifiers.
- **Deterministic mapping** — same TokenSet input + map version ⇒ same
  `lf_theme.css` fragment.
- **Global vs component** — colors, typography scales, spacing, radii, and
  action tokens used across components live in `lf_theme.css`. Hero-only
  overlay and focal composition live as **component-private** custom
  properties on `.lf-hero` (§12–14).
- **No ACSS runtime** — Automatic.css is not a dependency of `:live_frames`.
- **No unnecessary generator framework** — a single versioned JSON map plus an
  optional regen task in P6.4B suffices; no open-ended plugin system in P6.4.

## 10. `@theme` boundary

- `@theme` lives in `lf_theme.css` and defines LiveFrames semantic design
  tokens exposed to Tailwind v4.
- Component files use `theme(...)` / `var(--lf-...)` and semantic classes; they
  do **not** redefine global palette scales.
- Preview `storybook.css` `@theme` (if any) is **preview-only** and must not
  become the native Hero theme authority.

## 11. `@apply` policy

- **Default:** avoid `@apply` for layout-heavy or variant-heavy rules.
- **Allowed:** narrow use inside `@layer components` in `hero.css` when it
  reduces duplication of token-backed declarations **without** raising
  specificity above a single semantic class per element.
- **Forbidden:** `@apply` chains that reproduce fidelity high-specificity
  selectors or duplicate slotted consumer markup styling.

Ordinary CSS declarations remain preferred for pseudo-elements, overlays, and
slotted action states.

## 12. Class and custom-property namespaces

| Namespace | Use |
| --- | --- |
| `lf-` prefix | Public semantic component classes (`lf-hero__heading`) |
| `--lf-` | Global theme tokens bridged from TokenSet |
| `--lf-hero-` | Component-private variables (overlay, focal, local gaps) |
| `data-lf-theme` (optional) | Future host-level theme root; **not** required per component |

Consumers may pass `class` on the Hero root; internal classes are merged per
Phoenix conventions. Internal classes are not a supported extension API.

## 13. Cascade, layers, and overrides

- Component rules target **single semantic classes** with **low specificity**
  (no long chained selectors copied from fidelity CSS).
- Use `@layer components` in package CSS; avoid `!important` except where
  accessibility requires documented exceptions (none for Hero P6.4B).
- **Consumer `class`** on root may override presentation via utilities or
  custom rules; component-owned guarantees apply only to documented surfaces.
- **Theme overrides:** hosts may set `--lf-*` on a documented theme root;
  component-private `--lf-hero-*` may be overridden only for documented
  extension points (initially: none public).

### Preview wrapper `.live-frames`

The preview root layout uses `.live-frames` for Storybook sandbox and lab
chrome. **Consumers are not required** to wrap Hero in `.live-frames`. Native
package CSS must stand alone on a host page.

## 14. Hero display heading (semantic vs visual scale)

- **Semantics:** `heading_level` selects `<h1>`–`<h6>` only.
- **Visual scale:** `.lf-hero__heading` always uses the **Hero display**
  typography tokens (`--lf-typography-display-*`), independent of heading level.
- P6.4B introduces or formalizes `typography.display.hero` (or equivalent) in
  the native map — derived from Phase 5 fidelity authority for large heading
  scale, **not** tied to `typography.heading.scale.h1` as an HTML coupling.

## 15. Overlay strategy (component-private)

- No new **global** overlay token in P6.4 unless reuse is proven by a second
  tracer.
- Hero overlay is implemented with **component-private** `--lf-hero-overlay-*`
  variables and `::before` / `::after` / background layers in `hero.css` as
  needed.
- Prefer pseudo-elements over extra HEEx overlay nodes when layering suffices.

## 16. Image focal position (component-private)

- **No public API attr** for focal position (P6.1 boundary preserved).
- Responsive focal treatment uses **private** `--lf-hero-media-focal-*` and
  media queries in `hero.css`, mapped from Phase 5 visual evidence — not
  Bricks breakpoint attr names.

## 17. Responsive threshold policy

```text
public source breakpoint attrs = 0
```

Internal native thresholds are **evidence-backed**, not mechanical Bricks name
copy and not blind Tailwind defaults without mapping notes.

| Native internal name | Min-width (px) | Evidence basis |
| --- | --- | --- |
| `lf-sm` | 479 | Phase 5 `mobile_portrait` authority (`478`) — content stacks / full-width actions |
| `lf-md` | 992 | Phase 5 `tablet_portrait` authority (`991`) — layout / media composition shift |
| `lf-lg` | 1280 | Verification viewport used in Phase 5C browser matrix |

CSS uses `@media (min-width: …)` with these values. Names are **internal** to
package CSS; they are not attrs and are not Bricks identifiers.

## 18. Action hover and focus-visible

- Style **slotted** primary/secondary actions via descendant selectors on
  `.lf-hero__action--primary` / `--secondary` targeting interactive roots
  (`a`, `button`) without parsing slot content, rewriting semantics, or adding
  LiveView behavior.
- **Required in P6.4B:** visible `:hover` and `:focus-visible` consistent with
  token-backed action states in `native_hero_v1.json`.
- No new Button component required.

## 19. Alternate Tailwind compilers (research)

Architecture research evaluated
[BeaconCMS/tailwind_compiler](https://github.com/BeaconCMS/tailwind_compiler)
(candidate-in → CSS-out; Elixir NIF; WASM for browsers). **No dependency is
added.**

### Parity rule (durable)

```text
alternate Tailwind compiler feature support MUST NOT be treated as
official-Tailwind parity until the exact LiveFrames candidate subset has been
verified against the official Tailwind compiler.
```

Upstream may advertise broad variant/selector support; its own `DESIGN.md`
records coverage gaps. LiveFrames does not categorically deny feature support in
alternate compilers — it **requires subset verification** before any alternate
compiler can author or gate release CSS.

### Three responsibilities (future candidate pipelines)

```text
Design IR / editor state
        ↓
deterministic candidate generation
        ↓
candidate completeness validation
        ↓
compiler
```

Compiler output matching official Tailwind on a candidate list does **not**
prove all required styles were discovered. Completeness validation is a
separate step (e.g. manifest of required utilities + semantic CSS classes from
IR).

### Decision table

| Use case | Official Tailwind v4 | Candidate compiler (`tailwind_compiler`) | Current decision |
| --- | --- | --- | --- |
| Native package styling (Hero CSS artifact) | `@theme` + component CSS + library build | Possible for utility subsets | **Adopt now:** official v4 + ordinary CSS. **Reject** alternate as canonical for P6.4. |
| Preview static build (Storybook chrome) | Existing `tailwind storybook` | Optional dev speedup | **Adopt now:** official v4 for authority. **Evaluate later** optional dev-only fast path. |
| Generator / converter | Write files → host official compile | IR → candidates → compile | **Borrow architecture only.** **Evaluate later** with dual-compile parity on LiveFrames subset. |
| Server visual editor | CLI/process compile | In-memory NIF | **Evaluate later** (editor phase). |
| Browser visual editor | Impractical for tight loop | WASM compile | **Borrow architecture only.** **Evaluate later.** Not Phase 6. |

### Pipeline comparison (summary)

| | Candidate-driven | Filesystem + official compile |
| --- | --- | --- |
| Determinism | Good with sorted candidates + versioned theme | Strong; standard Phoenix path |
| Generator | Strong for synthetic trees | Strong for ejected repos |
| Editor | Strong | Weak |
| Compatibility risk | High without subset gate | Lowest |
| LiveFrames P6.4 Hero | Not canonical | **Chosen** |

### Runtime coupling

`LiveFrames.Components.Sections.Hero` must **never** invoke a compiler at
request time. Compilation stays in build, generator, or editor tooling.

## 20. P6.4B browser verification plan (before P6.6 Storybook)

P6.6 Storybook must **not** start until P6.4B styling verification passes per
this plan.

| Item | Specification |
| --- | --- |
| Verification host | `live_frames_preview` dev server (`mix phx.server` from umbrella) |
| Route (P6.4B) | `/liveframes/native/hero` — dedicated native Hero styling surface |
| Viewports | 1280×800, 992×800, 479×800, 375×667 |
| Hover | Primary and outline actions — hover background/border tokens visible |
| Keyboard focus | Tab to actions — `:focus-visible` ring/outline visible |
| Contrast | Heading, lede, actions against section background (manual + tooling note in P6.4B record) |
| Responsive actions | Full-width/stacked at narrow; side-by-side or aligned per evidence at `lf-md+` |
| Image / overlay / focal | With approved **synthetic** demo image only; overlay readability; focal shift at breakpoints — **no attachment 880** |
| Authority CSS | Compiled `priv/static/live_frames/css/live_frames.css` from library build |

Storybook (`/storybook`) remains P6.6.

## 21. Performance and runtime constraints

```text
runtime CSS generation = 0
DB calls = 0
network calls = 0
polling = 0
```

Static compile/build only; CDN/browser cache friendly.

## 22. Selector capability

Package CSS retains ordinary CSS:

`:hover`, `:focus-visible`, `:disabled` (where justified), `::before`,
`::after`, `:nth-child(...)` only when a future component proves it, media and
container queries as approved.

Hero does **not** invent `:nth-child()` behavior. When Tailwind utilities are
insufficient, **ordinary CSS** in `hero.css` is authoritative.

## 23. Asset policy

```text
attachment 880 = unavailable
```

Demo imagery for P6.4B must be independent/synthetic. No fidelity claim for
substitute media. Do not use `chore/placeholder-assets` / `6e73b2d…` without
separate owner authorization.

## 24. P6.4A completion record

```text
P6.4 workstream = architecture_proposed
P6.4 implementation = NOT AUTHORIZED
P6 lifecycle on main = ... → semantic_verified (unchanged)
styling_verified = NOT CLAIMED
canonical styling authority = live_frames library assets + priv static contract
preview role = verification host only
tailwind_compiler dependency = 0
official Tailwind v4 = compatibility authority for P6.4
```

## 25. P6.4B authorization prerequisites (checklist)

P6.4B may begin only after owner accepts P6.4A and clean `main` contains this
document. P6.4B scope includes: library Tailwind build alias, `hero.css`
implementation, token bridge file, verification LiveView route, and transition to
`styling_verified` — not Storybook.
