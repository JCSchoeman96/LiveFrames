# LiveFrames native token and math authority proposal

**Status:** Proposal only. This document does not establish accepted project authority or authorize implementation.

**Purpose:** Define a reviewable path for LiveFrames-owned native token defaults and responsive math while keeping imported design systems as scoped conversion inputs.

## Decision requested

The project owner should review the separation and lifecycle below before any native profile values or implementation work are proposed. This proposal chooses no numeric defaults, creates no package mapping, and changes no generated output.

## Existing capabilities and observed gap

The repository already has the pieces needed to represent and serialize token values:

- `LiveFrames.Tokens.TokenSet` and `Token` retain semantic values, resolution state, source metadata, and per-token provenance.
- The Automatic.css adapter maps recognized settings into source-neutral token paths and preserves source information in token provenance.
- `FluidDomain`, `FluidValue`, `FluidScale`, `FluidScaleStep`, `Validation`, `Resolver`, and `CSSSerializer` provide source-neutral responsive semantics and CSS realization.
- `LiveFrames.Tokens.CSSValue` supplies CSS candidates, and `LiveFrames.Styling.TokenBridge` materializes mapped TokenSet values as package-owned CSS variables.

The current default theme build does not yet read an independently authored LiveFrames profile. `Mix.Tasks.LiveFrames.Styling.Theme.Build` obtains its TokenSet through `AutomaticCSS.from_file/2` using the Automatic.css settings fixture, then passes that TokenSet to TokenBridge. It supplies source-version options to that path, but `from_file/2` does not verify the fixed reference identity. The shared and Hero mapping files choose token paths and `--lf-*` names; they do not define token values. The `native_shared_v3` filename therefore does not establish independent native value ownership. Current generated theme values remain tied to the adapter input and its provenance.

No production native profile source was found in the inspected code. The current pipeline is an observed architectural gap, not permission to promote imported values into LiveFrames defaults. Any later change to the current theme output requires separate owner authority, a versioned native profile, and output verification.

## Proposed native profile contract

LiveFrames should own an independently authored, versioned native profile. The profile is the authoring record for native defaults. A build selects one profile and materializes it into the existing TokenSet graph, which remains the semantic authority passed to CSSValue and TokenBridge. This does not create a second runtime registry or a second fluid calculation system.

The profile and its materialized tokens should retain source-neutral provenance that identifies the profile ID, profile version, and the owner decision for that version. Imported TokenSets keep their existing adapter, source identity, source keys, and transformation provenance. Materialization must preserve that imported evidence rather than replace it with native-profile metadata.

Native profiles and imported TokenSets are separate inputs. A native profile cannot inherit values from an imported TokenSet. An imported TokenSet cannot become a native profile through a mapping filename, package variable, or successful build. The current native profile format, storage location, and metadata field names remain open decisions. This proposal does not change the TokenSet version or the Design IR schema.

Native-profile admission must verify independent LiveFrames authorship and versioned owner authorization. `CSSValue.candidate/1` gives `metadata["css_expression"]` precedence over `resolved_value`; for derived values it can also use `source_expression`. An adapter-derived expression or source `variable_authorities` record must not enter native defaults without separate evidence of independent authorship and owner authorization. Clearing or replacing source metadata to make an imported token appear native is not an admission path. This guard does not reject legitimate static CSS values authored independently for a native profile, including values that happen to match an imported value.

## Source-neutral mathematical contract

The generic math contract remains owned by Lead 4 and uses the existing Fluid semantics:

- `FluidDomain` describes a bounded viewport-width interval with valid ordered `px` endpoints.
- `FluidValue` represents linear interpolation between resolved endpoints.
- `FluidScale` represents separately interpolated base and ratio parameters.
- `FluidScaleStep` applies its bounded integer power to the scale ratio.

Typography, spacing, and other responsive groups may have independent base endpoints, ratios, scale steps, and viewport domains. A profile may share a domain only when its author explicitly selects that relationship. The profile records those parameters as semantic values in TokenSet; it does not store CSS expressions as canonical meaning.

The two interpolation forms must remain distinct. Endpoint interpolation computes final endpoint values first and interpolates those values. Coupled scale interpolation interpolates the base and ratio independently, then calculates `base(p) × ratio(p)^power`. Adapters may select a form only when source evidence establishes the source semantics. If the evidence does not distinguish the forms, the imported value remains unresolved instead of being guessed.

Validation must reuse the current Fluid V1 rules: finite numeric values, supported and dimension-compatible units, positive finite ratios, integer powers within the existing `-4..4` bounds, valid ordered viewport ranges, valid references, and finite derived results. Unknown fields or semantic versions fail closed. Any different unit, range, exponent, or interpolation rule requires Lead 4 review and a separate authority decision.

Calculation runs during build or conversion. The implementation should reuse the existing TokenSet validation and Fluid resolution paths, calculate each selected profile once, and pass one deterministic candidate through CSSValue and TokenBridge. It should retain the existing serializer's stable ordering and numeric formatting. Do not add a separate rounding policy, duplicate Fluid calculations, rescan the full token graph per output, or perform calculations in browser JavaScript or request-time server code. Database, Redis, ETS, PubSub, GenServer, and Oban infrastructure is not needed.

## Profile modes, precedence, and isolation

The profile mode defines value authority, not CSS scope. `TokenBridge.generate/2` currently emits declarations under global `:root`, so the compiler does not provide separate native and source-fidelity scopes today. Until a scoped CSS realization is separately accepted and verified, one generated stylesheet must select one profile mode.

| Mode | Value authority | Precedence |
| --- | --- | --- |
| Native design-system mode | Owner-accepted LiveFrames native profile | The selected native profile, then an explicit compiler-managed override accepted for that profile build. A missing native value fails validation. |
| Source-fidelity mode | Source-verified and adapter-normalized imported TokenSet | The proven, resolved imported value. An intentional compiler-managed change is a separate visual-divergence output, not source-fidelity output. |

Native values never fill gaps in source-fidelity mode. Imported values never fill gaps in native mode. An explicit override cannot change a missing, unresolved, ambiguous, or unsupported imported value into a resolved source value. Preserve the original source-resolution state and provenance when a separate visual-divergence output intentionally supplies a different presentation. Conflicting authorities for the same path reject with `AMBIGUOUS_AUTHORITY`. No implicit cross-profile merge is allowed.

Compiler-managed overrides belong to a selected profile build, require explicit versioned authority, and retain their own provenance. They may change a resolved value only within the accepted profile contract. An unmanaged consumer CSS override is a downstream cascade rule. As `docs/11` describes, a consumer may load it after LiveFrames CSS or place it on a scoped container. TokenBridge does not inspect or validate that CSS; it does not alter TokenSet resolution or make the result source-faithful.

Source adapters preserve source meaning at the adapter boundary. Source-fidelity profiles must name the source identity, supported token paths, target component or theme scope, and the evidence for each mapping. Unsupported or ambiguous source values remain unresolved. Conversion fidelity and native design quality are separate review questions.

## CSS generation boundary

TokenSet keeps semantic authority. CSSValue selects a supported candidate. TokenBridge owns package mapping and CSS materialization. The existing Fluid serializer may realize accepted semantics with its supported `clamp()`, `calc()`, or progressive CSS output and deterministic fallback behavior. A FluidScale fallback must preserve the coupled base-and-ratio curve.

Legacy TokenBridge output wraps declarations in global `:root`. Progressive output also places fallback dependencies in global `:root`, then emits modern overrides in an `@supports` block targeting global `:root`. These declarations are not currently isolated by native or source-fidelity profile.

Mixed native and source-fidelity profiles on the same page must not be described as safely scoped today. That use requires separately accepted scoped CSS realization and tests for selector isolation and collisions across declarations, custom-property names, and Fluid fallback dependencies. This proposal does not choose a scoping mechanism or authorize its implementation.

This proposal adds no CSS syntax, package mapping, or source-specific branch to NativeGenerator. It authorizes no JavaScript or request-time calculations and no change to current generated CSS. Future materialization must prove deterministic output and preserve existing fallback behavior before any stylesheet changes.

## Lifecycle, guards, and side effects

### Native profile

| Transition | Guard | Side effect |
| --- | --- | --- |
| `DRAFT -> VALIDATED` | Closed profile shape, complete provenance, valid token references, and valid math | Validation result only; no asset write. |
| `VALIDATED -> OWNER_ACCEPTED` | The owner accepts the exact profile ID, version, values, and math parameters | Records versioned owner authority; no asset write. |
| `OWNER_ACCEPTED -> MATERIALIZED` | The selected build identifies that accepted profile version and passes it through TokenSet, CSSValue, and TokenBridge | Produces an in-memory or private candidate; does not publish. |
| `MATERIALIZED -> VERIFIED` | CSS safety, mapping uniqueness, deterministic serialization, expected output identity, and required acceptance tests pass | Records verification for the exact profile and output. Publication still needs a separate target-specific release decision. |

An accepted profile is immutable. A change to any token value, domain, ratio, step, or serialization authority requires a new profile version, a new owner decision, and fresh output verification.

### Imported profile

| Transition | Guard | Side effect |
| --- | --- | --- |
| `OBSERVED -> SOURCE_VERIFIED` | Source identity and version pass the existing trusted-source boundary | Records source identity evidence; no normalization yet. |
| `SOURCE_VERIFIED -> NORMALIZED` | The selected adapter recognizes the source and maps supported meanings while preserving provenance | Creates a source-derived TokenSet; unresolved values remain explicit. |
| `NORMALIZED -> FIDELITY_SCOPED` | Each selected source value has a proven mapping and an explicit target scope | Selects the conversion scope; native defaults remain excluded. |
| `FIDELITY_SCOPED -> REALIZED` | The candidate passes supported math, CSS safety, mapping, and output checks | Produces a private or in-memory candidate. Public output still requires exact target-specific publication authority. |

The terminal rejection outcomes are `INSUFFICIENT_EVIDENCE`, `AMBIGUOUS_AUTHORITY`, `INVALID_MATH`, `PUBLICATION_BLOCKED`, and `SOURCE_VALUE_UNRESOLVED`. A rejection produces diagnostics and no public asset for the blocked scope. No transition in this proposal writes or publishes generated assets.

## Future implementation ownership

- Lead 4 owns generic Fluid semantics, validation, resolution, and serializer math. Any change to those contracts needs Lead 4 review.
- Lead 1 owns adapter boundaries, source-fidelity scoping, style/compiler integration, native profile selection, and native component generation. TokenBridge remains the package mapping and materialization boundary.
- The project owner decides the native profile identity and version, all default values and design parameters, acceptance policy, and any migration or publication scope.

This proposal changes documentation only. It does not assign implementation work or change another Lead's owned code.

## Proposed acceptance and negative tests

Future implementation review should require:

- A native profile fixture with explicit LiveFrames provenance and no Automatic.css, Bricks, or Frames input dependency.
- A negative admission test where adapter-derived `metadata["css_expression"]` takes precedence over `resolved_value`, or source `variable_authorities` identify the token as imported; reject it as a native default without independent owner authorization. A positive test must admit an independently authored native static CSS value with native provenance.
- Independent native and imported profile builds that produce their own TokenSets and preserve their separate provenance.
- Compiler-managed override tests that preserve the imported token's original resolution state and provenance, keep unresolved or unsupported values unresolved, and record intentional visual divergence separately from source-fidelity output. Consumer CSS override tests must show that unmanaged cascade rules do not mutate TokenSet state.
- Scoped realization and collision tests for declaration selectors, custom-property names, and Fluid fallback dependencies before any mixed native/source-fidelity same-page use is supported.
- A FluidValue case and a FluidScale case that distinguish endpoint interpolation from coupled base-and-ratio interpolation between endpoints.
- TokenSet and CSSValue resolution tests for typography and spacing profiles using the accepted math contract.
- Stable TokenBridge bytes, safe declarations, unique package variables, and existing FluidScale fallback equivalence.
- A regression check that the current committed CSS output remains byte-for-byte unchanged until a separately accepted migration authorizes a change.
- Schema checks that preserve Design IR `6.0.0` and TokenSet `1.0.0` unless separate versioned authority approves a change.
- Failure tests for missing provenance, unverified source identity, unresolved references, ambiguous scoped authorities, non-finite inputs or results, invalid units, non-positive ratios, invalid viewport ranges, out-of-bound powers, unsupported versions, and source values that would otherwise be filled from native defaults.
- A publication gate test that blocks public output when the exact target and permission scope are not accepted.

These are proposed checks only. This proposal runs no tests and authorizes no implementation.

## Unresolved owner decisions

Before implementation, the owner must decide:

1. Whether to accept the native-profile separation as project authority and where the versioned profile authoring record will live.
2. The native profile ID and versioning policy.
3. Every initial native typography, spacing, and responsive-scale value, including base endpoints, ratios, steps, viewport endpoints, and domain-sharing choices. This proposal supplies none of them.
4. Whether the existing provenance maps can record native profile authorship and owner decisions without changing a public schema.
5. The scope names and precedence rules for consumer overrides, including conflict handling.
6. Whether current default theme generation will later migrate to an independent native profile, and the exact compatibility and output-verification gates for that migration.
7. Whether any source-derived output has sufficient source-specific rights evidence and owner approval for each public distribution target.

## Milan IR7 boundary

The [canonical provenance boundary](../04_SOURCE_AND_PROVENANCE.md#feature-milan-ir7-r3-implementation-and-r4-publication-boundary) records R3 BG implementation as verified and its publication clearance as not established. R3 receives no retrospective clearance here.

R4 exact-output verification remains private evidence. This proposal does not reproduce the expression or its checksum, create a native token from it, add its package mapping, or regenerate either stylesheet. Source-fidelity Milan R4 remains blocked pending official rights evidence and owner approval. The historical R4 technical authority does not authorize an independent LiveFrames native default.

```text
R3_IMPLEMENTATION=VERIFIED
R3_PUBLICATION_CLEARANCE=NOT_ESTABLISHED
R4_EXACT_OUTPUT=VERIFIED_PRIVATE
R4_PUBLIC_OUTPUT_CLEARANCE=NOT_ESTABLISHED
R4_IMPLEMENTATION_AUTHORIZED=NO
R5_AUTHORIZED=NO
FINAL_GENERATION_AUTHORIZED=NO
DESIGN_IR_SCHEMA=6.0.0
```

The independent native math programme may proceed through its own owner decisions. It does not change these Milan states.
