# LiveFrames Fluid Sizing — Lead 4 Roadmap

**Repository:** `JCSchoeman96/LiveFrames`  
**Lane:** Lead 4 — Fluid Sizing / Responsive Design System  
**Status:** OWNER-APPROVED ROADMAP  
**Spec:** `docs/superpowers/specs/2026-10-22-liveframes-fluid-sizing-design.md`  
**Plan:** `docs/superpowers/plans/2026-10-22-liveframes-fluid-sizing.md`  
**Authority checkpoint:** `main=40d7c90865dbea1aa47e6c4e210949cc311a4ab2`  
**Decisions changed from Lead 4 bootstrap:** NO  

---

## Mission

Build a source-neutral Fluid sizing subsystem and prove it through real conversion work.

```text
source design system
→ TokenSet
→ Fluid semantics
→ deterministic CSS
→ native sections
→ coherent full pages
```

The lane is not complete merely because generated CSS contains `progress()`.

---

## Operating rules

1. Real conversion pressure drives scope.
2. No source-specific Fluid core.
3. Preserve historical ACSS/package bytes until explicit migration authority.
4. `FluidValue` and `FluidScale` remain distinct.
5. `progress()` is realization, not semantics.
6. FluidScale fallback preserves the coupled curve.
7. TokenSet remains source-neutral authority.
8. TokenBridge remains package materialization boundary.
9. No JavaScript/server runtime.
10. Phase gates stop for independent review.

---

## Compiler lifecycle

```text
raw
→ intrinsically_valid
→ reference_valid
→ resolved
→ materializable
→ serialized
```

Terminal rejection states:

```text
invalid_shape
invalid_reference
unresolved_dependency
unsupported_realization
fidelity_failure
```

No runtime persistence is implied.

---

# F0 — Authority installation

Install exact owner-approved:

```text
docs/superpowers/specs/2026-10-22-liveframes-fluid-sizing-design.md
docs/development/fluid_sizing_roadmap.md
docs/superpowers/plans/2026-10-22-liveframes-fluid-sizing.md
```

Freeze and verify SHA256 values.

Gate:

```text
F0=MERGED_ACCEPTED
```

No production code before F0.

---

# F1 — Semantic kernel

Introduce intrinsic closed V1 semantics:

```text
fluid_domain
fluid_value
fluid_scale
fluid_scale_step
```

V1:

```text
input=viewport_width
clamp=bounded
interpolation=linear
length units=px|rem
power=-4..4
```

Gate:

```text
F1=INTRINSIC_SEMANTICS_PROVEN
```

---

# F2 — TokenSet authority

Validate:

- exact references;
- target type;
- finite values;
- dimensions;
- V1 bounds;
- cycles via existing TokenSet graph authority.

Gate:

```text
F2=REFERENCE_AUTHORITY_PROVEN
```

STOP if TokenSet `1.0.0` cannot safely contain the semantics:

```text
STOP=TOKENSET_CONTRACT_CHANGE_REQUIRED
```

---

# F3 — Resolution kernel

Deterministic direct lookup:

```text
FluidValue → Domain
FluidScale → Domain
FluidScaleStep → Scale → Domain
```

No source-adapter knowledge.

Gate:

```text
F3=RESOLUTION_PROVEN
```

---

# F4 — FluidValue CSS

Modern:

```text
progress()
```

Compatibility:

```text
exact linear clamp or exact shared progress fallback
```

Reference-math tolerance:

```text
absolute error <= 1e-9
```

Browser computed-length tolerance:

```text
absolute error <= 0.01 CSS px
```

Gate:

```text
F4=FLUIDVALUE_SERIALIZATION_PROVEN
```

---

# F5 — FluidScale CSS

Implement:

```text
base(p) × ratio(p)^power
```

with one shared domain progress and one shared base/ratio pair per scale.

Modern progress:

```text
progress()
```

Compatibility progress:

```text
bounded tan(atan2()) realization
```

No endpoint-linearized clamp fallback.

Gate:

```text
F5=FLUIDSCALE_SERIALIZATION_PROVEN
NUMERICAL_EQUIVALENCE=PROVEN
```

---

# F6 — CSSValue / TokenBridge integration

Integrate through existing boundaries.

Preserve:

```text
CSSValue.candidate/1
TokenBridge.generate/2 bytes
native Hero mapping behavior
existing fluid_px_pair behavior
```

Add explicit progressive output.

Gate:

```text
F6=PACKAGE_MATERIALIZATION_PROVEN
```

---

# F7 — ACSS fidelity bridge

Prove current ACSS `fluidClamp` maps semantically to `FluidValue`.

Do not mutate historical ACSS token bytes.

Required samples:

```text
below
start
25%
50%
75%
end
above
```

Gate:

```text
F7=ACSS_FLUIDVALUE_FIDELITY_PROVEN
```

STOP on:

```text
STOP=ACSS_CURVE_FIDELITY_MISMATCH
STOP=ACSS_IDENTITY_DRIFT
```

---

# F8 — Native coordinated design scales

Create source-neutral proof data:

```text
1 shared FluidDomain

typography FluidScale
powers 0..4

spacing FluidScale
powers -2..3

1 descending FluidValue
```

Gate:

```text
F8=NATIVE_FLUID_SCALES_PROVEN
```

---

# F9 — Real Bricks + ACSS tracer

Use one real ordinary Bricks + ACSS section.

```text
source
→ TokenSet
→ Fluid semantics
→ package CSS
→ rendered native section
```

Lead 1 retains general converter ownership.

Gate:

```text
F9=BRICKS_ACSS_TRACER_PROVEN
```

---

# F10 — Real Frames tracer

Use one real Frames-derived component already moving through Lead 1 and with a proven fluid requirement.

Do not invent Fluid semantics.

Gate:

```text
F10=FRAMES_TRACER_PROVEN
```

---

# F11 — Page-scale proof

Lead 3 assembles a representative real page.

Verify:

- typography and spacing share intended interpolation boundaries;
- multiple component instances;
- no variable collisions;
- no duplicate Fluid system per instance;
- fallback and modern paths;
- browser zoom;
- desktop/mobile behavior.

Gate:

```text
F11=PAGE_TRACER_PROVEN
```

---

# F12 — Hardening and regression

Prove:

```text
deterministic ordering
deterministic numeric formatting
legacy package stability
ACSS stability
TokenSet stability
Hero/CTA stability
full repository CI
```

Gate:

```text
F12=HARDENED
```

---

# F13 — V1 acceptance

Required:

```text
FLUID_DOMAIN=PROVEN
FLUID_VALUE=PROVEN
FLUID_SCALE=PROVEN
FLUID_SCALE_STEP=PROVEN
PROGRESS_SERIALIZATION=PROVEN
COMPATIBILITY_SERIALIZATION=PROVEN
NUMERICAL_EQUIVALENCE=PROVEN
ACSS_FIDELITY=PROVEN
NATIVE_TYPOGRAPHY_SCALE=PROVEN
NATIVE_SPACING_SCALE=PROVEN
BRICKS_ACSS_TRACER=PROVEN
FRAMES_TRACER=PROVEN
PAGE_TRACER=PROVEN
DETERMINISM=PROVEN
REGRESSION=GREEN
```

Then prefer:

```text
LEAD4=RETIRED_TO_MAINTENANCE
```

unless a concrete real tracer requires new Fluid semantics.

---

## V1 non-goals

Not authorized:

```text
container domains
element-size domains
height domains
multi-stop interpolation
easing curves
fluid colors
fluid shadows
fluid transforms
motion systems
runtime JS sizing
server viewport state
arbitrary CSS ASTs
```

---

## Performance & scaling

```text
Redis=N/A
Postgres=N/A
ETS=N/A
Cachex=N/A
PubSub=N/A
Oban=N/A
PgBouncer=N/A
```

Expected compile-time complexity:

```text
O(domains + scales + fluid_tokens)
```

Use direct/indexed TokenSet lookup.

---

## Global STOP conditions

```text
STOP=SPEC_DRIFT
STOP=TOKENSET_CONTRACT_CHANGE_REQUIRED
STOP=HISTORICAL_IDENTITY_DRIFT_UNAUTHORIZED
STOP=ACSS_CURVE_FIDELITY_MISMATCH
STOP=FALLBACK_CURVE_MISMATCH
STOP=RAW_CSS_BECOMING_CANONICAL_DATA
STOP=SOURCE_SPECIFIC_FLUID_CORE
STOP=UNBOUNDED_SCALE_POWER
STOP=UNKNOWN_NUMERIC_DIMENSION
STOP=TOKENBRIDGE_LEGACY_BYTES_CHANGED
STOP=PAGE_OUTPUT_DUPLICATES_FLUID_SYSTEM_PER_COMPONENT
STOP=LEAD1_FLUID_FILE_OWNERSHIP_CONFLICT
STOP=V1_SCOPE_EXPANSION_WITHOUT_REAL_TRACER
```

---

## Success metric

> How reliably can LiveFrames preserve and create coherent fluid design systems across real converted sections and complete pages while keeping CSS formulas as output rather than architectural authority?

```text
FLUID_ROADMAP=OWNER_APPROVED
IMPLEMENTATION_AUTHORIZED=NO
```
