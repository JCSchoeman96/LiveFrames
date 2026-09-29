defmodule LiveFrames.AutomaticCSSStructuralVariablesTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS.StructuralVariables
  alias LiveFrames.Styles.StructuralVariableAuthority

  test "4.0.1 with explicit grid_variables_enabled true includes --grid-1" do
    assert {:ok, index} =
             StructuralVariables.authority("4.0.1", grid_variables_enabled: true)

    assert StructuralVariableAuthority.resolve(index, "--grid-1").state == :unique_candidate
  end

  test "4.0.1 with settings option-grid-variables on includes --grid-1" do
    assert {:ok, index} =
             StructuralVariables.authority("4.0.1",
               settings: %{"option-grid-variables" => "on"}
             )

    assert StructuralVariableAuthority.resolve(index, "--grid-1").state == :unique_candidate
  end

  test "4.0.1 with explicit false returns an empty authority index" do
    assert {:ok, index} =
             StructuralVariables.authority("4.0.1", grid_variables_enabled: false)

    assert StructuralVariableAuthority.resolve(index, "--grid-1").state == :no_authority
  end

  test "4.0.1 with no options returns an empty authority index" do
    assert {:ok, index} = StructuralVariables.authority("4.0.1", [])

    assert StructuralVariableAuthority.resolve(index, "--grid-1").state == :no_authority
  end

  test "4.0.1 with settings missing option-grid-variables returns no authority" do
    assert {:ok, index} =
             StructuralVariables.authority("4.0.1", settings: %{"option-grid" => "on"})

    assert StructuralVariableAuthority.resolve(index, "--grid-1").state == :no_authority
  end

  test "4.0.1 with settings option off returns no authority" do
    assert {:ok, index} =
             StructuralVariables.authority("4.0.1",
               settings: %{"option-grid-variables" => "off"}
             )

    assert StructuralVariableAuthority.resolve(index, "--grid-1").state == :no_authority
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
