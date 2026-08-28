# LiveFrames Phase 0 implementation plan

The master spec authorizes repository foundation only. Execute the steps in
order and stop at the Phase 0 gate.

## 1. Establish the umbrella

- Keep the root `mix.exs`, `mix.lock`, formatter and config files at the repo
  root.
- Use `apps/live_frames` for the reusable package.
- Use `apps/live_frames_preview` for the Phoenix preview application.
- Keep the dependency direction one-way: preview depends on library.

## 2. Add the quality foundation

- Configure Elixir formatting and editor defaults.
- Compile with warnings as errors in CI.
- Add focused endpoint/core boundary tests.
- Add CI for dependency fetch, format, compile, tests and `git diff --check`.
- Record the locally verified Elixir/OTP and locked framework versions.

## 3. Add source/privacy boundaries

- Create `imports/{pending,approved,processed,rejected}`.
- Create `fixtures/{bricks,automatic_css,html,expected_ir,assets}`.
- Create `private_reference/` and ignore archives/vendor directories.
- Create `placeholders/{landscape,portrait,square}`.
- Copy the supplied Bricks and ACSS settings exports into fixtures.
- Add `SOURCE.md` provenance records without asserting unknown license rights.

## 4. Add documentation contracts

- Preserve the master spec unchanged as the authority.
- Add subordinate documentation placeholders `01` through `17`.
- Keep the Phase 0 design and plan synchronized with the master.

## 5. Verify and stop

Run:

```sh
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix test
git diff --check
```

Run a short preview smoke test against `/` and `/health`. Do not add Bricks
parsing, ACSS normalization, Design IR, Tailwind, Storybook, real catalogue
content or generated components in this phase.
