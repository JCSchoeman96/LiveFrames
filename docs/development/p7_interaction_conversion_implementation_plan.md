# P7 interaction conversion implementation plan

**Plan version:** 1.0.0  
**Date:** 2026-10-09  
**Status:** proposed for independent review; implementation is not authorized  
**Authority:** `docs/09_INTERACTION_MODEL.md` revision 1.0.1  
**Base:** `9d37aaf5169f8e59b38cda737f685b7fbf43d567`  
**Tree:** `91511a843a32e5f5f74da45c58d0fe91cd5b1298`

## 1. Purpose and authority

P7 establishes a source-neutral behavior contract and turns accepted behavior evidence into accessible Phoenix-native interactions. It must preserve the accepted C09D6 static generation path, bind behavior to one exact DesignDocument, and keep source runtimes and executable source material out of generated components.

This document resolves the implementation decisions that `docs/09_INTERACTION_MODEL.md` left open. It is an implementation plan and issue decomposition only. It does not authorize P7-A, create implementation structs, change a schema, create GitHub issues, or implement a primitive. Each future issue below needs separate owner authorization after this plan is reviewed and accepted.

The target flow is:

```text
untrusted source behavior evidence
  → source-neutral normalization
  → BehaviorContract linked to exact DesignDocumentIdentity
  → contract validation and explicit semantic review
  → DesignDocument + BehaviorContract + approved ComponentContract
    + matching ComponentizationPlan
  → BehaviorProjection with checked binding ownership
  → runtime realization selection
  → semantic HTML/CSS, LiveView.JS, colocated JS/hook,
    or server ownership only when required
  → interactive native component
  → Storybook, browser, and accessibility verification
```

The reusable `apps/live_frames` library remains independent of the preview application, Bricks, Frames, WordPress, ACSS, source JavaScript, private vendor code, and source runtime packages.

## 2. Repository truth and compatibility boundary

The cited authorities agree on these facts:

| Area | Current repository truth | P7 rule |
| --- | --- | --- |
| Design IR | `LiveFrames.IR.DesignDocument` writes IR `3.0.0`. Required root fields include `interactions`; there is no `behaviors` registry. | Keep BehaviorContract separate. Do not change required fields, field meanings, or serialized Design IR in P7-A through P7-L. |
| Coarse interaction intent | `LiveFrames.IR.Interaction` contains `interaction_id`, `intent`, `trigger`, `target_node_ids`, `parameters`, and `source_trace`. It describes intent and does not select a runtime. | Do not expand or reinterpret it. Existing `interaction_refs` remain references to the current interaction registry. |
| DesignDocument identity | `ComponentizationPlan.design_document_sha256/1` validates the document, calls `LiveFrames.IR.encode!/1`, then computes lowercase SHA-256 over those bytes. C09D3/C09D6 use this digest to bind a plan to the exact document. | Centralize and reuse these exact bytes and digest. Preserve the existing API as a delegating compatibility wrapper. Do not replace the digest with JCS or add a second DesignDocument hash. |
| IR serializer | `LiveFrames.IR.Serializer` emits explicit fields, converts trusted enum atoms to strings, sorts object keys recursively, preserves list order, and delegates JSON encoding to Jason. IR tests assert deterministic output for equivalent conversions. | Treat this existing serializer byte representation as the DesignDocument canonical form for P7. Lock it with golden compatibility tests before changing any implementation. |
| Catalogue canonical JSON | `LiveFrames.Catalogue.CanonicalJSON` implements RFC 8785 through `Jcs`, with a deliberately restricted value algebra: null, booleans, safe integers, valid Unicode strings, lists, and string-keyed objects. Catalogue fingerprints identify their own algorithm. | Reuse the value algebra and JCS behavior through a source-neutral shared boundary. `LiveFrames.Behavior.*` must not depend on `LiveFrames.Catalogue.*`. Keep Catalogue fingerprints byte-for-byte stable. |
| Componentization | `ComponentContract 1.0.0` owns the public API and its approval result. `ComponentizationPlan 1.0.0` owns placement and links to a contract and DesignDocument. C09D6 has shared generation prerequisites and human ComponentReview. | Keep both accepted formats unchanged. Behavior review cannot approve a ComponentContract or substitute for ComponentReview. |

### 2.1 DesignDocument identity decision

The exact identity tuple is:

```text
DesignDocumentIdentity =
  ir_version
  + canonicalization_id
  + lowercase_sha256(IR.encode!(validated DesignDocument) bytes)
```

P7-A names the canonicalization algorithm `lf-ir-serializer-v1`. For the current Design IR, that identifier means the explicit field mapping and recursively sorted JSON-object encoding in `LiveFrames.IR.Serializer`, with list order preserved and Jason JSON encoding as currently locked by the repository. The digest algorithm identifier is `sha-256`. The initial supported identity therefore records IR `3.0.0`, `lf-ir-serializer-v1`, `sha-256`, and the exact digest already produced by `ComponentizationPlan.design_document_sha256/1`.

P7-A centralizes the implementation in a source-neutral `LiveFrames.IR.Identity` boundary. `ComponentizationPlan.design_document_sha256/1` remains callable and delegates to it, preserving its return shape and historical digest. P7-A must prove existing fixtures and serialized ComponentizationPlans keep the same digest. The plan format does not gain an algorithm field. BehaviorContract carries the explicit identity tuple and rejects unknown canonicalization IDs or unsupported IR versions.

This choice uses repository behavior rather than RFC 8785 because the accepted Design IR serializer owns typed struct-to-map conversion and admits finite JSON floats in IR values, while Catalogue JCS rejects floats and accepts only normalized string-key maps. Switching DesignDocument identity to JCS would change the established componentization fingerprint and require explicit migration analysis. The current IR serializer already has explicit field conversion, deterministic key ordering, stable list ordering, and deterministic-output tests. If P7-A finds that its bytes cannot be held stable across supported changes, stop with `STOP=IDENTITY_ALGORITHM_UNRESOLVED`; do not silently replace the algorithm.

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

The identifier algorithm is `lf-behavior-binding-v1-jcs-sha256`. The ID is lowercase SHA-256 of those canonical payload bytes, prefixed `bnd_`. The payload uses named JSON fields, explicit string enum values, a non-negative integer ordinal, and the exact DesignDocument identity. It is unambiguous and does not rely on concatenation or separators. `binding_role` is required and source-independent. `ordinal` orders multiple bindings with the same owner, primitive, and role; normalization derives it from a stable semantic ordering, never raw source traversal. Duplicate payloads are validation errors. IDs exclude final BehaviorContract digest, random UUIDs, source/vendor IDs, selectors, DOM IDs, and component-instance identity.

### 2.3 BehaviorContract serialization and digest decision

P7-A extracts the tested JCS value encoder behind `LiveFrames.CanonicalJSON`; `LiveFrames.Catalogue.CanonicalJSON` delegates to that source-neutral module without changing accepted bytes, diagnostics, or Catalogue fingerprint algorithm. This is the only canonical JSON implementation after extraction. The Behavior domain serializes a typed, explicit map through this utility. It does not call Catalogue modules.

The BehaviorContract value algebra is exactly the extracted JCS algebra: `null`, booleans, safe integers, valid Unicode strings, arrays, and objects with valid Unicode string keys. Behavior semantics use integer milliseconds and closed string vocabularies, so binary floats are unnecessary and invalid. Structs, atoms, non-finite numbers, oversized integers, improper lists, invalid Unicode, and non-string object keys are rejected before encoding. Trusted Elixir enum atoms become their fixed vocabulary strings in the Behavior serializer; untrusted strings never become atoms.

The algorithm identifier is `lf-behavior-v1-jcs-sha256`. It identifies explicit BehaviorContract `1.0.0` field mapping, JCS bytes, and SHA-256. Digest output is lowercase hexadecimal. P7-B must freeze golden canonical bytes and digest fixtures before any future schema change.

Serialization rules are fixed as follows:

- The serializer emits every defined top-level field. Optional scalar/reference fields encode as JSON `null`; empty collections encode as `[]` or `{}` according to their declared type. The serializer never alternates between omission and null for one field.
- Primitive kinds, triggers, roles, transition kinds, effects, policy values, keys, severity, category, identifiers, and algorithm names serialize as closed strings. No atom names are created from input.
- Binding order is ascending `binding_id`. State dimensions, transitions, guards, effects, targets, and policy entries use their schema-defined arrays and stable semantic order. Object keys follow JCS ordering. Arrays are not sorted unless the schema explicitly declares a set-like collection; such collections sort by their stable typed identity before serialization.
- Diagnostics and provenance participate in the BehaviorContract digest, as required by `docs/09` §5 and §6. Diagnostics sort by `(code, severity, category, binding_id-or-empty, node_id-or-empty, stable evidence ID, message)`. Provenance records use typed stable fields, sort set-like evidence by stable evidence ID, and preserve order only for explicitly ordered traces. Changing a diagnostic or provenance record changes the digest.
- Source trace values may preserve inert provenance strings and paths under the source/provenance authority. They cannot be interpreted as executable code, runtime instructions, module names, event names, selectors, or filesystem paths.
- Runtime handles, DOM nodes, listener functions, timers, observers, component-instance scope, current focus, current viewport, and transient runtime state never enter serialized identity.

Unknown algorithm IDs fail closed. A diagnostic may explain an unknown algorithm, but consumers must not hash with a fallback algorithm or compare digests from unlike algorithms.

## 3. Design IR boundary and review model

BehaviorContract remains a separate versioned artifact linked to the exact DesignDocumentIdentity. It references normalized `DesignNode.node_id` values and does not mutate the DesignDocument. It may coexist with coarse `LiveFrames.IR.Interaction` evidence without assigning that registry new behavior semantics.

No Design IR migration is required for P7-A through P7-L. A future proposal to add a `behaviors` field, reinterpret `interaction_refs`, or point existing interaction refs at BehaviorBinding IDs must be a separate Design IR migration decision with a version and migration plan. P7 does not assume that such a migration is necessary.

BehaviorContract has no mutable approval lifecycle. Validation returns deterministic diagnostics. Human semantic review produces a separate immutable `BehaviorReviewResult` tied to the exact BehaviorContract digest, DesignDocumentIdentity, reviewer identity, decision, reviewed diagnostic set, and review timestamp. Its decisions are `approved`, `needs_review`, or `rejected`; a changed BehaviorContract digest invalidates the result. Review evidence is compile-time/persisted with conversion artifacts when the workflow stores artifacts. It is not included in BehaviorContract identity and has no state transitions of its own. No database-backed status service is required.

`approved` means the reviewer accepts the normalized behavior semantics and known diagnostics for downstream projection consideration. It does not approve a ComponentContract, prove source redistribution rights, authorize generation, or bypass C09D6 prerequisites. Interactive generation requires both an approved BehaviorReviewResult and the existing approved ComponentContract plus matching plan and DesignDocument validations.

## 4. Domain and resource map

Every reference is typed, document-local or contract-local, and validated by its owning layer. These are planning boundaries, not implementation structs.

| Concept | Owner and cardinality | Identity and allowed references | Validation owner | Serialization or persistence | Downstream consumer |
| --- | --- | --- | --- | --- | --- |
| `BehaviorContract` | One conversion result per exact DesignDocument; zero or more bindings and diagnostics | Format version plus one `DesignDocumentIdentity`; owns binding IDs and diagnostic/evidence references | `Behavior.Validation` validates identity, bindings, references, policies, and invariants | Persisted compile-time artifact; explicit `Behavior.Serializer` mapping and digest | Semantic review and `BehaviorProjection` |
| `DesignDocumentIdentity` | `LiveFrames.IR.Identity`; one per validated DesignDocument | `(ir_version, canonicalization_id, digest_algorithm, digest)`; no document resemblance matching | IR identity code validates current supported version and exact byte digest | Serializable value inside BehaviorContract and matching review/projection evidence | Componentization matching and stale-document rejection |
| `BehaviorBinding` | One occurrence in a BehaviorContract; exactly one primitive and owner node | Structured `BehaviorBindingID`; refs to exact contract's owner, trigger records, targets, state model, policies, evidence | Behavior validator; projection validator later checks one component boundary | Persisted as part of BehaviorContract | BehaviorProjection and runtime realization selection |
| `BehaviorPrimitiveDefinition` | Closed, versioned trusted registry; one definition per primitive kind | Registry key is a fixed primitive string; many bindings may reference it | Registry definition tests and Behavior validator | Compile-time trusted code/configuration; contract serializes primitive kind only | State validation, accessibility policy, realization selector |
| `Trigger` | Owned by one binding; zero or more typed trigger records | Closed trigger kind and optional typed origin node in owner scope | Behavior validator and primitive definition | Persisted semantic value; no arbitrary browser event string | Runtime realization selector |
| `ControlledTarget` | Owned by one binding; zero or more targets with primitive-specific required roles/cardinality | Exact DesignNode ID and closed target role, inside declared owner subtree | Behavior validator, then BehaviorProjection boundary check | Persisted semantic value; no selector fallback | HEEx relationships and realization |
| `BehaviorStateModel` | Owned by one primitive definition; one or more finite state dimensions | Dimension names/domains and initial values from primitive vocabulary | Primitive definition plus Behavior validator | Persisted normalized semantic data with deterministic dimension order | Transition validation and runtime realization |
| `Transition` | Owned by one state model; zero or more named transitions | Stable transition name, source predicate, trigger, destination dimensions, guards, effects | Behavior validator checks source/destination domains, invariants, and atomicity | Persisted contract value | Runtime realization and browser assertions |
| `TransitionGuard` | Owned by one transition; zero or more pure predicates | Closed guard kind with typed state/policy/context operands | Behavior validator and registry | Persisted typed value; no I/O or executable expression | Runtime realization selector/interpreter |
| `BehaviorEffect` | Owned by one transition; zero or more effects | Closed semantic effect kind and typed target/operand references | Behavior validator | Persisted typed value; no arbitrary DOM mutation recipe | Runtime realization |
| `AccessibilityEffect` | Owned by a transition/effect; zero or more synchronized changes | Semantic state, ARIA/native state, focus and relationships for exact controls/targets | Behavior validator plus accessibility tests/review | Persisted semantic value | Markup and runtime realization; browser/AT verification |
| `TimerPolicy` | Owned by a binding; zero or one policy unless the primitive defines named timers | Closed purpose, integer duration, eligibility, stop/restart rules and reduced-motion response | Primitive definition and Behavior validator | Persisted policy only; timer handle is ephemeral | Runtime timer owner for opted-in timed behavior |
| `FocusPolicy` | Owned by a binding; zero or one named policy | Closed initial, movement, containment, restoration, and safe fallback rules referencing typed nodes | Primitive definition and Behavior validator | Persisted policy | Runtime realization and accessibility checks |
| `KeyboardPolicy` | Owned by a binding; zero or one policy per keyboard interaction model | Closed key/modifier vocabulary and transition/focus mapping | Primitive definition and Behavior validator | Persisted policy | Native semantics or client runtime |
| `MotionPolicy` | Owned by a binding; zero or one policy | Closed animation/autoplay/reduced-motion behavior; time changes semantic state only when explicitly stated | Primitive definition and Behavior validator | Persisted policy | CSS/runtime selector and browser verification |
| `ResponsiveBehaviorOverride` | Owned by a binding; zero or more named mode mappings | Accepted responsive authority plus source-independent modes and reversible state map | Behavior validator; responsive authority resolver | Persisted semantic mapping, not style override | Projection and runtime mode reconciliation |
| `BehaviorDiagnostic` | Owned by a contract; may link one binding, node, or stable evidence record; zero or more | Stable code, severity, category, typed IDs, message, action and provenance evidence | Behavior validator/normalizer; reviewer resolves meaning | Persisted within contract and included in its digest | Review gate; unsupported bindings fail closed |
| `RuntimeInstance` | Runtime owner creates zero or more per binding and repeated item | `(binding_id, approved component instance scope, stable caller item key)`; DOM nodes/handles are references only at runtime | Runtime lifecycle manager | Ephemeral browser state; never serialized or persisted across page lifetime unless primitive semantics explicitly require it | RuntimeRealization and lifecycle cleanup |
| `BehaviorReviewResult` | Human review process; one current result per exact BehaviorContract digest and review scope | Contract digest, DesignDocumentIdentity, decision, reviewer, reviewed evidence set | Review gate and stale-result check | Immutable compile-time review evidence; no mutable lifecycle | Interactive generation prerequisites; never substitutes for ComponentReview |
| `BehaviorProjection` | Projection operation returns one artifact per exact DesignDocument + BehaviorContract + approved component tuple; zero or more projected bindings | Exact identities for all inputs, `contract_id`, plan identity, and one-to-one binding ownership mapping | Projection validator | Persisted compile-time sidecar artifact; its own deterministic serializer | Interactive generator prerequisites |
| `RuntimeRealization` | Selector produces one plan per projected binding or an explicit unsupported result | Binding ID, projection ID, trusted realization kind and version; references semantic policy only | Realization selector plus runtime-specific validators | Compile-time artifact; executable functions/handles are runtime-only and not serialized | HEEx/CSS/JS/hook/server output and browser verification |

`RuntimeInstance` cardinality is one per mounted binding scope, multiplied only by stable repeated-item keys when the approved component renders a repeated behavior. An array position is not a durable item identity. If a reorderable collection has no stable key, state preservation across reorder is unsupported and receives a diagnostic.

## 5. Behavior vocabulary and state validation

The implementation registry is closed and owned by trusted LiveFrames code. Source input cannot add primitive definitions, states, triggers, keys, effects, guards, policies, or realization kinds. A source string outside the registry produces an unsupported diagnostic and no runtime action.

P7-C implements only the definitions already specified by `docs/09_INTERACTION_MODEL.md`: Disclosure/Toggle, Accordion, Tabs, Disclosure Popup, Menu Button/Menu, Dialog, Carousel, and Lightbox as Dialog plus collection navigation. It also defines the policy vocabularies for triggers, target roles, state dimensions, transition guards/effects, accessibility effects, timers, focus, keyboard, motion, and responsive mappings. It does not add a source adapter or runtime realization.

Each primitive definition owns its allowed state dimensions, finite domains, initial values, invariants, transitions, target cardinalities, accessibility contract, policies, and cleanup requirements. Validation rejects unknown dimensions, invalid combinations, missing required targets, illegal transitions, and unsupported policy values. It does not guess a nearest valid state. The runtime can emit only a transition that preserves the primitive invariant and its accessibility state in the same semantic outcome.

Required accessibility gates follow the accepted primitive semantics in `docs/09`:

- Disclosure uses native disclosure semantics where they match; links stay usable and expanded state matches content visibility.
- Tabs keep `focused_tab_id` separate from `selected_tab_id`, define automatic or manual activation, map the selected keyboard model, and synchronize tab/panel relationships.
- Accordion defines `single | multiple`, closure rules, heading/button relationships, and any responsive mapping as a reversible state transformation.
- Website disclosure navigation remains separate from ARIA composite menu keyboard/focus semantics.
- Dialog implements actual modality, top-modal Escape handling, initial focus, containment, focus return, nested ownership, background inertness, and scroll-lock cleanup. `aria-modal` alone is insufficient.
- Carousel keeps selected slide, rotation state, focus/hover suspension, controls, and reduced-motion behavior as orthogonal state dimensions. Autoplay is opt-in and must stop on focus/hover according to the accepted policy.
- Lightbox composes the Dialog contract with typed gallery navigation and media accessibility.

No runtime slice passes without keyboard and screen-reader state synchronization review, reduced-motion checks, and browser verification appropriate to the primitive. Pure data validators and serializers do not require browser tests.

## 6. Componentization projection decision

P7-D uses **Option A, a separate `BehaviorProjection` sidecar artifact**. It consumes:

```text
DesignDocument
+ BehaviorContract
+ approved ComponentContract
+ matching ComponentizationPlan
→ BehaviorProjection
```

The projection records the exact DesignDocumentIdentity, BehaviorContract digest, `ComponentContract.contract_id`, and a `componentization_plan_sha256` computed as lowercase SHA-256 of `ComponentizationPlan.encode!` bytes after plan validation. Its plan digest algorithm ID is `lf-componentization-plan-serializer-v1-sha256`. It also records the approved component boundary and maps each BehaviorBinding to its owning contract and plan boundary. It does not copy or reinterpret BehaviorContract state semantics and does not change the public component API. The first implementation permits one binding to be projected wholly within one approved component boundary only. A binding whose owner or controlled target escapes the boundary, or whose behavior spans multiple component boundaries, fails closed with a stable diagnostic. A future cross-boundary capability requires a new typed authority and explicit authorization.

Option A keeps C09D1 `ComponentContract 1.0.0` and C09D3 `ComponentizationPlan 1.0.0` schemas and the accepted static C09D6 path unchanged. Option B would put behavior ownership into placement authority, require ComponentizationPlan format evolution or a tightly constrained optional extension, introduce reader/migration questions, and couple state semantics to a plan whose current purpose is static public-input placement. It would risk making existing static generation depend on behavior data it does not need. Neither schema needs a version change to implement the sidecar.

Projection validation requires all of the following:

1. The BehaviorContract identity matches the exact supplied DesignDocumentIdentity.
2. The ComponentContract and ComponentizationPlan validate under their existing authorities; the plan references that exact contract and existing DesignDocument digest.
3. The ComponentContract is explicitly approved. Behavior review cannot set or imply its approval status.
4. The same shared C09D6 generation prerequisites pass, excluding only final code emission.
5. Every binding owner and controlled target resolves in the exact DesignDocument and lies wholly within one approved component boundary.
6. Every projected binding maps exactly once. Unprojected required behavior, ambiguous ownership, escaped targets, or cross-boundary behavior blocks interactive generation.
7. The projection carries immutable hashes/IDs for the input artifacts. The DesignDocument, BehaviorContract, and plan are checked by exact digest. The component contract is checked by its existing `contract_id`, approval result, intrinsic/reference validation, and shared C09D6 prerequisites; P7 does not invent a competing ComponentContract fingerprint.

DOM proximity, shared classes, matching source IDs, naming similarity, and component-instance DOM layout never prove ownership. Projection does not change `ComponentContract.approval_status`, mutate the plan, or authorize generation by itself.

## 7. Runtime realization and lifecycle ownership

BehaviorContract expresses semantics, not source JavaScript or executable runtime recipes. RuntimeRealization maps a validated projected binding to the least complex platform mechanism that satisfies its semantics, in this order:

1. semantic HTML and CSS;
2. `Phoenix.LiveView.JS`;
3. component-colocated JavaScript;
4. component-colocated hook;
5. shared/global hook;
6. server event;
7. stateful `Phoenix.LiveComponent`.

The selector must explain why lower-cost options cannot satisfy the contract before choosing a more stateful option. Presentation-only transitions have no server round trip. Hooks are used only for browser lifecycle, DOM reconciliation, or platform behavior that native elements and LiveView.JS cannot express. There is no generic event bus, browser-local polling, general `phx-update="ignore"` state retention, or forced-hook implementation for every primitive.

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

The pinned LiveView 1.2.11 hook callbacks (`mounted`, `beforeUpdate`, `updated`, `destroyed`, `disconnected`, and `reconnected`) are the initial hook adapter contract. P7-E must verify those callbacks against the repository's pinned version before implementation. No callback other than actual owner removal may mark the runtime instance destroyed.

## 8. Security and failure handling

Imported JSON, source exports, CSS, JavaScript, PHP, paths, selectors, event names, and module-like strings are untrusted data. The parser and normalizer inspect data only. They never execute or evaluate source scripts, compile source code, import source modules, execute PHP, or follow source-provided paths.

All behavior kinds and runtime capabilities use closed trusted vocabularies. Source-provided arbitrary event names, selectors, key names, module names, effects, or runtime strategy strings are rejected or retained only as inert diagnostic provenance. No untrusted string is converted into an atom, module, executable function, shell argument, or file path. Source HTML is not treated as executable behavior. A source runtime package is not a target dependency merely because the source used it.

The following conditions have deterministic fail-closed outcomes:

| Failure | Required result |
| --- | --- |
| Stale DesignDocument digest or unsupported Design IR version | Reject contract/projection; do not bind to a similar document. |
| Unknown canonicalization or digest algorithm | Reject identity use; no fallback hashing. |
| Duplicate BehaviorBinding payload/ID | Reject conflicting bindings and emit a stable collision diagnostic. |
| Unresolved owner/target node or target outside declared owner subtree | Disable/reject the binding; never use selector fallback. |
| Binding owner/target escapes or crosses approved component boundary | Reject projection and interactive generation. |
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
| Source runtime dependency appears in target dependency graph | Reject the change unless a separate explicit project authority approves it. |
| Component approval is bypassed or BehaviorReview is used as ComponentReview | Block generation using existing C09D6 prerequisites. |

Behavior diagnostics cannot be silently dropped when behavior is omitted. Blocking diagnostics prevent review approval or projection as defined by their stable category and severity. Human review may resolve ambiguous semantics with explicit evidence; it cannot turn unsafe executable input into an accepted runtime instruction.

## 9. Performance and storage classification

P7 behavior state is browser-local unless an accepted semantic contract proves that the server owns the state or command. Classification for P7-A through P7-K:

```text
HOT_CACHE=N/A
REDIS=N/A
POSTGRES=N/A
DB_INDEX=N/A
PGBouncer=N/A
READ_REPLICA=N/A
OBAN=N/A
PUBSUB=N/A unless future server-authoritative behavior requires it
SERVER_POLLING=PROHIBITED for browser-local primitives
```

Browser-local performance goals are O(instances) bounded state, no server trip for presentation-only transitions, no polling, one listener/timer/observer ownership path, idempotent patch reconciliation, complete cleanup, and owner/target-scoped DOM work rather than repeated whole-document scans. Large collections may use typed owner-scoped lookup and stable item keys; they may not trigger document-wide observer scans per item.

Backend scaling becomes relevant only when a future behavior contract explicitly requires shared or durable state, server-authoritative decisions, cross-client synchronization, authorization checks, or a business command. That future issue must separately classify database/cache/index/queue/pubsub needs from the presentation runtime. Redis, Cachex, GenServer, PubSub, or a database are not added to solve ephemeral disclosure, tabs, accordion, dialog, or carousel state.

## 10. Test and review strategy

Every implementation issue follows TDD: add a focused failing test, confirm the failure, implement the smallest slice, run focused checks, then run applicable repository gates. This P7-0 planning change adds no tests and runs no broad Mix or browser suite.

| Slice | Required focused evidence |
| --- | --- |
| P7-A | Golden Design IR bytes and digest remain identical to current `IR.encode!/1` + SHA-256; unknown algorithm rejection; JCS extraction keeps all Catalogue canonical bytes/fingerprints unchanged; structured BehaviorBinding payloads are unambiguous. |
| P7-B | Deterministic BehaviorContract serialization across map insertion orders; golden canonical bytes/digest; diagnostics and provenance alter digest; optional/null/empty rules; exact DesignDocument linkage; malformed value algebra and unresolved references rejected. |
| P7-C | Primitive registry is closed; all primitive cardinalities and state dimensions validate; invalid combinations/transitions reject; trigger/key/effect/policy unknown values reject; accessibility state consistency checks. |
| P7-D | Owner and targets resolve; binding maps once; boundaries are contained; cross-boundary/escaping bindings reject; stale contract/plan/document reject; ComponentReview and shared C09D6 gates remain required. |
| P7-E | Repeated mount/update/reconnect is idempotent; listeners/timers/observers have one owner; unavailable recovers; owner destruction cleans every resource; shared dialog scroll-lock reference counts; no polling or global scans. |
| P7-F | Native details/summary path; usable links; no unnecessary JS; reduced motion; LiveView patch behavior; accessibility state matches open state. Browser verification required for supported browsers. |
| P7-G | Focused and selected tabs differ when manual activation requires it; key model; activation policy; tab/panel ARIA and visibility synchronized; patch/reconnect/cleanup verified in browser. |
| P7-H | `single | multiple` constraints; closure rules; tabs-to-accordion map is reversible; active state survives mode switches without loss or duplication. Browser verification required. |
| P7-I | Disclosure navigation and composite Menu have distinct definitions; usable links; keyboard/focus model matches selected semantics; no arbitrary source event names. Browser verification required. |
| P7-J | Top modal Escape handling; initial/contained/returned focus; nested dialog ownership; background inertness; scroll lock survives competing dialogs and cleans on destruction. Browser verification required. |
| P7-K | Orthogonal selected-slide/rotation/focus-hover/reduced-motion state; opt-in timer; pause/resume rules; timer and observer cleanup; controls and accessibility sync. Browser verification required. |
| P7-L | End-to-end accepted evidence → contract → review → projection → generation prerequisites → realization path; component review cannot be bypassed; generated target has no source runtime dependency. Browser and accessibility evidence only for interactive output. |

Every applicable slice also checks that no imported source code executes, no dynamic atom/module conversion occurs, and no Bricks, Frames, WordPress, ACSS, private vendor code, or unapproved runtime dependency enters the reusable library. Pure serializers and validators do not need browser tests.

## 11. Ordered future issue tree

Every item is **PLANNED — NOT AUTHORIZED**. No GitHub issues are created by P7-0. Each issue is independently reviewable and requires explicit owner authorization before work begins.

| Order | Issue | Scope and required result | Hard gate |
| --- | --- | --- | --- |
| 1 | P7-A — DesignDocument identity and canonical JSON boundary | Extract source-neutral JCS utility while preserving Catalogue outputs; centralize current IR serializer digest in `LiveFrames.IR.Identity`; freeze identity IDs and golden compatibility evidence; implement BehaviorBinding structured identity foundation only. | No changed DesignDocument digest or ComponentizationPlan format. Stop if exact IR byte identity cannot be preserved. |
| 2 | P7-B — BehaviorContract core | Implement `LiveFrames.Behavior` contract, binding, explicit serializer/digest, diagnostics, exact document linkage, and deterministic validator. No source adapter, primitive runtime, or hooks. | Golden serialization/digest and invalid reference tests pass. |
| 3 | P7-C — Primitive registry and semantic state validation | Implement closed definitions and finite state/policy vocabulary for the primitives already listed in `docs/09`; validate invariants, cardinalities, accessibility effects, and transition safety. | No source-defined vocabulary; no realization/runtime. |
| 4 | P7-D — BehaviorProjection sidecar | Validate BehaviorContract + DesignDocument + approved ComponentContract + matching ComponentizationPlan; map each binding wholly to one component boundary. | Static schemas stay 1.0.0; all existing C09D6 prerequisites and ComponentReview remain mandatory. |
| 5 | P7-E — Runtime realization and lifecycle foundation | Add typed realization selection, instance lifecycle, scoped resource ownership, patch reconciliation, disconnect/reconnect, unavailable recovery, and destruction cleanup. | No primitive-specific browser runtime before lifecycle/idempotency evidence passes. |
| 6 | P7-F — Disclosure tracer / Slide Menu Alpha | Convert the approved disclosure behavior to native details/summary where semantics match; prove usable links, accessibility, reduced motion, patch behavior, and no needless JS. | First real runtime tracer; no menu semantics inferred from disclosure navigation. |
| 7 | P7-G — Tabs | Implement tabs with separate focus/selection, automatic/manual activation, keyboard model, patch reconciliation, and cleanup. | Browser and accessibility review pass. |
| 8 | P7-H — Accordion and responsive tabs/accordion | Implement single/multiple accordion rules and reversible tabs-to-accordion state mapping. | State survives responsive transitions with no loss or duplication. |
| 9 | P7-I — Disclosure popup and menu | Implement website disclosure navigation separately from ARIA composite menu behavior. | Primitive choice follows observed semantics and keyboard needs. |
| 10 | P7-J — Dialog and lightbox | Implement modal lifecycle, focus containment/return, Escape stack, background inertness, scroll-lock ownership, and lightbox composition. | Nested/shared cleanup and accessibility tests pass. |
| 11 | P7-K — Carousel | Implement orthogonal selection and rotation dimensions, controls, timer eligibility, pause rules, reduced motion, and cleanup. | Dependency choice is downstream; no carousel package selected as the semantic starting point. |
| 12 | P7-L — Broader conversion integration | Integrate approved source evidence normalizers and generated behavior paths across supported patterns; preserve all review/projection/runtime gates. | Separate source-adapter and end-to-end scope review; no bypass of accepted authorities. |

P7-0 authorizes none of P7-A through P7-L. Approval of this plan authorizes only issue creation as a later separately requested action. Approval of any issue does not authorize its successor.

## 12. TOON micro-prompts

Each prompt is one future implementation task. Every task remains **PLANNED — NOT AUTHORIZED** until the owner authorizes that issue.

### P7-A — DesignDocument identity and canonicalization

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Centralize DesignDocument identity and extract the tested JCS encoder behind a source-neutral canonical JSON module. |
| Objective | Preserve the exact `LiveFrames.IR.encode!/1` SHA-256 used by componentization, expose a named identity algorithm, and let Behavior use the same restricted canonical JSON value algebra without depending on Catalogue. |
| Output    | `apps/live_frames/lib/live_frames/ir/identity.ex`; `apps/live_frames/lib/live_frames/canonical_json.ex`; compatibility delegation from `apps/live_frames/lib/live_frames/componentization_plan.ex` and `apps/live_frames/lib/live_frames/catalogue/canonical_json.ex`; focused identity/JCS tests and golden fixtures. |
| Note      | No schema or digest changes. Preserve Catalogue fingerprint bytes and current `ComponentizationPlan.design_document_sha256/1` results. Reject unsupported algorithms and floats in JCS values. No cache, TTL, Redis, DB, PubSub, browser runtime, or source dependencies. STOP if current IR bytes cannot be kept stable. |

### P7-B — BehaviorContract core

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Implement the versioned BehaviorContract, BehaviorBinding identity, serializer, digest, diagnostics, and exact DesignDocument linkage. |
| Objective | Create a deterministic source-neutral semantic artifact that can be validated and reviewed before primitive runtime or component ownership exists. |
| Output    | Focused modules under `apps/live_frames/lib/live_frames/behavior/` for contract, binding, identity payload, serializer, diagnostic, and validation; tests for canonical bytes/digest, optional values, references, IDs, and diagnostics/provenance participation. |
| Note      | Keep Design IR 3.x separate and `IR.Interaction` intent-only. Use only safe JCS values and closed string vocabularies. No source adapter, hooks, source runtime, Redis, DB, cache, timer, or browser dependency. STOP on identity or serialization ambiguity. |

### P7-C — Primitive registry and semantic validation

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Add the closed primitive definitions and state/policy validation specified by `docs/09_INTERACTION_MODEL.md`. |
| Objective | Reject unsupported primitives, cardinalities, state combinations, transitions, and accessibility inconsistencies before runtime selection. |
| Output    | Trusted primitive registry and focused definitions/validation under `apps/live_frames/lib/live_frames/behavior/`; tests for all admitted state invariants, target roles/cardinality, closed triggers/keys/effects, and accessibility synchronization. |
| Note      | Implement only Disclosure, Accordion, Tabs, Disclosure Popup, Menu, Dialog, Carousel, and Lightbox semantics already accepted. No source-defined types, source adapter, JavaScript, hooks, cache, TTL, Redis, DB, PubSub, or server polling. |

### P7-D — BehaviorProjection sidecar

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Project validated BehaviorBindings onto approved component boundaries through a separate BehaviorProjection artifact. |
| Objective | Freeze and enforce behavior ownership without changing ComponentContract 1.0.0 or ComponentizationPlan 1.0.0. |
| Output    | Projection model, serializer, and validator under `apps/live_frames/lib/live_frames/behavior/`; tests for exact input matching, one-to-one binding mapping, owner/target containment, stale artifacts, and cross-boundary rejection. |
| Note      | Require approved ComponentContract, matching plan, exact DesignDocument, BehaviorReviewResult, and existing C09D6 prerequisites. Reject escaping/cross-boundary behavior. No DOM proximity/class/source-ID ownership, schema bump, cache, Redis, DB, PubSub, or runtime code. |

### P7-E — Runtime realization and lifecycle foundation

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Implement typed realization selection and the shared browser runtime instance lifecycle after projection is accepted. |
| Objective | Provide idempotent mount, patch reconciliation, disconnect/reconnect, recoverable unavailable state, resource ownership, and terminal destruction before primitive hooks exist. |
| Output    | Runtime realization selector and lifecycle/resource ownership modules in the approved behavior/runtime boundary; tests for repeated reconciliation, cleanup, stable repeated keys, shared scroll lock, and pinned LiveView 1.2.11 callback behavior. |
| Note      | Prefer semantic HTML/CSS, then LiveView.JS, colocated JS, colocated hook, shared hook, server event, LiveComponent. No generic event bus, polling, general `phx-update="ignore"`, duplicate listeners/timers/observers, Redis, DB, cache, or server round trip for local presentation. |

### P7-F — Disclosure tracer / Slide Menu Alpha

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Implement the first approved disclosure conversion tracer using native details/summary when its semantics fit. |
| Objective | Prove the end-to-end contract and projection path with usable navigation, accessible open state, reduced-motion behavior, and minimal runtime. |
| Output    | Disclosure realization and native component/story evidence in the authorized locations; focused unit, LiveView patch, browser, keyboard, and accessibility tests. |
| Note      | Do not infer ARIA menu semantics from website navigation. Keep links usable. No JavaScript when native semantics suffice, no source runtime, polling, Redis, DB, or generic hook. |

### P7-G — Tabs

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Implement the Tabs primitive with explicit manual or automatic activation. |
| Objective | Prove separate focused and selected state, keyboard navigation, accessible relationships, and correct patch/runtime cleanup. |
| Output    | Tabs state validation and native LiveView realization; tests for activation modes, focus/selection separation, ARIA synchronization, patch/reconnect, cleanup, and supported-browser behavior. |
| Note      | Keep focused and selected tab IDs distinct. No server round trip for local selection, no timer by default, no source event strings, cache, Redis, DB, or PubSub. |

### P7-H — Accordion and responsive tabs/accordion

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Implement Accordion rules and reversible responsive tabs-to-accordion state mapping. |
| Objective | Preserve valid selection/open state when a responsive mode changes without losing or duplicating user state. |
| Output    | Accordion state model and responsive mapping implementation; tests for `single | multiple`, closure rules, reversible mappings, mode changes during activity, and browser accessibility. |
| Note      | Use only accepted breakpoint authority and a reversible mapping. Invalid mappings diagnose and fail closed. No source selector, global scan, cache, Redis, DB, PubSub, or polling. |

### P7-I — Disclosure popup and menu

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Implement disclosure popup navigation and composite menu as separate behavior primitives. |
| Objective | Keep ordinary website links and disclosure controls distinct from command-menu focus and keyboard behavior. |
| Output    | Separate validated primitive definitions and realizations; tests for links, expanded state, menu keyboard/focus movement, classification, patch cleanup, and browser accessibility. |
| Note      | Default website navigation to disclosure semantics unless evidence establishes menu behavior. Never translate arbitrary source event/listener names. No polling, cache, Redis, DB, or generic event bus. |

### P7-J — Dialog and lightbox

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Implement Dialog lifecycle and Lightbox composition on the validated Dialog behavior. |
| Objective | Provide real modality, safe focus ownership, correct Escape behavior, collection navigation, and complete nested cleanup. |
| Output    | Dialog and Lightbox realizations; tests for top-modal Escape, initial/contained/returned focus, removed focus targets, nested instances, background inertness, reference-counted scroll lock, and browser accessibility. |
| Note      | `aria-modal` alone is insufficient. Shared scroll locks require scoped tokens/reference counting. No dialog process, global unowned state, cache, Redis, DB, or source media runtime. |

### P7-K — Carousel

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Implement Carousel with orthogonal slide selection, rotation, focus/hover suspension, and motion state. |
| Objective | Support accessible controls and opt-in autoplay with predictable reduced-motion, pause/resume, and cleanup behavior. |
| Output    | Carousel state model, timer policy realization, controls, and browser/accessibility tests for selection, rotation, focus/hover, reduced-motion changes, and destruction. |
| Note      | Choose any external dependency only after semantics and cleanup are proven. Timers are browser-local, bounded, and destroyed with their owner. No polling, default autoplay, Redis, DB, cache, or per-carousel server process. |

### P7-L — Broader conversion integration

| Field     | Content |
|-----------|---------|
| Task      | **PLANNED — NOT AUTHORIZED** Integrate reviewed source behavior evidence with the accepted contract, projection, runtime, component review, and native generation gates across supported patterns. |
| Objective | Extend from validated tracers to broader source conversion without bypassing source-neutral normalization or accepted C09D authorities. |
| Output    | Separately approved adapter integration, deterministic fixtures, end-to-end conversion tests, generated native artifacts, and browser/accessibility evidence for each admitted pattern. |
| Note      | Scope each source adapter separately. Imported scripts remain inert evidence. Component approval and review cannot be bypassed. No private/vendor runtime, generic event bus, schema change, DB/cache/Redis/PubSub unless a separate server-authoritative requirement proves it necessary. |

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
- [x] Primitive registry boundary
- [x] Componentization projection architecture
- [x] Runtime realization boundary
- [x] Runtime lifecycle ownership
- [x] Security model
- [x] Accessibility gates
- [x] Performance classification
- [x] Test strategy
- [x] Ordered implementation issue tree
- [x] TOON micro-prompts
- [x] Explicit future authorization boundaries
