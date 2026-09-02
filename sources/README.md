# Source material

The intended public boundary for `sources/` is material explicitly approved
for repository distribution under
[`docs/04_SOURCE_AND_PROVENANCE.md`](../docs/04_SOURCE_AND_PROVENANCE.md).
Existing contents are historical public material; their location does not
prove redistribution permission. New source payloads with unresolved
redistribution status must not be added here.

This directory currently preserves the supplied standalone HTML/CSS/JS
experiments and the Bricks export. They are source/intake evidence, not code
that the applications execute. Imported JavaScript is never executed as part
of source inspection. Use the `imports/` and `fixtures/` contracts before
promoting any source into a later conversion pipeline.

`sources/work/` contains deterministic derived conversion/compiler artifacts.
Derived output retains upstream provenance and does not independently become
approved for public redistribution.
