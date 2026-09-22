# Package and generator model

**Status:** Consumer and package integration guide for the **`live_frames`**
library. Assumes **`:live_frames` is already present** as a Mix dependency in the
host umbrella or application. Hex publication, version pinning, and release
automation are **out of scope** for this document unless repository truth proves
otherwise.

Cross-cutting CSS strategy: **`docs/11_CSS_AND_TAILWIND_STRATEGY.md`**. P6.4
architecture history: **`docs/20_P6_4A_NATIVE_STYLING_BRIDGE_ARCHITECTURE.md`**.

Generator/ejection is described here as a **future relationship** only; there is
no generator implementation in the current package.

## 1. Package layout (consumer-relevant paths)

| Path | Role |
| --- | --- |
| `lib/live_frames/components/sections/hero.ex` | Native Hero function component |
| `assets/css/live_frames.css` | Optional Tailwind v4 **source** entry |
| `assets/css/theme/lf_theme.css` | Generated public `--lf-*` theme (read-only) |
| `assets/css/components/sections/hero.css` | Hero semantic presentation CSS |
| `priv/static/live_frames/css/live_frames.css` | **Precompiled** CSS (primary runtime path) |
| `priv/token_maps/` | Token bridge inputs (build/generation; not a runtime API) |

Hex `package/0` files list includes `lib`, `assets/css`, `priv/static/live_frames`,
and `priv/token_maps` (see `apps/live_frames/mix.exs`).

## 2. Component import and use

Module and function:

```text
LiveFrames.Components.Sections.Hero
hero/1
```

Make `hero/1` available with ordinary Elixir `import`, `alias`, or fully
qualified calls. Example assumes the host already imports Phoenix.Component and
its own `CoreComponents` link helper where used.

```elixir
alias LiveFrames.Components.Sections.Hero

~H"""
<Hero.hero
  heading="Welcome"
  heading_level={2}
  lede="Short supporting paragraph."
  image_src={~p"/images/hero.jpg"}
  image_alt="Description of the hero image."
>
  <:primary_action>
    <button type="button">Get started</button>
  </:primary_action>
  <:secondary_action>
    <.link navigate={~p"/learn-more"}>Learn more</.link>
  </:secondary_action>
</Hero.hero>
"""
```

LiveFrames does **not** own navigation, `phx-click`, analytics, or business
events. Those belong in consumer-supplied slot markup.

## 3. Public API contract (`hero/1`)

Complete public attrs:

| Attr | Type | Default | Constraints |
| --- | --- | --- | --- |
| `heading` | string | — | **Required.** Plain text; HEEx-escaped. |
| `heading_level` | integer | `2` | Must be `1..6`. |
| `lede` | string | `nil` | Optional; omitted when `nil`. |
| `image_src` | string | `nil` | Optional; omit for no media. |
| `image_alt` | string | `nil` | Required **binary** when `image_src` is set; see image rules. |
| `id` | string | `nil` | Optional section `id`. |
| `class` | string | `nil` | Additive on root; merged with `lf-hero`. |
| `rest` | global | empty | `aria-*`, `data-*`, etc. on section root; not duplicate `id`/`class`. |

**Not implemented** (do not use): `variant`, `theme`, `overlay`, `focal_position`,
`content_offset`, `breakpoint`, or source breakpoint names.

### Slots

| Slot | Cardinality | Notes |
| --- | --- | --- |
| `primary_action` | 0 or 1 entry | One interactive root (e.g. `<button>`, `<.link>`). |
| `secondary_action` | 0 or 1 entry | One interactive root (e.g. `<.link>`, `<a>`). |

Each slot represents **one** interactive root. LiveFrames validates slot **entry**
count, not arbitrary nested descendants inside consumer markup.

Runtime validation (raises `ArgumentError`):

- invalid `heading_level`;
- `image_src` without `image_alt`;
- more than one entry per action slot.

Module-level detail: `@moduledoc` / `@doc` on
`LiveFrames.Components.Sections.Hero`.

## 4. Image accessibility

| Condition | Contract |
| --- | --- |
| No `image_src` | Valid Hero without media. |
| `image_src` + `image_alt == nil` | **Invalid** (raises). |
| `image_alt == ""` | Explicit **decorative** image (`alt=""`). |
| Non-empty `image_alt` | **Informative** image. |

Consumer decides informative vs decorative. LiveFrames renders `<img alt={...}>`
from supplied values only.

## 5. Action ownership

**Hero owns:** presentation and layout of the action region; primary vs secondary
visual treatment on the **direct** slotted interactive root (`a` or `button`).

**Consumer owns:** `href`, `navigate`, `patch`, `phx-click`, disabled state,
business logic, analytics, and accessible action **labels** in slot content.

## 6. Precompiled CSS — primary integration path

**Preferred** for hosts that do not need to rebuild LiveFrames styling.

Canonical artifact (package-relative):

```text
priv/static/live_frames/css/live_frames.css
```

### Phoenix `Plug.Static`

LiveFrames owns the **package path**; the host owns the **URL prefix**.

Verified reference pattern (preview app only as a reference — not part of your
contract):

```elixir
plug Plug.Static,
  at: "/liveframes/library",
  from: :live_frames,
  gzip: false,
  only: ~w(live_frames)
```

Consumer equivalent (choose your own `at:` prefix):

```elixir
plug Plug.Static,
  at: "/assets/liveframes",
  from: :live_frames,
  gzip: false,
  only: ~w(live_frames)
```

Example stylesheet URL with that prefix:

```text
/assets/liveframes/live_frames/css/live_frames.css
```

Load in the host root layout (path must match your `Plug.Static` `at:` + file
path under `priv/static/`):

```heex
<link rel="stylesheet" href={~p"/assets/liveframes/live_frames/css/live_frames.css"} />
```

**Host Tailwind:** not required. **Runtime Tailwind:** 0.

## 7. Optional Tailwind v4 source path

For hosts **already** compiling Tailwind v4 and merging CSS at build time.

Source entry:

```text
deps/live_frames/assets/css/live_frames.css
```

Example host `assets/css/app.css` (paths relative to **that stylesheet**):

```css
@import "../../deps/live_frames/assets/css/live_frames.css";
@source "../../deps/live_frames/lib";
```

Adjust `../../deps/live_frames/...` if your app layout differs. `@source` paths
are relative to the importing stylesheet.

Do **not** use Tailwind v3 `content` configuration as the v4 integration model.
Do **not** treat JavaScript `tailwind.config` as the primary v4 path.

Importing source CSS pulls theme + Hero components but **not** Preflight; the
host base styles remain the host’s responsibility.

## 8. Theme overrides (public `--lf-*`)

Generated theme:

```text
assets/css/theme/lf_theme.css
```

**Read-only generated output.** Override **`--lf-*`** from consumer CSS instead.

Patterns:

1. **Global host override** — set variables on `:root` or a host theme scope after
   LiveFrames CSS.
2. **Scoped override** — set variables on a wrapper that contains LiveFrames
   sections.

Do not edit `lf_theme.css` or committed precompiled CSS.

### Public vs private variables

| Surface | Stable for consumers? |
| --- | --- |
| `--lf-*` from generated theme | **Yes** — public theme API |
| `--lf-hero-*` on `.lf-hero` | **No** — private composition |
| `.lf-hero*` classes | **No** — semantic implementation hooks |

See variable groups in `docs/11`. Canonical values: generated `lf_theme.css`.

### Override verification warning

P6.4 browser verification covers the **default** LiveFrames theme. Overrides to
colors, typography, spacing, focus, actions, root `class`, global attrs, or Hero
`color-scheme` may invalidate verified contrast, focus, and layout. **Consumer
re-verifies** customized presentation.

## 9. Responsive contract (consumer view)

Public API: **0** breakpoint attrs.

Internal behavior (implementation, not inputs):

- **Narrow:** stacked actions, full-width slotted controls.
- **From 479px:** row/wrap actions, auto-width controls.
- **From 992px:** desktop media overlay and focal treatment.

## 10. CSS requirement

Hero presentation requires LiveFrames CSS (precompiled or source-built). Without
it, semantic structure renders but verified styling, contrast, focus, and layout
do not apply.

## 11. Source-asset and fidelity truth

```text
attachment 880 = unavailable
image asset fidelity = unavailable
redistribution = unknown
full visual fidelity = not claimed
```

Do not depend on preview demo SVG/media as source fidelity.

## 12. Generator and ejection (relationship only)

Future generator/ejection may copy or adapt `hero/1` and CSS paths documented
here. Current releases expose the library module and static CSS only; no ejection
tooling ships in this phase.

## 13. Performance model

Static CSS, cache-friendly delivery, no per-request CSS generation. Tailwind
compilation is build-time when using the source path.

## 14. Consumer safety summary

- Text attrs: escaped HEEx.
- `image_src`: consumer-controlled URL/path.
- `rest`: consumer responsibility for valid global semantics.
- Actions: consumer-owned behavior and labels.
- Theme overrides: consumer-owned verification consequences.
