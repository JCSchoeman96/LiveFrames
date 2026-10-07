# C09D6-A — Native generation and review authority

**Status:** active authority (C09D6-A + C09D6-C0 emission-surface freeze)

**Plan ID:** C09D6-A

**Plan version:** v5

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

**Accepted base:** `a3efdafe3d8bcb7d04aa1c4ad9660f0858f86bc3`

**Accepted tree:** `4626a0348538979e933d955e1e67c21236536b57`

**Last updated:** 2026-10-07

### Revision log

- `v1` — initial C09D6-A authority: domain boundaries, review model,
  generator lifecycle, generation semantics, styling split, determinism, Fidelity
  and Catalogue/P10 boundaries, CTA Tango tracer preflight, near-term roadmap
- `v2` — PR #133 review: `validate_references/3`, shared
  `validate_generation_prerequisites`, module/function emission naming, C09D6-D
  style-coverage preflight (candidate sufficient)
- `v3` — PR #133 final: `:proposed`-only approval source, artifact-visible
  static internal content rule, package CSS class from `category` + `module_intent`
- `v4` — C09D6-C0 (PR #135 review): freeze native element emission, icon
  generation eligibility, optional/no-default attr omission, validation emission,
  slot runtime, collection runtime, generator totality; record PR #135 defect
  classes as prohibited implementation patterns
- `v5` — PR #136 review: binding-native emission XOR (no paired RenderProjection),
  normalized-tag precedence, Plan/Contract prerequisite ownership, image/figure
  structure, conditional image alt runtime, static navigation retention,
  heading-level STATIC_DEFAULT_RULE, collection omission/type rules, count
  validation alignment, roadmap reconciliation

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

**C09D6-C0 emission capability (v5):** the same prerequisite boundary must
include every rule in §10.10–§10.17 that gates whether a tuple is
**generation-representable**. Split ownership:

| Gate | API | Owns (in addition to rows above where applicable) |
| --- | --- | --- |
| Contract-only | `ComponentContract.validate_generation_prerequisites/2` | Contract intrinsic validity; strict `validate_ir_references/2`; stored contract blockers; generation-capable attr/item **types**; **supported** attr/item **validation** shapes (§10.13); default-literal representability (§10.16); §10.1 intent grammar; contract-only capability diagnostics (`:any`, slot cardinality, …) |
| Plan + tuple | `ComponentizationPlan.validate_generation_prerequisites/3` | **All Contract `/2` prerequisites**; plan intrinsic validity; `validate_references/3`; tuple linkage; stored plan blockers; indexed plan generation rules; **boundary-scoped** native emission eligibility (§10.10–§10.12); `BINDING_NATIVE_EMISSION_RULE` admissibility (§10.4.1); in-boundary `icon` (§10.11); placement-dependent optional-input compatibility |

`ComponentReview.validate_generation_prerequisites/3` delegates to the Plan
`/3` gate and therefore inherits every Plan-owned blocker.

**Must not** move generation-only C0 rules into ordinary
`ComponentContract.validate_ir_references/2` or
`ComponentizationPlan.validate_references/3` unless D1/D3 already require the
same invariant for non-generation validation. C09D5 proposer /
`:needs_review` construction must remain unchanged.

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

D3 freezes **placement XOR** on each public target location:

```text
exactly one BindingProjection
OR
exactly one RenderProjection
```

A binding-backed public target **never** receives a duplicate
`RenderProjection` on the same placement. The generator must not require or
assume a “paired” render projection.

Map **every** admitted first-wave `BindingProjection` to exactly one native
output locus derived only from the frozen tuple (§10.4.1). Any combination
without exactly one mechanical interpretation blocks **Plan**
`validate_generation_prerequisites/3` (§6.4).

| `projection_kind` | Summary |
| --- | --- |
| `scalar_attr` | Site-scoped `ValueBinding` → native locus from `target_kind` + target node `semantic_type` + referenced `Attr` (§10.4.1). |
| `collection_attr` | Repeat `repeat_root_node_id` subtree with top-level `:list` public attr (§10.15). |
| `collection_item_field` | Collection-item `ValueBinding` → native locus from `target_kind` + node + `ItemField` (§10.4.1). |
| `collection_count_attr` | Bind `ValueBinding.value_kind = collection_count` to approved count public attr; expose `@count` (and nested count item fields per D1). **Never** `length/1`. |
| `slot` | Generation-blocked upstream; not implemented in C09D6-C. |

`RenderProjection` and `scalar_attr` are **alternate** sources for the same
**native roles** (for example `link_url` on `link` nodes); both paths must be
implemented. Omitting either is invalid.

#### 10.4.1 `BINDING_NATIVE_EMISSION_RULE` (frozen)

Derive emission from:

```text
BindingProjection.projection_kind
referenced ValueBinding / CollectionBinding (when applicable)
ValueBinding.value_kind
ValueBinding.target_kind
ValueBinding.scope
target DesignNode.semantic_type
referenced Attr or ItemField (type, validation, accessibility)
approved image accessibility metadata (when applicable)
```

**Do not** infer `root_id`, `root_class`, `root_global_attrs`, or
`heading_level` from an ordinary site `ValueBinding` unless the tuple also
contains the matching `RenderProjection` on that node (root/heading roles are
RenderProjection-owned in format `1.0.0`).

| Admission pattern | Native output locus |
| --- | --- |
| `scalar_attr` + `scope: site` + `value_kind: field` + `target_kind: text` + node `heading` \| `paragraph` \| `rich_text` | Escaped text body on that node (`text_content` locus) from `@public_attr` / safe assign access (§10.12). |
| `scalar_attr` + `scope: site` + `value_kind: field` + `target_kind: asset` + node `image` | `src` on resolved `img` (`asset_src` locus). |
| `scalar_attr` + `scope: site` + `value_kind: text` + node `image` + consumer-supplied image policy | `alt` on resolved `img` (`asset_alt` locus); runtime §10.12.1. |
| `scalar_attr` + `scope: site` + `value_kind: link_url` + node `link` | `href` on `a` (`link_url` locus). |
| `collection_attr` + top-level `CollectionInput` | `for lf_ci_n <- @public_list_attr` wrapping `repeat_root_node_id` subtree (§10.15). |
| `collection_item_field` + `scope: collection_item` + `target_kind: text` + node `heading` \| `paragraph` \| `rich_text` | Escaped text from `lf_item_field(item, "field")` at `text_content` locus. |
| `collection_item_field` + `scope: collection_item` + `target_kind: asset` + node `image` | `src` from item field at `asset_src` locus. |
| `collection_item_field` + `scope: collection_item` + `target_kind: text` + node `image` + approved alt sibling policy | `alt` from item field at `asset_alt` locus; runtime §10.12.1. |
| `collection_item_field` + `scope: collection_item` + `target_kind: link_url` + node `link` | `href` from item field at `link_url` locus (only when D1/D3 already admit this binding). |
| `collection_item_field` + nested list `ItemField` + child `CollectionBinding` | Nested `for` over parent item field list (§10.15); no top-level attr invention. |
| `collection_count_attr` + top-level count `Attr` + `value_kind: collection_count` | Public `@count` assign; **no** visual substitution at `target_node_id` unless a separate text placement exists. |
| Nested count `collection_item_field` + `value_kind: collection_count` | Item-field count value via accessor; same non-`length/1` rule. |

Any row not listed → Plan generation prerequisite blocked
(`native_generation.binding_emission_unsupported`).

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

### 10.10 Native element emission (C09D6-C0 freeze)

PR #135 (`feat/c09d6-c-native-generator`) is **evidence only**. It must not be
treated as authority. This section freezes the mechanical emitter.

#### 10.10.1 Native tag resolution (two layers)

**A. Source-normalized tag evidence** — `DesignNode.attributes["tag"]` when it is
a binary, `StaticMarkupContract.native_tag?/1` is true, **and** the tag is in
the per-`semantic_type` compatibility set (§10.10.2). Normalized source tags
**win** over generator defaults when compatible.

**B. Generator-owned `DEFAULT_TAG`** — used only when layer A does not apply.
Tags such as `a` and `img` are **native-generator defaults** authorized by C0;
they are **not** claims that Bricks `StaticSemantics` currently admits `a`/`img`
through `StaticMarkupContract`.

Resolution order:

```text
1. If attributes["tag"] present:
     allowlisted AND semantically compatible → emit that tag
     allowlisted but incompatible → Plan prerequisite blocked
     not allowlisted → Plan prerequisite blocked
2. Else if DEFAULT_TAG exists for semantic_type → emit DEFAULT_TAG
3. Else → Plan prerequisite blocked
```

Safe static attributes (except `href` / placement-owned attrs) are only those
accepted by `StaticMarkupContract.safe_attribute?/3` for the resolved tag.
**Never** emit source classes, source IDs, or arbitrary attributes.

`paragraph` and `rich_text` remain **distinct** IR meanings.

**Package root class (§10.8)** and root `root_id` / `root_class` /
`root_global_attrs` projections apply on the **outermost emitted element** for
`plan.boundary_node_id` (including `img`, `figure` wrapper, or dynamic
`heading_level` branches).

**Static literal text** on `button` and `link` nodes must be emitted when not
superseded by a public placement on that node.

#### 10.10.2 Semantic tag compatibility and defaults

| `semantic_type` | `SEMANTIC_TAG_COMPATIBILITY` (normalized `attributes["tag"]`) | `DEFAULT_TAG` | Static `content` | Children | Block |
| --- | --- | --- | --- | --- | --- |
| `section` | `section`, `div` | `section` | escaped UTF-8 when artifact-visible | yes† | — |
| `container`, `wrapper`, `stack`, `grid`, `generic`, `background`, `overlay` | `div` only | `div` | escaped UTF-8 when artifact-visible | yes† | other allowlisted tags (e.g. `nav`) → blocked |
| `paragraph` | `p` only | `p` | escaped UTF-8 string only | no‡ | non-string `content` |
| `rich_text` | `div`, `p`, `span` only | **none** | escaped UTF-8 when tag resolved | no‡ | missing/incompatible tag; structured HTML |
| `heading` | `h1`–`h6` only when **no** public `heading_level` placement owns the node | **none** | escaped UTF-8 when artifact-visible | no‡ | see §10.12 `heading_level` |
| `image` | see §10.10.3 | `img` | none (placements) | no | static image without `asset_src` policy (D3) |
| `button` | `button` only | `button` | escaped UTF-8 + static child text | yes† | — |
| `link` | `a` only (generator default; not source-normalized today) | `a` | escaped UTF-8 + static child text | yes† | — |
| `actions` | `div` only | `div` | none | yes† / `subtree_slot` | — |
| `icon` | — | — | — | — | §10.11 |

†Children render when not replaced by `subtree_slot` and not owned by a binding/
projection target. ‡No static child subtree except literal text on the node
itself.

#### 10.10.3 `image` and `figure` (frozen structure)

When `attributes["tag"]` is absent or `img`, emit a single `<img>` element.
Boundary package/root projections attach to that `<img>` when the image node is
the boundary root.

When normalized `attributes["tag"] == "figure"`:

```text
<figure …boundary/root attrs when boundary…>
  <img src=… alt=… />
</figure>
```

- Outer `<figure>`: boundary `root_id` / `root_class` / `root_global_attrs` /
  package class when applicable.
- Inner `<img>`: `asset_src` / `asset_alt` placements only.
- No other `figure` shapes are generation-eligible.

#### 10.10.4 Static navigation retention (links)

Normalized IR may carry safe static navigation:

```text
attributes["navigation"] == %{"href" => safe_href}
```

(per adapter static-navigation authority; no URL inference in the generator).

```text
STATIC_NAVIGATION_RULE =
  no public link_url BindingProjection or RenderProjection owns the link URL
  AND normalized safe navigation.href exists
  → emit href as internal literal on <a>

  public link_url placement owns the URL location
  → ignore static navigation literal for href
  → bind href only from public attr / safe assign access (§10.12)
  → optional public link_url absent MUST NOT fall back to static href
    (STATIC_DEFAULT_RULE; D3)
```

### 10.11 Icon generation eligibility (C08B1 alignment)

`icon` is a valid Design IR `semantic_type`, but C08B1 records **no trusted
native glyph renderer** and forbids admitting `svg` / `i` / font-icon markup in
the static allowlist.

First-wave native generation **must not** emit icon visuals and **must not**
classify icon-bearing tuples as `generation_failed` generator defects.

```text
ICON_NATIVE_GENERATION_RULE =
  any DesignNode with semantic_type = icon inside plan.boundary_node_id subtree
  → Plan validate_generation_prerequisites/3 diagnostic (severity :error)
  → generation_blocked (ordinary prerequisite; NOT implementer STOP)
```

Diagnostic code (frozen): `native_generation.icon_unsupported`.

Contract `/2` **must not** scan the whole `DesignDocument` for icons outside the
selected boundary. Reviewers must not approve pairs that violate this rule.

### 10.12 Optional public attrs (`default: nil` means no default)

Per C09D1, contract `default: nil` means **no default was declared**, not an
explicit Elixir `nil` default. The generator **must not** emit `attr(...,
default: nil)` to “fix” omission.

For each placement role, when the referenced public attr has `required: false`
and **no** explicit default in the contract:

| Render / binding role | Mechanical omission behavior |
| --- | --- |
| `text_content` | Read with safe assign access (`Map.get(assigns, :name)` / `assigns[:name]`). If absent at render time, omit the text segment; do not raise solely for omission. |
| `asset_src` | If absent, **omit the entire `image` element** for that placement. |
| `asset_alt` | See §10.12.1 (never omit required informative alt when `src` present). |
| `link_url` | If absent, emit `<a>` without `href` only when static link content or §10.10.4 internal navigation remains; **never** fall back from optional public attr to static `href`. |
| `heading_level` | If optional with **no** explicit contract default: **do not** use static `h1`–`h6` tag as hidden default (STATIC_DEFAULT_RULE). Tuple must be Plan-blocked unless omission behavior is explicitly frozen elsewhere. Static heading tags apply only when **no** public `heading_level` placement owns the node. |
| `root_id` | If absent, omit `id`. |
| `root_class` | If absent, emit package class only. |
| `root_global_attrs` | If absent, omit global spread. |

If two or more rows would require contradictory omission choices for the same
tuple, **STOP** (§19) — the tuple is not generation-representable without new
authority.

Required public attrs may use `@name` after gates prove requiredness.

#### 10.12.1 Conditional image `alt` (runtime)

For consumer-supplied image policies with
`required_when_source_present = true` (D3):

```text
source absent (optional placement)
  → omit image element

source present + decorative policy
  → alt=""

source present + consumer_supplied + alt present
  → emit supplied alt

source present + consumer_supplied + alt absent
  → deterministic contract/accessibility ArgumentError
```

Apply to top-level image attrs and collection item image/alt field pairs.
**Never** emit an informative `<img>` with `src` present without satisfying the
approved alt requirement. `nil` does not mean decorative (D1).

### 10.13 Validation emission (attrs and item fields)

Inventory for format `1.0.0` (fail-closed):

| Contract validation shape | Phoenix `attr/3` | Generated runtime enforcement |
| --- | --- | --- |
| `%{"values" => [1,2,3,4,5,6]}` on `:integer` (heading level) | `values: 1..6` | none additional |
| `%{"min" => n}` on count attrs / count item fields where `n` is numeric and `n >= 0` and map has **no other keys** | **forbidden** (`:min` is not a Phoenix attr option) | generated runtime check: value `>= n` (matches `ComponentContract.Validation.non_negative_validation?/1`) |
| any other non-empty validation map | only if this table gains a row | otherwise **block Contract generation prerequisites** |

Never silently drop validation metadata. Never emit unsupported Phoenix attr
options.

**Item fields — types (every present value):** before field-specific
validation, enforce approved `ItemField.type`:

| `ItemField.type` | Present-value rule |
| --- | --- |
| `:string` | `is_binary/1` |
| `:integer` | `is_integer/1` |
| `:boolean` | `is_boolean/1` |
| `:list` | `is_list/1` |
| `:map` | `is_map/1` |
| `:global` | **generation-blocked** for first-wave collection items (no valid item-field meaning) |
| `:any` | already generation-blocked at Contract prerequisites |

Invalid present values → clear contract/access error (D1). Then apply supported
`ItemField.validation` per the table above.

### 10.14 Slot runtime semantics (first-wave `0..1`)

| Contract slot | Generated declaration | Runtime |
| --- | --- | --- |
| `required: false` | `slot :name` | `render_slot(@name)` allowed to render zero entries |
| `required: true` | `slot :name, required: true` | zero entries → `ArgumentError` with deterministic message |
| cardinality `0..1` | (no repeated slot API) | more than one entry → `ArgumentError` with deterministic message |

“Generation-eligible `0..1`” **requires** enforcing `0..1` at runtime in the
generated function component.

### 10.15 Collection runtime (generator reconfirmation)

- Item semantics are scoped per `CollectionInput`; field names are unique **only
  within** their owning collection input.
- **Never** collapse same-named fields across collections into one helper.
- **Never** expose `source_collection_binding_id` (or other source IDs) in
  generated public names, module paths, or consumer-visible strings.
- Internal loop variables use deterministic **ordinal identities** derived from
  `CollectionInput` order in the contract (`lf_ci_1`, nested `lf_ci_2`, …), not
  sanitized binding IDs.

**Optional top-level collection** (`required: false`, no explicit default):

```text
public list attr absent at runtime → omit repeat subtree (no iterations)
explicit contract default []       → zero iterations via declared default
present list value                 → iterate approved subtree
```

Do not synthesize `[]` for “no default”.

**Nested optional list fields:** absent field with no explicit default → omit
nested repeat subtree; explicit default `[]` → zero iterations; present
non-list → item field type error. Never `|| []`.

- Item accessor: exact string key, then existing atom key with matching
  `Atom.to_string/1`; never `String.to_atom/1` or `String.to_existing_atom/1`.
- `collection_count_attr` uses the approved count attr / count item field only.

### 10.16 Generator totality and default literals

```text
GENERATOR_TOTALITY_RULE =
  for every tuple that passes both generation gates,
  NativeGenerator.generate/3 returns exactly one frozen result tuple
  and never raises, throws, or exits due to emitter input shape.
```

Default literal emission for `attr` / `ItemField` defaults:

- Use `ComponentContract` canonical JSON normalization semantics (same as
  serializer), not a second conflicting map-key policy.
- Preserve JSON/Elixir numeric meaning exactly (`inspect/1` on numbers is
  acceptable only when it round-trips the stored value).
- Do not impose arbitrary float decimal formatting.
- Atom keys in stored maps must be normalized to string keys before emission.

Gate-valid defaults that cannot be expressed under these rules block generation
prerequisites.

### 10.17 Prohibited implementation patterns (PR #135 review)

The following classes are **explicitly forbidden** in C09D6-C implementers:

```text
scalar_attr or collection_count_attr binding omitted
“paired RenderProjection” assumed for binding-backed targets
bound link_url omitted
button/link static IR text or static navigation.href dropped
optional public link_url falling back to static navigation.href
package root class omitted on image or dynamic-heading boundary roots
normalized tag used when semantically incompatible (e.g. container + nav)
allowlisted normalized tag ignored or overwritten by semantic_type guesses
rich_text → unconditional <p>
heading_level optional attr falling back to static h1–h6 tag
icon → generation_failed instead of Plan prerequisite block
informative img with src present but required alt absent
unknown validation silently dropped
Phoenix attr options invented (e.g. min: 0)
ItemField validation ignored
same-named fields across collections collapsed
source_collection_binding_id embedded in generated locals
optional nested collection coerced with || []
gate-valid literal/default causing throw/crash in emitter
outer-source parse substituting for compile-safe generated helpers
```

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
C09D6-C0 native emission surface authority    ← v4 §10.10–§10.17 (this amendment)
C09D6-C  native generator core (HEEx)         ← blocked until C0 merged; PR #135 hold
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
rich_text or heading emission requires a tag/level guess outside §10.10.2
optional/no-default public attr placement requires a guess outside §10.12
approved validation metadata has no frozen emitter/runtime mapping (§10.13)
Behavior IR or raw HTML execution would be required for fidelity
```

C09D6-A completed without triggering STOP. C09D6-C0 documents emission-surface
STOP triggers for C09D6-C; **no Contract/Plan/IR schema change** is authorized
by C0.

---

## 20. Scope confirmation (C09D6-A)

| Deliverable | Status |
| --- | --- |
| `docs/development/c09d6_native_generation_authority.md` | this file (v5 includes C09D6-C0) |
| `docs/17_ROADMAP.md` C09D6-C0 pointer | updated in C0 slice PR |
| Generator production code | **out of scope** (PR #135 remains on hold) |
