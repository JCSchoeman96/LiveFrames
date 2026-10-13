# C09D7-C0 external consumer and Catalogue handoff authority

**Status:** C09D7-C0 authority only. The external consumer proof has not run. This document defines the later C1 proof and the Catalogue handoff boundary. It does not authorize C1 execution or Catalogue admission.

**Accepted baseline:**

    BASE_SHA=8563a9b5f93594b98c8367c1de21df9e82067fc7
    BASE_TREE=2963284a6ca7d7bb0268bbfe38f5dd8f0345bcf4
    BASE_MAIN_CI=38412095712
    BASE_MAIN_CI_RESULT=PASS

This authority resolves the roadmap STOP=CONSUMER_CONTRACT_UNDEFINED by defining the consumer contract. It does not claim that the consumer proof or any Catalogue transition occurred.

## 1. Authority and scope

Read this authority with the [Master Specification](../00_LIVEFRAMES_MASTER_SPEC.md), [source and provenance policy](../04_SOURCE_AND_PROVENANCE.md), [CSS and Tailwind strategy](../11_CSS_AND_TAILWIND_STRATEGY.md), [package and generator model](../16_PACKAGE_AND_GENERATOR_MODEL.md), [roadmap](../17_ROADMAP.md), [Catalogue architecture](../23_CATALOGUE_ARCHITECTURE.md), and [Catalogue versioning policy](../24_CATALOGUE_VERSIONING_POLICY.md). The accepted CTA authorities are [C09D7-A](c09d7a_cta_tango_component_review.md), [C09D7-B](c09d7b_cta_tango_ir4_reauthorization.md), and [native-generation authority](c09d6_native_generation_authority.md). Current implementation facts come from [the CTA component](../../apps/live_frames/lib/live_frames/components/sections/media_call_to_action.ex), [the CSS entry](../../apps/live_frames/assets/css/live_frames.css), [the CTA stylesheet](../../apps/live_frames/assets/css/components/sections/media_call_to_action.css), [the compiled stylesheet](../../apps/live_frames/priv/static/live_frames/css/live_frames.css), and [package configuration](../../apps/live_frames/mix.exs).

The documents agree on the boundary. The native CTA lifecycle is accepted, but an external consumer has not been proven. The package guide defines precompiled CSS as the primary consumer path and Tailwind v4 source integration as optional. Catalogue admission remains a separate, owner-authorized lifecycle action. Package publication, distribution support, provenance clearance, and P10 ejection remain separate decisions.

This slice changes documentation only. It does not execute C1, add a consumer application, admit CTA, change production code or package metadata, alter CI, publish a package, or start P10.

## 2. ConsumerProof lifecycle

The proof starts in DEFINED. Only the transitions below can advance it.

    DEFINED
      -> ENVIRONMENT_CREATED
      -> DEPENDENCY_RESOLVED
      -> COMPILED
      -> RUNTIME_VERIFIED
      -> PASSED

BLOCKED, FAILED, and PASSED are terminal states. A proof in a terminal state cannot advance. Repository tests, preview or Storybook tests, and successful individual commands do not establish a proof state by themselves.

| Transition | Guard | Effect | Required observable evidence |
| --- | --- | --- | --- |
| Start at DEFINED | This authority has passed independent review. A separate explicit owner authorization starts C1. | Open a new proof run. Do not alter LiveFrames or Catalogue state. | Record the authority revision, C1 authorization, and the accepted LiveFrames commit and tree selected for this run. |
| DEFINED to ENVIRONMENT_CREATED | Create a new Phoenix application with the exact generator command in section 3. The root must be outside the LiveFrames repository, every LiveFrames worktree, apps/live_frames_preview, fixtures, acss, and private_reference. Do not symlink or copy the preview application. Inspect the generated host to verify that Ecto, Tailwind, and dependency installation are absent. | Create only the external host skeleton and test-owned placeholder content. Do not install or resolve dependencies. | Record `ELIXIR_VERSION=`, `OTP_VERSION=`, `MIX_VERSION=`, `PHX_NEW_VERSION=`, `PHX_NEW_COMMAND=`, and `HOST_ROOT=`. Also record `PHX_NEW_PROFILE_MATCH=YES`, `ECTO_GENERATED=NO`, `TAILWIND_GENERATED=NO`, `DEPENDENCIES_INSTALLED_DURING_GENERATION=NO`, `ECTO_PRESENT=NO`, `TAILWIND_PRESENT=NO`, and `GENERATOR_DEP_INSTALL=NO`. Generated dependency requirements may be inspected, but do not report exact resolved Phoenix or Phoenix LiveView versions at this state. Record the LiveFrames checkout path, commit, tree, and clean status. |
| ENVIRONMENT_CREATED to DEPENDENCY_RESOLVED | Only after ENVIRONMENT_CREATED, add the local path dependency to the exact accepted checkout's apps/live_frames directory. Confirm the path resolves to that checkout and commit. Run `mix deps.get` successfully. | Resolve dependencies in the external host. Do not write into the LiveFrames checkout. Do not compile in this transition. | Record `LIVE_FRAMES_RESOLVED_PATH=`, `LIVE_FRAMES_RESOLVED_COMMIT=`, `MIX_DEPS_GET=PASS`, and `DEPENDENCY_TREE_RECORDED=YES`. Record `PHOENIX_VERSION=` and `PHOENIX_LIVE_VIEW_VERSION=` from the resolved dependency graph or lock state, not from version constraints in generated mix.exs. Record `LIVE_FRAMES_PREVIEW_DEPENDENCY=ABSENT` and `PHOENIX_STORYBOOK_DEPENDENCY=ABSENT`. This is the first transition where dependency installation or resolution is allowed. |
| DEPENDENCY_RESOLVED to COMPILED | Run mix compile --warnings-as-errors successfully in the external host. | Compile the external host and its dependencies. This does not establish runtime behavior. | Retain the command and exit result. Record resolved dependency versions. Do not infer a supported version range from this run. |
| COMPILED to RUNTIME_VERIFIED | Start the host and successfully boot its test endpoint. Verify the rendered component and the static CSS response against the C1 checklist in section 5. | Run the host endpoint and request the host-owned static CSS URL. | Retain the endpoint boot result, rendered markup assertions, HTTP status and response evidence for the CSS, and host dependency/runtime observations. |
| RUNTIME_VERIFIED to PASSED | A reviewer checks every required C1 item, exact version record, dependency isolation, private-reference exclusion, and before/after repository status. No requirement may be waived or inferred from another test suite. | Accept the evidence record and mark this proof run PASSED. Do not modify Catalogue state. | Publish a C1 evidence record containing the commands, results, exact versions, source identity, required assertions, and reviewer decision. Record outcome PASS and state PASSED. |

At any nonterminal state, a missing external prerequisite may end the run as BLOCKED. A failed guard or violated requirement ends it as FAILED. Record the first terminal outcome and supporting evidence. Do not convert a failure to a warning, skip a guard, or advance after a failure. A new attempt starts as a separately recorded proof run.

## 3. External application boundary

C1 must create a new Phoenix application whose canonical root is outside all of these locations:

- the LiveFrames repository and all of its worktrees;
- apps/live_frames_preview;
- fixtures;
- acss;
- private_reference.

A temporary root under /tmp is suitable. Do not commit the proof application to LiveFrames. Do not symlink, copy, or adapt apps/live_frames_preview as the host. Generate a clean host application and use test-owned text and placeholder image paths.

### C1 Phoenix generator profile

Create the host with this exact profile. C1 may choose the application directory and name, but it must use these flags:

```bash
mix phx.new "$HOST_ROOT" \
  --no-install \
  --no-ecto \
  --no-mailer \
  --no-dashboard \
  --no-gettext \
  --no-tailwind \
  --no-version-check
```

- `--no-install` keeps dependency fetching and resolution in the ENVIRONMENT_CREATED to DEPENDENCY_RESOLVED transition.
- `--no-ecto` makes the absence of persistence explicit. `POSTGRES=N/A` must hold by construction, not only because the proof made no database query.
- `--no-tailwind` keeps the host on the documented precompiled LiveFrames CSS path without a Tailwind build dependency.
- `--no-mailer`, `--no-dashboard`, and `--no-gettext` remove generated subsystems that C1 does not use.
- `--no-version-check` keeps Phoenix's remote latest-version check outside the proof. Record the installed generator version instead.

Do not use `--no-html` or `--no-live`; the host needs an ordinary Phoenix HTML and LiveView-capable environment. Do not use `--no-assets`; C1 excludes Tailwind without changing other asset assumptions.

The generator command alone is not evidence that the generated host matches the profile. Inspect the generated files and dependency declarations. Record `PHX_NEW_PROFILE_MATCH=YES`, `ECTO_GENERATED=NO`, `TAILWIND_GENERATED=NO`, and `DEPENDENCIES_INSTALLED_DURING_GENERATION=NO` only after confirming the host has no Ecto setup, no Tailwind setup, and no dependencies installed during generation. Record these values:

```text
PHX_NEW_VERSION=
PHX_NEW_COMMAND=
HOST_ROOT=
ECTO_PRESENT=NO
TAILWIND_PRESENT=NO
GENERATOR_DEP_INSTALL=NO
```

The host application is external to LiveFrames. Its dependency source is the exact accepted LiveFrames checkout selected for C1. The dependency source is not a copy of the app and does not make the consumer application part of the LiveFrames repository.

## 4. C1 dependency and CSS modes

Freeze the first proof as:

    DEPENDENCY_MODE=LOCAL_PATH_TO_EXACT_LIVE_FRAMES_APP

The host must depend directly on:

    <exact accepted checkout>/apps/live_frames

Record the absolute path, accepted commit SHA, accepted tree SHA, and clean checkout status. The dependency must resolve from that exact commit. Do not substitute a moving branch, another worktree revision, Hex, a GitHub release, or a copied package.

C1 proves source and library consumer compatibility only. It is not a Hex publication, GitHub release, package publication, package boundary, or P10 ejection proof.

Freeze the primary CSS path as:

    PRIMARY_CSS_PROOF=PRECOMPILED

The host must serve the LiveFrames artifact at:

    priv/static/live_frames/css/live_frames.css

through host-owned Plug.Static. The host chooses the URL prefix. The response must return HTTP 200 and contain the CTA selector family from the committed artifact, including the root selector .lf-section-media-call-to-action and its component selector family. Selector presence proves asset delivery; nested generated selectors do not become a stable consumer API.

The external host does not need Tailwind. C1 must not add a Tailwind runtime or require Tailwind compilation in the host. Tailwind v4 source integration remains an optional path for a later host that already compiles Tailwind.

## 5. C1 PASS evidence

Every item below is required for PASS:

1. The canonical external application root is outside the locations listed in section 3. Record its real path.
2. The Phoenix generator profile and generated-host inspections required in section 3 pass. `POSTGRES=N/A` and `TAILWIND_HOST_BUILD_REQUIREMENT=NO` hold by construction.
3. The exact LiveFrames dependency identity is recorded as required in section 4, and the dependency resolves from the selected accepted commit.
4. mix deps.get passes in the host.
5. mix compile --warnings-as-errors passes in the host.
6. The host starts and its test endpoint boots successfully.
7. The host imports or invokes LiveFrames.Components.Sections.MediaCallToAction.media_call_to_action/1.
8. The rendered CTA contains the test-owned required heading.
9. The rendered CTA contains all three test-owned image src and alt pairs.
10. Caller-owned primary_action markup renders.
11. The fixed CTA root class and a caller-supplied additive root class are present.
12. The host serves priv/static/live_frames/css/live_frames.css through its own Plug.Static and the URL returns HTTP 200.
13. The served stylesheet contains the CTA selector family present in the committed precompiled artifact.
14. The host has no Tailwind runtime or Tailwind build requirement for the proof.
15. The host dependency tree contains no live_frames_preview or phoenix_storybook dependency. The LiveFrames app itself depends on neither.
16. The proof leaves the exact accepted LiveFrames checkout unchanged. Record its status before and after the run.
17. The consumer contains no copied private_reference, fixture, or ACSS data. It uses only the public CTA API and test-owned placeholder content and assets.
18. The final proof record contains the exact Elixir, OTP, Mix, phx_new, resolved Phoenix, and resolved Phoenix LiveView versions used. The resolved Phoenix versions come from the dependency graph or lock state. These exact versions do not establish a compatibility range.

Record the versions from the actual proof run. One run does not establish an additional compatible version or version range. Keep the command output and assertion results in the C1 evidence record. No C1 result may be inferred from repository ExUnit, preview, or Storybook success.

## 6. Failure outcomes

Use only the following outcomes:

| Outcome | Terminal state | Meaning |
| --- | --- | --- |
| PASS | PASSED | Every C1 requirement passed and a reviewer accepted the evidence record. |
| BLOCKED_DEPENDENCY | BLOCKED | The exact local dependency or a required dependency cannot be resolved in the external environment. |
| BLOCKED_ENVIRONMENT | BLOCKED | The required toolchain or environment is unavailable, so a guarded step cannot run. |
| COMPILE_FAILURE | FAILED | mix compile --warnings-as-errors fails after dependency resolution. |
| RUNTIME_FAILURE | FAILED | The host or test endpoint fails to boot or run. |
| COMPONENT_CONTRACT_FAILURE | FAILED | The host cannot invoke the component or any required heading, image, action, or root-class assertion fails. |
| STATIC_ASSET_FAILURE | FAILED | Plug.Static cannot serve the specified artifact with HTTP 200 or the response lacks the CTA selector family. |
| DEPENDENCY_ISOLATION_FAILURE | FAILED | The dependency resolves from the wrong source identity, or either dependency graph includes a forbidden preview or Storybook dependency. |
| PRIVATE_REFERENCE_LEAK | FAILED | Private source, Bricks source JSON, ACSS reference material, private images, or source-builder IDs/classes appear in the consumer as copied data or public API. |
| REPOSITORY_MUTATION | FAILED | The proof changes any file in the accepted LiveFrames checkout. |

BLOCKED_DEPENDENCY and BLOCKED_ENVIRONMENT are the only blocked outcomes. All other non-PASS outcomes are failures. Preserve the failure and its evidence. Do not downgrade it to a warning or claim PASS after partial success.

## 7. Consumer proof and distribution boundary

C1_PASS means only that a separately created Phoenix application consumed the accepted LiveFrames source/library boundary through the documented primary precompiled CSS path.

    C1_PASS != Hex publication proof
    C1_PASS != package-boundary proof
    C1_PASS != distribution.library=supported
    C1_PASS != Catalogue RELEASED
    C1_PASS != P10 ejection

Do not declare distribution.library, distribution.generator, or distribution.ejection as supported from C0 or C1 alone. Each positive capability claim requires the separately governing Catalogue capability contract and accepted evidence. A local path consumer run does not prove general library distribution support, publication readiness, Hex readiness, or package release readiness.

## 8. Catalogue handoff

C09D7-C defines this handoff boundary:

    NOT_ADMITTED
      -> DRAFT

The transition guard requires all of the following:

- CTA has completed its accepted native lifecycle.
- The C1 consumer proof has passed and its evidence has been accepted.
- A valid globally unique Catalogue ID has been selected. It must never have been used or reserved before.
- The required DRAFT references are defined: component module and function, Storybook reference, documentation references, and structured provenance references.
- The owner explicitly authorizes the admit_to_catalogue action.

Use the existing Catalogue lifecycle and manifest authority for admission. The authorized lifecycle action and guard own the transition and the canonical DRAFT manifest. If an accepted implementation action owns the transition, a direct manifest edit cannot substitute for it. C0 does not choose or reserve an ID and does not run admission.

C09D7-C stops at DRAFT. It does not authorize DRAFT to VALIDATED, VALIDATED to REVIEWED, REVIEWED to APPROVED, APPROVED to RELEASED, publish_new_version, package publication, or P10. DRAFT admission does not establish validation, approval, release, distribution, or redistribution clearance.

Do not fabricate a positive library, generator, or ejection distribution declaration during C0 or C1. Preserve the governing Catalogue capability contract and its evidence requirements.

## 9. Provenance and redistribution

C1 uses only the native CTA public API and test-owned placeholder text and assets. Do not copy or expose private_reference source bytes, Bricks source JSON, ACSS proprietary or reference source, private source images, or source-builder IDs/classes as consumer API.

The local CTA source, fixture, and ACSS evidence roots are read-only research evidence. Their presence, hash, technical inspection, native rewrite, compile success, or consumer compatibility result does not establish ownership, license status, legal permission, internal-use scope, public-safety status, or redistribution clearance. Keep provenance facts and human decisions under docs/04_SOURCE_AND_PROVENANCE.md. C1 is technical evidence only.

## 10. Performance and scaling

C0 and C1 are build and test proof work. Serving the committed CSS through the host's Plug.Static is ordinary static delivery. It does not justify runtime cache infrastructure or a new service.

    DATA_LAYER=BUILD_TEST_ONLY
    POSTGRES=N/A
    REDIS=N/A
    ETS=N/A
    CACHEX=N/A
    GENSERVER=N/A
    PUBSUB=N/A
    OBAN=N/A
    PGBouncer=N/A
    READ_REPLICA=N/A
    RUNTIME_DB_CALLS=0
    RUNTIME_NETWORK_SERVICE_DEPENDENCIES=0

Do not add a database, Redis, ETS, Cachex, GenServer, PubSub, Oban, PgBouncer, read replica, or another runtime service for this slice.

## 11. Separate open workstreams

PR #98, Catalogue #51A package boundary verification, remains a separate package-boundary workstream. C09D7-C0 does not rebase or fix it, copy its changes, change apps/live_frames/mix.exs or .github/workflows/ci.yml, invent license metadata, or authorize Hex publication. Reconcile that package work in its own review against then-current main.

PR #196, C09C4 Bricks post content word limits, remains a separate implementation workstream. It does not authorize C09D7-C changes. Do not include or modify its implementation or tests in this authority slice.

Neither PR changes the C09D7-C0 scope. Recheck open PRs before future C1 or Catalogue work and stop if an active PR creates a material authority conflict.
