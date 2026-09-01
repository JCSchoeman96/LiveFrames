# Phase 5A Fidelity HEEx Generator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Generate deterministic base-fidelity HEEx/CSS/manifest artifacts from validated Hero Design IR.

**Architecture:** A small library render-plan boundary feeds separate HEEx and CSS emitters; a narrow AutomaticCSS resolver contributes proven source-hint declarations. The preview app consumes generated artifacts only.

**Tech Stack:** Elixir, Phoenix LiveView, Jason, Mix, ExUnit.

---

### Task 1: Fidelity core and tests

**Files:** Create `apps/live_frames/lib/live_frames/fidelity.ex` and focused fidelity modules/tests.

- [ ] Add failing tests for validation, traversal, semantic mapping, escaping, styles, deferred evidence, asset substitution, and determinism.
- [ ] Implement the private render plan and deterministic HEEx/CSS/manifest bundle.
- [ ] Run focused tests and refactor only while green.

### Task 2: AutomaticCSS fidelity resolver

**Files:** Create `apps/live_frames/lib/live_frames/adapters/automatic_css/fidelity_resolver.ex`; extend focused tests.

- [ ] Add failing mapping tests for the three proven hints and exact token paths.
- [ ] Implement only those mappings, including pseudo states and derived values without invention.
- [ ] Run resolver and fidelity tests.

### Task 3: Generation task and committed artifacts

**Files:** Create Mix task, generated Hero fidelity files under the preview app, and `sources/work/hero_india/fidelity/manifest.json`; add drift tests.

- [ ] Add failing task/drift tests.
- [ ] Implement thin IR-loading task and generate one authoritative artifact set.
- [ ] Verify byte-identical regeneration.

### Task 4: Isolated preview surface

**Files:** Modify preview router/web files and add preview tests plus dedicated fidelity CSS loading.

- [ ] Add failing route/render tests.
- [ ] Implement the minimal host consuming generated template/CSS.
- [ ] Compile and inspect the base route.

### Task 5: Gates and reviews

- [ ] Run focused tests, all repository gates, drift verification, and preview inspection.
- [ ] Run independent security/determinism and scope reviews.
- [ ] Review diff, commit, push, and open the requested PR without merging.
