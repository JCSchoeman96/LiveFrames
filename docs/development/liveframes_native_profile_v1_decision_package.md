# LiveFrames native profile V1 decision package

- **Status:** Proposal only. No profile values or ownership decisions are accepted.
- **Implementation:** Not authorized.
- **Profile JSON:** Not created.
- **Date:** 2026-11-05

This package recommends a first independently authored LiveFrames profile for
typography and spacing. Its values are design proposals. It does not change
TokenSet, Design IR, mappings, the current theme build, or generated CSS.

## Decision summary

Adopt the proposed profile identity **liveframes.native.core**, independent
profile version **1.0.0**, and future source path
**apps/live_frames/priv/native_profiles/liveframes_native_core_v1.json**.
Keep the profile version separate from the existing TokenSet and Design IR
versions.

Use one explicitly shared viewport domain for typography and spacing. Give the
two groups separate coupled FluidScale parameters and token steps. Typography
uses rem values and a scale anchored at the H5 step so every proposed power
stays within the existing FluidScaleStep bounds. Spacing uses a separate scale
with rem values for gaps, padding, and section rhythm.

I selected these values from native design goals. I used no Automatic.css
fixture values, source CSS output, or copied ACSS expression. Numerical
design parameters and calculated samples in this package are **PROPOSED**.
The existing math and schema limits cited below remain existing authority.

## Current authority and contract

The four named authorities support independent LiveFrames defaults, source
neutral fluid semantics, existing TokenSet integration, and a separate
publication decision. None accepts the values proposed here.

- The [native token and math authority proposal](liveframes_native_token_math_authority_proposal.md)
  leaves profile identity, storage, and numeric defaults open. It also requires
  source provenance to remain intact and forbids implicit native/source-fidelity
  fallback.
- The [CSS and Tailwind strategy](../11_CSS_AND_TAILWIND_STRATEGY.md) keeps
  theme values in TokenSet and generated CSS as their deterministic
  representation. The current theme build remains unchanged until the owner
  accepts and reviews a separate migration.
- The [Fluid Sizing design specification](../superpowers/specs/2026-10-22-liveframes-fluid-sizing-design.md)
  owns the existing Fluid V1 types, validation, resolution, math, CSS
  realization, determinism, and limits. Its implementation remains unauthorized.
- [Source and provenance](../04_SOURCE_AND_PROVENANCE.md) separates internal
  use, redistribution, and publication. A native rewrite or successful build
  does not establish publication permission.

The existing TokenSet is version **1.0.0**. Its root already has
source_metadata, tokens, and diagnostics. Each Token already has resolved_value,
resolution_status, references, provenance, and metadata. TokenSet validation
already accepts JSON object metadata and validates Fluid semantics and graph
references. Keep these fields and the TokenSet version. Do not change Design IR
schema **6.0.0**.

Fluid V1 already defines the JSON semantic types fluid_domain, fluid_value,
fluid_scale, and fluid_scale_step. Their existing format_version is **1.0.0**.
Use categories such as layout, typography, and spacing, not a new generic fluid
category. Store the semantic map in each token's resolved_value; keep canonical
meaning out of CSS strings.

The proposed TokenSet graph uses these paths. They are semantic token IDs, not
package CSS mappings:

| Role | PROPOSED path | PROPOSED category, type, and reference |
| --- | --- | --- |
| Shared viewport domain | layout.fluid.viewport.native_core | Category layout; fluid_domain; no references. |
| Typography scale | typography.scale.native_core | Category typography; fluid_scale; reference the domain path. |
| Body size | typography.body.size | Category typography; fluid_scale_step at power -2; reference the typography scale. |
| Heading sizes | typography.heading.size.h6 through typography.heading.size.h1 | Category typography; one fluid_scale_step per heading, with powers -1 through 4; each references the typography scale. |
| Spacing scale | spacing.scale.native_core | Category spacing; fluid_scale; reference the domain path. |
| Spacing steps | spacing.scale.3xs through spacing.scale.3xl | Category spacing; one fluid_scale_step per step, with powers -4 through 4; each references the spacing scale. |

For every edge, Token.references must equal the reference named in its closed
Fluid semantic map. The profile does not assign --lf-* names or change the
existing mappings.

The existing Fluid resolver resolves an indexed TokenSet graph. CSSValue
selects a candidate. CSSSerializer plans the supported Fluid realization.
TokenBridge materializes mapped values as package variables. The proposed
profile adds no math engine or source-specific branch.

## Profile identity and provenance

| Field | Recommendation |
| --- | --- |
| Stable profile ID | **PROPOSED:** liveframes.native.core. Keep this ID stable across content revisions. |
| Independent profile version | **PROPOSED:** 1.0.0, using SemVer independently from TokenSet 1.0.0, Design IR 6.0.0, and Fluid format_version 1.0.0. |
| Future profile file | **PROPOSED:** apps/live_frames/priv/native_profiles/liveframes_native_core_v1.json. This is a future location only; this PR creates no JSON. |

Treat each accepted profile version as immutable. Any semantic change needs a
new version, a new owner decision, and fresh verification. Under the proposed
version policy, a patch records a metadata-only correction, a minor version
adds or changes profile values without changing the profile contract, and a
major version changes the profile shape or meaning. The owner must accept this
policy before implementation.

Use the existing JSON maps for native provenance. Do not add TokenSet or Token
fields.

| Record | Proposed fields |
| --- | --- |
| Profile provenance | authority_kind = liveframes_native_profile; profile_id; profile_version; authorship_basis = independent_liveframes_design; author_ref; authored_at; selection_rationale_ref; source_inputs = []. |
| Owner decision | status = not_accepted in a draft; decision_ref; accepted_profile_sha256; decision_owner_ref; decided_at. Accepted fields stay empty until a human decision identifies the exact profile content. |
| TokenSet root | Store the profile provenance and owner decision under TokenSet.source_metadata["native_profile"]. Preserve the existing outer TokenSet shape. |
| Each authored token | Store profile_id, profile_version, authorship_basis, selection_rationale_ref, and the exact accepted decision reference and digest in the existing token provenance map. |

Use stable identity references for author_ref and decision_owner_ref. Store
authored_at and decided_at as UTC timestamps. The owner_decision status is
not_accepted in a draft and may become accepted or rejected only through a
recorded human decision. decision_ref points to that durable decision record.
accepted_profile_sha256 is the SHA-256 digest of the exact profile file bytes.
Store the owner decision in TokenSet.source_metadata, outside the hashed file.
selection_rationale_ref points to this proposal and any later accepted design
decision that records why the values were chosen.

Admission requires the root and each token to agree on the profile ID, version,
and accepted content digest. A native profile has no source inputs. Do not
relabel imported evidence or clear provenance to make an imported token look
native. CSSValue gives metadata["css_expression"] precedence over
resolved_value. Derived tokens may also carry source_expression, and source
variable authority can identify imported values. Those signals
require rejection unless separate evidence proves independent authorship and
owner authorization.

The proposed provenance fields are data inside existing maps. Keeping the
owner decision outside the profile file avoids a self-referential digest. If
validation requires a new TokenSet field, version, or shape, stop with
STOP=LEAD4_CONTRACT_CHANGE_REQUIRED.

## Proposed typography profile

The shared domain is **PROPOSED** to start at 360px and end at 1440px.
Its midpoint sample is 900px. These endpoints describe the continuous
viewport-width range. Below the start, bounded interpolation uses the start
value. Above the end, it uses the end value.

The typography scale's base is the H5 anchor. Its proposed endpoints are
1.44rem and 1.7578125rem; its ratio moves from 1.20 to 1.25 across the
domain. The endpoint sizes make the body token, at power -2, equal 1rem at the
start and 1.125rem at the end. Keeping the H5 anchor in the scale lets all body
and heading steps fit the existing integer power bounds.

| PROPOSED viewport sample | PROPOSED width | PROPOSED p | PROPOSED H5 base | PROPOSED ratio |
| --- | ---: | ---: | ---: | ---: |
| Start | 360px | 0 | 1.4400000000rem | 1.2000000000 |
| Midpoint | 900px | 0.5 | 1.5989062500rem | 1.2250000000 |
| End | 1440px | 1 | 1.7578125000rem | 1.2500000000 |

| Token relationship | PROPOSED power | PROPOSED at 360px | PROPOSED at 900px | PROPOSED at 1440px |
| --- | ---: | ---: | ---: | ---: |
| Body | -2 | 1.0000000000rem | 1.0654935444rem | 1.1250000000rem |
| H6 | -1 | 1.2000000000rem | 1.3052295918rem | 1.4062500000rem |
| H5, scale base | 0 | 1.4400000000rem | 1.5989062500rem | 1.7578125000rem |
| H4 | 1 | 1.7280000000rem | 1.9586601563rem | 2.1972656250rem |
| H3 | 2 | 2.0736000000rem | 2.3993586914rem | 2.7465820313rem |
| H2 | 3 | 2.4883200000rem | 2.9392143970rem | 3.4332275391rem |
| H1 | 4 | 2.9859840000rem | 3.6005376363rem | 4.2915344238rem |

The table's midpoint values use coupled interpolation. It does not linearly
interpolate each heading's final endpoint sizes. Values are displayed to ten
decimal places for reading; this is not a new calculation or serializer
rounding rule.

The body starts at 1rem, which follows the browser root size. At an
illustrative 16px root, that is 16px; user text scaling and zoom continue to
affect the rem result. The proposed H1 reaches about 4.29rem at the wide
endpoint. That gives a clear display hierarchy, with more wrapping risk on
narrow containers. The H6 endpoint is about 1.2rem. Body copy should use the
body token. Reserve smaller text treatments for nonessential labels with
sufficient contrast. Font family, line-height, weight, and heading/container
wrapping remain separate owner decisions; size alone does not establish
accessibility.

The domain can be shared with spacing because the same viewport interval is a
deliberate profile choice. The typography base and ratio remain independent of
the spacing base and ratio. Changing one group must not rewrite the other.

## Proposed spacing profile

Use a separate scale with proposed base endpoints 0.75rem and 1rem, and a
proposed ratio from 1.25 to 1.3333333333 across the shared viewport domain.
This keeps the base gap at 12px and 16px at an illustrative 16px root. Larger
powers provide more room for component padding and section rhythm.

| PROPOSED viewport sample | PROPOSED width | PROPOSED p | PROPOSED spacing base | PROPOSED ratio |
| --- | ---: | ---: | ---: | ---: |
| Start | 360px | 0 | 0.7500000000rem | 1.2500000000 |
| Midpoint | 900px | 0.5 | 0.8750000000rem | 1.29166666665 |
| End | 1440px | 1 | 1.0000000000rem | 1.3333333333 |

| Token step | PROPOSED power | PROPOSED at 360px | PROPOSED at 900px | PROPOSED at 1440px |
| --- | ---: | ---: | ---: | ---: |
| 3xs | -4 | 0.3072000000rem | 0.3143447740rem | 0.3164062500rem |
| 2xs | -3 | 0.3840000000rem | 0.4060286664rem | 0.4218750000rem |
| xs | -2 | 0.4800000000rem | 0.5244536941rem | 0.5625000000rem |
| s | -1 | 0.6000000000rem | 0.6774193548rem | 0.7500000000rem |
| m, scale base | 0 | 0.7500000000rem | 0.8750000000rem | 1.0000000000rem |
| l | 1 | 0.9375000000rem | 1.1302083333rem | 1.3333333333rem |
| xl | 2 | 1.1718750000rem | 1.4598524305rem | 1.7777777777rem |
| 2xl | 3 | 1.4648437500rem | 1.8856427227rem | 2.3703703702rem |
| 3xl | 4 | 1.8310546875rem | 2.4356218502rem | 3.1604938268rem |

Use the same step table for gaps and padding. A component can choose an s, m, or
l gap for its content density. Component insets can use l through 2xl. Section
block padding can use 3xl on each edge, so the same scale controls the top and
bottom rhythm. These are usage recommendations, not CSS mappings. The package
owner must decide final semantic paths and any mapping changes separately.

The spacing scale grows faster than typography's body size by design. This
gives wide screens larger layout gaps without increasing every text size.
Changing spacing parameters leaves the typography scale unchanged.

## Alternatives and trade-offs

| Choice | Benefit | Cost |
| --- | --- | --- |
| Recommended: separate coupled typography and spacing scales on one explicit domain | Keeps each group internally modular while allowing coordinated viewport bounds. | Requires the owner to review two independent base/ratio pairs and every semantic step. |
| Fixed sizes and spacing | Simple, predictable values with no fluid math. | Leaves more empty space on wide screens or tighter layouts on small screens; no continuous adjustment. |
| One shared base and ratio for type and space | Fewer parameters. | Couples reading size to layout rhythm. A spacing change would also alter the type hierarchy. |
| A separate endpoint-first FluidValue for every output token | Direct control of each mobile and desktop endpoint. | Loses one coupled modular relationship and makes consistent scale edits harder. Choose FluidValue only when endpoint-first interpolation defines the value. |

## Math and resolver contract

Use the existing Fluid V1 contract without changing its semantics:

- **FluidDomain** supplies bounded viewport_width interpolation. Its start
  and end are finite, ordered px lengths.
- **FluidValue** linearly interpolates one value's endpoints. Use it where
  endpoint-first interpolation is the intended meaning.
- **FluidScale** linearly interpolates a typed base and a positive finite
  ratio independently.
- **FluidScaleStep** applies an integer power from -4 through 4 to the
  coupled scale.
- **Resolver** resolves references from the indexed TokenSet graph.
- **CSSSerializer** realizes accepted semantics with its existing fallback or
  modern planning path. Keep generated CSS out of canonical token data.

For viewport width W, domain start W0, and domain end W1, calculate:

    raw_p = (W - W0) / (W1 - W0)
    p = min(1, max(0, raw_p))
    linear(a, b, p) = a + (b - a) * p
    FluidValue(p) = linear(start_value, end_value, p)
    base(p) = linear(base_start, base_end, p)
    ratio(p) = linear(ratio_start, ratio_end, p)
    step(p, n) = base(p) * ratio(p)^n

All inputs and calculated results must be finite. Length endpoints use
compatible px or rem units. Ratios must remain positive and finite. Domain
lengths use px; domain start must be less than end. References must resolve
to the exact expected type. Unknown fields and versions fail closed. Powers
remain integers within -4..4. Reject an overflow or non-finite result.

### Worked coupled example

At the proposed midpoint W = 900px, the proposed domain gives
p = (900 - 360) / (1440 - 360) = 0.5. The typography scale base is
1.59890625rem; its ratio is 1.225. The proposed H1 power is 4, so:

    H1(900px) = 1.59890625 * 1.225^4
              = 3.60053764rem

Endpoint-first interpolation of the H1 endpoints would produce
3.638759211914rem at that same midpoint. The results differ, so preserve the
coupled base-and-ratio calculation. Do not replace it with interpolation
between final step endpoints.

For comparison, a FluidValue between the proposed body endpoints 1rem and
1.125rem returns 1.0625rem at the midpoint. The body FluidScaleStep returns
1.0654935444rem there. These values differ because FluidValue interpolates its
endpoints while the scale step interpolates the base and ratio.

For spacing, the proposed midpoint base is 0.875rem and ratio is
1.29166666665. The proposed 3xl step at power 4 is:

    3xl(900px) = 0.875 * 1.29166666665^4
               = 2.435621850159rem

These examples use only the proposed profile parameters. They do not reproduce
source CSS or adapter output.

## Authoring rationale and assumptions

The typography proposal anchors body copy at 1rem on the compact endpoint
and 1.125rem at the wide endpoint. The proposed ratios move from 1.20 to
1.25, which increases heading separation as the viewport widens. The H5
scale base follows from those independently chosen body endpoints and ratios:
body endpoint multiplied by the ratio squared. The H5 anchor keeps body and
six heading levels within the existing power range.

The spacing proposal anchors the base gap at 0.75rem on the compact endpoint
and 1rem on the wide endpoint. Its ratio grows from 1.25 to
1.3333333333 so padding and section rhythm expand faster than body copy.
Typography and spacing share only the proposed viewport bounds.

The viewport endpoints represent a compact phone width and a wide desktop
width. Values outside them hold at the bounded endpoints. This package assumes
type and spacing use rem values, the build does not rewrite the browser root
size, and no default comes from imported source data. The owner still needs to
decide actual font families, line-height, semantic token paths, style mappings,
container behavior, and whether these values fit the current public theme.

Identical commonplace values would not prove independent authorship. The
recorded selection reasons above are the proposed rationale. Future
implementation must keep source inputs empty and retain the exact owner
decision reference and profile content digest.

## Future implementation boundary

The smallest future slice should run only after the owner accepts this exact
profile and its provenance fields:

1. Add the approved profile file at the proposed path and a loader that creates
   the existing TokenSet shape. Keep the new profile version independent from
   TokenSet and Design IR versions.
2. Validate its closed semantic maps and references with existing TokenSet and
   Fluid validation. Resolve one typography step and one spacing step through
   Resolver.
3. Produce an in-memory or private candidate through CSSValue and
   CSSSerializer. Keep the current default theme build and all committed
   generated bytes unchanged. Do not edit mappings or publish the candidate.
4. Add acceptance and rejection tests listed below. Measure the work at build
   time against the existing compiler path before any broader integration.

Lead 1 owns native profile selection, its loader boundary, and compiler mode
isolation. Lead 4 owns FluidDomain, FluidValue, FluidScale, FluidScaleStep,
validation, resolution, serializer math, compatibility math, and any
TokenBridge integration. Lead 1 must not change Lead 4's math contracts.
Any required math or public TokenSet contract change stops with
STOP=LEAD4_CONTRACT_CHANGE_REQUIRED. No implementation is authorized by this
document.

The current TokenBridge output uses global :root declarations. Until a
separate scoping authority and collision proof exist, one stylesheet must use
one profile mode. Do not combine native and source-fidelity values in the same
CSS output. Native mode must fail when its selected profile lacks a value.
Source-fidelity mode must keep missing, unresolved, or unsupported source
values unresolved. Never fill them from native defaults.

Profile resolution and serialization run at build time. Reuse indexed TokenSet
lookups and emit shared domain/scale dependencies once. Target work should
scale with the number of domains, scales, and selected fluid tokens. Do not
rescan the full graph for every output token. Do not add database, Redis, ETS,
PubSub, GenServer, Oban, calculations during requests, or JavaScript in the
browser. Record cold and warm build timings before expanding the slice;
agree on a performance threshold before implementation rather than inventing
one here.

## Exact future acceptance and rejection tests

The following checks are proposed requirements. They are not run by this
docs-only change.

| Test | Accept when | Reject when |
| --- | --- | --- |
| Profile identity and owner digest | The loader selects the exact accepted ID, version, and profile content digest; root and token provenance match. | ID, version, decision reference, digest, or token provenance is missing or mismatched. |
| Existing schemas | The result keeps TokenSet 1.0.0, Design IR 6.0.0, and Fluid object format_version 1.0.0. | Any implementation requires changing those contracts without a separate authority decision. |
| Independent authorship | The native profile has an empty source input list and independently authored token provenance. | Any default came from ACSS fixtures, source CSS, Bricks, Frames, adapter output, or a cleared/replaced source record. |
| Calculated samples | Resolver results at 360px, 900px, and 1440px match the full-precision coupled formulas within the existing pure-math tolerance. The tables show those results to ten decimal places. | Any sample uses endpoint-first math for a FluidScaleStep or exceeds the existing tolerance. |
| Coupled curve | The H1 midpoint follows base(0.5) * ratio(0.5)^4 and differs from endpoint-first interpolation. | The H1 result is replaced by a line between final endpoints. |
| Spacing curve | The 3xl midpoint follows base(0.5) * ratio(0.5)^4 for the independent spacing scale. | A typography change alters the spacing curve, or vice versa. |
| Bounds and values | Below-domain and above-domain samples clamp to endpoints; all inputs and results are finite; compatible px/rem lengths and positive ratios validate. | Equal or reversed domain endpoints, a non-px domain, a non-positive or non-finite ratio, a non-finite input or result, or overflow is rejected. |
| Powers and references | Integer powers at the existing -4 and 4 bounds and every integer between them pass with exact typed references. | Powers -5, 4.5, or 5, a missing or wrong target, a cycle, an unknown Fluid version, or an unknown field is rejected. |
| Token resolution | Resolved native Fluid tokens resolve through the existing graph and CSSValue boundary without mutating source records. | An unresolved or unsupported native value is serialized or filled from another profile. |
| CSS candidate admission | Native static values with matching independent provenance reach CSSValue and the existing safety checks. | metadata["css_expression"], source_expression, or imported variable authority silently wins over the native value. |
| Deterministic output | Repeated builds from identical accepted input produce identical TokenSet serialization and private CSS candidate bytes, with stable dependency ordering and one shared dependency per used scale/domain. | Map iteration, build order, or repeated dependency emission changes bytes. |
| Collision rejection | All declarations and Fluid fallback dependencies have unique names within the selected profile. | Duplicate semantic owners or conflicting custom-property names are emitted; return AMBIGUOUS_AUTHORITY. |
| Profile isolation | One output selects one mode; a separate accepted scope is required before mixed-profile output. | Native and source-fidelity values merge implicitly or use unaccepted global :root scoping. |
| Current output regression | Existing default theme and committed application CSS remain byte-for-byte unchanged. | The profile changes current generated bytes before a separate migration decision. |
| Build performance | Indexed lookup avoids a full TokenSet graph scan per output; measured cold and warm timings meet the threshold set before implementation. | Resolution work grows by repeated full graph scans or adds runtime/database infrastructure. |
| Publication gate | Publication requires an accepted target, exact verified output digest, and separate target-specific publication approval. | A private candidate, successful test, or native authorship alone is treated as publication authority. |

The positive authoring test also admits an independently authored native static
value whose number happens to match a commonplace or imported value, provided
its source input list is empty and its exact profile digest has owner approval.
Three negative admission cases must reject: an imported numeric token whose
metadata contains css_expression, a derived token with source_expression, and
a token whose variable authority identifies an imported source.

Use the existing Lead 4 numerical-equivalence limits and sample set. The pure
reference math limit is absolute error at most 1e-9. Browser computed lengths
use absolute error at most 0.01 CSS px after conversion with the actual
browser root size. Existing samples include below-domain, start, 25%, 50%,
75%, end, and above-domain inputs. This package does not widen those limits or
add a rounding policy.

## Lifecycle and transition rules

This is a future lifecycle. The package remains at DRAFT now.

| Transition | Guards | Side effects | Rejection or terminal result |
| --- | --- | --- | --- |
| DRAFT → VALIDATED | Closed profile shape; known profile version; complete proposed provenance fields; exact TokenSet references; existing Fluid validation passes; every proposed number is finite and within current units, ratio, domain, and power rules. | Record validation diagnostics only. Write no profile or CSS asset. | Invalid shape, missing provenance, invalid reference, or invalid math returns to author review as INVALID_PROFILE; no materialization. |
| VALIDATED → OWNER_ACCEPTED | The project owner accepts the exact profile ID, version, all typography and spacing values, shared-domain choice, provenance fields, and version policy. Record the decision reference, owner identity reference, timestamp, and accepted profile digest. | Record owner authority for that immutable profile content. Write no generated asset. | Owner rejection ends that submitted revision as REJECTED. Any changed content needs a new profile version and new decision. |
| OWNER_ACCEPTED → PRIVATE_MATERIALIZED | The build explicitly selects that accepted profile and matching digest. TokenSet validation, Fluid resolution, CSSValue, and serializer checks pass. The build has no adapter or fixture input for native values. | Produce only an in-memory or private candidate with provenance and output digest. Do not write or publish package CSS. | Mismatch, unresolved native values, source contamination, or scope collision gives MATERIALIZATION_REJECTED; no output fallback. |
| PRIVATE_MATERIALIZED → VERIFIED | The exact profile and candidate pass the acceptance tests, safety checks, deterministic byte check, collision checks, and unchanged-current-output regression. | Record verification for the exact profile digest and candidate digest. Candidate remains private. | Any failed check gives VERIFICATION_FAILED. Correcting it requires a new private candidate and complete verification. |
| VERIFIED → PUBLICATION_APPROVED | A separate owner decision accepts the exact output digest, publication target, scope, provenance, and applicable distribution authority. | Record approval for that target and exact digest. This transition grants only the recorded publication scope. | Missing rights evidence or owner approval gives terminal PUBLICATION_BLOCKED for that candidate. It creates no public asset. |

Approval of one profile version or output does not carry to another version,
target, selector scope, or generated digest. Revisions require a new
validation, owner decision, private materialization, and verification.

## Complete owner-decision checklist

Before implementation, the project owner must decide each item:

- [ ] Accept or reject the native-profile authority boundary. Bricks, Frames,
  and Automatic.css remain adapters, not LiveFrames default authorities.
- [ ] Accept or change profile ID liveframes.native.core.
- [ ] Accept or change independent profile version 1.0.0 and its versioning
  policy.
- [ ] Accept or change the proposed future profile storage path.
- [ ] Accept every proposed viewport, typography, and spacing parameter and
  calculated scale relationship.
- [ ] Accept the shared viewport domain, the separate typography/spacing
  parameters, each power assignment, and the section/gap/padding usage.
- [ ] Decide font family, line-height, font weight, text wrapping constraints,
  and any smaller-text use policy.
- [ ] Accept the native provenance and owner-decision fields, including the
  empty source input requirement and exact accepted-content digest.
- [ ] Confirm those fields fit existing JSON maps without changing TokenSet
  1.0.0 or Design IR 6.0.0.
- [ ] Accept or change the proposed semantic token paths and decide mapping
  ownership. This package makes no mapping change.
- [ ] Decide how a future compiler selects native mode and how missing tokens
  fail. Keep source-fidelity output separate.
- [ ] Confirm that global :root output remains single-mode until separate
  scope authority is accepted.
- [ ] Decide whether a later default-theme migration is in scope and define
  its byte-compatibility and review gates.
- [ ] Set the performance threshold at build time before broader integration.
- [ ] Decide the exact publication target and required rights review after
  private verification. Native authorship does not establish publication
  clearance.

Until every required decision is recorded, the status stays proposal-only.

## Unresolved design decisions

The owner has not accepted the proposed numeric values, profile ID, version, or
storage path. Final token paths and the mapping between those paths and public
LiveFrames variables also remain open. The profile does not choose font family,
line-height, or weight. The current default theme migration, native mode
selection, override precedence, and any future CSS scoping need separate
decisions. The owner must set a performance threshold at build time and identify
the publication target and rights review after verification.

## Milan IR7 boundary

This package uses no private R4 evidence and changes no Milan state:

    R3_PUBLICATION_CLEARANCE=NOT_ESTABLISHED
    R4_IMPLEMENTATION_AUTHORIZED=NO
    R5_AUTHORIZED=NO
    FINAL_GENERATION_AUTHORIZED=NO

It changes no Design IR schema, TokenSet version, mapping, fixture, generated
asset, or implementation permission. No lifecycle transition has occurred.
