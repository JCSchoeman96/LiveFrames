# C-08B1 — Bricks icon source contract (authority)

| Field | Value |
| --- | --- |
| Plan ID | C-08B1 |
| Plan version | v2 |
| Status | Active contract (documentation only) |
| Scope | Freeze source-independent icon representation before dedicated icon rendering |
| Authority | This file is the active contract for C-08B icon work. C-08A TokenSet authority remains separate. |
| Last updated | 2026-09-30 |
| Base commit | `0c6e4d87822544e16171543dc4d55886a4cef45e` |
| Base tree | `28b303e699ffdb9a5356c8ce65a08d733bb9599c` |
| Post-merge CI | Run `36705661808` — completed / success — `headSha` = base commit |

### Revision log

- `v1` — Initial authority slice from canonical Frames export corpus and ACSS icon framework.
- `v2` — Process correction: component corpus digest STOP recorded; component tree not current authority; 2XL aligned with C-07X; C-08B2 narrowed to admission + unresolved preservation only.

---

## 1. Accepted baseline

Preflight on 2026-09-30:

- `origin/main` = `0c6e4d87822544e16171543dc4d55886a4cef45e`
- `origin/main^{tree}` = `28b303e699ffdb9a5356c8ce65a08d733bb9599c`
- Worktree clean at branch creation
- GitHub Actions run `36705661808`: `status=completed`, `conclusion=success`, `headSha` matches base

No production code changes are in scope for C-08B1.

---

## 2. Private source identities

Digest algorithm (same as C-07X): for each authority tree, sort regular files by corpus-relative path; each record is `path<TAB>size<TAB>lowercase-sha256(file)<NL>`; tree digest is SHA-256 of the concatenated records.

| Authority | Records | Expected digest | Observed digest | Status |
| --- | ---: | --- | --- | --- |
| Frames export corpus `private_reference/frames/staging-2026-09/` (`Archive.tar.gz` excluded) | 34 | `074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e` | `074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e` | Match |
| Frames component corpus `private_reference/frames/frames-components/` | 43 | `630332dcedf3807064affcbe22cfed9d16859fdd771b815a8b06d4960774de9e` | `89c8de995ffb235b030dce10494c9f65a919c18c44b53bacea5475d92306c810` | **Mismatch** (count matches; content drift) |
| ACSS icon framework `private_reference/frames/acss-icons/` | 5 | `f196729484d67241ea3dc1ce066f24062a25677104907219d5660ba2654704f0` | `f196729484d67241ea3dc1ce066f24062a25677104907219d5660ba2654704f0` | Match |

**STOP condition (component corpus):** The task required STOP when the Frames component digest differed from the canonical C-07X contract. That condition triggered: observed `89c8de99…` ≠ accepted `630332dc…` (43 records in both). Continuing the export-corpus audit after STOP was a **process breach**. This revision does not re-pin the drifted tree.

**C-08B1 authority stack (current):**

```text
canonical 34-file Frames export corpus
  → primary Bricks icon serialization authority

canonical ACSS icon corpus (5 files)
  → icon presentation / TokenSet authority (C-08A)

current private_reference/frames/frames-components tree
  → NOT accepted current authority (digest drift)
  → do not derive new behavior from 89c8de…
  → C-07X historical audit may be cited separately; it is not revalidated here
```

All icon occurrence counts, shapes S1/S2, and classification in this contract come from the **verified export corpus** only.

ACSS icon file hashes (unchanged from C-07X): `_vars.scss`, `_tokens.scss`, `_classes.scss`, `_mixins.scss`, `_cheatsheet.json` — see `docs/development/c07x_unsupported_surface_inventory.md`.

---

## 3. Corpus search methodology

Tools: `git`, `gh`, `find`, `rg`, `sed`, `sha256sum`, and a deterministic JSON walk script (read-only).

Search roots:

1. All `*.json` under `staging-2026-09/` (nine Bricks fragments + `environment/acss-settings.json`).
2. Patterns: `"name": "icon"`, `"name":"icon"`, `icon`, `svg`, `iconSvg`, `svgCode`, `library`, `fontawesome`, `themify`, `ionicons`, `material`, `data-icon`, `data-icon-size`, `data-icon-style`, `icon--`.

Classification rules:

- An **icon-bearing configuration** is any Bricks settings object with `library` + (`icon` string glyph **or** `svg` object **or** nested control keys such as `buttonIcon`, `prevArrow`).
- Element inventory uses Bricks element `id`, `name`, and `parent` from each fragment.
- Substantial string values are cited by SHA-256 only (no proprietary URLs or SVG bodies in this document).

Bricks version: fragments declare the Bricks 2.3.1 component format. Current local Bricks 2.4.2 source was **not** used as authority.

---

## 4. Icon occurrence inventory (export corpus)

### 4.1 Summary

| Metric | Count |
| --- | ---: |
| Bricks elements with `name: "icon"` | 42 |
| Additional element-bound icon settings (non-`icon` elements) | 12 |
| **Total icon-bearing element configurations** | **54** |
| JSON fragments with any icon-bearing configuration | 3 (`header-basel`, `pricing-section-echo`, `slider-section-basel`) |
| Inline SVG markup in exports | 0 |
| Distinct visual URL payload (hashed) | 1 |
| Distinct filesystem path payload (hashed) | 1 |
| Dynamic / expression-driven icon values | 0 |

Non-`icon` element bindings (still icon-bearing for adapter awareness, but not standalone `semantic_type: "icon"` nodes in C-08B2):

| Component | Element `name` | Element id | Setting key | Library | Static |
| --- | --- | --- | --- | --- | --- |
| header-basel | dropdown | `ce571d` | `icon` | svg | yes |
| header-basel | dropdown | `bb651a` | `icon` | svg | yes |
| header-basel | dropdown | `4865bd` | `icon` | svg | yes |
| header-basel | text-link | `7c0685` | `icon` | svg | yes |
| header-basel | header-basel-nav__trigger | `eInPP8eddsh` | `buttonIcon` / `buttonIconActive` | themify | yes |
| header-basel | fr-trigger | `0dad0f` | `buttonIcon` / `buttonIconActive` | themify | yes |
| slider-section-basel | fr-slider | `9d94c0` | `playButtonIcon` / `pauseButtonIcon` | themify | yes |
| slider-section-basel | fr-slider | `9d94c0` | `prevArrow` / `nextArrow` | svg | yes |

Global class records in `header-basel` mirror `buttonIcon` / `buttonIconActive` themify glyphs (four settings on one global class). These are styling defaults for triggers, not additional standalone icon elements.

### 4.2 Bricks `icon` elements (42)

All 42 share the same settings shape: `settings.icon.library = "svg"` and `settings.icon.svg` object keys `{full, isPlaceholder, path, url}`.

| Component | Count | Parent element names | `isPlaceholder` | URL hash (full/url) | Path hash |
| --- | ---: | --- | --- | --- | --- |
| pricing-section-echo | 40 | `block` | `true` (all) | `2fa7f5b3fadaf5cf…` | `90b85b0124baa43e…` |
| header-basel | 2 | `div` | `true` (all) | same | same |

Representative element ids (pricing): `189f89`, `10ea1b`, `1d4eec`, `60fff1`, `385374`, `f9a96c`, `a4d2fc`, `0dc89a`, `22427f`, `a709eb`, `1df711`, `bd0227`, `172b05`, `cf9050`, `8b77a5`, `40fa09`, `b517fc`, `be350d`, `0f20c5`, `901e9f`, `fc0a59`, `06ccab`, `9399a5`, `4c040c`, `eb6f96`, `29b7ab`, `50832d`, `4ca963`, `55d622`, `c8c7c2`, `c73d56`, `7bedf7`, `d0506e`, `6e4c97`, `2267f9`, `c89aba`, `cc295f`, `932b1a`, `2b04dd`, `203501`. Header ids: `63d007`, `eb1f02`.

Evidence facts (no raw values):

- `url` values are `http://…` development host URLs, not markup.
- `path` values are absolute host filesystem paths ending in `.svg` under `wp-content`.
- `full` duplicates `url` (same hash).
- No `.svg` assets ship inside the 34-record export tree (PNGs only for captures).

### 4.3 Other fragments

`rg` matched `icon` in `acss-settings.json` and some fragments for unrelated keys (e.g. ACSS option names). No Bricks icon configurations appear outside the three components above.

---

## 5. Distinct source shapes

| Shape ID | Description | Occurrences | Components | Static | Visual bytes in export | External dependency | Standalone reconstruction today |
| --- | --- | ---: | --- | --- | --- | --- | --- |
| **S1** `bricks.icon.library.svg.asset_ref` | `settings.icon` or arrow settings with `library: "svg"` and `svg: {full,url,path,isPlaceholder}` | 48 | header-basel, pricing-section-echo, slider-section-basel | yes | **No** (HTTP URL + path reference only; `isPlaceholder: true`) | Bricks/theme media path + dev host URL | **No** |
| **S2** `bricks.control.library.themify.glyph` | Control settings (`buttonIcon`, `playButtonIcon`, …) with `library: "themify"` and `icon: "ti-…"` class token | 6 (+4 globalClass mirrors) | header-basel, slider-section-basel | yes | **No** (glyph name only) | Themify icon font (not owned by LiveFrames) | **No** |

**Not observed** in the export corpus (no occurrences, do not design C-08B2 around them yet):

- Inline SVG strings in JSON
- `iconSvg` / `svgCode` keys
- Font Awesome / Ionicons / Material library selectors in Bricks icon settings
- Image-backed icons
- Unicode literal glyphs
- Dynamic Bricks dynamic-data icon fields

---

## 6. Security / resolution classification

| Shape ID | Resolution class | Rationale |
| --- | --- | --- |
| S1 | `EVIDENCE_INSUFFICIENT` | Serialized export does not include SVG geometry or embeddable safe markup; placeholders point off-corpus. Cannot specify a narrow sanitizer input or validate paths without an asset authority layer. |
| S2 | `UNRESOLVED_EXTERNAL_DEPENDENCY` | Rendering requires Themify (or equivalent) font/CSS not present in LiveFrames and not redistributable from this slice. |

Counts:

| Class | Count |
| --- | ---: |
| `SAFE_STATIC_CANDIDATE` | 0 |
| `UNRESOLVED_EXTERNAL_DEPENDENCY` | 1 shape (6 element settings + 4 globalClass mirrors) |
| `UNRESOLVED_DYNAMIC` | 0 |
| `UNSUPPORTED_UNSAFE` | 0 |
| `EVIDENCE_INSUFFICIENT` | 1 shape (48 settings) |

---

## 7. Current LiveFrames capability boundary

| Layer | Icon support today |
| --- | --- |
| Design IR `DesignNode.semantic_type` | `"icon"` is a valid semantic type string |
| `DesignIRNormalizer` | `"icon"` **not** in `@supported_element_names`; maps to unsupported |
| Stage A | Treats Bricks `icon` as unsupported |
| Fidelity | No `semantic_type: "icon"` branch; falls through to `div` |
| `StaticMarkupContract` | No `svg`, `i`, `path`; `data-icon-list` reserved for runtime |
| ACSS TokenSet (C-08A) | 24 `icon.*` paths; 20 resolved / 4 unresolved in fixture contract |

Icons are a semantic type without a source admission path or trusted renderer.

---

## 8. Proposed source-independent IR representation (Design IR 1.0.0, no schema bump)

### 8.1 Semantic node

- Bricks elements with `name: "icon"` normalize to `semantic_type: "icon"`.
- Control-embedded icons (`buttonIcon`, arrows, dropdown adornments) **do not** become `icon` nodes in C-08B2; they remain on the owning widget/button semantic node with raw settings preserved in `SourceTrace` until Frames component slices own them.

### 8.2 Visual identity — `content` + `asset_refs` (both)

| Concern | Location | Why |
| --- | --- | --- |
| Source classification | `content` map (JSON-safe) | Stable, queryable fields without expanding IR schema |
| Visual resource | `asset_refs` → `AssetReference` | Same pattern as images: optional `uri`, `status`, `metadata` |
| Lossless Bricks payload | `source_trace` | Full settings subtree for audit and future reclassification |

Proposed `content` shape (versioned **inside** the map, not IR root):

```json
{
  "icon_contract_version": "1",
  "source_shape": "bricks.icon.library.svg.asset_ref",
  "library": "svg",
  "embedding": "bricks_icon_element",
  "is_placeholder": true,
  "glyph": null
}
```

For S2 (if ever promoted from a control slice):

```json
{
  "icon_contract_version": "1",
  "source_shape": "bricks.control.library.themify.glyph",
  "library": "themify",
  "embedding": "frames_control_setting",
  "glyph_class_token_hash": "<sha256>"
}
```

`AssetReference` for S1:

- `kind`: `"icon"`
- `status`: `:unresolved` until bytes are owned
- `uri`: omitted in C-08B2 (export URLs are dev-host-specific and not authority)
- `metadata`: `{ "url_hash", "path_hash", "is_placeholder", "library" }` — hashes only in serialized IR exports intended for logs; contract allows redaction

**Design IR version change required:** **no** — uses existing `content`, `asset_refs`, and `SourceTrace`.

### 8.3 Lifecycle / resolution states

Pipeline states (documentation only):

1. `source_seen` — Bricks `icon` element parsed
2. `classified` — mapped to S1 or S2
3. `preserved` — `content` + `source_trace` written
4. Terminal:
   - `safely_resolvable` — none in current corpus
   - `unresolved_external_dependency` — S2
   - `unresolved_dynamic` — (unused)
   - `unsupported_unsafe` — (unused)
   - `evidence_insufficient` — S1 until asset bytes or inline SVG authority exists

---

## 9. Future safe SVG contract (design only — not implemented)

**Corpus finding:** No inline SVG markup appears in any export field. S1 stores HTTP URLs and filesystem paths only. Therefore **no SVG element or attribute allowlist is activated by current evidence.**

When a future corpus proves inline SVG in a Bricks-controlled field (typically `svg.full` or equivalent **markup** field, not a URL):

1. Rendering must use a **dedicated trusted icon renderer**, not `StaticMarkupContract` native tag admission for source HTML.
2. Re-derive allowlisted elements from that corpus. Provisional upper bound for Bricks-style monochrome icons ( **hypothesis until evidenced** ): `svg`, `g`, `path`, `circle`, `rect`, `line`, `polyline`, `polygon`, `ellipse`.
3. Provisional attribute candidates to evaluate against real markup: `viewBox`, `d`, `cx`, `cy`, `r`, `rx`, `ry`, `x`, `y`, `x1`, `x2`, `y1`, `y2`, `points`, `fill`, `stroke`, `stroke-width`, `stroke-linecap`, `stroke-linejoin`, `fill-rule`, `clip-rule`.
4. Hard rejects regardless: `script`, `foreignObject`, event-handler attributes, `href` / `xlink:href` to external resources, `javascript:`, external URLs in `xlink:href`, `<style>` blocks, embedded HTML, `use` pointing off-document, arbitrary `url(#…)` unless separately validated.

C-08B2 must not widen generic source tag allowlists.

---

## 10. External icon library findings

| Library | Evidence | LiveFrames ownership | Redistribution | Class |
| --- | --- | --- | --- | --- |
| Themify (`ti-*` tokens) | 6 control settings + 4 globalClass mirrors | None | Not established | `UNRESOLVED_EXTERNAL_DEPENDENCY` |
| Bricks `library: "svg"` | 48 settings | N/A (asset ref) | Placeholder/theme SVG not in corpus | `EVIDENCE_INSUFFICIENT` |

**Historical context only (C-07X, not re-derived from the drifted component tree):** The prior C-07X inventory recorded that Frames widgets expose Bricks icon controls and call site patterns such as `render_icon()` in component PHP. That finding is **not** independent authority for C-08B1 and must not be updated from the current `89c8de…` tree. Widget-embedded icons (S2) remain **out of scope** for C-08B2 admission.

---

## 11. ACSS styling relationship (C-08A)

ACSS icon framework (`acss-icons`, digest verified) controls **presentation**, not glyph identity:

- Tokens: `icon.size.*`, `icon.padding.*`, `icon.color*`, `icon.background*`, `icon.border.*`, `icon.radius`, `icon.scheme`, `icon.list.*`
- Fixture contract: **24** paths, **20** resolved, **4** unresolved (`icon.border.color`, `icon.border.style`, `icon.border.width`, `icon.color`)

Pipeline rule:

```text
Bricks icon source → icon semantic node / unresolved asset
ACSS TokenSet → presentation variables
Fidelity (C-08B3) → combine only when both sides are independently proven
```

Do not conflate `icon.size.m` with glyph geometry.

---

## 12. `data-icon-list` ownership conflict

| Owner | Claim |
| --- | --- |
| LiveFrames `StaticMarkupContract` | `data-icon-list` is runtime-reserved |
| ACSS (`_classes.scss`) | `data-icon-list` and `.icon-list` are static list-layout semantics |

C-08B1 does **not** resolve this. A future deliberate policy change must choose: extend static allowlist + Fidelity emission, rename runtime attribute, or dual-write compatibility.

---

## 13. C-08B3 utility / attribute future contract (record only)

| ACSS semantic | Notes |
| --- | --- |
| `data-icon` (`$icon-data-attribute`) | Presentation hook on `svg` / `i` in ACSS selectors |
| `data-icon-size` / `.icon--xs` … `.icon--xl` | Size presentation |
| `data-icon-style` / `.icon--boxed` / `.icon--plain` | Boxed vs plain |
| `data-icon-list` / `.icon-list` | List layout; conflicts with runtime reservation |
| `.icon--2xl` / `[data-icon-size="2xl"]` | **Selector proven** in effective generated CSS (C-07X). **`--icon-size-2xl` and `--icon-padding-2xl` are not proven** in the audited generated variable output; reason for absence remains unresolved. LiveFrames must **not** fabricate `icon.size.2xl` or `icon.padding.2xl` without new authority. |

---

## 14. Unresolved / evidence-gap register

| ID | Gap | Impact |
| --- | --- | --- |
| G1 | Export corpus has zero inline SVG bytes | Cannot freeze element-level SVG sanitizer from this slice |
| G2 | All S1 records are `isPlaceholder: true` with dev URLs | Asset pipeline must precede `safely_resolvable` |
| G3 | Component corpus digest drift vs C-07X canonical (`89c8de…` ≠ `630332dc…`) | Current `frames-components` tree is **not** authority; re-pin requires a separate provenance decision — not in C-08B1 |
| G4 | Bricks 2.4.2 vs 2.3.1 export format | Exports pin 2.3.1; unpinned implementation must not override |
| G5 | `data-icon-list` ownership | Blocks ACSS-faithful list styling until policy merge |
| G6 | No `SAFE_STATIC_CANDIDATE` shapes | C-08B2 is admission + unresolved preservation only; no renderer until icon asset authority |

---

## 15. Matrices

### Source shape matrix

| Source shape | Occurrences | Static | Visual bytes present | External dependency | IR representation | Resolution class | Future renderer |
| --- | ---: | --- | --- | --- | --- | --- | --- |
| S1 `bricks.icon.library.svg.asset_ref` | 48 | yes | no | Bricks/media path | `content` + unresolved `asset_refs` | `EVIDENCE_INSUFFICIENT` | Dedicated icon renderer after asset or inline SVG authority |
| S2 `bricks.control.library.themify.glyph` | 6 (+4 GC) | yes | no | Themify font | Preserve on owner node / trace only in B2 | `UNRESOLVED_EXTERNAL_DEPENDENCY` | Out of C-08B2; component or font asset slice |

### ACSS semantic matrix

| ACSS semantic | Source admission needed | IR needed | Safe renderer needed | Fidelity needed | Current status |
| --- | --- | --- | --- | --- | --- |
| `icon.size.*` / padding / radius | no (tokens) | no | no | yes (C-08B3) | Tokens resolved (C-08A) |
| `icon.color*` / `icon.background*` | no | no | no | yes | Partially unresolved literals in fixture |
| `icon.border.*` | no | no | no | yes | 4 paths unresolved in fixture |
| `icon.list.*` | no | no | no | yes | Tokens resolved |
| `data-icon` / `data-icon-size` / `data-icon-style` | yes (on rendered icon markup) | icon node | yes | yes | Not emitted |
| `.icon--*` utilities | via classes on icon wrapper | icon node | yes | yes | Not emitted |
| `data-icon-list` / `.icon-list` | policy conflict | list container | yes | yes | Blocked by runtime reservation |

---

## 16. Proposed C-08B2 scope (implementation slice)

**Goal:** Admit Bricks `icon` elements into Design IR and preserve unresolved icon resources. **No visual glyph rendering.**

C-08B2 is **admission + unresolved preservation only**:

1. Add `"icon"` to Bricks adapter supported elements; map to `semantic_type: "icon"`.
2. Classify admitted `icon` elements; for the canonical export corpus, all are **S1** (`bricks.icon.library.svg.asset_ref`).
3. Populate proposed `content` + `AssetReference` with `kind: "icon"`, `status: :unresolved`, **no trusted `uri`** (development-host URLs and export paths are not authority).
4. Emit an **explicit** unresolved / evidence-insufficient diagnostic (do not imply visual fidelity).
5. **Do not** fetch export URLs or paths, emit SVG, implement Themify, or add `svg`, `path`, `i`, `use`, `symbol` to `StaticMarkupContract.@native_tags`.
6. **Do not** introduce a dedicated Fidelity icon renderer hook or other abstraction whose only behavior would be “render nothing.”
7. Tests: normalizer admission, IR preservation, diagnostic presence; **no** golden SVG or glyph output.

**Canonical corpus outcome:** `safely_resolvable` count = **0**. No asset URI from exports may be trusted.

### Temporary Fidelity behavior (C-08B2)

Until owned/proven icon bytes exist:

- `semantic_type: "icon"` → **no glyph output** (not icon rendering).
- Unresolved icon resource → diagnostic + preserved evidence in IR.
- If the existing generic structural path still yields an empty `<div>` for `icon` nodes, document that as a **temporary non-visual structural fallback** only. Do not add a new Fidelity renderer merely to produce the same empty result. Do not claim visual icon support.

Control-embedded icons (S2) remain on owning nodes; not admitted as standalone `icon` nodes in C-08B2.

---

## 17. Post–C-08B2 dependency chain (not in PR #107)

```text
C-08B2
  icon admission + unresolved preservation

        ↓

C-08B2A (icon asset authority slice)
  prove/own actual SVG bytes or another static renderable resource
  decide: byte provenance, ownership/licensing, deterministic asset identity,
          safe validation/sanitization, repository/runtime packaging

        ↓

protected icon renderer
  only for safely_resolvable resources
  (dedicated trusted output — not generic source SVG allowlisting)

        ↓

C-08B3
  ACSS icon presentation Fidelity (TokenSet from C-08A)
```

The asset-authority slice answers **where geometry comes from**; C-08B1 established that exports currently supply **references**, not bytes.

---

## 18. Proposed C-08B3 scope (Fidelity / ACSS styling)

Separate from glyph resolution:

1. `AutomaticCSS.FidelityResolver` — `semantic_type: "icon"` declaration mapping from C-08A `TokenSet` only.
2. Map boxed/plain, sizes, hover variables, and class/attribute hooks (`data-icon`, `data-icon-size`, `data-icon-style`) onto **wrapper** markup around the trusted icon output.
3. List styling (`icon-list`, `data-icon-list`) only after G5 ownership resolution.
4. Static path: DB 0, Redis 0, GenServer 0, LiveView 0, runtime ACSS 0.

---

## 19. Non-goals (C-08B1)

- SVG, `<i>`, or font rendering implementation
- Widening generic markup allowlists
- Frames widget / `buttonIcon` behavior
- Downloading icon packs or Themify assets
- Design IR version bump
- Modifying `private_reference` or committing proprietary blobs
- Merging or claiming visual parity for icons

---

## 20. Performance

Icons are static presentation primitives. Target steady-state for standalone icons: no server state, no runtime Bricks/ACSS, no polling. Interactive components may own behavior; icons remain presentational children.

---

## 21. Generic SVG allowlist

**Generic SVG allowlist change required:** **no** (must remain no).

---

*End of C-08B1 contract.*
