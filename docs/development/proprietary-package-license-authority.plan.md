# Proprietary package license authority (PR #98 / #51A gate)

| Field | Value |
| --- | --- |
| **Plan ID** | `proprietary-package-license-authority` |
| **Plan version** | `v1` |
| **Status** | **Active authority — documentation gate only** |
| **Scope** | Lock implementation boundaries for `:live_frames` Hex **package metadata** and **canonical license text** before any correction to PR #98. |
| **Last updated** | 2026-09-29 |

### Revision log

- `v1` — Initial machine-authority slice: proprietary/custom posture, intended `LicenseRef-LiveFrames-Proprietary`, owner-approved text gate, explicit prohibitions, future minimum-file correction sequence. No implementation authorized.

---

## Authority / source of truth

| Document | Role |
| --- | --- |
| **This file** (`docs/development/proprietary-package-license-authority.plan.md`) | **Active contract** for licensing posture and what may change before/while unblocking PR #98 package metadata. |
| [docs/04_SOURCE_AND_PROVENANCE.md](../04_SOURCE_AND_PROVENANCE.md) | Canonical provenance policy; unresolved redistribution must not be silently converted into permission. |
| [docs/16_PACKAGE_AND_GENERATOR_MODEL.md](../16_PACKAGE_AND_GENERATOR_MODEL.md) | Consumer package layout; Hex publication remains out of scope unless separately authorized. |
| [docs/23_CATALOGUE_ARCHITECTURE.md](../23_CATALOGUE_ARCHITECTURE.md) | #51 build/package/CI contract (#51A package boundary gate). |
| Catalogue **#51A** slice (merged docs via PR #96; implementation PR #98) | Package source `priv/catalogue` + Hex unpack CI — **implementation on branch `catalogue/51a-package-boundary`, PR #98, HEAD `f889b3231c673625c604b2fab712f7d353a5944f`**. |

**Conflict resolution:** This plan wins over agent improvisation on licensing and package publication metadata. On provenance facts, [docs/04](../04_SOURCE_AND_PROVENANCE.md) wins. On Catalogue package/CI mechanics, [docs/23](../23_CATALOGUE_ARCHITECTURE.md) wins unless this plan explicitly restricts metadata steps.

**This plan does not authorize editing** [docs/16](../16_PACKAGE_AND_GENERATOR_MODEL.md), [docs/23](../23_CATALOGUE_ARCHITECTURE.md), or [docs/24_CATALOGUE_VERSIONING_POLICY.md](../24_CATALOGUE_VERSIONING_POLICY.md) **in v1**.

---

## Goal

Record a **proprietary/custom** licensing posture for the reusable `:live_frames` **package** so that:

1. Future work cannot treat “we added a LICENSE file” as permission to broaden grants, pick open-source licenses, or publish to Hex.
2. PR **#98** can later receive a **narrow, explicitly authorized** metadata correction only after **owner/counsel-approved** license text exists.
3. The existing **#51A package-boundary CI** on PR #98 is preserved; only unauthorized `mix.exs` publication fields are removed/replaced in a future authorized step.

---

## Current baseline (rebaseline 2026-09-29)

| Item | State |
| --- | --- |
| `origin/main` | `898158bb14ce63097dec54a23786c5351ba61b91` (drift from #51A base is **SAFE_NON_OVERLAPPING** for Bricks/token/docs; does not override this gate) |
| #51A authority BASE | `599dffa9e4cd82dd9dba23156b5d9e01708463f5` |
| PR #98 branch | `catalogue/51a-package-boundary` @ `f889b3231c673625c604b2fab712f7d353a5944f` |
| PR #98 merge | **PROHIBITED** until license authority + separate implementation authorization |
| Repository `LICENSE` | **Absent** |
| Agent-added package metadata on PR #98 | **Unauthorized** — includes invented `LicenseRef-UNLICENSED`, `description`, and `links` in `apps/live_frames/mix.exs` |
| #51A CI implementation (workflow + probe gate + tests) | **Accepted in review** — not the blocking defect |
| Hex `mix hex.publish` | **PROHIBITED** |
| Open-source license (MIT, Apache-2.0, etc.) | **NOT AUTHORIZED** — deferred explicit owner decision |
| `LicenseRef-UNLICENSED` | **PROHIBITED** — must not appear in `mix.exs` or package |

---

## Licensing posture (owner direction recorded)

```text
LiveFrames :live_frames package licensing posture:
  PROPRIETARY / CUSTOM — pending explicit redistribution clearance where required

Open-source licensing:
  DEFERRED — requires future explicit owner decision

Hex publication / version bump / tag / release:
  NOT AUTHORIZED under this plan or #51A
```

### Intended future SPDX-style package identifier

When and only when canonical license text is approved and packaged:

```text
LicenseRef-LiveFrames-Proprietary
```

**Do not use** `LicenseRef-UNLICENSED` or any SPDX identifier (MIT, Apache-2.0, …) unless a **separate** owner authorization explicitly adopts open source.

Hex expectation: a custom `LicenseRef-*` must refer to **full license text included in the package** ([Mix.Tasks.Hex.Build](https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html) / Hex package configuration). The identifier is not a substitute for text.

---

## Non-negotiable constraints

1. **No agent-authored binding legal prose.** Agents may record machine authority (this plan), file paths, gates, and checklists — not draft the proprietary license body.
2. **Scope of grant (conceptual — enforced in owner/counsel text, not by agents):**
   - **LiveFrames-owned/controllable original code** → may be governed by LiveFrames proprietary terms once approved.
   - **Third-party / upstream material** → remains governed by its own rights and provenance records; **no additional rights** granted by the LiveFrames license.
   - **Material with unresolved redistribution authority** → remains unresolved; **not cleared** by project license language or package metadata.
3. **Provenance alignment:** Package licensing must not contradict [docs/04](../04_SOURCE_AND_PROVENANCE.md) (unknown stays unknown; internal-use approval ≠ redistribution approval).
4. **`description` and `links` in `mix.exs`:** **Explicitly undecided** — must not be added or changed in a future correction unless a separate authorization names approved values.
5. **`:licenses` in `mix.exs`:** Must not contain any value until canonical owner/counsel-approved license text is committed and included in the Hex `:files` list (minimum necessary path — typically a root `LICENSE` or explicitly authorized path).
6. **PR #98 / branch mutation:** **NOT AUTHORIZED** while this gate is active except via a **future, separate implementation authorization** after approved license text exists.
7. **#51B, #50, Hero admission, canonical Catalogue manifests, preview integration:** **NOT AUTHORIZED** under this plan.
8. **No “four-file minimum.”** Future implementation is limited to the **minimum tracked files actually required** to satisfy Hex build prerequisites and package the approved text (often `LICENSE` + `apps/live_frames/mix.exs`; possibly `package_contract_test.exs` or CI only if repository truth requires it — not assumed in advance).

---

## What is authorized in v1 (this slice only)

| Authorized | Not authorized |
| --- | --- |
| This plan file (machine authority) | Changing `catalogue/51a-package-boundary` |
| Recording posture and gates | Merging PR #98 |
| | Removing/replacing unauthorized metadata on PR #98 |
| | Adding `LICENSE` or any license body |
| | `mix hex.publish`, tags, releases |
| | #51B / #50 |

**v1 deliverable:** documentation only. **STOP after this file is recorded** (no implementation PR for license correction in v1).

---

## Preconditions for the next implementation authorization (future slice)

All must be true before any agent may touch PR #98 / `mix.exs` for license/metadata:

1. **Owner/counsel-approved** canonical proprietary license text exists as a **committed repository file** at an **explicitly authorized path** (default candidate: repository-root `LICENSE` — final path is part of implementation authorization, not assumed here).
2. Approved text reflects the **conceptual scope** in [Non-negotiable constraints](#non-negotiable-constraints) (no implied relicensing of third-party or unresolved-provenance material).
3. Implementation authorization lists **exact files** allowed to change (minimum set only).
4. Implementation authorization names the **exact** `:licenses` value: `LicenseRef-LiveFrames-Proprietary` (unless owner changes identifier in writing).
5. If `description` or `links` are included, implementation authorization must quote **approved strings** verbatim.

Until then: **STOP.**

---

## Future implementation sequence (not authorized until preconditions met)

When preconditions are satisfied, execute in order:

1. **Verify** current `origin/main` and **exact PR #98 HEAD** (`f889b3231c673625c604b2fab712f7d353a5944f` or successor explicitly named in authorization).
2. **Classify drift** from authorized bases using parallel-main policy (rebase only for correctness / overlapping package-license-CI drift — not merely because `main` moved).
3. **Authorize exact files** (minimum necessary — typically some subset of):
   - canonical license file (owner-approved text only),
   - `apps/live_frames/mix.exs` (remove unauthorized metadata; add approved `:licenses`; optional approved `description`/`links` only if named),
   - `apps/live_frames/test/live_frames/styling/package_contract_test.exs` **only if** package file list or invariants require it,
   - `.github/workflows/ci.yml` **only if** CI must assert packaged license bytes/path — not by default.
4. **Retain** existing #51A **Verify LiveFrames Hex package contents** step and probe/populated catalogue logic unless authorization explicitly changes it.
5. **Validate** locally: `mix hex.build --unpack` with approved metadata; package includes approved license text; probe cleanup unchanged; no `LicenseRef-UNLICENSED`.
6. Run focused gates applicable to touched files; then **exact-head CI** on the correction branch.
7. **Independent BASE→HEAD review** (BASE = implementation authorization base SHA; HEAD = correction commit).
8. **STOP for manual merge authorization** — do not merge without explicit owner instruction.

**Hex publication remains prohibited** after merge unless separately authorized.

---

## Explicit STOP reminders

```text
PR #98              DO NOT MERGE (until license correction authorized + reviewed)
#51B                DO NOT START
#50                 DO NOT START
Hex publish         PROHIBITED
MIT / Apache / OSS  DO NOT APPLY (deferred)
UNLICENSED          DO NOT APPLY
Agent license draft PROHIBITED
```

After v1: **STOP.** Do not mutate `catalogue/51a-package-boundary`, PR #98, `mix.exs`, CI, or package metadata until canonical proprietary license text is owner/counsel approved and a **separate implementation authorization** is issued.

---

## Success criteria (v1 — authority slice only)

- [x] Proprietary/custom posture and deferred OSS recorded in a tracked plan.
- [x] Intended identifier `LicenseRef-LiveFrames-Proprietary` recorded with Hex text-in-package requirement.
- [x] Owner-approved text gate before `:licenses` in `mix.exs` recorded.
- [x] Agent legal drafting, PR #98 correction, and minimum-file future sequence documented.
- [ ] **Implementation** — explicitly **out of scope for v1**; awaits owner/counsel text + separate authorization.
