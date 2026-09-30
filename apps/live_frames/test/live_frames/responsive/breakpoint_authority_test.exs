defmodule LiveFrames.Responsive.BreakpointAuthorityTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Responsive.BreakpointAuthority

  @authority_path Path.expand(
                    "../../../../../sources/work/hero_india/fidelity/breakpoint_authority.json",
                    __DIR__
                  )

  test "loads accepted authority with deterministic lookup and cascade order" do
    assert {:ok, authority} = BreakpointAuthority.from_file(@authority_path)

    assert authority.schema_version == "1.0.0"

    assert authority.authority_hash ==
             "5c9f891da7915fc8d9b94ff9bd74338f4b9e9995341296c324a339b84162bfd0"

    assert authority.authority_level == 3
    assert authority.authority_type == "version_matched_default_confirmed_by_source_environment"

    assert {:ok, tablet} =
             BreakpointAuthority.lookup(authority, "tablet_portrait", "tablet_portrait")

    assert tablet.media_condition == "@media (max-width: 991px)"
    assert tablet.max_width == 991

    assert {:ok, landscape} =
             BreakpointAuthority.lookup(authority, "mobile_landscape", "mobile_landscape")

    assert landscape.media_condition == "@media (max-width: 767px)"
    assert landscape.max_width == 767

    assert {:ok, mobile} =
             BreakpointAuthority.lookup(authority, "mobile_portrait", "mobile_portrait")

    assert mobile.media_condition == "@media (max-width: 478px)"
    assert mobile.max_width == 478

    assert authority
           |> BreakpointAuthority.ordered_entries()
           |> Enum.map(& &1.source_name) == [
             "tablet_portrait",
             "mobile_landscape",
             "mobile_portrait"
           ]
  end

  test "requires exact breakpoint identity and rejects missing authority" do
    assert {:ok, authority} = BreakpointAuthority.from_file(@authority_path)

    assert {:error, :source_breakpoint_mismatch} =
             BreakpointAuthority.lookup(authority, "tablet_portrait", "tablet")

    assert {:error, :authority_missing} =
             BreakpointAuthority.lookup(authority, "desktop", "desktop")
  end

  test "rejects authority media conditions that do not match numeric semantics" do
    authority_map =
      @authority_path
      |> File.read!()
      |> Jason.decode!()
      |> put_in(["breakpoints", "tablet_portrait", "media_condition"], "@media body")

    assert {:error, :invalid_media_condition} = BreakpointAuthority.from_map(authority_map)
  end

  test "revalidates authority structs before responsive serialization" do
    assert {:ok, authority} = BreakpointAuthority.from_file(@authority_path)

    tablet = authority.breakpoints["tablet_portrait"]

    authority = %{
      authority
      | breakpoints: %{
          authority.breakpoints
          | "tablet_portrait" => %{tablet | media_condition: "@media body"}
        }
    }

    assert {:error, :invalid_media_condition} = BreakpointAuthority.coerce(authority)
  end
end
