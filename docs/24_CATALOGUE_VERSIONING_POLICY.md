# G1 Catalogue versioning policy

**Status:** G1 versioning decisions are approved for written-spec capture. Catalogue implementation remains **NOT AUTHORIZED**. This policy freezes the versioning contract before a separate implementation authorization. Approval or merge of the G1 written architecture authorizes only implementation planning and issue decomposition, including GitHub issue creation. Catalogue implementation requires separate, explicit owner authorization.

**Authority:** This document defines CatalogueItem release-version semantics and compatibility classification. [docs/23_CATALOGUE_ARCHITECTURE.md](23_CATALOGUE_ARCHITECTURE.md) defines Catalogue identity, lifecycle, manifest ownership, and release guards. [docs/04_SOURCE_AND_PROVENANCE.md](04_SOURCE_AND_PROVENANCE.md) remains the authority for provenance and publication facts.

## 1. Separate version concepts

These values describe different things and must not be substituted for one another:

| Concept | Meaning |
| --- | --- |
| CatalogueItem ID | Immutable global identity. It is never reused after withdrawal or retirement. |
| CatalogueItem `release.version` | Current or proposed stable SemVer for the consumer-observable contract of one CatalogueItem. |
| Manifest `schema_version` | Integer selecting the manifest schema and its validator. |
| Package version | Version of a separately published Mix, Hex, GitHub, or other package artifact. |

A CatalogueItem release version does not define a manifest schema version or package version. A package version does not define a CatalogueItem release version.

For G1, when `release` is present in a manifest, its exact shape is:

~~~json
{
  "release": {
    "version": "1.2.3"
  }
}
~~~

`version` is the only key in the G1 `release` object. The general `Schema.V1` decoder checks only that `release`, when present, is a JSON object. It does not enforce this nested shape, the value type, or SemVer syntax. Dedicated versioning validation owns the exact keys and version checks. The manifest contract and this boundary are summarized in [docs/23_CATALOGUE_ARCHITECTURE.md](23_CATALOGUE_ARCHITECTURE.md).

`release.version` is an exact JSON string. Validation may parse it to check syntax, precedence, and increments, but the manifest preserves the supplied valid string. Do not trim it, change its case, add or remove a `v`, normalize it, coerce another JSON type, or infer it from another version field.

G1 does not create a separate CatalogueRelease entity. The canonical manifest stores the current CatalogueItem release version and last transition. Git history preserves prior versions and transition evidence.

A candidate manifest may contain a proposed first version before `APPROVED → RELEASED`. It has no released meaning until the guarded transition succeeds. A later CatalogueItem version uses guarded `RELEASED → RELEASED` via `publish_new_version`.

G1 CatalogueItem release versions support only the stable SemVer 2.0.0 core:

~~~text
MAJOR.MINOR.PATCH
~~~

Each component is a non-negative decimal integer. It has no leading zero unless the component is exactly `0`. Examples of valid strings are `0.0.0`, `0.1.0`, `1.0.0`, and `12.34.56`.

The exact G1 stable-core grammar is:

~~~text
\A(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\z
~~~

This grammar matches exactly three ASCII decimal components and the two required dots across the entire string. The whole-input anchors reject leading or trailing whitespace, including a final newline.

G1 rejects prerelease identifiers and build metadata for Catalogue releases, even though those forms are valid under general SemVer. For example, reject `1.0.0-alpha`, `1.0.0-alpha.1`, `1.0.0+build.7`, and `1.0.0-rc.1+build.7`. G1 has exactly MAJOR, MINOR, and PATCH release classes. Same-core prerelease promotion would add transition rules that this policy does not govern. Any future prerelease or build-metadata support requires separate authority.

Reject other forms that change the stable core syntax, including `1`, `1.2`, `01.2.3`, `1.02.3`, `1.2.03`, `-1.2.3`, `1.2.3.4`, `v1.2.3`, ` 1.2.3`, and `1.2.3 `.

Compare parsed numeric SemVer components, never raw version strings. For example, `1.10.0` is greater than `1.9.0`, regardless of lexical string ordering.

## 2. Public-contract boundary

CatalogueItem SemVer protects the documented, consumer-observable semantic contract. It does not promise identical pixels or preserve every private implementation detail.

Compatibility review considers the public contract fingerprint and its documented meaning. The contract covers public attrs, slots, semantics, behavior ownership, documented capabilities, and documented CSS/theme extension points. The fingerprint rules are defined in docs/23.

A visual or internal implementation change is not automatically a breaking change. A reviewer classifies a change by its effect on the documented public contract. The fingerprint detects public-contract drift; it does not determine the drift's SemVer severity.

## 3. Compatibility classification

A trusted compatibility review supplies the classification for each normal `publish_new_version` action. G1 code validates that the proposed numeric increment agrees with that reviewed decision. It does not classify arbitrary public-contract changes by comparing fingerprints, attrs, slots, CSS variables, capabilities, docs, Storybook evidence, or normalized contract data.

The exact G1 class strings are lowercase:

~~~text
"major"
"minor"
"patch"
~~~

Do not accept aliases, uppercase values, or atom-like strings such as `"breaking"`, `"feature"`, `"fix"`, `"MAJOR"`, or `":major"`.

The caller supplies this exact compatibility input shape:

~~~json
{
  "class": "minor",
  "evidence_refs": [
    "catalogue-compatibility-review:synthetic"
  ]
}
~~~

The record has exactly the keys `class` and `evidence_refs`. It is guard input, not a manifest field, and G1 `release` contains only `version`. On success, the validator returns the supplied evidence refs for the existing Lifecycle guard result; it does not store the compatibility record or class in the manifest.

`evidence_refs` must be a proper, non-empty list. Every member must be an exact, non-empty valid UTF-8 string, and duplicate strings are invalid. Do not trim, normalize, sort, atomize, or resolve the references automatically. Preserve their supplied order in the versioning guard result. The validator does not invent evidence references.

Fingerprint change does not automatically mean MAJOR, MINOR, or PATCH. The fingerprint proves public-contract drift but does not encode its semantic severity. An unchanged fingerprint also does not replace compatibility review evidence when the caller requests `publish_new_version`.

Use these policy examples as human review guidance:

| Increment | Apply when | Examples |
| --- | --- | --- |
| **MAJOR** | An incompatible change alters or removes a documented consumer-observable contract. | Removing or renaming a public attr; changing its type, accepted domain, or requiredness incompatibly; removing or renaming a slot; changing slot cardinality incompatibly; changing documented semantic HTML; changing ownership of state, events, or behavior; removing or renaming a documented public CSS/theme extension point such as a public `--lf-*` variable. |
| **MINOR** | A backwards-compatible public capability or optional contract element is added. | Adding an optional attr with a safe default; adding an optional slot; adding a backwards-compatible supported variant; adding a public theme variable; adding a supported distribution capability. |
| **PATCH** | A compatible correction preserves the documented public contract. | Compatible bug fix; compatible accessibility correction; internal markup refactor that preserves public semantics; styling/fidelity correction within the public contract; performance improvement; documentation correction. |

These examples do not create a machine classifier. A trusted reviewer supplies the exact class and evidence refs.

The example about adding a supported distribution capability is review
guidance. A change to a `distribution.*` declaration or normalized
`capabilities` value does not determine the class automatically. Those fields
remain separate as defined in docs/23 §8.4.

## 4. Release guards

Versioning is one release guard. An initial release also requires the current
contract fingerprint, validated capability claims, and provenance release
clearance under docs/23 §10. `APPROVED` alone does not grant permission to
distribute, and unknown redistribution status fails clearance. A normal
`publish_new_version` action has the corresponding fingerprint, capability,
and provenance-clearance checks. The versioning validator owns only version
syntax and agreement with the reviewed compatibility class.

### Initial release

For `APPROVED → RELEASED`, versioning validation receives the candidate `release.version` and explicit version-review evidence refs. There is no previous released CatalogueItem version, and no `major`, `minor`, or `patch` classification is required. Do not invent a synthetic current version such as `0.0.0`.

Any valid stable G1 SemVer may be the first version, subject to the other release guards. The versioning contract does not force `1.0.0`. Examples include `0.1.0`, `0.9.0`, `1.0.0`, and `2.0.0`.

The caller supplies version-review evidence separately from the manifest, conceptually as:

~~~json
{
  "evidence_refs": [
    "catalogue-version-review:synthetic"
  ]
}
~~~

The value must be a proper, non-empty list of exact, non-empty valid UTF-8 strings with no duplicates. Preserve the supplied order. This is guard input, not data inside `release`. On success, the versioning guard returns those exact refs. It never invents them.

### Normal new-version release

For `RELEASED → RELEASED` via `publish_new_version`, versioning validation receives two explicit versions and a compatibility record:

- The current version comes from the trusted current released CatalogueItem snapshot or input.
- The proposed version comes from the candidate's `release.version`.
- The compatibility class and evidence refs come from the trusted caller's compatibility review.

The current and proposed versions remain separate validation inputs. A candidate manifest containing `release.version = "2.0.0"` does not prove the prior released version, that `publish_new_version` occurred, or that the compatibility classification is valid. Do not infer the current version from a package version, `schema_version`, `introduced_in_package`, `last_changed_in_package`, a Git tag, or `mix.exs`.

For a normal `publish_new_version`, validate both version strings, the candidate's exact `release` object shape, the compatibility record and its class, and the compatibility evidence refs. The proposed version must be strictly greater than the current version under SemVer precedence. Equal or lower versions fail deterministically.

The proposed stable version must match the reviewed class exactly. There is no "at least this big" rule and no skipped numeric increments:

| Class | Exact required increment | Valid example | Invalid examples |
| --- | --- | --- | --- |
| `"major"` | `proposed.major == current.major + 1`; `proposed.minor == 0`; `proposed.patch == 0` | `1.7.4 → 2.0.0`; `0.7.4 → 1.0.0` | `1.7.4 → 2.1.0`; `1.7.4 → 3.0.0`; `1.7.4 → 1.8.0` |
| `"minor"` | `proposed.major == current.major`; `proposed.minor == current.minor + 1`; `proposed.patch == 0` | `1.7.4 → 1.8.0`; `0.7.4 → 0.8.0` | `1.7.4 → 1.8.1`; `1.7.4 → 1.9.0`; `1.7.4 → 2.0.0` |
| `"patch"` | `proposed.major == current.major`; `proposed.minor == current.minor`; `proposed.patch == current.patch + 1` | `1.7.4 → 1.7.5`; `0.7.4 → 0.7.5` | `1.7.4 → 1.7.6`; `1.7.4 → 1.8.0`; `1.7.4 → 2.0.0` |

The exact rules also apply before version `1.0.0`. For example, `0.3.2 → 0.3.3` is PATCH, `0.3.2 → 0.4.0` is MINOR, and `0.3.2 → 1.0.0` is MAJOR. G1 has no special `0.x` compatibility rule.

A version increment must agree with the supplied class. For example, class `major` with `1.2.3 → 1.2.4` fails, class `minor` with `1.2.3 → 1.2.4` fails, and class `patch` with `1.2.3 → 2.0.0` fails. A larger numeric change does not satisfy a smaller class.

### Validator and lifecycle boundary

The future versioning validator has distinct conceptual operations for first release and `publish_new_version`. First-release validation receives the candidate release object and version-review refs, requires its exact G1 shape and valid `version`, and has no prior version or class. New-version validation receives the current released version, proposed version, and compatibility record. A successful operation returns `{:ok, evidence_refs}`; ordinary validation failure returns `{:error, diagnostics}` deterministically rather than raising an exception. Exact function names and diagnostic codes are implementation details.

The versioning validator supplies a guard result. It does not call `Lifecycle.transition/3`, mutate the manifest, set or increment `release.version`, choose a next version, or rewrite malformed input. A separate release orchestrator composes the versioning result with fingerprint, capability, Storybook, and provenance-clearance results. Versioning does not run those other checks itself.

At minimum, failures are deterministic for an invalid release shape, missing or invalid version, unsupported prerelease/build metadata, invalid current version, invalid proposed version, invalid compatibility record or class, a version that is not greater, an increment mismatch, and invalid evidence refs.

The validator is static deterministic metadata validation. It requires no database, Redis, ETS, Cachex, GenServer, Oban, PubSub, network access, or filesystem scan. Elixir's standard SemVer-aware `Version` facilities may be used when they match this contract. Parsing success alone is insufficient: G1 must also enforce stable-core syntax, the exact release shape, and exact one-step increments. Do not add a third-party SemVer dependency unless it is demonstrably necessary.

A normal `publish_new_version` action is lifecycle-valid only from `RELEASED`, as defined in docs/23. Versioning does not repeat the lifecycle state machine or reject `DEPRECATED`, `WITHDRAWN`, or `RETIRED` based on manifest state. A lifecycle failure remains a lifecycle failure.

## 5. Element and item deprecation

Deprecating one public contract element is distinct from moving the whole CatalogueItem to `DEPRECATED`.

- Announce a public element deprecation in a MINOR release and keep the element compatible.
- Remove the element only in a later MAJOR release.
- Record the deprecation in release documentation and maintain the compatibility behavior during the deprecation period.

A trusted compatibility review supplies `"minor"` for the announcement and `"major"` for the later removal, with evidence refs. Element deprecation adds no Catalogue lifecycle state or `release` key. Versioning code does not discover element deprecation or removal by diffing contracts.

Whole-item deprecation requires a rationale. Set `superseded_by` when a replacement exists. A deprecated item remains traceable and available for compatibility lookup, but normal feature work stops. Retirement removes it from active Catalogue discovery while preserving its historical identity.

The normal `publish_new_version` transition remains available only from `RELEASED`. G1 adds no `hotfix_deprecated`, `emergency_release`, `revive`, or `republish` path. Any exceptional post-deprecation release process requires a separate governance decision.

## 6. Catalogue release and package publication

CatalogueItem `RELEASED` is an item-level Catalogue/distribution state. It does not imply Mix, Hex, GitHub, or other package publication. Package publication is a separate lifecycle fact and requires its own evidence.

CatalogueItem `release.version` and package version are independent. These values do not supply current or proposed CatalogueItem versions or determine its SemVer:

- `apps/live_frames/mix.exs` version;
- Hex version;
- GitHub release or tag;
- `introduced_in_package`;
- `last_changed_in_package`;
- manifest `schema_version`.

Do not read `Mix.Project.config()[:version]` to determine CatalogueItem SemVer.

For example, `schema_version = 1` with `release.version = "4.2.0"` is conceptually valid. A future schema-version migration does not inherently change CatalogueItem SemVer. Optional fields such as `introduced_in_package` and `last_changed_in_package` may record package linkage only.

Do not claim Hex or package publication unless repository evidence proves it. This policy makes no package-publication claim.

## 7. Hypothetical Hero examples

The following are compatibility examples for a hypothetical future CatalogueItem that references the accepted native Hero component. They do not claim that Hero has been admitted or released:

- Removing a documented public Hero attr would require MAJOR review classification.
- Adding an optional Hero attr with a safe default would require MINOR review classification.
- Refactoring Hero's private markup while preserving public semantics would require PATCH review classification.

The accepted Phase-6 Hero tracer state remains separate from any CatalogueItem version.
