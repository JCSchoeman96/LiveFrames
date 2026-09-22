defmodule Mix.Tasks.LiveFrames.Styling.Theme.Build do
  @shortdoc "Generate deterministic lf_theme.css from TokenSet mapping"
  use Mix.Task

  alias LiveFrames.Adapters.AutomaticCSS
  alias LiveFrames.Styling.TokenBridge

  @app_root Path.expand("../../..", __DIR__)

  @default_fixture Path.expand("../../fixtures/automatic_css/acss_settings.json", @app_root)
  @default_mapping Path.join(@app_root, "priv/token_maps/native_hero_v1.json")
  @default_output Path.join(@app_root, "assets/css/theme/lf_theme.css")

  @switches [
    fixture: :string,
    mapping: :string,
    output: :string
  ]

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("compile")

    {options, invalid} = OptionParser.parse!(args, strict: @switches)
    if invalid != [], do: Mix.raise("invalid theme build options: #{inspect(invalid)}")

    fixture = path(options, :fixture, @default_fixture)
    mapping_path = path(options, :mapping, @default_mapping)
    output = path(options, :output, @default_output)

    with {:ok, token_set, _diagnostics} <-
           AutomaticCSS.from_file(fixture,
             strict: true,
             profile: :hero_foundation,
             source_version: "4.0.1",
             source_version_status: "fixture_reference"
           ),
         mapping <- TokenBridge.load_mapping!(mapping_path),
         {:ok, css} <- TokenBridge.generate(token_set, mapping),
         :ok <- write(output, css) do
      Mix.shell().info(["Generated ", output])
    else
      {:error, reason} -> Mix.raise("theme build failed: #{inspect(reason)}")
    end
  end

  defp path(options, key, default) do
    Path.expand(Keyword.get(options, key, default), File.cwd!())
  end

  defp write(path, contents) do
    File.mkdir_p!(Path.dirname(path))
    File.write(path, contents)
  end
end
