defmodule GraphiteLimiter.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :graphite_limiter,
      version: "0.3.3",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env),
      dialyzer: [plt_add_deps: :transitive, ignore_warnings: "dialyzer.ignore-warnings"],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/test_helper.exs"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :plug, :prometheus_ex, :prometheus_plugs],
      mod: {GraphiteLimiter.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.4.0"},
      {:hackney, "~> 1.17.0"},
      {:jason, ">= 1.0.0"},
      {:mock, "~> 0.3.0", only: :test},
      {:cowboy, "~> 1.0"},
      {:plug_cowboy, "~> 1.0"},
      {:ranch, "~> 1.5.0", override: true},
      {:prometheus_plugs, "~> 1.1"},
      {:distillery, "~> 2.0"},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.8", only: :test},
      {:benchee, "~> 0.11", only: :dev}
    ]
  end
end
