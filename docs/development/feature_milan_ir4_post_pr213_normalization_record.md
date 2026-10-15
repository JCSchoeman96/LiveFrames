# Feature Milan IR4 post-PR213 normalization record

## Status

```text
LIFECYCLE=normalization_record_review_ready
CURRENT_IDENTITY_REVIEW_READY=YES
CURRENT_IDENTITY_ACCEPTED=NO
```

This record freezes the current-main normalization facts for Feature Milan. The identity remains a candidate until this record is reviewed and accepted. This work did not start Behavior reissue, componentization refresh, breakpoint evidence recovery, or semantic input work.

## Base and source identities

```text
BASE_SHA=dd8c942b38fd6cc261c41628797019f54185e855
BASE_TREE=9bc42a8e580c66ef420db8a6c8edefc2cd0cc523
BASE_CI_RUN=38606665281
BASE_CI_HEAD=dd8c942b38fd6cc261c41628797019f54185e855
BASE_CI_RESULT=success

PRIVATE_MILAN_SOURCE=private_reference/frames/staging-2026-09/feature-section-milan/bricks-component-ybsqrl-feature-section-milan.json
PRIVATE_MILAN_SHA256=f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132
PRIVATE_SOURCE_EXECUTED=NO

ACSS_FIXTURE=fixtures/automatic_css/acss_settings.json
ACSS_FIXTURE_SHA256=19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05
```

The Milan export was read as JSON. Its embedded JavaScript was not executed. The private export and generated canonical IR were not added to the repository.

## Frozen invocation

The replay used the source file path and these exact calls:

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

```text
SOURCE_ARGUMENT_FORM=file_path
BRICKS_OPTIONS=component_id:"ybsqrl", token_set:token_set
STRUCTURAL_VARIABLE_AUTHORITY_OPTION=omitted
THEME_STYLES_OPTION=omitted
EXTERNAL_CLASS_AUTHORITIES_OPTION=omitted
CONTAINER_WIDTH_OPTION=omitted
EXPECTED_ROOT_COUNT_OPTION=omitted

REPLAY_SCRIPT_SHA256=1a22b9d4caec8b01d96f997fcef31d6a9ec13597c5f04c47a5447b513c2bdbf9
IR_VALIDATION=:ok
CANONICAL_ENCODER=LiveFrames.IR.encode!/1
IDENTITY_API=LiveFrames.IR.Identity.from_document/1
```

The replay ran from the exact base checkout. It validated the document, encoded it with the canonical IR encoder, computed its SHA-256, and derived the DesignDocument identity. The canonical output remained under `/tmp` and is not committed.

## Current identity candidate

```text
IR_VERSION=4.0.0
CANONICAL_BYTES_LENGTH=412691
CANONICAL_SHA256=74cf822d0b0346a5d0526de387d42773b0bcc4a03475ea2dd6f64fe458690d59
CANONICALIZATION_ID=lf-ir-serializer-v1
DIGEST_ALGORITHM=sha-256
DESIGN_DOCUMENT_DIGEST=74cf822d0b0346a5d0526de387d42773b0bcc4a03475ea2dd6f64fe458690d59
EXPECTED_CANONICAL_BYTES_LENGTH=412691
EXPECTED_DESIGN_DOCUMENT_DIGEST=74cf822d0b0346a5d0526de387d42773b0bcc4a03475ea2dd6f64fe458690d59
EXPECTED_DIGEST_MATCH=YES

CURRENT_NORMALIZATION_IDENTITY_CANDIDATE=74cf822d0b0346a5d0526de387d42773b0bcc4a03475ea2dd6f64fe458690d59
CURRENT_CANONICAL_BYTES_LENGTH=412691
CURRENT_IDENTITY_REVIEW_READY=YES
CURRENT_IDENTITY_ACCEPTED=NO
```

## Structural invariants

```text
ROOT_NODE_COUNT=1
TOTAL_NODE_COUNT=17
RESPONSIVE_OVERRIDE_COUNT=3
RESPONSIVE_BREAKPOINT_IDS=mobile_landscape
COLLECTION_BINDING_COUNT=2
VALUE_BINDING_COUNT=4
```

The replay produced this node ID set, unchanged from the post-PR213 diagnostic:

```text
node_000001
node_000001_000001
node_000001_000001_000001
node_000001_000001_000001_000001
node_000001_000001_000001_000001_000001
node_000001_000001_000001_000001_000002
node_000001_000001_000001_000002
node_000001_000001_000001_000002_000001
node_000001_000001_000001_000002_000001_000001
node_000001_000001_000001_000002_000001_000002
node_000001_000001_000001_000002_000001_000002_000001
node_000001_000001_000001_000002_000001_000002_000002
node_000001_000001_000001_000002_000001_000002_000002_000001
node_000001_000001_000002
node_000001_000001_000002_000001
node_000001_000001_000002_000001_000001
node_000001_000002
```

The binding registries also retain their prior IDs:

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

### C09C4 value modifier

```text
B41076_TARGET_KIND=text
B41076_VALUE_KIND=field
B41076_SCOPE=collection_item
B41076_VALUE_KEY=content.body
B41076_MODIFIER_KIND=word_limit
B41076_MODIFIER_ARGUMENTS={"count":16}
B41076_NORMALIZATION_STATUS=normalized
```

LiveFrames does not parse or execute the source expression at runtime. The caller supplies the value after applying the word limit.

### 05E604 collection boundary

```text
05E604_COLLECTION_BINDING=NONE
05E604_DIAGNOSTIC=bricks.collection.boundary_unproven
```

No collection admission was added.

### Behavior reference nodes

```text
BEHAVIOR_REFERENCE_NODE_SET_STILL_PRESENT=YES
node_000001
node_000001_000001_000001_000002_000001
node_000001_000001_000001_000002_000001_000002_000001
node_000001_000001_000002_000001
```

Their presence confirms structural compatibility. It does not authorize reuse of the prior Behavior identities.

## Diagnostics and custom CSS

All DesignDocument diagnostics are warnings:

```text
DIAGNOSTIC_SEVERITY_COUNTS=warning:39

DIAGNOSTIC_CODE_COUNTS=
  bricks.attribute.unsupported=3
  bricks.breakpoint.unresolved=6
  bricks.collection.boundary_unproven=1
  bricks.custom_css.unsupported_declaration=1
  bricks.custom_css.unsupported_selector=9
  bricks.element.unsupported=1
  bricks.runtime.unsupported=1
  bricks.setting.unsupported=9
  bricks.variable.unresolved=8
```

The six `_cssCustom` sources retained these outcomes. The record lists source node and class IDs only; it does not include CSS text.

```text
ybsqrl/eInPPponetv=residual
ebbb6e/eInPPoxwwdh=residual
966841/eInPPqrvlve=base_style
05e604/eInPPseiwvh=base_style
30fae8/eInPPndcoxx=residual
b71f5d/eInPPbgdzgv=base_style
```

```text
BASE_STYLE_ENTRY_COUNT=73
RESPONSIVE_STYLE_ENTRY_COUNT=6
COMPLEX_CSS_VALUE_COUNT=3
CUSTOM_CSS_RESIDUAL_COUNT=3
STATE_RULE_COUNT=0
```

## PR #213 change classification

```text
INTRODUCING_PR=213
INTRODUCING_HEAD=d3f5cf0370afa56feb1faec381e6dd0e9e54b161
INTRODUCING_MERGE=504283226345e1f16d78022cf3b0840cf71077f5
CHANGE_CLASSIFICATION=INTENTIONAL_ACCEPTED_NORMALIZATION_CHANGE
```

Three safely normalizable conditionless declarations moved from opaque or residual custom CSS into structured base styles. Unsupported CSS remained inert residual evidence. The replay reports additional diagnostics for unsupported source constructs. Node topology, node IDs, responsive breakpoint identity, CollectionBinding IDs, ValueBinding IDs, ValueModifier semantics, and Behavior reference node availability remained unchanged. This record makes no claim that all Milan semantics stayed unchanged.

## Historical identity and downstream applicability

```text
HISTORICAL_DESIGN_DOCUMENT_DIGEST=52544dcc0d279d91d3d56d054c9785b18f96e77a5520b782726b678c404db864
HISTORICAL_CANONICAL_BYTES_LENGTH=387432
HISTORICAL_STATUS=accepted for the pre-PR213 normalization pipeline; superseded for current-main normalization by PR #213
HISTORICAL_RECORD_MODIFIED=NO
```

The historical record remains valid for its original pipeline. Its digest is no longer the current-main identity.

```text
OLD_BEHAVIOR_BINDING_REUSABLE=NO
OLD_BEHAVIOR_CONTRACT_REUSABLE=NO
OLD_BEHAVIOR_REVIEW_RESULT_REUSABLE=NO
OLD_COMPONENTIZATION_A0_EXACT_IDENTITY_CURRENT=NO
OLD_BREAKPOINT_PREFLIGHT_EXACT_IDENTITY_CURRENT=NO
```

The older records remain historically valid evidence. This normalization freeze does not create or refresh any downstream authority:

```text
NEW_BEHAVIOR_BINDING_CREATED=NO
NEW_BEHAVIOR_CONTRACT_CREATED=NO
NEW_BEHAVIOR_REVIEW_CREATED=NO
COMPONENTIZATION_A0_REFRESH_STARTED=NO
BREAKPOINT_EVIDENCE_RECOVERY_STARTED=NO
BREAKPOINT_AUTHORITY_CREATED=NO
DESIGN_DOCUMENT_RESOLVED=NO
A1_SEMANTIC_INPUT_FROZEN=NO
P7_D0_STARTED=NO
COMPONENT_PROPOSER_STARTED=NO
```

## Performance and lifecycle

```text
DATA_LAYER=COLD_COMPILE_REVIEW_TIME
ETS=N/A
CACHEX=N/A
REDIS=N/A
POSTGRES=N/A
PGBouncer=N/A
READ_REPLICA=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
```

```text
LIFECYCLE=unstarted
  → source_identity_verified
  → current_main_replayed
  → canonical_identity_derived
  → structural_invariants_verified
  → PR213_delta_classified
  → normalization_record_review_ready
```

The terminal state for this slice is `NORMALIZATION_RECORD_REVIEW_READY`. Behavior reissue requires separate review and acceptance of this identity record.
