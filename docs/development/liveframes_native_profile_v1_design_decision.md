# LiveFrames native profile V1 design decision

## Decision

- **State:** `DESIGN_OWNER_ACCEPTED`
- **Decision reference:** `LIVEFRAMES_NATIVE_V1_OWNER_DECISION_RECORD`
- **Accepted proposal:** `docs/development/liveframes_native_profile_v1_decision_package.md`
- **Accepted proposal Git blob:** `c27c53f2f318cfad77d2597c945d758da3438b72`
- **Owner approval date:** 2026-11-05, as stated by the project owner.
- **Decision owner reference:** [GitHub account JCSchoeman96](https://github.com/JCSchoeman96)
- **Identity check:** The authenticated GitHub account and the owner of `JCSchoeman96/LiveFrames` both resolve to `JCSchoeman96`.
- **Decision recorded at:** `2026-11-05T13:59:39Z`

The project owner explicitly approved the exact proposal blob above on
2026-11-05. This record sets `DESIGN_OWNER_ACCEPTED` for the LiveFrames native
typography-and-spacing core described below. The approval is design-only. It
does not accept a complete design system or authorize implementation or
publication.

The owner supplied the approval date but no time of approval. The UTC timestamp
above records this durable decision.

## Accepted profile identity and version policy

| Item | Accepted value |
| --- | --- |
| Scope | LiveFrames native typography-and-spacing core only |
| Profile ID | `liveframes.native.core` |
| Profile version | `1.0.0`, independent of TokenSet `1.0.0`, Design IR `6.0.0`, and Fluid `format_version` `1.0.0` |
| Patch version | Metadata-only corrections |
| Minor version | Add or change profile values without changing the profile contract |
| Major version | Change the profile shape or meaning |

Each accepted profile version is immutable. A semantic change requires a new
version, a new owner decision, and fresh verification.

## Accepted viewport and typography parameters

Typography and spacing share the continuous viewport-width domain from 360px
to 1440px. The midpoint sample is 900px. Interpolation clamps to the start or
end value outside that domain.

The typography scale uses H5 as its base. Its base and ratio vary independently
over the shared domain.

| Sample | Width | `p` | H5 base | Ratio |
| --- | ---: | ---: | ---: | ---: |
| Start | 360px | 0 | 1.4400000000rem | 1.2000000000 |
| Midpoint | 900px | 0.5 | 1.5989062500rem | 1.2250000000 |
| End | 1440px | 1 | 1.7578125000rem | 1.2500000000 |

| Token | Power | At 360px | At 900px | At 1440px |
| --- | ---: | ---: | ---: | ---: |
| Body | -2 | 1.0000000000rem | 1.0654935444rem | 1.1250000000rem |
| H6 | -1 | 1.2000000000rem | 1.3052295918rem | 1.4062500000rem |
| H5, scale base | 0 | 1.4400000000rem | 1.5989062500rem | 1.7578125000rem |
| H4 | 1 | 1.7280000000rem | 1.9586601563rem | 2.1972656250rem |
| H3 | 2 | 2.0736000000rem | 2.3993586914rem | 2.7465820313rem |
| H2 | 3 | 2.4883200000rem | 2.9392143970rem | 3.4332275391rem |
| H1 | 4 | 2.9859840000rem | 3.6005376363rem | 4.2915344238rem |

## Accepted spacing parameters

Spacing uses a separate scale on the same viewport domain. Its base and ratio
remain independent of the typography scale.

| Sample | Width | `p` | Spacing base | Ratio |
| --- | ---: | ---: | ---: | ---: |
| Start | 360px | 0 | 0.7500000000rem | 1.2500000000 |
| Midpoint | 900px | 0.5 | 0.8750000000rem | 1.29166666665 |
| End | 1440px | 1 | 1.0000000000rem | 1.3333333333 |

| Step | Power | At 360px | At 900px | At 1440px |
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

The sample values above retain the proposal's displayed precision. They add no
rounding rule.

## Accepted token paths and references

The accepted graph contains 19 canonical semantic token paths. For every
reference edge, `Token.references` must match the target in the closed Fluid
semantic map.

| # | Canonical path | Category | Type | Power | Reference |
| ---: | --- | --- | --- | ---: | --- |
| 1 | `layout.fluid.viewport.native_core` | layout | `fluid_domain` | n/a | none |
| 2 | `typography.scale.native_core` | typography | `fluid_scale` | n/a | `layout.fluid.viewport.native_core` |
| 3 | `typography.body.size` | typography | `fluid_scale_step` | -2 | `typography.scale.native_core` |
| 4 | `typography.heading.size.h6` | typography | `fluid_scale_step` | -1 | `typography.scale.native_core` |
| 5 | `typography.heading.size.h5` | typography | `fluid_scale_step` | 0 | `typography.scale.native_core` |
| 6 | `typography.heading.size.h4` | typography | `fluid_scale_step` | 1 | `typography.scale.native_core` |
| 7 | `typography.heading.size.h3` | typography | `fluid_scale_step` | 2 | `typography.scale.native_core` |
| 8 | `typography.heading.size.h2` | typography | `fluid_scale_step` | 3 | `typography.scale.native_core` |
| 9 | `typography.heading.size.h1` | typography | `fluid_scale_step` | 4 | `typography.scale.native_core` |
| 10 | `spacing.scale.native_core` | spacing | `fluid_scale` | n/a | `layout.fluid.viewport.native_core` |
| 11 | `spacing.native_core.step_n4` | spacing | `fluid_scale_step` | -4 | `spacing.scale.native_core` |
| 12 | `spacing.native_core.step_n3` | spacing | `fluid_scale_step` | -3 | `spacing.scale.native_core` |
| 13 | `spacing.native_core.step_n2` | spacing | `fluid_scale_step` | -2 | `spacing.scale.native_core` |
| 14 | `spacing.native_core.step_n1` | spacing | `fluid_scale_step` | -1 | `spacing.scale.native_core` |
| 15 | `spacing.native_core.step_zero` | spacing | `fluid_scale_step` | 0 | `spacing.scale.native_core` |
| 16 | `spacing.native_core.step_p1` | spacing | `fluid_scale_step` | 1 | `spacing.scale.native_core` |
| 17 | `spacing.native_core.step_p2` | spacing | `fluid_scale_step` | 2 | `spacing.scale.native_core` |
| 18 | `spacing.native_core.step_p3` | spacing | `fluid_scale_step` | 3 | `spacing.scale.native_core` |
| 19 | `spacing.native_core.step_p4` | spacing | `fluid_scale_step` | 4 | `spacing.scale.native_core` |

The nine spacing paths correspond in order to labels 3xs, 2xs, xs, s, m, l,
xl, 2xl, and 3xl. The paths are semantic IDs. This decision assigns no
`--lf-*` package variable names.

## Existing Lead 4 semantics

This decision preserves the existing Fluid V1 contract and its Lead 4
ownership. It changes no math, validation, resolver, serializer, compatibility,
or TokenBridge contract.

For viewport width `W`, domain endpoints `W0` and `W1`, and `p` clamped to
`[0, 1]`, the accepted scales retain the existing coupled calculation:

```text
p = min(1, max(0, (W - W0) / (W1 - W0)))
base(p) = base_start + (base_end - base_start) * p
ratio(p) = ratio_start + (ratio_end - ratio_start) * p
step(p, n) = base(p) * ratio(p)^n
```

`FluidDomain` uses a bounded viewport-width interval with finite, ordered `px`
endpoints. `FluidValue` interpolates one value's endpoints. `FluidScale`
interpolates its typed base and positive finite ratio independently.
`FluidScaleStep` applies an integer power from -4 through 4 to that coupled
scale. Resolution follows references in the indexed TokenSet graph. The
existing CSS serializer realizes accepted semantics through its supported
fallback or modern path. The midpoint step is not endpoint-first interpolation
of the final step values.

## Native and source-fidelity isolation

The profile modes remain isolated. One generated stylesheet selects one mode.
The native profile is independently authored and has no source inputs. Native
mode uses the selected native profile and fails if that profile lacks a value.
Source-fidelity mode preserves missing, unresolved, and unsupported source
values as unresolved. Native values never fill source-fidelity gaps, and
imported values never fill native gaps. This decision does not permit an
implicit cross-profile merge or claim that existing global `:root` output
provides mode scoping.

## Decisions that remain open

This approval covers the native typography-and-spacing design scope above.
It leaves the following work undecided:

- Font family, line-height, weight, heading and container wrapping, and smaller
  text policy.
- Mapping these semantic paths to public LiveFrames variables and ownership of
  those mappings.
- The physical profile storage path, the private draft and evidence paths, and
  any committed profile artifact.
- Native mode selection, override precedence, CSS scoping, and collision
  proof.
- Default-theme migration and a build-performance threshold.
- Authorization for profile JSON, a loader, parser, harness, tests, persistent
  code, compiler integration, or profile artifact acceptance.
- Publication target, exact output acceptance, and applicable rights evidence.

No profile JSON exists as part of this decision, so it records no profile-file
digest. Any profile artifact requires a separate authorization and a later
owner decision for its exact bytes and SHA-256 digest. Publication requires a
separate decision for the exact output and target. This record grants no Milan
R4 implementation authority and clears no publication or distribution hold.
