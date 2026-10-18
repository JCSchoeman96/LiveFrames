# NAV-CARRIER heading-link representation authority

This is a documentation-only architecture gate. It freezes a source-neutral
Design IR and native-rendering contract for a heading with a proven static
navigation destination. It does not change production code, tests, the
conversion matrix, or the canonical Romeo normalization.

## Base and accepted source requirement

```text
BASE_SHA=7d905f67575fab3aa22e3ed2e9eb53a75f2b2c53
BASE_TREE=67a185cc558a8eafc0248cbba061449847d52315
BASE_CI=39098261911 SUCCESS
PR_240_APPROVED_HEAD=b92c997e12c75a1b6db1f5813c6f2520470807e5
ROMEO_CANONICAL_GAP_DECOMPOSITION=ACCEPTED
CURRENT_MAIN=7d905f67575fab3aa22e3ed2e9eb53a75f2b2c53
CURRENT_MAIN_TREE=67a185cc558a8eafc0248cbba061449847d52315
CURRENT_MAIN_DESCENDS_FROM_BASE=YES

NAV_CARRIER_CANONICAL_COUNT=4
NAV_CARRIER_REQUIREMENT=CONFIRMED
NAVIGATION_DEPENDENCY_CLASS=INDEPENDENT
DESTINATION_SHAPE=STATIC_STRING
INTERACTION_RECORD_CONTAINS_NAVIGATION_EFFECT=NO
RUNTIME_NAVIGATION_REQUIRED=NO
```

The accepted source authority fixes these requirements. This review does not
reopen them and does not record destination strings. The source navigation
settings remain separate from pointer interaction records.

## Current generic contracts

`DesignNode` stores the semantic type separately from its attributes. A
heading uses `semantic_type = "heading"`. Bricks normalization stores a
proven native tag in `attributes["tag"]`; the supported heading tags are h1
through h6. The node ID comes from its Design IR traversal path. Source IDs
remain in `SourceTrace`.

`attributes` is already a JSON object, and the IR serializer already writes it
as one. The current IR validator checks JSON shape and semantic type. It does
not restrict the `navigation` attribute by semantic type or validate the
destination. `LiveFrames.StaticNavigation.validate_navigation_map/1` owns
destination validation before render or generation.

Bricks `StaticNavigation` currently accepts its proven `text-link` and button
carriers. It reports a heading with a link object as
`bricks.navigation.unsupported_carrier`. `DesignIRNormalizer` already keeps a
heading's semantic type and copies a navigation map onto the node when the
navigation normalizer returns one. Extending heading recognition does not
require a second normalization path.

Fidelity currently changes a static-navigation button or link root into an
anchor. It leaves headings on their heading path. Fidelity can preserve an
existing h1 through h6 tag in `attributes["tag"]`, but its generic missing-tag
fallback is h2. A navigable heading must carry a proven h1 through h6 tag or
fail closed. This lane does not authorize the fallback to choose a heading
level.

NativeGenerator renders headings as h1 through h6 when a compatible tag is
present, or through its existing heading-level projection. Its heading
generation prerequisite rejects child subtrees. Static navigation validation
and anchor emission currently apply only to `link` and `button`. This lane
uses a proven static tag and does not add heading-level bindings or projections
to Fidelity.

## Representation options

| Option | Preserves heading semantics | Preserves node identity | Requires synthetic DesignNode | Reuses navigation schema | Reuses URL safety | Renderer complexity | IR/schema impact | Style impact | Accessibility impact | Decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A. Heading node with navigation attribute and internal anchor | Yes | Yes | No | Yes | Yes | Medium. Both renderers add an internal native element and a bounded structural style rule. | None. Existing `heading`, attributes map, and navigation map remain. | Heading styles and classes stay on h1 through h6. Anchor gets navigation attributes and only the renderer-owned `color: inherit` and `text-decoration: inherit` neutralization. | Keeps native heading and link semantics; requires non-empty static text and no interactive descendants. | Selected |
| B. Heading with synthetic link child | Yes at the root | No. The child needs a new deterministic identity and source trace policy. | Yes | Yes | Yes | High. Both renderers, bindings, references, and styles must account for a new node. | Changes the IR tree and node count. | Requires ownership rules for heading styles, responsive styles, state styles, and link styles. | Can keep heading and link semantics, but adds content and interactive nesting ambiguity. | Reject |
| C. Convert the heading node to a link | No | No as a semantic node. The node ID may remain, but its heading meaning is lost. | No | Yes | Yes | Low | Changes the node's semantic meaning and tag resolution. | Existing heading styles would be applied to a link root. | Link remains, heading level and native heading semantics are lost. | Reject |
| D. Runtime click behavior or ARIA emulation | Not consistently | Usually yes | No | No | No | High. Requires event, keyboard, focus, and runtime rules. | Adds behavior-specific state and focus styling concerns. | An anchor with `role="heading"` overrides native link semantics; a heading click handler does not create native link behavior. | Reject |

Option B would add a node that has no source element. Reusing the heading's
source trace would duplicate source identity. Omitting it would lose trace
provenance. Moving content or bindings to that node would change ownership and
componentization references. Copying styles would create new ownership for
base, responsive, and state styles. The additional node would also change
deterministic traversal IDs, node counts, and source-tree fidelity. Current
native validation rejects heading child subtrees, so this option would need a
separate architecture decision.

## Rejected designs

This authority rejects:

- Changing the heading's semantic type to `link`.
- Adding a synthetic child DesignNode only to carry navigation.
- Replacing the native heading element with an anchor.
- Using `role="heading"` to replace h1 through h6.
- Adding `onclick`, JavaScript handlers, or runtime navigation behavior.
- Passing raw source anchor markup through the adapter or renderer.
- Emitting unsafe or dynamic destinations.
- Adding heading behavior that branches on source-specific IDs, classes, or values.

## Selected representation

```text
OPTION_A_VERDICT=SELECTED
OPTION_B_VERDICT=REJECTED
OPTION_C_VERDICT=REJECTED
OPTION_D_VERDICT=REJECTED
SELECTED_REPRESENTATION=HEADING_NODE_WITH_STATIC_NAVIGATION_ATTRIBUTE_AND_INTERNAL_NATIVE_ANCHOR
HEADING_SEMANTIC_TYPE_PRESERVED=YES
HEADING_NODE_ID_PRESERVED=YES
SYNTHETIC_DESIGN_NODE_CREATED=NO
```

The IR contains one node. Its semantic type stays `heading`, its source trace
stays on that node, and its validated static navigation map stays in
`attributes["navigation"]`.

```text
IR:
  one DesignNode
  semantic_type = "heading"
  attributes["tag"] = an already-proven h1 through h6 tag
  attributes["navigation"] = the existing validated static navigation map

Native structure:
  <hN ...heading attributes and classes...>
    <a ...validated navigation attributes...>heading text</a>
  </hN>
```

The anchor is a renderer-owned element. It has no DesignNode identity or
source trace. This representation states the generic native structure; it
does not claim an exact historical source DOM.

## Heading tag ownership

`attributes["tag"]` owns the normalized static heading tag. The chosen design
preserves each already-proven value, h1, h2, h3, h4, h5, or h6. A navigable
heading without one of these proven values fails closed. Navigation must not
choose h2, use a div, replace the heading with an anchor, or use
`role="heading"` in place of native heading markup.

```text
HEADING_TAG_PRESERVATION=Preserve the proven h1 through h6 tag in attributes["tag"]. Fail closed when absent or unsupported.
```

The existing public `heading_level` projection remains unchanged for other
generation cases. A navigable heading with a dynamic heading-level projection
is outside this lane because Fidelity receives only Design IR and cannot
produce the same dynamic heading branches. A later authority can define parity
if that capability is needed.

## Navigation map and URL safety

The heading uses the existing map in `attributes["navigation"]`. No
heading-specific schema is needed. The normalized map contains a required
`href` and may contain the existing bounded `target` value. The shared
validator reclassifies the destination and returns output attributes in the
order `href`, `target`, then `rel`. For `_blank`, it supplies
`rel="noopener noreferrer"`. Other target values do not create an emitted
target attribute.

The Bricks adapter must build this map only from the supported static link
object. It must not copy arbitrary source attributes into the map. The shared
validator remains the only destination-safety boundary. Unsafe schemes,
malformed destinations, and dynamic destinations remain rejected. Heading
navigation does not change escaping, target handling, blank protection, or
attribute ordering.

```text
EXISTING_NAVIGATION_MAP_REUSABLE=YES
NEW_NAVIGATION_SCHEMA_REQUIRED=NO
STATIC_NAVIGATION_VALIDATOR_REUSED=YES
URL_SAFETY_RULES_CHANGED=NO
```

## Static-only boundary and content shape

The lane covers only a validated static destination. It does not add dynamic
href bindings, query-derived links, runtime navigation state, Phoenix
navigation intents, JavaScript click handlers, source interaction actions,
history changes, or network actions. Dynamic heading destinations need a
separate authority.

The anchor needs an accessible name. The closed content rule is a non-empty
static UTF-8 string, with at least one non-whitespace character. The renderer
escapes it as text. `nil`, an empty string, or whitespace-only text fails
closed because it would create an unnamed link.

| Heading content shape | Supported |
| --- | --- |
| Non-empty static string | Yes |
| Empty or whitespace-only content | No |
| Structured object, list, or markup | No |
| Child DesignNodes | No |
| Slot or subtree-slot content | No |
| Dynamic text binding | No |
| Dynamic destination binding | No |

Current native generation supports text bindings for ordinary headings, but
that does not prove that a bound value will give a navigable heading a
non-empty accessible name. This lane keeps the content scalar and static.

```text
SUPPORTED_HEADING_CONTENT_SHAPES=NON_EMPTY_STATIC_UTF8_STRING
UNSUPPORTED_HEADING_CONTENT_POLICY=FAIL_CLOSED
NAVIGABLE_HEADING_CHILD_NODES_ALLOWED=NO
HEADING_LINK_URL_BINDING_SUPPORTED=NO
STATIC_ONLY=YES
DYNAMIC_HEADING_LINK_AUTHORIZED=NO
```

The child guard requires `children == []` before either renderer emits the
anchor. It excludes all child subtrees, including the current interactive
semantic types `button` and `link`. It also excludes `input`, `select`,
`textarea`, `summary`, and any other interactive child if LiveFrames represents
one in Design IR later. No arbitrary HTML analysis is part of the guard.

```text
NESTED_INTERACTIVE_GUARD=Require children == []; reject the whole child subtree, including button and link nodes, before rendering.
```

## Styling ownership and focus

All heading-owned presentation remains on the outer h1 through h6 element:

- Fidelity's deterministic class and accepted source-safe classes.
- NativeGenerator's package semantic class and private node-style class.
- Safe static heading attributes and any generated root attributes.
- Normalized base, responsive, and state styles.

Fidelity does not move source classes or styles to the anchor. NativeGenerator
does not move DesignNode styles or package classes to the anchor. The
navigation attributes belong only to the inner anchor. The anchor is a
renderer-created element, so it needs a small structural rule that prevents
browser link defaults from changing the heading's normalized presentation.
This rule describes LiveFrames' generated markup. It does not reconstruct
source CSS or claim what the historical source DOM contained.

```text
HEADING_STYLES_REMAIN_ON_HEADING=YES
ANCHOR_SOURCE_STYLE_SYNTHESIS=NO
ANCHOR_PRESENTATION_NEUTRALIZATION=REQUIRED
ANCHOR_NEUTRALIZATION_PROPERTIES=color: inherit; text-decoration: inherit
ANCHOR_NEUTRALIZATION_SCOPE=NAVIGABLE_HEADING_RENDERER_CREATED_DIRECT_CHILD_ONLY
ANCHOR_FOCUS_SUPPRESSION=NO
ANCHOR_STYLE_SOURCE=RENDERER_STRUCTURAL_CONTRACT
GLOBAL_ANCHOR_RESET_AUTHORIZED=NO
```

Apply exactly `color: inherit` and `text-decoration: inherit` to the
renderer-created direct-child anchor. These declarations prevent browser
default link color and underline from changing the heading presentation.
They also let a normalized heading color or text decoration pass through.
The anchor inherits ordinary typography from the heading through normal CSS
inheritance.

Do not add other declarations through this authority. In particular, do not
add display, position, width, height, padding, margin, font-size,
font-weight, line-height, background, border, transform, transition,
opacity, hover presentation, active presentation, or visited-specific source
styling. Do not copy source selectors or source link styles. Do not emit a
general `a` reset. The structural rule applies only to the renderer-created
anchor for a navigable heading. Fidelity may scope it with a deterministic
direct-child selector or another bounded renderer-owned marker; this
authority does not require a literal class name.

The neutralization does not suppress native focus. The anchor remains
keyboard focusable and keeps a visible focus indicator. Do not add
`outline: none`, `outline: 0`, `box-shadow: none`, or `tabindex="-1"` as
structural neutralization. Do not copy Romeo's source focus suppression.

The structural `color: inherit` rule applies to the anchor independently of
browser default link-state colors. Do not add source-derived `:link`,
`:visited`, `:hover`, or `:active` presentation rules. Any normalized
heading or heading-state presentation remains owned by the heading node.

```text
ANCHOR_KEYBOARD_FOCUSABLE=YES
VISIBLE_FOCUS_REQUIRED=YES
```

## Accessibility contract

The output retains native heading semantics on the h1 through h6 root and
native link semantics on the anchor. The static text supplies the anchor's
accessible name. Keyboard users can focus and activate the anchor through
native link behavior. The visible focus indicator remains required. The
childless content rule prevents nested interactive elements.

```text
NATIVE_HEADING_SEMANTICS_PRESERVED=YES
NATIVE_LINK_SEMANTICS_PRESERVED=YES
ARIA_SEMANTIC_SUBSTITUTION_REQUIRED=NO
```

## Design IR schema and version boundary

This capability reuses fields already present on `DesignNode`. It does not
change the serialized node shape, required fields, generic IR validation
rules, or serializer. The navigation map keeps its current meaning. The
generation prerequisite may add a closed representability check for the
heading-plus-navigation combination. That is a renderer capability gate, not
a new IR schema rule.

```text
DESIGN_IR_DATA_SHAPE_CHANGE_REQUIRED=NO
DESIGN_IR_VERSION_BUMP_REQUIRED=NO
IR_VALIDATION_CHANGE_REQUIRED=NO
IR_SERIALIZER_CHANGE_REQUIRED=NO
```

The Design IR version rule requires a new version when the IR data shape,
field meaning, generic validation rules, or serialized form changes. This
authority changes none of those. If a later implementation proposes a new IR
validation rule, it must stop and resolve the version decision before code.

## Bricks adapter acceptance rule

The future generic adapter may attach navigation metadata only when all of
these conditions hold:

1. The source element is a supported Bricks heading with a proven h1 through
   h6 tag.
2. Its link object matches an existing proven static navigation shape.
3. The destination is a string accepted by the existing static navigation
   validator.
4. No conflicting static link representation or runtime navigation meaning
   exists.
5. No dynamic-data expression, JavaScript behavior, or source interaction
   action supplies the destination or activation behavior.

On success, the adapter leaves the semantic type as `heading` and attaches the
existing navigation map. Unsupported, malformed, dynamic, or conflicting
input retains a diagnostic and no navigation map. A raw `tag = "a"` cannot
bypass this path. The rule applies to any supported Bricks heading with the
same evidence shape. It does not add source-specific IDs, names, classes,
filenames, or destination values.

## Fidelity contract

For a valid navigable heading, Fidelity retains the h1 through h6 element as
the DesignNode root and emits the validated anchor inside it:

```html
<hN class="...heading classes...">
  <a class="renderer-owned-structural-anchor" href="...">
    heading text
  </a>
</hN>
```

The class name is conceptual. Fidelity may use a deterministic direct-child
selector if it can scope the neutralization to this navigable heading. It must
give the inner anchor the effective declarations `color: inherit` and
`text-decoration: inherit`. It must not emit a global anchor reset, copy
source presentation to the anchor, or move heading presentation off the
heading root.

Navigation attributes stay off the heading. Fidelity reuses
`LiveFrames.StaticNavigation.validate_navigation_map/1` and emits no anchor
for an invalid map. It retains the heading root and reports the validation
diagnostic. It does not turn a heading into an anchor or add a second
DesignNode.

```text
FIDELITY_HEADING_ROOT_RETAINED=YES
FIDELITY_NAVIGATION_ANCHOR_INTERNAL=YES
FIDELITY_ANCHOR_PRESENTATION_NEUTRALIZED=YES
```

## NativeGenerator and componentization-plan contract

NativeGenerator emits the same static structure as Fidelity. Its heading
attributes, package classes, private style class, and normalized styles remain
on the h1 through h6 root. The inner anchor receives the validated navigation
attributes in the shared deterministic order. Its generated stylesheet gives
that anchor the same effective `color: inherit` and
`text-decoration: inherit` declarations, scoped to the renderer-created
direct-child anchor. The stylesheet must not add a global anchor reset, move
DesignNode presentation classes to the anchor, or copy source link styling.

```text
NATIVE_GENERATOR_ANCHOR_PRESENTATION_NEUTRALIZED=YES
FIDELITY_NATIVE_GENERATOR_STRUCTURE_MATCH=YES
FIDELITY_NATIVE_GENERATOR_PRESENTATION_CONTRACT_MATCH=YES
```

`ComponentizationPlan.ReferenceValidation` currently revalidates static
navigation only for `link` and `button`. The future generation prerequisite
must also validate the accepted navigable-heading shape before native
generation. It must reject missing or invalid navigation maps, missing or
unsupported tags, empty content, child subtrees, dynamic heading-level
projections, dynamic text bindings, slots, and any unsupported placement on
the anchor. It must preserve every unrelated generation prerequisite.

The existing binding contract does not authorize `render_role = :link_url`
on a heading. This lane does not add that role. A navigation map on a heading
becomes generation-representable only when the static shape above passes.

```text
HEADING_STATIC_NAVIGATION_GENERATION_REPRESENTABLE=YES
```

## Determinism and source neutrality

The existing traversal-derived node ID remains unchanged. No synthetic IDs,
source lookups, runtime destination lookups, or random values are added. For
the same source evidence, navigation map, and Design IR context, normalization
must produce the same DesignDocument and native generation must produce the
same markup and attributes.

The implementation is generic Bricks behavior. Romeo supplies accepted
requirement evidence only. Production behavior must not branch on Romeo IDs,
component IDs, class names, destination values, or filenames.

## Future production owners and tests

The minimum production owners for this capability are:

| Production file | Future responsibility |
| --- | --- |
| `apps/live_frames/lib/live_frames/adapters/bricks/static_navigation.ex` | Recognize the bounded heading link object and keep existing static-only failure rules. |
| `apps/live_frames/lib/live_frames/fidelity.ex` | Keep the heading root and emit the internal anchor. |
| `apps/live_frames/lib/live_frames/native_generator/renderer.ex` | Emit the same nested structure and place navigation attributes on the anchor. |
| `apps/live_frames/lib/live_frames/native_generator/style_integration.ex` | Own the bounded renderer-created heading-anchor presentation-neutralization rule in the generated stylesheet. |
| `apps/live_frames/lib/live_frames/componentization_plan/reference_validation.ex` | Revalidate the closed heading navigation shape as generation-representable. |

```text
PRODUCTION_IMPLEMENTATION_OWNER_FILES=apps/live_frames/lib/live_frames/adapters/bricks/static_navigation.ex; apps/live_frames/lib/live_frames/fidelity.ex; apps/live_frames/lib/live_frames/native_generator/renderer.ex; apps/live_frames/lib/live_frames/native_generator/style_integration.ex; apps/live_frames/lib/live_frames/componentization_plan/reference_validation.ex
CONDITIONAL_IMPLEMENTATION_OWNER=apps/live_frames/lib/live_frames/native_generator/stylesheet_renderer.ex
```

Change `StylesheetRenderer` only if the existing `StyleIntegration` and
`StylesheetRenderer` API cannot express the bounded deterministic
direct-child rule without duplication or ad-hoc raw CSS construction. If
that condition arises, stop for review before expanding scope. Do not treat
`StylesheetRenderer` as a required production change in this authority.

`DesignIRNormalizer` already attaches a returned navigation map without
changing heading semantics. `DesignNode`, IR validation, and the IR serializer
already represent the required fields. They do not need changes under this
authority.

Expected focused test files:

- `apps/live_frames/test/live_frames/bricks_static_navigation_test.exs`
- `apps/live_frames/test/live_frames/bricks_design_ir_test.exs`
- `apps/live_frames/test/live_frames/native_generator_test.exs`
- `apps/live_frames/test/live_frames/native_generator_v6_proofs_test.exs`
- `apps/live_frames/test/live_frames/native_generator/style_integration_test.exs`
- `apps/live_frames/test/live_frames/componentization_plan_reference_validation_test.exs`

Tests must cover tag preservation for h1 through h6, the static map and its
URL safety, nested markup parity, class and style ownership, visible focus
expectations, empty-content rejection, child and slot rejection, dynamic-link
rejection, and deterministic output. Style integration tests must prove that
the heading root retains its class and styles, the internal anchor receives
navigation attributes, the anchor effectively receives `color: inherit` and
`text-decoration: inherit`, no global anchor reset or source presentation is
copied to it, no focus suppression is emitted, and Fidelity and
NativeGenerator use the same presentation contract. If a later implementation
needs a `StylesheetRenderer` change, also require
`apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs`
in that implementation PR. No tests change in this authority PR.

```text
EXPECTED_STYLE_INTEGRATION_TEST=apps/live_frames/test/live_frames/native_generator/style_integration_test.exs
CONDITIONAL_STYLESHEET_RENDERER_TEST=apps/live_frames/test/live_frames/native_generator/stylesheet_renderer_test.exs
```

## Browser acceptance

The eventual implementation requires browser acceptance. Browser proof must
confirm that heading navigation preserves the heading level and does not
change heading presentation by itself, browser-default link color does not
leak through, and browser-default underline does not leak through unless the
heading already has inherited text decoration. It must also confirm that the
anchor remains keyboard focusable, visible focus remains present, and
navigation works. Do not run browser acceptance in this documentation PR.

```text
BROWSER_ACCEPTANCE_REQUIRED=YES
```

## Scope, performance, and lifecycle

The eventual implementation is one bounded capability named
`SUPPORTED_STATIC_HEADING_NAVIGATION`. It excludes CSS gap work, assets,
source settings, breakpoint resolution, local custom properties, compound
expressions, selector support, dynamic navigation, and Romeo componentization.

This is static conversion and generation work:

```text
DATA_LAYER=COLD_BUILD_TIME
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
REDIS=N/A
POSTGRES=N/A
CACHE=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
100K_CONCURRENT_USERS_IMPACT=NONE
```

The lane lifecycle remains:

```text
DISCOVERED
-> REQUIREMENT_CLASSIFIED
-> AUTHORITY_READY
-> IMPLEMENTATION_READY
-> IMPLEMENTED
-> CANONICAL_RERUN_VERIFIED
-> ACCEPTED
```

The lane enters this review at `REQUIREMENT_CLASSIFIED`. This record can move
it to `AUTHORITY_READY` after review, merge, and post-merge CI acceptance. It
does not authorize implementation. A later implementation gate must authorize
code changes explicitly.

```text
PRODUCTION_FILES_CHANGED=NO
TEST_FILES_CHANGED=NO
CONVERSION_MATRIX_CHANGED=NO
IMPLEMENTATION_STARTED=NO

NAV_CARRIER_STATE=AUTHORITY_READY_PENDING_PR_ACCEPTANCE
NAV_CARRIER_IMPLEMENTATION_AUTHORIZED=NO

ROMEO_COMPONENTIZATION_AUTHORIZED=NO
ROMEO_IMPLEMENTATION_AUTHORIZED=NO
ROMEO_NATIVE_GENERATION_AUTHORIZED=NO
```

After an authorized implementation is accepted, rerun canonical Romeo
normalization. The expected targeted diagnostic change is
`bricks.navigation.unsupported_carrier: 4 -> 0`; this record does not claim
that result. The rerun must show no unrelated canonical residual count change,
deterministic IR, and preserved visible-focus requirements.

```text
NEXT_GATE=REVIEW_AND_ACCEPT_NAV_CARRIER_REPRESENTATION_AUTHORITY
STOP=NONE
```
