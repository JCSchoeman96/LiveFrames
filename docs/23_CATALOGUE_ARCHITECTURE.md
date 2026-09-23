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

The immutable, globally unique, human-readable ID is the semantic CatalogueItem
identity. **Owner approval (#38, 2026-09-23):** v1 Catalogue IDs use exactly the
grammar below. Invalid IDs are rejected; validators must not normalize or coerce
input into a canonical ID.

### v1 ID contract

| Rule | Value |
| --- | --- |
| Shape | `live_frames.<kind>.<key>` |
| Namespace | Literal `live_frames` in v1 |
| Segment count | Exactly 3 (no deeper namespaces in v1) |
| Kind | One of: `primitive`, `component`, `pattern`, `section`, `page`, `template` |
| Key | Lowercase ASCII snake-case semantic key |
| Key regex | `^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$` |
| Machine slug | Exactly `<key>` (third segment) |
| Normalization | None; reject invalid input |
| Case folding | None; uppercase in any segment is invalid |
| Identity source | The ID itself, never module, file, or source-builder identity |

Third-party or federated publisher namespaces (for example `acme.section.hero`)
are **not** part of v1. If marketplace or plugin ownership is required later,
design it explicitly; existing `live_frames.*` IDs remain valid.

The ID's meaning and the manifest's `kind` must agree. Fundamentally different
concepts must have different IDs. The complete ID is globally unique. Both `id`
and `kind` are immutable after admission. An ID remains reserved after WITHDRAWN
or RETIRED and must never be reused.

There is **no `slug` field** in the manifest. Slug and path are derived from
`id` and `kind` only, so identity does not admit four competing authorities.

### Slug and path derivation

For every valid v1 ID:

~~~text
id    = live_frames.<kind>.<key>
slug  = <key>
path  = <catalogue_root> / <kind_directory> / (<key> <> ".json")
~~~

Where `<catalogue_root>` is `apps/live_frames/priv/catalogue/` and
`<kind_directory>` is the plural directory for `<kind>`:

| Kind | Directory |
| --- | --- |
| primitive | primitives |
| component | components |
| pattern | patterns |
| section | sections |
| page | pages |
| template | templates |

Examples:

~~~text
live_frames.section.hero
→ kind: section, slug: hero
→ apps/live_frames/priv/catalogue/sections/hero.json

live_frames.pattern.command_palette
→ kind: pattern, slug: command_palette
→ apps/live_frames/priv/catalogue/patterns/command_palette.json
~~~

### Collision invariant

One valid Catalogue ID corresponds to exactly one kind, one machine slug, and
one canonical manifest path. Two different valid v1 IDs cannot derive the same
path. Duplicate immutable IDs or duplicate canonical paths are validation
failures. There is no first-wins, overwrite, merge, or auto-renaming behavior.

### Filesystem portability

Reject derived slugs whose basename (case-insensitive) is a Windows-reserved
device name: `con`, `prn`, `aux`, `nul`, `com1`–`com9`, and `lpt1`–`lpt9`.
This keeps the Catalogue check-out and packaging reliable across platforms.

### Valid and invalid IDs (v1)

| ID | Result | Reason |
| --- | --- | --- |
| `live_frames.primitive.icon` | valid | canonical |
| `live_frames.component.avatar` | valid | canonical |
| `live_frames.pattern.command_palette` | valid | snake-case semantic key |
| `live_frames.section.hero` | valid | canonical |
| `live_frames.page.marketing_home` | valid | canonical |
| `live_frames.template.saas_marketing` | valid | canonical |
| `live_frames.sections.hero` | invalid | kind must be singular canonical kind |
| `live_frames.section.Hero` | invalid | uppercase |
| `live_frames.section.hero-split` | invalid | hyphen |
| `live_frames.section.hero.split` | invalid | fourth segment / deeper namespace |
| `live_frames.section._hero` | invalid | key regex |
| `live_frames.section.hero__split` | invalid | non-canonical consecutive separator |
| `live_frames.hero` | invalid | missing kind |
| `other.section.hero` | invalid in v1 | namespace is not `live_frames` |

Validators must reject non-canonical forms such as `Live_Frames.Section.Hero` or
`live_frames.section.hero-split`. They must never silently rewrite them to
`live_frames.section.hero` or `live_frames.section.hero_split`.

A mismatch among `id`, `kind`, derived slug, or canonical path is invalid.
`display_name` is mutable presentation metadata and does not change identity.

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
| id, kind | Immutable identity and one allowed taxonomy value. No separate `slug` field; slug and path are derived per §2. |
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

The fingerprint protects the documented, consumer-facing component contract. It
is a deterministic contract-drift detector; it is not the sole SemVer or
compatibility oracle. Internal or private refactors that preserve the public
contract must not change the fingerprint.

**Owner approval (#39, 2026-09-23):** G1 v1 uses the exact algorithm contract
below.

### v1 fingerprint algorithm

| Rule | Value |
| --- | --- |
| Algorithm identifier | `lf-contract-v1-jcs-sha256` |
| Normalized document format | `lf-contract-v1` |
| Canonical serialization | RFC 8785 JSON Canonicalization Scheme (JCS) |
| Digest | SHA-256 over the exact UTF-8 JCS bytes |
| Stored fingerprint | Exactly 64 lowercase hexadecimal characters |
| Unicode normalization | None; preserve exact Unicode string content |
| Unknown algorithm identifier | Validation failure |

The manifest stores both
`contract.fingerprint_algorithm = "lf-contract-v1-jcs-sha256"` and the
resulting lowercase hexadecimal `contract.fingerprint`.

The hash input is a separate normalized public-contract document. The Catalogue
manifest itself is not hashed. Catalogue ID, lifecycle state, CatalogueItem
SemVer, Storybook metadata, provenance, source paths, package metadata, and the
fingerprint fields themselves are not part of the normalized contract document.

The normalized top-level document has exactly these conceptual areas:

~~~json
{
  "format": "lf-contract-v1",
  "component": {
    "module": "LiveFrames.Components.Sections.Hero",
    "function": "hero"
  },
  "attrs": [],
  "slots": [],
  "capabilities": [],
  "css_theme_contract": []
}
~~~

The component module uses the fully-qualified normal Elixir module name without
the internal `Elixir.` prefix. The exported function is an exact string.
Changing either changes the public contract fingerprint.

### Public attributes

Each public attribute normalizes to a record containing exactly the public
semantics required by G1:

~~~text
name
type
required
default
constraints
~~~

Attribute records are sorted by `name`; source declaration order is ignored.

Types use an explicit representation rather than `inspect/1`. Built-in types
record their stable public type name. Struct/module-backed types record their
fully-qualified public module name. A future type form that has no approved
canonical representation is unsupported and fingerprint extraction must fail.

Defaults distinguish the absence of a declared default from an explicit default
whose value is `nil`:

~~~json
{"present": false}
~~~

~~~json
{"present": true, "value": null}
~~~

This distinction is part of the normalized public contract.

### Canonical values

Fingerprint extraction must never use arbitrary Elixir `inspect/1` output as a
canonical value representation.

The v1 canonical value algebra is:

| Elixir/public value | Canonical meaning |
| --- | --- |
| `nil` | JSON null |
| boolean | JSON boolean |
| UTF-8 binary/string | Exact JSON string |
| integer | Tagged exact base-10 integer string |
| float | Tagged exact IEEE-754 binary64 bit-pattern representation |
| atom | Tagged exact atom-name string |
| list | Tagged ordered sequence of recursively canonical values |
| tuple | Tagged ordered sequence of recursively canonical values |
| map | Tagged canonical key/value entries sorted by canonical key representation |
| finite range | Tagged exact range semantics when the range itself is the value |
| unsupported/opaque term | Deterministic extraction failure |

Functions, PIDs, ports, references, and opaque values without an explicitly
approved canonicalizer are unsupported. Validation must fail rather than fall
back to source text, `inspect/1`, or another unstable representation.

### Constraints

Only machine-significant public constraints enter the normalized contract.
Documentation examples that do not constrain accepted consumer input do not.

An exhaustive allowed-values constraint is a semantic **set**. Its members are
canonicalized, duplicates are invalid, and the canonical member
representations are sorted before JCS serialization. Source ordering therefore
does not affect the fingerprint.

Equivalent exhaustive constraints such as the same finite values declared in a
different order must fingerprint identically. A finite range used as an
exhaustive values constraint normalizes to the same accepted-value set as the
equivalent explicit finite values.

For public global-attribute extensions, any explicitly supported added names or
prefixes are normalized as sorted unique semantic sets. Changing that supported
surface changes the fingerprint.

### Public slots

Each v1 public slot normalizes to:

~~~text
name
required
min_entries
max_entries
~~~

`max_entries = null` means unbounded. Slot records are sorted by `name`;
source declaration order and Storybook ordering are ignored.

If repository-owned component validation narrows a slot's documented public
cardinality beyond the framework declaration, the normalized record must reflect
the documented public consumer contract.

### Capabilities and CSS/theme contract

`capabilities` and `css_theme_contract` are sorted, unique semantic sets of
stable public identifiers.

The CSS/theme set records documented public extension-point identifiers such as
public `--lf-*` custom-property names. It does not record their current
generated values merely because those values changed, and it excludes
component-private `--lf-hero-*` variables, private selectors, private classes,
private DOM shape, and implementation-only styling details.

Removing, renaming, or adding a documented public extension-point identifier is
a public-contract change and therefore changes the fingerprint.

### Deterministic ordering

Normalize unordered semantic collections before JCS serialization:

| Collection | v1 treatment |
| --- | --- |
| JSON object properties | RFC 8785 JCS ordering |
| attrs | Sort by canonical attr name |
| slots | Sort by canonical slot name |
| exhaustive allowed values | Unique semantic set; canonicalize then sort |
| capabilities | Unique semantic set; sort |
| CSS/theme contract identifiers | Unique semantic set; sort |
| list/tuple default values where order is observable | Preserve order |
| maps | Ignore source key order; sort canonical key/value representation |
| source declaration order | Ignore unless order is itself public semantics |

Equivalent normalized public contracts must therefore produce byte-identical JCS
input and the same SHA-256 fingerprint.

### Algorithm migration

The algorithm identifier is durable and participates in validation dispatch.
Unknown algorithm identifiers fail closed.

A future algorithm change, for example from
`lf-contract-v1-jcs-sha256` to a separately approved v2 identifier, is an
explicit tooling/schema metadata migration. It does **not** by itself represent
a component-contract change and must not require a CatalogueItem SemVer bump
solely because the fingerprint algorithm changed.

Fingerprints produced by different algorithm identifiers are not directly
comparable. Migration must recompute the fingerprint under the new algorithm,
record the new identifier, and revalidate the same public contract. It must not
silently rewrite an algorithm identifier or pretend old and new digests have the
same comparison domain.

### v1 scope boundary

The G1-approved fingerprint scope covers component module/function, public attrs,
public slot name/cardinality/requiredness, documented public capabilities, and
documented public CSS/theme contract references.

G1 v1 does **not** silently expand that scope to arbitrary slot-attribute schemas
or arbitrary machine-encoded cross-field runtime invariants. A future component
whose compatibility materially depends on such semantics requires an explicit
fingerprint-scope extension before those semantics can be claimed as covered by
the fingerprint.

This limitation does not make such public behavior irrelevant to compatibility.
`docs/24_CATALOGUE_VERSIONING_POLICY.md` remains the compatibility and SemVer
authority. The fingerprint assists deterministic drift detection; compatibility
review remains authoritative.

Exclude source paths, line numbers, private helpers, private CSS classes or
variables, internal DOM shape, prose formatting, Storybook ordering, Catalogue
metadata, and implementation-only markup. If a change affects the normalized
consumer-visible scope above, the fingerprint changes. If only excluded private
implementation details change, it does not.

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
