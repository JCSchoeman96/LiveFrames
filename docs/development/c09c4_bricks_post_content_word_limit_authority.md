# C09C4 Bricks post-content word-limit mapping authority

## 1. Status and scope

This authority closes one Bricks source mapping for fresh Design IR 4.0.0
normalization. It supplements `docs/development/c09b2_design_ir_4_value_modifier_authority.md`
and amends the `OPAQUE_POST_CONTENT_MODIFIER_POLICY` in
`docs/development/c09c2_bricks_binding_mapping_authority.md` for future fresh
normalization after a separate implementation is accepted. It does not
change the IR4 ValueModifier schema, reinterpret historical IR3 documents,
or authorize production implementation.

The C09C3 Bricks binding implementation already exists and was accepted in PR
#115. It recognizes the exact literal `{post_content:16}` as opaque. This
authority replaces that literal-only source decision for future implementation
and fresh normalization. The normalizer remains unchanged until a separate
implementation slice follows acceptance of this authority.

```text
AUTHORITY=C09C4
SOURCE_MAPPING_VERDICT=SUPPORTED
SOURCE_MAPPING_FORM={post_content:<positive integer>}
COUNT_DOMAIN=ASCII_DECIMAL_INTEGER_1_OR_GREATER
IMPLEMENTATION_AUTHORIZED=NO
```

## 2. Evidence classes

### SOURCE_EVIDENCE

The accepted Feature Milan source artifact is:

```text
PRIVATE_ARTIFACT=private_reference/frames/staging-2026-09/feature-section-milan/bricks-component-ybsqrl-feature-section-milan.json
PRIVATE_ARTIFACT_SHA256=f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132
ELEMENT_ID=b41076
ELEMENT_TYPE=text-basic
SOURCE_PATH=settings.text
SOURCE_EXPRESSION={post_content:16}
```

The JSON was inspected as data. Its embedded source code was not executed.
This occurrence proves the exact field, modifier-bearing form, and count 16
used by Feature Milan. On its own it would support only the literal example.

The accepted Bricks 2.3.1 repository fixture is
`fixtures/bricks/bricks_components.json`, SHA-256
`bb584f35b160f5095dc67fc367884f51cff35b59693c84374426f5cecf56a1a1`. It
contains `{post_content:60}` and `{post_excerpt:20}`. The `post_content:60`
occurrence independently establishes that the field uses a numeric suffix
other than Milan's literal `16` in the accepted fixture family.

### EXTERNAL/ACCEPTED_DOCUMENTATION_EVIDENCE

The accepted C09B2 authority cites the official Bricks Academy Dynamic Data
documentation at
<https://academy.bricksbuilder.io/builder/dynamic-content/dynamic-data/>.
The documentation identifies `{post_content}` as post content, gives
`{post_excerpt:55}` as a word-limit example, states that a colon followed by a
number limits output to that many words, and describes `:*numeric value*` on a
text field as trimming content to the specified number of words. The page was
consulted on 2026-10-13. This is current documentation, not direct inspection
of Bricks 2.3.1 implementation code. C09B2 records the cross-version
continuity limit and does not rely on source runtime code.

The source fixture supplies the field-specific `{post_content:60}` example;
the accepted documentation supplies the numeric-filter word-count meaning.
Together they support the closed numeric form for `post_content`, beyond
Milan's literal `16`. They do not support other suffix types or modifier
semantics.

### LIVEFRAMES_AUTHORITY

`docs/03_DESIGN_IR_SPEC.md` and C09B2 define the source-neutral resolved
modifier as:

```elixir
%LiveFrames.IR.ValueModifier.Resolved{
  kind: :word_limit,
  arguments: %{"count" => positive_integer}
}
```

IR4 permits this modifier only on `target_kind: :text`, `value_kind: :field`,
`scope: :collection_item` or `:site`, and
`normalization_status: :normalized`. C09B/C09C2 establish `post_content` as
`content.body`, require dynamic text to stay out of `DesignNode.content`, and
preserve the exact source expression and inference in `SourceTrace`. For
Feature Milan, C09C2 establishes the `collection_item` scope and admitted
collection reference.

The caller applies the word limit before supplying the value. LiveFrames does
not tokenize, transform, or truncate the value at runtime.

### ENGINEERING_DECISION

The source adapter may recognize only the complete text expression matching
`{post_content:<count>}`, where `<count>` is one or more ASCII decimal digits,
the first digit is `1` through `9`, and the remaining digits are `0` through
`9`. This is the positive-integer decimal form. The implementation must parse
the count as an integer and must reject a value it cannot represent safely.
This authority sets no maximum count.

The resolved ValueBinding uses the already-proven text target, field value
kind, source-authorized scope, and `content.body` key. The raw expression
remains provenance in SourceTrace. No source text is emitted as static
`DesignNode.content`.

Do not generalize this rule to another field or to `{field:value}` forms. Do
not accept signs, zero, leading zeroes, decimals, whitespace, extra suffixes,
multiple modifiers, arbitrary expressions, or dynamic syntax beyond this
complete form. In particular, do not infer `:format`, HTML behavior,
tokenization details, or punctuation and ellipsis rules.

Unknown, malformed, or unsupported modifier forms must never become an
unmodified `content.body` binding. When the existing closed classifier can
prove the typed target and base key but not the modifier, it may retain the
binding as `modifier: opaque` with
`normalization_status: :evidence_insufficient`, as C09B/C09C2 require.
Otherwise it follows the accepted unsupported-expression path, emits no
ValueBinding, clears generic content, retains SourceTrace, and diagnoses the
unsupported expression. It must not parse an arbitrary modifier language.

## 3. Normalized result

For an admitted source occurrence of `{post_content:<count>}`, emit the
following source-neutral semantics:

```text
target_kind=text
value_kind=field
scope=collection_item or site, only where the existing source authority admits that scope
normalization_status=normalized
value_key=content.body
modifier.status=resolved
modifier.kind=word_limit
modifier.arguments.count=<positive integer>
```

The original Bricks expression, exact source path, adapter/version, and
classification inference remain in SourceTrace. A resolved modifier does not
make LiveFrames the execution owner.

## 4. Identity and historical artifact boundary

```text
HISTORICAL_IR3_MILAN_MUTATED=NO
HISTORICAL_IR3_BEHAVIOR_CONTRACT_REUSED_FOR_IR4=NO
HISTORICAL_IR3_REVIEW_REUSED_FOR_IR4=NO

IR4_FRESH_NORMALIZATION_REQUIRED=YES
IR4_NEW_DESIGN_DOCUMENT_IDENTITY_REQUIRED=YES
IR4_NEW_BEHAVIOR_BINDING_IDS_EXPECTED=YES
IR4_NEW_BEHAVIOR_CONTRACT_DIGEST_REQUIRED=YES
IR4_NEW_BEHAVIOR_REVIEW_RESULT_REQUIRED=YES
```

The exact IR4 identity and dependent IDs or digests must be produced by the
later normalization and reissue execution. This authority does not predict or
freeze those values. Historical IR3 source, DesignDocument, BehaviorContract,
BehaviorReviewResult, bytes, IDs, and digests remain unchanged.

## 5. Downstream gate

The required order is:

```text
accepted source mapping authority
→ implementation of the narrow Bricks mapping
→ fresh Feature Milan IR4 normalization
→ exact new DesignDocument identity
→ new BehaviorContract against that identity
→ new immutable BehaviorReviewResult
→ real Milan P7-D0
→ existing ComponentizationProposer
→ existing ComponentReview
→ P7-D1 BehaviorProjection
→ P7-E
→ Milan runtime
```

This authority does not begin any later step. P7-D1 must not start until the
exact approved ComponentContract and matching ComponentizationPlan tuple
exists after ComponentReview.

## 6. Performance and scaling classification

This rule applies during cold compile, normalization, and review only.

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
TTL=N/A
DB_INDEX=N/A
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
```

## 7. Explicit exclusions

This authority does not authorize or add:

- an arbitrary modifier parser, expression language, or `{field:value}`
  classifier;
- arbitrary suffix handling or another Bricks field mapping;
- Bricks or WordPress runtime access, source runtime copies, or proprietary
  code;
- runtime word limiting or string truncation;
- componentization input, a ComponentContract, a ComponentizationPlan,
  ComponentizationProposer execution, or ComponentReview;
- Milan IR4 normalization, identity regeneration, BehaviorContract or review
  reissuance, P7-D0, P7-D1, P7-E, or runtime implementation.

```text
RUNTIME_MODIFIER_EXECUTION=NO
MILAN_IR4_RENORMALIZED=NO
MILAN_BEHAVIOR_REISSUED=NO
REAL_MILAN_D0_EXECUTED=NO
P7_D1_STARTED=NO
RUNTIME_STARTED=NO
```
