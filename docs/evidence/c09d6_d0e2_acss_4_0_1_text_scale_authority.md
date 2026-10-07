# C09D6-D0E2 ACSS 4.0.1 text-scale authority

## Purpose

This record captures the owner-cleared ACSS 4.0.1 text-scale facts needed to
resolve `G-TEXT-S`. It records the three-variable family semantics, active
small-step endpoint overrides, minimum resolved controls, and verification
metadata.

## Owner publication clearance

The project owner reviewed and approved this narrow publication scope on
2026-10-07. Approval covers the `--text-s`, `--text-m`, and `--text-l` family,
their default scale powers, the active `text-s-min` and `text-s-max` endpoint
overrides, the resulting effective endpoints and fluid-clamp relationship,
the three minimum resolved controls, and minimum verification metadata.

This approval does not authorize publication or redistribution of
Automatic.css plugin or SCSS source, source excerpts, generated stylesheets
beyond the three resolved controls below, configuration exports, SQL or
database contents, credentials or secrets, unrelated settings or variables,
or the wider Automatic.css research corpus. This decision makes no broader
claim about Automatic.css licensing, copyright, ownership, or redistribution
status.

## Source identity

- `ACSS_VERSION=4.0.1`
- `SOURCE_ENVIRONMENT=Local Site danbricks`
- `VERSION_EVIDENCE_PATH=wp-content/plugins/automatic-css/automatic-css.php:12`
- `VERSION_EVIDENCE_SHA256=fbb07573733b46f941c49d69153d9c4797bb0bf686da4fbc2d6f8f32cdd14276`

## Version evidence

The owner-controlled installation identifies itself as Automatic.css version
`4.0.1`. The plugin metadata used to verify the version is identified by the
path, line, and SHA-256 above.

## Source-authority records

The paths, line ranges, and SHA-256 values below identify the private source
authority used for verification. They are verification metadata only. No
source contents or excerpts are included in this document.

| Authority record | Private source path | Lines | SHA-256 |
|---|---|---|---|
| Text variables | `assets/scss/modules/text/_text-vars.scss` | 40-51 | `bb66598e6727b16166f33e238d0b4705e4510f496b5614b4e44657431789675e` |
| Text mixins | `assets/scss/modules/text/_text-mixins.scss` | 1-58, 78-94 | `ecab1bedb1cb4653f7a704e0114c3f0a437dcb618c9f26e4e7c1fca83dc64bd1` |
| Text tokens | `assets/scss/modules/text/_tokens.scss` | 1-24 | `a2469293be736b44d39776b6426e4a14bd5c36e549588509896723df02bc382e` |
| Fluid function | `assets/scss/helpers/_functions.scss` | 22-30 | `c29013aec6d8a43c24c9261f018dc0d81cdb9ed1dbd478ffb7c888e935d26ec1` |

## Feature/settings evidence

```text
SETTINGS_EVIDENCE_CLASS=owner-controlled local settings evidence
SETTINGS_EVIDENCE_SHA256=78aa02fe494dd5e07e46e09323c0328e68a5cbc08902a08c0b0b61a158e5bef7

base-text-mob=16
base-text-desk=18
mob-text-scale=1.2
text-scale=1.333
vp-min=360
vp-max=1366
text-s-min=14
text-s-max=15
TEXT_SIZE_VARIABLES_ENABLED=YES
```

Only the approved relevant settings are recorded. No settings file path,
serialized surrounding content, or unrelated configuration is published.

## Text-scale semantic relationship

The three variables belong to one deterministic ACSS 4.0.1 text-scale family.
Their default scale relationships are `--text-s` at power `-1`, `--text-m` at
power `0`, and `--text-l` at power `+1`. ACSS permits explicit mobile and
desktop endpoint overrides for text-scale steps.

| Variable | Default scale relationship | Active endpoint override | Result |
|---|---|---|---|
| `--text-s` | power `-1` | mobile `14`, desktop `15` | CONDITIONAL / PROVEN |
| `--text-m` | power `0` | none | PROVEN |
| `--text-l` | power `+1` | none | PROVEN |

The small-step scale relationship and the active small-step resolved
endpoints are different facts. The active endpoint overrides take precedence
over the default `-1` scale calculation before fluid interpolation.

## Active endpoint overrides

Without explicit overrides, ACSS derives the default `text-s` mobile endpoint
from `base-text-mob / mob-text-scale` and the default desktop endpoint from
`base-text-desk / text-scale`. In the verified source environment,
`text-s-min=14` and `text-s-max=15` replace those respective default
endpoints. The effective endpoints supplied to fluid interpolation are
therefore mobile `14` and desktop `15`.

The resolved relationship is:

```text
TEXT_S_RELATIONSHIP_TYPE=CONDITIONAL_DERIVATION
DEFAULT_RELATIONSHIP=scale power -1
ACTIVE_MOBILE_OVERRIDE=text-s-min=14
ACTIVE_DESKTOP_OVERRIDE=text-s-max=15
OVERRIDE_PRECEDENCE=explicit endpoint override replaces corresponding default endpoint
FINAL_RELATIONSHIP=fluidClamp(effective mobile endpoint, effective desktop endpoint, vp-min, vp-max)
```

**`text-s` has a proven default scale power of `-1`, but this verified ACSS
configuration overrides its mobile and desktop endpoints to `14` and `15`;
therefore a `-1` implementation alone is insufficient.**

## Resolved generated controls

Only the three minimum resolved controls are published:

```css
--text-s: clamp(0.875rem, calc(0.0994035785vw + 0.8526341948rem), 0.9375rem)
--text-m: clamp(1rem, calc(0.1988071571vw + 0.9552683897rem), 1.125rem)
--text-l: clamp(1.2rem, calc(0.4765407555vw + 1.09277833rem), 1.499625rem)
```

## Ambiguity/duplicate verification

All four available generated outputs agree. Each output contains one
definition of each variable, and each variable has one unique value across
the outputs.

```text
TEXT_S_DEFINITION_COUNT=4
TEXT_S_UNIQUE_VALUE_COUNT=1
TEXT_M_DEFINITION_COUNT=4
TEXT_M_UNIQUE_VALUE_COUNT=1
TEXT_L_DEFINITION_COUNT=4
TEXT_L_UNIQUE_VALUE_COUNT=1

FORMULA_INFERENCE_USED=NO
SEMANTIC_AUTHORITY_AMBIGUITY=NONE
SAME_TEXT_SCALE_FAMILY=YES
```

## LiveFrames model gap

```text
EXISTING_ACSS_CLAMP_MODEL_SUFFICIENT=NO
STOP=TEXT_S_MODEL_GAP
```

LiveFrames currently lacks a `text-s` mapping and scale-power `-1` handling.
More importantly, the verified ACSS configuration applies explicit
`text-s-min` and `text-s-max` endpoint overrides. Simply adding scale power
`-1` would not faithfully reproduce the active source semantics.

R1 must define how the source adapter represents default scale relationships,
optional endpoint overrides, effective endpoints, and the resulting
source-independent semantic token. This record does not choose the final
TokenSet path or implementation.

## Provenance boundary

This document publishes only the three-variable text-scale semantic facts,
the active small-step endpoint overrides, the three minimum resolved
controls, and verification metadata. The source paths, line ranges, and hashes
identify private verification authority; they do not reproduce source
material. The underlying source, generated CSS, and configuration remain
private/reference evidence. No source excerpts, stylesheet context,
configuration export, SQL or database contents, credentials, unrelated
settings, or unrelated variables are included.

This scoped `public_safe` decision does not make Automatic.css globally
`public_safe`. The Automatic.css settings-export and 4.0.1 research-set rows
retain their current states. Broader Automatic.css redistribution remains
unresolved, and this decision makes no broader licensing, copyright,
ownership, or redistribution declaration.

## Downstream authorization

While this PR is open:

```text
D0E2_SEMANTIC_EVIDENCE=PROVEN
D0E2_PUBLICATION_CLEARANCE=PENDING_MERGE
R1_CAN_RESUME=NO
D1_AUTHORIZED=NO
C09D7_A_AUTHORIZED=NO
```

After this exact PR is reviewed and merged:

```text
D0E2_SEMANTIC_EVIDENCE=PROVEN
D0E2_PUBLICATION_CLEARANCE=SCOPED_APPROVED
R1_CAN_RESUME=YES
D1_AUTHORIZED=NO
C09D7_A_AUTHORIZED=NO
```

R1 may resume only after this exact PR merges. D1 and C09D7-A remain
unauthorized.
