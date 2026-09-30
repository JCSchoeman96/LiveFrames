# C-08B2A icon asset authority

## 1. Accepted base

| Fact | Accepted value |
| --- | --- |
| Repository | `JCSchoeman96/LiveFrames` |
| Base commit | `4e4a0c01fd88c6edb2a28b5952e0bfe7cac62901` |
| Base tree | `e41cf0484d9411c4de4a6d4284e4c5a02b003410` |
| Exact-main CI | Run `36715506042`, completed / success, `headSha` matches the base commit |
| Initial worktree | Clean |
| Branch | `docs/c08b2a-icon-asset-authority` |

The local preflight matched all pinned values. The canonical export gate also matched: 34 regular files after excluding `Archive.tar.gz`, with digest `074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e`.

## 2. Authority inputs

Read before examining the S1 asset:

- `docs/development/c08b1_icon_source_contract.md`
- `docs/04_SOURCE_AND_PROVENANCE.md`
- `docs/18_PHASE_5_HARDENING_AND_ACCEPTANCE.md`

The C-08B1/C-08B2 facts remain locked for this slice. The audit covers only the 42 standalone S1 icon elements and their one distinct reference. It does not audit S2 or Themify.

The provenance policy requires explicit `redistribution_status = "approved"` before new third-party bytes enter public fixtures or sources. Possession, hashing, conversion, or repository presence does not supply that authority.

## 3. S1 reference identity

All 42 standalone icon elements use `bricks.icon.library.svg.asset_ref`. Their export values share one URL, one `full` value, and one filesystem path. `url` and `full` are equal.

| Reference fact | Value |
| --- | --- |
| Unique S1 reference count | 1 |
| URL SHA-256 | `2fa7f5b3fadaf5cf777b01f1c33b5033b9044c95a6d443c17bb14af3a5e356df` |
| Full SHA-256 | `2fa7f5b3fadaf5cf777b01f1c33b5033b9044c95a6d443c17bb14af3a5e356df` |
| Path SHA-256 | `90b85b0124baa43e498ca4b27d879226db12c08f7bc611bbe0ea4bb3b355e7ad` |
| Basename | `placeholder-svg.svg` |
| Extension | `.svg` |
| `isPlaceholder` | `true` |

The raw URL and absolute path are omitted. The basename is generic and does not identify a customer.

## 4. Trusted filesystem boundary

The exported path was treated as untrusted input. `realpath` resolved the expected LocalWP `wp-content` root and the candidate. The exported candidate equals its `realpath` result and has file type `regular file`. It remained inside the expected root, with no path or symlink escape.

The resolved relative suffix is `themes/bricks/assets/images/placeholder-svg.svg`. No absolute private filesystem path is recorded here.

## 5. Asset existence result

`ASSET_BYTE_STATUS = FOUND`

The exact exported filesystem reference exists inside the expected root. No similarly named substitute was used.

## 6. Raw byte identity

| Fact | Value |
| --- | --- |
| Byte size | `591` |
| Raw byte SHA-256 | `0b920401e4b8f4e39bbb927e390ea8728d4e929dd6a102f84d01ff867f0a144f` |
| `file` type | `SVG Scalable Vector Graphics image` |
| Extension | `.svg` |

The hash covers the raw file bytes. No XML formatting, whitespace, attribute, or geometry normalization was performed first.

## 7. Reference-to-byte correlation

The exported filesystem path resolves to the located file whose raw-byte SHA-256 is recorded above. The filesystem basename and the URL path basename both equal `placeholder-svg.svg`. The URL and `full` values are identical and their reference hashes remain separate from the byte hash.

This establishes the path-to-local-byte relationship. The URL was not fetched, so its HTTP response was not independently compared byte-for-byte. The local Bricks builder code constructs its SVG template placeholder path from the same theme asset directory and basename.

## 8. Origin classification

**Origin type:** Bricks theme asset, identified locally as the SVG template placeholder.

The local theme's `includes/builder.php` names `placeholder-svg.svg` in its `get_template_placeholder_image` helper when SVG placeholders are requested. The export also sets `isPlaceholder` to `true`. Local theme metadata identifies the installation as Bricks version `2.4.2`; the export format identifies Bricks `2.3.1`. This does not establish that the asset bytes were introduced in a particular release or that the two versions are interchangeable.

Directory location and package metadata do not prove ownership of this exact file.

## 9. Provenance facts

| Required fact | Recorded value |
| --- | --- |
| `source_name` | Bricks SVG template placeholder, `placeholder-svg.svg` |
| `source_group` | Bricks theme placeholder asset |
| `source_system` | Bricks theme |
| `source_version` | `2.4.2` in local theme metadata; exported format says `2.3.1`; asset-version relationship unknown |
| `origin_type` | Theme asset; Bricks builder code identifies the filename as its SVG template placeholder |
| `vendor_author` | `unknown` for this exact asset. Theme metadata lists Bricks as package author. |
| `license_status` | `unknown` for this exact asset. Theme `readme.txt` declares GPLv2 for the theme package, but no evidence ties that declaration to this file. |
| `internal_use_status` | `unknown` |
| `internal_use_scope` | `unknown` |
| `redistribution_status` | `unknown` |
| `evidence_refs` | Canonical S1 export string hashes; local Bricks theme `readme.txt`, `style.css`, `license.txt`, and `includes/builder.php`; raw-byte SHA-256 above; canonical provenance policy in `docs/04_SOURCE_AND_PROVENANCE.md` |
| `raw_byte_sha256` | `0b920401e4b8f4e39bbb927e390ea8728d4e929dd6a102f84d01ff867f0a144f` |
| `publication_state` | `classified`; not `public_safe` |

The asset contains no embedded license, copyright, author, creator, rights, or metadata marker. A targeted search found no repository or local-theme record of this exact byte hash. The theme package's GPLv2 metadata is recorded as evidence only; this document does not determine whether it applies to the asset or to LiveFrames redistribution.
The canonical provenance register was not changed. It reports repository evidence, while these bytes remain outside the repository in the private LocalWP theme tree. This document records the exact local asset evidence without changing the register scope or broader Frames provenance.

## 10. Redistribution and publication gate

```text
redistribution_status = unknown
PUBLIC_PACKAGING_AUTHORIZED = no
HUMAN_GOVERNANCE_REQUIRED = yes
```

The positive public packaging guard is not met. The local theme license metadata, local possession, byte identity, source code reference, and successful XML parse do not establish asset-specific redistribution authority. No legal conclusion is made.

Internal-use authority is also unknown, so the private-asset candidate guard is not met either.

## 11. SVG structural inventory

A deterministic, read-only Python standard-library XML inventory parsed the local bytes without following external resources. The raw file contains no DOCTYPE or ENTITY declaration.

| Inventory | Observed value |
| --- | --- |
| Parse status | Parsed |
| Root element | `svg` |
| Namespace | `http://www.w3.org/2000/svg` |
| Element counts | `svg: 1`, `path: 3` |
| Attribute counts | `d: 3`, `fill: 1`, `stroke: 1`, `stroke-linecap: 1`, `stroke-linejoin: 1`, `stroke-width: 3`, `viewBox: 1` |

Two `path d` values exceed 80 characters. Their categories, lengths, and hashes are:

| Category | Length | SHA-256 |
| --- | ---: | --- |
| Path geometry data | 105 | `83b375f5631a77982849a34eb7beec33f97f1e2b453abab50c9be6dc48011e13` |
| Path geometry data | 179 | `bf83a8fac4bbb67e96210611c2810069f1d42fd54fa50b89b862a289d32016ef` |

The shorter third `d` value is not reproduced. No path geometry or complete SVG markup is included in this document.

## 12. Risky, active, and external feature inventory

| Feature | Present |
| --- | --- |
| `<script>` | No |
| `<foreignObject>` | No |
| `<style>` element | No |
| `<use>` | No |
| `<image>` | No |
| `<a>` | No |
| DOCTYPE | No |
| ENTITY declaration | No |
| Event attributes (`on*`) | No |
| `href` / `xlink:href` | No |
| `javascript:` / `data:` / `http:` / `https:` | No |
| `url(...)` | No |
| CSS `style` attributes | No |
| `id` / `class` | No |
| `mask` / `clipPath` / `filter` | No |
| Gradient elements | No |
| `defs` | No |
| Animation elements (`animate`, `animateTransform`, `set`) | No |
| Active content | No |
| External references | No |

No external resource was resolved or fetched during this inventory.

## 13. Future sanitizer allowlist

**Observed classification: `SIMPLE_STATIC_GEOMETRY`.** This classification means the parsed file contains static SVG geometry with no active content, internal references, external references, CSS, or complex presentation features.

The minimum source-specific allowlist supported by this file is:

- Elements: `svg`, `path`
- Attributes: `viewBox`, `d`, `fill`, `stroke`, `stroke-linecap`, `stroke-linejoin`, `stroke-width`
- Namespace: the SVG namespace on the root element

The future validator should reject, for this contract, active and external behavior that the source does not use: `<script>`, `<foreignObject>`, event attributes, animation elements, all `href` and `xlink:href`, external schemes, and `url(...)`. It should also reject unobserved style blocks or attributes, `<use>`, `<image>`, `<a>`, IDs, classes, masks, clipping paths, filters, gradients, and `defs`. DOCTYPE and ENTITY declarations should be rejected before parsing. These rules describe a future bounded validator; no sanitizer is implemented here.

## 14. Reference hashes and byte hash

The reference hashes identify two string identities: URL and `full` share one value, and the path is distinct.

```text
URL and `full` string hash: 2fa7f5b3fadaf5cf777b01f1c33b5033b9044c95a6d443c17bb14af3a5e356df
Filesystem path string hash: 90b85b0124baa43e498ca4b27d879226db12c08f7bc611bbe0ea4bb3b355e7ad
```

The raw-byte hash identifies the located SVG file:

```text
Raw asset-byte SHA-256: 0b920401e4b8f4e39bbb927e390ea8728d4e929dd6a102f84d01ff867f0a144f
```

These facts are not interchangeable. This audit proves that the exported path resolves to those local bytes. It does not fetch the URL response. A future authority record must bind the reference-hash tuple to an approved byte hash only when its evidence records the relationship and the required use permissions.

## 15. Packaging options

| Option | Source fidelity | Provenance and redistribution | Reproducibility and runtime | Security and repository fit |
| --- | --- | --- | --- | --- |
| A. Repository-owned static asset | Could preserve these exact local bytes if the URL/path relationship is accepted. The asset is marked as a placeholder, not a verified project glyph. | Requires explicit redistribution approval for this exact asset. That evidence is absent. | Bundled bytes would be reproducible and need no Bricks, ACSS, LocalWP, or network runtime. | A narrow `svg`/`path` validator could cover the observed structure. Public packaging is not authorized. |
| B. Private project asset authority | Could preserve exact bytes if an authorized caller supplies the recorded hash. | Requires explicit internal-use authority. That evidence is absent. | A caller-supplied file could remove runtime dependence on Bricks, LocalWP, and network access. Reproducibility would require the caller to supply the same approved hash. | Public code could validate an input hash and structure without containing the bytes. This option is not authorized yet. |
| C. Owner-supplied replacement | Creates a new asset identity. It is not byte-fidelity-equivalent unless separately proven. | Requires owner authority covering the replacement and its intended distribution. | A committed or supplied replacement can be deterministic once its bytes and hash are fixed; no Bricks runtime is needed. | It needs its own structure review and bounded validator. Public placement depends on its authority. |
| D. Leave unresolved | The icon remains unresolved; no glyph is emitted from these bytes. | Makes no ownership or redistribution claim. | The unresolved result is deterministic and has no runtime asset dependency. | Keeps unapproved bytes out of public repository paths. |

## 16. Recommended packaging model

Choose Option D for the current evidence state.

- **Source fidelity:** The export points to a Bricks template placeholder and sets `isPlaceholder` to true. The local path resolves, but no browser comparison proves what the source rendered. Leaving it unresolved avoids claiming that the placeholder is the intended final glyph.
- **Licensing and provenance:** Package metadata says GPLv2, but no evidence identifies the license or author of this exact SVG or grants LiveFrames redistribution. Public packaging is not authorized.
- **Reproducibility:** The local bytes have a stable SHA-256. They remain in the private LocalWP installation, so another environment cannot reproduce them from the public repository.
- **Runtime:** The target remains free of Bricks, ACSS, LocalWP, and network dependencies. A later caller-supplied model could meet that target if internal-use authority is recorded.
- **Security:** The observed SVG needs only `svg` and `path` elements and the listed presentation attributes. A future validator can stay deterministic and narrow, but it must still validate every input.
- **Public repository:** No SVG bytes may enter fixtures, sources, static assets, or test support until explicit asset-specific redistribution approval exists.

Revisit Option B only if internal-use authority is recorded. Revisit Option A only if explicit redistribution authority is recorded. An owner-authorized replacement would be a new asset identity under Option C.

## 17. Asset-authority lifecycle

```text
reference_discovered
→ local_reference_validated
→ bytes_located
→ bytes_identified
→ provenance_classified
→ security_profiled
→ packaging_review
```

| Transition | Guard | Result |
| --- | --- | --- |
| `reference_discovered` → `local_reference_validated` | Exact C-08B2 S1 reference; `realpath` remains inside expected local source root | Passed |
| `local_reference_validated` → `bytes_located` | Exact referenced file exists | Passed |
| `bytes_located` → `bytes_identified` | Bytes readable; raw SHA-256 computed | Passed |
| `bytes_identified` → `provenance_classified` | Known facts and explicit unknowns recorded | Passed |
| `provenance_classified` → `security_profiled` | SVG parsed read-only and feature inventory recorded | Passed |
| `security_profiled` → `packaging_review` | No known evidence facts omitted | Passed |
| `packaging_review` → `public_package_candidate` | `redistribution_status == "approved"` | Blocked: status is `unknown` |
| `packaging_review` → `private_asset_candidate` | Usable internally and explicit internal-use authority exists | Blocked: status is `unknown` |

Terminal outcomes are `public_package_candidate`, `private_asset_candidate`, `replacement_required`, `evidence_insufficient`, and `rejected_unsafe`. Current terminal outcome: `evidence_insufficient`. The SVG structure is bounded, so `rejected_unsafe` does not apply. The private candidate guard is not satisfied.

## 18. Unresolved gaps

- Asset-specific author, ownership, license scope, internal-use authority, and redistribution authority are unknown.
- The URL response was not fetched, so only the exact path-to-local-byte relationship is established.
- The export format says Bricks `2.3.1`, while local theme metadata says `2.4.2`; the version relationship for these bytes is unknown.
- The placeholder's appearance was not compared in a browser or against a source capture.
- No owner-authorized replacement has been provided.
- A future sanitizer has not been implemented or verified.

## 19. Exact next implementation scope

No renderer, sanitizer, or runtime asset loader is authorized by this evidence. The next step is a human governance decision for this exact asset or an owner-authorized replacement:

- If explicit public redistribution authority covers this exact file, review a later C-08B2B slice for validation, approved packaging, and a protected renderer.
- If only internal use is explicitly authorized, design a caller-supplied private asset authority before considering rendering.
- If an owner supplies a replacement, record it as a new asset identity and repeat the authority and structural review.

Until one of those evidence changes is recorded, keep the icon unresolved. C-08B3 is not started.

## 20. Explicit non-goals

- No production code or tests changed.
- No SVG bytes copied or committed.
- No renderer, sanitizer, or runtime asset loader implemented.
- No network request, URL fetch, WordPress mutation, or database write.
- No legal conclusion or unsupported ownership, license, internal-use, or redistribution fact.
- No substitute asset chosen because its name is similar.
- No S2/Themify audit, ACSS presentation work, or C-08B3 work.

## 21. Next branch

```text
NEXT_BRANCH: EVIDENCE_INSUFFICIENT
```

Ownership and use authority for the located bytes remain unresolved. The exact path-to-local-byte relationship and safe static structure are recorded, but neither public redistribution nor internal-use authority is established. No renderer work follows from this branch.
