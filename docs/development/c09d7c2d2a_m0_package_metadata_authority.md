# C09D7-C2D2A-M0: LiveFrames package metadata authority

**Status:** Owner-approved package policy. Documentation authority only.

**Authority base:** `f5dcaf534db675b16fe1a4fa90e347cb96f42c40`, tree `443ca2e1e371ad05e0b0144b307860986629b849`.

This document records the owner's private/proprietary package policy and freezes the exact metadata and notice text for the later C2D2A package-boundary implementation. It does not resume that implementation or authorize package publication.

## Owner decision

The owner approved this package-policy direction:

```text
PACKAGE_LICENSE_POLICY=PRIVATE_PROPRIETARY
PUBLIC_OPEN_SOURCE_LICENSE_GRANTED=NO
PUBLIC_REDISTRIBUTION_GRANTED=NO
PUBLIC_PUBLICATION_GRANTED=NO
HEX_PUBLICATION_AUTHORIZED=NO
```

This decision applies to LiveFrames package policy. It does not establish copyright ownership, validate a licence, or clear third-party or source-derived material for redistribution or publication. Package metadata and source provenance remain separate authorities.

This decision is an explicit owner approval. It must not be inferred from the public GitHub repository, a Catalogue item's `APPROVED` state, the C1 consumer proof, prior C2D2 package work, or CTA provenance.

## Hex 2.5.1 build requirement

The stopped C2D2A implementation established this result:

```text
C2D2A_STOP=SCOPE_EXPANSION_REQUIRED
HEX_VERSION=2.5.1
HEX_BUILD_COMMAND=mix hex.build --unpack --output <temporary-directory>
HEX_FAILURE=Missing metadata fields: description, licenses, links
```

Hex 2.5.1 generated configuration documentation lists `description` as a project-level field. Its package-configuration section describes additional package metadata, including `licenses` and `links`, under the package config. Despite the documentation's optional/recommended framing for additional package metadata, the installed Hex 2.5.1 public-`hexpm` build path rejected the local package build while `description`, `licenses`, and `links` were absent. This records the exact observed build behavior; it is not a general Hex publication rule. Record the tooling difference as:

```text
HEX_BUILD_METADATA_REQUIRED_IN_INSTALLED_TOOLCHAIN=YES
HEX_DOCUMENTATION_AND_IMPLEMENTATION_BEHAVIOR_DIFFER=YES
```

The accepted package-boundary contract still requires the real `mix hex.build --unpack` check. Do not evade the metadata check by changing Hex versions, setting a fake organization, using empty values, skipping the Hex build, or constructing a separate tarball. See the [Hex build documentation](https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html) and the build/package/CI contract in [Catalogue architecture §11](../23_CATALOGUE_ARCHITECTURE.md).

## Frozen package metadata

The later `LiveFrames.MixProject.project/0` configuration must set this exact value:

```elixir
description: "Phoenix/LiveView design compiler and reusable UI-component library."
```

The later `LiveFrames.MixProject.package/0` configuration must set these exact values:

```elixir
licenses: ["LicenseRef-LiveFrames-Proprietary"],
links: %{
  "GitHub" => "https://github.com/JCSchoeman96/LiveFrames"
}
```

The link records the repository location only. It does not claim that LiveFrames has been published or that redistribution is permitted.

Freeze the custom identifier as:

```text
HEX_LICENSE_IDENTIFIER=LicenseRef-LiveFrames-Proprietary
```

`LicenseRef-LiveFrames-Proprietary` is the project-local identifier for the exact proprietary notice below. Hex accepts custom `LicenseRef-*` identifiers structurally; that acceptance does not validate or supply their legal meaning. This identifier is not an OSI-approved licence, an SPDX standard licence, or a grant of public use, redistribution, or publication rights.

Do not substitute another identifier, add multiple licence identifiers, or infer a public open-source licence.

## Frozen proprietary notice

The later C2D2A implementation must create `apps/live_frames/LICENSE-PROPRIETARY.txt` with exactly this content:

```text
LiveFrames Proprietary Notice

Copyright (c) LiveFrames rights holder. All rights reserved.

LiveFrames is proprietary software. This notice and the package metadata
identifier LicenseRef-LiveFrames-Proprietary do not themselves grant any
right to copy, modify, distribute, sublicense, publish, publicly release, or
otherwise make LiveFrames or its bundled source-derived material available to
third parties.

Any permission to use, copy, modify, distribute, publish, sublicense, or make
LiveFrames available must come from separate explicit written authorization
from the applicable rights holder.

This proprietary package policy does not establish or alter copyright
ownership, source provenance, licence validity, redistribution permission, or
publication clearance for third-party or source-derived material incorporated
into LiveFrames. Those matters remain governed by the project's separate
provenance and clearance authorities.
```

Do not paraphrase or extend this notice. Warranty, liability, patent, trademark, contributor, and governing-law terms are outside this authority.

## Future C2D2A package boundary

After this authority PR is independently reviewed and merged, the implementation may resume from the preserved stopped C2D2A worktree. It must not restart from scratch or broaden beyond these four files:

```text
.github/workflows/ci.yml
apps/live_frames/mix.exs
apps/live_frames/test/live_frames/styling/package_contract_test.exs
apps/live_frames/LICENSE-PROPRIETARY.txt
```

The package file list must contain all of these paths:

```text
lib
mix.exs
assets/css
priv/token_maps
priv/static/live_frames
priv/catalogue
LICENSE-PROPRIETARY.txt
```

The seven package entries preserve the source-package boundary in [Package and generator model](../16_PACKAGE_AND_GENERATOR_MODEL.md) and Catalogue architecture §11. The real unpacked-package proof must verify the proprietary notice file along with the canonical Catalogue JSON files and the existing required package roots. The previously observed package-contract test cycle remains evidence and does not need to be repeated in this M0 slice:

```text
TDD_PACKAGE_CONTRACT_RED=OBSERVED
PRIV_CATALOGUE_ASSERTION_GREEN_AFTER_MINIMAL_FIX=YES
```

This M0 document does not itself authorize resuming C2D2A. That implementation remains stopped until this authority PR is independently reviewed and merged.

## Publication and Catalogue boundaries

The later local `mix hex.build --unpack` is authorized only to inspect the actual package contents:

```text
mix hex.build=AUTHORIZED_LATER_FOR_LOCAL_BOUNDARY_PROOF
mix hex.publish=NOT_AUTHORIZED
HEX_CREDENTIALS=NOT_REQUIRED
HEX_PUBLIC_RELEASE=NOT_AUTHORIZED
PACKAGE_VERSION_BUMP=NOT_AUTHORIZED
GIT_TAG=NOT_AUTHORIZED
GITHUB_RELEASE=NOT_AUTHORIZED
```

A successful local build means only `LOCAL_PACKAGE_BUILD_SUCCEEDED`. It does not approve package publication, Catalogue release, or redistribution.

CTA Tango provenance remains governed by [Source and provenance](../04_SOURCE_AND_PROVENANCE.md):

```text
redistribution_status=unknown
publication_state=classified
clearance_evidence_refs=[]
CTA_PROVENANCE_MUTATED=NO
CTA_PROVENANCE_CLEARANCE_ESTABLISHED=NO
```

The package-policy decision does not alter those facts. The CTA Catalogue item remains `APPROVED`, and its distribution field remains absent:

```text
CATALOGUE_ID=live_frames.section.media_call_to_action
CATALOGUE_STATE=APPROVED
DISTRIBUTION_FIELD=ABSENT
```

No `distribution.library=supported` claim is authorized here. Library-capability evidence review remains blocked until the package boundary and current documentation truth are accepted and the evidence review is rerun. This document does not authorize C2D2B, C2D2R1, C2D3, a transition from `APPROVED` to `RELEASED`, package publication, or P10.

```text
C2D2A_M0=AUTHORIZED_DOCS_ONLY
C2D2A_IMPLEMENTATION_AUTHORIZED=NO
C2D2B_AUTHORIZED=NO
C2D2R1_AUTHORIZED=NO
C2D3_AUTHORIZED=NO
APPROVED_TO_RELEASED_AUTHORIZED=NO
PACKAGE_PUBLICATION_AUTHORIZED=NO
P10_AUTHORIZED=NO
```
