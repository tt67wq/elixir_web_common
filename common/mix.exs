defmodule Common.MixProject do
  use Mix.Project

  def project do
   [
      app: :common,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:eqrcode, "~> 0.1.6"},
      {:poison, "~> 4.0.1"},
      {:timex, "~> 3.1"},
      {:redix, ">= 0.0.0"},
      {:rsa_ex, "~> 0.4"},
      {:httpotion, "~> 3.1.0"},
      {:distillery, "~> 2.1.1"},
      {:peerage, "~> 1.0.2"},
      {:logger_file_backend, "~> 0.0.10"},
      {:credo, "~> 1.0.0", only: [:dev], runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true},
    ]
  end
end
