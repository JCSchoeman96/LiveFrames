# C09D3 Later Amendment: Generic Subtree-Slot Carrier

**Status:** proposed authority; pending independent review, merge, and green post-merge CI

```text
AUTHORITY_KIND=LATER_C09D3_AMENDMENT
MOTIVATING_TRACER=FEATURE_MILAN
SOURCE_SPECIFIC_RULE=NO

BASE_SHA=c1215401dde5b665e3c565757dc3c5925296e3ec
BASE_TREE=1b8e2ef6d6f6a19604f6b473c7ec6522f525995c
BASE_CI_RUN=40912713281
BASE_CI_RESULT=success

CURRENT_SUBTREE_SLOT_CARRIERS=actions;button;link;rich_text
AUTHORIZED_SUBTREE_SLOT_CARRIERS=actions;button;link;rich_text;generic
OTHER_STRUCTURAL_TYPES_WIDENED=NO

SUBTREE_OWNERSHIP_RULE_CHANGED=NO
BINDING_DESCENDANT_POLICY_CHANGED=NO
RENDER_PROJECTION_ENUM_CHANGE=NO
COMPONENTIZATION_PLAN_FORMAT_CHANGE=NO
COMPONENT_CONTRACT_FORMAT_CHANGE=NO
DESIGN_IR_VERSION_CHANGE=NO

MILAN_PUBLIC_API_CHANGE_REQUIRED=NO
MILAN_SEMANTIC_INPUT_CHANGE_REQUIRED=NO
```

This document amends the accepted C09D3 `ComponentizationPlan` and render
projection authority with one source-neutral carrier capability. It does not
rewrite historical C09D3 records or imply that `generic` was previously an
authorized `subtree_slot` target. The existing authority remains in force except
for the explicit `generic` addition below.

## 1. Motivating residual

The accepted Feature Milan Phase 7A semantic input places the public slot
`intro` on a Design IR node with semantic type `generic`:

```text
MILAN_TARGET_NODE=node_000001_000001_000001_000001
MILAN_TARGET_SEMANTIC_TYPE=generic
MILAN_PUBLIC_SLOT=intro
MILAN_RENDER_ROLE=subtree_slot
```

The target contains the static `heading` and `rich_text` intro leaves. The
owner-approved slot makes the caller responsible for the intro markup and
content. The Phase 7A candidate was constructed, but Behavior-aware reference
validation returned `componentization_plan.render_projection.role_node_mismatch`
and `componentization_plan.render_projection.role_conflict` for this placement.
Those are two manifestations of one generic capability gap: `generic` is not a
current `subtree_slot` carrier. Static-item review did not fire; all six
collection ItemFields were covered by ordinary projections or valid
consumer-supplied accessibility companions.

This is source-neutral evidence for one additional semantic carrier. The Milan
node ID above is motivating evidence only and must not become a production
branch or matching condition.

## 2. Existing compatibility and the one addition

The currently accepted closed role/node matrix is:

```text
text_content  -> heading | paragraph | rich_text
asset_src     -> image
asset_alt     -> image
link_url      -> link
heading_level -> heading
subtree_slot  -> actions | button | link | rich_text
```

The current implementation matches this matrix. This amendment adds exactly
one carrier to `subtree_slot`:

```text
subtree_slot -> actions | button | link | rich_text | generic
```

No other render-role/node compatibility changes are authorized.

## 3. Generic subtree-slot carrier rule

```text
GENERIC_SUBTREE_SLOT_CARRIER_RULE =

DesignNode.semantic_type == "generic"

AND

exactly one RenderProjection targets that generic node, with:
  render_role = subtree_slot
  public target = an existing approved public Slot
  slot cardinality = "0..1"

AND

all existing boundary, public-placement, subtree-ownership,
binding-descendant, collection-descendant, duplicate, and conflict
validations pass

=> valid generic subtree_slot carrier
```

The plan still has one placement for that public slot under the existing
public-target placement rules. A generic node cannot be the component boundary
root when replacing it would remove the component root. Existing boundary and
slot-ownership validation continues to decide that case.

This rule authorizes the semantic type `generic`, not every node that happens to
render as a `div`. Semantic compatibility follows `DesignNode.semantic_type`,
not native tag equality.

## 4. Closed scope

This amendment does not authorize `subtree_slot` on:

```text
section
container
wrapper
stack
grid
background
overlay
heading
paragraph
image
raw
unsupported
unknown
```

Those semantic types retain their current behavior and require separate
authority before any future extension. In particular:

```text
GENERIC != ALL_STRUCTURAL_TYPES
```

The fact that several semantic types can realize as a `div` does not make their
Design IR meanings interchangeable.

## 5. Existing subtree ownership is unchanged

The existing `SUBTREE_SLOT_OWNERSHIP_RULE` applies to a generic target without
relaxation. The slot replaces the target DesignNode and its descendants with
consumer-owned markup. The target's parent remains part of generated internal
structure. The replaced target and descendants are not independently emitted
from Design IR.

All existing isolation checks remain required:

```text
no BindingProjection may target the slot target or a descendant

no other RenderProjection may target the slot target or a descendant

no ValueBinding target may occur inside the replaced subtree

no CollectionBinding owner may occur inside the replaced subtree

no CollectionBinding repeat root may occur inside the replaced subtree
```

Existing duplicate-placement, boundary, and subtree-conflict checks also remain
in force. Violations continue to fail reference validation, including with
`componentization_plan.slot.subtree_conflict` for binding or collection
ownership conflicts.

## 6. Consumer ownership and presentation

```text
GENERIC_SUBTREE_SLOT_PRESENTATION_OWNERSHIP=CONSUMER
```

When a generic target is replaced, its source wrapper markup, static content,
and child markup are not independently rendered. The caller owns the slot
markup and content. Generation must not relocate source wrapper styles onto
caller markup and must not synthesize a generated wrapper merely to retain the
source structure. These constraints preserve existing `subtree_slot`
replacement semantics.

## 7. Co-location

Semantic role classification for a generic node changes from no allowed
semantic roles to:

```text
generic -> [subtree_slot]
```

A generic target may host at most one `subtree_slot` and no other render role.
Duplicate-role rejection remains active. These combinations remain invalid:

```text
generic + text_content
generic + heading_level
generic + asset_src
generic + asset_alt
generic + link_url
generic + root roles when the node is not the boundary root
generic + multiple subtree_slot projections
```

Unsupported co-location must continue to produce
`componentization_plan.render_projection.role_conflict`. A `container` or
`wrapper` target with `subtree_slot` remains incompatible and must continue to
produce `componentization_plan.render_projection.role_node_mismatch`.

## 8. Native realization

No new render role, serialized field, renderer architecture, or Milan-specific
renderer branch is required:

```text
NEW_RENDER_PROJECTION_ROLE_REQUIRED=NO
NEW_SERIALIZED_FIELD_REQUIRED=NO
RENDERER_SPECIAL_CASE_FOR_MILAN=NO
NO_ADDITIONAL_TREE_TRAVERSAL_REQUIRED=YES
```

The existing renderer indexes `subtree_slot` projections by target node and
returns the slot invocation before ordinary target-node rendering. The
`generic` semantic type already has the accepted default native tag `div`. The
slot replaces the generic node before its ordinary native realization, so this
amendment introduces no new generic tag semantics.

The rich-text-specific native-generation bypass is unchanged:

```text
RICH_TEXT_SUBTREE_SLOT_NATIVE_BYPASS=UNCHANGED
```

A generic node has an accepted default native tag and needs no rich-text
unresolved-tag bypass. If later implementation evidence shows a separate
generic bypass is necessary, stop with
`STOP=GENERIC_SLOT_NATIVE_AUTHORITY_INCOMPLETE`; do not widen the rich-text
bypass under this authority.

## 9. Required implementation and regression evidence

This document authorizes a later implementation task, not implementation in
this authority change. The primary expected implementation surfaces are:

```text
apps/live_frames/lib/live_frames/componentization_plan/reference_validation.ex
apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs
```

The two mechanically coupled changes are both required:

```elixir
:subtree_slot -> node.semantic_type in ["actions", "button", "link", "rich_text", "generic"]
```

and:

```elixir
semantic_allowed_roles(%DesignNode{semantic_type: "generic"}) -> [:subtree_slot]
```

The implementation must not make just one change; otherwise one of the two
Milan diagnostics remains. The implementation tests must prove:

```text
generic + one subtree_slot
  => valid

generic + duplicate subtree_slot
  => role_conflict

generic + unsupported second role
  => role_conflict

generic subtree_slot + descendant ValueBinding
  => componentization_plan.slot.subtree_conflict

generic subtree_slot + descendant CollectionBinding
  => componentization_plan.slot.subtree_conflict

container + subtree_slot
  => role_node_mismatch

wrapper + subtree_slot
  => role_node_mismatch
```

An end-to-end native-generation regression should also prove, where the existing
test infrastructure can do so without unrelated authority, that the generic
source subtree is omitted and the slot invocation replaces it.

## 10. Format, security, and source-neutral boundaries

This is a compatibility-matrix extension only:

```text
DESIGN_IR_VERSION_CHANGE=NO
COMPONENT_CONTRACT_FORMAT_CHANGE=NO
COMPONENTIZATION_PLAN_FORMAT_CHANGE=NO
RENDER_PROJECTION_ENUM_CHANGE=NO
SEMANTIC_INPUT_SHAPE_CHANGE=NO
NATIVE_GENERATOR_PUBLIC_API_CHANGE=NO
```

The implementation must remain source-neutral:

```text
SOURCE_SPECIFIC_BRANCH=NO
MILAN_NODE_ID_IN_PRODUCTION_CODE=NO
SOURCE_JS_EXECUTION=NO
SOURCE_PHP_EXECUTION=NO
RAW_HTML_AUTHORIZATION=NO
ARBITRARY_DYNAMIC_MARKUP_AUTHORIZATION=NO
```

The public `Slot` remains the only consumer-owned markup boundary. Existing
slot cardinality and subtree isolation rules remain the safety boundary.

## 11. Milan lifecycle and Article Juliet isolation

This capability does not change Milan's accepted SemanticInput or public API:

```text
MILAN_SEMANTIC_INPUT_CHANGE_REQUIRED=NO
MILAN_PUBLIC_API_CHANGE_REQUIRED=NO
MILAN_PHASE_7A_CURRENT_STATUS=BLOCKED_ON_GENERIC_SUBTREE_SLOT_CAPABILITY
MILAN_PHASE_7A_RETRY_AUTHORIZED=NO_PENDING_AUTHORITY_AND_IMPLEMENTATION
```

Only after this authority is reviewed, merged, and post-merge CI is green, and
the implementation is separately reviewed, merged, and post-merge CI is green,
is the same frozen-input Phase 7A retry authorized. This document does not
authorize Phase 7B, ComponentReview, or Phase 8.

Article Juliet P4B remains deferred while this shared capability is unresolved.
This change does not authorize changes to:

```text
EvidenceHandlingDecision
caller_supplied_destination_value
datetime_attribute
dynamic heading link realization
```

```text
ARTICLE_JULIET_P4B_STATUS=DEFERRED
```
