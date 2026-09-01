# Phase 5A Fidelity HEEx Generator Design

## Goal

Generate deterministic base-fidelity HEEx, CSS, and a truthful generation
manifest from validated Design IR `1.0.0` without parsing Bricks or Stage A.

## Design

`LiveFrames.Fidelity.generate/2` validates the supplied DesignDocument, builds
a private ordered render plan, and serializes a bundle containing HEEx, CSS,
and manifest data. The plan maps only the demonstrated semantic types, escapes
content through generated HEEx literals, preserves approved source classes,
resolves embedded TokenSet paths, and records unresolved or deferred evidence.

The generic fidelity core has no Automatic.css class knowledge. A narrow
`LiveFrames.Adapters.AutomaticCSS.FidelityResolver` supplies only the proven
`bg--ultra-dark`, `btn--primary`, and `btn--outline` declarations. Responsive
entries produce manifest evidence but no media queries. Unresolved images use
an explicit deterministic placeholder; unresolved variables and unitless
values are never guessed.

The preview app consumes one generated Hero template and stylesheet through a
small route. Generated artifacts are drift-tested byte-for-byte. No native
component API, Tailwind bridge, Storybook component, runtime state, or Phase 5B
responsive behavior is included.

## Verification

Tests cover validation, semantic mapping, safe content, source-class safety,
token and resolver mappings, gradient/custom CSS policy, unresolved evidence,
determinism, compilation, artifact drift, and the isolated base preview.
