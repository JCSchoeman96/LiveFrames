# Feature Milan IR4 componentization semantic-input preflight

## Status and scope

**TERMINAL_STATE=A0_REVIEW_READY**

| Gate | Result |
| --- | --- |
| A0 review ready | yes |
| A1 SemanticInput frozen or created | no |
| Real Milan D0 executed | no |
| Behavior componentization decision proposed | no |
| Component proposer executed | no |
| ComponentContract or ComponentizationPlan created | no |
| ComponentReview, P7-D1, P7-E, runtime started | no |
| Private source executed | no |

This record completes the A0 mechanical and authority preflight. Candidate semantic directions are recommendations only. This record does not accept an owner decision or authorize a later stage.

## Accepted base and exact tuple

| Field | Accepted value |
| --- | --- |
| BASE_SHA | ed3ea9c14738551c867a5264a8b1576947d85e4c |
| BASE_TREE | 0bb4a6244f038879c1241ec459e4bd700dc584e6 |
| BASE_CI_RUN / RESULT | 38555185035 / success |
| IR_VERSION | 4.0.0 |
| CANONICALIZATION_ID | lf-ir-serializer-v1 |
| DESIGN_DOCUMENT_DIGEST_ALGORITHM | sha-256 |
| DESIGN_DOCUMENT_DIGEST | 52544dcc0d279d91d3d56d054c9785b18f96e77a5520b782726b678c404db864 |
| IR4_IDENTITY_MATCH | yes |
| CANONICAL_BYTES_LENGTH | 387432 |
| BINDING_ID | bnd_caf04646aa92bbf2026ec3a2a1298a448ab03c624d27519c0740f874e64d22a7 |
| BEHAVIOR_CONTRACT_DIGEST | 303273984f180ea671ba968c841672603f0a0604368385b8f295e1cfcc64f826 |
| BEHAVIOR_REVIEW_ID | brv_5159f503fec2bb56c416642e6ea2151c402a2d9a70670d50b9fe153d5dd62e1d |
| REVIEW_APPROVED_GATE | PASS |

origin/main matched the accepted SHA and tree before analysis. The private Milan artifact SHA-256 is f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132. ACSS_FIXTURE_PATH=fixtures/automatic_css/acss_settings.json. Its SHA-256 is 19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05.

The accepted invocation uses SOURCE_ARGUMENT_FORM=file_path and loads the ACSS file with source_version 4.0.1, source_version_status fixture_reference, strict true, and profile hero_foundation. It passes the Milan file path, component_id ybsqrl, and resulting token set to Bricks.to_ir/2, with no other Bricks options. STRUCTURAL_VARIABLE_AUTHORITY_OPTION=omitted; THEME_STYLES_OPTION=omitted; EXTERNAL_CLASS_AUTHORITIES_OPTION=omitted; CONTAINER_WIDTH_OPTION=omitted. No other Bricks options are supplied. The effective structural-variable authority is the empty default struct. The document passes IR.validate/1; IR.encode!/1 produces 387432 bytes; IR.Identity.from_document/1 matches the exact accepted identity above. No alternate normalization options were tried.

The accepted IR4 BehaviorContract was reconstructed from its merged canonical authority and validated with Behavior.Validation.validate/2 against this replayed document. Its digest matched. The accepted BehaviorReviewResult was reconstructed from its merged canonical record; ReviewResult.validate/1, exact-contract matching, ReviewResult.id/1, and the singleton approved gate all passed. Every owner, trigger, and controlled-target DesignNode reference exists in the replay.

## Normalized DesignDocument inventory

| Measurement | Value |
| --- | ---: |
| ROOT_NODE_COUNT | 1 |
| TOTAL_NODE_COUNT | 17 |
| INTERACTION_COUNT | 0 |
| COLLECTION_BINDING_COUNT | 2 |
| VALUE_BINDING_COUNT | 4 |
| RESPONSIVE_OVERRIDE_COUNT | 3 |
| STATIC_CONTENT_NODE_COUNT | 2 |
| ASSET_REFERENCE_COUNT | 0 |
| IMAGE_DESIGN_NODE_COUNT | 2 |
| IMAGE_SOURCE_BINDING_COUNT | 2 |
| IMAGE_ALT_BINDING_COUNT | 0 |
| TOTAL_DIAGNOSTICS | 29 |
| ERROR_DIAGNOSTICS | 0 |
| FATAL_DIAGNOSTICS | 0 |
| DIAGNOSTIC_SEVERITY_COUNTS | warning: 29 |

All 29 diagnostics have warning severity.

| Diagnostic code | Count |
| --- | ---: |
| bricks.attribute.unsupported | 3 |
| bricks.breakpoint.unresolved | 6 |
| bricks.collection.boundary_unproven | 1 |
| bricks.element.unsupported | 1 |
| bricks.runtime.unsupported | 1 |
| bricks.setting.unsupported | 9 |
| bricks.variable.unresolved | 8 |

The following tree reports normalized DesignNode IDs only. Static values are omitted.

| DesignNode ID | Parent | Depth | Normalized kind | Children | Static content | Responsive overrides |
| --- | --- | ---: | --- | ---: | --- | ---: |
| node_000001 | — | 0 | section | 2 | no | 0 |
| node_000001_000001 | node_000001 | 1 | container | 2 | no | 1 |
| node_000001_000001_000001 | node_000001_000001 | 2 | generic | 2 | no | 0 |
| node_000001_000001_000001_000001 | node_000001_000001_000001 | 3 | generic | 2 | no | 0 |
| node_000001_000001_000001_000001_000001 | node_000001_000001_000001_000001 | 4 | heading | 0 | yes | 0 |
| node_000001_000001_000001_000001_000002 | node_000001_000001_000001_000001 | 4 | rich_text | 0 | yes | 0 |
| node_000001_000001_000001_000002 | node_000001_000001_000001 | 3 | generic | 1 | no | 0 |
| node_000001_000001_000001_000002_000001 | node_000001_000001_000001_000002 | 4 | generic | 2 | no | 0 |
| node_000001_000001_000001_000002_000001_000001 | node_000001_000001_000001_000002_000001 | 5 | heading | 0 | no | 0 |
| node_000001_000001_000001_000002_000001_000002 | node_000001_000001_000001_000002_000001 | 5 | generic | 2 | no | 0 |
| node_000001_000001_000001_000002_000001_000002_000001 | node_000001_000001_000001_000002_000001_000002 | 6 | paragraph | 0 | no | 0 |
| node_000001_000001_000001_000002_000001_000002_000002 | node_000001_000001_000001_000002_000001_000002 | 6 | generic | 1 | no | 1 |
| node_000001_000001_000001_000002_000001_000002_000002_000001 | node_000001_000001_000001_000002_000001_000002_000002 | 7 | image | 0 | no | 0 |
| node_000001_000001_000002 | node_000001_000001 | 2 | generic | 1 | no | 1 |
| node_000001_000001_000002_000001 | node_000001_000001_000002 | 3 | generic | 1 | no | 0 |
| node_000001_000001_000002_000001_000001 | node_000001_000001_000002_000001 | 4 | image | 0 | no | 0 |
| node_000001_000002 | node_000001 | 1 | unsupported | 0 | no | 0 |

### Static content

| DesignNode ID | Semantic kind | Present | UTF-8 bytes |
| --- | --- | --- | ---: |
| node_000001_000001_000001_000001_000001 | heading | yes | 43 |
| node_000001_000001_000001_000001_000002 | rich_text | yes | 236 |

Neither literal is included. Both are static content rather than binding-driven values.

### CollectionBindings

The two bindings are independent top-level collections with no parent collection. Their owners and repeat roots coincide in this document.

| CollectionBinding ID | Owner / repeat root | Parent collection | Relevant normalized subtree |
| --- | --- | --- | --- |
| cb_node_000001_000001_000001_000002_000001 | node_000001_000001_000001_000002_000001 | nil | node_000001_000001_000001_000002_000001; node_000001_000001_000001_000002_000001_000001; node_000001_000001_000001_000002_000001_000002; node_000001_000001_000001_000002_000001_000002_000001; node_000001_000001_000001_000002_000001_000002_000002; node_000001_000001_000001_000002_000001_000002_000002_000001 |
| cb_node_000001_000001_000002_000001 | node_000001_000001_000002_000001 | nil | node_000001_000001_000002_000001; node_000001_000001_000002_000001_000001 |

The normalized diagnostic bricks.collection.boundary_unproven refers to an occurrence whose source element identifier is 05e604. It has no CollectionBinding. This identifier is evidence only; it is not a public collection or a Selection target.

### ValueBindings

The value_key column reports normalized binding semantics, not proposed public names.

| ValueBinding ID | Owner / target DesignNode | Target kind | Value kind | Scope | CollectionBinding ID | Value key | Modifier | Normalization status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| vb_node_000001_000001_000001_000002_000001_000001_text_000001 | node_000001_000001_000001_000002_000001_000001 | text | field | collection_item | cb_node_000001_000001_000001_000002_000001 | content.title | none | normalized |
| vb_node_000001_000001_000001_000002_000001_000002_000001_text_000001 | node_000001_000001_000001_000002_000001_000002_000001 | text | field | collection_item | cb_node_000001_000001_000001_000002_000001 | content.body | word_limit, arguments {"count":16}; modifier status resolved | normalized |
| vb_node_000001_000001_000001_000002_000001_000002_000002_000001_asset_000001 | node_000001_000001_000001_000002_000001_000002_000002_000001 | asset | field | collection_item | cb_node_000001_000001_000001_000002_000001 | media.primary | none | normalized |
| vb_node_000001_000001_000002_000001_000001_asset_000001 | node_000001_000001_000002_000001_000001 | asset | field | collection_item | cb_node_000001_000001_000002_000001 | media.primary | none | normalized |

For the content.body binding, the public value direction is caller-supplied transformed text. Word-limit processing remains upstream DesignDocument/value-binding semantics. The component must not parse an upstream expression, truncate content at runtime, or add a public word-limit setting.

### Responsive overrides

All three entries have breakpoint_id mobile_landscape, source_name mobile_landscape, and unresolved breakpoint resolution. Values are described by normalized type/kind only.

| DesignNode ID | Property | Normalized value kind/type | Breakpoint status | Milan authority reference |
| --- | --- | --- | --- | --- |
| node_000001_000001 | grid-template-columns | unresolved / string | unresolved | none accepted for Milan |
| node_000001_000001_000001_000002_000001_000002_000002 | display | keyword | unresolved | none accepted for Milan |
| node_000001_000001_000001_000002_000001_000002_000002 | flex-direction | keyword | unresolved | none accepted for Milan |
| node_000001_000001_000002 | display | keyword | unresolved | none accepted for Milan |
| node_000001_000001_000002 | flex-direction | keyword | unresolved | none accepted for Milan |
| node_000001_000001_000002 | flex-wrap | keyword | unresolved | none accepted for Milan |

There are three ResponsiveOverride records containing six property values. Their normalized breakpoint IDs and source names are mobile_landscape; no numeric min/max threshold is resolved in the DesignDocument. The shared accepted record sources/work/hero_india/fidelity/breakpoint_authority.json includes a 767px mobile_landscape entry, but its evidence is tied to the Hero India source environment. It does not establish Milan's source environment or Milan's breakpoint mapping.

## Accepted Behavior authority and references

| Behavior field | Accepted value |
| --- | --- |
| Primitive | selection@1.0.0 |
| Alignment | position |
| Advance boundary | wrap |
| Timer interval | 5000 ms |
| Timer start | on_initialization |
| Manual activation | stop |
| Timer restart | never |
| Timer reset | none |
| Reduced motion | disable_automatic_advance |
| Focus policy | nil |
| Keyboard policy | nil |
| Motion policy | nil |
| Binding responsive overrides | empty list |

| Reference role | DesignNode |
| --- | --- |
| Owner | node_000001 |
| Activate trigger origin | node_000001_000001_000001_000002_000001 |
| Timer trigger origin | nil |
| Controlled target: control collection | node_000001_000001_000001_000002_000001 |
| Controlled target: feature-description presentation | node_000001_000001_000001_000002_000001_000002_000001 |
| Controlled target: desktop-media presentation | node_000001_000001_000002_000001 |
| Focus-policy references | none; policy is nil |

These roles do not establish complete Tabs semantics, keyboard navigation, focus movement, a panel relationship, durable item identity, or responsive Behavior overrides. The Behavior contract's positional alignment is the accepted cross-collection synchronization rule.

## Candidate boundary containment

Containment uses the complete D0 whole-binding reference set: owner, non-nil trigger origins, controlled targets, and focus-policy references if present. Diagnostic and provenance references are not binding-node references.

| Boundary candidate | Referenced nodes inside | Referenced nodes outside | Binding disposition | Owner acceptance |
| --- | --- | --- | --- | --- |
| node_000001 | owner, activate origin/control collection, feature-description presentation, desktop-media presentation | none | contained | required |
| node_000001_000001 | activate origin/control collection, feature-description presentation, desktop-media presentation | owner | split | required if considered |
| node_000001_000001_000001 | activate origin/control collection, feature-description presentation | owner, desktop-media presentation | split | required if considered |
| node_000001_000001_000001_000002 | activate origin/control collection, feature-description presentation | owner, desktop-media presentation | split | required if considered |
| node_000001_000001_000001_000002_000001 | activate origin/control collection, feature-description presentation | owner, desktop-media presentation | split | required if considered |
| node_000001_000001_000001_000002_000001_000002 | feature-description presentation | owner, activate origin/control collection, desktop-media presentation | split | required if considered |
| node_000001_000001_000001_000002_000001_000002_000001 | feature-description presentation | owner, activate origin/control collection, desktop-media presentation | split | required if considered |
| node_000001_000001_000002 | desktop-media presentation | owner, activate origin/control collection, feature-description presentation | split | required if considered |
| node_000001_000001_000002_000001 | desktop-media presentation | owner, activate origin/control collection, feature-description presentation | split | required if considered |

Every other strict descendant candidate contains none of the binding's referenced nodes and classifies outside_candidate. No referenced node is missing, so no candidate is unresolved. The root is the only candidate containing the entire binding. This is a mechanical finding, not an accepted boundary decision.

The root also contains node_000001_000002, normalized as unsupported. C09D3 says any raw, unsupported, or unknown node inside the selected boundary blocks plan reference validation and generation eligibility in plan 1.0.0; structured exclusions require later authority. A1 can record the root boundary, but it cannot waive or exclude this node. This is a downstream plan/generation blocker, not a missing-reference or A0 failure.

## Breakpoint prerequisite

| Field | Result |
| --- | --- |
| RESPONSIVE_OVERRIDES_PRESENT | YES |
| D0_BREAKPOINT_AUTHORITY_REQUIRED | YES |
| BREAKPOINT_AUTHORITY_REQUIRED_BY_D0 | YES |
| EXACT_MILAN_BREAKPOINT_AUTHORITY_PRESENT | NO |
| D0_BLOCKED_BREAKPOINT_AUTHORITY | YES |

Behavior.ComponentizationDecision.propose/4 checks for DesignDocument responsive overrides and requires the breakpoint-authority prerequisite when any are present. This preflight did not call that function or the proposer. The exact three current overrides are unresolved, and the shared accepted 767px entry is supported by evidence for a different source environment. Milan-specific evidence still records its breakpoint as not established. A Milan-scoped accepted authority must resolve the exact source name, width/query semantics, and applicable cascade before A1 freeze or D0.

## ComponentizationSemanticInput decision-family matrix

Recommendations below are not accepted decisions. Public names remain unset. Source binding keys and node IDs are evidence references only.

SEMANTIC_DECISION_FAMILIES_APPLICABLE=ContractIdentityDecision, ClassificationDecision, BoundaryDecision, PublicAttrDecision, PublicSlotDecision, CollectionAdmissionDecision, ItemFieldDecision, BindingAssignmentDecision, RenderPlacementDecision, ImageAccessibilityDecision, StaticContentDispositionDecision. CollectionCountLinkDecision and EvidenceHandlingDecision are not applicable.

OWNER_DECISION_COUNT=13
OWNER_DECISION_IDS=A1-Q01,A1-Q02,A1-Q03,A1-Q04,A1-Q05,A1-Q06,A1-Q07,A1-Q08,A1-Q09,A1-Q10,A1-Q11,A1-Q12,A1-Q13

| Decision family | Applicable | Mechanical IR facts | Existing authority | Owner decision required | Recommended source-independent direction | Alternatives | Risk if wrong | Blocker |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ContractIdentityDecision | yes | One root and one accepted selection behavior binding; no contract identity is present in IR. | C09D5 requires an explicit source-independent identifier and forbids deriving it from source/node/path identity. | Choose a stable reusable identity. | Use a generic product-role identity in the feature-showcase space; do not freeze an exact identifier in A0. | Another reusable product role, or defer identity. | Collision, unstable references, or source-coupled API identity. | Required for A1 input validity. |
| ClassificationDecision | yes | Root normalized kind is section; it does not choose contract category or module/function intent. | C09D1 permits primitive/component/pattern/section and requires explicit classification. | Choose category, module intent, and function intent. | Treat as a reusable feature showcase component unless broader composition evidence favors a pattern. | Pattern or section classification; primitive only with a distinct reusable primitive role. | Incorrect taxonomy and downstream catalogue/generation placement. | Required for A1 input validity. |
| BoundaryDecision | yes | Root contains all four unique Behavior node references; every descendant containing a referenced target splits the binding. Root also contains one unsupported node. | D0 whole-binding containment rule; C09D3 unsupported-node rule. | Accept or defer the root candidate. | Keep the root as the only whole-binding candidate, subject to explicit owner acceptance and recorded unsupported-node blocker. | Defer pending authority for structured exclusion or another supported model. | A split binding is inadmissible; root remains non-generation-eligible under current Plan authority. | Required for A1; unsupported node blocks downstream generation eligibility. |
| PublicAttrDecision | yes | Two top-level list-valued collection inputs are candidates. There are no scalar site-scope value bindings. | C09D1 requires explicit name, type, required/default, purpose, validation, accessibility, and provenance. Collection attrs must be list type. | Choose each public attr's exact name and complete schema. | Two distinct list attrs, each representing one CollectionBinding; no timer or word-limit config attr. | Defer one or both collections; a combined field would need new authority and cannot imply merged identity. | Ambiguous ownership, coupling, or changed behavior/configuration. | Required to expose admitted root collections. |
| PublicSlotDecision | yes | No normalized slot binding or required consumer-owned markup is present. | C09D1/C09D3 require explicit slot semantics and supported placement; Behavior authority invents no action markup. | Choose an empty slot list or identify a concrete consumer-owned composition need. | Empty slots unless an owner identifies a reusable composition responsibility. | A supported consumer-owned subtree slot with a separately chosen placement. | Shifts markup, accessibility, or behavior ownership without evidence. | Any chosen slot needs a complete explicit decision and placement. |
| CollectionAdmissionDecision | yes | Exactly two independent top-level CollectionBindings; both are referenced by accepted Behavior; no parent collection. | C09D1 requires one explicit admission and top-level list attr per root collection. | Decide whether to admit both separately and associate each with its own list attr. | Admit as two separate collections; preserve positional synchronization without claiming shared IDs or equal cardinality. | Defer componentization; do not merge them into one collection. | Merged data invents item identity/correlation or changes synchronization. | Required to represent both Behavior targets. |
| ItemFieldDecision | yes | First collection has content.title, transformed content.body, and a media.primary asset field; second collection has an independent media.primary asset field. | C09D1 requires explicit item field schema. C09C4 leaves the word-limit transform upstream. | Choose field schema and required/default/validation semantics separately within each owning collection. | Use role-based text and media fields; callers provide body text after upstream transformation. Keep same media key in separate collection schemas independent. | Omit a field only with reviewed boundary/API redesign; unprojected in-boundary bindings remain uncovered. | Incorrect item shape, altered text semantics, or implied cross-list identity. | Required for each projected item binding; image companion fields depend on accessibility choice. |
| CollectionCountLinkDecision | no | No collection_count ValueBinding or normalized count value exists. | C09D1 forbids deriving count links from list length; C09D5 omits this family when no count is public. | No owner decision for current IR. | Leave the family empty. | A future count requires new normalized evidence and explicit authority. | Invented count semantics or false per-list linkage. | none for A1; do not invent a count. |
| BindingAssignmentDecision | yes | Two collection bindings and four normalized value bindings exist. All four value bindings are collection-item fields. | C09D1 requires an explicit BindingProjection link for each public projection; C09D5 forbids inferred assignments. | Map each of the six bindings to the chosen collection attr or item field. | Collection roots map separately; each value maps to a field under its exact owning CollectionBinding. content.body remains transformed caller text. | Leave a binding unprojected only with resulting coverage/review consequences accepted. | Wrong data source, lost field, or accidental shared identity. | Required for every binding represented in the chosen boundary. |
| RenderPlacementDecision | yes, conditional | No unbound public value exists. Placement may be needed if static content is promoted or an unbound attr/slot is chosen. | C09D3 permits only existing render roles; each unbound public top-level target needs one explicit placement. | Decide placements only for selected unbound public members. | Empty when all public data is binding-backed and static nodes remain internal; use only existing roles if promoted. | Promote a static node to a public attr/slot and provide its supported role. | Wrong rendering locus, placement conflict, or generation-ineligible plan. | Conditional on selected unbound public members. |
| ImageAccessibilityDecision | yes | Two image DesignNodes are targets of asset ValueBindings; neither has normalized alt text/field authority. | C09D1/C09D3 require explicit consumer-supplied-alt or decorative policy for each image source; nil does not mean decorative. | Choose policy for each image field and any required sibling alt field. | Consider a consumer-supplied alt item field required when the image source is present; this is only an option, not accepted meaning. | Explicit decorative policy for a given image when owner evidence supports it. | Missing or incorrect alternative text, or false decorative classification. | Required before SemanticInput can validate image sources. |
| EvidenceHandlingDecision | no | All four ValueBindings have normalized status; none is evidence_insufficient. | C09D5 restricts this family to evidence-insufficient bindings and allows only omission. | No owner decision for current IR. | Leave the family empty. The normalized body modifier is not evidence-insufficient. | Revisit only if a future DesignDocument marks a binding evidence-insufficient. | Misusing evidence handling to bypass normalized binding semantics. | none for A1. |
| StaticContentDispositionDecision | yes | Two static nodes exist: heading (43 UTF-8 bytes) and rich_text (236 UTF-8 bytes); neither is binding-driven. | C09D1/C09D3 allow internal constants or explicit promotion; source literals do not become public defaults. | Decide internal vs promote for each node. | Keep both internal unless customization is an explicit reusable product need. | Promote a node to an attr or slot with matching explicit placement. | Freezes private copy, creates needless API surface, or chooses wrong consumer responsibility. | Explicit choice required before any static content is exposed. |

### Cross-collection invariant

| Fact | Status |
| --- | --- |
| TWO_COLLECTION_BINDINGS | yes |
| DURABLE_CROSS_COLLECTION_ITEM_IDENTITY | not proven |
| POSITIONAL_ALIGNMENT | proven |
| EQUAL_RUNTIME_CARDINALITY | not proven |
| 05E604_COLLECTION_BINDING | no |
| 05E604_DIAGNOSTIC | bricks.collection.boundary_unproven |

Any later public representation of both lists must preserve positional alignment and must not claim durable shared IDs, database identity, or equal runtime cardinality. Keep the root collections distinct. The extra media.primary field inside the first collection does not admit a third collection or add a Selection target. Existing mapping authority describes equal-target cardinality as a fail-closed runtime invariant; this preflight adds no runtime policy.

## A1 owner-decision register

Each entry is unresolved. The recommended direction is advisory and must not be copied into a frozen input without explicit owner acceptance.

| ID | Family / decision | Evidence | Recommended decision | Alternative(s) | Risk | Blocking downstream stage |
| --- | --- | --- | --- | --- | --- | --- |
| A1-Q01 | Contract identity | One reusable root; no IR identity field. | Choose a stable source-independent product-role identity. | Another generic reusable identity or defer. | Unstable or source-coupled public contract identity. | A1 freeze. |
| A1-Q02 | Classification | Root kind is section; category and product intent are not mechanical facts. | Choose component for a reusable feature-showcase role, with explicit module/function intent. | Pattern or section when product ownership supports it. | Wrong taxonomy or module responsibility. | A1 freeze. |
| A1-Q03 | Boundary | Root contains all Behavior references; every ref-bearing descendant splits; root contains unsupported node. | Accept root only with unsupported-node consequence recorded. | Defer until authority defines structured exclusion or another supported model. | Split binding or downstream non-generation-eligible plan. | A1 freeze; downstream plan/generation review. |
| A1-Q04 | Public attrs | Two separate top-level collections; no scalar site-scope values. | Define two distinct list attrs and complete D1 schema without exact A0 names. | Defer one/both inputs and revise the component model. | Invalid or misleading public data shape. | A1 freeze. |
| A1-Q05 | Public slots | No normalized consumer-owned slot evidence. | Choose no slots unless a concrete composition requirement exists. | Add only a supported consumer-owned slot with explicit purpose and placement. | Unexpected markup/behavior ownership transfer. | A1 freeze; placement validation if selected. |
| A1-Q06 | Collection admission | Two independent root CollectionBindings with no parents. | Admit both separately and associate each with its own list attr. | Defer componentization; do not merge the inputs. | False cross-list identity or lost synchronization. | A1 freeze. |
| A1-Q07 | Item fields | content.title, transformed content.body, and separate media.primary fields under each collection. | Define each collection schema independently; body is already transformed text. | Defer a field only with uncovered-binding consequences accepted. | Runtime parsing/truncation or false shared item schema. | A1 freeze. |
| A1-Q08 | Binding assignments | Two collection and four value bindings are normalized. | Assign each collection root and each value binding to its selected public member by exact owning binding. | Leave an in-boundary binding uncovered and accept review/blocking diagnostics. | Missing or misrouted data. | A1 freeze and proposer input validity. |
| A1-Q09 | Render placements | No unbound value; placements arise only if an unbound public member is selected. | Keep placements empty unless static content or an unbound member is promoted. | Choose a supported existing placement for each promoted member. | Wrong node/role or placement conflict. | A1 freeze if applicable. |
| A1-Q10 | Image accessibility | Two dynamic image sources, no alt authority. | Decide whether each gets a consumer-supplied sibling alt field, required with the source. | Explicitly mark an image decorative when owner evidence supports it. | Accessibility gap or inaccurate alternative text. | A1 input validation. |
| A1-Q11 | Static content | One static heading and one static rich-text node; literals withheld. | Keep both internal unless customization has product value. | Promote either through explicit attr/slot decision and placement. | Accidental private-copy exposure or unnecessary API. | A1 freeze for any public promotion. |
| A1-Q12 | Breakpoint authority prerequisite | Three unresolved overrides name mobile_landscape; shared 767px evidence is scoped to another source environment. | Accept Milan-scoped numeric/query/cascade authority before proceeding. | Supply different verified Milan source-environment evidence; do not reuse unrelated scope by name alone. | Incorrect responsive output and ungrounded D0 resolution. | A1 freeze and real P7-D0. |
| A1-Q13 | Unsupported-node consequence | Root includes one normalized unsupported node; C09D3 blocks Plan 1.0.0 validation/generation eligibility for it. | Decide whether to freeze root knowing the downstream blocker, or defer for structured-exclusion authority. | Defer componentization until authority changes. | A1 may produce a candidate that cannot become generation-eligible. | Owner review before A1; generation remains blocked under current authority. |

The accepted positional-alignment contract is an invariant, not an A1 option. A1 must not replace it with durable IDs, a merged list, inferred equal cardinality, or new selection targets. Collection-count links and evidence handling remain empty because their required IR evidence is absent.

## A0 result summary

| Field | Result |
| --- | --- |
| ROOT_BOUNDARY_BINDING_DISPOSITION | contained |
| OTHER_BOUNDARY_CLASSIFICATIONS | 8 split, 8 outside_candidate, 0 unresolved |
| D0_BREAKPOINT_AUTHORITY_REQUIRED | yes |
| EXACT_MILAN_BREAKPOINT_AUTHORITY_PRESENT | no |
| D0_BLOCKED_BREAKPOINT_AUTHORITY | yes |
| SEMANTIC_DECISION_FAMILIES_APPLICABLE | 11 of 13 |
| OWNER_DECISION_COUNT | 13 |
| A0_REVIEW_READY | yes |
| A1_SEMANTIC_INPUT_FROZEN | no |

## Lifecycle and terminal result

**accepted_tuple_verified → exact_normalization_replayed → componentization_surface_inventoried → behavior_references_inventoried → candidate_boundaries_classified → breakpoint_prerequisite_classified → semantic_decision_matrix_completed → owner_questions_recorded → A0_REVIEW_READY**

The accepted tuple, evidence hashes, exact replay, Behavior references, and A0 inventory all match. Owner decisions and Milan breakpoint authority remain open by design and are recorded above. The source-neutral product role can be described without choosing a final public identifier or schema; therefore A0 is review-ready. The unsupported node and breakpoint authority remain explicit downstream blockers.

## Performance and scaling

| Field | Value |
| --- | --- |
| DATA_LAYER | COLD_COMPILE_REVIEW_TIME |
| HOT_DATA / WARM_DATA | N/A |
| ETS / CACHEX | N/A |
| REDIS / POSTGRES / PGBouncer / READ_REPLICA | N/A |
| GENSERVER / PUBSUB / OBAN | N/A |
| TTL / DB_INDEX | N/A |
| RUNTIME_DB_CALLS | 0 |
| RUNTIME_NETWORK_CALLS | 0 |

No runtime infrastructure is introduced.

## Next gate

NEXT_REQUIRED_GATE=Review and accept the A0 owner-decision register, then resolve the exact Milan breakpoint authority before A1 SemanticInput freeze or real P7-D0. Separately decide whether to carry the known unsupported-node blocker into downstream review or defer for structured-exclusion authority.

UNRESOLVED_AUTHORITY_GAPS=Milan-scoped mobile_landscape breakpoint semantics; owner semantic choices A1-Q01 through A1-Q13; structured exclusion for the unsupported node if generation eligibility is required.
