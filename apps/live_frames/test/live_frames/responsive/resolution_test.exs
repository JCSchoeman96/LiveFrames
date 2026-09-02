defmodule LiveFrames.Responsive.ResolutionTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Fidelity.CSSDeclaration
  alias LiveFrames.IR.ResponsiveOverride
  alias LiveFrames.Responsive.BreakpointAuthority
  alias LiveFrames.Responsive.Resolution

  @authority_path Path.expand(
                    "../../../../../sources/work/hero_india/fidelity/breakpoint_authority.json",
                    __DIR__
                  )

  test "models authority binding through serialized terminal state" do
    assert {:ok, authority} = BreakpointAuthority.from_file(@authority_path)

    assert {:ok, entry} =
             BreakpointAuthority.lookup(authority, "tablet_portrait", "tablet_portrait")

    override = %ResponsiveOverride{
      breakpoint_id: "tablet_portrait",
      source_name: "tablet_portrait",
      styles: %{}
    }

    declaration = %CSSDeclaration{
      property: "object-fit",
      value: "cover",
      selector: nil,
      state: :accepted
    }

    resolution = Resolution.new("node-1", override)
    assert resolution.state == :authority_missing

    assert {:ok, bound} = Resolution.bind(resolution, entry)
    assert bound.state == :authority_bound
    assert bound.media_condition == "@media (max-width: 991px)"

    assert {:ok, validated} = Resolution.validate_value(bound, [declaration], nil)
    assert validated.state == :value_validated

    assert {:ok, resolved} = Resolution.resolve(validated)
    assert resolved.state == :resolved

    assert {:ok, serialized} = Resolution.serialize(resolved, "  object-fit: cover;")
    assert serialized.state == :serialized
    assert serialized.serialized_css == "  object-fit: cover;"
  end

  test "records nil responsive values as blocked rather than inventing output" do
    override = %ResponsiveOverride{
      breakpoint_id: "tablet_portrait",
      source_name: "tablet_portrait",
      styles: %{}
    }

    resolution = Resolution.new("node-1", override)
    assert {:ok, blocked} = Resolution.block(resolution, :value_unresolved)
    assert blocked.state == :blocked
    assert blocked.reason == :value_unresolved
  end
end
