defmodule LiveFrames.BricksDriftTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks.StageA
  alias LiveFrames.Adapters.AutomaticCSS

  defp fixture_path do
    Path.expand("../../../../fixtures/bricks/bricks_components.json", __DIR__)
  end

  defp committed_artifact_path do
    Path.expand("../../../../sources/work/hero_india/stage_a", __DIR__)
  end

  defp token_set do
    {:ok, token_set, _diagnostics} =
      AutomaticCSS.from_file(
        Path.expand("../../../../fixtures/automatic_css/acss_settings.json", __DIR__),
        source_version: "4.0.1",
        source_version_status: "fixture_reference",
        strict: true,
        profile: :hero_foundation
      )

    token_set
  end

  defp temp_dir(label) do
    path =
      Path.join(
        System.tmp_dir!(),
        "liveframes-phase4-#{label}-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(path)
    on_exit(fn -> File.rm_rf!(path) end)
    path
  end

  defp generate_to(directory) do
    assert {:ok, result} =
             StageA.generate_from_file(fixture_path(),
               component_id: "sqhmmc",
               output_dir: directory
             )

    result.artifacts
  end

  defp read_artifacts(directory) do
    Map.new(StageA.artifact_names(), fn name -> {name, File.read!(Path.join(directory, name))} end)
  end

  test "two successive generations are byte-identical" do
    first = temp_dir("first")
    second = temp_dir("second")

    generate_to(first)
    generate_to(second)
    assert read_artifacts(first) == read_artifacts(first)
    assert read_artifacts(second) == read_artifacts(second)
    assert read_artifacts(first) == read_artifacts(second)
  end

  test "drift detects a modified expected artifact" do
    expected = temp_dir("expected-modified")
    temporary = temp_dir("temporary-modified")
    generate_to(expected)
    File.write!(Path.join(expected, "index.html"), "changed")

    assert {:error, diagnostics} =
             StageA.verify_drift(
               expected_dir: expected,
               temporary_dir: temporary,
               source_path: fixture_path()
             )

    assert Enum.any?(diagnostics, &(&1.code == "bricks.artifact.different"))
  end

  test "drift detects missing and unexpected generated artifacts" do
    expected = temp_dir("expected-files")
    temporary = temp_dir("temporary-files")
    generate_to(expected)
    File.cp_r!(expected, temporary)
    File.rm!(Path.join(temporary, "styles.css"))
    File.write!(Path.join(temporary, "extra.txt"), "unexpected")

    assert {:error, diagnostics} =
             StageA.verify_drift(
               expected_dir: expected,
               temporary_dir: temporary,
               source_path: fixture_path(),
               generate: false
             )

    assert Enum.any?(diagnostics, &(&1.code == "bricks.artifact.missing"))
    assert Enum.any?(diagnostics, &(&1.code == "bricks.artifact.unexpected"))
  end

  test "generated report has no machine-local or generated metadata" do
    directory = temp_dir("metadata")
    generate_to(directory)
    report = Jason.decode!(File.read!(Path.join(directory, "report.json")))

    refute contains_forbidden_key?(report)
    refute contains_forbidden_value?(report)
  end

  test "committed artifacts regenerate byte-identically" do
    temporary = temp_dir("committed-parity")

    assert :ok =
             StageA.verify_drift(
               expected_dir: committed_artifact_path(),
               temporary_dir: temporary,
               source_path: fixture_path(),
               component_id: "sqhmmc",
               token_set: token_set()
             )
  end

  defp contains_forbidden_key?(value) when is_map(value) do
    Enum.any?(value, fn {key, nested} ->
      key in [
        "generated_at",
        "timestamp",
        "pid",
        "process_id",
        "host",
        "absolute_path",
        "random_id",
        "environment"
      ] or
        contains_forbidden_key?(nested)
    end)
  end

  defp contains_forbidden_key?(value) when is_list(value),
    do: Enum.any?(value, &contains_forbidden_key?/1)

  defp contains_forbidden_key?(_value), do: false

  defp contains_forbidden_value?(value) when is_binary(value),
    do: String.contains?(value, ["_build/", "LIVEFRAMES_", "/home/", "/tmp/"])

  defp contains_forbidden_value?(value) when is_map(value),
    do: Enum.any?(value, fn {_key, nested} -> contains_forbidden_value?(nested) end)

  defp contains_forbidden_value?(value) when is_list(value),
    do: Enum.any?(value, &contains_forbidden_value?/1)

  defp contains_forbidden_value?(_value), do: false
end
