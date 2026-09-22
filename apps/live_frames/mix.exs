defmodule LiveFrames.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_frames,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: [
        {:phoenix_live_view, "~> 1.2.11"},
        {:jason, "~> 1.4"},
        {:tailwind, "~> 0.5.1", runtime: false}
      ],
      package: package()
    ]
  end

  def application do
    [extra_applications: [:logger], mod: {LiveFrames.Application, []}]
  end

  def package do
    [
      files: ~w(lib mix.exs README.md assets/css priv/token_maps priv/static/live_frames)
    ]
  end
end
