defmodule LiveFrames.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_frames,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: [{:phoenix_live_view, "~> 1.2.11"}]
    ]
  end

  def application do
    [extra_applications: [:logger], mod: {LiveFrames.Application, []}]
  end
end
