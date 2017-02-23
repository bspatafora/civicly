defmodule Storage.Mixfile do
  use Mix.Project

  def project do
    [app: :storage,
     version: "0.1.0",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger],
     mod: {Storage.Application, []}]
  end

  defp deps do
    [{:ecto, "~> 2.1"},
     {:postgrex, "~> 0.13.1"}]
  end
end
