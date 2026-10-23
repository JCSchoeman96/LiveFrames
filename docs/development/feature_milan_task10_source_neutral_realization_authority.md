# Feature Milan Task 10 Source-Neutral Realization Authority

## Status

The owner-approved Approach A realization policy is recorded here for implementation planning. Slice 0A publishes this authority and its execution plan before product changes begin.

This authority applies only to Feature Milan under the exact identities below. Each implementation slice has its own review gate. A later slice may begin only after the prior exact head is accepted.

## Frozen identity tuple

    IR_VERSION=5.0.0
    DESIGN_DOCUMENT_SHA256=9ae73053d9224bebcb71833b77094a17c3ef7c3a25f0b5b1c4dbad5aaf9d2229
    BEHAVIOR_BINDING_ID=bnd_abf701b79aba7597825525c7ddf5065e89a2fdcfb378797f63e3d9fb74ff8ee2
    BEHAVIOR_CONTRACT_DIGEST=1e0095418d96f392594a155d9c6ea9610b6b5f4d62c6d0205df66dedea57506a
    BEHAVIOR_REVIEW_ID=brv_b4bc3ab7f4284cf20ae6f0aaf73da3fd2c242e42d18f1ab049acc6f1e62e9c11
    BEHAVIOR_REVIEW_CANONICAL_BYTES_LENGTH=905
    BEHAVIOR_REVIEW_CANONICAL_SHA256=b4bc3ab7f4284cf20ae6f0aaf73da3fd2c242e42d18f1ab049acc6f1e62e9c11

The review identity matches the accepted IR5 review record in [Feature Milan IR5 BehaviorReviewResult issuance](feature_milan_ir5_behavior_review_result.md). The BehaviorReviewResult, BehaviorContract, and DesignDocument remain unchanged.

## R1A public API

The approved public API tuple is:

| Input | Authority |
| --- | --- |
| id | Required string used as root_id |
| features | Required list |
| feature_media | Required list |
| feature_heading_level | Optional integer; defaults to 3; allowed values 1 through 6 |
| intro slot | Required slot with cardinality 0..1 |

No additional serialized schema fields are authorized.

## N2 and N3 structure and styling

N2 is the structural div wrapper. Its normalized static base properties remain on that wrapper:

    background
    border-color
    border-left-width
    border-style
    display
    grid-template-columns
    grid-template-rows
    padding-left
    padding-right
    position
    row-gap
    transition

The normalized N2 inventory also contains custom-css. It is opaque complex CSS and is not emitted. No source selector or source custom CSS becomes runtime or styling authority.

N3 remains a semantic heading at the approved heading level. A native title button inside the heading carries Selection activation. No N3 source style relocation is required. The title binding appears once inside the button.

The title button uses package-owned neutralization for inherited font and color, transparent background, no border, zero padding and margin, inherited text alignment, and a pointer cursor. Native focus indication remains visible.

## Selection realization

Selection state is browser-local and derives from the approved selection@1.0.0 BehaviorContract through a transient generation-time authority. The authority is not serialized.

The native activation button exposes aria-pressed. LiveFrames-owned state markers identify the control occurrence and its selected state. Inactive items in both synchronized presentation collections use the HTML hidden attribute. The selected item is revealed. The first rendered item is selected initially.

Automatic advancement uses one 5000 ms wrapping timer per active instance. Manual activation permanently stops automatic advancement for that instance. Timer advancement does not move focus. Reduced-motion preference suppresses automatic advancement while preserving manual activation.

Collections resolve inside the component root, must have equal nonzero cardinality, and use caller position for synchronization. A mismatch makes that instance unavailable. Reconciliation may recover when the collections become valid again; it preserves the numeric selected position only when that position remains valid and never clamps it. Disconnect suspends resources, reconnect resumes only a previously running timer, and destruction removes resources permanently.

The realization does not use Tabs semantics. It emits no tablist or tab roles, aria-selected, aria-controls, tabpanel, or roving-tabindex policy. It uses no server state or server event for selection.

## Picture realization

The bounded native structure is picture > img. It adds no generated source elements.

| Property or value | Realization locus |
| --- | --- |
| position | Outer picture |
| object-fit | Inner img |
| width | Both picture and img |
| height | Both picture and img |
| Private class | Outer picture only |
| Asset source | Inner img |
| Asset alt text | Inner img |

No alt attribute is placed on picture. Existing image behavior for an absent explicit tag and for figure remains unchanged. The picture policy is closed: unsupported base properties, responsive styles, pseudo styles, state rules, or custom CSS that needs a second locus fail closed.

## Generation boundary

The implementation must derive transient NativeRealizationAuthority from the exact approved component contract, final plan, DesignDocument, BehaviorContract, and approved BehaviorReviewResult. Generation must not infer Selection permission from a plan alone.

Ordinary generation receives empty realization authority and remains fail-closed for generic buttons. The public behavior-aware generate/7 signature remains unchanged. Shared binding containment covers Behavior owners, controlled targets, trigger origins, focus references, and IR interaction references and targets.

## Prohibited changes

The implementation must not:

- Mutate the DesignDocument or reissue Behavior authority.
- Widen serialized schemas.
- Copy source JavaScript, CSS, selectors, or runtime behavior.
- Reproduce Tabs semantics or use server-side Selection state.
- Widen ordinary generic-button generation.
- Add a new generated JavaScript artifact type.
- Globally widen image-tag or static-markup authority.
- Generate picture source children.

## Evidence

The normalized N2/N3 inventory was captured from the accepted IR5 DesignDocument. N2 has the static properties listed above plus opaque custom-css; N3 has no normalized base, responsive, or pseudo style properties. The accepted picture image policies remain valid for N4 and N5.

For the source evidence boundary and rejected Tabs mapping, see [Feature Milan timed Selection mapping preflight](feature_milan_timed_selection_mapping_preflight.md). The accepted BehaviorReviewResult and its canonical identity are recorded in [Feature Milan IR5 BehaviorReviewResult issuance](feature_milan_ir5_behavior_review_result.md).

## Authorization state

    APPROACH_A=APPROVED
    SLICE_0A=DOCUMENTATION_ONLY
    PRODUCTION_IMPLEMENTATION=NOT_AUTHORIZED_BY_THIS_DOCUMENT
    T1_AND_LATER_IMPLEMENTATION=NOT_AUTHORIZED
    FUTURE_SLICES_REQUIRE_ACCEPTANCE_OF_EACH_PRIOR_EXACT_HEAD
    R1B_RERUN=NOT_AUTHORIZED
    R1C_COMPONENT_REVIEW=NOT_AUTHORIZED
