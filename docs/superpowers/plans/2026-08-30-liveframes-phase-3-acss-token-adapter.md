# LiveFrames Phase 3 Automatic.css TokenSet Adapter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the independently versioned `LiveFrames.Tokens` contract and a pure Automatic.css settings adapter that normalizes the approved flat fixture into deterministic, provenance-preserving semantic tokens.

**Architecture:** Keep generic TokenSet structs, validation, and serialization under `LiveFrames.Tokens`; they must not reference the adapter. Keep Automatic.css recognition, explicit mapping, value normalization, and relationship resolution under `LiveFrames.Adapters.AutomaticCSS`. The adapter returns a TokenSet plus diagnostics, and strict profiles are checked by the generic validator.

**Tech Stack:** Elixir 1.19.3, OTP 28, ExUnit, Jason 1.4.5, Mix umbrella package `apps/live_frames`.

**Execution order:** The task sections below are kept with their detailed
edit streams, but the implementation order is dependency-driven: Tasks 1–6
(generic TokenSet contract) must complete before Tasks 7–11 (Automatic.css
adapter), followed by Tasks 12–14 (documentation, gates, and release).

---

## File map

Create:

- `apps/live_frames/lib/live_frames/tokens.ex`: public generic TokenSet API.
- `apps/live_frames/lib/live_frames/tokens/token_set.ex`: versioned TokenSet root.
- `apps/live_frames/lib/live_frames/tokens/token.ex`: canonical token struct.
- `apps/live_frames/lib/live_frames/tokens/diagnostic.ex`: generic diagnostic struct.
- `apps/live_frames/lib/live_frames/tokens/validation.ex`: TokenSet validation, references, cycles, and required paths.
- `apps/live_frames/lib/live_frames/tokens/serializer.ex`: JSON-ready conversion and deterministic encoding.
- `apps/live_frames/lib/live_frames/adapters/automatic_css.ex`: public adapter boundary.
- `apps/live_frames/lib/live_frames/adapters/automatic_css/loader.ex`: file/decode/flat-envelope recognition.
- `apps/live_frames/lib/live_frames/adapters/automatic_css/normalizer.ex`: authoritative mapping table and token construction.
- `apps/live_frames/lib/live_frames/adapters/automatic_css/resolver.ex`: direct, HSL, reference, and derived-value normalization.
- `apps/live_frames/test/live_frames/tokens_test.exs`: generic contract tests.
- `apps/live_frames/test/live_frames/automatic_css_adapter_test.exs`: adapter unit/integration tests.

Modify:

- `apps/live_frames/lib/live_frames.ex`: current package boundary documentation.
- `docs/06_ACSS_TOKEN_ADAPTER.md`: implemented Phase 3 contract.
- `docs/COMPATIBILITY.md`: narrow initial ACSS adapter support statement.
- `README.md`: remove stale claim that ACSS normalization is entirely deferred.

Do not modify `apps/live_frames/lib/live_frames/ir/**`, `apps/live_frames/test/live_frames/ir_test.exs`, `docs/03_DESIGN_IR_SPEC.md`, Bricks/preview fixtures, Tailwind, SCSS, HEEx, or Hero code.

## Task 1: Write failing TokenSet contract tests

**Files:** Create `apps/live_frames/test/live_frames/tokens_test.exs`.

- [ ] **Step 1: Add a valid TokenSet fixture and independent-version assertion.**

Use this minimal fixture so the intended public shape is executable:

```elixir
defmodule LiveFrames.TokensTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Tokens
  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet

  defp valid_token_set do
    %TokenSet{
      source_metadata: %{"source_version" => "4.0.1", "export_version" => nil},
      tokens: %{
        "color.primary" => %Token{
          path: "color.primary",
          category: :color,
          value: "#32a2c1",
          resolved_value: "#32a2c1",
          source_expression: "#32a2c1",
          resolution_status: :resolved,
          provenance: %{
            "source_keys" => ["color-primary"],
            "raw_value" => "#32a2c1",
            "adapter" => "automatic_css",
            "adapter_version" => "1.0.0",
            "transformation" => "direct"
          }
        },
        "button.primary.background" => %Token{
          path: "button.primary.background",
          category: :button,
          value: %{"type" => "reference", "path" => "color.primary"},
          resolved_value: "#32a2c1",
          source_expression: "var(--primary)",
          resolution_status: :resolved,
          references: ["color.primary"],
          provenance: %{"source_keys" => ["btn-primary-bg"]}
        }
      }
    }
  end

  test "owns an independent versioned TokenSet contract" do
    assert Tokens.current_token_set_version() == "1.0.0"
    assert TokenSet.new().token_set_version == "1.0.0"
    assert Tokens.validate(valid_token_set()) == :ok
  end
end
```

## Task 7: Write failing loader and adapter-boundary tests

**Files:** Create `apps/live_frames/test/live_frames/automatic_css_adapter_test.exs`.

- [ ] **Step 1: Add API and source-recognition tests.**

Use the committed fixture once and assert the public result shape:

```elixir
defmodule LiveFrames.AutomaticCSSAdapterTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS

  test "recognizes and normalizes the approved fixture through from_file" do
    path = Path.expand("../../../../fixtures/automatic_css/acss_settings.json", __DIR__)
    assert {:ok, token_set, diagnostics} = AutomaticCSS.from_file(path)
    assert token_set.token_set_version == "1.0.0"
    assert is_list(diagnostics)
    assert token_set.source_metadata["source_shape"] == "flat_settings_map"
  end

  test "returns structured diagnostics for malformed JSON" do
    assert {:error, diagnostics} = AutomaticCSS.from_json("{not-json")
    assert Enum.any?(diagnostics, &(&1.code == "acss.source.json_invalid"))
  end

  test "rejects unsupported top-level data without crashing" do
    assert {:error, diagnostics} = AutomaticCSS.normalize([{"color-primary", "#fff"}])
    assert Enum.any?(diagnostics, &(&1.code == "acss.source.invalid"))
    assert {:error, diagnostics} = AutomaticCSS.normalize(%{"unrelated" => true})
    assert Enum.any?(diagnostics, &(&1.code == "acss.source.invalid"))
  end

  test "returns structured diagnostics for an unreadable file" do
    assert {:error, diagnostics} = AutomaticCSS.from_file("/tmp/liveframes-missing-acss.json")
    assert Enum.any?(diagnostics, &(&1.code == "acss.source.invalid"))
  end
end
```

- [ ] **Step 2: Run the test and verify the correct red state.**

Run `mix test apps/live_frames/test/live_frames/automatic_css_adapter_test.exs`.
Expected: compilation fails because the adapter modules do not exist.

- [ ] **Step 3: Commit the adapter boundary tests.**

```sh
git add apps/live_frames/test/live_frames/automatic_css_adapter_test.exs
git commit -m "test: specify the Automatic.css adapter boundary"
```

## Task 8: Implement loader and public adapter API

**Files:** Create `apps/live_frames/lib/live_frames/adapters/automatic_css/loader.ex` and `apps/live_frames/lib/live_frames/adapters/automatic_css.ex`.

- [ ] **Step 1: Implement flat source recognition and provenance metadata.**

Accept only maps with non-empty string keys, JSON-safe values, and at least one
known mapping key. Reject lists, scalars, nested envelopes, and maps with no
recognized ACSS key using `acss.source.invalid`. Record this metadata:

```elixir
%{
  "source_system" => "automatic_css",
  "source_type" => "automatic_css_settings",
  "source_shape" => "flat_settings_map",
  "source_version" => "4.0.1",
  "source_version_status" => "fixture_reference",
  "export_version" => nil,
  "adapter" => "automatic_css",
  "adapter_version" => "1.0.0",
  "source_key_count" => map_size(settings),
  "compatibility" => "recognized_with_unknown_fields"
}
```

Use literal binary keys and `Map.has_key?/2`; never convert source strings to
atoms.

- [ ] **Step 2: Implement file and JSON entry points.**

Use `File.read/1` on the caller-supplied path and `Jason.decode/1` on one JSON
binary. Return `{:error, [Diagnostic.new(...)]}` for expected read/decode
failures. Feed successful decoded maps through `normalize/2`; do not create a
second normalization path.

- [ ] **Step 3: Implement result handling.**

`normalize/2` must recognize the decoded map, call the normalizer, construct a
`TokenSet`, validate it with strict/profile options, and return
`{:ok, token_set, diagnostics}` or `{:error, diagnostics}`. Store the same
diagnostic list in `token_set.diagnostics` on success.

- [ ] **Step 4: Run and commit.**

Run `mix test apps/live_frames/test/live_frames/automatic_css_adapter_test.exs`.
The loader tests pass; mapping assertions remain for Task 9. Commit:

```sh
git add apps/live_frames/lib/live_frames/adapters/automatic_css.ex apps/live_frames/lib/live_frames/adapters/automatic_css
git commit -m "feat: add the Automatic.css source loader boundary"
```

## Task 9: Write failing normalization and resolver tests

**Files:** Modify `apps/live_frames/test/live_frames/automatic_css_adapter_test.exs`.

- [ ] **Step 1: Add the minimal settings map and representative assertions.**

Use these exact source values:

```elixir
defp minimal_settings do
  %{
    "color-primary" => "#32a2c1",
    "primary-hover-h" => 193, "primary-hover-s" => 59, "primary-hover-l" => 55.2,
    "primary-light-h" => 193, "primary-light-s" => 59, "primary-light-l" => 85,
    "primary-ultra-dark-h" => 193, "primary-ultra-dark-s" => 59, "primary-ultra-dark-l" => 10,
    "color-neutral" => "#000000",
    "neutral-ultra-dark-h" => 0, "neutral-ultra-dark-s" => 0, "neutral-ultra-dark-l" => 10,
    "base-space" => 30, "base-space-min" => 24, "mob-space-scale" => 1.333, "space-scale" => 1.5,
    "contextual-content-gap" => "var(--space-m)", "gutter-min" => 16, "gutter-max" => 80,
    "base-text-desk" => 18, "base-text-mob" => 16, "base-text-lh" => "calc(6px + 2ex)",
    "base-heading-desk" => 20, "base-heading-mob" => 18, "base-heading-lh" => "calc(4px + 2ex)",
    "heading-scale" => 1.333, "mob-heading-scale" => 1.2,
    "text-scale" => 1.333, "mob-text-scale" => 1.2, "vp-min" => 360, "vp-max" => 1366,
    "btn-primary-bg" => "var(--primary)", "btn-primary-hover" => "var(--primary-hover)",
    "btn-primary-text" => "var(--primary-ultra-dark)", "btn-primary-border-color" => "var(--btn-background)",
    "btn-primary-focus-color" => "var(--primary-light)", "btn-border-radius" => "var(--radius)",
    "base-radius" => "5px", "btn-padding-inline" => "1.25em", "btn-padding-block" => ".5em",
    "btn-min-width" => 140, "btn-font-size" => "--text-m", "btn-font-weight" => "400",
    "btn-line-height" => 1, "btn-border-width" => "1.5px", "btn-border-style" => "solid",
    "btn-primary-outline-background" => "transparent",
    "btn-primary-outline-background-hover" => "var(--primary-hover)",
    "btn-primary-outline-border-color" => "var(--primary)",
    "btn-primary-outline-border-hover" => "var(--btn-background-hover)",
    "btn-primary-outline-focus-color" => "var(--primary-semi-light)",
    "primary-outline-btn-text" => "var(--primary)",
    "primary-outline-hover-text" => "var(--primary-ultra-light)"
  }
end

test "normalizes representative categories and relationships" do
  assert {:ok, token_set, diagnostics} = AutomaticCSS.normalize(minimal_settings())
  assert diagnostics == token_set.diagnostics
  assert token_set.tokens["color.primary"].resolved_value == "#32a2c1"
  assert token_set.tokens["color.primary.hover"].resolved_value == "hsl(193 59% 55.2%)"
  assert token_set.tokens["spacing.base.max"].resolved_value == "30px"
  assert token_set.tokens["spacing.gutter.min"].resolved_value == "16px"
  assert token_set.tokens["typography.body.line_height"].resolved_value == "calc(6px + 2ex)"
  assert token_set.tokens["button.primary.background"].references == ["color.primary"]
  assert token_set.tokens["button.primary.border"].references == ["button.primary.background"]
  assert token_set.tokens["button.primary.font_size"].references == ["typography.body.scale.medium"]
  assert token_set.tokens["layout.viewport.min"].resolved_value == "360px"
end
```

- [ ] **Step 2: Add provenance, unknown, unresolved, breakpoint, and strict tests.**

Assert a direct color contains raw source key/value, adapter identity/version,
and `transformation: "direct"`; add an unrelated key and assert one
`acss.setting.unknown` summary with a count and no canonical unknown token;
assert `color.text.dark` preserves `var(--black)` as unresolved; assert
`layout.breakpoint.auto_grid` is `992px` only when `auto-staggered-grid-breakpoint`
is numeric; and assert `strict: true, profile: :hero_foundation` succeeds for
the full fixture, fails with `tokens.required.missing` after deleting a
required source value, and does not fail when an unrelated status setting is
deleted. No `768px` or other inferred breakpoint may appear.

- [ ] **Step 3: Add deterministic normalization and atom-safety tests.**

Normalize equal maps inserted in opposite order and assert TokenSets and
`LiveFrames.Tokens.encode!/1` are equal. Compare `:erlang.system_info(:atom_count)`
before/after a map with a random untrusted key and assert the count does not
increase.

- [ ] **Step 4: Run and verify the correct red state.**

Run `mix test apps/live_frames/test/live_frames/automatic_css_adapter_test.exs`.
Expected: failures identify missing `Normalizer`/`Resolver` behavior.

## Task 10: Implement the explicit resolver and mapping table

**Files:** Create `apps/live_frames/lib/live_frames/adapters/automatic_css/resolver.ex` and `normalizer.ex`.

- [ ] **Step 1: Implement safe resolver functions.**

Implement pure functions with these signatures:

```elixir
Resolver.literal(value, kind, opts)
Resolver.px(value, source_key)
Resolver.hsl(settings, source_keys)
Resolver.reference(raw_value, target_path, source_key)
Resolver.derived(recipe, variable, inputs, references, source_keys)
Resolver.unresolved(raw_value, source_key, reason)
```

Accept only demonstrated types. Convert known numeric `px` values to canonical
CSS strings with stable precision; never coerce numeric strings. Render HSL
channels as `hsl(H S% L%)`, retaining raw channels in provenance. Known
references store a semantic reference and original expression; unknown
variables remain unresolved. No source code, CSS, PHP, JavaScript, shell, or
module is evaluated.

- [ ] **Step 2: Implement the one authoritative ordered mapping list.**

`Normalizer.mapping/0` must contain exactly the paths in the Phase 3 design
document. Each entry has `path`, `category`, `strategy`, `source_keys`, and,
when applicable, `reference_path`, `unit`, or a derived recipe. It includes the
primary/neutral/base/background/text colors, spacing/radius, typography,
primary button/outline, and viewport/breakpoint paths. Use the committed
`calculatedVariableGroups` evidence for `space-m`, `space-xl`,
`section-space-m`, `text-m`, `h1`, and the button/radius CSS-variable
relationships. Do not include Bricks names.

- [ ] **Step 3: Evaluate mappings and preserve provenance.**

Iterate in mapping order, create one token per path, retain source keys, raw
values, source expressions, adapter identity/version, and transformation. For
missing/invalid values create an unresolved token with a diagnostic; never
insert a fallback. Detect duplicate paths/conflicting definitions as
`acss.mapping.conflict`.

- [ ] **Step 4: Represent proven derived relationships.**

Create structured `derived` values for spacing medium/XL/section, body medium,
and heading H1. Include source ratios, base/viewport references, and the
calculation group name; do not calculate every ACSS scale or emit CSS. Resolve
contextual gap and button font-size references to these semantic paths.

- [ ] **Step 5: Summarize unknown settings and sort diagnostics.**

Compute source keys not consumed by the mapping, sort them, and emit one
`acss.setting.unknown` info diagnostic containing `count` and at most ten
sample keys. Sort diagnostics by code, path, source key, and message.

- [ ] **Step 6: Run and commit.**

Run `mix test apps/live_frames/test/live_frames/automatic_css_adapter_test.exs`.
Expected: all adapter unit tests pass. Commit:

```sh
git add apps/live_frames/lib/live_frames/adapters/automatic_css
git add apps/live_frames/test/live_frames/automatic_css_adapter_test.exs
git commit -m "feat: normalize Automatic.css settings into semantic tokens"
```

## Task 11: Add real-fixture integration and regression coverage

**Files:** Modify `apps/live_frames/test/live_frames/automatic_css_adapter_test.exs`.

- [ ] **Step 1: Assert real-fixture token coverage and category counts.**

Call `AutomaticCSS.from_file/2` on the committed fixture. Assert every
`hero_foundation` path exists and is resolved, the total equals
`length(Normalizer.mapping())`, each category count is computed from tokens,
and no raw ACSS key is emitted as a token path.

- [ ] **Step 2: Assert source/export version distinction.**

Assert `source_metadata["source_version"] == "4.0.1"`,
`source_metadata["export_version"] == nil`, and
`source_metadata["source_version_status"] == "fixture_reference"`.

- [ ] **Step 3: Assert unresolved and unknown behavior on the real fixture.**

Assert mapped `color.text.dark`/`color.text.light` preserve their raw
`var(--black)`/`var(--white)` expressions as unresolved, the unknown-setting
summary count is positive, and no token for the Hero overlay variable or
generic tablet/mobile threshold is fabricated.

- [ ] **Step 4: Assert bytewise real-fixture determinism.**

Decode the fixture once, reverse its map insertion order with
`Map.new(Enum.reverse(Map.to_list(settings)))`, normalize both maps, and assert
equal diagnostic lists and equal `LiveFrames.Tokens.encode!/1` output.

- [ ] **Step 5: Run and commit.**

Run:

```sh
mix test apps/live_frames/test/live_frames/tokens_test.exs apps/live_frames/test/live_frames/automatic_css_adapter_test.exs
```

Expected: all focused Phase 3 tests pass. Commit:

```sh
git add apps/live_frames/test/live_frames/automatic_css_adapter_test.exs
git commit -m "test: cover the approved ACSS fixture"
```

## Task 12: Complete documentation and package-boundary updates

**Files:** Modify `docs/06_ACSS_TOKEN_ADAPTER.md`, `docs/COMPATIBILITY.md`, `README.md`, and `apps/live_frames/lib/live_frames.ex`.

- [ ] **Step 1: Document the implemented contract.**

Replace the placeholder with purpose, boundaries, flat source shape,
4.0.1/reference versus absent export version, TokenSet `1.0.0`, exact canonical
path groups, provenance, direct/reference/derived resolution, strict
`hero_foundation`, unknown-setting policy, diagnostics, breakpoint policy,
deterministic serialization, security/performance classification, limitations,
and the exact Phase 3 stop boundary.

- [ ] **Step 2: Narrow compatibility claims.**

State that the approved Automatic.css settings subset is supported at the
initial contract level only, ACSS is not a runtime dependency, and Bricks class
resolution, Hero conversion, HEEx, Tailwind bridge, and SCSS generation are
not implemented.

- [ ] **Step 3: Run scope checks and format.**

Run:

```sh
rg -n "BricksParser|LiveFrames\.Adapters\.Bricks|HeroIndiaTokenSet|HEEx|tailwind\.config|scss" apps/live_frames/lib apps/live_frames/test
rg -n "automatic_css|Automatic\.css" apps/live_frames/mix.exs mix.exs
mix format
git diff --check
```

Expected: no forbidden implementation modules/dependencies; only intended
generic-token and adapter references appear.

- [ ] **Step 4: Commit documentation.**

```sh
git add README.md docs/06_ACSS_TOKEN_ADAPTER.md docs/COMPATIBILITY.md apps/live_frames/lib/live_frames.ex
git commit -m "docs: record the Phase 3 ACSS adapter contract"
```

## Task 13: Run every local validation gate

**Files:** No new files; inspect the full branch diff.

- [ ] **Step 1: Run focused Phase 3 tests.**

```sh
mix test apps/live_frames/test/live_frames/tokens_test.exs apps/live_frames/test/live_frames/automatic_css_adapter_test.exs
```

Expected: zero failures.

- [ ] **Step 2: Run all required repository gates as fresh commands.**

```sh
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix assets.build
mix test
mix deps.unlock --check-unused
git diff --check
```

Expected: every command exits zero, all Phase 0–2 tests remain green, and no
generated asset is tracked.

- [ ] **Step 3: Audit IR immutability and forbidden scope.**

```sh
git diff --name-only 7231195b5bf150ba7896648576c1bd0718801506
git diff -- apps/live_frames/lib/live_frames/ir docs/03_DESIGN_IR_SPEC.md
git status --short --branch
```

Expected: no IR or Design IR spec changes, no Bricks/Hero/HEEx/Tailwind/SCSS
implementation, and a clean worktree.

- [ ] **Step 4: Record final metrics from verified output.**

Use focused test output or a checked-in-safe `mix run` expression to report
TokenSet version, total/category counts, required profile result, unknown
count, unresolved paths, breakpoint candidates, and diagnostics by severity.
Do not add a runtime script or generated artifact solely for reporting.

## Task 14: Review, push, and open the dedicated PR

**Files:** Branch metadata and GitHub PR only.

- [ ] **Step 1: Request code review against the Phase 2 merge baseline.**

Use the requesting-code-review workflow with
`BASE_SHA=7231195b5bf150ba7896648576c1bd0718801506` and the final local
`HEAD_SHA`. Review the complete diff for scope, provenance, strict behavior,
determinism, and source/runtime coupling. Fix Critical/Important feedback,
rerun affected tests, and commit fixes.

- [ ] **Step 2: Push after local gates pass.**

```sh
git push -u origin feature/phase-3-acss-token-adapter
```

Confirm remote head equals local `HEAD` and wait for exact-head push CI.

- [ ] **Step 3: Open the dedicated PR.**

Create a temporary PR-body file with scope, fixture/version compatibility,
canonical coverage, limitations, diagnostics, performance/scaling review,
required profile result, local gates, and the explicit non-started Phase 4
boundaries, then run:

```sh
gh pr create --base main --head feature/phase-3-acss-token-adapter --title "Phase 3: add Automatic.css TokenSet adapter" --body-file /tmp/liveframes-phase-3-pr-body.md
```

Do not commit the temporary body file and do not merge the PR.

- [ ] **Step 4: Verify exact-head PR CI and final status.**

```sh
gh pr view --json number,url,state,headRefName,baseRefName,headRefOid,statusCheckRollup
gh run list --branch feature/phase-3-acss-token-adapter --limit 20
git status --short --branch
```

Expected: the PR is open against `main`, head SHA matches local `HEAD`, exact
push and pull-request quality checks are green, and the worktree is clean.

- [ ] **Step 5: Complete only after evidence is complete.**

Re-read this plan and the Phase 3 TOON, verify every explicit requirement,
command, invariant, and deliverable, then provide the required 27-item final
report. Stop without merging or starting Bricks, Hero, HEEx, Tailwind, SCSS, or
Phase 4.



- [ ] **Step 2: Run the test and verify the correct red state.**

Run `mix test apps/live_frames/test/live_frames/tokens_test.exs`.
Expected: compilation fails because the TokenSet modules do not exist. Fix
only test/setup errors if the missing implementation is not the failure.

- [ ] **Step 3: Commit the red test.**

```sh
git add apps/live_frames/test/live_frames/tokens_test.exs
git commit -m "test: specify the Phase 3 TokenSet contract"
```

## Task 2: Implement TokenSet structs and diagnostics

**Files:** Create `tokens.ex`, `tokens/token_set.ex`, `tokens/token.ex`, and `tokens/diagnostic.ex`.

- [ ] **Step 1: Implement the data model and constructors.**

Define `TokenSet` with only `token_set_version`, `source_metadata`, `tokens`,
and `diagnostics`. Define `Token` with `path`, `category`, `value`,
`resolved_value`, `source_expression`, `resolution_status`, `references`,
`provenance`, and `metadata`. Define `Diagnostic` with `code`, `severity`,
`category`, `message`, `path`, `source_key`, and `metadata`. Use JSON-safe
defaults and normalize only fixed known atoms/strings; never call
`String.to_atom/1` on source input.

Expose:

```elixir
LiveFrames.Tokens.current_token_set_version()
LiveFrames.Tokens.validate(token_set, opts \\ [])
LiveFrames.Tokens.validate!(token_set, opts \\ [])
LiveFrames.Tokens.to_map(token_set)
LiveFrames.Tokens.encode(token_set, opts \\ [])
LiveFrames.Tokens.encode!(token_set, opts \\ [])
LiveFrames.Tokens.TokenSet.new(attrs \\ [])
LiveFrames.Tokens.Token.new(attrs \\ [])
LiveFrames.Tokens.Diagnostic.new(attrs \\ [])
```

- [ ] **Step 2: Run the focused test.**

Run `mix test apps/live_frames/test/live_frames/tokens_test.exs`.
Expected: structs/version compile; validation is still red until Task 4.

- [ ] **Step 3: Commit the data model.**

```sh
git add apps/live_frames/lib/live_frames/tokens.ex apps/live_frames/lib/live_frames/tokens
git commit -m "feat: add the versioned TokenSet data model"
```

## Task 3: Write failing generic validation tests

**Files:** Modify `apps/live_frames/test/live_frames/tokens_test.exs`.

- [ ] **Step 1: Add tests for version, field shape, JSON safety, references, cycles, and strict paths.**

Assert these codes and behaviors:

```elixir
test "rejects unsupported TokenSet versions" do
  assert {:error, diagnostics} =
           Tokens.validate(%{valid_token_set() | token_set_version: "2.0.0"})

  assert Enum.any?(diagnostics, &(&1.code == "tokens.version.unsupported"))
end

test "rejects invalid paths, categories, statuses, and provenance" do
  token = valid_token_set().tokens["color.primary"]
  invalid = %{
    valid_token_set()
    | tokens: %{"bad path" => %{token | path: "bad path", category: :unknown, resolution_status: :pending, provenance: %{"bad" => self()}}}
  }

  assert {:error, diagnostics} = Tokens.validate(invalid)
  codes = Enum.map(diagnostics, & &1.code)
  assert "tokens.path.invalid" in codes
  assert "tokens.category.invalid" in codes
  assert "tokens.status.invalid" in codes
  assert "tokens.provenance.invalid" in codes
end

test "reports a missing reference and a reference cycle" do
  token = valid_token_set().tokens["color.primary"]
  missing = %{token | path: "spacing.content_gap", value: %{"type" => "reference", "path" => "spacing.missing"}, references: ["spacing.missing"]}
  assert {:error, diagnostics} = Tokens.validate(%{valid_token_set() | tokens: Map.put(valid_token_set().tokens, missing.path, missing)})
  assert Enum.any?(diagnostics, &(&1.code == "tokens.reference.missing"))

  a = %{token | path: "cycle.a", value: %{"type" => "reference", "path" => "cycle.b"}, references: ["cycle.b"]}
  b = %{token | path: "cycle.b", value: %{"type" => "reference", "path" => "cycle.a"}, references: ["cycle.a"]}
  assert {:error, diagnostics} = Tokens.validate(%{valid_token_set() | tokens: %{"cycle.a" => a, "cycle.b" => b}})
  assert Enum.any?(diagnostics, &(&1.code == "tokens.reference.cycle"))
end

test "strict validation reports only missing required paths" do
  assert {:error, diagnostics} = Tokens.validate(valid_token_set(), required_paths: ["color.primary", "spacing.content_gap"], strict: true)
  assert Enum.any?(diagnostics, &(&1.code == "tokens.required.missing"))
  assert Tokens.validate(valid_token_set(), required_paths: ["color.primary"], strict: true) == :ok
end
```

- [ ] **Step 2: Run the tests and verify the correct red state.**

Run `mix test apps/live_frames/test/live_frames/tokens_test.exs` and confirm
the failures identify missing validation behavior rather than test syntax.

## Task 4: Implement generic TokenSet validation

**Files:** Create `apps/live_frames/lib/live_frames/tokens/validation.ex`; modify `apps/live_frames/lib/live_frames/tokens.ex`.

- [ ] **Step 1: Validate root and token fields.**

Support categories `:color`, `:spacing`, `:typography`, `:button`, `:layout`,
`:radius`, and `:overlay`; statuses `:resolved` and `:unresolved`; and path
format `^[a-z][a-z0-9]*(\.[a-z][a-z0-9_]*)*$`. Validate JSON-safe values,
metadata, provenance, diagnostics, and duplicate keys after JSON normalization.

- [ ] **Step 2: Validate references and cycles.**

Accept reference values only as `%{"type" => "reference", "path" => path}`.
Accept derived values only with non-empty `type`, `recipe`, and JSON-object
`inputs`. Check every `references` target and report
`tokens.reference.missing`. Traverse sorted paths depth-first and report
`tokens.reference.cycle` with the deterministic cycle path in metadata.

- [ ] **Step 3: Implement strict required-token checks.**

With `strict: true`, require every `opts[:required_paths]` token to exist and
have `resolution_status: :resolved`; emit one `tokens.required.missing` per
absent/unresolved path and ignore unrelated paths. `validate!/2` returns the
original value on success and raises only for invalid programmer-supplied
TokenSet data.

- [ ] **Step 4: Run and commit.**

Run `mix test apps/live_frames/test/live_frames/tokens_test.exs` and expect all
generic validation tests to pass, then run:

```sh
git add apps/live_frames/lib/live_frames/tokens.ex apps/live_frames/lib/live_frames/tokens/validation.ex apps/live_frames/test/live_frames/tokens_test.exs
git commit -m "feat: validate TokenSet references and required tokens"
```

## Task 5: Write failing serialization tests

**Files:** Modify `apps/live_frames/test/live_frames/tokens_test.exs`.

- [ ] **Step 1: Add bytewise deterministic JSON assertions.**

Use equivalent source metadata inserted in opposite order and assert:

```elixir
test "encoding is deterministic and contains no struct internals" do
  first = %{valid_token_set() | source_metadata: Map.new([{"z", %{"b" => 2, "a" => 1}}, {"a", "first"}])}
  second = %{valid_token_set() | source_metadata: Map.new([{"a", "first"}, {"z", %{"a" => 1, "b" => 2}}])}
  assert Tokens.encode!(first) == Tokens.encode!(second)
  decoded = first |> Tokens.encode!() |> Jason.decode!()
  assert decoded["token_set_version"] == "1.0.0"
  assert decoded["tokens"]["button.primary.background"]["value"]["type"] == "reference"
  assert decoded["tokens"]["button.primary.background"]["references"] == ["color.primary"]
  refute Tokens.encode!(first) =~ "__struct__"
end
```

- [ ] **Step 2: Run the focused test and confirm serializer behavior is missing.**

Run `mix test apps/live_frames/test/live_frames/tokens_test.exs`; serialization
must fail for the missing serializer, not for malformed assertions.

## Task 6: Implement deterministic TokenSet serialization

**Files:** Create `apps/live_frames/lib/live_frames/tokens/serializer.ex`; modify `apps/live_frames/lib/live_frames/tokens.ex`.

- [ ] **Step 1: Convert structs explicitly to JSON maps.**

Emit string keys, string status/category/severity values, explicit `value`,
`resolved_value`, `source_expression`, `references`, provenance, metadata, and
diagnostic fields. Reject non-JSON values before Jason.

- [ ] **Step 2: Sort object keys recursively without changing list order.**

Convert maps recursively to sorted `Jason.OrderedObject` values and encode with
`maps: :strict`. Keep this serializer independent of the frozen IR serializer.

- [ ] **Step 3: Run and commit.**

Run `mix test apps/live_frames/test/live_frames/tokens_test.exs` and expect all
TokenSet tests to pass, then commit:

```sh
git add apps/live_frames/lib/live_frames/tokens.ex apps/live_frames/lib/live_frames/tokens/serializer.ex apps/live_frames/test/live_frames/tokens_test.exs
git commit -m "feat: serialize TokenSets deterministically"
```
