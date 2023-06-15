defmodule Pulk.MixProject do
  use Mix.Project

  def project do
    [
      app: :pulk,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:domo_compiler] ++ Mix.compilers() ++ [:domo_phoenix_hot_reload],
      test_coverage: [ignore_modules: [~r/\.TypeEnsurer$/]],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Pulk.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix_pubsub, "~> 2.1"},
      {:jason, "~> 1.2"},
      {:swoosh, "~> 1.3"},
      {:finch, "~> 0.13"},
      {:typed_struct, "~> 0.3.0"},
      {:domo, "~> 1.5"},
      {:friendlyid, "~> 0.2.0"},
      {:nanoid, "~> 2.0.5"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      "format.all": "format",
      lint: ["format --check-formatted", "credo"],
      setup: ["deps.get"],
      test: ["test"]
    ]
  end
end
