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

This change creates breakpoint authority only. It does not resolve the
DesignDocument, reissue Behavior artifacts, start A1 or P7-D0, or waive Q13.
