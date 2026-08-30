defmodule Mix.Tasks.LiveFrames.Bricks.StageA do
  @shortdoc "Generate deterministic Bricks Stage A artifacts"

  use Mix.Task

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.Bricks.StageA

  @switches [
    source: :string,
    component_id: :string,
    acss_source: :string,
    output_dir: :string
  ]

  @default_source "fixtures/bricks/bricks_components.json"
  @default_component_id "sqhmmc"
  @default_acss_source "fixtures/automatic_css/acss_settings.json"
  @default_output_dir "sources/work/hero_india/stage_a"

  @impl Mix.Task
  def run(args) do
    {options, invalid} = OptionParser.parse!(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid Bricks Stage A options: #{inspect(invalid)}")
    end

    source_path = path_option(options, :source, @default_source)
    component_id = Keyword.get(options, :component_id, @default_component_id)
    acss_path = path_option(options, :acss_source, @default_acss_source)
    output_dir = path_option(options, :output_dir, @default_output_dir)

    token_set = load_token_set!(acss_path)

    case StageA.generate_from_file(source_path,
           component_id: component_id,
           token_set: token_set,
           output_dir: output_dir
         ) do
      {:ok, result} ->
        Mix.shell().info("Generated #{Enum.join(StageA.artifact_names(), ", ")} in #{output_dir}")

        Mix.shell().info(
          "Elements: #{result.report["element_count"]}; diagnostics: #{length(result.diagnostics)}"
        )

      {:error, diagnostics} ->
        codes = diagnostics |> Enum.map(& &1.code) |> Enum.uniq() |> Enum.join(", ")

        Mix.raise(
          "Bricks Stage A generation failed#{if(codes == "", do: "", else: ": #{codes}")}"
        )
    end
  end

  defp load_token_set!(path) do
    case AutomaticCSS.from_file(path,
           source_version: "4.0.1",
           source_version_status: "fixture_reference",
           strict: true,
           profile: :hero_foundation
         ) do
      {:ok, token_set, _diagnostics} ->
        token_set

      {:error, diagnostics} ->
        codes = diagnostics |> Enum.map(& &1.code) |> Enum.uniq() |> Enum.join(", ")

        Mix.raise(
          "Automatic.css TokenSet could not be loaded#{if(codes == "", do: "", else: ": #{codes}")}"
        )
    end
  end

  defp path_option(options, key, default) do
    options
    |> Keyword.get(key, default)
    |> Path.expand(File.cwd!())
  end
end
