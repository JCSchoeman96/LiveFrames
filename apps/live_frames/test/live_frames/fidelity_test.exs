defmodule LiveFrames.FidelityTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.AutomaticCSS.FidelityResolver
  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Fidelity
  alias LiveFrames.IR.StyleValue

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

  defmodule PropertyAttackResolver do
    @behaviour LiveFrames.Fidelity.SourceResolver

    @properties [
      "color; background:red",
      "color: red",
      "color}\nbody{background:red",
      "background-color\n}",
      "&:hover"
    ]

    @impl true
    def resolve(_classes, _token_set) do
      %{
        resolver_id: "property_attack",
        declarations:
          Enum.map(@properties, fn property ->
            %{
              property: property,
              path: "attack.property",
              value: "property-attack",
              selector: nil
            }
          end),
        consumed_hints: []
      }
    end
  end

  defmodule SelectorAttackResolver do
    @behaviour LiveFrames.Fidelity.SourceResolver

    @selectors ["body", "*", ":root", "& body", "&, body", "}</style>", "&:active"]

    @impl true
    def resolve(_classes, _token_set) do
      %{
        resolver_id: "selector_attack",
        declarations:
          Enum.map(@selectors, fn selector ->
            %{
              property: "color",
              path: "attack.selector",
              value: "selector-attack",
              selector: selector
            }
          end),
        consumed_hints: []
      }
    end
  end

  defmodule SupportedSelectorResolver do
    @behaviour LiveFrames.Fidelity.SourceResolver

    @impl true
    def resolve(_classes, _token_set) do
      %{
        resolver_id: "supported_selectors",
        declarations: [
          %{
            property: "color",
            path: "supported.hover",
            value: "supported-hover",
            selector: "&:hover"
          },
          %{
            property: "outline-color",
            path: "supported.focus",
            value: "supported-focus",
            selector: "&:focus-visible"
          }
        ],
        consumed_hints: []
      }
    end
  end

  defmodule CustomPropertyResolver do
    @behaviour LiveFrames.Fidelity.SourceResolver

    @impl true
    def resolve(_classes, _token_set) do
      %{
        resolver_id: "custom_property",
        declarations: [
          %{
            property: "--lf-context-heading-color",
            path: "custom.heading",
            value: "custom-heading-color",
            selector: nil
          }
        ],
        consumed_hints: []
      }
    end
  end

  defmodule CustomCSSResolver do
    @behaviour LiveFrames.Fidelity.SourceResolver

    @impl true
    def resolve(_classes, _token_set) do
      %{
        resolver_id: "custom_css_attack",
        declarations: [
          %{
            property: "custom-css",
            path: "attack.custom_css",
            value: "</style>\nbody { background: resolver-bypass; }",
            selector: nil
          }
        ],
        consumed_hints: []
      }
    end
  end

  defmodule UnsafeValueResolver do
    @behaviour LiveFrames.Fidelity.SourceResolver

    @impl true
    def resolve(_classes, _token_set) do
      %{
        resolver_id: "unsafe_value",
        declarations: [
          %{
            property: "color",
            path: "attack.value.declaration",
            value: "red; } body { background: resolver-value-attack",
            selector: nil
          },
          %{
            property: "background-image",
            path: "attack.value.https",
            value: "url(https://attacker.example/x)",
            selector: nil
          },
          %{
            property: "background-image",
            path: "attack.value.protocol_relative",
            value: "url(//attacker.example/x)",
            selector: nil
          },
          %{
            property: "background-image",
            path: "attack.value.javascript",
            value: "url(javascript:alert(1))",
            selector: nil
          },
          %{
            property: "background-image",
            path: "attack.value.escaped_https",
            value: "url(\\68ttps://attacker.example/x)",
            selector: nil
          }
        ],
        consumed_hints: []
      }
    end
  end

  defmodule MalformedResolver do
    @behaviour LiveFrames.Fidelity.SourceResolver

    @impl true
    def resolve(_classes, _token_set) do
      %{
        resolver_id: "malformed",
        declarations: [
          nil,
          "not a declaration",
          %{property: 123, value: "resolver-malformed", selector: nil},
          %{property: "color", value: %{}, selector: nil},
          %{value: "resolver-malformed", selector: nil}
        ],
        consumed_hints: []
      }
    end
  end

  defmodule MalformedResultResolver do
    @behaviour LiveFrames.Fidelity.SourceResolver

    @impl true
    def resolve(_classes, _token_set),
      do: %{resolver_id: "malformed_result", declarations: :not_a_list, consumed_hints: []}
  end

  defmodule UnresolvedResolver do
    @behaviour LiveFrames.Fidelity.SourceResolver

    @impl true
    def resolve(_classes, _token_set) do
      %{
        resolver_id: "unresolved",
        declarations: [
          %{property: "color", path: "unresolved.color", value: nil, selector: nil}
        ],
        consumed_hints: []
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

  test "a validated IR document cannot serialize injected property names" do
    document = hero_document()
    root = hd(document.root_nodes)

    styles = %{
      "color; background:red" => StyleValue.literal("property-attack"),
      "color: red" => StyleValue.literal("property-attack"),
      "color}\nbody{background:red" => StyleValue.literal("property-attack"),
      "background-color\n}" => StyleValue.literal("property-attack"),
      "&:hover" => StyleValue.literal("property-attack")
    }

    document = %{document | root_nodes: [%{root | styles: styles} | tl(document.root_nodes)]}

    assert :ok = LiveFrames.IR.validate(document)
    assert {:ok, bundle} = Fidelity.generate(document)
    refute bundle.css =~ "background:red"
    refute bundle.css =~ "body{"
    refute bundle.css =~ "body {"
    refute bundle.css =~ "background-color\n}"
    refute bundle.css =~ "&:hover: property-attack;"

    assert Enum.any?(bundle.manifest["unresolved_declarations"], fn metadata ->
             metadata["origin"] == "ir" and metadata["reason"] == "invalid_css_property"
           end)
  end

  test "source resolver property attacks are omitted and diagnosed" do
    assert {:ok, bundle} =
             Fidelity.generate(hero_document(), source_resolver: PropertyAttackResolver)

    refute bundle.css =~ "background:red"
    refute bundle.css =~ "body{"
    refute bundle.css =~ "background-color\n}"
    refute bundle.css =~ "&:hover: property-attack;"

    assert Enum.any?(bundle.manifest["unresolved_declarations"], fn metadata ->
             metadata["origin"] == "source_resolver" and
               metadata["reason"] == "invalid_css_property"
           end)
  end

  test "source resolver selectors are restricted to the supported state set" do
    assert {:ok, bundle} =
             Fidelity.generate(hero_document(), source_resolver: SelectorAttackResolver)

    refute bundle.css =~ "selector-attack"
    refute bundle.css =~ "</style>"
    refute bundle.css =~ "body {"
    refute bundle.css =~ ":root {"
    refute bundle.css =~ "* {"

    assert Enum.any?(bundle.manifest["unresolved_declarations"], fn metadata ->
             metadata["origin"] == "source_resolver" and
               metadata["reason"] == "unsupported_selector"
           end)
  end

  test "supported source resolver selectors still serialize" do
    assert {:ok, bundle} =
             Fidelity.generate(hero_document(), source_resolver: SupportedSelectorResolver)

    assert bundle.css =~ ".lf-fidelity-node-000001:hover {"
    assert bundle.css =~ ".lf-fidelity-node-000001:focus-visible {"
    assert bundle.css =~ "supported-hover"
    assert bundle.css =~ "supported-focus"
  end

  test "the supported Fidelity custom property still serializes" do
    assert {:ok, bundle} =
             Fidelity.generate(hero_document(), source_resolver: CustomPropertyResolver)

    assert bundle.css =~ "--lf-context-heading-color: custom-heading-color;"
  end

  test "source resolvers cannot use the custom-css sentinel" do
    assert {:ok, bundle} = Fidelity.generate(hero_document(), source_resolver: CustomCSSResolver)

    refute bundle.css =~ "resolver-bypass"
    refute bundle.css =~ "</style>"
    refute bundle.css =~ "body {"

    assert Enum.any?(bundle.manifest["unresolved_declarations"], fn metadata ->
             metadata["origin"] == "source_resolver" and
               metadata["reason"] == "custom_css_forbidden"
           end)
  end

  test "source resolver values receive the final Fidelity safety check" do
    assert {:ok, bundle} =
             Fidelity.generate(hero_document(), source_resolver: UnsafeValueResolver)

    refute bundle.css =~ "resolver-value-attack"
    refute bundle.css =~ "attacker.example"
    refute bundle.css =~ "body {"

    assert Enum.any?(bundle.manifest["unresolved_declarations"], fn metadata ->
             metadata["origin"] == "source_resolver" and
               metadata["reason"] == "unsafe_css_value"
           end)
  end

  test "malformed source resolver declarations do not crash generation" do
    assert {:ok, bundle} = Fidelity.generate(hero_document(), source_resolver: MalformedResolver)

    refute bundle.css =~ "resolver-malformed"

    assert Enum.any?(bundle.manifest["unresolved_declarations"], fn metadata ->
             metadata["origin"] == "source_resolver" and
               metadata["reason"] in [
                 "invalid_declaration_shape",
                 "invalid_css_property",
                 "invalid_css_value",
                 "unsafe_css_value"
               ]
           end)
  end

  test "malformed source resolver results do not crash generation" do
    assert {:ok, bundle} =
             Fidelity.generate(hero_document(), source_resolver: MalformedResultResolver)

    refute bundle.css =~ "malformed_result"

    assert Enum.any?(bundle.manifest["unresolved_declarations"], fn metadata ->
             metadata["origin"] == "source_resolver" and
               metadata["reason"] == "invalid_resolver_result"
           end)
  end

  test "unresolved source resolver values remain non-emitted" do
    assert {:ok, bundle} = Fidelity.generate(hero_document(), source_resolver: UnresolvedResolver)

    refute bundle.css =~ "color: ;"
    assert "unresolved.color" in bundle.manifest["token_paths_consumed"]

    refute Enum.any?(bundle.manifest["unresolved_declarations"], fn metadata ->
             metadata["origin"] == "source_resolver" and
               metadata["reason"] in ["unsafe_css_value", "invalid_css_property"]
           end)
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

  test "rejects escaped external URLs in custom CSS" do
    document = hero_document()
    root = hd(document.root_nodes)

    style =
      StyleValue.complex_css(%{
        "type" => "custom_css",
        "rules" => [".x { background: url(\\68ttps://attacker.example/x); }"]
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
