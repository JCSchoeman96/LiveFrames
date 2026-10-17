defmodule LiveFrames.Responsive.FeatureMilanBreakpointAuthorityTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Responsive.BreakpointAuthority

  @authority_path Path.expand(
                    "../../../../../sources/work/feature_milan/fidelity/breakpoint_authority.json",
                    __DIR__
                  )

  test "loads accepted source-confirmed Milan breakpoint authority" do
    assert {:ok, authority} = BreakpointAuthority.from_file(@authority_path)

    assert authority.schema_version == "1.0.0"

    assert authority.authority_hash ==
             "e507d7d6ff33bbb4fb0880d46c44f3b5337d6c95c227154e11510e6a7a2c1b34"

    assert authority.authority_level == 3
    assert authority.authority_type == "direct_source_environment_runtime_confirmed"

    expected = %{
      "tablet_portrait" => {991, "@media (max-width: 991px)", 2},
      "mobile_landscape" => {767, "@media (max-width: 767px)", 3},
      "mobile_portrait" => {478, "@media (max-width: 478px)", 4}
    }

    for {source_name, {width, media_condition, cascade_order}} <- expected do
      entry = authority.breakpoints[source_name]

      assert entry.source_name == source_name
      assert entry.source_width == width
      assert entry.min_width == nil
      assert entry.max_width == width
      assert entry.unit == "px"
      assert entry.query_semantics == "max-width"
      assert entry.media_condition == media_condition
      assert entry.enabled
      assert entry.cascade_order == cascade_order
      assert entry.authority_level == 3
      assert entry.authority_type == "direct_source_environment_runtime_confirmed"
      assert entry.status == "accepted"
    end

    assert Enum.map(BreakpointAuthority.ordered_entries(authority), & &1.source_name) == [
             "tablet_portrait",
             "mobile_landscape",
             "mobile_portrait"
           ]

    raw_authority =
      @authority_path
      |> File.read!()
      |> Jason.decode!()

    assert raw_authority["cascade"]["base_breakpoint"] == %{
             "source_name" => "desktop",
             "source_width" => 1279,
             "unit" => "px",
             "base" => true
           }

    assert raw_authority["cascade"]["source_order"] == [
             "desktop",
             "tablet_portrait",
             "mobile_landscape",
             "mobile_portrait"
           ]

    assert raw_authority["source_context"]["exact_runtime_version"] == "unproven"
    assert raw_authority["source_context"]["acss_l_m_s"] == "unproven"

    assert raw_authority["source_context"]["custom_breakpoints_status"] ==
             "no_custom_breakpoints_observed_in_live_breakpoint_data"

    assert raw_authority["configuration_observations"]["owner_observed_766_reproduced"] == false
    assert raw_authority["configuration_observations"]["acss_l_m_s_mapping_proven"] == false
    assert raw_authority["configuration_observations"]["hero_india_authority_imported"] == false

    assert {:ok, landscape} =
             BreakpointAuthority.lookup(authority, "mobile_landscape", "mobile_landscape")

    assert landscape.source_width == 767
    assert landscape.media_condition == "@media (max-width: 767px)"
    assert landscape.cascade_order == 3
  end

  test "rejects a Milan lookup with the wrong source breakpoint name" do
    assert {:ok, authority} = BreakpointAuthority.from_file(@authority_path)

    assert {:error, :source_breakpoint_mismatch} =
             BreakpointAuthority.lookup(authority, "mobile_landscape", "mobile")
  end
end
