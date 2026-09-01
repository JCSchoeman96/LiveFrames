defmodule Mix.Tasks.LiveFrames.Bricks.DesignIr do
  @shortdoc "Generate the deterministic Bricks Design IR document"

  use Mix.Task

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.IR

  @switches [
    source: :string,
    component_id: :string,
    acss_source: :string,
    output: :string
  ]

  @default_source "fixtures/bricks/bricks_components.json"
  @default_component_id "sqhmmc"
  @default_acss_source "fixtures/automatic_css/acss_settings.json"
  @default_output "sources/work/hero_india/design_ir/design_document.json"

  @impl Mix.Task
  def run(args) do
    {options, invalid} = OptionParser.parse!(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid Bricks Design IR options: #{inspect(invalid)}")
    end

    source_path = path_option(options, :source, @default_source)
    component_id = Keyword.get(options, :component_id, @default_component_id)
    acss_path = path_option(options, :acss_source, @default_acss_source)
    output_path = path_option(options, :output, @default_output)
    token_set = load_token_set!(acss_path)

    case Bricks.to_ir(source_path, component_id: component_id, token_set: token_set) do
      {:ok, document} ->
        File.mkdir_p!(Path.dirname(output_path))
        File.write!(output_path, IR.encode!(document) <> "\n")
        Mix.shell().info("Generated #{output_path}")

      {:error, diagnostics} ->
        codes = diagnostics |> Enum.map(& &1.code) |> Enum.uniq() |> Enum.join(", ")

        Mix.raise(
          "Bricks Design IR generation failed#{if(codes == "", do: "", else: ": #{codes}")}"
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
