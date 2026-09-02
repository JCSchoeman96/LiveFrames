# P5-H0 Repository Truth and Provenance Governance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align the public repository’s status language and source-publication governance with the active Phase 5 authority without changing source payloads or compiler behavior.

**Architecture:** Keep `docs/00_LIVEFRAMES_MASTER_SPEC.md` as architecture authority and `docs/18_PHASE_5_HARDENING_AND_ACCEPTANCE.md` as Phase 5 execution authority. Make `docs/04_SOURCE_AND_PROVENANCE.md` the single durable provenance/publication policy, with small contextual READMEs and source records pointing to it.

**Tech Stack:** Markdown documentation, Git/GitHub, and the existing Mix quality gates.

---

### Task 1: Align repository orientation and source-location guidance

**Files:**
- Modify: `README.md`
- Modify: `fixtures/README.md`
- Modify: `sources/README.md`
- Modify: `private_reference/README.md`
- Modify: `private_reference/REFERENCE_MANIFEST.md`
- Modify: `acss/README.md`
- Modify: `imports/README.md`
- Modify: `imports/pending/README.md`
- Modify: `imports/approved/README.md`

- [ ] Replace Phase 3-era README status with the completed Phoenix, adapter, IR, TokenSet, Fidelity, and accepted-breakpoint facts supported by `docs/18_PHASE_5_HARDENING_AND_ACCEPTANCE.md`.
- [ ] State `Master Phase 5 = OPEN`, list the remaining hardening/acceptance work, and link architecture, execution, and provenance authorities.
- [ ] Make each source-location README distinguish internal-use approval from public-redistribution approval and prohibit new public placement when redistribution is unresolved.

### Task 2: Establish the canonical provenance/publication policy

**Files:**
- Modify: `docs/04_SOURCE_AND_PROVENANCE.md`
- Modify: `fixtures/bricks/SOURCE.md`
- Modify: `fixtures/automatic_css/SOURCE.md`
- Modify: `docs/18_PHASE_5_HARDENING_AND_ACCEPTANCE.md`

- [ ] Define separate internal-use and redistribution facts, including that unknown redistribution is unresolved rather than a legal conclusion.
- [ ] Define the required publication lifecycle, transition guards, terminal-state invariants, source-directory boundaries, and derived-artifact traceability rule.
- [ ] Record the repository-evidence status of the Bricks export, Automatic.css settings/research material, standalone source experiments, and derived Hero artifacts without changing payloads.
- [ ] Add scoped publication-state fields to the two existing fixture provenance records and cross-reference the canonical policy from the active Phase 5 document.

### Task 3: Verify scope, documentation consistency, and repository gates

**Files:**
- Verify only; no additional implementation files.

- [ ] Confirm the diff contains documentation only and excludes fixture JSON, source CSS/JS/HTML payloads, generated output, compiler code, dependency files, and secrets.
- [ ] Search all changed and relevant policy documents for stale Phase 3 claims, unqualified “safe/approved/reviewed” wording, contradictory publication-state terminology, and the forbidden exclusive `479–991px` tablet interpretation.
- [ ] Run `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix test`, `mix deps.unlock --check-unused`, and `git diff --check`.
- [ ] Review the final diff, commit one focused change, push the exact head, open the requested PR against `main`, and report exact push/PR CI results without merging.
