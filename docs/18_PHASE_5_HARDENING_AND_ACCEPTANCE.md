# LiveFrames Phase 5 Hardening & Acceptance Plan

**Document:** `docs/18_PHASE_5_HARDENING_AND_ACCEPTANCE.md`
**Status:** Active Phase 5 execution authority
**Scope:** Phase 5 hardening, responsive fidelity, acceptance, and Phase 6 entry criteria
**Supersedes:** No existing architecture authority
**Refines:** `docs/00_LIVEFRAMES_MASTER_SPEC.md` Phase 5 execution and acceptance
**Does not authorize:** repository visibility changes, deletion of published history, licensing conclusions, Phase 6 implementation, or catalogue expansion

---

# 1. Purpose

LiveFrames has progressed beyond a proof-of-concept converter.

The project now has a real compiler spine:

```text
source ecosystem
        ↓
source-specific adapter
        ↓
Design IR + TokenSet
        ↓
fidelity generation
        ↓
HEEx + CSS + manifest
        ↓
preview
        ↓
future native componentization
        ↓
catalogue
```

The architecture is fundamentally sound.

However, successful base generation is not sufficient to declare the first Hero India tracer bullet complete.

The purpose of this document is to define the exact hardening and acceptance work required between the current Phase 5A state and Master Phase 6.

This document exists to prevent three failure modes:

1. accelerating into native componentization before source fidelity has been proven;
2. allowing current trust-boundary or provenance inconsistencies to become architectural debt;
3. expanding the catalogue before a second structurally different component proves that the generic compiler actually generalizes.

---

# 2. Ultimate Goal

The long-term LiveFrames goal is not:

> convert Bricks JSON into HEEx.

The goal is:

> provide a source-independent Phoenix-native design compiler and reusable LiveView component platform capable of transforming multiple design ecosystems into deterministic, safe, reviewable, native Phoenix components.

The intended long-term flow is:

```text
Bricks ─────────┐
HTML/CSS/JS ────┤
Figma ──────────┤
Webflow ────────┤
future sources ─┘
        ↓
source adapters
        ↓
LiveFrames Design IR
        +
LiveFrames TokenSet
        ↓
resolution
        ↓
fidelity generation
        ↓
verified source reproduction
        ↓
native componentization
        ↓
LiveFrames reusable API
        ↓
Storybook / catalogue / generator
```

Every Phase 5 decision must preserve that destination.

---

# 3. Backward Plan From the Ultimate Goal

To reach a trustworthy reusable catalogue, the following systems must be proven in order:

```text
source evidence
        ↓
provenance safety
        ↓
source adapter
        ↓
Design IR
        ↓
TokenSet
        ↓
safe deterministic generator
        ↓
responsive authority
        ↓
responsive fidelity
        ↓
asset fidelity
        ↓
browser verification
        ↓
visual verification
        ↓
accessibility verification
        ↓
native componentization
        ↓
second-component generalization proof
        ↓
catalogue expansion
```

The immediate MVP is therefore **not** a catalogue.

The immediate MVP is:

> one fully verified Hero India conversion whose source evidence, compiler output, responsive behavior, asset state, visual fidelity, accessibility, determinism, and native componentization are all truthfully proven.

Only after that should breadth increase.

---

# 4. Current Repository Truth

## 4.1 Completed

The following compiler foundations are considered complete for the current tracer bullet:

* [x] Phase 0 repository foundation
* [x] Phoenix umbrella
* [x] reusable `live_frames` application
* [x] preview application
* [x] PhoenixStorybook foundation
* [x] Design IR `1.0.0`
* [x] deterministic node identity
* [x] IR validation
* [x] deterministic IR serialization
* [x] TokenSet `1.0.0`
* [x] Automatic.css adapter for current required semantics
* [x] Bricks structured loading
* [x] Bricks source validation
* [x] Bricks component resolution
* [x] tree reconstruction
* [x] global class resolution
* [x] dependency extraction
* [x] Stage A source reconstruction
* [x] Bricks → Design IR
* [x] deterministic Design IR artifact
* [x] Phase 5A base fidelity HEEx generation
* [x] Phase 5A base fidelity CSS generation
* [x] fidelity manifest
* [x] fidelity drift verification
* [x] source-independent `LiveFrames.Fidelity`
* [x] caller-injected source fidelity resolver
* [x] unresolved source facts preserved instead of guessed
* [x] base preview route
* [x] base output compilation

## 4.2 Current authority work

Phase 5B breakpoint authority has been recovered, reviewed, and committed to `main`.

Accepted source authority:

```text
mobile_portrait
→ 478px
→ max-width
→ @media (max-width: 478px)

tablet_portrait
→ 991px
→ max-width
→ @media (max-width: 991px)
```

Authority classification:

```text
Level 3
version_matched_default_confirmed_by_source_environment
```

Important cascade invariant:

```text
> 991px
→ base

≤ 991px
→ tablet_portrait applies

≤ 478px
→ tablet_portrait remains active
→ mobile_portrait additionally applies
```

`tablet_portrait` MUST NOT be rewritten as an exclusive `479–991px` band.

## 4.3 Not yet proven

The following remain incomplete:

* [ ] generic responsive authority consumption
* [ ] responsive fidelity CSS generation
* [ ] 4/4 responsive overrides resolved
* [ ] exact breakpoint boundary browser verification
* [ ] Hero source asset resolved or truthfully declared unavailable
* [ ] source visual reference established
* [ ] desktop visual comparison
* [ ] tablet visual comparison
* [ ] mobile visual comparison
* [ ] automated accessibility gate
* [ ] runtime console-error gate
* [ ] full Master Phase 5 acceptance
* [ ] lifecycle hardening
* [ ] native Hero componentization
* [ ] semantic Tailwind bridge
* [ ] native Storybook Hero
* [ ] real catalogue item
* [ ] second structurally different tracer bullet
* [ ] proof of compiler generality beyond Hero India

---

# 5. Critical Architectural Invariants

The following invariants are now frozen unless explicitly changed through an architecture decision.

## 5.1 Design IR remains source-independent

Generic IR modules MUST NOT contain:

* Bricks numeric breakpoints;
* Bricks internal IDs as rendering authority;
* ACSS utility-class logic;
* vendor-specific runtime dependencies.

Source-specific facts remain provenance or adapter concerns.

---

## 5.2 Fidelity consumes Design IR, never raw Bricks

Allowed:

```text
Design IR
+
TokenSet
+
explicit external authority
→ Fidelity
```

Forbidden:

```text
Fidelity
→ Bricks JSON
```

Forbidden:

```text
Fidelity
→ Stage A artifacts as compiler input
```

Stage A remains comparison/evidence only.

---

## 5.3 Unknown remains a legitimate state

Never convert unknown evidence into plausible output merely to complete a conversion.

Examples:

```text
"400"
→ do not invent px
```

```text
unresolved CSS variable
→ do not substitute unrelated semantic token
```

```text
missing asset URI
→ do not fabricate one
```

```text
missing breakpoint
→ do not assume vendor defaults
```

---

## 5.4 Generated truth and verification truth are separate

Generator lifecycle may prove:

```text
input validated
render plan built
HEEx generated
CSS generated
manifest generated
serialized
```

It MUST NOT claim:

```text
browser rendered
visual match verified
accessibility passed
accepted
```

unless an external verification workflow actually performed those actions.

---

## 5.5 Fidelity is not native componentization

Fidelity asks:

> what did the source actually intend?

Native componentization asks:

> how should this become a reusable Phoenix API?

These remain separate compiler stages.

---

## 5.6 No source-specific responsive assumptions in generic Fidelity

Forbidden:

```text
tablet_portrait = 991
mobile_portrait = 478
```

inside generic Fidelity code.

Required architecture:

```text
source evidence
        ↓
BreakpointAuthority
        ↓
ResponsiveOverride
        +
authority
        ↓
ResponsiveResolution
        ↓
generic Fidelity serializer
```

The generic renderer understands numeric media semantics, not Bricks conventions.

---

# 6. Revised Execution Sequence

The approved order is:

```text
PR #7 breakpoint authority
        ↓
MERGE
        ↓
P5-H0 Repository Truth & Provenance Governance
        ↓
P5-H1 Fidelity CSS Serialization Safety
        ↓
Phase 5B Responsive Generation
        ↓
Phase 5C Fidelity Acceptance Gate
        ↓
P5-H2 Lifecycle Hardening
        ↓
Phase 6 Native Hero Componentization
        ↓
Phase 6.5 Second Tracer Bullet
        ↓
Catalogue Expansion
```

Do not reorder these without explicit architecture review.

---

# 7. P5-H0 — Repository Truth & Provenance Governance

## 7.1 Objective

Bring public repository state, status documentation, source provenance, and fixture policy back into internal agreement before more source material is introduced.

This is a governance/truthfulness slice, not a compiler-feature slice.

The durable provenance/publication policy and current-status register are
canonical in [`docs/04_SOURCE_AND_PROVENANCE.md`](04_SOURCE_AND_PROVENANCE.md).
This document is the active Phase 5 execution authority and adopts that policy
for P5-H0; the two documents must remain consistent.

---

# 8. P5-H0A — README and Status Truth

The pre-P5-H0 root README represented an obsolete Phase 3-era repository.
P5-H0 must leave it as a concise current-state index rather than a frozen
historical status document.

## Required changes

* [ ] update current phase
* [ ] state Phase 0–5A completion truthfully
* [ ] state current Phase 5B/authority status
* [ ] state Master Phase 5 remains OPEN
* [ ] remove claims that Bricks parsing has not begun
* [ ] remove claims that HEEx generation has not begun
* [ ] accurately describe Design IR → Fidelity pipeline
* [ ] identify Master Spec as architecture authority
* [ ] identify this document as Phase 5 hardening/acceptance authority
* [ ] distinguish completed work from planned work
* [ ] keep README concise
* [ ] do not duplicate detailed phase acceptance criteria

### README invariant

README is navigation/status truth.

README is not architecture authority.

---

# 9. P5-H0B — Public Repository Provenance Contradiction

Before P5-H0, repository policy contained an internal contradiction.

The fixture index described inputs as reviewed and repository-safe, while
source provenance for key fixtures recorded:

```text
license = unknown
project use = unknown
redistribution = unknown
```

At the same time, the repository is public.

This document makes **no legal determination** about those files.

The remaining issue is that existing public material still has unresolved
redistribution status; its public location does not establish permission.

This section makes no permission determination. Use the canonical provenance
policy for the separate internal-use and redistribution facts, publication
states, transition guards, terminal invariants, source-location boundaries,
and existing-material governance register.

---

# 10. Source Publication State Machine

Every source artifact with meaningful provenance MUST use explicit publication states.

Required lifecycle:

```text
discovered
→ classified
→ internal_use_approved
→ redistribution_review
→ public_safe
```

Alternative terminal states:

```text
private_only
rejected
removed_from_active_use
```

## 10.1 discovered → classified

Guard:

* source identity is identifiable;
* origin is recorded where known;
* source system is recorded;
* vendor/author is recorded where known;
* license status is recorded;
* internal-use status is recorded;
* redistribution status is recorded.

Unknown is acceptable when it is explicitly recorded.

Side effects:

* record source system;
* origin;
* vendor/author if known;
* license status;
* internal-use status;
* redistribution status.

## 10.2 classified → internal_use_approved

Guard:

internal use is explicitly permitted under project policy for the recorded
scope. Possession of the file is not authority.

## 10.3 internal_use_approved → redistribution_review

Guard:

artifact has an explicit intent to be evaluated for a public repository or
release.

## 10.4 redistribution_review → public_safe

Guard:

redistribution is explicitly cleared. Unknown is insufficient.

Terminal for public distribution:

`public_safe`

## 10.5 Eligible state → private_only

Guard:

internal/reference retention may continue while redistribution is not
established.

## 10.6 Any state → rejected

Guard:

source is determined unusable under project authority.

For publication decisions, `public_safe`, `private_only`, and `rejected` are
terminal until explicit new evidence triggers re-review. `removed_from_active_use`
is terminal for active inputs; historical provenance may remain recorded.
Never silently transition unknown redistribution to `public_safe`, and never
use unqualified “reviewed” as a publication state.

---

# 11. Public Repository Source Invariant

For future material:

```text
redistribution != explicitly_allowed
        ↓
MUST NOT enter public fixtures/ or public sources/
```

This applies to:

* vendor exports;
* commercial plugin source;
* licensed design packs;
* source screenshots;
* source assets;
* private client material;
* copied proprietary CSS/JS;
* future Figma/Webflow exports.

---

# 12. Recommended Source Layout

Long-term target:

```text
private_reference/
    actual vendor/plugin evidence
    actual licensed/private exports
    local environment evidence
    confidential source material

fixtures/
    synthetic fixtures
    sanitized fixtures
    explicitly redistribution-cleared fixtures

sources/
    only source material explicitly suitable for repository distribution

sources/work/
    deterministic derived artifacts
```

---

# 13. Human Decision Required for Existing Public Material

The coding agent MUST NOT independently choose among:

1. changing repository visibility;
2. deleting existing public source material;
3. rewriting Git history;
4. declaring material legally redistributable;
5. replacing evidence with synthetic fixtures where doing so changes existing provenance truth.

Those are human/project-owner decisions.

## Agent STOP condition

If P5-H0 reaches a point where progress requires one of those decisions:

```text
STOP
```

Return:

* exact files affected;
* current provenance state;
* possible options;
* consequences of each;
* no legal conclusion.

---

# 14. P5-H0 Success Criteria

P5-H0 is complete when:

* [ ] README matches current repository reality
* [ ] repository source policy is explicit
* [ ] no new unknown-redistribution material may be added publicly
* [ ] existing contradiction is documented
* [ ] human decision points are explicit
* [ ] agent does not make licensing decisions
* [ ] no compiler behavior changes
* [ ] Design IR unchanged
* [ ] TokenSet unchanged
* [ ] all tests remain green

---

# 15. P5-H1 — Fidelity CSS Serialization Safety

## 15.1 Objective

Establish one strict safety boundary immediately before CSS serialization.

The current architecture filters CSS values, but generic CSS property names are not yet sufficiently constrained.

A validated Design IR must not be safe only because it happened to originate from the current Bricks adapter.

The final invariant must be:

```text
validated generator input
        ↓
declaration validation
        ↓
safe CSS serialization
```

---

# 16. Declaration Sources

The Fidelity CSS serializer currently receives declarations from multiple paths:

```text
Design IR styles
source fidelity resolver declarations
complex CSS handling
pseudo-state declarations
future responsive declarations
```

All paths MUST converge through the same safe serialization boundary.

---

# 17. CSS Declaration Model

A serializable declaration conceptually contains:

```text
property
value
selector/state context
source/provenance
```

Each element must be independently validated.

---

# 18. CSS Declaration Lifecycle

```text
received
→ validated
→ accepted
→ serialized
```

Exceptional terminal:

```text
rejected
```

## received → validated

Guards:

* property syntax safe;
* value safe under supported policy;
* selector/state syntax supported;
* no structural CSS escape;
* declaration type supported.

## validated → accepted

Guard:

declaration belongs to a supported current fidelity capability.

## accepted → serialized

Guard:

deterministic serializer can emit it.

## any active → rejected

Guard:

declaration cannot be represented safely.

Rejected declarations produce diagnostics.

They must never silently disappear without evidence.

---

# 19. CSS Property Safety

Required:

* [ ] CSS property must use conservative valid property syntax
* [ ] custom properties may be handled only if deliberately supported
* [ ] property cannot contain `{`
* [ ] property cannot contain `}`
* [ ] property cannot contain `;`
* [ ] property cannot contain `:`
* [ ] property cannot terminate a declaration
* [ ] property cannot inject another selector
* [ ] malformed properties produce deterministic diagnostics
* [ ] adversarial regression test exists

Do not build a full CSS parser for this slice.

Use the smallest conservative rule that supports the proven Hero property set.

---

# 20. SourceResolver Declaration Safety

A source resolver is not automatically trusted merely because it is a project module.

Before serialization validate:

* [ ] resolver property
* [ ] resolver value
* [ ] resolver pseudo selector
* [ ] resolver declaration type
* [ ] resolver output shape

Current required pseudo-state surface is narrow.

Examples currently proven:

```text
:hover
:focus-visible
```

Do not create a general arbitrary-selector language.

---

# 21. IR Contract Rule

P5-H1 should protect the generator boundary without silently changing Design IR `1.0.0`.

If tightening `IR.validate/1` would alter the frozen public IR contract:

```text
STOP
```

Report:

* proposed validation change;
* compatibility impact;
* whether IR version decision is required.

Generator safety can be fixed independently.

---

# 22. Custom CSS Safety

Current custom CSS is known, reviewed Hero evidence.

For arbitrary future imports, deny-list filtering is not sufficient isolation.

A future imported stylesheet may be syntactically safe while containing broad selectors such as:

```text
body
html
:root
*
main
```

which could affect the preview environment.

## Direction

Before arbitrary/unreviewed source CSS is supported, fidelity rendering SHOULD use an explicit isolation boundary.

Preferred architectural direction:

```text
conversion lab
        ↓
isolated preview document
        ↓
source fidelity CSS
```

A sandboxed iframe or equivalent isolated document boundary is preferred over attempting to perfectly rewrite arbitrary source selectors.

This is not required to block the reviewed Hero fixture.

It becomes mandatory before arbitrary second-party source CSS is rendered.

---

# 23. P5-H1 Required Tests

* [ ] malicious property name rejected
* [ ] semicolon injection rejected
* [ ] brace injection rejected
* [ ] selector injection through property rejected
* [ ] safe normal property accepted
* [ ] approved custom property behavior explicitly tested if supported
* [ ] resolver malicious property rejected
* [ ] resolver unsupported selector rejected
* [ ] supported `:hover` accepted
* [ ] supported `:focus-visible` accepted
* [ ] unsafe value regression remains rejected
* [ ] existing Hero output remains deterministic
* [ ] existing Phase 5A output does not regress unexpectedly

---

# 24. P5-H1 STOP Conditions

STOP if:

* safe serialization requires broad CSS parsing;
* Design IR `1.0.0` must change;
* approved Hero declarations cannot pass a conservative policy;
* source resolver must become vendor-specific in generic Fidelity;
* deterministic generation breaks;
* existing tests regress.

Do not broaden scope.

---

# 25. Phase 5B — Responsive Generation

## 25.1 Objective

Use committed breakpoint authority to resolve the four current Hero ResponsiveOverrides without changing frozen Design IR.

---

# 26. Responsive Domain Model

Recommended generic concepts:

```text
LiveFrames.Responsive.BreakpointAuthority
LiveFrames.Responsive.Resolution
```

Avoid:

```text
LiveFrames.Bricks.TabletBreakpoint
```

inside generic layers.

---

# 27. BreakpointAuthority

Represents accepted external numeric semantics.

Fields conceptually include:

```text
source_name
min_width
max_width
unit
query_semantics
media_condition
authority_type
authority_level
evidence_hash
status
```

This is compiler/reference data.

Not a database resource.

---

# 28. ResponsiveResolution

Represents:

```text
ResponsiveOverride
+
BreakpointAuthority
→ resolved media-query instruction
```

It preserves:

* node identity;
* original source breakpoint name;
* accepted numeric semantics;
* authority reference;
* raw source value;
* generated CSS target;
* status.

---

# 29. Responsive Resolution State Machine

```text
authority_missing
→ authority_bound
→ value_validated
→ resolved
→ serialized
```

Exceptional terminal:

```text
blocked
rejected
failed
```

## authority_missing → authority_bound

Guard:

an accepted authority entry exists for the exact source breakpoint identity.

## authority_bound → value_validated

Guard:

responsive StyleValue can be emitted safely.

## value_validated → resolved

Guard:

media semantics are unambiguous.

## resolved → serialized

Guard:

deterministic media-query serialization succeeds.

Never:

```text
authority_missing → resolved
```

through convention or defaults.

---

# 30. Current Hero Responsive Overrides

Exactly four current entries are in scope.

## 30.1 Mobile CTA

Node:

```text
node_000001_000001_000003
```

Authority:

```text
@media (max-width: 478px)
```

Rule:

```text
.fr-cta-links-alpha > * {
  width: 100% !important;
}
```

## 30.2 Tablet image object-fit

Node:

```text
node_000001_000002_000001
```

Authority:

```text
@media (max-width: 991px)
```

Value:

```text
object-fit: cover
```

## 30.3 Tablet image object-position

Same node.

Value:

```text
object-position: 50% 50%
```

## 30.4 Tablet responsive gradient

Node:

```text
node_000001_000002_000002
```

Authority:

```text
@media (max-width: 991px)
```

Structured responsive gradient must preserve:

* type;
* angle;
* colors;
* alpha;
* stop order;
* stop values.

---

# 31. Responsive Cascade Invariant

Media order MUST be deterministic.

Current expected ordering:

```text
base
@media (max-width: 991px)
@media (max-width: 478px)
```

At `478px` and below:

```text
tablet rules
+
mobile rules
```

must both match.

Regression tests MUST explicitly protect this.

---

# 32. Phase 5B Manifest Truth

After successful resolution:

```text
responsive_entries_total = 4
responsive_entries_resolved = 4
responsive_entries_deferred_for_authority = 0
invented_breakpoints = 0
```

Manifest must record:

* [ ] breakpoint authority schema
* [ ] authority hash
* [ ] authority level/type
* [ ] source names consumed
* [ ] generated media conditions
* [ ] resolved count
* [ ] deferred count
* [ ] invented count
* [ ] asset state
* [ ] deterministic CSS hash

Generator lifecycle remains terminal at:

```text
serialized
```

---

# 33. Phase 5B Boundary Verification

Required browser boundary matrix:

## Desktop

A width greater than `991px`.

Expected:

```text
tablet inactive
mobile inactive
```

## Tablet boundary

```text
992
991
990
```

Expected:

```text
992 → tablet inactive
991 → tablet active
990 → tablet active
```

## Mobile boundary

```text
479
478
477
```

Expected:

```text
479 → mobile inactive
478 → mobile active
477 → mobile active
```

At all three mobile test widths:

```text
tablet also active
```

because each is below `991px`.

---

# 34. Asset Resolution During Phase 5

Current Hero asset:

```text
asset_000001
attachment 880
cordallman-man-8493246_1920.webp
```

Filename alone is not enough to resolve it.

---

# 35. Asset State Machine

```text
unresolved
→ evidence_found
→ verified
→ resolved
```

Exceptional terminal:

```text
unavailable
rejected
```

## unresolved → evidence_found

Guard:

actual candidate source asset exists.

## evidence_found → verified

Guards:

* source identity matches;
* attachment/provenance matches;
* file hash known;
* project-use policy allows use.

## verified → resolved

Guard:

asset can be used deterministically by fidelity output.

Filename alone MUST NOT transition state.

---

# 36. Asset Acceptance Rule

If the actual Hero image remains unresolved:

Phase 5 may truthfully claim:

```text
structural fidelity verified
responsive rule behavior verified
image fidelity unavailable
```

It MUST NOT claim:

```text
full visual fidelity verified
```

without an explicit acceptance/waiver authority.

The coding agent cannot create that waiver.

---

# 37. Phase 5C — Fidelity Acceptance Gate

## 37.1 Objective

Separate responsive generation from actual product-level fidelity acceptance.

Phase 5B proves responsive compiler behavior.

Phase 5C proves whether Hero India actually passes the Master Phase 5 gate.

---

# 38. Verification State Machine

```text
generated
→ compiled
→ rendered
→ browser_verified
→ visual_compared
→ accessibility_verified
→ runtime_clean
→ accepted
```

Exceptional:

```text
failed
blocked
needs_review
```

---

# 39. generated → compiled

Guard:

normal Mix compilation succeeds with warnings treated as errors.

---

# 40. compiled → rendered

Guard:

preview route renders successfully.

---

# 41. rendered → browser_verified

Guards:

* desktop viewport verified;
* tablet viewport verified;
* mobile viewport verified;
* breakpoint boundaries verified;
* responsive cascade verified.

---

# 42. browser_verified → visual_compared

Guard:

authoritative source visual reference exists.

If no authoritative reference exists:

transition cannot occur.

Record:

```text
blocked
```

or remain prior state according to implementation model.

Do not invent source reference authority.

---

# 43. visual_compared → accessibility_verified

Guard:

agreed visual tolerance passes or all deviations are explicitly accepted under existing authority.

---

# 44. accessibility_verified → runtime_clean

Required minimum checks:

* no critical accessibility violations;
* semantic structure acceptable;
* button accessibility;
* keyboard/focus behavior applicable to current component;
* no obvious contrast/label failure introduced by generated implementation.

---

# 45. runtime_clean → accepted

Guards:

* browser console errors = 0;
* LiveView/runtime errors = 0;
* required acceptance evidence complete;
* unresolved limitations explicitly accepted under project authority.

Terminal:

`accepted`

Only this state closes Master Phase 5.

---

# 46. Visual Reference Authority

Preferred source hierarchy:

1. actual DanBricks source environment at matching viewport;
2. deterministic screenshot from an isolated restored copy of the source environment;
3. approved provenance-linked source screenshot;
4. other explicitly accepted reference.

Not acceptable:

* memory;
* random internet screenshots;
* unrelated Frames examples;
* approximations;
* generated LiveFrames output compared with itself.

---

# 47. Source Environment Safety

Starting or rendering DanBricks for reference MUST NOT mutate source evidence.

STOP if source rendering requires:

* WordPress upgrade;
* Bricks migration;
* plugin update;
* theme update;
* content save;
* breakpoint save;
* database migration;
* destructive restore.

An isolated copy may be used only through an existing safe restoration workflow.

---

# 48. Visual Verification Matrix

Required where reference evidence exists:

* [ ] desktop screenshot
* [ ] tablet screenshot
* [ ] mobile screenshot
* [ ] matching viewport dimensions
* [ ] layout structure
* [ ] spacing
* [ ] typography
* [ ] button styling
* [ ] background
* [ ] gradient
* [ ] CTA arrangement
* [ ] image placement if resolved
* [ ] responsive transitions
* [ ] known differences documented

Do not hide unresolved differences.

---

# 49. Accessibility Gate

Phase 5C must include accessibility as acceptance, not optional polish.

Required minimum:

* [ ] automated accessibility scan if existing tooling supports it
* [ ] semantic heading structure check
* [ ] interactive element semantics
* [ ] keyboard accessibility where applicable
* [ ] focus-visible behavior where applicable
* [ ] accessible unresolved-asset placeholder if asset unresolved
* [ ] no critical accessibility findings
* [ ] findings captured in verification evidence

Do not add a massive accessibility framework if a small existing tool can cover the gate.

---

# 50. Runtime Cleanliness Gate

Required:

* [ ] no browser console errors
* [ ] no uncaught JS errors
* [ ] no LiveView runtime errors
* [ ] no missing required CSS assets
* [ ] preview HTTP success
* [ ] generated CSS loads
* [ ] no polling
* [ ] no unexpected network dependency

---

# 51. Verification Artifact

Recommended:

```text
sources/work/hero_india/fidelity/verification.json
```

It owns external verification truth.

Required content:

* Design IR hash
* TokenSet version
* breakpoint authority hash
* HEEx hash
* CSS hash
* manifest hash
* tested viewport widths
* boundary results
* asset state
* source visual-reference state
* visual-reference hashes
* visual comparison result
* accessibility result
* console/runtime result
* known limitations
* verification lifecycle
* final status

Avoid non-deterministic timestamps unless required by existing policy.

---

# 52. Master Phase 5 Definition of Done

Master Phase 5 MUST remain OPEN until all mandatory gates pass.

## Compiler

* [ ] validated Design IR input
* [ ] source-independent Fidelity core
* [ ] safe declaration serialization
* [ ] deterministic HEEx
* [ ] deterministic CSS
* [ ] deterministic manifest
* [ ] base rendering
* [ ] authority-bound responsive rendering
* [ ] 4/4 Hero responsive entries resolved
* [ ] zero invented breakpoints
* [ ] correct max-width cascade

## Asset

One of:

* [ ] source asset resolved and verified

or:

* [ ] explicit authorized acceptance of unresolved image limitation

The agent cannot grant the second condition.

## Browser

* [ ] desktop verified
* [ ] 992/991/990 verified
* [ ] 479/478/477 verified
* [ ] tablet/mobile overlap verified
* [ ] route HTTP success
* [ ] CSS loaded
* [ ] runtime errors zero

## Visual

* [ ] authoritative visual reference exists
* [ ] desktop compared
* [ ] tablet compared
* [ ] mobile compared
* [ ] tolerance accepted
* [ ] differences documented

## Accessibility

* [ ] automated accessibility pass
* [ ] semantic structure reviewed
* [ ] interactions/focus reviewed as applicable
* [ ] no critical violations

## Determinism

* [ ] IR drift green
* [ ] Stage A drift green
* [ ] Fidelity drift green
* [ ] responsive artifact drift green
* [ ] verification artifact deterministic under its contract

Only then:

```text
MASTER PHASE 5 = CLOSED
```

---

# 53. P5-H2 — Lifecycle Enforcement Hardening

## 53.1 Objective

Bring implemented lifecycle models into agreement with the project rule that lifecycle-bearing concepts explicitly define:

* states;
* transitions;
* transition guards;
* side effects;
* terminal states.

The current Bricks Result model should be hardened before its pattern is copied into future workflow concepts.

---

# 54. Bricks Result Target Lifecycle

Happy path:

```text
received
→ recognized
→ validated
→ resolved
→ tree_built
→ dependencies_extracted
→ rendered
→ verified
→ completed
```

Exceptional terminal:

```text
rejected
failed
```

---

# 55. Terminal Invariant

Once in:

```text
completed
rejected
failed
```

no further transitions are permitted.

Forbidden:

```text
completed → rejected
completed → failed
rejected → failed
failed → rejected
```

unless an explicit future recovery model is designed.

Do not introduce recovery semantics accidentally.

---

# 56. Required Lifecycle API Characteristics

Conceptually colocate:

```text
active states
terminal states
allowed transitions
transition guards
terminal?/1
```

Do not scatter lifecycle truth across unrelated functions.

---

# 57. P5-H2 Tests

* [ ] happy path valid
* [ ] invalid forward transition rejected
* [ ] skipped transition rejected
* [ ] completed terminal
* [ ] rejected terminal
* [ ] failed terminal
* [ ] completed → rejected rejected
* [ ] completed → failed rejected
* [ ] rejected → failed rejected
* [ ] failed → rejected rejected
* [ ] diagnostics preserved appropriately

---

# 58. P5-H2 Scope

Do not redesign:

* Stage A;
* Design IR;
* TokenSet;
* Fidelity;
* responsive generation.

This is a bounded lifecycle correctness slice.

---

# 59. Phase 6 Entry Criteria

Master Phase 6 MUST NOT start until:

* [ ] Master Phase 5 accepted
* [ ] P5-H0 completed or human governance decision explicitly recorded
* [ ] P5-H1 completed
* [ ] P5-H2 completed
* [ ] source asset state understood
* [ ] visual acceptance complete
* [ ] accessibility gate complete
* [ ] generated source behavior understood well enough to separate fidelity from native design

---

# 60. Phase 6 — Native Componentization Direction

Phase 6 will convert fidelity output into intentional reusable Phoenix API design.

Fidelity output may contain:

```text
source classes
source-specific naming
fidelity node classes
source-oriented layout structure
```

Native component output should instead use:

* attrs;
* slots;
* semantic naming;
* LiveFrames tokens;
* reusable public API;
* source-independent module names;
* documented behavior;
* accessibility;
* Phoenix idioms.

Do not simply clean up generated HTML and call it native.

Phase 6 is an architectural translation.

---

# 61. Tailwind Strategy

Tailwind semantic normalization belongs to native componentization or the explicitly designated later bridge.

Do not rewrite Phase 5 fidelity CSS into Tailwind merely to make generated output look cleaner.

Phase 5 owns fidelity.

Phase 6 owns idiomatic native implementation.

---

# 62. Phase 6.5 — Second Tracer Bullet / Anti-Overfitting Gate

The second converted component MUST intentionally differ structurally from Hero India.

Do not choose another near-identical Hero.

Preferred stress characteristics:

* repeated child structures;
* links;
* icons;
* multiple assets;
* grid;
* nested layout;
* different responsive patterns;
* pseudo states;
* at least one simple interaction if source evidence permits.

---

# 63. Generalization Success Test

The second tracer bullet succeeds architecturally when:

```text
source adapter extensions
        ↓
same Design IR
        ↓
same generic responsive model
        ↓
same Fidelity compiler
        ↓
same native pipeline
```

with minimal generic architecture change.

Healthy outcome:

```text
adapter grows
generic compiler stays mostly stable
```

Warning outcome:

```text
every new component forces Design IR redesign
```

If that occurs:

STOP catalogue expansion.

Review whether Hero India overfit the architecture.

---

# 64. Deferred Hardening — Explicit Input Types

Current local compiler APIs may support convenience behavior where a binary can represent either data or a filesystem path.

Before public/untrusted ingestion, prefer explicit input forms conceptually:

```text
JSON input
trusted file input
already-decoded document
```

Do not allow an arbitrary untrusted string to ambiguously become a filesystem path.

This is deferred until public/import-facing workflows are introduced.

---

# 65. Deferred Hardening — Resource Exhaustion

Before public imports, define bounded limits for:

* input bytes;
* node count;
* tree depth;
* asset count;
* responsive overrides;
* interaction count;
* custom CSS size;
* diagnostic count;
* collection sizes.

Current local compiler work does not require premature complexity here.

But public ingestion MUST NOT proceed without explicit limits.

---

# 66. Deferred Hardening — Preview Isolation

Before arbitrary unreviewed CSS/JS sources are rendered:

* [ ] isolated fidelity document boundary
* [ ] source CSS cannot style conversion-lab shell
* [ ] source JS cannot access unrelated preview state
* [ ] no network access by default where avoidable
* [ ] browser APIs explicitly classified
* [ ] source script execution never automatic

---

# 67. Deferred Hardening — Empty Application Supervisor

The reusable library currently has negligible runtime process requirements.

Before package/release work, review whether `LiveFrames.Application` needs to start a Supervisor.

Do not interrupt Phase 5 for this.

Question to resolve later:

> should the compiler/package be a pure library unless runtime services actually exist?

---

# 68. Ash / Persistence Boundary

Do NOT introduce Ash merely because LiveFrames is an Elixir project.

Current compiler concepts should remain ordinary deterministic data/functions.

Ash becomes appropriate only when actual persistent application domains exist, such as:

* accounts;
* teams/workspaces;
* stored ConversionJobs;
* approvals;
* catalogue publishing workflow;
* marketplace entries;
* licenses;
* saved remote projects;
* persistent import histories.

Do not turn Design IR or TokenSet into Ash resources.

---

# 69. Performance & Scaling Review

LiveFrames Phase 5 is compiler/static work.

Therefore the generic platform performance architecture is classified as follows:

```text
Postgres           N/A
Redis              N/A
ETS                N/A
GenServer          N/A
Oban               N/A
Phoenix PubSub      N/A
PgBouncer          N/A
read replicas      N/A
runtime cache       N/A
browser storage    N/A
```

Do not introduce runtime infrastructure to satisfy requirements that do not apply to this domain.

---

# 70. Relevant Performance Requirements

For compiler work:

* [ ] deterministic traversal
* [ ] bounded tree traversal
* [ ] avoid repeated whole-document scans where a map lookup suffices
* [ ] token lookup by map/key
* [ ] breakpoint authority lookup by map/key
* [ ] no mutable global state
* [ ] safe concurrent future conversions
* [ ] no request-time DB
* [ ] no request-time network
* [ ] no polling
* [ ] generated files deterministic
* [ ] browser verification performed only at acceptance boundary

Before public imports:

* [ ] input-size caps
* [ ] node/depth caps
* [ ] memory behavior reviewed

---

# 71. Risk Register

| Risk                                       |                Severity | Current action                     |
| ------------------------------------------ | ----------------------: | ---------------------------------- |
| public fixture redistribution unknown      |     Critical governance | P5-H0                              |
| stale README/project status                |       High truthfulness | P5-H0                              |
| unsafe CSS property serialization          |           High security | P5-H1                              |
| source resolver declaration injection      |           High security | P5-H1                              |
| custom CSS preview escape                  | Medium now / High later | isolation before arbitrary sources |
| breakpoint hard-coding in generic compiler |       High architecture | Phase 5B invariant                 |
| responsive cascade mis-modeled             |           High fidelity | Phase 5B tests                     |
| unresolved Hero asset                      |         High acceptance | Phase 5B/5C                        |
| visual gate absent                         |         High acceptance | Phase 5C                           |
| accessibility gate absent                  |    High product quality | Phase 5C                           |
| lifecycle terminal states weak             |     Medium architecture | P5-H2                              |
| Design IR contract changed casually        |      High compatibility | STOP/version decision              |
| Hero overfitting                           |           High strategy | Phase 6.5                          |
| public file/path ambiguity                 |  Medium future security | pre-import hardening               |
| resource exhaustion                        |  Medium future security | pre-import hardening               |
| empty Supervisor                           |                     Low | pre-package cleanup                |
| premature Ash/runtime infra                |       Medium complexity | explicitly avoid                   |
| premature Figma/Webflow support            |         High focus risk | defer                              |
| premature catalogue expansion              |         High focus risk | defer                              |

---

# 72. Scope Explicitly Forbidden Until Phase 5 Closes

Do NOT begin:

* Figma adapter
* Webflow adapter
* Framer adapter
* marketplace
* billing
* auth
* database-backed catalogue
* persistent conversion jobs
* Tailwind-native Hero rewrite
* native Hero attrs/slots
* Hero Storybook production item
* public component catalogue expansion
* bulk source conversion
* hundreds of components
* runtime AI conversion orchestration
* general CSS parser
* general JS runtime
* Ash
* Redis
* Oban
* Postgres

---

# 73. Testing Strategy

The testing ladder should evolve deliberately.

## Existing strong layer

* unit tests
* integration tests
* drift tests
* compile warnings-as-errors
* deterministic artifacts

## Add during current hardening

### P5-H1

* adversarial CSS serialization tests

### Phase 5B

* responsive mapping tests
* cascade tests
* media-boundary browser tests

### Phase 5C

* visual screenshots/comparison
* accessibility
* runtime console errors

### Later public imports

* property/fuzz tests
* resource-exhaustion tests
* input-size/depth limits

Do not add every possible quality tool simultaneously.

---

# 74. Required Local Gates for Implementation Slices

Where relevant:

```text
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix assets.build
mix test
mix deps.unlock --check-unused
git diff --check
```

Plus slice-specific:

* drift verification
* authority validation
* browser verification
* accessibility verification
* visual comparison

Do not run browser gates before basic compiler/test gates pass.

---

# 75. Git / PR Discipline

Every implementation slice MUST:

1. start from synchronized clean `main`;
2. record exact baseline SHA;
3. use a fresh narrowly named branch;
4. implement exactly one architectural responsibility;
5. run local gates;
6. push;
7. open PR;
8. run exact-head CI;
9. STOP;
10. wait for review/explicit merge authority.

Do not merge automatically.

---

# 76. Recommended Branches

After breakpoint authority is merged:

```text
docs/phase-5-h0-repository-truth
```

or:

```text
hardening/phase-5-h0-repository-truth
```

Then:

```text
hardening/phase-5-h1-css-serialization
```

Then:

```text
feature/phase-5b-responsive-fidelity
```

Then:

```text
feature/phase-5c-fidelity-acceptance
```

Then:

```text
hardening/phase-5-h2-lifecycle-enforcement
```

Then Phase 6 separately.

Keep one purpose per PR.

---

# 77. Recommended PR Titles

```text
Phase 5 H0: align repository truth and provenance policy
```

```text
Phase 5 H1: harden fidelity CSS serialization
```

```text
Phase 5B: generate authority-bound responsive fidelity
```

```text
Phase 5C: verify Hero fidelity and accessibility
```

```text
Phase 5 H2: enforce Bricks lifecycle terminal states
```

---

# 78. Agent Tool Policy

Use the least amount necessary.

## Documentation/governance

Allowed:

* filesystem
* shell
* Git
* GitHub

Conditional:

* repository metadata inspection

Do not use browser/database unless provenance investigation specifically requires existing evidence.

## Compiler hardening

Allowed:

* filesystem/code inspection
* shell
* Git
* Mix/Elixir
* GitHub

## Responsive generation

Allowed:

* filesystem
* shell
* Git
* Mix
* committed breakpoint authority
* GitHub
* browser at verification boundary

## Acceptance

Allowed:

* browser/Playwright where already available
* source environment read-only
* accessibility tooling already available or minimally introduced

Do not introduce unrelated infrastructure.

---

# 79. Global STOP Conditions

The coding agent must STOP whenever:

* repository baseline is not clean/synchronized;
* required preceding PR is unmerged;
* authority evidence is missing;
* a value must be guessed;
* Design IR contract must change unexpectedly;
* TokenSet contract must change unexpectedly;
* licensing/legal judgment is required;
* repo visibility must change;
* Git history must be rewritten;
* source data must be deleted from history;
* source environment requires mutation;
* CSS safety requires a broad parser;
* asset URI must be fabricated;
* visual equivalence requires unsupported evidence;
* acceptance requires inventing a waiver;
* existing tests regress;
* deterministic artifacts drift unexpectedly;
* phase scope starts expanding into native componentization.

On STOP return:

1. exact blocker;
2. file/module/artifact;
3. current state;
4. attempted transition/action;
5. why guard failed;
6. options available;
7. which option requires human authority.

Do not guess.

---

# 80. Master Checklist

## Authority

* [x] PR #7 merged
* [x] `main` synchronized
* [x] breakpoint artifact committed
* [x] `478px max-width` proven
* [x] `991px max-width` proven
* [x] Level 3 classification retained
* [x] cascade invariant retained

## P5-H0

* [ ] README corrected
* [ ] current phase truthful
* [ ] public source policy explicit
* [ ] fixture policy explicit
* [ ] no new unknown-rights public fixtures
* [ ] human governance decisions identified
* [ ] no licensing conclusion invented

## P5-H1

* [ ] declaration serializer boundary exists
* [ ] property validation exists
* [ ] resolver property validation exists
* [ ] selector validation exists
* [ ] adversarial tests exist
* [ ] IR `1.0.0` unchanged unless separate decision
* [ ] Hero generation deterministic

## Phase 5B

* [ ] source-neutral authority reader
* [ ] source-neutral responsive resolution
* [ ] no Bricks values hard-coded generically
* [ ] 4 responsive entries total
* [ ] 4 resolved
* [ ] 0 authority deferred
* [ ] 0 invented
* [ ] tablet media condition exact
* [ ] mobile media condition exact
* [ ] max-width overlap preserved
* [ ] media ordering deterministic
* [ ] CSS drift pass
* [ ] manifest truthful

## Asset

* [ ] attachment 880 audited
* [ ] actual asset resolved OR explicit unavailable
* [ ] hash recorded if resolved
* [ ] provenance recorded
* [ ] no fabricated URI

## Phase 5C Browser

* [ ] desktop verified
* [ ] 992 verified
* [ ] 991 verified
* [ ] 990 verified
* [ ] 479 verified
* [ ] 478 verified
* [ ] 477 verified
* [ ] tablet active at mobile widths
* [ ] CSS loaded
* [ ] HTTP success
* [ ] no console errors

## Phase 5C Visual

* [ ] authoritative source reference
* [ ] desktop source screenshot/reference
* [ ] tablet source screenshot/reference
* [ ] mobile source screenshot/reference
* [ ] visual comparison complete
* [ ] differences documented
* [ ] tolerance accepted

## Accessibility

* [ ] automated accessibility
* [ ] semantic headings
* [ ] button semantics
* [ ] keyboard/focus
* [ ] no critical violations

## Verification

* [ ] `verification.json`
* [ ] hashes recorded
* [ ] lifecycle truthful
* [ ] asset limitation truthful
* [ ] deterministic evidence

## Lifecycle

* [ ] active states explicit
* [ ] terminal states explicit
* [ ] completed terminal
* [ ] rejected terminal
* [ ] failed terminal
* [ ] invalid transitions tested

## Phase 6 entry

* [ ] Master Phase 5 CLOSED
* [ ] H0 resolved
* [ ] H1 resolved
* [ ] H2 resolved
* [ ] no unresolved acceptance blocker
* [ ] native componentization explicitly authorized

---

# 81. What Success Looks Like

At the end of this plan, LiveFrames should be able to make the following statement truthfully:

> Hero India has been deterministically reconstructed through the source adapter, normalized into the frozen Design IR and TokenSet contracts, generated through a source-independent and serialization-safe Fidelity compiler, resolved against provenance-backed responsive authority, rendered correctly across source breakpoint boundaries, compared against an authoritative visual reference, checked for accessibility and runtime errors, and accepted without invented source facts.

Only after that statement is defensible should Phase 6 begin.

---

# 82. Strategic Success After Phase 6

The project is not considered generally proven after one Hero.

After native Hero componentization, a second structurally different component must pass through the same architecture.

The desired result is:

```text
new source complexity
        ↓
adapter extensions
        ↓
existing generic IR
        ↓
existing generic compiler
```

If that succeeds, LiveFrames has demonstrated the first meaningful evidence that it is a general design compiler.

Only then should component catalogue breadth accelerate.

---

# 83. Final Decision Summary

## Keep

* Design IR
* TokenSet
* source adapters
* deterministic drift
* source-independent Fidelity
* unresolved-as-truth
* fidelity-before-native
* explicit provenance
* exact lifecycle modeling
* narrow PRs
* compiler/static architecture

## Harden now

* repository/status truth
* provenance governance
* CSS serialization boundary
* responsive authority consumption
* responsive cascade
* visual acceptance
* accessibility
* lifecycle terminal enforcement

## Defer

* Figma/Webflow
* public ingestion
* resource limits until ingestion phase
* full preview isolation until arbitrary sources
* Ash
* database
* Redis
* Oban
* catalogue breadth
* empty Supervisor cleanup until package/release preparation

## Do not compromise

* never guess unknown source facts
* never claim verification that did not happen
* never let generic compiler layers silently acquire source-specific semantics
* never allow a terminal lifecycle state to transition without explicit design
* never declare Master Phase 5 complete because generated HTML merely looks plausible
* never expand breadth before the second tracer bullet proves generality

---

# 84. Next Execution Action

After this document is reviewed and accepted:

1. synchronize `main` and confirm the reviewed breakpoint-authority artifact remains present;
2. execute the plan one narrow slice at a time;
3. begin with P5-H0;
4. do not begin Phase 5B implementation until P5-H0 and P5-H1 have passed.

STOP.
