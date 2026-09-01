defmodule LiveFrames.FidelityTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.AutomaticCSS.FidelityResolver
  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Fidelity

  defmodule FakeResolver do
    @behaviour LiveFrames.Fidelity.SourceResolver

    @impl true
    def resolve(_classes, _token_set) do
      %{
        resolver_id: "fake",
        declarations: [
          %{property: "outline", path: "fake.outline", value: "1px solid red", selector: nil}
        ],
        consumed_hints: ["fake-hint"]
      }
    end
  end

  @bricks_path Path.expand("../../../../fixtures/bricks/bricks_components.json", __DIR__)
  @acss_path Path.expand("../../../../fixtures/automatic_css/acss_settings.json", __DIR__)

  test "generates safe deterministic base fidelity artifacts for Hero IR" do
    document = hero_document()
    assert {:ok, first} = Fidelity.generate(document)
    assert {:ok, second} = Fidelity.generate(document)
    assert first == second
    assert first.manifest["node_count"] == 10
    assert first.manifest["generated_element_count"] == 10
    assert first.manifest["deferred_responsive_count"] == 4
    assert first.manifest["invented_breakpoint_count"] == 0
    assert first.heex =~ "<section"
    assert first.heex =~ "<button class="
    assert first.heex =~ "type=\"button\""
    assert first.heex =~ "lf-fidelity-node-000001"
    assert first.heex =~ "Call to action"
    assert first.css =~ "linear-gradient"
    refute first.css =~ "@media"
    assert first.manifest["asset_substitutions"] |> hd() |> Map.fetch!("status") == "unresolved"
  end

  test "generic generation uses a no-op resolver by default" do
    assert {:ok, bundle} = Fidelity.generate(hero_document())

    assert bundle.manifest["source_fidelity_resolver"] == "noop"
    assert bundle.manifest["source_fidelity_hints_consumed"] == []
    refute bundle.css =~ "button.primary.background"
    refute bundle.css =~ "background-color: hsl(0 0% 10%)"
  end

  test "generic generation uses the caller-provided source resolver" do
    assert {:ok, bundle} = Fidelity.generate(hero_document(), source_resolver: FakeResolver)

    assert bundle.css =~ "outline: 1px solid red;"
    assert bundle.manifest["source_fidelity_resolver"] == "fake"
    assert bundle.manifest["source_fidelity_hints_consumed"] == ["fake-hint"]
  end

  test "Automatic.css reports only hints actually consumed" do
    token_set = hero_document().token_set

    assert FidelityResolver.resolve(["fr-example"], token_set).consumed_hints == []

    assert FidelityResolver.resolve(["btn--primary", "other"], token_set).consumed_hints == [
             "btn--primary"
           ]

    assert FidelityResolver.resolve(
             ["btn--outline", "bg--ultra-dark", "btn--primary"],
             token_set
           ).consumed_hints == ["bg--ultra-dark", "btn--primary", "btn--outline"]
  end

  test "escapes source content and rejects invalid IR" do
    document = hero_document()
    node = hd(document.root_nodes)
    container = hd(node.children)
    heading = hd(container.children)
    malicious = %{heading | content: ~s(<script>{@x} "quoted" & </h1>)}
    container = %{container | children: [malicious | tl(container.children)]}
    document = %{document | root_nodes: [%{node | children: [container | tl(node.children)]}]}
    assert {:ok, bundle} = Fidelity.generate(document)
    assert bundle.heex =~ "<%= #{inspect(malicious.content)} %>"
    refute bundle.heex =~ "Phoenix.HTML.raw"

    assert {:error, diagnostics} = Fidelity.generate(%{document | ir_version: "2.0.0"})
    assert Enum.any?(diagnostics, &(&1.code == "ir.document.version_unsupported"))
  end

  test "rejects unsafe CSS values and diagnoses unsafe source classes" do
    document = hero_document()
    root = hd(document.root_nodes)
    unsafe_trace = %{root.source_trace | source_classes: ["safe", "bad class"]}

    unsafe_root = %{
      root
      | source_trace: unsafe_trace,
        styles: %{"color" => LiveFrames.IR.StyleValue.literal("red; } .attacker { color: red")}
    }

    document = %{document | root_nodes: [unsafe_root | tl(document.root_nodes)]}

    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.css =~ ".attacker"
    refute bundle.css =~ "red; }"
    assert bundle.manifest["diagnostic_counts"]["warning"] > 0
  end

  test "rejects protocol-relative custom CSS URLs" do
    document = hero_document()
    root = hd(document.root_nodes)

    style =
      LiveFrames.IR.StyleValue.complex_css(%{
        "type" => "custom_css",
        "rules" => [".x { background: url(//attacker.example/x); }"]
      })

    document = %{document | root_nodes: [%{root | styles: %{"custom-css" => style}}]}

    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.css =~ "attacker.example"
    assert bundle.manifest["diagnostic_counts"]["warning"] > 0
  end

  test "applies CSS safety policy to scalar and unknown complex values" do
    document = hero_document()
    root = hd(document.root_nodes)
    unsafe = LiveFrames.IR.StyleValue.literal("url(https://attacker.example/x)")
    unknown = LiveFrames.IR.StyleValue.complex_css(%{"secret" => "} .attacker {"})

    document = %{
      document
      | root_nodes: [%{root | styles: %{"color" => unsafe, "unknown" => unknown}}]
    }

    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.css =~ "attacker.example"
    refute bundle.css =~ "secret"
    assert bundle.manifest["diagnostic_counts"]["warning"] >= 2
  end

  test "omits malformed gradients and unknown custom CSS structures" do
    document = hero_document()
    root = hd(document.root_nodes)
    malformed_gradient = LiveFrames.IR.StyleValue.complex_css(%{"type" => "gradient"})

    unknown_custom =
      LiveFrames.IR.StyleValue.complex_css(%{"type" => "future_css", "value" => "}"})

    document = %{
      document
      | root_nodes: [
          %{
            root
            | styles: %{"background-image" => malformed_gradient, "custom-css" => unknown_custom}
          }
        ]
    }

    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.css =~ "future_css"
    refute bundle.css =~ "type"
    assert bundle.manifest["diagnostic_counts"]["warning"] >= 2
  end

  test "does not emit unsafe gradient fields or resolver token values" do
    document = hero_document()
    root = hd(document.root_nodes)

    gradient =
      LiveFrames.IR.StyleValue.complex_css(%{
        "type" => "gradient",
        "value" => %{
          "angle" => "90; } .attacker {",
          "colors" => [%{"color" => %{"raw" => "url(https://attacker.example)"}, "stop" => "0"}]
        }
      })

    tokens =
      put_in(
        document.token_set,
        ["tokens", "color.background.ultra_dark", "resolved_value"],
        "url(//attacker.example)"
      )

    document = %{
      document
      | token_set: tokens,
        root_nodes: [%{root | styles: %{"background-image" => gradient}}]
    }

    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.css =~ "attacker"
    refute bundle.css =~ "90;"
  end

  defp hero_document do
    {:ok, token_set, _} =
      AutomaticCSS.from_file(@acss_path,
        source_version: "4.0.1",
        source_version_status: "fixture_reference",
        strict: true,
        profile: :hero_foundation
      )

    {:ok, document} = Bricks.to_ir(@bricks_path, component_id: "sqhmmc", token_set: token_set)
    document
  end
end
