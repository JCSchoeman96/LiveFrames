# Imports

`imports/` is mutable source intake. New source bundles enter `pending/`, move
through `approved/` after provenance review, and are either copied into safe
deterministic fixtures or moved to `processed/` / `rejected/`.

Do not treat files in this directory as runtime application code. A structured
bundle follows the contract in Section 10 of the master spec and includes a
`SOURCE.md` provenance record.
