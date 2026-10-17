# Source and provenance

This is LiveFrames’ canonical durable policy for source provenance and
publication state. It owns mutable provenance facts, internal-use status,
redistribution status, publication state, and recorded human governance
decisions. Other documents may define how they consume these facts, but they
must not duplicate or supersede them. The [Master
Specification](00_LIVEFRAMES_MASTER_SPEC.md) remains the architecture/product
authority, and the [Phase 5 hardening and acceptance
authority](18_PHASE_5_HARDENING_AND_ACCEPTANCE.md) remains the current
execution authority. This document provides the governance register used by
both.

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

For G1 Catalogue release clearance, the exact positive redistribution fact is
`redistribution_status == "approved"`. The older term
`explicitly_allowed` describes explicit evidence supporting that fact. It is
not another literal `redistribution_status` value. `unknown` remains
unresolved and does not satisfy the positive check.

`publication_state == "public_safe"` is a separate positive publication fact.
Neither field sets, replaces, or implies the other.

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
redistribution_status != "approved"
    ↓
MUST NOT be newly added to public fixtures/ or public sources/
```

This applies to vendor exports, commercial plugin data, design packs, client
material, screenshots, assets, copied CSS/JS, Figma exports, Webflow exports,
and other third-party source evidence. Existing public material is not
retroactively cleared by this rule; its unresolved status is recorded below
for explicit human governance review.

Internal-use approval, a native rewrite, successful conversion, Storybook
verification, Catalogue `APPROVED`, repository presence, or existing public
location does not supply either positive fact.

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
license, ownership, or general legal redistribution outcome.

| Source group | Current evidence and internal-use status | Redistribution evidence/status | Supported publication state | Current location | Human review |
| --- | --- | --- | --- | --- | --- |
| Bricks copied-elements export / Hero India | `fixtures/bricks/SOURCE.md` records identity, Bricks versions, internal origin, and internal-use status approved for internal conversion only; broader project use is unknown. | License and allowed redistribution are unknown; no explicit public-clearance evidence is recorded. | `internal_use_approved`, scoped to internal conversion; not `public_safe`. | `fixtures/bricks/` and duplicate `sources/bricks_components.json` | Yes — existing public material requires an explicit governance decision. |
| Bricks copied-elements export / CTA Tango | `AUTHORITY=docs/04_SOURCE_AND_PROVENANCE.md`; `SOURCE_SYSTEM=Bricks copied-elements export`; `ORIGIN_REFERENCE=private_reference/frames/staging-2026-09/cta-section-tango/bricks-component-hxambs-cta-section-tango.json`; `SHA256=73f866a27070c010584babe230b5ffd0c78dc704388fd8b6c286e149a3d93a87`; `EVIDENCE_REFS=[docs/development/c09d7a_cta_tango_semantic_input_freeze.md, docs/development/c09d7a_cta_tango_component_review.md]`; `SOURCE_VERSION=unknown`; `VENDOR/AUTHOR=unknown`; `ORIGIN_TYPE=unknown`; `OWNERSHIP=unknown`; `LICENSE_STATUS=unknown`; `INTERNAL_USE_STATUS=unknown`. | `REDISTRIBUTION_STATUS=unknown`; `CLEARANCE_EVIDENCE_REFS=[]`. | `PUBLICATION_STATE=classified` | `CURRENT_LOCATION=private_reference/` | `HUMAN_REVIEW=YES`; no human clearance decision is recorded or authorized by this entry. |
| Automatic.css settings export | `fixtures/automatic_css/SOURCE.md` records identity, version, internal origin, and internal-use status approved for internal conversion only; broader project use is unknown. | License and allowed redistribution are unknown; no explicit public-clearance evidence is recorded. | `internal_use_approved`, scoped to internal conversion; not `public_safe`. | `fixtures/automatic_css/` and `acss/acss.json` | Yes — existing public material requires an explicit governance decision. |
| Automatic.css 4.0.1 research set | `acss/README.md` and `private_reference/REFERENCE_MANIFEST.md` identify a research-only, immutable reference set; no explicit internal-use authority is recorded for the checked-in notes. | No license or redistribution clearance is recorded; status is unknown. | `classified`; not `public_safe`. | `acss/4.0.1/` | Yes — reconcile its public location, reference path, hash, and permitted use. |
| Automatic.css 4.0.1 structural-grid interoperability facts | Project owner reviewed the scoped evidence on 2026-10-07. | Owner approval covers only the resolved values of `--grid-1`, `--grid-2`, and `--grid-3-2`, plus minimum verification metadata. Broader Automatic.css redistribution remains unresolved. | `public_safe` for this scoped evidence only. | `docs/evidence/c09d6_d0e1_acss_4_0_1_grid_authority.md` | Yes — scoped owner decision recorded 2026-10-07. |
| Automatic.css 4.0.1 text-scale interoperability facts | Project owner reviewed the scoped evidence on 2026-10-07. | Owner approval covers only the three-variable text-scale semantic facts, active `text-s` endpoint overrides, minimum generated controls, and verification metadata. Broader Automatic.css redistribution remains unresolved. | `public_safe` for this scoped evidence only. | `docs/evidence/c09d6_d0e2_acss_4_0_1_text_scale_authority.md` | Yes — scoped owner decision recorded 2026-10-07. |
| Feature Milan breakpoint interoperability facts | `SOURCE_ENVIRONMENT=LocalWP DanBricks`; `SOURCE_URL=http://localhost:10049`; `SOURCE_SYSTEM=Bricks`; `SOURCE_VERSION=exact runtime unknown`; Milan private artifact SHA-256 `f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132`; DanBricks SQL SHA-256 `78aa02fe494dd5e07e46e09323c0328e68a5cbc08902a08c0b0b61a158e5bef7`; direct evidence manifest SHA-256 `c4050958d5993eb028ad2440ebd923b27fd611a1432525b5e4d0399785a9ad86`. | Owner approved scoped public-repository publication on 2026-10-17 for `tablet_portrait=991px`, `mobile_landscape=767px`, and `mobile_portrait=478px`; `max-width` queries `@media (max-width: 991px)`, `@media (max-width: 767px)`, and `@media (max-width: 478px)`; `MOBILE_LANDSCAPE_ENABLED=true`; `CASCADE_ORDER=desktop > tablet_portrait > mobile_landscape > mobile_portrait`; and minimum provenance hashes. `REDISTRIBUTION_STATUS=approved` only for this scope. Broader Bricks and Automatic.css redistribution remains unresolved. | `PUBLICATION_STATE=public_safe` ONLY for these sanitized interoperability facts and minimum provenance metadata. | `docs/development/feature_milan_direct_breakpoint_authority.md`; `sources/work/feature_milan/fidelity/breakpoint_authority.json` | Yes — scoped owner decision recorded 2026-10-17. |
| Standalone HTML/CSS/JS experiments | Named groups under `sources/` are present, but no group-level provenance record, internal-use authority, or origin is recorded. | No redistribution evidence is recorded; status is unknown. | `discovered`; not `public_safe`. | `sources/GSAP-*`, `sources/card-carousel`, `sources/css-tooltips`, `sources/elastic-accordion`, `sources/enlarge-gallery`, `sources/infinite-scroll`, `sources/swipe-reveal`, `sources/ux-animations` | Yes — classify each group or establish verified shared provenance. |
| Derived Hero India conversion artifacts | `sources/work/hero_india/` contains deterministic Stage A, IR, fidelity, manifest, and breakpoint artifacts that retain upstream source identifiers/hashes. | Upstream Bricks/Automatic.css redistribution remains unresolved; derivation does not provide independent clearance. | Inherits upstream unresolved status; not `public_safe`. | `sources/work/hero_india/` | Yes — decide whether these are distributable derived evidence or review-only artifacts. |

The register does not move, delete, sanitize, or replace any existing payload.
It records the human decision boundary so future work does not mistake current
public location for public-redistribution approval.

Each scoped interoperability evidence row has its own explicit `public_safe`
boundary. The scoped states apply only to the named structural-grid or
text-scale facts, their approved minimum controls, and verification metadata
recorded in the corresponding evidence documents. `scoped_public_safe` does
not mean Automatic.css is globally `public_safe`. The existing Automatic.css
settings export and research-set rows retain their current states. Plugin
source, generated stylesheets, configuration exports, unrelated variables,
and the wider research set remain private/reference material, with broader
redistribution unresolved.

The Feature Milan decision is limited to the sanitized breakpoint
interoperability facts and minimum provenance metadata recorded in its
authority and decision record. It does not change the broader Bricks or
Automatic.css provenance status. Explicit exclusions are the private Milan
export, DanBricks SQL/database contents, screenshots themselves, credentials,
proprietary Bricks source, proprietary Automatic.css source, ACSS configuration
exports, generated stylesheets, and unrelated source or private evidence.

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
