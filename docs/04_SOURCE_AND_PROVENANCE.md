# Source and provenance

This is LiveFrames’ canonical durable policy for source provenance and
publication state. The [Master Specification](00_LIVEFRAMES_MASTER_SPEC.md)
remains the architecture/product authority, and the [Phase 5 hardening and
acceptance authority](18_PHASE_5_HARDENING_AND_ACCEPTANCE.md) remains the
current execution authority. This document owns the provenance facts,
publication lifecycle, source-location boundaries, and current governance
register used by both.

This policy records repository evidence; it does not make a legal conclusion.
Unknown ownership, license, project-use, or redistribution facts remain
unknown. Repository presence, possession, hashing, technical review, or
conversion success does not establish permission.

## Separate internal use from redistribution

Every source record must keep these facts separate:

- `internal_use_status`: whether explicit evidence or project policy permits
  the recorded internal use, including its scope. For example, approval for
  internal conversion is narrower than approval for general project use.
- `redistribution_status`: whether explicit evidence permits public repository
  or release distribution.
- `publication_state`: the lifecycle state below; it must not be inferred
  from a file’s location or from an unqualified word such as “reviewed” or
  “approved.”

`internal_use_status = approved` never implies
`redistribution_status = approved`. `redistribution_status = unknown` means
redistribution is unresolved; it does not mean that the material is illegal,
that ownership is disproven, or that a license conclusion has been made.

The `SourceArtifact` conversion lifecycle in the Master Specification is a
separate concern. It must not be used as a substitute for this publication
lifecycle.

## Required provenance record

For each source group with meaningful provenance, record the following where
known and use `unknown` where evidence is absent:

- source name and identifiable source group
- source system
- source version
- source URL or origin reference
- vendor/author where known
- origin type
- license status or license-reference status
- internal-use status and scope
- redistribution status
- content hash where available, preferably SHA-256
- evidence/reference paths
- current `publication_state`

Unknown is an acceptable recorded value. It is not permission to fill in a
guess.

## Source publication state machine

The single publication lifecycle is:

```text
discovered
→ classified
→ internal_use_approved
→ redistribution_review
→ public_safe
```

Exceptional or terminal states are:

```text
private_only
rejected
removed_from_active_use
```

### State definitions

- `discovered`: the source has been encountered but is not sufficiently
  classified.
- `classified`: the source identity and known provenance facts have been
  recorded.
- `internal_use_approved`: explicit evidence or policy permits the recorded
  internal project use. This does not imply public redistribution.
- `redistribution_review`: the source is being evaluated specifically for
  public repository or release distribution.
- `public_safe`: explicit evidence permits public redistribution under
  project policy. This is a qualified publication state, not a general legal
  conclusion.
- `private_only`: the source may be retained for private/internal reference
  because public redistribution has not been established.
- `rejected`: the source may not be used under project authority.
- `removed_from_active_use`: the source is no longer an active project input;
  historical provenance may remain recorded.

### Transition guards

`discovered → classified` requires:

- an identifiable source;
- origin recorded where known;
- source system recorded;
- vendor/author recorded where known;
- license status recorded;
- internal-use status recorded;
- redistribution status recorded.

Unknown is acceptable for any fact when it is explicitly recorded.

`classified → internal_use_approved` requires explicit internal-use authority
for the recorded scope. Possession of a file is not authority.

`internal_use_approved → redistribution_review` requires an explicit intent to
evaluate the source for public repository or release distribution.

`redistribution_review → public_safe` requires explicit clearance for public
redistribution. Unknown is insufficient.

An otherwise eligible state may transition to `private_only` when
internal/reference retention may continue while redistribution is not
established.

Any state may transition to `rejected` when project authority determines the
source is unusable.

### Terminal and publication invariants

For publication decisions, `public_safe`, `private_only`, and `rejected` are
terminal until explicit new evidence triggers re-review. `removed_from_active_use`
is terminal for active inputs; its historical provenance may remain recorded.

Never silently transition `unknown` to `public_safe`. “Reviewed” is not a
publication state: qualify it as reviewed for internal use or approved for
public redistribution.

## Public repository gate

For new material:

```text
redistribution != explicitly_allowed
    ↓
MUST NOT be newly added to public fixtures/ or public sources/
```

This applies to vendor exports, commercial plugin data, design packs, client
material, screenshots, assets, copied CSS/JS, Figma exports, Webflow exports,
and other third-party source evidence. Existing public material is not
retroactively cleared by this rule; its unresolved status is recorded below
for explicit human governance review.

## Source-location boundaries

These are repository placement rules, not permission grants:

- `private_reference/` is for actual vendor/plugin evidence,
  confidential/private exports, source-environment evidence, and material
  whose redistribution is not established. Private reference evidence must
  never become a runtime or compiler network dependency.
- `fixtures/` is for synthetic, sanitized, or explicitly
  redistribution-cleared fixtures. A fixture is not public-safe merely because
  it was technically reviewed or committed.
- `sources/` is for material explicitly appropriate for repository
  distribution. Existing historical contents remain subject to the register.
- `sources/work/` is for deterministic derived conversion/compiler artifacts.
  Derived output does not erase upstream provenance or redistribution
  obligations.

Each derived artifact must retain enough source-group identity, source hash or
trace, and provenance references to follow the conversion back to its inputs.
Its publication state cannot be more permissive than the evidence supporting
the upstream inputs; conversion success does not turn unresolved redistribution
into approval.

## Current repository-evidence register

This register reports only repository evidence. `Human review: yes` marks a
governance decision that the agent must not make. No row below declares a
license, ownership, or legal redistribution outcome.

| Source group | Current evidence and internal-use status | Redistribution evidence/status | Supported publication state | Current location | Human review |
| --- | --- | --- | --- | --- | --- |
| Bricks copied-elements export / Hero India | `fixtures/bricks/SOURCE.md` records identity, Bricks versions, internal origin, and internal-use status approved for internal conversion only; broader project use is unknown. | License and allowed redistribution are unknown; no explicit public-clearance evidence is recorded. | `internal_use_approved`, scoped to internal conversion; not `public_safe`. | `fixtures/bricks/` and duplicate `sources/bricks_components.json` | Yes — existing public material requires an explicit governance decision. |
| Automatic.css settings export | `fixtures/automatic_css/SOURCE.md` records identity, version, internal origin, and internal-use status approved for internal conversion only; broader project use is unknown. | License and allowed redistribution are unknown; no explicit public-clearance evidence is recorded. | `internal_use_approved`, scoped to internal conversion; not `public_safe`. | `fixtures/automatic_css/` and `acss/acss.json` | Yes — existing public material requires an explicit governance decision. |
| Automatic.css 4.0.1 research set | `acss/README.md` and `private_reference/REFERENCE_MANIFEST.md` identify a research-only, immutable reference set; no explicit internal-use authority is recorded for the checked-in notes. | No license or redistribution clearance is recorded; status is unknown. | `classified`; not `public_safe`. | `acss/4.0.1/` | Yes — reconcile its public location, reference path, hash, and permitted use. |
| Standalone HTML/CSS/JS experiments | Named groups under `sources/` are present, but no group-level provenance record, internal-use authority, or origin is recorded. | No redistribution evidence is recorded; status is unknown. | `discovered`; not `public_safe`. | `sources/GSAP-*`, `sources/card-carousel`, `sources/css-tooltips`, `sources/elastic-accordion`, `sources/enlarge-gallery`, `sources/infinite-scroll`, `sources/swipe-reveal`, `sources/ux-animations` | Yes — classify each group or establish verified shared provenance. |
| Derived Hero India conversion artifacts | `sources/work/hero_india/` contains deterministic Stage A, IR, fidelity, manifest, and breakpoint artifacts that retain upstream source identifiers/hashes. | Upstream Bricks/Automatic.css redistribution remains unresolved; derivation does not provide independent clearance. | Inherits upstream unresolved status; not `public_safe`. | `sources/work/hero_india/` | Yes — decide whether these are distributable derived evidence or review-only artifacts. |

The register does not move, delete, sanitize, or replace any existing payload.
It records the human decision boundary so future work does not mistake current
public location for public-redistribution approval.

## Human governance boundary

An agent may record evidence, hashes, unknown values, and derived-artifact
lineage. An agent may not independently:

- change repository visibility;
- delete committed source material or rewrite Git history;
- declare copyright, license, ownership, or redistribution permission;
- declare existing material illegally distributed;
- remove or replace source evidence in a way that changes provenance truth.

For an unresolved public group, the project owner may choose among explicit
human review and clearance, private/reference retention, removal from active
use, or another documented governance decision. Each option has repository,
history, reproducibility, and future-conversion consequences. Until that
decision is recorded, unknown redistribution remains unresolved and is
insufficient for new public publication.
