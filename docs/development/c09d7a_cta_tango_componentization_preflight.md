# C09D7-A0: CTA Tango componentization preflight

## 1. Objective and non-goals

This preflight records source identity, deterministic normalized Design IR facts, and every first-wave semantic decision that an owner must make before constructing `ComponentizationSemanticInput`.

A0 does not freeze semantic input, call `ComponentizationProposer`, create a `ComponentContract` or `ComponentizationPlan`, approve a contract, generate HEEx or CSS, start C09D7-B, or inspect or implement Behavior/P7. No source plugin code was executed. The source artifact was read as JSON data only.

Static copy is represented below by normalized kind, presence, and UTF-8 byte length. No literal copy, source class, source editor label, source trace, proprietary CSS, or private file content is included.

## 2. Accepted authority chain

- D1 is accepted by PR #163, merged as `652a275b7f8cfb3a2dc2bae9818a61083074296c`; exact-merge CI run `37975316155` passed.
- The accepted current base is `a2bfee2baefbebacd570be1f59df7f82336c83af`, tree `0388b1a415a022a45f72f150e5e7b9b54e1a9274`; current-main CI run `37975332147` passed on that SHA.
- Issue #129 is closed. Issue #130 remains open and retains its historical dependency text. This A0 work does not mutate either issue.
- Relevant repository authority is recorded in `docs/development/c09d1_component_contract_authority.md`, `docs/development/c09d3_componentization_plan_authority.md`, `docs/development/c09d5_componentization_proposer_authority.md`, and `docs/development/c09d6_native_generation_authority.md`.
- The proposer cannot invent `contract_id`, category, module or function intent, public attr or slot names, boundary, defaults, accessibility policy, render placement, or static-content promotion. Every such choice remains an explicit A1 owner decision.

## 3. Source artifact identity

The one canonical source artifact was read from the user-provided local reference directory at the accepted relative identity:

`private_reference/frames/staging-2026-09/cta-section-tango/bricks-component-hxambs-cta-section-tango.json`

| Fact | Verified value |
| --- | --- |
| SHA-256 | `73f866a27070c010584babe230b5ffd0c78dc704388fd8b6c286e149a3d93a87` |
| Bytes | `10224` |
| Component ID in source | `hxambs` |
| Element count | `15` |
| Global class count | `13` |
| Parent Frames corpus digest | `074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e` |

The hash and counts match the accepted identity. No alternate export or envelope fixture was used.

## 4. Deterministic DesignDocument reproduction

Two independent constructions in one `mix run --no-start` invocation read and decode the canonical artifact separately. Each loaded `fixtures/automatic_css/acss_settings.json` with `LiveFrames.Adapters.AutomaticCSS.from_file/2`, source version `4.0.1`, `strict: true`, and profile `:hero_foundation`. Both used the accepted ACSS 4.0.1 structural-variable authority and passed the component fragment to `LiveFrames.Adapters.Bricks.to_ir/2` with component ID `hxambs`.

Both documents passed `LiveFrames.IR.validate/1`. Their `LiveFrames.IR.encode!/1` bytes matched, as did `LiveFrames.ComponentizationPlan.design_document_sha256/1`. A comparison against the accepted R5 in-memory settings normalization produced the same TokenSet and document digest.

No adapter behavior was changed. No raw `_cssCustom` data was interpreted for new meaning. The final inventory counts are computed in one canonical traversal per reproduced document.

## 5. DesignDocument identity

```ini
DESIGN_DOCUMENT_SHA256=4b90b3ce32f8fcec640cea40499e861951137e3c2466931ead3c4436e2c6c9c5
DESIGN_DOCUMENT_REPRODUCTION=DETERMINISTIC
IR_VALIDATION=PASS
ROOT_NODE_COUNT=1
TOTAL_NODE_COUNT=15
BINDING_COUNT_BY_KIND=value=0, collection=0
RESPONSIVE_OVERRIDE_COUNT=5 style-property overrides
BASE_STYLE_PROPERTY_COUNT=55
```

The single root makes the document single-root. No `evidence_insufficient` binding exists because the document has no value or collection bindings.

## 6. Canonical boundary and tree inventory

Canonical Design IR paths are non-empty lists of positive integers. Indexing is one-based across `DesignDocument.root_nodes` and recursively across every `DesignNode.children` list. These are the same positional paths consumed by `LiveFrames.IR.DesignNode.deterministic_id/1`. Normalized semantic kind and tag are reported separately and are not part of canonical path identity. `node_id` values are Design IR deterministic IDs, not source element IDs. A dash means the corresponding normalized fact is absent. “Compound” marks a node with more than one child, a mechanical candidate for style-locus review. It does not accept a component boundary.

| Canonical Design IR path | Design IR node ID | Kind / normalized tag | Children | Bindings on node | Static content | Accessibility semantics | Native-generation eligibility | Compound structure |
| --- | --- | --- | ---: | --- | --- | --- | --- | --- |
| `[1]` | `node_000001` | section | 1 | none | absent | N/A | unknown before Contract + Plan | no |
| `[1, 1]` | `node_000001_000001` | container | 2 | none | absent | N/A | unknown before Contract + Plan | yes |
| `[1, 1, 1]` | `node_000001_000001_000001` | generic | 1 | none | absent | N/A | unknown before Contract + Plan | no |
| `[1, 1, 1, 1]` | `node_000001_000001_000001_000001` | generic | 3 | none | absent | N/A | unknown before Contract + Plan | yes |
| `[1, 1, 1, 1, 1]` | `node_000001_000001_000001_000001_000001` | generic | 1 | none | absent | N/A | unknown before Contract + Plan | no |
| `[1, 1, 1, 1, 1, 1]` | `node_000001_000001_000001_000001_000001_000001` | image / figure | 0 | none | absent | no normalized alt | unknown before Contract + Plan | no |
| `[1, 1, 1, 1, 2]` | `node_000001_000001_000001_000001_000002` | generic | 1 | none | absent | N/A | unknown before Contract + Plan | no |
| `[1, 1, 1, 1, 2, 1]` | `node_000001_000001_000001_000001_000002_000001` | image / figure | 0 | none | absent | no normalized alt | unknown before Contract + Plan | no |
| `[1, 1, 1, 1, 3]` | `node_000001_000001_000001_000001_000003` | generic | 1 | none | absent | N/A | unknown before Contract + Plan | no |
| `[1, 1, 1, 1, 3, 1]` | `node_000001_000001_000001_000001_000003_000001` | image / figure | 0 | none | absent | no normalized alt | unknown before Contract + Plan | no |
| `[1, 1, 2]` | `node_000001_000001_000002` | generic | 4 | none | absent | N/A | unknown before Contract + Plan | yes |
| `[1, 1, 2, 1]` | `node_000001_000001_000002_000001` | heading / h2 | 0 | none | present, 49 bytes | N/A | unknown before Contract + Plan | no |
| `[1, 1, 2, 2]` | `node_000001_000001_000002_000002` | paragraph / p | 0 | none | present, 14 bytes | N/A | unknown before Contract + Plan | no |
| `[1, 1, 2, 3]` | `node_000001_000001_000002_000003` | rich_text | 0 | none | present, 236 bytes | N/A | unknown before Contract + Plan | no |
| `[1, 1, 2, 4]` | `node_000001_000001_000002_000004` | button | 0 | none | present, 14 bytes | N/A | unknown before Contract + Plan | no |

## 7. Binding and asset inventory

The DesignDocument has zero value bindings and zero CollectionBinding records. Binding counts by kind are therefore empty; no binding IDs or kinds attach to any node. There are no `evidence_insufficient` bindings.

Three normalized image asset records exist:

| Asset ID | Kind | Normalized resolution | URI present | Alt present |
| --- | --- | --- | --- | --- |
| `asset_000001` | image | unresolved | no | no |
| `asset_000002` | image | unresolved | no | no |
| `asset_000003` | image | unresolved | no | no |

These are static asset references, not binding-backed images. The IR contains no normalized source URI or accessibility text for them. No source URL or source metadata is copied into this report.

## 8. Static-only and behavior exclusion proof

The normalized document has zero interactions, zero value bindings, zero collection bindings, and no repeated collection structure. The only semantic leaves are static heading, paragraph, rich-text, button, and image records. No tabs, carousel or slider state, modal state, timers, observers, client runtime JavaScript, query execution, or source plugin runtime is represented or needed for this static tracer.

The CTA node is a normalized `button`, not a `link`. Its normalized attributes contain only `style`; neither `navigation` nor `href` exists, and it has zero interaction references. Therefore no normalized CTA destination exists to assign. The preflight does not infer one from unnormalized source fields.

```ini
BEHAVIOR_IR_REQUIRED=NO
QUERY_RUNTIME_REQUIRED=NO
COLLECTION_BINDINGS=0
EVIDENCE_INSUFFICIENT_BINDINGS=0
```

## 9. Semantic-decision-family matrix

Recommendations below are source-independent proposals for A1 review. None is accepted authority. Every applicable family marked for owner review must be frozen explicitly before proposer execution.

| Decision family | APPLICABLE | MECHANICAL_IR_FACTS | EXISTING_AUTHORITY | OWNER_DECISION_REQUIRED | RECOMMENDED_SOURCE_INDEPENDENT_DECISION | ALTERNATIVES | RISK_IF_WRONG | BLOCKER |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ContractIdentityDecision | YES | One static section; no bindings | C09D1 identity schema | YES | Choose a package-owned ID; do not derive it from source IDs or names | CTA section / content section identity | Source leakage or ID collision | A1 must choose an ID |
| ClassificationDecision | YES | One section root; static text, button, and image content | C09D1 classification fields | YES | Classify only after the reusable product role is stated | Static CTA section / broader content section | Wrong reuse boundary or behavior promise | A1 must choose category and intents |
| BoundaryDecision | YES | One root; 15 nodes; nested image and copy groups | Design IR tree; C09D3 boundary linkage | YES | Consider the root section as the complete boundary candidate | Root section / inner container / split subtrees | Omitted content or an overly broad API | A1 must accept one boundary |
| PublicAttrDecision | YES | Four static literals; no normalized CTA destination | C09D1 attr schema; no CTA attr authority | YES | Keep literals internal unless consumers need named variation | Heading, paragraph, rich-text, or label attrs | Copy-bound API or missing variation | A1 must decide each public attr |
| PublicSlotDecision | YES | One rich_text literal and three other static text nodes | C09D1 slot schema | YES | Keep static content internal unless composition requires replacement | Rich-text slot / other named slot / no slots | Unneeded flexibility or locked composition | A1 must decide slot names and scope |
| CollectionAdmissionDecision | NO | Zero CollectionBinding records | C09A and C09C2 collection rules | NO | Admit no collection | Future collection only with new evidence | Invented runtime data model | None in A0 |
| ItemFieldDecision | NO | No collection or item records | C09A and C09C2 binding rules | NO | Define no item fields | Future fields after collection evidence | Invented item schema | None in A0 |
| CollectionCountLinkDecision | NO | No collection, count, or link binding | C09A and C09C2 binding rules | NO | Define no count-link relationship | Future explicit count link | False count or link behavior | None in A0 |
| BindingAssignmentDecision | NO | Zero value and collection bindings | C09B and C09C2 binding authority | NO | Assign no bindings | Future explicit assignments from normalized evidence | Invented data flow | None in A0 |
| RenderPlacementDecision | YES | 15-node tree; three images; four static text records; no destination | C09D3 plan roles; C09D6 boundary-scoped generation checks | YES | Map only supported existing roles after A1; do not accept placements in A0 | Static content roles / asset roles / link role only if later evidence exists | Missing content or invented rendering | A2 must validate the selected roles |
| ImageAccessibilityDecision | YES | Three unresolved image assets; no URI or alt | C09D1 evidence and C09D6 generation authority | YES | Require an explicit informative or decorative decision per image | Alt text / decorative image / exclude pending evidence | Inaccessible or misleading output | A1 must decide all three |
| EvidenceHandlingDecision | YES | IR provenance exists; source detail is excluded from this report | C09D1 provenance and C09D5 proposer authority | YES | Keep source-specific traces private; expose no source class, source ID, or trace as API | Private evidence reference / no persisted trace | Source leakage or weak auditability | A1 must choose evidence references |
| StaticContentDispositionDecision | YES | Heading 49 bytes; paragraph 14; rich text 236; button label 14; all literal | Design IR content model; C09D1 public API rules | YES | Retain as internal static content unless variation is a stated product need | Internal literals / public attrs / rich-text slot | Unwanted public copy API or non-reusable component | A1 must decide disposition per node |

## 10. CTA-specific decision questions

- **Boundary.** The sole normalized root is a section at canonical Design IR path `[1]`. Inner candidates include the two-child container, three-image group, and four-child copy group. A1 must choose the boundary; A0 accepts none.
- **Visible text.** The IR has one `h2` heading (49 bytes), one `p` paragraph (14 bytes), one `rich_text` node (236 bytes), and one button label (14 bytes). There is no separate normalized accent or eyebrow role. The paragraph could be considered for that role, but the IR does not assign it. The heading is the primary-heading candidate by normalized type. No literal is reproduced.
- **Internal content or API.** All four text records can remain internal static content. Heading, paragraph, and button label could be attrs if consumers need variation. The rich-text node could remain internal or become a slot if composition requires it. A1 must choose.
- **CTA structure and destination.** The normalized CTA is a `button`; it is not a normalized `link` and has no `navigation`, `href`, or interaction reference. No normalized destination data exists.
- **Images.** There are exactly three image nodes, each with one unresolved static asset reference and no URI or alt. None is binding-backed. A1 must decide informative versus decorative use for each; the artifact does not settle that choice.
- **Collections and insufficient evidence.** There are no CollectionBinding records and no bindings marked `evidence_insufficient`.

## 11. Risks and authority gaps

- The normalized tree supports a single-root boundary, but the public component boundary remains an A1 decision.
- The normalized paragraph has no explicit eyebrow role. Assigning it one would be a product decision, not an IR fact.
- The button has no normalized destination. Adding one would require new evidence or an explicit owner decision; it cannot be inferred by the proposer.
- Image purpose and alt policy are absent. A1 must not silently classify all three as decorative or informative.
- Static copy is present in the IR but remains private evidence. A1 must decide whether any text becomes a public attr or slot.
- Native-generation eligibility is not known node-by-node before a Contract and Plan exist. Existing render roles include text content, asset source/alt, link URL, heading level, root identity/class/attrs, and subtree slot. A0 shows no required new render role, but A2 must validate actual placements and generation prerequisites.
- No public API name or semantic value has been accepted in A0.

## 12. Performance and scaling review

This is a cold compile-time evidence path. Normalization and the canonical tree traversal are O(nodes + bindings + styles + responsive records). The two required independent reproductions each perform one traversal to derive the inventory facts.

```ini
DATA_LAYER=COLD_BUILD_TIME
HOT_DATA=N/A
WARM_DATA=N/A
REDIS=N/A
CACHE_TTL=N/A
POSTGRES=N/A
DB_INDEXES=N/A
PGBouncer=N/A
READ_REPLICAS=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
CDN=N/A

100K_RUNTIME_CONCURRENCY=N/A
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
RUNTIME_CSS_GENERATION=0

FILESYSTEM_DISCOVERY=NO
PRIVATE_SOURCE_READ=EXPLICIT_SINGLE_FILE_ONLY
```

## 13. Verdict

```text
READY_FOR_SEMANTIC_DECISION_FREEZE
```

This verdict means the normalized facts are sufficient for the owner and reviewer to freeze explicit semantic decisions. It does not mean semantic input is accepted, the proposer passed, a Contract or Plan was proposed or approved, C09D7-A is complete, or C09D7-B is authorized.

## 14. Exact next step

Run C09D7-A1 as a review-only semantic decision freeze. The owner should decide contract identity, classification and intents, boundary, public attrs and slots, image accessibility, evidence handling, static-content disposition, and render placements. Record the explicit `ComponentizationSemanticInput` only after those decisions are accepted.

After A1 is accepted, A2 may run the frozen input through `ComponentizationProposer`. Do not call the proposer with these recommendations or begin C09D7-B.

## Lifecycle model

### Evidence and preflight lifecycle

```text
source_identity_pending
→ source_identity_verified
→ ir_reproduced
→ ir_validated
→ decision_inventory_complete
→ ready_for_semantic_decision_freeze
```

Failure terminals:

```text
source_identity_blocked
ir_reproduction_blocked
authority_blocked
behavior_blocked
```

### Future proposer lifecycle, not executed in A0

```text
semantic_input_frozen
→ proposer_called
→ proposed
| needs_review
| invalid_input
| construction_failed
```

### Future contract review lifecycle, not executed in A0

```text
proposed → approved
proposed → rejected

needs_review
→ revised semantic decisions / new proposal
→ proposed | needs_review

needs_review → rejected
```

There is no direct `needs_review → approved` transition. The Plan has no independent approval state.

## Validation record

- Deterministic reproduction: pass; both IR documents validated and encoded identically.
- Focused regressions: `mix test apps/live_frames/test/live_frames/bricks_design_ir_test.exs apps/live_frames/test/live_frames/componentization_proposer_semantic_input_test.exs` passed, 82 tests, 0 failures.
- The Bricks test file skipped its two private-reference proof assertions because the checkout-relative private artifact is absent. The separate A0 reproduction read the exact matching artifact from the user-provided path.
- `mix deps.get` completed with the existing lockfile; no dependency change was made.
- `git diff --check` is the final whitespace gate. Full local umbrella gates are not required for this docs-only evidence slice; PR CI must run the normal full quality workflow.
