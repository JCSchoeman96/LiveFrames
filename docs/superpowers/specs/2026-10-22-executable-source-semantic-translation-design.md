# LiveFrames — Executable Source Semantic Translation Design

**Date:** 2026-10-22
**Status:** Proposed architecture — approved direction, implementation not yet authorized
**Initial proving source:** Bricks Template 124 (`wc_product`)
**Data layer:** `COLD_BUILD_TIME`

## 1. Purpose

LiveFrames must convert structured page-builder templates into deterministic, Phoenix-native output without executing imported source code.

Real templates can contain executable-source elements whose runtime behavior represents ordinary template semantics. Template 124 proves one required example:

- a Bricks `code` element has PHP execution enabled;
- static analysis proves that it reads the current WooCommerce product's full description;
- that full description is required consumer-visible template content;
- LiveFrames currently preserves the code element as unsupported inert source;
- preserving the source does not preserve the required rendered meaning.

LiveFrames therefore needs a bounded mechanism that can translate **proven executable-source meaning** into ordinary source-independent LiveFrames data semantics.

It must never become a PHP execution, interpretation, emulation, or general program-translation system.

## 2. Ultimate goal

The long-term architecture must allow multiple source platforms to converge on the same canonical LiveFrames semantic.

For example:

```text
Bricks PHP code
Bricks dynamic-data expression
WooCommerce Bricks element
Elementor expression
WordPress shortcode
other proven source representation
              |
              v
CURRENT_ENTITY / commerce.product.full_description
              |
              v
LiveFrames ValueBinding / data semantics
              |
              v
Phoenix-native component
```

The source syntax establishes provenance.

The canonical semantic establishes meaning.

The generated Phoenix component must not depend on the source language that originally expressed that meaning.

## 3. Initial scope

The first implementation slice supports exactly one semantic:

```text
scope       = current entity
semantic    = commerce.product.full_description
target      = rich text
cardinality = one
```

It is proven initially from a Bricks `code` element whose static PHP data flow unambiguously means:

> obtain the current WooCommerce product and emit its full description.

This slice does **not** include:

- arbitrary PHP execution;
- arbitrary PHP interpretation;
- generic PHP-to-Elixir translation;
- arbitrary WooCommerce API translation;
- CODE1/CODE2 product attribute tables;
- add-to-cart semantics;
- product price semantics;
- breadcrumbs;
- short-description semantics;
- WooCommerce hook realization;
- arbitrary dynamic expressions;
- arbitrary HTML trust.

## 4. Proven Template 124 evidence

Canonical source:

```text
Template content SHA256 =
b629c9cb7412ff8531f06ba357eede11383c69424810a44469e5e740bf132826
```

Canonical Design IR identity:

```text
53299a0df37c3d9ba56be7b0f81e90c8bc73579a223d63aae14a5a8dcfd2cc20
```

Current conversion proves:

- 82 source elements;
- 82 accounted-for IR nodes;
- zero silent element loss;
- 72 native nodes;
- 10 preserved unsupported nodes;
- conversion deterministic;
- IR valid;
- lifecycle reaches `IR_READY`.

Three unsupported executable-source nodes were statically classified.

CODE1 and CODE2 produce product attribute tables. They are not part of this initial capability.

CODE3 is required template meaning. It reads the current product's full description and emits it as page content.

CODE3 is:

```text
SEMANTIC_CLASS=PRODUCT_DATA_PRESENTATION
SIDE_EFFECT_CLASS=READ_ONLY_RUNTIME_LOOKUP
ESSENTIALITY=REQUIRED_FOR_TEMPLATE_MEANING
```

No eval, dynamic include, process execution, filesystem operation, network operation, hook registration, or mutation was identified.

Static analysis did not execute the imported source.

## 5. Architectural principle

Executable source is treated as **evidence**, never as implementation.

The pipeline is:

```text
source executable element
        |
        v
parse as inert syntax
        |
        v
bounded safety classification
        |
        v
closed semantic recognizer
        |
        v
semantic validation
        |
        v
source-independent LiveFrames binding
        |
        v
normal Design IR / componentization / generation
```

There is no execution transition.

There is no arbitrary interpreter.

There is no source-language runtime in generated components.

## 6. Architecture boundaries

### 6.1 Source adapter responsibility

The Bricks adapter owns knowledge that:

- the source element is a Bricks `code` element;
- PHP execution is enabled in the source;
- Bricks would ordinarily evaluate that source;
- specific statically proven PHP data flow corresponds to a supported semantic.

That source-specific knowledge must not leak into generic IR.

### 6.2 Semantic translation boundary

A source-specific translator converts proven source syntax into a generic semantic result.

Conceptually:

```text
ExecutableSourceSemanticTranslator
  -> parse
  -> safety classify
  -> recognize
  -> validate
  -> translate
```

Recommended implementation location:

```text
apps/live_frames/lib/live_frames/adapters/bricks/
```

Exact module/file decomposition is deferred to the implementation plan, but source-language recognizers must remain below the Bricks adapter boundary.

### 6.3 Design IR responsibility

Design IR stores the normalized data requirement.

It must not store:

- PHP code as executable behavior;
- WooCommerce PHP function names;
- source hashes as semantic identity;
- PHP AST nodes;
- eval recipes.

It may retain source trace/provenance separately.

## 7. Generic ValueBinding extension

Current `ValueBinding` cannot cleanly represent the required semantic.

Current closed target kinds are:

```text
:text
:asset
:link_url
```

Current scopes are:

```text
:collection_item
:site
:collection
```

Using `:site` would misrepresent current-product scope.

Using `:text` would fail to express rich-text trust requirements.

The smallest generic extension should therefore add:

```text
target_kind = :rich_text
scope       = :current_entity
value_kind  = :field
value_key   = "commerce.product.full_description"
```

No PHP-specific field is added.

No WooCommerce-specific binding struct is added.

No parallel `PhpBinding`, `CodeBinding`, or `WooCommerceBinding` is permitted.

The namespaced `value_key` carries domain meaning while the scope remains generic.

## 8. Rich-text contract

Product full descriptions may contain HTML.

Therefore:

```text
target_kind=:rich_text
```

must be semantically distinct from:

```text
target_kind=:text
```

A `:rich_text` binding means:

> structured or HTML-bearing content that requires an explicit sanitization/trust policy before rendering.

It does **not** mean:

> arbitrary trusted HTML.

Imported source content must not automatically become `Phoenix.HTML.raw/1` input.

The eventual consumer/runtime boundary must define sanitization and trust separately.

Until that policy exists, `:rich_text` may advance through IR normalization but must fail closed before unsafe native rendering.

## 9. Executable-source lifecycle

Every executable-source candidate follows this lifecycle:

```text
DISCOVERED
  |
  v
PARSED_INERT
  |
  v
SAFETY_CLASSIFIED
  |
  v
SEMANTIC_MATCHED
  |
  v
SEMANTIC_VALIDATED
  |
  v
NORMALIZED
```

Failure branches:

```text
PARSE_FAILED
UNSAFE_SOURCE
SEMANTIC_UNKNOWN
SEMANTIC_AMBIGUOUS
VALIDATION_FAILED
       |
       v
PRESERVED_UNSUPPORTED
```

Terminal states:

```text
NORMALIZED
PRESERVED_UNSUPPORTED
```

`EXECUTED` is not a valid state.

## 10. Transition guards

### DISCOVERED -> PARSED_INERT

Requires:

- supported source element type;
- execution-enabled source is available as inert bytes;
- source is within configured byte limits;
- parser operates in parse/tokenization-only mode.

Failure:

```text
PARSE_FAILED
```

### PARSED_INERT -> SAFETY_CLASSIFIED

The analyzer must reject the supported semantic path if prohibited constructs are present.

The first slice permits only bounded read-only data-flow necessary to identify the current-product full-description semantic.

Prohibited constructs include:

- `eval`;
- dynamic include/require;
- process execution;
- filesystem writes;
- network I/O;
- database mutation;
- hook registration;
- session/request mutation;
- unbounded dynamic dispatch;
- semantic ambiguity.

Presence of prohibited behavior gives:

```text
UNSAFE_SOURCE
```

### SAFETY_CLASSIFIED -> SEMANTIC_MATCHED

Requires an exact structural match to one supported semantic family.

Matching must use parsed structure and data flow.

It must not rely on:

- exact source hash;
- whitespace;
- variable names;
- source element ID;
- Template 124 identity;
- Product 767 identity;
- literal whole-source regex equality.

No candidate match gives:

```text
SEMANTIC_UNKNOWN
```

More than one valid meaning gives:

```text
SEMANTIC_AMBIGUOUS
```

### SEMANTIC_MATCHED -> SEMANTIC_VALIDATED

Requires all semantic invariants for the candidate.

For the initial semantic:

- product identity is derived from current request/current post context;
- no hard-coded product identity is used;
- the selected field is full description;
- emitted output originates from that field;
- no additional consumer-visible output with unknown meaning exists;
- no prohibited side effect exists.

### SEMANTIC_VALIDATED -> NORMALIZED

Produces one source-independent binding:

```text
target_kind=:rich_text
value_kind=:field
scope=:current_entity
value_key="commerce.product.full_description"
```

Source trace remains attached for provenance.

## 11. Structural recognition rules

The first recognizer should prove semantic data flow, not source spelling.

Equivalent arrangements may be admitted when they prove the same closed meaning, such as harmless changes to:

- whitespace;
- temporary variable names;
- assignment ordering that does not change data flow;
- equivalent bounded current-product acquisition.

Near-miss cases must fail closed.

Examples that must **not** normalize as full description:

- hard-coded product ID;
- short description;
- description from a different product;
- description combined with mutation;
- description plus unknown executable call;
- dynamic function selection;
- network-enriched description;
- description plus unrelated consumer-visible output;
- CODE1/CODE2 attribute-table code;
- syntactically malformed source.

## 12. Provenance

Translation must retain enough source evidence to explain why a semantic was produced.

Provenance may include:

- adapter version;
- source element trace;
- source language classification;
- safe source fingerprint;
- semantic recognizer version;
- recognized semantic key;
- normalization status.

Public diagnostics must never contain raw executable source.

The raw source may remain available only in private source trace/evidence under existing privacy rules.

"Private source trace/evidence" means out-of-band private source corpus or ephemeral analyzer input only. It does not mean a `LiveFrames.IR.SourceTrace` inside a DesignDocument. Serialized `LiveFrames.IR.SourceTrace` values are ordinary IR data and must never contain raw executable source. This applies to every field that the serializer emits, including `source_settings`, `metadata`, node traces, diagnostics, diagnostic traces, and provenance.

Preserved unsupported executable-source elements keep safe structural provenance, not raw source bytes. Their source fingerprint, execution-enabled status, and safe non-code settings remain available. A preserved element still counts in source accounting and remains a whole-element unsupported node.

## 13. Diagnostic policy

The feature needs deterministic diagnostics for at least these outcomes:

```text
executable source parse failed
executable source unsafe
executable source semantic unsupported
executable source semantic ambiguous
executable source semantic translated
```

Final diagnostic code names must follow established LiveFrames naming conventions.

Diagnostics must not print:

- raw PHP;
- private selector values;
- source paths;
- arbitrary runtime values;
- credentials;
- private product data.

Unsupported or ambiguous executable source remains an explicit preservation node rather than disappearing.

## 14. Preservation and atomicity

Semantic translation is whole-element atomic.

For one executable-source element, LiveFrames must either:

1. prove the entire relevant consumer-visible meaning covered by the supported semantic and normalize it; or
2. preserve the element as unsupported.

It must not translate one output fragment and silently discard another unknown output fragment.

Preservation does not authorize raw executable bytes in serialized Design IR. Whether recognition normalizes an execution-enabled code element or fails and keeps it unsupported, the ordinary DesignDocument must not contain its raw source. The recognizer may read the inert bytes from the original source element only before ordinary trace construction.

This is especially important for code elements containing mixed PHP and HTML.

## 15. CODE1 and CODE2

CODE1 and CODE2 are deliberately excluded from the initial semantic.

They represent product attribute-table semantics involving:

- product attributes;
- taxonomy/term data;
- labels;
- repeated attribute values.

Their semantic family is materially broader than one scalar field.

After the first slice:

```text
CODE1=PRESERVED_UNSUPPORTED
CODE2=PRESERVED_UNSUPPORTED
```

If either becomes normalized accidentally, the recognizer is too broad and implementation must stop.

## 16. Data-semantics boundary

Recognition and realization are separate concerns.

### Recognition answers:

> What does this source mean?

For CODE3:

```text
commerce.product.full_description
```

### Realization answers:

> Where does this value come from in the generated Phoenix application?

That is a later commerce/data-provider responsibility.

The source recognizer must not:

- query WooCommerce;
- query WordPress;
- query PostgreSQL;
- fetch Product 767;
- inject example product values.

Product 767 is evidence/fixture context, not generated application state.

## 17. Native-generation boundary

Native generation must consume the normalized generic semantic, not PHP evidence.

Conceptually:

```text
ValueBinding
  scope=:current_entity
  value_key="commerce.product.full_description"
  target_kind=:rich_text
           |
           v
ComponentContract / public input
           |
           v
Phoenix-native render placement
```

The native generator must fail closed until it has an approved rich-text rendering contract.

It must never generate:

- PHP execution;
- shell execution;
- runtime WordPress calls;
- WooCommerce PHP calls;
- source-code interpreter hooks.

## 18. Security invariants

The following invariants are permanent:

1. Imported executable source is never executed.
2. Imported source cannot cause network access during conversion.
3. Imported source cannot cause filesystem writes.
4. Imported source cannot mutate databases.
5. Imported source cannot spawn processes.
6. Recognition is closed-list, not heuristic best-match.
7. Ambiguity fails closed.
8. Unknown meaning remains unsupported.
9. Raw executable source is excluded from ordinary diagnostics.
10. Source hashes are evidence, never semantic recognition keys.
11. Template-specific IDs cannot determine capability.
12. Product-specific IDs cannot determine capability.

## 19. Determinism and bounds

This is a build-time capability:

```text
DATA_LAYER=COLD_BUILD_TIME
```

The analyzer must have explicit finite limits for:

- source bytes per element;
- token/AST node count;
- nesting depth;
- call count;
- variable count;
- control-flow complexity accepted by recognizers;
- semantic data-flow steps.

Inputs beyond limits fail closed as unsupported.

No Redis, Cachex, GenServer, PubSub, Oban, CDN, runtime cache, or runtime database architecture is involved.

## 20. Testing strategy

Implementation must be test-driven.

### Positive semantic-equivalence tests

Prove normalization despite harmless variation in:

- whitespace;
- variable names;
- temporary assignments;
- equivalent supported current-product acquisition.

Expected semantic:

```text
scope=:current_entity
value_kind=:field
value_key="commerce.product.full_description"
target_kind=:rich_text
```

### Negative near-miss tests

Must remain unsupported:

- hard-coded product;
- short description;
- attribute table;
- mutation;
- unknown function;
- extra output;
- eval;
- include;
- process execution;
- network access;
- malformed PHP;
- ambiguous product source.

### Regression tests

Canonical Template 124 rerun must prove:

```text
SOURCE_ELEMENT_COUNT=82
SOURCE_ELEMENT_ACCOUNTING_COMPLETE=YES

CODE3=NORMALIZED
CODE1=PRESERVED_UNSUPPORTED
CODE2=PRESERVED_UNSUPPORTED

PHP_EXECUTED=NO
```

No unrelated existing Bricks fixture may regress.

## 21. Expected Template 124 outcome

After the first capability is implemented correctly:

```text
Template 124
  SOURCE_PINNED
  INGESTED
  IR_READY
```

CODE3 should become a normalized current-product full-description semantic.

That should remove executable-source meaning as the earliest blocker.

The next expected material gap is then commerce/WooCommerce data semantics for:

- product add-to-cart;
- breadcrumbs;
- short description;
- price;
- remaining product bindings;
- CODE1/CODE2 attribute collections;
- WooCommerce runtime expressions.

Those are explicitly outside this first implementation slice.

## 22. Folder and naming direction

Recommended boundary:

```text
apps/live_frames/lib/live_frames/adapters/bricks/
  executable_source_semantic_translator.ex
  php_semantic_recognizer.ex
```

Tests should remain alongside existing adapter tests under:

```text
apps/live_frames/test/live_frames/
```

Exact filenames may be refined during implementation planning if existing repository conventions indicate a better decomposition.

Do not create a new top-level executable-language subsystem unless implementation planning proves multiple adapters already require one.

## 23. Performance and scaling review

**Layer:** cold/build-time.

**100k concurrent users:** no runtime impact.

**DB calls:** none during semantic recognition.

**Redis representation:** not applicable.

**Streaming:** parse one bounded source element at a time; do not load unrelated source/database state.

**Latency objective:** conversion determinism and bounded work are more important than runtime request latency because this path is offline.

## 24. Acceptance criteria

Architecture implementation is successful when all of the following hold:

```text
IMPORTED_PHP_EXECUTED=NO

CURRENT_PRODUCT_FULL_DESCRIPTION_RECOGNIZED=YES

NORMALIZED_BINDING=
  scope=current_entity
  value_kind=field
  value_key=commerce.product.full_description
  target_kind=rich_text

CODE1_NORMALIZED=NO
CODE2_NORMALIZED=NO
CODE3_NORMALIZED=YES

AMBIGUOUS_SOURCE_FAILS_CLOSED=YES
UNSAFE_SOURCE_FAILS_CLOSED=YES
UNKNOWN_SOURCE_FAILS_CLOSED=YES

RAW_SOURCE_IN_PUBLIC_DIAGNOSTICS=NO

TEMPLATE_124_SOURCE_ELEMENT_ACCOUNTING_COMPLETE=YES
CONVERSION_DETERMINISTIC=YES
```

## 25. Explicit non-goals

This design does not authorize:

- implementation;
- arbitrary PHP support;
- runtime PHP;
- PHP sandboxing;
- PHP-to-Elixir compilation;
- generalized AST translation;
- CODE1/CODE2 translation;
- generic WooCommerce support;
- rich-text sanitizer implementation;
- browser parity claims;
- componentization approval.

Those require later plans or authority.

## 26. Next gate

After this design specification is reviewed and accepted:

```text
NEXT_STEP=WRITE_IMPLEMENTATION_PLAN
```

The implementation plan must:

- inspect all validators/encoders/identity paths affected by new closed enums;
- identify the exact minimal `ValueBinding`/IR changes;
- define rich-text fail-closed behavior;
- specify TDD order;
- add bounded recognizer tests;
- rerun canonical Template 124;
- preserve CODE1/CODE2 unsupported behavior;
- include explicit rollback/STOP conditions;
- prohibit implementation until the plan itself is reviewed and approved.

**IMPLEMENTATION_AUTHORIZED=NO**
