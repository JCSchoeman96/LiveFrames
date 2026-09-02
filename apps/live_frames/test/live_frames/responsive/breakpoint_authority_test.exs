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
             "f4ec88bc3099c0885de5453b4350214843ca99084831fce5057b6d40711749c8"

    assert authority.authority_level == 3
    assert authority.authority_type == "version_matched_default_confirmed_by_source_environment"

    assert {:ok, tablet} =
             BreakpointAuthority.lookup(authority, "tablet_portrait", "tablet_portrait")

    assert tablet.media_condition == "@media (max-width: 991px)"
    assert tablet.max_width == 991

    assert authority
           |> BreakpointAuthority.ordered_entries()
           |> Enum.map(& &1.source_name) == ["tablet_portrait", "mobile_portrait"]
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
