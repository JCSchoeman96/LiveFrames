# LiveFrames Phase 2 Design IR Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the versioned, source-independent LiveFrames Design IR contract with validation, diagnostics, and deterministic JSON serialization.

**Architecture:** Keep the IR in the reusable `live_frames` package. Plain structs represent the document, tree nodes, styles, responsive overrides, registries, traces, and diagnostics. `LiveFrames.IR` owns validation and serialization; it does not know about Bricks, ACSS, Phoenix rendering, or the preview application.

**Tech Stack:** Elixir 1.19.3, OTP 28, ExUnit, Jason 1.4.5.

---

## File map

Create:

- `apps/live_frames/lib/live_frames/ir/design_document.ex`: root document and defaults.
- `apps/live_frames/lib/live_frames/ir/design_node.ex`: node fields and deterministic path IDs.
- `apps/live_frames/lib/live_frames/ir/style_value.ex`: explicit style-value constructors.
- `apps/live_frames/lib/live_frames/ir/responsive_override.ex`: responsive style entries.
- `apps/live_frames/lib/live_frames/ir/asset_reference.ex`: asset registry records.
- `apps/live_frames/lib/live_frames/ir/interaction.ex`: interaction registry records.
- `apps/live_frames/lib/live_frames/ir/source_trace.ex`: source/provenance trace records.
- `apps/live_frames/lib/live_frames/ir/diagnostic.ex`: validation and conversion findings.
- `apps/live_frames/lib/live_frames/ir/validation_error.ex`: exception for `validate!/1` and `encode!/1`.
- `apps/live_frames/lib/live_frames/ir/validation.ex`: complete document validation.
- `apps/live_frames/lib/live_frames/ir/serializer.ex`: JSON-ready conversion and ordered encoding.
- `apps/live_frames/lib/live_frames/ir.ex`: public IR API.
- `apps/live_frames/test/live_frames/ir_test.exs`: construction, validation, and serialization tests.

Modify:

- `apps/live_frames/mix.exs`: add direct Jason dependency because the reusable package owns serialization.
- `docs/03_DESIGN_IR_SPEC.md`: record the frozen Phase 2 contract in the existing subordinate specification file.

Do not modify preview code, ACSS fixtures, Bricks fixtures, or generator directories.

## Task 1: Add the core JSON dependency

**Files:** `apps/live_frames/mix.exs`, `mix.lock`

- [x] Step 1: Add `{:jason, "~> 1.4"}` to the library dependency list.

The library must be independently consumable. It cannot rely on the preview application's transitive Jason dependency for IR serialization.

- [x] Step 2: Run the dependency resolution without changing unrelated locks.

Run:

```sh
mix deps.get
mix deps.tree --only runtime
```

Expected: `live_frames` lists Jason directly, and no Bricks, ACSS, database, Redis, or plugin dependency appears.

- [x] Step 3: Run the existing core tests.

Run: `mix test apps/live_frames`

Expected: the existing three core tests pass before IR code is added.

## Task 2: Write the failing IR contract tests

**File:** `apps/live_frames/test/live_frames/ir_test.exs`

- [x] Step 1: Add a valid document fixture in the test module.

The fixture must contain:

```elixir
node_id = LiveFrames.IR.DesignNode.deterministic_id([1])

node = %LiveFrames.IR.DesignNode{
  node_id: node_id,
  semantic_type: "section",
  semantic_role: "hero",
  content: %{"headline" => "Hello"},
  styles: %{
    "display" => LiveFrames.IR.StyleValue.keyword("flex"),
    "background" => LiveFrames.IR.StyleValue.token_ref("color.neutral.ultra_dark"),
    "gap" => LiveFrames.IR.StyleValue.calculation("var(--space-content)"),
    "custom" => LiveFrames.IR.StyleValue.complex_css(%{"rules" => []})
  },
  responsive: %{
    "tablet_portrait" => %LiveFrames.IR.ResponsiveOverride{
      breakpoint_id: "tablet_portrait",
      source_name: "tablet_portrait",
      resolution_status: :unresolved,
      styles: %{"display" => LiveFrames.IR.StyleValue.keyword("grid")}
    }
  },
  asset_refs: ["asset_001"],
  interaction_refs: ["interaction_001"],
  source_trace: %LiveFrames.IR.SourceTrace{
    source_type: "design_source",
    source_id: "source-1",
    source_settings: %{"display" => "flex"},
    inference: "role inferred from label"
  }
}
```

The document fixture must define matching asset and interaction registries. The interaction targets the node ID. The document must validate successfully.

Use this complete test module fixture and keep the field names in sync with the specification:

```elixir
defmodule LiveFrames.IRTest do
  use ExUnit.Case, async: true

  alias LiveFrames.IR
  alias LiveFrames.IR.AssetReference
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.Interaction
  alias LiveFrames.IR.ResponsiveOverride
  alias LiveFrames.IR.SourceTrace
  alias LiveFrames.IR.StyleValue

  defp valid_document do
    node_id = DesignNode.deterministic_id([1])

    node = %DesignNode{
      node_id: node_id,
      semantic_type: "section",
      semantic_role: "hero",
      content: %{"headline" => "Hello"},
      styles: %{
        "display" => StyleValue.keyword("flex"),
        "background" => StyleValue.token_ref("color.neutral.ultra_dark"),
        "gap" => StyleValue.calculation("var(--space-content)"),
        "custom" => StyleValue.complex_css(%{"rules" => []})
      },
      responsive: %{
        "tablet_portrait" => %ResponsiveOverride{
          breakpoint_id: "tablet_portrait",
          source_name: "tablet_portrait",
          resolution_status: :unresolved,
          styles: %{"display" => StyleValue.keyword("grid")}
        }
      },
      asset_refs: ["asset_001"],
      interaction_refs: ["interaction_001"],
      source_trace: %SourceTrace{
        source_type: "design_source",
        source_id: "source-1",
        source_settings: %{"display" => "flex"},
        inference: "role inferred from label"
      }
    }

    %DesignDocument{
      source_metadata: %{"source" => "fixture"},
      token_set: %{"color.neutral.ultra_dark" => "#050505"},
      root_nodes: [node],
      assets: %{
        "asset_001" => %AssetReference{
          asset_id: "asset_001",
          kind: "image",
          uri: "fixture://hero.png",
          status: :resolved
        }
      },
      interactions: %{
        "interaction_001" => %Interaction{
          interaction_id: "interaction_001",
          intent: "toggle_visibility",
          trigger: "click",
          target_node_ids: [node_id],
          parameters: %{"target" => node_id}
        }
      },
      provenance: %{"source_hash" => "abc123"}
    }
  end

test "deterministic IDs derive from traversal paths" do
  assert DesignNode.deterministic_id([1]) == "node_000001"
  assert DesignNode.deterministic_id([1, 2]) == "node_000001_000002"
  assert DesignNode.deterministic_id([1, 2]) == DesignNode.deterministic_id([1, 2])
end

test "valid IR accepts registries and unresolved responsive entries" do
  assert IR.validate(valid_document()) == :ok
end

test "validation reports duplicate nodes and missing references" do
  node = hd(valid_document().root_nodes)
  invalid_node = %{node | asset_refs: ["missing_asset"], interaction_refs: ["missing_interaction"]}
  document = %{valid_document() | root_nodes: [node, invalid_node]}

  assert {:error, diagnostics} = IR.validate(document)
  codes = Enum.map(diagnostics, & &1.code)

  assert "ir.node.id_duplicate" in codes
  assert "ir.node.asset_reference_missing" in codes
  assert "ir.node.interaction_reference_missing" in codes
end

test "validation reports invalid style values and unresolved breakpoints without source names" do
  node = hd(valid_document().root_nodes)

  invalid_node = %{
    node
    | styles: %{"color" => %StyleValue{kind: :unknown, value: "red"}},
      responsive: %{
        "tablet" => %ResponsiveOverride{
          breakpoint_id: "other",
          resolution_status: :unresolved,
          styles: %{}
        }
      }
  }

  assert {:error, diagnostics} = IR.validate(%{valid_document() | root_nodes: [invalid_node]})
  codes = Enum.map(diagnostics, & &1.code)

  assert "ir.style.kind_invalid" in codes
  assert "ir.responsive.key_mismatch" in codes
  assert "ir.responsive.source_name_missing" in codes
end

test "encoding returns stable JSON with explicit tagged values" do
  assert {:ok, first} = IR.encode(valid_document())
  assert {:ok, second} = IR.encode(valid_document())
  assert first == second
  assert Jason.decode!(first)["ir_version"] == "1.0.0"
  assert get_in(Jason.decode!(first), ["root_nodes", Access.at(0), "styles", "background", "kind"]) ==
           "token_ref"
  refute first =~ "__struct__"
end

test "encoding rejects invalid documents" do
  invalid = %{valid_document() | root_nodes: [%DesignNode{}]}

  assert {:error, diagnostics} = IR.encode(invalid)
  assert Enum.any?(diagnostics, &(&1.code == "ir.node.id_missing"))
end

test "strict validation raises with the collected diagnostics" do
  invalid = %{valid_document() | root_nodes: [%DesignNode{}]}

  assert_raise LiveFrames.IR.ValidationError, fn -> IR.validate!(invalid) end
end
end
```

- [x] Step 3: Run the focused test and confirm the expected red state.

Run: `mix test apps/live_frames/test/live_frames/ir_test.exs`

Expected: compilation fails because the IR modules do not exist yet. Fix only test syntax or dependency setup if the failure is unrelated to the missing implementation.

## Task 3: Implement the data structs and constructors

**Files:** all struct files in the file map

- [x] Step 1: Define the structs with the exact fields in `docs/03_DESIGN_IR_SPEC.md`.

Use JSON-compatible defaults: empty maps for object fields, empty lists for collections, `nil` for optional fields, and `DesignDocument` version `"1.0.0"`.

- [x] Step 2: Implement style constructors.

Each constructor returns `%StyleValue{kind: kind, value: value, ...}` and accepts optional `source_expression`, `source_trace`, and `metadata` keyword options. Provide:

```elixir
StyleValue.literal(value, opts \\ [])
StyleValue.token_ref(path, opts \\ [])
StyleValue.calculation(expression, opts \\ [])
StyleValue.keyword(keyword, opts \\ [])
StyleValue.responsive(value, opts \\ [])
StyleValue.complex_css(rules, opts \\ [])
StyleValue.unresolved(raw_value, opts \\ [])
```

- [x] Step 3: Implement deterministic node IDs and document defaults.

`DesignNode.deterministic_id/1` must accept a non-empty list of positive integers and return the zero-padded path form. Invalid paths raise `ArgumentError`. `DesignDocument.new/1` and `DesignNode.new/2` may provide ergonomic construction but must not bypass later validation.

- [x] Step 4: Run the focused tests.

Run: `mix test apps/live_frames/test/live_frames/ir_test.exs`

Expected: constructor, valid-document, and deterministic-ID tests pass; validation and serialization tests remain red until Tasks 4 and 5 are complete.

## Task 4: Implement validation and diagnostics

**Files:** `diagnostic.ex`, `validation_error.ex`, `validation.ex`, `ir.ex`

- [x] Step 1: Implement stable diagnostic creation.

`Diagnostic.new/1` must normalize severity and category to atoms for the Elixir struct while serialization emits strings. Validation errors must use the `ir.*` code family and the categories in the specification.

- [x] Step 2: Validate the document recursively.

Traverse all roots and children once to collect node IDs, then validate registry references and interaction targets against the collected sets. Do not stop at the first error. Validate JSON metadata recursively and reject non-JSON terms rather than allowing Jason to fail later.

- [x] Step 3: Validate explicit style and responsive values.

Reject unknown style kinds, empty token paths, empty calculations/keywords, malformed complex CSS values, mismatched responsive map keys, and unresolved breakpoint entries without a source name. Preserve unresolved values when their shape is valid.

- [x] Step 4: Add strict helpers.

`IR.validate!/1` returns the original document on success and raises `%IR.ValidationError{diagnostics: diagnostics}` on failure. `ValidationError` must include the diagnostic list in its exception message.

- [x] Step 5: Run focused validation tests.

Run: `mix test apps/live_frames/test/live_frames/ir_test.exs`

Expected: all validation tests pass, including duplicate IDs, missing references, invalid styles, and unresolved breakpoint rejection.

## Task 5: Implement deterministic serialization

**File:** `apps/live_frames/lib/live_frames/ir/serializer.ex`

- [x] Step 1: Convert each struct to an explicit JSON-ready object.

`Serializer.to_map/1` must emit string keys, tagged style values, string severity/category/status fields, registry maps keyed by IDs, and no Elixir struct metadata.

- [x] Step 2: Sort object keys recursively for encoding.

Convert each map to a `Jason.OrderedObject` with keys sorted lexicographically. Preserve list ordering. Do not sort semantic lists such as roots, children, diagnostics, or style rule lists.

- [x] Step 3: Expose encoding through `LiveFrames.IR`.

`IR.to_map/1` delegates to the serializer. `IR.encode/1` validates and returns `{:ok, json}` or `{:error, diagnostics}`. `IR.encode!/1` validates and returns JSON or raises `ValidationError`.

- [x] Step 4: Run serialization tests.

Run: `mix test apps/live_frames/test/live_frames/ir_test.exs`

Expected: stable repeated JSON, explicit `ir_version`, registry objects, and tagged style values all pass.

## Task 6: Complete the Phase 2 gate

**Files:** all Phase 2 files in the file map

- [x] Step 1: Format and run all core tests.

Run:

```sh
mix format
mix test apps/live_frames
```

Expected: no formatting changes remain and all core tests pass.

- [x] Step 2: Run the full umbrella checks and asset build.

Run:

```sh
mix format --check-formatted
mix compile --warnings-as-errors
mix assets.build
mix test
mix deps.unlock --check-unused
git diff --check
```

Expected: all commands exit successfully. The Phase 1 preview tests still pass, and no generated assets are tracked.

- [x] Step 3: Confirm scope boundaries.

Run:

```sh
rg -n "Bricks|Automatic\.css|Hero India|HEEx" apps/live_frames/lib/live_frames/ir apps/live_frames/test/live_frames/ir_test.exs
```

Expected: no source-specific parser or generator module is present. Generic provenance field names and documentation references are allowed; no fixture is consumed by Phase 2 code.

- [x] Step 4: Commit the Phase 2 implementation.

```sh
git add apps/live_frames docs/03_DESIGN_IR_SPEC.md mix.lock
git commit -m "feat: add the versioned Design IR contract"
```

The Phase 2 branch must remain separate from PR #1 until the Phase 0–1 correction PR is reviewed and merged.
