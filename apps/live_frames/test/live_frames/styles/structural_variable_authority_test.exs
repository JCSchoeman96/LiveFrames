defmodule LiveFrames.Styles.StructuralVariableAuthorityTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Styles.StructuralVariableAuthority

  defp record(overrides \\ %{}) do
    Map.merge(
      %{
        "variable" => "--grid-1",
        "resolved_value" => "repeat(1, minmax(0, 1fr))",
        "authority_id" => "automatic-css-4.0.1:structural-grid:grid-1",
        "source_system" => "automatic_css",
        "source_version" => "4.0.1",
        "authority_type" => "PROJECT_SOURCE_ENVIRONMENT_GENERATED_CSS"
      },
      overrides
    )
  end

  defp build!(records) do
    assert {:ok, index} = StructuralVariableAuthority.build(records)
    index
  end

  test "unknown variable returns no authority" do
    index = build!([])

    assert StructuralVariableAuthority.resolve(index, "--unknown") == %{
             state: :no_authority,
             variable: "--unknown",
             candidates: []
           }
  end

  test "one exact record returns a unique candidate with the resolved value" do
    index = build!([record()])

    assert %{
             state: :unique_candidate,
             variable: "--grid-1",
             candidates: [
               %{
                 resolved_value: "repeat(1, minmax(0, 1fr))",
                 authority_id: "automatic-css-4.0.1:structural-grid:grid-1"
               }
             ]
           } = StructuralVariableAuthority.resolve(index, "--grid-1")
  end

  test "differing authority values for the same variable are ambiguous" do
    index =
      build!([
        record(),
        record(%{
          "resolved_value" => "repeat(2, minmax(0, 1fr))",
          "authority_id" => "automatic-css-4.0.1:structural-grid:grid-1-alt"
        })
      ])

    assert %{
             state: :ambiguous_candidates,
             variable: "--grid-1",
             candidates: [_first, _second]
           } = StructuralVariableAuthority.resolve(index, "--grid-1")
  end

  test "resolution is deterministic regardless of input order" do
    first = build!([record(), record()])
    second = build!([record(), record()])

    assert StructuralVariableAuthority.resolve(first, "--grid-1") ==
             StructuralVariableAuthority.resolve(second, "--grid-1")
  end

  test "duplicate identical records are deduplicated" do
    index = build!([record(), record()])

    assert %{
             state: :unique_candidate,
             candidates: [candidate]
           } = StructuralVariableAuthority.resolve(index, "--grid-1")

    assert candidate.resolved_value == "repeat(1, minmax(0, 1fr))"
  end
end
