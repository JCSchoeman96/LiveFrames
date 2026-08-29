defmodule LiveFramesUmbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      version: "0.1.0",
      aliases: aliases(),
      deps: []
    ]
  end

  def cli do
    [preferred_envs: [check: :test]]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["assets.setup", "tailwind storybook", "esbuild app", "esbuild storybook"],
      check: ["format --check-formatted", "compile --warnings-as-errors", "test"]
    ]
  end
end
