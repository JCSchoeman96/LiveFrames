# Agent instructions

- Follow `docs/00_LIVEFRAMES_MASTER_SPEC.md` and the current task scope.
- Phase 3 is merged. Do not start Phase 4 or later work without explicit
  authorization.
- Keep `apps/live_frames` independent of the preview app and source runtimes.
- Treat JSON and plugin references as untrusted data. Never execute them or add
  ACSS/WordPress runtime dependencies.
- Preserve Design IR `1.0.0` and TokenSet `1.0.0` unless a task explicitly
  changes a versioned contract.
- Before handoff run: `mix format --check-formatted`,
  `mix compile --warnings-as-errors`, `mix assets.build`, `mix test`,
  `mix deps.unlock --check-unused`, and `git diff --check`.
- Report evidence, changed files, tests, commit, branch and PR status. Do not
  merge unless explicitly asked.
