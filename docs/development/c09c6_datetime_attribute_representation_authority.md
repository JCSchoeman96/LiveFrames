# C09C6 datetime attribute representation authority

## Status and scope

```text
AUTHORITY=C09C6
DESIGN_IR_TARGET_VERSION=6.0.0
REPRESENTATION_VERDICT=AUTHORIZED
IMPLEMENTATION_AUTHORIZED=NO
DESIGN_IR_6_IMPLEMENTATION_AUTHORIZED=NO
BRICKS_NORMALIZATION_IMPLEMENTATION_AUTHORIZED=NO
P4_DYNAMIC_HEADING_LINK_REALIZATION_AUTHORIZED=NO
P4_DATETIME_NATIVE_REALIZATION_AUTHORIZED=NO
FLUID11B_IMPLEMENTATION_AUTHORIZED=NO
FLUID12_AUTHORIZED=NO
```

This is representation authority only. The implemented specification remains Design IR 5.0.0 until separately authorized implementation is accepted. C09C6 owns the Design IR 6 representation, datetime target semantics, validation and migration rules, and identity implications. It does not own Bricks classifier implementation or diagnostic reconciliation, component contracts or componentization projection, HEEx realization, date formatting execution, heading dynamic-link realization, style normalization, or Fluid.

## Context and evidence

The ultimate tracer goal is real Article Juliet Bricks and ACSS source → source semantics → source-independent Design IR → componentization/native representation → generated package CSS → rendered native component → FLUID-11 real tracer accepted. The remaining formatted-date path is C09C5 source meaning → C09C6 representation authority → later IR 6 implementation → later exact Bricks normalization → later componentization/native realization → Article Juliet tracer rerun. These are separate stages.

The accepted Article Juliet source occurrence in `sources/bricks_components.json` is:

```text
SOURCE_ID=cfc2f2
SOURCE_ELEMENT=text-basic
settings.tag=custom
settings.customTag=time
settings.text={post_date}
settings._attributes=[
  {"id": "opmerk", "name": "datetime", "value": "{post_date:Y-m-d h:m}"}
]
```

C09C5 establishes the base semantic as published date, source-neutral key `content.published_at`, filter class `date_format`, exact format literal `Y-m-d h:m`, target intent datetime attribute, and scope `collection_item`. The literal is evidence and must not be corrected or reinterpreted. This authority does not re-prove the source expression or infer semantics from other occurrences.

## Version and destination

Design IR 5.0.0 supports only `text`, `asset`, `link_url`, and `rich_text` as `ValueBinding.target_kind`. A new required enum meaning changes the contract and serialized validation semantics. An in-place 5.0.0 extension is rejected; the target version is 6.0.0, not a backward-compatible minor change.

The one new canonical target kind is `datetime_attribute`. It means a caller-supplied value intended for the semantic HTML `datetime` attribute of a later-proven temporal carrier. It is not a generic or arbitrary HTML attribute, text content, date object, timestamp type, timezone contract, formatting engine, or source expression. `attribute`, `dynamic_attribute`, `html_attribute`, `date`, `datetime`, `post_date`, and `bricks_datetime` are not canonical target kinds.

The target kind denotes a fixed destination. Do not add `attribute_name`, `target_attribute`, `html_attribute`, or `dom_attribute` to `ValueBinding`. This does not authorize bindings for `onclick`, `onload`, `style`, `class`, `href`, `src`, `srcdoc`, `data-*`, `aria-*`, `role`, or `tabindex`.

Core IR records that a dynamic datetime-attribute value is intended for a node. It does not choose HEEx syntax, decide whether the node becomes `<time>`, specify Phoenix attribute rendering, or decide whether a semantic type is native-compatible. No new `DesignNode` semantic type, including `time`, is authorized. Core validation must not infer Bricks `customTag=time`. Native carrier compatibility belongs to later componentization/native authority.

## First-wave binding and validation

For `datetime_attribute`, the first-wave valid combination requires `value_kind=field`, `scope=collection_item`, a non-empty source-independent semantic `value_key`, and a required admitted `collection_binding_id`. The target node must resolve and lie within the referenced repeat subtree. `site`, `current_entity`, `collection`, and `collection_count` are not authorized for this target. Future evidence may expand the contract through separate authority.

For Article Juliet, the binding has `value_key=content.published_at` and references the nearest admitted Article Juliet collection. Its modifier is `{"status":"opaque"}` and its normalization status is `evidence_insufficient`.

Future IR 6 core validation must support the new enum and enforce all the requirements above. Existing modifier invariants remain: opaque requires `evidence_insufficient`; resolved requires `normalized`. The existing resolved `word_limit` remains valid only for its already-authorized text combinations and is forbidden for `datetime_attribute`. C09C6 adds no target-node semantic-type restriction; carrier compatibility is deferred.

Serialization adds only the new enum value to the existing ValueBinding shape. This conceptual excerpt omits the existing binding and target IDs, which remain required:

```json
{
  "target_kind": "datetime_attribute",
  "value_kind": "field",
  "scope": "collection_item",
  "value_key": "content.published_at",
  "collection_binding_id": "<id>",
  "modifier": {"status": "opaque"},
  "normalization_status": "evidence_insufficient"
}
```

## Modifier and provenance

C09C5 proves a `date_format` filter is present, but does not establish transferable canonical date-format semantics. Existing `ValueModifier.Opaque` means a modifier is present without established canonical transferable semantics. Do not add `Resolved(kind=:date_format)`, expand `ValueModifier.Resolved`, add arbitrary modifier arguments, or place `Y-m-d h:m` in canonical modifier arguments. Opaque is not implicit none.

SourceTrace metadata may retain the following source provenance for diagnostics and review:

```text
raw_expression={post_date:Y-m-d h:m}
filter_class=date_format
format_literal=Y-m-d h:m
attribute_name=datetime
```

These are source provenance, not canonical frontend semantic data or executable IR semantics. Neither the expression nor the literal may be parsed or executed at runtime. No PHP, WordPress, Bricks, Elixir, Unicode/CLDR, or JavaScript format grammar is inferred. Do not translate the literal or assign canonical month or minute meaning to `m`.

```text
DATE_VALUE_TYPE=UNSPECIFIED
TIMEZONE_SEMANTICS=UNSPECIFIED
FORMAT_GRAMMAR=UNSPECIFIED
FORMAT_EXECUTION_OWNER=UNRESOLVED_FOR_THIS_FILTER
LOCALE=UNSPECIFIED
CALENDAR_SYSTEM=UNSPECIFIED
OFFSET_POLICY=UNSPECIFIED
LIVEFRAMES_RUNTIME_MODIFIER_EXECUTION=FORBIDDEN
RAW_SOURCE_EXPRESSION_RUNTIME_PARSING=FORBIDDEN
AUTOMATIC_COMPONENTIZATION_APPROVAL=NO
AUTOMATIC_NATIVE_REALIZATION=NO
```

C09B2 retains caller ownership of resolved transformations. This opaque modifier does not establish enough information for automatic native consumption. An evidence-insufficient binding remains a blocking fidelity condition until later authority resolves how the required frontend value is supplied and represented.

## Migration and identity

The future 5.0.0 → 6.0.0 migration is structural only:

```text
source_version=5.0.0
target_version=6.0.0
kind=structural
frontend_semantics_recovered=false
```

It sets `ir_version` to `6.0.0`, preserves every existing represented node, registry record, field and value, preserves existing target kinds, modifiers, normalization states and source traces, and appends the normal migration provenance record. It never inspects source traces to infer semantics. It must not discover datetime attributes, parse Bricks expressions, convert unsupported diagnostics into bindings, create `content.published_at` bindings, or resolve opaque modifiers. Only fresh normalization under later source-adapter implementation authority may create a `datetime_attribute` binding.

The intended future routes are `1 → 2 → 3 → 4 → 5 → 6`, `2 → 3 → 4 → 5 → 6`, `3 → 4 → 5 → 6`, `4 → 5 → 6`, `5 → 6`, and `6 → 6` identity. Earlier migrations are not redesigned. Historical artifacts and approvals remain valid for their exact bytes and version.

IR version and migration provenance affect canonical serialized bytes. `V5_AND_V6_DOCUMENT_IDENTITY_EQUALITY=NOT_ASSUMED`. Fresh v6 normalization or migration requires recomputing the DesignDocument identity. Downstream exact-document identities and approvals must be recomputed or reissued under existing authority. Do not mutate historical review artifacts.

## Lifecycle and guards

```text
source_attribute_seen
→ datetime_attribute_identity_proven
→ content.published_at_semantic_proven
→ date_format_filter_presence_proven
→ transferable_format_semantics_unproven
→ datetime_attribute_binding_represented
→ modifier_opaque
→ evidence_insufficient
→ serialized_safely
```

Later adapter implementation must prove the recognized occurrence is a `datetime` destination before the first transition. The next transition requires separately accepted source-semantic authority such as C09C5. The next requires proven filter presence. Transferable semantics remain unproven because C09C5 proves the filter class, not a canonical transferable grammar. Representation at that point is allowed only with opaque modifier and evidence-insufficient status. Any missing proof fails closed.

Terminal states are `wrong_attribute`, `unknown_expression`, `missing_collection_context`, `conflicting_attribute_shape`, `source_format_semantics_unproven`, `generic_attribute_representation_required`, and `source_specific_core_representation_required`. No terminal path may silently become an unmodified date binding. The `source_format_semantics_unproven` terminal blocks automatic realization; the authorized opaque representation remains available when the preceding proofs hold.

## Security and performance

```text
ARBITRARY_ATTRIBUTE_NAMES=FORBIDDEN
EVENT_HANDLER_BINDINGS=FORBIDDEN
RAW_HTML_BINDING=FORBIDDEN
RAW_SOURCE_EXPRESSION_EXECUTION=FORBIDDEN
DYNAMIC_CODE_EVALUATION=FORBIDDEN
```

The new target must not open a generic HTML attribute injection path. No later native renderer may derive an arbitrary attribute name from caller data or SourceTrace.

```text
DATA_LAYER=COLD_COMPILE_REVIEW_TIME
VALIDATION=BOUNDED_ENUM_AND_REFERENCE_CHECKS
MIGRATION=O(document_size)
WHOLE_REGISTRY_REPEATED_SCAN=FORBIDDEN
RUNTIME_SOURCE_EXPRESSION_PARSING=NO
RUNTIME_DATE_FORMATTING=NOT_AUTHORIZED
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
ETS=N/A
CACHEX=N/A
REDIS=N/A
POSTGRES=N/A
PGBouncer=N/A
PUBSUB=N/A
GENSERVER=N/A
OBAN=N/A
TTL=N/A
DB_INDEX=N/A
```

Migration may stream or walk the document once. It must not require unnecessary duplicate materialization. This authority itself has no runtime side effects. Future IR 6 implementation affects version, validation, serialization, migration and document identity. It does not inherently affect Bricks interpretation, component contracts, componentization, HEEx generation, runtime date formatting, or Fluid; those require separate tasks.

## Rejected alternatives

- Reusing `text` conflates visible text with the semantic datetime attribute. Both destinations coexist on `cfc2f2`.
- A generic dynamic attribute creates arbitrary-attribute security and generalization exposure from one proven destination.
- Resolved `date_format` lacks an established transferable grammar, timezone semantics and execution contract.
- Putting `Y-m-d h:m` in canonical modifier arguments would promote source-specific syntax into source-independent IR.
- Keeping the formatted datetime diagnostic-only forever is unnecessary: C09C5 proves enough frontend meaning to represent the destination safely as evidence-insufficient IR.

## Informational sequence

These labels do not authorize implementation:

```text
P3A = Design IR 6.0.0 core implementation
P3B = exact Bricks datetime-attribute normalization
P4 = componentization/native realization authorities and implementation
P5 = remaining Article Juliet style/fidelity work
TRACER_RERUN
FLUID11B only if tracer prerequisites become proven
```
