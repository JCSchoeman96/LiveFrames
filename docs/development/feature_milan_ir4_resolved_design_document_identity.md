# Feature Milan IR4 resolved DesignDocument identity

## Status

```text
LIFECYCLE=resolved_design_document_identity_review_ready
TERMINAL_STATE=RESOLVED_DESIGN_DOCUMENT_IDENTITY_REVIEW_READY
STOP=NONE

BASE_SHA=ee39969b5d9b848aef25f825189d7646b70390f6
BASE_TREE=c13cec5a65c1fe477e027e9810689aa8d13a9b2e
BASE_CI_RUN=39047078001
BASE_CI_RESULT=success
BASE_CI_URL=https://github.com/JCSchoeman96/LiveFrames/actions/runs/39047078001
```

This record freezes the resolved DesignDocument identity for Feature Milan. It uses the accepted pre-resolution document and the accepted BreakpointAuthority. The resolver changed only each responsive override's resolution status and numeric range. No Behavior artifact was reissued.

## Source identities and replay

```text
PRIVATE_MILAN_PATH=/home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/feature-section-milan/bricks-component-ybsqrl-feature-section-milan.json
PRIVATE_MILAN_SHA256=f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132
PRIVATE_SOURCE_EXECUTED=NO

ACSS_PATH=/home/jcschoeman96/projects/current/LiveFrame/fixtures/automatic_css/acss_settings.json
ACSS_SHA256=19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05
```

Each of two independent `mix run --no-start` invocations reloaded the inputs and performed the normalization, resolution, validation, encoding, and identity derivation. The Milan export was used as JSON data. Its embedded JavaScript and PHP were not executed. Canonical IR bytes remained under `/tmp` and were not committed.

The replay used the frozen adapter calls without additional options:

```elixir
LiveFrames.Adapters.AutomaticCSS.from_file(
  acss_path,
  source_version: "4.0.1",
  source_version_status: "fixture_reference",
  strict: true,
  profile: :hero_foundation
)

LiveFrames.Adapters.Bricks.to_ir(
  milan_path,
  component_id: "ybsqrl",
  token_set: token_set
)
```

## Accepted BreakpointAuthority

```text
BREAKPOINT_AUTHORITY_PATH=sources/work/feature_milan/fidelity/breakpoint_authority.json
BREAKPOINT_AUTHORITY_SHA256=e507d7d6ff33bbb4fb0880d46c44f3b5337d6c95c227154e11510e6a7a2c1b34
AUTHORITY_VALIDATION=PASS
AUTHORITY_STATUS=accepted
AUTHORITY_LEVEL=3
AUTHORITY_TYPE=direct_source_environment_runtime_confirmed

MOBILE_LANDSCAPE_SOURCE_WIDTH=767
MOBILE_LANDSCAPE_MIN_WIDTH=nil
MOBILE_LANDSCAPE_MAX_WIDTH=767
MOBILE_LANDSCAPE_UNIT=px
MOBILE_LANDSCAPE_QUERY=max-width
MOBILE_LANDSCAPE_MEDIA=@media (max-width: 767px)
MOBILE_LANDSCAPE_ENABLED=true
MOBILE_LANDSCAPE_CASCADE_ORDER=3
```

The replay loaded and validated the authority through `LiveFrames.Responsive.BreakpointAuthority.from_file/1`.

## Pre-resolution identity

```text
PRE_RESOLUTION_IR_VERSION=4.0.0
PRE_RESOLUTION_CANONICALIZATION_ID=lf-ir-serializer-v1
PRE_RESOLUTION_DIGEST_ALGORITHM=sha-256
PRE_RESOLUTION_CANONICAL_BYTES_LENGTH=412691
PRE_RESOLUTION_DESIGN_DOCUMENT_DIGEST=74cf822d0b0346a5d0526de387d42773b0bcc4a03475ea2dd6f64fe458690d59

PRE_RESOLUTION_ROOT_NODE_COUNT=1
PRE_RESOLUTION_TOTAL_NODE_COUNT=17
PRE_RESOLUTION_RESPONSIVE_OVERRIDE_COUNT=3
PRE_RESOLUTION_RESPONSIVE_PROPERTY_VALUE_COUNT=6
PRE_RESOLUTION_RESPONSIVE_BREAKPOINT_IDS=mobile_landscape
PRE_RESOLUTION_RESPONSIVE_STATUS=unresolved
PRE_RESOLUTION_IR_VALIDATION=PASS
```

The pre-resolution document was validated and encoded with `LiveFrames.IR.validate/1` and `LiveFrames.IR.encode!/1`. `LiveFrames.IR.Identity.from_document/1` returned the recorded identity.

## Resolution result

```text
RESOLVER_RESULT=OK
IR_VALIDATION_AFTER_RESOLUTION=PASS

RESPONSIVE_OVERRIDE_COUNT=3
RESPONSIVE_PROPERTY_VALUE_COUNT=6
RESPONSIVE_BREAKPOINT_IDS=mobile_landscape
RESPONSIVE_RESOLUTION_STATUS=resolved
MOBILE_LANDSCAPE_MIN_WIDTH=nil
MOBILE_LANDSCAPE_MAX_WIDTH=767

RESPONSIVE_OVERRIDE_OBJECTS_ALL_RESOLVED=YES
RESPONSIVE_STYLE_VALUES_UNCHANGED=YES
ALLOWED_RESPONSIVE_TRANSITION_ONLY=YES
PRE_POST_DOCUMENT_MATCH_EXCEPT_ALLOWED_RESPONSIVE_FIELDS=YES
```

For all three overrides, `resolution_status` changed from `unresolved` to `resolved`, `min_width` remained `nil`, and `max_width` changed from `nil` to `767`. The breakpoint name, properties, and all six responsive property values stayed the same.

## Whole-document invariants

```text
ROOT_NODE_COUNT=1
TOTAL_NODE_COUNT=17
NODE_ID_SET_UNCHANGED=YES
NODE_ORDER_UNCHANGED=YES
NODE_SEMANTIC_TYPES_UNCHANGED=YES
NODE_TOPOLOGY_UNCHANGED=YES
STRUCTURAL_INVARIANTS_MATCH=YES

COLLECTION_BINDING_COUNT=2
COLLECTION_BINDING_IDS_UNCHANGED=YES
COLLECTION_BINDINGS_UNCHANGED=YES
VALUE_BINDING_COUNT=4
VALUE_BINDING_IDS_UNCHANGED=YES
VALUE_BINDINGS_UNCHANGED=YES
ASSET_REGISTRY_UNCHANGED=YES
INTERACTION_REGISTRY_UNCHANGED=YES
STYLE_VALUES_UNCHANGED=YES

BASE_STYLE_ENTRY_COUNT=73
RESPONSIVE_STYLE_ENTRY_COUNT=6
COMPLEX_CSS_VALUE_COUNT=3
CUSTOM_CSS_RESIDUAL_COUNT=3
STATE_RULE_COUNT=0

BEHAVIOR_REFERENCE_NODE_SET_STILL_PRESENT=YES
B41076_TARGET_KIND=text
B41076_VALUE_KIND=field
B41076_SCOPE=collection_item
B41076_VALUE_KEY=content.body
B41076_MODIFIER_KIND=word_limit
B41076_MODIFIER_COUNT=16
B41076_NORMALIZATION_STATUS=normalized
05E604_COLLECTION_BINDING=NONE
```

The binding registry IDs remain:

```text
COLLECTION_BINDING_IDS=
  cb_node_000001_000001_000001_000002_000001
  cb_node_000001_000001_000002_000001

VALUE_BINDING_IDS=
  vb_node_000001_000001_000001_000002_000001_000001_text_000001
  vb_node_000001_000001_000001_000002_000001_000002_000001_text_000001
  vb_node_000001_000001_000001_000002_000001_000002_000002_000001_asset_000001
  vb_node_000001_000001_000002_000001_000001_asset_000001
```

The resolver's output matched the pre-resolution document after the three permitted responsive fields were normalized back to their original values. The comparison covered node topology and order, registries, base styles, responsive properties, assets, interactions, diagnostics, and provenance.

The Behavior reference node set remains:

```text
node_000001
node_000001_000001_000001_000002_000001
node_000001_000001_000001_000002_000001_000002_000001
node_000001_000001_000002_000001
```

## Diagnostic semantics

```text
DIAGNOSTIC_LIST_MUTATED=NO
DIAGNOSTIC_SEVERITY_COUNTS=warning:39
bricks.breakpoint.unresolved=6
BREAKPOINT_UNRESOLVED_DIAGNOSTIC_COUNT=6

BREAKPOINT_UNRESOLVED_DIAGNOSTICS_CLASS=historical_normalization_findings
CURRENT_BREAKPOINT_RESOLUTION_SOURCE=ResponsiveOverride.resolution_status + min_width/max_width
CURRENT_MOBILE_LANDSCAPE_STATUS=resolved
CURRENT_MOBILE_LANDSCAPE_MAX_WIDTH=767
```

The six `bricks.breakpoint.unresolved` diagnostics record the normalization-time absence of numeric breakpoint authority. They are preserved source findings. They do not override the later authority-bound `ResponsiveOverride.resolution_status=:resolved` and `max_width=767`.

## Resolved identity and repeatability

```text
RESOLVED_IR_VERSION=4.0.0
RESOLVED_CANONICALIZATION_ID=lf-ir-serializer-v1
RESOLVED_DIGEST_ALGORITHM=sha-256
RESOLVED_CANONICAL_BYTES_LENGTH=412682
RESOLVED_CANONICAL_BYTES_SHA256=1fdc6e859bdb624f0931106f78a46b25baae89f807b6bfc7ba3e14ee79da1045
RESOLVED_DESIGN_DOCUMENT_DIGEST=1fdc6e859bdb624f0931106f78a46b25baae89f807b6bfc7ba3e14ee79da1045

RUN_1_BYTES_LENGTH=412682
RUN_2_BYTES_LENGTH=412682
RUN_1_SHA256=1fdc6e859bdb624f0931106f78a46b25baae89f807b6bfc7ba3e14ee79da1045
RUN_2_SHA256=1fdc6e859bdb624f0931106f78a46b25baae89f807b6bfc7ba3e14ee79da1045
DETERMINISTIC_BYTES_MATCH=YES
DETERMINISTIC_IDENTITY_MATCH=YES
RESOLVED_DIGEST_DIFFERS_FROM_PRE_RESOLUTION=YES
```

## Scope boundary

```text
Q12=RESOLVED
Q13_RESOLVED=NO
UNSUPPORTED_NODE_ID=node_000001_000002
UNSUPPORTED_NODE_BLOCKER_CURRENT=YES

POST_RESOLUTION_BEHAVIOR_BINDING_CREATED=NO
POST_RESOLUTION_BEHAVIOR_CONTRACT_CREATED=NO
POST_RESOLUTION_BEHAVIOR_REVIEW_CREATED=NO

A1_STARTED=NO
P7_D0_STARTED=NO
COMPONENT_PROPOSER_STARTED=NO
```

This record freezes the DesignDocument identity needed before BehaviorBinding and BehaviorContract can be reissued. It does not authorize that reissue or any later work.
