defmodule LiveFrames.Responsive.DesignDocumentResolverTest do
  use ExUnit.Case, async: true

  alias LiveFrames.IR
  alias LiveFrames.IR.{DesignDocument, DesignNode, ResponsiveOverride, SourceTrace, StyleValue}
  alias LiveFrames.Responsive.BreakpointAuthority
  alias LiveFrames.Responsive.DesignDocumentResolver

  test "binds tablet portrait to its validated max width" do
    override = unresolved("tablet_portrait", %{"display" => StyleValue.keyword("grid")})
    document = document(override)

    assert {:ok, resolved} = DesignDocumentResolver.resolve(document, authority())
    [node] = resolved.root_nodes
    bound = node.responsive["tablet_portrait"]

    assert bound.max_width == 991
    assert bound.min_width == nil
    assert bound.resolution_status == :resolved
    assert bound.styles == override.styles
    assert bound.source_trace == override.source_trace
    assert IR.validate(resolved) == :ok
  end

  test "binds mobile landscape to its validated max width" do
    override = unresolved("mobile_landscape", %{"width" => StyleValue.literal("100%")})

    assert {:ok, resolved} =
             document(override)
             |> DesignDocumentResolver.resolve(authority())

    [node] = resolved.root_nodes
    bound = node.responsive["mobile_landscape"]

    assert bound.max_width == 767
    assert bound.min_width == nil
    assert bound.resolution_status == :resolved
    assert bound.styles == override.styles
  end

  test "fails closed when authority is missing" do
    override = unresolved("desktop", %{"display" => StyleValue.keyword("grid")})

    assert {:error, diagnostic} =
             document(override)
             |> DesignDocumentResolver.resolve(authority())

    assert diagnostic.code == "design_document_resolver.authority_missing"

    assert diagnostic.metadata == %{
             "breakpoint_id" => "desktop",
             "node_id" => "node_000001",
             "source_name" => "desktop"
           }
  end

  test "fails closed when breakpoint authority is invalid" do
    override = unresolved("tablet_portrait", %{"display" => StyleValue.keyword("grid")})

    assert {:error, diagnostic} =
             document(override)
             |> DesignDocumentResolver.resolve(%{})

    assert diagnostic.code == "design_document_resolver.authority_invalid"
  end

  test "fails closed when the source name differs from accepted authority" do
    override = %{
      unresolved("tablet_portrait", %{"display" => StyleValue.keyword("grid")})
      | source_name: "tablet"
    }

    assert {:error, diagnostic} =
             document(override)
             |> DesignDocumentResolver.resolve(authority())

    assert diagnostic.code == "design_document_resolver.source_breakpoint_mismatch"
  end

  test "fails when an already-resolved range conflicts with matching authority" do
    override = %ResponsiveOverride{
      breakpoint_id: "tablet_portrait",
      source_name: "tablet_portrait",
      max_width: 992,
      resolution_status: :resolved,
      styles: %{"display" => StyleValue.keyword("grid")}
    }

    assert {:error, diagnostic} =
             document(override)
             |> DesignDocumentResolver.resolve(authority())

    assert diagnostic.code == "design_document_resolver.resolved_authority_conflict"
  end

  test "rejects a resolved override with no matching authority entry" do
    override = %ResponsiveOverride{
      breakpoint_id: "legacy_tablet",
      source_name: "legacy_tablet",
      max_width: 900,
      resolution_status: :resolved,
      styles: %{"display" => StyleValue.keyword("grid")}
    }

    assert {:error, diagnostic} =
             document(override)
             |> DesignDocumentResolver.resolve(authority())

    assert diagnostic.code == "design_document_resolver.authority_missing"

    assert diagnostic.metadata == %{
             "breakpoint_id" => "legacy_tablet",
             "node_id" => "node_000001",
             "source_name" => "legacy_tablet"
           }
  end

  test "preserves an already-resolved range that matches accepted authority" do
    override = %ResponsiveOverride{
      breakpoint_id: "tablet_portrait",
      source_name: "tablet_portrait",
      max_width: 991,
      resolution_status: :resolved,
      styles: %{"display" => StyleValue.keyword("grid")}
    }

    assert {:ok, resolved} =
             document(override)
             |> DesignDocumentResolver.resolve(authority())

    [node] = resolved.root_nodes
    assert node.responsive["tablet_portrait"] == override
  end

  test "rejects an internally invalid already-resolved range" do
    override = %ResponsiveOverride{
      breakpoint_id: "tablet_portrait",
      source_name: "tablet_portrait",
      resolution_status: :resolved,
      styles: %{"display" => StyleValue.keyword("grid")}
    }

    assert {:error, diagnostic} =
             document(override)
             |> DesignDocumentResolver.resolve(authority())

    assert diagnostic.code == "design_document_resolver.input_invalid"
  end

  test "does not mutate the input and resolves equal inputs deterministically" do
    original_override = unresolved("tablet_portrait", %{"display" => StyleValue.keyword("grid")})
    original_document = document(original_override)

    assert {:ok, first} = DesignDocumentResolver.resolve(original_document, authority())
    assert {:ok, second} = DesignDocumentResolver.resolve(original_document, authority())

    assert original_document.root_nodes |> hd() |> Map.fetch!(:responsive) == %{
             "tablet_portrait" => original_override
           }

    assert first == second
    assert IR.encode!(first) == IR.encode!(second)
  end

  defp unresolved(name, styles) do
    %ResponsiveOverride{
      breakpoint_id: name,
      source_name: name,
      resolution_status: :unresolved,
      styles: styles,
      source_trace: %SourceTrace{source_type: "fixture", source_name: name}
    }
  end

  defp document(override) do
    %DesignDocument{
      root_nodes: [
        %DesignNode{
          node_id: DesignNode.deterministic_id([1]),
          semantic_type: "section",
          responsive: %{override.breakpoint_id => override}
        }
      ]
    }
  end

  defp authority do
    entries = [
      {"tablet_portrait", 991, 1},
      {"mobile_landscape", 767, 2}
    ]

    breakpoints =
      Map.new(entries, fn {name, width, order} ->
        {name,
         %{
           "source_name" => name,
           "source_width" => width,
           "min_width" => nil,
           "max_width" => width,
           "unit" => "px",
           "query_semantics" => "max-width",
           "media_condition" => "@media (max-width: #{width}px)",
           "enabled" => true,
           "cascade_order" => order,
           "authority_level" => 3,
           "authority_type" => "version_matched_default_confirmed_by_source_environment",
           "status" => "accepted"
         }}
      end)

    {:ok, validated} =
      BreakpointAuthority.from_map(%{
        "schema_version" => "1.0.0",
        "authority_status" => "accepted",
        "authority_level" => 3,
        "authority_type" => "version_matched_default_confirmed_by_source_environment",
        "breakpoints" => breakpoints,
        "cascade" => %{"ordering" => "descending_width"}
      })

    validated
  end
end
