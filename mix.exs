defmodule Aoc2025.MixProject do
  use Mix.Project

  def project do
    [
      app: :aoc2025,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: Aoc2025.CLI],
      test_paths: ["tests"],
      deps: []
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end
end
