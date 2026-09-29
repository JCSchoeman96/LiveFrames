defmodule LiveFrames.Styles.StructuralVariableAuthorityTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Styles.StructuralVariableAuthority
  alias LiveFrames.Styles.StructuralVariableAuthority.BuildError

  defp record(overrides \\ %{}) do
    Map.merge(
      %{
        "variable" => "--grid-1",
        "resolved_value" => "repeat(1, minmax(0, 1fr))",
        "authority_id" => "automatic-css-4.0.1:structural-grid:grid-1",
        "source_system" => "automatic_css",
        "source_version" => "4.0.1",
        "authority_type" => "PROJECT_SOURCE_ENVIRONMENT_GENERATED_CSS",
        "metadata" => %{}
      },
      overrides
    )
  end

  defp build!(records) do
    assert {:ok, index} = StructuralVariableAuthority.build(records)
    index
  end

  test "empty index returns no authority" do
    index = build!([])

    assert StructuralVariableAuthority.resolve(index, "--unknown") == %{
             state: :no_authority,
             variable: "--unknown",
             candidates: []
           }
  end

  test "one valid record returns a unique candidate" do
    index = build!([record()])

    assert %{
             state: :unique_candidate,
             variable: "--grid-1",
             candidates: [candidate]
           } = StructuralVariableAuthority.resolve(index, "--grid-1")

    assert candidate.resolved_value == "repeat(1, minmax(0, 1fr))"
  end

  test "exact duplicate records deduplicate to one unique candidate" do
    index = build!([record(), record()])

    assert %{
             state: :unique_candidate,
             candidates: [candidate]
           } = StructuralVariableAuthority.resolve(index, "--grid-1")

    assert candidate.authority_id == "automatic-css-4.0.1:structural-grid:grid-1"
  end

  test "same variable and value with different authority IDs are ambiguous" do
    index =
      build!([
        record(),
        record(%{"authority_id" => "automatic-css-4.0.1:structural-grid:grid-1-alt"})
      ])

    assert %{
             state: :ambiguous_candidates,
             variable: "--grid-1",
             candidates: [_first, _second]
           } = StructuralVariableAuthority.resolve(index, "--grid-1")
  end

  test "differing resolved values are ambiguous" do
    index =
      build!([
        record(),
        record(%{"resolved_value" => "repeat(2, minmax(0, 1fr))"})
      ])

    assert StructuralVariableAuthority.resolve(index, "--grid-1").state == :ambiguous_candidates
  end

  test "resolution is deterministic regardless of input order" do
    first =
      build!([
        record(),
        record(%{"authority_id" => "automatic-css-4.0.1:structural-grid:grid-1-alt"})
      ])

    second =
      build!([
        record(%{"authority_id" => "automatic-css-4.0.1:structural-grid:grid-1-alt"}),
        record()
      ])

    assert StructuralVariableAuthority.resolve(first, "--grid-1") ==
             StructuralVariableAuthority.resolve(second, "--grid-1")
  end

  test "build fails closed for a missing required field" do
    assert {:error, [%BuildError{index: 0, reason: :missing_required_field}]} =
             StructuralVariableAuthority.build([Map.delete(record(), "authority_id")])
  end

  test "build fails closed for a non-string required value" do
    assert {:error, [%BuildError{index: 0, reason: :invalid_field_type}]} =
             StructuralVariableAuthority.build([Map.put(record(), "resolved_value", 1)])
  end

  test "build fails closed for invalid metadata" do
    assert {:error, [%BuildError{index: 0, reason: :invalid_metadata}]} =
             StructuralVariableAuthority.build([Map.put(record(), "metadata", "not-a-map")])
  end
end
