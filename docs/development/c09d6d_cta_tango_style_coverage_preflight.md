# C09D6-D0 — CTA Tango style-coverage preflight

**Plan ID:** `c09d6-d0-cta-tango-style-coverage`

**Version:** `v3`

**Status:** R5 verification PASS candidate; pending review and merge (`R5_EVIDENCE_STATE=verified`). D1 remains unauthorized until post-merge acceptance.

**Authority:** `docs/development/c09d6_native_generation_authority.md` §10.8, §10.9, §17, §19

**Repository base:** `3b18f94bb0ca960a4dcb6af441776addb8109b7a` (tree `b0ae20b5bf05a29e39c665547f0d877c532c7a4a`)

**Last updated:** 2026-10-09

### Revision log

- `v1` — Initial preflight on current `main`; verdict **BLOCKED**.
- `v2` — Review corrections: matrix count reconciliation, G-CUSTOM-CSS upstream boundary, primary-action proof, roadmap alignment.
- `v3` — Full 30-row R5 rerun on accepted post-R4 main; verification PASS candidate, evidence remains verified pending review and merge.

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
| Structural grid vars `--grid-1`, `--grid-2`, `--grid-3-2` | No authority | **Implemented and authorized** — exactly these three records in `AutomaticCSS.StructuralVariables`; R5 passed the authority explicitly |
| Native styling generator (C09D6-D) | N/A | **Not implemented** — Hero CSS is hand-authored (`hero.css`); `NativeGenerator` emits HEEx only |
| `Fidelity` | CSS serializer | **Not** the native styling generator (§10.9) |

## 5. Build / runtime architecture (confirmed)

Native styling path remains compile-time only: normalized artifacts → committed
package CSS → `priv/static/live_frames/css/live_frames.css`. No DB, Redis, ETS,
GenServer, Oban, PubSub, network, or request-time CSS generation (`docs/11` §13,
`docs/20` §6–9).

## 6. Historical v2 verdict (superseded by the R5 result in §14)

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
| G-CUSTOM-CSS | Image-group min-height; first-child span/full-width; second/third child aspect and layout | Source-only `_cssCustom` / `:nth-child(...)` recipes today — **not** generator authority | **Bounded upstream normalization** (separately authorized): source `complex_css` → **source-independent** semantic layout representation in Design IR / approved styling representation → **then** mechanical C09D6-D CSS emission. See §6.2. **C09D6-D must not** parse raw `_cssCustom`, rewrite arbitrary source selectors, or treat `.image-group-tango` / `:nth-child(...)` recipes as inputs. |
| G-TEXT-S | Accent heading `font-size: var(--text-s)` | TokenSet → `--lf-*` | Typography scale path for `text-s` (or explicit `token_ref` in IR) + TokenBridge mapping beyond `native_hero_v1` |
| G-RADIUS-ACSS | Image corners `var(--radius)` on all images | TokenSet → `--lf-*` | Public or component-private radius bridge (`radius.base` exists in TokenSet; not in `native_hero_v1.json` today) — required unless literals are authorized per-node |
| G-GRID-GAP-CALC | Inner gap `calc(var(--grid-gap) * 2)` | TokenSet / calculation | `spacing.grid_gap` → `--lf-*` bridge + documented calc policy for native CSS generator |

Non-blocking but noted: `heading` / `rich_text` nodes carry **zero** base styles
in normalized IR (empty global classes). The primary button has **no** styles in
IR (class hint only); required fill/hover/focus semantics are **PROVEN** from
reusable public `--lf-action-primary-*` tokens and ordinary package-owned CSS
capability (§8 rows CTA-D0-026/027) — **not** by reusing `.lf-hero__action--primary`
selectors.

### 6.2 G-CUSTOM-CSS — required upstream boundary (not C09D6-D)

Frozen C09D6 §10.9: preflight **STOP** when required styling depends on
source-only selector recipes or semantics omitted from IR/TokenSet; C09D6-D must
not reconstruct unsupported ACSS/source behavior heuristically.

**Required repair path:**

```text
source _cssCustom / complex_css (trace only)
        ↓
bounded, separately-authorized normalization
        ↓
source-independent semantic layout representation
        ↓
Design IR / approved styling representation
        ↓
C09D6-D mechanical CSS emission (package semantic selectors only)
```

**Forbidden in C09D6-D (and in this preflight as a “fix”):**

```text
complex_css → C09D6-D parses/rewrites selectors → committed CSS
```

For CTA Tango image-group layout, upstream work must make explicit and
source-independent (without preserving `.image-group-tango` or `:nth-child(...)`
as authority):

- group min-height (`675px` in source evidence);
- first-child full-width / column-span semantics;
- second-child `16/9` layout semantics (not only uniform per-image IR);
- third-child `5/3.5` aspect/layout semantics;
- any other child-specific rule currently only in `_cssCustom`.

Until that representation exists in approved IR/styling authority, rows
CTA-D0-010–013 remain **BLOCKED**. This preflight does **not** choose a new
Design IR schema; if schema or authority amendment is required, that is a
separate upstream slice before D0 re-run.

## 7. Responsive breakpoints used by CTA Tango

| Breakpoint | Used in source? | IR evidence | Native media authority |
| --- | --- | --- | --- |
| `tablet_portrait` / 991px | **Yes** — inner grid, image group justify/width | `ResponsiveOverride` on container + image-group nodes | **PROVEN** (`BreakpointAuthority`) |
| `mobile_landscape` / 767px | **Yes** — image group gap | `ResponsiveOverride` on image-group node | **PROVEN** |
| `mobile_portrait` / 478px | **No** in fragment | — | **NOT_REQUIRED** for this tracer |

## 8. Historical v2 style-coverage matrix

The statuses in this table record the original v2 result. The current R5 result for all 30 rows is in §14.

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
| CTA-D0-026 | Primary button fill/text/border/radius/padding | `btn--primary` class hint; `style: primary` | **No** button styles in IR; primary intent from `style: primary` | `docs/11` §7 action tokens; `native_hero_v1.json` `--lf-action-primary-*`; `docs/20` package-owned semantic CSS | `TokenBridge` + committed theme; Hero demonstrates slotted primary styling only as **precedent**, not CTA selector reuse | Future CTA sheet: generated package semantic selector (e.g. `.lf-section-*__action--primary`) + public `--lf-action-primary-*` on slotted `a`/`button` | NO | NO | PROVEN | — |
| CTA-D0-027 | Primary button hover/focus | ACSS btn family (not in fragment settings) | Not in IR; ordinary CSS pseudo capability | `docs/11` §3 (`:hover`, `:focus-visible` first-class); `--lf-action-primary-background-hover`, `--lf-action-primary-focus` in `native_hero_v1.json` | Theme tokens + Hero **example** of pseudo rules on slotted controls — CTA uses its own semantic selector at D time | Component CSS `:hover` / `:focus-visible` on slotted root | NO | NO | PROVEN | — |
| CTA-D0-028 | Button responsive width | No responsive button settings | — | — | — | Optional internal media in future CTA CSS | NO | NO | NOT_REQUIRED | — |
| CTA-D0-029 | Image assets sizing / src | Bricks `image` settings | Asset refs in IR (when resolved) | Design IR assets | Asset pipeline | HEEx `src` / placements | NO | NO | PROVEN | — |
| CTA-D0-030 | Flex wrap nowrap on image group | `_flexWrap: nowrap` | `flex-wrap: nowrap` | Design IR | Image-group node | Component CSS | NO | NO | PROVEN | — |

**Historical v2 counts:** 30 requirements — **PROVEN:** 14, **BLOCKED:** 10, **NOT_REQUIRED:** 6.

| Status | Row IDs |
| --- | --- |
| PROVEN | 001, 005, 007, 014, 015, 016, 017, 019, 021, 024, 026, 027, 029, 030 |
| BLOCKED | 003, 004, 006, 009, 010, 011, 012, 013, 020, 023 |
| NOT_REQUIRED | 002, 008, 018, 022, 025, 028 |

## 9. Historical v2 category checklist

| Category | Result |
| --- | --- |
| Structure / layout | **BLOCKED** — grid structural variables + `complex_css` layout |
| Spacing | **Mixed** — token gaps PROVEN; `calc(var(--grid-gap)*2)` BLOCKED |
| Typography | **BLOCKED** — `var(--text-s)`; main/rich text NOT_REQUIRED in IR |
| Colour / theme | NOT_REQUIRED at section level in source |
| Image / media | **BLOCKED** — `complex_css` composition + `var(--radius)` |
| Buttons / CTA | **PROVEN** — reusable `--lf-action-primary-*` + package CSS; CTA-specific semantic selector at D (not Hero selector reuse) |
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
  or other source class names; pasting `_cssCustom` rules verbatim; C09D6-D
  parsing/rewriting raw `complex_css` or source `:nth-child(...)` selector recipes;
  reusing `.lf-hero__*` selectors for CTA Tango.

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
  the R5 full-matrix verification is now PASS candidate pending review and merge; #129 remains open.

## 14. R5 full matrix rerun

```text
R5_VERIFICATION=PASS
R5_EVIDENCE_STATE=verified
D1_AUTHORIZED=NO
BASE_SHA=3b18f94bb0ca960a4dcb6af441776addb8109b7a
BASE_TREE=b0ae20b5bf05a29e39c665547f0d877c532c7a4a
PRIVATE_REFERENCE_PATH=private_reference/frames/staging-2026-09/cta-section-tango/bricks-component-hxambs-cta-section-tango.json
PRIVATE_REFERENCE_SHA256=73f866a27070c010584babe230b5ffd0c78dc704388fd8b6c286e149a3d93a87
PRIVATE_REFERENCE_BYTES=10224
PRIVATE_REFERENCE_COMPONENT_ID=hxambs
PRIVATE_REFERENCE_ELEMENT_COUNT=15
PRIVATE_REFERENCE_GLOBAL_CLASS_COUNT=13
```

R5 reran the canonical 30-row matrix against one normalization result from accepted `main`. The `TokenSet` used the D0E2 CTA settings overlay in memory. Structural-variable authority was enabled and passed explicitly to `Bricks.to_ir`. The committed settings fixture was not changed.

### 14.1 Reproduction command

Run from the repository root with the private reference present locally:

```sh
mix run --no-start -e '
path = "private_reference/frames/staging-2026-09/cta-section-tango/bricks-component-hxambs-cta-section-tango.json"
settings = Jason.decode!(File.read!("fixtures/automatic_css/acss_settings.json"))
  |> Map.merge(%{
    "base-text-mob" => 16,
    "base-text-desk" => 18,
    "mob-text-scale" => 1.2,
    "text-scale" => 1.333,
    "vp-min" => 360,
    "vp-max" => 1366,
    "text-s-min" => 14,
    "text-s-max" => 15
  })
{:ok, token_set, _diagnostics} = LiveFrames.Adapters.AutomaticCSS.normalize(settings,
  strict: true, profile: :hero_foundation,
  source_version: "4.0.1", source_version_status: "fixture_reference")
{:ok, structural_authority} =
  LiveFrames.Adapters.AutomaticCSS.structural_variable_authority(
    "4.0.1", grid_variables_enabled: true)
{:ok, document} = LiveFrames.Adapters.Bricks.to_ir(path,
  component_id: "hxambs",
  token_set: token_set,
  structural_variable_authority: structural_authority)
IO.write(Jason.encode!(LiveFrames.IR.Serializer.to_map(document), pretty: true))
'
```

The enabled authority contains exactly `--grid-1 → repeat(1, minmax(0, 1fr))`, `--grid-2 → repeat(2, minmax(0, 1fr))`, and `--grid-3-2 → minmax(0, 3fr) minmax(0, 2fr)`. `typography.body.scale.small` resolves under the active endpoint overrides to `clamp(0.875rem, calc(0.0994035785vw + 0.8526341948rem), 0.9375rem)`.

### 14.2 Fresh outcomes for all canonical rows

Every row below was checked against the R5 normalization output, package authorities, and the focused proofs listed in §14.5. `NOT_REQUIRED` means that no independent style is required by that row; it does not discard structure or styles covered by another row.

| D0 row | R5 state | Current normalized evidence and destination | Source dependency / inference |
| --- | --- | --- | --- |
| CTA-D0-001 | PROVEN | Root `hxambs`: `align-items: center`; section root | None / none |
| CTA-D0-002 | NOT_REQUIRED | No section background or text-color setting | None / none |
| CTA-D0-003 | PROVEN | `775f40`: desktop grid columns literal `minmax(0, 3fr) minmax(0, 2fr)` | No ACSS variable in semantic value / none |
| CTA-D0-004 | PROVEN | `775f40.gap`: multiply calculation with `spacing.grid_gap` and literal `2` | No `--grid-gap` operand / none |
| CTA-D0-005 | PROVEN | `775f40`: width `1100px`, auto side margins | None / none |
| CTA-D0-006 | PROVEN | `775f40` tablet columns literal `repeat(1, minmax(0, 1fr))` | No `--grid-1` semantic dependency / none |
| CTA-D0-007 | PROVEN | `775f40` tablet gap token ref `spacing.content_gap` | None / none |
| CTA-D0-008 | NOT_REQUIRED | `37f7b1` remains a structural media wrapper with no independent style | None / none |
| CTA-D0-009 | PROVEN | `0531fc`: columns `repeat(2, minmax(0, 1fr))`, rows `repeat(1, minmax(0, 1fr))` | No `--grid-*` semantic dependency / none |
| CTA-D0-010 | PROVEN | `0531fc`: `min-height: 675px` node-local literal | No `complex_css` input / none |
| CTA-D0-011 | PROVEN | `1171e1`: `grid-column: 1 / -1`, `width: 90%` | No selector required by D / none |
| CTA-D0-012 | PROVEN | `806d86`: `width: 100%`, `aspect-ratio: 16/9` | No selector required by D / none |
| CTA-D0-013 | PROVEN | `fc5f68`: `width: 100%`, `aspect-ratio: 5/3.5` | No selector required by D / none |
| CTA-D0-014 | PROVEN | `0531fc`: `justify-items: flex-end` | None / none |
| CTA-D0-015 | PROVEN | `0531fc` tablet: `justify-items: flex-start` | None / none |
| CTA-D0-016 | PROVEN | `0531fc` tablet: `width: 100%` | None / none |
| CTA-D0-017 | PROVEN | `0531fc` mobile landscape: token ref `spacing.scale.xs` | None / none |
| CTA-D0-018 | NOT_REQUIRED | Wrapper structure is retained; the independently required child layout is proven by 011–013 | No additional style / none |
| CTA-D0-019 | PROVEN | Images `0a0447`, `b3b3c9`, `b266bb`: object-fit cover, width/height 100% | None / none |
| CTA-D0-020 | PROVEN | All three image nodes: four radius properties reference `radius.base` | No `--radius` semantic value / none |
| CTA-D0-021 | PROVEN | `29c571`: centered content and `spacing.content_gap` row gap | None / none |
| CTA-D0-022 | NOT_REQUIRED | Heading node `ef8fa9` has no source style declaration | No inferred typography / none |
| CTA-D0-023 | PROVEN | `a29aa8.font-size` references `typography.body.scale.small`; D0E2 clamp and public mapping are available | No `--text-s` semantic value / none |
| CTA-D0-024 | PROVEN | `a29aa8`: `order: -1` | None / none |
| CTA-D0-025 | NOT_REQUIRED | Rich-text node `9c4498` has no source style declaration | No inferred typography / none |
| CTA-D0-026 | PROVEN | Button `8a7466` preserves primary intent; shared primary action token family and package CSS contract apply | No source builder class selector / none |
| CTA-D0-027 | PROVEN | Primary action hover and focus-visible are supported by the package pseudo-state contract | No source builder selector / none |
| CTA-D0-028 | NOT_REQUIRED | No responsive button-width setting exists in the source | No inferred responsive rule / none |
| CTA-D0-029 | PROVEN | Three image nodes retain `asset_refs` into document assets; sizing styles are proven by 019 | Asset URIs are unresolved source placeholders and are not D1 style inputs / none |
| CTA-D0-030 | PROVEN | `0531fc`: `flex-wrap: nowrap` | None / none |

```text
D0_MATRIX_TOTAL=30
D0_PROVEN_COUNT=24
D0_NOT_REQUIRED_COUNT=6
D0_BLOCKED_COUNT=0
D0_REQUIRED_UNRESOLVED_SOURCE_DEPENDENCIES=0
D0_REQUIRED_COMPLEX_CSS_DEPENDENCIES=0
```

Rows 029's three source image records are explicitly marked `unresolved_placeholder` with null URIs. R5 retains the asset references and makes no URI claim or substitution. This does not affect D1's required style values; the component's actual media source remains outside this style-only proof.

### 14.3 Required semantic mappings and bounded CSS results

```text
G_GRID_STRUCT=PROVEN
G_TEXT_S=PROVEN
G_RADIUS_ACSS=PROVEN
G_GRID_GAP_CALC=PROVEN
G_CUSTOM_CSS=PROVEN

TEXT_S_TOKEN_PATH=typography.body.scale.small
TEXT_S_RESOLVED_VALUE=clamp(0.875rem, calc(0.0994035785vw + 0.8526341948rem), 0.9375rem)
TEXT_S_PUBLIC_VARIABLE=--lf-typography-body-size-small

RADIUS_TOKEN_PATH=radius.base
RADIUS_PUBLIC_VARIABLE=--lf-radius-base

GRID_GAP_SEMANTIC_CALCULATION=StyleValue.calculation(multiply, token_ref(spacing.grid_gap), literal(2))
GRID_GAP_PUBLIC_VARIABLE=--lf-space-grid-gap

CCS_01_TARGET_0531FC=0531fc: min-height 675px
CCS_02_TARGET_1171E1=1171e1: grid-column 1 / -1; width 90%
CCS_03_TARGET_806D86=806d86: width 100%; aspect-ratio 16/9
CCS_04_TARGET_FC5F68=fc5f68: width 100%; aspect-ratio 5/3.5
CANONICAL_CSS_BLOB_REQUIRES_COMPLEX_CSS=NO
```

The shared public mappings above come from `apps/live_frames/priv/token_maps/native_shared_v1.json`. The supported custom CSS effects appear as ordinary node-local values in the R5 IR. Source selectors may remain in `source_selector_trace` provenance; D's semantic input does not consume those traces.

### 14.4 Source-independence scan

The scan covered normalized base and responsive `StyleValue.value` payloads. It excluded source settings, `source_expression`, `source_trace`, and `source_selector_trace`, which may retain provenance.

```text
REQUIRED_SEMANTIC_VALUE_CONTAINS_VAR_GRID_*=NO
REQUIRED_SEMANTIC_VALUE_CONTAINS_VAR_GRID_GAP=NO
REQUIRED_SEMANTIC_VALUE_CONTAINS_VAR_RADIUS=NO
REQUIRED_SEMANTIC_VALUE_CONTAINS_VAR_TEXT_S=NO
REQUIRED_COMPLEX_CSS_DEPENDENCY=NO
REQUIRED_SOURCE_SELECTOR_DEPENDENCY=NO
REQUIRED_SOURCE_RUNTIME_DEPENDENCY=NO
```

The scan found zero prohibited source-variable strings, selector strings, or `complex_css` values in the required base and responsive semantic payloads. The source trace retains the original expressions for evidence. The normalizer emitted unresolved-placeholder asset warnings and breakpoint/variable diagnostics; none supplies a required style value to D.

### 14.5 Ten former blockers: durable row evidence

```text
EVIDENCE_ID=R5-CTA-D0-003
D0_ROW=CTA-D0-003
PREVIOUS_STATE=BLOCKED
CURRENT_STATE=PROVEN
SOURCE_INPUT=_gridTemplateColumns: var(--grid-3-2)
NORMALIZATION_PATH=Bricks.to_ir with ACSS 4.0.1 structural_variable_authority explicitly enabled
SEMANTIC_OUTPUT=grid-template-columns literal minmax(0, 3fr) minmax(0, 2fr)
TARGET_NODE=775f40
REPRODUCTION_COMMAND=§14.1
TEST_OR_PROOF=CTA Tango R5 full style-coverage proof asserts the private CTA grid literal with enabled structural authority
LIMITATION=No CSS emission is part of R5.

EVIDENCE_ID=R5-CTA-D0-004
D0_ROW=CTA-D0-004
PREVIOUS_STATE=BLOCKED
CURRENT_STATE=PROVEN
SOURCE_INPUT=calc(var(--grid-gap) * 2)
NORMALIZATION_PATH=Bricks.to_ir structured calculation normalization plus native_shared_v1 mapping
SEMANTIC_OUTPUT=calculation multiply with token_ref spacing.grid_gap and literal factor 2; no source --grid-gap operand
TARGET_NODE=775f40.gap
REPRODUCTION_COMMAND=§14.1
TEST_OR_PROOF=CTA Tango R5 full style-coverage proof asserts the calculation; native_shared_v1 contains --lf-space-grid-gap
LIMITATION=R5 proves the operand and public mapping only; D1 CSS emission is not implemented.

EVIDENCE_ID=R5-CTA-D0-006
D0_ROW=CTA-D0-006
PREVIOUS_STATE=BLOCKED
CURRENT_STATE=PROVEN
SOURCE_INPUT=tablet_portrait grid-template-columns var(--grid-1)
NORMALIZATION_PATH=Bricks.to_ir with enabled ACSS structural authority and responsive normalization
SEMANTIC_OUTPUT=tablet_portrait grid-template-columns literal repeat(1, minmax(0, 1fr))
TARGET_NODE=775f40.responsive.tablet_portrait
REPRODUCTION_COMMAND=§14.1
TEST_OR_PROOF=CTA Tango R5 full style-coverage proof asserts the private responsive grid literal with enabled structural authority
LIMITATION=No CSS emission is part of R5.

EVIDENCE_ID=R5-CTA-D0-009
D0_ROW=CTA-D0-009
PREVIOUS_STATE=BLOCKED
CURRENT_STATE=PROVEN
SOURCE_INPUT=image-group grid-template columns and rows use --grid-2 and --grid-1
NORMALIZATION_PATH=Bricks.to_ir with enabled ACSS structural authority
SEMANTIC_OUTPUT=columns repeat(2, minmax(0, 1fr)); rows repeat(1, minmax(0, 1fr)); gap token_ref spacing.content_gap
TARGET_NODE=0531fc
REPRODUCTION_COMMAND=§14.1
TEST_OR_PROOF=CTA Tango R5 full style-coverage proof asserts the private image-group grid literals with enabled structural authority
LIMITATION=No CSS emission is part of R5.

EVIDENCE_ID=R5-CTA-D0-010
D0_ROW=CTA-D0-010
PREVIOUS_STATE=BLOCKED
CURRENT_STATE=PROVEN
SOURCE_INPUT=bounded CCS-01 owner min-height rule
NORMALIZATION_PATH=Bricks.to_ir bounded custom CSS normalization
SEMANTIC_OUTPUT=min-height literal 675px
TARGET_NODE=0531fc
REPRODUCTION_COMMAND=§14.1
TEST_OR_PROOF=Canonical R5 IR and bounded custom CSS test
LIMITATION=The source selector is retained only as provenance; no generic selector parsing is authorized.

EVIDENCE_ID=R5-CTA-D0-011
D0_ROW=CTA-D0-011
PREVIOUS_STATE=BLOCKED
CURRENT_STATE=PROVEN
SOURCE_INPUT=bounded CCS-02 first-child span and width rule
NORMALIZATION_PATH=Bricks.to_ir bounded child-index normalization
SEMANTIC_OUTPUT=grid-column literal 1 / -1; width literal 90%
TARGET_NODE=1171e1
REPRODUCTION_COMMAND=§14.1
TEST_OR_PROOF=Canonical R5 IR and bounded custom CSS test
LIMITATION=Child identity is resolved by the accepted bounded Bricks tree path; D receives node-local styles.

EVIDENCE_ID=R5-CTA-D0-012
D0_ROW=CTA-D0-012
PREVIOUS_STATE=BLOCKED
CURRENT_STATE=PROVEN
SOURCE_INPUT=bounded CCS-03 second-child width and aspect rule
NORMALIZATION_PATH=Bricks.to_ir bounded child-index normalization
SEMANTIC_OUTPUT=width literal 100%; aspect-ratio literal 16/9
TARGET_NODE=806d86
REPRODUCTION_COMMAND=§14.1
TEST_OR_PROOF=Canonical R5 IR and bounded custom CSS test
LIMITATION=The ratio is attached to the wrapper node; image source provenance may retain the original selector.

EVIDENCE_ID=R5-CTA-D0-013
D0_ROW=CTA-D0-013
PREVIOUS_STATE=BLOCKED
CURRENT_STATE=PROVEN
SOURCE_INPUT=bounded CCS-04 third-child width and aspect rule
NORMALIZATION_PATH=Bricks.to_ir bounded child-index normalization
SEMANTIC_OUTPUT=width literal 100%; aspect-ratio literal 5/3.5
TARGET_NODE=fc5f68
REPRODUCTION_COMMAND=§14.1
TEST_OR_PROOF=Canonical R5 IR and bounded custom CSS test
LIMITATION=The ratio is attached to the wrapper node; image source provenance may retain the original selector.

EVIDENCE_ID=R5-CTA-D0-020
D0_ROW=CTA-D0-020
PREVIOUS_STATE=BLOCKED
CURRENT_STATE=PROVEN
SOURCE_INPUT=each image corner radius uses var(--radius)
NORMALIZATION_PATH=Bricks token canonicalization to radius.base plus native_shared_v1 mapping
SEMANTIC_OUTPUT=four image corner values reference radius.base; public variable --lf-radius-base
TARGET_NODE=0a0447, b3b3c9, b266bb
REPRODUCTION_COMMAND=§14.1
TEST_OR_PROOF=CTA Tango R5 full style-coverage proof checks all four radius properties on each exact image ID
LIMITATION=The normalization diagnostic retains ambiguous source-variable provenance; required StyleValue values are token references.

EVIDENCE_ID=R5-CTA-D0-023
D0_ROW=CTA-D0-023
PREVIOUS_STATE=BLOCKED
CURRENT_STATE=PROVEN
SOURCE_INPUT=accent font-size uses var(--text-s)
NORMALIZATION_PATH=In-memory D0E2 TokenSet overlay plus Bricks token canonicalization
SEMANTIC_OUTPUT=typography.body.scale.small with the accepted 14px/15px clamp
TARGET_NODE=a29aa8.font-size
REPRODUCTION_COMMAND=§14.1
TEST_OR_PROOF=CTA Tango R5 full style-coverage proof asserts the token path and exact D0E2 CSS expression
LIMITATION=The default fixture lacks endpoint overrides; R5 applies the accepted overlay in memory.
```

The canonical CSS normalization proof covers `0531fc`, `1171e1`, `806d86`, and `fc5f68`. The tagged private-reference run passed both the historical R3 proof and the new R5 proof: 2 tests, 0 failures. The R5 assertions executed with the local private reference present. Bounded custom CSS tests passed: 33 tests, 0 failures.

### 14.6 R5 gate state

```text
R5_VERDICT=PASS
R5_EVIDENCE_STATE=verified
D1_AUTHORIZED=NO
PRODUCTION_CODE_CHANGE=NONE
HOT_DATA=N/A
REDIS=N/A
POSTGRES=N/A
PUBSUB=N/A
OBAN=N/A
100K_RUNTIME_CONCURRENCY=N/A
```

This is a pre-merge verification result. R5 becomes accepted only after independent review, merge, and successful post-merge CI on the exact main commit.
