# C09C5 Bricks article metadata binding authority

## Status and scope

This document records source-independent frontend meanings for six dynamic
expressions in the accepted Article Juliet Bricks source. It supplements the
C09B frontend binding authority, the C09B2 Design IR value modifier
authority, the C09C2 Bricks binding mapping authority, and the C09C4
post-content word-limit mapping authority.

```text
AUTHORITY=C09C5
SOURCE_SEMANTIC_VERDICT=PROVEN
IMPLEMENTATION_AUTHORIZED=NO
FLUID11B_IMPLEMENTATION_AUTHORIZED=NO
FLUID12_AUTHORIZED=NO
```

C09C5 authorizes only the meanings in the six-row matrix below. It does not
implement Bricks normalization, change Design IR, or decide how a heading
carries a link, how a date attribute is represented, or how any binding is
rendered. Those questions remain with the later normalization,
representation, and native realization phases.

## Governing frontend boundary

LiveFrames is a frontend compiler. The Bricks adapter interprets source syntax
and maps proven meanings to source-independent frontend semantics. Raw
expressions and source identities remain provenance in `SourceTrace`.
`ValueBinding.value_key` names the frontend value and must not repeat a Bricks
field name or become a Phoenix API name.

The host Phoenix application supplies values and owns data fetching. Bricks
query settings remain provenance. LiveFrames does not run a backend query,
apply Bricks filters, fetch a URL, format dates at runtime, or execute a source
expression.

The required flow is:

```text
Bricks source syntax
→ Bricks adapter semantic mapping
→ source-independent Design IR
→ componentization and native realization
```

Raw Bricks expressions must not reach `NativeGenerator` for parsing. Article
Juliet source IDs must not select hard-coded behavior. Query settings must not
become a LiveFrames backend execution contract.

## Evidence

The accepted Article Juliet source is recorded in
`sources/bricks_components.json`, SHA-256
`bb584f35b160f5095dc67fc367884f51cff35b59693c84374426f5cecf56a1a1`. The
source IDs and expressions in the matrix identify the six occurrences covered
by this authority.

The semantic review uses the official Bricks Academy Dynamic Data reference:
<https://academy.bricksbuilder.io/builder/dynamic-content/dynamic-data/>.
The page was checked on 2026-10-26 for the meanings listed here. C09C4 cites
the same official reference and records its earlier consultation for the
post-content word-limit evidence. No Bricks runtime code is executed or used
to infer these meanings.

The accepted Automatic.css fixture is unchanged at SHA-256
`19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05`. It is
not a source of authority for these Bricks metadata bindings.

## Source-semantics matrix

Each row records one accepted source occurrence. The source expression is
provenance, not a canonical key or executable runtime value.

| Source expression | Source ID | Base semantic | Source-neutral key | Modifier or filter | Target intent | Scope | Representation status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `{post_terms_category:plain}` | `a3b871` | Category terms assigned to the post, emitted as plain text without linked or HTML presentation | `taxonomy.category_names` | `plain`; removes links and HTML from term output | `text`, `field` | `collection_item` | `P2_NORMALIZATION_REQUIRED` |
| `{post_excerpt:20}` | `d9eebe` | Post excerpt | `content.excerpt` | Resolved source meaning: `word_limit`, count `20` | `text`, `field` | `collection_item` | `P2_NORMALIZATION_REQUIRED` |
| `{author_name}` | `5c0e06` | Post author name | `author.name` | None | `text`, `field` | `collection_item` | `P2_NORMALIZATION_REQUIRED` |
| `{post_date}` | `cfc2f2` | Post published date | `content.published_at` | None | `text`, `field` | `collection_item` | `P2_NORMALIZATION_REQUIRED` |
| `{post_date:Y-m-d h:m}` | `cfc2f2` | Post published date | `content.published_at` | Proven source filter class `date_format`; preserve the exact literal `Y-m-d h:m` | `datetime` attribute, `field` | `collection_item` | `P3_REPRESENTATION_AUTHORITY_REQUIRED` |
| `{post_url}` | `c5162b` | Post link | `content.url` | None | `link_url`, `field` | `collection_item` | `P2_NORMALIZATION_REQUIRED` |

The representation status identifies the earliest downstream authority or
implementation work still required. It does not authorize that work. The
`{post_url}` target intent is `link_url`; its heading carrier remains
unresolved and may require later Design IR or native representation authority.
The formatted date's source meaning is established, but its Design IR
representation is deferred to P3.

## Decisions and limits

### Category terms

`{post_terms_category:plain}` means category terms assigned to the post, with
the `plain` filter removing linked or HTML presentation. Its frontend value
is plain textual category-term output under `taxonomy.category_names`.
This authority does not define separators, ordering, term IDs, slugs, archive
URLs, or taxonomy query behavior. Separator and ordering semantics remain
unproven.

### Excerpt word limit

`{post_excerpt:20}` means the post excerpt with a word limit of 20. The
source-neutral key is `content.excerpt`, and the modifier semantics are
resolved as `word_limit` with count `20`.

C09C4's implementation mapping remains scoped to
`{post_content:<positive integer>}`. C09C5 does not claim that C09C4
authorizes normalization of `{post_excerpt:20}`. The existing C09B2
`ValueModifier` authority defines the source-neutral `word_limit` shape, but
excerpt normalization still requires separate P2 implementation authority.
The host supplies the value after applying the authorized transformation;
LiveFrames does not truncate it at runtime.

### Author name

`{author_name}` means the post author name and maps to `author.name`. It does
not establish an author ID, profile URL, biography, avatar, or another author
field.

### Post URL

`{post_url}` means the post link and maps to `content.url` with target intent
`link_url`. This source-semantic decision does not establish that the current
heading node can carry a dynamic link. The Bricks normalizer and later
representation/native phases must resolve that question without a
source-specific workaround.

### Published date

`{post_date}` means the post's published date and maps to
`content.published_at`. This authority does not specify timezone conversion,
date value type, or host-side formatting.

`{post_date:Y-m-d h:m}` has the same base meaning and key. The source filter
class is `date_format`, and the literal must remain exactly `Y-m-d h:m`.
Do not correct, normalize, or reinterpret the literal. Do not infer timezone
or decide whether LiveFrames or the host performs formatting. The source
meaning is proven; its Design IR representation is deferred to P3. This
authority creates no new `ValueModifier` kind.

```text
SOURCE_SEMANTIC=PROVEN
DESIGN_IR_REPRESENTATION=DEFERRED_TO_P3
```

## Source-independent key review

The repository's existing mapping authority uses `content.title`,
`media.primary`, `content.body`, and `site.url` for other proven meanings. A
repository search found no existing equivalent for the five keys introduced
here. The keys name frontend concepts that can be supplied by any host or
source adapter:

| Key | Source-independent meaning |
| --- | --- |
| `content.excerpt` | Excerpt content supplied for a frontend item |
| `author.name` | A person's name in the author role |
| `content.url` | A content item's link URL |
| `content.published_at` | The publication date value for a content item |
| `taxonomy.category_names` | Plain textual category-term output for a content item |

These keys do not prescribe component attribute names or host data structures.
If later evidence gives one key a conflicting meaning, stop and obtain
authority before changing the mapping.

## Semantic lifecycle

For each matrix row, the accepted evidence supports:

```text
expression_discovered
→ source_identity_proven
→ base_semantic_proven
→ modifier_semantic_proven_or_none
→ source_neutral_key_authorized
→ frontend_target_intent_proven
```

The five text or link values are source-semantics-authorized for their stated
targets. The formatted date also reaches source-semantic authority, but its
Design IR representation ends at `representation_deferred`. The category
separator and ordering, date formatting ownership, and heading link carrier
remain outside this authority. If a future source form lacks semantic
evidence, classify it as `base_semantic_unproven`,
`modifier_semantic_unproven`, or `target_intent_unproven`. Do not substitute a
backend contract or a source-specific key.

Other terminal outcomes are `backend_semantics_required`,
`source_specific_key_required`, and `representation_deferred`. The first two
do not authorize this document to add backend behavior or a source-specific
key. `representation_deferred` records a proven source meaning whose Design IR
or native form still needs separate authority, as with the formatted date.

## Query settings remain provenance

Article Juliet's `settings.query`, including `posts_per_page`, does not define
a LiveFrames query. It remains source provenance and does not add fields to a
`ValueBinding` or `CollectionBinding`.

```text
QUERY_CONFIGURATION_IS_PROVENANCE_ONLY=YES
LIVEFRAMES_BACKEND_QUERY_RESPONSIBILITY=NO
```

The host Phoenix application owns fetching, filtering, ordering, pagination,
and authorization. A collection binding describes frontend repetition over
caller-supplied items only.

## Performance and scaling

This authority concerns cold compile and review. A later implementation must
use a direct bounded classifier for this closed set of expressions. Runtime
source-expression parsing and runtime database or network calls are forbidden.

```text
DATA_LAYER=COLD_COMPILE_REVIEW_TIME
DIRECT_BOUNDED_CLASSIFIER=REQUIRED
RUNTIME_SOURCE_EXPRESSION_PARSING=FORBIDDEN
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0

ETS=N/A
CACHEX=N/A
REDIS=N/A
POSTGRES=N/A
PGBouncer=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
TTL=N/A
DB_INDEX=N/A
```

## Authorization boundary

C09C5 changes no source normalizer, Design IR schema, component contract,
componentization plan, native generator, Fluid subsystem, or package mapping.
It does not authorize Article Juliet rendering, FLUID-11B, or FLUID-12.

```text
IMPLEMENTATION_AUTHORIZED=NO
DESIGN_IR_SCHEMA_CHANGE_AUTHORIZED=NO
COMPONENTIZATION_OR_NATIVE_IMPLEMENTATION_AUTHORIZED=NO
FLUID_IMPLEMENTATION_AUTHORIZED=NO
FLUID11B_IMPLEMENTATION_AUTHORIZED=NO
FLUID12_AUTHORIZED=NO
```
