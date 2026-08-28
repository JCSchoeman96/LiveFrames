defmodule LiveFramesPreview.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_frames_preview,
      version: "0.1.0",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [mod: {LiveFramesPreview.Application, []}, extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:live_frames, in_umbrella: true},
      {:phoenix, "~> 1.8.13"},
      {:phoenix_live_view, "~> 1.2.11"},
      {:phoenix_storybook, "~> 1.3.0"},
      {:tailwind, "~> 0.5.1"},
      {:esbuild, "~> 0.10.0"},
      {:phoenix_live_reload, "~> 1.7", only: :dev},
      {:bandit, "~> 1.12"},
      {:jason, "~> 1.4"}
    ]
  end
end
