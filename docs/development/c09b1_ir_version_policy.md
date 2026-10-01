# C09B1 Design IR version policy

## 1. Accepted base

This authority is based on the exact main accepted after C-09B.

| Item | Accepted value |
| --- | --- |
| Repository | JCSchoeman96/LiveFrames |
| Main commit | 4ae4ccb10613ad4d8a920d460706a6eca7ba8e1c |
| Main tree | fd0452fd1d73ecfe65c807bebb230c7809d4b8bd |
| Merged PR | #111, C-09B: define frontend binding authority |
| Approved PR head | 622478c8785897e3bd6ba6ccc90055ab30142382 |
| Post-merge exact-main CI | 36820652988, completed / success on the accepted main commit |

## 2. Authority inputs and repository conventions

This decision reconciles:

- docs/03_DESIGN_IR_SPEC.md
- docs/00_LIVEFRAMES_MASTER_SPEC.md
- docs/development/c09b_frontend_binding_authority.md
- apps/live_frames/lib/live_frames/ir/design_document.ex
- apps/live_frames/lib/live_frames/ir.ex
- apps/live_frames/lib/live_frames/ir/serializer.ex
- apps/live_frames/lib/live_frames/ir/validation.ex
- apps/live_frames/lib/live_frames/fidelity/document_loader.ex

The repository also has CatalogueItem SemVer in docs/24 and a Catalogue
manifest schema migration contract in docs/23 and
apps/live_frames/lib/live_frames/catalogue/migration.ex. Those rules apply to
Catalogue releases and manifest maps. They do not define Design IR versions.
The master specification's Phase 11 SemVer item concerns package release
readiness. Package versions, CatalogueItem release versions, manifest schema
versions, adapter versions, token-set versions, and Design IR versions remain
separate authorities.

The Catalogue migration code provides a useful implementation precedent for
explicit, deterministic map transformations with explicit source and target
versions. C09B1 does not adopt its Catalogue version numbers or release
classification.

An earlier C-09A note listed 1.1.0 as one possible successor. It did not
establish a version rule or select a version. C-09B later froze a different
frontend contract and left its number undecided. This document resolves that
open decision.

## 3. Current 1.0.0 contract

Design IR 1.0.0 is the only implemented IR version. DesignDocument owns the
current version string, LiveFrames.IR.current_ir_version/0 delegates to it,
and the serializer emits it in the JSON root.

~~~text
CURRENT_IR_VERSION = 1.0.0
~~~

The 1.0.0 root contains ir_version, source_metadata, token_set, root_nodes,
assets, interactions, diagnostics, and provenance. DesignNode has its current
fields and remains unchanged under C-09B. The canonical spec requires a new
IR version and an explicit migration decision when required fields, field
meaning, validation rules, or serialized shape change.

The current validator compares ir_version with exactly
DesignDocument.current_ir_version/0. A different non-empty string is rejected
as unsupported. This is an observed dispatch rule. It does not, by itself,
prove that two document shapes have incompatible meanings.

The current serializer emits a fixed root shape and sorts object keys. The
current fidelity loader does not decode interactions from JSON and initializes
the interaction registry as empty. It also has no fields for the C-09B
registries. C-09B records the interaction round-trip gap as known evidence.
The C-09C1 gate below requires the successor migration and loader to preserve
all existing registries; it must not route valid v1 maps through the lossy
current loader before migration.

Repository search found no adopted Design IR PATCH, MINOR, or MAJOR rule and
no existing Design IR migration implementation. Unknown versions are rejected
by the current validator. No unsupported version is treated as current.

## 4. C-09B successor delta

C-09B requires two first-class root registries in the successor contract:

- collection_bindings
- value_bindings

Both are required root fields. DesignNode remains unchanged. The registries
carry frontend repetition and caller-supplied value semantics, with node and
registry reference checks, nested-collection graph checks, and typed binding
invariants.

C-09B rejects using content, attributes, Interaction, AssetReference, or
SourceTrace-only records to represent these meanings. Existing root fields
retain their 1.0.0 meanings. A successor can represent every meaning that 1.0.0
represents, but a non-empty binding registry adds meaning that 1.0.0 cannot
store.

## 5. Compatibility dimensions

Version rejection and semantic incompatibility are separate findings. The
current exact-version check rejects every version other than 1.0.0. That fact
alone does not make an additive change semantically breaking. Classification
must also examine the document shape, accepted values, meanings, validation,
references, and whether a previous version can preserve the data.

In this policy, a document is valid when it satisfies the authorized contract.
Implementation acceptance is only observed runtime behavior. A bug can make
the implementation accept a document that the contract defines as invalid.

| Dimension | Meaning for Design IR |
| --- | --- |
| Reader compatibility | Whether a reader can validate and consume a serialized artifact without first transforming its document shape. A version-string rejection is reported separately from a shape or meaning failure. |
| Writer compatibility | Whether a writer can produce the new capability while emitting a valid artifact under the previous version. A writer must not drop meaning just to retain an older version string. |
| Migration compatibility | Whether an explicit transformation can make an older artifact valid under the newer contract while preserving all meanings represented by the older artifact. |
| Feature compatibility | Whether the newer contract still represents every older meaning without redefining it. |
| Reverse compatibility | Whether every newer artifact can be converted to the older contract without losing consumer-observable meaning. |

Lossless downgrade means preservation of consumer-observable meaning, not
byte-for-byte JSON identity. A field can be discarded on downgrade only when
its contract explicitly marks it as advisory and semantically discardable.

## 6. Serialized-contract SemVer principles

Design IR SemVer versions persisted JSON interchange semantics. It does not
version the Mix package API. Apply the class that covers the largest impact of
the change: PATCH, then MINOR, then MAJOR, with MAJOR taking precedence when
any major condition applies.

Version increments use one exact step:

| Class | Increment |
| --- | --- |
| PATCH | Keep major and minor; add one to patch. |
| MINOR | Keep major; add one to minor and set patch to zero. |
| MAJOR | Add one to major; set minor and patch to zero. |

The compatibility direction for PATCH and MINOR is backward reading: a newer
reader in the same major line accepts earlier compatible documents without a
document rewrite or explicit migration. An older reader is not promised to
accept a later patch or minor artifact. This avoids claiming forward-reading
behavior that the current exact-version validator does not provide. Before a
PATCH or MINOR release can ship, the reader must support the earlier versions
that its compatibility class promises. The current validator does not yet do
this.

A MAJOR version starts a different document contract. The new reader accepts
an older major only through an explicit, named migration path. It does not
guess, silently reinterpret, or validate multiple shapes under one version.

## 7. PATCH rule

Use PATCH only when the accepted serialized shape and semantic contract stay
the same. The change must not alter field meanings, documents accepted by the
authorized contract, reference rules, or the serialized output defined by the
contract, other than the version string for the patch release.

Examples include a documentation clarification that does not change the
contract and an implementation bug fix that restores the already-authorized
contract. If the contract requires a non-empty node_id but a validator bug
accepts an empty value, fixing the validator to reject that value is PATCH.
Likewise, if the contract defines serializer output A but an implementation
bug emits B, restoring A is PATCH even though the observed output changes.

Implementation acceptance does not make a contract-invalid document valid.
Rejecting such a document after a bug fix is therefore not a contract change.
By contrast, if a new authorized contract rejects a document that was valid
under the previous authorized contract, that is a stricter validation rule
and cannot be PATCH. Under this policy it is normally MAJOR, especially when
the prior artifact needs repair or migration.

A reader for the new patch version must continue to read earlier patch
artifacts in the same major and minor line without migration. Existing older
readers may reject the new version string. That dispatch rejection alone does
not make the underlying contract change major.

## 8. MINOR rule

Use MINOR only for a backward-compatible addition within the same major line.
Every document valid under an earlier minor or patch version must remain valid
under the new reader without a structural rewrite or explicit migration.
Existing fields retain their meaning, all formerly valid values remain valid,
and validation does not become stricter.

New serialized fields must be optional, with a specified default that
preserves the older document's meaning when omitted. A field required to
appear in the serialized document is MAJOR even if a migration can supply a
default. New metadata must be explicitly advisory if an older contract cannot
retain it on downgrade. A new semantic registry is MAJOR when non-empty
records add meaning that the previous contract cannot preserve.
An enum addition is MINOR only when its new values are advisory and can be
dropped on downgrade without changing consumer-observable meaning. A new
semantic enum value that the previous contract cannot represent is MAJOR.
The current enums are closed-world, so adding a member is MAJOR unless a
separate authority changes the enum contract and proves lossless compatibility.

MINOR does not promise that a reader for 1.x accepts a later 1.y document.
The promise runs in the other direction: an updated reader accepts earlier
same-major artifacts. The current exact-version validator must be replaced or
extended before a minor release can satisfy this rule. A reader that still
compares only with current_ir_version/0 cannot claim MINOR compatibility.

## 9. MAJOR rule

Use MAJOR if any of these conditions holds:

- a previously valid document needs a structural migration before the new
  validator can accept it;
- the new contract adds a required serialized field that older documents do
  not contain;
- an existing field is removed, renamed, or changes meaning;
- an enum value or other document value valid under the previous authorized
  contract becomes invalid;
- validation adds a required cross-reference or invariant that rejects
  documents valid under the previous authorized contract;
- a new required semantic value cannot be expressed by the previous contract;
- a non-empty new capability cannot be downgraded without losing
  consumer-observable meaning.

An exact version-string rejection by an old reader is not sufficient by
itself. A MAJOR classification must be supported by a contract break such as
the conditions above. Conversely, unchanged meanings in old fields do not
make a change MINOR when new required structure or non-downgradable meaning is
added.

## 10. The 1.1.0 case

The case for 1.1.0 has real support:

- old root and node meanings remain unchanged;
- a deterministic migration can add empty registries;
- the new feature is additive;
- assets, interactions, token_set, diagnostics, provenance, and root_nodes
  remain representable;
- empty registries preserve the behavior of an old document.

Those facts establish feature compatibility and make the structural migration
simple. They do not meet this policy's MINOR rule. C-09B makes both new root
fields required, so every valid v1 document needs a structural migration
before successor validation. A non-empty binding registry also carries
frontend meaning that cannot be represented or preserved in 1.0.0. The
existing exact-version reader rejects the successor string, and the current
loader would discard registry values if they were emitted under 1.0.0. The
version-string rejection is not the deciding semantic break; required shape,
migration, and non-lossless downgrade are.

## 11. The 2.0.0 case

The case for 2.0.0 matches the MAJOR rule:

- the serialized root shape changes with two new required fields;
- v1 artifacts require an explicit migration before successor validation;
- old readers cannot consume the successor directly under the current exact
  version check;
- writers cannot truthfully emit non-empty bindings as 1.0.0;
- a non-empty binding registry cannot be removed on downgrade without losing
  frontend repetition or value-binding meaning;
- validation adds typed record, node-reference, collection-reference, and
  acyclic nesting requirements.

The successor still preserves every v1 meaning. That fact supports the
migration path, but it does not cancel the incompatible serialized contract.

## 12. Final successor selection

The serialized-contract rule above was derived before applying it to the
C-09B delta. Required new root fields make old artifacts invalid under the
successor validator without migration. Non-empty successor registries carry
meaning that v1 cannot preserve on downgrade. The successor is therefore a
MAJOR change.

~~~text
TARGET_IR_VERSION = 2.0.0
VERSION_CHANGE_CLASS = major
VERSIONING_REASON = Required root registries require structural v1 migration, and non-empty bindings cannot be downgraded without semantic loss.
~~~

SUCCESSOR_DELTA_CLASSIFICATION: MAJOR serialized-contract change with
additive feature semantics and stronger validation/reference invariants.

## 13. Migration implications

Every 1.0.0 artifact requires an explicit 1.0.0 to 2.0.0 migration before
successor validation. The structural transform must:

1. preserve every v1 field and its existing meaning;
2. set the target version;
3. add collection_bindings as an empty object;
4. add value_bindings as an empty object; and
5. record source version, target version, migration kind structural, and
   frontend_semantics_recovered false in provenance.

This transformation preserves all semantics already represented by a valid
v1 artifact. It cannot recover repetition or value-binding semantics absent
from v1. Recovery requires original Bricks or Frames source, a successor
adapter, and successor IR. The migration must not infer bindings from
SourceTrace.

Repository evidence shows that the current fidelity loader drops interactions.
That is a known implementation gap, also recorded by C-09B. It does not make a
raw-map structural transform impossible, but C-09C1 must preserve the
interactions registry when it builds and validates the successor document.
The migration must run on the decoded v1 map before any loader that drops
fields. C-09C1 must prove round-trip preservation of every v1 root field and
the new registries before claiming lossless v1-to-successor migration.

Lossless v1-to-successor migration is YES for existing represented semantics,
subject to that C-09C1 loader gate. Lossless successor-to-v1 downgrade is NO
for documents with non-empty binding registries. A document with both
registries empty may be projected to v1 if every other field remains
representable, but this is not a general downgrade guarantee.

Migration is explicit, deterministic, linear in document size, and suitable
for a map transform or streaming transform where practical. It performs no
source re-fetch, backend query, runtime resolution, or inferred semantic
recovery. Do not build a generic version-conversion framework for this first
route.

## 14. Read and write support policy

| Support decision | Policy for the first successor implementation |
| --- | --- |
| V1_READ_SUPPORT | Yes, through explicit 1.0.0 to 2.0.0 migration only. Do not validate v1 directly as a 2.0.0 document. |
| V1_WRITE_SUPPORT | No. All new serialized documents use the successor version. |
| SUCCESSOR_READ_SUPPORT | Yes, direct read and validation for 2.0.0 after migration dispatch. Unknown versions fail closed. |
| SUCCESSOR_WRITE_SUPPORT | Yes, write 2.0.0 only. |

The reader path is: decode untrusted JSON to a map, inspect its exact version,
run the explicit migration for the supported v1 route, decode the migrated
successor map, then validate as the successor. Do not accept two root shapes
under 1.0.0. Do not infer a migration target from an unknown or malformed
version.

## 15. Canonical spec transition timing

This authority fixes the future successor number. It does not make the
successor current in production. Production and docs/03_DESIGN_IR_SPEC.md
remain at 1.0.0 until the successor implementation lands. The canonical spec
must move to 2.0.0 in the same implementation slice that adds the new schema,
validator, serializer, loader, and migration path.

## 16. Examples for future IR changes

The matrix applies the rules above. "Old readers" means readers built for
the earlier exact document version. Their current version-string rejection
is shown separately from whether the document meanings are compatible.

| Change type | Old docs remain valid? | Migration required? | Old readers accept new docs? | Existing meaning changed? | Lossless downgrade? | Version bump |
| --- | --- | --- | --- | --- | --- | --- |
| Documentation-only clarification | Yes | No | Yes if the artifact version stays unchanged; otherwise exact old readers may reject the patch string | No | Yes | PATCH for a versioned IR correction; prose-only clarification need not change the IR version |
| Serializer bug fix restoring the authorized contract | Yes | No | Yes if the version string stays unchanged; otherwise old exact readers may reject the patch string | No | Yes | PATCH |
| New optional advisory metadata field with a discardable meaning | Yes | No | No direct later-version support under the exact reader | No | Yes, semantically | MINOR |
| New optional registry carrying frontend semantics | Yes if absent in older docs | No for absent registry | No direct later-version support under the exact reader | Adds new meaning | No when non-empty | MAJOR |
| New required root field | No, unless migration supplies a defined default | Yes | No | Not necessarily in old fields | No in general | MAJOR |
| New enum member in a closed-world enum | Yes for documents using existing members | No for those documents | No direct later-version support under the exact reader | No for existing members | No when the new semantic member is used | MAJOR |
| Removal of an enum member | No for documents using the removed member | Yes for affected documents | No direct later-version support under the exact reader | Accepted domain narrows | No unless a semantics-preserving mapping exists | MAJOR |
| Field meaning change | No as a semantic artifact | Yes, with an explicit value conversion decision | No; old reader would apply the old meaning | Yes | No in general | MAJOR |
| New validation rule rejecting documents valid under the previous authorized contract | No for affected documents | Yes, repair or migration required | No direct later-version support under the exact reader | Validation contract tightens | Not generally | MAJOR |
| New required cross-reference invariant | No for documents that violate it | Yes for affected documents | No direct later-version support under the exact reader | Reference contract tightens | Not generally | MAJOR |
| Field removal | No until removed data is handled | Yes when the old field is present | No direct later-version support under the exact reader | Meaning is removed unless transferred | No in general | MAJOR |
| Field rename | No until the old key is mapped | Yes | No direct later-version support under the exact reader | No if only the name changes | Yes if migration maps it exactly | MAJOR |

A new enum member or registry may be MINOR only after separate authority
defines any new values as optional and discardable, proves that earlier
documents validate without migration, and proves no earlier meaning or
accepted value is lost. Opening an enum alone does not make new members MINOR.
Do not assume an additive syntax change is a compatible artifact change.

## 17. Non-goals

C-09B1 does not implement the successor IR, CollectionBinding, ValueBinding,
serializers, validators, loaders, adapters, generators, HEEx, LiveView
components, runtime value resolution, query execution, or production code.
It does not change C-09B, docs/03_DESIGN_IR_SPEC.md, or the current 1.0.0
contract. It adds no expression execution, dynamic code loading, database
access, Redis access, or network access.

~~~text
RUNTIME_DB_CALLS = 0
RUNTIME_REDIS_CALLS = 0
RUNTIME_NETWORK_CALLS = 0
~~~

Unknown, malformed, or unsupported versions fail closed. Source expressions
remain inert data. The migration does not execute them.

## 18. C-09C1 implementation gate

C-09C1 may begin only as the separately authorized successor implementation
slice. Before it can be considered complete, it must:

- use 2.0.0 for the successor and preserve the C-09B collection_bindings and
  value_bindings architecture without adding node reference fields;
- update the canonical Design IR spec in the same implementation slice;
- migrate exact 1.0.0 maps explicitly before successor decoding and validation;
- preserve all v1 root fields, including interactions, diagnostics, and
  provenance, and round-trip both new registries without loss;
- enforce the C-09B registry, binding, node-reference, collection-reference,
  and acyclic nesting invariants;
- reject unknown and malformed versions without guessing or interpreting
  them as the current version;
- write new documents as 2.0.0 only;
- keep migration deterministic, linear in input size, side-effect-free, and
  free of source re-fetches, backend queries, database, Redis, and network
  calls; and
- avoid a generic multi-version runtime framework beyond the explicit 1.0.0
  to 2.0.0 route.

C-09C1 has not started in this authority change.
