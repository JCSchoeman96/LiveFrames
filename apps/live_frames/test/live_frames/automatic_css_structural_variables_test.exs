defmodule LiveFrames.AutomaticCSSStructuralVariablesTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS.StructuralVariables
  alias LiveFrames.Styles.StructuralVariableAuthority

  @grid_contracts %{
    "--grid-1" => %{
      resolved_value: "repeat(1, minmax(0, 1fr))",
      authority_id: "automatic-css-4.0.1:structural-grid:grid-1"
    },
    "--grid-2" => %{
      resolved_value: "repeat(2, minmax(0, 1fr))",
      authority_id: "automatic-css-4.0.1:structural-grid:grid-2"
    },
    "--grid-3-2" => %{
      resolved_value: "minmax(0, 3fr) minmax(0, 2fr)",
      authority_id: "automatic-css-4.0.1:structural-grid:grid-3-2"
    }
  }

  @grid_variables Map.keys(@grid_contracts)

  defp assert_enabled_authority(index) do
    assert map_size(index.by_variable) == 3

    for variable <- @grid_variables do
      %{resolved_value: resolved_value, authority_id: authority_id} =
        Map.fetch!(@grid_contracts, variable)

      assert %{
               state: :unique_candidate,
               candidates: [
                 %{
                   resolved_value: resolved_value,
                   authority_id: authority_id,
                   source_system: "automatic_css",
                   source_version: "4.0.1",
                   authority_type: "PROJECT_SOURCE_ENVIRONMENT_GENERATED_CSS"
                 }
               ]
             } = StructuralVariableAuthority.resolve(index, variable)
    end
  end

  defp assert_no_grid_authority(index) do
    for variable <- @grid_variables do
      assert StructuralVariableAuthority.resolve(index, variable).state == :no_authority
    end
  end

  test "4.0.1 with explicit grid_variables_enabled true includes exactly three grid variables" do
    assert {:ok, index} =
             StructuralVariables.authority("4.0.1", grid_variables_enabled: true)

    assert_enabled_authority(index)
  end

  test "4.0.1 with settings option-grid-variables on includes exactly three grid variables" do
    assert {:ok, index} =
             StructuralVariables.authority("4.0.1",
               settings: %{"option-grid-variables" => "on"}
             )

    assert_enabled_authority(index)
  end

  test "4.0.1 with explicit false returns an empty authority index" do
    assert {:ok, index} =
             StructuralVariables.authority("4.0.1", grid_variables_enabled: false)

    assert map_size(index.by_variable) == 0
    assert_no_grid_authority(index)
  end

  test "4.0.1 with no options returns an empty authority index" do
    assert {:ok, index} = StructuralVariables.authority("4.0.1", [])

    assert_no_grid_authority(index)
  end

  test "4.0.1 with malformed non-map settings returns no authority" do
    assert {:ok, index} = StructuralVariables.authority("4.0.1", settings: "not-a-map")

    assert_no_grid_authority(index)
  end

  test "4.0.1 with settings missing option-grid-variables returns no authority" do
    assert {:ok, index} =
             StructuralVariables.authority("4.0.1", settings: %{"option-grid" => "on"})

    assert_no_grid_authority(index)
  end

  test "4.0.1 with settings option off returns no authority" do
    assert {:ok, index} =
             StructuralVariables.authority("4.0.1",
               settings: %{"option-grid-variables" => "off"}
             )

    assert_no_grid_authority(index)
  end

  test "unsupported versions return an error" do
    assert {:error, :unsupported_source_version} =
             StructuralVariables.authority("4.0.0-rc-1", grid_variables_enabled: true)
  end

  test "metadata for the enabled mapping matches the proven contract" do
    assert {:ok, index} =
             StructuralVariables.authority("4.0.1", grid_variables_enabled: true)

    assert %{
             state: :unique_candidate,
             candidates: [
               %{
                 resolved_value: "repeat(1, minmax(0, 1fr))",
                 authority_id: "automatic-css-4.0.1:structural-grid:grid-1",
                 source_system: "automatic_css",
                 source_version: "4.0.1"
               }
             ]
           } = StructuralVariableAuthority.resolve(index, "--grid-1")
  end
end
