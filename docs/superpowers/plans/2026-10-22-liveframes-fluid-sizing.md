# LiveFrames Fluid Sizing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a source-neutral deterministic Fluid sizing subsystem supporting `FluidDomain`, `FluidValue`, `FluidScale`, and `FluidScaleStep`, with `progress()`-first CSS output, exact compatibility output, ACSS fidelity, and real section/page proof.

**Architecture:** Canonical Fluid semantics live under `LiveFrames.Styling.Fluid` and are persisted as closed JSON-safe resolved-value variants inside the existing TokenSet graph. TokenSet validates authority and references; Fluid resolves dependencies; `CSSValue` remains the candidate boundary; `TokenBridge` remains the package CSS materialization boundary. Existing ACSS and legacy package bytes remain unchanged until separately authorized migration.

**Tech Stack:** Elixir, ExUnit, existing TokenSet/TokenBridge, CSS math functions, PhoenixStorybook/existing browser verification.

**Spec:** `docs/superpowers/specs/2026-10-22-liveframes-fluid-sizing-design.md`  
**Roadmap:** `docs/development/fluid_sizing_roadmap.md`

---

## Global constraints

- Types: `fluid_domain`, `fluid_value`, `fluid_scale`, `fluid_scale_step`.
- Fluid format version: `1.0.0`.
- V1 input: `viewport_width`.
- V1 clamping: `bounded`.
- V1 interpolation: `linear`.
- V1 length units: `px`, `rem`.
- V1 `FluidScaleStep.power`: integer `-4..4`.
- All numbers finite.
- Ratios positive.
- `progress()` is output syntax, never canonical data.
- Existing `TokenBridge.generate/2` bytes MUST NOT change.
- Existing accepted ACSS TokenSet / `css_expression` bytes MUST NOT silently change.
- ACSS endpoint interpolation maps to `FluidValue`, not automatically to `FluidScale`.
- No JavaScript/server runtime.
- No ACSS/Bricks/Frames dependency inside generic Fluid code.
- TDD for production tasks.
- Coding agents never merge.

---

## Numerical equivalence requirements

Reference math:

```text
absolute error <= 1e-9
```

Browser computed lengths normalized to CSS px:

```text
absolute error <= 0.01 CSS px
```

Required sample positions:

```text
below domain
domain start
25%
50%
75%
domain end
above domain
```

Any mismatch above the applicable tolerance is:

```text
fidelity_failure
STOP=FALLBACK_CURVE_MISMATCH
```

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

---

## Review focus

1. Descending FluidValue remains valid.
2. Wrong reference type fails deterministically.
3. FluidScale fallback matches the coupled curve, not only endpoints.
4. Historical ACSS/TokenBridge bytes do not drift.
5. Shared domain/scale dependencies emit once.

---

# File map

## New production files

```text
apps/live_frames/lib/live_frames/styling/fluid/domain.ex
apps/live_frames/lib/live_frames/styling/fluid/value.ex
apps/live_frames/lib/live_frames/styling/fluid/scale.ex
apps/live_frames/lib/live_frames/styling/fluid/scale_step.ex
apps/live_frames/lib/live_frames/styling/fluid/validation.ex
apps/live_frames/lib/live_frames/styling/fluid/resolver.ex
apps/live_frames/lib/live_frames/styling/fluid/css_serializer.ex
```

## New tests

```text
apps/live_frames/test/live_frames/styling/fluid/domain_test.exs
apps/live_frames/test/live_frames/styling/fluid/value_test.exs
apps/live_frames/test/live_frames/styling/fluid/scale_test.exs
apps/live_frames/test/live_frames/styling/fluid/scale_step_test.exs
apps/live_frames/test/live_frames/styling/fluid/validation_test.exs
apps/live_frames/test/live_frames/styling/fluid/resolver_test.exs
apps/live_frames/test/live_frames/styling/fluid/css_serializer_test.exs
```

## Existing integration files expected to change

```text
apps/live_frames/lib/live_frames/tokens/validation.ex
apps/live_frames/lib/live_frames/tokens/css_value.ex
apps/live_frames/lib/live_frames/styling/token_bridge.ex
apps/live_frames/lib/live_frames/adapters/automatic_css/fluid_clamp.ex

apps/live_frames/test/live_frames/tokens/css_value_test.exs
apps/live_frames/test/live_frames/styling/token_bridge_test.exs
apps/live_frames/test/live_frames/automatic_css_adapter_test.exs
```

---

# Canonical shapes

## FluidDomain

```json
{
  "type": "fluid_domain",
  "format_version": "1.0.0",
  "input": "viewport_width",
  "start": {"value": 500, "unit": "px"},
  "end": {"value": 1000, "unit": "px"},
  "clamp_policy": "bounded"
}
```

References: `[]`.

## FluidValue

```json
{
  "type": "fluid_value",
  "format_version": "1.0.0",
  "domain_ref": "layout.fluid.viewport.default",
  "start_value": {"value": 1.0, "unit": "rem"},
  "end_value": {"value": 1.125, "unit": "rem"},
  "interpolation": "linear"
}
```

Start/end may instead be unitless finite numbers; dimensions must match.

References: `[domain_ref]`.

## FluidScale

```json
{
  "type": "fluid_scale",
  "format_version": "1.0.0",
  "domain_ref": "layout.fluid.viewport.default",
  "base_start": {"value": 1.0, "unit": "rem"},
  "base_end": {"value": 1.125, "unit": "rem"},
  "ratio_start": 1.2,
  "ratio_end": 1.414
}
```

References: `[domain_ref]`.

## FluidScaleStep

```json
{
  "type": "fluid_scale_step",
  "format_version": "1.0.0",
  "scale_ref": "typography.scale.primary",
  "power": 4
}
```

References: `[scale_ref]`.

---

# Task 0 — Install canonical authority

**Files:**
- Create `docs/superpowers/specs/2026-10-22-liveframes-fluid-sizing-design.md`
- Create `docs/development/fluid_sizing_roadmap.md`
- Create `docs/superpowers/plans/2026-10-22-liveframes-fluid-sizing.md`

**Consumes:** owner-approved exact bytes and SHA256 manifest.  
**Produces:** repository-local authority.

- [ ] Refresh `origin/main`; record SHA/tree.
- [ ] Verify no competing Fluid authority PR/files.
- [ ] Copy exact approved bytes without semantic edits.
- [ ] Verify local SHA256 values equal approved manifest.
- [ ] Run `git diff --check`.
- [ ] Commit signed docs-only change.
- [ ] Push/open docs-only PR.
- [ ] STOP.

No production code/tests in this PR.

---

# Task 1 — Intrinsic semantic validators

**Files:**
- Create the four semantic modules.
- Create four corresponding tests.

**Interfaces:**

```elixir
validate(term()) :: :ok | {:error, reason()}
type?(term()) :: boolean()
```

Reasons are deterministic closed tuples/atoms.

Steps:

- [ ] Write RED tests for valid shapes and every intrinsic invariant.
- [ ] Confirm RED.
- [ ] Implement minimal closed-map validation.
- [ ] Confirm GREEN.
- [ ] Run affected-app format/compile.
- [ ] Commit.
- [ ] STOP for review.

Required cases:

- missing/unknown fields;
- wrong type/version;
- non-finite values;
- domain start `>=` end;
- unsupported input/clamp policy;
- incompatible dimensions;
- ascending/descending/equal FluidValue endpoints;
- non-positive ratios;
- non-integer powers;
- `-5` and `5` rejected;
- `-4`, `0`, `4` accepted.

No TokenSet lookup or CSS yet.

---

# Task 2 — TokenSet Fluid authority

**Files:**
- Create `styling/fluid/validation.ex`
- Modify `tokens/validation.ex`
- Add focused tests.

**Interface:**

```elixir
LiveFrames.Styling.Fluid.Validation.validate_registry(tokens_by_path)
  :: [LiveFrames.Tokens.Diagnostic.t()]
```

Rules:

```text
domain: references=[]
value: references=[domain_ref], target=fluid_domain
scale: references=[domain_ref], target=fluid_domain
step: references=[scale_ref], target=fluid_scale
```

- [ ] RED tests for valid registry, missing/extra refs, wrong target type, deterministic diagnostics.
- [ ] Prove existing non-Fluid TokenSets still pass unchanged.
- [ ] Reuse existing cycle validation.
- [ ] Implement minimum integration.
- [ ] Run focused + existing TokenSet tests.
- [ ] Commit.
- [ ] STOP.

If version bump appears necessary:

```text
STOP=TOKENSET_CONTRACT_CHANGE_REQUIRED
```

---

# Task 3 — Deterministic resolver

**Files:**
- Create `styling/fluid/resolver.ex`
- Add resolver tests.

**Interface:**

```elixir
resolve(TokenSet.t(), String.t())
  :: {:ok, map()} | {:error, reason()}
```

Resolution:

```text
domain → itself
value → value + domain
scale → scale + domain
step → step + scale + domain
```

- [ ] RED tests.
- [ ] Use direct map lookup.
- [ ] Never mutate TokenSet.
- [ ] No source-adapter imports.
- [ ] GREEN.
- [ ] Commit.
- [ ] STOP.

---

# Task 4 — FluidValue CSS serializer

**Files:**
- Create `styling/fluid/css_serializer.ex`
- Add serializer tests.

**Interfaces:**

```elixir
legacy_value(TokenSet.t(), String.t())
  :: {:ok, String.t()} | {:error, reason()}

plan(TokenSet.t(), [String.t()])
  :: {:ok, map()} | {:error, reason()}
```

Plan contains deterministically sorted:

```text
fallback_dependencies
modern_overrides
values
```

- [ ] RED ascending/descending/constant tests.
- [ ] RED below/start/25/50/75/end/above tests.
- [ ] Implement modern `progress()`.
- [ ] Implement exact linear legacy expression.
- [ ] Add shared bounded fallback progress for progressive plan.
- [ ] Assert one domain dependency for multiple values.
- [ ] Assert stable formatting/order.
- [ ] GREEN.
- [ ] Commit.
- [ ] STOP.

---

# Task 5 — FluidScale CSS serializer

**Files:**
- Modify `css_serializer.ex`
- Extend serializer tests.

Per scale emit once:

```text
domain progress
scale base
scale ratio
```

Step:

```text
base × pow(ratio, power)
```

Fallback progress uses bounded trig realization preserving semantic progress.

- [ ] RED powers `-4`, `-1`, `0`, `1`, `4`.
- [ ] RED one-domain/two-scale deduplication.
- [ ] Build pure reference evaluator for tests only.
- [ ] Prove fallback/reference at required samples with `<=1e-9`.
- [ ] Assert endpoint-only clamp is absent for scale steps.
- [ ] GREEN.
- [ ] Commit.
- [ ] STOP.

Mismatch:

```text
STOP=FALLBACK_CURVE_MISMATCH
```

---

# Task 6 — TokenSet-aware CSSValue

**Files:**
- Modify `tokens/css_value.ex`
- Extend `tokens/css_value_test.exs`

Preserve:

```elixir
candidate(token)
```

Add:

```elixir
candidate(TokenSet.t(), Token.t(), keyword())
  :: {:ok, String.t()} | {:error, reason()}
```

Option:

```text
fluid_target=:legacy|:fallback|:modern
```

- [ ] Existing `/1` behavior unchanged.
- [ ] Add FluidValue contextual tests.
- [ ] Add FluidScaleStep contextual tests.
- [ ] Reject FluidScaleStep `:legacy` if it implies linearization.
- [ ] Non-Fluid contextual behavior matches `/1`.
- [ ] Do not duplicate CSS safety policy.
- [ ] Commit.
- [ ] STOP.

---

# Task 7 — TokenBridge progressive materialization

**Files:**
- Modify `styling/token_bridge.ex`
- Extend `styling/token_bridge_test.exs`

Preserve:

```elixir
generate(TokenSet.t(), mapping_or_layers)
```

Add:

```elixir
generate(TokenSet.t(), mapping_or_layers, keyword())
```

Option:

```text
fluid_output=:legacy|:progressive
```

`generate/2` remains legacy.

- [ ] Exact tests prove existing `/2` bytes unchanged.
- [ ] Existing `native_hero_v1.json` `fluid_px_pair` unchanged.
- [ ] Progressive FluidValue.
- [ ] Progressive FluidScaleStep.
- [ ] Deduplicate domain/scale dependencies.
- [ ] Mapping order independence.
- [ ] Existing unsafe CSS rejection remains.
- [ ] Commit.
- [ ] STOP.

If legacy bytes change:

```text
STOP=TOKENBRIDGE_LEGACY_BYTES_CHANGED
```

---

# Task 8 — ACSS semantic projection

**Files:**
- Modify `adapters/automatic_css/fluid_clamp.ex`
- Extend `automatic_css_adapter_test.exs`

Add:

```elixir
semantic_value(map())
  :: {:ok, map()} | {:error, reason()}
```

This projects `acss.clamp` into generic FluidValue semantics without changing Normalizer output.

- [ ] Use accepted spacing + typography fixtures.
- [ ] Prove endpoint equality.
- [ ] Prove 25/50/75% curve equality.
- [ ] Prove token `value`, `resolved_value`, `source_expression`, `metadata.css_expression` unchanged.
- [ ] Prove serialized TokenSet bytes unchanged.
- [ ] Never emit FluidScale merely because ACSS ratios exist.
- [ ] Commit.
- [ ] STOP.

Mismatch:

```text
STOP=ACSS_CURVE_FIDELITY_MISMATCH
```

---

# Task 9 — Native coordinated Fluid fixture

Add a dedicated TokenSet fixture:

```text
1 shared FluidDomain
typography FluidScale, powers 0..4
spacing FluidScale, powers -2..3
1 descending FluidValue
```

- [ ] TokenSet validates.
- [ ] Serialization deterministic.
- [ ] Progressive CSS deterministic.
- [ ] One fallback domain progress.
- [ ] One modern override.
- [ ] One base/ratio pair per scale.
- [ ] Stable repeated output.
- [ ] Commit.
- [ ] STOP.

---

# Task 10 — Full subsystem regression

Focused:

```text
Fluid
TokenSet validation
CSSValue
TokenBridge
AutomaticCSS adapter
```

Then:

```bash
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix assets.build
mix test
mix deps.unlock --check-unused
git diff --check
```

Explicit report:

```text
ACSS clamp tests=PASS
TokenBridge Hero mapping=PASS
TokenSet=PASS
package tests=PASS
full CI=PASS
```

No unrelated cleanup.

---

# Task 11 — Real Bricks + ACSS tracer

**Boundary:** Lead 4 Fluid + Lead 1 converter.

Select one real normal Bricks + ACSS section.

Prove:

```text
source identity
→ TokenSet
→ Fluid semantics
→ generated package CSS
→ rendered native component
```

If source behavior is endpoint interpolation, use FluidValue.

Do not invent FluidScale semantics or modify generic converter code merely to make Fluid pass.

STOP on source ambiguity.

---

# Task 12 — Real Frames-derived tracer

Select one real Frames component already in Lead 1's pipeline with a proven Fluid requirement.

Prove deterministic CSS and render/browser behavior.

Do not fork componentization authority.

If the current component has no proven fluid requirement, select a different tracer.

---

# Task 13 — Page-scale browser proof

**Boundary:** Lead 3 page assembly + Lead 4 Fluid review.

Use the representative real page.

Browser samples:

```text
below
start
25%
50%
75%
end
above
```

Modern and fallback paths must be tested.

Computed comparable lengths:

```text
absolute difference <= 0.01 CSS px
```

Also verify:

- shared typography/spacing boundaries;
- desktop/mobile;
- browser zoom;
- multiple instances;
- no variable collisions;
- no duplicated Fluid system.

Use existing Storybook/browser evidence process.

---

# Task 14 — V1 acceptance

Update roadmap and create one bounded acceptance/evidence record.

Require:

```text
FluidDomain=PROVEN
FluidValue=PROVEN
FluidScale=PROVEN
FluidScaleStep=PROVEN
progress output=PROVEN
exact fallback=PROVEN
numerical equivalence=PROVEN
ACSS fidelity=PROVEN
native typography=PROVEN
native spacing=PROVEN
Bricks tracer=PROVEN
Frames tracer=PROVEN
page tracer=PROVEN
determinism=PROVEN
regression=GREEN
```

Only then:

```text
FLUID_V1=ACCEPTED
```

Prefer:

```text
LEAD4=RETIRED_TO_MAINTENANCE
```

unless a concrete next tracer needs another Fluid semantic capability.

---

## Global STOP conditions

```text
STOP=MAIN_MOVED_WITH_MATERIAL_CONFLICT
STOP=SPEC_DRIFT
STOP=TOKENSET_CONTRACT_CHANGE_REQUIRED
STOP=ACSS_IDENTITY_DRIFT
STOP=ACSS_CURVE_FIDELITY_MISMATCH
STOP=FALLBACK_CURVE_MISMATCH
STOP=RAW_CSS_AS_CANONICAL_DATA
STOP=UNBOUNDED_POWER
STOP=SOURCE_SPECIFIC_FLUID_CORE
STOP=TOKENBRIDGE_LEGACY_BYTES_CHANGED
STOP=LEAD1_CONCURRENT_FLUID_EDIT
STOP=REAL_TRACER_DOES_NOT_SUPPORT_ASSUMED_SEMANTICS
STOP=V1_SCOPE_EXPANSION_WITHOUT_REAL_TRACER
```

---

## Completion definition

Fluid V1 must be:

```text
source-neutral
deterministic
source-faithful
progress-first
compatibility-safe
package-safe
browser-proven
section-proven
page-proven
```

No public-release/provenance claim is implied.

```text
FLUID_IMPLEMENTATION_PLAN=OWNER_APPROVAL_REQUIRED
IMPLEMENTATION_AUTHORIZED=NO
```
