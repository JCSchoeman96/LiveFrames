defmodule Mix.Tasks.LiveFrames.Assets.Build do
  @shortdoc "Build LiveFrames native styling artifacts"
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {options, invalid} = OptionParser.parse!(args, strict: [])
    if invalid != [], do: Mix.raise("invalid assets build options: #{inspect(invalid)}")
    if options != [], do: Mix.raise("live_frames.assets.build accepts no options")

    Mix.Task.run("live_frames.styling.theme.build")
    Mix.Task.run("tailwind", ["live_frames"])
    Mix.shell().info("Built live_frames styling artifacts")
  end
end
