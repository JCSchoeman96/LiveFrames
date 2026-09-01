defmodule Mix.Tasks.LiveFrames.Fidelity.Generate do
  @shortdoc "Generate deterministic Design IR fidelity artifacts"
  use Mix.Task

  alias LiveFrames.Fidelity
  alias LiveFrames.Fidelity.DocumentLoader

  @default_input "sources/work/hero_india/design_ir/design_document.json"
  @default_heex "apps/live_frames_preview/lib/live_frames_preview_web/live/fidelity_generated/hero.html.heex"
  @default_css "apps/live_frames_preview/priv/static/assets/fidelity/hero.css"
  @default_manifest "sources/work/hero_india/fidelity/manifest.json"

  @switches [input: :string, heex: :string, css: :string, manifest: :string]

  @impl Mix.Task
  def run(args) do
    {options, invalid} = OptionParser.parse!(args, strict: @switches)
    if invalid != [], do: Mix.raise("invalid fidelity options: #{inspect(invalid)}")

    input = path(options, :input, @default_input)
    heex = path(options, :heex, @default_heex)
    css = path(options, :css, @default_css)
    manifest = path(options, :manifest, @default_manifest)

    with {:ok, document} <- DocumentLoader.from_file(input),
         {:ok, bundle} <- Fidelity.generate(document),
         :ok <- write(heex, bundle.heex),
         :ok <- write(css, bundle.css),
         :ok <-
           write(
             manifest,
             Jason.encode!(Map.put(bundle.manifest, "input_ir_sha256", sha(File.read!(input)))) <>
               "\n"
           ) do
      Mix.shell().info("Generated fidelity artifacts")
    else
      {:error, diagnostics} -> Mix.raise("fidelity generation failed: #{inspect(diagnostics)}")
    end
  end

  defp path(options, key, default),
    do: Path.expand(Keyword.get(options, key, default), File.cwd!())

  defp write(path, contents) do
    File.mkdir_p!(Path.dirname(path))
    File.write(path, contents)
  end

  defp sha(value), do: Base.encode16(:crypto.hash(:sha256, value), case: :lower)
end
