# P7 interaction conversion implementation plan

**Plan version:** 1.0.8
**Date:** 2026-10-10
**Status:** proposed authority amendment; P7-B1, P7-B2, and P7-B3 are implemented and accepted; P7-B4 is blocked pending v1.0.8 acceptance
**Authority:** `docs/09_INTERACTION_MODEL.md` revision 1.0.1
**Base:** `5ea3b0b597eaeebec5524998db93a29e5f7225e8`
**Tree:** `4a4edf77a826db6840407626155cd68bce39149d`
**Base CI:** `38044213077 PASS`

## 1. Purpose and authority

P7 establishes a source-neutral behavior contract and turns accepted behavior evidence into accessible Phoenix-native interactions. It must preserve the accepted C09D6 static generation path, bind behavior to one exact DesignDocument, and keep source runtimes and executable source material out of generated components.

This document resolves the implementation decisions that `docs/09_INTERACTION_MODEL.md` left open. It is an implementation plan and issue decomposition only. P7-0 itself authorized no implementation. P7-A1 and P7-A2 were separately owner-authorized, implemented, reviewed, merged, and accepted. P7-B1, P7-B2, and P7-B3 are implemented and accepted. PR #179 merged at `5ea3b0b597eaeebec5524998db93a29e5f7225e8` with a valid signature and passing post-merge CI. The drift from B3's reviewed base was limited to non-overlapping CTA Tango proposer-run/proposer-output documentation. This v1.0.8 amendment freezes the remaining B4 review-result authority. B4 remains blocked until this amendment is independently accepted and merged with passing post-merge CI. Each later issue still needs separate owner authorization.

```text
P7_A1_STATUS=IMPLEMENTED_ACCEPTED
P7_A1_PR=154
P7_A2_STATUS=IMPLEMENTED_ACCEPTED
P7_A2_PR=157
P7_B1=IMPLEMENTED_ACCEPTED
P7_B2=IMPLEMENTED_ACCEPTED
P7_B3=IMPLEMENTED_ACCEPTED
P7_B3_PR=179
P7_B3_APPROVED_HEAD=5a64f6330d8376a84b17893ebf22e93352abe5e7
P7_B3_MERGE_SHA=5ea3b0b597eaeebec5524998db93a29e5f7225e8
P7_B3_MERGE_TREE=4a4edf77a826db6840407626155cd68bce39149d
P7_B3_MERGE_SIGNATURE=VALID
P7_B3_POST_MERGE_CI=38044213077
P7_B3_POST_MERGE_CI_RESULT=PASS
B3_MERGE_DRIFT=SAFE_NON_OVERLAPPING_DOCUMENTATION
P7_B4=BLOCKED_PENDING_V1_0_8_ACCEPTANCE
P7_B4_PREREQUISITES=SATISFIED
P7_B4_IMPLEMENTED=NO
P7_C_STARTED=NO
```

Versions 1.0.5 and 1.0.6 are accepted. Version 1.0.6 froze the FocusPolicy typed DesignNode references, their cardinality, the B1 structural model, and B2 deterministic binding identity. The accepted 1.0.7 amendment froze BehaviorContract persistence, canonical serialization, and structural/reference validation. This 1.0.8 amendment freezes B4 review-result authority. Neither amendment changes `docs/09_INTERACTION_MODEL.md`, the BehaviorContract format version, Design IR, or the accepted B2 binding-ID formula. This amendment authorizes no implementation.

The target flow is:

```text
untrusted source behavior evidence
  → source-neutral normalization
  → BehaviorContract linked to exact DesignDocumentIdentity
  → contract validation
  → explicit immutable BehaviorReviewResult
  → DesignDocument + BehaviorContract + approved BehaviorReviewResult
    + explicit ComponentizationSemanticInput
  → BehaviorComponentizationDecision
  → existing ComponentizationProposer
  → proposed ComponentContract + ComponentizationPlan
  → explicit ComponentReview
  → exact reviewed behavior tuple + exact approved component tuple
  → BehaviorProjection with checked binding ownership
  → runtime realization selection
  → semantic HTML/CSS, LiveView.JS, colocated JS/hook,
    or server ownership only when required
  → interactive native component
  → Storybook, browser, and accessibility verification
```

The reusable `apps/live_frames` library remains independent of the preview application, Bricks, Frames, WordPress, ACSS, source JavaScript, private vendor code, and source runtime packages.

```text
ACSS_DEPENDENCY=NO
FRAMES_RUNTIME_DEPENDENCY=NO
STATIC_STYLING_GENERATOR_DEPENDENCY=NO
SOURCE_RUNTIME_DEPENDENCY=NO
```

## 2. Repository truth and compatibility boundary

The cited authorities agree on these facts:

| Area | Current repository truth | P7 rule |
| --- | --- | --- |
| Design IR | `LiveFrames.IR.DesignDocument` writes IR `3.0.0`. Required root fields include `interactions`; there is no `behaviors` registry. | Keep BehaviorContract separate. Do not change required fields, field meanings, or serialized Design IR in P7-A1 through P7-L. |
| Coarse interaction intent | `LiveFrames.IR.Interaction` contains `interaction_id`, `intent`, `trigger`, `target_node_ids`, `parameters`, and `source_trace`. It describes intent and does not select a runtime. | Do not expand or reinterpret it. Existing `interaction_refs` remain references to the current interaction registry. |
| DesignDocument identity | `LiveFrames.IR.Identity` uses `canonicalization_id=lf-ir-serializer-v1` and `digest_algorithm=sha-256`. `ComponentizationPlan.design_document_sha256/1` delegates to it and retains its compatibility API. | Reuse these exact bytes and digest. Do not replace the digest with JCS or add a second DesignDocument hash. |
| IR serializer | `LiveFrames.IR.Serializer` emits explicit fields, converts trusted enum atoms to strings, sorts object keys recursively, preserves list order, and delegates JSON encoding to Jason. IR tests assert deterministic output for equivalent conversions. | Treat this existing serializer byte representation as the DesignDocument canonical form for P7. Lock it with golden compatibility tests before changing any implementation. |
| Canonical JSON | `LiveFrames.CanonicalJSON` owns the source-neutral JCS value encoder. `LiveFrames.Catalogue.CanonicalJSON` is the compatibility wrapper preserving Catalogue bytes, diagnostics, and fingerprints. | `LiveFrames.Behavior.*` must not depend on `LiveFrames.Catalogue.*`. Keep Catalogue fingerprints byte-for-byte stable. |
| Componentization | `ComponentContract 1.0.0` owns the public API and its approval result. `ComponentizationPlan 1.0.0` owns placement and links to a contract and DesignDocument. C09D6 has shared generation prerequisites and human ComponentReview. | Keep both accepted formats unchanged. Behavior review cannot approve a ComponentContract or substitute for ComponentReview. |
| Slide Menu Alpha disclosure mapping | `docs/development/slide_menu_alpha_disclosure_mapping_preflight.md` accepts the `closed | open` core and native `<details>/<summary>` sufficiency. The full mapping remains partial. Current-page identity input is evidence-insufficient; current-page timing and update lifecycle are unknown; nested policy, accessibility mapping, and motion mapping are partial; target style authority is required; hook need is not proven. | P7-F may test only the accepted core. It must not claim a complete Slide Menu conversion or infer current-page, nesting, ARIA, keyboard, hook, or motion details. |

The accepted Slide Menu classifications remain:

```text
CORE_DISCLOSURE_MAPPING=SUPPORTED
NATIVE_DETAILS_CORE_SUFFICIENCY=SUPPORTED_BY_AUTHORITY
NESTED_DISCLOSURE_MAPPING=PARTIAL
EXCLUSIVE_ACCORDION_POLICY=NOT_PROVEN
CURRENT_PAGE_OPEN_EFFECT=SUPPORTED
CURRENT_PAGE_IDENTITY_INPUT=EVIDENCE_INSUFFICIENT
CURRENT_PAGE_EFFECT_TIMING=UNKNOWN
CURRENT_PAGE_UPDATE_LIFECYCLE=UNKNOWN
ACCESSIBILITY_MAPPING=PARTIAL
MOTION_MAPPING=PARTIAL
HOOK_REQUIRED=NOT_PROVEN
STYLE_AUTHORITY_REQUIRED=YES
OVERALL_VERDICT=PARTIAL_BEHAVIOR_CONTRACT_MAPPING
```

`FULL_SLIDE_MENU_ALPHA_TRACER=BLOCKED` until the missing Slide Menu-specific input, lifecycle, nesting, accessibility, and style authorities are accepted. The supported core remains useful evidence and does not authorize its implementation.

The accepted authorities and current source tree do not contain an approved Disclosure ComponentContract/ComponentizationPlan pair. P7-F must not create that pair as part of the tracer. Native component/story work remains blocked by `STOP=COMPONENTIZATION_PREREQUISITE_MISSING` until the owner separately authorizes and accepts the exact tuple.

### 2.1 DesignDocument identity decision

The exact identity tuple is:

```text
DesignDocumentIdentity =
  ir_version
  + canonicalization_id
  + lowercase_sha256(IR.encode!(validated DesignDocument) bytes)
```

The accepted canonicalization algorithm is `lf-ir-serializer-v1`. For the current Design IR, that identifier means the explicit field mapping and recursively sorted JSON-object encoding in `LiveFrames.IR.Serializer`, with list order preserved and Jason JSON encoding as locked by the repository. The digest algorithm identifier is `sha-256`. The supported identity records IR `3.0.0`, `lf-ir-serializer-v1`, `sha-256`, and the exact digest produced by `ComponentizationPlan.design_document_sha256/1`.

P7-A1 implemented the source-neutral `LiveFrames.IR.Identity` boundary. `ComponentizationPlan.design_document_sha256/1` remains callable and delegates to it, preserving its return shape and historical digest. The plan format did not gain an algorithm field. BehaviorContract carries the explicit identity tuple and rejects unknown canonicalization IDs or unsupported IR versions.

This choice uses repository behavior rather than RFC 8785 because the accepted Design IR serializer owns typed struct-to-map conversion and admits finite JSON floats in IR values, while Catalogue JCS rejects floats and accepts only normalized string-key maps. Switching DesignDocument identity to JCS would change the established componentization fingerprint and require explicit migration analysis. The current IR serializer has explicit field conversion, deterministic key ordering, stable list ordering, and deterministic-output tests. The accepted algorithm remains fixed; any proposed change must stop with `STOP=IDENTITY_ALGORITHM_UNRESOLVED` rather than silently replacing it.

### 2.2 BehaviorBinding identity decision

Binding identity uses the following complete structured payload, encoded as canonical JSON before hashing:

```json
{
  "behavior_contract_format_version": "1.0.0",
  "design_document_identity": {
    "ir_version": "3.0.0",
    "canonicalization_id": "lf-ir-serializer-v1",
    "digest_algorithm": "sha-256",
    "digest": "<64 lowercase hexadecimal characters>"
  },
  "owner_node_id": "<normalized DesignNode ID>",
  "primitive_kind": "<closed vocabulary value>",
  "binding_role": "<stable semantic role>",
  "ordinal": 0
}
```

The identifier algorithm is `lf-behavior-binding-v1-jcs-sha256`. The ID is lowercase SHA-256 of those canonical payload bytes, prefixed `bnd_`. The payload uses named JSON fields, explicit string enum values, a non-negative integer ordinal, and the exact DesignDocument identity. Its `primitive_kind` value is `primitive_ref.kind`; `definition_version` is deliberately excluded from this accepted binding ID formula. It is unambiguous and does not rely on concatenation or separators. `binding_role` is required and source-independent. P7-B1 defines `binding_id` and `ordinal` as unassigned (`null`) only on the normalized pre-identity binding value; persisted BehaviorContract bindings must have both. P7-B2 assigns them. The semantic structure is fully typed before identity derivation; there is no provisional discriminator map.

Ordinal assignment is fixed. First group normalized bindings by the exact tuple `(owner_node_id, primitive_ref.kind, binding_role)`. For each binding, its semantic discriminator is a canonical JSON object with exactly these top-level fields:

```json
{
  "owner_node_id": "<DesignNode ID>",
  "primitive_kind": "<closed primitive string>",
  "binding_role": "<stable semantic role>",
  "initial_state": null,
  "primitive_policy_values": {},
  "triggers": [],
  "controlled_targets": [],
  "timer_policy": null,
  "focus_policy": null,
  "keyboard_policy": null,
  "motion_policy": null,
  "responsive_overrides": []
}
```

Each nested value is a normalized typed BehaviorBinding occurrence value. The discriminator removes exactly `binding_id`, `ordinal`, `diagnostics`, `provenance`, and `source_trace` from the binding. P7-B1 freezes the nested field shapes within these binding-owned fields before P7-B2 implements this algorithm. The map includes `primitive_kind` from `primitive_ref.kind`, typed trigger kind/origin, controlled target roles and node IDs, an optional occurrence-specific initial-state assignment, primitive-specific policy values, and the five named cross-cutting binding policies. It excludes `primitive_ref.definition_version` and the primitive definition's state dimensions/domains, default initialization, invariants, transitions, guards, or effects. Those remain owned by the trusted primitive registry and do not participate in binding identity. A runtime or component-instance value is not a legal BehaviorBinding field. Source/vendor IDs, selectors, and classes are invalid semantic fields and cannot enter this map.

The discriminator's object keys use JCS ordering. Sort trigger records by their complete JCS bytes, targets by `(role, node_id)`, and responsive overrides by mode key. Canonicalize the optional initial-state assignment by its declared dimension keys and typed values. For `primitive_policy_values`, recursively canonicalize object keys with JCS and preserve every array's exact order. B2 must not sort policy arrays or classify them according to primitive-specific meaning. Every policy array is structurally an ordered sequence, so `["a", "b"]` and `["b", "a"]` produce different discriminator bytes. Whether a particular primitive policy permits an array is validated later by P7-C against the exact definition. When that definition declares an unordered/set-like policy, its permitted shape should be a string-keyed object keyed by stable semantic identity; P7-C rejects other shapes. Other schema-declared set-like collections retain their separately defined stable ordering. No primitive state-machine definition enters the discriminator. Encode each discriminator with JCS. Within a group, byte-identical discriminators are duplicate semantic bindings and reject the group before any ID is assigned. Otherwise, sort discriminator byte strings in ascending unsigned byte order. The zero-based position is the `ordinal` used in each binding's ID payload. Raw source traversal or map insertion order never participates. P7-B2 consumes the typed structural model defined by P7-B1 and must add golden tests for policy map-order invariance, ordered-array sensitivity, stable-key object invariance, source-order noise, duplicate rejection, distinct deterministic ordinals, and stable binding IDs. If normalized occurrence semantics cannot distinguish bindings without a circular ID dependency, stop with `STOP=IDENTITY_ALGORITHM_UNRESOLVED`.

### 2.3 Primitive-specific occurrence policy values

`BehaviorBinding` has one source-neutral field named `primitive_policy_values`. Its default is the empty object `{}`. Each binding carries the selected policy assignments for that one occurrence:

```text
primitive_policy_values = {
  "<primitive-specific policy dimension>": <canonical typed value>,
  ...
}
```

The B1 structural model contains exactly the following listed occurrence fields, in addition to each field's declared nested type:

```text
binding_id
ordinal
primitive_ref
owner_node_id
binding_role
initial_state
primitive_policy_values
triggers
controlled_targets
timer_policy
focus_policy
keyboard_policy
motion_policy
responsive_overrides
diagnostics
provenance
source_trace
```

On the normalized pre-identity binding, `binding_id` and `ordinal` are `null`. B2 assigns both for persisted BehaviorContract bindings. This structural field list does not add primitive-definition or state-machine fields to BehaviorBinding.

`initial_state` assigns values to primitive STATE dimensions. `primitive_policy_values` assigns values to primitive POLICY dimensions. They are separate fields and cannot carry each other's dimensions. For example, an Accordion occurrence may assign `open_item_ids` through `initial_state`, and `mode`, `closure`, or `item_enabled` through `primitive_policy_values`. These are example primitive-specific keys, not universal BehaviorBinding fields. Other established examples include Disclosure `enabled`, and Disclosure Popup `enabled`, pointer-hover availability, and dismiss policy.

`BehaviorPrimitiveDefinition` owns permitted primitive policy keys, value types and shapes, value domains, defaults, and invariants. `BehaviorBinding` owns the selected occurrence values. P7-B1 validates structural representation only: object keys are strings, values use the accepted canonical value algebra, and every array is an ordered sequence. B1 does not decide whether a policy key or value shape is permitted for a primitive. P7-B2 deterministically identities that structural representation without classifying arrays by primitive-specific meaning. P7-B3 validates structure and references, then serializes the values. P7-C resolves exactly `(PrimitiveRef.kind, PrimitiveRef.definition_version)` and validates selected keys, value types and shapes, domains, required/optional status, and invariants against that definition. It may reject an array when the exact definition requires another shape, but it never reinterprets an array as a set or changes its order. P7-C does not fall back to kind-only or latest-version lookup. No validation implementation is authorized by this documentation change.

### 2.4 FocusPolicy structural shape and node references

Version 1.0.5 established that FocusPolicy owns initial focus, containment or roving, restoration, and focus scope, with typed node references. It did not define the concrete reference fields or their cardinality. P7-B1 uses this closed structural shape:

```text
FocusPolicy
  initial_strategy: string | null
  initial_target_node_id: DesignNode ID | null
  containment_strategy: string | null
  movement_strategy: string | null
  scope_node_id: DesignNode ID | null
  restoration_strategy: string | null
  restoration_target_node_id: DesignNode ID | null
  restoration_fallback_node_id: DesignNode ID | null
```

`BehaviorBinding.focus_policy` has cardinality zero or one. Each of the four node-reference fields has cardinality zero or one. The complete FocusPolicy DesignNode-reference set is `initial_target_node_id`, `scope_node_id`, `restoration_target_node_id`, and `restoration_fallback_node_id`. No FocusPolicy field carries a list of arbitrary node IDs.

All four `*_strategy` values are inert source-neutral strings or `null` in B1. B1 checks structural types only. P7-C owns their closed vocabularies and validates which strategies require, allow, or prohibit each related reference, along with primitive-specific focus rules and modal/non-modal requirements. No imported string becomes an atom.

When `scope_node_id` is `null`, `binding.owner_node_id` is the focus scope. This is the only canonical representation of the owner as focus scope. A non-null `scope_node_id` must identify a node distinct from `binding.owner_node_id`; an explicit reference equal to the owner is noncanonical and B1 rejects it before identity assignment. B2 receives canonical B1 input and does not normalize redundant scope forms. A distinct non-null scope is structurally allowed, while P7-C decides whether the primitive and strategy permit it. `initial_target_node_id` is the optional explicit destination for predetermined initial focus, such as an accepted static title/content anchor. A dynamic strategy such as choosing the first appropriate focusable descendant does not serialize a node ID for that runtime choice. P7-C validates the strategy/reference combination.

`restoration_target_node_id` is the optional explicit return-focus destination. `restoration_fallback_node_id` is the optional explicit logical fallback if that destination is unavailable. Both are DesignNode references. P7-C validates their combinations with `restoration_strategy`.

FocusPolicy does not serialize `invoker_node_id`, `runtime_invoker_id`, or `last_trigger_node_id`. A strategy that returns focus to the invoker uses the activating occurrence/runtime context; the concrete invoker is ephemeral RuntimeInstance state. Roving-focus members and other concrete control/item relationships remain in `controlled_targets`. FocusPolicy does not duplicate them as `roving_node_ids`, `focusable_node_ids`, or `contained_node_ids`. `movement_strategy` may express source-neutral movement semantics only.

P7-B3 serializes every FocusPolicy field, preserves strategy values as strings, and resolves every explicit typed DesignNode reference against the exact DesignDocument. Its complete reference set is `owner_node_id`, non-null trigger origins, controlled-target nodes, the four FocusPolicy references, and non-null diagnostic node IDs. It rejects malformed or unresolved references and never searches selectors for replacements. P7-D0 and P7-D1 enumerate the binding-owned reference set for their boundary checks; diagnostic references remain contract integrity references. P7-C owns the strategy vocabulary and semantic combinations. A later accepted primitive that needs another concrete node relationship requires a separate typed-reference authority amendment.

Other cross-cutting policies cannot introduce hidden DesignNode references through arbitrary strings or maps:

```text
TIMER_POLICY_DESIGN_NODE_REFS=NONE
KEYBOARD_POLICY_DESIGN_NODE_REFS=NONE
MOTION_POLICY_DESIGN_NODE_REFS=NONE
RESPONSIVE_OVERRIDE_DESIGN_NODE_REFS=NONE
```

Keyboard focus movement is expressed semantically over already typed binding relationships. Any future requirement for another concrete node relationship needs an explicit typed field and matching B3/D0/D1 enumeration authority.

```text
FOCUS_POLICY_CARDINALITY=0..1
FOCUS_POLICY_NODE_REFERENCE_FIELDS=initial_target_node_id,scope_node_id,restoration_target_node_id,restoration_fallback_node_id
EACH_FOCUS_POLICY_NODE_REFERENCE_CARDINALITY=0..1
NULL_SCOPE_MEANS_BINDING_OWNER=YES
FOCUS_SCOPE_CANONICAL_FORM=NULL_FOR_BINDING_OWNER
EXPLICIT_SCOPE_EQUAL_TO_OWNER_ALLOWED=NO
B2_CAN_RECEIVE_REDUNDANT_OWNER_SCOPE=NO
FOCUS_POLICY_SERIALIZES_RUNTIME_INVOKER=NO
FOCUS_POLICY_DUPLICATES_CONTROLLED_TARGETS=NO
P7_C_OWNS_FOCUS_STRATEGY_VOCABULARY_AND_COMBINATIONS=YES
P7_B3_RESOLVES_ALL_FOUR_FOCUS_NODE_REFS=YES
P7_D0_ENUMERATES_ALL_FOUR_FOCUS_NODE_REFS=YES
P7_D1_ENUMERATES_ALL_FOUR_FOCUS_NODE_REFS=YES
```

```text
UNKNOWN_KIND_VERSION_PAIR=UNSUPPORTED
KIND_ONLY_FALLBACK=PROHIBITED
LATEST_VERSION_FALLBACK=PROHIBITED
```

The value algebra is the existing BehaviorContract-safe canonical JSON algebra: `null`, booleans, safe integers, valid Unicode strings, arrays of allowed values, and string-keyed objects of allowed values. Within `primitive_policy_values`, every array at every nesting level is structurally an order-significant sequence, and B1, B2, and B3 preserve that order exactly. Arrays are not a generic unordered collection representation. The exact `BehaviorPrimitiveDefinition` determines the permitted value type and shape for each policy key. If a definition declares a policy to be unordered/set-like, its permitted representation should be a string-keyed object keyed by stable semantic identity; P7-C validates that shape and rejects a mismatching array. For example, an exact definition may permit per-item enabled values as `{"item_enabled":{"item-a":true,"item-b":false}}` and reject `{"item_enabled":["item-a","item-b"]}`. `item_enabled` is an example, not a universal field. B1/B2 do not infer set-like meaning from a policy key or array. If a future policy cannot be modeled safely with the value algebra and its exact definition, it requires a separately authorized explicit typed field. P7-C may validate whether an exact primitive definition permits an ordered sequence, but it cannot change or reinterpret the sequence's order. Floats, functions, PIDs, references, tuples, structs, arbitrary atoms derived from input, and executable terms are forbidden. Trusted serializer code may map trusted enums to fixed strings. It must never convert imported strings to atoms.

```text
PRIMITIVE_POLICY_ARRAYS_ORDER_SIGNIFICANT=YES
PRIMITIVE_POLICY_OBJECT_KEYS_CANONICALIZED=YES
PRIMITIVE_POLICY_ARRAY_ORDER=ALWAYS_SEMANTIC
B1_CLASSIFIES_SET_LIKE_POLICY=NO
B2_CLASSIFIES_SET_LIKE_POLICY=NO
B2_PRESERVES_ARRAY_ORDER=YES
B2_REQUIRES_P7_C_FOR_ARRAY_ORDERING=NO
P7_C_VALIDATES_POLICY_VALUE_SHAPE=YES
P7_C_CAN_REJECT_ARRAY_FOR_EXACT_POLICY=YES
P7_C_CAN_REINTERPRET_POLICY_ARRAY_AS_SET=NO
P7_C_CAN_REORDER_ARRAY=NO
SET_LIKE_POLICY_REPRESENTATION_GUIDANCE=STABLE_KEY_OBJECT
SET_LIKE_ARRAY_REJECTION_OWNER=P7-C_SEMANTIC_VALIDATION
```

Policy values cannot contain or encode DesignNode references. D0 enumerates explicit typed references: `owner_node_id`, trigger origins, `controlled_targets`, and the four FocusPolicy node references frozen in §2.4. TimerPolicy, KeyboardPolicy, MotionPolicy, and ResponsiveBehaviorOverride cannot introduce DesignNode references in B1. A future primitive relationship requires a separately authorized typed structural field and matching B3/D0/D1 reference enumeration. Primitive policy values do not replace `timer_policy`, `focus_policy`, `keyboard_policy`, `motion_policy`, or `responsive_overrides`; those remain shared cross-primitive contracts, while this field holds only primitive-specific occurrence policies.

This field does not change the accepted ownership hierarchy: `BehaviorPrimitiveDefinition → BehaviorStateModel → Transition → TransitionGuard / BehaviorEffect`. `BehaviorBinding` does not own state models, state domains, default-state definitions, invariants, transitions, guards, effects, or terminal-state definitions. `PrimitiveRef` remains exactly `{kind, definition_version}`. Unknown pairs are unsupported; kind-only and latest-version fallbacks are prohibited.

```text
INITIAL_STATE_CAN_CARRY_POLICY_DIMENSIONS=NO
PRIMITIVE_POLICY_VALUES_CAN_CARRY_STATE_DIMENSIONS=NO
PRIMITIVE_POLICY_VALUES_CONTAIN_DESIGN_NODE_REFS=NO
BINDING_ID_FORMULA_CHANGED=NO
BINDING_ID_DIRECTLY_INCLUDES_PRIMITIVE_POLICY_VALUES=NO
PRIMITIVE_POLICY_VALUES_SERIALIZED=YES
PRIMITIVE_POLICY_VALUES_IN_CONTRACT_DIGEST=YES
```

### 2.5 Cross-cutting policy structural shapes

The five cross-cutting binding policies use source-neutral structures that B1 can freeze without taking ownership of P7-C semantic vocabularies. Their stored values are occurrence data. B1 does not serialize them or call `LiveFrames.CanonicalJSON` during normal construction to produce bytes.

```text
CrossCuttingPolicyValues
= string-keyed canonical-value object

canonical value
= null
| boolean
| safe integer
| valid Unicode string
| ordered array of canonical values
| string-keyed object of canonical values
```

Every array at every nesting level is an order-significant sequence. B2 preserves each array's exact order. P7-C may reject an unpermitted value shape, but it never reinterprets or reorders an accepted array. Unordered or set-like data uses a stable string-keyed object, not an array. Object keys use the existing source-neutral CanonicalJSON value domain; B1 does not encode these policy values.

```text
CROSS_CUTTING_POLICY_ARRAYS_ORDER_SIGNIFICANT=YES
CROSS_CUTTING_POLICY_VALUES_CONTAIN_DESIGN_NODE_REFS=NO
B2_REQUIRES_P7_C_FOR_CROSS_CUTTING_STRUCTURE=NO
```

Strings in these generic values are inert data. They never become DesignNode references by key name, prefix, equality with a node ID, selector, or source ID. A future concrete node relationship requires an explicit typed structural field and matching B3/D0/D1 reference authority. FocusPolicy remains the accepted cross-cutting policy with explicit occurrence-level node references.

The three singular policy fields have this B1 shape and default:

```text
BehaviorBinding.timer_policy: CrossCuttingPolicyValues | null = null
BehaviorBinding.keyboard_policy: CrossCuttingPolicyValues | null = null
BehaviorBinding.motion_policy: CrossCuttingPolicyValues | null = null
```

B1 checks the string-keyed object and recursive canonical-value structure only. It does not define universal fields inside these objects. P7-C owns the semantic keys, values, domains, applicability, required/optional status, defaults, and invariants. It owns TimerPolicy purpose, duration, eligibility, start/stop/restart/reset behavior, reduced-motion interaction, and named-timer semantics; KeyboardPolicy interaction models, key/modifier vocabularies, transition mappings, and focus-movement semantics; and MotionPolicy animation, autoplay, reduced-motion, and time/state semantics. Named timer configuration may use stable string keys when a later exact definition permits it. Keyboard focus movement acts over existing typed binding relationships. None of these three policies contains DesignNode references.

Responsive overrides have a closed outer record because B2 orders them by mode. `ResponsiveBehaviorOverride` has exactly these three fields:

```text
ResponsiveBehaviorOverride
  mode: string
  authority_ref: string | null
  state_mapping: CrossCuttingPolicyValues

BehaviorBinding.responsive_overrides: [ResponsiveBehaviorOverride] = []
```

`mode` is the source-neutral mode key used for deterministic ordering. `authority_ref` is a stable source-neutral semantic identifier for the accepted responsive authority that defines or resolves the mode condition used by this override. It is an inert compile-time identifier, not an evidence citation, selector, URL, filesystem path, module name, runtime callback, or source-runtime identifier. Evidence-only citations belong in `provenance`, `source_trace`, or the applicable diagnostic/evidence structure, and never in `authority_ref`. Because the authority is semantic occurrence input, `authority_ref` participates in the B2 discriminator and the canonical BehaviorContract bytes and digest. `state_mapping` is a string-keyed canonical-value object; P7-C owns accepted responsive authority, allowed modes, mapping validity and reversibility, and primitive-specific compatibility. This field adds no DesignNode references.

Within one binding, `mode` values must be structurally unique. B1 rejects duplicate modes before B2 assigns any ordinal or ID. It does not keep the first/last record or use input order as a tie-breaker. P7-C decides whether a unique mode string is semantically allowed.

```text
RESPONSIVE_OVERRIDE_MODE_UNIQUE_PER_BINDING=YES
RESPONSIVE_AUTHORITY_REF_IS_SEMANTIC=YES
RESPONSIVE_AUTHORITY_REF_IS_PROVENANCE_ONLY=NO
EVIDENCE_ONLY_RESPONSIVE_REFERENCE_IN_AUTHORITY_REF=NO
```

B2 canonicalizes object keys in `timer_policy`, `keyboard_policy`, `motion_policy`, and each responsive `state_mapping` through JCS while preserving every nested array's order. It uses the complete typed FocusPolicy value, assumes B1 has rejected an explicit owner-valued `scope_node_id`, and does not normalize redundant scope forms. It sorts `responsive_overrides` by unique `mode`; source traversal order is never a tie-breaker. A semantic `authority_ref` participates in the discriminator. Evidence-only responsive citations remain in excluded provenance/source-trace fields and do not affect binding identity. Duplicate modes reject before identity assignment. These rules require no P7-C lookup:

```text
B2_REQUIRES_P7_C_FOR_CROSS_CUTTING_STRUCTURE=NO
```

B3 serializes the stored forms of `timer_policy`, `focus_policy`, `keyboard_policy`, `motion_policy`, and `responsive_overrides`. Objects canonicalize with JCS. Arrays preserve stored order except where §2.7 assigns a canonical collection order. Generic cross-cutting values do not create DesignNode references; B3 resolves only the explicit typed reference set in §2.7.

After this amendment B1 stores the policies as follows:

```text
timer_policy             = null | CrossCuttingPolicyValues
focus_policy             = null | exact FocusPolicy
keyboard_policy          = null | CrossCuttingPolicyValues
motion_policy            = null | CrossCuttingPolicyValues
responsive_overrides     = [ResponsiveBehaviorOverride]
```

B1 does not own semantic keys/values, primitive applicability, policy defaults beyond the field defaults above, primitive-specific invariants, or runtime behavior. P7-C owns those decisions. This amendment does not implement these types or tests.

B1 tests prove the three null defaults, the empty responsive list default, recursive string-keyed safe policy values, ordered arrays, exact `ResponsiveBehaviorOverride` fields, unique responsive modes, and the absence of any generic policy node-reference channel. They also prove `scope_node_id: nil` is the canonical owner scope, an explicit scope equal to the owner is rejected, and a distinct explicit scope is structurally allowed. B2 tests prove reordered unique responsive records yield the same discriminator, duplicate modes reject before identity assignment, and only canonical FocusPolicy scope forms reach identity assignment. They prove changing semantic `authority_ref` changes the discriminator while changing evidence-only provenance/source-trace references does not. B3 tests that changing `authority_ref` changes canonical bytes and digest. This plan amendment implements no tests.

### 2.6 BehaviorContract serialization and digest decision

P7-A2 is implemented and accepted. It moved the tested JCS value encoder behind `LiveFrames.CanonicalJSON` with a neutral validation result/reason API. `LiveFrames.Catalogue.CanonicalJSON` remains a compatibility wrapper and maps every neutral failure to the existing `catalogue.canonical_json.*` code, path, and message exactly. It preserves success bytes, error shape, validation order, paths, messages, and Catalogue fingerprint values. The Behavior serializer maps neutral failures to `behavior.*` diagnostics. This is the only canonical JSON implementation. The Behavior domain serializes a typed, explicit map through this utility and does not call Catalogue modules.

The BehaviorContract value algebra is exactly the extracted JCS algebra: `null`, booleans, safe integers, valid Unicode strings, arrays, and objects with valid Unicode string keys. Behavior semantics use integer milliseconds and closed string vocabularies, so binary floats are unnecessary and invalid. Structs, atoms, non-finite numbers, oversized integers, improper lists, invalid Unicode, and non-string object keys are rejected before encoding. Trusted Elixir enum atoms become their fixed vocabulary strings in the Behavior serializer; untrusted strings never become atoms.

The algorithm identifier is `lf-behavior-v1-jcs-sha256`. It identifies explicit BehaviorContract `1.0.0` field mapping, JCS bytes, and SHA-256. Digest output is lowercase hexadecimal. P7-B3 must freeze golden canonical bytes and digest fixtures before any future schema change.

Serialization rules are fixed as follows:

- The serializer emits every defined top-level field. Optional scalar/reference fields encode as JSON `null`; empty collections encode as `[]` or `{}` according to their declared type. The serializer never alternates between omission and null for one field.
- Primitive references, triggers, roles, primitive policy values, cross-cutting policy values, keys, severity, category, identifiers, and algorithm names serialize using their declared safe types and closed strings. Primitive transition/effect definitions remain registry-owned and are not contract fields. No atom names are created from input.
- Binding order is ascending `binding_id`. P7-B3 collection ordering is frozen in §2.7. Primitive definitions and their state dimensions, invariants, transitions, guards, and effects are not serialized as BehaviorContract fields. Object keys follow JCS ordering.
- Within `primitive_policy_values`, object keys use canonical JCS ordering and arrays are emitted in their stored order. The serializer never sorts policy arrays and does not consult primitive-registry semantics to choose an order.
- `primitive_policy_values` participates in the semantic discriminator, canonical BehaviorContract bytes, and contract digest. Changing its selected values changes the BehaviorReviewResult compatibility input. The field cannot carry DesignNode references.
- Diagnostics and provenance participate in the BehaviorContract digest, as required by `docs/09` §5 and §6. Their exact fields, ordering, and canonical value shapes are frozen in §2.7.
- Source trace values may preserve inert provenance strings and paths. `source_path` is provenance only. The serializer never opens, resolves, executes, filesystem-normalizes, or uses it as runtime input.
- Runtime handles, DOM nodes, listener functions, timers, observers, component-instance scope, current focus, current viewport, and transient runtime state never enter serialized identity.

Unknown algorithm IDs fail closed. A diagnostic may explain an unknown algorithm, but consumers must not hash with a fallback algorithm or compare digests from unlike algorithms. The contract serializes each binding's full trusted `PrimitiveRef` and occurrence semantics; it never embeds a second copy of the trusted primitive registry. `PrimitiveRef` includes `kind` and `definition_version`, and both fields participate in canonical BehaviorContract bytes and its digest. Changing the referenced definition version therefore changes the contract digest and makes any prior `BehaviorReviewResult` mismatch. The binding ID continues to use the accepted primitive-kind field only. A change to a primitive definition is governed by primitive/version authority rather than by duplicating its body in each contract.

### 2.7 P7-B3 persistence and structural-validation authority

P7-B3 uses the accepted BehaviorContract `1.0.0`, Design IR, DesignDocument identity, and P7-B2 binding-ID formula. It adds no fields to Design IR and does not change B1 or B2. B3 implements only canonical serialization, digesting, and structural/reference validation. It does not resolve primitive definitions or validate primitive semantics.

#### BehaviorDiagnostic

After B3 structural validation, `BehaviorContract.diagnostics` and `BehaviorBinding.diagnostics` contain only `BehaviorDiagnostic` values with exactly these fields:

```text
BehaviorDiagnostic
  code
  severity
  category
  binding_id
  node_id
  evidence_id
  message
  suggested_action
  source_trace
```

Types and closed values:

```text
code             = non-empty safe Unicode string
severity         = trusted closed string: info | warning | error | fatal
category         = trusted closed string: structure | identity | reference | semantic |
                   accessibility | provenance | projection | realization | runtime
binding_id       = BehaviorBinding ID | null
node_id          = DesignNode ID | null
evidence_id      = non-empty safe Unicode opaque evidence identifier | null
message          = safe Unicode string
suggested_action = safe Unicode string | null
source_trace     = LiveFrames.IR.SourceTrace | null
```

Imported strings never become atoms. A contract diagnostic's `binding_id` is null or resolves to one binding in that contract. A binding-owned diagnostic's `binding_id` MUST be null; its containing binding is the canonical association. B3 rejects any non-null binding-owned diagnostic ID, including one equal to its containing binding ID. B3 does not normalize the value during serialization.

```text
BINDING_OWNED_DIAGNOSTIC_BINDING_ID=null
BINDING_DIAGNOSTIC_ASSOCIATION_CANONICAL=CONTAINER_ONLY
BINDING_DIAGNOSTIC_EXPLICIT_BINDING_ID_ALLOWED=NO
```

A non-null diagnostic `node_id` resolves in the exact linked DesignDocument. It may identify a node outside a linked binding's owner subtree. Diagnostic node IDs do not participate in P7-D0 candidate-boundary or P7-D1 approved component-boundary containment. `evidence_id` is an opaque ID that B3 checks only for structural form. B3 performs no provenance lookup: it does not search provenance maps for matching keys or interpret the ID as a path, selector, DesignNode ID, or runtime lookup key. A typed evidence registry or linkage mechanism requires separate authority.

```text
DIAGNOSTIC_NODE_REFERENCE_SCOPE=EXACT_DESIGN_DOCUMENT_ONLY
DIAGNOSTIC_NODE_OWNER_SUBTREE_REQUIRED=NO
DIAGNOSTIC_NODE_IN_D0_D1_BOUNDARY_SET=NO
EVIDENCE_ID_NON_EMPTY_WHEN_PRESENT=YES
B3_EVIDENCE_ID_PROVENANCE_LOOKUP=NO
```

Sort diagnostics by this primary tuple:

```text
(code, severity, category, binding_id-or-empty, node_id-or-empty,
 evidence_id-or-empty, message)
```

When tuples tie, sort by the complete canonical `BehaviorDiagnostic` JCS bytes. Input traversal order is never a tie-breaker.

```text
DIAGNOSTIC_SORT_TIE_BREAK=COMPLETE_JCS_BYTES
```

#### Provenance and SourceTrace

`BehaviorContract.provenance` and `BehaviorBinding.provenance` are string-keyed canonical-value objects. Their recursive value algebra is exactly `null`, boolean, safe integer, safe Unicode string, ordered array, and string-keyed object. Provenance arrays are always ordered sequences. B3 does not infer set semantics from an array. Represent logically unordered evidence as a string-keyed object whose keys are stable evidence IDs.

```text
PROVENANCE_REPRESENTATION=STRING_KEYED_CANONICAL_OBJECT
PROVENANCE_ARRAY_ORDER_ALWAYS_SEMANTIC=YES
PROVENANCE_SET_LIKE_REPRESENTATION=STABLE_KEY_OBJECT
```

Reuse `LiveFrames.IR.SourceTrace`; do not add a Behavior-specific source-trace type. Serialize exactly these fields:

```text
source_type
source_id
source_path
source_name
source_classes
source_settings
adapter
adapter_version
inference
metadata
```

Optional scalar fields serialize as JSON `null`. `source_settings` and `metadata` use canonical-value objects. `source_path` is inert provenance. Do not open it, resolve it, execute it, normalize it against a filesystem, or treat it as runtime input.

`source_classes` is a set-like collection of safe Unicode strings. Reject duplicate values structurally and serialize in ascending string/binary order.

```text
SOURCE_TRACE_REUSED=LiveFrames.IR.SourceTrace
SOURCE_TRACE_CLASS_ORDER=ASCENDING_STRING
SOURCE_TRACE_DUPLICATE_CLASS=REJECT
```

#### BehaviorContract canonical mapping

The canonical top-level mapping contains exactly these fields. It never omits a defined field:

```text
behavior_contract_format_version
design_document_identity
bindings
diagnostics
provenance
```

Defaults are `bindings=[]`, `diagnostics=[]`, and `provenance={}`. Serialize every accepted Binding field:

```text
binding_id
ordinal
primitive_ref
owner_node_id
binding_role
initial_state
primitive_policy_values
triggers
controlled_targets
timer_policy
focus_policy
keyboard_policy
motion_policy
responsive_overrides
diagnostics
provenance
source_trace
```

Serialize the complete `PrimitiveRef` as `kind` and `definition_version`. Primitive definition bodies remain registry-owned and are never serialized. Changing only `definition_version` changes BehaviorContract canonical bytes and digest, while the accepted B2 binding-ID formula remains unchanged.

#### Collection ordering and FocusPolicy

Freeze these orders:

```text
BehaviorContract.bindings   → ascending binding_id
triggers                    → complete canonical Trigger JCS bytes
controlled_targets           → (role, node_id)
responsive_overrides         → mode
diagnostics                  → the ordering above
```

Arrays inside `primitive_policy_values`, generic policy values, and provenance values preserve their stored order unless this authority explicitly assigns another order. No P7-C registry lookup participates in ordering. Every FocusPolicy serialization contains all eight fields below. Optional values encode as JSON `null`:

```text
initial_strategy
initial_target_node_id
containment_strategy
movement_strategy
scope_node_id
restoration_strategy
restoration_target_node_id
restoration_fallback_node_id
```

B3 does not normalize focus scope. B1 remains responsible for the canonical owner-scope representation `scope_node_id=nil`.

#### Serializer API

Freeze this API:

```text
LiveFrames.Behavior.Serializer.algorithm/0
  → "lf-behavior-v1-jcs-sha256"

LiveFrames.Behavior.Serializer.encode/1
  → {:ok, canonical_bytes}
  | {:error, [BehaviorDiagnostic]}

LiveFrames.Behavior.Serializer.digest/1
  → {:ok, lowercase_sha256_hex}
  | {:error, [BehaviorDiagnostic]}
```

`digest/1` hashes exactly the bytes returned by accepted `encode/1`. Use only `LiveFrames.CanonicalJSON` for JCS. B3 has no Catalogue dependency.

```text
SERIALIZER_ALGORITHM=lf-behavior-v1-jcs-sha256
SERIALIZER_API=algorithm/0,encode/1,digest/1
VALIDATION_API=validate_structure/2
FULL_VALIDATE_EXPOSED=NO
P7_C_SEMANTICS_INCLUDED=NO
```

#### Structural validation and DesignDocument linkage

Freeze only this validation API in B3:

```text
LiveFrames.Behavior.Validation.validate_structure(design_document, behavior_contract)
  → :ok
  | {:error, [BehaviorDiagnostic]}
```

Do not expose `validate_semantics/2` or `validate/2`; they remain P7-C APIs. `validate_structure/2` first validates the supplied DesignDocument with existing IR validation, derives its exact `LiveFrames.IR.Identity`, and requires equality with `contract.design_document_identity`.

```text
UNKNOWN_IR_CANONICALIZATION=REJECT
DOCUMENT_IDENTITY_MISMATCH=REJECT
```

Do not use resemblance matching, fallback canonicalization, or a second DesignDocument digest.

Resolve exactly these DesignNode references:

```text
binding.owner_node_id
trigger.origin_node_id                         when non-null
controlled_target.node_id
focus_policy.initial_target_node_id
focus_policy.scope_node_id
focus_policy.restoration_target_node_id
focus_policy.restoration_fallback_node_id
```

Diagnostic references are separately constrained:

```text
diagnostic.node_id                              when non-null
→ resolve in the exact linked DesignDocument only
→ may be outside a linked binding's owner subtree
→ excluded from P7-D0 and P7-D1 boundary containment
```

Generic policy and provenance strings never become DesignNode references. Do not fall back to selectors, classes, or source IDs. Before approved component boundaries, `binding.owner_node_id` is the behavior-owner scope root. Every binding-owned behavior reference listed above resolves to that owner or a descendant in the exact linked DesignDocument. A distinct `focus_policy.scope_node_id` must also lie in that subtree. No narrower-scope field is added.

#### Binding identity and diagnostic integrity

Every persisted binding has `binding_id=bnd_<64 lowercase hex>` and a non-negative integer `ordinal`. To verify identities, make an in-memory copy of the complete binding set, setting only each `binding_id` and `ordinal` to null. Call the accepted P7-B2 `LiveFrames.Behavior.BindingIdentity.assign/1` once on that complete set with the same contract format and DesignDocument identity. Compare every recomputed ID and ordinal with the persisted values. Any mismatch rejects structural validation. Do not recompute bindings individually or change B2.

```text
B3_BINDING_ID_VERIFICATION=FULL_SET_B2_RECOMPUTATION
```

Binding IDs are unique within a contract. Contract diagnostics have null `binding_id` or resolve exactly once. Every binding-owned diagnostic has `binding_id=null`, as required by the container-only association rule above. A diagnostic node ID must resolve in the exact DesignDocument, but does not inherit behavior-owner subtree or D0/D1 boundary containment. A non-null evidence ID must be non-empty safe Unicode. B3 performs no generic provenance lookup for evidence IDs.

#### Digest participation and B3/C boundary

The contract digest includes the format version, DesignDocumentIdentity, all bindings, full PrimitiveRefs, occurrence values, `primitive_policy_values`, all FocusPolicy fields, responsive `authority_ref`, binding diagnostics/provenance/source_trace, contract diagnostics, and contract provenance. B2's identity exclusions do not exclude those fields from the final BehaviorContract digest.

B3 validates the contract format, canonical structural values, DesignDocument identity, assigned binding IDs and ordinals, explicit node references, owner-subtree containment, diagnostic references, and serialization safety. B3 does not validate PrimitiveRef registry membership, primitive-specific state domains or policy vocabulary, FocusPolicy strategy vocabulary, Timer/Keyboard/Motion semantics, responsive mode semantics or authority existence/validity, reversibility, or primitive-specific target cardinality. Those remain P7-C.

#### Performance classification

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

## 3. Design IR boundary and review model

BehaviorContract remains a separate versioned artifact linked to the exact DesignDocumentIdentity. It references normalized `DesignNode.node_id` values and does not mutate the DesignDocument. It may coexist with coarse `LiveFrames.IR.Interaction` evidence without assigning that registry new behavior semantics.

No Design IR migration is required for P7-A1 through P7-L. A future proposal to add a `behaviors` field, reinterpret `interaction_refs`, or point existing interaction refs at BehaviorBinding IDs must be a separate Design IR migration decision with a version and migration plan. P7 does not assume that such a migration is necessary.

BehaviorContract has no mutable approval lifecycle. Validation returns deterministic diagnostics. A trusted review process issues one complete, intrinsically valid `BehaviorReviewResult`. The result is immutable and terminal once issued. A later human decision creates a new result. There is no database-backed current-review state and no mutable `approved`, `rejected`, or `needs_review` status transition.

The persisted `BehaviorReviewResult` has exactly these fields, with no inferred defaults:

```text
review_format_version
design_document_identity
behavior_contract_digest_algorithm
behavior_contract_digest
decision
reviewer_identity
reviewed_at
review_note
evidence_refs
```

Every valid value supplies every field. `review_format_version` is exactly `"1.0.0"`. The result reuses `LiveFrames.IR.Identity` as `design_document_identity`, with exactly `ir_version`, `canonicalization_id`, `digest_algorithm`, and `digest`. B4 checks that structure but does not recompute the DesignDocument identity. The contract digest algorithm is exactly `"lf-behavior-v1-jcs-sha256"`, equal to `LiveFrames.Behavior.Serializer.algorithm()`. Its digest has exactly 64 lowercase hexadecimal SHA-256 characters. The only decisions are the safe strings `approved`, `needs_review`, and `rejected`; imported strings are never converted to atoms.

`reviewer_identity` is a non-empty safe Unicode string supplied by the trusted review process. It is opaque, is not looked up or normalized, and its exact bytes affect the review identity. `review_note` is a safe Unicode string or `null`; an empty string remains distinct from `null`. It is inert content. B4 does not interpret Markdown or HTML.

`reviewed_at` uses exactly `YYYY-MM-DDTHH:MM:SS.ffffffZ`. It must use UTC, a literal trailing `Z`, six fractional digits, and a valid Gregorian date/time. Validation checks both this lexical form and successful UTC `DateTime` parsing. Offset forms, missing or other-width fractions, timezone names, and impossible dates/times fail. B4 does not normalize timestamps and never reads the system clock.

`evidence_refs` is a list of non-empty safe Unicode strings that serve as stable opaque evidence IDs. B4 defines no prefix vocabulary or evidence registry. Duplicate refs fail. Canonical serialization sorts them in ascending string/binary Unicode-scalar order, so input order does not affect identity. B4 never looks them up, searches provenance, opens paths, resolves selectors, interprets them as DesignNode IDs, or infers source ownership.

The canonical JSON object contains every persisted field listed above. `review_note: nil` encodes as JSON `null`; an empty evidence list encodes as `[]`. `LiveFrames.CanonicalJSON` is the only JCS implementation. The persisted struct has no `review_id`, `id`, `digest`, `status`, or `version_counter` field. Identity is derived on demand from the encoded canonical bytes, and the derived ID is never included in its own payload. Downstream artifacts may carry the computed ID.

The identity algorithm is `lf-behavior-review-v1-jcs-sha256`. `id/1` prefixes lowercase SHA-256 of the exact bytes returned by `encode/1` with `brv_`. `encode/1` first runs intrinsic validation, then maps the result to the exact canonical object and sorts only `evidence_refs`. It does not mutate the struct or normalize other fields. `id/1` calls `encode/1` and hashes those returned bytes; it does not rebuild the mapping.

The sole production module is `LiveFrames.Behavior.ReviewResult`, with exactly this public API:

```text
algorithm/0
validate/1
encode/1
id/1
validate_against_contract/2
require_approved/2
```

The contracts are:

```text
algorithm() -> "lf-behavior-review-v1-jcs-sha256"
validate(review_result) -> :ok | {:error, [BehaviorDiagnostic]}
encode(review_result) -> {:ok, canonical_bytes} | {:error, [BehaviorDiagnostic]}
id(review_result) -> {:ok, "brv_" <> lowercase_sha256_hex} | {:error, [BehaviorDiagnostic]}
validate_against_contract(review_result, behavior_contract) -> :ok | {:error, [BehaviorDiagnostic]}
require_approved(review_results, behavior_contract) -> {:ok, BehaviorReviewResult} | {:error, [BehaviorDiagnostic]}
```

`validate/1` checks the exact struct field set, format version, DesignDocumentIdentity shape, contract digest algorithm and syntax, decision, reviewer identity, timestamp, note, and evidence refs. It needs no BehaviorContract and performs no P7-C validation. `encode/1` calls it first. No `latest/1`, `current/1`, `find_approved/1`, `approve!/1`, `mutate/2`, `save/1`, `load/1`, or other bang API is exposed.

`validate_against_contract/2` accepts exactly one result and one BehaviorContract. It calls `validate/1`, recomputes the supplied contract digest through `LiveFrames.Behavior.Serializer.digest/1`, and requires exact equality between the result and contract `design_document_identity`, between the result algorithm and `LiveFrames.Behavior.Serializer.algorithm()`, and between the result digest and the recomputed contract digest. If the serializer cannot digest the supplied contract, B4 returns `behavior.review.contract_digest_mismatch` in category `identity`. It takes no DesignDocument argument and does not call `Behavior.Validation.validate_structure/2`. Consumers that possess a DesignDocument, including later D0/D1, own those checks. B4 recomputes the BehaviorContract digest but does not recompute the DesignDocument identity.

`require_approved/2` accepts a proper list of explicit results and one BehaviorContract. Exactly one result is allowed: an empty list returns `behavior.review.result_missing`; a list with two or more results returns `behavior.review.result_ambiguous`, without sorting or choosing one. An improper list or a singleton that is not a `BehaviorReviewResult` fails intrinsic input validation with `behavior.review.invalid`. For a valid singleton it calls `validate_against_contract/2`, then requires `decision == "approved"`. A non-approved decision returns `behavior.review.not_approved`. It returns that exact result on success. Timestamps never select a result, and approval is never selected from a larger list.

All B4 failures use `LiveFrames.Behavior.Diagnostic`, existing categories, and severity `error`. The complete B4 code set is:

```text
behavior.review.invalid
behavior.review.format_unsupported
behavior.review.document_identity_mismatch
behavior.review.contract_digest_algorithm_mismatch
behavior.review.contract_digest_mismatch
behavior.review.result_missing
behavior.review.result_ambiguous
behavior.review.not_approved
```

Invalid shape/value and unsupported format use category `structure`; document/digest mismatches use `identity`; missing or ambiguous results use `structure`; a non-approved decision uses `semantic`. B4 adds no diagnostic type or category. If a required failure cannot use this set without misclassification, implementation stops with `STOP=B4_DIAGNOSTIC_AUTHORITY_REQUIRED`.

An `approved` decision means only that the human reviewer approved that exact BehaviorContract artifact. It does not mean P7-C semantic validation passed, that the contract is generation-ready, or that a ComponentContract, componentization, generation, or runtime realization is approved. B4 calls none of `PrimitiveRegistry`, `validate_semantics/2`, or `Behavior.Validation.validate/2`. P7-C remains separately unauthorized.

```text
REVIEW_RESULT_MUTABLE_STATUS=NO
REVIEW_RESULT_TERMINAL_STATE=ISSUED
LATER_DECISION_CREATES_NEW_RESULT=YES
BEHAVIOR_REVIEW_RESULT_HAS_REVIEW_ID_FIELD=NO
REVIEW_ID_DERIVATION=ON_DEMAND
REVIEW_ID_INCLUDED_IN_OWN_PAYLOAD=NO
REVIEW_DECISION_VOCABULARY_CLOSED=YES
REVIEW_TIMESTAMP_AUTO_GENERATED=NO
REVIEW_TIMESTAMP_NORMALIZED=NO
B4_EVIDENCE_LOOKUP=NO
B4_RECOMPUTES_BEHAVIOR_CONTRACT_DIGEST=YES
B4_RECOMPUTES_DESIGN_DOCUMENT_IDENTITY=NO
B4_TAKES_DESIGN_DOCUMENT=NO
LATEST_REVIEW_SELECTION=NO
TIMESTAMP_AUTHORITY_SELECTION=NO
MULTIPLE_REVIEW_RESULTS=REJECT
ZERO_REVIEW_RESULTS=REJECT
P7_C_SEMANTICS_INCLUDED=NO
```

B4 treats all review strings as inert data. It never converts untrusted strings to atoms, looks up reviewer or evidence identities, executes source paths, or performs arbitrary module lookup. Its classification is `DATA_LAYER=COLD_COMPILE_REVIEW_TIME`; ETS, Cachex, Redis, Postgres, PgBouncer, read replicas, GenServer, PubSub, Oban, TTL, and database indexes are `N/A`. Runtime database and network calls are zero; server polling is disabled. No infrastructure is introduced.

Future B4 tests freeze one fully populated result fixture, literal canonical JSON bytes, and a `brv_` ID independently computed from those bytes. They prove that evidence input order does not affect bytes or ID; changes to decision, reviewer, timestamp, or evidence set do; `null` and empty note differ; and duplicate evidence rejects. Timestamp tests reject missing, three-digit, or seven-or-more-digit fractions, `+00:00`, and impossible dates/times. Matching tests cover an exact contract, a changed contract digest, a changed DesignDocumentIdentity, and a wrong digest algorithm. Gate tests cover zero, singleton approved, `needs_review`, `rejected`, two-result rejection regardless of approval/timestamp ordering, and prove that a newer timestamp never selects a result. Lifecycle tests prove decisions are immutable and later decisions use new results. These are future B4 requirements, not implementation work in this amendment.

Future B4 implementation is limited to `apps/live_frames/lib/live_frames/behavior/review_result.ex` and `apps/live_frames/test/live_frames/behavior/review_result_test.exs`. Do not modify B3 serializer or validation. If another file is required, stop with `STOP=UNEXPECTED_CHANGED_FILE_REQUIRED`.
## 4. Domain and resource map

Every reference is typed, document-local or contract-local, and validated by its owning layer. These are planning boundaries, not implementation structs.

| Concept | Owner and cardinality | Identity and allowed references | Validation owner | Serialization or persistence | Downstream consumer |
| --- | --- | --- | --- | --- | --- |
| `BehaviorContract` | One conversion result per exact DesignDocument; zero or more bindings and diagnostics | Format version plus one `DesignDocumentIdentity`; owns binding IDs and diagnostic/evidence references | P7-B3 `validate_structure/2` validates identity, shape, values, and references. P7-C adds `validate_semantics/2`; `validate/2` composes both only after P7-C. | Persisted compile-time artifact; explicit `Behavior.Serializer` mapping and digest | BehaviorReviewResult, pre-proposer decision, and BehaviorProjection |
| `DesignDocumentIdentity` | `LiveFrames.IR.Identity`; one per validated DesignDocument | `(ir_version, canonicalization_id, digest_algorithm, digest)`; no document resemblance matching | IR identity code validates current supported version and exact byte digest | Serializable value inside BehaviorContract and matching review/projection evidence | Componentization matching and stale-document rejection |
| `BehaviorBinding` | One occurrence in a BehaviorContract; exactly one `PrimitiveRef` and owner node | P7-B1 typed occurrence fields; P7-B2 structured `BehaviorBindingID`; owns one exact `PrimitiveRef`, owner node, binding role, initial-state assignment, primitive-specific policy values, trigger occurrences, controlled targets, cross-cutting binding policies, diagnostics/evidence/provenance; never owns a state model or transition definitions | P7-B1 validates structure only. P7-B3 checks structure, references, and IDs. P7-C resolves the exact primitive reference and validates occurrence values. P7-D0 checks candidate-boundary admissibility; P7-D1 checks the approved boundary. | Persisted as part of BehaviorContract, without a copy of primitive-definition semantics | Review, componentization decision, BehaviorProjection, and runtime realization selection |
| `PrimitiveRef` | One exact trusted primitive definition reference owned by one BehaviorBinding | `kind` and `definition_version`, both closed trusted strings; the exact pair selects one definition | P7-B1 validates closed fields; P7-C resolves the exact pair and rejects unknown pairs without fallback | Full value is serialized in BehaviorContract and participates in its digest; not the registry body | Semantic validation and runtime realization selection |
| `BehaviorPrimitiveDefinition` | Closed, versioned trusted registry; one definition per implemented primitive kind/version | Exact registry lookup by `(kind, definition_version)` from `PrimitiveRef`; owns its `BehaviorStateModel`, state dimensions/domains, default initialization, invariants, cardinality, accessibility contract, and permitted primitive-policy keys, value domains, defaults, and invariants; unknown pairs return unsupported | P7-C registry API and the implementing tracer's definition tests | Trusted compile-time code/configuration; BehaviorContract serializes only the primitive reference | State and primitive-policy validation, accessibility policy, realization selector |
| `primitive_policy_values` field | One selected value map owned by one BehaviorBinding occurrence; defaults to `{}` | String-keyed safe canonical-value object; no DesignNode references; exact primitive definition owns permitted policy keys, value types/shapes, domains, defaults, and invariants; arrays mean ordered sequences; where a policy is defined as unordered/set-like, its permitted shape should be a stable-key object; distinct from `initial_state` and shared cross-cutting policy fields; not a separate runtime object | P7-B1 checks canonical structure only; P7-B2 identities that structure and preserves array order; P7-B3 serializes stored order; P7-C validates exact-definition semantics and shape without reinterpreting or reordering arrays | Included in the occurrence discriminator, canonical BehaviorContract bytes, and contract digest; never includes primitive-definition bodies | Semantic validation and runtime realization selection |
| `Trigger` | Owned by one binding; zero or more typed trigger records | Closed trigger kind and optional typed origin node in owner scope | Behavior validator and primitive definition | Persisted semantic value; no arbitrary browser event string | Runtime realization selector |
| `ControlledTarget` | Owned by one binding; zero or more targets with primitive-specific required roles/cardinality | Exact DesignNode ID and closed target role, inside declared owner subtree | Behavior validator, then P7-D0 candidate and P7-D1 approved-boundary checks | Persisted semantic value; no selector fallback | HEEx relationships and realization |
| `OccurrenceInitialStateAssignment` | Optional value owned by one BehaviorBinding occurrence | Assigns values only to dimensions and values declared by its exact `PrimitiveRef` definition; introduces no dimensions, domains, invariants, transitions, guards, or effects; not mutable runtime state | P7-C resolves the exact definition, applies defaults for omitted dimensions, and validates the complete state against its domains and invariants | Serialized as binding-owned occurrence data; absent means use the referenced definition's accepted/default initialization | Resolved initial-state input for that occurrence |
| `BehaviorStateModel` | Owned by one primitive definition; one or more finite state dimensions | Dimension names/domains, default initial values, invariants, transitions, and terminal rules/states from primitive vocabulary | Primitive definition plus Behavior validator | Trusted compile-time definition; not serialized as a second copy in BehaviorContract | Transition validation and runtime realization |
| `Transition` | Owned by one state model; zero or more named definitions | Stable transition name, source predicate, trigger, destination dimensions, guards, effects, and applicable accessibility effects | Primitive definition and Behavior validator check domains, invariants, and atomicity | Trusted compile-time definition; not serialized in BehaviorContract | Runtime realization and browser assertions |
| `TransitionGuard` | Owned by one transition; zero or more pure definitions | Closed guard kind with typed state/policy/context operands | Primitive definition and Behavior validator | Trusted compile-time definition; no I/O or executable expression; not serialized in BehaviorContract | Runtime realization selector/interpreter |
| `BehaviorEffect` | Owned by one transition; zero or more definitions | Closed semantic effect kind and typed target/operand references | Primitive definition and Behavior validator | Trusted compile-time definition; no arbitrary DOM mutation recipe; not serialized in BehaviorContract | Runtime realization |
| `AccessibilityEffect` | Owned by a transition/effect; zero or more synchronized definitions | Semantic state, ARIA/native state, focus and relationships for exact controls/targets | Primitive definition and Behavior validator plus accessibility tests/review | Trusted compile-time definition; not serialized in BehaviorContract | Markup and runtime realization; browser/AT verification |
| `TimerPolicy` | Owned by a binding; zero or one policy unless the primitive defines named timers | Closed purpose, integer duration, eligibility, stop/restart rules and reduced-motion response | Primitive definition and Behavior validator | Persisted policy only; timer handle is ephemeral | Runtime timer owner for opted-in timed behavior |
| `FocusPolicy` | Owned by a binding; zero or one policy | Exact fields: `initial_strategy`, `initial_target_node_id`, `containment_strategy`, `movement_strategy`, `scope_node_id`, `restoration_strategy`, `restoration_target_node_id`, and `restoration_fallback_node_id`. Strategies are inert strings or null. The four node references are each optional single DesignNode IDs. A null `scope_node_id` means `owner_node_id`; an explicit scope equal to the owner is noncanonical and rejected by B1; roving members remain in `controlled_targets`; runtime invoker identity is not serialized. | B1 checks structure and the canonical scope form; B3 resolves all four references; P7-C validates strategy vocabulary/combinations; D0 and D1 enumerate all four references for boundary containment. | Persisted typed policy; no selector fallback or runtime invoker ID | Runtime realization and accessibility checks |
| `KeyboardPolicy` | Owned by a binding; zero or one policy per keyboard interaction model | Closed key/modifier vocabulary and transition/focus mapping | Primitive definition and Behavior validator | Persisted policy | Native semantics or client runtime |
| `MotionPolicy` | Owned by a binding; zero or one policy | Closed animation/autoplay/reduced-motion behavior; time changes semantic state only when explicitly stated | Primitive definition and Behavior validator | Persisted policy | CSS/runtime selector and browser verification |
| `ResponsiveBehaviorOverride` | Owned by a binding; zero or more named mode mappings | Stable semantic `authority_ref`, source-independent mode, and reversible state map; evidence citations remain in provenance/source trace | P7-C and responsive authority resolver validate semantic authority and mapping | Persisted semantic mapping, not style override; `authority_ref` participates in B2 identity and the contract digest | Projection and runtime mode reconciliation |
| `BehaviorDiagnostic` | Owned by a contract; may link one binding, node, or stable evidence record; zero or more | Stable code, severity, category, typed IDs, message, action and provenance evidence | Behavior validator/normalizer; reviewer resolves meaning | Persisted within contract and included in its digest | Review gate; unsupported bindings fail closed |
| `RuntimeInstance` | Runtime owner creates zero or more per binding and repeated item | `(binding_id, approved component instance scope, stable caller item key)`; DOM nodes/handles are references only at runtime | Runtime lifecycle manager | Ephemeral browser state; never serialized or persisted across page lifetime unless primitive semantics explicitly require it | RuntimeRealization and lifecycle cleanup |
| `BehaviorReviewResult` | Each human decision creates one immutable terminal `issued` artifact; consumers pass exactly one explicit result to a gate | `LiveFrames.Behavior.ReviewResult.id/1` derives `brv_` from all nine exact persisted fields; no ID field is stored | P7-B4 exposes `algorithm/0`, `validate/1`, `encode/1`, `id/1`, `validate_against_contract/2`, and `require_approved/2`; exact contract matching uses `Behavior.Serializer.digest/1`; zero or multiple results reject | Persisted compile-time review evidence; no mutable status or current-review state | P7-D0 and P7-D1 gates; never substitutes for ComponentReview or P7-C |
| `BehaviorComponentizationDecision` | One ephemeral gate result per exact DesignDocument, contract, review, and candidate semantic input | Exact input identities and candidate boundary plus ordered binding-containment outcomes; no independent ID | P7-D0 validates review/contract/document equality, existing SemanticInput validity, and full binding containment before proposer invocation | Ephemeral compile-time value; no serialization or persistence | Gates the existing ComponentizationProposer for the interactive path |
| `BehaviorProjection` | Projection operation returns one artifact per exact five-input tuple; zero or more projected bindings | `bpr_` identity over exact projection payload, including review result and plan fingerprint | P7-D1 projection structural/reference validator plus full BehaviorContract validation and C09D6 checks | Persisted compile-time sidecar artifact; deterministic JCS serializer/digest | Interactive generator prerequisites and RuntimeRealization |
| `RuntimeRealization` | Compile-time selector returns one plan per projected binding or an explicit unsupported result | Binding ID, exact BehaviorProjection ID, trusted realization kind/version; references semantic policy only | Selector validates only after full semantic validation and projection. Runtime validators are primitive-specific. | Compile-time artifact; executable functions/handles are runtime-only and not serialized | HEEx/CSS/JS/hook/server output and browser verification |

`RuntimeInstance` exists only when an accepted primitive requires managed browser resources. A native-only Disclosure has `RUNTIME_INSTANCE_REQUIRED=NO`. When managed state is required, there is one instance per mounted binding scope, multiplied only by stable repeated-item keys when the approved component renders a repeated behavior. An array position is not a durable item identity. If a reorderable collection has no stable key, state preservation across reorder is unsupported and receives a diagnostic.

## 5. Behavior vocabulary and state validation

The implementation registry is closed and owned by trusted LiveFrames code. Source input cannot add primitive definitions, states, triggers, keys, effects, guards, policies, or realization kinds. A source string outside the registry produces an unsupported diagnostic and no runtime action.

P7-C implements the trusted registry mechanism, common closed vocabularies, and the semantic validation composition API. It does not implement every primitive definition. P7-F through P7-K add one primitive family at a time with its state/cardinality/accessibility definition and tests. An unimplemented registered kind remains unsupported and cannot pass semantic validation. No source adapter or runtime realization is added by P7-C.

Each primitive definition owns its allowed state dimensions, finite domains, default initial values, invariants, transition definitions, target cardinalities, accessibility contract, permitted policy shapes, and cleanup requirements. A binding carries only permitted occurrence policy values, which the registry validates. Validation rejects unknown dimensions, invalid combinations, missing required targets, illegal transitions, and unsupported policy values. It does not guess a nearest valid state. The runtime can emit only a transition that preserves the primitive invariant and its accessibility state in the same semantic outcome.

### 5.1 Primitive-definition and occurrence-state ownership

The primitive definition is the sole owner of the state-machine definition:

```text
BehaviorPrimitiveDefinition
  → BehaviorStateModel
      → Transition
          → TransitionGuard / BehaviorEffect
              → AccessibilityEffect
```

A `BehaviorBinding` represents one occurrence. It owns exactly one typed `PrimitiveRef` and owns only occurrence-specific triggers, controlled targets, permitted binding policies, and accepted occurrence values. It does not own or serialize a second state model, transition definitions, guards, or effects. P7-C resolves the exact `(kind, definition_version)` pair and validates occurrence values against that trusted definition. The kind and version are closed trusted strings; untrusted input never becomes an atom. An unknown pair is unsupported, with no latest-version or kind-only fallback.

```text
PrimitiveRef
  kind
  definition_version

BehaviorBinding.primitive_ref = {
  "kind": "<closed trusted primitive kind>",
  "definition_version": "<closed trusted definition version>"
}

PRIMITIVE_REF_KIND=CLOSED_TRUSTED_STRING
PRIMITIVE_REF_DEFINITION_VERSION=CLOSED_TRUSTED_STRING
PRIMITIVE_REF_SERIALIZED=YES
PRIMITIVE_REF_IN_CONTRACT_DIGEST=YES
PRIMITIVE_DEFINITION_BODY_SERIALIZED=NO
UNKNOWN_KIND_VERSION_PAIR=UNSUPPORTED
KIND_ONLY_FALLBACK=PROHIBITED
LATEST_VERSION_FALLBACK=PROHIBITED
UNTRUSTED_STRING_TO_ATOM=PROHIBITED
```

`docs/09_INTERACTION_MODEL.md` §9.1 requires normalization to use an explicit accepted initial state when one exists and otherwise use the Disclosure default `closed`. The occurrence-specific value is represented as an optional typed `initial_state` assignment on `BehaviorBinding`, separate from the primitive definition's state model and its default initialization. The assignment contains only dimension/value pairs whose dimensions and values already exist in that definition. It cannot add dimensions, change domains or invariants, or define transitions, guards, or effects. If absent, every dimension uses the definition's accepted/default initialization. P7-C validates the assigned dimensions and values, resolves unspecified dimensions from the definition, and validates the combined initial state against all declared invariants before full Behavior validation succeeds. This value is an initialization input, not live runtime state.

```text
PRIMITIVE_STATE_MODEL_OWNER=BehaviorPrimitiveDefinition
TRANSITION_OWNER=BehaviorStateModel
BINDING_OWNS_STATE_MODEL=NO
BINDING_OWNS_TRANSITION_DEFINITIONS=NO
BINDING_OWNS_TRANSITIONS=NO
BINDING_OWNS_GUARD_DEFINITIONS=NO
BINDING_OWNS_EFFECT_DEFINITIONS=NO
BINDING_OWNS_GUARDS=NO
BINDING_OWNS_EFFECTS=NO

BINDING_OWNS_TRIGGER_OCCURRENCES=YES
BINDING_OWNS_CONTROLLED_TARGET_OCCURRENCES=YES
BINDING_OWNS_BINDING_POLICIES=YES

PRIMITIVE_DEFINITION_BODY_SERIALIZED_IN_BEHAVIOR_CONTRACT=NO
FULL_PRIMITIVE_REF_SERIALIZED_IN_BEHAVIOR_CONTRACT=YES
PRIMITIVE_REF_PARTICIPATES_IN_CONTRACT_DIGEST=YES
BINDING_ID_FORMULA_CHANGED=NO
BINDING_ID_INCLUDES_DEFINITION_VERSION=NO
BINDING_ID_DEPENDS_ON_PRIMITIVE_DEFINITION_BODY=NO
OCCURRENCE_INITIAL_STATE_REPRESENTATION=OPTIONAL_ASSIGNMENT_THEN_RESOLVED
INITIAL_STATE_VALIDATION_OWNER=P7-C
INITIAL_STATE_CAN_ADD_DIMENSION=NO
INITIAL_STATE_CAN_EXTEND_DOMAIN=NO
INITIAL_STATE_CAN_EXTEND_DOMAINS=NO
INITIAL_STATE_CAN_DEFINE_INVARIANT=NO
INITIAL_STATE_CAN_DEFINE_TRANSITION=NO
INITIAL_STATE_CAN_DEFINE_GUARD_EFFECT=NO
INITIAL_STATE_IS_RUNTIME_STATE=NO
```

Required accessibility gates follow the accepted primitive semantics in `docs/09`:

- Disclosure uses native disclosure semantics where they match; links stay usable and expanded state matches content visibility.
- Tabs keep `focused_tab_id` separate from `selected_tab_id`, define automatic or manual activation, map the selected keyboard model, and synchronize tab/panel relationships.
- Accordion defines `single | multiple`, closure rules, heading/button relationships, and any responsive mapping as a reversible state transformation.
- Website disclosure navigation remains separate from ARIA composite menu keyboard/focus semantics.
- Dialog implements actual modality, top-modal Escape handling, initial focus, containment, focus return, nested ownership, background inertness, and scroll-lock cleanup. `aria-modal` alone is insufficient.
- Carousel keeps selected slide, rotation state, focus/hover suspension, controls, and reduced-motion behavior as orthogonal state dimensions. Autoplay is opt-in and must stop on focus/hover according to the accepted policy.
- Lightbox composes the Dialog contract with typed gallery navigation and media accessibility.

Each runtime slice proves only the keyboard and screen-reader state synchronization, reduced-motion, and browser behavior required by its accepted primitive authority. A native-only Disclosure test does not inherit unresolved Slide Menu-specific accessibility or style claims. Pure data validators and serializers do not require browser tests.

## 6. Componentization integration decisions

### 6.1 Pre-proposer BehaviorComponentizationDecision

`BehaviorComponentizationDecision` is the pre-proposer admissibility gate required by `docs/09_INTERACTION_MODEL.md`. Its exact input is:

```text
DesignDocument
+ BehaviorContract
+ one approved BehaviorReviewResult
+ explicit ComponentizationSemanticInput
→ BehaviorComponentizationDecision
```

The decision validates that the contract and review result match the exact DesignDocumentIdentity and BehaviorContract digest. It validates the existing `ComponentizationSemanticInput` against that DesignDocument using the existing C09D5 input rules, then checks the canonical candidate boundary from its `BoundaryDecision`. The first-wave proposer supports one boundary node; multi-root remains unsupported under C09D5 and must not be inferred here.

An admissible result requires `Behavior.Validation.validate_structure/2` success and one explicit approved review result matching the exact document and contract. P7-D0 uses structural node references to assess boundary containment; it does not claim that an unimplemented primitive is semantically supported. Full P7-C-composed `validate/2` remains mandatory before BehaviorProjection and realization.

For each binding relevant to that candidate (at least one binding-owned DesignNode reference lies in its subtree), the gate resolves every concrete binding-owned node reference: `owner_node_id`, trigger origin node IDs, controlled target node IDs, `focus_policy.initial_target_node_id`, `focus_policy.scope_node_id`, `focus_policy.restoration_target_node_id`, `focus_policy.restoration_fallback_node_id`, and any other separately authorized explicit occurrence-level node-reference fields. These four FocusPolicy references are the complete FocusPolicy reference set. All references contained means `contained`; all references outside the candidate means `outside_candidate`; references on both sides mean `split` and reject; any unresolved reference means `unresolved` and reject. Primitive transition/effect definitions belong to the trusted registry and are not binding references checked by D0. No source class, DOM proximity, source/vendor ID, selector, or wrapper depth determines relevance or ownership. `BEHAVIOR_SPLIT_ACROSS_PROPOSED_BOUNDARIES=REJECT`.

```text
P7_D0_TRANSITION_EFFECT_REFERENCE_REMOVED=YES
P7_D0_BINDING_NODE_REFERENCE_RULE=ALL_CONCRETE_OCCURRENCE_OWNED_DESIGN_NODE_REFS
P7_D0_FOCUS_POLICY_REFERENCE_SET_EXPLICIT=YES
```

The decision outcome is the closed compile-time value `admissible | rejected`; each binding disposition is `contained | outside_candidate | split | unresolved`. The decision is an **ephemeral compile-time validator result**, not a persisted artifact. It has no serializer, digest, database record, timestamp selection, or independent approval state. During the gated call it holds the exact DesignDocumentIdentity, BehaviorContract digest, BehaviorReviewResult ID, canonical ComponentizationSemanticInput value, proposed boundary node ID, and per-binding containment dispositions sorted by `binding_id`; diagnostics use their existing deterministic ordering. The gate returns a blocking diagnostic and does not call the proposer if it cannot establish safe containment; report `STOP=BEHAVIOR_AWARE_BOUNDARY_UNRESOLVED`. This result need not survive ComponentReview: P7-D1 independently repeats ownership validation against the exact approved tuple, so the decision is not an identity input or a substitute for that later proof.

On an admissible result, the behavior-aware gate immediately calls the existing `ComponentizationProposer.propose/2` with the same validated DesignDocument and canonical ComponentizationSemanticInput checked by the decision. It never mutates BehaviorContract, and it does not replace, mutate, or extend the semantic input, change the proposer API or output schemas, select a boundary, approve a component, or generate code. It only constrains whether the existing proposer may be called for this interactive path. Ordinary static componentization remains on its existing path.

The resulting proposed ComponentContract and ComponentizationPlan still require the existing explicit ComponentReview and generation prerequisites. The pre-proposer decision is not stored as component approval and does not substitute for ComponentReview. ComponentContract 1.0.0, ComponentizationPlan 1.0.0, and Design IR 3.x remain unchanged.

### 6.2 Post-review BehaviorProjection

P7-D1 uses **Option A, a separate `BehaviorProjection` sidecar artifact**. It is the post-ComponentReview verification against the actual approved tuple, distinct from the pre-proposer admissibility decision. Its canonical five-input signature is:

```text
DesignDocument
+ BehaviorContract
+ approved BehaviorReviewResult
+ approved ComponentContract
+ matching ComponentizationPlan
→ BehaviorProjection
```

Projection requires exactly one explicit approved BehaviorReviewResult. It validates `decision == approved`, exact DesignDocumentIdentity equality, exact BehaviorContract digest algorithm/value equality, and review-result identity. It never selects a review by timestamp or storage order.

The projection records the exact DesignDocumentIdentity, BehaviorContract digest algorithm/value, BehaviorReviewResult algorithm/ID, `ComponentContract.contract_id`, and a `componentization_plan_sha256` computed as lowercase SHA-256 over the exact `plan_bytes` returned by `ComponentizationPlan.encode(plan)` after plan validation. This is the same serialized-plan algorithm used by `LiveFrames.NativeGenerator`; identify it as `lf-componentization-plan-serializer-v1-sha256`. It also records the approved component boundary and deterministically ordered binding-to-boundary mappings.

BehaviorProjection uses format version `1.0.0`. Its explicit JCS identity payload contains `projection_format_version`, DesignDocumentIdentity, BehaviorContract digest algorithm/value, BehaviorReviewResult algorithm/ID, `ComponentContract.contract_id`, ComponentizationPlan fingerprint algorithm/value, boundary identity (`design_document_sha256`, `contract_id`, and `boundary_node_id`), deterministically ordered `{binding_id, boundary_node_id}` mappings, and projection diagnostics. Ownership mappings sort by `binding_id`. Projection diagnostics serialize as their explicit typed maps and sort by their complete JCS bytes. Do not include `projection_id` in its own payload. The projection ID is `bpr_` plus lowercase SHA-256 of those JCS bytes, algorithm `lf-behavior-projection-v1-jcs-sha256`. `RuntimeRealization` refers to this exact projection ID. P7-D1 must add golden projection bytes/ID tests and rejection tests for altered review, plan, boundary, mapping, or diagnostics.

The projection does not copy or reinterpret BehaviorContract state semantics and does not change the public component API. The first implementation permits one binding to be projected wholly within one approved component boundary only. A binding whose owner, trigger origin, controlled target, or non-null FocusPolicy reference escapes the boundary, or whose behavior spans multiple component boundaries, fails closed with a stable diagnostic. D1 enumerates `focus_policy.initial_target_node_id`, `focus_policy.scope_node_id`, `focus_policy.restoration_target_node_id`, and `focus_policy.restoration_fallback_node_id` explicitly. A future cross-boundary capability requires a new typed authority and explicit authorization.

Option A keeps C09D1 `ComponentContract 1.0.0` and C09D3 `ComponentizationPlan 1.0.0` schemas and the accepted static C09D6 path unchanged. Option B would put behavior ownership into placement authority, require ComponentizationPlan format evolution or a tightly constrained optional extension, introduce reader/migration questions, and couple state semantics to a plan whose current purpose is static public-input placement. It would risk making existing static generation depend on behavior data it does not need. Neither schema needs a version change to implement the sidecar.

Projection validation requires all of the following:

1. The BehaviorContract identity matches the exact supplied DesignDocumentIdentity.
2. The ComponentContract and ComponentizationPlan validate under their existing authorities; the plan references that exact contract and existing DesignDocument digest.
3. The ComponentContract is explicitly approved. Behavior review cannot set or imply its approval status.
4. The same shared C09D6 generation prerequisites pass, excluding only final code emission.
5. Every binding owner, controlled target, trigger origin, and each non-null FocusPolicy node reference resolves in the exact DesignDocument and lies wholly within one approved component boundary.
6. Every projected binding maps exactly once. Unprojected required behavior, ambiguous ownership, escaped targets, or cross-boundary behavior blocks interactive generation.
7. The projection carries immutable hashes/IDs for all exact inputs. The DesignDocument, BehaviorContract, BehaviorReviewResult, and plan are checked by exact identity/digest. The component contract is checked by its existing `contract_id`, approval result, intrinsic/reference validation, and shared C09D6 prerequisites; P7 does not invent a competing ComponentContract fingerprint.

DOM proximity, shared classes, matching source IDs, naming similarity, and component-instance DOM layout never prove ownership. The pre-proposer decision checks admissibility of the human candidate boundary; `BehaviorProjection` later proves exact ownership against the actual approved ComponentContract and plan. Projection does not change `ComponentContract.approval_status`, mutate the plan, or authorize generation by itself.

## 7. Runtime realization and lifecycle ownership

BehaviorContract expresses semantics, not source JavaScript or executable runtime recipes. RuntimeRealization maps a validated projected binding to the least complex platform mechanism that satisfies its semantics, in this order:

1. semantic HTML and CSS;
2. `Phoenix.LiveView.JS`;
3. component-colocated JavaScript;
4. component-colocated hook;
5. shared/global hook;
6. server event;
7. stateful `Phoenix.LiveComponent`.

The compile-time selector must explain why lower-cost options cannot satisfy the contract before choosing a more stateful option. Presentation-only transitions have no server round trip. Hooks are used only for browser lifecycle, DOM reconciliation, or platform behavior that native elements and LiveView.JS cannot express. There is no generic event bus, browser-local polling, general `phx-update="ignore"` state retention, or forced-hook implementation for every primitive. P7-E implements only compile-time realization selection and result validation. It does not add a generic browser runtime, hook registry, resource manager, or RuntimeInstance framework. Each primitive issue adds the smallest browser code and cleanup it proves necessary.

### 7.1 Runtime lifecycle

The shared runtime lifecycle is fixed:

```text
no instance
  → mounted
  → active

mounted | active
  → unavailable

unavailable
  → active

mounted | active | unavailable
  → destroyed
```

Rules:

- `destroyed` is terminal and occurs only when the actual owner is removed.
- Ordinary LiveView `updated` is post-patch reconciliation, never destruction.
- `unavailable` is recoverable; entering it releases unsafe resources but retains identity needed for a later valid reconciliation.
- Mount and post-patch reconciliation are idempotent. Each listener, timer, observer, focus owner, and shared resource is acquired at most once per owner.
- Disconnect suspends or releases resources according to the primitive policy without destroying the still-mounted owner. Reconnect revalidates targets and reacquires only resources that are still required.
- A removed owner destroys its instance and releases all resources, including timers, observers, listeners, pointer capture, focus ownership, media control, and scroll-lock ownership.
- Shared resources such as nested-dialog scroll locks use scoped tokens or reference counts. Destroying one instance cannot release a resource owned by another active instance.
- Stale DOM references are discarded on reconciliation. Focus restoration uses a still-connected typed target or the documented safe fallback; a missing target never triggers selector search.
- A transition interrupted by owner removal emits no later timer or observer work.

The pinned LiveView 1.2.11 hook callbacks (`mounted`, `beforeUpdate`, `updated`, `destroyed`, `disconnected`, and `reconnected`) are the available hook lifecycle contract. A primitive may use a callback only when that primitive demonstrates a need for a managed runtime. `updated` never means destroyed. No callback other than actual owner removal may mark a RuntimeInstance destroyed. P7-G is the earliest planned slice that may introduce a narrow managed runtime, and only if Tabs cannot meet its accepted patch and cleanup requirements with native behavior or LiveView.JS.

## 8. Security and failure handling

Imported JSON, source exports, CSS, JavaScript, PHP, paths, selectors, event names, and module-like strings are untrusted data. The parser and normalizer inspect data only. They never execute or evaluate source scripts, compile source code, import source modules, execute PHP, or follow source-provided paths.

All behavior kinds and runtime capabilities use closed trusted vocabularies. Source-provided arbitrary event names, selectors, key names, module names, effects, or runtime strategy strings are rejected or retained only as inert diagnostic provenance. No untrusted string is converted into an atom, module, executable function, shell argument, or file path. Source HTML is not treated as executable behavior. A source runtime package is not a target dependency merely because the source used it.

The following conditions have deterministic fail-closed outcomes:

| Failure | Required result |
| --- | --- |
| Stale DesignDocument digest or unsupported Design IR version | Reject contract/projection; do not bind to a similar document. |
| Unknown canonicalization or digest algorithm | Reject identity use; no fallback hashing. |
| Missing, multiple, stale, or non-approved BehaviorReviewResult | Reject projection. The caller must pass exactly one approved result matching the exact DesignDocumentIdentity and BehaviorContract digest; do not select by timestamp. |
| Duplicate BehaviorBinding payload/ID | Reject conflicting bindings and emit a stable collision diagnostic. |
| Unresolved owner/target node or target outside declared owner subtree | Disable/reject the binding; never use selector fallback. |
| Binding owner/target escapes or crosses approved component boundary | Reject projection and interactive generation. |
| BehaviorComponentizationDecision finds a binding split across or unsupported by the proposed component boundary | Reject before calling ComponentizationProposer; report `STOP=BEHAVIOR_AWARE_BOUNDARY_UNRESOLVED`. |
| Repeated collection reorder without stable caller key | Diagnose unsupported state preservation; do not use index as durable identity. |
| Invalid state combination or transition violating an invariant | Reject transition and emit no effects. |
| Unsupported primitive, arbitrary event, key, effect, selector, module, or realization | Keep inert evidence and diagnostic; emit no executable behavior. |
| Duplicate hook/listener registration after patch or reconnect | Idempotency invariant failure; release duplicate and fail the runtime test gate. |
| Duplicate timers/observers, stale DOM references, or timer running after destruction | Release resource and fail lifecycle verification; no late transition may occur. |
| Owner removed during a transition | Destroy its runtime instance and cancel queued work before effects apply. |
| Focus target removed mid-transition | Apply the primitive's documented safe fallback or leave transition incomplete with a diagnostic; never focus an unrelated node. |
| Multiple dialogs competing for scroll lock | Maintain scoped ownership/reference count; releasing one dialog leaves the other lock active. |
| Reduced-motion preference changes | Reconcile motion and timer policy immediately; do not keep prohibited autoplay running. |
| Responsive mode changes while active | Apply only a validated reversible state map; otherwise keep safe current semantics and diagnose the unsupported mapping. |
| Slide Menu current-page behavior lacks an accepted identity input or timing/lifecycle rule | Do not implement current-page opening. Keep the supported `closed | open` disclosure core only; do not infer initial render versus later update. |
| Slide Menu target motion lacks accepted style authority | Do not map exact transition duration, easing, or interpolation. Reduced-motion evidence may inform MotionPolicy, but target style values remain blocked. |
| Source runtime dependency appears in target dependency graph | Reject the change unless a separate explicit project authority approves it. |
| Component approval is bypassed or BehaviorReview is used as ComponentReview | Block generation using existing C09D6 prerequisites. |

Behavior diagnostics cannot be silently dropped when behavior is omitted. Blocking diagnostics prevent review approval or projection as defined by their stable category and severity. Human review may resolve ambiguous semantics with explicit evidence; it cannot turn unsafe executable input into an accepted runtime instruction.

## 9. Performance and storage classification

P7 behavior state is browser-local unless an accepted semantic contract proves that the server owns the state or command. Classification for P7-A1 through P7-L and the B3 authority boundary:

```text
DATA_LAYER=COLD_COMPILE_REVIEW_TIME
ETS=N/A
CACHEX=N/A
REDIS=N/A
POSTGRES=N/A
PGBouncer=N/A
READ_REPLICA=N/A
PUBSUB=N/A
GENSERVER=N/A
OBAN=N/A
TTL=N/A
DB_INDEX=N/A
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
SERVER_POLLING=NO for browser-local presentation behavior
BROWSER_LOCAL_PRESENTATION=NO_POLLING_NO_PER_TOGGLE_BACKEND_CALLS
DISCLOSURE_DB_CALLS_PER_TOGGLE=0
DISCLOSURE_NETWORK_CALLS_PER_TOGGLE=0
DB_CALLS_PER_TOGGLE=0
NETWORK_CALLS_PER_TOGGLE=0
```

Browser-local performance goals are O(instances) bounded state, no server trip for presentation-only transitions, no polling, one listener/timer/observer ownership path, idempotent patch reconciliation, complete cleanup, and owner/target-scoped DOM work rather than repeated whole-document scans. Large collections may use typed owner-scoped lookup and stable item keys; they may not trigger document-wide observer scans per item.

Backend scaling becomes relevant only when a future behavior contract explicitly requires shared or durable state, server-authoritative decisions, cross-client synchronization, authorization checks, or a business command. That future issue must separately classify database/cache/index/queue/pubsub needs from the presentation runtime. Redis, Cachex, GenServer, PubSub, or a database are not added to solve ephemeral disclosure, tabs, accordion, dialog, or carousel state.

## 10. Test and review strategy

Every implementation issue follows TDD: add a focused failing test, confirm the failure, implement the smallest slice, run focused checks, then run applicable repository gates. This P7-0 planning change adds no tests and runs no broad Mix or browser suite.

| Slice | Required focused evidence |
| --- | --- |
| P7-A1 | Existing DesignDocument SHA-256 values remain byte-for-byte equal; known and unknown canonicalization IDs; invalid documents rejected before identity calculation. |
| P7-A2 | All JCS success bytes remain identical; Catalogue failure codes, paths, messages, error shape, and validation order remain identical; neutral errors map to Behavior diagnostics. |
| P7-B1 | Typed contract/binding shapes for primitive references, triggers, controlled targets, optional occurrence initial-state assignments, `primitive_policy_values` with default `{}`, the eight exact FocusPolicy fields and their cardinality, diagnostics, provenance, and the complete occurrence field list. Evidence confirms all four FocusPolicy references are enumerable, null scope means binding owner, explicit owner-valued scope is rejected as noncanonical, runtime invoker and roving-target references are not duplicated, other cross-cutting policies carry no node references, state and policy assignments remain distinct, arrays are ordered, and primitive-definition/state-machine fields remain absent. Also prove the three null policy defaults, empty responsive list, recursive safe string-keyed values, ordered arrays, exact ResponsiveBehaviorOverride fields, unique modes, and no generic node-reference channel. |
| P7-B2 | Binding-ID golden vectors prove occurrence-only discriminators; changing `primitive_policy_values` changes the discriminator; different object insertion order with the same values yields the same discriminator; `['a', 'b']` and `['b', 'a']` yield different discriminators; equivalent stable-key objects with different insertion order yield the same discriminator. Also test source traversal noise, duplicate occurrence rejection, stable zero-based ordinals, and that primitive-definition body changes do not affect binding IDs. B2 tests prove structural determinism, not primitive policy validity. Also prove nested policy arrays retain order, reordered unique responsive records yield the same discriminator, duplicate modes reject before identity assignment without P7-C lookup, B2 receives no redundant owner scope, changing semantic `authority_ref` changes the discriminator, and evidence-only provenance/source-trace references do not. |
| P7-B3 | Golden bytes/digest cover every canonical contract and binding field, diagnostics, provenance, and SourceTrace. Test deterministic diagnostic order and complete-JCS tie-break, provenance ordered arrays, SourceTrace class sorting/duplicate rejection, full PrimitiveRef participation, all binding-owned references and owner-subtree checks, exact DesignDocument identity, and full-set B2 ID/ordinal recomputation. Prove binding-owned diagnostics accept only `binding_id=null`; contract diagnostics accept null or an existing ID and reject unknown IDs. Prove diagnostic nodes inside and outside a binding subtree are valid when present in the exact document, while unknown nodes reject. Reject empty non-null evidence IDs and prove opaque IDs trigger no provenance lookup. `validate_structure/2` is the only validation API; no primitive semantics are included. |
| P7-B4 | Freeze a literal full-result fixture, canonical JSON bytes, and independently computed `brv_` ID. Prove evidence input-order invariance; ID changes for decision, reviewer, timestamp, evidence set, and null-versus-empty note; duplicate evidence rejects. Reject noncanonical/impossible timestamps. Exact contract, digest, identity, and algorithm matches pass; mismatches reject. Gate tests prove zero/multiple-result rejection, exact singleton approved success, non-approved rejection, and no timestamp selection. Lifecycle tests prove immutable decisions and new results for later decisions. |
| P7-C | Registry rejects unknown/unimplemented exact `(kind, definition_version)` pairs without fallback; validates occurrence initial-state assignments and `primitive_policy_values` keys, value types/shapes, domains, required/optional status, defaults, and invariants against the exact definition. Evidence proves an array is semantically rejected when that definition requires a stable-key object, while a permitted stable-key object may pass; permitted arrays retain their exact order. P7-C never reinterprets or reorders arrays. `validate/2` calls both `validate_structure/2` and `validate_semantics/2`; semantic diagnostics are deterministic. P7-C owns Timer/Keyboard/Motion/Responsive semantic vocabularies, applicability, domains, defaults, invariants, mode/authority checks, reversibility, and primitive-specific combinations. |
| P7-D0 | Exact document/contract/review matching; structural validation; candidate boundary and every binding-owned behavior reference checked, including all four FocusPolicy references; contained, irrelevant, split, and unresolved bindings classified deterministically; proposer is not called on rejection and receives unchanged validated semantic input on acceptance. Diagnostic node IDs are excluded from candidate-boundary containment. Unsupported primitive semantics remain blocked at the later full validation gate. Generic policy values add no node-reference channel. |
| Existing ComponentizationProposer + ComponentReview | Existing proposer still creates only a proposed tuple; its existing ComponentReview and C09D6 gates remain mandatory before the post-review projection. |
| P7-D1 | Five exact inputs required; review decision/document/contract digest match; golden projection bytes/ID; plan fingerprint equals NativeGenerator's serialized-plan SHA-256; all four FocusPolicy node refs rechecked against approved boundaries; invalid boundaries, stale inputs, ambiguous mappings, and unprojected required bindings reject. Generic policy values add no node-reference channel. |
| P7-E | Realization selector chooses only supported least-cost strategies; unknown/unsafe strategy rejects; no hook, RuntimeInstance, browser resource manager, or DOM lifecycle code is introduced. |
| P7-F | Core `closed | open`; native details/summary candidate; ordinary links; accepted native activation/accessibility only; no invented ARIA; no JavaScript and no RuntimeInstance. Browser verification only for this bounded core. |
| P7-G | Separate focused/selected tab state; activation modes and keyboard policy; accessible relationships; if a managed runtime is required, its patch/reconnect/resource cleanup tests cover Tabs only. |
| P7-H | `single | multiple` constraints; closure rules; reversible tabs-to-accordion mapping; browser verification for responsive changes. |
| P7-I | Disclosure navigation and composite Menu remain separate; usable links; accepted keyboard/focus model; unknown source event names reject. |
| P7-J | Top-modal Escape, focus entry/containment/return, nested dialog ownership, inert background, and dialog-owned scroll-lock cleanup. |
| P7-K | Orthogonal slide selection/rotation/focus-hover state; reduced-motion changes; timer eligibility, pause/resume, and owner cleanup. |
| P7-L | One separately selected source fixture and one approved behavior pattern traverse evidence, contract, review, pre-proposer decision, existing proposer and ComponentReview, projection, generation prerequisites, and realization without source runtime dependencies. |

Every applicable slice also checks that no imported source code executes, no dynamic atom/module conversion occurs, and no Bricks, Frames, WordPress, ACSS, private vendor code, or unapproved runtime dependency enters the reusable library. Pure serializers and validators do not need browser tests. Browser tests are limited to a slice whose accepted behavior requires browser proof.

## 11. Ordered future issue tree

P7-A1, P7-A2, P7-B1, and P7-B2 are implemented and accepted. P7-B3 is implemented and accepted on PR #179 with valid signature and passing post-merge CI. P7-B4 is blocked until this v1.0.8 amendment is independently accepted and merged with passing post-merge CI. P7-C through P7-L remain planned and not authorized. No GitHub issues are created by P7-0. Each later issue is independently reviewable and requires explicit owner authorization before work begins.

```text
P7_ISSUE_COUNT=17
FUTURE_ISSUE_COUNT=13
FUTURE_ISSUES_CREATED=NO
P7_B1=IMPLEMENTED_ACCEPTED
P7_B2=IMPLEMENTED_ACCEPTED
P7_B3=IMPLEMENTED_ACCEPTED
P7_B4=BLOCKED_PENDING_V1_0_8_ACCEPTANCE
P7_B4_PREREQUISITES=SATISFIED
P7_B4_IMPLEMENTED=NO
P7_C_STARTED=NO
```

| Order | Issue | Scope and required result | Dependency and hard gate |
| --- | --- | --- | --- |
| 1 | **IMPLEMENTED / ACCEPTED** P7-A1 — DesignDocument identity | `LiveFrames.IR.Identity` owns the current IR serializer SHA-256; `ComponentizationPlan.design_document_sha256/1` delegates to it; algorithm is `lf-ir-serializer-v1` + `sha-256`. | Separately owner-authorized after P7-0. Existing digest values and ComponentizationPlan 1.0.0 remain unchanged. |
| 2 | **IMPLEMENTED / ACCEPTED** P7-A2 — Source-neutral JCS utility | `LiveFrames.CanonicalJSON` owns the tested JCS encoder; Catalogue compatibility wrapper preserves bytes and diagnostics. | Separately owner-authorized after P7-0. No Behavior → Catalogue dependency or Catalogue contract changes. |
| 3 | **IMPLEMENTED / ACCEPTED** P7-B1 — BehaviorContract / BehaviorBinding structural model | Define the typed contract/binding model and closed nested shapes for versioned primitive references, triggers, targets, occurrence initial-state assignments, source-neutral `primitive_policy_values` defaulting to `{}`, cross-cutting policies including FocusPolicy, diagnostics, and provenance. | Accepted B1 structural authority. No primitive semantic validation or runtime. |
| 4 | **IMPLEMENTED / ACCEPTED** P7-B2 — BehaviorBinding deterministic identity | Apply the occurrence-only discriminator, duplicate rule, deterministic ordinal ranking, and `bnd_` ID algorithm to P7-B1's typed model. | Accepted B2 identity authority. The formula uses `primitive_ref.kind`, excludes definition version and primitive-definition bodies, and preserves ordered policy arrays. |
| 5 | **IMPLEMENTED / ACCEPTED** P7-B3 — BehaviorContract serializer and structural validation | Implemented under PR #179 and accepted on merge `5ea3b0b597eaeebec5524998db93a29e5f7225e8`; post-merge CI `38044213077` passed on that SHA. | Validated with the accepted v1.0.7 authority. No P7-C semantic checks. Merge drift was limited to non-overlapping CTA Tango proposer-run/proposer-output documentation. |
| 6 | **BLOCKED PENDING V1.0.8 ACCEPTANCE** P7-B4 — BehaviorReviewResult artifact | Implement the exact immutable nine-field review model, canonical JCS serializer, derived `brv_` identity, intrinsic validator, contract matcher, and exact-one approval gate specified in §3. | P7-B3 is accepted and prerequisites are satisfied. This v1.0.8 amendment does not authorize B4; no latest/timestamp selection, storage service, mutable status, or P7-C authority. |
| 7 | **PLANNED — NOT AUTHORIZED** P7-C — Primitive registry and validation composition | Implement the trusted registry and primitive-definition ownership of StateModels, Transitions, Guards, Effects, cardinality, invariants, and semantic validation. Compose `validate/2 = validate_structure/2 AND validate_semantics/2`. | Depends on P7-B4. Validate state assignments and each exact primitive definition's allowed policy keys, value types/shapes, domains, required/optional status, defaults, and invariants. Own FocusPolicy strategy vocabularies, strategy/reference combinations, and primitive-specific focus invariants. Reject mismatching structural shapes, such as an array where the exact definition requires a stable-key object; preserve the exact order of every permitted array. Never reinterpret or reorder arrays. Do not implement every primitive; each tracer adds its own definition. P7-C owns semantic policy values and combinations for Timer/Keyboard/Motion/Responsive. |
| 8 | **PLANNED — NOT AUTHORIZED** P7-D0 — BehaviorComponentizationDecision | Validate the exact reviewed behavior against the explicit candidate `ComponentizationSemanticInput`; gate the existing proposer call on whole-binding containment. | Depends on P7-C and P7-B4. Ephemeral result only. Reject split/uncertain boundaries with `STOP=BEHAVIOR_AWARE_BOUNDARY_UNRESOLVED`; do not bypass or change the proposer. |
| Existing stage | EXISTING — ComponentizationProposer + ComponentReview | Existing authorities create a proposed ComponentContract/Plan and require explicit human ComponentReview plus C09D6 prerequisites. | This is an existing pipeline stage, not a new P7 issue. P7-D1 cannot proceed before its exact approved tuple exists. |
| 9 | **PLANNED — NOT AUTHORIZED** P7-D1 — BehaviorProjection | Implement the five-input post-review projection, exact review-result validation, deterministic `bpr_` identity, ownership verification, and C09D6 prerequisites. | Depends on P7-D0, existing ComponentizationProposer, and approved ComponentReview. Use a test-only trusted primitive definition; add no production primitive. Formats remain 1.0.0. |
| 10 | **PLANNED — NOT AUTHORIZED** P7-E — Compile-time realization selector | Select the least complex safe realization for a fully validated projected binding. | Depends on P7-D1. No browser runtime, hook framework, resource manager, or DOM lifecycle code. |
| 11 | **PLANNED — NOT AUTHORIZED** P7-F — Core Disclosure tracer informed by Slide Menu Alpha | Add the first concrete primitive and native component/story for only the accepted `closed | open` core and ordinary usable links. | Depends on P7-E and a separately approved component tuple. `FULL_SLIDE_MENU_ALPHA_TRACER=BLOCKED`; no unresolved current-page, nesting, keyboard, ARIA, style, or hook behavior. `RUNTIME_INSTANCE_REQUIRED=NO`. |
| 12 | **PLANNED — NOT AUTHORIZED** P7-G — Tabs | Add Tabs semantics and the minimum realization required for accepted activation behavior. | Depends on P7-F. Any managed runtime stays scoped to Tabs and its patch/cleanup evidence. |
| 13 | **PLANNED — NOT AUTHORIZED** P7-H — Accordion and responsive mapping | Add Accordion semantics and reversible responsive Tabs-to-Accordion mapping. | Depends on P7-G and accepted responsive authority; no nesting policy inferred from Slide Menu. |
| 14 | **PLANNED — NOT AUTHORIZED** P7-I — Disclosure popup and Menu | Add website disclosure navigation and composite Menu as separate behavior definitions. | Depends on P7-H; menu semantics and keyboard model require accepted evidence. |
| 15 | **PLANNED — NOT AUTHORIZED** P7-J — Dialog and Lightbox | Add Dialog/Lightbox semantics and required scoped modal runtime ownership. | Depends on P7-I; dialog-specific focus, nested stack, and scroll-lock work starts here. |
| 16 | **PLANNED — NOT AUTHORIZED** P7-K — Carousel | Add Carousel semantics and opt-in timer/control realization. | Depends on P7-J; timer and cleanup remain primitive-scoped. |
| 17 | **PLANNED — NOT AUTHORIZED** P7-L — One source integration tracer | Integrate one separately selected source fixture and one approved behavior through the complete reviewed pipeline. | Depends on preceding primitive/pipeline gates. Additional sources or behaviors require separate authorization. |

P7-B1, P7-B2, and P7-B3 are implemented and accepted. P7-B3 was accepted on PR #179, merge `5ea3b0b597eaeebec5524998db93a29e5f7225e8`, with valid signature and passing post-merge CI. Its only merge drift from the reviewed base was non-overlapping CTA Tango proposer-run/proposer-output documentation. P7-B4 remains blocked until this v1.0.8 amendment is independently accepted and merged with passing post-merge CI. P7-C through P7-L remain unauthorized and depend on their prior artifacts as shown. P7-D0 gates the existing proposer; existing ComponentReview occurs before P7-D1. The pre-proposer decision is ephemeral, while the post-review projection is the persisted identity-bearing sidecar. P7-D1 uses a test-only trusted primitive definition through the P7-C registry API; it adds no production primitive.

P7-0 itself authorized no implementation. P7-A1, P7-A2, P7-B1, and P7-B2 were separately owner-authorized and are implemented/accepted.

This v1.0.8 authority amendment does not itself authorize P7-B4 or any successor.

Approval of any issue does not authorize its successor.

## 12. TOON micro-prompts

P7-A1, P7-A2, P7-B1, and P7-B2 below are accepted historical slices, not future prompts. P7-B3 is implemented and accepted. P7-B4 is blocked pending v1.0.8 acceptance and merge. P7-C through P7-L remain **PLANNED — NOT AUTHORIZED** until the owner authorizes each issue. The existing ComponentizationProposer and ComponentReview are gates between P7-D0 and P7-D1, not new issues in this decomposition.

### P7-A1 — DesignDocument identity

| Field     | Content |
|-----------|---------|
| Task      | **IMPLEMENTED / ACCEPTED** Historical slice. |
| Objective | `LiveFrames.IR.Identity` owns the current `IR.encode!` plus SHA-256 identity without changing componentization fingerprints. |
| Output    | `apps/live_frames/lib/live_frames/ir/identity.ex`; `ComponentizationPlan.design_document_sha256/1` compatibility delegation; accepted digest tests. |
| Note      | Separately authorized after P7-0. `ComponentizationPlan.design_document_sha256/1` return values and plan format remain unchanged. |

### P7-A2 — Source-neutral CanonicalJSON

| Field     | Content |
|-----------|---------|
| Task      | **IMPLEMENTED / ACCEPTED** Historical slice. |
| Objective | `LiveFrames.CanonicalJSON` gives Behavior the shared restricted JSON algebra without a Behavior-to-Catalogue dependency. |
| Output    | `apps/live_frames/lib/live_frames/canonical_json.ex`; Catalogue compatibility wrapper; accepted byte, error-contract, and fingerprint tests. |
| Note      | Separately authorized after P7-0. Catalogue diagnostics, bytes, and fingerprints remain compatible. |

### P7-B1 — BehaviorContract / BehaviorBinding structural model

| Field     | Content |
|-----------|---------|
| Task      | **IMPLEMENTED / ACCEPTED** Define the typed structural model and closed field shapes for BehaviorContract and BehaviorBinding. Also prove policy defaults, recursive safe values, ordered arrays, exact responsive fields, unique modes, and no generic node-reference channel. |
| Objective | Give identity, serialization, review, and projection slices one stable typed representation to consume. |
| Output    | `apps/live_frames/lib/live_frames/behavior/contract.ex` and `binding.ex`, with typed primitive references, triggers, controlled targets, optional occurrence initial-state assignments, `primitive_policy_values` as a source-neutral string-keyed canonical-value object with default `{}`, cross-cutting binding policies, diagnostics/provenance, and closed field-shape tests under `apps/live_frames/test/live_frames/behavior/`. Tests keep state assignments separate from policy assignments, define arrays as ordered sequences, and reject primitive-definition/state-machine fields on bindings. Tests prove timer/keyboard/motion defaults are nil, responsive overrides default to [], recursive safe string-key values, ordered arrays, unique modes, canonical owner scope with redundant owner scope rejected, and no generic node-reference channel. Focus-scope cases prove owner plus null is canonical, owner-equal explicit scope is rejected, and distinct explicit scope is structurally allowed. |
| Note      | Depends on accepted P7-A1 and P7-A2. Freeze `PrimitiveRef {kind, definition_version}` as two closed trusted strings, with exactly one reference per binding. B1 freezes string object keys, the accepted canonical value algebra, order-significant arrays, and the FocusPolicy field/reference shape in §2.4. B1 owns structural representation only and does not validate primitive-specific policy vocabulary or value shapes, or consult the registry. Define `binding_id` and `ordinal` as unassigned `null` only on the normalized pre-identity binding value; persisted contract bindings require both. B1 performs no ID derivation, contract digest, primitive semantic validation, source adaptation, or runtime work. Freeze CrossCuttingPolicyValues as safe string-keyed values with ordered arrays. Timer/keyboard/motion are object-or-null; responsive records have unique modes and semantic authority references. B1 rejects duplicate modes and explicit owner-valued FocusPolicy scope before identity; owner plus null is canonical and distinct explicit scope remains structurally allowed. P7-C owns policy meaning and strategy/reference combinations. |

### P7-B2 — BehaviorBinding deterministic identity

| Field     | Content |
|-----------|---------|
| Task      | **IMPLEMENTED / ACCEPTED** Implement the structured binding ID payload and semantic discriminator ordinal algorithm over P7-B1's typed model. |
| Objective | Make BehaviorBinding IDs deterministic and independent of source traversal, map order, and final contract digest. |
| Output    | `apps/live_frames/lib/live_frames/behavior/binding_identity.ex`; golden IDs and order/duplicate/ordinal tests under `apps/live_frames/test/live_frames/behavior/`. |
| Note      | Depends on P7-B1. Group by `(owner_node_id, primitive_ref.kind, binding_role)`; discriminate on occurrence triggers, controlled targets, optional initial-state assignments, `primitive_policy_values`, and binding-owned cross-cutting policies including the complete typed `focus_policy` value; remove exactly `binding_id`, `ordinal`, `diagnostics`, `provenance`, and `source_trace`; JCS-encode; reject duplicate bytes; rank unsigned byte strings from zero. Canonicalize policy object keys and preserve every policy array's exact order without classifying arrays by primitive-specific meaning or consulting P7-C for ordering. Structurally valid values may receive deterministic identity before P7-C rejects their semantic shape. Different values produce different discriminators; equivalent maps with different insertion order produce the same discriminator; reversed ordered arrays produce different discriminators. Exclude `definition_version` and all primitive definitions, state models, transitions, guards, and effects from binding IDs. Do not change the high-level binding ID formula. No FocusPolicy fields enter the high-level payload. No provisional maps, generic untyped API, random/source IDs, selectors/classes, component instances, or runtime. Preserve the accepted identity vectors and add proofs for nested policy-array order, responsive input-order invariance, duplicate-mode rejection before ordinal/ID assignment, and canonical FocusPolicy scope input. Changing semantic `authority_ref` changes the discriminator; changing evidence-only provenance/source-trace references does not. B2 assumes B1 canonical scope and never normalizes it. |

### P7-B3 — BehaviorContract serializer and structural validation

| Field     | Content |
|-----------|---------|
| Task      | **IMPLEMENTED / ACCEPTED** Historical slice, implemented under PR #179 after v1.0.7 acceptance. |
| Objective | Create the persisted source-neutral contract linked to one exact DesignDocument and verify assigned binding identities. |
| Output    | `apps/live_frames/lib/live_frames/behavior/serializer.ex`, `diagnostic.ex`, and `validation.ex`; golden bytes/digest and malformed-reference tests under `apps/live_frames/test/live_frames/behavior/`. |
| Note      | Depends on accepted P7-B2 and accepted v1.0.7 authority. Use the §2.7 diagnostic shape/order, container-only binding diagnostic association (`binding_id` MUST be null), contract diagnostic binding reference rules, canonical provenance object, `LiveFrames.IR.SourceTrace` mapping, BehaviorContract/Binding mappings, collection ordering, and digest participation exactly. Diagnostic `node_id` resolves against the exact DesignDocument only, not behavior-owner or component-boundary containment. `evidence_id` is opaque, non-empty safe Unicode when present, and is not resolved through generic provenance. Use only `LiveFrames.CanonicalJSON` for JCS. Expose `LiveFrames.Behavior.Validation.validate_structure/2` only. Validate the exact DesignDocument identity, all references in §2.7, binding-owned owner-subtree containment, diagnostic ownership/references, and binding IDs/ordinals by one full-set call to accepted `BindingIdentity.assign/1`. No registry lookup or semantic vocabulary checks. Do not expose `validate_semantics/2` or `validate/2`; those remain P7-C. Preserve BehaviorContract `1.0.0`, Design IR, and the accepted B2 identity formula. |

### P7-B4 — BehaviorReviewResult artifact

| Field     | Content |
|-----------|---------|
| Task      | **BLOCKED PENDING V1.0.8 ACCEPTANCE** Implement only after this exact authority is accepted and merged with passing post-merge CI. |
| Objective | Represent one immutable human decision about one exact BehaviorContract and let consumers require that explicit result. |
| Output    | Only `apps/live_frames/lib/live_frames/behavior/review_result.ex` and `apps/live_frames/test/live_frames/behavior/review_result_test.exs`. Production module `LiveFrames.Behavior.ReviewResult`; public API exactly `algorithm/0`, `validate/1`, `encode/1`, `id/1`, `validate_against_contract/2`, `require_approved/2`. |
| Note      | Exact persisted fields, with no defaults: `review_format_version`, `design_document_identity`, `behavior_contract_digest_algorithm`, `behavior_contract_digest`, `decision`, `reviewer_identity`, `reviewed_at`, `review_note`, `evidence_refs`. Version `1.0.0`. No persisted `review_id`, `id`, `digest`, `status`, `latest`, or `version_counter`; derive `brv_` plus lowercase SHA-256 on demand from `LiveFrames.CanonicalJSON` bytes. Sort evidence refs by ascending Unicode-scalar string order; reject duplicates; input order is not identity-significant. Require UTC `YYYY-MM-DDTHH:MM:SS.ffffffZ`, exact lexical validation and valid UTC `DateTime` parsing; no normalization or system clock. Reuse `LiveFrames.IR.Identity` and `LiveFrames.Behavior.Diagnostic`. Match exact document identity, `LiveFrames.Behavior.Serializer.algorithm()`, and recomputed `Serializer.digest/1`; no DesignDocument argument or B3 structural-validation call. `require_approved/2` accepts a proper list, rejects zero and multiple results, validates the singleton against the contract, then returns that exact result only if decision is `approved`; never select by time/order. Use the eight `behavior.review.*` codes and existing categories in §3. No P7-C semantics, database/current-review state, registry lookup, infrastructure, B3 changes, or other changed files. See §3 for golden bytes/ID, field validation, gate, lifecycle, boundary, diagnostics, security, and scaling tests. This amendment does not authorize implementation. |

### P7-C — Primitive registry and validation composition

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Implement the trusted registry mechanism, common closed vocabularies, and staged semantic validation API. |
| Objective | Ensure full Behavior validation cannot pass without both structural/reference checks and primitive semantics. |
| Output    | `apps/live_frames/lib/live_frames/behavior/primitive_registry.ex` and the composed `validation.ex` API; `validate_semantics/2`; `validate/2 = validate_structure/2 AND validate_semantics/2`; composition and unsupported-definition tests. |
| Note      | Depends on P7-B4. The trusted registry resolves each exact `(kind, definition_version)` pair and owns that definition's `BehaviorStateModel`; the model owns `Transition` definitions, which own their `TransitionGuard`, `BehaviorEffect`, and associated `AccessibilityEffect` definitions. Validate each binding's primitive reference, occurrence initial-state assignment, `primitive_policy_values`, triggers, targets, and binding policies against the selected definition. Unknown pairs fail closed; kind-only and latest-version fallback are prohibited. The exact definition owns permitted policy keys, value types/shapes, domains, required/optional status, defaults, and invariants. Reject a structural value shape, including an array, when that exact policy definition does not permit it; a semantically invalid binding may already have a deterministic structural ID. For an allowed ordered sequence, validate its contents without reinterpreting or reordering it. Where a policy is defined as unordered/set-like, its permitted shape should use a stable-key object. Policy values contain no DesignNode references. Do not implement every primitive definition here. An unimplemented kind/version remains unsupported until its tracer supplies the definition. No source-defined vocabulary, adapter, JavaScript, hooks, infrastructure, or polling. P7-C owns Timer/Keyboard/Motion/Responsive semantics, modes and authority validity, reversible mapping, and primitive-specific combinations. |

### P7-D0 — BehaviorComponentizationDecision

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Add the ephemeral pre-proposer boundary admissibility gate for the exact reviewed BehaviorContract and explicit ComponentizationSemanticInput. |
| Objective | Prevent a human componentization candidate from splitting or excluding a behavior binding before the existing proposer constructs a tuple. |
| Output    | `apps/live_frames/lib/live_frames/behavior/componentization_decision.ex`; deterministic containment diagnostics; tests proving fail-closed gating and unchanged input to the existing `ComponentizationProposer.propose/2`. |
| Note      | Depends on P7-C and the P7-B4 review artifact. Require `validate_structure/2` and validate existing semantic input, exact DesignDocumentIdentity/contract digest/review ID, the proposed boundary node, and every typed node reference in each relevant binding. Enumerate `owner_node_id`, trigger origins, controlled targets, all four FocusPolicy references, and any other separately authorized typed occurrence-level references. This gate makes no claim that an unimplemented primitive passes semantic validation; full `validate/2` is required before projection/generation. No serializer, ID, persistence, proposer bypass/change, boundary inference, source selector/class/runtime, or format change. Reject split/uncertain bindings with `STOP=BEHAVIOR_AWARE_BOUNDARY_UNRESOLVED`. The four FocusPolicy refs are the complete current FocusPolicy node-ref set; generic policy values add no reference channel. |

### P7-D1 — BehaviorProjection post-review sidecar

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Verify exact binding ownership against the actual approved ComponentContract and matching ComponentizationPlan. |
| Objective | Prove every required binding fits the component tuple after the existing ComponentReview. |
| Output    | `apps/live_frames/lib/live_frames/behavior/projection.ex` and its explicit JCS serializer/validator; `bpr_` IDs; golden serializer/digest and stale/boundary tests. |
| Note      | Depends on P7-D0, the existing proposer output, and its approved ComponentReview. Inputs are exact DesignDocument, BehaviorContract, one approved matching BehaviorReviewResult, approved ComponentContract, and matching ComponentizationPlan. Recheck all four FocusPolicy references against approved boundaries. Use NativeGenerator's serialized-plan SHA-256. Use a test-only trusted primitive definition; add no production primitive. No component hash, cross-boundary mapping, schema change, or runtime. Recheck the FocusPolicy references against approved boundaries; generic values add no node refs. |

### P7-E — Compile-time RuntimeRealization selector

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Select the least complex safe realization for a fully validated projected binding. |
| Objective | Keep semantic contracts separate from output choices and reject unsupported target strategies before generation. |
| Output    | `apps/live_frames/lib/live_frames/behavior/runtime_realization.ex`; compile-time selector/result tests under the behavior test tree. |
| Note      | Depends on P7-D1. No browser runtime, hooks, RuntimeInstance manager, timer system, resource manager, DOM scans, polling, cache, Redis, DB, or PubSub. Add managed code only inside a later primitive issue that proves it needs it. |

### P7-F — Core Disclosure tracer informed by Slide Menu Alpha

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Prove only the accepted `closed | open` Disclosure core with a native `<details>/<summary>` candidate and ordinary usable links. |
| Objective | Establish the smallest evidence-backed Disclosure tracer without claiming full Slide Menu Alpha behavior. |
| Output    | Core Disclosure semantic definition/tests plus native component/story and browser evidence using the existing approved component tuple. |
| Note      | Depends on P7-E and the exact approved component tuple. `RUNTIME_INSTANCE_REQUIRED=NO`; no unnecessary JavaScript. If the tuple is absent or unauthorized, `STOP=COMPONENTIZATION_PREREQUISITE_MISSING`; P7-F cannot create or bypass it. Exclude current-page, nesting, exclusive accordion policy, custom keyboard, invented ARIA, source selectors/classes/runtime, and exact motion values. `FULL_SLIDE_MENU_ALPHA_TRACER=BLOCKED`. |

### P7-G — Tabs

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Add Tabs state semantics and the minimum realization needed for accepted activation behavior. |
| Objective | Prove separate focus/selection, activation policy, keyboard behavior, accessible relationships, and LiveView patch requirements. |
| Output    | Tabs primitive definition and tests; browser adapter only if native semantics/LiveView.JS cannot meet accepted lifecycle requirements. |
| Note      | Depends on P7-F. If managed runtime is necessary, scope lifecycle and cleanup to Tabs. Do not build a generic hook framework or use a server round trip for local presentation. |

### P7-H — Accordion and responsive mapping

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Add Accordion semantics and reversible responsive Tabs-to-Accordion state mapping. |
| Objective | Preserve valid selection/open state across accepted responsive modes. |
| Output    | Accordion definition, responsive mapping, invariant tests, and browser accessibility evidence. |
| Note      | Depends on P7-G. Define `single | multiple` and closure rules from accepted authority. Do not infer them from Slide Menu nesting. Missing style/breakpoint authority blocks mapping. |

### P7-I — Disclosure popup and Menu

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Add website disclosure popup and composite Menu as separate behavior definitions. |
| Objective | Preserve ordinary navigation links while implementing command-menu semantics only where evidence supports them. |
| Output    | Separate definitions and focused keyboard/focus/browser tests for each accepted behavior. |
| Note      | Depends on P7-H. Do not infer menu behavior from dropdown appearance or translate arbitrary source event/listener names. |

### P7-J — Dialog and Lightbox

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Add Dialog semantics and Lightbox composition with only the modal runtime resources those behaviors require. |
| Objective | Prove modality, focus ownership, Escape stack behavior, nested coordination, and cleanup. |
| Output    | Dialog/Lightbox definitions, scoped runtime if required, and tests for focus, inertness, top-modal Escape, nested dialogs, scroll-lock ownership, and browser accessibility. |
| Note      | Depends on P7-I. Dialog scroll-lock, focus containment, and nested stack code belongs here. `aria-modal` alone is insufficient. |

### P7-K — Carousel

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Add Carousel state and its bounded opt-in timer realization. |
| Objective | Prove orthogonal slide selection, rotation, focus/hover suspension, control state, reduced motion, and timer cleanup. |
| Output    | Carousel primitive definition, minimal browser runtime if required, and browser/accessibility/timer lifecycle tests. |
| Note      | Depends on P7-J. Carousel timers and cleanup belong here. No default autoplay, polling, or premature dependency selection. |

### P7-L — One source integration tracer

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Integrate exactly one separately selected source fixture and one approved primitive through the accepted pipeline. |
| Objective | Prove end-to-end conversion without turning one tracer into a broad adapter sweep. |
| Output    | One source-normalization path, deterministic fixture, reviewed BehaviorContract, pre-proposer decision, approved component tuple, exact projection, generated artifact, and required browser/accessibility evidence. |
| Note      | Depends on preceding pipeline gates. Owner selects the source and behavior before authorization. Imported scripts remain inert. ComponentReview and all prior gates remain mandatory. Each additional source or behavior gets a separate issue. |

## 13. Change and authorization limits

P7 implementation must stop and request an authority update if it requires a Design IR schema or meaning change, a ComponentContract or ComponentizationPlan format change, a different DesignDocument identity algorithm, cross-boundary behavior ownership, unresolved accessibility semantics, ambiguous resource ownership, or implementation work to prove the architecture. Do not resolve those conditions by adding production code outside an authorized issue.

The only change authorized by P7-0 is this planning document. It authorizes no Elixir, JavaScript, hook, CSS, tests, schema, dependency, Catalogue change, roadmap rewrite, GitHub issue, or runtime behavior.

## 14. P7-0 review checklist

- [x] Ultimate P7 outcome
- [x] Domain/resource map
- [x] DesignDocument identity strategy
- [x] Canonicalization strategy
- [x] BehaviorBinding identity strategy
- [x] BehaviorContract canonical serialization strategy
- [x] Design IR non-migration boundary
- [x] BehaviorContract review/approval model
- [x] Immutable BehaviorReviewResult serialization, identity, and explicit-input rule
- [x] Primitive registry boundary
- [x] Pre-proposer BehaviorComponentizationDecision and ephemeral persistence rule
- [x] Behavior-aware candidate-boundary gate before ComponentizationProposer
- [x] Existing ComponentReview gate preserved
- [x] Post-review BehaviorProjection ownership proof
- [x] BehaviorProjection five-input signature and content identity
- [x] Runtime realization boundary
- [x] Runtime lifecycle ownership
- [x] Staged structural and primitive semantic validation
- [x] Stable BehaviorBinding semantic discriminator and ordinal assignment
- [x] Typed BehaviorBinding structural model precedes identity derivation
- [x] Dedicated BehaviorReviewResult implementation slice precedes consumers
- [x] Slide Menu Alpha core-only status and blocked full tracer
- [x] Bounded issue decomposition and native-runtime YAGNI gate
- [x] Security model
- [x] Accessibility gates
- [x] Performance classification
- [x] Test strategy
- [x] Ordered implementation issue tree
- [x] TOON micro-prompts
- [x] Explicit future authorization boundaries
