defmodule LiveFramesPreview.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_frames_preview,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [mod: {LiveFramesPreview.Application, []}, extra_applications: [:logger]]
  end

  defp deps do
    [
      {:live_frames, in_umbrella: true},
      {:phoenix, "~> 1.8.9"},
      {:phoenix_live_view, "~> 1.1"},
      {:bandit, "~> 1.12"},
      {:jason, "~> 1.4"}
    ]
  end
end
