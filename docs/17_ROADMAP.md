# Roadmap

**Architecture authority:** [`00_LIVEFRAMES_MASTER_SPEC.md`](00_LIVEFRAMES_MASTER_SPEC.md)

**Current repository checkpoint:** PR #192 merged on `main`.

```text
MAIN_SHA=bdc2b8b80a1ef8f0ffaa9f155d154144afae66e9
MAIN_TREE=29a3798ac9864155eadb4dc7b024bb9fc1559b9b
MAIN_CI_RUN=38386374178
MAIN_CI_RESULT=PASS
```

## Current status

- Design IR current version: `4.0.0`.
- C09D6-B review, C09D6-C native generation, and C09D6-D native styling are
  implemented on `main`.
- C09D7-A CTA Tango componentization and review are accepted (A3 approval
  transition, PR #184).
- C09D7-B native CTA delivery is implemented and merged on `main` via PR #192.
  The component API, package CSS, and repository Storybook verification exist.
- C09D7-C external consumer proof and Catalogue handoff have not yet been
  proven. Before implementation, inspect accepted consumer, package, and
  Catalogue authority to establish the exact authorized proof scope. If that
  authority is insufficient or ambiguous, do not begin implementation. Stop
  with `STOP=CONSUMER_CONTRACT_UNDEFINED`; the next action is the smallest owner
  decision or authority prompt needed to define the missing contract. This
  status makes no C09D7-C authorization claim.
- Catalogue library infrastructure exists. Production content under
  `apps/live_frames/priv/catalogue/` is absent; no production Catalogue
  membership is claimed.
- P10 consumer-project ejection is not implemented.
- No Hex publication or public release readiness is claimed.

The accepted native-generation semantics remain in
[`development/c09d6_native_generation_authority.md`](development/c09d6_native_generation_authority.md).
Its embedded checkpoint predates PR #192 and remains historical authority
context; this file records current implementation status. Catalogue architecture
history remains in [docs/23](23_CATALOGUE_ARCHITECTURE.md) and [docs/24](24_CATALOGUE_VERSIONING_POLICY.md).

This file is a current-status pointer. It does not replace the architecture or
semantic authority documents.
