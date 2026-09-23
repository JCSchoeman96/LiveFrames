# G1 Catalogue architecture

**Status:** G1 architecture decisions are approved for written-spec capture. Catalogue implementation remains **NOT AUTHORIZED**. Approval or merge of the G1 written architecture authorizes only implementation planning and issue decomposition, including GitHub issue creation. Catalogue implementation requires separate, explicit owner authorization.

**Authority:** This document defines Catalogue identity, manifests, admission, lifecycle, validation, Registry, and runtime boundaries. [docs/24_CATALOGUE_VERSIONING_POLICY.md](24_CATALOGUE_VERSIONING_POLICY.md) defines CatalogueItem SemVer and compatibility policy. [docs/04_SOURCE_AND_PROVENANCE.md](04_SOURCE_AND_PROVENANCE.md) remains the provenance and publication-facts authority.

This is architecture documentation. It does not claim a Catalogue implementation or CatalogueItem instance exists.

## 1. Authority boundaries

| Concern | Authority |
| --- | --- |
| Catalogue identity, taxonomy, state, release metadata, references, compatibility, deprecation, supersession, distribution-capability declarations | Canonical Catalogue manifest described here |
| Actual component module, attrs, slots, rendering, runtime behavior, and public component contract | Production component source and its documentation |
| Story preview and render verification | Storybook story and verification evidence |
| Source origin, rights, provenance, publication facts, and clearance evidence | docs/04 |
| CatalogueItem release-version classification | docs/24 |
| Mix, Hex, or other package publication | Separate package lifecycle and evidence |

A Catalogue manifest references the production component contract. It does not copy the complete attrs or slots schema and does not generate production component APIs. Storybook is not Catalogue metadata, lifecycle, provenance, component API, or release-state authority.

## 2. Canonical metadata and identity

There is one declarative JSON manifest per CatalogueItem. Manifests contain data only. Catalogue metadata must not be executable Elixir or live in .exs files.

The canonical root is:

~~~text
apps/live_frames/priv/catalogue/
~~~

The immutable, globally unique, human-readable ID is the CatalogueItem identity. Examples:

~~~text
live_frames.primitive.icon
live_frames.component.avatar
live_frames.pattern.command_palette
live_frames.section.hero
live_frames.page.marketing_home
live_frames.template.saas_marketing
~~~

The allowed kind values are:

~~~text
primitive
component
pattern
section
page
template
~~~

For v1, an ID has three dot-separated segments: the live_frames namespace,
one allowed kind, and a lower snake_case semantic key. The kind segment must
equal the manifest kind. The complete ID is globally unique. Both ID and kind
become immutable when the manifest is admitted. An ID remains reserved after
WITHDRAWN or RETIRED and must never be reused.

The machine slug is the semantic_key segment. The canonical path pattern is
apps/live_frames/priv/catalogue/{directory-for-kind}/{semantic_key}.json,
using the directory table below. The manifest has no separately mutable slug
field.

| Kind | Directory |
| --- | --- |
| primitive | primitives |
| component | components |
| pattern | patterns |
| section | sections |
| page | pages |
| template | templates |

For example:

~~~text
live_frames.section.hero
→ apps/live_frames/priv/catalogue/sections/hero.json
~~~

A mismatch among ID, kind, derived slug, or path is invalid. display_name is mutable presentation metadata and does not change identity.

## 3. Admission from the native lifecycle

A native component must already be in its terminal accepted native lifecycle state before Catalogue admission. Native acceptance does not create, approve, or release a CatalogueItem.

Admission requires an explicit owner-authorized admit_to_catalogue action. Its guard requires a valid Catalogue ID that is globally unique and has never previously been used or reserved by any CatalogueItem. On success, admit_to_catalogue creates the canonical DRAFT manifest and permanently reserves the immutable ID. Admission does not run a generator, publish a package, claim redistribution clearance, or create a release claim. IDs remain reserved forever after WITHDRAWN or RETIRED.

The manifest must include references to the component, its Storybook module, documentation, and structured provenance evidence. Admission does not advance any other Catalogue lifecycle state.

The Phase-6 Hero tracer is accepted in its native lifecycle and has accepted Storybook evidence in [docs/22_P6_6_NATIVE_HERO_STORYBOOK_VERIFICATION.md](22_P6_6_NATIVE_HERO_STORYBOOK_VERIFICATION.md). Hero has not been admitted to the Catalogue. The ID live_frames.section.hero above is an identity example only.

## 4. Minimum v1 manifest shape

The following table documents the approved reference-oriented v1 shape. It is a schema description, not a CatalogueItem manifest. This PR must not add a real manifest.

| Area | Conceptual contents |
| --- | --- |
| schema_version | Explicit integer identifying the manifest schema. G1 v1 uses integer 1. It is independent of CatalogueItem SemVer. |
| id, kind | Immutable identity and one allowed taxonomy value. |
| display_name | Mutable presentation label. |
| state | Current CatalogueItem lifecycle state. |
| component.module, component.function | References to the production component export. |
| contract.fingerprint_algorithm, contract.fingerprint | Versioned fingerprint of the normalized public contract. |
| storybook.module | Reference to the PhoenixStorybook module that contains the production component's story. The manifest may record variation IDs when explicitly needed. It does not require a second story identifier. |
| docs | Structured references to item documentation. |
| provenance | Structured source-group, authority, and evidence references. This area does not store competing provenance status. |
| distribution.library, distribution.generator, distribution.ejection | Independent capability declarations with evidence references for any capability marked supported. |
| release.version | Proposed or current CatalogueItem SemVer, governed by docs/24. |
| Optional package linkage | Observational fields such as introduced_in_package or last_changed_in_package. These do not define CatalogueItem version. |
| lifecycle.last_transition | The most recent action, state change, and required evidence references. |
| deprecation | Whole-item deprecation rationale and related metadata when applicable. |
| superseded_by | Replacement CatalogueItem ID when a replacement exists. |

The manifest stores current state, the last transition, and the evidence references required for that state. It does not contain a large append-only event history. Git history is the durable transition history.

## 5. Lifecycle and state intent

The normal lifecycle is:

~~~text
DRAFT
→ VALIDATED
→ REVIEWED
→ APPROVED
→ RELEASED
→ DEPRECATED
→ RETIRED
~~~

The pre-release side exit is:

~~~text
DRAFT | VALIDATED | REVIEWED | APPROVED
→ WITHDRAWN
~~~

A repeated release uses a guarded self-transition:

~~~text
RELEASED
→ RELEASED via publish_new_version
~~~

WITHDRAWN and RETIRED are terminal. DEPRECATED is not terminal and may move to RETIRED. IDs remain reserved after either terminal outcome. GENERATED is not a CatalogueItem state. Registry and index generation are derived technical operations.

| State | Intent |
| --- | --- |
| DRAFT | Admission created the manifest and reserved its identity. |
| VALIDATED | Schema, identity, path, kind, references, Storybook evidence, and current contract fingerprint passed deterministic validation. |
| REVIEWED | Independent Catalogue review evidence exists. |
| APPROVED | An owner approved the item for eventual Catalogue release. This does not grant distribution permission. |
| RELEASED | The item-level Catalogue and distribution release gate passed. This does not mean a package was published. |
| DEPRECATED | The item remains traceable and available for compatibility lookup, but users should choose a replacement when one exists. |
| RETIRED | The item is removed from active Catalogue discovery. Its historical identity remains reserved and traceable. |
| WITHDRAWN | Pre-release admission was abandoned. The identity remains reserved. |

## 6. Transition actions, guards, and effects

State changes occur only through explicit transition actions and guards. An arbitrary edit to the state field is invalid.

| Action | Transition | Required guard |
| --- | --- | --- |
| admit_to_catalogue | Not admitted → DRAFT | Explicit owner authorization; accepted native lifecycle where the item is a native component; valid globally unique ID never previously used or reserved by any CatalogueItem; required references recorded. On success, create the canonical DRAFT manifest and permanently reserve the immutable ID. |
| validate | DRAFT → VALIDATED | State-dependent requirements in §7 pass, including a valid Storybook module reference, production-component target, canonical/default variation, and renderable default evidence. |
| review | VALIDATED → REVIEWED | Independent review evidence identifies the reviewed item and contract. |
| approve | REVIEWED → APPROVED | Owner approval evidence exists. Approval is not publication or redistribution clearance. |
| release | APPROVED → RELEASED | Valid SemVer, current fingerprint, validated capability claims, and explicit human-governed publication/redistribution clearance evidence exist. |
| publish_new_version | RELEASED → RELEASED | New SemVer is greater than the current version; the bump matches the compatibility classification; current fingerprint, capability evidence, and required clearance evidence pass. |
| deprecate | RELEASED → DEPRECATED | Rationale exists; superseded_by is set when a replacement exists. |
| retire | DEPRECATED → RETIRED | Explicit owner-authorized retirement evidence exists. |
| withdraw | DRAFT or VALIDATED or REVIEWED or APPROVED → WITHDRAWN | Explicit owner-authorized withdrawal action and rationale exist. |

A successful transition updates the current state, lifecycle.last_transition, and the evidence references required for the target state in the canonical manifest. The repository commit records the durable history. A transition does not publish a package, run a generator, or infer provenance facts.

No other transitions are defined in G1. Invalid transitions fail deterministically and leave the manifest unchanged. A stale fingerprint or missing evidence blocks the requested transition; it does not authorize direct state edits.

## 7. State-dependent validation

Validation requirements become stricter as an item advances. Release-only fields are not required in DRAFT.

| Target state | Minimum evidence and checks |
| --- | --- |
| DRAFT | Immutable identity and kind; component module/function reference; Storybook module reference; documentation references; structured provenance references. |
| VALIDATED | All references resolve; ID, kind, derived slug, and canonical path agree; schema version is supported; normalized contract fingerprint matches current production contract; the Storybook module exists, targets/references the production component, and its canonical/default variation renders. Any deliberately referenced variation IDs are valid. |
| REVIEWED | Independent review evidence exists and identifies the item and reviewed contract. |
| APPROVED | Owner approval evidence exists and records approval for eventual Catalogue release. |
| RELEASED | Valid CatalogueItem SemVer; current fingerprint; evidence for every capability marked supported; explicit human-governed publication/redistribution clearance. Unknown clearance is insufficient. |
| DEPRECATED | Whole-item deprecation rationale; superseded_by when a replacement exists. |
| RETIRED | Retirement evidence and preserved historical identity. |
| WITHDRAWN | Withdrawal rationale and preserved identity reservation. |

Agents may validate evidence presence, references, and shape. They must not invent or infer legal, provenance, publication, or redistribution clearance.

## 8. Contract fingerprint

The fingerprint protects the documented, consumer-facing component contract. It must remain unchanged when an internal refactor preserves that contract.

The fingerprint algorithm and canonical serialization must be deterministic and explicitly versioned. G1 does not select a digest algorithm or byte serialization. The exact v1 algorithm and serialization must be selected and owner-approved during the separately authorized implementation plan, before fingerprint implementation begins. An algorithm or version change must not masquerade as a component contract change. G1 has no fingerprint implementation.

The normalized record includes:

- Component module and exported function.
- Public attrs: names, types, requiredness, default semantics, and constrained values.
- Public slots: names, cardinality, and requiredness.
- Documented public capabilities.
- Documented public CSS and theme contract references, including public --lf-* variables.

Normalize attrs, slots, and other unordered public-contract entries by stable semantic key. Treat constrained values as a set unless their documented order is consumer-observable. Formatting and source declaration order do not affect the fingerprint.

Exclude source paths, line numbers, private helpers, private CSS classes or variables, internal DOM shape, prose formatting, and Storybook ordering. If a change affects a documented consumer-visible contract, the fingerprint changes. If only private implementation details change, it does not.

## 9. Storybook evidence

Every admitted CatalogueItem must reference its Storybook module. Storybook is mandatory validation evidence. A validator must confirm that the module exists and its story targets or references the production component. It must also confirm that a canonical/default variation exists and renders. Any variation IDs deliberately referenced by the manifest must be valid. No second story identifier is required.

Storybook remains preview and verification authority for its stories. It does not define Catalogue metadata, Catalogue lifecycle, provenance, component API authority, or release state. A Storybook story cannot admit or release an item.

The accepted Phase-6 Hero Storybook evidence is recorded in docs/22. It proves that the accepted native Hero has a verified story; it does not prove Catalogue admission.

## 10. Provenance and distribution capabilities

The Catalogue manifest references provenance. It does not own provenance truth. Keep docs/04_SOURCE_AND_PROVENANCE.md as the canonical authority. Do not duplicate mutable fields such as redistribution_status or publication_state in Catalogue manifests. Store structured references to source groups, authorities, and evidence instead.

APPROVED is not permission to distribute. The APPROVED → RELEASED transition requires explicit human-governed publication and redistribution clearance evidence. Unknown redistribution status is insufficient. Agents must never infer or invent clearance.

Library, generator, and ejection are independent distribution capabilities. Catalogue release does not require generator or ejection support. Mark a capability supported only when its implementation, tests, documentation, and compatibility contract exist. Generator and ejection remain unsupported and not authorized. A false supported claim blocks validation or release.

## 11. Registry and public discovery

Canonical JSON manifests are the source authority. When implementation is separately authorized, the Elixir Registry is a deterministic compile-time representation derived directly from those manifests.

G1 does not commit a generated index.json. Runtime directory scanning and per-request manifest parsing are prohibited. Invalid manifests must fail deterministic validation and CI.

The internal Registry may represent every lifecycle state. Public Catalogue discovery exposes RELEASED by default. DEPRECATED requires explicit opt-in or direct compatibility lookup. DRAFT, VALIDATED, REVIEWED, APPROVED, WITHDRAWN, and RETIRED do not appear in normal public discovery.

Registry presence, public discoverability, and distributability are separate facts. Presence in an internal Registry does not make an item public or distributable.

## 12. Schema evolution

schema_version is an explicit integer and is independent of CatalogueItem SemVer. Validation is explicit for each supported schema version. Unknown future schema versions fail deterministically.

Schema migrations are explicit, deterministic, side-effect-free transformations introduced in dedicated changes. They must never silently coerce or reinterpret an incompatible schema. A migration does not change CatalogueItem identity or release version.

## 13. Performance and scaling

Catalogue metadata is static build-time data. Hot, warm, and cold application caching architecture is **N/A for G1 Catalogue**.

- Runtime database calls: zero.
- Runtime network calls: zero.
- Per-request manifest scanning or parsing: prohibited.
- No database, Redis, GenServer, or network lookup.
- Redis, ETS, Cachex, PgBouncer, read replicas, and Oban are not justified for G1 Catalogue.
- If Catalogue data is exposed on the web later, static or package data and CDN/browser caching are suitable delivery options.
- Deterministic compiled/static metadata remains safe at high request concurrency because discovery is not a high-concurrency write path.

Native acceleration is benchmark-gated. Rust/Zig/native acceleration is not authorized. If measured evidence later justifies a native boundary, Rust is the preferred first option and must stay behind a source-independent interface. Heavy compiler work may justify an isolated Rust CLI/Port before considering a NIF. This is an architectural guard, not permission to add native code now.

## 14. Failure and risk review

Validation and review must detect at least these failures:

- Duplicate immutable IDs.
- ID, kind, derived slug, or canonical path disagreement.
- Reuse of an ID after WITHDRAWN or RETIRED.
- Dangling component, Storybook, documentation, or provenance references.
- A stale contract fingerprint or drift between the manifest reference and production component contract.
- An unsupported schema version or silent schema reinterpretation.
- An invalid lifecycle transition or arbitrary direct state edit.
- False provenance, publication, legal, or redistribution inference.
- Release without valid SemVer or with missing human clearance.
- Incorrect SemVer compatibility classification.
- A capability falsely marked supported.
- Exposure of APPROVED or any other non-released item in normal public discovery.
- A package-publication claim inferred from CatalogueItem RELEASED.
- Storybook becoming accidental Catalogue metadata, lifecycle, provenance, or component API authority.
- Native acceleration added without measured benchmark evidence.

## 15. G1 implementation boundary

This PR records architecture only. It does not create apps/live_frames/priv/catalogue/, a JSON CatalogueItem manifest, a Catalogue module or Registry, validators, transition functions, fingerprint extraction, dependencies, database/cache/process infrastructure, generator/ejection implementation, native code, package publication, or Catalogue admission.

Catalogue implementation remains **NOT AUTHORIZED**. Approval or merge of the G1 written architecture authorizes only implementation planning and issue decomposition, including GitHub issue creation. Catalogue implementation requires separate, explicit owner authorization.
