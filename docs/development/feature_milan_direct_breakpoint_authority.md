# Feature Milan direct breakpoint authority

```text
Q12=RESOLVED
BREAKPOINT_AUTHORITY_EVIDENCE_COMPLETE=YES
AUTHORITY_CREATION_RESULT=CREATED_PENDING_REVIEW

tablet_portrait=991px
mobile_landscape=767px
mobile_portrait=478px
mobile_landscape_query_semantics=max-width
mobile_landscape_media_condition=@media (max-width: 767px)
mobile_landscape_enabled=true
mobile_landscape_cascade_order=3

E02_RUNTIME_VERSION=UNPROVEN
E02_REQUIRED_FOR_Q12=NO

ACSS_BRICKS_MAPPING=UNPROVEN
ACSS_L_M_S_MAPPING_PROVEN=NO
OWNER_OBSERVED_766_REPRODUCED=NO
HERO_INDIA_AUTHORITY_IMPORTED=NO

Q13_RESOLVED=NO
UNSUPPORTED_NODE_ID=node_000001_000002
UNSUPPORTED_NODE_BLOCKER_CURRENT=YES
```

The authority uses the live DanBricks Bricks breakpoint data and toolbar values,
cross-checked against the generated frontend media queries. Bricks reports
`mobile_landscape=767` and emits `@media (max-width: 767px)`. This direct source
evidence resolves Q12 without assigning an exact Bricks runtime version or
using a version-matched default fallback. ACSS L/M/S mapping remains unproven.

The earlier preflight correctly left the authority fields open because it had
no Milan-to-environment link or direct runtime evidence. The later Milan corpus
and DanBricks snapshot match, authenticated builder capture, and emitted CSS
fill those gaps. The preflight remains unchanged as a historical record.

Evidence identities:

- Milan private artifact SHA-256:
  `f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132`
- DanBricks SQL snapshot SHA-256:
  `78aa02fe494dd5e07e46e09323c0328e68a5cbc08902a08c0b0b61a158e5bef7`
- Direct evidence capture SHA-256:
  `c4050958d5993eb028ad2440ebd923b27fd611a1432525b5e4d0399785a9ad86`

## Owner-scoped publication clearance

The project owner approved public-repository publication on 2026-10-17 only
for the sanitized Feature Milan Q12 breakpoint interoperability facts and
minimum provenance metadata: DanBricks source-environment identity; breakpoint
names and widths `991px`, `767px`, and `478px`; `px` units; `max-width`
semantics and exact media conditions; enabled state; cascade order; and the
hashes needed to trace the evidence. This scope is recorded in the
[canonical provenance register](../04_SOURCE_AND_PROVENANCE.md). It excludes
the private Milan export, DanBricks SQL/database contents, screenshots
themselves, credentials, proprietary Bricks or Automatic.css source, ACSS
configuration exports, generated stylesheets, and unrelated source or private
evidence.
Broader Bricks and Automatic.css provenance status is unchanged.

## Durable sanitized source capture

```text
CAPTURE_MODE=authenticated_read_only_source_environment
SOURCE_ENVIRONMENT=DanBricks

LIVE_BREAKPOINT_ORDER=
desktop > tablet_portrait > mobile_landscape > mobile_portrait

LIVE_BREAKPOINTS=
desktop=1279
tablet_portrait=991
mobile_landscape=767
mobile_portrait=478

MOBILE_LANDSCAPE_ENABLED=true

GENERATED_MEDIA_QUERIES=
@media (max-width: 991px)
@media (max-width: 767px)
@media (max-width: 478px)

DIRECT_EVIDENCE_MANIFEST_SHA256=
c4050958d5993eb028ad2440ebd923b27fd611a1432525b5e4d0399785a9ad86

SETTINGS_CHANGED=NO
SAVE_CLICKED=NO
CSS_REGENERATED=NO

E02_RUNTIME_VERSION=UNPROVEN
ACSS_L_M_S_MAPPING=UNPROVEN
OWNER_OBSERVED_766_REPRODUCED=NO
```

Sanitized screenshot evidence references (hashes only; image files are not
published):

- Bricks breakpoint manager capture:
  `ced1a1837dd290cf3ad2c7db11020fa22ab979b1a30843919beb129917186506`
- ACSS website dimensions capture:
  `95edd01c8cb70d1a4808122e738b3c436f9045245e5d8a62169b018e3da5df1b`

This change creates breakpoint authority only. It does not resolve the
DesignDocument, reissue Behavior artifacts, start A1 or P7-D0, or waive Q13.
