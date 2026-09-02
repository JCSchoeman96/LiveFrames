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

  test "failure is reachable from every non-terminal resolution state" do
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

    resolution = Resolution.new("node-failure", override)
    assert {:ok, failed_missing} = Resolution.fail(resolution, :authority_lookup_failed)
    assert failed_missing.state == :failed
    assert failed_missing.reason == :authority_lookup_failed
    assert failed_missing.node_id == "node-failure"
    assert failed_missing.raw_styles == override.styles

    assert {:ok, bound} = Resolution.bind(resolution, entry)
    assert {:ok, failed_bound} = Resolution.fail(bound, :value_preparation_failed)
    assert failed_bound.state == :failed
    assert failed_bound.reason == :value_preparation_failed

    assert {:ok, validated} = Resolution.validate_value(bound, [declaration], nil)
    assert {:ok, failed_validated} = Resolution.fail(validated, :resolution_failed)
    assert failed_validated.state == :failed
    assert failed_validated.reason == :resolution_failed

    assert {:ok, resolved} = Resolution.resolve(validated)
    assert {:ok, failed_resolved} = Resolution.fail(resolved, :serialization_preparation_failed)
    assert failed_resolved.state == :failed
    assert failed_resolved.reason == :serialization_preparation_failed
  end

  test "serialized, blocked, rejected, and failed resolutions are terminal" do
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

    resolution = Resolution.new("node-terminal", override)
    assert {:ok, bound} = Resolution.bind(resolution, entry)
    assert {:ok, validated} = Resolution.validate_value(bound, [declaration], nil)
    assert {:ok, resolved} = Resolution.resolve(validated)
    assert {:ok, serialized} = Resolution.serialize(resolved, "  object-fit: cover;")
    assert {:ok, blocked} = Resolution.block(resolution, :authority_missing)
    assert {:ok, rejected} = Resolution.reject(resolution, :invalid_value)
    assert {:ok, failed} = Resolution.fail(resolution, :internal_failure)

    for terminal <- [serialized, blocked, rejected, failed] do
      assert terminal.state in [:serialized, :blocked, :rejected, :failed]
      assert {:error, :invalid_transition} = Resolution.fail(terminal, :late_failure)
      assert {:error, :invalid_transition} = Resolution.block(terminal, :late_block)
      assert {:error, :invalid_transition} = Resolution.reject(terminal, :late_rejection)
    end

    assert {:error, :invalid_transition} = Resolution.fail(resolution, "not_an_atom")
  end
end
