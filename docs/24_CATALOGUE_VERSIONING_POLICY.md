# G1 Catalogue versioning policy

**Status:** G1 versioning decisions are approved for written-spec capture. Catalogue implementation remains **NOT AUTHORIZED** until the written architecture/spec PR is independently reviewed and owner-approved.

**Authority:** This document defines CatalogueItem release-version semantics and compatibility classification. [docs/23_CATALOGUE_ARCHITECTURE.md](23_CATALOGUE_ARCHITECTURE.md) defines Catalogue identity, lifecycle, manifest ownership, and release guards. [docs/04_SOURCE_AND_PROVENANCE.md](04_SOURCE_AND_PROVENANCE.md) remains the authority for provenance and publication facts.

## 1. Separate version concepts

These values describe different things and must not be substituted for one another:

| Concept | Meaning |
| --- | --- |
| CatalogueItem ID | Immutable global identity. It is never reused after withdrawal or retirement. |
| CatalogueItem release_version | SemVer for the consumer-observable contract of one CatalogueItem. |
| Manifest schema_version | Integer selecting the manifest schema and its validator. |
| Package version | Version of a separately published Mix, Hex, GitHub, or other package artifact. |

A CatalogueItem release version does not define a manifest schema version or package version. A package version does not define a CatalogueItem release version.

A proposed first release.version may be present while preparing APPROVED → RELEASED. Until that guarded transition succeeds, the proposed value has no released meaning. A later CatalogueItem release uses the guarded RELEASED → RELEASED transition via publish_new_version.

G1 does not create a separate CatalogueRelease entity. The canonical manifest stores the current CatalogueItem release version and last transition. Git history preserves prior versions and transition evidence.

## 2. Public-contract boundary

CatalogueItem SemVer protects the documented, consumer-observable semantic contract. It does not promise identical pixels or preserve every private implementation detail.

Compatibility review compares the public contract fingerprint and its documented meaning. The contract covers public attrs, slots, semantics, behavior ownership, documented capabilities, and documented CSS/theme extension points. The fingerprint rules are defined in docs/23.

A visual or internal implementation change is not automatically a breaking change. Classify it by its effect on the documented public contract.

## 3. Compatibility classification

Use SemVer 2.0.0 precedence and syntax. Increment MAJOR for MAJOR changes,
reset MINOR and PATCH to zero; increment MINOR for MINOR changes, reset PATCH
to zero; increment PATCH for PATCH changes. The increment must fully match the
compatibility effect. A release cannot proceed until the classification has
evidence and the new version is greater than the current version.

| Increment | Apply when | Examples |
| --- | --- | --- |
| **MAJOR** | An incompatible change alters or removes a documented consumer-observable contract. | Removing or renaming a public attr; changing its type, accepted domain, or requiredness incompatibly; removing or renaming a slot; changing slot cardinality incompatibly; changing documented semantic HTML; changing ownership of state, events, or behavior; removing or renaming a documented public CSS/theme extension point such as a public --lf-* variable. |
| **MINOR** | A backwards-compatible public capability or optional contract element is added. | Adding an optional attr with a safe default; adding an optional slot; adding a backwards-compatible supported variant; adding a public theme variable; adding a supported distribution capability. |
| **PATCH** | A compatible correction preserves the documented public contract. | Compatible bug fix; compatible accessibility correction; internal markup refactor that preserves public semantics; styling/fidelity correction within the public contract; performance improvement; documentation correction. |

A patch cannot hide an incompatible contract change. A release cannot use a lower increment than its compatibility evidence requires.

## 4. Release guards

The initial transition from APPROVED to RELEASED requires a valid SemVer value, the current contract fingerprint, validated capability claims, and explicit human-governed publication/redistribution clearance evidence. APPROVED alone does not grant permission to distribute. Unknown redistribution is insufficient.

For each publish_new_version action:

1. The current state is RELEASED.
2. The proposed SemVer is valid and greater than the current CatalogueItem release version.
3. The MAJOR, MINOR, or PATCH increment matches the compatibility classification in §3.
4. The current public-contract fingerprint and supported-capability evidence are valid.
5. Required human-governed publication/redistribution clearance evidence exists.

If a guard fails, the manifest remains unchanged and the action fails deterministically. A direct edit to release.version does not release or publish a version.

A CatalogueItem in DEPRECATED, RETIRED, or WITHDRAWN cannot publish a new version under the G1 lifecycle.

## 5. Element and item deprecation

Deprecating one public contract element is distinct from moving the whole CatalogueItem to DEPRECATED.

- Announce a public element deprecation in a MINOR release and keep the element compatible.
- Remove the element only in a later MAJOR release.
- Record the deprecation in release documentation and maintain the compatibility behavior during the deprecation period.

Whole-item deprecation requires a rationale. Set superseded_by when a replacement exists. A deprecated item remains traceable and available for compatibility lookup, but normal feature work stops. Retirement removes it from active Catalogue discovery while preserving its historical identity.

## 6. Catalogue release and package publication

CatalogueItem RELEASED is an item-level Catalogue/distribution state. It does not imply Mix, Hex, GitHub, or other package publication. Package publication is a separate lifecycle fact and requires its own evidence.

CatalogueItem release_version and package version are independent. Optional observational fields such as introduced_in_package or last_changed_in_package may record package linkage, but they must not define or substitute for CatalogueItem SemVer.

Do not claim Hex or package publication unless repository evidence proves it. This policy makes no package-publication claim.

## 7. Hypothetical Hero examples

The following are compatibility examples for a hypothetical future CatalogueItem that references the accepted native Hero component. They do not claim that Hero has been admitted or released:

- Removing a documented public Hero attr would require MAJOR.
- Adding an optional Hero attr with a safe default would require MINOR.
- Refactoring Hero's private markup while preserving public semantics would require PATCH.

The accepted Phase-6 Hero tracer state remains separate from any CatalogueItem version.
