# C09C7: Article Juliet dynamic native realization authority

```text
AUTHORITY=C09C7
PHASE=P4A
STATUS=AUTHORITY_FOR_REVIEW
P4_IMPLEMENTATION_AUTHORIZED=NO
```

## Scope and outcome

This authority amends the narrow downstream consumption boundaries in C09D5 and the native carrier rules in C09D6 and NAV-CARRIER. It does not authorize implementation. It preserves C09B, C09B2, C09C5, C09C6, C09D1 and C09D3 except for the specific downstream exception described here. Earlier documents remain historical authority for all other cases.

P4 succeeds only when accepted IR supports a caller collection item containing title text, a dynamic content URL, published-date visible text and a separate published-date datetime destination value, through an approved ComponentContract, validated ComponentizationPlan and NativeGenerator, to native heading/link and time/datetime markup. No source expression reaches NativeGenerator. No backend query or runtime Bricks or WordPress parser is created.

## Dynamic heading link

NAV-CARRIER selected an outer native heading and a renderer-owned internal anchor for static heading navigation. It explicitly left `HEADING_LINK_URL_BINDING_SUPPORTED=NO` and `DYNAMIC_HEADING_LINK_AUTHORIZED=NO`. This authority extends only that unresolved dynamic case.

A single heading DesignNode retains its identity and semantic type, a proven static `h1` through `h6` tag, a text ValueBinding and a `link_url` ValueBinding. The native output is conceptually:

```text
<hN ...heading-owned attributes and classes...>
  <a href={caller_supplied_link}>{caller_supplied_heading_text}</a>
</hN>
```

The renderer-created anchor has no DesignNode identity. No synthetic DesignNode, heading-to-link conversion or runtime click emulation is permitted.

The dynamic link is permitted only when all of these conditions hold:

- The node has `semantic_type=heading`, a proven static `h1` through `h6` native tag and `children=[]`.
- Exactly one normalized field ValueBinding with `target_kind=link_url` owns the destination.
- A normalized text ValueBinding or separately proven non-empty static text owns the heading text.
- No static navigation map competes for the destination, no dynamic heading-level projection exists and no subtree slot owns the heading contents.

Article Juliet uses dynamic text. These predicates are source-neutral. A collection-item URL remains an ordinary `BindingProjection` with `source_binding_kind=value` and `projection_kind=collection_item_field`, assigned to a `:string` item field. Its text binding independently projects to its own string item field. Title and URL are not collapsed into an object or map. No HeadingLinkProjection, DynamicNavigationProjection or NavigationBinding is introduced.

Heading styles and classes remain on the outer heading. The internal anchor owns the href and receives renderer-owned `color: inherit` and `text-decoration: inherit`. Focus suppression and a global anchor reset are forbidden. The caller must supply a string heading-text field and is responsible for an accessible name. Compile time cannot prove runtime text is non-empty; an empty value violates the consumer accessibility contract. No fallback text is silently added.

The URL inherits the existing caller-supplied `link_url` trust and safety contract and normal HEEx attribute escaping. This authority does not parse routes, create Phoenix navigate or patch intents, execute source navigation, copy source JavaScript, add StaticNavigation maps for dynamic values or change existing URL safety semantics. If a new URL trust model is needed, stop with `STOP=DYNAMIC_LINK_URL_SAFETY_MODEL_CHANGE_REQUIRED`.

## Opaque datetime destination

The accepted IR remains unchanged: `target_kind=datetime_attribute`, `value_kind=field`, `scope=collection_item`, `value_key=content.published_at`, `modifier=Opaque` and `normalization_status=evidence_insufficient`. Neither the status nor the modifier is rewritten.

### Caller-supplied opaque destination rule

`CALLER_SUPPLIED_OPAQUE_DESTINATION_RULE` passes only for a ValueBinding with exactly `target_kind=datetime_attribute`, `value_kind=field`, `scope=collection_item`, `modifier=Opaque` and `normalization_status=evidence_insufficient`, when all ordinary collection and reference invariants pass. No other evidence-insufficient target gains this rule.

The non-serialized `EvidenceHandlingDecision` gains exactly one outcome, `caller_supplied_destination_value`. The existing `omit_public_projection` outcome remains unchanged. The new outcome means that the consumer supplies the final destination-ready string; LiveFrames executes no source modifier and performs no transformation. It must pair one-to-one with a `BindingAssignmentDecision` for the exact same binding. It is invalid for normalized bindings, text, asset, link_url, rich_text, collection_count, site or current_entity scope, non-Opaque modifiers and every other evidence-insufficient binding class.

C09D5's prohibition on assigning an evidence-insufficient binding remains in force except when this rule passes, the evidence decision has the new outcome and the assignment targets that exact binding. The proposer may then construct the ordinary collection-item BindingProjection. There is no new projection kind, generic override flag or generic evidence waiver.

C09C7 amends the applicable C09D5 frozen first-wave evidence-handling rules only for `caller_supplied_destination_value`. It preserves `omit_public_projection` unchanged.

| Rule | `omit_public_projection` | `caller_supplied_destination_value` |
| --- | --- | --- |
| Requires `normalization_status=evidence_insufficient` | YES | YES |
| Requires `modifier=Opaque` | Existing C09D5 rules | YES |
| Scope limited to `collection_item` | Existing C09D5 rules | YES |
| Target limited to `datetime_attribute` | NO | YES |
| `BindingAssignmentDecision` allowed | NO | YES, exactly one |
| `BindingProjection` emitted | NO | YES, ordinary collection-item field |
| Public field required | NO from binding | YES |
| Field type | N/A | `:string` |
| Field required | N/A | `true` |
| Field default | N/A | `nil` |
| Contract provenance audit | YES | YES |
| Evidence-insufficient blocking diagnostic | YES | NO for exact valid tuple |
| Proposer may return `:proposed` | NO | NO |
| Proposer result when otherwise valid | `:needs_review` | `:needs_review` |
| Human approval required before generation | YES | YES |
| Generation after approval | NO ordinary projection | YES, only for exact persisted tuple |

The semantic-input decision record remains transient and non-serialized. As with existing C09D5 evidence handling, construction records an inert audit copy in the existing contract provenance map:

```elixir
provenance["evidence_handling"][source_binding_id] =
  %{"outcome" => "caller_supplied_destination_value"}
```

The audit is serialized provenance, not a new serialized schema field or enum. It requires no ComponentContract format bump.

The underlying binding retains `normalization_status=evidence_insufficient` and `modifier=Opaque`. Caller ownership makes the closed projection structurally admissible; it does not normalize the source evidence. Human semantic review remains mandatory. This narrowly amends C09D5 section 16.4: the exact authorized tuple with `caller_supplied_destination_value` returns `:needs_review`, never `:proposed`.

```text
CALLER_SUPPLIED_DESTINATION_PROPOSER_RESULT=needs_review
CALLER_SUPPLIED_DESTINATION_MAY_AUTO_PROPOSE=NO
PROPOSER_NEEDS_REVIEW -> HUMAN_REVIEW -> APPROVED | REJECTED
```

For the exact valid tuple, an intrinsically and reference-valid candidate pair must be available for human review. Do not emit `component_contract.binding_evidence_insufficient` or `componentization_plan.binding.evidence_insufficient` as blocking errors for that tuple. Do not emit `componentization_plan.binding.uncovered`, because the authorized ordinary BindingProjection covers the binding. These diagnostics remain required for every other evidence-insufficient case. The semantic review trigger, not an invalid candidate pair, requires `:needs_review`.

The visible date text and datetime destination share `content.published_at` but have different transformation semantics. They must use distinct collection item fields. For illustration only, names could be `published_at_text` and `published_at_datetime`; explicit semantic componentization decisions select the actual names later. Names must not be mechanically derived from `value_key`. The datetime field has `type=:string`, `required=true` and `default=nil`, and its purpose states that the caller supplies the final destination value, not a DateTime for LiveFrames to format. Public inputs do not accept format strings, timezone or locale options, formatter functions, Bricks expressions, raw HTML attributes or attribute maps.

The carrier must have normalized native tag `time`. Preserve the current DesignNode semantic type. Do not add `semantic_type=time` or change Design IR. Native validation must admit the proven `time` tag for this closed binding-backed case while retaining the existing semantic type; if it cannot safely do so, stop with `STOP=NEW_DESIGN_NODE_SEMANTIC_TYPE_REQUIRED`. The compiler owns the fixed attribute name `datetime`; the caller supplies only its value. Conceptually:

```text
<time datetime={caller_supplied_datetime_value}>
  caller_supplied_visible_date
</time>
```

This is conceptual structure, not literal implementation code. The datetime value is ordinary caller-owned string data escaped by HEEx. LiveFrames must not execute date formatting or parse a raw format literal at runtime. It must not interpret the source format as an HTML datetime grammar, translate it to ISO8601, correct its tokens, or infer timezone or local/UTC semantics. The caller may reproduce a source result outside LiveFrames and supply the final string. If source formatting inside LiveFrames is required, stop with `STOP=SOURCE_FORMAT_EXECUTION_REQUIRED`.

### Post-proposal validation

After human approval, generation and reference validation must check the persisted tuple, not depend on the transient semantic decision record:

```text
OPAQUE_DATETIME_PROJECTABLE =
  ValueBinding target=datetime_attribute + field + collection_item
  + Opaque + evidence_insufficient
  + ordinary valid collection reference
  + ordinary collection_item BindingProjection
  + assigned ItemField type=string, required=true, default=nil
  + distinct field from the visible text binding
  + target node normalized native tag=time
```

Only this exact tuple may pass the evidence-insufficient projection blocker after approval. All other evidence-insufficient bindings remain blocked. Other opaque bindings, target kinds and scopes gain no exception; the new outcome is invalid for normalized bindings and non-Opaque modifiers. Proposal validation still requires the explicit decision and exact assignment; persisted tuple validation does not claim to recover that transient decision.

The fixed destination is binding-backed. An internal native role `:datetime_attribute` derives from the IR ValueBinding target kind, analogous to binding-native `text_content`, `asset_src` and `link_url`. It is not added to serialized `ComponentizationPlan.RenderProjection.render_roles`. There is no unbound public datetime RenderProjection.

## Native generation and conflicts

The only newly authorized combinations are:

- Heading, text_content binding, link_url binding and static h1 through h6 tag: emit an outer heading and inner dynamic anchor. The separately proven static-text alternative follows the heading guards above.
- Proven time native tag, text_content binding and datetime_attribute binding: emit the fixed datetime attribute and dynamic text.

There is no generic dynamic-attribute loop, `Map.to_list(attrs)` pass-through or arbitrary attribute interpolation. Reject rather than select by precedence when a heading link has static navigation, children, a subtree slot, a dynamic heading-level projection or no proven heading tag. Reject a datetime binding with no time tag, on the wrong node, with a non-string item field, sharing the visible-text field, without the explicit caller destination decision at proposal time, or with another modifier or status. Ordinary binding, reference, slot and carrier invariants also remain in force.

## Lifecycles

```text
normalized_link_binding -> component_field_selected -> heading_carrier_compatible
-> public_projection_valid -> generation_prerequisites_valid -> internal_anchor_emitted

terminal: wrong_carrier, heading_tag_unproven, child_subtree_present,
          navigation_conflict, heading_level_conflict, projection_invalid

evidence_insufficient_datetime_binding -> caller_destination_ownership_explicit
-> distinct_public_field_selected -> fixed_time_carrier_proven
-> scoped_projection_exception_valid -> native_datetime_role_valid
-> fixed_attribute_emitted

terminal: caller_ownership_missing, generic_evidence_waiver_required,
          public_field_alias_conflict, wrong_native_carrier,
          format_execution_required, generic_attribute_required
```

## Format and architecture decisions

```text
DESIGN_IR_VERSION=6.0.0
DESIGN_IR_VERSION_BUMP_REQUIRED=NO
COMPONENT_CONTRACT_FORMAT=1.0.0
COMPONENT_CONTRACT_FORMAT_BUMP_REQUIRED=NO
COMPONENTIZATION_PLAN_FORMAT=1.0.0
COMPONENTIZATION_PLAN_FORMAT_BUMP_REQUIRED=NO
```

No serialized IR shape or meaning changes. No ComponentContract serialized field or enum changes, and no BindingProjection kind is added. No ComponentizationPlan serialized field or RenderProjection enum changes. The additional EvidenceHandlingDecision record is compile-time semantic input only; its inert audit effect may be serialized in the existing provenance map. Generation and reference validation admit only an exact existing tuple, not a generic schema change. If any serialized shape or enum must change, stop with `STOP=SERIALIZED_FORMAT_CHANGE_REQUIRED`; do not silently bump a version.

| Architecture question | Answer |
| --- | --- |
| NEW_DESIGN_IR_FIELD_REQUIRED? | NO |
| NEW_DESIGN_NODE_SEMANTIC_TYPE_REQUIRED? | NO |
| NEW_COMPONENT_CONTRACT_FIELD_REQUIRED? | NO |
| NEW_BINDING_PROJECTION_KIND_REQUIRED? | NO |
| NEW_RENDER_PROJECTION_ROLE_REQUIRED? | NO |
| NEW_PLAN_FORMAT_REQUIRED? | NO |
| NEW_CONTRACT_FORMAT_REQUIRED? | NO |
| GENERIC_EVIDENCE_WAIVER_REQUIRED? | NO |
| GENERIC_ATTRIBUTE_SYSTEM_REQUIRED? | NO |
| SOURCE_FORMAT_EXECUTION_REQUIRED? | NO |

If repository evidence proves any answer false, stop with `STOP=ARCHITECTURE_ASSUMPTION_INVALID` and report the evidence.

## Security and scaling

```text
ARBITRARY_DYNAMIC_ATTRIBUTES=FORBIDDEN
DYNAMIC_ATTRIBUTE_NAME_FROM_CALLER=FORBIDDEN
EVENT_HANDLER_BINDINGS=FORBIDDEN
RAW_HTML=FORBIDDEN
SOURCE_EXPRESSION_EXECUTION=FORBIDDEN
SOURCE_FORMAT_EXECUTION=FORBIDDEN
DYNAMIC_CODE_EVALUATION=FORBIDDEN

DATA_LAYER=COLD_COMPILE_AND_RENDER_TEMPLATE
COMPONENTIZATION=O(bindings + decisions + references)
ROLE_LOOKUP=O(1) indexed
NATIVE_RENDER=O(nodes + bindings)
REPEATED_FULL_BINDING_SCAN=FORBIDDEN
SOURCE_RUNTIME_PARSING=0
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

## Evidence and examples

The merged `bricks_frontend_binding_test.exs` Article Juliet proof identifies heading source `c5162b` as semantic type `heading`, with normalized title and URL bindings and no static navigation map. The checked source settings establish tag `h3` and no children. The adapter preserves that tag. Date source `cfc2f2` has no children, a normalized text binding for `content.published_at` and a distinct opaque evidence-insufficient datetime binding for the same key. Its source is `text-basic` with a proven custom `time` tag; the adapter maps this non-`p` case to semantic type `rich_text` and preserves `attributes["tag"]= "time"`. Current native tag validation allows `rich_text` tags `div`, `p` and `span`, so the scoped `time` carrier must be admitted later without changing the node semantic type.

The provenance literals `Y-m-d h:m`, `date_format` and `{post_date:Y-m-d h:m}` are evidence only. They must never reach generated runtime logic. Source IDs in this section are examples, not decision predicates.

## Implementation decomposition and stop conditions

```text
P4A = this docs-only authority
P4B = generic dynamic heading-link componentization/native implementation
P4C = scoped opaque datetime caller-value componentization/native implementation
P4D = real Article Juliet componentization and generated native artifact proof
P5 = remaining Article Juliet style/fidelity blockers
TRACER_RERUN
FLUID11B = only after the real tracer prerequisite passes
```

P4B, P4C, P4D, P5, FLUID11B and FLUID12 implementation are not authorized by this document. Stop if implementation starts during P4A. Stop on material main movement or unaccepted P3B; a required IR or semantic type change; a required contract field, projection kind or format change; a required RenderProjection role or plan format change; a generic evidence waiver or attribute system; a new dynamic URL safety model; source format execution, date grammar or raw source runtime parsing; a synthetic DesignNode or heading semantic loss; or a Fluid change. Use the corresponding `STOP` code in the P4A request. An open PR ends this slice for independent review, not merge.

```text
STOP=MAIN_MOVED_WITH_MATERIAL_CONFLICT
STOP=P3B_NOT_MERGED_ACCEPTED
STOP=DESIGN_IR_CHANGE_REQUIRED
STOP=NEW_DESIGN_NODE_SEMANTIC_TYPE_REQUIRED
STOP=COMPONENT_CONTRACT_FIELD_REQUIRED
STOP=NEW_BINDING_PROJECTION_KIND_REQUIRED
STOP=COMPONENT_CONTRACT_FORMAT_CHANGE_REQUIRED
STOP=NEW_RENDER_PROJECTION_ROLE_REQUIRED
STOP=COMPONENTIZATION_PLAN_FORMAT_CHANGE_REQUIRED
STOP=GENERIC_EVIDENCE_WAIVER_REQUIRED
STOP=GENERIC_ATTRIBUTE_SYSTEM_REQUIRED
STOP=DYNAMIC_LINK_URL_SAFETY_MODEL_CHANGE_REQUIRED
STOP=SOURCE_FORMAT_EXECUTION_REQUIRED
STOP=DATE_FORMAT_GRAMMAR_REQUIRED
STOP=RAW_SOURCE_RUNTIME_PARSING_REQUIRED
STOP=SYNTHETIC_DESIGN_NODE_REQUIRED
STOP=HEADING_SEMANTIC_LOSS_REQUIRED
STOP=FLUID_CHANGE_REQUIRED
STOP=IMPLEMENTATION_STARTED
STOP=PR_OPEN_FOR_REVIEW
```
