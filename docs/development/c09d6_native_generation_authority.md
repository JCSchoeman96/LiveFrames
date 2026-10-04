# C09D6-A — Native generation and review authority

**Status:** authority/documentation only (C09D6-A)

**Plan ID:** C09D6-A

**Plan version:** v1

**Scope:** freeze native component generation boundaries, review-to-generation
gates, styling split, result taxonomy, Catalogue/P10 separation, and repository
truth reconciliation. No generator production code in this slice.

**Authority:** this file is the active contract for native component generation
semantics and review-gated generation inputs. It does **not** supersede
`docs/development/c09d1_component_contract_authority.md`,
`docs/development/c09d3_componentization_plan_authority.md`, or
`docs/development/c09d5_componentization_proposer_authority.md` on public API,
placement, or proposer rules; it **extends** them with generation and review
boundaries. `docs/11_CSS_AND_TAILWIND_STRATEGY.md` and
`docs/20_P6_4A_NATIVE_STYLING_BRIDGE_ARCHITECTURE.md` own cross-cutting styling
delivery. `docs/23_CATALOGUE_ARCHITECTURE.md` and
`docs/24_CATALOGUE_VERSIONING_POLICY.md` remain G1 architecture history;
current **runtime** Catalogue posture is summarized in §2 and §15.

**Accepted base:** `98c464b4ba92d0a14e7a95b397496717c15b4835`

**Accepted tree:** `04f02998067e4db1442e22a735f800f8d25add1d`

**Last updated:** 2026-10-04

### Revision log

- `v1` — initial C09D6-A authority: domain boundaries, review model,
  generator lifecycle, generation semantics, styling split, determinism, Fidelity
  and Catalogue/P10 boundaries, CTA Tango tracer preflight, near-term roadmap

---

## 1. Goal and non-goals

### Goal

Enable a deterministic, review-gated pipeline:

```text
DesignDocument
+ explicit ComponentizationSemanticInput
→ ComponentizationProposer
→ proposed ComponentContract + ComponentizationPlan
→ explicit human reviewer approval
→ native Phoenix/HEEx + package-owned styling generation
→ Storybook/browser verification
→ second real native section
→ Catalogue admission (separate reviewed step)
→ later P10 consumer-project ejection (separate system)
```

C09D6-A freezes the **authority** for everything after proposer output through
generation handoff. Implementation slices (`C09D6-B` … `C09D6-D`, `C09D7-*`)
follow this document.

### Non-goals (C09D6-A and deferred slices)

```text
native generator production code (C09D6-C/D)
reviewer approval UI or persistence (C09D6-B)
Catalogue admission workflows or production manifests
P10 consumer-project ejection
Design IR 2.0.0 schema changes
ComponentContract format 1.0.0 schema changes
ComponentizationPlan format 1.0.0 schema changes
new RenderProjection roles
collection-item RenderProjection
Behavior IR or interactive component generation
semantic guessing, accessibility inference, or naming invention
machine-level evidence-insufficient waiver for human approval
routing native generation through LiveFrames.Fidelity
```

---

## 2. Repository truth (current checkpoint)

Reconciled against accepted base `98c464b4ba92d0a14e7a95b397496717c15b4835`.
Short pointers: `docs/17_ROADMAP.md`, `README.md`.

| Area | State |
| --- | --- |
| C09D5-A / B0 / B1 / B2 | **complete** — proposer authority and implementation |
| `ComponentizationProposer` | **implemented** |
| `ComponentContract` / `ComponentizationPlan` models and validators | **implemented** |
| Catalogue schema, manifest, lifecycle, Registry, fingerprint, versioning, discovery | **implemented** in library code |
| Production Catalogue root `apps/live_frames/priv/catalogue/` | **absent** (no committed manifests) |
| Production Registry at compile time | **empty** membership (no canonical Hero Catalogue manifest) |
| Native component generator | **not implemented** |
| P10 Catalogue ejection generator | **not implemented** |
| Phase 6 Hero native section | **accepted** (hand-authored; not proposer/generator pipeline) |

G1 documents (`docs/23`, `docs/24`) record pre-implementation architecture
approval. They are **not** rewritten here. Current truth: Catalogue **library
infrastructure exists**; **production Catalogue content, admission, generator
support flags, and ejection** remain downstream and not authorized by C09D6-A.

---

## 3. Critical terminology (frozen)

```text
Native Component Generator
  approved ComponentContract
  + matching ComponentizationPlan
  + exact DesignDocument
  → native Phoenix component artifacts (+ package-owned CSS per §10)

Catalogue Ejection Generator / P10
  selected Catalogue item
  → copies/adapts files into a consumer Phoenix project
```

These are **separate systems**. C09D6 does not implement or authorize P10
ejection.

---

## 4. Authority hierarchy (read order)

| Priority | Document | Owns |
| --- | --- | --- |
| 1 | `docs/03_DESIGN_IR_SPEC.md` | normalized design meaning |
| 2 | `docs/development/c09d1_component_contract_authority.md` | public API, BindingProjection, approval semantics |
| 3 | `docs/development/c09d3_componentization_plan_authority.md` | RenderProjection, placement, plan validation |
| 4 | `docs/development/c09d5_componentization_proposer_authority.md` | proposer inputs and outcomes |
| 5 | **this document** | review gates, native generation lifecycle, styling split, results |
| 6 | `docs/11_CSS_AND_TAILWIND_STRATEGY.md`, `docs/20_P6_4A_NATIVE_STYLING_BRIDGE_ARCHITECTURE.md` | package CSS, `--lf-*`, Tailwind build boundary |
| 7 | `docs/19_PHASE_6_NATIVE_COMPONENTIZATION.md`, `docs/08_COMPONENT_MODEL.md` | Hero evidence only |

---

## 5. Domain model boundaries

Conceptual boundaries only — **no new schemas in C09D6-A**.

| Domain | Responsibility | Inputs | Outputs | Must not |
| --- | --- | --- | --- | --- |
| **Component Review** | Human records approval on `ComponentContract.approval_status` only | Candidate contract + plan + design doc + reviewer judgment | `:approved`, `:rejected`, or retained `:needs_review` / `:proposed` | Emit HEEx/CSS; mutate plan; auto-approve proposer output |
| **Native Generation** | Mechanical emission from approved tuple | Approved contract, matching plan, exact design doc | `Generation Result` / artifact bundle | Change approval_status; invent semantics; call Fidelity as generator |
| **Native Styling** | Package-owned presentation CSS and public `--lf-*` surface | Approved contract roles, TokenSet-backed theme rules, layout evidence from plan/IR | Component CSS + theme bridge updates (C09D6-D) | Expose Bricks/Frames/ACSS class names as public API |
| **Generation Result** | Typed outcome of one generator run | Generator lifecycle terminal | Success bundle or failure taxonomy (§9) | Imply Catalogue or filesystem writes |
| **Generated Artifact Bundle** | Deterministic set of emitted source files | Successful generation | Ordered file records (module, CSS, optional map metadata) | Consumer-project paths |
| **Verification** | Storybook/browser evidence | Rendered component + CSS | Human acceptance records (separate slices) | Substitute for review or generation gates |
| **Catalogue handoff** | Reviewed admission of a verified native section | Verified component + manifests policy | `CatalogueItem` lifecycle advance | Run automatically on `generated` |
| **future Ejection (P10)** | Consumer project copy/adapt | Selected released Catalogue item | Deterministic file copy + namespace rewrite | Share implementation with native generator |

---

## 6. Review result model

### 6.1 `approval_status` (unchanged)

`ComponentContract.approval_status` remains:

```text
proposed | approved | needs_review | rejected
```

It is an **approval result**, not a second independent workflow lifecycle.
`ComponentizationPlan` has **no** `approval_status`.

### 6.2 Allowed transitions (reviewer-only)

```text
proposed → approved
proposed → rejected

needs_review → (revised semantic decisions / IR) → new proposal
               → approval_status returns to proposed or needs_review on new pair

needs_review → rejected
```

The **native generator must never** change `approval_status`.

### 6.3 First-wave guard: `needs_review` → `approved`

First-wave human approval **must not** directly promote a blocker-bearing
`needs_review` candidate to `:approved`. Blockers include any contract or plan
diagnostic with severity `:error` or `:fatal`, and any failed validator in §6.4.

Resolution path: revise upstream semantic input and/or IR, re-run proposer,
then review the **new** pair.

### 6.4 Reviewer approval guards (ordering)

Reviewers establish `:approved` only after **all** steps succeed on the **same
tuple** `(ComponentContract, ComponentizationPlan, DesignDocument)`:

| Step | Function | Purpose |
| --- | --- | --- |
| 1 | `LiveFrames.IR.validate/1` | Design document intrinsic validity |
| 2 | `ComponentContract.validate/1` | Contract intrinsic validity |
| 3 | `ComponentContract.validate_ir_references/2` | Contract ↔ IR linkage (**strict**; `evidence_insufficient` blocks approval) |
| 4 | `ComponentizationPlan.validate/1` | Plan intrinsic validity |
| 5 | `ComponentizationPlan.validate/3` | Plan ↔ contract ↔ IR references |
| 6 | Tuple linkage | `plan.contract_id == contract.contract_id` and `plan.design_document_sha256` equals fingerprint from `ComponentizationPlan.design_document_sha256/1` on the supplied document |
| 7 | Stored diagnostics | No `:error` or `:fatal` in `contract.diagnostics` or `plan.diagnostics` |

**Circularity resolution:** `ComponentContract.validate_for_generation/2` and
`ComponentizationPlan.validate_for_generation/3` require `approval_status ==
:approved` **before** running generation-eligibility checks. Human approval
therefore uses steps 1–7 only; it does **not** call `validate_for_generation` to
decide whether approval is allowed. After a reviewer sets `:approved`, the
**generator entry gate** calls `validate_for_generation` on contract and plan to
confirm the tuple still satisfies generation prerequisites.

C09D6-A does **not** add a machine-level `evidence_insufficient` waiver for
step 3. (Plan `preflight` may treat that code specially for **pairing**
validation; that existing behavior does not authorize silent human approval.)

### 6.5 Generation entry gate (post-approval, generator-only)

Immediately before native generation:

```text
ComponentContract.validate_for_generation(contract, design_document)
ComponentizationPlan.validate_for_generation(plan, contract, design_document)
```

Both must return `:ok`. Failure → `generation_blocked` (§9), not a change to
`approval_status`.

---

## 7. Generator input (frozen tuple)

The native generator **must** require exactly:

```text
approved ComponentContract   (approval_status = :approved)
matching ComponentizationPlan
exact DesignDocument
```

Rules:

- `plan.contract_id` must equal `contract.contract_id`.
- `plan.design_document_sha256` must equal the fingerprint of the supplied
  `DesignDocument`.
- **No** contract-only generation.
- **No** plan-only generation.
- **No** generation from a design document that does not match the plan
  fingerprint.

---

## 8. Native generator lifecycle

Compile-time / cold-path only. States, guards, and side effects:

```text
received
  guard: tuple present
  → gate_validated
      guard: IR validate + validate_for_generation on contract and plan (§6.5)
      fail terminal: generation_blocked
  → render_model_built
      guard: mechanical indexes built; projections resolved from plan + contract
      fail terminal: generation_blocked (invalid projection) | generation_failed (internal defect)
  → source_emitted
      guard: HEEx (+ optional CSS slice per §10) bytes materialized in memory
      fail terminal: generation_failed
  → source_validated
      guard: emitted source passes generator-internal structural/security checks
      fail terminal: generation_failed
  → generated
      terminal success: Generation Result with artifact bundle
```

**Side effects:** C09D6-A authorizes **no implicit filesystem write**, no
consumer-project mutation, and no Catalogue mutation. Persisting artifacts is an
explicit later implementation choice guarded by separate authorization.

**Terminal failures:**

| Terminal | Meaning |
| --- | --- |
| `generation_blocked` | Invalid, unapproved, or mismatched inputs; failed `validate_for_generation`; unresolved projections; security rule violation on **inputs** |
| `generation_failed` | Generator defect after inputs were gate-validated (bug, incomplete emitter, internal invariant break) |
| `generated` | Success |

---

## 9. Generation result taxonomy (frozen)

| Result | When | Carries |
| --- | --- | --- |
| `{:ok, %GeneratedArtifactBundle{}}` | `generated` | Canonical-ordered artifacts + deterministic metadata (fingerprints, contract_id, plan fingerprint) |
| `{:error, :generation_blocked, diagnostics}` | gate or input semantics | Diagnostics only; no partial public artifacts |
| `{:error, :generation_failed, diagnostics}` | post-gate generator defect | Diagnostics; may include internal detail for engineers |

Do not conflate `generation_blocked` with `generation_failed` in APIs or logs.

---

## 10. Generation semantics (mechanical rules)

The generator is **mechanical**. It must not make semantic decisions omitted
upstream (names, roles, placement, accessibility policy, and public API shape
come from the approved contract and plan).

### 10.1 Module and function intents

- Emit `defmodule` from `module_intent` and `def` function component from
  `function_intent` using the same bounded validation as
  `ComponentContract.Validation` (`validate_intent_name/2` rules).
- **No** arbitrary executable identifiers: intents must pass existing intent
  name validation before emission.

### 10.2 Phoenix attrs and slots

- `public_attrs` → `attr` declarations on the function component in contract
  order.
- `public_slots` → `slot` declarations in contract order; first-wave cardinality
  only as enforced by `validate_for_generation`.

### 10.3 Collections

- `CollectionInput` → typed list attrs and nested `item_fields` per contract;
  render collection subtrees via plan placement and bindings, not new public
  fields invented at generation time.

### 10.4 BindingProjection rendering

- Map each `BindingProjection` to HEEx attribute or slot wiring on
  `target_node_id` within the boundary subtree.
- Types and requiredness come from the contract attr/slot/item field referenced
  by the projection.

### 10.5 RenderProjection rendering

Closed first-wave roles only (per C09D3):

| Role | Mechanical emission |
| --- | --- |
| `text_content` | Escaped text body |
| `asset_src` | Image `src` from attr/binding |
| `asset_alt` | Image `alt`; decorative policy from plan (`alt=""` when authority says decorative) |
| `link_url` | `href` on link roots |
| `heading_level` | Heading tag level from attr |
| `root_id` | HTML `id` |
| `root_class` | HTML `class` (package semantic classes plus reviewer-approved values only) |
| `root_global_attrs` | Allowed global attrs via Phoenix `global` typing |
| `subtree_slot` | Slot invocation for subtree composition |

No collection-item `RenderProjection` in format 1.0.0.

### 10.6 Static internal content

Nodes inside the boundary without a public binding may emit **static** structure
from Design IR literal content where plan marks internal-only placement; no new
public attrs.

### 10.7 Image accessibility

- `asset_alt` projections and contract accessibility metadata govern `alt`
  emission; generator does not infer decorative vs informative without plan +
  contract authority.

### 10.8 Styling boundary (mandatory split)

| Slice | Delivers |
| --- | --- |
| **C09D6-C** (core) | Phoenix module + HEEx function component source |
| **C09D6-D** (styling) | Package-owned component CSS under `assets/css/components/…`, updates to `live_frames.css` import graph, and TokenSet-backed `--lf-*` via existing `LiveFrames.Styling.TokenBridge` rules |

A reusable section is **end-to-end complete** only after **C09D6-C + C09D6-D +
verification**. C09D6-A does not authorize claiming visual completeness from
HEEx alone.

**Package-owned semantic classes:**

- Public structure/presentation classes use the `.lf-*` namespace per `docs/11`
  (e.g. `.lf-cta` derived deterministically from `contract_id` / approved
  `root_class` role — never from source Bricks/Frames/ACSS class strings).
- Theme customization remains on public `--lf-*` only; component-private
  `--lf-<component>-*` composition variables follow `docs/20` §8 pattern.
- **Do not** expose source `globalClasses` or ACSS utility names as generated
  public API.

**Authority sufficiency:** Design IR 2.0.0 style records, TokenSet `1.0.0`,
`docs/11`, `docs/20`, and Hero/Fidelity mechanical evidence are sufficient to
derive **deterministic** native styling **without semantic guessing**, provided
styling generation maps IR/plan layout evidence to token-backed rules already
used for Hero. C09D6-A does **not** STOP for styling authority.

`LiveFrames.Fidelity` is **not** the native styling generator; reuse shared
low-level CSS serialization helpers only where semantics match (§12).

---

## 11. HEEx and security rules (frozen)

```text
caller text escapes through HEEx
no raw source HTML execution
no source PHP/JS execution
no Code.eval*
no dynamic module loading
no String.to_atom on untrusted strings
no untrusted apply/MFA
no arbitrary tag generation
no arbitrary attribute generation
no javascript: URL fabrication
```

Tag names and attribute names emitted from Design IR must come from closed
allow-lists tied to normalized IR node kinds, not free-form source strings.
`module_intent` / `function_intent` follow bounded validation (§10.1).

---

## 12. LiveFrames.Fidelity boundary

```text
LiveFrames.Fidelity = fidelity reproduction compiler
                      ≠ native component generator
```

Fidelity compiles Design IR toward **source-faithful** preview output. The
native generator compiles an **approved public API** toward package-owned
components. Do not route native generation through Fidelity because it already
emits HEEx. Shared helpers (e.g. safe CSS declaration shaping) may be reused
only when input semantics are identical; otherwise duplicate mechanically with
native types.

---

## 13. Determinism

Same approved tuple must produce **byte-identical** output.

Forbidden in the generator path:

```text
clock
randomness
filesystem discovery
DB
network
runtime configuration
map enumeration dependence (unordered iteration)
```

**Canonical artifact ordering:** sort emitted files by logical path (UTF-8
lexicographic). Within each file: deterministic formatter (Mix format rules for
`.ex`, committed CSS formatting conventions for stylesheets). Build projection
indexes once; **O(boundary nodes + bindings + contract records + plan records +
style records)**; do not scan the full IR tree per projection.

---

## 14. Performance posture

Cold compile/build-time path only. No Redis, ETS, Cachex, DB, GenServer, Oban,
PubSub, or PgBouncer in the generator hot path.

---

## 15. Catalogue boundary

Catalogue **infrastructure** exists in `apps/live_frames/lib/live_frames/catalogue/**`.
Production `priv/catalogue/` is **absent**; Registry membership is **empty**.

Native generation does **not** automatically:

```text
create CatalogueItem
advance Catalogue lifecycle state
mark distribution.generator supported
mark distribution.ejection supported
release a component
```

Catalogue admission remains a separate reviewed step (`C09D7-C`, P9 expansion).

---

## 16. P10 boundary

Master Phase 10 consumer ejection (downstream):

```text
selected Catalogue item
→ module namespace rewrite
→ assets/theme/hooks
→ conflict detection
→ deterministic file copy
```

C09D6 does **not** implement or authorize this. The **Catalogue Ejection
Generator** is a distinct product from the **Native Component Generator** (§3).

---

## 17. Second tracer: CTA Tango (preflight)

**Preferred** first non-Hero static tracer, subject to preflight:

Repository evidence (`docs/development/c07x_unsupported_surface_inventory.md`,
`docs/development/c09a_query_dynamic_data_contract.md`):

- Static composition: image, headings, rich text, primary button, grids, tablet
  styling changes.
- **No** query objects in export (listed alongside other static templates).
- **No** authorized interactive tracer in C09D6.

**Preflight result:** CTA Tango does **not** require Behavior IR, tabs, slider
state, modal state, timers, observer lifecycle, or dynamic query runtime for the
first-wave **static** native section path. C09D6-A does **not** expand into
Behavior IR.

If future componentization discovers runtime Behavior IR requirements, **STOP**
that tracer and escalate; do not stretch C09D6.

---

## 18. Near-term roadmap (refined sequence)

```text
C09D6-A  authority + repository truth          ← this slice
C09D6-B  reviewer approval implementation
C09D6-C  native generator core (HEEx)
C09D6-D  native styling generation
C09D7-A  CTA Tango componentization tracer
C09D7-B  CTA Tango generation + Storybook/browser verification
C09D7-C  external consumer proof / Catalogue handoff
P9       Catalogue expansion
P10      consumer ejection
later    Behavior IR + interactive components
```

C09D6-A does not implement these slices.

---

## 19. STOP conditions (implementers)

STOP and report the exact contradiction if:

```text
native generation requires Design IR, ComponentContract, or ComponentizationPlan schema changes
a new RenderProjection role is required
collection-item RenderProjection is required
review approval requires inventing evidence-insufficient waiver semantics
generator requires semantic naming/classification/accessibility inference
styling cannot be generated from docs/11 + docs/20 + TokenSet without guessing
CTA Tango componentization requires Behavior IR
native generator and P10 ejection cannot be cleanly separated
```

C09D6-A completed without triggering STOP.

---

## 20. Scope confirmation (C09D6-A)

| Deliverable | Status |
| --- | --- |
| `docs/development/c09d6_native_generation_authority.md` | this file |
| `docs/17_ROADMAP.md` current-status reconciliation | updated in slice PR |
| `README.md` current-status reconciliation | updated in slice PR |
| Generator production code | **out of scope** |
