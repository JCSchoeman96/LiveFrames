defmodule LiveFrames.AutomaticCSSStructuralVariablesTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.AutomaticCSS.StructuralVariables
  alias LiveFrames.Styles.StructuralVariableAuthority

  test "ACSS 4.0.1 authority supplies the proven --grid-1 mapping when enabled" do
    assert {:ok, index} =
             StructuralVariables.authority("4.0.1", grid_variables_enabled: true)

    assert %{
             state: :unique_candidate,
             variable: "--grid-1",
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

  test "disabled grid variables produce no structural authority" do
    assert {:ok, index} =
             StructuralVariables.authority("4.0.1", grid_variables_enabled: false)

    assert StructuralVariableAuthority.resolve(index, "--grid-1").state == :no_authority
  end

  test "rejects unsupported Automatic.css versions" do
    assert {:error, :unsupported_source_version} =
             StructuralVariables.authority("4.0.0-rc-1", grid_variables_enabled: true)
  end
end
