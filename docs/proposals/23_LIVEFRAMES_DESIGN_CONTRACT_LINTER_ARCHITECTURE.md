# LiveFrames Design Contract Linter Architecture

**Document:** `23_LIVEFRAMES_DESIGN_CONTRACT_LINTER_ARCHITECTURE.md`  
**Version:** `0.1.0`  
**Status:** PROPOSED architecture and implementation authority  
**Date:** 2026-09-23  
**Scope:** LiveFrames native-component design-contract linting  
**Decision class:** Cross-cutting developer tooling / CI governance  
**Implementation authorization:** This document defines the recommended architecture and phased implementation plan. It does **not** authorize catalogue work, generator/ejection work, source-runtime coupling, or unrelated component expansion.

---

## 0. Executive decision

LiveFrames should adopt the **design-system enforcement philosophy** demonstrated by `@shadcn/lint`, but it should **not** make `@shadcn/lint`, ESLint, Oxlint, Node.js, React-style ASTs, or a fork of the shadcn implementation foundational dependencies of LiveFrames.

The correct LiveFrames implementation is a **native Elixir design-contract linter** with first-class knowledge of:

- Phoenix HEEx (`.heex` and `~H` sigils);
- Phoenix function-component identity and public API contracts;
- LiveFrames semantic `.lf-*` classes;
- LiveFrames public `--lf-*` theme tokens;
- component-private `--lf-<component>-*` composition variables;
- TokenSet and token-mapping authority;
- ordinary CSS as a first-class styling mechanism;
- Tailwind v4 as an optional/build-time compatibility syntax, not design authority;
- source-system leakage boundaries;
- deterministic diagnostics suitable for coding agents and CI.

The target command is:

```sh
mix lf.lint
```

and, after the tracer is proven and the rule set is promoted to enforcement:

```text
mix format --check-formatted
→ mix compile --warnings-as-errors
→ mix lf.lint
→ mix assets.build
→ artifact drift check
→ mix test
→ mix deps.unlock --check-unused
→ git diff --check
```

The linter must be **fail closed**: inability to prove a file or construct compliant is never reported as compliant.

---

## 1. Why this work exists

LiveFrames is no longer merely converting source designs. It now has an accepted native component lifecycle, an explicit CSS/Tailwind strategy, a public token surface, private composition variables, semantic component classes, and consumer responsibilities.

That creates a new governance problem:

> The rules exist in documentation, code and tests, but an agent or contributor can still bypass them while producing syntactically valid Phoenix code.

Examples:

```heex
<Hero.hero
  heading="Welcome"
  class="bg-red-500 p-[72px] rounded-[19px]"
/>
```

```css
.lf-card {
  background: #ef4444;
  padding-inline: 17px;
}
```

```css
.consumer-theme {
  --lf-hero-overlay-gradient-desktop: linear-gradient(...);
}
```

```heex
<div class={"lf-card--#{@variant}"}>
```

All can be valid source code while violating LiveFrames' intended design authority or making compliance impossible to prove statically.

A written instruction in `AGENTS.md` is necessary but insufficient. Coding agents need executable, deterministic feedback at the point of violation.

The primary objective is therefore:

> Convert existing LiveFrames design-system authority into machine-verifiable contracts without creating a competing source of truth.

---

## 2. Research baseline

This proposal was prepared against the repository state visible on **2026-09-23**.

### 2.1 `@shadcn/lint`

Current inspected package facts:

- package: `@shadcn/lint`;
- inspected version: `0.2.0`;
- licence: MIT;
- Node requirement: `>=20.19`;
- design target: Tailwind v4 design systems;
- shadcn/ui itself is not required;
- supported template families documented by the project: React/JSX, Vue and Svelte;
- engines: ESLint and Oxlint;
- main rule families inspected:
  - `no-restyle`;
  - `no-raw-colors`;
  - `no-arbitrary-values`;
  - `no-inline-styles`;
  - `no-unknown-classes`;
  - `require-static-classes`.

The implementation's template reader abstraction currently dispatches only to JSX, Svelte and Vue readers. There is no HEEx reader in the inspected implementation.

Useful upstream references:

- <https://github.com/shadcn-ui/lint>
- <https://github.com/shadcn-ui/lint/blob/main/README.md>
- <https://github.com/shadcn-ui/lint/blob/main/docs/rules.md>
- <https://github.com/shadcn-ui/lint/blob/main/docs/design-systems.md>
- <https://github.com/shadcn-ui/lint/blob/main/docs/adoption.md>
- <https://github.com/shadcn-ui/lint/blob/main/docs/evals.md>
- <https://github.com/shadcn-ui/lint/blob/main/packages/lint/src/sites/readers/types.ts>
- <https://github.com/shadcn-ui/lint/blob/main/packages/lint/src/sites/readers/index.ts>
- <https://github.com/shadcn-ui/lint/blob/main/LICENSE>

### 2.2 LiveFrames

Inspected LiveFrames authority includes:

- `docs/11_CSS_AND_TAILWIND_STRATEGY.md`;
- `docs/16_PACKAGE_AND_GENERATOR_MODEL.md`;
- `docs/19_PHASE_6_NATIVE_COMPONENTIZATION.md`;
- `docs/20_P6_4A_NATIVE_STYLING_BRIDGE_ARCHITECTURE.md`;
- `docs/21_P6_4B2_NATIVE_HERO_BROWSER_VERIFICATION.md`;
- `docs/22_P6_6_NATIVE_HERO_STORYBOOK_VERIFICATION.md`;
- `AGENTS.md`;
- `apps/live_frames/lib/live_frames/components/sections/hero.ex`;
- `apps/live_frames/assets/css/components/sections/hero.css`;
- `apps/live_frames/lib/live_frames/styling/token_bridge.ex`;
- root `mix.exs` and `.github/workflows/ci.yml`.

Relevant current design truths:

1. ordinary CSS is first-class;
2. Tailwind v4 is build-time compatibility authority where used, not a runtime requirement;
3. LiveFrames owns semantic component structure and presentation;
4. public theme customization is through generated `--lf-*` variables;
5. component-private composition variables such as `--lf-hero-*` are not public theme API;
6. generated `lf_theme.css` is a deterministic representation, not the semantic value authority;
7. TokenSet values and approved mappings are the authority chain;
8. consumer `class` is additive but can invalidate verified presentation;
9. source-system classes and source breakpoints are not native public API;
10. current CI already checks generated styling drift.

### 2.3 Phoenix / HEEx parsing

Phoenix LiveView's current HEEx implementation exposes public engines/formatting surfaces, while its structured `Phoenix.LiveView.TagEngine.Parser` is marked `@moduledoc false` and therefore must be treated as a **private compatibility dependency** if used.

The parser is nevertheless attractive for a tracer because it already returns structured tag nodes, attributes, expressions and source metadata, and Phoenix's own HTML formatter uses it internally.

Relevant upstream references:

- <https://github.com/phoenixframework/phoenix_live_view/blob/main/lib/phoenix_live_view/html_formatter.ex>
- <https://github.com/phoenixframework/phoenix_live_view/blob/main/lib/phoenix_live_view/tag_engine/parser.ex>
- <https://github.com/phoenixframework/phoenix_live_view/blob/main/lib/phoenix_live_view/tag_engine/tokenizer.ex>
- <https://github.com/phoenixframework/phoenix_live_view/blob/main/lib/phoenix_live_view/html_engine.ex>

A third-party Tree-sitter HEEx grammar exists, but adopting it as core authority would add an independent grammar/version surface and likely native parser integration. It remains a possible future adapter, not the preferred first implementation.

---

## 3. What `@shadcn/lint` gets right

LiveFrames should intentionally copy the **ideas**, not blindly copy the runtime architecture.

### 3.1 Agent-first diagnostics

The best upstream idea is that a diagnostic should answer more than "what failed?" It should tell an agent:

- which rule was violated;
- what value/class/property caused it;
- which component or source surface owns the decision;
- what approved alternative exists;
- where the relevant authority lives.

Bad diagnostic:

```text
arbitrary value not allowed
```

LiveFrames-quality diagnostic:

```text
LF-CSS-002 apps/live_frames/assets/css/components/cards/feature.css:41:19

`padding-inline: 17px` bypasses LiveFrames spacing authority.

Use an approved semantic `--lf-*` spacing token. If no existing token expresses
this semantic need, change TokenSet/mapping authority first; do not mint a local
literal in component CSS.

Authority:
  TokenSet → approved mapping → generated --lf-* theme variable
```

### 3.2 Component contracts

`@shadcn/lint` recognizes that callers may be permitted to control some aspects of a component while the component owns the rest.

LiveFrames needs the same concept, but its contract vocabulary must be LiveFrames-native rather than Tailwind-category-native.

Example conceptual policy:

```elixir
%LiveFrames.Lint.ComponentContract{
  id: "hero/v1",
  module: LiveFrames.Components.Sections.Hero,
  function: :hero,
  public_root_class: "lf-hero",
  consumer_class_policy: %{
    allow: [:placement],
    deny: [:component_color, :component_spacing, :typography, :shape]
  },
  public_tokens: :from_authority,
  private_token_prefixes: ["--lf-hero-"]
}
```

The exact struct/API is not authorized by this document; the semantic contract is.

### 3.3 Progressive adoption

Upstream recommends starting with warnings, baselining existing violations, and progressively promoting rules to errors.

LiveFrames should use the same principle **where legacy scope exists**, but the first lint tracer is new code and should not begin by normalizing known violations. The Hero tracer corpus should be clean by construction.

### 3.4 Explicit inability to read templates

The shadcn implementation warns when a Vue/Svelte template parser is unavailable rather than silently implying full template coverage.

LiveFrames must go further:

> **Unparsed, unsupported or ambiguous source is `indeterminate`, never `compliant`.**

### 3.5 Evals and red-team testing

The upstream eval suite tests coding-agent correction behavior and deliberately tests bypasses. LiveFrames should adopt the same pressure-testing mindset, with a LiveFrames-specific adversarial corpus.

Important upstream lesson: their own red-team notes show that plain CSS and newly minted theme tokens can escape a JSX-focused linter. That is direct evidence that LiveFrames cannot stop at HEEx/Tailwind class analysis.

---

## 4. What must *not* be copied unchanged

### 4.1 Do not make ESLint/Oxlint the LiveFrames authority

Reasons:

- HEEx is not currently supported by `@shadcn/lint`;
- LiveFrames is an Elixir/Phoenix library;
- the primary source surfaces are `.ex`, `.heex` and `.css`;
- Node.js would become a new foundational tooling dependency for consumers/contributors;
- ESLint's component identity/import model does not naturally represent Phoenix local function components, remote function components, slots and assigns;
- LiveFrames already has a Mix-centric validation workflow.

Optional JavaScript linting may continue to exist for JS hooks or preview assets, but it is not the canonical LiveFrames design-contract gate.

### 4.2 Do not turn LiveFrames into a Tailwind-only design system

This would contradict current LiveFrames authority.

LiveFrames deliberately uses semantic CSS and custom properties. Tailwind may appear in a host or build source path, but the linter must reason about the **design contract**, not only utility-class syntax.

### 4.3 Do not fork the whole shadcn linter as a permanent architecture

A fork appears attractive because its rule engine already exists, but it creates the wrong long-term ownership:

```text
LiveFrames semantics
→ translated into JS/ESLint concepts
→ HEEx shim/parser
→ shadcn rule assumptions
→ diagnostics
```

The desired path is:

```text
LiveFrames authority
→ native normalized lint facts
→ LiveFrames rules
→ diagnostics
```

A narrow reuse of MIT-licensed algorithms or grammar ideas is acceptable if attribution/licence requirements are preserved. Wholesale architectural coupling is not recommended.

### 4.4 Do not make generated CSS the source of truth

`lf_theme.css` is generated output. The linter should consume TokenSet/mapping authority through an authoritative registry/API, then optionally verify generated CSS parity as an evidence check.

Re-parsing generated CSS to rediscover the design system would reverse the existing authority direction.

---

## 5. Alternatives pressure-tested

| Option | HEEx fit | CSS/token fit | Phoenix component fit | Runtime/tooling cost | Drift risk | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| Install `@shadcn/lint` unchanged | Poor | Partial | Poor | Adds Node/ESLint | High false confidence | Reject as canonical gate |
| Fork shadcn/lint + add HEEx reader | Medium | Partial | Medium | Node/ESLint + custom parser | High semantic impedance | Reject as foundation |
| Convert HEEx to JSX-like surrogate then lint | Fragile | Partial | Poor | Translation layer | Very high | Reject |
| Tree-sitter HEEx + TypeScript rule engine | Good syntax potential | Partial | Medium | Native grammar + Node | Medium/high | Keep as future adapter option only |
| Native Elixir regex linter | Superficially easy | Fragile | Weak | Low | Very high | Reject |
| Native Elixir core + isolated HEEx parser adapter + conservative CSS scanner | Strong | Strong | Strong | Fits Mix | Controlled | **Adopt** |
| Native Elixir core + optional future JS interoperability | Strong | Strong | Strong | Incremental | Low | **Allowed later** |

### Decision

Build a **native Elixir lint core**. Parsing implementations remain adapters so LiveFrames can replace a Phoenix-private parser or CSS scanner without changing rule semantics.

---

## 6. Authority hierarchy: no second source of truth

The linter is an **enforcer**, not a legislature.

Authority must flow in this order:

```text
LiveFrames architecture / accepted component contract
                    │
                    ▼
             TokenSet authority
                    │
                    ▼
          approved token mapping
                    │
                    ├─────────────► generated --lf-* theme CSS
                    │
                    ▼
          lint contract registry
                    │
                    ▼
             rule evaluation
                    │
                    ▼
               diagnostics
```

The linter must not independently invent:

- design tokens;
- component variants;
- public styling knobs;
- breakpoint APIs;
- semantic component categories;
- component ownership decisions.

If a rule needs information that does not exist in authority, the correct result is one of:

1. the rule does not exist yet;
2. the lint result is `indeterminate`;
3. an explicit architecture decision adds the missing authority first.

Never solve missing authority by encoding an undocumented opinion inside a lint rule.

---

## 7. Proposed subsystem architecture

Recommended package location:

```text
apps/live_frames/lib/live_frames/lint/
├── engine.ex
├── run.ex
├── diagnostic.ex
├── finding.ex
├── source.ex
├── source_range.ex
├── policy.ex
├── rule.ex
├── rule_registry.ex
├── component_contract.ex
├── component_registry.ex
├── token_registry.ex
├── parser/
│   ├── heex.ex
│   ├── heex_phoenix_adapter.ex
│   ├── elixir_source.ex
│   └── css.ex
├── normalize/
│   ├── heex.ex
│   ├── css.ex
│   └── component.ex
├── rules/
│   ├── heex/
│   ├── css/
│   ├── token/
│   └── component/
└── report/
    ├── text.ex
    └── json.ex

apps/live_frames/lib/mix/tasks/
└── lf.lint.ex
```

Names are recommendations, not irreversible public API.

### 7.1 Core boundary

Rules must evaluate **normalized facts**, not parser-specific node structures.

Wrong:

```elixir
Rule.NoRestyle.check(%Phoenix.LiveView.TagEngine.Parser{...})
```

Correct direction:

```elixir
Rule.NoRestyle.check(%LiveFrames.Lint.Fact.ComponentCall{...}, context)
```

This keeps the rules independent of whichever HEEx parser is used.

### 7.2 Normalized facts

Initial fact types should be deliberately small:

```text
MarkupElement
ComponentCall
ClassValue
InlineStyle
CssSelector
CssDeclaration
CssCustomPropertyDefinition
CssCustomPropertyReference
TokenDefinition
TokenReference
SourceSystemClass
DynamicExpression
```

Every fact carries:

- source file;
- exact or best-known source range;
- parser confidence (`exact`, `conservative`, `unknown`);
- owning construct/component when known;
- raw spelling required for diagnostics;
- normalized semantic value where safe.

### 7.3 Diagnostic contract

A diagnostic should be a struct, not preformatted prose.

Conceptually:

```elixir
%Diagnostic{
  rule_id: "LF-COMP-001",
  severity: :error,
  state: :violation,
  file: "lib/acme_web/live/home_live.ex",
  range: %{line: 42, column: 7, end_line: 42, end_column: 28},
  subject: "Hero.hero",
  evidence: "bg-red-500",
  message_code: :component_owns_color,
  guidance: "Use the approved --lf-* theme surface instead.",
  authority_refs: ["docs/11#public-theme-surface", "hero/v1"],
  suggestions: ["theme override on an approved --lf-* variable"]
}
```

Rendering to terminal text and JSON occurs after evaluation.

### 7.4 Deterministic ordering

Diagnostics must sort deterministically by:

```text
file path bytes
→ start line
→ start column
→ rule id
→ message code
→ evidence bytes
```

Do not put wall-clock timestamps, random IDs or environment-specific absolute paths into the canonical JSON result.

---

## 8. HEEx parsing strategy

### 8.1 Required source coverage

The canonical gate must eventually cover both:

```text
*.heex
```

and embedded:

```elixir
~H"""
...
"""
```

Failing to cover `~H` would miss the current native Hero implementation itself.

### 8.2 First tracer parser recommendation

For the first tracer, use `Phoenix.LiveView.TagEngine.Parser` **only through**:

```text
LiveFrames.Lint.Parser.Heex
        ↓ behaviour
LiveFrames.Lint.Parser.HeexPhoenixAdapter
```

Why this is acceptable for the tracer:

- it parses the same HEEx grammar Phoenix itself is using;
- it returns tag names, attributes, expression values and metadata;
- Phoenix's own HTML formatter already depends on it internally;
- it avoids inventing a second HEEx grammar immediately.

Why it is dangerous if used carelessly:

- it is marked `@moduledoc false`;
- its node shapes are not a public compatibility promise;
- a LiveView upgrade may change it.

Therefore these guards are mandatory:

1. **One adapter module only.** No rule may pattern-match Phoenix parser tuples directly.
2. **Supported-version gate.** The adapter records the tested Phoenix LiveView version/range.
3. **Characterization corpus.** CI runs parser-shape tests against representative HEEx constructs.
4. **Unknown version never passes.** Unsupported parser version returns `{:error, :unsupported_heex_parser_version}`.
5. **Parser failure makes the lint run indeterminate.** It cannot downgrade to warning and continue as if the file passed.
6. **Upgrade gate.** Any Phoenix LiveView dependency update must run the HEEx parser compatibility suite before acceptance.

### 8.3 Extracting `~H` sigils

Use Elixir's parser to locate HEEx sigils in `.ex`/`.exs` files. The implementation should use `Code.string_to_quoted/2` or `Code.string_to_quoted_with_comments/2` with source metadata enabled (`columns: true`, `token_metadata: true`) and preserve enough literal metadata to map nested HEEx ranges back to the host file.

This extraction layer must be separately tested for:

- heredoc `~H"""..."""`;
- single-line sigils;
- indentation offsets;
- multiple `~H` sigils in one file;
- comments around sigils;
- modules with unrelated ordinary strings/sigils;
- syntax errors before/after the HEEx sigil;
- exact host-file line/column mapping.

Do not identify `~H` by regex alone.

### 8.4 Dynamic HEEx values

HEEx permits values such as:

```heex
class="lf-card"
class={["lf-card", @class]}
class={@class}
class={if(@active, do: "lf-card--active")}
class={"lf-card--#{@variant}"}
```

The linter must distinguish:

- **statically proven values**;
- **partially proven values**;
- **unanalyzable values**.

It must not claim that a dynamic expression is safe merely because no forbidden literal was visible.

---

## 9. CSS analysis strategy

### 9.1 Why CSS is mandatory

A LiveFrames linter that checks only HEEx would reproduce a known weakness of JSX-oriented design-system linting: styling policy can move into CSS and escape the rule.

LiveFrames owns component CSS directly, so CSS must be a first-class lint surface.

### 9.2 Do not build a full CSS standards engine in LF-LINT-000

The first tracer needs a **conservative source scanner**, not a browser CSS implementation.

It needs to recognize reliably:

- comments and strings;
- balanced `{}` blocks;
- selectors;
- declarations;
- custom-property definitions;
- `var(--...)` references;
- raw color literals;
- numeric dimensions relevant to governed properties;
- at-rule nesting (`@layer`, `@media`, etc.) without losing inner declarations.

If the scanner encounters valid syntax it cannot classify safely, return an `indeterminate` fact for the affected region instead of skipping it.

### 9.3 CSS authority categories

Not every literal is forbidden.

The current Hero already contains justified component-private composition literals, for example gradient stops and image focal percentages. A naïve "no numbers" rule would be wrong.

Therefore rules must distinguish:

```text
semantic theme value
component-private composition value
structural CSS value
unapproved design value
```

Examples:

- `display: flex` → structural; allowed;
- `position: absolute` → structural; allowed;
- `background-color: var(--lf-color-background-ultra-dark)` → semantic token; allowed;
- `padding-inline: 17px` → likely governed design value; violation unless component authority explicitly permits a private literal;
- `object-position: 70% 50%` → component-private composition; permitted when declared by component authority;
- gradient stops inside private Hero overlay variables → component-private composition; permitted by Hero contract;
- `#ff0033` for a component background → raw design color; violation.

This is why the linter must enforce **contracts**, not generic style opinions.

---

## 10. Token registry: consume authority, do not rediscover it

Create a read-only lint-facing registry from existing TokenSet + mapping authority.

Recommended responsibility:

```text
LiveFrames.Lint.TokenRegistry
```

It should expose facts such as:

```text
public CSS variable name
semantic TokenSet path
resolution status
resolved category/type
mapping version
public/private status
allowed component scope where applicable
```

Where possible, reuse the validation already present in `LiveFrames.Styling.TokenBridge` rather than duplicating mapping validation.

The linter must **not** decide a token is valid merely because a CSS custom property beginning `--lf-` exists in source.

This specifically closes the "mint a new token and become on-system" loophole.

A new token becomes authoritative only through the approved TokenSet/mapping workflow.

---

## 11. Component contract registry

### 11.1 Purpose

The linter needs to know what a component owns and what consumers may change.

This must be explicit and versionable.

### 11.2 Minimum Hero tracer contract

For Hero v1, the lint contract should derive from existing accepted authority and encode at least:

```text
component identity:
  LiveFrames.Components.Sections.Hero.hero/1

semantic root:
  .lf-hero

required internal namespace:
  .lf-hero*

consumer `class`:
  additive API exists
  does not transfer ownership of component presentation

public theme surface:
  approved --lf-* values generated from TokenSet/mapping authority

private composition surface:
  --lf-hero-* is package-private

source-system names:
  forbidden from native public API / semantic classes

responsive behavior:
  component-owned; no public source breakpoint attrs
```

### 11.3 Contract location

Do not hide contracts solely in lint configuration.

Preferred end state:

```text
accepted component contract
        │
        ├── docs
        ├── runtime/component tests
        ├── lint contract projection
        └── Storybook metadata where useful
```

The exact canonical serialization can be decided after the tracer. The key requirement is that lint policy must be **derived from or checked against** accepted component authority.

---

## 12. Initial rule catalogue

The first general rule vocabulary should be intentionally small.

### `LF-HEEX-001 no-inline-style`

Flags component/markup inline styling where LiveFrames CSS ownership requires stylesheet/token authority.

Must understand:

```heex
style="..."
style={...}
```

Dynamic style expressions that cannot be proven empty/safe are `indeterminate` or violations according to the component contract.

### `LF-HEEX-002 require-analyzable-class`

Flags class expressions on governed components that cannot be statically verified.

Example:

```heex
<Hero.hero class={dynamic_classes(@state)} />
```

Default for a governed LiveFrames component: fail closed unless an approved analyzable helper contract exists.

### `LF-HEEX-003 no-source-class-leakage`

Rejects classes/identifiers known to originate from Bricks, ACSS or other source systems in native component/public consumer contracts.

The source vocabulary must come from explicit source adapters/known namespaces, not a hard-coded folklore list in the rule.

### `LF-CSS-001 no-raw-design-color`

Rejects unapproved literal design colors in governed component presentation.

Must cover at minimum:

```text
hex
rgb()/rgba()
hsl()/hsla()
oklch()/lab()/lch() where encountered
named palette colours where policy classifies them as design values
```

Private composition gradients require explicit component-contract treatment; do not blindly ban all color literals before the Hero tracer accounts for current accepted overlay authority.

### `LF-CSS-002 no-ungoverned-design-value`

Rejects design values for governed properties that bypass TokenSet/public/private component authority.

This is the LiveFrames evolution of shadcn's `no-arbitrary-values`, but it applies to ordinary CSS too.

### `LF-TOKEN-001 known-public-token`

Every public `--lf-*` reference must resolve through the authoritative registry.

Typo example:

```css
color: var(--lf-color-headng-on-dark);
```

must be an error with nearest approved token suggestions where deterministic.

### `LF-TOKEN-002 private-token-boundary`

Prevents private component variables such as `--lf-hero-*` from being used or overridden outside approved owner scope.

### `LF-TOKEN-003 no-unapproved-token-definition`

Prevents a contributor from making an arbitrary value appear legitimate by defining a new `--lf-*` variable outside the approved TokenSet/mapping workflow.

### `LF-COMP-001 component-restyle-contract`

Checks consumer-supplied classes/styles against a LiveFrames component's ownership contract.

For Hero, classes that alter verified background, internal spacing, typography, shape or private variables should not silently pass merely because `class` is syntactically allowed.

### `LF-COMP-002 semantic-class-namespace`

Enforces the component's approved semantic class namespace and prevents source-export class leakage.

### `LF-COMP-003 unknown-semantic-class`

Flags misspelled or undeclared `.lf-*` semantic classes where a known registry exists.

---

## 13. Rules that should **not** exist initially

Avoid speculative rules such as:

- universal spacing preferences;
- generic HTML style opinions unrelated to LiveFrames authority;
- arbitrary accessibility heuristics already covered better by semantic tests/browser tooling;
- every Tailwind "best practice";
- source-specific rules that accidentally make Bricks/ACSS a native dependency;
- rules that infer design intent from visual similarity;
- automatic token creation;
- automatic component API expansion.

The linter should be narrow and authoritative before it becomes broad.

---

## 14. Lint run lifecycle

A lint run is a domain concept with an explicit lifecycle.

### States

```text
created
  ↓
discovering
  ↓
parsing
  ↓
normalizing
  ↓
evaluating
  ↓
reporting
  ├── compliant      (terminal)
  ├── violations     (terminal)
  └── indeterminate  (terminal)
```

### Transition guards

| Transition | Guard |
| --- | --- |
| `created → discovering` | configuration loads and validates |
| `discovering → parsing` | source set is deterministic and non-ambiguous |
| `parsing → normalizing` | every required source either parsed or produced an explicit parse failure |
| `normalizing → evaluating` | facts satisfy internal schemas and authority registries loaded successfully |
| `evaluating → reporting` | every enabled rule returned a result for its applicable facts |
| `reporting → compliant` | zero error violations and zero indeterminate conditions |
| `reporting → violations` | at least one policy violation; no higher-priority infrastructure indeterminacy hides coverage |
| `reporting → indeterminate` | parser/config/authority/internal failure prevents proof of complete evaluation |

### Side effects

The linter may:

- write terminal diagnostics;
- write deterministic JSON evidence when requested;
- return an exit code.

It must not:

- rewrite source by default;
- mint tokens;
- modify component contracts;
- edit generated CSS;
- execute imported/source-system code;
- mutate repository state.

### Terminal state priority

`indeterminate` has higher safety priority than `compliant`.

If a run has both ordinary violations and an unreadable governed file, machine output may include both classes of finding, but the overall proof state remains `indeterminate` because coverage was incomplete.

---

## 15. Rule lifecycle

Rules also have a lifecycle.

```text
draft
  ↓
shadow
  ↓
enforced
  ├── amended → shadow/enforced after evidence
  └── retired  (terminal)
```

### `draft`

Implementation/tests may exist, but the rule is not part of normal lint results.

### `shadow`

Rule runs in CI and produces evidence but does not fail ordinary PRs. It must have a measured false-positive/false-negative review before promotion.

### `enforced`

Violation fails the lint gate.

### Promotion guard

A rule may become `enforced` only when:

1. its scope is tied to documented authority;
2. positive and negative fixtures exist;
3. bypass/red-team fixtures exist;
4. diagnostics are deterministic;
5. no known accepted current source is falsely rejected;
6. no known covered violation silently passes;
7. indeterminate cases fail closed.

---

## 16. Exception/suppression lifecycle

Do **not** copy casual `eslint-disable` culture into LiveFrames.

For LF-LINT-000, support **no suppressions**.

If exceptions are later proven necessary, model them explicitly:

```text
proposed
  ↓
approved
  ├── expired  (terminal)
  └── revoked  (terminal)
```

An approved exception must carry:

- stable exception ID;
- rule ID;
- precise target/scope;
- reason;
- authority reference;
- approval provenance;
- optional expiry/removal condition.

An exception must not silently broaden to new files/components.

Prefer changing the component/design contract when an exception represents a legitimate reusable capability.

---

## 17. Result semantics and exit codes

Recommended command behavior:

```text
exit 0 = complete evaluation, no enforced violations
exit 1 = complete evaluation, one or more enforced policy violations
exit 2 = indeterminate: configuration/parser/authority/internal failure
```

Warnings never convert an incomplete evaluation to success.

Human output should end with an explicit proof summary:

```text
LiveFrames lint: COMPLIANT
Files evaluated: 18
Rules enforced: 7
Indeterminate regions: 0
Violations: 0
```

or:

```text
LiveFrames lint: INDETERMINATE
Reason: unsupported Phoenix LiveView HEEx parser version 1.2.15
No compliance claim has been made.
```

---

## 18. Machine-readable report

`mix lf.lint --format json` should produce a deterministic schema.

Illustrative shape:

```json
{
  "schema_version": "1.0.0",
  "status": "violations",
  "policy_version": "0.1.0",
  "parser_compatibility": {
    "phoenix_live_view": "1.2.11",
    "heex_adapter": "phoenix_tag_engine_v1"
  },
  "files_evaluated": 12,
  "indeterminate_regions": 0,
  "diagnostics": [
    {
      "rule_id": "LF-COMP-001",
      "severity": "error",
      "file": "lib/acme_web/live/home_live.ex",
      "line": 42,
      "column": 7,
      "subject": "LiveFrames.Components.Sections.Hero.hero/1",
      "message_code": "component_owns_color",
      "evidence": "bg-red-500"
    }
  ]
}
```

Do not include timestamps or random run IDs in the canonical deterministic payload. CI systems may wrap this report with external run metadata.

---

## 19. Security/trust model

The linter processes repository source as **data**.

It must not:

- `Code.eval_string/3` dynamic class expressions;
- compile arbitrary imported project modules merely to discover styling;
- execute source-system JavaScript/PHP/CSS imports;
- invoke shell commands derived from source strings;
- create atoms from untrusted source values without bounded/static conversion;
- follow arbitrary filesystem paths emitted by source data;
- load remote stylesheets;
- resolve network URLs.

Static analysis is preferred even when evaluation would be easier.

This aligns with the repository's existing `AGENTS.md` trust boundary.

---

## 20. Performance requirements

This is build-time tooling, not request-path code, so sub-millisecond runtime is not required. Determinism and correctness matter more than micro-optimisation.

Still, the architecture should avoid obvious quadratic work.

Target after generalisation:

```text
single repository lint on ordinary developer machine: comfortably < 5 seconds
incremental/focused lint of changed component files: < 1 second where practical
```

These are engineering targets, not acceptance guarantees for LF-LINT-000.

Rules should share parsed/normalized facts rather than reparsing each file independently.

---

## 21. LF-LINT-000 — mandatory tracer

Do not begin by implementing the entire rule catalogue.

### Goal

Prove that LiveFrames can reliably detect design-contract violations across the accepted native Hero surface using a native Mix command.

### Scope

Only:

```text
Hero component HEEx
Hero component CSS
Hero token/public-private boundary
one or more consumer Hero-use fixtures
```

### Required first-tracer rules

Implement the smallest rules that prove all architectural layers:

1. `LF-HEEX-002 require-analyzable-class` for governed Hero usage;
2. `LF-COMP-001 component-restyle-contract` for Hero consumer class misuse;
3. `LF-TOKEN-001 known-public-token`;
4. `LF-TOKEN-002 private-token-boundary`;
5. one CSS governed-value rule (`LF-CSS-001` or tightly scoped `LF-CSS-002`).

Do not implement every future rule merely because the architecture lists it.

### Required fixtures

Positive fixtures:

```text
clean native Hero source
clean consumer call with no class override
clean consumer placement-only class if contract explicitly allows it
valid public --lf-* token reference
valid private Hero token inside Hero owner CSS
accepted Hero private gradient/focal composition literals
```

Negative fixtures:

```text
consumer raw Tailwind color on Hero
consumer arbitrary padding on Hero
consumer override/use of --lf-hero-* outside Hero owner CSS
unknown --lf-* token typo
new --lf-* token minted outside approved mapping
source-system class in native Hero markup
raw design color inserted into governed Hero declaration
```

Indeterminate fixtures:

```text
class={unknown_function(@x)}
malformed HEEx
supported syntax with deliberately unsupported analyzer shape
unsupported Phoenix parser version simulation
CSS region scanner cannot classify safely
```

Every indeterminate fixture must prove the run does **not** report compliant.

---

## 22. LF-LINT-000 implementation sequence

### Step 1 — freeze the baseline

Before code changes:

```sh
git status --short --branch
git rev-parse HEAD
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix assets.build
mix test
mix deps.unlock --check-unused
git diff --check
```

Record skipped gates and reasons.

### Step 2 — add pure domain structs and state model

Implement/test:

```text
Run
Diagnostic
SourceRange
Fact types
Rule behaviour
Run status reduction
```

No parser yet.

Acceptance: deterministic ordering and `compliant / violations / indeterminate` semantics are fully tested.

### Step 3 — HEEx parser adapter characterization

Create adapter tests against the exact currently locked/selected Phoenix LiveView version.

Test all HEEx forms used by Hero plus the dynamic-class corpus.

Do not add lint rules until source ranges and attribute extraction are proven.

### Step 4 — `~H` source extraction

Implement host Elixir AST extraction with metadata and map HEEx ranges back to `.ex` source coordinates.

Acceptance: diagnostics for Hero's current `~H` template point to exact expected host-file lines/columns.

### Step 5 — TokenRegistry projection

Expose approved public token names from existing authority.

Acceptance: registry output is deterministic and cannot be expanded merely by writing a new CSS custom property.

### Step 6 — Hero component contract

Encode/projection-test only already accepted Hero authority.

No new Hero API or styling decision is allowed in this step.

### Step 7 — CSS conservative scanner

Implement enough CSS scanning for Hero owner CSS and the required negative fixtures.

Acceptance includes multiline gradients, nested `@layer`, nested `@media`, comments, strings and custom-property references.

### Step 8 — first rules

Implement the five tracer rules only after parsers/facts are stable.

### Step 9 — `mix lf.lint`

Add CLI with:

```text
human output default
--format json
--path <path> optional focused scope
--rule <id> optional development filter
```

Do not add `--fix` in LF-LINT-000.

### Step 10 — shadow CI

Run lint in CI without merge blocking for a short characterization period **only if** the rule implementation is not yet proven clean.

For a brand-new clean tracer with fully deterministic fixtures, direct enforcement on the tracer scope is acceptable after review.

### Step 11 — exact evidence review

Before promotion:

- inspect exact diff;
- run full current CI gates;
- run all lint fixtures;
- prove parser compatibility;
- prove no false compliant result under indeterminate fixtures;
- review machine JSON determinism;
- verify no new Node/runtime dependency;
- verify no catalogue/generator/ejection scope creep.

---

## 23. CI integration

Current LiveFrames CI already runs formatting, compile, asset build, generated-style drift, tests, unused-dependency check and whitespace check.

After LF-LINT-000 is accepted, insert:

```yaml
- name: Lint LiveFrames design contracts
  run: mix lf.lint
```

Recommended order:

```text
checkout
setup Elixir
mix deps.get
format
compile
lf.lint
assets.build
artifact drift
tests
unused deps
whitespace
```

Why before asset build: lint should evaluate source authority, not depend on regenerated output to hide source violations.

Why keep the existing drift gate: linting and deterministic artifact parity prove different things.

---

## 24. Agent workflow integration

After enforcement, `AGENTS.md` should require:

```sh
mix lf.lint
```

and include one concise rule:

> A lint `indeterminate` result is a failed verification, not a pass. Do not bypass or suppress a LiveFrames design-contract diagnostic; change the code or the accepted authority through the appropriate architecture process.

Diagnostics should be sufficient for a smaller coding agent to self-correct without receiving the entire design-system documentation in prompt context.

---

## 25. Red-team corpus

The linter is not ready because happy-path tests pass. It is ready when common bypasses fail safely.

At minimum test these attacks:

| Bypass attempt | Required result |
| --- | --- |
| raw hex directly in component CSS | caught |
| raw colour hidden in CSS custom property | caught or explicit allowed-private authority |
| mint new `--lf-*` token in local CSS | caught |
| misspell existing `--lf-*` token | caught, suggestion if deterministic |
| use `--lf-hero-*` from consumer CSS | caught |
| dynamic class helper on Hero | indeterminate/violation, never clean |
| interpolate class suffix | indeterminate unless enumerably proven |
| source-system class renamed slightly | caught only if rule has explicit provenance evidence; otherwise do not claim coverage |
| inline style on governed component | caught |
| move violation from HEEx into CSS class | CSS layer catches it |
| hide CSS declaration in nested `@media` | caught |
| hide declaration in `@layer` | caught |
| comment/string containing fake declaration | ignored correctly |
| malformed CSS around valid forbidden declaration | indeterminate, never clean |
| malformed HEEx | indeterminate, never clean |
| parser version outside tested range | indeterminate/fatal |
| rule throws unexpectedly | indeterminate/fatal |
| duplicate/conflicting component contracts | configuration failure |
| duplicate rule IDs | configuration failure |

Add a regression fixture for every real bypass found after release.

---

## 26. False-positive pressure tests

The linter must not reject accepted LiveFrames design merely because a generic rule dislikes it.

Required Hero examples include:

- internal `margin-top: 400px` if it remains accepted component-private implementation;
- internal `object-position: 70% 50%` if it remains accepted responsive composition;
- accepted private overlay gradients containing literal colour/alpha stops;
- structural `display`, `position`, `inset`, `z-index`, flex and width declarations;
- consumer `id` and approved global attributes;
- `class` being present as an additive API field while still policing forbidden restyling at consumer call sites.

If a rule cannot distinguish accepted private composition from an ungoverned value, the rule is not ready for enforcement.

---

## 27. Testing pyramid

### Unit tests

Test pure:

```text
fact normalization
policy matching
diagnostic rendering
status reduction
deterministic sorting
token lookup
component-contract lookup
CSS value classification
```

### Parser characterization tests

Treat the Phoenix-private parser adapter as compatibility code. Snapshot or exact-assert the normalized facts, **not** raw Phoenix tuple shapes where possible.

### Golden diagnostics

Use small fixtures where expected diagnostics are exact, including line/column and guidance code.

### Integration tests

Invoke the Mix task against fixture directories and assert exit code + output status.

### Repository self-lint

Once stable, the current LiveFrames source itself becomes a corpus.

### Upgrade tests

Dependency-upgrade PRs must run parser compatibility and full self-lint.

---

## 28. Dependency policy

LF-LINT-000 should prefer **zero new runtime dependencies**.

A development/build-time dependency may be proposed only if it materially improves correctness and passes these questions:

1. Does it parse a language more faithfully than our bounded adapter?
2. Is its compatibility surface clearer than Phoenix's current parser?
3. Does it add native binaries/NIFs or platform friction?
4. Does it need Node.js?
5. Does it become a consumer runtime dependency?
6. Can we isolate it behind the existing parser behaviour?
7. What happens when it is missing or version-mismatched?

No dependency should be added merely because it makes the first implementation shorter.

---

## 29. Upstream reuse and licence handling

`@shadcn/lint` is MIT licensed at the inspected baseline. Its concepts can be adopted freely; copied or substantially derived source code must retain the applicable MIT copyright/licence notice.

Preferred approach:

- independently implement LiveFrames domain structures;
- credit `@shadcn/lint` as design inspiration in this architecture document;
- copy code only when there is concrete value;
- if source is copied/ported, retain required licence attribution in the relevant file or third-party notices.

Do not claim upstream eval results prove LiveFrames lint efficacy. They justify the **hypothesis** that agent-facing diagnostics help; LiveFrames must run its own evals.

---

## 30. LiveFrames-specific agent evals

After the tracer is technically correct, create a small eval harness modelled on the useful upstream methodology.

### Test classes

1. **Temptation:** ask an agent to make Hero "more exciting" with off-system colour/spacing.
2. **Neutral assembly:** ask an agent to use Hero without styling instructions.
3. **Consumer override:** ask for brand theming and see whether the agent uses public tokens vs private CSS overrides.
4. **Dynamic shortcut:** prompt an agent to generate class names from runtime state.
5. **CSS escape:** prompt it to move rejected classes into a new stylesheet.
6. **Token minting:** prompt it to create a new `--lf-*` variable locally.

### Compare

```text
A: instructions only
B: instructions + exact lint diagnostics
```

Measure:

- violations before;
- violations after;
- rounds to convergence;
- workaround/suppression attempts;
- whether intended appearance/behavior remains;
- whether the fix lands in the correct authority layer.

Do not make model-cost numbers a permanent architectural assumption; record dated evidence.

---

## 31. Public package question

Do not expose `LiveFrames.Lint` as a stable public consumer API in LF-LINT-000.

First prove it inside the repository.

Later decisions can separate:

```text
A. maintainers-only self-lint
B. consumer lint for applications using LiveFrames
C. reusable Phoenix design-contract lint framework
```

Those are different products and should not be conflated.

The immediate need is **A**, with enough architecture not to block **B** later.

---

## 32. How consumer lint can work later

If consumer lint becomes authorized, a host Phoenix project could add LiveFrames as normal and run:

```sh
mix lf.lint
```

or a dedicated package/tool task if packaging boundaries later require it.

The linter would discover calls such as:

```heex
<LiveFrames.Components.Sections.Hero.hero ... />
```

or imported/local aliases and evaluate caller-owned overrides against the packaged component-contract manifest.

At that point, a **versioned contract manifest** shipped under `priv/` may be appropriate so consumer lint does not introspect implementation modules dynamically.

Do not build that manifest until self-lint proves the contract model.

---

## 33. Rejected shortcut: lint only generated output

It may be tempting to compile/render everything and lint resulting HTML/CSS.

That is insufficient because:

- component identity can be lost;
- ownership boundaries can be lost;
- dynamic code may render only one state;
- source locations become poor;
- a private-token violation can be flattened into valid CSS;
- agent diagnostics need to point to the source decision, not only browser output.

Rendered/browser checks remain complementary evidence, not a replacement for source-contract lint.

---

## 34. Rejected shortcut: let tests cover it

Tests are necessary but poorly suited to enforcing open-ended negative style policy across every new component/caller.

A test proves examples. A linter applies reusable law over a source surface.

The desired stack is:

```text
component contract tests
+ lint policy
+ generated artifact drift
+ browser/visual verification
```

Each has a separate job.

---

## 35. Rejected shortcut: inspect only Tailwind classes

LiveFrames' current Hero proves why this fails: much of the component's presentation is semantic CSS using variables.

A Tailwind-only linter would miss:

```css
background: #f00;
padding: 17px;
--lf-made-up-token: 17px;
```

and could falsely report a clean component.

Tailwind syntax support is useful, but secondary.

---

## 36. Definition of done for LF-LINT-000

LF-LINT-000 is complete only when all of the following are true:

- [ ] native Elixir lint core exists;
- [ ] `mix lf.lint` exists;
- [ ] `.heex` and current Hero `~H` parsing path is proven;
- [ ] Phoenix-private parser usage is isolated behind one adapter;
- [ ] unsupported parser versions fail closed;
- [ ] normalized facts do not expose Phoenix parser tuples to rules;
- [ ] TokenRegistry derives from existing authority rather than generated CSS discovery;
- [ ] Hero component contract contains no new design decision;
- [ ] CSS scanner handles current Hero nesting/multiline constructs;
- [ ] required positive fixtures pass;
- [ ] required negative fixtures fail;
- [ ] required indeterminate fixtures never return compliant;
- [ ] deterministic diagnostic ordering is tested;
- [ ] JSON output is deterministic;
- [ ] exit-code semantics are tested;
- [ ] no suppression mechanism exists in the tracer;
- [ ] no Node/ESLint foundational dependency is added;
- [ ] no catalogue/generator/ejection work is introduced;
- [ ] current repository gates all pass;
- [ ] exact final diff is reviewed before merge;
- [ ] exact PR head CI is green before any merge recommendation.

---

## 37. STOP conditions

Stop implementation and return to architecture if any of the following occurs:

1. HEEx parsing requires evaluating application code.
2. The chosen parser cannot provide reliable source mapping for current Hero syntax.
3. A parser failure can be mistaken for a clean result.
4. A rule requires inventing a new design-system decision not present in authority.
5. Token validity can only be determined by treating generated CSS as canonical.
6. Correct Hero CSS would require broad ad-hoc lint exemptions.
7. The linter requires Node.js as a core LiveFrames dependency merely to function.
8. A new dependency introduces unbounded native/NIF/platform complexity without an approved architecture amendment.
9. The tracer expands into catalogue, generator, ejection or a second component without authorization.
10. CI or existing repository gates fail.

---

## 38. Recommended implementation slices after LF-LINT-000

Only authorize these sequentially after the tracer passes.

### LF-LINT-001 — Parser and fact-model hardening

- broaden HEEx fixture corpus;
- prove source ranges across files/sigils;
- stabilize fact schemas;
- add dependency-upgrade compatibility gate.

### LF-LINT-002 — Token/CSS governance

- generalize CSS rules beyond Hero;
- public/private token scope;
- unapproved token definition detection;
- raw design values with component-private allowances.

### LF-LINT-003 — Component contract generalization

- versioned component-contract registry;
- multiple native components;
- contract conflict detection;
- stable owner-scope rules.

### LF-LINT-004 — Consumer-call linting

- imported/aliased Phoenix component resolution;
- caller class/style policy;
- consumer-facing diagnostics.

### LF-LINT-005 — Agent eval + governance hardening

- temptation/neutral/red-team agent corpus;
- measured correction performance;
- rule promotion policy;
- exception lifecycle if genuinely required.

Do not pre-authorize LF-LINT-004/005 implementation by merging this document.

---

## 39. Suggested first coding-agent prompt

Use this only after LF-LINT-000 is explicitly authorized:

```text
Implement LF-LINT-000 from docs/23_LIVEFRAMES_DESIGN_CONTRACT_LINTER_ARCHITECTURE.md.

Hard boundaries:
- Work only on LF-LINT-000.
- Do not begin later LF-LINT slices.
- Do not add catalogue, generator/ejection, new native components, or new Hero API.
- Do not add Node/ESLint as a foundational lint dependency.
- Do not execute source/imported code to analyze it.
- Treat Phoenix.LiveView.TagEngine.Parser as private compatibility code and isolate it behind the approved adapter boundary.
- An unsupported/unreadable source is indeterminate, never compliant.
- Derive token validity from existing TokenSet/mapping authority, not from arbitrary CSS definitions.
- Use tests first for run-state semantics, parser characterization and every required positive/negative/indeterminate fixture.

Before editing:
1. read AGENTS.md completely;
2. inspect exact branch/worktree/HEAD;
3. run the applicable baseline gates;
4. read docs/11, docs/16, docs/19, docs/20, docs/21, docs/22 and this doc;
5. inspect Hero, Hero CSS, TokenBridge and current CI.

Implementation order:
1. pure lint domain/state structs;
2. HEEx adapter characterization;
3. ~H extraction/source mapping;
4. TokenRegistry projection;
5. Hero lint contract;
6. CSS conservative scanner;
7. tracer rules;
8. mix lf.lint;
9. integration/evidence tests;
10. CI integration only after local proof.

Do not claim completion until the exact final diff, all applicable repository gates, lint red-team fixtures and exact PR-head CI have been independently verified.
```

---

## 40. Decision summary

### Adopt from shadcn/lint

- executable design-system rules;
- component styling contracts;
- agent-oriented remediation messages;
- deterministic suggestions from existing design authority;
- progressive rule adoption;
- adversarial/eval methodology;
- explicit acknowledgement of parser/coverage limits.

### Do not adopt as LiveFrames foundation

- JSX-first AST assumptions;
- ESLint/Oxlint as canonical engine;
- Node.js as required LiveFrames lint runtime;
- Tailwind utility classes as the sole design-system truth;
- generated theme declarations as sufficient proof of token legitimacy;
- silent success when a template cannot be parsed.

### Build for LiveFrames

```text
Native Elixir design-contract lint core
+ parser adapter boundary
+ HEEx normalized facts
+ CSS normalized facts
+ TokenSet/mapping-backed registry
+ component contract registry
+ fail-closed run state
+ deterministic human/JSON diagnostics
+ Mix task
+ CI gate
+ adversarial corpus
```

The governing principle is:

> **LiveFrames authority first. Parsed evidence second. Lint rule third. Compliance claim last.**

The linter does not decide what the design system should be. It proves whether source code conforms to the design system LiveFrames has already authorized.

---

## Appendix A — shadcn/lint → LiveFrames concept map

| `@shadcn/lint` concept | LiveFrames equivalent | Change required |
| --- | --- | --- |
| JSX/Vue/Svelte reader | HEEx parser adapter | New native adapter |
| ESTree expressions | normalized HEEx facts | Do not leak parser AST into rules |
| Tailwind theme discovery | TokenSet + approved token mapping | Use existing authority |
| `no-restyle` | `LF-COMP-001` | Phoenix component ownership semantics |
| `no-raw-colors` | `LF-CSS-001` | Also inspect ordinary component CSS |
| `no-arbitrary-values` | `LF-CSS-002` | Generalize to governed CSS values |
| `no-inline-styles` | `LF-HEEX-001` | HEEx syntax/expressions |
| `require-static-classes` | `LF-HEEX-002` | Fail closed on dynamic governed classes |
| `no-unknown-classes` | `LF-COMP-003` | LiveFrames semantic classes; Tailwind optional |
| theme token suggestion | authoritative TokenRegistry suggestions | Never suggest minted tokens |
| component contract regex | versioned component contract | Prefer stable component identity over loose regex |
| ESLint warning/error | shadow/enforced lifecycle | LiveFrames governance |
| parser unavailable warning | run `indeterminate` | Stronger fail-closed semantics |
| agent eval suite | LiveFrames temptation/neutral/red-team eval | Project-specific evidence |

---

## Appendix B — example diagnostic catalogue

### Component restyle violation

```text
LF-COMP-001  error
lib/acme_web/live/home_live.ex:52:9

`bg-red-500` cannot be applied to LiveFrames Hero.
Hero owns its background presentation.

For theme customization, override an approved public `--lf-*` token in consumer CSS.
Do not override package-private `--lf-hero-*` variables.

Authority: Hero v1 component contract; docs/11 §§7-9.
```

### Unknown token

```text
LF-TOKEN-001  error
assets/css/app.css:81:10

Unknown LiveFrames public token `--lf-color-headng-on-dark`.

Did you mean:
  --lf-color-heading-on-dark

Only variables projected from approved TokenSet/mapping authority are valid public LiveFrames tokens.
```

### Dynamic class indeterminate

```text
LF-HEEX-002  indeterminate
lib/acme_web/live/home_live.ex:60:7

The `class` value for LiveFrames Hero cannot be statically verified:
  classes_for(@hero)

No compliance claim can be made for this component call.
Use a static/analyzable class list or an approved contract-aware helper.
```

### Private token boundary

```text
LF-TOKEN-002  error
assets/css/app.css:102:3

`--lf-hero-overlay-gradient-desktop` is a Hero-private composition variable.
Consumers must use the public `--lf-*` theme surface instead.
```

---

## Appendix C — source links

### shadcn/lint

- Repository: <https://github.com/shadcn-ui/lint>
- README: <https://github.com/shadcn-ui/lint/blob/main/README.md>
- Rules: <https://github.com/shadcn-ui/lint/blob/main/docs/rules.md>
- Design-system contracts: <https://github.com/shadcn-ui/lint/blob/main/docs/design-systems.md>
- Adoption: <https://github.com/shadcn-ui/lint/blob/main/docs/adoption.md>
- Evals/red-team: <https://github.com/shadcn-ui/lint/blob/main/docs/evals.md>
- Template reader contract: <https://github.com/shadcn-ui/lint/blob/main/packages/lint/src/sites/readers/types.ts>
- Reader dispatch: <https://github.com/shadcn-ui/lint/blob/main/packages/lint/src/sites/readers/index.ts>
- Licence: <https://github.com/shadcn-ui/lint/blob/main/LICENSE>

### Phoenix LiveView / Elixir

- HEEx formatter: <https://github.com/phoenixframework/phoenix_live_view/blob/main/lib/phoenix_live_view/html_formatter.ex>
- TagEngine parser: <https://github.com/phoenixframework/phoenix_live_view/blob/main/lib/phoenix_live_view/tag_engine/parser.ex>
- HEEx tokenizer: <https://github.com/phoenixframework/phoenix_live_view/blob/main/lib/phoenix_live_view/tag_engine/tokenizer.ex>
- HEEx engine: <https://github.com/phoenixframework/phoenix_live_view/blob/main/lib/phoenix_live_view/html_engine.ex>
- Elixir `Code` parser metadata: <https://hexdocs.pm/elixir/Code.html>

### LiveFrames

- Repository: <https://github.com/JCSchoeman96/LiveFrames>
- CSS/Tailwind strategy: <https://github.com/JCSchoeman96/LiveFrames/blob/main/docs/11_CSS_AND_TAILWIND_STRATEGY.md>
- Package/consumer model: <https://github.com/JCSchoeman96/LiveFrames/blob/main/docs/16_PACKAGE_AND_GENERATOR_MODEL.md>
- Phase 6 authority: <https://github.com/JCSchoeman96/LiveFrames/blob/main/docs/19_PHASE_6_NATIVE_COMPONENTIZATION.md>
- Styling bridge: <https://github.com/JCSchoeman96/LiveFrames/blob/main/docs/20_P6_4A_NATIVE_STYLING_BRIDGE_ARCHITECTURE.md>
- Hero browser verification: <https://github.com/JCSchoeman96/LiveFrames/blob/main/docs/21_P6_4B2_NATIVE_HERO_BROWSER_VERIFICATION.md>
- Hero Storybook verification: <https://github.com/JCSchoeman96/LiveFrames/blob/main/docs/22_P6_6_NATIVE_HERO_STORYBOOK_VERIFICATION.md>
- Hero implementation: <https://github.com/JCSchoeman96/LiveFrames/blob/main/apps/live_frames/lib/live_frames/components/sections/hero.ex>
- Hero CSS: <https://github.com/JCSchoeman96/LiveFrames/blob/main/apps/live_frames/assets/css/components/sections/hero.css>
- Token bridge: <https://github.com/JCSchoeman96/LiveFrames/blob/main/apps/live_frames/lib/live_frames/styling/token_bridge.ex>
- CI: <https://github.com/JCSchoeman96/LiveFrames/blob/main/.github/workflows/ci.yml>
