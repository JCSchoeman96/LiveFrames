# C09D6-A — Native generation and review authority

**Status:** authority/documentation only (C09D6-A)

**Plan ID:** C09D6-A

**Plan version:** v3

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
- `v2` — PR #133 review: `validate_references/3`, shared
  `validate_generation_prerequisites`, module/function emission naming, C09D6-D
  style-coverage preflight (candidate sufficient)
- `v3` — PR #133 final: `:proposed`-only approval source, artifact-visible
  static internal content rule, package CSS class from `category` + `module_intent`

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

### 6.3 Forbidden: direct `needs_review` → `approved`

Human approval **must never** set `approval_status = :approved` while the
contract remains `:needs_review`, **even when**
`validate_generation_prerequisites/3` returns `:ok`. C09D5 mandatory review
triggers (for example `STATIC_COLLECTION_ITEM_RULE`) can require
`:needs_review` without a generation-prerequisite blocker; prerequisites do not
“clear” that classification.

Only `:proposed` candidates may become `:approved` (§6.5). A `:needs_review`
pair must be **revised and re-proposed** or **rejected** (§6.2).

### 6.4 Shared non-status generation prerequisites (frozen)

**Invariant:** among candidates eligible for approval (`approval_status ==
:proposed` only; §6.3), a reviewer may set `:approved` **if and only if** the
same tuple satisfies every generation prerequisite **except** the
`approval_status == :approved` check itself. No `:proposed` candidate that
would fail generation eligibility (for example `:any` public attrs or collection
item fields) may be approved.

C09D6-B **must** introduce a single reusable, pure prerequisite boundary so
review approval and generator entry cannot drift. Conceptual API (exact module
name is implementation detail; behavior is frozen):

```text
validate_generation_prerequisites(contract, plan, design_document) :: :ok | {:error, diagnostics}
```

**Must include** (same semantics as today's `validate_for_generation` paths,
**excluding** only the contract `approval_status` guard):

| Check | Public API (reference) |
| --- | --- |
| Design document intrinsic validity | `LiveFrames.IR.validate/1` |
| Contract intrinsic validity | `ComponentContract.validate/1` |
| Contract ↔ IR linkage (**strict**; `evidence_insufficient` blocks) | `ComponentContract.validate_ir_references/2` |
| Plan intrinsic validity | `ComponentizationPlan.validate/1` |
| Plan ↔ contract ↔ IR references | `ComponentizationPlan.validate_references/3` |
| Tuple linkage | `plan.contract_id == contract.contract_id` and matching `design_document_sha256` |
| Stored blockers | No `:error` or `:fatal` in `contract.diagnostics` or `plan.diagnostics` |
| Generation capability | Same rules as `ComponentContract` generation-capability diagnostics today (for example rejection of `:any` public attrs and collection `ItemField` types, first-wave slot cardinality) |
| Plan generation reference index | Same indexed reference rules invoked by `ComponentizationPlan.validate_for_generation/3` after preflight |
| Intent emission eligibility | §10.1 generation token grammar |

**Must not** require `approval_status == :approved`.

**Implementation rule (C09D6-B):** extract shared logic from existing
`ComponentContract.validate_for_generation/2` and
`ComponentizationPlan.validate_for_generation/3`. Public `validate_for_generation`
**must** compose:

```text
approval_status == :approved
AND validate_generation_prerequisites(contract, plan, design_document) == :ok
```

Do **not** maintain two independent rule sets that can diverge.

C09D6-A does **not** add a machine-level `evidence_insufficient` waiver for
human approval or prerequisites. C09D6-B may refactor internal plan preflight
so pairing validation aligns with this strict prerequisite policy.

### 6.5 Review approval gate

Reviewer approval requires **both**:

```text
contract.approval_status == :proposed
AND
validate_generation_prerequisites(contract, plan, design_document) == :ok
→ reviewer may set approval_status = :approved
```

If `approval_status == :needs_review`, approval is **forbidden** regardless of
prerequisites (§6.3). Resolution: revise upstream semantic input and/or IR,
re-run proposer, review the **new** pair, or reject.

Setting `:approved` does **not** call `validate_for_generation/2` or `/3`
directly; prerequisites already cover every non-status generation check.

### 6.6 Generation entry gate (post-approval)

Immediately before native generation:

```text
ComponentContract.validate_for_generation(contract, design_document)
ComponentizationPlan.validate_for_generation(plan, contract, design_document)
```

Both must return `:ok`. Equivalently: `approval_status == :approved` plus
`validate_generation_prerequisites/3 == :ok`. Failure → `generation_blocked` (§9),
not a change to `approval_status`.

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
      guard: validate_generation_prerequisites + approved status (§6.4–6.6);
         equivalently validate_for_generation on contract and plan
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

### 10.1 Module and function intents → Elixir source names

`ComponentContract.Validation.validate_intent_name/2` proves only a **non-empty,
non-source-vocabulary** string. It does **not** prove a valid Elixir module alias
or function identifier. Examples such as `module_intent: "marketing_block"` are
**semantic Phoenix module intents**, not literal `defmodule` names.

First-wave generation **must** map intents through a frozen, package-owned rule
(no `String.to_atom/1`, no dynamic `apply`, no arbitrary user module alias, no
filesystem/path inference):

#### Generation token grammar (additional prerequisite)

Both `module_intent` and `function_intent` must match:

```text
^[a-z][a-z0-9_]*$
```

(same character class as contract public names). Tokens failing this grammar
block `validate_generation_prerequisites/3` until the contract is revised and
re-proposed. `validate_intent_name/2` alone is **not** sufficient for emission.

#### Deterministic module namespace

| `category` | Generated module prefix |
| --- | --- |
| `:section` | `LiveFrames.Components.Sections` |
| `:component` | `LiveFrames.Components` |
| `:pattern` | `LiveFrames.Components.Patterns` |
| `:primitive` | `LiveFrames.Components.Primitives` |

**Module suffix:** split `module_intent` on `_`, capitalize each segment with
ASCII rules (`marketing_block` → `MarketingBlock`), concatenate without separators.

**Full module name:**

```text
<prefix>.<ModuleSuffix>
```

Example: `category: :section`, `module_intent: "marketing_block"` →
`LiveFrames.Components.Sections.MarketingBlock`.

#### Function component name

Emit `def <function_intent>(assigns)` using the validated token verbatim
(`function_intent: "hero"` → `def hero(assigns)`).

#### Artifact path (deterministic, not inferred from host project)

```text
lib/live_frames/components/<category_path>/<module_intent>.ex
```

where `category_path` is `sections`, `patterns`, `primitives`, or empty
(component category maps to `lib/live_frames/components/<module_intent>.ex`).

Same semantic intents always yield the same module, function, and relative path.
The contract does **not** choose an arbitrary top-level namespace.

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
| `root_class` | Optional **consumer-supplied** additional `class` value(s) on the root, emitted **alongside** the always-present package semantic class (§10.8); never replaces it |
| `root_global_attrs` | Allowed global attrs via Phoenix `global` typing |
| `subtree_slot` | Slot invocation for subtree composition |

No collection-item `RenderProjection` in format 1.0.0.

### 10.6 Static internal content

`ComponentizationPlan` format `1.0.0` does **not** serialize
`StaticContentDispositionDecision` from C09D5 semantic input. The native
generator tuple is **only** `(ComponentContract, ComponentizationPlan,
DesignDocument)` — do **not** read semantic-input decisions at generation time
and do **not** infer “internal-only placement” from nonexistent plan fields.

**Artifact-visible first-wave rule:** a supported `DesignNode` inside the
validated boundary may retain literal IR content as an **internal generated
constant** only when **all** hold:

- the node lies inside the validated boundary;
- it is not replaced by a `subtree_slot` projection;
- its relevant content/location is not owned by a public `BindingProjection` or
  `RenderProjection` target;
- retaining it does not violate D3 static-image, unsupported-node, placement,
  accessibility, or other generation rules.

This is mechanical derivation from the approved tuple, not semantic promotion.
Static content must **never** become a new public attr or slot during generation.

**STOP (tuple insufficiency):** if C09D6-C proves that two different valid
`StaticContentDispositionDecision` sets can yield the same approved
`ComponentContract` + `ComponentizationPlan` + `DesignDocument` tuple but
require different native output, **STOP**. Do not silently add `SemanticInput`
to the generator tuple and do not change Contract/Plan schemas inside C09D6-C.

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

**Package-owned semantic classes (structural identity):**

Derive the generated package semantic class **only** from validated `category`
and `module_intent` (§10.1 token grammar). **Do not** derive CSS identity from
`contract_id`, source classes, source IDs, or the public `root_class` attr.

Transform `module_intent` underscores to hyphens; prefix with category to avoid
cross-category collisions:

| `category` | `module_intent` | Generated root class |
| --- | --- | --- |
| `:section` | `marketing_block` | `.lf-section-marketing-block` |
| `:component` | `card` | `.lf-component-card` |
| `:pattern` | `pricing_grid` | `.lf-pattern-pricing-grid` |
| `:primitive` | `badge` | `.lf-primitive-badge` |

General rule:

```text
.lf-<category>-<module_intent with "_" → "-">
```

where `<category>` is the atom name (`section`, `component`, `pattern`,
`primitive`).

**Root `class` behavior:**

- the generated package semantic class is **always present** on the component
  root;
- `root_class` (RenderProjection / public attr) is an **optional**
  consumer-supplied additional class layered alongside it;
- the consumer `root_class` value must **never** replace the generated
  structural class.

Theme customization remains on public `--lf-*` only; component-private
`--lf-<component>-*` composition variables follow `docs/20` §8 pattern. **Do
not** expose source `globalClasses` or ACSS utility names as generated public
API.

**Styling authority posture (candidate sufficient, not proven):** Hero and
cross-cutting docs (`docs/11`, `docs/20`, TokenSet `1.0.0`) establish the
**package-owned styling model**, but repository evidence (for example
`docs/development/c07x_unsupported_surface_inventory.md`) still records
incomplete ACSS class/selector reproduction. C09D6-A does **not** assert that
every visually meaningful style for a future tracer already survives in
normalized Design IR / TokenSet.

### 10.9 C09D6-D style-coverage preflight (mandatory before styling implementation)

Before C09D6-D implementation for a selected tracer (provisional: CTA Tango),
owners **must** run a documented style-coverage preflight:

```text
for every visually meaningful style required by that tracer:
  prove representation from approved Design IR, TokenSet, responsive IR,
  and/or existing package styling authority (docs/11, docs/20, TokenBridge)

if any required style depends on:
  unsupported ACSS class semantics
  unnormalized source globalClasses
  source-only selector recipes
  missing responsive/style semantics in IR
  inference from screenshots or source names

→ STOP (do not implement C09D6-D for that tracer)
```

C09D6-D may proceed **only** after this coverage proof passes. C09D6-D must
**not** reconstruct unsupported ACSS behavior heuristically or guess semantics
omitted from IR/TokenSet.

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
`module_intent` / `function_intent` follow §10.1 emission naming (not
`validate_intent_name/2` alone).

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
review approval and generator generation-eligibility cannot share the same
  non-status prerequisite semantics without changing frozen schemas/authority
generator requires semantic naming/classification/accessibility inference
  beyond frozen §10.1 token grammar and category namespace mapping
CTA Tango C09D6-D style-coverage preflight fails (unsupported semantics)
CTA Tango componentization requires Behavior IR
safe module/function source naming requires ComponentContract schema changes
static internal content requires SemanticInput in the generator tuple, or
  identical Contract+Plan+DesignDocument tuples would yield different native
  output from different StaticContentDispositionDecision sets
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
