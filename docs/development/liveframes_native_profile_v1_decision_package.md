# LiveFrames native profile V1 decision package

- **Status:** Proposal only. No profile values or ownership decisions are accepted.
- **Lifecycle state:** DESIGN_PROPOSED. No profile JSON exists.
- **Implementation:** Not authorized.
- **Profile JSON:** Not created.
- **Date:** 2026-11-05

This package proposes a first independently authored LiveFrames typography and
spacing core profile. It is not acceptance of a complete design system. Its
values are design proposals. It does not change TokenSet, Design IR, mappings,
the current theme build, or generated CSS.

## Decision summary

Adopt the proposed profile identity **liveframes.native.core**, independent
profile version **1.0.0**, and future canonical repository path
**apps/live_frames/priv/native_profiles/liveframes_native_core_v1.json**.
That path is public if committed and is not a private draft or evidence
location. Any future use of it requires separately scoped implementation
authorization after the appropriate gates. Keep the profile version separate
from the existing TokenSet and Design IR versions.

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
| Spacing steps | See the proposed canonical paths below. | Category spacing; one fluid_scale_step per step; each references spacing.scale.native_core. |

The spacing labels remain human-readable scale labels. Use separate canonical
token paths so each path segment starts with a letter and follows the existing
TokenSet and TokenBridge path rule. These nine paths are **PROPOSED**; each
step's Token.references and Fluid semantic reference target
spacing.scale.native_core.

| Human-readable step label | PROPOSED power | PROPOSED canonical token path | PROPOSED reference target |
| --- | ---: | --- | --- |
| 3xs | -4 | spacing.native_core.step_n4 | spacing.scale.native_core |
| 2xs | -3 | spacing.native_core.step_n3 | spacing.scale.native_core |
| xs | -2 | spacing.native_core.step_n2 | spacing.scale.native_core |
| s | -1 | spacing.native_core.step_n1 | spacing.scale.native_core |
| m | 0 | spacing.native_core.step_zero | spacing.scale.native_core |
| l | 1 | spacing.native_core.step_p1 | spacing.scale.native_core |
| xl | 2 | spacing.native_core.step_p2 | spacing.scale.native_core |
| 2xl | 3 | spacing.native_core.step_p3 | spacing.scale.native_core |
| 3xl | 4 | spacing.native_core.step_p4 | spacing.scale.native_core |

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
| Future canonical repository profile file | **PROPOSED:** apps/live_frames/priv/native_profiles/liveframes_native_core_v1.json. This path is public if committed; it is not the private Stage 3 draft or evidence location. This PR creates no JSON. |

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
| Design decision record | Keep outside the profile JSON. Record status, decision_ref, the full accepted decision-document Git blob object ID, the named accepted scope, profile_id, profile_version, every accepted parameter, all 19 canonical token paths and their type/power/reference relationships, decision_owner_ref, and decided_at. This record does not require a profile-file digest because the profile JSON does not exist at this stage. |
| Profile artifact decision | Keep outside the hashed profile file. Before Stage 5, status = not_accepted. At Stage 5, record decision_ref, accepted_profile_sha256, decision_owner_ref, and decided_at for the exact validated profile bytes. |
| TokenSet root | Store the profile provenance, design decision, and profile artifact decision under TokenSet.source_metadata["native_profile"]. Preserve the existing outer TokenSet shape. |
| Each authored token | Store profile_id, profile_version, authorship_basis, and selection_rationale_ref in the existing token provenance map. After Stage 5, include the design decision reference, profile artifact decision reference, and exact profile digest there. |

Use stable identity references for author_ref and decision_owner_ref. Store
authored_at and decided_at as UTC timestamps. A design decision may become
accepted or rejected only through an explicit, durable human decision that
identifies the full Git blob object ID for this document. Stage 2 records the
accepted design scope, profile ID and version, all accepted parameters, and
all 19 canonical token paths with their type, power, and reference
relationships. It records no profile-file digest because no profile JSON
exists yet.

Reserve accepted_profile_sha256 for Stage 5, after Stage 4 has validated an
existing profile file and calculated SHA-256 over its exact bytes. The Stage 5
artifact decision stays outside the hashed profile file. decision_ref points
to the durable decision record. selection_rationale_ref points to this
proposal and any later accepted design decision that records why the values
were chosen.

After Stage 5, admission requires the root and each token to agree on the
profile ID, version, and accepted content digest. A native profile has no
source inputs. Do not relabel imported evidence or clear provenance to make an
imported token look native. CSSValue gives
metadata["css_expression"] precedence over resolved_value. Derived tokens may
also carry source_expression, and source variable authority can identify
imported values. Those signals
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
implementation must keep source inputs empty. After Stage 5, the materialized
TokenSet provenance must retain both the design decision reference and the
profile artifact decision reference with the exact profile digest.

## Future implementation boundary

The owner must first accept the exact decision-document blob as a design-only
decision. Stage 3 requires a separate, explicit implementation authorization
for JSON drafting only. The authorization must name the exact resolved private
path, for example
`~/.local/state/liveframes/native-profile-work/liveframes.native.core/1.0.0/profile.json`,
and confirm that it is outside Git worktrees and public repositories and is
not in shared, synchronized, or otherwise public storage. Restrict directory
and file permissions to the owner, and keep draft and evidence files in that
authorized private location. A file committed to GitHub is not treated as
private evidence. If the path cannot be kept private, stop without creating
the draft.

The proposed canonical repository path
`apps/live_frames/priv/native_profiles/liveframes_native_core_v1.json` is
separate from this private draft location and is public if committed. Stage 3
does not authorize writing to or committing that canonical path. It also does
not authorize a loader, compiler integration, tests, mappings, generated CSS,
or any other persistent code.

1. Create only the profile JSON at the exact authorized private path. Do not
   create a loader, parser, harness, tests, mappings, assets, or persistent
   code. Keep the profile version independent from TokenSet and Design IR
   versions.
2. Validate the closed semantic maps and references with existing TokenSet
   and Fluid validators through an already-authorized path that can consume
   the private draft. Confirm every value and relationship matches the
   owner-accepted design. Calculate the profile-file SHA-256 only after these
   bytes exist. If validation needs a new loader or harness, stop at
   `PRIVATE_PROFILE_DRAFT` with
   `STOP=VALIDATION_PATH_NOT_AUTHORIZED`. Proceed only after a separate,
   explicit authorization names the temporary private tool, its files, allowed
   use, and removal or quarantine plan. The tool may only adapt or submit the
   draft to the existing validators; it does not authorize changes to those
   validators, production loader code, or compiler integration.
3. After separate owner acceptance of the exact validated profile bytes, a
   further scoped authorization may produce only the named private or
   in-memory candidate through CSSValue and CSSSerializer. Any temporary
   private tooling must be named with its files, allowed use, and removal or
   quarantine plan in that authorization. Keep the current
   default theme build and all committed generated bytes unchanged. Do not
   edit mappings or publish the candidate.
4. The acceptance and rejection tests below are requirements for later,
   separately authorized proof work; they are not implementation authority.
   Measure authorized build-time work against the existing compiler path
   before any broader integration.

Any persistent native profile loader, compiler integration, or related
production code requires its own separately scoped implementation/proof
authorization after the appropriate design and artifact gates. This proposal
and the Stage 3 JSON-only authorization do not grant that authority.

Lead 1 owns native profile selection, its loader boundary, and compiler mode
isolation. Naming Lead 1 as owner defines responsibility, not implementation
permission. Any persistent loader requires its own later, separately scoped
authorization. Lead 4 owns FluidDomain, FluidValue, FluidScale, FluidScaleStep,
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
| Design identity and profile artifact acceptance | The design decision identifies the exact accepted document blob, scope, profile ID/version, parameters, and token relationships. After the JSON exists and validates, a separate owner decision accepts its exact SHA-256 digest; root and token provenance match that accepted artifact. | The design blob, scope, ID, version, values, relationships, artifact decision reference, digest, or provenance is missing or mismatched. |
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
its source input list is empty and its exact profile digest has separate Stage 5
owner acceptance.
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

This package is at `DESIGN_PROPOSED`. No profile JSON exists, no owner has
accepted this proposal, and no implementation authorization exists. The
lifecycle below applies only to the proposed typography-and-spacing core. It
does not accept a complete design system.

| Transition | Guards | Side effects | Rejection or terminal result |
| --- | --- | --- | --- |
| `DESIGN_PROPOSED` → `DESIGN_OWNER_ACCEPTED` | A human owner explicitly accepts the exact full Git blob object ID of this document and the named scope: the LiveFrames native typography-and-spacing core, including its proposed profile ID/version, versioning policy, every proposed parameter, the shared viewport domain, and all 19 canonical token paths with their types, powers, and reference relationships. The decision states that it does not accept a complete design system. No profile-file digest is requested because no profile JSON exists. | Record the durable decision reference, owner identity, UTC timestamp, full document blob ID, accepted scope, profile ID/version, versioning policy, parameters, and token relationships. Change only the design-decision state. Create no JSON, code, tests, mappings, CSS, or publication authority. | Explicit rejection gives `DESIGN_REJECTED`, terminal for that document blob. A changed document has a new blob ID and returns to `DESIGN_PROPOSED`; acceptance never transfers to a different blob. |
| `DESIGN_OWNER_ACCEPTED` → `PRIVATE_PROFILE_DRAFT` | A separate, explicit human implementation authorization cites the accepted design decision and blob ID, names the exact resolved private draft path and evidence location, confirms they are outside Git worktrees/public repositories and shared or synchronized storage, and permits creation of the JSON profile only. It must not authorize a loader, parser, harness, tests, mappings, assets, or persistent code. Design acceptance alone is not authorization. | Create only the JSON profile and necessary private directories at the authorized location; restrict their permissions to the owner. Keep draft and evidence out of GitHub, packages, and assets. Do not write the proposed canonical repository path, publish an asset, or replace the default theme. | A declined or missing authorization gives `IMPLEMENTATION_NOT_AUTHORIZED` for that attempt. An unprivate or public location rejects the attempt; create no file or evidence and do not enter `PRIVATE_PROFILE_DRAFT`. |
| `PRIVATE_PROFILE_DRAFT` → `PROFILE_VALIDATED` | Existing TokenSet and Fluid validators pass through an already-authorized path that consumes the private draft. Every value and relationship matches the owner-accepted design. Provenance is complete, `source_inputs` is empty, source isolation passes, and TokenSet 1.0.0, Design IR 6.0.0, and Lead 4 math contracts remain unchanged. If a new loader or harness is needed, a separate explicit authorization must name the temporary private tool, files, permitted use, and removal or quarantine plan; it may only call existing validators and cannot authorize production loader code or compiler integration. Without that authorization, stop with `STOP=VALIDATION_PATH_NOT_AUTHORIZED` and remain at `PRIVATE_PROFILE_DRAFT`. | Record validation evidence only in the authorized private evidence location and calculate SHA-256 over the exact profile-file bytes. This is the first state with a profile-file digest. A separately authorized temporary validation tool must remain private and be removed or quarantined as specified. Write no generated CSS. | Failure of the existing validators or design/provenance checks gives `PROFILE_VALIDATION_REJECTED`, terminal for those exact bytes. A corrected file is a new candidate and must pass validation again. An unavailable or unauthorized validation path is a stop at `PRIVATE_PROFILE_DRAFT`, not a validation result; create no loader or harness. |
| `PROFILE_VALIDATED` → `PROFILE_ARTIFACT_ACCEPTED` | A human owner separately accepts the exact profile bytes and SHA-256 digest, profile ID/version, accepted design decision, provenance, and validation record. No acceptance is inferred from a proposal merge, CI result, or agent output. | Record the artifact decision outside the hashed profile file. Freeze the accepted profile bytes, identity, and provenance for that version. This grants no publication clearance. | Rejection gives `PROFILE_ARTIFACT_REJECTED`, terminal for those exact bytes. Changed bytes require validation and a new artifact decision. A design change requires a new design decision first. |
| `PROFILE_ARTIFACT_ACCEPTED` → `PRIVATE_MATERIALIZED` | A separate authorization explicitly permits the private or in-memory proof and names its scope, exact accepted profile digest, evidence location, and any temporary private tooling. It passes the existing TokenSet, Fluid, CSSValue, and serializer checks and uses no adapter or fixture input for native values. A persistent loader or compiler integration is outside this transition and requires its own separately scoped implementation/proof authorization after the appropriate gates. | Produce only the authorized private or in-memory candidate and record its output digest in the authorized private evidence location. Keep temporary tools private and remove or quarantine them as authorized. Do not change committed generated CSS, publish an asset, write the proposed canonical repository path, or replace the default theme. | Missing or declined proof authorization gives `PRIVATE_PROOF_NOT_AUTHORIZED`, terminal for that authorization attempt. A mismatch, unresolved value, source contamination, or scope collision gives `MATERIALIZATION_REJECTED`, terminal for that candidate. Produce no fallback output. |
| `PRIVATE_MATERIALIZED` → `VERIFIED` | The exact profile and candidate pass deterministic-output, math-equivalence, isolation, regression, collision, and safety checks. Authorized technical reviewers explicitly accept the evidence. It confirms TokenSet 1.0.0, Design IR 6.0.0, and the Lead 4 math contract remain unchanged. | Record verification against the exact profile and output digests with reviewer references. Keep the candidate private. | Any failed or unaccepted check gives `VERIFICATION_REJECTED`, terminal for that candidate. A changed candidate requires complete verification again. |
| `VERIFIED` → `PUBLICATION_APPROVED` | A separate human decision approves the exact output digest, named target, selector/scope, provenance, and applicable distribution rights. Existing R3/R4 rights holds remain unchanged; this transition does not clear Milan R4. | Record clearance for that exact target and output. The approval permits only that output and scope to publish. This transition does not publish or create an asset. | Missing owner approval or rights evidence gives `PUBLICATION_BLOCKED`, terminal for that output and target. Create no public asset. |

Each terminal state applies to the exact document blob, authorization attempt,
profile bytes, candidate, or publication target named in its transition. A new
attempt starts at the earliest state invalidated by the changed identity and
must produce fresh evidence. Any document edit changes its Git blob identity
and invalidates design acceptance. Any change to profile bytes, identity, or
provenance invalidates artifact acceptance. Any output change invalidates
verification and publication approval. A proposal merge, successful CI run, or
agent output never counts as human acceptance.

## Owner-decision checklist

The Stage 2 design decision is limited to the typography-and-spacing core
proposal. Its durable record must include:

- [ ] An explicit human acceptance or rejection and the full Git blob object ID
  of this exact document.
- [ ] The named scope: the LiveFrames native typography-and-spacing core in
  that document, not a complete design system.
- [ ] Profile ID `liveframes.native.core` and independent profile version
  `1.0.0`, or the exact changed identity if the owner rejects those proposals.
- [ ] The proposed profile versioning policy, or the exact alternative the
  owner selects.
- [ ] Every accepted numeric parameter, the shared viewport domain, the
  separate typography and spacing scales, and their calculated sample
  relationships.
- [ ] All 19 canonical token paths with their types, powers, and reference
  relationships.
- [ ] A durable decision reference, owner identity reference, and UTC
  timestamp.
- [ ] An explicit statement that design acceptance does not authorize
  implementation or publication. No profile-file digest is required at Stage
  2 because no profile JSON exists.

Later gates require separate records:

- [ ] Before Stage 3, authorize only one JSON profile at an exact resolved
  private path, for example
  `~/.local/state/liveframes/native-profile-work/liveframes.native.core/1.0.0/profile.json`.
  Confirm the draft and evidence locations are outside Git worktrees and
  public repositories and are not shared or synchronized; restrict their
  permissions to the owner. Do not authorize the proposed canonical repository
  path, a loader, parser, harness, tests, mappings, assets, or persistent code.
- [ ] Before Stage 4, identify an already-authorized path that runs the
  existing TokenSet and Fluid validators on the private draft. If a new loader
  or harness is needed, stop at `PRIVATE_PROFILE_DRAFT` with
  `STOP=VALIDATION_PATH_NOT_AUTHORIZED`. Resume only after a separate explicit
  authorization names the temporary private tool, its files, allowed use, and
  removal or quarantine plan; it may call existing validators only, cannot
  change them, and grants no production loader or compiler integration
  authority.
- [ ] Before Stage 5, accept the exact validated profile bytes and SHA-256
  digest.
- [ ] Before Stage 6, authorize the exact profile digest and named private or
  in-memory proof, its private evidence location, and any temporary private
  tooling with its files, allowed use, and removal or quarantine plan. This
  does not authorize a persistent loader or compiler integration; those
  require a separately scoped implementation/proof authorization after the
  appropriate gates.
- [ ] Before Stage 8, approve the exact output digest, publication target,
  scope, and rights evidence. This cannot clear existing R3/R4 holds.

Font family, line-height, font weight, wrapping constraints, smaller-text
policy, semantic mapping ownership, default-theme migration, and performance
threshold remain separate decisions. None is accepted by this core proposal.

## Unresolved design decisions

The owner has not accepted the proposed numeric values, profile ID, version,
or storage decisions. The canonical repository path is proposed; the private
draft and evidence paths must be named and verified in separate authorizations.
Final token paths and the mapping between those paths and public LiveFrames
variables also remain open. The profile does not choose font family,
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
