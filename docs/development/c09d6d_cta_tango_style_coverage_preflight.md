# C09D6-D0 — CTA Tango style-coverage preflight

**Plan ID:** `c09d6-d0-cta-tango-style-coverage`

**Version:** `v1`

**Status:** complete — **C09D6-D implementation NOT authorized**

**Authority:** `docs/development/c09d6_native_generation_authority.md` §10.8, §10.9, §17, §19

**Repository base:** `c09e6fd721e003ce65ffd46c359adc027cf70efb` (tree `c770ddec3aeb36effc978a1e16c1e0ed4058d2b7`)

**Last updated:** 2026-10-07

### Revision log

- `v1` — Initial preflight on current `main`; verdict **BLOCKED**.

## 1. Objective

Prove whether every visually meaningful style required by the **CTA Section Tango**
static tracer can be represented from approved Design IR, TokenSet, responsive IR,
and/or existing package styling authority (`docs/11`, `docs/20`, `TokenBridge`)
without source guessing, ACSS class reconstruction, or Fidelity as the native
styling generator.

## 2. Canonical CTA Tango evidence identity

| Artifact | Path | Identity |
| --- | --- | --- |
| Bricks component fragment (primary) | `private_reference/frames/staging-2026-09/cta-section-tango/bricks-component-hxambs-cta-section-tango.json` | SHA-256 `73f866a27070c010584babe230b5ffd0c78dc704388fd8b6c286e149a3d93a87`; 10 224 bytes; component id `hxambs`; 15 elements; 13 `globalClasses` |
| Frames export corpus (parent set) | `private_reference/frames/staging-2026-09/` (34 records, `Archive.tar.gz` excluded) | Digest `074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e` per `docs/development/c09a_query_dynamic_data_contract.md` |
| Catalogue index pointer | `fixtures/bricks/bricks_components.json` / `sources/bricks_components.json` | Label **CTA Section Tango**; Bricks cid `ourczc`; envelope index only (not the full fragment) |
| PNG captures (identity only; **not** styling authority) | `private_reference/frames/staging-2026-09/cta-section-tango/desktop.png`, `mobile.png` | Present locally; **not** used for style inference in this preflight |
| Query / Behavior IR | — | **None** in export (`docs/development/c09a_query_dynamic_data_contract.md`) |

**Design IR reproduction (deterministic, current `main`):**

```sh
# From repo root; requires local private_reference (gitignored) per C09A/C07X contracts.
mix run --no-start -e '
path = "private_reference/frames/staging-2026-09/cta-section-tango/bricks-component-hxambs-cta-section-tango.json"
{:ok, token_set, _} = LiveFrames.Adapters.AutomaticCSS.from_file(
  "fixtures/automatic_css/acss_settings.json",
  source_version: "4.0.1", source_version_status: "fixture_reference",
  strict: true, profile: :hero_foundation
)
json = Jason.decode!(File.read!(path))
source = %{"components" => json["components"], "globalClasses" => json["globalClasses"]}
{:ok, doc} = LiveFrames.Adapters.Bricks.to_ir(source, component_id: "hxambs", token_set: token_set)
IO.puts("root_nodes=#{length(doc.root_nodes)}")
'
```

No committed `sources/work/cta_tango/design_ir/` artifact exists; normalization output
above is the authoritative IR evidence for this preflight.

## 3. Tracer scope (static)

Static surface only: section layout, two-column grid, three-image composition,
accent + main headings, rich-text body, primary CTA button. No tabs, queries,
scripts, or runtime Behavior IR.

## 4. Current pipeline truths (rebasing C07X)

| Topic | Historical C07X note | Current `main` truth |
| --- | --- | --- |
| `mobile_landscape` / 767px | Recorded missing | **Implemented** — `BreakpointAuthority` + tests (`apps/live_frames/test/live_frames/responsive/breakpoint_authority_test.exs`) |
| Responsive cascade 991 / 767 / 478 | Partial | **Proven** in responsive resolution / fidelity responsive tests |
| Structural grid vars `--grid-2`…`--grid-12` | No authority | **Still true** — only `--grid-1` in `AutomaticCSS.StructuralVariables` |
| Native styling generator (C09D6-D) | N/A | **Not implemented** — Hero CSS is hand-authored (`hero.css`); `NativeGenerator` emits HEEx only |
| `Fidelity` | CSS serializer | **Not** the native styling generator (§10.9) |

## 5. Build / runtime architecture (confirmed)

Native styling path remains compile-time only: normalized artifacts → committed
package CSS → `priv/static/live_frames/css/live_frames.css`. No DB, Redis, ETS,
GenServer, Oban, PubSub, network, or request-time CSS generation (`docs/11` §13,
`docs/20` §6–9).

## 6. Final verdict

```text
C09D6_D_STYLE_COVERAGE=BLOCKED
```

At least one **required** visual semantics cannot be represented on the native
styling path without guessing, emitting ACSS/source selectors, or depending on
unsupported structural variables. **C09D6-D1 styling-generator implementation
is NOT authorized.**

### 6.1 Blocking gaps (summary)

| Gap ID | Visual requirement | Layer | Smallest upstream slice |
| --- | --- | --- | --- |
| G-GRID-STRUCT | `grid-template-columns: var(--grid-3-2)` / `var(--grid-2)` / responsive `var(--grid-1)` on inner / image group | Structural variable + TokenSet / `--lf-*` bridge | Extend `AutomaticCSS.StructuralVariables` (and native token mapping policy) for `--grid-2`, `--grid-3-2`, or replace with approved literal/`--lf-*` grid recipes without ACSS names |
| G-CUSTOM-CSS | Image-group min-height, per-child width/column/aspect-ratio rules | Design IR `complex_css` → native styling authority | New **native** (non-Fidelity) `complex_css` emission contract: rewrite to package semantic selectors (`docs/20` §8); cannot paste `.image-group-tango` rules |
| G-TEXT-S | Accent heading `font-size: var(--text-s)` | TokenSet → `--lf-*` | Typography scale path for `text-s` (or explicit `token_ref` in IR) + TokenBridge mapping beyond `native_hero_v1` |
| G-RADIUS-ACSS | Image corners `var(--radius)` on all images | TokenSet → `--lf-*` | Public or component-private radius bridge (`radius.base` exists in TokenSet; not in `native_hero_v1.json` today) — required unless literals are authorized per-node |
| G-GRID-GAP-CALC | Inner gap `calc(var(--grid-gap) * 2)` | TokenSet / calculation | `spacing.grid_gap` → `--lf-*` bridge + documented calc policy for native CSS generator |

Non-blocking but noted: `heading` / `rich_text` / `button` nodes carry **zero**
base styles in normalized IR (presentation from empty global classes or class
hints only). Primary button **can** follow Hero action CSS + `--lf-action-primary-*`
(`hero.css`, `native_hero_v1.json`) without `btn--primary` in public CSS.

## 7. Responsive breakpoints used by CTA Tango

| Breakpoint | Used in source? | IR evidence | Native media authority |
| --- | --- | --- | --- |
| `tablet_portrait` / 991px | **Yes** — inner grid, image group justify/width | `ResponsiveOverride` on container + image-group nodes | **PROVEN** (`BreakpointAuthority`) |
| `mobile_landscape` / 767px | **Yes** — image group gap | `ResponsiveOverride` on image-group node | **PROVEN** |
| `mobile_portrait` / 478px | **No** in fragment | — | **NOT_REQUIRED** for this tracer |

## 8. Style-coverage matrix

Legend: **Status** = `PROVEN` | `BLOCKED` | `NOT_REQUIRED`.

| ID | Visual requirement | Source evidence | Normalized representation | Authority | Current implementation | Styling destination | Source leakage? | Guess? | Status | Blocking dependency |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CTA-D0-001 | Section root vertical alignment (center) | Intrinsic `brxe-section` + class `cta-section-tango` (empty settings) | `align-items: center` keyword on section node | Bricks intrinsic defaults → Design IR | `DesignIRNormalizer` intrinsic merge | `.lf-section-*` root | NO | NO | PROVEN | — |
| CTA-D0-002 | Section background / text color | No settings on `cta-section-tango` | None in IR | — | — | Theme / host context | NO | NO | NOT_REQUIRED | — |
| CTA-D0-003 | Inner 2-column desktop grid | `cta-section-tango__inner` `_display`, `_gridTemplateColumns: var(--grid-3-2)` | `display:grid`, `grid-template-columns: var(--grid-3-2)` literals | Design IR literals + structural vars | Normalized on container node | Component CSS grid | YES if emit `--grid-3-2` | NO | **BLOCKED** | G-GRID-STRUCT |
| CTA-D0-004 | Inner grid gap desktop | `_gridGap: calc(var(--grid-gap) * 2)` | `gap: calc(var(--grid-gap) * 2)` | Design IR calculation | On container | Component CSS gap | YES (`--grid-gap`) | NO | **BLOCKED** | G-GRID-GAP-CALC |
| CTA-D0-005 | Inner max width 1100px centered | `_width: 1100px`, auto margins | Literals in IR | Design IR | On container | Component CSS width/margin | NO | NO | PROVEN | — |
| CTA-D0-006 | Inner single column tablet | `_gridTemplateColumns:tablet_portrait: var(--grid-1)` | `responsive.tablet_portrait.grid-template-columns` | Responsive IR | `ResponsiveOverride` | `@media (max-width: 991px)` block | YES if emit `var(--grid-1)` without bridge | NO | **BLOCKED** | G-GRID-STRUCT (bridge) |
| CTA-D0-007 | Inner gap tablet | `_gridGap:tablet_portrait: var(--content-gap)` | `token_ref: spacing.content_gap` at tablet | TokenSet + responsive IR | Normalized override | Responsive gap via `--lf-space-content-gap` | NO | NO | PROVEN | — |
| CTA-D0-008 | Media column wrapper | `cta-section-tango__media-wrapper` empty class | No styles | — | — | Structural wrapper in HEEx only | NO | NO | NOT_REQUIRED | — |
| CTA-D0-009 | Image group desktop grid 2-col | `image-group-tango` grid settings | `display:grid`, `grid-template-columns: var(--grid-2)`, rows `var(--grid-1)`, gap token | Design IR | On generic node | Component CSS | YES | NO | **BLOCKED** | G-GRID-STRUCT |
| CTA-D0-010 | Image group min-height 675px | `_cssCustom` on `image-group-tango` | `styles.custom-css` `complex_css` rules | Design IR `complex_css` | Preserved in IR | Component CSS child rules | YES (source selectors in rules) | NO | **BLOCKED** | G-CUSTOM-CSS |
| CTA-D0-011 | First image full width / column span | `_cssCustom` `:first-child` rules | Same `complex_css` blob | Design IR `complex_css` | Preserved | Semantic child selectors | YES | NO | **BLOCKED** | G-CUSTOM-CSS |
| CTA-D0-012 | Second image 16/9 aspect | `_cssCustom` `:nth-child(2)` + per-node `_aspectRatio` | Conflict: all `image` nodes have `aspect-ratio:16/9` in IR; differentiated ratio only in `complex_css` | Design IR | Image nodes + complex_css | Component CSS | YES | NO | **BLOCKED** | G-CUSTOM-CSS |
| CTA-D0-013 | Third image 5/3.5 aspect | `_cssCustom` `:nth-child(3)` | Only in `complex_css` | Design IR `complex_css` | Not on per-image IR | Component CSS | YES | NO | **BLOCKED** | G-CUSTOM-CSS |
| CTA-D0-014 | Image group justify desktop end | `_justifyItemsGrid: flex-end` | `justify-items: flex-end` | Design IR | On image-group | Component CSS | NO | NO | PROVEN | — |
| CTA-D0-015 | Image group justify tablet start | `_justifyItemsGrid:tablet_portrait` | Responsive `justify-items` | Responsive IR | Override | `@media 991px` | NO | NO | PROVEN | — |
| CTA-D0-016 | Image group width tablet 100% | `_width:tablet_portrait: 100%` | Responsive width | Responsive IR | Override | Responsive block | NO | NO | PROVEN | — |
| CTA-D0-017 | Image group gap mobile landscape | `_gridGap:mobile_landscape: var(--space-xs)` | `token_ref: spacing.scale.xs` | TokenSet + responsive | Override | `@media 767px` | NO | NO | PROVEN | — |
| CTA-D0-018 | Image wrapper boxes | `image-group-tango__image-wrapper` empty | No styles | — | — | HEEx structure | NO | NO | NOT_REQUIRED | — |
| CTA-D0-019 | Image cover + fill box | `image-group-tango__image` | `object-fit:cover`, `width/height:100%` | Design IR | Per image node | Component CSS | NO | NO | PROVEN | — |
| CTA-D0-020 | Image border radius | `_border.radius: var(--radius)` | Four corner radii `var(--radius)` | Design IR literals | Per image | Component CSS | YES (`--radius`) | NO | **BLOCKED** | G-RADIUS-ACSS |
| CTA-D0-021 | Content stack centered | `cta-section-tango__content-wrapper` | `justify-content:center`, `row-gap` token | Design IR | On content wrapper | Component CSS flex | NO | NO | PROVEN | — |
| CTA-D0-022 | Main heading typography | `cta-section-tango__heading` empty class | No IR styles | — | — | Package defaults / future contract typography | NO | YES if invented | NOT_REQUIRED | — |
| CTA-D0-023 | Accent heading uppercase small type | `fr-accent-heading` typography map | `font-size: var(--text-s)`, weight, tracking, etc. | Design IR on paragraph node | Normalized | Component CSS | YES (`--text-s`) | NO | **BLOCKED** | G-TEXT-S |
| CTA-D0-024 | Accent heading order -1 | `_order: -1` | `order: -1` | Design IR | Paragraph node | Component CSS | NO | NO | PROVEN | — |
| CTA-D0-025 | Body rich text typography | `cta-section-tango__text` empty | No IR styles | — | — | Inherited body tokens | NO | NO | NOT_REQUIRED | — |
| CTA-D0-026 | Primary button fill/text/border/radius/padding | `btn--primary` class hint; `style: primary` | **No** button styles in IR | Hero action pattern | `hero.css` + `native_hero_v1` action tokens | `.lf-*-__action--primary` slotted pattern | NO | NO | PROVEN | — |
| CTA-D0-027 | Primary button hover/focus | ACSS btn family (not in fragment settings) | Hero CSS pseudo rules | `docs/11`, `hero.css` | Existing package CSS | `:hover` / `:focus-visible` on slotted control | NO | NO | PROVEN | — |
| CTA-D0-028 | Button responsive width | No responsive button settings | — | Hero actions pattern | `hero.css` breakpoints | Internal media queries | NO | NO | NOT_REQUIRED | — |
| CTA-D0-029 | Image assets sizing / src | Bricks `image` settings | Asset refs in IR (when resolved) | Design IR assets | Asset pipeline | HEEx `src` / placements | NO | NO | PROVEN | — |
| CTA-D0-030 | Flex wrap nowrap on image group | `_flexWrap: nowrap` | `flex-wrap: nowrap` | Design IR | Image-group node | Component CSS | NO | NO | PROVEN | — |

**Counts:** 30 requirements — **PROVEN:** 16, **BLOCKED:** 11, **NOT_REQUIRED:** 3.

## 9. Category checklist

| Category | Result |
| --- | --- |
| Structure / layout | **BLOCKED** — grid structural variables + `complex_css` layout |
| Spacing | **Mixed** — token gaps PROVEN; `calc(var(--grid-gap)*2)` BLOCKED |
| Typography | **BLOCKED** — `var(--text-s)`; main/rich text NOT_REQUIRED in IR |
| Colour / theme | NOT_REQUIRED at section level in source |
| Image / media | **BLOCKED** — `complex_css` composition + `var(--radius)` |
| Buttons / CTA | **PROVEN** via Hero action + TokenBridge pattern |
| Responsive | **PROVEN** for 991 + 767 where not BLOCKED by variable/CSS gaps |
| Pseudo / selectors | **BLOCKED** for image-group rules unless G-CUSTOM-CSS resolved |
| Tokens / variables | **BLOCKED** for ACSS grid + text-s + radius public surface |

## 10. Fidelity boundary

`LiveFrames.Fidelity` can serialize `custom-css` and resolve some ACSS class
hints for preview; that path is **explicitly excluded** from C09D6-D (§10.9).
No native styling module equivalent exists on `main`.

## 11. C09D6-D implementation contract (frozen — not authorized)

Until gaps G-* are closed with new authority and implementation:

- **Inputs:** NOT authorized — do not implement generator.
- **Outputs:** NOT authorized.
- **Forbidden:** Fidelity as generator; public `btn--primary`, `image-group-tango`,
  or other source class names; pasting `_cssCustom` rules verbatim.

When unblocked, expected outputs remain per §10.8: `assets/css/components/...`,
`live_frames.css` import graph, `--lf-*` via `TokenBridge`.

## 12. Tests cited

| Claim | Test / command |
| --- | --- |
| 991 / 767 / 478 breakpoint authority | `mix test apps/live_frames/test/live_frames/responsive/breakpoint_authority_test.exs` |
| Responsive binding | `mix test apps/live_frames/test/live_frames/responsive/resolution_test.exs` |
| TokenBridge / theme | `mix test apps/live_frames/test/live_frames/styling/token_bridge_test.exs` |
| Grid variable gap (structural) | `mix test apps/live_frames/test/live_frames/automatic_css_structural_variables_test.exs` |
| IR normalization | Reproduction command §2 |

## 13. GitHub issues

- **#128 (C09D6-C):** CLOSED — merge `c09e6fd721e003ce65ffd46c359adc027cf70efb`.
- **#129 (C09D6-D):** OPEN — historical “blocked by #128” is **stale** after C merge;
  **actual gate** is this preflight (**BLOCKED**) and upstream G-* slices, not #128.
