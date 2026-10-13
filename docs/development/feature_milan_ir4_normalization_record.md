# Feature Milan IR 4.0.0 normalization record

## Accepted base and inputs

```text
BASE_SHA=51d958e05627e7291b57d75f857cdf4332e37814
BASE_TREE=20c5f0851d7c7c615c3ec46a444a68077361dd01
BASE_CI_RUN=38435558502
BASE_CI_HEAD=51d958e05627e7291b57d75f857cdf4332e37814
BASE_CI_STATUS=completed
BASE_CI_RESULT=success

PRIVATE_MILAN_PATH=/home/jcschoeman96/projects/current/LiveFrame/private_reference/frames/staging-2026-09/feature-section-milan/bricks-component-ybsqrl-feature-section-milan.json
PRIVATE_MILAN_SHA256=f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132
PRIVATE_COMPONENT_ID=ybsqrl
PRIVATE_SOURCE_EXECUTED=NO
SOURCE_ELEMENT_b41076=settings.text:{post_content:16}

ACSS_SOURCE_PATH=/home/jcschoeman96/projects/current/LiveFrame/fixtures/automatic_css/acss_settings.json
ACSS_SOURCE_SHA256=19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05
ACSS_SOURCE_VERSION=4.0.1
ACSS_SOURCE_VERSION_STATUS=fixture_reference
ACSS_AUTHORITY_PROFILE=hero_foundation
ACSS_OPTIONS=source_version:"4.0.1", source_version_status:"fixture_reference", strict:true, profile::hero_foundation
ACSS_AUTHORITY_INPUT_PROVENANCE=/home/jcschoeman96/projects/current/LiveFrame/acss/acss.json
ACSS_AUTHORITY_INPUT_SHA256=ef6899b948413b58102244237d718efa77ed333f9903c40a605efe9e5c47d7a3
ACSS_4_0_1_RESEARCH_MANIFEST=/home/jcschoeman96/projects/current/LiveFrame/acss/4.0.1/RESEARCH_MANIFEST.yaml
ACSS_4_0_1_RESEARCH_MANIFEST_SHA256=f46b9343a51945bba0014b30d7d9a23fc2f09ca02ba370ff46444c947182d03e
ACSS_INPUT_ROLE=committed deterministic adapter fixture; the supplied export and research manifest establish its 4.0.1 reference provenance

NORMALIZATION_ROUTE=AutomaticCSS.from_file/2 → Bricks.to_ir/2 → IR.validate/1 → IR.encode!/1 → IR.Identity.from_document/1
COMPONENT_ID=ybsqrl
```

The private JSON was read as data. Its embedded JavaScript was not executed. The historical Milan record identifies the same committed ACSS fixture as its 4.0.1 token authority. The repository ACSS adapter flow supplies the options recorded above. No ACSS reference or private-source file was changed.

## Independent normalization runs

Each run started a separate `mix run --no-start` process. Each process loaded the private source through `Bricks.to_ir/2`, loaded the accepted token fixture through `AutomaticCSS.from_file/2`, validated the returned document, encoded it with `IR.encode!/1`, and derived its identity with `IR.Identity.from_document/1`. The canonical bytes were written outside the repository and compared with `cmp`.

```text
RUN_1_IR_VERSION=4.0.0
RUN_1_CANONICAL_BYTES_LENGTH=387432
RUN_1_CANONICAL_BYTES_SHA256=52544dcc0d279d91d3d56d054c9785b18f96e77a5520b782726b678c404db864
RUN_1_CANONICALIZATION_ID=lf-ir-serializer-v1
RUN_1_DIGEST_ALGORITHM=sha-256
RUN_1_DESIGN_DOCUMENT_DIGEST=52544dcc0d279d91d3d56d054c9785b18f96e77a5520b782726b678c404db864

RUN_2_IR_VERSION=4.0.0
RUN_2_CANONICAL_BYTES_LENGTH=387432
RUN_2_CANONICAL_BYTES_SHA256=52544dcc0d279d91d3d56d054c9785b18f96e77a5520b782726b678c404db864
RUN_2_CANONICALIZATION_ID=lf-ir-serializer-v1
RUN_2_DIGEST_ALGORITHM=sha-256
RUN_2_DESIGN_DOCUMENT_DIGEST=52544dcc0d279d91d3d56d054c9785b18f96e77a5520b782726b678c404db864

CANONICAL_BYTES_IDENTICAL=YES (byte-for-byte cmp)
IDENTITIES_IDENTICAL=YES
NEW_IR_VERSION=4.0.0
NEW_CANONICALIZATION_ID=lf-ir-serializer-v1
NEW_DIGEST_ALGORITHM=sha-256
NEW_DESIGN_DOCUMENT_DIGEST=52544dcc0d279d91d3d56d054c9785b18f96e77a5520b782726b678c404db864
CANONICAL_BYTES_TEMP_FILES_COMMITTED=NO
```

The document came directly from the current source normalizer. No serialized IR3 input or migration path was used.

## IR4 structure and frontend bindings

The five path-derived node IDs match the accepted historical Milan mapping:

| Source element | Current DesignNode | Purpose |
| --- | --- | --- |
| `ybsqrl` | `node_000001` | Behavior owner/root |
| `ebbb6e` | `node_000001_000001_000001_000002_000001` | Repeated feature-control collection |
| `b41076` | `node_000001_000001_000001_000002_000001_000002_000001` | Feature description |
| `b71f5d` | `node_000001_000001_000002_000001` | Separate desktop media collection |
| `05e604` | `node_000001_000001_000001_000002_000001_000002_000002` | Mobile media/query wrapper |

```text
QUERY_OWNER_COUNT=3
QUERY_OWNER_IDS=05e604, b71f5d, ebbb6e
COLLECTION_BINDING_COUNT=2
COLLECTION_BINDINGS=
  ebbb6e → cb_node_000001_000001_000001_000002_000001
  b71f5d → cb_node_000001_000001_000002_000001
05e604_COLLECTION_BINDING=NO
05e604_DIAGNOSTIC=bricks.collection.boundary_unproven
VALUE_BINDING_COUNT=4
```

The two admitted collection bindings remain separate and have no parent collection. `05e604` remains a query-like owner without an admitted `CollectionBinding`; its diagnostic remains. Descendant bindings under the nested wrapper continue to inherit the admitted `ebbb6e` collection where the current source mapping assigns them.

The current frontend bindings are:

| Source element | ValueBinding ID | Source value | Value key | Scope and owner | Status |
| --- | --- | --- | --- | --- | --- |
| `a34333` | `vb_node_000001_000001_000001_000002_000001_000001_text_000001` | `{post_title}` | `content.title` | `collection_item`, `ebbb6e` | `normalized` |
| `2a8181` | `vb_node_000001_000001_000001_000002_000001_000002_000002_000001_asset_000001` | `{featured_image}` | `media.primary` | `collection_item`, `ebbb6e` | `normalized` |
| `0ba4da` | `vb_node_000001_000001_000002_000001_000001_asset_000001` | `{featured_image}` | `media.primary` | `collection_item`, `b71f5d` | `normalized` |
| `b41076` | `vb_node_000001_000001_000001_000002_000001_000002_000001_text_000001` | `{post_content:16}` | `content.body` | `collection_item`, `ebbb6e` | `normalized` |

No additional normalized frontend binding appeared.

## C09C4 word-limit result

```text
B41076_VALUE_BINDING_ID=vb_node_000001_000001_000001_000002_000001_000002_000001_text_000001
B41076_TARGET_KIND=text
B41076_VALUE_KIND=field
B41076_SCOPE=collection_item
B41076_VALUE_KEY=content.body
B41076_COLLECTION_BINDING_ID=cb_node_000001_000001_000001_000002_000001
B41076_MODIFIER_KIND=word_limit
B41076_MODIFIER_ARGUMENTS={"count":16}
B41076_NORMALIZATION_STATUS=normalized
B41076_SOURCE_EXPRESSION={post_content:16}
B41076_SOURCE_PATH=components[0].elements[10].settings.text
B41076_SOURCE_TRACE_SOURCE_NAME=text
B41076_STATIC_DESIGN_NODE_CONTENT=nil
B41076_OLD_EVIDENCE_INSUFFICIENT_DIAGNOSTIC_PRESENT=NO
```

The value and exact source path remain in `SourceTrace`. `DesignNode.content` does not contain the dynamic expression. The caller applies the word limit before supplying the value; LiveFrames does not execute the modifier.

## Diagnostics and remaining evidence limits

The complete DesignDocument diagnostic set is warning-only:

```text
EXPECTED_SURVIVING_DIAGNOSTICS=
  bricks.attribute.unsupported=3
  bricks.breakpoint.unresolved=6
  bricks.collection.boundary_unproven=1
  bricks.element.unsupported=1
  bricks.runtime.unsupported=1
  bricks.setting.unsupported=9
  bricks.variable.unresolved=8
TOTAL_DIAGNOSTICS=29
ERROR_DIAGNOSTICS=0
FATAL_DIAGNOSTICS=0
RESOLVED_BY_C09C4=the b41076 bricks.binding.evidence_insufficient modifier diagnostic
NEW_DIAGNOSTICS=NONE
```

C09C4 resolves the source word-limit modifier only. This normalization does not establish durable cross-collection item identity, rendered cardinality equality, full Tabs semantics, a Milan-specific responsive breakpoint, timer cleanup on source lifecycle changes, listener cleanup, or browser accessibility behavior. These evidence statuses remain unchanged.

The ACSS adapter returned these token-source diagnostics, separate from the DesignDocument diagnostics above: `acss.setting.unknown=1` and `acss.value.unresolved=4`.

## Historical boundary, authorization, and performance

```text
HISTORICAL_IR3_IR_VERSION=3.0.0
HISTORICAL_IR3_DESIGN_DOCUMENT_DIGEST=b75c599cc0b8718f00897e8686d946db85c3c94014225b0612b892421ec9e114
HISTORICAL_BEHAVIOR_CONTRACT_DIGEST=3a5173b0c873bb502a7e949c3bdfa13eb97f97e8acf229c9c240c758856cd9cc
HISTORICAL_BEHAVIOR_REVIEW_ID=brv_ee78cac37236ffd7b50cc216e4e7d2c899f0d776972a2cf267edf705d17a3810
HISTORICAL_IR3_ARTIFACTS_CHANGED=NO
HISTORICAL_IR3_IDENTITY_REUSED=NO
HISTORICAL_BEHAVIOR_REUSED_FOR_IR4=NO
HISTORICAL_REVIEW_REUSED_FOR_IR4=NO

MILAN_IR4_RENORMALIZED=YES
MILAN_IR4_IDENTITY_FROZEN=YES
MILAN_BEHAVIOR_REISSUED=NO
MILAN_BEHAVIOR_REVIEW_ISSUED=NO
REAL_MILAN_D0_EXECUTED=NO
SEMANTIC_INPUT_CREATED=NO
COMPONENT_PROPOSER_EXECUTED=NO
COMPONENT_REVIEW_EXECUTED=NO
P7_D1_STARTED=NO
P7_E_STARTED=NO
RUNTIME_STARTED=NO

DATA_LAYER=COLD_COMPILE_REVIEW_TIME
HOT_DATA=N/A
WARM_DATA=N/A
REDIS=N/A
POSTGRES=N/A
PGBouncer=N/A
READ_REPLICA=N/A
ETS=N/A
CACHEX=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
TTL=N/A
DB_INDEX=N/A
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
```

The next slice is a separate reissue of the Feature Milan BehaviorContract against this exact IR4 DesignDocument identity. This record does not start that work.
