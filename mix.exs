defmodule MicroServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :micro_server,
      version: "0.1.0",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MicroServer.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 2.2"},
      {:mariaex, "~> 0.8.2"},
      {:luerl, "~> 0.3.1"},
      {:earmark, "~> 1.2", only: :dev},
      {:ex_doc, "~> 0.18.0", only: :dev},
      {:kunerauqs, ">= 0.1.0", path: "J:/NEW_WORLD/20xx/projects/kunerauqs"},
      {:httpoison, "~> 1.4"},
      {:poolboy, "~> 1.5.1"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
