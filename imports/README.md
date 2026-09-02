# Imports

`imports/` is mutable source intake. New source bundles enter `pending/`, move
through `approved/` only after their provenance facts and scoped internal-use
authority are recorded, and are either copied into deterministic fixtures only
when the public-redistribution gate is satisfied or moved to `processed/` /
`rejected/`.

“Approved” in this intake flow does not mean approved for public
redistribution. Unknown redistribution remains unresolved and is insufficient
for new public `fixtures/` or `sources/` material. See the canonical
[`docs/04_SOURCE_AND_PROVENANCE.md`](../docs/04_SOURCE_AND_PROVENANCE.md)
policy.

Do not treat files in this directory as runtime application code. A structured
bundle follows the contract in Section 10 of the master spec and includes a
`SOURCE.md` provenance record.
