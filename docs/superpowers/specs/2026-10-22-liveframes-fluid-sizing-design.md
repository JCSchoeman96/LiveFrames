# LiveFrames Fluid Sizing System — Design Specification

**Repository:** `JCSchoeman96/LiveFrames`  
**Programme lane:** Lead 4 — Fluid Sizing / Responsive Design System  
**Design version:** `1.0.0`  
**Status:** OWNER-APPROVED DESIGN AUTHORITY  
**Implementation authorized:** NO  
**Authority checkpoint:** `main=40d7c90865dbea1aa47e6c4e210949cc311a4ab2`, tree `277f95f782469d47f3663c72d759b1a3c0445e92`  
**Decisions changed from Lead 4 bootstrap:** NO  

---

## 1. Executive decision

LiveFrames SHALL provide a source-neutral fluid sizing subsystem.

```text
source semantics
    ↓
TokenSet
    ↓
FluidDomain
FluidValue
FluidScale
FluidScaleStep
    ↓
CSS realization
```

These are explicitly distinct:

```text
SEMANTIC INTERPOLATION
≠
CSS REALIZATION
≠
COMPATIBILITY REALIZATION
```

`progress()` is the preferred modern CSS realization. It is not canonical semantic data.

`clamp()` remains an exact compatibility realization for linear `FluidValue` where appropriate.

A true `FluidScale` MUST preserve:

```text
base(p) × ratio(p)^power
```

and MUST NOT be approximated by independently clamping each final scale-step endpoint.

---

## 2. Ultimate goal

LiveFrames must be able to ingest, preserve, author, generate, and consume coherent responsive design systems across:

- Frames-derived sections;
- ordinary Bricks + Automatic.css sections;
- mixed Bricks / Frames / ACSS pages;
- LiveFrames-native design systems;
- complete Phoenix and Ash-powered pages.

Typography, spacing, section spacing, gaps, and compatible design dimensions should be able to share explicit fluid domains so page rhythm scales coherently.

Imported source behavior must retain fidelity. LiveFrames-native design systems may use richer coupled scales.

---

## 3. Existing architecture that remains authoritative

Fluid V1 extends rather than replaces:

- `LiveFrames.Tokens.TokenSet`
- `LiveFrames.Tokens.Token`
- `LiveFrames.Tokens.Validation`
- `LiveFrames.Tokens.CSSValue`
- `LiveFrames.Styling.TokenBridge`
- `LiveFrames.Adapters.AutomaticCSS.FluidClamp`
- package-owned `--lf-*` variables
- PhoenixStorybook / existing browser-evidence workflow.

Existing accepted ACSS and package output MUST NOT silently change.

`AutomaticCSS.FluidClamp` remains an adapter compatibility surface, not the generic Fluid architecture owner.

---

## 4. Selected architecture

Rejected:

1. extending `AutomaticCSS.FluidClamp` into the generic architecture;
2. storing generated `progress()` or `clamp()` strings as canonical token meaning.

Selected:

```text
source adapter
→ source-neutral TokenSet semantics
→ Fluid validation/resolution
→ deterministic CSS serializer
→ TokenBridge/package materialization
```

Recommended namespace:

```text
LiveFrames.Styling.Fluid
```

Recommended production files:

```text
apps/live_frames/lib/live_frames/styling/fluid/
  domain.ex
  value.ex
  scale.ex
  scale_step.ex
  validation.ex
  resolver.ex
  css_serializer.ex
```

No module under `LiveFrames.Styling.Fluid` may depend on ACSS, Bricks, Frames, Ash, persistence, or runtime server state.

---

## 5. Canonical semantic types

Persisted type names:

```text
fluid_domain
fluid_value
fluid_scale
fluid_scale_step
```

All V1 shapes are JSON-safe closed maps with:

```text
format_version = "1.0.0"
```

Unknown fields and unknown versions fail closed. All numbers MUST be finite.

### 5.1 FluidDomain

```text
type            = fluid_domain
format_version  = 1.0.0
input           = viewport_width
start           = {value: number, unit: px}
end             = {value: number, unit: px}
clamp_policy    = bounded
```

Invariants:

- `input == viewport_width`
- `clamp_policy == bounded`
- start/end use `px`
- `start.value < end.value`
- no references.

### 5.2 FluidValue

```text
type            = fluid_value
format_version  = 1.0.0
domain_ref      = canonical token path
start_value     = typed numeric value
end_value       = typed numeric value
interpolation   = linear
```

Supported dimensions:

```text
length
number
```

Supported length units:

```text
px
rem
```

Start may exceed end. References MUST equal `[domain_ref]`.

### 5.3 FluidScale

```text
type            = fluid_scale
format_version  = 1.0.0
domain_ref
base_start      = typed length
base_end        = compatible typed length
ratio_start     = positive finite number
ratio_end       = positive finite number
```

References MUST equal `[domain_ref]`.

At progress position `p`:

```text
base(p)  = linear(base_start, base_end, p)
ratio(p) = linear(ratio_start, ratio_end, p)
```

### 5.4 FluidScaleStep

```text
type            = fluid_scale_step
format_version  = 1.0.0
scale_ref
power           = integer -4..4
```

References MUST equal `[scale_ref]`.

Semantic result:

```text
base(p) × ratio(p)^power
```

---

## 6. Critical fidelity distinction

Current ACSS `fluidClamp` behavior is endpoint-first:

```text
mobile_endpoint  = mobile_base × mobile_ratio^n
desktop_endpoint = desktop_base × desktop_ratio^n
result(p) = linear(mobile_endpoint, desktop_endpoint, p)
```

That is a `FluidValue`.

A true `FluidScale` is:

```text
linear(mobile_base, desktop_base, p)
×
linear(mobile_ratio, desktop_ratio, p)^n
```

These are not generally equal between endpoints.

Therefore:

```text
ACSS fluidClamp → FluidValue
```

unless source evidence explicitly proves coupled base/ratio interpolation.

Never infer `FluidScale` merely because a source exposes mobile and desktop ratios.

---

## 7. TokenSet integration

Fluid semantics live inside the existing TokenSet graph as closed JSON-safe `resolved_value` maps.

Do not create a second registry or a generic `fluid` category. Use the token's real category, e.g. `layout`, `typography`, `spacing`, `radius`.

Example:

```text
layout.fluid.viewport.default
  category = layout
  resolved_value.type = fluid_domain

typography.scale.primary
  category = typography
  resolved_value.type = fluid_scale
  references = [layout.fluid.viewport.default]

typography.heading.h1
  category = typography
  resolved_value.type = fluid_scale_step
  references = [typography.scale.primary]
```

TokenSet remains `1.0.0` unless implementation proves that recognizing these JSON-safe variants changes the formal TokenSet contract.

If a version change appears required:

```text
STOP=TOKENSET_CONTRACT_CHANGE_REQUIRED
```

---

## 8. Exact reference authority

```text
fluid_domain
references = []

fluid_value
references = [domain_ref]
domain_ref must resolve to fluid_domain

fluid_scale
references = [domain_ref]
domain_ref must resolve to fluid_domain

fluid_scale_step
references = [scale_ref]
scale_ref must resolve to fluid_scale
```

Existing TokenSet cycle detection remains authoritative.

---

## 9. Compiler-domain lifecycle

Fluid artifacts are immutable compiler-domain values with no browser/session/server lifecycle.

```text
raw
→ intrinsically_valid
→ reference_valid
→ resolved
→ materializable
→ serialized
```

Transition guards:

### raw → intrinsically_valid

Requires:

- closed recognized shape;
- supported format version;
- supported units;
- finite numbers;
- valid domain ordering;
- positive scale ratios;
- bounded integer power;
- supported interpolation/input/clamp policy.

### intrinsically_valid → reference_valid

Requires:

- exact reference list;
- referenced paths exist;
- referenced token types match;
- no cycles.

### reference_valid → resolved

Requires:

- all dependencies resolved;
- compatible dimensions/units;
- no unresolved dependency.

### resolved → materializable

Requires:

- selected CSS target supports realization;
- compatibility policy is supported;
- no fidelity mismatch.

### materializable → serialized

Requires:

- safe deterministic CSS naming;
- deterministic numeric formatting;
- deterministic dependency ordering;
- existing declaration-safety policy passes.

Terminal rejection states:

```text
invalid_shape
invalid_reference
unresolved_dependency
unsupported_realization
fidelity_failure
```

Correction creates a new artifact. The serializer never repairs invalid input.

---

## 10. Semantic interpolation

For domain start/end:

```text
raw_p = (input - domain_start) / (domain_end - domain_start)
p = min(1, max(0, raw_p))
```

`FluidValue`:

```text
value(p)
=
start_value + (end_value - start_value) × p
```

`FluidScale`:

```text
base(p)
=
base_start + (base_end - base_start) × p

ratio(p)
=
ratio_start + (ratio_end - ratio_start) × p
```

`FluidScaleStep`:

```text
step(p)
=
base(p) × ratio(p)^power
```

These equations are semantic authority. CSS is an implementation.

---

## 11. Modern CSS realization

Preferred domain progress:

```css
progress(100vw, <domain-start>, <domain-end>)
```

For `FluidValue`:

```text
start + (end - start) × progress
```

For `FluidScale`:

```text
shared progress
→ shared fluid base
→ shared fluid ratio
→ base × pow(ratio, power)
```

Dependencies should be emitted once per used domain/scale, not per component instance.

Package-owned custom properties use `--lf-fluid-*`.

---

## 12. Compatibility realization

### FluidValue

The existing deterministic slope/intercept `clamp()` form remains semantically exact for one linear FluidValue.

### FluidScale

Endpoint-only clamp interpolation is forbidden.

Compatibility must preserve the same semantic progress and coupled scale curve.

Candidate V1 exact fallback progress:

```text
clamp(
  0,
  tan(
    atan2(
      current_dimension - domain_start,
      domain_end - domain_start
    )
  ),
  1
)
```

That progress feeds the same base/ratio/power relationships as the modern path.

Fallback math is serializer-private.

---

## 13. Numerical equivalence policy

"Exact compatibility" means semantic equivalence subject only to deterministic numeric/browser rounding.

### Pure reference-math tests

For unitless progress/ratio/scalar comparisons:

```text
absolute error <= 1e-9
```

### Browser computed length

After converting comparable lengths to CSS px using actual browser root font size:

```text
absolute error <= 0.01 CSS px
```

Required samples:

```text
below domain
domain start
25%
50%
75%
domain end
above domain
```

If any required sample exceeds the relevant threshold:

```text
state=fidelity_failure
STOP=FALLBACK_CURVE_MISMATCH
```

Do not widen tolerance without new authority.

---

## 14. Progressive enhancement

Preferred structure:

```text
fallback :root
  shared fallback progress
  shared scale calculations
  mapped values

@supports (...)
  :root
    override shared progress using progress()
```

Avoid duplicating the entire Fluid scale in both blocks when overriding shared progress is sufficient.

---

## 15. Breakpoint relationship

Fluid sizing and responsive breakpoints remain separate:

```text
FluidDomain = continuous interpolation
BreakpointAuthority = discrete responsive transition
```

Do not encode breakpoint behavior into FluidScale or continuous fluid behavior into BreakpointAuthority.

---

## 16. ACSS migration policy

Initial ACSS work is semantic projection/equivalence only.

Do not immediately rewrite historical ACSS TokenSet bytes.

First prove:

```text
existing FluidClamp curve
==
generic FluidValue semantic curve
```

at all required sample points.

Any persisted representation migration is a separate authority decision.

---

## 17. TokenBridge / CSSValue boundaries

`TokenBridge` remains package CSS materialization authority.

`generate/2` must preserve legacy bytes.

A new explicit progressive option may be added without altering `/2`.

Existing `fluid_px_pair` behavior remains until separately migrated.

`CSSValue` remains the candidate boundary. Fluid should extend it with TokenSet context where needed rather than bypassing it.

Existing CSS safety policy remains authoritative.

---

## 18. Shared domains

Many systems may reference one domain:

```text
layout.fluid.viewport.default
        ↓
typography scale
spacing scale
section spacing
gaps
```

Values sharing one domain begin/end interpolation together.

Multiple explicit domains are allowed when justified. Do not synthesize arbitrary domains from magic formulas.

---

## 19. Native examples

### Typography

```text
domain: 500px → 1000px
base:   1rem → 1.125rem
ratio:  1.2 → 1.414

body = 0
h4 = 1
h3 = 2
h2 = 3
h1 = 4
```

### Spacing

```text
shared domain
base: start → end
ratio: start → end

xs  = -2
s   = -1
m   = 0
l   = 1
xl  = 2
xxl = 3
```

---

## 20. Accessibility

Prefer relative units such as `rem` for LiveFrames-owned typography.

Viewport bounds may use `px`.

Imported source fidelity may require supported source units.

Do not silently rewrite source units for preference.

Browser proof includes zoom/text scaling.

---

## 21. Determinism

Identical validated semantics and output policy MUST produce identical CSS bytes.

Requirements:

- stable ordering;
- stable names;
- one deterministic float formatter;
- stable TokenSet serialization;
- no browser/runtime ordering input.

---

## 22. Performance and scaling

Fluid is build-time infrastructure:

```text
Redis=N/A
Postgres=N/A
ETS=N/A
Cachex=N/A
PubSub=N/A
Oban=N/A
PgBouncer=N/A
browser JS=N/A
```

Expected compiler complexity:

```text
O(domains + scales + fluid_tokens)
```

Use direct/indexed path lookup. No repeated whole-registry scan per step.

---

## 23. Security

Reject:

- NaN/infinity;
- arbitrary CSS fragments as semantic values;
- arbitrary functions;
- invalid references;
- unsupported units;
- unbounded exponents;
- unknown type/version/interpolation.

CSS strings are produced only by the serializer.

---

## 24. Required failure tests

Must include:

- domain start == end;
- domain start > end;
- missing/wrong domain;
- missing/wrong scale;
- cycle;
- unresolved dependency;
- NaN/infinity;
- ratio <= 0;
- unsupported unit;
- incompatible dimensions;
- power outside `-4..4`;
- unknown type/version/interpolation;
- ascending/descending/equal FluidValue;
- below/in/above-domain input;
- negative/zero/positive scale power;
- duplicate dependency emission;
- legacy byte drift.

---

## 25. Real-tracer requirements

V1 requires:

1. existing ACSS fluid typography;
2. existing ACSS fluid spacing;
3. native true typography FluidScale;
4. native true spacing FluidScale;
5. one ordinary Bricks + ACSS section;
6. one Frames-derived section;
7. one mixed/full-page consumer proof.

---

## 26. Browser verification

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

Verify:

- modern path;
- compatibility path;
- numerical equivalence;
- desktop/mobile;
- zoom;
- multiple instances;
- no duplicate Fluid system;
- no variable collisions.

Use existing PhoenixStorybook/browser evidence processes.

---

## 27. V1 non-goals

Not authorized:

- container/element/height domains;
- multi-stop interpolation;
- easing curves;
- fluid colors/shadows/transforms;
- motion;
- runtime JS sizing;
- server viewport detection;
- per-user sizing state;
- arbitrary CSS formula ASTs.

---

## 28. Ownership

### Lead 4

Fluid semantics, validation, resolution, serialization, compatibility math, TokenBridge integration, ACSS projection, Fluid tests/evidence.

### Lead 1

General Bricks/Frames normalization, CSS parsing/selectors/custom properties, componentization, NativeGenerator, section conversion.

### Lead 2

Behavior/runtime; normally independent.

### Lead 3

Page assembly, Phoenix/Ash consumer integration, page proof.

Avoid competing edits to Fluid integration surfaces while V1 is active.

---

## 29. Acceptance criteria

```text
FLUID_DOMAIN=PROVEN
FLUID_VALUE=PROVEN
FLUID_SCALE=PROVEN
FLUID_SCALE_STEP=PROVEN
PROGRESS_SERIALIZATION=PROVEN
COMPATIBILITY_SERIALIZATION=PROVEN
NUMERICAL_EQUIVALENCE=PROVEN
ACSS_FLUIDVALUE_FIDELITY=PROVEN
TYPOGRAPHY_SCALE=PROVEN
SPACING_SCALE=PROVEN
NORMAL_BRICKS_TRACER=PROVEN
FRAMES_TRACER=PROVEN
PAGE_TRACER=PROVEN
DETERMINISM=PROVEN
REGRESSION=GREEN
```

---

## 30. STOP conditions

```text
STOP=SPEC_NOT_ACCEPTED
STOP=TOKENSET_CONTRACT_CHANGE_REQUIRED
STOP=HISTORICAL_IDENTITY_DRIFT_UNAUTHORIZED
STOP=ACSS_CURVE_FIDELITY_MISMATCH
STOP=FALLBACK_CURVE_MISMATCH
STOP=RAW_CSS_BECOMING_CANONICAL_DATA
STOP=SOURCE_SPECIFIC_FLUID_LOGIC_REQUIRED
STOP=UNBOUNDED_SCALE_POWER
STOP=UNKNOWN_NUMERIC_DIMENSION
STOP=PAGE_OUTPUT_DUPLICATES_FLUID_SYSTEM_PER_COMPONENT
STOP=LEAD1_FLUID_FILE_OWNERSHIP_CONFLICT
STOP=V1_SCOPE_EXPANSION_WITHOUT_REAL_TRACER
```

---

## 31. Success definition

Fluid V1 succeeds when LiveFrames can preserve imported fluid semantics, author richer coordinated scales, and deterministically realize them across real sections and complete Phoenix/Ash pages without generated clamp arithmetic becoming architectural authority.

```text
FLUID_DESIGN_SPEC=OWNER_APPROVED
DECISIONS_CHANGED_FROM_BOOTSTRAP=NO
IMPLEMENTATION_AUTHORIZED=NO
```
