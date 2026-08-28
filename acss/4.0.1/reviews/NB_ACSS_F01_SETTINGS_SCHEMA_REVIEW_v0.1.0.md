# NovaBase — F01 Settings Schema Review

**Document ID:** NB-REV-F01-001  
**Version:** 0.1.0  
**Status:** Review Complete  
**Date:** 2026-08-20  
**Reviewed task:** F01 — Settings Schema  
**Reviewed branch:** `nb000-f01-settings`  
**Reviewed commit:** `bacc98cdc40360a8eaa64693302c9e050e23e46b`  
**Reference:** Automatic.css 4.0.1  
**Verdict:** **ACCEPT WITH NON-BLOCKING NOTES**

---

## 1. Review Scope

This review independently challenged the F01 Settings Schema research against the ACSS 4.0.1 reference corpus.

Reviewed deliverables:

```text
research/acss/4.0.1/foundations/settings/
├── NB_ACSS_SETTINGS_SCHEMA_SPEC_v0.1.0.md
├── NB_ACSS_SETTINGS_SCHEMA_SOURCE_MAP_v0.1.0.md
└── acss-settings-map.json
```

The branch was also compared with `main` to verify scope discipline.

The review focused on the highest-risk claims:

- canonical settings declaration;
- UI flattening and recognised setting types;
- declared-input counts;
- persistence boundaries;
- settings-to-generation mapping;
- `scssVariable` / setting-ID behaviour;
- `cssVariable` preview semantics;
- unit transformation;
- colour expansion;
- import/export versioning;
- legacy aliases;
- unresolved items and cross-foundation handoffs;
- machine-readable settings-map structure and provenance.

---

## 2. Verdict

# ACCEPT WITH NON-BLOCKING NOTES

No blocker or major defect was found.

The submitted work is sufficiently evidence-backed and appropriately scoped to serve as accepted F01 foundation research after normal integration governance.

The four unresolved items are legitimate boundaries or deferred research, not hidden F01 failures.

The review found one terminology precision note in the agent's **chat handoff**, but the repository artefacts themselves make the correct distinction.

---

## 3. Summary

F01 establishes a credible model of ACSS 4.0.1 settings as a layered system rather than a flat settings file.

The research correctly distinguishes:

```text
UI/config declaration
    ↓
runtime flattening
    ↓
persistence/validation
    ↓
generation metadata
    ↓
transformers
    ↓
SCSS/internal generation
```

and separately identifies the dashboard/live-preview `cssVariable` channel.

The source map is structured around stable finding IDs and correctly marks unresolved areas rather than silently inferring them.

The machine-readable map records source provenance, aggregate counts, architecture metadata, screens, settings metadata, aliases, flags, and related evidence required by later foundation/domain work.

---

## 4. Blockers

**Count: 0**

None.

---

## 5. Major Findings

**Count: 0**

None.

---

## 6. Minor Findings

**Count: 0**

None requiring correction to the submitted artefacts.

---

## 7. Notes

### NOTE-001 — Use precise wording for the 1,599 count

The agent's final chat response states:

```text
1599 UI-declared settings mapped
```

The research artefacts themselves are more precise:

```text
1,599 UI-declared inputs
1,594 recognised/persistable setting inputs
5 clone UI-only inputs
```

`clone` inputs are not recognised by `UI::is_setting()` as persistable settings.

Therefore future summaries should say:

> **1,599 UI-declared inputs, of which 1,594 are recognised/persistable settings and 5 are clone UI-only inputs.**

No change to the F01 spec or machine map is required because they already preserve this distinction.

---

### NOTE-002 — The settings map is not a conventional fixture set

The F01 handoff reports:

```text
FIXTURES: 1
```

The manifest actually requires:

```text
acss-settings-map.json
```

This is a machine-readable research map and contains deterministic structural vectors, but it should not be confused with the dedicated fixture sets expected from formula-heavy foundation/domain tasks.

Recommended review terminology:

```text
MACHINE MAPS VERIFIED: 1
DETERMINISTIC STRUCTURAL VECTORS: present
```

No repository correction is required.

---

### NOTE-003 — Full machine map was structurally reviewed, not exhaustively manually re-derived record-by-record

The map is large and contains the complete settings inventory. The review checked its metadata, counts, provenance model, architecture sections, representative records/structures, and consistency with independently inspected source behaviour.

The review did not manually re-derive all 1,599 records one by one.

That is appropriate for this review because:

- the source-map architecture was independently checked;
- aggregate counts were independently checked during review;
- no duplicate-ID issue was identified;
- representative transformer and persistence claims were checked directly against source;
- deterministic machine generation is more reliable here than manual transcription.

Future automated parity tooling should consume the map and provide ongoing schema validation.

---

## 8. Formula / Transformation Verification

### 8.1 UnitTransformer

**Verified.**

F01 correctly records the relevant transformation sequence.

Important behaviour includes:

- unit may come from explicit options or control type;
- `px` values are divided by 10 unless conversion is skipped;
- percent values receive `%` when necessary;
- `percentage-convert` uses the 62.5 root-font baseline relative to the supplied root font size;
- `appendunit` is applied separately after the main transformation step.

F01's deterministic vector:

```text
30 px → 3 before append
```

is correct.

The research appropriately hands deeper shared formula semantics to F02/F03 rather than treating F01 as the formula authority.

---

### 8.2 Settings → generation mapping

**Verified.**

The F01 report correctly identifies that backend generation uses the setting metadata and generation pipeline rather than simply treating dashboard CSS-variable metadata as the canonical SCSS key.

The default generation-key relationship is appropriately represented as:

```text
setting ID
    ↓
SCSS/internal generation key
```

unless an explicit variable override applies.

---

### 8.3 `cssVariable` vs generation key

**Verified.**

F01 correctly treats `cssVariable` as part of the dashboard/live-preview channel rather than assuming that it is necessarily the backend SCSS-generation identifier.

This distinction is important and should be inherited by F03 and F04.

---

### 8.4 Colour expansion

**Verified at F01-required depth.**

The runtime source establishes that colour settings are special-cased and expand into additional generated values.

F01 does not claim that all resulting colour entities are directly declared as individual dashboard settings.

The exhaustive expanded colour-token inventory is correctly deferred.

---

## 9. Machine Map Verification

### 9.1 Provenance

**PASS**

The map identifies:

```text
product: Automatic.css
version: 4.0.1
research task: F01
reference path
settings option key
database-version option key
```

This is sufficient provenance for the current research phase.

---

### 9.2 Aggregate counts

**PASS**

The map explicitly distinguishes:

```text
ui_declared_inputs: 1599
persisted_setting_types: 1594
clone_ui_only: 5
screens: 18
```

The distinction resolves the only ambiguity present in the agent's chat summary.

---

### 9.3 Confidence model

**PASS**

The map carries the expected research confidence vocabulary:

```text
CONFIRMED
INFERRED
UNRESOLVED
CONTRADICTORY
```

---

### 9.4 Architecture metadata

**PASS**

The map records canonical declaration, schema layers, storage, generation mapping, export versioning, and relevant evidence paths rather than presenting settings as isolated key/value pairs.

This makes it useful to F02–F04 and later compatibility tooling.

---

### 9.5 JSON validity

The producing F01 agent reports successful JSON validation and a clean branch quality check.

The connector review successfully retrieved and traversed the JSON content as a structured repository artefact.

No malformed structure was observed during review.

---

## 10. Missing / Hidden Dependencies

No hidden blocker was found.

The F01 report appropriately identifies handoffs to:

```text
F02 — Formula and Function Library
F03 — Compilation Pipeline
F04 — Token and Naming Architecture
D10 — Colour Palette and OKLCH
D19 — General Utilities / expansion behaviour where relevant
```

These are legitimate research boundaries.

F01 should not absorb their complete scope.

---

## 11. Required Corrections

**None required before acceptance.**

Optional editorial improvement only:

When referencing the inventory outside the F01 artefacts, use:

```text
1,599 UI-declared inputs
```

rather than:

```text
1,599 settings
```

unless the 1,594 + 5 distinction is immediately explained.

---

## 12. Unresolved Questions

The four unresolved F01 items are accepted as non-blocking:

### F01-U01 — Full client-side condition evaluator semantics

The schema and condition shapes are mapped, but every minified-dashboard evaluation path has not been fully decompiled.

**Disposition:** acceptable deferment unless a later compatibility requirement depends on exact UI-evaluator parity.

---

### F01-U02 — Runtime filter-added variable overrides

The shipped reference contains no evidence that production-site `acss/config/*` filters add relevant `options.variable` overrides.

The extensibility mechanism exists, but arbitrary site-local behaviour cannot be inferred from the reference corpus.

**Disposition:** correctly unresolved.

---

### F01-U03 — Exhaustive runtime-expanded colour setting/token inventory

The expansion pattern is confirmed, but the full generated cartesian inventory is not enumerated.

**Disposition:** defer to F02/F04/D10 or create mechanical fixtures when required.

---

### F01-U04 — Complete setting → emitted CSS custom-property mapping

This requires full SCSS/token analysis.

**Disposition:** correctly assigned to F04.

---

## 13. Acceptance Checklist

- [x] Material claims independently challenged.
- [x] High-risk transformation behaviour independently verified.
- [x] Settings declaration model is credible.
- [x] Persistence boundary is adequately documented.
- [x] Generation transformation boundary is not skipped.
- [x] Preview-vs-generation distinction is explicit.
- [x] Dependencies and handoffs are explicit.
- [x] Machine map is provenance-aware.
- [x] Aggregate setting counts are internally coherent.
- [x] Unknowns remain explicit.
- [x] No contradiction was hidden.
- [x] Branch scope is limited to the three F01 deliverables.
- [x] No `reference/` files were modified.
- [x] No NovaBase implementation code was introduced.
- [x] Research has not been presented as NovaBase design law.
- [x] No blocker remains.
- [x] No major correction remains.

---

## Review Outcome

```text
REVIEW: F01
VERDICT: ACCEPT WITH NON-BLOCKING NOTES

BLOCKERS: 0
MAJOR: 0
MINOR: 0
UNRESOLVED: 4
MACHINE MAPS VERIFIED: 1
REQUIRED CORRECTIONS: 0
```

### Recommended next action

F01 is eligible for controlled acceptance/integration.

The orchestrator should:

1. preserve this review artefact under the repository review path;
2. merge/integrate the reviewed F01 commit through the chosen governance workflow;
3. update `RESEARCH_MANIFEST.yaml` from `pending` to `accepted` only as part of that controlled integration;
4. retain all four unresolved F01 items for downstream handoff;
5. allow F02–F04 to consume the accepted F01 research where useful, while their independent foundation work continues.

---

> **F01 has earned acceptance through evidence. Acceptance does not turn ACSS behaviour into NovaBase design law.**
