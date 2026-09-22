# CSS and Tailwind strategy

**Status:** Cross-cutting CSS/Tailwind strategy for native LiveFrames components.
P6.4 styling bridge is **verified** (`docs/20`, `docs/21`). Consumer integration
steps live in **`docs/16_PACKAGE_AND_GENERATOR_MODEL.md`**. Architecture rationale
and P6.4 history remain in **`docs/20_P6_4A_NATIVE_STYLING_BRIDGE_ARCHITECTURE.md`**.

This document defines styling ownership, public/private boundaries, and compiler
posture. It does not replace the package integration guide in `docs/16`.

## 1. Role in the documentation set

| Document | Role |
| --- | --- |
| `docs/11` (this file) | Cross-cutting CSS/Tailwind strategy and theme boundaries |
| `docs/16` | Phoenix consumer package integration, CSS loading, Hero usage |
| `docs/20` | P6.4 styling-bridge architecture and verification history |
| `docs/21` | P6.4B2 browser verification evidence |

## 2. Ownership model

The **`live_frames` library** owns:

- component semantic structure and presentation CSS;
- generated public theme custom properties (`--lf-*`);
- precompiled CSS shipped under `priv/static/live_frames/css/`;
- responsive behavior inside component CSS (no public breakpoint attrs).

The **consumer application** owns:

- host layout, routing, and surrounding document hierarchy;
- action destinations, events, and labels (via slots);
- supplied images and informative vs decorative `image_alt` decisions;
- how LiveFrames CSS is served (URL prefix, caching headers);
- deliberate theme overrides on the public `--lf-*` surface;
- any re-verification after overrides that change contrast, focus, or layout.

The **`live_frames_preview`** application consumes the library CSS for lab and
verification. It is **not** the consumer-distribution authority.

## 3. Ordinary CSS remains first-class

LiveFrames styling is **static CSS**, not runtime-generated styles. Pseudo-classes
(`:hover`, `:focus-visible`), pseudo-elements (`::after` overlays), and media
queries are first-class. Tailwind utilities are a **build-time** compatibility
layer where used; there is **no** Tailwind runtime in production (`Tailwind runtime = 0`).

## 4. Official Tailwind v4 as compatibility authority

The package builds with the **official Tailwind v4** toolchain (`tailwind` Mix
dependency, build-time only). Alternate CSS compilers are not canonical. Host
applications are **not** required to run Tailwind when they use **precompiled**
LiveFrames CSS (see `docs/16`).

## 5. Source entry (`assets/css/live_frames.css`)

Package source entry:

```text
apps/live_frames/assets/css/live_frames.css
```

Current composition:

```text
@layer theme, components
→ tailwindcss/theme.css (theme layer only)
→ theme/lf_theme.css (generated public --lf-*)
→ components/sections/hero.css (Hero semantic presentation)
```

**Preflight / global reset is not shipped.** Importing LiveFrames does **not**
reset the host application’s base styles. Consumers must not assume a global
normalize from this package.

## 6. Precompiled CSS (primary consumer path)

Canonical committed artifact:

```text
apps/live_frames/priv/static/live_frames/css/live_frames.css
```

This is the **preferred** runtime integration: host static serving, browser/CDN
cacheable, **host Tailwind not required**. Details: `docs/16`.

## 7. Public theme surface (`--lf-*`)

Generated public theme variables live in:

```text
apps/live_frames/assets/css/theme/lf_theme.css
```

That file is **generated** (`LiveFrames.Styling.TokenBridge`). Consumers must
**not** edit it. They may override **`--lf-*`** custom properties from their own
stylesheet or scoped container, loaded so overrides win through normal cascade.

Literal token values are authoritative only in generated output and the token
map; this document names groups and purpose, not duplicate numeric/color tables.

### Public variable groups (Hero-relevant)

| Group | Examples (names only) | Purpose |
| --- | --- | --- |
| Background / text on dark | `--lf-color-background-ultra-dark`, `--lf-color-heading-on-dark`, `--lf-color-text-on-dark` | Section and typography colors |
| Display typography | `--lf-typography-display-size`, `--lf-typography-display-weight`, `--lf-typography-display-line-height` | Hero heading visual scale (independent of HTML heading level) |
| Body typography | `--lf-typography-body-size`, `--lf-typography-body-line-height` | Lede and base section type |
| Container width | `--lf-layout-container-max-width` | Capped content width |
| Section / container / content spacing | `--lf-space-section-padding-block`, `--lf-space-gutter`, `--lf-space-container-gap`, `--lf-space-content-gap` | Padding and gaps |
| Primary action | `--lf-action-primary-*` | Filled primary slotted control |
| Secondary action | `--lf-action-secondary-*` | Outlined secondary slotted control |
| Focus | `--lf-action-primary-focus`, `--lf-action-secondary-focus` | Keyboard focus outlines on slotted roots |
| Border / radius | primary border and radius variables on actions | Action shape |

## 8. Private component presentation

These are **implementation hooks**, not a stable consumer API:

```text
--lf-hero-*
.lf-hero*
```

Hero overlay gradients, focal treatment, and layout-specific composition use
**component-private** `--lf-hero-*` variables on `.lf-hero`. Semantic
`.lf-hero*` classes style the verified structure. Consumers must **not** depend
on private variables or internal class names for long-term theming.

## 9. Consumer overrides and cascade

Layering model:

```text
LiveFrames package CSS (theme + components)
→ consumer CSS / theme overrides
```

Recommended practice:

- override public `--lf-*` from the host theme scope;
- load consumer overrides **after** LiveFrames CSS;
- use global host overrides or scoped container overrides as appropriate.

**Avoid:** `!important`, high-specificity wars, editing `lf_theme.css`, or
patching committed `live_frames.css`.

### Override safety and verified evidence

P6.4 browser evidence applies to the **default** LiveFrames theme and Hero
presentation. Changing colors, font sizes, spacing, focus colors, action fills,
root `class` / global attrs, or **`color-scheme`** on `.lf-hero` may invalidate
verified contrast, focus visibility, layout, and responsive behavior. The consumer
owns re-verification after such changes.

The Hero uses a **fixed dark presentation** and sets local `color-scheme` behavior
needed for verified on-dark text treatment. Do not remove or override that
casually; if overridden, the consumer owns contrast verification.

## 10. Responsive behavior (internal)

The Hero public API exposes **zero** breakpoint attrs. Responsive layout,
action stacking, overlay, and focal treatment are **internal CSS**.

Observed implementation behavior (not public inputs):

| Viewport | Behavior |
| --- | --- |
| Below 479px | Actions stack; slotted controls full width |
| From 479px | Actions row with wrap; auto width on controls |
| From 992px | Desktop media overlay gradient; adjusted image focal position |

Thresholds `479px` and `992px` are **implementation details**, not component
contract. `1280px` is not a Hero behavior breakpoint.

## 11. `@apply` posture

Prefer semantic CSS and token-backed custom properties. Use `@apply` narrowly
and only where it clearly improves maintainability; default is ordinary CSS and
variables in component stylesheets.

## 12. Optional Tailwind v4 source integration

Consumers already compiling Tailwind v4 may import package **source** CSS and
add `@source` for library HEEx (see `docs/16`). This path is **optional** when
precompiled CSS is sufficient.

## 13. Delivery and scaling

```text
precompiled static CSS
→ host Plug.Static (or CDN)
→ browser cache
```

No request-time CSS generation. Build-time Tailwind compilation only. Runtime
infrastructure (DB, Redis, ETS, Oban, PubSub) is **N/A** for this path.

## 14. Source-asset fidelity

Attachment 880 remains **unavailable**. Image asset fidelity is **unavailable**,
redistribution **unknown**, full visual fidelity **not claimed**. The native Hero
is a reusable semantic component; demo/substitute media must not be treated as
source fidelity.

## 15. Security notes (styling boundary)

Consumer `heading` and `lede` remain escaped HEEx. `image_src` is consumer-owned.
`rest` / global attrs are consumer responsibility. LiveFrames does not introduce
raw HTML content APIs for Hero text fields.
