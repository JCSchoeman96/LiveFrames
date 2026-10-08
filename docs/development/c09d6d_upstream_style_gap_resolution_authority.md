# C09D6-D0R1 — Upstream native styling gap-resolution authority

**Plan ID:** `c09d6-d0r1-upstream-style-gap-authority`

**Plan version:** `v3`

**Status:** `PENDING_ACCEPTED_MERGE` (candidate R1 authority in PR #140 — architecture only;
**not implemented**, **not verified**, **does not close D0**)

**Scope:** Freeze source-independent architecture for CTA Tango native-styling blockers
`G-GRID-STRUCT`, `G-TEXT-S`, `G-RADIUS-ACSS`, `G-GRID-GAP-CALC`, and `G-CUSTOM-CSS`.
No production code in this slice.

**Authority (pre-merge):** This document is the **candidate** contract for R2–R5 once
merged. It becomes active authority only after owner approval and merge to `main`.
Until then, **no R2 / D0R2A / R3 / R4 implementation is authorized by this document**.
After accepted merge, on conflict with historical D0 preflight architecture prose where
this file explicitly specifies gap resolution, **this file wins**.
Evidence remains authoritative for facts: `docs/evidence/c09d6_d0e1_acss_4_0_1_grid_authority.md`,
`docs/evidence/c09d6_d0e2_acss_4_0_1_text_scale_authority.md`.
D0 preflight matrix remains historical identification only:
`docs/development/c09d6d_cta_tango_style_coverage_preflight.md`.

**Repository base (R1):** `b58e9bc9b561c9367c27fd479323b6ea290fbea2` (tree
`661b1f8f5d0659cdf3276ffa4b38c27f3958ac70`)

**Last updated:** 2026-10-08

### Revision log

- `v1` — Initial R1 freeze after D0E1/D0E2 merge; downstream implementation not authorized.
- `v2` — Review corrections: Design IR 3.0.0 migration freeze, CCS direct-child targets,
  D0E PR attribution, serial implementation authorization, issue #129 text.
- `v3` — R3 vs C09D6-D1 boundary: upstream IR/mapping only in R3; frozen future D1 emission contract.

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
| D0E1 structural grid evidence | **COMPLETE / MERGED** — PR **#138**, merge `3b3b1f07a5362550642d2b7770494ecbb4710487` |
| D0E2 text-scale evidence | **COMPLETE / MERGED** — PR **#139**, merge `b58e9bc9b561c9367c27fd479323b6ea290fbea2` |
| D0R1 (this document) | **PENDING_ACCEPTED_MERGE** (PR #140); `authority_frozen` only after merge |
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
  → public --lf-radius-base (R3: mapping + theme availability only)
  → future C09D6-D1 (after R5): may emit component CSS using var(--lf-radius-base)
```

R3 does **not** generate component CSS or implement C09D6-D.

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

### Design IR version and migration (frozen in R1 — not delegated to D0R2A)

`docs/03_DESIGN_IR_SPEC.md` requires a new IR version when validation rules or serialized
shape change. Current contract is **2.0.0**; validation requires `:calculation` `value` to
be a non-empty **string**. Structured semantic calculations require **3.0.0**.

```text
CURRENT_DESIGN_IR_VERSION=2.0.0
STRUCTURED_CALCULATION_IR_VERSION=3.0.0

DESIGN_IR_SCHEMA_CHANGE_REQUIRED=YES
DESIGN_IR_VERSION_BUMP_REQUIRED=YES
DESIGN_IR_TARGET_VERSION=3.0.0
DEDICATED_SCHEMA_SLICE_REQUIRED=YES
DEDICATED_SCHEMA_SLICE_NAME=C09D6-D0R2A
```

#### 2.0.0 → 3.0.0 migration (structural, non-inferential)

```text
- Existing 2.0.0 StyleValue values are preserved exactly.
- Existing calculation strings remain calculation strings.
- No semantic token references are inferred from old calculation strings.
- ir_version becomes 3.0.0.
- Migration provenance is appended using the existing liveframes_ir_migrations model.
- frontend_semantics_recovered = false.
```

#### 1.0.0 input chain

```text
1.0.0 → existing 2.0.0 migration → 3.0.0 migration
```

Do **not** create a separate 1.0.0 → 3.0.0 interpretation path.

`Migration.to_current/1` obligations for D0R2A:

```text
1 → 2 → 3
2 → 3
3 → identity
```

#### 3.0.0 `StyleValue.kind = :calculation` value contract

`value` may be **either**:

1. a non-empty **string** — opaque/preserved calculations (legacy 2.0.0 behavior); or
2. a bounded **structured map** — approved semantic calculations only.

Introducing structured maps does **not** invalidate existing opaque calculation strings.

**First structured contract (frozen):**

```json
{
  "operation": "multiply",
  "operands": [
    {"kind": "token_ref", "path": "spacing.grid_gap"},
    {"kind": "literal", "value": 2}
  ]
}
```

**General validation (3.0.0):**

```text
operation:
  exactly "multiply" in this first version

operands:
  exactly two

operand 1:
  kind = "token_ref"
  path = non-empty validated semantic token path

operand 2:
  kind = "literal"
  value = finite JSON number
```

Constraints: no nested calculations; no arbitrary operators; no CSS variable strings
inside the structured value; no `--lf-*` names in Design IR. `source_expression` may
retain original source text for traceability only and is **never** semantic authority.

For CTA source normalization admitted in R3, operand 2 must additionally satisfy the
bounded Bricks source pattern `calc(var(--grid-gap) * <positive-rational-literal>)` with
factor `2` when rewriting from `calc(var(--grid-gap) * 2)`.

```text
G_GRID_GAP_SCHEMA_CHANGE_REQUIRED=YES
G_GRID_GAP_CALC_REPRESENTATION=StyleValue.calculation value = structured map (multiply token_ref × numeric literal) under IR 3.0.0
```

#### R3 ownership (upstream only)

```text
R3 owns:
- Bricks bounded source-pattern recognition
- source-independent structured calculation production
- spacing.grid_gap TokenSet reference inside structured calculation
- native_shared_v1 mapping metadata
- public --lf-space-grid-gap availability via TokenBridge/theme build
- no ACSS/source variable leakage in IR calculation value

R3 does NOT own:
- component CSS generation
- C09D6-D / C09D6-D1 implementation
- rendering structured calculation to final component CSS
- committed component stylesheet emission

R3_COMPONENT_CSS_GENERATION=NONE
R3_C09D6_D_IMPLEMENTATION=NONE
```

#### `FUTURE_C09D6_D_EMISSION_CONTRACT` (frozen now; implemented only when D1 authorized)

When C09D6-D1 is authorized (after R5), given:

```text
StyleValue.calculation {
  operation = multiply
  operands = [
    token_ref("spacing.grid_gap"),
    literal(2)
  ]
}

+ approved TokenBridge mapping:
  spacing.grid_gap → --lf-space-grid-gap
```

C09D6-D must deterministically emit:

```text
calc(var(--lf-space-grid-gap) * 2)
```

without reading `--grid-gap`, Automatic.css semantics, or `source_expression`.

```text
D1_EMISSION_CONTRACT_FROZEN=YES
D1_EXPECTED_GRID_GAP_CSS=calc(var(--lf-space-grid-gap) * 2)
D1_IMPLEMENTATION_AUTHORIZED=NO
```

#### `FUTURE_D1_TEST_OBLIGATION` (not executed until D1 authorized)

```text
Given the approved structured calculation and approved token mapping,
C09D6-D must deterministically emit:

calc(var(--lf-space-grid-gap) * 2)

without reading:
- --grid-gap
- Automatic.css semantics
- source_expression
```

R5 may verify upstream representation sufficiency for D0 coverage; R5 must **not**
implement C09D6-D1.

```text
R5_D1_IMPLEMENTATION=NONE
```

**C09D6-D0R2A** (after R2 merge, before R3): implement IR **3.0.0** version bump,
migrations, validation, serializer/loader alignment, and tests below. D0R2A does **not**
re-decide versioning, legacy string preservation, or migration shape — those are frozen here.
Do not implement D0R2A in PR #140.

### Implementation slices

```text
C09D6-D0R2A → Design IR 3.0.0 + structured semantic calculation contract + migrations
R3 → Bricks pattern rewrite + spacing.grid_gap structured IR + shared mapping (--lf-space-grid-gap)
```

### Tests required (R3)

```text
R3_GRID_GAP_IR_TESTS_FROZEN=YES
R3_SHARED_MAPPING_TEST_FROZEN=YES
```

1. `calc(var(--grid-gap) * 2)` → structured semantic calculation (IR 3.0.0).
2. Structured `value` contains `token_ref` `spacing.grid_gap` × numeric literal `2`.
3. No `--grid-gap` in semantic calculation `value`.
4. `spacing.grid_gap` present in approved `native_shared_v1` mapping as `--lf-space-grid-gap`.
5. Structured calculation survives serialization and validation under IR 3.0.0.
6. Unsupported source calculation shapes → fail closed / diagnostic (no guessing).
7. R3 produces **no** component CSS and starts **no** C09D6-D implementation (no temporary renderer).

Do **not** introduce a temporary CSS generator to assert future D output in R3.

### Tests required (D0R2A)

```text
DesignDocument.current_ir_version → 3.0.0
Migration.to_current: 1 → 2 → 3, 2 → 3, 3 → identity
StyleValue / validation / serializer / loader alignment
migration provenance tests
legacy calculation-string preservation (no inference)
structured calculation round-trip
invalid structured calculation rejection
```

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
`cIqHGvqlwpj`, owner element id **`0531fc`**). Direct children of `0531fc` in source
tree order (verified against private CTA Tango reference): **`1171e1`**, **`806d86`**,
**`fc5f68`** (wrapper `div` nodes). Child combinator selectors (`> *:…`) select those
**direct-child** DesignNodes only — not descendant `image` nodes.

```text
SOURCE_SELECTOR_TARGET_PRESERVED=YES
PROPERTY_RELOCATION_BY_HEURISTIC=NO
```

| Rule ID | Source selector pattern | Bounded operation | Bricks element id (target) | Normalized properties |
| --- | --- | --- | --- | --- |
| CCS-01 | owner block rule on `.image-group-tango` | owner `0531fc` | `0531fc` | `min-height: 675px` literal |
| CCS-02 | `> *:first-child` | direct child index 1 under `0531fc` | **`1171e1`** | `grid-column: 1 / -1`, `width: 90%` |
| CCS-03 | `> *:nth-child(2)` | direct child index 2 under `0531fc` | **`806d86`** | `width: 100%`, `aspect-ratio: 16/9` |
| CCS-04 | `> *:nth-child(3)` | direct child index 3 under `0531fc` | **`fc5f68`** | `width: 100%`, `aspect-ratio: 5/3.5` |

R4 resolves targets by Bricks children array under `0531fc` → `1171e1`, `806d86`,
`fc5f68`. **Do not** move `width` or `aspect-ratio` from these wrapper-selected rules
onto inner image nodes (`0a0447`, `b3b3c9`, etc.) based on node role heuristics. Per-image
`_aspectRatio` on image settings is a separate normalization path (D0 row CTA-D0-012);
CCS-03/04 remain wrapper-local until a separate bounded rule is proven in source.

```text
CCS_02_TARGET=1171e1
CCS_03_TARGET=806d86
CCS_04_TARGET=fc5f68
```

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

- Each CCS rule maps to expected DesignNode ids (`0531fc`, `1171e1`, `806d86`, `fc5f68`).
- Wrapper `806d86` vs `fc5f68` carry distinct `aspect-ratio` values from CCS-03/04.
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
| → `authority_frozen` | D0 row + upstream evidence + R1 merge | R1 doc merge | This file + D0E* | R2 authorized (serial chain §17) | `blocked_authority` |
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
D0R2A       Design IR 3.0.0 + structured semantic calculation (G-GRID-GAP-CALC)
R3          G-TEXT-S, G-RADIUS-ACSS, G-GRID-GAP-CALC implementation
R4          G-CUSTOM-CSS
R5          exact CTA Tango D0 rerun (no D1 generator)
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
| D0R2A | IR 3.0.0 bump, 1→2→3 / 2→3 migrations, legacy calc strings preserved, structured multiply validation |
| R3 | text-s overrides, 14/15 control, radius + grid_gap mapping, grid-gap structured IR + shared theme mapping (no component CSS) |
| R4 | CCS-01–04 node attachment, aspect ratio differentiation (no component CSS / no D) |
| R5 | Full CTA-D0 matrix rerun; only R5 updates preflight verdict; **no C09D6-D1 implementation** |

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

Serial integration only (fresh-`main` review between slices). No parallel/stacked path.

```text
R1 → R2 → C09D6-D0R2A → R3 → R4 → R5

R2_AUTHORIZED_AFTER_R1_MERGE=YES
D0R2A_AUTHORIZED_AFTER_R2_MERGE=YES
R3_AUTHORIZED_AFTER_D0R2A_MERGE=YES
R4_AUTHORIZED_AFTER_R3_MERGE=YES
R5_AUTHORIZED_AFTER_R4_MERGE=YES
PARALLEL_R4_AUTHORIZED=NO
```

| Slice | Authorized when |
| --- | --- |
| R2 | R1 merged to `main` |
| C09D6-D0R2A | R2 merged to `main` |
| R3 | D0R2A merged to `main` |
| R4 | R3 merged to `main` |
| R5 | R4 merged to `main` |
| C09D6-D1 | **NO** until R5 PASS |
| C09D7-A | **NO** until C09D6-D programme authorizes |

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

C09D6-D0R2A is required to introduce the versioned structured semantic
calculation contract (Design IR 3.0.0) before R3.

C09D6-D1 may begin only after R5 passes.
```

```text
ISSUE_129_STALE=YES
```
