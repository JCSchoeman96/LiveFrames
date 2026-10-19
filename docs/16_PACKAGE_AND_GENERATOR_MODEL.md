# Package and generator model

**Status:** Consumer and package integration guide for the **`live_frames`**
library. Assumes **`:live_frames` is already present** as a Mix dependency in the
host umbrella or application. Hex publication, version pinning, and release
automation are **out of scope** for this document unless repository truth proves
otherwise.

Cross-cutting CSS strategy: **`docs/11_CSS_AND_TAILWIND_STRATEGY.md`**. P6.4
architecture history: **`docs/20_P6_4A_NATIVE_STYLING_BRIDGE_ARCHITECTURE.md`**.

`LiveFrames.NativeGenerator` is implemented in the library. It generates
in-memory native component artifacts from approved inputs. P10
consumer-project ejection is a separate capability and remains unimplemented.

## Catalogue and package boundaries

CatalogueItem RELEASED is an item-level Catalogue/distribution state. It does
not imply Mix, Hex, GitHub, or other package publication. Package publication
requires separate evidence, and package version is independent of CatalogueItem
release_version.

The canonical Catalogue source tree exists at
`apps/live_frames/priv/catalogue/` and contains the production CTA manifest.
Package compilation uses these files as `Registry.Builder` input, while runtime
reads only the compiled Registry. The CTA item
`live_frames.section.media_call_to_action` is `APPROVED`. Its library
distribution capability is governed by the accepted C2D2R1 evidence review and
the separate C2D3 manifest-persistence gate. C2D2A proves that the built and
unpacked LiveFrames source package contains the canonical Catalogue JSON and
`LICENSE-PROPRIETARY.txt`.

These manifests are inspectable package source. The public Catalogue API's
visibility rules do not make them confidential. The proprietary notice and
package metadata do not grant CTA redistribution permission. See the #51 build
and CI contract in [docs/23](23_CATALOGUE_ARCHITECTURE.md).

Library, native generation, and ejection are independent capabilities.
Catalogue release does not require generator or ejection support. Native
generation is implemented; P10 ejection is not. See
[docs/23_CATALOGUE_ARCHITECTURE.md](23_CATALOGUE_ARCHITECTURE.md) and
[docs/24_CATALOGUE_VERSIONING_POLICY.md](24_CATALOGUE_VERSIONING_POLICY.md).

## 1. Package layout (consumer-relevant paths)

| Path | Role |
| --- | --- |
| `lib/live_frames/components/sections/hero.ex` | Native Hero function component |
| `lib/live_frames/components/sections/media_call_to_action.ex` | Native CTA function component |
| `assets/css/live_frames.css` | Optional Tailwind v4 **source** entry |
| `assets/css/theme/lf_theme.css` | Generated public `--lf-*` theme (read-only) |
| `assets/css/components/sections/hero.css` | Hero semantic presentation CSS |
| `assets/css/components/sections/media_call_to_action.css` | CTA package-owned presentation CSS, imported by the source CSS entry |
| `priv/static/live_frames/css/live_frames.css` | **Precompiled** CSS (primary runtime path) |
| `priv/token_maps/` | Token bridge inputs (build/generation; not a runtime API) |
| `priv/catalogue/` | Existing canonical Catalogue source and `Registry.Builder` input |
| `LICENSE-PROPRIETARY.txt` | Proprietary package notice; it grants no redistribution permission |

`apps/live_frames/mix.exs` includes `priv/catalogue` and
`LICENSE-PROPRIETARY.txt` in `package/0 :files`. CI builds and unpacks the real
package with `mix hex.build --unpack`, then verifies the required package roots
and canonical Catalogue JSON byte-for-byte. C2D2A proves this package boundary;
it does not prove Hex publication or accept `distribution.library=supported`.
Package inclusion does not filter manifests by lifecycle or discovery state and
does not grant redistribution clearance or generator or ejection support.

## 2. Component import and use

The native CTA API is:

```text
LiveFrames.Components.Sections.MediaCallToAction
media_call_to_action/1
```

It requires `heading`, three image source/alt pairs, and one
`primary_action` slot entry. `heading_level` defaults to `2` and accepts `1..6`;
`eyebrow`, `class`, `rest`, and one `body` slot entry are optional. The module
rejects missing or empty image alt text and invalid slot cardinality.

```elixir
import LiveFrames.Components.Sections.MediaCallToAction

~H"""
<.media_call_to_action
  heading="A place to begin"
  image_1_src="/images/first.svg"
  image_1_alt="First image"
  image_2_src="/images/second.svg"
  image_2_alt="Second image"
  image_3_src="/images/third.svg"
  image_3_alt="Third image"
>
  <:primary_action><a href="/details">See the details</a></:primary_action>
</.media_call_to_action>
"""
```

The API above follows the implementation and component tests. The preview has a
Storybook story and route test. C1's accepted clean external consumer proof used
a local path dependency to the exact LiveFrames application. C1 does not prove:

- the distributable package boundary;
- Hex publication;
- `distribution.library=supported`;
- P10 consumer-project ejection.

C2D2A separately proves that the actual built and unpacked LiveFrames source
package contains the required package roots and canonical Catalogue content.
C1 and C2D2A alone do not establish library capability evidence. C2D2R1
separately records the accepted library-capability evidence. Persisting that
accepted claim is the separate C2D3 manifest-mutation gate.

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

Importing source CSS pulls the theme, Hero CSS, and CTA CSS but **not**
Preflight; the host base styles remain the host's responsibility.

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

### Public styling surfaces

| Surface | Role |
| --- | --- |
| `.lf-hero*` | **Public** semantic component class namespace (package-owned selectors) |
| `--lf-*` from generated theme | **Public** theme customization surface — **preferred** for consumer theming |
| `--lf-hero-*` on `.lf-hero` | **Private** composition variables — not public theme API |

Semantic TokenSet values are authoritative; `lf_theme.css` is the generated
resolved CSS output; `native_hero_v1.json` is mapping metadata only (see
`docs/11`). Variable groups: `docs/11`. Do not duplicate literal values here.

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

Hero and CTA presentation require LiveFrames CSS (precompiled or source-built).
The CTA stylesheet is part of the source CSS import graph and the committed
precompiled `priv/static/live_frames/css/live_frames.css` artifact. Repository
tests and the preview Storybook test verify CTA rendering and styling presence.
The accepted C1 external consumer proof and C2D2A package-boundary proof are
recorded separately above; neither establishes `distribution.library=supported`.

## 11. Source-asset and fidelity truth

```text
attachment 880 = unavailable
image asset fidelity = unavailable
redistribution = unknown
full visual fidelity = not claimed
```

Do not depend on preview demo SVG/media as source fidelity.

## 12. Native generation and P10 ejection

`LiveFrames.NativeGenerator` accepts an approved `ComponentContract`, matching
`ComponentizationPlan`, and exact `DesignDocument`. It returns an in-memory
artifact bundle containing generated native component source and package CSS.
It does not write into a consumer project or perform Catalogue admission.

P10 consumer-project ejection is separate:

```text
NativeGenerator
!=
P10 consumer-project ejection
```

P10 would copy or adapt a selected Catalogue item into a consumer project. It is
not implemented. C1's accepted local-path consumer proof and C2D2A's accepted
package-boundary proof are separate evidence; neither establishes P10 or
`distribution.library=supported`. This guide makes no Hex publication or public
release claim.

## 13. Performance model

Static CSS, cache-friendly delivery, no per-request CSS generation. Tailwind
compilation is build-time when using the source path.

## 14. Consumer safety summary

- Text attrs: escaped HEEx.
- `image_src`: consumer-controlled URL/path.
- `rest`: consumer responsibility for valid global semantics.
- Actions: consumer-owned behavior and labels.
- Theme overrides: consumer-owned verification consequences.
