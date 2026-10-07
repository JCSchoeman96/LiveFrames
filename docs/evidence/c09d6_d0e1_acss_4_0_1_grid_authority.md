# C09D6-D0E1 ACSS 4.0.1 structural-grid authority

## Purpose

This record captures owner-cleared ACSS 4.0.1 evidence for the three
structural-grid values needed by LiveFrames. It contains the resolved values
and minimum verification metadata only.

## Owner publication clearance

The project owner reviewed and approved this narrow publication scope on
2026-10-07. Approval covers the resolved values of `--grid-1`, `--grid-2`, and
`--grid-3-2`, together with minimum provenance and verification metadata. It
does not authorize publication of Automatic.css source code, generated
stylesheets, configuration exports, unrelated variables, or the broader
research corpus. This decision makes no broader claim about license,
ownership, copyright, or redistribution status.

## Source identity

- `SOURCE_ENVIRONMENT=Local Site danbricks`
- `VERSION_EVIDENCE_PATH=wp-content/plugins/automatic-css/automatic-css.php:12`
- `VERSION_EVIDENCE_SHA256=fbb07573733b46f941c49d69153d9c4797bb0bf686da4fbc2d6f8f32cdd14276`
- `GENERATED_CSS_EVIDENCE_PATH=wp-content/uploads/automatic-css/automatic-variables.css`
- `GENERATED_CSS_EVIDENCE_SHA256=34127351b41a2496c5be9a9f238aba2fcffd63dc8a790eefc8f03d6b3becd093`
- `GENERATED_CSS_HEADER_VERSION=4.0.1`
- `GENERATED_CSS_HEADER_GENERATED_AT=2026-09-29 15:56:24`
- Four agreeing generated outputs: `automatic-variables.css`, `automatic.css`, `automatic-core-for-block-editor.css`, and `automatic-core-for-iframe-editor.css`.

## Version evidence

The owner-controlled installation identifies itself as Automatic.css version
`4.0.1`. Its plugin metadata is identified by the path, line, and SHA-256 in
the source identity section. The generated variables stylesheet header also
identifies version `4.0.1` and the generation time recorded above.

## Feature-state evidence

`GRID_VARIABLES_ENABLED=YES`

`GRID_VARIABLES_SETTING=option-grid-variables=on`

`GRID_VARIABLES_SETTING_EVIDENCE=app/sql/local.sql`

`GRID_VARIABLES_SETTING_SHA256=78aa02fe494dd5e07e46e09323c0328e68a5cbc08902a08c0b0b61a158e5bef7`

The setting value is recorded without publishing database contents.

## Resolved structural-grid values

| Variable | Exact resolved value | Definitions | Unique values | Result |
|---|---|---:|---:|---|
| `--grid-1` | `repeat(1, minmax(0, 1fr))` | 4 | 1 | PROVEN / control match |
| `--grid-2` | `repeat(2, minmax(0, 1fr))` | 4 | 1 | PROVEN |
| `--grid-3-2` | `minmax(0, 3fr) minmax(0, 2fr)` | 4 | 1 | PROVEN |

## Ambiguity/duplicate verification

Each value appears in all four named generated CSS outputs. Each variable has
four definitions and one unique value across those outputs.

`FORMULA_INFERENCE_USED=NO`

`AUTHORITY_AMBIGUITY=NONE`

## Control comparison

The captured ACSS 4.0.1 value for `--grid-1`,
`repeat(1, minmax(0, 1fr))`, exactly matches the existing LiveFrames structural
authority value for `--grid-1`. This confirms that the captured values use the
same structural-variable contract already represented in LiveFrames.

## Provenance boundary

This document publishes only the three owner-cleared structural-grid
interoperability facts and minimum verification metadata. It does not
redistribute Automatic.css source code, generated stylesheets, configuration
exports, or the broader Automatic.css research corpus. The broader
Automatic.css redistribution status remains unresolved.

The underlying plugin and generated stylesheet artifacts remain
private/reference evidence. No absolute local filesystem paths, stylesheet
content beyond the three resolved values, configuration exports, database
contents, unrelated variables, or license conclusions are included.

## Downstream authorization

After this PR merges:

```text
D0E1_TECHNICAL_EVIDENCE=PROVEN
D0E1_PUBLICATION_CLEARANCE=SCOPED_APPROVED
R1_CAN_RESUME=YES_AFTER_THIS_PR_MERGES
D1_AUTHORIZED=NO
```

While this PR is open, R1 remains paused. R1 may resume only after the PR
merges. D1 remains unauthorized.
