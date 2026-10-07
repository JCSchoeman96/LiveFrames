# C09D6-D0R1 — Upstream native styling gap-resolution authority

**Plan ID:** `c09d6-d0r1-upstream-style-gap-authority`

**Plan version:** `v1`

**Status:** active authority slice (architecture only — **not implemented**, **not verified**, **does not close D0**)

**Scope:** Freeze source-independent architecture for CTA Tango native-styling blockers
`G-GRID-STRUCT`, `G-TEXT-S`, `G-RADIUS-ACSS`, `G-GRID-GAP-CALC`, and `G-CUSTOM-CSS`.
No production code in this slice.

**Authority:** This document is the active contract for R2–R5 implementation prompts.
On conflict with historical preflight prose, this file wins for gap architecture after merge.
Evidence remains authoritative for facts: `docs/evidence/c09d6_d0e1_acss_4_0_1_grid_authority.md`,
`docs/evidence/c09d6_d0e2_acss_4_0_1_text_scale_authority.md`.
D0 preflight matrix remains historical identification only:
`docs/development/c09d6d_cta_tango_style_coverage_preflight.md`.

**Repository base (R1):** `b58e9bc9b561c9367c27fd479323b6ea290fbea2` (tree
`661b1f8f5d0659cdf3276ffa4b38c27f3958ac70`)

**Last updated:** 2026-10-07

### Revision log

- `v1` — Initial R1 freeze after D0E1/D0E2 merge; downstream implementation not authorized.

---

## 1. Purpose / scope

Freeze the smallest source-independent architecture so implementation agents (R2–R4)
have **no material architectural discretion** for the five G-* blockers identified in
C09D6-D0. Distinguish:

```text
authority frozen  != implemented
implemented       != verified
verified          != D0 closed
```

**In scope:** ownership, normalization boundaries, Design IR / TokenSet / public `--lf-*`
impact, implementation slices, tests, failure behavior, C09D6-D isolation.

**Out of scope:** C09D6-D1 generator implementation, C09D7-A, production Elixir/CSS,
D0 matrix edits, evidence republication, issue #129 mutation.

---

## 2. Authority inputs

| Input | Role |
| --- | --- |
| `docs/development/c09d6d_cta_tango_style_coverage_preflight.md` | Gap identification + CTA-D0 row IDs |
| `docs/development/c09d6_native_generation_authority.md` | C09D6-D styling split, §10.8–§10.9 |
| `docs/03_DESIGN_IR_SPEC.md` | `StyleValue` kinds |
| `docs/06_ACSS_TOKEN_ADAPTER.md` | TokenSet paths, `acss.clamp` derived recipes |
| `docs/07_BRICKS_ADAPTER.md` | Bricks normalization boundaries |
| `docs/11_CSS_AND_TAILWIND_STRATEGY.md` | Public `--lf-*` policy |
| `docs/20_P6_4A_NATIVE_STYLING_BRIDGE_ARCHITECTURE.md` | Token map = mapping metadata only |
| `docs/evidence/c09d6_d0e1_acss_4_0_1_grid_authority.md` | Proven `--grid-1`, `--grid-2`, `--grid-3-2` |
| `docs/evidence/c09d6_d0e2_acss_4_0_1_text_scale_authority.md` | Proven text-scale family + `text-s` overrides |

Do **not** rediscover D0E1 grid values or D0E2 text-scale semantics from proprietary source.

---

## 3. D0 / D0E1 / D0E2 status

| Slice | Status |
| --- | --- |
| C09D6-D0 preflight | **COMPLETE / BLOCKED** (`C09D6_D_STYLE_COVERAGE=BLOCKED`) |
| D0E1 structural grid evidence | **COMPLETE / MERGED** (PR #139 programme) |
| D0E2 text-scale evidence | **COMPLETE / MERGED** (PR #139 programme) |
| D0R1 (this document) | **authority frozen** when merged; not implementation |
| D0 rerun (R5) | **REQUIRED** after R2–R4; only R5 may advance gaps toward **closed** |

---

## 4. Gap taxonomy

| Gap ID | CTA-D0 rows | Layer |
| --- | --- | --- |
| G-GRID-STRUCT | 003, 006, 009 | Structural variable authority → Bricks IR literals |
| G-TEXT-S | 023 | TokenSet derived typography → Bricks `token_ref` |
| G-RADIUS-ACSS | 020 | TokenSet `radius.base` → theme mapping → IR / CSS |
| G-GRID-GAP-CALC | 004 | TokenSet `spacing.grid_gap` × factor → IR calculation |
| G-CUSTOM-CSS | 010–013 | Bounded Bricks `_cssCustom` → node-local IR styles |

---

## 5. G-GRID-STRUCT authority

### Source authority

`docs/evidence/c09d6_d0e1_acss_4_0_1_grid_authority.md` — do not re-infer:

```text
--grid-1   = repeat(1, minmax(0, 1fr))
--grid-2   = repeat(2, minmax(0, 1fr))
--grid-3-2 = minmax(0, 3fr) minmax(0, 2fr)
```

### Normalization owner

```text
LiveFrames.Adapters.AutomaticCSS.StructuralVariables
  → LiveFrames.Styles.StructuralVariableAuthority
  → LiveFrames.Adapters.Bricks.DesignIRNormalizer (resolve_direct_variable / structural)
  → LiveFrames.Adapters.Bricks.DependencyExtractor (declaration context)
```

Extend **`StructuralVariables`** only (not TokenSet theme tokens). Grid recipes are
**not** semantic TokenSet values merely because the source syntax is `var(--grid-*)`.

### Source-independent output

On successful resolution, `grid-template-columns` / `grid-template-rows` become
`StyleValue.literal` whose **value** is the proven track recipe string (e.g.
`minmax(0, 3fr) minmax(0, 2fr)`), with existing structural metadata
(`structural_resolved_value`, `structural_authority_id`, etc.). No `var(--grid-*)`
in normalized value or in native-generation inputs.

### Design IR impact

No new `StyleValue` kind. Reuse literal + structural metadata already defined in
Bricks normalization.

### TokenSet impact

**None** — do not add `layout.grid.*` TokenSet paths for these three recipes.

### Public `--lf-*` impact

```text
G_GRID_STRUCT_PUBLIC_LF_API=NONE
```

### Implementation slice

**R2** — structural grid normalization only.

### Tests required (R2)

- Exactly three authority records for enabled grid variables (`--grid-1`, `--grid-2`, `--grid-3-2`).
- Duplicate / ambiguous authority → fail closed (no literal emission).
- Grid variables disabled → variables unresolved / diagnostic per existing contract.
- Bricks normalization: CTA inner + image-group desktop/tablet columns resolve to literals.
- Native-generation fixture path: **no** `--grid-*` substrings in normalized IR values destined for D.

### Failure behavior

Fail closed on: unsupported ACSS version, malformed recipes, missing authority,
ambiguous candidates, invalid property pairing (`structural_value_invalid`).

### C09D6-D forbidden knowledge

`--grid-1`, `--grid-2`, `--grid-3-2`, Automatic.css, structural variable names.

D consumes **literal grid track recipes** only.

### Frozen fields

```text
G_GRID_STRUCT_NORMALIZATION_OWNER=LiveFrames.Adapters.AutomaticCSS.StructuralVariables
G_GRID_STRUCT_OUTPUT_REPRESENTATION=StyleValue.literal (source-independent grid track recipe) + structural authority metadata
G_GRID_STRUCT_PUBLIC_LF_API=NONE
G_GRID_STRUCT_SCHEMA_IMPACT=StructuralVariableAuthority record set extension only (no Design IR kind change)
```

---

## 6. G-TEXT-S authority

D0E2 removed evidence ambiguity. Architecture must model **default scale relationship**
and **independent optional endpoint overrides** before fluid interpolation.

### Source authority

`docs/evidence/c09d6_d0e2_acss_4_0_1_text_scale_authority.md`:

```text
text-s default power = -1
text-m default power = 0
text-l default power = +1
text-s-min=14, text-s-max=15 (active in verified CTA environment)
```

Invariant: **scale power -1 alone is wrong** for verified CTA Tango TokenSet resolution.

### Canonical TokenSet path

Repository convention: `typography.body.scale.medium` names the `text-m` step using a
**semantic size word**, not the ACSS suffix. Freeze:

```text
G_TEXT_S_TOKEN_PATH=typography.body.scale.small
```

### Override model

Adapter-owned derivation (AutomaticCSS normalizer + `FluidClamp` or adjacent resolver):

```text
default_mobile  = base-text-mob / mob-text-scale
default_desktop = base-text-desk / text-scale

effective_mobile  = text-s-min when setting present and valid
                    else default_mobile
effective_desktop = text-s-max when setting present and valid
                    else default_desktop

fluidClamp(effective_mobile, effective_desktop, vp-min, vp-max)
```

- Mobile and desktop overrides are **independent** (either, both, or neither).
- Use **explicit presence / validation** for override settings — never
  `override_min || calculated_min` truthiness.
- Valid numeric zero, if ever proven for overrides, must not be dropped.

### TokenSet contract

Retain **TokenSet root `1.0.0`** and recipe **`acss.clamp`** for the derived token.

```text
G_TEXT_S_TOKENSET_SCHEMA_CHANGE_REQUIRED=NO
G_TEXT_S_RECIPE_CHANGE_REQUIRED=YES
```

Extend the derived `inputs` map for `typography.body.scale.small` (conceptual shape):

| Input key | Source | Required |
| --- | --- | --- |
| `mobile_base`, `desktop_base`, `mobile_scale`, `desktop_scale` | same as `text-m` | yes |
| `viewport_min`, `viewport_max` | `vp-min`, `vp-max` | yes |
| `scale_power` | constant `-1` for this token | yes |
| `mobile_endpoint_override_px` | `text-s-min` | only when setting present |
| `desktop_endpoint_override_px` | `text-s-max` | only when setting present |

Resolver order: compute default endpoints from power **then** replace each endpoint
only when its override key is present and valid.

### Normalization owner

```text
LiveFrames.Adapters.AutomaticCSS.Normalizer (token definition)
LiveFrames.Adapters.AutomaticCSS.FluidClamp (or dedicated effective-endpoint helper)
LiveFrames.Adapters.Bricks.DesignIRNormalizer (var(--text-s) → token_ref)
```

### Source-independent output

- TokenSet: resolved derived value + deterministic CSS expression for CTA fixture.
- Design IR: `StyleValue.token_ref("typography.body.scale.small")` for `font-size` on
  accent heading (and any other `var(--text-s)` declarations normalized through token authority).

### Design IR impact

No new kind; `token_ref` to frozen path.

### Public `--lf-*` impact

R3 adds mapping entry (see §10): `--lf-typography-body-size-small` (or composed via shared map).

### Implementation slice

**R3** (shared token/value normalization).

### Tests required (R3)

Listed in programme prompt — including 14/15px fluid control for CTA fixture,
independent override cases, unchanged `text-m` / `text-l` behavior.

### Failure behavior

Invalid override → deterministic diagnostic / unresolved token per existing adapter strictness.

### C09D6-D isolation

```text
ACSS_TEXT_SCALE_OVERRIDE_KNOWLEDGE_REQUIRED_BY_D=NO
```

### Frozen summary

```text
G_TEXT_S_TOKEN_PATH=typography.body.scale.small
G_TEXT_S_DEFAULT_POWER=-1
G_TEXT_S_OVERRIDE_MODEL=independent optional mobile/desktop endpoint overrides with explicit presence; overrides applied before fluidClamp
G_TEXT_S_OUTPUT_REPRESENTATION=TokenSet acss.clamp derived token + Design IR token_ref
```

---

## 7. G-RADIUS-ACSS authority

### Source authority

TokenSet already owns **`radius.base`** (`docs/06_ACSS_TOKEN_ADAPTER.md`). Bricks maps
`var(--radius)` through existing token variable authority to that path.

### Path

```text
source var(--radius)
  → Bricks token authority (existing)
  → TokenSet radius.base
  → TokenBridge mapping metadata
  → public --lf-radius-base
  → C09D6-D emits component CSS using var(--lf-radius-base) or resolved equivalent
```

Do **not** create a second radius value authority.

### Frozen fields

```text
G_RADIUS_TOKEN_PATH=radius.base
G_RADIUS_PUBLIC_LF_API=--lf-radius-base
```

### Implementation slice

**R3** — mapping + any Bricks edge cases; no duplicate TokenSet token.

---

## 8. G-GRID-GAP-CALC authority

### Source evidence (not IR authority)

CTA Tango source: `calc(var(--grid-gap) * 2)` on inner container (CTA-D0-004).

Semantic value authority:

```text
G_GRID_GAP_TOKEN_PATH=spacing.grid_gap
```

### Required invariant

```text
ACSS_VARIABLE_KNOWLEDGE_REQUIRED_BY_D=NO
```

C09D6-D must not parse `--grid-gap` or rewrite calc strings containing source variables.

### Architectural decision

Today, Bricks preserves unknown calcs as `StyleValue.calculation` **string**
(`calc(var(--grid-gap) * 2)`), which leaks ACSS into IR and forces D to emit source
syntax. That violates §13 isolation.

**Freeze:** Bricks normalization (R3) must recognize the **bounded** source pattern:

```text
calc(var(--grid-gap) * <positive-rational-literal>)
```

when `--grid-gap` resolves to `spacing.grid_gap`, and emit a **source-independent**
structured calculation in Design IR.

### Representation (frozen contract)

Introduce a documented structured calculation payload carried by `StyleValue` kind
`:calculation` whose `value` is a **map** (not a CSS string):

```json
{
  "operation": "multiply",
  "operands": [
    {"kind": "token_ref", "path": "spacing.grid_gap"},
    {"kind": "literal", "value": 2}
  ]
}
```

Rules:

- `operation` initially only `multiply` (CTA Tango needs factor `2` only).
- Operand `token_ref.path` must be a validated TokenSet path.
- Operand `literal` must be a JSON number (not a string) for deterministic emission.
- `source_expression` may retain the original Bricks string for traceability only;
  **consumers for native generation must ignore** `source_expression` and use `value`.
- Do **not** manufacture `spacing.grid_gap.double`.
- Do **not** embed `calc(var(--lf-...)*…)` in IR.

C09D6-D emission (R3/R4 programme): resolve `token_ref` via approved mapping to
`var(--lf-space-grid-gap)` at CSS generation time →
`calc(var(--lf-space-grid-gap) * 2)` in committed component CSS only.

### Schema impact

`docs/03_DESIGN_IR_SPEC.md` currently describes `calculation` as a preserved CSS string;
`LiveFrames.IR.Validation` enforces non-empty string `value`. Both require amendment.

```text
G_GRID_GAP_SCHEMA_CHANGE_REQUIRED=YES
G_GRID_GAP_CALC_REPRESENTATION=StyleValue.calculation with structured map value (multiply token_ref × numeric literal)
DESIGN_IR_SCHEMA_CHANGE_REQUIRED=YES
DEDICATED_SCHEMA_SLICE_REQUIRED=YES
DEDICATED_SCHEMA_SLICE_NAME=C09D6-D0R2A
```

**C09D6-D0R2A** (before R3): authority + spec/validation alignment + tests for structured
calculation only. Do not bury this inside R3.

### Implementation slices

```text
C09D6-D0R2A → structured semantic calculation contract
R3 → Bricks pattern rewrite + TokenBridge spacing.grid_gap public variable + D emission rules
```

### Tests required

- `calc(var(--grid-gap) * 2)` → structured IR; no `--grid-gap` in `value`.
- Token ref survives serialization round-trip.
- D/CSS generator emits `calc(var(--lf-space-grid-gap) * 2)` with mapping from R3.
- Unrecognized calc shapes → unresolved/diagnostic (no guessing).

---

## 9. Token mapping strategy

`native_hero_v1.json` is Hero-oriented naming. Do not append global CTA semantics there.

### Frozen model

```text
TOKEN_MAPPING_STRATEGY=layered_compose
```

1. **`priv/token_maps/native_shared_v1.json`** (new in R3) — cross-component semantic
   paths: `typography.body.scale.small`, `radius.base`, `spacing.grid_gap`, and any
   other globals required by R3 gaps. Use neutral `native_shared_v1` naming.
2. **`priv/token_maps/native_hero_v1.json`** — Hero-specific display aliases unchanged
   in meaning; may reference shared paths indirectly where already composed.
3. **`Mix.Tasks.LiveFrames.Styling.Theme.Build`** — R3 extends to load **ordered**
   mapping layers (shared first, then component-specific overlays) with deterministic
   merge: reject duplicate `css_variable` keys across layers.

Invariants:

```text
TokenSet = semantic value authority
mapping JSON = mapping metadata only
lf_theme.css = deterministic function of TokenSet + ordered mapping layers
one value authority only
no source ACSS variables in native public API
no Hero-only naming for globally shared tokens
```

Hero output remains compatible: existing `--lf-*` variables keep names; shared layer
adds new variables only.

Public names frozen for R3 gaps:

| Token path | `--lf-*` |
| --- | --- |
| `typography.body.scale.small` | `--lf-typography-body-size-small` |
| `radius.base` | `--lf-radius-base` |
| `spacing.grid_gap` | `--lf-space-grid-gap` |

---

## 10. G-CUSTOM-CSS authority

Evidence path today: `Bricks _cssCustom` → `StyleValue.complex_css` (retention only).

### Required pipeline

```text
source _cssCustom (trace)
  → bounded Bricks adapter normalization (R4)
  → source-independent node-local styles
  → Design IR
  → C09D6-D mechanical CSS (package semantic selectors)
```

### Normalization owner

```text
G_CUSTOM_CSS_NORMALIZATION_OWNER=LiveFrames.Adapters.Bricks.DesignIRNormalizer
  (delegating to LiveFrames.Adapters.Bricks.BoundedCustomCssNormalizer)
```

### Supported CTA Tango subset (frozen)

All rules originate on global class **`image-group-tango`** (Bricks global class id
`cIqHGvqlwpj`, element id **`0531fc`**). Resolver prefers **stable Bricks element id**
over positional guessing when attaching styles.

| Rule ID | Source selector (evidence) | Bounded operation | Target | Normalized properties |
| --- | --- | --- | --- | --- |
| CCS-01 | `.image-group-tango { min-height: 675px }` | owner element `0531fc` | image-group DesignNode | `min-height: 675px` literal |
| CCS-02 | `.image-group-tango > *:first-child` | owner `0531fc`, **direct child index 1** (element `1171e1` wrapper) | that child DesignNode | `grid-column: 1 / -1`, `width: 90%` |
| CCS-03 | `.image-group-tango > *:nth-child(2)` | owner `0531fc`, **direct child index 2** (image `b3b3c9` via wrapper `806d86`) | second image DesignNode | `width: 100%`, `aspect-ratio: 16/9` |
| CCS-04 | `.image-group-tango > *:nth-child(3)` | owner `0531fc`, **direct child index 3** (third image subtree `fc5f68` chain) | third image DesignNode | `width: 100%`, `aspect-ratio: 5/3.5` |

R4 must resolve child indices using the Bricks children array under `0531fc`
(`1171e1`, `806d86`, `fc5f68`), attaching wrapper vs image per existing IR node roles
(image styles belong on **image** DesignNodes for aspect-ratio; span/width on wrapper
or image per row above).

### Output representation

```text
G_CUSTOM_CSS_OUTPUT_REPRESENTATION=ordinary node-local StyleValue maps (literal/keyword);
resolved rules removed from native-generation dependency on complex_css blob
```

Retain `complex_css` only when a rule is outside CCS-01–04 (diagnostic), per fail-closed policy.

### Design IR impact

No new kinds; redistribute declarations from `complex_css` to per-node `styles`.

### C09D6-D

Emits CSS from node roles + normalized properties only — **no** `.image-group-tango`,
**:nth-child**, or raw `_cssCustom` selectors.

### Forbidden

```text
ARBITRARY_SELECTOR_ENGINE_REQUIRED=NO
```

No generic cascade/specificity/browser matcher/runtime class resolver.

### Implementation slice

**R4** — bounded custom-CSS semantic normalization.

### Tests required (R4)

- Each CCS rule maps to expected DesignNode ids for CTA Tango fixture.
- Per-image aspect ratios differ (16/9 vs 5/3.5) on correct nodes.
- No `complex_css` required for CTA-D0-010–013 after normalization.
- Unsupported selector in same blob → diagnostic; no silent drop.

If a future tracer requires selectors outside this table → **STOP=G_CUSTOM_CSS_BOUNDARY_TOO_BROAD**
(new authority slice), do not expand engine in R4.

---

## 11. C09D6-D isolation boundary

### D must NOT know or parse

```text
--grid-*, --text-*, --grid-gap, text-s-min, text-s-max
ACSS selector syntax, ACSS utility classes, Bricks source class names
raw _cssCustom selectors, Automatic.css version rules
```

### D may consume

```text
literal grid track recipes
token_ref to TokenSet paths (resolved via mapping at generation time)
structured calculations (multiply token_ref × literal)
responsive overrides with BreakpointAuthority ids
ordinary per-node style maps
```

---

## 12. Gap lifecycle / state machine

States per G-*:

```text
identified → authority_frozen → implemented → verified → d0_retested → closed
```

Failure states: `blocked_authority`, `blocked_evidence`, `blocked_schema`, `blocked_scope`.

| Transition | Guard | Owner | Evidence | Side effect | On failure |
| --- | --- | --- | --- | --- | --- |
| → `authority_frozen` | D0 row + upstream evidence or R1 freeze | R1 doc merge | This file + D0E* | R2–R4 authorized to plan | `blocked_authority` |
| → `implemented` | Slice PR merged | R2/R3/R4 | Unit/integration tests | IR/TokenSet/code change | remain prior state |
| → `verified` | Slice tests + review | same | CI green on slice | — | `blocked_scope` |
| → `d0_retested` | R5 D0 rerun | R5 only | Updated preflight verdict | May unblock D1 planning | stay `verified` |
| → `closed` | R5 PASS + owner acceptance | R5 / owner | CTA-D0 matrix PROVEN rows | Gap removed from blocker set | — |

**Rules:** `implemented != closed`, `verified != closed`. Unit tests in R2–R4 do **not**
close gaps or D0.

Current gap states after R1 merge:

| Gap | State |
| --- | --- |
| G-GRID-STRUCT | `authority_frozen` |
| G-TEXT-S | `authority_frozen` |
| G-RADIUS-ACSS | `authority_frozen` |
| G-GRID-GAP-CALC | `authority_frozen` (schema slice D0R2A also frozen) |
| G-CUSTOM-CSS | `authority_frozen` |

```text
GAP_LIFECYCLE_FROZEN=PASS
```

---

## 13. Implementation slice dependency graph

```text
D0          COMPLETE / BLOCKED
D0E1        COMPLETE / MERGED
D0E2        COMPLETE / MERGED
R1          THIS SLICE (authority)
R2          G-GRID-STRUCT
D0R2A       structured semantic calculation (G-GRID-GAP-CALC IR contract)
R3          G-TEXT-S, G-RADIUS-ACSS, G-GRID-GAP-CALC implementation
R4          G-CUSTOM-CSS
R5          exact CTA Tango D0 rerun
PASS        → D1 planning may be authorized
BLOCKED     → return to smallest unresolved upstream slice
```

```text
IMPLEMENTATION_ORDER=R1 → R2 → C09D6-D0R2A → R3 → R4 → R5
```

---

## 14. Test obligations (summary)

| Slice | Obligation |
| --- | --- |
| R2 | Grid authority records, Bricks literals, no `--grid-*` in D inputs |
| D0R2A | Structured calculation validation, serialization, rejection of string-only contract for semantic multiply |
| R3 | text-s overrides, 14/15 control, radius + grid_gap mapping, grid-gap structured calc + theme vars |
| R4 | CCS-01–04 node attachment, aspect ratio differentiation |
| R5 | Full CTA-D0 matrix rerun; only R5 updates preflight verdict |

---

## 15. Complexity / performance review

Compile-time / build-time only:

```text
DB=N/A  Redis=N/A  ETS=N/A  GenServer=N/A  Oban=N/A  PubSub=N/A
request_time_generation=NONE
runtime_tailwind=NONE
source_runtime_dependency=NONE
```

Target: **O(nodes + styles + authority records)**. For G-CUSTOM-CSS, pre-index Bricks
element parent/child ids under owner `0531fc`; no document-wide selector backtracking.

---

## 16. Failure / STOP conditions

R1 STOP conditions (unchanged from programme). R1 did not trigger STOP.

If implementation discovers selectors beyond CCS-01–04 → `G_CUSTOM_CSS_BOUNDARY_TOO_BROAD`.

---

## 17. Downstream authorization

| Slice | Authorized after R1 merge? |
| --- | --- |
| R2 | YES (G-GRID-STRUCT) |
| C09D6-D0R2A | YES (schema contract before R3 grid-gap) |
| R3 | YES after D0R2A merge |
| R4 | YES (parallel after R3 only if no R3 dependency — **R4 may start after R2**; custom CSS does not depend on D0R2A) |
| R5 | YES after R2 + D0R2A + R3 + R4 complete |
| C09D6-D1 | **NO** until R5 PASS |
| C09D7-A | **NO** until C09D6-D programme authorizes |

Clarification: **R4** does not require R3, but **R5** requires all upstream gaps implemented.

```text
D0_RERUN_REQUIRED=YES
D1_AUTHORIZED=NO
C09D7_A_AUTHORIZED=NO
```

---

## 18. GitHub issue #129 (recommended dependency text — do not edit in R1)

Issue body still says `blocked by #128` — **stale**.

```text
Blocked by C09D6-D0 upstream styling closure.

Evidence gates D0E1 and D0E2 are complete.

Current dependency chain:
R1 → R2 → C09D6-D0R2A → R3 → R4 → R5.

If R1 requires a dedicated Design IR calculation-contract slice, that slice
must complete before R3.

C09D6-D1 may begin only after R5 passes.
```

```text
ISSUE_129_STALE=YES
```
