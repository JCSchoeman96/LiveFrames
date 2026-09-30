defmodule LiveFrames.FidelityResponsiveTest do
  use ExUnit.Case, async: false

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.AutomaticCSS.FidelityResolver
  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Fidelity
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.ResponsiveOverride
  alias LiveFrames.IR.StyleValue
  alias LiveFrames.Responsive.BreakpointAuthority

  @bricks_path Path.expand("../../../../fixtures/bricks/bricks_components.json", __DIR__)
  @acss_path Path.expand("../../../../fixtures/automatic_css/acss_settings.json", __DIR__)
  @authority_path Path.expand(
                    "../../../../sources/work/hero_india/fidelity/breakpoint_authority.json",
                    __DIR__
                  )

  @tablet_media "@media (max-width: 991px)"
  @landscape_media "@media (max-width: 767px)"
  @portrait_media "@media (max-width: 478px)"
  @authority_hash "5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0"

  test "resolves all four Hero responsive entries through committed authority" do
    assert {:ok, bundle} = generate_with_authority()

    assert bundle.css =~ @tablet_media
    assert bundle.css =~ @portrait_media
    assert :binary.match(bundle.css, @tablet_media) < :binary.match(bundle.css, @portrait_media)
    assert bundle.css =~ "object-fit: cover;"
    assert bundle.css =~ "object-position: 50% 50%;"
    assert bundle.css =~ "linear-gradient(180deg, hsla(0, 0%, 0%, 0) 5%"
    assert bundle.css =~ ".fr-cta-links-alpha > * {\n  width: 100% !important;\n}"

    assert bundle.manifest["responsive_entries_total"] == 4
    assert bundle.manifest["responsive_entries_resolved"] == 4
    assert bundle.manifest["responsive_entries_deferred_for_authority"] == 0
    assert bundle.manifest["invented_breakpoints"] == 0
    assert bundle.manifest["deferred_responsive_count"] == 0
    assert bundle.manifest["deferred_responsive_entries"] == []

    authority_manifest = bundle.manifest["responsive_breakpoint_authority"]
    assert authority_manifest["schema_version"] == "1.0.0"
    assert authority_manifest["authority_hash"] == @authority_hash
    assert authority_manifest["authority_level"] == 3

    assert authority_manifest["authority_type"] ==
             "version_matched_default_confirmed_by_source_environment"

    assert authority_manifest["source_names"] == ["tablet_portrait", "mobile_portrait"]
    assert authority_manifest["media_conditions"] == [@tablet_media, @portrait_media]
  end

  test "serializes overlapping max-width media queries in authority cascade order" do
    assert {:ok, authority} = BreakpointAuthority.from_file(@authority_path)

    assert {:ok, bundle} =
             Fidelity.generate(overlap_document(),
               source_resolver: FidelityResolver,
               responsive_authority: authority
             )

    assert bundle.css =~ @tablet_media
    assert bundle.css =~ @landscape_media
    assert bundle.css =~ @portrait_media

    assert :binary.match(bundle.css, @tablet_media) <
             :binary.match(bundle.css, @landscape_media)

    assert :binary.match(bundle.css, @landscape_media) <
             :binary.match(bundle.css, @portrait_media)

    authority_manifest = bundle.manifest["responsive_breakpoint_authority"]

    assert authority_manifest["source_names"] == [
             "tablet_portrait",
             "mobile_landscape",
             "mobile_portrait"
           ]

    assert authority_manifest["media_conditions"] == [
             @tablet_media,
             @landscape_media,
             @portrait_media
           ]
  end

  test "overlapping width overrides emit 991, 767, and 478 media blocks in cascade order" do
    assert {:ok, authority} = BreakpointAuthority.from_file(@authority_path)

    assert {:ok, bundle} =
             Fidelity.generate(overlap_document(),
               source_resolver: FidelityResolver,
               responsive_authority: authority
             )

    tablet_pos = :binary.match(bundle.css, @tablet_media)
    landscape_pos = :binary.match(bundle.css, @landscape_media)
    portrait_pos = :binary.match(bundle.css, @portrait_media)

    assert tablet_pos < landscape_pos
    assert landscape_pos < portrait_pos

    assert bundle.css =~ "#{@tablet_media} {\n.lf-fidelity-node-000001 {\n  width: tablet-value;"

    assert bundle.css =~
             "#{@landscape_media} {\n.lf-fidelity-node-000001 {\n  width: landscape-value;"

    assert bundle.css =~
             "#{@portrait_media} {\n.lf-fidelity-node-000001 {\n  width: portrait-value;"

    assert bundle.css =~ ".lf-fidelity-node-000001 {\n  width: base-value;\n}"
  end

  test "responsive generation is deterministic" do
    assert {:ok, first} = generate_with_authority()
    assert {:ok, second} = generate_with_authority()

    assert first.heex == second.heex
    assert first.css == second.css
    assert first.manifest == second.manifest
  end

  test "responsive media serialization uses the supplied authority semantics" do
    assert {:ok, document} = hero_document()
    assert {:ok, authority_map} = authority_map()

    authority_map =
      authority_map
      |> put_in(["breakpoints", "tablet_portrait", "source_width"], 900)
      |> put_in(["breakpoints", "tablet_portrait", "max_width"], 900)
      |> put_in(
        ["breakpoints", "tablet_portrait", "media_condition"],
        "@media (max-width: 900px)"
      )

    assert {:ok, authority} = BreakpointAuthority.from_map(authority_map)

    assert {:ok, bundle} =
             Fidelity.generate(document,
               source_resolver: FidelityResolver,
               responsive_authority: authority
             )

    assert bundle.css =~ "@media (max-width: 900px)"
    refute bundle.css =~ @tablet_media

    assert bundle.manifest["responsive_breakpoint_authority"]["media_conditions"] == [
             "@media (max-width: 900px)",
             @portrait_media
           ]
  end

  test "missing authority defers only the affected responsive entry" do
    assert {:ok, document} = hero_document()
    assert {:ok, authority_map} = authority_map()

    authority_map = update_in(authority_map, ["breakpoints"], &Map.delete(&1, "mobile_portrait"))
    assert {:ok, authority} = BreakpointAuthority.from_map(authority_map)

    assert {:ok, bundle} =
             Fidelity.generate(document,
               source_resolver: FidelityResolver,
               responsive_authority: authority
             )

    assert bundle.css =~ @tablet_media
    refute bundle.css =~ @portrait_media
    assert bundle.manifest["responsive_entries_total"] == 4
    assert bundle.manifest["responsive_entries_resolved"] == 3
    assert bundle.manifest["responsive_entries_deferred_for_authority"] == 1

    assert Enum.any?(bundle.manifest["unresolved_declarations"], fn entry ->
             entry["reason"] == "authority_missing"
           end)
  end

  defp generate_with_authority do
    with {:ok, document} <- hero_document(),
         {:ok, authority} <- BreakpointAuthority.from_file(@authority_path) do
      Fidelity.generate(document,
        source_resolver: FidelityResolver,
        responsive_authority: authority
      )
    end
  end

  defp overlap_document do
    node_id = DesignNode.deterministic_id([1])

    %DesignDocument{
      root_nodes: [
        %DesignNode{
          node_id: node_id,
          semantic_type: "generic",
          content: %{},
          attributes: %{},
          styles: %{"width" => StyleValue.literal("base-value")},
          responsive: %{
            "tablet_portrait" => %ResponsiveOverride{
              breakpoint_id: "tablet_portrait",
              source_name: "tablet_portrait",
              resolution_status: :unresolved,
              styles: %{"width" => StyleValue.literal("tablet-value")}
            },
            "mobile_landscape" => %ResponsiveOverride{
              breakpoint_id: "mobile_landscape",
              source_name: "mobile_landscape",
              resolution_status: :unresolved,
              styles: %{"width" => StyleValue.literal("landscape-value")}
            },
            "mobile_portrait" => %ResponsiveOverride{
              breakpoint_id: "mobile_portrait",
              source_name: "mobile_portrait",
              resolution_status: :unresolved,
              styles: %{"width" => StyleValue.literal("portrait-value")}
            }
          },
          children: []
        }
      ]
    }
  end

  defp hero_document do
    with {:ok, token_set, _diagnostics} <-
           AutomaticCSS.from_file(
             @acss_path,
             source_version: "4.0.1",
             source_version_status: "fixture_reference",
             strict: true,
             profile: :hero_foundation
           ),
         {:ok, document} <-
           Bricks.to_ir(@bricks_path, component_id: "sqhmmc", token_set: token_set) do
      {:ok, document}
    end
  end

  defp authority_map do
    @authority_path
    |> File.read!()
    |> Jason.decode()
  end
end
