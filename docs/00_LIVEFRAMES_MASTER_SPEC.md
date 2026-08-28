# LiveFrames Master Specification

**Document:** `docs/00_LIVEFRAMES_MASTER_SPEC.md`  
**Project:** LiveFrames  
**Status:** Proposed Architecture Authority / Pre-Implementation  
**Version:** 0.1.0  
**Date:** 2026-08-27  
**Primary audience:** LiveFrames maintainers, `/go` coding agents, reviewers, future contributors  
**Authority rule:** Until superseded by a later accepted version, this document defines the intended product boundaries, repository structure, conversion pipeline, lifecycle rules, agent workflow, and implementation sequence for LiveFrames.

---

# 1. Executive Summary

LiveFrames is a reusable Phoenix LiveView UI platform and design-to-code compiler.

It has two related but distinct responsibilities:

1. **Reusable LiveView UI library** — a curated catalogue of production-quality Phoenix function components, interactive patterns, sections, page compositions, and eventually templates that can be consumed by Phoenix projects.
2. **Design ingestion and conversion system** — a compiler-style pipeline that accepts structured frontend design sources such as Bricks Builder JSON + Automatic.css configuration, and unstructured sources such as HTML/CSS/JavaScript, normalizes them into a framework-independent LiveFrames Design Intermediate Representation, and produces idiomatic HEEx/LiveView components with compatible styling and interaction behavior.

The central architectural principle is:

> **LiveFrames is not a Bricks converter. Bricks is one input language. LiveFrames is the compiler and reusable LiveView component platform.**

The first serious source stack is:

```text
Bricks Builder copied-component JSON
        +
Automatic.css exported settings JSON
        +
source assets / reference screenshots
        +
optional plugin-source reference knowledge
        |
        v
LiveFrames source adapters
        |
        v
LiveFrames Design IR
        |
        v
normalization + token resolution + componentization
        |
        v
HEEx + Tailwind v4 + CSS + LiveView.JS / colocated hooks
        |
        v
PhoenixStorybook + LiveFrames conversion laboratory
        |
        v
verified reusable LiveFrames component
```

Novamira, Novamira Pro, Automatic.css, Bricks, Frames, and similar tools are **reference/input ecosystems**, not required LiveFrames runtime dependencies.

---

# 2. Ultimate Long-Term Goal

The long-term goal is a reusable Phoenix-native UI platform where a developer can:

1. Browse a catalogue of polished LiveView primitives, components, patterns, sections, pages, and templates.
2. Preview each item interactively and responsively.
3. Understand its attrs, slots, tokens, interactions, accessibility rules, source provenance, and compatibility.
4. Add it to a Phoenix project through a Mix dependency and/or generate/eject the source into the consuming application.
5. Import selected third-party or internal frontend designs through supported adapters.
6. Convert those sources reproducibly into LiveFrames-native HEEx components.
7. Use a coding agent to perform conversions under a deterministic contract rather than free-form “convert this page” instructions.
8. Share a consistent design-token vocabulary across multiple Phoenix applications while still allowing each application to brand and customize itself.

Potential future source adapters include:

- Bricks Builder
- Automatic.css / Frames-oriented Bricks data
- Plain HTML/CSS/JavaScript
- Figma structured exports or API data
- Webflow exports
- other visual builders where the source model can be legally and technically consumed

Potential future outputs include:

- HEEx function components
- LiveComponents where justified
- LiveView pages/patterns
- Tailwind v4 theme bridge
- scoped component CSS
- colocated CSS
- colocated hooks / colocated JS
- optional SCSS compatibility output
- documentation and Storybook stories
- Mix generators for ejected source

---

# 3. MVP Defined Backward From the Ultimate Goal

LiveFrames must not attempt its final vision in the first implementation.

The MVP is the smallest slice that proves the architecture can faithfully understand and convert one real structured design.

## 3.1 MVP input

- One real Bricks copied-component JSON fixture: **Hero India**.
- One Automatic.css settings export matching the design environment.
- Optional reference screenshots and placeholder image assets.
- Local/private access to Automatic.css, Novamira and Novamira Pro source solely as schema/reference material where useful.

## 3.2 MVP output

- LiveFrames Design IR representing Hero India.
- A fidelity-mode HEEx rendering of Hero India.
- A native-mode reusable Hero India function component.
- A normalized token set derived from relevant ACSS settings.
- Tailwind v4 / CSS token integration sufficient to render the component.
- LiveView-compatible interaction classification, even if the first Hero requires no complex client interaction.
- PhoenixStorybook story and custom conversion-lab preview.
- Automated structural, compilation, rendering and responsive tests.

## 3.3 MVP success criteria

The MVP is successful only when:

- Bricks source validation is deterministic.
- ACSS token resolution is deterministic for every token used by the fixture.
- The Design IR contains no WordPress-specific assumptions that the generator requires.
- Generated HEEx compiles.
- The component renders without runtime warnings.
- Required image/assets are resolved or deliberately substituted with documented placeholders.
- Desktop, tablet and mobile previews render correctly.
- Accessibility checks for the generated markup pass the project gate.
- No unresolved conversion diagnostics remain unless explicitly waived.
- The native component exposes a deliberate public API rather than hard-coded source content.
- The preview app can demonstrate both the generated component and its metadata.

---

# 4. Explicit Non-Goals

The following are **not** MVP responsibilities:

- Building a WordPress replacement.
- Running WordPress, Bricks, ACSS or Novamira in production.
- Automatically converting arbitrary WordPress websites.
- Reproducing every Bricks element immediately.
- Supporting every ACSS utility/class immediately.
- Supporting Figma/Webflow/Elementor/Framer before the Bricks + ACSS pipeline proves the IR.
- Building an online marketplace.
- Adding user accounts, subscriptions, payments or a database-backed component CMS.
- Adding Redis, Oban, Ash, PostgreSQL, queues or distributed infrastructure where the library does not need them.
- Reimplementing Tailwind.
- Reimplementing PhoenixStorybook.
- Creating a new JavaScript UI framework.
- Designing custom cryptography or security infrastructure.
- Redistributing third-party proprietary designs without explicit permission.
- Treating AI-generated conversion as authoritative without deterministic validation.

---

# 5. Architectural Principles

## 5.1 Compiler architecture, not string replacement

LiveFrames must parse source systems into structured models and normalize them through an intermediate representation. Direct regex/string substitution from JSON/HTML to HEEx is prohibited as the primary architecture.

## 5.2 Framework-independent Design IR

The Design IR must not contain Bricks class IDs, WordPress post IDs, plugin-specific PHP structures, or other source-only implementation details as its required rendering contract. Source provenance may retain those values for traceability, but generators consume normalized meaning.

## 5.3 Function components by default

Reusable markup defaults to `Phoenix.Component` function components with declarative `attr` and `slot` contracts.

Use `Phoenix.LiveComponent` only where a reusable component genuinely owns isolated state/events and a function component plus parent LiveView event handling would be inferior.

Use nested LiveViews only for independently isolated UI/process concerns where the extra lifecycle/process cost is justified.

## 5.4 Client interaction hierarchy

Preferred order:

1. semantic HTML / CSS only
2. `Phoenix.LiveView.JS`
3. colocated JavaScript
4. colocated hook
5. shared/global hook
6. server event
7. stateful LiveComponent

A server round trip must not be introduced merely to open a dropdown, toggle an accordion, reveal a tooltip, or perform similar presentation-only behavior.

## 5.5 Tokens over source-system coupling

ACSS is interpreted into LiveFrames semantic tokens. Generated components must not require ACSS to be installed in the consuming Phoenix project.

## 5.6 Tailwind v4 is the primary utility integration

LiveFrames uses CSS-first Tailwind v4 theme integration. Legacy `tailwind.config.js` assumptions must not be the canonical architecture.

## 5.7 CSS remains allowed

Do not force every complex source declaration into huge Tailwind class strings. Scoped or colocated component CSS is acceptable when it is clearer, more maintainable, or preserves complex design behavior better.

## 5.8 Fidelity and native conversion are separate concerns

A source may first be rendered faithfully and then normalized into an idiomatic reusable component. Visual fidelity and architecture quality are independently measurable gates.

## 5.9 Source provenance is mandatory

Every imported third-party source must have known origin and allowed usage scope before a resulting component can reach `RELEASED`.

## 5.10 Generated code must be understandable

LiveFrames output is source code humans must be able to maintain. Minified, opaque, excessively generated markup is unacceptable as a released native component.

## 5.11 No unnecessary infrastructure

Static component metadata, tokens, stories and fixtures belong in files/modules. Do not introduce a database or network service to solve a compile-time/static-library concern.

---

# 6. Terminology

| Term | Meaning |
|---|---|
| **Source Artifact** | Raw input supplied to LiveFrames: Bricks JSON, ACSS JSON, HTML/CSS/JS, images, screenshots, etc. |
| **Source Adapter** | Parser/translator for a specific source ecosystem, e.g. Bricks. |
| **Design-System Adapter** | Resolver for design-system semantics, e.g. Automatic.css. |
| **Raw Source Model** | Parsed source-specific representation before normalization. |
| **LiveFrames Design IR** | Framework-independent normalized representation used between import and generation. |
| **TokenSet** | Normalized semantic design tokens. |
| **Fidelity Mode** | Conversion whose first goal is visual equivalence to source. |
| **Native Mode** | Conversion whose first goal is idiomatic, reusable LiveView architecture while retaining intended design. |
| **Primitive** | Small low-level reusable UI building block. |
| **Component** | Reusable UI unit composed of primitives/content. |
| **Pattern** | Reusable interactive/application UI pattern. |
| **Section** | Larger styled composition, e.g. hero, pricing, testimonials. |
| **Page Composition** | Ordered composition of multiple sections. |
| **Template** | Curated multi-page or domain-level UI package. |
| **Story** | PhoenixStorybook representation and variations for a released/previewable item. |
| **Conversion Diagnostic** | Structured warning/error/information emitted during conversion. |
| **Provenance** | Origin, version, license/permission, source hash and usage restrictions. |

---

# 7. Domain / Resource Map

LiveFrames is primarily a compile-time/tooling domain rather than a business-data application. These concepts must still be explicit.

## 7.1 Source domain

### SourceArtifact

Represents an imported input bundle.

Fields/metadata conceptually include:

- `source_id`
- `source_kind`
- `source_name`
- `source_version`
- `source_system`
- `source_url` if relevant
- `received_at`
- `content_hash`
- `provenance`
- `usage_scope`
- `assets`
- `reference_images`
- `status`

### Provenance

- origin type: original / internal / commercial / open-source / unknown
- source vendor
- source URL
- author where known
- license name/text reference
- redistribution allowed: yes/no/unknown
- internal conversion allowed: yes/no/unknown
- commercial project use allowed: yes/no/unknown
- evidence/reference note

## 7.2 Compiler domain

### DesignDocument

Root Design IR object produced from one import/conversion unit.

### DesignNode

Tree node with semantic type, properties, styles, responsive overrides, children and source trace.

### TokenSet

Normalized colors, typography, spacing, sizing, radii, borders, shadows, motion, breakpoints and component tokens.

### Interaction

Normalized client/server behavior intent.

### AssetReference

Logical reference to an image, icon, video, font or other asset.

### ConversionDiagnostic

Structured compiler diagnostic.

### ConversionJob

Represents one deterministic conversion attempt and its lifecycle.

## 7.3 Catalogue domain

### CatalogueItem

Released or previewable primitive/component/pattern/section/page/template.

### ComponentContract

The public attrs, slots, events, CSS/token dependencies, asset contract and accessibility expectations of a component.

### StoryDefinition

Preview variations and states used by PhoenixStorybook.

### ReleaseMetadata

Version, compatibility, deprecation and replacement information.

---

# 8. Lifecycle State Machines

Every lifecycle-bearing concept must be explicit.

## 8.1 SourceArtifact lifecycle

```text
RECEIVED
   |
   v
VALIDATED
   |
   v
CLASSIFIED
   |
   v
APPROVED_FOR_CONVERSION
   |
   v
PARSED

Terminal / side exits:
REJECTED
ARCHIVED
```

### Transitions

**RECEIVED -> VALIDATED**  
Guard:
- input is readable
- supported envelope/file type is detected
- required top-level structure exists

Side effects:
- compute source hash
- record source size/type/version
- create validation diagnostics

**VALIDATED -> CLASSIFIED**  
Guard:
- source kind can be identified
- source version is known or explicitly marked unknown

Side effects:
- select adapter candidate
- classify structured vs unstructured source

**CLASSIFIED -> APPROVED_FOR_CONVERSION**  
Guard:
- provenance record exists
- usage scope is not `unknown` for a release-bound conversion

Side effects:
- select allowed conversion mode(s)

**APPROVED_FOR_CONVERSION -> PARSED**  
Guard:
- adapter supports detected source version or explicit compatibility override exists
- parser completes without fatal errors

Side effects:
- create Raw Source Model
- attach trace IDs from raw nodes to source offsets/IDs

**Any active state -> REJECTED**  
Guard:
- fatal schema problem, unsupported source, prohibited usage, or explicit reviewer rejection

**Any non-terminal state -> ARCHIVED**  
Guard:
- source intentionally retired without conversion

Terminal states: `REJECTED`, `ARCHIVED`, `PARSED` for SourceArtifact responsibility.

## 8.2 ConversionJob lifecycle

```text
PENDING
  |
  v
PARSING
  |
  v
NORMALIZING
  |
  v
COMPONENTIZING
  |
  v
GENERATING
  |
  v
VERIFYING
  |
  v
PASSED

Exceptional states:
NEEDS_REVIEW
FAILED
REJECTED
```

### Guards and side effects

**PENDING -> PARSING**
- source approved
- required adapters available

**PARSING -> NORMALIZING**
- raw tree is structurally valid
- fatal parser diagnostics = 0

**NORMALIZING -> COMPONENTIZING**
- Design IR validates against IR contract
- all required style references are either resolved or represented as explicit unresolved diagnostics

**COMPONENTIZING -> GENERATING**
- target component/page classification selected
- public component contract generated or reviewer-approved

**GENERATING -> VERIFYING**
- output files generated
- formatter succeeds
- compilation succeeds

**VERIFYING -> PASSED**
- compilation/tests pass
- no disallowed diagnostics
- visual/responsive gate passes where reference exists
- accessibility gate passes
- provenance release guard passes

**Any processing state -> NEEDS_REVIEW**
- conversion is technically possible but semantic/style/interaction ambiguity exceeds automatic confidence threshold

**Any processing state -> FAILED**
- implementation/runtime/compiler failure

**Any processing state -> REJECTED**
- reviewer rejects output or source permission prevents intended release

Terminal: `PASSED`, `FAILED`, `REJECTED`.

`NEEDS_REVIEW` is non-terminal and resumes at the appropriate prior stage after resolution.

## 8.3 CatalogueItem lifecycle

```text
DRAFT
  |
  v
GENERATED
  |
  v
REVIEWED
  |
  v
APPROVED
  |
  v
RELEASED
  |
  v
DEPRECATED
```

Guards:

- `DRAFT -> GENERATED`: component source exists and compiles.
- `GENERATED -> REVIEWED`: story, docs and tests exist.
- `REVIEWED -> APPROVED`: architecture + visual + accessibility review accepted.
- `APPROVED -> RELEASED`: provenance/distribution permissions accepted; version metadata assigned.
- `RELEASED -> DEPRECATED`: replacement/removal rationale documented.

Terminal: `DEPRECATED`.

A deprecated item may contain `superseded_by`, but history must remain traceable.

---

# 9. Repository Architecture

Recommended initial repository:

```text
live_frames/
|
|-- mix.exs                         # umbrella root
|-- mix.lock
|-- .formatter.exs
|-- .gitignore
|-- README.md
|
|-- apps/
|   |
|   |-- live_frames/                # reusable library + compiler
|   |   |-- mix.exs
|   |   |-- lib/
|   |   |   |-- live_frames.ex
|   |   |   `-- live_frames/
|   |   |       |-- ir/
|   |   |       |-- source/
|   |   |       |-- importers/
|   |   |       |   |-- bricks/
|   |   |       |   `-- html/
|   |   |       |-- adapters/
|   |   |       |   `-- automatic_css/
|   |   |       |-- normalization/
|   |   |       |-- componentization/
|   |   |       |-- generators/
|   |   |       |   |-- heex/
|   |   |       |   |-- css/
|   |   |       |   |-- tailwind/
|   |   |       |   |-- javascript/
|   |   |       |   `-- documentation/
|   |   |       |-- tokens/
|   |   |       |-- components/
|   |   |       |   |-- primitives/
|   |   |       |   |-- components/
|   |   |       |   |-- patterns/
|   |   |       |   `-- sections/
|   |   |       |-- registry/
|   |   |       |-- diagnostics/
|   |   |       `-- mix/tasks/
|   |   |
|   |   |-- priv/
|   |   |   |-- templates/
|   |   |   `-- themes/
|   |   `-- test/
|   |
|   `-- live_frames_preview/        # real Phoenix + LiveView preview/lab
|       |-- mix.exs
|       |-- lib/
|       |   `-- live_frames_preview_web/
|       |       |-- live/
|       |       |   `-- conversion_lab/
|       |       |-- components/
|       |       `-- storybook.ex
|       |-- assets/
|       |   |-- css/
|       |   `-- js/
|       |-- storybook/
|       `-- test/
|
|-- imports/                        # mutable source intake, not library source code
|   |-- pending/
|   |-- approved/
|   |-- processed/
|   |-- rejected/
|   `-- README.md
|
|-- fixtures/                       # deterministic test fixtures safe for repo
|   |-- bricks/
|   |-- automatic_css/
|   |-- html/
|   |-- expected_ir/
|   `-- assets/
|
|-- private_reference/              # gitignored local vendor/plugin references
|   `-- README.md
|
|-- placeholders/
|   |-- landscape/
|   |-- portrait/
|   `-- square/
|
|-- docs/
|   |-- 00_LIVEFRAMES_MASTER_SPEC.md
|   |-- 01_PRODUCT_BOUNDARIES.md
|   |-- 02_SYSTEM_ARCHITECTURE.md
|   |-- 03_DESIGN_IR_SPEC.md
|   |-- 04_SOURCE_AND_PROVENANCE.md
|   |-- 05_IMPORT_PIPELINES.md
|   |-- 06_ACSS_TOKEN_ADAPTER.md
|   |-- 07_BRICKS_ADAPTER.md
|   |-- 08_COMPONENT_MODEL.md
|   |-- 09_INTERACTION_MODEL.md
|   |-- 10_HEEX_GENERATION_RULES.md
|   |-- 11_CSS_AND_TAILWIND_STRATEGY.md
|   |-- 12_PREVIEW_AND_STORYBOOK.md
|   |-- 13_CONVERSION_WORKFLOW.md
|   |-- 14_AGENT_WORKFLOW.md
|   |-- 15_TESTING_AND_VISUAL_VALIDATION.md
|   |-- 16_PACKAGE_AND_GENERATOR_MODEL.md
|   `-- 17_ROADMAP.md
|
`-- scripts/                         # repo validation helpers only when Mix task is inappropriate
```

## 9.1 Dependency direction

Allowed:

```text
live_frames_preview -> live_frames
```

Forbidden:

```text
live_frames -> live_frames_preview
```

The reusable package must compile and test without the preview app.

## 9.2 Why umbrella initially

An umbrella is justified here because the reusable compiler/package and the full Phoenix preview application have different responsibilities and dependency profiles but must be developed together.

Do **not** create a separate CLI OTP application initially. Mix tasks in `live_frames` are sufficient until a standalone non-Mix CLI is proven necessary.

---

# 10. Source Intake Contract

## 10.1 Preferred source bundle structure

A structured source dropped into LiveFrames should use:

```text
imports/pending/<category>/<source_name>/
|-- source.bricks.json              # when Bricks source exists
|-- acss.settings.json              # optional per-source snapshot; normally shared fixture/theme
|-- source.html                     # optional
|-- source.css                      # optional
|-- source.js                       # optional
|-- SOURCE.md                       # provenance / usage contract
|-- assets/
|   |-- ...
|-- reference/
|   |-- desktop.png
|   |-- tablet.png
|   `-- mobile.png
`-- notes.md                         # optional conversion-specific observations
```

Not every source needs every file.

## 10.2 Required inputs by source type

### Bricks + ACSS / Frames-style source

Minimum:

- Bricks component/page JSON
- ACSS settings snapshot if source depends on ACSS tokens unavailable in the Bricks export
- source provenance

Strongly recommended:

- desktop screenshot
- tablet screenshot
- mobile screenshot
- all local images/assets where redistribution/use is permitted

Optional reference only:

- Automatic.css plugin source
- Novamira / Novamira Pro source
- Bricks installation/runtime

### Plain HTML/CSS/JS

Minimum:

- HTML
- provenance

As applicable:

- CSS
- JavaScript
- external dependency manifest
- screenshots
- assets

## 10.3 SOURCE.md template

```markdown
# Source Provenance

- Source name:
- Source system:
- Source version:
- Source URL:
- Source author/vendor:
- Origin: original | internal | commercial | open-source | unknown
- License:
- Allowed internal conversion: yes | no | unknown
- Allowed project use: yes | no | unknown
- Allowed redistribution in LiveFrames: yes | no | unknown
- Evidence/reference:
- Notes:
```

## 10.4 Do not commit proprietary plugin archives by default

`Automatic.css`, `Novamira Pro`, commercial Frames assets, or other licensed vendor source must not automatically be committed to the LiveFrames repository.

Preferred handling:

- keep archives in `private_reference/` or another gitignored local location
- record filename, version and SHA-256 in a reference manifest
- extract only facts/interfaces necessary to implement a clean-room adapter
- commit only source fixtures that the project has permission to retain/distribute

---

# 11. Bricks Source Adapter

The Bricks adapter is the first structured-source adapter.

## 11.1 Known source shape from the Hero India fixture

The supplied copied-component JSON contains:

- `content`
- `source`
- `sourceUrl`
- `version`
- `components`
- `globalClasses`

A component contains a flat element array where each element can contain:

- `id`
- `name`
- `parent`
- `children`
- `settings`
- `label`

This is valuable because semantic and structural information exists before HTML rendering.

## 11.2 Bricks structural authority rule

The adapter must treat parent relationships as the primary tree-reconstruction authority when source inconsistencies occur, because Bricks tooling can rebuild `children` from parent pointers. The parser must still validate reciprocity and emit diagnostics when `children` and `parent` disagree.

## 11.3 Bricks validation requirements

Before normalization:

- IDs must be unique and non-empty.
- Parent pointers must reference existing nodes or root.
- Circular parent chains are fatal.
- Child arrays must be lists when present.
- Parent/child reciprocity mismatches produce diagnostics.
- `settings` must be an object/map or empty.
- `_cssGlobalClasses` must be treated as a list of class-ID strings, not embedded class objects.
- Unknown element types are preserved as unsupported/raw nodes with diagnostics rather than silently discarded.
- Unknown settings must not be silently assumed to have taken effect.

## 11.4 Bricks classes

Elements refer to global classes by IDs. The adapter resolves those IDs against `globalClasses`.

Example source concept:

```text
Element.settings._cssGlobalClasses
    -> [class_id_a, class_id_b]
    -> globalClasses lookup
    -> class name + settings + category
```

The IR must retain:

- semantic resolved class name where useful
- normalized styles/tokens
- source trace containing original class ID

The generator must not require the original Bricks class ID.

## 11.5 Bricks element semantic mapping

Initial support should deliberately cover only the MVP set:

- `section`
- `container`
- `div`
- `heading`
- `text-basic`
- `button`
- `image`

Unsupported types remain explicit IR nodes/diagnostics until mapped.

## 11.6 Bricks labels and categories

Source labels such as `Hero India`, `Content Wrapper`, `Primary Action`, `Secondary Action`, `Background`, and `Overlay` are semantic hints.

They may improve componentization, but must not be treated as infallible truth.

Priority when determining semantics:

1. explicit supported element type
2. structural context
3. known global-class naming convention
4. component category
5. human label
6. heuristic inference

Heuristic inference must emit confidence metadata.

## 11.7 Bricks source versioning

The adapter must record Bricks source version. Unsupported/new versions must not silently parse under assumed compatibility.

Compatibility policy:

- exact tested version: supported
- known compatible range: supported with compatibility metadata
- unknown version: parse only under explicit experimental mode and emit warning

---

# 12. Automatic.css Design-System Adapter

ACSS is not a runtime requirement. It is a high-information input/reference design system.

## 12.1 Why ACSS is valuable

The supplied settings export includes semantic systems for:

- brand and status colors
- shade families
- OKLCH values
- typography scales
- heading scales
- text scales
- section spacing
- content/grid gaps
- gutter values
- radii
- borders
- shadows
- easing and transitions
- icon values
- card values
- button variants
- contextual background/text relationships
- responsive/mobile adjustments
- breakpoints / viewport min/max
- overlays
- forms
- many feature flags

This allows LiveFrames to infer **design intent**, not merely raw CSS values.

## 12.2 ACSS adapter output

The adapter produces a `LiveFrames.TokenSet` with namespaces such as:

```text
color.brand.primary
color.brand.primary.hover
color.brand.primary.light
color.brand.primary.dark
color.neutral.ultra_dark
color.text.dark
color.text.light

space.content
space.grid
space.section.m
space.gutter.min
space.gutter.max

type.body.base
type.heading.scale

radius.base
border.default
shadow.1
motion.ease.snappy
breakpoint.mobile
breakpoint.tablet
```

Exact namespace names must be frozen in `03_DESIGN_IR_SPEC.md`; examples above are conceptual.

## 12.3 Preserve semantic references

If source style says:

```text
var(--content-gap)
```

prefer normalized token reference:

```text
space.content
```

over immediately resolving to a fixed pixel/rem number.

This permits later theme replacement.

## 12.4 ACSS to Bricks global synchronization knowledge

ACSS plugin reference shows that ACSS can synchronize/import framework classes and colors into Bricks globals. Therefore the Bricks JSON may contain classes whose IDs are Bricks-specific but whose names/semantics originate in ACSS.

The adapter chain must support:

```text
Bricks class ID
   -> Bricks global class record
   -> class name/category
   -> ACSS semantic matcher
   -> LiveFrames token/style semantics
```

## 12.5 Token collision policy

When multiple inputs define the same semantic value:

Priority for structured Bricks + ACSS conversion:

1. element-specific responsive setting
2. element-specific base setting
3. resolved Bricks global class setting
4. normalized ACSS token referenced by the class/value
5. ACSS framework default
6. LiveFrames fallback/default

Every fallback below level 4 should be diagnosable in strict conversion mode.

---

# 13. LiveFrames Design IR

The Design IR is the most important internal contract.

## 13.1 Required qualities

It must be:

- source-system independent
- deterministic
- serializable for fixtures/debugging
- versioned
- validation-friendly
- rich enough for responsive styles and interactions
- traceable back to source
- suitable for multiple output generators

## 13.2 Conceptual root

```text
DesignDocument
|-- ir_version
|-- source_metadata
|-- token_set
|-- root_nodes[]
|-- assets[]
|-- interactions[]
|-- diagnostics[]
`-- provenance
```

## 13.3 Conceptual DesignNode

```text
DesignNode
|-- node_id
|-- semantic_type
|-- semantic_role
|-- label
|-- content
|-- attributes
|-- styles
|-- responsive
|-- interactions
|-- children[]
|-- assets[]
`-- source_trace
```

## 13.4 Initial semantic types

Structural:

- section
- container
- wrapper
- stack
- grid
- generic

Content:

- heading
- paragraph
- rich_text
- image
- icon
- button
- link

Composition hints:

- actions
- background
- overlay

Unsupported source nodes:

- raw
- unsupported

## 13.5 Style IR

Style representation must distinguish:

1. semantic token references
2. literal CSS values
3. calculated values
4. responsive overrides
5. complex CSS rules that cannot safely map to simple properties

Conceptual example:

```yaml
layout:
  position: relative
  display: flex
  align_items: flex-start
  justify_content: flex-end

spacing:
  row_gap:
    token: space.content

size:
  max_width: 70ch

visual:
  background:
    token: color.neutral.ultra_dark
```

## 13.6 Responsive IR

Do not hard-code Bricks breakpoint key names into generator logic.

Normalize to breakpoint identifiers in the TokenSet, e.g.:

```text
base
tablet
mobile
```

The source trace may retain `tablet_portrait`, `mobile_portrait`, etc.

## 13.7 SourceTrace

Every generated/normalized node should preserve enough traceability to answer:

- which source element created this node?
- which global classes affected it?
- which source settings affected a property?
- which adapter made an inferred semantic decision?

This is essential for diagnostics and agent review.

## 13.8 Diagnostics

Diagnostic levels:

- `info`
- `warning`
- `error`
- `fatal`

Diagnostic categories:

- schema
- unsupported_element
- unsupported_style
- unresolved_class
- unresolved_token
- ambiguous_semantics
- asset_missing
- interaction_unsupported
- accessibility
- provenance
- generator
- visual_validation

A diagnostic must contain:

- code
- severity
- human message
- source trace where possible
- suggested action where known

---

# 14. Componentization

The componentization stage converts generic Design IR into a reusable public UI contract.

## 14.1 Componentization is not parsing

Parsing answers:

> What does the source contain?

Componentization answers:

> What reusable LiveView abstraction should this become?

These stages must not be conflated.

## 14.2 Hero India example

The source structurally contains:

```text
section
|-- content wrapper
|   |-- heading
|   |-- lede
|   `-- action group
|       |-- primary action
|       `-- secondary action
`-- background
    |-- image
    `-- overlay
```

A native component contract may become conceptually:

```text
HeroIndia
attrs:
- id
- heading
- lede
- image_src
- image_alt
- class

slots:
- primary_action
- secondary_action

optional configuration:
- image_position
- overlay_variant
```

Do not automatically make every source string an attr. Prefer attrs/slots that represent stable reusable semantics.

## 14.3 Public API rules

A released component must:

- use declarative `attr`/`slot`
- document attrs/slots
- expose semantic names, not source-builder IDs
- provide sensible defaults only when defaults are truly general
- accept `:global` attributes where appropriate
- support consumer-provided `class`/styling extension under a documented policy
- not leak application business logic
- not perform database access
- not silently own server-side domain state

## 14.4 Function component vs LiveComponent decision

Use function component if the item primarily renders markup and can receive behavior through attrs, JS commands, parent LiveView events, colocated hooks, or shared hooks.

Use LiveComponent only if all apply:

- reusable component needs encapsulated state/events
- state is meaningfully local to the component
- parent ownership would create worse coupling
- stable unique component ID can be required

A carousel is not automatically a LiveComponent. A purely visual carousel is usually client-side behavior.

---

# 15. HEEx Generation Rules

## 15.1 Output quality

Generated HEEx must be formatted, semantic and human-maintainable.

Prohibited release output:

- opaque auto-generated IDs where stable semantic IDs are possible
- giant unreviewed inline style strings
- unnecessary wrapper proliferation retained solely because the visual builder produced it
- invalid interactive nesting
- buttons implemented as anchors without navigation semantics, or vice versa
- missing image alt contract
- server events for presentation-only toggles

## 15.2 HTML semantics

Preserve source intent but improve semantics in native mode when safe.

Examples:

- headings retain valid hierarchy or emit diagnostic
- CTA navigation uses `<.link>` where appropriate
- actual actions use `<button type="button">`
- images use meaningful alt input or documented decorative handling
- list-like content should become lists when semantically justified

## 15.3 Dynamic content

Static source text becomes attrs/slots only when the component contract requires customization.

Do not turn every decorative label into a public attr if a slot or internal constant is more appropriate.

## 15.4 IDs

Interactive components requiring DOM targeting must expose or generate stable IDs under Phoenix conventions.

Random IDs generated per render are prohibited.

---

# 16. Styling Architecture

## 16.1 Canonical flow

```text
ACSS / source styles
      |
      v
LiveFrames TokenSet
      |
      v
LiveFrames CSS custom properties
      |
      +-------------------------+
      |                         |
      v                         v
Tailwind v4 @theme          component CSS
      |
      v
HEEx utilities
```

## 16.2 Tailwind v4

Use CSS-first theme variables.

Conceptual bridge:

```css
@import "tailwindcss";

:root {
  --lf-color-primary: ...;
  --lf-space-content: ...;
}

@theme inline {
  --color-primary: var(--lf-color-primary);
}
```

Exact names belong to the token specification.

Do not make legacy JavaScript Tailwind config the primary design-token mechanism.

## 16.3 Style classification algorithm

For each source style:

### A. Standard stable CSS primitive

Examples:

- flex
- grid
- position
- object-cover
- width 100%

Prefer Tailwind utility if output remains readable.

### B. Reusable design decision

Examples:

- primary color
- content gap
- section spacing
- base radius

Normalize to LiveFrames token, then expose through CSS/Tailwind.

### C. Complex component-specific styling

Examples:

- responsive gradients
- intricate overlay behavior
- unusual pseudo-element effects
- complex selector relationships

Use scoped/colocated CSS when clearer than utility explosion.

### D. Untranslatable or unsupported source style

Preserve in fidelity CSS where safe, emit diagnostic, and require native-mode review.

## 16.4 Colocated CSS

Current LiveView supports colocated CSS. LiveFrames may use it for component-specific CSS when:

- CSS is truly owned by the component
- it should travel with generated component source
- it does not represent global theme infrastructure

Global theme/token CSS remains in shared assets.

## 16.5 SCSS policy

SCSS is an optional compatibility/fidelity output, not a required runtime dependency.

Use SCSS only when:

- imported source is naturally maintained in SCSS
- consumer explicitly requests SCSS output
- a legacy design requires it during migration

Native released LiveFrames components should prefer Tailwind v4 + CSS variables + scoped/colocated CSS.

## 16.6 Global CSS prohibition

Imported arbitrary rules must not silently create broad global selectors such as:

```css
h1 {}
button {}
.container {}
```

Any required global behavior belongs to an explicit theme/base layer.

---

# 17. Interaction Conversion Architecture

## 17.1 Classification

Every imported behavior is classified into exactly one primary strategy:

1. CSS-only
2. `Phoenix.LiveView.JS`
3. colocated JS
4. colocated Hook
5. shared Hook
6. server LiveView event
7. stateful LiveComponent
8. unsupported / manual rewrite

## 17.2 Decision guidance

### CSS-only

Use for hover/focus/reveal behaviors that require no application state or imperative DOM logic.

### Phoenix.LiveView.JS

Use for DOM-patch-aware:

- show/hide
- toggle classes
- attributes
- focus
- transitions
- simple modal/accordion/nav behavior

### Colocated JS

Use for small component-owned browser code that does not require full hook lifecycle behavior.

### Colocated Hook

Use for component-owned JS requiring mount/update/destroy lifecycle or DOM/library integration.

Examples:

- a carousel library
- GSAP component animation
- gallery zoom behavior
- resize/observer logic

### Shared Hook

Use when the same hook implementation is intentionally shared across multiple components.

### Server event

Use only when action changes server/application state or requires server-authoritative logic.

### LiveComponent

Use only where encapsulated reusable server state/events are justified.

## 17.3 Imported JS rules

An agent must never copy arbitrary source JS directly into production without review.

It must identify:

- external dependencies
- DOM selectors
- lifecycle assumptions
- global state
- event listeners
- timers/observers
- cleanup requirements
- network calls
- storage usage
- accessibility effects

Every hook must clean up resources/listeners as required.

## 17.4 GSAP and third-party JS

Third-party JS may remain a dependency when it materially provides behavior that would be wasteful or inferior to rewrite.

Dependency addition requires:

- license check
- version pin/range
- bundle-size consideration
- component ownership decision
- fallback/reduced-motion behavior

Do not introduce GSAP merely because source uses GSAP if equivalent native/CSS behavior is trivial.

---

# 18. Fidelity Mode vs Native Mode

## 18.1 Fidelity Mode

Goal: render the imported design as close to the source as practical.

Characteristics:

- preserves more wrappers
- preserves more literal values
- may preserve fidelity CSS
- avoids premature API abstraction
- used to validate parser/style correctness

Output is not automatically release-quality.

## 18.2 Native Mode

Goal: produce idiomatic reusable LiveView source.

Characteristics:

- semantic component API
- attrs and slots
- token normalization
- redundant wrappers may be removed
- Tailwind/CSS simplified
- interactions converted according to LiveView hierarchy
- accessibility hardened
- source-only identifiers removed from public API

## 18.3 Required sequence for difficult imports

```text
source
 -> fidelity conversion
 -> visual validation
 -> native refactor
 -> visual + API + accessibility validation
 -> release
```

This makes it clear whether a regression originates in parsing or architectural normalization.

---

# 19. Asset and Placeholder System

## 19.1 Placeholder families

Initial design should support three aspect-ratio families:

```text
placeholders/
|-- landscape/
|   |-- sm.webp
|   |-- md.webp
|   `-- lg.webp
|-- portrait/
|   |-- sm.webp
|   |-- md.webp
|   `-- lg.webp
`-- square/
    |-- sm.webp
    |-- md.webp
    `-- lg.webp
```

The user may begin with one family / three sizes, but the asset contract must not assume all components use landscape images.

## 19.2 Placeholder rules

Placeholders are for:

- deterministic preview data
- responsive testing
- missing-source-asset development
- documentation screenshots

They must not mask an unresolved production asset in a release conversion. Missing required source assets produce diagnostics.

## 19.3 Image contract

Component APIs should prefer semantic image inputs:

- source
- alt
- optional responsive source set where supported
- object-position/variant only when meaningful to component

Do not embed WordPress attachment IDs in released component APIs.

---

# 20. Preview Application Architecture

LiveFrames requires a real Phoenix application so everything is rendered in the environment consumers will use.

## 20.1 PhoenixStorybook responsibility

Use PhoenixStorybook for:

- component catalogue navigation
- function component stories
- LiveComponent stories
- attrs/slots docs
- variations
- interactive playground
- source display
- iframe isolation where needed
- complex example pages where appropriate

Do not rebuild these generic features unless a proven limitation requires it.

## 20.2 LiveFrames Conversion Lab responsibility

Build custom preview routes for compiler-specific needs:

- source metadata
- source tree inspection
- Design IR inspection
- normalized token inspection
- conversion diagnostics
- fidelity vs native output
- desktop/tablet/mobile views
- reference-vs-generated comparison
- adapter compatibility info

Conceptually:

```text
/storybook/...                  -> catalogue
/liveframes/lab/<conversion>    -> compiler lab
```

## 20.3 No database initially

Story and catalogue metadata remain files/modules.

Add a database only if a future hosted marketplace/CMS requirement proves it necessary.

---

# 21. Testing and Validation

## 21.1 Test layers

### Unit tests

- Bricks schema validation
- tree reconstruction
- class resolution
- ACSS token normalization
- IR validation
- generator functions
- diagnostic generation

### Fixture/golden tests

Input fixtures produce deterministic expected IR snapshots.

Example:

```text
fixtures/bricks/hero_india.json
fixtures/automatic_css/acss_settings.json
fixtures/expected_ir/hero_india.json
```

### Compile tests

Generated HEEx/components must compile under the supported Phoenix/LiveView version range.

### Render tests

Use LiveView/Phoenix test helpers to render components and assert structural output.

### Interaction tests

Validate `Phoenix.LiveView.JS`, hooks and server event behavior as appropriate.

### Browser tests

Use browser automation only for behaviors/visual checks that cannot be adequately verified through lower-cost tests.

### Visual validation

For source conversions with reference screenshots:

- desktop
- tablet
- mobile

Use deterministic viewport sizes and placeholder/source assets.

Pixel-perfect comparison may be used as a signal, not the only truth; rendering engines/font differences require tolerances.

### Accessibility

At minimum validate:

- semantic roles/elements
- headings
- accessible names
- image alt handling
- keyboard operability
- focus behavior
- reduced-motion behavior for animations
- unique IDs

## 21.2 Quality gate order

Fastest failures first:

1. source/IR schema
2. formatter
3. compile
4. unit tests
5. render/interaction tests
6. browser/responsive/a11y
7. visual comparison

---

# 22. Performance and Scaling Review

LiveFrames itself is not a high-concurrency transactional platform. Applying distributed infrastructure by default would be poor architecture.

## 22.1 Data layers

### Hot

Not applicable for core package compilation. Runtime browser behavior should use client-side state where appropriate.

### Warm

Not required for the package MVP.

### Cold

Static fixtures, component source, token files and story definitions in Git/filesystem.

### Browser

Compiled CSS/JS/static assets served normally by Phoenix/CDN in consuming applications.

## 22.2 Performance rules

- Presentation-only interactions should not cause server round trips.
- Avoid excessive generated DOM wrappers.
- Avoid shipping large JS dependencies for tiny behaviors.
- Do not introduce Redis/Postgres lookups to render library components.
- Tailwind/CSS build must remain compatible with production asset optimization.
- Storybook/compiler diagnostics may be development-only where appropriate.

## 22.3 Future large catalogue

If the catalogue grows to thousands of items, optimize static discovery/indexing before considering a database.

---

# 23. Security and Trust Boundaries

Imported frontend source is untrusted input.

## 23.1 Never execute imported JavaScript during parsing

Parser stages inspect JavaScript as text/AST/reference. Do not evaluate arbitrary source scripts on the host.

## 23.2 HTML sanitization awareness

Native released components must not blindly preserve unsafe scripts, inline event handlers, dangerous URLs, or untrusted raw HTML.

## 23.3 Generated code review

Compiler output is not automatically trusted merely because it compiled.

## 23.4 Plugin source

Vendor PHP plugin code is reference material. Do not copy proprietary implementation wholesale into LiveFrames. Implement only the required clean adapter behavior in Elixir.

---

# 24. Package and Distribution Model

## 24.1 Runtime dependency mode

Eventually consumers may use:

```elixir
{:live_frames, "~> 1.x"}
```

for stable reusable components/tokens/tooling.

## 24.2 Ejected/generated mode

For components intended to become application-owned:

```text
mix live_frames.add hero_india
```

may generate source under the consuming application's component directory.

The consumer then owns the generated source and can modify it without runtime lock-in, subject to license terms of the component/source.

## 24.3 Do not choose one mode globally

Some shared primitives/components may be best used directly from the dependency.

Some complex sections/templates are better ejected.

Each catalogue item should declare distribution mode compatibility:

- dependency
- ejectable
- both

---

# 25. Naming Conventions

Package/module naming:

```text
LiveFrames
LiveFrames.IR.*
LiveFrames.Importers.Bricks.*
LiveFrames.Adapters.AutomaticCSS.*
LiveFrames.Components.*
LiveFrames.Sections.*
```

Catalogue IDs:

```text
hero_india
hero_split_001
features_grid_001
pricing_cards_001
```

Avoid source builder random IDs as public names.

File names use snake_case.

Category names should be singular/plural consistently across repository once frozen in catalogue taxonomy.

---

# 26. Agent Operating Model

Agents must execute LiveFrames work as small, reviewable phases.

## 26.1 General agent rules

The agent MUST:

- read this master spec before implementation
- read only the relevant subordinate specs for the current task
- inspect actual source fixtures instead of guessing
- use the least number of tools necessary
- keep one task/PR focused
- preserve provenance and fixture history
- emit diagnostics instead of silently dropping unsupported input
- use current Phoenix/LiveView/Tailwind APIs
- prefer minimal, clear implementations
- avoid speculative abstraction beyond the accepted phase
- stop at the explicit phase STOP condition

The agent MUST NOT:

- implement later phases opportunistically
- redesign the architecture without documenting a contradiction
- add dependencies without justification
- add a database, Redis, Oban, Ash or other infrastructure without a phase requirement
- copy vendor/proprietary plugin code into the package
- silently reinterpret an unsupported Bricks/ACSS setting
- convert arbitrary JS into a server event by default
- claim visual fidelity without rendering/testing it

## 26.2 Minimum tool policy

### Planning/spec tasks

Use:

- filesystem/code inspection
- official web documentation only when current APIs/versions matter
- Git/GitHub once repo exists

Do not use browser automation unless rendering behavior is under review.

### Parser/token tasks

Use:

- filesystem/code inspection
- Elixir tests
- vendor source locally only where schema behavior is genuinely unclear

### Visual/component conversion tasks

Use:

- filesystem/code inspection
- mix compile/test/format
- preview app
- browser automation for responsive/visual/interactive validation

### External vendor tools

Do not call a running WordPress/Bricks system unless a task specifically needs runtime comparison that static fixtures cannot answer.

## 26.3 Standard conversion task contract

Every conversion request must identify:

- component/source name
- source type
- source paths
- provenance status
- conversion mode: fidelity/native/both
- expected component category
- target output path
- applicable token set
- required visual reference
- known interactions
- acceptance gates
- STOP condition

---

# 27. Standard Conversion Workflow

## Step 1 — Intake

Collect source bundle and provenance.

Output:

- SourceArtifact record/metadata
- content hash

STOP if provenance/usage is insufficient for intended target.

## Step 2 — Validate source

Run source-specific validation.

For Bricks:

- validate root envelope
- version
- element IDs
- parent relationships
- children reciprocity
- settings shapes
- class-ID references

STOP on fatal source errors.

## Step 3 — Parse

Convert raw source into source-specific parsed model.

No HEEx generation yet.

## Step 4 — Resolve design system

Resolve Bricks globals, ACSS semantics and token references.

Emit unresolved-token diagnostics rather than guessing.

## Step 5 — Normalize to Design IR

Produce valid IR fixture.

Gate: IR schema validation passes.

## Step 6 — Fidelity componentization/rendering

Create minimal abstraction necessary to render source faithfully.

Gate: compile + visual comparison.

## Step 7 — Native componentization

Define public attrs/slots and simplify source-builder artifacts.

Gate: API review.

## Step 8 — Interaction rewrite

Classify and implement each behavior using interaction hierarchy.

Gate: interaction tests + keyboard/reduced-motion checks where applicable.

## Step 9 — Styling normalization

Map tokens, Tailwind utilities and scoped/colocated CSS.

Gate: no unexplained source-global CSS leakage.

## Step 10 — Story + conversion lab

Add story variations and compiler metadata preview.

## Step 11 — Full verification

- format
- compile
- tests
- story render
- browser responsive check
- accessibility
- visual comparison
- diagnostics = acceptable

## Step 12 — Release decision

Transition catalogue item only after provenance/distribution gate.

---

# 28. Detailed Roadmap

## Phase 0 — Authority and Repository Foundation

### Goal

Create the project skeleton and freeze architecture before compiler implementation.

### Sub-phases

**P0.1 Repository initialization**
- initialize Git repository
- create umbrella
- create reusable `live_frames` app
- create Phoenix `live_frames_preview` app

**P0.2 Quality foundation**
- formatter
- compiler warnings policy
- tests
- CI
- `git diff --check`

**P0.3 Documentation authority**
- commit master spec
- create subordinate spec placeholders

**P0.4 Source/privacy structure**
- imports/fixtures/private_reference separation
- gitignore vendor archives/private references

### Gate

- clean repository
- umbrella compiles
- tests pass
- preview app boots
- library does not depend on preview

### STOP

Do not implement Design IR, Bricks parsing or real components.

---

## Phase 1 — Preview and Storybook Foundation

### Goal

Establish the rendering environment before creating catalogue content.

### Sub-phases

**P1.1 PhoenixStorybook integration**
- mount storybook
- configure content path/assets

**P1.2 trivial architecture-proof component**
- one internal non-production function component proving library -> preview integration

**P1.3 conversion lab shell**
- empty/static routes for future IR/diagnostic display

**P1.4 Tailwind v4 base**
- verify CSS-first theme setup
- no ACSS tokens yet

### Gate

- Storybook loads
- trivial library component appears
- preview app hot reload works

### STOP

Do not convert Hero India.

---

## Phase 2 — Design IR Contract

### Goal

Freeze the framework-independent internal representation.

### Sub-phases

**P2.1 IR versioning and structs**
- DesignDocument
- DesignNode
- SourceTrace
- diagnostics

**P2.2 Style IR**
- literals
- tokens
- responsive overrides
- complex CSS representation

**P2.3 Interaction IR**
- normalized intent

**P2.4 Asset IR**

**P2.5 validation + serialization**

### Gate

- IR can be constructed and serialized independently of Bricks
- validation tests cover invalid graphs/styles

### STOP

No Bricks parser and no HEEx generator.

---

## Phase 3 — Automatic.css Token Adapter

### Goal

Convert the supplied ACSS settings JSON into a deterministic LiveFrames TokenSet.

### Sub-phases

**P3.1 settings loader/schema tolerance**

**P3.2 core color mapping**
- primary/base/neutral/accent
- variants

**P3.3 spacing/layout tokens**
- content gap
- grid gap
- section spacing
- gutter

**P3.4 typography tokens**

**P3.5 button/component tokens required by Hero India**

**P3.6 responsive/breakpoint tokens required by Hero India**

Do not map every ACSS setting in v1.

### Gate

- relevant known ACSS values convert deterministically
- unused unknown settings do not block
- required unknown settings produce diagnostics

### STOP

No Hero HEEx generation.

---

## Phase 4 — Bricks Structural Adapter

### Goal

Convert Hero India Bricks JSON into structurally correct LiveFrames Design IR.

### Sub-phases

**P4.1 Bricks envelope/version parser**

**P4.2 flat-element validation**

**P4.3 tree reconstruction**

**P4.4 supported element mapping**

**P4.5 global class resolution**

**P4.6 style setting normalization**

**P4.7 ACSS semantic resolution**

**P4.8 golden expected IR fixture**

### Gate

Hero India fixture -> deterministic expected IR with no fatal diagnostics.

### STOP

Do not create final Hero component.

---

## Phase 5 — Fidelity HEEx Generator

### Goal

Prove IR can render the source accurately.

### Sub-phases

**P5.1 structural HEEx renderer**

**P5.2 fidelity style renderer**

**P5.3 image placeholder/source mapping**

**P5.4 preview integration**

**P5.5 responsive visual comparison**

### Gate

Hero India fidelity output passes agreed visual tolerance at required viewports.

### STOP

Do not yet refactor into the final reusable native API if that could obscure fidelity debugging.

---

## Phase 6 — Native Componentization

### Goal

Create the first production-quality LiveFrames section from proven fidelity output.

### Sub-phases

**P6.1 component API proposal**

**P6.2 attr/slot implementation**

**P6.3 semantic HEEx cleanup**

**P6.4 token/Tailwind/CSS cleanup**

**P6.5 documentation**

**P6.6 PhoenixStorybook variations**

### Gate

- native component API approved
- visual intent retained
- accessibility pass
- no source-builder IDs leaked into API

### STOP

Do not generalize a full hero framework from one example unless a second example proves commonality.

---

## Phase 7 — Interaction Compiler Foundation

### Goal

Support imported interactive HTML/JS examples already collected in the project.

Recommended learning order:

1. CSS tooltip
2. elastic accordion
3. gallery enlargement
4. carousel
5. infinite scroll
6. GSAP examples

### Sub-phases per interaction

- source behavior analysis
- interaction classification
- minimal LiveView-native implementation
- cleanup/lifecycle handling
- reduced-motion/a11y
- story + tests

### Gate

Each pattern demonstrates the correct interaction strategy rather than indiscriminate hooks/server events.

---

## Phase 8 — Plain HTML/CSS/JS Adapter

### Goal

Support unstructured frontend intake without compromising the IR architecture.

### Sub-phases

- HTML parser
- CSS association strategy
- JS inventory/analyzer
- semantic inference with confidence
- IR generation

### Gate

At least two existing `convert-this` fixtures convert through the same IR/generator pipeline.

---

## Phase 9 — Catalogue Expansion

### Goal

Build curated library quality, not volume for its own sake.

Initial categories:

- heroes
- feature sections
- testimonials/social proof
- CTA
- pricing
- FAQ
- navigation
- footer

Gate for new category:

- naming standard
- minimum story variations
- accessibility contract
- theme behavior

---

## Phase 10 — Generator / Ejection System

### Goal

Allow selected catalogue items to be copied into consuming Phoenix projects safely.

Possible interface:

```text
mix live_frames.add hero_india
```

Must handle:

- module namespace rewrite
- required assets
- token/theme prerequisites
- hook/colocated asset requirements
- conflict detection
- deterministic output

STOP on existing-file conflict unless explicit overwrite option is supplied.

---

## Phase 11 — Package Release Readiness

### Goal

Prepare stable dependency consumption.

Deliver:

- semantic versioning policy
- compatibility matrix
- changelog
- docs
- release test project
- dependency audit
- package contents audit

---

## Phase 12 — Additional Source Adapters

Only after the first pipelines are stable.

Candidate order must be driven by real use:

- Figma
- Webflow
- other builders

Each source must enter through the same Design IR, not a dedicated direct-to-HEEx shortcut.

---

# 29. Failure Modes and Risk Review

## 29.1 Bricks schema drift

Risk: source versions change field shapes.

Mitigation:

- versioned adapter compatibility
- fixture matrix
- explicit warnings for unknown versions

## 29.2 ACSS schema size/complexity

Risk: attempting to model thousands of settings stalls the project.

Mitigation:

- map only tokens required by supported fixtures/features
- expand adapter incrementally

## 29.3 Visual-builder cruft becomes public API

Mitigation:

- separate fidelity and native modes
- API review gate

## 29.4 Tailwind class explosion

Mitigation:

- style classification rules
- tokens + scoped/colocated CSS

## 29.5 JS conversion becomes fragile

Mitigation:

- explicit interaction classification
- current LiveView colocated hooks/JS
- browser tests only where useful

## 29.6 Vendor lock-in

Mitigation:

- framework-independent IR
- ACSS/Bricks only adapters

## 29.7 Copyright/licensing

Mitigation:

- provenance state machine
- release guard
- private reference storage

## 29.8 Overengineering compiler abstractions

Mitigation:

- every IR feature must be justified by a real fixture or near-term generator need
- no generic plugin architecture before second adapter proves need

## 29.9 Agent scope creep

Mitigation:

- one phase/PR
- explicit STOP condition
- task-specific allowed files/tools

## 29.10 Preview app becomes product logic dependency

Mitigation:

- strict dependency direction
- library tests independent of preview

---

# 30. Current Source/Reference Set

The current planning effort has access to:

1. **Hero India Bricks JSON example** containing component elements and global classes.
2. **Automatic.css settings JSON export** containing the current design-system configuration.
3. **Automatic.css 4.0.1 plugin archive** as local reference material.
4. **Novamira 1.11.6 plugin archive** as local reference material.
5. **Novamira Pro plugin archive** containing Bricks-oriented abilities such as content/settings/elements/components/interactions/variables/global classes/templates.
6. **LiveFrame.tar.gz** containing initial plain HTML/CSS/JS conversion candidates, including carousel, accordion, tooltips, gallery, GSAP and infinite-scroll examples.

These inputs are enough to author the architecture and begin Phase 0-4 planning. They do not need to be supplied again within the current working conversation/session.

Before repository execution begins, the fixtures/reference policy in Section 10 must be followed so agents can access the approved sources consistently.

---

# 31. Upload / Fixture Policy for Future Work

## 31.1 No re-upload required right now

For the current planning work, do not upload the Bricks JSON, ACSS JSON, ACSS plugin, Novamira or Novamira Pro again.

## 31.2 What should enter the repository

Recommended safe fixtures after review/scrubbing:

- Hero India Bricks JSON
- ACSS settings export that you own/control
- placeholder/reference images you own or may distribute
- expected IR snapshots
- plain HTML/CSS/JS examples you own or may retain

## 31.3 What should normally remain private/local

Unless licensing explicitly allows redistribution:

- Automatic.css plugin ZIP/source
- Novamira Pro plugin ZIP/source
- commercial Frames source/layout exports
- other proprietary vendor packages

Keep local in a gitignored reference location and record version/hash.

## 31.4 When a re-upload is needed

Re-upload/provide again only if:

- working in a different environment where the original attachment is no longer available
- a newer plugin/source version must be analyzed
- a different ACSS configuration/theme is being converted
- a new Bricks component/page is being converted
- source/reference assets were not previously provided

Every new Bricks component conversion should provide its own Bricks JSON and, ideally, reference screenshots. The ACSS settings need not be repeated for every component if all components use the same frozen TokenSet/theme version.

---

# 32. Scaffolding TOON Prompt

| Field | Content |
|---|---|
| **Task** | Scaffold the LiveFrames umbrella repository with a reusable `live_frames` package and separate Phoenix LiveView `live_frames_preview` application, implementing only Phase 0 foundation contracts. |
| **Objective** | Establish the permanent package/preview/source-fixture boundaries required for the design compiler and reusable LiveView catalogue before any Bricks, ACSS or HEEx conversion logic is written. |
| **Output** | Root umbrella; `apps/live_frames`; `apps/live_frames_preview`; `imports`; `fixtures`; gitignored `private_reference`; `placeholders`; `docs`; formatter/test/CI foundation; preview app that boots; dependency direction proof. |
| **Note** | Use current supported Phoenix/LiveView and Tailwind v4 conventions. Do not add Ash, Postgres, Redis, Oban, a separate CLI app, Bricks parser, ACSS adapter, real catalogue sections, or arbitrary third-party JS. The reusable package must not depend on the preview app. Vendor plugin archives must remain gitignored/private unless redistribution permission is proven. Required DB indexes/caching/Redis structures: none; this phase is static/tooling code. CDN/browser caching applies only to preview static assets. PubSub rules: none beyond Phoenix defaults; no realtime domain state. **STOP when the umbrella compiles, tests pass, preview boots, repo is clean, docs/folder contracts exist, and no Phase 1+ implementation has begun.** |

---

# 33. Initial Phase TOON Execution Prompts

## P0 — Foundation

| Field | Content |
|---|---|
| **Task** | Implement Phase 0 repository foundation exactly as defined in this master spec. |
| **Objective** | Create a stable project boundary so later compiler tasks cannot blur reusable library code, preview code, fixtures and proprietary reference inputs. |
| **Output** | Working umbrella repository, two apps, docs/fixtures/imports/private-reference/placeholders structure, baseline CI/tests. |
| **Note** | No conversion code. No real UI catalogue content. No unnecessary dependencies. Performance: static filesystem/code only; no DB/cache. **STOP at Phase 0 gate.** |

## P1 — Preview foundation

| Field | Content |
|---|---|
| **Task** | Add PhoenixStorybook and the LiveFrames Conversion Lab shell to `apps/live_frames_preview`. |
| **Objective** | Establish the canonical environment for rendering future library components and inspecting compiler artifacts. |
| **Output** | Mounted Storybook, trivial internal proof component, empty/static conversion-lab page, Tailwind v4 base. |
| **Note** | Do not convert Hero India. Do not add DB. Keep library->preview dependency forbidden. Static assets browser-cache normally. **STOP at Phase 1 gate.** |

## P2 — Design IR

| Field | Content |
|---|---|
| **Task** | Implement the versioned LiveFrames Design IR structs, validation, serialization and diagnostics without source-specific parser logic. |
| **Objective** | Freeze a framework-independent compiler contract before coupling to Bricks or ACSS. |
| **Output** | IR modules/tests covering root document, nodes, styles, responsive values, interactions, assets, source trace and diagnostics. |
| **Note** | No Bricks names in required IR contracts. No HEEx generator. No DB/cache. **STOP after IR validation tests prove valid and invalid examples.** |

## P3 — ACSS adapter

| Field | Content |
|---|---|
| **Task** | Implement the minimal Automatic.css settings adapter required to normalize the supplied design configuration into a LiveFrames TokenSet for Hero India. |
| **Objective** | Prove design-system intent can be separated from ACSS and reused by LiveFrames generators/themes. |
| **Output** | ACSS loader, token normalization modules, deterministic token fixture/tests for Hero India requirements. |
| **Note** | Do not attempt every ACSS setting. Unknown unused values may be retained/ignored with diagnostics; required unresolved values must fail strict mode. ACSS plugin is reference only. No runtime ACSS dependency. **STOP at Phase 3 gate; do not parse Bricks yet.** |

## P4 — Bricks adapter

| Field | Content |
|---|---|
| **Task** | Parse and normalize the approved Hero India Bricks JSON fixture into LiveFrames Design IR using the accepted ACSS TokenSet. |
| **Objective** | Prove the first structured source adapter can reconstruct structure, resolve global classes and preserve source trace without generating HEEx. |
| **Output** | Bricks envelope parser, validators, tree builder, supported-element mapping, global-class resolver, relevant style normalization, expected IR golden fixture/tests. |
| **Note** | Parent pointers are structural authority where reciprocity differs; emit diagnostic. `_cssGlobalClasses` is a list of class-ID strings. Preserve unsupported elements explicitly. Novamira source may be inspected only to clarify Bricks schema behavior; do not copy its implementation. **STOP when Hero India -> expected IR is deterministic; no HEEx generation.** |

---

# 34. Acceptance Definition for this Master Spec

This document is ready to freeze as v0.1.0 when the maintainer accepts these core decisions:

1. LiveFrames is both a reusable LiveView UI platform and a design compiler.
2. The LiveFrames Design IR is the central internal contract.
3. Bricks and ACSS are adapters, not core runtime dependencies.
4. Novamira/ACSS plugin source is reference material, not bundled dependency code.
5. Function components are default.
6. Tailwind v4 + semantic CSS variables is the primary style architecture.
7. scoped/colocated CSS is allowed when cleaner than utility-only output.
8. SCSS is optional compatibility output.
9. LiveView 1.2 colocated hooks/JS/CSS are preferred for component-owned behavior/assets where appropriate.
10. PhoenixStorybook provides the generic component catalogue; LiveFrames builds only compiler-specific preview tooling around it.
11. Fidelity mode and native mode are distinct conversion stages.
12. Provenance gates release/distribution.
13. Vendor plugin archives are private/reference by default.
14. Phase implementation is sequential with explicit STOP gates.
15. No unnecessary DB/Redis/Oban/Ash infrastructure is introduced into this tooling project.

Once accepted, subordinate specifications should refine — not contradict — this master authority.

---

# 35. Final Build Order

```text
P0  Repository foundation
 |
 v
P1  Phoenix preview + Storybook
 |
 v
P2  LiveFrames Design IR
 |
 v
P3  Automatic.css TokenSet adapter
 |
 v
P4  Bricks -> Design IR
 |
 v
P5  Design IR -> fidelity HEEx/CSS
 |
 v
P6  Native LiveView componentization
 |
 v
P7  Interaction conversion foundation
 |
 v
P8  Plain HTML/CSS/JS adapter
 |
 v
P9  Catalogue expansion
 |
 v
P10 Mix ejection/generator
 |
 v
P11 Package release
 |
 v
P12 Additional import adapters
```

The project must resist skipping directly to P5/P6 because the visible result is tempting. The value of LiveFrames is the reusable, deterministic pipeline that makes the hundredth conversion easier and safer than the first.

---


---

# 36. Reference Evidence and Known Local Source Paths

This section records why specific architecture decisions exist. It is not permission to copy vendor implementations.

## 36.1 Novamira Pro Bricks reference surface

The locally reviewed Novamira Pro archive exposes dedicated Bricks-oriented abilities under:

```text
novamira-pro/includes/abilities/bricks/
```

Observed files include:

```text
check-setup.php
create-template.php
get-content.php
get-settings.php
helpers.php
insert-content.php
list-elements.php
list-settings.php
list-templates.php
manage-color-palette.php
manage-components.php
manage-dynamic-data.php
manage-global-classes.php
manage-interactions.php
manage-template-conditions.php
manage-theme-styles.php
manage-variables.php
patch-elements.php
remove-content.php
set-content.php
set-post-types.php
set-settings.php
```

The important architectural conclusion is not that LiveFrames should depend on Novamira. It is that Bricks has discoverable, inspectable concepts for elements, settings, global classes, components, variables and interactions that justify treating Bricks JSON as structured compiler input.

The reviewed `helpers.php` contains validation concepts that are useful as behavioral reference, including:

- flat element arrays
- unique element IDs
- parent pointers and children reciprocity
- circular parent detection
- `_cssGlobalClasses` shape validation
- element control/settings validation
- custom CSS shape checks
- border/typography/scalar shape checks
- Bricks CSS generation/verification concepts

LiveFrames should independently implement only the behavior required by its clean Elixir adapter and test fixtures.

## 36.2 Automatic.css reference surface

The locally reviewed Automatic.css 4.0.1 archive contains:

```text
automatic-css/classes/Features/Bricks_Globals_Sync/Bricks_Globals_Sync.php
automatic-css/classes/UI/Settings_Page/Import_Export.php
```

The Bricks globals synchronization code demonstrates that ACSS framework classes/colors can be materialized into Bricks global data, including WordPress options for Bricks global classes/color palette.

The Import/Export settings page obtains framework variables from the ACSS settings model and serializes them as JSON. This supports treating the user's ACSS JSON export as the primary deterministic settings input instead of requiring a running WordPress/ACSS installation during conversion.

## 36.3 Private reference manifest

When repository implementation starts, create a gitignored manifest conceptually like:

```text
private_reference/MANIFEST.md
```

Record for each local archive:

- filename
- product
- version
- SHA-256
- acquisition/source note
- why LiveFrames needs reference access
- redistribution status

Do not include secrets, license keys or account credentials.

---

# 37. Worked Conversion Trace — Hero India

The following is the first canonical end-to-end example the implementation should support.

## 37.1 Source component

The Bricks payload identifies a component categorized as `Hero` and labeled `Hero India`.

Root element:

```text
id: sqhmmc
name: section
label: Hero India
```

Children:

```text
2ef2fa  Content Wrapper
1c85d9  Background Alpha
```

## 37.2 Root class resolution

The root references global classes including:

```text
6lGpftooejv
acss_import_bg--ultra-dark
```

Global-class lookup resolves approximately:

```text
6lGpftooejv
  -> fr-hero-india
  -> position: relative
  -> isolation: isolate
```

and:

```text
acss_import_bg--ultra-dark
  -> bg--ultra-dark
  -> category: acss
```

The ACSS-imported class may contain little/no local Bricks settings because its styling meaning belongs to the ACSS framework. The ACSS adapter therefore resolves the semantic class through the imported ACSS configuration/framework token system rather than assuming an empty class has no effect.

Conceptual IR result:

```yaml
semantic_type: section
semantic_role: hero
styles:
  layout:
    position: relative
    isolation: isolate
  visual:
    background:
      token: color.neutral.ultra_dark
source_trace:
  element_id: sqhmmc
  global_classes:
    - 6lGpftooejv
    - acss_import_bg--ultra-dark
```

## 37.3 Content wrapper

Bricks class:

```text
fr-hero-india__content-wrapper
```

Relevant source settings include:

```text
row gap: var(--content-gap)
align-items: flex-start
justify-content: flex-end
position: relative
z-index: 1
margin-top: 400
```

Normalization rules:

- `var(--content-gap)` -> semantic LiveFrames content-gap token where resolvable.
- flex alignment/justification -> standard layout values.
- position/z-index -> literal structural style unless normalized token exists.
- bare numeric margin values require Bricks-unit interpretation from the source schema; do not guess units silently.

If source-unit meaning is uncertain, emit a diagnostic and consult tested Bricks behavior/reference fixture before release.

## 37.4 Heading

Source:

```text
name: heading
text: Hero heading
tag: h1
```

Fidelity IR:

```yaml
semantic_type: heading
content:
  text: Hero heading
attributes:
  level: h1
```

Native componentization converts the source literal into a deliberate public attr such as `heading`.

## 37.5 Lede

Source element:

```text
name: text-basic
tag: p
label: Lede
```

Global classes:

```text
fr-hero-india__lede
fr-lede
```

Known local style includes:

```text
max-width: 70ch
```

Native componentization should expose the text as `lede` or a content slot based on the accepted component API, not expose Bricks class IDs.

## 37.6 Action group

Source wrapper:

```text
fr-cta-links-alpha
```

Known behavior/styles include:

- display flex
- wrap
- row/column gap using content gap
- width 100%
- mobile custom CSS making direct children full width

Children:

```text
Primary Action
Secondary Action
```

The first button is primary. The second uses the same primary style plus an outline flag.

Native componentization should normally use action slots rather than hard-code URLs/text into the hero implementation:

```text
primary_action slot
secondary_action slot
```

The component must not assume every CTA navigates; callers choose link/button semantics through the slot content unless a narrower contract is explicitly accepted.

## 37.7 Background image

The source image is positioned absolutely and covers the section.

Known relevant settings include:

```text
position: absolute
inset: 0
width: 100%
height: 100%
object-fit: cover
object-position base: 70% 50%
object-position tablet portrait: 50% 50%
```

LiveFrames IR must preserve responsive object-position as a breakpoint override.

WordPress attachment information such as numeric media ID must remain source trace only. The native component takes a Phoenix/web asset source.

## 37.8 Overlay

The overlay contains:

- absolute inset
- z-index
- semantic/custom background variable
- base gradient
- different tablet-portrait gradient

This is a good example of a style that may be cleaner as scoped/colocated component CSS rather than an enormous utility-class expression.

The parser must represent both gradients structurally enough to regenerate them or preserve them as validated fidelity CSS.

## 37.9 Expected conversion outputs

### Phase 4 output

Design IR only.

No final component.

### Phase 5 output

Fidelity rendering that visually reproduces Hero India using resolved tokens/literal fallback CSS.

### Phase 6 output

Native function component with an API conceptually similar to:

```text
attrs:
- id
- heading
- lede
- image_src
- image_alt
- class

slots:
- primary_action
- secondary_action
```

plus internal styling based on LiveFrames tokens and appropriate responsive behavior.

The exact API must be proposed and reviewed in Phase 6; this master spec does not freeze individual attr names beyond the semantic intent.

---

# 38. Technology Baseline Verification Policy

The project architecture is based on the current Phoenix ecosystem as verified on 2026-08-27, including:

- Phoenix 1.8-generation component/layout conventions
- Phoenix LiveView 1.2-generation APIs
- LiveView declarative function-component attrs and slots
- `Phoenix.LiveView.JS`
- colocated hooks and colocated JavaScript
- colocated CSS support introduced in LiveView 1.2
- Tailwind CSS v4 CSS-first `@theme` variables
- PhoenixStorybook 1.3-generation component stories/variations

These are not permanent hard pins inside this document.

At Phase 0 repository initialization the coding agent MUST verify the currently compatible stable versions and record them in the actual project dependency files/compatibility document.

The agent must not silently upgrade major framework versions later. Major-version changes require a compatibility review because they can affect generated-source contracts.

---

# 39. Master Spec STOP Condition

This master specification intentionally stops before implementation code.

The next action after acceptance is **Phase 0 only**.

An agent receiving this document must not interpret it as permission to execute the entire roadmap in one run.

Global STOP rule:

> Execute only the explicitly authorized phase/task. Once that phase's gate is satisfied, produce evidence, commit/open the expected PR if requested, and STOP. Do not begin the next phase unless separately instructed.

# END OF MASTER SPEC
