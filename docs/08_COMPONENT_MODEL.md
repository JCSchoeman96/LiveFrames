# Component model

This document defines the smallest component-model rules established by the
first native Hero proposal. It is a model for reusable Phoenix APIs, not a
catalogue specification.

## Taxonomy

- **Primitives** are small, independently meaningful building blocks such as
  a text treatment or an action surface. They expose only the contract needed
  by more meaningful compositions.
- **Components** are reusable semantic units with a stable public contract of
  attrs and slots. A component is a Phoenix function component by default.
- **Patterns** are compositions of components that express a recurring layout
  or interaction arrangement. A pattern is justified by repeated evidence,
  not by every nested DOM element.
- **Sections** are page-level semantic compositions with a meaningful content
  role, such as a Hero. A section may compose primitives and components while
  keeping one deliberate consumer-facing contract.

The Hero tracer is a section. Its content, actions, overlay, and background
remain internal structure until an independent reusable contract is proven.

## Public contracts

- Name APIs after semantic intent, never after a source system, export, CSS
  class, breakpoint, or fixture.
- Use attrs for plain, scalar content and stable configuration. Use slots when
  consumers need arbitrary Phoenix markup or application-owned behavior.
- Keep optional content naturally optional. Do not add a knob for every source
  style or every current responsive value.
- Prefer constrained values with deterministic rendering over arbitrary tag,
  selector, class, or style input.
- A function component owns presentation and semantic structure. Consumer
  applications own links, events, navigation, business rules, analytics, and
  state unless a separately proven component contract says otherwise.

## Function components and state

Use `Phoenix.Component` function components by default. A `LiveComponent`,
nested LiveView, hook, process, or server event is justified only by concrete
component-owned state or interaction evidence. Static/local presentation does
not acquire state merely because it renders inside LiveView.

## Attributes, slots, and global attributes

Every public attr and slot must have a semantic purpose, a documented default
or requirement, and an accessibility consequence where applicable. Named slots
are appropriate when a small number of stable semantic roles is evidenced;
repeatable or variant-heavy slot DSLs are not a default.

For a singular named slot, the component validates slot-entry cardinality
before rendering. A slot with cardinality zero or one accepts no more than one
entry. The component validates entries, not arbitrary nested descendants in
consumer HEEx. Each consumer-supplied action role must provide one appropriate
interactive root and a meaningful accessible name.

Declarative attr values can provide compile-time warnings for literal inputs,
but dynamic invariants still require deterministic runtime guards. Invalid
values raise `ArgumentError`; components do not coerce, silently fall back, or
infer missing accessibility information.

`id`, `class`, and standard global attributes follow Phoenix conventions. The
component may merge consumer classes with its internal semantic classes, while
internal classes remain implementation details. `attr :rest, :global` is the
preferred global-attribute contract. Explicit `id` and `class` are not also
controlled through `rest`, and callers do not provide a second `rest={...}` map
API. Raw inline `style` is not the primary extension mechanism.

Consumer global attrs can alter root semantics, focus behavior, visibility,
ARIA, data attributes, LiveView bindings, and appearance. Those effects are
consumer-owned and outside the component-owned accessibility and isolated
visual guarantees. HEEx escaping remains authoritative, and ordinary content
never uses `raw/1`.

## Accessibility

Components provide deterministic native semantics, valid heading structure,
visible keyboard focus where an interactive surface is styled, and
LiveFrames-owned markup that does not itself introduce positive `tabindex`,
hidden focus targets, inappropriate ARIA replacing native semantics, or
component-owned root event behavior. Consumers choose the document heading
hierarchy, provide meaningful action names and markup, and make an explicit
informative-versus-decorative image decision. Consumer global attrs remain
consumer-owned. A component does not claim complete WCAG conformance from
isolated markup.

## Tokens and styling

Design tokens remain the authority for shared color, type, spacing, layout,
border, and state values. P6.1 records responsibility and gaps; it does not
invent or implement new tokens. Tailwind utilities, CSS-first `@theme`
variables, and scoped/colocated CSS may coexist. The chosen tool must preserve
ordinary CSS selectors and pseudo-states, including `:hover`,
`:focus-visible`, `:disabled`, `::before`, and `::after` where justified.

## Responsive behavior

Responsive implementation is internal component behavior. Public APIs do not
expose source breakpoint names or pixel thresholds. A consumer may use normal
global attributes and classes, but source-specific responsive controls are not
part of the contract unless later evidence proves a stable semantic need.

## Provenance and abstraction boundaries

Source IDs, classes, editor names, attachment identifiers, and source-runtime
concepts remain provenance evidence only. They do not enter public attrs,
slots, module names, or CSS contracts. Do not extract a child solely because it
is a DOM child. Promote a child to a reusable component or primitive only when
its independent semantics, consumers, and lifecycle are proven by more than a
single fixture or when a later tracer supplies that evidence.

These rules intentionally leave the future catalogue, ejection format, and
broader Hero taxonomy open for later evidence.
